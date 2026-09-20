RegisterNetEvent("doorlock:client:create", function(doorlock)
    Doorlock.cache[#Doorlock.cache+1] = doorlock

    Doorlock:CreateDoorLock(doorlock.doorsData, doorlock.id)
end)

RegisterNetEvent("doorlock:client:delete", function(doorlockId)
    local index <const>, doorlock <const> = Doorlock:FindDoorlockById(doorlockId)

    if not index then
        return
    end

    Doorlock:RemoveDoor(doorlock.doorsData)
    table.remove(Doorlock.cache, index)
end)

RegisterNetEvent("doorlock:client:update", function(doorlock)
    local index <const> = Doorlock:FindDoorlockById(doorlock.id)

    if not index then
        return
    end

    -- Preserve client-side door hashes (generated in CreateDoorLock)
    local existing <const> = Doorlock.cache[index]
    if existing and existing.doorsData then
        for i = 1, #existing.doorsData do
            if doorlock.doorsData and doorlock.doorsData[i] and existing.doorsData[i].hash then
                doorlock.doorsData[i].hash = existing.doorsData[i].hash
            end
        end
    end

    Doorlock.cache[index] = doorlock
end)

RegisterNetEvent("doorlock:client:toggleDoor", function(doorlockId, newState)
    local index <const>, doorlock <const> = Doorlock:FindDoorlockById(doorlockId)

    if not index then
        return
    end

    local doorsData <const> = doorlock.doorsData

    if not doorsData or not next(doorsData) then
        return
    end

    if newState == 0 then
        doorlock.isLocked = false
    else
        doorlock.isLocked = true
    end

    for i = 1, #doorsData do
        DoorSystemSetDoorState(doorsData[i].hash, newState, false, true)
    end

    if currentNearDoorId == doorlockId and currentNearSource == "custom" then
        Doorlock:SendNuiStatus(doorlock)
    end
end)