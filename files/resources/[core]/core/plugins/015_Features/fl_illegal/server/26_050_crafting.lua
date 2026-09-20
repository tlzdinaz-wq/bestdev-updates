local Crafting = {
    stations = {},
    recipes = {},
    recipesById = {},
    queues = {},
    viewers = {},
    orders = {},
    dynamicOrders = {},
    running = {},
}

local BUILDER_PERM = "illegal_activities_builder"
local STATION_RANGE = 8.0

local function LoadStations()
    Crafting.stations = {}
    local rows = IL.Query("SELECT * FROM illegal_craft_stations")
    for i = 1, #rows do
        local row = rows[i]
        Crafting.stations[row.id] = {
            id = row.id,
            name = row.name or "Fabrication",
            station_type = row.station_type or "armes",
            coords_x = IL.Num(row.coords_x, 0.0),
            coords_y = IL.Num(row.coords_y, 0.0),
            coords_z = IL.Num(row.coords_z, 0.0),
            rotation_z = IL.Num(row.rotation_z, 0.0),
            marker_x = row.marker_x, marker_y = row.marker_y, marker_z = row.marker_z,
            prop_model = row.prop_model,
            blip_enabled = IL.Bool(row.blip_enabled),
            blip_sprite = IL.Int(row.blip_sprite, 1),
            blip_color = IL.Int(row.blip_color, 1),
            blip_scale = IL.Num(row.blip_scale, 0.5),
            blip_label = row.blip_label,
            faction_restriction = row.faction_restriction or "",
            faction_grade_min = IL.Int(row.faction_grade_min, 0),
        }
    end
end

