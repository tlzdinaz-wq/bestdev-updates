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

--- Quantité d'un item comptée comme le fait la fabrication (haveItem / removeInventoryItem lisent la même entrée),
--- pour que la fenêtre n'annonce jamais un craft possible que le serveur refuserait.
local function ItemTotal(xPlayer, name)
    local item = xPlayer and xPlayer.getInventoryItem and xPlayer.getInventoryItem(name)
    return item and tonumber(item.count) or 0
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

local function ItemImage(name)
    return VFW.ItemImageUrl and VFW.ItemImageUrl(name, VFW.Items and VFW.Items[name]) or nil
end

local function RecipeSlot(xPlayer, recipe)
    local ingredients, requirements = {}, {}
    local maxCraftable = 99
    local list = IngredientList(recipe)
    for i = 1, #list do
        local name, count = list[i].item, list[i].count
        local owned = ItemTotal(xPlayer, name)
        local label = IL.ItemLabel(name)
        ingredients[#ingredients + 1] = {
            name = name,
            label = label,
            count = count,
            quantity = count,
            has = owned >= count,
        }
        -- format lu par la fenêtre de craft (« Composants requis »)
        requirements[#requirements + 1] = {
            id = name,
            name = label,
            icon = ItemImage(name),
            amount = count,
            playerHas = owned,
            hasEnough = owned >= count,
        }
        maxCraftable = math.min(maxCraftable, owned // count)
    end
    return {
        id = recipe.recipe_name,
        recipeDbId = recipe.id,
        itemId = recipe.recipe_name,
        itemName = recipe.output_item,
        name = recipe.output_item,
        label = recipe.label,
        quantity = recipe.output_quantity,
        -- la fenêtre affiche craftTime en secondes ; la durée réelle vient du serveur au lancement du craft
        craftTime = math.max(1, math.floor((tonumber(recipe.craft_time) or 5000) / 1000)),
        time = recipe.craft_time,
        slot = recipe.slot_index,
        ingredients = ingredients,
        requirements = requirements,
        maxCraftable = maxCraftable,
        preview = ItemImage(recipe.output_item),
        image = ItemImage(recipe.output_item),
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

-- File de fabrication des tables du builder (onglet « File d'attente » de la fenêtre) : les ingrédients sont pris au
-- lancement, les objets se fabriquent un par un même si le joueur s'éloigne, il les récupère à la table
-- (« Récupérer ») ou annule (objets finis rendus, ingrédients des objets pas encore faits remboursés). Tout est gardé
-- en base (illegal_craft_queue) : un redémarrage ne fait rien perdre.
local QUEUE_ACTIVE <const> = "active"
local MAX_ENTRIES_PER_STATION <const> = 3

local QUEUE_COLUMNS <const> = {
    { column = "started_at", definition = "BIGINT NOT NULL DEFAULT 0" },
    { column = "unit_time", definition = "INT NOT NULL DEFAULT 5" },
    { column = "collected", definition = "INT NOT NULL DEFAULT 0" },
    { column = "output_item", definition = "VARCHAR(64) NULL" },
    { column = "output_quantity", definition = "INT NOT NULL DEFAULT 1" },
    { column = "label", definition = "VARCHAR(100) NULL" },
    { column = "ingredients", definition = "LONGTEXT NULL" },
}

-- `ADD COLUMN IF NOT EXISTS` n'existe pas sur MySQL : on regarde le schéma avant
local function EnsureQueueColumns()
    for i = 1, #QUEUE_COLUMNS do
        local entry = QUEUE_COLUMNS[i]
        local exists = IL.Scalar([[
            SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'illegal_craft_queue' AND COLUMN_NAME = ?
        ]], { entry.column })
        if (tonumber(exists) or 0) == 0 then
            IL.Execute(("ALTER TABLE illegal_craft_queue ADD COLUMN `%s` %s"):format(entry.column, entry.definition))
        end
    end
end

local function QueueEntry(row)
    return {
        id = row.id,
        stationId = row.station_id,
        playerName = row.player_name,
        total = math.max(1, IL.Int(row.quantity, 1)),
        startedAt = IL.Int(row.started_at, 0),
        unitTime = math.max(1, IL.Int(row.unit_time, 5)),
        collected = IL.Int(row.collected, 0),
        output = row.output_item,
        outputQty = math.max(1, IL.Int(row.output_quantity, 1)),
        label = row.label or IL.ItemLabel(row.output_item),
        ingredients = IL.Decode(row.ingredients, {}),
    }
end

local function Completed(entry, now)
    local elapsed = math.max(0, (now or IL.Now()) - entry.startedAt)
    return math.min(entry.total, elapsed // entry.unitTime)
end

local function PlayerEntries(identifier, stationId)
    local rows = IL.Query(
        "SELECT * FROM illegal_craft_queue WHERE identifier = ? AND station_id = ? AND status = ? ORDER BY id",
        { identifier, stationId, QUEUE_ACTIVE }
    )
    local out = {}
    for i = 1, #rows do out[i] = QueueEntry(rows[i]) end
    return out
end

local function OwnEntry(xPlayer, queueId)
    local row = IL.Single(
        "SELECT * FROM illegal_craft_queue WHERE id = ? AND identifier = ? AND status = ?",
        { queueId, xPlayer.identifier, QUEUE_ACTIVE }
    )
    return row and QueueEntry(row) or nil
end

--- Format lu par l'onglet « File d'attente » (progression calculée par la fenêtre à partir de startedAt)
local function QueuePayload(xPlayer, stationId)
    local out = {}
    if not xPlayer then return out end
    local now = IL.Now()
    local entries = PlayerEntries(xPlayer.identifier, stationId)
    for i = 1, #entries do
        local entry = entries[i]
        out[#out + 1] = {
            id = entry.id,
            position = i,
            playerName = entry.playerName,
            recipeLabel = entry.label,
            itemLabel = entry.label,
            recipePreview = ItemImage(entry.output),
            startedAt = entry.startedAt,
            craftTimePerUnit = entry.unitTime,
            totalQuantity = entry.total,
            collectedQuantity = entry.collected,
            quantity = entry.total,
            status = Completed(entry, now) >= entry.total and "done" or "running",
            serverTime = now,
        }
    end
    return out
end

local function PushQueue(source, stationId)
    TriggerClientEvent("illegalCrafting:queueUpdated", source, stationId, QueuePayload(IL.Player(source), stationId))
end

local function NearStation(source, station)
    if IL.DistanceTo(source, station.coords_x, station.coords_y, station.coords_z) <= STATION_RANGE then return true end
    local mx, my, mz = tonumber(station.marker_x), tonumber(station.marker_y), tonumber(station.marker_z)
    return mx ~= nil and my ~= nil and mz ~= nil and IL.DistanceTo(source, mx, my, mz) <= STATION_RANGE
end

--- Rend des objets au joueur même au-delà de son poids max (ce sont ses ingrédients ou des objets déjà payés)
local function ForceGive(xPlayer, name, count)
    if count <= 0 or not IL.ItemExists(name) then return false end
    return xPlayer.addInventoryItem(name, count, nil, false) ~= false
end

local function RefundIngredients(xPlayer, ingredients, units)
    if units <= 0 or not IL.IsTable(ingredients) then return end
    for i = 1, #ingredients do
        local entry = ingredients[i]
        local name = IL.IsTable(entry) and IL.Str(entry.item or entry.name, nil)
        local count = IL.IsTable(entry) and IL.Int(entry.count or entry.amount, 1) or 0
        if name and count > 0 then ForceGive(xPlayer, name, count * units) end
    end
end

-- une seule action à la fois par fabrication (deux clics rapides sur « Récupérer » ne donnent pas deux fois)
local queueBusy = {}

IL.OnReady(function()
    LoadStations()
    LoadRecipes()
    EnsureQueueColumns()
    -- anciennes entrées (fabrication à barre de progression) : jamais reprises
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

    return QueuePayload(IL.Player(source), id)
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
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local id = IL.Int(stationId, nil)
    local recipeId = IL.Int(recipeDbId, nil)
    quantity = IL.Int(quantity, 1)
    if not id or not recipeId or quantity <= 0 or quantity > 50 then
        return { success = false, message = "Quantité invalide." }
    end

    local station = Crafting.stations[id]
    local recipe = Crafting.recipesById[recipeId]
    if not station or not recipe or recipe.station_id ~= id then
        return { success = false, message = "Recette introuvable sur cette table." }
    end
    if not CanUseStation(xPlayer, station) then return { success = false, message = "Accès refusé." } end
    if not NearStation(source, station) then return { success = false, message = "Vous êtes trop loin de la table." } end
    if not IL.ItemExists(recipe.output_item) then
        return { success = false, message = ("L'objet « %s » n'existe pas : recette à corriger."):format(tostring(recipe.output_item)) }
    end
    if #PlayerEntries(xPlayer.identifier, id) >= MAX_ENTRIES_PER_STATION then
        return { success = false, message = ("Déjà %d fabrications en cours ici : récupérez-les d'abord."):format(MAX_ENTRIES_PER_STATION) }
    end

    local ok, missing = HasIngredients(xPlayer, recipe, quantity)
    if not ok then return { success = false, message = ("Il vous manque : %s."):format(IL.ItemLabel(missing)) } end
    if not ConsumeIngredients(xPlayer, recipe, quantity) then
        return { success = false, message = "Composants manquants." }
    end

    local ingredients = IngredientList(recipe)
    local unitTime = math.max(1, math.floor((tonumber(recipe.craft_time) or 5000) / 1000 + 0.5))
    local queueId = IL.Insert([[
        INSERT INTO illegal_craft_queue
            (station_id, recipe_id, identifier, player_name, quantity, status, started_at, unit_time, collected,
             output_item, output_quantity, label, ingredients)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)
    ]], {
        id, recipeId, xPlayer.identifier, xPlayer.name, quantity, QUEUE_ACTIVE, IL.Now(), unitTime,
        recipe.output_item, recipe.output_quantity, recipe.label, IL.Encode(ingredients),
    })
    if not queueId then
        RefundIngredients(xPlayer, ingredients, quantity)
        return { success = false, message = "Fabrication impossible, composants rendus." }
    end

    Crafting.viewers[id] = Crafting.viewers[id] or {}
    Crafting.viewers[id][source] = true
    PushQueue(source, id)
    return { success = true, label = recipe.label, quantity = quantity }
end)

IL.RegisterCallback("illegalBuilder:collectQueueCraft", function(source, queueId)
    local xPlayer = IL.Player(source)
    local id = IL.Int(queueId, nil)
    if not xPlayer or not id then return { success = false, error = "Fabrication introuvable." } end
    if queueBusy[id] then return { success = false, error = "Patientez…" } end
    queueBusy[id] = true

    local result
    local entry = OwnEntry(xPlayer, id)
    local station = entry and Crafting.stations[entry.stationId]
    if not entry then
        result = { success = false, error = "Fabrication introuvable." }
    elseif station and not NearStation(source, station) then
        result = { success = false, error = "Revenez à la table pour récupérer vos objets." }
    elseif not IL.ItemExists(entry.output) then
        result = { success = false, error = "Objet inconnu : annulez pour récupérer vos composants." }
    else
        local available = Completed(entry) - entry.collected
        local given = 0
        for _ = 1, available do
            if not IL.GiveItem(xPlayer, entry.output, entry.outputQty, false) then break end
            given = given + 1
        end
        if available <= 0 then
            result = { success = false, error = "Rien à récupérer pour le moment." }
        elseif given == 0 then
            result = { success = false, error = "Inventaire plein." }
        else
            entry.collected = entry.collected + given
            local status = entry.collected >= entry.total and "done" or QUEUE_ACTIVE
            IL.Execute("UPDATE illegal_craft_queue SET collected = ?, status = ? WHERE id = ?", { entry.collected, status, id })
            result = {
                success = true, label = entry.label,
                collected = given * entry.outputQty, totalCollected = given * entry.outputQty,
                inventoryFull = given < available,
            }
        end
    end

    queueBusy[id] = nil
    if entry then PushQueue(source, entry.stationId) end
    return result
end)

IL.RegisterCallback("illegalBuilder:cancelQueueCraft", function(source, queueId)
    local xPlayer = IL.Player(source)
    local id = IL.Int(queueId, nil)
    if not xPlayer or not id then return { success = false, error = "Fabrication introuvable." } end
    if queueBusy[id] then return { success = false, error = "Patientez…" } end
    queueBusy[id] = true

    local entry = OwnEntry(xPlayer, id)
    if not entry then
        queueBusy[id] = nil
        return { success = false, error = "Fabrication introuvable." }
    end

    -- marquée annulée avant de rendre quoi que ce soit : un second appel ne la retrouve plus
    IL.Execute("UPDATE illegal_craft_queue SET status = 'cancelled' WHERE id = ?", { id })
    local completed = Completed(entry)
    local finished = math.max(0, completed - entry.collected)
    if finished > 0 then ForceGive(xPlayer, entry.output, finished * entry.outputQty) end
    local refunded = entry.total - completed
    RefundIngredients(xPlayer, entry.ingredients, refunded)

    queueBusy[id] = nil
    PushQueue(source, entry.stationId)
    return {
        success = true, label = entry.label,
        itemsCollected = finished, outputQuantity = entry.outputQty, ingredientsRefunded = refunded,
    }
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
