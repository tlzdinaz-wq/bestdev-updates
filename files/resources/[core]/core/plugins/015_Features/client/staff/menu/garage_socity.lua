local function getGarageDefaultData()
    return {
        vehType = 1,
        name = nil,
        type = "society",
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

local VUI = exports["VUI"]

local vehicleType <const> = {"voiture/moto", "bateaux", "avion"}

local adminBanner = exports["core"]:GetVUIBanner("admin")
StaffMenu.createGarageSocietyData = VUI:CreateSubMenu(StaffMenu.createGarageSociety, "CRÉATION DE GARAGE", adminBanner, true)
StaffMenu.addVehicleToGarageSociety = VUI:CreateSubMenu(StaffMenu.createGarageSocietyData, "AJOUT DE VÉHICULES", adminBanner, true)
StaffMenu.addVehicleToGarageSocietyData = VUI:CreateSubMenu(StaffMenu.addVehicleToGarageSociety, "DONNEES DU VÉHICULE", adminBanner, true)
StaffMenu.modifyGarageSocietyData = VUI:CreateSubMenu(StaffMenu.createGarageSociety, "MODIFICATION DE GARAGE", adminBanner, true)
StaffMenu.modifyGarageSocietyDataPreview = VUI:CreateSubMenu(StaffMenu.modifyGarageSocietyData, "APERÇU DES VÉHICULES", adminBanner, true)
StaffMenu.garageSocietyJobSelect = VUI:CreateSubMenu(StaffMenu.createGarageSocietyData, "SÉLECTION DU JOB", adminBanner, true)
StaffMenu.garageSocietyJobSelectEdit = VUI:CreateSubMenu(StaffMenu.modifyGarageSocietyData, "SÉLECTION DU JOB", adminBanner, true)

local SOCIETY_GARAGES_PER_PAGE = 25
StaffMenu.societyGaragePage = StaffMenu.societyGaragePage or 1
StaffMenu.societyGarageSearch = StaffMenu.societyGarageSearch or nil

function StaffMenu.BuildCreateGarageSociety()
    garages = TriggerServerCallback("core:getAllGarages", "society")

    StaffMenu.createGarageSociety.Button("Ajouter un garage", "", nil, "chevron", false, function()
        garageSelected = getGarageDefaultData()
    end, StaffMenu.createGarageSocietyData)

    local searchLabel = StaffMenu.societyGarageSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.societyGarageSearch == nil and "Nom du garage / société" or StaffMenu.societyGarageSearch
    StaffMenu.createGarageSociety.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.societyGarageSearch ~= nil then
            StaffMenu.societyGarageSearch = nil
            StaffMenu.societyGaragePage = 1
            StaffMenu.createGarageSociety.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du garage / société")
        if query == nil or query == "" then return end
        StaffMenu.societyGarageSearch = query
        StaffMenu.societyGaragePage = 1
        StaffMenu.createGarageSociety.refresh()
    end)

    local flat = {}
    for jobName, garagesByType in pairs(garages or {}) do
        for id, garageData in pairs(garagesByType or {}) do
            table.insert(flat, { id = id, job = jobName, data = garageData })
        end
    end
    table.sort(flat, function(a, b) return (a.data.name or ""):lower() < (b.data.name or ""):lower() end)

    local filtered = flat
    if StaffMenu.societyGarageSearch and StaffMenu.societyGarageSearch ~= "" then
        local q = StaffMenu.societyGarageSearch:lower()
        filtered = {}
        for _, e in ipairs(flat) do
            if (e.data.name or ""):lower():find(q, 1, true) or (e.job or ""):lower():find(q, 1, true) then
                table.insert(filtered, e)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / SOCIETY_GARAGES_PER_PAGE), 1)
    if StaffMenu.societyGaragePage > totalPages then StaffMenu.societyGaragePage = totalPages end
    if StaffMenu.societyGaragePage < 1 then StaffMenu.societyGaragePage = 1 end
    local startIdx = (StaffMenu.societyGaragePage - 1) * SOCIETY_GARAGES_PER_PAGE + 1
    local endIdx = math.min(startIdx + SOCIETY_GARAGES_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.societyGarageSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d garages de société, page %d sur %d", totalItems, StaffMenu.societyGaragePage, totalPages)
    end
    StaffMenu.createGarageSociety.Separator(header)

    if totalItems == 0 then
        StaffMenu.createGarageSociety.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function()end)
        return
    end

    for idx = startIdx, endIdx do
        local e = filtered[idx]
        StaffMenu.createGarageSociety.Button(("Garage | %s | id : %s"):format(e.data.name, e.id), e.job, nil, "chevron", false, function()
            garageSelected = e.data
        end, StaffMenu.modifyGarageSocietyData)
    end

    if totalPages > 1 then
        StaffMenu.createGarageSociety.Separator(nil)
        if StaffMenu.societyGaragePage > 1 then
            StaffMenu.createGarageSociety.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.societyGaragePage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.societyGaragePage = StaffMenu.societyGaragePage - 1
                StaffMenu.createGarageSociety.refresh()
            end)
        end
        if StaffMenu.societyGaragePage < totalPages then
            StaffMenu.createGarageSociety.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.societyGaragePage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.societyGaragePage = StaffMenu.societyGaragePage + 1
                StaffMenu.createGarageSociety.refresh()
            end)
        end
    end
