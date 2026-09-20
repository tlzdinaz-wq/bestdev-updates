VFW.PedScale = {}

local DEFAULT_SCALE = 1.0
local scaledPeds = {}

local function asVec(vec)
    if type(vec) == "vector3" then return vec end
    if type(vec) == "table" then
        local x, y, z = tonumber(vec.x or vec[1]), tonumber(vec.y or vec[2]), tonumber(vec.z or vec[3])
        if x and y and z then return vector3(x, y, z) end
    end
    return vector3(0.0, 0.0, 0.0)
end

local function norm(vec)
    vec = asVec(vec)
    local mag = math.sqrt(vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2)
    if mag > 0.0001 then
        return vec / mag
    end
    return vec
end

local function applyScaleToEntity(ped, scale)
    local a, b, c, d, e, f, g, h, i, j, k, l = GetEntityMatrix(ped)
    local forward, right, upVector, position
    if type(a) == "vector3" or type(a) == "table" then
        forward, right, upVector, position = a, b, c, d
    else
        forward = vector3(tonumber(a) or 0.0, tonumber(b) or 0.0, tonumber(c) or 0.0)
        right = vector3(tonumber(d) or 0.0, tonumber(e) or 0.0, tonumber(f) or 0.0)
        upVector = vector3(tonumber(g) or 0.0, tonumber(h) or 0.0, tonumber(i) or 0.0)
        position = vector3(tonumber(j) or 0.0, tonumber(k) or 0.0, tonumber(l) or 0.0)
    end
    position = asVec(position)

    local forwardNorm = norm(forward) * scale
    local rightNorm = norm(right) * scale
    local upNorm = norm(upVector) * scale

    local zOffset = (1.0 - scale) * 0.5
    local adjustedZ = position.z - zOffset

    if GetEntitySpeed(ped) > 0 then
        adjustedZ = adjustedZ - zOffset
    else
        adjustedZ = adjustedZ + zOffset
    end

    SetEntityMatrix(ped,
        forwardNorm.x, forwardNorm.y, forwardNorm.z,
        rightNorm.x, rightNorm.y, rightNorm.z,
        upNorm.x, upNorm.y, upNorm.z,
        position.x, position.y, adjustedZ
    )
end

function VFW.PedScale.GetOf(serverId)
    return scaledPeds[tonumber(serverId)] or DEFAULT_SCALE
end

function VFW.PedScale.PreviewLocal(scale)
    scale = tonumber(scale) or DEFAULT_SCALE
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        applyScaleToEntity(ped, scale)
    end
end

RegisterNetEvent("pedscale:sync", function(serverId, scale)
    serverId = tonumber(serverId)
    if not serverId then return end

    local previous = scaledPeds[serverId]
    scaledPeds[serverId] = scale

    if previous and not scale then
        local pid = GetPlayerFromServerId(serverId)
        if pid ~= -1 then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and DoesEntityExist(ped) then
                applyScaleToEntity(ped, DEFAULT_SCALE)
            end
        end
    end
end)

RegisterNetEvent("pedscale:syncAll", function(map)
    if type(map) ~= "table" then return end
    for src, scale in pairs(map) do
        scaledPeds[tonumber(src)] = scale
    end
end)

CreateThread(function()
    while true do
        if next(scaledPeds) ~= nil then
            for serverId, scale in pairs(scaledPeds) do
                local pid = GetPlayerFromServerId(serverId)
                if pid ~= -1 then
                    local ped = GetPlayerPed(pid)
                    if ped ~= 0 and DoesEntityExist(ped) then
                        applyScaleToEntity(ped, scale)
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
