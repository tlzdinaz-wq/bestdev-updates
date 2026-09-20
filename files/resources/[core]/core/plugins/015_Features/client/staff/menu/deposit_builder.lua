---@meta _
---@diagnostic disable: duplicate-doc-field

local depositData

local function resetDepositData()
    depositData = { id = nil, label = nil, coords = nil, consultJobs = {}, isUpdate = false }
end

resetDepositData()

local function closeDepositCreator(goToList)
    resetDepositData()
    StaffMenu.CreateDeposit.close()
    local target = goToList and StaffMenu.DepositList or StaffMenu.builderDeposit
    target.open()
end

local function getPlayerCoords()
    local coords <const> = GetEntityCoords(PlayerPedId())
    return { x = coords.x, y = coords.y, z = coords.z }
end

local function formatCoords(coords)
    if not coords then return "Non défini" end
    return ("%.1f, %.1f, %.1f"):format(coords.x, coords.y, coords.z)
end

local function isJobSelected(jobName)
    for i = 1, #depositData.consultJobs do
        if depositData.consultJobs[i] == jobName then return true end
    end
    return false
end

local function toggleJob(jobName)
    for i = 1, #depositData.consultJobs do
        if depositData.consultJobs[i] == jobName then
            table.remove(depositData.consultJobs, i)
            return
        end
    end
    depositData.consultJobs[#depositData.consultJobs + 1] = jobName
end

function StaffMenu.BuildDepositConsultJobsMenu()
    StaffMenu.DepositConsultJobs.ClearItems()

    local jobs <const> = TriggerServerCallback("depositBuilder:getPoliceJobs") or {}

    StaffMenu.DepositConsultJobs.Separator(("JOBS POLICE (%d sélectionné%s)"):format(#depositData.consultJobs, #depositData.consultJobs > 1 and "s" or ""))

    if not jobs or #jobs == 0 then
        StaffMenu.DepositConsultJobs.Button("AUCUN JOB POLICE", "Liste vide", nil, nil, true, function() end)
        return
    end

    for i = 1, #jobs do
        local job <const> = jobs[i]
        local selected <const> = isJobSelected(job.name)
        StaffMenu.DepositConsultJobs.Button(
            job.label or job.name,
            job.name,
            selected and ":check:" or "",
            selected and "check" or "chevron",
            false,
            function()
                toggleJob(job.name)
                StaffMenu.DepositConsultJobs.refresh()
            end
        )
    end
end

function StaffMenu.BuildCreateDepositMenu()
    StaffMenu.CreateDeposit.ClearItems()

    StaffMenu.CreateDeposit.Separator(depositData.isUpdate and "MODIFIER LE DÉPÔT" or "CRÉER UN DÉPÔT")

    StaffMenu.CreateDeposit.Button("NOM DU DÉPÔT", nil, depositData.label or "Non défini", "chevron", false, function()
        local name <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du dépôt")

        if not name or name == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Dépôts',
                message = "Ce nom n'est pas valide"
          })
        end

        depositData.label = name
        StaffMenu.CreateDeposit.refresh()
    end)

    StaffMenu.CreateDeposit.Separator("POSITION")

    StaffMenu.CreateDeposit.Button(":pin: POSITION", "Utilise ta position actuelle", formatCoords(depositData.coords), "chevron", false, function()
        depositData.coords = getPlayerCoords()
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Dépôts', message = "Position enregistrée" })
        StaffMenu.CreateDeposit.refresh()
    end)

    StaffMenu.CreateDeposit.Separator("CONSULTATION")

    StaffMenu.CreateDeposit.Button(
        "JOBS POLICE CONSULTABLES",
        "Jobs autorisés à consulter (lecture seule)",
        ("%d sélectionné%s"):format(#depositData.consultJobs, #depositData.consultJobs > 1 and "s" or ""),
        "chevron",
        false,
        function() end,
        StaffMenu.DepositConsultJobs
    )

    StaffMenu.CreateDeposit.Separator()

    StaffMenu.CreateDeposit.Button(depositData.isUpdate and ":check: MODIFIER LE DÉPÔT" or ":check: CRÉER LE DÉPÔT", nil, nil, "chevron", false, function()
        if not depositData.label or not depositData.coords then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Dépôts',
                message = "Ces données ne sont pas valides. Nom et position obligatoires."
          })
        end

        local isUpdate <const> = depositData.isUpdate
        local payload <const> = {
            id = depositData.id,
            label = depositData.label,
            coords = depositData.coords,
            consultJobs = depositData.consultJobs
        }

        local result <const> = TriggerServerCallback(
            isUpdate and "depositBuilder:server:update" or "depositBuilder:server:create",
            payload
        )

        if not result then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Dépôts',
                message = "Échec de l'enregistrement. Vérifie tes permissions."
          })
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Dépôts',
            message = isUpdate and ("Dépôt « " .. result.label .. " » modifié") or ("Dépôt « " .. result.label .. " » créé")
        })

        closeDepositCreator(true)
    end)

    StaffMenu.CreateDeposit.Button(":x: Annuler", nil, nil, "chevron", false, function()
        closeDepositCreator(false)
    end)
end

function StaffMenu.BuildDepositBuilderMenu()
    StaffMenu.builderDeposit.ClearItems()

    StaffMenu.builderDeposit.Button(":plus: CRÉER UN DÉPÔT", "Créer un nouveau point de dépôt", nil, "chevron", false, function()
        resetDepositData()
    end, StaffMenu.CreateDeposit)

    StaffMenu.builderDeposit.Button(":report: LISTE DES DÉPÔTS", "Gérer les dépôts existants", nil, "chevron", false, function()
    end, StaffMenu.DepositList)
