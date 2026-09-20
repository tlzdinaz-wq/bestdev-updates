---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Staff Menu - Gestionnaire des props métier (jobsPropsMenu)
-- Hiérarchie : Métiers → Props → Actions (TP / Supprimer / Infos)
-- Données en mémoire serveur uniquement (volatile)
-- ============================================================

local function formatTime(ts)
    if not ts then return "Inconnu" end
    local seconds = ts % 60
    local minutes = math.floor(ts / 60) % 60
    local hours = math.floor(ts / 3600) % 24
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function formatCoords(c)
    if not c then return "?" end
    return ("%.1f / %.1f / %.1f"):format(c.x or 0, c.y or 0, c.z or 0)
end

-- ============================================================
-- Rebuild du menu par job
-- ============================================================

local selectedJobName = nil
local selectedJobProps = nil

local function BuildJobPropsMenu(jobName, propsList)
    selectedJobName = jobName
    selectedJobProps = propsList

    StaffMenu.jobsPropsJob.ClearItems()

    if not propsList or #propsList == 0 then
        StaffMenu.jobsPropsJob.Separator("Aucun prop actif pour ce métier")
        return
    end

    StaffMenu.jobsPropsJob.Separator((#propsList > 1 and ":box: %d props actifs" or ":box: %d prop actif"):format(#propsList))

    for _, prop in ipairs(propsList) do
        local label = ("%s posé à %s"):format(prop.model, formatTime(prop.placedAt))
        local desc  = ("Par: %s | %s"):format(prop.ownerName, formatCoords(prop.coords))

        StaffMenu.jobsPropsJob.Button(label, desc, nil, "chevron", false, function()
            StaffMenu.data.selectedJobProp = prop
        end, StaffMenu.jobsPropsProp)
    end
end

-- ============================================================
-- Rebuild du menu de détail d'un prop
-- ============================================================

local function BuildPropDetailMenu()
    StaffMenu.jobsPropsProp.ClearItems()

    local prop = StaffMenu.data.selectedJobProp
    if not prop then
        StaffMenu.jobsPropsProp.Separator("Aucun prop sélectionné")
        return
    end

    -- Infos
    StaffMenu.jobsPropsProp.Separator(":report: INFORMATIONS")
    StaffMenu.jobsPropsProp.Button("Modèle : " .. prop.model,      nil, nil, nil, true, function() end)
    StaffMenu.jobsPropsProp.Button("Posé par : " .. prop.ownerName, nil, nil, nil, true, function() end)
    StaffMenu.jobsPropsProp.Button("Heure : " .. formatTime(prop.placedAt), nil, nil, nil, true, function() end)
    StaffMenu.jobsPropsProp.Button("Coords : " .. formatCoords(prop.coords), nil, nil, nil, true, function() end)

    -- Actions
    StaffMenu.jobsPropsProp.Separator(":bolt: ACTIONS")

    -- Téléporter au prop
    StaffMenu.jobsPropsProp.Button(":rocket: SE TÉLÉPORTER", "Aller aux coordonnées du prop", nil, "chevron", not prop.coords, function()
        if not prop.coords then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Props Métier', message = "Coordonnées indisponibles." })
            return
        end
        SetEntityCoords(PlayerPedId(), prop.coords.x, prop.coords.y, prop.coords.z + 0.5, false, false, false, false)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Props Métier', message = "Téléporté au prop." })
        StaffMenu.jobsPropsProp.close()
        StaffMenu.jobsPropsJob.open()
    end)

    -- Supprimer le prop
    StaffMenu.jobsPropsProp.Button(":trash: SUPPRIMER", "Forcer la suppression de ce prop", nil, "chevron", false, function()
        TriggerServerEvent('jobsPropsMenu:staff:forceRemove', prop.netId)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Props Métier', message = "Prop supprimé." })
        StaffMenu.data.selectedJobProp = nil
        StaffMenu.jobsPropsProp.close()
        StaffMenu.jobsPropsJob.open()
    end)
end

-- ============================================================
-- Rebuild du menu principal (liste des métiers)
-- ============================================================

local function BuildJobsPropsMenu()
    StaffMenu.jobsPropsMain.ClearItems()

    local byJob = TriggerServerCallback('jobsPropsMenu:staff:getAll')

    if not byJob or not next(byJob) then
        StaffMenu.jobsPropsMain.Separator("Aucun prop métier actif sur le serveur")
        return
    end

    local total = 0
    for _, props in pairs(byJob) do total = total + #props end

    StaffMenu.jobsPropsMain.Separator((":wrench: %d métier%s, %d prop%s au total"):format(0, "", total, total > 1 and "s" or ""))

    local jobCount = 0
    for jobName, props in pairs(byJob) do
        jobCount = jobCount + 1
    end

    -- Mettre à jour le header avec le vrai compte
    StaffMenu.jobsPropsMain.ClearItems()
    StaffMenu.jobsPropsMain.Separator((":wrench: %d métier%s, %d prop%s au total"):format(jobCount, jobCount > 1 and "s" or "", total, total > 1 and "s" or ""))
    for jobName, props in pairs(byJob) do
        local jobLabel = props.label or jobName
        local label = (":briefcase: %s  [%d]"):format(jobLabel, #props)
        StaffMenu.jobsPropsMain.Button(label, ("Voir les %d props actifs"):format(#props), nil, "chevron", false, function()
            BuildJobPropsMenu(jobName, props)
        end, StaffMenu.jobsPropsJob)
    end
end

-- ============================================================
-- OnOpen handlers
-- ============================================================

StaffMenu.jobsPropsMain.OnOpen(function()
    BuildJobsPropsMenu()
end)

StaffMenu.jobsPropsJob.OnOpen(function()
    BuildJobPropsMenu(selectedJobName, selectedJobProps)
end)

StaffMenu.jobsPropsProp.OnOpen(function()
    BuildPropDetailMenu()
end)
