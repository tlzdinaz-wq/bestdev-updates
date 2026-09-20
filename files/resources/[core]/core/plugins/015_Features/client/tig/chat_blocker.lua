---@meta _
---@diagnostic disable: duplicate-doc-field

-- TIG System - Advanced Chat Blocker
-- Comprehensive chat blocking during TIG

-- Store the chat status
local chatWasEnabled = true

-- Monitor and block chat
CreateThread(function()
    while true do
        Wait(100)

        if IsPlayerInTIG() then
            -- Multiple methods to ensure chat is blocked

            -- Method 1: Native chat disable
            SetTextChatEnabled(false)

            -- Method 3: Force close any open chat
            if IsPauseMenuActive() then
                SetPauseMenuActive(false)
            end

            -- Method 4: Clear chat feed
            if chatWasEnabled then
                -- Send a NUI message to hide chat
                SendNUIMessage({
                    action = "chat:clear"
                })
                SendNUIMessage({
                    action = "chat:hide"
                })
                chatWasEnabled = false
            end
        else
            -- Le chat FiveM (ressource chat) reste en NUI : ne jamais réactiver le chat GTA.
            if not chatWasEnabled then
                SetTextChatEnabled(false)
                chatWasEnabled = true
            end
        end
    end
end)

-- Intercept all common chat commands
local chatCommands = {
    "say", "ooc", "twt", "news", "ad", "ano",
    "ayuda", "id", "gme", "gdo", "/", "help"
}

for _, cmd in ipairs(chatCommands) do
    RegisterCommand(cmd, function(source, args, rawCommand)
        if IsPlayerInTIG() then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Le chat est désactivé pendant les TIG"
            })
            return
        end
        -- If not in TIG, the command will pass through normally
    end, false)
end

-- Block message sending
AddEventHandler('chat:messageEntered', function()
    if IsPlayerInTIG() then
        CancelEvent()
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le chat est désactivé pendant les TIG"
        })
    end
end)

-- Block outgoing messages
AddEventHandler('chat:outMessage', function(author, color, message)
    if IsPlayerInTIG() then
        CancelEvent()
    end
end)

-- Block incoming messages from showing
AddEventHandler('chat:addMessage', function(message)
    if IsPlayerInTIG() then
        CancelEvent()
    end
end)

-- Block chat templates
AddEventHandler('chat:addTemplate', function(name, template)
    if IsPlayerInTIG() then
        CancelEvent()
    end
end)

-- Override the chat resource functions if they exist
CreateThread(function()
    Wait(2000) -- Wait for chat resource to load

    -- Try to override chat functions
    pcall(function()
        if chat then
            local originalChatOpen = chat.open
            chat.open = function(...)
                if IsPlayerInTIG() then
                    return false
                end
                return originalChatOpen(...)
            end
        end
    end)
end)
