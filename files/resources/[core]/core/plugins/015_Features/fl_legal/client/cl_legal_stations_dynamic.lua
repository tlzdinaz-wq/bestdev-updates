local legalStations = {}
local legalStationProps = {}
local legalStationBlips = {}
local legalStationRecipes = {}
local isNearLegalStation = false
local currentLegalStation = nil
local legalFloatingShown = false
local legalFloatingId = nil
local currentOpenLegalStationId = nil
local currentLegalRecipes = {}

local RefreshLegalStationBlips

local function CanAccessStation(station)
    if not station.job_restriction or station.job_restriction == "" then
        return true
    end

    local playerJob = VFW.PlayerData.job
    if not playerJob or playerJob.name ~= station.job_restriction then
        return false
    end

    if station.job_grade_min and station.job_grade_min > 0 then
        local playerGrade = playerJob.grade or 0
        if playerGrade < station.job_grade_min then
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

local function SpawnLegalStationProp(stationId, station)
    if not station.prop_model or station.prop_model == "" then
        return nil
    end

    if legalStationProps[stationId] and DoesEntityExist(legalStationProps[stationId]) then
        DeleteEntity(legalStationProps[stationId])
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

    legalStationProps[stationId] = prop
    return prop
end

local function DeleteLegalStationProp(stationId)
    if legalStationProps[stationId] and DoesEntityExist(legalStationProps[stationId]) then
        DeleteEntity(legalStationProps[stationId])
        legalStationProps[stationId] = nil
    end
end

local function CreateLegalStationBlip(stationId, station)
    if not station.blip_enabled then return end
    if not CanAccessStation(station) then return end

    if legalStationBlips[stationId] and DoesBlipExist(legalStationBlips[stationId]) then
        RemoveBlip(legalStationBlips[stationId])
    end

    local blip = AddBlipForCoord(station.coords_x, station.coords_y, station.coords_z)
    SetBlipSprite(blip, station.blip_sprite or 1)
    SetBlipColour(blip, station.blip_color or 1)
    SetBlipScale(blip, station.blip_scale or 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(station.blip_label or station.name)
    EndTextCommandSetBlipName(blip)

    legalStationBlips[stationId] = blip
end

local function DeleteLegalStationBlip(stationId)
    if legalStationBlips[stationId] and DoesBlipExist(legalStationBlips[stationId]) then
        RemoveBlip(legalStationBlips[stationId])
        legalStationBlips[stationId] = nil
    end
end

local function SpawnAllLegalStations()
    for stationId, station in pairs(legalStations) do
        SpawnLegalStationProp(stationId, station)
        CreateLegalStationBlip(stationId, station)
    end
end

local function DeleteAllLegalStations()
    for stationId, _ in pairs(legalStationProps) do
        DeleteLegalStationProp(stationId)
    end
    for stationId, _ in pairs(legalStationBlips) do
        DeleteLegalStationBlip(stationId)
    end
end

local stationsLoaded = false

local function LoadLegalStations()
    if not TriggerServerCallback then
        Citizen.SetTimeout(2000, LoadLegalStations)
        return
    end

    TriggerServerCallback("legalBuilder:getStations", function(stations)
        if not stations then
            Citizen.SetTimeout(5000, function()
                if not stationsLoaded then
                    LoadLegalStations()
                end
            end)
            return
        end

        DeleteAllLegalStations()
        legalStations = {}

        for id, station in pairs(stations) do
            legalStations[id] = station
        end
        stationsLoaded = true

        SpawnAllLegalStations()
    end)
end

local function OpenLegalStationMenu(stationId)
    local station = legalStations[stationId]
    if not station then
        VFW.ShowNotification({ type = 'ROUGE', content = "Station introuvable" })
        return
    end

    if not CanAccessStation(station) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Accès refusé à cette station" })
        return
    end

    local slots = TriggerServerCallback("legalBuilder:getStationRecipesForNUI", tonumber(stationId))

    currentOpenLegalStationId = stationId
    currentLegalRecipes = {}
    for _, slot in ipairs(slots or {}) do
        currentLegalRecipes[slot.id] = slot.recipeDbId
    end

    VFW.Nui.IllegalCrafting(true, {
        title = station.name or 'FABRICATION',
        stationId = stationId,
        isDynamic = true,
        type = 'legal',
        slots = slots or {}
    })
end

local function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

RegisterNetEvent("legalBuilder:syncStations")
AddEventHandler("legalBuilder:syncStations", function(stations)
    DeleteAllLegalStations()
    legalStations = {}

    if stations then
        for id, station in pairs(stations) do
            legalStations[id] = station
        end
        stationsLoaded = true
    end

    SpawnAllLegalStations()
end)

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    LoadLegalStations()
    TriggerServerEvent("legalBuilder:requestSync")
end)

AddEventHandler("vfw:playerLoaded", function()
    Citizen.Wait(1000)
    LoadLegalStations()
    Citizen.Wait(2000)
    RefreshLegalStationBlips()
end)

AddEventHandler("playerSpawned", function()
    Citizen.Wait(1000)
    if not stationsLoaded then
        LoadLegalStations()
    end
end)

local function ShowLegalFloating(stationId, station, worldPos)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.5)
    if not onScreen then
        if legalFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            legalFloatingShown = false
            legalFloatingId = nil
        end
        return
    end

    local data = {
        id = "legal_station_" .. tostring(stationId),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Ouvrir", key = "E" }
        }
    }

    if legalFloatingShown and legalFloatingId == stationId then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        legalFloatingShown = true
        legalFloatingId = stationId
    end
