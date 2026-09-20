---@meta _
---@diagnostic disable: duplicate-doc-field

--region ------ Helper Functions

local function IsInStaffMode()
    for _, staffId in ipairs(VFW.staffMode or {}) do
        if staffId == GetPlayerServerId(PlayerId()) then
            return true
        end
    end
    return false
end

local function HasStaffPermission(permission)
    return IsInStaffMode() and VFW.HasStaffPerm and VFW.HasStaffPerm(permission)
end

local function PlayerHasVehicleKeys(vehicle)
    if not VFW.PlayerData.inventory then return false end
    local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
    for i = 1, #VFW.PlayerData.inventory do
        local item = VFW.PlayerData.inventory[i]
        if item.name == "keys" and item.meta and item.meta.plate == plate then
            return true
        end
    end
    return false
end

local function IsDriver(vehicle)
    local ped = VFW.PlayerData.ped
    return GetPedInVehicleSeat(vehicle, -1) == ped
end

local function vehicleModelLabel(veh)
    local hash = GetEntityModel(veh)
    local dn = GetDisplayNameFromVehicleModel(hash)
    if not dn then return tostring(hash) end
    local lbl = GetLabelText(dn)
    -- GetLabelText retourne "NULL" pour les vehicules importes (add-on)
    if lbl == "NULL" then return dn end
    return lbl
end

--endregion

--region ------ Constants

local SEAT_LABELS = {
    [-1] = "Conducteur",
    [0] = "Avant droit",
    [1] = "Arrière gauche",
    [2] = "Arrière droit",
    [3] = "Arrière centre",
    [4] = "Siège 4",
    [5] = "Siège 5",
    [6] = "Siège 6",
}

local function listUsableSeats(veh)
    local seats = {}
    local maxPassengers = GetVehicleMaxNumberOfPassengers(veh)
    for i = -1, math.max(3, maxPassengers) do
        if DoesEntityExist(veh) then
            local label = SEAT_LABELS[i] or ("Siège " .. tostring(i))
            seats[#seats + 1] = { idx = i, label = label }
        end
    end
    return seats
end

--endregion

--region ------ Main Submenus

-- Staff principal
local staffSubmenu = VFW.ContextAddSubmenu("vehicle", ":police: Action Staff", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, { color = { 255, 64, 64 } }, nil)
VFW.ContextBindScope(staffSubmenu, "vehicle:staff_info")

-- Développeurs (séparé)
local DevSubmenu = VFW.ContextAddSubmenu("vehicle", ":wrench: Action Développeurs", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("devcontextmenu")
end, { color = { 0, 162, 255 } }, nil)

--endregion

--region ------ 1. Infos & Joueurs

local infoJoueursSubmenu = VFW.ContextAddSubmenu("vehicle", ":chart: Infos & Joueurs", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, {}, staffSubmenu)
VFW.ContextBindScope(infoJoueursSubmenu, "vehicle:staff_info")

VFW.ContextAddInfo("vehicle", "Modèle", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle)
    return vehicleModelLabel(vehicle)
end, {}, infoJoueursSubmenu, { useScope = true })

VFW.ContextAddInfo("vehicle", "Nom technique", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle)
    local hash = GetEntityModel(vehicle)
    local dn = GetDisplayNameFromVehicleModel(hash)
    return (dn and dn ~= "" and dn) or tostring(hash)
end, {}, infoJoueursSubmenu, { useScope = true })

VFW.ContextAddInfo("vehicle", "Plaque", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle, scope)
    return (scope and scope.plate) or VFW.Math.Trim(GetVehicleNumberPlateText(vehicle)) or "Inconnue"
end, {}, infoJoueursSubmenu, { useScope = true })

VFW.ContextAddInfo("vehicle", "Propriétaire", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle, scope)
    return (scope and (scope.ownerName or ("#" .. tostring(scope.ownerId or "???")))) or "Inconnu"
end, {}, infoJoueursSubmenu, { useScope = true })

VFW.ContextAddInfo("vehicle", "ID Entité", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle)
    return tostring(vehicle)
end, {}, infoJoueursSubmenu, { useScope = true })

