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

--- Nombre de tickets qu'il reste dans l'inventaire (affiché : « N tickets restants » + bouton Suivant).
local function remainingTickets(xPlayer)
    local total = 0
    local list = Inv.PlayerList(xPlayer)
    for i = 1, #list do
        if list[i].name == SCRATCH_ITEM then total = total + (tonumber(list[i].count) or 1) end
    end
    return total
end

local function shuffled(from, to)
    local out = {}
    for n = from, to do out[#out + 1] = n end
    for i = #out, 2, -1 do
        local j = math.random(1, i)
        out[i], out[j] = out[j], out[i]
    end
    return out
end

--- Le ticket tel que l'interface le lit : 3 numéros gagnants, 20 cases { value, prize }. Une case gagne si son
--- numéro est l'un des numéros gagnants, et rapporte son montant. L'ancienne version envoyait un autre format
--- (cells / winning) : l'interface ne trouvait aucune case, plantait au premier grattage, n'affichait aucun gain
--- et laissait le joueur bloqué.
--- Un ticket gagnant a UNE case gagnante (le montant tiré) ; un ticket perdant n'en a aucune.
local function buildScratchConfig(prize, remaining)
    local tiers = getPrizeTiers()
    local amounts, maxPrize = {}, 0
    for i = 1, #tiers do
        local amount = math.floor(tonumber(tiers[i].amount) or 0)
        if amount > 0 then
            amounts[#amounts + 1] = amount
            if amount > maxPrize then maxPrize = amount end
        end
    end
    if #amounts == 0 then amounts[1] = 500; maxPrize = 500 end

    local numbers = shuffled(1, 60)
    local winning = { numbers[1], numbers[2], numbers[3] }

    local cells = {}
    for i = 1, 20 do
        cells[i] = { value = numbers[3 + i], prize = amounts[math.random(1, #amounts)] }
    end

    if prize > 0 then
        cells[math.random(1, 20)] = { value = winning[math.random(1, 3)], prize = prize }
        if prize > maxPrize then maxPrize = prize end
    end

    return {
        winningNumbers = winning,
        playerNumbers = cells,
        maxPrize = maxPrize,
        remainingTickets = remaining or 0,
    }
end

--- Un tirage : le ticket est consommé et le gain est versé tout de suite. Avant, il n'était versé qu'à la
--- fermeture du ticket : un joueur qui se déconnectait ou dont l'écran se bloquait perdait son gain.
local function startScratchCard(xPlayer, entry)
    if not consumeOne(xPlayer, entry) then return false end

    local prize = rollPrize()
    if prize > 0 then
        Inv.AddToList(Inv.PlayerList(xPlayer), "money", prize, nil, Inv.PlayerMaxSlots)
    end
    Inv.PushPlayer(xPlayer)

    Inv.ScratchSessions[xPlayer.source] = { prize = prize, startedAt = GetGameTimer() }

    TriggerClientEvent("core:UseScratchCard", xPlayer.source, buildScratchConfig(prize, remainingTickets(xPlayer)))
    return true
end

--- Le client refuse de gratter au volant : on ne consomme donc pas le ticket dans ce cas.
local function isDriving(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped
end

Inv.RegisterUsableItem(SCRATCH_ITEM, function(xPlayer, entry)
    if isDriving(xPlayer.source) then
        Inv.Toast(xPlayer.source, "Vous ne pouvez pas gratter un ticket en conduisant.")
        return
    end
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

    -- le gain a été versé au tirage : la mise à jour d'inventaire l'a déjà annoncé

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
