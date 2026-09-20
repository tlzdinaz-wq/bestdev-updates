local activePromise = nil
local lastCancelled = false

local function closeUi()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "ui", toggle = false })
end

RegisterNUICallback('callback', function(data, cb)
    closeUi()
    lastCancelled = false
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve(data and data.success == true)
    end
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    closeUi()
    lastCancelled = true
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve(false)
    end
    cb('ok')
end)

exports('startLockpick', function()
    if activePromise then return false end

    lastCancelled = false
    activePromise = promise.new()
    SendNUIMessage({ action = "ui", toggle = true })
    SetNuiFocus(true, true)

    return Citizen.Await(activePromise)
end)

exports('wasCancelled', function()
    return lastCancelled
end)

exports('cancel', function()
    if not activePromise then return false end
    closeUi()
    lastCancelled = true
    local p = activePromise
    activePromise = nil
    p:resolve(false)
    return true
end)

AddEventHandler("onResourceStop", function(resName)
    if resName == GetCurrentResourceName() and activePromise then
        SetNuiFocus(false, false)
        local p = activePromise
        activePromise = nil
        lastCancelled = true
        p:resolve(false)
    end
end)
