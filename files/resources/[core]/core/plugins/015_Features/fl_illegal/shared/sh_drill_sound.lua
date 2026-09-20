---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- SYSTEME DE SON DE PERCEUSE SYNCHRONISE
-- Permet a tous les joueurs d'entendre les perceuses actives
-- ============================================

local activeDrillSounds = {} -- Track des sons actifs par joueur/position

-- Configuration du son
local DRILL_SOUND_CONFIG = {
    soundName = "Drill",
    soundSet = "DLC_HEIST_FLEECA_SOUNDSET",
    maxDistance = 5.0, -- Distance max pour entendre le son (5m)
    updateInterval = 100 -- Intervalle de mise a jour en ms
}

-- ============================================
-- CLIENT SIDE
-- ============================================
if not IsDuplicityVersion() then

    local myDrillSoundId = nil -- Son local du joueur qui perce

    -- Handler pour demarrer le son de perceuse (pour les autres joueurs)
    RegisterNetEvent("core:illegal:startDrillSound")
    AddEventHandler("core:illegal:startDrillSound", function(drillerId, coords)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local drillPos = vector3(coords.x, coords.y, coords.z)

        -- Ne pas jouer le son pour le joueur qui perce (il a son propre son local)
        if drillerId == GetPlayerServerId(PlayerId()) then
            return
        end

        -- Verifier la distance
        local dist = #(playerCoords - drillPos)
        if dist > DRILL_SOUND_CONFIG.maxDistance then
            return
        end

        -- Creer un sound ID unique pour ce joueur
        local soundId = GetSoundId()

        -- Jouer le son en boucle a la position
        PlaySoundFromCoord(soundId, DRILL_SOUND_CONFIG.soundName,
            coords.x, coords.y, coords.z,
            DRILL_SOUND_CONFIG.soundSet, true, DRILL_SOUND_CONFIG.maxDistance, false)

        -- Stocker le sound ID pour pouvoir l'arreter plus tard
        activeDrillSounds[drillerId] = {
            soundId = soundId,
            coords = coords
        }
    end)

    -- Handler pour arreter le son de perceuse
    RegisterNetEvent("core:illegal:stopDrillSound")
    AddEventHandler("core:illegal:stopDrillSound", function(drillerId)
        -- Ne pas traiter pour soi-meme
        if drillerId == GetPlayerServerId(PlayerId()) then
            return
        end

        if activeDrillSounds[drillerId] then
            local soundData = activeDrillSounds[drillerId]
            if soundData.soundId then
                StopSound(soundData.soundId)
                ReleaseSoundId(soundData.soundId)
            end
            activeDrillSounds[drillerId] = nil
        end
    end)

    -- Nettoyage quand un joueur se deconnecte
    RegisterNetEvent("core:illegal:cleanupDrillSound")
    AddEventHandler("core:illegal:cleanupDrillSound", function(drillerId)
        if activeDrillSounds[drillerId] then
            local soundData = activeDrillSounds[drillerId]
            if soundData.soundId then
                StopSound(soundData.soundId)
                ReleaseSoundId(soundData.soundId)
            end
            activeDrillSounds[drillerId] = nil
        end
    end)

    -- Nettoyage au demarrage de la ressource
    AddEventHandler("onResourceStart", function(resourceName)
        if GetCurrentResourceName() == resourceName then
            activeDrillSounds = {}
        end
    end)

    -- Nettoyage a l'arret de la ressource
    AddEventHandler("onResourceStop", function(resourceName)
        if GetCurrentResourceName() == resourceName then
            for drillerId, soundData in pairs(activeDrillSounds) do
                if soundData.soundId then
                    StopSound(soundData.soundId)
                    ReleaseSoundId(soundData.soundId)
                end
            end
            activeDrillSounds = {}
        end
    end)

    -- Fonction exportee pour demarrer le son (appele par les scripts de drilling)
    function StartSyncedDrillSound(coords)
        -- Jouer le son localement pour le joueur qui perce
        if myDrillSoundId then
            StopSound(myDrillSoundId)
            ReleaseSoundId(myDrillSoundId)
        end

        myDrillSoundId = GetSoundId()
        PlaySoundFromCoord(myDrillSoundId, DRILL_SOUND_CONFIG.soundName,
            coords.x, coords.y, coords.z,
            DRILL_SOUND_CONFIG.soundSet, true, DRILL_SOUND_CONFIG.maxDistance, false)

        -- Broadcast aux autres joueurs
        TriggerServerEvent("core:illegal:broadcastDrillSound", "start", coords)
    end

    -- Fonction exportee pour arreter le son
    function StopSyncedDrillSound()
        -- Arreter le son local
        if myDrillSoundId then
            StopSound(myDrillSoundId)
            ReleaseSoundId(myDrillSoundId)
            myDrillSoundId = nil
        end

        -- Broadcast aux autres joueurs
        TriggerServerEvent("core:illegal:broadcastDrillSound", "stop", nil)
    end

-- ============================================
-- SERVER SIDE
-- ============================================
else

    local activeDrillers = {} -- Track qui est en train de percer

    -- Recevoir les demandes de broadcast du son
    RegisterNetEvent("core:illegal:broadcastDrillSound")
    AddEventHandler("core:illegal:broadcastDrillSound", function(action, coords)
        local source = source

        if action == "start" then
            -- Stocker l'info du joueur qui perce
            activeDrillers[source] = {
                coords = coords,
                startTime = GetGameTimer()
            }

            -- Broadcast a tous les autres joueurs
            TriggerClientEvent("core:illegal:startDrillSound", -1, source, coords)

        elseif action == "stop" then
            -- Supprimer l'info
            activeDrillers[source] = nil

            -- Broadcast l'arret a tous les autres joueurs
            TriggerClientEvent("core:illegal:stopDrillSound", -1, source)
        end
    end)

    -- Nettoyage quand un joueur se deconnecte
    AddEventHandler("playerDropped", function(reason)
        local source = source

        if activeDrillers[source] then
            activeDrillers[source] = nil
            -- Informer tous les clients d'arreter le son pour ce joueur
            TriggerClientEvent("core:illegal:cleanupDrillSound", -1, source)
        end
    end)

    -- Sync pour les joueurs qui rejoignent (pour entendre les drills en cours)
    AddEventHandler("core:playerloaded", function(playerId)
        SetTimeout(2000, function()
            -- Envoyer tous les drills actifs au nouveau joueur
            for drillerId, drillData in pairs(activeDrillers) do
                TriggerClientEvent("core:illegal:startDrillSound", playerId, drillerId, drillData.coords)
            end
        end)
    end)
end
