local dynamicStations = {}
local dynamicStationProps = {}
local dynamicStationBlips = {}
local dynamicStationRecipes = {}
local isNearDynamicStation = false
local currentDynamicStation = nil
local currentOpenDynamicStationId = nil
local currentDynamicRecipes = {}

local RefreshDynamicStationBlips

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

local function RequestModelSync(model)
    if type(model) == "string" then
        model = GetHashKey(model)
    end
    if not IsModelInCdimage(model) then
        return false
    end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function SpawnDynamicStationProp(stationId, station)
    if not station.prop_model or station.prop_model == "" then
        return nil
    end

    if dynamicStationProps[stationId] and DoesEntityExist(dynamicStationProps[stationId]) then
        DeleteEntity(dynamicStationProps[stationId])
    end

    if not RequestModelSync(station.prop_model) then
        return nil
    end

    local modelHash = GetHashKey(station.prop_model)
    local prop = CreateObject(modelHash, station.coords_x, station.coords_y, station.coords_z, false, false, false)

    if not DoesEntityExist(prop) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    SetEntityHeading(prop, station.rotation_z or 0.0)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityInvincible(prop, true)
    SetEntityCanBeDamaged(prop, false)

    SetModelAsNoLongerNeeded(modelHash)

    dynamicStationProps[stationId] = prop
    return prop
end

local function DeleteDynamicStationProp(stationId)
    if dynamicStationProps[stationId] and DoesEntityExist(dynamicStationProps[stationId]) then
        DeleteEntity(dynamicStationProps[stationId])
        dynamicStationProps[stationId] = nil
    end
end

local function CreateDynamicStationBlip(stationId, station)
    if not station.blip_enabled then return end
    if not CanAccessStation(station) then return end

    if dynamicStationBlips[stationId] and DoesBlipExist(dynamicStationBlips[stationId]) then
        RemoveBlip(dynamicStationBlips[stationId])
    end

    local blip = AddBlipForCoord(station.coords_x, station.coords_y, station.coords_z)
    SetBlipSprite(blip, station.blip_sprite or 1)
    SetBlipColour(blip, station.blip_color or 1)
    SetBlipScale(blip, station.blip_scale or 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(station.blip_label or station.name)
    EndTextCommandSetBlipName(blip)

    dynamicStationBlips[stationId] = blip
end

local function DeleteDynamicStationBlip(stationId)
    if dynamicStationBlips[stationId] and DoesBlipExist(dynamicStationBlips[stationId]) then
        RemoveBlip(dynamicStationBlips[stationId])
        dynamicStationBlips[stationId] = nil
    end
end

local function SpawnAllDynamicStations()
    for stationId, station in pairs(dynamicStations) do
        SpawnDynamicStationProp(stationId, station)
        CreateDynamicStationBlip(stationId, station)
    end
end

local function DeleteAllDynamicStations()
    for stationId, _ in pairs(dynamicStationProps) do
        DeleteDynamicStationProp(stationId)
    end
    for stationId, _ in pairs(dynamicStationBlips) do
        DeleteDynamicStationBlip(stationId)
    end
end

local stationsLoaded = false
local stationsLoading = false

local function LoadDynamicStations()
    if stationsLoading then return end
    stationsLoading = true

    if not TriggerServerCallback then
        stationsLoading = false
        Citizen.SetTimeout(2000, LoadDynamicStations)
        return
    end

    TriggerServerCallback("illegalBuilder:getCraftStations", function(stations)
        if not stations then
            stationsLoading = false
            Citizen.SetTimeout(5000, function()
                if not stationsLoaded then
                    LoadDynamicStations()
                end
            end)
            return
        end

        DeleteAllDynamicStations()
        dynamicStations = {}

        for id, station in pairs(stations) do
            dynamicStations[id] = station
        end
        stationsLoaded = true

        SpawnAllDynamicStations()
        stationsLoading = false
    end)
end

local function LoadStationRecipes(stationId, callback)
    local numId = tonumber(stationId)
    local recipes = TriggerServerCallback("illegalBuilder:getStationRecipes", numId)
    dynamicStationRecipes[stationId] = recipes or {}
    if callback then callback(recipes) end
end

local function OpenDynamicStationMenu(stationId)
    local station = dynamicStations[stationId]
    if not station then
        return
    end

    if not CanAccessStation(station) then
        return
    end

    local playerPed = PlayerPedId()
    SetEntityHeading(playerPed, station.rotation_z or 0.0)

    local slots = TriggerServerCallback("illegalBuilder:getStationRecipesForNUI", tonumber(stationId))

    currentOpenDynamicStationId = stationId
    currentDynamicRecipes = {}
    for _, slot in ipairs(slots or {}) do
        currentDynamicRecipes[slot.id] = slot.recipeDbId
    end

    local queueData = TriggerServerCallback("illegalBuilder:getStationQueue", tonumber(stationId))

    VFW.Nui.IllegalCrafting(true, {
        title = station.name or 'FABRICATION',
        stationId = stationId,
        isDynamic = true,
        type = 'illegal',
        stationType = station.station_type or 'armes',
        slots = slots or {},
        queue = queueData or {}
    })
end

local function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

RegisterNetEvent("illegalBuilder:syncCraftStations")
AddEventHandler("illegalBuilder:syncCraftStations", function(stations)
    DeleteAllDynamicStations()
    dynamicStations = {}

    if stations then
        for id, station in pairs(stations) do
            dynamicStations[id] = station
        end
        stationsLoaded = true
    end

    SpawnAllDynamicStations()
end)

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    LoadDynamicStations()
    TriggerServerEvent("illegalBuilder:requestSync")
end)

