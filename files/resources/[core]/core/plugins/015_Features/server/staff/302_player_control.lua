local frozenPlayers = {}

local function canControlPlayer(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if xPlayer.hasPermission("freeze_player")
        or xPlayer.hasPermission("menu_anim")
        or xPlayer.hasPermission("staff_menu") then
        return xPlayer
    end

    return nil
end

local function setPlayerFrozen(source, targetId, frozen)
    local xPlayer = canControlPlayer(source)
    if not xPlayer then
        return false, "Vous n'avez pas la permission de freeze un joueur."
    end
    if not Staff29.RateLimit(source, "player:freeze", 250) then
        return false, "Patientez un instant."
    end

    local target = Staff29.ToInt(targetId, 1, 65535)
    local xTarget = target and VFW.GetPlayerFromId(target) or nil
    if not xTarget then
        return false, "Ce joueur n'est plus connecté."
    end

    local state = frozen == true or frozen == 1
    frozenPlayers[target] = state or nil

    TriggerClientEvent("core:FreezePlayer", target, state)
    TriggerEvent("vfw:logs:staff", source, state and "player_freeze" or "player_unfreeze", {
        target = target,
        targetName = xTarget.name,
    })
    return true
end

Staff29.Cb("vfw:staff:setPlayerFrozen", setPlayerFrozen)

RegisterNetEvent("core:FreezePlayer", function(targetId, frozen)
    local success, reason = setPlayerFrozen(source, targetId, frozen)
    if not success and reason then
        Staff29.Notify(source, "ERROR", "Gestion joueur", reason)
    end
end)

Staff29.Cb("vfw:staff:isPlayerFrozen", function(source, targetId)
    if not canControlPlayer(source) then return false end
    local target = Staff29.ToInt(targetId, 1, 65535)
    return target and frozenPlayers[target] == true or false
end)

AddEventHandler("vfw:playerDropped", function(source)
    frozenPlayers[tonumber(source)] = nil
end)

