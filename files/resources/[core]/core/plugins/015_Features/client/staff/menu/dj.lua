---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- PLATINE DJ CREATION
-- ============================================

local platineData = {
    name = "",
    position = nil,
    radius = 50.0,
    scope = "public",
    job = nil,
    floatingZ = 0.5
}

-- Platine sélectionnée pour la gestion
local selectedPlatine = {
    id = nil,
    data = nil
}

--- Réinitialise les données de la platine
local function ResetPlatineData()
    platineData = {
        name = "",
        position = nil,
        radius = 50.0,
        scope = "public",
        job = nil
    }
end

--- Retourne le label du job à partir de son nom technique
local function GetJobLabel(jobName)
    if not jobName then return nil end
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs
    for _, job in pairs(jobs) do
        if job.name == jobName then
            return job.label
        end
    end
    return jobName
end

--- Menu de création de platine DJ
function StaffMenu.BuildCreatePlatineMenu()
    StaffMenu.CreatePlatine.Separator(":music: CRÉATION DE PLATINE DJ")

    -- Nom de la platine
    StaffMenu.CreatePlatine.Button(":edit: NOM", platineData.name ~= "" and platineData.name or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Entrer le nom de la platine", platineData.name)
        if input and input ~= "" then
            platineData.name = input
            StaffMenu.CreatePlatine.refresh()
        end
    end)

    -- Position (via le perso)
    StaffMenu.CreatePlatine.Button(":pin: POSITION", platineData.position and "Définie" or "Non définie", nil, "chevron", false, function()
        platineData.position = GetEntityCoords(PlayerPedId())
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Mode DJ',
            message = "Position enregistrée."
      })
        StaffMenu.CreatePlatine.refresh()
    end)

    StaffMenu.CreatePlatine.Separator("PARAMÈTRES AUDIO")

    -- Portée audio (radius)
    StaffMenu.CreatePlatine.Button(":signal: PORTÉE AUDIO", platineData.radius .. " mètres", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Entrer la portée audio en mètres (10-500)", tostring(platineData.radius))
        if input and tonumber(input) then
            local radius = tonumber(input)
            if radius >= 10 and radius <= 500 then
                platineData.radius = radius
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Mode DJ',
                    message = "Portée audio définie à " .. radius .. " mètres."
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'INFO',
                    subtitle = 'Mode DJ',
                    message = "La portée doit être entre 10 et 500 mètres."
              })
            end
            StaffMenu.CreatePlatine.refresh()
        end
    end)

    StaffMenu.CreatePlatine.Separator("RESTRICTIONS D'ACCÈS")

    -- Affichage du scope actuel
    local scopeLabel = platineData.scope == "public" and "Public" or "Job"
  local scopeDetail = platineData.scope == "job" and platineData.job and GetJobLabel(platineData.job) or nil
    local scopeRightLabel = scopeDetail and (scopeLabel .. " - " .. scopeDetail) or scopeLabel

    StaffMenu.CreatePlatine.Button(":lock: ACCÈS", scopeRightLabel, nil, "chevron", false, function()
    end, StaffMenu.PlatineSelectScope)

    StaffMenu.CreatePlatine.Button(":target: Position du floating", nil, ("Hauteur: %.2f"):format(platineData.floatingZ or 0.5), "chevron", false, function()
        if not platineData.position then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Mode DJ', message = "Définissez d'abord la position." })
            return
        end
        StaffMenu.CreatePlatine.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(platineData.position, platineData.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({ { label = "Monter", control = 172 }, { label = "Descendre", control = 173 }, { label = "Valider", control = 201 } })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                platineData.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.CreatePlatine.open()
    end)

    StaffMenu.CreatePlatine.Separator(nil)

    -- Valider la création
    local canCreate = platineData.name ~= "" and platineData.position
    StaffMenu.CreatePlatine.Button(":check: CRÉER LA PLATINE", "Valider et sauvegarder", nil, "check", not canCreate, function()
        if platineData.name == "" then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Mode DJ',
                message = "Veuillez définir un nom pour la platine."
          })
            return
        end

        if not platineData.position then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Mode DJ',
                message = "Veuillez définir une position."
          })
            return
        end

        -- Vérification si scope job mais pas de job sélectionné
        if platineData.scope == "job" and not platineData.job then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Mode DJ',
                message = "Veuillez sélectionner un job pour l'accès restreint."
          })
            return
        end

        -- Envoyer au serveur
        TriggerServerEvent("vfw:staff:create:platine", {
            name = platineData.name,
            position = platineData.position,
            radius = platineData.radius,
            scope = platineData.scope,
            job = platineData.job,
            floatingZ = platineData.floatingZ
        })

        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Mode DJ',
            message = "Platine '" .. platineData.name .. "' créée."
      })

        ResetPlatineData()
        StaffMenu.CreatePlatine.refresh()
    end)

    -- Annuler
    StaffMenu.CreatePlatine.Button(":x: ANNULER", nil, nil, "chevron", false, function()
        ResetPlatineData()
        StaffMenu.CreatePlatine.close()
    end)
