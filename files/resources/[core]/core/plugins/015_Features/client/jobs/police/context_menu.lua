---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Context Menu Police - Menu dédié pour les jobs police
-- ============================================================

local POLICE_JOBS = PoliceJobsList
local LAW_ENFORCEMENT_JOBS = LawEnforcementJobsList
local ESCORT_JOBS = LawEnforcementJobsList

local function isPoliceJob()
    return VFW.PlayerData and VFW.PlayerData.job and POLICE_JOBS[VFW.PlayerData.job.name]
end

local function isLawEnforcementJob()
    return VFW.PlayerData and VFW.PlayerData.job and LAW_ENFORCEMENT_JOBS[VFW.PlayerData.job.name]
end

local function isOnDuty()
    return VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.onDuty
end

local function canShowPedMenu(ped)
    if not isLawEnforcementJob() or not isOnDuty() then return false end
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return false end
    if ped == PlayerPedId() then return false end
    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if targetId == GetPlayerServerId(PlayerId()) then return false end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
    return dist <= 2.75
end

local function canShowPoliceOnlyPedAction(ped)
    if not isPoliceJob() then return false end
    return canShowPedMenu(ped)
end

local function canShowVehMenu(vehicle)
    if not isPoliceJob() or not isOnDuty() then return false end
    if not DoesEntityExist(vehicle) then return false end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    return dist <= 2.75
end

local function canShowEscortAction(ped)
    if not canShowPedMenu(ped) then return false end
    return ESCORT_JOBS[VFW.PlayerData.job.name] == true
end

-- ============================================================
-- Submenus
-- ============================================================
local pedSubmenu = VFW.ContextAddSubmenu("ped", ":police: Actions Police", canShowPedMenu, { color = { 30, 100, 220 } }, nil, { order = 1 })
local vehSubmenu = VFW.ContextAddSubmenu("vehicle", " Actions Police", canShowVehMenu, { color = { 30, 100, 220 } }, nil, { order = 1 })

-- ============================================================
-- Helpers
-- ============================================================
local function hasItem(itemName)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then return false end
    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.name == itemName and item.count > 0 then return true end
    end
    return false
end

-- ============================================================
-- Boutons Ped
-- ============================================================

local function getPoliceImg()
    return VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png")
end

local function policeNotif(subtitle, content)
    local jobLabel = (VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label) or "SASP"
   VFW.ShowNotification({ type = "JOB", title = jobLabel, subtitle = subtitle, image = getPoliceImg(), content = content })
end
VFW.ContextAddButton("ped", ":id: Vérifier l'identité", function(ped)
    if not canShowPoliceOnlyPedAction(ped) then return false end
    return hasItem("fingerprint_scanner")
end, function(ped)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not targetServerId then return end

    local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", targetServerId)
    if not isCuffed then
        policeNotif("Lecteur d'empreinte", "La personne doit être menottée.")
        return
    end

    SendNUIMessage({
        action = "nui:fingerprintScanner:show",
        data = { targetServerId = targetServerId }
    })
    VFW.Nui.Focus(true, false)
end, {}, pedSubmenu)

VFW.ContextAddButton("ped", ":search: Fouiller", canShowPedMenu, function(ped)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not targetServerId then return end
    TriggerServerEvent("police:search", targetServerId)
end, {}, pedSubmenu)

VFW.ContextAddButton("ped", " Menotter / Démenotter", canShowPedMenu, function(ped)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not targetServerId then return end
    TriggerServerEvent("police:toggleHandcuff", targetServerId)
end, {}, pedSubmenu)

-- ============================================================
-- Amende - Popup NUI
-- ============================================================
local _fineProp = nil
local _fineAnimActive = false

