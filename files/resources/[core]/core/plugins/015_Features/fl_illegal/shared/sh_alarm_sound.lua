---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- SYSTEME D'ALARME SYNCHRONISE
-- ============================================

-- Configuration
local ALARM_DURATION = 120000 -- 2 minutes
local ALARM_INTERVAL = 500    -- Intervalle entre les sons
local ALARM_MAX_DISTANCE = 50.0 -- Distance max pour entendre l'alarme (en mètres)
local ALARM_MIN_VOLUME = 0.05   -- Volume minimum (quand loin)
local ALARM_MAX_VOLUME = 0.8    -- Volume maximum (quand proche)

-- ============================================
-- CLIENT SIDE
-- ============================================
if not IsDuplicityVersion() then

    local activeClientAlarms = {}
    local alarmThreads = {}

    -- Handler pour demarrer une alarme
    RegisterNetEvent("core:illegal:startAlarm")
    AddEventHandler("core:illegal:startAlarm", function(alarmId, coords, alarmType)
        if activeClientAlarms[alarmId] then return end

        local alarmPos = vector3(coords.x, coords.y, coords.z)

        activeClientAlarms[alarmId] = {
            coords = alarmPos,
            alarmType = alarmType
        }
        alarmThreads[alarmId] = true

        -- Thread qui gere la distance et le volume progressif
        Citizen.CreateThread(function()
            local wasPlaying = false
            local lastVolume = 0

            while alarmThreads[alarmId] do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords - alarmPos)

                if dist < ALARM_MAX_DISTANCE then
                    -- Calculer le volume progressif (plus proche = plus fort)
                    local distRatio = dist / ALARM_MAX_DISTANCE -- 0 (proche) à 1 (loin)
                    local volume = ALARM_MAX_VOLUME - (distRatio * (ALARM_MAX_VOLUME - ALARM_MIN_VOLUME))
                    volume = math.max(ALARM_MIN_VOLUME, math.min(ALARM_MAX_VOLUME, volume))

                    -- Arrondir pour éviter les mises à jour inutiles
                    local roundedVolume = math.floor(volume * 100) / 100

                    if not wasPlaying or roundedVolume ~= lastVolume then
                        SendNUIMessage({
                            action = "nui:alarm",
                            data = { action = "start", volume = roundedVolume }
                        })
                        wasPlaying = true
                        lastVolume = roundedVolume
                    end
                else
                    if wasPlaying then
                        -- Arrêter si trop loin
                        SendNUIMessage({
                            action = "nui:alarm",
                            data = { action = "stop" }
                        })
                        wasPlaying = false
                        lastVolume = 0
                    end
                end

                Citizen.Wait(500)
            end
        end)
    end)

    -- Handler pour arreter une alarme
    RegisterNetEvent("core:illegal:stopAlarm")
    AddEventHandler("core:illegal:stopAlarm", function(alarmId)
        alarmThreads[alarmId] = nil
        activeClientAlarms[alarmId] = nil

        -- Arreter le son NUI
        SendNUIMessage({
            action = "nui:alarm",
            data = { action = "stop" }
        })
    end)

    -- ==========================================
    -- COMMANDES DE TEST
    -- ==========================================

    -- COMMANDES SUPPRIMÉES : /testalarm et /stopalarm

    -- Nettoyage
    AddEventHandler("onResourceStop", function(resourceName)
        if GetCurrentResourceName() == resourceName then
            for alarmId, _ in pairs(alarmThreads) do
                alarmThreads[alarmId] = nil
            end
            activeClientAlarms = {}
            alarmThreads = {}
        end
    end)

-- ============================================
-- SERVER SIDE
-- ============================================
else

    local activeServerAlarms = {}

    function StartAlarm(alarmId, coords, alarmType)
        if activeServerAlarms[alarmId] then return end

        activeServerAlarms[alarmId] = {
            coords = coords,
            alarmType = alarmType or "default",
            startTime = GetGameTimer()
        }

        TriggerClientEvent("core:illegal:startAlarm", -1, alarmId, coords, alarmType)

        -- Auto-stop apres 2 minutes
        SetTimeout(ALARM_DURATION, function()
            if activeServerAlarms[alarmId] then
                StopAlarm(alarmId)
            end
        end)
    end

    function StopAlarm(alarmId)
        if not activeServerAlarms[alarmId] then return end
        activeServerAlarms[alarmId] = nil
        TriggerClientEvent("core:illegal:stopAlarm", -1, alarmId)
    end

    function IsAlarmActive(alarmId)
        return activeServerAlarms[alarmId] ~= nil
    end

    -- Sync nouveaux joueurs
    AddEventHandler("core:playerloaded", function(playerId)
        SetTimeout(2000, function()
            for alarmId, alarmData in pairs(activeServerAlarms) do
                TriggerClientEvent("core:illegal:startAlarm", playerId, alarmId, alarmData.coords, alarmData.alarmType)
            end
        end)
    end)

    -- Nettoyage
    AddEventHandler("onResourceStop", function(resourceName)
        if GetCurrentResourceName() == resourceName then
            for alarmId, _ in pairs(activeServerAlarms) do
                TriggerClientEvent("core:illegal:stopAlarm", -1, alarmId)
            end
            activeServerAlarms = {}
        end
    end)

    -- Exports
    exports("StartAlarm", StartAlarm)
    exports("StopAlarm", StopAlarm)
    exports("IsAlarmActive", IsAlarmActive)
end
