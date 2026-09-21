---@meta _
---@diagnostic disable: duplicate-doc-field

local staffHudVisible = false
local onlineStaffs = 0
local staffsInService = 0
local hudInitialized = false

local function reportCount()
    if VFW and type(VFW.Reports) == "table" then
        return #VFW.Reports
    end
    return 0
end

-- Update NUI with current data
local function UpdateStaffHudNUI()
    local n = reportCount()
    SendNUIMessage({
        action = "staffHud:update",
        data = {
            visible = staffHudVisible,
            reports = n,
            reportsStr = tostring(n),
            hasReports = n > 0 and 1 or 0,
            onlineStaffs = onlineStaffs > 0 and onlineStaffs or 1,
            staffsInService = staffsInService > 0 and staffsInService or 1
        }
    })
end

-- Même source que le menu Reports (VFW.Reports), pour ne pas rester à 1 après fermeture.
_G.RefreshStaffHudReports = function()
    UpdateStaffHudNUI()
end

local function refreshHudSoon()
    SetTimeout(0, function()
        UpdateStaffHudNUI()
    end)
end

-- Toggle HUD visibility
_G.IsStaffHUDVisible = function()
    return staffHudVisible
end

_G.ToggleStaffHUD = function(state)
    staffHudVisible = state
    SendNUIMessage({
        action = "staffHud:toggle",
        data = state
    })
    if state then
        UpdateStaffHudNUI()
    end
end

-- Make functions global explicitly
_G.initStaffHud = function()
    if hudInitialized then
        return
    end
    hudInitialized = true
    UpdateStaffHudNUI()
end

-- HUD Configuration Menu
function StaffMenu.BuildHUDConfigMenu()
    StaffMenu.hudConfig.Separator("CONFIGURATION HUD STAFF")

    StaffMenu.hudConfig.Checkbox("Afficher HUD", nil, false, staffHudVisible, function(_checked)
        ToggleStaffHUD(_checked)
    end)
end

-- Update staff data (online staffs, etc.)
RegisterNetEvent('vfw:staff:sendStaffsData', function(staffData)
    if not staffData then return end

    if staffData.onlineStaffs then
        onlineStaffs = staffData.onlineStaffs
    end

    if staffData.staffsInService then
        staffsInService = staffData.staffsInService
    end

    UpdateStaffHudNUI()
end)

RegisterNetEvent('vfw:staff:reports', function()
    refreshHudSoon()
end)

RegisterNetEvent('vfw:staff:report', function()
    refreshHudSoon()
end)

RegisterNetEvent('vfw:staff:deleteReport', function()
    refreshHudSoon()
end)

-- Auto-enable HUD when staff mode is activated
RegisterNetEvent("vfw:staff:modeChanged", function(enabled)
    if enabled then
        ToggleStaffHUD(true)
        initStaffHud()
        -- Request current reports from server when entering staff mode
        TriggerServerEvent("vfw:staff:requestReports")
    else
        ToggleStaffHUD(false)
    end
end)

-- Apply the "keep HUD visible while off-duty" preference. Called when staff
-- mode is toggled off and at resource start so report counts keep updating
-- for staffs who opted in.
_G.ApplyHudOffDutyPreference = function()
    if StaffMenu and StaffMenu.adminChecked then return end
    local enabled = GetResourceKvpString("staff_hud_offduty") == "true"
  local hideHud = GetResourceKvpString("staff_hide_web_hud") == "true"
  if enabled and not hideHud then
        TriggerServerEvent("vfw:staff:setHudOffDuty", true)
        initStaffHud()
        ToggleStaffHUD(true)
    else
        TriggerServerEvent("vfw:staff:setHudOffDuty", false)
        ToggleStaffHUD(false)
    end
end

-- Initialize HUD on resource start if already in staff mode
CreateThread(function()
    Wait(1000)
    if StaffMenu and StaffMenu.adminChecked then
        ToggleStaffHUD(true)
        initStaffHud()
        -- Request current reports if already in staff mode
        TriggerServerEvent("vfw:staff:requestReports")
    else
        ApplyHudOffDutyPreference()
    end
end)

-- Commands
VFW.RequireStaffMode("staffhud", function()
    if VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["staff_menu"] then
        staffHudVisible = not staffHudVisible
        ToggleStaffHUD(staffHudVisible)
        SetResourceKvp("staff_hide_web_hud", staffHudVisible and "false" or "true")
        VFW.ShowNotification({
            type = 'STAFF',
            variant = staffHudVisible and 'SUCCESS' or 'INFO',
            subtitle = 'Interface Staff',
            message = "Staff HUD " .. (staffHudVisible and "activé." or "désactivé.")
        })
    end
end)
