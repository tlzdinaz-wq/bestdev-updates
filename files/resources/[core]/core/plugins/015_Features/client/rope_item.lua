local ropeMode = false
local ropeProp = nil
local firstEntity = nil
local firstEntityType = nil
local firstEntitySide = nil
local ropeConnections = {}
local tempRope = nil
local tempRopeActive = false
local tempRopeEntity = nil
local tempRopeEntityType = nil
local tempRopeEntitySide = nil

local ROPE_PROP_MODEL = `prop_rope_family_3`
local HOOK_PROP_MODEL = `prop_tool_jackham`
local ROPE_LENGTH = 10.0

local function IsValidProp(entity)
    if not DoesEntityExist(entity) then return false end
    return true
end

local function EnsureEntityNetworked(entity)
    if not DoesEntityExist(entity) then return false end
    if NetworkGetEntityIsNetworked(entity) then return true end

    NetworkRegisterEntityAsNetworked(entity)
    local timeout = 0
    while not NetworkGetEntityIsNetworked(entity) and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end
    return NetworkGetEntityIsNetworked(entity)
end

local function GetClosestProp(coords, maxDist)
    local closestProp = nil
    local closestDist = maxDist
    local ped = PlayerPedId()

    local objects = GetGamePool('CObject')
    for _, obj in ipairs(objects) do
        if DoesEntityExist(obj) then
            if obj == ropeProp then
                goto continue
            end
            if obj == weaponOnBackProp then
                goto continue
            end
            if IsEntityAttached(obj) then
                goto continue
            end

            local objCoords = GetEntityCoords(obj)
            local dist = #(coords - objCoords)

            if dist < closestDist and IsValidProp(obj) then
                closestProp = obj
                closestDist = dist
            end
        end
        ::continue::
    end

    return closestProp, closestDist
end

local function CleanupProp()
    if ropeProp and DoesEntityExist(ropeProp) then
        DeleteEntity(ropeProp)
        ropeProp = nil
    end
end

local function CleanupTempRope()
    tempRopeActive = false
    if tempRope then
        DeleteRope(tempRope)
        RopeUnloadTextures()
        tempRope = nil
    end
    tempRopeEntity = nil
    tempRopeEntityType = nil
    tempRopeEntitySide = nil
end

local function CleanupAll()
    CleanupProp()
    CleanupTempRope()
    ropeMode = false
    firstEntity = nil
    firstEntityType = nil
    firstEntitySide = nil
end

local function IsVehicleFrontOrBack(vehicle, playerCoords)
    local vehCoords = GetEntityCoords(vehicle)
    local vehForward = GetEntityForwardVector(vehicle)

    local toPlayer = playerCoords - vehCoords
    toPlayer = vector3(toPlayer.x, toPlayer.y, 0.0)
    local len = #toPlayer
    if len < 0.01 then return nil end
    local toPlayerNorm = toPlayer / len

    local dot = toPlayerNorm.x * vehForward.x + toPlayerNorm.y * vehForward.y

    if dot > 0.85 then
        return "front"
    elseif dot < -0.85 then
        return "back"
    end

    return nil
end

local function GetAttachOffsetVehicle(vehicle, side)
    local model = GetEntityModel(vehicle)
    local min, max = GetModelDimensions(model)

    if side == "front" then
        return vector3(0.0, max.y - 0.3, min.z + 0.4)
    else
        return vector3(0.0, min.y + 0.3, min.z + 0.4)
    end
end

local function GetAttachOffsetProp(prop)
    local model = GetEntityModel(prop)
    local min, max = GetModelDimensions(model)

    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    local localPos = GetOffsetFromEntityGivenWorldCoords(prop, playerCoords.x, playerCoords.y, playerCoords.z)

    local clampedZ = math.max(min.z + 0.1, math.min(max.z - 0.1, localPos.z))

    return vector3(0.0, 0.0, clampedZ)
end

local function GetAttachOffset(entity, entityType, side)
    if entityType == "vehicle" then
        return GetAttachOffsetVehicle(entity, side)
    else
        return GetAttachOffsetProp(entity)
    end
end

