---@meta _
---@diagnostic disable: duplicate-doc-field

local craftLoaded = nil

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
                    table.insert(filteredInventory, { name = mI.name, label = VFW.Items[mI.name].label, amount = mI.count })
                    addedItems[mI.name] = true
                end
            end
        end
    end

    return filteredInventory
end

local loadCraftPos = function()

    if craftLoaded then
        Worlds.Zone.Remove(craftLoaded)
        craftLoaded = nil
    end

    local pos = TriggerServerCallback("core:faction:requestCraftPosition")
    if pos == nil then
        return
    end

    craftLoaded =  Worlds.Zone.Create(pos, 1.5, false, function()
        VFW.RegisterInteraction("Craft:faction", function()
            local craftsItems = TriggerServerCallback("core:faction:getMyCraftItems")
            if not craftsItems or #craftsItems == 0 then
                VFW.ShowNotification({
                    type = "ROUGE",
                    content = "Vous n'avez pas le rang necessaire !"
                })
                return
            end

            local filteredInventory = GetInventoryRecipe(craftsItems)
            VFW.SetLastRecipe(craftsItems)
            VFW.Nui.Craft(true, craftsItems, filteredInventory, "Armes")
        end)
    end, function()
        VFW.RemoveInteraction("Craft:faction")
    end, "Craft", "E", "CraftIllegal", {
        "#FF3939",
        "#FF0000",
    })
end

RegisterNetEvent("vfw:setFaction", function()
    loadCraftPos()
end)

RegisterNetEvent("vfw:playerLoaded", function()
    while not VFW.PlayerData do
        Wait(1000)
    end

    while not VFW.PlayerData.faction do
        Wait(1000)
    end

    local crew = VFW.PlayerData.faction
    if not crew or crew.name == "nocrew" then
        return
    end

    loadCraftPos()

end)
