Feat27 = Feat27 or {}

local function sellerCatalog(activityName)
    local sellers = Config and Config.legalActivitiesSellers or {}
    local entry = sellers[activityName]
    if not entry or type(entry.itemsToSell) ~= "table" then return nil end
    return entry.itemsToSell
end

local function buildShopData(xPlayer, activityName)
    local catalog = sellerCatalog(activityName)
    if not catalog then return nil end

    local items = {}
    for i = 1, #catalog do
        local entry = catalog[i]
        items[#items + 1] = {
            name = entry.name,
            label = Feat27.Inv.Label(entry.name),
            count = Feat27.Inv.Count(xPlayer, entry.name),
            price = tonumber(entry.price) or 0,
            category = entry.category or activityName,
            image = Feat27.Inv.Image(entry.name),
        }
    end

    return {
        type = activityName,
        title = "Revente",
        activity = activityName,
        items = items,
    }
end

RegisterNetEvent("core:legal_activities:server:openSeller", function(activityName)
    local source = source
    if type(activityName) ~= "string" then return end
    if not Feat27.RateLimit(source, "legal:openSeller", 500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local shopData = buildShopData(xPlayer, activityName)
    if not shopData then
        Feat27.NotifyError(source, "Ce revendeur n'est pas disponible.")
        return
    end

    TriggerClientEvent("core:legal_activities:client:openShop", source, shopData)
end)

RegisterServerCallback("core:legal_activities:server:sellItems", function(source, items)
    if type(items) ~= "table" then
        return { success = false, message = "Aucun article sélectionné." }
    end
    if not Feat27.RateLimit(source, "legal:sellItems", 600) then
        return { success = false, message = "Veuillez patienter." }
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable." }
    end

    local prices = {}
    local sellers = Config and Config.legalActivitiesSellers or {}
    for activity, entry in pairs(sellers) do
        if type(entry.itemsToSell) == "table" then
            for i = 1, #entry.itemsToSell do
                local item = entry.itemsToSell[i]
                prices[item.name] = { price = tonumber(item.price) or 0, activity = activity }
            end
        end
    end

    local total = 0
    local soldCount = 0

    for _, request in pairs(items) do
        if type(request) == "table" and type(request.name) == "string" then
            local wanted = math.floor(tonumber(request.count or request.quantity or request.amount) or 0)
            local definition = prices[request.name]

            if definition and definition.price > 0 and wanted > 0 then
                local owned = Feat27.Inv.Count(xPlayer, request.name)
                if wanted > owned then wanted = owned end

                if wanted > 0 and Feat27.Inv.Take(xPlayer, request.name, wanted, false) then
                    local amount = definition.price * wanted
                    total = total + amount
                    soldCount = soldCount + wanted
                    LegalActivities.Log(xPlayer.identifier, definition.activity, request.name, wanted, amount, "cash")
                end
            end
        end
    end

    if total <= 0 then
        return { success = false, message = "Rien à vendre." }
    end

    LegalActivities.Pay(xPlayer, total, "cash", "revente-activite-legale")

    return {
        success = true,
        message = ("Vous avez vendu %d article%s pour %d$."):format(soldCount, soldCount > 1 and "s" or "", total),
        total = total,
        count = soldCount,
    }
end)
