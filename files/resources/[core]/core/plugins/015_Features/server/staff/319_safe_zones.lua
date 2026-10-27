-- Zones safe : polygones où certaines actions sont désactivées (sauter, bagarre, sortir une arme, dégâts...).
-- Le staff les gère depuis Builders > ZONES SAFE (menu et carte) ; chaque joueur les reçoit à la connexion
-- (core:getAllSafeZones) et à chaque changement (zonesafe:client:add / update / remove).
--
-- Ce fichier manquait : sans réponse à core:getAllSafeZones, le menu et la carte restaient sur « chargement »
-- pour toujours, et personne ne recevait les zones.

local TABLE_SQL = [[
    CREATE TABLE IF NOT EXISTS `safe_zones` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(64) NOT NULL,
        `label` VARCHAR(100) NOT NULL,
        `points` LONGTEXT NOT NULL,
        `height` FLOAT NOT NULL DEFAULT 10,
        `action_disabled` LONGTEXT NOT NULL,
        `bypass_job` LONGTEXT NOT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `name` (`name`)
    )
]]

local MAX_NAME, MAX_LABEL, MAX_POINTS, MAX_ACTIONS, MAX_JOBS = 64, 100, 100, 40, 100
local NAMED_ACTIONS = { degats = true, carkill = true }

local zones = {}      -- liste ordonnée, ce que reçoivent les joueurs
local loaded = false

local function copy(zone)
    local points = {}
    for i = 1, #zone.points do
        points[i] = { x = zone.points[i].x, y = zone.points[i].y, z = zone.points[i].z }
    end
    local actions, jobs = {}, {}
    for i = 1, #zone.actionDisabled do actions[i] = zone.actionDisabled[i] end
    for i = 1, #zone.bypassJob do jobs[i] = zone.bypassJob[i] end
    return {
        name = zone.name,
        label = zone.label,
        points = points,
        height = zone.height,
        actionDisabled = actions,
        bypassJob = jobs,
    }
end

local function indexOf(name)
    for i = 1, #zones do
        if zones[i].name == name then return i end
    end
end

local function rateOk(source, key, ms)
    if Feat27 and Feat27.RateLimit then return Feat27.RateLimit(source, key, ms) end
    return true
end

local function allowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("zonesafe_builder") or xPlayer.hasPermission("dev") then return xPlayer end
    return nil
end

local function tell(source, ok, message)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.showNotification then return end
    xPlayer.showNotification({ type = "STAFF", variant = ok and "SUCCESS" or "ERROR", subtitle = "Zones Safe", message = message })
end

-- ── nettoyage de ce que le client envoie ──

