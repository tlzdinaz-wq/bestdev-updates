local WEATHER_VAR = "weather_zones"
local weatherZones = {}
local nextZoneId = 1

local VALID_WEATHER = {
    CLEAR = true, EXTRASUNNY = true, CLOUDS = true, OVERCAST = true, RAIN = true,
    CLEARING = true, THUNDER = true, SMOG = true, FOGGY = true, XMAS = true,
    SNOWLIGHT = true, BLIZZARD = true, SNOW = true, HALLOWEEN = true, NEUTRAL = true,
}

local function pushZones()
    local copy = {}
    for i = 1, #weatherZones do
        copy[i] = weatherZones[i]
    end
    GlobalState.WeatherZones = copy
end

local function persistZones()
    if not VFW.Variables or not VFW.Variables.SetVariable then return end
    pcall(VFW.Variables.SetVariable, WEATHER_VAR, { zones = weatherZones, nextId = nextZoneId })
end

local function loadZones()
    if not VFW.Variables or not VFW.Variables.GetVariable then return end
    local ok, saved = pcall(VFW.Variables.GetVariable, WEATHER_VAR)
    if not ok or type(saved) ~= "table" then return end
    if type(saved.zones) == "table" then weatherZones = saved.zones end
    if tonumber(saved.nextId) then nextZoneId = math.floor(tonumber(saved.nextId)) end
end

