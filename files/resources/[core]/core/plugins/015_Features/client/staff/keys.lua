---@meta _
---@diagnostic disable: duplicate-doc-field

-- Register F2 keybinding for noclip (staff only)
VFW.RegisterInput("staff_noclip", "Activer/Désactiver le noclip", "keyboard", "F2", function()
    ExecuteCommand("noclip")
end)

-- Register F10 keybinding for staff menu
VFW.RegisterInput("openStaffMenu", "Menu Staff", "keyboard", "F10", function()
    VFW.OpenStaffMenu()
end)

-- Register N key for dismissing reports
VFW.RegisterInput("dismissReport", "Fermer le report", "keyboard", "N", function()
    -- Check for animator report first
    if VFW.lastAnimatorReport then
        VFW.RemoveNotification()
        VFW.lastAnimatorReport = nil
        return
    end

    -- Then check for admin report
    if VFW.lastReport then
        VFW.RemoveNotification()
        return
    end
end)

-- Register Y key for accepting reports
VFW.RegisterInput("acceptReport", "Accepter le report", "keyboard", "Y", function()
    -- Check for animator report first
    if VFW.lastAnimatorReport then
        for i = 1, #VFW.AnimatorReports do
            if VFW.AnimatorReports[i].id == VFW.lastAnimatorReport then
                -- Auto-enable animator mode if not already in staff/animator mode
                -- This is needed because staff actions require being on duty
                if not VFW.IsInStaffMode() then
                    -- Enable animator mode
                    TriggerServerEvent("vfw:animator:mode", true)
                    -- Update local state
                    if StaffMenu then
                        StaffMenu.animatorModeEnabled = true
                    end
                    local hideHudPreference = GetResourceKvpString("animator_hide_web_hud") == "true"
                  if not hideHudPreference then
                        if ToggleAnimatorHUD then ToggleAnimatorHUD(true) end
                        if initAnimatorHud then initAnimatorHud() end
                    end

                    local savedTagState = GetResourceKvpString("staff_gamer_tags")
                    if savedTagState == "true" and not VFW.IsGamerTagsActive() then
                        TriggerServerEvent("Admin:activeBlips", true)
                        TriggerServerEvent("Admin:gamerTag", true)
                        if StaffMenu.animatorSettings then StaffMenu.animatorSettings.showNameTags = true end
                    end
                    local savedNametagState = GetResourceKvpString("staff_name_tags")
                    if savedNametagState == "true" then
                        StaffMenu.showRPNamesOnPlayerTags = true
                    end
                end

                -- Check which menu system is available (prefer integrated staff menu)
                if StaffMenu and StaffMenu.animatorReport then
                    -- Using integrated staff menu (preferred)
                    StaffMenu.animatorData.selectedPlayer = VFW.AnimatorReports[i].player.source
                    StaffMenu.animatorData.reportInfo = VFW.AnimatorReports[i]
                    StaffMenu.animatorReport.open()
                elseif AnimatorMenu and AnimatorMenu.report then
                    -- Fallback to standalone animator menu (legacy)
                    AnimatorMenu.data.selectedPlayer = VFW.AnimatorReports[i].player.source
                    AnimatorMenu.data.reportInfo = VFW.AnimatorReports[i]
                    AnimatorMenu.report.open()
                end

                VFW.RemoveNotification()
                VFW.lastAnimatorReport = nil
                break
            end
        end
        return
    end

    -- Then check for admin report
    if VFW.lastReport then
        for i = 1, #VFW.Reports do
            if VFW.Reports[i].id == VFW.lastReport then
                StaffMenu.data.selectedPlayer = VFW.Reports[i].player.source
                StaffMenu.data.reportInfo = VFW.Reports[i]

                StaffMenu.report.open()
                VFW.RemoveNotification()
                break
            end
        end
    end
end)
