---@meta _
---@diagnostic disable: duplicate-doc-field

local staffChatData = {
    messages = {},
    isTyping = false,
    showChat = true,
    maxMessages = 50
}

-- Staff Chat System
function VFW.SendStaffMessage(message)
    if not message or message == "" then return end
    
    TriggerServerEvent("vfw:staff:sendStaffMessage", message)
end

-- Receive staff messages
RegisterNetEvent("vfw:staff:receiveStaffMessage", function(sender, message, rank, color)
    table.insert(staffChatData.messages, {
        sender = sender,
        message = message,
        rank = rank,
        color = color or "white",
        timestamp = os.date("%H:%M")
    })
    
    -- Limit message history
    if #staffChatData.messages > staffChatData.maxMessages then
        table.remove(staffChatData.messages, 1)
    end
    
    -- Display in chat
    if staffChatData.showChat then
        local colorCode = {
            white = "^0",
            red = "^1",
            green = "^2",
            yellow = "^3",
            blue = "^4",
            cyan = "^5",
            purple = "^6",
            orange = "^9"
      }
        
        local color = colorCode[color] or "^0"
      TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            multiline = true,
            args = {"( " .. color .. sender .. " | " .. rank .. " )", message}
        })
    end
end)

-- Staff chat command
RegisterCommand("sc", function(source, args, rawCommand)
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions then
        return
    end
    if not VFW.PlayerGlobalData.permissions["staff_chat"] then
        if next(VFW.PlayerGlobalData.permissions) then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Chat Staff',
                message = "Vous n'avez pas accès au chat staff"
          })
        end
        return
    end
    
    local message = table.concat(args, " ")
    if message ~= "" then
        VFW.SendStaffMessage(message)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Chat Staff', message = "Votre message a bien été envoyé." })
    end
end, false)

-- Toggle staff chat visibility
RegisterCommand("togglesc", function()
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions then
        return
    end
    if not VFW.PlayerGlobalData.permissions["staff_chat"] then
        if next(VFW.PlayerGlobalData.permissions) then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Chat Staff',
                message = "Vous n'avez pas la permission d'utiliser cette commande."
          })
        end
        return
    end
    
    staffChatData.showChat = not staffChatData.showChat
    VFW.ShowNotification({
        type = 'STAFF',
        variant = staffChatData.showChat and 'SUCCESS' or 'INFO',
        subtitle = 'Chat Staff',
        message = "Chat staff " .. (staffChatData.showChat and "activé." or "désactivé.")
    })
end, false)

-- Build Staff Chat Menu
function StaffMenu.BuildStaffChatMenu()
    StaffMenu.staffChat.Separator("CHAT STAFF")
    
    -- Toggle chat
    StaffMenu.staffChat.Checkbox("AFFICHER LE CHAT", "Afficher les messages du chat staff dans le tchat de jeu en temps réel", false, staffChatData.showChat, function(_checked)
        staffChatData.showChat = _checked
    end)
    
    -- Send message
    StaffMenu.staffChat.Button("ENVOYER UN MESSAGE", "Envoyer un message visible uniquement par les membres du staff connectés", nil, "chevron", false, function()
        local message = VFW.Nui.KeyboardInput(true, "Message pour le staff", "")
        if message and message ~= "" then
            VFW.SendStaffMessage(message)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Chat Staff', message = "Votre message a bien été envoyé." })
        end
    end)
    
    -- Clear chat
    StaffMenu.staffChat.Button("EFFACER L'HISTORIQUE", "Effacer l'historique local des messages du chat staff affichés dans ce menu", nil, "trash", false, function()
        staffChatData.messages = {}
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Chat Staff',
            message = "Historique du chat effacé"
      })
    end)
    
    StaffMenu.staffChat.Separator("HISTORIQUE DES MESSAGES")
    
    -- Display recent messages
    if #staffChatData.messages > 0 then
        for i = math.max(1, #staffChatData.messages - 10), #staffChatData.messages do
            local msg = staffChatData.messages[i]
            if msg then
                StaffMenu.staffChat.Button(
                    string.format("[%s] %s", msg.timestamp, msg.sender),
                    msg.message,
                    nil,
                    nil,
                    true,
                    function() end
                )
            end
        end
    else
        StaffMenu.staffChat.Separator("Aucun message")
    end
end

-- Staff announcements
function VFW.SendStaffAnnouncement(message, type)
    if not VFW.PlayerGlobalData or not VFW.PlayerGlobalData.permissions then
        return
    end
    if not VFW.PlayerGlobalData.permissions["announce_staff"] then
        if next(VFW.PlayerGlobalData.permissions) then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Chat Staff',
                message = "Vous n'avez pas la permission d'envoyer des annonces."
          })
        end
        return
    end
    
    TriggerServerEvent("vfw:staff:sendAnnouncement", message, type or "staff")
end

RegisterNetEvent("vfw:staff:receiveAnnouncement", function(message, type, sender)
    -- Display announcement with special formatting
    if type == "global" then
        -- Global server announcement
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~ANNONCE SERVEUR~s~\n" .. message .. "\n~c~Par: " .. sender)
        DrawNotification(false, true)
    elseif type == "staff" then
        -- Staff-only announcement
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~y~ANNONCE STAFF~s~\n" .. message .. "\n~c~Par: " .. sender)
        DrawNotification(false, true)
    end
end)