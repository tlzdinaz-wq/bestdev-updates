local Drug = {
    settings = {},
    prices = {},
    zones = {},
    sessions = {},
    npcs = {},
    npcSeq = 0,
}

local ADMIN_PERM = "builder_drug_dealing"
local DEFAULT_SETTINGS = {
    enabled = true,
    spawnDistanceMin = 60,
    spawnDistanceMax = 250,
    spawnInterval = 45,
    maxNpcPerPlayer = 1,
    refuseChance = 25,
    policeChance = 25,
    saleCooldown = 20,
    sessionCooldown = 0,
    minQuantity = 1,
    maxQuantity = 3,
}

local function LoadSettings()
    Drug.settings = IL.LoadSettings("drugdealing_settings", DEFAULT_SETTINGS)
end

local function LoadPrices()
    Drug.prices = {}
    local rows = IL.Query("SELECT * FROM drugdealing_prices")
    for i = 1, #rows do
        local row = rows[i]
        Drug.prices[row.item_name] = {
            item_name = row.item_name,
            min_price = IL.Int(row.min_price, 100),
            max_price = IL.Int(row.max_price, 200),
        }
    end
end

AddEventHandler("illegal:internal:reloadDrugPrices", function()
    LoadPrices()
end)

local function LoadZones()
    Drug.zones = {}
    local rows = IL.Query("SELECT * FROM drugdealing_zones")
    for i = 1, #rows do
        local row = rows[i]
        Drug.zones[row.zone_name] = {
            id = row.id,
            zone_name = row.zone_name,
            enabled = IL.Bool(row.enabled),
            price_multiplier = IL.Num(row.price_multiplier, 1.0),
            police_chance = IL.Int(row.police_chance, 25),
        }
    end
end

local function Session(source)
    local session = Drug.sessions[source]
    if not session then
        session = {
            enabled = false,
            totalSales = 0,
            totalEarnings = 0,
            lastSale = 0,
            lastSpawn = 0,
            zoneName = "",
            npcIds = {},
        }
        Drug.sessions[source] = session
    end
    return session
end

