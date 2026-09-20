---@meta _
---@diagnostic disable: duplicate-doc-field

local Cfg = SN_SAMS.Config.Stretcher
local LOAD_TIMEOUT = 5000
local DEFAULT_PATIENT_OFFSET = { x = 0.0, y = -1.3, z = 1.3, rx = 0.0, ry = 0.0, rz = 180.0 }

-- ============================================================
-- Multi-model support
-- ============================================================
local stretcherModelSet = {}
for _, hash in ipairs(Cfg.modelHashes) do
    stretcherModelSet[GetHashKey(hash)] = true
end
local defaultStretcherModel = Cfg.modelHashes[1]

-- Pre-built hash map for ambulance configs (avoids per-frame GetHashKey calls)
local ambulanceHashMap = {}
for _, config in ipairs(Cfg.Vehicles) do
    ambulanceHashMap[GetHashKey(config.modelHash)] = config
end

---@param vehicle number
---@return boolean
local function IsStretcherModel(vehicle)
    return stretcherModelSet[GetEntityModel(vehicle)] == true
end

---@param coords vector3
---@param maxDist number
---@return number|nil
local function GetClosestStretcher(coords, maxDist)
    local closest = nil
    local closestDist = maxDist
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(v) and IsStretcherModel(v) then
            local dist = #(coords - GetEntityCoords(v))
            if dist < closestDist then
                closestDist = dist
                closest = v
            end
        end
    end
    return closest
end

-- ============================================================
-- State
-- ============================================================
local stretchers = {}
local PreventTakingStretcherWhileSeated = false
local getUpCooldown = 0
local patientState = nil

-- ============================================================
-- Helpers: async loaders with timeout
-- ============================================================

---@param dict string
---@return boolean
local function safeLoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if (GetGameTimer() - t) > LOAD_TIMEOUT then return false end
        Wait(5)
    end
    return true
end

---@param model string|number
---@return boolean
local function safeLoadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local t = GetGameTimer()
    while not HasModelLoaded(model) do
        if (GetGameTimer() - t) > LOAD_TIMEOUT then return false end
        Wait(5)
    end
    return true
end

---@param message string
local function Notify(message)
    VFW.ShowNotification({
        type = "JOB",
        logo = SN_SAMS.Logo,
        title = "SAMS",
        subtitle = "Brancard",
        content = message,
    })
end

-- ============================================================
-- Net ID helpers
-- ============================================================

local function GetVehicleNetId(vehicle)
    return VehToNet(vehicle)
end

local function GetVehicleFromNetId(netId)
    return NetToVeh(netId)
end

-- ============================================================
-- State sync (server <-> client)
-- ============================================================

local function AddStretcherId(netId)
    TriggerServerEvent('sn_sams:stretcher:add', netId)
end

local function SetMovingState(netId, bool)
    TriggerServerEvent('sn_sams:stretcher:setMoving', netId, bool)
end

local function SetSittingState(netId, bool)
    TriggerServerEvent('sn_sams:stretcher:setSitting', netId, bool)
end

local function RemoveStretcherId(netId)
    TriggerServerEvent('sn_sams:stretcher:remove', netId)
end

local function CheckMovingState(netId)
    return stretchers[netId] and stretchers[netId].moving
end

local function CheckSittingState(netId)
    return stretchers[netId] and stretchers[netId].sitting
end

-- ============================================================
-- State sync events
-- ============================================================

RegisterNetEvent('sn_sams:stretcher:syncAll', function(updatedStretchers)
    stretchers = updatedStretchers
end)

RegisterNetEvent('sn_sams:stretcher:syncMoving', function(netId, bool)
    if stretchers[netId] then
        stretchers[netId].moving = bool
    else
        stretchers[netId] = { moving = bool }
    end
end)

RegisterNetEvent('sn_sams:stretcher:syncSitting', function(netId, bool)
    if stretchers[netId] then
        stretchers[netId].sitting = bool
    else
        stretchers[netId] = { sitting = bool }
    end
end)

RegisterNetEvent('sn_sams:stretcher:syncRemove', function(netId)
    if stretchers[netId] then
        stretchers[netId] = nil
    end
end)

RegisterNetEvent('sn_sams:stretcher:onPatientToVehicle', function(vehicleNetId, patientOffset)
    local po = patientOffset or DEFAULT_PATIENT_OFFSET
    patientState = { kind = "vehicle", netId = vehicleNetId, offset = po }
    PreventTakingStretcherWhileSeated = true

    local vehicle = GetVehicleFromNetId(vehicleNetId)
    local t = GetGameTimer()
    while (not vehicle or vehicle == 0 or not DoesEntityExist(vehicle)) and (GetGameTimer() - t) < 5000 do
        Wait(50)
        vehicle = GetVehicleFromNetId(vehicleNetId)
    end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local ped = PlayerPedId()
    DetachEntity(ped, true, true)
    ClearPedTasksImmediately(ped)

    local bone = GetEntityBoneIndexByName(vehicle, "chassis_dummy")
    if bone == -1 then bone = GetEntityBoneIndexByName(vehicle, "chassis") end
    if bone == -1 then bone = 0 end

    AttachEntityToEntity(ped, vehicle, bone, po.x, po.y, po.z, po.rx, po.ry, po.rz, false, false, false, false, 2, true)
    safeLoadAnimDict("savecouch@")
    TaskPlayAnim(ped, "savecouch@", "t_sleep_loop_couch", 8.0, -8.0, -1, 1, 0, false, false, false)
end)

