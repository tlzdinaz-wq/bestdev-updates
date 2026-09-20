local selectedLocationId = nil
local configData = nil
local newLocationData = {}
local previewVehicles = {}
local previewActive = false
local isRefreshing = false

local NPC_MODELS <const> = {
    { label = "Dealer", model = "s_m_y_dealer_01", image = VFW.CDN.Get("others/vehicle_sell_seller.png") },
    { label = "Business", model = "a_m_y_business_02", image = VFW.CDN.Get("others/vehicle_sell_a_m_y_business_02.webp") },
    { label = "Beverly Hills jeune", model = "a_m_y_bevhills_02", image = VFW.CDN.Get("others/vehicle_sell_a_m_y_bevhills_02.webp") },
    { label = "Autoshop", model = "s_m_m_autoshop_02", image = VFW.CDN.Get("others/vehicle_sell_s_m_m_autoshop_02.webp") },
    { label = "Beverly Hills", model = "a_m_m_bevhills_01", image = VFW.CDN.Get("others/vehicle_sell_a_m_m_bevhills_01.webp") },
}

local function destroyPreviews()
    for _, vehicle in pairs(previewVehicles) do
        if vehicle and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    previewVehicles = {}
    previewActive = false
end

local function spawnPreviews()
    destroyPreviews()
    if not configData or not configData.parking_spots then return end

    previewActive = true

    for i, spot in ipairs(configData.parking_spots) do
        local vehicle = VFW.Game.SpawnVehicle("sultan", vector3(spot.x, spot.y, spot.z), spot.w or 0.0, nil, false)
        if vehicle and vehicle ~= 0 then
            SetVehicleOnGroundProperly(vehicle)
            FreezeEntityPosition(vehicle, true)
            SetEntityCollision(vehicle, false, false)
            SetEntityCompletelyDisableCollision(vehicle, false, false)
            SetEntityAlpha(vehicle, 120, false)
            SetEntityInvincible(vehicle, true)
            SetVehicleDoorsLocked(vehicle, 2)
            previewVehicles[i] = vehicle
        end
    end

    local spotCoords = {}
    for i, spot in ipairs(configData.parking_spots) do
        spotCoords[i] = vector3(spot.x, spot.y, spot.z + 1.5)
    end

    CreateThread(function()
        while previewActive do
            local playerCoords = GetEntityCoords(PlayerPedId())
            for i, _ in pairs(previewVehicles) do
                if spotCoords[i] and #(playerCoords - spotCoords[i]) < 10.0 then
                    VFW.Game.Utils.DrawText3D(spotCoords[i], "Emplacement #" .. i)
                end
            end
            Wait(0)
        end
    end)
end

local function fcRefresh(Menu)
    isRefreshing = true
    local savedStack = {}
    if VUI_MenuStack then
        for i, v in ipairs(VUI_MenuStack) do savedStack[i] = v end
    end
    Menu.refresh()
    VUI_MenuStack = savedStack
    isRefreshing = false
end

local function fcCoordsStr(c)
    if not c or (c.x == 0 and c.y == 0 and c.z == 0) then return "Non défini" end
    return ("%.2f, %.2f, %.2f"):format(c.x, c.y, c.z)
end

local function fcGetModelLabel(model)
    for _, m in ipairs(NPC_MODELS) do
        if m.model == model then return m.label end
    end
    return model or "Non défini"
end

local function fcGetImageForModel(model)
    for _, m in ipairs(NPC_MODELS) do
        if m.model == model then return m.image end
    end
    return NPC_MODELS[1].image
end

local function showImagePreview(data)
    local image = data.npc_image or fcGetImageForModel(data.npc_model)
    VFW.ShowNotification({
        type = "JOB",
        title = "Vendeur Vehicule",
        subtitle = "Preview",
        image = image,
        content = "Apercu de la notification avec cette image."
  })
end

