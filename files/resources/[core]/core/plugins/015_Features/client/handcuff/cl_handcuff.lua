---@meta _
---@diagnostic disable: undefined-global

-- ============================================================================
-- SYSTÈME DE MENOTTES (intégré au core)
-- Mécanisme repris de 7Cuffs (TulppuG/7Cuffs) : mêmes animations et boucle de
-- contrainte, mais piloté par le core via le statebag joueur `isCuffed` et
-- l'abstraction serveur xPlayer.handcuff/uncuff (aucune dépendance ox_target /
-- ox_inventory). Les items (handcuff, serflex, pince_serflex) et les menus
-- restent gérés par le core (context menu, faction, police...).
-- ============================================================================

local isCuffed = false

-- Boucle bloquante pendant le menottage : rejoue l'animation "idle", désactive
-- le tir et l'attaque au corps-à-corps. (repris de 7Cuffs)
local function cuffedLoop()
    local dict = 'mp_arresting'

    while isCuffed do
        if not IsEntityPlayingAnim(cache.ped, dict, 'idle', 3) then
            lib.requestAnimDict(dict)
            TaskPlayAnim(cache.ped, dict, 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
        end

        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 140, true) -- Attaque légère (melee)
        Wait(0)
    end

    ClearPedTasks(cache.ped)
    RemoveAnimDict(dict)
end

-- Réaction du joueur ciblé quand son état "isCuffed" change (statebag joueur
-- répliqué depuis le serveur). Joue l'animation de réception puis (dé)verrouille
-- les contraintes.
AddStateBagChangeHandler('isCuffed', ('player:%s'):format(cache.serverId), function(_, _, value)
    value = value == true
    if value == isCuffed then return end

    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(cache.ped, true)

    local dict = value and 'mp_arrest_paired' or 'mp_arresting'
    lib.requestAnimDict(dict)

    if value then
        TaskPlayAnim(cache.ped, dict, 'crook_p2_back_right', 8.0, -8, 5000, 2, 0, false, false, false)
        Wait(5000)
    else
        TaskPlayAnim(cache.ped, dict, 'arrested_spin_l_0', 8.0, -8, 4000, 0, 0, false, false, false)
        Wait(4000)
    end

    SetEnableHandcuffs(cache.ped, value)
    LocalPlayer.state:set('invBusy', value, true)
    RemoveAnimDict(dict)
    FreezeEntityPosition(cache.ped, false)

    isCuffed = value
    if isCuffed then
        CreateThread(cuffedLoop)
    end

    ClearPedTasks(cache.ped)
end)

-- Animation de l'agent qui (dé)menotte : il s'attache brièvement à la cible.
-- Déclenché par le serveur (xPlayer.handcuff/uncuff) sur la source de l'agent.
RegisterNetEvent('core:handcuff:cufferAnim', function(targetNetId, isUncuff)
    local targetPed = targetNetId and NetworkGetEntityFromNetworkId(targetNetId)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then return end

    FreezeEntityPosition(cache.ped, true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    AttachEntityToEntity(cache.ped, targetPed, 11816, -0.07, -0.58, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

    local dict = isUncuff and 'mp_arresting' or 'mp_arrest_paired'
    lib.requestAnimDict(dict)

    if isUncuff then
        TaskPlayAnim(cache.ped, dict, 'a_uncuff', 8.0, -8, 5500, 0, 0, false, false, false)
        Wait(5000)
    else
        TaskPlayAnim(cache.ped, dict, 'cop_p2_back_right', 8.0, -8.0, 3750, 2, 0.0, false, false, false)
        Wait(4000)
    end

    DetachEntity(cache.ped, true, false)
    FreezeEntityPosition(cache.ped, false)
    RemoveAnimDict(dict)
    ClearPedTasks(cache.ped)
end)

-- Resynchronisation à l'apparition d'un nouveau ped (respawn/mort) : réapplique
-- l'état de contrainte si le joueur est toujours marqué menotté côté serveur.
AddEventHandler('playerSpawned', function()
    if LocalPlayer.state.isCuffed == true then
        SetEnableHandcuffs(cache.ped, true)
        if not isCuffed then
            isCuffed = true
            CreateThread(cuffedLoop)
        end
    end
end)
