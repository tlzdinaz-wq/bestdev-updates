VFW.Screen = {}

local currentPed = nil
local nearbyPedsList = {}
local nearbyPedsMap = {}

local gridConfig = {
    rows = 3,
    cols = 4
}

local maxDistance = 5.0
local screenPositions = {}
local startX = 0.8
local startY = 0.25
local spacingX = 0.08
local spacingY = 0.18

local maleModelHash = 1885233650
local femaleModelHash = -1667301416

local idleAnimDict = "anim@amb@nightclub@peds@"
local idleAnimName = "rcmme_amanda1_stand_loop_cop"

local nearbyGridPositions = {
    { x = 0.68, y = 0.25 }, { x = 0.74, y = 0.25 }, { x = 0.8, y = 0.25 }, { x = 0.86, y = 0.25 },
    { x = 0.68, y = 0.47 }, { x = 0.74, y = 0.47 }, { x = 0.8, y = 0.47 }, { x = 0.86, y = 0.47 },
    { x = 0.68, y = 0.65 }, { x = 0.74, y = 0.65 }, { x = 0.8, y = 0.65 }, { x = 0.86, y = 0.65 }
}

for row = 1, gridConfig.rows do
    for col = 1, gridConfig.cols do
        local index = (row - 1) * gridConfig.cols + col
        screenPositions[index] = {
            x = startX + (col - 1) * spacingX,
            y = startY + (row - 1) * spacingY,
            z = 0.0
        }
    end
end

local function configurePreviewPed(ped)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end

local function playIdleAnim(ped)
    lib.requestAnimDict(idleAnimDict)
    TaskPlayAnim(ped, idleAnimDict, idleAnimName, 8.0, -8.0, -1, 1, 0.0, false, false, false)
end

local function isPedTracked(ped)
    if currentPed == ped then
        return true
    end

    for _, tracked in pairs(nearbyPedsMap) do
        if tracked == ped then
            return true
        end
    end

    return false
end

local function startPedCameraThread(pedEntity, screenX, screenY, distance)
    CreateThread(function()
        while DoesEntityExist(pedEntity) do
            if not isPedTracked(pedEntity) then
                break
            end

            local worldCoords, forwardVec = GetWorldCoordFromScreenCoord(screenX, screenY)
            local targetCoords = worldCoords + forwardVec * distance
            local camRotation = GetGameplayCamRot(2)

            SetEntityCoords(pedEntity, targetCoords.x, targetCoords.y, targetCoords.z - 1.0, false, false, false, true)
            SetEntityHeading(pedEntity, camRotation.z + 180.0)

            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)

            Wait(0)
        end
    end)
end

local function getFixedCamRelativePosition(distance)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local pitch = math.rad(camRot.x)
    local yaw = math.rad(camRot.z)
    local dir = vector3(
            -math.sin(yaw) * math.cos(pitch),
            math.cos(yaw) * math.cos(pitch),
            math.sin(pitch)
    )
    local offset = dir * distance
    return camCoords + offset, camRot
end

function VFW.Screen.Create(animData)
    if currentPed then
        DeleteEntity(currentPed)
        currentPed = nil
    end

    local playerPed = PlayerPedId()
    local pedModel = GetEntityModel(playerPed)

    lib.requestModel(pedModel, 1000)

    local screenX, screenY = 0.503, 0.45
    local worldCoords, forwardDir = GetWorldCoordFromScreenCoord(screenX, screenY)
    local spawnCoords = worldCoords + forwardDir * 1.5
    local camRotation = GetGameplayCamRot(2)

    local createdPed = CreatePed(4, pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, camRotation.z + 180.0, false, true)

    if not DoesEntityExist(createdPed) then
        return nil
    end

    currentPed = createdPed

    configurePreviewPed(createdPed)
    ClonePedToTarget(playerPed, createdPed)

    if animData and animData.dict and animData.anim then
        lib.requestAnimDict(animData.dict)
        TaskPlayAnim(createdPed, animData.dict, animData.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end

    local rotationBuffer = {}
    local bufferSize = 5
    local fixedDepth = 3.5

    CreateThread(function()
        while DoesEntityExist(createdPed) and currentPed == createdPed do
            local targetPos, camRot = getFixedCamRelativePosition(fixedDepth)

            table.insert(rotationBuffer, camRot)
            if #rotationBuffer > bufferSize then
                table.remove(rotationBuffer, 1)
            end

            local averagedRotation = vector3(0, 0, 0)
            for _, rotation in ipairs(rotationBuffer) do
                averagedRotation = averagedRotation + rotation
            end
            averagedRotation = averagedRotation / #rotationBuffer

            SetEntityCoordsNoOffset(currentPed, targetPos.x, targetPos.y, targetPos.z, false, false, false)
            SetEntityRotation(currentPed, -averagedRotation.x, 0.0, averagedRotation.z + 180.0, 2, true)

            Wait(0)
        end
    end)

    return createdPed
end

function VFW.Screen.Delete(targetEntity)
    if targetEntity then
        if DoesEntityExist(targetEntity) then
            SetEntityAsNoLongerNeeded(targetEntity)
            DeleteEntity(targetEntity)
        end
        return
    end

    if currentPed then
        if DoesEntityExist(currentPed) then
            SetEntityAsNoLongerNeeded(currentPed)
            DeleteEntity(currentPed)
        end
        currentPed = nil
    end
end

function VFW.Screen.GetPed(data, index)
    if not data or not data.ped then
        return nil
    end

    local posConfig = screenPositions[index]
    if not posConfig then
        return nil
    end

    local model = IsPedMale(data.ped) and maleModelHash or femaleModelHash

    lib.requestModel(model, 1000)

    local worldCoords, forwardVec = GetWorldCoordFromScreenCoord(posConfig.x, posConfig.y)
    local spawnCoords = worldCoords + forwardVec * 3.5
    local camRotation = GetGameplayCamRot(2)

    local createdPed = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, camRotation.z + 180.0, false, true)

    if not DoesEntityExist(createdPed) then
        return nil
    end

    configurePreviewPed(createdPed)

    for component = 0, 11 do
        local drawable = GetPedDrawableVariation(data.ped, component)
        local texture = GetPedTextureVariation(data.ped, component)
        SetPedComponentVariation(createdPed, component, drawable, texture, 0)
    end

    playIdleAnim(createdPed)
    startPedCameraThread(createdPed, posConfig.x, posConfig.y, 3.5)

    return createdPed
