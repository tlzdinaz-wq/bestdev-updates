---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["dev"] == true or perms["staff"] == true or perms["server_management"] == true
end

local function Panel()
    local res = TriggerServerCallback("gestionNotifs:hubPanel")
    if type(res) ~= "table" then
        local list = TriggerServerCallback("periodicNotifs:getAll")
        return { ok = true, notifications = type(list) == "table" and list or {} }
    end
    if res.ok ~= true and res.success ~= true then
        return { ok = false, error = res.error or "Impossible de charger les notifications." }
    end
    res.ok = true
    res.notifications = res.notifications or {}
    return res
end

local function Fail(cb, result, fallback)
    cb({
        ok = false,
        error = (type(result) == "table" and (result.error or result.message)) or fallback or "Action impossible.",
    })
end

RegisterNuiCallback("gestion:notifs:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les notifications." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:notifs:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:notifs:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionNotifs:save", data)
    if type(result) ~= "table" or (result.ok ~= true and result.success ~= true) then
        Fail(cb, result, "Enregistrement impossible.")
        return
    end
    result.ok = true
    result.notifications = result.notifications or {}
    cb(result)
end)

RegisterNuiCallback("gestion:notifs:preview", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    VFW.ShowNotification({
        type = (data and data.type) or "DEFAULT",
        subtitle = (data and data.subtitle) or "Notification",
        message = (data and data.message) or "",
        content = (data and data.message) or "",
    })
    cb({ ok = true })
end)
