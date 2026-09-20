
local mining = false
local mineSpots = {}
local currentRockSpotId = nil
local currentRock = nil
local currentBlip = nil
local configData = nil



local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end

local function spawnRock(spot)
    local model = GetHashKey("prop_rock_3_c")
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        return nil
    end

    local rock = CreateObject(model, spot.x, spot.y, spot.z - 1.0, false, false, false)
    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(rock, true)
    SetEntityAsMissionEntity(rock, true, true)

    return rock
end

local function getRandomSpotExcluding(excludeId)
    local availableSpots = {}
    for spotId, spot in pairs(mineSpots) do
        if spotId ~= excludeId then
            table.insert(availableSpots, {id = spotId, data = spot})
        end
    end

    if #availableSpots == 0 then
        for spotId, spot in pairs(mineSpots) do
            table.insert(availableSpots, {id = spotId, data = spot})
        end
    end

    if #availableSpots > 0 then
        local randomIndex = math.random(1, #availableSpots)
        return availableSpots[randomIndex].id, availableSpots[randomIndex].data
    end

    return nil, nil
end

local function spawnRockAtRandomSpot(excludeSpotId)
    if currentRock and DoesEntityExist(currentRock) then
        DeleteEntity(currentRock)
        currentRock = nil
    end

    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end

    local newSpotId, newSpot = getRandomSpotExcluding(excludeSpotId)
    if newSpotId and newSpot then
        currentRock = spawnRock(newSpot)
        currentRockSpotId = newSpotId

        currentBlip = AddBlipForCoord(newSpot.x, newSpot.y, newSpot.z)
        SetBlipSprite(currentBlip, 618)
        SetBlipColour(currentBlip, 5)
        SetBlipScale(currentBlip, 0.5)
        SetBlipDisplay(currentBlip, 4)
        SetBlipAsShortRange(currentBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Mineur")
        EndTextCommandSetBlipName(currentBlip)
    end
end

local function removeAllMineSpots()
    if currentRock and DoesEntityExist(currentRock) then
        DeleteEntity(currentRock)
    end
    if currentBlip then
        RemoveBlip(currentBlip)
    end
    currentRock = nil
    currentBlip = nil
    currentRockSpotId = nil
    mineSpots = {}
end

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local t = GetGameTimer() + 5000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < t do
            Wait(0)
        end
    end
end

RegisterNetEvent("interim:miner:setMineSpots", function(spots)
    removeAllMineSpots()
    if spots and type(spots) == "table" then
        for spotId, spot in pairs(spots) do
            mineSpots[spotId] = spot
        end

        if not configData then
            configData = TriggerServerCallback("interim:miner:getConfig")
        end

        spawnRockAtRandomSpot(nil)
    end
end)

RegisterNetEvent("interim:miner:clearMineSpots", function()
    removeAllMineSpots()
end)

RegisterNetEvent("interim:miner:setSpot", function(spot)
    removeAllMineSpots()
    if spot then
        mineSpots["current"] = spot

        if not configData then
            configData = TriggerServerCallback("interim:miner:getConfig")
        end

        spawnRockAtRandomSpot(nil)
    end
end)

local function spawnPickaxe(ped)
    local model = GetHashKey("prop_tool_pickaxe")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local obj = VFW.OneSync.CreateObject(model, GetEntityCoords(ped))
    SetModelAsNoLongerNeeded(model)
    DisableCamCollisionForObject(obj)
    DisableCamCollisionForEntity(obj)

    AttachEntityToEntity(
            obj, ped, GetPedBoneIndex(ped, 57005),
            0.09, -0.25, -0.10,
            252.0, 180.0, 0.0,
            false, true, true, true, 0, true
    )

    return obj
end

RegisterNetEvent("interim:miner:miningStart", function(payload)
    if not payload then
        return
    end


    local ped = PlayerPedId()
    mining = true

    CreateThread(function()
        while mining do
            DisableControlAction(0, 38, true)
            Wait(0)
        end
    end)

    local pickaxe = spawnPickaxe(ped)
    loadAnimDict(payload.dict or "amb@world_human_hammering@male@base")

    TaskPlayAnim(
            ped,
            payload.dict or "amb@world_human_hammering@male@base",
            payload.name or "base",
            3.0, -1.0,
            payload.delay or 5000,
            payload.flag or 49,
            0.0, false, false, false
    )

    notify("JAUNE", "Tu commences à miner...")

    SetTimeout(payload.delay or 5000, function()
        if DoesEntityExist(pickaxe) then
            DeleteEntity(pickaxe)
        end
    end)
end)

RegisterNetEvent("interim:miner:miningSuccess", function()
    ClearPedTasks(PlayerPedId())
    mining = false


    local oldSpotId = currentRockSpotId
    spawnRockAtRandomSpot(oldSpotId)
end)

RegisterNetEvent("interim:miner:miningCancel", function(reason)
    ClearPedTasks(PlayerPedId())
    mining = false
    notify("ROUGE", reason or "Minage annulé.")
end)

RegisterNetEvent("interim:miner:notify", function(t, msg)
    notify(t, msg)
end)

--RegisterCommand('testminespot', function()
--    local ped = PlayerPedId()
--    local coords = GetEntityCoords(ped)
--
--    local testSpots = {
--        spot1 = {
--            x = coords.x + 2.0,
--            y = coords.y + 2.0,
--            z = coords.z,
--            radius = 3.0
--        },
--        spot2 = {
--            x = coords.x - 2.0,
--            y = coords.y + 2.0,
--            z = coords.z,
--            radius = 3.0
--        },
--        spot3 = {
--            x = coords.x + 2.0,
--            y = coords.y - 2.0,
--            z = coords.z,
--            radius = 3.0
--        }
--    }
--
--    TriggerEvent("interim:miner:setMineSpots", testSpots)
--end, false)

CreateThread(function()
    while true do
        local playerPos = GetEntityCoords(PlayerPedId())
        local isNearRock = false

        if currentRock and DoesEntityExist(currentRock) then
            local rockPos = GetEntityCoords(currentRock)
            local distance = #(playerPos - rockPos)
            local radius = (currentRockSpotId and mineSpots[currentRockSpotId] and mineSpots[currentRockSpotId].radius) or 2.0

            if distance <= radius then
                isNearRock = true
            end
        end

        if isNearRock then
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour miner")

            if VFW.Interact.JustPressed(0, 38) then
                if mining then
                    notify("JAUNE", "Tu es déjà en train de miner.")
                else
                    CreateThread(function()
                        local deadline = GetGameTimer() + 7000
                        while GetGameTimer() < deadline and not mining do
                            DisableControlAction(0, 38, true)
                            Wait(0)
                        end
                    end)
                    TriggerServerEvent("interim:miner:requestMine", currentRockSpotId)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
