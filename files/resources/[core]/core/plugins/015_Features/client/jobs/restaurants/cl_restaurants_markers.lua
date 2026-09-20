local COLORS = {
    burgershot = {r = 255, g = 130, b = 0},
    pizzeria = {r = 255, g = 50, b = 50},
    bean_coffee = {r = 139, g = 69, b = 19},
    noodle = {r = 255, g = 215, b = 0},
    pearls = {r = 100, g = 149, b = 237},
    uwu_cafe = {r = 255, g = 182, b = 193}
}

local CONFIGS = {
    { config = "BurgerShotConfig", color = "burgershot" },
    { config = "PizzeriaConfig", color = "pizzeria" },
    { config = "BeanCoffeeConfig", color = "bean_coffee" },
    { config = "NoodleConfig", color = "noodle" },
    { config = "PearlsConfig", color = "pearls" },
    { config = "UwuCafeConfig", color = "uwu_cafe" }
}

local STATION_KEYS = {
    "Machine", "SteakStation", "GrillStation", "FryerStation",
    "OvenStation", "BrothStation", "CraftingTable", "MilkshakeStation",
    "GranitaStation"
}

local markers = {}

local function buildMarkers()
    markers = {}
    for _, entry in ipairs(CONFIGS) do
        local cfg = _G[entry.config]
        if cfg and cfg.Locations then
            local color = COLORS[entry.color]
            for jobName, loc in pairs(cfg.Locations) do
                for _, stationKey in ipairs(STATION_KEYS) do
                    local station = loc[stationKey]
                    if station then
                        local radius = station.radius or 1.0
                        local zOffset = loc.markerZOffset or -0.48
                        if station.slots then
                            for _, slotData in pairs(station.slots) do
                                if slotData.pos then
                                    markers[#markers + 1] = { coords = slotData.pos, hideRadius = radius, color = color, jobName = jobName, zOffset = zOffset }
                                end
                            end
                        elseif station.coords then
                            markers[#markers + 1] = { coords = station.coords, hideRadius = radius, color = color, jobName = jobName, zOffset = zOffset }
                        elseif station.center then
                            markers[#markers + 1] = { coords = station.center, hideRadius = radius, color = color, jobName = jobName, zOffset = zOffset }
                        end
                    end
                end
            end
        end
    end
end

local active = false
local markerScale = vector3(0.35, 0.35, 0.35)
local drawDistance = 8.0

local function getPlayerRestaurantJob()
    if not VFW.PlayerData or not VFW.PlayerData.job or not VFW.PlayerData.job.onDuty then
        return nil
    end
    return VFW.PlayerData.job.name
end

local function startLoop()
    if active then return end
    active = true

    buildMarkers()

    CreateThread(function()
        while active do
            local sleep = 1000
            local playerJob = getPlayerRestaurantJob()

            if playerJob then
                local playerCoords = GetEntityCoords(PlayerPedId())

                for _, marker in ipairs(markers) do
                    if marker.jobName == playerJob then
                        local distance = #(playerCoords - marker.coords)

                        if distance < drawDistance and distance > marker.hideRadius then
                            sleep = 0

                            DrawMarker(
                                21,
                                marker.coords.x, marker.coords.y, marker.coords.z + marker.zOffset,
                                0.0, 0.0, 0.0,
                                180.0, 0.0, 0.0,
                                markerScale.x, markerScale.y, markerScale.z,
                                marker.color.r, marker.color.g, marker.color.b, 180,
                                true, true, 2, false, nil, nil, false
                            )
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

local function stopLoop()
    active = false
end

RegisterNetEvent("vfw:setJob", function()
    Wait(500)
    if getPlayerRestaurantJob() then
        startLoop()
    else
        stopLoop()
    end
end)

RegisterNetEvent("vfw:playerLoaded", function()
    while not VFW.PlayerData do
        Wait(1000)
    end
    while not VFW.PlayerData.job do
        Wait(1000)
    end

    if getPlayerRestaurantJob() then
        startLoop()
    end
end)

RegisterNetEvent("vfw:client:changeDuty", function()
    Wait(200)
    if getPlayerRestaurantJob() then
        startLoop()
    else
        stopLoop()
    end
end)

-- Reconstruit les markers après déplacement depuis le builder F10
AddEventHandler("restaurant_stations:rebuild", function()
    if active then buildMarkers() end
end)
