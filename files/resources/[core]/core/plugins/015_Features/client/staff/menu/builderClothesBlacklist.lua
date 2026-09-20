-- ============================================================
-- Staff Menu: Clothes Blacklist Builder
-- 3-level menu: Gender > Category > Items (with live preview)
-- ============================================================

local BLACKLIST_CATEGORIES = {
    -- Vetements (Config.ClothesBan)
    { banKey = "BanTop",       label = "Hauts",              componentId = 11, type = "drawable", skinKey = "torso_1",    config = "clothes", separator = "VETEMENTS" },
    { banKey = "BanSous",      label = "Sous-hauts",         componentId = 8,  type = "drawable", skinKey = "tshirt_1",   config = "clothes" },
    { banKey = "BanArm",       label = "Bras",               componentId = 3,  type = "drawable", skinKey = "arms",       config = "clothes" },
    { banKey = "BanLeg",       label = "Pantalons",          componentId = 4,  type = "drawable", skinKey = "pants_1",    config = "clothes" },
    { banKey = "BanShoes",     label = "Chaussures",         componentId = 6,  type = "drawable", skinKey = "shoes_1",    config = "clothes" },
    { banKey = "BanBag",       label = "Sacs",               componentId = 5,  type = "drawable", skinKey = "bags_1",     config = "clothes" },
    { banKey = "BanCou",       label = "Colliers vetements", componentId = 7,  type = "drawable", skinKey = "chain_1",    config = "clothes" },
    { banKey = "BanMasque",    label = "Masques",            componentId = 1,  type = "drawable", skinKey = "mask_1",     config = "clothes" },
    { banKey = "BanKevlar",    label = "Gilets pare-balles", componentId = 9,  type = "drawable", skinKey = "bproof_1",   config = "clothes" },
    { banKey = "BanHat",       label = "Chapeaux",           componentId = 0,  type = "prop",     skinKey = "helmet_1",   config = "clothes" },
    { banKey = "BanGlases",    label = "Lunettes",           componentId = 1,  type = "prop",     skinKey = "glasses_1",  config = "clothes" },
    { banKey = "BanWatch",     label = "Montres",            componentId = 6,  type = "prop",     skinKey = "watches_1",  config = "clothes" },
    { banKey = "BanEarring",   label = "Boucles d'oreilles", componentId = 2,  type = "prop",     skinKey = "ears_1",     config = "clothes" },
    { banKey = "BanBracelet",  label = "Bracelets",          componentId = 7,  type = "prop",     skinKey = "bracelets_1",config = "clothes" },
    { banKey = "BanNecklace",  label = "Colliers accessoire",componentId = 7,  type = "drawable", skinKey = "chain_1",    config = "clothes" },
}

local ITEMS_PER_PAGE = 50

-- State
local currentBlacklistGender = nil
local currentBlacklistCategory = nil
local currentBlacklistPage = 0
local savedSkinBeforePreview = nil
local showBannedOnly = false

-- ============================================================
-- Helper: Check if an ID is in a static ban list
-- ============================================================
local function IsStaticBan(gender, banKey, drawableId)
    local staticConfig = Config.StaticClothesBan
    if not staticConfig then return false end
    if not staticConfig[gender] then return false end
    if not staticConfig[gender][banKey] then return false end
    return VFW.Table.TableContains(staticConfig[gender][banKey], drawableId)
end

-- ============================================================
-- Helper: Check if an ID is in a dynamic ban list
-- ============================================================
local function IsDynamicBan(dynamicBans, gender, banKey, drawableId)
    if not dynamicBans then return false end
    if not dynamicBans[gender] then return false end
    if not dynamicBans[gender][banKey] then return false end
    return VFW.Table.TableContains(dynamicBans[gender][banKey], drawableId)
end

-- ============================================================
-- Helper: Get number of variations for a category
-- ============================================================
local function GetVariationCount(playerPed, cat)
    if cat.type == "prop" then
        return GetNumberOfPedPropDrawableVariations(playerPed, cat.componentId)
    else
        return GetNumberOfPedDrawableVariations(playerPed, cat.componentId)
    end
