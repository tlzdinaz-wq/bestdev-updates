-- Society Locker Builder
local VUI = exports["VUI"]

local selectedSocietyLocker = nil

function getSocietyLockerDefaultData()
    return {
        label = nil,
        position = nil,
        job = nil,
        maxWeight = 500,
        maxSlots = 50,
        floatingZ = 0.5
    }
end

StaffMenu.createSocietyLocker = VUI:CreateSubMenu(StaffMenu.builderSocietyLocker, "Créer un casier", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.manageSocietyLockers = VUI:CreateSubMenu(StaffMenu.builderSocietyLocker, "Gérer les casiers", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.selectedSocietyLocker = VUI:CreateSubMenu(StaffMenu.manageSocietyLockers, "Casier sélectionné", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.societyLockerJobSelect = VUI:CreateSubMenu(StaffMenu.createSocietyLocker, "Sélection du job", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.societyLockerJobSelectEdit = VUI:CreateSubMenu(StaffMenu.selectedSocietyLocker, "Sélection du job", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.archivedSocietyLockers = VUI:CreateSubMenu(StaffMenu.selectedSocietyLocker, "Casiers supprimés", exports["core"]:GetVUIBanner("admin"), true)
StaffMenu.archivedLockerContent = VUI:CreateSubMenu(StaffMenu.archivedSocietyLockers, "Contenu du casier", exports["core"]:GetVUIBanner("admin"), true)

local selectedArchivedLocker = nil

function StaffMenu.BuildSocietyLockerMenu()
    StaffMenu.builderSocietyLocker.Button("Créer un casier", "Créer un nouveau casier de société", nil, "chevron", false, function()
        selectedSocietyLocker = getSocietyLockerDefaultData()
    end, StaffMenu.createSocietyLocker)

    StaffMenu.builderSocietyLocker.Button("Gérer les casiers", "Modifier ou supprimer des casiers existants", nil, "chevron", false, function()
        selectedSocietyLocker = nil
    end, StaffMenu.manageSocietyLockers)
end

StaffMenu.createSocietyLocker.OnOpen(function()
    StaffMenu.createSocietyLocker.Button("Nom du casier", nil, selectedSocietyLocker.label or "Non défini", "chevron", false, function()
        local label = VFW.Nui.KeyboardInput(true, "Entrez le nom du casier", selectedSocietyLocker.label or "")
        if label == "" then
            return
        end

        selectedSocietyLocker.label = label
        StaffMenu.createSocietyLocker.refresh()
    end)

    StaffMenu.createSocietyLocker.Button("Position du casier", nil, selectedSocietyLocker.position and "Défini" or "Non défini", "chevron", false, function()
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        selectedSocietyLocker.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, h = heading }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
            message = "Position définie à votre emplacement actuel"
      })
        StaffMenu.createSocietyLocker.refresh()
    end)

    StaffMenu.createSocietyLocker.Button("Job autorisé", nil, selectedSocietyLocker.job or "Non défini", "chevron", false, function()
    end, StaffMenu.societyLockerJobSelect)

    StaffMenu.createSocietyLocker.Button("Poids maximum ", nil, tostring(selectedSocietyLocker.maxWeight or 100000), "chevron", false, function()
        local weight = VFW.Nui.KeyboardInput(true, "Entrez le poids maximum", tostring(selectedSocietyLocker.maxWeight or 100000))
        if weight == "" then
            return
        end

        local weightNum = tonumber(weight)
        if not weightNum then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Veuillez entrer un nombre valide"
          })
            return
        end

        selectedSocietyLocker.maxWeight = weightNum
        StaffMenu.createSocietyLocker.refresh()
    end)

    StaffMenu.createSocietyLocker.Button("Slots maximum", nil, tostring(selectedSocietyLocker.maxSlots or 50), "chevron", false, function()
        local slots = VFW.Nui.KeyboardInput(true, "Entrez le nombre de slots maximum", tostring(selectedSocietyLocker.maxSlots or 50))
        if slots == "" then
            return
        end

        local slotsNum = tonumber(slots)
        if not slotsNum then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Veuillez entrer un nombre valide"
          })
            return
        end

        selectedSocietyLocker.maxSlots = slotsNum
        StaffMenu.createSocietyLocker.refresh()
    end)

    StaffMenu.createSocietyLocker.Button("Position du floating", nil, ("Hauteur: %.2f"):format(selectedSocietyLocker.floatingZ or 0.5), "chevron", false, function()
        if not selectedSocietyLocker.position then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société', message = "Définissez d'abord la position." })
            return
        end
        StaffMenu.createSocietyLocker.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(vector3(selectedSocietyLocker.position.x, selectedSocietyLocker.position.y, selectedSocietyLocker.position.z), selectedSocietyLocker.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({ { label = "Monter", control = 172 }, { label = "Descendre", control = 173 }, { label = "Valider", control = 201 } })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                selectedSocietyLocker.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.createSocietyLocker.open()
    end)

    local canValidate = selectedSocietyLocker.label and selectedSocietyLocker.position and selectedSocietyLocker.job
    StaffMenu.createSocietyLocker.Button("Valider la création", nil, canValidate and "Prêt" or "Incomplet", canValidate and "check" or "lock", not canValidate, function()
        if not selectedSocietyLocker.label or not selectedSocietyLocker.position or not selectedSocietyLocker.job then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Vous devez remplir tous les champs obligatoires (nom, position, job)"
          })
            return
        end

        TriggerServerEvent("core:societyLockers:create", selectedSocietyLocker)
        StaffMenu.createSocietyLocker.close()
    end)