local function CreateTempRopeToHand(entity, entityType, side)
    CleanupTempRope()

    local ped = PlayerPedId()
    local offset = GetAttachOffset(entity, entityType, side)
    local entityPos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    local handPos = GetPedBoneCoords(ped, 28422, 0.0, 0.0, 0.0)

    local dist = #(entityPos - handPos)
    local length = dist + 0.1
    if length < 1.0 then length = 1.0 end

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do Wait(0) end

    tempRope = AddRope(
        entityPos.x, entityPos.y, entityPos.z,
        0.0, 0.0, 0.0,
        length + 5.0,
        1,
        length,
        0.5,
        0.0,
        false,
        true,
        false,
        5.0,
        false,
        0
    )

    Wait(100)

    if not DoesRopeExist(tempRope) then
        RopeUnloadTextures()
        tempRope = nil
        return
    end

    RopeForceLength(tempRope, length)
    ActivatePhysics(tempRope)
    RopeSetUpdatePinverts(tempRope)

    PinRopeVertex(tempRope, 0, entityPos.x, entityPos.y, entityPos.z)
    local vc = GetRopeVertexCount(tempRope)
    if vc > 0 then
        PinRopeVertex(tempRope, vc - 1, handPos.x, handPos.y, handPos.z)
    end

    tempRopeEntity = entity
    tempRopeEntityType = entityType
    tempRopeEntitySide = side
    tempRopeActive = true

    CreateThread(function()
        while tempRopeActive and tempRope and DoesRopeExist(tempRope) do
            Wait(0)
            if tempRopeEntity and DoesEntityExist(tempRopeEntity) then
                local currentPed = PlayerPedId()
                local currentOffset = GetAttachOffset(tempRopeEntity, tempRopeEntityType, tempRopeEntitySide)
                local currentEntityPos = GetOffsetFromEntityInWorldCoords(tempRopeEntity, currentOffset.x, currentOffset.y, currentOffset.z)
                local currentHandPos = GetPedBoneCoords(currentPed, 28422, 0.0, 0.0, 0.0)

                local dist = #(currentEntityPos - currentHandPos)

                if dist > 7.0 then
                    CleanupTempRope()
                    firstEntity = nil
                    firstEntityType = nil
                    firstEntitySide = nil
                    break
                end

                local ropeLen = dist + 0.1
                if ropeLen < 1.0 then ropeLen = 1.0 end
                RopeForceLength(tempRope, ropeLen)

                PinRopeVertex(tempRope, 0, currentEntityPos.x, currentEntityPos.y, currentEntityPos.z)
                local vertexCount = GetRopeVertexCount(tempRope)
                if vertexCount > 0 then
                    PinRopeVertex(tempRope, vertexCount - 1, currentHandPos.x, currentHandPos.y, currentHandPos.z)
                end
            end
        end
    end)
end

local function CreateHookProp(entity, entityType, side)
    local model = HOOK_PROP_MODEL
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return nil end

    local offset = GetAttachOffset(entity, entityType, side)
    local coords = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)

    local hook = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityCollision(hook, false, false)
    SetEntityVisible(hook, false, false)

    AttachEntityToEntity(hook, entity, 0, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, true, true, false, false, 0, true)

    SetModelAsNoLongerNeeded(model)
    return hook, offset
end

local function GetVehicleAttachPosition(vehicle, side)
    local offset = GetAttachOffsetVehicle(vehicle, side)
    return GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z), offset
end

local function CreateRopeConnection(ent1, type1, side1, ent2, type2, side2)
    local towingEnt = ent1
    local towedEnt = ent2
    local towingSide = side1
    local towedSide = side2
    local towingType = type1
    local towedType = type2

    if type1 == "vehicle" and type2 == "vehicle" then
        if side1 == "front" then
            towingEnt = ent2
            towedEnt = ent1
            towingSide = side2
            towedSide = side1
            towingType = type2
            towedType = type1
        end
    elseif type2 == "vehicle" and type1 == "prop" then
        towingEnt = ent2
        towedEnt = ent1
        towingSide = side2
        towedSide = side1
        towingType = type2
        towedType = type1
    end

    local pos1, offset1
    local pos2, offset2

    if towingType == "vehicle" then
        pos1, offset1 = GetVehicleAttachPosition(towingEnt, towingSide)
    else
        offset1 = GetAttachOffset(towingEnt, towingType, towingSide)
        pos1 = GetOffsetFromEntityInWorldCoords(towingEnt, offset1.x, offset1.y, offset1.z)
    end

    if towedType == "vehicle" then
        pos2, offset2 = GetVehicleAttachPosition(towedEnt, towedSide)
    else
        offset2 = GetAttachOffset(towedEnt, towedType, towedSide)
        pos2 = GetOffsetFromEntityInWorldCoords(towedEnt, offset2.x, offset2.y, offset2.z)
    end

    local length = #(pos1 - pos2)
    if length > ROPE_LENGTH then
        return nil
    end
    if length < 1.0 then length = 1.0 end

    RopeLoadTextures()
    local timeout = 0
    while not RopeAreTexturesLoaded() and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    local rope = AddRope(
        pos1.x, pos1.y, pos1.z,
        0.0, 0.0, 0.0,
        length + 5.0,
        1,
        length,
        0.5,
        0.0,
        false,
        true,
        false,
        5.0,
        false,
        0
    )

    Wait(100)

    AttachEntitiesToRope(
        rope,
        towingEnt,
        towedEnt,
        pos1.x, pos1.y, pos1.z,
        pos2.x, pos2.y, pos2.z,
        length,
        false,
        false,
        nil,
        nil
    )

    ActivatePhysics(rope)
    StopRopeUnwindingFront(rope)
    StartRopeWinding(rope)
    RopeForceLength(rope, length)

    if towedType == "vehicle" then
        SetVehicleHandbrake(towedEnt, false)
        SetVehicleBrake(towedEnt, false)
    end

    return {
        rope = rope,
        towingEnt = towingEnt,
        towedEnt = towedEnt,
        towingType = towingType,
        towedType = towedType,
        towingOffset = offset1,
        towedOffset = offset2,
        length = length
    }
