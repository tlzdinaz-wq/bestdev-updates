-- Builder Custom Prices
-- Manage modification prices with percentage modifiers for category and model

local bIsOpen = false

-- Cache for price data
local CustomPricesCache = {
    basePrices = {},
    categoryModifiers = {},
    categoryOverrides = {},
    modelModifiers = {},
    modelOverrides = {}
}

-- Search filter for models
local modelSearchFilter = ""

-- Receive sync from server
RegisterNetEvent('customPrices:syncConfig')
AddEventHandler('customPrices:syncConfig', function(data)
    CustomPricesCache = data or {
        basePrices = {},
        categoryModifiers = {},
        categoryOverrides = {},
        modelModifiers = {},
        modelOverrides = {}
    }
end)

-- Selected items
local tSelectedCategory = nil
local tSelectedModel = nil

local function fcRefresh(Menu)
    bIsOpen = true
    Menu.refresh()
    bIsOpen = false
end

-- ==================== MENU PRINCIPAL ====================

function StaffMenu.BuildCustomPricesMenu()
    StaffMenu.builderCustomPrices.Separator("PRIX DES MODIFICATIONS")

    StaffMenu.builderCustomPrices.Button("PRIX PAR DÉFAUT", "Prix appliqués si aucune configuration spécifique", nil, "chevron", false, function()
    end, StaffMenu.customPricesBase)

    StaffMenu.builderCustomPrices.Button("% PAR CATÉGORIE", "Pourcentage de majoration par classe de vehicule.", nil, "chevron", false, function()
    end, StaffMenu.customPricesCategories)

    StaffMenu.builderCustomPrices.Button("% PAR MODÈLE", "Pourcentage de majoration par modele specifique.", nil, "chevron", false, function()
    end, StaffMenu.customPricesModels)


end

StaffMenu.builderCustomPrices.OnOpen(function()
    StaffMenu.BuildCustomPricesMenu()
end)

-- ==================== PRIX DE BASE ====================

local function BuildBasePricesMenu()
    local modTypes = TriggerServerCallback('customPrices:getModTypes') or {}

    -- Group by category
    local categories = {
        { id = "performance", label = "PERFORMANCE" },
        { id = "aesthetic", label = "ESTHÉTIQUE" },
        { id = "color", label = "COULEURS" },
        { id = "wheels", label = "ROUES" },
        { id = "lights", label = "ÉCLAIRAGE" },
        { id = "interior", label = "INTÉRIEUR" },
        { id = "other", label = "AUTRES" }
    }

    for _, cat in ipairs(categories) do
        StaffMenu.customPricesBase.Separator(cat.label)

        for _, modType in ipairs(modTypes) do
            if modType.category == cat.id then
                local currentPrice = CustomPricesCache.basePrices[modType.id]
                local priceText = currentPrice and (VFW.Math.FormatMoney(currentPrice.base_price)) or "Non défini"
              if currentPrice and modType.hasLevels and currentPrice.price_per_level > 0 then
                    priceText = priceText .. " (+" .. currentPrice.price_per_level .. "/lvl)"
              end

                StaffMenu.customPricesBase.Button(modType.label, priceText, nil, "chevron", false, function()
                    local basePrice = VFW.Nui.KeyboardInput(true, "Prix de base (" .. LOCALE.currencySymbol .. ")")
                    if basePrice and tonumber(basePrice) then
                        local pricePerLevel = 0
                        if modType.hasLevels then
                            local levelInput = VFW.Nui.KeyboardInput(true, "Prix par niveau (0 si aucun)")
                            pricePerLevel = tonumber(levelInput) or 0
                        end

                        local result = TriggerServerCallback('customPrices:updateBasePrice', modType.id, tonumber(basePrice), pricePerLevel)
                        if result and result.success then
                            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = "Prix de base mis à jour" })
                        else
                            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
                        end
                        fcRefresh(StaffMenu.customPricesBase)
                    end
                end)
            end
        end
    end
