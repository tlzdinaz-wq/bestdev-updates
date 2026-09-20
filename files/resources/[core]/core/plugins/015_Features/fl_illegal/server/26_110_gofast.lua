local GoFast = {
    npcs = {},
    categories = {},
    deliveries = {},
    missions = {},
    settings = {},
}

local BUILDER_PERM = "builder_gofast"
local CARGO_ITEM = "gofast_cargo"
local playerCooldown = {}
local DEFAULT_SETTINGS = {
    missionCooldown = 900,
    deliveryTimeout = 1200,
    absenceLimit = 30,
    minPolice = 0,
}

local function LoadSettings()
    IL.EnsureSettingsTable("gofast_settings")
    GoFast.settings = IL.LoadSettings("gofast_settings", DEFAULT_SETTINGS)
end

local function Setting(key)
    return IL.Num(GoFast.settings[key], DEFAULT_SETTINGS[key])
end

local function LoadNPCs()
    GoFast.npcs = {}
    local rows = IL.Query("SELECT * FROM gofast_npcs")
    for i = 1, #rows do
        local row = rows[i]
        GoFast.npcs[#GoFast.npcs + 1] = {
            id = row.id,
            region = row.region,
            enabled = IL.Bool(row.enabled),
            model = row.model or "g_m_y_mexgang_01",
            label = row.label or row.region,
            position = {
                x = IL.Num(row.pos_x, 0.0),
                y = IL.Num(row.pos_y, 0.0),
                z = IL.Num(row.pos_z, 0.0),
                heading = IL.Num(row.heading, 0.0),
            },
        }
    end
end

local function LoadCategories()
    GoFast.categories = {}
    local rows = IL.Query("SELECT * FROM gofast_categories WHERE enabled = 1")
    for i = 1, #rows do
        local row = rows[i]
        GoFast.categories[#GoFast.categories + 1] = {
            id = row.id,
            name = row.name,
            label = row.label or row.name,
            models = IL.Decode(row.vehicle_models, {}),
            priceMin = IL.Int(row.price_min, 5000),
            priceMax = IL.Int(row.price_max, 12000),
            enabled = true,
        }
    end
end

local function LoadDeliveries()
    GoFast.deliveries = {}
    local rows = IL.Query("SELECT * FROM gofast_deliveries WHERE enabled = 1")
    for i = 1, #rows do
        local row = rows[i]
        GoFast.deliveries[#GoFast.deliveries + 1] = {
            id = row.id,
            region = row.region,
            label = row.label or row.region,
            pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0) },
        }
    end
end

local function FindCategory(name)
    for i = 1, #GoFast.categories do
        if GoFast.categories[i].name == name or GoFast.categories[i].label == name then
            return GoFast.categories[i]
        end
    end
    return nil
end

