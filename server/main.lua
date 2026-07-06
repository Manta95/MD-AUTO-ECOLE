ESX = exports["es_extended"]:getSharedObject()

function SendToDiscord(color, title, message)
    if not Config.Webhook or Config.Webhook == "" or Config.Webhook == "TON_LIEN_WEBHOOK_ICI" then return end
    
    local embed = {
        {
            ["color"] = color,
            ["title"] = "**" .. title .. "**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "Auto-École Logs",
            },
        }
    }
    
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({username = "Auto-École", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

ESX.RegisterServerCallback('md_autoecole:hasLicense', function(source, cb, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchAll('SELECT * FROM md_autoecole_licenses WHERE identifier = @id AND type = @type AND status = "granted"', {
        ['@id'] = identifier,
        ['@type'] = type
    }, function(result)
        cb(#result > 0)
    end)
end)

ESX.RegisterServerCallback('md_autoecole:getPassedCodes', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    
    MySQL.Async.fetchAll('SELECT type FROM md_autoecole_licenses WHERE identifier = @id AND (status = "code_passed" OR status = "granted")', {
        ['@id'] = identifier
    }, function(result)
        local passedTypes = {}
        for i=1, #result do
            passedTypes[result[i].type] = true
        end
        cb(passedTypes)
    end)
end)

ESX.RegisterServerCallback('md_autoecole:checkMoney', function(source, cb, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.Prices[type] or 500

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        cb(true)
    elseif xPlayer.getAccount('bank').money >= price then
        xPlayer.removeAccountMoney('bank', price)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent('md_autoecole:addLicense')
AddEventHandler('md_autoecole:addLicense', function(type)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    -- Vérifier le type
    if type ~= "voiture" and type ~= "moto" and type ~= "camion" then
        DropPlayer(source, "Type de permis invalide.")
        return
    end

    -- Insérer en base ou mettre à jour le statut à "granted"
    MySQL.Async.execute([[
        INSERT INTO md_autoecole_licenses (identifier, type, status) 
        VALUES (@id, @type, 'granted')
        ON DUPLICATE KEY UPDATE status = 'granted'
    ]], {
        ['@id'] = identifier,
        ['@type'] = type
    }, function(rowsChanged)
        TriggerClientEvent('esx:showNotification', source, 'Félicitations ! Vous avez obtenu votre permis ' .. type .. ' !')
        print('[md_autoecole] Permis ' .. type .. ' accordé (granted) pour ' .. identifier)
        SendToDiscord(65280, "Permis Obtenu", "Le joueur **" .. xPlayer.getName() .. "** a obtenu son permis de type **" .. type .. "**.")
    end)
end)

RegisterNetEvent('md_autoecole:saveCodePassed')
AddEventHandler('md_autoecole:saveCodePassed', function(type)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    if type ~= "voiture" and type ~= "moto" and type ~= "camion" then return end

    MySQL.Async.execute([[
        INSERT INTO md_autoecole_licenses (identifier, type, status) 
        VALUES (@id, @type, 'code_passed')
        ON DUPLICATE KEY UPDATE status = status
    ]], {
        ['@id'] = identifier,
        ['@type'] = type
    }, function()
        SendToDiscord(3447003, "Code de la Route", "Le joueur **" .. xPlayer.getName() .. "** a validé son code pour le permis **" .. type .. "**.")
    end)
end)

ESX = exports["es_extended"]:getSharedObject()

function SendToDiscord(color, title, message)
    if not Config.Webhook or Config.Webhook == "" or Config.Webhook == "TON_LIEN_WEBHOOK_ICI" then return end
    
    local embed = {
        {
            ["color"] = color,
            ["title"] = "**" .. title .. "**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "Auto-École Logs",
            },
        }
    }
    
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({username = "Auto-École", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

ESX.RegisterServerCallback('md_autoecole:hasLicense', function(source, cb, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchAll('SELECT * FROM md_autoecole_licenses WHERE identifier = @id AND type = @type AND status = "granted"', {
        ['@id'] = identifier,
        ['@type'] = type
    }, function(result)
        cb(#result > 0)
    end)
end)

ESX.RegisterServerCallback('md_autoecole:getPassedCodes', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()
    
    MySQL.Async.fetchAll('SELECT type FROM md_autoecole_licenses WHERE identifier = @id AND (status = "code_passed" OR status = "granted")', {
        ['@id'] = identifier
    }, function(result)
        local passedTypes = {}
        for i=1, #result do
            passedTypes[result[i].type] = true
        end
        cb(passedTypes)
    end)
end)

ESX.RegisterServerCallback('md_autoecole:checkMoney', function(source, cb, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.Prices[type] or 500

    if xPlayer.getMoney() >= price then
        xPlayer.removeMoney(price)
        cb(true)
    elseif xPlayer.getAccount('bank').money >= price then
        xPlayer.removeAccountMoney('bank', price)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent('md_autoecole:addLicense')
AddEventHandler('md_autoecole:addLicense', function(type)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    -- Vérifier le type
    if type ~= "voiture" and type ~= "moto" and type ~= "camion" then
        DropPlayer(source, "Type de permis invalide.")
        return
    end

    -- Insérer en base ou mettre à jour le statut à "granted"
    MySQL.Async.execute([[
        INSERT INTO md_autoecole_licenses (identifier, type, status) 
        VALUES (@id, @type, 'granted')
        ON DUPLICATE KEY UPDATE status = 'granted'
    ]], {
        ['@id'] = identifier,
        ['@type'] = type
    }, function(rowsChanged)
        TriggerClientEvent('esx:showNotification', source, 'Félicitations ! Vous avez obtenu votre permis ' .. type .. ' !')
        print('[md_autoecole] Permis ' .. type .. ' accordé (granted) pour ' .. identifier)
        SendToDiscord(65280, "Permis Obtenu", "Le joueur **" .. xPlayer.getName() .. "** a obtenu son permis de type **" .. type .. "**.")
    end)
end)

RegisterNetEvent('md_autoecole:saveCodePassed')
AddEventHandler('md_autoecole:saveCodePassed', function(type)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    if type ~= "voiture" and type ~= "moto" and type ~= "camion" then return end

    MySQL.Async.execute([[
        INSERT INTO md_autoecole_licenses (identifier, type, status) 
        VALUES (@id, @type, 'code_passed')
        ON DUPLICATE KEY UPDATE status = status
    ]], {
        ['@id'] = identifier,
        ['@type'] = type
    }, function()
        SendToDiscord(3447003, "Code de la Route", "Le joueur **" .. xPlayer.getName() .. "** a validé son code pour le permis **" .. type .. "**.")
    end)
end)

RegisterNetEvent('md_autoecole:logFailure')
AddEventHandler('md_autoecole:logFailure', function(type, reason)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    SendToDiscord(16711680, "Échec d'Examen", "Le joueur **" .. xPlayer.getName() .. "** a échoué à son examen (**" .. type .. "**).\n**Raison:** " .. reason)
end)

RegisterCommand('resetpermis', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        MySQL.Async.execute('DELETE FROM md_autoecole_licenses WHERE identifier = @id', {
            ['@id'] = identifier
        }, function(rowsChanged)
            TriggerClientEvent('esx:showNotification', source, 'Vos permis (Code + Conduite) ont été réinitialisés pour les tests.')
        end)
    end
end, false)
