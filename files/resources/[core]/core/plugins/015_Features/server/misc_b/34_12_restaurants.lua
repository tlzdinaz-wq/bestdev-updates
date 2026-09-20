local BRANDS = {
    bean_coffee = "BeanCoffeeConfig",
    burgershot  = "BurgerShotConfig",
    noodle      = "NoodleConfig",
    pearls      = "PearlsConfig",
    pizzeria    = "PizzeriaConfig",
    uwu_cafe    = "UwuCafeConfig",
}

local CRAFT_KINDS = { "crafting", "granita", "milkshake" }

local slotClaims = {}
local machineLevels = {}
local deliveries = {}
local bags = {}

local DELIVERY_POINTS = {
    { x = 128.6, y = -1298.5, z = 29.2, name = "Client Vespucci" },
    { x = -47.9, y = -1108.7, z = 26.4, name = "Client Innocence" },
    { x = 288.4, y = -1049.4, z = 29.3, name = "Client Alta" },
    { x = -262.9, y = -968.6, z = 31.2, name = "Client Legion" },
    { x = -628.2, y = -235.1, z = 38.0, name = "Client Rockford" },
    { x = -1290.4, y = -571.9, z = 30.2, name = "Client Del Perro" },
    { x = -1487.2, y = -885.2, z = 10.1, name = "Client Vespucci Beach" },
    { x = 894.6, y = -1799.9, z = 29.6, name = "Client Cypress" },
    { x = 1141.7, y = -981.2, z = 46.0, name = "Client Mirror Park" },
    { x = 78.5, y = 108.5, z = 79.2, name = "Client Vinewood" },
    { x = -710.1, y = 261.4, z = 83.1, name = "Client Hills" },
    { x = 340.2, y = -223.9, z = 54.1, name = "Client Downtown" },
}

local function cfgOf(brand)
    local name = BRANDS[brand]
    if not name then return nil end
    local cfg = _G[name]
    if type(cfg) ~= "table" then return nil end
    return cfg
end

local function locationOf(cfg, jobName)
    if not cfg or type(cfg.Locations) ~= "table" then return nil end
    return cfg.Locations[jobName]
end

local function onDutyFor(xPlayer, jobName)
    if not xPlayer then return false end
    if MiscB.JobName(xPlayer) ~= jobName then return false end
    return MiscB.OnDuty(xPlayer)
end

local function recipesOf(cfg, kind)
    if not cfg or type(cfg.Recipes) ~= "table" then return nil end
    local list = cfg.Recipes[kind]
    if type(list) ~= "table" then return nil end
    return list
end

local function findRecipe(list, recipeId)
    for i = 1, #list do
        if tostring(list[i].id) == tostring(recipeId) then return list[i] end
    end
    return nil
end

local function claimKey(brand, jobName, kind, slotName)
    return ("%s|%s|%s|%s"):format(brand, tostring(jobName), tostring(kind), tostring(slotName))
end

local function claimSlot(source, brand, jobName, kind, slotName)
    local key = claimKey(brand, jobName, kind, slotName)
    local holder = slotClaims[key]
    if holder and holder ~= source and VFW.GetPlayerFromId(holder) then
        return false, "Ce poste est occupe."
    end
    slotClaims[key] = source
    return true, nil
end

local function releaseSlot(source, brand, jobName, kind, slotName)
    local key = claimKey(brand, jobName, kind, slotName)
    if slotClaims[key] == source then slotClaims[key] = nil end
    return true
end

