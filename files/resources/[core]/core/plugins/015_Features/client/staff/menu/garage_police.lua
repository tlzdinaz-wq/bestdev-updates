local VUI = exports["VUI"]
local adminBanner = exports["core"]:GetVUIBanner("admin")

-- Jobs chargés dynamiquement depuis le serveur { name, label }
local policeJobList    = {}
local policeJobLabels  = {}

local function loadPoliceJobs()
    local jobs = TriggerServerCallback("policeGarage:getPoliceJobs")
    policeJobList   = jobs or {}
    policeJobLabels = {}
    for _, j in ipairs(policeJobList) do
        policeJobLabels[#policeJobLabels + 1] = j.label
    end
end

-- Submenus — un seul formulaire pour création ET édition
StaffMenu.builderPoliceGarageForm     = VUI:CreateSubMenu(StaffMenu.builderPoliceGarage, "GARAGE MÉTIER", adminBanner, true)
StaffMenu.builderPoliceGarageVehicles = VUI:CreateSubMenu(StaffMenu.builderPoliceGarageForm, "VÉHICULES DU GARAGE", adminBanner, true)
StaffMenu.builderPoliceGarageAddVeh   = VUI:CreateSubMenu(StaffMenu.builderPoliceGarageVehicles, "AJOUTER UN VÉHICULE", adminBanner, true)
StaffMenu.builderPoliceGarageGrades  = VUI:CreateSubMenu(StaffMenu.builderPoliceGarageAddVeh, "GRADES AUTORISÉS", adminBanner, true)

-- State
local policeGarageSelected = nil
local currentPGVehicle     = {}

local function getDefaultPGData()
    return {
        name            = nil,
        job             = policeJobList[1] and policeJobList[1].name or "",
        jobIndex        = 1,
        position        = {},
        spawnPositions  = {},
        despawnPosition = {},
        vehicles        = {},
        pedModel        = "a_m_m_prolhost_01"
  }
end

-- ============================================================
-- Menu principal : liste + bouton créer
-- ============================================================

local POLICE_GARAGES_PER_PAGE = 25
StaffMenu.policeGaragePage = StaffMenu.policeGaragePage or 1
StaffMenu.policeGarageSearch = StaffMenu.policeGarageSearch or nil

function StaffMenu.BuildPoliceGarageMenu()
    loadPoliceJobs()
    local garages = TriggerServerCallback("policeGarage:getAll") or {}

    StaffMenu.builderPoliceGarage.Button(":plus: Créer un garage", "Configurer un nouveau garage métier", nil, "chevron", false, function()
        policeGarageSelected = getDefaultPGData()
    end, StaffMenu.builderPoliceGarageForm)

    local searchLabel = StaffMenu.policeGarageSearch == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = StaffMenu.policeGarageSearch == nil and "Nom du garage / métier" or StaffMenu.policeGarageSearch
    StaffMenu.builderPoliceGarage.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.policeGarageSearch ~= nil then
            StaffMenu.policeGarageSearch = nil
            StaffMenu.policeGaragePage = 1
            StaffMenu.builderPoliceGarage.refresh()
            return
        end
        local query = VFW.Nui.KeyboardInput(true, "Recherche : nom du garage / métier")
        if query == nil or query == "" then return end
        StaffMenu.policeGarageSearch = query
        StaffMenu.policeGaragePage = 1
        StaffMenu.builderPoliceGarage.refresh()
    end)

    local flat = {}
    for id, data in pairs(garages) do
        local jobLabel = data.job or "?"
      for _, j in ipairs(policeJobList) do
            if j.name == data.job then jobLabel = j.label break end
        end
        table.insert(flat, { id = id, data = data, jobLabel = jobLabel })
    end
    table.sort(flat, function(a, b) return (a.data.name or ""):lower() < (b.data.name or ""):lower() end)

    local filtered = flat
    if StaffMenu.policeGarageSearch and StaffMenu.policeGarageSearch ~= "" then
        local q = StaffMenu.policeGarageSearch:lower()
        filtered = {}
        for _, e in ipairs(flat) do
            if (e.data.name or ""):lower():find(q, 1, true)
                or (e.jobLabel or ""):lower():find(q, 1, true)
                or (e.data.job or ""):lower():find(q, 1, true) then
                table.insert(filtered, e)
            end
        end
    end

    local totalItems = #filtered
    local totalPages = math.max(math.ceil(totalItems / POLICE_GARAGES_PER_PAGE), 1)
    if StaffMenu.policeGaragePage > totalPages then StaffMenu.policeGaragePage = totalPages end
    if StaffMenu.policeGaragePage < 1 then StaffMenu.policeGaragePage = 1 end
    local startIdx = (StaffMenu.policeGaragePage - 1) * POLICE_GARAGES_PER_PAGE + 1
    local endIdx = math.min(startIdx + POLICE_GARAGES_PER_PAGE - 1, totalItems)

    local header
    if StaffMenu.policeGarageSearch then
        header = string.format("Résultats : %d", totalItems)
    else
        header = string.format("%d garages existants, page %d sur %d", totalItems, StaffMenu.policeGaragePage, totalPages)
    end
    StaffMenu.builderPoliceGarage.Separator(header)

    if totalItems == 0 then
        StaffMenu.builderPoliceGarage.Button(":x: AUCUN RÉSULTAT", "", nil, nil, true, function() end)
        return
    end

    for idx = startIdx, endIdx do
        local e = filtered[idx]
        local data = e.data
        StaffMenu.builderPoliceGarage.Button(
            ("%s  [%s]"):format(data.name or "?", e.jobLabel),
            (#(data.vehicles or {}) > 1 and "ID: %s | %d véhicules" or "ID: %s | %d véhicule"):format(tostring(e.id), #(data.vehicles or {})),
            nil, "chevron", false,
            function()
                policeGarageSelected = {}
                for k, v in pairs(data) do policeGarageSelected[k] = v end
                policeGarageSelected.vehicles = {}
                for i, v in ipairs(data.vehicles or {}) do policeGarageSelected.vehicles[i] = v end
                policeGarageSelected.jobIndex = 1
                for i, j in ipairs(policeJobList) do
                    if j.name == data.job then policeGarageSelected.jobIndex = i break end
                end
            end,
            StaffMenu.builderPoliceGarageForm
        )
    end

    if totalPages > 1 then
        StaffMenu.builderPoliceGarage.Separator(nil)
        if StaffMenu.policeGaragePage > 1 then
            StaffMenu.builderPoliceGarage.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (StaffMenu.policeGaragePage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.policeGaragePage = StaffMenu.policeGaragePage - 1
                StaffMenu.builderPoliceGarage.refresh()
            end)
        end
        if StaffMenu.policeGaragePage < totalPages then
            StaffMenu.builderPoliceGarage.Button("PAGE SUIVANTE :arrow:", "Page " .. (StaffMenu.policeGaragePage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                StaffMenu.policeGaragePage = StaffMenu.policeGaragePage + 1
                StaffMenu.builderPoliceGarage.refresh()
            end)
        end
    end
end

-- ============================================================
-- Formulaire unifié (création + édition)
-- ============================================================

StaffMenu.builderPoliceGarageForm.OnOpen(function()
    if not policeGarageSelected then
        policeGarageSelected = getDefaultPGData()
    end

    local isEditing = policeGarageSelected.id ~= nil

    StaffMenu.builderPoliceGarageForm.title = isEditing and "MODIFIER LE GARAGE" or "CRÉER UN GARAGE MÉTIER"

  if isEditing and policeGarageSelected.position and policeGarageSelected.position.x then
        StaffMenu.builderPoliceGarageForm.Button(
            "Se téléporter au garage", "", nil, "chevron", false, function()
                local ped = PlayerPedId()
                SetEntityCoords(ped, policeGarageSelected.position.x, policeGarageSelected.position.y, policeGarageSelected.position.z + 0.99, false, false, false, false)
                if policeGarageSelected.position.w then
                    SetEntityHeading(ped, policeGarageSelected.position.w)
                end
            end
        )
        StaffMenu.builderPoliceGarageForm.Separator("Configuration")
    end

    StaffMenu.builderPoliceGarageForm.Button(
        ":edit: Nom du garage", "",
        policeGarageSelected.name or "Non défini",
        "chevron", false, function()
            local name = VFW.Nui.KeyboardInput(true, "Entrez le nom du garage", policeGarageSelected.name or "")
            if not name or name == "" then return end
            policeGarageSelected.name = name
            StaffMenu.builderPoliceGarageForm.refresh()
        end
    )

    StaffMenu.builderPoliceGarageForm.List(
        ":police: Job", "Job propriétaire du garage",
        false, policeJobLabels,
        policeGarageSelected.jobIndex or 1,
        function(index)
            policeGarageSelected.jobIndex = index
            policeGarageSelected.job      = policeJobList[index] and policeJobList[index].name or ""
      end
    )

    local posX = policeGarageSelected.position and policeGarageSelected.position.x
    StaffMenu.builderPoliceGarageForm.Button(
        ":pin: Position du garage", "Se placer à l'endroit voulu puis cliquer",
        posX and "Définie" or "Non définie",
        "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            policeGarageSelected.position = { x = pos.x, y = pos.y, z = pos.z - 0.99, w = GetEntityHeading(ped) }
            StaffMenu.builderPoliceGarageForm.refresh()
        end
    )

    local hasSpawn = policeGarageSelected.spawnPositions and policeGarageSelected.spawnPositions[1]
    StaffMenu.builderPoliceGarageForm.Button(
        " Points de spawn", "Placer les emplacements véhicules",
        hasSpawn and "Définis" or "Non définis",
        "chevron", false, function()
            StaffMenu.builderPoliceGarageForm.close()
            local exits = Garage:SetExitPoint(1)
            StaffMenu.builderPoliceGarageForm.open()
            policeGarageSelected.spawnPositions = exits
            StaffMenu.builderPoliceGarageForm.refresh()
        end
    )

    local despawnX = policeGarageSelected.despawnPosition and policeGarageSelected.despawnPosition.x
    StaffMenu.builderPoliceGarageForm.Button(
        ":box: Zone de rangement (despawn)", "Se placer à la zone de retour",
        despawnX and "Définie" or "Non définie",
        "chevron", false, function()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            policeGarageSelected.despawnPosition = { x = pos.x, y = pos.y, z = pos.z - 0.99 }
            StaffMenu.builderPoliceGarageForm.refresh()
        end
    )

    StaffMenu.builderPoliceGarageForm.Button(
        ":user: Modèle du PED", "Nom du ped NPC de garde",
        policeGarageSelected.pedModel or "a_m_m_prolhost_01",
        "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle PED", policeGarageSelected.pedModel or "a_m_m_prolhost_01")
            if not model or model == "" then return end
            policeGarageSelected.pedModel = model
            StaffMenu.builderPoliceGarageForm.refresh()
        end
    )

    StaffMenu.builderPoliceGarageForm.Button(
        ":car: Gérer les véhicules",
        (#(policeGarageSelected.vehicles or {}) > 1 and "(%d) véhicules configurés" or "(%d) véhicule configuré"):format(#(policeGarageSelected.vehicles or {})),
        nil, "chevron", false, function() end,
        StaffMenu.builderPoliceGarageVehicles
    )

    StaffMenu.builderPoliceGarageForm.Separator()

    if isEditing then
        StaffMenu.builderPoliceGarageForm.Button(":save: Sauvegarder les modifications", "", nil, "chevron", false, function()
            if not policeGarageSelected.name or policeGarageSelected.name == "" then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir le nom." })
                return
            end
            if not policeGarageSelected.position or not policeGarageSelected.position.x then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir la position." })
                return
            end
            if not policeGarageSelected.spawnPositions or not policeGarageSelected.spawnPositions[1] then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir le spawn." })
                return
            end

            TriggerServerEvent("policeGarage:update", policeGarageSelected.id, policeGarageSelected)
            policeGarageSelected = nil
            StaffMenu.builderPoliceGarageForm.close()
        end)

        StaffMenu.builderPoliceGarageForm.Button(":trash: Supprimer le garage", "", nil, "trash", false, function()
            TriggerServerEvent("policeGarage:delete", policeGarageSelected.id)
            policeGarageSelected = nil
            StaffMenu.builderPoliceGarageForm.close()
        end)
    else
        StaffMenu.builderPoliceGarageForm.Button(":check: Créer le garage", "", nil, "chevron", false, function()
            if not policeGarageSelected.name or policeGarageSelected.name == "" then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir le nom du garage." })
                return
            end
            if not policeGarageSelected.position or not policeGarageSelected.position.x then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir la position." })
                return
            end
            if not policeGarageSelected.spawnPositions or not policeGarageSelected.spawnPositions[1] then
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir au moins un point de spawn." })
                return
            end

            TriggerServerEvent("policeGarage:create", policeGarageSelected)
            policeGarageSelected = getDefaultPGData()
            StaffMenu.builderPoliceGarageForm.close()
        end)
    end
end)

-- ============================================================
-- Liste des véhicules
-- ============================================================

StaffMenu.builderPoliceGarageVehicles.OnOpen(function()
    if not policeGarageSelected then return end

    StaffMenu.builderPoliceGarageVehicles.Button(":plus: Ajouter un véhicule", "", nil, "chevron", false, function()
        currentPGVehicle = {}
    end, StaffMenu.builderPoliceGarageAddVeh)

    if #(policeGarageSelected.vehicles or {}) > 0 then
        StaffMenu.builderPoliceGarageVehicles.Separator("Véhicules configurés")
    end

    for i, veh in ipairs(policeGarageSelected.vehicles or {}) do
        StaffMenu.builderPoliceGarageVehicles.Button(
            veh.label or veh.model,
            ("Modèle: %s  |  Grades: %s"):format(veh.model, (function()
                if not veh.allowedGrades or not next(veh.allowedGrades) then
                    if veh.minGrade and veh.minGrade > 0 then return "min " .. veh.minGrade end
                    return "Tous"
              end
                local count = 0
                for _ in pairs(veh.allowedGrades) do count = count + 1 end
                return count .. (count > 1 and " autorisés" or " autorisé")
          end)()),
            nil, "trash", false, function()
                table.remove(policeGarageSelected.vehicles, i)
                StaffMenu.builderPoliceGarageVehicles.refresh()
            end
        )
    end
end)

-- ============================================================
-- Formulaire ajout véhicule
-- ============================================================

StaffMenu.builderPoliceGarageAddVeh.OnOpen(function()
    StaffMenu.builderPoliceGarageAddVeh.Button(
        ":car: Modèle", "Nom spawn du véhicule (ex: police3)",
        currentPGVehicle.model or "Non défini",
        "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, "Modèle du véhicule", currentPGVehicle.model or "")
            if not model or model == "" then return end
            currentPGVehicle.model = model
            StaffMenu.builderPoliceGarageAddVeh.refresh()
        end
    )

    StaffMenu.builderPoliceGarageAddVeh.Button(
        ":tag: Label", "Nom affiché dans le menu",
        currentPGVehicle.label or "Non défini",
        "chevron", false, function()
            local label = VFW.Nui.KeyboardInput(true, "Label affiché", currentPGVehicle.label or "")
            if not label or label == "" then return end
            currentPGVehicle.label = label
            StaffMenu.builderPoliceGarageAddVeh.refresh()
        end
    )

    local allowedCount = 0
    if currentPGVehicle.allowedGrades then
        for _ in pairs(currentPGVehicle.allowedGrades) do allowedCount = allowedCount + 1 end
    end
    local gradesDesc = allowedCount > 0 and (allowedCount .. (allowedCount > 1 and " grades sélectionnés" or " grade sélectionné")) or "Aucun (tous autorisés)"

  StaffMenu.builderPoliceGarageAddVeh.Button(
        ":star: Grades autorisés", gradesDesc,
        nil, "chevron", false, function()
        end, StaffMenu.builderPoliceGarageGrades
    )

    StaffMenu.builderPoliceGarageAddVeh.Separator()

    StaffMenu.builderPoliceGarageAddVeh.Button(":check: Ajouter le véhicule", "", nil, "chevron", false, function()
        if not currentPGVehicle.model or currentPGVehicle.model == "" then
            VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir un modèle." })
            return
        end
        if not currentPGVehicle.label or currentPGVehicle.label == "" then
            VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Garage Métier", message = "Veuillez définir un label." })
            return
        end

        if not policeGarageSelected.vehicles then
            policeGarageSelected.vehicles = {}
        end

        policeGarageSelected.vehicles[#policeGarageSelected.vehicles + 1] = {
            model         = currentPGVehicle.model,
            label         = currentPGVehicle.label,
            allowedGrades = currentPGVehicle.allowedGrades or {},
            category      = "defaut"
      }

        currentPGVehicle = {}
        StaffMenu.builderPoliceGarageVehicles.open()
    end)
end)

-- ============================================================
-- Sous-menu grades autorisés
-- ============================================================
StaffMenu.builderPoliceGarageGrades.OnOpen(function()
    StaffMenu.builderPoliceGarageGrades.ClearItems()

    if not currentPGVehicle.allowedGrades then
        currentPGVehicle.allowedGrades = {}
    end

    local jobName = policeGarageSelected and policeGarageSelected.job or ""
  local grades = TriggerServerCallback("legalBuilder:getJobGrades", jobName)

    if not grades or #grades == 0 then
        StaffMenu.builderPoliceGarageGrades.Button("Aucun grade trouvé", "Job: " .. jobName, nil, nil, true, function() end)
        return
    end

    -- Checkbox "Tous les grades" en haut
    local allChecked = true
    for _, g in ipairs(grades) do
        if currentPGVehicle.allowedGrades[tostring(tonumber(g.grade) or 0)] ~= true then
            allChecked = false
            break
        end
    end

    StaffMenu.builderPoliceGarageGrades.Checkbox(
        ":check: Tous les grades", "Cocher / décocher tous les grades", false, allChecked,
        function(checked)
            for _, g in ipairs(grades) do
                local gNum = tostring(tonumber(g.grade) or 0)
                currentPGVehicle.allowedGrades[gNum] = checked or nil
            end
            StaffMenu.builderPoliceGarageGrades.refresh()
        end
    )

    StaffMenu.builderPoliceGarageGrades.Separator("GRADES - " .. string.upper(jobName))

    for _, g in ipairs(grades) do
        local gradeNum = tonumber(g.grade) or 0
        local gradeLabel = g.label or ("Grade " .. gradeNum)
        local isAllowed = currentPGVehicle.allowedGrades[tostring(gradeNum)] == true

        StaffMenu.builderPoliceGarageGrades.Checkbox(
            gradeLabel, "Grade " .. gradeNum, false, isAllowed,
            function(checked)
                currentPGVehicle.allowedGrades[tostring(gradeNum)] = checked or nil
                StaffMenu.builderPoliceGarageGrades.refresh()
            end
        )
    end
end)
