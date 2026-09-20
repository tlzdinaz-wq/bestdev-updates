---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["manage_doj"] == true
end

local function Panel()
    local res = TriggerServerCallback("dojStaff:getPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger les permissions DOJ." }
    end
    return res
end

RegisterNuiCallback("gestion:doj:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer le DOJ." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:doj:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Panel())
end)

RegisterNuiCallback("gestion:doj:save", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local result = TriggerServerCallback("dojStaff:updateGrade", data)
    if type(result) ~= "table" or result.ok ~= true then
        cb({ ok = false, error = (type(result) == "table" and result.error) or "Enregistrement impossible." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "DOJ", message = "Permissions enregistrées." })
    cb(result)
end)
