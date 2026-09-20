---@meta _
---@diagnostic disable: duplicate-doc-field

local staffCustomState = {
    isPermanent = false,
    originalProps = nil,
    isStaffCustomMode = false,
    validated = false,
    returnMenu = nil
}

local STAFF_CUSTOM_PERMISSION = "staff_custom"

local function hasStaffCustomPermission()
    return VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
        and VFW.PlayerGlobalData.permissions[STAFF_CUSTOM_PERMISSION]
end

function VFW.IsStaffCustomMode()
    return staffCustomState.isStaffCustomMode
end

function VFW.IsStaffCustomPermanent()
    return staffCustomState.isPermanent
end

function VFW.ToggleStaffCustomPermanent(enabled)
    staffCustomState.isPermanent = enabled
end

function VFW.SetStaffCustomValidated(validated)
    staffCustomState.validated = validated
end

function VFW.IsStaffCustomValidated()
    return staffCustomState.validated
end

function VFW.OpenStaffCustom()
    if not hasStaffCustomPermission() then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Actions Staff',
            title = (StaffMenu and StaffMenu.animatorModeEnabled) and VFW.AnimatorTitle() or nil,
            message = "Vous n'avez pas la permission d'utiliser cette fonction"
      })
        return
    end

    StaffMenu.OpenVehicleCustomMenu()
end

function VFW.ApplyStaffCustom(permanent)
    if not staffCustomState.isStaffCustomMode then return end

    local vehicle = VFW.PlayerData.vehicle
    if not vehicle then return end

    local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
    local props = VFW.Game.GetVehicleProperties(vehicle)

    staffCustomState.validated = true

    if permanent then
        TriggerServerEvent("vfw:staff:saveVehicleCustom", plate, props)
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Actions Staff',
            title = (StaffMenu and StaffMenu.animatorModeEnabled) and VFW.AnimatorTitle() or nil,
            message = "Modifications appliquées."
      })
    end

    FreezeEntityPosition(vehicle, false)
end

function VFW.CancelStaffCustom()
    if not staffCustomState.isStaffCustomMode then return end
    if staffCustomState.validated then return end

    local vehicle = VFW.PlayerData.vehicle
    if vehicle and staffCustomState.originalProps then
        VFW.Game.SetVehicleProperties(vehicle, staffCustomState.originalProps)
    end

    staffCustomState.isStaffCustomMode = false
    FreezeEntityPosition(vehicle, false)
end

function VFW.ResetStaffCustomState()
    staffCustomState.isStaffCustomMode = false
    staffCustomState.isPermanent = false
    staffCustomState.validated = false
    staffCustomState.originalProps = nil
    staffCustomState.returnMenu = nil
end

function VFW.SetStaffCustomReturnMenu(menu)
    staffCustomState.returnMenu = menu
end

function VFW.OpenStaffCustomReturnMenu()
    if staffCustomState.returnMenu and staffCustomState.returnMenu.open then
        local menuToOpen = staffCustomState.returnMenu
        staffCustomState.returnMenu = nil
        CreateThread(function()
            Wait(50)
            menuToOpen.open()
        end)
        return true
    end
    return false
end

RegisterCommand("staffcustom", function()
    VFW.OpenStaffCustom()
end, false)

VFW.AddChatSuggestion('/staffcustom', 'Ouvrir le menu de customisation staff')