end

local function DeleteRopeConnection(ropeId)
    local data = ropeConnections[ropeId]
    if data then
        if data.rope then
            StopRopeUnwindingFront(data.rope)
            StopRopeWinding(data.rope)
            RopeConvertToSimple(data.rope)
            DetachRopeFromEntity(data.rope, data.towingEnt)
            DetachRopeFromEntity(data.rope, data.towedEnt)
            DeleteRope(data.rope)
            RopeUnloadTextures()
        end
        if data.towingType == "vehicle" and data.towingEnt and DoesEntityExist(data.towingEnt) then
            SetVehicleEngineTorqueMultiplier(data.towingEnt, 1.0)
            ModifyVehicleTopSpeed(data.towingEnt, 1.0)
        end
    end
end

local function AttachRopePropToHand()
    local ped = PlayerPedId()
    local model = ROPE_PROP_MODEL

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(model) then
        return false
    end

    local coords = GetEntityCoords(ped)
    ropeProp = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)

    AttachEntityToEntity(
        ropeProp,
        ped,
        GetPedBoneIndex(ped, 28422),
        0.05, 0.02, -0.02,
        -80.0, 0.0, 0.0,
        true, true, false, true, 0, true
    )

    SetModelAsNoLongerNeeded(model)
    return true
end

local function FindRopeNearPlayer()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)

    if IsPedInAnyVehicle(ped, false) then
        return nil, nil
    end

    for ropeId, data in pairs(ropeConnections) do
        local currentVeh = GetVehiclePedIsIn(ped, false)
        if currentVeh ~= 0 and (currentVeh == data.towingEnt or currentVeh == data.towedEnt) then
            goto continue
        end

        if data.towingEnt and DoesEntityExist(data.towingEnt) and data.towingOffset then
            local attachPos = GetOffsetFromEntityInWorldCoords(data.towingEnt, data.towingOffset.x, data.towingOffset.y, data.towingOffset.z)
            local dist1 = #(playerCoords - attachPos)
            if dist1 < 2.0 then
                return ropeId, data
            end
        end
        if data.towedEnt and DoesEntityExist(data.towedEnt) and data.towedOffset then
            local attachPos = GetOffsetFromEntityInWorldCoords(data.towedEnt, data.towedOffset.x, data.towedOffset.y, data.towedOffset.z)
            local dist2 = #(playerCoords - attachPos)
            if dist2 < 2.0 then
                return ropeId, data
            end
        end

        ::continue::
    end

    return nil, nil
end

