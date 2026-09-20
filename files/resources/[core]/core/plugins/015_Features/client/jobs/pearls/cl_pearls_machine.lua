local machineOpen = false
local machineJobName = nil
local PEARLS_LOGO = VFW.CDN.Get("entreprise/pearl.png")

function Pearls_OpenMachine(jobName)
    if machineOpen then return end

    local data = TriggerServerCallback("pearls:machine:getData", jobName)
    if not data then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Service", image = PEARLS_LOGO, content = "Vous devez être en service." })
        return
    end

    machineOpen = true
    machineJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "pearls:machine:visible",
        data = true
    })

    SendNUIMessage({
        action = "pearls:machine:data",
        data = data
    })
end

local function closeMachine()
    if not machineOpen then return end
    machineOpen = false
    machineJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "pearls:machine:visible",
        data = false
    })
end

RegisterNUICallback("pearls:machine:serve", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local size = data.size or "33cl"
    local success, newData, errMsg = TriggerServerCallback("pearls:machine:serve", machineJobName, drinkKey, size)

    if success and newData then
        SendNUIMessage({
            action = "pearls:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Machine", image = PEARLS_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("pearls:machine:replaceBarrel", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local success, newData, errMsg = TriggerServerCallback("pearls:machine:replaceBarrel", machineJobName, drinkKey)

    if success and newData then
        SendNUIMessage({
            action = "pearls:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Machine", image = PEARLS_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("pearls:machine:close", function(_, cb)
    closeMachine()
    cb({ ok = true })
end)
