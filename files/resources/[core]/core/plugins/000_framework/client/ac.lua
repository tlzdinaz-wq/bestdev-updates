---@meta _
---@diagnostic disable: duplicate-doc-field

local blacklistedAnimations = {
    {
        dict = "anim@mp_rollarcoaster",
        name = "hands_up_idle_a_player_one",
    }
}

local blacklistedAnimTriggered = false

---@param ped number
---@return boolean
local function isPlayingBlacklistedAnim(ped)
    for _, anim in pairs(blacklistedAnimations) do
        if IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then
            return true
        end
    end

    return false
end

local function sanitizeBlacklistedEmotes()
    if type(RP) ~= "table" then
        return
    end

    for _, listName in ipairs({ "Emotes", "PropEmotes" }) do
        local emoteList = RP[listName]
        if type(emoteList) ~= "table" then
            goto continue
        end

        for emoteName, emoteData in pairs(emoteList) do
            if type(emoteData) ~= "table" then
                goto next_emote
            end

            for i = 1, #blacklistedAnimations do
                local anim = blacklistedAnimations[i]
                if emoteData[1] == anim.dict and emoteData[2] == anim.name then
                    emoteList[emoteName] = nil
                    break
                end
            end

            ::next_emote::
        end

        ::continue::
    end
end

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()
        if ped == 0 or not DoesEntityExist(ped) then
            goto continue
        end

        if not isPlayingBlacklistedAnim(ped) then
            blacklistedAnimTriggered = false
            goto continue
        end

        if not blacklistedAnimTriggered then
            blacklistedAnimTriggered = true
            TriggerServerEvent(
                "ac:flagBlacklistedAnimation",
                "anim@mp_rollarcoaster",
                "hands_up_idle_a_player_one"
            )
        end

        ::continue::
    end
end)

CreateThread(function()
    while type(RP) ~= "table" or (type(RP.Emotes) ~= "table" and type(RP.PropEmotes) ~= "table") do
        Wait(250)
    end

    sanitizeBlacklistedEmotes()
end)

---@param resName string
AddEventHandler('onClientResourceStop', function(resName)
    if resName == 'gsm' then
        TriggerServerEvent('imASlut')
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- AntiAttach — détection prop de propulsion/kill attaché au joueur
-- ════════════════════════════════════════════════════════════════════
-- Le cheat attache un prop (modèle ATTACH_EXPLOIT_MODEL) au ped d'un autre
-- joueur pour le propulser / le tuer. Aucun usage légitime de ce modèle
-- attaché à un ped joueur.
--
-- Détection CÔTÉ VICTIME : le prop étant attaché au ped local, il est
-- toujours streamé ici, et GetEntityAttachedTo est fiable sur son propre
-- ped. On envoie uniquement le netId de l'objet ; c'est le SERVEUR qui
-- re-valide le modèle et identifie l'auteur via le owner réseau du prop.
-- On ne signale que si le prop est réellement attaché au ped joueur (un
-- prop simplement posé dans le monde n'est jamais signalé).
local ATTACH_EXPLOIT_MODEL = 1336576410
local ATTACH_SCAN_INTERVAL_MS = 500
local ATTACH_REPORT_COOLDOWN_MS = 5000
local lastAttachReport = 0

CreateThread(function()
    while true do
        Wait(ATTACH_SCAN_INTERVAL_MS)

        -- Désactivable en cas de problème via /antiattach. nil/true => actif.
        if GlobalState.AntiAttachEnabled == false then
            goto continue
        end

        local ped = PlayerPedId()
        if ped == 0 or not DoesEntityExist(ped) then
            goto continue
        end

        local now = GetGameTimer()
        if (now - lastAttachReport) < ATTACH_REPORT_COOLDOWN_MS then
            goto continue
        end

        for _, obj in ipairs(GetGamePool('CObject')) do
            if GetEntityModel(obj) == ATTACH_EXPLOIT_MODEL and GetEntityAttachedTo(obj) == ped then
                local netId = NetworkGetNetworkIdFromEntity(obj)
                if netId and netId ~= 0 then
                    lastAttachReport = now
                    TriggerServerEvent("ac:reportAttachExploit", netId)
                end
                break
            end
        end

        ::continue::
    end
end)

-- Le serveur demande de revive la victime après suppression du prop, mais
-- SEULEMENT si elle est réellement morte (l'état de mort est local, non
-- répliqué : le client de la victime est le seul juge fiable). On réutilise
-- le flux de revive existant (vfw:revivePlayer) sans réanimer un joueur vivant.
RegisterNetEvent("ac:reviveIfDead", function()
    local function reviveIfDead()
        local ped = PlayerPedId()
        if ped == 0 or not DoesEntityExist(ped) then
            return false
        end

        local dead = IsEntityDead(ped)
            or IsPedDeadOrDying(ped, true)
            or (type(Death) == "table" and Death.isDead)
            or (VFW.PlayerData and VFW.PlayerData.dead)

        if dead then
            TriggerEvent("vfw:revivePlayer")
            return true
        end

        return false
    end

    -- Vérif immédiate, puis re-vérif différée : la propulsion peut tuer la
    -- victime juste après la suppression du prop.
    if reviveIfDead() then
        return
    end

    CreateThread(function()
        Wait(1500)
        reviveIfDead()
    end)
end)

local headBoneTags = {}
for _, bone in ipairs({1356, 11174, 12844, 17188, 17719, 19336, 20178, 20279, 20623, 21550, 25260, 27474, 29868, 31086, 35731, 43536, 45750, 46240, 47419, 47495, 49979, 58331, 61839, 39317}) do
    headBoneTags[bone] = true
end

RegisterNetEvent("ac:checkHeadshot", function(payload)
    if not payload or not payload.netId or not payload.bonusDamage then return end

    Wait(50)

    local entity = NetworkDoesEntityExistWithNetworkId(payload.netId) and NetworkGetEntityFromNetworkId(payload.netId) or 0
    if entity == 0 or not DoesEntityExist(entity) then return end

    local existed, lastBone = GetPedLastDamageBone(entity)
    if not existed or not headBoneTags[lastBone] then return end

    local bonus = payload.bonusDamage
    local currentArmor = GetPedArmour(entity)
    if currentArmor > 0 then
        local newArmor = math.max(0, currentArmor - bonus)
        local consumed = currentArmor - newArmor
        SetPedArmour(entity, math.floor(newArmor))
        bonus = bonus - consumed
    end

    if bonus > 0 then
        local currentHealth = GetEntityHealth(entity)
        SetEntityHealth(entity, math.max(0, math.floor(currentHealth - bonus)))
    end
end)
