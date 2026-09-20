---@meta _
---@diagnostic disable: duplicate-doc-field

-- Default banner URL
local defaultBanner = VFW.CDN.Get("banners/default.png")

-- Storage for animator reports
VFW.AnimatorReports = {}
VFW.lastAnimatorReport = nil

-- Animator menu data
StaffMenu.animatorData = {
    reportInfo = {},
    selectedPlayer = nil,
    announceType = 1,
    announceRadius = 50,
    announceMessage = "",
    giveType = 1,
    giveRadius = 10,
    targetPlayerId = nil,
    itemQuery = nil,
    selectedQuantity = 1
}

-- Register events for animator reports
local function RefreshAnimatorReportsIfOpen()
    if StaffMenu.animatorReports and StaffMenu.animatorReports.opened then
        StaffMenu.animatorReports.refresh()
    end
    if StaffMenu.animatorStandaloneReports and StaffMenu.animatorStandaloneReports.opened then
        StaffMenu.animatorStandaloneReports.refresh()
    end
    -- Refresh des menus principaux pour mettre à jour le compteur de reports
    if StaffMenu.animator and StaffMenu.animator.opened then
        StaffMenu.animator.refresh()
    end
    if StaffMenu.animatorStandalone and StaffMenu.animatorStandalone.opened then
        StaffMenu.animatorStandalone.refresh()
    end
end

RegisterNetEvent("vfw:animator:report", function(report)
    table.insert(VFW.AnimatorReports, report)

    -- Set last animator report for keyboard shortcuts
    VFW.lastAnimatorReport = report.id

    -- Clear after 10 seconds
    SetTimeout(10000, function()
        if VFW.lastAnimatorReport == report.id then
            VFW.lastAnimatorReport = nil
        end
    end)

    -- Live refresh si le menu reports est ouvert
    RefreshAnimatorReportsIfOpen()
end)

RegisterNetEvent("vfw:animator:deleteReport", function(id)
    for i = 1, #VFW.AnimatorReports do
        if VFW.AnimatorReports[i].id == id then
            table.remove(VFW.AnimatorReports, i)
            if VFW.lastAnimatorReport == id then
                VFW.lastAnimatorReport = nil
            end
            break
        end
    end
    RefreshAnimatorReportsIfOpen()
end)

RegisterNetEvent("vfw:animator:updateReport", function(report)
    for i, r in ipairs(VFW.AnimatorReports) do
        if r.id == report.id then
            VFW.AnimatorReports[i] = report
            break
        end
    end
    RefreshAnimatorReportsIfOpen()
end)

RegisterNetEvent("vfw:animator:refreshMenu", function()
    if StaffMenu.animatorReports and StaffMenu.animatorReports.opened then
        StaffMenu.animatorReports.refresh()
    end
    if StaffMenu.animatorStandaloneReports and StaffMenu.animatorStandaloneReports.opened then
        StaffMenu.animatorStandaloneReports.refresh()
    end
end)

-- Animator settings - synchronized with staff menu
StaffMenu.animatorSettings = {
    animatorOutfit = false,
    showNameTags = false,
    noclipActive = false,
    disableReportNotifications = GetResourceKvpString("animator_disable_notifications") == "true"
}

-- Track animator mode state locally
StaffMenu.animatorModeEnabled = false
local isAnimatorMenuRefreshing = false -- Flag pour éviter de reset pendant un refresh

-- Local state for actions personnelles
local animActionsState = {
    invincible = false,
    invisible = false,
    blipsActive = false,
    blipsThread = false,
    playerBlips = {}
}

-- Build animator main menu (accepts targetMenu to support both standalone and submenu versions)
-- isStandalone: true for F7 access (shows MODE ANIMATEUR checkbox), false for admin menu access (direct access)
function StaffMenu.BuildAnimatorMenu(targetMenu, isStandalone)
    -- Use provided menu or default to submenu version
    local menu = targetMenu or StaffMenu.animator


    -- Sync with current staff menu states
    StaffMenu.animatorSettings.showNameTags = VFW.IsGamerTagsActive()
    StaffMenu.animatorSettings.noclipActive = VFW.IsNoclipActive()


    -- CHECKBOX MODE ANIMATEUR uniquement pour le standalone (F7)
    -- Depuis le menu admin, on a déjà le mode staff donc pas besoin d'activer le mode animateur
    if isStandalone then
        menu.Checkbox("MODE ANIMATEUR", nil, false, StaffMenu.animatorModeEnabled, function(_checked)
            StaffMenu.animatorModeEnabled = _checked

            -- Désactiver noclip si on quitte le mode
            if not _checked and VFW.IsNoclipActive() then
                VFW.ToggleNoclip()
            end

            -- Trigger server event pour toggle le mode animateur
            TriggerServerEvent("vfw:animator:mode", _checked)

            -- Auto-toggle HUD animateur
            if _checked then
                local hideHudPreference = GetResourceKvpString("animator_hide_web_hud") == "true"
              if not hideHudPreference then
                    if ToggleAnimatorHUD then ToggleAnimatorHUD(true) end
                    if initAnimatorHud then initAnimatorHud() end
                end

                local savedTagState = GetResourceKvpString("staff_gamer_tags")
                if savedTagState == "true" and not VFW.IsGamerTagsActive() then
                    TriggerServerEvent("Admin:activeBlips", true)
                    TriggerServerEvent("Admin:gamerTag", true)
                    StaffMenu.animatorSettings.showNameTags = true
                end

                local savedNametagState = GetResourceKvpString("staff_name_tags")
                if savedNametagState == "true" then
                    StaffMenu.showRPNamesOnPlayerTags = true
                    VFW.UpdateAllGamerTags()
                end
            else
                if ToggleAnimatorHUD then ToggleAnimatorHUD(false) end
            end

            VFW.ShowNotification({
                type = 'STAFF',
                variant = _checked and 'SUCCESS' or 'INFO',
                title = 'EVE Animateur',
                subtitle = _checked and 'Mode Animation : Activé' or 'Mode Animation : Désactivé',
                message = _checked and "Vous avez activé le mode animation." or "Vous avez désactivé le mode animation."
          })

            if not _checked then
                -- Désactiver la tenue si elle était active
                if StaffMenu.animatorSettings.animatorOutfit then
                    StaffMenu.animatorSettings.animatorOutfit = false
                    TriggerServerEvent("vfw:staff:setAnimatorOutfit", false)
                end
                -- Désactiver les noms SEULEMENT si activés via l'animateur (pas via le menu Outils)
                -- On vérifie le KVP pour savoir si l'utilisateur a activé via Outils
                local savedTagState = GetResourceKvpString("staff_gamer_tags")
                local tagsEnabledViaOutils = savedTagState == "true"

              if StaffMenu.animatorSettings.showNameTags and not tagsEnabledViaOutils then
                    StaffMenu.animatorSettings.showNameTags = false
                    TriggerServerEvent("Admin:gamerTag", false)
                    TriggerServerEvent("Admin:activeBlips", false)
                else
                    -- Juste reset le flag sans désactiver les gamertags
                    StaffMenu.animatorSettings.showNameTags = false
                end
            end

            -- Set le flag pour éviter que OnOpen reset la valeur
            isAnimatorMenuRefreshing = true
            menu.refresh()
        end)

        -- Si pas en mode animateur (standalone), afficher message et bloquer le reste
        if not StaffMenu.animatorModeEnabled then
            menu.Textbox(
                "Activer le mode animation pour accéder aux outils d'animateur",
                "Information")
            return -- Ne pas construire le reste du menu
        end
    end

    -- ========== RESTE DU MENU ==========

    -- Select the correct submenus based on standalone mode (for correct back navigation)
    local reportsMenu = isStandalone and StaffMenu.animatorStandaloneReports or StaffMenu.animatorReports
    local optionsMenu = isStandalone and StaffMenu.animatorStandaloneOptions or StaffMenu.animatorOptions
    local actionsMenu = isStandalone and StaffMenu.animatorStandaloneActions or StaffMenu.animatorActions
    local giveItemMenu = isStandalone and StaffMenu.animatorStandaloneGiveItem or StaffMenu.animatorGiveItem
    local vehiclesMenu = isStandalone and StaffMenu.animatorStandaloneVehicles or StaffMenu.animatorVehicles
    local pedManagementMenu = isStandalone and StaffMenu.animatorStandalonePedManagement or StaffMenu.animatorPedManagement

    local animReportCount = VFW.AnimatorReports and #VFW.AnimatorReports or 0
    local animReportLabel = animReportCount > 0 and (":document: REPORTS ANIMATION (%d)"):format(animReportCount) or ":document: REPORTS ANIMATION"
  menu.Button(animReportLabel, "Consulter et prendre en charge les reports des joueurs animateurs", nil, "chevron", false, function()
        if reportsMenu and reportsMenu.open then
            reportsMenu.open()
        end
    end)

    menu.Button(":settings: OPTIONS ANIMATEUR", "Tenue, HUD, notifications, messages et annonces", nil, "chevron", false, function()
    end, optionsMenu)

    menu.Button(":bolt: ACTIONS PERSONNELLES", "Noclip, affichage des noms et outils rapides", nil, "chevron", false, function()
    end, actionsMenu)

    menu.Button(":gift: DONNER ITEM TEMPORAIRE", "Donner un item temporaire à un joueur ou à tous dans un rayon", nil, "chevron", false, function()
    end, giveItemMenu)

    menu.Button(":car: GESTION VÉHICULES", "Spawner et customiser des véhicules pour les events", nil, "chevron", false, function()
    end, vehiclesMenu)

    menu.Button(":user: GESTION DES PEDS", "Changer votre apparence (ped, animal, personnage...)", nil, "chevron", false, function()
    end, pedManagementMenu)

    if VFW.PlayerGlobalData.permissions and (VFW.PlayerGlobalData.permissions["menu_event"] or VFW.PlayerGlobalData.permissions["menu_anim"]) then
        menu.Button(":mask: MENU ÉVENT", "Accéder aux outils de création et gestion d'événements", nil, "chevron", false, function()
            StaffMenu.events.parent = menu
            StaffMenu._eventsParentMenu = menu
        end, StaffMenu.events)
    end

