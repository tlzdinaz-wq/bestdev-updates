---@meta _
---@diagnostic disable: duplicate-doc-field

--- .BuildReportMenu
function StaffMenu.BuildReportMenu()
    if not StaffMenu.data.reportInfo or not next(StaffMenu.data.reportInfo) then
        StaffMenu.report.Textbox("Ce report n'existe plus.", ":document: Report")
        StaffMenu.report.Button(":back: RETOUR", "Retourner à la liste des reports", nil, "chevron", false, function()
            exports["VUI"]:HandleBack()
        end)
        return
    end

    -- Vérifier que le report existe encore dans VFW.Reports
    local reportStillExists = false
    for _, r in ipairs(VFW.Reports) do
        if r.id == StaffMenu.data.reportInfo.id then
            reportStillExists = true
            -- Mettre à jour les données avec la version la plus récente
            StaffMenu.data.reportInfo = r
            break
        end
    end

    if not reportStillExists then
        StaffMenu.data.reportInfo = {}
        StaffMenu.report.Textbox("Ce report a été fermé ou supprimé.", ":document: Report")
        StaffMenu.report.Button(":back: RETOUR", "Retourner à la liste des reports", nil, "chevron", false, function()
            exports["VUI"]:HandleBack()
        end)
        return
    end

    local report = StaffMenu.data.reportInfo
    local player = report.player

    StaffMenu.report.ClearItems()

    StaffMenu.report.ReportPreview(
        report.id,
        report.date,
        report.message,
        player.name or "Inconnu",
        tostring(player.source or "?"),
        player.id or "Inconnu",
        report.takenByName or nil
    )

    StaffMenu.report.Separator(":bolt: ACTIONS")

    local playerName = player and player.name or "Inconnu"
  local playerSource = player and player.source or 0
    local adminBanner = exports["core"]:GetVUIBanner("admin")
    local VUI = exports["VUI"]

    StaffMenu.player = VUI:CreateSubMenu(StaffMenu.report, string.format("%s [%d]", playerName, playerSource), adminBanner, true)

    StaffMenu.wipe = VUI:CreateSubMenu(StaffMenu.player, "WIPE", adminBanner, true)
    StaffMenu.items = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES ITEMS", adminBanner, true)
    StaffMenu.AttachItemsMenuCallback()
    StaffMenu.jobs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES JOBS", adminBanner, true)
    StaffMenu.grades_jobs = VUI:CreateSubMenu(StaffMenu.jobs, "LISTE DES GRADES", adminBanner, true)
    StaffMenu.factions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES FACTIONS", adminBanner, true)
    StaffMenu.grades_factions = VUI:CreateSubMenu(StaffMenu.factions, "LISTE DES GRADES", adminBanner, true)
    StaffMenu.vehs = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES VÉHICULES", adminBanner, true)
    StaffMenu.vehs_owned = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOUEUR", adminBanner, true)
    StaffMenu.vehs_job = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DU JOB", adminBanner, true)
    StaffMenu.vehs_faction = VUI:CreateSubMenu(StaffMenu.vehs, "LISTE DES VÉHICULES DE FACTION", adminBanner, true)
    StaffMenu.vehicleActions = VUI:CreateSubMenu(StaffMenu.vehs_owned, "ACTIONS VÉHICULE", adminBanner, true)
    StaffMenu.playerSanctions = VUI:CreateSubMenu(StaffMenu.player, "LISTE DES SANCTIONS", adminBanner, true)
    StaffMenu.playerLicense = VUI:CreateSubMenu(StaffMenu.player, "DONNER UN PERMIS", adminBanner, true)
    StaffMenu.playerGiveItem = VUI:CreateSubMenu(StaffMenu.player, "DONNER UN ITEM", adminBanner, true)

    StaffMenu.player.OnOpen(function()
        StaffMenu.animatorPlayerContext = false
        StaffMenu.data.selectedPlayer = playerSource
        StaffMenu.data.playerInfo = TriggerServerCallback("vfw:staff:getPlayerInfo", playerSource) or {}
        StaffMenu.data.playerList = TriggerServerCallback("vfw:staff:getPlayerList") or {}
        StaffMenu.data.jobsList = TriggerServerCallback("vfw:staff:getJobs") or {}
        StaffMenu.data.factionsList = TriggerServerCallback("core:staff:getOrganizations") or {}
        StaffMenu.data.sanctionsPlayerList = TriggerServerCallback("vfw:staff:getPlayerSanctions",
            playerSource, StaffMenu.data.playerInfo.identifier, StaffMenu.data.playerInfo.discord) or {}
        StaffMenu.BuildPlayerMenu()
    end)
    StaffMenu.jobs.OnOpen(function() StaffMenu.BuildJobsMenu() end)
    StaffMenu.grades_jobs.OnOpen(function() StaffMenu.BuildGradesJobsMenu() end)
    StaffMenu.factions.OnOpen(function() StaffMenu.BuildFactionsMenu() end)
    StaffMenu.grades_factions.OnOpen(function() StaffMenu.BuildGradesFactionsMenu() end)
    StaffMenu.vehs.OnOpen(function() StaffMenu.BuildVehsMenu() end)
    StaffMenu.vehs_owned.OnOpen(function() StaffMenu.BuildVehsOwnedMenu() end)
    StaffMenu.vehs_job.OnOpen(function() StaffMenu.BuildVehsJobMenu() end)
    StaffMenu.vehs_faction.OnOpen(function() StaffMenu.BuildVehsFactionMenu() end)
    StaffMenu.vehicleActions.OnOpen(function() StaffMenu.BuildVehicleActionsMenu() end)
    StaffMenu.playerSanctions.OnOpen(function() StaffMenu.BuildPlayerSanctionsMenu() end)
    StaffMenu.playerLicense.OnOpen(function() StaffMenu.BuildPlayerLicenseMenu() end)
    StaffMenu.playerGiveItem.OnOpen(function()
        StaffMenu.playerGiveItem.ClearItems()
        StaffMenu.BuildPlayerGiveItemMenu()
    end)
    StaffMenu.wipe.OnOpen(function() StaffMenu.BuildWipeMenu() end)

    if not report.takenBy then
        StaffMenu.report.Button(":document: PRENDRE LE REPORT", "Prendre en charge ce report et ouvrir le menu du joueur concerné", nil, "chevron", false, function()
            TriggerServerEvent("vfw:staff:takeReport", StaffMenu.data.selectedPlayer)
        end, StaffMenu.player)
    else
        StaffMenu.report.Button(":user: ACTIONS SUR LE JOUEUR", "Ouvrir le menu d'actions sur le joueur concerné par le report", nil, "chevron", false, function()
        end, StaffMenu.player)

        StaffMenu.report.Button(":x: ABANDONNER LA PRISE EN CHARGE", "Libérer le report sans le fermer pour qu'un autre staff le prenne", nil, nil, false, function()
            TriggerServerEvent("vfw:staff:abandonReport", StaffMenu.data.selectedPlayer)
            StaffMenu.data.reportInfo = {}
            StaffMenu.report.close()
            SetTimeout(300, function()
                StaffMenu.reports.open()
            end)
            return false
        end)
    end

    StaffMenu.report.Button(":check: FERMER LE REPORT", "Marquer le report comme traité et clôturer la fiche", nil, nil, false, function()
        TriggerServerEvent("vfw:staff:closeReport", StaffMenu.data.selectedPlayer)
        StaffMenu.data.reportInfo = {}
        StaffMenu.report.close()
        SetTimeout(300, function()
            StaffMenu.reports.open()
        end)
        return false
    end)
end
