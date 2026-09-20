RegisterNetEvent("chestBuilder:client:getPlayerChests", function(chests)
    if not chests or not next(chests) then
        return
    end

    ChestBuilder:ReformatChest(chests)

    ChestBuilder:CreateBlips()
end)



RegisterNetEvent("chestBuilder:client:syncNewChest", function(newChest)
    ChestBuilder.cache[#ChestBuilder.cache + 1] = newChest

    if newChest.accessName and newChest.accessName ~= "" then
        ChestBuilder:CreateBlip(newChest)
    end
end)

RegisterNetEvent("chestBuilder:client:deleteChest", function(chestId)
    local chest <const>, index <const> = ChestBuilder:FindZoneById(chestId)

    if not chest or not index then
        return
    end

    if chest.accessName and chest.accessName ~= "" then
        ChestBuilder:RemoveBlipForChest(chest)
    end

    table.remove(ChestBuilder.cache, index)
end)

RegisterNetEvent("chestBuilder:client:updateChest", function(newChestData)
    local chest <const>, index <const> = ChestBuilder:FindZoneById(newChestData.id)

    if not chest or not index then
        return
    end

    ChestBuilder:RemoveBlipForChest(chest)

    ChestBuilder.cache[index] = newChestData

    if newChestData.accessName and newChestData.accessName ~= "" then
        ChestBuilder:CreateBlip(newChestData)
    end
end)

RegisterNetEvent("chestBuilder:client:openChest", function(id, maxWeight)
    VFW.OpenChest(id, "stockage", 50) --- TODO Change chest builder to implements max slots
end)

RegisterNetEvent("chestBuilder:client:syncOnGroupChange", function(chests, lastGroupName)
    ChestBuilder:DeleteZoneByAccessName(lastGroupName)


    if not chests or not next(chests) then
        return
    end

    for uuid, chest in pairs(chests) do
        ChestBuilder.cache[#ChestBuilder.cache + 1] = chest

        if (chest.accessName and chest.accessName ~= "")then
            ChestBuilder:CreateBlip(chest)
        end
    end
end)
