---@meta _
---@diagnostic disable: duplicate-doc-field

--- .BuildGradesJobsMenu
function StaffMenu.BuildGradesJobsMenu()
    if StaffMenu.data.jobsList and StaffMenu.data.selecteJob and StaffMenu.data.jobsList[StaffMenu.data.selecteJob] then
        local jobData = StaffMenu.data.jobsList[StaffMenu.data.selecteJob]
        local currentJobName = StaffMenu.data.playerInfo and StaffMenu.data.playerInfo.jobName or ""
      local currentGrade = StaffMenu.data.playerInfo and tonumber(StaffMenu.data.playerInfo.gradeNum) or -1

        -- Afficher le nom du job
        StaffMenu.grades_jobs.Separator(":report: " .. (jobData.label or StaffMenu.data.selecteJob))

        -- Convertir les grades en table triable
        local sortedGrades = {}
        for k, v in pairs(jobData.grades) do
            table.insert(sortedGrades, { key = k, data = v })
        end

        -- Trier par grade décroissant (patron en haut, grade le plus faible en bas)
        table.sort(sortedGrades, function(a, b)
            return (tonumber(a.data.grade) or 0) > (tonumber(b.data.grade) or 0)
        end)

        -- Afficher les grades triés
        for _, item in ipairs(sortedGrades) do
            local k, v = item.key, item.data
            local isCurrentGrade = (currentJobName == StaffMenu.data.selecteJob) and (tonumber(v.grade) == currentGrade)
            local icon = isCurrentGrade and "check" or nil
            local rightLabel = isCurrentGrade and "Grade actuel" or ("Niveau " .. v.grade)

            StaffMenu.grades_jobs.Button(v.label, rightLabel, nil, icon, isCurrentGrade, function()
                if not isCurrentGrade then
                    TriggerServerEvent('vfw:staff:setJob', StaffMenu.data.playerInfo.id, StaffMenu.data.selecteJob, v.grade)

                    -- Mettre à jour les données locales
                    StaffMenu.data.playerInfo.job = jobData.label
                    StaffMenu.data.playerInfo.jobName = StaffMenu.data.selecteJob
                    StaffMenu.data.playerInfo.grade = v.label
                    StaffMenu.data.playerInfo.gradeNum = v.grade

                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Grades',
                        message = "Job changé: " .. jobData.label .. " - " .. v.label
                    })

                    -- Rafraîchir le menu des grades
                    StaffMenu.grades_jobs.refresh()
                end
            end)
        end
    end
end

--- .BuildGradesFactionsMenu
function StaffMenu.BuildGradesFactionsMenu()
    if StaffMenu.data.factionsList and StaffMenu.data.selectedFaction and StaffMenu.data.factionsList[StaffMenu.data.selectedFaction] then
        local factionData = StaffMenu.data.factionsList[StaffMenu.data.selectedFaction]
        local currentFactionName = StaffMenu.data.playerInfo and StaffMenu.data.playerInfo.factionName or ""
      local currentGrade = StaffMenu.data.playerInfo and tonumber(StaffMenu.data.playerInfo.factionGradeNum) or -1

        -- Afficher le nom de la faction
        StaffMenu.grades_factions.Separator(":report: " .. (factionData.label or StaffMenu.data.selectedFaction))

        -- Convertir les grades en table triable (compatible clé "grade" et "grades")
        local sortedGrades = {}
        local gradeSource = factionData.grades or factionData.grade or {}
        for k, v in pairs(gradeSource) do
            table.insert(sortedGrades, { key = k, data = v })
        end

        -- Trier par grade décroissant (patron en haut)
        table.sort(sortedGrades, function(a, b)
            return (tonumber(a.data.grade) or 0) > (tonumber(b.data.grade) or 0)
        end)

        for _, item in ipairs(sortedGrades) do
            local k, v = item.key, item.data
            local isCurrentGrade = (currentFactionName == StaffMenu.data.selectedFaction) and (tonumber(v.grade) == currentGrade)
            local icon = isCurrentGrade and "check" or nil
            local rightLabel = isCurrentGrade and "Grade actuel" or ("Niveau " .. v.grade)

            StaffMenu.grades_factions.Button(v.label, rightLabel, nil, icon, isCurrentGrade, function()
                if not isCurrentGrade then
                    TriggerServerEvent('vfw:staff:setFaction', StaffMenu.data.playerInfo.id, StaffMenu.data.selectedFaction, v.grade)

                    -- Mettre à jour les données locales
                    StaffMenu.data.playerInfo.faction = factionData.label
                    StaffMenu.data.playerInfo.factionName = StaffMenu.data.selectedFaction
                    StaffMenu.data.playerInfo.factionGrade = v.label
                    StaffMenu.data.playerInfo.factionGradeNum = v.grade

                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Grades',
                        message = "Faction changée: " .. factionData.label .. " - " .. v.label
                    })

                    -- Rafraîchir le menu des grades
                    StaffMenu.grades_factions.refresh()
                end
            end)
        end
    end
end
