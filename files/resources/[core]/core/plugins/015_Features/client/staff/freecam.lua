---@meta _
---@diagnostic disable: duplicate-doc-field

---@class AdminFreecam
---@field _internal_camera nil
---@field _internal_camera nil
---@field _internal_camera nil
AdminFreecam = {}

AdminFreecam._internal_camera = nil
local _internal_isFrozen = false
local _internal_pos = nil
local _internal_rot = nil
local _internal_fov = nil
local _internal_vecX = nil
local _internal_vecY = nil
local _internal_vecZ = nil
local INPUT_LOOK_LR = 1
local INPUT_LOOK_UD = 2
local INPUT_CHARACTER_WHEEL = 19
local INPUT_SPRINT = 21
local INPUT_MOVE_UD = 31
local INPUT_MOVE_LR = 30
local INPUT_VEH_ACCELERATE = 71
local INPUT_VEH_BRAKE = 72
local INPUT_PARACHUTE_BRAKE_LEFT = 152
local INPUT_PARACHUTE_BRAKE_RIGHT = 153

--------------------------------------------------------------------------------
local function protect(t)
    local fn = function (_, k)
      error('Key `' .. tostring(k) .. '` is not supported.')
    end
  
    return setmetatable(t, {
      __index = fn,
      __newindex = fn
    })
end

--- .copy
---@param x any
function table.copy(x)
    local copy = {}

    for k, v in pairs(x) do
      if type(v) == 'table' then
          copy[k] = table.copy(v)
      else
          copy[k] = v
      end
    end

    return copy
end

BASE_CONTROL_MAPPING = protect({
  -- Rotation
  LOOK_X = INPUT_LOOK_LR,
  LOOK_Y = INPUT_LOOK_UD,

  -- Position
  MOVE_X = INPUT_MOVE_LR,
  MOVE_Y = INPUT_MOVE_UD,
  MOVE_Z = { INPUT_PARACHUTE_BRAKE_LEFT, INPUT_PARACHUTE_BRAKE_RIGHT },

  -- Multiplier
  MOVE_FAST = INPUT_SPRINT,
  MOVE_SLOW = INPUT_CHARACTER_WHEEL
})

--------------------------------------------------------------------------------

BASE_CONTROL_SETTINGS = protect({
  -- Rotation
  LOOK_SENSITIVITY_X = 5,
  LOOK_SENSITIVITY_Y = 5,

  -- Position
  BASE_MOVE_MULTIPLIER = 1,
  FAST_MOVE_MULTIPLIER = 10,
  SLOW_MOVE_MULTIPLIER = 10,
})

--------------------------------------------------------------------------------

BASE_CAMERA_SETTINGS = protect({
  --Camera
  FOV = 45.0,

  -- On enable/disable
  ENABLE_EASING = true,
  EASING_DURATION = 1000,

  -- Keep position/rotation
  KEEP_POSITION = false,
  KEEP_ROTATION = false
})

--------------------------------------------------------------------------------

KEYBOARD_CONTROL_MAPPING = table.copy(BASE_CONTROL_MAPPING)
GAMEPAD_CONTROL_MAPPING = table.copy(BASE_CONTROL_MAPPING)

-- Swap up/down movement (LB for down, RB for up)
GAMEPAD_CONTROL_MAPPING.MOVE_Z[1] = INPUT_PARACHUTE_BRAKE_LEFT
GAMEPAD_CONTROL_MAPPING.MOVE_Z[2] = INPUT_PARACHUTE_BRAKE_RIGHT

-- Use LT and RT for speed
GAMEPAD_CONTROL_MAPPING.MOVE_FAST = INPUT_VEH_ACCELERATE
GAMEPAD_CONTROL_MAPPING.MOVE_SLOW = INPUT_VEH_BRAKE

protect(KEYBOARD_CONTROL_MAPPING)
protect(GAMEPAD_CONTROL_MAPPING)

--------------------------------------------------------------------------------

KEYBOARD_CONTROL_SETTINGS = table.copy(BASE_CONTROL_SETTINGS)
GAMEPAD_CONTROL_SETTINGS = table.copy(BASE_CONTROL_SETTINGS)

-- Gamepad sensitivity can be reduced by BASE.
GAMEPAD_CONTROL_SETTINGS.LOOK_SENSITIVITY_X = 2
GAMEPAD_CONTROL_SETTINGS.LOOK_SENSITIVITY_Y = 2

protect(KEYBOARD_CONTROL_SETTINGS)
protect(GAMEPAD_CONTROL_SETTINGS)

--------------------------------------------------------------------------------

CAMERA_SETTINGS = table.copy(BASE_CAMERA_SETTINGS)
protect(CAMERA_SETTINGS)

---Get InitialCameraPosition
---@return vector3|table
local function GetInitialCameraPosition()
	if CAMERA_SETTINGS.KEEP_POSITION and _internal_pos then
	  return _internal_pos
	end
  
	return GetGameplayCamCoord()
end
  
