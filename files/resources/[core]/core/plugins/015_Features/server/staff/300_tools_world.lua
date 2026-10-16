local ENTITY_WINDOW_MS = 10000
local ENTITY_MAX_PER_WINDOW = 20
local MAX_STAFF_PROPS = 512
local MAX_EVENT_OBJECTS = 512
local MAX_TEMP_ITEM_TARGETS = 64
local EXPLOSION_BROADCAST_RADIUS = 400.0
local PED_AI_BROADCAST_RADIUS = 300.0
local FIRE_ORIGIN_TOLERANCE = 60.0
local PLACEMENT_TOLERANCE = 350.0

local STAFF_LICENSE_TYPES = {
    car = "driver",
    motorcycle = "moto",
    truck = "camion",
}

local entityBudget = {}
local staffProps = {}
local staffPropCount = 0
local staffPropSeq = 0
local eventObjects = {}
local eventObjectCount = 0
local activeStaffFires = {}
local fireworkRunning = false

local function notify(source, variant, subtitle, message)
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF",
        variant = variant,
        subtitle = subtitle,
        message = message,
    })
end

local function logStaff(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, action, payload)
end

local function allow(source, ...)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local keys = { ... }
    for i = 1, #keys do
        if xPlayer.hasPermission(keys[i]) then return xPlayer end
    end
    return nil
end

local function allowEvent(source, ...)
    local xPlayer = allow(source, ...)
    if xPlayer then return xPlayer end
    return allow(source, "events", "menu_event", "menu_anim")
end

local function consumeEntityBudget(source, amount)
    local now = GetGameTimer()
    local budget = entityBudget[source]

    if not budget or now >= budget.resetAt then
        budget = { resetAt = now + ENTITY_WINDOW_MS, used = 0 }
        entityBudget[source] = budget
    end

    if budget.used + amount > ENTITY_MAX_PER_WINDOW then
        return false
    end

    budget.used = budget.used + amount
    return true
end

local function readNumber(value, minimum, maximum)
    local n = tonumber(value)
    if not n or n ~= n then return nil end
    if n == math.huge or n == -math.huge then return nil end
    if minimum and n < minimum then return nil end
    if maximum and n > maximum then return nil end
    return n + 0.0
end

local function readInteger(value, minimum, maximum)
    local n = readNumber(value, minimum, maximum)
    if not n then return nil end
    return math.floor(n)
end

local function readRadius(value, maximum)
    local n = readNumber(value)
    if not n or n <= 0 then return nil end
    if n > maximum then return maximum end
    return n
end

local function readVector(value)
    local kind = type(value)
    if kind ~= "table" and kind ~= "vector3" and kind ~= "vector4" then return nil end

    local x = readNumber(value.x, -20000.0, 20000.0)
    local y = readNumber(value.y, -20000.0, 20000.0)
    local z = readNumber(value.z, -2000.0, 5000.0)
    if not x or not y or not z then return nil end

    return { x = x, y = y, z = z }
end

local function readRotation(value)
    local kind = type(value)
    if kind ~= "table" and kind ~= "vector3" and kind ~= "vector4" then
        return { x = 0.0, y = 0.0, z = 0.0 }
    end

    return {
        x = readNumber(value.x, -360.0, 360.0) or 0.0,
        y = readNumber(value.y, -360.0, 360.0) or 0.0,
        z = readNumber(value.z, -360.0, 360.0) or 0.0,
    }
end

local function readModel(value)
    if type(value) == "number" then
        if value ~= value or value == math.huge or value == -math.huge then return nil end
        local hash = math.floor(value)
        if hash == 0 then return nil end
        return hash
    end

    if type(value) ~= "string" then return nil end

    local name = (value:gsub("%s", ""))
    if name == "" or #name > 64 then return nil end
    if name:find("[^%w_%-]") then return nil end
    return name
end

local function modelLabel(model)
    if type(model) == "string" then return model end
    return tostring(model)
end

local function unsignedHash(value)
    local n = tonumber(value)
    if not n or n ~= n then return nil end
    return math.floor(n) % 4294967296
end

