---@meta _
---@diagnostic disable: duplicate-doc-field

local inFreecam = false
local freecamVeh = 0
local internalCam = nil
local internalPos = nil
local internalRot = nil
local internalFov = nil
local internalVecX = nil
local internalVecY = nil
local internalVecZ = nil
local lastOptions = nil
local BASE_CAMERA_SETTINGS <const> = {
    FOV = 50.0,
    ENABLE_EASING = true,
    EASING_DURATION = 250,
    KEEP_POSITION = false,
    KEEP_ROTATION = false
}
local CONTROLS <const> = {
    LOOK_X = 1,
    LOOK_Y = 2,
    MOVE_X = 30,
    MOVE_Y = 31,
    MOVE_Z = { 152, 153 },
    MOVE_FAST = 21,
    MOVE_SLOW = 22,
    SPECTATE = 24
}
local SETTINGS <const> = {
    LOOK_SENSITIVITY_X = 5,
    LOOK_SENSITIVITY_Y = 5,
    BASE_MOVE_MULTIPLIER = 0.05,
    FAST_MOVE_MULTIPLIER = 2,
    SLOW_MOVE_MULTIPLIER = 4,
}

--- Clamp
---@param x any
---@param _min any
---@param _max any
---@return any
local function Clamp(x, _min, _max)
    return math.min(math.max(x, _min), _max)
end

---Get InitialCameraPosition
---@return vector3|table
local function GetInitialCameraPosition()
    if BASE_CAMERA_SETTINGS.KEEP_POSITION and internalPos then
        return internalPos
    end

    return GetGameplayCamCoord()
end

---Get InitialCameraRotation
---@return any
local function GetInitialCameraRotation()
    if BASE_CAMERA_SETTINGS.KEEP_ROTATION and internalRot then
        return internalRot
    end

    local rot = GetGameplayCamRot()
    return vector3(rot.x, 0.0, rot.z)
end

---Get FreecamPosition
---@return vector3|table
local function GetFreecamPosition()
    return internalPos
end

---Set FreecamPosition
---@param x any
---@param y any
---@param z any
local function SetFreecamPosition(x, y, z)
    local int = GetInteriorAtCoords(x, y, z)

    LoadInterior(int)
    SetFocusArea(x, y, z)
    LockMinimapPosition(x, y)
    SetCamCoord(internalCam, x, y, z)

    internalPos = vec3(x, y, z)
end

---Get FreecamRotation
---@return any
local function GetFreecamRotation()
    return internalRot
end

--- ClampCameraRotation
---@param rotX any
---@param rotY any
---@param rotZ any
---@return any
local function ClampCameraRotation(rotX, rotY, rotZ)
    local x = Clamp(rotX, -90.0, 90.0)
    local y = rotY % 360
    local z = rotZ % 360
    return x, y, z
end

--- EulerToMatrix
---@param rotX any
---@param rotY any
---@param rotZ any
---@return any
local function EulerToMatrix(rotX, rotY, rotZ)
    local radX = math.rad(rotX)
    local radY = math.rad(rotY)
    local radZ = math.rad(rotZ)

    local sinX = math.sin(radX)
    local sinY = math.sin(radY)
    local sinZ = math.sin(radZ)
    local cosX = math.cos(radX)
    local cosY = math.cos(radY)
    local cosZ = math.cos(radZ)

    local vecX = {}
    local vecY = {}
    local vecZ = {}

    vecX.x = cosY * cosZ
    vecX.y = cosY * sinZ
    vecX.z = -sinY

    vecY.x = cosZ * sinX * sinY - cosX * sinZ
    vecY.y = cosX * cosZ - sinX * sinY * sinZ
    vecY.z = cosY * sinX

    vecZ.x = -cosX * cosZ * sinY + sinX * sinZ
    vecZ.y = -cosZ * sinX + cosX * sinY * sinZ
    vecZ.z = cosX * cosY

    vecX = vector3(vecX.x, vecX.y, vecX.z)
    vecY = vector3(vecY.x, vecY.y, vecY.z)
    vecZ = vector3(vecZ.x, vecZ.y, vecZ.z)

    return vecX, vecY, vecZ
end