---Get AdminFreecam.InitialCameraRotation
---@return any
function AdminFreecam.GetInitialCameraRotation()
	if CAMERA_SETTINGS.KEEP_ROTATION and _internal_rot then
	  return _internal_rot
	end
  
	local rot = GetGameplayCamRot()
	return vector3(rot.x, 0.0, rot.z)
end
  
--- IsFreecamFrozen
---@return boolean
local function IsFreecamFrozen()
	return _internal_isFrozen
end
  
---Set AdminFreecam.FreecamFrozen
---@param frozen any
function AdminFreecam.SetFreecamFrozen(frozen)
	local frozen = frozen == true
	_internal_isFrozen = frozen
end
  
---Get FreecamPosition
---@return vector3|table
local function GetFreecamPosition()
	return _internal_pos
end
  
---Set AdminFreecam.FreecamPosition
---@param x any
---@param y any
---@param z any
function AdminFreecam.SetFreecamPosition(x, y, z)
	local pos = vector3(x, y, z)
	local int = GetInteriorAtCoords(pos)
  
	LoadInterior(int)
	SetFocusArea(pos)
	LockMinimapPosition(x, y)
	SetCamCoord(AdminFreecam._internal_camera, pos)
  
	_internal_pos = pos
end

---Get FreecamRotation
---@return any
local function GetFreecamRotation()
	return _internal_rot
end
  
---Get FreecamFov
---@return any
function GetFreecamFov()
	return _internal_fov
end
  
--- Clamp
---@param x any
---@param min any
---@param max any
---@return any
local function Clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

---Set AdminFreecam.FreecamFov
---@param fov any
function AdminFreecam.SetFreecamFov(fov)
	local fov = Clamp(fov, 0.0, 90.0)
	SetCamFov(AdminFreecam._internal_camera, fov)
	_internal_fov = fov
end
  
---Get FreecamMatrix
---@return any
local function GetFreecamMatrix()
	return _internal_vecX,
		   _internal_vecY,
		   _internal_vecZ,
		   _internal_pos
end
  
--- IsFreecamActive
---@return boolean
local function IsFreecamActive()
	return IsCamActive(AdminFreecam._internal_camera) == 1
end

---Set AdminFreecam.FreecamActive
---@param active boolean
function AdminFreecam.SetFreecamActive(active)
	if active == false then
		SetCamActive(AdminFreecam._internal_camera, false)
		DestroyCam(AdminFreecam._internal_camera)
		AdminFreecam._internal_camera = nil
		_internal_pos = nil
		_internal_rot = nil
		_internal_fov = nil
		_internal_vecX = nil
		_internal_vecY = nil
		_internal_vecZ = nil
		DestroyAllCams(true)
		RenderScriptCams(false, false, 0, true, true)
		SetPlayerControl(PlayerId(), true)
		ClearFocus()
		UnlockMinimapPosition()
		UnlockMinimapAngle()
		TriggerEvent('freecam:onExit')
	  	return
	end
  
	local enableEasing = CAMERA_SETTINGS.ENABLE_EASING
	local easingDuration = CAMERA_SETTINGS.EASING_DURATION
  
	if active then
	  	--console.debug("active")
	  	local pos = GetInitialCameraPosition()
	  	local rot = AdminFreecam.GetInitialCameraRotation()
		
	  	AdminFreecam._internal_camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		
	  	AdminFreecam.SetFreecamFov(CAMERA_SETTINGS.FOV)
	  	AdminFreecam.SetFreecamPosition(pos.x, pos.y, pos.z)
	  	AdminFreecam.SetFreecamRotation(rot.x, rot.y, rot.z)
	  	TriggerEvent('freecam:onEnter')
	else
	  	DestroyCam(AdminFreecam._internal_camera)
	  	ClearFocus()
	  	UnlockMinimapPosition()
	  	UnlockMinimapAngle()
	  	TriggerEvent('freecam:onExit')
	end
  
	SetPlayerControl(PlayerId(), not active)
	--console.debug("RenderScriptCams active")
	RenderScriptCams(active, enableEasing, easingDuration)
end

--- IsGamepadControl
---@return boolean
local function IsGamepadControl()
    return (not IsInputDisabled(2))
end

---Create GamepadMetatable
---@param keyboard any
---@param gamepad any
---@return number|table|boolean Created object or success status
local function CreateGamepadMetatable(keyboard, gamepad)
    return setmetatable({}, {
      __index = function (t, k)
        local src = IsGamepadControl() and gamepad or keyboard
        return src[k]
      end
    })
end

-- Create some convenient variables.
-- Allows us to access controls and config without a gamepad switch.
CONTROL_MAPPING  = CreateGamepadMetatable(KEYBOARD_CONTROL_MAPPING,  GAMEPAD_CONTROL_MAPPING)
CONTROL_SETTINGS = CreateGamepadMetatable(KEYBOARD_CONTROL_SETTINGS, GAMEPAD_CONTROL_SETTINGS)

local SETTINGS = CONTROL_SETTINGS
local CONTROLS = CONTROL_MAPPING

-------------------------------------------------------------------------------

