local occupancy = {}

VFW.Game = VFW.Game or {}

local function sanitizePlate(plate)
    if type(plate) ~= "string" then return nil end
    plate = plate:gsub("^%s+", ""):gsub("%s+$", "")
    if plate == "" or plate == "null" then return nil end
    return plate:sub(1, 12)
end

local function sanitizeSeat(seat)
    seat = tonumber(seat)
    if not seat then return nil end
    seat = math.floor(seat)
    if seat < -2 or seat > 16 then return nil end
    return seat
end

local function sanitizeNetId(netId)
    netId = tonumber(netId)
    if not netId or netId <= 0 then return 0 end
    return math.floor(netId)
end

local function sanitizeName(name)
    if type(name) ~= "string" then return nil end
    if name == "" or name == "null" then return nil end
    return name:sub(1, 32)
end

function VFW.Game.GetOccupancy(source)
    return occupancy[tonumber(source) or 0]
end

function VFW.Game.IsInVehicle(source)
    local entry = occupancy[tonumber(source) or 0]
    return entry ~= nil and entry.state == "in"
end

RegisterNetEvent("vfw:enteringVehicle", function(plate, seat, netId)
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = {
        state = "entering",
        plate = sanitizePlate(plate),
        seat = sanitizeSeat(seat),
        netId = sanitizeNetId(netId),
        at = os.time(),
    }

    occupancy[source] = entry

    TriggerEvent("vfw:game:vehicleEntering", source, entry)
end)

RegisterNetEvent("vfw:enteringVehicleAborted", function()
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local previous = occupancy[source]
    if previous and previous.state ~= "entering" then return end

    occupancy[source] = nil

    TriggerEvent("vfw:game:vehicleEnterAborted", source, previous)
end)

RegisterNetEvent("vfw:enteredVehicle", function(plate, seat, displayName, netId)
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = {
        state = "in",
        plate = sanitizePlate(plate),
        seat = sanitizeSeat(seat),
        model = sanitizeName(displayName),
        netId = sanitizeNetId(netId),
        at = os.time(),
    }

    occupancy[source] = entry

    TriggerEvent("vfw:game:vehicleEntered", source, entry)
end)

RegisterNetEvent("vfw:exitedVehicle", function(plate, seat, displayName, netId)
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local entry = {
        state = "out",
        plate = sanitizePlate(plate),
        seat = sanitizeSeat(seat),
        model = sanitizeName(displayName),
        netId = sanitizeNetId(netId),
        at = os.time(),
    }

    occupancy[source] = nil

    TriggerEvent("vfw:game:vehicleExited", source, entry)
end)

AddEventHandler("playerDropped", function()
    local source = source
    local entry = occupancy[source]

    occupancy[source] = nil

    if entry and entry.state == "in" then
        TriggerEvent("vfw:game:vehicleExited", source, entry)
    end
end)
