-- Paid Shop Builder for Staff Menu
-- VUI-based administration for the paid shop (items, Coins, history)

local PaidShopCache = {
    categories = {},
    items = {}
}

local selectedCategory = nil
local selectedItem = nil
local newItem = {}
local isSaving = false
local newDailyReward = {}
local selectedDailyReward = nil

-- Pour Moi pool state
local pourMoiPoolCache = {}
local newPourMoiRef = {}
local selectedPourMoiRef = nil

-- Rarity options for crate items
local rarityOptions = {"common", "uncommon", "rare", "epic", "legendary"}
local rarityLabels = {
    common = "Commun",
    uncommon = "Peu commun",
    rare = "Rare",
    epic = "Épique",
    legendary = "Légendaire"
}

-- Catégories ne pouvant PAS alimenter le pool Pour Moi
local pourMoiBlockedSourceCategories = {
    pour_moi = true, vip = true, daily_reward = true
}

-- Récupère le pool depuis le serveur (avec source label/prix hydraté)
local function fetchPourMoiPool()
    local result = TriggerServerCallback('paidshop:adminGetPourMoiPool')
    if result and result.success and type(result.pool) == "table" then
        pourMoiPoolCache = result.pool
    else
        pourMoiPoolCache = {}
    end
    return pourMoiPoolCache
end

local function isInPourMoiPool(sourceCategory, sourceSpawnName)
    for _, ref in ipairs(pourMoiPoolCache) do
        if ref.sourceCategory == sourceCategory and ref.sourceSpawnName == sourceSpawnName then
            return true
        end
    end
    return false
end

-- Type options for crate items
local crateTypeOptions = {"vehicle", "weapon", "item", "money"}
local crateTypeLabels = {
    vehicle = "Véhicule",
    weapon = "Arme",
    item = "Item",
    money = "Argent"
}

-- Fetch shop data from server
local function fetchShopData()
    local shopData = TriggerServerCallback('paidshop:getShopData')
    if shopData then
        PaidShopCache.categories = shopData.categories or {}
        PaidShopCache.items = shopData.items or {}
    end
    return shopData
end

-- Get category label by id
local function getCategoryLabel(categoryId)
    for _, cat in ipairs(PaidShopCache.categories) do
        if cat.id == categoryId then
            return cat.label
        end
    end
    return categoryId
end

-- Get items count for a category
local function getItemsCount(categoryId)
    if PaidShopCache.items[categoryId] then
        return #PaidShopCache.items[categoryId]
    end
    return 0
end

-- Helper: count pack content items
local function countPackContent(content)
    if not content then return 0 end
    local count = 0
    if content.vehicles then count = count + #content.vehicles end
    if content.weapons then count = count + #content.weapons end
    if content.items then count = count + #content.items end
    if content.money and content.money > 0 then count = count + 1 end
    if content.spacecoins and content.spacecoins > 0 then count = count + 1 end
    return count
end

-- Helper: ensure pack content structure exists
local function ensurePackContent(item)
    if not item.content then
        item.content = {}
    end
    if not item.content.vehicles then item.content.vehicles = {} end
    if not item.content.weapons then item.content.weapons = {} end
    if not item.content.items then item.content.items = {} end
    return item.content
end

-- Helper: ensure possible_items structure exists
local function ensurePossibleItems(item)
    if not item.possible_items then
        item.possible_items = {}
    end
    return item.possible_items
end

-- Helper: build pack content menu entries on a given menu, referencing a given item
-- Temp storage for new pack element being configured via sub-menu
local newPackElement = {}
-- Reference to the parent item being edited (for adding the pack element to)
local packParentItem = nil

-- Pack element type options
local packElementTypes = {"vehicle", "weapon", "item"}
local packElementTypeLabels = {
    vehicle = "Véhicule",
    weapon = "Arme",
    item = "Item"
}

-- ==========================================
--  Weapon / Item pickers (shared helpers)
-- ==========================================

local pickerSearchText = ""

local weaponCategoryOrder = {
    "PISTOLETS", "SMG", "FUSILS D'ASSAUT", "SHOTGUNS",
    "SNIPERS", "MITRAILLEUSES", "LOURDES", "LANCABLES", "AUTRES",
}

local function getWeaponCategory(name)
    local upper = string.upper(name)
    if string.find(upper, "PISTOL") or string.find(upper, "REVOLVER") or string.find(upper, "STUNGUN") or string.find(upper, "STUNROD") then
        return "PISTOLETS"
  end
    if string.find(upper, "SHOTGUN") or string.find(upper, "MUSKET") then
        return "SHOTGUNS"
  end
    if string.find(upper, "SMG") or upper == "WEAPON_COMBATPDW" or upper == "WEAPON_MACHINEPISTOL" or upper == "WEAPON_MINISMG" or upper == "WEAPON_TECPISTOL" then
        return "SMG"
  end
    if string.find(upper, "SNIPER") or string.find(upper, "MARKSMAN") or string.find(upper, "PRECISION") then
        return "SNIPERS"
  end
    if upper == "WEAPON_MG" or upper == "WEAPON_COMBATMG" or upper == "WEAPON_COMBATMG_MK2" or upper == "WEAPON_GUSENBERG" then
        return "MITRAILLEUSES"
  end
    if string.find(upper, "LAUNCHER") or string.find(upper, "MINIGUN") or string.find(upper, "RPG") or string.find(upper, "RAILGUN") or string.find(upper, "FIREWORK") then
        return "LOURDES"
  end
    if string.find(upper, "RIFLE") then
        return "FUSILS D'ASSAUT"
  end
    if string.find(upper, "GRENADE") or string.find(upper, "MOLOTOV") or string.find(upper, "BZGAS") or string.find(upper, "SMOKEGRENADE") or string.find(upper, "FLARE") or string.find(upper, "PROXMINE") or string.find(upper, "STICKYBOMB") or string.find(upper, "BALL") or string.find(upper, "SNOWBALL") or string.find(upper, "PIPEBOMB") then
        return "LANCABLES"
  end
    return "AUTRES"
end

-- Pack elements store the spawn name under `.model`; crate items use `.spawnName`.
local function buildWeaponPickerMenu(menu, getState, field, excludeSet)
    menu.ClearItems()
    menu.Separator("RECHERCHE")

    menu.Button("Rechercher une arme", pickerSearchText ~= "" and ("Recherche: " .. pickerSearchText) or nil,
        nil, "search", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Rechercher une arme", pickerSearchText)
            if input then
                pickerSearchText = input
                menu.refresh()
            end
        end)

    if pickerSearchText ~= "" then
        menu.Button("Effacer la recherche", nil, nil, "trash", false, function()
            pickerSearchText = ""
          menu.refresh()
        end)
    end

    local categorized = {}
    for _, cat in ipairs(weaponCategoryOrder) do categorized[cat] = {} end

    for itemName, item in pairs(VFW.Items) do
        if item.type == "weapons" and (not excludeSet or not excludeSet[itemName]) then
            local cat = getWeaponCategory(itemName)
            if not categorized[cat] then categorized[cat] = {} end
            table.insert(categorized[cat], { name = itemName, label = item.label or itemName })
        end
    end

    for _, cat in ipairs(weaponCategoryOrder) do
        table.sort(categorized[cat], function(a, b) return a.label < b.label end)
    end

    local state = getState()
    local searchLower = pickerSearchText ~= "" and string.lower(pickerSearchText) or nil
    local selectedName = state and state[field] or nil

    for _, cat in ipairs(weaponCategoryOrder) do
        local list = categorized[cat] or {}
        local filtered = list
        if searchLower then
            filtered = {}
            for _, w in ipairs(list) do
                if string.find(string.lower(w.label), searchLower, 1, true) or string.find(string.lower(w.name), searchLower, 1, true) then
                    table.insert(filtered, w)
                end
            end
        end

        if #filtered > 0 then
            menu.Separator(cat)
            for _, w in ipairs(filtered) do
                local isSelected = selectedName == w.name
                menu.Button(w.label, w.name, nil, isSelected and "check" or "empty", false, function()
                    local target = getState()
                    if target then
                        target[field] = w.name
                        if not target.name or target.name == "" then
                            target.name = w.label
                        end
                    end
                    menu.close()
                    menu.parent.open()
                end)
            end
        end
    end
end

local function buildItemPickerMenu(menu, getState, field, namePrefix, excludeSet)
    menu.ClearItems()
    menu.Separator("RECHERCHE")

    menu.Button("Rechercher un item", pickerSearchText ~= "" and ("Recherche: " .. pickerSearchText) or nil,
        nil, "search", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Rechercher un item", pickerSearchText)
            if input then
                pickerSearchText = input
                menu.refresh()
            end
        end)

    if pickerSearchText ~= "" then
        menu.Button("Effacer la recherche", nil, nil, "trash", false, function()
            pickerSearchText = ""
          menu.refresh()
        end)
    end

    local prefixLower = namePrefix and string.lower(namePrefix) or nil
    local prefixLen = prefixLower and string.len(prefixLower) or 0

    local byType = {}
    for itemName, item in pairs(VFW.Items) do
        if item.type and item.type ~= "weapons" and item.type ~= "clothes" and item.type ~= "tint" then
            if not prefixLower or string.sub(string.lower(itemName), 1, prefixLen) == prefixLower then
                if not excludeSet or not excludeSet[itemName] then
                    local t = string.upper(item.type)
                    byType[t] = byType[t] or {}
                    table.insert(byType[t], { name = itemName, label = item.label or itemName })
                end
            end
        end
    end

    local typeList = {}
    for t in pairs(byType) do table.insert(typeList, t) end
    table.sort(typeList)

    for _, t in ipairs(typeList) do
        table.sort(byType[t], function(a, b) return a.label < b.label end)
    end

    local state = getState()
    local searchLower = pickerSearchText ~= "" and string.lower(pickerSearchText) or nil
    local selectedName = state and state[field] or nil

    for _, t in ipairs(typeList) do
        local list = byType[t]
        local filtered = list
        if searchLower then
            filtered = {}
            for _, it in ipairs(list) do
                if string.find(string.lower(it.label), searchLower, 1, true) or string.find(string.lower(it.name), searchLower, 1, true) then
                    table.insert(filtered, it)
                end
            end
        end

        if #filtered > 0 then
            menu.Separator(t)
            for _, it in ipairs(filtered) do
                local isSelected = selectedName == it.name
                menu.Button(it.label, it.name, nil, isSelected and "check" or "empty", false, function()
                    local target = getState()
                    if target then
                        target[field] = it.name
                        if not target.name or target.name == "" then
                            target.name = it.label
                        end
                    end
                    menu.close()
                    menu.parent.open()
                end)
            end
        end
    end
end

local function buildPackContentMenu(menu, item, addSubMenu)
    local content = ensurePackContent(item)

    menu.Separator("VEHICULES (" .. #content.vehicles .. ")")

    for i, veh in ipairs(content.vehicles) do
        menu.Button(
            veh.name or veh.model,
            "Modele: " .. (veh.model or "N/A"),
            nil, "trash", false,
            function()
                table.remove(content.vehicles, i)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Pack',
                    message = "Véhicule retiré"
              })
                menu.refresh()
            end
        )
    end

    menu.Separator("ARMES (" .. #content.weapons .. ")")

    for i, wpn in ipairs(content.weapons) do
        menu.Button(
            wpn.name or wpn.model,
            "Modèle : " .. (wpn.model or "N/A") .. " | Munitions : " .. (wpn.ammo or 0),
            nil, "trash", false,
            function()
                table.remove(content.weapons, i)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Pack',
                    message = "Arme retiree"
              })
                menu.refresh()
            end
        )
    end

    menu.Separator("ITEMS (" .. #content.items .. ")")

    for i, itm in ipairs(content.items) do
        menu.Button(
            itm.name or itm.item,
            "Item: " .. (itm.item or "N/A") .. " | Qte: " .. (itm.count or 1),
            nil, "trash", false,
            function()
                table.remove(content.items, i)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Pack',
                    message = "Item retiré"
              })
                menu.refresh()
            end
        )
    end

    menu.Separator("BONUS")

    local moneyAmount = content.money or 0
    menu.Button("Argent: " .. VFW.Math.FormatMoney(moneyAmount), "Cliquez pour modifier", nil, "chevron", false, function()
        local amount = VFW.Nui.KeyboardInput(true, "Montant d'argent (0 = aucun)", tostring(moneyAmount))
        local amountNum = tonumber(amount)
        if amountNum and amountNum >= 0 then
            content.money = amountNum > 0 and amountNum or nil
            menu.refresh()
        end
    end)

    local spacecoinsAmount = content.spacecoins or 0
    menu.Button("Coins: " .. spacecoinsAmount, "Cliquez pour modifier", nil, "chevron", false, function()
        local amount = VFW.Nui.KeyboardInput(true, "Montant de Coins (0 = aucun)", tostring(spacecoinsAmount))
        local amountNum = tonumber(amount)
        if amountNum and amountNum >= 0 then
            content.spacecoins = amountNum > 0 and amountNum or nil
            menu.refresh()
        end
    end)

    menu.Separator("AJOUTER")

    menu.Button("+ Ajouter un element", "Vehicule, arme ou item", nil, "chevron", false, function()
        newPackElement = {}
        packParentItem = item
    end, addSubMenu)
end

