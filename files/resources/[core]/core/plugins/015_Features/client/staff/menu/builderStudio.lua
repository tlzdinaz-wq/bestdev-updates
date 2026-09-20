---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- STUDIO D'ENREGISTREMENT BUILDER
-- ============================================

function StaffMenu.BuildStudioBuilderMenu()
    StaffMenu.builderStudio.Button(":music: CRÉER UN STUDIO", "Placer un nouveau studio d'enregistrement", nil, "chevron", false, function()
    end, StaffMenu.CreateStudio)

    StaffMenu.builderStudio.Button(":trash: GÉRER LES STUDIOS", "Modifier ou supprimer des studios", nil, "chevron", false, function()
    end, StaffMenu.ManageStudios)
end

local studioData = {
    name = "",
    position = nil,
    mixingTablePosition = nil,
    liveZoneRadius = 15.0,
    scope = "public",  -- "public" ou "job"
  job = nil
}

local selectedStudio = {
    id = nil,
    data = nil
}

local function ResetStudioData()
    studioData = {
        name = "",
        position = nil,
        mixingTablePosition = nil,
        liveZoneRadius = 15.0,
        scope = "public",
        job = nil
    }
end

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

-- ============================================
-- MENU DE CRÉATION
-- ============================================

function StaffMenu.BuildCreateStudioMenu()
    StaffMenu.CreateStudio.Separator("CRÉATION DE STUDIO")

    -- Nom du studio
    StaffMenu.CreateStudio.Button("NOM", studioData.name ~= "" and studioData.name or "Non défini", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Entrer le nom du studio", studioData.name)
        if input and input ~= "" then
            studioData.name = input
            StaffMenu.CreateStudio.refresh()
        end
    end)

    -- Position principale (point d'entrée singer)
    StaffMenu.CreateStudio.Button("POSITION STUDIO", studioData.position and "Définie" or "Non définie", nil, "chevron", false, function()
        studioData.position = GetEntityCoords(PlayerPedId())
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Position du studio enregistrée."
      })
        StaffMenu.CreateStudio.refresh()
    end)

    -- Position table de mixage (point d'entrée engineer)
    StaffMenu.CreateStudio.Button("POSITION TABLE MIXAGE", studioData.mixingTablePosition and "Définie" or "Non définie", nil, "chevron", false, function()
        studioData.mixingTablePosition = GetEntityCoords(PlayerPedId())
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Position de la table de mixage enregistrée."
      })
        StaffMenu.CreateStudio.refresh()
    end)

    StaffMenu.CreateStudio.Separator("PARAMÈTRES")

    -- Rayon zone live
    StaffMenu.CreateStudio.Button("RAYON ZONE LIVE", studioData.liveZoneRadius .. " metres", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rayon de la zone d'écoute live (5-100)", tostring(studioData.liveZoneRadius))
        if input and tonumber(input) then
            local radius = tonumber(input)
            if radius >= 5 and radius <= 100 then
                studioData.liveZoneRadius = radius
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Studio Builder',
                    message = "Rayon défini à " .. radius .. " metres."
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'INFO',
                    subtitle = 'Studio Builder',
                    message = "Le rayon doit être entre 5 et 100 mètres."
              })
            end
            StaffMenu.CreateStudio.refresh()
        end
    end)

    StaffMenu.CreateStudio.Separator("RESTRICTIONS D'ACCÈS")

    -- Scope
    local scopeLabel = studioData.scope == "public" and "Public" or "Job"
  local scopeDetail = studioData.scope == "job" and studioData.job and GetJobLabel(studioData.job) or nil
    local scopeRightLabel = scopeDetail and (scopeLabel .. " - " .. scopeDetail) or scopeLabel

    StaffMenu.CreateStudio.Button("ACCES", scopeRightLabel, nil, "chevron", false, function()
    end, StaffMenu.StudioSelectScope)

    StaffMenu.CreateStudio.Separator(nil)

    -- Valider
    local canCreate = studioData.name ~= "" and studioData.position and studioData.mixingTablePosition
    StaffMenu.CreateStudio.Button("CREER LE STUDIO", "Valider et sauvegarder", nil, "check", not canCreate, function()
        if studioData.name == "" then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Studio Builder',
                message = "Veuillez définir un nom."
          })
            return
        end

        if not studioData.position then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Studio Builder',
                message = "Veuillez définir la position du studio."
          })
            return
        end

        if not studioData.mixingTablePosition then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Studio Builder',
                message = "Veuillez définir la position de la table de mixage."
          })
            return
        end

        if studioData.scope == "job" and not studioData.job then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Studio Builder',
                message = "Veuillez sélectionnér un job."
          })
            return
        end

        TriggerServerEvent("vfw:staff:create:studio", {
            name = studioData.name,
            position = studioData.position,
            mixingTablePosition = studioData.mixingTablePosition,
            liveZoneRadius = studioData.liveZoneRadius,
            scope = studioData.scope,
            job = studioData.job
        })

        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Studio '" .. studioData.name .. "' créé."
      })

        ResetStudioData()
        StaffMenu.CreateStudio.refresh()
    end)

    -- Annuler
    StaffMenu.CreateStudio.Button("ANNULER", nil, nil, "chevron", false, function()
        ResetStudioData()
        StaffMenu.CreateStudio.close()
        StaffMenu.CreateStudio.parent.open()
    end)