end

--- Menu de gestion des platines existantes (liste des platines)
function StaffMenu.BuildDeletePlatineMenu()
    local allPlatines = TriggerServerCallback("vfw:staff:getAllPlatines")

    if not allPlatines or next(allPlatines) == nil then
        StaffMenu.DeletePlatine.Button("", "Aucune platine trouvée", nil, nil, true, function() end)
        return
    end

    StaffMenu.DeletePlatine.Separator(":music: PLATINES EXISTANTES")

    -- Trier les platines par nom
    local sortedPlatines = {}
    for platineId, platineInfo in pairs(allPlatines) do
        table.insert(sortedPlatines, { id = platineId, info = platineInfo })
    end
    table.sort(sortedPlatines, function(a, b)
        return (a.info.name or a.id) < (b.info.name or b.id)
    end)

    for _, platine in ipairs(sortedPlatines) do
        local platineId = platine.id
        local platineInfo = platine.info
        local platineName = platineInfo.name or platineId
        local currentScope = platineInfo.scope or "public"
      local scopeIcon = currentScope == "public" and ":globe:" or ":briefcase:"

      StaffMenu.DeletePlatine.Button(":music: " .. platineName, scopeIcon .. " " .. (currentScope == "public" and "Public" or "Job"), nil, "chevron", false, function()
            selectedPlatine.id = platineId
            selectedPlatine.data = platineInfo
        end, StaffMenu.PlatineManage)
    end
end