end

StaffMenu.createGarageSocietyData.OnOpen(function()

    StaffMenu.createGarageSocietyData.Button("Nom du garage", "", garageSelected.name and "Définie" or "Non définie", "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du garage")

        if not name or name == "" then
            return
        end

        garageSelected.name = name
        StaffMenu.createGarageSocietyData.refresh()
    end)

    StaffMenu.createGarageSocietyData.List('Type de véhicules', nil, false, vehicleType, garageSelected.vehType, function(Index)
        garageSelected.vehType = Index
    end)


    local jobLabel = garageSelected.access.name or "Non défini"
  if garageSelected.access.name and VFW.Jobs and VFW.Jobs[garageSelected.access.name] then
        jobLabel = VFW.Jobs[garageSelected.access.name].label or garageSelected.access.name
    end
    local rankInfo = garageSelected.access.rank and (" (Grade: " .. garageSelected.access.rank .. ")") or ""
  StaffMenu.createGarageSocietyData.Button("Job autorisé", "Sélectionnez le job pour ce garage", jobLabel .. rankInfo, "chevron", false, function()
    end, StaffMenu.garageSocietyJobSelect)


    StaffMenu.createGarageSocietyData.Button("Position du garage", "", garageSelected.position.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
        StaffMenu.createGarageSocietyData.refresh()
    end)

    StaffMenu.createGarageSocietyData.Button("Spawn des véhicules", "", garageSelected.spawnPosition[1] and "Définie" or "Non définie", "chevron", false, function()
        StaffMenu.createGarageSocietyData.close()
        local exitCoords <const> = Garage:SetExitPoint(garageSelected.vehType)
        StaffMenu.createGarageSocietyData.open()

        garageSelected.spawnPosition = exitCoords
        StaffMenu.createGarageSocietyData.refresh()
    end)

    StaffMenu.createGarageSocietyData.Button("Suppression des véhicules", "", garageSelected.deletePosition.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.deletePosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        StaffMenu.createGarageSocietyData.refresh()
    end)


    StaffMenu.createGarageSocietyData.Button("Ajouter des véhicules", "Permet de give des véhicules à ce garage.", nil, "chevron", false, function()
    end, StaffMenu.addVehicleToGarageSociety)

    StaffMenu.createGarageSocietyData.Checkbox("Garage personnel", 'Les employés auront un espace de stockage personnel dans ce garage.', false, garageSelected.secondaryGarage or false, function(checked)
        garageSelected.secondaryGarage = checked and 1 or 0
        StaffMenu.createGarageSocietyData.refresh()
    end)

    StaffMenu.createGarageSocietyData.Button("Créer le garage", "", nil, "chevron", false, function()
        if not garageSelected.position.x or not garageSelected.spawnPosition[1] or not garageSelected.deletePosition.x then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir toutes les positions avant d'ajouter le garage."
          })

            return
        end

        if not garageSelected.name then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir le nom du garage."
          })

            return
        end

        if not garageSelected.access.name or not garageSelected.access.rank then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir le job du garage."
          })

            return
        end

        local result = TriggerServerCallback("core:createGarage", garageSelected)
        if not result or not result.ok then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = result and result.error or "Création du garage impossible."
          })
            return
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Garage Société',
            message = "Garage créé."
      })
        garageSelected = getGarageDefaultData()
        StaffMenu.createGarageSocietyData.close()
        StaffMenu.createGarageSociety.open()
    end)
