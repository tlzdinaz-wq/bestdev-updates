local CONFIG = {
    SCAN_INTERVAL_FAR = 500,
    SCAN_INTERVAL_MEDIUM = 250,
    SCAN_INTERVAL_NEAR = 0,
    RENDER_DISTANCE = 20.0,
    MEDIUM_DISTANCE = 8.0,
    INTERACT_DISTANCE = 5.0,
    HELP_REFRESH_INTERVAL = 300,
    FADE_DURATION = 500,
    POST_TELEPORT_WAIT = 1000
}

ElevatorsData = {}

local elevatorCenterCache = {}
local whitelistCache = {}
local lastHelpShown = 0

local selectedElevatorIndex = nil
local selectedFloorIndex = nil
local isNUIOpen = false
local currentThread = nil

local function getPlayerJobAndGrade()
    local jobData = VFW and VFW.PlayerData and VFW.PlayerData.job
    if not jobData then
        return "unemployed", 0, "unemployed"
  end

    return jobData.name or "unemployed", tonumber(jobData.grade) or 0, jobData.grade_name or ""
end

local function listToSet(list)
    if not list then return nil end

    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

local function calculateElevatorCenter(elevator)
    if not elevator.floors or #elevator.floors == 0 then
        return vector3(0, 0, 0)
    end

    local totalX, totalY, totalZ = 0, 0, 0
    local validFloors = 0

    for i = 1, #elevator.floors do
        local coords = elevator.floors[i].coords
        if coords and coords.x and coords.y and coords.z then
            totalX = totalX + coords.x
            totalY = totalY + coords.y
            totalZ = totalZ + coords.z
            validFloors = validFloors + 1
        end
    end

    if validFloors == 0 then
        return vector3(0, 0, 0)
    end

    return vector3(totalX / validFloors, totalY / validFloors, totalZ / validFloors)
end

local function initializeCaches()
    elevatorCenterCache = {}
    whitelistCache = {}

    for elevatorIndex, elevator in pairs(ElevatorsData) do
        elevatorCenterCache[elevatorIndex] = calculateElevatorCenter(elevator)
    end
end

local function updateElevatorCacheEntry(elevatorIndex)
    local elevator = ElevatorsData[elevatorIndex]
    if elevator then
        elevatorCenterCache[elevatorIndex] = calculateElevatorCenter(elevator)
    else
        elevatorCenterCache[elevatorIndex] = nil
    end
end

local function clearAllCaches()
    whitelistCache = {}
end

local function isFloorAllowedForPlayer(floor)
    local whitelist = floor.whitelist
    if not whitelist then return true end

    local cacheKey = json.encode(whitelist)

    if not whitelistCache[cacheKey] then
        whitelistCache[cacheKey] = {
            jobs = whitelist.jobs and listToSet(whitelist.jobs) or nil,
            gradesByJob = {}
        }

        if whitelist.gradesByJob then
            for job, grades in pairs(whitelist.gradesByJob) do
                whitelistCache[cacheKey].gradesByJob[job] = listToSet(grades)
            end
        end
    end

    local cache = whitelistCache[cacheKey]
    local playerJob, playerGrade, playerGradeName = getPlayerJobAndGrade()

    if cache.jobs and not cache.jobs[playerJob] then
        return false
    end

    if cache.gradesByJob[playerJob] then
        local allowedGrades = cache.gradesByJob[playerJob]
        if not (allowedGrades[playerGrade] or allowedGrades[playerGradeName]) then
            return false
        end
    end

    return true
end

local function getClosestFloorFromPlayer(playerCoords)
    local closestDistance = math.huge
    local closestFloor, closestElevatorIndex, closestFloorIndex = nil, nil, nil
    local renderRangeSq = (CONFIG.RENDER_DISTANCE * 1.5) * (CONFIG.RENDER_DISTANCE * 1.5)

    for elevatorIndex, centerCoords in pairs(elevatorCenterCache) do
        local dx = playerCoords.x - centerCoords.x
        local dy = playerCoords.y - centerCoords.y
        local dz = playerCoords.z - centerCoords.z
        if (dx * dx + dy * dy + dz * dz) <= renderRangeSq then
            local elevator = ElevatorsData[elevatorIndex]
            if elevator and elevator.floors then
                for floorIndex = 1, #elevator.floors do
                    local floor = elevator.floors[floorIndex]
                    local coords = floor and floor.coords
                    if coords and coords.x and coords.y and coords.z then
                        local fdx = playerCoords.x - coords.x
                        local fdy = playerCoords.y - coords.y
                        local fdz = playerCoords.z - coords.z
                        local distance = math.sqrt(fdx * fdx + fdy * fdy + fdz * fdz)

                        if distance < closestDistance then
                            closestDistance = distance
                            closestFloor = floor
                            closestElevatorIndex = elevatorIndex
                            closestFloorIndex = floorIndex
                        end
                    end
                end
            end
        end
    end

    return closestFloor, closestDistance, closestElevatorIndex, closestFloorIndex
end

local function buildAccessibleFloorsList(elevator, currentFloorIndex)
    local accessibleFloors = {}
    local currentFloorNumber = nil

    for floorIndex = 1, #elevator.floors do
        local floor = elevator.floors[floorIndex]
        if isFloorAllowedForPlayer(floor) then
            table.insert(accessibleFloors, {
                index = floorIndex,
                label = floor.label or ("Étage " .. floorIndex)
            })

            if floorIndex == currentFloorIndex then
                currentFloorNumber = floorIndex
            end
        end
    end

    if not currentFloorNumber and #accessibleFloors > 0 then
        currentFloorNumber = accessibleFloors[1].index
    end

    return accessibleFloors, currentFloorNumber
