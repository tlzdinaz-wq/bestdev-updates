local pendingCraft = {}

local function logCraft(xPlayer, item, quantity, result)
    VFW.Society.Insert([[
        INSERT INTO society_craft_logs (job_name, identifier, player_name, item, quantity, result)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        xPlayer.job and xPlayer.job.name or "",
        xPlayer.identifier or "",
        xPlayer.name or "",
        tostring(item):sub(1, 64),
        quantity,
        result,
    })
end

RegisterNetEvent("society:craft:startLogs", function(name, quantity)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(name) ~= "string" or name == "" then return end

    local amount = tonumber(quantity)
    if not amount or amount < 1 then amount = 1 end
    amount = math.floor(math.min(amount, 100))

    logCraft(xPlayer, name, amount, "request")
end)

VFW.Society.RegisterCallback("society:craft:startCraft", function(source, name, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return false end
    if type(name) ~= "string" or name == "" then return false end

    local amount = tonumber(quantity)
    if not amount or amount < 1 then return false end
    amount = math.floor(math.min(amount, 100))

    local recipe = VFW.Society.GetRecipe(xPlayer.job.name, name)
    if not recipe then return false end

    if not xPlayer.job.onDuty then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous devez être en service." })
        return false
    end

    for i = 1, #recipe.recipe do
        local ingredient = recipe.recipe[i]
        local needed = (tonumber(ingredient.amount) or 1) * amount
        if not xPlayer.haveItem(ingredient.name, needed) then
            return false
        end
    end

    local produced = (tonumber(recipe.amount) or 1) * amount
    if not xPlayer.canCarryItem(name, produced) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez pas assez de place." })
        return false
    end

    for i = 1, #recipe.recipe do
        local ingredient = recipe.recipe[i]
        local needed = (tonumber(ingredient.amount) or 1) * amount
        xPlayer.removeInventoryItem(ingredient.name, needed, nil, false)
    end

    pendingCraft[source] = {
        name = name,
        quantity = amount,
        produced = produced,
        expires = os.time() + 600,
    }

    logCraft(xPlayer, name, amount, "started")

    return true
end)

RegisterNetEvent("society:craft:additem", function(name, quantity)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(name) ~= "string" or name == "" then return end

    local pending = pendingCraft[source]
    if not pending then return end
    if pending.name ~= name then return end
    if os.time() > pending.expires then
        pendingCraft[source] = nil
        return
    end

    pendingCraft[source] = nil

    xPlayer.addInventoryItem(name, pending.produced, nil, true)
    logCraft(xPlayer, name, pending.quantity, "collected")
end)

AddEventHandler("playerDropped", function()
    local source = source
    pendingCraft[source] = nil
end)
