--- Liaison Gouvernement NUI Callbacks (entreprises → gouvernement)
--- Les callbacks gouvernement:* sont enregistrés dans client/jobs/gouvernement/panel.lua

RegisterNuiCallback("liaison:getConversation", function(data, cb)
    local messages = TriggerServerCallback("liaison:getConversation")
    cb(messages or {})
end)

RegisterNuiCallback("liaison:sendMessage", function(data, cb)
    local messageText = data and (data.message or data.messageText)
    if not messageText then
        cb(false)
        return
    end
    local success = TriggerServerCallback("liaison:sendMessage", { message = messageText })
    cb(success or false)
end)

RegisterNuiCallback("liaison:getCompanyTaxes", function(data, cb)
    local taxes = TriggerServerCallback("liaison:getCompanyTaxes")
    cb(taxes or {})
end)

RegisterNuiCallback("liaison:getTaxLogs", function(data, cb)
    local logs = TriggerServerCallback("liaison:getTaxLogs")
    cb(logs or {})
end)

RegisterNuiCallback("liaison:deleteMessage", function(data, cb)
    if not data or not data.messageId then
        cb(false)
        return
    end
    local success = TriggerServerCallback("liaison:deleteMessage", { messageId = data.messageId })
    cb(success or false)
end)

RegisterNuiCallback("liaison:clearConversation", function(data, cb)
    local success = TriggerServerCallback("liaison:clearConversation")
    cb(success or false)
end)

RegisterNuiCallback("liaison:getUnreadCount", function(data, cb)
    local count = TriggerServerCallback("liaison:getUnreadCount")
    cb(count or 0)
end)

RegisterNuiCallback("liaison:markAsRead", function(data, cb)
    local success = TriggerServerCallback("liaison:markAsRead")
    cb(success or false)
end)

RegisterNetEvent("liaison:newMessage", function(data)
    SendNUIMessage({
        action = "liaison:newMessage",
        data = data or {}
    })
end)
