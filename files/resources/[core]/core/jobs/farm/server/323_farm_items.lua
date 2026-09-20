VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Farm = VFW.Farm or {}

local JC = VFW.JobsCommon
local Farm = VFW.Farm

local pendingUse = {}

local function registerUsable(name, handler)
    local Inv = VFW.Inventory
    if not Inv or not Inv.RegisterUsableItem then return false end
    return Inv.RegisterUsableItem(name, handler)
end

local function deferredUse(eventName, itemNames)
    return function(xPlayer, entry)
        local source = xPlayer.source
        pendingUse[source] = {
            slot = entry and entry.slot or nil,
            name = entry and entry.name or nil,
            names = itemNames,
            at = GetGameTimer(),
        }
        TriggerClientEvent(eventName, source, { id = entry and entry.slot or 0, name = entry and entry.name or "" })
    end
end

local function consumePending(source, expectedNames)
    local pending = pendingUse[source]
    pendingUse[source] = nil
    if not pending then return false end
    if (GetGameTimer() - (pending.at or 0)) > 600000 then return false end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    if expectedNames and pending.name then
        local ok = false
        for i = 1, #expectedNames do
            if expectedNames[i] == pending.name then
                ok = true
                break
            end
        end
        if not ok then return false end
    end

    return JC.RemoveSlot(xPlayer, pending.slot, pending.name)
end

AddEventHandler("playerDropped", function()
    local source = source
    pendingUse[source] = nil
end)

local BANG_ITEMS = { "bang" }
local CANDY_ITEMS = { "cbd_candy" }
local JOINT_ITEMS = { "cbd_joint", "cbd_joint_1", "cbd_joint_2" }
local VAPE_ITEMS = { "e_cigarette_cbd", "e_cigarette_cbd_1", "e_cigarette_cbd_2" }

CreateThread(function()
    Wait(0)

    registerUsable("bang", deferredUse("cbdshop:useBang", BANG_ITEMS))

    for i = 1, #CANDY_ITEMS do
        registerUsable(CANDY_ITEMS[i], deferredUse("cbdshop:useCandy", CANDY_ITEMS))
    end
    for i = 1, #JOINT_ITEMS do
        registerUsable(JOINT_ITEMS[i], deferredUse("cbdshop:useJoint", JOINT_ITEMS))
    end
    for i = 1, #VAPE_ITEMS do
        registerUsable(VAPE_ITEMS[i], deferredUse("cbdshop:useCigarette", VAPE_ITEMS))
    end

    registerUsable("cigarette", function(xPlayer, entry)
        local source = xPlayer.source
        if not JC.RemoveSlot(xPlayer, entry and entry.slot or nil, "cigarette") then return end
        TriggerClientEvent("core:UseCigarette", source)
    end)

    local carteJobs = {}
    if type(BarsConfig) == "table" then
        for i = 1, #BarsConfig do
            local bar = BarsConfig[i]
            if type(bar) == "table" and type(bar.jobName) == "string" then
                carteJobs[bar.jobName .. "_carte"] = bar.jobName
            end
        end
    end
    carteJobs["burgershot_carte"] = "burgershot"

    for itemName, jobName in pairs(carteJobs) do
        registerUsable(itemName, function(xPlayer)
            TriggerClientEvent("bar:menu:openFromItem", xPlayer.source, jobName)
        end)
    end
end)

RegisterNetEvent("cbd:useBang:done", function(isCancelled, itemId)
    local source = source
    if type(isCancelled) ~= "boolean" then isCancelled = isCancelled == true end
    if itemId ~= nil and type(itemId) ~= "number" and type(itemId) ~= "string" then return end

    if isCancelled then
        pendingUse[source] = nil
        return
    end

    consumePending(source, BANG_ITEMS)
end)

RegisterNetEvent("cbd:useCandy:done", function(itemId)
    local source = source
    if itemId ~= nil and type(itemId) ~= "number" and type(itemId) ~= "string" then return end
    consumePending(source, CANDY_ITEMS)
end)

RegisterNetEvent("cbd:useJoint:done", function(itemId)
    local source = source
    if itemId ~= nil and type(itemId) ~= "number" and type(itemId) ~= "string" then return end
    consumePending(source, JOINT_ITEMS)
end)

RegisterNetEvent("cbd:useCigarette:done", function(itemId)
    local source = source
    if itemId ~= nil and type(itemId) ~= "number" and type(itemId) ~= "string" then return end
    consumePending(source, VAPE_ITEMS)
end)

local function findRecipe(recipeId)
    if type(CbdShopConfig) ~= "table" then return nil end
    local crafting = CbdShopConfig.crafting
    if type(crafting) ~= "table" or type(crafting.recipes) ~= "table" then return nil end

    for i = 1, #crafting.recipes do
        local recipe = crafting.recipes[i]
        if recipe.output == recipeId or recipe.name == recipeId then return recipe end
    end
    return nil
end

Farm.FindCbdRecipe = findRecipe

JC.Cb("farm:cbdshop:craft", function(source, recipeId, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not JC.HasJob(xPlayer, "cbdshop", false) then return false end

    local id = JC.Str(recipeId, 60)
    if not id then return false end

    local qty = JC.Int(quantity, 1, 50)
    if not qty then return false end

    local recipe = findRecipe(id)
    if not recipe then return false end

    if not JC.Throttle(source, "farm:craft:cbdshop", 1000) then return false end

    local craftCoords = CbdShopConfig.crafting.coords
    if craftCoords and JC.Dist(source, craftCoords) > 10.0 then return false end

    local outputQuantity = (JC.Int(recipe.outputQuantity, 1) or 1) * qty

    for i = 1, #(recipe.ingredients or {}) do
        local ingredient = recipe.ingredients[i]
        local need = (JC.Int(ingredient.quantity, 1) or 1) * qty
        if JC.Count(xPlayer, ingredient.name) < need then return false end
    end

    if not JC.CanCarry(xPlayer, recipe.output, outputQuantity) then return false end

    local consumed = {}
    for i = 1, #(recipe.ingredients or {}) do
        local ingredient = recipe.ingredients[i]
        local need = (JC.Int(ingredient.quantity, 1) or 1) * qty
        if not JC.Remove(xPlayer, ingredient.name, need) then
            for j = 1, #consumed do
                JC.Add(xPlayer, consumed[j].name, consumed[j].count)
            end
            return false
        end
        consumed[#consumed + 1] = { name = ingredient.name, count = need }
    end

    if not JC.Add(xPlayer, recipe.output, outputQuantity) then
        for j = 1, #consumed do
            JC.Add(xPlayer, consumed[j].name, consumed[j].count)
        end
        return false
    end

    Farm.Log(xPlayer, "cbdshop", "process", recipe.output, outputQuantity, 0)
    return true
end)
