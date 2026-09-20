---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["builder_radio911"] == true
end

local function Panel()
    local res = TriggerServerCallback("radio911:getPanel")
    if type(res) ~= "table" or res.ok ~= true then
        return { ok = false, error = "Impossible de charger la radio 911." }
    end
    return res
end

RegisterNuiCallback("gestion:radio911:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer la radio 911." })
        return
    end
    cb(Panel())
end)

RegisterNuiCallback("gestion:radio911:add", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local name = data and data.job
    local ok = TriggerServerCallback("radio911:addJob", name)
    if not ok then
        cb({ ok = false, error = "Job déjà présent ou nom invalide." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Radio 911", message = "Job autorisé." })
    cb(Panel())
end)

RegisterNuiCallback("gestion:radio911:remove", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok = TriggerServerCallback("radio911:removeJob", data and data.job)
    if not ok then
        cb({ ok = false, error = "Impossible de retirer ce job." })
        return
    end
    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Radio 911", message = "Job retiré." })
    cb(Panel())
end)
