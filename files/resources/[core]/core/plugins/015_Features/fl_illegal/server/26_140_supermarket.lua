local Supermarket = {
    stores = {},
    items = {},
    apuRobbing = {},
    safeRobbing = {},
    apuWindow = {},
    settings = {},
}

local BUILDER_PERM = "builder_supermarket"
local DEFAULT_SETTINGS = {
    apuCooldown = 1800,
    safeCooldown = 3600,
    safeWindow = 300,
    minPolice = 0,
    apuRewardMin = 800,
    apuRewardMax = 1600,
    safeRewardMin = 3000,
    safeRewardMax = 6000,
}

local function LoadSettings()
    IL.EnsureSettingsTable("supermarket_settings")
    Supermarket.settings = IL.LoadSettings("supermarket_settings", DEFAULT_SETTINGS)
end

local function Setting(key)
    return IL.Num(Supermarket.settings[key], DEFAULT_SETTINGS[key])
end

local function LoadStores()
    Supermarket.stores = {}
    local rows = IL.Query("SELECT * FROM supermarkets")
    for i = 1, #rows do
        local row = rows[i]
        Supermarket.stores[row.id] = {
            id = row.id,
            name = row.name or "Superette",
            pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0) },
            apuPos = { x = IL.Num(row.apu_x, 0.0), y = IL.Num(row.apu_y, 0.0), z = IL.Num(row.apu_z, 0.0), h = IL.Num(row.apu_h, 0.0) },
            safePos = { x = IL.Num(row.safe_x, 0.0), y = IL.Num(row.safe_y, 0.0), z = IL.Num(row.safe_z, 0.0), h = IL.Num(row.safe_h, 0.0) },
            storeType = row.store_type or "automatic",
            zoneRadius = IL.Num(row.zone_radius, 3.0),
            active = IL.Bool(row.active),
            blipEnabled = IL.Bool(row.blip_enabled),
            canRob = IL.Bool(row.can_rob),
            apuLastRobbed = IL.Int(row.apu_last_robbed, 0),
            safeLastRobbed = IL.Int(row.safe_last_robbed, 0),
        }
    end
end

local function LoadItems()
    Supermarket.items = {}
    local rows = IL.Query("SELECT * FROM supermarket_items WHERE enabled = 1 ORDER BY category, name")
    for i = 1, #rows do
        local row = rows[i]
        Supermarket.items[#Supermarket.items + 1] = {
            name = row.name,
            label = row.label or IL.ItemLabel(row.name),
            price = IL.Int(row.price, 0),
            category = row.category or "divers",
        }
    end
end

local function StoresMap()
    local out = {}
    for id, store in pairs(Supermarket.stores) do
        out[id] = {
            pos = store.pos,
            apuPos = store.apuPos,
            safePos = store.safePos,
            active = store.active,
            blipEnabled = store.blipEnabled,
            canRob = store.canRob,
            storeType = store.storeType,
            zoneRadius = store.zoneRadius,
            name = store.name,
        }
    end
    return out
end

local function FindItem(name)
    for i = 1, #Supermarket.items do
        if Supermarket.items[i].name == name then return Supermarket.items[i] end
    end
    return nil
end

local function ApuTimeLeft(storeId)
    local window = Supermarket.apuWindow[storeId]
    if not window then return 0 end
    return math.max(0, window - IL.Now())
end

