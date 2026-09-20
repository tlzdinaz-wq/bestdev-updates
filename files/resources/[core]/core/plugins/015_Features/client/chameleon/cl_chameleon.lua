---@meta _
---@diagnostic disable: duplicate-doc-field

-- ════════════════════════════════════════════════
-- Chameleon Paint System (Client)
-- Handles the spray animation, ownership re-check via server callback,
-- and broadcasts the painted color to all observers.
-- ════════════════════════════════════════════════

local SPRAY_ANIM_DICT     = "anim@amb@business@weed@weed_inspecting_lo_med_hi@"
local SPRAY_ANIM_NAME     = "weed_spraybottle_stand_spraying_01_inspector"
local SPRAY_OBJECT        = `ng_proc_spraycan01b`
local SPRAY_DURATION_MS   = 13000
local MAX_VEHICLE_DISTANCE = 3.0

---Loads an animation dictionary with a hard timeout to avoid infinite waits.
---@param dict string
---@return boolean loaded
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 500 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    return HasAnimDictLoaded(dict)
end

---Loads a model with a hard timeout to avoid infinite waits.
---@param model number|string
---@return boolean loaded
local function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 500 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    return HasModelLoaded(model)
end

---Finds a vehicle in front of the player using a forward capsule shape test.
---Returns the entity handle or 0 if none found within MAX_VEHICLE_DISTANCE.
---@param ped number
---@return number entity
local function getVehicleInFront(ped)
    local pedCoords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local endCoords = vector3(
        pedCoords.x + forward.x * MAX_VEHICLE_DISTANCE,
        pedCoords.y + forward.y * MAX_VEHICLE_DISTANCE,
        pedCoords.z + forward.z * MAX_VEHICLE_DISTANCE
    )

    -- flags 10 = vehicles + objects
    local handle = StartShapeTestCapsule(
        pedCoords.x, pedCoords.y, pedCoords.z,
        endCoords.x, endCoords.y, endCoords.z,
        1.0, 10, ped, 7
    )

    local _, hit, _, _, entityHit = GetShapeTestResult(handle)
    if hit and entityHit and entityHit ~= 0 and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) then
        return entityHit
    end

    return 0
end

RegisterNetEvent("chameleon:use", function(chameleonId, itemUniqueId)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, true) then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous devez être à pied pour utiliser ce spray."
        })
        return
    end

    local vehicle = getVehicleInFront(ped)
    if vehicle == 0 then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Aucun véhicule devant vous."
        })
        return
    end

    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    if not vehicleNetId or vehicleNetId == 0 then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Aucun véhicule devant vous."
        })
        return
    end

    local success, errMsg = TriggerServerCallback(
        "chameleon:checkOwnership",
        chameleonId,
        itemUniqueId,
        vehicleNetId
    )

    if not success then
        VFW.ShowNotification({
            type = "ROUGE",
            content = errMsg or "Impossible d'appliquer la peinture caméléon."
        })
        return
    end

    if not loadAnimDict(SPRAY_ANIM_DICT) then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Impossible de charger l'animation de peinture."
        })
        return
    end

    if not loadModel(SPRAY_OBJECT) then
        RemoveAnimDict(SPRAY_ANIM_DICT)
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Impossible de charger l'objet spray."
        })
        return
    end

    local pedCoords = GetEntityCoords(ped)
    local sprayObject = CreateObject(SPRAY_OBJECT, pedCoords.x, pedCoords.y, pedCoords.z, false, true, false)

    -- Bone 28422 = IK_R_Hand (right hand)
    AttachEntityToEntity(
        sprayObject, ped, GetPedBoneIndex(ped, 28422),
        0.072, 0.041, -0.06,
        33.0, 38.0, 0.0,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(SPRAY_OBJECT)

    -- Flag 49 = upper-body loop (8 + 16 + 32 + 1)
    TaskPlayAnim(ped, SPRAY_ANIM_DICT, SPRAY_ANIM_NAME, 1.0, 1.0, -1, 49, 0.0, false, false, false)

    Citizen.Wait(SPRAY_DURATION_MS)

    StopAnimTask(ped, SPRAY_ANIM_DICT, SPRAY_ANIM_NAME, -4.0)

    if DoesEntityExist(sprayObject) then
        DetachEntity(sprayObject, true, true)
        DeleteObject(sprayObject)
    end

    RemoveAnimDict(SPRAY_ANIM_DICT)

    TriggerServerEvent("chameleon:apply", chameleonId, itemUniqueId, vehicleNetId)
end)

RegisterNetEvent("chameleon:syncColor", function(vehicleNetId, nativeColor)
    if not vehicleNetId or vehicleNetId == 0 then
        return
    end

    if not NetworkDoesNetworkIdExist(vehicleNetId) then
        return
    end

    local entity = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return
    end

    -- Without clearing custom RGB overrides first, SetVehicleColours has no
    -- visible effect on vehicles previously painted via the customs menu.
    ClearVehicleCustomPrimaryColour(entity)
    ClearVehicleCustomSecondaryColour(entity)
    SetVehicleColours(entity, nativeColor, nativeColor)
end)
