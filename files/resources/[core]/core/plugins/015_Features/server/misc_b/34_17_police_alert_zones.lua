PoliceAlertZones = PoliceAlertZones or {}

local zones = {}
local loaded = false

local ALERT_TYPES = {
    { id = "generic", label = "Alerte générique", type = "backup", category = "backup", title = "Alerte test", icon = "fa-bell", level = 1, blipSprite = 161, blipColor = 3, color = "#7263EE", color2 = "#1e90ff" },
    { id = "gunshot", label = "Coups de feu", type = "gunshot", category = "gunshot", title = "Coups de feu", icon = "fa-gun", level = 2, blipSprite = 313, blipColor = 1, color = "#0000006e", color2 = "#c235166e" },
    { id = "panic", label = "Panic button", type = "panic", category = "panic", title = "Panic button", icon = "fa-triangle-exclamation", level = 3, blipSprite = 161, blipColor = 1, color = "#8b0000", color2 = "#ff3b3b" },
    { id = "backup", label = "Demande de renforts", type = "backup", category = "backup", title = "Renforts", icon = "fa-user-shield", level = 2, blipSprite = 58, blipColor = 3, color = "#1e90ff", color2 = "#7263EE" },
    { id = "pursuit", label = "Poursuite", type = "pursuit", category = "pursuit", title = "Poursuite", icon = "fa-car", level = 2, blipSprite = 229, blipColor = 1, color = "#fb8c00", color2 = "#e53935" },
}

local function encode(value)
    if VFW and VFW.DB and VFW.DB.Encode then
        return VFW.DB.Encode(value)
    end
    return json.encode(value or {})
end

local function decode(value, fallback)
    if VFW and VFW.DB and VFW.DB.Decode then
        return VFW.DB.Decode(value, fallback)
    end
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return fallback end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

