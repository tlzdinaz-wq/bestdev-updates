CreateThread(function()
    while true do
        Wait(5000)
        TriggerEvent('esx_ambulancejobIsPlayerInLife')
    end
end)

local trapVehicles = {}
local trapHandles = {}

local TRAP_MODELS = {
    "adder", "zentorno", "t20", "entity2", "entityxf",
    "osiris", "turismor", "reaper", "fmj", "tempesta",
    "vagner", "xa21", "tezeract", "emerus", "krieger",
    "thrax", "zorrusso", "tigon", "furia", "visione",
}

local TRAP_LOCATIONS = {
    vector4(-1042.0, -2745.0, -15.0, 0.0),
    vector4(2540.0, 1665.0, -30.0, 90.0),
    vector4(1290.0, -1750.0, -40.0, 180.0),
    vector4(-550.0, 5300.0, -20.0, 45.0),
    vector4(460.0, -980.0, -50.0, 270.0),

    vector4(0.0, 0.0, 1500.0, 0.0),
    vector4(-1600.0, -1000.0, 1200.0, 120.0),
    vector4(2000.0, 3500.0, 1800.0, 200.0),
    vector4(-2500.0, 3000.0, 1400.0, 60.0),

    vector4(-5000.0, -5000.0, -50.0, 0.0),
    vector4(5000.0, 5000.0, -100.0, 90.0),
    vector4(-4000.0, 6000.0, -80.0, 180.0),
    vector4(6000.0, -4000.0, -60.0, 270.0),

    vector4(-3100.0, 500.0, -60.0, 45.0),
    vector4(3200.0, -600.0, -70.0, 135.0),
    vector4(-1800.0, -2200.0, -55.0, 0.0),
    vector4(800.0, 7200.0, -90.0, 210.0),

    vector4(500.0, 5600.0, 600.0, 300.0),
    vector4(-1950.0, 2100.0, -25.0, 160.0),
    vector4(2800.0, 1400.0, -35.0, 75.0),
}

local trapsSpawned = false

---@param hash number
---@return boolean
local function loadTrapModel(hash)
    if HasModelLoaded(hash) then
        return true
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then
            return false
        end
        Wait(0)
    end

    return true
end

---@param modelName string
---@param loc vector4
---@return number|nil
local function createTrapVehicle(modelName, loc)
    local hash = joaat(modelName)
    if not IsModelValid(hash) then
        return nil
    end

    if not loadTrapModel(hash) then
        return nil
    end

    local veh = CreateVehicle(hash, loc.x, loc.y, loc.z, loc.w, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(veh) then
        return nil
    end

    SetEntityVisible(veh, false, false)
    SetVehicleDoorsLocked(veh, 2)
    FreezeEntityPosition(veh, true)
    SetEntityInvincible(veh, true)
    SetEntityAsMissionEntity(veh, true, true)

    return veh
end

local function clearTrapVehicles()
    for i = 1, #trapHandles do
        local veh = trapHandles[i]
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end

    for entity in pairs(trapVehicles) do
        trapVehicles[entity] = nil
    end

    for i = #trapHandles, 1, -1 do
        trapHandles[i] = nil
    end

    trapsSpawned = false
end

local function spawnTrapVehicles()
    clearTrapVehicles()

    local modelCount = #TRAP_MODELS
    for i = 1, #TRAP_LOCATIONS do
        local loc = TRAP_LOCATIONS[i]
        local modelName = TRAP_MODELS[((i - 1) % modelCount) + 1]
        local veh = createTrapVehicle(modelName, loc)

        if veh then
            trapVehicles[veh] = modelName
            trapHandles[#trapHandles + 1] = veh
        end
    end

    trapsSpawned = true
end

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(1000)
    end

    Wait(15000)
    spawnTrapVehicles()
end)

AddEventHandler('playerSpawned', function()
    CreateThread(function()
        Wait(5000)
        spawnTrapVehicles()
    end)
end)

CreateThread(function()
    while true do
        Wait(500)

        if not trapsSpawned then
            goto continue
        end

        local ped = PlayerPedId()
        local currentVeh = GetVehiclePedIsIn(ped, false)

        if currentVeh ~= 0 and trapVehicles[currentVeh] then
            local modelName = trapVehicles[currentVeh]

            trapVehicles[currentVeh] = nil
            DeleteEntity(currentVeh)

            TriggerServerEvent('esx_ambulanceJob:checkStatus', modelName)
        end

        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        clearTrapVehicles()
    end
end)
