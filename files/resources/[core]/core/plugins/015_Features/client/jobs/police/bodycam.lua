---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- POLICE BODYCAM SYSTEM
-- Alt+click on self → start/stop recording (2 min max)
-- Captures real video via GameRender + MediaRecorder (NUI)
-- View recording via carte_memoire_bodycam item
-- ============================================================

local POLICE_JOBS = PoliceJobsList
local MAX_DURATION = 120 -- 2 minutes en secondes
local UPLOAD_RATE = 500000 -- 500KB/s pour TriggerLatentServerEvent

local isRecording = false
local recordingStartTime = 0
local recordingThread = false
local pendingVideoData = nil
local bodycamProp = nil
local viewerOpen = false

local BODYCAM_MODEL = GetHashKey("sn_bodycam")
local BODYCAM_BONE = 0x60F2
local BODYCAM_OFFSET = { x = 0.081, y = 0.161, z = -0.003 }
local BODYCAM_ROT = { x = 3.255, y = -91.805, z = 175.182 }
local BODYCAM_ANIM_DICT = "clothingtie"
local BODYCAM_ANIM_NAME = "try_tie_positive_a"

-- ============================================================
-- HELPER
-- ============================================================

local function isPoliceOnDuty()
    local job = VFW.PlayerData.job
    return job and job.onDuty and POLICE_JOBS[job.name]
end

local function getOfficerName()
    if VFW.PlayerData and VFW.PlayerData.firstName and VFW.PlayerData.lastName then
        return VFW.PlayerData.firstName .. " " .. VFW.PlayerData.lastName
    end
    return "Officier"
end

local function formatTimer(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

-- ============================================================
-- PROP ATTACHMENT
-- ============================================================

local function attachBodycamProp()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    RequestModel(BODYCAM_MODEL)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(BODYCAM_MODEL) do
        Wait(10)
        if GetGameTimer() > timeout then return end
    end

    RequestAnimDict(BODYCAM_ANIM_DICT)
    while not HasAnimDictLoaded(BODYCAM_ANIM_DICT) do Wait(10) end
    TaskPlayAnim(ped, BODYCAM_ANIM_DICT, BODYCAM_ANIM_NAME, 8.0, -8.0, 2000, 49, 0, false, false, false)
    Wait(800)

    local prop = CreateObject(BODYCAM_MODEL, coords.x, coords.y, coords.z, false, true, false)
    if not prop or prop == 0 or not DoesEntityExist(prop) then
        SetModelAsNoLongerNeeded(BODYCAM_MODEL)
        return
    end

    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, BODYCAM_BONE),
        BODYCAM_OFFSET.x, BODYCAM_OFFSET.y, BODYCAM_OFFSET.z,
        BODYCAM_ROT.x, BODYCAM_ROT.y, BODYCAM_ROT.z,
        true, true, false, true, 0, true
    )
    bodycamProp = prop

    SetModelAsNoLongerNeeded(BODYCAM_MODEL)
    RemoveAnimDict(BODYCAM_ANIM_DICT)
end

local function detachBodycamProp()
    if bodycamProp and DoesEntityExist(bodycamProp) then
        local ped = PlayerPedId()

        RequestAnimDict(BODYCAM_ANIM_DICT)
        while not HasAnimDictLoaded(BODYCAM_ANIM_DICT) do Wait(10) end
        TaskPlayAnim(ped, BODYCAM_ANIM_DICT, BODYCAM_ANIM_NAME, 8.0, -8.0, 2000, 49, 0, false, false, false)
        Wait(800)

        DetachEntity(bodycamProp, true, true)
        DeleteEntity(bodycamProp)
        bodycamProp = nil

        RemoveAnimDict(BODYCAM_ANIM_DICT)
    end
end

-- ============================================================
-- START / STOP RECORDING
-- ============================================================

local function startRecording()
    if isRecording then return end
    if not isPoliceOnDuty() then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous devez être en service" })
        return
    end

    isRecording = true
    recordingStartTime = GetGameTimer()
    pendingVideoData = nil

    attachBodycamProp()

    -- Cacher le HUD pendant l'enregistrement
    DisplayRadar(false)
    if VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(false)
    end

    SendNUIMessage({ action = "bodycam:startRecording", data = true })

    VFW.ShowNotification({ type = 'VERT', content = "Enregistrement démarré" })

    if not recordingThread then
        recordingThread = true
        CreateThread(function()
            while isRecording do
                Wait(1000)
                local elapsed = (GetGameTimer() - recordingStartTime) / 1000
                if elapsed >= MAX_DURATION then
                    stopRecording()
                end
            end
            recordingThread = false
        end)
    end
end

function stopRecording()
    if not isRecording then return end
    isRecording = false

    local elapsed = math.floor((GetGameTimer() - recordingStartTime) / 1000)

    -- IMPORTANT: set pendingVideoData AVANT tout Wait() sinon le NUI callback arrive trop tôt
    pendingVideoData = { duration = elapsed }

    SendNUIMessage({ action = "bodycam:stopRecording", data = true })

    -- Remettre le HUD
    DisplayRadar(true)
    if VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(true)
    end

    VFW.ShowNotification({ type = 'VERT', content = "Enregistrement terminé, veuillez patienter..." })

    -- Animation de retrait après (ne bloque pas le callback NUI)
    detachBodycamProp()
end

RegisterNuiCallback("bodycam:videoReady", function(data, cb)
    cb("ok")
    if not pendingVideoData then return end
    if not data or not data.video or data.video == "" then return end

    TriggerLatentServerEvent("police:bodycam:save", UPLOAD_RATE, {
        duration = pendingVideoData.duration,
        video = data.video,
    })

    pendingVideoData = nil
end)