local function sanitizePolygon(polygon)
    if type(polygon) ~= "table" then return nil end
    local out = {}
    for i = 1, #polygon do
        local p = polygon[i]
        if type(p) == "table" then
            local x, y = tonumber(p.x), tonumber(p.y)
            if not x or not y then return nil end
            out[#out + 1] = { x = x + 0.0, y = y + 0.0 }
        end
    end
    if #out < 3 or #out > 64 then return nil end
    return out
end

local function findZone(zoneId)
    for i = 1, #weatherZones do
        if tostring(weatherZones[i].id) == tostring(zoneId) then return i end
    end
    return nil
end

local function isStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("server_management")
        or xPlayer.hasPermission("weather")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function createZoneFromData(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local polygon = sanitizePolygon(data.polygon or data.points)
    if not polygon then return nil, "Polygone invalide (minimum 3 points)." end
    local weather = MiscB.Str(data.weather, 24)
    if not weather or not VALID_WEATHER[weather:upper()] then return nil, "Météo invalide." end
    local zone = {
        id = nextZoneId,
        name = MiscB.Str(data.name, 64) or ("Zone " .. nextZoneId),
        weather = weather:upper(),
        polygon = polygon,
        active = data.active ~= false,
    }
    nextZoneId = nextZoneId + 1
    weatherZones[#weatherZones + 1] = zone
    pushZones()
    persistZones()
    return zone
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(2500)
    loadZones()
    pushZones()
end)

MiscB.Cb("weatherManager:getData", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local hour, minute = 0, 0
    if VFW.Environment and VFW.Environment.GetTime then
        hour, minute = VFW.Environment.GetTime()
    end

    local weatherTypes = {}
    for name in pairs(VALID_WEATHER) do weatherTypes[#weatherTypes + 1] = name end
    table.sort(weatherTypes)

    local globalWeather = VFW.Environment and VFW.Environment.GetWeather() or "EXTRASUNNY"
    local freezeWeather = VFW.Environment and VFW.Environment.IsWeatherFrozen() or false
    local freezeTime = VFW.Environment and VFW.Environment.IsTimeFrozen() or false
    local zonesOut = {}
    for i = 1, #weatherZones do
        zonesOut[i] = weatherZones[i]
    end

    -- L'UI tablette lit data.config (globalWeather / inGameHour / freeze*), pas les champs à plat.
    local config = {
        globalWeather = globalWeather,
        freezeWeather = freezeWeather == true,
        freezeTime = freezeTime == true,
        inGameHour = hour,
        inGameMinute = minute,
    }

    return {
        zones = zonesOut,
        config = config,
        globalWeather = globalWeather,
        freezeWeather = freezeWeather == true,
        freezeTime = freezeTime == true,
        hour = hour,
        minute = minute,
        weatherTypes = weatherTypes,
        isStaff = isStaff(source) ~= nil,
    }
end)

MiscB.Cb("weatherManager:createZone", function(source, data)
    if not isStaff(source) then return { ok = false, error = "Permission refusée." } end
    local zone, err = createZoneFromData(data)
    if not zone then return { ok = false, error = err or "Création impossible." } end
    return { ok = true, zone = zone, zones = weatherZones }
end)

RegisterNetEvent("weatherManager:createZone", function(data)
    local source = source
    if not isStaff(source) then return end
    createZoneFromData(data)
end)

RegisterNetEvent("weatherManager:updateZone", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not isStaff(source) then return end

    local index = findZone(data.zoneId or data.id)
    if not index then return end
    local zone = weatherZones[index]

    if data.name ~= nil then zone.name = MiscB.Str(data.name, 64) or zone.name end
    if data.weather ~= nil then
        local weather = MiscB.Str(data.weather, 24)
        if weather and VALID_WEATHER[weather:upper()] then zone.weather = weather:upper() end
    end
    if data.polygon ~= nil or data.points ~= nil then
        local polygon = sanitizePolygon(data.polygon or data.points)
        if polygon then zone.polygon = polygon end
    end
    if data.active ~= nil then zone.active = data.active == true end

    pushZones()
    persistZones()
end)

RegisterNetEvent("weatherManager:deleteZone", function(zoneId)
    local source = source
    if not isStaff(source) then return end
    local index = findZone(zoneId)
    if not index then return end
    table.remove(weatherZones, index)
    pushZones()
    persistZones()
end)

RegisterNetEvent("weatherManager:setGlobalWeather", function(weather)
    local source = source
    if not isStaff(source) then return end
    local w = MiscB.Str(weather, 24)
    if not w or not VALID_WEATHER[w:upper()] then return end
    if VFW.Environment and VFW.Environment.SetWeather then
        VFW.Environment.SetWeather(w:upper())
    end
end)

RegisterNetEvent("weatherManager:setFreezeWeather", function(freeze)
    local source = source
    if not isStaff(source) then return end
    if VFW.Environment and VFW.Environment.SetWeatherFrozen then
        VFW.Environment.SetWeatherFrozen(freeze == true)
    end
end)

RegisterNetEvent("weatherManager:setFreezeTime", function(freeze)
    local source = source
    if not isStaff(source) then return end
    if VFW.Environment and VFW.Environment.SetTimeFrozen then
        VFW.Environment.SetTimeFrozen(freeze == true)
    end
end)

RegisterNetEvent("weatherManager:setTime", function(hour, minute)
    local source = source
    if not isStaff(source) then return end
    local h = MiscB.ToInt(hour, 0, 23)
    local m = MiscB.ToInt(minute, 0, 59) or 0
    if h == nil then return end
    if VFW.Environment and VFW.Environment.SetTime then
        VFW.Environment.SetTime(h, m)
    end
end)

MiscB.Cb("weatherManager:setTime", function(source, data)
    if not isStaff(source) then return { ok = false, error = "Permission refusée." } end
    data = type(data) == "table" and data or {}
    local h = MiscB.ToInt(data.hour, 0, 23)
    local m = MiscB.ToInt(data.minute, 0, 59) or 0
    if h == nil then return { ok = false, error = "Heure invalide." } end
    if not (VFW.Environment and VFW.Environment.SetTime) then
        return { ok = false, error = "Système d'heure indisponible." }
    end
    VFW.Environment.SetTime(h, m)
    return { ok = true, hour = h, minute = m }
end)

MiscB.Cb("weatherManager:updateZone", function(source, data)
    if not isStaff(source) then return { ok = false, error = "Permission refusée." } end
    if type(data) ~= "table" then return { ok = false, error = "Données invalides." } end
    local index = findZone(data.zoneId or data.id)
    if not index then return { ok = false, error = "Zone introuvable." } end
    local zone = weatherZones[index]
    if data.name ~= nil then zone.name = MiscB.Str(data.name, 64) or zone.name end
    if data.weather ~= nil then
        local weather = MiscB.Str(data.weather, 24)
        if weather and VALID_WEATHER[weather:upper()] then zone.weather = weather:upper() end
    end
    if data.polygon ~= nil or data.points ~= nil then
        local polygon = sanitizePolygon(data.polygon or data.points)
        if polygon then zone.polygon = polygon end
    end
    if data.active ~= nil then zone.active = data.active == true end
    pushZones()
    persistZones()
    return { ok = true, zones = weatherZones }
end)

MiscB.Cb("weatherManager:deleteZone", function(source, zoneId)
    if not isStaff(source) then return { ok = false, error = "Permission refusée." } end
    local index = findZone(zoneId)
    if not index then return { ok = false, error = "Zone introuvable." } end
    table.remove(weatherZones, index)
    pushZones()
    persistZones()
    return { ok = true, zones = weatherZones }
end)

local ambientStarts = {}

RegisterNetEvent("core:ambientSound:requestSync", function(zoneId)
    local source = source
    if zoneId == nil then return end
    local id = tostring(zoneId)
    if #id > 64 then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not ambientStarts[id] then ambientStarts[id] = GetGameTimer() end
    local elapsed = math.floor((GetGameTimer() - ambientStarts[id]) / 1000)
    if elapsed < 0 then elapsed = 0 end

    TriggerClientEvent("core:ambientSound:syncTimestamp", source, zoneId, elapsed)
end)

RegisterNetEvent("esx_ambulanceJob:checkStatus", function(modelName)
    local source = source
    if type(modelName) ~= "string" or #modelName > 32 then return end

    TriggerEvent("vfw:ac:flag", source, "trap_vehicle", { model = modelName })

    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.kick("Vehicule piege detecte (teleportation illegitime).")
    else
        DropPlayer(source, "Vehicule piege detecte (teleportation illegitime).")
    end
end)