local function PlayerDrugs(xPlayer)
    local out = {}
    for name, price in pairs(Drug.prices) do
        local item = xPlayer.getInventoryItem(name)
        if item and item.count > 0 then
            out[#out + 1] = { name = name, count = item.count, price = price }
        end
    end
    return out
end

local function DespawnNpc(npcId)
    local npc = Drug.npcs[npcId]
    if not npc then return end
    if npc.entity and DoesEntityExist(npc.entity) then
        DeleteEntity(npc.entity)
    end
    Drug.npcs[npcId] = nil
    TriggerClientEvent("core:drugdealing:despawnNPC", -1, npcId)
end

local function ClearPlayerNpcs(source)
    for npcId, npc in pairs(Drug.npcs) do
        if npc.owner == source then
            DespawnNpc(npcId)
        end
    end
    local session = Drug.sessions[source]
    if session then session.npcIds = {} end
end

IL.OnReady(function()
    LoadSettings()
    LoadPrices()
    LoadZones()
end)

IL.OnPlayerDropped(function(source)
    ClearPlayerNpcs(source)
    Drug.sessions[source] = nil
end)

local function RequestSpawn(source)
    local session = Drug.sessions[source]
    if not session or not session.enabled then return end

    local count = 0
    for _, npc in pairs(Drug.npcs) do
        if npc.owner == source then count = count + 1 end
    end
    if count >= IL.Int(Drug.settings.maxNpcPerPlayer, 1) then return end

    session.lastSpawn = IL.Now()
    TriggerClientEvent("core:drugdealing:findSidewalkSpawn", source,
        IL.Num(Drug.settings.spawnDistanceMin, 60.0),
        IL.Num(Drug.settings.spawnDistanceMax, 250.0))
end

CreateThread(function()
    while true do
        Wait(10000)
        local now = IL.Now()
        local interval = IL.Int(Drug.settings.spawnInterval, 45)
        for source, session in pairs(Drug.sessions) do
            if session.enabled and IL.Player(source) then
                if now - session.lastSpawn >= interval then
                    RequestSpawn(source)
                end
            end
        end
    end
end)

RegisterNetEvent("core:drugdealing:toggleSystem", function(newState, zoneName)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if type(newState) ~= "boolean" then return end
    zoneName = IL.Str(zoneName, "")

    local session = Session(source)

    if not newState then
        session.enabled = false
        ClearPlayerNpcs(source)
        TriggerClientEvent("core:drugdealing:setEnabled", source, false)
        TriggerClientEvent("core:drugdealing:sendNotification", source, {
            type = "ILLEGAL", text = "Vous rangez votre marchandise.",
        })
        return
    end

    if not IL.Bool(Drug.settings.enabled) then
        TriggerClientEvent("core:drugdealing:setEnabled", source, false)
        TriggerClientEvent("core:drugdealing:sendNotification", source, {
            type = "ILLEGAL", text = "La vente de drogue est desactivee.",
        })
        return
    end

    if #PlayerDrugs(xPlayer) == 0 then
        TriggerClientEvent("core:drugdealing:setEnabled", source, false)
        TriggerClientEvent("core:drugdealing:sendNotification", source, {
            type = "ILLEGAL", text = "Vous n'avez rien a vendre.",
        })
        return
    end

    local zone = Drug.zones[zoneName]
    if zone and not zone.enabled then
        TriggerClientEvent("core:drugdealing:setEnabled", source, false)
        TriggerClientEvent("core:drugdealing:sendNotification", source, {
            type = "ILLEGAL", text = "Impossible de vendre dans ce secteur.",
        })
        return
    end

    local cooldown = IL.Int(Drug.settings.sessionCooldown, 0)
    if cooldown > 0 and session.lastSale > 0 and (IL.Now() - session.lastSale) < cooldown then
        TriggerClientEvent("core:drugdealing:setEnabled", source, false)
        TriggerClientEvent("core:drugdealing:sendNotification", source, {
            type = "ILLEGAL", text = "Laissez retomber la pression avant de recommencer.",
        })
        return
    end

    session.enabled = true
    session.zoneName = zoneName
    session.lastSpawn = 0

    TriggerClientEvent("core:drugdealing:setEnabled", source, true)
    TriggerClientEvent("core:drugdealing:sendNotification", source, {
        type = "ILLEGAL", text = "Vous sortez votre marchandise. Restez discret.",
    })

    RequestSpawn(source)
end)

RegisterNetEvent("core:drugdealing:checkZone", function(x, y, z)
    local source = source
    local session = Drug.sessions[source]
    if not session or not session.enabled then return end
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return end
end)

RegisterNetEvent("core:drugdealing:spawnFailed", function(reason)
    local source = source
    if type(reason) ~= "string" then return end
    local session = Drug.sessions[source]
    if not session then return end
    session.lastSpawn = IL.Now()
end)

RegisterNetEvent("core:drugdealing:validateAndSpawn", function(validPositions)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if not IL.IsTable(validPositions) or #validPositions == 0 then return end

    local session = Drug.sessions[source]
    if not session or not session.enabled then return end

    local count = 0
    for _, npc in pairs(Drug.npcs) do
        if npc.owner == source then count = count + 1 end
    end
    if count >= IL.Int(Drug.settings.maxNpcPerPlayer, 1) then return end

    local playerCoords = IL.Coords(source)
    if not playerCoords then return end

    local chosen = nil
    local limit = math.min(#validPositions, 10)
    for i = 1, limit do
        local pos = validPositions[i]
        if IL.IsTable(pos) then
            local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z)
            if x and y and z then
                local dx, dy = playerCoords.x - x, playerCoords.y - y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist >= 30.0 and dist <= 500.0 then
                    chosen = { x = x, y = y, z = z, heading = IL.Num(pos.heading, 0.0) }
                    break
                end
            end
        end
    end
    if not chosen then return end

    local models = (Config and Config.DrugDealing and Config.DrugDealing.NPCModels) or { "a_m_m_soucent_01" }
    local model = models[math.random(1, #models)]

    local ped = CreatePed(4, GetHashKey(model), chosen.x, chosen.y, chosen.z, chosen.heading, true, true)
    local attempts = 0
    while not DoesEntityExist(ped) and attempts < 50 do
        Wait(20)
        attempts = attempts + 1
    end
    if not DoesEntityExist(ped) then return end

    Drug.npcSeq = Drug.npcSeq + 1
    local npcId = ("npc_%d_%d"):format(source, Drug.npcSeq)
    local netId = NetworkGetNetworkIdFromEntity(ped)

    Drug.npcs[npcId] = {
        id = npcId,
        entity = ped,
        netId = netId,
        owner = source,
        createdAt = IL.Now(),
        sold = false,
    }
    session.npcIds[npcId] = true

    TriggerClientEvent("core:drugdealing:spawnNPC", -1, npcId, netId, source)
end)

RegisterNetEvent("core:drugdealing:npcKilled", function(npcId)
    local source = source
    if type(npcId) ~= "string" and type(npcId) ~= "number" then return end
    local npc = Drug.npcs[npcId]
    if not npc then return end
    if npc.owner ~= source then return end
    DespawnNpc(npcId)
end)

RegisterNetEvent("core:drugdealing:startAutoSale", function(npcId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if type(npcId) ~= "string" and type(npcId) ~= "number" then return end

    local npc = Drug.npcs[npcId]
    if not npc or npc.owner ~= source or npc.sold then
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, false)
        return
    end

    local session = Session(source)
    if not session.enabled then
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, false)
        return
    end

    local cooldown = IL.Int(Drug.settings.saleCooldown, 20)
    if cooldown > 0 and session.lastSale > 0 and (IL.Now() - session.lastSale) < cooldown then
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, false)
        return
    end

    local drugs = PlayerDrugs(xPlayer)
    if #drugs == 0 then
        session.enabled = false
        TriggerClientEvent("core:drugdealing:setEnabled", source, false)
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, false)
        return
    end

    local zone = Drug.zones[session.zoneName]
    local refuseChance = IL.Int(Drug.settings.refuseChance, 25)
    if math.random(1, 100) <= refuseChance then
        npc.sold = true
        local policeChance = zone and zone.police_chance or IL.Int(Drug.settings.policeChance, 25)
        local callsPolice = math.random(1, 100) <= policeChance
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, callsPolice)
        if callsPolice then
            local coords = IL.Coords(source)
            if coords then
                IL.AlertPolice("core:drugdealing:policeAlert", { x = coords.x, y = coords.y, z = coords.z })
            end
        end
        return
    end

    local pick = drugs[math.random(1, #drugs)]
    local maxQuantity = math.min(IL.Int(Drug.settings.maxQuantity, 3), pick.count)
    local minQuantity = math.min(IL.Int(Drug.settings.minQuantity, 1), maxQuantity)
    if maxQuantity < 1 then
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, false)
        return
    end
    local quantity = math.random(minQuantity, maxQuantity)

    if not IL.TakeItem(xPlayer, pick.name, quantity) then
        TriggerClientEvent("core:drugdealing:npcRefusedSale", source, npcId, false)
        return
    end

    local unitPrice = math.random(pick.price.min_price, math.max(pick.price.min_price, pick.price.max_price))
    local multiplier = zone and zone.price_multiplier or 1.0

    local territoryId = nil
    local bonusPercent = 0
    if Territories and Territories.GetAtCoords then
        local coords = IL.Coords(source)
        if coords then
            local territory, bonus = Territories.GetAtCoords(coords, xPlayer)
            if territory then
                territoryId = territory.id
                bonusPercent = bonus or 0
            end
        end
    end

    local amount = math.floor(unitPrice * quantity * multiplier * (1 + (bonusPercent / 100)))
    if amount < 1 then amount = 1 end

    npc.sold = true
    session.lastSale = IL.Now()
    session.totalSales = session.totalSales + 1
    session.totalEarnings = session.totalEarnings + amount

    IL.GiveMoney(xPlayer, "black_money", amount, "drug-sale")

    IL.Execute([[
        INSERT INTO drugdealing_sales (identifier, player_name, zone_name, item_name, quantity, amount, territory_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { xPlayer.identifier, xPlayer.name, session.zoneName, pick.name, quantity, amount, territoryId })

    if Territories and Territories.RegisterSale and territoryId then
        pcall(Territories.RegisterSale, territoryId, xPlayer)
    end

    TriggerClientEvent("core:drugdealing:playAutoSaleAnimation", source, npcId)
    TriggerClientEvent("core:drugdealing:saleResult", source, npcId, true, {
        item = pick.name,
        label = IL.ItemLabel(pick.name),
        quantity = quantity,
        amount = amount,
    })
    TriggerClientEvent("core:drugdealing:sendNotification", source, {
        type = "ILLEGAL",
        text = ("Vous avez vendu %dx %s pour %d$ sale."):format(quantity, IL.ItemLabel(pick.name), amount),
    })

    SetTimeout(12000, function()
        if Drug.npcs[npcId] then
            TriggerClientEvent("core:drugdealing:npcLeaving", -1, npcId)
            SetTimeout(20000, function()
                DespawnNpc(npcId)
            end)
        end
    end)
end)

IL.RegisterCallback("core:drugdealing:getSessionData", function(source)
    local session = Session(source)
    local cooldown = IL.Int(Drug.settings.saleCooldown, 20)
    local remaining = 0
    if cooldown > 0 and session.lastSale > 0 then
        remaining = math.max(0, cooldown - (IL.Now() - session.lastSale))
    end
    return {
        enabled = session.enabled,
        totalSales = session.totalSales,
        totalEarnings = session.totalEarnings,
        cooldownRemaining = remaining,
    }
end)

IL.RegisterCallback("core:drugdealing:getAllNPCs", function(source)
    local out = {}
    for npcId, npc in pairs(Drug.npcs) do
        out[npcId] = { netId = npc.netId, owner = npc.owner }
    end
    return out
end)

IL.RegisterCallback("core:drugdealing:admin:hasPermission", function(source)
    local xPlayer = IL.Player(source)
    return xPlayer ~= nil and xPlayer.hasPermission(ADMIN_PERM)
end)

RegisterNetEvent("core:drugdealing:admin:getSettings", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(ADMIN_PERM) then return end

    local prices = {}
    for name, price in pairs(Drug.prices) do
        prices[#prices + 1] = {
            item_name = name,
            label = IL.ItemLabel(name),
            min_price = price.min_price,
            max_price = price.max_price,
        }
    end

    TriggerClientEvent("core:drugdealing:admin:settingsData", source, Drug.settings, prices)
end)

RegisterNetEvent("core:drugdealing:admin:getZones", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(ADMIN_PERM) then return end

    local zones = {}
    for _, zone in pairs(Drug.zones) do
        zones[#zones + 1] = zone
    end

    TriggerClientEvent("core:drugdealing:admin:zonesData", source, zones)
end)

RegisterNetEvent("core:drugdealing:admin:getStatistics", function(period)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(ADMIN_PERM) then return end

    period = IL.Str(period, "today")
    local since = "CURDATE()"
    if period == "week" then
        since = "DATE_SUB(NOW(), INTERVAL 7 DAY)"
    elseif period == "month" then
        since = "DATE_SUB(NOW(), INTERVAL 30 DAY)"
    end

    local stats = IL.Single(([[
        SELECT COUNT(*) AS total_sales, COALESCE(SUM(amount), 0) AS total_amount,
               COALESCE(SUM(quantity), 0) AS total_quantity
        FROM drugdealing_sales WHERE created_at >= %s
    ]]):format(since)) or {}

    local recent = IL.Query([[
        SELECT identifier, player_name, zone_name, item_name, quantity, amount, created_at
        FROM drugdealing_sales ORDER BY id DESC LIMIT 25
    ]])

    TriggerClientEvent("core:drugdealing:admin:statisticsData", source, {
        period = period,
        totalSales = IL.Int(stats.total_sales, 0),
        totalAmount = IL.Int(stats.total_amount, 0),
        totalQuantity = IL.Int(stats.total_quantity, 0),
    }, recent)
end)

RegisterNetEvent("core:drugdealing:admin:updateSetting", function(key, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(ADMIN_PERM) then return end
    if type(key) ~= "string" then return end
    local aliases = {
        system_enabled = "enabled",
        npc_spawn_distance_min = "spawnDistanceMin",
        npc_spawn_distance_max = "spawnDistanceMax",
        sale_cooldown = "saleCooldown",
        police_alert_chance = "policeChance",
    }
    key = aliases[key] or key
    if DEFAULT_SETTINGS[key] == nil then return end

    if type(DEFAULT_SETTINGS[key]) == "boolean" then
        local state = IL.Bool(value)
        IL.SaveSetting("drugdealing_settings", key, state)
        Drug.settings[key] = state
    else
        local number = tonumber(value)
        if not number then return end
        IL.SaveSetting("drugdealing_settings", key, number)
        Drug.settings[key] = number
    end
end)

RegisterNetEvent("core:drugdealing:admin:reload", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(ADMIN_PERM) then return end
    LoadSettings()
    LoadPrices()
    LoadZones()
end)

local function staffOk(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(ADMIN_PERM)
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { success = false, ok = false, error = message or "Action impossible." }
end

local function ItemsCatalog()
    local out = {}
    for name, def in pairs(VFW.Items or {}) do
        if type(name) == "string" and name ~= "" then
            out[#out + 1] = {
                name = name,
                label = (type(def) == "table" and (def.label or name)) or name,
            }
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function ZoneRows()
    local rows = IL.Query("SELECT * FROM drugdealing_zones ORDER BY zone_name")
    for i = 1, #rows do
        rows[i].enabled = IL.Bool(rows[i].enabled)
    end
    return rows
end

local function PriceRows()
    local rows = IL.Query("SELECT * FROM drugdealing_prices ORDER BY item_name")
    for i = 1, #rows do
        rows[i].label = IL.ItemLabel(rows[i].item_name)
    end
    return rows
end

local function StatsPayload(period)
    period = IL.Str(period, "today")
    local since = "CURDATE()"
    if period == "week" then
        since = "DATE_SUB(NOW(), INTERVAL 7 DAY)"
    elseif period == "month" then
        since = "DATE_SUB(NOW(), INTERVAL 30 DAY)"
    end
    local stats = IL.Single(([[
        SELECT COUNT(*) AS total_sales, COALESCE(SUM(amount), 0) AS total_amount,
               COALESCE(SUM(quantity), 0) AS total_quantity
        FROM drugdealing_sales WHERE created_at >= %s
    ]]):format(since)) or {}
    local recent = IL.Query([[
        SELECT identifier, player_name, zone_name, item_name, quantity, amount, created_at
        FROM drugdealing_sales ORDER BY id DESC LIMIT 25
    ]])
    for i = 1, #recent do
        recent[i].label = IL.ItemLabel(recent[i].item_name)
    end
    return {
        period = period,
        totalSales = IL.Int(stats.total_sales, 0),
        totalAmount = IL.Int(stats.total_amount, 0),
        totalQuantity = IL.Int(stats.total_quantity, 0),
        recent = recent,
    }
end

local function HubPanel(period)
    return {
        ok = true,
        success = true,
        settings = {
            enabled = IL.Bool(Drug.settings.enabled),
            spawnDistanceMin = IL.Num(Drug.settings.spawnDistanceMin, 60),
            spawnDistanceMax = IL.Num(Drug.settings.spawnDistanceMax, 250),
            spawnInterval = IL.Int(Drug.settings.spawnInterval, 45),
            maxNpcPerPlayer = IL.Int(Drug.settings.maxNpcPerPlayer, 1),
            refuseChance = IL.Int(Drug.settings.refuseChance, 25),
            policeChance = IL.Int(Drug.settings.policeChance, 25),
            saleCooldown = IL.Int(Drug.settings.saleCooldown, 20),
            sessionCooldown = IL.Int(Drug.settings.sessionCooldown, 0),
            minQuantity = IL.Int(Drug.settings.minQuantity, 1),
            maxQuantity = IL.Int(Drug.settings.maxQuantity, 3),
        },
        zones = ZoneRows(),
        prices = PriceRows(),
        catalog = ItemsCatalog(),
        stats = StatsPayload(period),
    }
end

local function SaveSettings(data)
    if type(data) ~= "table" then return false end
    for key, default in pairs(DEFAULT_SETTINGS) do
        local value = data[key]
        if value ~= nil then
            if type(default) == "boolean" then
                local state = IL.Bool(value)
                IL.SaveSetting("drugdealing_settings", key, state)
                Drug.settings[key] = state
            else
                local number = tonumber(value)
                if number then
                    if key == "refuseChance" or key == "policeChance" then
                        number = math.max(0, math.min(100, number))
                    elseif key == "minQuantity" or key == "maxQuantity" or key == "maxNpcPerPlayer" then
                        number = math.max(1, math.floor(number))
                    elseif key == "spawnDistanceMin" or key == "spawnDistanceMax" or key == "spawnInterval" or key == "saleCooldown" or key == "sessionCooldown" then
                        number = math.max(0, number)
                    end
                    IL.SaveSetting("drugdealing_settings", key, number)
                    Drug.settings[key] = number
                end
            end
        end
    end
    return true
end

local function UpsertZone(data)
    local name = IL.Str(data.zone_name or data.name or data.zoneName, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", ""):upper()
    if name == "" then return nil, "Nom de zone GTA obligatoire." end
    local enabled = data.enabled
    if enabled == nil then enabled = true end
    local multiplier = IL.Num(data.price_multiplier or data.priceMultiplier, 1.0)
    if multiplier <= 0 then multiplier = 1.0 end
    local police = math.max(0, math.min(100, IL.Int(data.police_chance or data.policeChance, IL.Int(Drug.settings.policeChance, 25))))
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE drugdealing_zones SET zone_name = ?, enabled = ?, price_multiplier = ?, police_chance = ? WHERE id = ?
        ]], { name:sub(1, 100), IL.Bool(enabled) and 1 or 0, multiplier, police, id })
        LoadZones()
        return id
    end
    IL.Execute([[
        INSERT INTO drugdealing_zones (zone_name, enabled, price_multiplier, police_chance)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE enabled = VALUES(enabled), price_multiplier = VALUES(price_multiplier),
            police_chance = VALUES(police_chance)
    ]], { name:sub(1, 100), IL.Bool(enabled) and 1 or 0, multiplier, police })
    LoadZones()
    local row = IL.Single("SELECT id FROM drugdealing_zones WHERE zone_name = ?", { name })
    return row and row.id or true
end

local function UpsertPrice(data)
    local name = IL.Str(data.item_name or data.itemName or data.name, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil, "Item obligatoire." end
    local minP = math.max(0, IL.Int(data.min_price or data.minPrice or data.dealPriceMin, 0))
    local maxP = math.max(minP, IL.Int(data.max_price or data.maxPrice or data.dealPriceMax, minP))
    IL.Execute([[
        INSERT INTO drugdealing_prices (item_name, min_price, max_price)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE min_price = VALUES(min_price), max_price = VALUES(max_price)
    ]], { name:sub(1, 64), minP, maxP })
    LoadPrices()
    return true
end

RegisterNetEvent("core:drugdealing:admin:createZone", function(data)
    local source = source
    if not staffOk(source) then return end
    UpsertZone(data or {})
end)

RegisterNetEvent("core:drugdealing:admin:updateZone", function(zoneId, field, value)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(zoneId, nil)
    if not id then return end
    local row = IL.Single("SELECT * FROM drugdealing_zones WHERE id = ?", { id })
    if not row then return end
    local payload = {
        id = id,
        zone_name = row.zone_name,
        enabled = IL.Bool(row.enabled),
        price_multiplier = row.price_multiplier,
        police_chance = row.police_chance,
    }
    if field == "name" or field == "zone_name" then payload.zone_name = value
    elseif field == "active" or field == "enabled" then payload.enabled = value
    elseif field == "price_multiplier" then payload.price_multiplier = value
    elseif field == "police_chance" then payload.police_chance = value
    elseif IL.IsTable(field) then
        payload = field
        payload.id = id
    end
    UpsertZone(payload)
end)

RegisterNetEvent("core:drugdealing:admin:deleteZone", function(zoneId)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(zoneId, nil)
    if not id then return end
    IL.Execute("DELETE FROM drugdealing_zones WHERE id = ?", { id })
    LoadZones()
end)

RegisterNetEvent("core:drugdealing:admin:updateDrugPrice", function(itemName, data)
    local source = source
    if not staffOk(source) then return end
    local payload = IL.IsTable(data) and data or {}
    payload.item_name = itemName or payload.item_name
    UpsertPrice(payload)
end)

IL.RegisterCallback("core:drugdealing:admin:getSettingsSync", function(source)
    if not staffOk(source) then return {} end
    local prices = {}
    for name, price in pairs(Drug.prices) do
        prices[#prices + 1] = {
            item_name = name,
            label = IL.ItemLabel(name),
            min_price = price.min_price,
            max_price = price.max_price,
        }
    end
    return { settings = Drug.settings, prices = prices }
end)

IL.RegisterCallback("core:drugdealing:admin:getStatisticsSync", function(source, period)
    if not staffOk(source) then return {} end
    return StatsPayload(period)
end)

IL.RegisterCallback("gestionDrugDealing:hubPanel", function(source, period)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer la vente de drogue." }
    end
    LoadSettings()
    LoadPrices()
    LoadZones()
    return HubPanel(period)
end)

IL.RegisterCallback("gestionDrugDealing:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = tostring(data.action or "")
    local err

    if action == "settings:save" then
        SaveSettings(data)
    elseif action == "zone:save" then
        local id
        id, err = UpsertZone(data)
        if not id then return fail(err) end
    elseif action == "zone:delete" then
        local id = IL.Int(data.id, nil)
        if not id then return fail("Zone introuvable.") end
        IL.Execute("DELETE FROM drugdealing_zones WHERE id = ?", { id })
        LoadZones()
    elseif action == "price:save" then
        local ok
        ok, err = UpsertPrice(data)
        if not ok then return fail(err) end
    elseif action == "price:delete" then
        local name = IL.Str(data.item_name or data.name, "")
        local id = IL.Int(data.id, nil)
        if id then
            IL.Execute("DELETE FROM drugdealing_prices WHERE id = ?", { id })
        elseif name ~= "" then
            IL.Execute("DELETE FROM drugdealing_prices WHERE item_name = ?", { name })
        else
            return fail("Prix introuvable.")
        end
        LoadPrices()
    else
        return fail("Action inconnue.")
    end

    local panel = HubPanel(data.period)
    panel.success = true
    return panel
end)
