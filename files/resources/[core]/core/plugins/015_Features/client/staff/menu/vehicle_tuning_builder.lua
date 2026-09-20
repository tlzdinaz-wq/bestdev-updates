---@meta _
---@diagnostic disable: duplicate-doc-field

local tuningData = {
    id = nil,
    label = nil,
    coords = nil,
    jobRequired = nil,
    gradeMin = 0,
    floatingZ = 0.5,
    isUpdate = false
}

function resetTuningData()
    tuningData = {
        id = nil,
        label = nil,
        coords = nil,
        jobRequired = nil,
        gradeMin = 0,
        floatingZ = 0.5,
        isUpdate = false
    }
end

local function closeTuningCreator()
    resetTuningData()
    StaffMenu.CreateVehicleTuning.close()
    StaffMenu.builderVehicleTuning.open()
end

local function checkValidTuningData()
    if not tuningData.label or not tuningData.coords or not tuningData.jobRequired then
        return false
    end
    return true
end

function StaffMenu.BuildVehicleTuningBuilderMenu()
    StaffMenu.builderVehicleTuning.Button(":plus: CRÉER UN POINT", nil, nil, "chevron", false, function()
        resetTuningData()
    end, StaffMenu.CreateVehicleTuning)

    StaffMenu.builderVehicleTuning.Button(":report: LISTE DES POINTS", nil, nil, "chevron", false, function()
    end, StaffMenu.VehicleTuningList)
end

function StaffMenu.BuildVehicleTuningJobSelectMenu()
    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    if not next(jobs) then
        StaffMenu.VehicleTuningJobSelect.Button("AUCUN JOB", "Pas de jobs disponibles", nil, nil, true, function() end)
        return
    end

    for _, job in pairs(jobs) do
        local isSelected = tuningData.jobRequired == job.name
        StaffMenu.VehicleTuningJobSelect.Button(
            job.label or job.name,
            job.name,
            nil,
            isSelected and "check" or "chevron",
            false,
            function()
                tuningData.jobRequired = job.name
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Builder Tuning',
                    message = "Job sélectionné: " .. (job.label or job.name)
                })
                StaffMenu.CreateVehicleTuning.refresh()
            end
        )
    end
end

function StaffMenu.BuildCreateVehicleTuningMenu()
    StaffMenu.CreateVehicleTuning.Button("NOM DU POINT", nil, tuningData.label, "chevron", false, function()
        local label <const> = VFW.Nui.KeyboardInput(true, "Entrer le nom du point")

        if not label or label == "" then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Tuning',
                message = "Ce nom n'est pas valide"
          })
        end

        tuningData.label = label
        StaffMenu.CreateVehicleTuning.refresh()
    end)

    StaffMenu.CreateVehicleTuning.Button("DÉFINIR LA POSITION", nil, nil, tuningData.coords and "check" or "chevron", false, function()
        local playerCoords <const> = GetEntityCoords(PlayerPedId())

        if not playerCoords then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Tuning',
                message = "Cette position n'est pas valide"
          })
        end

        tuningData.coords = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }
        StaffMenu.CreateVehicleTuning.refresh()
    end)

    local jobLabel = tuningData.jobRequired or "Non défini"
  if tuningData.jobRequired and StaffMenu.data.jobsList then
        for _, job in pairs(StaffMenu.data.jobsList) do
            if job.name == tuningData.jobRequired then
                jobLabel = job.label or job.name
                break
            end
        end
    end

    StaffMenu.CreateVehicleTuning.Button("JOB AUTORISÉ", nil, jobLabel, "chevron", false, function()
    end, StaffMenu.VehicleTuningJobSelect)

    StaffMenu.CreateVehicleTuning.Button("GRADE MINIMUM", nil, tuningData.gradeMin or 0, "chevron", false, function()
        local grade <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le grade minimum (0 pour aucune restriction)"))

        if not grade or grade < 0 then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Tuning',
                message = "Ce grade n'est pas valide"
          })
        end

        tuningData.gradeMin = grade
        StaffMenu.CreateVehicleTuning.refresh()
    end)

    StaffMenu.CreateVehicleTuning.Button("Position du floating", nil, ("Hauteur: %.2f"):format(tuningData.floatingZ or 0.5), "chevron", false, function()
        if not tuningData.coords then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Tuning',
                message = "Définissez d'abord la position."
          })
            return
        end
        StaffMenu.CreateVehicleTuning.close()
        VUI_CurrentMenu = nil
        FloatingUI.StartHeightPreview(vector3(tuningData.coords.x, tuningData.coords.y, tuningData.coords.z), tuningData.floatingZ or 0.5)
        local instrId = VFW.AddInstructionalButtons({
            { label = "Monter", control = 172 },
            { label = "Descendre", control = 173 },
            { label = "Valider", control = 201 }
        })
        while FloatingUI.IsPreviewActive() do
            if IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                tuningData.floatingZ = FloatingUI.StopHeightPreview()
                break
            end
            Wait(0)
        end
        VFW.RemoveInstructionalButtons(instrId)
        StaffMenu.CreateVehicleTuning.open()
    end)

    StaffMenu.CreateVehicleTuning.Separator()

    StaffMenu.CreateVehicleTuning.Button(":check: CRÉER / MODIFIER LE POINT", nil, nil, "chevron", false, function()
        if not checkValidTuningData() then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Tuning',
                message = "Ces données ne sont pas valides. Vérifiez nom, position et job."
          })
        end

        if tuningData.isUpdate then
            TriggerServerEvent("vehicleTuningBuilder:server:update", {
                id = tuningData.id,
                label = tuningData.label,
                coords = tuningData.coords,
                jobRequired = tuningData.jobRequired,
                gradeMin = tuningData.gradeMin,
                floatingZ = tuningData.floatingZ
            })
        else
            TriggerServerEvent("vehicleTuningBuilder:server:create", {
                label = tuningData.label,
                coords = tuningData.coords,
                jobRequired = tuningData.jobRequired,
                gradeMin = tuningData.gradeMin,
                floatingZ = tuningData.floatingZ
            })
        end

        closeTuningCreator()
    end)

    StaffMenu.CreateVehicleTuning.Button(":x: Annuler", nil, nil, "chevron", false, function()
        closeTuningCreator()
    end)
