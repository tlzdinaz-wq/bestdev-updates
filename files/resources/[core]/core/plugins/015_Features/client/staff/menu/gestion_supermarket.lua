---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["builder_supermarket"] == true
end

local function Panel()
    local res = TriggerServerCallback("gestionSupermarket:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les supérettes." }
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
        h = heading,
        heading = heading,
        w = heading,
    }
end

RegisterNuiCallback("gestion:supermarket:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les supérettes." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:supermarket:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:supermarket:here", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb({ ok = true, coords = Here() })
end)

RegisterNuiCallback("gestion:supermarket:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local x = data and tonumber(data.x)
    local y = data and tonumber(data.y)
    local z = data and tonumber(data.z)
    if not x or not y or not z then
        cb({ ok = false, error = "Position introuvable." })
        return
    end
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z + 0.99, false, false, false, false)
    if data.heading or data.h or data.w then
        SetEntityHeading(ped, (tonumber(data.heading or data.h or data.w) or 0.0) + 0.0)
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Supérette", message = "Téléporté." })
    cb(Panel())
end)

RegisterNuiCallback("gestion:supermarket:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionSupermarket:save", data)
    if type(result) ~= "table" or (result.ok ~= true and result.success ~= true) then
        Fail(cb, result, "Enregistrement impossible.")
        return
    end
    local action = tostring(data and data.action or "")
    local verb = "Enregistré."
    if action:find("delete") then
        verb = "Supprimé."
    elseif action:find("reset") then
        verb = "Cooldowns réinitialisés."
    elseif action:find("create") or (action:find("save") and not data.id) then
        verb = "Enregistré."
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Supérette", message = verb })
    result.ok = true
    cb(result)
end)
