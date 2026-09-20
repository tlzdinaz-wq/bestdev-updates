---@meta _
---@diagnostic disable: duplicate-doc-field

local VehicleFuel = {}

local currentVehicle = nil
local isConsuming = false
local isStopFuel = false
local fuelTick = 0
local SYNC_INTERVAL = 5
local trackedFuel = 0.0 -- authoritative fuel level for current vehicle (avoids GTA native resets)

local EXCLUDED_CLASSES = {
    [13] = true,
    [14] = true,
    [15] = true,
    [16] = true,
}

local EXCLUDED_MODELS = {
    [`iak_wheelchair`] = true,
}

function VehicleFuel.Get(vehicle)
    if not DoesEntityExist(vehicle) then return 0.0 end
    if vehicle == currentVehicle and isConsuming then
        return trackedFuel + 0.0
    end
    local vehState = Entity(vehicle).state
    local fuel = vehState.fuel or GetVehicleFuelLevel(vehicle)
    return (fuel or 0.0) + 0.0
end

function VehicleFuel.Set(vehicle, amount, sync)
    if not DoesEntityExist(vehicle) then return 0.0 end

    amount = math.max(0.0, math.min(100.0, (amount or 0.0) + 0.0))
    SetVehicleFuelLevel(vehicle, amount)

    if sync then
        Entity(vehicle).state:set("fuel", amount, true)
    end

    return amount
end

function VehicleFuel.AddLiters(vehicle, liters, sync)
    if not DoesEntityExist(vehicle) then return 0.0 end

    liters = (liters or 0) + 0.0
    local tankCapacity = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")
    local currentPercent = VehicleFuel.Get(vehicle) + 0.0
    local currentLiters = (currentPercent / 100.0) * tankCapacity
    local newLiters = math.min(currentLiters + liters, tankCapacity)
    local newPercent = (newLiters / tankCapacity) * 100.0

    return VehicleFuel.Set(vehicle, newPercent, sync)
end

function VehicleFuel.GetLiters(vehicle)
    if not DoesEntityExist(vehicle) then return 0.0, 0.0 end

    local tankCapacity = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")
    local percent = VehicleFuel.Get(vehicle)
    local liters = (percent / 100.0) * tankCapacity

    return liters, tankCapacity
end

local function GetRpmConsumption(rpm)
    local roundedRpm = math.floor(rpm * 10.0 + 0.5) / 10.0
    return Fuel.FuelUsage[roundedRpm] or Fuel.FuelUsage[0.1] or 0.05
end

local function CalculateConsumption(vehicle)
    local rpm = GetVehicleCurrentRpm(vehicle)
    local vehClass = GetVehicleClass(vehicle)
    local baseConsumption = GetRpmConsumption(rpm)
    local classMultiplier = Fuel.Classes[vehClass] or 1.0
    local consumption = baseConsumption * classMultiplier / 20.0

    if Entity(vehicle).state.interim_job == "routier" then
        consumption = consumption / 4.0
    end

    return consumption
end

