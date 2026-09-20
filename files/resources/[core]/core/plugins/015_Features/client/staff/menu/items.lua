---@meta _
---@diagnostic disable: duplicate-doc-field

local itemQuery = nil

local HIDDEN_ITEMS = {
    potion_1 = true, potion_2 = true, potion_3 = true,
    potion_4 = true, potion_5 = true, potion_6 = true,
    potion_7 = true, potion_8 = true, potion_9 = true,
}

--- .BuildItemsMenu
---@return any
function StaffMenu.BuildItemsMenu()
    local firstLabel = itemQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = itemQuery == nil and "UN ITEM" or itemQuery

    StaffMenu.items.Button(firstLabel, lastLabel, nil, "search", false, function()
        if itemQuery ~= nil then
            itemQuery = nil
            StaffMenu.items.refresh()
            return
        end

        itemQuery = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if itemQuery == nil or itemQuery == "" then
            itemQuery = nil
            return
        end

        StaffMenu.items.refresh()
    end)

    StaffMenu.items.Separator(nil)

    for itemName, item in pairs(VFW.Items) do
        if not HIDDEN_ITEMS[itemName] and (not itemQuery or string.find(string.lower(itemName), string.lower(tostring(itemQuery))) or
                string.find(string.lower(item.label), string.lower(tostring(itemQuery)))) then
            StaffMenu.items.Button(item.label, itemName, item.weight .. " kg", "chevron", false, function()
                local count = VFW.Nui.KeyboardInput(true, "Quantité")

                if tonumber(count) then
                    TriggerServerEvent("vfw:staff:giveItem", StaffMenu.data.selectedPlayer, itemName, tonumber(count))
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Items',
                        message = string.format("Item '%s' x%s donné au joueur %s.", item.label, tonumber(count), StaffMenu.data.selectedPlayer)
                    })
                    StaffMenu.outils.open()
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Items',
                        message = "Veuillez entrer un nombre valide."
                  })
                    StaffMenu.items.refresh()
                end
            end)
        end
    end
end
