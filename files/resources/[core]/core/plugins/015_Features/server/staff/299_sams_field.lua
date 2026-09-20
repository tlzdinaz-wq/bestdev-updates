local stretchers = {}
local vehicleExtras = {}
local wheelchairs = {}
local wheelchairPending = {}
local pendingRevives = {}

local HEAL_LIGHT = 40
local HEAL_HEAVY = 100
local HEAL_LIGHT_DURATION = 8000
local HEAL_HEAVY_DURATION = 15000
local CPR_FALLBACK = 32000

local function SAMS()
    return Staff29.SAMS
end

local function finalizeRevive(targetSource, medicSource)
    local pending = pendingRevives[targetSource]
    if not pending then return end
    pendingRevives[targetSource] = nil

    local target = VFW.GetPlayerFromId(targetSource)
    if not target then return end

    target.revive()

    local medic = VFW.GetPlayerFromId(medicSource or pending.medicSource)
    if medic then
        medic.showNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "SAMS",
            message = ("%s a été réanimé."):format(target.name),
        })
        Staff29.Insert([[
            INSERT INTO sams_logs (hospital, agent, action, details, created_at) VALUES (?, ?, ?, ?, ?)
        ]], { SAMS().Hospital(medic), medic.name, "revive", target.name, Staff29.Now() })
    end
end

local function startRevive(medicSource, targetSource)
    if pendingRevives[targetSource] then return end

    pendingRevives[targetSource] = {
        medicSource = medicSource,
        startedAt = GetGameTimer(),
    }

    TriggerClientEvent("sn_sams:reviveAnimPatient", targetSource, medicSource)

    VFW.SetTimeout(CPR_FALLBACK, function()
        if pendingRevives[targetSource] then
            finalizeRevive(targetSource, medicSource)
        end
    end)
end

RegisterNetEvent("sn_sams:healPlayer", function(targetId, healType)
    local source = source

    local target = Staff29.ToInt(targetId, 1, 1024)
    if not target then return end
    if healType ~= "revive" and healType ~= "light" and healType ~= "heavy" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget or xPlayer.source == xTarget.source then return end

    if not SAMS().HasJob(xPlayer) or not xPlayer.job.onDuty then return end
    if not Staff29.Distance(source, target, 3.0) then return end
    if not Staff29.RateLimit(source, "samsHeal", 2000) then return end

    if healType == "revive" then
        startRevive(source, target)
        return
    end

    local amount = healType == "light" and HEAL_LIGHT or HEAL_HEAVY
    local duration = healType == "light" and HEAL_LIGHT_DURATION or HEAL_HEAVY_DURATION

    xPlayer.triggerEvent("sn_sams:playHealAnim", duration)

    VFW.SetTimeout(duration, function()
        local stillThere = VFW.GetPlayerFromId(target)
        if stillThere then
            stillThere.triggerEvent("sn_sams:applyHeal", amount)
        end
    end)
end)

RegisterNetEvent("sn_sams:reviveAnimMedic", function(medicServerId)
    local source = source

    local medic = Staff29.ToInt(medicServerId, 1, 1024)
    if not medic then return end

    local pending = pendingRevives[source]
    if not pending or pending.medicSource ~= medic then return end

    TriggerClientEvent("sn_sams:reviveAnimMedic", medic)
end)

RegisterNetEvent("sn_sams:cprAnimDone", function()
    local source = source
    if not pendingRevives[source] then return end
    finalizeRevive(source, nil)
end)

RegisterNetEvent("sn_sams:civilRevive", function(targetServerId)
    local source = source

    local target = Staff29.ToInt(targetServerId, 1, 1024)
    if not target then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget or xPlayer.source == xTarget.source then return end
    if not Staff29.Distance(source, target, 3.0) then return end
    if not Staff29.RateLimit(source, "civilRevive", 3000) then return end

    if not xPlayer.haveItem("medikit", 1) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Soins",
            message = "Vous n'avez pas de medikit.",
        })
        return
    end

    xPlayer.removeInventoryItem("medikit", 1, nil, true)
    startRevive(source, target)
end)

local ITEM_HANDLERS = {
    medikit = function(src) TriggerClientEvent("sn_sams:useMedikit", src) end,
    band = function(src) TriggerClientEvent("sn_sams:useBandage", src) end,
    bequille = function(src) TriggerClientEvent("sn_sams:useBequille", src) end,
    sams_document = function(src, metadata) TriggerClientEvent("sn_sams:openPaperDocument", src, metadata or {}) end,
    contract = function(src, metadata) TriggerClientEvent("contract:viewDocument", src, metadata or {}) end,
}

