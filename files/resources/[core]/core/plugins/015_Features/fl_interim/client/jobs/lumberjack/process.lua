local processCircles = {}
local processBlips = {}
local isProcessing = false
local processConfig = {}
local configData = nil
local processSpots = {}
local processMenu
local depositedCount = 0
local producedCount = 0

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
    if not dict then
        return
    end
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local deadline = GetGameTimer() + 5000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
            Wait(0)
        end
    end
end

local function clearProcessSpots()
    for _, circleId in ipairs(processCircles) do
        RemoveInteractionCircle(circleId)
    end
    processCircles = {}

    for _, b in ipairs(processBlips) do
        RemoveBlip(b)
    end
    processBlips = {}
    processSpots = {}
end

local function createProcessSpotsWithConfig(spots)
    processSpots = spots

    for i, spot in ipairs(spots) do
        local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
        SetBlipSprite(blip, 477)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 0.5)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(i == 1 and "~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Bucheron • Scierie" or "Bucheron • Scierie secondaire")
        EndTextCommandSetBlipName(blip)
        table.insert(processBlips, blip)

        local circleColor = (configData and configData.interactionCircle and configData.interactionCircle.processColor)
                or { r = 139, g = 69, b = 19, a = 120 }

        local circleId = CreateInteractionCircle(
                vector3(spot.coords.x, spot.coords.y, spot.coords.z),
                spot.radius or 1.5,
                circleColor,
                "Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la scierie",
                function()
                    if not processMenu then
                        return
                    end
                    processMenu.toggle()
                end,
                { heightRange = 3.0 }
        )

        table.insert(processCircles, circleId)
    end
end

local function createProcessSpots(spots)
    clearProcessSpots()

    if not spots or #spots == 0 then
        return
    end

    if not CreateInteractionCircle then
        SetTimeout(1000, function()
            createProcessSpots(spots)
        end)
        return
    end

    if not configData then
        configData = TriggerServerCallback("interim:lumberjack:getConfig")
    end

    createProcessSpotsWithConfig(spots)
end

RegisterNetEvent("interim:lumberjack:setProcessSpots", function(spots)
    createProcessSpots(spots)
end)

RegisterNetEvent("interim:lumberjack:clearProcessSpots", function()
    clearProcessSpots()
end)

RegisterNetEvent("interim:lumberjack:processStart", function()


    local ped = PlayerPedId()
    isProcessing = true

    local dict = processConfig.animDict or "amb@world_human_hammering@male@base"
    local name = processConfig.animName or "base"
    local flag = processConfig.animFlag or 49
    local delay = tonumber(processConfig.processDelay or 5000) or 5000

    loadAnimDict(dict)
    TaskPlayAnim(ped, dict, name, 3.0, -1.0, delay, flag, 0.0, false, false, false)
    notify("JAUNE", "Transformation en cours...")

    SetTimeout(delay, function()
        ClearPedTasks(ped)
        isProcessing = false
    end)
end)

local function refreshProcessState()
    local st = TriggerServerCallback("interim:lumberjack:getProcessState")
    if st and type(st) == "table" then
        depositedCount = tonumber(st.deposited or 0) or 0
        producedCount = tonumber(st.produced or 0) or 0
    end
end

RegisterNetEvent("interim:lumberjack:processStateUpdated", function(state)
    depositedCount = tonumber(state.deposited or 0) or 0
    producedCount = tonumber(state.produced or 0) or 0
    if processMenu then
        processMenu.refresh()
    end
end)

local function setProcessCirclesEnabled(state)
    for _, circleId in ipairs(processCircles) do
        SetInteractionCircleEnabled(circleId, state)
    end
end

local function ensureProcessMenu()
    if processMenu then
        return processMenu
    end

    local VUI = exports["VUI"]
    processMenu = VUI:CreateMenu("Scierie du bûcheron", GetVUIBanner("lumberjack"), false)

    processMenu.OnOpen(function()
        setProcessCirclesEnabled(false)
        refreshProcessState()
        processMenu.ClearItems()
        processMenu.Title("Scierie", "", "", "", nil)
        processMenu.Separator(nil)

        processMenu.Button(("Déposer une bûche (%d/5)"):format(depositedCount), nil, nil, "chevron", false, function()
            TriggerServerEvent("interim:lumberjack:depositWood")
            Wait(500)
            refreshProcessState()
        end)

        processMenu.Button(("Démarrer le traitement (%d bûches)"):format(depositedCount), nil, nil, "chevron", false, function()
            if depositedCount <= 0 then
                notify("JAUNE", "Aucune bûche déposée")
                return
            end

            processMenu.close()

            CreateThread(function()
                isProcessing = true

                local ped = PlayerPedId()

                local animDict = "random@domestic"
                local animName = "pickup_low"

                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do Wait(10) end

                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)

                Wait(1200)

                ClearPedTasks(ped)
                RemoveAnimDict(animDict)

                isProcessing = false
            end)

            TriggerServerEvent("interim:lumberjack:startProcessing")

            if VFW and VFW.Nui and VFW.Nui.ProgressBar then
                VFW.Nui.ProgressBar("Traitement du bois", 5000)
            end
        end)

        processMenu.Button(("Récupérer les planches (%d)"):format(producedCount), nil, nil, "check", false, function()
            if producedCount <= 0 then
                notify("JAUNE", "Aucune planche disponible")
                return
            end
            TriggerServerEvent("interim:lumberjack:collectPlanks")
            Wait(500)
            refreshProcessState()
        end)
    end)

    processMenu.OnClose(function()
        processMenu.ClearItems()
        setProcessCirclesEnabled(true)
    end)

    return processMenu
end

CreateThread(function()
    while true do
        local playerPos = GetEntityCoords(PlayerPedId())
        local hasNearbySpot = false
        local isNearSpot = false

        for _, spot in ipairs(processSpots) do
            local distance = #(playerPos - spot.coords)
            local radius = spot.radius or 1.5

            local distanceXY = #(vector2(playerPos.x, playerPos.y) - vector2(spot.coords.x, spot.coords.y))
            local distanceZ = math.abs(playerPos.z - spot.coords.z)

            if distance < 50.0 then
                hasNearbySpot = true
                DrawMarker(
                        23,
                        spot.coords.x, spot.coords.y, spot.coords.z - 0.98,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.4, 0.4, 0.4,
                        139, 69, 19, 80,
                        false, true, 2, false, nil, nil, false
                )

                if distanceXY <= radius and distanceZ <= 3.0 then
                    isNearSpot = true
                end
            end
        end

        ensureProcessMenu()
        Wait(hasNearbySpot and 0 or 500)
    end
end)