local function ToggleRopeMode()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas utiliser la corde dans un véhicule"
        })
        return
    end

    if ropeMode then
        CleanupAll()
        VFW.ShowNotification({
            type = 'VERT',
            content = "Corde rangée"
        })
        return
    end

    local nearbyRopeId, nearbyRopeData = FindRopeNearPlayer()
    if nearbyRopeId then
        TriggerServerEvent("vfw:rope:remove", nearbyRopeId)
        VFW.ShowNotification({
            type = 'VERT',
            content = "Corde détachée"
        })
        return
    end

    ropeMode = true
    VFW.ShowNotification({
        type = 'VERT',
        content = "Corde en main - Approchez-vous d'un véhicule ou d'un objet mobile"
    })
    AttachRopePropToHand()

    CreateThread(function()

        while ropeMode do
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)

            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                CleanupAll()
                break
            end

            local targetEntity = nil
            local targetType = nil
            local targetSide = nil
            local targetDist = 999.0

            local closestVeh = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)
            if closestVeh and closestVeh ~= 0 and DoesEntityExist(closestVeh) then
                local dist = #(playerCoords - GetEntityCoords(closestVeh))
                local side = IsVehicleFrontOrBack(closestVeh, playerCoords)
                if dist < 3.0 and dist < targetDist then
                    targetEntity = closestVeh
                    targetType = "vehicle"
                    targetSide = side or "back"
                    targetDist = dist
                end
            end

            local closestProp, propDist = GetClosestProp(playerCoords, 2.0)
            if closestProp and propDist < targetDist then
                targetEntity = closestProp
                targetType = "prop"
                targetSide = "center"
                targetDist = propDist
            end

            if targetEntity and targetDist < 3.0 then
                local actionText = "Attacher la corde"
                local targetText = targetType == "vehicle" and (targetSide == "front" and "avant" or "arrière") or "objet"

                if firstEntity then
                    if firstEntity == targetEntity then
                        actionText = "Annuler l'attache"
                    elseif firstEntityType == "prop" and targetType == "prop" then
                        actionText = "Connecter (véhicule requis)"
                    else
                        actionText = "Connecter"
                    end
                end

                local helpText = "~INPUT_CONTEXT~ " .. actionText .. " (" .. targetText .. ")"
                if firstEntity then
                    helpText = helpText .. "~n~~INPUT_VEH_DUCK~ Annuler"
                end
                VFW.ShowHelpNotification(helpText, false, false)

                if firstEntity and IsControlJustPressed(0, 73) then
                    CleanupTempRope()
                    firstEntity = nil
                    firstEntityType = nil
                    firstEntitySide = nil
                end

                if VFW.Interact.JustPressed(0, 51) then
                    if not firstEntity then
                        firstEntity = targetEntity
                        firstEntityType = targetType
                        firstEntitySide = targetSide

                        CreateTempRopeToHand(targetEntity, targetType, targetSide)
                    elseif firstEntity == targetEntity then
                        firstEntity = nil
                        firstEntityType = nil
                        firstEntitySide = nil

                        CleanupTempRope()
                    else
                        if firstEntityType == "prop" and targetType == "prop" then
                        else
                            if not EnsureEntityNetworked(firstEntity) or not EnsureEntityNetworked(targetEntity) then
                                VFW.ShowNotification({
                                    type = 'ROUGE',
                                    content = "Impossible de connecter cet objet"
                                })
                            else
                                local offset1 = GetAttachOffset(firstEntity, firstEntityType, firstEntitySide)
                                local pos1 = GetOffsetFromEntityInWorldCoords(firstEntity, offset1.x, offset1.y, offset1.z)
                                local offset2 = GetAttachOffset(targetEntity, targetType, targetSide)
                                local pos2 = GetOffsetFromEntityInWorldCoords(targetEntity, offset2.x, offset2.y, offset2.z)
                                local distance = #(pos1 - pos2)

                                if distance > ROPE_LENGTH then
                                    VFW.ShowNotification({
                                        type = 'ROUGE',
                                        content = "Les deux points d'attaches sont trop distants."
                                    })
                                else
                                    local firstNetId = NetworkGetNetworkIdFromEntity(firstEntity)
                                    local secondNetId = NetworkGetNetworkIdFromEntity(targetEntity)

                                    TriggerServerEvent("vfw:rope:create", firstNetId, firstEntityType, firstEntitySide, secondNetId, targetType, targetSide)

                                    CleanupTempRope()
                                    CleanupProp()
                                    ropeMode = false
                                    firstEntity = nil
                                    firstEntityType = nil
                                    firstEntitySide = nil
                                end
                            end
                        end
                    end
                end
            end

            Wait(0)
        end
    end)
end

