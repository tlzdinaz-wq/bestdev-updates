Feat27 = Feat27 or {}

local sessions = {}
local MASK_ITEM = "scuba_mask"
local OBJECT_LIFETIME = 300000

local function divingConfig()
    return (Config and Config.diving) or { zones = {}, items = {} }
end

local function sellPrices()
    local out = {}
    local sellers = Config and Config.legalActivitiesSellers or {}
    local diving = sellers.diving
    if diving and diving.itemsToSell then
        for i = 1, #diving.itemsToSell do
            local entry = diving.itemsToSell[i]
            out[entry.name] = tonumber(entry.price) or 0
        end
    end
    local items = divingConfig().items or {}
    for i = 1, #items do
        if not out[items[i].name] then
            out[items[i].name] = tonumber(items[i].price) or 0
        end
    end
    return out
end

local function maskOxygen(xPlayer)
    local meta = Feat27.Inv.Meta(xPlayer, MASK_ITEM)
    if not Feat27.Inv.Entry(xPlayer, MASK_ITEM) then return 0 end
    if type(meta) == "table" and tonumber(meta.oxygen) then
        local value = tonumber(meta.oxygen)
        if value < 0 then return 0 end
        if value > 100 then return 100 end
        return value
    end
    return 100
end

local function setMaskOxygen(xPlayer, percent)
    Feat27.Inv.SetMeta(xPlayer, MASK_ITEM, "oxygen", percent)
end

local function clearSessionObjects(source)
    local session = sessions[source]
    if not session then return end
    for netId in pairs(session.objects) do
        TriggerClientEvent("core:diving:client:deleteObject", source, netId)
        Feat27.DeleteNet(netId)
    end
    session.objects = {}
end

local function spawnDivingObject(source)
    local session = sessions[source]
    if not session or not session.zone then return end

    local zone = divingConfig().zones[session.zone]
    if not zone or type(zone.spawns) ~= "table" or #zone.spawns == 0 then return end
    if type(zone.objectsModels) ~= "table" or #zone.objectsModels == 0 then return end

    local spawn = zone.spawns[math.random(1, #zone.spawns)]
    local model = zone.objectsModels[math.random(1, #zone.objectsModels)]

    local netId = Feat27.SpawnObject(model, spawn, 0.0)
    if not netId then return end

    session.objects[netId] = model
    session.currentNetId = netId
    session.currentModel = model

    TriggerClientEvent("core:diving:client:new", source, netId)

    SetTimeout(OBJECT_LIFETIME, function()
        local current = sessions[source]
        if current and current.objects[netId] then
            current.objects[netId] = nil
            Feat27.DeleteNet(netId)
        end
    end)
end

local function stopDiving(source)
    local session = sessions[source]
    if not session then return end
    clearSessionObjects(source)
    sessions[source] = nil
end

function LegalActivities.StartDiving(xPlayer)
    local source = xPlayer.source

    local equipResult = TriggerClientCallback(source, "core:diving:client:equip")
    if equipResult == true then
        stopDiving(source)
        return
    end
    if equipResult == false then
        return
    end

    local oxygen = maskOxygen(xPlayer)
    if oxygen <= 0 then
        Feat27.NotifyError(source, "Votre bouteille est vide.")
        return
    end

    local zone = TriggerClientCallback(source, "core:diving:client:start", oxygen)

    sessions[source] = { zone = nil, objects = {} }

    if type(zone) == "string" and zone ~= "-1" and divingConfig().zones[zone] then
        sessions[source].zone = zone
        spawnDivingObject(source)
    end
end

RegisterNetEvent("core:diving:server:updateOxygen", function(currentPercent)
    local source = source
    local percent = tonumber(currentPercent)
    if not percent then return end
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    setMaskOxygen(xPlayer, math.floor(percent))
end)

RegisterNetEvent("core:diving:server:stop", function()
    local source = source
    stopDiving(source)
end)

RegisterNetEvent("core:diving:server:scubaMaskBroken", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    stopDiving(source)

    if Feat27.Inv.Entry(xPlayer, MASK_ITEM) then
        Feat27.Inv.Take(xPlayer, MASK_ITEM, 1, true)
    end
    Feat27.NotifyError(source, "Votre masque de plongée est hors d'usage.")
end)

RegisterServerCallback("core:diving:server:collect", function(source, zone, objectNetId)
    if type(zone) ~= "string" then return false end
    local netId = tonumber(objectNetId)
    if not netId then return false end
    if not Feat27.RateLimit(source, "diving:collect", 800) then return false end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local session = sessions[source]
    if not session or session.zone ~= zone then return false end
    if not session.objects[netId] then return false end

    local entity = Feat27.EntityFromNet(netId)
    if entity then
        local coords = Feat27.PlayerCoords(source)
        if not coords or #(coords - GetEntityCoords(entity)) > 8.0 then return false end
    end

    local zoneConfig = divingConfig().zones[zone]
    if not zoneConfig or type(zoneConfig.rewards) ~= "table" then return false end

    local model = session.objects[netId]
    local reward = zoneConfig.rewards[model]
    if not reward then return false end

    if not Feat27.Inv.CanCarry(xPlayer, reward, 1) then
        Feat27.NotifyError(source, "Votre inventaire est plein.")
        return false
    end

    session.objects[netId] = nil
    session.currentNetId = nil

    TriggerClientEvent("core:diving:client:deleteObject", source, netId)
    SetTimeout(3000, function()
        Feat27.DeleteNet(netId)
    end)

    Feat27.Inv.Give(xPlayer, reward, 1, nil, true)

    SetTimeout(1500, function()
        if sessions[source] then
            spawnDivingObject(source)
        end
    end)

    return true
end)

RegisterServerCallback("core:legal_activities:diving:getMyItems", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local prices = sellPrices()
    local out = {}
    for name, price in pairs(prices) do
        out[#out + 1] = {
            name = name,
            label = Feat27.Inv.Label(name),
            count = Feat27.Inv.Count(xPlayer, name),
            price = price,
            image = Feat27.Inv.Image(name),
        }
    end
    return out
end)

RegisterNetEvent("core:legal_activities:diving:resell", function(name, count, paymentType)
    local source = source
    if type(name) ~= "string" then return end

    local amount = math.floor(tonumber(count) or 0)
    if amount <= 0 then return end
    if not Feat27.RateLimit(source, "diving:sell", 400) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local price = sellPrices()[name]
    if not price or price <= 0 then return end

    if Feat27.Inv.Count(xPlayer, name) < amount then
        Feat27.NotifyError(source, "Vous n'avez pas assez d'objets.")
        return
    end

    if not Feat27.Inv.Take(xPlayer, name, amount, false) then return end

    local total = price * amount
    LegalActivities.Pay(xPlayer, total, paymentType, "plongee-revente")
    LegalActivities.Log(xPlayer.identifier, "diving", name, amount, total, paymentType)
    Feat27.NotifyOk(source, ("Vous avez vendu %d objet%s pour %d$."):format(amount, amount > 1 and "s" or "", total))
end)

AddEventHandler("vfw:playerDropped", function(source)
    stopDiving(source)
end)

CreateThread(function()
    while not VFW or not VFW.Inventory or not VFW.Inventory.RegisterUsableItem do Wait(500) end
    VFW.Inventory.RegisterUsableItem(MASK_ITEM, function(xPlayer)
        CreateThread(function()
            LegalActivities.StartDiving(xPlayer)
        end)
    end)
end)