end

StaffMenu.customPricesBase.OnOpen(function()
    BuildBasePricesMenu()
end)

-- ==================== % PAR CATEGORIE ====================

local function BuildCategoriesMenu()
    local vehicleClasses = TriggerServerCallback('customPrices:getVehicleClasses') or {}

    StaffMenu.customPricesCategories.Separator("CATEGORIES DE VEHICULES")

    for _, vehClass in ipairs(vehicleClasses) do
        local globalPercent = CustomPricesCache.categoryModifiers[vehClass.name] or 0
        local overrides = CustomPricesCache.categoryOverrides[vehClass.name] or {}
        local overrideCount = 0
        for _ in pairs(overrides) do overrideCount = overrideCount + 1 end

        local percentText = globalPercent == 0 and "Aucun modificateur" or (globalPercent > 0 and ("+" .. globalPercent .. "%") or (globalPercent .. "%"))
        if overrideCount > 0 then
            percentText = percentText .. " (" .. overrideCount .. " override" .. (overrideCount > 1 and "s" or "") .. ")"
      end

        StaffMenu.customPricesCategories.Button(vehClass.label, percentText, nil, "chevron", false, function()
            tSelectedCategory = vehClass
        end, StaffMenu.customPricesCategoryEdit)
    end
end

StaffMenu.customPricesCategories.OnOpen(function()
    BuildCategoriesMenu()
end)

-- ==================== EDIT CATEGORIE ====================

local function BuildCategoryEditMenu()
    if not tSelectedCategory then return end

    local modTypes = TriggerServerCallback('customPrices:getModTypes') or {}
    local globalPercent = CustomPricesCache.categoryModifiers[tSelectedCategory.name] or 0
    local overrides = CustomPricesCache.categoryOverrides[tSelectedCategory.name] or {}

    StaffMenu.customPricesCategoryEdit.Separator(tSelectedCategory.label:upper())

    -- Global percentage
    local globalText = globalPercent == 0 and "Aucun" or (globalPercent > 0 and ("+" .. globalPercent .. "%") or (globalPercent .. "%"))
    StaffMenu.customPricesCategoryEdit.Button("% GLOBAL", globalText, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Pourcentage global (0 pour supprimer)")
        if input then
            local percent = tonumber(input) or 0
            local result = TriggerServerCallback('customPrices:setCategoryModifier', tSelectedCategory.name, percent)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = percent == 0 and "Modificateur supprimé." or ("Global défini à " .. percent .. "%.") })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
            end
            fcRefresh(StaffMenu.customPricesCategoryEdit)
        end
    end)

    StaffMenu.customPricesCategoryEdit.Separator("OVERRIDES PAR TYPE")

    -- Group by category
    local categories = {
        { id = "performance", label = "PERFORMANCE" },
        { id = "aesthetic", label = "ESTHÉTIQUE" },
        { id = "color", label = "COULEURS" },
        { id = "wheels", label = "ROUES" },
        { id = "lights", label = "ÉCLAIRAGE" },
        { id = "interior", label = "INTÉRIEUR" },
        { id = "other", label = "AUTRES" }
    }

    for _, cat in ipairs(categories) do
        local hasTypes = false
        for _, modType in ipairs(modTypes) do
            if modType.category == cat.id then
                hasTypes = true
                break
            end
        end

        if hasTypes then
            StaffMenu.customPricesCategoryEdit.Separator(cat.label)

            for _, modType in ipairs(modTypes) do
                if modType.category == cat.id then
                    local overridePercent = overrides[modType.id]
                    local text = overridePercent and (overridePercent > 0 and ("+" .. overridePercent .. "%") or (overridePercent .. "%")) or "Global"

                  StaffMenu.customPricesCategoryEdit.Button(modType.label, text, nil, "chevron", false, function()
                        local input = VFW.Nui.KeyboardInput(true, "Pourcentage (0 pour utiliser global)")
                        if input then
                            local percent = tonumber(input) or 0
                            local result = TriggerServerCallback('customPrices:setCategoryOverride', tSelectedCategory.name, modType.id, percent)
                            if result and result.success then
                                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = percent == 0 and "Override supprimé." or ("Override défini à " .. percent .. "%.") })
                            else
                                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
                            end
                            fcRefresh(StaffMenu.customPricesCategoryEdit)
                        end
                    end)
                end
            end
        end
    end