end

-- ============================================
-- MENU DE GESTION (LISTE)
-- ============================================

function StaffMenu.BuildManageStudiosMenu()
    local allStudios = TriggerServerCallback("vfw:staff:getAllStudios")

    if not allStudios or next(allStudios) == nil then
        StaffMenu.ManageStudios.Button("", "Aucun studio trouve", nil, nil, true, function() end)
        return
    end

    StaffMenu.ManageStudios.Separator("STUDIOS EXISTANTS")

    local sortedStudios = {}
    for studioId, studioInfo in pairs(allStudios) do
        table.insert(sortedStudios, { id = studioId, info = studioInfo })
    end
    table.sort(sortedStudios, function(a, b)
        return (a.info.name or a.id) < (b.info.name or b.id)
    end)

    for _, studio in ipairs(sortedStudios) do
        local studioId = studio.id
        local studioInfo = studio.info
        local studioName = studioInfo.name or ("Studio #" .. studioId)
        local currentScope = studioInfo.scope or "public"
      local scopeIcon = currentScope == "public" and "" or "(Job)"

      StaffMenu.ManageStudios.Button(studioName, scopeIcon .. " " .. (currentScope == "public" and "Public" or GetJobLabel(studioInfo.job) or "Job"), nil, "chevron", false, function()
            selectedStudio.id = studioId
            selectedStudio.data = studioInfo
        end, StaffMenu.StudioManage)
    end
end

-- ============================================
-- MENU DE GESTION (INDIVIDUEL)
-- ============================================

