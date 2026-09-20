---@meta _
---@diagnostic disable: duplicate-doc-field

local trafficPosThread = false

-- Cache local des zones actives pour l'enforcement de vitesse
local activeZones = {}
local currentZoneSpeed = nil -- vitesse de la zone dans laquelle le joueur se trouve (nil = hors zone)
local enforcementThread = false

--- OpenCerculationenu - Opens the MDT on the circulation tab
function OpenCerculationenu()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous devez être en service pour utiliser ce menu.",
        })
        return
    end

    VFW.Nui.policePanel(true)
    SendNUIMessage({
        action = "nui:PolicePanel:openTool",
        data = "circulation"
    })
end

-- ============================================================
-- Speed enforcement thread
-- Tourne en permanence, verifie si le joueur est dans une zone
-- et bride le vehicule en consequence
-- ============================================================

local function startEnforcementThread()
    if enforcementThread then return end
    enforcementThread = true

    CreateThread(function()
        while enforcementThread do
            local ped = PlayerPedId()

            if IsPedInAnyVehicle(ped, false) and #activeZones > 0 then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local driver = GetPedInVehicleSeat(vehicle, -1)

                -- Seulement si le joueur est conducteur
                if driver == ped then
                    local pos = GetEntityCoords(ped)
                    local inZoneSpeed = nil

                    -- Trouver la zone la plus restrictive dans laquelle le joueur se trouve
                    for _, zone in ipairs(activeZones) do
                        local zp = zone.zonePos
                        local dx = pos.x - zp.x
                        local dy = pos.y - zp.y
                        local dist = math.sqrt(dx * dx + dy * dy)

                        if dist <= zone.zoneRadius then
                            if not inZoneSpeed or zone.zoneSpeed < inZoneSpeed then
                                inZoneSpeed = zone.zoneSpeed
                            end
                        end
                    end

                    if inZoneSpeed then
                        local limitMs = inZoneSpeed / 3.6 -- km/h -> m/s

                        -- Appliquer la limite max + notif a l'entree
                        if currentZoneSpeed ~= inZoneSpeed then
                            local wasOutside = currentZoneSpeed == nil
                            currentZoneSpeed = inZoneSpeed
                            SetVehicleMaxSpeed(vehicle, limitMs)

                            if wasOutside then
                                VFW.ShowNotification({
                                    type = "BLEU",
                                    content = "Zone de circulation - Limite : " .. math.floor(inZoneSpeed) .. " km/h"
                                })
                            end
                        end

                        -- Freinage progressif si au-dessus de la limite
                        local currentSpeed = GetEntitySpeed(vehicle) -- m/s
                        if currentSpeed > limitMs + 1.0 then
                            -- Reduire de 15% par tick pour un freinage smooth
                            local newSpeed = currentSpeed * 0.85
                            if newSpeed < limitMs then
                                newSpeed = limitMs
                            end
                            SetVehicleForwardSpeed(vehicle, newSpeed)
                        end
                    else
                        -- Hors zone : retirer la limite
                        if currentZoneSpeed then
                            currentZoneSpeed = nil
                            SetVehicleMaxSpeed(vehicle, 0.0) -- 0.0 = pas de limite
                        end
                    end
                end

                Wait(200)
            else
                -- Pas en vehicule ou aucune zone, check moins souvent
                if currentZoneSpeed then
                    currentZoneSpeed = nil
                    -- Reset la limite du véhicule si on vient d'en sortir
                    local veh = GetVehiclePedIsIn(ped, true)
                    if veh and veh ~= 0 then
                        SetVehicleMaxSpeed(veh, 0.0)
                    end
                end
                Wait(2000)
            end
        end
    end)
end

local function refreshZoneCache()
    local zones = TriggerServerCallback("core:jobs:traffic:get")
    activeZones = zones or {}

    if #activeZones > 0 then
        startEnforcementThread()
    end
end