VFW.ContextAddInfo("vehicle", "Essence", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle)
    local fuelLevel = VehicleFuel and VehicleFuel.Get(vehicle) or GetVehicleFuelLevel(vehicle)
    local tankCapacity = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")
    local fuelLiters = (fuelLevel / 100.0) * tankCapacity
    return string.format("%.1f%% (%.1fL / %.0fL)", fuelLevel, fuelLiters, tankCapacity)
end, {}, infoJoueursSubmenu, { useScope = true })

--endregion

--region ------ 2. Gestion du véhicule

local vehMgmtStaff = VFW.ContextAddSubmenu("vehicle", ":car: Gestion du véhicule", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, {}, staffSubmenu)

-- 1. Sous-menu Fenêtres
local winSubStaff = VFW.ContextAddSubmenu("vehicle", ":home: Fenêtres", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, {}, vehMgmtStaff)

local winActions = {
    { label = "↓ Ouvrir toutes", action = "vehicle:windowsOpenAll" },
    { label = "↑ Fermer toutes", action = "vehicle:windowsCloseAll" },
}

for _, w in ipairs(winActions) do
    VFW.ContextAddButton("vehicle", w.label, function(vehicle)
        return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
    end, nil, {}, winSubStaff, { serverAction = w.action, permission = "alt_vehicle_management" })
end

-- 2. Sous-menu Portières/Coffre (dans Gestion du véhicule)
local doorsSubStaff = VFW.ContextAddSubmenu("vehicle", ":door: Portières/Coffre", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, {}, vehMgmtStaff)

-- Liste des portières
local DOORS = {
    { idx = 0, label = ":door: Avant gauche" },
    { idx = 1, label = ":door: Avant droit" },
    { idx = 2, label = ":door: Arrière gauche" },
    { idx = 3, label = ":door: Arrière droit" },
    { idx = 4, label = ":wrench: Capot" },
    { idx = 5, label = ":box: Coffre" },
}

local DOOR_BONES = {
    [0] = "door_dside_f",
    [1] = "door_pside_f",
    [2] = "door_dside_r",
    [3] = "door_pside_r",
    [4] = "bonnet",
    [5] = "boot",
}

local function doorExists(vehicle, doorIdx)
    local boneName = DOOR_BONES[doorIdx]
    if not boneName then return false end
    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    return boneIndex ~= -1
end

for _, d in ipairs(DOORS) do
    VFW.ContextAddButton("vehicle", d.label, function(vehicle)
        return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management") and doorExists(vehicle, d.idx)
    end, nil, {}, doorsSubStaff, { serverAction = "vehicle:doorToggle", useScope = false, order = d.idx, extra = { door = d.idx }, permission = "alt_vehicle_management" })
end

local doorBulkActions = {
    { label = ":unlock: Tout ouvrir", action = "vehicle:doorsOpenAll" },
    { label = ":lock: Tout fermer", action = "vehicle:doorsCloseAll" },
    { label = ":box: Ouvrir/Fermer coffre", action = "vehicle:trunkToggle" },
}

for _, da in ipairs(doorBulkActions) do
    VFW.ContextAddButton("vehicle", da.label, function(vehicle)
        return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
    end, nil, {}, doorsSubStaff, { serverAction = da.action, permission = "alt_vehicle_management" })
end

-- 3. Actions rapides (boutons)
VFW.ContextAddButton("vehicle", ":key: Allumer/Éteindre moteur", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:engineToggle", permission = "alt_vehicle_management" })

-- 4. Verrouiller/Déverrouiller (avec notification) - Staff
VFW.ContextAddButton("vehicle", ":lock: Verrouiller/Déverrouiller", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, function(vehicle)
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local result = TriggerServerCallback("vfw:action:run", {
        action = "vehicle:lockToggle",
        ent = { netId = netId, entType = 2 },
        permission = "alt_vehicle_management"
  })

    if result and result.ok then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Gestion Véhicules',
            message = result.msg .. "."
      })
    elseif result and result.err then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
            message = "Erreur: " .. result.err .. "."
      })
    end
end, {}, vehMgmtStaff)

