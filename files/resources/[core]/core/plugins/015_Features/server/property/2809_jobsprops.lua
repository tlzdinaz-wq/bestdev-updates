local PS = VFW.PropertyServer

local MAX_PROPS_PER_PLAYER = 15

PS.JobProps = {}

local function syncPayload()
    local out = {}
    for netId, data in pairs(PS.JobProps) do
        out[netId] = {
            owner = data.owner,
            coords = data.coords,
            rot = data.rot,
            model = data.model,
            job = data.job,
        }
    end
    return out
end

local function remapOwners()
    local byIdentifier = {}
    for _, xPlayer in pairs(VFW.Players) do
        byIdentifier[xPlayer.identifier] = xPlayer.source
    end
    for _, data in pairs(PS.JobProps) do
        local src = data.ownerIdentifier and byIdentifier[data.ownerIdentifier] or nil
        if src then
            data.owner = src
        end
    end
end

local function countPropsOf(identifier)
    local count = 0
    for _, data in pairs(PS.JobProps) do
        if data.ownerIdentifier == identifier then
            count = count + 1
        end
    end
    return count
end

local function deletePropEntity(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

RegisterNetEvent("jobsPropsMenu:place", function(netId, jobName, model, coords)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = PS.ToInt(netId)
    local job = PS.SafeString(jobName, 60)
    local propModel = PS.SafeString(model, 64)
    local position = PS.ReadVec3(coords)

    if not id or not job or not propModel or not position then return end

    if not xPlayer.job or xPlayer.job.name ~= job then
        deletePropEntity(id)
        return
    end

    if countPropsOf(xPlayer.identifier) >= MAX_PROPS_PER_PLAYER then
        TriggerClientEvent("jobsPropsMenu:limitReached", source, MAX_PROPS_PER_PLAYER)
        deletePropEntity(id)
        return
    end

    local entity = NetworkGetEntityFromNetworkId(id)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        Entity(entity).state:set("jobProp", job, true)
    end

    PS.JobProps[id] = {
        owner = source,
        ownerIdentifier = xPlayer.identifier,
        ownerName = xPlayer.name,
        coords = position,
        rot = { x = 0.0, y = 0.0, z = 0.0 },
        model = propModel,
        job = job,
        placedAt = PS.Now(),
    }

    TriggerClientEvent("jobsPropsMenu:syncAdd", -1, id, {
        owner = source,
        coords = position,
        rot = PS.JobProps[id].rot,
        model = propModel,
        job = job,
    })
end)

RegisterNetEvent("jobsPropsMenu:move", function(netId, coords, rot)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = PS.ToInt(netId)
    if not id then return end

    local data = PS.JobProps[id]
    if not data then return end

    if (not xPlayer.job or xPlayer.job.name ~= data.job) and not xPlayer.hasPermission("manage_job_props") then
        return
    end

    local position = PS.ReadVec3(coords)
    local rotation = PS.ReadVec3(rot)
    if not position then return end

    data.coords = position
    data.rot = rotation or data.rot

    TriggerClientEvent("jobsPropsMenu:syncMove", -1, id, data.coords, data.rot)
end)

RegisterServerCallback("jobsPropsMenu:remove", function(source, netId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local id = PS.ToInt(netId)
    if not id then return false end

    local data = PS.JobProps[id]
    if not data then return false end

    local allowed = xPlayer.hasPermission("manage_job_props") or PS.IsStaff(xPlayer)
    if not allowed then
        if not xPlayer.job or xPlayer.job.name ~= data.job then return false end
        if not xPlayer.job.onDuty then return false end
        allowed = true
    end

    if not allowed then return false end

    PS.JobProps[id] = nil
    deletePropEntity(id)
    TriggerClientEvent("jobsPropsMenu:syncRemove", -1, id)
    return true
end)

RegisterNetEvent("jobsPropsMenu:staff:forceRemove", function(netId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("manage_job_props") and not PS.IsStaff(xPlayer) then return end

    local id = PS.ToInt(netId)
    if not id then return end

    PS.JobProps[id] = nil
    deletePropEntity(id)
    TriggerClientEvent("jobsPropsMenu:syncRemove", -1, id)
end)

RegisterServerCallback("jobsPropsMenu:staff:getAll", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    if not xPlayer.hasPermission("manage_job_props") and not PS.IsStaff(xPlayer) then return {} end

    local out = {}
    for netId, data in pairs(PS.JobProps) do
        out[data.job] = out[data.job] or {}
        table.insert(out[data.job], {
            netId = netId,
            model = data.model,
            coords = data.coords,
            rot = data.rot,
            owner = data.owner,
            ownerName = data.ownerName,
            placedAt = data.placedAt,
            job = data.job,
        })
    end

    for jobName, list in pairs(out) do
        list.label = PS.GetJobLabel(jobName)
    end

    return out
end)

AddEventHandler("vfw:playerLoaded", function(source)
    remapOwners()
    TriggerClientEvent("jobsPropsMenu:syncAll", -1, syncPayload())
end)
