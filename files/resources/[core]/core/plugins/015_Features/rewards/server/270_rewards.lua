Feat27 = Feat27 or {}

local DEFAULT_GIFTS = {
    { name = "gift_money_1", label = "500 $", isPremium = false, type = "money", amount = 500 },
    { name = "gift_bread", label = "5x Pain", isPremium = false, type = "item", item = "bread", count = 5 },
    { name = "gift_money_2", label = "1 500 $", isPremium = false, type = "money", amount = 1500 },
    { name = "gift_water", label = "5x Eau", isPremium = false, type = "item", item = "eau_plate", count = 5 },
    { name = "gift_money_3", label = "2 500 $", isPremium = false, type = "money", amount = 2500 },
    { name = "gift_vip_money", label = "5 000 $ (VIP)", isPremium = true, type = "money", amount = 5000 },
    { name = "gift_vip_coins", label = "100 Coins (VIP)", isPremium = true, type = "spacecoins", amount = 100 },
}

local function config()
    return Rewards or {}
end

local function currentTheme()
    local cfg = config()
    local month = tonumber(os.date("%m")) or 1
    local map = cfg.MonthToTheme
    if type(map) == "table" and map[month] then return map[month] end
    return 1
end

local function progressRow(xPlayer)
    local row = MySQL.single.await("SELECT * FROM rewards_progress WHERE `identifier` = ?", { xPlayer.identifier })
    if row then return row end

    MySQL.insert.await(
        "INSERT IGNORE INTO rewards_progress (`identifier`, `theme`, `last_gift_index`, `last_gift_timestamp`, `last_vip_gift_timestamp`) VALUES (?, ?, -1, 0, 0)",
        { xPlayer.identifier, currentTheme() }
    )
    return MySQL.single.await("SELECT * FROM rewards_progress WHERE `identifier` = ?", { xPlayer.identifier })
end

local function isVip(xPlayer)
    local cfg = config()
    if (tonumber(xPlayer.vipTier) or 0) > 0 then return true end
    if cfg.VIPPermission and xPlayer.hasPermission(cfg.VIPPermission) then return true end
    if cfg.VIPPlusPermission and xPlayer.hasPermission(cfg.VIPPlusPermission) then return true end
    return false
end

local function buildPayload(xPlayer, row)
    local cfg = config()
    local gifts = {}
    for i = 1, #DEFAULT_GIFTS do
        gifts[i] = {
            name = DEFAULT_GIFTS[i].name,
            label = DEFAULT_GIFTS[i].label,
            isPremium = DEFAULT_GIFTS[i].isPremium,
        }
    end

    return {
        theme = math.floor(tonumber(row and row.theme) or currentTheme()),
        lastGiftTimestamp = math.floor(tonumber(row and row.last_gift_timestamp) or 0),
        lastGiftIndex = math.floor(tonumber(row and row.last_gift_index) or -1),
        giftCooldown = math.floor(tonumber(cfg.RegularCooldown) or 86400000),
        gifts = gifts,
        isVip = isVip(xPlayer),
    }
end

local function grant(xPlayer, gift)
    if type(gift) ~= "table" then return false, "Cette récompense n'est pas valide" end

    if gift.type == "money" then
        xPlayer.addAccountMoney("money", math.floor(tonumber(gift.amount) or 0), "rewards")
        return true, gift.label
    end

    if gift.type == "spacecoins" then
        if PaidShop and PaidShop.AddCoins then
            PaidShop.AddCoins(xPlayer, math.floor(tonumber(gift.amount) or 0))
            return true, gift.label
        end
        return false, "Boutique indisponible"
    end

    if gift.type == "item" and type(gift.item) == "string" then
        local count = math.floor(tonumber(gift.count) or 1)
        if not Feat27.Inv.CanCarry(xPlayer, gift.item, count) then
            return false, "Votre inventaire est plein"
        end
        Feat27.Inv.Give(xPlayer, gift.item, count, nil, true)
        return true, gift.label
    end

    return false, "Récompense inconnue"
end

RegisterNetEvent("rewards:openPanel", function()
    local source = source
    if not Feat27.RateLimit(source, "rewards:open", 1000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = progressRow(xPlayer)
    TriggerClientEvent("rewards:openNUI", source, buildPayload(xPlayer, row))
end)

RegisterNetEvent("rewards:claimGift", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not Feat27.RateLimit(source, "rewards:claim", 2000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local giftIndex = math.floor(tonumber(data.giftIndex) or 0)
    local track = data.track == "vip" and "vip" or "regular"

    local gift = DEFAULT_GIFTS[giftIndex]
    if not gift then
        Feat27.NotifyError(source, "Récompense introuvable.")
        return
    end

    if track == "vip" and not isVip(xPlayer) then
        Feat27.NotifyError(source, "Cette récompense est réservée aux VIP.")
        return
    end

    if gift.isPremium and not isVip(xPlayer) then
        Feat27.NotifyError(source, "Cette récompense est réservée aux VIP.")
        return
    end

    local cfg = config()
    local row = progressRow(xPlayer)
    local now = os.time() * 1000

    local lastTimestamp = math.floor(tonumber(track == "vip" and row.last_vip_gift_timestamp or row.last_gift_timestamp) or 0)
    local cooldown = math.floor(tonumber(track == "vip" and cfg.VIPCooldown or cfg.RegularCooldown) or 86400000)

    if lastTimestamp > 0 and (now - lastTimestamp) < cooldown then
        Feat27.NotifyError(source, "Vous avez déjà réclamé cette récompense aujourd'hui.")
        return
    end

    local ok, label = grant(xPlayer, gift)
    if not ok then
        Feat27.NotifyError(source, label or "Récompense indisponible.")
        return
    end

    if track == "vip" then
        MySQL.update.await("UPDATE rewards_progress SET `last_vip_gift_timestamp` = ? WHERE `identifier` = ?", { now, xPlayer.identifier })
    else
        MySQL.update.await("UPDATE rewards_progress SET `last_gift_timestamp` = ?, `last_gift_index` = ? WHERE `identifier` = ?", {
            now, giftIndex, xPlayer.identifier,
        })
    end

    MySQL.insert("INSERT INTO rewards_history (`identifier`, `track`, `gift_index`) VALUES (?, ?, ?)", {
        xPlayer.identifier, track, giftIndex,
    })

    local updated = progressRow(xPlayer)
    TriggerClientEvent("rewards:updateProgress", source, buildPayload(xPlayer, updated))
    TriggerClientEvent("rewards:updateGifts", source, buildPayload(xPlayer, updated))

    Feat27.NotifyOk(source, ("Récompense réclamée : %s"):format(label or gift.label))
end)
