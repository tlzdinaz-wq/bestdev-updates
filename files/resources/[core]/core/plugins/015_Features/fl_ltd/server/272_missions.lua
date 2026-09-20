Feat27 = Feat27 or {}

local missions = {}
local BOX_ITEM = "ltd_box"

local DEFAULT_PICKUPS = {
    { x = 25.75,    y = -1347.31, z = 29.49 },
    { x = 1163.09,  y = -323.86,  z = 69.20 },
    { x = -3242.29, y = 1001.29,  z = 12.83 },
    { x = 1729.45,  y = 6414.35,  z = 35.03 },
    { x = 547.34,   y = 2670.11,  z = 42.15 },
    { x = -707.30,  y = -913.66,  z = 19.21 },
}

local DEFAULT_DELIVERIES = {
    { x = 128.75,   y = -1288.36, z = 29.26, h = 30.0,  npcName = "Marcel" },
    { x = -1487.55, y = -378.13,  z = 39.16, h = 130.0, npcName = "Sophie" },
    { x = 373.87,   y = 326.36,   z = 103.56, h = 250.0, npcName = "Karim" },
    { x = -1193.12, y = -893.09,  z = 13.86, h = 30.0,  npcName = "Yann" },
    { x = 1136.02,  y = -982.13,  z = 45.41, h = 275.0, npcName = "Nadia" },
    { x = -47.79,   y = -1758.36, z = 29.42, h = 50.0,  npcName = "Bruno" },
    { x = 1961.30,  y = 3740.24,  z = 32.34, h = 300.0, npcName = "Léa" },
    { x = 1728.66,  y = 6415.06,  z = 35.04, h = 240.0, npcName = "Roger" },
}

local dbPickups = nil
local dbDeliveries = nil

