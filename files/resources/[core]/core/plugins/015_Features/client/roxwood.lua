---@meta _
---@diagnostic disable: duplicate-doc-field

local lastEntity = false
local rentalTimer = false
local rentalZone = vector3(-2857.48, 8329.44, 42.28)
local rentalZoneRadius = 500.0
local locationData = {}
local dataLocation = {
    ["formula"] = { label = "Formula 1" },
    ["formula2"] = { label = "Formula 2" },
}

--- isInRentalZone
---@param vehicle number|table Vehicle handle or object
---@return boolean
local function isInRentalZone(vehicle)
    local vehCoords = GetEntityCoords(vehicle)
    return #(vehCoords - rentalZone) <= rentalZoneRadius
end

--- startRentalTimer
---@param duration any
local function startRentalTimer(duration)
    if rentalTimer then
        rentalTimer = false
        Wait(100)
    end

    rentalTimer = true
    local startTime = GetGameTimer()

    CreateThread(function()
        while rentalTimer do
            local currentTime = GetGameTimer()
            local elapsed = (currentTime - startTime) / 60000

            if elapsed >= duration then
                local playerPed = PlayerPedId()
                if IsPedInAnyVehicle(playerPed, false) then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    TaskLeaveVehicle(playerPed, vehicle, 0)
                    Wait(2000)
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                end

                rentalTimer = false
                lastEntity = false
                break
            end

            if currentTime % 5000 < 100 then
                if lastEntity and DoesEntityExist(lastEntity) then
                    if not isInRentalZone(lastEntity) then
                        for i = 10, 1, -1 do
                            if not isInRentalZone(lastEntity) then
                                Wait(1000)
                            else
                                break
                            end

                            if i == 1 then
                                SetEntityAsMissionEntity(lastEntity, true, true)
                                DeleteVehicle(lastEntity)
                                lastEntity = false
                                rentalTimer = false
                            end
                        end
                    end
                end
            end

            Wait(1000)
        end
    end)
end

---Get Location
local function getLocation()
---@class locationData
    locationData = {}

    for k, v in pairs(dataLocation) do
        local tempCatalogue = {
            label = v.label,
            model = k,
            image = ("assets/vehicules/%s.webp"):format(k),
            price = 200,
        }

        table.insert(locationData, tempCatalogue)
    end

    return locationData
end

---Get LocationData
---@return any
local function getLocationData()
    local data = {
        style = {
            menuStyle = "custom",
            backgroundType = 1,
            bannerType = 2,
            gridType = 1,
            buyType = 2,
            bannerImg = "assets/catalogues/headers/header_location.webp",
            buyTextType = false,
            buyText = "Louer",
        },
        eventName = "roxwood",
        category = { show = false },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        showStats = { show = false },
        mouseEvents = false,
        color = { show = false },
        items = getLocation()
    }

    return data
end

--- SelectBuy
---@param model any
---@return any
local function SelectBuy(model)
    if not model or model == 0 then
        console.error("Model is not valid for purchase.")
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    if lastEntity and DoesEntityExist(lastEntity) then
        SetEntityAsMissionEntity(lastEntity, true, true)
        DeleteEntity(lastEntity)
        lastEntity = false
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end

    lastEntity = VFW.OneSync.CreateVehicleRaw(model, coords, GetEntityHeading(playerPed))
    SetVehicleOnGroundProperly(lastEntity)
    SetVehicleNumberPlateText(lastEntity, "ROXWOOD")
    TaskWarpPedIntoVehicle(playerPed, lastEntity, -1)

    startRentalTimer(10)

    local blip = AddBlipForEntity(lastEntity)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Véhicule loué")
    EndTextCommandSetBlipName(blip)
end

RegisterNuiCallback("nui:newgrandcatalogue:roxwood:selectBuy", function(data)
    if lastEntity and DoesEntityExist(lastEntity) then
        SetEntityAsMissionEntity(lastEntity, true, true)
        SetEntityAsNoLongerNeeded(lastEntity)
        DeleteEntity(lastEntity)
        lastEntity = false
        console.debug("Entity successfully deleted when closing.")
    else
        console.debug("No entity to delete or entity already deleted when closing.")
    end

    VFW.Nui.BigMenu(false)

    Wait(150)

    for k, _ in pairs(dataLocation) do
        if k == data then
            local check = TriggerServerCallback("core:roxwood:check", 200)
            if check then
                SelectBuy(joaat(data))
            end

            break
        end
    end
end)

RegisterNUICallback("nui:newgrandcatalogue:roxwood:close", function()
    VFW.Nui.BigMenu(false)
end)

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end

    --TODO: Good coords
    --VFW.CreateBlipAndPoint("roxwood", vector3(-2760.5, 8071.69, 42.49 + 1.25), 1, 595, 3, 0.8, "Location Roxwood",  "Location", "E", "Location",{
    --    onPress = function()
    --        VFW.Nui.BigMenu(true, getLocationData())
    --    end
    --})
end)
