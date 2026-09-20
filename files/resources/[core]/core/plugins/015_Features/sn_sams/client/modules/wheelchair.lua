-- ============================================================
-- Wheelchair - Client module (server-authoritative)
-- ============================================================
-- The wheelchair IS a streamed `iak_wheelchair` vehicle. The sitter is simply
-- the driver of the vehicle: native vehicle netcode handles sync, and the
-- sitter can drive themselves at a walking pace.
--
-- State is owned by the server and replicated via Entity.state.wheelchair.
-- ============================================================

local WHEELCHAIR_MODEL = `iak_wheelchair`
local LOAD_TIMEOUT     = 5000
local WHEELCHAIR_TOP_SPEED = 2.5 -- m/s, ~9 km/h

-- Local state (this client only)
local isSitting     = false
local currentVeh    = nil
local currentNetId  = nil

-- ============================================================
-- Helpers
-- ============================================================

local function safeLoadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local t = GetGameTimer()
    while not HasModelLoaded(model) do
        if (GetGameTimer() - t) > LOAD_TIMEOUT then return false end
        Wait(10)
    end
    return true
end

local function getWheelchairState(veh)
    if not veh or not DoesEntityExist(veh) then return nil end
    local s = Entity(veh).state
    return s and s.wheelchair or nil
end

local function notifyError(msg)
    VFW.ShowNotification({ type = "ROUGE", content = msg })
end

local function configureVehicle(vehicle)
    SetEntityInvincible(vehicle, true)
    SetEntityCanBeDamaged(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleOutOfControl(vehicle, false, false)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleCanBreak(vehicle, false)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleMaxSpeed(vehicle, WHEELCHAIR_TOP_SPEED)
    SetVehicleGravity(vehicle, true)
    SetEntityCollision(vehicle, true, true)
    SetVehicleDoorsLocked(vehicle, 2) -- no one can enter via F key; context menu only
end

-- ============================================================
-- Sit
-- ============================================================

local function SitLoop(vehicle)
    local ped = PlayerPedId()

    while isSitting and currentVeh == vehicle and GetVehiclePedIsIn(ped, false) == vehicle do
        Wait(100)

        if IsPedDeadOrDying(ped) then break end

        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vous lever")

        if VFW.Interact.JustPressed(0, 38) then -- E: stand up
            break
        end
    end
end

local function doSit(vehicle)
    local ped = PlayerPedId()

    isSitting = true
    currentVeh = vehicle

    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    SitLoop(vehicle)

    -- Cleanup
    local netIdSnapshot = currentNetId
    isSitting = false
    currentVeh = nil
    currentNetId = nil

    if DoesEntityExist(vehicle) and GetVehiclePedIsIn(ped, false) == vehicle then
        TaskLeaveVehicle(ped, vehicle, 16) -- instant exit
    end

    if netIdSnapshot then
        TriggerServerEvent("sn_sams:wheelchair:unsit", netIdSnapshot)
    end
end

local function requestSit(vehicle)
    if isSitting then return end
    if not DoesEntityExist(vehicle) then return end

    local state = getWheelchairState(vehicle)
    if not state then
        notifyError("Ce fauteuil n'est pas encore enregistré.")
        return
    end
    if state.sitter then
        notifyError("Quelqu'un est déjà assis sur ce fauteuil roulant !")
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return end

    currentNetId = netId
    TriggerServerEvent("sn_sams:wheelchair:sit", netId)
end

RegisterNetEvent("sn_sams:wheelchair:sitGranted", function(netId)
    if isSitting then
        TriggerServerEvent("sn_sams:wheelchair:unsit", netId)
        return
    end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then
        currentNetId = nil
        TriggerServerEvent("sn_sams:wheelchair:unsit", netId)
        return
    end
    currentNetId = netId
    doSit(vehicle)
end)

-- ============================================================
-- Spawn (server asks client to create the vehicle)
-- ============================================================
RegisterNetEvent("sn_sams:wheelchair:spawn", function()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        notifyError("Impossible de sortir le fauteuil roulant dans un véhicule !")
        TriggerServerEvent("sn_sams:wheelchair:spawnFailed")
        return
    end

    if isSitting then
        notifyError("Vous utilisez déjà un fauteuil roulant !")
        TriggerServerEvent("sn_sams:wheelchair:spawnFailed")
        return
    end

    if not safeLoadModel(WHEELCHAIR_MODEL) then
        notifyError("Impossible de sortir le fauteuil roulant.")
        TriggerServerEvent("sn_sams:wheelchair:spawnFailed")
        return
    end

    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnPos = coords + forward * 1.5
    local heading = GetEntityHeading(ped)

    local vehicle = VFW.OneSync.CreateVehicleRaw(WHEELCHAIR_MODEL, vector3(spawnPos.x, spawnPos.y, spawnPos.z), heading)
    if not DoesEntityExist(vehicle) then
        TriggerServerEvent("sn_sams:wheelchair:spawnFailed")
        return
    end

    configureVehicle(vehicle)

    -- Wait for network id to propagate
    local t = GetGameTimer()
    while not NetworkGetEntityIsNetworked(vehicle) do
        if (GetGameTimer() - t) > 1500 then
            DeleteVehicle(vehicle)
            TriggerServerEvent("sn_sams:wheelchair:spawnFailed")
            return
        end
        Wait(10)
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, false)

    TriggerServerEvent("sn_sams:wheelchair:register", netId)
    SetModelAsNoLongerNeeded(WHEELCHAIR_MODEL)
end)

