---@meta _
---@diagnostic disable: duplicate-doc-field

-- Current equipped bag data
local currentEquippedBagUUID = nil
local currentBagMeta = nil

---Get the currently equipped bag UUID
---@return string|nil bagUUID
function VFW.GetEquippedBagUUID()
    return currentEquippedBagUUID
end

---Set the currently equipped bag
---@param bagUUID string|nil Bag UUID
---@param bagMeta table|nil Bag item metadata
function VFW.SetEquippedBag(bagUUID, bagMeta)
    currentEquippedBagUUID = bagUUID
    currentBagMeta = bagMeta
end

---Check if a bag is equipped
---@return boolean
function VFW.HasEquippedBag()
    return currentEquippedBagUUID ~= nil
end

-- Update bag inventory in real-time
RegisterNetEvent("vfw:bag:update", function(inventory, weight)
    if not VFW.StateInventory() or not currentEquippedBagUUID then return end

    -- Reload the inventory display with updated data
    if VFW.PlayerData.target and VFW.PlayerData.target.bagUUID then
        VFW.PlayerData.target.inventory = inventory
        VFW.PlayerData.target.weight = weight
        VFW.LoadInventories()
    end
end)

-- Initialize equipped bag on player ready
RegisterNetEvent("vfw:playerReady", function()
    -- Check if player has a bag equipped in their skin
    CreateThread(function()
        Wait(1000) -- Wait for player data to load

        if not VFW.PlayerData or not VFW.PlayerData.inventory then
            return
        end

        -- Check inventory for bag items with bag_uuid
        for i = 1, #VFW.PlayerData.inventory do
            local item = VFW.PlayerData.inventory[i]
            if item.meta and item.meta.type == "bag" and item.meta.bag_uuid then
                -- Check if this bag is currently equipped (via GetClothes)
                if GetClothes and GetClothes["bag"] then
                    currentEquippedBagUUID = item.meta.bag_uuid
                    currentBagMeta = item.meta
                    console.debug("Bag inventory initialized with UUID:", currentEquippedBagUUID)
                    break
                end
            end
        end
    end)
end)

-- Clean up on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        currentEquippedBagUUID = nil
        currentBagMeta = nil
    end
end)

-- console.info("^2[VFW]^7 Bag Inventory Client loaded")
