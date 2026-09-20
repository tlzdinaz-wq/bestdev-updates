---
--- Carte Points - Client
--- Interactions flottantes "CARTE" placees par le staff
--- A proximite d'un point, le joueur peut appuyer sur E pour ouvrir la carte du bar/restau lie
---

local activeZones = {}

local function ZoneId(jobName, index)
    return ("cartepoint_%s_%d"):format(jobName, index)
end

local function GetBarLabel(jobName)
    if BarsConfig then
        for _, bar in ipairs(BarsConfig) do
            if bar.jobName == jobName then
                return bar.label or jobName
            end
        end
    end
    return jobName
end

local function ClearJobZones(jobName)
    if not activeZones[jobName] then return end
    for _, id in ipairs(activeZones[jobName]) do
        FloatingUI.Remove(id)
    end
    activeZones[jobName] = nil
end

local function ApplyJobPoints(jobName, points)
    ClearJobZones(jobName)
    if not points or #points == 0 then return end

    activeZones[jobName] = {}
    local label = GetBarLabel(jobName)

    for i, pt in ipairs(points) do
        local id = ZoneId(jobName, i)
        FloatingUI.Create(id, vector3(pt.x, pt.y, pt.z), 1.5, {
            title = "CARTE",
            subtitle = label,
            size = "small",
            buttons = {
                {
                    label = "Consulter",
                    key = "E",
                    icon = "coffee",
                    action = function()
                        TriggerEvent("bar:menu:openFromItem", jobName)
                    end
                }
            }
        })
        activeZones[jobName][#activeZones[jobName] + 1] = id
    end
end

local function LoadAll()
    local data = TriggerServerCallback("bar:cartePoints:getAll")
    if type(data) ~= "table" then return end

    for jobName in pairs(activeZones) do
        if data[jobName] == nil then
            ClearJobZones(jobName)
        end
    end

    for jobName, points in pairs(data) do
        ApplyJobPoints(jobName, points)
    end
end

CreateThread(function()
    while VFW.PlayerData == nil do Wait(250) end
    Wait(500)
    LoadAll()
end)

RegisterNetEvent("vfw:playerLoaded", function()
    Wait(500)
    LoadAll()
end)

RegisterNetEvent("bar:cartePoints:sync", function(jobName, points)
    if not jobName then return end
    ApplyJobPoints(jobName, points or {})
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for jobName in pairs(activeZones) do
        ClearJobZones(jobName)
    end
end)