-- Shared builder for "add pack element" sub-menus
local function buildAddPackElementMenu(menu, weaponPickerMenu, itemPickerMenu)
    menu.ClearItems()

    menu.Separator("NOUVEL ELEMENT DE PACK")

    -- Type (List selector)
    local typeLabelsArray = {}
    for _, t in ipairs(packElementTypes) do
        table.insert(typeLabelsArray, packElementTypeLabels[t] or t)
    end
    local selectedTypeIndex = 1
    if newPackElement.type then
        for i, t in ipairs(packElementTypes) do
            if t == newPackElement.type then
                selectedTypeIndex = i
                break
            end
        end
    else
        newPackElement.type = packElementTypes[1]
    end

    menu.List(
        "Type",
        "Fleches gauche/droite pour changer",
        false,
        typeLabelsArray,
        selectedTypeIndex,
        function(index)
            newPackElement.type = packElementTypes[index]
            menu.refresh()
        end
    )

    -- Name
    menu.Button("Nom: " .. (newPackElement.name or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom de l'element", newPackElement.name or "")
        if name and string.len(string.gsub(name, "%s+", "")) > 0 then
            newPackElement.name = name
            menu.refresh()
        end
    end)

    -- Model/SpawnName
    if newPackElement.type == "weapon" and weaponPickerMenu then
        local current = newPackElement.model or ""
      local currentLabel = current ~= "" and ((VFW.Items[current] and VFW.Items[current].label) or current) or "Non définie"
      menu.Button("Arme: " .. currentLabel, "Choisir une arme dans la liste", nil, "chevron", false,
            function() pickerSearchText = "" end,
            weaponPickerMenu)
    elseif newPackElement.type == "item" and itemPickerMenu then
        local current = newPackElement.model or ""
      local currentLabel = current ~= "" and ((VFW.Items[current] and VFW.Items[current].label) or current) or "Non défini"
      menu.Button("Item: " .. currentLabel, "Choisir un item dans la liste", nil, "chevron", false,
            function() pickerSearchText = "" end,
            itemPickerMenu)
    else
        -- Vehicle (or fallback): manual model input
        local modelLabel = "Modele"
      local modelPlaceholder = "ex: sultan"
      menu.Button(modelLabel .. ": " .. (newPackElement.model or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
            local model = VFW.Nui.KeyboardInput(true, modelLabel .. " (" .. modelPlaceholder .. ")", newPackElement.model or "")
            if model and string.len(string.gsub(model, "%s+", "")) > 0 then
                newPackElement.model = model
                menu.refresh()
            end
        end)
    end

    -- Ammo (weapons only)
    if newPackElement.type == "weapon" then
        menu.Button("Munitions : " .. (newPackElement.ammo or 100), "Cliquez pour définir", nil, "chevron", false, function()
            local ammo = VFW.Nui.KeyboardInput(true, "Quantité de munitions", newPackElement.ammo and tostring(newPackElement.ammo) or "100")
            local ammoNum = tonumber(ammo)
            if ammoNum and ammoNum >= 0 then
                newPackElement.ammo = ammoNum
                menu.refresh()
            end
        end)
    end

    -- Count (items only)
    if newPackElement.type == "item" then
        menu.Button("Quantité : " .. (newPackElement.count or 1), "Cliquez pour définir", nil, "chevron", false, function()
            local count = VFW.Nui.KeyboardInput(true, "Quantité", newPackElement.count and tostring(newPackElement.count) or "1")
            local countNum = tonumber(count)
            if countNum and countNum > 0 then
                newPackElement.count = countNum
                menu.refresh()
            end
        end)
    end

    -- Image (optional)
    local imageStatus = newPackElement.image and newPackElement.image ~= "" and "Définie" or "Non définie"
  menu.Button("Image: " .. imageStatus, "Optionnel", nil, "chevron", false, function()
        local image = VFW.Nui.KeyboardInput(true, "URL de l'image (optionnel)", newPackElement.image or "")
        if image then
            newPackElement.image = image
            menu.refresh()
        end
    end)

    menu.Separator("VALIDER")

    menu.Button("AJOUTER L'ELEMENT", "Cliquez pour ajouter au pack", nil, "check", false, function()
        -- Validate
        if not newPackElement.name or string.len(string.gsub(newPackElement.name or "", "%s+", "")) == 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pack', message = "Veuillez définir le nom" })
            return
        end
        if not newPackElement.model or string.len(string.gsub(newPackElement.model or "", "%s+", "")) == 0 then
            local label = newPackElement.type == "item" and "spawn name" or "modele"
          VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pack', message = "Veuillez définir le " .. label })
            return
        end

        if not packParentItem then return end
        local content = ensurePackContent(packParentItem)

        if newPackElement.type == "vehicle" then
            table.insert(content.vehicles, {
                name = newPackElement.name,
                model = newPackElement.model,
                image = newPackElement.image or ""
          })
        elseif newPackElement.type == "weapon" then
            table.insert(content.weapons, {
                name = newPackElement.name,
                model = newPackElement.model,
                ammo = newPackElement.ammo or 100,
                image = newPackElement.image or ""
          })
        elseif newPackElement.type == "item" then
            table.insert(content.items, {
                name = newPackElement.name,
                item = newPackElement.model,
                count = newPackElement.count or 1,
                image = newPackElement.image or ""
          })
        end

        local typeLabel = packElementTypeLabels[newPackElement.type] or newPackElement.type
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Pack',
            message = typeLabel .. " ajouté: " .. newPackElement.name
        })

        newPackElement = {}
        menu.close()
        menu.parent.open()
    end)
end

-- Helper: build crate possible items menu entries on a given menu, referencing a given item
-- Temp storage for new crate item being configured via sub-menu
local newCrateItem = {}
-- Reference to the parent item being edited (for adding the crate item to)
local crateParentItem = nil

local function buildCrateItemsMenu(menu, item, addSubMenu)
    local possibleItems = ensurePossibleItems(item)

    menu.Separator("ITEMS POSSIBLES (" .. #possibleItems .. ")")

    for i, pi in ipairs(possibleItems) do
        local rarityLabel = rarityLabels[pi.rarity] or pi.rarity or "?"
      local typeLabel = crateTypeLabels[pi.type] or pi.type or "?"
      menu.Button(
            pi.name or pi.spawnName or "Item " .. i,
            typeLabel .. " | " .. rarityLabel .. " | " .. (pi.chance or 0) .. "%",
            nil, "trash", false,
            function()
                table.remove(possibleItems, i)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Caisse',
                    message = "Item possible retiré"
              })
                menu.refresh()
            end
        )
    end

    menu.Separator("AJOUTER")

    menu.Button("+ Ajouter un item possible", "Configurer un nouvel item de caisse", nil, "chevron", false, function()
        newCrateItem = {}
        crateParentItem = item
    end, addSubMenu)
end

-- Shared builder for "add crate item" sub-menus
local function buildAddCrateItemMenu(menu, parentMenu, weaponPickerMenu, itemPickerMenu)
    menu.ClearItems()

    menu.Separator("NOUVEL ITEM DE CAISSE")

    -- Type (List selector)
    local typeLabelsArray = {}
    for _, t in ipairs(crateTypeOptions) do
        table.insert(typeLabelsArray, crateTypeLabels[t] or t)
    end
    local selectedTypeIndex = 1
    if newCrateItem.type then
        for i, t in ipairs(crateTypeOptions) do
            if t == newCrateItem.type then
                selectedTypeIndex = i
                break
            end
        end
    else
        newCrateItem.type = crateTypeOptions[1]
    end

    menu.List(
        "Type",
        "Fleches gauche/droite pour changer",
        false,
        typeLabelsArray,
        selectedTypeIndex,
        function(index)
            newCrateItem.type = crateTypeOptions[index]
            menu.refresh()
        end
    )

    -- Name
    menu.Button("Nom: " .. (newCrateItem.name or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom de l'item", newCrateItem.name or "")
        if name and string.len(string.gsub(name, "%s+", "")) > 0 then
            newCrateItem.name = name
            menu.refresh()
        end
    end)

    -- SpawnName (hidden for money type)
    if newCrateItem.type == "weapon" and weaponPickerMenu then
        local current = newCrateItem.spawnName or ""
      local currentLabel = current ~= "" and ((VFW.Items[current] and VFW.Items[current].label) or current) or "Non définie"
      menu.Button("Arme: " .. currentLabel, "Choisir une arme dans la liste", nil, "chevron", false,
            function() pickerSearchText = "" end,
            weaponPickerMenu)
    elseif newCrateItem.type == "item" and itemPickerMenu then
        local current = newCrateItem.spawnName or ""
      local currentLabel = current ~= "" and ((VFW.Items[current] and VFW.Items[current].label) or current) or "Non défini"
      menu.Button("Item: " .. currentLabel, "Choisir un item dans la liste", nil, "chevron", false,
            function() pickerSearchText = "" end,
            itemPickerMenu)
    elseif newCrateItem.type ~= "money" then
        -- Vehicle (or fallback): manual spawn name input
        menu.Button("SpawnName: " .. (newCrateItem.spawnName or "Non défini"), "Identifiant de spawn", nil, "chevron", false, function()
            local spawnName = VFW.Nui.KeyboardInput(true, "Spawn name", newCrateItem.spawnName or "")
            if spawnName and string.len(string.gsub(spawnName, "%s+", "")) > 0 then
                newCrateItem.spawnName = spawnName
                menu.refresh()
            end
        end)
    end

    -- Rarity (List selector)
    local rarityLabelsArray = {}
    for _, r in ipairs(rarityOptions) do
        table.insert(rarityLabelsArray, rarityLabels[r] or r)
    end
    local selectedRarityIndex = 1
    if newCrateItem.rarity then
        for i, r in ipairs(rarityOptions) do
            if r == newCrateItem.rarity then
                selectedRarityIndex = i
                break
            end
        end
    else
        newCrateItem.rarity = rarityOptions[1]
    end

    menu.List(
        "Rareté",
        "Fleches gauche/droite pour changer",
        false,
        rarityLabelsArray,
        selectedRarityIndex,
        function(index)
            newCrateItem.rarity = rarityOptions[index]
        end
    )

    -- Chance
    menu.Button("Chance: " .. (newCrateItem.chance and (newCrateItem.chance .. "%") or "Non définie"), "Probabilité de drop", nil, "chevron", false, function()
        local chanceStr = VFW.Nui.KeyboardInput(true, "Chance en % (ex: 25)", newCrateItem.chance and tostring(newCrateItem.chance) or "10")
        local chance = tonumber(chanceStr)
        if chance and chance > 0 and chance <= 100 then
            newCrateItem.chance = chance
            menu.refresh()
        elseif chanceStr then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Caisse', message = "La chance doit être entre 1 et 100" })
        end
    end)

    -- Amount/count
    local amountLabel = newCrateItem.type == "money" and "Montant" or "Quantité"
  local amountValue = newCrateItem.type == "money" and newCrateItem.amount or newCrateItem.count
    menu.Button(amountLabel .. ": " .. (amountValue or 1), "Cliquez pour définir", nil, "chevron", false, function()
        local amountStr = VFW.Nui.KeyboardInput(true, amountLabel, amountValue and tostring(amountValue) or "1")
        local amount = tonumber(amountStr)
        if amount and amount > 0 then
            if newCrateItem.type == "money" then
                newCrateItem.amount = amount
                newCrateItem.count = nil
            else
                newCrateItem.count = amount
                newCrateItem.amount = nil
            end
            menu.refresh()
        end
    end)

    -- Image (optional)
    local imageStatus = newCrateItem.image and newCrateItem.image ~= "" and "Définie" or "Non définie"
  menu.Button("Image: " .. imageStatus, "Optionnel", nil, "chevron", false, function()
        local image = VFW.Nui.KeyboardInput(true, "URL de l'image (optionnel)", newCrateItem.image or "")
        if image then
            newCrateItem.image = image
            menu.refresh()
        end
    end)

    menu.Separator("VALIDER")

    menu.Button("AJOUTER L'ITEM", "Cliquez pour ajouter a la caisse", nil, "check", false, function()
        -- Validate
        if not newCrateItem.name or string.len(string.gsub(newCrateItem.name or "", "%s+", "")) == 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Caisse', message = "Veuillez définir le nom" })
            return
        end
        if newCrateItem.type ~= "money" and (not newCrateItem.spawnName or string.len(string.gsub(newCrateItem.spawnName or "", "%s+", "")) == 0) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Caisse', message = "Veuillez définir le spawn name" })
            return
        end
        if not newCrateItem.chance or newCrateItem.chance <= 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Caisse', message = "Veuillez définir la chance" })
            return
        end

        -- Build the item
        local possibleItem = {
            name = newCrateItem.name,
            type = newCrateItem.type,
            spawnName = newCrateItem.spawnName or "",
            image = newCrateItem.image or "",
            rarity = newCrateItem.rarity or "common",
            chance = newCrateItem.chance
        }
        if newCrateItem.type == "money" then
            possibleItem.amount = newCrateItem.amount or 1
        else
            possibleItem.count = newCrateItem.count or 1
        end

        -- Add to parent item
        if crateParentItem then
            local possibleItems = ensurePossibleItems(crateParentItem)
            table.insert(possibleItems, possibleItem)
        end

        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Caisse',
            message = "Item ajouté: " .. newCrateItem.name .. " (" .. (rarityLabels[newCrateItem.rarity] or newCrateItem.rarity) .. ")"
      })

        -- Reset and go back to the loot list (parent) so the user can chain more adds
        newCrateItem = {}
        menu.close()
        if parentMenu then parentMenu.refresh() end
    end)
end

-- ==========================================
--          MAIN MENU
-- ==========================================

StaffMenu.builderPaidShop.OnOpen(function()
    StaffMenu.builderPaidShop.ClearItems()

    -- Reset global state
    selectedCategory = nil
    selectedItem = nil
    newItem = {}

    -- Sync data from server
    fetchShopData()

    StaffMenu.builderPaidShop.Separator("CATALOGUE")

    StaffMenu.builderPaidShop.Button("GERER LES ITEMS", "Ajouter, modifier, supprimer des items", nil, "chevron", false, function()
    end, StaffMenu.paidShopItems)

    StaffMenu.builderPaidShop.Button("ACTIVER / DÉSACTIVER CATÉGORIES", "Masquer une catégorie pour tous les joueurs", nil, "chevron", false, function()
    end, StaffMenu.paidShopCategoryToggle)

    StaffMenu.builderPaidShop.Separator("ÉCONOMIE")

    StaffMenu.builderPaidShop.Button("GERER LES COINS", "Ajouter/Retirer des Coins", nil, "chevron", false, function()
    end, StaffMenu.paidShopCoins)

    StaffMenu.builderPaidShop.Button("DONNER UN ARTICLE", "Offrir un article a un joueur", nil, "chevron", false, function()
    end, StaffMenu.paidShopGiveItem)

    StaffMenu.builderPaidShop.Separator("RÉCOMPENSES")

    StaffMenu.builderPaidShop.Button("RÉCOMPENSES QUOTIDIENNES", "Gérer les daily rewards (véhicule, argent, item)", nil, "chevron", false, function()
    end, StaffMenu.paidShopDailyRewards)

    StaffMenu.builderPaidShop.Button("BONUS QUOTIDIEN 7 JOURS", "Configurer la récompense de chaque jour du streak", nil, "chevron", false, function()
    end, StaffMenu.paidShopDailyStreak)

    StaffMenu.builderPaidShop.Separator("SCANNER")

    StaffMenu.builderPaidShop.Button("CAISSES AFFICHÉES DANS LE SCANNER", "Configurer les caisses du scanner boutique", nil, "chevron", false, function()
    end, StaffMenu.paidShopDisplayedCases)

end)

