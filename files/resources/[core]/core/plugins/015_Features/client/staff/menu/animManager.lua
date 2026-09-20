-- ═══════════════════════════════════════════════════════
-- Animation Manager — Staff Menu (Développeurs)
-- ═══════════════════════════════════════════════════════

local selectedAnimName = nil
local selectedAnimData = nil
local selectedCategory = nil
local cachedOverrides = {}
local animsByCategory = nil

-- Pagination & search state for animation list
local ANIMS_PER_PAGE = 30
local animListPage = 1
local animListQuery = nil

-- ── Helpers ──

--- Builds a map { categoryName = { {name, originalLabel, type}, ... } } sorted
local function GetAnimsByCategory()
    if animsByCategory then return animsByCategory end

    local map = {}
    for categoryName, group in pairs(RP) do
        local type = group.type or "emote"
      map[categoryName] = {}
        for key, v in pairs(group) do
            if key ~= "type" and key ~= "icon" and key ~= "label" then
                local label = v[3] or v[2] or key
                table.insert(map[categoryName], {
                    name = key,
                    originalLabel = label,
                    originalCategory = categoryName,
                    type = type,
                    custom = v.custom == true,
                })
            end
        end
        table.sort(map[categoryName], function(a, b)
            return string.lower(a.originalLabel) < string.lower(b.originalLabel)
        end)
    end

    animsByCategory = map
    return map
end

--- Invalide le cache (appelé quand les animations personnalisées changent)
function StaffMenu.ResetAnimManagerCache()
    animsByCategory = nil
end

--- Returns sorted list of category names from RP.*
local function GetCategoryNames()
    local names = {}
    for categoryName, _ in pairs(RP) do
        table.insert(names, categoryName)
    end
    table.sort(names)
    return names
end

-- ═══════════════════════════════════════════════════════
-- Main Menu: Liste des catégories
-- ═══════════════════════════════════════════════════════

function StaffMenu.BuildAnimManagerMenu()
    cachedOverrides = TriggerServerCallback("vfw:animManager:getOverrides") or {}

    local allByCategory = GetAnimsByCategory()
    local categories = GetCategoryNames()

    -- Stats
    local totalAnims = 0
    local disabledCount = 0
    local modifiedCount = 0
    for _, anims in pairs(allByCategory) do
        totalAnims = totalAnims + #anims
    end
    for _, override in pairs(cachedOverrides) do
        if override.disabled then disabledCount = disabledCount + 1 end
        modifiedCount = modifiedCount + 1
    end

    StaffMenu.animManager.Separator(totalAnims .. " anims | " .. disabledCount .. " désactivées | " .. modifiedCount .. " modifiées")

    -- List categories
    for _, catName in ipairs(categories) do
        local anims = allByCategory[catName] or {}
        local catDisabled = 0
        local catModified = 0
        for _, anim in ipairs(anims) do
            local ov = cachedOverrides[anim.name]
            if ov then
                catModified = catModified + 1
                if ov.disabled then catDisabled = catDisabled + 1 end
            end
        end

        local desc = #anims .. " animations"
      if catModified > 0 then
            desc = desc .. ", " .. catModified .. (catModified > 1 and " modifiées" or " modifiée")
      end
        if catDisabled > 0 then
            desc = desc .. ", " .. catDisabled .. (catDisabled > 1 and " désactivées" or " désactivée")
      end

        local icon = RP[catName] and RP[catName].icon or ":film:"

      StaffMenu.animManager.Button(icon .. " " .. catName, desc, nil, "chevron", false, function()
            selectedCategory = catName
            animListPage = 1
            animListQuery = nil
        end, StaffMenu.animManagerList)
    end
end

-- ═══════════════════════════════════════════════════════
-- List Menu: Animations d'une catégorie
-- ═══════════════════════════════════════════════════════

