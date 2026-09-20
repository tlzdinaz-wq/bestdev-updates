---@meta _
---@diagnostic disable: duplicate-doc-field

-- Modern Sanctions UI System
local sanctionsOpen = false
local currentTargetPlayer = nil

-- Open Sanctions UI for a specific player
function StaffMenu.OpenSanctionsUI(targetPlayer)
    if not targetPlayer then
        return
    end

    sanctionsOpen = true
    currentTargetPlayer = targetPlayer

    -- Get player sanctions history
    local sanctions = TriggerServerCallback("vfw:staff:getSanctions", targetPlayer.source, targetPlayer.id)

    -- Ensure sanctions is always a table
    if not sanctions then
        sanctions = {}
    end

    -- Ensure NUI is visible before opening sanctions UI
    VFW.Nui.Visible(true)

    -- Send data to UI
    local perms = VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions or {}
    SendNUIMessage({
        action = "staff:sanctions:open",
        data = {
            visible = true,
            targetPlayer = {
                id = targetPlayer.id,
                source = targetPlayer.source,
                name = targetPlayer.name,
                identifier = targetPlayer.identifier,
                discord = targetPlayer.discord,
                online = targetPlayer.online or false
            },
            sanctions = sanctions,
            permissions = {
                sanctions = perms["sanctions"] or false,
                modify_sanctions = perms["modify_sanctions"] or false
            }
        }
    })

    -- Set NUI focus
    VFW.Nui.Focus(true, false)
end

-- Close Sanctions UI
function StaffMenu.CloseSanctionsUI()
    if not sanctionsOpen then return end

    sanctionsOpen = false
    currentTargetPlayer = nil

    SendNUIMessage({
        action = "staff:sanctions:close"
  })

    -- Force release NUI focus
    VFW.Nui.Focus(false, false)
end

-- NUI Callbacks
RegisterNUICallback("staff:sanctions:closed", function(data, cb)
    cb("ok")

    sanctionsOpen = false
    currentTargetPlayer = nil

    -- Force release NUI focus
    VFW.Nui.Focus(false)
end)

-- Apply sanction callback
RegisterNUICallback("staff:sanctions:apply", function(data, cb)
    if not currentTargetPlayer then
        cb({ success = false, error = "No target player" })
        return
    end

    local sanctionData = {
        targetId = data.playerId,
        globalId = data.globalId,
        type = data.type,
        reason = data.reason,
        duration = data.duration,
        durationType = data.durationType,
        tigTasks = data.tigTasks,
        displayMode = data.displayMode or "visual"
  }

    local success = TriggerServerCallback("vfw:staff:applySanction", sanctionData)

    -- Re-establish NUI focus after server callback (fixes focus loss issue)
    VFW.Nui.Focus(true)

    if success then
        -- Show notification
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sanctions Joueurs',
            message = "Sanction appliquée."
      })

        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
            message = "Erreur lors de l'application de la sanction."
      })

        cb({ success = false })
    end
end)

-- Revoke sanction callback
RegisterNUICallback("staff:sanctions:revoke", function(data, cb)
    local success = TriggerServerCallback("vfw:staff:revokeSanction", data.sanctionId)

    -- Re-establish NUI focus after server callback (fixes focus loss issue)
    VFW.Nui.Focus(true)

    if success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sanctions Joueurs',
            message = "Sanction révoquée."
      })

        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
            message = "Erreur lors de la révocation de la sanction."
      })

        cb({ success = false })
    end
end)

-- Get updated sanctions list
RegisterNUICallback("staff:sanctions:getSanctions", function(data, cb)
    local sanctions = TriggerServerCallback("vfw:staff:getSanctions", data.playerId, data.globalId) or {}
    VFW.Nui.Focus(true)
    cb(sanctions)
end)

-- Modify sanction reason callback
RegisterNUICallback("staff:sanctions:modifyReason", function(data, cb)
    local success = TriggerServerCallback("vfw:staff:modifySanctionReason", data.sanctionId, data.sanctionType, data.newReason)
    VFW.Nui.Focus(true)

    if success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sanctions Joueurs',
            message = "Raison modifiée."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
            message = "Erreur lors de la modification (permission insuffisante ?)."
      })
        cb({ success = false })
    end
