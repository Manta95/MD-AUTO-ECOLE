ESX = exports["es_extended"]:getSharedObject()
-- VARIABLES
---------------------------------------------------------------------------
local display = false
local pedSpawned = false
local schoolPed = nil
local menuCam = nil

local inTest = false
local currentTestType = nil
local currentVehicle = nil
local currentInstructor = nil
local currentCheckpoint = 1
local errors = 0
local quizPassed = {} -- Track which license types have passed the quiz
local purchaseInProgress = false -- Empêche de lancer deux demandes d'examen en parallèle

function CreateQuizCamera()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local cam = Config.Camera

    local camX = pedCoords.x + fwd.x * cam.distance
    local camY = pedCoords.y + fwd.y * cam.distance
    local camZ = pedCoords.z + cam.height

    menuCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(menuCam, camX, camY, camZ)
    PointCamAtCoord(menuCam, pedCoords.x, pedCoords.y, pedCoords.z + 0.1)
    SetCamFov(menuCam, cam.fov)

    SetCamActive(menuCam, true)
    RenderScriptCams(true, true, cam.transitionMs, true, false)
end

function DestroyQuizCamera()
    if menuCam then
        RenderScriptCams(false, true, Config.Camera.transitionMs, true, false)
        SetCamActive(menuCam, false)
        DestroyCam(menuCam, false)
        menuCam = nil
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local pedCoords = Config.SchoolZone.Ped.coords
        local dist = #(playerCoords - vector3(pedCoords.x, pedCoords.y, pedCoords.z))

        if dist < 50.0 and not pedSpawned then
            RequestModel(Config.SchoolZone.Ped.model)
            while not HasModelLoaded(Config.SchoolZone.Ped.model) do Wait(10) end
            
            schoolPed = CreatePed(4, Config.SchoolZone.Ped.model, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
            FreezeEntityPosition(schoolPed, true)
            SetEntityInvincible(schoolPed, true)
            SetBlockingOfNonTemporaryEvents(schoolPed, true)
            pedSpawned = true
        elseif dist >= 50.0 and pedSpawned then
            DeletePed(schoolPed)
            pedSpawned = false
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local mCoords = Config.SchoolZone.Marker.coords
        local dist = #(playerCoords - vector3(mCoords.x, mCoords.y, mCoords.z))
        
        if not inTest and not display and dist < 10.0 then
            wait = 0
            if Config.SchoolZone.Marker.enabled then
                DrawMarker(Config.SchoolZone.Marker.type, mCoords.x, mCoords.y, mCoords.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.SchoolZone.Marker.size.x, Config.SchoolZone.Marker.size.y, Config.SchoolZone.Marker.size.z, Config.SchoolZone.Marker.color.r, Config.SchoolZone.Marker.color.g, Config.SchoolZone.Marker.color.b, Config.SchoolZone.Marker.color.a, false, true, 2, false, nil, nil, false)
            end
            
            if dist < 2.0 then
                ESX.ShowHelpNotification(Config.SchoolZone.Marker.text)
                if IsControlJustReleased(0, 38) then -- E
                    SetDisplay(true)
                end
            end
        end
        Wait(wait)
    end
end)

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    
    if bool then
        -- On récupère les codes déjà passés depuis la BDD avant d'ouvrir le menu
        ESX.TriggerServerCallback('md_autoecole:getPassedCodes', function(dbPassedCodes)
            quizPassed = dbPassedCodes or {}
            SendNUIMessage({
                action = "openMenu",
                questions = Config.Questions,
                quizPassed = quizPassed,
                quizConfig = {
                    questionsPerExam = Config.Quiz.questionsPerExam,
                    timeLimit        = Config.Quiz.timeLimit,
                    passThreshold    = Config.Quiz.passThreshold,
                }
            })
        end)
    else
        SendNUIMessage({
            action = "closeMenu",
        })
    end
end

-- Callbacks pour la caméra du quiz
RegisterNUICallback("quizStart", function(data, cb)
    CreateQuizCamera()
    if schoolPed and DoesEntityExist(schoolPed) then
        SetEntityVisible(schoolPed, false, 0)
    end
    cb("ok")
end)

RegisterNUICallback("quizEnd", function(data, cb)
    DestroyQuizCamera()
    if schoolPed and DoesEntityExist(schoolPed) then
        SetEntityVisible(schoolPed, true, 0)
    end
    cb("ok")
end)

