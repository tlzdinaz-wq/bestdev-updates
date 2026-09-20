local VUI <const> = exports["VUI"]
local adminBanner <const> = exports["core"]:GetVUIBanner("admin")

local PLATE_MODES <const> = { "both", "random", "manual" }
local PLATE_MODE_LABELS <const> = { "Aléatoire + Manuelle", "Aléatoire uniquement", "Manuelle uniquement" }

local function defaultData()
    return {
        id = nil,
        name = "Garage Illégal",
        coords = {},
        plateMode = "both",
        isPaid = false,
        price = 0,
        allowedJobs = {},
        allowedFactions = {},
    }
end

local selected = defaultData()
local points = {}
local jobsCache = nil
local factionsCache = nil
local pickerState = {
    jobsSearch = nil, jobsPage = 1,
    factionsSearch = nil, factionsPage = 1,
}
local PICKER_PER_PAGE = 25

local function ensureJobsFactions()
    if jobsCache and factionsCache then return end
    local result = TriggerServerCallback("garageIllegal:getJobsAndFactions") or {}
    jobsCache = result.jobs or {}
    factionsCache = result.factions or {}
end

local function isInList(list, name)
    if not list then return false end
    for i = 1, #list do
        if list[i] == name then return true, i end
    end
    return false
end

