---@meta _
---@diagnostic disable: duplicate-doc-field

local FIELD_MARKET = "spacemarket"
local FIELD_SETTINGS = "spacemarket_settings"
local FIELD_LOCATIONS = "spacemarket_locations"
local FIELD_PED_MODEL = "spacemarket_ped_model"

local function player(source)
    return VFW and VFW.GetPlayerFromId and VFW.GetPlayerFromId(source) or nil
end

local function hasBuilderPermission(source)
    local xPlayer = player(source)
    return xPlayer ~= nil and (xPlayer.hasPermission("builder_spacemarket") or xPlayer.hasPermission("staff_menu"))
end

local function encode(data)
    return json.encode(data or {})
end

local function decode(raw, fallback)
    if type(raw) ~= "string" or raw == "" then return fallback end
    local ok, out = pcall(json.decode, raw)
    if ok and type(out) == "table" then return out end
    return fallback
end

local function getAddonTable(society, field, fallback)
    if Feat27 and Feat27.Society and Feat27.Society.GetAddonTable then
        return Feat27.Society.GetAddonTable(society, field, fallback)
    end

    local rows = MySQL.query.await("SELECT `value` FROM society_addon_fields WHERE `society` = ? AND `field` = ? LIMIT 1", { society, field }) or {}
    return rows[1] and decode(rows[1].value, fallback) or fallback
end

local function setAddon(society, field, value)
    if Feat27 and Feat27.Society and Feat27.Society.SetAddon then
        return Feat27.Society.SetAddon(society, field, value)
    end

    MySQL.query.await(
        "INSERT INTO society_addon_fields (`society`, `field`, `value`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)",
        { society, field, type(value) == "table" and encode(value) or tostring(value or "") }
    )
    return true
end