end

local function handleElevatorInteraction(elevatorIndex, floorIndex)
    if isNUIOpen then return end

    local elevator = ElevatorsData[elevatorIndex]
    if not elevator then return end

    local accessibleFloors, currentFloorNumber = buildAccessibleFloorsList(elevator, floorIndex)

    if #accessibleFloors == 0 then return end

    selectedElevatorIndex = elevatorIndex
    selectedFloorIndex = floorIndex
    isNUIOpen = true

    SendNUIMessage({
        action = "nui:elevator:open",
        data = {
            currentFloor = currentFloorNumber,
            floors = accessibleFloors
        }
    })

    VFW.Nui.Focus(true, false)
end

local function teleportPlayerToFloor(floor)
    if not floor or not floor.coords then return false end

    local playerPed = PlayerPedId()
    local coords = floor.coords

    DoScreenFadeOut(CONFIG.FADE_DURATION)

    local fadeStart = GetGameTimer()
    while not IsScreenFadedOut() and (GetGameTimer() - fadeStart) < CONFIG.FADE_DURATION * 2 do
        Wait(0)
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local collisionStart = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(playerPed) and (GetGameTimer() - collisionStart) < 5000 do
        Wait(50)
    end

    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)

    Wait(CONFIG.POST_TELEPORT_WAIT)
    DoScreenFadeIn(CONFIG.FADE_DURATION)

    return true
end

local function closeNUI()
    if isNUIOpen then
        VFW.Nui.Focus(false, false)
        isNUIOpen = false
        selectedElevatorIndex = nil
        selectedFloorIndex = nil
    end
end

local function startElevatorThread()
    if currentThread then return end

    currentThread = CreateThread(function()
        while next(ElevatorsData) do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local closestFloor, distance, elevatorIndex, floorIndex = getClosestFloorFromPlayer(playerCoords)

            if closestFloor and distance <= CONFIG.INTERACT_DISTANCE then
                local now = GetGameTimer()
                if (now - lastHelpShown) >= CONFIG.HELP_REFRESH_INTERVAL then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour utiliser l'ascenseur")
                    lastHelpShown = now
                end

                if VFW.Interact.JustPressed(0, 38) then
                    handleElevatorInteraction(elevatorIndex, floorIndex)
                end

                Wait(CONFIG.SCAN_INTERVAL_NEAR)
            elseif closestFloor and distance <= CONFIG.MEDIUM_DISTANCE then
                Wait(CONFIG.SCAN_INTERVAL_MEDIUM)
            else
                Wait(CONFIG.SCAN_INTERVAL_FAR)
            end
        end

        currentThread = nil
    end)
end

RegisterNUICallback("nui:elevator:selectFloor", function(data, cb)
    local success, result = pcall(function()
        if not data.floor or not selectedElevatorIndex or not selectedFloorIndex then
            return "error"
      end

        local elevator = ElevatorsData[selectedElevatorIndex]
        if not elevator or not elevator.floors then
            return "error"
      end

        local currentFloor = elevator.floors[selectedFloorIndex]
        if not currentFloor or not currentFloor.coords then
            return "error"
      end

        local playerCoords = GetEntityCoords(PlayerPedId())
        local floorCoords = vector3(currentFloor.coords.x, currentFloor.coords.y, currentFloor.coords.z)
        local distance = #(playerCoords - floorCoords)

        if distance > CONFIG.INTERACT_DISTANCE then
            closeNUI()
            return "too_far"
      end

        local targetFloor = elevator.floors[data.floor]
        if not targetFloor then
            return "error"
      end

        if not isFloorAllowedForPlayer(targetFloor) then
            return "error"
      end

        closeNUI()

        if teleportPlayerToFloor(targetFloor) then
            return "ok"
      else
            return "error"
      end
    end)

    cb(success and result or "error")
end)

RegisterNUICallback("nui:elevator:close", function(data, cb)
    closeNUI()
    cb("ok")
end)

RegisterNetEvent("core:player:receiveElevatorData", function(data)
    if not data or type(data) ~= "table" then return end

    ElevatorsData = data
    initializeCaches()

    if next(ElevatorsData) then
        startElevatorThread()
    end
end)

RegisterNetEvent("core:player:addElevator", function(elevatorIndex, elevatorData)
    if not elevatorIndex or not elevatorData then return end

    ElevatorsData[elevatorIndex] = elevatorData
    updateElevatorCacheEntry(elevatorIndex)
    clearAllCaches()

    if not currentThread and next(ElevatorsData) then
        startElevatorThread()
    end
end)

RegisterNetEvent("core:player:removeElevator", function(elevatorIndex)
    if not elevatorIndex then return end

    ElevatorsData[elevatorIndex] = nil
    elevatorCenterCache[elevatorIndex] = nil
    clearAllCaches()

    if selectedElevatorIndex == elevatorIndex then
        closeNUI()
        SendNUIMessage({ action = "nui:elevator:forceClose" })
    end
end)

RegisterNetEvent("core:player:updateElevatorFloors", function(elevatorIndex, floors)
    if not elevatorIndex or not floors then return end

    if ElevatorsData[elevatorIndex] then
        ElevatorsData[elevatorIndex].floors = floors
        updateElevatorCacheEntry(elevatorIndex)
        clearAllCaches()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        closeNUI()
    end
end)

-- console.info("Script client d'ascenseurs initialisé - En attente des données serveur...")

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("core:elevator:requestData")
end)