--- Sous-menu de gestion d'une platine individuelle
function StaffMenu.BuildPlatineManageMenu()
    if not selectedPlatine.id or not selectedPlatine.data then
        StaffMenu.PlatineManage.Button("", "Aucune platine sélectionnée", nil, nil, true, function() end)
        return
    end

    local platineId = selectedPlatine.id
    local platineInfo = selectedPlatine.data
    local platineName = platineInfo.name or platineId
    local platineRadius = platineInfo.radius or 50
    local platinePos = platineInfo.position

    StaffMenu.PlatineManage.Separator(":music: " .. platineName)

    -- Téléportation à la platine
    StaffMenu.PlatineManage.Button(":pin: SE TÉLÉPORTER", nil, nil, "chevron", false, function()
        if platinePos then
            local pos = platinePos
            if type(pos) == "table" then
                SetEntityCoords(PlayerPedId(), pos.x or pos[1], pos.y or pos[2], pos.z or pos[3], false, false, false, false)
            else
                SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, false)
            end
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Mode DJ',
                message = "Téléporté à la platine '" .. platineName .. "'."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Mode DJ',
                message = "Position de la platine introuvable."
          })
        end
    end)

    StaffMenu.PlatineManage.Separator("PARAMÈTRES")

    -- Modifier le nom
    StaffMenu.PlatineManage.Button(":edit: MODIFIER LE NOM", platineName, nil, "chevron", false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nouveau nom de la platine", platineName)
        if newName and newName ~= "" and newName ~= platineName then
            TriggerServerEvent("vfw:staff:update:platine", platineId, { name = newName })
            selectedPlatine.data.name = newName
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Mode DJ',
                message = "Nom modifié en '" .. newName .. "'."
          })
            Wait(150)
            StaffMenu.PlatineManage.refresh()
            StaffMenu.DeletePlatine.refresh()
        end
    end)

    -- Modifier le radius
    StaffMenu.PlatineManage.Button(":signal: MODIFIER LA PORTÉE", platineRadius .. "m", nil, "chevron", false, function()
        local newRadius = VFW.Nui.KeyboardInput(true, "Nouvelle portée audio en mètres (10-500)", tostring(platineRadius))
        if newRadius and tonumber(newRadius) then
            local radius = tonumber(newRadius)
            if radius >= 10 and radius <= 500 then
                TriggerServerEvent("vfw:staff:update:platine", platineId, { radius = radius })
                selectedPlatine.data.radius = radius
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
                    message = "Portée modifiée à " .. radius .. " mètres"
              })
                Wait(150)
                StaffMenu.PlatineManage.refresh()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'INFO', subtitle = 'Mode DJ',
                    message = "La portée doit être entre 10 et 500 mètres"
              })
            end
        end
    end)

    -- Modifier la position
    StaffMenu.PlatineManage.Button(":target: MODIFIER LA POSITION", "Position actuelle", nil, "chevron", false, function()
        local newPos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("vfw:staff:update:platine", platineId, { position = newPos })
        selectedPlatine.data.position = newPos
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
            message = "Position mise à jour à votre emplacement actuel"
      })
        Wait(150)
        StaffMenu.PlatineManage.refresh()
    end)

    -- Position du floating
    StaffMenu.PlatineManage.Button(":target: Position du floating", nil, ("Hauteur: %.2f"):format(platineInfo.floatingZ or 0.5), "chevron", false, function()
        if not platineInfo.position then return end
        StaffMenu.PlatineManage.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(platineInfo.position, platineInfo.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({ { label = "Monter", control = 172 }, { label = "Descendre", control = 173 }, { label = "Valider", control = 201 } })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                local newZ = FloatingUI.StopHeightPreview()
                platineInfo.floatingZ = newZ
                TriggerServerEvent("vfw:staff:update:platine", platineId, { floatingZ = newZ })
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.PlatineManage.open()
    end)

    -- Modifier l'accès (scope)
    local currentScope = platineInfo.scope or "public"
  local currentJob = platineInfo.job
    local scopeDisplayLabel = currentScope == "public" and "Public" or ("Job - " .. (GetJobLabel(currentJob) or currentJob or "Non défini"))

    StaffMenu.PlatineManage.Button(":lock: MODIFIER L'ACCÈS", scopeDisplayLabel, nil, "chevron", false, function()
    end, StaffMenu.PlatineEditScope)

    StaffMenu.PlatineManage.Separator("DANGER")

    -- Supprimer la platine
    StaffMenu.PlatineManage.Button(":trash: SUPPRIMER", nil, nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'SUPPRIMER' pour confirmer la suppression de: " .. platineName)

        if confirm and confirm:upper() == "SUPPRIMER" then
            TriggerServerEvent("vfw:staff:delete:platine", platineId)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
                message = "Platine '" .. platineName .. "' supprimée"
          })
            selectedPlatine.id = nil
            selectedPlatine.data = nil
            Wait(150)
            StaffMenu.PlatineManage.close()
            StaffMenu.DeletePlatine.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Mode DJ',
                message = "Suppression annulée"
          })
        end
    end)
end

-- ============================================
-- MENUS DE SELECTION SCOPE/JOB (CREATION)
-- ============================================

--- Menu de sélection du type d'accès (création)
function StaffMenu.BuildPlatineSelectScopeMenu()
    StaffMenu.PlatineSelectScope.Separator(":lock: TYPE D'ACCÈS")

    -- Option Public
    local isPublic = platineData.scope == "public"
  StaffMenu.PlatineSelectScope.Button(":globe: PUBLIC", isPublic and ":check: Sélectionné" or "Accessible à tous", nil, isPublic and "check" or "chevron", false, function()
        platineData.scope = "public"
      platineData.job = nil
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
            message = "Accès défini sur Public"
      })
        StaffMenu.PlatineSelectScope.close()
        StaffMenu.CreatePlatine.refresh()
    end)

    -- Option Job (ouvre sous-menu)
    local isJob = platineData.scope == "job"
  local jobLabel = isJob and platineData.job and GetJobLabel(platineData.job) or "Sélectionner un job"
  StaffMenu.PlatineSelectScope.Button(":briefcase: JOB", isJob and (":check: " .. jobLabel) or "Restreint à un job", nil, "chevron", false, function()
        platineData.scope = "job"
  end, StaffMenu.PlatineSelectJob)
end

