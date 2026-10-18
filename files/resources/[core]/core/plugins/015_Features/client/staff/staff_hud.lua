---@meta _
---@diagnostic disable: duplicate-doc-field

local staffHudVisible = false
local onlineStaffs = 0
local staffsInService = 0
local hudInitialized = false

local HUD_STYLES = {
    { id = "classic", label = "Classique" },
    { id = "glass", label = "Verre" },
    { id = "neon", label = "Néon" },
    { id = "ribbon", label = "Ruban" },
    { id = "orbs", label = "Orbes" },
    { id = "line", label = "Ligne" },
}

local HUD_STYLE_LEGACY = {
    compact = "glass",
    bar = "ribbon",
    minimal = "line",
    pills = "orbs",
}

function StaffHudStyleList()
    local labels = {}
    for i = 1, #HUD_STYLES do
        labels[i] = HUD_STYLES[i].label
    end
    return labels
end

function StaffHudStyleAt(index)
    local entry = HUD_STYLES[tonumber(index) or 0]
    return entry and entry.id or "classic"
end

function StaffHudStyleId()
    local style = GetResourceKvpString("staff_hud_style") or "classic"
    style = HUD_STYLE_LEGACY[style] or style
    for i = 1, #HUD_STYLES do
        if HUD_STYLES[i].id == style then
            return style, i
        end
    end
    return "classic", 1
end

function ApplyStaffHudStyle(style)
    local found = false
    for i = 1, #HUD_STYLES do
        if HUD_STYLES[i].id == style then
            found = true
            break
        end
    end
    if not found then style = "classic" end
    SetResourceKvp("staff_hud_style", style)
    SendNUIMessage({ action = "staffHud:style", data = style })
    if VFW.HudLayout and VFW.HudLayout.PushStaffPlace then
        VFW.HudLayout.PushStaffPlace()
    end
end

local function pushStaffHudStyle()
    SendNUIMessage({ action = "staffHud:style", data = select(1, StaffHudStyleId()) })
end

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
    pushStaffHudStyle()
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

local function staffModeOn()
    return StaffMenu and StaffMenu.adminChecked == true
end

_G.ToggleStaffHUD = function(state)
    if state and not staffModeOn() then
        state = false
    end
    staffHudVisible = state == true
    SendNUIMessage({
        action = "staffHud:toggle",
        data = staffHudVisible
    })
    if staffHudVisible then
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
    if enabled and staffModeOn() then
        local hideHud = GetResourceKvpString("staff_hide_web_hud") == "true"
        if not hideHud then
            ToggleStaffHUD(true)
            initStaffHud()
        end
        TriggerServerEvent("vfw:staff:requestReports")
    else
        ToggleStaffHUD(false)
    end
end)

-- Le panneau ne reste jamais affiché hors mode staff, y compris au spawn.
_G.ApplyHudOffDutyPreference = function()
    TriggerServerEvent("vfw:staff:setHudOffDuty", false)
    if not staffModeOn() then
        ToggleStaffHUD(false)
    end
end

local function syncStaffHud()
    if staffModeOn() and GetResourceKvpString("staff_hide_web_hud") ~= "true" then
        ToggleStaffHUD(true)
        initStaffHud()
        TriggerServerEvent("vfw:staff:requestReports")
        return
    end
    ToggleStaffHUD(false)
end

CreateThread(function()
    ToggleStaffHUD(false)
    Wait(1000)
    syncStaffHud()
end)

RegisterNetEvent("vfw:playerLoaded", function()
    CreateThread(function()
        Wait(500)
        syncStaffHud()
    end)
end)

RegisterNetEvent("vfw:characterLoaded", function()
    CreateThread(function()
        Wait(500)
        syncStaffHud()
    end)
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
