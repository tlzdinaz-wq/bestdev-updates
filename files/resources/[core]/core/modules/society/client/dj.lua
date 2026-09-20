---@meta _
---@diagnostic disable: duplicate-doc-field

local open = false
local lastSoundId = nil
local xSound = exports.xsound
local pause = false

--- OpenMenu
local function OpenMenu()
    open = not open
    VFW.Nui.MediaPlayer(open)
end

RegisterNUICallback("nui:MediaPlayer:play", function(data)
    TriggerServerEvent("core:dj:play", "mediaplayer_" .. math.random(1000, 9999), data, 0.5, GetEntityCoords(PlayerPedId()), VFW.GetDJDistance())
end)

RegisterNUICallback("nui:MediaPlayer:stop", function()
    TriggerServerEvent("core:dj:stop", lastSoundId)
end)

RegisterNUICallback("nui:MediaPlayer:pause", function()
    -- Récupérer le timestamp actuel avant de mettre en pause
    local currentTime = 0
    if lastSoundId and xSound:soundExists(lastSoundId) then
        currentTime = xSound:getTimeStamp(lastSoundId) or 0
    end
    TriggerServerEvent("core:dj:pause", lastSoundId, currentTime)
end)

RegisterNUICallback("nui:MediaPlayer:continue", function()
    -- Le serveur gère le toggle et enverra le timestamp de reprise
    TriggerServerEvent("core:dj:pause", lastSoundId)
end)

RegisterNUICallback("nui:MediaPlayer:volume", function(data)
    TriggerServerEvent("core:dj:volume", lastSoundId, data.volume)
end)

RegisterNUICallback("nui:media-player:close", function()
    open = false
    VFW.Nui.MediaPlayer(false)
end)

---@param soundId any
---@param url any
---@param volume any
---@param coords vector3|table
---@param dist any
RegisterNetEvent("core:dj:play", function(soundId, url, volume, coords, dist)
    -- Détruire l'ancien son de manière asynchrone pour éviter les freezes
    if lastSoundId then
        local oldSoundId = lastSoundId
        if xSound:soundExists(oldSoundId) then
            xSound:setVolume(oldSoundId, 0.0) -- Mute immédiat
            CreateThread(function()
                Wait(200)
                if xSound:soundExists(oldSoundId) then
                    xSound:Destroy(oldSoundId)
                end
            end)
        end
    end

    lastSoundId = soundId

    xSound:PlayUrlPos(soundId, url, volume, coords)
    xSound:Distance(soundId, dist)
    xSound:setVolume(soundId, volume)
    xSound:Position(soundId, coords)
end)

---@param soundId any
RegisterNetEvent("core:dj:stop", function(soundId)
    if xSound:soundExists(soundId) then
        xSound:Destroy(soundId)
        lastSoundId = nil
    end
end)

---@param soundId any
RegisterNetEvent("core:dj:pause", function(soundId)
    if xSound:soundExists(soundId) then
        pause = true
        xSound:Pause(soundId)
    end
end)

---@param soundId any
---@param resumeTime number|nil Timestamp à reprendre (en secondes)
RegisterNetEvent("core:dj:resume", function(soundId, resumeTime)
    if xSound:soundExists(soundId) then
        pause = false
        -- Reprendre au timestamp sauvegardé
        if resumeTime and resumeTime > 0 then
            xSound:setTimeStamp(soundId, resumeTime)
        end
        xSound:Resume(soundId)
    end
end)

---@param soundId any
---@param volume any
RegisterNetEvent("core:dj:volume", function(soundId, volume)
    if xSound:soundExists(soundId) then
        xSound:setVolume(soundId, volume / 100.0)
    end
end)

---@param resourceName string Resource name
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if xSound:soundExists(lastSoundId) then
            xSound:Destroy(lastSoundId)
            lastSoundId = nil
        end
    end
end)

local currentDJs = {}

function Society.initDJ()
    if Society?.data?.custom?.dj then
        local DJs = Society.data.custom.dj

        for k, pos in pairs(DJs) do
            local pos = vector3(pos.x, pos.y, pos.z)

            currentDJs[k] = VFW.CreateBlipAndPoint("society:dj:"..Society.data.name..k, pos + vector3(0.0, 0.0, 1.0), k, 136, 3, 0.5, VFW.PlayerData.job.label .. " - DJ", "DJ", "E", "DJ", {
                onPress = function()
                    OpenMenu()
                end
            })
        end
    end
end

function Society.unloadDJ()
    for k, zone in pairs(currentDJs) do
        if zone then
            Worlds.Zone.Remove(zone)
            Worlds.Blips.Remove(zone)
        end
    end
    currentDJs = {}
end