function getLockerDefaultData()
    return {
        label = nil,
        position = nil,
        whitelistType = 1,
        whitelistValue = nil,
        showBlip = true,
        outfits = {},
        floatingZ = 0.5
    }
end

-- Utilise FloatingUI.StartHeightPreview / StopHeightPreview de 012_floatingUI.lua

local VUI = exports["VUI"]

local selectedLocker = nil

local lockerTypes = { "job", "faction" }
local lockerTypeLabels = { "Société (Job)", "Faction (Job2)" }

StaffMenu.createLocker = VUI:CreateSubMenu(StaffMenu.builderLocker, "Créer un vestiaire", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.manageLockers = VUI:CreateSubMenu(StaffMenu.builderLocker, "Gérer les vestiaires", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.selectedLocker = VUI:CreateSubMenu(StaffMenu.manageLockers, "Vestiaire sélectionné", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.lockerJobSelect = VUI:CreateSubMenu(StaffMenu.createLocker, "Sélection du job", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.lockerFactionSelect = VUI:CreateSubMenu(StaffMenu.createLocker, "Sélection de la faction", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.lockerJobSelectEdit = VUI:CreateSubMenu(StaffMenu.selectedLocker, "Sélection du job", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.lockerFactionSelectEdit = VUI:CreateSubMenu(StaffMenu.selectedLocker, "Sélection de la faction", exports["core"]:GetVUIBanner("admin"), true)

function StaffMenu.BuildLockerMenu()
    StaffMenu.builderLocker.Button("Créer un vestiaire", "Créer un nouveau vestiaire", nil, "chevron", false, function()
        selectedLocker = getLockerDefaultData()
    end, StaffMenu.createLocker)

    StaffMenu.builderLocker.Button("Gérer les vestiaires", "", nil, "chevron", false, function()
        selectedLocker = getLockerDefaultData()
    end, StaffMenu.manageLockers)
end

StaffMenu.createLocker.OnOpen(function()
    StaffMenu.createLocker.List('Type de vestiaire', nil, false, lockerTypeLabels, selectedLocker.whitelistType, function(Index)
        selectedLocker.whitelistType = Index
        selectedLocker.whitelistValue = nil -- Reset value when changing type
        StaffMenu.createLocker.refresh()
    end)

    -- Display label for the selected value
    local valueLabel = selectedLocker.whitelistValue or "Non défini"
  if selectedLocker.whitelistValue then
        if selectedLocker.whitelistType == 1 and VFW.Jobs and VFW.Jobs[selectedLocker.whitelistValue] then
            valueLabel = VFW.Jobs[selectedLocker.whitelistValue].label or selectedLocker.whitelistValue
        elseif selectedLocker.whitelistType == 2 and VFW.Factions and VFW.Factions[selectedLocker.whitelistValue] then
            valueLabel = VFW.Factions[selectedLocker.whitelistValue].label or selectedLocker.whitelistValue
        end
    end

    -- Show different button based on selected type
    if selectedLocker.whitelistType == 1 then
        StaffMenu.createLocker.Button("Job autorisé", "Sélectionnez le job", valueLabel, "chevron", false, function()
        end, StaffMenu.lockerJobSelect)
    else
        StaffMenu.createLocker.Button("Faction autorisée", "Sélectionnez la faction", valueLabel, "chevron", false, function()
        end, StaffMenu.lockerFactionSelect)
    end

    StaffMenu.createLocker.Button("Nom du vestiaire", nil, selectedLocker.label or "Non défini", "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du vestiaire", selectedLocker.label or "")
        if label == "" then
            return
        end

        selectedLocker.label = label
        StaffMenu.createLocker.refresh()
    end)

    StaffMenu.createLocker.Button("Position du vestiaire", nil, selectedLocker.position and "Défini" or "Non défini", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        selectedLocker.position = { x = pos.x, y = pos.y, z = pos.z - 0.99 }

        StaffMenu.createLocker.refresh()
    end)

    StaffMenu.createLocker.Button("Position du floating", nil, ("Hauteur: %.2f"):format(selectedLocker.floatingZ or 0.5), "chevron", false, function()
        if not selectedLocker.position then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Vestiaire', message = "Définissez d'abord la position du vestiaire." })
            return
        end
        StaffMenu.createLocker.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(vector3(selectedLocker.position.x, selectedLocker.position.y, selectedLocker.position.z), selectedLocker.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({
            { label = "Monter", control = 172 },
            { label = "Descendre", control = 173 },
            { label = "Valider", control = 201 },
        })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                selectedLocker.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.createLocker.open()
    end)

    StaffMenu.createLocker.Button("Valider la création", "", selectedLocker.label and selectedLocker.position and selectedLocker.whitelistType and selectedLocker.whitelistValue, "check", false, function()
        if not selectedLocker.label or not selectedLocker.position or not selectedLocker.whitelistType or not selectedLocker.whitelistValue then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Casiers',
                message = "Vous devez remplir tous les champs avant de valider la creation."
          })
            return
        end

        selectedLocker.whitelistType = lockerTypes[selectedLocker.whitelistType]
        TriggerServerEvent("core:lockers:create", selectedLocker)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
            message = "Vestiaire créé."
      })
        selectedLocker = getLockerDefaultData()
        StaffMenu.createLocker.close()
        StaffMenu.createLocker.parent.open()
    end)
end)

-- Job selection for creation
StaffMenu.lockerJobSelect.OnOpen(function()
    local jobs = TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not jobs or not next(jobs) then
        StaffMenu.lockerJobSelect.Button("AUCUN JOB DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = selectedLocker.whitelistValue == job.name
        StaffMenu.lockerJobSelect.Button(job.label or job.name, job.name, isSelected and ":check:" or nil, "chevron", false, function()
            selectedLocker.whitelistValue = job.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
                message = "Job sélectionné: " .. (job.label or job.name)
            })
        end)
    end
end)

-- Faction selection for creation
StaffMenu.lockerFactionSelect.OnOpen(function()
    local factions = TriggerServerCallback("core:gestion-factions:getAll") or {}
    StaffMenu.data.factionsList = factions

    if not factions or not next(factions) then
        StaffMenu.lockerFactionSelect.Button("AUCUNE FACTION DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, faction in pairs(factions) do
        local isSelected = selectedLocker.whitelistValue == faction.name
        StaffMenu.lockerFactionSelect.Button(faction.label or faction.name, faction.name, isSelected and ":check:" or nil, "chevron", false, function()
            selectedLocker.whitelistValue = faction.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
                message = "Faction sélectionnée: " .. (faction.label or faction.name)
            })
            StaffMenu.lockerFactionSelect.close()
            StaffMenu.lockerFactionSelect.parent.open()
        end)
    end
end)