function StaffMenu.BuildAnimManagerListMenu()
    if not selectedCategory then return end

    local allByCategory = GetAnimsByCategory()
    local allAnims = allByCategory[selectedCategory] or {}

    -- Filter by search query
    local anims
    if animListQuery then
        local lq = string.lower(animListQuery)
        anims = {}
        for _, anim in ipairs(allAnims) do
            local override = cachedOverrides[anim.name] or {}
            local effectiveLabel = override.label or anim.originalLabel
            if string.find(string.lower(effectiveLabel), lq, 1, true)
                or string.find(string.lower(anim.name), lq, 1, true) then
                table.insert(anims, anim)
            end
        end
    else
        anims = allAnims
    end

    local totalAnims = #anims
    local totalPages = math.max(1, math.ceil(totalAnims / ANIMS_PER_PAGE))

    -- Clamp page
    if animListPage > totalPages then animListPage = totalPages end
    if animListPage < 1 then animListPage = 1 end

    local startIdx = (animListPage - 1) * ANIMS_PER_PAGE + 1
    local endIdx = math.min(animListPage * ANIMS_PER_PAGE, totalAnims)

    -- Search button
    StaffMenu.animManagerList.Button(
        animListQuery and (":search: RECHERCHE: " .. animListQuery) or ":search: RECHERCHER",
        animListQuery and "Appuyer pour effacer" or "Rechercher une animation",
        nil, "search", false,
        function()
            if animListQuery then
                animListQuery = nil
                animListPage = 1
                StaffMenu.animManagerList.refresh()
                return
            end
            local input = VFW.Nui.KeyboardInput(true, "Rechercher une animation...")
            if input == nil or input == "" then return end
            animListQuery = input
            animListPage = 1
            StaffMenu.animManagerList.refresh()
        end
    )

    -- Header
    StaffMenu.animManagerList.Separator(
        selectedCategory .. " : " .. totalAnims .. " animations",
        nil,
        "Page " .. animListPage .. "/" .. totalPages
    )

    -- Previous page button
    if animListPage > 1 then
        StaffMenu.animManagerList.Button(":arrow: PAGE PRÉCÉDENTE", "Page " .. (animListPage - 1) .. "/" .. totalPages, nil, "chevron", false, function()
            animListPage = animListPage - 1
            StaffMenu.animManagerList.refresh()
        end)
    end

    -- Animation buttons for current page
    for i = startIdx, endIdx do
        local anim = anims[i]
        local override = cachedOverrides[anim.name] or {}
        local effectiveLabel = override.label or anim.originalLabel

        -- Build description with flags
        local flags = {}
        if override.disabled then table.insert(flags, ":dot-red: OFF") end
        if override.label then table.insert(flags, ":edit:") end
        if override.previewDisabled then table.insert(flags, ":eye::chat: no preview") end
        if override.category then table.insert(flags, ":folder: → " .. override.category) end
        if anim.custom then table.insert(flags, ":star: personnalisée") end

        local desc = #flags > 0 and table.concat(flags, " ") or nil
        local icon = override.disabled and ":dot-red:" or ":dot-green:"

      StaffMenu.animManagerList.Button(icon .. " " .. effectiveLabel, desc, nil, "chevron", false, function()
            selectedAnimName = anim.name
            selectedAnimData = anim
        end, StaffMenu.animManagerEdit)
    end

    -- Next page button
    if animListPage < totalPages then
        StaffMenu.animManagerList.Button(":arrow: PAGE SUIVANTE", "Page " .. (animListPage + 1) .. "/" .. totalPages, nil, "chevron", false, function()
            animListPage = animListPage + 1
            StaffMenu.animManagerList.refresh()
        end)
    end
end

-- ═══════════════════════════════════════════════════════
-- Edit Menu: Modifier une animation
-- ═══════════════════════════════════════════════════════

