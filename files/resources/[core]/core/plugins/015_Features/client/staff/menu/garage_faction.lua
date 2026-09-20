local function getGarageDefaultData()
    return {
        vehType = 1,
        name = nil,
        type = "faction",
        position = {},
        spawnPosition = {},
        deletePosition = {},
        vehicles = {},
        currentVehicle = {},
        access = {},
        secondaryGarage = false
    }
end

local garageSelected = getGarageDefaultData()
local garages = {}
local factionsList = {}
local factionsNames = {}

local VUI = exports["VUI"]

local vehicleType <const> = {"voiture/moto", "bateaux", "avion"}

-- Charger la liste des factions
local function loadFactions()
    local factions = TriggerServerCallback("core:gestion-factions:getAll")
    factionsList = factions or {}
    factionsNames = {}
    for i, faction in ipairs(factionsList) do
        factionsNames[i] = faction.label or faction.name
    end
end

local adminBanner = exports["core"]:GetVUIBanner("admin")
StaffMenu.createGarageFactionData = VUI:CreateSubMenu(StaffMenu.createGarageFaction, "CRÉATION DE GARAGE", adminBanner, true)
StaffMenu.addVehicleToGarageFaction = VUI:CreateSubMenu(StaffMenu.createGarageFactionData, "AJOUT DE VÉHICULES", adminBanner, true)
StaffMenu.addVehicleToGarageFactionData = VUI:CreateSubMenu(StaffMenu.addVehicleToGarageFaction, "DONNEES DU VÉHICULE", adminBanner, true)
StaffMenu.modifyGarageFactionData = VUI:CreateSubMenu(StaffMenu.createGarageFaction, "MODIFICATION DE GARAGE", adminBanner, true)
StaffMenu.modifyGarageFactionDataPreview = VUI:CreateSubMenu(StaffMenu.modifyGarageFactionData, "APERÇU DES VÉHICULES", adminBanner, true)

local FACTION_GARAGES_PER_PAGE = 25
StaffMenu.factionGaragePage = StaffMenu.factionGaragePage or 1
StaffMenu.factionGarageSearch = StaffMenu.factionGarageSearch or nil

function StaffMenu.BuildCreateGarageFaction()
    StaffMenu.createGarageFaction.ClearItems()
    garages = TriggerServerCallback("core:getAllGarages", "faction")

    StaffMenu.createGarageFaction.Button("Ajouter un garage", "", nil, "chevron", false, function()
        garageSelected = getGarageDefaultData()
    end, StaffMenu.createGarageFactionData)

    local searchLabel = StaffMenu.factionGarageSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.factionGarageSearch == nil and "Nom du garage / faction" or StaffMenu.factionGarageSearch
    StaffMenu.createGarageFaction.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.factionGarageSearch ~= nil then
            StaffMenu.factionGarageSearch = nil
            StaffMenu.factionGaragePage = 1
            StaffMenu.createGarageFaction.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du garage / faction")
        if query == nil or query == "" then return end
        StaffMenu.factionGarageSearch = query
        StaffMenu.factionGaragePage = 1
        StaffMenu.createGarageFaction.refresh()
    end)

    -- Flat list
    local flat = {}
    for factionName, garagesByType in pairs(garages or {}) do
        for id, garageData in pairs(garagesByType or {}) do
            table.insert(flat, { id = id, faction = factionName, data = garageData })
        end
    end
    table.sort(flat, function(a, b)
        local an, bn = (a.data.name or ""):lower(), (b.data.name or ""):lower()
        return an < bn
    end)

    local filtered = flat
    if StaffMenu.factionGarageSearch and StaffMenu.factionGarageSearch ~= "" then
        local q = StaffMenu.factionGarageSearch:lower()
        filtered = {}
        for _, e in ipairs(flat) do
            if (e.data.name or ""):lower():find(q, 1, true) or (e.faction or ""):lower():find(q, 1, true) then
                table.insert(filtered, e)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / FACTION_GARAGES_PER_PAGE), 1)
    if StaffMenu.factionGaragePage > totalPages then StaffMenu.factionGaragePage = totalPages end
    if StaffMenu.factionGaragePage < 1 then StaffMenu.factionGaragePage = 1 end
    local startIdx = (StaffMenu.factionGaragePage - 1) * FACTION_GARAGES_PER_PAGE + 1
    local endIdx = math.min(startIdx + FACTION_GARAGES_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.factionGarageSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d garages de faction, page %d sur %d", totalItems, StaffMenu.factionGaragePage, totalPages)
    end
    StaffMenu.createGarageFaction.Separator(header)

    if totalItems == 0 then
        StaffMenu.createGarageFaction.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function()end)
        return
    end

    for idx = startIdx, endIdx do
        local e = filtered[idx]
        StaffMenu.createGarageFaction.Button(("Garage | %s | id : %s"):format(e.data.name, e.id), e.faction, nil, "chevron", false, function()
            garageSelected = e.data
        end, StaffMenu.modifyGarageFactionData)
    end

    if totalPages > 1 then
        StaffMenu.createGarageFaction.Separator(nil)
        if StaffMenu.factionGaragePage > 1 then
            StaffMenu.createGarageFaction.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.factionGaragePage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.factionGaragePage = StaffMenu.factionGaragePage - 1
                StaffMenu.createGarageFaction.refresh()
            end)
        end
        if StaffMenu.factionGaragePage < totalPages then
            StaffMenu.createGarageFaction.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.factionGaragePage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.factionGaragePage = StaffMenu.factionGaragePage + 1
                StaffMenu.createGarageFaction.refresh()
            end)
        end
    end