end

-- Build OPTIONS ANIMATEUR submenu
function StaffMenu.BuildAnimatorOptionsMenu(isStandalone)
    local menu = isStandalone and StaffMenu.animatorStandaloneOptions or StaffMenu.animatorOptions
    local announceMenu = isStandalone and StaffMenu.animatorStandaloneAnnounce or StaffMenu.animatorAnnounce

    menu.Checkbox(":briefcase: TENUE ANIMATEUR", "Mettre la tenue d'animateur et masquer votre identité en jeu", false, StaffMenu.animatorSettings.animatorOutfit, function(_checked)
        StaffMenu.animatorSettings.animatorOutfit = _checked
        TriggerServerEvent("vfw:staff:setAnimatorOutfit", _checked)
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Options Animateur', message = _checked and "Tenue animateur activée." or "Tenue personnelle restaurée." })
    end)

    local currentHudState = GetResourceKvpString("animator_hide_web_hud") ~= "true"
  menu.Checkbox(":monitor: HUD ANIMATEUR", "Afficher ou masquer le HUD animateur à l'écran", false, currentHudState, function(_checked)
        SetResourceKvp("animator_hide_web_hud", _checked and "false" or "true")
        if _checked then
            if ToggleAnimatorHUD then ToggleAnimatorHUD(true) end
            if initAnimatorHud then initAnimatorHud() end
        else
            if ToggleAnimatorHUD then ToggleAnimatorHUD(false) end
        end
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Options Animateur', message = _checked and "HUD Animateur activé." or "HUD Animateur désactivé." })
    end)

    menu.Checkbox(":bell: DÉSACTIVER NOTIF REPORTS", "Masquer les notifications de nouveaux reports animation en temps réel", false, StaffMenu.animatorSettings.disableReportNotifications, function(_checked)
        StaffMenu.animatorSettings.disableReportNotifications = _checked
        SetResourceKvp("animator_disable_notifications", _checked and "true" or "false")
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'INFO' or 'SUCCESS', subtitle = 'Options Animateur', message = _checked and "Notifications désactivées." or "Notifications activées." })
    end)

    menu.Button(":chat: MESSAGE CHAT ANIMATEUR", "Envoyer un message dans le chat visible par le staff et les animateurs", nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Message chat animateur", "")
        if not input or input == "" then return end
        TriggerServerEvent("vfw:animator:sendChatMessage", input)
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = 'SUCCESS', subtitle = 'Chat Animateur', message = "Votre message a bien été envoyé." })
    end)

    menu.Button(":megaphone: ANNONCES", "Envoyer une annonce aux joueurs en radius ou sur tout le serveur", nil, "chevron", false, function()
    end, announceMenu)
end