-- ============================================================
-- Context menu (on vehicle entity)
-- ============================================================

local function isWheelchair(vehicle)
    return DoesEntityExist(vehicle) and GetEntityModel(vehicle) == WHEELCHAIR_MODEL
end

local function nearby(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) <= 3.0
end

local function canSit(vehicle)
    if not isWheelchair(vehicle) then return false end
    if isSitting then return false end
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, vehicle, false) then return false end
    if not nearby(vehicle) then return false end
    local state = getWheelchairState(vehicle)
    if not state then return false end
    return state.sitter == nil
end

local function canPickup(vehicle)
    if not isWheelchair(vehicle) then return false end
    if isSitting then return false end
    if not nearby(vehicle) then return false end
    local state = getWheelchairState(vehicle)
    if not state then return false end
    return state.sitter == nil
end

local function canStandUp(vehicle)
    if not isWheelchair(vehicle) then return false end
    if not isSitting then return false end
    return currentVeh == vehicle
end

VFW.ContextAddButton("vehicle", ":box: S'asseoir", canSit, function(vehicle)
    requestSit(vehicle)
end)

VFW.ContextAddButton("vehicle", ":user: Se lever", canStandUp, function(_vehicle)
    isSitting = false -- loop exits, doSit cleanup runs
end)

local function playPickupAnim()
    local ped = PlayerPedId()
    RequestAnimDict("pickup_object")
    local t = GetGameTimer()
    while not HasAnimDictLoaded("pickup_object") do
        if (GetGameTimer() - t) > 1000 then return end
        Wait(10)
    end
    TaskPlayAnim(ped, "pickup_object", "pickup_low", 2.0, 2.0, -1, 0, 0, false, false, false)
    Wait(900)
    ClearPedTasks(ped)
    RemoveAnimDict("pickup_object")
end

VFW.ContextAddButton("vehicle", ":box: Ramasser", canPickup, function(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return end
    playPickupAnim()
    TriggerServerEvent("sn_sams:wheelchair:pickup", netId)
end)

-- ============================================================
-- Resource stop safety: release anything we're holding
-- ============================================================
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local ped = PlayerPedId()
    if currentVeh and DoesEntityExist(currentVeh) then
        if GetVehiclePedIsIn(ped, false) == currentVeh then
            TaskLeaveVehicle(ped, currentVeh, 16)
        end
    end
    isSitting = false
    currentVeh = nil
    currentNetId = nil
end)
