---@meta _
---@diagnostic disable: duplicate-doc-field

local MAX_INTERACT_DISTANCE = 3.0

local function isPedDead(ped)
    if IsPedDeadOrDying(ped, true) then return true end
    if IsEntityPlayingAnim(ped, "dead", "dead_a", 3) then return true end
    if IsEntityPlayingAnim(ped, "veh@low@front_ps@idle_duck", "sit", 3) then return true end
    return false
end

local function getDeadOccupants(veh)
    local results = {}
    if not DoesEntityExist(veh) then return results end

    local maxPassengers = GetVehicleMaxNumberOfPassengers(veh)
    for seat = -1, math.max(3, maxPassengers) do
        local ped = GetPedInVehicleSeat(veh, seat)
        if ped ~= 0 and DoesEntityExist(ped) and IsPedAPlayer(ped) and ped ~= PlayerPedId() then
            if isPedDead(ped) then
                local playerIndex = NetworkGetPlayerIndexFromPed(ped)
                local src = playerIndex >= 0 and GetPlayerServerId(playerIndex) or nil
                if src then
                    results[#results + 1] = { ped = ped, seat = seat, src = src }
                end
            end
        end
    end
    return results
end

local function getClosestDeadOccupant(veh, fromCoords)
    local occupants = getDeadOccupants(veh)
    if #occupants == 0 then return nil end

    local closest, closestDist = nil, math.huge
    for _, occ in ipairs(occupants) do
        local d = #(fromCoords - GetEntityCoords(occ.ped))
        if d < closestDist then
            closestDist = d
            closest = occ
        end
    end
    return closest, #occupants
end

VFW.ContextAddButton("vehicle", ":door: Sortir le corps", function(veh)
    if not DoesEntityExist(veh) then return false end

    local myPed = VFW.PlayerData and VFW.PlayerData.ped or PlayerPedId()
    if not DoesEntityExist(myPed) then return false end

    if Death and Death.isDead then return false end
    if VFW.PlayerData and VFW.PlayerData.dead then return false end
    if IsPedInAnyVehicle(myPed, false) then return false end
    if VFW.IsCarrying and VFW.IsCarrying() then return false end

    local myCoords = GetEntityCoords(myPed)
    if #(myCoords - GetEntityCoords(veh)) > MAX_INTERACT_DISTANCE then return false end

    return #getDeadOccupants(veh) > 0
end, function(veh)
    local myPed = VFW.PlayerData and VFW.PlayerData.ped or PlayerPedId()
    local closest = getClosestDeadOccupant(veh, GetEntityCoords(myPed))

    if not closest then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun corps à sortir." })
        return
    end

    VFW.CloseContextMenu()
    VFW.CarryPeople(closest.ped)
end)