-- 5. Immobiliser (staff only)
VFW.ContextAddButton("vehicle", ":ban: Immobiliser / Libérer", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:immobilizeToggle", permission = "alt_vehicle_management" })

-- 5. Retourner 180° (staff only)
VFW.ContextAddButton("vehicle", ":refresh: Retourner 180°", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:flip180", permission = "alt_vehicle_management" })

-- 6. Retirer les roues (staff only)
VFW.ContextAddButton("vehicle", ":car: Retirer les roues", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("devcontextmenu")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:removeWheels", permission = "devcontextmenu" })

-- 6. Détruire le moteur (staff only)
VFW.ContextAddButton("vehicle", " Détruire le moteur", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("devcontextmenu")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:destroyEngine", permission = "devcontextmenu" })

-- 7. Mettre un savon (staff only)
VFW.ContextAddButton("vehicle", " Mettre un savon", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("devcontextmenu")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:soap", permission = "devcontextmenu" })

-- 8. Mettre le plein (staff only)
VFW.ContextAddButton("vehicle", ":car: Mettre le plein", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_repair_vehicle")
end, nil, {}, vehMgmtStaff, { serverAction = "vehicle:refuel", permission = "alt_repair_vehicle" })

--endregion

--region ------ 3. Inventaire

local inventaireSubmenu = VFW.ContextAddSubmenu("vehicle", ":box: Inventaire", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, {}, staffSubmenu)

VFW.ContextAddButton("vehicle", ":eye: Voir le coffre", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, function(vehicle)
    local isLocked = GetVehicleDoorLockStatus(vehicle) > 1
    if isLocked then
        TriggerServerEvent('vfw:staff:openLockedTrunk', VehToNet(vehicle))
    end
    if VFW.OpenTrunk then
        local OwnedVehicle = Entity(vehicle).state.OwnedVehicle
        local plate = GetVehicleNumberPlateText(vehicle)
        VFW.OpenTrunk(OwnedVehicle, plate, VehToNet(vehicle))
    else
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = "Fonction OpenTrunk non disponible." })
    end
end, {}, inventaireSubmenu)

VFW.ContextAddButton("vehicle", " Accéder au coffre", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_management")
end, function(vehicle)
    if VFW.OpenTrunkStaff then
        local plate = GetVehicleNumberPlateText(vehicle)
        VFW.OpenTrunkStaff(plate, VehToNet(vehicle))
    else
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = "Fonction OpenTrunkStaff non disponible." })
    end
end, {}, inventaireSubmenu)

--endregion

--region ------ 4. Gestion des clés

-- Sous-menu Gestion des clés (dans Actions Développeurs)
local keysSubmenu = VFW.ContextAddSubmenu("vehicle", ":key: Gestion des clés", function(vehicle)
    return DoesEntityExist(vehicle) and (
        HasStaffPermission("vehicle_keys_permanent") or
        HasStaffPermission("vehicle_keys_temp") or
        HasStaffPermission("alt_give_vehicle")
    )
end, {}, DevSubmenu)

-- Clés temporaires (disparaissent au reboot)
VFW.ContextAddButton("vehicle", ":key: Clés temporaires (reboot)", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("vehicle_keys_temp")
end, function(vehicle)
    VFW.CloseContextMenu()
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    local result = TriggerServerCallback("vfw:action:run", {
        action = "vehicle:getKeysTemp",
        ent = { netId = netId, entType = 2 },
        permission = "vehicle_keys_temp"
  })

    if result and result.ok then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
            message = (result.msg or "Clés temporaires obtenues") .. "."
      })
    elseif result and result.err then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
            message = "Erreur: " .. result.err .. "."
      })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
            message = "Erreur inconnue."
      })
    end
end, {}, keysSubmenu)

-- Clés permanentes (persistent)
VFW.ContextAddButton("vehicle", ":key: Clés permanentes", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("vehicle_keys_permanent")
end, function(vehicle)
    VFW.CloseContextMenu()
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    local result = TriggerServerCallback("vfw:action:run", {
        action = "vehicle:getKeys",
        ent = { netId = netId, entType = 2 },
        permission = "vehicle_keys_permanent"
  })

    if result and result.ok then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
            message = (result.msg or "Clés obtenues") .. "."
      })
    elseif result and result.err then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
            message = "Erreur: " .. result.err .. "."
      })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
            message = "Erreur inconnue."
      })
    end
end, {}, keysSubmenu)

