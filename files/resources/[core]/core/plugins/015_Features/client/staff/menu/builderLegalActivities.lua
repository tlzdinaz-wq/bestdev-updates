-- Builder Legal Activities
-- Manage seller positions and item prices for Fishing, Hunting, Diving
-- Supports multiple sellers, visibility toggle, position at player feet

local bIsOpen = false
local ConfigCache = nil

local function fcRefresh(Menu)
    bIsOpen = true
    Menu.refresh()
    bIsOpen = false
end

-- Format price for display
local function FormatPrice(price)
    return VFW.Math.FormatMoney(price)
end

-- Fetch config from server
local function LoadConfig()
    ConfigCache = TriggerServerCallback('legalActivities:getConfig')
    return ConfigCache
end

-- Seller manage submenu state
local selectedSellerActivity = nil
local selectedSellerIndex = nil
local selectedSellerLabel = nil
local selectedSellerParentMenu = nil

-- Build seller buttons (shared logic for all 3 activities)
local function BuildSellerButtons(menu, activityKey, sellers, activityLabel)
    for _, seller in ipairs(sellers) do
        local coordStr = string.format("%.1f, %.1f, %.1f", seller.coords.x, seller.coords.y, seller.coords.z)
        local visLabel = seller.visible and "Visible" or "Masqué"
      local sellerLabel = "VENDEUR #" .. seller.index

        menu.Button(
            sellerLabel,
            coordStr .. ", " .. visLabel,
            nil, "chevron", false,
            function()
                selectedSellerActivity = activityKey
                selectedSellerIndex = seller.index
                selectedSellerLabel = activityLabel
                selectedSellerParentMenu = menu
            end, StaffMenu.legalActSellerManage
        )
    end

    -- Add seller button
    menu.Button(
        "+ AJOUTER UN VENDEUR",
        "Crée un nouveau point de vente à ta position",
        nil, "plus", false,
        function()
            local result = TriggerServerCallback('legalActivities:addSeller', activityKey)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = activityLabel, message = "Vendeur #" .. result.index .. " créé à ta position." })
                LoadConfig()
                fcRefresh(menu)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = activityLabel, message = result and result.error or "Erreur." })
            end
        end
    )
end

-- Build seller manage submenu
function StaffMenu.BuildLegalActSellerManageMenu()
    if not selectedSellerActivity or not selectedSellerIndex then return end

    local activityKey = selectedSellerActivity
    local sellerIdx = selectedSellerIndex
    local activityLabel = selectedSellerLabel
    local parentMenu = selectedSellerParentMenu

    -- Find seller data from cache
    local cfg = ConfigCache
    local sellerData = nil
    if cfg and cfg[activityKey] and cfg[activityKey].sellers then
        for _, s in ipairs(cfg[activityKey].sellers) do
            if s.index == sellerIdx then
                sellerData = s
                break
            end
        end
    end

    StaffMenu.legalActSellerManage.Separator("VENDEUR #" .. sellerIdx)

    -- Position button
    StaffMenu.legalActSellerManage.Button(
        ":pin: MODIFIER LA POSITION",
        "Déplace le vendeur à ta position actuelle",
        nil, "edit", false,
        function()
            local result = TriggerServerCallback('legalActivities:updatePosition', activityKey, tostring(sellerIdx))
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = activityLabel, message = "Position du vendeur #" .. sellerIdx .. " mise à jour." })
                LoadConfig()
                fcRefresh(StaffMenu.legalActSellerManage)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = activityLabel, message = result and result.error or "Erreur." })
            end
        end
    )

    -- Visibility toggle
    local isVisible = sellerData and sellerData.visible or false
    StaffMenu.legalActSellerManage.Checkbox(
        "VISIBLE",
        isVisible and "Le vendeur est actuellement visible" or "Le vendeur est actuellement masqué",
        false, isVisible,
        function(checked)
            local result = TriggerServerCallback('legalActivities:toggleSellerVisibility', activityKey, tostring(sellerIdx), checked)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = activityLabel, message = checked and "Vendeur #" .. sellerIdx .. " affiché." or "Vendeur #" .. sellerIdx .. " masqué." })
                LoadConfig()
                fcRefresh(StaffMenu.legalActSellerManage)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = activityLabel, message = result and result.error or "Erreur." })
            end
        end
    )

    -- Delete button
    StaffMenu.legalActSellerManage.Button(
        ":trash: SUPPRIMER",
        "Supprime définitivement ce vendeur",
        nil, "chevron", false,
        function()
            local result = TriggerServerCallback('legalActivities:deleteSeller', activityKey, tostring(sellerIdx))
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = activityLabel, message = "Vendeur #" .. sellerIdx .. " supprimé." })
                LoadConfig()
                Citizen.SetTimeout(50, function()
                    StaffMenu.legalActSellerManage.close()
                    if parentMenu then
                        parentMenu.open()
                    end
                end)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = activityLabel, message = result and result.error or "Erreur." })
            end
        end
    )
