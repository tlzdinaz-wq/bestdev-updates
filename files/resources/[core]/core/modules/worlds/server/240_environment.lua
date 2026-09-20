local VARIABLE_NAME = "environment"

local WEATHER_TYPES = {
    CLEAR = true,
    EXTRASUNNY = true,
    CLOUDS = true,
    OVERCAST = true,
    RAIN = true,
    CLEARING = true,
    THUNDER = true,
    SMOG = true,
    FOGGY = true,
    XMAS = true,
    SNOWLIGHT = true,
    BLIZZARD = true,
    SNOW = true,
    HALLOWEEN = true,
    NEUTRAL = true,
}

local WEATHER_CYCLE = {
    "EXTRASUNNY",
    "CLEAR",
    "CLOUDS",
    "OVERCAST",
    "CLEARING",
    "RAIN",
    "THUNDER",
    "CLEARING",
    "CLOUDS",
    "SMOG",
    "FOGGY",
    "CLEAR",
}

local function convarNumber(name, default)
    local raw = GetConvar(name, tostring(default))
    return tonumber(raw) or default
end

local MS_PER_INGAME_MINUTE = math.max(50, convarNumber("core_time_scale", 2000))
local WEATHER_INTERVAL_MS = math.max(60000, convarNumber("core_weather_interval", 600000))

local env = {
    hour = 7,
    minute = 0,
    weather = "EXTRASUNNY",
    timeFrozen = false,
    weatherFrozen = false,
    cycleIndex = 1,
    loaded = false,
}

local dirty = false

VFW.Environment = VFW.Environment or {}

local function pushTime()
    GlobalState.EnvironmentTime = { hour = env.hour, minute = env.minute }
    GlobalState.EnvironmentTimeFrozen = env.timeFrozen
end

local function pushWeather()
    GlobalState.EnvironmentWeather = env.weather
    GlobalState.EnvironmentWeatherFrozen = env.weatherFrozen
end

local function persist()
    if not dirty then return end
    dirty = false
    if not VFW.Variables or not VFW.Variables.SetVariable then return end
    VFW.Variables.SetVariable(VARIABLE_NAME, {
        hour = env.hour,
        minute = env.minute,
        weather = env.weather,
        timeFrozen = env.timeFrozen,
        weatherFrozen = env.weatherFrozen,
        cycleIndex = env.cycleIndex,
    })
end

local function broadcastTime(target)
    TriggerClientEvent("core:sync:setTime", target or -1, env.hour, env.minute)
end

function VFW.Environment.GetTime()
    return env.hour, env.minute
end

function VFW.Environment.GetWeather()
    return env.weather
end

function VFW.Environment.IsTimeFrozen()
    return env.timeFrozen
end

function VFW.Environment.IsWeatherFrozen()
    return env.weatherFrozen
end

function VFW.Environment.SetTime(hour, minute, silent)
    hour = tonumber(hour)
    minute = tonumber(minute) or 0

    if not hour then return false end

    hour = math.floor(hour) % 24
    minute = math.floor(minute) % 60

    env.hour = hour
    env.minute = minute
    dirty = true

    pushTime()

    if not silent then
        broadcastTime()
    end

    TriggerEvent("vfw:environment:timeChanged", env.hour, env.minute)
    return true
end

function VFW.Environment.SetWeather(weather, silent)
    if type(weather) ~= "string" then return false end

    weather = weather:upper()
    if not WEATHER_TYPES[weather] then return false end

    env.weather = weather
    dirty = true

    pushWeather()

    if not silent then
        TriggerEvent("vfw:environment:weatherChanged", env.weather)
    end

    return true
end

function VFW.Environment.SetTimeFrozen(frozen)
    env.timeFrozen = frozen and true or false
    dirty = true
    pushTime()
    return env.timeFrozen
end

function VFW.Environment.SetWeatherFrozen(frozen)
    env.weatherFrozen = frozen and true or false
    dirty = true
    pushWeather()
    return env.weatherFrozen
end

function VFW.Environment.SyncTo(source)
    source = tonumber(source)
    if not source or source <= 0 then return end
    broadcastTime(source)
end

function VFW.Environment.GetWeatherTypes()
    local out, n = {}, 0
    for name in pairs(WEATHER_TYPES) do
        n = n + 1
        out[n] = name
    end
    table.sort(out)
    return out
end

pushTime()
pushWeather()

local function restore()
    if not VFW.Variables or not VFW.Variables.GetVariable then return end

    local saved = VFW.Variables.GetVariable(VARIABLE_NAME)
    if type(saved) ~= "table" then return end

    if tonumber(saved.hour) then env.hour = math.floor(tonumber(saved.hour)) % 24 end
    if tonumber(saved.minute) then env.minute = math.floor(tonumber(saved.minute)) % 60 end
    if type(saved.weather) == "string" and WEATHER_TYPES[saved.weather:upper()] then
        env.weather = saved.weather:upper()
    end
    if tonumber(saved.cycleIndex) then
        env.cycleIndex = math.floor(tonumber(saved.cycleIndex))
        if env.cycleIndex < 1 or env.cycleIndex > #WEATHER_CYCLE then env.cycleIndex = 1 end
    end
    env.timeFrozen = saved.timeFrozen and true or false
    env.weatherFrozen = saved.weatherFrozen and true or false