local function hasIngredients(xPlayer, recipe)
    local missing = {}
    if type(recipe.ingredients) ~= "table" then return true, missing end

    for i = 1, #recipe.ingredients do
        local ing = recipe.ingredients[i]
        local item = xPlayer.getInventoryItem(ing.name)
        local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
        if count < (tonumber(ing.amount) or 1) then
            missing[#missing + 1] = { name = ing.name, label = ing.label or ing.name, have = count, need = ing.amount or 1 }
        end
    end

    return #missing == 0, missing
end

local function buildCraftSlots(cfg, jobName, kind, xPlayer)
    local list = recipesOf(cfg, kind)
    if not list then return {} end

    local out = {}
    for i = 1, #list do
        local recipe = list[i]
        local ok = hasIngredients(xPlayer, recipe)
        local ingredients = {}
        if type(recipe.ingredients) == "table" then
            for j = 1, #recipe.ingredients do
                local ing = recipe.ingredients[j]
                local item = xPlayer.getInventoryItem(ing.name)
                local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
                ingredients[#ingredients + 1] = {
                    name = ing.name,
                    label = ing.label or ing.name,
                    amount = ing.amount or 1,
                    have = count,
                }
            end
        end

        out[#out + 1] = {
            id = recipe.id,
            itemId = recipe.id,
            label = recipe.label,
            output = recipe.output,
            outputQuantity = recipe.outputQuantity or 1,
            craftTime = recipe.craftTime or 5,
            ingredients = ingredients,
            canCraft = ok,
        }
    end
    return out
end

local function machineKey(brand, jobName)
    return ("%s|%s"):format(brand, tostring(jobName))
end

local function machineData(cfg, brand, jobName)
    local key = machineKey(brand, jobName)
    machineLevels[key] = machineLevels[key] or {}
    local levels = machineLevels[key]

    local machine = type(cfg.Machine) == "table" and cfg.Machine or {}
    local drinks = type(machine.drinks) == "table" and machine.drinks or {}

    local out = {}
    for drinkKey, drink in pairs(drinks) do
        if levels[drinkKey] == nil then levels[drinkKey] = 100 end
        local sizes = {}
        if type(drink.sizes) == "table" then
            for sizeKey, itemName in pairs(drink.sizes) do
                sizes[#sizes + 1] = { key = sizeKey, item = itemName }
            end
        end
        out[#out + 1] = {
            key = drinkKey,
            drinkKey = drinkKey,
            label = drink.label or drinkKey,
            barrel = drink.barrel,
            level = levels[drinkKey],
            max = 100,
            minReplaceThreshold = machine.minReplaceThreshold or 20,
            sizes = sizes,
        }
    end

    table.sort(out, function(a, b) return tostring(a.key) < tostring(b.key) end)
    return { drinks = out, jobName = jobName }
end

local function deliveryPick(exclude)
    local point = DELIVERY_POINTS[math.random(#DELIVERY_POINTS)]
    local tries = 0
    while exclude and point == exclude and tries < 8 do
        point = DELIVERY_POINTS[math.random(#DELIVERY_POINTS)]
        tries = tries + 1
    end
    return point
end

local function deliveryOrder(cfg)
    local allowed = type(cfg.DeliveryAllowedItems) == "table" and cfg.DeliveryAllowedItems or {}
    if #allowed == 0 then return nil end

    local count = math.random(1, math.min(3, #allowed))
    local picked = {}
    local used = {}

    for _ = 1, count do
        local index = math.random(#allowed)
        local tries = 0
        while used[index] and tries < 10 do
            index = math.random(#allowed)
            tries = tries + 1
        end
        used[index] = true

        local name = allowed[index]
        local def = VFW.Items and VFW.Items[name] or nil
        picked[#picked + 1] = {
            name = name,
            label = (type(def) == "table" and def.label) or name,
            count = math.random(1, 3),
        }
    end

    return picked
end

local function orderReward(items)
    local reward = 0
    for i = 1, #items do
        reward = reward + (items[i].count * math.random(45, 85))
    end
    return reward
end

local function newDeliveryStep(cfg, current)
    local point = deliveryPick(current and current.point or nil)
    local items = deliveryOrder(cfg)
    if not items then return nil end

    return {
        point = point,
        clientData = { x = point.x, y = point.y, z = point.z },
        npcName = point.name,
        orderItems = items,
        reward = orderReward(items),
        model = cfg.DeliveryDefaultModel,
    }
end

local function registerBrand(brand)
    local prefix = brand .. ":"

    for _, kind in ipairs(CRAFT_KINDS) do
        MiscB.Cb(prefix .. kind .. ":getData", function(source, jobName)
            local xPlayer = VFW.GetPlayerFromId(source)
            local cfg = cfgOf(brand)
            if not xPlayer or not cfg then return nil end
            if not onDutyFor(xPlayer, jobName) then return nil end
            if not recipesOf(cfg, kind) then return nil end
            return buildCraftSlots(cfg, jobName, kind, xPlayer)
        end)

        MiscB.Cb(prefix .. kind .. ":claimSlot", function(source, jobName, slotName)
            local xPlayer = VFW.GetPlayerFromId(source)
            if not xPlayer then return false, "Joueur introuvable." end
            if not onDutyFor(xPlayer, jobName) then return false, "Vous devez etre en service." end
            if type(slotName) ~= "string" or #slotName > 32 then return false, "Ce poste n'est pas valide." end
            return claimSlot(source, brand, jobName, kind, slotName)
        end)

        MiscB.Cb(prefix .. kind .. ":releaseSlot", function(source, jobName, slotName)
            if type(slotName) ~= "string" then return false end
            return releaseSlot(source, brand, jobName, kind, slotName)
        end)

        MiscB.Cb(prefix .. kind .. ":craftOne", function(source, jobName, recipeId)
            local xPlayer = VFW.GetPlayerFromId(source)
            local cfg = cfgOf(brand)
            if not xPlayer or not cfg then return false, "Action impossible pour le moment." end
            if not onDutyFor(xPlayer, jobName) then return false, "Vous devez etre en service." end

            local list = recipesOf(cfg, kind)
            if not list then return false, "Recette introuvable." end

            local recipe = findRecipe(list, recipeId)
            if not recipe then return false, "Recette introuvable." end

            local ok, missing = hasIngredients(xPlayer, recipe)
            if not ok then
                local parts = {}
                for i = 1, #missing do
                    parts[#parts + 1] = ("%s (%d/%d)"):format(missing[i].label, missing[i].have, missing[i].need)
                end
                return false, "Il vous manque : " .. table.concat(parts, ", ")
            end

            if type(recipe.ingredients) == "table" then
                for i = 1, #recipe.ingredients do
                    local ing = recipe.ingredients[i]
                    xPlayer.removeInventoryItem(ing.name, tonumber(ing.amount) or 1)
                end
            end

            return true, nil, recipe.craftTime or 5
        end)

        MiscB.Cb(prefix .. kind .. ":completeOne", function(source, jobName, recipeId)
            local xPlayer = VFW.GetPlayerFromId(source)
            local cfg = cfgOf(brand)
            if not xPlayer or not cfg then return false end
            if not onDutyFor(xPlayer, jobName) then return false end

            local list = recipesOf(cfg, kind)
            if not list then return false end

            local recipe = findRecipe(list, recipeId)
            if not recipe then return false end

            local quantity = tonumber(recipe.outputQuantity) or 1
            if not xPlayer.canCarryItem(recipe.output, quantity) then return false end

            xPlayer.addInventoryItem(recipe.output, quantity)
            return true
        end)
    end

    MiscB.Cb(prefix .. "cooking:getRecipes", function(source, jobName, stationType)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return nil end
        if not onDutyFor(xPlayer, jobName) then return nil end

        local list = recipesOf(cfg, stationType)
        if not list then return nil end

        local out = {}
        for i = 1, #list do
            local recipe = list[i]
            local item = xPlayer.getInventoryItem(recipe.input)
            local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
            out[#out + 1] = {
                input = recipe.input,
                output = recipe.output,
                label = recipe.label,
                hasInput = count > 0,
                playerHas = count,
            }
        end
        return out
    end)

    MiscB.Cb(prefix .. "cooking:claimSlot", function(source, jobName, stationType, slotName, inputItem)
        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer then return false, "Joueur introuvable." end
        if not onDutyFor(xPlayer, jobName) then return false, "Vous devez etre en service." end
        if type(slotName) ~= "string" or #slotName > 32 then return false, "Ce poste n'est pas valide." end
        if type(stationType) ~= "string" or #stationType > 32 then return false, "Ce poste n'est pas valide." end
        if not xPlayer.haveItem(inputItem, 1) then return false, "Il vous manque l'ingredient." end
        return claimSlot(source, brand, jobName, stationType, slotName)
    end)

    MiscB.Cb(prefix .. "cooking:cancel", function(source, jobName, stationType, slotName)
        if type(slotName) ~= "string" or type(stationType) ~= "string" then return false end
        return releaseSlot(source, brand, jobName, stationType, slotName)
    end)

    MiscB.Cb(prefix .. "cooking:cookOne", function(source, jobName, stationType, slotName, inputItem)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return false end
        if not onDutyFor(xPlayer, jobName) then return false end

        local list = recipesOf(cfg, stationType)
        if not list then return false end

        local found = nil
        for i = 1, #list do
            if list[i].input == inputItem then found = list[i] break end
        end
        if not found then return false end
        if not xPlayer.haveItem(found.input, 1) then return false end

        return xPlayer.removeInventoryItem(found.input, 1) == true
    end)

    MiscB.Cb(prefix .. "cooking:completeOne", function(source, jobName, stationType, slotName, inputItem, outputItem)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return false end
        if not onDutyFor(xPlayer, jobName) then return false end

        local list = recipesOf(cfg, stationType)
        if not list then return false end

        local found = nil
        for i = 1, #list do
            if list[i].input == inputItem then found = list[i] break end
        end
        if not found then return false end
        if outputItem ~= nil and found.output ~= outputItem then return false end
        if not xPlayer.canCarryItem(found.output, 1) then return false end

        xPlayer.addInventoryItem(found.output, 1)
        return true
    end)

    MiscB.Cb(prefix .. "machine:getData", function(source, jobName)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return nil end
        if not onDutyFor(xPlayer, jobName) then return nil end
        if type(cfg.Machine) ~= "table" then return nil end
        return machineData(cfg, brand, jobName)
    end)

    MiscB.Cb(prefix .. "machine:serve", function(source, jobName, drinkKey, size)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return false end
        if not onDutyFor(xPlayer, jobName) then return false end
        if type(drinkKey) ~= "string" or type(size) ~= "string" then return false end

        local machine = type(cfg.Machine) == "table" and cfg.Machine or nil
        if not machine or type(machine.drinks) ~= "table" then return false end

        local drink = machine.drinks[drinkKey]
        if not drink or type(drink.sizes) ~= "table" then return false end

        local itemName = drink.sizes[size]
        if not itemName then return false end

        local decrease = 1
        if type(machine.serveDecrease) == "table" and tonumber(machine.serveDecrease[size]) then
            decrease = math.floor(tonumber(machine.serveDecrease[size]))
        end

        local key = machineKey(brand, jobName)
        machineLevels[key] = machineLevels[key] or {}
        if machineLevels[key][drinkKey] == nil then machineLevels[key][drinkKey] = 100 end
        if machineLevels[key][drinkKey] < decrease then return false end

        if not xPlayer.canCarryItem(itemName, 1) then return false end

        machineLevels[key][drinkKey] = machineLevels[key][drinkKey] - decrease
        xPlayer.addInventoryItem(itemName, 1)

        return true, machineData(cfg, brand, jobName)
    end)

    MiscB.Cb(prefix .. "machine:replaceBarrel", function(source, jobName, drinkKey)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return false end
        if not onDutyFor(xPlayer, jobName) then return false end
        if type(drinkKey) ~= "string" then return false end

        local machine = type(cfg.Machine) == "table" and cfg.Machine or nil
        if not machine or type(machine.drinks) ~= "table" then return false end

        local drink = machine.drinks[drinkKey]
        if not drink or not drink.barrel then return false end

        local key = machineKey(brand, jobName)
        machineLevels[key] = machineLevels[key] or {}
        if machineLevels[key][drinkKey] == nil then machineLevels[key][drinkKey] = 100 end

        local threshold = tonumber(machine.minReplaceThreshold) or 20
        if machineLevels[key][drinkKey] > threshold then return false end

        if not xPlayer.haveItem(drink.barrel, 1) then return false end
        if not xPlayer.removeInventoryItem(drink.barrel, 1) then return false end

        machineLevels[key][drinkKey] = 100
        return true, machineData(cfg, brand, jobName)
    end)

    MiscB.Cb(prefix .. "delivery:start", function(source, jobName)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        if not xPlayer or not cfg then return false, "Action impossible pour le moment." end
        if not onDutyFor(xPlayer, jobName) then return false, "Vous devez etre en service." end
        if deliveries[source] then return false, "Une livraison est deja en cours." end

        local step = newDeliveryStep(cfg, nil)
        if not step then return false, "Aucune commande disponible." end

        deliveries[source] = { brand = brand, jobName = jobName, step = step, delivered = 0 }
        return true, step
    end)

    MiscB.Cb(prefix .. "delivery:next", function(source)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        local delivery = deliveries[source]
        if not xPlayer or not cfg or not delivery or delivery.brand ~= brand then
            return false, "Aucune livraison en cours."
        end

        local step = newDeliveryStep(cfg, delivery.step)
        if not step then return false, "Il n'y a plus de clients disponibles." end

        delivery.step = step
        return true, step
    end)

    MiscB.Cb(prefix .. "delivery:checkItems", function(source)
        local xPlayer = VFW.GetPlayerFromId(source)
        local delivery = deliveries[source]
        if not xPlayer or not delivery or delivery.brand ~= brand then return false end

        local items = delivery.step and delivery.step.orderItems or {}
        for i = 1, #items do
            local item = xPlayer.getInventoryItem(items[i].name)
            local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
            if count < items[i].count then return false end
        end
        return true
    end)

    MiscB.Cb(prefix .. "delivery:deliver", function(source)
        local xPlayer = VFW.GetPlayerFromId(source)
        local cfg = cfgOf(brand)
        local delivery = deliveries[source]
        if not xPlayer or not cfg or not delivery or delivery.brand ~= brand then
            return false, "Aucune livraison en cours."
        end

        local items = delivery.step and delivery.step.orderItems or {}
        local missing = {}
        for i = 1, #items do
            local item = xPlayer.getInventoryItem(items[i].name)
            local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
            if count < items[i].count then
                missing[#missing + 1] = { label = items[i].label, have = count, need = items[i].count }
            end
        end

        if #missing > 0 then return false, nil, missing end

        for i = 1, #items do
            xPlayer.removeInventoryItem(items[i].name, items[i].count)
        end

        local total = tonumber(delivery.step.reward) or 0
        local societyPercent = tonumber(cfg.DeliverySocietyPercent) or 70
        local societyGain = math.floor(total * societyPercent / 100)
        local employeeBase = total - societyGain

        local tip = 0
        local chance = tonumber(cfg.DeliveryTipChance) or 0
        if chance > 0 and math.random(100) <= chance then
            tip = math.random(tonumber(cfg.DeliveryTipMin) or 0, tonumber(cfg.DeliveryTipMax) or 0)
        end

        xPlayer.addAccountMoney("money", employeeBase + tip, "livraison-" .. brand)

        if societyGain > 0 then
            TriggerEvent("vfw:society:addMoney", delivery.jobName, societyGain, "livraison-" .. brand)
        end

        MiscB.Insert([[
            INSERT INTO restaurant_delivery_logs (brand, job_name, identifier, player_name, reward, society_gain, tip, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        ]], { brand, delivery.jobName, xPlayer.identifier, MiscB.CharName(xPlayer), total, societyGain, tip })

        delivery.delivered = delivery.delivered + 1

        return true, employeeBase + tip, tip, societyGain
    end)

    MiscB.Cb(prefix .. "delivery:end", function(source)
        deliveries[source] = nil
        return true
    end)

    MiscB.Cb(prefix .. "delivery:clearLogs", function(source)
        local xPlayer = VFW.GetPlayerFromId(source)
        if not xPlayer or not MiscB.IsBoss(xPlayer) then return false end

        MiscB.Update("DELETE FROM restaurant_delivery_logs WHERE brand = ? AND job_name = ?",
            { brand, MiscB.JobName(xPlayer) })
        return true
    end)
end

for brand in pairs(BRANDS) do
    registerBrand(brand)
end

local function bagKey(jobName)
    return ("burgershot|%s"):format(tostring(jobName))
end

local function bagPayload(xPlayer, jobName)
    local cfg = cfgOf("burgershot")
    local key = bagKey(jobName)
    bags[key] = bags[key] or {}

    local allowed = type(cfg) == "table" and type(cfg.BagAllowedItems) == "table" and cfg.BagAllowedItems or {}
    local inventoryItems = {}
    for i = 1, #allowed do
        local item = xPlayer.getInventoryItem(allowed[i])
        local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
        if count > 0 then
            local def = VFW.Items and VFW.Items[allowed[i]] or nil
            inventoryItems[#inventoryItems + 1] = {
                name = allowed[i],
                label = (type(def) == "table" and def.label) or allowed[i],
                count = count,
            }
        end
    end

    local bagList = {}
    for slot, content in pairs(bags[key]) do
        bagList[#bagList + 1] = { slot = slot, items = content }
    end
    table.sort(bagList, function(a, b) return tostring(a.slot) < tostring(b.slot) end)

    return { bags = bagList, inventoryItems = inventoryItems }
end

MiscB.Cb("burgershot:bag:getData", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not onDutyFor(xPlayer, jobName) then return nil end
    return bagPayload(xPlayer, jobName)
end)

MiscB.Cb("burgershot:bag:addItem", function(source, jobName, bagSlot, itemName, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    local cfg = cfgOf("burgershot")
    if not xPlayer or not cfg then return false, "Action impossible pour le moment." end
    if not onDutyFor(xPlayer, jobName) then return false, "Vous devez etre en service." end

    local slot = bagSlot ~= nil and tostring(bagSlot) or nil
    local name = MiscB.Str(itemName, 64)
    local qty = MiscB.ToInt(quantity, 1, 50) or 1
    if not slot or #slot > 32 or not name then return false, "Cette demande n'a pas pu être traitée." end

    local allowed = false
    if type(cfg.BagAllowedItems) == "table" then
        for i = 1, #cfg.BagAllowedItems do
            if cfg.BagAllowedItems[i] == name then allowed = true break end
        end
    end
    if not allowed then return false, "Cet item ne peut pas etre mis dans un sac." end

    if not xPlayer.haveItem(name, qty) then return false, "Vous n'avez pas assez de cet item." end

    local key = bagKey(jobName)
    bags[key] = bags[key] or {}
    bags[key][slot] = bags[key][slot] or {}

    local total = 0
    for _, entry in pairs(bags[key][slot]) do total = total + (tonumber(entry) or 0) end
    local maxItems = tonumber(cfg.BagMaxItems) or 10
    if total + qty > maxItems then return false, "Le sac est plein." end

    if not xPlayer.removeInventoryItem(name, qty) then return false, "Erreur d'inventaire." end
    bags[key][slot][name] = (bags[key][slot][name] or 0) + qty

    return true, nil, bagPayload(xPlayer, jobName)
end)

MiscB.Cb("burgershot:bag:removeItem", function(source, jobName, bagSlot, itemName, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Action impossible pour le moment." end
    if not onDutyFor(xPlayer, jobName) then return false, "Vous devez etre en service." end

    local slot = bagSlot ~= nil and tostring(bagSlot) or nil
    local name = MiscB.Str(itemName, 64)
    local qty = MiscB.ToInt(quantity, 1, 50) or 1
    if not slot or not name then return false, "Cette demande n'a pas pu être traitée." end

    local key = bagKey(jobName)
    if not bags[key] or not bags[key][slot] then return false, "Sac vide." end

    local stored = tonumber(bags[key][slot][name]) or 0
    if stored < qty then return false, "Quantite insuffisante dans le sac." end
    if not xPlayer.canCarryItem(name, qty) then return false, "Inventaire plein." end

    bags[key][slot][name] = stored - qty
    if bags[key][slot][name] <= 0 then bags[key][slot][name] = nil end
    if next(bags[key][slot]) == nil then bags[key][slot] = nil end

    xPlayer.addInventoryItem(name, qty)
    return true, nil, bagPayload(xPlayer, jobName)
end)

local stationOverrides = nil
local stationsLoading = false

local function loadStations()
    if stationOverrides then return stationOverrides end
    if stationsLoading then
        local waited = 0
        while stationsLoading and waited < 5000 do
            Wait(10)
            waited = waited + 10
        end
        return stationOverrides or {}
    end
    stationsLoading = true

    local rows = MiscB.Query("SELECT resto_key, loc_key, station_key, data FROM restaurant_stations", {})
    local loaded = {}
    for i = 1, #rows do
        local row = rows[i]
        loaded[row.resto_key] = loaded[row.resto_key] or {}
        loaded[row.resto_key][row.loc_key] = loaded[row.resto_key][row.loc_key] or {}
        loaded[row.resto_key][row.loc_key][row.station_key] = VFW.DB.Decode(row.data, {})
    end

    stationOverrides = loaded
    stationsLoading = false
    return stationOverrides
end

MiscB.Cb("restaurant_stations:getAll", function(source)
    return loadStations()
end)

AddEventHandler("vfw:playerDropped", function(source)
    deliveries[source] = nil
    for key, holder in pairs(slotClaims) do
        if holder == source then slotClaims[key] = nil end
    end
end)
