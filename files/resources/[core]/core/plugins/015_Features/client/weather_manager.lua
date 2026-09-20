---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
--  Weather Zone Manager - Client Side
--  Détection zone joueur + application météo par zone + tablette
-- ============================================================

local currentWeatherZone = nil
local weatherZones = {}
local WEATHER_TRANSITION_DURATION = 15.0

-- ── Point-in-polygon (ray casting) ──────────────────────────

local function isPointInPolygon(px, py, polygon)
    local n = #polygon
    if n < 3 then return false end

    local inside = false
    local j = n

    for i = 1, n do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        if ((yi > py) ~= (yj > py)) and
           (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end

    return inside
end

-- ── Détection de zone et application météo ──────────────────

local function findZoneAtPosition(x, y)
    for _, zone in ipairs(weatherZones) do
        if zone.active and zone.polygon and #zone.polygon >= 3 then
            if isPointInPolygon(x, y, zone.polygon) then
                return zone
            end
        end
    end
    return nil
end

local function applyZoneWeather(weather, instant)
    local duration = instant and 0.0 or WEATHER_TRANSITION_DURATION
    SetWeatherTypeOvertimePersist(weather, duration)

    if weather == "XMAS" then
        SetForceVehicleTrails(true)
        SetForcePedFootstepsTracks(true)
    else
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
    end
end

local function refreshZoneWeather(instant)
    if #weatherZones == 0 then
        if currentWeatherZone then
            currentWeatherZone = nil
            local globalWeather = GlobalState.EnvironmentWeather
            if globalWeather then applyZoneWeather(globalWeather, instant == true) end
        end
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    local zone = findZoneAtPosition(coords.x, coords.y)
    if zone then
        if instant or not currentWeatherZone or currentWeatherZone.id ~= zone.id then
            currentWeatherZone = zone
            applyZoneWeather(zone.weather, instant == true)
        else
            currentWeatherZone = zone
        end
        return
    end

    if currentWeatherZone then
        currentWeatherZone = nil
        local globalWeather = GlobalState.EnvironmentWeather
        if globalWeather then applyZoneWeather(globalWeather, instant == true) end
    end
end

AddStateBagChangeHandler('WeatherZones', 'global', function(_, _, zones)
    if type(zones) == "table" then
        weatherZones = zones
        refreshZoneWeather(true)
    end
end)

-- Thread de détection de zone (toutes les 5 secondes)
CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(500) end

    -- Charger les zones initiales
    local initialZones = GlobalState.WeatherZones
    if initialZones then
        weatherZones = initialZones
    end

    while true do
        Wait(2000)
        refreshZoneWeather(false)
    end
end)

-- ── Tablette Staff - Ouvrir/Fermer ──────────────────────────

local isTabletOpen = false

--- L'UI React attend { zones[], config: { globalWeather, freezeWeather, freezeTime, inGameHour, inGameMinute } }.
--- Sans `config`, le rendu plante → curseur NUI sans interface.
local function WeatherManagerPayload(raw)
    if type(raw) ~= "table" then return nil end

    local zones = {}
    if type(raw.zones) == "table" then
        for i = 1, #raw.zones do
            zones[i] = raw.zones[i]
        end
    end

    local cfg = type(raw.config) == "table" and raw.config or {}
    local globalWeather = cfg.globalWeather or raw.globalWeather or "EXTRASUNNY"
    local freezeWeather = cfg.freezeWeather
    if freezeWeather == nil then freezeWeather = raw.freezeWeather == true end
    local freezeTime = cfg.freezeTime
    if freezeTime == nil then freezeTime = raw.freezeTime == true end
    local hour = tonumber(cfg.inGameHour) or tonumber(raw.hour) or 12
    local minute = tonumber(cfg.inGameMinute) or tonumber(raw.minute) or 0

    return {
        zones = zones,
        config = {
            globalWeather = globalWeather,
            freezeWeather = freezeWeather == true,
            freezeTime = freezeTime == true,
            inGameHour = hour,
            inGameMinute = minute,
        },
        globalWeather = globalWeather,
        freezeWeather = freezeWeather == true,
        freezeTime = freezeTime == true,
        hour = hour,
        minute = minute,
        weatherTypes = raw.weatherTypes,
        isStaff = raw.isStaff,
    }
end

local function FetchWeatherManagerPayload()
    return WeatherManagerPayload(TriggerServerCallback("weatherManager:getData"))
end

function OpenWeatherManagerTablet()
    if isTabletOpen then return true end

    local data = FetchWeatherManagerPayload()
    if not data then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Météo', message = "Impossible de charger les données météo." })
        return false
    end

    isTabletOpen = true
    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        StaffMenu.CoverGestionHub()
    end
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "openWeatherManager",
        data = data
    })
    return true
end

function CloseWeatherManagerTablet()
    if not isTabletOpen then return end
    isTabletOpen = false
    SendNUIMessage({ action = "closeWeatherManager" })
    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        StaffMenu.UncoverGestionHub()
    else
        VFW.Nui.Focus(false, false)
    end
end

-- ── NUI Callbacks ───────────────────────────────────────────

RegisterNUICallback("weatherManager:close", function(_, cb)
    CloseWeatherManagerTablet()
    cb("ok")
end)

RegisterNUICallback("weatherManager:refresh", function(_, cb)
    cb(FetchWeatherManagerPayload() or { zones = {}, config = {} })
end)

RegisterNUICallback("weatherManager:createZone", function(data, cb)
    TriggerServerEvent("weatherManager:createZone", data)
    Wait(500)
    cb(FetchWeatherManagerPayload() or { zones = {}, config = {} })
end)

RegisterNUICallback("weatherManager:deleteZone", function(data, cb)
    TriggerServerEvent("weatherManager:deleteZone", data.zoneId)
    Wait(500)
    cb(FetchWeatherManagerPayload() or { zones = {}, config = {} })
end)

RegisterNUICallback("weatherManager:updateZone", function(data, cb)
    TriggerServerEvent("weatherManager:updateZone", data)
    Wait(500)
    cb(FetchWeatherManagerPayload() or { zones = {}, config = {} })
end)

RegisterNUICallback("weatherManager:setGlobalWeather", function(data, cb)
    TriggerServerEvent("weatherManager:setGlobalWeather", data.weather)
    cb("ok")
end)

RegisterNUICallback("weatherManager:setFreezeWeather", function(data, cb)
    TriggerServerEvent("weatherManager:setFreezeWeather", data.freeze)
    cb("ok")
end)

RegisterNUICallback("weatherManager:setTime", function(data, cb)
    TriggerServerEvent("weatherManager:setTime", data.hour, data.minute)
    cb("ok")
end)

RegisterNUICallback("weatherManager:setFreezeTime", function(data, cb)
    TriggerServerEvent("weatherManager:setFreezeTime", data.freeze)
    cb("ok")
end)
