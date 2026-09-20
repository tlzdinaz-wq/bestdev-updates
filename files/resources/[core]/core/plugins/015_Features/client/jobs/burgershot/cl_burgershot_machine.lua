local machineOpen = false
local machineJobName = nil
local BURGERSHOT_LOGO = VFW.CDN.Get("entreprise/burgershot.png")

function BurgerShot_OpenMachine(jobName)
    if machineOpen then return end

    local data = TriggerServerCallback("burgershot:machine:getData", jobName)
    if not data then
        VFW.ShowNotification({ type = "JOB", title = "BurgerShot", subtitle = "Service", image = BURGERSHOT_LOGO, content = "Vous devez être en service." })
        return
    end

    machineOpen = true
    machineJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "burgershot:machine:visible",
        data = true
    })

    SendNUIMessage({
        action = "burgershot:machine:data",
        data = data
    })
end

local function closeMachine()
    if not machineOpen then return end
    machineOpen = false
    machineJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "burgershot:machine:visible",
        data = false
    })
end

RegisterNUICallback("burgershot:machine:serve", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local size = data.size or "33cl"
    local success, newData, errMsg = TriggerServerCallback("burgershot:machine:serve", machineJobName, drinkKey, size)

    if success and newData then
        SendNUIMessage({
            action = "burgershot:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "BurgerShot", subtitle = "Machine", image = BURGERSHOT_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("burgershot:machine:replaceBarrel", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local drinkKey = data.drinkKey
    local success, newData, errMsg = TriggerServerCallback("burgershot:machine:replaceBarrel", machineJobName, drinkKey)

    if success and newData then
        SendNUIMessage({
            action = "burgershot:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        if errMsg then
            VFW.ShowNotification({ type = "JOB", title = "BurgerShot", subtitle = "Machine", image = BURGERSHOT_LOGO, content = errMsg })
        end
        cb({ ok = false })
    end
end)

RegisterNUICallback("burgershot:machine:close", function(_, cb)
    closeMachine()
    cb({ ok = true })
end)