local function LoadRecipes()
    Crafting.recipes = {}
    Crafting.recipesById = {}
    local rows = IL.Query("SELECT * FROM illegal_craft_recipes ORDER BY station_id, slot_index, id")
    for i = 1, #rows do
        local row = rows[i]
        local recipe = {
            id = row.id,
            station_id = row.station_id,
            recipe_name = row.recipe_name,
            label = row.label or IL.ItemLabel(row.output_item),
            output_item = row.output_item,
            output_quantity = IL.Int(row.output_quantity, 1),
            ingredients = IL.Decode(row.ingredients, {}),
            craft_time = IL.Int(row.craft_time, 5000),
            slot_index = IL.Int(row.slot_index, 0),
            faction_restriction = row.faction_restriction or "",
            faction_grade_min = IL.Int(row.faction_grade_min, 0),
        }
        Crafting.recipes[row.station_id] = Crafting.recipes[row.station_id] or {}
        local list = Crafting.recipes[row.station_id]
        list[#list + 1] = recipe
        Crafting.recipesById[row.id] = recipe
    end
end

local function CanUseStation(xPlayer, station)
    if not station then return false end
    return IL.HasFactionAccess(xPlayer, station.faction_restriction, station.faction_grade_min)
end

local function ClosestStation(source)
    local coords = IL.Coords(source)
    if not coords then return nil, 9999.0 end
    local best, bestDist = nil, 9999.0
    for _, station in pairs(Crafting.stations) do
        local dx = coords.x - station.coords_x
        local dy = coords.y - station.coords_y
        local dz = coords.z - station.coords_z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        if dist < bestDist then
            best, bestDist = station, dist
        end
    end
    return best, bestDist
end

local function IngredientList(recipe)
    local out = {}
    local ingredients = recipe.ingredients
    if not IL.IsTable(ingredients) then return out end
    for i = 1, #ingredients do
        local entry = ingredients[i]
        if IL.IsTable(entry) then
            local name = IL.Str(entry.item or entry.name, nil)
            local count = IL.Int(entry.count or entry.quantity, 1)
            if name and count > 0 then
                out[#out + 1] = { item = name, count = count }
            end
        end
    end
    return out
end

local function HasIngredients(xPlayer, recipe, multiplier)
    local list = IngredientList(recipe)
    for i = 1, #list do
        if not xPlayer.haveItem(list[i].item, list[i].count * multiplier) then
            return false, list[i].item
        end
    end
    return true, nil
end

local function ConsumeIngredients(xPlayer, recipe, multiplier)
    local list = IngredientList(recipe)
    for i = 1, #list do
        if not xPlayer.haveItem(list[i].item, list[i].count * multiplier) then
            return false
        end
    end
    for i = 1, #list do
        xPlayer.removeInventoryItem(list[i].item, list[i].count * multiplier, nil, true)
    end
    return true
end

local function RecipeSlot(xPlayer, recipe)
    local ingredients = {}
    local list = IngredientList(recipe)
    for i = 1, #list do
        ingredients[#ingredients + 1] = {
            name = list[i].item,
            label = IL.ItemLabel(list[i].item),
            count = list[i].count,
            quantity = list[i].count,
            has = xPlayer and xPlayer.haveItem(list[i].item, list[i].count) or false,
        }
    end
    return {
        id = recipe.recipe_name,
        recipeDbId = recipe.id,
        itemId = recipe.recipe_name,
        itemName = recipe.output_item,
        name = recipe.output_item,
        label = recipe.label,
        quantity = recipe.output_quantity,
        craftTime = recipe.craft_time,
        time = recipe.craft_time,
        slot = recipe.slot_index,
        ingredients = ingredients,
        isLegal = false,
    }
end

local function StationsMap()
    local out = {}
    for id, station in pairs(Crafting.stations) do
        out[id] = station
    end
    return out
end

local function QueuePayload(stationId)
    local queue = Crafting.queues[stationId] or {}
    local out = {}
    for i = 1, #queue do
        local entry = queue[i]
        out[#out + 1] = {
            id = entry.id,
            position = i,
            playerName = entry.playerName,
            recipeName = entry.recipeName,
            itemLabel = entry.itemLabel,
            quantity = entry.quantity,
            status = entry.status,
        }
    end
    return out
end

local function PushQueue(stationId)
    local payload = QueuePayload(stationId)
    local viewers = Crafting.viewers[stationId]
    if not viewers then return end
    for source in pairs(viewers) do
        TriggerClientEvent("illegalCrafting:queueUpdated", source, stationId, payload)
    end
end

local function AdvanceQueue(stationId)
    local queue = Crafting.queues[stationId]
    if not queue or #queue == 0 then
        Crafting.running[stationId] = nil
        return
    end
    if Crafting.running[stationId] then return end

    local entry = queue[1]
    local xPlayer = IL.Player(entry.source)
    if not xPlayer then
        table.remove(queue, 1)
        PushQueue(stationId)
        return AdvanceQueue(stationId)
    end

    entry.status = "running"
    Crafting.running[stationId] = entry
    PushQueue(stationId)

    TriggerClientEvent("illegalBuilder:startDynamicCraft", entry.source, stationId, entry.recipeDbId, entry.recipeName, entry.quantity)
end

local function FinishQueueEntry(stationId)
    local queue = Crafting.queues[stationId]
    if queue and #queue > 0 then
        table.remove(queue, 1)
    end
    Crafting.running[stationId] = nil
    PushQueue(stationId)
    AdvanceQueue(stationId)
end

IL.OnReady(function()
    LoadStations()
    LoadRecipes()
    IL.Execute("UPDATE illegal_craft_queue SET status = 'cancelled' WHERE status IN ('queued','running')")
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("illegalBuilder:syncCraftStations", source, StationsMap())
    TriggerClientEvent("illegalCrafting:receiveStations", source, {})
end)

IL.OnPlayerDropped(function(source)
    Crafting.orders[source] = nil
    Crafting.dynamicOrders[source] = nil
    for stationId, viewers in pairs(Crafting.viewers) do
        viewers[source] = nil
    end
    for stationId, queue in pairs(Crafting.queues) do
        local i = 1
        while i <= #queue do
            if queue[i].source == source then
                table.remove(queue, i)
            else
                i = i + 1
            end
        end
        local running = Crafting.running[stationId]
        if running and running.source == source then
            Crafting.running[stationId] = nil
            AdvanceQueue(stationId)
        end
        PushQueue(stationId)
    end
end)

RegisterNetEvent("illegalCrafting:requestStations", function()
    local source = source
    TriggerClientEvent("illegalCrafting:receiveStations", source, {})
end)

RegisterNetEvent("illegalCrafting:openStationMenu", function(stationId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(stationId, nil)
    local station = id and Crafting.stations[id] or nil
    if not station then
        TriggerClientEvent("illegalCrafting:notify", source, "ROUGE", "Station introuvable")
        return
    end
    if not CanUseStation(xPlayer, station) then
        TriggerClientEvent("illegalCrafting:notify", source, "ROUGE", "Vous n'avez pas acces a cette station")
        return
    end

    local slots = {}
    local list = Crafting.recipes[id] or {}
    for i = 1, #list do
        slots[#slots + 1] = RecipeSlot(xPlayer, list[i])
    end

    TriggerClientEvent("illegalCrafting:visible", source, true)
    TriggerClientEvent("illegalCrafting:data", source, { title = station.name, slots = slots })
end)

RegisterNetEvent("illegalCrafting:close", function()
    local source = source
    Crafting.orders[source] = nil
end)

RegisterNetEvent("illegalCrafting:cancelCraft", function()
    local source = source
    Crafting.orders[source] = nil
end)

RegisterNetEvent("illegalCrafting:completeCraft", function(payload)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if not IL.IsTable(payload) then return end

    local itemId = IL.Str(payload.itemId, nil)
    if not itemId then return end

    local order = Crafting.orders[source]
    if not order or order.recipeName ~= itemId then return end
    if order.remaining <= 0 then
        Crafting.orders[source] = nil
        return
    end

    local recipe = order.recipe
    local station = Crafting.stations[order.stationId]
    if station and IL.DistanceTo(source, station.coords_x, station.coords_y, station.coords_z) > STATION_RANGE then
        Crafting.orders[source] = nil
        TriggerClientEvent("illegalCrafting:notify", source, "ROUGE", "Vous avez quitte la station")
        return
    end

    if not ConsumeIngredients(xPlayer, recipe, 1) then
        Crafting.orders[source] = nil
        TriggerClientEvent("illegalCrafting:notify", source, "ROUGE", "Ingredients manquants")
        return
    end

    order.remaining = order.remaining - 1
    if not IL.GiveItem(xPlayer, recipe.output_item, recipe.output_quantity, true) then
        TriggerClientEvent("illegalCrafting:notify", source, "ROUGE", "Inventaire plein")
    end

    if order.remaining <= 0 then
        Crafting.orders[source] = nil
    end
end)

IL.RegisterCallback("illegalCrafting:getStationData", function(source)
    local xPlayer = IL.Player(source)
    local station, dist = ClosestStation(source)

    if not xPlayer or not station or dist > STATION_RANGE or not CanUseStation(xPlayer, station) then
        return { title = "FABRICATION ILLEGALE", slots = {} }
    end

    local slots = {}
    local list = Crafting.recipes[station.id] or {}
    for i = 1, #list do
        slots[#slots + 1] = RecipeSlot(xPlayer, list[i])
    end

    return { title = station.name or "FABRICATION ILLEGALE", slots = slots }
end)

IL.RegisterCallback("illegalCrafting:prepareCraft", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer then
        return { success = false, message = "Joueur introuvable", craftTime = 0, stationId = 0, itemLabel = "" }
    end
    if not IL.IsTable(data) then
        return { success = false, message = "Cette demande n'a pas pu être traitée", craftTime = 0, stationId = 0, itemLabel = "" }
    end

    local itemId = IL.Str(data.itemId, nil)
    local quantity = IL.Int(data.quantity, 1)
    if not itemId or quantity <= 0 or quantity > 50 then
        return { success = false, message = "Cette demande n'a pas pu être traitée", craftTime = 0, stationId = 0, itemLabel = "" }
    end

    local station, dist = ClosestStation(source)
    if not station or dist > STATION_RANGE then
        return { success = false, message = "Aucune station a proximite", craftTime = 0, stationId = 0, itemLabel = "" }
    end
    if not CanUseStation(xPlayer, station) then
        return { success = false, message = "Acces refuse", craftTime = 0, stationId = station.id, itemLabel = "" }
    end

    local recipe = nil
    local list = Crafting.recipes[station.id] or {}
    for i = 1, #list do
        if list[i].recipe_name == itemId then
            recipe = list[i]
            break
        end
    end
    if not recipe then
        return { success = false, message = "Recette introuvable", craftTime = 0, stationId = station.id, itemLabel = "" }
    end

    local ok, missing = HasIngredients(xPlayer, recipe, quantity)
    if not ok then
        return {
            success = false,
            message = ("Il vous manque : %s"):format(IL.ItemLabel(missing)),
            craftTime = 0,
            stationId = station.id,
            itemLabel = recipe.label,
        }
    end

    Crafting.orders[source] = {
        stationId = station.id,
        recipe = recipe,
        recipeName = recipe.recipe_name,
        remaining = quantity,
        startedAt = IL.Now(),
    }

    return {
        success = true,
        message = "",
        craftTime = math.max(1, math.floor(recipe.craft_time / 1000)),
        stationId = station.id,
        itemLabel = recipe.label,
    }
end)

RegisterNetEvent("illegalBuilder:requestSync", function()
    local source = source
    TriggerClientEvent("illegalBuilder:syncCraftStations", source, StationsMap())
    TriggerEvent("illegal:internal:syncHarvestSpots", source)
    TriggerEvent("illegal:internal:syncTransformSpots", source)
end)

IL.RegisterCallback("illegalBuilder:getCraftStations", function(source, maybeCallback)
    local stations = StationsMap()
    if type(maybeCallback) == "function" then
        local ok, err = pcall(maybeCallback, stations)
        if not ok then
            console.warn(("[illegal] getCraftStations callback error: %s"):format(tostring(err)))
        end
    end
    return stations
end)

IL.RegisterCallback("illegalBuilder:getStationRecipes", function(source, stationId)
    local id = IL.Int(stationId, nil)
    if not id then return {} end
    return Crafting.recipes[id] or {}
end)

IL.RegisterCallback("illegalBuilder:getStationRecipesForNUI", function(source, stationId)
    local xPlayer = IL.Player(source)
    local id = IL.Int(stationId, nil)
    if not id then return {} end

    local out = {}
    local list = Crafting.recipes[id] or {}
    for i = 1, #list do
        out[#out + 1] = RecipeSlot(xPlayer, list[i])
    end
    return out
end)

IL.RegisterCallback("illegalBuilder:getStationQueue", function(source, stationId)
    local id = IL.Int(stationId, nil)
    if not id then return {} end

    Crafting.viewers[id] = Crafting.viewers[id] or {}
    Crafting.viewers[id][source] = true

    return QueuePayload(id)
end)

IL.RegisterCallback("illegalBuilder:getRecipeIdByName", function(source, recipeName)
    if type(recipeName) ~= "string" then return nil end
    for id, recipe in pairs(Crafting.recipesById) do
        if recipe.recipe_name == recipeName then
            return id
        end
    end
    return nil
end)

RegisterNetEvent("illegalBuilder:unregisterQueueViewer", function(stationId)
    local source = source
    local id = IL.Int(stationId, nil)
    if not id then return end
    if Crafting.viewers[id] then
        Crafting.viewers[id][source] = nil
    end
end)

IL.RegisterCallback("illegalBuilder:startQueueCraft", function(source, stationId, recipeDbId, quantity)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false end

    local id = IL.Int(stationId, nil)
    local recipeId = IL.Int(recipeDbId, nil)
    quantity = IL.Int(quantity, 1)
    if not id or not recipeId or quantity <= 0 or quantity > 50 then return false end

    local station = Crafting.stations[id]
    local recipe = Crafting.recipesById[recipeId]
    if not station or not recipe or recipe.station_id ~= id then return false end
    if not CanUseStation(xPlayer, station) then return false end

    Crafting.queues[id] = Crafting.queues[id] or {}
    local queue = Crafting.queues[id]

    for i = 1, #queue do
        if queue[i].source == source then
            return false
        end
    end

    local queueDbId = IL.Insert([[
        INSERT INTO illegal_craft_queue (station_id, recipe_id, identifier, player_name, quantity, status)
        VALUES (?, ?, ?, ?, ?, 'queued')
    ]], { id, recipeId, xPlayer.identifier, xPlayer.name, quantity })

    queue[#queue + 1] = {
        id = queueDbId or (#queue + 1),
        source = source,
        identifier = xPlayer.identifier,
        playerName = xPlayer.name,
        recipeDbId = recipeId,
        recipeName = recipe.recipe_name,
        itemLabel = recipe.label,
        quantity = quantity,
        status = "queued",
    }

    Crafting.viewers[id] = Crafting.viewers[id] or {}
    Crafting.viewers[id][source] = true

    PushQueue(id)
    AdvanceQueue(id)
    return true
end)

IL.RegisterCallback("illegalBuilder:prepareDynamicCraft", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, craftTime = 5000, totalCycles = 1 } end
    if not IL.IsTable(data) then return { success = false, craftTime = 5000, totalCycles = 1 } end

    local stationId = IL.Int(data.stationId, nil)
    local recipeId = IL.Int(data.recipeId, nil)
    local quantity = IL.Int(data.quantity, 1)
    if not stationId or not recipeId or quantity <= 0 or quantity > 50 then
        return { success = false, craftTime = 5000, totalCycles = 1 }
    end

    local station = Crafting.stations[stationId]
    local recipe = Crafting.recipesById[recipeId]
    if not station or not recipe or recipe.station_id ~= stationId then
        return { success = false, craftTime = 5000, totalCycles = 1 }
    end
    if not CanUseStation(xPlayer, station) then
        return { success = false, craftTime = 5000, totalCycles = 1 }
    end
    if IL.DistanceTo(source, station.coords_x, station.coords_y, station.coords_z) > STATION_RANGE then
        return { success = false, craftTime = 5000, totalCycles = 1 }
    end

    local ok = HasIngredients(xPlayer, recipe, quantity)
    if not ok then
        FinishQueueEntry(stationId)
        return { success = false, craftTime = 5000, totalCycles = 1 }
    end

    Crafting.dynamicOrders[source] = {
        stationId = stationId,
        recipe = recipe,
        remaining = quantity,
        startedAt = IL.Now(),
    }

    return {
        success = true,
        craftTime = math.max(500, recipe.craft_time),
        totalCycles = quantity,
    }
end)

RegisterNetEvent("illegalBuilder:completeDynamicCraftCycle", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local order = Crafting.dynamicOrders[source]
    if not order or order.remaining <= 0 then return end

    local station = Crafting.stations[order.stationId]
    if station and IL.DistanceTo(source, station.coords_x, station.coords_y, station.coords_z) > STATION_RANGE then
        Crafting.dynamicOrders[source] = nil
        FinishQueueEntry(order.stationId)
        return
    end

    if not ConsumeIngredients(xPlayer, order.recipe, 1) then
        Crafting.dynamicOrders[source] = nil
        FinishQueueEntry(order.stationId)
        return
    end

    order.remaining = order.remaining - 1
    IL.GiveItem(xPlayer, order.recipe.output_item, order.recipe.output_quantity, true)

    if order.remaining <= 0 then
        Crafting.dynamicOrders[source] = nil
        FinishQueueEntry(order.stationId)
    end
end)

RegisterNetEvent("illegalBuilder:cancelDynamicCraft", function()
    local source = source
    local order = Crafting.dynamicOrders[source]
    if not order then return end
    Crafting.dynamicOrders[source] = nil
    FinishQueueEntry(order.stationId)
end)

AddEventHandler("illegal:internal:reloadCraft", function()
    LoadStations()
    LoadRecipes()
    TriggerClientEvent("illegalBuilder:refreshCraftStations", -1, StationsMap())
end)

RegisterNetEvent("illegalBuilder:reloadCraft", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    LoadStations()
    LoadRecipes()
    TriggerClientEvent("illegalBuilder:refreshCraftStations", -1, StationsMap())
end)
