---
--- Mechanic Job Menu
--- Registers mechanic-specific items to the job menu
---

local resourceName = "core"

-- Item labels for notifications
local ITEM_LABELS = {
    clean = "Kit de nettoyage",
    body = "Kit carrosserie",
    engine = "Kit de réparation",
}

-- Action durations in ms
local ACTION_DURATIONS = {
    clean = 5000,
    body = 8000,
    engine = 10000,
}

-- Animations for each action. If `prop` is set, a networked prop is spawned and
-- attached to the right hand (visible to all clients) during the action.
local ANIMATIONS = {
    clean = {
        dict = "timetable@floyd@clean_kitchen@base",
        anim = "base",
        prop = {
            model = "prop_sponge_01",
            bone = 57005, -- IK_R_Hand (main droite)
            pos = vector3(0.15, 0.0, -0.01),
            rot = vector3(90.0, 0.0, 0.0),
        },
    },
    body = { dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", anim = "machinic_loop_mechandplayer" },
    engine = { dict = "mini@repair", anim = "fixing_a_ped" },
}

--- Create a networked prop attached to the ped (visible to all clients).
---@param ped number Player ped
---@param propData table { model, bone, pos, rot }
---@return number|nil prop Entity handle or nil on failure
local function createAttachedProp(ped, propData)
    local model = type(propData.model) == "string" and GetHashKey(propData.model) or propData.model
    if not IsModelValid(model) then return nil end

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not HasModelLoaded(model) then return nil end

    local coords = GetEntityCoords(ped)
    -- Prop cosmétique local (non-networked) — compatible lockdown "strict".
    local prop = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, propData.bone),
        propData.pos.x, propData.pos.y, propData.pos.z,
        propData.rot.x, propData.rot.y, propData.rot.z,
        false, false, false, false, 2, true
    )
    SetModelAsNoLongerNeeded(model)
    return prop
end

--- Remove an attached prop (safe on nil / deleted entities).
---@param prop number|nil Entity handle
local function removeAttachedProp(prop)
    if not prop then return end
    if DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end
end