end

local currentDeposit
local DEPOSITS_PER_PAGE = 25
StaffMenu.depositListPage = StaffMenu.depositListPage or 1
StaffMenu.depositListSearch = StaffMenu.depositListSearch or nil

local function getCachedDeposits()
    local list = {}
    local cache = DepositBuilder and DepositBuilder.cache or {}
    for i = 1, #cache do
        list[#list + 1] = cache[i]
    end
    return list
end

function StaffMenu.BuildDepositListMenu()
    StaffMenu.DepositList.ClearItems()

    local points = getCachedDeposits()

    local searchLabel = StaffMenu.depositListSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.depositListSearch == nil and "Nom du dépôt" or StaffMenu.depositListSearch
    StaffMenu.DepositList.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.depositListSearch ~= nil then
            StaffMenu.depositListSearch = nil
            StaffMenu.depositListPage = 1
            StaffMenu.DepositList.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du dépôt")
        if query == nil or query == "" then return end
        StaffMenu.depositListSearch = query
        StaffMenu.depositListPage = 1
        StaffMenu.DepositList.refresh()
    end)

    if not points or #points == 0 then
        StaffMenu.DepositList.Separator(nil)
        StaffMenu.DepositList.Button("AUCUN DÉPÔT", nil, nil, nil, false, function() end)
        return
    end

    table.sort(points, function(a, b)
        return (a.label or ""):lower() < (b.label or ""):lower()
    end)

    local filtered = points
    if StaffMenu.depositListSearch and StaffMenu.depositListSearch ~= "" then
        local q = StaffMenu.depositListSearch:lower()
        filtered = {}
        for _, p in ipairs(points) do
            if (p.label or ""):lower():find(q, 1, true) then
                filtered[#filtered + 1] = p
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / DEPOSITS_PER_PAGE), 1)
    if StaffMenu.depositListPage > totalPages then StaffMenu.depositListPage = totalPages end
    if StaffMenu.depositListPage < 1 then StaffMenu.depositListPage = 1 end
    local startIdx = (StaffMenu.depositListPage - 1) * DEPOSITS_PER_PAGE + 1
    local endIdx = math.min(startIdx + DEPOSITS_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.depositListSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d dépôts, page %d sur %d", totalItems, StaffMenu.depositListPage, totalPages)
    end
    StaffMenu.DepositList.Separator(header)

    if totalItems == 0 then
        StaffMenu.DepositList.Button("AUCUN RÉSULTAT", nil, nil, nil, false, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local point = filtered[idx]
        local jobsCount = point.consultJobs and #point.consultJobs or 0
        local sub = jobsCount > 0 and (jobsCount .. (jobsCount > 1 and " jobs consultables" or " job consultable")) or "Aucun consultable"

      StaffMenu.DepositList.Button(":box: " .. (point.label or "Sans nom"), sub, nil, "chevron", false, function()
            currentDeposit = point
        end, StaffMenu.DepositManage)
    end

    if totalPages > 1 then
        StaffMenu.DepositList.Separator(nil)
        if StaffMenu.depositListPage > 1 then
            StaffMenu.DepositList.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.depositListPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.depositListPage = StaffMenu.depositListPage - 1
                StaffMenu.DepositList.refresh()
            end)
        end
        if StaffMenu.depositListPage < totalPages then
            StaffMenu.DepositList.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.depositListPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.depositListPage = StaffMenu.depositListPage + 1
                StaffMenu.DepositList.refresh()
            end)
        end
    end
end

function StaffMenu.BuildManageDepositMenu()
    StaffMenu.DepositManage.ClearItems()

    if not currentDeposit then
        StaffMenu.DepositManage.Button("AUCUN DÉPÔT SÉLECTIONNÉ", nil, nil, nil, false, function() end)
        return
    end

    StaffMenu.DepositManage.Separator(currentDeposit.label or "Dépôt")

    StaffMenu.DepositManage.Button(":target: TÉLÉPORTER", formatCoords(currentDeposit.coords), nil, "chevron", false, function()
        if not currentDeposit.coords then
            return VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Dépôts', message = "Aucune position" })
        end
        SetEntityCoords(PlayerPedId(), currentDeposit.coords.x, currentDeposit.coords.y, currentDeposit.coords.z + 1.0, false, false, false, false)
    end)

    local jobsCount = currentDeposit.consultJobs and #currentDeposit.consultJobs or 0
    StaffMenu.DepositManage.Button(":police: JOBS CONSULTABLES", jobsCount .. (jobsCount > 1 and " jobs" or " job"), nil, nil, true, function() end)

    StaffMenu.DepositManage.Button(":monitor: MODIFIER LE DÉPÔT", nil, nil, "chevron", false, function()
        local jobsCopy = {}
        if currentDeposit.consultJobs then
            for i = 1, #currentDeposit.consultJobs do
                jobsCopy[i] = currentDeposit.consultJobs[i]
            end
        end
        depositData = {
            id = currentDeposit.id,
            label = currentDeposit.label,
            coords = currentDeposit.coords,
            consultJobs = jobsCopy,
            isUpdate = true
        }
    end, StaffMenu.CreateDeposit)

    StaffMenu.DepositManage.Button(":trash: SUPPRIMER LE DÉPÔT", nil, nil, "chevron", false, function()
        TriggerServerEvent("depositBuilder:server:delete", currentDeposit.id)
        currentDeposit = nil
        StaffMenu.DepositManage.close()
        StaffMenu.DepositList.open()
    end)
end
