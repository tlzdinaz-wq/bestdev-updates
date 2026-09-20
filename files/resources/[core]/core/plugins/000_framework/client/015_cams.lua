---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Cam = {}
VFW.Cam.__index = VFW.Cam
VFW.Cam.cam = {}
VFW.Cam.prop = {}

function VFW.Cam:Create(name, data, ped)
    local playerPed = ped and ped or PlayerPedId()

    if self.cam[name] then
        DestroyCam(self.cam[name], false)
        self.cam[name] = nil
    end

    if data.rotation then 
        data.CamRot = data.rotation
    end

    if data.position then 
        data.CamCoords = data.position
    end

    if not data.Fov then 
        data.Fov = 50.0
    end

    if data.OffsetPlayer then
        local pos = GetOffsetFromEntityInWorldCoords(playerPed, data.OffsetPlayer.x, data.OffsetPlayer.y, data.OffsetPlayer.z)
        self.cam[name] = CreateCamWithParams(
            "DEFAULT_SCRIPTED_CAMERA", 
            pos.x, pos.y, pos.z,
            data.CamRot.x, data.CamRot.y, data.CamRot.z, 
            data.Fov, true, 2
        )
    else
        self.cam[name] = CreateCamWithParams(
            "DEFAULT_SCRIPTED_CAMERA", 
            data.CamCoords.x, data.CamCoords.y, data.CamCoords.z, 
            data.CamRot.x, data.CamRot.y, data.CamRot.z, 
            data.Fov, true, 2
        )
    end

    if data.Dof then
        SetCamUseShallowDofMode(self.cam[name], true)
        SetCamNearDof(self.cam[name], 0.6)
        SetCamFarDof(self.cam[name], 4.0)
        SetCamDofStrength(self.cam[name], data.DofStrength)

        CreateThread(function()
            while DoesCamExist(self.cam[name]) do
                SetUseHiDof()
                Wait(1)
            end
        end)
    end

    SetCamActive(self.cam[name], true)

    if data.Freeze ~= nil then
        FreezeEntityPosition(playerPed, data.Freeze)
    end

    if data.Animation then
        self:UpdateAnim(name, data.Animation, playerPed)
    end

    RenderScriptCams(true, false, 0, true, true)

    if data.OffsetLook then
        local posLook = GetOffsetFromEntityInWorldCoords(playerPed, data.OffsetLook.x, data.OffsetLook.y, data.OffsetLook.z)
        PointCamAtCoord(self.cam[name], posLook.x, posLook.y, posLook.z)
    elseif data.Look then
        TaskLookAtCoord(playerPed, data.CamCoords.x, data.CamCoords.y, data.CamCoords.z, -1, 0, 2)
    end
end

function VFW.Cam:Update(name, data, ped)
    if not self.cam[name] then
        return
    end

    local playerPed = ped and ped or PlayerPedId()
    
    if data.OffsetPlayer then
        local pos = GetOffsetFromEntityInWorldCoords(playerPed, data.OffsetPlayer.x, data.OffsetPlayer.y, data.OffsetPlayer.z)
        SetCamParams(self.cam[name], 
            pos.x, pos.y, pos.z,
            data.CamRot.x, data.CamRot.y, data.CamRot.z,
            data.Fov, data.Transition or 1000, 0, 0, 2
        )
    else
        SetCamParams(self.cam[name], 
            data.CamCoords.x, data.CamCoords.y, data.CamCoords.z,
            data.CamRot.x, data.CamRot.y, data.CamRot.z,
            data.Fov, data.Transition or 1000, 0, 0, 2
        )
    end

    if data.Dof then
        SetCamUseShallowDofMode(self.cam[name], true)
        SetCamNearDof(self.cam[name], 0.6)
        SetCamFarDof(self.cam[name], 4.0)
        SetCamDofStrength(self.cam[name], data.DofStrength)
    else
        SetCamUseShallowDofMode(self.cam[name], false)
    end

    if data.Animation then
        self:UpdateAnim(name, data.Animation, playerPed)
    end

    if data.Freeze ~= nil then
        FreezeEntityPosition(playerPed, data.Freeze)
    end

    if data.OffsetLook then
        local posLook = GetOffsetFromEntityInWorldCoords(playerPed, data.OffsetLook.x, data.OffsetLook.y, data.OffsetLook.z)
        PointCamAtCoord(self.cam[name], posLook.x, posLook.y, posLook.z)
    elseif data.Look then
        TaskLookAtCoord(playerPed, data.CamCoords.x, data.CamCoords.y, data.CamCoords.z, -1, 0, 2)
    end
end

function VFW.Cam:UpdateAnim(name, animation, ped)
    if not animation then
        return
    end

    local playerPed = ped and ped or PlayerPedId()

    ClearPedTasksImmediately(playerPed)
    if name and self.prop[name] then
        if DoesEntityExist(self.prop[name]) then
            ClearPedProp(playerPed, self.prop[name])
            DeleteEntity(self.prop[name])
        end
    end

    local animDict = animation.dict
    local animName = animation.anim

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    RemoveAnimDict(animDict)

    if animation.prop and animation.propPlacement then
        local propModel = joaat(animation.prop)

        RequestModel(propModel)
        while not HasModelLoaded(propModel) do
            Wait(100)
        end

        self.prop[name] = CreateObject(propModel, GetEntityCoords(playerPed), false, true, true)
        SetModelAsNoLongerNeeded(propModel)
        local boneIndex = animation.propBone and GetPedBoneIndex(playerPed, animation.propBone) or GetPedBoneIndex(playerPed, 57005)

        if type(animation.propPlacement) == "table" and #animation.propPlacement == 6 then
            AttachEntityToEntity(
                    self.prop[name], playerPed, boneIndex,
                    animation.propPlacement[1], animation.propPlacement[2], animation.propPlacement[3],
                    animation.propPlacement[4], animation.propPlacement[5], animation.propPlacement[6],
                    true, true, false, true, 1, true
            )
        end
    end
end

function VFW.Cam:Destroy(name, ped)
    if self.cam[name] then
        DestroyCam(self.cam[name], false)
        self.cam[name] = nil
    end

    RenderScriptCams(false, false, 0, true, true)

    local playerPed = ped and ped or PlayerPedId()

    FreezeEntityPosition(playerPed, false)
    ClearPedTasksImmediately(playerPed)
    if name and self.prop[name] then
        if DoesEntityExist(self.prop[name]) then
            ClearPedProp(playerPed, self.prop[name])
            DeleteEntity(self.prop[name])
        end
    end
end

function VFW.Cam:Get(name)
    return self.cam[name]
end