--- Best-effort request of network control so SetVehicle* natives stick and replicate.
--- Returns true if we got control, false otherwise — caller should proceed either way.
---@param vehicle number Vehicle entity
---@return boolean hasControl
local function ensureNetworkControl(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    -- Local (non-networked) entities: we already have full authority
    if NetworkGetEntityIsNetworked and not NetworkGetEntityIsNetworked(vehicle) then
        return true
    end
    if NetworkHasControlOfEntity(vehicle) then return true end
    NetworkRequestControlOfEntity(vehicle)
    local tries = 0
    while not NetworkHasControlOfEntity(vehicle) and tries < 15 do
        Wait(50)
        NetworkRequestControlOfEntity(vehicle)
        tries = tries + 1
    end
    return NetworkHasControlOfEntity(vehicle)
end

--- Read live vehicle stats (health, fuel, dirt)
---@param vehicle number Vehicle entity
---@return table|nil stats Nil if vehicle no longer exists
local function readVehicleStats(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return nil end
    return {
        engineHealth = math.max(0, GetVehicleEngineHealth(vehicle) / 10),
        bodyHealth = math.max(0, GetVehicleBodyHealth(vehicle) / 10),
        fuelLevel = GetVehicleFuelLevel and GetVehicleFuelLevel(vehicle) or 0,
        dirtLevel = GetVehicleDirtLevel(vehicle) * 6.67,
    }
end

-- Active diagnostic session (single instance)
local diagnosticSession = nil

--- Show vehicle diagnostic UI
---@param vehicle number Vehicle entity
local function showDiagnosticUI(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    local image = TriggerServerCallback("core:get:societyImage")

    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local name = GetLabelText(model)
    local stats = readVehicleStats(vehicle)
    if not stats then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "nui:vehicleDiagnostic:open",
        data = {
            societyImage = image,
            vehicleName = name,
            plate = plate,
            engineHealth = stats.engineHealth,
            bodyHealth = stats.bodyHealth,
            fuelLevel = stats.fuelLevel,
            dirtLevel = stats.dirtLevel,
        }
    })

    -- Start live update loop so the UI reflects repairs done by other mechanics
    diagnosticSession = { vehicle = vehicle, running = true }
    local session = diagnosticSession
    CreateThread(function()
        while session.running do
            Wait(500)
            if not session.running then break end
            local liveStats = readVehicleStats(session.vehicle)
            if not liveStats then
                session.running = false
                VFW.Nui.Focus(false, false)
                SendNUIMessage({ action = "nui:vehicleDiagnostic:close" })
                break
            end
            SendNUIMessage({
                action = "nui:vehicleDiagnostic:update",
                data = liveStats,
            })
        end
    end)
end

-- NUI callback for closing diagnostic
RegisterNuiCallback("nui:vehicleDiagnostic:close", function(_, cb)
    if diagnosticSession then
        diagnosticSession.running = false
        diagnosticSession = nil
    end
    VFW.Nui.Focus(false, false)
    cb("ok")
end)

--- Check if player is near the front (engine) of a vehicle
---@param vehicle number Vehicle entity
---@param maxDistance number Maximum distance from engine
---@return boolean
local function isPlayerNearEngine(vehicle, maxDistance)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleForward = GetEntityForwardVector(vehicle)

    -- Get the front of the vehicle (engine position)
    local modelMin, modelMax = GetModelDimensions(GetEntityModel(vehicle))
    local engineOffset = (modelMax.y - modelMin.y) / 2 + 0.5 -- Front of the vehicle
    local enginePos = vehicleCoords + vehicleForward * engineOffset

    local distance = #(playerCoords - enginePos)
    return distance <= maxDistance
end

--- Get the closest vehicle in front of the player
---@param maxDistance number Maximum distance to search
---@return number|nil vehicle The vehicle entity or nil
local function getVehicleInFront(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)

    -- Raycast in front of player
    local endCoords = playerCoords + forwardVector * maxDistance
    local rayHandle = StartShapeTestRay(
            playerCoords.x, playerCoords.y, playerCoords.z,
            endCoords.x, endCoords.y, endCoords.z,
            10, -- Vehicles flag
            playerPed,
            0
    )

    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit and IsEntityAVehicle(entityHit) then
        return entityHit
    end

    -- Fallback: check for closest vehicle in range
    local closestVehicle = VFW.Game.GetClosestVehicle(playerCoords)
    if closestVehicle and DoesEntityExist(closestVehicle) then
        -- Check if vehicle is in front (dot product > 0)
        local vehicleCoords = GetEntityCoords(closestVehicle)
        local toVehicle = vehicleCoords - playerCoords
        local dot = forwardVector.x * toVehicle.x + forwardVector.y * toVehicle.y

        if dot > 0 then
            return closestVehicle
        end
    end

    return nil
end

--- Perform a repair action on a vehicle
---@param actionType string Type of action (clean, body, engine)
---@param vehicle number Vehicle entity
local function performRepairAction(actionType, vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    -- For engine repair, check if player is near the front of the vehicle
    if actionType == "engine" then
        if not isPlayerNearEngine(vehicle, 3.0) then
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Vous devez être devant le capot pour réparer le moteur"
           })
            return
        end
    end

    -- Check if player has item
    local hasItem = TriggerServerCallback("mechanic:hasItem", actionType)
    if not hasItem then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas de " .. ITEM_LABELS[actionType]
        })
        return
    end

    local playerPed = PlayerPedId()

    -- Turn player to face the vehicle
    TaskTurnPedToFaceEntity(playerPed, vehicle, 1000)
    Wait(1000)

    -- Open hood for engine repair
    local hoodOpened = false
    if actionType == "engine" then
        SetVehicleDoorOpen(vehicle, 4, false, false) -- 4 = hood
        hoodOpened = true
        Wait(500)
    end

    -- Load and play animation
    local animData = ANIMATIONS[actionType]
    if not HasAnimDictLoaded(animData.dict) then
        RequestAnimDict(animData.dict)
        local timeout = 0
        while not HasAnimDictLoaded(animData.dict) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
    end
    -- Loop flag = 1 keeps the animation looping during the progress bar
    TaskPlayAnim(playerPed, animData.dict, animData.anim, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Spawn networked prop (visible to all clients)
    local activeProp = nil
    if animData.prop then
        activeProp = createAttachedProp(playerPed, animData.prop)
    end

    -- Progress bar
    local label = actionType == "clean" and "Nettoyage en cours..." or
            actionType == "body" and "Réparation carrosserie..." or
            "Réparation moteur..."

   -- Freeze blocks movement but leaves the camera free to look around
    FreezeEntityPosition(playerPed, true)
    local success = VFW.Nui.ProgressBar(label, ACTION_DURATIONS[actionType], false)
    FreezeEntityPosition(playerPed, false)

    -- Stop animation and remove prop
    ClearPedTasksImmediately(playerPed)
    removeAttachedProp(activeProp)
    activeProp = nil

    -- Close hood if it was opened
    if hoodOpened and DoesEntityExist(vehicle) then
        SetVehicleDoorShut(vehicle, 4, false) -- Close hood
    end

    if not success then
        VFW.ShowNotification({ type = 'ROUGE', content = "Action annulée" })
        return
    end

    -- Verify vehicle still exists
    if not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    -- Best-effort: take network control so SetVehicle* natives replicate to other clients.
    -- Proceed even on failure: changes will at least apply locally.
    ensureNetworkControl(vehicle)

    -- Perform the actual repair FIRST
    if actionType == "clean" then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        Entity(vehicle).state:set("mechanic:lastClean", GetGameTimer(), true)
    elseif actionType == "body" then
        local engineHealth = GetVehicleEngineHealth(vehicle)
        SetVehicleFixed(vehicle)
        Wait(0)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleEngineHealth(vehicle, engineHealth)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleUndriveable(vehicle, false)
        for i = 0, 7 do FixVehicleWindow(vehicle, i) end
        for i = 0, 5 do SetVehicleDoorShut(vehicle, i, false) end
        Wait(100)
        Entity(vehicle).state:set("mechanic:lastBodyRepair", GetGameTimer(), true)
        local props = VFW.Game.GetVehicleProperties(vehicle)
        if props then
            Entity(vehicle).state:set("VehicleProperties", props, true)
        end
    elseif actionType == "engine" then
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleUndriveable(vehicle, false)
        Entity(vehicle).state:set("engineDestroyed", nil, true)
        local props = VFW.Game.GetVehicleProperties(vehicle)
        if props then
            Entity(vehicle).state:set("VehicleProperties", props, true)
        end
    end

    -- Remove item from inventory AFTER repair is done
    local removed = TriggerServerCallback("mechanic:removeItem", actionType)
    if not removed then
        VFW.ShowNotification({ type = 'ROUGE', content = "Erreur lors de la consommation de l'item" })
        return
    end

    -- Show success notification
    if actionType == "clean" then
        VFW.ShowNotification({ type = 'VERT', content = "Véhicule nettoyé" })
    elseif actionType == "body" then
        VFW.ShowNotification({ type = 'VERT', content = "Carrosserie réparée" })
    elseif actionType == "engine" then
        VFW.ShowNotification({ type = 'VERT', content = "Moteur réparé" })
    end
end

-- Event for using items from inventory (mechanic only)
RegisterNetEvent("mechanic:useItem", function(actionType)
    local vehicle = getVehicleInFront(5.0)
    if not vehicle then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
        return
    end
    performRepairAction(actionType, vehicle)
end)

-- Event for using fast repair kit (any player)
RegisterNetEvent("mechanic:useFastRepairKit", function()
    local playerPed = PlayerPedId()

    -- Get vehicle in front of player
    local vehicle = getVehicleInFront(5.0)
    if not vehicle then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
        return
    end

    -- Check if player is near the engine (front of vehicle)
    if not isPlayerNearEngine(vehicle, 3.0) then
        VFW.ShowNotification({
            type = 'ORANGE',
            content = "Vous devez être devant le capot pour réparer le moteur"
       })
        return
    end

    -- Check current engine health
    local currentHealth = GetVehicleEngineHealth(vehicle)
    if currentHealth >= 1000.0 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Le moteur est déjà en bon état" })
        return
    end

    -- Turn player to face the vehicle
    TaskTurnPedToFaceEntity(playerPed, vehicle, 1000)
    Wait(1000)

    -- Open hood
    SetVehicleDoorOpen(vehicle, 4, false, false)
    Wait(500)

    -- Load animation
    local animDict = "mini@repair"
   if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
    end

    -- Play animation
    TaskPlayAnim(playerPed, animDict, "fixing_a_ped", 8.0, -8.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(playerPed, true)

    -- Progress bar - 20 seconds
    local success = VFW.Nui.ProgressBar("Réparation d'urgence...", 20000, true)
    FreezeEntityPosition(playerPed, false)

    -- Stop animation
    ClearPedTasks(playerPed)

    -- Close hood
    if DoesEntityExist(vehicle) then
        SetVehicleDoorShut(vehicle, 4, false)
    end

    if not success then
        VFW.ShowNotification({ type = 'ROUGE', content = "Réparation annulée" })
        return
    end

    -- Verify vehicle still exists
    if not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule introuvable" })
        return
    end

    -- Calculate new health (+25%, max 1000)
    local newHealth = math.min(currentHealth + 250.0, 1000.0)

    -- Demander au serveur la réparation + consommation de l'item.
    -- Le serveur valide (item, proximité, rate limit) puis broadcast à tous les clients
    -- via "mechanic:fastRepair:applyToAll" pour synchroniser la santé moteur partout.
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Véhicule non networké" })
        return
    end

    TriggerServerEvent("mechanic:fastRepair:apply", netId, newHealth)

    -- Calculate percentage repaired (affichage local optimiste)
    local percentRepaired = math.floor((newHealth - currentHealth) / 10)
    VFW.ShowNotification({
        type = 'VERT',
        content = string.format("Moteur réparé (+%d%%) - État: %d%%", percentRepaired, math.floor(newHealth / 10))
    })
end)

-- Réception du broadcast serveur: appliquer la nouvelle santé moteur sur tous les clients
RegisterNetEvent("mechanic:fastRepair:applyToAll", function(netId, newHealth)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleEngineHealth(vehicle, newHealth)

    if newHealth > 0 then
        SetVehicleUndriveable(vehicle, false)
        -- Démarrer le moteur si le véhicule était mort (côté owner uniquement)
        if NetworkGetEntityOwner(vehicle) == PlayerId() then
            SetVehicleEngineOn(vehicle, true, true, false)
        end
    end

    -- Sync du statebag VehicleProperties côté owner pour que la santé ne soit pas réécrasée
    if NetworkGetEntityOwner(vehicle) == PlayerId() then
        local props = VFW.Game.GetVehicleProperties(vehicle)
        if props then
            Entity(vehicle).state:set("VehicleProperties", props, true)
        end
    end
end)

-- ========================================
-- MENU & CONTEXT REGISTRATION
-- ========================================

-- Registries are in modules/**/client/ which loads before jobs/**/client/
-- So exports are guaranteed available at this point
local registry = exports.core:getJobMenuRegistry()
local contextRegistry = exports.core:getJobContextRegistry()

if registry then
    local repairSubMenu = registry.createSubMenuByType("mechanic", "repair", "Réparations")

    -- Setup repair submenu
    repairSubMenu.OnOpen(function()
        repairSubMenu.Button("Réparer le moteur", "Devant le capot - Kit de réparation", nil, "chevron", false, function()
            local vehicle = getVehicleInFront(5.0)
            if not vehicle then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
                return
            end
            repairSubMenu.close()
            performRepairAction("engine", vehicle)
        end)

        repairSubMenu.Button("Réparer la carrosserie", "Nécessite: Kit carrosserie", nil, "chevron", false, function()
            local vehicle = getVehicleInFront(5.0)
            if not vehicle then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
                return
            end
            repairSubMenu.close()
            performRepairAction("body", vehicle)
        end)

        repairSubMenu.Button("Nettoyer le véhicule", "Nécessite: Kit de nettoyage", nil, "chevron", false, function()
            local vehicle = getVehicleInFront(5.0)
            if not vehicle then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
                return
            end
            repairSubMenu.close()
            performRepairAction("clean", vehicle)
        end)

        repairSubMenu.Button("Diagnostic véhicule", "Voir l'état du véhicule", nil, "chevron", false, function()
            local vehicle = getVehicleInFront(5.0)
            if not vehicle then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
                return
            end
            repairSubMenu.close()
            showDiagnosticUI(vehicle)
        end)

        repairSubMenu.Button("Mettre en fourrière", "Enlever le véhicule à proximité", nil, "chevron", false, function()
            local vehicle = getVehicleInFront(5.0)
            if not vehicle then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
                return
            end
            repairSubMenu.close()
            VFW.Jobs.SetVehicleInFourriere(vehicle)
        end)

        repairSubMenu.Button("Charger sur le plateau", "Charger un véhicule sur le tcguardow", nil, "chevron", false, function()
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous devez être à pied" })
                return
            end
            local vehicle = getVehicleInFront(5.0)
            if not vehicle then
                VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule devant vous" })
                return
            end
            repairSubMenu.close()
            LoadVehicleOnTcguardow(vehicle)
        end)

        repairSubMenu.Button("Décharger du plateau", "Décharger le véhicule du tcguardow", nil, "chevron", false, function()
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous devez être à pied" })
                return
            end
            repairSubMenu.close()
            UnloadVehicleFromTcguardow()
        end)
    end)

    -- Register mechanic menu builder
    registry.registerByType("mechanic", function(menu, subMenus)
        menu.Button("Action véhicule", "Actions disponibles sur le véhicule", nil, "chevron", false, function()
        end, subMenus.repair)
    end, 10)
end

if contextRegistry then
    -- Set custom submenu labels
    contextRegistry.setSubmenuLabelByType("mechanic", "vehicle", ":wrench: Actions Mécanicien")

    -- Condition commune : pas dans un véhicule
    local notInVehicle = function()
        return not IsPedInAnyVehicle(PlayerPedId(), false)
    end

    -- Vehicle Actions
    contextRegistry.registerVehicleByType("mechanic", {
        label = ":wrench: Réparer le moteur",
        condition = notInVehicle,
        callback = function(vehicle)
            if not isPlayerNearEngine(vehicle, 3.0) then
                VFW.ShowNotification({
                    type = 'ORANGE',
                    content = "Vous devez être devant le capot"
               })
                return
            end
            performRepairAction("engine", vehicle)
        end
    })

    contextRegistry.registerVehicleByType("mechanic", {
        label = ":car: Réparer la carrosserie",
        condition = notInVehicle,
        callback = function(vehicle)
            performRepairAction("body", vehicle)
        end
    })

    contextRegistry.registerVehicleByType("mechanic", {
        label = ":trash: Nettoyer le véhicule",
        condition = notInVehicle,
        callback = function(vehicle)
            performRepairAction("clean", vehicle)
        end
    })

    contextRegistry.registerVehicleByType("mechanic", {
        label = ":search: Diagnostic",
        condition = notInVehicle,
        callback = function(vehicle)
            showDiagnosticUI(vehicle)
        end
    })

    contextRegistry.registerVehicleByType("mechanic", {
        label = ":siren: Mettre en fourrière",
        condition = notInVehicle,
        callback = function(vehicle)
            VFW.Jobs.SetVehicleInFourriere(vehicle)
        end
    })

    contextRegistry.registerVehicleByType("mechanic", {
        label = ":box: Charger sur le plateau",
        condition = function()
            if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
            local tcguardow = GetClosestTcguardow(10.0)
            return tcguardow ~= nil
        end,
        callback = function(vehicle)
            LoadVehicleOnTcguardow(vehicle)
        end
    })

    contextRegistry.registerVehicleByType("mechanic", {
        label = ":box: Décharger du plateau",
        condition = function()
            if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
            local tcguardow = GetClosestTcguardow(10.0)
            if not tcguardow then return false end
            return GetVehicleOnTcguardow(tcguardow) ~= nil
        end,
        callback = function(_)
            UnloadVehicleFromTcguardow()
        end
    })
end
