---@meta _
---@diagnostic disable: duplicate-doc-field

local hostage = {
    InProgress = false,
    targetSrc = -1,
    type = "", -- "holding" or "beingheld"
    holder = {
        animDict = "anim@gangops@hostage@",
        anim = "perp_idle",
        flag = 49,
    },
    victim = {
        animDict = "anim@gangops@hostage@",
        anim = "victim_idle",
        attachX = -0.3,
        attachY = 0.1,
        attachZ = 0.0,
        flag = 33,
    }
}

local function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
    end
    return animDict
end

local function IsWeaponAllowedForHostage(weaponHash)
    local allowed = GlobalState.HostageWeaponsAllowed
    if not allowed then return false end

    local weaponData = VFW.GetWeaponFromHash(weaponHash)
    if not weaponData then return false end

    return allowed[weaponData.name:upper()] == true
end

local function StopHostage()
    if not hostage.InProgress then return end

    hostage.InProgress = false
    local myPed = VFW.PlayerData.ped

    ClearPedSecondaryTask(myPed)
    DetachEntity(myPed, true, false)
    FreezeEntityPosition(myPed, false)
    SetPedCanRagdoll(myPed, true)

    if hostage.type == "holding" then
        TriggerServerEvent("Hostage:release")
    end

    hostage.targetSrc = -1
    hostage.type = ""
end

-- Command /otage
RegisterCommand('otage', function()
    local myPed = VFW.PlayerData.ped

    -- Already in hostage situation -> release
    if hostage.InProgress and hostage.type == "holding" then
        StopHostage()
        return
    end

    -- Checks
    if hostage.InProgress then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous êtes déjà en situation de prise d'otage." })
        return
    end

    if IsPedInAnyVehicle(myPed, false) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas faire ça en véhicule." })
        return
    end

    if VFW.IsCarrying and VFW.IsCarrying() then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas faire ça en portant quelqu'un." })
        return
    end

    if VFW.IsBeingCarried and VFW.IsBeingCarried() then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas faire ça en étant porté." })
        return
    end

    -- Check weapon in hand
    local weaponHash = GetSelectedPedWeapon(myPed)
    if weaponHash == `weapon_unarmed` then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous devez avoir une arme en main." })
        return
    end

    -- Check weapon whitelist
    if not IsWeaponAllowedForHostage(weaponHash) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette arme ne permet pas de prendre en otage." })
        return
    end

    -- Find closest player
    local closestPlayer = VFW.Game.GetClosestPlayer(GetEntityCoords(myPed), 3.0)
    if not closestPlayer then
        VFW.ShowNotification({ type = 'ROUGE', content = "Il n'y a aucune personne à proximité." })
        return
    end

    local targetPed = GetPlayerPed(closestPlayer)
    local targetSrc = GetPlayerServerId(closestPlayer)
    if not targetSrc or targetSrc <= 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Joueur introuvable." })
        return
    end

    -- Initiate hostage
    hostage.InProgress = true
    hostage.targetSrc = targetSrc
    hostage.type = "holding"

    ensureAnimDict(hostage.holder.animDict)
    TaskPlayAnim(myPed, hostage.holder.animDict, hostage.holder.anim, 8.0, -8.0, 100000, hostage.holder.flag, 0, false, false, false)

    TriggerServerEvent("Hostage:sync", targetSrc)
end, false)

VFW.AddChatSuggestion('/otage', 'Prendre en otage le joueur le plus proche (doit avoir les mains en l\'air)')

-- Animation loop: keep anims playing
CreateThread(function()
    local pNear = 500

    while true do
        pNear = 500

        if hostage.InProgress then
            local myPed = VFW.PlayerData.ped
            if hostage.type == "beingheld" then
                if not IsEntityPlayingAnim(myPed, hostage.victim.animDict, hostage.victim.anim, 3) then
                    TaskPlayAnim(myPed, hostage.victim.animDict, hostage.victim.anim, 8.0, -8.0, 100000, hostage.victim.flag, 0, false, false, false)
                end
            elseif hostage.type == "holding" then
                if not IsEntityPlayingAnim(myPed, hostage.holder.animDict, hostage.holder.anim, 3) then
                    TaskPlayAnim(myPed, hostage.holder.animDict, hostage.holder.anim, 8.0, -8.0, 100000, hostage.holder.flag, 0, false, false, false)
                end
            end

            pNear = 1
        end

        Wait(pNear)
    end
end)

