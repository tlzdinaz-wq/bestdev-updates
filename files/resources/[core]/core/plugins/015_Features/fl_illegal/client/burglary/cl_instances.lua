---@meta _
---@diagnostic disable: duplicate-doc-field

local isInInstance = false
local currentHouseId = nil
local currentInterior = nil
local instanceTimer = nil
local lootPoints = {}
local lootedPoints = {}
local entryTimer = nil
local robberyTimer = nil
local lootBlips = {}
local instanceStartTime = 0
local instanceDuration = 0
local lootDisabled = false
local isLooting = false

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

local function StartLootInteraction(pointId)
    if isLooting then return end
    isLooting = true

    local playerPed = PlayerPedId()

    -- Animation de fouille accroupie
    RequestAnimDict("amb@prop_human_bum_bin@idle_b")
    while not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b") do
        Wait(100)
    end
    TaskPlayAnim(playerPed, "amb@prop_human_bum_bin@idle_b", "idle_d", 8.0, 8.0, -1, 1, 0, false, false, false)

    local lootTime = 3000

    CreateThread(function()
        local endAt = GetGameTimer() + lootTime
        local cancelled = false

        while GetGameTimer() < endAt do
            local timeLeft = math.ceil((endAt - GetGameTimer()) / 1000)
            ShowHelp(string.format("~y~Fouille en cours~w~ - %ds", timeLeft))

            local playerCoords = GetEntityCoords(PlayerPedId())
            local point = nil
            for _, p in ipairs(lootPoints) do
                if p.id == pointId then
                    point = p
                    break
                end
            end

            if point then
                local dist = #(playerCoords - vector3(point.pos.x, point.pos.y, point.pos.z))
                if dist > 2.0 then
                    ClearPedTasksImmediately(playerPed)
                    VFW.ShowNotification({
                        type = 'ILLEGAL',
                        message = "Vous vous êtes trop éloigné !"
                    })
                    cancelled = true
                    break
                end
            end

            Wait(0)
        end

        ClearPedTasksImmediately(playerPed)
        if not cancelled then
            TriggerServerEvent("core:burglary:lootPoint", currentHouseId, pointId)
        end
        isLooting = false
    end)
end

