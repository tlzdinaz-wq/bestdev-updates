---@meta _
---@diagnostic disable: duplicate-doc-field

-- Panneau natif "King of the Hill" du hub Gestion.

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["builder_koth"] == true or perms["koth"] == true
end

local function DefaultRadius()
    return (type(KOTHConfig) == "table" and tonumber(KOTHConfig.defaultRadius)) or 50
end

local function DefaultDuration()
    return (type(KOTHConfig) == "table" and tonumber(KOTHConfig.defaultDuration)) or 15
end

local function CirclePolygon(cx, cy, radius, steps)
    local poly = {}
    local n = steps or 24
    local r = tonumber(radius) or DefaultRadius()
    for i = 0, n - 1 do
        local a = (i / n) * math.pi * 2
        poly[#poly + 1] = { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r }
    end
    return poly
end

local function CopyHours(raw)
    local hours = {}
    if type(raw) ~= "table" then return hours end
    for i = 1, #raw do
        hours[#hours + 1] = tostring(raw[i])
    end
    return hours
end

local function ParseHours(value)
    local hours = {}
    if type(value) == "table" then
        for i = 1, #value do
            local entry = tostring(value[i] or "")
            local h, m = entry:match("^(%d+):(%d+)$")
            if not h then
                h = entry:match("^(%d+)$")
                m = "0"
            end
            h, m = tonumber(h), tonumber(m)
            if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 then
                hours[#hours + 1] = ("%d:%02d"):format(h, m)
            end
        end
        return hours
    end
    if type(value) ~= "string" or value == "" then return hours end
    for entry in value:gmatch("[^,]+") do
        entry = entry:match("^%s*(.-)%s*$")
        local h, m = entry:match("^(%d+):(%d+)$")
        if not h then
            h = entry:match("^(%d+)$")
            m = "0"
        end
        h, m = tonumber(h), tonumber(m)
        if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 then
            hours[#hours + 1] = ("%d:%02d"):format(h, m)
        end
    end
    return hours
end

local function GroundZ(x, y)
    local found, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 1000.0, false)
    if found then return z end
    return 50.0
end

local function Payload()
    local zones = TriggerServerCallback("koth:getZones") or {}
    local active = TriggerServerCallback("koth:getActive")
    local history = TriggerServerCallback("koth:getHistory") or {}
    local coords = GetEntityCoords(PlayerPedId())
    local list = {}
    local activeId = active and active.id
    for i = 1, #zones do
        local z = zones[i]
        local cx = tonumber(z.x) or (z.coords and tonumber(z.coords.x)) or 0.0
        local cy = tonumber(z.y) or (z.coords and tonumber(z.coords.y)) or 0.0
        local cz = tonumber(z.z) or (z.coords and tonumber(z.coords.z)) or 0.0
        local radius = tonumber(z.radius) or DefaultRadius()
        local running = activeId ~= nil and tostring(activeId) == tostring(z.id)
        local range = type(z.scheduleRange) == "table" and z.scheduleRange or {}
        list[#list + 1] = {
            id = z.id,
            name = z.name,
            x = cx, y = cy, z = cz,
            radius = radius,
            duration = tonumber(z.duration) or DefaultDuration(),
            enabled = z.enabled == true,
            scheduleHours = CopyHours(z.scheduleHours),
            scheduleStart = z.scheduleStart or range.start,
            scheduleEnd = z.scheduleEnd or range.finish,
            running = running,
            color = running and "#FFB300" or "#e53935",
            active = z.enabled == true,
            polygon = CirclePolygon(cx, cy, radius, 24),
        }
    end
    local hist = {}
    for i = 1, #history do
        local h = history[i]
        hist[#hist + 1] = {
            id = h.id,
            zone_id = h.zone_id,
            zone_name = h.zone_name,
            winner_faction = h.winner_faction,
            winner_score = h.winner_score,
            started_at = tostring(h.started_at or ""),
            ended_at = tostring(h.ended_at or ""),
        }
    end
    return {
        ok = true,
        zones = list,
        active = active,
        history = hist,
        defaults = { radius = DefaultRadius(), duration = DefaultDuration() },
        player = { x = coords.x + 0.0, y = coords.y + 0.0 },
    }
end

RegisterNuiCallback("gestion:koth:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer le KOTH." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" then cb({ ok = false, error = "Données invalides." }) return end
    local name = type(data.name) == "string" and data.name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then
        cb({ ok = false, error = "Indique un nom de zone." })
        return
    end
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y then
        local coords = GetEntityCoords(PlayerPedId())
        x, y, z = coords.x, coords.y, coords.z
    elseif not z then
        z = GroundZ(x, y)
    end
    local radius = tonumber(data.radius) or DefaultRadius()
    local duration = tonumber(data.duration) or DefaultDuration()
    local id = TriggerServerCallback("koth:createZone", {
        name = name,
        x = x, y = y, z = z,
        radius = radius,
        duration = duration,
        scheduleHours = ParseHours(data.scheduleHours),
    })
    if not id then
        cb({ ok = false, error = "Impossible de créer la zone." })
        return
    end
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Zone '" .. name .. "' créée." })
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local id = data.zoneId
    local ok = true
    if data.name ~= nil then
        ok = TriggerServerCallback("koth:updateZone", id, "name", data.name) and ok
    end
    if data.enabled ~= nil then
        ok = TriggerServerCallback("koth:updateZone", id, "enabled", data.enabled == true) and ok
    end
    if data.radius ~= nil then
        ok = TriggerServerCallback("koth:updateZone", id, "radius", tonumber(data.radius)) and ok
    end
    if data.duration ~= nil then
        ok = TriggerServerCallback("koth:updateZone", id, "duration", tonumber(data.duration)) and ok
    end
    if data.scheduleHours ~= nil then
        ok = TriggerServerCallback("koth:updateZone", id, "scheduleHours", ParseHours(data.scheduleHours)) and ok
    end
    if data.scheduleStart ~= nil or data.scheduleEnd ~= nil then
        local startH = data.scheduleStart
        local endH = data.scheduleEnd
        if startH == "" then startH = nil end
        if endH == "" then endH = nil end
        ok = TriggerServerCallback("koth:updateZone", id, "scheduleRange", { start = startH, finish = endH }) and ok
    end
    if not ok then
        cb({ ok = false, error = "Mise à jour impossible." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if not data or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local ok = TriggerServerCallback("koth:deleteZone", data.zoneId)
    if not ok then
        cb({ ok = false, error = "Suppression impossible." })
        return
    end
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Zone supprimée." })
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = Payload()
    local id = data and tonumber(data.zoneId)
    for i = 1, #payload.zones do
        local z = payload.zones[i]
        if tonumber(z.id) == id then
            SetEntityCoords(PlayerPedId(), z.x, z.y, z.z + 1.0, false, false, false, false)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Téléporté sur " .. tostring(z.name) .. "." })
            payload.player = { x = z.x, y = z.y }
            cb(payload)
            return
        end
    end
    cb({ ok = false, error = "Zone introuvable." })
end)

RegisterNuiCallback("gestion:koth:start", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if not data or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local ok = TriggerServerCallback("koth:forceStart", data.zoneId)
    if not ok then
        cb({ ok = false, error = "Impossible (KOTH déjà en cours ou zone désactivée)." })
        return
    end
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "KOTH démarré." })
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:stop", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local withWinner = data and data.withWinner == true
    local ok = TriggerServerCallback(withWinner and "koth:forceStopWithWinner" or "koth:forceStop")
    if not ok then
        cb({ ok = false, error = "Aucun KOTH en cours." })
        return
    end
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH',
        message = withWinner and "KOTH arrêté avec vainqueur." or "KOTH arrêté sans vainqueur.",
    })
    cb(Payload())
end)

RegisterNuiCallback("gestion:koth:clearHistory", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok = TriggerServerCallback("koth:clearHistory")
    if not ok then
        cb({ ok = false, error = "Impossible de vider l’historique." })
        return
    end
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'KOTH', message = "Historique vidé." })
    cb(Payload())
end)
