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

--endregion

--region ------ SUBMENUS (en premier)

-- 1. Actions Staff
local staffSubmenu = VFW.ContextAddSubmenu("world", ":police: Actions Staff", function()
    return IsInStaffMode()
end, {}, nil, { permission = "contextmenu" })

-- 2. Actions Développeur
local devSubmenu = VFW.ContextAddSubmenu("world", ":wrench: Actions Développeur", function()
    return IsInStaffMode()
end, {}, nil, { permission = "devcontextmenu" })

--endregion

--region ------ 1. Actions Staff

-- Téléportation
VFW.ContextAddButton("world", ":rocket: Se téléporter ici", function()
    return IsInStaffMode()
end, function(_, worldPosition)
    local playerPed = PlayerPedId()
    SetEntityCoordsNoOffset(playerPed, worldPosition.x, worldPosition.y, worldPosition.z + 1.0, false, false, false)
    SetEntityHeading(playerPed, GetGameplayCamRelativeHeading())
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = 'Téléporté.' })
end, {}, staffSubmenu, { permission = "alt_teleport" })

-- Placer marqueur GPS
VFW.ContextAddButton("world", ":pin: Placer un marqueur GPS", function()
    return IsInStaffMode()
end, function(_, worldPosition)
    SetNewWaypoint(worldPosition.x, worldPosition.y)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = 'Marqueur placé sur la carte.' })
end, {}, staffSubmenu, { permission = "contextmenu" })

-- Mesurer distance
VFW.ContextAddButton("world", ":ruler: Mesurer la distance", function()
    return IsInStaffMode()
end, function(_, worldPosition)
    local playerPos = GetEntityCoords(PlayerPedId())
    local distance = #(playerPos - vector3(worldPosition.x, worldPosition.y, worldPosition.z))
    VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Menu Monde', message = string.format('Distance: %.2f mètres.', distance) })
end, {}, staffSubmenu, { permission = "contextmenu" })

-- Heal zone
VFW.ContextAddButton("world", ":dot-green: Heal zone (75m)", function()
    return IsInStaffMode()
end, function(_, worldPosition)
    VFW.TreatZone(75, vector3(worldPosition.x, worldPosition.y, worldPosition.z))
end, {}, staffSubmenu, { permission = "zone_actions" })

-- Spawn props (placement avec preview + gizmo, copié du système jobsPropsMenu)
local StartStaffPropPlacement

local function SpawnStaffPropPreview(model, position)
    local hash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(hash) then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Spawn Prop', message = "Ce modèle n'est pas valide : " .. tostring(model) .. "." })
        return nil
    end

    local obj = nil
    VFW.Game.SpawnLocalObject(model, position, function(o) obj = o end)
    if not obj or not DoesEntityExist(obj) then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Spawn Prop', message = "Échec du spawn de l'objet." })
        return nil
    end

    SetEntityAlpha(obj, 150, false)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, true)
    return obj
end

local function FinalizeStaffPropPlacement(model, pos, rot)
    TriggerServerEvent("vfw:staff:spawnProp", model, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z)
end

StartStaffPropPlacement = function(model)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnPos = coords + forward * 2.5

    local previewObj = SpawnStaffPropPreview(model, spawnPos)
    if not previewObj then return end

    PlaceObjectOnGroundProperly(previewObj)

    local buttonsId = VFW.AddInstructionalButtons({
        { label = "Poser l'objet", control = 38 },
        { label = "Tourner", control = 15, control2 = 16 },
        { label = "Mode avancé", control = 47 },
        { label = "Terminer", control = 177 },
    })

    local currentHeading = GetEntityHeading(playerPed)
    local placing = true
    local useGizmo = false

    while placing do
        Wait(0)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)
        local targetPos = pCoords + fwd * 2.5

        SetEntityCoords(previewObj, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(previewObj)
        SetEntityHeading(previewObj, currentHeading)

        DisableControlAction(0, 15, true)
        DisableControlAction(0, 16, true)
        if IsDisabledControlJustPressed(0, 15) then currentHeading = currentHeading + 15.0 end
        if IsDisabledControlJustPressed(0, 16) then currentHeading = currentHeading - 15.0 end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(ped, true)

        if VFW.Interact.JustPressed(0, 38) then placing = false end
        if IsControlJustPressed(0, 47) then placing = false; useGizmo = true end
        if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
            placing = false
            if DoesEntityExist(previewObj) then VFW.Game.DeleteObject(previewObj) end
            VFW.RemoveInstructionalButtons(buttonsId)
            return
        end
    end

    VFW.RemoveInstructionalButtons(buttonsId)

    if useGizmo then
        local data = exports["core"]:useGizmo(previewObj)
        if data and data.switchedBack then
            if DoesEntityExist(previewObj) then VFW.Game.DeleteObject(previewObj) end
            StartStaffPropPlacement(model)
        elseif data and data.handle and DoesEntityExist(data.handle) then
            VFW.Game.DeleteObject(previewObj)
            FinalizeStaffPropPlacement(model, data.position, data.rotation)
            StartStaffPropPlacement(model)
        else
            if DoesEntityExist(previewObj) then VFW.Game.DeleteObject(previewObj) end
        end
    else
        local finalPos = GetEntityCoords(previewObj)
        local finalRot = GetEntityRotation(previewObj)
        VFW.Game.DeleteObject(previewObj)
        FinalizeStaffPropPlacement(model, finalPos, finalRot)
        StartStaffPropPlacement(model)
    end
end

VFW.ContextAddButton("world", ":box: Spawn un prop", function()
    return HasStaffPermission("alt_spawn_object")
end, function()
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local propName = VFW.Nui.KeyboardInput(true, "Nom du prop (ex: prop_barrier_work05)", "", 50)
        if not propName or propName == "" or propName == "KBD_CANCEL" then return end

        if not IsModelInCdimage(GetHashKey(propName)) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Spawn Prop', message = "Ce modèle n'est pas valide : " .. propName .. "." })
            return
        end

        StartStaffPropPlacement(propName)
    end)
end, {}, staffSubmenu, { permission = "alt_spawn_object" })

