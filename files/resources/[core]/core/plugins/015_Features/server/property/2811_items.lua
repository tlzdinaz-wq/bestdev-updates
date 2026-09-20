local PS = VFW.PropertyServer

function PS.UseContractItem(source, metadata)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(metadata) ~= "table" then return false end

    TriggerClientEvent("dynastyContract:viewDocument", source, {
        propertyName = metadata.propertyName,
        categoryLabel = metadata.categoryLabel,
        contractType = metadata.contractType,
        unitPrice = metadata.unitPrice,
        duration = metadata.duration,
        totalPrice = metadata.totalPrice,
        expiryDate = metadata.expiryDate,
        buyerName = metadata.buyerName,
        ownerType = metadata.ownerType,
        groupLabel = metadata.groupLabel,
        agentName = metadata.agentName,
        signedDate = metadata.signedDate,
    })
    return true
end

function PS.UseMotelKey(source, metadata)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(metadata) ~= "table" then return false end

    local pincode = PS.ToInt(metadata.pincode)
    if not pincode then return false end

    local doorlockIds = metadata.doorlockIds
    if type(doorlockIds) ~= "table" then
        local single = PS.ToInt(metadata.doorlockId)
        if not single then return false end
        doorlockIds = { single }
    end

    local playerCoords = xPlayer.getCoords()
    local bestId, bestDist = nil, nil

    for i = 1, #doorlockIds do
        local dlId = PS.ToInt(doorlockIds[i])
        local dl = dlId and PS.Doorlocks[dlId] or nil
        if dl then
            local dx = playerCoords.x - (dl.coords.x or 0.0)
            local dy = playerCoords.y - (dl.coords.y or 0.0)
            local dz = playerCoords.z - (dl.coords.z or 0.0)
            local dist = (dx * dx) + (dy * dy) + (dz * dz)
            if not bestDist or dist < bestDist then
                bestId, bestDist = dlId, dist
            end
        end
    end

    if not bestId then return false end

    TriggerClientEvent("motel:client:useKey", source, bestId, pincode)
    return true
end

local function handleItemUse(source, itemName, metadata)
    if itemName == "dynasty_contract" then
        return PS.UseContractItem(source, metadata)
    elseif itemName == "key_motel" then
        return PS.UseMotelKey(source, metadata)
    end
    return false
end

AddEventHandler("vfw:itemUsed", function(source, itemName, metadata)
    handleItemUse(source, itemName, metadata)
end)

AddEventHandler("vfw:item:used", function(source, itemName, metadata)
    handleItemUse(source, itemName, metadata)
end)

RegisterNetEvent("vfw:property:useItem", function(itemName, metadata)
    local source = source
    if type(itemName) ~= "string" then return end
    handleItemUse(source, itemName, metadata)
end)

exports("usePropertyItem", function(source, itemName, metadata)
    return handleItemUse(source, itemName, metadata)
end)
