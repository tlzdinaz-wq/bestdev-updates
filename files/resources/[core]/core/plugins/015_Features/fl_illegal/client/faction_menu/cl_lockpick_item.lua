-- ============================================
-- LOCKPICK ITEM - CLIENT SIDE
-- Use of "kit_de_crochetage_veh" via inventory
-- ============================================

local ANIM_DICT = 'missheistfbisetup1'
local ANIM_NAME = 'hassle_intro_loop_f'
local SEARCH_RADIUS = 4.0

local isBusy = false

local function GetClosestVehicle(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = nil
    local closestDistance = maxDistance

    local forwardVector = GetEntityForwardVector(playerPed)
    local startCoords = playerCoords + vector3(0, 0, 0.5)
    local endCoords = startCoords + (forwardVector * maxDistance)

    local rayHandle = StartShapeTestRay(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, 10, playerPed, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit and entityHit and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) then
        closestVehicle = entityHit
        closestDistance = #(playerCoords - GetEntityCoords(entityHit))
    end

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(veh) and not IsPedInVehicle(playerPed, veh, false) then
            local distance = #(playerCoords - GetEntityCoords(veh))
            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = veh
            end
        end
    end

    return closestVehicle
end

local function VehicleIsEmpty(vehicle)
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for i = -1, seats - 2 do
        if not IsVehicleSeatFree(vehicle, i) then
            return false
        end
    end
    return true
end

local function CleanupAnim(playerPed)
    SetNuiFocus(false, false)
    if playerPed and DoesEntityExist(playerPed) then
        pcall(StopAnimTask, playerPed, ANIM_DICT, ANIM_NAME, 1.0)
        ClearPedSecondaryTask(playerPed)
        ClearPedTasks(playerPed)
        if IsEntityPlayingAnim(playerPed, ANIM_DICT, ANIM_NAME, 3) then
            ClearPedTasksImmediately(playerPed)
        end
    end
    RemoveAnimDict(ANIM_DICT)
end

local function PlayerCanContinue(playerPed, vehicle)
    if not playerPed or not DoesEntityExist(playerPed) then return false end
    if IsEntityDead(playerPed) then return false end
    if IsPedInAnyVehicle(playerPed, false) then return false end
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    return true
end

RegisterNetEvent("vfw:lockpickItem:start", function()
    if isBusy then return end

    if VFW.CloseInventory then VFW.CloseInventory() end

    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous ne pouvez pas faire cela en véhicule." })
        return
    end

    local vehicle = GetClosestVehicle(SEARCH_RADIUS)
    if not vehicle or not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule à proximité." })
        return
    end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 0 or lockStatus == 1 then
        VFW.ShowNotification({ type = 'JAUNE', content = "Le véhicule est déjà déverrouillé." })
        return
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Ce véhicule n'est pas synchronisé." })
        return
    end

    if not VehicleIsEmpty(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Il y a quelqu'un dans le véhicule." })
        return
    end

    if not TriggerServerCallback("vfw:lockpickItem:hasItem") then
        VFW.ShowNotification({ type = 'ROUGE', content = "Vous n'avez pas de kit de crochetage véhicules." })
        return
    end

    isBusy = true
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local aborted = false

    TaskTurnPedToFaceEntity(playerPed, vehicle, 1000)
    Wait(800)

    RequestAnimDict(ANIM_DICT)
    local timeout = 0
    while not HasAnimDictLoaded(ANIM_DICT) and timeout < 50 do
        Wait(20)
        timeout = timeout + 1
    end
    TaskPlayAnim(playerPed, ANIM_DICT, ANIM_NAME, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Watchdog: abort if player dies, enters a vehicle, or target disappears
    CreateThread(function()
        while isBusy and not aborted do
            if not PlayerCanContinue(playerPed, vehicle) then
                aborted = true
                pcall(function() exports['s_lockpick']:cancel() end)
                break
            end
            Wait(500)
        end
    end)

    local success = exports['s_lockpick']:startLockpick()
    local cancelled = exports['s_lockpick']:wasCancelled() or aborted

    CleanupAnim(playerPed)

    if cancelled then
        VFW.ShowNotification({ type = 'JAUNE', content = "Crochetage annulé." })
        isBusy = false
        return
    end

    NetworkRequestControlOfEntity(vehicle)
    local controlTimeout = 0
    while not NetworkHasControlOfEntity(vehicle) and controlTimeout < 50 do
        Wait(10)
        controlTimeout = controlTimeout + 1
    end

    if success then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        VFW.ShowNotification({ type = 'VERT', content = "Véhicule crocheté." })
        TriggerServerEvent("vfw:lockpickItem:result", "success", netId)
    else
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 4000)
        SetVehicleDoorsLocked(vehicle, 2)
        VFW.ShowNotification({ type = 'ROUGE', content = "Crochetage raté, l'alarme s'est déclenchée." })
        TriggerServerEvent("vfw:lockpickItem:result", "fail", netId)
    end

    isBusy = false
end)

AddEventHandler("onResourceStop", function(resName)
    if resName == GetCurrentResourceName() and isBusy then
        CleanupAnim(PlayerPedId())
        isBusy = false
    end
end)

RegisterCommand("cancellockpick", function()
    pcall(function() exports['s_lockpick']:cancel() end)
    CleanupAnim(PlayerPedId())
    isBusy = false
    VFW.ShowNotification({ type = 'JAUNE', content = "Crochetage forcé à se terminer." })
end, false)
