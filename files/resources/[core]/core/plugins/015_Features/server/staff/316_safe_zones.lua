---@meta _
---@diagnostic disable: duplicate-doc-field

-- Zones safe : côté serveur.
--
-- La fonctionnalité était entièrement cliente. Le menu staff et la tablette envoyaient
-- `zonesafe:server:create`, `:update`, `:delete` et `:forceHolster`, et le client appelait
-- `core:getAllSafeZones` au chargement — mais rien n'écoutait, et aucune table n'existait.
-- Créer une zone affichait donc « Zone safe créée » puis renvoyait vers une liste vide, et
-- aucune zone n'était jamais appliquée à qui que ce soit.
--
-- Les deux interfaces (menu VUI et tablette) envoient la même charge utile, dans le même
-- ordre, ce qui est respecté ici.

local CREATE_PERM = "zonesafe_builder"
local zones = {}
local loaded = false

local function encode(value)
    if VFW and VFW.DB and VFW.DB.Encode then return VFW.DB.Encode(value) end
    return json.encode(value or {})
end

local function decode(value, fallback)
    if type(value) == "table" then return value end
    if VFW and VFW.DB and VFW.DB.Decode then return VFW.DB.Decode(value, fallback) end
    if type(value) ~= "string" or value == "" then return fallback end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

local function ensureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS safe_zones (
            id INT NOT NULL AUTO_INCREMENT,
            name VARCHAR(64) NOT NULL,
            label VARCHAR(100) NOT NULL,
            points LONGTEXT NOT NULL,
            height FLOAT NOT NULL DEFAULT 10,
            action_disabled LONGTEXT NOT NULL,
            bypass_job LONGTEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uniq_safe_zone_name (name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

--- Forme attendue par le client (plugins/015_Features/client/safeZone/function.lua).
---@param row table
---@return table
local function fromRow(row)
    return {
        name = row.name,
        label = row.label,
        points = decode(row.points, {}),
        height = tonumber(row.height) or 10.0,
        actionDisabled = decode(row.action_disabled, {}),
        bypassJob = decode(row.bypass_job, {}),
    }
end

local function loadZones()
    local rows = MySQL.query.await("SELECT * FROM safe_zones") or {}

    zones = {}
    for i = 1, #rows do
        zones[#zones + 1] = fromRow(rows[i])
    end

    loaded = true
    console.info(("[zones safe] %d zone(s) chargée(s)."):format(#zones))
end

---@param name string
---@return table|nil zone, number|nil index
local function findZone(name)
    for i = 1, #zones do
        if zones[i].name == name then return zones[i], i end
    end
end

--- Le staff a-t-il le droit de modifier les zones ?
---@param source number
---@return table|nil
local function builder(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if not xPlayer.hasPermission(CREATE_PERM) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Zones Sécurisées",
            message = "Vous n'avez pas la permission de gérer les zones safe.",
        })
        return nil
    end

    return xPlayer
end

--- Nettoie ce que le menu envoie : les points arrivent avec des champs superflus, et le
--- nom sert de clé.
---@return table|nil
local function sanitize(name, label, points, height, actionDisabled, bypassJob)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" or #name > 64 then return nil end

    label = tostring(label or name):gsub("^%s+", ""):gsub("%s+$", "")
    if label == "" then label = name end

    if type(points) ~= "table" or #points < 3 then return nil end

    local clean = {}
    for i = 1, #points do
        local point = points[i]
        if type(point) == "table" and tonumber(point.x) and tonumber(point.y) then
            clean[#clean + 1] = {
                x = tonumber(point.x) + 0.0,
                y = tonumber(point.y) + 0.0,
                z = tonumber(point.z) or 0.0,
            }
        end
    end

    if #clean < 3 then return nil end

    return {
        name = name,
        label = label:sub(1, 100),
        points = clean,
        height = math.max(1.0, tonumber(height) or 10.0),
        actionDisabled = type(actionDisabled) == "table" and actionDisabled or {},
        bypassJob = type(bypassJob) == "table" and bypassJob or {},
    }
end

RegisterServerCallback("core:getAllSafeZones", function()
    -- Appelé par chaque joueur au chargement : pas de permission, c'est une donnée de monde.
    return zones
end)

RegisterNetEvent("zonesafe:server:create", function(name, label, points, height, actionDisabled, bypassJob)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    local zone = sanitize(name, label, points, height, actionDisabled, bypassJob)
    if not zone then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Zones Sécurisées",
            message = "Zone invalide : il faut un nom et au moins 3 points.",
        })
        return
    end

    if findZone(zone.name) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Zones Sécurisées",
            message = ("Une zone nommée « %s » existe déjà."):format(zone.name),
        })
        return
    end

    MySQL.insert.await([[
        INSERT INTO safe_zones (name, label, points, height, action_disabled, bypass_job)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        zone.name, zone.label, encode(zone.points), zone.height,
        encode(zone.actionDisabled), encode(zone.bypassJob),
    })

    zones[#zones + 1] = zone
    TriggerClientEvent("zonesafe:client:add", -1, zone)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Zones Sécurisées",
        message = ("Zone « %s » créée."):format(zone.label),
    })
end)

