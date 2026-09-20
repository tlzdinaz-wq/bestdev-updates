---@meta _
---@diagnostic disable: duplicate-doc-field


local outils = {
    indexBan = 1,
    Spectate = false,
    showCoords = false,
    hideMyTag = false
}

-- Expose shared state for cross-file access (personal_actions.lua)
StaffMenu.outilsState = outils

-- Fonction pour nettoyer les caracteres d'echappement couleur (~r~, ~g~, ~b~, etc.)
function stripColorCodes(text)
    if not text then
        return nil
    end
    -- Retire les patterns ~X~ ou ~XX~ (codes couleur FiveM)
    return text:gsub("~%a+~", "")
end

-- Fonction globale pour reinitialiser l'etat spectate (appele depuis StaffMenu.StopSpectate)
function StaffMenu.ResetOutilsSpectate()
    outils.Spectate = false
    -- Rafraichir le menu outils s'il est ouvert
    if StaffMenu.outils and StaffMenu.outils.refresh then
        pcall(function()
            StaffMenu.outils.refresh()
        end)
    end
end

StaffMenu.LastPlayerource = nil
StaffMenu.showRPNamesOnPlayerTags = false
-- Load tag preference from KVP
local savedTagState = GetResourceKvpString("staff_gamer_tags")
local initialTagState = savedTagState == "true"

function StaffMenu.BuildFarmMenu()
    local FarmConfigs = TriggerServerCallback("core:farm:getConfigs") or {}

    for societyName, config in pairs(FarmConfigs) do
        StaffMenu.builderFarm.Button(("Job %s"):format(societyName), nil, nil, "chevron", false, function()
            StaffMenu.builderFarmOptions.currentConfig = {
                societyName = societyName,
                config = config,
            }
        end, StaffMenu.builderFarmOptions)
    end
end

function StaffMenu.BuildFarmOptionsMenu()
    local societyName = StaffMenu.builderFarmOptions.currentConfig.societyName
    local config = StaffMenu.builderFarmOptions.currentConfig.config

    StaffMenu.builderFarmOptions.Separator((":user::leaf: Options de %s"):format(societyName))

    StaffMenu.builderFarmOptions.Button("Se téléporter au PNJ", "Vous téléporte au PNJ", nil, "chevron", false, function()
        if not config.ped_coords or not config.ped_coords.x or tonumber(config.ped_coords.x) == 0.0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Builder Farm', message = "Aucune position de PNJ définie pour ce job." })
            return
        end
        SetEntityCoords(PlayerPedId(), config.ped_coords.x, config.ped_coords.y, config.ped_coords.z)
    end)

    -- Button to update Ped Position
    StaffMenu.builderFarmOptions.Button("Mettre à jour la position du PNJ", "Met a jour la position du PNJ du job.", nil, "chevron", false, function()

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        -- GetEntityCoords returns position at ped center (waist), subtract 1.0 to get ground level
        local newPedPos = { x = coords.x, y = coords.y, z = coords.z - 1.0, heading = heading }

        -- Update on server
        TriggerServerEvent("core:farm:updatePedPosition", societyName, newPedPos)

        -- Update local config
        config.ped_coords = newPedPos
    end)

    -- Section zones dynamiques (uniquement pour les bars)
    if config.is_bar then
        StaffMenu.builderFarmOptions.Separator(":pin: Zone de récolte")

        local harvestInfo = config.harvest_zone
        if harvestInfo and harvestInfo.center then
            local defaultTag = harvestInfo.isDefault and " (défaut)" or " (custom)"
          StaffMenu.builderFarmOptions.Button(
                ("Centre: %.1f, %.1f, %.1f"):format(harvestInfo.center.x, harvestInfo.center.y, harvestInfo.center.z),
                ("Radius: %.1f%s"):format(harvestInfo.radius, defaultTag),
                nil, nil, true, function() end
            )
        end

        StaffMenu.builderFarmOptions.Button("Se TP à la zone de récolte", nil, nil, "chevron", false, function()
            if harvestInfo and harvestInfo.center then
                SetEntityCoords(PlayerPedId(), harvestInfo.center.x, harvestInfo.center.y, harvestInfo.center.z)
            end
        end)

        StaffMenu.builderFarmOptions.Button("Définir le centre de récolte ici", nil, nil, "chevron", false, function()
            local coords = GetEntityCoords(PlayerPedId())
            local newCenter = { x = coords.x, y = coords.y, z = coords.z }
            local currentRadius = (harvestInfo and harvestInfo.radius) or 30.0
            TriggerServerEvent("core:farm:updateHarvestZone", societyName, newCenter, currentRadius)
            config.harvest_zone = config.harvest_zone or {}
            config.harvest_zone.center = newCenter
            config.harvest_zone.isDefault = false
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = "Centre de récolte mis à jour." })
            StaffMenu.builderFarmOptions.refresh()
        end)

        StaffMenu.builderFarmOptions.Button("Modifier le radius de récolte", nil, nil, "chevron", false, function()
            local currentRadius = (harvestInfo and harvestInfo.radius) or 30.0
            local newRadiusStr = VFW.Nui.KeyboardInput(true, "Nouveau radius de récolte", tostring(currentRadius))
            local newRadius = tonumber(newRadiusStr)
            if newRadius and newRadius > 0 then
                local currentCenter = harvestInfo and harvestInfo.center
                TriggerServerEvent("core:farm:updateHarvestZone", societyName, currentCenter, newRadius)
                config.harvest_zone = config.harvest_zone or {}
                config.harvest_zone.radius = newRadius
                config.harvest_zone.isDefault = false
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = ("Radius de récolte: %.1f"):format(newRadius) })
                StaffMenu.builderFarmOptions.refresh()
            elseif newRadiusStr ~= nil then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce rayon n'est pas valide." })
            end
        end)

        StaffMenu.builderFarmOptions.Separator(":wrench: Point de transformation")

        local processingInfo = config.processing_coords
        if processingInfo then
            StaffMenu.builderFarmOptions.Button(
                ("Position: %.1f, %.1f, %.1f"):format(processingInfo.x, processingInfo.y, processingInfo.z),
                nil, nil, nil, true, function() end
            )
        end

        StaffMenu.builderFarmOptions.Button("Se TP au point de transformation", nil, nil, "chevron", false, function()
            if processingInfo then
                SetEntityCoords(PlayerPedId(), processingInfo.x, processingInfo.y, processingInfo.z)
            end
        end)

        StaffMenu.builderFarmOptions.Button("Définir le point de transformation ici", nil, nil, "chevron", false, function()
            local coords = GetEntityCoords(PlayerPedId())
            local newPos = { x = coords.x, y = coords.y, z = coords.z }
            TriggerServerEvent("core:farm:updateProcessingPosition", societyName, newPos)
            config.processing_coords = newPos
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = "Point de transformation mis à jour." })
            StaffMenu.builderFarmOptions.refresh()
        end)
    end

    StaffMenu.builderFarmOptions.Separator(":money: Prix des items")

    if config.items and next(config.items) then
        for action, itemsArray in pairs(config.items) do
            if action == "process" or action == "processing" then
                for _, itemData in ipairs(itemsArray) do
                    StaffMenu.builderFarmOptions.Button(
                            ("%s: %s"):format(itemData.label, VFW.Math.FormatMoney(itemData.price)),
                            "Cliquer pour modifier le prix",
                            nil,
                            "chevron",
                            false,
                            function()
                                -- Ask for new price
                                local newPriceInput = VFW.Nui.KeyboardInput(true, ("Nouveau prix pour %s"):format(itemData.label), tostring(itemData.price))
                                local newPrice = tonumber(newPriceInput)

                                if newPrice and newPrice >= 0 then
                                    -- Trigger server event to update price
                                    TriggerServerEvent("core:farm:updateItemPrice", societyName, itemData.name, newPrice)

                                    -- Update price locally for immediate feedback
                                    itemData.price = newPrice

                                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = ("Prix de %s mis à jour à %s."):format(itemData.label, VFW.Math.FormatMoney(newPrice)) })

                                    -- Refresh menu
                                    StaffMenu.builderFarmOptions.refresh()
                                elseif newPriceInput ~= nil then
                                    -- Avoid notification on cancel
                                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce prix n'est pas valide." })
                                end
                            end
                    )
                end
            end
        end
    else
        StaffMenu.builderFarmOptions.Button("Aucun item à configurer", nil, nil, nil, true, function()
        end)
    end

    StaffMenu.builderFarmOptions.Separator(":money: Gains de la société")
    StaffMenu.builderFarmOptions.Button("Gain restant pour l'entreprise", "Gain pour l'entreprise en pourcentage", config.society_percent or 0, "chevron", false, function()
        local percent = VFW.Nui.KeyboardInput(true, ("Gain restant pour %s"):format(societyName), tostring(config.society_percent or 0))
        percent = tonumber(percent)

        if percent and percent >= 0 and percent <= 100 then
            TriggerServerEvent("core:farm:updateSocietyPercent",societyName, percent)
            config.society_percent = percent
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = ("Gain restant pour %s: %s%%."):format(societyName, percent) })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce pourcentage n'est pas valide." })
        end
        StaffMenu.builderFarmOptions.refresh()
    end)
