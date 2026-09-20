---@meta _
---@diagnostic disable: duplicate-doc-field

local pointing = false
--- IsPlayerAiming
---@param player number|table Player ID or player object
---@return boolean
local function IsPlayerAiming(player)
    return IsPlayerFreeAiming(player) or IsAimCamActive() or IsAimCamThirdPersonActive()
end

--- CanPlayerPoint
---@return boolean
local function CanPlayerPoint()
    if not DoesEntityExist(VFW.PlayerData.ped) or IsPedOnAnyBike(VFW.PlayerData.ped) or IsPlayerAiming(VFW.playerId) or IsPedFalling(VFW.PlayerData.ped) or IsPedInjured(VFW.PlayerData.ped) or IsPedInMeleeCombat(VFW.PlayerData.ped) or IsPedRagdoll(VFW.PlayerData.ped) or not IsPedHuman(VFW.PlayerData.ped) then
        return false
    end

    return true
end

--- PointingStopped
local function PointingStopped()
    RequestTaskMoveNetworkStateTransition(VFW.PlayerData.ped, 'Stop')
    SetPedConfigFlag(VFW.PlayerData.ped, 36, false)
    if not IsPedInjured(VFW.PlayerData.ped) then
        ClearPedSecondaryTask(VFW.PlayerData.ped)
    end

    RemoveAnimDict("anim@mp_point")
end

--- PointingThread
local function PointingThread()
    CreateThread(function()
        while pointing do
            Wait(0)

            if not CanPlayerPoint() then
                pointing = false
                break
            end

            local camPitch = GetGameplayCamRelativePitch()
            if camPitch < -70.0 then
                camPitch = -70.0
            elseif camPitch > 42.0 then
                camPitch = 42.0
            end

            camPitch = (camPitch + 70.0) / 112.0

            local camHeading = GetGameplayCamRelativeHeading()
            local cosCamHeading = math.cos(camHeading)
            local sinCamHeading = math.sin(camHeading)

            if camHeading < -180.0 then
                camHeading = -180.0
            elseif camHeading > 180.0 then
                camHeading = 180.0
            end

            camHeading = (camHeading + 180.0) / 360.0
            local coords = GetOffsetFromEntityInWorldCoords(VFW.PlayerData.ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
            local _, blocked = GetShapeTestResult(StartShapeTestCapsule(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, VFW.PlayerData.ped, 7))

            SetTaskMoveNetworkSignalFloat(VFW.PlayerData.ped, 'Pitch', camPitch)
            SetTaskMoveNetworkSignalFloat(VFW.PlayerData.ped, 'Heading', (camHeading * -1.0) + 1.0)
            SetTaskMoveNetworkSignalBool(VFW.PlayerData.ped, 'isBlocked', blocked)
            SetTaskMoveNetworkSignalBool(VFW.PlayerData.ped, 'isFirstPerson', GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
        end

        PointingStopped()
    end)
end

--- StartPointing
---@return any
local function StartPointing()
    if not CanPlayerPoint() then
        return
    end

    pointing = not pointing

    if pointing and VFW.Streaming.RequestAnimDict("anim@mp_point") then
        SetPedConfigFlag(VFW.PlayerData.ped, 36, true)
        TaskMoveNetworkByName(VFW.PlayerData.ped, 'task_mp_pointing', 0.5, false, 'anim@mp_point', 24)
        PointingThread()
    end
end

RegisterCommand("pointing", function()
    if IsPedInAnyVehicle(VFW.PlayerData.ped, false) or VFW.IsNoclipActive() then
        return
    end
    if IsPlayerInMugshot() then return end

    StartPointing()
end, false)
RegisterKeyMapping("pointing", "Pointer du doigt", "keyboard", "B")