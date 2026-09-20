Feat27 = Feat27 or {}

local WHEEL_CLASSIC = {
    { type = "spacecoins", amount = 10, label = "10 SC", weight = 30 },
    { type = "spacecoins", amount = 25, label = "25 SC", weight = 25 },
    { type = "spacecoins", amount = 50, label = "50 SC", weight = 15 },
    { type = "money", amount = 2500, label = "2 500 $", weight = 20 },
    { type = "money", amount = 7500, label = "7 500 $", weight = 8 },
    { type = "spacecoins", amount = 150, label = "150 SC", weight = 2 },
}

local WHEEL_VIP = {
    { type = "spacecoins", amount = 50, label = "50 SC", weight = 30 },
    { type = "spacecoins", amount = 100, label = "100 SC", weight = 25 },
    { type = "spacecoins", amount = 200, label = "200 SC", weight = 15 },
    { type = "money", amount = 10000, label = "10 000 $", weight = 20 },
    { type = "money", amount = 25000, label = "25 000 $", weight = 8 },
    { type = "spacecoins", amount = 500, label = "500 SC", weight = 2 },
}

local function streakRewards()
    local config = PaidShopConfig and PaidShopConfig.DailyBonus and PaidShopConfig.DailyBonus.StreakRewards
    if type(config) == "table" then return config end
    return {
        [1] = { type = "spacecoins", amount = 25, label = "25 SC" },
        [2] = { type = "spacecoins", amount = 35, label = "35 SC" },
        [3] = { type = "spacecoins", amount = 50, label = "50 SC" },
        [4] = { type = "spacecoins", amount = 75, label = "75 SC" },
        [5] = { type = "spacecoins", amount = 100, label = "100 SC" },
        [6] = { type = "spacecoins", amount = 150, label = "150 SC" },
        [7] = { type = "spacecoins", amount = 250, label = "250 SC" },
    }
end

local function claimRow(xPlayer)
    local row = MySQL.single.await("SELECT * FROM paidshop_daily_claims WHERE `identifier` = ?", { xPlayer.identifier })
    if row then return row end

    MySQL.insert.await("INSERT IGNORE INTO paidshop_daily_claims (`identifier`, `streak_day`) VALUES (?, 0)", { xPlayer.identifier })
    return MySQL.single.await("SELECT * FROM paidshop_daily_claims WHERE `identifier` = ?", { xPlayer.identifier })
end

local function elapsedSince(value)
    if not value then return math.huge end

    local row
    local millis = type(value) == "number" and value or nil

    if millis then
        row = MySQL.single.await("SELECT TIMESTAMPDIFF(SECOND, FROM_UNIXTIME(? / 1000), NOW()) AS delta", { millis })
    else
        row = MySQL.single.await("SELECT TIMESTAMPDIFF(SECOND, ?, NOW()) AS delta", { value })
    end

    if not row or not row.delta then return math.huge end
    return tonumber(row.delta) or math.huge
end

local function grant(xPlayer, reward)
    if type(reward) ~= "table" then return false, "Cette récompense n'est pas valide" end

    if reward.type == "spacecoins" then
        PaidShop.AddCoins(xPlayer, math.floor(tonumber(reward.amount) or 0))
        return true, reward.label or ("%d Coins"):format(math.floor(tonumber(reward.amount) or 0))
    end

    if reward.type == "money" then
        xPlayer.addAccountMoney("money", math.floor(tonumber(reward.amount) or 0), "boutique-bonus")
        return true, reward.label or ("%d $"):format(math.floor(tonumber(reward.amount) or 0))
    end

    if reward.type == "item" and type(reward.item) == "string" then
        local count = math.floor(tonumber(reward.count) or 1)
        if not Feat27.Inv.CanCarry(xPlayer, reward.item, count) then
            return false, "Votre inventaire est plein"
        end
        Feat27.Inv.Give(xPlayer, reward.item, count, nil, true)
        return true, reward.label or Feat27.Inv.Label(reward.item)
    end

    if reward.type == "vehicle" and type(reward.vehicle) == "string" then
        local ok, result = Feat27.Vehicles.Store(xPlayer.identifier, reward.vehicle, {}, nil, { kind = "car" })
        if not ok then return false, "Livraison du véhicule impossible" end
        return true, reward.label or ("Véhicule %s (plaque %s)"):format(reward.vehicle, tostring(result))
    end

    return false, "Récompense inconnue"
end

