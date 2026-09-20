VFW.NetAttached = VFW.NetAttached or {}

local attached = {}
local nextId = 0

local function stateKey(index)
    return ("netAttachedEntity:%d"):format(index)
end

local function toVec(value, fallback)
    if type(value) == "table" then
        return {
            x = tonumber(value.x) or 0.0,
            y = tonumber(value.y) or 0.0,
            z = tonumber(value.z) or 0.0,
        }
    end
    if type(value) == "vector3" then
        return { x = value.x + 0.0, y = value.y + 0.0, z = value.z + 0.0 }
    end
    return fallback
end

local function normalize(def)
    local attach = type(def.attach) == "table" and def.attach or {}

    local boneTag = attach.boneTag
    if type(boneTag) ~= "number" and type(boneTag) ~= "string" then
        boneTag = 0
    end

    local model = def.model
    if type(model) == "string" then
        model = joaat(model)
    end
    model = tonumber(model)

    nextId = nextId + 1

    return {
        id = def.id or ("nae_%d"):format(nextId),
        type = tonumber(def.type) or rageE.EntityType.Object,
        group = def.group or "default",
        model = model,
        state = def.state,
        attach = {
            boneTag = boneTag,
            offset = toVec(attach.offset, { x = 0.0, y = 0.0, z = 0.0 }),
            rotation = toVec(attach.rotation, { x = 0.0, y = 0.0, z = 0.0 }),
            detachWhenDead = attach.detachWhenDead and true or false,
            detachWhenRagdoll = attach.detachWhenRagdoll and true or false,
            activeCollisions = attach.activeCollisions and true or false,
            basicAttachIfPed = attach.basicAttachIfPed and true or false,
            attachOffsetIsRelative = attach.attachOffsetIsRelative == nil and true or (attach.attachOffsetIsRelative and true or false),
            rotOrder = tonumber(attach.rotOrder) or rageE.EulerRotOrder.YXZ,
        },
        extra = def.extra,
    }
end

local function freeSlot(source)
    local slots = attached[source]
    if not slots then return 0 end

    for i = 0, NetEntity.GetMaxNetAttachedEntities() - 1 do
        if slots[i] == nil then
            return i
        end
    end
    return nil
end

function VFW.NetAttached.Attach(source, def)
    source = tonumber(source)
    if not source or type(def) ~= "table" then return nil end
    if not GetPlayerName(source) then return nil end

    attached[source] = attached[source] or {}

    local index = freeSlot(source)
    if not index then
        console.warn(("[netattach] aucun slot libre pour %d (max %d)"):format(source, NetEntity.GetMaxNetAttachedEntities()))
        return nil
    end

    local entity = normalize(def)
    if not entity.model then return nil end

    attached[source][index] = entity
    Player(source).state:set(stateKey(index), NetEntity.PackNetAttachedEntity(entity), true)

    return index, entity.id
end

function VFW.NetAttached.Update(source, index, def)
    source = tonumber(source)
    index = tonumber(index)
    if not source or not index or type(def) ~= "table" then return false end

    local slots = attached[source]
    if not slots or not slots[index] then return false end

    local previous = slots[index]
    local entity = normalize(def)
    entity.id = previous.id

    slots[index] = entity
    Player(source).state:set(stateKey(index), NetEntity.PackNetAttachedEntity(entity), true)
    return true
end

function VFW.NetAttached.Detach(source, index)
    source = tonumber(source)
    index = tonumber(index)
    if not source or not index then return false end

    local slots = attached[source]
    if not slots or not slots[index] then return false end

    slots[index] = nil
    if GetPlayerName(source) then
        Player(source).state:set(stateKey(index), nil, true)
    end
    return true
end

function VFW.NetAttached.DetachById(source, id)
    source = tonumber(source)
    if not source or id == nil then return false end

    local slots = attached[source]
    if not slots then return false end

    for index, entity in pairs(slots) do
        if entity.id == id then
            return VFW.NetAttached.Detach(source, index)
        end
    end
    return false
end

function VFW.NetAttached.DetachGroup(source, group)
    source = tonumber(source)
    if not source or group == nil then return 0 end

    local slots = attached[source]
    if not slots then return 0 end

    local removed = 0
    for index, entity in pairs(slots) do
        if entity.group == group then
            if VFW.NetAttached.Detach(source, index) then
                removed = removed + 1
            end
        end
    end
    return removed
end

function VFW.NetAttached.Get(source)
    source = tonumber(source)
    if not source then return {} end
    return attached[source] or {}
end

function VFW.NetAttached.Clear(source)
    source = tonumber(source)
    if not source then return end

    local slots = attached[source]
    if not slots then return end

    local online = GetPlayerName(source) ~= nil
    for index in pairs(slots) do
        if online then
            Player(source).state:set(stateKey(index), nil, true)
        end
    end
    attached[source] = nil
end

AddEventHandler("playerDropped", function()
    local source = source
    attached[source] = nil
end)

AddEventHandler("vfw:playerDropped", function(source)
    attached[source] = nil
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for source in pairs(attached) do
        VFW.NetAttached.Clear(source)
    end
end)