-- ============================================================
-- HUD OVERLAY (NUI)
-- ============================================================

CreateThread(function()
    while true do
        if isRecording then
            SendNUIMessage({
                action = "bodycam:hudUpdate",
                data = { visible = true }
            })
            Wait(1000)
        else
            SendNUIMessage({
                action = "bodycam:hudUpdate",
                data = { visible = false }
            })
            Wait(1000)
        end
    end
end)

-- ============================================================
-- CONTEXT MENU (record only)
-- ============================================================

local function isSelfPed(ped)
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return false end
    local playerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    return playerId == GetPlayerServerId(PlayerId())
end

local function canShowSelfPoliceMenu(ped)
    if not isPoliceOnDuty() then return false end
    return isSelfPed(ped)
end

local selfSubmenu = VFW.ContextAddSubmenu("ped", ":police: Actions Police", canShowSelfPoliceMenu, { color = { 30, 100, 220 } }, nil, { order = 2 })

VFW.ContextAddButton("ped", ":film: Activer la bodycam", function(ped)
    if not canShowSelfPoliceMenu(ped) then return false end
    return not isRecording
end, function()
    startRecording()
end, {}, selfSubmenu)

VFW.ContextAddButton("ped", ":film: Arrêter la bodycam", function(ped)
    if not canShowSelfPoliceMenu(ped) then return false end
    return isRecording
end, function()
    stopRecording()
end, { color = { 220, 60, 60 } }, selfSubmenu)

-- ---- Backup requests ----
local cachedMatricule = nil

local function refreshMatricule()
    local data = TriggerServerCallback("police:units:getData")
    if data and data.matricule then
        cachedMatricule = data.matricule
    end
end

local function requestBackup(level)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
    local location = crossing and (street .. " / " .. crossing) or street

    if not cachedMatricule then refreshMatricule() end

    local desc = "Demande envoyée par l'agent"
   if cachedMatricule then
        desc = desc .. " (Matricule " .. tostring(cachedMatricule) .. ")"
   end

    local levelNames = { "routine", "priority", "critical" }
    local levelTitles = { "Backup niveau 1", "Backup niveau 2", "Backup niveau 3 - URGENT" }

    TriggerServerEvent("dispatch:server:requestBackup", level)
    TriggerServerEvent("police:dispatch:create", {
        level = levelNames[level] or "routine",
        title = levelTitles[level] or "Demande de backup",
        description = desc,
        location = location,
        x = coords.x,
        y = coords.y,
        z = coords.z,
    })
end

VFW.ContextAddButton("ped", ":dot-green: Backup niveau 1", canShowSelfPoliceMenu, function()
    requestBackup(1)
end, {}, selfSubmenu)

VFW.ContextAddButton("ped", ":dot-orange: Backup niveau 2", canShowSelfPoliceMenu, function()
    requestBackup(2)
end, {}, selfSubmenu)

VFW.ContextAddButton("ped", ":dot-red: Backup niveau 3", canShowSelfPoliceMenu, function()
    requestBackup(3)
end, { color = { 220, 60, 60 } }, selfSubmenu)

-- ============================================================
-- VIEWER (NUI) — only via item
-- ============================================================

local function closeBodycamViewer()
    if not viewerOpen then return end
    viewerOpen = false
    SendNUIMessage({ action = "nui:BodycamViewer:visible", data = false })
    VFW.Nui.Focus(false)

    CreateThread(function()
        local endTime = GetGameTimer() + 500
        while GetGameTimer() < endTime do
            DisableControlAction(0, 24, true)   -- INPUT_ATTACK
            DisableControlAction(0, 25, true)   -- INPUT_AIM
            DisableControlAction(0, 257, true)  -- INPUT_ATTACK2
            Wait(0)
        end
    end)
end

RegisterNuiCallback("bodycam:close", function(_, cb)
    closeBodycamViewer()
    cb("ok")
end)

RegisterNuiCallback("bodycam:getRecording", function(data, cb)
    local id = tonumber(data.id)
    if not id then cb(nil) return end
    local recording = TriggerServerCallback("police:bodycam:getRecording", id)
    cb(recording)
end)

-- Item use → open viewer
RegisterNetEvent("police:bodycam:viewFromItem", function(metadata)
    if not metadata or not metadata.recordingId then return end

    VFW.CloseInventory()
    viewerOpen = true

    CreateThread(function()
        while viewerOpen do
            DisableAllControlActions(0)
            Wait(0)
        end
    end)

    SendNUIMessage({
        action = "nui:BodycamViewer:openRecording",
        data = {
            recordingId = metadata.recordingId,
            officerName = metadata.officerName,
            duration = metadata.duration,
            date = metadata.date,
        }
    })
    VFW.Nui.Focus(true)
end)

-- ============================================================
-- SERVER RESPONSE
-- ============================================================

RegisterNetEvent("police:bodycam:saved", function(recordingId)
    VFW.ShowNotification({ type = 'VERT', content = "Enregistrement sauvegardé" })
end)

-- ============================================================
-- CLEANUP
-- ============================================================

RegisterNetEvent("vfw:setJob", function()
    if isRecording and not isPoliceOnDuty() then
        stopRecording()
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isRecording then
        isRecording = false
        SendNUIMessage({ action = "bodycam:stopRecording", data = true })
    end
    if bodycamProp and DoesEntityExist(bodycamProp) then
        DetachEntity(bodycamProp, true, true)
        DeleteEntity(bodycamProp)
        bodycamProp = nil
    end
    if viewerOpen then
        viewerOpen = false
        VFW.Nui.Focus(false)
    end
end)