local LOCKERS_PER_PAGE = 25
StaffMenu.lockerListPage = StaffMenu.lockerListPage or 1
StaffMenu.lockerListSearch = StaffMenu.lockerListSearch or nil

StaffMenu.manageLockers.OnOpen(function()
    local lockers = TriggerServerCallback("core:lockers:getAll")

    local searchLabel = StaffMenu.lockerListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.lockerListSearch == nil and "Nom du vestiaire / job / faction" or StaffMenu.lockerListSearch
    StaffMenu.manageLockers.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.lockerListSearch ~= nil then
            StaffMenu.lockerListSearch = nil
            StaffMenu.lockerListPage = 1
            StaffMenu.manageLockers.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du vestiaire / job / faction")
        if query == nil or query == "" then return end
        StaffMenu.lockerListSearch = query
        StaffMenu.lockerListPage = 1
        StaffMenu.manageLockers.refresh()
    end)

    if not lockers or not next(lockers) then
        StaffMenu.manageLockers.Separator(nil)
        StaffMenu.manageLockers.Button("AUCUN VESTIAIRE", nil, nil, nil, true, function() end)
        return
    end

    -- Flat list avec icône
    local flat = {}
    for _, locker in pairs(lockers) do
        local icon = locker.whitelistType == "faction" and ":skull:" or ":briefcase:"
      table.insert(flat, { locker = locker, icon = icon, kind = locker.whitelistType or "job" })
    end
    table.sort(flat, function(a, b)
        if a.kind ~= b.kind then return a.kind < b.kind end
        return ((a.locker.label or "")):lower() < ((b.locker.label or "")):lower()
    end)

    local filtered = flat
    if StaffMenu.lockerListSearch and StaffMenu.lockerListSearch ~= "" then
        local q = StaffMenu.lockerListSearch:lower()
        filtered = {}
        for _, e in ipairs(flat) do
            if ((e.locker.label or "")):lower():find(q, 1, true)
                or ((e.locker.whitelistValue or "")):lower():find(q, 1, true) then
                table.insert(filtered, e)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / LOCKERS_PER_PAGE), 1)
    if StaffMenu.lockerListPage > totalPages then StaffMenu.lockerListPage = totalPages end
    if StaffMenu.lockerListPage < 1 then StaffMenu.lockerListPage = 1 end
    local startIdx = (StaffMenu.lockerListPage - 1) * LOCKERS_PER_PAGE + 1
    local endIdx = math.min(startIdx + LOCKERS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.lockerListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d vestiaires, page %d sur %d", totalItems, StaffMenu.lockerListPage, totalPages)
    end
    StaffMenu.manageLockers.Separator(header)

    if totalItems == 0 then
        StaffMenu.manageLockers.Button("AUCUN RÉSULTAT", nil, nil, nil, true, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local e = filtered[idx]
        StaffMenu.manageLockers.Button(e.icon .. " " .. (e.locker.label or "?"), e.locker.whitelistValue, nil, "chevron", false, function()
            selectedLocker = e.locker
        end, StaffMenu.selectedLocker)
    end

    if totalPages > 1 then
        StaffMenu.manageLockers.Separator(nil)
        if StaffMenu.lockerListPage > 1 then
            StaffMenu.manageLockers.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.lockerListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.lockerListPage = StaffMenu.lockerListPage - 1
                StaffMenu.manageLockers.refresh()
            end)
        end
        if StaffMenu.lockerListPage < totalPages then
            StaffMenu.manageLockers.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.lockerListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.lockerListPage = StaffMenu.lockerListPage + 1
                StaffMenu.manageLockers.refresh()
            end)
        end
    end
