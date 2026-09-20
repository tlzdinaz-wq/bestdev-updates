---@meta _
---@diagnostic disable: duplicate-doc-field

local chestData = {
    name = nil,
    maxWeight = nil,
    maxSlots = nil,
    coords = nil,
    pincode = nil,
    accessName = nil,
    accessType = nil,
    gradeMinPut = nil,
    gradeMinTake = nil,
    gradeMinHistory = nil,
    floatingZ = 0.5
}

--- Reset chest data to defaults
function resetChestData()
    chestData = {
        name = nil,
        maxWeight = nil,
        maxSlots = nil,
        coords = nil,
        pincode = nil,
        accessName = nil,
        accessType = nil,
        gradeMinPut = nil,
        gradeMinTake = nil,
        gradeMinHistory = nil,
        floatingZ = 0.5
    }
end

--- Close the chest creator menu and reset data
local function closeChestCreator()
    chestData = {
        name = nil,
        maxWeight = nil,
        maxSlots = nil,
        coords = nil,
        pincode = nil,
        accessName = nil,
        accessType = nil,
        gradeMinPut = nil,
        gradeMinTake = nil,
        gradeMinHistory = nil,
        floatingZ = 0.5
    }
    StaffMenu.CreateChest.close()
    StaffMenu.builderChest.open()
end

--- Check if the chest data is valid
--- @return boolean
local function checkValidChestData()
    if not chestData.name or not chestData.maxWeight or not chestData.coords then
        return false
    end
    return true
end

--- Build access type menu
function StaffMenu.BuildChestAccessTypeMenu()
    StaffMenu.ChestAccessType.Button(":globe: PUBLIC", "Accessible à tous", nil, (chestData.accessType == nil or chestData.accessType == "public") and "check" or "chevron", false, function()
        chestData.accessName = nil
        chestData.accessType = "public"
      StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.ChestAccessType.Button(":briefcase: JOB (Légal)", "Choisir un job", nil, chestData.accessType == "job" and "check" or "chevron", false, function()
    end, StaffMenu.ChestAccessJob)

    StaffMenu.ChestAccessType.Button(":skull: FACTION (Illégal)", "Choisir une faction", nil, chestData.accessType == "faction" and "check" or "chevron", false, function()
    end, StaffMenu.ChestAccessFaction)

    StaffMenu.ChestAccessType.Separator()

    StaffMenu.ChestAccessType.Button(":edit: MANUEL", "Taper le nom manuellement", nil, chestData.accessType == "manual" and "check" or "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du job ou de la faction")
        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce nom n'est pas valide"
          })
        end
        chestData.accessName = name
        chestData.accessType = "manual"
      StaffMenu.CreateChest.refresh()
    end)
end