RegisterNetEvent('sn_sams:stretcher:onPatientToStretcher', function(stretcherNetId)
    local offsetInfo = {0, 0.0, 0.2, 1.1, 0.0, 0.0, 180.0, false, false, false, false, 2, true}
    patientState = {
        kind = "stretcher",
        netId = stretcherNetId,
        dict = "savecouch@",
        anim = "t_sleep_loop_couch",
        offset = offsetInfo,
    }
    PreventTakingStretcherWhileSeated = true

    local stretcher = GetVehicleFromNetId(stretcherNetId)
    local t = GetGameTimer()
    while (not stretcher or stretcher == 0 or not DoesEntityExist(stretcher)) and (GetGameTimer() - t) < 5000 do
        Wait(50)
        stretcher = GetVehicleFromNetId(stretcherNetId)
    end
    if not stretcher or stretcher == 0 or not DoesEntityExist(stretcher) then return end

    local ped = PlayerPedId()
    DetachEntity(ped, true, true)
    ClearPedTasksImmediately(ped)
    AttachEntityToEntity(ped, stretcher, offsetInfo[1], offsetInfo[2], offsetInfo[3], offsetInfo[4], offsetInfo[5], offsetInfo[6], offsetInfo[7], offsetInfo[8], offsetInfo[9], offsetInfo[10], offsetInfo[11], offsetInfo[12], offsetInfo[13])
    safeLoadAnimDict("savecouch@")
    TaskPlayAnim(ped, "savecouch@", "t_sleep_loop_couch", 8.0, -8.0, -1, 1, 0, false, false, false)
end)

RegisterNetEvent('sn_sams:stretcher:cleanup', function()
    patientState = nil
    PreventTakingStretcherWhileSeated = false
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if IsStretcherModel(v) then
            SetEntityAsMissionEntity(v, true, true)
            DeleteVehicle(v)
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
    end
end)

-- ============================================================
-- Vehicle extra sync (broadcast from server to all clients)
-- ============================================================

local vehicleExtraCache = {} -- vehicleExtraCache[vehicleNetId] = { [extraIndex] = state }