function StaffMenu.BuildStudioManageMenu()
    if not selectedStudio.id or not selectedStudio.data then
        StaffMenu.StudioManage.Button("", "Aucun studio sélectionné", nil, nil, true, function() end)
        return
    end

    local studioId = selectedStudio.id
    local studioInfo = selectedStudio.data
    local studioName = studioInfo.name or ("Studio #" .. studioId)

    StaffMenu.StudioManage.Separator(studioName)

    -- Teleportation
    StaffMenu.StudioManage.Button("SE TELEPORTER (Studio)", nil, nil, "chevron", false, function()
        local pos = studioInfo.position
        if pos then
            if type(pos) == "table" then
                SetEntityCoords(PlayerPedId(), pos.x or pos[1], pos.y or pos[2], pos.z or pos[3], false, false, false, false)
            else
                SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, false)
            end
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Studio Builder',
                message = "Téléporté au studio."
          })
        end
    end)

    StaffMenu.StudioManage.Button("SE TELEPORTER (Table mixage)", nil, nil, "chevron", false, function()
        local pos = studioInfo.mixingTablePosition
        if pos then
            if type(pos) == "table" then
                SetEntityCoords(PlayerPedId(), pos.x or pos[1], pos.y or pos[2], pos.z or pos[3], false, false, false, false)
            else
                SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, false)
            end
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Studio Builder',
                message = "Téléporté a la table de mixage."
          })
        end
    end)

    StaffMenu.StudioManage.Separator("PARAMÈTRES")

    -- Modifier le nom
    StaffMenu.StudioManage.Button("MODIFIER LE NOM", studioName, nil, "chevron", false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nouveau nom du studio", studioName)
        if newName and newName ~= "" and newName ~= studioName then
            TriggerServerEvent("vfw:staff:update:studio", studioId, { name = newName })
            selectedStudio.data.name = newName
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Studio Builder',
                message = "Nom modifié en '" .. newName .. "'."
          })
            Wait(150)
            StaffMenu.StudioManage.refresh()
            StaffMenu.ManageStudios.refresh()
        end
    end)

    -- Modifier position studio
    StaffMenu.StudioManage.Button("MODIFIER POSITION STUDIO", "Position actuelle", nil, "chevron", false, function()
        local newPos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("vfw:staff:update:studio", studioId, { position = newPos })
        selectedStudio.data.position = newPos
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Position du studio mise à jour."
      })
        Wait(150)
        StaffMenu.StudioManage.refresh()
    end)

    -- Modifier position table mixage
    StaffMenu.StudioManage.Button("MODIFIER POSITION TABLE", "Position actuelle", nil, "chevron", false, function()
        local newPos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("vfw:staff:update:studio", studioId, { mixingTablePosition = newPos })
        selectedStudio.data.mixingTablePosition = newPos
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Position de la table de mixage mise à jour."
      })
        Wait(150)
        StaffMenu.StudioManage.refresh()
    end)

    -- Modifier rayon
    local currentRadius = studioInfo.liveZoneRadius or 15
    StaffMenu.StudioManage.Button("MODIFIER RAYON ZONE", currentRadius .. "m", nil, "chevron", false, function()
        local newRadius = VFW.Nui.KeyboardInput(true, "Nouveau rayon (5-100)", tostring(currentRadius))
        if newRadius and tonumber(newRadius) then
            local radius = tonumber(newRadius)
            if radius >= 5 and radius <= 100 then
                TriggerServerEvent("vfw:staff:update:studio", studioId, { liveZoneRadius = radius })
                selectedStudio.data.liveZoneRadius = radius
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Studio Builder',
                    message = "Rayon modifié a " .. radius .. " metres."
              })
                Wait(150)
                StaffMenu.StudioManage.refresh()
            end
        end
    end)

    -- Modifier accès
    local currentScope = studioInfo.scope or "public"
  local currentJob = studioInfo.job
    local scopeDisplayLabel = currentScope == "public" and "Public" or ("Job - " .. (GetJobLabel(currentJob) or currentJob or "Non défini"))

    StaffMenu.StudioManage.Button("MODIFIER L'ACCÈS", scopeDisplayLabel, nil, "chevron", false, function()
    end, StaffMenu.StudioEditScope)

    StaffMenu.StudioManage.Separator("DANGER")

    -- Supprimer
    StaffMenu.StudioManage.Button("SUPPRIMER", nil, nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'SUPPRIMER' pour confirmer: " .. studioName)

        if confirm and confirm:upper() == "SUPPRIMER" then
            TriggerServerEvent("vfw:staff:delete:studio", studioId)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Studio Builder',
                message = "Studio '" .. studioName .. "' supprimé."
          })
            selectedStudio.id = nil
            selectedStudio.data = nil
            StaffMenu.StudioManage.close()
            StaffMenu.StudioManage.parent.open()
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Studio Builder',
                message = "Suppression annulee."
          })
        end
    end)
end

-- ============================================
-- MENUS DE SELECTION SCOPE/JOB (CREATION)
-- ============================================

