-- Builders > « Stockage véhicules » : coffre (poids, places) et boîte à gants par modèle, et « peut monter dans le
-- coffre ». Le menu (client/staff/menu/builderVehicleStorage.lua) appelait vehicleStorage:getAll / create / update /
-- delete sans aucune réponse du serveur : il restait sur « Chargement du menu… ».
--
-- Table `vehicle_storage_config` (le modèle et le poids du coffre existaient déjà, les autres colonnes sont ajoutées
-- si elles manquent). Les réglages sont envoyés aux joueurs (`vehicleStorage:syncConfig`, lu par
-- client/vehicle/trunk.lua) et appliqués à l'ouverture du coffre / de la boîte à gants (25_15_vehicle_storage.lua).

local Inv = VFW.Inventory
local Storage = {}
VFW.VehicleStorage = Storage

local LIMITS <const> = {
    trunk_weight = { 1, 5000 },
    trunk_slots = { 1, 200 },
    glovebox_weight = { 1, 500 },
    glovebox_slots = { 1, 50 },
}
local DEFAULTS <const> = { trunk_weight = 60, trunk_slots = 30, glovebox_weight = 5, glovebox_slots = 5 }

local MISSING_COLUMNS <const> = {
    { column = "vehicle_hash", definition = "BIGINT NOT NULL DEFAULT 0" },
    { column = "trunk_slots", definition = "INT NOT NULL DEFAULT 30" },
    { column = "glovebox_weight", definition = "INT NOT NULL DEFAULT 5" },
    { column = "glovebox_slots", definition = "INT NOT NULL DEFAULT 5" },
    { column = "can_enter_trunk", definition = "TINYINT(1) NOT NULL DEFAULT 1" },
}

local byModel, byHash = {}, {}
local ready = false

local function isSet(v)
    return v == true or v == 1 or v == "1"
end

local function cleanModel(raw)
    if type(raw) ~= "string" then return nil end
    local name = raw:lower():gsub("%s+", "")
    if name == "" or #name > 60 or not name:match("^[%w_%-]+$") then return nil end
    return name
end

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    return xPlayer ~= nil and (xPlayer.hasPermission("manage_trunk") or xPlayer.hasPermission("dev"))
end

local function ensureColumns()
    for i = 1, #MISSING_COLUMNS do
        local entry = MISSING_COLUMNS[i]
        local ok, exists = pcall(MySQL.scalar.await, [[
            SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'vehicle_storage_config' AND COLUMN_NAME = ?
        ]], { entry.column })
        if ok and (tonumber(exists) or 0) == 0 then
            pcall(MySQL.update.await, ("ALTER TABLE vehicle_storage_config ADD COLUMN `%s` %s"):format(entry.column, entry.definition), {})
        end
    end
end

local function rowToConfig(row)
    local model = row.model
    return {
        model = model,
        vehicle_hash = GetHashKey(model),
        trunk_weight = tonumber(row.trunk_weight) or DEFAULTS.trunk_weight,
        trunk_slots = tonumber(row.trunk_slots) or DEFAULTS.trunk_slots,
        glovebox_weight = tonumber(row.glovebox_weight) or DEFAULTS.glovebox_weight,
        glovebox_slots = tonumber(row.glovebox_slots) or DEFAULTS.glovebox_slots,
        can_enter_trunk = row.can_enter_trunk == nil or isSet(row.can_enter_trunk),
    }
end

local function reload()
    local ok, rows = pcall(MySQL.query.await, "SELECT * FROM vehicle_storage_config", {})
    byModel, byHash = {}, {}
    for _, row in ipairs(ok and rows or {}) do
        if cleanModel(row.model) then
            local config = rowToConfig(row)
            byModel[config.model] = config
            byHash[config.vehicle_hash] = config
        end
    end
end

local function sync(target)
    TriggerClientEvent("vehicleStorage:syncConfig", target or -1, byModel, byHash)
end

--- Réglages d'un véhicule (par hash du modèle, puis par nom) ; nil = valeurs par défaut du jeu
function Storage.Get(hashOrModel)
    if type(hashOrModel) == "number" then return byHash[hashOrModel] end
    local name = cleanModel(hashOrModel)
    return name and byModel[name] or nil
end

--- Valeurs reçues du menu, bornées ; nil si le modèle est invalide
local function readConfig(model, data)
    local name = cleanModel(model)
    if not name or type(data) ~= "table" then return nil end
    local out = { model = name }
    for key, range in pairs(LIMITS) do
        local n = tonumber(data[key]) or DEFAULTS[key]
        out[key] = math.floor(math.max(range[1], math.min(range[2], n)))
    end
    out.can_enter_trunk = data.can_enter_trunk ~= false
    return out
end

local function save(config)
    local ok, err = pcall(MySQL.update.await, [[
        INSERT INTO vehicle_storage_config
            (model, vehicle_hash, trunk_weight, trunk_slots, glovebox_weight, glovebox_slots, can_enter_trunk)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE vehicle_hash = VALUES(vehicle_hash), trunk_weight = VALUES(trunk_weight),
            trunk_slots = VALUES(trunk_slots), glovebox_weight = VALUES(glovebox_weight),
            glovebox_slots = VALUES(glovebox_slots), can_enter_trunk = VALUES(can_enter_trunk)
    ]], {
        config.model, GetHashKey(config.model), config.trunk_weight, config.trunk_slots,
        config.glovebox_weight, config.glovebox_slots, config.can_enter_trunk and 1 or 0,
    })
    if not ok then
        console.warn("[vehicle_storage] SQL : " .. tostring(err))
        return false
    end
    reload()
    sync()
    return true
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    ensureColumns()
    reload()
    ready = true
    sync()
end)

AddEventHandler("vfw:playerLoaded", function(source)
    if ready then sync(source) end
end)

Inv.RegisterCallback("vehicleStorage:getAll", function(source)
    if not staffOk(source) then return {} end
    return byModel
end)

Inv.RegisterCallback("vehicleStorage:create", function(source, data)
    if not staffOk(source) then return { success = false, error = "Permission refusée." } end
    local config = readConfig(type(data) == "table" and data.model, data)
    if not config then return { success = false, error = "Nom de modèle invalide." } end
    if byModel[config.model] then return { success = false, error = "Ce véhicule est déjà configuré : modifiez-le dans la liste." } end
    if not save(config) then return { success = false, error = "Enregistrement impossible." } end
    return { success = true }
end)

Inv.RegisterCallback("vehicleStorage:update", function(source, model, data)
    if not staffOk(source) then return { success = false, error = "Permission refusée." } end
    local config = readConfig(model, data)
    if not config or not byModel[config.model] then return { success = false, error = "Véhicule introuvable." } end
    if not save(config) then return { success = false, error = "Enregistrement impossible." } end
    return { success = true }
end)

Inv.RegisterCallback("vehicleStorage:delete", function(source, model)
    if not staffOk(source) then return { success = false, error = "Permission refusée." } end
    local name = cleanModel(model)
    if not name or not byModel[name] then return { success = false, error = "Véhicule introuvable." } end
    local ok, err = pcall(MySQL.update.await, "DELETE FROM vehicle_storage_config WHERE model = ?", { name })
    if not ok then
        console.warn("[vehicle_storage] SQL : " .. tostring(err))
        return { success = false, error = "Suppression impossible." }
    end
    reload()
    sync()
    return { success = true }
end)
