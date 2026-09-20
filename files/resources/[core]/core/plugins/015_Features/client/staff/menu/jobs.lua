---@meta _
---@diagnostic disable: duplicate-doc-field

local jobQuery = nil

--- .BuildJobsMenu
---@return any
function StaffMenu.BuildJobsMenu()
    local firstLabel = jobQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = jobQuery == nil and "UN JOB" or jobQuery

    -- Bouton refresh pour recharger les données
    StaffMenu.jobs.Button(":refresh: ACTUALISER", "Recharger les jobs depuis le serveur", nil, "chevron", false, function()
        StaffMenu.data.jobsList = TriggerServerCallback("vfw:staff:getJobs") or {}
        StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", StaffMenu.data.selectedPlayer) or {}
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Métiers', message = "Liste des jobs actualisée." })
        StaffMenu.jobs.refresh()
    end)

    StaffMenu.jobs.Button(firstLabel, lastLabel, nil, "search", false, function()
        if jobQuery ~= nil then
            jobQuery = nil
            StaffMenu.jobs.refresh()
            return
        end

        jobQuery = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if jobQuery == nil or jobQuery == "" then
            jobQuery = nil
            return
        end

        StaffMenu.jobs.refresh()
    end)

    -- Afficher le job actuel du joueur
    if StaffMenu.data.playerInfo then
        local currentJobLabel = StaffMenu.data.playerInfo.job or "Aucun"
      local currentGradeLabel = StaffMenu.data.playerInfo.grade or ""
      local currentJobName = StaffMenu.data.playerInfo.jobName or "unemployed"

      StaffMenu.jobs.Separator(":report: JOB ACTUEL")

        if currentJobName ~= "unemployed" then
            -- Bouton pour changer le grade du job actuel
            StaffMenu.jobs.Button(":edit: " .. currentJobLabel, "Grade: " .. currentGradeLabel .. " - Cliquer pour changer", nil, "chevron", false, function()
                StaffMenu.data.selecteJob = currentJobName
            end, StaffMenu.grades_jobs)

            -- Bouton pour retirer le job
            StaffMenu.jobs.Button(":trash: RETIRER LE JOB", "Mettre au chômage", nil, "trash", false, function()
                TriggerServerEvent('vfw:staff:setJob', StaffMenu.data.playerInfo.id, "unemployed", 0)
                StaffMenu.data.playerInfo.job = "Chômeur"
              StaffMenu.data.playerInfo.jobName = "unemployed"
              StaffMenu.data.playerInfo.grade = "0"
              VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Métiers',
                    message = "Job retiré."
              })
                StaffMenu.jobs.refresh()
            end)
        else
            StaffMenu.jobs.Button("Chômeur", "Aucun job assigné", nil, nil, true, function() end)
        end
    end

    StaffMenu.jobs.Separator(":folder: AUTRES JOBS")

    if StaffMenu.data.jobsList and next(StaffMenu.data.jobsList) then
        local currentJobName = StaffMenu.data.playerInfo and StaffMenu.data.playerInfo.jobName or ""

      for _, v in pairs(StaffMenu.data.jobsList) do
            if v.label == nil then
                v.label = "Inconnu"
          end

            if jobQuery == nil or string.find(string.lower(v.name), string.lower(jobQuery)) or string.find(string.lower(v.label), string.lower(jobQuery)) then
                -- Ne pas afficher le job actuel dans la liste des autres jobs
                if currentJobName ~= v.name then
                    StaffMenu.jobs.Button(v.label, v.name, nil, "chevron", false, function()
                        StaffMenu.data.selecteJob = v.name
                    end, StaffMenu.grades_jobs)
                end
            end
        end
    end
end
