---@meta _
---@diagnostic disable: duplicate-doc-field

-- Variables de flow pour la gestion du poids
local pendingWeight = nil -- { targetId, weight, characterIdentifier, characters }

function StaffMenu.BuildWeightManagementMenu()
    StaffMenu.weightManagement.ClearItems()

    -- Bouton pour donner un poids
    StaffMenu.weightManagement.Button(":plus: DONNER UN POIDS", "Définir un poids personnalisé", nil, "chevron", false, function()
        local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
        if not playerId or playerId == "" then return end
        playerId = tonumber(playerId)
        if not playerId then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Poids', message = "Cet identifiant n'est pas valide" })
            return
        end

        local weight = VFW.Nui.KeyboardInput(true, "Poids en kg (ex: 100)")
        if not weight or weight == "" then return end
        weight = tonumber(weight)
        if not weight or weight <= 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Poids', message = "Ce poids n'est pas valide" })
            return
        end

        -- Récupérer les personnages du joueur cible
        local characters = TriggerServerCallback("vfw:staff:getPlayerCharacters", playerId)
        if not characters or #characters == 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Poids', message = "Joueur introuvable" })
            return
        end

        if #characters == 1 then
            -- Un seul personnage → passer directement à la durée
            pendingWeight = {
                targetId = playerId,
                weight = weight,
                characterIdentifier = characters[1].identifier,
                characters = characters
            }
            StaffMenu.weightManagement.close()
            Wait(100)
            StaffMenu.weightDuration.open()
        else
            -- Plusieurs personnages → menu de sélection
            pendingWeight = {
                targetId = playerId,
                weight = weight,
                characterIdentifier = nil,
                characters = characters
            }
            StaffMenu.weightManagement.close()
            Wait(100)
            StaffMenu.weightCharSelect.open()
        end
    end)

    StaffMenu.weightManagement.Separator("~ Joueurs avec poids modifié ~")

    -- Récupérer la liste des joueurs modifiés
    local modifiedPlayers = TriggerServerCallback("vfw:staff:getModifiedWeights") or {}

    if #modifiedPlayers == 0 then
        StaffMenu.weightManagement.Button("Aucun joueur", "Aucun joueur avec poids modifié", nil, nil, true, function() end)
    else
        for _, player in ipairs(modifiedPlayers) do
            local statusIcon = ""
          if player.durationType == "session" then
                statusIcon = "[Session] "
          elseif player.durationType == "days" then
                statusIcon = "[Jours] "
          elseif player.durationType == "permanent" then
                statusIcon = "[Permanent] "
          end

            local nameLabel = player.name
            if player.online then
                nameLabel = nameLabel .. " (ID: " .. player.id .. ")"
          else
                nameLabel = nameLabel .. " (Hors-ligne)"
          end

            local desc = "Poids: " .. player.weight .. " kg | " .. statusIcon .. (player.remainingText or "")

            StaffMenu.weightManagement.Button(
                nameLabel,
                desc,
                nil,
                "chevron",
                false,
                function()
                    local choice = VFW.Nui.KeyboardInput(true, "1 = Modifier, 2 = Retirer")

                    if choice == "1" then
                        local newWeight = VFW.Nui.KeyboardInput(true, "Nouveau poids en kg")
                        if newWeight and tonumber(newWeight) and tonumber(newWeight) > 0 then
                            -- Réutiliser le flow de durée pour la modification
                            pendingWeight = {
                                targetId = player.id,
                                weight = tonumber(newWeight),
                                characterIdentifier = player.identifier,
                                characters = nil
                            }
                            StaffMenu.weightManagement.close()
                            Wait(100)
                            StaffMenu.weightDuration.open()
                            return
                        end
                    elseif choice == "2" then
                        TriggerServerEvent("vfw:staff:resetPlayerWeight", player.id, player.identifier)
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Poids', message = "Poids retiré" })
                    end

                    Wait(100)
                    StaffMenu.BuildWeightManagementMenu()
                end
            )
        end
    end
end

function StaffMenu.BuildWeightCharSelectMenu()
    StaffMenu.weightCharSelect.ClearItems()

    if not pendingWeight or not pendingWeight.characters then
        StaffMenu.weightCharSelect.Button("Erreur", "Aucun personnage disponible", nil, nil, true, function() end)
        return
    end

    for _, char in ipairs(pendingWeight.characters) do
        local label = "Personnage " .. char.slot .. " - " .. char.name
        StaffMenu.weightCharSelect.Button(
            label,
            "Sélectionner ce personnage",
            nil,
            "chevron",
            false,
            function()
                pendingWeight.characterIdentifier = char.identifier
                StaffMenu.weightCharSelect.close()
                Wait(100)
                StaffMenu.weightDuration.open()
            end
        )
    end
end

function StaffMenu.BuildWeightDurationMenu()
    StaffMenu.weightDuration.ClearItems()

    if not pendingWeight then
        StaffMenu.weightDuration.Button("Erreur", "Aucune donnée en attente", nil, nil, true, function() end)
        return
    end

    StaffMenu.weightDuration.Button("JUSQU'À LA DÉCO", "Le poids sera perdu à la déconnexion", nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:setPlayerWeight", pendingWeight.targetId, pendingWeight.weight, "session", nil, pendingWeight.characterIdentifier)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Poids', message = "Poids de " .. pendingWeight.weight .. " kg appliqué (session)" })
        pendingWeight = nil
        StaffMenu.weightDuration.close()
        Wait(100)
        StaffMenu.weightManagement.open()
    end)

    StaffMenu.weightDuration.Button("NOMBRE DE JOURS", "Définir une durée en jours", nil, "chevron", false, function()
        local daysInput = VFW.Nui.KeyboardInput(true, "Nombre de jours")
        if not daysInput or daysInput == "" then return end
        local numDays = tonumber(daysInput)
        if not numDays or numDays <= 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Poids', message = "Ce nombre de jours n'est pas valide" })
            return
        end

        TriggerServerEvent("vfw:staff:setPlayerWeight", pendingWeight.targetId, pendingWeight.weight, "days", numDays, pendingWeight.characterIdentifier)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Poids', message = "Poids de " .. pendingWeight.weight .. " kg appliqué pour " .. numDays .. (numDays > 1 and " jours" or " jour") })
        pendingWeight = nil
        StaffMenu.weightDuration.close()
        Wait(100)
        StaffMenu.weightManagement.open()
    end)

    StaffMenu.weightDuration.Button("PERMANENT", "Le poids restera indéfiniment", nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:setPlayerWeight", pendingWeight.targetId, pendingWeight.weight, "permanent", nil, pendingWeight.characterIdentifier)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Poids', message = "Poids de " .. pendingWeight.weight .. " kg appliqué (permanent)" })
        pendingWeight = nil
        StaffMenu.weightDuration.close()
        Wait(100)
        StaffMenu.weightManagement.open()
    end)
end