local function rollWheel(list)
    local total = 0
    for i = 1, #list do total = total + (tonumber(list[i].weight) or 1) end
    local roll = math.random(1, total)
    local acc = 0
    for i = 1, #list do
        acc = acc + (tonumber(list[i].weight) or 1)
        if roll <= acc then return list[i], i end
    end
    return list[#list], #list
end

RegisterServerCallback("paidshop:getDailyClaimStatus", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { available = false, streakDay = 0, rewards = streakRewards(), cooldown = 86400 }
    end

    local row = claimRow(xPlayer)
    local streak = row and math.floor(tonumber(row.streak_day) or 0) or 0
    local elapsed = elapsedSince(row and row.last_claim_at)
    local available = elapsed >= 86400

    return {
        available = available,
        canClaim = available,
        streakDay = streak,
        currentDay = math.min(streak + 1, 7),
        nextDay = math.min(streak + 1, 7),
        rewards = streakRewards(),
        cooldown = 86400,
        remaining = available and 0 or math.floor(86400 - elapsed),
    }
end)

RegisterServerCallback("paidshop:claimDailyReward", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end
    if not Feat27.RateLimit(source, "paidshop:daily", 2000) then
        return { success = false, message = "Veuillez patienter." }
    end

    local row = claimRow(xPlayer)
    if not row then return { success = false, message = "Impossible de lire votre progression." } end

    if elapsedSince(row.last_claim_at) < 86400 then
        return { success = false, message = "Vous avez déjà réclamé votre bonus aujourd'hui." }
    end

    local streak = math.floor(tonumber(row.streak_day) or 0)
    local nextDay = streak + 1
    if nextDay > 7 then nextDay = 1 end

    local rewards = streakRewards()
    local reward = rewards[nextDay]

    local ok, label = grant(xPlayer, reward)
    if not ok then return { success = false, message = label } end

    MySQL.update.await("UPDATE paidshop_daily_claims SET `streak_day` = ?, `last_claim_at` = NOW() WHERE `identifier` = ?", {
        nextDay, xPlayer.identifier,
    })

    xPlayer.triggerEvent("paidshop:dailyRewardClaimed")

    return {
        success = true,
        message = ("Bonus quotidien réclamé : %s"):format(label),
        streakDay = nextDay,
        reward = reward,
        newBalance = PaidShop.GetCoins(xPlayer),
    }
end)

RegisterServerCallback("paidshop:getDailyRewardWheel", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { classic = WHEEL_CLASSIC, vip = WHEEL_VIP, classicClaimed = false, vipClaimed = false }
    end

    local row = claimRow(xPlayer)

    return {
        classic = WHEEL_CLASSIC,
        vip = WHEEL_VIP,
        classicClaimed = elapsedSince(row and row.wheel_classic_claimed_at) < 86400,
        vipClaimed = elapsedSince(row and row.wheel_vip_claimed_at) < 86400,
    }
end)

RegisterServerCallback("paidshop:spinDailyReward", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end
    if not Feat27.RateLimit(source, "paidshop:wheel", 2000) then
        return { success = false, message = "Veuillez patienter." }
    end

    local track = "classic"
    if type(data) == "table" then
        local requested = data.track or data.type or data.wheel
        if requested == "vip" then track = "vip" end
    end

    if track == "vip" and PaidShop.GetVipTier(xPlayer) <= 0 and not xPlayer.hasPermission("vip_bronze") then
        return { success = false, message = "Roue réservée aux membres VIP." }
    end

    local row = claimRow(xPlayer)
    local column = track == "vip" and "wheel_vip_claimed_at" or "wheel_classic_claimed_at"
    local last = track == "vip" and (row and row.wheel_vip_claimed_at) or (row and row.wheel_classic_claimed_at)

    if elapsedSince(last) < 86400 then
        return { success = false, message = "Vous avez déjà tourné cette roue aujourd'hui." }
    end

    local list = track == "vip" and WHEEL_VIP or WHEEL_CLASSIC
    local reward, index = rollWheel(list)

    local ok, label = grant(xPlayer, reward)
    if not ok then return { success = false, message = label } end

    MySQL.update.await(("UPDATE paidshop_daily_claims SET `%s` = NOW() WHERE `identifier` = ?"):format(column), {
        xPlayer.identifier,
    })

    return {
        success = true,
        message = ("Vous avez gagné : %s"):format(label),
        track = track,
        index = index,
        reward = reward,
        newBalance = PaidShop.GetCoins(xPlayer),
    }
end)
