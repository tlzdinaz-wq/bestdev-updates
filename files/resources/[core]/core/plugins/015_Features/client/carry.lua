---@meta _
---@diagnostic disable: duplicate-doc-field

local carry = {
    InProgress = false,
    targetSrc = -1,
    type = "",
    personCarrying = {
        animDict = "missfinale_c2mcs_1",
        anim = "fin_c2_mcs_1_camman",
        flag = 49,
    },
    personCarried = {
        animDict = "nm",
        anim = "firemans_carry",
        attachX = 0.27,
        attachY = 0.15,
        attachZ = 0.63,
        flag = 33,
    }
}

--- ensureAnimDict
---@param animDict any
local function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
    end
    
    return animDict
end

--- .CarryPeople
---@param entity any
function VFW.CarryPeople(entity)
    if not carry.InProgress then
        -- Verifier si le joueur cible est mort (animation de mort)
        local targetSrc = VFW.GetDeathCloneOwner and VFW.GetDeathCloneOwner(entity)
        if not targetSrc then
            local players = NetworkGetPlayerIndexFromPed(entity)
            targetSrc = GetPlayerServerId(players)
        end

        if targetSrc and targetSrc > 0 then
            -- Sortir de tout scenario/emote (sit, lean, etc.) AVANT le carry, sinon
            -- la cancellation ulterieure (cancelemote / X) declenche un clip-floor
            -- car le carrier est encore ancre par le scenario quand B est attache.
            local myPed = VFW.PlayerData.ped
            if HasActiveEmote and HasActiveEmote(myPed) then
                if StopAnimation then
                    StopAnimation(myPed, true)
                else
                    ClearPedTasksImmediately(myPed)
                end
                Wait(100)
            end

            carry.InProgress = true
            carry.targetSrc = targetSrc

            TriggerServerEvent("CarryPeople:sync", targetSrc)

            ensureAnimDict(carry.personCarrying.animDict)

            carry.type = "carrying"
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Personne à proximité !"
            })
        end
    else
        carry.InProgress = false

        ClearPedSecondaryTask(VFW.PlayerData.ped)

        DetachEntity(VFW.PlayerData.ped, true, false)

        TriggerServerEvent("CarryPeople:stop", carry.targetSrc)

        carry.targetSrc = 0
    end
end

CreateThread(function()
    local pNear = 500
    
    while true do
        pNear = 500
        
        if carry.InProgress then
            if carry.type == "beingcarried" then
                if not IsEntityPlayingAnim(VFW.PlayerData.ped, carry.personCarried.animDict, carry.personCarried.anim, 3) then
                    TaskPlayAnim(VFW.PlayerData.ped, carry.personCarried.animDict, carry.personCarried.anim, 8.0, -8.0, 100000, carry.personCarried.flag, 0, false, false, false)
                end
            elseif carry.type == "carrying" then
                if not IsEntityPlayingAnim(VFW.PlayerData.ped, carry.personCarrying.animDict, carry.personCarrying.anim, 3) then
                    TaskPlayAnim(VFW.PlayerData.ped, carry.personCarrying.animDict, carry.personCarrying.anim, 8.0, -8.0, 100000, carry.personCarrying.flag, 0, false, false, false)
                end
            end

            pNear = 1
        end
        
        Wait(pNear)
    end
end)

CreateThread(function()
    while true do
        if carry.InProgress then
            -- Afficher l'aide à l'écran
            if carry.type == "carrying" then
                -- Pour celui qui porte
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour relâcher le joueur")
            elseif carry.type == "beingcarried" and not (Death and Death.isDead) then
                -- Pour celui qui est porté (pas si mort)
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vous libérer")
            end

            -- Allow both carrier and carried person to press E to stop (not if dead)
            local canBreakFree = carry.type ~= "beingcarried" or not (Death and Death.isDead)
            if canBreakFree and VFW.Interact.JustPressed(0, 51) then -- E key
                carry.InProgress = false

                ClearPedSecondaryTask(VFW.PlayerData.ped)

                DetachEntity(VFW.PlayerData.ped, true, false)

                if carry.type == "carrying" then
                    TriggerServerEvent("CarryPeople:stop", carry.targetSrc)
                elseif carry.type == "beingcarried" then
                    -- Notify the carrier to stop
                    TriggerServerEvent("CarryPeople:requestStop")
                end

                carry.targetSrc = 0
                carry.type = ""
            end

            Wait(0)
        else
            Wait(2000)
        end
    end
end)

