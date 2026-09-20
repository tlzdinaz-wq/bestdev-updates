-- ========================================================================
-- BUILDER RADIO 911 - Gestion whitelist jobs
-- ========================================================================

StaffMenu.builderRadio911.OnOpen(function()
    StaffMenu.builderRadio911.ClearItems()

    StaffMenu.builderRadio911.Separator(":plus: AJOUTER")
    StaffMenu.builderRadio911.Button("Ajouter un job", "Voir la liste des jobs disponibles", nil, "chevron", false, function() end, StaffMenu.builderRadio911Add)

    StaffMenu.builderRadio911.Separator(":search: RECHERCHER")
    StaffMenu.builderRadio911.Button("Rechercher un job", "Entrez le nom du job à ajouter", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nom du job (ex: lspd)")
        if not input or input == "" then return end

        input = string.lower(input)
        local ok = TriggerServerCallback("radio911:addJob", input)
        if ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Radio 911', message = 'Job "' .. input .. '" ajouté.' })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Radio 911', message = 'Job déjà présent ou erreur.' })
        end
        StaffMenu.builderRadio911.refresh()
    end)

    StaffMenu.builderRadio911.Separator(":music: JOBS AUTORISÉS")

    local jobs = TriggerServerCallback("radio911:getAllowedJobs")
    local allJobs = TriggerServerCallback("vfw:staff:getJobs")
    if not jobs or #jobs == 0 then
        StaffMenu.builderRadio911.Button("Aucun job configuré", "Ajoutez des jobs avec les boutons ci-dessus", nil, "chevron", true, function() end)
    else
        for _, jobName in ipairs(jobs) do
            local jobLabel = allJobs and allJobs[jobName] and allJobs[jobName].label or jobName
            local displayLabel = jobLabel ~= jobName and (jobLabel .. " (" .. jobName .. ")") or jobName
            StaffMenu.builderRadio911.Button(displayLabel, "Cliquer pour retirer", nil, "trash", false, function()
                local ok = TriggerServerCallback("radio911:removeJob", jobName)
                if ok then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Radio 911', message = 'Job "' .. jobLabel .. '" retiré.' })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Radio 911', message = 'Erreur lors de la suppression.' })
                end
                StaffMenu.builderRadio911.refresh()
            end)
        end
    end
end)

-- Submenu listing all available jobs (not already whitelisted)
StaffMenu.builderRadio911Add.OnOpen(function()
    StaffMenu.builderRadio911Add.ClearItems()
    StaffMenu.builderRadio911Add.Separator(":report: JOBS DISPONIBLES")

    local allJobs = TriggerServerCallback("vfw:staff:getJobs")
    local allowedJobs = TriggerServerCallback("radio911:getAllowedJobs")

    -- Build lookup for already allowed jobs
    local allowedLookup = {}
    if allowedJobs then
        for _, j in ipairs(allowedJobs) do
            allowedLookup[j] = true
        end
    end

    if not allJobs then
        StaffMenu.builderRadio911Add.Button("Aucun job trouvé", "Le serveur n'a retourné aucun job", nil, "chevron", true, function() end)
        return
    end

    -- Convert table to sorted list
    local sorted = {}
    for name, job in pairs(allJobs) do
        if not allowedLookup[name] then
            sorted[#sorted + 1] = { name = name, label = job.label or name }
        end
    end
    table.sort(sorted, function(a, b) return a.label < b.label end)

    if #sorted == 0 then
        StaffMenu.builderRadio911Add.Button("Tous les jobs sont déjà autorisés", "", nil, "chevron", true, function() end)
        return
    end

    for _, job in ipairs(sorted) do
        local label = job.label ~= job.name and (job.label .. " (" .. job.name .. ")") or job.name
        StaffMenu.builderRadio911Add.Button(label, "Cliquer pour autoriser", nil, "chevron", false, function()
            local ok = TriggerServerCallback("radio911:addJob", job.name)
            if ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Radio 911', message = 'Job "' .. job.name .. '" ajouté.' })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Radio 911', message = 'Job déjà présent ou erreur.' })
            end
            StaffMenu.builderRadio911Add.refresh()
        end)
    end
end)
