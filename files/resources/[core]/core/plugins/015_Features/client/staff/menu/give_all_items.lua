---@meta _
---@diagnostic disable: duplicate-doc-field

-- Local variables for search and filtering
StaffMenu.itemSearchQuery = nil
local selectedCategory = "all"
local categories = {
    all = "Tous les items",
    weapon = "Armes",
    food = "Nourriture",
    drink = "Boissons",
    misc = "Divers",
    illegal = "Illégal",
    premium = "Premium"
}

-- Build Give All Items Menu
function StaffMenu.BuildGiveAllItemsMenu()
    -- Search functionality
    local firstLabel = StaffMenu.itemSearchQuery == nil and ":search: RECHERCHER" or ":search: RECHERCHER:"
  local lastLabel = StaffMenu.itemSearchQuery == nil and "UN ITEM" or StaffMenu.itemSearchQuery

    StaffMenu.giveAllItems.Button(firstLabel, lastLabel, nil, "search", false, function()
        if StaffMenu.itemSearchQuery ~= nil then
            StaffMenu.itemSearchQuery = nil
            StaffMenu.giveAllItems.refresh()
            return
        end

        StaffMenu.itemSearchQuery = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label d'item")
        if StaffMenu.itemSearchQuery == nil or StaffMenu.itemSearchQuery == "" then
            StaffMenu.itemSearchQuery = nil
            return
        end

        StaffMenu.giveAllItems.refresh()
    end)

    StaffMenu.giveAllItems.Separator("ITEMS DISPONIBLES")

    -- Quick actions for common items
    StaffMenu.giveAllItems.Button(":money: DONNER DE L'ARGENT À TOUS", "Distribuer un montant d'argent à tous les joueurs connectés", nil, "chevron", false, function()
        local amount = VFW.Nui.KeyboardInput(true, "Montant d'argent", "1000")
        amount = tonumber(amount)

        if amount and amount > 0 then
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour donner " .. VFW.Math.FormatMoney(amount) .. " à tous les joueurs", "")

            if confirm == "CONFIRMER" then
                TriggerServerEvent("vfw:staff:giveItemToAll", "money", amount)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Distribution Items',
                    message = string.format("%s donnés à tous les joueurs.", VFW.Math.FormatMoney(amount))
                })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Distribution Items',
                    message = "Action annulée."
              })
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Distribution Items',
                message = "Ce montant n'est pas valide."
          })
        end
    end)

    StaffMenu.giveAllItems.Separator(nil)

    -- Display items list
    local itemCount = 0
    for itemName, item in pairs(VFW.Items) do
        local shouldDisplay = true

        -- Filter by search query
        if StaffMenu.itemSearchQuery and StaffMenu.itemSearchQuery ~= "" then
            local query = string.lower(tostring(StaffMenu.itemSearchQuery))
            if not string.find(string.lower(itemName), query) and
               not string.find(string.lower(item.label), query) then
                shouldDisplay = false
            end
        end

        -- Filter by category
        if selectedCategory ~= "all" then
            if item.type ~= selectedCategory then
                shouldDisplay = false
            end
        end

        if shouldDisplay then
            itemCount = itemCount + 1
            local itemInfo = string.format("%s | %s kg", itemName, item.weight or 0)

            StaffMenu.giveAllItems.Button(
                item.label,
                itemInfo,
                nil,
                "chevron",
                false,
                function()
                    local quantity = VFW.Nui.KeyboardInput(true, "Quantité pour " .. item.label, "1")
                    quantity = tonumber(quantity)

                    if quantity and quantity > 0 then
                        local confirm = VFW.Nui.KeyboardInput(
                            true,
                            string.format("Tapez 'CONFIRMER' pour donner %dx %s à tous les joueurs", quantity, item.label),
                            ""
                      )

                        if confirm == "CONFIRMER" then
                            TriggerServerEvent("vfw:staff:giveItemToAll", itemName, quantity)
                            VFW.ShowNotification({
                                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Distribution Items',
                                message = string.format("%dx %s donnés à tous les joueurs.", quantity, item.label)
                            })

                            -- Log action locally
                            print(string.format("^3[Staff] Gave %dx %s to all players^0", quantity, itemName))
                        else
                            VFW.ShowNotification({
                                type = 'STAFF', variant = 'ERROR', subtitle = 'Distribution Items',
                                message = "Action annulée."
                          })
                        end
                    else
                        VFW.ShowNotification({
                            type = 'STAFF', variant = 'ERROR', subtitle = 'Distribution Items',
                            message = "Cette quantité n'est pas valide."
                      })
                    end
                end
            )
        end
    end

    if itemCount == 0 then
        StaffMenu.giveAllItems.Separator("Aucun item trouvé")
    else
        StaffMenu.giveAllItems.Separator(nil)
        StaffMenu.giveAllItems.Button(
            string.format(":chart: Total: %d items affichés", itemCount),
            nil,
            nil,
            nil,
            true,
            function() end
        )
    end

end

-- Register the menu open event
StaffMenu.giveAllItems.OnOpen(function()
    StaffMenu.BuildGiveAllItemsMenu()
end)