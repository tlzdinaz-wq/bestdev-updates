---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Territories = {}

--- .Territories.SendGestionData
function VFW.Territories.SendGestionData()
    -- Get total influences of crews
    local crewInfluences = {}

    VFW.Territories.Cache.Territories = TriggerServerCallback("core:territories:getShowTerritories")
    VFW.Territories.Cache.Crews = TriggerServerCallback("core:factions:getOrganizations", "crew")
    for k, v in pairs(VFW.Territories.Cache.Territories) do
        local totalInfluence = {}
        if v.global and next(v.global) then
            for _, crew in pairs(v.global) do
                for a, z in pairs(topCrews) do
                    totalInfluence[z.leader] = (totalInfluence[z.leader] or 0) + crew.influence
                end
            end
        end

        local crewId = 1

        for a, z in pairs(VFW.Territories.Cache.Crews) do
            crewInfluences[#crewInfluences + 1] = { crew = a, value = (totalInfluence[a] or 0), color = z.color, id = crewId, territoryId = a }
            crewId += 1
        end
    end

    for k, v in pairs(VFW.Territories.Cache.Territories) do
        if not v.id then
            v.id = k
        end

        -- for a,z in pairs(v.polygon) do 
        --     console.debug(a,z, z[1], z[2])
        -- end
        v.topCrews = nil
        v.zone = nil
        v.location = nil
        v.crewid = k
        v.business = nil
        v.shop1 = "Commerce 1"
      v.shop2 = "Commerce 2"
      v.shop3 = "Commerce 3"
      v.price1 = 5000
        v.price2 = 10000
        v.price3 = 15000
    end

    VFW.Nui.TerritoriesGestion(VFW.Territories.Cache.Territories)
    --console.debug(json.encode(crewInfluences, {indent = true}))
    VFW.Nui.TerritoriesInfluence(crewInfluences)
end

RegisterNUICallback("server-gestion-illegal:addTerritory", function(data)
    local points = data.polygon
    local name = data.name
    TriggerServerEvent("core:territories:addTerritory", points, name)
end)

RegisterNUICallback("server-gestion-illegal:setInfluence", function(data)
    console.debug(json.encode(data))
    if (not data.territoryId) then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Territoires',
            message = "Vous devez sélectionner une zone pour modifier l'influence."
      })
        return
    end

    local territoryName = VFW.Territories.Cache.Territories[data.territoryId].name
    console.debug("Territory name: " .. territoryName)
    TriggerServerEvent("core:territories:setInfluence", data.name, data.value, data.territoryId)
end)

RegisterNUICallback("server-gestion-illegal:saveTerritories", function(data)
    for k, v in pairs(VFW.Territories.Cache.Territories) do
        if v.id == data.id then
            data.oldName = v.name
            v.name = data.name
            v.shop1 = data.shop1
            v.shop2 = data.shop2
            v.shop3 = data.shop3
            v.price1 = data.price1
            v.price2 = data.price2
            v.price3 = data.price3
            break
        end
    end

    console.debug("server-gestion-illegal:saveTerritories", json.encode(data, { indent = true }))
    TriggerServerEvent("core:territories:updateTerrritory", data)
end)

RegisterNuiCallback("server-gestion-illegal:removeTerritories", function(data)
    console.debug("server-gestion-illegal:removeTerritories", json.encode(data))
    TriggerServerEvent("core:territories:deleteTerritory", data.name)
end)

