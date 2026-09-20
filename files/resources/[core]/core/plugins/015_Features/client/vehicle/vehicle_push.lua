local InteractKey = 38 -- E
local EngineHealthThreshold = 200.0
local PushSpeed = 1.5

local function GetTrunkBone(veh)
    local bone = "platelight"
   if GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, bone)) == vector3(0, 0, 0) then
        if tostring(veh) == "826114" or tostring(veh) == "1377794" then
            bone = "door_pside_r"
       elseif GetVehicleClass(veh) == 8 then
            bone = "swingarm"
       elseif GetVehicleClass(veh) == 20 then
            bone = "reversinglight_r"
       elseif GetVehicleClass(veh) == 14 then
            bone = "engine"
       elseif GetVehicleClass(veh) == 16 or GetVehicleClass(veh) == 15 then
            bone = "airbrake_l"
       else
            bone = "boot"
       end
    end
    return bone
end

local pushButtonId = generateUniqueID(8)

VFW.ContextAddButton("vehicle", " Pousser le véhicule", function(veh)
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    -- Ne pas afficher si le joueur est dans le véhicule
    if IsPedInVehicle(ped, veh, false) then
        return false
    end
    return (Entity(veh).state.VehicleProperties) and (#(playerPos - GetEntityCoords(veh)) < 5.0) and GetVehicleDoorLockStatus(veh) < 2
end, function(veh)
    PushVehicle(veh)
end)

function PushVehicle(veh)
    local ped = PlayerPedId()

    NetworkRequestControlOfEntity(veh)
    local timeout = 0
    while not NetworkHasControlOfEntity(veh) and timeout < 2000 do
        Wait(100)
        timeout = timeout + 100
    end

    local dict = "missfinale_c2ig_11"
   RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)

    local minDim, maxDim = GetModelDimensions(GetEntityModel(veh))
    SetEntityCollision(ped, false, false)
    AttachEntityToEntity(ped, veh, -1, 0.0, minDim.y - 0.5, minDim.z + 1.0, 0.0, 0.0, 0.0, false, false, false, false, true)

    TaskPlayAnim(ped, dict, "pushcar_offcliff_m", 2.0, -8.0, -1, 35, 0, 0, 0, 0)

    CreateThread(function()
        instructionalButtons[pushButtonId] = {
            { control = 34, control2 = 35, label = "Diriger" },
            { control = 32, label = "Pousser" },
            { control = 38, label = "Arrêter" },
        }
        local isPushing = true
        local safeTime = GetGameTimer() + 1500 -- Sécurité 1.5s

        while isPushing do
            Wait(0)
            if not IsEntityAttachedToEntity(ped, veh) then
                AttachEntityToEntity(ped, veh, -1, 0.0, minDim.y - 0.5, minDim.z + 1.0, 0.0, 0.0, 0.0, false, false, false, false, true)
                TaskPlayAnim(ped, dict, "pushcar_offcliff_m", 2.0, -8.0, -1, 35, 0, 0, 0, 0)
            end

            local canCancel = GetGameTimer() > safeTime

            if not DoesEntityExist(veh) then
                StopPushing(ped, veh)
                isPushing = false
                break
            end

            if canCancel and IsDisabledControlJustPressed(0, InteractKey) then
                StopPushing(ped, veh)
                isPushing = false
                break
            end

            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 38, true) -- E
            DisableControlAction(0, 32, true) -- Z
            DisableControlAction(0, 8, true) -- S
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Saut

            if IsDisabledControlPressed(0, 32) then
                if IsVehicleSeatFree(veh, -1) then
                    SetVehicleForwardSpeed(veh, PushSpeed)
                end
            else
                SetVehicleForwardSpeed(veh, 0.0)
            end


            -- Direction
            if IsDisabledControlPressed(0, 34) then
                TaskVehicleTempAction(ped, veh, 11, 1000)
                SetVehicleSteeringAngle(veh, 10.0)
            elseif IsDisabledControlPressed(0, 35) then -- Note: 35 pour Droite
                TaskVehicleTempAction(ped, veh, 10, 1000)
                SetVehicleSteeringAngle(veh, -10.0)
            else
                SetVehicleSteeringAngle(veh, 0.0)
            end
        end

        instructionalButtons[pushButtonId] = nil
    end)
end

function StopPushing(ped, veh)
    DetachEntity(ped, false, false)
    StopAnimTask(ped, "missfinale_c2ig_11", "pushcar_offcliff_m", 2.0)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    ClearPedTasks(ped)
end