--- Build job selection menu
function StaffMenu.BuildChestAccessJobMenu()
    local jobs = TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not next(jobs) then
        StaffMenu.ChestAccessJob.Button("AUCUN JOB", "Pas de jobs disponibles", nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = chestData.accessName == job.name
        StaffMenu.ChestAccessJob.Button(
            job.label or job.name,
            job.name,
            nil,
            isSelected and "check" or "chevron",
            false,
            function()
                chestData.accessName = job.name
                chestData.accessType = "job"
              VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Coffres', message = "Job sélectionné: " .. (job.label or job.name) })
                StaffMenu.CreateChest.refresh()
            end
        )
    end
end

--- Build faction selection menu
function StaffMenu.BuildChestAccessFactionMenu()
    local factions = TriggerServerCallback("core:gestion-factions:getAll") or {}

    if not factions or #factions == 0 then
        StaffMenu.ChestAccessFaction.Button("AUCUNE FACTION", "Pas de factions disponibles", nil, nil, true, function() end)
        return
    end

    for _, faction in pairs(factions) do
        local isSelected = chestData.accessName == faction.name
        local statusIcon = faction.active and ":check:" or ":hourglass:"
      StaffMenu.ChestAccessFaction.Button(
            statusIcon .. " " .. (faction.label or faction.name),
            faction.name,
            nil,
            isSelected and "check" or "chevron",
            false,
            function()
                chestData.accessName = faction.name
                chestData.accessType = "faction"
              VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Coffres', message = "Faction sélectionnée: " .. (faction.label or faction.name) })
                StaffMenu.CreateChest.refresh()
            end
        )
    end
end

function StaffMenu.BuildCreateChestMenu()
    StaffMenu.CreateChest.Button("NOM DU COFFRE", nil, chestData.name, "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du coffre")

        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce nom n'est pas valide"
          })
        end

        chestData.name = name
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Button("POIDS DU COFFRE", nil, chestData.maxWeight, "chevron", false, function()
        local weight <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le poids du coffre (en kg)"))

        if not weight or weight <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce poids n'est pas valide"
          })
        end

        chestData.maxWeight = weight
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Button("NOMBRE DE SLOTS", nil, chestData.maxSlots or "Non défini", "chevron", false, function()
        local slots <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le nombre de slots (laisser vide pour illimité)"))

        if slots and slots <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce nombre de slots n'est pas valide"
          })
        end

        chestData.maxSlots = slots
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Button("DÉFINIR LA POSITION", nil, nil, chestData.coords and "check" or "chevron", false, function()
        local playerCoords <const> = GetEntityCoords(PlayerPedId())

        if not playerCoords then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Cette position n'est pas valide"
          })
        end

        chestData.coords = playerCoords
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Separator("GESTION DES ACCÈS")

    StaffMenu.CreateChest.Button("METTRE UN PIN CODE", nil, chestData.pincode, "chevron", false, function()
        local pincode <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le pin code du coffre (max 9 chiffres)"))

        if not pincode or pincode <= 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce code PIN n'est pas valide"
          })
        end

        if #tostring(pincode) > 9 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Pin code trop long"
          })
        end

        chestData.pincode = pincode
        StaffMenu.CreateChest.refresh()
    end)

    local accessRightLabel = "Public"
  if chestData.accessType == "job" then
        accessRightLabel = ":briefcase: " .. (chestData.accessName or "Non défini")
    elseif chestData.accessType == "faction" then
        accessRightLabel = ":skull: " .. (chestData.accessName or "Non défini")
    elseif chestData.accessType == "manual" and chestData.accessName then
        accessRightLabel = ":edit: " .. chestData.accessName
    end

    StaffMenu.CreateChest.Button("AJOUTER / GÉRER LES ACCÈS", nil, accessRightLabel, "chevron", false, function()
    end, StaffMenu.ChestAccessType)

    StaffMenu.CreateChest.Separator("RESTRICTION DE GRADE")

    StaffMenu.CreateChest.Button("GRADE MIN POUR DÉPOSER", nil, chestData.gradeMinPut or "Aucune restriction", "chevron", false, function()
        local grade <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le grade min pour déposer (laisser vide pour aucune restriction)"))

        if grade and grade < 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce grade n'est pas valide"
          })
        end

        chestData.gradeMinPut = grade
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Button("GRADE MIN POUR RETIRER", nil, chestData.gradeMinTake or "Aucune restriction", "chevron", false, function()
        local grade <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le grade min pour retirer (laisser vide pour aucune restriction)"))

        if grade and grade < 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce grade n'est pas valide"
          })
        end

        chestData.gradeMinTake = grade
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Button("GRADE MIN POUR L'HISTORIQUE", nil, chestData.gradeMinHistory or "Aucun accès", "chevron", false, function()
        local grade <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le grade min pour l'historique (laisser vide pour bloquer l'accès)"))

        if grade and grade < 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ce grade n'est pas valide"
          })
        end

        chestData.gradeMinHistory = grade
        StaffMenu.CreateChest.refresh()
    end)

    StaffMenu.CreateChest.Button("Position du floating", nil, ("Hauteur: %.2f"):format(chestData.floatingZ or 0.5), "chevron", false, function()
        if not chestData.coords then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres', message = "Définissez d'abord la position." })
            return
        end
        StaffMenu.CreateChest.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(vector3(chestData.coords.x, chestData.coords.y, chestData.coords.z), chestData.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({ { label = "Monter", control = 172 }, { label = "Descendre", control = 173 }, { label = "Valider", control = 201 } })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                chestData.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.CreateChest.open()
    end)

    StaffMenu.CreateChest.Separator()

    StaffMenu.CreateChest.Button(":check: CRÉER / MODIFIER LE COFFRE", nil, nil, "chevron", false, function()
        if not checkValidChestData() then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Ces données ne sont pas valides, veuillez vérifier que vous avez bien rempli les champs suivant : nom, poids et position"
          })
        end

        if chestData.isUpdate then
            TriggerServerEvent("chestBuilder:server:update", {
                id = chestData.id,
                label = chestData.name,
                maxWeight = chestData.maxWeight,
                maxSlots = chestData.maxSlots,
                coords = chestData.coords,
                gradeMinPut = chestData.gradeMinPut,
                gradeMinTake = chestData.gradeMinTake,
                gradeMinHistory = chestData.gradeMinHistory,
                accessName = chestData.accessName,
                accessType = chestData.accessType,
                pincode = chestData.pincode,
                floatingZ = chestData.floatingZ
            })
        else
            TriggerServerEvent("chestBuilder:server:create", {
                label = chestData.name,
                maxWeight = chestData.maxWeight,
                maxSlots = chestData.maxSlots,
                accessName = chestData.accessName,
                accessType = chestData.accessType,
                coords = chestData.coords,
                pincode = chestData.pincode,
                gradeMinPut = chestData.gradeMinPut,
                gradeMinTake = chestData.gradeMinTake,
                gradeMinHistory = chestData.gradeMinHistory,
                floatingZ = chestData.floatingZ
            })
        end

        closeChestCreator()
    end)

    StaffMenu.CreateChest.Button(":x: Annuler", nil, nil, "chevron", false, function()
        closeChestCreator()
    end)
