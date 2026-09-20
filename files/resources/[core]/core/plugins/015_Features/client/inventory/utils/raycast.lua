---@meta _
---@diagnostic disable: duplicate-doc-field

--- DegreesToRadians
---@param degrees any
---@return any
local function DegreesToRadians(degrees)
	return (degrees * math.pi) / 180.0
end

--- RaycastScreen
---@param screenPosition vector3|table Position
---@param maxDistance any
---@param ignore any
---@return boolean
function RaycastScreen(screenPosition, maxDistance, ignore)
	local CAM_POS <const> = GetGameplayCamCoord()
	local CAM_ROT <const> = GetGameplayCamRot(0)
	local CAM_FOV <const> = GetGameplayCamFov()
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