end)

StaffMenu.selectedLocker.OnOpen(function()
    if not selectedLocker or not selectedLocker.id then
        return
    end

    StaffMenu.selectedLocker.Button("Nom du vestiaire", nil, selectedLocker.label or "Non défini", "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrez le nom du vestiaire", selectedLocker.label or "")
        if label == "" then
            return
        end

        selectedLocker.label = label
        StaffMenu.selectedLocker.refresh()
    end)

    StaffMenu.selectedLocker.Button("Position du vestiaire", nil, selectedLocker.position and "Défini" or "Non défini", "chevron", false, function()
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        selectedLocker.position = { x = pos.x, y = pos.y, z = pos.z - 0.99 }

        StaffMenu.selectedLocker.refresh()
    end)

    -- Type selector
    local currentTypeIndex = 1
    if selectedLocker.whitelistType == "faction" then
        currentTypeIndex = 2
    end

    StaffMenu.selectedLocker.List('Type de vestiaire', nil, false, lockerTypeLabels, currentTypeIndex, function(Index)
        selectedLocker.whitelistType = lockerTypes[Index]
        selectedLocker.whitelistValue = nil -- Reset value when changing type
        StaffMenu.selectedLocker.refresh()
    end)

    -- Display label for the selected value
    local editValueLabel = selectedLocker.whitelistValue or "Non défini"
  if selectedLocker.whitelistValue then
        if selectedLocker.whitelistType == "job" and VFW.Jobs and VFW.Jobs[selectedLocker.whitelistValue] then
            editValueLabel = VFW.Jobs[selectedLocker.whitelistValue].label or selectedLocker.whitelistValue
        elseif selectedLocker.whitelistType == "faction" and VFW.Factions and VFW.Factions[selectedLocker.whitelistValue] then
            editValueLabel = VFW.Factions[selectedLocker.whitelistValue].label or selectedLocker.whitelistValue
        end
    end

    -- Show different button based on selected type
    if selectedLocker.whitelistType == "job" or selectedLocker.whitelistType == nil then
        StaffMenu.selectedLocker.Button("Job autorisé", "Sélectionnez le job", editValueLabel, "chevron", false, function()
        end, StaffMenu.lockerJobSelectEdit)
    else
        StaffMenu.selectedLocker.Button("Faction autorisée", "Sélectionnez la faction", editValueLabel, "chevron", false, function()
        end, StaffMenu.lockerFactionSelectEdit)
    end

    StaffMenu.selectedLocker.Button("Position du floating", nil, ("Hauteur: %.2f"):format(selectedLocker.floatingZ or 0.5), "chevron", false, function()
        if not selectedLocker.position then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Vestiaire', message = "Position non définie." })
            return
        end
        StaffMenu.selectedLocker.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(vector3(selectedLocker.position.x, selectedLocker.position.y, selectedLocker.position.z), selectedLocker.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({
            { label = "Monter", control = 172 },
            { label = "Descendre", control = 173 },
            { label = "Valider", control = 201 },
        })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                selectedLocker.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.selectedLocker.open()
    end)

    StaffMenu.selectedLocker.Checkbox("Afficher le blip sur la carte", nil, selectedLocker.showBlip or false, function(Checked)
        selectedLocker.showBlip = Checked
        StaffMenu.selectedLocker.refresh()
    end)

    StaffMenu.selectedLocker.Button("Valider les modifications", nil, "" , "chevron", false, function()
        if not selectedLocker.label or not selectedLocker.position then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Casiers',
                message = "Vous devez remplir tous les champs avant de valider les modifications."
          })
            return
        end

        TriggerServerEvent("core:lockers:update", selectedLocker.id, selectedLocker)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
            message = "Vestiaire modifié."
      })
        StaffMenu.selectedLocker.close()
        StaffMenu.selectedLocker.parent.open()
    end)

    StaffMenu.selectedLocker.Button("Supprimer le vestiaire", nil, nil, "trash", false, function()
        TriggerServerEvent("core:lockers:remove", selectedLocker.id)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
            message = "Vestiaire supprimé."
      })
        StaffMenu.selectedLocker.close()
        StaffMenu.selectedLocker.parent.open()
    end)