end

-- ============================================================
-- Helper: Apply a preview on the player ped
-- ============================================================
local function ApplyPreview(cat, drawableId)
    TriggerEvent("skinchanger:change", cat.skinKey, drawableId)
end

-- ============================================================
-- Level 1: Gender selection
-- ============================================================
function StaffMenu.BuildClothesBlacklistMenu()
    if not StaffMenu or not StaffMenu.clothesBlacklist then return end

    StaffMenu.clothesBlacklist.Separator("SELECTION DU GENRE")

    StaffMenu.clothesBlacklist.Button("Homme", "Gerer les bans pour les personnages masculins", nil, "chevron", false, function()
        currentBlacklistGender = "Homme"
  end, StaffMenu.clothesBlacklistGender)

    StaffMenu.clothesBlacklist.Button("Femme", "Gerer les bans pour les personnages feminins", nil, "chevron", false, function()
        currentBlacklistGender = "Femme"
  end, StaffMenu.clothesBlacklistGender)
end

-- ============================================================
-- Level 2: Category list (with ban counts)
-- ============================================================
function StaffMenu.BuildClothesBlacklistGenderMenu()
    if not StaffMenu or not StaffMenu.clothesBlacklistGender then return end
    if not currentBlacklistGender then return end

    local stats = TriggerServerCallback("clothesBlacklist:getStats", currentBlacklistGender)

    StaffMenu.clothesBlacklistGender.Separator("CATEGORIES - " .. currentBlacklistGender)

    for _, cat in ipairs(BLACKLIST_CATEGORIES) do
        if cat.separator then
            StaffMenu.clothesBlacklistGender.Separator(cat.separator)
        end

        local catDbKey = cat.dbKey or cat.banKey
        local count = (stats and stats[catDbKey]) or 0
        local rightLabel = count > 0 and (count .. " bannis") or ""

      StaffMenu.clothesBlacklistGender.Button(cat.label, "Gerer les bans: " .. cat.label, rightLabel, "chevron", false, function()
            currentBlacklistCategory = cat
            currentBlacklistPage = 0
        end, StaffMenu.clothesBlacklistCategory)
    end
end

