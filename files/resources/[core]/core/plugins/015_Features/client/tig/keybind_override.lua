---@meta _
---@diagnostic disable: duplicate-doc-field

-- TIG System - Keybind Overrides
-- This file overrides keybinds when player is in TIG

-- Thread to block typing in chat
CreateThread(function()
    while true do
        Wait(0)
        if IsPlayerInTIG() then
            -- Block the chat input key
            if IsControlPressed(0, 245) then -- T key held
                DisableControlAction(0, 245, true)
            end

            -- Close chat if it somehow opens (le chat FiveM est en NUI, pas le chat GTA)
            SetTextChatEnabled(false)
        else
            Wait(1000) -- Less frequent check when not in TIG
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if IsPlayerInTIG() then
            -- Block K key (Phone) - lb-phone uses this key
            DisableControlAction(0, 311, true)
            if IsControlJustPressed(0, 311) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Le téléphone est désactivé pendant les TIG"
                })
            end

            -- Block T key (Chat) notification only - chat is blocked elsewhere
            if IsControlJustPressed(0, 245) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Le chat est désactivé pendant les TIG"
                })
            end

            -- Note: F3/F4/F5/F6 notifications removed - individual menus handle their own TIG checks
        else
            Wait(1000)
        end
    end
end)

-- Override inventory functions if they exist
CreateThread(function()
    Wait(1000)

    -- Try to override various inventory systems
    if VFW and VFW.OpenInventory then
        local originalOpenInventory = VFW.OpenInventory
        VFW.OpenInventory = function(...)
            if IsPlayerInTIG() then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "L'inventaire est désactivé pendant les TIG"
                })
                return
            end
            return originalOpenInventory(...)
        end
    end

    if VFW and VFW.CloseInventory then
        local originalCloseInventory = VFW.CloseInventory
        VFW.CloseInventory = function(...)
            if IsPlayerInTIG() then
                return
            end
            return originalCloseInventory(...)
        end
    end
end)

-- Block NUI callbacks
RegisterNUICallback('OpenMenu', function(data, cb)
    if IsPlayerInTIG() then
        cb(false)
        return
    end
    -- Let it pass through if not in TIG
end)

RegisterNUICallback('chat:sendMessage', function(data, cb)
    if IsPlayerInTIG() then
        cb(false)
        return
    end
end)

-- Override SetNuiFocus to prevent menu opening
local originalSetNuiFocus = SetNuiFocus
function SetNuiFocus(hasFocus, hasCursor)
    if IsPlayerInTIG() then
        local stack = debug.getinfo(2)
        if stack and stack.source then
            -- Allow TIG-related and Staff-related NUI focus
            if string.find(stack.source, "tig") or string.find(stack.source, "staff") then
                return originalSetNuiFocus(hasFocus, hasCursor)
            end
        end

        -- Also allow if player has staff_menu permission
        if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["staff_menu"] then
            return originalSetNuiFocus(hasFocus, hasCursor)
        end

        -- Block everything else
        if hasFocus or hasCursor then
            return -- Don't set focus/cursor
        end
    end

    return originalSetNuiFocus(hasFocus, hasCursor)
end
