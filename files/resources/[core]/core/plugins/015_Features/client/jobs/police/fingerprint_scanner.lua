---@meta _
---@diagnostic disable: duplicate-doc-field

local scannerOpen = false

RegisterNetEvent("police:fingerprintScanner:use", function()
    if scannerOpen then return end

    VFW.CloseInventory()
    Wait(200)

    local playerId = VFW.StartSelect(5.0, true)
    if not playerId then return end

    local serverId = GetPlayerServerId(playerId)
    if not serverId or serverId <= 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Joueur introuvable." })
        return
    end

    local isCuffed = TriggerServerCallback("vfw:faction:isPlayerCuffed", serverId)
    if not isCuffed then
        VFW.ShowNotification({ type = 'ROUGE', content = "La personne doit être menottée." })
        return
    end

    scannerOpen = true
    SendNUIMessage({
        action = "nui:fingerprintScanner:show",
        data = { targetServerId = serverId }
    })
    VFW.Nui.Focus(true, false)
end)

RegisterNUICallback("fingerprintScanner:scan", function(data, cb)
    if not data or not data.targetServerId then
        cb(nil)
        return
    end
    local result = TriggerServerCallback("police:fingerprintScanner:scan", data.targetServerId)
    cb(result or {})
end)

RegisterNUICallback("fingerprintScanner:history", function(_, cb)
    local history = TriggerServerCallback("police:fingerprintScanner:getHistory")
    cb(history or {})
end)

RegisterNUICallback("fingerprintScanner:close", function(_, cb)
    scannerOpen = false
    VFW.Nui.Focus(false)
    cb("ok")
end)