-- Gestion Graffiti
local graffitiSubmenu = VFW.ContextAddSubmenu("world", ":palette: Gestion Graffiti", function()
    return HasStaffPermission("graffiti")
end, {}, staffSubmenu)

VFW.ContextAddButton("world", ":eye: Afficher les IDs", function()
    return HasStaffPermission("graffiti")
end, function()
    ExecuteCommand("showgraffiti")
end, {}, graffitiSubmenu)

VFW.ContextAddButton("world", ":trash: Supprimer un graffiti", function()
    return HasStaffPermission("graffiti")
end, function()
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, "ID du graffiti à supprimer", "", 10)
        if input and input ~= "" and input ~= "KBD_CANCEL" then
            local graffitiId = tonumber(input)
            if graffitiId then
                ExecuteCommand("removegraffitiadmin " .. graffitiId)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Menu Monde', message = 'Cet identifiant n\'est pas valide.' })
            end
        end
    end)
end, {}, graffitiSubmenu)

--endregion

--region ------ 2. Actions Développeur

-- ============================================
-- 2.1 :globe: Environnement (Météo & Horaire)
-- ============================================
local envSubmenu = VFW.ContextAddSubmenu("world", ":globe: Environnement", function()
    return HasStaffPermission("alt_weather")
end, {}, devSubmenu, { permission = "alt_weather" })

-- Météo
local meteoSubmenu = VFW.ContextAddSubmenu("world", ":globe: Météo", function()
    return HasStaffPermission("alt_weather")
end, {}, envSubmenu)

local weatherTypes = {
    { label = ":sparkles: Ensoleillé", weather = "EXTRASUNNY" },
    { label = ":globe: Dégagé", weather = "CLEAR" },
    { label = " Nuageux", weather = "CLOUDS" },
    { label = ":globe: Très nuageux", weather = "OVERCAST" },
    { label = ":globe: Brume", weather = "SMOG" },
    { label = ":globe: Brouillard", weather = "FOGGY" },
    { label = ":globe: Pluie", weather = "RAIN" },
    { label = ":globe: Orage", weather = "THUNDER" },
    { label = ":globe: Neige légère", weather = "SNOWLIGHT" },
    { label = ":sparkles: Neige", weather = "SNOW" },
    { label = ":globe: Blizzard", weather = "BLIZZARD" },
    { label = ":leaf: Noël", weather = "XMAS" },
    { label = ":star: Halloween", weather = "HALLOWEEN" },
}

for _, w in ipairs(weatherTypes) do
    VFW.ContextAddButton("world", w.label, function()
        return true
    end, function()
        TriggerServerEvent("vfw:staff:setWeather", w.weather)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = "Météo changée: " .. w.label .. "." })
    end, {}, meteoSubmenu)
end

-- Horaire
local horaireSubmenu = VFW.ContextAddSubmenu("world", ":clock: Horaire", function()
    return HasStaffPermission("alt_time")
end, {}, envSubmenu)

