VFW.ContextMenu = VFW.ContextMenu or {}

local scopes = {}
local conditions = {}
local actions = {}

function VFW.ContextMenu.RegisterScope(name, resolver)
    if type(name) ~= "string" or type(resolver) ~= "function" then return false end
    scopes[name] = resolver
    return true
end

function VFW.ContextMenu.RegisterCondition(route, evaluator)
    if type(route) ~= "string" or type(evaluator) ~= "function" then return false end
    conditions[route] = evaluator
    return true
end

function VFW.ContextMenu.RegisterAction(name, handler, permission)
    if type(name) ~= "string" or type(handler) ~= "function" then return false end
    actions[name] = { handler = handler, permission = permission }
    return true
end

function VFW.ContextMenu.HasScope(name) return scopes[name] ~= nil end
function VFW.ContextMenu.HasCondition(route) return conditions[route] ~= nil end
function VFW.ContextMenu.HasAction(name) return actions[name] ~= nil end

local function playerFromEntity(entity)
    if not entity or entity == 0 then return nil end
    for _, xPlayer in pairs(VFW.Players) do
        if GetPlayerPed(xPlayer.source) == entity then
            return xPlayer.source
        end
    end
    return nil
end

local function buildEnt(source, netId, entType, world)
    netId = tonumber(netId) or 0
    entType = tonumber(entType) or 0

    local ent = {
        source = source,
        netId = netId,
        entType = entType,
        world = world,
        entity = nil,
        targetSource = nil,
        model = nil,
        coords = nil,
    }

    if netId ~= 0 then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            ent.entity = entity
            ent.model = GetEntityModel(entity)
            local c = GetEntityCoords(entity)
            ent.coords = { x = c.x, y = c.y, z = c.z }
            if entType == 1 or GetEntityType(entity) == 1 then
                ent.targetSource = playerFromEntity(entity)
            end
        end
    end

    return ent
end

local function normalizeWorld(wx, wy, wz)
    wx, wy, wz = tonumber(wx), tonumber(wy), tonumber(wz)
    if not wx or not wy or not wz then return nil end
    return { x = wx, y = wy, z = wz }
end

RegisterServerCallback("vfw:scope:resolve", function(source, scopeName, netId, entType, wx, wy, wz)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { ok = false } end
    if type(scopeName) ~= "string" or scopeName == "" then return { ok = false } end

    local world = normalizeWorld(wx, wy, wz)
    local ent = buildEnt(source, netId, entType, world)

    local resolver = scopes[scopeName]
    local scope

    if resolver then
        local ok, result = pcall(resolver, source, ent, xPlayer)
        if not ok then
            console.error(("[contextmenu] scope %s : %s"):format(scopeName, tostring(result)))
            return { ok = false }
        end
        if result == false then return { ok = false } end
        scope = type(result) == "table" and result or {}
    else
        scope = {}
    end

    scope.targetSource = scope.targetSource or ent.targetSource
    scope.model = scope.model or ent.model
    scope.coords = scope.coords or ent.coords

    return {
        ok = true,
        scope = scope,
        source = source,
        netId = ent.netId,
        entType = ent.entType,
        world = world,
    }
end)

RegisterServerCallback("vfw:conds:batch", function(source, payload)
    local results = {}

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(payload) ~= "table" or type(payload.items) ~= "table" then
        return results
    end

    local entPayload = type(payload.ent) == "table" and payload.ent or {}
    local world = type(entPayload.world) == "table"
        and normalizeWorld(entPayload.world.x, entPayload.world.y, entPayload.world.z)
        or nil
    local ent = buildEnt(source, entPayload.netId, entPayload.entType, world)
    local scope = type(payload.scope) == "table" and payload.scope or nil

    for i = 1, #payload.items do
        local item = payload.items[i]
        if type(item) == "table" and item.id ~= nil and type(item.route) == "string" then
            local allowed = false
            local evaluator = conditions[item.route]

            if evaluator then
                local ok, result = pcall(evaluator, source, ent, scope, xPlayer)
                if ok then
                    allowed = result and true or false
                else
                    console.error(("[contextmenu] condition %s : %s"):format(item.route, tostring(result)))
                end
            end

            results[item.id] = allowed
            results[tostring(item.id)] = allowed
        end
    end

    return results
end)

RegisterServerCallback("vfw:action:run", function(source, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { ok = false, err = "Joueur introuvable." } end
    if type(payload) ~= "table" or type(payload.action) ~= "string" then
        return { ok = false, err = "Action invalide." }
    end

    local entry = actions[payload.action]
    if not entry then
        return { ok = false, err = "Action inconnue." }
    end

    local permission = payload.permission
    if type(permission) ~= "string" or permission == "" then
        permission = entry.permission
    end

    if type(permission) == "string" and permission ~= "" and not xPlayer.hasPermission(permission) then
        return { ok = false, err = "Vous n'avez pas la permission." }
    end

    if type(entry.permission) == "string" and entry.permission ~= "" and not xPlayer.hasPermission(entry.permission) then
        return { ok = false, err = "Vous n'avez pas la permission." }
    end

    local entPayload = type(payload.ent) == "table" and payload.ent or {}
    local world = type(entPayload.world) == "table"
        and normalizeWorld(entPayload.world.x, entPayload.world.y, entPayload.world.z)
        or nil
    local ent = buildEnt(source, entPayload.netId, entPayload.entType, world)
    local scope = type(payload.scope) == "table" and payload.scope or nil

    local ok, result, message = pcall(entry.handler, source, ent, scope, payload.extra, xPlayer)
    if not ok then
        console.error(("[contextmenu] action %s : %s"):format(payload.action, tostring(result)))
        return { ok = false, err = "Action impossible pour le moment." }
    end

    if type(result) == "table" then
        return {
            ok = result.ok and true or false,
            msg = result.msg,
            err = result.err,
        }
    end

    if result == false then
        return { ok = false, err = message or "Action refusee." }
    end

    return { ok = true, msg = message or "OK" }
end)