end

local currentChest
local CHESTS_PER_PAGE = 25
StaffMenu.chestListPage = StaffMenu.chestListPage or 1
StaffMenu.chestListSearch = StaffMenu.chestListSearch or nil

function StaffMenu.BuildChestListMenu()
    local chests <const> = TriggerServerCallback("chestBuilder:getAllChests")

    -- Search bar (toggle: cliquer pour saisir, recliquer pour reset)
    local searchLabel = StaffMenu.chestListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.chestListSearch == nil and "Nom du coffre / société / faction" or StaffMenu.chestListSearch
    StaffMenu.ChestList.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.chestListSearch ~= nil then
            StaffMenu.chestListSearch = nil
            StaffMenu.chestListPage = 1
            StaffMenu.ChestList.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du coffre / société / faction")
        if query == nil or query == "" then return end
        StaffMenu.chestListSearch = query
        StaffMenu.chestListPage = 1
        StaffMenu.ChestList.refresh()
    end)

    if not chests or not next(chests) then
        StaffMenu.ChestList.Separator(nil)
        StaffMenu.ChestList.Button("AUCUN COFFRE", nil, nil, nil, false, function()end)
        return
    end

    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs
    local factions = TriggerServerCallback("core:gestion-factions:getAll") or {}

    local jobNames, factionNames = {}, {}
    for _, job in pairs(jobs) do jobNames[job.name] = true end
    for _, faction in pairs(factions) do factionNames[faction.name] = true end

    -- Build a flat list avec icône de type
    local flat = {}
    for _, chest in pairs(chests) do
        local accessName = chest.accessName
        local icon, kind
        if not accessName or accessName == "" or accessName == "public" then
            icon, kind = ":globe:", "public"
      elseif factionNames[accessName] then
            icon, kind = ":skull:", "faction"
      elseif jobNames[accessName] then
            icon, kind = ":briefcase:", "job"
      else
            icon, kind = ":briefcase:", "job"
      end
        table.insert(flat, { chest = chest, icon = icon, kind = kind, name = chest.name or "", access = accessName or "" })
    end

    -- Tri stable: par icône puis par nom
    table.sort(flat, function(a, b)
        if a.kind ~= b.kind then return a.kind < b.kind end
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    -- Filtre recherche (case-insensitive sur nom + access)
    local filtered = flat
    if StaffMenu.chestListSearch and StaffMenu.chestListSearch ~= "" then
        local q = StaffMenu.chestListSearch:lower()
        filtered = {}
        for _, entry in ipairs(flat) do
            if entry.name:lower():find(q, 1, true) or entry.access:lower():find(q, 1, true) then
                table.insert(filtered, entry)
            end
        end
    end

    -- Pagination
    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / CHESTS_PER_PAGE), 1)
    if StaffMenu.chestListPage > totalPages then StaffMenu.chestListPage = totalPages end
    if StaffMenu.chestListPage < 1 then StaffMenu.chestListPage = 1 end
    local startIdx = (StaffMenu.chestListPage - 1) * CHESTS_PER_PAGE + 1
    local endIdx = math.min(startIdx + CHESTS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.chestListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d coffres, page %d sur %d", totalItems, StaffMenu.chestListPage, totalPages)
    end
    StaffMenu.ChestList.Separator(header)

    if totalItems == 0 then
        StaffMenu.ChestList.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function()end)
        return
    end

    for idx = startIdx, endIdx do
        local entry = filtered[idx]
        local chest = entry.chest
        local sub
        if entry.kind == "public" then
            sub = tostring(chest.maxWeight or "?") .. "kg / " .. tostring(chest.maxSlots or "?") .. " slots"
      else
            sub = chest.accessName .. ", " .. tostring(chest.maxWeight or "?") .. "kg / " .. tostring(chest.maxSlots or "?") .. " slots"
      end
        StaffMenu.ChestList.Button(entry.icon .. " " .. chest.name, sub, nil, "chevron", false, function()
            currentChest = chest
        end, StaffMenu.ChestManage)
    end

    if totalPages > 1 then
        StaffMenu.ChestList.Separator(nil)
        if StaffMenu.chestListPage > 1 then
            StaffMenu.ChestList.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.chestListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.chestListPage = StaffMenu.chestListPage - 1
                StaffMenu.ChestList.refresh()
            end)
        end
        if StaffMenu.chestListPage < totalPages then
            StaffMenu.ChestList.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.chestListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.chestListPage = StaffMenu.chestListPage + 1
                StaffMenu.ChestList.refresh()
            end)
        end
    end
