---@meta _
---@diagnostic disable: duplicate-doc-field

-- Configuration partagée pour les stations d'essence
GasStationConfig = {}

-- Plage de prix aléatoire pour l'essence
GasStationConfig.PriceRange = {
    min = 100,  -- Prix minimum par litre
    max = 250   -- Prix maximum par litre
}

-- Modèles de pompes à essence supportés
GasStationConfig.GasPumpModels = {
    `prop_gas_pump_1a`,
    `prop_gas_pump_1b`,
    `prop_gas_pump_1c`,
    `prop_gas_pump_1d`,
    `prop_gas_pump_old1`,
    `prop_gas_pump_old2`,
    `prop_gas_pump_old3`,
    `prop_vintage_pump`,
    `prop_gas_bowser1`,
    `amb_rox_caspump_pf`,
}

-- Distance de détection des pompes et véhicules
GasStationConfig.PumpDetectionRadius = 3.0      -- Distance pour que le joueur puisse interagir avec la pompe
GasStationConfig.VehicleDetectionRadius = 5.0   -- Distance pour détecter les véhicules près de la pompe

-- Distance maximale pour scanner les props de pompes
GasStationConfig.ScanRadius = 25.0

-- Configuration des blips
GasStationConfig.BlipConfig = {
    sprite = 361,  -- Icône de station essence
    color = 1,
    scale = 0.5,
    name = "Station Essence"
}

-- Paramètres de validation
GasStationConfig.MinFuelToFillUp = 5.0    -- Minimum de carburant manquant pour autoriser le remplissage
GasStationConfig.MaxFuelLevel = 100.0      -- Niveau maximum de carburant

-- Messages d'erreur
GasStationConfig.Messages = {
    EngineRunning = "Éteignez le moteur avant de faire le plein!",
    TankFull = "Le réservoir est déjà plein!",
    NoVehicle = "Aucun véhicule détecté près de cette pompe.",
    NoMoney = "Vous n'avez pas assez d'argent!",
    PurchaseSuccess = "Vous avez acheté %d litres pour $%.2f"
}

-- Protection des pompes contre explosions
GasStationConfig.PumpProtection = {
    enabled = true,                    -- Activer/désactiver la protection
    scanInterval = 5000,               -- Intervalle de scan en ms (5 secondes)
    searchRadius = 5.0,                -- Rayon pour trouver l'entité de pompe (augmenté de 1.5 à 5.0 pour meilleure détection)
    protectionRadius = 75.0,           -- Protège les pompes dans ce rayon du joueur
    debugMode = true,                  -- Activer les logs de debug (temporairement activé pour vérifier le fix en prod)
    immunitySettings = {
        bullet = true,                -- Permettre les dégâts de balles
        fire = true,                   -- Immunisé contre le feu
        explosion = true,              -- Immunisé contre les explosions
        collision = true,             -- Permettre les dégâts de collision
        melee = true,                 -- Permettre les dégâts de mêlée
        steam = true,
        p7 = true,                     -- Immunité feu supplémentaire
        p8 = true,                     -- Immunité explosion supplémentaire
        drown = true
    }
}