function StaffMenu.BuildAnimatorActionsMenu(isStandalone)
    local menu = isStandalone and StaffMenu.animatorStandaloneActions or StaffMenu.animatorActions

    menu.Checkbox(":rocket: NOCLIP", "Voler librement à travers les murs et le décor. Raccourci : F2", false, StaffMenu.animatorSettings.noclipActive, function(_checked)
        VFW.ToggleNoclip()
        Wait(100)
        StaffMenu.animatorSettings.noclipActive = VFW.IsNoclipActive()
    end)

    menu.Checkbox(":eye: INVISIBILITÉ", "Rendre votre personnage invisible aux autres joueurs", false, animActionsState.invisible, function(_checked)
        animActionsState.invisible = _checked
        SetEntityVisible(PlayerPedId(), not _checked, false)
        TriggerServerEvent("vfw:stafflogs:invisibleState", _checked)
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Mode Animateur', message = _checked and "Invisibilité activée." or "Invisibilité désactivée." })
    end)

    menu.Button(":flag: TP MARKER", "Se téléporter instantanément sur votre point GPS actif", nil, "arrow", false, function()
        TriggerEvent("vfw:tpm")
    end)
    menu.Button(":pin: TÉLÉPORTATION", "Accéder aux options de téléportation (marker, plaque, coords, lieux)", nil, "chevron", false, function()
    end, StaffMenu.personalTeleport)

    menu.Button(":car: ALLER AU VÉHICULE", "Se téléporter vers un véhicule par sa plaque d'immatriculation", nil, "arrow", false, function()
        VFW.Nui.Focus(true)
        local plate = VFW.Nui.KeyboardInput(true, "Plaque d'immatriculation", "", 8)
        if plate == nil or plate == "" or plate == "KBD_CANCEL" then return end
        plate = string.upper(VFW.Math.Trim(plate))
        TriggerServerEvent("vfw:staff:gotoVehicle", plate)
    end)

    menu.Button(":bolt: RAMENER UN VÉHICULE", "Téléporter un véhicule vers soi par sa plaque d'immatriculation", nil, "arrow", false, function()
        VFW.Nui.Focus(true)
        local plate = VFW.Nui.KeyboardInput(true, "Plaque d'immatriculation", "", 8)
        if plate == nil or plate == "" or plate == "KBD_CANCEL" then return end
        plate = string.upper(VFW.Math.Trim(plate))
        TriggerServerEvent("vfw:staff:bringVehicle", plate)
    end)

    menu.Separator(nil)

    menu.Checkbox(":tag: GAMERTAGS", "Afficher les tags des joueurs avec leur ID au-dessus de leur tête", false, VFW.IsGamerTagsActive(), function(_checked)
        SetResourceKvp("staff_gamer_tags", _checked and "true" or "false")
        TriggerServerEvent("Admin:activeBlips", _checked)
        TriggerServerEvent("Admin:gamerTag", _checked)
        if StaffMenu.animatorSettings then StaffMenu.animatorSettings.showNameTags = _checked end
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Mode Animateur', message = _checked and "Gamertags activés." or "Gamertags désactivés." })
    end)

    menu.Checkbox(" NAMETAGS", "Afficher les noms RP des joueurs au-dessus de leur tête", false, StaffMenu.showRPNamesOnPlayerTags or false, function(_checked)
        StaffMenu.showRPNamesOnPlayerTags = _checked
        SetResourceKvp("staff_name_tags", _checked and "true" or "false")
        VFW.UpdateAllGamerTags()
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Mode Animateur', message = _checked and "Nametags activés." or "Nametags désactivés." })
    end)

    menu.Checkbox(":pin: AFFICHER COORDONNÉES", "Afficher vos coordonnées X Y Z en temps réel à l'écran", false, StaffMenu.outilsState and StaffMenu.outilsState.showCoords or false, function(_checked)
        if StaffMenu.outilsState then StaffMenu.outilsState.showCoords = _checked end
        StaffMenu.EnableCoords(_checked)
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Mode Animateur', message = _checked and "Coordonnées activées." or "Coordonnées désactivées." })
    end)

    menu.Checkbox(":signal: BLIPS JOUEURS", "Afficher les blips des joueurs sur la minimap dans un rayon de 1km", false, animActionsState.blipsActive, function(_checked)
        animActionsState.blipsActive = _checked
        if _checked and not animActionsState.blipsThread then
            animActionsState.blipsThread = true
            animActionsState.playerBlips = {}
            CreateThread(function()
                while animActionsState.blipsActive do
                    local myCoords = GetEntityCoords(PlayerPedId())
                    local activePlayers = GetActivePlayers()
                    local newBlips = {}
                    for _, playerId in ipairs(activePlayers) do
                        if playerId ~= PlayerId() then
                            local targetPed = GetPlayerPed(playerId)
                            if DoesEntityExist(targetPed) then
                                local dist = #(myCoords - GetEntityCoords(targetPed))
                                if dist <= 1000.0 then
                                    local serverId = GetPlayerServerId(playerId)
                                    local blip = animActionsState.playerBlips[serverId]
                                    if not blip or not DoesBlipExist(blip) then
                                        blip = AddBlipForEntity(targetPed)
                                        SetBlipSprite(blip, 1)
                                        SetBlipScale(blip, 0.5)
                                        SetBlipColour(blip, 0)
                                        SetBlipAsShortRange(blip, true)
                                        BeginTextCommandSetBlipName("STRING")
                                        AddTextComponentString(GetPlayerName(playerId) .. " [" .. serverId .. "]")
                                        EndTextCommandSetBlipName(blip)
                                    end
                                    newBlips[serverId] = blip
                                end
                            end
                        end
                    end
                    for serverId, blip in pairs(animActionsState.playerBlips) do
                        if not newBlips[serverId] and DoesBlipExist(blip) then RemoveBlip(blip) end
                    end
                    animActionsState.playerBlips = newBlips
                    Wait(2000)
                end
                for _, blip in pairs(animActionsState.playerBlips or {}) do
                    if DoesBlipExist(blip) then RemoveBlip(blip) end
                end
                animActionsState.playerBlips = {}
                animActionsState.blipsThread = false
            end)
        end
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Mode Animateur', message = _checked and "Blips joueurs activés (rayon 1km)." or "Blips joueurs désactivés." })
    end)

    menu.Separator(nil)

    menu.List(":cart: REMPLIR", "Remplir votre faim, votre soif ou les deux en une action", false, { "Faim", "Soif", "Les deux" }, 3, function(index, item)
        local need = item == "Faim" and "hunger" or (item == "Soif" and "thirst" or "both")
        TriggerServerEvent("vfw:staff:selfFillNeeds", need)
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = 'SUCCESS', subtitle = 'Mode Animateur', message = item == "Les deux" and "Faim et soif remplies." or (item .. " remplie.") })
    end)

    menu.Button(":heart: SE HEAL", "Restaurer votre santé au maximum", nil, "heart", false, function()
        SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = 'SUCCESS', subtitle = 'Mode Animateur', message = "Santé régénérée." })
    end)

    menu.Button(":dot-green: SE REVIVE", "Se ranimer si vous êtes mort ou KO", nil, "heart", false, function()
        TriggerServerEvent("vfw:staff:revivePlayer", GetPlayerServerId(PlayerId()))
    end)

    menu.Button(":skull: SE KILL", "Se suicider immédiatement", nil, "arrow", false, function()
        VFW.DeathOverrideCause = "suicide"
      SetEntityHealth(PlayerPedId(), 0)
        TriggerServerEvent("vfw:stafflogs:selfKill")
        VFW.ShowNotification({ type = 'STAFF', title = 'EVE Animateur', variant = 'INFO', subtitle = 'Mode Animateur', message = "Vous vous êtes tué." })
    end)
end

-- Build animator reports menu
function StaffMenu.BuildAnimatorReportsMenu(isStandalone)

    -- Select correct menus based on mode
    local reportsMenu = isStandalone and StaffMenu.animatorStandaloneReports or StaffMenu.animatorReports
    local reportMenu = isStandalone and StaffMenu.animatorStandaloneReport or StaffMenu.animatorReport

    if not VFW.AnimatorReports then
        VFW.AnimatorReports = {}
    end

    local haveReports = false

    for k, v in pairs(VFW.AnimatorReports) do
        if not haveReports then
            haveReports = true
        end

        local playerName = (v.player and v.player.name) or "UNKNOWN_NAME"
      local status = v.takenByName and "Pris en charge" or "Non pris en charge"
      local displayName = playerName .. " | " .. (v.takenByName and ("Pris par " .. v.takenByName) or "Non pris en charge")

        -- Pastille couleur selon l'ancienneté du report (vert < 5min, orange 5-8min, rouge 8min+)
        local dot = ":dot-green:"
      if v.timestamp and v.serverTime then
            local elapsedMin = math.floor((v.serverTime - v.timestamp) / 60)
            if elapsedMin >= 8 then
                dot = ":dot-red:"
          elseif elapsedMin >= 5 then
                dot = ":dot-orange:"
          end
        end

        if k == 1 then
            reportsMenu.ReportPreview(
                v.id,
                v.date,
                v.message,
                v.player and v.player.name or "Inconnu",
                tostring(v.player and v.player.source or "?"),
                v.player and v.player.id or "Inconnu",
                v.takenByName or nil
            )
        end

        local label = ":report: N°" .. v.id .. " | " .. status
        reportsMenu.Button(label, displayName, dot, nil, false, function()
            StaffMenu.animatorData.selectedPlayer = v.player.source
            StaffMenu.animatorData.reportInfo = v
            StaffMenu.animatorData.isStandalone = isStandalone -- Store for report menu
        end, reportMenu)
    end

    if not haveReports then
        reportsMenu.Textbox("Aucun report en cours ou en attente.", "📕 Reports")
    end
