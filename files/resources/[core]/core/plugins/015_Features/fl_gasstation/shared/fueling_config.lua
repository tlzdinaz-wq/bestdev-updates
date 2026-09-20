---@meta _
---@diagnostic disable: duplicate-doc-field

-- Configuration pour le système de remplissage manuel

FuelingConfig = {
    -- Temps de remplissage
    TimePerLiter = 3.5, -- Secondes par litre d'essence (plus réaliste)

    -- Distance de détection pour commencer le remplissage
    VehicleInteractionDistance = 3.0,

    -- Distance maximale avec fuel nozzle avant annulation automatique
    MaxFuelNozzleDistance = 8.0,

    -- Animation du joueur pendant le remplissage
    FuelingAnimation = {
        dict = "timetable@gardener@filling_can",
        name = "gar_ig_5_filling_can",
        flag = 50 -- ANIM_FLAG_REPEAT (flag 50 comme LegacyFuel)
    },

    -- Objet pompe à essence
    PumpObject = {
        model = "prop_cs_fuel_nozle", -- Pistolet de pompe à essence
        bone = 0x49D9, -- Main gauche (LH_Hand)
        offset = vector3(0.1, 0.02, 0.02),
        rotation = vector3(120.0, 100.0, 150.0) -- Valeurs ajustées
    },

    -- Côtés du véhicule où se trouve généralement le réservoir
    FuelCapSides = {
        -- La plupart des véhicules ont le réservoir à droite
        default = "right",
        -- Véhicules spéciaux avec réservoir à gauche
        leftSide = {
            -- Ajouter les hash de modèles si nécessaire
        }
    },

    -- Interface de progression
    ProgressBar = {
        updateInterval = 100, -- Mise à jour toutes les 100ms pour fluidité
        colors = {
            background = "#1a1a1a",
            progress = "#4CAF50",
            text = "#ffffff"
        }
    },

    -- Messages d'instruction
    Messages = {
        approachVehicle = "Approchez-vous de votre véhicule pour faire le plein",
        startFueling = "~g~[E]~w~ Commencer le remplissage",
        fueling = "Remplissage en cours... Ne bougez pas !",
        completed = "Remplissage terminé !"
    }
}