ITEM_HANDLERS.wheelchair = function(src)
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return end
    if wheelchairPending[src] then return end

    if not xPlayer.haveItem("wheelchair", 1) then return end

    xPlayer.removeInventoryItem("wheelchair", 1, nil, true)
    wheelchairPending[src] = true
    TriggerClientEvent("sn_sams:wheelchair:spawn", src)

    VFW.SetTimeout(15000, function()
        wheelchairPending[src] = nil
    end)
end

function Staff29.HandleItemUse(source, itemName, metadata)
    local handler = ITEM_HANDLERS[itemName]
    if not handler then return false end
    if not VFW.GetPlayerFromId(source) then return false end
    handler(source, metadata)
    return true
end

AddEventHandler("vfw:item:used", function(source, itemName, metadata)
    Staff29.HandleItemUse(source, itemName, metadata)
end)

AddEventHandler("vfw:inventory:itemUsed", function(source, itemName, metadata)
    Staff29.HandleItemUse(source, itemName, metadata)
end)

RegisterNetEvent("sn_sams:wheelchair:spawnFailed", function()
    local source = source
    if not wheelchairPending[source] then return end

    wheelchairPending[source] = nil

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if VFW.Items and VFW.Items["wheelchair"] then
        xPlayer.addInventoryItem("wheelchair", 1, nil, false)
    end
end)

RegisterNetEvent("sn_sams:wheelchair:register", function(netId)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end
    if not VFW.GetPlayerFromId(source) then return end
    if not wheelchairPending[source] then return end

    wheelchairPending[source] = nil
    wheelchairs[id] = { owner = source, sitter = nil }

    local entity = NetworkGetEntityFromNetworkId(id)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        Entity(entity).state:set("wheelchair", { sitter = nil }, true)
    end
end)

RegisterNetEvent("sn_sams:wheelchair:sit", function(netId)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end
    if not VFW.GetPlayerFromId(source) then return end

    local chair = wheelchairs[id]
    if not chair then return end
    if chair.sitter ~= nil then return end

    chair.sitter = source

    local entity = NetworkGetEntityFromNetworkId(id)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        Entity(entity).state:set("wheelchair", { sitter = source }, true)
    end

    TriggerClientEvent("sn_sams:wheelchair:sitGranted", source, id)
end)

RegisterNetEvent("sn_sams:wheelchair:unsit", function(netId)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end

    local chair = wheelchairs[id]
    if not chair or chair.sitter ~= source then return end

    chair.sitter = nil

    local entity = NetworkGetEntityFromNetworkId(id)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        Entity(entity).state:set("wheelchair", { sitter = nil }, true)
    end
end)

RegisterNetEvent("sn_sams:wheelchair:pickup", function(netId)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local chair = wheelchairs[id]
    if not chair or chair.sitter ~= nil then return end

    local entity = NetworkGetEntityFromNetworkId(id)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        pcall(DeleteEntity, entity)
    end

    wheelchairs[id] = nil

    if VFW.Items and VFW.Items["wheelchair"] then
        xPlayer.addInventoryItem("wheelchair", 1, nil, true)
    end
end)

RegisterNetEvent("sn_sams:stretcher:add", function(netId)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end
    if not VFW.GetPlayerFromId(source) then return end

    stretchers[id] = { moving = false, sitting = false }
    TriggerClientEvent("sn_sams:stretcher:syncAll", -1, stretchers)
end)

RegisterNetEvent("sn_sams:stretcher:remove", function(netId)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end
    if not VFW.GetPlayerFromId(source) then return end

    stretchers[id] = nil
    TriggerClientEvent("sn_sams:stretcher:syncRemove", -1, id)
end)

RegisterNetEvent("sn_sams:stretcher:setMoving", function(netId, bool)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id or type(bool) ~= "boolean" then return end
    if not VFW.GetPlayerFromId(source) then return end

    stretchers[id] = stretchers[id] or { moving = false, sitting = false }
    stretchers[id].moving = bool

    TriggerClientEvent("sn_sams:stretcher:syncMoving", -1, id, bool)
end)

