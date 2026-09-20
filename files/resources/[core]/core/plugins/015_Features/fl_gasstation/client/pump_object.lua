---@meta _
---@diagnostic disable: duplicate-doc-field

PumpObject = {}

local pumpObject = nil
local isPumpAttached = false
local pumpCoords = nil
local lastPumpPosition = nil
local ropeHandle = nil
local ropeThread = nil

function PumpObject.Attach(pumpPosition)
    if isPumpAttached then
        return
    end

    local playerPed = PlayerPedId()
    local config = FuelingConfig.PumpObject

    RequestModel(config.model)
    while not HasModelLoaded(config.model) do
        Wait(1)
    end

    pumpObject = VFW.OneSync.CreateObject(config.model, GetEntityCoords(playerPed))

    AttachEntityToEntity(
        pumpObject,
        playerPed,
        GetPedBoneIndex(playerPed, config.bone),
        config.offset.x,
        config.offset.y,
        config.offset.z,
        config.rotation.x,
        config.rotation.y,
        config.rotation.z,
        true,
        true,
        false,
        true,
        1,
        true
    )

    isPumpAttached = true

    if not pumpPosition then
        pumpPosition = lastPumpPosition
    end

    if pumpPosition and pumpPosition.x and pumpPosition.y and pumpPosition.z then
        lastPumpPosition = vector3(pumpPosition.x, pumpPosition.y, pumpPosition.z)
        pumpCoords = vector3(pumpPosition.x, pumpPosition.y, pumpPosition.z + 1.2)
        PumpObject.CreateRope()
    end
end

function PumpObject.CreateRope()
    if not pumpCoords or not pumpObject then
        return
    end

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(0)
    end

    local nozzlePos = GetEntityCoords(pumpObject)
    local ropeLength = #(pumpCoords - nozzlePos)

    local ropeId = AddRope(
        pumpCoords.x, pumpCoords.y, pumpCoords.z,
        0.0, 0.0, 0.0,
        ropeLength,
        4,
        ropeLength,
        0.1,
        0.0,
        false,
        false,
        true,
        5.0,
        false,
        0
    )

    if ropeId and ropeId ~= 0 then
        ropeHandle = ropeId
        ActivatePhysics(ropeHandle)
        RopeSetUpdatePinverts(ropeHandle)

        ropeThread = CreateThread(function()
            while isPumpAttached and ropeHandle and pumpCoords do
                Wait(1)

                if pumpObject and DoesEntityExist(pumpObject) then
                    local nozzlePos = GetEntityCoords(pumpObject)
                    local dist = #(pumpCoords - nozzlePos)

                    RopeForceLength(ropeHandle, dist + 0.1)

                    PinRopeVertex(ropeHandle, 0, pumpCoords.x, pumpCoords.y, pumpCoords.z)

                    local ropeVertexCount = GetRopeVertexCount(ropeHandle)
                    if ropeVertexCount > 0 then
                        PinRopeVertex(ropeHandle, ropeVertexCount - 1, nozzlePos.x, nozzlePos.y, nozzlePos.z)
                    end
                end
            end
        end)
    end
end

function PumpObject.DeleteRope()
    ropeThread = nil

    if ropeHandle then
        DeleteRope(ropeHandle)
        RopeUnloadTextures()
        ropeHandle = nil
    end

    pumpCoords = nil
end

function PumpObject.Detach()
    if not isPumpAttached or not pumpObject then
        return
    end

    PumpObject.DeleteRope()

    DetachEntity(pumpObject, true, true)
    DeleteEntity(pumpObject)

    pumpObject = nil
    isPumpAttached = false
end

---@return boolean
function PumpObject.IsAttached()
    return isPumpAttached and pumpObject ~= nil and DoesEntityExist(pumpObject)
end

---@return number|nil
function PumpObject.GetEntity()
    return pumpObject
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        PumpObject.Detach()
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        if isPumpAttached then
            local playerPed = PlayerPedId()

            if IsEntityDead(playerPed) then
                PumpObject.Detach()
            end

            if not DoesEntityExist(pumpObject) then
                isPumpAttached = false
                pumpObject = nil
            end
        end
    end
end)