---Set FreecamRotation
---@param x any
---@param y any
---@param z any
local function SetFreecamRotation(x, y, z)
    local rotX, rotY, rotZ = ClampCameraRotation(x, y, z)
    local vecX, vecY, vecZ = EulerToMatrix(rotX, rotY, rotZ)
    local rot = vector3(rotX, rotY, rotZ)

    LockMinimapAngle(math.floor(rotZ))
    SetCamRot(internalCam, rotX, rotY, rotZ)

    internalRot  = rot
    internalVecX = vecX
    internalVecY = vecY
    internalVecZ = vecZ
end

---Set FreecamFov
---@param fov any
local function SetFreecamFov(fov)
    local fov = Clamp(fov, 0.0, 90.0)
    SetCamFov(internalCam, fov)
    internalFov = fov
end

--- IsFreecamActive
---@return boolean
local function IsFreecamActive()
    return IsCamActive(internalCam)
end

---Get SmartControlNormal
---@param control any
---@return any
local function GetSmartControlNormal(control)
    if type(control) == 'table' then
        local normal1 = GetDisabledControlNormal(0, control[1])
        local normal2 = GetDisabledControlNormal(0, control[2])
        return normal1 - normal2
    end

    return GetDisabledControlNormal(0, control)
end

---Get SpeedMultiplier
---@return any
local function GetSpeedMultiplier()
    local fastNormal = GetSmartControlNormal(CONTROLS.MOVE_FAST)
    local slowNormal = GetSmartControlNormal(CONTROLS.MOVE_SLOW)

    local baseSpeed = SETTINGS.BASE_MOVE_MULTIPLIER
    local fastSpeed = 1 + ((SETTINGS.FAST_MOVE_MULTIPLIER - 1) * fastNormal)
    local slowSpeed = 1 + ((SETTINGS.SLOW_MOVE_MULTIPLIER - 1) * slowNormal)

    local frameMultiplier = GetFrameTime() * 60
    local speedMultiplier = baseSpeed * fastSpeed / slowSpeed

    return speedMultiplier * frameMultiplier
end

---Get FreecamMatrix
---@return any
local function GetFreecamMatrix()
    return internalVecX,
    internalVecY,
    internalVecZ,
    internalPos
end