-- ==========================================
--          ITEMS MENU (Categories)
-- ==========================================

StaffMenu.paidShopItems.OnOpen(function()
    StaffMenu.paidShopItems.ClearItems()

    -- Refresh data
    fetchShopData()

    StaffMenu.paidShopItems.Separator("CATEGORIES")

    for _, category in ipairs(PaidShopCache.categories) do
        -- Skip vip category for item management
        if category.id ~= "vip" then
            local itemCount = getItemsCount(category.id)
            local icon = category.icon or "fa-box"

          StaffMenu.paidShopItems.Button(
                string.upper(category.label),
                itemCount .. " items",
                nil,
                "chevron",
                false,
                function()
                    selectedCategory = category.id
                end,
                StaffMenu.paidShopItemCategory
            )
        end
    end

    StaffMenu.paidShopItems.Separator("ACTIONS")

    StaffMenu.paidShopItems.Button("+ AJOUTER UN ITEM", "Creer un nouvel item dans la boutique", nil, "chevron", false, function()
        newItem = {}
        selectedCategory = nil
    end, StaffMenu.paidShopAddItem)
end)

-- ==========================================
--          CATEGORY ITEMS LIST
-- ==========================================

StaffMenu.paidShopItemCategory.OnOpen(function()
    StaffMenu.paidShopItemCategory.ClearItems()

    if not selectedCategory then
        StaffMenu.paidShopItemCategory.Button("Erreur", "Aucune catégorie sélectionnée", nil, nil, true, function() end)
        return
    end

    -- POUR MOI : gestion du pool de réfs (sourceCategory + sourceSpawnName + rarity + reduction)
    if selectedCategory == "pour_moi" then
        fetchPourMoiPool()

        StaffMenu.paidShopItemCategory.Separator("POOL POUR MOI (" .. #pourMoiPoolCache .. " items)")

        if #pourMoiPoolCache == 0 then
            StaffMenu.paidShopItemCategory.Button("Pool vide", "Ajoute des items via le bouton ci-dessous", nil, nil, true, function() end)
        else
            for _, ref in ipairs(pourMoiPoolCache) do
                local label    = ref.sourceLabel or ref.sourceSpawnName
                local rarity   = rarityLabels[ref.rarity] or ref.rarity
                local subTitle = string.format("%s · %s · -%d%% (%d SC)",
                    string.upper(ref.sourceCategory or "?"), rarity,
                    ref.reductionPercent or 0, ref.computedPrice or 0)
                if ref.sourceMissing then
                    subTitle = "[ITEM SOURCE INTROUVABLE] " .. subTitle
                end
                local r = ref  -- capture pour la closure
                StaffMenu.paidShopItemCategory.Button(label, subTitle, nil, "chevron", false, function()
                    selectedPourMoiRef = r
                end, StaffMenu.paidShopPourMoiEdit)
            end
        end

        StaffMenu.paidShopItemCategory.Separator("ACTIONS")
        StaffMenu.paidShopItemCategory.Button("+ AJOUTER UN ITEM AU POOL", "Choisir item source + rareté + réduction", nil, "chevron", false, function()
            newPourMoiRef = {}
        end, StaffMenu.paidShopPourMoiAdd)
        return
    end

    local items = PaidShopCache.items[selectedCategory] or {}
    local categoryLabel = getCategoryLabel(selectedCategory)

    StaffMenu.paidShopItemCategory.Separator("ITEMS - " .. string.upper(categoryLabel))

    if #items == 0 then
        StaffMenu.paidShopItemCategory.Button("Aucun item", "Cette catégorie est vide", nil, nil, true, function() end)
    else
        for _, item in ipairs(items) do
            local priceText = item.price and (item.price .. " Coins") or "N/A"
          if item.promoPercent and item.promoPercent > 0 then
                local discounted = math.floor(item.price * (1 - item.promoPercent / 100))
                priceText = priceText .. " (-" .. item.promoPercent .. "% = " .. discounted .. ")"
          end
            StaffMenu.paidShopItemCategory.Button(
                item.name or item.spawnName,
                item.spawnName .. " | " .. priceText,
                nil,
                "chevron",
                false,
                function()
                    selectedItem = item
                end,
                StaffMenu.paidShopItemEdit
            )
        end
    end
end)

-- ==========================================
--          EDIT ITEM MENU
-- ==========================================

StaffMenu.paidShopItemEdit.OnOpen(function()
    StaffMenu.paidShopItemEdit.ClearItems()

    if not selectedItem then
        StaffMenu.paidShopItemEdit.Button("Erreur", "Aucun item sélectionné", nil, nil, true, function() end)
        return
    end

    StaffMenu.paidShopItemEdit.Separator("ITEM: " .. (selectedItem.name or selectedItem.spawnName))

    -- Nom
    StaffMenu.paidShopItemEdit.Button("Nom: " .. (selectedItem.name or "N/A"), "Cliquez pour modifier", nil, "chevron", false, function()
        local newName = VFW.Nui.KeyboardInput(true, "Nouveau nom", selectedItem.name or "")
        if newName and string.len(string.gsub(newName, "%s+", "")) > 0 then
            selectedItem.name = newName
            StaffMenu.paidShopItemEdit.refresh()
        elseif newName then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Boutique',
                message = "Le nom ne peut pas être vide"
          })
        end
    end)

    -- SpawnName (lecture seule, hidden for caisses and packs since it's auto-generated)
    if selectedCategory ~= "caisses" and selectedCategory ~= "packs" then
        local spawnLabel = selectedCategory == "peds" and "Modèle du ped: " or "SpawnName: "
        local spawnDesc = selectedCategory == "peds" and "Nom ou hash du ped (non modifiable)" or "Identifiant unique (non modifiable)"
        StaffMenu.paidShopItemEdit.Button(spawnLabel .. (selectedItem.spawnName or "N/A"), spawnDesc, nil, nil, true, function() end)
    end

    -- Prix
    StaffMenu.paidShopItemEdit.Button("Prix: " .. (selectedItem.price or 0) .. " Coins", "Cliquez pour modifier", nil, "chevron", false, function()
        local newPrice = VFW.Nui.KeyboardInput(true, "Nouveau prix (Coins)", tostring(selectedItem.price or 0))
        if newPrice and tonumber(newPrice) then
            local priceNum = tonumber(newPrice)
            if priceNum <= 0 then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Boutique',
                    message = "Le prix doit être supérieur à 0"
              })
                return
            end
            selectedItem.price = priceNum
            StaffMenu.paidShopItemEdit.refresh()
        end
    end)

    -- Promotion
    local hasPromo = selectedItem.promoPercent and selectedItem.promoPercent > 0
    local promoLabel, promoDesc
    if hasPromo then
        local discountedPrice = math.floor(selectedItem.price * (1 - selectedItem.promoPercent / 100))
        promoLabel = "Promotion: -" .. selectedItem.promoPercent .. "% (" .. discountedPrice .. " Coins)"
      promoDesc = "Prix original: " .. selectedItem.price .. " | Tapez 0 pour retirer"
  else
        promoLabel = "Promotion: Aucune"
      promoDesc = "Cliquez pour mettre en promotion"
  end
    StaffMenu.paidShopItemEdit.Button(promoLabel, promoDesc, nil, "chevron", false, function()
        local currentPercent = hasPromo and tostring(selectedItem.promoPercent) or ""
      local input = VFW.Nui.KeyboardInput(true, "Pourcentage de reduction (0 = retirer)", currentPercent)
        if input and tonumber(input) then
            local percent = tonumber(input)
            if percent <= 0 then
                selectedItem.promoPercent = nil
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Boutique',
                    message = "Promotion retirée"
              })
            elseif percent >= 100 then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique',
                    message = "Le pourcentage doit être entre 1 et 99"
              })
                return
            else
                selectedItem.promoPercent = percent
                local discounted = math.floor((selectedItem.price or 0) * (1 - percent / 100))
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Boutique',
                    message = "Promotion activée: -" .. percent .. "% (" .. discounted .. " Coins)"
              })
            end
            StaffMenu.paidShopItemEdit.refresh()
        end
    end)

    -- Mise en avant (uniquement pour la catégorie vehicules)
    -- Marque l'item comme hero card de la catégorie ; un seul featured par catégorie.
    if selectedCategory == "vehicules" then
        local isFeatured = selectedItem.featured == true
        local featuredLabel = isFeatured and ":star: Mis en avant, cliquez pour retirer" or "Mettre en avant ce véhicule"
      local featuredDesc = isFeatured
            and "Ce véhicule est actuellement affiché en hero. Un seul peut être mis en avant à la fois."
          or "Affiche ce véhicule en hero card (grand format) en haut de la catégorie."
      StaffMenu.paidShopItemEdit.Button(featuredLabel, featuredDesc, nil, "chevron", false, function()
            if isSaving then return end
            isSaving = true
            local targetSpawn = isFeatured and "" or (selectedItem.spawnName or "")
            local result, message = TriggerServerCallback('paidshop:setFeaturedItem', selectedCategory, targetSpawn)
            isSaving = false
            if result then
                -- Met à jour le cache local pour rester cohérent sans re-fetch (qui écraserait les éditions in-memory)
                if PaidShopCache.items[selectedCategory] then
                    for _, it in ipairs(PaidShopCache.items[selectedCategory]) do
                        it.featured = nil
                    end
                end
                if not isFeatured then
                    selectedItem.featured = true
                else
                    selectedItem.featured = nil
                end
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Boutique',
                    message = message or (isFeatured and "Mise en avant retirée" or "Véhicule mis en avant")
                })
                StaffMenu.paidShopItemEdit.refresh()
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique',
                    message = message or "Erreur lors de la mise à jour"
              })
            end
        end)
    end

    -- Image
    local imageStatus = selectedItem.image and "Définie" or "Non définie"
  StaffMenu.paidShopItemEdit.Button("Image: " .. imageStatus, "Cliquez pour modifier l'URL", nil, "chevron", false, function()
        local newImage = VFW.Nui.KeyboardInput(true, "URL de l'image", selectedItem.image or "")
        if newImage then
            selectedItem.image = newImage
            StaffMenu.paidShopItemEdit.refresh()
        end
    end)

    if selectedItem.image and selectedItem.image ~= "" then
        StaffMenu.paidShopItemEdit.Imagebox(selectedItem.image, nil)
    end

    -- Description
    local descStatus = selectedItem.description and "Définie" or "Non définie"
  StaffMenu.paidShopItemEdit.Button("Description: " .. descStatus, selectedItem.description or "Cliquez pour modifier", nil, "chevron", false, function()
        local newDesc = VFW.Nui.KeyboardInput(true, "Description", selectedItem.description or "")
        if newDesc then
            selectedItem.description = newDesc
            StaffMenu.paidShopItemEdit.refresh()
        end
    end)

    -- Tags
    local currentTags = selectedItem.tags or {}
    local tagsLabel = #currentTags > 0 and table.concat(currentTags, ", ") or "Aucun"
  StaffMenu.paidShopItemEdit.Button("Tags: " .. tagsLabel, "Cliquez pour modifier (separer par des virgules)", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Tags (separes par des virgules)", table.concat(currentTags, ", "))
        if input then
            local tags = {}
            for tag in string.gmatch(input, "[^,]+") do
                local trimmed = tag:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then
                    tags[#tags + 1] = trimmed
                end
            end
            selectedItem.tags = tags
            StaffMenu.paidShopItemEdit.refresh()
        end
    end)

    -- Pack content button (only for packs category)
    if selectedCategory == "packs" then
        local contentCount = countPackContent(selectedItem.content)
        StaffMenu.paidShopItemEdit.Separator("CONTENU DU PACK")
        StaffMenu.paidShopItemEdit.Button(
            "Contenu du pack (" .. contentCount .. " elements)",
            "Gerer vehicules, armes, items, argent, Coins",
            nil, "chevron", false,
            function() end,
            StaffMenu.paidShopEditPackContent
        )
    end

    -- Crate possible items button (only for caisses category)
    if selectedCategory == "caisses" then
        local possibleCount = selectedItem.possible_items and #selectedItem.possible_items or 0
        StaffMenu.paidShopItemEdit.Separator("ITEMS POSSIBLES")
        StaffMenu.paidShopItemEdit.Button(
            "Items possibles (" .. possibleCount .. ")",
            "Gerer les items de la caisse",
            nil, "chevron", false,
            function() end,
            StaffMenu.paidShopEditCrateItems
        )
    end

    StaffMenu.paidShopItemEdit.Separator("ACTIONS")

    -- Sauvegarder
    StaffMenu.paidShopItemEdit.Button("SAUVEGARDER", "Enregistrer les modifications", nil, "check", false, function()
        if isSaving then return end
        isSaving = true
        local result, message = TriggerServerCallback('paidshop:editItemServer', selectedItem, selectedCategory)
        isSaving = false
        if result then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Boutique',
                message = "Item modifié"
          })
            -- Refresh cache
            fetchShopData()
            StaffMenu.paidShopItemEdit.close()
            StaffMenu.paidShopItemEdit.parent.open()
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Boutique',
                message = message or "Erreur lors de la modification"
          })
        end
    end)

    -- Supprimer
    StaffMenu.paidShopItemEdit.Button("SUPPRIMER", "Supprimer cet item de la boutique", nil, "trash", false, function()
        if isSaving then return end
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer la suppression")
        if confirm and string.upper(confirm) == "OUI" then
            isSaving = true
            local result, message = TriggerServerCallback('paidshop:deleteItemServer', selectedItem.spawnName, selectedCategory)
            isSaving = false
            if result then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'SUCCESS',
                    subtitle = 'Boutique',
                    message = "Item supprimé"
              })
                -- Refresh cache
                fetchShopData()
                StaffMenu.paidShopItemEdit.close()
                StaffMenu.paidShopItemEdit.parent.open()
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Boutique',
                    message = message or "Erreur lors de la suppression"
              })
            end
        end
    end)
end)

-- ==========================================
--    EDIT: PACK CONTENT SUB-MENU
-- ==========================================