end

--- .BuildOutilsMenu
function StaffMenu.BuildOutilsMenu()
    -- NOTE: Ne pas réappliquer l'état KVP ici, ça crée des conflits avec l'animator
    StaffMenu.outils.ClearItems()
    local perms = VFW.StaffPerms()
    if VFW.HasStaffPerm("staff_menu") or VFW.HasStaffPerm("menu_anim") then
        perms = VFW.BuildFullPermissions()
    end

    -- === :home: GESTION ===
    local hasGestion = perms["manage_property"] or perms["manage_job_props"]
    if hasGestion then
        StaffMenu.outils.Separator(":home: GESTION")
    end

    if perms["manage_property"] then
        StaffMenu.outils.Button(":home: GESTION PROPRIÉTÉS", "Connaître la position des propriétés et de les masquer si activées.", nil, "chevron", false, function() end, StaffMenu.builderProperties)
    end

    if perms["manage_job_props"] then
        StaffMenu.outils.Button(":wrench: GESTION PROPS MÉTIER", "Placer et configurer les props liés aux métiers", nil, "chevron", false, function() end, StaffMenu.jobsPropsMain)
    end

    -- === :car: VÉHICULES JOUEUR ===
    if perms["staff_menu"] then
        StaffMenu.outils.Separator(":car: VÉHICULES")

        StaffMenu.outils.Button(":car: VÉHICULE JOUEUR", "Voir les véhicules d'un joueur connecté (ID) ou déconnecté (UUID)", nil, "chevron", false, function()
            local mode = VFW.Nui.ChoiceInput("Type de recherche", "Le joueur est-il connecté ?", {
                { label = "Online (ID session)", value = "online" },
                { label = "Offline (UUID)", value = "offline" },
            })
            if not mode then return end

            local placeholder = mode == "online" and "ID session du joueur" or "UUID du joueur"
          local inputId = VFW.Nui.KeyboardInput(true, placeholder)
            if not inputId or inputId == "" then return end

            local result = TriggerServerCallback("core:server:GetAllVehicleStaff", inputId, mode)
            if not result then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicules', message = "Joueur non trouvé." })
                return
            end

            StaffMenu.data.vehsList = result.vehs or { owned = {}, job = {}, faction = {} }
            StaffMenu.data.playerInfo = result.info or {}
            StaffMenu.data.selectedPlayer = result.info and result.info.source or 0
            StaffMenu.data.vehsLookupMode = true

            StaffMenu.BuildVehsMenu()
            StaffMenu.vehs.open()
        end)
    end

    -- === :scales: SANCTIONS ===
    local hasSanctions = perms["sanctions"] or perms["kick"] or perms["ban"] or perms["ban_offline"] or perms["give_tig"] or perms["remove_tig"]
    if hasSanctions then
        StaffMenu.outils.Separator(":scales: SANCTIONS")
    end

    if perms["sanctions"] then
        StaffMenu.outils.Button(":scales: INTERFACE SANCTION", "Ouvrir l'interface de sanction complète pour un joueur connecté (ID) ou déconnecté (UUID)", nil, "chevron", false, function()
            local mode = VFW.Nui.ChoiceInput("Type de recherche", "Le joueur est-il connecté ?", {
                { label = "Online (ID session)", value = "online" },
                { label = "Offline (UUID)", value = "offline" },
            })
            if not mode then return end

            local placeholder = mode == "online" and "ID session du joueur" or "UUID du joueur"
          local inputId = VFW.Nui.KeyboardInput(true, placeholder)
            if not inputId or inputId == "" then return end

            local playerData = TriggerServerCallback("vfw:staff:resolvePlayerForSanctions", inputId, mode)
            if not playerData then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions', message = "Joueur non trouvé." })
                return
            end

            StaffMenu.outils.close()
            Wait(100)
            StaffMenu.OpenSanctionsUI(playerData)
        end)
    end

    if perms["sanctions"] then
        StaffMenu.outils.Button(":warning: WARN UN JOUEUR", "Envoyer un avertissement officiel à un joueur connecté", nil, "chevron", false, function()
            local inputId = VFW.Nui.KeyboardInput(true, "ID session du joueur")
            if not inputId or inputId == "" then return end

            local reason = VFW.Nui.KeyboardInput(true, "Motif du warn", "")
            if not reason or reason == "" then return end

            ExecuteCommand(("warn %s %s"):format(inputId, reason))
        end)

        StaffMenu.outils.Button(":gun: TIG ARMES", "Confisquer les armes d'un joueur pour une durée définie", nil, "chevron", false, function()
            local mode = VFW.Nui.ChoiceInput("Type de recherche", "Le joueur est-il connecté ?", {
                { label = "Online (ID session)", value = "online" },
                { label = "Offline (UUID)", value = "offline" },
            })
            if not mode then return end

            local placeholder = mode == "online" and "ID session du joueur" or "UUID du joueur"
          local inputId = VFW.Nui.KeyboardInput(true, placeholder)
            if not inputId or inputId == "" then return end

            local duration = VFW.Nui.KeyboardInput(true, "Durée en minutes (max 600)", "")
            if not duration or duration == "" then return end
            if not tonumber(duration) or tonumber(duration) <= 0 or tonumber(duration) > 600 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'TIG Armes', message = "Cette durée n'est pas valide (1-600 minutes)." })
                return
            end

            local reason = VFW.Nui.KeyboardInput(true, "Motif du TIG armes", "")
            if not reason or reason == "" then return end

            ExecuteCommand(("tigweapon %s %s %s"):format(inputId, duration, reason))
        end)
    end

    if perms["kick"] then
        StaffMenu.outils.Button(":user: KICK UN JOUEUR", "Expulser un joueur du serveur avec une raison obligatoire", nil, "chevron", false, function()
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not playerId or playerId == "" then return end

            local reason = VFW.Nui.KeyboardInput(true, "Raison du kick", "")
            if not reason or reason == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Raison obligatoire." })
                return
            end

            ExecuteCommand("kick " .. playerId .. " " .. reason)
        end)
    end

    if perms["ban"] then
        StaffMenu.outils.Button(":hammer: BANNIR CONNECTÉ", "Bannir définitivement ou temporairement un joueur actuellement en ligne", nil, "chevron", false, function()
            local mode = VFW.Nui.ChoiceInput("Type", "Le joueur est-il connecté ?", {
                { label = "Online (ID session)", value = "online" },
            })
            if not mode then return end

            local inputId = VFW.Nui.KeyboardInput(true, "ID session du joueur")
            if not inputId or inputId == "" then return end

            local playerData = TriggerServerCallback("vfw:staff:resolvePlayerForSanctions", inputId, "online")
            if not playerData then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Sanctions', message = "Joueur non trouvé." })
                return
            end

            StaffMenu.outils.close()
            Wait(100)
            playerData.defaultType = "ban"
          StaffMenu.OpenSanctionsUI(playerData)
        end)

        StaffMenu.outils.Button(":check: UNBAN UN JOUEUR", "Lever le bannissement d'un joueur en entrant son Ban ID", nil, "chevron", false, function()
            local id = VFW.Nui.KeyboardInput(true, "Ban ID")
            if id and id ~= "" then
                TriggerServerEvent("core:ban:unbanplayer", id)
            end
        end)
    end

    if perms["ban_offline"] then
        StaffMenu.outils.List(":hammer: BANNIR DÉCONNECTÉ", nil, false,
            { "Jours", "Heures", "Perm" }, outils.indexBan, function(index, item)
                outils.indexBan = index

                local id = VFW.Nui.KeyboardInput(true, "UUID du joueur")
                if not id or id == "" then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Identifiant requis." })
                    return
                end

                local reason = VFW.Nui.KeyboardInput(true, "Raison", "")
                if not reason or reason == "" then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Raison obligatoire." })
                    return
                end

                local time
                local typeBan
                if item == "Jours" then
                    time = VFW.Nui.KeyboardInput(true, "Nombre de jours", "")
                    typeBan = "jours"
              elseif item == "Heures" then
                    time = VFW.Nui.KeyboardInput(true, "Nombre d'heures", "")
                    typeBan = "heures"
              elseif item == "Perm" then
                    time = 0
                    typeBan = "perm"
              end

                if time ~= nil and time ~= "" then
                    TriggerServerEvent("core:ban:banofflineplayer", id, reason, time, GetPlayerServerId(PlayerId()), typeBan)
                end
            end)
    end

    if perms["give_tig"] then
        StaffMenu.outils.Button(":report: TIG CONNECTÉ", "Donner des travaux d'intérêt général à un joueur connecté par son ID session", nil, "chevron", false, function()
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not playerId or playerId == "" then return end

            local amount = VFW.Nui.KeyboardInput(true, "Nombre de TIG (1-300)", "")
            if not amount or not tonumber(amount) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce nombre n'est pas valide." })
                return
            end
            amount = tonumber(amount)
            if amount < 1 or amount > 300 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Le nombre doit être entre 1 et 300." })
                return
            end

            local reason = VFW.Nui.KeyboardInput(true, "Raison des TIG", "")
            if not reason or reason == "" then reason = "Aucune raison spécifiée" end

            TriggerServerEvent("vfw:admin:giveTIG", tonumber(playerId), amount, reason)
        end)

        StaffMenu.outils.Button(":report: TIG DÉCONNECTÉ", "Donner des travaux d'intérêt général à un joueur hors ligne par son UUID", nil, "chevron", false, function()
            local globalId = VFW.Nui.KeyboardInput(true, "UUID du joueur")
            if not globalId or globalId == "" then return end

            local amount = VFW.Nui.KeyboardInput(true, "Nombre de TIG (1-300)", "")
            if not amount or not tonumber(amount) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce nombre n'est pas valide." })
                return
            end
            amount = tonumber(amount)
            if amount < 1 or amount > 300 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Le nombre doit être entre 1 et 300." })
                return
            end

            local reason = VFW.Nui.KeyboardInput(true, "Raison des TIG", "")
            if not reason or reason == "" then reason = "Aucune raison spécifiée" end

            TriggerServerEvent("vfw:admin:giveTIGOffline", tonumber(globalId), amount, reason)
        end)
    end

    if perms["remove_tig"] then
        StaffMenu.outils.Button(":x: UNTIG CONNECTÉ", "Retirer les TIG d'un joueur connecté par ID", nil, "chevron", false, function()
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not playerId or playerId == "" then return end
            TriggerServerEvent("vfw:admin:removeTIG", tonumber(playerId))
        end)

        StaffMenu.outils.Button(":x: UNTIG DÉCONNECTÉ", "Retirer les TIG d'un joueur déconnecté par UUID", nil, "chevron", false, function()
            local globalId = VFW.Nui.KeyboardInput(true, "UUID du joueur")
            if not globalId or globalId == "" then return end
            TriggerServerEvent("vfw:admin:removeTIGOffline", tonumber(globalId))
        end)
    end

    -- === :report: HISTORIQUES ===
    local hasHistoriques = perms["voir_prison"] or perms["voir_bans"] or perms["voir_tig"] or perms["voir_kicks"] or perms["warn"]
    if hasHistoriques then
        StaffMenu.outils.Separator(":report: HISTORIQUES")
    end

    if perms["voir_prison"] then
        StaffMenu.outils.Button(":lock: JOUEURS EN PRISON", "Voir tous les joueurs actuellement incarcérés et leur temps restant", nil, "chevron", false, function()
            StaffMenu.data.prisonList = TriggerServerCallback("vfw:staff:getPrisonList") or {}
        end, StaffMenu.prisonList)
    end

    if perms["voir_bans"] then
        StaffMenu.outils.Button(":hammer: BANNISSEMENTS", "Voir tous les bans actifs et les détails de chaque bannissement", nil, "chevron", false, function()
            StaffMenu.data.banList = TriggerServerCallback("core:ban:getbans") or {}
        end, StaffMenu.banListDirect)
    end

    if perms["voir_tig"] then
        StaffMenu.outils.Button(":report: TIG EN COURS", "Voir tous les travaux d'intérêt général en cours", nil, "chevron", false, function()
            StaffMenu.data.tigList = TriggerServerCallback("vfw:staff:getTigList") or {}
        end, StaffMenu.tigListMenu)

        StaffMenu.outils.Button(":gun: TIG ARMES EN COURS", "Voir toutes les confiscations d'armes actives", nil, "chevron", false, function()
            StaffMenu.data.tigWeaponsList = TriggerServerCallback("vfw:staff:getTigWeaponsList") or {}
        end, StaffMenu.tigWeaponsListMenu)
    end

    if perms["voir_kicks"] then
        StaffMenu.outils.Button(":user: KICKS", "Historique des kicks effectués sur le serveur", nil, "chevron", false, function()
            StaffMenu.data.kickList = TriggerServerCallback("vfw:staff:getKickList") or {}
        end, StaffMenu.kickListMenu)
    end

    if perms["warn"] then
        StaffMenu.outils.Button(":warning: WARNS", "Historique des avertissements donnés aux joueurs", nil, "chevron", false, function()
            StaffMenu.data.warnList = TriggerServerCallback("vfw:staff:getWarnList") or {}
        end, StaffMenu.warnListMenu)
    end

    -- === :wrench: OUTILS ===
    local hasOutils = perms["give_item"] or perms["give_weapon"] or perms["zone_actions"] or perms["clean_zone"] or perms["give_permis"] or perms["retirer_permis"] or perms["mugshot"]
    if hasOutils then
        StaffMenu.outils.Separator(":wrench: OUTILS")
    end

    if perms["give_item"] then
        StaffMenu.outils.Button(":gift: GIVE UN ITEM", "Donner un item à un joueur connecté par ID puis choisir l'item et la quantité", nil, "chevron", false, function()
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not playerId or playerId == "" then return end
            StaffMenu.data.selectedPlayer = tonumber(playerId)
        end, StaffMenu.items)
    end

    if perms["give_weapon"] then
        StaffMenu.outils.Button(":gun: DONNER DES ARMES", "Donner une ou plusieurs armes à un joueur connecté", nil, "chevron", false, function() end, StaffMenu.weapons)
    end

    if perms["zone_actions"] then
        StaffMenu.outils.Button(":dot-green: REVIVE DE ZONE", "Réanimer tous les joueurs morts dans un rayon défini autour de vous", nil, "chevron", false, function()
            local radius = VFW.Nui.KeyboardInput(true, "Rayon (max 500)", "100")
            radius = tonumber(radius)
            if not radius or radius <= 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce rayon n'est pas valide." })
                return
            end
            if radius > 500 then radius = 500 end
            TriggerServerEvent("vfw:staff:reviveZone", radius)
        end)
    end

    if perms["zone_actions"] then
        StaffMenu.outils.Button(":flask: SOIGNER LA ZONE", "Soigner tous les joueurs blessés dans un rayon défini autour de vous", nil, "heart", false, function()
            local radius = VFW.Nui.KeyboardInput(true, "Radius de la zone (max 750)")
            if tonumber(radius) and tonumber(radius) >= 0 then
                VFW.TreatZone(radius)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce rayon n'est pas valide." })
            end
        end)
    end

    if perms["clean_zone"] then
        StaffMenu.outils.Button(":trash: NETTOYAGE ZONE", "Supprimer les véhicules et objets abandonnés dans un rayon défini", nil, "chevron", false, function()
            local radius = VFW.Nui.KeyboardInput(true, "Rayon (max 500)", "50")
            radius = tonumber(radius)
            if not radius or radius <= 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Ce rayon n'est pas valide." })
                return
            end
            if radius > 500 then radius = 500 end
            TriggerServerEvent("vfw:staff:clearZone", radius)
        end)
    end

    if perms["give_permis"] then
        StaffMenu.outils.Button(":id: DONNER UN PERMIS", "Attribuer un permis de conduire ou autre licence à un joueur par ID", nil, "chevron", false, function()
            local idplayer = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not idplayer or idplayer == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Cet identifiant n'est pas valide." })
                return
            end
            StaffMenu.data.licenseTargetId = idplayer
        end, StaffMenu.giveLicense)
    end

    if perms["retirer_permis"] then
        StaffMenu.outils.Button(":id: RETIRER UN PERMIS", "Révoquer un permis ou une licence d'un joueur par ID", nil, "chevron", false, function()
            local idplayer = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not idplayer or idplayer == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Cet identifiant n'est pas valide." })
                return
            end
            StaffMenu.data.removeLicenseTargetId = idplayer
            StaffMenu.data.removeLicenseData = TriggerServerCallback("vfw:staff:getPlayerLicensesForRemoval", tonumber(idplayer))
            if not StaffMenu.data.removeLicenseData then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Joueur non trouvé." })
                return
            end
        end, StaffMenu.removeLicense)
    end

    if perms["mugshot"] then
        StaffMenu.outils.Button(":camera: REFAIRE MUGSHOT", "Forcer la prise d'un nouveau mugshot pour un joueur par ID", nil, "chevron", false, function()
            local idplayer = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not idplayer or idplayer == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Cet identifiant n'est pas valide." })
                return
            end
            ExecuteCommand("mugshot " .. idplayer)
        end)
    end

    -- === :users: JOUEURS ===
    local hasJoueurs = perms["setjob"] or perms["setjob2"] or perms["gestion_role"] or perms["count_players_zone"] or perms["wipe"] or perms["register"]
    if hasJoueurs then
        StaffMenu.outils.Separator(":users: JOUEURS")
    end

    if perms["setjob"] then
        StaffMenu.outils.Button(":briefcase: CHANGER LE MÉTIER", "Modifier le job d'un joueur connecté en le sélectionnant dans la liste", nil, "chevron", false, function()
            StaffMenu.data.playerListForJob = TriggerServerCallback("vfw:staff:getPlayerList") or {}
        end, StaffMenu.selectPlayerForJob)
    end

    if perms["setjob2"] then
        StaffMenu.outils.Button(":users: CHANGER LA FACTION", "Modifier la faction (gang, organisation) d'un joueur connecté", nil, "chevron", false, function()
            StaffMenu.data.playerListForFaction = TriggerServerCallback("vfw:staff:getPlayerList") or {}
        end, StaffMenu.selectPlayerForFaction)
    end

    if perms["gestion_role"] then
        StaffMenu.outils.Button(":shield: CHANGER LE RÔLE", "Modifier le rôle staff d'un joueur (grade, permissions) par ID Global", nil, "chevron", false, function()
            local globalId = VFW.Nui.KeyboardInput(true, "ID Global du joueur")
            if not globalId or globalId == "" then return end

            local playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfoByGlobalId", tonumber(globalId))
            if not playerInfo or not playerInfo.identifier then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Joueur non trouvé." })
                return
            end
            StaffMenu.data.roleChangeTarget = playerInfo
        end, StaffMenu.staffRoleChangeOutils)
    end

    if perms["count_players_zone"] then
        StaffMenu.outils.Button(":hash: COMPTER LES JOUEURS", "Compter le nombre de joueurs présents dans un rayon autour de vous", nil, "chevron", false, function()
            local radius = VFW.Nui.KeyboardInput(true, "Radius")
            radius = tonumber(radius)
            if radius and radius > 0 then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local playersCount = 0
                for _, player in ipairs(GetActivePlayers()) do
                    local targetPed = GetPlayerPed(player)
                    local targetCoords = GetEntityCoords(targetPed)
                    if #(playerCoords - targetCoords) <= radius then
                        playersCount = playersCount + 1
                    end
                end
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff',
                    message = playersCount .. " joueurs dans un radius de " .. radius .. "m."
              })
            end
        end)
    end

    if perms["wipe"] then
        StaffMenu.outils.Button(":skull: WIPE CONNECTÉ", "Supprimer un ou plusieurs personnages d'un joueur connecté par ID", nil, "chevron", false, function()
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not playerId or playerId == "" then return end
            StaffMenu.data.selectedPlayer = tonumber(playerId)
            StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getCharList", tonumber(playerId))
            if not StaffMenu.data.charList or not StaffMenu.data.charList.charList or #StaffMenu.data.charList.charList == 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Joueur non trouvé." })
                return
            end
            StaffMenu.data.isOfflineWipe = false
            StaffMenu.wipeConnected.ClearItems()
            for _, v in pairs(StaffMenu.data.charList.charList) do
                StaffMenu.wipeConnected.Button(v.name, (v.actual and "Actuel" or "OFF"), v.id, "chevron", false, function()
                    local validations = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI'")
                    if string.lower(validations) == "oui" then
                        TriggerServerEvent("vfw:staff:wipePlayer", StaffMenu.data.selectedPlayer, v.id)
                        SetTimeout(500, function()
                            StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getCharList", StaffMenu.data.selectedPlayer) or {}
                            if StaffMenu.data.charList and StaffMenu.data.charList.charList and #StaffMenu.data.charList.charList > 0 then
                                StaffMenu.wipeConnected.ClearItems()
                                for _, c in pairs(StaffMenu.data.charList.charList) do
                                    StaffMenu.wipeConnected.Button(c.name, (c.actual and "Actuel" or "OFF"), c.id, "chevron", false, function()
                                        local confirm = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI'")
                                        if string.lower(confirm) == "oui" then
                                            TriggerServerEvent("vfw:staff:wipePlayer", StaffMenu.data.selectedPlayer, c.id)
                                        else
                                            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe', message = "Vous n'avez pas confirmé." })
                                        end
                                    end)
                                end
                                StaffMenu.wipeConnected.refresh()
                            else
                                StaffMenu.wipeConnected.close()
                            end
                        end)
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe', message = "Vous n'avez pas confirmé." })
                    end
                end)
            end
        end, StaffMenu.wipeConnected)

        StaffMenu.outils.Button(":skull: WIPE DÉCONNECTÉ", "Supprimer un personnage d'un joueur hors ligne par UUID", nil, "chevron", false, function()
            local globalId = VFW.Nui.KeyboardInput(true, "UUID du joueur")
            if not globalId or globalId == "" then return end
            StaffMenu.data.selectedGlobalId = tonumber(globalId)
            StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getOfflineCharList", tonumber(globalId))
            if not StaffMenu.data.charList or not StaffMenu.data.charList.charList or #StaffMenu.data.charList.charList == 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Aucun personnage trouvé." })
                return
            end
            StaffMenu.wipeOffline.open()
        end)
    end

    if perms["register"] then
        StaffMenu.outils.Button(":edit: REGISTER", "Enregistrer manuellement un joueur dans la base de données", nil, "chevron", false, function()
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
            if not playerId or playerId == "" then return end
            ExecuteCommand("register " .. playerId)
        end)
    end

