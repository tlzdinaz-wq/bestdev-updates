local fallback = {}
local useFallback = false

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

local function getOccupancy(src)
    src = tonumber(src)
    if not src then return nil end

    if useFallback then
        return fallback[src]
    end

    if type(VFW.Game.GetOccupancy) == "function" then
        local ok, entry = pcall(VFW.Game.GetOccupancy, src)
        if ok then return entry end
    end

    return fallback[src]
end

function VFW.GetPlayerVehicleState(source)
    return getOccupancy(source)
end

function VFW.IsPlayerInVehicle(source)
    local entry = getOccupancy(source)
    return entry ~= nil and entry.state == "in"
end

function VFW.GetPlayerVehicleNetId(source)
    local entry = getOccupancy(source)
    if not entry or entry.state ~= "in" then return 0 end
    return entry.netId or 0
end

function VFW.GetPlayerVehiclePlate(source)
    local entry = getOccupancy(source)
    if not entry or entry.state ~= "in" then return nil end
    return entry.plate
end

function VFW.GetPlayerSeat(source)
    local entry = getOccupancy(source)
    if not entry or entry.state ~= "in" then return nil end
    return entry.seat
end

function VFW.GetPlayersInVehicle(netId)
    netId = sanitizeNetId(netId)

    local out, n = {}, 0
    if netId == 0 then return out end

    local players = VFW.GetPlayers()
    for i = 1, #players do
        local src = players[i]
        local entry = getOccupancy(src)
        if entry and entry.state == "in" and entry.netId == netId then
            n = n + 1
            out[n] = src
        end
    end

    return out
end

function VFW.GetVehicleDriver(netId)
    netId = sanitizeNetId(netId)
    if netId == 0 then return nil end

    local players = VFW.GetPlayers()
    for i = 1, #players do
        local src = players[i]
        local entry = getOccupancy(src)
        if entry and entry.state == "in" and entry.netId == netId and entry.seat == -1 then
            return src
        end
    end

    return nil
end

function VFW.GetVehicleNetEntity(netId)
    netId = sanitizeNetId(netId)
    if netId == 0 then return 0 end

    local ok, entity = pcall(NetworkGetEntityFromNetworkId, netId)
    if not ok or type(entity) ~= "number" or entity == 0 then return 0 end
    if not DoesEntityExist(entity) then return 0 end

    return entity
end

local function installFallback()
    useFallback = true

    console.warn("[Game] VFW.Game absent : suivi véhicule de secours activé dans modules/game/server/210_vehicle_helpers.lua")

    RegisterNetEvent("vfw:enteringVehicle", function(plate, seat, netId)
        local source = source
        if not VFW.GetPlayerFromId(source) then return end

        fallback[source] = {
            state = "entering",
            plate = sanitizePlate(plate),
            seat = sanitizeSeat(seat),
            netId = sanitizeNetId(netId),
            at = os.time(),
        }

        TriggerEvent("vfw:game:vehicleEntering", source, fallback[source])
    end)

    RegisterNetEvent("vfw:enteringVehicleAborted", function()
        local source = source
        if not VFW.GetPlayerFromId(source) then return end

        local previous = fallback[source]
        if previous and previous.state ~= "entering" then return end

        fallback[source] = nil

        TriggerEvent("vfw:game:vehicleEnterAborted", source, previous)
    end)

    RegisterNetEvent("vfw:enteredVehicle", function(plate, seat, displayName, netId)
        local source = source
        if not VFW.GetPlayerFromId(source) then return end

        fallback[source] = {
            state = "in",
            plate = sanitizePlate(plate),
            seat = sanitizeSeat(seat),
            model = sanitizeName(displayName),
            netId = sanitizeNetId(netId),
            at = os.time(),
        }

        TriggerEvent("vfw:game:vehicleEntered", source, fallback[source])
    end)

    RegisterNetEvent("vfw:exitedVehicle", function(plate, seat, displayName, netId)
        local source = source
        if not VFW.GetPlayerFromId(source) then return end

        local entry = {
            state = "out",
            plate = sanitizePlate(plate),
            seat = sanitizeSeat(seat),
            model = sanitizeName(displayName),
            netId = sanitizeNetId(netId),
            at = os.time(),
        }

        fallback[source] = nil

        TriggerEvent("vfw:game:vehicleExited", source, entry)
    end)

    AddEventHandler("vfw:playerDropped", function(source)
        local src = tonumber(source)
        if not src then return end

        local entry = fallback[src]
        fallback[src] = nil

        if entry and entry.state == "in" then
            TriggerEvent("vfw:game:vehicleExited", src, entry)
        end
    end)
end

CreateThread(function()
    Wait(0)

    if type(VFW.Game) ~= "table" or type(VFW.Game.GetOccupancy) ~= "function" then
        installFallback()
    end
end)