-- Donner le véhicule (transférer propriété)
VFW.ContextAddButton("vehicle", ":gift: Donner le véhicule", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_give_vehicle")
end, function(vehicle)
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local targetId = VFW.Nui.KeyboardInput(true, "ID du joueur à qui donner", "", 10)

        if targetId == nil or targetId == "" or targetId == "KBD_CANCEL" then
            return
        end

        if not tonumber(targetId) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = "Cet identifiant n'est pas valide." })
            return
        end

        local props = VFW.Game.GetVehicleProperties(vehicle)

        local result = TriggerServerCallback("vfw:action:run", {
            action = "vehicle:give",
            ent = { netId = netId, entType = 2 },
            extra = { targetId = tonumber(targetId), props = props }
        })

        if result and result.ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules', message = (result.msg or "Véhicule transféré") .. "." })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = (result and result.err or "Erreur lors du transfert") .. "." })
        end
    end)
end, {}, keysSubmenu)

--endregion

--region ------ 5. Modifications

local modificationsSubmenu = VFW.ContextAddSubmenu("vehicle", ":wrench: Modifications", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("contextmenu")
end, {}, staffSubmenu)

VFW.ContextAddButton("vehicle", ":wrench: Réparer", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_repair_vehicle")
end, nil, {}, modificationsSubmenu, { serverAction = "vehicle:repair", permission = "alt_repair_vehicle" })

VFW.ContextAddButton("vehicle", ":trash: Nettoyer", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_repair_vehicle")
end, nil, {}, modificationsSubmenu, { serverAction = "vehicle:clean", permission = "alt_repair_vehicle" })

VFW.ContextAddButton("vehicle", ":rocket: Full Perf (temporaire)", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_custom_vehicle")
end, function(vehicle)
    -- Mettre le véhicule en full performance max
    NetworkRequestControlOfEntity(vehicle)

    -- Toutes les modifications de performance au max
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Engine
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Brakes
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmission
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false) -- Suspension
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false) -- Armor
    ToggleVehicleMod(vehicle, 17, true) -- Turbo
    ToggleVehicleMod(vehicle, 18, true) -- Xenon
    ToggleVehicleMod(vehicle, 22, true) -- Xenon Headlights

    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules', message = "Véhicule en Full Performance (temporaire)." })
end, {}, modificationsSubmenu)

-- Sous-menu couleurs
local colorsSubmenu = VFW.ContextAddSubmenu("vehicle", ":palette: Couleur (temporaire)", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_custom_vehicle")
end, {}, modificationsSubmenu)

local VEHICLE_COLORS = {
    { label = ":dot-grey: Noir", primary = 0 },
    { label = ":dot-grey: Blanc", primary = 111 },
    { label = ":dot-red: Rouge", primary = 27 },
    { label = ":dot-blue: Bleu", primary = 64 },
    { label = ":dot-green: Vert", primary = 55 },
    { label = ":dot-yellow: Jaune", primary = 88 },
    { label = ":dot-orange: Orange", primary = 38 },
    { label = ":dot-grey: Violet", primary = 71 },
    { label = " Rose", primary = 135 },
    { label = " Gris", primary = 7 },
    { label = ":trophy: Argent", primary = 4 },
    { label = ":trophy: Or", primary = 37 },
    { label = " Bleu ciel", primary = 87 },
    { label = ":dot-green: Vert citron", primary = 92 },
    { label = ":heart: Rouge mat", primary = 39 },
    { label = ":heart: Bleu mat", primary = 83 },
}

for _, color in ipairs(VEHICLE_COLORS) do
    VFW.ContextAddButton("vehicle", color.label, function(vehicle)
        return DoesEntityExist(vehicle) and HasStaffPermission("alt_custom_vehicle")
    end, function(vehicle)
        NetworkRequestControlOfEntity(vehicle)
        local timeout = 0
        while not NetworkHasControlOfEntity(vehicle) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end

        if NetworkHasControlOfEntity(vehicle) then
            SetVehicleColours(vehicle, color.primary, color.primary)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules', message = "Couleur appliquée: " .. color.label .. "." })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = "Impossible de modifier le véhicule." })
        end
    end, {}, colorsSubmenu)
end

--endregion

--region ------ 6. Cacher

