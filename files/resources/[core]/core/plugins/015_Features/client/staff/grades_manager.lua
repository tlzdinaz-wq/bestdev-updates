---@meta _
---@diagnostic disable: duplicate-doc-field

-- Staff Grades Manager UI
local gradesManagerOpen = false
local currentFaction = nil

-- ─── Open ─────────────────────────────────────────────────────────────────────

function StaffMenu.OpenGradesManager(factionName)
    if not factionName then return end

    local data = TriggerServerCallback("vfw:staff:grades:getData", factionName)
    if not data then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion des grades',
            message = "Faction introuvable."
      })
        return
    end

    gradesManagerOpen = true
    currentFaction = data.faction

    VFW.Nui.Visible(true)

    SendNUIMessage({
        action = "staff:grades:open",
        data = {
            visible = true,
            faction = data.faction,
            grades = data.grades,
        }
    })

    VFW.Nui.Focus(true, false)
end

-- ─── Close ────────────────────────────────────────────────────────────────────

function StaffMenu.CloseGradesManager()
    if not gradesManagerOpen then return end

    gradesManagerOpen = false
    currentFaction = nil

    SendNUIMessage({ action = "staff:grades:close" })
    VFW.Nui.Focus(false, false)
end

-- ─── NUI Callbacks ────────────────────────────────────────────────────────────

RegisterNUICallback("staff:grades:close", function(data, cb)
    cb("ok")
    gradesManagerOpen = false
    currentFaction = nil
    VFW.Nui.Focus(false)
end)

-- Créer un grade
RegisterNUICallback("staff:grades:createGrade", function(data, cb)
    if not currentFaction then cb({ success = false }) return end

    local result = TriggerServerCallback("vfw:staff:grades:createGrade", {
        factionName = data.factionName,
        gradeName   = data.gradeName,
    })

    VFW.Nui.Focus(true)

    if result and result.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion des grades',
            message = "Grade créé."
      })
        cb({ success = true, grade = result.grade })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion des grades',
            message = result and result.error or "Erreur lors de la création."
      })
        cb({ success = false })
    end
end)

-- Renommer un grade
RegisterNUICallback("staff:grades:renameGrade", function(data, cb)
    if not currentFaction then cb({ success = false }) return end

    local result = TriggerServerCallback("vfw:staff:grades:renameGrade", {
        factionName = data.factionName,
        gradeLevel  = data.gradeLevel,
        newName     = data.newName,
    })

    VFW.Nui.Focus(true)

    if result and result.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion des grades',
            message = "Grade renommé."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion des grades',
            message = result and result.error or "Erreur lors du renommage."
      })
        cb({ success = false })
    end
end)

-- Supprimer un grade
RegisterNUICallback("staff:grades:deleteGrade", function(data, cb)
    if not currentFaction then cb({ success = false }) return end

    local result = TriggerServerCallback("vfw:staff:grades:deleteGrade", {
        factionName = data.factionName,
        gradeLevel  = data.gradeLevel,
    })

    VFW.Nui.Focus(true)

    if result and result.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion des grades',
            message = "Grade supprimé."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion des grades',
            message = result and result.error or "Erreur lors de la suppression."
      })
        cb({ success = false })
    end
end)

-- Swap de grades (drag & drop)
RegisterNUICallback("staff:grades:swapGrades", function(data, cb)
    if not currentFaction then cb({ success = false }) return end

    local result = TriggerServerCallback("vfw:staff:grades:swapGrades", {
        factionName = data.factionName,
        levelA      = data.levelA,
        levelB      = data.levelB,
    })

    VFW.Nui.Focus(true)

    if result and result.success then
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion des grades',
            message = "Erreur lors de la réorganisation."
      })
        cb({ success = false })
    end
end)

-- Mettre à jour les permissions d'un grade
RegisterNUICallback("staff:grades:updatePermissions", function(data, cb)
    if not currentFaction then cb({ success = false }) return end

    local result = TriggerServerCallback("vfw:staff:grades:updatePermissions", {
        factionName = data.factionName,
        gradeLevel  = data.gradeLevel,
        permissions = data.permissions,
    })

    VFW.Nui.Focus(true)

    if result and result.success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion des grades',
            message = "Permissions sauvegardées."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion des grades',
            message = "Erreur lors de la sauvegarde."
      })
        cb({ success = false })
    end
end)

-- ─── Export ───────────────────────────────────────────────────────────────────

exports("OpenGradesManager", StaffMenu.OpenGradesManager)
exports("CloseGradesManager", StaffMenu.CloseGradesManager)
