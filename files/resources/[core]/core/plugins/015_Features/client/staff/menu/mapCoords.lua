local VUI = exports["VUI"]

StaffMenu.createMapCoord = VUI:CreateSubMenu(StaffMenu.mapCoords, "AJOUTER UN MAPPING", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.manageMapCoords = VUI:CreateSubMenu(StaffMenu.mapCoords, "LISTE DES MAPPINGS", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.editMapCoord = VUI:CreateSubMenu(StaffMenu.manageMapCoords, "GÉRER LE MAPPING", exports["core"]:GetVUIBanner("admin"), true)

local mapTypes = {"légal", "illégal", "autre"}
local mapTypesInternal = {"legal", "illegal", "other"}

local searchQuery = ""

local function getDefaultMapData()
    return {
        id = nil,
        name = nil,
        type = 1,
        position = nil
    }
end

local selectedMap = getDefaultMapData()

function StaffMenu.BuildMapCoordsMenu()
    StaffMenu.mapCoords.Button(":plus: Ajouter un mapping", "Ajouter un nouveau mapping sur la carte", nil, "chevron", false, function()
        selectedMap = getDefaultMapData()
    end, StaffMenu.createMapCoord)

    StaffMenu.mapCoords.Button(":settings: Gérer les mappings", "Modifier ou supprimer des mappings existants", nil, "chevron", false, function()
    end, StaffMenu.manageMapCoords)
end

-- Create
StaffMenu.createMapCoord.OnOpen(function()
    StaffMenu.createMapCoord.ClearItems()

    StaffMenu.createMapCoord.List("Type de mapping", nil, false, mapTypes, selectedMap.type or 1, function(Index)
        selectedMap.type = Index
        StaffMenu.createMapCoord.refresh()
    end)

    StaffMenu.createMapCoord.Button("Nom du mapping", "", selectedMap.name or "Non défini", "chevron", false, function()
        local value = VFW.Nui.KeyboardInput(true, "Entrez le nom du mapping", "")
        if value == "" then return end
        selectedMap.name = value
        StaffMenu.createMapCoord.refresh()
    end)

    StaffMenu.createMapCoord.Button("Position du mapping", "Définir la position au joueur", selectedMap.position and "Défini" or "Non défini", "chevron", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        selectedMap.position = { x = coords.x, y = coords.y, z = coords.z }
        StaffMenu.createMapCoord.refresh()
    end)

    StaffMenu.createMapCoord.Button(":check: Créer le mapping", "", nil, "check", false, function()
        if not selectedMap.name or not selectedMap.position then
            return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Map Coords', message = "Vous devez définir au moins le nom et la position." })
        end

        local payload = {
            name = selectedMap.name,
            type = mapTypesInternal[selectedMap.type],
            position = selectedMap.position
        }

        TriggerServerEvent("core:createMapCoord", payload)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Map Coords', message = "Mapping créé." })
        SetTimeout(500, function()
            if StaffMenu.mapCoords and StaffMenu.mapCoords.open then
                StaffMenu.mapCoords.open()
            end
        end)
    end)
end)

-- Manage
StaffMenu.manageMapCoords.OnOpen(function()
    StaffMenu.manageMapCoords.ClearItems()

    local maps = TriggerServerCallback("core:getAllMapCoords") or {}

    -- Convert to array and sort alphabetically
    local mapArray = {}
    for _, map in pairs(maps) do
        table.insert(mapArray, map)
    end
    
    table.sort(mapArray, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    -- Search button
    StaffMenu.manageMapCoords.Button(":search: Rechercher", "Rechercher un mapping par nom", searchQuery ~= "" and searchQuery or "Aucun filtre", "chevron", false, function()
        local value = VFW.Nui.KeyboardInput(true, "Entrez le nom du mapping à rechercher", searchQuery or "")
        searchQuery = value
        StaffMenu.manageMapCoords.refresh()
    end)

    -- Filter and display maps
    local displayedCount = 0
    for _, map in ipairs(mapArray) do
        -- Filter by search query
        if searchQuery == "" or (map.name and map.name:lower():find(searchQuery:lower(), 1, true)) then
            displayedCount = displayedCount + 1
            
            -- Convert server type to index for internal consistency
            local typeIndex = 1
            if map.type == "legal" then typeIndex = 1
            elseif map.type == "illegal" then typeIndex = 2
            elseif map.type == "other" then typeIndex = 3
            end
            
            StaffMenu.manageMapCoords.Button(map.name, map.type and (map.type == "legal" and "légal" or (map.type == "illegal" and "illégal" or "autre")) or "", nil, "chevron", false, function()
                selectedMap = map
                selectedMap.type = typeIndex  -- Ensure type is always an index (1-3)
            end, StaffMenu.editMapCoord)
        end
    end

    -- Show message if no results
    if displayedCount == 0 and searchQuery ~= "" then
        StaffMenu.manageMapCoords.Button(":x: Aucun résultat trouvé", "", nil, "chevron", true, function() end)
    end
end)

-- Edit
StaffMenu.editMapCoord.OnOpen(function()
    StaffMenu.editMapCoord.ClearItems()

    StaffMenu.editMapCoord.Button("TP au mapping", "Se téléporter à la position du mapping", nil, "arrow", false, function()
        if not selectedMap.position then return end
        local ped = PlayerPedId()
        VFW.ToggleNoclip()
        SetEntityCoords(ped, selectedMap.position.x, selectedMap.position.y, selectedMap.position.z, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Map Coords', message = "Téléporté au mapping." })
    end)

    StaffMenu.editMapCoord.List("Type de mapping", nil, false, mapTypes, selectedMap.type or 1, function(Index)
        selectedMap.type = Index
        StaffMenu.editMapCoord.refresh()
    end)

    StaffMenu.editMapCoord.Button("Nom du mapping", "", selectedMap.name or "Non défini", "chevron", false, function()
        local value = VFW.Nui.KeyboardInput(true, "Entrez le nom du mapping", "")
        if value == "" then return end
        selectedMap.name = value
        StaffMenu.editMapCoord.refresh()
    end)

    StaffMenu.editMapCoord.Button("Position du mapping", "Redéfinir la position au joueur", selectedMap.position and "Défini" or "Non défini", "chevron", false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        selectedMap.position = { x = coords.x, y = coords.y, z = coords.z }
        StaffMenu.editMapCoord.refresh()
    end)

    StaffMenu.editMapCoord.Button(":save: Enregistrer les modifications", "", nil, "check", false, function()
        if not selectedMap.id or not selectedMap.name or not selectedMap.position then
            return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Map Coords', message = "Vous devez définir au moins le nom et la position." })
        end

        local payload = {
            id = selectedMap.id,
            name = selectedMap.name,
            type = mapTypesInternal[selectedMap.type],
            position = selectedMap.position
        }

        TriggerServerEvent("core:updateMapCoord", selectedMap.id, payload)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Map Coords', message = "Mapping mis à jour." })
        SetTimeout(500, function()
            if StaffMenu.mapCoords and StaffMenu.mapCoords.open then
                StaffMenu.mapCoords.open()
            end
        end)
    end)

    StaffMenu.editMapCoord.Button(":trash: Supprimer le mapping", "", nil, "chevron", false, function()
        if not selectedMap.id then return end
        TriggerServerEvent("core:deleteMapCoord", selectedMap.id)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Map Coords', message = "Mapping supprimé." })
        SetTimeout(500, function()
            if StaffMenu.mapCoords and StaffMenu.mapCoords.open then
                StaffMenu.mapCoords.open()
            end
        end)
    end)
end)

-- Register open handler for the main submenu
StaffMenu.mapCoords.OnOpen(function()
    StaffMenu.BuildMapCoordsMenu()
end)
