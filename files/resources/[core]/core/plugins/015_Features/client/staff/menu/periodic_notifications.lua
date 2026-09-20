---@meta _
---@diagnostic disable: duplicate-doc-field

-- ══════════════════════════════════════════════════════════════
-- Periodic Notifications - NUI Client Bridge
-- ══════════════════════════════════════════════════════════════

local isOpen = false

function OpenPeriodicNotificationsPanel()
    if isOpen then
        isOpen = false
        SendNUIMessage({
            action = "nui:periodicNotifs:visible",
            data = false
        })
    end

    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        if StaffMenu.UncoverGestionHub then StaffMenu.UncoverGestionHub() end
        SendNUIMessage({
            action = "gestion:notifs:sync",
            data = true,
        })
        return
    end

    -- Charger les notifications existantes
    local notifs = TriggerServerCallback("periodicNotifs:getAll")

    SendNUIMessage({
        action = "nui:periodicNotifs:data",
        data = notifs or {}
    })

    SendNUIMessage({
        action = "nui:periodicNotifs:visible",
        data = true
    })

    VFW.Nui.Focus(true)
    isOpen = true
end

local function ClosePanel()
    SendNUIMessage({
        action = "nui:periodicNotifs:visible",
        data = false
    })
    VFW.Nui.Focus(false)
    isOpen = false
    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        StaffMenu.UncoverGestionHub()
    end
end

-- ── NUI Callbacks ──

RegisterNUICallback("periodicNotifs:close", function(_, cb)
    ClosePanel()
    cb("ok")
end)

RegisterNUICallback("periodicNotifs:create", function(data, cb)
    local result = TriggerServerCallback("periodicNotifs:create", data)
    cb(result or { success = false, error = "Pas de réponse" })
end)

RegisterNUICallback("periodicNotifs:update", function(data, cb)
    local result = TriggerServerCallback("periodicNotifs:update", data)
    cb(result or { success = false, error = "Pas de réponse" })
end)

RegisterNUICallback("periodicNotifs:delete", function(data, cb)
    local result = TriggerServerCallback("periodicNotifs:delete", data.id)
    cb(result or { success = false, error = "Pas de réponse" })
end)

RegisterNUICallback("periodicNotifs:sendNow", function(data, cb)
    local result = TriggerServerCallback("periodicNotifs:sendNow", data.id)
    cb(result or { success = false, error = "Pas de réponse" })
end)

RegisterNUICallback("periodicNotifs:refresh", function(_, cb)
    local notifs = TriggerServerCallback("periodicNotifs:getAll")
    cb(notifs or {})
end)

RegisterNUICallback("periodicNotifs:preview", function(data, cb)
    VFW.ShowNotification({
        type = data.type or "DEFAULT",
        subtitle = data.subtitle or "Notification",
        content = data.message or ""
  })
    cb("ok")
end)
