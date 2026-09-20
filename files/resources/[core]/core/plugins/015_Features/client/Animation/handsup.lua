---@meta _
---@diagnostic disable: duplicate-doc-field

local isHandsup = false

function VFW.IsPlayerHandsUp(ped)
    if not ped then
        ped = VFW.PlayerData.ped
    end

    if ped == VFW.PlayerData.ped then
        return isHandsup
    end

    return IsEntityPlayingAnim(ped, "random@mugging3", "handsup_standing_base", 3)
end

local handsupDict = "random@mugging3"
local handsupAnim = "handsup_standing_base"

RegisterCommand('+handsup', function()
    if SN_SAMS and SN_SAMS.cprActive then return end
    if IsPlayerInMugshot() then return end
    if VFW.isEscorting then return end
    if not IsPedOnFoot(VFW.PlayerData.ped) then
        return
    end

    isHandsup = not isHandsup

    if isHandsup then
        RequestAnimDict(handsupDict)
        while not HasAnimDictLoaded(handsupDict) do
            Wait(0)
        end

        TaskPlayAnim(VFW.PlayerData.ped, handsupDict, handsupAnim, 2.0, 2.0, -1, 49, 0, false, false, false)
    else
        if IsEntityPlayingAnim(VFW.PlayerData.ped, handsupDict, handsupAnim, 3) then
            StopAnimTask(VFW.PlayerData.ped, handsupDict, handsupAnim, -2.0)
        else
            ClearPedTasks(VFW.PlayerData.ped)
        end
    end

end, false)
RegisterKeyMapping('+handsup', "Mains en l'air", 'keyboard', 'GRAVE')

-- Commande pour arreter toute animation (emotes + handsup) avec X
RegisterCommand('+cancelanim', function()
    if SN_SAMS and SN_SAMS.cprActive then return end
    if IsPlayerInMugshot() then return end
    if VFW.isEscorting then return end
    local ped = VFW.PlayerData.ped

    if IsEntityDead(ped) or (Death and Death.isDead) or isKnockedOut then
        return
    end

    -- Vérifier si le joueur a une emote active ou handsup
    local hasEmote = HasActiveEmote and HasActiveEmote(ped)

    if not isHandsup and not hasEmote then
        return
    end

    -- Arreter handsup si actif avec blend-out fluide
    if isHandsup then
        isHandsup = false
        if not IsPedInAnyVehicle(ped, false) then
            if IsEntityPlayingAnim(ped, handsupDict, handsupAnim, 3) then
                StopAnimTask(ped, handsupDict, handsupAnim, -2.0)
            else
                ClearPedTasks(ped)
            end
        end
    end

    -- Arreter toute autre animation (emotes, scenarios, etc.)
    if hasEmote then
        -- Cancel via server to propagate to shared emote partner
        TriggerServerEvent("vfw:newanim:cancelSharedAnim")
    end
end, false)
RegisterKeyMapping('+cancelanim', "Annuler animation", 'keyboard', 'X')
