local stationProps = {}
local stationBlips = {}
local currentStation = nil
local isNearStation = false
local targetSystemAvailable = false

targetSystemAvailable = false

local stations = {}

local stationCircles = {}

local stationCircleColors = {}

local stationCoordsList = {}

local craftFloatingShown = false
local craftFloatingId = nil

local isCrafting = false

local function CanAccessStation(station)
    if not station.faction_restriction or station.faction_restriction == "" then
        return true
    end

    local playerFaction = VFW.PlayerData.faction
    if not playerFaction or playerFaction.name ~= station.faction_restriction then
        return false
    end

    if station.faction_grade_min and station.faction_grade_min > 0 then
        local playerGrade = playerFaction.grade or 0
        if playerGrade < station.faction_grade_min then
            return false
        end
    end

    return true
end

local function CalculateCirclePosition(coords, heading, showProps)
    if not showProps then
        return coords
    end

    local distance = 0.8
    local radians = math.rad(heading)

    local circleX = coords.x - (math.sin(radians) * distance)
    local circleY = coords.y + (math.cos(radians) * distance)
    local circleZ = coords.z

    return vector3(circleX, circleY, circleZ)
end

RegisterNetEvent('illegalCrafting:receiveStations', function(stationsConfig)
    for stationId, _ in pairs(stationBlips) do
        DeleteStationBlip(stationId)
    end

    stations = stationsConfig

    for stationId, station in pairs(stations) do
        -- Skip stations without props
        if not station.showProps or not station.prop then
            if type(station.coords) == "table" then
                stationCoordsList[stationId] = station.coords
                stationCircles[stationId] = {}
                for i, coord in ipairs(station.coords) do
                    stationCircles[stationId][i] = coord  -- Use original coords for stations without props
                end
            else
                stationCoordsList[stationId] = {station.coords}
                stationCircles[stationId] = {station.coords}
            end
        elseif type(station.coords) == "table" then
            stationCoordsList[stationId] = station.coords
            stationCircles[stationId] = {}
            for i, coord in ipairs(station.coords) do
                stationCircles[stationId][i] = CalculateCirclePosition(coord, station.heading, station.showProps)
            end
        else
            stationCoordsList[stationId] = {station.coords}
            stationCircles[stationId] = {CalculateCirclePosition(station.coords, station.heading, station.showProps)}
        end

        if station.interaction and station.interaction.circleColor then
            stationCircleColors[stationId] = station.interaction.circleColor
        else
            stationCircleColors[stationId] = {255, 165, 0, 150}
        end
    end

    SpawnAllStations()
end)

function TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function SpawnAllStations()
    for stationId, station in pairs(stations) do
        SpawnStationProp(stationId, station)
        CreateStationBlip(stationId, station)
    end
end

function SpawnStationProp(stationId, station)
    if not station.showProps or not station.prop then
        return true
    end

    if stationProps[stationId] then
        if type(stationProps[stationId]) == "table" then
            for _, prop in ipairs(stationProps[stationId]) do
                if DoesEntityExist(prop) then
                    DeleteEntity(prop)
                end
            end
        else
            if DoesEntityExist(stationProps[stationId]) then
                DeleteEntity(stationProps[stationId])
            end
        end
    end

    local propHash = GetHashKey(station.prop)

    RequestModel(propHash)
    local attempts = 0
    while not HasModelLoaded(propHash) and attempts < 100 do
        Citizen.Wait(100)
        attempts = attempts + 1
    end

    if not HasModelLoaded(propHash) then
        TriggerEvent('illegalCrafting:notify', 'ROUGE', string.format("~r~Erreur: Impossible de charger le modèle %s", station.prop))
        return false
    end

    local coords = type(station.coords) == "table" and station.coords[1] or station.coords
    local prop = CreateObject(propHash, coords.x, coords.y, coords.z, false, false, false)

    if not DoesEntityExist(prop) then
        TriggerEvent('illegalCrafting:notify', 'ROUGE', string.format("~r~Erreur: Impossible de créer le prop pour %s", stationId))
        SetModelAsNoLongerNeeded(propHash)
        return false
    end

    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityHeading(prop, station.heading)

    SetEntityInvincible(prop, true)
    SetEntityCanBeDamaged(prop, false)

    stationProps[stationId] = prop

    SetModelAsNoLongerNeeded(propHash)

    return true
end

local function DeleteStationBlip(stationId)
    if stationBlips[stationId] and DoesBlipExist(stationBlips[stationId]) then
        RemoveBlip(stationBlips[stationId])
        stationBlips[stationId] = nil
    end
end

