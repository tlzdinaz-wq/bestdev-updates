---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Reports = {}
---@param reports any
RegisterNetEvent("vfw:staff:reports", function(reports)
    VFW.Reports = reports
end)

---@param report any
RegisterNetEvent("vfw:staff:report", function(report)
    table.insert(VFW.Reports, report)

    VFW.lastReport = nil
    VFW.lastReport = report.id

    SetTimeout(10000, function()
        if VFW.lastReport == report.id then
            VFW.lastReport = nil
        end
    end)

    -- Auto-refresh reports menu for all staff in service (only if menu is open)
    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
    -- Refresh main menu to update report counter
    if StaffMenu and StaffMenu.main and StaffMenu.main.opened then
        StaffMenu.main.refresh()
    end
end)

---@param id any
RegisterNetEvent("vfw:staff:deleteReport", function(id)
    for i = 1, #VFW.Reports do
        if VFW.Reports[i].id == id then
            table.remove(VFW.Reports, i)
            if VFW.lastReport == id then
                VFW.lastReport = nil
            end
            break
        end
    end

    -- Auto-refresh reports menu for all staff in service (only if menu is open)
    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
    -- Refresh main menu to update report counter
    if StaffMenu and StaffMenu.main and StaffMenu.main.opened then
        StaffMenu.main.refresh()
    end
end)

---@param report any
RegisterNetEvent("vfw:staff:updateReport", function(report)
    for i, r in ipairs(VFW.Reports) do
        if r.id == report.id then
            VFW.Reports[i] = report
            break
        end
    end

    -- Auto-refresh reports menu for all staff in service (only if menu is open)
    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
end)

RegisterNetEvent("vfw:staff:refreshMenu", function()
    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
end)