end

-- Build specific animator report menu
function StaffMenu.BuildAnimatorReportMenu(isStandalone)
    -- Use stored standalone state if not provided (from button callback)
    local standalone = isStandalone
    if standalone == nil then
        standalone = StaffMenu.animatorData.isStandalone
    end

    -- Select correct menus based on mode
    local reportMenu = standalone and StaffMenu.animatorStandaloneReport or StaffMenu.animatorReport
    local reportsMenu = standalone and StaffMenu.animatorStandaloneReports or StaffMenu.animatorReports

    if not StaffMenu.animatorData.reportInfo or not next(StaffMenu.animatorData.reportInfo) then
        reportMenu.Textbox("Ce report n'existe plus.", ":document: Report")
        return
    end

    local reportStillExists = false
    for _, r in ipairs(VFW.AnimatorReports or {}) do
        if r.id == StaffMenu.animatorData.reportInfo.id then
            reportStillExists = true
            StaffMenu.animatorData.reportInfo = r
            break
        end
    end

    if not reportStillExists then
        StaffMenu.animatorData.reportInfo = {}
        reportMenu.Textbox("Ce report a été fermé ou supprimé.", ":document: Report")
        return
    end

    if next(StaffMenu.animatorData.reportInfo) then
        local report = StaffMenu.animatorData.reportInfo
        local localPlayerId = GetPlayerServerId(PlayerId())

        reportMenu.ReportPreview(
            report.id,
            report.date,
            report.message,
            report.player and report.player.name or "Inconnu",
            tostring(report.player and report.player.source or "?"),
            report.player and report.player.id or "Inconnu",
            report.takenByName or nil
        )

        reportMenu.Separator(":bolt: ACTIONS")

        -- Menu principal pour retour si plus de reports
        local mainMenu = standalone and StaffMenu.animatorStandalone or StaffMenu.animator

        local playerName = report.player and report.player.name or "Inconnu"
      local playerSource = report.player and report.player.source or 0

        if not report.takenBy then
            reportMenu.Button(":document: PRENDRE LE REPORT", "Prendre en charge ce report et ouvrir le menu du joueur concerné", nil, "chevron", false, function()
                TriggerServerEvent("vfw:animator:takeReport", StaffMenu.animatorData.selectedPlayer)
                StaffMenu.PreparePlayerMenu(playerSource, reportMenu, nil, true)
            end, StaffMenu.player)
        else
            reportMenu.Button(":user: ACTIONS SUR LE JOUEUR", "Ouvrir le menu d'actions sur le joueur concerné par le report", nil, "chevron", false, function()
                StaffMenu.PreparePlayerMenu(playerSource, reportMenu, nil, true)
            end, StaffMenu.player)

            reportMenu.Button(":x: ABANDONNER LA PRISE EN CHARGE", "Libérer le report pour qu'un autre animateur puisse le prendre", nil, nil, false, function()
                TriggerServerEvent("vfw:animator:abandonReport", StaffMenu.animatorData.selectedPlayer)
                StaffMenu.animatorData.reportInfo = {}
                SetTimeout(150, function()
                    if #VFW.AnimatorReports == 0 then
                        mainMenu.open()
                    else
                        reportsMenu.open()
                    end
                end)
            end)
        end

        reportMenu.Button(":check: FERMER LE REPORT", "Marquer le report comme résolu et le retirer de la liste", nil, nil, false, function()
            local reportId = report.id
            TriggerServerEvent("vfw:animator:closeReport", StaffMenu.animatorData.selectedPlayer)
            StaffMenu.animatorData.reportInfo = {}
            SetTimeout(150, function()
                if #VFW.AnimatorReports == 0 then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'INFO',
                        title = 'EVE Animateur', subtitle = 'Mode Animateur',
                        message = "Plus aucun report en attente."
                  })
                    mainMenu.open()
                else
                    reportsMenu.open()
                end
            end)
        end)
    end
end

-- Build announcement menu
function StaffMenu.BuildAnimatorAnnounceMenu(isStandalone)
    local announceTypes = { "Radius", "Global" }
    local announceMenu = isStandalone and StaffMenu.animatorStandaloneAnnounce or StaffMenu.animatorAnnounce

    -- 1. LISTE EN PREMIER (en haut du menu)
    announceMenu.List("Type d'annonce", "Choisir si l'annonce est limitée à un rayon ou envoyée à tout le serveur", false, announceTypes, StaffMenu.animatorData.announceType, function(index)
        StaffMenu.animatorData.announceType = index
        announceMenu.refresh()
    end)

    -- 2. RADIUS seulement si type = Radius (index 1)
    if StaffMenu.animatorData.announceType == 1 then
        announceMenu.Button("RADIUS", "Définir le rayon d'envoi de l'annonce en mètres", tostring(StaffMenu.animatorData.announceRadius) .. " mètres", nil, false, function()
            local input = VFW.Nui.KeyboardInput(true, "Entrez le radius (en mètres)", tostring(StaffMenu.animatorData.announceRadius))
            if input and tonumber(input) then
                StaffMenu.animatorData.announceRadius = tonumber(input)
                announceMenu.refresh()
            end
        end)
    end

    -- 3. MESSAGE
    announceMenu.Button("MESSAGE", "Rédiger le message qui sera affiché aux joueurs concernés",
        (StaffMenu.animatorData.announceMessage == "" or StaffMenu.animatorData.announceMessage == nil) and "Cliquer pour définir" or StaffMenu.animatorData.announceMessage,
        nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Entrez votre message d'annonce", StaffMenu.animatorData.announceMessage or "")
        if input and input ~= "" then
            StaffMenu.animatorData.announceMessage = input
            announceMenu.refresh()
        end
    end)

    announceMenu.Separator()

    -- 4. ENVOYER
    local hasMessage = StaffMenu.animatorData.announceMessage ~= nil and StaffMenu.animatorData.announceMessage ~= ""
  announceMenu.Button("ENVOYER L'ANNONCE", "Envoyer l'annonce aux joueurs selon le type et le rayon choisi", nil, nil, not hasMessage, function()
        if not hasMessage then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Veuillez entrer un message."
          })
            return
        end

        local isGlobal = StaffMenu.animatorData.announceType == 2
        TriggerServerEvent("vfw:animator:announce",
            StaffMenu.animatorData.announceMessage,
            isGlobal,
            isGlobal and nil or StaffMenu.animatorData.announceRadius)

        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Annonce envoyée."
      })

        StaffMenu.animatorData.announceMessage = ""
      announceMenu.refresh()
    end)
end

-- Pagination settings
local ANIMATOR_ITEMS_PER_PAGE = 20

