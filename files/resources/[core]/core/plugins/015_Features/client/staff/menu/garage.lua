local function getGarageDefaultData()
    return {
        name = nil,
        vehType = 1,
        type = "public",
        position = {},
        spawnPosition = {},
        deletePosition = {},
        secondaryGarage = false
    }
end

local garageSelected = getGarageDefaultData()
local garages = {}

local VUI = exports["VUI"]

local vehicleType <const> = {"voiture/moto", "bateaux", "avion"}

local adminBanner = exports["core"]:GetVUIBanner("admin")
StaffMenu.createGarageData = VUI:CreateSubMenu(StaffMenu.createGarage, "CRÉATION DE GARAGE", adminBanner, true)
StaffMenu.createGarageDataPreview = VUI:CreateSubMenu(StaffMenu.createGarageData, "APERÇU DES VÉHICULES", adminBanner, true)
StaffMenu.addVehicleToGarage = VUI:CreateSubMenu(StaffMenu.createGarageData, "AJOUT DE VÉHICULES", adminBanner, true)
StaffMenu.addVehicleToGarageData = VUI:CreateSubMenu(StaffMenu.addVehicleToGarage, "DONNEES DU VÉHICULE", adminBanner, true)

StaffMenu.modifyGarageData = VUI:CreateSubMenu(StaffMenu.createGarage, "MODIFICATION DE GARAGE", adminBanner, true)
StaffMenu.modifyGarageDataPreview = VUI:CreateSubMenu(StaffMenu.modifyGarageData, "APERÇU DES VÉHICULES", adminBanner, true)

local GARAGES_PER_PAGE = 25
StaffMenu.publicGaragePage = StaffMenu.publicGaragePage or 1
StaffMenu.publicGarageSearch = StaffMenu.publicGarageSearch or nil

function StaffMenu.BuildCreateGarageMenu()
    garages = TriggerServerCallback("core:getAllGarages", "public")

    StaffMenu.createGarage.Button("Ajouter un garage", "", nil, "chevron", false, function()
        garageSelected = getGarageDefaultData()
    end, StaffMenu.createGarageData)

    local searchLabel = StaffMenu.publicGarageSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.publicGarageSearch == nil and "Nom du garage" or StaffMenu.publicGarageSearch
    StaffMenu.createGarage.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.publicGarageSearch ~= nil then
            StaffMenu.publicGarageSearch = nil
            StaffMenu.publicGaragePage = 1
            StaffMenu.createGarage.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du garage")
        if query == nil or query == "" then return end
        StaffMenu.publicGarageSearch = query
        StaffMenu.publicGaragePage = 1
        StaffMenu.createGarage.refresh()
    end)

    -- Build filtered list
    local flat = {}
    for _, data in pairs(garages or {}) do table.insert(flat, data) end
    table.sort(flat, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)

    local filtered = flat
    if StaffMenu.publicGarageSearch and StaffMenu.publicGarageSearch ~= "" then
        local q = StaffMenu.publicGarageSearch:lower()
        filtered = {}
        for _, data in ipairs(flat) do
            if (data.name or ""):lower():find(q, 1, true) then
                table.insert(filtered, data)
            end
        end
    end

    -- Pagination
    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / GARAGES_PER_PAGE), 1)
    if StaffMenu.publicGaragePage > totalPages then StaffMenu.publicGaragePage = totalPages end
    if StaffMenu.publicGaragePage < 1 then StaffMenu.publicGaragePage = 1 end
    local startIdx = (StaffMenu.publicGaragePage - 1) * GARAGES_PER_PAGE + 1
    local endIdx = math.min(startIdx + GARAGES_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.publicGarageSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d garages, page %d sur %d", totalItems, StaffMenu.publicGaragePage, totalPages)
    end
    StaffMenu.createGarage.Separator(header)

    if totalItems == 0 then
        StaffMenu.createGarage.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function()end)
        return
    end

    for idx = startIdx, endIdx do
        local data = filtered[idx]
        StaffMenu.createGarage.Button(("Garage | %s"):format(data.name), nil, nil, "chevron", false, function()
            garageSelected = data
            if not garageSelected.vehType then
                garageSelected.vehType = 1
            end
        end, StaffMenu.modifyGarageData)
    end

    if totalPages > 1 then
        StaffMenu.createGarage.Separator(nil)
        if StaffMenu.publicGaragePage > 1 then
            StaffMenu.createGarage.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.publicGaragePage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.publicGaragePage = StaffMenu.publicGaragePage - 1
                StaffMenu.createGarage.refresh()
            end)
        end
        if StaffMenu.publicGaragePage < totalPages then
            StaffMenu.createGarage.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.publicGaragePage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.publicGaragePage = StaffMenu.publicGaragePage + 1
                StaffMenu.createGarage.refresh()
            end)
        end
    end