function RequestStartExam(pType)
    if inTest or purchaseInProgress then return end
    purchaseInProgress = true

    ESX.TriggerServerCallback('md_autoecole:hasLicense', function(hasLicense)
        if hasLicense then
            ESX.ShowNotification("Vous avez déjà ce permis !")
            purchaseInProgress = false
        else
            ESX.TriggerServerCallback('md_autoecole:checkMoney', function(hasMoney)
                if hasMoney then
                    StartTest(pType)
                else
                    local price = Config.Prices[pType] or 500
                    ESX.ShowNotification("Vous n'avez pas assez d'argent ($" .. price .. ").")
                end
                purchaseInProgress = false
            end, pType)
        end
    end, pType)
end

RegisterNUICallback("action", function(data, cb)
    if data.action == "close" then
        SetDisplay(false)
        cb("ok")
    elseif data.action == "select" then
        SetDisplay(false)
        local pType = data.type

        if pType == "voiture" or pType == "moto" or pType == "camion" then
            RequestStartExam(pType)
        end
        cb("ok")
    elseif data.action == "quizResult" then
        -- Le quiz est terminé
        if data.passed then
            quizPassed[data.type] = true
            -- Sauvegarder la progression en BDD
            TriggerServerEvent('md_autoecole:saveCodePassed', data.type)
        else
            TriggerServerEvent('md_autoecole:logFailure', data.type, "Échec au Code de la Route")
        end
        cb("ok")
    elseif data.action == "startPractical" then
        -- Le joueur a déjà passé le code, il veut lancer l'examen pratique directement
        SetDisplay(false)
        local pType = data.type
        if pType and quizPassed[pType] then
            RequestStartExam(pType)
        end
        cb("ok")
    end
end)

function StartTest(type)
    if inTest then return end

    local vehicleModel = Config.Vehicles[type]
    if not vehicleModel then
        ESX.ShowNotification("Erreur: véhicule d'examen introuvable.")
        return
    end

    inTest = true
    currentTestType = type
    currentCheckpoint = 1
    errors = 0

    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do Wait(10) end

    -- Décale le point de spawn par joueur pour éviter que deux véhicules
    -- se superposent si plusieurs examens démarrent en même temps
    local spawn = Config.SpawnPoint
    local offsetAngle = math.rad((GetPlayerServerId(PlayerId()) % 8) * 45.0)
    local spawnX = spawn.x + math.cos(offsetAngle) * 6.0
    local spawnY = spawn.y + math.sin(offsetAngle) * 6.0
    currentVehicle = CreateVehicle(vehicleModel, spawnX, spawnY, spawn.z, spawn.w, true, true)
    
    -- Cinematic Enter
    Citizen.CreateThread(function()
        DoScreenFadeOut(500)
        Wait(500)
        
        local ped = PlayerPedId()
        
        -- Spawn Instructor Ped
        local pedModel = Config.SchoolZone.Ped.model
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do Wait(10) end
        
        -- Placer le joueur à côté de la porte conducteur
        local driverDoorPos = GetOffsetFromEntityInWorldCoords(currentVehicle, -1.5, 0.0, 0.0)
        SetEntityCoords(ped, driverDoorPos.x, driverDoorPos.y, driverDoorPos.z)
        
        -- Placer le moniteur à côté de la porte passager
        local passDoorPos = GetOffsetFromEntityInWorldCoords(currentVehicle, 1.5, 0.0, 0.0)
        currentInstructor = CreatePed(4, pedModel, passDoorPos.x, passDoorPos.y, passDoorPos.z, spawn.w, false, true)
        SetBlockingOfNonTemporaryEvents(currentInstructor, true)
        SetEntityInvincible(currentInstructor, true)
        
        Wait(500)
        DoScreenFadeIn(500)
        
        -- Ordre de monter dans le véhicule
        TaskEnterVehicle(ped, currentVehicle, -1, -1, 1.5, 1, 0)
        TaskEnterVehicle(currentInstructor, currentVehicle, -1, 0, 1.5, 1, 0)
        
        -- Attendre qu'ils soient tous les deux installés
        while not IsPedInAnyVehicle(ped, false) or not IsPedInAnyVehicle(currentInstructor, false) do
            Wait(500)
        end
        
        ESX.ShowNotification("Examen commencé ! Rendez-vous au premier point.")
        RunTestLoop()
    end)
end

function StopTest(success, reason)
    inTest = false
    local ped = PlayerPedId()
    
    if success then
        ESX.ShowNotification("Examen réussi ! Vous obtenez votre permis.")
        TriggerServerEvent('md_autoecole:addLicense', currentTestType)
    else
        ESX.ShowNotification("Examen échoué ! Vous avez fait trop d'erreurs.")
        TriggerServerEvent('md_autoecole:logFailure', currentTestType, reason or "Trop d'erreurs")
    end
    
    if DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end
    currentVehicle = nil

    if DoesEntityExist(currentInstructor) then
        DeletePed(currentInstructor)
    end
    currentInstructor = nil
    
    -- Teleport back to school
    local back = Config.SchoolZone.Marker.coords
    SetEntityCoords(ped, back.x, back.y, back.z)
