---------------------------------------------------------------------------
-- CONFIGURATION AUTO-ÉCOLE
-- Modifie ce fichier pour personnaliser l'auto-école
---------------------------------------------------------------------------

Config = {}

---------------------------------------------------------------------------
-- ZONE DE L'AUTO-ÉCOLE (PNJ + Marker)
---------------------------------------------------------------------------
Config.SchoolZone = {
    Ped = {
        model = 'a_m_y_business_02',                -- Modèle du PNJ
        coords = {x = 218.27, y = -1386.06, z = 30.59, w = 141.00}
    },
    Marker = {
        enabled = false,
        type    = 1,
        coords  = {x = 218.27, y = -1386.06, z = 30.59},
        size    = {x = 1.0, y = 1.0, z = 1.0},
        color   = {r = 59, g = 130, b = 246, a = 100},
        text    = "Appuyez sur ~INPUT_CONTEXT~ pour accéder à l'auto-école"
    }
}

---------------------------------------------------------------------------
-- BLIP SUR LA CARTE
---------------------------------------------------------------------------
Config.Blip = {
    enabled = true,
    coords  = {x = 218.27, y = -1386.06, z = 30.59},
    sprite  = 549,   -- Icône diplôme
    color   = 3,     -- Bleu clair
    scale   = 0.8,
    name    = "Auto-École"
}

---------------------------------------------------------------------------
-- WEBHOOK DISCORD LOGS
---------------------------------------------------------------------------
Config.Webhook = ""
---------------------------------------------------------------------------
-- PRIX PAR TYPE DE PERMIS
---------------------------------------------------------------------------
Config.Prices = {
    voiture = 500,
    moto    = 750,
    camion  = 1500
}

---------------------------------------------------------------------------
-- EXAMEN THÉORIQUE (CODE)
---------------------------------------------------------------------------
Config.Quiz = {
    questionsPerExam = 10,      -- Nombre de questions par examen
    timeLimit        = 120,     -- Temps en secondes (2 minutes)
    passThreshold    = 7,       -- Nombre minimum de bonnes réponses
}

---------------------------------------------------------------------------
-- EXAMEN PRATIQUE (CONDUITE)
---------------------------------------------------------------------------
Config.MaxErrors = 5

Config.DamageFail = {
    enabled = true,
    minHealth = 800.0 -- (Max 1000) Si la santé de la voiture descend sous ce seuil, c'est un échec immédiat.
}

Config.SpawnPoint = {x = 227.99975585938, y = -1392.6203613281, z = 30.509635925293, w = 213.07221984863}

Config.Checkpoints = {
    -- Départ Auto-École -> Ville
    {coords = {x = 226.07934570312, y = -1409.7034912109, z = 29.446184158325}, speedLimit = 50, msg = "Suivez la route et respectez les limitations."},
    {coords = {x = 176.18908691406, y = -1400.4133300781, z = 29.341180801392}, speedLimit = 50, action = "stop", msg = "Feu tricolore, marquez l'arrêt..."},
    {coords = {x = 118.18264770508, y = -1355.8187255859, z = 29.206302642822}, speedLimit = 50, msg = "Continuez tout droit vers l'autoroute."},
    
    -- Entrée Autoroute
    {coords = {x = 67.392082214355,  y = -1182.1120605469, z = 29.341567993164}, speedLimit = 80, msg = "Tournez a gauche pour rentrer sur l'autoroute"},
    {coords = {x = 7.4552111625671,  y = -1168.6013183594, z = 31.397928237915}, speedLimit = 80, msg = "Voie d'insertion, accélérez progressivement."},
    {coords = {x = -140.73487854004, y = -1188.8121337891, z = 37.37476348877}, speedLimit = 120, msg = "Vous êtes sur l'autoroute, limitation à 120 km/h."},
    {coords = {x = -273.64193725586, y = -1197.7664794922, z = 37.1545753479}, speedLimit = 120, msg = "Gardez votre ligne d'autoroute."},
    
    -- Sortie Autoroute -> Ville
    {coords = {x = -450.07626342773, y = -1290.3648681641, z = 43.20426940918}, speedLimit = 80, msg = "Préparez-vous à sortir, ralentissez."},
    {coords = {x = -458.72271728516, y = -1397.8044433594, z = 29.352716445923}, speedLimit = 50, action = "stop", msg = "Cédez le passage avant de tourner..."},
    
    -- Retour vers l'auto-école
    {coords = {x = -349.63778686523, y = -1442.0816650391, z = 29.487203598022}, speedLimit = 50, msg = "Respectez la limitation en ville."},
    {coords = {x = -122.41679382324, y = -1381.6456298828, z = 29.43150138855}, speedLimit = 50, action = "stop", msg = "Stop ! Marquez l'arrêt complet..."},
    {coords = {x = 124.5623550415, y = -1384.4989013672, z = 29.310180664062}, speedLimit = 50, msg = "Dernière ligne droite."},
    {coords = {x = 222.95849609375, y = -1387.8786621094, z = 30.536737442017}, speedLimit = 50, msg = "Garez-vous ici pour finir l'examen."}
}

