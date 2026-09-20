---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.currentHour = 7
VFW.currentMinute = 0
VFW.currentWeather = "EXTRASUNNY"

local WEATHER_TRANSITION_DURATION = 15.0 -- Durée de transition en secondes

-- Désactiver la sync réseau native GTA pour éviter les conflits
SetWeatherOwnedByNetwork(false)

---Get TimeIcon
---@param hour any
---@return string
local function getTimeIcon(hour)
    if hour >= 20 or hour < 6 then
        return "nuit"
    elseif hour >= 6 and hour < 7 then
        return "debut"
    elseif hour >= 7 and hour < 9 then
        return "debut"
    elseif hour >= 9 and hour < 18 then
        return "jour"
    elseif hour >= 18 and hour < 20 then
        return "fin"
    end

    return "jour"
end

---Update NUIDisplay
local function updateNUIDisplay()
    local displayWeather = VFW.currentWeather
    local hour = tonumber(VFW.currentHour) or 12

    if hour >= 9 and hour < 18 then
        displayWeather = VFW.currentWeather
    else
        displayWeather = getTimeIcon(hour)
    end

    SendNUIMessage({
        action = "nui:weather-time:visible",
        data = {
            visible = true,
            hour = math.floor(VFW.currentHour),
            minute = math.floor(VFW.currentMinute),
            weather = displayWeather,
        }
    })
end

--- Appliquer la météo localement
---@param weather string
---@param instant boolean
local function applyWeather(weather, instant)
    if VFW.currentWeather == weather then return end

    local duration = instant and 0.0 or WEATHER_TRANSITION_DURATION
    SetWeatherTypeOvertimePersist(weather, duration)

    VFW.currentWeather = weather

    if weather == "XMAS" then
        SetForceVehicleTrails(true)
        SetForcePedFootstepsTracks(true)
    else
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
    end

    updateNUIDisplay()
end

-- Écouter les changements de GlobalState via StateBag
AddStateBagChangeHandler('EnvironmentWeather', 'global', function(bagName, key, weather)
    if weather then
        applyWeather(weather, false)
    end
end)

-- Initialisation météo au spawn (pour les joueurs qui rejoignent)
CreateThread(function()
    -- Attendre que le joueur soit chargé
    while not VFW.IsPlayerLoaded() do Wait(100) end

    -- Récupérer la météo actuelle du serveur via GlobalState
    local serverWeather = GlobalState.EnvironmentWeather
    if serverWeather then
        applyWeather(serverWeather, true)  -- instant = true pour le spawn
    end
end)

---@param hour any
---@param minute any
RegisterNetEvent("core:sync:setTime", function(hour, minute)
    -- Ignore time sync during character selection to keep nighttime frozen
    if Multicharacter and Multicharacter.inSelection then
        return
    end

    NetworkOverrideClockTime(hour, minute, 0)
    SetClockTime(hour, minute, 0)
    VFW.currentHour = hour
    VFW.currentMinute = minute

    updateNUIDisplay()
end)

VFW.GetCurrentTime = function()
    return {
        hour = math.floor(VFW.currentHour),
        minute = math.floor(VFW.currentMinute),
    }
end