-- Build give item menu
function StaffMenu.BuildAnimatorGiveItemMenu(isStandalone)
    -- Select correct menus based on mode
    local giveItemMenu = isStandalone and StaffMenu.animatorStandaloneGiveItem or StaffMenu.animatorGiveItem
    local durationMenu = isStandalone and StaffMenu.animatorStandaloneGiveItemDuration or StaffMenu.animatorGiveItemDuration

    -- Store standalone state for duration menu
    StaffMenu.animatorData.giveItemIsStandalone = isStandalone

    local giveTypes = { "Joueur", "Radius" }

    -- Initialize pagination data
    StaffMenu.animatorData.currentPage = StaffMenu.animatorData.currentPage or 1

    -- 1. LISTE EN PREMIER (en haut du menu)
    giveItemMenu.List("Type de don", "Donner à un joueur spécifique ou à tous dans un rayon autour de vous", false, giveTypes, StaffMenu.animatorData.giveType, function(index)
        StaffMenu.animatorData.giveType = index
        giveItemMenu.refresh()
    end)

    -- 2. Bouton conditionnel selon le type sélectionné
    if StaffMenu.animatorData.giveType == 1 then
        -- Joueur sélectionné - afficher ID JOUEUR
        giveItemMenu.Button("ID JOUEUR",
            StaffMenu.animatorData.targetPlayerId and tostring(StaffMenu.animatorData.targetPlayerId) or "Non défini",
            nil, nil, false, function()
            local input = VFW.Nui.KeyboardInput(true, "Entrez l'ID du joueur", "")
            if input and tonumber(input) then
                StaffMenu.animatorData.targetPlayerId = tonumber(input)
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    title = 'EVE Animateur', subtitle = 'Mode Animateur',
                    message = "Cet identifiant n'est pas valide."
              })
            end
            giveItemMenu.refresh()
        end)
    else
        -- Radius sélectionné - afficher RADIUS
        giveItemMenu.Button("RADIUS", tostring(StaffMenu.animatorData.giveRadius) .. " mètres", nil, nil, false, function()
            local input = VFW.Nui.KeyboardInput(true, "Entrez le radius (max 100)", tostring(StaffMenu.animatorData.giveRadius))
            if input and tonumber(input) and tonumber(input) <= 100 then
                StaffMenu.animatorData.giveRadius = tonumber(input)
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    title = 'EVE Animateur', subtitle = 'Mode Animateur',
                    message = "Ce rayon n'est pas valide (100 au maximum)."
              })
            end
            giveItemMenu.refresh()
        end)
    end

    -- Item search
    local firstLabel = StaffMenu.animatorData.itemQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = StaffMenu.animatorData.itemQuery == nil and "UN ITEM" or StaffMenu.animatorData.itemQuery

    giveItemMenu.Button(firstLabel, lastLabel, nil, "search", false, function()
        if StaffMenu.animatorData.itemQuery ~= nil then
            StaffMenu.animatorData.itemQuery = nil
            StaffMenu.animatorData.currentPage = 1
            giveItemMenu.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if query == nil or query == "" then
            return
        end

        StaffMenu.animatorData.itemQuery = query
        StaffMenu.animatorData.currentPage = 1
        giveItemMenu.refresh()
    end)

    giveItemMenu.Separator()

    -- Check if items should be disabled (Player mode without ID)
    local isDisabled = (StaffMenu.animatorData.giveType == 1 and not StaffMenu.animatorData.targetPlayerId)

    -- Items restreints (potions) — masqués du menu animateur
    local restrictedItems = {
        potion_1 = true, potion_2 = true, potion_3 = true,
        potion_4 = true, potion_5 = true, potion_6 = true,
        potion_7 = true, potion_8 = true, potion_9 = true,
    }

    -- Build filtered items list
    local filteredItems = {}
    for itemName, item in pairs(VFW.Items) do
        if not restrictedItems[itemName] and
           (not StaffMenu.animatorData.itemQuery or
           string.find(string.lower(itemName), string.lower(tostring(StaffMenu.animatorData.itemQuery))) or
           string.find(string.lower(item.label), string.lower(tostring(StaffMenu.animatorData.itemQuery)))) then
            table.insert(filteredItems, { name = itemName, data = item })
        end
    end

    -- Sort items alphabetically by label
    table.sort(filteredItems, function(a, b)
        return a.data.label < b.data.label
    end)

    -- Calculate pagination
    local totalItems = #filteredItems
    local totalPages = math.ceil(totalItems / ANIMATOR_ITEMS_PER_PAGE)
    if totalPages == 0 then totalPages = 1 end

    -- Clamp current page
    if StaffMenu.animatorData.currentPage > totalPages then
        StaffMenu.animatorData.currentPage = totalPages
    end
    if StaffMenu.animatorData.currentPage < 1 then
        StaffMenu.animatorData.currentPage = 1
    end

    local startIndex = (StaffMenu.animatorData.currentPage - 1) * ANIMATOR_ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + ANIMATOR_ITEMS_PER_PAGE - 1, totalItems)

    -- Pagination controls
    if totalPages > 1 then
        giveItemMenu.Separator("Page " .. StaffMenu.animatorData.currentPage .. "/" .. totalPages, totalItems .. " items")

        -- Navigation buttons
        if StaffMenu.animatorData.currentPage > 1 then
            giveItemMenu.Button(":back: PAGE PRÉCÉDENTE", "Revenir à la page précédente de la liste d'items", nil, nil, isDisabled, function()
                StaffMenu.animatorData.currentPage = StaffMenu.animatorData.currentPage - 1
                giveItemMenu.refresh()
            end)
        end
        if StaffMenu.animatorData.currentPage < totalPages then
            giveItemMenu.Button("PAGE SUIVANTE :arrow:", "Aller à la page suivante de la liste d'items", nil, nil, isDisabled, function()
                StaffMenu.animatorData.currentPage = StaffMenu.animatorData.currentPage + 1
                giveItemMenu.refresh()
            end)
        end

        giveItemMenu.Separator()
    end

    -- Display paginated items
    for i = startIndex, endIndex do
        local itemEntry = filteredItems[i]
        if itemEntry then
            local itemName = itemEntry.name
            local item = itemEntry.data

            giveItemMenu.Button(item.label, itemName, item.weight .. " kg", "chevron", isDisabled, function()
                -- Validate target before opening duration menu
                if StaffMenu.animatorData.giveType == 1 and not StaffMenu.animatorData.targetPlayerId then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        title = 'EVE Animateur', subtitle = 'Mode Animateur',
                        message = "Veuillez spécifier un ID de joueur."
                  })
                    return
                end

                -- Store item data for duration menu
                StaffMenu.animatorData.selectedItemName = itemName
                StaffMenu.animatorData.selectedItemLabel = item.label
            end, durationMenu)
        end
    end

    -- Show message if no items found
    if totalItems == 0 then
        giveItemMenu.Separator("Aucun item", "trouvé")
    end
end