local hideSubmenu = VFW.ContextAddSubmenu("vehicle", ":eye: Cacher", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_hide")
end, {}, staffSubmenu)

VFW.ContextAddButton("vehicle", ":eye: Rendre invisible", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_hide")
end, nil, {}, hideSubmenu, { serverAction = "vehicle:setAlpha", extra = { alpha = 0 }, permission = "alt_vehicle_hide" })

VFW.ContextAddButton("vehicle", ":eye::chat: Semi-transparent", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_hide")
end, nil, {}, hideSubmenu, { serverAction = "vehicle:setAlpha", extra = { alpha = 128 }, permission = "alt_vehicle_hide" })

VFW.ContextAddButton("vehicle", ":check: Rendre visible", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_vehicle_hide")
end, nil, {}, hideSubmenu, { serverAction = "vehicle:setAlpha", extra = { alpha = 255 }, permission = "alt_vehicle_hide" })

--endregion

--region ------ 7. Actions rapides (Staff root)

VFW.ContextAddButton("vehicle", ":trash: Supprimer l'entité", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_delete_entity")
end, nil, {}, staffSubmenu, { serverAction = "vehicle:delete", permission = "alt_delete_entity" })

--endregion

--region ------ 8. Gestion Véhicule (occupants)

local function isInThisVehicle(vehicle)
    local ped = VFW.PlayerData.ped or PlayerPedId()
    if not DoesEntityExist(ped) or not IsPedInAnyVehicle(ped, false) then return false end
    return GetVehiclePedIsIn(ped, false) == vehicle
end

local function canManageOccupantVehicle(vehicle)
    return DoesEntityExist(vehicle) and isInThisVehicle(vehicle)
end

-- Cache "le joueur a-t-il les clés du véhicule courant ?" (interroge le serveur quand la plaque change)
local currentVehiclePlate = nil
local hasKeysForCurrentPlate = false

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(500) end
    while true do
        Wait(1000)
        local ped = VFW.PlayerData.ped or PlayerPedId()
        local plate = nil
        if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(veh) then
                plate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
            end
        end
        if plate ~= currentVehiclePlate then
            currentVehiclePlate = plate
            hasKeysForCurrentPlate = false
            if plate then
                local result = TriggerServerCallback("vfw:context:hasVehicleKey", plate)
                if plate == currentVehiclePlate then
                    hasKeysForCurrentPlate = result == true
                end
            end
        end
    end
end)

local function canLockVehicle(vehicle)
    if not canManageOccupantVehicle(vehicle) then return false end
    return hasKeysForCurrentPlate or HasStaffPermission("alt_vehicle_management")
end

local occupantVehMgmt = VFW.ContextAddSubmenu("vehicle", ":car: Gestion Véhicule", function(vehicle)
    return canManageOccupantVehicle(vehicle)
end, {}, nil)

-- Moteur (label dynamique : Allumer si éteint, Éteindre si allumé)
VFW.ContextAddButton("vehicle", ":fire: Éteindre le moteur", function(vehicle)
    return canManageOccupantVehicle(vehicle) and GetIsVehicleEngineRunning(vehicle)
end, function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    SetVehicleEngineOn(vehicle, false, true, true)
end, {}, occupantVehMgmt)

VFW.ContextAddButton("vehicle", ":sparkles: Allumer le moteur", function(vehicle)
    return canManageOccupantVehicle(vehicle) and not GetIsVehicleEngineRunning(vehicle)
end, function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    SetVehicleEngineOn(vehicle, true, true, true)
end, {}, occupantVehMgmt)

-- Fenêtres
VFW.ContextAddButton("vehicle", ":home: Ouvrir les fenêtres", function(vehicle)
    return canManageOccupantVehicle(vehicle)
end, function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    for w = 0, 3 do RollDownWindow(vehicle, w) end
end, {}, occupantVehMgmt)

VFW.ContextAddButton("vehicle", ":home: Fermer les fenêtres", function(vehicle)
    return canManageOccupantVehicle(vehicle)
end, function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    for w = 0, 3 do RollUpWindow(vehicle, w) end
end, {}, occupantVehMgmt)

