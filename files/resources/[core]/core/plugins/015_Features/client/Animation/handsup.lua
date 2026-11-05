---@meta _
---@diagnostic disable: duplicate-doc-field

local isHandsup = false

local handsupDict = "random@mugging3"
local handsupAnim = "handsup_standing_base"

-- Le raccourci et le menu d'emotes ne jouent pas la même animation.
-- On les reconnaît toutes pour pouvoir les baisser.
local HANDS_ANIMS = {
    { handsupDict, handsupAnim },
    { "missminuteman_1ig_2", "handsup_base" },
    { "anim@mp_player_intuppersurrender", "idle_a_fp" },
    { "anim@mp_rollarcoaster", "hands_up_idle_a_player_one" },
}

local function playingHands(ped)
    for i = 1, #HANDS_ANIMS do
        local entry = HANDS_ANIMS[i]
        if IsEntityPlayingAnim(ped, entry[1], entry[2], 3) then
            return true
        end
    end
    return false
end

local function lowerHands(ped)
    isHandsup = false
    for i = 1, #HANDS_ANIMS do
        local entry = HANDS_ANIMS[i]
        StopAnimTask(ped, entry[1], entry[2], 2.0)
    end
    -- Flag 49/51 : l'animation tourne en tâche secondaire. StopAnimTask la
    -- laisse souvent en place, donc les mains restent levées.
    ClearPedSecondaryTask(ped)
    if playingHands(ped) and not IsPedInAnyVehicle(ped, false) then
        ClearPedTasks(ped)
    end
end

function VFW.IsPlayerHandsUp(ped)
    if not ped then
        ped = VFW.PlayerData.ped
    end

    if playingHands(ped) then
        return true
    end

    if ped == VFW.PlayerData.ped then
        return isHandsup
    end

    return false
end

RegisterCommand('+handsup', function()
    if SN_SAMS and SN_SAMS.cprActive then return end
    if IsPlayerInMugshot() then return end
    if VFW.isEscorting then return end

    local ped = VFW.PlayerData.ped or PlayerPedId()
    if not ped or ped == 0 or not IsPedOnFoot(ped) then
        return
    end

    if isHandsup or playingHands(ped) then
        lowerHands(ped)
        if HasActiveEmote and HasActiveEmote(ped) then
            VFW.CancelEmote()
        end
        return
    end

    isHandsup = true
    RequestAnimDict(handsupDict)
    while not HasAnimDictLoaded(handsupDict) do
        Wait(0)
    end

    TaskPlayAnim(ped, handsupDict, handsupAnim, 2.0, 2.0, -1, 49, 0, false, false, false)
end, false)
RegisterCommand('-handsup', function() end, false)
RegisterKeyMapping('+handsup', "Mains en l'air", 'keyboard', 'GRAVE')

-- Commande pour arreter toute animation (emotes + handsup) avec X
RegisterCommand('+cancelanim', function()
    if SN_SAMS and SN_SAMS.cprActive then return end
    if IsPlayerInMugshot() then return end
    if VFW.isEscorting then return end
    local ped = VFW.PlayerData.ped or PlayerPedId()
    if not ped or ped == 0 then return end

    if IsEntityDead(ped) or (Death and Death.isDead) or isKnockedOut then
        return
    end

    local hasEmote = HasActiveEmote and HasActiveEmote(ped)
    local hands = isHandsup or playingHands(ped)

    if not hands and not hasEmote then
        return
    end

    if hands then
        lowerHands(ped)
    end

    if hasEmote then
        VFW.CancelEmote()
    end
end, false)
-- Relâchement de la touche : rien à faire (sans cette commande, FiveM signale « -cancelanim » inconnue)
RegisterCommand('-cancelanim', function() end, false)
RegisterKeyMapping('+cancelanim', "Annuler animation", 'keyboard', 'X')