--- Menu de sélection du job (création)
function StaffMenu.BuildPlatineSelectJobMenu()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    StaffMenu.PlatineSelectJob.Separator(":briefcase: SÉLECTIONNER UN JOB")

    if not jobs or not next(jobs) then
        StaffMenu.PlatineSelectJob.Button("", "Aucun job trouvé", nil, nil, true, function() end)
        return
    end

    -- Trier les jobs par label
    local sortedJobs = {}
    for _, job in pairs(jobs) do
        if job.name and job.name ~= "unemployed" then
            table.insert(sortedJobs, job)
        end
    end
    table.sort(sortedJobs, function(a, b)
        return (a.label or a.name) < (b.label or b.name)
    end)

    for _, job in ipairs(sortedJobs) do
        local isSelected = platineData.job == job.name
        StaffMenu.PlatineSelectJob.Button(job.label or job.name, isSelected and ":check: Sélectionné" or job.name, nil, isSelected and "check" or "chevron", false, function()
            platineData.job = job.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
                message = "Job sélectionné: " .. (job.label or job.name)
            })
            StaffMenu.PlatineSelectJob.close()
            StaffMenu.PlatineSelectScope.close()
            StaffMenu.CreatePlatine.refresh()
        end)
    end
end

-- ============================================
-- MENUS DE MODIFICATION SCOPE/JOB (EDITION)
-- ============================================

--- Menu de modification du type d'accès (édition platine existante)
function StaffMenu.BuildPlatineEditScopeMenu()
    if not selectedPlatine.id or not selectedPlatine.data then
        StaffMenu.PlatineEditScope.Button("", "Aucune platine sélectionnée", nil, nil, true, function() end)
        return
    end

    local platine = selectedPlatine.data
    local currentScope = platine.scope or "public"

  StaffMenu.PlatineEditScope.Separator(":lock: MODIFIER L'ACCÈS")
    StaffMenu.PlatineEditScope.Separator("Platine: " .. (platine.name or "Inconnue"))

    -- Option Public
    local isPublic = currentScope == "public"
  StaffMenu.PlatineEditScope.Button(":globe: PUBLIC", isPublic and ":check: Actuel" or "Accessible à tous", nil, isPublic and "check" or "chevron", false, function()
        TriggerServerEvent("vfw:staff:update:platine", selectedPlatine.id, { scope = "public", job = nil })
        selectedPlatine.data.scope = "public"
      selectedPlatine.data.job = nil
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
            message = "Accès modifié en Public"
      })
        Wait(150)
        StaffMenu.PlatineEditScope.close()
        StaffMenu.PlatineManage.refresh()
    end)

    -- Option Job (ouvre sous-menu)
    local isJob = currentScope == "job"
  local jobLabel = isJob and platine.job and GetJobLabel(platine.job) or "Sélectionner un job"
  StaffMenu.PlatineEditScope.Button(":briefcase: JOB", isJob and (":check: " .. jobLabel) or "Restreint à un job", nil, "chevron", false, function()
    end, StaffMenu.PlatineEditSelectJob)
end

--- Menu de sélection du job (édition platine existante)
function StaffMenu.BuildPlatineEditSelectJobMenu()
    if not selectedPlatine.id or not selectedPlatine.data then
        StaffMenu.PlatineEditSelectJob.Button("", "Aucune platine sélectionnée", nil, nil, true, function() end)
        return
    end

    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    local platine = selectedPlatine.data
    local currentJob = platine.job

    StaffMenu.PlatineEditSelectJob.Separator(":briefcase: SÉLECTIONNER UN JOB")

    if not jobs or not next(jobs) then
        StaffMenu.PlatineEditSelectJob.Button("", "Aucun job trouvé", nil, nil, true, function() end)
        return
    end

    -- Trier les jobs par label
    local sortedJobs = {}
    for _, job in pairs(jobs) do
        if job.name and job.name ~= "unemployed" then
            table.insert(sortedJobs, job)
        end
    end
    table.sort(sortedJobs, function(a, b)
        return (a.label or a.name) < (b.label or b.name)
    end)

    for _, job in ipairs(sortedJobs) do
        local isSelected = currentJob == job.name
        StaffMenu.PlatineEditSelectJob.Button(job.label or job.name, isSelected and ":check: Actuel" or job.name, nil, isSelected and "check" or "chevron", false, function()
            TriggerServerEvent("vfw:staff:update:platine", selectedPlatine.id, { scope = "job", job = job.name })
            selectedPlatine.data.scope = "job"
          selectedPlatine.data.job = job.name
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Mode DJ',
                message = "Accès modifié: Job " .. (job.label or job.name)
            })
            Wait(150)
            StaffMenu.PlatineEditSelectJob.close()
            StaffMenu.PlatineEditScope.close()
            StaffMenu.PlatineManage.refresh()
        end)
    end
end