end

AddEventHandler("vfw:sync:requestTime", function(source)
    VFW.Environment.SyncTo(source)
end)

AddEventHandler("vfw:environment:setTime", function(hour, minute)
    VFW.Environment.SetTime(hour, minute)
end)

AddEventHandler("vfw:environment:setWeather", function(weather)
    VFW.Environment.SetWeather(weather)
end)

AddEventHandler("vfw:environment:freezeTime", function(frozen)
    VFW.Environment.SetTimeFrozen(frozen)
end)

AddEventHandler("vfw:environment:freezeWeather", function(frozen)
    VFW.Environment.SetWeatherFrozen(frozen)
end)

AddEventHandler("vfw:characterLoaded", function(source)
    VFW.Environment.SyncTo(source)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    VFW.Environment.SyncTo(source)
end)

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end

    Wait(2000)
    restore()
    env.loaded = true

    pushTime()
    pushWeather()
    broadcastTime()

    console.init("Environment", ("Heure %02d:%02d - meteo %s"):format(env.hour, env.minute, env.weather))

    local lastHour = env.hour

    while true do
        Wait(MS_PER_INGAME_MINUTE)

        if not env.timeFrozen then
            env.minute = env.minute + 1
            if env.minute >= 60 then
                env.minute = 0
                env.hour = (env.hour + 1) % 24
            end

            pushTime()
            broadcastTime()

            if env.hour ~= lastHour then
                lastHour = env.hour
                dirty = true
                persist()
            end
        end
    end
end)

CreateThread(function()
    Wait(5000)

    while true do
        Wait(WEATHER_INTERVAL_MS)

        if not env.weatherFrozen then
            env.cycleIndex = env.cycleIndex + 1
            if env.cycleIndex > #WEATHER_CYCLE then env.cycleIndex = 1 end

            VFW.Environment.SetWeather(WEATHER_CYCLE[env.cycleIndex])
            persist()
        end
    end
end)

CreateThread(function()
    while not VFW.RegisterCommand do Wait(250) end
    Wait(1000)

    local existing = VFW.GetRegisteredCommands and VFW.GetRegisteredCommands() or {}

    if not existing["time"] then
        VFW.RegisterCommand("time", "time", function(source, xPlayer, args)
            local hour = tonumber(args[1])
            local minute = tonumber(args[2]) or 0

            if not hour then
                if xPlayer then
                    xPlayer.showNotification({
                        type = "STAFF",
                        variant = "ERROR",
                        subtitle = "Heure",
                        message = "Usage : /time <heure> [minute]",
                    })
                end
                return
            end

            VFW.Environment.SetTime(hour, minute)

            local newHour, newMinute = VFW.Environment.GetTime()

            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "SUCCESS",
                    subtitle = "Heure",
                    message = ("Heure du serveur reglee sur %02d:%02d."):format(newHour, newMinute),
                })
            else
                console.info(("Heure du serveur reglee sur %02d:%02d."):format(newHour, newMinute))
            end
        end, {
            help = "Change l'heure du serveur.",
            params = {
                { name = "heure", help = "0-23" },
                { name = "minute", help = "0-59 (optionnel)" },
            },
            allowConsole = true,
        })
    end

    if not existing["weather"] then
        VFW.RegisterCommand("weather", "weather", function(source, xPlayer, args)
            local weather = args[1]

            if not VFW.Environment.SetWeather(weather) then
                if xPlayer then
                    xPlayer.showNotification({
                        type = "STAFF",
                        variant = "ERROR",
                        subtitle = "Meteo",
                        message = "Ce type de meteo n'est pas valide.",
                    })
                else
                    console.warn(("Types valides : %s"):format(table.concat(VFW.Environment.GetWeatherTypes(), ", ")))
                end
                return
            end

            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "SUCCESS",
                    subtitle = "Meteo",
                    message = ("Meteo du serveur reglee sur %s."):format(VFW.Environment.GetWeather()),
                })
            end
        end, {
            help = "Change la meteo du serveur.",
            params = { { name = "type", help = "EXTRASUNNY, CLEAR, RAIN, THUNDER..." } },
            allowConsole = true,
        })
    end

    if not existing["freezetime"] then
        VFW.RegisterCommand("freezetime", "freezetime", function(source, xPlayer)
            local frozen = VFW.Environment.SetTimeFrozen(not VFW.Environment.IsTimeFrozen())

            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "SUCCESS",
                    subtitle = "Heure",
                    message = frozen and "Heure bloquee." or "Heure debloquee.",
                })
            end
        end, { help = "Bloque ou debloque l'heure du serveur.", allowConsole = true })
    end

    if not existing["freezeweather"] then
        VFW.RegisterCommand("freezeweather", "freezeweather", function(source, xPlayer)
            local frozen = VFW.Environment.SetWeatherFrozen(not VFW.Environment.IsWeatherFrozen())

            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "SUCCESS",
                    subtitle = "Meteo",
                    message = frozen and "Meteo bloquee." or "Meteo debloquee.",
                })
            end
        end, { help = "Bloque ou debloque la meteo du serveur.", allowConsole = true })
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    dirty = true
    persist()
end)