local function distanceSquared(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function withinReach(xPlayer, coords, tolerance)
    local origin = xPlayer.getCoords()
    if not origin then return false end
    return distanceSquared(coords, origin) <= (tolerance * tolerance)
end

local function sendNear(coords, radius, event, ...)
    local nearby = VFW.GetPlayersInRadius(coords, radius)
    for i = 1, #nearby do
        TriggerClientEvent(event, nearby[i].source, ...)
    end
    return #nearby
end

local function rememberEventObject(netId, name, owner)
    local key = tostring(netId)
    if eventObjects[key] == nil then
        if eventObjectCount >= MAX_EVENT_OBJECTS then return false end
        eventObjectCount = eventObjectCount + 1
    end

    eventObjects[key] = { name = name, netId = netId, owner = owner }
    return true
end

local function forgetEventObject(key)
    if eventObjects[key] == nil then return nil end

    local entry = eventObjects[key]
    eventObjects[key] = nil
    eventObjectCount = eventObjectCount - 1
    return entry
end

local function releaseStaffProp(propId)
    local entry = staffProps[propId]
    if not entry then return nil end

    staffProps[propId] = nil
    staffPropCount = staffPropCount - 1
    return entry
end

RegisterNetEvent("vfw:staff:spawnProp", function(model, posX, posY, posZ, rotX, rotY, rotZ)
    local source = source
    local xPlayer = allow(source, "alt_spawn_object")
    if not xPlayer then return end

    local resolved = readModel(model)
    if not resolved then
        notify(source, "ERROR", "Spawn objet", "Ce modèle n'est pas valide.")
        return
    end

    local coords = readVector({ x = posX, y = posY, z = posZ })
    if not coords then return end
    if not withinReach(xPlayer, coords, PLACEMENT_TOLERANCE) then return end

    local rotation = readRotation({ x = rotX, y = rotY, z = rotZ })

    if staffPropCount >= MAX_STAFF_PROPS then
        notify(source, "ERROR", "Spawn objet", "La limite d'objets staff posés est atteinte.")
        return
    end

    if not consumeEntityBudget(source, 1) then
        notify(source, "ERROR", "Spawn objet", "Vous posez des objets trop vite. Patientez quelques secondes.")
        return
    end

    if not Feat27 or not Feat27.SpawnObject then return end

    local netId, entity = Feat27.SpawnObject(resolved, coords, rotation.z)
    if not netId or not entity then
        notify(source, "ERROR", "Spawn objet", "Cet objet n'a pas pu apparaître.")
        return
    end

    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
    FreezeEntityPosition(entity, true)

    staffPropSeq = staffPropSeq + 1
    local propId = ("staffprop_%d"):format(staffPropSeq)

    staffProps[propId] = { entity = entity, netId = netId, model = resolved, owner = source }
    staffPropCount = staffPropCount + 1

    Entity(entity).state:set("staffPropId", propId, true)

    notify(source, "SUCCESS", "Spawn objet", "L'objet est en place.")
    logStaff(source, "spawn_prop", { model = modelLabel(resolved), coords = coords, propId = propId })
end)

RegisterNetEvent("vfw:staff:deleteProp", function(propId)
    local source = source
    local xPlayer = allow(source, "alt_delete_entity", "clearprops")
    if not xPlayer then return end
    if type(propId) ~= "string" or #propId > 64 then return end

    local entry = releaseStaffProp(propId)
    if not entry then
        notify(source, "ERROR", "Objet staff", "Cet objet n'existe plus.")
        return
    end

    if entry.entity and DoesEntityExist(entry.entity) then
        DeleteEntity(entry.entity)
    end

    logStaff(source, "delete_prop", { propId = propId, model = modelLabel(entry.model) })
end)

RegisterNetEvent("vfw:staff:spawnPed", function(model, posX, posY, posZ, heading)
    local source = source
    local xPlayer = allow(source, "alt_spawn_ped")
    if not xPlayer then return end

    local resolved = readModel(model)
    if not resolved then
        notify(source, "ERROR", "Spawn PNJ", "Ce modèle n'est pas valide.")
        return
    end

    local coords = readVector({ x = posX, y = posY, z = posZ })
    if not coords then return end
    if not withinReach(xPlayer, coords, PLACEMENT_TOLERANCE) then return end

    local face = readNumber(heading, -360.0, 360.0) or 0.0

    if not consumeEntityBudget(source, 1) then
        notify(source, "ERROR", "Spawn PNJ", "Vous créez des PNJ trop vite. Patientez quelques secondes.")
        return
    end

    if not Feat27 or not Feat27.SpawnPed then return end

    local netId, ped = Feat27.SpawnPed(resolved, coords, face)
    if not netId or not ped then
        notify(source, "ERROR", "Spawn PNJ", "Ce PNJ n'a pas pu apparaître.")
        return
    end

    FreezeEntityPosition(ped, true)
    Entity(ped).state:set("staffSpawnedPed", true, true)

    sendNear(coords, PED_AI_BROADCAST_RADIUS, "vfw:staff:disablePedAI", netId)

    notify(source, "SUCCESS", "Spawn PNJ", "Le PNJ est en place.")
    logStaff(source, "spawn_ped", { model = modelLabel(resolved), coords = coords, netId = netId })
end)

RegisterNetEvent("vfw:staff:giveCar", function(targetId, model, plate, label)
    local source = source
    local xPlayer = allow(source, "addvehplayer")
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        notify(source, "ERROR", "Véhicule définitif", "Ce joueur n'est pas connecté.")
        return
    end

    local resolved = readModel(model)
    if type(resolved) ~= "string" then
        notify(source, "ERROR", "Véhicule définitif", "Ce nom de véhicule n'est pas valide.")
        return
    end

    local wanted
    if type(plate) == "string" then
        wanted = (plate:gsub("[^%w ]", "")):sub(1, 8)
        if wanted == "" then wanted = nil end
    end

    if not Feat27 or not Feat27.Vehicles or not Feat27.Vehicles.Store then return end

    local ok, result = Feat27.Vehicles.Store(target.identifier, resolved, {}, wanted, { kind = "car" })
    if not ok then
        notify(source, "ERROR", "Véhicule définitif", "Ce véhicule n'a pas pu être enregistré.")
        return
    end

    notify(source, "SUCCESS", "Véhicule définitif",
        ("Véhicule enregistré au nom de %s sous la plaque %s."):format(target.name, tostring(result)))
    notify(target.source, "SUCCESS", "Véhicule",
        ("Un véhicule vous a été attribué. Plaque : %s."):format(tostring(result)))

    logStaff(source, "give_vehicle", {
        target = target.source,
        model = resolved,
        plate = result,
        label = type(label) == "string" and label:sub(1, 64) or nil,
    })
end)

RegisterNetEvent("vfw:staff:createExplosion", function(posX, posY, posZ)
    local source = source
    local xPlayer = allow(source, "devcontextmenu")
    if not xPlayer then return end

    local coords = readVector({ x = posX, y = posY, z = posZ })
    if not coords then return end
    if not withinReach(xPlayer, coords, PLACEMENT_TOLERANCE) then return end

    if not consumeEntityBudget(source, 1) then
        notify(source, "ERROR", "Explosion", "Vous déclenchez des explosions trop vite. Patientez quelques secondes.")
        return
    end

    sendNear(coords, EXPLOSION_BROADCAST_RADIUS, "vfw:staff:doExplosion", coords.x, coords.y, coords.z)
    logStaff(source, "create_explosion", { coords = coords })
end)

RegisterServerCallback("vfw:staff:spawnNetworkObject", function(source, model, coords, rotation, freeze)
    local xPlayer = allow(source, "menu_event", "menu_anim")
    if not xPlayer then return { success = false } end

    local resolved = readModel(model)
    if not resolved then return { success = false } end

    local position = readVector(coords)
    if not position then return { success = false } end
    if not withinReach(xPlayer, position, PLACEMENT_TOLERANCE) then return { success = false } end

    local rot = readRotation(rotation)

    if eventObjectCount >= MAX_EVENT_OBJECTS then
        notify(source, "ERROR", "Props Editor", "La limite d'objets posés est atteinte.")
        return { success = false }
    end

    if not consumeEntityBudget(source, 1) then
        notify(source, "ERROR", "Props Editor", "Vous posez des objets trop vite. Patientez quelques secondes.")
        return { success = false }
    end

    if not Feat27 or not Feat27.SpawnObject then return { success = false } end

    local netId, entity = Feat27.SpawnObject(resolved, position, rot.z)
    if not netId or not entity then return { success = false } end

    SetEntityRotation(entity, rot.x, rot.y, rot.z, 2, true)
    if freeze == true then
        FreezeEntityPosition(entity, true)
    end

    Entity(entity).state:set("eventPropNetId", netId, true)
    rememberEventObject(netId, modelLabel(resolved), source)

    logStaff(source, "spawn_event_object", { model = modelLabel(resolved), coords = position, netId = netId })

    return { success = true, netId = netId }
end)

RegisterNetEvent("vfw:staff:saveObject", function(payload)
    local source = source
    local xPlayer = allow(source, "menu_event", "menu_anim")
    if not xPlayer then return end
    if type(payload) ~= "table" then return end

    local netId = readInteger(payload.geneartedId or payload.netId, 1, 1000000)
    if not netId then return end

    local name = readModel(payload.name)
    if not name then return end

    if not rememberEventObject(netId, modelLabel(name), source) then
        notify(source, "ERROR", "Props Editor", "La limite d'objets posés est atteinte.")
        return
    end

    logStaff(source, "save_event_object", { model = modelLabel(name), netId = netId })
end)

RegisterServerCallback("vfw:staff:getObject", function(source)
    local xPlayer = allow(source, "menu_event", "menu_anim", "alt_delete_entity")
    if not xPlayer then return {} end

    local canPrune = Feat27 ~= nil and Feat27.EntityFromNet ~= nil
    local out = {}
    local stale = {}

    for key, entry in pairs(eventObjects) do
        if canPrune and not Feat27.EntityFromNet(entry.netId) then
            stale[#stale + 1] = key
        else
            out[key] = { name = entry.name, netId = entry.netId }
        end
    end

    for i = 1, #stale do
        forgetEventObject(stale[i])
    end

    return out
end)

RegisterNetEvent("vfw:staff:deleteObject", function(key)
    local source = source
    local xPlayer = allow(source, "menu_event", "menu_anim", "alt_delete_entity")
    if not xPlayer then return end

    local netId = readInteger(key, 1, 1000000)
    if not netId then return end

    local entry = forgetEventObject(tostring(netId))

    if Feat27 and Feat27.DeleteNet then
        Feat27.DeleteNet(netId)
    end

    logStaff(source, "delete_event_object", { netId = netId, name = entry and entry.name or nil })
end)

RegisterServerCallback("vfw:staff:deleteEmoteProp", function(source, targetId, modelHash)
    local xPlayer = allow(source, "alt_delete_entity")
    if not xPlayer then return false end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then return false end

    local wanted = unsignedHash(modelHash)
    if not wanted then return false end

    if not VFW.NetAttached or not VFW.NetAttached.Get or not VFW.NetAttached.Detach then return false end

    local slots = VFW.NetAttached.Get(target.source)
    for index, entity in pairs(slots) do
        if unsignedHash(entity.model) == wanted then
            if VFW.NetAttached.Detach(target.source, index) then
                logStaff(source, "delete_emote_prop", { target = target.source, model = wanted })
                return true
            end
        end
    end

    return false
end)

RegisterNetEvent("vfw:staff:setStaffPed", function(model)
    local source = source
    local xPlayer = allow(source, "persist_staff_ped")
    if not xPlayer then return end

    local resolved = readModel(model)
    if not resolved then return end

    xPlayer.setMeta("staffPed", resolved)
    logStaff(source, "set_staff_ped", { model = modelLabel(resolved) })
end)

RegisterNetEvent("vfw:staff:clearStaffPed", function()
    local source = source
    local xPlayer = allow(source, "persist_staff_ped")
    if not xPlayer then return end

    xPlayer.setMeta("staffPed", nil)
    logStaff(source, "clear_staff_ped", {})
end)

RegisterNetEvent("vfw:staff:setBlackout", function(state)
    local source = source
    local xPlayer = allowEvent(source)
    if not xPlayer then return end

    local enabled = state and true or false
    GlobalState.blackout = enabled
    TriggerClientEvent("vfw:staff:setBlackout", -1, enabled)

    logStaff(source, "blackout", { enabled = enabled })
end)

RegisterNetEvent("vfw:staff:startFire", function(data)
    local source = source
    local xPlayer = allowEvent(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end
    if not VFW.Fire or not VFW.Fire.Start then return end

    local coords = readVector(data.coords)
    if not coords then return end
    if not withinReach(xPlayer, coords, FIRE_ORIGIN_TOLERANCE) then return end

    local flames = readInteger(data.flames, 1, 60) or 15
    local spread = readInteger(data.spread, 1, 60) or 15
    local minutes = readInteger(data.duration, 1, 30) or 10
    local notifyRange = readRadius(data.notifyRange, 300.0) or 30.0
    local alarmDelay = readInteger(data.alarmDelay, 10, 120) or 30
    local wantAlarm = data.alarm == true
    local wantNotify = data.notify == true

    local function ignite()
        local fireId = VFW.Fire.Start({ position = coords, flames = flames, spread = spread })
        if not fireId then
            notify(source, "ERROR", "Incendie", "L'incendie n'a pas pu démarrer.")
            return
        end

        activeStaffFires[fireId] = true

        if wantNotify then
            sendNear(coords, notifyRange, "vfw:staff:fireNotification")
        end

        SetTimeout(minutes * 60000, function()
            if not activeStaffFires[fireId] then return end
            activeStaffFires[fireId] = nil
            if VFW.Fire and VFW.Fire.Stop then
                VFW.Fire.Stop(fireId)
            end
        end)

        logStaff(source, "start_fire", {
            coords = coords,
            flames = flames,
            spread = spread,
            duration = minutes,
            fireId = fireId,
        })
    end

    if wantAlarm then
        sendNear(coords, notifyRange, "vfw:staff:fireAlarmClient")
        SetTimeout(alarmDelay * 1000, ignite)
        return
    end

    ignite()
end)

RegisterNetEvent("vfw:staff:fireAlarm", function(data)
    local source = source
    local xPlayer = allowEvent(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    local coords = readVector(data.coords)
    if not coords then return end
    if not withinReach(xPlayer, coords, FIRE_ORIGIN_TOLERANCE) then return end

    local notifyRange = readRadius(data.notifyRange, 300.0) or 30.0

    sendNear(coords, notifyRange, "vfw:staff:fireAlarmClient")

    SetTimeout(9000, function()
        sendNear(coords, notifyRange, "vfw:staff:fireAlarmEnd")
    end)

    logStaff(source, "fire_false_alarm", { coords = coords, range = notifyRange })
end)

RegisterNetEvent("vfw:staff:stopAllFires", function()
    local source = source
    local xPlayer = allowEvent(source)
    if not xPlayer then return end
    if not VFW.Fire or not VFW.Fire.StopAll then return end

    activeStaffFires = {}
    VFW.Fire.StopAll()

    notify(source, "SUCCESS", "Incendie", "Tous les incendies ont été éteints.")
    logStaff(source, "stop_all_fires", {})
end)

RegisterNetEvent("vfw:staff:triggerEarthquake", function(durationMs)
    local source = source
    local xPlayer = allowEvent(source)
    if not xPlayer then return end
    if not VFW.Earthquake or not VFW.Earthquake.Start then return end

    local duration = readInteger(durationMs, 1000, 900000)
    if not duration then
        notify(source, "ERROR", "Séisme", "Cette durée n'est pas valide.")
        return
    end

    VFW.Earthquake.Start({ duration = duration })

    notify(source, "SUCCESS", "Séisme", "Le séisme est déclenché.")
    logStaff(source, "earthquake_start", { duration = duration })
end)

RegisterNetEvent("vfw:staff:stopEarthquakeManual", function()
    local source = source
    local xPlayer = allowEvent(source)
    if not xPlayer then return end
    if not VFW.Earthquake or not VFW.Earthquake.Stop then return end

    VFW.Earthquake.Stop()

    notify(source, "INFO", "Séisme", "Le séisme est arrêté.")
    logStaff(source, "earthquake_stop", {})
end)

RegisterNetEvent("vfw:staff:triggerFirework", function(durationMs, musicUrl, volume)
    local source = source
    local xPlayer = allowEvent(source, "builder_firework")
    if not xPlayer then return end

    if fireworkRunning then
        notify(source, "ERROR", "Feu d'artifice", "Un spectacle est déjà en cours.")
        return
    end

    local duration = readInteger(durationMs, 5000, 600000) or 120000

    local url
    if type(musicUrl) == "string" and musicUrl ~= "" then
        if #musicUrl > 512 or not musicUrl:match("^https://") then
            notify(source, "ERROR", "Feu d'artifice", "Ce lien de musique n'est pas accepté.")
            return
        end
        url = musicUrl
    end

    local level = readNumber(volume, 0.0, 1.0) or 0.5

    local origin = xPlayer.getCoords()
    if not origin then return end

    local center = { x = origin.x, y = origin.y, z = origin.z }

    fireworkRunning = true
    SetTimeout(duration + 5000, function()
        fireworkRunning = false
    end)

    for target in pairs(VFW.Players) do
        TriggerClientEvent("vfw:staff:startFirework", target, duration, url, level, center, target == source)
    end

    logStaff(source, "firework_start", { duration = duration, music = url ~= nil, coords = center })
end)

RegisterNetEvent("vfw:staff:stopFirework", function()
    local source = source
    local xPlayer = allowEvent(source, "builder_firework")
    if not xPlayer then return end

    fireworkRunning = false

    for target in pairs(VFW.Players) do
        TriggerClientEvent("vfw:staff:stopFirework", target, target == source)
    end

    logStaff(source, "firework_stop", {})
end)

local function giveItemTemp(source, targetId, itemName, count, duration, radius)
    local xPlayer = allow(source, "give_item", "menu_event", "menu_anim")
    if not xPlayer then return end

    if type(itemName) ~= "string" or itemName == "" or #itemName > 64 then return end
    if type(VFW.Items) ~= "table" or not VFW.Items[itemName] then
        notify(source, "ERROR", "Item temporaire", "Cet item n'existe pas.")
        return
    end

    local amount = readInteger(count, 1, 100)
    if not amount then
        notify(source, "ERROR", "Item temporaire", "Cette quantité n'est pas valide.")
        return
    end

    local minutes = readInteger(duration, -1, 60)
    if not minutes then
        notify(source, "ERROR", "Item temporaire", "Cette durée n'est pas valide.")
        return
    end
    local untilReboot = minutes == -1

    if not Feat27 or not Feat27.Inv or not Feat27.Inv.Give then return end

    local targets
    local single = VFW.GetPlayerFromId(tonumber(targetId))

    if single then
        targets = { single }
    else
        local range = readRadius(radius, 200.0)
        if not range then
            notify(source, "ERROR", "Item temporaire", "Ce joueur n'est pas connecté.")
            return
        end

        local origin = xPlayer.getCoords()
        if not origin then return end
        targets = VFW.GetPlayersInRadius(origin, range)
    end

    if #targets == 0 then
        notify(source, "INFO", "Item temporaire", "Aucun joueur à portée.")
        return
    end

    if #targets > MAX_TEMP_ITEM_TARGETS then
        notify(source, "ERROR", "Item temporaire", "Trop de joueurs à portée. Réduisez le rayon.")
        return
    end

    local given = 0
    for i = 1, #targets do
        local receiver = targets[i]
        if Feat27.Inv.Give(receiver, itemName, amount, nil, true) then
            given = given + 1

            if not untilReboot then
                local receiverId = receiver.source
                SetTimeout(minutes * 60000, function()
                    local still = VFW.GetPlayerFromId(receiverId)
                    if not still then return end
                    if not Feat27 or not Feat27.Inv or not Feat27.Inv.Take then return end
                    Feat27.Inv.Take(still, itemName, amount, false)
                end)
            end
        end
    end

    if given == 0 then
        notify(source, "ERROR", "Item temporaire", "L'item n'a pas pu être remis.")
        return
    end

    if given == 1 then
        notify(source, "SUCCESS", "Item temporaire",
            untilReboot and "Item remis jusqu'au reboot." or ("Item remis pour %d minutes."):format(minutes))
    else
        notify(source, "SUCCESS", "Item temporaire",
            untilReboot and ("Item remis à %d joueurs jusqu'au reboot."):format(given) or ("Item remis à %d joueurs pour %d minutes."):format(given, minutes))
    end

    logStaff(source, "give_item_temp", {
        item = itemName,
        count = amount,
        minutes = minutes,
        receivers = given,
    })
end

RegisterNetEvent("vfw:staff:giveItemTemp", function(targetId, itemName, count, duration, radius)
    giveItemTemp(source, targetId, itemName, count, duration, radius)
end)

RegisterNetEvent("vfw:animator:giveItemTemp", function(targetId, itemName, count, duration, radius)
    giveItemTemp(source, targetId, itemName, count, duration, radius)
end)

local function licenseMap(target)
    local owned = {}
    local list = target.licenses or {}

    for i = 1, #list do
        local entry = list[i]
        if type(entry) == "table" and type(entry.type) == "string" then
            owned[entry.type] = true
        end
    end

    local out = {}
    for dvmType, internal in pairs(STAFF_LICENSE_TYPES) do
        out[dvmType] = owned[internal] == true
    end
    return out
end

RegisterServerCallback("vfw:staff:getPlayerLicensesForRemoval", function(source, targetId)
    local xPlayer = allow(source, "retirer_permis")
    if not xPlayer then return nil end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then return nil end

    return {
        name = target.name,
        source = target.source,
        licenses = licenseMap(target),
    }
end)

-- Lecture mémoire uniquement (pas de SQL) : utilisé par le menu joueur + outils.
RegisterServerCallback("vfw:staff:getPlayerLicenses", function(source, targetId)
    local xPlayer = allow(source, "give_permis", "retirer_permis")
    if not xPlayer then return {} end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then return {} end

    return licenseMap(target)
end)

RegisterNetEvent("vfw:staff:giveLicense", function(targetId, licenseType)
    local source = source
    local xPlayer = allow(source, "give_permis")
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        notify(source, "ERROR", "Permis", "Ce joueur n'est pas connecté.")
        return
    end

    local internal = type(licenseType) == "string" and STAFF_LICENSE_TYPES[licenseType] or nil
    if not internal then return end
    if not Misc30 or not Misc30.GrantLicense then return end

    if not Misc30.GrantLicense(target, internal) then
        notify(source, "ERROR", "Permis", "Ce joueur a déjà ce permis (ou type invalide).")
        return
    end

    notify(source, "SUCCESS", "Permis", ("Permis attribué à %s."):format(target.name))
    notify(target.source, "INFO", "Permis", "Un permis vient de vous être attribué.")

    logStaff(source, "give_license", { target = target.source, license = internal })
end)

RegisterNetEvent("vfw:staff:removeLicense", function(targetId, licenseType)
    local source = source
    local xPlayer = allow(source, "retirer_permis")
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        notify(source, "ERROR", "Permis", "Ce joueur n'est pas connecté.")
        return
    end

    local internal = type(licenseType) == "string" and STAFF_LICENSE_TYPES[licenseType] or nil
    if not internal then return end

    if not Misc30 or not Misc30.RevokeLicense then return end

    Misc30.RevokeLicense(target, internal)

    notify(source, "SUCCESS", "Permis", ("Permis retiré à %s."):format(target.name))
    notify(target.source, "INFO", "Permis", "Un permis vient de vous être retiré.")

    logStaff(source, "remove_license", { target = target.source, license = internal })
end)

-- ══════════════════════════════════════════════════════════════════════════
-- Moitié serveur manquante pour freeze/unfreeze, spectate et goto/bring/return.
-- Le menu staff et les listeners client existaient déjà des deux côtés, mais
-- rien ne les reliait sur le serveur (spectate = écran noir bloqué, freeze =
-- aucun effet, goto/bring/return = commandes jamais enregistrées).
-- ══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("core:FreezePlayer", function(targetId, state)
    local source = source
    local xPlayer = allow(source, "freeze_player")
    if not xPlayer then return end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        notify(source, "ERROR", "Freeze", "Ce joueur n'est pas connecté.")
        return
    end

    local frozen = state == true
    TriggerClientEvent("core:FreezePlayer", target.source, frozen)

    logStaff(source, "freeze_player", { target = target.source, frozen = frozen })
end)

-- Le ped de l'admin ne bouge jamais pendant le spectate (seule la caméra change via
-- NetworkSetInSpectatorMode) : pas besoin de coordonnées à transmettre, ni au départ
-- ni au retour, le client gère déjà les deux cas avec coords = nil.
-- Position de l'admin avant le spectate, pour l'y ramener à la sortie.
local spectateOrigins = {}

local function xyz(xp)
    local c = xp and xp.getCoords()
    if not c then return nil end
    return { x = c.x, y = c.y, z = c.z }
end

RegisterNetEvent("core:StaffSpectate", function(targetId, isSpectating)
    local source = source
    local xPlayer = allow(source, "spectate")
    if not xPlayer then return end

    local spectating = isSpectating == true

    if not spectating then
        local back = spectateOrigins[source]
        spectateOrigins[source] = nil
        TriggerClientEvent("core:StaffSpectate", source, back, tonumber(targetId) or 0, false)
        logStaff(source, "spectate_player", { target = tonumber(targetId), spectating = false })
        return
    end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then
        notify(source, "ERROR", "Spectate", "Ce joueur n'est pas connecté.")
        return
    end

    -- Sans coordonnées, le client reste sur place : le ped de la cible n'est pas streamé et
    -- NetworkSetInSpectatorMode ne montre qu'un écran noir. On envoie donc la position de la
    -- cible (l'admin s'y téléporte invisible) et on garde la sienne pour le retour.
    spectateOrigins[source] = xyz(xPlayer)

    TriggerClientEvent("core:StaffSpectate", source, xyz(target), target.source, true)
    logStaff(source, "spectate_player", { target = target.source, spectating = true })
end)

VFW.RegisterCommand("unspectate", "spectate", function(source)
    local back = spectateOrigins[source]
    spectateOrigins[source] = nil
    TriggerClientEvent("core:StaffSpectate", source, back, 0, false)
end, { help = "Quitter le mode spectateur" })

AddEventHandler("playerDropped", function()
    spectateOrigins[source] = nil
end)

local function coordsTable(xp)
    local c = xp.getCoords()
    if not c then return nil end
    return { x = c.x, y = c.y, z = c.z }
end

-- Position d'un joueur avant un /bring, pour pouvoir le /return à sa place d'origine.
local bringOrigins = {}

-- Enregistrées via VFW.RegisterCommand : elles apparaissent dans les suggestions du chat et
-- passent par le pont `vfw:command:run` (le chat et le menu staff ne peuvent pas atteindre une
-- commande serveur avec ExecuteCommand côté client).
VFW.RegisterCommand("goto", "goto", function(source, xPlayer, args)
    local target = VFW.GetPlayerFromId(tonumber(args and args[1]))
    if not target then
        notify(source, "ERROR", "Goto", "Ce joueur n'est pas connecté.")
        return
    end

    local coords = target.getCoords()
    if not coords then return end

    TriggerClientEvent("vfw:teleportTo", source, coords.x, coords.y, coords.z)
    notify(source, "SUCCESS", "Goto", ("Téléporté sur %s."):format(target.name or ("#" .. target.source)))
    logStaff(source, "goto_player", { target = target.source })
end, {
    help = "Se téléporter sur un joueur",
    params = { { name = "id", help = "ID du joueur" } },
})

VFW.RegisterCommand("bring", "goto", function(source, xPlayer, args)
    local target = VFW.GetPlayerFromId(tonumber(args and args[1]))
    if not target then
        notify(source, "ERROR", "Bring", "Ce joueur n'est pas connecté.")
        return
    end

    local adminCoords = xPlayer and xPlayer.getCoords()
    if not adminCoords then return end

    bringOrigins[target.source] = coordsTable(target)

    TriggerClientEvent("vfw:teleportTo", target.source, adminCoords.x, adminCoords.y, adminCoords.z)
    notify(source, "SUCCESS", "Bring", ("%s a été téléporté jusqu'à vous."):format(target.name or ("#" .. target.source)))
    logStaff(source, "bring_player", { target = target.source })
end, {
    help = "Téléporter un joueur jusqu'à vous",
    params = { { name = "id", help = "ID du joueur" } },
})

VFW.RegisterCommand("return", "goto", function(source, xPlayer, args)
    local target = VFW.GetPlayerFromId(tonumber(args and args[1]))
    if not target then
        notify(source, "ERROR", "Return", "Ce joueur n'est pas connecté.")
        return
    end

    local origin = bringOrigins[target.source]
    if not origin then
        notify(source, "ERROR", "Return", "Aucune position de retour enregistrée pour ce joueur.")
        return
    end

    bringOrigins[target.source] = nil
    TriggerClientEvent("vfw:teleportTo", target.source, origin.x, origin.y, origin.z)
    notify(source, "SUCCESS", "Return", ("%s a été renvoyé à sa position."):format(target.name or ("#" .. target.source)))
    logStaff(source, "return_player", { target = target.source })
end, {
    help = "Renvoyer un joueur à sa position d'avant le bring",
    params = { { name = "id", help = "ID du joueur" } },
})

-- Même bug que goto/bring/return : le bouton "GPS POSITION" appelait ce callback,
-- jamais enregistré côté serveur (trouvé en passant, pas dans la liste d'origine).
RegisterServerCallback("core:CoordsOfPlayer", function(source, targetId)
    local xPlayer = allow(source, "goto")
    if not xPlayer then return nil end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then return nil end

    return coordsTable(target)
end)

AddEventHandler("playerDropped", function()
    local source = source
    entityBudget[source] = nil
    bringOrigins[source] = nil
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for propId, entry in pairs(staffProps) do
        if entry.entity and DoesEntityExist(entry.entity) then
            DeleteEntity(entry.entity)
        end
        staffProps[propId] = nil
    end
    staffPropCount = 0
end)

-- ── Actions staff sur un joueur (menu ALT) ──────────────────────────────────────────────
--
-- Les boutons du menu contextuel « ped » envoient une action au serveur, qui doit la relayer
-- au joueur vise. Le client sait les traiter depuis toujours (`vfw:ped:apply`), mais aucune
-- de ces actions n'etait enregistree cote serveur : le callback repondait « Action inconnue »
-- et rien ne se passait. Animations, plaquage, arret d'animation, teleportations : neuf
-- actions mortes.

--- Destinations fixes des teleportations staff. A ajuster si votre serveur place ces lieux
--- ailleurs : ce sont les positions GTA d'origine.
local STAFF_DESTINATIONS <const> = {
    police = { x = 441.0, y = -982.0, z = 30.7 },   -- commissariat de Mission Row
    cubes  = { x = 195.0, y = -934.0, z = 30.7 },   -- Legion Square, dite « place des cubes »
}

local PED_RANGE <const> = 30.0

--- Resout le joueur vise par le menu contextuel.
---@return table|nil target, string|nil erreur
local function contextTarget(source, ent)
    if type(ent) ~= "table" then return nil, "Cible introuvable." end

    local targetId = tonumber(ent.targetSource)
    if not targetId then return nil, "Cette action ne vaut que sur un joueur." end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return nil, "Ce joueur n'est plus connecte." end

    local me = VFW.GetPlayerFromId(source)
    local here = me and me.getCoords()
    local there = target.getCoords()

    if here and there then
        local dx, dy, dz = here.x - there.x, here.y - there.y, here.z - there.z
        if (dx * dx + dy * dy + dz * dz) > (PED_RANGE * PED_RANGE) then
            return nil, "Ce joueur est trop loin."
        end
    end

    return target, nil
end

--- Relaie l'action au client du joueur vise, avec le netId de son propre ped : c'est ce que
--- son gestionnaire verifie avant d'appliquer quoi que ce soit.
local function pedRelay(action, message)
    return function(source, ent, _, extra)
        local target, err = contextTarget(source, ent)
        if not target then return { ok = false, err = err } end

        local netId = tonumber(ent.netId) or 0
        if netId == 0 then return { ok = false, err = "Ce joueur n'est pas synchronise." } end

        TriggerClientEvent("vfw:ped:apply", target.source, action, netId, extra)
        return { ok = true, msg = message }
    end
end

--- Teleporte le joueur vise, en memorisant sa position pour que « renvoyer » fonctionne.
local function pedTeleport(resolve, message)
    return function(source, ent)
        local target, err = contextTarget(source, ent)
        if not target then return { ok = false, err = err } end

        local destination, failure = resolve(source, target)
        if not destination then return { ok = false, err = failure or "Destination inconnue." } end

        bringOrigins[target.source] = coordsTable(target)
        TriggerClientEvent("vfw:teleportTo", target.source, destination.x, destination.y, destination.z)
        logStaff(source, "context_teleport_player", { target = target.source })

        return { ok = true, msg = message }
    end
end

CreateThread(function()
    while type(VFW.ContextMenu) ~= "table" or type(VFW.ContextMenu.RegisterAction) ~= "function" do
        Wait(100)
    end

    local register = VFW.ContextMenu.RegisterAction

    register("ped:playAnim", pedRelay("ped:playAnim", "Animation jouee"), "alt_ped_management")
    register("ped:stopAnim", pedRelay("ped:stopAnim", "Animation arretee"), "alt_ped_management")
    register("ped:tackleDown", pedRelay("ped:tackleDown", "Joueur plaque au sol"), "alt_ped_management")

    register("ped:teleportToMe", pedTeleport(function(source)
        local me = VFW.GetPlayerFromId(source)
        local coords = me and me.getCoords()
        if not coords then return nil, "Votre position est introuvable." end
        return coords
    end, "Joueur amene jusqu'a vous"), "alt_teleport")

    register("ped:teleportToPolice", pedTeleport(function()
        return STAFF_DESTINATIONS.police
    end, "Joueur envoye au commissariat"), "alt_teleport")

    register("ped:teleportToPlaceDesCubes", pedTeleport(function()
        return STAFF_DESTINATIONS.cubes
    end, "Joueur envoye place des cubes"), "alt_teleport")

    register("ped:teleportToPound", pedTeleport(function()
        -- La fourriere est configurable en jeu : on prend la premiere enregistree.
        local ok, rows = pcall(MySQL.query.await, "SELECT position FROM pounds ORDER BY id ASC LIMIT 1")
        if not ok or type(rows) ~= "table" or not rows[1] then
            return nil, "Aucune fourriere n'est configuree."
        end

        local position = VFW.DB.Decode(rows[1].position, nil)
        if type(position) ~= "table" or not tonumber(position.x) then
            return nil, "La position de la fourriere est illisible."
        end

        return { x = tonumber(position.x), y = tonumber(position.y), z = tonumber(position.z) or 30.0 }
    end, "Joueur envoye a la fourriere"), "alt_teleport")

    register("ped:returnBroughtPlayer", function(source, ent)
        local target, err = contextTarget(source, ent)
        if not target then return { ok = false, err = err } end

        local origin = bringOrigins[target.source]
        if not origin then return { ok = false, err = "Aucune position de retour enregistree." } end

        bringOrigins[target.source] = nil
        TriggerClientEvent("vfw:teleportTo", target.source, origin.x, origin.y, origin.z)
        logStaff(source, "context_return_player", { target = target.source })

        return { ok = true, msg = "Joueur renvoye a sa position" }
    end, "alt_teleport")

    register("ped:delete", function(source, ent)
        if type(ent) ~= "table" then return { ok = false, err = "Cible introuvable." } end

        -- Un joueur ne se supprime pas : seuls les PNJ sont concernes.
        if ent.targetSource then
            return { ok = false, err = "On ne supprime pas un joueur." }
        end

        local entity = ent.entity
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            return { ok = false, err = "Ce PNJ n'existe plus." }
        end

        DeleteEntity(entity)
        logStaff(source, "context_delete_ped", {})

        return { ok = true, msg = "PNJ supprime" }
    end, "alt_ped_management")
end)

--- Un joueur connecte au hasard, pour la teleportation aleatoire du noclip (touche J).
---
--- Le tirage se fait cote serveur : le client ne connait que les joueurs proches de lui,
--- il ne pourrait donc tomber que sur ceux qu'il voit deja.
RegisterServerCallback("vfw:staff:randomPlayerCoords", function(source)
    local xPlayer = allow(source, "goto", "noclip", "staff_menu")
    if not xPlayer then return nil end

    local candidates, n = {}, 0
    for _, src in ipairs(VFW.GetPlayers()) do
        if src ~= source then
            local other = VFW.GetPlayerFromId(src)
            if other and other.getCoords() then
                n = n + 1
                candidates[n] = other
            end
        end
    end

    if n == 0 then return nil, "Aucun autre joueur connecte." end

    local picked = candidates[math.random(1, n)]
    local coords = picked.getCoords()

    logStaff(source, "random_teleport", { target = picked.source })

    return {
        coords = { x = coords.x, y = coords.y, z = coords.z },
        name = picked.name or ("#" .. picked.source),
        source = picked.source,
    }
end)

-- ── Apparence d'un joueur (menu Gestion Joueur) ─────────────────────────────────────────
--
-- « Recuperer son apparence » et « Appliquer une apparence » appelaient deux points d'entree
-- qui n'ont jamais existe : le menu affichait donc toujours « Impossible de recuperer
-- l'apparence ». Le skin vit sur le joueur cote serveur (xPlayer.skin) et s'applique chez le
-- client par l'evenement `skinchanger:loadSkin`, deja en place.

RegisterServerCallback("vfw:staff:getSkin", function(source, targetId)
    local xPlayer = allow(source, "recup_apparence")
    if not xPlayer then return nil end

    local target = VFW.GetPlayerFromId(tonumber(targetId))
    if not target then return nil end

    local skin = target.skin
    if type(skin) ~= "table" or not next(skin) then return nil end

    return skin, target.tattoos
end)

RegisterServerCallback("vfw:staff:applySkinToPlayer", function(source, sourceId, targetId)
    local xPlayer = allow(source, "recup_apparence")
    if not xPlayer then return false end

    local from = VFW.GetPlayerFromId(tonumber(sourceId))
    local to = VFW.GetPlayerFromId(tonumber(targetId))
    if not from or not to then return false end

    local skin = from.skin
    if type(skin) ~= "table" or not next(skin) then return false end

    -- Volontairement temporaire : rien n'est ecrit en base, l'apparence d'origine revient
    -- a la prochaine connexion du joueur. C'est ce qu'annonce le menu.
    TriggerClientEvent("skinchanger:loadSkin", to.source, skin)

    logStaff(source, "apply_skin", { from = from.source, target = to.source })

    return true
end)
