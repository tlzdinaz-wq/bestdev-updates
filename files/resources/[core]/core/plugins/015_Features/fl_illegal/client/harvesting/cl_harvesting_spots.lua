local harvestingSpots = {}
local spotBlips = {}
local currentSpot = nil
local isNearSpot = false
local spotCircles = {}
local spotCircleColors = {}
local spotCoordsList = {}
local keyMustBeReleased = false

local function CanAccessSpot(spot)
    if not spot.faction_restriction or spot.faction_restriction == "" then
        return true
    end

    local playerFaction = VFW.PlayerData.faction
    if not playerFaction or playerFaction.name ~= spot.faction_restriction then
        return false
    end

    if spot.faction_grade_min and spot.faction_grade_min > 0 then
        local playerGrade = playerFaction.grade or 0
        if playerGrade < spot.faction_grade_min then
            return false
        end
    end

    return true
end

function CalculateCirclePosition(coords, offset)
    offset = offset or 0
    return vector3(coords.x, coords.y, coords.z + offset)
end

function LoadHarvestingSpots()
    local spotsConfig = TriggerServerCallback("illegalHarvesting:getSpots")
    harvestingSpots = spotsConfig

    if not spotsConfig or TableLength(spotsConfig) == 0 then
        return
    end

    for spotId, spot in pairs(harvestingSpots) do
        if type(spot.coords) == "table" then
            spotCoordsList[spotId] = spot.coords
            spotCircles[spotId] = {}
            for i, coord in ipairs(spot.coords) do
                spotCircles[spotId][i] = CalculateCirclePosition(coord, 0)
            end
        else
            spotCoordsList[spotId] = {spot.coords}
            spotCircles[spotId] = {CalculateCirclePosition(spot.coords, 0)}
        end

        if spot.interaction and spot.interaction.circleColor then
            spotCircleColors[spotId] = spot.interaction.circleColor
        else
            spotCircleColors[spotId] = {139, 0, 0, 150}
        end
    end

    SpawnAllSpots()
end

function TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function SpawnAllSpots()
    for spotId, spot in pairs(harvestingSpots) do
        CreateSpotBlip(spotId, spot)
    end
end

local function DeleteSpotBlip(spotId)
    if spotBlips[spotId] and DoesBlipExist(spotBlips[spotId]) then
        RemoveBlip(spotBlips[spotId])
        spotBlips[spotId] = nil
    end
end

function CreateSpotBlip(spotId, spot)
    if not spot.blip_enabled then return end
    if not CanAccessSpot(spot) then return end

    if spotBlips[spotId] and DoesBlipExist(spotBlips[spotId]) then
        RemoveBlip(spotBlips[spotId])
    end

    local coords = type(spot.coords) == "table" and spot.coords[1] or spot.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, spot.blip_sprite or 1)
    SetBlipColour(blip, spot.blip_color or 1)
    SetBlipScale(blip, spot.blip_scale or 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(spot.blip_label or spot.name)
    EndTextCommandSetBlipName(blip)

    spotBlips[spotId] = blip
end

local function spotEquals(a, b)
    if not a or not b then return false end
    return a.spotId == b.spotId and a.coordIndex == b.coordIndex
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for spotId, blip in pairs(spotBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

-- Thread unique : cercles, détection proximité, prompt et trigger d'interaction.
-- Mutuellement exclusif avec le thread de contrôle de cl_harvesting_ui.lua (actif uniquement pendant isHarvesting).
local lastHelpNotif = 0

Citizen.CreateThread(function()
    while true do
        local sleep = 500

        if isHarvesting then
            if isNearSpot then
                isNearSpot = false
                currentSpot = nil
            end
            keyMustBeReleased = true
            sleep = 250
        elseif next(spotCircles) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local inCircle = nil

            for spotId, circlePosList in pairs(spotCircles) do
                for idx, circlePos in ipairs(circlePosList) do
                    local distance = #(playerCoords - circlePos)

                    if distance < 10.0 then
                        sleep = 0
                        local color = spotCircleColors[spotId] or {139, 0, 0, 150}

                        DrawMarker(
                            1,
                            circlePos.x, circlePos.y, circlePos.z,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.5, 0.5, 0.1,
                            color[1], color[2], color[3], color[4],
                            false, false,
                            2, false,
                            nil, nil, false
                        )
                    end

                    if not inCircle then
                        local detectionPos = vector3(circlePos.x, circlePos.y, circlePos.z + 0.85)
                        if #(playerCoords - detectionPos) < 0.5 then
                            inCircle = {spotId = spotId, coordIndex = idx}
                        end
                    end
                end
            end

            if inCircle then
                local isNewSpot = not isNearSpot or not spotEquals(currentSpot, inCircle)
                if isNewSpot then
                    isNearSpot = true
                    currentSpot = inCircle
                end

                local spot = harvestingSpots[inCircle.spotId]
                if spot and spot.interaction then
                    -- À l'entrée du spot, force le release si E est déjà appuyé
                    if isNewSpot and IsControlPressed(0, spot.interaction.key) then
                        keyMustBeReleased = true
                    end

                    -- Throttle NUI : 1 SendNUIMessage / 800ms au lieu de 60/sec
                    local now = GetGameTimer()
                    if isNewSpot or now - lastHelpNotif > 800 then
                        VFW.ShowHelpNotification(string.format("~b~%s~s~\n~w~%s", spot.name, spot.interaction.text))
                        lastHelpNotif = now
                    end

                    if keyMustBeReleased then
                        if not IsControlPressed(0, spot.interaction.key) then
                            keyMustBeReleased = false
                        end
                    elseif IsControlJustPressed(0, spot.interaction.key) then
                        keyMustBeReleased = true
                        TriggerServerEvent('illegalHarvesting:startHarvest', inCircle.spotId, inCircle.coordIndex)
                    end
                end
            elseif isNearSpot then
                isNearSpot = false
                currentSpot = nil
                keyMustBeReleased = false
                lastHelpNotif = 0
            end
        end

        Citizen.Wait(sleep)
    end
end)

exports('getCurrentSpot', function()
    return currentSpot
end)

exports('isNearSpot', function()
    return isNearSpot
end)

exports('LoadHarvestingSpots', LoadHarvestingSpots)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    LoadHarvestingSpots()
end)

RegisterNetEvent("illegalHarvesting:refreshSpots", function(spotsConfig)
    for spotId, _ in pairs(spotBlips) do
        DeleteSpotBlip(spotId)
    end

    harvestingSpots = spotsConfig or {}

    for spotId, spot in pairs(harvestingSpots) do
        if type(spot.coords) == "table" then
            spotCoordsList[spotId] = spot.coords
            spotCircles[spotId] = {}
            for i, coord in ipairs(spot.coords) do
                spotCircles[spotId][i] = CalculateCirclePosition(coord, 0)
            end
        else
            spotCoordsList[spotId] = {spot.coords}
            spotCircles[spotId] = {CalculateCirclePosition(spot.coords, 0)}
        end

        if spot.interaction and spot.interaction.circleColor then
            spotCircleColors[spotId] = spot.interaction.circleColor
        else
            spotCircleColors[spotId] = {139, 0, 0, 150}
        end
    end

    SpawnAllSpots()
end)

local function RefreshSpotBlips()
    for spotId, _ in pairs(spotBlips) do
        DeleteSpotBlip(spotId)
    end
    for spotId, spot in pairs(harvestingSpots) do
        CreateSpotBlip(spotId, spot)
    end
end

RegisterNetEvent("vfw:setFaction")
AddEventHandler("vfw:setFaction", function()
    Citizen.Wait(100)
    RefreshSpotBlips()
end)