StaffMenu.paidShopEditPackContent.OnOpen(function()
    StaffMenu.paidShopEditPackContent.ClearItems()

    if not selectedItem then
        StaffMenu.paidShopEditPackContent.Button("Erreur", "Aucun item sélectionné", nil, nil, true, function() end)
        return
    end

    buildPackContentMenu(StaffMenu.paidShopEditPackContent, selectedItem, StaffMenu.paidShopEditAddPackElement)
end)

-- ==========================================
--    EDIT: ADD PACK ELEMENT SUB-MENU
-- ==========================================

StaffMenu.paidShopEditAddPackElement.OnOpen(function()
    buildAddPackElementMenu(
        StaffMenu.paidShopEditAddPackElement,
        StaffMenu.paidShopEditAddPackElementWeaponSelect,
        StaffMenu.paidShopEditAddPackElementItemSelect
    )
end)

StaffMenu.paidShopEditAddPackElementWeaponSelect.OnOpen(function()
    buildWeaponPickerMenu(StaffMenu.paidShopEditAddPackElementWeaponSelect, function() return newPackElement end, "model")
end)

StaffMenu.paidShopEditAddPackElementItemSelect.OnOpen(function()
    buildItemPickerMenu(StaffMenu.paidShopEditAddPackElementItemSelect, function() return newPackElement end, "model")
end)

-- ==========================================
--    EDIT: CRATE ITEMS SUB-MENU
-- ==========================================

StaffMenu.paidShopEditCrateItems.OnOpen(function()
    StaffMenu.paidShopEditCrateItems.ClearItems()

    if not selectedItem then
        StaffMenu.paidShopEditCrateItems.Button("Erreur", "Aucun item sélectionné", nil, nil, true, function() end)
        return
    end

    buildCrateItemsMenu(StaffMenu.paidShopEditCrateItems, selectedItem, StaffMenu.paidShopEditAddCrateItem)
end)

-- ==========================================
--    EDIT: ADD CRATE ITEM SUB-MENU
-- ==========================================

StaffMenu.paidShopEditAddCrateItem.OnOpen(function()
    buildAddCrateItemMenu(
        StaffMenu.paidShopEditAddCrateItem,
        StaffMenu.paidShopEditCrateItems,
        StaffMenu.paidShopEditAddCrateItemWeaponSelect,
        StaffMenu.paidShopEditAddCrateItemItemSelect
    )
end)

StaffMenu.paidShopEditAddCrateItemWeaponSelect.OnOpen(function()
    buildWeaponPickerMenu(StaffMenu.paidShopEditAddCrateItemWeaponSelect, function() return newCrateItem end, "spawnName")
end)

StaffMenu.paidShopEditAddCrateItemItemSelect.OnOpen(function()
    buildItemPickerMenu(StaffMenu.paidShopEditAddCrateItemItemSelect, function() return newCrateItem end, "spawnName")
end)

-- ==========================================
--          ADD ITEM MENU
-- ==========================================

StaffMenu.paidShopAddItem.OnOpen(function()
    StaffMenu.paidShopAddItem.ClearItems()

    -- Preserve existing data
    newItem = {
        name = newItem.name or nil,
        spawnName = newItem.spawnName or nil,
        price = newItem.price or nil,
        promoPercent = newItem.promoPercent or nil,
        image = newItem.image or nil,
        description = newItem.description or nil,
        tags = newItem.tags or {},
        content = newItem.content or nil,
        possible_items = newItem.possible_items or nil
    }

    StaffMenu.paidShopAddItem.Separator("NOUVEL ITEM")

    -- Build category options for List component
    local categoryOptions = {}
    local categoryIds = {}
    for _, cat in ipairs(PaidShopCache.categories) do
        if cat.id ~= "vip" then
            table.insert(categoryOptions, cat.label)
            table.insert(categoryIds, cat.id)
        end
    end

    -- Find current index if category is already selected
    local selectedCategoryIndex = 1
    if selectedCategory then
        for i, catId in ipairs(categoryIds) do
            if catId == selectedCategory then
                selectedCategoryIndex = i
                break
            end
        end
    else
        -- Auto-select first category if none selected
        if #categoryIds > 0 then
            selectedCategory = categoryIds[1]
        end
    end

    -- Selection categorie with List component (left/right arrows)
    StaffMenu.paidShopAddItem.List(
        "Categorie",
        "Fleches gauche/droite pour changer",
        false,
        categoryOptions,
        selectedCategoryIndex,
        function(index, item)
            selectedCategory = categoryIds[index]
            StaffMenu.paidShopAddItem.refresh()
        end
    )

    -- Nom
    StaffMenu.paidShopAddItem.Button("Nom: " .. (newItem.name or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local name = VFW.Nui.KeyboardInput(true, "Nom de l'item", newItem.name or "")
        if name and string.len(string.gsub(name, "%s+", "")) > 0 then
            newItem.name = name
            StaffMenu.paidShopAddItem.refresh()
        elseif name then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Boutique',
                message = "Le nom ne peut pas être vide"
          })
        end
    end)

    -- SpawnName (hidden for caisses and packs - auto-generated)
    if selectedCategory ~= "caisses" and selectedCategory ~= "packs" then
        local categoryConfig = PaidShopConfig.GetCategoryConfig(selectedCategory)
        local catItemType = categoryConfig and categoryConfig.itemType

        if catItemType == "weapon" then
            local current = newItem.spawnName or ""
          local currentLabel = current ~= "" and ((VFW.Items[current] and VFW.Items[current].label) or current) or "Non définie"
          StaffMenu.paidShopAddItem.Button("SpawnName: " .. currentLabel, "Choisir une arme dans la liste", nil, "chevron", false,
                function() pickerSearchText = "" end,
                StaffMenu.paidShopAddItemWeaponSelect)
        elseif catItemType == "consumable" then
            local current = newItem.spawnName or ""
          local currentLabel = current ~= "" and ((VFW.Items[current] and VFW.Items[current].label) or current) or "Non défini"
          StaffMenu.paidShopAddItem.Button("SpawnName: " .. currentLabel, "Choisir un item dans la liste", nil, "chevron", false,
                function() pickerSearchText = "" end,
                StaffMenu.paidShopAddItemItemSelect)
        elseif catItemType == "ped" then
            StaffMenu.paidShopAddItem.Button("Modèle du ped: " .. (newItem.spawnName or "Non défini"), "Nom du ped ou hash (ex: a_c_shepherd)", nil, "chevron", false, function()
                local spawnName = VFW.Nui.KeyboardInput(true, "Modèle ou hash du ped (ex: a_c_shepherd)", newItem.spawnName or "")
                if spawnName and string.len(string.gsub(spawnName, "%s+", "")) > 0 then
                    newItem.spawnName = spawnName
                    StaffMenu.paidShopAddItem.refresh()
                elseif spawnName then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Boutique',
                        message = "Le modèle du ped ne peut pas être vide"
                  })
                end
            end)
        else
            StaffMenu.paidShopAddItem.Button("SpawnName: " .. (newItem.spawnName or "Non défini"), "Identifiant unique", nil, "chevron", false, function()
                local spawnName = VFW.Nui.KeyboardInput(true, "Spawn name (identifiant unique)", newItem.spawnName or "")
                if spawnName and string.len(string.gsub(spawnName, "%s+", "")) > 0 then
                    newItem.spawnName = spawnName
                    StaffMenu.paidShopAddItem.refresh()
                elseif spawnName then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Boutique',
                        message = "Le spawn name ne peut pas être vide"
                  })
                end
            end)
        end
    end

    -- Prix
    StaffMenu.paidShopAddItem.Button("Prix: " .. (newItem.price and (newItem.price .. " Coins") or "Non défini"), "Cliquez pour définir", nil, "chevron", false, function()
        local price = VFW.Nui.KeyboardInput(true, "Prix en Coins", newItem.price and tostring(newItem.price) or "")
        if price and tonumber(price) then
            local priceNum = tonumber(price)
            if priceNum <= 0 then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Boutique',
                    message = "Le prix doit être supérieur à 0"
              })
                return
            end
            newItem.price = priceNum
            StaffMenu.paidShopAddItem.refresh()
        end
    end)

    -- Promotion
    local hasPromo = newItem.promoPercent and newItem.promoPercent > 0
    local promoLabel, promoDesc
    if hasPromo then
        local discountedPrice = math.floor((newItem.price or 0) * (1 - newItem.promoPercent / 100))
        promoLabel = "Promotion: -" .. newItem.promoPercent .. "% (" .. discountedPrice .. " Coins)"
      promoDesc = "Prix original: " .. (newItem.price or 0) .. " | Tapez 0 pour retirer"
  else
        promoLabel = "Promotion: Aucune"
      promoDesc = "Cliquez pour mettre en promotion"
  end
    StaffMenu.paidShopAddItem.Button(promoLabel, promoDesc, nil, "chevron", false, function()
        if not newItem.price or newItem.price <= 0 then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique',
                message = "Définissez d'abord le prix avant d'ajouter une promotion"
          })
            return
        end
        local currentPercent = hasPromo and tostring(newItem.promoPercent) or ""
      local input = VFW.Nui.KeyboardInput(true, "Pourcentage de reduction (0 = retirer)", currentPercent)
        if input and tonumber(input) then
            local percent = tonumber(input)
            if percent <= 0 then
                newItem.promoPercent = nil
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Boutique',
                    message = "Promotion retirée"
              })
            elseif percent >= 100 then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique',
                    message = "Le pourcentage doit être entre 1 et 99"
              })
                return
            else
                newItem.promoPercent = percent
                local discounted = math.floor(newItem.price * (1 - percent / 100))
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Boutique',
                    message = "Promotion activée: -" .. percent .. "% (" .. discounted .. " Coins)"
              })
            end
            StaffMenu.paidShopAddItem.refresh()
        end
    end)

    -- Image URL
    local imageStatus = newItem.image and "Définie" or "Non définie"
  StaffMenu.paidShopAddItem.Button("Image URL: " .. imageStatus, "Cliquez pour définir", nil, "chevron", false, function()
        local image = VFW.Nui.KeyboardInput(true, "URL de l'image", newItem.image or "")
        if image then
            newItem.image = image
            StaffMenu.paidShopAddItem.refresh()
        end
    end)

    if newItem.image and newItem.image ~= "" then
        StaffMenu.paidShopAddItem.Imagebox(newItem.image, nil)
    end

    -- Description
    local descStatus = newItem.description and "Définie" or "Non définie"
  StaffMenu.paidShopAddItem.Button("Description: " .. descStatus, "Cliquez pour définir", nil, "chevron", false, function()
        local desc = VFW.Nui.KeyboardInput(true, "Description", newItem.description or "")
        if desc then
            newItem.description = desc
            StaffMenu.paidShopAddItem.refresh()
        end
    end)

    -- Tags
    local currentNewTags = newItem.tags or {}
    local newTagsLabel = #currentNewTags > 0 and table.concat(currentNewTags, ", ") or "Aucun"
  StaffMenu.paidShopAddItem.Button("Tags: " .. newTagsLabel, "Cliquez pour définir (separer par des virgules)", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Tags (separes par des virgules)", table.concat(currentNewTags, ", "))
        if input then
            local tags = {}
            for tag in string.gmatch(input, "[^,]+") do
                local trimmed = tag:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then
                    tags[#tags + 1] = trimmed
                end
            end
            newItem.tags = tags
            StaffMenu.paidShopAddItem.refresh()
        end
    end)

    -- Pack content button (only when packs category is selected)
    if selectedCategory == "packs" then
        local contentCount = countPackContent(newItem.content)
        StaffMenu.paidShopAddItem.Separator("CONTENU DU PACK")
        StaffMenu.paidShopAddItem.Button(
            "Contenu du pack (" .. contentCount .. " elements)",
            "Gerer vehicules, armes, items, argent, Coins",
            nil, "chevron", false,
            function() end,
            StaffMenu.paidShopPackContent
        )
    end

    -- Crate possible items button (only when caisses category is selected)
    if selectedCategory == "caisses" then
        local possibleCount = newItem.possible_items and #newItem.possible_items or 0
        StaffMenu.paidShopAddItem.Separator("ITEMS POSSIBLES")
        StaffMenu.paidShopAddItem.Button(
            "Items possibles (" .. possibleCount .. ")",
            "Gerer les items de la caisse",
            nil, "chevron", false,
            function() end,
            StaffMenu.paidShopCrateItems
        )
    end

    StaffMenu.paidShopAddItem.Separator("VALIDER")

    -- For caisses and packs, spawnName is auto-generated from the name
    local needsSpawnName = selectedCategory ~= "caisses" and selectedCategory ~= "packs"

  StaffMenu.paidShopAddItem.Button("CREER L'ITEM", "Cliquez pour creer l'item", nil, "check", false, function()
        -- Validate required fields
        if not newItem.name or string.len(string.gsub(newItem.name or "", "%s+", "")) == 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique', message = "Veuillez définir le nom de l'item" })
            return
        end
        if needsSpawnName and (not newItem.spawnName or string.len(string.gsub(newItem.spawnName or "", "%s+", "")) == 0) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique', message = "Veuillez définir le spawn name" })
            return
        end
        if not newItem.price or newItem.price <= 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique', message = "Veuillez définir un prix valide" })
            return
        end
        if not selectedCategory then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique', message = "Veuillez sélectionnér une categorie" })
            return
        end

        if isSaving then return end
        isSaving = true

        -- Auto-generate spawnName for caisses and packs
        if (selectedCategory == "caisses" or selectedCategory == "packs") and (not newItem.spawnName or newItem.spawnName == "") then
            local prefix = selectedCategory == "caisses" and "case_" or "pack_"
          local sanitized = string.gsub(string.lower(newItem.name), "[^%a%d]", "_")
            newItem.spawnName = prefix .. sanitized .. "_" .. os.time()
        end

        local result, message = TriggerServerCallback('paidshop:addItemServer', newItem, selectedCategory)
        isSaving = false
        if result then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'SUCCESS',
                subtitle = 'Boutique',
                message = "Item créé"
          })
            -- Reset item data but keep category selection so admin can add another
            local keepCategory = selectedCategory
            newItem = {}
            fetchShopData()
            selectedCategory = keepCategory
            -- Stay on the add item page instead of closing
            StaffMenu.paidShopAddItem.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'ERROR',
                subtitle = 'Boutique',
                message = message or "Erreur lors de la creation"
          })
        end
    end)