end)

StaffMenu.societyLockerJobSelect.OnOpen(function()
    local jobs = TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not jobs or not next(jobs) then
        StaffMenu.societyLockerJobSelect.Button("AUCUN JOB DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        StaffMenu.societyLockerJobSelect.Button(job.label or job.name, job.name, nil, "chevron", false, function()
            selectedSocietyLocker.job = job.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
                message = "Job sélectionné: " .. (job.label or job.name)
            })
        end)
    end
end)

local SOCIETY_LOCKERS_PER_PAGE = 25
StaffMenu.societyLockerListPage = StaffMenu.societyLockerListPage or 1
StaffMenu.societyLockerListSearch = StaffMenu.societyLockerListSearch or nil

StaffMenu.manageSocietyLockers.OnOpen(function()
    local lockers = TriggerServerCallback("core:societyLockers:getAll")

    local searchLabel = StaffMenu.societyLockerListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.societyLockerListSearch == nil and "Nom du casier / société" or StaffMenu.societyLockerListSearch
    StaffMenu.manageSocietyLockers.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.societyLockerListSearch ~= nil then
            StaffMenu.societyLockerListSearch = nil
            StaffMenu.societyLockerListPage = 1
            StaffMenu.manageSocietyLockers.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du casier / société")
        if query == nil or query == "" then return end
        StaffMenu.societyLockerListSearch = query
        StaffMenu.societyLockerListPage = 1
        StaffMenu.manageSocietyLockers.refresh()
    end)

    if not lockers or not next(lockers) then
        StaffMenu.manageSocietyLockers.Separator(nil)
        StaffMenu.manageSocietyLockers.Button("AUCUN CASIER DE SOCIÉTÉ", nil, nil, nil, true, function() end)
        return
    end

    local flat = {}
    for _, locker in pairs(lockers) do
        local job = locker.job or "unknown"
      local jobLabel = job
        if VFW.Jobs and VFW.Jobs[job] then
            jobLabel = VFW.Jobs[job].label or job
        end
        table.insert(flat, { locker = locker, job = job, jobLabel = jobLabel })
    end
    table.sort(flat, function(a, b)
        if a.job ~= b.job then return a.job < b.job end
        return ((a.locker.label or "")):lower() < ((b.locker.label or "")):lower()
    end)

    local filtered = flat
    if StaffMenu.societyLockerListSearch and StaffMenu.societyLockerListSearch ~= "" then
        local q = StaffMenu.societyLockerListSearch:lower()
        filtered = {}
        for _, e in ipairs(flat) do
            if ((e.locker.label or "")):lower():find(q, 1, true)
                or ((e.jobLabel or "")):lower():find(q, 1, true)
                or ((e.job or "")):lower():find(q, 1, true) then
                table.insert(filtered, e)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / SOCIETY_LOCKERS_PER_PAGE), 1)
    if StaffMenu.societyLockerListPage > totalPages then StaffMenu.societyLockerListPage = totalPages end
    if StaffMenu.societyLockerListPage < 1 then StaffMenu.societyLockerListPage = 1 end
    local startIdx = (StaffMenu.societyLockerListPage - 1) * SOCIETY_LOCKERS_PER_PAGE + 1
    local endIdx = math.min(startIdx + SOCIETY_LOCKERS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.societyLockerListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d casiers de société, page %d sur %d", totalItems, StaffMenu.societyLockerListPage, totalPages)
    end
    StaffMenu.manageSocietyLockers.Separator(header)

    if totalItems == 0 then
        StaffMenu.manageSocietyLockers.Button("AUCUN RÉSULTAT", nil, nil, nil, true, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local e = filtered[idx]
        StaffMenu.manageSocietyLockers.Button(":briefcase: " .. (e.locker.label or "?"), e.jobLabel, nil, "chevron", false, function()
            selectedSocietyLocker = e.locker
        end, StaffMenu.selectedSocietyLocker)
    end

    if totalPages > 1 then
        StaffMenu.manageSocietyLockers.Separator(nil)
        if StaffMenu.societyLockerListPage > 1 then
            StaffMenu.manageSocietyLockers.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.societyLockerListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.societyLockerListPage = StaffMenu.societyLockerListPage - 1
                StaffMenu.manageSocietyLockers.refresh()
            end)
        end
        if StaffMenu.societyLockerListPage < totalPages then
            StaffMenu.manageSocietyLockers.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.societyLockerListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.societyLockerListPage = StaffMenu.societyLockerListPage + 1
                StaffMenu.manageSocietyLockers.refresh()
            end)
        end
    end