RegisterNetEvent('sn_sams:stretcher:syncVehicleExtra', function(vehicleNetId, extraIndex, state)
    -- Update local cache
    if not vehicleExtraCache[vehicleNetId] then
        vehicleExtraCache[vehicleNetId] = {}
    end
    vehicleExtraCache[vehicleNetId][extraIndex] = state

    local vehicle = GetVehicleFromNetId(vehicleNetId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleExtra(vehicle, extraIndex, state)
    end
end)

-- Bulk sync on connect
RegisterNetEvent('sn_sams:stretcher:syncAllExtras', function(allExtras)
    vehicleExtraCache = allExtras or {}
    for netId, extras in pairs(vehicleExtraCache) do
        local vehicle = GetVehicleFromNetId(netId)
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            for extraIndex, state in pairs(extras) do
                SetVehicleExtra(vehicle, extraIndex, state)
            end
        end
    end
end)

---@param vehicle number
---@param extraIndex number
---@param state boolean  -- true = OFF, false = ON (GTA convention)
local function SyncVehicleExtra(vehicle, extraIndex, state)
    SetVehicleExtra(vehicle, extraIndex, state)
    TriggerServerEvent('sn_sams:stretcher:setVehicleExtra', GetVehicleNetId(vehicle), extraIndex, state)
end

-- Reapply cached extras when vehicles stream in
CreateThread(function()
    while true do
        Wait(2000)
        for netId, extras in pairs(vehicleExtraCache) do
            local vehicle = GetVehicleFromNetId(netId)
            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                for extraIndex, state in pairs(extras) do
                    SetVehicleExtra(vehicle, extraIndex, state)
                end
            end
        end
    end
end)

-- ============================================================
-- Vehicle door sync event
-- ============================================================

RegisterNetEvent('sn_sams:stretcher:syncDoors', function(netId, fld, frd, bld, brd, hood, trunk, rld, rrd)
    local doors = {fld, frd, bld, brd, hood, trunk, rld, rrd}
    local doorIndices = {0, 1, 2, 3, 4, 5, 6, 7}
    local vehicle = GetVehicleFromNetId(netId)

    if not vehicle then return end

    local openCount = 0
    local closedCount = 0

    for i, isOpen in ipairs(doors) do
        if isOpen then
            local doorIndex = doorIndices[i]
            local doorState = GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0
            if doorState then
                openCount = openCount + 1
            else
                closedCount = closedCount + 1
            end
        end
    end

    for i, isOpen in ipairs(doors) do
        if isOpen then
            local doorIndex = doorIndices[i]
            if closedCount >= openCount then
                SetVehicleDoorOpen(vehicle, doorIndex, false, false)
            else
                SetVehicleDoorShut(vehicle, doorIndex, false)
            end
        end
    end
end)

-- ============================================================
-- UTIL: Vehicle helpers
-- ============================================================

local function GetClosestVehicleFromPedPos(ped, maxDistance, maxHeight, canReturnVehicleInside, configTable)
    local veh = nil
    local smallestDistance = maxDistance
    local matchingConfig = nil

    for _, v in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(v) and (canReturnVehicleInside or not IsPedInVehicle(ped, v, false)) then
            local distance = #(GetEntityCoords(ped) - GetEntityCoords(v))
            local height = math.abs(GetEntityHeightAboveGround(v))
            if distance <= smallestDistance and height <= maxHeight and height >= 0 and IsVehicleDriveable(v, false) then
                local vehicleModel = GetEntityModel(v)
                for _, config in ipairs(configTable) do
                    if GetHashKey(config.modelHash) == vehicleModel then
                        smallestDistance = distance
                        veh = v
                        matchingConfig = config
                        break
                    end
                end
            end
        end
    end
    return veh, matchingConfig
end

-- ============================================================
-- UTIL: Animation
-- ============================================================

local function PlayAnimation(player, dict, anim, offsetInfo)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local stretcherObject = GetClosestStretcher(playerCoords, 3.0)
    if not stretcherObject then return end

    if CheckSittingState(GetVehicleNetId(stretcherObject)) and not IsEntityAttachedToEntity(stretcherObject, PlayerPedId()) then
        Notify("~y~Quelqu'un est déjà sur ce brancard.")
        return
    end

    AttachEntityToEntity(player, stretcherObject, offsetInfo[1], offsetInfo[2], offsetInfo[3], offsetInfo[4], offsetInfo[5], offsetInfo[6], offsetInfo[7], offsetInfo[8], offsetInfo[9], offsetInfo[10], offsetInfo[11], offsetInfo[12], offsetInfo[13])
    safeLoadAnimDict(dict)
    TaskPlayAnim(player, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    PreventTakingStretcherWhileSeated = true
    SetSittingState(GetVehicleNetId(stretcherObject), true)
    patientState = {
        kind = "stretcher",
        netId = GetVehicleNetId(stretcherObject),
        dict = dict,
        anim = anim,
        offset = offsetInfo,
    }
end

CreateThread(function()
    while true do
        Wait(400)
        if patientState then
            local ped = PlayerPedId()
            if patientState.kind == "stretcher" then
                local stretcher = GetVehicleFromNetId(patientState.netId)
                if stretcher and stretcher ~= 0 and DoesEntityExist(stretcher) then
                    if not IsEntityAttachedToEntity(ped, stretcher) then
                        local off = patientState.offset
                        AttachEntityToEntity(ped, stretcher, off[1], off[2], off[3], off[4], off[5], off[6], off[7], off[8], off[9], off[10], off[11], off[12], off[13])
                        if not IsEntityPlayingAnim(ped, patientState.dict, patientState.anim, 3) then
                            safeLoadAnimDict(patientState.dict)
                            TaskPlayAnim(ped, patientState.dict, patientState.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
                        end
                    end
                end
            elseif patientState.kind == "vehicle" then
                local vehicle = GetVehicleFromNetId(patientState.netId)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    if not IsEntityAttachedToEntity(ped, vehicle) then
                        local po = patientState.offset or DEFAULT_PATIENT_OFFSET
                        local bone = GetEntityBoneIndexByName(vehicle, "chassis_dummy")
                        if bone == -1 then bone = GetEntityBoneIndexByName(vehicle, "chassis") end
                        if bone == -1 then bone = 0 end
                        AttachEntityToEntity(ped, vehicle, bone, po.x, po.y, po.z, po.rx, po.ry, po.rz, false, false, false, false, 2, true)
                        if not IsEntityPlayingAnim(ped, "savecouch@", "t_sleep_loop_couch", 3) then
                            safeLoadAnimDict("savecouch@")
                            TaskPlayAnim(ped, "savecouch@", "t_sleep_loop_couch", 8.0, -8.0, -1, 1, 0, false, false, false)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- UTIL: Equipment extras
-- ============================================================

local function ToggleEquipmentExtra(player, extraIndex)
    local stretcherObject = GetClosestStretcher(GetEntityCoords(player), 3.0)
    if not stretcherObject then return end

    if type(extraIndex) == "table" then
        for _, index in ipairs(extraIndex) do
            if IsVehicleExtraTurnedOn(stretcherObject, index) then
                SetVehicleExtra(stretcherObject, index, 1)
            else
                SetVehicleExtra(stretcherObject, index, 0)
            end
        end
        return
    end

    if IsVehicleExtraTurnedOn(stretcherObject, extraIndex) then
        SetVehicleExtra(stretcherObject, extraIndex, 1)
    else
        SetVehicleExtra(stretcherObject, extraIndex, 0)
    end
end

-- ============================================================
-- Spawn / Delete stretcher
-- ============================================================

local function SpawnStretcher()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    if not safeLoadModel(defaultStretcherModel) then return end

    local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
    local stretcher = VFW.OneSync.CreateVehicleRaw(defaultStretcherModel, vector3(offset.x, offset.y, offset.z), playerHeading - 90.0)

    SetVehicleOnGroundProperly(stretcher)
    SetVehicleHasBeenOwnedByPlayer(stretcher, true)

    SetVehicleExtra(stretcher, 2, 0)
    SetVehicleExtra(stretcher, 12, 0)
    SetVehicleExtra(stretcher, 1, 1)
    SetVehicleExtra(stretcher, 3, 1)
    SetVehicleExtra(stretcher, 5, 1)
    SetVehicleExtra(stretcher, 6, 1)
    SetVehicleExtra(stretcher, 7, 1)
    SetVehicleExtra(stretcher, 11, 1)
    SetVehicleHasBeenOwnedByPlayer(stretcher, true)
    SetModelAsNoLongerNeeded(defaultStretcherModel)

    AddStretcherId(GetVehicleNetId(stretcher))
end

local function DeleteStretcher()
    local stretcherObject = GetClosestStretcher(GetEntityCoords(PlayerPedId()), 5.0)
    if not DoesEntityExist(stretcherObject) then
        Notify("~y~No stretcher nearby to delete!")
        return
    end
    SetEntityAsMissionEntity(stretcherObject, true, true)
    RemoveStretcherId(GetVehicleNetId(stretcherObject))
    DeleteVehicle(stretcherObject)
end

local function DeleteAllStretchers()
    local delCount = 0

    for _, stretcher in ipairs(GetGamePool('CVehicle')) do
        if IsStretcherModel(stretcher) then
            SetEntityAsMissionEntity(stretcher, true, true)
            RemoveStretcherId(GetVehicleNetId(stretcher))
            DeleteVehicle(stretcher)
            if DoesEntityExist(stretcher) then
                DeleteEntity(stretcher)
            end
            delCount = delCount + 1
        end
    end
    Notify('~y~' .. delCount .. ' stretchers deleted.')
end

-- ============================================================
-- TakeStretcher
-- ============================================================

local function TakeStretcher(stretcherObject)
    if IsPedInAnyVehicle(PlayerPedId()) then return end
    if PreventTakingStretcherWhileSeated then return end
    if GetGameTimer() < getUpCooldown then return end
    if not stretcherObject or not DoesEntityExist(stretcherObject) then return end

    safeLoadAnimDict("anim@heists@box_carry@")

    NetworkRequestControlOfEntity(stretcherObject)
    local t = GetGameTimer()
    while not NetworkHasControlOfEntity(stretcherObject) do
        if (GetGameTimer() - t) > LOAD_TIMEOUT then return end
        Wait(0)
    end

    AttachEntityToEntity(stretcherObject, PlayerPedId(), PlayerPedId(), -0.05, 1.375, -0.3450, 180.0, 180.0, 180.0, false, false, false, false, 2, true)
    SetVehicleExtra(stretcherObject, 1, 0)
    SetVehicleExtra(stretcherObject, 2, 1)
    SetMovingState(GetVehicleNetId(stretcherObject), true)

    local stretcherButtonsId = VFW.AddInstructionalButtons({
        { control = 47, label = "Charger" },
        { control = 73, label = "Poser" },
    })

    while IsEntityAttachedToEntity(stretcherObject, PlayerPedId()) do
        Wait(0)

        HideHudComponentThisFrame(19)
        DisableControlAction(0, 37, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 45, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, Cfg.Keys.load, true)
        DisableControlAction(0, Cfg.Keys.take, true)

        if not IsEntityPlayingAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 3) then
            TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
        end

        if IsPedDeadOrDying(PlayerPedId()) or IsPedRagdoll(PlayerPedId()) then
            ClearPedTasksImmediately(PlayerPedId())
            SetVehicleExtra(stretcherObject, 1, 1)
            SetVehicleExtra(stretcherObject, 2, 0)
            DetachEntity(stretcherObject, true, true)
            SetVehicleOnGroundProperly(stretcherObject)
            SetMovingState(GetVehicleNetId(stretcherObject), false)
        end

        if IsDisabledControlJustPressed(0, Cfg.Keys.load) or IsControlJustPressed(0, Cfg.Keys.load) then
            local success = AttachToAmbulance(stretcherObject)
            if success then
                ClearPedTasksImmediately(PlayerPedId())
            end
        end

        if IsDisabledControlJustPressed(0, Cfg.Keys.take) or IsControlJustPressed(0, Cfg.Keys.take) then
            ClearPedTasksImmediately(PlayerPedId())
            SetVehicleExtra(stretcherObject, 1, 1)
            SetVehicleExtra(stretcherObject, 2, 0)
            DetachEntity(stretcherObject, true, false)
            SetVehicleOnGroundProperly(stretcherObject)

            local playerPed = PlayerPedId()
            local OffsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.127, 1.375, -0.030)
            SetEntityCoords(stretcherObject, OffsetCoords.x, OffsetCoords.y, OffsetCoords.z)

            SetMovingState(GetVehicleNetId(stretcherObject), false)
        end
    end

    VFW.RemoveInstructionalButtons(stretcherButtonsId)
end

-- ============================================================
-- AttachToAmbulance
-- ============================================================

function AttachToAmbulance(stretcherObject)
    -- Direct search: find nearest ambulance from config using pre-built hash map
    local pedCoords = GetEntityCoords(PlayerPedId())
    local nearestVehicle, vehicleConfig = nil, nil
    local smallestDist = 20.0

    for _, v in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(v) then
            local config = ambulanceHashMap[GetEntityModel(v)]
            if config then
                local dist = #(pedCoords - GetEntityCoords(v))
                if dist <= smallestDist and dist <= (config.dist or 8.0) then
                    smallestDist = dist
                    nearestVehicle = v
                    vehicleConfig = config
                end
            end
        end
    end

    if not nearestVehicle or not vehicleConfig then
        Notify("~r~Aucune ambulance à proximité.")
        return false
    end

    NetworkRequestControlOfEntity(nearestVehicle)

    local vehicleBone = -1

    if vehicleConfig.powerload then
        vehicleBone = GetEntityBoneIndexByName(nearestVehicle, "bonnet")
        if vehicleBone == -1 then return false end
    else
        vehicleBone = GetEntityBoneIndexByName(nearestVehicle, "chassis_dummy")
        if vehicleBone == -1 then
            vehicleBone = GetEntityBoneIndexByName(nearestVehicle, "chassis")
        end
        if vehicleBone == -1 then
            vehicleBone = GetEntityBoneIndexByName(nearestVehicle, "bodyshell")
        end
        if vehicleBone == -1 then
            vehicleBone = GetEntityBoneIndexByName(nearestVehicle, "seat_dside_f")
        end
        if vehicleBone == -1 then return false end
    end

    SetVehicleHasBeenOwnedByPlayer(nearestVehicle, true)
    SetEntityAsMissionEntity(nearestVehicle, true, true)

    SetVehicleExtra(stretcherObject, 1, 1)
    SetVehicleExtra(stretcherObject, 2, 0)

    AttachEntityToEntity(stretcherObject, nearestVehicle, vehicleBone, vehicleConfig.xOffset, vehicleConfig.yOffset, vehicleConfig.zOffset, 0.0, 0.0, vehicleConfig.rotOffset, false, false, true, false, 2, true)
    SetMovingState(GetVehicleNetId(stretcherObject), true)

    local patientPed = nil
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= PlayerPedId() and IsEntityAttachedToEntity(ped, stretcherObject) then
            patientPed = ped
            break
        end
    end

    if patientPed then
        local patientOffset = vehicleConfig.patientOffset or DEFAULT_PATIENT_OFFSET
        local vehicleNetId = GetVehicleNetId(nearestVehicle)
        local playerIdx = NetworkGetPlayerIndexFromPed(patientPed)

        if playerIdx ~= -1 and NetworkIsPlayerActive(playerIdx) then
            local targetSrc = GetPlayerServerId(playerIdx)
            TriggerServerEvent('sn_sams:stretcher:relayPatientToVehicle', targetSrc, vehicleNetId, patientOffset)
        else
            NetworkRequestControlOfEntity(patientPed)
            local t = GetGameTimer()
            while not NetworkHasControlOfEntity(patientPed) do
                if (GetGameTimer() - t) > 1500 then break end
                Wait(0)
            end
            DetachEntity(patientPed, true, true)
            ClearPedTasksImmediately(patientPed)
            local bone = GetEntityBoneIndexByName(nearestVehicle, "chassis_dummy")
            if bone == -1 then bone = GetEntityBoneIndexByName(nearestVehicle, "chassis") end
            if bone == -1 then bone = 0 end
            AttachEntityToEntity(patientPed, nearestVehicle, bone, patientOffset.x, patientOffset.y, patientOffset.z, patientOffset.rx, patientOffset.ry, patientOffset.rz, false, false, false, false, 2, true)
            safeLoadAnimDict("savecouch@")
            TaskPlayAnim(patientPed, "savecouch@", "t_sleep_loop_couch", 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end

    -- If vehicle has stretcherExtra, turn it ON (brancard visible inside) - synced to all players
    if vehicleConfig.stretcherExtra and DoesExtraExist(nearestVehicle, vehicleConfig.stretcherExtra) then
        SyncVehicleExtra(nearestVehicle, vehicleConfig.stretcherExtra, false) -- false = ON in GTA
    end

    -- Close doors
    for _, door in ipairs(vehicleConfig.doors) do
        local doorIndex = ({FLD=0, FRD=1, BLD=2, BRD=3, HOOD=4, TRUNK=5, RLD=6, RRD=7})[door]
        if doorIndex then
            SetVehicleDoorShut(nearestVehicle, doorIndex, false)
        end
    end

    -- Delete the strykerpro stretcher
    SetEntityAsMissionEntity(stretcherObject, true, true)
    RemoveStretcherId(GetVehicleNetId(stretcherObject))
    DeleteVehicle(stretcherObject)

    ClearPedTasksImmediately(PlayerPedId())
    Notify("Brancard rangé dans le véhicule.")
    return true
end

-- ============================================================
-- ToggleVehicleDoors
-- ============================================================

local function ToggleVehicleDoors()
    local nearestVehicle, vehicleConfig = GetClosestVehicleFromPedPos(PlayerPedId(), 20.0, 7.0, true, Cfg.Vehicles)
    if not nearestVehicle or not vehicleConfig then return end

    SetVehicleHasBeenOwnedByPlayer(nearestVehicle, true)
    SetEntityAsMissionEntity(nearestVehicle, true, true)

    local distanceToVehicle = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(nearestVehicle))
    if distanceToVehicle > vehicleConfig.dist then return end

    local fld, frd, bld, brd, hood, trunk, rld, rrd = false, false, false, false, false, false, false, false

    for _, door in ipairs(vehicleConfig.doors) do
        if door == "FLD" then fld = true end
        if door == "FRD" then frd = true end
        if door == "BLD" then bld = true end
        if door == "BRD" then brd = true end
        if door == "HOOD" then hood = true end
        if door == "TRUNK" then trunk = true end
        if door == "RLD" then rld = true end
        if door == "RRD" then rrd = true end
    end

    TriggerServerEvent('sn_sams:stretcher:toggleDoors', GetVehicleNetId(nearestVehicle), fld, frd, bld, brd, hood, trunk, rld, rrd)
end

-- ============================================================
-- Event handlers: positions
-- ============================================================

local EventHandlers = {
    ["StretcherReceiveCPR"]              = { "mini@cpr@char_b@cpr_str", "cpr_pumpchest", {0, 0.0, 0.2, 1.5, 0.0, 0.0, 180.0, false, false, false, false, 2, true} },
    ["StretcherSitRight"]                = { "amb@prop_human_seat_chair_food@male@base", "base", {0, 0.0, -0.2, 0.55, 0.0, 0.0, -90.0, false, false, false, false, 2, true} },
    ["StretcherSitLeft"]                 = { "amb@prop_human_seat_chair_food@male@base", "base", {0, 0.0, -0.2, 0.55, 0.0, 0.0, 90.0, false, false, false, false, 2, true} },
    ["StretcherSitEnd"]                  = { "anim@heists@fleeca_bank@hostages@intro", "intro_loop_ped_a", {0, 0.0, -1.1, 1.05, 0.0, 0.0, 180.0, false, false, false, false, 2, true} },
    ["StretcherSitUpright"]              = { "amb@world_human_stupor@male@base", "base", {0, -0.05, 0.1, 1.5, 0.0, 0.0, 180.0, false, false, false, false, 2, true} },
    ["StretcherSitUprightLegsCrossed"]   = { "switch@michael@tv_w_kids", "001520_02_mics3_14_tv_w_kids_exit_trc", {0, 0.0, -0.075, 1.6, 0.0, 0.0, 180.0, false, false, false, false, 2, true} },
    ["StretcherSitUprightKneesTucked"]   = { "anim@amb@casino@out_of_money@ped_male@02b@base", "base", {0, 0.0, 0.1, 1.52, 0.0, 0.0, 184.0, false, false, false, false, 2, true} },
    ["StretcherLieBack"]                 = { "savecouch@", "t_sleep_loop_couch", {0, 0.0, 0.2, 1.1, 0.0, 0.0, 180.0, false, false, false, false, 2, true} },
    ["StretcherLieLeft"]                 = { "amb@lo_res_idles@", "world_human_bum_slumped_right_lo_res_base", {0, 0.2, 0.1, 1.55, 0.0, 0.0, 100.0, false, false, false, false, 2, true} },
    ["StretcherLieUpright"]              = { "amb@world_human_stupor@male_looking_left@base", "base", {0, 0.0, 0.3, 1.5, 0.0, 0.0, 180.0, false, false, false, false, 2, true} },
    ["StretcherLieProne"]                = { "amb@world_human_sunbathe@male@front@base", "base", {0, 0.0, 0.2, 1.5, 0.0, 0.0, 0.0, false, false, false, false, 2, true} },
}

for event, data in pairs(EventHandlers) do
    AddEventHandler(event, function()
        PlayAnimation(PlayerPedId(), data[1], data[2], data[3])
    end)
end

-- ============================================================
-- Event handlers: equipment toggles
-- ============================================================

AddEventHandler('ToggleHeadrest', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local stretcherObject = GetClosestStretcher(playerCoords, 3.0)
    if not stretcherObject then return end
    if IsVehicleExtraTurnedOn(stretcherObject, 11) then
        SetVehicleExtra(stretcherObject, 11, 1)
        SetVehicleExtra(stretcherObject, 12, 0)
    elseif IsVehicleExtraTurnedOn(stretcherObject, 12) then
        SetVehicleExtra(stretcherObject, 11, 0)
        SetVehicleExtra(stretcherObject, 12, 1)
    end
end)

AddEventHandler('ToggleBackboard', function()
    ToggleEquipmentExtra(PlayerPedId(), 3)
end)

AddEventHandler('ToggleMonitor', function()
    ToggleEquipmentExtra(PlayerPedId(), 5)
end)

AddEventHandler('ToggleRedBag', function()
    ToggleEquipmentExtra(PlayerPedId(), 6)
end)

AddEventHandler('ToggleBlueBag', function()
    ToggleEquipmentExtra(PlayerPedId(), 7)
end)

-- ============================================================
-- StretcherGetUp
-- ============================================================

AddEventHandler('StretcherGetUp', function()
    local playerPed = PlayerPedId()

    if patientState and patientState.kind == "vehicle" then
        local vehicle = GetVehicleFromNetId(patientState.netId)
        patientState = nil
        PreventTakingStretcherWhileSeated = false
        getUpCooldown = GetGameTimer() + 1000

        ClearPedTasksImmediately(playerPed)
        DetachEntity(playerPed, true, true)

        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            local vehCoords = GetEntityCoords(vehicle)
            local exitCoords = vehCoords + GetEntityForwardVector(vehicle) * -2.8
            SetEntityCoords(playerPed, exitCoords.x, exitCoords.y, exitCoords.z + 0.2, false, false, false, false)
        end
        return
    end

    -- Patient couché sur un brancard : on se contente de le détacher.
    -- L'ancien chemin (en-dessous) demande NetworkRequestControlOfEntity du brancard
    -- pour le supprimer/recréer (logique côté médic), mais le patient n'en a
    -- généralement pas le contrôle réseau (c'est le médic qui l'a spawn), donc
    -- la boucle d'attente time out à 5s et `return` silencieusement -> rien ne se passe.
    if patientState and patientState.kind == "stretcher" then
        local stretcher = GetVehicleFromNetId(patientState.netId)
        patientState = nil
        PreventTakingStretcherWhileSeated = false
        getUpCooldown = GetGameTimer() + 1000

        ClearPedTasksImmediately(playerPed)
        DetachEntity(playerPed, true, true)

        if stretcher and stretcher ~= 0 and DoesEntityExist(stretcher) then
            local sc = GetEntityCoords(stretcher)
            local exitCoords = sc + GetEntityForwardVector(stretcher) * -1.5
            SetEntityCoords(playerPed, exitCoords.x, exitCoords.y, exitCoords.z + 0.2, false, false, false, false)
        end
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local stretcherObject = GetClosestStretcher(playerCoords, 5.0)

    if not stretcherObject then return end

    if not NetworkHasControlOfEntity(stretcherObject) then
        NetworkRequestControlOfEntity(stretcherObject)
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(stretcherObject) do
            if (GetGameTimer() - t) > LOAD_TIMEOUT then return end
            Wait(0)
        end
        TriggerEvent('StretcherGetUp')
        return
    end

    local stretcherCoords = GetEntityCoords(stretcherObject)
    local stretcherHeading = GetEntityHeading(stretcherObject)

    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(stretcherObject, i) then
            extras[i] = IsVehicleExtraTurnedOn(stretcherObject, i) and 0 or 1
        end
    end

    local stretcherModel = GetEntityModel(stretcherObject)

    DetachEntity(playerPed, true, true)
    local x, y, z = table.unpack(stretcherCoords + GetEntityForwardVector(stretcherObject) * -1.5)
    SetEntityCoords(playerPed, x, y, z)
    ClearPedTasksImmediately(playerPed)

    PreventTakingStretcherWhileSeated = false
    patientState = nil
    getUpCooldown = GetGameTimer() + 1000

    SetVehicleHasBeenOwnedByPlayer(stretcherObject, false)
    SetEntityAsMissionEntity(stretcherObject, true, true)
    RemoveStretcherId(GetVehicleNetId(stretcherObject))
    DeleteVehicle(stretcherObject)
    SetEntityAsNoLongerNeeded(stretcherObject)

    if not safeLoadModel(stretcherModel) then return end

    local newStretcher = VFW.OneSync.CreateVehicleRaw(stretcherModel, vector3(stretcherCoords.x, stretcherCoords.y, stretcherCoords.z), stretcherHeading)

    SetVehicleOnGroundProperly(newStretcher)
    SetVehicleHasBeenOwnedByPlayer(newStretcher, true)

    for extra, state in pairs(extras) do
        SetVehicleExtra(newStretcher, extra, state)
    end
    SetModelAsNoLongerNeeded(stretcherModel)

    AddStretcherId(GetVehicleNetId(newStretcher))
    SetSittingState(GetVehicleNetId(newStretcher), false)
end)

-- ============================================================
-- Commands
-- ============================================================

local function CanUseStretcherCommand()
    local job = VFW.PlayerData.job
    return job ~= nil and job.onDuty
end

RegisterCommand('stretcher', function()
    if not CanUseStretcherCommand() then return end
    SpawnStretcher()
end, false)

RegisterCommand('delstretcher', function()
    if not CanUseStretcherCommand() then return end
    DeleteStretcher()
end, false)

RegisterCommand('mdstretcher', function()
    if not CanUseStretcherCommand() then return end
    DeleteAllStretchers()
end, false)

-- ============================================================
-- ToggleBrancard (global, used by radial menu)
-- ============================================================

local brancardDeployed = false

function ToggleBrancard()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = 'JOB', logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Erreur",
            content = "Vous n'êtes pas en service."
        })
        return
    end

    if not brancardDeployed then
        VFW.ShowNotification({
            type = 'JOB', logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Brancard",
            content = "Le brancard est déployé."
        })
        brancardDeployed = true
        ExecuteCommand('stretcher')
    else
        VFW.ShowNotification({
            type = 'JOB', logo = SN_SAMS.Logo, title = "SAMS", subtitle = "Brancard",
            content = "Le brancard est rangé."
        })
        brancardDeployed = false
        ExecuteCommand('delstretcher')
    end