local function toggleInList(list, name)
    local present, idx = isInList(list, name)
    if present then
        table.remove(list, idx)
    else
        list[#list + 1] = name
    end
end

StaffMenu.createGarageIllegalData = VUI:CreateSubMenu(StaffMenu.createGarageIllegal, "CRÉATION DE GARAGE ILLÉGAL", adminBanner, true)
StaffMenu.modifyGarageIllegalData = VUI:CreateSubMenu(StaffMenu.createGarageIllegal, "MODIFICATION DE GARAGE ILLÉGAL", adminBanner, true)
StaffMenu.garageIllegalJobsCreate = VUI:CreateSubMenu(StaffMenu.createGarageIllegalData, "ACCÈS JOBS", adminBanner, true)
StaffMenu.garageIllegalFactionsCreate = VUI:CreateSubMenu(StaffMenu.createGarageIllegalData, "ACCÈS FACTIONS", adminBanner, true)
StaffMenu.garageIllegalJobsModify = VUI:CreateSubMenu(StaffMenu.modifyGarageIllegalData, "ACCÈS JOBS", adminBanner, true)
StaffMenu.garageIllegalFactionsModify = VUI:CreateSubMenu(StaffMenu.modifyGarageIllegalData, "ACCÈS FACTIONS", adminBanner, true)

local function getPlateModeIndex(mode)
    for i = 1, #PLATE_MODES do
        if PLATE_MODES[i] == mode then return i end
    end
    return 1
end

local function posDisplay(coords)
    if coords and coords.x then
        return ("%.1f, %.1f, %.1f"):format(coords.x, coords.y, coords.z)
    end
    return "Non défini"
end

local ILLEGAL_GARAGES_PER_PAGE = 25
StaffMenu.illegalGaragePage = StaffMenu.illegalGaragePage or 1
StaffMenu.illegalGarageSearch = StaffMenu.illegalGarageSearch or nil

function StaffMenu.BuildCreateGarageIllegal()
    StaffMenu.createGarageIllegal.ClearItems()
    points = TriggerServerCallback("garageIllegal:listAll") or {}

    StaffMenu.createGarageIllegal.Button(":plus: Ajouter un garage illégal", "Créer un nouveau point", nil, "chevron", false, function()
        selected = defaultData()
    end, StaffMenu.createGarageIllegalData)

    local searchLabel = StaffMenu.illegalGarageSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.illegalGarageSearch == nil and "Nom du garage" or StaffMenu.illegalGarageSearch
    StaffMenu.createGarageIllegal.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.illegalGarageSearch ~= nil then
            StaffMenu.illegalGarageSearch = nil
            StaffMenu.illegalGaragePage = 1
            StaffMenu.createGarageIllegal.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du garage")
        if query == nil or query == "" then return end
        StaffMenu.illegalGarageSearch = query
        StaffMenu.illegalGaragePage = 1
        StaffMenu.createGarageIllegal.refresh()
    end)

    local filtered = points
    if StaffMenu.illegalGarageSearch and StaffMenu.illegalGarageSearch ~= "" then
        local q = StaffMenu.illegalGarageSearch:lower()
        filtered = {}
        for _, p in ipairs(points) do
            if (p.name or ""):lower():find(q, 1, true) then
                table.insert(filtered, p)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / ILLEGAL_GARAGES_PER_PAGE), 1)
    if StaffMenu.illegalGaragePage > totalPages then StaffMenu.illegalGaragePage = totalPages end
    if StaffMenu.illegalGaragePage < 1 then StaffMenu.illegalGaragePage = 1 end
    local startIdx = (StaffMenu.illegalGaragePage - 1) * ILLEGAL_GARAGES_PER_PAGE + 1
    local endIdx = math.min(startIdx + ILLEGAL_GARAGES_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.illegalGarageSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d garages illégaux, page %d sur %d", totalItems, StaffMenu.illegalGaragePage, totalPages)
    end
    StaffMenu.createGarageIllegal.Separator(header)

    if totalItems == 0 then
        StaffMenu.createGarageIllegal.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function()end)
        return
    end

    for idx = startIdx, endIdx do
        local p = filtered[idx]
        StaffMenu.createGarageIllegal.Button(
            ("%s | id : %s"):format(p.name or "Garage Illégal", p.id),
            ("%s • %s"):format(p.isPaid and (VFW.Math.FormatMoney(p.price)) or "Gratuit", PLATE_MODE_LABELS[getPlateModeIndex(p.plateMode)]),
            nil, "chevron", false, function()
                local copyJobs = {}
                if p.allowedJobs then for i = 1, #p.allowedJobs do copyJobs[i] = p.allowedJobs[i] end end
                local copyFactions = {}
                if p.allowedFactions then for i = 1, #p.allowedFactions do copyFactions[i] = p.allowedFactions[i] end end
                selected = {
                    id = p.id,
                    name = p.name,
                    coords = { x = p.coords.x, y = p.coords.y, z = p.coords.z, heading = p.coords.heading },
                    plateMode = p.plateMode,
                    isPaid = p.isPaid,
                    price = p.price,
                    allowedJobs = copyJobs,
                    allowedFactions = copyFactions,
                }
            end, StaffMenu.modifyGarageIllegalData)
    end

    if totalPages > 1 then
        StaffMenu.createGarageIllegal.Separator(nil)
        if StaffMenu.illegalGaragePage > 1 then
            StaffMenu.createGarageIllegal.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.illegalGaragePage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.illegalGaragePage = StaffMenu.illegalGaragePage - 1
                StaffMenu.createGarageIllegal.refresh()
            end)
        end
        if StaffMenu.illegalGaragePage < totalPages then
            StaffMenu.createGarageIllegal.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.illegalGaragePage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.illegalGaragePage = StaffMenu.illegalGaragePage + 1
                StaffMenu.createGarageIllegal.refresh()
            end)
        end
    end
end