local function InitializeVehicleFuel(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local vehState = Entity(vehicle).state
    local fuel = vehState.fuel

    if fuel == nil then
        -- Pas de state bag: lire le native GTA (preservee entre sessions)
        fuel = GetVehicleFuelLevel(vehicle)
        if fuel <= 0.0 then fuel = 100.0 end -- Nouveau vehicule seulement
        vehState:set("fuel", fuel + 0.0, true)
    end

    trackedFuel = fuel + 0.0
    SetVehicleFuelLevel(vehicle, trackedFuel)
end

local function StopConsuming()
    if not isConsuming then return end -- guard double-call

    local lastFuel = trackedFuel
    local lastVehicle = currentVehicle

    isConsuming = false
    currentVehicle = nil
    fuelTick = 0
    trackedFuel = 0.0

    -- Sync APRES avoir clear l'etat pour eviter les race conditions
    if lastVehicle and DoesEntityExist(lastVehicle) and lastFuel > 0.0 then
        Entity(lastVehicle).state:set("fuel", lastFuel, true)
    end
end

local function ConsumptionThread(vehicle)
    CreateThread(function()
        fuelTick = 0
        local savedFuel = trackedFuel -- Sauvegarder en cas de streaming out

        while isConsuming and currentVehicle == vehicle do
            Wait(1000)

            -- Entity disappeared (streaming) — wait up to 5s for recovery
            if not DoesEntityExist(vehicle) then
                local recovered = false
                for _ = 1, 10 do
                    Wait(500)
                    if DoesEntityExist(vehicle) then
                        recovered = true
                        break
                    end
                end
                if not recovered then
                    -- Le joueur est peut-etre toujours dans le vehicule
                    -- Verifier via le ped
                    local currentVeh = GetVehiclePedIsIn(PlayerPedId(), false)
                    if currentVeh ~= 0 then
                        -- Toujours en vehicule, le handle a peut-etre change
                        vehicle = currentVeh
                        currentVehicle = vehicle
                        -- Restaurer le fuel sur le nouveau handle
                        SetVehicleFuelLevel(vehicle, savedFuel)
                        Entity(vehicle).state:set("fuel", savedFuel, true)
                    else
                        StopConsuming()
                        return
                    end
                end
            end

            -- Verifier qu'on est toujours le conducteur
            local currentVeh = GetVehiclePedIsIn(PlayerPedId(), false)
            if currentVeh == 0 then
                StopConsuming()
                return
            end
            -- Handle peut changer apres streaming, mettre a jour
            if currentVeh ~= vehicle then
                vehicle = currentVeh
                currentVehicle = vehicle
            end

            if GetIsVehicleEngineRunning(vehicle) then
                if trackedFuel > 0.0 then
                    local consumption = CalculateConsumption(vehicle)
                    trackedFuel = math.max(0.0, trackedFuel - consumption)
                    savedFuel = trackedFuel
                    SetVehicleFuelLevel(vehicle, trackedFuel)

                    fuelTick = fuelTick + 1
                    if fuelTick >= SYNC_INTERVAL then
                        Entity(vehicle).state:set("fuel", trackedFuel, true)
                        fuelTick = 0
                    end
                else
                    SetVehicleEngineOn(vehicle, false, true, true)
                    VehicleFuel.Set(vehicle, 0.0, true)
                    trackedFuel = 0.0
                    savedFuel = 0.0
                end
            end
        end
    end)
end

AddEventHandler("vfw:enteredVehicle", function(vehicle, _, seat)
    if isStopFuel then return end
    if seat ~= -1 then return end

    local vehClass = GetVehicleClass(vehicle)
    if EXCLUDED_CLASSES[vehClass] then return end
    if EXCLUDED_MODELS[GetEntityModel(vehicle)] then return end

    -- Meme vehicule: ne pas re-initialiser (streaming recovery)
    if currentVehicle == vehicle and isConsuming then return end

    -- Clean up l'ancien vehicule
    if isConsuming then
        StopConsuming()
    end

    InitializeVehicleFuel(vehicle)

    isConsuming = true
    currentVehicle = vehicle
    ConsumptionThread(vehicle)
end)

AddEventHandler("vfw:exitedVehicle", function()
    StopConsuming()
end)

AddStateBagChangeHandler("fuel", nil, function(bagName, _, value)
    if not bagName:find("entity:") then return end
    if value == nil then return end

    local netId = tonumber(bagName:match("entity:(%d+)"))
    if not netId then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    if currentVehicle == vehicle and isConsuming then return end

    SetVehicleFuelLevel(vehicle, math.max(0.0, math.min(100.0, value + 0.0)))
end)

RegisterNetEvent("fl_gasstation:fuelUpdatedExternally", function(vehicleNetId, newFuelPercent)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if vehicle and DoesEntityExist(vehicle) then
        if currentVehicle == vehicle then
            trackedFuel = newFuelPercent + 0.0
            VehicleFuel.Set(vehicle, newFuelPercent, false)
        end
    end
end)

function SetFuelStopped(stopped)
    isStopFuel = stopped
end

exports("SetFuelStopped", SetFuelStopped)
exports("GetVehicleFuel", VehicleFuel.Get)
exports("SetVehicleFuel", VehicleFuel.Set)
exports("AddVehicleFuelLiters", VehicleFuel.AddLiters)
exports("GetVehicleFuelLiters", VehicleFuel.GetLiters)

_G.VehicleFuel = VehicleFuel

local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(1) end
    end
end

RegisterNuiCallback("nui:menu-ltd:close", function()
    VFW.Nui.FuelMenu(false)
end)

RegisterNuiCallback("nui:menu-ltd:submit", function(data)
    if not data then return end

    local getMoney = TriggerServerCallback("core:server:getFuelMoney", data.payment, data.volume)

    if data.action == "plein" or data.action == "manuel" then
        if getMoney then
            VFW.Nui.FuelMenu(false)
            StartFueling()
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas assez d'argent"
            })
        end
    elseif data.action == "bidon" then
        if getMoney then
            TriggerServerEvent("vfw:addPetrolCan")
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas assez d'argent"
            })
        end
    end
