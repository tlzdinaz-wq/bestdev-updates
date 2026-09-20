---@meta _
---@diagnostic disable: duplicate-doc-field

local shortcuts = {
    enabled = true,
    customBindings = {}
}

-- Default key bindings
local defaultBindings = {
    -- F1-F12 Keys
    --{key = 288, action = "toggle_menu", description = "Ouvrir/Fermer Menu Admin"}, -- F1 (désactivé)
    --{key = 289, action = "toggle_noclip", description = "Toggle Noclip"}, -- F2 (géré par RegisterKeyMapping dans keys.lua)
    --{key = 170, action = "toggle_invisible", description = "Toggle Invisible"}, -- F3

    -- Special combinations
    {key = 38, modifier = 19, action = "revive_self", description = "Se Revive"}, -- E + Alt
    {key = 47, modifier = 19, action = "repair_vehicle", description = "Réparer Véhicule"}, -- G + Alt

    -- Numpad shortcuts
    --{key = 117, action = "quick_report", description = "Report Rapide"}, -- Numpad 7 (désactivé)
}

-- Register keyboard shortcuts
function RegisterStaffShortcuts()
    if not VFW.HasStaffPerm("staff_menu") and not VFW.HasStaffPerm("menu_anim") then return end
    
    CreateThread(function()
        while shortcuts.enabled do
            Wait(0)
            
            for _, binding in ipairs(defaultBindings) do
                if binding.modifier then
                    if (IsControlPressed(0, binding.modifier) or IsDisabledControlPressed(0, binding.modifier)) and (IsControlJustPressed(0, binding.key) or IsDisabledControlJustPressed(0, binding.key)) then
                        ExecuteShortcutAction(binding.action)
                    end
                else
                    if IsControlJustPressed(0, binding.key) or IsDisabledControlJustPressed(0, binding.key) then
                        ExecuteShortcutAction(binding.action)
                    end
                end
            end
            
            -- Custom bindings
            for key, action in pairs(shortcuts.customBindings) do
                if IsControlJustPressed(0, key) then
                    ExecuteShortcutAction(action)
                end
            end
        end
    end)
end

-- Execute shortcut action
function ExecuteShortcutAction(action)
    if not StaffMenu.adminChecked and action ~= "toggle_menu" then
        return
    end
    
    if action == "toggle_menu" then
        VFW.OpenStaffMenu()
    elseif action == "toggle_noclip" then
        VFW.ToggleNoclip()
    elseif action == "toggle_invisible" then
        local visible = IsEntityVisible(PlayerPedId())
        SetEntityVisible(PlayerPedId(), not visible, false)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = visible and 'WARNING' or 'SUCCESS',
            subtitle = 'Raccourcis Staff',
            title = StaffMenu.animatorModeEnabled and VFW.AnimatorTitle() or nil,
            message = visible and "Mode invisible activé." or "Mode invisible désactivé."
      })
    elseif action == "toggle_godmode" then
        local invincible = GetPlayerInvincible(PlayerId())
        SetEntityInvincible(PlayerPedId(), not invincible)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = not invincible and 'SUCCESS' or 'WARNING',
            subtitle = 'Raccourcis Staff',
            title = StaffMenu.animatorModeEnabled and VFW.AnimatorTitle() or nil,
            message = not invincible and "God Mode activé." or "God Mode désactivé."
      })
    elseif action == "teleport_marker" then
        TriggerEvent("vfw:tpm")
    elseif action == "revive_self" then
        TriggerServerEvent("vfw:staff:revivePlayer")
    elseif action == "repair_vehicle" then
        ExecuteCommand("repair")
    -- elseif action == "quick_report" then
    --     local message = VFW.Nui.KeyboardInput(true, "Message du report", "")
    --     if message then
    --         TriggerServerEvent("vfw:staff:createReport", message)
    --     end
    end
end

-- Help text display
function ShowShortcutHelp()
    local helpText = "=== RACCOURCIS CLAVIER ===\n\n"
    
  for _, binding in ipairs(defaultBindings) do
        local keyName = GetControlInstructionalButton(0, binding.key, true)
        if binding.modifier then
            local modName = GetControlInstructionalButton(0, binding.modifier, true)
            helpText = helpText .. modName .. " + " .. keyName .. " : " .. binding.description .. "\n"
      else
            helpText = helpText .. keyName .. " : " .. binding.description .. "\n"
      end
    end
    
    -- Display help
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(helpText)
    EndTextCommandThefeedPostTicker(true, true)
end

-- Helper function to check if player is in staff mode (client-side)
local function IsInStaffMode()
    if not VFW.staffMode then
        return false
    end

    local myServerId = GetPlayerServerId(PlayerId())
    for _, staffId in ipairs(VFW.staffMode) do
        if staffId == myServerId then
            return true
        end
    end

    return false
end

-- Command to show shortcuts
RegisterCommand("shortcuts", function()
    if not IsInStaffMode() then
        return
    end

    if VFW.HasStaffPerm("staff_menu") or VFW.HasStaffPerm("menu_anim") then
        ShowShortcutHelp()
    end
end, false)

CreateThread(function()
    Wait(4000)
    if VFW.HasStaffPerm("staff_menu") or VFW.HasStaffPerm("menu_anim") then
        RegisterStaffShortcuts()
    end
end)