end

StaffMenu.createGarageFactionData.OnOpen(function()
    loadFactions()

    StaffMenu.createGarageFactionData.Button("Nom du garage", "", garageSelected.name or "Non défini", "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du garage")

        if not name or name == "" then
            return
        end

        garageSelected.name = name
        StaffMenu.createGarageFactionData.refresh()
    end)

    StaffMenu.createGarageFactionData.List('Type de véhicules', nil, false, vehicleType, garageSelected.vehType, function(Index)
        garageSelected.vehType = Index
    end)

    -- Trouver l'index de la faction sélectionnée
    local selectedFactionIndex = 1
    if garageSelected.access.name then
        for i, faction in ipairs(factionsList) do
            if faction.name == garageSelected.access.name then
                selectedFactionIndex = i
                break
            end
        end
    end

    StaffMenu.createGarageFactionData.List('Faction', nil, false, factionsNames, selectedFactionIndex, function(Index)
        local selectedFaction = factionsList[Index]
        if selectedFaction then
            garageSelected.access.name = selectedFaction.name
            garageSelected.access.rank = 98 -- Chef et co-chef uniquement (98+)
        end
    end)


    local posDisplay = garageSelected.position.x and ("%.1f, %.1f, %.1f"):format(garageSelected.position.x, garageSelected.position.y, garageSelected.position.z) or "Non défini"
  StaffMenu.createGarageFactionData.Button("Position du garage", "", posDisplay, "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
        StaffMenu.createGarageFactionData.refresh()
    end)

    local spawnCount = garageSelected.spawnPosition[1] and (#garageSelected.spawnPosition .. (#garageSelected.spawnPosition > 1 and " points" or " point")) or "Non défini"
  StaffMenu.createGarageFactionData.Button("Spawn des véhicules", "", spawnCount, "chevron", false, function()
        StaffMenu.createGarageFactionData.close()
        local exitCoords <const> = Garage:SetExitPoint(garageSelected.vehType)
        StaffMenu.createGarageFactionData.open()

        garageSelected.spawnPosition = exitCoords
        StaffMenu.createGarageFactionData.refresh()
    end)

    local deleteDisplay = garageSelected.deletePosition.x and ("%.1f, %.1f, %.1f"):format(garageSelected.deletePosition.x, garageSelected.deletePosition.y, garageSelected.deletePosition.z) or "Non défini"
  StaffMenu.createGarageFactionData.Button("Suppression des véhicules", "", deleteDisplay, "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.deletePosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        StaffMenu.createGarageFactionData.refresh()
    end)


    local vehicleCount = #garageSelected.vehicles > 0 and (#garageSelected.vehicles .. (#garageSelected.vehicles > 1 and " véhicules" or " véhicule")) or "Aucun"
  StaffMenu.createGarageFactionData.Button("Véhicules", nil, vehicleCount, "chevron", false, function()
    end, StaffMenu.addVehicleToGarageFaction)

    StaffMenu.createGarageFactionData.Checkbox("Garage personnel", 'Les membres auront un espace de stockage personnel dans ce garage.', false, garageSelected.secondaryGarage or false, function(checked)
        garageSelected.secondaryGarage = checked and 1 or 0
        StaffMenu.createGarageFactionData.refresh()
    end)

    StaffMenu.createGarageFactionData.Button("Créer le garage", "", nil, "chevron", false, function()
        if not garageSelected.position.x or not garageSelected.spawnPosition[1] or not garageSelected.deletePosition.x then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Faction',
                message = "Veuillez définir toutes les positions avant d'ajouter le garage."
          })

            return
        end

        if not garageSelected.access.name or not garageSelected.access.rank then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Faction',
                message = "Veuillez définir le nom de la faction avant d'ajouter le garage."
          })

            return
        end

        TriggerServerEvent("core:createGarage", garageSelected)
        garageSelected = getGarageDefaultData()
        StaffMenu.createGarageFactionData.close()
    end)
