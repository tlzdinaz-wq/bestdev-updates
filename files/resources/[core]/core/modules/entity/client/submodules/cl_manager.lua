---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Entity.Manager
cEntity.Manager = {
    id = 0,
    netId = 0,
}

function cEntity.Manager:new(entity, isNetworked)
    local obj = setmetatable({}, self)
    self.__index = self

    obj.id = entity
    if isNetworked and NetworkGetEntityIsNetworked(entity) then
        obj.netId = NetworkGetNetworkIdFromEntity(entity)
    end

    return obj
end

function cEntity.Manager:requestModel(modelHash, cb)
    modelHash = type(modelHash) == "number" and modelHash or joaat(modelHash)

    if not IsModelInCdimage(modelHash) then
        return
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(500) end

    return cb and cb(modelHash) or modelHash
end

function cEntity.Manager:CreateVehicle(model, pos, heading)
    if type(model) == "number" then
        self:requestModel(model)
        model = model
    else
        self:requestModel(model)
        model = joaat(model)
    end

    -- Lockdown "strict" : création networked déléguée au serveur.
    local entity = VFW.OneSync.CreateVehicleRaw(model, pos.xyz, heading)
    SetEntityAsMissionEntity(entity, 1, 1)
    SetVehicleDoorsLocked(entity, 0)

    return self:new(entity, true)
end

function cEntity.Manager:CreateVehicleLocal(model, pos, heading)
    if type(model) == "number" then
        self:requestModel(model)
        model = model
    else
        self:requestModel(model)
        model = joaat(model)
    end

    local entity = CreateVehicle(model, pos.xyz, heading, false, false)
    SetEntityAsMissionEntity(entity, 1, 1)
    SetVehicleDoorsLocked(entity, 0)

    return self:new(entity, false)
end

function cEntity.Manager:CreateObject(model, pos)
    self:requestModel(model)

    -- Lockdown "strict" : création networked déléguée au serveur.
    local entity = VFW.OneSync.CreateObject(model, pos.xyz)
    SetEntityAsMissionEntity(entity, 1, 1)

    return self:new(entity, true)
end

function cEntity.Manager:CreateObjectLocal(model, pos)
    self:requestModel(model)

    local entity = CreateObject(joaat(model), pos.xyz, false, false, true)
    SetEntityAsMissionEntity(entity, 1, 1)

    return self:new(entity, false)
end

function cEntity.Manager:CreatePed(model, pos, heading)
    self:requestModel(model)

    -- Lockdown "strict" : création networked déléguée au serveur.
    local entity = VFW.OneSync.CreatePed(1, model, pos.xyz, heading)
    SetEntityAsMissionEntity(entity, 1, 1)

    return self:new(entity, true)
end

function cEntity.Manager:CreatePedLocal(model, pos, heading)
    self:requestModel(model)

    local entity = CreatePed(1, joaat(model), pos.xyz, heading, false, false)
    SetEntityAsMissionEntity(entity, 1, 1)

    SetBlockingOfNonTemporaryEvents(entity, true)

    return self:new(entity, false)
end

function cEntity.Manager:getEntityId()
    return self.id
end

function cEntity.Manager:getModel()
    return GetEntityModel(self.id)
end

function cEntity.Manager:getHealth()
    return GetEntityHealth(self.id)
end

function cEntity.Manager:getPos()
    return GetEntityCoords(self.id)
end

function cEntity.Manager:getHeading()
    return GetEntityHeading(self.id)
end

function cEntity.Manager:getNetId()
    return self.netId
end

function cEntity.Manager:getOwner()
    return NetworkGetEntityOwner(self.id)
end

function cEntity.Manager:isNetworked()
    if NetworkRegisterEntityAsNetworked(self.id) then
        return true
    else
        return false
    end
end

function cEntity.Manager:setPos(pos)
    SetEntityCoordsNoOffset(self.id, pos.xyz, 0.0, 0.0, 0.0)
end

function cEntity.Manager:setHeading(heading)
    SetEntityHeading(self.id, heading)
end

function cEntity.Manager:setFreeze(status)
    FreezeEntityPosition(self.id, status)
end

function cEntity.Manager:setAlpha(alpha)
    SetEntityAlpha(self.id, alpha, 0)
end

function cEntity.Manager:resetAlpha()
    ResetEntityAlpha(self.id)
end

function cEntity.Manager:setInvincible(status)
    SetEntityInvincible(self.id, status)
end

function cEntity.Manager:setScenario(scenario, timeToLeave, playIntroClip)
    TaskStartScenarioInPlace(self.id, scenario, timeToLeave, playIntroClip)
end

function cEntity.Manager:delete()
    if self:isNetworked() and self.netId then
        TriggerServerEvent("vfw:deleteEntity", { self.netId })
    else
        DeleteEntity(self.id)
    end
end
