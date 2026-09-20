---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["gestion_faction"] == true or perms["manage_garages"] == true
end

local function Panel(id)
    local res = TriggerServerCallback("gestionIllegalGarages:hubPanel", id)
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les garages illégaux." }
    end
    return res
end

local function Fail(cb, result, fallback)
    cb({
        ok = false,
        error = (type(result) == "table" and (result.error or result.message)) or fallback or "Action impossible.",
    })
end

local function Here()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped) + 0.0
    return {
        x = pos.x + 0.0,
        y = pos.y + 0.0,
        z = (pos.z - 0.99) + 0.0,
        heading = heading,
        w = heading,
    }
end

RegisterNuiCallback("gestion:illegalGarages:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les garages illégaux." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:illegalGarages:refresh", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel(data and data.id))
end)

RegisterNuiCallback("gestion:illegalGarages:detail", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel(data and data.id))
end)

RegisterNuiCallback("gestion:illegalGarages:here", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb({ ok = true, coords = Here() })
end)

RegisterNuiCallback("gestion:illegalGarages:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = Panel(data and data.id)
    local selected = payload.selected
    if type(selected) ~= "table" or type(selected.coords) ~= "table" or not selected.coords.x then
        cb({ ok = false, error = "Position introuvable." })
        return
    end
    local ped = PlayerPedId()
    SetEntityCoords(ped, selected.coords.x, selected.coords.y, selected.coords.z + 0.99, false, false, false, false)
    if selected.coords.heading then
        SetEntityHeading(ped, selected.coords.heading + 0.0)
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage illégal", message = "Téléporté au point." })
    cb(payload)
end)

RegisterNuiCallback("gestion:illegalGarages:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionIllegalGarages:create", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Création impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage illégal", message = "Point créé." })
    cb(result)
end)

RegisterNuiCallback("gestion:illegalGarages:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionIllegalGarages:update", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Mise à jour impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage illégal", message = "Point mis à jour." })
    cb(result)
end)

RegisterNuiCallback("gestion:illegalGarages:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionIllegalGarages:delete", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Suppression impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage illégal", message = "Point supprimé." })
    cb(result)
end)
