local woodCircles = {}
local woodBlips = {}
local isChopping = false
local configData = nil
local woodSpots = {}

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local deadline = GetGameTimer() + 5000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
            Wait(0)
        end
    end
end

local function setWoodCirclesEnabled(enabled)
    for _, circleId in ipairs(woodCircles) do
        if SetInteractionCircleEnabled then
            SetInteractionCircleEnabled(circleId, enabled)
        end
    end
end

local function createWoodCirclesWithConfig(spots)
    woodSpots = spots



    for i, spot in ipairs(spots) do
        local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
        SetBlipSprite(blip, 237)
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 2)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(i == 1 and "~b~[Intérim]~w~ Bucheron • Récolte" or "Bucheron • Récolte secondaire")
        EndTextCommandSetBlipName(blip)
        table.insert(woodBlips, blip)

        local circleColor = (configData and configData.interactionCircle and configData.interactionCircle.color)
                          or {r = 0, g = 0, b = 255, a = 255}


        local circleId = CreateInteractionCircle(
            vector3(spot.coords.x, spot.coords.y, spot.coords.z + 0.05),
            spot.radius or 1.5,
            circleColor,
            "Appuyez sur ~INPUT_CONTEXT~ pour récolter du bois",
            function()
                if isChopping then
                    return
                end

                CreateThread(function()
                    local deadline = GetGameTimer() + 7000
                    while GetGameTimer() < deadline and not isChopping do
                        DisableControlAction(0, 38, true)
                        Wait(0)
                    end
                end)

                TriggerServerEvent("interim:lumberjack:requestChop", i)
            end,
            { heightRange = 5.0 }
        )



        table.insert(woodCircles, circleId)
    end
end

local function removeWoodCircles()
    for _, circleId in pairs(woodCircles) do
        RemoveInteractionCircle(circleId)
    end
    woodCircles = {}

    for _, blip in pairs(woodBlips) do
        RemoveBlip(blip)
    end
    woodBlips = {}
    woodSpots = {}
end

local function createWoodCircles(spots)
    removeWoodCircles()

    if not spots or #spots == 0 then
        return
    end

    if not CreateInteractionCircle then
        SetTimeout(1000, function()
            createWoodCircles(spots)
        end)
        return
    end

    if not configData then
        configData = TriggerServerCallback("interim:lumberjack:getConfig")
    end

    createWoodCirclesWithConfig(spots)
end

RegisterNetEvent("interim:lumberjack:setWoodSpots", function(spots)
    createWoodCircles(spots)
end)

RegisterNetEvent("interim:lumberjack:clearWoodSpots", function()
    removeWoodCircles()
end)

RegisterNetEvent("interim:lumberjack:startChopAnim", function(payload)
    if isChopping then
        return
    end

    isChopping = true
    setWoodCirclesEnabled(false)

    local ped = PlayerPedId()
    local dict = "melee@large_wpn@streamed_core"
    local name = "ground_attack_on_spot"
    local flag = payload.flag or 49
    local delay = payload.delay or 5000

    loadAnimDict(dict)

    local axe
    local pPos = GetEntityCoords(ped)
    local axeModel = GetHashKey("prop_tool_fireaxe")
    RequestModel(axeModel)
    local dl = GetGameTimer() + 3000
    while not HasModelLoaded(axeModel) and GetGameTimer() < dl do
        Wait(0)
    end
    axe = VFW.OneSync.CreateObject(axeModel, pPos)
    if axe and axe ~= 0 then
        AttachEntityToEntity(
            axe,
            ped,
            GetPedBoneIndex(ped, 57005),
            0.0160, -0.3140, -0.0860,
            -97.1455, 165.0749, 13.9114,
            true, true, false, true, 1, true
        )
    end

    notify("JAUNE", "Tu commences à récolter du bois...")

    CreateThread(function()
        while isChopping do
            DisableControlAction(0, 38, true)
            Wait(0)
        end
    end)

    local endTime = GetGameTimer() + delay
    CreateThread(function()
        while GetGameTimer() < endTime do
            TaskPlayAnim(ped, dict, name, 8.0, -8.0, 1000, flag, 0.0, false, false, false)
            Wait(950)
        end
        ClearPedTasks(ped)
        if axe and DoesEntityExist(axe) then
            DetachEntity(axe, true, true)
            DeleteObject(axe)
        end
        isChopping = false
        setWoodCirclesEnabled(true)
    end)
end)

RegisterNetEvent("interim:lumberjack:notify", function(t, msg)
    notify(t, msg)
end)

CreateThread(function()
    while true do
        local playerPos = GetEntityCoords(PlayerPedId())
        local hasNearbySpot = false

        for _, spot in ipairs(woodSpots) do
            local distance = #(playerPos - spot.coords)

            if distance < 50.0 then
                hasNearbySpot = true
                DrawMarker(
                    23,
                    spot.coords.x, spot.coords.y, spot.coords.z + 0.01,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.4, 0.4, 0.4,
                    255, 178, 102, 80,
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        Wait(hasNearbySpot and 0 or 500)
    end
end)

