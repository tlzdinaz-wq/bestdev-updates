---@meta _
---@diagnostic disable: duplicate-doc-field

-- Sous-menu natif "Serveur" du hub Gestion (météo, heure, stats, zone).

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

local function EnvSnapshot()
    local hour, minute = GetClockHours(), GetClockMinutes()
    local weather, freezeWeather, freezeTime = "EXTRASUNNY", false, false
    local env = TriggerServerCallback("weatherManager:getData")
    if type(env) == "table" then
        local cfg = type(env.config) == "table" and env.config or {}
        weather = env.globalWeather or cfg.globalWeather or weather
        freezeWeather = env.freezeWeather == true or cfg.freezeWeather == true
        freezeTime = env.freezeTime == true or cfg.freezeTime == true
        hour = tonumber(env.hour) or tonumber(cfg.inGameHour) or hour
        minute = tonumber(env.minute) or tonumber(cfg.inGameMinute) or minute
    end
    return {
        weather = weather,
        freezeWeather = freezeWeather,
        freezeTime = freezeTime,
        hour = hour,
        minute = math.floor((tonumber(minute) or 0) / 5) * 5,
    }
end

local function Stats()
    return TriggerServerCallback("vfw:staff:getServerStats") or {}
end

local function Payload(extra)
    local env = EnvSnapshot()
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    local data = {
        ok = true,
        weathers = WEATHERS,
        weather = env.weather,
        hour = env.hour,
        minute = env.minute,
        freezeWeather = env.freezeWeather,
        freezeTime = env.freezeTime,
        stats = Stats(),
        canClean = perms["clean_zone"] == true,
    }
    if type(extra) == "table" then
        for k, v in pairs(extra) do data[k] = v end
    end
    return data
end

RegisterNuiCallback("gestion:server:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer le serveur." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:server:previewWeather", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local value = data and data.value
    if type(value) ~= "string" then cb({ ok = false }) return end
    SetWeatherTypeNow(value)
    SetWeatherTypeOvertimePersist(value, 5.0)
    StaffMenu.weatherPreviewActive = true
    cb({ ok = true })
end)

RegisterNuiCallback("gestion:server:setWeather", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local value = data and data.value
    if type(value) ~= "string" then cb({ ok = false, error = "Météo invalide." }) return end
    StaffMenu.weatherPreviewActive = false
    TriggerServerEvent("vfw:staff:setWeather", value)
    local label = value
    for i = 1, #WEATHERS do
        if WEATHERS[i].value == value then label = WEATHERS[i].label break end
    end
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Serveur',
        message = "Météo appliquée : " .. label .. ".",
    })
    cb({ ok = true, weather = value })
end)

RegisterNuiCallback("gestion:server:freezeWeather", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local freeze = data and data.freeze == true
    TriggerServerEvent("vfw:staff:freezeWeather", freeze)
    cb({ ok = true, freezeWeather = freeze })
end)

RegisterNuiCallback("gestion:server:setTime", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local hour = math.max(0, math.min(23, math.floor(tonumber(data and data.hour) or 0)))
    local minute = math.max(0, math.min(59, math.floor(tonumber(data and data.minute) or 0)))
    TriggerServerEvent("vfw:staff:setTime", hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
    SetClockTime(hour, minute, 0)
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Serveur',
        message = string.format("Temps changé : %02d:%02d.", hour, minute),
    })
    cb({ ok = true, hour = hour, minute = minute })
end)

RegisterNuiCallback("gestion:server:freezeTime", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local freeze = data and data.freeze == true
    TriggerServerEvent("vfw:staff:freezeTime", freeze)
    cb({ ok = true, freezeTime = freeze })
end)

RegisterNuiCallback("gestion:server:cleanZone", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    if not perms["clean_zone"] then
        cb({ ok = false, error = "Vous n'avez pas la permission de nettoyer la zone." })
        return
    end
    local radius = tonumber(data and data.radius)
    if not radius or radius <= 0 then
        cb({ ok = false, error = "Indique un rayon valide." })
        return
    end
    TriggerServerEvent("vfw:staff:clearZone", radius)
    cb({ ok = true })
end)

RegisterNuiCallback("gestion:server:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    TriggerServerEvent("vfw:staff:refreshServerData")
    cb(Payload())
end)

RegisterNuiCallback("gestion:server:tablet", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb({ ok = true, opens = "weather" })
end)