local timeOptions = {
    { label = ":globe: Aube (06:00)", hour = 6, minute = 0 },
    { label = ":sparkles: Matin (09:00)", hour = 9, minute = 0 },
    { label = ":sparkles: Midi (12:00)", hour = 12, minute = 0 },
    { label = ":building: Après-midi (15:00)", hour = 15, minute = 0 },
    { label = ":building: Fin de journée (18:00)", hour = 18, minute = 0 },
    { label = ":globe: Coucher de soleil (20:00)", hour = 20, minute = 0 },
    { label = ":clock: Soirée (21:00)", hour = 21, minute = 0 },
    { label = ":building: Nuit (00:00)", hour = 0, minute = 0 },
    { label = ":globe: Nuit profonde (03:00)", hour = 3, minute = 0 },
}

for _, t in ipairs(timeOptions) do
    VFW.ContextAddButton("world", t.label, function()
        return HasStaffPermission("alt_time")
    end, function()
        TriggerServerEvent("vfw:staff:setTime", t.hour, t.minute)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = "Horaire changé: " .. t.label .. "." })
    end, {}, horaireSubmenu)
end

-- ============================================
-- 2.2 :rocket: Spawn (Véhicules, PED, Objets)
-- ============================================
local spawnSubmenu = VFW.ContextAddSubmenu("world", ":rocket: Spawn", function()
    return IsInStaffMode() and (HasStaffPermission("alt_spawn_vehicle") or HasStaffPermission("alt_spawn_ped") or HasStaffPermission("alt_spawn_object") or HasStaffPermission("addvehplayer"))
end, {}, nil)

-- Spawn véhicule temporaire
VFW.ContextAddButton("world", ":car: Véhicule temporaire", function()
    return HasStaffPermission("alt_spawn_vehicle")
end, function(_, worldPosition)
    local posX, posY, posZ = worldPosition.x, worldPosition.y, worldPosition.z

    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local vehicle = VFW.Nui.KeyboardInput(true, "Nom du véhicule (ex: adder)", "", 30)

        if not vehicle or vehicle == "" or vehicle == "KBD_CANCEL" then
            return
        end

        local heading = GetEntityHeading(PlayerPedId())
        TriggerServerEvent("vfw:staff:spawnVehicle", vehicle, posX, posY, posZ + 0.5, heading)
    end)
end, {}, spawnSubmenu)

-- Spawn véhicule définitif
VFW.ContextAddButton("world", ":car: Véhicule définitif", function()
    return HasStaffPermission("addvehplayer")
end, function(_, worldPosition)
    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local vehicle = VFW.Nui.KeyboardInput(true, "Nom du véhicule (ex: adder)", "", 30)

        if not vehicle or vehicle == "" or vehicle == "KBD_CANCEL" then
            return
        end

        Wait(100)
        VFW.Nui.Focus(true)
        local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur", "", 10)

        if not playerId or playerId == "" or playerId == "KBD_CANCEL" then
            return
        end

        local plate = "ADM" .. math.random(10000, 99999)
        TriggerServerEvent("vfw:staff:giveCar", tonumber(playerId), vehicle, plate, GetMakeNameFromVehicleModel(GetHashKey(vehicle)))
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = 'Véhicule définitif donné au joueur #' .. playerId .. '.' })
    end)
end, {}, spawnSubmenu)

-- Spawn PED
VFW.ContextAddButton("world", ":user: PED", function()
    return HasStaffPermission("alt_spawn_ped")
end, function(_, worldPosition)
    local posX, posY, posZ = worldPosition.x, worldPosition.y, worldPosition.z

    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local pedModel = VFW.Nui.KeyboardInput(true, "Modèle du PED (ex: a_m_y_hipster_01)", "", 50)

        if not pedModel or pedModel == "" or pedModel == "KBD_CANCEL" then
            return
        end

        local heading = GetEntityHeading(PlayerPedId())
        TriggerServerEvent("vfw:staff:spawnPed", pedModel, posX, posY, posZ, heading)
    end)
end, {}, spawnSubmenu)

-- Spawn objet
VFW.ContextAddButton("world", ":box: Objet", function()
    return HasStaffPermission("alt_spawn_object")
end, function(_, worldPosition)
    local posX, posY, posZ = worldPosition.x, worldPosition.y, worldPosition.z

    VFW.OpenContextMenu()
    CreateThread(function()
        Wait(250)
        VFW.Nui.Focus(true)
        local object = VFW.Nui.KeyboardInput(true, "Nom de l'objet (ex: prop_bench_01a)", "", 50)

        if not object or object == "" or object == "KBD_CANCEL" then
            return
        end

        if not IsModelInCdimage(GetHashKey(object)) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Menu Monde', message = 'Ce modèle n\'est pas valide: ' .. object .. '.' })
            return
        end

        TriggerServerEvent("vfw:staff:spawnProp", object, posX, posY, posZ, 0.0, 0.0, 0.0)
    end)
