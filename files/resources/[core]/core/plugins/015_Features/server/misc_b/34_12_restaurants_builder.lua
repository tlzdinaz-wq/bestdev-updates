-- Builders > Restaurants & commerces > « Livraisons … » (BurgerShot, Pizzeria, Pearls, Noodle, Bean Coffee, UwU Café).
--
-- Les menus du staff appelaient `<enseigne>:delivery:getAllClients / getClients / addClient / updateClient / deleteClient`
-- et `restaurants_builder:getConfig / updateConfig`, mais aucun code serveur n'y répondait : le menu restait sur
-- « Chargement du menu… ». Ce fichier les fournit :
--   - clients de livraison par établissement (nom du PNJ, modèle, position, commande avec prix) : table
--     `restaurant_delivery_clients` ; la mission de livraison (34_12_restaurants.lua) les utilise dès qu'un établissement
--     en a, sinon elle garde ses points par défaut ;
--   - réglages de livraison par enseigne (pourboires, part de la société, distances, véhicules) : table
--     `restaurants_builder_config`, appliqués au serveur et envoyés aux joueurs (`restaurants_builder:syncConfig`).

MiscB.Restaurants = MiscB.Restaurants or {}
local R = MiscB.Restaurants

local BRANDS = {
    bean_coffee = "BeanCoffeeConfig",
    burgershot  = "BurgerShotConfig",
    noodle      = "NoodleConfig",
    pearls      = "PearlsConfig",
    pizzeria    = "PizzeriaConfig",
    uwu_cafe    = "UwuCafeConfig",
}

local clients = {}  -- clients[brand][jobName] = { { id, npcName, npcModel, x, y, z, heading, orderItems }, ... }
local configs = {}  -- configs[brand] = réglages enregistrés par le staff
local loaded = false

local function cfgOf(brand)
    local name = BRANDS[brand]
    local cfg = name and _G[name] or nil
    return type(cfg) == "table" and cfg or nil
end

local function isStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("restaurant_builder") or xPlayer.hasPermission("staff") or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

-- ── base de données ───────────────────────────────────────────────

--- Exécute une écriture ; faux seulement si la requête échoue (0 ligne modifiée = valeurs identiques, pas une erreur).
local function exec(sql, params)
    local ok, err = pcall(MySQL.update.await, sql, params)
    if not ok then
        console.error("[restaurants_builder] SQL : " .. tostring(err))
        return false
    end
    return true
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS restaurant_delivery_clients (
            id INT NOT NULL AUTO_INCREMENT,
            brand VARCHAR(32) NOT NULL,
            job_name VARCHAR(64) NOT NULL,
            npc_name VARCHAR(64) NOT NULL,
            npc_model VARCHAR(64) NOT NULL,
            x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, heading DOUBLE NOT NULL DEFAULT 0,
            order_items LONGTEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_brand_job (brand, job_name)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS restaurants_builder_config (
            brand VARCHAR(32) NOT NULL,
            data LONGTEXT NOT NULL,
            PRIMARY KEY (brand)
        )
    ]])
end

local function decodeItems(raw)
    local ok, list = pcall(json.decode, raw or "[]")
    if not ok or type(list) ~= "table" then return {} end
    return list
end

local function addToCache(row)
    local brand, job = row.brand, row.job_name
    clients[brand] = clients[brand] or {}
    clients[brand][job] = clients[brand][job] or {}
    table.insert(clients[brand][job], {
        id = row.id, npcName = row.npc_name, npcModel = row.npc_model,
        x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0, heading = (row.heading or 0) + 0.0,
        orderItems = decodeItems(row.order_items),
    })
end

-- Réglages enregistrés : appliqués à la config du serveur (la mission de livraison les lit) et envoyés aux joueurs.
local function applyConfig(brand, data)
    local cfg = cfgOf(brand)
    if not cfg or type(data) ~= "table" then return end
    cfg.DeliveryTipChance = data.tip_chance
    cfg.DeliveryTipMin = data.tip_min
    cfg.DeliveryTipMax = data.tip_max
    cfg.DeliverySocietyPercent = data.society_percent
    cfg.DeliveryStartMaxDistance = data.delivery_max_distance
    cfg.DeliveryNpcSpawnDistance = data.delivery_npc_distance
    cfg.DeliveryVehicleModels = data.vehicle_models or {}
end