local function startFineAnim()
    if _fineAnimActive then return end
    _fineAnimActive = true

    CreateThread(function()
        local ped = PlayerPedId()
        local dict = "amb@world_human_clipboard@male@idle_a"
       local anim = "idle_c"
       local propModel = `p_amb_clipboard_01`

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
        RequestModel(propModel)
        while not HasModelLoaded(propModel) do Wait(0) end

        if not _fineAnimActive then
            SetModelAsNoLongerNeeded(propModel)
            RemoveAnimDict(dict)
            return
        end

        _fineProp = CreateObject(propModel, 0.0, 0.0, 0.0, false, true, false)
        AttachEntityToEntity(_fineProp, ped, GetPedBoneIndex(ped, 36029), 0.16, 0.08, 0.03, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
        SetModelAsNoLongerNeeded(propModel)
    end)
end

local function stopFineAnim()
    if not _fineAnimActive then return end
    _fineAnimActive = false
    ClearPedTasksImmediately(PlayerPedId())
    if _fineProp and DoesEntityExist(_fineProp) then DeleteObject(_fineProp) end
    _fineProp = nil
end

local function openQuickFine(targetServerId)
    startFineAnim()
    SendNUIMessage({ action = "nui:quickFine:open", data = { targetServerId = targetServerId } })
    VFW.Nui.Focus(true, false)
end

RegisterNUICallback("quickFine:select", function(data, cb)
    cb({})
    VFW.Nui.Focus(false, false)
    stopFineAnim()
    if data.targetServerId and data.fineId then
        TriggerServerEvent("police:createFineFromMenu", data.targetServerId, data.fineId)
    end
end)

RegisterNUICallback("quickFine:close", function(_, cb)
    cb({})
    VFW.Nui.Focus(false, false)
    stopFineAnim()
end)

VFW.ContextAddButton("ped", ":money: Mettre une amende", canShowPoliceOnlyPedAction, function(ped)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not targetServerId then return end
    openQuickFine(targetServerId)
end, {}, pedSubmenu)

-- Event pour ouvrir le menu amende depuis un autre script (menu métier etc.)
AddEventHandler("police:openFineMenu", function(targetServerId)
    openQuickFine(targetServerId)
end)

VFW.ContextAddButton("ped", " Escorter", canShowEscortAction, function(ped)
    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    TriggerServerEvent("police:escort", serverId)
end, {}, pedSubmenu)

VFW.ContextAddButton("ped", ":car: Mettre dans le véhicule", function(ped)
    if not canShowPedMenu(ped) then return false end
    if not ESCORT_JOBS[VFW.PlayerData.job.name] then return false end
    return IsEntityAttachedToEntity(ped, PlayerPedId())
end, function(ped)
    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not serverId then return end
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, 0, 71)
    end
    if not vehicle or vehicle == 0 then
        VFW.ShowNotification({ type = "ROUGE", content = "Aucun véhicule à proximité." })
        return
    end
    local netId = VehToNet(vehicle)
    TriggerServerEvent("police:putInVehicle", serverId, netId)
end, {}, pedSubmenu)

-- ============================================================
-- Bouton Relâcher l'escorte (sur soi-même)
-- ============================================================
local function isSelfPed(ped)
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return false end
    return GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)) == GetPlayerServerId(PlayerId())
end

local function canShowEscortRelease(ped)
    if not isLawEnforcementJob() or not isOnDuty() then return false end
    if not ESCORT_JOBS[VFW.PlayerData.job.name] then return false end
    if not isSelfPed(ped) then return false end
    return TriggerServerCallback("police:isEscortingSomeone")
end

VFW.ContextAddButton("ped", " Relâcher l'escorte", canShowEscortRelease, function()
    TriggerServerEvent("police:stopEscort")
end)

-- ============================================================
-- Boutons Véhicule
-- ============================================================
VFW.ContextAddButton("vehicle", ":unlock: Crocheter", canShowVehMenu, function(vehicle)
    VFW.Jobs.HookVehicle(vehicle)
end, {}, vehSubmenu)

VFW.ContextAddButton("vehicle", ":search: Inspecter", canShowVehMenu, function(vehicle)
    local plate = VFW.Game.GetPlate(vehicle)
    VFW.Nui.policePanel(true)
    SendNUIMessage({ action = "nui:PolicePanel:searchPlate", data = plate or "" })
end, {}, vehSubmenu)



VFW.ContextAddButton("vehicle", ":wrench: Retirer le sabot", function(vehicle)
    if not canShowVehMenu(vehicle) then return false end
    return Entity(vehicle).state.hasBoot == true
end, function(vehicle)
    VehicleUnbootAction(vehicle)
end, {}, vehSubmenu)

VFW.ContextAddButton("vehicle", ":car: Fourrière", canShowVehMenu, function(vehicle)
    VFW.Jobs.SetVehicleInFourriere(vehicle)
end, { color = { 220, 60, 60 } }, vehSubmenu)
