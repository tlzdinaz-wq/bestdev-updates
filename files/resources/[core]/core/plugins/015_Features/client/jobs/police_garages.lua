-- ============================================================================
-- JOB GARAGES - PED interaction, spawn, despawn
-- ============================================================================

local policeGarages = {}
local activePeds = {}
local activeBlips = {}
local creatingPeds = {}
local currentGarageId = nil

local function createBlip(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function cleanupGarage(id)
    if activePeds[id] then
        if DoesEntityExist(activePeds[id]) then
            DeleteEntity(activePeds[id])
        end
        activePeds[id] = nil
    end
    if activeBlips[id] then
        RemoveBlip(activeBlips[id])
        activeBlips[id] = nil
    end
end

local function cleanup()
    for id, ped in pairs(activePeds) do
        if ped and DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    activePeds = {}

    for id, blip in pairs(activeBlips) do
        if blip then
            RemoveBlip(blip)
        end
    end
    activeBlips = {}
end

local function getFilteredVehicles(garage)
    local playerGrade = VFW.PlayerData.job.grade or 0
    local filtered = {}

    for _, veh in pairs(garage.vehicles or {}) do
        if type(veh) == "table" then
            local allowed = false
            if veh.allowedGrades and next(veh.allowedGrades) then
                -- New system: check if player grade is in allowed list
                allowed = veh.allowedGrades[tostring(playerGrade)] == true
            elseif veh.minGrade then
                -- Legacy fallback: grade minimum
                allowed = playerGrade >= (veh.minGrade or 0)
            else
                allowed = true
            end
            if allowed then
                filtered[#filtered + 1] = veh
            end
        end
    end

    return filtered
end

local function formatVehiclesForUI(vehicles)
    local formatted = {}
    for _, veh in ipairs(vehicles) do
        local override = Garage.LabelOverrides and Garage.LabelOverrides[(veh.model or ""):lower()]
        local label = override or veh.label
        if not label or label == "" then
            label = Garage.GetVehicleLabel(veh.model)
        end

        formatted[#formatted + 1] = {
            plate = veh.model,
            name = veh.model,
            vehName = veh.model,
            label = label,
            pounded = false,
            engineHealth = 1000,
            bodyHealth = 1000,
        }
    end
    return formatted
end

local jobGarageOpen = false

RegisterNetEvent("policeGarage:menuClosed", function()
    jobGarageOpen = false
end)

local function openGarageMenu(garage)
    currentGarageId = garage.id
    local filteredVehicles = getFilteredVehicles(garage)

    if #filteredVehicles == 0 then
        VFW.ShowNotification({ type = "ROUGE", content = "Aucun véhicule disponible pour votre grade." })
        return
    end

    local formatted = formatVehiclesForUI(filteredVehicles)

    -- Stocker les spawn positions pour le callback takeOut
    Garage.currentGarage = {
        id = garage.id,
        type = "jobGarage",
        spawnPosition = garage.spawnPositions,
    }
    jobGarageOpen = true

    SendNUIMessage({
        action = "nui:vehicleStorage:open",
        data = {
            type = "society",
            hasSecondaryGarage = false,
            location = "Garage " .. VFW.PlayerData.job.label,
            privateVehicles = {},
            societyVehicles = formatted,
            gangVehicles = {},
            factionVehicles = {},
            canManage = false,
            isSocietyStorage = true,
            isGangStorage = false,
            repairPrice = 0
        }
    })

    VFW.Nui.Focus(true, false)
    VFW.Nui.HudVisible(false)
end


local function setupGarage(garage)
    local pos = garage.position
    if not pos or not pos.x or not garage.id then return end

    if not activeBlips[garage.id] then
        local blipLabel = ("%s  • Garage - Voiture"):format(garage.name or "Garage")
        activeBlips[garage.id] = createBlip(vector3(pos.x, pos.y, pos.z), 357, 26, 0.5, blipLabel)
    end

    if creatingPeds[garage.id] then return end
    if activePeds[garage.id] and DoesEntityExist(activePeds[garage.id]) then return end

    creatingPeds[garage.id] = true
    local ped = VFW.CreatePed(pos, garage.pedModel or "a_m_m_prolhost_01")
    creatingPeds[garage.id] = nil

    if not ped or not DoesEntityExist(ped) then return end

    -- Race protection: if a parallel call already set activePeds, delete our duplicate
    if activePeds[garage.id] and DoesEntityExist(activePeds[garage.id]) and activePeds[garage.id] ~= ped then
        DeleteEntity(ped)
        return
    end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, true)
    activePeds[garage.id] = ped
end

-- Thread de proximité pour interagir avec les PED et les zones de despawn
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for id, garage in pairs(policeGarages) do
            local pos = garage.position
            if pos and pos.x then
                local dist = #(playerCoords - vector3(pos.x, pos.y, pos.z))

                -- Recreate the PED if streaming or another resource killed it
                if dist < 100.0 and (not activePeds[id] or not DoesEntityExist(activePeds[id])) then
                    setupGarage(garage)
                end

                if dist < 2.5 and not jobGarageOpen then
                    sleep = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder au garage.")
                    if VFW.Interact.JustPressed(0, 38) then -- E
                        if not VFW.PlayerData.job.onDuty then
                            VFW.ShowNotification({ type = "ROUGE", content = "Vous devez être en service." })
                        else
                            openGarageMenu(garage)
                        end
                    end
                end
            end

            local despawn = garage.despawnPosition
            if despawn and despawn.x then
                local despawnDist = #(playerCoords - vector3(despawn.x, despawn.y, despawn.z))
                if despawnDist < 15.0 then
                    sleep = 0
                    DrawMarker(36, despawn.x, despawn.y, despawn.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 255, false, false, 2, true, nil, false)
                end
                if despawnDist < 3.0 and IsPedInAnyVehicle(playerPed, false) then
                    sleep = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ranger le véhicule.")
                    if VFW.Interact.JustPressed(0, 38) then -- E
                        if not VFW.PlayerData.job.onDuty then
                            VFW.ShowNotification({ type = "ROUGE", content = "Vous devez être en service." })
                        else
                            local veh = GetVehiclePedIsIn(playerPed, false)
                            local plate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
                            local netId = VehToNet(veh)
                            TriggerServerEvent("vfw:vehicle:keyTemporarly:remove", "job", plate)
                            TriggerServerEvent("core:deletesyncItem", netId)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

local function loadGarages(garages)
    garages = garages or {}

    -- Diff: drop garages that no longer exist
    for id in pairs(policeGarages) do
        if not garages[id] then
            cleanupGarage(id)
        end
    end

    policeGarages = garages

    for id, garage in pairs(policeGarages) do
        garage.id = garage.id or id
        setupGarage(garage)
        Wait(25)
    end
end

local function registerNuiCallbacks(garageId)
    local callbackName = ("policeGarage_%d"):format(garageId)

    RegisterNuiCallback(("nui:newgrandcatalogue:%s:selectHeadCategory"):format(callbackName), function(data)
        if not data then return end
        currentCategory = data

        local garage = policeGarages[garageId]
        if not garage then return end

        local filtered = getFilteredVehicles(garage)
        local byCategory = getVehiclesByCategory(filtered)
        local availableCategories = getAvailableCategories(byCategory)

        Wait(50)
        VFW.Nui.UpdateBigMenu({
            style = {
                menuStyle = "custom",
                backgroundType = 1,
                bannerType = 2,
                gridType = 1,
                buyType = 2,
                bannerImg = ("assets/catalogues/headers/header_%s.webp"):format(VFW.PlayerData.job.name),
                buyTextType = false,
                buyText = "Selectionner",
            },
            eventName = callbackName,
            category = { show = false },
            cameras = { show = false },
            nameContainer = { show = false },
            headCategory = {
                show = #availableCategories > 1,
                items = availableCategories
            },
            showStats = { show = false },
            mouseEvents = false,
            color = { show = false },
            items = byCategory[currentCategory] or {}
        })
    end)

    RegisterNuiCallback(("nui:newgrandcatalogue:%s:selectBuy"):format(callbackName), function(vehicleModel)
        VFW.Nui.BigMenu(false)
        jobGarageOpen = false

        local garage = policeGarages[garageId]
        if not garage then return end

        local allowed = TriggerServerCallback("policeGarage:validateSpawn", garageId, vehicleModel)
        if not allowed then
            VFW.ShowNotification({ type = "ROUGE", content = "Vous n'avez pas le grade requis pour ce véhicule." })
            return
        end

        -- Résoudre les spawn points (supporte array ou objet unique)
        local spawnPoints = garage.spawnPositions
        if not spawnPoints then
            VFW.ShowNotification({ type = "ROUGE", content = "Aucun point de spawn configuré." })
            return
        end

        -- Normaliser en array si c'est un objet unique {x,y,z,w}
        if spawnPoints.x then
            spawnPoints = { spawnPoints }
        end

        if #spawnPoints == 0 then
            VFW.ShowNotification({ type = "ROUGE", content = "Aucun point de spawn configuré." })
            return
        end

        -- Trouver un point de spawn libre
        local sp = nil
        for _, point in ipairs(spawnPoints) do
            local occupied = false
            local closestVeh = GetClosestVehicle(point.x, point.y, point.z, 3.0, 0, 70)
            if closestVeh and closestVeh ~= 0 and DoesEntityExist(closestVeh) then
                occupied = true
            end
            if not occupied then
                sp = point
                break
            end
        end

        if not sp then
            VFW.ShowNotification({ type = "ROUGE", content = "Tous les emplacements de spawn sont occupés." })
            return
        end

        -- Résoudre le type de véhicule côté client avant d'envoyer au serveur
        local vehicleType = VFW.GetVehicleTypeClient(joaat(vehicleModel))
        if not vehicleType then
            VFW.ShowNotification({ type = "ROUGE", content = "Ce modèle de véhicule n'est pas valide: " .. tostring(vehicleModel) })
            return
        end

        TriggerServerEvent("policeGarage:spawnVehicle", vehicleModel, garageId, sp, vehicleType)
    end)

    RegisterNuiCallback(("nui:newgrandcatalogue:%s:close"):format(callbackName), function()
        VFW.Nui.BigMenu(false)
        currentGarageId = nil
        jobGarageOpen = false
    end)
end

-- Net events

RegisterNetEvent("policeGarage:spawnSuccess", function(networkId)
    -- Le warp est déjà fait côté serveur, on attend juste que l'entité soit visible
    local timeout = 0
    while not NetworkDoesEntityExistWithNetworkId(networkId) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    local vehicle = NetworkGetEntityFromNetworkId(networkId)
    if not DoesEntityExist(vehicle) then return end

    local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
    TriggerServerEvent("vfw:vehicle:keyTemporarly:add", "job", plate)
    SetVehicleMod(vehicle, 11, 2, false)
    SetVehicleMod(vehicle, 12, 2, false)
    SetVehicleMod(vehicle, 13, 2, false)
    SetVehicleFuelLevel(vehicle, 100.0)
    Entity(vehicle).state:set("fuel", 100.0, true)
    Entity(vehicle).state:set("VehicleProperties", VFW.Game.GetVehicleProperties(vehicle), true)
    TriggerServerEvent("core:jobs:addChest", plate)
end)

RegisterNetEvent("policeGarage:spawnFailed", function(reason)
    VFW.ShowNotification({ type = "ROUGE", content = reason or "Impossible de faire spawner le véhicule." })
end)

RegisterNetEvent("policeGarage:load", function(garages)
    for id in pairs(garages) do
        registerNuiCallbacks(id)
    end
    loadGarages(garages)
end)

RegisterNetEvent("policeGarage:added", function(garage)
    -- Ignorer si le garage n'est pas pour notre job (sécurité client)
    if garage.job and VFW.PlayerData.job and garage.job ~= VFW.PlayerData.job.name then return end
    policeGarages[garage.id] = garage
    registerNuiCallbacks(garage.id)
    setupGarage(garage)
end)

RegisterNetEvent("policeGarage:updated", function(garage)
    if garage.job and VFW.PlayerData.job and garage.job ~= VFW.PlayerData.job.name then return end
    cleanupGarage(garage.id)
    policeGarages[garage.id] = garage
    setupGarage(garage)
end)

RegisterNetEvent("policeGarage:removed", function(garageId)
    if not policeGarages[garageId] then return end
    policeGarages[garageId] = nil
    cleanupGarage(garageId)
end)

RegisterNetEvent("vfw:setJob", function(Job, lastJob)
    -- No client-side wipe here: the server resends policeGarage:load (even empty)
    -- right after vfw:setJob, and loadGarages' diff handles cleanup of stale peds.
    -- Wiping here races with policeGarage:load and would erase newly-created peds.
    currentGarageId = nil
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        cleanup()
    end
end)

-- ============================================================================
-- GESTION GARAGE POLICE - Menu job (boss/patron)
-- ============================================================================

local categoryLabels = { "defaut" }

local function hasBossPermissions()
    local job = VFW.PlayerData.job
    if not job or not job.onDuty then return false end
    return job.grade_is_boss or (job.perms and job.perms.manage_permissions)
end

-- Wait for the registry export to be available, then register
CreateThread(function()
    while not exports.core or not exports.core.getJobMenuRegistry do
        Wait(500)
    end

    local registry = exports.core:getJobMenuRegistry()
    if not registry then return end

    -- Create submenus for garage management
    local garageListSub = registry.createSubMenuByType("police", "policeGarageList", "Garage Police")
    local garageCreateSub = registry.createSubMenuByType("police", "policeGarageCreate", "Créer un garage")
    local garageEditSub = registry.createSubMenuByType("police", "policeGarageEdit", "Modifier le garage")
    local garageVehiclesSub = registry.createSubMenuByType("police", "policeGarageVehicles", "Véhicules du garage")
    local garageAddVehSub = registry.createSubMenuByType("police", "policeGarageAddVeh", "Ajouter un véhicule")

    -- Local state for management
    local garageSelected = nil
    local currentVehicle = {}

    local function getDefaultGarageData()
        return {
            name = nil,
            job = nil,
            position = {},
            spawnPositions = {},
            despawnPosition = {},
            vehicles = {},
            pedModel = "s_m_y_cop_01"
        }
    end

    -- Garage management removed from F4 — use staff menu (F5) instead

    -- Garage list submenu
    garageListSub.OnOpen(function()
        local garages = TriggerServerCallback("policeGarage:getForJob", VFW.PlayerData.job.name)

        garageListSub.Button("Créer un garage", "", nil, "chevron", false, function()
            garageSelected = getDefaultGarageData()
            garageSelected.job = VFW.PlayerData.job.name
        end, garageCreateSub)

        garageListSub.Separator("Garages existants")

        if garages and next(garages) then
            for id, data in pairs(garages) do
                garageListSub.Button(
                    ("%s (ID: %d)"):format(data.name, id),
                    ("%d véhicule%s"):format(#(data.vehicles or {}), #(data.vehicles or {}) > 1 and "s" or ""),
                    nil, "chevron", false, function()
                        garageSelected = data
                    end, garageEditSub
                )
            end
        else
            garageListSub.Button("Aucun garage", "", nil, nil, true, function() end)
        end
    end)

    -- Create form
    garageCreateSub.OnOpen(function()
        garageCreateSub.Button("Nom du garage", "", garageSelected.name and "Défini" or "Non défini", "chevron", false, function()
            local name = VFW.Nui.KeyboardInput(true, "Entrez le nom du garage")
            if not name or name == "" then return end
            garageSelected.name = name
            garageCreateSub.refresh()
        end)

        garageCreateSub.Button("Position du garage", "Se placer à l'endroit voulu", garageSelected.position.x and "Définie" or "Non définie", "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
            garageCreateSub.refresh()
        end)

        garageCreateSub.Button("Spawn des véhicules", "Se placer à l'endroit de spawn", garageSelected.spawnPositions and garageSelected.spawnPositions.x and "Définie" or "Non définie", "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            garageSelected.spawnPositions = { x = pos.x, y = pos.y, z = pos.z, w = GetEntityHeading(ped) }
            garageCreateSub.refresh()
        end)

        garageCreateSub.Button("Zone despawn", "Se placer à la zone de rangement", garageSelected.despawnPosition.x and "Définie" or "Non définie", "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            garageSelected.despawnPosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
            garageCreateSub.refresh()
        end)

        garageCreateSub.Button("Modèle du PED", "", garageSelected.pedModel, "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle du PED", garageSelected.pedModel or "")
            if not model or model == "" then return end
            garageSelected.pedModel = model
            garageCreateSub.refresh()
        end)

        garageCreateSub.Button("Gérer les véhicules", ("(%d)"):format(#garageSelected.vehicles), nil, "chevron", false, function()
        end, garageVehiclesSub)

        garageCreateSub.Separator()

        garageCreateSub.Button("Créer le garage", "", nil, "chevron", false, function()
            if not garageSelected.name then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir le nom du garage." })
                return
            end
            if not garageSelected.position.x or not (garageSelected.spawnPositions and garageSelected.spawnPositions.x) then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir la position et le spawn." })
                return
            end

            TriggerServerEvent("policeGarage:create", garageSelected)
            garageSelected = getDefaultGarageData()
            garageCreateSub.close()
        end)
    end)

    -- Edit form
    garageEditSub.OnOpen(function()
        if not garageSelected then return end

        garageEditSub.Button("Nom", "", garageSelected.name or "?", "chevron", false, function()
            local name = VFW.Nui.KeyboardInput(true, "Nom du garage", garageSelected.name or "")
            if not name or name == "" then return end
            garageSelected.name = name
            garageEditSub.refresh()
        end)

        garageEditSub.Button("Position du garage", "", garageSelected.position and garageSelected.position.x and "Définie" or "Non définie", "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
            garageEditSub.refresh()
        end)

        garageEditSub.Button("Spawn des véhicules", "Se placer à l'endroit de spawn", garageSelected.spawnPositions and garageSelected.spawnPositions.x and "Définie" or "Non définie", "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            garageSelected.spawnPositions = { x = pos.x, y = pos.y, z = pos.z, w = GetEntityHeading(ped) }
            garageEditSub.refresh()
        end)

        garageEditSub.Button("Zone despawn", "", garageSelected.despawnPosition and garageSelected.despawnPosition.x and "Définie" or "Non définie", "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            garageSelected.despawnPosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
            garageEditSub.refresh()
        end)

        garageEditSub.Button("Modèle du PED", "", garageSelected.pedModel or "s_m_y_cop_01", "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle du PED", garageSelected.pedModel or "")
            if not model or model == "" then return end
            garageSelected.pedModel = model
            garageEditSub.refresh()
        end)

        garageEditSub.Button("Véhicules", ("(%d)"):format(#(garageSelected.vehicles or {})), nil, "chevron", false, function()
        end, garageVehiclesSub)

        garageEditSub.Separator()

        garageEditSub.Button("Sauvegarder", "", nil, "chevron", false, function()
            if not garageSelected.name then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir le nom." })
                return
            end
            if not garageSelected.position or not garageSelected.position.x then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir la position." })
                return
            end
            if not garageSelected.spawnPositions or not garageSelected.spawnPositions.x then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir le spawn." })
                return
            end

            TriggerServerEvent("policeGarage:update", garageSelected.id, garageSelected)
            garageSelected = nil
            garageEditSub.close()
        end)

        garageEditSub.Button("Supprimer le garage", "", nil, "trash", false, function()
            TriggerServerEvent("policeGarage:delete", garageSelected.id)
            garageSelected = nil
            garageEditSub.close()
        end)
    end)

    -- Vehicle list submenu (shared for create & edit)
    garageVehiclesSub.OnOpen(function()
        if not garageSelected then return end

        garageVehiclesSub.Button("Ajouter un véhicule", "", nil, "chevron", false, function()
            currentVehicle = {}
        end, garageAddVehSub)

        if garageSelected.vehicles and #garageSelected.vehicles > 0 then
            garageVehiclesSub.Separator("Véhicules")
        end

        for i, veh in ipairs(garageSelected.vehicles or {}) do
            garageVehiclesSub.Button(
                veh.label or veh.model,
                ("Modèle: %s | Grade min: %d | Cat: %s"):format(veh.model, veh.minGrade or 0, veh.category or "service"),
                nil, "trash", false, function()
                    table.remove(garageSelected.vehicles, i)
                    garageVehiclesSub.refresh()
                end
            )
        end
    end)

    -- Add vehicle form
    garageAddVehSub.OnOpen(function()
        garageAddVehSub.Button("Modèle", "Nom spawn du véhicule", currentVehicle.model and "Défini" or "Non défini", "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (ex: police3)")
            if not model or model == "" then return end
            currentVehicle.model = model
            garageAddVehSub.refresh()
        end)

        garageAddVehSub.Button("Label", "Nom affiché", currentVehicle.label and "Défini" or "Non défini", "chevron", false, function()
            local label = VFW.Nui.KeyboardInput(true, "Label du véhicule (ex: Police Cruiser)")
            if not label or label == "" then return end
            currentVehicle.label = label
            garageAddVehSub.refresh()
        end)

        garageAddVehSub.Button("Grade minimum", "Grade requis pour sortir ce véhicule", tostring(currentVehicle.minGrade or 0), "chevron", false, function()
            local grade = tonumber(VFW.Nui.KeyboardInput(true, "Grade minimum (0 = tous)", tostring(currentVehicle.minGrade or 0)))
            if not grade or grade < 0 then grade = 0 end
            currentVehicle.minGrade = grade
            garageAddVehSub.refresh()
        end)

        garageAddVehSub.List("Catégorie", nil, false, categoryLabels, currentVehicle.categoryIndex or 1, function(index)
            currentVehicle.categoryIndex = index
            currentVehicle.category = categoryLabels[index]
        end)

        garageAddVehSub.Separator()

        garageAddVehSub.Button("Ajouter le véhicule", "", nil, "chevron", false, function()
            if not currentVehicle.model or currentVehicle.model == "" then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir un modèle." })
                return
            end
            if not currentVehicle.label or currentVehicle.label == "" then
                VFW.ShowNotification({ type = "ROUGE", content = "Veuillez définir un label." })
                return
            end

            if not garageSelected.vehicles then
                garageSelected.vehicles = {}
            end

            garageSelected.vehicles[#garageSelected.vehicles + 1] = {
                model = currentVehicle.model,
                label = currentVehicle.label,
                minGrade = currentVehicle.minGrade or 0,
                category = currentVehicle.category or "service"
            }

            currentVehicle = {}
            garageVehiclesSub.open()
        end)
    end)
end)
