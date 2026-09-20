---@meta _
---@diagnostic disable: duplicate-doc-field

local garageVehicles = {}      -- entity -> plate mapping
local garageNetIds = {}        -- plate -> netId (server-spawned vehicles)
local garageMarkerActive = false
local garagePropertyId = nil
VFW.PropertyCanManage = false
VFW.PropertyGarageVehicles = {} -- exposed for NoCarJack exclusion
VFW.InsidePropertyGarage = false -- blocks vehicle key usage while in garage

--- Clear all non-player peds in radius
---@param coords vector3
---@param radius number
local function ClearInteriorPeds(coords, radius)
    local handle, ped = FindFirstPed()
    local success = true
    while success do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - coords) <= radius then
                DeleteEntity(ped)
            end
        end
        success, ped = FindNextPed(handle)
    end
    EndFindPed(handle)
end

--- Delete all garage vehicles (server-side cleanup via vehicle class)
--- excludePlate: plaque à NE PAS despawn (cas sortie-avec-véhicule : la même
--- VehicleClass est en train d'être re-spawn à l'extérieur par
--- exitGarageWithVehicle. Si on envoie despawnGarageVehicles pour cette
--- plaque, la race serveur entre les deux events peut faire despawn le
--- véhicule extérieur juste après son spawn).
local function DeleteGarageVehicles(excludePlate)
    if next(garageNetIds) then
        local plates = {}
        for plate, _ in pairs(garageNetIds) do
            if plate ~= excludePlate then
                plates[#plates + 1] = plate
            end
        end
        if #plates > 0 then
            TriggerServerEvent("vfw:property:despawnGarageVehicles", plates, garagePropertyId)
        end
    end
    garageVehicles = {}
    garageNetIds = {}
    VFW.PropertyGarageVehicles = {}
end

--- Draw a marker on the ground
---@param coords vector3|vector4
---@param r number
---@param g number
---@param b number
local function DrawGroundMarker(coords, r, g, b)
    DrawMarker(25, coords.x, coords.y, coords.z - 0.2, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.5, r, g, b, 120, false, true, 2, false, nil, nil, false)
end

--- Résout la config intérieure d'un garage depuis maxPlaces.
--- 1) Property.Garage.List[maxPlaces]  2) fallback scan data[].maxPlaces
---@param maxPlaces number|nil
---@return table|nil
local function resolveGarageConfig(maxPlaces)
    if type(maxPlaces) ~= "number" then return nil end
    local list = Property.Garage and Property.Garage.List
    local data = Property.Garage and Property.Garage.data
    if not data then return nil end

    local garageId = list and list[maxPlaces]
    if garageId and data[garageId] then
        return data[garageId]
    end

    for _, cfg in ipairs(data) do
        if cfg.maxPlaces == maxPlaces then
            return cfg
        end
    end
    return nil
end

--- Rollback : le serveur a déjà mis le joueur dans le bucket propriété.
local function abortGarageEnter(reason)
    VFW.InsidePropertyGarage = false
    garageMarkerActive = false
    local propId = garagePropertyId or VFW.ActualProperty
    if propId then
        TriggerServerEvent("vfw:leaveProperty", propId)
    end
    FreezeEntityPosition(VFW.PlayerData.ped, false)
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(500)
    end
    VFW.ShowNotification({
        type = "ROUGE",
        content = reason or "Impossible d'entrer dans ce garage."
    })
end