end

function VFW.Screen.GetNearbyPlayers()
    local playersInRange = {}
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local activePlayers = GetActivePlayers()

    for _, playerId in ipairs(activePlayers) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(myCoords - targetCoords)

            if distance <= maxDistance then
                table.insert(playersInRange, {
                    id = playerId,
                    serverId = GetPlayerServerId(playerId),
                    ped = targetPed,
                    coords = targetCoords,
                    distance = distance,
                    name = GetPlayerName(playerId)
                })
            end
        end
    end

    table.sort(playersInRange, function(a, b)
        return a.distance < b.distance
    end)

    return playersInRange
end

function VFW.Screen.DisplayNearbyPlayers(playersData)
    local dataToDisplay = {}
    if playersData and type(playersData) == "table" and #playersData > 0 then
        dataToDisplay = playersData
    end

    local currentFramePeds = {}
    nearbyPedsList = {}

    for i, playerData in ipairs(dataToDisplay) do
        if i > 12 then
            break
        end

        local posConfig = nearbyGridPositions[i]
        if posConfig then
            local playerKey = tostring(playerData.id)
            local existingPed = nearbyPedsMap[playerKey]

            if existingPed and DoesEntityExist(existingPed) then
                local worldCoords, forwardVec = GetWorldCoordFromScreenCoord(posConfig.x, posConfig.y)
                local newPos = worldCoords + forwardVec * 10.0
                local camRot = GetGameplayCamRot(2)

                SetEntityCoords(existingPed, newPos.x, newPos.y, newPos.z - 1.0, false, false, false, true)
                SetEntityHeading(existingPed, camRot.z + 180.0)

                currentFramePeds[playerKey] = existingPed
                table.insert(nearbyPedsList, {
                    player = playerData,
                    ped = existingPed
                })
            else
                local sourcePed = playerData.ped
                if not sourcePed or not DoesEntityExist(sourcePed) then
                    sourcePed = PlayerPedId()
                end

                local model = GetEntityModel(sourcePed)
                if not model or model == 0 then
                    model = maleModelHash
                end

                lib.requestModel(model, 1000)

                local worldCoords, forwardVec = GetWorldCoordFromScreenCoord(posConfig.x, posConfig.y)
                local spawnPos = worldCoords + forwardVec * 10.0
                local camRot = GetGameplayCamRot(2)

                local newPed = CreatePed(4, model, spawnPos.x, spawnPos.y, spawnPos.z - 1.0, camRot.z + 180.0, false, true)

                if DoesEntityExist(newPed) then
                    configurePreviewPed(newPed)
                    ClonePedToTarget(sourcePed, newPed)
                    playIdleAnim(newPed)
                    startPedCameraThread(newPed, posConfig.x, posConfig.y, 10.0)

                    nearbyPedsMap[playerKey] = newPed
                    currentFramePeds[playerKey] = newPed
                    table.insert(nearbyPedsList, {
                        player = playerData,
                        ped = newPed
                    })
                end
            end
        end
    end

    for key, ped in pairs(nearbyPedsMap) do
        if not currentFramePeds[key] then
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
            nearbyPedsMap[key] = nil
        end
    end

    nearbyPedsMap = currentFramePeds

    return #nearbyPedsList > 0
end

function VFW.Screen.ClearNearbyPlayers()
    for _, entry in ipairs(nearbyPedsList) do
        local entity = type(entry) == "table" and entry.ped or entry
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    for _, entity in pairs(nearbyPedsMap) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    nearbyPedsList = {}
    nearbyPedsMap = {}
end

function VFW.Screen.GetPlayerServerIdAtPosition(index)
    local entry = nearbyPedsList[index]
    if entry and entry.player then
        return entry.player.serverId
    end
    return nil
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        VFW.Screen.Delete()
        VFW.Screen.ClearNearbyPlayers()
    end
end)

exports("PedScreenCreate", VFW.Screen.Create)
exports("PedScreenDelete", VFW.Screen.Delete)
exports("PedScreenGetPed", VFW.Screen.GetPed)
exports("NearbyPlayersDisplay", VFW.Screen.DisplayNearbyPlayers)
exports("NearbyPlayersClear", VFW.Screen.ClearNearbyPlayers)
exports("NearbyPlayersGetServerId", VFW.Screen.GetPlayerServerIdAtPosition)
