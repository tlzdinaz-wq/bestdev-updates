---@meta _
---@diagnostic disable: duplicate-doc-field

Config = Config or {}
Config.DVM = {
    -- Global Configuration
    General = {
        CodePassingScore = 80,            -- Minimum Score (to 100)
        DrivingPassingScore = 85,         -- Minimum Score (to 100)
        MaxAttempts = 3,                  -- Maximum attempts per day
        CooldownBetweenAttempts = 300000, -- Cooldown between attempts (5 minutes)
        ExamCost = {
            code = 500,                   -- Code price
            driving = 1000                -- Driving price
        },
        -- Bribe/Corruption System
        BribeSystem = {
            enabled = true,                -- Enable the bribe system
            codeExamBribe = 2500,          -- Bribe amount for code exam (5x exam cost)
            drivingExamBribe = 5000,       -- Bribe amount for driving exam (5x exam cost)
            successRate = 100,             -- Chance of bribe success (%)
            minScore = 0                   -- Minimum score required to attempt bribe (0 = no minimum)
        }
    },

    -- Available license types
    LicenseTypes = {
        car = {
            label = "Permis Voiture",
            description = "Permis de conduire pour véhicules légers",
            icon = "car",
            vehicleClass = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, -- Allowed vehicle classes
            examVehicle = "blista",                          -- Vehicle used for the exam
            instructorModel = "csb_popov",                    -- NPC instructor model
            codeQuestions = 40,                              -- Number of questions for the code
            drivingTime = 600000                             -- Driving exam duration (10 minutes)
        },
        motorcycle = {
            label = "Permis Moto",
            description = "Permis de conduire pour motocycles",
            icon = "motorcycle",
            vehicleClass = { 8 }, -- Only motorcycles
            examVehicle = "pcj",
            instructorVehicle = "pcj", -- Same motorcycle as the student
            instructorModel = "csb_popov",
            codeQuestions = 30,
            drivingTime = 480000 -- Driving exam duration (8 minutes)
        },
        truck = {
            label = "Permis Poids Lourd",
            description = "Permis de conduire pour véhicules lourds",
            icon = "truck",
            vehicleClass = { 14, 15, 16 }, -- Commercial and industrial vehicles
            examVehicle = "mule",
            instructorModel = "s_m_y_cop_01",
            codeQuestions = 50,
            drivingTime = 900000,     -- Driving exam duration (15 minutes)
            prerequisites = { "car" } -- Requires the car license
        }
    },

    -- Exam centers (positions dans core/config/dvm/config.lua)
    ExamCenters = (DVMConfig and DVMConfig.ExamCenters) or {},

    -- Driving exam routes
    DrivingRoutes = {
        car = {
            {
                name = "Permis voiture",
                description = "Permis voiture",
                examCenter = 1,
                checkpoints = {
                    { coords = vector3(213.05, -1415.14, 28.25), speed = 50 },
                    { coords = vector3(219.44, -1303.74, 28.33), speed = 50 },
                    { coords = vector3(225.90, -1158.82, 28.23), speed = 50 },
                    { coords = vector3(485.95, -1134.86, 28.38), speed = 50 },
                    { coords = vector3(533.02, -1409.49, 28.27), speed = 50 },
                    { coords = vector3(354.34, -1332.56, 31.54), speed = 50 },
                    { coords = vector3(248.01, -1432.14, 28.18), speed = 50 },
                    { coords = vector3(215.89, -1381.32, 29.56), speed = 50 },
                },
                evaluation = {
                    speedLimit = true,
                    trafficLights = true,
                    indicators = true,
                    parking = true,
                    smoothness = true,
                    safety = true
                }
            },
            {
                name = "Paleto",
                description = "Entrainement",
                examCenter = 2,
                checkpoints = {
                    { coords = vector3(-263.70, 6276.94, 30.37), speed = 50 },
                    { coords = vector3(-303.57, 6238.12, 30.45), speed = 50 },
                    { coords = vector3(-358.44, 6300.18, 28.89), speed = 50 },
                    { coords = vector3(-260.56, 6387.98, 29.91), speed = 50 },
                    { coords = vector3(-180.60, 6465.06, 29.64), speed = 50 },
                    { coords = vector3(-125.99, 6430.42, 30.45), speed = 50 },
                    { coords = vector3(68.86, 6598.72, 30.38), speed = 50 },
                    { coords = vector3(140.68, 6538.78, 30.69), speed = 50 },
                    { coords = vector3(-98.27, 6288.62, 30.35), speed = 50 },
                    { coords = vector3(-171.36, 6360.16, 30.48), speed = 50 },
                    { coords = vector3(-259.26, 6281.29, 30.37), speed = 50 },
                },
                evaluation = {
                    speedLimit = true,
                    trafficLights = true,
                    indicators = true,
                    parking = true,
                    smoothness = true,
                    safety = true
                }
            }
        },
        motorcycle = {
            {
                name = "Permis moto",
                description = "Permis moto",
                examCenter = 1,
                checkpoints = {
                    { coords = vector3(213.05, -1415.14, 28.25), speed = 50 },
                    { coords = vector3(219.44, -1303.74, 28.33), speed = 50 },
                    { coords = vector3(225.90, -1158.82, 28.23), speed = 50 },
                    { coords = vector3(485.95, -1134.86, 28.38), speed = 50 },
                    { coords = vector3(533.02, -1409.49, 28.27), speed = 50 },
                    { coords = vector3(354.34, -1332.56, 31.54), speed = 50 },
                    { coords = vector3(248.01, -1432.14, 28.18), speed = 50 },
                    { coords = vector3(215.89, -1381.32, 29.56), speed = 50 },
                },
                evaluation = {
                    speedLimit = true,
                    trafficLights = true,
                    indicators = true,
                    parking = true,
                    smoothness = true,
                    safety = true
                }
            },
            {
                name = "Paleto",
                description = "Entrainement",
                examCenter = 2,
                checkpoints = {
                    { coords = vector3(-263.70, 6276.94, 30.37), speed = 50 },
                    { coords = vector3(-303.57, 6238.12, 30.45), speed = 50 },
                    { coords = vector3(-358.44, 6300.18, 28.89), speed = 50 },
                    { coords = vector3(-260.56, 6387.98, 29.91), speed = 50 },
                    { coords = vector3(-180.60, 6465.06, 29.64), speed = 50 },
                    { coords = vector3(-125.99, 6430.42, 30.45), speed = 50 },
                    { coords = vector3(68.86, 6598.72, 30.38), speed = 50 },
                    { coords = vector3(140.68, 6538.78, 30.69), speed = 50 },
                    { coords = vector3(-98.27, 6288.62, 30.35), speed = 50 },
                    { coords = vector3(-171.36, 6360.16, 30.48), speed = 50 },
                    { coords = vector3(-259.26, 6281.29, 30.37), speed = 50 },
                },
                evaluation = {
                    speedLimit = true,
                    trafficLights = true,
                    indicators = true,
                    parking = true,
                    smoothness = true,
                    safety = true
                }
            }
        },
        truck = {
            {
                name = "Permis poids lourd",
                description = "Permis poids lourd",
                examCenter = 1,
                checkpoints = {
                    { coords = vector3(213.05, -1415.14, 28.25), speed = 50 },
                    { coords = vector3(219.44, -1303.74, 28.33), speed = 50 },
                    { coords = vector3(225.90, -1158.82, 28.23), speed = 50 },
                    { coords = vector3(485.95, -1134.86, 28.38), speed = 50 },
                    { coords = vector3(533.02, -1409.49, 28.27), speed = 50 },
                    { coords = vector3(354.34, -1332.56, 31.54), speed = 50 },
                    { coords = vector3(248.01, -1432.14, 28.18), speed = 50 },
                    { coords = vector3(215.89, -1381.32, 29.56), speed = 50 },
                },
                evaluation = {
                    speedLimit = true,
                    trafficLights = true,
                    indicators = true,
                    parking = true,
                    smoothness = true,
                    safety = true
                }
            },
            {
                name = "Camion paletto",
                description = "Camion",
                examCenter = 2,
                checkpoints = {
                    { coords = vector3(-263.70, 6276.94, 30.37), speed = 50 },
                    { coords = vector3(-303.57, 6238.12, 30.45), speed = 50 },
                    { coords = vector3(-358.44, 6300.18, 28.89), speed = 50 },
                    { coords = vector3(-260.56, 6387.98, 29.91), speed = 50 },
                    { coords = vector3(-180.60, 6465.06, 29.64), speed = 50 },
                    { coords = vector3(-125.99, 6430.42, 30.45), speed = 50 },
                    { coords = vector3(68.86, 6598.72, 30.38), speed = 50 },
                    { coords = vector3(140.68, 6538.78, 30.69), speed = 50 },
                    { coords = vector3(-98.27, 6288.62, 30.35), speed = 50 },
                    { coords = vector3(-171.36, 6360.16, 30.48), speed = 50 },
                    { coords = vector3(-259.26, 6281.29, 30.37), speed = 50 },
                },
                evaluation = {
                    speedLimit = true,
                    trafficLights = true,
                    indicators = true,
                    parking = true,
                    smoothness = true,
                    safety = true
                }
            }
        }
    },

    -- Messages and instructions
    Messages = {
        WelcomeToExam = "Bienvenue à l'examen du permis de conduire",
        CodeExamStart = "L'examen du code va commencer. Vous avez %d questions.",
        DrivingExamStart = "L'examen de conduite va commencer. Suivez les instructions de l'instructeur.",
        ExamPassed = "Félicitations ! Vous avez réussi votre examen.",
        ExamFailed = "Vous avez échoué à l'examen. Vous pourrez repasser dans %d minutes.",
        InsufficientFunds = "Vous n'avez pas assez d'argent pour passer l'examen.",
        AlreadyHasLicense = "Vous possédez déjà ce permis.",
        PrerequisitesMissing = "Vous devez d'abord obtenir le permis : %s",
        MaxAttemptsReached = "Vous avez atteint le nombre maximum de tentatives pour aujourd'hui."
    },

    -- Driving instructions
    DrivingInstructions = {
        TurnLeft = "Tournez à gauche au prochain carrefour",
        TurnRight = "Tournez à droite au prochain carrefour",
        GoStraight = "Continuez tout droit",
        SlowDown = "Ralentissez",
        SpeedUp = "Accélérez légèrement",
        Stop = "Arrêtez-vous",
        Park = "Garez-vous ici",
        UTurn = "Effectuez un demi-tour",
        UseIndicator = "N'oubliez pas vos clignotants",
        CheckMirrors = "Vérifiez vos rétroviseurs",
        Reverse = "Effectuez une marche arrière"
    }
}