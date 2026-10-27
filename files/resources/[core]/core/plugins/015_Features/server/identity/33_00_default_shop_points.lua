--[[
    Points de magasins livrés avec la base : Ammu-Nation, superettes (24/7, LTD, Rob's Liquor),
    magasins de vêtements, coiffeurs et tatoueurs, aux emplacements d'origine de GTA.

    Posés UNE SEULE FOIS par serveur, et seulement si la table de ce type de magasin est vide :
      - un serveur qui a déjà ses magasins n'est jamais modifié ;
      - si le staff supprime ensuite tous les points, ils ne reviennent pas au redémarrage
        (table `default_seeds`).
    Les positions sont celles du joueur debout à l'endroit (comme un point posé avec les builders) ;
    le staff les ajuste ensuite dans Gestion > Builders.
]]

DefaultShopPoints = {}

local function vec(x, y, z, h) return { x = x, y = y, z = z, h = h or 0.0 } end

-- Vendeurs Ammu-Nation (position du vendeur derrière le comptoir).
local AMMUNATION = {
    { "Ammu-Nation - Little Seoul", vec(-661.96, -933.53, 21.83, 177.05) },
    { "Ammu-Nation - Cypress Flats", vec(809.68, -2159.13, 29.62, 1.43) },
    { "Ammu-Nation - Sandy Shores", vec(1692.67, 3761.38, 34.71, 227.65) },
    { "Ammu-Nation - Paleto Bay", vec(-331.23, 6085.37, 31.45, 228.02) },
    { "Ammu-Nation - Hawick", vec(253.63, -51.02, 69.94, 72.91) },
    { "Ammu-Nation - Pillbox Hill", vec(23.0, -1105.67, 29.8, 162.91) },
    { "Ammu-Nation - Tataviam", vec(2567.48, 292.59, 108.73, 349.68) },
    { "Ammu-Nation - Route 68", vec(-1118.59, 2700.05, 18.55, 221.89) },
    { "Ammu-Nation - La Mesa", vec(841.92, -1035.32, 28.19, 1.56) },
    { "Ammu-Nation - Morningwood", vec(-1304.19, -395.12, 36.7, 75.03) },
    { "Ammu-Nation - Chumash", vec(-3173.31, 1088.85, 20.84, 244.18) },
}

-- Superettes : position du vendeur (APU) derrière la caisse.
local SUPERMARKETS = {
    { "24/7 - Strawberry", vec(24.47, -1346.62, 29.5, 271.66) },
    { "24/7 - Banham Canyon", vec(-3039.54, 584.38, 7.91, 17.27) },
    { "24/7 - Chumash", vec(-3242.97, 1000.01, 12.83, 357.57) },
    { "24/7 - Mount Chiliad", vec(1728.07, 6416.63, 35.04, 247.45) },
    { "24/7 - Sandy Shores", vec(1959.82, 3740.48, 32.34, 301.57) },
    { "24/7 - Harmony", vec(549.13, 2670.85, 42.16, 99.39) },
    { "24/7 - Senora Freeway", vec(2677.47, 3279.76, 55.24, 335.08) },
    { "24/7 - Tataviam", vec(2556.66, 380.84, 108.62, 356.67) },
    { "24/7 - Vinewood", vec(372.66, 326.98, 103.57, 253.73) },
    { "LTD - Davis", vec(-47.02, -1758.23, 29.42, 45.05) },
    { "LTD - Little Seoul", vec(-706.06, -913.97, 19.22, 88.04) },
    { "LTD - Richman Glen", vec(-1820.02, 794.03, 138.09, 135.45) },
    { "LTD - Mirror Park", vec(1164.71, -322.94, 69.21, 101.72) },
    { "LTD - Grapeseed", vec(1697.87, 4922.96, 42.06, 324.71) },
    { "Rob's Liquor - Vespucci Canals", vec(-1221.58, -908.15, 12.33, 35.49) },
    { "Rob's Liquor - Morningwood", vec(-1486.59, -377.68, 40.16, 139.51) },
    { "Rob's Liquor - Banham Canyon", vec(-2966.39, 391.42, 15.04, 87.48) },
    { "Rob's Liquor - Grand Senora", vec(1165.17, 2710.88, 38.16, 179.43) },
    { "Rob's Liquor - El Burro Heights", vec(1134.2, -982.91, 46.42, 277.24) },
}

-- Table `shops` (Gestion > Builders > Magasins) : point d'interaction dans la boutique.
local SHOPS = {
    clothing = {
        blip = 73, color = 47,
        points = {
            vec(72.25, -1399.10, 29.38), vec(-703.78, -152.26, 37.42), vec(-167.86, -298.97, 39.73),
            vec(428.69, -800.11, 29.49), vec(-829.41, -1073.71, 11.33), vec(-1447.80, -242.46, 49.82),
            vec(11.63, 6514.22, 31.88), vec(123.65, -219.44, 54.56), vec(1696.29, 4829.31, 42.06),
            vec(618.09, 2759.63, 42.09), vec(1190.55, 2713.44, 38.22), vec(-1193.43, -772.26, 17.32),
            vec(-3172.50, 1048.13, 20.86), vec(-1108.44, 2708.92, 19.11),
        },
    },
    barber = {
        blip = 71, color = 0,
        points = {
            vec(-814.31, -183.82, 37.57), vec(136.83, -1708.37, 29.29), vec(-1282.60, -1116.76, 6.99),
            vec(1931.51, 3729.67, 32.84), vec(1212.84, -472.92, 66.21), vec(-32.89, -152.32, 57.08),
            vec(-278.08, 6228.46, 31.70),
        },
    },
    tattoo = {
        blip = 75, color = 1,
        points = {
            vec(1322.65, -1651.98, 52.28), vec(-1153.68, -1425.68, 4.95), vec(322.14, 180.47, 103.59),
            vec(-3170.07, 1075.06, 20.83), vec(1864.63, 3747.74, 33.03), vec(-293.71, 6200.04, 31.49),
        },
    },
}

local function exec(query, params)
    local ok, res = pcall(MySQL.update.await, query, params or {})
    if not ok then console.warn(("[default_shop_points] %s"):format(tostring(res))) end
    return ok
end

local function scalar(query, params)
    local ok, res = pcall(MySQL.scalar.await, query, params or {})
    if not ok then return nil end
    return res
end

local tableReady = false
local function ensureSeedTable()
    if tableReady then return true end
    tableReady = exec([[CREATE TABLE IF NOT EXISTS `default_seeds` (
        `name` VARCHAR(64) NOT NULL PRIMARY KEY,
        `seeded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )]])
    return tableReady
end

local SEEDERS = {
    ammunition_shops = function()
        for _, s in ipairs(AMMUNATION) do
            local p = s[2]
            exec([[INSERT INTO ammunition_shops (name, pos_x, pos_y, pos_z, pos_h, npc_x, npc_y, npc_z, npc_h, npc_model, active, blip_enabled)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 's_m_y_ammucity_01', 1, 1)]], { s[1], p.x, p.y, p.z, p.h, p.x, p.y, p.z, p.h })
        end
        return #AMMUNATION
    end,
    supermarkets = function()
        for _, s in ipairs(SUPERMARKETS) do
            local p = s[2]
            exec([[INSERT INTO supermarkets (name, store_type, pos_x, pos_y, pos_z, apu_x, apu_y, apu_z, apu_h,
                    safe_x, safe_y, safe_z, safe_h, zone_radius, active, blip_enabled, can_rob)
                VALUES (?, 'automatic', ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 2.0, 1, 1, 0)]], { s[1], p.x, p.y, p.z, p.x, p.y, p.z, p.h })
        end
        return #SUPERMARKETS
    end,
    shops = function()
        local n = 0
        for shopType, def in pairs(SHOPS) do
            for _, p in ipairs(def.points) do
                exec("INSERT INTO shops (type, position, blip, blip_color, price_multiplier, chairs) VALUES (?, ?, ?, ?, 1, '[]')",
                    { shopType, json.encode({ x = p.x, y = p.y, z = p.z, heading = p.h }), def.blip, def.color })
                n = n + 1
            end
        end
        return n
    end,
}

--- Pose les points par défaut d'une table s'ils n'ont jamais été posés et que la table est vide.
--- Appelé par chaque système juste avant de charger ses magasins.
---@param tableName "ammunition_shops"|"supermarkets"|"shops"
function DefaultShopPoints.Ensure(tableName)
    local seeder = SEEDERS[tableName]
    if not seeder or not ensureSeedTable() then return end
    if scalar("SELECT 1 FROM default_seeds WHERE name = ?", { tableName }) then return end

    local count = scalar(("SELECT COUNT(*) FROM `%s`"):format(tableName))
    if count == nil then return end -- table absente : on réessaiera au prochain démarrage
    if tonumber(count) == 0 then
        local added = seeder()
        console.success(("[default_shop_points] %d point(s) par défaut ajouté(s) dans %s."):format(added, tableName))
    end
    exec("INSERT IGNORE INTO default_seeds (name) VALUES (?)", { tableName })
end
