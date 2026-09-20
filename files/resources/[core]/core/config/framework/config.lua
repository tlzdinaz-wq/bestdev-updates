---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Config Configuration table
---@field Features table
---@field CustomInventory boolean
---@field Accounts any
---@field StartingAccountMoney table
---@field StartingInventoryItems any
---@field DefaultSpawns any
---@field EnableSocietyPayouts any
---@field MaxWeight any
---@field PaycheckInterval any
---@field SaveDeathStatus any
---@field EnableDebug any
---@field DefaultJobDuty any
---@field OffDutyPaycheckMultiplier any
---@field Multichar any
---@field Identity any
---@field DistanceGive any
---@field AdminLogging any
Config = {}
Config.Features = {}

-- Pour ox_inventory, cette valeur est ajustée automatiquement. Pour d'autres inventaires, changer en "resource_name"
Config.CustomInventory = false

Config.Accounts = {
    bank        = { label = "Banque",      round = true },
    black_money = { label = "Argent sale", round = true },
}

-- Argent de départ attribué à un nouveau personnage
Config.StartingAccountMoney = { bank = 2000 }

-- Table d'items ou false (aucun item de départ)
Config.StartingInventoryItems = false

-- Position(s) de spawn par défaut
Config.DefaultSpawns = {
    { x = 222.2027, y = -864.0162, z = 30.2922, heading = 1.0 }
    -- { x = 224.9865, y = -865.0871, z = 30.2922, heading = 1.0 },
    -- { x = 227.8436, y = -866.0400, z = 30.2922, heading = 1.0 },
    -- { x = 230.6051, y = -867.1450, z = 30.2922, heading = 1.0 },
    -- { x = 233.5459, y = -868.2626, z = 30.2922, heading = 1.0 }
}

-- Payer depuis la caisse de la société employeuse ? (nécessite VFW_society)
Config.EnableSocietyPayouts = false

-- Poids max de l'inventaire sans sac à dos
Config.MaxWeight = 5000

-- Intervalle de paye en millisecondes (15 minutes)
Config.PaycheckInterval = 15 * 60000

-- Sauvegarder le statut de mort du joueur
Config.SaveDeathStatus = true

-- Activer les logs de debug
Config.EnableDebug = false

-- Statut de service par défaut lors d'un changement de job
Config.DefaultJobDuty = false

-- Multiplicateur de paye hors-service (0.5 = 50% de la paye en service)
Config.OffDutyPaycheckMultiplier = 0.5

-- Activer le système de multicaractère
Config.Multichar = true

-- Demander les données d'identité avant de charger (actif par défaut avec multichar)
Config.Identity = true

-- Distance maximale pour donner des items / armes
Config.DistanceGive = 4.0

-- Logger les commandes utilisées par les membres group.admin (false par défaut)
Config.AdminLogging = false