local function GetSmartControlNormal(control)
	if type(control) == 'table' then
        local normal1 = GetDisabledControlNormal(0, control[1])
        local normal2 = GetDisabledControlNormal(0, control[2])
		return normal1 - normal2
	end
  
	return GetDisabledControlNormal(0, control)
end

local newSpeed = CONTROL_SETTINGS.BASE_MOVE_MULTIPLIER
local currentSpeed = CONTROL_SETTINGS.BASE_MOVE_MULTIPLIER
local sppedd = 1.0
---Get SpeedMultiplier
local function GetSpeedMultiplier()
	--console.debug("newSpeed, sppedd", newSpeed, sppedd)
  	local fastNormal = GetSmartControlNormal(CONTROLS.MOVE_FAST)
  	local slowNormal = GetSmartControlNormal(CONTROLS.MOVE_SLOW)
  	local wheelDeltaDOWN = GetSmartControlNormal(0, 14)
  	local wheelDeltaUP = GetSmartControlNormal(0, 15)

	if IsControlPressed(0, 14) or IsDisabledControlPressed(0, 14) then
		newSpeed = math.max(currentSpeed * 0.9, 0.01) -- Decrease speed down to min 0.01x
		currentSpeed = newSpeed
	elseif IsControlPressed(0, 15) or IsDisabledControlPressed(0, 15) then
		newSpeed = math.min(currentSpeed * 1.1, 20.0) -- Increase speed up to max 20x
		currentSpeed = newSpeed
	end

	sppedd = newSpeed

	SetTextFont(4)
	SetTextScale(0.4, 0.4)
	SetTextColour(255, 255, 255, 255)
	SetTextOutline()
	SetTextCentre(true)
	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(string.format("Camera Speed: %.1fx", (sppedd or 1.0)))
	EndTextCommandDisplayText(0.5, 0.95)

  	return sppedd
end

---Update Camera
---@return any
local function UpdateCamera()
  	if not IsFreecamActive() or IsPauseMenuActive() then
    	return
  	end

    if CameraSettingsCopy.Dof then
      SetUseHiDof() -- Sets the camera to use high dof
    end

  	if not IsFreecamFrozen() then
    local vecX, vecY = GetFreecamMatrix()
    local vecZ = vector3(0, 0, 1)

    local pos = GetFreecamPosition()
    local rot = GetFreecamRotation()

    -- Get speed multiplier for movement
    local speedMultiplier = GetSpeedMultiplier()
--	console.debug("speedMultiplier", speedMultiplier)
    -- Get rotation input
    local lookX = GetSmartControlNormal(CONTROLS.LOOK_X)
    local lookY = GetSmartControlNormal(CONTROLS.LOOK_Y)

    -- Get position input
    local moveX = GetSmartControlNormal(CONTROLS.MOVE_X)
    local moveY = GetSmartControlNormal(CONTROLS.MOVE_Y)
    local moveZ = GetSmartControlNormal(CONTROLS.MOVE_Z)

    -- Calculate new rotation.
    local rotX = rot.x + (-lookY * SETTINGS.LOOK_SENSITIVITY_X)
    local rotZ = rot.z + (-lookX * SETTINGS.LOOK_SENSITIVITY_Y)
    local rotY = rot.y

    -- Adjust position relative to camera rotation.
    pos = pos + (vecX *  moveX * speedMultiplier)
    pos = pos + (vecY * -moveY * speedMultiplier)
    pos = pos + (vecZ *  moveZ * speedMultiplier)

    -- Adjust new rotation
    rot = vector3(rotX, rotY, rotZ)

    -- Update camera
    AdminFreecam.SetFreecamPosition(pos.x, pos.y, pos.z)
    AdminFreecam.SetFreecamRotation(rot.x, rot.y, rot.z)
  end

  -- Trigger a tick event. Resources depending on the freecam position can
  -- make use of this event.
  TriggerEvent('freecam:onTick')
end

-------------------------------------------------------------------------------

CreateThread(function ()
  	while true do
  	  	Wait(0)
		if IsFreecamActive() then
  	  		UpdateCamera()
		else
			Wait(500)
		end
  	end
end)

--------------------------------------------------------------------------------

-- When the resource is stopped, make sure to return the camera to the player.
---@param resourceName number Player ID
AddEventHandler('onResourceStop', function (resourceName)
	if resourceName == GetCurrentResourceName() then
		AdminFreecam.SetFreecamActive(false)
	end
end)

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

---Set AdminFreecam.FreecamRotation
---@param x any
---@param y any
---@param z any
function AdminFreecam.SetFreecamRotation(x, y, z)
    local rotX, rotY, rotZ = ClampCameraRotation(x, y, z)
    local vecX, vecY, vecZ = EulerToMatrix(rotX, rotY, rotZ)
    local rot = vector3(rotX, rotY, rotZ)

    LockMinimapAngle(math.floor(rotZ))
    SetCamRot(AdminFreecam._internal_camera, rot)

    _internal_rot  = rot
    _internal_vecX = vecX
    _internal_vecY = vecY
    _internal_vecZ = vecZ
end