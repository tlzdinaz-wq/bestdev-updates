---@meta _
---@diagnostic disable: duplicate-doc-field

-- Animator menu structure (kept for compatibility)
AnimatorMenu = {}

-- Open animator menu function (uses standalone menu for F7 access)
function VFW.OpenAnimatorMenu()
    if not VFW.PlayerData or not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions then
        return
    end
    if not VFW.PlayerGlobalData.permissions["menu_anim"] then
        return
    end

    if StaffMenu and StaffMenu.animatorStandalone then
        StaffMenu.animatorStandalone.toggle()
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', title = 'EVE Animateur', subtitle = 'Mode Animateur',
            message = "Menu animateur non disponible."
      })
    end
end

-- Register F7 keybinding for animator menu
VFW.RegisterInput("openAnimatorMenu", "Menu Animateur", "keyboard", "F7", function()
    VFW.OpenAnimatorMenu()
end)

-- Command to open animator menu
VFW.RequireStaffMode("animateur", function()
    VFW.OpenAnimatorMenu()
end)

TriggerEvent("chat:addSuggestion", "/animateur", "Ouvre le menu animateur (permission animateur requise)")
