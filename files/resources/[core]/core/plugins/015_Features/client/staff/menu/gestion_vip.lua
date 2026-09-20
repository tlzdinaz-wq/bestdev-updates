---@meta _
---@diagnostic disable: duplicate-doc-field

local TIER_LABELS = { [1] = "Bronze", [2] = "Silver", [3] = "Gold" }

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["boutique"] == true
end

local function Wrap(res, fallback)
    if type(res) ~= "table" then return { ok = false, error = fallback or "Action impossible." } end
    if res.success == false then
        return { ok = false, error = res.message or res.error or fallback or "Action impossible." }
    end
    res.ok = true
    return res
end

local function Payload()
    local vehicles = TriggerServerCallback("vip:admin:getMonthlyVehicles") or {}
    local players = TriggerServerCallback("vip:admin:listVIPPlayers") or {}
    local configs = {}
    for tier = 1, 3 do
        local res = TriggerServerCallback("vip:admin:getTierConfig", tier)
        configs[#configs + 1] = {
            tier = tier,
            label = TIER_LABELS[tier],
            config = (res and res.config) or {},
        }
    end
    return {
        ok = true,
        vehicles = vehicles.vehicles or {},
        players = players.players or {},
        configs = configs,
        tiers = TIER_LABELS,
    }
end

RegisterNuiCallback("gestion:vip:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission boutique." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:vip:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Payload())
end)

RegisterNuiCallback("gestion:vip:addVehicle", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("vip:admin:addMonthlyVehicleCallback", data)
    if not res or not res.success then
        cb(Wrap(res, "Impossible d'ajouter ce véhicule."))
        return
    end
    local payload = Payload()
    payload.message = res.message
    cb(payload)
end)

RegisterNuiCallback("gestion:vip:removeVehicle", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("vip:admin:removeMonthlyVehicleCallback", data and data.id)
    if not res or not res.success then
        cb(Wrap(res, "Impossible de supprimer ce véhicule."))
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:vip:setConfig", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("vip:admin:setTierConfigValue", data)
    if not res or not res.success then
        cb(Wrap(res, "Impossible d'enregistrer cette valeur."))
        return
    end
    local payload = Payload()
    payload.message = res.message
    cb(payload)
end)

RegisterNuiCallback("gestion:vip:lookup", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("vip:admin:getPlayerVIPStatus", data and data.serverId)
    cb(Wrap(res, "Joueur introuvable."))
end)

RegisterNuiCallback("gestion:vip:setPlayer", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("vip:admin:setPlayerVIP", data)
    if not res or not res.success then
        cb(Wrap(res, "Impossible d'attribuer le VIP."))
        return
    end
    local payload = Payload()
    payload.message = res.message
    cb(payload)
end)

RegisterNuiCallback("gestion:vip:removePlayer", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("vip:admin:removePlayerVIP", data and data.serverId)
    if not res or not res.success then
        cb(Wrap(res, "Impossible de retirer le VIP."))
        return
    end
    local payload = Payload()
    payload.message = res.message
    cb(payload)
end)
