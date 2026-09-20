local VEST_TYPES = {
    ["gpb"] = true,
    ["kevlar"] = true,
}

local PLATE_LABELS = {
    ["armor_plate_light"] = "Plaque legere",
    ["armor_plate_medium"] = "Plaque moyenne",
    ["armor_plate_heavy"] = "Plaque lourde",
}

local MAX_DAMAGE_PER_TICK = 100
local FLUSH_DELAY = 350

local pendingDamage = {}
local flushScheduled = {}

local function findVest(list)
    local fallback = nil
    for i = 1, #list do
        local entry = list[i]
        local meta = entry.meta
        if meta and (VEST_TYPES[meta.type] or entry.name == "gpb") then
            if meta.equipped_bproof or meta._equippedSlot == entry.slot then
                return entry
            end
            if not fallback then fallback = entry end
        end
    end
    return fallback
end

local function totalPlateArmor(vest)
    if not vest or type(vest.meta) ~= "table" or type(vest.meta.plates) ~= "table" then return 0 end
    local total = 0
    for i = 1, #vest.meta.plates do
        total = total + (tonumber(vest.meta.plates[i].durability) or 0)
    end
    if total < 0 then total = 0 end
    if total > 100 then total = 100 end
    return math.floor(total)
end

local function weakestPlateIndex(plates)
    local best, bestValue = nil, nil
    for i = 1, #plates do
        local durability = tonumber(plates[i].durability) or 0
        if durability > 0 and (bestValue == nil or durability < bestValue) then
            best, bestValue = i, durability
        end
    end
    return best
end

local function applyDamage(source, amount)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local inv = Misc30.Inv()
    if not inv then return end

    local list = inv.PlayerList(xPlayer)
    local vest = findVest(list)
    if not vest then return end

    local before = totalPlateArmor(vest)
    if before <= 0 then return end

    if amount > before then amount = before end
    if amount <= 0 then return end

    vest.meta = vest.meta or {}
    if type(vest.meta.plates) ~= "table" then vest.meta.plates = {} end

    local plates = vest.meta.plates
    local remaining = amount
    local destroyed = {}

    while remaining > 0 do
        local index = weakestPlateIndex(plates)
        if not index then break end

        local plate = plates[index]
        local durability = tonumber(plate.durability) or 0

        if durability > remaining then
            plate.durability = durability - remaining
            remaining = 0
        else
            remaining = remaining - durability
            destroyed[#destroyed + 1] = plate.label or PLATE_LABELS[plate.name] or "Plaque"
            table.remove(plates, index)
        end
    end

    local after = totalPlateArmor(vest)

    for i = 1, #destroyed do
        TriggerClientEvent("vfw:armor:plateDestroyed", source, { plateType = destroyed[i] })
    end

    TriggerClientEvent("vfw:armor:durabilityUpdated", source, { totalArmor = after })

    inv.PushPlayer(xPlayer)
end

local function scheduleFlush(source)
    if flushScheduled[source] then return end
    flushScheduled[source] = true

    SetTimeout(FLUSH_DELAY, function()
        flushScheduled[source] = nil
        local amount = pendingDamage[source]
        pendingDamage[source] = nil
        if not amount or amount <= 0 then return end
        applyDamage(source, amount)
    end)
end

RegisterNetEvent("vfw:armor:syncDamage", function(damageTaken)
    local source = source

    local amount = Misc30.ToInt(damageTaken, 1, MAX_DAMAGE_PER_TICK)
    if not amount then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local current = pendingDamage[source] or 0
    if current >= MAX_DAMAGE_PER_TICK then return end

    pendingDamage[source] = math.min(MAX_DAMAGE_PER_TICK, current + amount)
    scheduleFlush(source)
end)

Misc30.Cb("vfw:armor:getEquippedPlates", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { totalArmor = 0 } end

    local inv = Misc30.Inv()
    if not inv then return { totalArmor = 0 } end

    local vest = findVest(inv.PlayerList(xPlayer))
    return { totalArmor = totalPlateArmor(vest) }
end)

AddEventHandler("vfw:playerDropped", function(source)
    pendingDamage[source] = nil
    flushScheduled[source] = nil
end)