-- Build give item duration menu
function StaffMenu.BuildAnimatorGiveItemDurationMenu(isStandalone)
    -- Use stored standalone state if not provided
    local standalone = isStandalone
    if standalone == nil then
        standalone = StaffMenu.animatorData.giveItemIsStandalone
    end

    -- Select correct menu based on mode
    local durationMenu = standalone and StaffMenu.animatorStandaloneGiveItemDuration or StaffMenu.animatorGiveItemDuration

    local itemName = StaffMenu.animatorData.selectedItemName
    local itemLabel = StaffMenu.animatorData.selectedItemLabel or itemName

    if not itemName then
        durationMenu.Separator("Aucun item", "sélectionné")
        return
    end

    durationMenu.Title("Item:", itemLabel)
    durationMenu.Separator()

    -- Quantity selector
    local currentQty = StaffMenu.animatorData.selectedQuantity or 1
    durationMenu.Button("QUANTITÉ", "Nombre d'exemplaires à donner (1 à 100)", tostring(currentQty), nil, false, function()
        local input = VFW.Nui.KeyboardInput(true, "Quantité (1-100)", tostring(currentQty))
        local qty = tonumber(input)
        if qty and qty >= 1 and qty <= 100 then
            StaffMenu.animatorData.selectedQuantity = math.floor(qty)
            durationMenu.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', title = 'EVE Animateur', variant = 'ERROR', subtitle = 'Mode Animateur',
                message = "Cette quantité n'est pas valide (entre 1 et 100)."
          })
        end
    end)

    durationMenu.Separator()

    -- Helper function to give the item
    local function giveItem(duration)
        local quantity = StaffMenu.animatorData.selectedQuantity or 1
        if StaffMenu.animatorData.giveType == 1 then
            -- Give to player
            TriggerServerEvent("vfw:animator:giveItemTemp",
                StaffMenu.animatorData.targetPlayerId,
                itemName,
                quantity,
                duration)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Item donné au joueur."
          })
        else
            -- Give to radius
            TriggerServerEvent("vfw:animator:giveItemTemp",
                nil,
                itemName,
                quantity,
                duration,
                StaffMenu.animatorData.giveRadius)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Item donné aux joueurs dans le radius."
          })
        end
        durationMenu.close()
    end

    -- Custom duration button
    durationMenu.Button("DURÉE PERSONNALISÉE", "En minutes (max 60)", nil, nil, false, function()
        local duration = VFW.Nui.KeyboardInput(true, "Durée en minutes (max 60)", "60")
        local durationNum = tonumber(duration)
        if durationNum and durationNum > 0 then
            if durationNum > 60 then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    title = 'EVE Animateur', subtitle = 'Mode Animateur',
                    message = "La durée ne peut pas dépasser 60 minutes."
              })
                durationMenu.refresh()
                return
            end
            giveItem(durationNum)
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Cette durée n'est pas valide."
          })
            durationMenu.refresh()
        end
    end)

    -- Permanent until reboot button
    durationMenu.Button("JUSQU'AU REBOOT", "Item permanent", nil, nil, false, function()
        giveItem(-1)
    end)
end

-- Build vehicles menu
function StaffMenu.BuildAnimatorVehiclesMenu(isStandalone)
    -- Select correct menus based on mode
    local vehiclesMenu = isStandalone and StaffMenu.animatorStandaloneVehicles or StaffMenu.animatorVehicles
    local vehicleCustomMenu = isStandalone and StaffMenu.animatorStandaloneVehicleCustom or StaffMenu.animatorVehicleCustom

    vehiclesMenu.ClearItems()

    vehiclesMenu.Button(":car: SPAWN VÉHICULE", "Faire apparaître un véhicule à votre position en saisissant son nom de modèle GTA", nil, nil, false, function()
        local model = VFW.Nui.KeyboardInput(true, "Spawn Véhicule", "")
        if not model or model == "" then return end

        local hash = GetHashKey(model)
        if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Le modèle \"" .. model .. "\" est introuvable."
          })
            return
        end

        TriggerServerEvent("vfw:animator:spawnVehicle", model)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Véhicule " .. model .. " est apparu."
      })
    end)

    vehiclesMenu.Button(":trash: DV VÉHICULE", "Supprime le véhicule le plus proche dans un rayon de 2 mètres", nil, nil, false, function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local closestVehicle = nil
        local closestDist = 2.0

        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            local dist = #(playerCoords - GetEntityCoords(vehicle))
            if dist < closestDist then
                closestDist = dist
                closestVehicle = vehicle
            end
        end

        if closestVehicle then
            NetworkRequestControlOfEntity(closestVehicle)
            local attempts = 0
            while not NetworkHasControlOfEntity(closestVehicle) and attempts < 20 do
                Wait(10)
                attempts = attempts + 1
            end
            SetEntityAsMissionEntity(closestVehicle, true, true)
            DeleteVehicle(closestVehicle)
            if DoesEntityExist(closestVehicle) then
                DeleteEntity(closestVehicle)
            end
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Véhicule supprimé."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Aucun véhicule trouvé dans un rayon de 2 mètres."
          })
        end
    end)

    vehiclesMenu.Button(":wrench: MENU CUSTOM", "Ouvrir le menu de personnalisation du véhicule dans lequel vous êtes", nil, "chevron", false, function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if vehicle == 0 then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Vous devez être à bord d'un véhicule."
          })
            return
        end

        vehicleCustomMenu.open()
    end)

end

-- Build vehicle custom menu
function StaffMenu.BuildAnimatorVehicleCustomMenu(isStandalone)
    -- Select correct menu based on mode
    local vehicleCustomMenu = isStandalone and StaffMenu.animatorStandaloneVehicleCustom or StaffMenu.animatorVehicleCustom

    vehicleCustomMenu.ClearItems()

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    vehicleCustomMenu.Button(":hammer: RÉPARER", "Réparer la carrosserie, le moteur et remettre le véhicule en état", nil, nil, false, function()
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Véhicule réparé."
      })
    end)

    vehicleCustomMenu.Button(":trash: NETTOYER", "Supprimer toute la saleté et les traces sur le véhicule actuel", nil, nil, false, function()
        SetVehicleDirtLevel(vehicle, 0)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Véhicule nettoyé."
      })
    end)

    vehicleCustomMenu.Button(":palette: CHANGER LA COULEUR", "Permet de changer la couleur du véhicule, ce changement est temporaire", nil, nil, false, function()
        -- Get current colors from vehicle
        local pR, pG, pB = GetVehicleCustomPrimaryColour(vehicle)
        local sR, sG, sB = GetVehicleCustomSecondaryColour(vehicle)

        -- Open color picker with current colors
        vehicleCustomMenu.ColorPicker(
            pR or 0, pG or 0, pB or 0,  -- Primary color
            sR or 0, sG or 0, sB or 0,  -- Secondary color
            function(r, g, b)  -- Primary color callback (real-time)
                if DoesEntityExist(vehicle) then
                    SetVehicleCustomPrimaryColour(vehicle, r, g, b)
                end
            end,
            function(r, g, b)  -- Secondary color callback (real-time)
                if DoesEntityExist(vehicle) then
                    SetVehicleCustomSecondaryColour(vehicle, r, g, b)
                end
            end
        )
    end)

    vehicleCustomMenu.Button(":bolt: MAX UPGRADE", "Améliorer toutes les performances du véhicule au maximum en un clic, ce changement est temporaire", nil, nil, false, function()
        -- Upgrade vehicle to max
        SetVehicleModKit(vehicle, 0)

        -- Engine
        SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)
        -- Brakes
        SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)
        -- Transmission
        SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)
        -- Suspension
        SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false)
        -- Armor
        SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)
        -- Turbo
        ToggleVehicleMod(vehicle, 18, true)

        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Véhicule upgrade au maximum."
      })
    end)
end

-- Register menu callbacks
-- Submenu callback (from admin menu) - direct access, no MODE ANIMATEUR checkbox
StaffMenu.animator.OnOpen(function()
    StaffMenu.menuContext = 'animator'
    StaffMenu.BuildAnimatorMenu(StaffMenu.animator, false)
end)

-- Standalone menu callback (for F7 access - shows MODE ANIMATEUR checkbox, closes on back)
StaffMenu.animatorStandalone.OnOpen(function()
    StaffMenu.menuContext = 'animator'
    if not isAnimatorMenuRefreshing then
        StaffMenu.animatorModeEnabled = VFW.IsInAnimatorMode()
    end
    isAnimatorMenuRefreshing = false
    StaffMenu.BuildAnimatorMenu(StaffMenu.animatorStandalone, true)
end)

StaffMenu.animatorReports.OnOpen(function()
    StaffMenu.BuildAnimatorReportsMenu()
end)

