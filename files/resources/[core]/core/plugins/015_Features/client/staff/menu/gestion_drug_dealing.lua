---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["builder_drug_dealing"] == true
end

local function Panel()
    local res = TriggerServerCallback("gestionDrugDealing:hubPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger la vente de drogue." }
    end
    return res
end

local function Fail(cb, result, fallback)
    cb({
        ok = false,
        error = (type(result) == "table" and (result.error or result.message)) or fallback or "Action impossible.",
    })
end

RegisterNuiCallback("gestion:drugDealing:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer la vente de drogue." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:drugDealing:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:drugDealing:hereZone", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    local pos = GetEntityCoords(PlayerPedId())
    local name = GetNameOfZone(pos.x, pos.y, pos.z)
    local label = GetLabelText(name)
    if not label or label == "" or label == "NULL" or label:sub(1, 5) == "ZONE_" then
        label = name
    end
    cb({ ok = true, zone_name = name, label = label })
end)

RegisterNuiCallback("gestion:drugDealing:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionDrugDealing:save", data)
    if type(result) ~= "table" or (result.ok ~= true and result.success ~= true) then
        Fail(cb, result, "Enregistrement impossible.")
        return
    end
    local action = tostring(data and data.action or "")
    local verb = "Enregistré."
    if action:find("delete") then verb = "Supprimé."
    elseif action:find("save") and action:find("zone") then verb = "Zone enregistrée."
    elseif action:find("price") then verb = "Prix enregistré."
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Vente de drogue", message = verb })
    result.ok = true
    cb(result)
end)