end)

local function collectExistingShopSpawnNames()
    local used = {}
    for _, items in pairs(PaidShopCache.items or {}) do
        for _, item in ipairs(items) do
            if item.spawnName and item.spawnName ~= "" then
                used[item.spawnName] = true
            end
        end
    end
    return used
end

StaffMenu.paidShopAddItemWeaponSelect.OnOpen(function()
    buildWeaponPickerMenu(StaffMenu.paidShopAddItemWeaponSelect, function() return newItem end, "spawnName")
end)

StaffMenu.paidShopAddItemItemSelect.OnOpen(function()
    local prefix, excludeSet
    if selectedCategory == "potions" then
        prefix = "potion"
      excludeSet = collectExistingShopSpawnNames()
    end
    buildItemPickerMenu(
        StaffMenu.paidShopAddItemItemSelect,
        function() return newItem end,
        "spawnName",
        prefix,
        excludeSet
    )
end)

-- ==========================================
--    ADD: PACK CONTENT SUB-MENU
-- ==========================================

StaffMenu.paidShopPackContent.OnOpen(function()
    StaffMenu.paidShopPackContent.ClearItems()
    buildPackContentMenu(StaffMenu.paidShopPackContent, newItem, StaffMenu.paidShopAddPackElement)
end)

-- ==========================================
--    ADD: ADD PACK ELEMENT SUB-MENU
-- ==========================================

StaffMenu.paidShopAddPackElement.OnOpen(function()
    buildAddPackElementMenu(
        StaffMenu.paidShopAddPackElement,
        StaffMenu.paidShopAddPackElementWeaponSelect,
        StaffMenu.paidShopAddPackElementItemSelect
    )
end)

StaffMenu.paidShopAddPackElementWeaponSelect.OnOpen(function()
    buildWeaponPickerMenu(StaffMenu.paidShopAddPackElementWeaponSelect, function() return newPackElement end, "model")
end)

StaffMenu.paidShopAddPackElementItemSelect.OnOpen(function()
    buildItemPickerMenu(StaffMenu.paidShopAddPackElementItemSelect, function() return newPackElement end, "model")
end)

-- ==========================================
--    ADD: CRATE ITEMS SUB-MENU
-- ==========================================

StaffMenu.paidShopCrateItems.OnOpen(function()
    StaffMenu.paidShopCrateItems.ClearItems()
    buildCrateItemsMenu(StaffMenu.paidShopCrateItems, newItem, StaffMenu.paidShopAddCrateItem)
end)

-- ==========================================
--    ADD: ADD CRATE ITEM SUB-MENU
-- ==========================================

StaffMenu.paidShopAddCrateItem.OnOpen(function()
    buildAddCrateItemMenu(
        StaffMenu.paidShopAddCrateItem,
        StaffMenu.paidShopCrateItems,
        StaffMenu.paidShopAddCrateItemWeaponSelect,
        StaffMenu.paidShopAddCrateItemItemSelect
    )
end)

StaffMenu.paidShopAddCrateItemWeaponSelect.OnOpen(function()
    buildWeaponPickerMenu(StaffMenu.paidShopAddCrateItemWeaponSelect, function() return newCrateItem end, "spawnName")
end)

StaffMenu.paidShopAddCrateItemItemSelect.OnOpen(function()
    buildItemPickerMenu(StaffMenu.paidShopAddCrateItemItemSelect, function() return newCrateItem end, "spawnName")
end)

-- ==========================================
--          VCOINS MANAGEMENT
-- ==========================================

StaffMenu.paidShopCoins.OnOpen(function()
    StaffMenu.paidShopCoins.ClearItems()

    StaffMenu.paidShopCoins.Separator("GESTION COINS")

    -- Voir solde
    StaffMenu.paidShopCoins.Button("VOIR LE SOLDE", "Consulter les Coins d'un joueur", nil, "chevron", false, function()
        local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
        if playerId and tonumber(playerId) then
            local result, data = TriggerServerCallback('paidshop:getCoinsAdmin', tonumber(playerId))
            if result and data then
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'INFO',
                    subtitle = 'Coins',
                    message = data.name .. " (ID: " .. playerId .. ") possède " .. data.spacecoins .. " Coins"
              })
            else
                VFW.ShowNotification({
                    type = 'STAFF',
                    variant = 'ERROR',
                    subtitle = 'Coins',
                    message = data or "Joueur introuvable"
              })
            end
        end
    end)

    -- Ajouter Coins
    StaffMenu.paidShopCoins.Button("+ AJOUTER COINS", "Donner des Coins a un joueur", nil, "chevron", false, function()
        local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
        if playerId and tonumber(playerId) then
            local amount = VFW.Nui.KeyboardInput(true, "Montant a ajouter")
            if amount and tonumber(amount) then
                local result, message = TriggerServerCallback('paidshop:addCoinsAdmin', tonumber(playerId), tonumber(amount))
                if result then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'SUCCESS',
                        subtitle = 'Coins',
                        message = amount .. " Coins ajoutes au joueur " .. playerId
                    })
                else
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Coins',
                        message = message or "Erreur"
                  })
                end
            end
        end
    end)

    -- Retirer Coins
    StaffMenu.paidShopCoins.Button("- RETIRER COINS", "Retirer des Coins d'un joueur", nil, "chevron", false, function()
        local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur")
        if playerId and tonumber(playerId) then
            local amount = VFW.Nui.KeyboardInput(true, "Montant a retirer")
            if amount and tonumber(amount) then
                local result, message = TriggerServerCallback('paidshop:removeCoinsAdmin', tonumber(playerId), tonumber(amount))
                if result then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'SUCCESS',
                        subtitle = 'Coins',
                        message = amount .. " Coins retires du joueur " .. playerId
                    })
                else
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Coins',
                        message = message or "Erreur"
                  })
                end
            end
        end
    end)
end)

-- ==========================================
--          GIVE ITEM TO PLAYER
-- ==========================================

local giveItemState = {
    mode = nil,         -- "online" or "offline"
  targetValue = nil,  -- player ID or identifier
    category = nil      -- selected category
}

StaffMenu.paidShopGiveItem.OnOpen(function()
    StaffMenu.paidShopGiveItem.ClearItems()

    -- Reset state
    giveItemState = { mode = nil, targetValue = nil, category = nil }

    -- Refresh data
    fetchShopData()

    StaffMenu.paidShopGiveItem.Separator("MODE DE SELECTION")

    StaffMenu.paidShopGiveItem.Button("JOUEUR CONNECTE (ID)", "Donner un article a un joueur en ligne", nil, "chevron", false, function()
        local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur connecte")
        if playerId and tonumber(playerId) then
            giveItemState.mode = "online"
          giveItemState.targetValue = tonumber(playerId)
            StaffMenu.paidShopGiveCategory.open()
        end
    end)

    StaffMenu.paidShopGiveItem.Button("JOUEUR DECONNECTE (ID Global)", "Donner un article via ID global", nil, "chevron", false, function()
        local globalId = VFW.Nui.KeyboardInput(true, "ID global du joueur (numéro)")
        if globalId then
            globalId = string.match(globalId, "^%s*(.-)%s*$")
            local globalIdNum = tonumber(globalId)
            if globalIdNum and globalIdNum > 0 then
                giveItemState.mode = "offline"
              giveItemState.targetValue = globalIdNum
                StaffMenu.paidShopGiveCategory.open()
            end
        end
    end)
end)

-- ==========================================
--    GIVE: CATEGORY SELECTION
-- ==========================================

StaffMenu.paidShopGiveCategory.OnOpen(function()
    StaffMenu.paidShopGiveCategory.ClearItems()

    if not giveItemState.mode or not giveItemState.targetValue then
        StaffMenu.paidShopGiveCategory.Button("Erreur", "Aucun joueur sélectionné", nil, nil, true, function() end)
        return
    end

    local targetLabel = giveItemState.mode == "online"
      and ("Joueur ID: " .. tostring(giveItemState.targetValue))
        or ("ID Global: " .. tostring(giveItemState.targetValue))

    StaffMenu.paidShopGiveCategory.Separator("CIBLE: " .. targetLabel)
    StaffMenu.paidShopGiveCategory.Separator("CHOISIR UNE CATEGORIE")

    for _, category in ipairs(PaidShopCache.categories) do
        -- Skip vip and pour_moi categories
        if category.id ~= "vip" and category.id ~= "pour_moi" then
            local itemCount = getItemsCount(category.id)

            StaffMenu.paidShopGiveCategory.Button(
                string.upper(category.label),
                itemCount .. " items",
                nil,
                "chevron",
                false,
                function()
                    giveItemState.category = category.id
                end,
                StaffMenu.paidShopGiveItemSelect
            )
        end
    end
end)

-- ==========================================
--    GIVE: ITEM SELECTION
-- ==========================================

StaffMenu.paidShopGiveItemSelect.OnOpen(function()
    StaffMenu.paidShopGiveItemSelect.ClearItems()

    if not giveItemState.category then
        StaffMenu.paidShopGiveItemSelect.Button("Erreur", "Aucune catégorie sélectionnée", nil, nil, true, function() end)
        return
    end

    local items = PaidShopCache.items[giveItemState.category] or {}
    local categoryLabel = getCategoryLabel(giveItemState.category)

    StaffMenu.paidShopGiveItemSelect.Separator("ITEMS - " .. string.upper(categoryLabel))

    if #items == 0 then
        StaffMenu.paidShopGiveItemSelect.Button("Aucun item", "Cette catégorie est vide", nil, nil, true, function() end)
    else
        for _, item in ipairs(items) do
            -- Skip daily rewards and special items
            if not item.isDailyReward then
                local priceText = item.price and (item.price .. " Coins") or "Gratuit"
              StaffMenu.paidShopGiveItemSelect.Button(
                    item.name or item.spawnName,
                    item.spawnName .. " | " .. priceText,
                    nil,
                    "chevron",
                    false,
                    function()
                        -- Ask for quantity
                        local qty = VFW.Nui.KeyboardInput(true, "Quantité à donner", "1")
                        local qtyNum = tonumber(qty)
                        if not qtyNum or qtyNum < 1 or qtyNum > 100 or qtyNum ~= math.floor(qtyNum) then
                            VFW.ShowNotification({
                                type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique',
                                message = "Cette quantité n'est pas valide (1-100, entier)."
                          })
                            return
                        end

                        -- Confirm
                        local targetLabel = giveItemState.mode == "online"
                          and ("joueur ID " .. tostring(giveItemState.targetValue))
                            or ("ID global " .. tostring(giveItemState.targetValue))

                        local confirm = VFW.Nui.KeyboardInput(true,
                            "Donner " .. qtyNum .. "x " .. (item.name or item.spawnName) .. " a " .. targetLabel .. " ? (OUI/NON)")

                        if confirm and string.match(string.upper(confirm), "^%s*OUI%s*$") then
                            if isSaving then return end
                            isSaving = true
                            local result, message = TriggerServerCallback('paidshop:giveItemAdmin',
                                giveItemState.mode,
                                giveItemState.targetValue,
                                item.spawnName,
                                giveItemState.category,
                                qtyNum
                            )

                            if result then
                                VFW.ShowNotification({
                                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Boutique',
                                    message = "Article offert: " .. qtyNum .. "x " .. (item.name or item.spawnName)
                                })
                            else
                                VFW.ShowNotification({
                                    type = 'STAFF', variant = 'ERROR', subtitle = 'Boutique',
                                    message = message or "Erreur lors du don"
                              })
                            end
                            isSaving = false
                        end
                    end
                )
            end
        end
    end
end)

-- ==========================================
--     DAILY REWARDS MANAGEMENT
-- ==========================================

local dailyRewardTypeLabels = {
    money = "Argent",
    item = "Item",
    vehicle = "Véhicule"
}

StaffMenu.paidShopDailyRewards.OnOpen(function()
    StaffMenu.paidShopDailyRewards.ClearItems()
    newDailyReward = {}
    selectedDailyReward = nil

    -- Fetch current daily rewards from server
    local rewards = TriggerServerCallback('paidshop:getDailyRewards')

    StaffMenu.paidShopDailyRewards.Separator("RÉCOMPENSES ACTUELLES")

    if rewards and #rewards > 0 then
        for _, reward in ipairs(rewards) do
            local typeLabel = dailyRewardTypeLabels[reward.rewardType] or reward.rewardType
            local desc = typeLabel

            if reward.rewardType == "money" then
                desc = typeLabel .. " - " .. VFW.Math.FormatMoney(reward.cashAmount or 0)
          elseif reward.rewardType == "item" then
                desc = typeLabel .. " - " .. (reward.rewardItem or "?") .. " x" .. (reward.rewardCount or 1)
            elseif reward.rewardType == "vehicle" then
                desc = typeLabel .. " - " .. (reward.rewardVehicle or "?")
            end

            StaffMenu.paidShopDailyRewards.Button(
                reward.name or "Récompense",
                desc,
                nil,
                "chevron",
                false,
                function()
                    selectedDailyReward = reward
                end,
                StaffMenu.paidShopDailyRewardEdit
            )
        end
    else
        StaffMenu.paidShopDailyRewards.Button("Aucune récompense", "Ajoutez-en une ci-dessous", nil, nil, true)
    end

    StaffMenu.paidShopDailyRewards.Separator("ACTIONS")

    StaffMenu.paidShopDailyRewards.Button("+ AJOUTER UNE RÉCOMPENSE", "Créer une nouvelle récompense quotidienne", nil, "chevron", false, function()
        newDailyReward = {}
    end, StaffMenu.paidShopDailyRewardAdd)
end)

-- ==========================================
--     ADD DAILY REWARD
-- ==========================================