end

-- ============================================================
-- Threads
-- ============================================================

-- Door hold thread
CreateThread(function()
    local activated = false
    while true do
        if IsControlPressed(0, Cfg.Keys.doors) and not IsPedInAnyVehicle(PlayerPedId()) then
            if not activated then
                local timer = 0
                local hold = 700
                activated = true
                while IsControlPressed(0, Cfg.Keys.doors) do
                    Wait(0)
                    timer = timer + GetFrameTime() * 1000
                    if timer >= hold then
                        ToggleVehicleDoors()
                        break
                    end
                end
            end
        else
            activated = false
            Wait(200)
        end
    end
end)

-- StretcherTake (via context menu)
AddEventHandler('StretcherTake', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local stretcherObject = GetClosestStretcher(playerCoords, 3.0)
    if stretcherObject then
        TakeStretcher(stretcherObject)
    end
end)

-- ============================================================
-- Deploy stretcher from ambulance vehicle (extra toggle)
-- ============================================================

AddEventHandler('sn_sams:stretcher:deployFromVehicle', function(vehicleNetId)
    local vehicle = NetToVeh(vehicleNetId)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local vehicleModel = GetEntityModel(vehicle)
    local vehicleConfig = nil
    for _, config in ipairs(Cfg.Vehicles) do
        if GetHashKey(config.modelHash) == vehicleModel then
            vehicleConfig = config
            break
        end
    end
    if not vehicleConfig or not vehicleConfig.stretcherExtra then return end

    NetworkRequestControlOfEntity(vehicle)
    local t = GetGameTimer()
    while not NetworkHasControlOfEntity(vehicle) do
        if (GetGameTimer() - t) > 5000 then return end
        Wait(0)
    end

    -- Open doors
    for _, door in ipairs(vehicleConfig.doors) do
        local doorIndex = ({FLD=0, FRD=1, BLD=2, BRD=3, HOOD=4, TRUNK=5, RLD=6, RRD=7})[door]
        if doorIndex then
            SetVehicleDoorOpen(vehicle, doorIndex, false, false)
        end
    end

    -- Turn off stretcher extra on vehicle - synced to all players
    SyncVehicleExtra(vehicle, vehicleConfig.stretcherExtra, true) -- true = OFF in GTA

    -- Spawn strykerpro behind vehicle
    if not safeLoadModel(defaultStretcherModel) then return end

    local vehCoords = GetEntityCoords(vehicle)
    local behind = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -7.0, 0.0)
    local vehHeading = GetEntityHeading(vehicle)

    local stretcher = VFW.OneSync.CreateVehicleRaw(defaultStretcherModel, vector3(behind.x, behind.y, behind.z), vehHeading)
    SetVehicleOnGroundProperly(stretcher)
    SetVehicleHasBeenOwnedByPlayer(stretcher, true)

    -- Default extras for strykerpro
    SetVehicleExtra(stretcher, 2, 0)
    SetVehicleExtra(stretcher, 12, 0)
    SetVehicleExtra(stretcher, 1, 1)
    SetVehicleExtra(stretcher, 3, 1)
    SetVehicleExtra(stretcher, 5, 1)
    SetVehicleExtra(stretcher, 6, 1)
    SetVehicleExtra(stretcher, 7, 1)
    SetVehicleExtra(stretcher, 11, 1)
    SetModelAsNoLongerNeeded(defaultStretcherModel)

    AddStretcherId(GetVehicleNetId(stretcher))

    local patientPed = nil
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= PlayerPedId() and IsEntityAttachedToEntity(ped, vehicle) then
            patientPed = ped
            break
        end
    end

    if patientPed then
        local stretcherNetId = GetVehicleNetId(stretcher)
        local playerIdx = NetworkGetPlayerIndexFromPed(patientPed)

        if playerIdx ~= -1 and NetworkIsPlayerActive(playerIdx) then
            local targetSrc = GetPlayerServerId(playerIdx)
            TriggerServerEvent('sn_sams:stretcher:relayPatientToStretcher', targetSrc, stretcherNetId)
        else
            NetworkRequestControlOfEntity(patientPed)
            local t = GetGameTimer()
            while not NetworkHasControlOfEntity(patientPed) do
                if (GetGameTimer() - t) > 1500 then break end
                Wait(0)
            end
            DetachEntity(patientPed, true, true)
            ClearPedTasksImmediately(patientPed)
            AttachEntityToEntity(patientPed, stretcher, 0, 0.0, 0.2, 1.1, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
            safeLoadAnimDict("savecouch@")
            TaskPlayAnim(patientPed, "savecouch@", "t_sleep_loop_couch", 8.0, -8.0, -1, 1, 0, false, false, false)
        end
        SetSittingState(GetVehicleNetId(stretcher), true)
    end

    Notify("Brancard sorti du véhicule.")
end)

-- ============================================================
-- KeyMapping
-- ============================================================

RegisterKeyMapping('+StretcherGetUp', 'Se lever du brancard', 'keyboard', 'x')
RegisterCommand("+StretcherGetUp", function()
    TriggerEvent("StretcherGetUp")
end, false)

