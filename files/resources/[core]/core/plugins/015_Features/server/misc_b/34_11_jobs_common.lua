local function hasKit(source, item)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.haveItem(item, 1) == true
end

MiscB.Cb("core:mechanic:hasRepairKit", function(source)
    return hasKit(source, "repairkit") or hasKit(source, "fastrepairkit")
end)

MiscB.Cb("core:mechanic:hasCleanKit", function(source)
    return hasKit(source, "cleankit")
end)

MiscB.Cb("core:mechanic:hasCarroserieKit", function(source)
    return hasKit(source, "kitcarrosserie")
end)

MiscB.Cb("core:mechanic:hasCrochetageKit", function(source)
    return hasKit(source, "kit_de_crochetage_veh") or hasKit(source, "kit_de_crochetage")
end)

local function consumeFirst(xPlayer, items)
    for i = 1, #items do
        if xPlayer.haveItem(items[i], 1) then
            if xPlayer.removeInventoryItem(items[i], 1) then return true end
        end
    end
    return false
end

RegisterNetEvent("core:mechanic:repairEngine", function(netId)
    local source = source
    local net = tonumber(netId)
    if not net then return end
    if not MiscB.Rate(source, "repairengine", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not consumeFirst(xPlayer, { "repairkit", "fastrepairkit" }) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de kit de reparation." })
        return
    end

    TriggerClientEvent("core:mechanic:repairEngine:apply", -1, net)
end)

RegisterNetEvent("core:mechanic:repairBodywork", function(netId, engineHealth)
    local source = source
    local net = tonumber(netId)
    if not net then return end
    if not MiscB.Rate(source, "repairbody", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not consumeFirst(xPlayer, { "kitcarrosserie" }) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de kit de carrosserie." })
        return
    end

    local health = MiscB.ToNum(engineHealth, 1000.0)
    TriggerClientEvent("core:mechanic:repairBodywork:apply", -1, net, health)
end)

RegisterNetEvent("core:mechanic:cleanVehicle", function(netId)
    local source = source
    local net = tonumber(netId)
    if not net then return end
    if not MiscB.Rate(source, "cleanveh", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not consumeFirst(xPlayer, { "cleankit" }) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de kit de nettoyage." })
        return
    end

    TriggerClientEvent("core:mechanic:cleanVehicle:apply", -1, net)
end)

local VEHICLE_REACH = 8.0

local function trimPlate(plate)
    return (plate:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function canDeleteVehicles(xPlayer)
    return xPlayer.hasPermission("dv") or xPlayer.hasPermission("alt_delete_entity")
end

local function vehicleWithinReach(source, plate)
    local vehicles = VFW.Vehicles
    if not vehicles or not vehicles.FindEntityByPlate then return false end

    local entity = vehicles.FindEntityByPlate(plate)
    if not entity or not DoesEntityExist(entity) then return false end

    local coords = MiscB.PlayerCoords(source)
    if not coords then return false end

    return MiscB.Dist(coords, GetEntityCoords(entity)) <= VEHICLE_REACH
end

local function ownedRow(plate)
    local vehicles = VFW.Vehicles
    if not vehicles or not vehicles.GetByPlate then return nil end

    local normalized = vehicles.NormalizePlate and vehicles.NormalizePlate(plate) or plate
    return vehicles.GetByPlate(normalized) or vehicles.GetByPlate(plate)
end

RegisterNetEvent("vfw:mechanic:impound", function(plate)
    local source = source
    if type(plate) ~= "string" or #plate > 12 then return end
    if not MiscB.Rate(source, "impound", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local staffDelete = canDeleteVehicles(xPlayer)
    if not staffDelete
        and not MiscB.IsLawEnforcement(xPlayer)
        and not MiscB.HasJob(xPlayer, { "mechanic", "mecano", "bennys" }) then
        return
    end

    local normalized = trimPlate(plate)

    if not staffDelete and not vehicleWithinReach(source, normalized) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous devez être à proximité du véhicule." })
        return
    end

    local row = ownedRow(normalized)
    if not row then return end

    if row.pounded == 1 then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Ce véhicule est déjà en fourrière." })
        return
    end

    if not staffDelete and row.stored == 1 then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Ce véhicule est rangé dans un garage." })
        return
    end

    MiscB.Update("UPDATE owned_vehicles SET pounded = 1, stored = 0 WHERE plate = ?", { row.plate })
    VFW.ShowNotification(source, { type = "VERT", content = "Vehicule mis en fourriere." })
end)

local tempKeys = {}

local function grantTemporaryKey(source, xPlayer, kind, plate)
    tempKeys[plate] = tempKeys[plate] or {}
    tempKeys[plate][tostring(source)] = kind

    Player(source).state:set("tempVehicleKey:" .. plate, kind, true)
    TriggerClientEvent("vfw:vehicle:keyTemporarly:added", source, kind, plate)
    TriggerEvent("vfw:vehicle:tempKeyAdded", source, kind, plate, xPlayer.identifier)
end

local function alreadyGranted(source, xPlayer, plate)
    local holders = tempKeys[plate]
    if holders and holders[tostring(source)] ~= nil then return true end

    if Staff29 and Staff29.HasTemporaryVehicleKey then
        return Staff29.HasTemporaryVehicleKey(plate, xPlayer.identifier) == true
    end

    return false
end

RegisterNetEvent("vfw:vehicle:keyTemporarly:add", function(keyType, plate)
    local source = source
    if type(plate) ~= "string" or #plate > 12 then return end
    if not MiscB.Rate(source, "tempKeyAdd", 1000) then return end

    local kind = MiscB.Str(keyType, 16) or "job"

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local normalized = trimPlate(plate)
    if not alreadyGranted(source, xPlayer, normalized) then return end

    grantTemporaryKey(source, xPlayer, kind, normalized)
end)

local function canClearVehicleKeys(source, xPlayer, plate, holders)
    if holders[tostring(source)] ~= nil then return true end
    if canDeleteVehicles(xPlayer) then return true end

    if not MiscB.IsLawEnforcement(xPlayer)
        and not MiscB.HasJob(xPlayer, { "mechanic", "mecano", "bennys" }) then
        return false
    end

    return vehicleWithinReach(source, plate)
end

RegisterNetEvent("vfw:vehicle:keyTemporarly:remove", function(keyType, plate)
    local source = source
    if type(plate) ~= "string" or #plate > 12 then return end
    if not MiscB.Rate(source, "tempKeyRemove", 1000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local normalized = plate:gsub("^%s+", ""):gsub("%s+$", "")
    local holders = tempKeys[normalized]
    if not holders then return end

    if not canClearVehicleKeys(source, xPlayer, normalized, holders) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas les clés de ce véhicule." })
        return
    end

    tempKeys[normalized] = nil
    for src in pairs(holders) do
        local target = tonumber(src)
        if target and VFW.GetPlayerFromId(target) then
            Player(target).state:set("tempVehicleKey:" .. normalized, nil, true)
        end
    end

    TriggerClientEvent("vfw:vehicle:keyTemporarly:removed", -1, normalized)
    TriggerEvent("vfw:vehicle:tempKeyRemoved", normalized)
end)

RegisterNetEvent("core:deletesyncItem", function(netId)
    local source = source
    local net = tonumber(netId)
    if not net then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entity = NetworkGetEntityFromNetworkId(net)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    local entityType = GetEntityType(entity)
    if entityType ~= 2 and entityType ~= 3 then return end

    local coords = MiscB.PlayerCoords(source)
    if not coords or MiscB.Dist(coords, GetEntityCoords(entity)) > VEHICLE_REACH then return end

    DeleteEntity(entity)
    TriggerClientEvent("core:deletesyncItemC", -1, net)
end)

RegisterNetEvent("core:recupHerse", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "herse", 800) then return end
    if not xPlayer.canCarryItem("herse", 1) then return end
    xPlayer.addInventoryItem("herse", 1)
end)

local vehAttachees = {}

RegisterNetEvent("core:GetVehAttachee", function()
    local source = source
    TriggerClientEvent("core:VehAttachee", source, vehAttachees)
end)

RegisterNetEvent("core:AddVehAttachee", function(towNetId, vehNetId)
    local source = source
    local tow, veh = tonumber(towNetId), tonumber(vehNetId)
    if not tow or not veh then return end

    vehAttachees[tostring(tow)] = veh
    TriggerClientEvent("core:VehAttachee", -1, vehAttachees)
end)

RegisterNetEvent("core:DeleteVehAttachee", function(towNetId)
    local source = source
    local tow = tonumber(towNetId)
    if not tow then return end

    vehAttachees[tostring(tow)] = nil
    TriggerClientEvent("core:VehAttachee", -1, vehAttachees)
end)

MiscB.Cb("core:jobs:server:getVeh", function(source, plate)
    if type(plate) ~= "string" or #plate > 12 then return nil, nil end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil, nil end

    local normalized = plate:gsub("^%s+", ""):gsub("%s+$", "")
    local row = MiscB.Single([[
        SELECT c.firstname, c.lastname FROM owned_vehicles v
        LEFT JOIN characters c ON c.identifier = v.owner
        WHERE v.plate = ? LIMIT 1
    ]], { normalized })

    if not row then return nil, nil end
    return row.firstname or "", row.lastname or ""
end)

MiscB.Cb("core:jobs:server:haveKit", function(source, kind)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    if kind == "revive" then
        return xPlayer.haveItem("medikit", 1) or xPlayer.haveItem("medikit_sams", 1)
    end
    return xPlayer.haveItem("bandage", 1) or xPlayer.haveItem("medikit", 1)
end)

RegisterNetEvent("core:jobs:server:HealthPlayer", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end
    if not MiscB.Rate(source, "healplayer", 2000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if not consumeFirst(xPlayer, { "bandage", "medikit" }) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de bandage." })
        return
    end

    local ped = GetPlayerPed(target)
    local health = ped ~= 0 and GetEntityHealth(ped) or 200
    TriggerClientEvent("core:jobs:client:HealthPlayer", target, math.min(200, health + 50))
end)

RegisterNetEvent("core:jobs:server:RevivePlayer", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end
    if not MiscB.Rate(source, "revive", 4000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if not consumeFirst(xPlayer, { "medikit_sams", "medikit" }) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de kit de reanimation." })
        return
    end

    xTarget.revive()
end)

RegisterNetEvent("core:jobs:server:reviveanimrevived", function(targetServerId, heading, coords, location)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end
    if not VFW.GetPlayerFromId(target) then return end

    TriggerClientEvent("core:jobs:client:reviveanimrevived", target,
        MiscB.ToNum(heading, 0.0), MiscB.Plain(coords), location, source)
end)

RegisterNetEvent("core:jobs:server:reviveanimreviver", function(players)
    local source = source
    local target = tonumber(players)
    if not target then return end
    TriggerClientEvent("core:jobs:client:reviveanimreviver", source, target)
end)

RegisterNetEvent("vfw:server:nurse:heal", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "nurse", 10000) then return end

    local price = 250
    local account = xPlayer.getAccount("bank")
    local balance = type(account) == "table" and (account.money or account.amount or 0) or (tonumber(account) or 0)
    if balance < price then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Fonds insuffisants pour payer les soins." })
        return
    end

    xPlayer.removeAccountMoney("bank", price, "infirmerie")
    xPlayer.revive()
    VFW.ShowNotification(source, { type = "VERT", content = "Vous avez ete soigne (" .. price .. "$)." })
end)

local activeCalls = {}
local callSeq = 0

RegisterNetEvent("core:alert:makeCall", function(jobName, coords, isSilent, message, unknown, category)
    local source = source
    local job = MiscB.Str(jobName, 64)
    local pos = MiscB.Plain(coords)
    local msg = MiscB.Str(message, 220) or ""
    if not job or not pos then return end
    if not MiscB.Rate(source, "alertcall", 1200) then return end

    local xPlayer = VFW.GetPlayerFromId(source)

    local targetData = { name = "" }
    if xPlayer and unknown ~= true then
        targetData.name = MiscB.CharName(xPlayer)
        targetData.source = source
    end

    callSeq = callSeq + 1
    local callId = callSeq
    activeCalls[callId] = {
        id = callId,
        job = job,
        pos = pos,
        targetData = targetData,
        message = msg,
        category = MiscB.Str(category, 32),
        createdAt = os.time(),
    }

    local receivers = MiscB.PlayersWithJobs(job)
    local sent = 0
    for i = 1, #receivers do
        local receiver = receivers[i]
        if receiver and receiver.source ~= source and MiscB.OnDuty(receiver) then
            TriggerClientEvent("core:alert:callIncoming", receiver.source, job, pos, targetData, msg, activeCalls[callId].category)
            sent = sent + 1
        end
    end

    if sent == 0 and isSilent ~= true and xPlayer then
        TriggerClientEvent("core:alert:takeCall", source, "noAnswer")
    end
end)

RegisterNetEvent("core:alert:callAccept", function(job, pos, targetData, category)
    local source = source
    local jobName = MiscB.Str(job, 64)
    local coords = MiscB.Plain(pos)
    if not jobName or not coords then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    TriggerClientEvent("core:alert:callAccepted", source, coords, MiscB.Str(category, 32))

    if type(targetData) == "table" and tonumber(targetData.source) then
        local caller = tonumber(targetData.source)
        if VFW.GetPlayerFromId(caller) then
            TriggerClientEvent("core:alert:takeCall", caller, "callTake")
        end
    end
end)

RegisterNetEvent("core:logs:shooting", function(weaponLabel, coords)
    local source = source
    local label = MiscB.Str(weaponLabel, 96) or "?"
    local pos = MiscB.Plain(coords)
    if not pos then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if VFW.Logs and VFW.Logs.Simple then
        VFW.Logs.Simple("general.shooting", "Tir",
            ("%s a tire avec %s en %.1f %.1f %.1f"):format(MiscB.CharName(xPlayer), label, pos.x, pos.y, pos.z))
    end
end)

RegisterNetEvent("core:testPoudre", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.setMeta("gunpowder", os.time())
end)

local douilles = {}
local douilleSeq = 0

RegisterNetEvent("core:jobs:server:shootingcases", function(coords, weaponGroup, lastWeaponId)
    local source = source
    local pos = MiscB.Plain(coords)
    if not pos then return end
    if not MiscB.Rate(source, "douille", 500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    douilleSeq = douilleSeq + 1
    local data = {
        id = douilleSeq,
        pos = pos,
        time = os.time(),
        typeAmmo = tonumber(weaponGroup) or 0,
        weaponId = lastWeaponId,
        owner = xPlayer.identifier,
        ownerName = MiscB.CharName(xPlayer),
    }
    douilles[douilleSeq] = data

    local nearby = VFW.GetPlayersInRadius(vector3(pos.x, pos.y, pos.z), 150.0)
    for i = 1, #nearby do
        TriggerClientEvent("core:jobs:client:shootingcases", nearby[i].source, data)
    end
end)

RegisterNetEvent("core:jobs:server:addDouille", function(data)
    local source = source
    if type(data) ~= "table" then return end
    local id = MiscB.ToInt(data.id, 1)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local stored = douilles[id]
    if not stored then return end
    douilles[id] = nil

    if not xPlayer.canCarryItem("douille", 1) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Inventaire plein." })
        return
    end

    xPlayer.addInventoryItem("douille", 1, {
        time = stored.time,
        typeAmmo = stored.typeAmmo,
        owner = stored.ownerName,
        identifier = stored.owner,
    })
end)

local trafficZones = {}
local trafficLoaded = false
local trafficLoading = false

local function loadTraffic()
    if trafficLoaded then return end
    if trafficLoading then
        local waited = 0
        while not trafficLoaded and waited < 5000 do
            Wait(10)
            waited = waited + 10
        end
        return
    end
    trafficLoading = true
    local rows = MiscB.Query("SELECT id, job, data FROM job_traffic_zones", {})
    for i = 1, #rows do
        local zone = VFW.DB.Decode(rows[i].data, {})
        if type(zone) == "table" then
            zone.id = rows[i].id
            zone.job = rows[i].job
            trafficZones[rows[i].id] = zone
        end
    end
    trafficLoaded = true
    trafficLoading = false
end

MiscB.Cb("core:jobs:traffic:get", function(source)
    loadTraffic()
    local out = {}
    for _, zone in pairs(trafficZones) do
        out[#out + 1] = zone
    end
    return out
end)

RegisterNetEvent("core:jobs:traffic:add", function(zone)
    local source = source
    if type(zone) ~= "table" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end

    loadTraffic()
    local id = MiscB.Insert("INSERT INTO job_traffic_zones (job, data) VALUES (?, ?)",
        { MiscB.JobName(xPlayer) or "", VFW.DB.Encode(zone) })
    if not id then return end

    zone.id = id
    zone.job = MiscB.JobName(xPlayer)
    trafficZones[id] = zone

    TriggerClientEvent("core:jobs:traffic:addclient", -1, zone)
end)

RegisterNetEvent("core:jobs:traffic:remove", function(zoneId)
    local source = source
    local id = MiscB.ToInt(zoneId, 1)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end

    loadTraffic()
    trafficZones[id] = nil
    MiscB.Update("DELETE FROM job_traffic_zones WHERE id = ?", { id })
    TriggerClientEvent("core:jobs:traffic:removeclient", -1, id)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    CreateThread(function()
        Wait(4000)
        loadTraffic()
        for _, zone in pairs(trafficZones) do
            TriggerClientEvent("core:jobs:traffic:addclient", source, zone)
        end
    end)
end)

local bracelets = {}

RegisterNetEvent("core:jobs:setBracelet", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end
    if not MiscB.Rate(source, "bracelet", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not MiscB.IsLawEnforcement(xPlayer) then return end

    local status = not bracelets[xTarget.identifier]
    if status then
        bracelets[xTarget.identifier] = { source = target, since = os.time() }
    else
        bracelets[xTarget.identifier] = nil
    end

    xTarget.setMeta("bracelet", status)
    TriggerClientEvent("core:jobs:setBracelet", target, status)
    VFW.ShowNotification(source, { type = "VERT", content = status and "Bracelet pose." or "Bracelet retire." })
end)

local braceletBlips = {}

RegisterNetEvent("core:jobs:activeBlips", function(activeState)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end
    braceletBlips[source] = activeState == true
end)

MiscB.Cb("police:getBraceletPlayers", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return {} end

    local out = {}
    for identifier, data in pairs(bracelets) do
        local xTarget = VFW.GetPlayerFromIdentifier(identifier)
        if xTarget then
            local coords = xTarget.getCoords()
            out[#out + 1] = {
                serverId = xTarget.source,
                identifier = identifier,
                name = MiscB.CharName(xTarget),
                online = true,
                x = coords.x, y = coords.y, z = coords.z,
                since = data.since,
            }
        else
            out[#out + 1] = {
                identifier = identifier,
                name = identifier,
                online = false,
                x = 0.0, y = 0.0, z = 0.0,
                since = data.since,
            }
        end
    end
    return out
end)

MiscB.Cb("police:braceletShock", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local target = tonumber(data.serverId or data.targetId)
    if not target or not VFW.GetPlayerFromId(target) then return { success = false } end

    TriggerClientEvent("police:braceletShock", target)
    return { success = true }
end)

MiscB.Cb("police:braceletMessage", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return { success = false } end
    if type(data) ~= "table" then return { success = false } end

    local target = tonumber(data.serverId or data.targetId)
    local message = MiscB.Str(data.message, 300)
    if not target or not message or not VFW.GetPlayerFromId(target) then return { success = false } end

    TriggerClientEvent("police:braceletMessage", target, message)
    return { success = true }
end)

local boots = {}

RegisterNetEvent("core:jobs:vehicle:applyBoot", function(vehicleNetId, propNetId, bone)
    local source = source
    local veh = tonumber(vehicleNetId)
    local prop = tonumber(propNetId)
    if not veh then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end

    local entity = NetworkGetEntityFromNetworkId(veh)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    boots[veh] = { prop = prop, bone = tonumber(bone) or 0 }

    local state = Entity(entity).state
    state:set("hasBoot", true, true)
    state:set("bootWheel", tonumber(bone) or 0, true)
    state:set("bootPropNet", prop, true)
end)

RegisterNetEvent("core:jobs:vehicle:updateBootProp", function(vehNet, propNet)
    local source = source
    local veh, prop = tonumber(vehNet), tonumber(propNet)
    if not veh or not prop then return end
    if not boots[veh] then return end

    boots[veh].prop = prop
    local entity = NetworkGetEntityFromNetworkId(veh)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        Entity(entity).state:set("bootPropNet", prop, true)
    end
end)

RegisterNetEvent("core:jobs:vehicle:removeBoot", function(vehicleNetId)
    local source = source
    local veh = tonumber(vehicleNetId)
    if not veh then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end

    boots[veh] = nil
    local entity = NetworkGetEntityFromNetworkId(veh)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        local state = Entity(entity).state
        state:set("hasBoot", false, true)
        state:set("bootWheel", nil, true)
        state:set("bootPropNet", nil, true)
    end

    TriggerClientEvent("core:jobs:vehicle:cleanupBoot", -1, veh)
end)

RegisterNetEvent("core:jobs:vehicle:returnSabot", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "sabot", 800) then return end
    if not xPlayer.canCarryItem("sabot", 1) then return end
    xPlayer.addInventoryItem("sabot", 1)
end)

MiscB.Cb("core:jobs:vehicle:useSabot", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if not xPlayer.haveItem("sabot", 1) then return false end
    return xPlayer.removeInventoryItem("sabot", 1) == true
end)

local armories = {}
local equipments = {}

local function loadArmories()
    armories = {}
    local rows = MiscB.Query("SELECT * FROM job_armories", {})
    for i = 1, #rows do
        local row = rows[i]
        armories[row.id] = {
            id = row.id,
            name = row.name,
            jobs = VFW.DB.Decode(row.jobs, {}),
            pos = VFW.DB.Decode(row.pos, nil),
            npcPos = VFW.DB.Decode(row.npc_pos, nil),
            npcModel = row.npc_model,
            blipEnabled = row.blip_enabled == 1,
            blipSprite = row.blip_sprite,
            blipColor = row.blip_color,
            blipScale = row.blip_scale,
            active = row.active == 1,
        }
    end
end

local function loadEquipments()
    equipments = {}
    local rows = MiscB.Query("SELECT * FROM job_equipments", {})
    for i = 1, #rows do
        local row = rows[i]
        equipments[row.id] = {
            id = row.id,
            name = row.name,
            jobs = VFW.DB.Decode(row.jobs, {}),
            pos = VFW.DB.Decode(row.pos, nil),
            npcPos = VFW.DB.Decode(row.npc_pos, nil),
            npcModel = row.npc_model,
            blipEnabled = row.blip_enabled == 1,
            blipSprite = row.blip_sprite,
            blipColor = row.blip_color,
            blipScale = row.blip_scale,
            active = row.active == 1,
        }
    end
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(3500)
    loadArmories()
    loadEquipments()
end)

RegisterNetEvent("core:jobArmory:requestSync", function()
    local source = source
    TriggerClientEvent("core:jobArmory:sync", source, armories)
end)

RegisterNetEvent("core:jobEquipment:requestSync", function()
    local source = source
    TriggerClientEvent("core:jobEquipment:sync", source, equipments)
end)

local function playerInArmory(xPlayer, armory)
    if not armory or type(armory.jobs) ~= "table" then return false end
    local job = MiscB.JobName(xPlayer)
    if not job then return false end
    for i = 1, #armory.jobs do
        if armory.jobs[i] == job then return true end
    end
    return false
end

local function buildStockList(rows, xPlayer)
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        if (tonumber(row.min_grade) or 0) <= MiscB.GradeLevel(xPlayer) then
            local playerCount = 0
            local item = xPlayer.getInventoryItem(row.item_name)
            if type(item) == "table" then playerCount = tonumber(item.count) or 0 end

            out[#out + 1] = {
                id = row.id,
                item_name = row.item_name,
                label = row.label,
                max_stock = row.max_stock,
                current_out = row.current_out or 0,
                available = math.max(0, (tonumber(row.max_stock) or 0) - (tonumber(row.current_out) or 0)),
                playerHas = playerCount > 0,
                playerHasCount = playerCount,
                maxPerPlayer = row.max_per_player or 1,
            }
        end
    end
    return out
end

MiscB.Cb("core:jobArmory:getWeaponsForPlayer", function(source, armoryId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {}, false end

    local id = MiscB.ToInt(armoryId, 1)
    local armory = id and armories[id] or nil
    if not armory or not playerInArmory(xPlayer, armory) then return {}, false end

    local rows = MiscB.Query("SELECT * FROM job_armory_weapons WHERE armory_id = ? ORDER BY id ASC", { id })
    return buildStockList(rows, xPlayer), MiscB.IsBoss(xPlayer)
end)

MiscB.Cb("core:jobEquipment:getItemsForPlayer", function(source, equipmentId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {}, false end

    local id = MiscB.ToInt(equipmentId, 1)
    local equipment = id and equipments[id] or nil
    if not equipment or not playerInArmory(xPlayer, equipment) then return {}, false end

    local rows = MiscB.Query("SELECT * FROM job_equipment_items WHERE equipment_id = ? ORDER BY id ASC", { id })
    return buildStockList(rows, xPlayer), MiscB.IsBoss(xPlayer)
end)

local function logArmory(armoryId, xPlayer, itemName, action, quantity)
    MiscB.Insert([[
        INSERT INTO job_armory_logs (armory_id, identifier, player_name, item_name, action, quantity, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ]], { armoryId, xPlayer.identifier, MiscB.CharName(xPlayer), itemName, action, quantity })
end

local function logEquipment(equipmentId, xPlayer, itemName, action, quantity)
    MiscB.Insert([[
        INSERT INTO job_equipment_logs (equipment_id, identifier, player_name, item_name, action, quantity, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ]], { equipmentId, xPlayer.identifier, MiscB.CharName(xPlayer), itemName, action, quantity })
end

MiscB.Cb("core:jobArmory:takeWeapon", function(source, weaponId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local id = MiscB.ToInt(weaponId, 1)
    if not id then return { success = false, message = "Cette arme n'est pas valide." } end

    local row = MiscB.Single("SELECT * FROM job_armory_weapons WHERE id = ? LIMIT 1", { id })
    if not row then return { success = false, message = "Arme introuvable." } end

    local armory = armories[row.armory_id]
    if not armory or not playerInArmory(xPlayer, armory) then
        return { success = false, message = "Acces refuse." }
    end
    if (tonumber(row.min_grade) or 0) > MiscB.GradeLevel(xPlayer) then
        return { success = false, message = "Grade insuffisant." }
    end
    if (tonumber(row.current_out) or 0) >= (tonumber(row.max_stock) or 0) then
        return { success = false, message = "Stock epuise." }
    end

    local item = xPlayer.getInventoryItem(row.item_name)
    local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
    if count >= (tonumber(row.max_per_player) or 1) then
        return { success = false, message = "Vous en avez deja assez." }
    end
    if not xPlayer.canCarryItem(row.item_name, 1) then
        return { success = false, message = "Inventaire plein." }
    end

    xPlayer.addInventoryItem(row.item_name, 1)
    MiscB.Update("UPDATE job_armory_weapons SET current_out = current_out + 1 WHERE id = ?", { id })
    logArmory(row.armory_id, xPlayer, row.item_name, "take", 1)

    return { success = true, message = "Arme recuperee." }
end)

MiscB.Cb("core:jobArmory:returnWeapon", function(source, weaponId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local id = MiscB.ToInt(weaponId, 1)
    if not id then return { success = false, message = "Cette arme n'est pas valide." } end

    local row = MiscB.Single("SELECT * FROM job_armory_weapons WHERE id = ? LIMIT 1", { id })
    if not row then return { success = false, message = "Arme introuvable." } end

    if not xPlayer.haveItem(row.item_name, 1) then
        return { success = false, message = "Vous n'avez pas cette arme." }
    end
    if not xPlayer.removeInventoryItem(row.item_name, 1) then
        return { success = false, message = "Impossible de rendre l'arme." }
    end

    MiscB.Update("UPDATE job_armory_weapons SET current_out = GREATEST(0, current_out - 1) WHERE id = ?", { id })
    logArmory(row.armory_id, xPlayer, row.item_name, "return", 1)

    return { success = true, message = "Arme rendue." }
end)

MiscB.Cb("core:jobArmory:getLogs", function(source, armoryId, limit)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    local id = MiscB.ToInt(armoryId, 1)
    if not id then return {} end
    local max = MiscB.ToInt(limit, 1, 200) or 50

    return MiscB.Query(
        "SELECT * FROM job_armory_logs WHERE armory_id = ? ORDER BY id DESC LIMIT " .. max,
        { id }
    )
end)

MiscB.Cb("core:jobEquipment:takeItem", function(source, itemId, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local id = MiscB.ToInt(itemId, 1)
    local qty = MiscB.ToInt(quantity, 1, 100) or 1
    if not id then return { success = false, message = "Cet item n'est pas valide." } end

    local row = MiscB.Single("SELECT * FROM job_equipment_items WHERE id = ? LIMIT 1", { id })
    if not row then return { success = false, message = "Item introuvable." } end

    local equipment = equipments[row.equipment_id]
    if not equipment or not playerInArmory(xPlayer, equipment) then
        return { success = false, message = "Acces refuse." }
    end
    if (tonumber(row.min_grade) or 0) > MiscB.GradeLevel(xPlayer) then
        return { success = false, message = "Grade insuffisant." }
    end

    local available = (tonumber(row.max_stock) or 0) - (tonumber(row.current_out) or 0)
    if available < qty then return { success = false, message = "Stock insuffisant." } end

    local item = xPlayer.getInventoryItem(row.item_name)
    local count = type(item) == "table" and (tonumber(item.count) or 0) or 0
    local maxPer = tonumber(row.max_per_player) or 1
    if count + qty > maxPer then
        return { success = false, message = "Quantite maximale atteinte." }
    end
    if not xPlayer.canCarryItem(row.item_name, qty) then
        return { success = false, message = "Inventaire plein." }
    end

    xPlayer.addInventoryItem(row.item_name, qty)
    MiscB.Update("UPDATE job_equipment_items SET current_out = current_out + ? WHERE id = ?", { qty, id })
    logEquipment(row.equipment_id, xPlayer, row.item_name, "take", qty)

    return { success = true, message = "Materiel recupere." }
end)

MiscB.Cb("core:jobEquipment:returnItem", function(source, itemId, quantity)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local id = MiscB.ToInt(itemId, 1)
    local qty = MiscB.ToInt(quantity, 1, 100) or 1
    if not id then return { success = false, message = "Cet item n'est pas valide." } end

    local row = MiscB.Single("SELECT * FROM job_equipment_items WHERE id = ? LIMIT 1", { id })
    if not row then return { success = false, message = "Item introuvable." } end

    if not xPlayer.haveItem(row.item_name, qty) then
        return { success = false, message = "Vous n'avez pas cet item." }
    end
    if not xPlayer.removeInventoryItem(row.item_name, qty) then
        return { success = false, message = "Impossible de rendre l'item." }
    end

    MiscB.Update("UPDATE job_equipment_items SET current_out = GREATEST(0, current_out - ?) WHERE id = ?", { qty, id })
    logEquipment(row.equipment_id, xPlayer, row.item_name, "return", qty)

    return { success = true, message = "Materiel rendu." }
end)

MiscB.Cb("core:jobEquipment:getLogs", function(source, equipmentId, limit)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsBoss(xPlayer) then return {} end

    local id = MiscB.ToInt(equipmentId, 1)
    if not id then return {} end
    local max = MiscB.ToInt(limit, 1, 200) or 50

    return MiscB.Query(
        "SELECT * FROM job_equipment_logs WHERE equipment_id = ? ORDER BY id DESC LIMIT " .. max,
        { id }
    )
end)

local policeGarages = {}

local function loadPoliceGarages()
    policeGarages = {}
    local rows = MiscB.Query("SELECT * FROM police_garages", {})
    for i = 1, #rows do
        local row = rows[i]
        policeGarages[row.id] = {
            id = row.id,
            name = row.name,
            job = row.job,
            position = VFW.DB.Decode(row.position, {}),
            spawnPositions = VFW.DB.Decode(row.spawn_positions, {}),
            despawnPosition = VFW.DB.Decode(row.despawn_position, {}),
            vehicles = VFW.DB.Decode(row.vehicles, {}),
            pedModel = row.ped_model,
        }
    end
end

local function garagesForJob(jobName)
    local out = {}
    for id, garage in pairs(policeGarages) do
        if garage.job == jobName then out[id] = garage end
    end
    return out
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(4000)
    loadPoliceGarages()
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    CreateThread(function()
        Wait(5000)
        local job = MiscB.JobName(xPlayer)
        if not job then return end
        TriggerClientEvent("policeGarage:load", source, garagesForJob(job))
    end)
end)

MiscB.Cb("policeGarage:getForJob", function(source, jobName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local job = MiscB.Str(jobName, 64) or MiscB.JobName(xPlayer)
    if job ~= MiscB.JobName(xPlayer) and not xPlayer.hasPermission("staff") then
        job = MiscB.JobName(xPlayer)
    end
    if not job then return {} end
    return garagesForJob(job)
end)

MiscB.Cb("policeGarage:validateSpawn", function(source, garageId, vehicleModel)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local id = MiscB.ToInt(garageId, 1)
    local garage = id and policeGarages[id] or nil
    if not garage then return false end
    if garage.job ~= MiscB.JobName(xPlayer) then return false end

    local model = MiscB.Str(vehicleModel, 64)
    if not model then return false end

    local list = type(garage.vehicles) == "table" and garage.vehicles or {}
    for i = 1, #list do
        local entry = list[i]
        local entryModel = type(entry) == "table" and entry.model or entry
        if entryModel == model then
            local minGrade = type(entry) == "table" and tonumber(entry.minGrade or entry.grade) or 0
            return (minGrade or 0) <= MiscB.GradeLevel(xPlayer)
        end
    end
    return false
end)

RegisterNetEvent("policeGarage:spawnVehicle", function(vehicleModel, garageId, sp, vehicleType)
    local source = source
    local model = MiscB.Str(vehicleModel, 64)
    local id = MiscB.ToInt(garageId, 1)
    if not model or not id or type(sp) ~= "table" then return end
    if not MiscB.Rate(source, "pgspawn", 2000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local garage = policeGarages[id]
    if not xPlayer or not garage then
        TriggerClientEvent("policeGarage:spawnFailed", source, "Garage introuvable.")
        return
    end
    if garage.job ~= MiscB.JobName(xPlayer) then
        TriggerClientEvent("policeGarage:spawnFailed", source, "Acces refuse.")
        return
    end

    local coords = {
        x = MiscB.ToNum(sp.x, 0.0),
        y = MiscB.ToNum(sp.y, 0.0),
        z = MiscB.ToNum(sp.z, 0.0),
    }
    local heading = MiscB.ToNum(sp.w or sp.h or sp.heading, 0.0)

    local vehicle, netId
    if VFW.Vehicles and VFW.Vehicles.Spawn then
        vehicle, netId = VFW.Vehicles.Spawn(source, model, coords, heading, {})
    end

    if not vehicle or not netId then
        TriggerClientEvent("policeGarage:spawnFailed", source, "Impossible de faire spawner le vehicule.")
        return
    end

    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        SetPedIntoVehicle(ped, vehicle, -1)
    end

    local spawnedPlate = GetVehicleNumberPlateText(vehicle)
    if type(spawnedPlate) == "string" then
        spawnedPlate = trimPlate(spawnedPlate)
        if spawnedPlate ~= "" then
            grantTemporaryKey(source, xPlayer, "job", spawnedPlate)
        end
    end

    TriggerClientEvent("policeGarage:spawnSuccess", source, netId)
end)

local function garageStaff(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if MiscB.IsBoss(xPlayer) or xPlayer.hasPermission("staff") or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

RegisterNetEvent("policeGarage:create", function(garage)
    local source = source
    if type(garage) ~= "table" then return end

    local xPlayer = garageStaff(source)
    if not xPlayer then return end

    local name = MiscB.Str(garage.name, 64)
    local job = MiscB.Str(garage.job, 64) or MiscB.JobName(xPlayer)
    if not name or not job then return end

    local id = MiscB.Insert([[
        INSERT INTO police_garages (name, job, position, spawn_positions, despawn_position, vehicles, ped_model)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        name, job,
        VFW.DB.Encode(garage.position or {}),
        VFW.DB.Encode(garage.spawnPositions or {}),
        VFW.DB.Encode(garage.despawnPosition or {}),
        VFW.DB.Encode(garage.vehicles or {}),
        MiscB.Str(garage.pedModel, 64) or "s_m_y_cop_01",
    })
    if not id then return end

    loadPoliceGarages()
    local created = policeGarages[id]
    local receivers = MiscB.PlayersWithJobs(job)
    for i = 1, #receivers do
        TriggerClientEvent("policeGarage:added", receivers[i].source, created)
    end
end)

RegisterNetEvent("policeGarage:update", function(garageId, garage)
    local source = source
    local id = MiscB.ToInt(garageId, 1)
    if not id or type(garage) ~= "table" then return end

    local xPlayer = garageStaff(source)
    if not xPlayer then return end
    if not policeGarages[id] then return end

    MiscB.Update([[
        UPDATE police_garages SET name = ?, position = ?, spawn_positions = ?,
        despawn_position = ?, vehicles = ?, ped_model = ? WHERE id = ?
    ]], {
        MiscB.Str(garage.name, 64) or policeGarages[id].name,
        VFW.DB.Encode(garage.position or {}),
        VFW.DB.Encode(garage.spawnPositions or {}),
        VFW.DB.Encode(garage.despawnPosition or {}),
        VFW.DB.Encode(garage.vehicles or {}),
        MiscB.Str(garage.pedModel, 64) or "s_m_y_cop_01",
        id,
    })

    local job = policeGarages[id].job
    loadPoliceGarages()

    local receivers = MiscB.PlayersWithJobs(job)
    for i = 1, #receivers do
        TriggerClientEvent("policeGarage:updated", receivers[i].source, policeGarages[id])
    end
end)

RegisterNetEvent("policeGarage:delete", function(garageId)
    local source = source
    local id = MiscB.ToInt(garageId, 1)
    if not id then return end

    local xPlayer = garageStaff(source)
    if not xPlayer then return end

    local garage = policeGarages[id]
    if not garage then return end
    local job = garage.job

    MiscB.Update("DELETE FROM police_garages WHERE id = ?", { id })
    policeGarages[id] = nil

    local receivers = MiscB.PlayersWithJobs(job)
    for i = 1, #receivers do
        TriggerClientEvent("policeGarage:removed", receivers[i].source, id)
    end
end)

RegisterNetEvent("core:jobs:addChest", function(plate)
    local source = source
    if type(plate) ~= "string" or #plate > 12 then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local normalized = plate:gsub("^%s+", ""):gsub("%s+$", "")
    local chestId = "vehicle_" .. normalized

    MiscB.Update([[
        INSERT INTO chests (chest_id, label, max_weight, max_slots, items) VALUES (?, ?, 100000, 40, '[]')
        ON DUPLICATE KEY UPDATE label = VALUES(label)
    ]], { chestId, "Coffre " .. normalized })

    TriggerClientEvent("core:jobs:chestAdded", source, chestId, normalized)
end)

RegisterNetEvent("core:server:announceEntreprise:sendData", function(data)
    local source = source
    if type(data) ~= "table" then return end
    if not MiscB.Rate(source, "announce", 30000) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Patientez avant une nouvelle annonce." })
        return
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.IsBoss(xPlayer) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Seul un patron peut publier une annonce." })
        return
    end

    local payload = {
        job = MiscB.JobName(xPlayer),
        jobLabel = type(xPlayer.job) == "table" and xPlayer.job.label or nil,
        author = MiscB.CharName(xPlayer),
        title = MiscB.Str(data.title, 96) or "",
        message = MiscB.Str(data.message or data.content, 1000) or "",
        image = MiscB.Str(data.image, 512),
        phone = MiscB.Str(data.phone, 32),
        at = os.time(),
    }

    if payload.message == "" then return end

    TriggerClientEvent("core:client:announceEntreprise:receiveData", -1, payload)
end)