-- ============================================================
-- Level 3: Items list (with preview, pagination, toggle)
-- ============================================================
function StaffMenu.BuildClothesBlacklistCategoryMenu()
    if not StaffMenu or not StaffMenu.clothesBlacklistCategory then return end
    if not currentBlacklistGender or not currentBlacklistCategory then return end

    local cat = currentBlacklistCategory
    local gender = currentBlacklistGender
    local dbKey = cat.banKey
    local playerPed = PlayerPedId()
    local totalItems = GetVariationCount(playerPed, cat)

    -- Fetch dynamic bans for this category
    local dynamicBans = TriggerServerCallback("clothesBlacklist:getAll")

    -- Save skin on first open
    if not savedSkinBeforePreview then
        TriggerEvent("skinchanger:getSkin", function(skinData)
            savedSkinBeforePreview = skinData
        end)
    end

    -- Build item list (filtered or full)
    local itemsList = {}
    if showBannedOnly then
        for i = 0, totalItems - 1 do
            if IsStaticBan(gender, cat.banKey, i) or IsDynamicBan(dynamicBans, gender, dbKey, i) then
                table.insert(itemsList, i)
            end
        end
    else
        for i = 0, totalItems - 1 do
            table.insert(itemsList, i)
        end
    end

    -- Pagination
    local totalFiltered = #itemsList
    local totalPages = math.max(math.ceil(totalFiltered / ITEMS_PER_PAGE), 1)
    if currentBlacklistPage >= totalPages then currentBlacklistPage = totalPages - 1 end
    local startIdx = currentBlacklistPage * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, totalFiltered)

    StaffMenu.clothesBlacklistCategory.Separator(
        string.format("%s - %s (Page %d/%d)", cat.label, gender, currentBlacklistPage + 1, totalPages)
    )

    -- Filter checkbox
    StaffMenu.clothesBlacklistCategory.Checkbox("Afficher uniquement les bannis", nil, false, showBannedOnly, function(_checked)
        showBannedOnly = _checked
        currentBlacklistPage = 0
        StaffMenu.clothesBlacklistCategory.refresh()
    end)

    -- Navigation buttons
    if totalPages > 1 then
        if currentBlacklistPage > 0 then
            StaffMenu.clothesBlacklistCategory.Button("< Page precedente", nil, nil, "arrow", false, function()
                currentBlacklistPage = currentBlacklistPage - 1
                StaffMenu.clothesBlacklistCategory.refresh()
            end)
        end

        if not showBannedOnly then
            StaffMenu.clothesBlacklistCategory.Button("Aller a l'ID...", "Entrer un ID pour y acceder directement", nil, "arrow", false, function()
                local input = VFW.Nui.KeyboardInput(true, "Entrer l'ID du drawable (0 a " .. (totalItems - 1) .. ")")
                local targetId = tonumber(input)
                if targetId and targetId >= 0 and targetId < totalItems then
                    currentBlacklistPage = math.floor(targetId / ITEMS_PER_PAGE)
                    StaffMenu.clothesBlacklistCategory.refresh()
                elseif input and input ~= "" then
                    VFW.ShowNotification({type = "STAFF", variant = "ERROR", subtitle = "Blacklist", message = "Cet identifiant n'est pas valide"})
                end
            end)
        end

        if currentBlacklistPage < totalPages - 1 then
            StaffMenu.clothesBlacklistCategory.Button("Page suivante >", nil, nil, "arrow", false, function()
                currentBlacklistPage = currentBlacklistPage + 1
                StaffMenu.clothesBlacklistCategory.refresh()
            end)
        end
    end

    StaffMenu.clothesBlacklistCategory.Separator(showBannedOnly and string.format("BANNIS (%d)", totalFiltered) or "ITEMS")

    -- Item list
    for idx = startIdx, endIdx do
        local i = itemsList[idx]
        local isStatic = IsStaticBan(gender, cat.banKey, i)
        local isDynamic = IsDynamicBan(dynamicBans, gender, dbKey, i)

        local rightLabel
        if isStatic then
            rightLabel = "STATIQUE"
      elseif isDynamic then
            rightLabel = "BANNI"
      else
            rightLabel = "OK"
      end

        StaffMenu.clothesBlacklistCategory.Button(string.format("#%d", i), nil, rightLabel, nil, false, function()
            -- Preview
            ApplyPreview(cat, i)

            if isStatic then
                VFW.ShowNotification({type = "STAFF", variant = "INFO", subtitle = "Blacklist", message = "Ban statique (non modifiable via le menu)"})
                return
            end

            -- Toggle ban
            local result = TriggerServerCallback("clothesBlacklist:toggleBan", gender, dbKey, i)
            if result and result.success then
                local actionMsg = result.action == "banned" and "BANNI" or "DEBANNI"
              VFW.ShowNotification({type = "STAFF", variant = "SUCCESS", subtitle = "Blacklist", message = string.format("Item #%d %s", i, actionMsg)})
                StaffMenu.clothesBlacklistCategory.refresh()
            else
                VFW.ShowNotification({type = "STAFF", variant = "ERROR", subtitle = "Blacklist", message = result and result.message or "Erreur"})
            end
        end)
    end
end

-- ============================================================
-- OnClose: Restore skin
-- ============================================================
RegisterNetEvent("clothesBlacklistCategory:onClose")
AddEventHandler("clothesBlacklistCategory:onClose", function()
    if savedSkinBeforePreview then
        TriggerEvent("skinchanger:loadSkin", savedSkinBeforePreview)
        savedSkinBeforePreview = nil
    end
end)
