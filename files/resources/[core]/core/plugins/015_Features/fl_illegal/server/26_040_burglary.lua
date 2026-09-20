local Burglary = {
    houses = {},
    interiors = {},
    lootPoints = {},
    settings = {},
    instances = {},
    postRobbery = {},
    players = {},
}

local BUILDER_PERM = "builder_burglary"
local LOCKPICK_ITEM = "kit_de_crochetage"
local BUCKET_BASE = 30000
local DEFAULT_SETTINGS = {
    lockpick_difficulty = "medium",
    robbery_duration = 600,
    house_cooldown = 3600,
    min_police = 0,
    post_robbery_duration = 1800,
    max_loot_per_point = 1,
}

local function LoadSettings()
    Burglary.settings = IL.LoadSettings("burglary_settings", DEFAULT_SETTINGS)
end

local function LoadInteriors()
    Burglary.interiors = {}
    local rows = IL.Query("SELECT * FROM burglary_interiors")
    for i = 1, #rows do
        local row = rows[i]
        Burglary.interiors[row.id] = {
            id = row.id,
            name = row.name,
            iplName = row.ipl_name or "_default_",
            spawnPos = {
                x = IL.Num(row.spawn_x, 0.0),
                y = IL.Num(row.spawn_y, 0.0),
                z = IL.Num(row.spawn_z, 0.0),
                h = IL.Num(row.spawn_h, 0.0),
            },
        }
    end
end

local function LoadHouses()
    Burglary.houses = {}
    local rows = IL.Query("SELECT * FROM burglary_houses")
    for i = 1, #rows do
        local row = rows[i]
        Burglary.houses[row.id] = {
            id = row.id,
            name = row.name,
            entryPos = { x = IL.Num(row.entry_x, 0.0), y = IL.Num(row.entry_y, 0.0), z = IL.Num(row.entry_z, 0.0) },
            interiorId = row.interior_id,
            active = IL.Bool(row.active),
            blipEnabled = IL.Bool(row.blip_enabled),
            lastRobbed = IL.Int(row.last_robbed, 0),
        }
    end
end

local function LoadLootPoints()
    Burglary.lootPoints = {}
    local rows = IL.Query("SELECT * FROM burglary_loot_points")
    for i = 1, #rows do
        local row = rows[i]
        local interiorId = row.interior_id
        Burglary.lootPoints[interiorId] = Burglary.lootPoints[interiorId] or {}
        Burglary.lootPoints[interiorId][#Burglary.lootPoints[interiorId] + 1] = {
            id = row.id,
            pos = { x = IL.Num(row.pos_x, 0.0), y = IL.Num(row.pos_y, 0.0), z = IL.Num(row.pos_z, 0.0) },
            loot = IL.Decode(row.loot_table, {}),
        }
    end
end

local function HousesPayload()
    local out = {}
    for id, house in pairs(Burglary.houses) do
        out[id] = {
            entryPos = house.entryPos,
            active = house.active,
            blipEnabled = house.blipEnabled,
            name = house.name,
        }
    end
    return out
end

local function InteriorsPayload()
    local out = {}
    for id, interior in pairs(Burglary.interiors) do
        out[id] = {
            spawnPos = interior.spawnPos,
            iplName = interior.iplName,
            name = interior.name,
        }
    end
    return out
end

local function PostRobberyPayload()
    local out = {}
    local now = IL.Now()
    for houseId, expiry in pairs(Burglary.postRobbery) do
        if expiry > now then
            out[houseId] = true
        end
    end
    return out
end

local function SyncAll(target)
    TriggerClientEvent("core:burglary:syncData", target or -1, {
        houses = HousesPayload(),
        interiors = InteriorsPayload(),
        settings = Burglary.settings,
    })
end