StaffMenu.paidShopDailyRewardAdd.OnOpen(function()
    StaffMenu.paidShopDailyRewardAdd.ClearItems()

    local rewardTypes = {"money", "item", "vehicle"}

    StaffMenu.paidShopDailyRewardAdd.Separator("CONFIGURATION")

    -- Type selection
    local typeIndex = 1
    for i, t in ipairs(rewardTypes) do
        if newDailyReward.rewardType == t then typeIndex = i end
    end
    local typeLabels = {}
    for _, t in ipairs(rewardTypes) do
        table.insert(typeLabels, dailyRewardTypeLabels[t])
    end
    StaffMenu.paidShopDailyRewardAdd.List("TYPE", "Choisir le type de récompense", false, typeLabels, typeIndex, function(index)
        newDailyReward.rewardType = rewardTypes[index]
        StaffMenu.paidShopDailyRewardAdd.refresh()
    end)

    -- Name
    StaffMenu.paidShopDailyRewardAdd.Button(
        "NOM",
        newDailyReward.name and newDailyReward.name ~= "" and newDailyReward.name or "Cliquez pour définir",
        nil, "edit", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom de la récompense")
            if input and input ~= "" then
                newDailyReward.name = input
                StaffMenu.paidShopDailyRewardAdd.refresh()
            end
        end
    )

    -- Image
    StaffMenu.paidShopDailyRewardAdd.Button(
        "IMAGE",
        newDailyReward.image and newDailyReward.image ~= "" and "URL définie" or "Cliquez pour définir",
        nil, "edit", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "URL de l'image")
            if input and input ~= "" then
                newDailyReward.image = input
                StaffMenu.paidShopDailyRewardAdd.refresh()
            end
        end
    )

    if newDailyReward.image and newDailyReward.image ~= "" then
        StaffMenu.paidShopDailyRewardAdd.Imagebox(newDailyReward.image, nil)
    end

    -- Description
    StaffMenu.paidShopDailyRewardAdd.Button(
        "DESCRIPTION",
        newDailyReward.description and newDailyReward.description ~= "" and newDailyReward.description or "Cliquez pour définir",
        nil, "edit", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Description de la récompense")
            if input and input ~= "" then
                newDailyReward.description = input
                StaffMenu.paidShopDailyRewardAdd.refresh()
            end
        end
    )

    -- VIP only toggle
    local vipOptions = {"Non", "Bronze+", "Silver+", "Gold"}
    local vipValues = {0, 1, 2, 3}
    local vipIndex = 1
    for i, v in ipairs(vipValues) do
        if newDailyReward.requiredVipTier == v then vipIndex = i end
    end
    StaffMenu.paidShopDailyRewardAdd.List("VIP REQUIS", "Réservé aux VIP ?", false, vipOptions, vipIndex, function(index)
        newDailyReward.requiredVipTier = vipValues[index]
    end)

    -- Type-specific fields
    local currentType = newDailyReward.rewardType or rewardTypes[1]
    newDailyReward.rewardType = currentType

    StaffMenu.paidShopDailyRewardAdd.Separator("DÉTAILS " .. string.upper(dailyRewardTypeLabels[currentType] or ""))

    if currentType == "money" then
        StaffMenu.paidShopDailyRewardAdd.Button(
            "MONTANT",
            newDailyReward.cashAmount and VFW.Math.FormatMoney(newDailyReward.cashAmount) or "Cliquez pour définir",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Montant en " .. LOCALE.currencySymbol)
                if input then
                    local amount = tonumber(input)
                    if amount and amount > 0 then
                        newDailyReward.cashAmount = amount
                        StaffMenu.paidShopDailyRewardAdd.refresh()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = "Ce montant n'est pas valide" })
                    end
                end
            end
        )
    elseif currentType == "item" then
        StaffMenu.paidShopDailyRewardAdd.Button(
            "SPAWN NAME",
            newDailyReward.rewardItem and newDailyReward.rewardItem ~= "" and newDailyReward.rewardItem or "Cliquez pour définir",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Spawn name de l'item")
                if input and input ~= "" then
                    newDailyReward.rewardItem = input
                    StaffMenu.paidShopDailyRewardAdd.refresh()
                end
            end
        )
        StaffMenu.paidShopDailyRewardAdd.Button(
            "QUANTITÉ",
            newDailyReward.rewardCount and tostring(newDailyReward.rewardCount) or "1",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Quantité")
                if input then
                    local count = tonumber(input)
                    if count and count > 0 and count == math.floor(count) then
                        newDailyReward.rewardCount = count
                        StaffMenu.paidShopDailyRewardAdd.refresh()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = "Cette quantité n'est pas valide." })
                    end
                end
            end
        )
    elseif currentType == "vehicle" then
        StaffMenu.paidShopDailyRewardAdd.Button(
            "MODÈLE VÉHICULE",
            newDailyReward.rewardVehicle and newDailyReward.rewardVehicle ~= "" and newDailyReward.rewardVehicle or "Cliquez pour définir",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Spawn name du véhicule")
                if input and input ~= "" then
                    newDailyReward.rewardVehicle = input
                    StaffMenu.paidShopDailyRewardAdd.refresh()
                end
            end
        )
    end

    StaffMenu.paidShopDailyRewardAdd.Separator("")

    -- Save button
    StaffMenu.paidShopDailyRewardAdd.Button("SAUVEGARDER", "Créer la récompense quotidienne", nil, "check", false, function()
        if isSaving then return end

        -- Validate
        if not newDailyReward.name or newDailyReward.name == "" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = "Le nom est requis" })
            return
        end

        if currentType == "money" and (not newDailyReward.cashAmount or newDailyReward.cashAmount <= 0) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = "Le montant est requis" })
            return
        end

        if currentType == "item" and (not newDailyReward.rewardItem or newDailyReward.rewardItem == "") then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = "Le spawn name de l'item est requis" })
            return
        end

        if currentType == "vehicle" and (not newDailyReward.rewardVehicle or newDailyReward.rewardVehicle == "") then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = "Le modèle du véhicule est requis" })
            return
        end

        isSaving = true

        -- Build the item data
        local rewardData = {
            name = newDailyReward.name,
            image = newDailyReward.image or "",
            description = newDailyReward.description or "",
            rewardType = currentType,
            requiredVipTier = newDailyReward.requiredVipTier or 0,
            cashAmount = currentType == "money" and newDailyReward.cashAmount or nil,
            rewardItem = currentType == "item" and newDailyReward.rewardItem or nil,
            rewardCount = currentType == "item" and (newDailyReward.rewardCount or 1) or nil,
            rewardVehicle = currentType == "vehicle" and newDailyReward.rewardVehicle or nil,
        }

        local success, message = TriggerServerCallback('paidshop:addDailyReward', rewardData)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Récompense ajoutée" })
            newDailyReward = {}
            fetchShopData()
            StaffMenu.paidShopDailyRewards.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur lors de l'ajout" })
        end
        isSaving = false
    end)
end)

-- ==========================================
--     EDIT / DELETE DAILY REWARD
-- ==========================================

StaffMenu.paidShopDailyRewardEdit.OnOpen(function()
    StaffMenu.paidShopDailyRewardEdit.ClearItems()

    if not selectedDailyReward then return end

    local reward = selectedDailyReward
    local typeLabel = dailyRewardTypeLabels[reward.rewardType] or reward.rewardType

    StaffMenu.paidShopDailyRewardEdit.Separator("INFORMATIONS")

    StaffMenu.paidShopDailyRewardEdit.Button("NOM", reward.name or "?", nil, nil, true)
    StaffMenu.paidShopDailyRewardEdit.Button("TYPE", typeLabel, nil, nil, true)
    local vipTierLabels = {[0] = "Non", [1] = "Bronze+", [2] = "Silver+", [3] = "Gold"}
    StaffMenu.paidShopDailyRewardEdit.Button("VIP REQUIS", vipTierLabels[reward.requiredVipTier or 0] or "Non", nil, nil, true)
    StaffMenu.paidShopDailyRewardEdit.Button("SPAWN NAME", reward.spawnName or "?", nil, nil, true)

    if reward.rewardType == "money" then
        StaffMenu.paidShopDailyRewardEdit.Button("MONTANT", VFW.Math.FormatMoney(reward.cashAmount or 0), nil, nil, true)
    elseif reward.rewardType == "item" then
        StaffMenu.paidShopDailyRewardEdit.Button("ITEM", (reward.rewardItem or "?") .. " x" .. (reward.rewardCount or 1), nil, nil, true)
    elseif reward.rewardType == "vehicle" then
        StaffMenu.paidShopDailyRewardEdit.Button("VÉHICULE", reward.rewardVehicle or "?", nil, nil, true)
    end

    if reward.image and reward.image ~= "" then
        StaffMenu.paidShopDailyRewardEdit.Imagebox(reward.image, nil)
    end

    if reward.description and reward.description ~= "" then
        StaffMenu.paidShopDailyRewardEdit.Button("DESCRIPTION", reward.description, nil, nil, true)
    end

    StaffMenu.paidShopDailyRewardEdit.Separator("MODIFIER")

    -- Edit name
    StaffMenu.paidShopDailyRewardEdit.Button("MODIFIER LE NOM", "Changer le nom", nil, "edit", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau nom")
        if input and input ~= "" then
            reward.name = input
            local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Nom modifié" })
                fetchShopData()
                StaffMenu.paidShopDailyRewardEdit.refresh()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
            end
        end
    end)

    -- Edit image
    StaffMenu.paidShopDailyRewardEdit.Button("MODIFIER L'IMAGE", "Changer l'image", nil, "edit", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouvelle URL image")
        if input and input ~= "" then
            reward.image = input
            local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Image modifiée" })
                fetchShopData()
                StaffMenu.paidShopDailyRewardEdit.refresh()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
            end
        end
    end)

    -- Edit VIP requirement
    local editVipOptions = {"Non", "Bronze+", "Silver+", "Gold"}
    local editVipValues = {0, 1, 2, 3}
    local editVipIndex = 1
    for i, v in ipairs(editVipValues) do
        if (reward.requiredVipTier or 0) == v then editVipIndex = i end
    end
    StaffMenu.paidShopDailyRewardEdit.List("MODIFIER VIP REQUIS", "Changer le niveau VIP requis", false, editVipOptions, editVipIndex, function(index)
        reward.requiredVipTier = editVipValues[index]
        local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "VIP requis modifié" })
            fetchShopData()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
        end
    end)

    -- Edit type-specific value
    if reward.rewardType == "money" then
        StaffMenu.paidShopDailyRewardEdit.Button("MODIFIER LE MONTANT", "Changer le montant", nil, "edit", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nouveau montant en " .. LOCALE.currencySymbol)
            if input then
                local amount = tonumber(input)
                if amount and amount > 0 then
                    reward.cashAmount = amount
                    local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
                    if success then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Montant modifié" })
                        fetchShopData()
                        StaffMenu.paidShopDailyRewardEdit.refresh()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
                    end
                end
            end
        end)
    elseif reward.rewardType == "item" then
        StaffMenu.paidShopDailyRewardEdit.Button("MODIFIER L'ITEM", "Changer le spawn name", nil, "edit", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nouveau spawn name")
            if input and input ~= "" then
                reward.rewardItem = input
                local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
                if success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Item modifié" })
                    fetchShopData()
                    StaffMenu.paidShopDailyRewardEdit.refresh()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
                end
            end
        end)
        StaffMenu.paidShopDailyRewardEdit.Button("MODIFIER LA QUANTITÉ", "Changer la quantité", nil, "edit", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nouvelle quantité")
            if input then
                local count = tonumber(input)
                if count and count > 0 and count == math.floor(count) then
                    reward.rewardCount = count
                    local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
                    if success then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Quantité modifiée." })
                        fetchShopData()
                        StaffMenu.paidShopDailyRewardEdit.refresh()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
                    end
                end
            end
        end)
    elseif reward.rewardType == "vehicle" then
        StaffMenu.paidShopDailyRewardEdit.Button("MODIFIER LE VÉHICULE", "Changer le modèle", nil, "edit", false, function()
            local input = VFW.Nui.KeyboardInput(true, "Nouveau spawn name véhicule")
            if input and input ~= "" then
                reward.rewardVehicle = input
                local success, message = TriggerServerCallback('paidshop:editDailyReward', reward)
                if success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Véhicule modifié" })
                    fetchShopData()
                    StaffMenu.paidShopDailyRewardEdit.refresh()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
                end
            end
        end)
    end

    StaffMenu.paidShopDailyRewardEdit.Separator("DANGER")

    -- Delete
    StaffMenu.paidShopDailyRewardEdit.Button("SUPPRIMER", "Supprimer cette récompense", nil, "trash", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer")
        if confirm and string.upper(confirm) == "OUI" then
            local success, message = TriggerServerCallback('paidshop:deleteDailyReward', reward.spawnName)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Reward', message = "Récompense supprimée" })
                fetchShopData()
                StaffMenu.paidShopDailyRewards.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Reward', message = message or "Erreur" })
            end
        end
    end)
end)

-- ==========================================
--    DISPLAYED CASES (SCANNER) MENU
-- ==========================================

local builderDisplayedCases = {}

local function refreshDisplayedCasesCache()
    local result = TriggerServerCallback('paidshop:builder:getDisplayedCases')
    if result and result.success then
        builderDisplayedCases = result.displayedCases or {}
    else
        builderDisplayedCases = {}
    end
end

local function moveCase(index, direction)
    local newIndex = index + direction
    if newIndex < 1 or newIndex > #builderDisplayedCases then return end
    builderDisplayedCases[index], builderDisplayedCases[newIndex] =
        builderDisplayedCases[newIndex], builderDisplayedCases[index]
    local result = TriggerServerCallback('paidshop:builder:setDisplayedCases', builderDisplayedCases)
    if result and result.success then
        builderDisplayedCases = result.displayedCases or builderDisplayedCases
    else
        -- rollback local
        builderDisplayedCases[index], builderDisplayedCases[newIndex] =
            builderDisplayedCases[newIndex], builderDisplayedCases[index]
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'Boutique',
            message = (result and result.error) or "Erreur lors de la sauvegarde"
      })
    end
end

local function removeCase(index)
    -- Si c'est la dernière caisse, demander confirmation (le serveur va DELETE tous les reveals joueurs)
    if #builderDisplayedCases == 1 then
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer (cela supprimera TOUS les items révélés des joueurs)")
        if not confirm or string.upper(confirm) ~= "OUI" then
            VFW.ShowNotification({
                type = 'STAFF',
                variant = 'INFO',
                subtitle = 'Boutique',
                message = "Suppression annulée"
          })
            return false
        end
    end

    local removed = table.remove(builderDisplayedCases, index)
    local result = TriggerServerCallback('paidshop:builder:setDisplayedCases', builderDisplayedCases)
    if result and result.success then
        builderDisplayedCases = result.displayedCases or builderDisplayedCases
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'SUCCESS',
            subtitle = 'Boutique',
            message = "Caisse \"" .. (removed or "?") .. "\" retirée du scanner"
      })
        return true
    else
        -- restore local cache si serveur refuse
        table.insert(builderDisplayedCases, index, removed)
        VFW.ShowNotification({
            type = 'STAFF',
            variant = 'ERROR',
            subtitle = 'Boutique',
            message = (result and result.error) or "Erreur lors de la sauvegarde"
      })
        return false
    end