end

function RunTestLoop()
    Citizen.CreateThread(function()
        local lastHealth = {
            engine = GetVehicleEngineHealth(currentVehicle),
            body = GetVehicleBodyHealth(currentVehicle)
        }
        local lastDamageErrorTime = 0
        local lastSpeedErrorTime = 0
        
        while inTest do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local currentTime = GetGameTimer()
            
            -- Check Damages
            local currentEngineHealth = GetVehicleEngineHealth(currentVehicle)
            local currentBodyHealth = GetVehicleBodyHealth(currentVehicle)
            
            if Config.DamageFail and Config.DamageFail.enabled then
                if currentEngineHealth < Config.DamageFail.minHealth or currentBodyHealth < Config.DamageFail.minHealth then
                    ESX.ShowNotification("Véhicule trop endommagé ! Examen annulé.")
                    StopTest(false, "Véhicule trop endommagé")
                    break
                end
            end

            if currentEngineHealth < lastHealth.engine or currentBodyHealth < lastHealth.body then
                if currentTime - lastDamageErrorTime > 1500 then
                    errors = errors + 1
                    ESX.ShowNotification("Véhicule accroché ! Erreurs: " .. errors .. "/" .. Config.MaxErrors)
                    if errors >= Config.MaxErrors then
                        StopTest(false, "Trop d'accrochages ("..errors.."/"..Config.MaxErrors..")")
                        break
                    end
                    lastDamageErrorTime = currentTime
                end
                lastHealth.engine = currentEngineHealth
                lastHealth.body = currentBodyHealth
            end
            
            -- Check Speed
            local speed = GetEntitySpeed(currentVehicle) * 3.6 -- km/h
            local limit = Config.Checkpoints[currentCheckpoint].speedLimit
            if speed > limit + 5.0 then
                if currentTime - lastSpeedErrorTime > 3000 then
                    errors = errors + 1
                    ESX.ShowNotification("Vitesse excessive ! (" .. math.floor(speed) .. " km/h > " .. limit .. " km/h) Erreurs: " .. errors .. "/" .. Config.MaxErrors)
                    if errors >= Config.MaxErrors then
                        StopTest(false, "Excès de vitesse ("..errors.."/"..Config.MaxErrors..")")
                        break
                    end
                    lastSpeedErrorTime = currentTime
                end
            end
            
            -- Draw Checkpoint
            local cpCoords = Config.Checkpoints[currentCheckpoint].coords
            DrawMarker(1, cpCoords.x, cpCoords.y, cpCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
            SetNewWaypoint(cpCoords.x, cpCoords.y)
            
            local dist = #(coords - vector3(cpCoords.x, cpCoords.y, cpCoords.z))
            if dist < 4.0 then
                local cpData = Config.Checkpoints[currentCheckpoint]
                
                -- Gestion de l'action STOP (Automatique pendant 3s)
                if cpData.action == "stop" then
                    ESX.ShowNotification("Aide: Arrêt automatique au feu/stop...")
                    
                    -- Freinage brutal et blocage
                    SetVehicleForwardSpeed(currentVehicle, 0.0)
                    FreezeEntityPosition(currentVehicle, true)
                    
                    Wait(3000) -- Attendre 3 secondes bloqué
                    
                    -- Déblocage du véhicule
                    FreezeEntityPosition(currentVehicle, false)
                    AdvanceCheckpoint()
                else
                    -- Checkpoint normal
                    AdvanceCheckpoint()
                end
            end
        end
    end)
end

function AdvanceCheckpoint()
    currentCheckpoint = currentCheckpoint + 1
    if currentCheckpoint > #Config.Checkpoints then
        StopTest(true)
    else
        local nextCp = Config.Checkpoints[currentCheckpoint]
        if nextCp.msg then
            ESX.ShowNotification("Passage: " .. nextCp.msg)
        else
            ESX.ShowNotification("Point de passage atteint. Allez au suivant.")
        end
    end
end

Citizen.CreateThread(function()
    if Config.Blip and Config.Blip.enabled then
        local blip = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Nettoyage des entités si la resource est stoppée/redémarrée en cours d'utilisation
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    DestroyQuizCamera()

    if schoolPed and DoesEntityExist(schoolPed) then
        DeletePed(schoolPed)
    end

    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteVehicle(currentVehicle)
    end

    if currentInstructor and DoesEntityExist(currentInstructor) then
        DeletePed(currentInstructor)
    end
end)
