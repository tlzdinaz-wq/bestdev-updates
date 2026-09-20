VFW.PNJ = VFW.PNJ or {}

local managed = {}

local function resolveModel(model)
    if type(model) == "string" then
        return joaat(model)
    end
    return tonumber(model)
end

local function waitForEntity(entity)
    local tries = 0
    while not DoesEntityExist(entity) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end
    return DoesEntityExist(entity)
end

local function applyOptions(entity, options)
    local state = Entity(entity).state

    state:set("pnj_managed", true, true)

    if type(options.scenario) == "string" and options.scenario ~= "" then
        state:set("pnj_scenario", options.scenario, true)
    end

    if options.freeze ~= nil then
        state:set("pnj_freeze", options.freeze and true or false, true)
    end

    if options.invincible ~= nil then
        state:set("pnj_invincible", options.invincible and true or false, true)
    end
end

function VFW.PNJ.Create(model, coords, heading, options)
    model = resolveModel(model)
    if not model or type(coords) ~= "table" then return nil end

    options = type(options) == "table" and options or {}

    local ped = CreatePed(tonumber(options.pedType) or 4, model,
        coords.x + 0.0, coords.y + 0.0, coords.z + 0.0,
        tonumber(heading) or 0.0, true, true)

    if not waitForEntity(ped) then return nil end

    SetEntityOrphanMode(ped, 2)
    if options.invincible then
        SetEntityInvincible(ped, true)
    end
    if options.freeze then
        FreezeEntityPosition(ped, true)
    end

    applyOptions(ped, options)

    local netId = NetworkGetNetworkIdFromEntity(ped)
    managed[netId] = {
        netId = netId,
        entity = ped,
        model = model,
        group = options.group or "default",
        coords = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 },
        heading = tonumber(heading) or 0.0,
    }

    return netId, ped
end

function VFW.PNJ.FindSidewalkCoord(center, radius, attempts)
    if type(center) ~= "table" then return nil end

    radius = tonumber(radius) or 30.0
    attempts = tonumber(attempts) or 12

    local candidates = VFW.GetPlayersInRadius(center, math.max(radius * 4.0, 200.0))
    if #candidates == 0 then
        candidates = {}
        for _, xPlayer in pairs(VFW.Players) do
            candidates[#candidates + 1] = xPlayer
        end
    end

    for i = 1, #candidates do
        local target = candidates[i]
        local ok, coord = pcall(TriggerClientCallback, target.source, "vfw:pnj:findSidewalkCoord", center, radius, attempts)
        if ok and type(coord) == "table" and coord.x then
            return coord
        end
    end

    return nil
end

function VFW.PNJ.CreateOnSidewalk(model, center, options)
    options = type(options) == "table" and options or {}

    local coord = VFW.PNJ.FindSidewalkCoord(center, options.radius, options.attempts)
    if not coord then
        if options.fallback == false then return nil end
        coord = center
    end

    return VFW.PNJ.Create(model, coord, options.heading, options)
end

function VFW.PNJ.SetScenario(netId, scenario)
    local entry = managed[tonumber(netId) or -1]
    if not entry or not DoesEntityExist(entry.entity) then return false end
    Entity(entry.entity).state:set("pnj_scenario", type(scenario) == "string" and scenario or nil, true)
    return true
end

function VFW.PNJ.SetFreeze(netId, freeze)
    local entry = managed[tonumber(netId) or -1]
    if not entry or not DoesEntityExist(entry.entity) then return false end
    freeze = freeze and true or false
    FreezeEntityPosition(entry.entity, freeze)
    Entity(entry.entity).state:set("pnj_freeze", freeze, true)
    return true
end

function VFW.PNJ.SetInvincible(netId, invincible)
    local entry = managed[tonumber(netId) or -1]
    if not entry or not DoesEntityExist(entry.entity) then return false end
    invincible = invincible and true or false
    SetEntityInvincible(entry.entity, invincible)
    Entity(entry.entity).state:set("pnj_invincible", invincible, true)
    return true
end

function VFW.PNJ.Get(netId)
    return managed[tonumber(netId) or -1]
end

function VFW.PNJ.GetAll()
    return managed
end

function VFW.PNJ.Delete(netId)
    netId = tonumber(netId)
    local entry = managed[netId or -1]
    if not entry then return false end

    if entry.entity and DoesEntityExist(entry.entity) then
        DeleteEntity(entry.entity)
    end
    managed[netId] = nil
    return true
end

function VFW.PNJ.DeleteGroup(group)
    local removed = 0
    for netId, entry in pairs(managed) do
        if entry.group == group then
            if VFW.PNJ.Delete(netId) then
                removed = removed + 1
            end
        end
    end
    return removed
end

function VFW.PNJ.DeleteAll()
    for netId in pairs(managed) do
        VFW.PNJ.Delete(netId)
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    VFW.PNJ.DeleteAll()
end)
