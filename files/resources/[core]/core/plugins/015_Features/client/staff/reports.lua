---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Reports = {}

local function sameReportId(a, b)
    if a == b then return true end
    local na, nb = tonumber(a), tonumber(b)
    return na ~= nil and nb ~= nil and na == nb
end

local function syncStaffHud()
    if RefreshStaffHudReports then
        RefreshStaffHudReports()
    end
end

local function refreshReportMenus()
    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
    if StaffMenu and StaffMenu.main and StaffMenu.main.opened then
        StaffMenu.main.refresh()
    end
    syncStaffHud()
end

---@param reports any
RegisterNetEvent("vfw:staff:reports", function(reports)
    VFW.Reports = reports or {}
    refreshReportMenus()
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

    refreshReportMenus()
end)

---@param id any
RegisterNetEvent("vfw:staff:deleteReport", function(id)
    for i = 1, #VFW.Reports do
        if VFW.Reports[i] and sameReportId(VFW.Reports[i].id, id) then
            table.remove(VFW.Reports, i)
            if sameReportId(VFW.lastReport, id) then
                VFW.lastReport = nil
            end
            break
        end
    end

    refreshReportMenus()
end)

---@param report any
RegisterNetEvent("vfw:staff:updateReport", function(report)
    for i, r in ipairs(VFW.Reports) do
        if sameReportId(r.id, report.id) then
            VFW.Reports[i] = report
            break
        end
    end

    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
    syncStaffHud()
end)

RegisterNetEvent("vfw:staff:refreshMenu", function()
    if StaffMenu and StaffMenu.reports and StaffMenu.reports.opened then
        StaffMenu.reports.refresh()
    end
end)