end)

StaffMenu.garageSocietyJobSelect.OnOpen(function()
    local jobs = TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not jobs or not next(jobs) then
        StaffMenu.garageSocietyJobSelect.Button("AUCUN JOB DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = garageSelected.access.name == job.name
        StaffMenu.garageSocietyJobSelect.Button(job.label or job.name, job.name, isSelected and ":check:" or nil, "chevron", false, function()
            garageSelected.access.name = job.name

            -- Demander le grade minimum
            local rank = tonumber(VFW.Nui.KeyboardInput(true, "Grade minimum pour gérer le garage (0 = tous)", tostring(garageSelected.access.rank or 0)))

            if not rank or rank < 0 then
                rank = 0
            end

            garageSelected.access.rank = rank

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Garage Société',
                message = "Job sélectionné: " .. (job.label or job.name) .. " (Grade: " .. rank .. ")."
          })

        end)
    end
end)

StaffMenu.addVehicleToGarageSociety.OnOpen(function()
    StaffMenu.addVehicleToGarageSociety.Button("Ajouter un véhicule", "Permet d'ajouter un véhicule à ce garage.", nil, "chevron", false, function()
    end, StaffMenu.addVehicleToGarageSocietyData)

    StaffMenu.addVehicleToGarageSociety.Separator("Véhicules")

    for i, data in pairs(garageSelected.vehicles) do
        StaffMenu.addVehicleToGarageSociety.Button(data.model, ("Label: %s"):format(data.label), nil, "trash", false, function()
            garageSelected.vehicles[i] = nil
            StaffMenu.addVehicleToGarageSociety.refresh()
        end)
    end
end)

StaffMenu.addVehicleToGarageSocietyData.OnOpen(function()
    local currentVehicle = garageSelected.currentVehicle

    StaffMenu.addVehicleToGarageSocietyData.Button("Modèle du véhicule", "Exemple: sultanrs", currentVehicle.model and "Définie" or "Non définie", "chevron", false, function()
        local model <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du modèle", "")
        if model == "" then
            return
        end

        currentVehicle.model = model
        StaffMenu.addVehicleToGarageSocietyData.refresh()
    end)

    StaffMenu.addVehicleToGarageSocietyData.List('Type de véhicules', nil, false, vehicleType, garageSelected.vehType, function(Index)
        currentVehicle.type = Index
    end)

    StaffMenu.addVehicleToGarageSocietyData.Button("Label du véhicule", "Exemple: Sultan RS", currentVehicle.label and "Définie" or "Non définie", "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du véhicule", "")
        if label == "" then
            return
        end

        currentVehicle.label = label
        StaffMenu.addVehicleToGarageSocietyData.refresh()
    end)

    StaffMenu.addVehicleToGarageSocietyData.Separator()

    StaffMenu.addVehicleToGarageSocietyData.Button("Ajouter le véhicule", "", nil, "chevron", false, function()
        if not currentVehicle.model or currentVehicle.model == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir un modèle de véhicule."
          })

            return
        end

        if not currentVehicle.label or currentVehicle.label == "" then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir un label de véhicule."
          })

            return
        end

        garageSelected.vehicles[#garageSelected.vehicles + 1] = {
            model = currentVehicle.model,
            label = currentVehicle.label,
            type = currentVehicle.type or 1,
        }

        garageSelected.currentVehicle = {}

        StaffMenu.addVehicleToGarageSociety.open()
    end)
