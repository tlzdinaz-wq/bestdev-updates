local machineOpen = false
local machineJobName = nil
local UWU_CAFE_LOGO = VFW.CDN.Get("entreprise/uwucafe.png")

function UwuCafe_OpenMachine(jobName)
    if machineOpen then return end

    local drinksData = TriggerServerCallback("uwu_cafe:machine:getData", jobName)
    if not drinksData then
        VFW.ShowNotification({ type = "JOB", title = "UwU Cafe", subtitle = "Service", image = UWU_CAFE_LOGO, content = "Vous devez être en service." })
        return
    end

    machineOpen = true
    machineJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "uwu_cafe:machine:visible",
        data = true
    })

    SendNUIMessage({
        action = "uwu_cafe:machine:data",
        data = drinksData
    })
end

local function closeMachine()
    if not machineOpen then return end
    machineOpen = false
    machineJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "uwu_cafe:machine:visible",
        data = false
    })
end

RegisterNUICallback("uwu_cafe:machine:close", function(_, cb)
    closeMachine()
    cb({ ok = true })
end)

RegisterNUICallback("uwu_cafe:machine:serve", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local jobName = machineJobName
    local success, newData = TriggerServerCallback("uwu_cafe:machine:serve", jobName, data.drinkKey, data.size)

    if success and newData then
        SendNUIMessage({
            action = "uwu_cafe:machine:data",
            data = newData
        })
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)

RegisterNUICallback("uwu_cafe:machine:replaceBarrel", function(data, cb)
    if not machineOpen then
        cb({ ok = false })
        return
    end

    local jobName = machineJobName
    local success, newData = TriggerServerCallback("uwu_cafe:machine:replaceBarrel", jobName, data.drinkKey)

    if success and newData then
        SendNUIMessage({
            action = "uwu_cafe:machine:data",
            data = newData
        })
        VFW.ShowNotification({ type = "JOB", title = "UwU Cafe", subtitle = "Machine", image = UWU_CAFE_LOGO, content = "Le sac de grains a été remplacé." })
        cb({ ok = true })
    else
        cb({ ok = false })
    end
end)
