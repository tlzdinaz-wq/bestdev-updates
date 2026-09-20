---@meta _
---@diagnostic disable: duplicate-doc-field

--- .BuildWipeMenu
function StaffMenu.BuildWipeMenu()
    if StaffMenu.data.charList and StaffMenu.data.charList.charList then
        for _, v in pairs(StaffMenu.data.charList.charList) do
            StaffMenu.wipe.Button(v.name, (v.actual and "Actuel" or "OFF"), v.id, "chevron", false, function()
                local validations = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI'")

                if string.lower(validations) == "oui" then
                    if StaffMenu.data.isOfflineWipe then
                        TriggerServerEvent("vfw:staff:wipeOfflinePlayer", StaffMenu.data.selectedGlobalId, v.id)
                    else
                        TriggerServerEvent("vfw:staff:wipePlayer", StaffMenu.data.selectedPlayer, v.id)
                    end
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Wipe Données',
                        message = "Vous venez de wipe le personnage."
                  })
                    local wasOffline = StaffMenu.data.isOfflineWipe
                    StaffMenu.data.isOfflineWipe = false
                    SetTimeout(500, function()
                        local source = wasOffline and StaffMenu.data.selectedGlobalId or StaffMenu.data.selectedPlayer
                        StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getCharList", source) or {}
                        if StaffMenu.data.charList and StaffMenu.data.charList.charList and #StaffMenu.data.charList.charList > 0 then
                            StaffMenu.wipe.refresh()
                        else
                            StaffMenu.wipe.close()
                        end
                    end)
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe Données',
                        message = "Vous n'avez pas confirmé."
                  })
                end
            end)
        end
    end
end

--- .BuildWipeOfflineMenu
function StaffMenu.BuildWipeOfflineMenu()
    if StaffMenu.data.charList and StaffMenu.data.charList.charList then
        for _, v in pairs(StaffMenu.data.charList.charList) do
            StaffMenu.wipeOffline.Button(v.name, "OFF", v.id, "chevron", false, function()
                local validations = VFW.Nui.KeyboardInput(true, "Confirmer 'OUI'")

                if string.lower(validations) == "oui" then
                    TriggerServerEvent("vfw:staff:wipeOfflinePlayer", StaffMenu.data.selectedGlobalId, v.id)
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Wipe Données',
                        message = "Vous venez de wipe le personnage."
                  })
                    SetTimeout(500, function()
                        StaffMenu.data.charList = TriggerServerCallback("vfw:staff:getCharList", StaffMenu.data.selectedGlobalId) or {}
                        if StaffMenu.data.charList and StaffMenu.data.charList.charList and #StaffMenu.data.charList.charList > 0 then
                            StaffMenu.wipeOffline.refresh()
                        else
                            StaffMenu.wipeOffline.close()
                        end
                    end)
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Wipe Données',
                        message = "Vous n'avez pas confirmé."
                  })
                end
            end)
        end
    end
end
