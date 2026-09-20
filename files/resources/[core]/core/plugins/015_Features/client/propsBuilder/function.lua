PropsBuilder = {}
PropsBuilder.cache = {
    zone = {},
    props = {}
}

function PropsBuilder:GetZoneById(zoneId)
    if not zoneId then
        return nil
    end

    return self.cache.zone[zoneId]
end

function PropsBuilder:DrawProps(zoneId)
    if not zoneId then
        return
    end

    local zone <const> = self.cache.zone[zoneId]
    if not zone then
        return
    end

    for i = 1, #zone.props do
        local propId <const> = zone.props[i]
        local propInstance <const> = self.cache.props[propId]
        if propInstance and not propInstance.object then
            local modelHash <const> = GetHashKey(propInstance.model)
            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do
                Wait(10)
            end

            local coords <const> = propInstance.position.coords

            VFW.Game.SpawnLocalObject(propInstance.model, coords, function(props)
                SetEntityAsMissionEntity(props, true, true)
                SetModelAsNoLongerNeeded(modelHash)

                if propInstance.position.rotation then
                    SetEntityRotation(props, propInstance.position.rotation.x, propInstance.position.rotation.y, propInstance.position.rotation.z, 2, false)
                elseif propInstance.position.heading then
                    SetEntityHeading(props, propInstance.position.heading)
                end

                FreezeEntityPosition(props, true)

                propInstance.object = props
            end)

        end
    end
end

function PropsBuilder:ClearProps(zoneId)
    if not zoneId then
        return
    end

    local zone <const> = self.cache.zone[zoneId]
    if not zone then
        return
    end

    for i = 1, #zone.props do
        local propId <const> = zone.props[i]
        local propInstance <const> = self.cache.props[propId]
        if propInstance and propInstance.object then

            VFW.Game.DeleteObject(propInstance.object)
            propInstance.object = nil
        end
    end
end

