---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["illegal_activities_builder"] == true
end

local function Panel()
    local res = TriggerServerCallback("gestionIllegalCraft:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger le craft illégal." }
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
        rotationZ = heading,
    }
end

RegisterNuiCallback("gestion:illegalCraft:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer le craft illégal." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:illegalCraft:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:illegalCraft:here", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb({ ok = true, coords = Here() })
end)

RegisterNuiCallback("gestion:illegalCraft:teleport", function(data, cb)
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
    if data.heading or data.w then
        SetEntityHeading(ped, (tonumber(data.heading or data.w) or 0.0) + 0.0)
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Craft illégal", message = "Téléporté." })
    cb(Panel())
end)

local ACTIONS = {
    ["harvest:create"] = "illegalBuilder:createHarvestSpot",
    ["harvest:update"] = "illegalBuilder:updateHarvestSpot",
    ["harvest:delete"] = "illegalBuilder:deleteHarvestSpot",
    ["station:create"] = "illegalBuilder:createCraftStation",
    ["station:update"] = "illegalBuilder:updateCraftStation",
    ["station:delete"] = "illegalBuilder:deleteCraftStation",
    ["recipe:create"] = "illegalBuilder:createRecipe",
    ["recipe:update"] = "illegalBuilder:updateRecipe",
    ["recipe:delete"] = "illegalBuilder:deleteRecipe",
    ["transform:create"] = "illegalBuilder:createTransformSpot",
    ["transform:update"] = "illegalBuilder:updateTransformSpot",
    ["transform:delete"] = "illegalBuilder:deleteTransformSpot",
}

RegisterNuiCallback("gestion:illegalCraft:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = type(data) == "table" and data or {}
    local key = tostring(payload.action or "")
    local cbName = ACTIONS[key]
    if not cbName then
        cb({ ok = false, error = "Action inconnue." })
        return
    end

    local result
    if payload.action:find(":update$") then
        result = TriggerServerCallback(cbName, payload.id, payload)
    elseif payload.action:find(":delete$") then
        result = TriggerServerCallback(cbName, payload.id)
    else
        result = TriggerServerCallback(cbName, payload)
    end

    if type(result) ~= "table" or (result.ok ~= true and result.success ~= true) then
        Fail(cb, result, "Enregistrement impossible.")
        return
    end

    local verb = payload.action:find(":delete$") and "Supprimé." or (payload.action:find(":update$") and "Enregistré." or "Créé.")
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Craft illégal", message = verb })
    result.ok = true
    cb(result)
end)