local function cleanText(value, max)
    if type(value) ~= "string" then return nil end
    value = value:gsub("%c", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    if value == "" then return nil end
    if #value > max then value = value:sub(1, max) end
    return value
end

-- Les coordonnées arrivent en vector3 (pas en table) : on ne lit que .x .y .z.
local function cleanPoints(value)
    if type(value) ~= "table" then return nil end
    local out = {}
    for i = 1, #value do
        local p = value[i]
        if p == nil then return nil end
        local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
        if not x or not y or x ~= x or y ~= y or math.abs(x) > 20000 or math.abs(y) > 20000 then return nil end
        if not z or z ~= z or math.abs(z) > 5000 then z = 0.0 end
        out[#out + 1] = { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
        if #out > MAX_POINTS then return nil end
    end
    if #out < 3 then return nil end
    return out
end

local function cleanActions(value)
    local out, seen = {}, {}
    if type(value) ~= "table" then return out end
    for i = 1, #value do
        local action = value[i]
        local key
        if type(action) == "number" and action >= 0 and action <= 360 and action == math.floor(action) then
            key = action
        elseif type(action) == "string" and NAMED_ACTIONS[action] then
            key = action
        end
        if key ~= nil and not seen[key] then
            seen[key] = true
            out[#out + 1] = key
            if #out >= MAX_ACTIONS then break end
        end
    end
    return out
end

local function cleanJobs(value)
    local out, seen = {}, {}
    if type(value) ~= "table" then return out end
    for i = 1, #value do
        local job = value[i]
        if type(job) == "string" and #job <= 64 and job:match("^[%w_%-%.]+$") and not seen[job] then
            seen[job] = true
            out[#out + 1] = job
            if #out >= MAX_JOBS then break end
        end
    end
    return out
end

local function clean(name, label, points, height, actionDisabled, bypassJob)
    name = cleanText(name, MAX_NAME)
    if not name then return nil, "Donne un nom à la zone." end
    label = cleanText(label, MAX_LABEL) or name
    local cleanedPoints = cleanPoints(points)
    if not cleanedPoints then return nil, "Une zone a besoin d'au moins 3 points valides." end
    height = tonumber(height) or 10.0
    if height ~= height or height < 1.0 then height = 1.0 end
    if height > 1000.0 then height = 1000.0 end
    return {
        name = name,
        label = label,
        points = cleanedPoints,
        height = height + 0.0,
        actionDisabled = cleanActions(actionDisabled),
        bypassJob = cleanJobs(bypassJob),
    }
end

-- ── base de données ──

local function decode(value, fallback)
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return fallback end
    local ok, result = pcall(json.decode, value)
    if ok and type(result) == "table" then return result end
    return fallback
end

local function fromRow(row)
    local points = {}
    local stored = decode(row.points, {})
    for i = 1, #stored do
        local p = stored[i]
        if type(p) == "table" and tonumber(p.x) and tonumber(p.y) then
            points[#points + 1] = { x = tonumber(p.x) + 0.0, y = tonumber(p.y) + 0.0, z = (tonumber(p.z) or 0.0) + 0.0 }
        end
    end
    return {
        name = row.name,
        label = row.label ~= nil and row.label ~= "" and row.label or row.name,
        points = points,
        height = tonumber(row.height) or 10.0,
        actionDisabled = cleanActions(decode(row.action_disabled, {})),
        bypassJob = cleanJobs(decode(row.bypass_job, {})),
    }
end

local function load()
    pcall(MySQL.query.await, TABLE_SQL)
    local ok, rows = pcall(MySQL.query.await, "SELECT * FROM `safe_zones` ORDER BY `id` ASC")
    rows = (ok and type(rows) == "table") and rows or {}

    local list = {}
    for i = 1, #rows do
        local zone = fromRow(rows[i])
        if #zone.points >= 3 then list[#list + 1] = zone end
    end
    zones = list
    loaded = true
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 400 do
        Wait(250)
        tries = tries + 1
    end
    load()
end)

local function waitLoaded()
    local tries = 0
    while not loaded and tries < 100 do
        Wait(100)
        tries = tries + 1
    end
end

-- ── côté joueurs ──

RegisterServerCallback("core:getAllSafeZones", function(source)
    waitLoaded()
    local out = {}
    for i = 1, #zones do out[i] = copy(zones[i]) end
    return out
end)

-- ── côté staff ──

RegisterNetEvent("zonesafe:server:create", function(name, label, points, height, actionDisabled, bypassJob)
    local src = source
    if not allowed(src) then return end
    if not rateOk(src, "zonesafe:write", 150) then return end
    waitLoaded()

    local zone, reason = clean(name, label, points, height, actionDisabled, bypassJob)
    if not zone then return tell(src, false, reason) end
    if indexOf(zone.name) then return tell(src, false, "Une zone porte déjà ce nom.") end

    local ok = pcall(MySQL.insert.await,
        "INSERT INTO `safe_zones` (`name`, `label`, `points`, `height`, `action_disabled`, `bypass_job`) VALUES (?, ?, ?, ?, ?, ?)",
        { zone.name, zone.label, json.encode(zone.points), zone.height, json.encode(zone.actionDisabled), json.encode(zone.bypassJob) })
    if not ok then return tell(src, false, "Enregistrement impossible, regarde la console serveur.") end

    zones[#zones + 1] = zone
    TriggerClientEvent("zonesafe:client:add", -1, copy(zone))
end)

RegisterNetEvent("zonesafe:server:update", function(oldName, name, label, points, height, actionDisabled, bypassJob)
    local src = source
    if not allowed(src) then return end
    if not rateOk(src, "zonesafe:write", 100) then return end
    waitLoaded()

    oldName = cleanText(oldName, MAX_NAME)
    local index = oldName and indexOf(oldName)
    if not index then return tell(src, false, "Cette zone n'existe plus.") end

    local zone, reason = clean(name, label, points, height, actionDisabled, bypassJob)
    if not zone then return tell(src, false, reason) end
    if zone.name ~= oldName and indexOf(zone.name) then return tell(src, false, "Une zone porte déjà ce nom.") end

    local ok = pcall(MySQL.update.await,
        "UPDATE `safe_zones` SET `name` = ?, `label` = ?, `points` = ?, `height` = ?, `action_disabled` = ?, `bypass_job` = ? WHERE `name` = ?",
        { zone.name, zone.label, json.encode(zone.points), zone.height, json.encode(zone.actionDisabled), json.encode(zone.bypassJob), oldName })
    if not ok then return tell(src, false, "Enregistrement impossible, regarde la console serveur.") end

    zones[index] = zone
    TriggerClientEvent("zonesafe:client:update", -1, oldName, copy(zone))
end)

RegisterNetEvent("zonesafe:server:delete", function(name)
    local src = source
    if not allowed(src) then return end
    if not rateOk(src, "zonesafe:write", 150) then return end
    waitLoaded()

    name = cleanText(name, MAX_NAME)
    local index = name and indexOf(name)
    if not index then return tell(src, false, "Cette zone n'existe plus.") end

    local ok = pcall(MySQL.update.await, "DELETE FROM `safe_zones` WHERE `name` = ?", { name })
    if not ok then return tell(src, false, "Suppression impossible, regarde la console serveur.") end

    table.remove(zones, index)
    TriggerClientEvent("zonesafe:client:remove", -1, name)
end)

--- Un joueur entre dans une zone où sortir une arme est interdit : on lui fait ranger celle qu'il a en main.
RegisterNetEvent("zonesafe:server:forceHolster", function()
    local src = source
    if not VFW.GetPlayerFromId(src) then return end
    if not rateOk(src, "zonesafe:holster", 1000) then return end
    TriggerClientEvent("zonesafe:client:holster", src)
end)