-- Verrouiller/Déverrouiller (visible si clés détenues, validation serveur identique à la touche U)
VFW.ContextAddButton("vehicle", ":lock: Verrouiller/Déverrouiller", function(vehicle)
    return canLockVehicle(vehicle)
end, function()
    TriggerServerEvent("vfw:vehicle:open")
end, {}, occupantVehMgmt)

-- Sous-menu Portes
local occupantDoorsSub = VFW.ContextAddSubmenu("vehicle", ":door: Ouvrir Portes", function(vehicle)
    return canManageOccupantVehicle(vehicle)
end, {}, occupantVehMgmt)

VFW.ContextAddButton("vehicle", ":unlock: Tout ouvrir", function(vehicle)
    return canManageOccupantVehicle(vehicle)
end, function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    for d = 0, 5 do
        if doorExists(vehicle, d) then
            SetVehicleDoorOpen(vehicle, d, false, false)
        end
    end
end, {}, occupantDoorsSub, { order = 0 })

VFW.ContextAddButton("vehicle", ":lock: Tout fermer", function(vehicle)
    return canManageOccupantVehicle(vehicle)
end, function(vehicle)
    NetworkRequestControlOfEntity(vehicle)
    for d = 0, 5 do
        if doorExists(vehicle, d) then
            SetVehicleDoorShut(vehicle, d, false)
        end
    end
end, {}, occupantDoorsSub, { order = 1 })

for _, d in ipairs(DOORS) do
    VFW.ContextAddButton("vehicle", d.label, function(vehicle)
        return canManageOccupantVehicle(vehicle) and doorExists(vehicle, d.idx)
    end, function(vehicle)
        NetworkRequestControlOfEntity(vehicle)
        if GetVehicleDoorAngleRatio(vehicle, d.idx) > 0.1 then
            SetVehicleDoorShut(vehicle, d.idx, false)
        else
            SetVehicleDoorOpen(vehicle, d.idx, false, false)
        end
    end, {}, occupantDoorsSub, { order = 10 + d.idx })
end

--endregion

--region ------ 9. Action Développeurs - Mode Drift

local driftModeEnabled = false

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end
    while true do
        Wait(150)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and HasStaffPermission("alt_drift_mode") then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                if driftModeEnabled then
                    SetVehicleReduceGrip(veh, IsControlPressed(0, 21)) -- SHIFT
                else
                    SetVehicleReduceGrip(veh, false)
                end
            end
        end
    end
end)

VFW.ContextAddButton("vehicle", ":flag: Mode Drift", function(vehicle)
    return DoesEntityExist(vehicle) and HasStaffPermission("alt_drift_mode")
end, function()
    driftModeEnabled = not driftModeEnabled
    VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Gestion Véhicules', message = "Mode drift " .. (driftModeEnabled and "activé" or "désactivé") .. "." })
end, {}, DevSubmenu)

--endregion

--region ------ Event Client Side