local function loadAll()
    ensureTables()
    clients = {}
    local rows = MySQL.query.await("SELECT * FROM restaurant_delivery_clients ORDER BY id ASC") or {}
    for i = 1, #rows do
        if BRANDS[rows[i].brand] then addToCache(rows[i]) end
    end
    configs = {}
    local cfgRows = MySQL.query.await("SELECT brand, data FROM restaurants_builder_config") or {}
    for i = 1, #cfgRows do
        local brand = cfgRows[i].brand
        local ok, data = pcall(json.decode, cfgRows[i].data or "{}")
        if BRANDS[brand] and ok and type(data) == "table" then
            configs[brand] = data
            applyConfig(brand, data)
        end
    end
    loaded = true
end

-- Utilisé par la mission de livraison (34_12_restaurants.lua).
function R.Clients(brand, jobName)
    local list = clients[brand] and clients[brand][jobName]
    return list and #list > 0 and list or nil
end

-- ── validation ────────────────────────────────────────────────────

local function cleanOrderItems(list)
    if type(list) ~= "table" then return nil, "Configurez au moins un item dans la commande." end
    local out = {}
    for i = 1, #list do
        local it = list[i]
        if type(it) == "table" and type(it.name) == "string" and VFW.Items and VFW.Items[it.name] then
            local count = math.floor(tonumber(it.count) or 0)
            local price = math.floor(tonumber(it.price) or 0)
            if count >= 1 and count <= 50 and price >= 0 and price <= 100000 then
                out[#out + 1] = { name = it.name, count = count, price = price }
            end
        end
        if #out >= 12 then break end
    end
    if #out == 0 then return nil, "Configurez au moins un item dans la commande." end
    return out
end

local function cleanClient(brand, data, requireJob)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local cfg = cfgOf(brand)
    if not cfg then return nil, "Enseigne inconnue." end

    local jobName = MiscB.Str(data.jobName, 64)
    if jobName == "" then jobName = nil end
    if requireJob and (not jobName or type(cfg.Locations) ~= "table" or not cfg.Locations[jobName]) then
        return nil, "Établissement inconnu."
    end

    local npcName = MiscB.Str(data.npcName, 64)
    if not npcName or npcName:match("^%s*$") then npcName = "Client" end
    local npcModel = MiscB.Str(data.npcModel, 64)
    if not npcModel or npcModel == "" then npcModel = cfg.DeliveryDefaultModel or "a_m_y_business_01" end
    if not npcModel:match("^[%w_]+$") then return nil, "Modèle de PNJ invalide." end

    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y or not z or (x == 0 and y == 0) then return nil, "Capturez d'abord une position." end
    if math.abs(x) > 10000 or math.abs(y) > 10000 or math.abs(z) > 2000 then return nil, "Position invalide." end

    local items, why = cleanOrderItems(data.orderItems)
    if not items then return nil, why end

    return { jobName = jobName, npcName = npcName, npcModel = npcModel, x = x + 0.0, y = y + 0.0, z = z + 0.0,
        heading = (tonumber(data.heading) or 0.0) + 0.0, orderItems = items }
end

local function findClient(brand, id)
    for job, list in pairs(clients[brand] or {}) do
        for index, c in ipairs(list) do
            if c.id == id then return c, list, index, job end
        end
    end
    return nil
end

-- ── callbacks de chaque enseigne ──────────────────────────────────

local function registerBrand(brand)
    local prefix = brand .. ":delivery:"

    MiscB.Cb(prefix .. "getAllClients", function(source)
        if not isStaff(source) then return {} end
        return clients[brand] or {}
    end)

    MiscB.Cb(prefix .. "getClients", function(source, jobName)
        if not isStaff(source) then return {} end
        jobName = MiscB.Str(jobName, 64)
        return jobName and clients[brand] and clients[brand][jobName] or {}
    end)

    MiscB.Cb(prefix .. "addClient", function(source, data)
        if not isStaff(source) then return false, "Permission insuffisante." end
        local c, why = cleanClient(brand, data, true)
        if not c then return false, why end

        local id = MiscB.Insert([[
            INSERT INTO restaurant_delivery_clients (brand, job_name, npc_name, npc_model, x, y, z, heading, order_items)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], { brand, c.jobName, c.npcName, c.npcModel, c.x, c.y, c.z, c.heading, json.encode(c.orderItems) })
        if not id then return false, "Enregistrement impossible (consultez la console du serveur)." end

        addToCache({ id = id, brand = brand, job_name = c.jobName, npc_name = c.npcName, npc_model = c.npcModel,
            x = c.x, y = c.y, z = c.z, heading = c.heading, order_items = json.encode(c.orderItems) })
        TriggerEvent("vfw:logs:staff", source, "restaurant_delivery_client_add", { brand = brand, job = c.jobName, id = id })
        return true, id
    end)

    MiscB.Cb(prefix .. "updateClient", function(source, id, data)
        if not isStaff(source) then return false end
        id = MiscB.ToInt(id, 1)
        local current = id and findClient(brand, id)
        if not current then return false end
        local c = cleanClient(brand, data, false)
        if not c then return false end

        if not exec([[
            UPDATE restaurant_delivery_clients SET npc_name = ?, npc_model = ?, x = ?, y = ?, z = ?, heading = ?, order_items = ?
            WHERE id = ? AND brand = ?
        ]], { c.npcName, c.npcModel, c.x, c.y, c.z, c.heading, json.encode(c.orderItems), id, brand }) then return false end

        current.npcName, current.npcModel = c.npcName, c.npcModel
        current.x, current.y, current.z, current.heading = c.x, c.y, c.z, c.heading
        current.orderItems = c.orderItems
        return true
    end)

    MiscB.Cb(prefix .. "deleteClient", function(source, id)
        if not isStaff(source) then return false end
        id = MiscB.ToInt(id, 1)
        local current, list, index = nil, nil, nil
        if id then current, list, index = findClient(brand, id) end
        if not current then return false end

        if not exec("DELETE FROM restaurant_delivery_clients WHERE id = ? AND brand = ?", { id, brand }) then return false end
        table.remove(list, index)
        TriggerEvent("vfw:logs:staff", source, "restaurant_delivery_client_delete", { brand = brand, id = id })
        return true
    end)
end

for brand in pairs(BRANDS) do registerBrand(brand) end

-- ── réglages de livraison (pourboires, part de la société, distances, véhicules) ──

local function cleanConfig(data)
    if type(data) ~= "table" then return nil end
    local function num(v, min, max, fallback)
        v = tonumber(v)
        if not v then return fallback end
        return math.max(min, math.min(max, v))
    end
    local tipMin = num(data.tip_min, 0, 100000, 0)
    local tipMax = num(data.tip_max, 0, 100000, tipMin)
    if tipMax < tipMin then tipMax = tipMin end

    local models = {}
    if type(data.vehicle_models) == "table" then
        for i = 1, #data.vehicle_models do
            local m = data.vehicle_models[i]
            if type(m) == "string" and m:match("^[%w_]+$") and #m <= 64 then models[#models + 1] = m end
            if #models >= 20 then break end
        end
    end

    return {
        tip_chance = math.floor(num(data.tip_chance, 0, 100, 0)),
        tip_min = math.floor(tipMin),
        tip_max = math.floor(tipMax),
        society_percent = math.floor(num(data.society_percent, 0, 100, 70)),
        delivery_max_distance = num(data.delivery_max_distance, 1, 1000, 50.0) + 0.0,
        delivery_npc_distance = num(data.delivery_npc_distance, 1, 1000, 50.0) + 0.0,
        vehicle_models = models,
    }
end

MiscB.Cb("restaurants_builder:getConfig", function(source, brand)
    if not isStaff(source) or not BRANDS[brand] then return nil end
    return configs[brand] -- nil : le menu affiche les valeurs par défaut de l'enseigne
end)

MiscB.Cb("restaurants_builder:updateConfig", function(source, brand, data)
    if not isStaff(source) or not BRANDS[brand] then return false end
    local clean = cleanConfig(data)
    if not clean then return false end

    if not exec([[
        INSERT INTO restaurants_builder_config (brand, data) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data)
    ]], { brand, json.encode(clean) }) then return false end

    configs[brand] = clean
    applyConfig(brand, clean)
    TriggerClientEvent("restaurants_builder:syncConfig", -1, { [brand] = clean })
    TriggerEvent("vfw:logs:staff", source, "restaurant_delivery_config", { brand = brand })
    return true
end)

-- Les joueurs qui se connectent reçoivent les réglages enregistrés.
AddEventHandler("vfw:playerLoaded", function(source)
    if next(configs) ~= nil then
        TriggerClientEvent("restaurants_builder:syncConfig", source, configs)
    end
end)

CreateThread(function()
    while not VFW.Ready or type(MySQL) ~= "table" do Wait(250) end
    Wait(3000)
    local ok, err = pcall(loadAll)
    if not ok then console.error("[restaurants_builder] chargement : " .. tostring(err)) end
end)