end)

-- Modify sanction duration callback (ban/tig/tigweapon)
RegisterNUICallback("staff:sanctions:modifyDuration", function(data, cb)
    local success = TriggerServerCallback("vfw:staff:modifySanctionDuration", data.sanctionId, data.sanctionType, data.newDuration)
    VFW.Nui.Focus(true)

    if success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sanctions Joueurs',
            message = "Durée modifiée."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
            message = "Erreur lors de la modification (permission insuffisante ?)."
      })
        cb({ success = false })
    end
end)

-- Delete warn callback
RegisterNUICallback("staff:sanctions:deleteWarn", function(data, cb)
    local success = TriggerServerCallback("vfw:staff:removeWarn", data.sanctionId)
    VFW.Nui.Focus(true)

    if success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sanctions Joueurs',
            message = "Warn supprimé."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
            message = "Erreur lors de la suppression."
      })
        cb({ success = false })
    end
end)

-- Delete ban callback (revokes it immediately)
RegisterNUICallback("staff:sanctions:deleteBan", function(data, cb)
    local success = TriggerServerCallback("vfw:staff:revokeBan", data.sanctionId)
    VFW.Nui.Focus(true)

    if success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Sanctions Joueurs',
            message = "Ban supprimé."
      })
        cb({ success = true })
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
            message = "Erreur lors de la suppression."
      })
        cb({ success = false })
    end
end)

-- Update the BuildSanctionsMenu to use the new UI
function StaffMenu.BuildSanctionsMenu()
    StaffMenu.sanctions.Button("OUVRIR L'INTERFACE SANCTIONS", nil, nil, "arrow", false, function()
        -- Get selected player from context (you'll need to pass this from the player menu)
        if StaffMenu.data.selectPlayer then
            StaffMenu.sanctions.close()
            StaffMenu.OpenSanctionsUI(StaffMenu.data.selectPlayer)
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
                message = "Aucun joueur sélectionné."
          })
        end
    end)

    StaffMenu.sanctions.Separator("~y~RACCOURCIS RAPIDES")

    StaffMenu.sanctions.Button("WARN RAPIDE", nil, nil, "arrow", false, function()
        if not StaffMenu.data.selectPlayer then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
                message = "Aucun joueur sélectionné."
          })
            return
        end

        local reason = VFW.Nui.KeyboardInput(true, "Raison du warn")
        if reason and reason ~= "" then
            local choice = VFW.Nui.ChoiceInput("Mode d'affichage", "Choisissez le type d'avertissement", {
                { label = "Avertissement Visuel", value = "visual", icon = ":monitor:" },
                { label = "Message Chat", value = "chat", icon = ":chat:" }
            })
            if not choice then return end
            local showVisual = choice == "visual"
          TriggerServerEvent("vfw:staff:quickWarn", StaffMenu.data.selectPlayer.source, reason, showVisual)
        end
    end)

    StaffMenu.sanctions.Button("KICK RAPIDE", nil, nil, "arrow", false, function()
        if not StaffMenu.data.selectPlayer then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions Joueurs',
                message = "Aucun joueur sélectionné."
          })
            return
        end

        local reason = VFW.Nui.KeyboardInput(true, "Raison du kick")
        if reason and reason ~= "" then
            TriggerServerEvent("vfw:staff:quickKick", StaffMenu.data.selectPlayer.source, reason)
        end
    end)
end

-- Real-time permissions update: push new perms to NUI if sanctions UI is open
AddEventHandler('vfw:updatePlayerGlobalData', function(data)
    if not sanctionsOpen then return end
    local perms = data and data.permissions or {}
    SendNUIMessage({
        action = "staff:sanctions:permissions",
        data = {
            sanctions = perms["sanctions"] or false,
            modify_sanctions = perms["modify_sanctions"] or false
        }
    })
end)

-- Export the functions for use in other files
exports("OpenSanctionsUI", StaffMenu.OpenSanctionsUI)
exports("CloseSanctionsUI", StaffMenu.CloseSanctionsUI)