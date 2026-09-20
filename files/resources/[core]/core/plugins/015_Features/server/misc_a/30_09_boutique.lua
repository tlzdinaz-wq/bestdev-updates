local function paidshopCatalog(category)
    if not PaidShop or not PaidShop.LoadItems then return nil end

    local ok, items = pcall(PaidShop.LoadItems)
    if not ok or type(items) ~= "table" then return nil end

    local list = items[category]
    if type(list) ~= "table" or #list == 0 then return nil end

    local out = {}
    for i = 1, #list do
        local entry = list[i]
        out[#out + 1] = {
            name = entry.spawnName,
            model = entry.spawnName,
            spawnName = entry.spawnName,
            label = entry.name ~= "" and entry.name or entry.spawnName,
            price = math.floor(tonumber(entry.price) or 0),
            originalPrice = entry.originalPrice,
            image = entry.image,
            description = entry.description,
            rarity = entry.rarity,
            type = category,
            category = entry.category or category,
        }
    end

    return out
end

local function boutiqueCatalog(category)
    local rows = Misc30.Query([[
        SELECT `model`, `label`, `price`, `type`, `category` FROM `boutique_vehicles`
        WHERE `type` = ? ORDER BY `price` ASC
    ]], { category })

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            name = row.model,
            model = row.model,
            spawnName = row.model,
            label = row.label ~= "" and row.label or row.model,
            price = math.floor(tonumber(row.price) or 0),
            type = row.type or category,
            category = row.category or category,
        }
    end

    return out
end

Misc30.Cb("boutique:getVehiclesByType", function(source, kind)
    if not VFW.GetPlayerFromId(source) then return {} end

    local category = Misc30.Clean(kind, 32, "vehicules")

    local out = paidshopCatalog(category)
    if out and #out > 0 then return out end

    out = boutiqueCatalog(category)
    if #out > 0 then return out end

    if category == "nautique" then
        out = paidshopCatalog("nautic") or boutiqueCatalog("nautic")
    elseif category == "nautic" then
        out = paidshopCatalog("nautique") or boutiqueCatalog("nautique")
    end

    return out or {}
end)

Misc30.Cb("vfw:getPlayerCount", function()
    if VFW.GetPlayerCount then
        local ok, count = pcall(VFW.GetPlayerCount)
        if ok and type(count) == "number" then return count end
    end
    return #GetPlayers()
end)

local function openBoutique(source, xPlayer)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "openBoutique", 1500) then return end
    xPlayer.triggerEvent("vfw:openEscapeMenuBoutique")
end

VFW.RegisterCommand("boutique", nil, function(source, xPlayer)
    openBoutique(source, xPlayer)
end, { help = "Ouvrir la boutique du serveur" })

VFW.RegisterCommand("shop", nil, function(source, xPlayer)
    openBoutique(source, xPlayer)
end, { help = "Ouvrir la boutique du serveur" })

local lastBroadcastCount = -1

CreateThread(function()
    while true do
        Wait(5000)

        local count
        if VFW.GetPlayerCount then
            local ok, value = pcall(VFW.GetPlayerCount)
            if ok and type(value) == "number" then count = value end
        end
        if not count then count = #GetPlayers() end

        if count ~= lastBroadcastCount then
            lastBroadcastCount = count
            TriggerClientEvent("vfw:updatePlayerCount", -1, count)
        end
    end
end)
