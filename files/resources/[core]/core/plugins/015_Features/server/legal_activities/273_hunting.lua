Feat27 = Feat27 or {}

local sessions = {}
local MUSKET = "WEAPON_MUSKET"

local function huntingConfig()
    return (Config and Config.hunting) or { zones = {}, items = {}, animals = {} }
end

local function pickAnimal()
    local animals = huntingConfig().animals or {}
    if #animals == 0 then return "a_c_deer" end
    return animals[math.random(1, #animals)]
end

local function pickSpawn(zoneKey)
    local zone = huntingConfig().zones[zoneKey]
    if not zone or type(zone.spawns) ~= "table" or #zone.spawns == 0 then return nil end
    return zone.spawns[math.random(1, #zone.spawns)]
end

local function meatPrices()
    local out = {}
    local items = huntingConfig().items or {}
    for _, entry in pairs(items) do
        if type(entry) == "table" and entry.name then
            out[entry.name] = tonumber(entry.price) or 0
        end
    end
    return out
end

local function giveMusket(xPlayer)
    if xPlayer.hasWeapon(MUSKET) then
        xPlayer.addWeaponAmmo(MUSKET, 20)
        return
    end
    xPlayer.addWeapon(MUSKET, 20)
end

local function removeMusket(xPlayer)
    if xPlayer.hasWeapon(MUSKET) then
        xPlayer.removeWeapon(MUSKET)
    end
    if Feat27.Inv.Has(xPlayer, "weapon_musket", 1) then
        Feat27.Inv.Take(xPlayer, "weapon_musket", 1, false)
    end
end

local function stopHunting(source, notifyClient)
    local session = sessions[source]
    if not session then return end

    if session.vehicleNetId then
        Feat27.DeleteNet(session.vehicleNetId)
    end

    sessions[source] = nil

    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer then removeMusket(xPlayer) end

    if notifyClient ~= false then
        TriggerClientEvent("core:hunting:client:stop", source)
    end
end

RegisterNetEvent("core:hunting:server:start", function(zone)
    local source = source
    if type(zone) ~= "string" then return end
    if not Feat27.RateLimit(source, "hunting:start", 2000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local zoneConfig = huntingConfig().zones[zone]
    if not zoneConfig then
        Feat27.NotifyError(source, "Zone de chasse inconnue.")
        return
    end

    if sessions[source] then
        Feat27.NotifyError(source, "Vous êtes déjà en activité de chasse.")
        return
    end

    local coords = Feat27.PlayerCoords(source)
    local zonePos = Feat27.Vec3(zoneConfig.position)
    if zonePos and coords and #(coords - zonePos) > 150.0 then
        Feat27.NotifyError(source, "Vous devez être au point de chasse.")
        return
    end

    local vehicleNetId = nil
    local spots = zoneConfig.spawnVehicle
    if type(spots) == "table" and #spots > 0 then
        local spot = spots[math.random(1, #spots)]
        vehicleNetId = Feat27.SpawnVehicle("bison", spot, spot.w or 0.0)
    end

    local spawn = pickSpawn(zone)
    if not spawn then
        Feat27.NotifyError(source, "Aucun animal disponible dans cette zone.")
        if vehicleNetId then Feat27.DeleteNet(vehicleNetId) end
        return
    end

    local animal = pickAnimal()

    sessions[source] = {
        zone = zone,
        animal = animal,
        position = Feat27.Plain(spawn),
        vehicleNetId = vehicleNetId,
        startedAt = GetGameTimer(),
    }

    giveMusket(xPlayer)

    TriggerClientEvent("core:hunting:client:start", source, Feat27.Vec3(spawn), animal, vehicleNetId or 0)
end)

RegisterNetEvent("core:hunting:server:stop", function()
    local source = source
    stopHunting(source, true)
end)

RegisterNetEvent("core:hunting:server:removeWeapon", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if sessions[source] then return end
    removeMusket(xPlayer)
end)

RegisterNetEvent("core:hunting:server:collect", function()
    local source = source
    if not Feat27.RateLimit(source, "hunting:collect", 3000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local session = sessions[source]
    if not session then return end

    local coords = Feat27.PlayerCoords(source)
    local animalPos = Feat27.Vec3(session.position)
    if not coords or not animalPos or #(coords - animalPos) > 150.0 then
        Feat27.NotifyError(source, "Vous devez être auprès de l'animal.")
        return
    end

    local items = huntingConfig().items or {}
    local reward = items[session.animal]
    if not reward or not reward.name then return end

    if not Feat27.Inv.CanCarry(xPlayer, reward.name, 1) then
        Feat27.NotifyError(source, "Votre inventaire est plein.")
        return
    end

    Feat27.Inv.Give(xPlayer, reward.name, 1, nil, true)
    LegalActivities.Log(xPlayer.identifier, "hunting", reward.name, 1, 0, "none")

    TriggerClientEvent("core:hunting:client:collected", source)

    local spawn = pickSpawn(session.zone)
    if not spawn then return end

    session.animal = pickAnimal()
    session.position = Feat27.Plain(spawn)

    SetTimeout(2000, function()
        if sessions[source] then
            TriggerClientEvent("core:hunting:client:new", source, Feat27.Vec3(spawn), session.animal)
        end
    end)
end)

RegisterServerCallback("core:legal_activities:hunting:getMyMeats", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local out = {}
    for name, price in pairs(meatPrices()) do
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

RegisterNetEvent("core:legal_activities:hunting:resell", function(name, count, paymentType)
    local source = source
    if type(name) ~= "string" then return end

    local amount = math.floor(tonumber(count) or 0)
    if amount <= 0 then return end
    if not Feat27.RateLimit(source, "hunting:sell", 400) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local price = meatPrices()[name]
    if not price or price <= 0 then return end

    if Feat27.Inv.Count(xPlayer, name) < amount then
        Feat27.NotifyError(source, "Vous n'avez pas assez de viande.")
        return
    end

    if not Feat27.Inv.Take(xPlayer, name, amount, false) then return end

    local total = math.floor(price * amount)
    LegalActivities.Pay(xPlayer, total, paymentType, "chasse-revente")
    LegalActivities.Log(xPlayer.identifier, "hunting", name, amount, total, paymentType)
    Feat27.NotifyOk(source, ("Vous avez vendu %d viande%s pour %d$."):format(amount, amount > 1 and "s" or "", total))
end)

AddEventHandler("vfw:playerDropped", function(source)
    stopHunting(source, false)
end)