end)

StaffMenu.selectedSocietyLocker.OnOpen(function()
    if not selectedSocietyLocker or not selectedSocietyLocker.id then
        return
    end

    StaffMenu.selectedSocietyLocker.Button("Nom du casier", nil, selectedSocietyLocker.label or "Non défini", "chevron", false, function()
        local label = VFW.Nui.KeyboardInput(true, "Entrez le nom du casier", selectedSocietyLocker.label or "")
        if label == "" then
            return
        end

        selectedSocietyLocker.label = label
        StaffMenu.selectedSocietyLocker.refresh()
    end)

    StaffMenu.selectedSocietyLocker.Button("Position du casier", nil, selectedSocietyLocker.position and "Défini" or "Non défini", "chevron", false, function()
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        selectedSocietyLocker.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, h = heading }

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
            message = "Position mise à jour à votre emplacement actuel"
      })
        StaffMenu.selectedSocietyLocker.refresh()
    end)

    StaffMenu.selectedSocietyLocker.Button("Position du floating", nil, ("Hauteur: %.2f"):format(selectedSocietyLocker.floatingZ or 0.5), "chevron", false, function()
        if not selectedSocietyLocker.position then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société', message = "Position non définie." })
            return
        end
        StaffMenu.selectedSocietyLocker.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(vector3(selectedSocietyLocker.position.x, selectedSocietyLocker.position.y, selectedSocietyLocker.position.z), selectedSocietyLocker.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({ { label = "Monter", control = 172 }, { label = "Descendre", control = 173 }, { label = "Valider", control = 201 } })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                selectedSocietyLocker.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.selectedSocietyLocker.open()
    end)

    StaffMenu.selectedSocietyLocker.Button("Se téléporter au casier", nil, nil, "chevron", false, function()
        if selectedSocietyLocker.position then
            local pos = selectedSocietyLocker.position
            SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z + 1.0, false, false, false, false)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
                message = "Téléporté au casier"
          })
        end
    end)

    local currentJobLabel = selectedSocietyLocker.job
    if VFW.Jobs and VFW.Jobs[selectedSocietyLocker.job] then
        currentJobLabel = VFW.Jobs[selectedSocietyLocker.job].label or selectedSocietyLocker.job
    end
    StaffMenu.selectedSocietyLocker.Button("Job autorisé", nil, currentJobLabel or "Non défini", "chevron", false, function()
    end, StaffMenu.societyLockerJobSelectEdit)

    StaffMenu.selectedSocietyLocker.Button("Poids maximum (g)", nil, tostring(selectedSocietyLocker.maxWeight or 100000), "chevron", false, function()
        local weight = VFW.Nui.KeyboardInput(true, "Entrez le poids maximum en grammes", tostring(selectedSocietyLocker.maxWeight or 100000))
        if weight == "" then
            return
        end

        local weightNum = tonumber(weight)
        if not weightNum then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Veuillez entrer un nombre valide"
          })
            return
        end

        selectedSocietyLocker.maxWeight = weightNum
        StaffMenu.selectedSocietyLocker.refresh()
    end)

    StaffMenu.selectedSocietyLocker.Button("Slots maximum", nil, tostring(selectedSocietyLocker.maxSlots or 50), "chevron", false, function()
        local slots = VFW.Nui.KeyboardInput(true, "Entrez le nombre de slots maximum", tostring(selectedSocietyLocker.maxSlots or 50))
        if slots == "" then
            return
        end

        local slotsNum = tonumber(slots)
        if not slotsNum then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Veuillez entrer un nombre valide"
          })
            return
        end

        selectedSocietyLocker.maxSlots = slotsNum
        StaffMenu.selectedSocietyLocker.refresh()
    end)

    StaffMenu.selectedSocietyLocker.Separator("ACTIONS")

    StaffMenu.selectedSocietyLocker.Button("Voir les casiers supprimés", "Casiers archivés des anciens employés", nil, "chevron", false, function()
        selectedArchivedLocker = nil
    end, StaffMenu.archivedSocietyLockers)

    StaffMenu.selectedSocietyLocker.Button("Sauvegarder les modifications", nil, nil, "check", false, function()
        if not selectedSocietyLocker.label or not selectedSocietyLocker.position or not selectedSocietyLocker.job then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Vous devez remplir tous les champs obligatoires"
          })
            return
        end

        TriggerServerEvent("core:societyLockers:update", selectedSocietyLocker.id, selectedSocietyLocker)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
            message = "Casier mis à jour"
      })
        StaffMenu.selectedSocietyLocker.close()
    end)

    StaffMenu.selectedSocietyLocker.Button("Supprimer le casier", "Cette action est irréversible", nil, "trash", false, function()
        TriggerServerEvent("core:societyLockers:remove", selectedSocietyLocker.id)
        StaffMenu.selectedSocietyLocker.close()
    end)
