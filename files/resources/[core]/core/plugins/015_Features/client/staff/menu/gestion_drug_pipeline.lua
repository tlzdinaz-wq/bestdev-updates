---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["builder_drug_pipeline"] == true or perms["illegal_activities_builder"] == true
end

local function Panel()
    local res = TriggerServerCallback("gestionDrugPipeline:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les pipelines drogue." }
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
        rotationZ = heading,
    }
end

RegisterNuiCallback("gestion:drugPipeline:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les pipelines drogue." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:drugPipeline:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:drugPipeline:here", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb({ ok = true, coords = Here() })
end)

RegisterNuiCallback("gestion:drugPipeline:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local x = data and tonumber(data.x)
    local y = data and tonumber(data.y)
    local z = data and tonumber(data.z)
    if not x or not y or not z then
        cb({ ok = false, error = "Position introuvable." })
        return
    end
    SetEntityCoords(PlayerPedId(), x, y, z + 0.99, false, false, false, false)
    if data.heading or data.w then
        SetEntityHeading(PlayerPedId(), (tonumber(data.heading or data.w) or 0.0) + 0.0)
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Pipeline drogue", message = "Téléporté." })
    cb(Panel())
end)

RegisterNuiCallback("gestion:drugPipeline:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionDrugPipeline:save", data)
    if type(result) ~= "table" or (result.ok ~= true and result.success ~= true) then
        Fail(cb, result, "Enregistrement impossible.")
        return
    end
    local action = tostring(data and data.action or "")
    local verb = action:find("delete") and "Supprimé." or (action:find("create") and "Créé." or "Enregistré.")
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Pipeline drogue", message = verb })
    result.ok = true
    cb(result)
end)