end

-- ============================================================
-- BUILD FUNCTIONS FOR LIST SUBMENUS
-- ============================================================

--- .BuildPrisonListMenu
function StaffMenu.BuildPrisonListMenu()
    local prisoners = StaffMenu.data.prisonList or {}

    StaffMenu.prisonList.Button(":refresh: ACTUALISER", nil, nil, "chevron", false, function()
        StaffMenu.data.prisonList = TriggerServerCallback("vfw:staff:getPrisonList") or {}
        StaffMenu.prisonList.refresh()
    end)

    StaffMenu.prisonList.Separator(":lock: JOUEURS EN PRISON (" .. #prisoners .. ")")

    if #prisoners == 0 then
        StaffMenu.prisonList.Textbox("Aucun joueur en prison actuellement.", ":document: Prison")
        return
    end

    for _, prisoner in ipairs(prisoners) do
        local label = prisoner.name or "Inconnu"
      local desc = prisoner.remainingMinutes .. " min restantes | " .. (prisoner.reason or "")
        StaffMenu.prisonList.Button(label, desc, nil, "chevron", false, function()
            if prisoner.online then
                TriggerServerEvent("vfw:staff:releasePrisoner", prisoner.source)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Prison',
                    message = prisoner.name .. " a été libéré de prison."
              })
                StaffMenu.data.prisonList = TriggerServerCallback("vfw:staff:getPrisonList") or {}
                StaffMenu.prisonList.refresh()
            end
        end)
    end