local function Purchase(source, purchaseData, total, paymentMethod)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end
    if not IL.IsTable(purchaseData) or #purchaseData == 0 then
        return { success = false, message = "Panier vide" }
    end

    paymentMethod = IL.Str(paymentMethod, "cash")
    local account = paymentMethod == "bank" and "bank" or "money"

    local realTotal = 0
    local lines = {}
    for i = 1, #purchaseData do
        local entry = purchaseData[i]
        if not IL.IsTable(entry) then return { success = false, message = "Votre panier n'est pas valide" } end
        local name = IL.Str(entry.name or entry.itemName, nil)
        local quantity = IL.Int(entry.quantity, 0)
        if not name or quantity <= 0 or quantity > 500 then
            return { success = false, message = "Votre panier n'est pas valide" }
        end
        local def = FindItem(name)
        if not def then return { success = false, message = "Article indisponible" } end
        realTotal = realTotal + (def.price * quantity)
        lines[#lines + 1] = { name = name, quantity = quantity }
    end

    if realTotal <= 0 then return { success = false, message = "Votre panier n'est pas valide" } end

    for i = 1, #lines do
        if not xPlayer.canCarryItem(lines[i].name, lines[i].quantity) then
            return { success = false, message = "Votre inventaire est plein" }
        end
    end

    if not IL.TakeMoney(xPlayer, account, realTotal, "supermarket") then
        return { success = false, message = "Fonds insuffisants" }
    end

    for i = 1, #lines do
        IL.GiveItem(xPlayer, lines[i].name, lines[i].quantity, false)
    end

    return { success = true }
end

IL.OnReady(function()
    LoadSettings()
    LoadStores()
    LoadItems()
    TriggerClientEvent("core:supermarket:syncSupermarkets", -1, StoresMap())
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:supermarket:receiveSupermarketsList", source, StoresMap())
end)

IL.OnPlayerDropped(function(source)
    for id, holder in pairs(Supermarket.apuRobbing) do
        if holder.source == source then
            Supermarket.apuRobbing[id] = nil
            TriggerClientEvent("core:supermarket:syncAPURobberyState", -1, id, false, 0)
        end
    end
    for id, holder in pairs(Supermarket.safeRobbing) do
        if holder.source == source then
            Supermarket.safeRobbing[id] = nil
            TriggerClientEvent("core:supermarket:syncSafeRobberyState", -1, id, false, 0)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(10000)
        local now = IL.Now()
        for id, holder in pairs(Supermarket.apuRobbing) do
            if now - holder.startedAt > 180 then
                Supermarket.apuRobbing[id] = nil
                TriggerClientEvent("core:supermarket:syncAPURobberyState", -1, id, false, 0)
            end
        end
        for id, holder in pairs(Supermarket.safeRobbing) do
            if now - holder.startedAt > 300 then
                Supermarket.safeRobbing[id] = nil
                TriggerClientEvent("core:supermarket:syncSafeRobberyState", -1, id, false, 0)
            end
        end
        for id, window in pairs(Supermarket.apuWindow) do
            if window <= now then
                Supermarket.apuWindow[id] = nil
                TriggerClientEvent("core:supermarket:syncAPUShocked", -1, id, false)
            end
        end
    end
end)

RegisterNetEvent("core:supermarket:requestSupermarketsList", function()
    local source = source
    TriggerClientEvent("core:supermarket:receiveSupermarketsList", source, StoresMap())
end)

IL.RegisterCallback("core:supermarket:getGlobalItems", function(source)
    return Supermarket.items
end)

IL.RegisterCallback("core:supermarket:getPlayerAccounts", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { cash = 0, bank = 0 } end
    return {
        cash = IL.AccountMoney(xPlayer, "money"),
        bank = IL.AccountMoney(xPlayer, "bank"),
    }
end)

IL.RegisterCallback("core:supermarket:purchaseItems", function(source, purchaseData, total, paymentMethod)
    return Purchase(source, purchaseData, total, paymentMethod)
end)

IL.RegisterCallback("shops:buy", function(source, data)
    if not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local items = data.items
    if not IL.IsTable(items) then return { success = false, message = "Panier vide" } end

    local purchaseData = {}
    for _, entry in pairs(items) do
        if IL.IsTable(entry) then
            purchaseData[#purchaseData + 1] = {
                name = entry.itemName or entry.name,
                quantity = IL.Int(entry.quantity or entry.count, 1),
                price = IL.Int(entry.price, 0),
            }
        end
    end

    return Purchase(source, purchaseData, IL.Int(data.total, 0), IL.Str(data.paymentMethod, "cash"))
end)

RegisterNetEvent("shops:close", function()
    local source = source
    if not IL.Player(source) then return end
end)

IL.RegisterCallback("core:supermarket:canRobAPU", function(source, supermarketId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = IL.Int(supermarketId, nil)
    local store = id and Supermarket.stores[id] or nil
    if not store then return false, "Cette superette n'est pas valide" end
    if not store.active or not store.canRob then return false, "Cette superette n'est pas braquable" end

    if Supermarket.apuRobbing[id] then return false, "Un braquage est deja en cours" end

    local now = IL.Now()
    if store.apuLastRobbed > 0 and (now - store.apuLastRobbed) < Setting("apuCooldown") then
        return false, "Ce magasin a deja ete braque recemment"
    end

    if Setting("minPolice") > 0 and IL.PoliceOnDutyCount() < Setting("minPolice") then
        return false, "Trop peu de policiers en service"
    end

    return true, nil
end)

IL.RegisterCallback("core:supermarket:canRobSafe", function(source, supermarketId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local id = IL.Int(supermarketId, nil)
    local store = id and Supermarket.stores[id] or nil
    if not store then return false, "Cette superette n'est pas valide" end
    if not store.active or not store.canRob then return false, "Cette superette n'est pas braquable" end

    if Supermarket.safeRobbing[id] then return false, "Le coffre est deja en cours d'ouverture" end

    if ApuTimeLeft(id) <= 0 then
        return false, "Vous devez d'abord braquer le vendeur"
    end

    local now = IL.Now()
    if store.safeLastRobbed > 0 and (now - store.safeLastRobbed) < Setting("safeCooldown") then
        return false, "Ce coffre a deja ete vide recemment"
    end

    return true, nil
end)

IL.RegisterCallback("core:supermarket:getAPUState", function(source, supermarketId)
    local id = IL.Int(supermarketId, nil)
    if not id then return false, 0 end
    local timeLeft = ApuTimeLeft(id)
    return timeLeft > 0, timeLeft
end)

RegisterNetEvent("core:supermarket:startAPURobbery", function(supermarketId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(supermarketId, nil)
    local store = id and Supermarket.stores[id] or nil
    if not store or not store.active or not store.canRob then return end
    if Supermarket.apuRobbing[id] then return end

    local now = IL.Now()
    if store.apuLastRobbed > 0 and (now - store.apuLastRobbed) < Setting("apuCooldown") then return end

    Supermarket.apuRobbing[id] = { source = source, startedAt = now }

    TriggerClientEvent("core:supermarket:syncAPURobberyState", -1, id, true, source)
    TriggerClientEvent("core:supermarket:syncAPUShocked", -1, id, true)
    IL.AlertPolice("core:supermarket:policeAlert", id, store.pos)
end)

RegisterNetEvent("core:supermarket:cancelAPURobbery", function(supermarketId, reason)
    local source = source
    local id = IL.Int(supermarketId, nil)
    if not id then return end
    if type(reason) ~= "string" and reason ~= nil then return end

    local holder = Supermarket.apuRobbing[id]
    if not holder or holder.source ~= source then return end

    Supermarket.apuRobbing[id] = nil
    TriggerClientEvent("core:supermarket:syncAPURobberyState", -1, id, false, 0)
end)

RegisterNetEvent("core:supermarket:completeAPURobbery", function(supermarketId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(supermarketId, nil)
    local store = id and Supermarket.stores[id] or nil
    if not store then return end

    local holder = Supermarket.apuRobbing[id]
    if not holder or holder.source ~= source then return end

    Supermarket.apuRobbing[id] = nil

    local now = IL.Now()
    store.apuLastRobbed = now
    IL.Execute("UPDATE supermarkets SET apu_last_robbed = ? WHERE id = ?", { now, id })

    local minReward = math.max(0, IL.Int(Setting("apuRewardMin"), 800))
    local maxReward = math.max(minReward, IL.Int(Setting("apuRewardMax"), 1600))
    local amount = math.random(minReward, maxReward)
    IL.GiveMoney(xPlayer, "black_money", amount, "supermarket-apu")

    Supermarket.apuWindow[id] = now + math.max(0, IL.Int(Setting("safeWindow"), 300))

    TriggerClientEvent("core:supermarket:syncAPURobberyState", -1, id, false, 0)
    IL.Notify(source, "ILLEGAL", ("Caisse videe : %d$ sale."):format(amount))
end)

RegisterNetEvent("core:supermarket:startSafeRobbery", function(supermarketId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(supermarketId, nil)
    local store = id and Supermarket.stores[id] or nil
    if not store then return end
    if Supermarket.safeRobbing[id] then return end
    if ApuTimeLeft(id) <= 0 then return end

    Supermarket.safeRobbing[id] = { source = source, startedAt = IL.Now() }
    TriggerClientEvent("core:supermarket:syncSafeRobberyState", -1, id, true, source)
end)

RegisterNetEvent("core:supermarket:completeSafeRobbery", function(supermarketId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(supermarketId, nil)
    local store = id and Supermarket.stores[id] or nil
    if not store then return end

    local holder = Supermarket.safeRobbing[id]
    if not holder or holder.source ~= source then return end

    Supermarket.safeRobbing[id] = nil

    if ApuTimeLeft(id) <= 0 then
        TriggerClientEvent("core:supermarket:syncSafeRobberyState", -1, id, false, 0)
        return
    end

    local now = IL.Now()
    if store.safeLastRobbed > 0 and (now - store.safeLastRobbed) < Setting("safeCooldown") then
        TriggerClientEvent("core:supermarket:syncSafeRobberyState", -1, id, false, 0)
        return
    end

    store.safeLastRobbed = now
    IL.Execute("UPDATE supermarkets SET safe_last_robbed = ? WHERE id = ?", { now, id })

    local minReward = math.max(0, IL.Int(Setting("safeRewardMin"), 3000))
    local maxReward = math.max(minReward, IL.Int(Setting("safeRewardMax"), 6000))
    local amount = math.random(minReward, maxReward)
    IL.GiveMoney(xPlayer, "black_money", amount, "supermarket-safe")

    Supermarket.apuWindow[id] = nil

    TriggerClientEvent("core:supermarket:syncSafeRobberyState", -1, id, false, 0)
    TriggerClientEvent("core:supermarket:syncAPUShocked", -1, id, false)
    IL.Notify(source, "ILLEGAL", ("Coffre vide : %d$ sale."):format(amount))
end)

RegisterNetEvent("core:supermarket:reload", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    LoadSettings()
    LoadStores()
    LoadItems()
    TriggerClientEvent("core:supermarket:cleanupAllAPUs", -1)
    TriggerClientEvent("core:supermarket:syncSupermarkets", -1, StoresMap())
    TriggerClientEvent("core:supermarket:invalidateGlobalItemsCache", -1)
end)

local function staffOk(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission(BUILDER_PERM)
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

local function Vec(src)
    if type(src) ~= "table" then return nil end
    if src.x == nil and src.pos_x == nil then return nil end
    return {
        x = IL.Num(src.x or src.pos_x, 0.0),
        y = IL.Num(src.y or src.pos_y, 0.0),
        z = IL.Num(src.z or src.pos_z, 0.0),
        h = IL.Num(src.h or src.heading or src.w, 0.0),
    }
end

local function StoreRows()
    local rows = IL.Query("SELECT * FROM supermarkets ORDER BY name")
    for i = 1, #rows do
        local row = rows[i]
        row.active = IL.Bool(row.active)
        row.blip_enabled = IL.Bool(row.blip_enabled)
        row.can_rob = IL.Bool(row.can_rob)
        row.pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0) }
        row.apuPos = { x = IL.Num(row.apu_x, 0.0), y = IL.Num(row.apu_y, 0.0), z = IL.Num(row.apu_z, 0.0), h = IL.Num(row.apu_h, 0.0) }
        row.safePos = { x = IL.Num(row.safe_x, 0.0), y = IL.Num(row.safe_y, 0.0), z = IL.Num(row.safe_z, 0.0), h = IL.Num(row.safe_h, 0.0) }
        row.blipEnabled = row.blip_enabled
        row.canRob = row.can_rob
        row.storeType = row.store_type
        row.zoneRadius = IL.Num(row.zone_radius, 2.0)
    end
    return rows
end

local function ItemRows()
    local rows = IL.Query("SELECT * FROM supermarket_items ORDER BY category, name")
    for i = 1, #rows do
        rows[i].enabled = IL.Bool(rows[i].enabled)
        if not rows[i].label or rows[i].label == "" then
            rows[i].label = IL.ItemLabel(rows[i].name)
        end
    end
    return rows
end

local function SettingsPayload()
    return {
        apuCooldown = IL.Int(Setting("apuCooldown"), 1800),
        safeCooldown = IL.Int(Setting("safeCooldown"), 3600),
        safeWindow = IL.Int(Setting("safeWindow"), 300),
        minPolice = IL.Int(Setting("minPolice"), 0),
        apuRewardMin = IL.Int(Setting("apuRewardMin"), 800),
        apuRewardMax = IL.Int(Setting("apuRewardMax"), 1600),
        safeRewardMin = IL.Int(Setting("safeRewardMin"), 3000),
        safeRewardMax = IL.Int(Setting("safeRewardMax"), 6000),
    }
end

local function HubPanel()
    return {
        ok = true,
        success = true,
        stores = StoreRows(),
        items = ItemRows(),
        catalog = ItemsCatalog(),
        settings = SettingsPayload(),
    }
end

local function BroadcastStores(cleanup)
    LoadStores()
    if cleanup then
        TriggerClientEvent("core:supermarket:cleanupAllAPUs", -1)
    end
    TriggerClientEvent("core:supermarket:syncSupermarkets", -1, StoresMap())
end

local function BroadcastItems()
    LoadItems()
    TriggerClientEvent("core:supermarket:invalidateGlobalItemsCache", -1)
end

local function SaveStore(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local pos = Vec(data.pos or data.coords or data)
    local apu = Vec(data.apuPos or data.apu_pos or data.apu)
    if not pos then return nil, "Définissez la position du magasin." end
    if not apu then return nil, "Définissez la position de l'APU." end
    local name = IL.Str(data.name, "Superette")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "Superette" end
    local canRob = data.canRob
    if canRob == nil then canRob = data.can_rob end
    if canRob == nil then canRob = true end
    canRob = IL.Bool(canRob)
    local active = data.active
    if active == nil then active = true end
    local blip = data.blipEnabled
    if blip == nil then blip = data.blip_enabled end
    if blip == nil then blip = true end
    local storeType = canRob and "robbable" or "automatic"
    local radius = IL.Num(data.zoneRadius or data.zone_radius, 2.0)
    if radius < 1 then radius = 2.0 end
    local safe = Vec(data.safePos or data.safe_pos or data.safe)
    if canRob and not safe then return nil, "Définissez la position du coffre." end
    if not canRob then safe = { x = 0.0, y = 0.0, z = 0.0, h = 0.0 } end
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE supermarkets SET name = ?, store_type = ?, pos_x = ?, pos_y = ?, pos_z = ?,
                apu_x = ?, apu_y = ?, apu_z = ?, apu_h = ?,
                safe_x = ?, safe_y = ?, safe_z = ?, safe_h = ?,
                zone_radius = ?, active = ?, blip_enabled = ?, can_rob = ?
            WHERE id = ?
        ]], {
            name, storeType, pos.x, pos.y, pos.z,
            apu.x, apu.y, apu.z, apu.h,
            safe.x, safe.y, safe.z, safe.h,
            radius, IL.Bool(active) and 1 or 0, IL.Bool(blip) and 1 or 0, canRob and 1 or 0, id,
        })
        BroadcastStores(true)
        return id
    end
    id = IL.Insert([[
        INSERT INTO supermarkets (name, store_type, pos_x, pos_y, pos_z, apu_x, apu_y, apu_z, apu_h,
            safe_x, safe_y, safe_z, safe_h, zone_radius, active, blip_enabled, can_rob)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        name, storeType, pos.x, pos.y, pos.z, apu.x, apu.y, apu.z, apu.h,
        safe.x, safe.y, safe.z, safe.h, radius, IL.Bool(active) and 1 or 0, IL.Bool(blip) and 1 or 0, canRob and 1 or 0,
    })
    if not id then return nil, "Création impossible." end
    BroadcastStores(true)
    return id
end

local function SaveItem(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local name = IL.Str(data.name or data.item_name, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil, "Item obligatoire." end
    local label = IL.Str(data.label, IL.ItemLabel(name))
    local price = math.max(0, IL.Int(data.price, 0))
    local category = IL.Str(data.category, "divers")
    if category == "" then category = "divers" end
    local enabled = data.enabled
    if enabled == nil then enabled = true end
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE supermarket_items SET name = ?, label = ?, price = ?, category = ?, enabled = ? WHERE id = ?
        ]], { name:sub(1, 64), label:sub(1, 100), price, category:sub(1, 60), IL.Bool(enabled) and 1 or 0, id })
        BroadcastItems()
        return id
    end
    IL.Execute([[
        INSERT INTO supermarket_items (name, label, price, category, enabled)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), price = VALUES(price), category = VALUES(category), enabled = VALUES(enabled)
    ]], { name:sub(1, 64), label:sub(1, 100), price, category:sub(1, 60), IL.Bool(enabled) and 1 or 0 })
    BroadcastItems()
    return true
end

local function SaveSettings(data)
    if type(data) ~= "table" then return false end
    for key, default in pairs(DEFAULT_SETTINGS) do
        local value = data[key]
        if value ~= nil then
            local number = tonumber(value)
            if number then
                if key == "minPolice" then
                    number = math.max(0, math.floor(number))
                elseif key == "apuCooldown" or key == "safeCooldown" or key == "safeWindow" then
                    number = math.max(0, math.floor(number))
                else
                    number = math.max(0, math.floor(number))
                end
                IL.SaveSetting("supermarket_settings", key, number)
                Supermarket.settings[key] = number
            end
        end
    end
    return true
end

local function ResetCooldowns()
    IL.Execute("UPDATE supermarkets SET apu_last_robbed = 0, safe_last_robbed = 0")
    for _, store in pairs(Supermarket.stores) do
        store.apuLastRobbed = 0
        store.safeLastRobbed = 0
    end
    Supermarket.apuWindow = {}
    return true
end

IL.RegisterCallback("core:supermarket:getSupermarkets", function(source)
    if not staffOk(source) then return {} end
    return StoreRows()
end)

IL.RegisterCallback("core:supermarket:getSettings", function(source)
    if not staffOk(source) then return {} end
    return SettingsPayload()
end)

IL.RegisterCallback("core:supermarket:getGlobalItemsForBuilder", function(source)
    if not staffOk(source) then return {} end
    return ItemRows()
end)

RegisterNetEvent("core:supermarket:createSupermarket", function(data)
    local source = source
    if not staffOk(source) then return end
    SaveStore(data or {})
end)

RegisterNetEvent("core:supermarket:updateSupermarket", function(storeId, field, value)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(storeId, nil)
    if not id then return end
    local row = IL.Single("SELECT * FROM supermarkets WHERE id = ?", { id })
    if not row then return end
    local payload = {
        id = id,
        name = row.name,
        pos = { x = row.pos_x, y = row.pos_y, z = row.pos_z },
        apuPos = { x = row.apu_x, y = row.apu_y, z = row.apu_z, h = row.apu_h },
        safePos = { x = row.safe_x, y = row.safe_y, z = row.safe_z, h = row.safe_h },
        canRob = IL.Bool(row.can_rob),
        active = IL.Bool(row.active),
        blipEnabled = IL.Bool(row.blip_enabled),
        zoneRadius = row.zone_radius,
    }
    if field == "name" then payload.name = value
    elseif field == "active" then payload.active = value
    elseif field == "blipEnabled" or field == "blip_enabled" then payload.blipEnabled = value
    elseif field == "canRob" or field == "can_rob" then payload.canRob = value
    elseif field == "pos" then payload.pos = value
    elseif field == "apuPos" then payload.apuPos = value
    elseif field == "safePos" then payload.safePos = value
    elseif field == "zoneRadius" or field == "zone_radius" then payload.zoneRadius = value
    elseif IL.IsTable(field) then
        payload = field
        payload.id = id
    end
    SaveStore(payload)
end)

RegisterNetEvent("core:supermarket:deleteSupermarket", function(storeId)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(storeId, nil)
    if not id then return end
    IL.Execute("DELETE FROM supermarkets WHERE id = ?", { id })
    BroadcastStores(true)
end)

RegisterNetEvent("core:supermarket:updateSettings", function(key, value)
    local source = source
    if not staffOk(source) then return end
    local map = {
        globalCooldown = "apuCooldown",
        minPoliceRequired = "minPolice",
        apuRewardMin = "apuRewardMin",
        apuRewardMax = "apuRewardMax",
        safeRewardMin = "safeRewardMin",
        safeRewardMax = "safeRewardMax",
        apuCooldown = "apuCooldown",
        safeCooldown = "safeCooldown",
        safeWindow = "safeWindow",
        minPolice = "minPolice",
    }
    local target = map[tostring(key or "")]
    if not target then return end
    local number = tonumber(value)
    if not number then return end
    if key == "globalCooldown" then number = number * 60 end
    SaveSettings({ [target] = number })
end)

RegisterNetEvent("core:supermarket:addGlobalItem", function(itemName, price, category)
    local source = source
    if not staffOk(source) then return end
    SaveItem({ name = itemName, price = price, category = category, enabled = true })
end)

RegisterNetEvent("core:supermarket:updateGlobalItem", function(itemName, price, category)
    local source = source
    if not staffOk(source) then return end
    SaveItem({ name = itemName, price = price, category = category })
end)

RegisterNetEvent("core:supermarket:removeGlobalItem", function(itemName)
    local source = source
    if not staffOk(source) then return end
    IL.Execute("DELETE FROM supermarket_items WHERE name = ?", { IL.Str(itemName, "") })
    BroadcastItems()
end)

RegisterNetEvent("core:supermarket:resetCooldowns", function()
    local source = source
    if not staffOk(source) then return end
    ResetCooldowns()
end)

RegisterNetEvent("core:supermarket:reloadFromDatabase", function()
    local source = source
    if not staffOk(source) then return end
    LoadSettings()
    BroadcastStores(true)
    BroadcastItems()
end)

IL.RegisterCallback("gestionSupermarket:hubPanel", function(source)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les supérettes." }
    end
    LoadSettings()
    return HubPanel()
end)

IL.RegisterCallback("gestionSupermarket:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = tostring(data.action or "")
    local err, id

    if action == "settings:save" then
        SaveSettings(data)
    elseif action == "store:save" then
        id, err = SaveStore(data)
        if not id then return fail(err) end
    elseif action == "store:delete" then
        local storeId = IL.Int(data.id, nil)
        if not storeId then return fail("Supérette introuvable.") end
        IL.Execute("DELETE FROM supermarkets WHERE id = ?", { storeId })
        BroadcastStores(true)
    elseif action == "item:save" then
        id, err = SaveItem(data)
        if not id then return fail(err) end
    elseif action == "item:delete" then
        if data.id then
            IL.Execute("DELETE FROM supermarket_items WHERE id = ?", { IL.Int(data.id, 0) })
        else
            IL.Execute("DELETE FROM supermarket_items WHERE name = ?", { IL.Str(data.name, "") })
        end
        BroadcastItems()
    elseif action == "cooldowns:reset" then
        ResetCooldowns()
    else
        return fail("Action inconnue.")
    end

    local panel = HubPanel()
    panel.success = true
    return panel
end)