end)

local jerrycanProcessActive = false
local TIME_PER_LITER = 10

local petrolCanHash = joaat("weapon_petrolcan")
local jerrycanMaxFuel = 20
local lastKnownFuel = 0

local function JerrycanCancelProgress()
    SendNUIMessage({ action = "nui:progress:cancel" })
end

local function JerrycanStartFueling(vehicle, jerrycanFuel, slot)
    if jerrycanProcessActive then return end

    if not NetworkGetEntityIsNetworked(vehicle) then
        VFW.ShowNotification({type = 'ROUGE', content = "Le véhicule n'est pas synchronisé sur le réseau"})
        return
    end

    local currentLiters, tankCapacity = VehicleFuel.GetLiters(vehicle)
    local fuelNeeded = tankCapacity - currentLiters
    local fuelToTransfer = math.min(jerrycanFuel, fuelNeeded)

    if fuelToTransfer <= 0 then
        VFW.ShowNotification({type = 'JAUNE', content = "Impossible de transférer l'essence"})
        return
    end

    local animDict = "weapon@w_sp_jerrycan"
    local animName = "fire"
    LoadAnimDict(animDict)

    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    local canFuel, errorMsg = TriggerServerCallback("fl_gasstation:canFuelVehicle", vehicleNetId)
    if not canFuel then
        VFW.ShowNotification({type = 'ROUGE', content = errorMsg or "Impossible de remplir ce véhicule"})
        return
    end

    TriggerServerEvent("fl_gasstation:startFuelingVehicle", vehicleNetId)
    jerrycanProcessActive = true

    local remainingFuel = jerrycanFuel - fuelToTransfer
    local totalDuration = fuelToTransfer * TIME_PER_LITER * 1000

    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 50, 0, false, false, false)

    -- Thread parallele: controles + cancel + refresh anim
    CreateThread(function()
        while jerrycanProcessActive do
            Wait(0)
            local ped = PlayerPedId()

            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 24, true)   -- Attack
            DisableControlAction(0, 25, true)   -- Aim
            DisableControlAction(0, 45, true)   -- Reload
            DisableControlAction(0, 47, true)   -- Detonate
            DisableControlAction(0, 58, true)   -- Throw grenade
            DisableControlAction(0, 140, true)  -- Melee light
            DisableControlAction(0, 141, true)  -- Melee heavy
            DisableControlAction(0, 142, true)  -- Melee alternate
            DisableControlAction(0, 143, true)  -- Melee block
            DisableControlAction(0, 257, true)  -- Attack 2
            DisableControlAction(0, 263, true)  -- Melee attack 1
            DisableControlAction(0, 264, true)  -- Melee attack 2
            DisableControlAction(0, 37, true)   -- Select weapon
            DisableControlAction(0, 23, true)   -- Enter vehicle
            DisableControlAction(0, 44, true)   -- Cover
            DisableControlAction(0, 73, true)   -- X cancel
            DisablePlayerFiring(PlayerId(), true)

            if IsDisabledControlJustPressed(0, 73) then
                JerrycanCancelProgress()
            end

            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                JerrycanCancelProgress()
            end

            if not IsEntityPlayingAnim(ped, animDict, animName, 3) and jerrycanProcessActive then
                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 50, 0, false, false, false)
            end
        end
    end)

    local startTime = GetGameTimer()
    local completed = VFW.Nui.ProgressBar(
        string.format("Remplissage (+%.1fL)", fuelToTransfer),
        totalDuration,
        false,
        true
    )

    -- Cleanup
    jerrycanProcessActive = false
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    if completed then
        VehicleFuel.AddLiters(vehicle, fuelToTransfer, true)
        TriggerServerEvent("fl_gasstation:syncVehicleFuel", vehicleNetId, VehicleFuel.Get(vehicle))
        TriggerServerEvent("vfw:updateJerrycanFuel", slot, remainingFuel)
        TriggerServerEvent("fl_gasstation:fuelingComplete", vehicleNetId)
        VFW.ShowNotification({
            type = 'VERT',
            content = string.format("Remplissage terminé ! +%.1fL d'essence", fuelToTransfer)
        })
    else
        local elapsed = GetGameTimer() - startTime
        local progress = math.min((elapsed / totalDuration) * 100.0, 100.0)
        local litersTransferred = (progress / 100.0) * fuelToTransfer
        local newJerrycanFuel = (remainingFuel + fuelToTransfer) - litersTransferred

        if litersTransferred > 0.1 then
            VehicleFuel.AddLiters(vehicle, litersTransferred, true)
            TriggerServerEvent("fl_gasstation:syncVehicleFuel", vehicleNetId, VehicleFuel.Get(vehicle))
            VFW.ShowNotification({
                type = 'JAUNE',
                content = string.format("Remplissage arrêté. %.1fL ajoutés.", litersTransferred)
            })
        else
            VFW.ShowNotification({type = 'ROUGE', content = "Remplissage arrêté"})
        end

        TriggerServerEvent("vfw:updateJerrycanFuel", slot, math.max(0, newJerrycanFuel))
        TriggerServerEvent("fl_gasstation:fuelingCancelled", vehicleNetId)
    end
