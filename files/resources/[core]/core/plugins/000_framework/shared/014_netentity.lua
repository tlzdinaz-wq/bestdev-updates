---@meta _
---@diagnostic disable: duplicate-doc-field

NetEntity = NetEntity or {}

-- Rage Enums (if not already defined)
if not rageE then
    rageE = {
        EntityType = {
            Ped = 1,
            Vehicle = 2,
            Object = 3
        },
        EulerRotOrder = {
            YXZ = 0,
            ZYX = 1,
            ZXY = 2,
            XZY = 3,
            YZX = 4,
            XYZ = 5
        }
    }
end

function NetEntity.GetMaxNetAttachedEntities()
    return 8
end

function NetEntity.PackNetAttachedEntity(netAttachedEntity)
    local packed = {}

    packed[1] = netAttachedEntity.id
    packed[2] = netAttachedEntity.type
    packed[3] = netAttachedEntity.group
    packed[4] = netAttachedEntity.model
    packed[5] = netAttachedEntity.state

    packed[6] = netAttachedEntity.attach.boneTag
    packed[7] = netAttachedEntity.attach.offset
    packed[8] = netAttachedEntity.attach.rotation

    local flags = 0
    if netAttachedEntity.attach.detachWhenDead then flags = flags | 1 end
    if netAttachedEntity.attach.detachWhenRagdoll then flags = flags | 2 end
    if netAttachedEntity.attach.activeCollisions then flags = flags | 4 end
    if netAttachedEntity.attach.basicAttachIfPed then flags = flags | 8 end
    if netAttachedEntity.attach.attachOffsetIsRelative then flags = flags | 16 end
    packed[9] = flags

    packed[10] = netAttachedEntity.attach.rotOrder

    local extra = netAttachedEntity.extra
    local hasExtra = extra ~= nil
    packed[11] = hasExtra

    if hasExtra then
        if netAttachedEntity.type == 4 --[[WEAPON_OBJECT]] then
            if extra.createDefaultComponents == nil then
                extra.createDefaultComponents = true
            end
            packed[12] = extra.createDefaultComponents
            packed[13] = extra.scale or 1.0
            packed[14] = extra.customModel or 0

            packed[15] = extra.tintIndex or -1

            local liveryColor = extra.liveryColor
            local hasLiveryColor = liveryColor ~= nil
            packed[16] = hasLiveryColor
            local packedIdx = 16

            if hasLiveryColor then
                packed[17] = liveryColor.camoComponentHash
                packed[18] = liveryColor.colorIndex
                packedIdx = packedIdx + 2
            end

            local components = extra.components
            local componentsLen = components and #components or 0
            packedIdx = packedIdx + 1
            packed[packedIdx] = componentsLen

            for i = 1, componentsLen do
                packed[packedIdx + i] = components[i]
            end

            --packedIdx = packedIdx + componentsLen
        end
    end

    return packed
end

function NetEntity.UnpackNetAttachedEntity(packedNetAttachedEntity)
    local unpacked = {}

    unpacked.id = packedNetAttachedEntity[1]
    unpacked.type = packedNetAttachedEntity[2]
    unpacked.group = packedNetAttachedEntity[3]
    unpacked.model = packedNetAttachedEntity[4]
    unpacked.state = packedNetAttachedEntity[5]

    local attach = {}
    unpacked.attach = attach

    attach.boneTag = packedNetAttachedEntity[6]
    attach.offset = packedNetAttachedEntity[7]
    attach.rotation = packedNetAttachedEntity[8]

    local flags = packedNetAttachedEntity[9]
    attach.detachWhenDead = (flags & 1) ~= 0
    attach.detachWhenRagdoll = (flags & 2) ~= 0
    attach.activeCollisions = (flags & 4) ~= 0
    attach.basicAttachIfPed = (flags & 8) ~= 0
    attach.attachOffsetIsRelative = (flags & 16) ~= 0

    attach.rotOrder = packedNetAttachedEntity[10]

    if packedNetAttachedEntity[11] then
        local extra = {}
        unpacked.extra = extra

        if unpacked.type == 4 --[[WEAPON_OBJECT]] then
            extra.createDefaultComponents = packedNetAttachedEntity[12]
            extra.scale = packedNetAttachedEntity[13]
            extra.customModel = packedNetAttachedEntity[14]

            extra.tintIndex = packedNetAttachedEntity[15]

            local hasLiveryColor = packedNetAttachedEntity[16]
            local packedIdx = 16

            if hasLiveryColor then
                local liveryColor = {}
                extra.liveryColor = liveryColor

                liveryColor.camoComponentHash = packedNetAttachedEntity[17]
                liveryColor.colorIndex = packedNetAttachedEntity[18]
                packedIdx = packedIdx + 2
            end

            packedIdx = packedIdx + 1
            local componentsLen = packedNetAttachedEntity[packedIdx]
            extra.components = {}

            for i = 1, componentsLen do
                extra.components[i] = packedNetAttachedEntity[packedIdx + i]
            end

            --packedIdx = packedIdx + componentsLen
        end
    end

    return unpacked
end