end

StaffMenu.paidShopDisplayedCases.OnOpen(function()
    StaffMenu.paidShopDisplayedCases.ClearItems()
    refreshDisplayedCasesCache()

    StaffMenu.paidShopDisplayedCases.Separator("CAISSES AFFICHÉES (ordre = position scanner)")

    if #builderDisplayedCases == 0 then
        StaffMenu.paidShopDisplayedCases.Textbox(
            "Cliquez sur '+ Ajouter une caisse' ci-dessous pour configurer le scanner.",
            "Aucune caisse sélectionnée"
      )
    else
        local availableResult = TriggerServerCallback('paidshop:builder:getAvailableCases')
        local availableMap = {}
        if availableResult and availableResult.success then
            for _, ac in ipairs(availableResult.availableCases) do
                availableMap[ac.id] = ac.name
            end
        end

        for i, caseId in ipairs(builderDisplayedCases) do
            local nameLabel = availableMap[caseId] or caseId
            local label = ("%d. %s"):format(i, nameLabel)
            StaffMenu.paidShopDisplayedCases.Button(label, "↑ Monter", nil, "arrow", false, function()
                moveCase(i, -1)
                StaffMenu.paidShopDisplayedCases.refresh()
            end)
            StaffMenu.paidShopDisplayedCases.Button("  ↓ Descendre", "Déplacer cette caisse vers le bas", nil, "chevron", false, function()
                moveCase(i, 1)
                StaffMenu.paidShopDisplayedCases.refresh()
            end)
            StaffMenu.paidShopDisplayedCases.Button("  :trash: Retirer", "Retirer du scanner", nil, "trash", false, function()
                if removeCase(i) then
                    StaffMenu.paidShopDisplayedCases.refresh()
                end
            end)
        end
    end

    StaffMenu.paidShopDisplayedCases.Separator("AJOUTER")
    StaffMenu.paidShopDisplayedCases.Button(
        "+ Ajouter une caisse",
        "Choisir une caisse à afficher dans le scanner",
        nil, "plus", false,
        function() end,
        StaffMenu.paidShopAddDisplayedCase
    )
end)

StaffMenu.paidShopAddDisplayedCase.OnOpen(function()
    StaffMenu.paidShopAddDisplayedCase.ClearItems()

    local result = TriggerServerCallback('paidshop:builder:getAvailableCases')
    if not result or not result.success then
        StaffMenu.paidShopAddDisplayedCase.Textbox(
            (result and result.error) or "Impossible de charger les caisses",
            "Erreur"
      )
        return
    end

    local selectedSet = {}
    for _, id in ipairs(builderDisplayedCases) do selectedSet[id] = true end

    local hasAny = false
    for _, ac in ipairs(result.availableCases) do
        if not selectedSet[ac.id] then
            hasAny = true
            local desc = ac.isValid
                and ("Items configurés : " .. ac.possibleItemsCount)
                or ":warning: Aucun item, sélection impossible"
          StaffMenu.paidShopAddDisplayedCase.Button(
                ac.name,
                desc,
                nil, "plus", not ac.isValid,
                function()
                    if not ac.isValid then return end
                    table.insert(builderDisplayedCases, ac.id)
                    local saveResult = TriggerServerCallback('paidshop:builder:setDisplayedCases', builderDisplayedCases)
                    if saveResult and saveResult.success then
                        builderDisplayedCases = saveResult.displayedCases or builderDisplayedCases
                        VFW.ShowNotification({
                            type = 'STAFF',
                            variant = 'SUCCESS',
                            subtitle = 'Boutique',
                            message = "Caisse \"" .. ac.name .. "\" ajoutée au scanner"
                      })
                        StaffMenu.paidShopAddDisplayedCase.close()
                        StaffMenu.paidShopDisplayedCases.refresh()
                    else
                        -- rollback local
                        table.remove(builderDisplayedCases)
                        VFW.ShowNotification({
                            type = 'STAFF',
                            variant = 'ERROR',
                            subtitle = 'Boutique',
                            message = (saveResult and saveResult.error) or "Erreur lors de la sauvegarde"
                      })
                    end
                end
            )
        end
    end

    if not hasAny then
        StaffMenu.paidShopAddDisplayedCase.Textbox(
            "Aucune caisse à ajouter. Créez d'abord une caisse via Builder Boutique → Gérer les items → Caisses, ou toutes les caisses sont déjà ajoutées au scanner.",
            "Aucune caisse disponible"
      )
    end
end)

-- ==========================================
-- POUR MOI : ADD ITEM AU POOL
-- ==========================================

StaffMenu.paidShopPourMoiAdd.OnOpen(function()
    StaffMenu.paidShopPourMoiAdd.ClearItems()

    StaffMenu.paidShopPourMoiAdd.Separator("NOUVEL ITEM POUR MOI")

    -- 1) Source
    local sourceLabel = "Choisir un item source"
  if newPourMoiRef.sourceCategory and newPourMoiRef.sourceSpawnName then
        local catLabel = getCategoryLabel(newPourMoiRef.sourceCategory) or newPourMoiRef.sourceCategory
        sourceLabel = string.format("%s · %s", catLabel, newPourMoiRef.sourceLabel or newPourMoiRef.sourceSpawnName)
    end
    StaffMenu.paidShopPourMoiAdd.Button("Source: " .. sourceLabel, "Cliquez pour choisir", nil, "chevron", false, function()
        -- Reset progress when changing source
    end, StaffMenu.paidShopPourMoiSourceCat)

    -- 2) Rareté
    local rarityLabel = newPourMoiRef.rarity and (rarityLabels[newPourMoiRef.rarity] or newPourMoiRef.rarity) or "Choisir"
  StaffMenu.paidShopPourMoiAdd.Button("Rareté: " .. rarityLabel, "Pondère le tirage", nil, "chevron", false, function() end, StaffMenu.paidShopPourMoiRarity)

    -- 3) Réduction %
    local reductionLabel = newPourMoiRef.reductionPercent and (newPourMoiRef.reductionPercent .. " %") or "Non définie"
  local previewSubtitle = "Cliquez pour saisir (0-90)"
  if newPourMoiRef.reductionPercent and newPourMoiRef.sourcePrice then
        local computed = math.floor(newPourMoiRef.sourcePrice * (1 - newPourMoiRef.reductionPercent / 100))
        previewSubtitle = string.format("Prix résultant: %d SC (au lieu de %d SC)", computed, newPourMoiRef.sourcePrice)
    end
    StaffMenu.paidShopPourMoiAdd.Button("Réduction: " .. reductionLabel, previewSubtitle, nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Pourcentage de réduction (0-90)", tostring(newPourMoiRef.reductionPercent or 25))
        local val = tonumber(input)
        if val and val >= 0 and val <= 90 then
            newPourMoiRef.reductionPercent = math.floor(val)
            StaffMenu.paidShopPourMoiAdd.refresh()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pour Moi', message = "Cette réduction n'est pas valide (0 à 90)" })
        end
    end)

    StaffMenu.paidShopPourMoiAdd.Separator("")

    -- Submit
    StaffMenu.paidShopPourMoiAdd.Button("AJOUTER AU POOL", "Valider et enregistrer", nil, "check", false, function()
        if isSaving then return end
        if not newPourMoiRef.sourceCategory or not newPourMoiRef.sourceSpawnName then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pour Moi', message = "Item source requis" })
            return
        end
        if not newPourMoiRef.rarity then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pour Moi', message = "Rareté requise" })
            return
        end
        if not newPourMoiRef.reductionPercent then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pour Moi', message = "Réduction requise" })
            return
        end

        isSaving = true
        local ok, msg = TriggerServerCallback('paidshop:adminAddPourMoiItem',
            newPourMoiRef.sourceCategory, newPourMoiRef.sourceSpawnName,
            newPourMoiRef.rarity, newPourMoiRef.reductionPercent)
        isSaving = false

        VFW.ShowNotification({
            type = 'STAFF', variant = ok and 'SUCCESS' or 'ERROR',
            subtitle = 'Pour Moi', message = msg or (ok and "Ajouté" or "Échec")
        })

        if ok then
            newPourMoiRef = {}
            fetchPourMoiPool()
            StaffMenu.paidShopPourMoiAdd.close()
            StaffMenu.paidShopItemCategory.open()
        end
    end)
end)

-- ==========================================
-- POUR MOI : CHOISIR CATÉGORIE SOURCE
-- ==========================================

StaffMenu.paidShopPourMoiSourceCat.OnOpen(function()
    StaffMenu.paidShopPourMoiSourceCat.ClearItems()
    fetchShopData()

    StaffMenu.paidShopPourMoiSourceCat.Separator("CATÉGORIES ÉLIGIBLES")

    local hasAny = false
    for _, category in ipairs(PaidShopCache.categories) do
        if not pourMoiBlockedSourceCategories[category.id] then
            local count = getItemsCount(category.id)
            hasAny = true
            local cId = category.id
            StaffMenu.paidShopPourMoiSourceCat.Button(
                string.upper(category.label),
                count .. " items",
                nil, "chevron", false,
                function() newPourMoiRef.sourceCategory = cId end,
                StaffMenu.paidShopPourMoiSourceItem
            )
        end
    end

    if not hasAny then
        StaffMenu.paidShopPourMoiSourceCat.Button("Aucune catégorie disponible", nil, nil, nil, true, function() end)
    end
end)

-- ==========================================
-- POUR MOI : CHOISIR ITEM SOURCE
-- ==========================================

StaffMenu.paidShopPourMoiSourceItem.OnOpen(function()
    StaffMenu.paidShopPourMoiSourceItem.ClearItems()

    if not newPourMoiRef.sourceCategory then
        StaffMenu.paidShopPourMoiSourceItem.Button("Erreur", "Pas de catégorie sélectionnée", nil, nil, true, function() end)
        return
    end

    local items = PaidShopCache.items[newPourMoiRef.sourceCategory] or {}
    local catLabel = getCategoryLabel(newPourMoiRef.sourceCategory)

    StaffMenu.paidShopPourMoiSourceItem.Separator("ITEMS - " .. string.upper(catLabel or newPourMoiRef.sourceCategory))

    if #items == 0 then
        StaffMenu.paidShopPourMoiSourceItem.Button("Aucun item", "Cette catégorie est vide", nil, nil, true, function() end)
        return
    end

    -- Anti-doublon : on cache les items déjà dans le pool
    fetchPourMoiPool()

    for _, item in ipairs(items) do
        if item.spawnName then
            local already = isInPourMoiPool(newPourMoiRef.sourceCategory, item.spawnName)
            local icon = already and "check" or "chevron"
          local subTitle = (item.price or 0) .. " SC"
          if already then subTitle = subTitle .. " · DÉJÀ DANS LE POOL" end

            local capturedItem = item
            StaffMenu.paidShopPourMoiSourceItem.Button(
                item.name or item.spawnName,
                subTitle,
                nil, icon, already,
                function()
                    if already then return end
                    newPourMoiRef.sourceSpawnName = capturedItem.spawnName
                    newPourMoiRef.sourceLabel    = capturedItem.name or capturedItem.spawnName
                    newPourMoiRef.sourcePrice    = capturedItem.price or 0
                    StaffMenu.paidShopPourMoiSourceItem.close()
                    StaffMenu.paidShopPourMoiAdd.open()
                end
            )
        end
    end
end)

-- ==========================================
-- POUR MOI : CHOISIR RARETÉ (add)
-- ==========================================

StaffMenu.paidShopPourMoiRarity.OnOpen(function()
    StaffMenu.paidShopPourMoiRarity.ClearItems()
    StaffMenu.paidShopPourMoiRarity.Separator("RARETÉ")

    for _, r in ipairs(rarityOptions) do
        local capturedR = r
        local isSelected = newPourMoiRef.rarity == r
        StaffMenu.paidShopPourMoiRarity.Button(
            rarityLabels[r] or r,
            "Tier " .. r,
            nil, isSelected and "check" or "empty", false,
            function()
                newPourMoiRef.rarity = capturedR
                StaffMenu.paidShopPourMoiRarity.close()
                StaffMenu.paidShopPourMoiAdd.open()
            end
        )
    end
end)

-- ==========================================
-- POUR MOI : EDIT POOL ITEM
-- ==========================================