RegisterNetEvent("vfw:vehicle:apply", function(action, netId, extra)
    -- Attendre que l'entité soit disponible (peut prendre quelques frames)
    local veh = NetworkGetEntityFromNetworkId(netId)
    local attempts = 0
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and attempts < 20 do
        Wait(50)
        veh = NetworkGetEntityFromNetworkId(netId)
        attempts = attempts + 1
    end

    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return
    end

    if action == "vehicle:repair" then
        SetVehicleFixed(veh)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleUndriveable(veh, false)

    -- vehicle:lockToggle est maintenant géré entièrement côté serveur (voir sv_vehicle_context_menu.lua)

    elseif action == "vehicle:engineToggle" then
        local running = GetIsVehicleEngineRunning(veh)
        SetVehicleEngineOn(veh, not running, true, true)

    elseif action == "vehicle:immobilizeToggle" then
        local frozen = IsEntityPositionFrozen(veh)
        FreezeEntityPosition(veh, not frozen)

    elseif action == "vehicle:doorToggle" then
        local d = extra and extra.door or 0
        if GetVehicleDoorAngleRatio(veh, d) > 0.1 then
            SetVehicleDoorShut(veh, d, false)
        else
            SetVehicleDoorOpen(veh, d, false, false)
        end

    elseif action == "vehicle:doorsOpenAll" then
        for d = 0, 5 do SetVehicleDoorOpen(veh, d, false, false) end

    elseif action == "vehicle:doorsCloseAll" then
        for d = 0, 5 do SetVehicleDoorShut(veh, d, false) end

    elseif action == "vehicle:trunkToggle" then
        local d = 5
        if GetVehicleDoorAngleRatio(veh, d) > 0.1 then
            SetVehicleDoorShut(veh, d, false)
        else
            SetVehicleDoorOpen(veh, d, false, false)
        end

    elseif action == "vehicle:windowsOpenAll" then
        for w = 0, 3 do RollDownWindow(veh, w) end

    elseif action == "vehicle:windowsCloseAll" then
        for w = 0, 3 do RollUpWindow(veh, w) end

    elseif action == "vehicle:speedLimit" then
        local kph = (extra and extra.kph) or 0
        if kph and kph > 0 then
            SetVehicleMaxSpeed(veh, kph / 3.6)
        else
            SetVehicleMaxSpeed(veh, 999.0)
        end

    elseif action == "vehicle:delete" then
        -- Attendre d'avoir le contrôle de l'entité
        local timeout = 0
        NetworkRequestControlOfEntity(veh)
        while not NetworkHasControlOfEntity(veh) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end

        if NetworkHasControlOfEntity(veh) then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteEntity(veh)
        end

    elseif action == "vehicle:destroyEngine" then
        SetVehicleEngineHealth(veh, 0.0)
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleUndriveable(veh, true)

    elseif action == "vehicle:clean" then
        SetVehicleDirtLevel(veh, 0.0)

    elseif action == "vehicle:refuel" then
        if VehicleFuel then
            VehicleFuel.Set(veh, 100.0, true)
        else
            SetVehicleFuelLevel(veh, 100.0)
        end

    elseif action == "vehicle:flip180" then
        -- Attendre d'avoir le contrôle de l'entité
        local timeout = 0
        NetworkRequestControlOfEntity(veh)
        while not NetworkHasControlOfEntity(veh) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end

        if NetworkHasControlOfEntity(veh) then
            SetVehicleOnGroundProperly(veh)
        end

    elseif action == "vehicle:removeWheels" then
        local timeout = 0
        NetworkRequestControlOfEntity(veh)
        while not NetworkHasControlOfEntity(veh) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
        if NetworkHasControlOfEntity(veh) then
            for i = 0, GetVehicleNumberOfWheels(veh) - 1 do
                BreakOffVehicleWheel(veh, i, false, false, true, false)
            end
        end

    elseif action == "vehicle:soap" then
        local timeout = 0
        NetworkRequestControlOfEntity(veh)
        while not NetworkHasControlOfEntity(veh) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
        if NetworkHasControlOfEntity(veh) then
            local origTractionMax = GetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax")
            local origTractionMin = GetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin")
            local origTractionBias = GetVehicleHandlingFloat(veh, "CHandlingData", "fTractionBiasFront")
            local origLowSpeedLoss = GetVehicleHandlingFloat(veh, "CHandlingData", "fLowSpeedTractionLossMult")

            SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax", 0.4)
            SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin", 0.2)
            SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionBiasFront", 0.48)
            SetVehicleHandlingFloat(veh, "CHandlingData", "fLowSpeedTractionLossMult", 0.0)

            CreateThread(function()
                Wait(60000)
                if DoesEntityExist(veh) then
                    NetworkRequestControlOfEntity(veh)
                    local t = 0
                    while not NetworkHasControlOfEntity(veh) and t < 50 do
                        Wait(10)
                        t = t + 1
                    end
                    if NetworkHasControlOfEntity(veh) then
                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMax", origTractionMax)
                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionCurveMin", origTractionMin)
                        SetVehicleHandlingFloat(veh, "CHandlingData", "fTractionBiasFront", origTractionBias)
                        SetVehicleHandlingFloat(veh, "CHandlingData", "fLowSpeedTractionLossMult", origLowSpeedLoss)
                    end
                end
            end)
        end

    elseif action == "vehicle:setAlpha" then
        local alpha = (extra and extra.alpha) or 255

        -- SetEntityAlpha fonctionne sans contrôle de l'entité (modification locale)
        if alpha == 255 then
            ResetEntityAlpha(veh)
        else
            SetEntityAlpha(veh, alpha, false)
        end
    end
end)

--endregion