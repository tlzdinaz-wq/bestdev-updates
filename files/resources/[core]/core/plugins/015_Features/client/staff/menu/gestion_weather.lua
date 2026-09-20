---@meta _
---@diagnostic disable: duplicate-doc-field

-- Panneau natif "Météo par zone" du hub Gestion (sans overlay tablette).

local WEATHERS = {
    { label = "Clair", value = "CLEAR" },
    { label = "Très ensoleillé", value = "EXTRASUNNY" },
    { label = "Nuageux", value = "CLOUDS" },
    { label = "Couvert", value = "OVERCAST" },
    { label = "Pluie", value = "RAIN" },
    { label = "Éclaircie", value = "CLEARING" },
    { label = "Orage", value = "THUNDER" },
    { label = "Brouillard épais", value = "SMOG" },
    { label = "Brumeux", value = "FOGGY" },
    { label = "Noël", value = "XMAS" },
    { label = "Neige légère", value = "SNOWLIGHT" },
    { label = "Blizzard", value = "BLIZZARD" },
}

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["server_management"] == true
end

local function CopyZones(raw)
    local zones = {}
    if type(raw) ~= "table" then return zones end
    for i = 1, #raw do
        zones[i] = raw[i]
    end
    return zones
end

local function CirclePolygon(cx, cy, radius, steps)
    local poly = {}
    local n = steps or 16
    for i = 0, n - 1 do
        local a = (i / n) * math.pi * 2
        poly[#poly + 1] = { x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius }
    end
    return poly
end

local function Payload()
    local env = TriggerServerCallback("weatherManager:getData")
    if type(env) ~= "table" then
        return { ok = false, error = "Impossible de charger les zones météo." }
    end
    local cfg = type(env.config) == "table" and env.config or {}
    local coords = GetEntityCoords(PlayerPedId())
    local hour = tonumber(env.hour) or tonumber(cfg.inGameHour) or GetClockHours()
    local minute = tonumber(env.minute) or tonumber(cfg.inGameMinute) or GetClockMinutes()
    return {
        ok = true,
        weathers = WEATHERS,
        zones = CopyZones(env.zones),
        weather = env.globalWeather or cfg.globalWeather or "EXTRASUNNY",
        freezeWeather = env.freezeWeather == true or cfg.freezeWeather == true,
        freezeTime = env.freezeTime == true or cfg.freezeTime == true,
        hour = hour,
        minute = math.floor((tonumber(minute) or 0) / 5) * 5,
        player = { x = coords.x + 0.0, y = coords.y + 0.0 },
    }
end

RegisterNuiCallback("gestion:weather:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer la météo." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:weather:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Payload())
end)

RegisterNuiCallback("gestion:weather:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" then cb({ ok = false, error = "Données invalides." }) return end
    local name = type(data.name) == "string" and data.name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then
        cb({ ok = false, error = "Indique un nom de zone." })
        return
    end
    local weather = type(data.weather) == "string" and data.weather or "EXTRASUNNY"
    local polygon = data.polygon
    if type(polygon) ~= "table" or #polygon < 3 then
        local radius = tonumber(data.radius)
        if not radius or radius < 20 or radius > 2500 then
            cb({ ok = false, error = "Dessine un polygone (3 points) ou indique un rayon entre 20 et 2500 m." })
            return
        end
        local coords = GetEntityCoords(PlayerPedId())
        polygon = CirclePolygon(coords.x, coords.y, radius, 16)
    end
    local result = TriggerServerCallback("weatherManager:createZone", {
        name = name,
        weather = weather,
        polygon = polygon,
        active = true,
    })
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.error) or "Impossible de créer la zone." })
        return
    end
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Météo',
        message = "Zone '" .. name .. "' créée.",
    })
    cb(Payload())
end)

RegisterNuiCallback("gestion:weather:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local result = TriggerServerCallback("weatherManager:updateZone", {
        zoneId = data.zoneId,
        name = data.name,
        weather = data.weather,
        active = data.active,
    })
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.error) or "Mise à jour impossible." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:weather:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if not data or data.zoneId == nil then
        cb({ ok = false, error = "Zone invalide." })
        return
    end
    local result = TriggerServerCallback("weatherManager:deleteZone", data.zoneId)
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.error) or "Suppression impossible." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:weather:setGlobalWeather", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local value = data and data.value
    if type(value) ~= "string" then cb({ ok = false, error = "Météo invalide." }) return end
    TriggerServerEvent("weatherManager:setGlobalWeather", value)
    local label = value
    for i = 1, #WEATHERS do
        if WEATHERS[i].value == value then label = WEATHERS[i].label break end
    end
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Météo',
        message = "Météo globale : " .. label .. ".",
    })
    cb({ ok = true, weather = value })
end)

RegisterNuiCallback("gestion:weather:freezeWeather", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local freeze = data and data.freeze == true
    TriggerServerEvent("weatherManager:setFreezeWeather", freeze)
    cb({ ok = true, freezeWeather = freeze })
end)

RegisterNuiCallback("gestion:weather:setTime", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local hour = math.max(0, math.min(23, math.floor(tonumber(data and data.hour) or 0)))
    local minute = math.max(0, math.min(59, math.floor(tonumber(data and data.minute) or 0)))
    local result = TriggerServerCallback("weatherManager:setTime", { hour = hour, minute = minute })
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.error) or "Impossible de changer l’heure." })
        return
    end
    NetworkOverrideClockTime(hour, minute, 0)
    SetClockTime(hour, minute, 0)
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Météo',
        message = string.format("Heure appliquée : %02d:%02d.", hour, minute),
    })
    cb({ ok = true, hour = hour, minute = minute })
end)

RegisterNuiCallback("gestion:weather:freezeTime", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local freeze = data and data.freeze == true
    TriggerServerEvent("weatherManager:setFreezeTime", freeze)
    cb({ ok = true, freezeTime = freeze })
end)
