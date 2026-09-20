local pochonShopBuilderConfig = nil

function StaffMenu.BuildPochonShopMenu()
    StaffMenu.builderPochonShop.ClearItems()

    if not pochonShopBuilderConfig then
        StaffMenu.builderPochonShop.Separator("CHARGEMENT...")
        return
    end

    StaffMenu.builderPochonShop.Separator("POCHON SHOP")

    StaffMenu.builderPochonShop.Button(
        "PRIX: " .. VFW.Math.FormatMoney(pochonShopBuilderConfig.price),
        "Modifier le prix unitaire (espèces ou banque)",
        nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Prix unitaire", tostring(pochonShopBuilderConfig.price))
            if result and result ~= "" then
                local newPrice = tonumber(result)
                if newPrice and newPrice >= 0 then
                    local res = TriggerServerCallback("pochonShop:updatePrice", math.floor(newPrice))
                    if res and res.success then
                        pochonShopBuilderConfig.price = math.floor(newPrice)
                        StaffMenu.builderPochonShop.refresh()
                    end
                end
            end
        end
    )

    StaffMenu.builderPochonShop.Button(
        "PRIX ARGENT SALE: " .. VFW.Math.FormatMoney(pochonShopBuilderConfig.dirty_money_price),
        "Modifier le prix unitaire en argent sale",
        nil, "arrow", false,
        function()
            local result = VFW.Nui.KeyboardInput(true, "Prix argent sale", tostring(pochonShopBuilderConfig.dirty_money_price))
            if result and result ~= "" then
                local newPrice = tonumber(result)
                if newPrice and newPrice >= 0 then
                    local res = TriggerServerCallback("pochonShop:updateDirtyMoneyPrice", math.floor(newPrice))
                    if res and res.success then
                        pochonShopBuilderConfig.dirty_money_price = math.floor(newPrice)
                        StaffMenu.builderPochonShop.refresh()
                    end
                end
            end
        end
    )

    StaffMenu.builderPochonShop.Checkbox(
        "Argent sale autorisé",
        "Permettre le paiement en argent sale",
        false,
        pochonShopBuilderConfig.dirty_money_allowed,
        function(checked)
            local res = TriggerServerCallback("pochonShop:updateDirtyMoney", checked)
            if res and res.success then
                pochonShopBuilderConfig.dirty_money_allowed = checked
                StaffMenu.builderPochonShop.refresh()
            end
        end
    )
end

if StaffMenu and StaffMenu.builderPochonShop and StaffMenu.builderPochonShop.OnOpen then
    StaffMenu.builderPochonShop.OnOpen(function()
        local config = TriggerServerCallback("pochonShop:getConfig")
        pochonShopBuilderConfig = config or { price = 50, dirty_money_price = 75, dirty_money_allowed = false }
        StaffMenu.BuildPochonShopMenu()
    end)
end
