Feat27 = Feat27 or {}

local function seedItems()
    local rows = MySQL.query.await("SELECT * FROM ltd_items ORDER BY `position` ASC, `item` ASC") or {}

    if #rows == 0 then
        local defaults = LTDItems and LTDItems.List or {}
        for i = 1, #defaults do
            local entry = defaults[i]
            MySQL.query.await(
                "INSERT IGNORE INTO ltd_items (`item`, `label`, `normal_price`, `buy_price`, `sell_price`, `position`) VALUES (?, ?, ?, ?, ?, ?)",
                { entry.item, entry.label or entry.item, entry.normalPrice, entry.buyPrice, entry.sellPrice, i }
            )
        end
        rows = MySQL.query.await("SELECT * FROM ltd_items ORDER BY `position` ASC, `item` ASC") or {}
    end

    local list = {}
    for i = 1, #rows do
        local row = rows[i]
        list[i] = {
            item = row.item,
            label = row.label,
            normalPrice = row.normal_price,
            buyPrice = row.buy_price,
            sellPrice = row.sell_price,
        }
    end

    LTDItems = LTDItems or {}
    LTDItems.List = list
    return list
end

function Feat27.LtdItems()
    if not LTDItems or type(LTDItems.List) ~= "table" then
        return {}
    end
    return LTDItems.List
end

function Feat27.LtdItemEntry(itemName)
    local list = Feat27.LtdItems()
    for i = 1, #list do
        if list[i].item == itemName then return list[i] end
    end
    return nil
end

function Feat27.LtdSyncItems(target)
    TriggerClientEvent("vfw:ltd:items:sync", target or -1, Feat27.LtdItems())
end

function Feat27.LtdSaveItem(entry)
    if type(entry) ~= "table" or type(entry.item) ~= "string" then return false end
    MySQL.query.await([[
        INSERT INTO ltd_items (`item`, `label`, `normal_price`, `buy_price`, `sell_price`, `position`)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `normal_price` = VALUES(`normal_price`),
            `buy_price` = VALUES(`buy_price`), `sell_price` = VALUES(`sell_price`), `position` = VALUES(`position`)
    ]], {
        entry.item,
        tostring(entry.label or entry.item),
        tonumber(entry.normalPrice),
        tonumber(entry.buyPrice),
        tonumber(entry.sellPrice),
        tonumber(entry.position) or 0,
    })
    seedItems()
    Feat27.LtdSyncItems()
    return true
end

function Feat27.LtdDeleteItem(itemName)
    if type(itemName) ~= "string" then return false end
    MySQL.query.await("DELETE FROM ltd_items WHERE `item` = ?", { itemName })
    MySQL.query.await("DELETE FROM ltd_society_catalog WHERE `item` = ?", { itemName })
    seedItems()
    Feat27.LtdSyncItems()
    return true
end

AddEventHandler("vfw:playerLoaded", function(source)
    TriggerClientEvent("vfw:ltd:items:sync", source, Feat27.LtdItems())
end)

CreateThread(function()
    while not VFW or not VFW.Ready do Wait(200) end
    local ok, err = pcall(seedItems)
    if not ok then
        console.warn(("fl_ltd: seed des items impossible (%s)"):format(tostring(err)))
        return
    end
    console.init("fl_ltd", ("%d item(s) de catalogue chargé(s)"):format(#Feat27.LtdItems()))
end)