end, {}, spawnSubmenu)

-- ============================================
-- 2.3 :trash: Suppression
-- ============================================
local deleteSubmenu = VFW.ContextAddSubmenu("world", ":trash: Suppression", function()
    return HasStaffPermission("devcontextmenu") or HasStaffPermission("alt_delete_entity")
end, {}, devSubmenu)

-- Supprimer objets proches
VFW.ContextAddButton("world", ":box: Objets proches (5m)", function()
    return HasStaffPermission("devcontextmenu")
end, function(_, worldPosition)
    local objectsDeleted = 0
    local objects = GetGamePool('CObject')
    for _, object in ipairs(objects) do
        local objPos = GetEntityCoords(object)
        local distance = #(objPos - vector3(worldPosition.x, worldPosition.y, worldPosition.z))
        if distance <= 5.0 then
            DeleteEntity(object)
            objectsDeleted = objectsDeleted + 1
        end
    end
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = objectsDeleted .. ' objets supprimés.' })
end, {}, deleteSubmenu)

-- Supprimer véhicule définitivement
VFW.ContextAddButton("world", ":car: Véhicule définitif", function()
    return HasStaffPermission("dv")
end, function(_, worldPosition)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = 10.0

    for _, vehicle in ipairs(vehicles) do
        local vehPos = GetEntityCoords(vehicle)
        local distance = #(vehPos - vector3(worldPosition.x, worldPosition.y, worldPosition.z))
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end

    if closestVehicle then
        local plate = VFW.Math.Trim(GetVehicleNumberPlateText(closestVehicle))
        local netId = NetworkGetNetworkIdFromEntity(closestVehicle)
        if netId then
            TriggerServerEvent("core:jobs:vehicle:cleanupBootBeforeDelete", netId)
        end
        TriggerServerEvent("vfw:vehicle:keyTemporarly:remove", nil, plate)
        TriggerServerEvent("vfw:mechanic:impound", plate)
        DeleteEntity(closestVehicle)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = 'Véhicule supprimé (plaque: ' .. plate .. ').' })
    else
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Menu Monde', message = 'Aucun véhicule trouvé à proximité.' })
    end
end, {}, deleteSubmenu)

-- ============================================
-- 2.4 :wrench: Utilitaires
-- ============================================
local utilsSubmenu = VFW.ContextAddSubmenu("world", ":wrench: Utilitaires", function()
    return HasStaffPermission("devcontextmenu")
end, {}, devSubmenu)

-- Copier coordonnées
VFW.ContextAddButton("world", ":report: Copier coordonnées", function()
    return HasStaffPermission("alt_copy_coords")
end, function(_, worldPosition)
    local coordstring = string.format("vector3(%.2f, %.2f, %.2f)", worldPosition.x, worldPosition.y, worldPosition.z)
    VFW.Clipboard(coordstring)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Menu Monde', message = 'Coordonnées copiées.' })
end, {}, utilsSubmenu)

-- Créer explosion
VFW.ContextAddButton("world", " Créer explosion", function()
    return HasStaffPermission("devcontextmenu")
end, function(_, worldPosition)
    TriggerServerEvent("vfw:staff:createExplosion", worldPosition.x, worldPosition.y, worldPosition.z)
end, {}, utilsSubmenu)

RegisterNetEvent("vfw:staff:doExplosion", function(x, y, z)
    AddExplosion(x + 0.0, y + 0.0, z + 0.0, 1, 1.0, true, false, 1.0)
end)

-- ============================================
-- 2.5 :pin: DVM Route Editor
-- ============================================
local dvmEditorSubmenu = VFW.ContextAddSubmenu("world", ":pin: DVM Route Editor", function()
    return HasStaffPermission("dev")
end, {}, devSubmenu)

-- Start New Route -> Category Selection
local startRouteSubmenu = VFW.ContextAddSubmenu("world", ":arrow: Démarrer Nouvelle Route", function()
    return not VFW.DVMRouteRecording
end, {}, dvmEditorSubmenu)

-- Category: Car
local carSubmenu = VFW.ContextAddSubmenu("world", ":car: Voiture", function()
    return not VFW.DVMRouteRecording
end, {}, startRouteSubmenu)

-- Category: Motorcycle
local motoSubmenu = VFW.ContextAddSubmenu("world", ":car: Moto", function()
    return not VFW.DVMRouteRecording
end, {}, startRouteSubmenu)