end

--- .BuildBanListDirectMenu
local banListQuery = nil
local banListCurrentPage = 1
local banListPerPage = 20

--- IsPermaBan - true si le ban est permanent (expiration 0 ou > an 3000)
---@param expiration number
---@return boolean
local function IsPermaBan(expiration)
    if not expiration or expiration == 0 then return true end
    return expiration >= 32503680000
end

--- BanMatchesQuery - true si le ban matche le terme de recherche (pseudo, UUID ou ID de ban, insensible à la casse)
---@param ban table
---@param query string
---@return boolean
local function BanMatchesQuery(ban, query)
    if not query or query == "" then return true end
    local needle = string.lower(query)
    local fields = {
        tostring(ban.id or ""),
        tostring(ban.playerGlobalId or ""),
        tostring(ban.pseudo or "")
    }
    for _, f in ipairs(fields) do
        if string.find(string.lower(f), needle, 1, true) then
            return true
        end
    end
    return false
end

function StaffMenu.BuildBanListDirectMenu()
    local firstLabel = banListQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = banListQuery == nil and "UN BAN" or banListQuery

    StaffMenu.banListDirect.Button(firstLabel, lastLabel, nil, "search", false, function()
        if banListQuery ~= nil then
            banListQuery = nil
            banListCurrentPage = 1
            StaffMenu.banListDirect.refresh()
            return
        end
        banListQuery = VFW.Nui.KeyboardInput(true, "Pseudo, UUID ou ID de ban")
        if not banListQuery or banListQuery == "" then
            banListQuery = nil
            return
        end
        banListCurrentPage = 1
        StaffMenu.banListDirect.refresh()
    end)

    StaffMenu.banListDirect.Button(":refresh: ACTUALISER", nil, nil, "chevron", false, function()
        StaffMenu.data.banList = TriggerServerCallback("core:ban:getbans") or {}
        banListQuery = nil
        banListCurrentPage = 1
        StaffMenu.banListDirect.refresh()
    end)

    if not StaffMenu.data.banList or not next(StaffMenu.data.banList) then
        StaffMenu.banListDirect.Separator(":hammer: BANNISSEMENTS")
        StaffMenu.banListDirect.Textbox("Aucun bannissement actif.", ":document: Bans")
        return
    end

    local filtered = {}
    for _, v in pairs(StaffMenu.data.banList) do
        if BanMatchesQuery(v, banListQuery) then
            table.insert(filtered, v)
        end
    end

    table.sort(filtered, function(a, b)
        return (tonumber(a.id) or 0) > (tonumber(b.id) or 0)
    end)

    local totalCount = #filtered
    local totalPages = math.ceil(totalCount / banListPerPage)
    if totalPages < 1 then totalPages = 1 end
    if banListCurrentPage > totalPages then banListCurrentPage = totalPages end
    if banListCurrentPage < 1 then banListCurrentPage = 1 end

    if banListQuery then
        StaffMenu.banListDirect.Separator(":hammer: BANNISSEMENTS - Résultats (" .. totalCount .. ")")
    else
        StaffMenu.banListDirect.Separator(":hammer: BANNISSEMENTS - Page " .. banListCurrentPage .. "/" .. totalPages .. " (" .. totalCount .. " total)")
    end

    if banListQuery and totalCount == 0 then
        StaffMenu.banListDirect.Textbox("Aucun ban ne correspond à \"" .. banListQuery .. "\".", ":search: Aucun résultat")
        return
    end

    local startIdx = (banListCurrentPage - 1) * banListPerPage + 1
    local endIdx = math.min(startIdx + banListPerPage - 1, totalCount)

    for i = startIdx, endIdx do
        local v = filtered[i]
        local label = v.pseudo or "Joueur inconnu"
      local sub = (IsPermaBan(v.expiration) and "PERMA" or "TEMP") .. " | ID: " .. tostring(v.id)
        StaffMenu.banListDirect.Button(label, sub, nil, "chevron", false, function()
            StaffMenu.data.selectedBan = v
            StaffMenu.banDetail.open()
        end, StaffMenu.banDetail)
    end

    if totalPages > 1 then
        StaffMenu.banListDirect.Separator(nil)

        if banListCurrentPage > 1 then
            StaffMenu.banListDirect.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (banListCurrentPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                banListCurrentPage = banListCurrentPage - 1
                StaffMenu.banListDirect.refresh()
            end)
        end

        if banListCurrentPage < totalPages then
            StaffMenu.banListDirect.Button("PAGE SUIVANTE :arrow:", "Page " .. (banListCurrentPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                banListCurrentPage = banListCurrentPage + 1
                StaffMenu.banListDirect.refresh()
            end)
        end
    end
end

--- FormatExpiration - Formate l'expiration en string lisible
---@param expiration number
---@return string
local function FormatExpiration(expiration)
    if IsPermaBan(expiration) then
        return "Permanent"
  end
    local remaining = expiration - GetCloudTimeAsInt()
    if remaining <= 0 then
        return "Expiré"
  end
    local d = math.floor(remaining / 86400)
    remaining = remaining % 86400
    local h = math.floor(remaining / 3600)
    remaining = remaining % 3600
    local m = math.ceil(remaining / 60)
    if d > 0 then
        return string.format("%dj %dh %dm", d, h, m)
    elseif h > 0 then
        return string.format("%dh %dm", h, m)
    else
        return string.format("%dm", m)
    end
end

--- .BuildBanDetailMenu
function StaffMenu.BuildBanDetailMenu()
    local v = StaffMenu.data.selectedBan
    if not v then
        StaffMenu.banDetail.Textbox("Aucun ban sélectionné.", ":question: Erreur")
        return
    end

    StaffMenu.banDetail.Separator(":report: INFORMATIONS")
    StaffMenu.banDetail.Button("Joueur : " .. (v.pseudo or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.banDetail.Button("UUID : " .. tostring(v.playerGlobalId or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.banDetail.Button("Motif : " .. (v.raison or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.banDetail.Button("Banni par : " .. (v.by or "Inconnu"), nil, nil, nil, false, function() end)
    StaffMenu.banDetail.Button("ID du ban : " .. tostring(v.id), nil, nil, nil, false, function() end)
    StaffMenu.banDetail.Button("Date : " .. (v.banDate or "Inconnue"), nil, nil, nil, false, function() end)
    StaffMenu.banDetail.Button("Durée restante : " .. FormatExpiration(v.expiration), nil, nil, nil, false, function() end)

    StaffMenu.banDetail.Separator(":bolt: ACTIONS")

    local canUnban = VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["ban"]
    StaffMenu.banDetail.Button(":unlock: UNBAN", "Lever le bannissement de ce joueur", nil, "chevron", not canUnban, function()
        if not canUnban then return end
        TriggerServerEvent("core:ban:unbanplayer", v.id)
        StaffMenu.data.selectedBan = nil
        StaffMenu.banDetail.close()
        StaffMenu.banListDirect.open()
    end)
end

--- .BuildTigListMenu
function StaffMenu.BuildTigListMenu()
    local tigList = StaffMenu.data.tigList or {}

    StaffMenu.tigListMenu.Button(":refresh: ACTUALISER", nil, nil, "chevron", false, function()
        StaffMenu.data.tigList = TriggerServerCallback("vfw:staff:getTigList") or {}
        StaffMenu.tigListMenu.refresh()
    end)

    StaffMenu.tigListMenu.Separator(":report: TIG ACTIFS (" .. #tigList .. ")")

    if #tigList == 0 then
        StaffMenu.tigListMenu.Textbox("Aucun TIG actif.", ":document: TIG")
        return
    end

    for _, tig in ipairs(tigList) do
        local name = tig.global_pseudo or ((tig.firstname or "") .. " " .. (tig.lastname or ""))
        local progress = (tig.completed_tig or 0) .. "/" .. (tig.total_tig or 0)
        local desc = progress .. " | " .. (tig.reason or "Sans raison")
        StaffMenu.tigListMenu.Button(name, desc, nil, nil, false, function() end)
    end
end

--- .BuildTigWeaponsListMenu
function StaffMenu.BuildTigWeaponsListMenu()
    local list = StaffMenu.data.tigWeaponsList or {}

    StaffMenu.tigWeaponsListMenu.Button(":refresh: ACTUALISER", nil, nil, "chevron", false, function()
        StaffMenu.data.tigWeaponsList = TriggerServerCallback("vfw:staff:getTigWeaponsList") or {}
        StaffMenu.tigWeaponsListMenu.refresh()
    end)

    StaffMenu.tigWeaponsListMenu.Separator(":gun: TIG ARMES ACTIFS (" .. #list .. ")")

    if #list == 0 then
        StaffMenu.tigWeaponsListMenu.Textbox("Aucun TIG armes actif.", ":document: TIG Armes")
        return
    end

    for _, tw in ipairs(list) do
        local name = tw.global_pseudo or ("UUID:" .. (tw.player_global_id or "?"))
        local desc = (tw.reason or "Sans raison") .. " | Par: " .. (tw.given_by or "Inconnu")
        StaffMenu.tigWeaponsListMenu.Button(name, desc, nil, nil, false, function() end)
    end
end

--- .BuildKickListMenu
function StaffMenu.BuildKickListMenu()
    local list = StaffMenu.data.kickList or {}

    StaffMenu.kickListMenu.Button(":refresh: ACTUALISER", nil, nil, "chevron", false, function()
        StaffMenu.data.kickList = TriggerServerCallback("vfw:staff:getKickList") or {}
        StaffMenu.kickListMenu.refresh()
    end)

    StaffMenu.kickListMenu.Separator(":user: KICKS RÉCENTS (" .. #list .. ")")

    if #list == 0 then
        StaffMenu.kickListMenu.Textbox("Aucun kick récent.", ":document: Kicks")
        return
    end

    for _, kick in ipairs(list) do
        local name = kick.player_pseudo or ("ID:" .. (kick.id or "?"))
        local date = kick.kick_date_formatted or "?"
      local desc = date .. " | Par: " .. (kick.kicked_by or "Inconnu") .. " | " .. (kick.reason or "")
        StaffMenu.kickListMenu.Button(name, desc, nil, nil, false, function() end)
    end
end

--- .BuildWarnListMenu
function StaffMenu.BuildWarnListMenu()
    local list = StaffMenu.data.warnList or {}

    StaffMenu.warnListMenu.Button(":refresh: ACTUALISER", nil, nil, "chevron", false, function()
        StaffMenu.data.warnList = TriggerServerCallback("vfw:staff:getWarnList") or {}
        StaffMenu.warnListMenu.refresh()
    end)

    StaffMenu.warnListMenu.Separator(":warning: WARNS RÉCENTS (" .. #list .. ")")

    if #list == 0 then
        StaffMenu.warnListMenu.Textbox("Aucun warn récent.", ":document: Warns")
        return
    end

    for _, warn in ipairs(list) do
        local name = warn.player_pseudo or ("ID:" .. (warn.id or "?"))
        local date = warn.warn_date_formatted or "?"
      local desc = date .. " | Par: " .. (warn.warned_by or "Inconnu") .. " | " .. (warn.reason or "")
        StaffMenu.warnListMenu.Button(name, desc, nil, nil, false, function() end)
    end
end

--- .BuildRemoveLicenseMenu
function StaffMenu.BuildRemoveLicenseMenu()
    StaffMenu.removeLicense.ClearItems()
    local data = StaffMenu.data.removeLicenseData
    if not data then
        StaffMenu.removeLicense.Textbox("Aucun joueur sélectionné.", ":document: Permis")
        return
    end

    local targetId = StaffMenu.data.removeLicenseTargetId
    StaffMenu.removeLicense.Separator(":id: PERMIS DE " .. (data.name or "Inconnu"))

    local licenseTypes = {
        { type = "car", label = "Permis Voiture" },
        { type = "motorcycle", label = "Permis Moto" },
        { type = "truck", label = "Permis Poids Lourd" }
    }

    local hasAny = false
    for _, license in ipairs(licenseTypes) do
        if data.licenses and data.licenses[license.type] then
            hasAny = true
            StaffMenu.removeLicense.Button(":trash: " .. license.label, nil, nil, "arrow", false, function()
                TriggerServerEvent("vfw:staff:removeLicense", tonumber(targetId), license.type)
                -- Refresh data
                StaffMenu.data.removeLicenseData = TriggerServerCallback("vfw:staff:getPlayerLicensesForRemoval", tonumber(targetId))
                StaffMenu.removeLicense.refresh()
            end)
        end
    end

    if not hasAny then
        StaffMenu.removeLicense.Textbox("Ce joueur n'a aucun permis.", ":document: Permis")
    end
end


-- Handler unique de nettoyage de zone (déclenché par VFW.ClearZone côté serveur)
RegisterNetEvent("vfw:clearZone")
AddEventHandler("vfw:clearZone", function(zoneCoords, radius)
    if not zoneCoords or not zoneCoords.x then return end

    Citizen.CreateThread(function()
        local coords = vector3(zoneCoords.x + 0.0, zoneCoords.y + 0.0, zoneCoords.z + 0.0)
        local myCoords = GetEntityCoords(PlayerPedId())
        -- Ne traiter que si on est dans la zone étendue
        if #(myCoords - coords) > radius + 100 then return end

        -- Véhicules : non occupés par des joueurs
        for _, veh in ipairs(GetGamePool("CVehicle")) do
            if DoesEntityExist(veh) and #(coords - GetEntityCoords(veh)) <= radius then
                local occupied = false
                for seat = -1, GetVehicleMaxNumberOfPassengers(veh) do
                    local ped = GetPedInVehicleSeat(veh, seat)
                    if ped ~= 0 and IsPedAPlayer(ped) then
                        occupied = true
                        break
                    end
                end
                if not occupied then
                    if NetworkGetEntityIsNetworked(veh) then
                        TriggerServerEvent("vfw:deleteEntity", { VehToNet(veh) })
                    end
                    SetEntityAsMissionEntity(veh, true, true)
                    DeleteEntity(veh)
                end
            end
        end

        -- Peds NPC uniquement
        for _, ped in ipairs(GetGamePool("CPed")) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and #(coords - GetEntityCoords(ped)) <= radius then
                if NetworkGetEntityIsNetworked(ped) then
                    TriggerServerEvent("vfw:deleteEntity", { PedToNet(ped) })
                end
                SetEntityAsMissionEntity(ped, true, true)
                DeleteEntity(ped)
            end
        end

        -- Objets : uniquement ceux spawnés par scripts (networked), pas les world props ymaps
        for _, obj in ipairs(GetGamePool("CObject")) do
            if DoesEntityExist(obj) and NetworkGetEntityIsNetworked(obj) and #(coords - GetEntityCoords(obj)) <= radius then
                NetworkRequestControlOfEntity(obj)
                local timeout = 0
                while not NetworkHasControlOfEntity(obj) and timeout < 5 do
                    Wait(50)
                    timeout = timeout + 1
                end
                TriggerServerEvent("vfw:deleteEntity", { ObjToNet(obj) })
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
        end

        -- Pickups
        for _, pickup in ipairs(GetGamePool("CPickup")) do
            if DoesEntityExist(pickup) and #(coords - GetEntityCoords(pickup)) <= radius then
                DeleteEntity(pickup)
            end
        end

        -- Feux et events de choc
        StopFireInRange(coords.x, coords.y, coords.z, radius)
        RemoveAllShockingEvents(true)
    end)
end)

-- Handler pour la commande /wipeoffline
RegisterNetEvent("vfw:staff:openWipeOfflineMenu", function(globalId)
    StaffMenu.data.selectedGlobalId = tonumber(globalId)
    StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getOfflineCharList", tonumber(globalId))

    if not StaffMenu.data.charList or not StaffMenu.data.charList.charList or #StaffMenu.data.charList.charList == 0 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff',
            message = "Aucun personnage trouvé pour cet UUID."
      })
        return
    end

    StaffMenu.wipeOffline.open()
end)

--- .BuildGiveLicenseMenu
function StaffMenu.BuildGiveLicenseMenu()
    local targetSource = StaffMenu.data.licenseTargetId
    if not targetSource then
        return
    end

    -- Récupérer les permis existants du joueur
    local existingLicenses = TriggerServerCallback("vfw:staff:getPlayerLicenses", tonumber(targetSource)) or {}

    local licenseTypes = {
        { type = "car", label = "Permis Voiture" },
        { type = "motorcycle", label = "Permis Moto" },
        { type = "truck", label = "Permis Poids Lourd" }
    }

    for _, license in ipairs(licenseTypes) do
        local alreadyHas = existingLicenses[license.type] == true
        if alreadyHas then
            StaffMenu.giveLicense.Button(":check: " .. "Retirer " .. license.label, nil, nil, "trash", false, function()
                TriggerServerEvent("vfw:staff:removeLicense", tonumber(targetSource), license.type)
                SetTimeout(300, function()
                    StaffMenu.giveLicense.ClearItems()
                    StaffMenu.giveLicense.refresh()
                end)
            end)
        else
            StaffMenu.giveLicense.Button("Donner " .. license.label, nil, nil, "arrow", false, function()
                TriggerServerEvent("vfw:staff:giveLicense", tonumber(targetSource), license.type)
                SetTimeout(300, function()
                    StaffMenu.giveLicense.ClearItems()
                    StaffMenu.giveLicense.refresh()
                end)
            end)
        end
    end
end

-- Variable pour la recherche de joueurs
local playerSearchQueryJob = nil
local playerSearchQueryFaction = nil

--- .BuildSelectPlayerForJobMenu
local function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function StaffMenu.BuildSelectPlayerForJobMenu()
    local players = StaffMenu.data.playerListForJob or {}

    -- Bouton actualiser
    StaffMenu.selectPlayerForJob.Button(":refresh: ACTUALISER", "Recharger la liste des joueurs", nil, "chevron", false, function()
        StaffMenu.data.playerListForJob = TriggerServerCallback("vfw:staff:getPlayerList") or {}
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = "Liste des joueurs actualisée." })
        StaffMenu.selectPlayerForJob.refresh()
    end)

    -- Bouton recherche
    local searchLabel = playerSearchQueryJob == nil and ":search: RECHERCHER" or ":search: RECHERCHER:"
  local searchValue = playerSearchQueryJob == nil and "UN JOUEUR" or playerSearchQueryJob
    StaffMenu.selectPlayerForJob.Button(searchLabel, searchValue, nil, "search", false, function()
        if playerSearchQueryJob ~= nil then
            playerSearchQueryJob = nil
            StaffMenu.selectPlayerForJob.refresh()
            return
        end

        playerSearchQueryJob = VFW.Nui.KeyboardInput(true, "Nom ou ID du joueur")
        if playerSearchQueryJob == nil or playerSearchQueryJob == "" then
            playerSearchQueryJob = nil
            return
        end
        StaffMenu.selectPlayerForJob.refresh()
    end)

    StaffMenu.selectPlayerForJob.Separator(":report: JOUEURS CONNECTÉS (" .. tableCount(players) .. ")")

    -- Liste des joueurs
    for _, player in pairs(players) do
        local playerName = player.name or "Inconnu"
      local playerId = player.source or 0
        local playerJob = player.job or "Chômeur"

      -- Filtrage par recherche
        local matchSearch = true
        if playerSearchQueryJob then
            local query = string.lower(playerSearchQueryJob)
            matchSearch = string.find(string.lower(playerName), query) or
                         string.find(tostring(playerId), query) or
                         string.find(string.lower(playerJob), query)
        end

        if matchSearch then
            StaffMenu.selectPlayerForJob.Button(
                playerName,
                "ID: " .. playerId .. " | " .. playerJob,
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.data.selectedPlayer = playerId
                    StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", playerId) or {}
                    if not StaffMenu.data.playerInfo or not StaffMenu.data.playerInfo.id then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Joueur non trouvé ou non connecté." })
                        return false
                    end
                    StaffMenu.data.jobsList = TriggerServerCallback("vfw:staff:getJobs") or {}
                    if not StaffMenu.data.jobsList or not next(StaffMenu.data.jobsList) then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Impossible de charger la liste des jobs." })
                        return false
                    end
                end,
                StaffMenu.jobs
            )
        end
    end
end

--- .BuildSelectPlayerForFactionMenu
function StaffMenu.BuildSelectPlayerForFactionMenu()
    local players = StaffMenu.data.playerListForFaction or {}

    -- Bouton actualiser
    StaffMenu.selectPlayerForFaction.Button(":refresh: ACTUALISER", "Recharger la liste des joueurs", nil, "chevron", false, function()
        StaffMenu.data.playerListForFaction = TriggerServerCallback("vfw:staff:getPlayerList") or {}
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Staff', message = "Liste des joueurs actualisée." })
        StaffMenu.selectPlayerForFaction.refresh()
    end)

    -- Bouton recherche
    local searchLabel = playerSearchQueryFaction == nil and ":search: RECHERCHER" or ":search: RECHERCHER:"
  local searchValue = playerSearchQueryFaction == nil and "UN JOUEUR" or playerSearchQueryFaction
    StaffMenu.selectPlayerForFaction.Button(searchLabel, searchValue, nil, "search", false, function()
        if playerSearchQueryFaction ~= nil then
            playerSearchQueryFaction = nil
            StaffMenu.selectPlayerForFaction.refresh()
            return
        end

        playerSearchQueryFaction = VFW.Nui.KeyboardInput(true, "Nom ou ID du joueur")
        if playerSearchQueryFaction == nil or playerSearchQueryFaction == "" then
            playerSearchQueryFaction = nil
            return
        end
        StaffMenu.selectPlayerForFaction.refresh()
    end)

    StaffMenu.selectPlayerForFaction.Separator(":report: JOUEURS CONNECTÉS (" .. tableCount(players) .. ")")

    -- Liste des joueurs
    for _, player in pairs(players) do
        local playerName = player.name or "Inconnu"
      local playerId = player.source or 0
        local playerFaction = player.crew or "Aucune"

      -- Filtrage par recherche
        local matchSearch = true
        if playerSearchQueryFaction then
            local query = string.lower(playerSearchQueryFaction)
            matchSearch = string.find(string.lower(playerName), query) or
                         string.find(tostring(playerId), query) or
                         string.find(string.lower(playerFaction), query)
        end

        if matchSearch then
            StaffMenu.selectPlayerForFaction.Button(
                playerName,
                "ID: " .. playerId .. " | " .. playerFaction,
                nil,
                "chevron",
                false,
                function()
                    StaffMenu.data.selectedPlayer = playerId
                    StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", playerId) or {}
                    if not StaffMenu.data.playerInfo or not StaffMenu.data.playerInfo.id then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Joueur non trouvé ou non connecté." })
                        return false
                    end
                    StaffMenu.data.factionsList = TriggerServerCallback("core:staff:getOrganizations") or {}
                    if not StaffMenu.data.factionsList or not next(StaffMenu.data.factionsList) then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Staff', message = "Impossible de charger la liste des factions." })
                        return false
                    end
                end,
                StaffMenu.factions
            )
        end
    end
end