end

StaffMenu.customPricesCategoryEdit.OnOpen(function()
    BuildCategoryEditMenu()
end)

-- ==================== % PAR MODELE ====================

local function BuildModelsMenu()
    StaffMenu.customPricesModels.Separator("RECHERCHE")

    -- Search button
    StaffMenu.customPricesModels.Button("RECHERCHER", modelSearchFilter ~= "" and ("Filtre: " .. modelSearchFilter) or "Aucun filtre.", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher un modele (vide pour tout afficher)")
        modelSearchFilter = input and string.lower(input) or ""
      fcRefresh(StaffMenu.customPricesModels)
    end)

    StaffMenu.customPricesModels.Separator("MODELES CONFIGURES")

    local hasModels = false
    local sortedModels = {}

    for modelName, percentage in pairs(CustomPricesCache.modelModifiers) do
        -- Apply search filter
        if modelSearchFilter == "" or string.find(string.lower(modelName), modelSearchFilter, 1, true) then
            hasModels = true
            local overrides = CustomPricesCache.modelOverrides[modelName] or {}
            local overrideCount = 0
            for _ in pairs(overrides) do overrideCount = overrideCount + 1 end
            table.insert(sortedModels, { name = modelName, percentage = percentage, overrideCount = overrideCount })
        end
    end

    -- Also check models that only have overrides (no global percentage)
    for modelName, overrides in pairs(CustomPricesCache.modelOverrides) do
        if not CustomPricesCache.modelModifiers[modelName] then
            if modelSearchFilter == "" or string.find(string.lower(modelName), modelSearchFilter, 1, true) then
                local exists = false
                for _, m in ipairs(sortedModels) do
                    if m.name == modelName then exists = true break end
                end
                if not exists then
                    hasModels = true
                    local overrideCount = 0
                    for _ in pairs(overrides) do overrideCount = overrideCount + 1 end
                    table.insert(sortedModels, { name = modelName, percentage = 0, overrideCount = overrideCount })
                end
            end
        end
    end

    table.sort(sortedModels, function(a, b) return a.name < b.name end)

    for _, model in ipairs(sortedModels) do
        local percentText = model.percentage == 0 and "Aucun global" or (model.percentage > 0 and ("+" .. model.percentage .. "%") or (model.percentage .. "%"))
        if model.overrideCount > 0 then
            percentText = percentText .. " (" .. model.overrideCount .. " override" .. (model.overrideCount > 1 and "s" or "") .. ")"
      end

        StaffMenu.customPricesModels.Button(model.name:upper(), percentText, nil, "chevron", false, function()
            tSelectedModel = model.name
        end, StaffMenu.customPricesModelEdit)
    end

    if not hasModels then
        if modelSearchFilter ~= "" then
            StaffMenu.customPricesModels.Button("Aucun résultat", "Modifiez votre recherche.", nil, nil, true, function() end)
        else
            StaffMenu.customPricesModels.Button("Aucun modèle", "Ajoutez-en un ci-dessous.", nil, nil, true, function() end)
        end
    end

    StaffMenu.customPricesModels.Separator("ACTIONS")

    StaffMenu.customPricesModels.Button("AJOUTER UN MODÈLE", "Configurer un nouveau véhicule", nil, "chevron", false, function()
        local modelName = VFW.Nui.KeyboardInput(true, "Nom du modèle (ex: adder)")
        if modelName and modelName ~= "" then
            local modelLower = string.lower(modelName)

            local input = VFW.Nui.KeyboardInput(true, "Pourcentage global (ex: 50 pour +50%)")
            if input then
                local percent = tonumber(input) or 0

                local result = TriggerServerCallback('customPrices:setModelModifier', modelLower, percent)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = "Modèle ajouté." })
                    tSelectedModel = modelLower
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
                end
                fcRefresh(StaffMenu.customPricesModels)
            end
        end
    end)