local function buildFormButtons(menuRef, isEdit)
    menuRef.Button("Nom", "", selected.name or "Non défini", "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom du garage illégal", selected.name or "")
        if not name or name == "" then return end
        selected.name = name:sub(1, 100)
        menuRef.refresh()
    end)

    menuRef.Button("Position", "Utilise la position actuelle du joueur", posDisplay(selected.coords), "chevron", false, function()
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        selected.coords = { x = pos.x, y = pos.y, z = pos.z - 0.99, heading = GetEntityHeading(ped) }
        menuRef.refresh()
    end)

    menuRef.List("Mode de plaque", nil, false, PLATE_MODE_LABELS, getPlateModeIndex(selected.plateMode), function(Index)
        selected.plateMode = PLATE_MODES[Index] or "both"
  end)

    menuRef.Checkbox("Payant (argent sale)", "Si coché, un coût en argent sale sera appliqué.", false, selected.isPaid or false, function(checked)
        selected.isPaid = checked
        menuRef.refresh()
    end)

    if selected.isPaid then
        menuRef.Button("Prix (argent sale)", "Montant à débiter en argent sale", VFW.Math.FormatMoney(selected.price or 0), "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Prix en argent sale", tostring(selected.price or 0))
            local n = tonumber(input)
            if not n or n < 0 then return end
            selected.price = math.floor(n)
            menuRef.refresh()
        end)
    end

    menuRef.Separator("ACCÈS (vide = personne)")

    local jobCount = selected.allowedJobs and #selected.allowedJobs or 0
    local factionCount = selected.allowedFactions and #selected.allowedFactions or 0

    menuRef.Button(
        "Jobs autorisés",
        "Choisir les jobs qui peuvent utiliser ce garage",
        (jobCount > 0) and (jobCount .. (jobCount > 1 and " sélectionnés" or " sélectionné")) or "Aucun",
        "chevron", false, function()
            pickerState.jobsSearch = nil
            pickerState.jobsPage = 1
        end,
        isEdit and StaffMenu.garageIllegalJobsModify or StaffMenu.garageIllegalJobsCreate)

    menuRef.Button(
        "Factions autorisées",
        "Choisir les factions qui peuvent utiliser ce garage",
        (factionCount > 0) and (factionCount .. (factionCount > 1 and " sélectionnées" or " sélectionnée")) or "Aucune",
        "chevron", false, function()
            pickerState.factionsSearch = nil
            pickerState.factionsPage = 1
        end,
        isEdit and StaffMenu.garageIllegalFactionsModify or StaffMenu.garageIllegalFactionsCreate)

    menuRef.Separator()

    if isEdit then
        menuRef.Button("Se téléporter", "", nil, "chevron", false, function()
            if not selected.coords or not selected.coords.x then return end
            local ped = PlayerPedId()
            SetEntityCoords(ped, selected.coords.x, selected.coords.y, selected.coords.z + 0.99, false, false, false, false)
            if selected.coords.heading then SetEntityHeading(ped, selected.coords.heading) end
        end)

        menuRef.Button(":save: Enregistrer les modifications", "", nil, "chevron", false, function()
            if not selected.coords or not selected.coords.x then
                return VFW.ShowNotification({ type = 'ROUGE', content = "Veuillez définir la position." })
            end
            if selected.isPaid and (not selected.price or selected.price <= 0) then
                return VFW.ShowNotification({ type = 'ROUGE', content = "Ce prix n'est pas valide." })
            end
            TriggerServerEvent("garageIllegal:server:update", selected)
            menuRef.close()
            Wait(300)
            StaffMenu.createGarageIllegal.open()
        end)

        menuRef.Button(":trash: Supprimer le garage", "", nil, "trash", false, function()
            TriggerServerEvent("garageIllegal:server:delete", selected.id)
            menuRef.close()
            Wait(300)
            StaffMenu.createGarageIllegal.open()
        end)
    else
        menuRef.Button(":check: Créer le garage", "", nil, "chevron", false, function()
            if not selected.coords or not selected.coords.x then
                return VFW.ShowNotification({ type = 'ROUGE', content = "Veuillez définir la position." })
            end
            if selected.isPaid and (not selected.price or selected.price <= 0) then
                return VFW.ShowNotification({ type = 'ROUGE', content = "Ce prix n'est pas valide." })
            end
            TriggerServerEvent("garageIllegal:server:create", selected)
            selected = defaultData()
            menuRef.close()
            Wait(300)
            StaffMenu.createGarageIllegal.open()
        end)
    end
end

StaffMenu.createGarageIllegalData.OnOpen(function()
    StaffMenu.createGarageIllegalData.ClearItems()
    buildFormButtons(StaffMenu.createGarageIllegalData, false)
end)

StaffMenu.modifyGarageIllegalData.OnOpen(function()
    StaffMenu.modifyGarageIllegalData.ClearItems()
    buildFormButtons(StaffMenu.modifyGarageIllegalData, true)
end)

