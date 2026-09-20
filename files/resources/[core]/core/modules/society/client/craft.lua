---@meta _
---@diagnostic disable: duplicate-doc-field

-- I'm not the owner of this code

local currentCrafts = {}
local LastRecipe = nil

---Get InventoryRecipe
---@param Items string|table Item name or object
---@return table Inventory data
local function GetInventoryRecipe(Items)
    local filteredInventory = {}
    local addedItems = {}

    for _, mI in pairs(VFW.PlayerData.inventory) do
        for _, recipe in pairs(Items) do
            for _, item in pairs(recipe.recipe) do
                if mI.name == item.name and not addedItems[mI.name] then
                    if VFW.Items[mI.name] then
                        table.insert(filteredInventory, { name = mI.name, label = VFW.Items[mI.name].label, amount = mI.count })
                        addedItems[mI.name] = true
                    else
                        console.debug("Item not found in VFW.Items:", mI.name)
                    end
                end
            end
        end
    end

    return filteredInventory
end

local function JobCraftOpen(Items)
    local filteredInventory = GetInventoryRecipe(Items)
    VFW.Nui.Craft(true, Items, filteredInventory)
end

RegisterNUICallback("nui:craft:close", function()
    VFW.Nui.Craft(false)
end)

RegisterNUICallback("nui:craft:craft", function(data, cb)
    TriggerServerEvent("society:craft:startLogs", data.name, data.quantity)
    local success = TriggerServerCallback("society:craft:startCraft", data.name, data.quantity)
    
    if not success then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Impossible de fabriquer cet objet"
        })
    end
    
    cb(success)
    VFW.Nui.CraftUpdateInventory(GetInventoryRecipe(LastRecipe))
    return
end)

VFW.SetLastRecipe = function(recipe)
    LastRecipe = recipe
end

RegisterNUICallback("nui:craft:recup", function(data)
    for _, rI in pairs(LastRecipe) do
        if rI.name == data.name then
            TriggerServerEvent("society:craft:additem", data.name, data.quantity)
        end
    end
end)

function Society.initCrafts()
    if Society?.data?.custom?.crafts then
        local crafts <const> = Society.data.custom.crafts

        for k, v in pairs(crafts) do
            currentCrafts[k] = VFW.CreateBlipAndPoint("society:craft:"..Society.data.name..":"..k, vector3(v.position.x, v.position.y, v.position.z), 1, 606, 3, 0.5, VFW.PlayerData.job.label .. " - Craft", "Craft", "E", "Catalogue", {
                onPress = function()
                    LastRecipe = v.items
                    JobCraftOpen(LastRecipe)
                end
            })
        end
    end

    return true
end

function Society.unloadCraft()
    for k, v in pairs(currentCrafts) do
        Worlds.Zone.Remove(v)
        Worlds.Blips.Remove(v)
    end
    currentCrafts = {}
end
