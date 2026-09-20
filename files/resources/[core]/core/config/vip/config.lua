---@meta _
-- ============================================================
-- CONFIG - Système VIP
-- Définit les paliers, avantages et restrictions VIP.
-- ============================================================

VIPConfig = {}

-- Paliers VIP (id, nom, label, couleur HEX)
VIPConfig.Tiers = {
    [0] = { id = 0, name = "Aucun VIP",  label = "Non-VIP",    color = "#808080" },
    [1] = { id = 1, name = "vip_bronze", label = "VIP Bronze", color = "#CD7F32" },
    [2] = { id = 2, name = "vip_silver", label = "VIP Silver", color = "#C0C0C0" },
    [3] = { id = 3, name = "vip_gold",   label = "VIP Gold",   color = "#FFD700" },
}

-- Pièces mensuelle offertes le 1er de chaque mois
VIPConfig.MonthlyCoins = {
    [0] = 0,
    [1] = 500,
    [2] = 1000,
    [3] = 1500,
}

-- Limite de poids inventaire (kg)
VIPConfig.InventoryWeight = {
    [0] = 30,
    [1] = 40,
    [2] = 50,
    [3] = 60,
}

-- Aide d'état / RSA (en $ toutes les X minutes)
VIPConfig.StateAid = {
    base = {
        enabled      = true,
        amount       = 1000,
        interval     = 30,
        requireNoJob = true,
    },
    vip = {
        enabled      = true,
        interval     = 30,
        requireNoJob = false,
        amounts = {
            [1] = 3000,
            [2] = 4000,
            [3] = 5000,
        },
    },
}

-- Pièces horaires (toutes les X minutes pour les VIP en ligne)
VIPConfig.HourlyCoins = {
    enabled  = true,
    interval = 60,
    amounts = {
        [1] = 10,
        [2] = 20,
        [3] = 30,
    },
}

-- Remise fourrière (%)
VIPConfig.ImpoundDiscount = {
    [0] = 0,
    [1] = 30,
    [2] = 40,
    [3] = 50,
}

-- Nombre de slots de personnage par palier
VIPConfig.CharacterSlots = {
    [0] = 2,
    [1] = 2,
    [2] = 2,
    [3] = 2,
}

-- Limites de props (permanents / temporaires)
VIPConfig.PropsLimits = {
    [0] = { permanent = 0,  temporary = 0  },
    [1] = { permanent = 10, temporary = 5  },
    [2] = { permanent = 20, temporary = 10 },
    [3] = { permanent = 30, temporary = 15 },
}

-- Bonus capacité coffre véhicule (%)
VIPConfig.TrunkBonus = {
    [0] = 0,
    [1] = 30,
    [2] = 50,
    [3] = 100,
}

-- Bonus stockage dynasty (%)
VIPConfig.DynastyBonus = {
    [0] = 0,
    [1] = 30,
    [2] = 50,
    [3] = 100,
}

-- Bonus par type de boulot
VIPConfig.JobBonuses = {
    interim = {
        enabled          = true,
        bonusType        = "double",
        doubleMultiplier = 2,
        speedMultiplier  = { [1] = 1.3, [2] = 1.7, [3] = 2.0 },
        minVipTier       = 1,
    },
    gofast = {
        enabled         = true,
        speedMultiplier = { [1] = 1.2, [2] = 1.5, [3] = 1.8 },
        minVipTier      = 1,
    },
    drugDealing = {
        enabled         = true,
        speedMultiplier = { [1] = 1.15, [2] = 1.3, [3] = 1.5 },
        minVipTier      = 1,
    },
    fishing = {
        enabled     = true,
        autoEnabled = true,
        minVipTier  = 1,
    },
}

-- Location mensuelle de véhicule (véhicules configurés dans le paidshop)
VIPConfig.MonthlyVehicle = {
    enabled = true,
}

-- Permis de port d'armes (PPA)
VIPConfig.WeaponPermit = {
    enabled        = true,
    minVipTier     = 1,
    permitPrefix   = "PPA",
    documentType   = "weapon_permit",
}

-- Items nécessitant un palier VIP minimum
VIPConfig.RestrictedItems = {
    boombox = {
        enabled    = true,
        minVipTier = 1,
        message    = "Vous devez être VIP 1 ou plus pour utiliser le Boombox",
    },
}

-- Commandes réservées aux VIP
VIPConfig.RestrictedCommands = {}

-- Intégration Discord (sync rôles)
VIPConfig.Discord = {
    enabled = false,
    roles = {
        [1] = "1234567890",
        [2] = "1234567891",
        [3] = "1234567892",
    },
}