end)

-- Job selection for edit
StaffMenu.lockerJobSelectEdit.OnOpen(function()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not jobs or not next(jobs) then
        StaffMenu.lockerJobSelectEdit.Button("AUCUN JOB DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = selectedLocker.whitelistValue == job.name
        StaffMenu.lockerJobSelectEdit.Button(job.label or job.name, job.name, isSelected and ":check:" or nil, "chevron", false, function()
            selectedLocker.whitelistValue = job.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
                message = "Job sélectionné: " .. (job.label or job.name)
            })
            StaffMenu.lockerJobSelectEdit.close()
            StaffMenu.lockerJobSelectEdit.parent.open()
        end)
    end
end)

-- Faction selection for edit
StaffMenu.lockerFactionSelectEdit.OnOpen(function()
    local factions = StaffMenu.data.factionsList or TriggerServerCallback("core:gestion-factions:getAll") or {}
    StaffMenu.data.factionsList = factions

    if not factions or not next(factions) then
        StaffMenu.lockerFactionSelectEdit.Button("AUCUNE FACTION DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, faction in pairs(factions) do
        local isSelected = selectedLocker.whitelistValue == faction.name
        StaffMenu.lockerFactionSelectEdit.Button(faction.label or faction.name, faction.name, isSelected and ":check:" or nil, "chevron", false, function()
            selectedLocker.whitelistValue = faction.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Casiers',
                message = "Faction sélectionnée: " .. (faction.label or faction.name)
            })
            StaffMenu.lockerFactionSelectEdit.close()
            StaffMenu.lockerFactionSelectEdit.parent.open()
        end)
    end
end)