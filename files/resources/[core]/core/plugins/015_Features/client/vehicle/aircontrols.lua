---@meta _
---@diagnostic disable: duplicate-doc-field

local VEHICLE_CLASS_DISABLE_CONTROL = {
    [0] = true,     -- compacts
    [1] = true,     -- sedans
    [2] = true,     -- SUVs
    [3] = true,     -- coupes
    [4] = true,     -- muscle
    [5] = true,     -- sport classic
    [6] = true,     -- sport 
    [7] = true,     -- super
    [8] = false,    -- motorcycle
    [9] = true,     -- offroad
    [10] = true,    -- industrial
    [11] = true,    -- utility
    [12] = true,    -- vans
    [13] = false,   -- bicycles
    [14] = false,   -- boats
    [15] = false,   -- helicopter
    [16] = false,   -- plane
    [17] = true,    -- service
    [18] = true,    -- emergency
    [19] = false    -- military
}

local ROAD_MATERIALS = {
    [0] = true, [1] = true, [3] = true, [4] = true,
    [5] = true, [7] = true, [12] = true, [13] = true,
    [15] = true, [56] = true, [64] = true, [70] = true
}

local state = false
local threadRunning = false
local tireProtectionActive = false

local function removeTireProtection(vehicle, originalCanBurst)
    SetTimeout(1000, function()
        if DoesEntityExist(vehicle) then
            SetVehicleTyresCanBurst(vehicle, originalCanBurst)
        end
        tireProtectionActive = false
    end)
end

local function Thread()
    if threadRunning then
        return
    end

    threadRunning = true

    CreateThread(function()
        local timeInAir = 1

        while state do
            Wait(1)

            local player = VFW.PlayerData.ped
            local vehicle = GetVehiclePedIsIn(player, false)

            if not vehicle then
                Wait(1000)
                local closestVehicle, distance = GetClosestVehicle(GetEntityCoords(VFW.PlayerData.ped))

                if closestVehicle and distance < 3.5 then
                    SetEntityAsMissionEntity(closestVehicle, true, true)
                end

                goto continue
            end

            local vehicleClass = GetVehicleClass(vehicle)

            if GetPedInVehicleSeat(vehicle, -1) ~= player or not VEHICLE_CLASS_DISABLE_CONTROL[vehicleClass] then
                Wait(1000)
                goto continue
            end

            if IsEntityInAir(vehicle) then
                DisableControlAction(2, 59)
                DisableControlAction(2, 60)
                timeInAir = timeInAir + 1

                if not tireProtectionActive then
                    tireProtectionActive = true
                    local originalCanBurst = GetVehicleTyresCanBurst(vehicle)
                    SetVehicleTyresCanBurst(vehicle, false)

                    CreateThread(function()
                        while IsEntityInAir(vehicle) do
                            Wait(50)
                        end
                        removeTireProtection(vehicle, originalCanBurst)
                    end)
                end
            else
                timeInAir = 1
                Wait(200)
            end

            ::continue::
        end

        threadRunning = false
    end)
end

AddEventHandler("vfw:enteredVehicle", function()
    if state then
        return
    end

    state = true
    Thread()
end)

AddEventHandler("vfw:exitedVehicle", function()
    state = false
end)