-- Intégration Tebex (produits → paliers VIP)
VIPConfig.Tebex = {
    enabled         = true,
    packages        = {},
    coinPackages    = {},
    defaultDuration = 30,
}

-- Temps de respawn sans EMS (secondes)
VIPConfig.RespawnTime = {
    [0] = 600,
    [1] = 480,
    [2] = 300,
    [3] = 180,
}

-- Changements de plaque par mois
VIPConfig.PlateChangesPerMonth = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
}

-- Véhicule d'urgence personnel (modèle par palier)
VIPConfig.EmergencyVehicle = {
    [0] = nil,
    [1] = { model = "faggio", label = "Faggio"   },
    [2] = { model = "bati",   label = "Bati 801" },
    [3] = { model = "akuma",  label = "Akuma"    },
}

-- Réduction de la saleté des véhicules VIP
VIPConfig.VehicleDirt = {
    enabled      = true,
    interval     = 10000,
    idleInterval = 2000,
    reductionFactor = {
        [0] = 0.0,
        [1] = 0.3,
        [2] = 0.5,
        [3] = 0.7,
    },
}

-- Personnalisation d'armes (teintes & skins)
VIPConfig.WeaponCustomization = {
    enabled    = true,
    minVipTier = 1,
}

-- Caméra libre (freecam)
VIPConfig.Freecam = {
    enabled    = true,
    minVipTier = 1,
}

-- Fonctionnalités futures
VIPConfig.AdditionalFeatures = {
    publicOutfits = { enabled = false, minVipTier = 1 },
    apartmentTV   = { enabled = false, minVipTier = 1 },
}

-- Vérification de l'expiration VIP
VIPConfig.ExpiryCheck = {
    interval        = 60000,
    immediateRemoval = true,
}

-- Suivi GPS du véhicule spawné
VIPConfig.VehicleTracking = {
    enabled      = true,
    minVipTier   = 1,
    blipSprite   = 225,
    blipColor    = 3,
    blipScale    = 0.5,
    showRoute    = true,
    blipDuration = 60000,
}

-- ============================================================
-- Fonctions utilitaires
-- ============================================================

function VIPConfig.GetTierName(tier)
    return VIPConfig.Tiers[tier] and VIPConfig.Tiers[tier].name or "Unknown"
end

function VIPConfig.GetTierLabel(tier)
    return VIPConfig.Tiers[tier] and VIPConfig.Tiers[tier].label or "N/A"
end

function VIPConfig.HasMinimumTier(playerTier, requiredTier)
    return playerTier >= requiredTier
end

function VIPConfig.GetInventoryWeight(tier)
    return VIPConfig.InventoryWeight[tier] or VIPConfig.InventoryWeight[0]
end

function VIPConfig.GetImpoundDiscount(tier)
    return VIPConfig.ImpoundDiscount[tier] or 0
end

function VIPConfig.GetCharacterSlots(tier)
    return VIPConfig.CharacterSlots[tier] or 1
end

function VIPConfig.GetPropsLimits(tier)
    return VIPConfig.PropsLimits[tier] or VIPConfig.PropsLimits[0]
end

function VIPConfig.GetMonthlyCoins(tier)
    return VIPConfig.MonthlyCoins[tier] or 0
end

function VIPConfig.GetTrunkBonus(tier)
    return VIPConfig.TrunkBonus[tier] or 0
end

function VIPConfig.GetDynastyBonus(tier)
    return VIPConfig.DynastyBonus[tier] or 0
end

function VIPConfig.GetStateAidAmount(tier)
    if tier == 0 then
        return VIPConfig.StateAid.base.amount
    end
    return VIPConfig.StateAid.vip.amounts[tier] or 0
end

function VIPConfig.GetHourlyCoins(tier)
    return VIPConfig.HourlyCoins.amounts[tier] or 0
end

function VIPConfig.GetInterimSellMultiplier(vipTier)
    local cfg = VIPConfig.JobBonuses.interim
    if cfg.enabled and vipTier >= cfg.minVipTier then
        return cfg.speedMultiplier[vipTier] or 1
    end
    return 1
end

function VIPConfig.GetGofastMultiplier(vipTier)
    local cfg = VIPConfig.JobBonuses.gofast
    if cfg.enabled and vipTier >= cfg.minVipTier then
        return cfg.speedMultiplier[vipTier] or 1
    end
    return 1
end

function VIPConfig.GetDrugDealingMultiplier(vipTier)
    local cfg = VIPConfig.JobBonuses.drugDealing
    if cfg.enabled and vipTier >= cfg.minVipTier then
        return cfg.speedMultiplier[vipTier] or 1
    end
    return 1
end