function StaffMenu.BuildAnimManagerEditMenu()
    if not selectedAnimName or not selectedAnimData then return end

    local override = cachedOverrides[selectedAnimName] or {}
    local effectiveLabel = override.label or selectedAnimData.originalLabel
    local effectiveCategory = override.category or selectedAnimData.originalCategory

    StaffMenu.animManagerEdit.Separator(selectedAnimName)

    -- Toggle enabled/disabled
    local isEnabled = not override.disabled
    StaffMenu.animManagerEdit.Checkbox("ACTIVER L'ANIMATION", nil, false, isEnabled, function(_checked)
        if _checked then
            override.disabled = nil
        else
            override.disabled = true
        end
        if not next(override) then
            override = nil
        end
        cachedOverrides[selectedAnimName] = override
        TriggerServerEvent("vfw:animManager:setOverride", selectedAnimName, override)
        VFW.ShowNotification({
            type = 'STAFF', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Anim Manager',
            message = _checked and ("Animation " .. selectedAnimName .. " activée.") or ("Animation " .. selectedAnimName .. " désactivée.")
        })
        StaffMenu.animManagerEdit.refresh()
    end)

    -- Rename
    local renameDesc = override.label and ("Actuel: " .. override.label .. " (original: " .. selectedAnimData.originalLabel .. ")") or ("Actuel: " .. selectedAnimData.originalLabel)
    StaffMenu.animManagerEdit.Button("RENOMMER", renameDesc, nil, "edit", false, function()
        local newLabel = VFW.Nui.KeyboardInput(true, "Nouveau label (vide = reset)")
        if newLabel == nil then return end

        if newLabel == "" then
            override.label = nil
        else
            override.label = newLabel
        end

        if not next(override) then
            override = nil
        end
        cachedOverrides[selectedAnimName] = override
        TriggerServerEvent("vfw:animManager:setOverride", selectedAnimName, override)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Anim Manager',
            message = newLabel == "" and ("Label de " .. selectedAnimName .. " réinitialisé.") or ("Label de " .. selectedAnimName .. " changé en \"" .. newLabel .. "\".")
        })
        StaffMenu.animManagerEdit.refresh()
    end)

    -- Toggle preview
    local previewEnabled = not override.previewDisabled
    StaffMenu.animManagerEdit.Checkbox("PREVIEW ACTIVÉE", nil, false, previewEnabled, function(_checked)
        if _checked then
            override.previewDisabled = nil
        else
            override.previewDisabled = true
        end
        if not next(override) then
            override = nil
        end
        cachedOverrides[selectedAnimName] = override
        TriggerServerEvent("vfw:animManager:setOverride", selectedAnimName, override)
        VFW.ShowNotification({
            type = 'STAFF', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Anim Manager',
            message = _checked and ("Preview de " .. selectedAnimName .. " activée.") or ("Preview de " .. selectedAnimName .. " désactivée.")
        })
        StaffMenu.animManagerEdit.refresh()
    end)

    -- Change category
    StaffMenu.animManagerEdit.Button("CHANGER CATÉGORIE", "Catégorie: " .. effectiveCategory, nil, "chevron", false, function()
    end, StaffMenu.animManagerCategory)

    -- Reset all overrides
    StaffMenu.animManagerEdit.Separator()
    StaffMenu.animManagerEdit.Button(":refresh: RÉINITIALISER", "Supprimer toutes les modifications", nil, nil, false, function()
        cachedOverrides[selectedAnimName] = nil
        TriggerServerEvent("vfw:animManager:setOverride", selectedAnimName, nil)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Anim Manager',
            message = "Tous les overrides de " .. selectedAnimName .. " ont été réinitialisés."
      })
        StaffMenu.animManagerEdit.refresh()
    end)
end

-- ═══════════════════════════════════════════════════════
-- Category Menu: Choisir une nouvelle catégorie
-- ═══════════════════════════════════════════════════════

function StaffMenu.BuildAnimManagerCategoryMenu()
    if not selectedAnimName or not selectedAnimData then return end

    local override = cachedOverrides[selectedAnimName] or {}
    local effectiveCategory = override.category or selectedAnimData.originalCategory

    StaffMenu.animManagerCategory.Separator("Catégorie actuelle: " .. effectiveCategory)

    local categories = GetCategoryNames()
    for _, catName in ipairs(categories) do
        local isCurrent = (catName == effectiveCategory)
        local icon = isCurrent and ":check:" or nil
        StaffMenu.animManagerCategory.Button(catName, nil, icon, nil, false, function()
            if catName == selectedAnimData.originalCategory then
                override.category = nil
            else
                override.category = catName
            end

            if not next(override) then
                override = nil
            end
            cachedOverrides[selectedAnimName] = override
            TriggerServerEvent("vfw:animManager:setOverride", selectedAnimName, override)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Anim Manager',
                message = "Catégorie de " .. selectedAnimName .. " changée en \"" .. catName .. "\"."
          })
            StaffMenu.animManagerEdit.open()
        end)
    end
end