local function LootPointsPayload(instance)
    local out = {}
    local points = Burglary.lootPoints[instance.interiorId] or {}
    for i = 1, #points do
        if not instance.looted[points[i].id] then
            out[#out + 1] = { id = points[i].id, pos = points[i].pos }
        end
    end
    return out
end

local function ExpelPlayer(source, houseId, timedOut)
    local xPlayer = IL.Player(source)
    Burglary.players[source] = nil
    SetPlayerRoutingBucket(source, 0)
    local house = Burglary.houses[houseId]
    if xPlayer and house then
        xPlayer.setCoords({
            x = house.entryPos.x,
            y = house.entryPos.y,
            z = house.entryPos.z,
            heading = 0.0,
        })
    end
    if timedOut then
        TriggerClientEvent("core:burglary:robberyTimeout", source)
    end
    TriggerClientEvent("core:burglary:exitInstance", source)
end

local function CloseInstance(houseId)
    local instance = Burglary.instances[houseId]
    if not instance then return end

    for source in pairs(instance.members) do
        ExpelPlayer(source, houseId, false)
    end

    Burglary.instances[houseId] = nil
    Burglary.postRobbery[houseId] = IL.Now() + IL.Int(Burglary.settings.post_robbery_duration, 1800)
    TriggerClientEvent("core:burglary:syncHouseState", -1, houseId, false)
    TriggerClientEvent("core:burglary:postRobbery", -1, houseId, true)
end

IL.OnReady(function()
    LoadSettings()
    LoadInteriors()
    LoadHouses()
    LoadLootPoints()
    SyncAll(-1)
end)

IL.OnPlayerLoaded(function(source)
    SyncAll(source)
    for houseId, instance in pairs(Burglary.instances) do
        if instance.active then
            TriggerClientEvent("core:burglary:syncHouseState", source, houseId, true)
        end
    end
    for houseId in pairs(PostRobberyPayload()) do
        TriggerClientEvent("core:burglary:postRobbery", source, houseId, true)
    end
end)

IL.OnPlayerDropped(function(source)
    local state = Burglary.players[source]
    if not state then return end
    local instance = Burglary.instances[state.houseId]
    if instance then
        instance.members[source] = nil
        local remaining = 0
        for _ in pairs(instance.members) do remaining = remaining + 1 end
        if remaining == 0 then
            Burglary.instances[state.houseId] = nil
            TriggerClientEvent("core:burglary:syncHouseState", -1, state.houseId, false)
        end
    end
    Burglary.players[source] = nil
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = IL.Now()
        for houseId, instance in pairs(Burglary.instances) do
            if not instance.expired and now >= instance.endsAt then
                instance.expired = true
                for source in pairs(instance.members) do
                    TriggerClientEvent("core:burglary:timerExpired", source)
                end
            end
            if instance.expired and now >= instance.endsAt + 120 then
                CloseInstance(houseId)
            end
            local count = 0
            for _ in pairs(instance.members) do count = count + 1 end
            if count == 0 and now > instance.startedAt + 30 then
                CloseInstance(houseId)
            end
        end
        for houseId, expiry in pairs(Burglary.postRobbery) do
            if expiry <= now then
                Burglary.postRobbery[houseId] = nil
                TriggerClientEvent("core:burglary:postRobbery", -1, houseId, false)
            end
        end
    end
end)

IL.RegisterCallback("core:burglary:getHouses", function(source)
    return HousesPayload()
end)

IL.RegisterCallback("core:burglary:getInteriors", function(source)
    return InteriorsPayload()
end)

IL.RegisterCallback("core:burglary:getSettings", function(source)
    return Burglary.settings
end)

IL.RegisterCallback("core:burglary:getPostRobberyHouses", function(source)
    return PostRobberyPayload()
end)

IL.RegisterCallback("core:burglary:canStartRobbery", function(source, houseId)
    houseId = IL.Int(houseId, nil)
    if not houseId then return false, "Cette maison n'est pas valide" end

    local xPlayer = IL.Player(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local house = Burglary.houses[houseId]
    if not house or not house.active then return false, "Maison indisponible" end
    if not house.interiorId or not Burglary.interiors[house.interiorId] then
        return false, "Interieur non configure"
    end

    if Burglary.instances[houseId] then
        return false, "Un cambriolage est deja en cours ici"
    end

    local now = IL.Now()
    if Burglary.postRobbery[houseId] and Burglary.postRobbery[houseId] > now then
        return false, "Cette maison vient d'etre cambriolee"
    end
    if house.lastRobbed > 0 and (now - house.lastRobbed) < IL.Int(Burglary.settings.house_cooldown, 3600) then
        return false, "Cette maison a ete cambriolee recemment"
    end

    if Burglary.players[source] then
        return false, "Vous etes deja dans une instance"
    end

    if not xPlayer.haveItem(LOCKPICK_ITEM, 1) then
        return false, "Il vous faut un kit de crochetage"
    end

    local minPolice = IL.Int(Burglary.settings.min_police, 0)
    if minPolice > 0 and IL.PoliceOnDutyCount() < minPolice then
        return false, "Trop peu de policiers en service"
    end

    if IL.DistanceTo(source, house.entryPos.x, house.entryPos.y, house.entryPos.z) > 8.0 then
        return false, "Vous etes trop loin"
    end

    return true, nil
end)

IL.RegisterCallback("core:burglary:getInstanceStatus", function(source, houseId)
    houseId = IL.Int(houseId, nil)
    if not houseId then return { active = false } end
    local instance = Burglary.instances[houseId]
    if not instance then return { active = false } end
    local count = 0
    for _ in pairs(instance.members) do count = count + 1 end
    return {
        active = true,
        players = count,
        expired = instance.expired == true,
        timeLeft = math.max(0, instance.endsAt - IL.Now()),
    }
end)

IL.RegisterCallback("core:burglary:getInstanceReport", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return { active_instances = {} } end

    local report = {}
    for houseId, instance in pairs(Burglary.instances) do
        local count = 0
        for _ in pairs(instance.members) do count = count + 1 end
        local looted = 0
        for _ in pairs(instance.looted) do looted = looted + 1 end
        local house = Burglary.houses[houseId]
        local interior = Burglary.interiors[instance.interiorId]
        report[houseId] = {
            house_name = house and house.name or "?",
            bucket_id = instance.bucket,
            interior_name = interior and interior.name or "?",
            ipl_name = interior and interior.iplName or "",
            player_count = count,
            looted_points = looted,
            loot_points = #(Burglary.lootPoints[instance.interiorId] or {}),
            time_left = math.max(0, (instance.endsAt - IL.Now()) * 1000),
        }
    end
    return { active_instances = report }
end)

IL.RegisterCallback("core:burglary:validateIsolation", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then
        return { isolation_status = "denied", total_instances = 0, unique_buckets = {}, bucket_conflicts = {} }
    end

    local buckets, unique, conflicts, total = {}, {}, {}, 0
    for _, instance in pairs(Burglary.instances) do
        total = total + 1
        if buckets[instance.bucket] then
            conflicts[#conflicts + 1] = instance.bucket
        else
            buckets[instance.bucket] = true
            unique[#unique + 1] = instance.bucket
        end
    end

    return {
        isolation_status = #conflicts == 0 and "healthy" or "conflict",
        total_instances = total,
        unique_buckets = unique,
        bucket_conflicts = conflicts,
    }
end)

RegisterNetEvent("core:burglary:useLockpickKit", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    IL.TakeItem(xPlayer, LOCKPICK_ITEM, 1)
end)

RegisterNetEvent("core:burglary:startRobbery", function(houseId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    houseId = IL.Int(houseId, nil)
    if not houseId then return end

    local house = Burglary.houses[houseId]
    if not house or not house.active then return end
    if Burglary.instances[houseId] then return end
    if Burglary.players[source] then return end

    local interior = Burglary.interiors[house.interiorId]
    if not interior then
        IL.Notify(source, "ILLEGAL", "Interieur non configure.")
        return
    end

    local now = IL.Now()
    if Burglary.postRobbery[houseId] and Burglary.postRobbery[houseId] > now then return end
    if house.lastRobbed > 0 and (now - house.lastRobbed) < IL.Int(Burglary.settings.house_cooldown, 3600) then return end
    if IL.DistanceTo(source, house.entryPos.x, house.entryPos.y, house.entryPos.z) > 10.0 then return end

    if not IL.TakeItem(xPlayer, LOCKPICK_ITEM, 1) then
        IL.Notify(source, "ILLEGAL", "Il vous faut un kit de crochetage.")
        return
    end

    local duration = IL.Int(Burglary.settings.robbery_duration, 600)

    local instance = {
        houseId = houseId,
        interiorId = house.interiorId,
        bucket = BUCKET_BASE + houseId,
        members = {},
        looted = {},
        startedAt = now,
        endsAt = now + duration,
        expired = false,
        active = true,
    }
    Burglary.instances[houseId] = instance
    instance.members[source] = true
    Burglary.players[source] = { houseId = houseId, post = false }

    house.lastRobbed = now
    IL.Execute("UPDATE burglary_houses SET last_robbed = ? WHERE id = ?", { now, houseId })

    SetPlayerRoutingBucket(source, instance.bucket)
    TriggerClientEvent("core:burglary:enterInstance", source, houseId, {
        spawnPos = interior.spawnPos,
        iplName = interior.iplName,
    }, duration)
    TriggerClientEvent("core:burglary:updateLootPoints", source, houseId, LootPointsPayload(instance))

    TriggerClientEvent("core:burglary:syncHouseState", -1, houseId, true)
    IL.AlertPolice("core:burglary:createPoliceBlip", houseId, house.entryPos)
end)

RegisterNetEvent("core:burglary:joinInstance", function(houseId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    houseId = IL.Int(houseId, nil)
    if not houseId then return end

    local instance = Burglary.instances[houseId]
    if not instance then return end
    if Burglary.players[source] then return end

    local house = Burglary.houses[houseId]
    local interior = Burglary.interiors[instance.interiorId]
    if not house or not interior then return end

    if IL.DistanceTo(source, house.entryPos.x, house.entryPos.y, house.entryPos.z) > 10.0 then
        IL.Notify(source, "ILLEGAL", "Vous etes trop loin de l'entree.")
        return
    end

    instance.members[source] = true
    Burglary.players[source] = { houseId = houseId, post = false }

    SetPlayerRoutingBucket(source, instance.bucket)

    local timeLeft = math.max(0, instance.endsAt - IL.Now())
    TriggerClientEvent("core:burglary:enterInstance", source, houseId, {
        spawnPos = interior.spawnPos,
        iplName = interior.iplName,
    }, timeLeft)
    TriggerClientEvent("core:burglary:updateLootPoints", source, houseId, LootPointsPayload(instance))
end)

RegisterNetEvent("core:burglary:visitPostRobbery", function(houseId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    houseId = IL.Int(houseId, nil)
    if not houseId then return end
    if Burglary.players[source] then return end

    local now = IL.Now()
    if not Burglary.postRobbery[houseId] or Burglary.postRobbery[houseId] <= now then return end

    local house = Burglary.houses[houseId]
    if not house then return end
    local interior = Burglary.interiors[house.interiorId]
    if not interior then return end

    if IL.DistanceTo(source, house.entryPos.x, house.entryPos.y, house.entryPos.z) > 10.0 then return end

    Burglary.players[source] = { houseId = houseId, post = true }
    SetPlayerRoutingBucket(source, BUCKET_BASE + houseId)
    TriggerClientEvent("core:burglary:enterPostRobbery", source, houseId, {
        spawnPos = interior.spawnPos,
        iplName = interior.iplName,
    })
end)

RegisterNetEvent("core:burglary:lootPoint", function(houseId, pointId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    houseId = IL.Int(houseId, nil)
    if not houseId or pointId == nil then return end

    local state = Burglary.players[source]
    if not state or state.houseId ~= houseId or state.post then return end

    local instance = Burglary.instances[houseId]
    if not instance or instance.expired then return end
    if not instance.members[source] then return end

    local points = Burglary.lootPoints[instance.interiorId] or {}
    local point = nil
    for i = 1, #points do
        if points[i].id == pointId then
            point = points[i]
            break
        end
    end
    if not point then return end
    if instance.looted[point.id] then return end

    if IL.DistanceTo(source, point.pos.x, point.pos.y, point.pos.z) > 5.0 then return end

    instance.looted[point.id] = true

    local loot = point.loot
    if IL.IsTable(loot) then
        for i = 1, #loot do
            local entry = loot[i]
            if IL.IsTable(entry) and type(entry.item) == "string" then
                local chance = IL.Int(entry.chance, 100)
                if math.random(1, 100) <= chance then
                    local minCount = IL.Int(entry.min, 1)
                    local maxCount = IL.Int(entry.max, minCount)
                    if maxCount < minCount then maxCount = minCount end
                    local count = math.random(minCount, maxCount)
                    if entry.item == "money" or entry.item == "black_money" then
                        IL.GiveMoney(xPlayer, "black_money", count, "burglary-loot")
                    else
                        IL.GiveItem(xPlayer, entry.item, count, true)
                    end
                end
            end
        end
    end

    for member in pairs(instance.members) do
        TriggerClientEvent("core:burglary:pointLooted", member, houseId, point.id)
    end
end)

RegisterNetEvent("core:burglary:leaveInstance", function()
    local source = source
    local state = Burglary.players[source]
    if not state then return end

    local houseId = state.houseId
    local instance = Burglary.instances[houseId]
    if instance then
        instance.members[source] = nil
    end

    ExpelPlayer(source, houseId, false)

    if instance then
        local remaining = 0
        for _ in pairs(instance.members) do remaining = remaining + 1 end
        if remaining == 0 then
            Burglary.instances[houseId] = nil
            Burglary.postRobbery[houseId] = IL.Now() + IL.Int(Burglary.settings.post_robbery_duration, 1800)
            TriggerClientEvent("core:burglary:syncHouseState", -1, houseId, false)
            TriggerClientEvent("core:burglary:postRobbery", -1, houseId, true)
        end
    end
end)

RegisterNetEvent("core:burglary:builderReload", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    LoadSettings()
    LoadInteriors()
    LoadHouses()
    LoadLootPoints()
    SyncAll(-1)
end)
