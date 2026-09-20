local machineOpen = false
local machineJobName = nil
local BEAN_COFFEE_LOGO = VFW.CDN.Get("entreprise/bean.png")

function BeanCoffee_OpenMachine(jobName)
    if machineOpen then return end

    local drinksData = TriggerServerCallback("bean_coffee:machine:getData", jobName)
    if not drinksData then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Service", image = BEAN_COFFEE_LOGO, content = "Vous devez être en service." })
        return
    end

    machineOpen = true
    machineJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "bean_coffee:machine:visible",
        data = true
    })

    SendNUIMessage({
        action = "bean_coffee:machine:data",
        data = drinksData
    })
end

local function closeMachine()
    if not machineOpen then return end
    machineOpen = false
    machineJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "bean_coffee:machine:visible",
        data = false
    })
end

RegisterNUICallback("bean_coffee:machine:close", function(_, cb)
    closeMachine()
    cb({ ok = true })
end)

RegisterNUICallback("bean_coffee:machine:serve", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local jobName = machineJobName
    local success, newData = TriggerServerCallback("bean_coffee:machine:serve", jobName, data.drinkKey, data.size)

    if success and newData then
        SendNUIMessage({
            action = "bean_coffee:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)

RegisterNUICallback("bean_coffee:machine:replaceBarrel", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local jobName = machineJobName
    local success, newData = TriggerServerCallback("bean_coffee:machine:replaceBarrel", jobName, data.drinkKey)

    if success and newData then
        SendNUIMessage({
            action = "bean_coffee:machine:data",
            data = newData
        })
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Machine", image = BEAN_COFFEE_LOGO, content = "Le sac de grains a été remplacé." })
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)