-- Category: Truck
local truckSubmenu = VFW.ContextAddSubmenu("world", ":car: Camion", function()
    return not VFW.DVMRouteRecording
end, {}, startRouteSubmenu)

-- Add exam center buttons for each category (loaded after config is available)
CreateThread(function()
    Wait(500) -- Attendre que Config.DVM soit chargé

    if Config.DVM and Config.DVM.ExamCenters then
        for i, center in ipairs(Config.DVM.ExamCenters) do
            VFW.ContextAddButton("world", center.name, function()
                return not VFW.DVMRouteRecording
            end, function()
                VFW.DVMStartRouteRecording("car", i)
            end, {}, carSubmenu)

            VFW.ContextAddButton("world", center.name, function()
                return not VFW.DVMRouteRecording
            end, function()
                VFW.DVMStartRouteRecording("motorcycle", i)
            end, {}, motoSubmenu)

            VFW.ContextAddButton("world", center.name, function()
                return not VFW.DVMRouteRecording
            end, function()
                VFW.DVMStartRouteRecording("truck", i)
            end, {}, truckSubmenu)
        end
    end
end)

-- Add Checkpoint Here
VFW.ContextAddButton("world", ":plus: Ajouter Checkpoint Ici", function()
    return VFW.DVMRouteRecording
end, function(_, worldPosition)
    local coords = vector3(worldPosition.x, worldPosition.y, worldPosition.z)
    VFW.DVMAddCheckpoint(coords)
end, {}, dvmEditorSubmenu)

-- Remove Last Checkpoint
VFW.ContextAddButton("world", ":minus: Supprimer Dernier Checkpoint", function()
    return VFW.DVMRouteRecording and VFW.DVMCurrentRoute and #VFW.DVMCurrentRoute.checkpoints > 0
end, function()
    VFW.DVMRemoveLastCheckpoint()
end, {}, dvmEditorSubmenu)

-- Finish & Export Route
VFW.ContextAddButton("world", ":check: Terminer & Exporter Route", function()
    return VFW.DVMRouteRecording and VFW.DVMCurrentRoute and #VFW.DVMCurrentRoute.checkpoints >= 2
end, function()
    VFW.DVMFinishRoute()
end, {}, dvmEditorSubmenu)

-- Cancel Route
VFW.ContextAddButton("world", ":x: Annuler Route", function()
    return VFW.DVMRouteRecording
end, function()
    VFW.DVMCancelRoute()
end, {}, dvmEditorSubmenu)

--endregion

--region ------ Staff Props Client

-- Le spawn/delete est server-side : on lit juste le state répliqué pour identifier les props staff
function IsStaffProp(object)
    if not DoesEntityExist(object) then return false, nil end
    local propId = Entity(object).state.staffPropId
    if propId then return true, propId end
    return false, nil
end

--endregion

--region ------ Staff Spawned PED (no AI)

local function ApplyNoAIToPed(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    if not NetworkHasControlOfEntity(ped) then
        NetworkRequestControlOfEntity(ped)
        local timeout = 0
        while not NetworkHasControlOfEntity(ped) and timeout < 20 do
            Wait(50); timeout = timeout + 1
        end
    end
    if not NetworkHasControlOfEntity(ped) then return end

    ClearPedTasksImmediately(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedAsEnemy(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityInvincible(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetPedConfigFlag(ped, 32, true)
    SetPedConfigFlag(ped, 17, true)
    SetPedConfigFlag(ped, 281, true)
    SetPedConfigFlag(ped, 294, true)
    FreezeEntityPosition(ped, true)
end

RegisterNetEvent("vfw:staff:disablePedAI", function(netId)
    CreateThread(function()
        local ped = NetworkGetEntityFromNetworkId(netId)
        local timeout = 0
        while (not ped or ped == 0 or not DoesEntityExist(ped)) and timeout < 30 do
            Wait(100)
            ped = NetworkGetEntityFromNetworkId(netId)
            timeout = timeout + 1
        end
        ApplyNoAIToPed(ped)
    end)
end)

AddStateBagChangeHandler("staffSpawnedPed", nil, function(bagName, _, value)
    if not value then return end
    local netId = tonumber(bagName:match("entity:(%d+)"))
    if not netId then return end
    CreateThread(function()
        local ped = NetworkGetEntityFromNetworkId(netId)
        local timeout = 0
        while (not ped or ped == 0 or not DoesEntityExist(ped)) and timeout < 30 do
            Wait(100)
            ped = NetworkGetEntityFromNetworkId(netId)
            timeout = timeout + 1
        end
        ApplyNoAIToPed(ped)
    end)
end)

--endregion