end

function StaffMenu.BuildManageChestMenu()
    StaffMenu.ChestManage.Button(":target:​ TELEPORTATION A LA POSITION", nil, nil, "chevron", false, function()
        if not currentChest.coords then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Coffres',
                message = "Aucune position définie"
          })
        end

        SetEntityCoords(PlayerPedId(), currentChest.coords.x, currentChest.coords.y, currentChest.coords.z + 1.0, false, false, false, false)
    end)

    StaffMenu.ChestManage.Button(":monitor:​​ MODIFIER LE COFFRE", nil, nil, "chevron", false, function()
        chestData = currentChest
        chestData.isUpdate = true
        chestData.floatingZ = chestData.floatingZ or (chestData.coords and chestData.coords.floatingZ) or 0.5
        if not chestData.accessType then
            if not chestData.accessName or chestData.accessName == "" or chestData.accessName == "public" then
                chestData.accessType = "public"
          else
                local jobs = StaffMenu.data.jobsList or {}
                local factions = TriggerServerCallback("core:gestion-factions:getAll") or {}
                local isJob, isFaction = false, false
                for _, job in pairs(jobs) do
                    if job.name == chestData.accessName then isJob = true break end
                end
                if not isJob then
                    for _, faction in pairs(factions) do
                        if faction.name == chestData.accessName then isFaction = true break end
                    end
                end
                chestData.accessType = isJob and "job" or (isFaction and "faction" or "manual")
            end
        end
    end, StaffMenu.CreateChest)

    StaffMenu.ChestManage.Button(":report: SUPPRIMER LES LOGS", nil, nil, "chevron", false, function()
        TriggerServerEvent("chestBuilder:server:deleteLogs", currentChest.id)
        StaffMenu.ChestManage.close()
        StaffMenu.ChestList.open()
    end)

    StaffMenu.ChestManage.Button(":box: VIDER LE COFFRE", "Supprime tous les items stockés", nil, "chevron", false, function()
        TriggerServerEvent("chestBuilder:server:clear", currentChest.id)
        StaffMenu.ChestManage.close()
        StaffMenu.ChestList.open()
    end)

    StaffMenu.ChestManage.Button(":trash: SUPPRIMER LE COFFRE", nil, nil, "chevron", false, function()
        TriggerServerEvent("chestBuilder:server:delete", currentChest.id)
        currentChest = nil
        StaffMenu.ChestManage.close()
        StaffMenu.ChestList.open()
    end)
end