function StaffMenu.BuildStudioSelectScopeMenu()
    StaffMenu.StudioSelectScope.Separator("TYPE D'ACCÈS")

    local isPublic = studioData.scope == "public"
  StaffMenu.StudioSelectScope.Button("PUBLIC", isPublic and "Sélectionné" or "Accessible à tous", nil, isPublic and "check" or "chevron", false, function()
        studioData.scope = "public"
      studioData.job = nil
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Accès défini sur Public."
      })
        StaffMenu.StudioSelectScope.close()
        StaffMenu.StudioSelectScope.parent.open()
    end)

    local isJob = studioData.scope == "job"
  local jobLabel = isJob and studioData.job and GetJobLabel(studioData.job) or "Sélectionner un job"
  StaffMenu.StudioSelectScope.Button("JOB", isJob and ("Sélectionné: " .. jobLabel) or "Restreint à un job", nil, "chevron", false, function()
        studioData.scope = "job"
  end, StaffMenu.StudioSelectJob)
end

function StaffMenu.BuildStudioSelectJobMenu()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    StaffMenu.StudioSelectJob.Separator("SÉLECTIONNER UN JOB")

    if not jobs or not next(jobs) then
        StaffMenu.StudioSelectJob.Button("", "Aucun job trouve", nil, nil, true, function() end)
        return
    end

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
        local isSelected = studioData.job == job.name
        StaffMenu.StudioSelectJob.Button(job.label or job.name, isSelected and "Sélectionné" or job.name, nil, isSelected and "check" or "chevron", false, function()
            studioData.job = job.name
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Studio Builder',
                message = "Job sélectionné: " .. (job.label or job.name)
            })
            StaffMenu.StudioSelectJob.close()
            StaffMenu.CreateStudio.open()
        end)
    end
end

-- ============================================
-- MENUS DE MODIFICATION SCOPE/JOB (EDITION)
-- ============================================

function StaffMenu.BuildStudioEditScopeMenu()
    if not selectedStudio.id or not selectedStudio.data then
        StaffMenu.StudioEditScope.Button("", "Aucun studio sélectionné", nil, nil, true, function() end)
        return
    end

    local studio = selectedStudio.data
    local currentScope = studio.scope or "public"

  StaffMenu.StudioEditScope.Separator("MODIFIER L'ACCÈS")
    StaffMenu.StudioEditScope.Separator("Studio: " .. (studio.name or "Inconnu"))

    local isPublic = currentScope == "public"
  StaffMenu.StudioEditScope.Button("PUBLIC", isPublic and "Actuel" or "Accessible à tous", nil, isPublic and "check" or "chevron", false, function()
        TriggerServerEvent("vfw:staff:update:studio", selectedStudio.id, { scope = "public", job = nil })
        selectedStudio.data.scope = "public"
      selectedStudio.data.job = nil
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Studio Builder',
            message = "Accès modifié en Public."
      })
        StaffMenu.StudioEditScope.close()
        StaffMenu.StudioEditScope.parent.open()
    end)

    local isJob = currentScope == "job"
  local jobLabel = isJob and studio.job and GetJobLabel(studio.job) or "Sélectionner un job"
  StaffMenu.StudioEditScope.Button("JOB", isJob and ("Actuel: " .. jobLabel) or "Restreint à un job", nil, "chevron", false, function()
    end, StaffMenu.StudioEditSelectJob)
end

function StaffMenu.BuildStudioEditSelectJobMenu()
    if not selectedStudio.id or not selectedStudio.data then
        StaffMenu.StudioEditSelectJob.Button("", "Aucun studio sélectionné", nil, nil, true, function() end)
        return
    end

    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    local studio = selectedStudio.data
    local currentJob = studio.job

    StaffMenu.StudioEditSelectJob.Separator("SÉLECTIONNER UN JOB")

    if not jobs or not next(jobs) then
        StaffMenu.StudioEditSelectJob.Button("", "Aucun job trouve", nil, nil, true, function() end)
        return
    end

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
        StaffMenu.StudioEditSelectJob.Button(job.label or job.name, isSelected and "Actuel" or job.name, nil, isSelected and "check" or "chevron", false, function()
            TriggerServerEvent("vfw:staff:update:studio", selectedStudio.id, { scope = "job", job = job.name })
            selectedStudio.data.scope = "job"
          selectedStudio.data.job = job.name
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Studio Builder',
                message = "Accès modifié: Job " .. (job.label or job.name)
            })
            StaffMenu.StudioEditSelectJob.close()
            StaffMenu.StudioManage.open()
        end)
    end
end
