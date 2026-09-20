---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["pochon_shop_builder"] == true
end

local function Panel()
    local res = TriggerServerCallback("pochonShop:getConfig")
    if type(res) ~= "table" or (res.ok ~= true and res.price == nil) then
        return { ok = false, error = "Impossible de charger la boutique de pochons." }
    end
    res.ok = true
    return res
end

RegisterNuiCallback("gestion:pochonShop:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer la boutique de pochons." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:pochonShop:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:pochonShop:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("gestionPochonShop:save", data)
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.error) or "Enregistrement impossible." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Pochon shop", message = "Tarifs enregistrés." })
    cb(result)
end)