end)

StaffMenu.societyLockerJobSelectEdit.OnOpen(function()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not jobs or not next(jobs) then
        StaffMenu.societyLockerJobSelectEdit.Button("AUCUN JOB DISPONIBLE", nil, nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = selectedSocietyLocker.job == job.name
        StaffMenu.societyLockerJobSelectEdit.Button(job.label or job.name, job.name, isSelected and ":check:" or nil, "chevron", false, function()
            selectedSocietyLocker.job = job.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
                message = "Job sélectionné: " .. (job.label or job.name)
            })
            StaffMenu.societyLockerJobSelectEdit.close()
            StaffMenu.societyLockerJobSelectEdit.parent.open()
        end)
    end
end)

-- Menu des casiers archivés
StaffMenu.archivedSocietyLockers.OnOpen(function()
    if not selectedSocietyLocker or not selectedSocietyLocker.id then
        StaffMenu.archivedSocietyLockers.Button("ERREUR", "Aucun casier sélectionné", nil, nil, true, function() end)
        return
    end

    local archived = TriggerServerCallback("core:societyLockers:getArchivedByLocker", selectedSocietyLocker.id)

    if not archived or #archived == 0 then
        StaffMenu.archivedSocietyLockers.Button("AUCUN CASIER ARCHIVÉ", "Aucun ancien employé n'a laissé d'items", nil, nil, true, function() end)
        return
    end

    for _, archive in ipairs(archived) do
        local weightStr = archive.totalWeight >= 1000 and string.format("%.1fkg", archive.totalWeight / 1000) or (archive.totalWeight .. "g")

        StaffMenu.archivedSocietyLockers.Button(
            archive.playerName,
            archive.itemCount .. " items - " .. weightStr .. " | " .. (archive.archivedAtFormatted or "Date inconnue"),
            nil,
            "chevron",
            false,
            function()
                selectedArchivedLocker = archive
            end,
            StaffMenu.archivedLockerContent
        )
    end
end)

-- Menu du contenu d'un casier archivé
StaffMenu.archivedLockerContent.OnOpen(function()
    if not selectedArchivedLocker then
        StaffMenu.archivedLockerContent.Button("ERREUR", "Aucun casier archivé sélectionné", nil, nil, true, function() end)
        return
    end

    StaffMenu.archivedLockerContent.Separator(":box: CONTENU DU CASIER")

    if not selectedArchivedLocker.items or #selectedArchivedLocker.items == 0 then
        StaffMenu.archivedLockerContent.Button("AUCUN ITEM", nil, nil, nil, true, function() end)
    else
        for _, item in ipairs(selectedArchivedLocker.items) do
            StaffMenu.archivedLockerContent.Button(
                item.label or item.name,
                "Quantité: " .. (item.count or 1),
                "x" .. (item.count or 1),
                nil,
                true,
                function() end
            )
        end
    end

    StaffMenu.archivedLockerContent.Separator("ACTIONS")

    StaffMenu.archivedLockerContent.Button("Supprimer définitivement", "Supprime l'archive de la base de données", nil, "trash", false, function()
        local success = TriggerServerCallback("core:societyLockers:deleteArchivedLocker", selectedArchivedLocker.id)
        if success then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Casier Société',
                message = "Casier archivé supprimé"
          })
            StaffMenu.archivedLockerContent.close()
            selectedArchivedLocker = nil
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Casier Société',
                message = "Erreur lors de la suppression"
          })
        end
    end)
end)
