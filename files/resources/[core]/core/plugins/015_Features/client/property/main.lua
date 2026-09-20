---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Properties = {}
VFW.ActualProperty = nil
VFW.PropertyMenuOpen = false
local heistHouse = {}
local blips = {}
local propertyPositions = {}
local vehiclePositions = {}  -- id -> vec3 for garage vehicle entry points

--- .EnterProperty
---@param id number|string
---@return any
function VFW.EnterProperty(id)
    local property = TriggerServerCallback("vfw:getProperty", id)
    if not property then
        console.debug("Property not found")
        return
    end

    VFW.ActualProperty = id
    VFW.OpenUIProperty(property)
end

---Create Point
---@param id number|string
---@param pos vector3|table Position
---@param typeProperty any
---@param vehiclePosData table|nil Vehicle entry position for garages
local function createPoint(id, pos, typeProperty, vehiclePosData)
    if typeProperty == "Habitation" then
        heistHouse[id] = pos
    end

    local posVec = vec3(pos.x, pos.y, pos.z)
    propertyPositions[id] = posVec
    VFW.Properties[id] = { pos = posVec, type = typeProperty }

    if vehiclePosData and vehiclePosData.x then
        vehiclePositions[id] = vec3(vehiclePosData.x, vehiclePosData.y, vehiclePosData.z)
    end
end

local lastCheckedId = nil
local lastIsLocked = true
local lastVehCheckedId = nil
local lastVehHasAccess = false

--- DrawMarker thread for property entrance
CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestId, nearestPos, nearestDist = nil, nil, 8.0

        for id, pos in pairs(propertyPositions) do
            local dist = #(playerCoords - pos)
            if dist < nearestDist then
                nearestId = id
                nearestPos = pos
                nearestDist = dist
            end
        end

        -- Also check vehicle entry points
        local nearestVehId, nearestVehPos, nearestVehDist = nil, nil, 8.0
        for id, pos in pairs(vehiclePositions) do
            local dist = #(playerCoords - pos)
            if dist < nearestVehDist then
                nearestVehId = id
                nearestVehPos = pos
                nearestVehDist = dist
            end
        end

        -- Check if player is driving a vehicle
        local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local isInVehicle = playerVehicle ~= 0 and GetPedInVehicleSeat(playerVehicle, -1) == PlayerPedId()

        local hasNearby = nearestPos or nearestVehPos
        if hasNearby then
            sleep = 0
        end

        -- Draw pedestrian marker (green) — only when on foot
        if nearestPos and not isInVehicle then
            local _, groundZ = GetGroundZFor_3dCoord(nearestPos.x, nearestPos.y, nearestPos.z + 2.0, false)
            DrawMarker(25, nearestPos.x, nearestPos.y, groundZ + 0.02, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.5, 45, 124, 40, 120, false, true, 2, false, nil, nil, false)

            if nearestDist < 1.5 and not VFW.PropertyMenuOpen then
                if lastCheckedId ~= nearestId then
                    lastCheckedId = nearestId
                    local canAccess = TriggerServerCallback("vfw:property:canManage", nearestId)
                    lastIsLocked = not canAccess
                end

                VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ pour" .. (lastIsLocked and " sonner" or " entrer"), nil, false)
                if VFW.Interact.JustPressed(0, 51) then
                    VFW.EnterProperty(nearestId)
                end
            else
                lastCheckedId = nil
            end
        else
            lastCheckedId = nil
        end

        -- Vehicle entry marker — only visible to players with access, only when in vehicle
        if nearestVehId and isInVehicle then
            -- Check access (cached per property id)
            if lastVehCheckedId ~= nearestVehId then
                lastVehCheckedId = nearestVehId
                lastVehHasAccess = TriggerServerCallback("vfw:property:canManage", nearestVehId)
            end

            if lastVehHasAccess and nearestVehPos then
                DrawMarker(36, nearestVehPos.x, nearestVehPos.y, nearestVehPos.z + 0.5, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.5, 255, 165, 0, 120, false, true, 2, false, nil, nil, false)

                if nearestVehDist < 3.0 and not VFW.PropertyMenuOpen then
                    VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ Entrer le véhicule dans le garage", nil, false)
                    if VFW.Interact.JustPressed(0, 51) then
                        local model = GetEntityModel(playerVehicle)
                        local props = VFW.Game.GetVehicleProperties(playerVehicle)
                        -- Fallback plaque : state bag souvent absent sur les imports.
                        local plate = (Entity(playerVehicle).state.VehicleProperties and Entity(playerVehicle).state.VehicleProperties.plate)
                            or (props and props.plate)
                            or VFW.Math.Trim(GetVehicleNumberPlateText(playerVehicle))

                        -- Fade out before server despawns the vehicle
                        DoScreenFadeOut(500)
                        Wait(500)

                        local result, enterProperty = TriggerServerCallback("vfw:enterVehicle", nearestVehId, plate, GetMakeNameFromVehicleModel(model), props)
                        if result then
                            VFW.ActualProperty = nearestVehId
                            VFW.EnterGarage(enterProperty)
                        else
                            DoScreenFadeIn(500)
                        end
                    end
                end
            end
        else
            lastVehCheckedId = nil
        end

        if not hasNearby then
            lastCheckedId = nil
            lastVehCheckedId = nil
        end

        Wait(sleep)
    end
end)

---@param properties any
RegisterNetEvent("vfw:loadProperty", createPoint)
---@param properties any
RegisterNetEvent("vfw:loadProperties", function(properties)
    for k, v in pairs(properties) do
        createPoint(k, v.pos, v.type, v.vehiclePos)
    end
end)

---@param id any
RegisterNetEvent("vfw:deleteProperty", function(id)
    propertyPositions[id] = nil
    vehiclePositions[id] = nil
    VFW.Properties[id] = nil
    if blips[id] then
        Worlds.Blips.Remove(blips[id])
        blips[id] = nil
    end
end)

---Get VFW.HeistHouse
---@return any
function VFW.GetHeistHouse()
    return heistHouse
end

local typeList = {
    ["Habitation"] = 40,
    ["Garage"] = 473,
    ["Stockage"] = 357
}

local typeLabel = {
    ["Habitation"] = "Habitation",
    ["Garage"] = "Garage",
    ["Stockage"] = "Entrepôt",
}

---@param data table
RegisterNetEvent("vfw:loadPropertiesBlips", function(data)
    lastCheckedId = nil
    lastVehCheckedId = nil

    for i, v in pairs(blips) do
        Worlds.Blips.Remove(v)
        blips[i] = nil
    end

    for k, v in pairs(data) do
        if v.pos.x == 0 and v.pos.y == 0 and v.pos.z == 0 then
            goto continue
        end

        local role
        if v.ownerKind == "job" then
            role = "Société " .. (v.ownerLabel or "")
        elseif v.ownerKind == "crew" then
            role = "Groupe " .. (v.ownerLabel or "")
        else
            role = v.isOwner and "Propriétaire" or "Co-propriétaire"
        end
        local label = (typeLabel[v.type] or v.type) .. " • " .. role .. " - " .. (v.name or "Propriété")
        blips[k] = Worlds.Blips.Create(vector3(v.pos.x, v.pos.y, v.pos.z), typeList[v.type], 2, 0.8, label)

        ::continue::
    end
end)
