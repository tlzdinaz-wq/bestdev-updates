---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Target
---@field __index any
Target = {}
Target.__index = Target

setmetatable(Target, {
    __call = function(self, ...)
        return (self)
    end
})

---RotationToDirection
---@param rotation number
---@param return number
function Target:RotationToDirection(rotation)
    local adjustedRotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

---RayCastGamePlayCamera
---@param distance number
---@return boolean vector3 entity
function Target:RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = Target:RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, hit, coords, d, entity = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return hit, coords, entity
end

---GetPedsCoords
---@return x, y, z
function Target:GetPedsCoords()
    local Player = PlayerPedId()
    local PlayerCoords = GetEntityCoords(Player)
    return PlayerCoords.x, PlayerCoords.y, PlayerCoords.z
end

function Target:TargetCoords(screenPosition, maxDistance, flags, ignoreEntity)
    local pos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local fov = GetGameplayCamFov()
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, 0, 2)
    local camRight, camForward, camUp, camPos = GetCamMatrix(cam)
    DestroyCam(cam, true)
    screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0
    local fovRadians = (fov * 3.14) / 180.0
    local resX, resY = GetActiveScreenResolution()
    local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * (resX / resY) * 0.534375) - (camUp * screenPosition.y * fovRadians * 0.534375)

    local direction = (to - camPos) * maxDistance
    local endPoint = camPos + direction

    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, flags or -1, ignoreEntity, 0)
    local _, hit, worldPosition, normalDirection, materialHash, entity = GetShapeTestResultIncludingMaterial(rayHandle)

    if hit == 1 then
        return true, worldPosition, normalDirection, entity, materialHash
    else
        return false, vector3(0, 0, 0), vector3(0, 0, 0), nil, materialHash
    end
end

function Target:Target(distance)
    local x, y, z = Target:GetPedsCoords()
    local safeDistance = math.min(distance or 100.0, 200.0)
    local hit, coords, entity = Target:RayCastGamePlayCamera(safeDistance)
    if hit == 1 and entity and entity ~= 0 and DoesEntityExist(entity)
        and (IsEntityAVehicle(entity) or IsEntityAPed(entity) or IsEntityAnObject(entity)) then
        -- Pour les peds, n'accepter que les joueurs (les NPCs en streaming
        -- peuvent avoir un handle Lua valide mais pas de net object stable).
        if IsEntityAPed(entity) and not IsPedAPlayer(entity) then
            return 0, 0, 0, 0
        end
        return entity, coords.x, coords.y, coords.z
    else
        return 0, 0, 0, 0
    end
end

local toogle = false

function Target:MouveEntity(entitytarget)
    if toogle then
        toogle = false
        return
    end

    toogle = true
    while toogle do
        VFW.ShowHelpNotification("Appuyez sur ~g~E~s~ pour arrêter de déplacer")
        screenPosition = vector2(GetControlNormal(0, 239), GetControlNormal(0, 240))
        hitSomething, worldPosition, normalDirection, hitEntityHandle, materialHash = _Target:TargetCoords(screenPosition, 10000.0, 1, entitytarget)
        SetEntityCoords(entitytarget, worldPosition.x, worldPosition.y, worldPosition.z)
        PlaceObjectOnGroundProperly(entitytarget)
        SetEntityCollision(entitytarget, false, true)
        Wait(0)
        if VFW.Interact.JustPressed(0, 51) then
            SetEntityCollision(entitytarget, true, true)
            toogle = false
        end
    end
end

function Target:DuplicateEntity(LastEntityHit)
    local x, y, z = Target:GetPedsCoords()
    local model = GetEntityModel(LastEntityHit)
    local entity = VFW.OneSync.CreateObject(model, vector3(x, y, z))
    return entity
end

_Target = Target()
