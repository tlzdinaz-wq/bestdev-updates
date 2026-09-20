VFW = VFW or {}
VFW.GPS = VFW.GPS or {}

local GPS = VFW.GPS

local function isValidTarget(target)
    if target == -1 then return true end
    local id = tonumber(target)
    if not id then return false end
    return VFW.GetPlayerFromId(id) ~= nil
end

function GPS.SetObjective(target, objectiveId, coords, options)
    if not isValidTarget(target) then return false end
    if type(objectiveId) ~= "string" or objectiveId == "" then return false end
    if type(coords) ~= "table" then return false end

    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return false end

    TriggerClientEvent("vfw:gps:setObjective", target, objectiveId, x + 0.0, y + 0.0, z + 0.0,
        type(options) == "table" and options or {})
    return true
end

function GPS.SetEntityObjective(target, objectiveId, netId, options)
    if not isValidTarget(target) then return false end
    if type(objectiveId) ~= "string" or objectiveId == "" then return false end

    local id = tonumber(netId)
    if not id then return false end

    TriggerClientEvent("vfw:gps:setEntityObjective", target, objectiveId, id,
        type(options) == "table" and options or {})
    return true
end

function GPS.RemoveObjective(target, objectiveId, playSound)
    if not isValidTarget(target) then return false end
    if type(objectiveId) ~= "string" or objectiveId == "" then return false end

    TriggerClientEvent("vfw:gps:removeObjective", target, objectiveId, playSound == true)
    return true
end

function GPS.ClearAll(target)
    if not isValidTarget(target) then return false end

    TriggerClientEvent("vfw:gps:clearAll", target)
    return true
end

exports("GPSSetObjectiveFor", GPS.SetObjective)
exports("GPSSetEntityObjectiveFor", GPS.SetEntityObjective)
exports("GPSRemoveObjectiveFor", GPS.RemoveObjective)
exports("GPSClearAllFor", GPS.ClearAll)