end

local function HideLegalFloating()
    if legalFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        legalFloatingShown = false
        legalFloatingId = nil
    end
end

Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local sleep = 500
        local found = false

        if IsNuiFocused() then
            HideLegalFloating()
            Citizen.Wait(sleep)
            goto continueLoop
        end

        for stationId, station in pairs(legalStations) do
            if not CanAccessStation(station) then goto continueStation end

            local markerX, markerY, markerZ
            if station.marker_x and station.marker_y and station.marker_z then
                markerX, markerY, markerZ = station.marker_x, station.marker_y, station.marker_z
            else
                markerX, markerY, markerZ = station.coords_x, station.coords_y, station.coords_z
                if station.prop_model and station.prop_model ~= "" then
                    markerZ = station.coords_z + 0.95
                end
            end

            local interactCoords = vector3(markerX, markerY, markerZ)
            local distance = #(playerCoords - interactCoords)

            if distance < 1.5 then
                found = true
                sleep = 0
                isNearLegalStation = true
                currentLegalStation = station.id

                ShowLegalFloating(stationId, station, interactCoords)

                if VFW.Interact.JustPressed(0, 38) then
                    HideLegalFloating()
                    OpenLegalStationMenu(station.id)
                end
                break
            end

            ::continueStation::
        end

        if not found then
            HideLegalFloating()
            if isNearLegalStation then
                isNearLegalStation = false
                currentLegalStation = nil
            end
        end

        Citizen.Wait(sleep)
        ::continueLoop::
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)

        for stationId, station in pairs(legalStations) do
            local prop = legalStationProps[stationId]
            if station.prop_model and station.prop_model ~= "" then
                if not prop or not DoesEntityExist(prop) then
                    SpawnLegalStationProp(stationId, station)
                end
            end
        end
    end
end)

RegisterNetEvent("legalBuilder:refreshStations", function(stations)
    DeleteAllLegalStations()
    legalStations = {}

    if stations then
        for id, station in pairs(stations) do
            legalStations[id] = station
        end
        stationsLoaded = true
    end

    SpawnAllLegalStations()
end)

RegisterNetEvent("legalBuilder:stationCreated", function(station)
    if not station or not station.id then return end
    legalStations[station.id] = station
    SpawnLegalStationProp(station.id, station)
    CreateLegalStationBlip(station.id, station)
end)

RegisterNetEvent("legalBuilder:stationUpdated", function(station)
    if not station or not station.id then return end
    DeleteLegalStationProp(station.id)
    DeleteLegalStationBlip(station.id)
    legalStations[station.id] = station
    SpawnLegalStationProp(station.id, station)
    CreateLegalStationBlip(station.id, station)
end)

RegisterNetEvent("legalBuilder:stationDeleted", function(stationId)
    DeleteLegalStationProp(stationId)
    DeleteLegalStationBlip(stationId)
    legalStations[stationId] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        HideLegalFloating()
        DeleteAllLegalStations()
    end
end)

exports('getLegalStations', function()
    return legalStations
end)

exports('getLegalStationProp', function(stationId)
    return legalStationProps[stationId]
end)

exports('refreshLegalStations', function()
    LoadLegalStations()
end)

exports('isLegalStationOpen', function()
    return currentOpenLegalStationId ~= nil
end)

RefreshLegalStationBlips = function()
    for stationId, _ in pairs(legalStationBlips) do
        DeleteLegalStationBlip(stationId)
    end
    for stationId, station in pairs(legalStations) do
        CreateLegalStationBlip(stationId, station)
    end
end

RegisterNetEvent("vfw:setJob")
AddEventHandler("vfw:setJob", function()
    Citizen.Wait(100)
    RefreshLegalStationBlips()
end)

AddEventHandler('core:illegalCrafting:craft', function(data)
    if currentOpenLegalStationId and data.isLegal then
        local recipeName = data.itemId or data.id
        local recipeDbId = currentLegalRecipes[recipeName]
        local quantity = data.quantity or 1

        if not recipeDbId then
            recipeDbId = TriggerServerCallback("illegalBuilder:getRecipeIdByName", recipeName)
        end

        if not recipeDbId then
            VFW.ShowNotification({ type = 'ROUGE', content = "Recette introuvable" })
            return
        end

        TriggerEvent('legalBuilder:startCraft', currentOpenLegalStationId, recipeDbId, recipeName, quantity)
    end
end)

AddEventHandler('core:illegalCrafting:close', function()
    if currentOpenLegalStationId then
        currentOpenLegalStationId = nil
        currentLegalRecipes = {}
    end
end)

RegisterNetEvent('legalBuilder:startCraft', function(stationId, recipeDbId, recipeName, quantity)
    local result = TriggerServerCallback("legalBuilder:prepareCraft", {
        stationId = stationId,
        recipeId = recipeDbId,
        quantity = quantity or 1
    })

    if not result or not result.success then
        VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Erreur de préparation" })
        return
    end

    local totalCycles = result.totalCycles or quantity or 1
    for _ = 1, totalCycles do
        TriggerServerEvent("legalBuilder:completeCraftCycle")
        Citizen.Wait(50)
    end
end)

