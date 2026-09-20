---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- CONFIGURATION MARKET
-- ============================================================

-- Éviter d'écraser la configuration d'autres modules
Config = Config or {}

-- Modèle du PED vendeur
Config.PedModel    = "a_m_y_business_02"
Config.PedScenario = "WORLD_HUMAN_CLIPBOARD"

-- Prop lâché lors d'un achat
Config.DropProp = {
    model          = "prop_boxpile_06b",
    dropOnPurchase = true
}

-- Distance d'interaction avec le PED (mètres)
Config.InteractionDistance = 2.5

-- Emplacements des 3 Markets
Config.Locations = {
    {
        name      = "Space Market 1",
        pedCoords = vector4(2736.725342, 3477.296631, 55.666626, 252.283463),
        dropCoords = vector4(2700.05, 3470.98, 56.23, 0.0)
    },
    {
        name      = "Space Market 2",
        pedCoords = vector4(51.54, -1753.73, 29.12, 52.29),
        dropCoords = vector4(93.67, -1797.93, 27.07, 230.17)
    },
    {
        name      = "Space Market 3",
        pedCoords = vector4(-61.58, 6519.15, 31.49, 316.06),
        dropCoords = vector4(-88.59, 6500.53, 31.49, 240.06)
    }
}

-- Configuration du magasin
Config.Shop = {
    name  = "Space Market",
    phone = "555-MARKET",
    logo  = BRANDING.cdnBase .. "/shops/logos/spacemarket.svg",

    -- Catégories (chargées depuis la BDD ou `society.custom.spacemarket`)
    categories = {},

    -- Items (chargés depuis la BDD ou `society.custom.spacemarket`)
    items = {}
}