end

RegisterNetEvent("vfw:usePetrolCan", function()
    CreateThread(function()
        Wait(100)
        local jerrycanData = TriggerServerCallback("vfw:getJerrycanFuel")
        if not jerrycanData then return end

        lastKnownFuel = jerrycanData.fuel or 0
        jerrycanMaxFuel = jerrycanData.maxFuel or 20

        local playerPed = PlayerPedId()
        if HasPedGotWeapon(playerPed, petrolCanHash, false) then
            local ammo = math.floor(lastKnownFuel * 100)
            if ammo < 1 then ammo = 1 end
            SetPedAmmo(playerPed, petrolCanHash, ammo)
        end
    end)
end)

CreateThread(function()
    local wasHolding = false
    local wasPouring = false
    local jerrycanSlotCache = nil
    local lastNuiUpdate = 0
    local lastFuelSent = -1

    while true do
        local playerPed = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(playerPed)

        if currentWeapon == petrolCanHash then
            if not wasHolding then
                wasHolding = true
                local jerrycanData = TriggerServerCallback("vfw:getJerrycanFuel")
                if jerrycanData then
                    lastKnownFuel = jerrycanData.fuel or 0
                    jerrycanMaxFuel = jerrycanData.maxFuel or 20
                    jerrycanSlotCache = jerrycanData.slot
                    local ammo = math.floor(lastKnownFuel * 100)
                    if ammo < 1 then ammo = 1 end
                    SetPedAmmo(playerPed, petrolCanHash, ammo)
                end
                lastFuelSent = -1
            end

            local ammo = GetAmmoInPedWeapon(playerPed, petrolCanHash)
            lastKnownFuel = ammo / 100.0

            if not jerrycanProcessActive then
                local isPouring = IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24)

                if wasPouring and lastKnownFuel <= 0.01 then
                    TriggerServerEvent("vfw:jerrycanPourStop", 0)
                    wasPouring = false
                elseif isPouring and not wasPouring then
                    TriggerServerEvent("vfw:jerrycanPourStart")
                    wasPouring = true
                elseif wasPouring and not isPouring then
                    TriggerServerEvent("vfw:jerrycanPourStop", lastKnownFuel)
                    wasPouring = false
                end
            elseif wasPouring then
                TriggerServerEvent("vfw:jerrycanPourStop", lastKnownFuel)
                wasPouring = false
            end

            if not jerrycanProcessActive and lastKnownFuel > 0 and jerrycanSlotCache then
                local playerCoords = GetEntityCoords(playerPed)
                local closestVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 3.0, 0, 71)

                if closestVehicle and closestVehicle ~= 0 and DoesEntityExist(closestVehicle) and not IsPedInAnyVehicle(playerPed, false) then
                    local currentLiters, tankCapacity = VehicleFuel.GetLiters(closestVehicle)
                    local fuelNeeded = tankCapacity - currentLiters

                    if fuelNeeded > 0.5 then
                        local fuelToTransfer = math.min(lastKnownFuel, fuelNeeded)
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour remplir le véhicule (~b~+" .. string.format("%.1f", fuelToTransfer) .. "L~w~)")

                        if VFW.Interact.JustPressed(0, 38) then
                            JerrycanStartFueling(closestVehicle, lastKnownFuel, jerrycanSlotCache)
                        end
                    else
                        VFW.ShowHelpNotification("Le réservoir est ~g~plein")
                    end
                end
            end

            local currentTime = GetGameTimer()
            local roundedFuel = math.floor(lastKnownFuel * 10)
            if currentTime - lastNuiUpdate >= 200 or roundedFuel ~= lastFuelSent then
                SendNUIMessage({
                    action = 'nui:jerrycan:status',
                    data = { visible = true, fuel = lastKnownFuel, maxFuel = jerrycanMaxFuel }
                })
                lastNuiUpdate = currentTime
                lastFuelSent = roundedFuel
            end

            Wait(50)
        else
            if wasHolding then
                if wasPouring then
                    TriggerServerEvent("vfw:jerrycanPourStop", lastKnownFuel)
                end
                wasHolding = false
                wasPouring = false
                jerrycanSlotCache = nil
                SendNUIMessage({
                    action = 'nui:jerrycan:status',
                    data = { visible = false, fuel = 0, maxFuel = jerrycanMaxFuel }
                })
            end

            Wait(500)
        end
    end
end)

RegisterNetEvent("vfw:setJerrycanAmmo", function(fuel)
    if fuel == nil then return end
    lastKnownFuel = fuel

    local playerPed = PlayerPedId()
    if HasPedGotWeapon(playerPed, petrolCanHash, false) then
        local ammo = math.floor(lastKnownFuel * 100)
        if ammo < 1 then ammo = 1 end
        SetPedAmmo(playerPed, petrolCanHash, ammo)
    end
end)

RegisterNetEvent("vfw:jerrycanEmpty", function()
    local playerPed = PlayerPedId()
    if HasPedGotWeapon(playerPed, petrolCanHash, false) then
        RemoveWeaponFromPed(playerPed, petrolCanHash)
    end
    lastKnownFuel = 0
    SendNUIMessage({
        action = 'nui:jerrycan:status',
        data = { visible = false, fuel = 0, maxFuel = jerrycanMaxFuel }
    })
    VFW.ShowNotification({
        type = 'JAUNE',
        content = "Le jerrycan est vide et a été retiré de votre inventaire."
    })
end)

