Feat27 = Feat27 or {}

local function societyOverrides(society)
    local rows = MySQL.query.await("SELECT `item`, `price` FROM ltd_society_catalog WHERE `society` = ?", { society }) or {}
    local out = {}
    for i = 1, #rows do
        out[rows[i].item] = rows[i].price
    end
    return out
end

local function catalogPrice(itemName, overrides)
    if overrides and overrides[itemName] then
        return tonumber(overrides[itemName]) or 0
    end
    local entry = Feat27.LtdItemEntry(itemName)
    if entry and entry.sellPrice then
        return tonumber(entry.sellPrice) or 0
    end
    return 0
end

RegisterServerCallback("vfw:ltd:getCatalogPoints", function(source)
    local rows = MySQL.query.await("SELECT `society`, `x`, `y`, `z`, `h` FROM ltd_catalog_points") or {}
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            x = row.x + 0.0,
            y = row.y + 0.0,
            z = row.z + 0.0,
            h = (row.h or 0.0) + 0.0,
            society = row.society,
        }
    end
    return out
end)

RegisterServerCallback("vfw:ltd:getCatalogItems", function(source, jobName)
    if type(jobName) ~= "string" or jobName == "" then return nil end

    local job = VFW.Jobs and VFW.Jobs[jobName]
    if not job then return nil end

    local overrides = societyOverrides(jobName)
    local list = Feat27.LtdItems()
    local items = {}

    for i = 1, #list do
        local entry = list[i]
        local price = catalogPrice(entry.item, overrides)
        if price and price > 0 then
            items[#items + 1] = {
                item = entry.item,
                label = entry.label or entry.item,
                price = price,
            }
        end
    end

    return { label = job.label or jobName, items = items }
end)

RegisterServerCallback("vfw:ltd:purchaseCatalogItem", function(source, jobName, itemName)
    local src = source

    if type(jobName) ~= "string" or jobName == "" or type(itemName) ~= "string" or itemName == "" then
        return { success = false, message = "Cette demande n'a pas pu être traitée" }
    end

    if not Feat27.RateLimit(src, "ltd:catalogBuy", 600) then
        return { success = false, message = "Veuillez patienter un instant" }
    end

    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local entry = Feat27.LtdItemEntry(itemName)
    if not entry then return { success = false, message = "Article indisponible" } end

    local price = catalogPrice(itemName, societyOverrides(jobName))
    if not price or price <= 0 then
        return { success = false, message = "Article indisponible" }
    end

    if not Feat27.Inv.Exists(itemName) then
        return { success = false, message = "Article indisponible" }
    end

    if not Feat27.Inv.CanCarry(xPlayer, itemName, 1) then
        return { success = false, message = "Votre inventaire est plein, faites de la place." }
    end

    local paymentMethod = "cash"
    if xPlayer.getMoney() >= price then
        xPlayer.removeAccountMoney("money", price, "ltd-catalogue")
    else
        local bank = xPlayer.getAccount("bank")
        if not bank or bank.money < price then
            return { success = false, message = "Vous n'avez pas assez d'argent" }
        end
        xPlayer.removeAccountMoney("bank", price, "ltd-catalogue")
        paymentMethod = "bank"
    end

    Feat27.Inv.Give(xPlayer, itemName, 1, nil, true)
    Feat27.Society.AddMoney(jobName, price, "ltd-catalogue")

    return { success = true, message = "Achat effectué", paymentMethod = paymentMethod }
end)

function Feat27.LtdSetCatalogPrice(society, itemName, price)
    if type(society) ~= "string" or type(itemName) ~= "string" then return false end
    local value = math.floor(tonumber(price) or 0)
    if value <= 0 then
        MySQL.query.await("DELETE FROM ltd_society_catalog WHERE `society` = ? AND `item` = ?", { society, itemName })
    else
        MySQL.query.await(
            "INSERT INTO ltd_society_catalog (`society`, `item`, `price`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `price` = VALUES(`price`)",
            { society, itemName, value }
        )
    end
    TriggerClientEvent("vfw:ltd:catalogUpdated", -1)
    return true
end

function Feat27.LtdAddCatalogPoint(society, coords, heading)
    if type(society) ~= "string" then return false end
    local pos = Feat27.Vec3(coords)
    if not pos then return false end
    MySQL.insert.await(
        "INSERT INTO ltd_catalog_points (`society`, `x`, `y`, `z`, `h`) VALUES (?, ?, ?, ?, ?)",
        { society, pos.x, pos.y, pos.z, tonumber(heading) or 0.0 }
    )
    TriggerClientEvent("vfw:ltd:catalogUpdated", -1)
    return true
end

function Feat27.LtdRemoveCatalogPoint(pointId)
    local id = tonumber(pointId)
    if not id then return false end
    MySQL.query.await("DELETE FROM ltd_catalog_points WHERE `id` = ?", { id })
    TriggerClientEvent("vfw:ltd:catalogUpdated", -1)
    return true
end
