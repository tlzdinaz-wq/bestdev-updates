---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIGURATION ZONE AFK
-- Instances isolées avec routing buckets + système de points
-- ============================================================

AFKConfig = {}

-- =========================================================
-- INSTANCES (ROUTING BUCKETS)
-- =========================================================
AFKConfig.Instances = {
    bucketStart = 10000, -- Premier bucket disponible pour la zone AFK
    bucketEnd   = 10999, -- Dernier bucket (1 000 slots max)
}

-- =========================================================
-- POSITION
-- =========================================================
AFKConfig.Position = {
    coords         = vector3(482.707977, 4813.277344, -58.384243),
    heading        = 180.0,
    boundaryRadius = 250.0, -- Téléportation de retour si le joueur dépasse ce rayon
}

-- =========================================================
-- POINTS
-- =========================================================
AFKConfig.Points = {
    pointsPerMinute = 1,     -- Points gagnés par minute dans la zone AFK
    intervalMs      = 60000, -- Intervalle en ms (60 000 = 1 minute)
}

-- =========================================================
-- LEADERBOARD
-- =========================================================
AFKConfig.Leaderboard = {
    enabled  = true,
    topCount = 3, -- Nombre de joueurs en tête affichés

    -- Prop du podium (position absolue)
    podium = {
        model    = "xs_prop_arena_podium_03a",
        position = vector3(480.189, 4821.932, -58.402),
        rotation = vector3(0.0, 0.0, 15.0),
    },

    -- Positions des NPCs sur le podium (positions absolues)
    npcPositions = {
        [1] = { position = vector3(480.195, 4821.876, -58.939), heading = 198.14 }, -- 1ère place
        [2] = { position = vector3(479.419, 4821.604, -59.042), heading = 198.14 }, -- 2ème place
        [3] = { position = vector3(480.990, 4822.012, -59.050), heading = 198.14 }, -- 3ème place
    },

    -- Modèle NPC par défaut si le skin du joueur n'est pas chargé
    defaultModel = "a_m_y_hipster_01",
}

-- =========================================================
-- NPC SORTIE
-- =========================================================
AFKConfig.ExitNPC = {
    model             = "a_m_y_soucent_01",
    position          = vector3(474.267, 4816.361, -58.384),
    heading           = 285.02,
    interactionRadius = 2.0,
}

-- =========================================================
-- NPC CLASSEMENT VIP (visible uniquement dans la zone AFK)
-- =========================================================
AFKConfig.RankingNPC = {
    model             = "a_m_m_business_01",
    position          = vector3(487.18, 4799.27, -59.38),
    heading           = 24.39,
    interactionRadius = 2.0,
    maxEntries        = 50,
}

-- =========================================================
-- BOUTIQUE
-- =========================================================
AFKConfig.Shop = {
    enabled = true,

    npc = {
        model             = "a_f_y_business_01",
        position          = vector3(478.0, 4808.0, -58.384),
        heading           = 0.0,
        interactionRadius = 2.5,
    },

    cases = {
        -- ----------------------------------------
        -- CAISSE AFK GOLD — 2 000 points
        -- ----------------------------------------
        gold = {
            itemName    = "afk_case_gold",
            name        = "Caisse AFK Gold",
            description = "Une caisse classique avec de belles récompenses en argent et objets utiles.",
            price       = 2000,
            image       = BRANDING.cdnBase .. "/boutique/box.svg",
            prizes = {
                -- Commun (75 %)
                { type = "money",  name = "25 000$",  amount = 25000,  rarity = 1, chance = 25 },
                { type = "money",  name = "50 000$",  amount = 50000,  rarity = 1, chance = 20 },
                { type = "item",   name = "Pain x50", itemName = "bread", count = 50, rarity = 1, chance = 15 },
                { type = "item",   name = "Eau x50",  itemName = "water", count = 50, rarity = 1, chance = 15 },
                -- Peu commun (18 %)
                { type = "money",  name = "100 000$",  amount = 100000,  rarity = 2, chance = 10 },
                { type = "money",  name = "250 000$",  amount = 250000,  rarity = 2, chance = 8  },
                -- Rare (6 %)
                { type = "weapon", name = "Pistolet 9mm", itemName = "weapon_pistol", rarity = 3, chance = 4 },
                { type = "money",  name = "500 000$", amount = 500000, rarity = 3, chance = 2 },
                -- Légendaire (1 %)
                { type = "money",  name = "1 000 000$", amount = 1000000, rarity = 4, chance = 1 },
            }
        },

        -- ----------------------------------------
        -- CAISSE AFK LÉGENDAIRE — 6 000 points
        -- ----------------------------------------
        legendary = {
            itemName    = "afk_case_legendary",
            name        = "Caisse AFK Légendaire",
            description = "La caisse ultime ! Contient des récompenses exceptionnelles : armes rares et véhicules.",
            price       = 6000,
            image       = BRANDING.cdnBase .. "/boutique/box.svg",
            prizes = {
                -- Commun (35 %)
                { type = "money", name = "100 000$",   amount = 100000, rarity = 1, chance = 15 },
                { type = "item",  name = "Pain x100",  itemName = "bread", count = 100, rarity = 1, chance = 10 },
                { type = "item",  name = "Eau x100",   itemName = "water", count = 100, rarity = 1, chance = 10 },
                -- Peu commun (27 %)
                { type = "money", name = "250 000$",   amount = 250000, rarity = 2, chance = 15 },
                { type = "money", name = "500 000$",   amount = 500000, rarity = 2, chance = 12 },
                -- Rare (26 %)
                { type = "weapon", name = "Micro Uzi",   itemName = "weapon_microsmg",      rarity = 3, chance = 8  },
                { type = "money",  name = "750 000$",    amount = 750000,                   rarity = 3, chance = 10 },
                { type = "money",  name = "1 000 000$",  amount = 1000000,                  rarity = 3, chance = 8  },
                -- Légendaire (12 %)
                { type = "weapon",  name = "AK Compact", itemName = "weapon_specialcarbine", rarity = 4, chance = 4 },
                { type = "money",   name = "3 000 000$", amount = 3000000,                   rarity = 4, chance = 3 },
                { type = "vehicle", name = "Elegy RH8",  vehicleModel = "elegy2",            rarity = 4, chance = 2 },
                { type = "vehicle", name = "Banshee",    vehicleModel = "banshee",           rarity = 4, chance = 2 },
                { type = "case",    name = "Caisse Diamond", itemName = "box_diamond",       rarity = 4, chance = 1 },
            }
        },
    }
}

-- =========================================================
-- RESTRICTIONS
-- =========================================================
AFKConfig.Restrictions = {
    noVehicle       = true,  -- Impossible d'entrer en véhicule
    noCuffed        = true,  -- Impossible d'entrer menotté
    requireSafeZone = true,  -- Doit être dans une zone safe pour entrer
}

-- =========================================================
-- FONCTIONS UTILITAIRES
-- =========================================================

---@return vector3
function AFKConfig.GetPosition()
    return AFKConfig.Position.coords
end

---@return number
function AFKConfig.GetHeading()
    return AFKConfig.Position.heading
end

---Vérifie si un bucket appartient à la plage AFK.
---@param bucket number
---@return boolean
function AFKConfig.IsAFKBucket(bucket)
    return bucket >= AFKConfig.Instances.bucketStart and bucket <= AFKConfig.Instances.bucketEnd
end