---@param targetSrc any
RegisterNetEvent("CarryPeople:syncTarget", function(targetSrc)
    local targetPlayer = GetPlayerFromServerId(targetSrc)
    if targetPlayer == -1 then return end
    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then return end
    local myPed = VFW.PlayerData.ped

    -- Si le joueur est mort, arreter la boucle d'animation de mort
    if Death and Death.isDead then
        Death.gettingRevived = true

        -- Si le carry arrive avant le resurrect (pendant les 2s de ragdoll)
        if IsPedDeadOrDying(myPed, true) then
            local coords = GetEntityCoords(myPed)
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(myPed), true, false)
            myPed = PlayerPedId()
            SetEntityInvincible(myPed, true)
            SetEntityHealth(myPed, 100)
            SetEveryoneIgnorePlayer(PlayerId(), true)
        end
    end

    -- Si le joueur est dans un véhicule, le sortir avant d'attacher au porteur
    if IsPedInAnyVehicle(myPed, false) then
        local veh = GetVehiclePedIsIn(myPed, false)
        ClearPedTasksImmediately(myPed)
        if veh and veh ~= 0 then
            TaskLeaveVehicle(myPed, veh, 16)
        end
        local timeout = GetGameTimer() + 1500
        while IsPedInAnyVehicle(PlayerPedId(), false) and GetGameTimer() < timeout do
            Wait(50)
        end
        myPed = PlayerPedId()
        if IsPedInAnyVehicle(myPed, false) then
            -- Fallback : téléporter à côté du porteur si l'éjection échoue
            local tCoords = GetEntityCoords(targetPed)
            SetEntityCoords(myPed, tCoords.x, tCoords.y, tCoords.z, true, false, false, false)
        end
    end

    FreezeEntityPosition(myPed, false)
    SetPedCanRagdoll(myPed, false)
    ClearPedTasksImmediately(myPed)

    carry.InProgress = true

    ensureAnimDict(carry.personCarried.animDict)

    AttachEntityToEntity(myPed, targetPed, 0, carry.personCarried.attachX, carry.personCarried.attachY, carry.personCarried.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)

    carry.type = "beingcarried"
end)

RegisterNetEvent("CarryPeople:cl_stop", function()
    carry.InProgress = false
    local myPed = VFW.PlayerData.ped

    ClearPedSecondaryTask(myPed)
    DetachEntity(myPed, true, false)
    SetPedCanRagdoll(myPed, true)

    -- Si le joueur etait mort, reprendre la boucle d'animation de mort
    if Death and Death.isDead then
        Death.gettingRevived = false
    end
end)

-- Export functions to check carry status
VFW.IsCarrying = function()
    return carry.InProgress and carry.type == "carrying"
end

VFW.IsBeingCarried = function()
    return carry.InProgress and carry.type == "beingcarried"
end

VFW.GetCarryTarget = function()
    return carry.targetSrc
end

VFW.StopCarrying = function()
    if carry.InProgress then
        carry.InProgress = false
        ClearPedSecondaryTask(VFW.PlayerData.ped)
        DetachEntity(VFW.PlayerData.ped, true, false)

        if carry.type == "carrying" then
            TriggerServerEvent("CarryPeople:stop", carry.targetSrc)
        elseif carry.type == "beingcarried" then
            TriggerServerEvent("CarryPeople:requestStop")
        end

        carry.targetSrc = 0
        carry.type = ""
    end
end

-- Commande /porter pour porter le joueur le plus proche
RegisterCommand('porter', function()
    if Death and Death.isDead then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas porter quelqu'un en étant mort."
        })
        return
    end

    if carry.InProgress then
        -- Si déjà en train de porter, arrêter
        VFW.CarryPeople(nil)
        return
    end

    -- Trouver le joueur le plus proche
    local closestPlayer = VFW.Game.GetClosestPlayer(GetEntityCoords(VFW.PlayerData.ped), 3.0)

    if not closestPlayer then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Il n'y a aucune personne à proximité."
        })
        return
    end

    local targetPed = GetPlayerPed(closestPlayer)

    VFW.CarryPeople(targetPed)
end, false)

VFW.AddChatSuggestion('/porter', 'Porter le joueur le plus proche')

local tackleDict <const> = "missmic2ig_11"
local tackleAnimAttacker <const> = "mic_2_ig_11_intro_goon"
local tackleAnimVictim <const> = "mic_2_ig_11_intro_p_one"

RegisterNetEvent("interaction:tackle:attacker", function(targetId)
    local ped = PlayerPedId()
    local targetPlayer = GetPlayerFromServerId(targetId)
    if targetPlayer == -1 then return end
    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then return end

    RequestAnimDict(tackleDict)
    while not HasAnimDictLoaded(tackleDict) do Wait(10) end

    local targetCoords = GetEntityCoords(targetPed)
    local myCoords = GetEntityCoords(ped)
    local heading = GetHeadingFromVector_2d(targetCoords.x - myCoords.x, targetCoords.y - myCoords.y)
    SetEntityHeading(ped, heading)

    AttachEntityToEntity(ped, targetPed, 11816, 0.25, 0.5, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
    TaskPlayAnim(ped, tackleDict, tackleAnimAttacker, 8.0, -8.0, 3000, 0, 0, false, false, false)
    Wait(3000)
    DetachEntity(ped, true, false)
    ClearPedTasks(ped)
    RemoveAnimDict(tackleDict)
end)

RegisterNetEvent("interaction:tackle:victim", function(attackerSource)
    local ped = PlayerPedId()

    RequestAnimDict(tackleDict)
    while not HasAnimDictLoaded(tackleDict) do Wait(10) end

    TaskPlayAnim(ped, tackleDict, tackleAnimVictim, 8.0, -8.0, 3000, 0, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(ped)
    SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false)
    RemoveAnimDict(tackleDict)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    if not carry.InProgress then
        return
    end

    local myPed = PlayerPedId()
    ClearPedSecondaryTask(myPed)
    DetachEntity(myPed, true, false)
    SetPedCanRagdoll(myPed, true)
end)