end

StaffMenu.customPricesModels.OnOpen(function()
    BuildModelsMenu()
end)

-- ==================== EDIT MODELE ====================

local function BuildModelEditMenu()
    if not tSelectedModel then return end

    local modTypes = TriggerServerCallback('customPrices:getModTypes') or {}
    local globalPercent = CustomPricesCache.modelModifiers[tSelectedModel] or 0
    local overrides = CustomPricesCache.modelOverrides[tSelectedModel] or {}

    StaffMenu.customPricesModelEdit.Separator(tSelectedModel:upper())

    -- Global percentage
    local globalText = globalPercent == 0 and "Aucun" or (globalPercent > 0 and ("+" .. globalPercent .. "%") or (globalPercent .. "%"))
    StaffMenu.customPricesModelEdit.Button("% GLOBAL", globalText, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Pourcentage global (0 pour supprimer)")
        if input then
            local percent = tonumber(input) or 0
            local result = TriggerServerCallback('customPrices:setModelModifier', tSelectedModel, percent)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = percent == 0 and "Global supprimé." or ("Global défini à " .. percent .. "%.") })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
            end
            fcRefresh(StaffMenu.customPricesModelEdit)
        end
    end)

    -- Delete button
    StaffMenu.customPricesModelEdit.Button("SUPPRIMER LE MODELE", "Supprimer toute la configuration.", nil, "chevron", false, function()
        local result = TriggerServerCallback('customPrices:deleteModelModifier', tSelectedModel)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = "Modèle supprimé." })
            StaffMenu.customPricesModels.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
        end
    end)

    StaffMenu.customPricesModelEdit.Separator("OVERRIDES PAR TYPE")

    -- Group by category
    local categories = {
        { id = "performance", label = "PERFORMANCE" },
        { id = "aesthetic", label = "ESTHÉTIQUE" },
        { id = "color", label = "COULEURS" },
        { id = "wheels", label = "ROUES" },
        { id = "lights", label = "ÉCLAIRAGE" },
        { id = "interior", label = "INTÉRIEUR" },
        { id = "other", label = "AUTRES" }
    }

    for _, cat in ipairs(categories) do
        local hasTypes = false
        for _, modType in ipairs(modTypes) do
            if modType.category == cat.id then
                hasTypes = true
                break
            end
        end

        if hasTypes then
            StaffMenu.customPricesModelEdit.Separator(cat.label)

            for _, modType in ipairs(modTypes) do
                if modType.category == cat.id then
                    local overridePercent = overrides[modType.id]
                    local text = overridePercent and (overridePercent > 0 and ("+" .. overridePercent .. "%") or (overridePercent .. "%")) or "Global"

                  StaffMenu.customPricesModelEdit.Button(modType.label, text, nil, "chevron", false, function()
                        local input = VFW.Nui.KeyboardInput(true, "Pourcentage (0 pour utiliser global)")
                        if input then
                            local percent = tonumber(input) or 0
                            local result = TriggerServerCallback('customPrices:setModelOverride', tSelectedModel, modType.id, percent)
                            if result and result.success then
                                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Custom Prices', message = percent == 0 and "Override supprimé." or ("Override défini à " .. percent .. "%.") })
                            else
                                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Custom Prices', message = result and result.error or "Erreur." })
                            end
                            fcRefresh(StaffMenu.customPricesModelEdit)
                        end
                    end)
                end
            end
        end
    end
end

StaffMenu.customPricesModelEdit.OnOpen(function()
    BuildModelEditMenu()
end)