local function buildModelChoices(currentModel)
    local choices = {}
    for _, m in ipairs(NPC_MODELS) do
        if m.model == currentModel then
            table.insert(choices, 1, { label = m.label, value = m.model })
        else
            choices[#choices + 1] = { label = m.label, value = m.model }
        end
    end
    return choices
end

local function getDefaultConfig()
    return {
        name = "Point de vente",
        npc_coords = {x = 0, y = 0, z = 0, w = 0},
        npc_model = NPC_MODELS[1].model,
        parking_spots = {},
        interaction_distance = 2.0,
        vehicle_detection_distance = 15.0,
        zone_distance = 100.0,
        price_min = 1,
        price_max = 100000000,
        sale_cooldown = 30,
        sale_duration_days = 15,
        npc_image = NPC_MODELS[1].image
    }
end

StaffMenu.builderVehicleSell.OnOpen(function()
    StaffMenu.builderVehicleSell.Separator("VENTE VEHICULES")

    StaffMenu.builderVehicleSell.Button("Creer un point de vente", "Ajouter un nouveau point de vente", nil, "chevron", false, function()
        newLocationData = getDefaultConfig()
    end, StaffMenu.vehicleSellCreate)

    StaffMenu.builderVehicleSell.Button("Gerer les points de vente", "Modifier ou supprimer", nil, "chevron", false, function()
    end, StaffMenu.vehicleSellList)
end)

StaffMenu.vehicleSellCreate.OnOpen(function()
    StaffMenu.vehicleSellCreate.Separator("NOUVEAU POINT DE VENTE")

    StaffMenu.vehicleSellCreate.Button("Nom: " .. (newLocationData.name or ""), "Définir le nom", nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom du point de vente", newLocationData.name or "")
        if sInput and sInput ~= "" then
            newLocationData.name = sInput
            fcRefresh(StaffMenu.vehicleSellCreate)
        end
    end)

    StaffMenu.vehicleSellCreate.Button("Emplacement PNJ: " .. fcCoordsStr(newLocationData.npc_coords), "Se placer et cliquer", nil, newLocationData.npc_coords.x ~= 0 and "check" or "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        newLocationData.npc_coords = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = "Position PNJ définie." })
        fcRefresh(StaffMenu.vehicleSellCreate)
    end)

    StaffMenu.vehicleSellCreate.Button("Modele PNJ: " .. fcGetModelLabel(newLocationData.npc_model), "Configure automatiquement l'image notification", nil, "chevron", false, function()
        local result = VFW.Nui.ChoiceInput("Modele PNJ", "Le modele configure automatiquement l'image de notification", buildModelChoices(newLocationData.npc_model))
        if result then
            newLocationData.npc_model = result
            newLocationData.npc_image = fcGetImageForModel(result)
            showImagePreview(newLocationData)
            fcRefresh(StaffMenu.vehicleSellCreate)
        end
    end)

    StaffMenu.vehicleSellCreate.Button("Image notification: " .. fcGetModelLabel(newLocationData.npc_model), "Cliquer pour previsualiser", nil, "chevron", false, function()
        showImagePreview(newLocationData)
    end)

    local spotCount = newLocationData.parking_spots and #newLocationData.parking_spots or 0
    StaffMenu.vehicleSellCreate.Button("Emplacements parking: " .. spotCount, "Ajouter des places de stationnement", nil, spotCount > 0 and "check" or "chevron", false, function()
        configData = newLocationData
    end, StaffMenu.vehicleSellCreateParking)

    StaffMenu.vehicleSellCreate.Separator("VALIDATION")

    local npcValid = newLocationData.npc_coords and newLocationData.npc_coords.x ~= 0
    local spotsValid = newLocationData.parking_spots and #newLocationData.parking_spots > 0

    StaffMenu.vehicleSellCreate.Button("Creer le point de vente", npcValid and spotsValid and "Pret" or "Position PNJ et emplacements requis", nil, npcValid and spotsValid and "check" or nil, not (npcValid and spotsValid), function()
        local newId = TriggerServerCallback("vehicleSell:createConfig", newLocationData)
        if newId then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = ("Point de vente #%d créé."):format(newId) })
            StaffMenu.vehicleSellCreate.close()
            Wait(100)
            StaffMenu.vehicleSellList.refresh()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Vente Vehicules', message = "Erreur lors de la creation." })
        end
    end)
end)

StaffMenu.vehicleSellList.OnOpen(function()
    StaffMenu.vehicleSellList.Separator("POINTS DE VENTE")

    local configs = TriggerServerCallback("vehicleSell:getAllConfigs") or {}

    local count = 0
    for locationId, cfg in pairs(configs) do
        local displayName = cfg.name or ("Point #" .. locationId)
        local spotCount = cfg.parking_spots and #cfg.parking_spots or 0
        StaffMenu.vehicleSellList.Button(
            displayName,
            ("ID: %d | %d emplacements"):format(locationId, spotCount),
            nil, "chevron", false,
            function()
                selectedLocationId = locationId
                configData = TriggerServerCallback("vehicleSell:getConfig", locationId) or cfg
            end,
            StaffMenu.vehicleSellEdit
        )
        count = count + 1
    end

    if count == 0 then
        StaffMenu.vehicleSellList.Button("Aucun point de vente", "Créez-en un d'abord", nil, nil, true, function() end)
    end
end)

