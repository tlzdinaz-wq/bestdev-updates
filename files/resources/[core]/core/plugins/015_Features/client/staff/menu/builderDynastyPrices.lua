-- Builder Dynasty Prices
-- Manage sell and rent prices for Dynasty 8 catalogue properties

local bIsOpen = false

-- Cache for dynasty price data (synced from server)
local DynastyPricesCache = {}

-- Receive sync from server
RegisterNetEvent('dynastyPrices:syncConfig')
AddEventHandler('dynastyPrices:syncConfig', function(data)
    DynastyPricesCache = data or {}
end)

-- Selected items
local tSelectedCategory = nil
local tSelectedProperty = nil

local function fcRefresh(Menu)
    bIsOpen = true
    Menu.refresh()
    bIsOpen = false
end

-- Category definitions
local dynastyCategories = {
    { id = "Appartement", label = "HABITATIONS" },
    { id = "Garage", label = "GARAGES" },
    { id = "Entrepot", label = "ENTREPOTS" }
}

-- Format price for display
local function FormatPrice(price)
    return VFW.Math.FormatMoney(price)
end

-- ==================== MENU PRINCIPAL ====================

function StaffMenu.BuildDynastyPricesMenu()
    StaffMenu.builderDynastyPrices.Separator("GESTION DYNASTY 8")

    StaffMenu.builderDynastyPrices.Button("Tablette Dynasty (Staff)", "Ouvrir la tablette en mode staff", nil, "chevron", false, function()
        StaffMenu.builderDynastyPrices.close()
        SetTimeout(200, function()
            VFW.OpenDynastyTablet(nil, true, true)
        end)
    end)

    for _, cat in ipairs(dynastyCategories) do
        local count = 0
        if Property[cat.id] and Property[cat.id].data then
            count = #Property[cat.id].data
        end

        StaffMenu.builderDynastyPrices.Button(cat.label, count .. " propriétés", nil, "chevron", false, function()
            tSelectedCategory = cat
        end, StaffMenu.dynastyPricesCategory)
    end

end

StaffMenu.builderDynastyPrices.OnOpen(function()
    StaffMenu.BuildDynastyPricesMenu()
end)

-- ==================== MENU CATÉGORIE ====================

local function BuildCategoryMenu()
    if not tSelectedCategory then return end

    local categoryId = tSelectedCategory.id
    StaffMenu.dynastyPricesCategory.Separator(tSelectedCategory.label)

    if Property[categoryId] and Property[categoryId].data then
        for _, prop in ipairs(Property[categoryId].data) do
            local prices = DynastyPricesCache[categoryId] and DynastyPricesCache[categoryId][prop.id]
            local sellPrice = prices and prices.sell or 0
            local rentEnabled = prices and prices.rentEnabled or false
            local rentPrice = prices and prices.rent or 0
            local isEnabled = prices and prices.enabled or false

            local enabledStatus = isEnabled and ":check:" or ":x:"
          local priceText = enabledStatus .. " Vente: " .. FormatPrice(sellPrice)
            if rentEnabled then
                priceText = priceText .. " | Location: " .. FormatPrice(rentPrice) .. "/sem"
          end

            StaffMenu.dynastyPricesCategory.Button(prop.name, priceText, nil, "chevron", false, function()
                tSelectedProperty = {
                    id = prop.id,
                    name = prop.name,
                    categoryId = categoryId
                }
            end, StaffMenu.dynastyPricesEdit)
        end
    else
        StaffMenu.dynastyPricesCategory.Button("Aucune propriété", "Cette catégorie est vide.", nil, nil, true, function() end)
    end
end

StaffMenu.dynastyPricesCategory.OnOpen(function()
    BuildCategoryMenu()
end)

-- ==================== MENU ÉDITION PROPRIÉTÉ ====================

local function BuildEditMenu()
    if not tSelectedProperty then return end

    local propId = tSelectedProperty.id
    local categoryId = tSelectedProperty.categoryId
    local prices = DynastyPricesCache[categoryId] and DynastyPricesCache[categoryId][propId]
    local currentSell = prices and prices.sell or 0
    local currentRent = prices and prices.rent or 0
    local currentRentEnabled = prices and prices.rentEnabled or false
    local currentEnabled = prices and prices.enabled or false

    StaffMenu.dynastyPricesEdit.Separator(tSelectedProperty.name)

    -- Toggle sale (was previously labelled "Activer dans le catalogue").
    -- The catalog now shows the property if sale OR rent is enabled, so this
    -- toggle only controls whether the property can be sold.
    StaffMenu.dynastyPricesEdit.Checkbox("ACTIVER LA VENTE", "Permet de vendre cette propriété (visible si vente ou location active)", false, currentEnabled, function(_checked)
        local result = TriggerServerCallback('dynastyPrices:updatePrice', propId, categoryId, currentSell, currentRent, currentRentEnabled, _checked)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dynasty 8', message = _checked and "Vente activée." or "Vente désactivée." })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Dynasty 8', message = result and result.error or "Erreur." })
        end
        fcRefresh(StaffMenu.dynastyPricesEdit)
    end)

    -- Edit sell price
    StaffMenu.dynastyPricesEdit.Button("PRIX DE VENTE", FormatPrice(currentSell), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Prix de vente (" .. LOCALE.currencySymbol .. ")")
        if input and tonumber(input) then
            local newSell = tonumber(input)
            local result = TriggerServerCallback('dynastyPrices:updatePrice', propId, categoryId, newSell, currentRent, currentRentEnabled, currentEnabled)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dynasty 8', message = "Prix de vente mis à jour: " .. FormatPrice(newSell) })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Dynasty 8', message = result and result.error or "Erreur." })
            end
            fcRefresh(StaffMenu.dynastyPricesEdit)
        end
    end)

    -- Toggle rent enabled
    StaffMenu.dynastyPricesEdit.Checkbox("ACTIVER LA LOCATION", "Permet de louer cette propriété à la semaine", false, currentRentEnabled, function(_checked)
        local result = TriggerServerCallback('dynastyPrices:updatePrice', propId, categoryId, currentSell, currentRent, _checked, currentEnabled)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dynasty 8', message = _checked and "Location activée." or "Location désactivée." })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Dynasty 8', message = result and result.error or "Erreur." })
        end
        fcRefresh(StaffMenu.dynastyPricesEdit)
    end)

    -- Edit rent price (only if enabled)
    if currentRentEnabled then
        StaffMenu.dynastyPricesEdit.Button("PRIX DE LOCATION / SEMAINE", FormatPrice(currentRent) .. "/sem", nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Prix de location par semaine (" .. LOCALE.currencySymbol .. ")")
            if input and tonumber(input) then
                local newRent = tonumber(input)
                local result = TriggerServerCallback('dynastyPrices:updatePrice', propId, categoryId, currentSell, newRent, currentRentEnabled, currentEnabled)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dynasty 8', message = "Prix de location mis à jour: " .. FormatPrice(newRent) .. "/sem" })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Dynasty 8', message = result and result.error or "Erreur." })
                end
                fcRefresh(StaffMenu.dynastyPricesEdit)
            end
        end)
    end
end

StaffMenu.dynastyPricesEdit.OnOpen(function()
    BuildEditMenu()
end)
