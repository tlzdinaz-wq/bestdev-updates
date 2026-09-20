RegisterNetEvent("core:propsBuilder:Init", function(propsData, zoneData)
    PropsBuilder.cache.props = propsData
    PropsBuilder.cache.zone = zoneData
end)

RegisterNetEvent("propsBuilder:CreateZone", function(zoneId, zoneData, propsData)
    if not zoneId or not zoneData then
        return
    end

    PropsBuilder.cache.zone[zoneId] = zoneData
    PropsBuilder.cache.props[propsData.id] = propsData
end)

RegisterNetEvent("propsBuilder:deleteZone", function(zoneId)
    if not zoneId then
        return
    end

    local zone <const> = PropsBuilder:GetZoneById(zoneId)
    if not zone then
        return
    end

    PropsBuilder:ClearProps(zoneId)
    PropsBuilder.cache.zone[zoneId] = nil
end)

RegisterNetEvent("propsBuilder:updateZoneProps", function(zoneId, zoneData, propsData)
    if not zoneId or not propsData then
        return
    end

    local zone = PropsBuilder:GetZoneById(zoneId)
    if not zone then
        return
    end

    local oldPropsList = zone.props and {} or nil
    if zone.props then
        for i = 1, #zone.props do
            oldPropsList[i] = zone.props[i]
        end
    end

    PropsBuilder.cache.zone[zoneId] = zoneData

    if oldPropsList then
        for i = 1, #oldPropsList do
            local oldPropId = oldPropsList[i]
            local oldProp = PropsBuilder.cache.props[oldPropId]

            local stillExists = false
            for _, newProp in pairs(propsData) do
                if newProp.id == oldPropId then
                    stillExists = true
                    break
                end
            end

            if not stillExists then
                if oldProp then
                    if oldProp.object and DoesEntityExist(oldProp.object) then
                        VFW.Game.DeleteObject(oldProp.object)
                    end
                    PropsBuilder.cache.props[oldPropId] = nil
                end
            elseif oldProp then
                if oldProp.object and DoesEntityExist(oldProp.object) then
                    VFW.Game.DeleteObject(oldProp.object)
                end
                oldProp.object = nil
            end
        end
    end

    for _ ,propData in pairs(propsData) do
        PropsBuilder.cache.props[propData.id] = propData
        PropsBuilder.cache.props[propData.id].object = nil
    end
end)