AddEventHandler("vfw:playerLoaded", function()
    Citizen.Wait(1000)
    LoadDynamicStations()
    Citizen.Wait(2000)
    RefreshDynamicStationBlips()
end)

AddEventHandler("playerSpawned", function()
    Citizen.Wait(1000)
    if not stationsLoaded then
        LoadDynamicStations()
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        local foundStation = nil

        for stationId, station in pairs(dynamicStations) do
            local stationCoords = vector3(station.coords_x, station.coords_y, station.coords_z)
            local distance = #(playerCoords - stationCoords)

            if distance < 8.0 then
                sleep = 0

                if distance > 1.5 then
                    local markerX, markerY, markerZ
                    if station.marker_x and station.marker_y and station.marker_z then
                        markerX, markerY, markerZ = station.marker_x, station.marker_y, station.marker_z
                    else
                        markerX, markerY, markerZ = stationCoords.x, stationCoords.y, stationCoords.z
                    end
                    DrawMarker(
                        22,
                        markerX, markerY, markerZ - 0.4,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.4, 0.4, 0.4,
                        0, 100, 255, 200,
                        true, true,
                        2, false,
                        nil, nil, false
                    )
                end

                if not foundStation then
                    local interactCoords
                    if station.marker_x and station.marker_y and station.marker_z then
                        interactCoords = vector3(station.marker_x, station.marker_y, station.marker_z)
                    else
                        interactCoords = stationCoords
                    end
                    if #(playerCoords - interactCoords) < 1.5 then
                        local actualId = station.id or stationId
                        foundStation = { id = actualId, station = station }
                    end
                end
            end
        end

        if foundStation then
            if not isNearDynamicStation or currentDynamicStation ~= foundStation.id then
                isNearDynamicStation = true
                currentDynamicStation = foundStation.id
            end

            local canAccess = CanAccessStation(foundStation.station)
            local accessText = canAccess and "~w~Appuyez sur ~y~[E]~w~ pour ouvrir" or "~r~Accès restreint"

            VFW.ShowHelpNotification(string.format("~b~%s~s~\n%s", foundStation.station.name or "Station", accessText))

            if canAccess and VFW.Interact.JustPressed(0, 38) then
                OpenDynamicStationMenu(foundStation.id)
            end
        else
            if isNearDynamicStation then
                isNearDynamicStation = false
                currentDynamicStation = nil
            end
        end

        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)

        for stationId, station in pairs(dynamicStations) do
            local prop = dynamicStationProps[stationId]
            if station.prop_model and station.prop_model ~= "" then
                if not prop or not DoesEntityExist(prop) then
                    SpawnDynamicStationProp(stationId, station)
                end
            end
        end
    end
end)

