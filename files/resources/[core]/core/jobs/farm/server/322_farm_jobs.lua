VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Farm = VFW.Farm or {}

local JC = VFW.JobsCommon
local Farm = VFW.Farm

local HARVEST_COOLDOWN = 2000
local PROCESS_COOLDOWN = 2000
local SELL_COOLDOWN = 3000
local HARVEST_RADIUS = 6.0
local PROCESS_RADIUS = 6.0

local function toPoint(value)
    local kind = type(value)
    if kind == "vector3" or kind == "vector4" then
        return { x = value.x + 0.0, y = value.y + 0.0, z = value.z + 0.0 }
    end
    return JC.Vec(value)
end

local function actor(source, societyName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not JC.HasJob(xPlayer, societyName, false) then return nil end
    return xPlayer
end

local function nearHarvest(source, societyName)
    local points = Farm.HarvestPoints(societyName)
    if #points == 0 then return true end
    local ok = JC.NearAny(source, points, HARVEST_RADIUS)
    return ok == true
end

local function nearProcessing(source, societyName)
    local points = Farm.ProcessingPoints(societyName)
    if #points == 0 then return true end
    local ok = JC.NearAny(source, points, PROCESS_RADIUS)
    return ok == true
end

local function nearSellingPed(source, societyName)
    local ped = Farm.PedPayload(societyName)
    if not ped or ped.x == 0.0 then return false end
    return JC.Dist(source, ped) <= 8.0
end

local function giveHarvest(source, xPlayer, societyName, itemName)
    if not JC.Throttle(source, "farm:harvest:" .. societyName, HARVEST_COOLDOWN) then return end
    if not nearHarvest(source, societyName) then
        JC.Notify(source, "Vous n'etes pas sur un point de recolte.", true)
        return
    end
    if not JC.Add(xPlayer, itemName, 1) then
        JC.Notify(source, "Vous ne pouvez pas en porter davantage.", true)
        return
    end
    Farm.Log(xPlayer, societyName, "harvest", itemName, 1, 0)
end

local function doProcess(source, xPlayer, societyName, inputItem)
    local def = Farm.Definitions[societyName]
    if not def then return end

    local recipe = def.recipes and def.recipes[inputItem]
    if not recipe then
        JC.Notify(source, "Cette transformation n'existe pas.", true)
        return
    end

    if not JC.Throttle(source, "farm:process:" .. societyName, PROCESS_COOLDOWN) then return end
    if not nearProcessing(source, societyName) then
        JC.Notify(source, "Vous n'etes pas sur un point de transformation.", true)
        return
    end

    local fromItem = recipe.from or inputItem
    local cost = JC.Int(recipe.cost, 1) or 1

    if JC.Count(xPlayer, fromItem) < cost then
        JC.Notify(source, ("Vous devez avoir au moins %d %s."):format(cost, JC.ItemLabel(fromItem)), true)
        return
    end

    if not JC.CanCarry(xPlayer, recipe.output, 1) then
        JC.Notify(source, "Vous ne pouvez pas porter davantage.", true)
        return
    end

    if not JC.Remove(xPlayer, fromItem, cost) then return end
    if not JC.Add(xPlayer, recipe.output, 1) then
        JC.Add(xPlayer, fromItem, cost)
        return
    end

    Farm.Log(xPlayer, societyName, "process", recipe.output, 1, 0)
end

local function doSell(source, societyName)
    local xPlayer = actor(source, societyName)
    if not xPlayer then return end

    local def = Farm.Definitions[societyName]
    if not def then return end

    if not JC.Throttle(source, "farm:sell:" .. societyName, SELL_COOLDOWN) then return end
    if not nearSellingPed(source, societyName) then
        JC.Notify(source, "Vous n'etes pas devant l'acheteur.", true)
        return
    end

    local percent = Farm.SocietyPercent(societyName)
    local totalPlayer, totalSociety, totalItems = 0, 0, 0

    for i = 1, #(def.sellItems or {}) do
        local itemName = def.sellItems[i]
        local count = JC.Count(xPlayer, itemName)
        if count > 0 then
            if JC.Remove(xPlayer, itemName, count) then
                local unit = Farm.Price(societyName, itemName)
                local gross = unit * count
                local societyCut = math.floor(gross * percent / 100)
                local playerCut = gross - societyCut

                totalPlayer = totalPlayer + playerCut
                totalSociety = totalSociety + societyCut
                totalItems = totalItems + count

                Farm.Log(xPlayer, societyName, "selling", itemName, count, playerCut)
            end
        end
    end

    if totalItems == 0 then
        JC.Notify(source, "Vous n'avez rien a vendre.", true)
        return
    end

    if totalPlayer > 0 then
        xPlayer.addAccountMoney("money", totalPlayer, ("Vente %s"):format(societyName))
    end
    if totalSociety > 0 then
        JC.AddSocietyMoney(societyName, totalSociety, "farm-vente")
    end

    JC.Notify(source, ("Vous avez vendu %d produit%s pour %d$."):format(totalItems, totalItems > 1 and "s" or "", totalPlayer), false)
end

local BARLEY_BARS = { "asgard", "billard", "henhouse", "irishpub", "unicorn", "yellowjack", "cayo_lagoon" }

for i = 1, #BARLEY_BARS do
    local societyName = BARLEY_BARS[i]

    RegisterNetEvent(("farm:%s:give"):format(societyName), function(action, itemType)
        local source = source
        local xPlayer = actor(source, societyName)
        if not xPlayer then return end

        local act = JC.Str(action, 32)
        if act == "harvest" then
            giveHarvest(source, xPlayer, societyName, Farm.Definitions[societyName].harvestItem)
        elseif act == "process" then
            local input = JC.Str(itemType, 60)
            if not input then return end
            doProcess(source, xPlayer, societyName, input)
        end
    end)

    RegisterNetEvent(("farm:%s:selling"):format(societyName), function()
        local source = source
        doSell(source, societyName)
    end)

    JC.Cb(("farm:%s:canProcess"):format(societyName), function(source, action, itemType)
        local xPlayer = actor(source, societyName)
        if not xPlayer then return false end

        local def = Farm.Definitions[societyName]
        local act = JC.Str(action, 32)

        if act == "process" then
            local input = JC.Str(itemType, 60)
            if not input then return false end
            local recipe = def.recipes and def.recipes[input]
            if not recipe then return false end
            return JC.Count(xPlayer, recipe.from or input) >= (JC.Int(recipe.cost, 1) or 1)
        end

        if act == "selling" then
            for j = 1, #(def.sellItems or {}) do
                if JC.Count(xPlayer, def.sellItems[j]) > 0 then return true end
            end
            return false
        end

        return false
    end)
end

RegisterNetEvent("farm:cayofarm:give", function(first, action)
    local source = source
    local xPlayer = actor(source, "cayofarm")
    if not xPlayer then return end

    local act = JC.Str(action, 32)
    if act == "harvest" then
        local index = JC.Int(first, 1)
        local points = Farm.HarvestPoints("cayofarm")
        if not index or (#points > 0 and index > #points) then return end
        giveHarvest(source, xPlayer, "cayofarm", "mango")
    elseif act == "process" then
        local input = JC.Str(first, 60)
        if not input then return end
        doProcess(source, xPlayer, "cayofarm", input)
    end
end)

RegisterNetEvent("farm:cayofarm:selling", function()
    local source = source
    doSell(source, "cayofarm")
end)

JC.Cb("farm:cayofarm:canProcess", function(source, action, fruitType)
    local xPlayer = actor(source, "cayofarm")
    if not xPlayer then return false end

    local act = JC.Str(action, 32)
    if act == "process" then
        local input = JC.Str(fruitType, 60) or "mango"
        local recipe = Farm.Definitions.cayofarm.recipes[input]
        if not recipe then return false end
        return JC.Count(xPlayer, input) >= recipe.cost
    end
    if act == "selling" then
        return JC.Count(xPlayer, "juice_mango") > 0
    end
    return false
end)

local GRAPES = { "white_grapes", "red_grapes", "yellow_grapes" }

RegisterNetEvent("farm:vigneron:give", function(first, action)
    local source = source
    local xPlayer = actor(source, "vigneron")
    if not xPlayer then return end

    local act = JC.Str(action, 32)
    if act == "harvest" then
        local index = JC.Int(first, 1)
        local points = Farm.HarvestPoints("vigneron")
        if not index or (#points > 0 and index > #points) then return end
        local variety = GRAPES[((index - 1) % #GRAPES) + 1]
        giveHarvest(source, xPlayer, "vigneron", variety)
    elseif act == "process" then
        local input = JC.Str(first, 60)
        if not input then return end
        doProcess(source, xPlayer, "vigneron", input)
    end
end)

RegisterNetEvent("farm:vigneron:selling", function()
    local source = source
    doSell(source, "vigneron")
end)

JC.Cb("farm:vigneron:canProcess", function(source, action, grapesType)
    local xPlayer = actor(source, "vigneron")
    if not xPlayer then return false end

    local act = JC.Str(action, 32)
    if act == "process" then
        local input = JC.Str(grapesType, 60)
        if not input then return false end
        local recipe = Farm.Definitions.vigneron.recipes[input]
        if not recipe then return false end
        return JC.Count(xPlayer, input) >= recipe.cost
    end
    if act == "selling" then
        for i = 1, #Farm.Definitions.vigneron.sellItems do
            if JC.Count(xPlayer, Farm.Definitions.vigneron.sellItems[i]) > 0 then return true end
        end
        return false
    end
    return false
end)

local TABAC_PACKAGING_COST = 5

RegisterNetEvent("farm:tabac:give", function(index, action)
    local source = source
    local xPlayer = actor(source, "tabac")
    if not xPlayer then return end

    local act = JC.Str(action, 32)
    local idx = JC.Int(index, 1)
    if not idx then return end

    if act == "harvest" then
        if type(TabacConfig) == "table" and TabacConfig.plants and idx > #TabacConfig.plants then return end
        giveHarvest(source, xPlayer, "tabac", "paper_tabacco")
        return
    end

    if act == "process" then
        if type(TabacConfig) == "table" and TabacConfig.processing and idx > #TabacConfig.processing then return end
        doProcess(source, xPlayer, "tabac", "paper_tabacco")
        return
    end

    if act == "selling" then
        if type(TabacConfig) == "table" and TabacConfig.packaging and idx > #TabacConfig.packaging then return end
        if not JC.Throttle(source, "farm:process:tabac", PROCESS_COOLDOWN) then return end

        if JC.Count(xPlayer, "cigarette") < TABAC_PACKAGING_COST then
            JC.Notify(source, ("Vous devez avoir au moins %d cigarettes."):format(TABAC_PACKAGING_COST), true)
            return
        end
        if not JC.CanCarry(xPlayer, "cigarette_paquet", 1) then
            JC.Notify(source, "Vous ne pouvez pas porter davantage.", true)
            return
        end
        if not JC.Remove(xPlayer, "cigarette", TABAC_PACKAGING_COST) then return end
        if not JC.Add(xPlayer, "cigarette_paquet", 1) then
            JC.Add(xPlayer, "cigarette", TABAC_PACKAGING_COST)
            return
        end
        Farm.Log(xPlayer, "tabac", "packaging", "cigarette_paquet", 1, 0)
    end
end)

RegisterNetEvent("farm:tabac:selling", function()
    local source = source
    doSell(source, "tabac")
end)

JC.Cb("farm:tabac:canProcess", function(source, action)
    local xPlayer = actor(source, "tabac")
    if not xPlayer then return false end

    local act = JC.Str(action, 32)
    if act == "process" then
        return JC.Count(xPlayer, "paper_tabacco") >= 3
    end
    if act == "packaging" then
        return JC.Count(xPlayer, "cigarette") >= TABAC_PACKAGING_COST
    end
    if act == "selling" then
        return JC.Count(xPlayer, "cigarette_paquet") > 0
    end
    return false
end)

RegisterNetEvent("farm:globeoil:give", function(index, action, coords)
    local source = source
    local xPlayer = actor(source, "globeoil")
    if not xPlayer then return end

    local act = JC.Str(action, 32)
    local idx = JC.Int(index, 1)

    if act == "harvest" then
        if not idx then return end
        local point = toPoint(coords)
        if point and JC.Dist(source, point) > 12.0 then return end
        giveHarvest(source, xPlayer, "globeoil", "empty_barrel")
        return
    end

    if act == "process" then
        if not idx then return end
        if type(GlobeOilConfig) == "table" and GlobeOilConfig.processing and idx > #GlobeOilConfig.processing then return end
        doProcess(source, xPlayer, "globeoil", "empty_barrel")
    end
end)

RegisterNetEvent("farm:globeoil:selling", function()
    local source = source
    doSell(source, "globeoil")
end)

JC.Cb("farm:globeoil:canProcess", function(source, action)
    local xPlayer = actor(source, "globeoil")
    if not xPlayer then return false end

    local act = JC.Str(action, 32)
    if act == "processing" or act == "process" then
        return JC.Count(xPlayer, "empty_barrel") >= 1
    end
    if act == "selling" then
        return JC.Count(xPlayer, "petrol_barrel") > 0
    end
    return false
end)

RegisterNetEvent("farm:cbdshop:give", function(first, action, coords)
    local source = source
    local xPlayer = actor(source, "cbdshop")
    if not xPlayer then return end

    local act = JC.Str(action, 32)

    if act == "harvest" then
        local point = toPoint(coords)
        if not point then return end
        if JC.Dist(source, point) > 8.0 then return end
        if not JC.Throttle(source, "farm:harvest:cbdshop", HARVEST_COOLDOWN) then return end
        if not JC.Add(xPlayer, "cbd_leaf", 1) then
            JC.Notify(source, "Vous ne pouvez pas en porter davantage.", true)
            return
        end
        Farm.Log(xPlayer, "cbdshop", "harvest", "cbd_leaf", 1, 0)
        return
    end

    if act == "process" then
        local itemName = JC.Str(first, 60)
        if not itemName then return end
        if itemName ~= "cbd_oil" and itemName ~= "cannabis_flower" then return end
        doProcess(source, xPlayer, "cbdshop", itemName)
    end
end)

RegisterNetEvent("farm:cbdshop:selling", function()
    local source = source
    doSell(source, "cbdshop")
end)

JC.Cb("farm:cbdshop:canProcess", function(source, action)
    local xPlayer = actor(source, "cbdshop")
    if not xPlayer then return false end

    local act = JC.Str(action, 32)
    if act == "processing" or act == "process" then
        return JC.Count(xPlayer, "cbd_leaf") >= 1
    end
    if act == "selling" then
        return JC.Count(xPlayer, "cbd_oil") > 0 or JC.Count(xPlayer, "cannabis_flower") > 0
    end
    return false
end)