local function ensureTable()
    MiscB.Query([[
        CREATE TABLE IF NOT EXISTS police_alert_zones (
            id INT NOT NULL AUTO_INCREMENT,
            name VARCHAR(64) NOT NULL,
            polygon LONGTEXT NOT NULL,
            assigned_jobs LONGTEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]], {})
end

local function sanitizePolygon(polygon)
    if type(polygon) ~= "table" then return nil end
    local out = {}
    for i = 1, #polygon do
        local p = polygon[i]
        if type(p) == "table" then
            local x = tonumber(p.x or p[1])
            local y = tonumber(p.y or p[2])
            if not x or not y then return nil end
            out[#out + 1] = { x = x + 0.0, y = y + 0.0 }
        end
    end
    if #out < 3 or #out > 64 then return nil end
    return out
end

local function cleanJob(raw)
    local name = tostring(raw or ""):lower():gsub("%s+", "")
    if name == "" or #name > 64 or not name:match("^[%w_%-]+$") then return nil end
    return name
end

local function sanitizeJobs(list)
    if type(list) ~= "table" then return {} end
    local out, seen = {}, {}
    for i = 1, #list do
        local name = cleanJob(list[i])
        if name and not seen[name] then
            seen[name] = true
            out[#out + 1] = name
        end
    end
    table.sort(out)
    return out
end

local function pointInPolygon(px, py, polygon)
    if type(polygon) ~= "table" or #polygon < 3 then return false end
    local inside = false
    local n = #polygon
    local j = n
    for i = 1, n do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y
        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / ((yj - yi) + 0.0) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function jobLabel(name)
    local jobs = VFW.Jobs or {}
    local def = jobs[name]
    if type(def) == "table" then return def.label or name end
    return name
end

local function policeJobs()
    local out, seen = {}, {}
    local function add(name)
        if type(name) ~= "string" or name == "" or seen[name] then return end
        seen[name] = true
        out[#out + 1] = { name = name, label = jobLabel(name) }
    end
    if type(PoliceJobsList) == "table" then
        for name in pairs(PoliceJobsList) do add(name) end
    end
    if #out == 0 and type(VFW.Jobs) == "table" then
        for name, def in pairs(VFW.Jobs) do
            if type(def) == "table" and def.type == "police" then add(name) end
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function publicZone(zone)
    return {
        id = zone.id,
        name = zone.name,
        polygon = zone.polygon,
        assigned_jobs = zone.assigned_jobs,
        color = "#7263EE",
        active = true,
    }
end

local function publicList()
    local out = {}
    for i = 1, #zones do
        out[i] = publicZone(zones[i])
    end
    return out
end

local function loadZones()
    ensureTable()
    zones = {}
    local rows = MiscB.Query("SELECT id, name, polygon, assigned_jobs FROM police_alert_zones ORDER BY id ASC", {})
    for i = 1, #rows do
        local row = rows[i]
        local polygon = sanitizePolygon(decode(row.polygon, {}))
        if polygon then
            zones[#zones + 1] = {
                id = tonumber(row.id),
                name = tostring(row.name or ("Zone " .. tostring(row.id))),
                polygon = polygon,
                assigned_jobs = sanitizeJobs(decode(row.assigned_jobs, {})),
            }
        end
    end
    loaded = true
end

local function findZone(zoneId)
    local wanted = tonumber(zoneId)
    if not wanted then return nil end
    for i = 1, #zones do
        if zones[i].id == wanted then return i, zones[i] end
    end
    return nil
end

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("manage_police_zones")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function cleanName(raw)
    local name = MiscB.Str(raw, 64)
    if not name then return nil end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name
end

function PoliceAlertZones.JobsAt(x, y)
    if not loaded then loadZones() end
    x, y = tonumber(x), tonumber(y)
    if not x or not y then return nil end

    local found = false
    local unrestricted = false
    local jobs, seen = {}, {}

    for i = 1, #zones do
        local zone = zones[i]
        if pointInPolygon(x, y, zone.polygon) then
            found = true
            local list = zone.assigned_jobs or {}
            if #list == 0 then
                unrestricted = true
                break
            end
            for j = 1, #list do
                local name = list[j]
                if not seen[name] then
                    seen[name] = true
                    jobs[#jobs + 1] = name
                end
            end
        end
    end

    if not found or unrestricted then return nil end
    return jobs
end

function PoliceAlertZones.BroadcastCall(stored)
    local Dispatch = VFW and VFW.Dispatch
    if not Dispatch then return end

    local coords = stored and stored.coords
    local jobs = nil
    if type(coords) == "table" then
        jobs = PoliceAlertZones.JobsAt(coords.x, coords.y)
    end

    if not jobs then
        if Dispatch.Broadcast then
            Dispatch.Broadcast("dispatch:client:receiveNotification", stored)
        end
        return
    end

    local lookup = {}
    for i = 1, #jobs do lookup[jobs[i]] = true end
    local players = VFW.GetPlayers()
    for i = 1, #players do
        local xPlayer = VFW.GetPlayerFromId(players[i])
        if xPlayer and xPlayer.job and lookup[xPlayer.job.name] then
            TriggerClientEvent("dispatch:client:receiveNotification", players[i], stored)
        end
    end
end

local function createZone(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local name = cleanName(data.name)
    if not name then return nil, "Indique un nom de zone." end
    local polygon = sanitizePolygon(data.polygon)
    if not polygon then return nil, "Polygone invalide (minimum 3 points)." end
    local jobs = sanitizeJobs(data.assigned_jobs)
    local id = MiscB.Insert(
        "INSERT INTO police_alert_zones (name, polygon, assigned_jobs) VALUES (?, ?, ?)",
        { name, encode(polygon), encode(jobs) }
    )
    if not id then return nil, "Impossible d'enregistrer la zone." end
    local zone = { id = id, name = name, polygon = polygon, assigned_jobs = jobs }
    zones[#zones + 1] = zone
    return zone
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(1500)
    loadZones()
end)

MiscB.Cb("policeAlertZones:getAll", function(source)
    if not staffOk(source) then return {} end
    if not loaded then loadZones() end
    return publicList()
end)

MiscB.Cb("policeAlertZones:getPoliceJobs", function(source)
    if not staffOk(source) then return {} end
    return policeJobs()
end)

MiscB.Cb("policeAlertZones:getAlertTypes", function(source)
    if not staffOk(source) then return {} end
    local out = {}
    for i = 1, #ALERT_TYPES do
        out[i] = { id = ALERT_TYPES[i].id, label = ALERT_TYPES[i].label }
    end
    return out
end)

MiscB.Cb("policeAlertZones:getPanel", function(source)
    if not staffOk(source) then return { ok = false } end
    if not loaded then loadZones() end
    return {
        ok = true,
        zones = publicList(),
        policeJobs = policeJobs(),
        alertTypes = (function()
            local out = {}
            for i = 1, #ALERT_TYPES do
                out[i] = { id = ALERT_TYPES[i].id, label = ALERT_TYPES[i].label }
            end
            return out
        end)(),
    }
end)

MiscB.Cb("policeAlertZones:create", function(source, data)
    if not staffOk(source) then return { ok = false, success = false, message = "Permission refusée." } end
    if not loaded then loadZones() end
    local zone, err = createZone(data)
    if not zone then
        return { ok = false, success = false, message = err or "Création impossible." }
    end
    return { ok = true, success = true, id = zone.id, zone = publicZone(zone), message = "Zone créée." }
end)

MiscB.Cb("policeAlertZones:update", function(source, data)
    if not staffOk(source) then return { ok = false, success = false, message = "Permission refusée." } end
    if type(data) ~= "table" then return { ok = false, success = false, message = "Données invalides." } end
    if not loaded then loadZones() end
    local index, zone = findZone(data.id or data.zoneId)
    if not zone then return { ok = false, success = false, message = "Zone introuvable." } end

    if data.name ~= nil then
        local name = cleanName(data.name)
        if not name then return { ok = false, success = false, message = "Nom invalide." } end
        zone.name = name
    end
    if data.polygon ~= nil then
        local polygon = sanitizePolygon(data.polygon)
        if not polygon then return { ok = false, success = false, message = "Polygone invalide." } end
        zone.polygon = polygon
    end
    if data.assigned_jobs ~= nil then
        zone.assigned_jobs = sanitizeJobs(data.assigned_jobs)
    end

    MiscB.Update(
        "UPDATE police_alert_zones SET name = ?, polygon = ?, assigned_jobs = ? WHERE id = ?",
        { zone.name, encode(zone.polygon), encode(zone.assigned_jobs), zone.id }
    )
    return { ok = true, success = true, zone = publicZone(zone) }
end)

MiscB.Cb("policeAlertZones:delete", function(source, data)
    if not staffOk(source) then return { ok = false, success = false, message = "Permission refusée." } end
    if not loaded then loadZones() end
    local id = data
    if type(data) == "table" then id = data.id or data.zoneId end
    local index, zone = findZone(id)
    if not zone then return { ok = false, success = false, message = "Zone introuvable." } end
    MiscB.Update("DELETE FROM police_alert_zones WHERE id = ?", { zone.id })
    table.remove(zones, index)
    return { ok = true, success = true }
end)

MiscB.Event("policeAlertZones:simulateAlert", function(alertTypeId, x, y, z)
    local source = source
    if not staffOk(source) then return end
    if not MiscB.Rate(source, "policeAlertZones:simulate", 3000) then return end

    local kind = nil
    for i = 1, #ALERT_TYPES do
        if ALERT_TYPES[i].id == tostring(alertTypeId or "") then
            kind = ALERT_TYPES[i]
            break
        end
    end
    if not kind then kind = ALERT_TYPES[1] end

    local coords = MiscB.PlayerCoords(source)
    x = tonumber(x) or (coords and coords.x) or 0.0
    y = tonumber(y) or (coords and coords.y) or 0.0
    z = tonumber(z) or (coords and coords.z) or 0.0

    local payload = {
        type = kind.type,
        category = kind.category,
        level = kind.level,
        code = kind.level,
        icon = kind.icon,
        jobName = "",
        unitNumber = "",
        street = "",
        coords = { x = x, y = y, z = z },
        title = kind.title,
        message = ("Simulation staff — %s"):format(kind.label),
        style = { useGradient = true, color = kind.color, color2 = kind.color2 },
        blipSprite = kind.blipSprite,
        blipColor = kind.blipColor,
        blipUseBig = true,
        blipBigSprite = 670,
        blipBigColor = kind.blipColor,
    }

    local Dispatch = VFW and VFW.Dispatch
    if Dispatch and Dispatch.PushCall then
        Dispatch.PushCall(payload)
        return
    end
    if Dispatch and Dispatch.StoreCall then
        PoliceAlertZones.BroadcastCall(Dispatch.StoreCall(payload))
    end
end)