-- ============================================================
-- Position thread management (started/stopped by the React component)
-- ============================================================

RegisterNUICallback("nui:trafficZones:startPosUpdates", function(_, cb)
    if not trafficPosThread then
        trafficPosThread = true
        CreateThread(function()
            while trafficPosThread do
                local coords = GetEntityCoords(PlayerPedId())
                SendNUIMessage({
                    action = "nui:trafficZones:updatePos",
                    data = {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z
                    }
                })
                Wait(2000)
            end
        end)
    end
    cb("ok")
end)

RegisterNUICallback("nui:trafficZones:stopPosUpdates", function(_, cb)
    trafficPosThread = false
    cb("ok")
end)

-- ============================================================
-- NUI Callbacks for traffic zones management
-- ============================================================

RegisterNUICallback("nui:trafficZones:getData", function(_, cb)
    local zones = TriggerServerCallback("core:jobs:traffic:get") or {}
    activeZones = zones -- update cache
    local playerCoords = GetEntityCoords(PlayerPedId())
    cb({
        zones = zones,
        playerPos = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }
    })
end)

RegisterNUICallback("nui:trafficZones:add", function(data, cb)
    if not data.zoneRadius or data.zoneRadius <= 0 then
        cb(nil)
        return
    end

    local pos = vector3(data.zonePos.x, data.zonePos.y, data.zonePos.z)
    local id = AddRoadNodeSpeedZone(pos, data.zoneRadius + 0.0, data.zoneSpeed + 0.0, true)

    local newZone = {
        zoneName = data.zoneName or "Zone",
        zonePos = { x = pos.x, y = pos.y, z = pos.z },
        zoneRadius = data.zoneRadius,
        zoneSpeed = data.zoneSpeed,
        zoneId = id,
        zoneDuration = data.zoneDuration or 30
    }

    TriggerServerEvent("core:jobs:traffic:add", newZone)

    -- Update local cache
    activeZones[#activeZones + 1] = newZone
    startEnforcementThread()

    cb(newZone)
end)

RegisterNUICallback("nui:trafficZones:remove", function(data, cb)
    if not data.zoneId then
        cb("ok")
        return
    end

    RemoveRoadNodeSpeedZone(data.zoneId)
    TriggerServerEvent("core:jobs:traffic:remove", data.zoneId)

    -- Update local cache
    for i = #activeZones, 1, -1 do
        if activeZones[i].zoneId == data.zoneId then
            table.remove(activeZones, i)
            break
        end
    end

    -- Reset la limite du véhicule actuel si on était dans cette zone
    if currentZoneSpeed then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleMaxSpeed(vehicle, 0.0)
        end
        currentZoneSpeed = nil
    end

    cb("ok")
end)

-- ============================================================
-- Sync events from other players
-- ============================================================

---@param zone any
RegisterNetEvent("core:jobs:traffic:addclient", function(zone)
    local pos = vector3(zone.zonePos.x + 0.0, zone.zonePos.y + 0.0, zone.zonePos.z + 0.0)
    AddRoadNodeSpeedZone(pos, zone.zoneRadius + 0.0, zone.zoneSpeed + 0.0, true)
    -- Update local cache for enforcement
    activeZones[#activeZones + 1] = zone
    startEnforcementThread()
end)

---@param zoneId any
RegisterNetEvent("core:jobs:traffic:removeclient", function(zoneId)
    RemoveRoadNodeSpeedZone(zoneId)
    -- Update local cache
    for i = #activeZones, 1, -1 do
        if activeZones[i].zoneId == zoneId then
            table.remove(activeZones, i)
            break
        end
    end

    -- Reset la limite du véhicule actuel
    if currentZoneSpeed then
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleMaxSpeed(vehicle, 0.0)
        end
        currentZoneSpeed = nil
    end
end)

-- ============================================================
-- Load zones on player ready
-- ============================================================

RegisterNetEvent("vfw:playerReady", function()
    refreshZoneCache()
end)
