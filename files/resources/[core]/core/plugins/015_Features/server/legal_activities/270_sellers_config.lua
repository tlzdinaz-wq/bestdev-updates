Feat27 = Feat27 or {}

LegalActivities = LegalActivities or {}

LegalActivities.Activities = { "fishing", "hunting", "diving" }

local DEFAULT_SELLERS = {
    fishing = {
        { index = 1, model = "ig_cletus", x = -1839.61, y = -1223.15, z = 13.02, w = 232.0 },
    },
    hunting = {
        { index = 1, model = "s_m_m_lathandy_01", x = -1492.26, y = 4978.32, z = 62.50, w = 93.15 },
    },
    diving = {
        { index = 1, model = "s_m_m_highsec_01", x = -1605.13, y = 5261.05, z = 3.87, w = 313.0 },
    },
}

local function isActivity(name)
    for i = 1, #LegalActivities.Activities do
        if LegalActivities.Activities[i] == name then return true end
    end
    return false
end

LegalActivities.IsActivity = isActivity

function LegalActivities.LoadSellers()
    local rows = MySQL.query.await("SELECT * FROM legal_activity_sellers") or {}

    if #rows == 0 then
        for activity, list in pairs(DEFAULT_SELLERS) do
            for i = 1, #list do
                local seller = list[i]
                MySQL.query.await([[
                    INSERT IGNORE INTO legal_activity_sellers (`activity`, `seller_index`, `model`, `x`, `y`, `z`, `w`, `visible`)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 1)
                ]], { activity, seller.index, seller.model, seller.x, seller.y, seller.z, seller.w })
            end
        end
        rows = MySQL.query.await("SELECT * FROM legal_activity_sellers") or {}
    end

    local out = {}
    for i = 1, #LegalActivities.Activities do
        out[LegalActivities.Activities[i]] = { sellers = {} }
    end

    for i = 1, #rows do
        local row = rows[i]
        local bucket = out[row.activity]
        if bucket then
            bucket.sellers[#bucket.sellers + 1] = {
                index = row.seller_index,
                model = row.model,
                coords = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0, w = row.w + 0.0 },
                visible = row.visible == 1,
            }
        end
    end

    return out
end

RegisterServerCallback("legalActivities:getConfig", function(source)
    local ok, config = pcall(LegalActivities.LoadSellers)
    if not ok then return {} end
    return config
end)

function LegalActivities.SetSellerPosition(activity, sellerIndex, posData)
    if not isActivity(activity) then return false end
    local index = tonumber(sellerIndex)
    if not index or type(posData) ~= "table" then return false end

    local visible = posData.visible
    if visible == nil then visible = true end

    MySQL.query.await([[
        INSERT INTO legal_activity_sellers (`activity`, `seller_index`, `model`, `x`, `y`, `z`, `w`, `visible`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `model` = VALUES(`model`), `x` = VALUES(`x`), `y` = VALUES(`y`),
            `z` = VALUES(`z`), `w` = VALUES(`w`), `visible` = VALUES(`visible`)
    ]], {
        activity, index, tostring(posData.model or ""),
        tonumber(posData.x) or 0.0, tonumber(posData.y) or 0.0,
        tonumber(posData.z) or 0.0, tonumber(posData.w) or 0.0,
        visible and 1 or 0,
    })

    TriggerClientEvent("legalActivities:sellerPositionUpdated", -1, activity, tostring(index), {
        x = tonumber(posData.x) or 0.0,
        y = tonumber(posData.y) or 0.0,
        z = tonumber(posData.z) or 0.0,
        w = tonumber(posData.w) or 0.0,
        model = posData.model,
        visible = visible,
    })
    return true
end

function LegalActivities.SetSellerVisibility(activity, sellerIndex, visible)
    if not isActivity(activity) then return false end
    local index = tonumber(sellerIndex)
    if not index then return false end

    MySQL.query.await("UPDATE legal_activity_sellers SET `visible` = ? WHERE `activity` = ? AND `seller_index` = ?", {
        visible and 1 or 0, activity, index,
    })

    local row = MySQL.single.await("SELECT * FROM legal_activity_sellers WHERE `activity` = ? AND `seller_index` = ?", { activity, index })
    local posData = row and {
        x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0, w = row.w + 0.0,
        model = row.model, visible = visible and true or false,
    } or nil

    TriggerClientEvent("legalActivities:sellerVisibilityChanged", -1, activity, tostring(index), visible and true or false, posData)
    return true
end

function LegalActivities.DeleteSeller(activity, sellerIndex)
    if not isActivity(activity) then return false end
    local index = tonumber(sellerIndex)
    if not index then return false end

    MySQL.query.await("DELETE FROM legal_activity_sellers WHERE `activity` = ? AND `seller_index` = ?", { activity, index })
    TriggerClientEvent("legalActivities:sellerDeleted", -1, activity, tostring(index))
    return true
end

function LegalActivities.Log(identifier, activity, item, count, amount, paymentType)
    MySQL.insert("INSERT INTO legal_activity_logs (`identifier`, `activity`, `item`, `count`, `amount`, `payment_type`) VALUES (?, ?, ?, ?, ?, ?)", {
        identifier, activity, item, count, amount, paymentType or "cash",
    })
end

function LegalActivities.Pay(xPlayer, amount, paymentType, reason)
    local value = math.floor(tonumber(amount) or 0)
    if value <= 0 then return 0 end

    if paymentType == "bank" or paymentType == "banque" then
        xPlayer.addAccountMoney("bank", value, reason)
        return value
    end

    xPlayer.addAccountMoney("money", value, reason)
    return value
end

function LegalActivities.IsVip(xPlayer)
    if not xPlayer then return false end
    if (tonumber(xPlayer.vipTier) or 0) > 0 then return true end
    return xPlayer.hasPermission("vip_bronze") or xPlayer.hasPermission("vip_silver") or xPlayer.hasPermission("vip_gold")
end

CreateThread(function()
    while not VFW or not VFW.Ready do Wait(200) end
    local ok, err = pcall(LegalActivities.LoadSellers)
    if not ok then
        console.warn(("legal_activities: chargement des acheteurs impossible (%s)"):format(tostring(err)))
        return
    end
    console.init("legal_activities", "Acheteurs chargés")
end)