StaffMenu.animatorReports.OnIndexChange(function(index, item)
    if not item or not item.props or not item.props.title then
        StaffMenu.animatorReports.CloseReportPreview()
        return
    end
    local reportId = tonumber(string.match(item.props.title, "%d+"))
    local report = nil
    for i = 1, #VFW.AnimatorReports do
        if VFW.AnimatorReports[i].id == reportId then
            report = VFW.AnimatorReports[i]
            break
        end
    end
    if not report then
        StaffMenu.animatorReports.CloseReportPreview()
        return
    end
    StaffMenu.animatorReports.ReportPreview(
        reportId,
        report.date,
        report.message,
        report.player and report.player.name or "Inconnu",
        tostring(report.player and report.player.source or "?"),
        report.player and report.player.id or "Inconnu",
        report.takenByName or nil
    )
end)

StaffMenu.animatorReports.OnClose(function()
    StaffMenu.animatorReports.CloseReportPreview()
end)

StaffMenu.animatorReport.OnOpen(function()
    StaffMenu.BuildAnimatorReportMenu()
end)

StaffMenu.animatorOptions.OnOpen(function()
    StaffMenu.BuildAnimatorOptionsMenu(false)
end)

StaffMenu.animatorActions.OnOpen(function()
    StaffMenu.BuildAnimatorActionsMenu(false)
end)

StaffMenu.animatorAnnounce.OnOpen(function()
    StaffMenu.BuildAnimatorAnnounceMenu()
end)

StaffMenu.animatorGiveItem.OnOpen(function()
    StaffMenu.BuildAnimatorGiveItemMenu()
end)

StaffMenu.animatorGiveItemDuration.OnOpen(function()
    StaffMenu.BuildAnimatorGiveItemDurationMenu()
end)

StaffMenu.animatorVehicles.OnOpen(function()
    StaffMenu.BuildAnimatorVehiclesMenu()
end)

StaffMenu.animatorVehicleCustom.OnOpen(function()
    StaffMenu.BuildAnimatorVehicleCustomMenu(false)
end)

-- Standalone submenus callbacks (for F7 access - correct back navigation)
StaffMenu.animatorStandaloneReports.OnOpen(function()
    StaffMenu.BuildAnimatorReportsMenu(true)
end)

StaffMenu.animatorStandaloneReports.OnIndexChange(function(index, item)
    if not item or not item.props or not item.props.title then
        StaffMenu.animatorStandaloneReports.CloseReportPreview()
        return
    end
    local reportId = tonumber(string.match(item.props.title, "%d+"))
    local report = nil
    for i = 1, #VFW.AnimatorReports do
        if VFW.AnimatorReports[i].id == reportId then
            report = VFW.AnimatorReports[i]
            break
        end
    end
    if not report then
        StaffMenu.animatorStandaloneReports.CloseReportPreview()
        return
    end
    StaffMenu.animatorStandaloneReports.ReportPreview(
        reportId,
        report.date,
        report.message,
        report.player and report.player.name or "Inconnu",
        tostring(report.player and report.player.source or "?"),
        report.player and report.player.id or "Inconnu",
        report.takenByName or nil
    )
end)

StaffMenu.animatorStandaloneReports.OnClose(function()
    StaffMenu.animatorStandaloneReports.CloseReportPreview()
end)

StaffMenu.animatorStandaloneReport.OnOpen(function()
    StaffMenu.BuildAnimatorReportMenu(true)
end)

StaffMenu.animatorStandaloneOptions.OnOpen(function()
    StaffMenu.BuildAnimatorOptionsMenu(true)
end)

StaffMenu.animatorStandaloneActions.OnOpen(function()
    StaffMenu.BuildAnimatorActionsMenu(true)
end)

StaffMenu.animatorStandaloneAnnounce.OnOpen(function()
    StaffMenu.BuildAnimatorAnnounceMenu(true)
end)

StaffMenu.animatorStandaloneGiveItem.OnOpen(function()
    StaffMenu.BuildAnimatorGiveItemMenu(true)
end)

StaffMenu.animatorStandaloneGiveItemDuration.OnOpen(function()
    StaffMenu.BuildAnimatorGiveItemDurationMenu(true)
end)

StaffMenu.animatorStandaloneVehicles.OnOpen(function()
    StaffMenu.BuildAnimatorVehiclesMenu(true)
end)

StaffMenu.animatorStandaloneVehicleCustom.OnOpen(function()
    StaffMenu.BuildAnimatorVehicleCustomMenu(true)
end)

StaffMenu.animatorStandalonePedManagement.OnOpen(function()
    StaffMenu.BuildAnimatorPedManagementMenu(true)
end)

StaffMenu.animatorStandalonePedList.OnOpen(function()
    StaffMenu.BuildAnimatorPedListMenu(true)
end)

-- Animator Ped Management data
local animatorPedData = {
    selectedCategory = 1,
    customModel = ""
}

local animatorPedCategories = {
    {
        name = "Personnages Principaux",
        peds = {
            {name = "Michael", model = "player_zero"},
            {name = "Franklin", model = "player_one"},
            {name = "Trevor", model = "player_two"},
            {name = "MP Male", model = "mp_m_freemode_01"},
            {name = "MP Female", model = "mp_f_freemode_01"}
        }
    },
    {
        name = "Animaux",
        peds = {
            {name = "Chien Berger", model = "a_c_shepherd"},
            {name = "Chat", model = "a_c_cat_01"},
            {name = "Chien Husky", model = "a_c_husky"},
            {name = "Chien Retriever", model = "a_c_retriever"},
            {name = "Rottweiler", model = "a_c_rottweiler"},
            {name = "Carlin", model = "a_c_pug"},
            {name = "Cochon", model = "a_c_pig"},
            {name = "Sanglier", model = "a_c_boar"},
            {name = "Poulet", model = "a_c_hen"},
            {name = "Chimpanzé", model = "a_c_chimp"},
            {name = "Vache", model = "a_c_cow"},
            {name = "Coyote", model = "a_c_coyote"},
            {name = "Cerf", model = "a_c_deer"},
            {name = "Aigle", model = "a_c_chickenhawk"},
            {name = "Corbeau", model = "a_c_crow"},
            {name = "Dauphin", model = "a_c_dolphin"},
            {name = "Mouette", model = "a_c_seagull"},
            {name = "Requin", model = "a_c_sharktiger"},
            {name = "Lapin", model = "a_c_rabbit_01"}
        }
    },
    {
        name = "Services d'urgence",
        peds = {
            {name = "Policier", model = "s_m_y_cop_01"},
            {name = "Policière", model = "s_f_y_cop_01"},
            {name = "Sheriff", model = "s_m_y_sheriff_01"},
            {name = "Sheriff Femme", model = "s_f_y_sheriff_01"},
            {name = "SWAT", model = "s_m_y_swat_01"},
            {name = "Pompier", model = "s_m_y_fireman_01"},
            {name = "Paramédic", model = "s_m_m_paramedic_01"},
            {name = "Médecin", model = "s_m_m_doctor_01"},
            {name = "Marine", model = "s_m_m_marine_01"},
            {name = "Ranger", model = "s_m_y_ranger_01"},
            {name = "Prisonnier", model = "s_m_y_prisoner_01"},
            {name = "Garde", model = "s_m_m_prisguard_01"},
            {name = "Sécurité", model = "s_m_m_security_01"},
            {name = "Armée", model = "s_m_y_blackops_01"}
        }
    },
    {
        name = "Gangs",
        peds = {
            {name = "Ballas 01", model = "g_m_y_ballaorig_01"},
            {name = "Ballas 02", model = "g_m_y_ballaeast_01"},
            {name = "Families 01", model = "g_m_y_famca_01"},
            {name = "Families 02", model = "g_m_y_famdnf_01"},
            {name = "Vagos 01", model = "g_m_y_mexgang_01"},
            {name = "Vagos 02", model = "g_m_y_mexgoon_01"},
            {name = "Lost MC 01", model = "g_m_y_lost_01"},
            {name = "Lost MC 02", model = "g_m_y_lost_02"},
            {name = "Korean 01", model = "g_m_y_korean_01"},
            {name = "Korean 02", model = "g_m_y_korean_02"},
            {name = "Aztecas", model = "g_m_y_azteca_01"},
            {name = "Marabunta", model = "g_m_y_salvagoon_01"}
        }
    },
    {
        name = "Civils",
        peds = {
            {name = "Hipster Male", model = "a_m_y_hipster_01"},
            {name = "Hipster Female", model = "a_f_y_hipster_01"},
            {name = "Business Male", model = "a_m_y_business_01"},
            {name = "Business Female", model = "a_f_y_business_01"},
            {name = "Beach Male", model = "a_m_y_beach_01"},
            {name = "Beach Female", model = "a_f_y_beach_01"},
            {name = "Bodybuilder", model = "a_m_y_musclbeac_01"},
            {name = "Jogger Male", model = "a_m_y_runner_01"},
            {name = "Jogger Female", model = "a_f_y_runner_01"},
            {name = "Skater", model = "a_m_y_skater_01"},
            {name = "Golfer", model = "a_m_y_golfer_01"},
            {name = "Hiker", model = "a_m_y_hiker_01"}
        }
    },
    {
        name = "Spéciaux",
        peds = {
            {name = "Zombie", model = "u_m_y_zombie_01"},
            {name = "Jesus", model = "u_m_m_jesus_01"},
            {name = "Clown", model = "s_m_y_clown_01"},
            {name = "Mime", model = "s_m_y_mime"},
            {name = "Astronaute", model = "s_m_m_movspace_01"},
            {name = "Alien", model = "s_m_m_movalien_01"},
            {name = "Bigfoot", model = "ig_orleans"},
            {name = "Stripper 01", model = "s_f_y_stripper_01"},
            {name = "Stripper 02", model = "s_f_y_stripper_02"},
            {name = "Père Noël", model = "s_m_m_movprem_01"}
        }
    }
}