local function buildPicker(menuRef, kind)
    menuRef.ClearItems()
    ensureJobsFactions()

    local source, listSel, searchKey, pageKey, emptyLabel
    if kind == "jobs" then
        source = jobsCache or {}
        listSel = selected.allowedJobs
        searchKey, pageKey = "jobsSearch", "jobsPage"
      emptyLabel = "Aucun job"
  else
        source = factionsCache or {}
        listSel = selected.allowedFactions
        searchKey, pageKey = "factionsSearch", "factionsPage"
      emptyLabel = "Aucune faction"
  end

    local searchLabel = (pickerState[searchKey] == nil) and "RECHERCHER" or "RECHERCHER:"
  local searchValue = pickerState[searchKey] or "Nom"
  menuRef.Button(searchLabel, searchValue, nil, "search", false, function()
        if pickerState[searchKey] ~= nil then
            pickerState[searchKey] = nil
            pickerState[pageKey] = 1
            menuRef.refresh()
            return
        end
        local q = VFW.Nui.KeyboardInput(true, "Recherche")
        if q == nil or q == "" then return end
        pickerState[searchKey] = q
        pickerState[pageKey] = 1
        menuRef.refresh()
    end)

    if #listSel > 0 then
        menuRef.Button(":x: Tout désélectionner", nil, tostring(#listSel), "trash", false, function()
            for k in pairs(listSel) do listSel[k] = nil end
            menuRef.refresh()
        end)
    end

    local filtered = source
    if pickerState[searchKey] and pickerState[searchKey] ~= "" then
        local q = pickerState[searchKey]:lower()
        filtered = {}
        for i = 1, #source do
            local item = source[i]
            if (item.label or item.name or ""):lower():find(q, 1, true)
                or (item.name or ""):lower():find(q, 1, true) then
                filtered[#filtered + 1] = item
            end
        end
    end

    local total = #filtered
    local totalPages = math.max(math.ceil(total / PICKER_PER_PAGE), 1)
    if pickerState[pageKey] > totalPages then pickerState[pageKey] = totalPages end
    if pickerState[pageKey] < 1 then pickerState[pageKey] = 1 end
    local startIdx = (pickerState[pageKey] - 1) * PICKER_PER_PAGE + 1
    local endIdx = math.min(startIdx + PICKER_PER_PAGE - 1, total)

    menuRef.Separator(("Sélectionnés: %d • Résultats: %d • Page %d/%d"):format(#listSel, total, pickerState[pageKey], totalPages))

    if total == 0 then
        menuRef.Button(emptyLabel, nil, nil, nil, false, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local item = filtered[idx]
        local selectedNow = isInList(listSel, item.name)
        menuRef.Checkbox(
            item.label or item.name,
            item.name,
            false,
            selectedNow,
            function()
                toggleInList(listSel, item.name)
            end
        )
    end

    if totalPages > 1 then
        menuRef.Separator(nil)
        if pickerState[pageKey] > 1 then
            menuRef.Button(":back: PAGE PRÉCÉDENTE", nil, nil, "arrow", false, function()
                pickerState[pageKey] = pickerState[pageKey] - 1
                menuRef.refresh()
            end)
        end
        if pickerState[pageKey] < totalPages then
            menuRef.Button("PAGE SUIVANTE :arrow:", nil, nil, "arrow", false, function()
                pickerState[pageKey] = pickerState[pageKey] + 1
                menuRef.refresh()
            end)
        end
    end
end

StaffMenu.garageIllegalJobsCreate.OnOpen(function() buildPicker(StaffMenu.garageIllegalJobsCreate, "jobs") end)
StaffMenu.garageIllegalFactionsCreate.OnOpen(function() buildPicker(StaffMenu.garageIllegalFactionsCreate, "factions") end)
StaffMenu.garageIllegalJobsModify.OnOpen(function() buildPicker(StaffMenu.garageIllegalJobsModify, "jobs") end)
StaffMenu.garageIllegalFactionsModify.OnOpen(function() buildPicker(StaffMenu.garageIllegalFactionsModify, "factions") end)
