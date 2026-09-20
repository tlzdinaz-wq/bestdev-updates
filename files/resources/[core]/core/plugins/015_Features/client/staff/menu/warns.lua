---@meta _
---@diagnostic disable: duplicate-doc-field

local sanctionQuery = nil

-- Icons and labels for each sanction type
local sanctionConfig = {
    warn = { icon = ":warning:", label = "Warn", color = "#f59e0b" },
    kick = { icon = ":user:", label = "Kick", color = "#ef4444" },
    ban = { icon = ":hammer:", label = "Ban", color = "#dc2626" },
    tig = { icon = ":pickaxe:", label = "TIG", color = "#22c55e" },
    tigweapon = { icon = ":gun:", label = "TIG Arme", color = "#8b5cf6" }
}

--- .BuildPlayerSanctionsMenu
---@return any
function StaffMenu.BuildPlayerSanctionsMenu()
    local selected = StaffMenu.data.selectedPlayer
    local info = StaffMenu.data.playerInfo or {}
    if selected and StaffMenu._sanctionsFor ~= selected then
        StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
            selected, info.identifier, info.discord) or {}
        StaffMenu._sanctionsFor = selected
    end

    local firstLabel = sanctionQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = sanctionQuery == nil and "UNE SANCTION" or sanctionQuery

    StaffMenu.playerSanctions.Button(firstLabel, lastLabel, nil, "search", false, function()
        if sanctionQuery ~= nil then
            sanctionQuery = nil
            StaffMenu.playerSanctions.refresh()
            return
        end

        sanctionQuery = VFW.Nui.KeyboardInput(true, "Entrez un ID de sanction")
        if sanctionQuery == nil or sanctionQuery == "" then
            sanctionQuery = nil
            return
        end

        StaffMenu.playerSanctions.refresh()
    end)

    StaffMenu.playerSanctions.Separator(nil)

    if StaffMenu.data.sanctionsPlayerList then
        local hasResults = false

        for _, sanction in pairs(StaffMenu.data.sanctionsPlayerList) do
            local matchesQuery = sanctionQuery == nil or
                (sanction.id and tostring(sanction.id):find(sanctionQuery, 1, true))

            if matchesQuery then
                hasResults = true
                local config = sanctionConfig[sanction.type] or { icon = ":question:", label = "?", color = "#888" }
                local leftLabel = config.icon .. " " .. config.label
                local rightLabel = tostring(sanction.id)

                -- Add status indicator
                if sanction.active then
                    leftLabel = leftLabel .. " :dot-green:"
              else
                    leftLabel = leftLabel .. " :dot-grey:"
              end

                -- Determine action based on type
                local canRemove = sanction.type == "warn"
              local canRevoke = (sanction.type == "ban" or sanction.type == "tig" or sanction.type == "tigweapon") and sanction.active
                local isReadOnly = sanction.type == "kick" or
                    (sanction.type == "ban" and not sanction.active) or
                    (sanction.type == "tig" and not sanction.active) or
                    (sanction.type == "tigweapon" and not sanction.active)

                StaffMenu.playerSanctions.Button(leftLabel, rightLabel, nil, "chevron", false, function()
                    -- Create sub-menu for this sanction
                    local sanctionTitle = string.format("%s #%s", config.label, sanction.id)
                    local adminBanner = exports["core"]:GetVUIBanner("admin")

                    if not StaffMenu.sanctionDetail then
                        StaffMenu.sanctionDetail = exports["VUI"]:CreateSubMenu(StaffMenu.playerSanctions, sanctionTitle, adminBanner, true)
                    else
                        StaffMenu.sanctionDetail.title = sanctionTitle
                    end

                    StaffMenu.sanctionDetail.OnOpen(function()
                        StaffMenu.sanctionDetail.ClearItems()

                        -- Details section
                        StaffMenu.sanctionDetail.Separator("DÉTAILS")

                        local reasonText = sanction.reason or "N/A"
                      if #reasonText > 50 then
                            reasonText = reasonText:sub(1, 47) .. "..."
                      end
                        StaffMenu.sanctionDetail.Button("Raison", reasonText, nil, "chevron", true, function() end)
                        StaffMenu.sanctionDetail.Button("Par", sanction.issuedBy or sanction.by or "Système", nil, "chevron", true, function() end)
                        StaffMenu.sanctionDetail.Button("Date", sanction.issuedAtFormatted or sanction.at or "N/A", nil, "chevron", true, function() end)

                        -- Show duration chevron for ban/tig/tigweapon
                        if sanction.type == "ban" and sanction.expiresAt then
                            StaffMenu.sanctionDetail.Button("Expire", sanction.expiresAtFormatted or sanction.expiresAt, nil, "chevron", true, function() end)
                        elseif sanction.type == "ban" and sanction.active then
                            StaffMenu.sanctionDetail.Button("Durée", "Permanent", nil, "chevron", true, function() end)
                        elseif sanction.type == "tigweapon" and sanction.expiresAt then
                            StaffMenu.sanctionDetail.Button("Expire", sanction.expiresAtFormatted or sanction.expiresAt, nil, "chevron", true, function() end)
                        end

                        -- Actions section
                        StaffMenu.sanctionDetail.Separator("ACTIONS")

                        -- Modify options (if permission)
                        local canModify = VFW.PlayerGlobalData.permissions["modify_sanctions"]
                        if canModify and (sanction.type == "warn" or sanction.type == "ban" or sanction.type == "tig" or sanction.type == "tigweapon") then
                            StaffMenu.sanctionDetail.Button("Modifier la raison", "Changer la raison de la sanction affichée au joueur", nil, "chevron", false, function()
                                local newReason = VFW.Nui.KeyboardInput(true, "Nouvelle raison", sanction.reason or "")
                                if newReason and newReason ~= "" then
                                    local result = TriggerServerCallback("vfw:staff:modifySanctionReason", sanction.id, sanction.type, newReason)
                                    if result then
                                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Avertissements', message = "Raison modifiée." })
                                        sanction.reason = newReason
                                        StaffMenu.sanctionDetail.close()
                                        sanctionQuery = nil
                                        StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                                            StaffMenu.data.selectedPlayer, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
                                        StaffMenu.playerSanctions.refresh()
                                    else
                                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Erreur lors de la modification." })
                                    end
                                end
                            end)

                            -- Modify duration for active ban/tig/tigweapon
                            if (sanction.type == "ban" or sanction.type == "tig" or sanction.type == "tigweapon") and sanction.active then
                                StaffMenu.sanctionDetail.Button("Modifier la durée", "Changer la durée en heures (-1 = permanent, 0 = lever immédiatement)", nil, "chevron", false, function()
                                    local durationStr = VFW.Nui.KeyboardInput(true, "Nouvelle durée en heures (-1 = permanent)")
                                    if durationStr then
                                        local durationHours = tonumber(durationStr)
                                        if durationHours then
                                            local durationSeconds = durationHours == -1 and -1 or (durationHours * 3600)
                                            local result = TriggerServerCallback("vfw:staff:modifySanctionDuration", sanction.id, sanction.type, durationSeconds)
                                            if result then
                                                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Avertissements', message = "Durée modifiée." })
                                                StaffMenu.sanctionDetail.close()
                                                sanctionQuery = nil
                                                StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                                                    StaffMenu.data.selectedPlayer, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
                                                StaffMenu.playerSanctions.refresh()
                                            else
                                                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Erreur lors de la modification." })
                                            end
                                        else
                                            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Cette durée n'est pas valide." })
                                        end
                                    end
                                end)
                            end
                        end

                        -- Delete/Revoke options
                        if canRemove then
                            StaffMenu.sanctionDetail.Button("Supprimer le warn", "Supprimer définitivement cet avertissement de la base de données", nil, "arrow", false, function()
                                local result = TriggerServerCallback("vfw:staff:removeWarn", sanction.id)
                                if result then
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Avertissements', message = "Warn supprimé." })
                                else
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Erreur lors de la suppression." })
                                end
                                StaffMenu.sanctionDetail.close()
                                sanctionQuery = nil
                                StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                                    StaffMenu.data.selectedPlayer, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
                                StaffMenu.playerSanctions.refresh()
                            end)
                        elseif canRevoke and sanction.type == "ban" then
                            StaffMenu.sanctionDetail.Button("Révoquer le ban", "Lever le ban immédiatement, le joueur pourra se reconnecter", nil, "arrow", false, function()
                                local result = TriggerServerCallback("vfw:staff:revokeBan", sanction.id)
                                if result then
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Avertissements', message = "Ban révoqué." })
                                else
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Erreur lors de la révocation." })
                                end
                                StaffMenu.sanctionDetail.close()
                                sanctionQuery = nil
                                StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                                    StaffMenu.data.selectedPlayer, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
                                StaffMenu.playerSanctions.refresh()
                            end)
                        elseif canRevoke and sanction.type == "tig" then
                            StaffMenu.sanctionDetail.Button("Révoquer le TIG", "Lever le TIG immédiatement, le joueur retrouve son accès au travail", nil, "arrow", false, function()
                                local result = TriggerServerCallback("vfw:staff:revokeTIG", sanction.id)
                                if result then
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Avertissements', message = "TIG révoqué." })
                                else
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Erreur lors de la révocation." })
                                end
                                StaffMenu.sanctionDetail.close()
                                sanctionQuery = nil
                                StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                                    StaffMenu.data.selectedPlayer, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
                                StaffMenu.playerSanctions.refresh()
                            end)
                        elseif canRevoke and sanction.type == "tigweapon" then
                            StaffMenu.sanctionDetail.Button("Révoquer le TIG Arme", "Lever le TIG Arme, le joueur récupère l'accès à ses armes de métier", nil, "arrow", false, function()
                                local result = TriggerServerCallback("vfw:staff:revokeSanction", sanction.id)
                                if result then
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Avertissements', message = "TIG Arme révoqué." })
                                else
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Avertissements', message = "Erreur lors de la révocation." })
                                end
                                StaffMenu.sanctionDetail.close()
                                sanctionQuery = nil
                                StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
                                    StaffMenu.data.selectedPlayer, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
                                StaffMenu.playerSanctions.refresh()
                            end)
                        elseif isReadOnly then
                            StaffMenu.sanctionDetail.Button("Lecture seule", "Aucune action disponible", nil, "chevron", true, function() end)
                        end
                    end)

                    StaffMenu.sanctionDetail.open()
                end)
            end
        end

        if not hasResults then
            StaffMenu.playerSanctions.Textbox("Aucune sanction trouvée", "Info")
        end
    else
        StaffMenu.playerSanctions.Textbox("Aucune sanction pour ce joueur", "Info")
    end
end