--- Enter garage physically
---@param property table Data from server (garageList, maxPlaces, name, advancedPerm, access, garageId)
function VFW.EnterGarage(property)
    garagePropertyId = VFW.ActualProperty

    local garageConfig = resolveGarageConfig(property and property.maxPlaces)
    if not garageConfig then
        console.debug("Garage config not found for maxPlaces:", property and property.maxPlaces)
        abortGarageEnter(("Intérieur garage introuvable (%s places). Contactez un staff."):format(tostring(property and property.maxPlaces)))
        return
    end

    VFW.PropertyCanManage = TriggerServerCallback("vfw:property:canManage", VFW.ActualProperty)
    VFW.InsidePropertyGarage = true
    garageMarkerActive = false

    -- Fade out and prepare
    DoScreenFadeOut(500)
    Wait(500)
    FreezeEntityPosition(VFW.PlayerData.ped, true)

    -- Pin interior in memory
    local leavePos = garageConfig.leave
    PinInteriorInMemory(GetInteriorAtCoords(leavePos.x, leavePos.y, leavePos.z))
    Wait(500)

    -- Teleport player to leave position (interior entry point)
    SetEntityCoords(VFW.PlayerData.ped, leavePos.x, leavePos.y, leavePos.z)
    SetEntityHeading(VFW.PlayerData.ped, leavePos.w)

    -- Spawn vehicles server-side (networked entities in the property routing bucket)
    DeleteGarageVehicles()
    local spawnPoints = garageConfig.spawnPoints

    -- Send spawn points as a simple indexed table for the server
    local spData = {}
    for i, sp in ipairs(spawnPoints) do
        spData[i] = { x = sp.x, y = sp.y, z = sp.z, w = sp.w or 0.0 }
    end

    local vehicleMap = TriggerServerCallback("vfw:property:spawnGarageVehicles", garagePropertyId, spData)

    if vehicleMap then
        for plate, netId in pairs(vehicleMap) do
            garageNetIds[plate] = netId
            -- Wait for entity to exist on client
            local timeout = 50
            while not NetworkDoesNetworkIdExist(netId) and timeout > 0 do
                Wait(50)
                timeout = timeout - 1
            end
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh and DoesEntityExist(veh) then
                garageVehicles[veh] = plate
                VFW.PropertyGarageVehicles[veh] = true
            end
        end
    end

    -- Clear interior peds
    Wait(200)
    ClearInteriorPeds(vec3(leavePos.x, leavePos.y, leavePos.z), 100.0)

    -- Unfreeze and fade in
    FreezeEntityPosition(VFW.PlayerData.ped, false)
    DoScreenFadeIn(500)

    -- Start threads
    garageMarkerActive = true

    -- Thread to detect when player enters a vehicle and auto-exit garage
    CreateThread(function()
        while garageMarkerActive do
            for veh, _ in pairs(garageVehicles) do
                if DoesEntityExist(veh) then
                    if GetVehicleDoorLockStatus(veh) ~= 1 then
                        SetVehicleDoorsLocked(veh, 1)
                    end
                end
            end

            local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
            if playerVeh ~= 0 and garageVehicles[playerVeh] then
                if IsEntityPositionFrozen(playerVeh) then
                    FreezeEntityPosition(playerVeh, false)
                end

                -- Auto-exit: player got in a garage vehicle
                local plate = garageVehicles[playerVeh]
                if plate then
                    garageMarkerActive = false
                    VFW.InsidePropertyGarage = false

                    -- Warp player into seat instantly and wait for animation to settle
                    TaskWarpPedIntoVehicle(PlayerPedId(), playerVeh, -1)
                    FreezeEntityPosition(playerVeh, true)
                    Wait(1500)

                    DoScreenFadeOut(500)
                    Wait(500)
                    DeleteGarageVehicles(plate)
                    TriggerServerEvent("vfw:property:exitGarageWithVehicle", garagePropertyId, plate)
                    Wait(2000)
                    DoScreenFadeIn(500)
                    return
                end
            end
            Wait(100)
        end
    end)

    -- Start marker thread
    local interactDist = 2.5

    local lastPermCheck = GetGameTimer()
    CreateThread(function()
        while garageMarkerActive do
            local sleep = 500
            local now = GetGameTimer()
            if now - lastPermCheck > 10000 then
                lastPermCheck = now
                VFW.PropertyCanManage = TriggerServerCallback("vfw:property:canManage", VFW.ActualProperty)
            end
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distLeave = #(playerCoords - vec3(leavePos.x, leavePos.y, leavePos.z))

            if distLeave < 10.0 then
                sleep = 0
                DrawGroundMarker(leavePos, 45, 124, 40)

                if distLeave < interactDist then
                    local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    local isInVehicle = playerVehicle ~= 0 and GetPedInVehicleSeat(playerVehicle, -1) == PlayerPedId()

                    if isInVehicle then
                        VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ Sortir avec le véhicule", nil, false)

                        if VFW.Interact.JustPressed(0, 51) then -- E
                            -- Find plate from entity
                            local plate = garageVehicles[playerVehicle]
                            if plate then
                                garageMarkerActive = false
                                DeleteGarageVehicles(plate)
                                DoScreenFadeOut(500)
                                Wait(500)
                                TriggerServerEvent("vfw:property:exitGarageWithVehicle", garagePropertyId, plate)
                                Wait(2000)
                                DoScreenFadeIn(500)
                                return
                            end
                        end
                    else
                        VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ Sortir" .. (VFW.PropertyCanManage and " / Gérer" or ""), nil, false)

                        if VFW.Interact.JustPressed(0, 51) then -- E
                            if VFW.PropertyCanManage then
                                -- Open choice UI (Sortir / Gérer)
                                VFW.PropertyChoiceResult = nil
                                SendNUIMessage({ action = "nui:property-choice:visible", data = true })
                                VFW.Nui.Focus(true, false)

                                local choiceDeadline = GetGameTimer() + 15000
                                while VFW.PropertyChoiceResult == nil do
                                    if GetGameTimer() > choiceDeadline then
                                        VFW.PropertyChoiceResult = "cancel"
                                        break
                                    end
                                    Wait(100)
                                end

                                SendNUIMessage({ action = "nui:property-choice:visible", data = false })
                                -- Relâche le focus sauf si on ouvre la gestion (qui le reprend).
                                if VFW.PropertyChoiceResult ~= "manage" then
                                    VFW.Nui.Focus(false)
                                end

                                if VFW.PropertyChoiceResult == "manage" then
                                    VFW.OpenPropertyGestion()
                                elseif VFW.PropertyChoiceResult == "leave" then
                                    VFW.ExitGarage()
                                    return
                                end
                            else
                                VFW.ExitGarage()
                                return
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

--- Exit garage (on foot)
function VFW.ExitGarage()
    local propId = garagePropertyId or VFW.ActualProperty
    garageMarkerActive = false
    VFW.InsidePropertyGarage = false
    DeleteGarageVehicles()
    DoScreenFadeOut(500)
    Wait(500)
    FreezeEntityPosition(VFW.PlayerData.ped, true)
    if propId then
        TriggerServerEvent("vfw:leaveProperty", propId)
    end
    Wait(1000)
    FreezeEntityPosition(VFW.PlayerData.ped, false)
    DoScreenFadeIn(500)
    VFW.Nui.Focus(false)
end

--- Un autre joueur a sorti un véhicule du garage, le retirer côté client
RegisterNetEvent("vfw:property:garageVehicleRemoved")
AddEventHandler("vfw:property:garageVehicleRemoved", function(plate)
    local netId = garageNetIds[plate]
    if netId then
        garageNetIds[plate] = nil
        local veh = NetworkGetEntityFromNetworkId(netId)
        if veh and DoesEntityExist(veh) then
            garageVehicles[veh] = nil
            VFW.PropertyGarageVehicles[veh] = nil
            DeleteEntity(veh)
        end
    end
end)

-- =============================================
-- NUI callbacks for property-choice (reuse same as house.lua)
-- These are already registered in house.lua, no need to duplicate
-- =============================================
