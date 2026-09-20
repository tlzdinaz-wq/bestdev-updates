---@meta _
---@diagnostic disable: duplicate-doc-field

-- Whitening points data from server
local whiteningPoints = {}
local whiteningSettings = {}

-- Blips per point
local pointBlips = {} -- { [pointId] = blipHandle }

-- Active session state
local activeSession = nil -- { pointId, timerSeconds, cleanAmount, fee, feePercent, startTime, pointPos }

-- FloatingInteraction state
local floatingShown = false
local floatingPointId = nil

-- Interaction
local KEY_INTERACT = 38 -- E
local INTERACT_RADIUS = 1.5
local BLIP_DISPLAY_RADIUS = 500.0
local MAX_DISTANCE = 500.0

-- FloatingInteraction helpers
local function ShowFloating(pointId, worldPos, isSession, timeLeft)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.5)
    if not onScreen then
        if floatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            floatingShown = false
            floatingPointId = nil
        end
        return
    end

    local data = {
        id = "whitening_" .. tostring(pointId),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {}
    }

    if isSession then
        if timeLeft and timeLeft > 0 then
            local minutes = math.floor(timeLeft / 60)
            local seconds = math.floor(timeLeft % 60)
            data.subtitle = ("En cours - %d:%02d"):format(minutes, seconds)
        else
            data.subtitle = "Prêt"
            data.buttons = {
                { label = "Récupérer l'argent", key = "E" }
            }
        end
    else
        data.buttons = {
            { label = "Blanchir de l'argent", key = "E" }
        }
    end

    if floatingShown and floatingPointId == pointId then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        floatingShown = true
        floatingPointId = pointId
    end
end

local function HideFloating()
    if floatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        floatingShown = false
        floatingPointId = nil
    end
end

-- Create blip for a point (only restricted points get a blip)
local function CreatePointBlip(pointId, point)
    -- No blip for unrestricted points
    if not point.groupRestriction or point.groupRestriction == "" then return end

    if pointBlips[pointId] and DoesBlipExist(pointBlips[pointId]) then return end

    local blip = AddBlipForCoord(point.pos.x, point.pos.y, point.pos.z)
    SetBlipSprite(blip, 431)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Point de traitement · " .. point.groupRestriction)
    EndTextCommandSetBlipName(blip)
    pointBlips[pointId] = blip
end

local function RemovePointBlip(pointId)
    if pointBlips[pointId] and DoesBlipExist(pointBlips[pointId]) then
        RemoveBlip(pointBlips[pointId])
    end
    pointBlips[pointId] = nil
end

local function RemoveAllBlips()
    for pointId, _ in pairs(pointBlips) do
        RemovePointBlip(pointId)
    end
end

-- Check if player can access a point based on group restriction
local function CanAccessPoint(point)
    if not point.groupRestriction or point.groupRestriction == "" then
        return true
    end
    local factionName = VFW.PlayerData.faction and VFW.PlayerData.faction.name or ""
    return factionName == point.groupRestriction
end

-- Interact with point: start session or check status
local function InteractWithPoint(pointId, point)
    -- If session active at this point, check status
    if activeSession and activeSession.pointId == pointId then
        local result = TriggerServerCallback("core:whitening:checkSession")
        if result and result.active then
            if result.ready then
                TriggerServerEvent("core:whitening:collect", pointId)
            else
                local minutes = math.floor(result.timeLeft / 60)
                local seconds = result.timeLeft % 60
                VFW.ShowNotification({ type = "ILLEGAL", message = ("Pas encore prêt. Encore %d:%02d."):format(minutes, seconds) })
            end
        end
        return
    end

    -- If session active at another point
    if activeSession then
        VFW.ShowNotification({ type = "ILLEGAL", message = "Vous avez déjà un blanchiment en cours ailleurs." })
        return
    end

    -- Check cooldown (pass pointId for faction vs player logic)
    local cooldownResult = TriggerServerCallback("core:whitening:checkCooldown", pointId)
    if cooldownResult and cooldownResult.hasError then
        VFW.ShowNotification({ type = "ILLEGAL", message = cooldownResult.message })
        return
    end
    if cooldownResult and cooldownResult.onCooldown then
        VFW.ShowNotification({ type = "ILLEGAL", message = cooldownResult.message })
        return
    end

    -- Check access
    local canAccess, reason = TriggerServerCallback("core:whitening:canAccessPoint", pointId)
    if not canAccess then
        VFW.ShowNotification({ type = "ILLEGAL", message = reason or "Accès refusé." })
        return
    end

    -- Open input for amount (point overrides > global settings)
    local overrides = point.overrides or {}
    local maxDirtyMoney = tonumber(overrides.maxDirtyMoney) or tonumber(whiteningSettings.maxDirtyMoney) or 50000
    local feePercent = tonumber(overrides.feePercent) or tonumber(whiteningSettings.feePercent) or 20

    -- Use remaining limit from server (faction or player)
    if cooldownResult and cooldownResult.factionRemaining then
        maxDirtyMoney = cooldownResult.factionRemaining
    elseif cooldownResult and cooldownResult.playerRemaining then
        maxDirtyMoney = cooldownResult.playerRemaining
    end

    if maxDirtyMoney <= 0 then
        VFW.ShowNotification({ type = "ILLEGAL", message = "Vous avez atteint votre limite de blanchiment." })
        return
    end

    CreateThread(function()
        Wait(200)
        VFW.Nui.Focus(true)
        local input = VFW.Nui.KeyboardInput(true, ("Montant à blanchir (Max: %s - Frais: %d%%)"):format(VFW.Math.FormatMoney(maxDirtyMoney), feePercent))
        VFW.Nui.Focus(false)

        if input == nil then return end
        local amount = tonumber(input)
        if not amount or amount <= 0 then
            VFW.ShowNotification({ type = "ILLEGAL", message = "Ce montant n'est pas valide." })
            return
        end
        if amount > maxDirtyMoney then
            VFW.ShowNotification({ type = "ILLEGAL", message = ("Maximum autorisé : %s."):format(VFW.Math.FormatMoney(maxDirtyMoney)) })
            return
        end

        local hasEnough = TriggerServerCallback("vfw:illegal:whitening:hasEnoughDirtyMoney", amount)
        if not hasEnough then
            VFW.ShowNotification({ type = "ILLEGAL", message = "Vous n'avez pas assez d'argent sale." })
            return
        end

        TriggerServerEvent("core:whitening:startSession", pointId, amount)
    end)
