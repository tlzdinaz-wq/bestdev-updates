---@meta _
---@diagnostic disable: duplicate-doc-field

-- TIG System - NUI Message Interceptor
-- Intercepts and blocks NUI messages when player is in TIG

-- Store original SendNUIMessage function
local originalSendNUIMessage = SendNUIMessage

-- Override SendNUIMessage to filter messages during TIG
function SendNUIMessage(data)
    if IsPlayerInTIG() then
        -- Allow staff menu for players with staff_menu permission
        if VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions["staff_menu"] then
            return originalSendNUIMessage(data)
        end

        -- Check if the message is related to blocked features
        if data.action then
            local blockedActions = {
                "chat:open",
                "chat:show",
                "phone:open",
                "phone:show",
                "phone:toggle",
                "inventory:open",
                "inventory:show",
                "emotes:open",
                "emotes:show",
                "menu:open",
                "menu:show",
                "menuf5:open",
                "menuf5:show",
                "menuf4:open",
                "menuf6:open",
                "nui:escape-menu:visible" -- Block F5 escape menu
            }

            for _, blockedAction in ipairs(blockedActions) do
                if string.find(string.lower(data.action), blockedAction) then
                    -- Block the message
                    return
                end
            end
        end

        -- Check if it's trying to open any UI
        if data.type then
            local blockedTypes = {
                "ON_OPEN",
                "OPEN_MENU",
                "SHOW_UI",
                "TOGGLE_UI"
            }

            for _, blockedType in ipairs(blockedTypes) do
                if string.find(string.upper(data.type or ""), blockedType) then
                    return -- Block the message
                end
            end
        end

        -- Check for specific UI visibility flags
        if data.visible == true or data.show == true or data.display == true then
            -- Check if it's not TIG-related UI
            if not (data.action and string.find(string.lower(data.action), "tig")) then
                -- Block most UI visibility changes
                if data.action and not string.find(string.lower(data.action), "notification") then
                    return
                end
            end
        end
    end

    -- Call original function if not blocked
    return originalSendNUIMessage(data)
end

-- Block RegisterNUICallback for certain callbacks during TIG
local blockedCallbacks = {
    "chat:sendMessage",
    "phone:action",
    "inventory:action",
    "menu:action",
    "emotes:play"
}

local originalRegisterNUICallback = RegisterNUICallback

function RegisterNUICallback(name, callback)
    -- Wrap the callback to check TIG status
    local wrappedCallback = function(data, cb)
        if IsPlayerInTIG() then
            -- Check if this is a blocked callback
            for _, blocked in ipairs(blockedCallbacks) do
                if string.find(string.lower(name), string.lower(blocked)) then
                    cb(false) -- Return false to the NUI
                    return
                end
            end
        end

        -- Call original callback
        return callback(data, cb)
    end

    -- Register with wrapped callback
    return originalRegisterNUICallback(name, wrappedCallback)
end

-- Hide UI elements when entering TIG
RegisterNetEvent('vfw:tig:statusChanged')
AddEventHandler('vfw:tig:statusChanged', function(inTIG)
    if inTIG then
        -- Force close all UIs
        originalSendNUIMessage({action = "chat:hide"})
        originalSendNUIMessage({action = "phone:hide"})
        originalSendNUIMessage({action = "inventory:close"})
        originalSendNUIMessage({action = "menu:close"})
        originalSendNUIMessage({action = "emotes:close"})
        originalSendNUIMessage({action = "nui:escape-menu:close"})

        -- Disable NUI focus if active
        VFW.Nui.Focus(false, false)
    end
end)