RegisterNetEvent("zonesafe:server:update", function(oldName, name, label, points, height, actionDisabled, bypassJob)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    oldName = tostring(oldName or "")

    local existing, index = findZone(oldName)
    if not existing then return end

    local zone = sanitize(name, label, points, height, actionDisabled, bypassJob)
    if not zone then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Zones Sécurisées",
            message = "Zone invalide : il faut un nom et au moins 3 points.",
        })
        return
    end

    if zone.name ~= oldName and findZone(zone.name) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Zones Sécurisées",
            message = ("Une zone nommée « %s » existe déjà."):format(zone.name),
        })
        return
    end

    MySQL.update.await([[
        UPDATE safe_zones SET name = ?, label = ?, points = ?, height = ?,
            action_disabled = ?, bypass_job = ? WHERE name = ?
    ]], {
        zone.name, zone.label, encode(zone.points), zone.height,
        encode(zone.actionDisabled), encode(zone.bypassJob), oldName,
    })

    zones[index] = zone
    TriggerClientEvent("zonesafe:client:update", -1, oldName, zone)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Zones Sécurisées",
        message = ("Zone « %s » modifiée."):format(zone.label),
    })
end)

RegisterNetEvent("zonesafe:server:delete", function(name)
    local source = source
    local xPlayer = builder(source)
    if not xPlayer then return end

    name = tostring(name or "")

    local zone, index = findZone(name)
    if not zone then return end

    MySQL.update.await("DELETE FROM safe_zones WHERE name = ?", { name })
    table.remove(zones, index)
    TriggerClientEvent("zonesafe:client:remove", -1, name)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Zones Sécurisées",
        message = ("Zone « %s » supprimée."):format(zone.label or name),
    })
end)

--- Le joueur entre dans une zone qui interdit les armes : on lui demande de rengainer.
RegisterNetEvent("zonesafe:server:forceHolster", function()
    TriggerClientEvent("zonesafe:client:holster", source)
end)

MySQL.ready(function()
    local ok, err = pcall(function()
        ensureTable()
        loadZones()
    end)

    if not ok then
        console.error("[zones safe] chargement impossible : " .. tostring(err))
    end
end)

--- Les joueurs demandent la liste eux-mêmes au chargement (ZoneSafe:SyncSafeZone). Ce
--- filet couvre celui qui se connecte pendant le démarrage, avant que la table soit lue.
AddEventHandler("vfw:playerLoaded", function(xPlayer)
    if not loaded or #zones == 0 then return end

    local target = type(xPlayer) == "table" and xPlayer.source or xPlayer
    if not target then return end

    TriggerClientEvent("zonesafe:client:sync", target, zones)
end)