end

-- Session started event from server
RegisterNetEvent('core:whitening:sessionStarted')
AddEventHandler('core:whitening:sessionStarted', function(data)
    local point = whiteningPoints[data.pointId]
    if not point then return end

    activeSession = {
        pointId = data.pointId,
        timerSeconds = data.timerSeconds,
        cleanAmount = data.cleanAmount,
        fee = data.fee,
        feePercent = data.feePercent,
        startTime = GetGameTimer(),
        pointPos = vector3(point.pos.x, point.pos.y, point.pos.z)
    }

    local minutes = math.floor(data.timerSeconds / 60)
    VFW.ShowNotification({ type = "ILLEGAL", message = ("Je commence à blanchir, reviens dans %d minutes et ça sera prêt. Quitte pas les lieux."):format(minutes) })
end)

-- Session complete event
RegisterNetEvent('core:whitening:sessionComplete')
AddEventHandler('core:whitening:sessionComplete', function()
    if activeSession then
        VFW.ShowNotification({ type = "ILLEGAL", message = ("Vous avez récupéré %s d'argent propre."):format(VFW.Math.FormatMoney(activeSession.cleanAmount)) })
        activeSession = nil
    end
end)

-- Main loop: blip management + distance check
CreateThread(function()
    while true do
        local wait = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        for pointId, point in pairs(whiteningPoints) do
            if point.active and CanAccessPoint(point) then
                local pointPos = vector3(point.pos.x, point.pos.y, point.pos.z)
                local dist = #(playerCoords - pointPos)

                if dist < BLIP_DISPLAY_RADIUS then
                    CreatePointBlip(pointId, point)
                else
                    RemovePointBlip(pointId)
                end
            else
                RemovePointBlip(pointId)
            end
        end

        -- Distance check for active session
        if activeSession then
            local dist = #(playerCoords - activeSession.pointPos)

            if dist > MAX_DISTANCE then
                VFW.ShowNotification({ type = "ILLEGAL", message = "Vous vous êtes trop éloigné ! L'argent est perdu." })
                TriggerServerEvent("core:whitening:cancelSession")
                activeSession = nil
            end
        end

        Wait(wait)
    end
end)

-- Interaction loop (floatingInteraction + E press)
CreateThread(function()
    while true do
        local wait = 1000

        if IsNuiFocused() then
            HideFloating()
        else
            local playerCoords = GetEntityCoords(PlayerPedId())
            local closestPoint = nil
            local closestDist = 999.0
            local closestId = nil

            for pointId, point in pairs(whiteningPoints) do
                if point.active and CanAccessPoint(point) then
                    local pointPos = vector3(point.pos.x, point.pos.y, point.pos.z)
                    local dist = #(playerCoords - pointPos)

                    if dist < closestDist then
                        closestDist = dist
                        closestPoint = point
                        closestId = pointId
                    end
                end
            end

            if closestId and closestDist <= INTERACT_RADIUS then
                wait = 0
                local pos = closestPoint.pos
                local isSession = activeSession and activeSession.pointId == closestId
                local timeLeft = nil

                if isSession then
                    local elapsed = (GetGameTimer() - activeSession.startTime) / 1000
                    timeLeft = math.max(0, activeSession.timerSeconds - elapsed)
                end

                ShowFloating(closestId, vector3(pos.x, pos.y, pos.z), isSession, timeLeft)

                if IsControlJustPressed(0, KEY_INTERACT) then
                    HideFloating()
                    InteractWithPoint(closestId, closestPoint)
                end
            else
                HideFloating()
            end
        end

        Wait(wait)
    end
end)

-- Distance warning loop (when session active, warn at 400m)
CreateThread(function()
    while true do
        local wait = 2000

        if activeSession then
            wait = 5000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - activeSession.pointPos)

            if dist > 400.0 and dist <= MAX_DISTANCE then
                VFW.ShowNotification({ type = "ILLEGAL", message = "Attention ! Ne vous éloignez pas trop du point de traitement." })
            end
        end

        Wait(wait)
    end
end)

-- Load points from server
local function LoadWhiteningData()
    whiteningPoints = TriggerServerCallback("core:whitening:getPoints") or {}
    whiteningSettings = TriggerServerCallback("core:whitening:getSettings") or {}
end

-- Server sync events
RegisterNetEvent('core:whitening:pointsUpdated')
AddEventHandler('core:whitening:pointsUpdated', function(points)
    RemoveAllBlips()
    whiteningPoints = points or {}
end)

RegisterNetEvent('core:whitening:settingsUpdated')
AddEventHandler('core:whitening:settingsUpdated', function(settings)
    whiteningSettings = settings or {}
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        HideFloating()
        RemoveAllBlips()
        if activeSession then
            TriggerServerEvent("core:whitening:cancelSession")
            activeSession = nil
        end
    end
end)

-- Load on start
CreateThread(function()
    Wait(2000)
    LoadWhiteningData()
end)
