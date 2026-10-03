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


-- ══════════════════════════════════════════════════════════════════════════
-- Scope « player:identity »
--
-- Les sous-menus « Mes informations » et « Infos » du menu contextuel (ALT) lisent leurs
-- valeurs dans ce scope. Aucun fournisseur n'avait jamais été enregistré : toutes les
-- lignes affichaient « N/A », sur soi comme sur les autres joueurs.
-- ══════════════════════════════════════════════════════════════════════════

local function playtimeOf(target)
    local playtime = 0
    if target.globalData then
        playtime = tonumber(target.globalData.playtime) or 0
    end
    if target.sessionStart then
        playtime = playtime + math.max(0, os.time() - target.sessionStart)
    end
    return playtime
end

local function playtimeLabel(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ("%dh%02d"):format(hours, minutes)
    end
    return ("%d min"):format(minutes)
end

local function moneyLabel(amount)
    return ("%d $"):format(math.floor(tonumber(amount) or 0))
end

VFW.ContextMenu.RegisterScope("player:identity", function(source, ent, xPlayer)
    -- Sur un autre joueur, il faut la permission ; sur soi-même, non.
    local targetSource = ent and ent.targetSource or source
    local target = (targetSource == source) and xPlayer or VFW.GetPlayerFromId(targetSource)

    if not target then return false end

    if target.source ~= source then
        if not xPlayer.hasPermission("contextmenu") and not xPlayer.hasPermission("staff_menu") then
            return false
        end
    end

    local bank = target.getAccount and target.getAccount("bank")
    local dirty = target.getAccount and target.getAccount("black_money")

    return {
        targetSource = target.source,
        firstName = target.firstName or "",
        lastName = target.lastName or "",
        date_of_birth = target.dateofbirth or "",
        height = target.height and (tostring(target.height) .. " cm") or "",
        job_label = target.job and (target.job.label or target.job.name) or "Sans emploi",
        job2_label = target.job2 and (target.job2.label or target.job2.name) or "Aucun",
        money = moneyLabel(target.getMoney and target.getMoney() or 0),
        bank = moneyLabel(bank and bank.money or 0),
        black_money = moneyLabel(dirty and dirty.money or 0),
        total_playtime = playtimeLabel(playtimeOf(target)),
    }
end)