StaffMenu.vehicleSellEdit.OnOpen(function()
    if not configData or not selectedLocationId then return end

    StaffMenu.vehicleSellEdit.Separator("EDITION - " .. (configData.name or ""))

    StaffMenu.vehicleSellEdit.Button("Nom: " .. (configData.name or ""), "Modifier le nom", nil, "chevron", false, function()
        local sInput = VFW.Nui.KeyboardInput(true, "Nom du point de vente", configData.name or "")
        if sInput and sInput ~= "" then
            configData.name = sInput
            fcRefresh(StaffMenu.vehicleSellEdit)
        end
    end)

    StaffMenu.vehicleSellEdit.Button("Emplacement PNJ: " .. fcCoordsStr(configData.npc_coords), "Se placer et cliquer", nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        configData.npc_coords = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = "Position PNJ définie." })
        fcRefresh(StaffMenu.vehicleSellEdit)
    end)

    StaffMenu.vehicleSellEdit.Button("Modele PNJ: " .. fcGetModelLabel(configData.npc_model), "Configure automatiquement l'image notification", nil, "chevron", false, function()
        local result = VFW.Nui.ChoiceInput("Modele PNJ", "Le modele configure automatiquement l'image de notification", buildModelChoices(configData.npc_model))
        if result then
            configData.npc_model = result
            configData.npc_image = fcGetImageForModel(result)
            showImagePreview(configData)
            fcRefresh(StaffMenu.vehicleSellEdit)
        end
    end)

    StaffMenu.vehicleSellEdit.Button("Image notification: " .. fcGetModelLabel(configData.npc_model), "Cliquer pour previsualiser", nil, "chevron", false, function()
        showImagePreview(configData)
    end)

    local spotCount = configData.parking_spots and #configData.parking_spots or 0
    StaffMenu.vehicleSellEdit.Button("Emplacements parking: " .. spotCount, "Gerer les places de stationnement", nil, "chevron", false, function()
    end, StaffMenu.vehicleSellParking)

    StaffMenu.vehicleSellEdit.Separator("ACTIONS")

    StaffMenu.vehicleSellEdit.Button("Sauvegarder", "Enregistrer la configuration", nil, "check", false, function()
        TriggerServerEvent("vehicleSell:saveConfig", selectedLocationId, configData)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = "Configuration sauvegardée." })
    end)

    StaffMenu.vehicleSellEdit.Button("Supprimer ce point de vente", "Suppression définitive", nil, "trash", false, function()
        VFW.Nui.Focus(true)
        local bResponse = VFW.Nui.ConfirmPopup("Suppression", ("Supprimer le point de vente #%d ?"):format(selectedLocationId))
        VFW.Nui.Focus(false)
        if bResponse then
            local success = TriggerServerCallback("vehicleSell:deleteConfig", selectedLocationId)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = "Point de vente supprimé." })
                selectedLocationId = nil
                configData = nil
                StaffMenu.vehicleSellEdit.close()
                Wait(100)
                StaffMenu.vehicleSellList.refresh()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Vente Vehicules', message = "Impossible de supprimer (ventes actives ?)." })
            end
        end
    end)
end)

local function buildParkingMenu(menu)
    menu.ClearItems()
    if not configData then return end

    menu.Separator("EMPLACEMENTS PARKING")

    menu.Button("Preview", previewActive and "Masquer" or "Afficher les previews", nil, previewActive and "check" or "chevron", false, function()
        if previewActive then
            destroyPreviews()
        else
            spawnPreviews()
        end
        fcRefresh(menu)
    end)

    menu.Button("Ajouter un emplacement", "Se placer et cliquer", nil, "chevron", false, function()
        local pos = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        if not configData.parking_spots then configData.parking_spots = {} end
        configData.parking_spots[#configData.parking_spots + 1] = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = heading }
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = "Emplacement #" .. #configData.parking_spots .. " ajouté." })
        if previewActive then spawnPreviews() end
        fcRefresh(menu)
    end)

    menu.Separator((#(configData.parking_spots or {}) > 1 and "%d EMPLACEMENTS" or "%d EMPLACEMENT"):format(#(configData.parking_spots or {})))

    if not configData.parking_spots or #configData.parking_spots == 0 then
        menu.Button("Aucun emplacement", "", nil, nil, true, function() end)
    else
        for i, spot in ipairs(configData.parking_spots) do
            menu.Button("Emplacement #" .. i, ("%.2f, %.2f, %.2f, h: %.1f"):format(spot.x, spot.y, spot.z, spot.w or 0), nil, "trash", false, function()
                table.remove(configData.parking_spots, i)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Vente Vehicules', message = "Emplacement supprimé." })
                if previewActive then spawnPreviews() end
                fcRefresh(menu)
            end)
        end
    end
end

StaffMenu.vehicleSellParking.OnOpen(function()
    buildParkingMenu(StaffMenu.vehicleSellParking)
end)

StaffMenu.vehicleSellParking.OnClose(function()
    if not isRefreshing then
        destroyPreviews()
    end
end)

StaffMenu.vehicleSellCreateParking.OnOpen(function()
    buildParkingMenu(StaffMenu.vehicleSellCreateParking)
end)

StaffMenu.vehicleSellCreateParking.OnClose(function()
    if not isRefreshing then
        destroyPreviews()
    end
end)