end)

StaffMenu.modifyGarageSocietyData.OnOpen(function()
    if garageSelected.position and garageSelected.position.x then
        StaffMenu.modifyGarageSocietyData.Button("Se téléporter au garage", "", nil, "chevron", false, function()
            local ped <const> = PlayerPedId()
            SetEntityCoords(ped, garageSelected.position.x, garageSelected.position.y, garageSelected.position.z + 0.99, false, false, false, false)
            if garageSelected.position.w then
                SetEntityHeading(ped, garageSelected.position.w)
            end
        end)
        StaffMenu.modifyGarageSocietyData.Separator("Configuration")
    end

    StaffMenu.modifyGarageSocietyData.Button("Nom du garage", "", garageSelected.name or "Non défini", "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du garage", garageSelected.name or "")
        if not name or name == "" then
            return
        end
        garageSelected.name = name
        StaffMenu.modifyGarageSocietyData.refresh()
    end)

    StaffMenu.modifyGarageSocietyData.Button("Position du garage", "", garageSelected.position.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
        StaffMenu.modifyGarageSocietyData.refresh()
    end)

    local editJobLabel = garageSelected.access.name or "Non défini"
  if garageSelected.access.name and VFW.Jobs and VFW.Jobs[garageSelected.access.name] then
        editJobLabel = VFW.Jobs[garageSelected.access.name].label or garageSelected.access.name
    end
    local editRankInfo = garageSelected.access.rank and (" (Grade: " .. garageSelected.access.rank .. ")") or ""
  StaffMenu.modifyGarageSocietyData.Button("Job autorisé", "Sélectionnez le job pour ce garage", editJobLabel .. editRankInfo, "chevron", false, function()
    end, StaffMenu.garageSocietyJobSelectEdit)

    StaffMenu.modifyGarageSocietyData.Button("Spawn des véhicules", "", garageSelected.spawnPosition[1] and "Définie" or "Non définie", "chevron", false, function()
        StaffMenu.modifyGarageSocietyData.close()
        local exitCoords <const> = Garage:SetExitPoint(garageSelected.vehType)
        StaffMenu.modifyGarageSocietyData.open()

        garageSelected.spawnPosition = exitCoords
        StaffMenu.modifyGarageSocietyData.refresh()
    end)

    StaffMenu.modifyGarageSocietyData.Button("Suppression des véhicules", "", garageSelected.deletePosition.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.deletePosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        StaffMenu.modifyGarageSocietyData.refresh()
    end)

    StaffMenu.modifyGarageSocietyData.Button("Liste des véhicules", "", nil, "chevron", false, function()
    end, StaffMenu.modifyGarageSocietyDataPreview)

    StaffMenu.modifyGarageSocietyData.Checkbox("Garage personnel", 'Les employés auront un espace de stockage personnel dans ce garage.', false, garageSelected.secondaryGarage == 1 or garageSelected.secondaryGarage == true, function(checked)
        garageSelected.secondaryGarage = checked and 1 or 0
        StaffMenu.modifyGarageSocietyData.refresh()
    end)

    StaffMenu.modifyGarageSocietyData.Button("Modifier le garage", "", nil, "chevron", false, function()
        if not garageSelected.position.x or not garageSelected.spawnPosition[1] or not garageSelected.deletePosition.x then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir toutes les positions avant de modifier le garage."
          })

            return
        end

        if not garageSelected.name then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir le nom du garage."
          })

            return
        end

        if not garageSelected.access or not garageSelected.access.name or not garageSelected.access.rank then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                message = "Veuillez définir le job du garage."
          })

            return
        end

        TriggerServerCallback("core:updateGarage", garageSelected.id, garageSelected)
        garageSelected = getGarageDefaultData()
        StaffMenu.createGarageSociety.open()
    end)

    StaffMenu.modifyGarageSocietyData.Button("Supprimer le garage", "", nil, "trash", false, function()
        TriggerServerEvent("core:deleteGarage", garageSelected.id)
        garageSelected = getGarageDefaultData()
        StaffMenu.modifyGarageSocietyData.close()
        StaffMenu.createGarageSociety.open()
    end)
