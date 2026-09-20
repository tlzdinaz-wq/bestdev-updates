local machineOpen = false
local machineJobName = nil
local PIZZERIA_LOGO = VFW.CDN.Get("entreprise/pizzathis.png")

function Pizzeria_OpenMachine(jobName)
    if machineOpen then return end

    local data = TriggerServerCallback("pizzeria:machine:getData", jobName)
    if not data then
        VFW.ShowNotification({ type = "JOB", title = "Pizzeria", subtitle = "Service", image = PIZZERIA_LOGO, content = "Vous devez être en service." })
        return
    end

    machineOpen = true
    machineJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "pizzeria:machine:visible",
        data = true
    })

    SendNUIMessage({
        action = "pizzeria:machine:data",
        data = data
    })
end

local function closeMachine()
    if not machineOpen then return end
    machineOpen = false
    machineJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "pizzeria:machine:visible",
        data = false
    })
end

RegisterNUICallback("pizzeria:machine:serve", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local size = data.size or "33cl"
    local success, newData, errMsg = TriggerServerCallback("pizzeria:machine:serve", machineJobName, drinkKey, size)

    if success and newData then
        SendNUIMessage({
            action = "pizzeria:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "Pizzeria", subtitle = "Machine", image = PIZZERIA_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("pizzeria:machine:replaceBarrel", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local success, newData, errMsg = TriggerServerCallback("pizzeria:machine:replaceBarrel", machineJobName, drinkKey)

    if success and newData then
        SendNUIMessage({
            action = "pizzeria:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "Pizzeria", subtitle = "Machine", image = PIZZERIA_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("pizzeria:machine:close", function(_, cb)
    closeMachine()
    cb({ ok = true })
end)
