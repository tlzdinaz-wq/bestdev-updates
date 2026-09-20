---@meta _
---@diagnostic disable: duplicate-doc-field

--- .BuildReportsMenu
function StaffMenu.BuildReportsMenu()
    StaffMenu.reports.ClearItems()
    local haveReports = false

    for k, v in pairs(VFW.Reports) do
        if not haveReports then
            haveReports = true
        end

        local playerName = v.player.name or "UNKNOWN_NAME"
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
            StaffMenu.reports.ReportPreview(
                v.id,
                v.date,
                v.message,
                v.player.name or "Inconnu",
                tostring(v.player.source or "?"),
                v.player.id or "Inconnu",
                v.takenByName or nil
            )
        end

        local label = ":report: N°" .. v.id .. " | " .. status
        StaffMenu.reports.Button(label, displayName, dot, nil, false, function()
            StaffMenu.data.selectedPlayer = v.player.source
            StaffMenu.data.reportInfo = v
        end, StaffMenu.report)
    end

    if not haveReports then
        StaffMenu.reports.Textbox("Aucun report en cours ou en attente.", "📕 Reports")
    end
end