end

local currentTuning

function StaffMenu.BuildVehicleTuningListMenu()
    local points <const> = TriggerServerCallback("vehicleTuningBuilder:getAllPoints")

    if not points or not next(points) then
        StaffMenu.VehicleTuningList.Button("AUCUN POINT", nil, nil, nil, false, function() end)
        return
    end

    local jobs = StaffMenu.data.jobsList or TriggerServerCallback("vfw:staff:getJobs") or {}
    StaffMenu.data.jobsList = jobs

    local jobLabels = {}
    for _, job in pairs(jobs) do
        jobLabels[job.name] = job.label or job.name
    end

    local pointsByJob = {}
    for _, point in pairs(points) do
        local jobName = point.jobRequired or "inconnu"
      pointsByJob[jobName] = pointsByJob[jobName] or {}
        table.insert(pointsByJob[jobName], point)
    end

    for jobName, jobPoints in pairs(pointsByJob) do
        StaffMenu.VehicleTuningList.Separator(":briefcase: " .. (jobLabels[jobName] or jobName))
        for _, point in pairs(jobPoints) do
            local rightLabel = "Grade min: " .. tostring(point.gradeMin or 0)
            StaffMenu.VehicleTuningList.Button(point.label, jobLabels[jobName] or jobName, rightLabel, "chevron", false, function()
                currentTuning = point
            end, StaffMenu.VehicleTuningManage)
        end
    end
end

function StaffMenu.BuildVehicleTuningManageMenu()
    StaffMenu.VehicleTuningManage.Button(":target: TÉLÉPORTATION A LA POSITION", nil, nil, "chevron", false, function()
        if not currentTuning or not currentTuning.coords then
            return VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Tuning',
                message = "Aucune position définie"
          })
        end

        SetEntityCoords(PlayerPedId(), currentTuning.coords.x, currentTuning.coords.y, currentTuning.coords.z + 1.0, false, false, false, false)
    end)

    StaffMenu.VehicleTuningManage.Button(":monitor: MODIFIER LE POINT", nil, nil, "chevron", false, function()
        if not currentTuning then return end
        tuningData = {
            id = currentTuning.id,
            label = currentTuning.label,
            coords = currentTuning.coords,
            jobRequired = currentTuning.jobRequired,
            gradeMin = currentTuning.gradeMin or 0,
            floatingZ = currentTuning.floatingZ or 0.5,
            isUpdate = true
        }
    end, StaffMenu.CreateVehicleTuning)

    StaffMenu.VehicleTuningManage.Button(":trash: SUPPRIMER LE POINT", nil, nil, "chevron", false, function()
        if not currentTuning then return end
        TriggerServerEvent("vehicleTuningBuilder:server:delete", currentTuning.id)
        currentTuning = nil
        StaffMenu.VehicleTuningManage.close()
        StaffMenu.VehicleTuningList.open()
    end)
end
