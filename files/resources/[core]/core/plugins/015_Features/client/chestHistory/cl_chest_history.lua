-- Client-side script for chest history

---Event to open chest history UI
RegisterNetEvent('chestHistory:open', function(data)
    VFW.Nui.Focus(true)

    SendNUIMessage({
        action = 'chestHistory:open',
        data = data
    })
end)

---Event to close chest history UI
RegisterNetEvent('chestHistory:close', function()
    SendNUIMessage({
        action = 'chestHistory:close'
    })
    VFW.Nui.Focus(false)
end)

---Event to update chest history data from server
RegisterNetEvent('chestHistory:receiveData', function(data)
    SendNUIMessage({
        action = 'chestHistory:receiveData',
        data = data
    })
end)

---NUI Callback to fetch chest history data
RegisterNUICallback('chestHistory:fetchData', function(data, cb)
    -- Request data from server
    TriggerServerEvent('chestHistory:requestData', data)

    -- The callback will be handled when server sends back the data
    cb('ok')
end)

---NUI Callback when chest history is closed
RegisterNUICallback('chestHistory:closed', function(data, cb)
    VFW.Nui.Focus(false)
    cb('ok')
end)

---Command to request chest history (client-side)
RegisterCommand("requestchesthistory", function(source, args)
    local chestId = args[1]

    if not chestId then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Usage: /requestchesthistory <chest_id>"
        })
        return
    end

    TriggerServerEvent('chestHistory:requestOpen', chestId)
end, false)