local function normalizeGrades(grades)
    local out = {}
    if type(grades) ~= "table" then return out end
    for _, grade in pairs(grades) do
        local value = tonumber(grade)
        if value then out[#out + 1] = value end
    end
    table.sort(out, function(a, b) return a < b end)
    return out
end

local function normalizeMarket(data)
    data = type(data) == "table" and data or {}
    data.enabled = data.enabled == true
    data.allowed_grades = normalizeGrades(data.allowed_grades or data.grades)
    data.grades = data.allowed_grades
    data.categories = type(data.categories) == "table" and data.categories or {}
    data.items = type(data.items) == "table" and data.items or {}
    data.nextCategoryId = tonumber(data.nextCategoryId) or 1
    data.nextItemId = tonumber(data.nextItemId) or 1

    for i = 1, #data.categories do
        local category = data.categories[i]
        if type(category) ~= "table" then
            data.categories[i] = { id = data.nextCategoryId, name = tostring(category) }
            data.nextCategoryId = data.nextCategoryId + 1
        else
            category.id = tonumber(category.id) or data.nextCategoryId
            category.name = tostring(category.name or category.label or ("Catégorie " .. category.id))
            if category.id >= data.nextCategoryId then data.nextCategoryId = category.id + 1 end
        end
    end

    for i = 1, #data.items do
        local item = data.items[i]
        if type(item) == "table" then
            item.id = tonumber(item.id) or data.nextItemId
            if item.id >= data.nextItemId then data.nextItemId = item.id + 1 end
            item.item = tostring(item.item or item.name or "")
            item.name = item.item
            item.label = tostring(item.label or (VFW.Items[item.item] and VFW.Items[item.item].label) or item.item)
            item.price = math.max(math.floor(tonumber(item.price) or 0), 0)
            item.category = tostring(item.category or "")
            item.type = tostring(item.type or "item")
        end
    end

    return data
end

local function getMarket(society)
    if type(society) ~= "string" or society == "" then return nil end
    local raw = getAddonTable(society, FIELD_MARKET, nil)
    if raw == nil then return nil end
    return normalizeMarket(raw)
end

local function saveMarket(society, data)
    return setAddon(society, FIELD_MARKET, normalizeMarket(data))
end

local function jobLabel(name)
    local job = VFW and VFW.Jobs and VFW.Jobs[name]
    return job and job.label or name
end

local function listMarketJobs()
    local rows = MySQL.query.await("SELECT `society`, `value` FROM society_addon_fields WHERE `field` = ?", { FIELD_MARKET }) or {}
    local out = {}
    for i = 1, #rows do
        local name = rows[i].society
        local market = normalizeMarket(decode(rows[i].value, {}))
        out[name] = {
            name = name,
            label = jobLabel(name),
            enabled = market.enabled == true,
            allowed_grades = market.allowed_grades or {},
            categories = market.categories or {},
            items = market.items or {},
        }
    end
    return out
end

local function notify(source, variant, message)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification(source, {
            type = variant == "SUCCESS" and "VERT" or (variant == "INFO" and "BLEU" or "ROUGE"),
            content = "Market : " .. tostring(message or ""),
        })
    end
end

RegisterServerCallback("spacemarket:get:jobs", function(source)
    if not hasBuilderPermission(source) then return {} end
    return listMarketJobs()
end)

RegisterServerCallback("spacemarket:get:job", function(source, society)
    if not hasBuilderPermission(source) then return {} end
    local market = getMarket(society)
    if not market then return {} end
    return market
end)

RegisterServerCallback("core:get:societyData", function(source, society)
    if not hasBuilderPermission(source) then return {} end
    if type(society) ~= "string" or society == "" then return {} end
    return {
        name = society,
        label = jobLabel(society),
        custom = { spacemarket = getMarket(society) or normalizeMarket({}) },
    }
end)

RegisterNetEvent("spacemarket:create:job", function(society, data)
    local source = source
    if not hasBuilderPermission(source) then return end
    if type(society) ~= "string" or society == "" or not VFW.Jobs[society] then
        notify(source, "ERROR", "Job introuvable.")
        return
    end
    if getMarket(society) then
        notify(source, "ERROR", "Ce job est déjà assigné au Market.")
        return
    end

    saveMarket(society, {
        enabled = data and data.enabled ~= false,
        allowed_grades = normalizeGrades(data and data.allowed_grades or {}),
        categories = {},
        items = {},
    })
    notify(source, "SUCCESS", "Job ajouté au Market.")
end)

RegisterNetEvent("spacemarket:update:job", function(society, data)
    local source = source
    if not hasBuilderPermission(source) then return end
    local market = getMarket(society)
    if not market then
        notify(source, "ERROR", "Job Market introuvable.")
        return
    end

    if type(data) == "table" then
        if data.enabled ~= nil then market.enabled = data.enabled == true end
        if data.allowed_grades or data.grades then market.allowed_grades = normalizeGrades(data.allowed_grades or data.grades) end
    end
    saveMarket(society, market)
    notify(source, "SUCCESS", "Market enregistré.")
end)

RegisterServerCallback("spacemarket:delete:job", function(source, society)
    if not hasBuilderPermission(source) then return false end
    if type(society) ~= "string" or society == "" then return false end
    MySQL.query.await("DELETE FROM society_addon_fields WHERE `society` = ? AND `field` = ?", { society, FIELD_MARKET })
    if Feat27 and Feat27.Society and Feat27.Society.LoadAddons then Feat27.Society.LoadAddons() end
    notify(source, "SUCCESS", "Job retiré du Market.")
    return true
end)

RegisterNetEvent("spacemarket:add:category", function(society, name)
    local source = source
    if not hasBuilderPermission(source) then return end
    local market = getMarket(society)
    name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if not market or name == "" then return notify(source, "ERROR", "Catégorie invalide.") end

    market.categories[#market.categories + 1] = { id = market.nextCategoryId, name = name }
    market.nextCategoryId = market.nextCategoryId + 1
    saveMarket(society, market)
    notify(source, "SUCCESS", "Catégorie ajoutée.")
end)

RegisterNetEvent("spacemarket:update:category", function(society, categoryId, name)
    local source = source
    if not hasBuilderPermission(source) then return end
    local market = getMarket(society)
    name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if not market or name == "" then return notify(source, "ERROR", "Catégorie invalide.") end

    local wanted = tonumber(categoryId)
    for i = 1, #market.categories do
        local category = market.categories[i]
        if (wanted and tonumber(category.id) == wanted) or category.name == categoryId then
            local oldName = category.name
            category.name = name
            for j = 1, #market.items do
                if market.items[j].category == oldName then market.items[j].category = name end
            end
            saveMarket(society, market)
            notify(source, "SUCCESS", "Catégorie modifiée.")
            return
        end
    end
    notify(source, "ERROR", "Catégorie introuvable.")
end)

RegisterServerCallback("spacemarket:delete:category", function(source, society, categoryId)
    if not hasBuilderPermission(source) then return false end
    local market = getMarket(society)
    if not market then return false end
    local wanted = tonumber(categoryId)

    for i = #market.categories, 1, -1 do
        local category = market.categories[i]
        if (wanted and tonumber(category.id) == wanted) or category.name == categoryId then
            local oldName = category.name
            table.remove(market.categories, i)
            for j = 1, #market.items do
                if market.items[j].category == oldName then market.items[j].category = "" end
            end
            saveMarket(society, market)
            notify(source, "SUCCESS", "Catégorie supprimée.")
            return true
        end
    end
    return false
end)

RegisterNetEvent("spacemarket:add:item", function(society, itemData)
    local source = source
    if not hasBuilderPermission(source) then return end
    local market = getMarket(society)
    if not market or type(itemData) ~= "table" then return notify(source, "ERROR", "Item invalide.") end

    local itemName = tostring(itemData.item or itemData.name or "")
    if itemName == "" or not VFW.Items[itemName] then return notify(source, "ERROR", "Item introuvable.") end
    local price = math.max(math.floor(tonumber(itemData.price) or 0), 0)
    if price <= 0 then return notify(source, "ERROR", "Prix invalide.") end

    market.items[#market.items + 1] = {
        id = market.nextItemId,
        item = itemName,
        name = itemName,
        label = tostring(itemData.label or VFW.Items[itemName].label or itemName),
        price = price,
        category = tostring(itemData.category or ""),
        type = tostring(itemData.type or "item"),
    }
    market.nextItemId = market.nextItemId + 1
    saveMarket(society, market)
    notify(source, "SUCCESS", "Item ajouté.")
end)

RegisterNetEvent("spacemarket:update:item", function(itemId, itemData)
    local source = source
    if not hasBuilderPermission(source) then return end
    itemId = tonumber(itemId)
    if not itemId or type(itemData) ~= "table" then return notify(source, "ERROR", "Item invalide.") end

    for society, _ in pairs(listMarketJobs()) do
        local market = getMarket(society)
        for i = 1, #(market.items or {}) do
            if tonumber(market.items[i].id) == itemId then
                local itemName = tostring(itemData.item or itemData.name or market.items[i].item or "")
                if itemName == "" or not VFW.Items[itemName] then return notify(source, "ERROR", "Item introuvable.") end
                market.items[i].item = itemName
                market.items[i].name = itemName
                market.items[i].label = tostring(itemData.label or VFW.Items[itemName].label or itemName)
                market.items[i].price = math.max(math.floor(tonumber(itemData.price) or 0), 0)
                market.items[i].category = tostring(itemData.category or "")
                market.items[i].type = tostring(itemData.type or "item")
                saveMarket(society, market)
                notify(source, "SUCCESS", "Item modifié.")
                return
            end
        end
    end
    notify(source, "ERROR", "Item introuvable.")
end)

RegisterNetEvent("spacemarket:delete:item", function(itemId)
    local source = source
    if not hasBuilderPermission(source) then return end
    itemId = tonumber(itemId)
    if not itemId then return end

    for society, _ in pairs(listMarketJobs()) do
        local market = getMarket(society)
        for i = #(market.items or {}), 1, -1 do
            if tonumber(market.items[i].id) == itemId then
                table.remove(market.items, i)
                saveMarket(society, market)
                notify(source, "SUCCESS", "Item supprimé.")
                return
            end
        end
    end
end)

local function defaultSettings()
    return { min = 60, max = 300, enabled = true }
end

local function packCoords(coords)
    if type(coords) ~= "vector4" and type(coords) ~= "vector3" and type(coords) ~= "table" then
        return { x = 0.0, y = 0.0, z = 0.0, w = 0.0 }
    end
    return {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
        w = tonumber(coords.w or coords.h or coords.heading) or 0.0,
    }
end

local function normalizeLocations(locations)
    local out = {}
    if type(locations) ~= "table" then return out end
    for i = 1, #locations do
        local loc = locations[i]
        if type(loc) == "table" then
            out[#out + 1] = {
                name = tostring(loc.name or ("Space Market " .. tostring(i))),
                pedCoords = packCoords(loc.pedCoords),
                dropCoords = packCoords(loc.dropCoords),
            }
        end
    end
    return out
end

local function getSettings()
    local settings = getAddonTable("_global", FIELD_SETTINGS, defaultSettings())
    settings.min = math.max(math.floor(tonumber(settings.min) or 60), 1)
    settings.max = math.max(math.floor(tonumber(settings.max) or 300), settings.min + 1)
    settings.enabled = settings.enabled ~= false
    return settings
end

local function defaultLocations()
    return normalizeLocations(Config and Config.Locations or {})
end

local function getLocations()
    return normalizeLocations(getAddonTable("_global", FIELD_LOCATIONS, defaultLocations()))
end

local function getPedModel()
    local raw = Feat27 and Feat27.Society and Feat27.Society.GetAddonString and Feat27.Society.GetAddonString("_global", FIELD_PED_MODEL, nil)
    return raw or (Config and Config.PedModel) or "a_m_y_business_02"
end

local function syncSpaceMarket(target)
    TriggerClientEvent("spacemarket:setGlobalEnabled", target or -1, getSettings().enabled)
    TriggerClientEvent("spacemarket:syncLocations", target or -1, getLocations(), getPedModel())
end

RegisterServerCallback("spacemarket:get:delivery_settings", function(source)
    if not hasBuilderPermission(source) then return defaultSettings() end
    return getSettings()
end)

RegisterServerCallback("spacemarket:get:locations", function(source)
    if not hasBuilderPermission(source) then return { locations = defaultLocations(), pedModel = getPedModel() } end
    return { locations = getLocations(), pedModel = getPedModel() }
end)

RegisterNetEvent("spacemarket:set:delivery_settings", function(minTime, maxTime, enabled)
    local source = source
    if not hasBuilderPermission(source) then return end
    local settings = {
        min = math.max(math.floor(tonumber(minTime) or 60), 1),
        max = math.max(math.floor(tonumber(maxTime) or 300), 2),
        enabled = enabled ~= false,
    }
    if settings.max <= settings.min then settings.max = settings.min + 1 end
    setAddon("_global", FIELD_SETTINGS, settings)
    syncSpaceMarket(-1)
    notify(source, "SUCCESS", "Configuration Market enregistrée.")
end)

RegisterNetEvent("spacemarket:setPedModel", function(model)
    local source = source
    if not hasBuilderPermission(source) then return end
    model = type(model) == "string" and model:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if model == "" then return notify(source, "ERROR", "Modèle invalide.") end
    setAddon("_global", FIELD_PED_MODEL, model)
    syncSpaceMarket(-1)
    notify(source, "SUCCESS", "PNJ Market modifié.")
end)

RegisterNetEvent("spacemarket:updateLocation", function(index, pedCoords, dropCoords)
    local source = source
    if not hasBuilderPermission(source) then return end
    index = tonumber(index)
    local locations = getLocations()
    if not index or not locations[index] then return notify(source, "ERROR", "Position Market introuvable.") end

    if type(pedCoords) == "table" then
        locations[index].pedCoords = packCoords(pedCoords)
    end
    if type(dropCoords) == "table" then
        locations[index].dropCoords = packCoords(dropCoords)
    end

    setAddon("_global", FIELD_LOCATIONS, locations)
    syncSpaceMarket(-1)
    notify(source, "SUCCESS", "Position Market enregistrée.")
end)

RegisterNetEvent("spacemarket:requestGlobalEnabled", function()
    syncSpaceMarket(source)
end)

RegisterNetEvent("spacemarket:requestLocations", function()
    syncSpaceMarket(source)
end)

RegisterNetEvent("core:checkAuthorization", function()
    local source = source
    local xPlayer = player(source)
    if not xPlayer or not xPlayer.job or not xPlayer.job.name then
        TriggerClientEvent("core:authorizationResult", source, false, "Job introuvable.")
        return
    end

    local market = getMarket(xPlayer.job.name)
    if not market or market.enabled ~= true then
        TriggerClientEvent("core:authorizationResult", source, false, "Votre entreprise n'a pas accès au Market.")
        return
    end

    local allowed = market.allowed_grades or {}
    if #allowed > 0 then
        local grade = tonumber(xPlayer.job.grade)
        local ok = false
        for i = 1, #allowed do
            if tonumber(allowed[i]) == grade then ok = true break end
        end
        if not ok then
            TriggerClientEvent("core:authorizationResult", source, false, "Grade non autorisé.")
            return
        end
    end

    TriggerClientEvent("core:authorizationResult", source, true, nil)
end)

RegisterNetEvent("core:getPlayerMoneyData", function()
    local source = source
    local xPlayer = player(source)
    if not xPlayer then return end
    local societyMoney = 0
    if xPlayer.job and xPlayer.job.name and Feat27 and Feat27.Society and Feat27.Society.GetAddonNumber then
        societyMoney = Feat27.Society.GetAddonNumber(xPlayer.job.name, "money", 0) or 0
    end
    TriggerClientEvent("core:moneyDataResponse", source, xPlayer.getMoney and xPlayer.getMoney() or 0, societyMoney)
end)

RegisterNetEvent("core:requestShopData", function()
    local source = source
    local xPlayer = player(source)
    if not xPlayer or not xPlayer.job then return end
    local market = getMarket(xPlayer.job.name)
    if not market or market.enabled ~= true then
        TriggerClientEvent("core:sendShopData", source, nil, "Votre entreprise n'a pas accès au Market.")
        return
    end
    TriggerClientEvent("core:sendShopData", source, {
        name = Config and Config.Shop and Config.Shop.name or "Space Market",
        phone = Config and Config.Shop and Config.Shop.phone or "555-MARKET",
        logo = Config and Config.Shop and Config.Shop.logo or "",
        categories = market.categories or {},
        items = market.items or {},
    })
end)

RegisterNetEvent("core:buyItems:net", function(cart, _total, requestId, paymentType)
    local source = source
    local xPlayer = player(source)
    local function reply(ok, err, deliveryTime)
        TriggerClientEvent("core:buyItems:response", source, requestId, ok, err, deliveryTime)
    end
    if not xPlayer or not xPlayer.job then return reply(false, "Joueur introuvable.") end
    local market = getMarket(xPlayer.job.name)
    if not market or market.enabled ~= true then return reply(false, "Market indisponible.") end
    if type(cart) ~= "table" or #cart == 0 then return reply(false, "Panier vide.") end

    local catalog = {}
    for i = 1, #(market.items or {}) do
        local item = market.items[i]
        catalog[item.item or item.name] = item
    end

    local lines, total = {}, 0
    for i = 1, #cart do
        local entry = cart[i]
        local itemName = type(entry) == "table" and tostring(entry.item or entry.name or entry.id or "") or ""
        local quantity = math.max(math.floor(tonumber(entry.quantity or entry.count or entry.qty) or 0), 0)
        local def = catalog[itemName]
        if itemName == "" or quantity <= 0 or not def then return reply(false, "Article indisponible.") end
        if not xPlayer.canCarryItem(itemName, quantity) then return reply(false, "Inventaire plein.") end
        total = total + ((tonumber(def.price) or 0) * quantity)
        lines[#lines + 1] = { name = itemName, quantity = quantity }
    end
    if total <= 0 then return reply(false, "Montant invalide.") end

    if paymentType == "society" or paymentType == "bank" then
        if xPlayer.getAccount and xPlayer.getAccount("bank") and xPlayer.getAccount("bank").money >= total then
            xPlayer.removeAccountMoney("bank", total, "spacemarket")
        else
            return reply(false, "Fonds bancaires insuffisants.")
        end
    else
        if not xPlayer.getMoney or xPlayer.getMoney() < total then return reply(false, "Fonds insuffisants.") end
        xPlayer.removeAccountMoney("money", total, "spacemarket")
    end

    for i = 1, #lines do
        xPlayer.addInventoryItem(lines[i].name, lines[i].quantity, nil, true)
    end

    reply(true, nil, 0)
end)