local function loadPoints()
    local rows = MySQL.query.await("SELECT * FROM ltd_delivery_points") or {}
    local pickups, deliveries = {}, {}
    for i = 1, #rows do
        local row = rows[i]
        local point = {
            x = row.x + 0.0,
            y = row.y + 0.0,
            z = row.z + 0.0,
            h = (row.h or 0.0) + 0.0,
            npcName = row.npc_name or "Client",
            npcModel = row.npc_model or "a_m_m_indian_01",
            society = row.society or "",
        }
        if row.kind == "pickup" then
            pickups[#pickups + 1] = point
        else
            deliveries[#deliveries + 1] = point
        end
    end
    dbPickups = pickups
    dbDeliveries = deliveries
end

local function pickupPool(society)
    if dbPickups == nil then pcall(loadPoints) end
    local pool = {}
    if dbPickups then
        for i = 1, #dbPickups do
            local p = dbPickups[i]
            if p.society == "" or p.society == society then pool[#pool + 1] = p end
        end
    end
    if #pool == 0 then return DEFAULT_PICKUPS end
    return pool
end

local function deliveryPool(society)
    if dbDeliveries == nil then pcall(loadPoints) end
    local pool = {}
    if dbDeliveries then
        for i = 1, #dbDeliveries do
            local p = dbDeliveries[i]
            if p.society == "" or p.society == society then pool[#pool + 1] = p end
        end
    end
    if #pool == 0 then return DEFAULT_DELIVERIES end
    return pool
end

local function ltdImage()
    if VFW and VFW.CDN and VFW.CDN.Get then
        local ok, url = pcall(VFW.CDN.Get, "banners/ltd.png")
        if ok and type(url) == "string" then return url end
    end
    return ""
end

local function societyConfig(jobName)
    local job = VFW.Jobs and VFW.Jobs[jobName]
    if not job or job.type ~= "ltd" then return nil end

    local defaults = LTDDelivery and LTDDelivery.Config or {}
    return {
        vehicle = Feat27.Society.GetAddonString(jobName, "vehicle", defaults.DefaultVehicle or "speedo"),
        pricePerBox = Feat27.Society.GetAddonNumber(jobName, "pricePerBox", defaults.DefaultPricePerBox or 150),
        pricePerBoxSociety = Feat27.Society.GetAddonNumber(jobName, "pricePerBoxSociety", defaults.DefaultPricePerBoxSociety or 50),
        label = job.label or jobName,
    }
end

local function pickPoint(pool, previous)
    if #pool == 0 then return nil end
    if #pool == 1 then return pool[1] end
    local choice = pool[math.random(1, #pool)]
    local guard = 0
    while previous and choice.x == previous.x and choice.y == previous.y and guard < 8 do
        choice = pool[math.random(1, #pool)]
        guard = guard + 1
    end
    return choice
end

local function buildStep(mission)
    local pickup = pickPoint(pickupPool(mission.jobName), mission.pickup)
    local delivery = pickPoint(deliveryPool(mission.jobName), mission.delivery)
    if not pickup or not delivery then return nil end

    mission.pickup = { x = pickup.x, y = pickup.y, z = pickup.z }
    mission.delivery = {
        x = delivery.x,
        y = delivery.y,
        z = delivery.z,
        npcName = delivery.npcName or "Client",
    }
    mission.npcModel = delivery.npcModel or (LTDDelivery and LTDDelivery.Config and LTDDelivery.Config.DefaultNpcModel) or "a_m_m_indian_01"
    mission.npcHeading = delivery.h or 0.0
    mission.phase = "pickup"
    mission.boxInTrunk = nil
    mission.boxHolder = nil
    return mission
end

local function syncNpc(owner, mission)
    TriggerClientEvent("fl_ltd:syncDeliveryNpc", -1, owner, {
        model = mission.npcModel,
        name = mission.delivery.npcName,
        coords = mission.delivery,
        heading = mission.npcHeading,
    })
end

local function dropGroundBox(owner, mission, coords)
    mission.boxOnGround = coords
    mission.boxHolder = nil
    TriggerClientEvent("fl_ltd:boxDropped", -1, owner, coords)
end

local function clearMission(owner, reason)
    local mission = missions[owner]
    if not mission then return end
    missions[owner] = nil
    TriggerClientEvent("fl_ltd:unregisterDeliveryNpc", -1, owner)
    TriggerClientEvent("fl_ltd:boxPickedUp", -1, owner)
    if reason then
        TriggerClientEvent("fl_ltd:missionCancelled", owner, reason)
    end
end

local function findBoxOwner(xPlayer)
    local item = Feat27.Inv.Entry(xPlayer, BOX_ITEM)
    if not item or item.count < 1 then return nil end
    local meta = item.metadata or item.meta
    if type(meta) == "table" and tonumber(meta.missionOwner) then
        return tonumber(meta.missionOwner)
    end
    return nil
end

RegisterServerCallback("fl_ltd:getMissionState", function(source)
    local mission = missions[source]
    if not mission then
        return { active = false, delivered = 0 }
    end
    return { active = true, delivered = mission.delivered or 0 }
end)

RegisterServerCallback("fl_ltd:getSocietyConfig", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    return societyConfig(xPlayer.job.name)
end)

RegisterServerCallback("fl_ltd:startMission", function(source)
    local src = source

    if not Feat27.RateLimit(src, "ltd:start", 1500) then
        return false, "Veuillez patienter un instant."
    end

    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return false, "Joueur introuvable." end

    if missions[src] then
        return false, "Une mission est déjà en cours."
    end

    local config = societyConfig(xPlayer.job.name)
    if not config then
        return false, "Votre société n'est pas une entreprise de livraison."
    end

    local ped = GetPlayerPed(src)
    local vehicle = ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    if not vehicle or vehicle == 0 then
        return false, "Vous devez être dans un véhicule de service."
    end

    local mission = {
        owner = src,
        identifier = xPlayer.identifier,
        jobName = xPlayer.job.name,
        label = config.label,
        vehicle = config.vehicle,
        pricePerBox = config.pricePerBox,
        pricePerBoxSociety = config.pricePerBoxSociety,
        image = ltdImage(),
        delivered = 0,
    }

    if not buildStep(mission) then
        return false, "Aucun point de livraison disponible."
    end

    missions[src] = mission
    syncNpc(src, mission)
    dropGroundBox(src, mission, mission.pickup)

    return true, {
        jobName = mission.jobName,
        label = mission.label,
        pickup = mission.pickup,
        delivery = mission.delivery,
        vehicle = mission.vehicle,
        image = mission.image,
    }
end)

RegisterServerCallback("fl_ltd:nextDelivery", function(source)
    local src = source
    local mission = missions[src]
    if not mission then return false, "Aucune mission en cours." end
    if not Feat27.RateLimit(src, "ltd:next", 800) then return false, "Veuillez patienter." end

    if not buildStep(mission) then
        return false, "Aucun point de livraison disponible."
    end

    syncNpc(src, mission)
    dropGroundBox(src, mission, mission.pickup)

    return true, { pickup = mission.pickup, delivery = mission.delivery }
end)

RegisterServerCallback("fl_ltd:endMission", function(source)
    local src = source
    local mission = missions[src]
    if not mission then return false, "Aucune mission en cours." end

    local xPlayer = VFW.GetPlayerFromId(src)
    local delivered = mission.delivered or 0

    if xPlayer then
        local item = Feat27.Inv.Entry(xPlayer, BOX_ITEM)
        if item and item.count > 0 then
            Feat27.Inv.Take(xPlayer, BOX_ITEM, item.count, false)
        end
    end

    clearMission(src)
    return true, delivered
end)

RegisterServerCallback("fl_ltd:giveBoxItem", function(source, missionOwner)
    local src = source
    local owner = tonumber(missionOwner)
    if not owner then return false end
    if not Feat27.RateLimit(src, "ltd:giveBox", 600) then return false end

    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return false end

    local mission = missions[owner]
    if not mission then return false end
    if not mission.boxOnGround then return false end

    local coords = Feat27.PlayerCoords(src)
    if not coords or #(coords - Feat27.Vec3(mission.boxOnGround)) > 6.0 then return false end

    if Feat27.Inv.Entry(xPlayer, BOX_ITEM) then return false end
    if not Feat27.Inv.CanCarry(xPlayer, BOX_ITEM, 1) then
        Feat27.NotifyError(src, "Votre inventaire est plein.")
        return false
    end

    local ok = Feat27.Inv.Give(xPlayer, BOX_ITEM, 1, {
        missionOwner = owner,
        vehicleModel = mission.vehicle,
        jobLabel = mission.label,
    }, false)
    if not ok then return false end

    mission.boxOnGround = nil
    mission.boxHolder = src
    mission.phase = "delivery"

    TriggerClientEvent("fl_ltd:boxPickedUp", -1, owner)
    syncNpc(owner, mission)
    return true
end)

RegisterServerCallback("fl_ltd:removeBoxItem", function(source, coords)
    local src = source
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return false end

    local owner = findBoxOwner(xPlayer)
    if not owner then return false end

    if not Feat27.Inv.Take(xPlayer, BOX_ITEM, 1, false) then return false end

    local mission = missions[owner]
    if not mission then return true end

    if Feat27.IsVec(coords) then
        local pos = Feat27.Plain(coords)
        dropGroundBox(owner, mission, pos)
    else
        mission.boxHolder = nil
        mission.boxOnGround = nil
    end

    return true
end)

RegisterServerCallback("fl_ltd:putBoxInTrunk", function(source, plate)
    local src = source
    if type(plate) ~= "string" then return false end

    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return false end

    local owner = findBoxOwner(xPlayer)
    if not owner then return false end

    local mission = missions[owner]
    if not mission then return false end

    if not Feat27.Inv.Take(xPlayer, BOX_ITEM, 1, false) then return false end

    mission.boxInTrunk = plate
    mission.boxHolder = nil
    mission.boxOnGround = nil
    return true
end)

local function nearTrunkedBox(src, mission)
    if not mission.boxInTrunk then return false end
    local coords = Feat27.PlayerCoords(src)
    if not coords then return false end

    local vehicles = GetAllVehicles and GetAllVehicles() or {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if DoesEntityExist(vehicle) and GetVehicleNumberPlateText(vehicle) == mission.boxInTrunk then
            if #(coords - GetEntityCoords(vehicle)) <= 20.0 then return true end
        end
    end
    return false
end

RegisterServerCallback("fl_ltd:deliverBox", function(source)
    local src = source

    if not Feat27.RateLimit(src, "ltd:deliver", 1000) then
        return false, "Veuillez patienter un instant."
    end

    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return false, "Joueur introuvable." end

    local owner = findBoxOwner(xPlayer)
    local usedTrunk = false
    local mission

    if owner then
        mission = missions[owner]
    else
        mission = missions[src]
        if mission and nearTrunkedBox(src, mission) then
            owner = src
            usedTrunk = true
        else
            return false, "Vous n'avez pas de carton à livrer."
        end
    end

    if not mission then return false, "Cette mission n'existe plus." end

    local coords = Feat27.PlayerCoords(src)
    if not coords or #(coords - Feat27.Vec3(mission.delivery)) > 15.0 then
        return false, "Vous êtes trop loin du point de livraison."
    end

    if usedTrunk then
        mission.boxInTrunk = nil
    elseif not Feat27.Inv.Take(xPlayer, BOX_ITEM, 1, false) then
        return false, "Vous n'avez pas de carton à livrer."
    end

    mission.delivered = (mission.delivered or 0) + 1
    mission.phase = "waiting"
    mission.boxHolder = nil

    local payment = math.floor(tonumber(mission.pricePerBox) or 150)
    local tip = 0
    if math.random(1, 100) <= 25 then
        tip = math.floor(payment * (math.random(5, 20) / 100))
    end

    local total = payment + tip
    if total > 0 then
        xPlayer.addAccountMoney("money", total, "ltd-livraison")
    end
    Feat27.Society.AddMoney(mission.jobName, math.floor(tonumber(mission.pricePerBoxSociety) or 0), "ltd-livraison")

    MySQL.insert("INSERT INTO ltd_delivery_logs (`society`, `identifier`, `player_name`, `delivered`, `payment`, `tip`) VALUES (?, ?, ?, ?, ?, ?)", {
        mission.jobName, xPlayer.identifier, xPlayer.name or xPlayer.playerName, mission.delivered, payment, tip,
    })

    TriggerClientEvent("fl_ltd:deliveryNpcReceiveBox", -1, owner)

    local isOwner = (owner == src)
    local ownerXPlayer = VFW.GetPlayerFromId(owner)
    local ownerConnected = ownerXPlayer ~= nil

    if not isOwner and ownerConnected then
        TriggerClientEvent("fl_ltd:deliveryComplete", owner, mission.delivered, payment, mission.image, tip)
    end

    return true, mission.delivered, payment, mission.image, isOwner, ownerConnected, mission.label, tip
end)

RegisterServerCallback("fl_ltd:clearLogs", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local job = VFW.Jobs and VFW.Jobs[xPlayer.job.name]
    if not job or job.type ~= "ltd" then return false end
    if not Feat27.Society.IsBoss(xPlayer) and not xPlayer.hasPermission("gestion") then return false end

    local result = MySQL.query.await("DELETE FROM ltd_delivery_logs WHERE `society` = ?", { xPlayer.job.name })
    local affected = 0
    if type(result) == "table" then
        affected = tonumber(result.affectedRows) or 0
    elseif type(result) == "number" then
        affected = result
    end
    return affected + 1
end)

AddEventHandler("vfw:playerDropped", function(source)
    if missions[source] then
        clearMission(source)
    end
end)

AddEventHandler("vfw:setJob", function(source, job)
    local mission = missions[source]
    if not mission then return end
    if not job or job.name ~= mission.jobName then
        clearMission(source, "Vous avez changé de métier, la mission est annulée.")
    end
end)

AddEventHandler("vfw:playerLoaded", function(source)
    for owner, mission in pairs(missions) do
        syncNpc(owner, mission)
        if mission.boxOnGround then
            TriggerClientEvent("fl_ltd:boxDropped", source, owner, mission.boxOnGround)
        end
    end
end)

function Feat27.LtdCancelMission(owner, reason)
    clearMission(tonumber(owner), reason or "Mission annulée.")
end