end

StaffMenu.legalActSellerManage.OnOpen(function()
    StaffMenu.BuildLegalActSellerManageMenu()
end)

-- Build price buttons (shared logic for all 3 activities)
local function BuildPriceButtons(menu, activityKey, items, activityLabel)
    for _, item in ipairs(items) do
        menu.Button(
            item.label,
            FormatPrice(item.price),
            nil, "chevron", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nouveau prix pour " .. item.label .. " (" .. LOCALE.currencySymbol .. ")")
                if input and tonumber(input) then
                    local newPrice = tonumber(input)
                    local result = TriggerServerCallback('legalActivities:updatePrice', activityKey, item.name, newPrice)
                    if result and result.success then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = activityLabel, message = item.label .. " → " .. FormatPrice(newPrice) })
                        LoadConfig()
                        fcRefresh(menu)
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = activityLabel, message = result and result.error or "Erreur." })
                    end
                end
            end
        )
    end
end

-- ==================== MAIN MENU ====================

function StaffMenu.BuildLegalActivitiesMenu()
    StaffMenu.builderLegalActivities.Separator("ACTIVITÉS LÉGALES")

    StaffMenu.builderLegalActivities.Button("PÊCHE", "Vendeurs et prix des poissons", nil, "chevron", false, function()
    end, StaffMenu.legalActFishing)

    StaffMenu.builderLegalActivities.Button("CHASSE", "Vendeurs et prix des viandes", nil, "chevron", false, function()
    end, StaffMenu.legalActHunting)

    StaffMenu.builderLegalActivities.Button("PLONGÉE", "Vendeur et prix des objets", nil, "chevron", false, function()
    end, StaffMenu.legalActDiving)
end

StaffMenu.builderLegalActivities.OnOpen(function()
    LoadConfig()
    StaffMenu.BuildLegalActivitiesMenu()
end)

-- ==================== FISHING ====================

local function BuildFishingMenu()
    local cfg = ConfigCache
    if not cfg or not cfg.fishing then return end

    StaffMenu.legalActFishing.Separator("VENDEURS")
    BuildSellerButtons(StaffMenu.legalActFishing, "fishing", cfg.fishing.sellers, "Pêche")

    StaffMenu.legalActFishing.Separator("PRIX DES POISSONS")
    BuildPriceButtons(StaffMenu.legalActFishing, "fishing", cfg.fishing.items, "Pêche")
end

StaffMenu.legalActFishing.OnOpen(function()
    if not ConfigCache then LoadConfig() end
    BuildFishingMenu()
end)

-- ==================== HUNTING ====================

local function BuildHuntingMenu()
    local cfg = ConfigCache
    if not cfg or not cfg.hunting then return end

    StaffMenu.legalActHunting.Separator("VENDEURS")
    BuildSellerButtons(StaffMenu.legalActHunting, "hunting", cfg.hunting.sellers, "Chasse")

    StaffMenu.legalActHunting.Separator("PRIX DES VIANDES")
    BuildPriceButtons(StaffMenu.legalActHunting, "hunting", cfg.hunting.items, "Chasse")
end

StaffMenu.legalActHunting.OnOpen(function()
    if not ConfigCache then LoadConfig() end
    BuildHuntingMenu()
end)

-- ==================== DIVING ====================

local function BuildDivingMenu()
    local cfg = ConfigCache
    if not cfg or not cfg.diving then return end

    StaffMenu.legalActDiving.Separator("VENDEURS")
    BuildSellerButtons(StaffMenu.legalActDiving, "diving", cfg.diving.sellers, "Plongée")

    StaffMenu.legalActDiving.Separator("PRIX DES OBJETS")
    BuildPriceButtons(StaffMenu.legalActDiving, "diving", cfg.diving.items, "Plongée")
end

StaffMenu.legalActDiving.OnOpen(function()
    if not ConfigCache then LoadConfig() end
    BuildDivingMenu()
end)