end)

StaffMenu.addVehicleToGarageFaction.OnOpen(function()
    StaffMenu.addVehicleToGarageFaction.Button("Ajouter un véhicule", "Permet d'ajouter un véhicule à ce garage.", nil, "chevron", false, function()
    end, StaffMenu.addVehicleToGarageFactionData)

    StaffMenu.addVehicleToGarageFaction.Separator("Véhicules")

    for i, data in pairs(garageSelected.vehicles) do
        StaffMenu.addVehicleToGarageFaction.Button(data.model, ("Label: %s"):format(data.label), nil, "trash", false, function()
            garageSelected.vehicles[i] = nil
            StaffMenu.addVehicleToGarageFaction.refresh()
        end)
    end
end)

StaffMenu.addVehicleToGarageFactionData.OnOpen(function()
    local currentVehicle = garageSelected.currentVehicle

    StaffMenu.addVehicleToGarageFactionData.Button("Modèle du véhicule", "Exemple: sultanrs", currentVehicle.model and "Définie" or "Non définie", "chevron", false, function()
        local model <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du modèle", "")
        if model == "" then
            return
        end

        currentVehicle.model = model
        StaffMenu.addVehicleToGarageFactionData.refresh()
    end)

    StaffMenu.addVehicleToGarageFactionData.List('Type de véhicules', nil, false, vehicleType, garageSelected.vehType, function(Index)
        currentVehicle.type = Index
    end)

    StaffMenu.addVehicleToGarageFactionData.Button("Label du véhicule", "Exemple: Sultan RS", currentVehicle.label and "Définie" or "Non définie", "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du véhicule", "")
        if label == "" then
            return
        end

        currentVehicle.label = label
        StaffMenu.addVehicleToGarageFactionData.refresh()
    end)

    StaffMenu.addVehicleToGarageFactionData.Separator()

    StaffMenu.addVehicleToGarageFactionData.Button("Ajouter le véhicule", "", nil, "chevron", false, function()
        if not currentVehicle.model or currentVehicle.model == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Faction',
                message = "Veuillez définir un modèle de véhicule."
          })

            return
        end

        if not currentVehicle.label or currentVehicle.label == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Faction',
                message = "Veuillez définir un label de véhicule."
          })

            return
        end

        garageSelected.vehicles[#garageSelected.vehicles + 1] = {
            model = currentVehicle.model,
            label = currentVehicle.label,
            type = currentVehicle.type or 1,
        }

        currentVehicle = {}

        StaffMenu.addVehicleToGarageFaction.open()
    end)
end)