RegisterNetEvent("illegalCrafting:queueUpdated", function(stationId, queueData)
    if currentOpenDynamicStationId and tonumber(currentOpenDynamicStationId) == tonumber(stationId) then
        SendNUIMessage({ action = "illegalCrafting:queue", data = queueData or {} })
    end
end)

RegisterNetEvent("illegalBuilder:refreshStations", function()
    LoadDynamicStations()
end)

RegisterNetEvent("illegalBuilder:refreshCraftStations", function(stations)
    DeleteAllDynamicStations()
    dynamicStations = {}

    if stations then
        for id, station in pairs(stations) do
            dynamicStations[id] = station
        end
        stationsLoaded = true
    end

    SpawnAllDynamicStations()
end)

RegisterNetEvent("illegalBuilder:stationCreated", function(station)
    if not station or not station.id then return end
    dynamicStations[station.id] = station
    SpawnDynamicStationProp(station.id, station)
    CreateDynamicStationBlip(station.id, station)
end)

RegisterNetEvent("illegalBuilder:stationUpdated", function(station)
    if not station or not station.id then return end
    DeleteDynamicStationProp(station.id)
    DeleteDynamicStationBlip(station.id)
    dynamicStations[station.id] = station
    SpawnDynamicStationProp(station.id, station)
    CreateDynamicStationBlip(station.id, station)
end)

RegisterNetEvent("illegalBuilder:stationDeleted", function(stationId)
    DeleteDynamicStationProp(stationId)
    DeleteDynamicStationBlip(stationId)
    dynamicStations[stationId] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteAllDynamicStations()
    end
end)

exports('getDynamicStations', function()
    return dynamicStations
end)

exports('getDynamicStationProp', function(stationId)
    return dynamicStationProps[stationId]
end)

exports('refreshDynamicStations', function()
    LoadDynamicStations()
end)

exports('isDynamicStationOpen', function()
    return currentOpenDynamicStationId ~= nil
end)

RefreshDynamicStationBlips = function()
    for stationId, _ in pairs(dynamicStationBlips) do
        DeleteDynamicStationBlip(stationId)
    end
    for stationId, station in pairs(dynamicStations) do
        CreateDynamicStationBlip(stationId, station)
    end
end

RegisterNetEvent("vfw:setFaction")
AddEventHandler("vfw:setFaction", function()
    Citizen.Wait(100)
    RefreshDynamicStationBlips()
end)

-- « Fabriquer » : les composants partent tout de suite, la fabrication continue côté serveur ; la fenêtre reste ouverte
-- et passe d'elle-même sur l'onglet « File d'attente » (où l'on récupère les objets finis).
AddEventHandler('core:illegalCrafting:craft', function(data)
    if not currentOpenDynamicStationId or (data and data.isLegal) then return end

    local recipeName = data.itemId or data.id
    local recipeDbId = currentDynamicRecipes[recipeName]
    local quantity = tonumber(data.quantity) or 1
    local stationId = currentOpenDynamicStationId

    if not recipeDbId then
        recipeDbId = TriggerServerCallback("illegalBuilder:getRecipeIdByName", recipeName)
    end
    if not recipeDbId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Recette introuvable" })
        return
    end

    local result = TriggerServerCallback("illegalBuilder:startQueueCraft", tonumber(stationId), recipeDbId, quantity)
    if not (result and result.success) then
        VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Fabrication impossible" })
        return
    end

    SendNUIMessage({ action = "illegalCrafting:craftStart", data = { itemLabel = result.label, quantity = quantity } })

    -- quantités possibles recalculées (les composants viennent de partir)
    local station = dynamicStations[stationId]
    if station and currentOpenDynamicStationId == stationId then
        local slots = TriggerServerCallback("illegalBuilder:getStationRecipesForNUI", tonumber(stationId))
        VFW.Nui.IllegalCraftingUpdate({
            title = station.name or 'FABRICATION',
            stationId = stationId,
            isDynamic = true,
            type = 'illegal',
            stationType = station.station_type or 'armes',
            slots = slots or {},
        })
    end
end)

AddEventHandler('core:illegalCrafting:close', function()
    if currentOpenDynamicStationId then
        TriggerServerEvent("illegalBuilder:unregisterQueueViewer", tonumber(currentOpenDynamicStationId))
        currentOpenDynamicStationId = nil
        currentDynamicRecipes = {}
    end
end)
