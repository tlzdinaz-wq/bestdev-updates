local VehicleSellBuilder = {
    configs = {},
    versions = {},
    ready = false,
}

local ALLOWED_NPC_MODELS = {
    s_m_y_dealer_01 = true,
    a_m_y_business_02 = true,
    a_m_y_bevhills_02 = true,
    s_m_m_autoshop_02 = true,
    a_m_m_bevhills_01 = true,
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do
        out[key] = copy(child)
    end
    return out
end

local function getBuilder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("builder_vehicle_sell") or xPlayer.hasPermission("staff_menu") then
        return xPlayer
    end
    return nil
end

local function cleanText(value, maxLength, fallback)
    if type(value) ~= "string" then return fallback end
    value = value:gsub("[%z\1-\31]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return fallback end
    return value:sub(1, maxLength)
end

local function finiteNumber(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then return nil end
    return number + 0.0
end

local function clamp(value, minimum, maximum, fallback)
    local number = finiteNumber(value) or fallback
    if number < minimum then return minimum end
    if number > maximum then return maximum end
    return number
end

local function sanitizeCoords(value)
    if type(value) ~= "table" then return nil end
    local x = finiteNumber(value.x)
    local y = finiteNumber(value.y)
    local z = finiteNumber(value.z)
    local w = finiteNumber(value.w) or finiteNumber(value.h) or 0.0
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z, w = w }
end

local function sanitizeConfig(data)
    if type(data) ~= "table" then
        return nil, "Les données du point de vente sont invalides."
    end

    local npcCoords = sanitizeCoords(data.npc_coords)
    if not npcCoords or (npcCoords.x == 0.0 and npcCoords.y == 0.0 and npcCoords.z == 0.0) then
        return nil, "La position du PNJ n'est pas définie."
    end

    local npcModel = cleanText(data.npc_model, 80, "s_m_y_dealer_01")
    if not ALLOWED_NPC_MODELS[npcModel] then
        return nil, "Le modèle du PNJ n'est pas autorisé."
    end

    if type(data.parking_spots) ~= "table" then
        return nil, "Ajoutez au moins un emplacement de parking."
    end

    local parkingSpots = {}
    for _, rawSpot in ipairs(data.parking_spots) do
        local spot = sanitizeCoords(rawSpot)
        if spot then
            parkingSpots[#parkingSpots + 1] = spot
            if #parkingSpots >= 30 then break end
        end
    end

    if #parkingSpots == 0 then
        return nil, "Ajoutez au moins un emplacement de parking valide."
    end

    local priceMin = math.floor(clamp(data.price_min, 1, 100000000, 1))
    local priceMax = math.floor(clamp(data.price_max, priceMin, 100000000, 100000000))

    return {
        name = cleanText(data.name, 100, "Point de vente"),
        npc_coords = npcCoords,
        npc_model = npcModel,
        npc_image = cleanText(data.npc_image, 512, ""),
        parking_spots = parkingSpots,
        interaction_distance = clamp(data.interaction_distance, 1.0, 10.0, 2.0),
        vehicle_detection_distance = clamp(data.vehicle_detection_distance, 3.0, 50.0, 15.0),
        zone_distance = clamp(data.zone_distance, 20.0, 300.0, 100.0),
        price_min = priceMin,
        price_max = priceMax,
        sale_cooldown = math.floor(clamp(data.sale_cooldown, 0, 1440, 30)),
        sale_duration_days = math.floor(clamp(data.sale_duration_days, 1, 365, 15)),
    }
end

local function encodeConfig(config)
    local ok, encoded = pcall(VFW.DB.Encode, config)
    if not ok or type(encoded) ~= "string" then return nil end
    return encoded
end

local function decodeConfig(value)
    local ok, decoded = pcall(VFW.DB.Decode, value, {})
    if not ok or type(decoded) ~= "table" then return nil end
    return decoded
end

local function ensureTable()
    local ok, err = pcall(MySQL.query.await, [[
        CREATE TABLE IF NOT EXISTS `vehicle_sell_locations` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(100) NOT NULL DEFAULT 'Point de vente',
            `config` LONGTEXT NOT NULL,
            `version` INT UNSIGNED NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    if not ok then
        console.error(("[VehicleSell] Création de la table impossible: %s"):format(tostring(err)))
        return false
    end
    return true
end

local function loadConfigs()
    if not ensureTable() then return false end

    local ok, rows = pcall(MySQL.query.await,
        "SELECT id, name, config, version FROM vehicle_sell_locations ORDER BY id ASC")
    if not ok then
        console.error(("[VehicleSell] Chargement des points impossible: %s"):format(tostring(rows)))
        return false
    end

    local configs, versions = {}, {}
    for i = 1, #(rows or {}) do
        local row = rows[i]
        local id = tonumber(row.id)
        local config = decodeConfig(row.config)
        if id and config then
            config.name = cleanText(config.name, 100, row.name or "Point de vente")
            configs[id] = config
            versions[id] = tonumber(row.version) or 1
        end
    end

    VehicleSellBuilder.configs = configs
    VehicleSellBuilder.versions = versions
    VehicleSellBuilder.ready = true
    console.init("VehicleSell", ("%d points de vente chargés"):format(#(rows or {})))
    return true
end

MySQL.ready(loadConfigs)

Misc30.Cb("vehicleSell:getAllConfigs", function()
    return copy(VehicleSellBuilder.configs)
end)

Misc30.Cb("vehicleSell:getConfig", function(source, locationId)
    if not getBuilder(source) then return nil end
    locationId = tonumber(locationId)
    if not locationId then return nil end
    return copy(VehicleSellBuilder.configs[locationId])
end)

Misc30.Cb("vehicleSell:createConfig", function(source, data)
    if not getBuilder(source) then
        return nil, "Vous n'avez pas la permission de créer un point de vente."
    end
    if not VehicleSellBuilder.ready then
        return nil, "Le service des points de vente n'est pas encore prêt."
    end

    local config, validationError = sanitizeConfig(data)
    if not config then return nil, validationError end

    local encoded = encodeConfig(config)
    if not encoded then return nil, "Impossible de préparer la configuration."
    end

    local ok, insertResult = pcall(MySQL.insert.await, [[
        INSERT INTO vehicle_sell_locations (name, config, version)
        VALUES (?, ?, 1)
    ]], { config.name, encoded })

    local newId = ok and tonumber(insertResult) or nil
    if not newId then
        console.error(("[VehicleSell] Création impossible: %s"):format(tostring(ok and "ID absent" or insertResult)))
        return nil, "La base de données a refusé la création du point de vente."
    end

    VehicleSellBuilder.configs[newId] = config
    VehicleSellBuilder.versions[newId] = 1
    TriggerClientEvent("vehicleSell:locationCreated", -1, newId, copy(config))
    return newId
end)

local function saveConfig(source, locationId, data)
    if not getBuilder(source) then
        return false, "Vous n'avez pas la permission de modifier ce point de vente."
    end
    locationId = tonumber(locationId)
    if not locationId or not VehicleSellBuilder.configs[locationId] then
        return false, "Ce point de vente n'existe plus."
    end

    local config, validationError = sanitizeConfig(data)
    if not config then return false, validationError end
    local encoded = encodeConfig(config)
    if not encoded then return false, "Impossible de préparer la configuration." end

    local ok, affected = pcall(MySQL.update.await, [[
        UPDATE vehicle_sell_locations
        SET name = ?, config = ?, version = version + 1
        WHERE id = ?
    ]], { config.name, encoded, locationId })

    if not ok or tonumber(affected) == 0 then
        return false, "La base de données a refusé la modification."
    end

    VehicleSellBuilder.configs[locationId] = config
    VehicleSellBuilder.versions[locationId] = (VehicleSellBuilder.versions[locationId] or 1) + 1
    TriggerClientEvent("vehicleSell:syncConfig", -1, locationId, copy(config))
    return true
end

Misc30.Cb("vehicleSell:saveConfigCallback", saveConfig)

RegisterNetEvent("vehicleSell:saveConfig", function(locationId, data)
    saveConfig(source, locationId, data)
end)

Misc30.Cb("vehicleSell:deleteConfig", function(source, locationId)
    if not getBuilder(source) then
        return false, "Vous n'avez pas la permission de supprimer ce point de vente."
    end
    locationId = tonumber(locationId)
    if not locationId or not VehicleSellBuilder.configs[locationId] then
        return false, "Ce point de vente n'existe plus."
    end

    local ok, affected = pcall(MySQL.update.await,
        "DELETE FROM vehicle_sell_locations WHERE id = ?", { locationId })
    if not ok or tonumber(affected) == 0 then
        return false, "La base de données a refusé la suppression."
    end

    VehicleSellBuilder.configs[locationId] = nil
    VehicleSellBuilder.versions[locationId] = nil
    TriggerClientEvent("vehicleSell:locationDeleted", -1, locationId)
    return true
end)

