---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Context Menu USSS - Actions citoyen et véhicule
-- Mêmes actions que police sans bracelet, emprisonner, test poudre, sabot
-- ============================================================

local function isUSSSJob()
    return VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name
        and string.lower(VFW.PlayerData.job.name):find("usss")
end

local function isOnDuty()
    return VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.onDuty
end

local function canShowPedMenu(ped)
    if not isUSSSJob() or not isOnDuty() then return false end
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return false end
    if ped == PlayerPedId() then return false end
    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if targetId == GetPlayerServerId(PlayerId()) then return false end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
    return dist <= 2.75
end

local function canShowVehMenu(vehicle)
    if not isUSSSJob() or not isOnDuty() then return false end
    if not DoesEntityExist(vehicle) then return false end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    return dist <= 2.75
end

local function canShowEscortAction(ped)
    return canShowPedMenu(ped)
end

-- ============================================================
-- Submenus
-- ============================================================
local pedSubmenu = VFW.ContextAddSubmenu("ped", ":shield: Actions USSS", canShowPedMenu, { color = { 139, 92, 246 } }, nil, { order = 2 })
local vehSubmenu = VFW.ContextAddSubmenu("vehicle", ":shield: Actions USSS", canShowVehMenu, { color = { 139, 92, 246 } }, nil, { order = 2 })

-- ============================================================
-- Helpers
-- ============================================================
local function getUSSSImg()
    return VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "usss") .. ".png")
end

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

VFW.ContextAddButton("ped", ":id: Vérifier l'identité", function(ped)
    if not canShowPedMenu(ped) then return false end
    return hasItem("fingerprint_scanner")
end, function(ped)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not targetServerId then return end
    local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", targetServerId)
    if not isCuffed then
        VFW.ShowNotification({ type = "JOB", title = "USSS", subtitle = "Lecteur d'empreinte", image = getUSSSImg(), content = "La personne doit être menottée." })
        return
    end
    SendNUIMessage({ action = "nui:fingerprintScanner:show", data = { targetServerId = targetServerId } })
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


VFW.ContextAddButton("ped", " Escorter", canShowEscortAction, function(ped)
    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    TriggerServerEvent("police:escort", serverId)
end, {}, pedSubmenu)

VFW.ContextAddButton("ped", ":car: Mettre dans le véhicule", function(ped)
    if not canShowPedMenu(ped) then return false end
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
-- Boutons Véhicule (sans sabot)
-- ============================================================

VFW.ContextAddButton("vehicle", ":unlock: Crocheter", canShowVehMenu, function(vehicle)
    VFW.Jobs.HookVehicle(vehicle)
end, {}, vehSubmenu)

VFW.ContextAddButton("vehicle", ":car: Fourrière", canShowVehMenu, function(vehicle)
    VFW.Jobs.SetVehicleInFourriere(vehicle)
end, { color = { 220, 60, 60 } }, vehSubmenu)

-- ============================================================
-- Self Actions USSS (backup requests, no bodycam)
-- ============================================================

local function isSelfPed(ped)
    if not DoesEntityExist(ped) or not IsPedAPlayer(ped) then return false end
    local playerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    return playerId == GetPlayerServerId(PlayerId())
end

local function canShowSelfUSSSMenu(ped)
    if not isUSSSJob() or not isOnDuty() then return false end
    return isSelfPed(ped)
end

local selfSubmenu = VFW.ContextAddSubmenu("ped", ":shield: Actions USSS", canShowSelfUSSSMenu, { color = { 139, 92, 246 } }, nil, { order = 2 })

-- Backup requests (USSS dispatch only)
local cachedMatricule = nil

local function refreshMatricule()
    local data = TriggerServerCallback("usss:units:getData")
    if data and data.matricule then
        cachedMatricule = data.matricule
    end
end

local function requestUSSSBackup(level)
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

    TriggerServerEvent("usss:dispatch:create", {
        level = levelNames[level] or "routine",
        title = levelTitles[level] or "Demande de backup",
        description = desc,
        location = location,
        x = coords.x,
        y = coords.y,
        z = coords.z,
    })
end

VFW.ContextAddButton("ped", ":dot-green: Backup niveau 1", canShowSelfUSSSMenu, function()
    requestUSSSBackup(1)
end, {}, selfSubmenu)

VFW.ContextAddButton("ped", ":dot-orange: Backup niveau 2", canShowSelfUSSSMenu, function()
    requestUSSSBackup(2)
end, {}, selfSubmenu)

VFW.ContextAddButton("ped", ":dot-red: Backup niveau 3", canShowSelfUSSSMenu, function()
    requestUSSSBackup(3)
end, { color = { 220, 60, 60 } }, selfSubmenu)