RegisterNetEvent("vfw:rope:created", function(ropeId, owner, ent1NetId, type1, side1, ent2NetId, type2, side2)
    local ent1 = NetworkGetEntityFromNetworkId(ent1NetId)
    local ent2 = NetworkGetEntityFromNetworkId(ent2NetId)

    local function DoCreate()
        local connectionData = CreateRopeConnection(ent1, type1, side1, ent2, type2, side2)
        if connectionData then
            ropeConnections[ropeId] = {
                owner = owner,
                ent1NetId = ent1NetId,
                ent2NetId = ent2NetId,
                rope = connectionData.rope,
                towingEnt = connectionData.towingEnt,
                towedEnt = connectionData.towedEnt,
                towingType = connectionData.towingType,
                towedType = connectionData.towedType,
                towingOffset = connectionData.towingOffset,
                towedOffset = connectionData.towedOffset,
                length = connectionData.length
            }

            if owner == GetPlayerServerId(PlayerId()) then
                local msg = "Connexion établie !"
                if type1 == "vehicle" and type2 == "vehicle" then
                    msg = "Véhicules connectés !"
                elseif type1 == "prop" or type2 == "prop" then
                    msg = "Objet connecté au véhicule !"
                end
                VFW.ShowNotification({
                    type = 'VERT',
                    content = msg
                })
            end
        else
            if owner == GetPlayerServerId(PlayerId()) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Les deux points d'attaches sont trop distants."
                })
            end
        end
    end

    if not DoesEntityExist(ent1) or not DoesEntityExist(ent2) then
        CreateThread(function()
            local timeout = 0
            while timeout < 50 do
                Wait(100)
                ent1 = NetworkGetEntityFromNetworkId(ent1NetId)
                ent2 = NetworkGetEntityFromNetworkId(ent2NetId)
                if DoesEntityExist(ent1) and DoesEntityExist(ent2) then
                    break
                end
                timeout = timeout + 1
            end

            if DoesEntityExist(ent1) and DoesEntityExist(ent2) then
                DoCreate()
            end
        end)
        return
    end

    DoCreate()
end)

RegisterNetEvent("vfw:rope:removed", function(ropeId)
    DeleteRopeConnection(ropeId)
    ropeConnections[ropeId] = nil
end)

RegisterNetEvent("vfw:rope:toggle", function()
    CreateThread(function()
        ToggleRopeMode()
    end)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupAll()
        for ropeId, _ in pairs(ropeConnections) do
            DeleteRopeConnection(ropeId)
        end
        ropeConnections = {}
    end
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        TriggerServerEvent("vfw:rope:requestAll")
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        for ropeId, data in pairs(ropeConnections) do
            local ent1 = NetworkGetEntityFromNetworkId(data.ent1NetId)
            local ent2 = NetworkGetEntityFromNetworkId(data.ent2NetId)

            if not DoesEntityExist(ent1) or not DoesEntityExist(ent2) then
                DeleteRopeConnection(ropeId)
                ropeConnections[ropeId] = nil
                TriggerServerEvent("vfw:rope:remove", ropeId)
            end
        end
    end
end)

CreateThread(function()
    while true do
        if not next(ropeConnections) then
            Wait(1000)
            goto continue
        end

        Wait(0)

        for ropeId, data in pairs(ropeConnections) do
            if data.rope and DoesRopeExist(data.rope) then
                if DoesEntityExist(data.towingEnt) and DoesEntityExist(data.towedEnt) then
                    StopRopeUnwindingFront(data.rope)
                    StartRopeWinding(data.rope)
                    RopeForceLength(data.rope, data.length)
                    RopeConvertToSimple(data.rope)
                end
            end

            if data.towedType == "vehicle" and data.towedEnt and DoesEntityExist(data.towedEnt) then
                SetVehicleHandbrake(data.towedEnt, false)
                SetVehicleBrake(data.towedEnt, false)
            end

            if data.towingType == "vehicle" and data.towingEnt and DoesEntityExist(data.towingEnt) then
                SetVehicleEngineTorqueMultiplier(data.towingEnt, 1.3)
                ModifyVehicleTopSpeed(data.towingEnt, 0.85)
            end
        end

        ::continue::
    end
end)

local ropeRemoveCooldown = false

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ropeMode or ropeRemoveCooldown or IsPedInAnyVehicle(ped, false) then
            Wait(500)
            goto continue
        end

        Wait(0)

        local nearbyRopeId, _ = FindRopeNearPlayer()
        if nearbyRopeId then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour détacher la corde", false, false)

                if VFW.Interact.JustPressed(0, 51) then
                    ropeRemoveCooldown = true
                    TriggerServerEvent("vfw:rope:remove", nearbyRopeId)
                    VFW.ShowNotification({
                        type = 'VERT',
                        content = "Corde détachée"
                    })
                    SetTimeout(1000, function()
                        ropeRemoveCooldown = false
                    end)
                end
            end

        ::continue::
    end
end)