---------------------------------------------------------------------------
-- VÉHICULES D'EXAMEN
---------------------------------------------------------------------------
Config.Vehicles = {
    voiture = 'blista',
    moto    = 'bati',
    camion  = 'mule'
}

---------------------------------------------------------------------------
-- CAMÉRA DU QUIZ
---------------------------------------------------------------------------
Config.Camera = {
    distance     = 1.8,
    height       = 0.3,
    fov          = 50.0,
    transitionMs = 800
}

---------------------------------------------------------------------------
-- QUESTIONS DU CODE
-- q = la question
-- answers = les 4 réponses possibles
-- correct = index de la bonne réponse (0 = première, 1 = deuxième, etc.)
---------------------------------------------------------------------------
Config.Questions = {
    { q = "De quel côté de la route doit-on rouler ?", answers = {"À gauche", "À droite", "Au milieu", "Où on veut"}, correct = 1 },
    { q = "Que signifie un feu rouge ?", answers = {"On accélère", "On s'arrête", "On klaxonne", "On recule"}, correct = 1 },
    { q = "Que signifie un feu vert ?", answers = {"On s'arrête", "On recule", "On peut passer", "On coupe le moteur"}, correct = 2 },
    { q = "Faut-il mettre sa ceinture de sécurité ?", answers = {"Non jamais", "Seulement sur autoroute", "Oui toujours", "Seulement la nuit"}, correct = 2 },
    { q = "Peut-on rouler sur le trottoir ?", answers = {"Oui si on va vite", "Non c'est interdit", "Seulement en marche arrière", "Oui le dimanche"}, correct = 1 },
    { q = "Que doit-on faire à un stop ?", answers = {"Accélérer", "S'arrêter complètement", "Klaxonner", "Fermer les yeux"}, correct = 1 },
    { q = "Peut-on conduire sans permis ?", answers = {"Oui si on conduit bien", "Non c'est interdit", "Seulement le mardi", "Oui en ville"}, correct = 1 },
    { q = "Que fait-on quand un piéton traverse ?", answers = {"On accélère", "On klaxonne", "On s'arrête et on le laisse passer", "On le contourne"}, correct = 2 },
    { q = "Peut-on griller un feu rouge ?", answers = {"Oui si personne ne regarde", "Non jamais", "Seulement la nuit", "Oui en urgence"}, correct = 1 },
    { q = "À quoi sert le clignotant ?", answers = {"À rien", "À faire joli", "À indiquer qu'on tourne", "À aller plus vite"}, correct = 2 },
    { q = "Peut-on téléphoner en conduisant ?", answers = {"Oui toujours", "Non c'est dangereux", "Seulement en ville", "Seulement en reculant"}, correct = 1 },
    { q = "Que signifie un panneau STOP ?", answers = {"Accélérer", "Tourner à gauche", "S'arrêter", "Klaxonner"}, correct = 2 },
    { q = "Où doit-on garer son véhicule ?", answers = {"Sur la route", "Sur un parking ou place autorisée", "Sur le trottoir", "N'importe où"}, correct = 1 },
    { q = "Doit-on respecter les limitations de vitesse ?", answers = {"Non si on est pressé", "Oui toujours", "Seulement devant la police", "Non en ville"}, correct = 1 },
    { q = "Peut-on faire demi-tour sur l'autoroute ?", answers = {"Oui quand on veut", "Non c'est interdit et dangereux", "Oui si on roule vite", "Seulement la nuit"}, correct = 1 },
    { q = "Que doit-on vérifier avant de démarrer ?", answers = {"La radio", "Les rétroviseurs et la ceinture", "La couleur de la voiture", "Rien du tout"}, correct = 1 },
    { q = "Peut-on doubler par la droite ?", answers = {"Oui toujours", "Non c'est interdit", "Seulement les camions", "Oui en ville"}, correct = 1 },
    { q = "Que fait-on en cas d'accident ?", answers = {"On s'enfuit", "On appelle les secours", "On continue sa route", "On klaxonne"}, correct = 1 },
    { q = "Doit-on allumer ses phares la nuit ?", answers = {"Non on voit très bien", "Oui c'est obligatoire", "Seulement en ville", "Seulement s'il pleut"}, correct = 1 },
    { q = "Qui a la priorité au rond-point ?", answers = {"Celui qui va le plus vite", "Celui qui est déjà dans le rond-point", "Celui qui klaxonne", "Le plus gros véhicule"}, correct = 1 },
}
