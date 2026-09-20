local Inv = VFW.Inventory

Inv.PendingRefund = Inv.PendingRefund or {}
Inv.ScratchSessions = Inv.ScratchSessions or {}

local SCRATCH_ITEM = "ticket_gratter"
local REFUND_WINDOW = 30000

local defaultPrizeTiers = {
    { amount = 500, probability = 30 },
    { amount = 1500, probability = 10 },
    { amount = 3000, probability = 2 },
    { amount = 10000, probability = 0.3 },
    { amount = 30000, probability = 0.02 },
    { amount = 50000, probability = 0.015 },
    { amount = 100000, probability = 0.01 },
    { amount = 500000, probability = 0.001 },
}

local function markRefundable(source, name, count)
    Inv.PendingRefund[source] = {
        name = name,
        count = count,
        expires = GetGameTimer() + REFUND_WINDOW,
    }
end

local function consumeOne(xPlayer, entry)
    local list = Inv.PlayerList(xPlayer)
    local removed = Inv.RemoveFromSlot(list, entry.slot, 1)
    return removed ~= nil
end

local function simpleEffect(eventName, consume)
    return function(xPlayer, entry)
        if consume then
            if not consumeOne(xPlayer, entry) then return end
            markRefundable(xPlayer.source, entry.name, 1)
        end
        TriggerClientEvent(eventName, xPlayer.source)
    end
end

Inv.RegisterUsableItem("cigar", simpleEffect("core:UseCigar", true))
Inv.RegisterUsableItem("cigarette", simpleEffect("core:UseCigar", true))
Inv.RegisterUsableItem("cocaine", simpleEffect("core:CokeEffect", true))
Inv.RegisterUsableItem("pochon_cocaine", simpleEffect("core:CokeEffect", true))
Inv.RegisterUsableItem("fentanyl", simpleEffect("core:FentanylEffect", true))
Inv.RegisterUsableItem("weed", simpleEffect("core:WeedEffect", true))
Inv.RegisterUsableItem("pochon_weed", simpleEffect("core:WeedEffect", true))
Inv.RegisterUsableItem("meth", simpleEffect("core:MethEffect", true))
Inv.RegisterUsableItem("pochon_meth", simpleEffect("core:MethEffect", true))
Inv.RegisterUsableItem("pince", simpleEffect("core:UsePince", false))
Inv.RegisterUsableItem("makeup", simpleEffect("core:UseMakeup", false))
Inv.RegisterUsableItem("ciseau", simpleEffect("core:UseCiseau", false))

Inv.RegisterUsableItem("spray", function(xPlayer)
    TriggerClientEvent("vfw:graffiti:use", xPlayer.source, "spray")
end)

Inv.RegisterUsableItem("spray_remover", function(xPlayer)
    TriggerClientEvent("vfw:graffiti:use", xPlayer.source, "clean")
end)

local function getPrizeTiers()
    if VFW.Variables and VFW.Variables.GetVariable then
        local ok, stored = pcall(VFW.Variables.GetVariable, "scratchcard_config")
        if ok and type(stored) == "table" and type(stored.prizeTiers) == "table" and #stored.prizeTiers > 0 then
            return stored.prizeTiers
        end
    end
    return defaultPrizeTiers
end

local function rollPrize()
    local tiers = getPrizeTiers()
    local roll = math.random() * 100.0
    local cumulative = 0.0

    for i = 1, #tiers do
        local tier = tiers[i]
        local amount = math.floor(tonumber(tier.amount) or 0)
        local probability = tonumber(tier.probability) or 0
        if amount > 0 and probability > 0 then
            cumulative = cumulative + probability
            if roll <= cumulative then
                return amount
            end
        end
    end

    return 0
end

local function buildScratchConfig(prize)
    local cells = {}
    local winningIndexes = {}

    if prize > 0 then
        while #winningIndexes < 3 do
            local index = math.random(1, 20)
            local exists = false
            for i = 1, #winningIndexes do
                if winningIndexes[i] == index then exists = true break end
            end
            if not exists then winningIndexes[#winningIndexes + 1] = index end
        end
    end

    local decoys = { 500, 1500, 3000, 10000, 30000, 50000, 100000, 500000 }

    for i = 1, 20 do
        cells[i] = decoys[math.random(1, #decoys)]
    end

    for i = 1, #winningIndexes do
        cells[winningIndexes[i]] = prize
    end

    return {
        cells = cells,
        winning = winningIndexes,
        prize = prize,
        prizeTiers = getPrizeTiers(),
    }
end

local function startScratchCard(xPlayer, entry)
    if not consumeOne(xPlayer, entry) then return false end

    local prize = rollPrize()
    local config = buildScratchConfig(prize)

    Inv.ScratchSessions[xPlayer.source] = { prize = prize, startedAt = GetGameTimer() }

    TriggerClientEvent("core:UseScratchCard", xPlayer.source, config)
    return true
end

Inv.RegisterUsableItem(SCRATCH_ITEM, function(xPlayer, entry)
    startScratchCard(xPlayer, entry)
end)

Inv.RegisterNet("core:MiaCooperSousBBL69", function(itemName, quantity)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(itemName) ~= "string" or not Inv.Exists(itemName) then return end

    local count = math.floor(tonumber(quantity) or 0)
    if count <= 0 then return end

    local pending = Inv.PendingRefund[source]
    if not pending or pending.name ~= itemName or GetGameTimer() > pending.expires then return end
    if count > pending.count then count = pending.count end

    pending.count = pending.count - count
    if pending.count <= 0 then
        Inv.PendingRefund[source] = nil
    end

    Inv.AddToList(Inv.PlayerList(xPlayer), itemName, count, nil, Inv.PlayerMaxSlots)
    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterNet("core:scratchcard:close", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(data) ~= "table" then return end

    local session = Inv.ScratchSessions[source]
    if not session then return end

    Inv.ScratchSessions[source] = nil

    if session.prize > 0 then
        Inv.AddToList(Inv.PlayerList(xPlayer), "money", session.prize, nil, Inv.PlayerMaxSlots)
        Inv.PushPlayer(xPlayer)
        TriggerClientEvent("vfw:showItemNotification", source, "money", session.prize, 1)
    end

    if data.next ~= true then return end

    local list = Inv.PlayerList(xPlayer)
    local entry
    for i = 1, #list do
        if list[i].name == SCRATCH_ITEM then
            entry = list[i]
            break
        end
    end

    if not entry then
        TriggerClientEvent("core:scratchcard:nomore", source)
        return
    end

    if not startScratchCard(xPlayer, entry) then
        TriggerClientEvent("core:scratchcard:nomore", source)
        return
    end

    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterNet("ciseau:requestCut", function(targetServerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local targetId = tonumber(targetServerId)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or target.source == source then return end

    local distance = Inv.Distance(Inv.PlayerCoords(source), Inv.PlayerCoords(target.source))
    if distance > 3.5 then
        Inv.Toast(source, "Vous êtes trop loin.")
        return
    end

    local list = Inv.PlayerList(xPlayer)
    local entry
    for i = 1, #list do
        if list[i].name == "ciseau" then
            entry = list[i]
            break
        end
    end

    if not entry then
        Inv.Toast(source, "Vous n'avez pas de ciseau.")
        return
    end

    TriggerClientEvent("ciseau:applyHaircut", target.source, source)
end)

AddEventHandler("vfw:playerDropped", function(source)
    Inv.PendingRefund[source] = nil
    Inv.ScratchSessions[source] = nil
end)