RegisterNetEvent("sn_sams:stretcher:setSitting", function(netId, bool)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id or type(bool) ~= "boolean" then return end
    if not VFW.GetPlayerFromId(source) then return end

    stretchers[id] = stretchers[id] or { moving = false, sitting = false }
    stretchers[id].sitting = bool

    TriggerClientEvent("sn_sams:stretcher:syncSitting", -1, id, bool)
end)

RegisterNetEvent("sn_sams:stretcher:setVehicleExtra", function(vehicleNetId, extraIndex, state)
    local source = source

    local id = Staff29.ToInt(vehicleNetId, 1, 2147483647)
    local index = Staff29.ToInt(extraIndex, 0, 20)
    if not id or not index or type(state) ~= "boolean" then return end
    if not VFW.GetPlayerFromId(source) then return end

    vehicleExtras[id] = vehicleExtras[id] or {}
    vehicleExtras[id][index] = state

    TriggerClientEvent("sn_sams:stretcher:syncVehicleExtra", -1, id, index, state)
end)

RegisterNetEvent("sn_sams:stretcher:toggleDoors", function(netId, fld, frd, bld, brd, hood, trunk, rld, rrd)
    local source = source

    local id = Staff29.ToInt(netId, 1, 2147483647)
    if not id then return end
    if not VFW.GetPlayerFromId(source) then return end

    local flags = { fld, frd, bld, brd, hood, trunk, rld, rrd }
    for i = 1, #flags do
        if type(flags[i]) ~= "boolean" then return end
    end

    TriggerClientEvent("sn_sams:stretcher:syncDoors", -1, id, fld, frd, bld, brd, hood, trunk, rld, rrd)
end)

RegisterNetEvent("sn_sams:stretcher:relayPatientToVehicle", function(targetSrc, vehicleNetId, patientOffset)
    local source = source

    local target = Staff29.ToInt(targetSrc, 1, 1024)
    local netId = Staff29.ToInt(vehicleNetId, 1, 2147483647)
    if not target or not netId or not Staff29.IsTable(patientOffset) then return end

    if not VFW.GetPlayerFromId(source) or not VFW.GetPlayerFromId(target) then return end
    if not Staff29.Distance(source, target, 12.0) then return end

    TriggerClientEvent("sn_sams:stretcher:onPatientToVehicle", target, netId, patientOffset)
end)

RegisterNetEvent("sn_sams:stretcher:relayPatientToStretcher", function(targetSrc, stretcherNetId)
    local source = source

    local target = Staff29.ToInt(targetSrc, 1, 1024)
    local netId = Staff29.ToInt(stretcherNetId, 1, 2147483647)
    if not target or not netId then return end

    if not VFW.GetPlayerFromId(source) or not VFW.GetPlayerFromId(target) then return end
    if not Staff29.Distance(source, target, 12.0) then return end

    TriggerClientEvent("sn_sams:stretcher:onPatientToStretcher", target, netId)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    if not source or source == 0 then return end
    VFW.SetTimeout(3000, function()
        if not VFW.GetPlayerFromId(source) then return end
        TriggerClientEvent("sn_sams:stretcher:syncAll", source, stretchers)
        TriggerClientEvent("sn_sams:stretcher:syncAllExtras", source, vehicleExtras)
    end)
end)

AddEventHandler("vfw:playerDropped", function(source)
    wheelchairPending[source] = nil
    pendingRevives[source] = nil

    for netId, chair in pairs(wheelchairs) do
        if chair.sitter == source then
            chair.sitter = nil
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                Entity(entity).state:set("wheelchair", { sitter = nil }, true)
            end
        end
    end

    for targetSource, pending in pairs(pendingRevives) do
        if pending.medicSource == source then
            pendingRevives[targetSource] = nil
        end
    end
end)

VFW.RegisterCommand("clearstretchers", "gestion", function(source, xPlayer)
    stretchers = {}
    vehicleExtras = {}
    TriggerClientEvent("sn_sams:stretcher:cleanup", -1)
    Staff29.Notify(source, "SUCCESS", "SAMS", "Tous les brancards ont été nettoyés.")
end, { help = "Supprimer tous les brancards du serveur." })

VFW.RegisterCommand("clearpharmacynpcs", "pharmacy_builder", function(source, xPlayer)
    TriggerClientEvent("sn_sams:pharmacy:cleanupAllNPCs", -1)
    Staff29.Notify(source, "SUCCESS", "SAMS", "PNJ pharmaciens nettoyés.")
end, { help = "Nettoyer les PNJ des pharmacies." })