-- Helper function to change ped model (animator version)
local function AnimatorChangePed(modelName)
    local model = GetHashKey(modelName)

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Ce modèle n'est pas valide: " .. modelName .. "."
      })
        return
    end

    RequestModel(model)
    local loadWait = 0
    while not HasModelLoaded(model) and loadWait < 5000 do
        Wait(50)
        loadWait = loadWait + 50
    end
    if not HasModelLoaded(model) then
        SetModelAsNoLongerNeeded(model)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Le modèle n'a pas pu être chargé à temps : " .. modelName .. "."
      })
        return
    end

    -- Freeze pendant le swap : sans ça le ped émet des updates de position
    -- pendant la destruction/recréation du net object → crash réseau côté
    -- voisins (GTA5+1691021 / september-ceiling-network).
    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), model)

    local newPed = PlayerPedId()
    local timeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and timeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        timeout = timeout + 1
    end
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(model)

    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
        SetEntityHealth(newPed, GetEntityMaxHealth(newPed))
    end

    VFW.ShowNotification({
        type = 'STAFF',
        variant = 'SUCCESS',
        title = 'EVE Animateur', subtitle = 'Mode Animateur',
        message = "Ped changé: " .. modelName .. "."
  })
end

-- Build Animator Ped Management Menu
function StaffMenu.BuildAnimatorPedManagementMenu(isStandalone)
    -- Select correct menus based on mode
    local pedManagementMenu = isStandalone and StaffMenu.animatorStandalonePedManagement or StaffMenu.animatorPedManagement
    local pedListMenu = isStandalone and StaffMenu.animatorStandalonePedList or StaffMenu.animatorPedList

    pedManagementMenu.Separator(":user: GESTION DES PEDS")

    -- Custom model input
    pedManagementMenu.Button(":mask: MODÈLE PERSONNALISÉ", animatorPedData.customModel ~= "" and animatorPedData.customModel or "Cliquez pour entrer", nil, "chevron", false, function()
        local model = VFW.Nui.KeyboardInput(true, "Nom du modèle de ped", animatorPedData.customModel)

        if model and model ~= "" then
            animatorPedData.customModel = model
            AnimatorChangePed(model)
        end
    end)

    -- Reset to default ped
    pedManagementMenu.Button(":refresh: RÉINITIALISER LE PED", nil, nil, "chevron", false, function()
        TriggerServerEvent("vfw:staff:resetPed")
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'INFO',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Ped réinitialisé."
      })
    end)

    -- Random ped
    pedManagementMenu.Button(":gamepad: PED ALÉATOIRE", nil, nil, "chevron", false, function()
        local randomCategory = animatorPedCategories[math.random(1, #animatorPedCategories)]
        local randomPed = randomCategory.peds[math.random(1, #randomCategory.peds)]
        AnimatorChangePed(randomPed.model)
    end)

    pedManagementMenu.Separator(":folder: CATÉGORIES")

    -- Ped categories
    for i, category in ipairs(animatorPedCategories) do
        pedManagementMenu.Button(":user: " .. category.name, string.format("%d peds", #category.peds), nil, "chevron", false, function()
            animatorPedData.selectedCategory = i
            animatorPedData.isStandalone = isStandalone
        end, pedListMenu)
    end

    pedManagementMenu.Separator(":palette: OPTIONS")

    -- Health
    pedManagementMenu.Button(":heart: RÉGÉNÉRER LA SANTÉ", nil, nil, "heart", false, function()
        SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Santé régénérée."
      })
    end)

    local hasArmor = GetPedArmour(PlayerPedId()) > 0
    pedManagementMenu.Button(hasArmor and ":shield: RETIRER ARMURE" or ":shield: DONNER ARMURE", nil, nil, "chevron", false, function()
        local p = PlayerPedId()
        if GetPedArmour(p) > 0 then
            SetPedArmour(p, 0)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Armure retirée."
          })
        else
            SetPedArmour(p, 100)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                title = 'EVE Animateur', subtitle = 'Mode Animateur',
                message = "Armure donnée."
          })
        end
        pedManagementMenu.refresh()
    end)

    -- Clean ped
    pedManagementMenu.Button(":trash: NETTOYER LE PED", nil, nil, "chevron", false, function()
        local playerPed = PlayerPedId()
        ClearPedBloodDamage(playerPed)
        ClearPedWetness(playerPed)
        ClearPedEnvDirt(playerPed)
        ResetPedVisibleDamage(playerPed)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Ped nettoyé."
      })
    end)
end

-- Build Animator Ped List Menu
function StaffMenu.BuildAnimatorPedListMenu(isStandalone)
    if isStandalone == nil then
        isStandalone = animatorPedData.isStandalone
    end

    local pedListMenu = isStandalone and StaffMenu.animatorStandalonePedList or StaffMenu.animatorPedList
    local category = animatorPedCategories[animatorPedData.selectedCategory]

    if not category then return end

    pedListMenu.Separator(category.name:upper())

    for _, ped in ipairs(category.peds) do
        pedListMenu.Button(":user: " .. ped.name, ped.model, nil, nil, false, function()
            AnimatorChangePed(ped.model)
        end)
    end
end

StaffMenu.animatorPedManagement.OnOpen(function()
    StaffMenu.BuildAnimatorPedManagementMenu()
end)

StaffMenu.animatorPedList.OnOpen(function()
    StaffMenu.BuildAnimatorPedListMenu()
end)