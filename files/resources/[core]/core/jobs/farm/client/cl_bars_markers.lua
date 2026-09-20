---
--- Markers au sol pour les points de recolte des bars
--- Fleches type 21 inversees par rapport aux restaurants
---

local BAR_CONFIGS = {
    { jobName = "unicorn", config = "UnicornBarConfig" },
    { jobName = "yellowjack", config = "YellowJackBarConfig" },
    { jobName = "asgard", config = "AsgardBarConfig" },
    { jobName = "irishpub", config = "IrishPubBarConfig" },
    { jobName = "henhouse", config = "HenHouseBarConfig" },
    { jobName = "billard", config = "BillardBarConfig" },
    { jobName = "cayo_lagoon", config = "CayoLagoonBarConfig" },
}

local COLOR = {r = 255, g = 180, b = 50}

local dynamicHarvest = {}
local dynamicProcessing = {}

for _, bar in ipairs(BAR_CONFIGS) do
    RegisterNetEvent("farm:" .. bar.jobName .. ":syncZones", function(zones)
        if zones then
            dynamicHarvest[bar.jobName] = zones.harvestPoints or nil
            if zones.processingPoints then
                dynamicProcessing[bar.jobName] = zones.processingPoints
            end
        else
            dynamicHarvest[bar.jobName] = nil
            dynamicProcessing[bar.jobName] = nil  -- reset to nil (array or nil)
        end
    end)
end

local active = false
local markerScale = vector3(0.35, 0.35, 0.35)
local drawDistance = 8.0
local hideRadius = 1.0

local function getPlayerBarJob()
    if not VFW.PlayerData or not VFW.PlayerData.job then
        return nil
    end
    local jobName = VFW.PlayerData.job.name
    for _, bar in ipairs(BAR_CONFIGS) do
        if bar.jobName == jobName then
            return jobName
        end
    end
    return nil
end

local function getHarvestPoints(jobName)
    if dynamicHarvest[jobName] then
        return dynamicHarvest[jobName]
    end
    for _, bar in ipairs(BAR_CONFIGS) do
        if bar.jobName == jobName then
            local cfg = _G[bar.config]
            if cfg and cfg.harvest then
                return cfg.harvest
            end
        end
    end
    return {}
end

local function getProcessingPoints(jobName)
    -- Dynamic array override
    if dynamicProcessing[jobName] and #dynamicProcessing[jobName] > 0 then
        local points = {}
        for _, pt in ipairs(dynamicProcessing[jobName]) do
            points[#points + 1] = vector3(pt.x, pt.y, pt.z)
        end
        return points
    end

    -- Fallback: config par défaut
    local points = {}
    for _, bar in ipairs(BAR_CONFIGS) do
        if bar.jobName == jobName then
            local cfg = _G[bar.config]
            if cfg and cfg.processing then
                for _, coords in pairs(cfg.processing) do
                    points[#points + 1] = vector3(coords.x, coords.y, coords.z)
                end
            end
        end
    end
    return points
end

local function startLoop()
    if active then return end
    active = true

    CreateThread(function()
        while active do
            local sleep = 1000
            local playerJob = getPlayerBarJob()

            if playerJob then
                local playerCoords = GetEntityCoords(PlayerPedId())

                -- Markers recolte
                local harvestPts = getHarvestPoints(playerJob)
                for _, pt in ipairs(harvestPts) do
                    local coords = vector3(pt.x, pt.y, pt.z)
                    local distance = #(playerCoords - coords)

                    if distance < drawDistance and distance > hideRadius then
                        sleep = 0

                        DrawMarker(
                            21,
                            coords.x, coords.y, coords.z - 0.48,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            markerScale.x, markerScale.y, markerScale.z,
                            COLOR.r, COLOR.g, COLOR.b, 180,
                            true, true, 2, false, nil, nil, false
                        )
                    end
                end

                -- Markers transformation
                local processPts = getProcessingPoints(playerJob)
                for _, coords in ipairs(processPts) do
                    local distance = #(playerCoords - coords)

                    if distance < drawDistance and distance > hideRadius then
                        sleep = 0

                        DrawMarker(
                            21,
                            coords.x, coords.y, coords.z - 0.48,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            markerScale.x, markerScale.y, markerScale.z,
                            COLOR.r, COLOR.g, COLOR.b, 180,
                            true, true, 2, false, nil, nil, false
                        )
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
    if getPlayerBarJob() then
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

    if getPlayerBarJob() then
        startLoop()
    end
end)

RegisterNetEvent("vfw:client:changeDuty", function()
    Wait(200)
    if getPlayerBarJob() then
        startLoop()
    else
        stopLoop()
    end
end)