StaffMenu.modifyGarageFactionData.OnOpen(function()
    loadFactions()

    if garageSelected.position and garageSelected.position.x then
        StaffMenu.modifyGarageFactionData.Button("Se téléporter au garage", "", nil, "chevron", false, function()
            local ped <const> = PlayerPedId()
            SetEntityCoords(ped, garageSelected.position.x, garageSelected.position.y, garageSelected.position.z + 0.99, false, false, false, false)
            if garageSelected.position.w then
                SetEntityHeading(ped, garageSelected.position.w)
            end
        end)
        StaffMenu.modifyGarageFactionData.Separator("Configuration")
    end

    local posDisplay = garageSelected.position.x and ("%.1f, %.1f, %.1f"):format(garageSelected.position.x, garageSelected.position.y, garageSelected.position.z) or "Non défini"
  StaffMenu.modifyGarageFactionData.Button("Position du garage", "", posDisplay, "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
        StaffMenu.modifyGarageFactionData.refresh()
    end)

    -- Trouver l'index de la faction sélectionnée
    local selectedFactionIndex = 1
    if garageSelected.access.name then
        for i, faction in ipairs(factionsList) do
            if faction.name == garageSelected.access.name then
                selectedFactionIndex = i
                break
            end
        end
    end

    StaffMenu.modifyGarageFactionData.List('Faction', nil, false, factionsNames, selectedFactionIndex, function(Index)
        local selectedFaction = factionsList[Index]
        if selectedFaction then
            garageSelected.access.name = selectedFaction.name
            garageSelected.access.rank = 98 -- Chef et co-chef uniquement (98+)
        end
    end)

    local spawnCount = garageSelected.spawnPosition[1] and (#garageSelected.spawnPosition .. (#garageSelected.spawnPosition > 1 and " points" or " point")) or "Non défini"
  StaffMenu.modifyGarageFactionData.Button("Spawn des véhicules", "", spawnCount, "chevron", false, function()
        StaffMenu.modifyGarageFactionData.close()
        local exitCoords <const> = Garage:SetExitPoint(garageSelected.vehType)
        StaffMenu.modifyGarageFactionData.open()

        garageSelected.spawnPosition = exitCoords
        StaffMenu.modifyGarageFactionData.refresh()
    end)

    local deleteDisplay = garageSelected.deletePosition.x and ("%.1f, %.1f, %.1f"):format(garageSelected.deletePosition.x, garageSelected.deletePosition.y, garageSelected.deletePosition.z) or "Non défini"
  StaffMenu.modifyGarageFactionData.Button("Suppression des véhicules", "", deleteDisplay, "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.deletePosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        StaffMenu.modifyGarageFactionData.refresh()
    end)

    StaffMenu.modifyGarageFactionData.Button("Liste des véhicules", "", nil, "chevron", false, function()
    end, StaffMenu.modifyGarageFactionDataPreview)

    StaffMenu.modifyGarageFactionData.Button("Modifier le garage", "", nil, "chevron", false, function()
        if not garageSelected.position.x or not garageSelected.spawnPosition[1] or not garageSelected.deletePosition.x then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Faction',
                message = "Veuillez définir toutes les positions avant de modifier le garage."
          })

            return
        end

        TriggerServerCallback("core:updateGarage", garageSelected.id, garageSelected)
        garageSelected = getGarageDefaultData()
        StaffMenu.createGarageFaction.open()
    end)

    StaffMenu.modifyGarageFactionData.Button("Supprimer le garage", "", nil, "trash", false, function()
        TriggerServerEvent("core:deleteGarage", garageSelected.id)
        garageSelected = getGarageDefaultData()
        Wait(500)
        StaffMenu.createGarageFaction.open()
    end)
end)

StaffMenu.modifyGarageFactionDataPreview.OnOpen(function()
    if not garageSelected.vehicles then
        local vehicles = TriggerServerCallback("garage:getGarageData", garageSelected.id)
        garageSelected.vehicles = vehicles.groupVehicles or {}
    end

    StaffMenu.modifyGarageFactionDataPreview.Button("Ajouter un véhicule", "Permet d'ajouter un véhicule à ce garage.", nil, "chevron", false, function()
        local vehModel <const> = VFW.Nui.KeyboardInput(true, "Entrez le modèle du véhicule", "")
        if not vehModel or vehModel == "" then
            return
        end

        local vehLabel <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du véhicule", "")
        if not vehLabel or vehLabel == "" then
            return
        end

        local addVehicle = TriggerServerCallback("garage:addVehicleToGarageFaction", garageSelected.id, vehModel, vehLabel)

        if addVehicle and addVehicle.plate then
            -- Recharger la liste depuis le serveur pour être sûr
            local vehicles = TriggerServerCallback("garage:getGarageData", garageSelected.id)
            garageSelected.vehicles = vehicles.groupVehicles or {}
        end

        StaffMenu.modifyGarageFactionDataPreview.refresh()
    end)

    if next(garageSelected.vehicles) then
        StaffMenu.modifyGarageFactionDataPreview.Separator("Véhicules")
    end

    for k, v in pairs(garageSelected.vehicles) do
        StaffMenu.modifyGarageFactionDataPreview.Button(v.vehName, ("Label: %s"):format(v.label), nil, "trash", false, function()
            local success = TriggerServerCallback("garage:removeVehicleFromFaction", v.plate, garageSelected.id)
            if not success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Faction',
                    message = "Véhicule non trouvé."
              })
                return
            end
            -- Recharger la liste depuis le serveur
            local vehicles = TriggerServerCallback("garage:getGarageData", garageSelected.id)
            garageSelected.vehicles = vehicles.groupVehicles or {}
            StaffMenu.modifyGarageFactionDataPreview.refresh()
        end)
    end
end)