function CreateStationBlip(stationId, station)
    if not station.blip_enabled then return end
    if not CanAccessStation(station) then return end

    if stationBlips[stationId] and DoesBlipExist(stationBlips[stationId]) then
        RemoveBlip(stationBlips[stationId])
    end

    local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
    SetBlipSprite(blip, station.blip_sprite or 1)
    SetBlipColour(blip, station.blip_color or 1)
    SetBlipScale(blip, station.blip_scale or 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(station.blip_label or station.name)
    EndTextCommandSetBlipName(blip)

    stationBlips[stationId] = blip
end

local function ShowCraftFloating(stationId, station, worldPos)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.5)
    if not onScreen then
        if craftFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            craftFloatingShown = false
            craftFloatingId = nil
        end
        return
    end

    local data = {
        id = "craft_illegal_" .. tostring(stationId),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Ouvrir", key = "E" }
        }
    }

    if craftFloatingShown and craftFloatingId == stationId then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        craftFloatingShown = true
        craftFloatingId = stationId
    end
end

local function HideCraftFloating()
    if craftFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        craftFloatingShown = false
        craftFloatingId = nil
    end
end

function SetupTargetInteractions()
    for stationId, station in pairs(stations) do
        local options = {
            {
                name = 'illegal_crafting_' .. stationId,
                icon = 'fas fa-hammer',
                label = station.name,
                action = function()
                    OpenStationMenu(stationId)
                end,
                canInteract = function()
                    return true
                end
            }
        }

        if targetSystemAvailable == 'ox_target' then
            exports.ox_target:addLocalEntity(stationProps[stationId], options)
        elseif targetSystemAvailable == 'qb-target' then
            exports['qb-target']:AddTargetEntity(stationProps[stationId], {
                options = options,
                distance = station.interaction.distance
            })
        end
    end
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = #(vector3(p.x, p.y, p.z) - vector3(x, y, z))
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scaleMultiplier = scale * fov

    if onScreen then
        SetTextScale(0.0 * scaleMultiplier, 0.55 * scaleMultiplier)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function OpenStationMenu(stationId)
    local station = stations[stationId]
    if not station then
        TriggerEvent('illegalCrafting:notify', 'ROUGE', "~r~Station introuvable")
        return
    end


    TriggerServerEvent('illegalCrafting:openStationMenu', stationId)
end

RegisterNetEvent('illegalCrafting:closeMenu', function()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        HideCraftFloating()

        for stationId, prop in pairs(stationProps) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end

        for stationId, blip in pairs(stationBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        if targetSystemAvailable then
        end

    end
end)

function ShowCraftingNotification(_, message)
    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = message
    })
end

RegisterNetEvent('illegalCrafting:notify', function(type, message)
    ShowCraftingNotification(type, message)
end)

RegisterNetEvent('illegalCrafting:visible', function(visible)

    VFW.Nui.Focus(visible)

    if visible then
        HideCraftFloating()
    else
        isNearStation = false
        currentStation = nil
    end

    SendNUIMessage({
        action = 'illegalCrafting:visible',
        data = visible
    })
end)

RegisterNetEvent('illegalCrafting:data', function(data)
    SendNUIMessage({
        action = 'illegalCrafting:data',
        data = data
    })
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    TriggerServerEvent('illegalCrafting:requestStations')
end)

RegisterNUICallback('illegalCrafting:close', function(data, cb)
    TriggerServerEvent('illegalCrafting:close')
    cb('ok')
end)

-- Using the IllegalHarvesting cancel callback
RegisterNUICallback('illegalHarvesting:cancel', function(data, cb)
    if isCrafting then
        CancelCrafting()
    end
    cb('ok')
end)

RegisterNUICallback('illegalCrafting:craft', function(data, cb)
    if exports['core']:isDynamicStationOpen() then
        return
    end

    local craftInfo = TriggerServerCallback('illegalCrafting:prepareCraft', data)

    if craftInfo.success then
        StartCraftingTimer(data.itemId, data.quantity, craftInfo.craftTime, craftInfo.stationId, craftInfo.itemLabel)
        cb({success = true})
    else
        cb({success = false, message = craftInfo.message})
    end
end)

local craftStartTime = 0
local craftDuration = 0
local craftItemId = ""
local craftQuantity = 1
local craftStationId = ""
local craftCurrentCycle = 0
local craftTotalCycles = 1
local craftItemLabel = ""

