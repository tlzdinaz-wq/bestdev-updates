---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["builder_fines"] == true
end

local function Panel()
    local res = TriggerServerCallback("policeFineTypes:getPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les amendes police." }
    end
    return res
end

RegisterNuiCallback("gestion:fines:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les amendes police." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:fines:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:fines:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("police:addFineType", data)
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.message) or "Impossible d'ajouter l'amende." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Amendes", message = "Amende ajoutée." })
    cb(Panel())
end)

RegisterNuiCallback("gestion:fines:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("police:updateFineType", data)
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.message) or "Mise à jour impossible." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Amendes", message = "Amende mise à jour." })
    cb(Panel())
end)

RegisterNuiCallback("gestion:fines:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("police:deleteFineType", data)
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.message) or "Suppression impossible." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Amendes", message = "Amende supprimée." })
    cb(Panel())
end)