local function PickDelivery(region)
    local pool = {}
    for i = 1, #GoFast.deliveries do
        if GoFast.deliveries[i].region ~= region then
            pool[#pool + 1] = GoFast.deliveries[i]
        end
    end
    if #pool == 0 then pool = GoFast.deliveries end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function FindNpc(region)
    for i = 1, #GoFast.npcs do
        if GoFast.npcs[i].region == region and GoFast.npcs[i].enabled then
            return GoFast.npcs[i]
        end
    end
    return nil
end

local function RandomPlate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = "GF"
    for _ = 1, 6 do
        local index = math.random(1, #chars)
        plate = plate .. chars:sub(index, index)
    end
    return plate
end

local function EndMission(source, status, reason)
    local mission = GoFast.missions[source]
    if not mission then return end

    GoFast.missions[source] = nil
    IL.Execute("UPDATE gofast_missions SET status = ?, cancel_reason = ? WHERE id = ?", {
        status, reason, mission.dbId,
    })

    if status ~= "completed" and mission.vehicle and DoesEntityExist(mission.vehicle) then
        DeleteEntity(mission.vehicle)
    end
end

IL.OnReady(function()
    LoadSettings()
    LoadNPCs()
    LoadCategories()
    LoadDeliveries()
    IL.Execute("UPDATE gofast_missions SET status = 'canceled', cancel_reason = 'restart' WHERE status = 'running'")
end)

IL.OnPlayerDropped(function(source)
    EndMission(source, "canceled", "deconnexion")
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = IL.Now()
        local running, total = {}, 0
        for source in pairs(GoFast.missions) do
            total = total + 1
            running[total] = source
        end

        for i = 1, total do
            local source = running[i]
            local mission = GoFast.missions[source]
            if mission then
                if not IL.Player(source) then
                    EndMission(source, "canceled", "deconnexion")
                elseif now - mission.startedAt > Setting("deliveryTimeout") then
                    TriggerClientEvent("core:gofast:missionCanceled", source, "Temps écoulé")
                    EndMission(source, "canceled", "timeout")
                elseif mission.lastSeen > 0 and (now - mission.lastSeen) > Setting("absenceLimit") then
                    TriggerClientEvent("core:gofast:missionCanceled", source, "Véhicule abandonné")
                    EndMission(source, "canceled", "abandon")
                end
            end
        end
    end
end)

IL.RegisterCallback("core:gofast:getNPCs", function(source)
    return GoFast.npcs
end)

IL.RegisterCallback("core:gofast:getVehicleCategories", function(source)
    local out = {}
    for i = 1, #GoFast.categories do
        local category = GoFast.categories[i]
        out[#out + 1] = {
            id = category.id,
            name = category.name,
            label = category.label,
            price = category.priceMin,
            priceMin = category.priceMin,
            priceMax = category.priceMax,
            enabled = true,
        }
    end
    return out
end)

IL.RegisterCallback("core:gofast:canStartMission", function(source, region)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { canStart = false, reason = "Joueur introuvable" } end

    region = IL.Str(region, nil)
    if region ~= "NORTH" and region ~= "SOUTH" then
        return { canStart = false, reason = "Cette region n'est pas valide" }
    end

    if GoFast.missions[source] then
        return { canStart = false, reason = "Vous avez deja une mission en cours" }
    end

    local npc = FindNpc(region)
    if not npc or not npc.enabled then
        return { canStart = false, reason = "Ce point n'est pas disponible" }
    end

    if #GoFast.categories == 0 then
        return { canStart = false, reason = "Aucune categorie de vehicule disponible" }
    end

    if #GoFast.deliveries == 0 then
        return { canStart = false, reason = "Aucun point de livraison configure" }
    end

    if Setting("minPolice") > 0 and IL.PoliceOnDutyCount() < Setting("minPolice") then
        return { canStart = false, reason = "Trop peu de policiers en service" }
    end

    local last = playerCooldown[xPlayer.identifier]
    if last and (IL.Now() - last) < Setting("missionCooldown") then
        return { canStart = false, reason = "Vous devez attendre avant un nouveau Go Fast" }
    end

    return { canStart = true, reason = nil }
end)

RegisterNetEvent("core:gofast:startMission", function(region, category)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    region = IL.Str(region, nil)
    if region ~= "NORTH" and region ~= "SOUTH" then return end
    if type(category) ~= "string" then return end
    if GoFast.missions[source] then return end

    local npc = FindNpc(region)
    if not npc or not npc.enabled then return end

    local def = FindCategory(category)
    if not def then
        IL.Notify(source, "ILLEGAL", "Categorie inconnue.")
        return
    end

    local models = def.models
    if not IL.IsTable(models) or #models == 0 then
        IL.Notify(source, "ILLEGAL", "Aucun vehicule disponible.")
        return
    end

    local delivery = PickDelivery(region)
    if not delivery then
        IL.Notify(source, "ILLEGAL", "Aucun point de livraison disponible.")
        return
    end

    local last = playerCooldown[xPlayer.identifier]
    if last and (IL.Now() - last) < Setting("missionCooldown") then
        IL.Notify(source, "ILLEGAL", "Vous devez attendre avant un nouveau Go Fast.")
        return
    end

    playerCooldown[xPlayer.identifier] = IL.Now()

    local model = models[math.random(1, #models)]
    local spawn = {
        x = npc.position.x + math.random(-6, 6) * 1.0,
        y = npc.position.y + math.random(-6, 6) * 1.0,
        z = npc.position.z,
        heading = npc.position.heading,
    }

    local vehicle = CreateVehicle(GetHashKey(model), spawn.x, spawn.y, spawn.z, spawn.heading, true, true)
    local attempts = 0
    while not DoesEntityExist(vehicle) and attempts < 50 do
        Wait(20)
        attempts = attempts + 1
    end
    if not DoesEntityExist(vehicle) then
        playerCooldown[xPlayer.identifier] = last
        IL.Notify(source, "ILLEGAL", "Impossible de faire apparaitre le vehicule.")
        return
    end

    local plate = RandomPlate()
    if SetVehicleNumberPlateText then
        pcall(SetVehicleNumberPlateText, vehicle, plate)
    end

    local price = math.random(def.priceMin, math.max(def.priceMin, def.priceMax))
    local now = IL.Now()

    local dbId = IL.Insert([[
        INSERT INTO gofast_missions (identifier, region, category, vehicle_model, vehicle_plate, vehicle_price,
            delivery_x, delivery_y, delivery_z, delivery_region, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'running')
    ]], {
        xPlayer.identifier, region, def.name, model, plate, price,
        delivery.pos.x, delivery.pos.y, delivery.pos.z, delivery.region,
    })

    local missionId = ("gf_%d_%d"):format(source, now)

    GoFast.missions[source] = {
        id = missionId,
        dbId = dbId,
        source = source,
        region = region,
        category = def.name,
        vehicle = vehicle,
        vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle),
        plate = plate,
        price = price,
        delivery = delivery,
        startedAt = now,
        lastSeen = now,
        cargoLoaded = false,
    }

    playerCooldown[xPlayer.identifier] = now

    TriggerClientEvent("core:gofast:missionStarted", source, {
        missionId = missionId,
        region = region,
        deliveryPosition = delivery.pos,
        deliveryRegion = delivery.label,
        vehicleModel = model,
        vehiclePlate = plate,
        vehiclePrice = price,
        vehicleSpawn = spawn,
        vehicleNetId = GoFast.missions[source].vehicleNetId,
        deliveryTimeout = Setting("deliveryTimeout"),
    })
end)

RegisterNetEvent("core:gofast:loadCargo", function(missionId)
    local source = source
    local mission = GoFast.missions[source]
    if not mission then return end
    if missionId ~= nil and missionId ~= mission.id then return end

    mission.cargoLoaded = true
    mission.lastSeen = IL.Now()
end)

RegisterNetEvent("core:gofast:updateVehiclePresence", function(missionId, present)
    local source = source
    local mission = GoFast.missions[source]
    if not mission then return end
    if missionId ~= nil and missionId ~= mission.id then return end
    if type(present) ~= "boolean" then return end

    if present then
        mission.lastSeen = IL.Now()
    end
end)

RegisterNetEvent("core:gofast:completeMission", function(missionId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local mission = GoFast.missions[source]
    if not mission then return end
    if missionId ~= nil and missionId ~= mission.id then return end
    if not mission.cargoLoaded then return end

    local delivery = mission.delivery
    if IL.DistanceTo(source, delivery.pos.x, delivery.pos.y, delivery.pos.z) > 60.0 then
        IL.Notify(source, "ILLEGAL", "Vous n'etes pas au point de livraison.")
        return
    end

    IL.GiveMoney(xPlayer, "black_money", mission.price, "gofast")
    IL.Notify(source, "ILLEGAL", ("Livraison terminee : %d$ sale."):format(mission.price))

    TriggerClientEvent("core:gofast:missionCompleted", source, 60)
    EndMission(source, "completed", nil)
end)

RegisterNetEvent("core:gofast:reload", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    LoadSettings()
    LoadNPCs()
    LoadCategories()
    LoadDeliveries()
    TriggerClientEvent("core:gofast:reloadConfig", -1)
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

local function Vec(src)
    if type(src) ~= "table" then return nil end
    if src.x == nil and src.pos_x == nil then return nil end
    return {
        x = IL.Num(src.x or src.pos_x, 0.0),
        y = IL.Num(src.y or src.pos_y, 0.0),
        z = IL.Num(src.z or src.pos_z, 0.0),
        heading = IL.Num(src.heading or src.h or src.w, 0.0),
    }
end

local function RegionOf(value)
    local region = IL.Str(value, ""):upper()
    if region ~= "NORTH" and region ~= "SOUTH" then return nil end
    return region
end

local function ParseModels(value)
    if type(value) == "string" then
        local out = {}
        for part in string.gmatch(value, "[^,%s]+") do
            out[#out + 1] = part
        end
        return out
    end
    if not IL.IsTable(value) then return {} end
    local out = {}
    for i = 1, #value do
        local name = IL.Str(value[i], "")
        if name ~= "" then out[#out + 1] = name end
    end
    return out
end

local function NpcRows()
    local rows = IL.Query("SELECT * FROM gofast_npcs ORDER BY region, id")
    for i = 1, #rows do
        rows[i].enabled = IL.Bool(rows[i].enabled)
        rows[i].position = {
            x = IL.Num(rows[i].pos_x, 0.0),
            y = IL.Num(rows[i].pos_y, 0.0),
            z = IL.Num(rows[i].pos_z, 0.0),
            heading = IL.Num(rows[i].heading, 0.0),
        }
        rows[i].coords = rows[i].position
        rows[i].model = rows[i].model or "g_m_y_mexgang_01"
    end
    return rows
end

local function DeliveryRows()
    local rows = IL.Query("SELECT * FROM gofast_deliveries ORDER BY region, id")
    for i = 1, #rows do
        rows[i].enabled = IL.Bool(rows[i].enabled)
        rows[i].pos = { x = IL.Num(rows[i].pos_x, 0.0), y = IL.Num(rows[i].pos_y, 0.0), z = IL.Num(rows[i].pos_z, 0.0) }
        rows[i].coords = rows[i].pos
    end
    return rows
end

local function CategoryRows()
    local rows = IL.Query("SELECT * FROM gofast_categories ORDER BY name")
    for i = 1, #rows do
        rows[i].enabled = IL.Bool(rows[i].enabled)
        rows[i].models = IL.Decode(rows[i].vehicle_models, {})
        rows[i].vehicle_models = rows[i].models
        rows[i].priceMin = IL.Int(rows[i].price_min, 0)
        rows[i].priceMax = IL.Int(rows[i].price_max, 0)
    end
    return rows
end

local function SettingsPayload()
    return {
        missionCooldown = IL.Int(Setting("missionCooldown"), 900),
        deliveryTimeout = IL.Int(Setting("deliveryTimeout"), 1200),
        absenceLimit = IL.Int(Setting("absenceLimit"), 30),
        minPolice = IL.Int(Setting("minPolice"), 0),
    }
end

local function HubPanel()
    return {
        ok = true,
        success = true,
        npcs = NpcRows(),
        deliveries = DeliveryRows(),
        categories = CategoryRows(),
        settings = SettingsPayload(),
        running = 0,
    }
end

local function BroadcastGoFast()
    LoadNPCs()
    LoadCategories()
    LoadDeliveries()
    TriggerClientEvent("core:gofast:reloadConfig", -1)
end

local function SaveNpc(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local region = RegionOf(data.region)
    if not region then return nil, "Région NORTH ou SOUTH obligatoire." end
    local pos = Vec(data.position or data.coords or data.pos or data)
    if not pos then return nil, "Définissez la position du NPC." end
    local enabled = data.enabled
    if enabled == nil then enabled = true end
    local model = IL.Str(data.model, "g_m_y_mexgang_01")
    if model == "" then model = "g_m_y_mexgang_01" end
    local label = IL.Str(data.label, region)
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE gofast_npcs SET region = ?, enabled = ?, pos_x = ?, pos_y = ?, pos_z = ?, heading = ?, model = ?, label = ?
            WHERE id = ?
        ]], { region, IL.Bool(enabled) and 1 or 0, pos.x, pos.y, pos.z, pos.heading, model:sub(1, 60), label:sub(1, 100), id })
        BroadcastGoFast()
        return id
    end
    id = IL.Insert([[
        INSERT INTO gofast_npcs (region, enabled, pos_x, pos_y, pos_z, heading, model, label)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { region, IL.Bool(enabled) and 1 or 0, pos.x, pos.y, pos.z, pos.heading, model:sub(1, 60), label:sub(1, 100) })
    if not id then return nil, "Création impossible." end
    BroadcastGoFast()
    return id
end

local function SaveDelivery(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local region = RegionOf(data.region)
    if not region then return nil, "Région NORTH ou SOUTH obligatoire." end
    local pos = Vec(data.pos or data.coords or data.position or data)
    if not pos then return nil, "Définissez la position de livraison." end
    local enabled = data.enabled
    if enabled == nil then enabled = data.active end
    if enabled == nil then enabled = true end
    local label = IL.Str(data.label or data.name, region)
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE gofast_deliveries SET region = ?, label = ?, pos_x = ?, pos_y = ?, pos_z = ?, enabled = ? WHERE id = ?
        ]], { region, label:sub(1, 100), pos.x, pos.y, pos.z, IL.Bool(enabled) and 1 or 0, id })
        BroadcastGoFast()
        return id
    end
    id = IL.Insert([[
        INSERT INTO gofast_deliveries (region, label, pos_x, pos_y, pos_z, enabled)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { region, label:sub(1, 100), pos.x, pos.y, pos.z, IL.Bool(enabled) and 1 or 0 })
    if not id then return nil, "Création impossible." end
    BroadcastGoFast()
    return id
end

local function SaveCategory(data)
    if type(data) ~= "table" then return nil, "Données invalides." end
    local name = IL.Str(data.name, "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil, "Identifiant de catégorie obligatoire." end
    local label = IL.Str(data.label, name)
    local models = ParseModels(data.models or data.vehicle_models)
    if #models == 0 then return nil, "Ajoutez au moins un modèle de véhicule." end
    local minP = math.max(0, IL.Int(data.price_min or data.priceMin, 5000))
    local maxP = math.max(minP, IL.Int(data.price_max or data.priceMax, 12000))
    local enabled = data.enabled
    if enabled == nil then enabled = true end
    local id = IL.Int(data.id, nil)
    if id then
        IL.Execute([[
            UPDATE gofast_categories SET name = ?, label = ?, vehicle_models = ?, price_min = ?, price_max = ?, enabled = ? WHERE id = ?
        ]], { name:sub(1, 60), label:sub(1, 100), IL.Encode(models), minP, maxP, IL.Bool(enabled) and 1 or 0, id })
        BroadcastGoFast()
        return id
    end
    IL.Execute([[
        INSERT INTO gofast_categories (name, label, vehicle_models, price_min, price_max, enabled)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), vehicle_models = VALUES(vehicle_models),
            price_min = VALUES(price_min), price_max = VALUES(price_max), enabled = VALUES(enabled)
    ]], { name:sub(1, 60), label:sub(1, 100), IL.Encode(models), minP, maxP, IL.Bool(enabled) and 1 or 0 })
    BroadcastGoFast()
    return true
end

local function SaveSettings(data)
    if type(data) ~= "table" then return false end
    for key, default in pairs(DEFAULT_SETTINGS) do
        local value = data[key]
        if value ~= nil then
            local number = tonumber(value)
            if number then
                number = math.max(0, math.floor(number))
                IL.SaveSetting("gofast_settings", key, number)
                GoFast.settings[key] = number
            end
        end
    end
    return true
end

IL.RegisterCallback("core:gofast:getSettings", function(source)
    if not staffOk(source) then return {} end
    local s = SettingsPayload()
    return {
        min_police_required = s.minPolice,
        cooldown_duration = math.floor(s.missionCooldown / 60),
        delivery_timeout = s.deliveryTimeout,
        missionCooldown = s.missionCooldown,
        deliveryTimeout = s.deliveryTimeout,
        absenceLimit = s.absenceLimit,
        minPolice = s.minPolice,
    }
end)

IL.RegisterCallback("core:gofast:getDestinations", function(source)
    if not staffOk(source) then return {} end
    local rows = DeliveryRows()
    for i = 1, #rows do
        rows[i].active = rows[i].enabled
        rows[i].position = rows[i].pos
    end
    return rows
end)

RegisterNetEvent("core:gofast:updateSettings", function(key, value)
    local source = source
    if not staffOk(source) then return end
    local map = {
        min_police_required = "minPolice",
        cooldown_duration = "missionCooldown",
        delivery_timeout = "deliveryTimeout",
        missionCooldown = "missionCooldown",
        deliveryTimeout = "deliveryTimeout",
        absenceLimit = "absenceLimit",
        minPolice = "minPolice",
    }
    local target = map[tostring(key or "")]
    if not target then return end
    local number = tonumber(value)
    if not number then return end
    if key == "cooldown_duration" then number = number * 60 end
    SaveSettings({ [target] = number })
end)

RegisterNetEvent("core:gofast:updateNPC", function(region, field, value)
    local source = source
    if not staffOk(source) then return end
    region = RegionOf(region)
    if not region then return end
    local row = IL.Single("SELECT * FROM gofast_npcs WHERE region = ? ORDER BY id LIMIT 1", { region })
    if not row then
        if field == "position" and IL.IsTable(value) then
            SaveNpc({ region = region, position = value, enabled = true })
        end
        return
    end
    local payload = {
        id = row.id,
        region = row.region,
        enabled = IL.Bool(row.enabled),
        model = row.model,
        label = row.label,
        position = { x = row.pos_x, y = row.pos_y, z = row.pos_z, heading = row.heading },
    }
    if field == "position" then payload.position = value
    elseif field == "vehicle_spawn" then return
    elseif field == "enabled" then payload.enabled = value
    elseif field == "model" then payload.model = value
    end
    SaveNpc(payload)
end)

RegisterNetEvent("core:gofast:createDestination", function(data)
    local source = source
    if not staffOk(source) then return end
    SaveDelivery(data or {})
end)

RegisterNetEvent("core:gofast:updateDestination", function(destId, field, value)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(destId, nil)
    if not id then return end
    local row = IL.Single("SELECT * FROM gofast_deliveries WHERE id = ?", { id })
    if not row then return end
    local payload = {
        id = id,
        region = row.region,
        label = row.label,
        pos = { x = row.pos_x, y = row.pos_y, z = row.pos_z },
        enabled = IL.Bool(row.enabled),
    }
    if field == "position" then payload.pos = value
    elseif field == "active" or field == "enabled" then payload.enabled = value
    elseif field == "label" then payload.label = value
    elseif field == "region" then payload.region = value
    end
    SaveDelivery(payload)
end)

RegisterNetEvent("core:gofast:deleteDestination", function(destId)
    local source = source
    if not staffOk(source) then return end
    local id = IL.Int(destId, nil)
    if not id then return end
    IL.Execute("DELETE FROM gofast_deliveries WHERE id = ?", { id })
    BroadcastGoFast()
end)

RegisterNetEvent("core:gofast:resetCooldowns", function()
    local source = source
    if not staffOk(source) then return end
    playerCooldown = {}
end)

RegisterNetEvent("core:gofast:reloadFromDatabase", function()
    local source = source
    if not staffOk(source) then return end
    LoadSettings()
    BroadcastGoFast()
end)

IL.RegisterCallback("gestionGoFast:hubPanel", function(source)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer le go fast." }
    end
    LoadSettings()
    local panel = HubPanel()
    local running = 0
    for _ in pairs(GoFast.missions) do running = running + 1 end
    panel.running = running
    return panel
end)

IL.RegisterCallback("gestionGoFast:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    local action = tostring(data.action or "")
    local err, id

    if action == "settings:save" then
        SaveSettings(data)
    elseif action == "npc:save" then
        id, err = SaveNpc(data)
        if not id then return fail(err) end
    elseif action == "npc:delete" then
        local npcId = IL.Int(data.id, nil)
        if not npcId then return fail("NPC introuvable.") end
        IL.Execute("DELETE FROM gofast_npcs WHERE id = ?", { npcId })
        BroadcastGoFast()
    elseif action == "delivery:save" then
        id, err = SaveDelivery(data)
        if not id then return fail(err) end
    elseif action == "delivery:delete" then
        local destId = IL.Int(data.id, nil)
        if not destId then return fail("Livraison introuvable.") end
        IL.Execute("DELETE FROM gofast_deliveries WHERE id = ?", { destId })
        BroadcastGoFast()
    elseif action == "category:save" then
        id, err = SaveCategory(data)
        if not id then return fail(err) end
    elseif action == "category:delete" then
        if data.id then
            IL.Execute("DELETE FROM gofast_categories WHERE id = ?", { IL.Int(data.id, 0) })
        else
            IL.Execute("DELETE FROM gofast_categories WHERE name = ?", { IL.Str(data.name, "") })
        end
        BroadcastGoFast()
    elseif action == "cooldowns:reset" then
        playerCooldown = {}
    else
        return fail("Action inconnue.")
    end

    local panel = HubPanel()
    panel.success = true
    local running = 0
    for _ in pairs(GoFast.missions) do running = running + 1 end
    panel.running = running
    return panel
end)

