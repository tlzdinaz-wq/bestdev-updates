---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["boutique"] == true
end

local function Wrap(res, fallback)
    if type(res) ~= "table" then return { ok = false, error = fallback or "Action impossible." } end
    if res.success == false then
        return { ok = false, error = res.error or res.message or fallback or "Action impossible." }
    end
    res.ok = true
    return res
end

local function CasesPayload()
    local cases = TriggerServerCallback("core:afkshop:getCases") or {}
    return { ok = true, cases = cases.cases or {} }
end

RegisterNuiCallback("gestion:afk:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission boutique." })
        return
    end
    local cases = TriggerServerCallback("core:afkshop:getCases") or {}
    local points = TriggerServerCallback("core:afkshop:getPlayersPoints", "", 100) or {}
    local logs = TriggerServerCallback("core:afkshop:getPurchaseLogs", 100) or {}
    cb({
        ok = true,
        cases = cases.cases or {},
        players = points.players or {},
        logs = logs.logs or {},
    })
end)

RegisterNuiCallback("gestion:afk:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    local cases = TriggerServerCallback("core:afkshop:getCases") or {}
    cb({ ok = true, cases = cases.cases or {} })
end)

RegisterNuiCallback("gestion:afk:createCase", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:createCase", data)
    if not res or not res.success then cb(Wrap(res, "Impossible de créer la caisse.")) return end
    cb(CasesPayload())
end)

RegisterNuiCallback("gestion:afk:editCase", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:editCase", data)
    if not res or not res.success then cb(Wrap(res, "Impossible de modifier la caisse.")) return end
    cb(CasesPayload())
end)

RegisterNuiCallback("gestion:afk:deleteCase", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:deleteCase", data and data.id)
    if not res or not res.success then cb(Wrap(res, "Impossible de supprimer la caisse.")) return end
    cb(CasesPayload())
end)

RegisterNuiCallback("gestion:afk:addPrize", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:addPrize", data and data.caseId, data and data.prize)
    if not res or not res.success then cb(Wrap(res, "Impossible d'ajouter ce lot.")) return end
    cb(CasesPayload())
end)

RegisterNuiCallback("gestion:afk:editPrize", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:editPrize", data and data.id, data and data.prize)
    if not res or not res.success then cb(Wrap(res, "Impossible de modifier ce lot.")) return end
    cb(CasesPayload())
end)

RegisterNuiCallback("gestion:afk:deletePrize", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:deletePrize", data and data.id)
    if not res or not res.success then cb(Wrap(res, "Impossible de supprimer ce lot.")) return end
    cb(CasesPayload())
end)

RegisterNuiCallback("gestion:afk:points", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local search = (data and data.search) or ""
    local res = TriggerServerCallback("core:afkshop:getPlayersPoints", search, 100)
    cb({ ok = true, players = (res and res.players) or {} })
end)

RegisterNuiCallback("gestion:afk:adjustPoints", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:adjustPoints", data and data.identifier, data and data.delta)
    if not res or not res.success then cb(Wrap(res, "Impossible d'ajuster les points.")) return end
    local search = (data and data.search) or ""
    local list = TriggerServerCallback("core:afkshop:getPlayersPoints", search, 100)
    cb({ ok = true, players = (list and list.players) or {}, newPoints = res.newPoints })
end)

RegisterNuiCallback("gestion:afk:logs", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("core:afkshop:getPurchaseLogs", 100)
    cb({ ok = true, logs = (res and res.logs) or {} })
end)