end

StaffMenu.createGarageData.OnOpen(function()

    StaffMenu.createGarageData.Button("Nom du garage", "", garageSelected.name and "Définie" or "Non définie", "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du garage")

        if not name or name == "" then
            return
        end

        garageSelected.name = name
        StaffMenu.createGarageData.refresh()
    end)

    StaffMenu.createGarageData.List('Type de vehicules', nil, false, vehicleType, garageSelected.vehType or 1, function(Index)
        garageSelected.vehType = Index
    end)

    StaffMenu.createGarageData.Button("Position du garage", "", garageSelected.position.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped)}
        StaffMenu.createGarageData.refresh()
    end)

    StaffMenu.createGarageData.Button("Spawn des véhicules", "", garageSelected.spawnPosition[1] and "Définie" or "Non définie", "chevron", false, function()
        StaffMenu.createGarageData.close()
        local exitCoords <const> = Garage:SetExitPoint(garageSelected.vehType)
        StaffMenu.createGarageData.open()

        garageSelected.spawnPosition = exitCoords
        StaffMenu.createGarageData.refresh()
    end)

    StaffMenu.createGarageData.Button("Suppression des véhicules", "", garageSelected.deletePosition.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.deletePosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        StaffMenu.createGarageData.refresh()
    end)

    StaffMenu.createGarageData.Button("Créer le garage", "", nil, "chevron", false, function()
        if not garageSelected.position.x or not garageSelected.spawnPosition[1] or not garageSelected.deletePosition.x or not garageSelected.name then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Garage',
                message = "Veuillez définir toutes les positions avant d'ajouter le garage."
          })

            return
        end

        TriggerServerEvent("core:createGarage", garageSelected)
        garageSelected = getGarageDefaultData()
        StaffMenu.createGarageData.close()
    end)
end)

StaffMenu.modifyGarageData.OnOpen(function()
    if garageSelected.position and garageSelected.position.x then
        StaffMenu.modifyGarageData.Button("Se téléporter au garage", "", nil, "chevron", false, function()
            local ped <const> = PlayerPedId()
            SetEntityCoords(ped, garageSelected.position.x, garageSelected.position.y, garageSelected.position.z + 0.99, false, false, false, false)
            if garageSelected.position.w then
                SetEntityHeading(ped, garageSelected.position.w)
            end
        end)
        StaffMenu.modifyGarageData.Separator("Configuration")
    end

    StaffMenu.modifyGarageData.Button("Position du garage", "", garageSelected.position.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
        StaffMenu.modifyGarageData.refresh()
    end)

    StaffMenu.modifyGarageData.Button("Spawn des véhicules", "", garageSelected.spawnPosition[1] and "Définie" or "Non définie", "chevron", false, function()
        local exitCoords <const> = Garage:SetExitPoint(garageSelected.vehType)

        garageSelected.spawnPosition = exitCoords
        StaffMenu.modifyGarageData.refresh()
    end)

    StaffMenu.modifyGarageData.Button("Suppression des véhicules", "", garageSelected.deletePosition.x and "Définie" or "Non définie", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        garageSelected.deletePosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
        StaffMenu.modifyGarageData.refresh()
    end)

    --StaffMenu.modifyGarageData.Button("Position de la caméra", "", nil, "chevron", false, function()
    --end, StaffMenu.modifyGarageDataPreview)

    StaffMenu.modifyGarageData.Button("Modifier le garage", "", nil, "chevron", false, function()
        if not garageSelected.position.x or not garageSelected.spawnPosition[1] or not garageSelected.deletePosition.x then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Garage',
                message = "Veuillez définir toutes les positions avant de modifier le garage."
          })

            return
        end

        TriggerServerCallback("core:updateGarage", garageSelected.id, garageSelected)
        garageSelected = getGarageDefaultData()
        StaffMenu.createGarage.open()
    end)
    
    StaffMenu.modifyGarageData.Button("Supprimer le garage", "", nil, "chevron", false, function()
        TriggerServerEvent("core:deleteGarage", garageSelected.id)
        garageSelected = getGarageDefaultData()
        StaffMenu.modifyGarageData.close()
    end)
end)