end)


StaffMenu.modifyGarageSocietyDataPreview.OnOpen(function()
    if not garageSelected.vehicles then
        local vehicles = TriggerServerCallback("garage:getGarageData", garageSelected.id)
        garageSelected.vehicles = vehicles.groupVehicles or {}
        print("[DEBUG] garageSelected.vehicles:", json.encode(garageSelected.vehicles, { indent = true }))
    end

    StaffMenu.modifyGarageSocietyDataPreview.Button("Ajouter un véhicule", "Permet d'ajouter un véhicule à ce garage.", nil, "chevron", false, function()
        local vehModel <const> = VFW.Nui.KeyboardInput(true, "Entrez le modèle du véhicule", "")
        if not vehModel or vehModel == "" then
            return
        end

        local vehLabel <const> = VFW.Nui.KeyboardInput(true, "Entrez le label du véhicule", "")
        if not vehLabel or vehLabel == "" then
            return
        end

        local addVehicle = TriggerServerCallback("garage:addVehicleToGarageSociety", garageSelected.id, vehModel, vehLabel)

        garageSelected.vehicles[#garageSelected.vehicles + 1] = {
            vehName = addVehicle.vehName,
            label = addVehicle.label,
            plate = addVehicle.plate,
            type = garageSelected.vehType or 1,
        }

        StaffMenu.modifyGarageSocietyDataPreview.refresh()
    end)

    if next(garageSelected.vehicles) then
        StaffMenu.modifyGarageSocietyDataPreview.Separator("Véhicules")
    end

    for k, v in pairs(garageSelected.vehicles) do
        StaffMenu.modifyGarageSocietyDataPreview.Button(v.vehName, ("Label: %s"):format(v.label), nil, "trash", false, function()
            local success = TriggerServerCallback("garage:removeVehicleFromSociety", v.plate, garageSelected.id)
            if not success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Garage Société',
                    message = "Véhicule non trouvé."
              })
                return
            end
            garageSelected.vehicles[k] = nil
            StaffMenu.modifyGarageSocietyDataPreview.refresh()
        end)
    end
end)

StaffMenu.garageSocietyJobSelectEdit.OnOpen(function()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not jobs or not next(jobs) then
        StaffMenu.garageSocietyJobSelectEdit.Button("AUCUN JOB DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = garageSelected.access and garageSelected.access.name == job.name
        StaffMenu.garageSocietyJobSelectEdit.Button(job.label or job.name, job.name, isSelected and ":check:" or nil, "chevron", false, function()
            if not garageSelected.access then
                garageSelected.access = {}
            end
            garageSelected.access.name = job.name

            -- Demander le grade minimum
            local rank = tonumber(VFW.Nui.KeyboardInput(true, "Grade minimum pour gérer le garage (0 = tous)", tostring(garageSelected.access.rank or 0)))

            if not rank or rank < 0 then
                rank = 0
            end

            garageSelected.access.rank = rank

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Garage Société',
                message = "Job sélectionné: " .. (job.label or job.name) .. " (Grade: " .. rank .. ")."
          })
            StaffMenu.garageSocietyJobSelectEdit.close()
            StaffMenu.garageSocietyJobSelectEdit.parent.open()
        end)
    end
end)
