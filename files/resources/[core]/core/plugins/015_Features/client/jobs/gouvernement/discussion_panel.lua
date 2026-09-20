-- Discussion system client relay
-- Relays NUI discussion messages to server callbacks

RegisterNuiCallback('discussion:getJobs', function(data, cb)
    local senderJob = data
    local jobs = TriggerServerCallback('discussion:getJobs', senderJob)
    cb(jobs)
end)

RegisterNuiCallback('discussion:getMessages', function(data, cb)
    local messages = TriggerServerCallback('discussion:getMessages', data)
    cb(messages)
end)

RegisterNuiCallback('discussion:sendMessage', function(data, cb)
    local success = TriggerServerCallback('discussion:sendMessage', data)
    cb(success)
end)

RegisterNuiCallback('discussion:markAsRead', function(data, cb)
    local success = TriggerServerCallback('discussion:markAsRead', data)
    cb(success)
end)
