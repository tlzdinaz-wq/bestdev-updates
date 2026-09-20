---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["gestion_faction"] == true or perms["manage_garages"] == true
end

local function Panel(id)
    local res = TriggerServerCallback("gestionFactionGarages:hubPanel", id)
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les garages de faction." }
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
        w = heading,
        heading = heading,
    }
end

RegisterNuiCallback("gestion:factionGarages:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:factionGarages:refresh", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel(data and data.id))
end)

RegisterNuiCallback("gestion:factionGarages:detail", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel(data and data.id))
end)

RegisterNuiCallback("gestion:factionGarages:here", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb({ ok = true, coords = Here() })
end)

RegisterNuiCallback("gestion:factionGarages:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = Panel(data and data.id)
    local selected = payload.selected
    if type(selected) ~= "table" or type(selected.position) ~= "table" or not selected.position.x then
        cb({ ok = false, error = "Position introuvable." })
        return
    end
    local ped = PlayerPedId()
    SetEntityCoords(ped, selected.position.x, selected.position.y, selected.position.z + 0.99, false, false, false, false)
    if selected.position.w then
        SetEntityHeading(ped, selected.position.w + 0.0)
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage faction", message = "Téléporté au garage." })
    cb(payload)
end)

RegisterNuiCallback("gestion:factionGarages:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionFactionGarages:create", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Création impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage faction", message = "Garage créé." })
    cb(result)
end)

RegisterNuiCallback("gestion:factionGarages:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionFactionGarages:update", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Mise à jour impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage faction", message = "Garage mis à jour." })
    cb(result)
end)

RegisterNuiCallback("gestion:factionGarages:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionFactionGarages:delete", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Suppression impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage faction", message = "Garage supprimé." })
    cb(result)
end)

RegisterNuiCallback("gestion:factionGarages:addVehicle", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionFactionGarages:addVehicle", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Ajout du véhicule impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage faction", message = "Véhicule ajouté." })
    cb(result)
end)

RegisterNuiCallback("gestion:factionGarages:removeVehicle", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionFactionGarages:removeVehicle", data)
    if type(result) ~= "table" or result.ok ~= true then
        Fail(cb, result, "Retrait du véhicule impossible.")
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Garage faction", message = "Véhicule retiré." })
    cb(result)
end)
