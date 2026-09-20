Feat27 = Feat27 or {}

local BAIT_ITEM = "bait"
local ROD_ITEM = "fishroad"

local function fishes()
    local list = Config and Config.fishing and Config.fishing.fishes or {}
    return list
end

local function fishPrices()
    local out = {}
    local list = fishes()
    for i = 1, #list do
        out[list[i].name] = tonumber(list[i].price) or 0
    end
    return out
end

local function rollFish(isVip)
    local list = fishes()
    if #list == 0 then return nil end

    local total = 0
    for i = 1, #list do
        total = total + math.max(1, math.floor(tonumber(list[i].price) or 1))
    end

    if isVip then
        return list[math.random(1, #list)]
    end

    local roll = math.random(1, total)
    local acc = 0
    for i = #list, 1, -1 do
        acc = acc + math.max(1, math.floor(tonumber(list[i].price) or 1))
        if roll <= acc then return list[i] end
    end
    return list[#list]
end

local function giveFish(xPlayer)
    local fish = rollFish(LegalActivities.IsVip(xPlayer))
    if not fish then return false end
    if not Feat27.Inv.CanCarry(xPlayer, fish.name, 1) then
        Feat27.NotifyError(xPlayer.source, "Votre inventaire est plein.")
        return false
    end
    Feat27.Inv.Give(xPlayer, fish.name, 1, nil, true)
    return true
end

RegisterServerCallback("core:legal_activities:fishing:isVip", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return LegalActivities.IsVip(xPlayer)
end)

RegisterServerCallback("core:legal_activities:fishing:putBait", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not Feat27.RateLimit(source, "fishing:bait", 1000) then return false end

    if not Feat27.Inv.Has(xPlayer, BAIT_ITEM, 1) then
        Feat27.NotifyError(source, "Vous n'avez pas d'appât.")
        return false
    end

    return Feat27.Inv.Take(xPlayer, BAIT_ITEM, 1, false)
end)

RegisterServerCallback("core:legal_activities:fishing:autoFishResult", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { isVip = false, success = false } end
    if not Feat27.RateLimit(source, "fishing:auto", 2000) then
        return { isVip = false, success = false }
    end

    local isVip = LegalActivities.IsVip(xPlayer)
    if not isVip then
        return { isVip = false, success = false }
    end

    if not Feat27.Inv.Has(xPlayer, ROD_ITEM, 1) then
        return { isVip = false, success = false }
    end

    local success = math.random(1, 100) <= 75
    if success then
        success = giveFish(xPlayer)
    end

    return { isVip = true, success = success }
end)

RegisterServerCallback("core:legal_activities:fishing:reward", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not Feat27.RateLimit(source, "fishing:reward", 1500) then return false end

    if not Feat27.Inv.Has(xPlayer, ROD_ITEM, 1) then return false end

    giveFish(xPlayer)
    return LegalActivities.IsVip(xPlayer)
end)

RegisterServerCallback("core:legal_activities:fishing:getMyFishes", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local list = fishes()
    local out = {}
    for i = 1, #list do
        local name = list[i].name
        out[#out + 1] = {
            name = name,
            label = Feat27.Inv.Label(name),
            count = Feat27.Inv.Count(xPlayer, name),
            price = tonumber(list[i].price) or 0,
            image = Feat27.Inv.Image(name),
        }
    end
    return out
end)

RegisterNetEvent("core:legal_activities:fishing:resell", function(name, count, paymentType)
    local source = source
    if type(name) ~= "string" then return end

    local amount = math.floor(tonumber(count) or 0)
    if amount <= 0 then return end
    if not Feat27.RateLimit(source, "fishing:sell", 400) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local price = fishPrices()[name]
    if not price or price <= 0 then return end

    if Feat27.Inv.Count(xPlayer, name) < amount then
        Feat27.NotifyError(source, "Vous n'avez pas assez de poissons.")
        return
    end

    if not Feat27.Inv.Take(xPlayer, name, amount, false) then return end

    local total = math.floor(price * amount)
    LegalActivities.Pay(xPlayer, total, paymentType, "peche-revente")
    LegalActivities.Log(xPlayer.identifier, "fishing", name, amount, total, paymentType)
    Feat27.NotifyOk(source, ("Vous avez vendu %d poisson%s pour %d$."):format(amount, amount > 1 and "s" or "", total))
end)

CreateThread(function()
    while not VFW or not VFW.Inventory or not VFW.Inventory.RegisterUsableItem do Wait(500) end
    VFW.Inventory.RegisterUsableItem(ROD_ITEM, function(xPlayer)
        local source = xPlayer.source
        CreateThread(function()
            local canFish = TriggerClientCallback(source, "core:legal_activities:fishing:canFish")
            if canFish ~= true then
                Feat27.NotifyError(source, "Vous ne pouvez pas pêcher ici.")
            end
        end)
    end)
end)