-- Timer local calculé côté client
CreateThread(function()
    while true do
        local wait = 1000

        if isInInstance and instanceStartTime > 0 then
            wait = 1000
        end

        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        local wait = 1000

        if isInInstance and not lootDisabled and #lootPoints > 0 then
            wait = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, point in ipairs(lootPoints) do
                if not lootedPoints[point.id] then
                    local pointPos = vector3(point.pos.x, point.pos.y, point.pos.z)
                    local dist = #(playerCoords - pointPos)

                    if dist < 10.0 then
                        DrawMarker(1,
                            point.pos.x, point.pos.y, point.pos.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.6, 0.6, 0.1,
                            255, 255, 0, 100,
                            false, true, 2, false, nil, nil, false
                        )
                    end

                    if dist < 1.5 and not isLooting then
                        ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour fouiller")

                        if VFW.Interact.JustPressed(0, 38) then
                            StartLootInteraction(point.id)
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        local wait = 1000

        if isInInstance and currentInterior then
            wait = 0
            local playerCoords = GetEntityCoords(PlayerPedId())

            -- Point de sortie = point de spawn (entrée de l'intérieur)
            local exitPos = vector3(currentInterior.spawnPos.x, currentInterior.spawnPos.y, currentInterior.spawnPos.z)

            local dist = #(playerCoords - exitPos)

            if dist < 10.0 then
                DrawMarker(1, -- Type: Cylinder
                    exitPos.x, exitPos.y, exitPos.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.6, 0.6, 0.1,
                    255, 0, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
            end

            if dist < 1.5 then
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour sortir de la maison")

                if VFW.Interact.JustPressed(0, 38) then -- E key
                    TriggerServerEvent("core:burglary:leaveInstance")
                end
            end
        end

        Wait(wait)
    end
end)

-- Charge l'IPL et attend qu'il soit actif AVANT de téléporter le joueur,
-- sinon SetEntityCoords se fait dans un monde vide → position part en vrille
-- et les autres joueurs ne nous voient pas pendant plusieurs secondes.
local function EnsureIPLLoadedSync(iplName)
    if not iplName or iplName == "" or iplName == "_default_" then return end
    local iplManager = exports.core:GetIPLManager()
    if not iplManager then return end
    if iplManager.IsIPLLoaded(iplName) then return end
    iplManager.LoadIPL(iplName)
end

RegisterNetEvent("core:burglary:enterInstance")
AddEventHandler("core:burglary:enterInstance", function(houseId, interiorData, timeLeftInSeconds)
    -- IMPORTANT: setter l'état AVANT tout Wait, sinon updateLootPoints (envoyé
    -- juste après enterInstance par le serveur) arrive pendant qu'on yield et
    -- voit currentHouseId == nil → les loot points sont jetés.
    local timerExpired = not timeLeftInSeconds or timeLeftInSeconds <= 0

    isInInstance = true
    currentHouseId = houseId
    currentInterior = interiorData
    lootDisabled = timerExpired

    lootPoints = {}
    lootedPoints = {}

    for _, blip in pairs(lootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    lootBlips = {}

    instanceStartTime = GetGameTimer()
    instanceDuration = (timeLeftInSeconds and timeLeftInSeconds > 0) and timeLeftInSeconds or 0

    -- Fade out pour cacher le switch de bucket / téléport
    DoScreenFadeOut(500)
    local fadeDeadline = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end

    local playerPed = PlayerPedId()

    -- Freeze le ped pour éviter qu'il fall-through avant que l'IPL soit chargé
    FreezeEntityPosition(playerPed, true)

    -- Charger l'IPL de manière synchrone AVANT le téléport
    EnsureIPLLoadedSync(interiorData.iplName)

    local spawnPos = interiorData.spawnPos
    SetEntityCoords(playerPed, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
    SetEntityHeading(playerPed, spawnPos.h or 0.0)

    -- Laisser le temps à la nouvelle position de propager au serveur puis aux autres
    -- clients du bucket pour que tout le monde se voie correctement
    Wait(800)

    FreezeEntityPosition(playerPed, false)

    DoScreenFadeIn(500)

    if timerExpired then
        VFW.ShowNotification({
            type = 'ROUGE',
            message = "Le cambriolage est terminé, dépêchez-vous de sortir !"
        })
    else
        local mins = math.floor(instanceDuration / 60)
        VFW.ShowNotification({
            type = 'ROUGE',
            message = ("Vous êtes entré dans la maison ! Vous avez %d minutes pour fouiller."):format(mins)
        })
    end
end)

RegisterNetEvent("core:burglary:enterPostRobbery")
AddEventHandler("core:burglary:enterPostRobbery", function(houseId, interiorData)
    isInInstance = true
    currentHouseId = houseId
    currentInterior = interiorData

    lootPoints = {}
    lootedPoints = {}
    instanceStartTime = 0
    instanceDuration = 0

    DoScreenFadeOut(500)
    local fadeDeadline = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end

    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)

    EnsureIPLLoadedSync(interiorData.iplName)

    local spawnPos = interiorData.spawnPos
    SetEntityCoords(playerPed, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
    SetEntityHeading(playerPed, spawnPos.h or 0.0)

    Wait(800)

    FreezeEntityPosition(playerPed, false)

    DoScreenFadeIn(500)

    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Cette maison semble avoir été cambriolée..."
    })
end)

RegisterNetEvent("core:burglary:exitInstance")
AddEventHandler("core:burglary:exitInstance", function()

    isInInstance = false
    currentHouseId = nil
    currentInterior = nil
    lootPoints = {}
    lootedPoints = {}
    lootDisabled = false

    -- Reset timer
    instanceStartTime = 0
    instanceDuration = 0

    -- Supprimer tous les blips
    for _, blip in pairs(lootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    lootBlips = {}

    DoScreenFadeOut(500)
    Wait(500)
    DoScreenFadeIn(500)
end)

local function CreateLootBlips()
    -- Supprimer les anciens blips
    for _, blip in pairs(lootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    lootBlips = {}

    -- Créer les blips pour chaque point de loot
    for _, point in ipairs(lootPoints) do
        if not lootedPoints[point.id] then
            local blip = AddBlipForCoord(point.pos.x, point.pos.y, point.pos.z)
            SetBlipSprite(blip, 1) -- Point blanc
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 46) -- Jaune
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Point de fouille")
            EndTextCommandSetBlipName(blip)

            lootBlips[point.id] = blip
        end
    end
end

RegisterNetEvent("core:burglary:updateLootPoints")
AddEventHandler("core:burglary:updateLootPoints", function(houseId, points)
    if currentHouseId == houseId then
        lootPoints = points
        if lootDisabled then
            for _, blip in pairs(lootBlips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            lootBlips = {}
        else
            CreateLootBlips()
        end
    end
end)

RegisterNetEvent("core:burglary:pointLooted")
AddEventHandler("core:burglary:pointLooted", function(houseId, pointId)
    if currentHouseId == houseId then
        lootedPoints[pointId] = true

        -- Supprimer le blip du point looté
        if lootBlips[pointId] and DoesBlipExist(lootBlips[pointId]) then
            RemoveBlip(lootBlips[pointId])
            lootBlips[pointId] = nil
        end
    end
end)

RegisterNetEvent("core:burglary:robberyTimeout")
AddEventHandler("core:burglary:robberyTimeout", function()
    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Temps écoulé ! Vous avez été expulsé de la maison."
    })
end)

-- Timer expiré mais joueurs encore dedans - ils peuvent encore sortir
RegisterNetEvent("core:burglary:timerExpired")
AddEventHandler("core:burglary:timerExpired", function()
    lootDisabled = true

    for _, blip in pairs(lootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    lootBlips = {}

    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Temps écoulé ! Plus de fouille possible, dirigez-vous vers la sortie."
    })
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isInInstance then
            TriggerServerEvent("core:burglary:leaveInstance")
        end
    end
end)

exports('IsInBurglaryInstance', function()
    return isInInstance
end)

exports('GetCurrentHouseId', function()
    return currentHouseId
end)