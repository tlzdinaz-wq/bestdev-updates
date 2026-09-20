local machineOpen = false
local machineJobName = nil
local NOODLE_LOGO = VFW.CDN.Get("entreprise/noodle.png")

function Noodle_OpenMachine(jobName)
    if machineOpen then return end

    local data = TriggerServerCallback("noodle:machine:getData", jobName)
    if not data then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Service", image = NOODLE_LOGO, content = "Vous devez être en service." })
        return
    end

    machineOpen = true
    machineJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "noodle:machine:visible",
        data = true
    })

    SendNUIMessage({
        action = "noodle:machine:data",
        data = data
    })
end

local function closeMachine()
    if not machineOpen then return end
    machineOpen = false
    machineJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "noodle:machine:visible",
        data = false
    })
end

RegisterNUICallback("noodle:machine:serve", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local size = data.size or "33cl"
    local success, newData, errMsg = TriggerServerCallback("noodle:machine:serve", machineJobName, drinkKey, size)

    if success and newData then
        SendNUIMessage({
            action = "noodle:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Machine", image = NOODLE_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("noodle:machine:replaceBarrel", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local success, newData, errMsg = TriggerServerCallback("noodle:machine:replaceBarrel", machineJobName, drinkKey)

    if success and newData then
        SendNUIMessage({
            action = "noodle:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Machine", image = NOODLE_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("noodle:machine:close", function(_, cb)
    closeMachine()
    cb({ ok = true })
end)
