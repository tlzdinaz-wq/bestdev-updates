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

    local playerSource = player and player.source or 0

    if not report.takenBy then
        StaffMenu.report.Button(":document: PRENDRE LE REPORT", "Prendre en charge ce report et ouvrir le menu du joueur concerné", nil, "chevron", false, function()
            TriggerServerEvent("vfw:staff:takeReport", StaffMenu.data.selectedPlayer)
            StaffMenu.PreparePlayerMenu(playerSource, StaffMenu.report, nil, false)
        end, StaffMenu.player)
    else
        StaffMenu.report.Button(":user: ACTIONS SUR LE JOUEUR", "Ouvrir le menu d'actions sur le joueur concerné par le report", nil, "chevron", false, function()
            StaffMenu.PreparePlayerMenu(playerSource, StaffMenu.report, nil, false)
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