---Update Camera
---@return any
local function UpdateCamera()
    if not IsFreecamActive() or IsPauseMenuActive() then
        return
    end

    local vecX, vecY = GetFreecamMatrix()

    local pos = GetFreecamPosition()
    if lastOptions and lastOptions.distance and (#(pos - lastOptions.getCenter()) > lastOptions.distance) then
        console.debug("Detecting freecam position outside of distance, teleporting to center")
        pos = lastOptions.getCenter()
    end

    local rot = GetFreecamRotation()

    local speedMultiplier = GetSpeedMultiplier()
    
    local lookX = GetSmartControlNormal(CONTROLS.LOOK_X)
    local lookY = GetSmartControlNormal(CONTROLS.LOOK_Y)
    if lastOptions and lastOptions.rightClickRotation then
        if lastOptions.getCursorPos() then
            local cursorPos = VFW.GetCursorScreenPosition()
            lookX = -(lastOptions.getCursorPos().x - cursorPos.x) * 16
            lookY = -(lastOptions.getCursorPos().y - cursorPos.y) * 16
        else
            lookX, lookY = 0, 0
        end
    end

    local moveX = GetSmartControlNormal(CONTROLS.MOVE_X)
    local moveY = GetSmartControlNormal(CONTROLS.MOVE_Y)
    local moveZ = GetSmartControlNormal(CONTROLS.MOVE_Z)

    local rotX = rot.x + (-lookY * SETTINGS.LOOK_SENSITIVITY_X)
    local rotZ = rot.z + (-lookX * SETTINGS.LOOK_SENSITIVITY_Y)

    pos = pos + (vecX *  moveX * speedMultiplier)
    pos = pos + (vecY * -moveY * speedMultiplier)
    pos = pos + (vector3(0, 0, 1) *  moveZ * speedMultiplier)

    rot = vector3(rotX, rot.y, rotZ)

    if not lastOptions or not lastOptions.distance or not (#(pos - lastOptions.getCenter()) > lastOptions.distance) then
        SetFreecamPosition(pos.x, pos.y, pos.z)
    end

    if not lastOptions or (not lastOptions.rightClickRotation or IsDisabledControlPressed(0, 25)) then
        SetFreecamRotation(rot.x, rot.y, rot.z)
    end

    return pos, rotZ
end

--- StartFreecamThread
local function StartFreecamThread()
    CreateThread(function ()
        local frameCounter = 0
        local loopPos, loopRotZ

        while IsFreecamActive() do
            loopPos, loopRotZ = UpdateCamera()
            if lastOptions and lastOptions.distance then
                DrawMarker(28, lastOptions.getCenter(), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, lastOptions.distance+.0, lastOptions.distance+.0, lastOptions.distance+.0, 255, 0, 0, 150, false, false, 2, false, nil, nil, false)
            end

            Wait(0)
        end
    end)

    --@todo: Add controls on bottom right
end

---Set FreecamActive
---@param active boolean
---@return any
local function SetFreecamActive(active)
    if active == IsFreecamActive() then
        return
    end

    local enableEasing = BASE_CAMERA_SETTINGS.ENABLE_EASING
    local easingDuration = BASE_CAMERA_SETTINGS.EASING_DURATION

    if active then
        local pos = GetInitialCameraPosition()
        local rot = GetInitialCameraRotation()

        internalCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

        SetFreecamFov(BASE_CAMERA_SETTINGS.FOV)
        SetFreecamPosition(pos.x, pos.y, pos.z)
        SetFreecamRotation(rot.x, rot.y, rot.z)
    else
        DestroyCam(internalCam)
        ClearFocus()
        UnlockMinimapPosition()
        UnlockMinimapAngle()
    end

    RenderScriptCams(active, enableEasing, easingDuration, true, true)
end

--- DegreesToRadians
---@param degrees any
---@return any
local function DegreesToRadians(degrees)
	return (degrees * math.pi) / 180.0
end

--- .RaycastScreenFreecam
---@param screenPosition vector3|table Position
---@param maxDistance any
---@param ignore any
---@return boolean
function VFW.RaycastScreenFreecam(screenPosition, maxDistance, ignore)
	local CAM_POS <const> = GetFreecamPosition()
	local CAM_ROT <const> = GetFreecamRotation()
	local CAM_FOV <const> = internalFov
	local TEMP_CAM <const> = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", CAM_POS.x, CAM_POS.y, CAM_POS.z, CAM_ROT.x, CAM_ROT.y, CAM_ROT.z, CAM_FOV, 0, 2)
	local CAM_RIGHT <const>, CAM_FORWARD <const>, CAM_UP <const>, _ = GetCamMatrix(TEMP_CAM)
	DestroyCam(TEMP_CAM, true)

	screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0

	local CAM_FOV_RADIANS <const> = DegreesToRadians(CAM_FOV)
	local TARGET <const> = CAM_POS + CAM_FORWARD + (CAM_RIGHT * screenPosition.x * CAM_FOV_RADIANS * GetAspectRatio(false) * 0.534375) - (CAM_UP * screenPosition.y * CAM_FOV_RADIANS * 0.534375)

	local DIRECTION <const> = (TARGET - CAM_POS) * maxDistance
	local END_POINT <const> = CAM_POS + DIRECTION

	local _, HIT <const>, WORLD_POSITION <const>, NORMAL_DIRECTION <const>, ENTITY <const> = GetShapeTestResult(StartShapeTestRay(CAM_POS.x, CAM_POS.y, CAM_POS.z, END_POINT.x, END_POINT.y, END_POINT.z, -1, ignore, 0))

	if HIT then
		return true, WORLD_POSITION, NORMAL_DIRECTION, ENTITY
	else
		return false, vector3(0, 0, 0), vector3(0, 0, 0), nil
	end
end

--- .TogglePlayerFreecam
---@param forceValue any
---@param options table Options
---@return any
function VFW.TogglePlayerFreecam(forceValue, options)
    if (forceValue == inFreecam) then
        return
    end

    if (forceValue == nil) then
        inFreecam = not inFreecam
    else
        inFreecam = forceValue
    end

    lastOptions = options

    if not IsFreecamActive() and inFreecam then
        SetFreecamActive(true)
        StartFreecamThread()
    end

    if IsFreecamActive() and not inFreecam then
        SetFreecamActive(false)
        SetGameplayCamRelativeHeading(0)
    end
end