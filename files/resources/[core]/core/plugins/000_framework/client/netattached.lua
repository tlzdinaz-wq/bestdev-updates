---@meta _
---@diagnostic disable: duplicate-doc-field

-- Client-side NetAttachedEntity handler
local netAttachedEntities = {}
local trackedToPlayers = {}

-- Helper function to request model
local function RequestModelSync(model)
    if not IsModelInCdimage(model) then
        return false
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    return true
end

-- Delete a NetAttachedEntity
local function deleteNetAttachedEntity(netAttachedEntity, trackedToPlayer)
    if not trackedToPlayer then
        trackedToPlayer = trackedToPlayers[netAttachedEntity.toPlayerServerId]
    end

    if trackedToPlayer then
        trackedToPlayer.netAttachedEntitiesByKeyIdx[netAttachedEntity.stateKeyIdx] = nil

        -- Remove from array
        for i = 1, #trackedToPlayer.netAttachedEntities do
            if trackedToPlayer.netAttachedEntities[i].id == netAttachedEntity.id then
                table.remove(trackedToPlayer.netAttachedEntities, i)
                break
            end
        end

        if #trackedToPlayer.netAttachedEntities == 0 then
            trackedToPlayers[netAttachedEntity.toPlayerServerId] = nil
        end
    end

    if netAttachedEntity.handle and DoesEntityExist(netAttachedEntity.handle) then
        DeleteEntity(netAttachedEntity.handle)
    end

    netAttachedEntities[netAttachedEntity.id] = nil
end

-- Attach the entity
local function attachNetAttachedEntity(netAttachedEntity)
    local attach = netAttachedEntity.attach
    local boneIdx = 0

    if type(attach.boneTag) == 'number' then
        if attach.boneTag > 0 and GetEntityType(netAttachedEntity.toEntity) == 1 then
            boneIdx = GetPedBoneIndex(netAttachedEntity.toEntity, attach.boneTag)
        else
            boneIdx = attach.boneTag
        end
    elseif type(attach.boneTag) == 'string' then
        boneIdx = GetEntityBoneIndexByName(netAttachedEntity.toEntity, attach.boneTag)
    end

    AttachEntityToEntity(
        netAttachedEntity.handle,
        netAttachedEntity.toEntity,
        boneIdx,
        attach.offset.x, attach.offset.y, attach.offset.z,
        attach.rotation.x, attach.rotation.y, attach.rotation.z,
        attach.detachWhenDead,
        attach.detachWhenRagdoll,
        attach.activeCollisions,
        false, -- basicAttachIfPed
        attach.rotOrder or 0,
        attach.attachOffsetIsRelative
    )
end

-- Create attached entity
local function createAttachedEntity(netAttachedEntity, toEntity, toPlayerServerId)
    -- Check if already exists
    local presentNetAttachedEntity = netAttachedEntities[netAttachedEntity.id]
    if presentNetAttachedEntity then
        -- Update attach params
        presentNetAttachedEntity.attach = netAttachedEntity.attach
        presentNetAttachedEntity.state = netAttachedEntity.state
        attachNetAttachedEntity(presentNetAttachedEntity)
        return
    end

    netAttachedEntity.toEntity = toEntity
    netAttachedEntity.toPlayerServerId = toPlayerServerId

    local entity = nil
    local coords = GetEntityCoords(toEntity) - vector3(0.0, 0.0, 50.0)

    if netAttachedEntity.type == rageE.EntityType.Object or netAttachedEntity.type == 3 then
        if RequestModelSync(netAttachedEntity.model) then
            entity = CreateObject(netAttachedEntity.model, coords.x, coords.y, coords.z, false, false, true)
            SetModelAsNoLongerNeeded(netAttachedEntity.model)
        end
    end

    if not entity or entity == 0 then
        return
    end

    netAttachedEntity.handle = entity

    -- Attach the entity
    attachNetAttachedEntity(netAttachedEntity)

    -- Track it
    if toPlayerServerId then
        local trackedToPlayer = trackedToPlayers[toPlayerServerId]
        if not trackedToPlayer then
            trackedToPlayer = { netAttachedEntities = {}, netAttachedEntitiesByKeyIdx = {} }
            trackedToPlayers[toPlayerServerId] = trackedToPlayer
        end

        trackedToPlayer.netAttachedEntities[#trackedToPlayer.netAttachedEntities + 1] = netAttachedEntity
        trackedToPlayer.netAttachedEntitiesByKeyIdx[netAttachedEntity.stateKeyIdx] = netAttachedEntity
    end

    netAttachedEntities[netAttachedEntity.id] = netAttachedEntity
end

-- Get player server ID from state bag name
local function GetPlayerServerIdFromStateBagName(bagName)
    local playerStrLen = ('player:'):len()
    if bagName:sub(1, playerStrLen) ~= 'player:' then
        return 0
    end

    return tonumber(bagName:sub(playerStrLen + 1))
end

-- Handle state bag changes
AddStateBagChangeHandler('', '', function(bagName, key, value, reserved, replicated)
    if replicated then
        return
    end

    local netAttachedEntityLen = ('netAttachedEntity:'):len()
    if string.sub(key, 1, netAttachedEntityLen) ~= 'netAttachedEntity:' then
        return
    end

    local stateKeyIdx = tonumber(string.sub(key, netAttachedEntityLen + 1))
    if not stateKeyIdx or stateKeyIdx < 0 or stateKeyIdx >= NetEntity.GetMaxNetAttachedEntities() then
        return
    end

    if string.sub(bagName, 1, ('player:'):len()) == 'player:' then
        local toPlayerServerId = GetPlayerServerIdFromStateBagName(bagName)
        if toPlayerServerId == 0 then
            return
        end

        local toPlayer = GetPlayerFromServerId(toPlayerServerId)
        if toPlayer == -1 then
            return
        end

        local toPlayerPed = GetPlayerPed(toPlayer)
        if toPlayerPed == 0 then
            return
        end

        if not value then
            local trackedToPlayer = trackedToPlayers[toPlayerServerId]
            if not trackedToPlayer then
                return
            end

            local netAttachedEntity = trackedToPlayer.netAttachedEntitiesByKeyIdx[stateKeyIdx]
            if not netAttachedEntity then
                return
            end

            deleteNetAttachedEntity(netAttachedEntity, trackedToPlayer)
            return
        end

        local netAttachedEntity = NetEntity.UnpackNetAttachedEntity(value)
        netAttachedEntity.stateKeyIdx = stateKeyIdx

        createAttachedEntity(netAttachedEntity, toPlayerPed, toPlayerServerId)
    end
end)

-- Clean up on player drop
RegisterNetEvent('onPlayerDropped', function(playerServerId, playerName, playerId)
    local trackedToPlayer = trackedToPlayers[playerServerId]
    if not trackedToPlayer then
        return
    end

    for i = 1, #trackedToPlayer.netAttachedEntities do
        local netAttachedEntity = trackedToPlayer.netAttachedEntities[i]
        if netAttachedEntity.handle and DoesEntityExist(netAttachedEntity.handle) then
            DeleteEntity(netAttachedEntity.handle)
        end
        netAttachedEntities[netAttachedEntity.id] = nil
    end

    trackedToPlayers[playerServerId] = nil
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for _, netAttachedEntity in pairs(netAttachedEntities) do
        if netAttachedEntity.handle and DoesEntityExist(netAttachedEntity.handle) then
            DeleteEntity(netAttachedEntity.handle)
        end
    end
end)