-- Controls thread: holder G=release, H=kill / victim sees message
CreateThread(function()
    while true do
        if hostage.InProgress then
            if hostage.type == "holding" then
                -- Help text for holder
                VFW.ShowHelpNotification("~INPUT_DETONATE~ Relâcher l'otage~n~~INPUT_CONTEXT~ Tuer l'otage")

                -- G (INPUT_DETONATE = 47) -> Release
                if IsControlJustPressed(0, 47) then
                    StopHostage()
                end

                -- E (INPUT_CONTEXT = 51) -> Kill
                if VFW.Interact.JustPressed(0, 51) then
                    local myPed = PlayerPedId()
                    local currentWeapon = GetSelectedPedWeapon(myPed)

                    if currentWeapon == `weapon_unarmed` or GetAmmoInPedWeapon(myPed, currentWeapon) <= 0 then
                        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas de munitions." })
                    else
                        -- Consume 1 bullet
                        local ammo = GetAmmoInPedWeapon(myPed, currentWeapon)
                        SetPedAmmo(myPed, currentWeapon, ammo - 1)

                        hostage.InProgress = false
                        ClearPedSecondaryTask(myPed)
                        TriggerServerEvent("Hostage:kill")
                        hostage.targetSrc = -1
                        hostage.type = ""
                    end
                end
            elseif hostage.type == "beingheld" then
                -- Help text for victim (no action possible)
                VFW.ShowHelpNotification("Vous êtes pris en otage")
            end

            Wait(0)
        else
            Wait(2000)
        end
    end
end)

-- Thread: check if holder dies -> auto-release
CreateThread(function()
    while true do
        if hostage.InProgress and hostage.type == "holding" then
            local myPed = VFW.PlayerData.ped
            if IsPedDeadOrDying(myPed, true) or IsPedFatallyInjured(myPed) then
                TriggerServerEvent("Hostage:release")
                hostage.InProgress = false
                hostage.targetSrc = -1
                hostage.type = ""
            end
        end

        Wait(500)
    end
end)

-- Event: victim gets attached to holder
RegisterNetEvent("Hostage:syncTarget", function(holderSrc)
    local myPed = VFW.PlayerData.ped
    local holderPlayer = GetPlayerFromServerId(holderSrc)
    if holderPlayer == -1 then return end
    local holderPed = GetPlayerPed(holderPlayer)
    if not DoesEntityExist(holderPed) then return end

    FreezeEntityPosition(myPed, true)
    SetPedCanRagdoll(myPed, false)
    ClearPedTasksImmediately(myPed)

    hostage.InProgress = true
    hostage.targetSrc = holderSrc
    hostage.type = "beingheld"

    ensureAnimDict(hostage.victim.animDict)

    AttachEntityToEntity(myPed, holderPed, 0,
        hostage.victim.attachX, hostage.victim.attachY, hostage.victim.attachZ,
        0.0, 0.0, 0.0, false, false, false, false, 2, false)

    TaskPlayAnim(myPed, hostage.victim.animDict, hostage.victim.anim, 8.0, -8.0, 100000, hostage.victim.flag, 0, false, false, false)
end)

-- Event: victim gets released
RegisterNetEvent("Hostage:cl_release", function()
    local myPed = PlayerPedId()

    hostage.InProgress = false
    hostage.targetSrc = -1
    hostage.type = ""

    if DoesEntityExist(myPed) then
        ClearPedSecondaryTask(myPed)
        DetachEntity(myPed, true, false)
        FreezeEntityPosition(myPed, false)
        SetPedCanRagdoll(myPed, true)
    end

    VFW.ShowNotification({ type = 'VERT', content = "Vous avez été relâché." })
end)

-- Event: victim gets killed
RegisterNetEvent("Hostage:cl_kill", function()
    local myPed = PlayerPedId()

    hostage.InProgress = false
    hostage.targetSrc = -1
    hostage.type = ""

    if DoesEntityExist(myPed) then
        ClearPedSecondaryTask(myPed)
        DetachEntity(myPed, true, false)
        FreezeEntityPosition(myPed, false)
        SetPedCanRagdoll(myPed, true)
        SetEntityHealth(myPed, 0)
    end
end)

-- Event: holder cleanup when victim disconnects
RegisterNetEvent("Hostage:cl_holderStop", function()
    local myPed = PlayerPedId()

    hostage.InProgress = false
    hostage.targetSrc = -1
    hostage.type = ""

    if DoesEntityExist(myPed) then
        ClearPedSecondaryTask(myPed)
    end

    VFW.ShowNotification({ type = 'ROUGE', content = "L'otage s'est déconnecté." })
end)

-- Exports
VFW.IsHoldingHostage = function()
    return hostage.InProgress and hostage.type == "holding"
end

VFW.IsBeingHeldHostage = function()
    return hostage.InProgress and hostage.type == "beingheld"
end

VFW.StopHostage = function()
    StopHostage()
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    if not hostage.InProgress then
        return
    end

    local myPed = PlayerPedId()
    ClearPedSecondaryTask(myPed)
    DetachEntity(myPed, true, false)
    FreezeEntityPosition(myPed, false)
    SetPedCanRagdoll(myPed, true)
end)