function StartCraftingTimer(itemId, quantity, duration, stationId, itemLabel)
    if isCrafting then
        TriggerEvent('illegalCrafting:notify', 'ROUGE', "~r~Un craft est déjà en cours")
        return
    end

    isCrafting = false
    craftStartTime = 0
    craftDuration = 0
    craftItemId = ""
    craftQuantity = 1
    craftStationId = ""
    craftCurrentCycle = 0
    craftTotalCycles = 1
    craftItemLabel = ""

    Citizen.Wait(0)

    isCrafting = true
    craftStartTime = GetGameTimer()
    craftDuration = duration * 1000
    craftItemId = itemId
    craftQuantity = 1
    craftStationId = stationId
    craftCurrentCycle = 1
    craftTotalCycles = quantity
    craftItemLabel = itemLabel or itemId

    SendNUIMessage({
        action = 'illegalCrafting:craftStart',
        data = {
            itemLabel = craftItemLabel,
            quantity = quantity
        }
    })
end

function StopCraftingAnimation()
end

function CancelCrafting()
    if isCrafting then
        isCrafting = false
        craftStartTime = 0
        craftDuration = 0
        craftItemId = ""
        craftQuantity = 1
        craftStationId = ""
        craftCurrentCycle = 0
        craftTotalCycles = 1

        TriggerServerEvent('illegalCrafting:cancelCraft')

        TriggerEvent('illegalCrafting:notify', 'JAUNE', "~y~Fabrication annulée")
    end
end

Citizen.CreateThread(function()
    while true do
        if isCrafting then
            local currentTime = GetGameTimer()
            local elapsed = currentTime - craftStartTime

            if elapsed >= craftDuration then
                TriggerServerEvent('illegalCrafting:completeCraft', {
                    itemId = craftItemId,
                    quantity = 1,
                    stationId = craftStationId
                })

                if craftCurrentCycle < craftTotalCycles then
                    craftCurrentCycle = craftCurrentCycle + 1
                    craftStartTime = GetGameTimer()
                else
                    TriggerEvent('illegalCrafting:notify', 'VERT', string.format("~g~Fabrication complète: %d/%d", craftTotalCycles, craftTotalCycles))

                    TriggerServerEvent('illegalCrafting:cancelCraft')

                    SendNUIMessage({
                        action = 'illegalCrafting:craftDone',
                        data = true
                    })

                    isCrafting = false
                    craftStartTime = 0
                    craftDuration = 0
                    craftItemId = ""
                    craftQuantity = 1
                    craftStationId = ""
                    craftCurrentCycle = 0
                    craftTotalCycles = 1
                end
            end

            Citizen.Wait(100)
        else
            Citizen.Wait(500)
        end
    end
end)

exports('getCurrentStation', function()
    return currentStation
end)

exports('isNearStation', function()
    return isNearStation
end)

exports('getStationProp', function(stationId)
    return stationProps[stationId]
end)

exports('isCrafting', function()
    return isCrafting
end)

RegisterNetEvent('illegalCrafting:startTimer', function(itemId, quantity, craftTime, stationId, itemLabel)
    StartCraftingTimer(itemId, quantity, craftTime, stationId, itemLabel)
end)

-- COMMANDE SUPPRIMÉE : /testicrafting


Citizen.CreateThread(function()
    while true do
        local wait = 500

        if stations and TableLength(stations) > 0 and not isCrafting and not IsNuiFocused() then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local found = false

            for stationId, circlePosList in pairs(stationCircles) do
                local station = stations[stationId]
                if not station then goto continueStation end

                for idx, circlePos in ipairs(circlePosList) do
                    local interactDist = (station.interaction and station.interaction.distance) or 1.5
                    local distance = #(playerCoords - circlePos)

                    if distance < interactDist then
                        found = true
                        wait = 0
                        isNearStation = true
                        currentStation = { stationId = stationId, coordIndex = idx }

                        ShowCraftFloating(stationId, station, circlePos)

                        if VFW.Interact.JustPressed(0, 38) then
                            HideCraftFloating()
                            OpenStationMenu(stationId)
                        end
                        break
                    end
                end

                if found then break end
                ::continueStation::
            end

            if not found then
                HideCraftFloating()
                if isNearStation then
                    isNearStation = false
                    currentStation = nil
                end
            end
        end

        Citizen.Wait(wait)
    end
end)

Citizen.CreateThread(function()
    while true do
        if stations and TableLength(stations) > 0 then
            for stationId, station in pairs(stations) do
                local prop = stationProps[stationId]
                if not prop or not DoesEntityExist(prop) then
                    SpawnStationProp(stationId, station)
                end
            end
        end
        Citizen.Wait(30000)
    end
end)

local function RefreshStationBlips()
    for stationId, _ in pairs(stationBlips) do
        DeleteStationBlip(stationId)
    end
    for stationId, station in pairs(stations) do
        CreateStationBlip(stationId, station)
    end
end

RegisterNetEvent("vfw:setFaction")
AddEventHandler("vfw:setFaction", function()
    Citizen.Wait(100)
    RefreshStationBlips()
end)