StaffMenu.paidShopPourMoiEdit.OnOpen(function()
    StaffMenu.paidShopPourMoiEdit.ClearItems()

    if not selectedPourMoiRef then
        StaffMenu.paidShopPourMoiEdit.Button("Erreur", "Aucun item sélectionné", nil, nil, true, function() end)
        return
    end

    local ref = selectedPourMoiRef
    StaffMenu.paidShopPourMoiEdit.Separator("ITEM: " .. (ref.sourceLabel or ref.sourceSpawnName))

    -- Source en lecture seule
    StaffMenu.paidShopPourMoiEdit.Button(
        "Source: " .. (ref.sourceLabel or ref.sourceSpawnName),
        string.upper(ref.sourceCategory or "?") .. " · " .. (ref.sourcePrice or 0) .. " SC, non modifiable, supprimez puis rajoutez",
        nil, nil, true, function() end
    )

    -- Rareté modifiable
    StaffMenu.paidShopPourMoiEdit.Button(
        "Rareté: " .. (rarityLabels[ref.rarity] or ref.rarity),
        "Cliquez pour modifier",
        nil, "chevron", false, function() end,
        StaffMenu.paidShopPourMoiEditRarity
    )

    -- Réduction modifiable
    local computedPrice = math.floor((ref.sourcePrice or 0) * (1 - (ref.reductionPercent or 0) / 100))
    StaffMenu.paidShopPourMoiEdit.Button(
        "Réduction: " .. (ref.reductionPercent or 0) .. " %",
        "Prix résultant: " .. computedPrice .. " SC · cliquez pour modifier",
        nil, "chevron", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nouvelle réduction (0-90)", tostring(ref.reductionPercent or 25))
            local val = tonumber(input)
            if not val or val < 0 or val > 90 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Pour Moi', message = "Cette réduction n'est pas valide (0-90)" })
                return
            end
            if isSaving then return end
            isSaving = true
            local ok, msg = TriggerServerCallback('paidshop:adminUpdatePourMoiItem',
                ref.sourceCategory, ref.sourceSpawnName, ref.rarity, math.floor(val))
            isSaving = false
            VFW.ShowNotification({
                type = 'STAFF', variant = ok and 'SUCCESS' or 'ERROR',
                subtitle = 'Pour Moi', message = msg or (ok and "Modifié" or "Échec")
            })
            if ok then
                ref.reductionPercent = math.floor(val)
                fetchPourMoiPool()
                StaffMenu.paidShopPourMoiEdit.refresh()
            end
        end
    )

    StaffMenu.paidShopPourMoiEdit.Separator("")

    -- Suppression
    StaffMenu.paidShopPourMoiEdit.Button("SUPPRIMER DU POOL", "L'item ne sera plus tirable", nil, "trash", false, function()
        if isSaving then return end
        local confirm = VFW.Nui.KeyboardInput(true, "Confirmer la suppression ? (OUI/NON)", "")
        if not confirm or not string.match(string.upper(confirm), "^%s*OUI%s*$") then
            return
        end
        isSaving = true
        local ok, msg = TriggerServerCallback('paidshop:adminRemovePourMoiItem',
            ref.sourceCategory, ref.sourceSpawnName)
        isSaving = false
        VFW.ShowNotification({
            type = 'STAFF', variant = ok and 'SUCCESS' or 'ERROR',
            subtitle = 'Pour Moi', message = msg or (ok and "Supprimé" or "Échec")
        })
        if ok then
            selectedPourMoiRef = nil
            fetchPourMoiPool()
            StaffMenu.paidShopPourMoiEdit.close()
            StaffMenu.paidShopItemCategory.open()
        end
    end)
end)

-- ==========================================
-- POUR MOI : EDIT RARITY (sub-menu de paidShopPourMoiEdit)
-- ==========================================

StaffMenu.paidShopPourMoiEditRarity.OnOpen(function()
    StaffMenu.paidShopPourMoiEditRarity.ClearItems()
    StaffMenu.paidShopPourMoiEditRarity.Separator("MODIFIER RARETÉ")

    if not selectedPourMoiRef then
        StaffMenu.paidShopPourMoiEditRarity.Button("Erreur", "Aucun item sélectionné", nil, nil, true, function() end)
        return
    end

    local ref = selectedPourMoiRef
    for _, r in ipairs(rarityOptions) do
        local capturedR = r
        local isSelected = ref.rarity == r
        StaffMenu.paidShopPourMoiEditRarity.Button(
            rarityLabels[r] or r,
            "Tier " .. r,
            nil, isSelected and "check" or "empty", false,
            function()
                if isSelected then
                    StaffMenu.paidShopPourMoiEditRarity.close()
                    return
                end
                if isSaving then return end
                isSaving = true
                local ok, msg = TriggerServerCallback('paidshop:adminUpdatePourMoiItem',
                    ref.sourceCategory, ref.sourceSpawnName, capturedR, ref.reductionPercent or 0)
                isSaving = false
                VFW.ShowNotification({
                    type = 'STAFF', variant = ok and 'SUCCESS' or 'ERROR',
                    subtitle = 'Pour Moi', message = msg or (ok and "Rareté modifiée" or "Échec")
                })
                if ok then
                    ref.rarity = capturedR
                    fetchPourMoiPool()
                    StaffMenu.paidShopPourMoiEditRarity.close()
                    StaffMenu.paidShopPourMoiEdit.open()
                end
            end
        )
    end
end)

-- ==========================================
--     DAILY STREAK 7 JOURS — Builder
-- ==========================================
--
-- Liste des 7 slots (Jour 1 à 7). Chaque slot ouvre un sous-menu d'édition
-- où l'admin choisit le type (SC / argent / item / véhicule) et les détails.
-- La source de vérité est côté serveur (paidshop:adminGetDailyStreak), persistée
-- via paidshop_items (category = '__daily_streak').
-- ==========================================

local dailyStreakCache = {}     -- slots indexés par numéro (1..7)
local selectedStreakSlot = nil  -- slot en cours d'édition
local streakDraft = {}          -- payload en cours pour l'édition

local streakTypeLabels = {
    spacecoins = "Coins",
    money      = "Argent",
    item       = "Item",
    vehicle    = "Véhicule",
}
local streakTypeOrder = { "spacecoins", "money", "item", "vehicle" }

-- Charge les 7 slots depuis le serveur
local function fetchDailyStreak()
    local res = TriggerServerCallback('paidshop:adminGetDailyStreak')
    dailyStreakCache = {}
    if res and res.success and type(res.slots) == "table" then
        for slot = 1, 7 do
            dailyStreakCache[slot] = res.slots[slot] or res.slots[tostring(slot)]
        end
    end
    return dailyStreakCache
end

local function streakSlotSubtitle(slot)
    local s = dailyStreakCache[slot]
    if not s then return "Aucun" end
    return (streakTypeLabels[s.type] or s.type or "?") .. " · " .. (s.label or "?")
end

StaffMenu.paidShopDailyStreak.OnOpen(function()
    StaffMenu.paidShopDailyStreak.ClearItems()
    fetchDailyStreak()

    StaffMenu.paidShopDailyStreak.Separator("CYCLE 7 JOURS")

    for slot = 1, 7 do
        local capturedSlot = slot
        StaffMenu.paidShopDailyStreak.Button(
            "JOUR " .. slot,
            streakSlotSubtitle(slot),
            nil, "chevron", false,
            function()
                selectedStreakSlot = capturedSlot
                local current = dailyStreakCache[capturedSlot] or { type = "spacecoins", amount = 50 }
                streakDraft = {
                    type     = current.type or "spacecoins",
                    amount   = current.amount,
                    item     = current.item,
                    count    = current.count,
                    itemLabel = current.itemLabel,
                    vehicle  = current.vehicle,
                    vehicleLabel = current.vehicleLabel,
                    label    = current.label,
                }
            end,
            StaffMenu.paidShopDailyStreakSlot
        )
    end

    StaffMenu.paidShopDailyStreak.Separator("AIDE")
    StaffMenu.paidShopDailyStreak.Button(
        "Comportement du streak",
        "Si un joueur loupe un jour, il reprend où il en était (pas de reset).",
        nil, nil, true
    )
end)

-- Sous-menu d'édition d'un slot précis
StaffMenu.paidShopDailyStreakSlot.OnOpen(function()
    StaffMenu.paidShopDailyStreakSlot.ClearItems()
    if not selectedStreakSlot then return end

    StaffMenu.paidShopDailyStreakSlot.Separator("JOUR " .. selectedStreakSlot)

    -- Type (List)
    local typeIndex = 1
    for i, t in ipairs(streakTypeOrder) do
        if streakDraft.type == t then typeIndex = i end
    end
    local typeLabelList = {}
    for _, t in ipairs(streakTypeOrder) do
        table.insert(typeLabelList, streakTypeLabels[t])
    end
    StaffMenu.paidShopDailyStreakSlot.List("TYPE", "Type de récompense", false, typeLabelList, typeIndex, function(index)
        streakDraft.type = streakTypeOrder[index]
        StaffMenu.paidShopDailyStreakSlot.refresh()
    end)

    -- Champs spécifiques selon le type
    local t = streakDraft.type or "spacecoins"
  if t == "spacecoins" or t == "money" then
        StaffMenu.paidShopDailyStreakSlot.Button(
            "MONTANT",
            (streakDraft.amount and tostring(streakDraft.amount)) or "Cliquez pour définir",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Montant (entier)")
                if input then
                    local n = tonumber(input)
                    if n and n >= 0 then
                        streakDraft.amount = math.floor(n)
                        StaffMenu.paidShopDailyStreakSlot.refresh()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Streak', message = "Ce montant n'est pas valide" })
                    end
                end
            end
        )
    elseif t == "item" then
        StaffMenu.paidShopDailyStreakSlot.Button(
            "SPAWN NAME ITEM",
            (streakDraft.item and streakDraft.item ~= "" and streakDraft.item) or "Cliquez pour définir",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Spawn name de l'item")
                if input and input ~= "" then
                    streakDraft.item = input
                    StaffMenu.paidShopDailyStreakSlot.refresh()
                end
            end
        )
        StaffMenu.paidShopDailyStreakSlot.Button(
            "QUANTITÉ",
            tostring(streakDraft.count or 1),
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Quantité")
                if input then
                    local n = tonumber(input)
                    if n and n > 0 and n == math.floor(n) then
                        streakDraft.count = n
                        StaffMenu.paidShopDailyStreakSlot.refresh()
                    else
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Streak', message = "Cette quantité n'est pas valide" })
                    end
                end
            end
        )
        StaffMenu.paidShopDailyStreakSlot.Button(
            "NOM AFFICHÉ (optionnel)",
            (streakDraft.itemLabel and streakDraft.itemLabel ~= "" and streakDraft.itemLabel) or "Auto",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nom affiché de l'item")
                if input then
                    streakDraft.itemLabel = input
                    StaffMenu.paidShopDailyStreakSlot.refresh()
                end
            end
        )
    elseif t == "vehicle" then
        StaffMenu.paidShopDailyStreakSlot.Button(
            "MODÈLE VÉHICULE",
            (streakDraft.vehicle and streakDraft.vehicle ~= "" and streakDraft.vehicle) or "Cliquez pour définir",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Spawn name du véhicule")
                if input and input ~= "" then
                    streakDraft.vehicle = input
                    StaffMenu.paidShopDailyStreakSlot.refresh()
                end
            end
        )
        StaffMenu.paidShopDailyStreakSlot.Button(
            "NOM AFFICHÉ (optionnel)",
            (streakDraft.vehicleLabel and streakDraft.vehicleLabel ~= "" and streakDraft.vehicleLabel) or "Auto",
            nil, "edit", false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nom affiché du véhicule")
                if input then
                    streakDraft.vehicleLabel = input
                    StaffMenu.paidShopDailyStreakSlot.refresh()
                end
            end
        )
    end

    -- Override label (affiché dans le bouton "Réclamer")
    StaffMenu.paidShopDailyStreakSlot.Button(
        "LABEL BOUTON (optionnel)",
        (streakDraft.label and streakDraft.label ~= "" and streakDraft.label) or "Auto",
        nil, "edit", false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Texte court (ex: Jackpot, +200 SC)")
            if input then
                streakDraft.label = input
                StaffMenu.paidShopDailyStreakSlot.refresh()
            end
        end
    )

    StaffMenu.paidShopDailyStreakSlot.Separator("")

    -- Sauvegarde
    StaffMenu.paidShopDailyStreakSlot.Button("SAUVEGARDER", "Enregistrer ce slot", nil, "check", false, function()
        if not selectedStreakSlot then return end

        -- Validations côté client (le serveur revalide)
        local ty = streakDraft.type
        if ty == "spacecoins" or ty == "money" then
            if not streakDraft.amount or streakDraft.amount < 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Streak', message = "Montant requis" })
                return
            end
        elseif ty == "item" then
            if not streakDraft.item or streakDraft.item == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Streak', message = "Spawn name requis" })
                return
            end
        elseif ty == "vehicle" then
            if not streakDraft.vehicle or streakDraft.vehicle == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Streak', message = "Modèle véhicule requis" })
                return
            end
        end

        local ok, msg = TriggerServerCallback('paidshop:adminEditDailyStreakSlot', selectedStreakSlot, streakDraft)
        if ok then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Daily Streak', message = msg or "Slot enregistré" })
            fetchDailyStreak()
            StaffMenu.paidShopDailyStreakSlot.close()
            StaffMenu.paidShopDailyStreak.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Daily Streak', message = msg or "Erreur" })
        end
    end)
end)

-- ==========================================
--          CATEGORY TOGGLE (ON / OFF)
-- ==========================================
-- Liste toutes les catégories (y compris désactivées) avec leur état courant.
-- Clic sur une catégorie : toggle. Confirmation requise pour la désactivation.

StaffMenu.paidShopCategoryToggle.OnOpen(function()
    StaffMenu.paidShopCategoryToggle.ClearItems()

    local ok, categories = TriggerServerCallback('paidshop:adminGetAllCategories')
    if not ok or type(categories) ~= "table" then
        StaffMenu.paidShopCategoryToggle.Button(
            "Erreur",
            "Impossible de récupérer la liste des catégories",
            nil, nil, true, function() end
        )
        return
    end

    StaffMenu.paidShopCategoryToggle.Separator("ÉTAT GLOBAL DES CATÉGORIES")

    for _, category in ipairs(categories) do
        local statusBadge = category.enabled and "[ ACTIVE ]" or "[ DÉSACTIVÉE ]"
      local subtitle = category.enabled
            and "Visible pour tous les joueurs · Cliquer pour désactiver"
          or "Masquée pour tous les joueurs · Cliquer pour réactiver"

      StaffMenu.paidShopCategoryToggle.Button(
            string.upper(category.label) .. " " .. statusBadge,
            subtitle,
            nil,
            "chevron",
            false,
            function()
                if category.enabled then
                    VFW.Nui.Focus(true)
                    local confirmed = VFW.Nui.ConfirmPopup(
                        "Désactiver la catégorie " .. category.label .. " ?",
                        "Elle sera masquée pour tous les joueurs au prochain accès à la boutique."
                  )
                    VFW.Nui.Focus(false)
                    if not confirmed then return end
                end

                local newState = not category.enabled
                local cbOk, msg = TriggerServerCallback('paidshop:adminSetCategoryEnabled', category.id, newState)

                if cbOk then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'SUCCESS',
                        subtitle = 'Boutique',
                        message = msg or (newState and "Catégorie activée" or "Catégorie désactivée")
                    })
                else
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Boutique',
                        message = msg or "Erreur lors du toggle"
                  })
                end

                StaffMenu.paidShopCategoryToggle.refresh()
            end
        )
    end

    StaffMenu.paidShopCategoryToggle.Separator("INFO")
    StaffMenu.paidShopCategoryToggle.Button(
        "Comportement",
        "Les catégories désactivées sont masquées de la sidebar boutique pour tous les joueurs.",
        nil, nil, true, function() end
    )
end)
