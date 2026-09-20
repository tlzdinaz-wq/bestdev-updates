---@meta _
---@diagnostic disable: duplicate-doc-field

-- Bag Categorizer Dev Tool
-- Allows developers to categorize bags into custom lists for configuration

local BagCategorizer = {}
BagCategorizer.active = false
BagCategorizer.buttonId = nil

-- State
local currentDrawable = 0
local currentTexture = 0
local maxDrawables = 0
local maxTextures = 0
local currentSex = "male"

-- Categories/Lists
local categories = {}  -- { [name] = { drawables = {0, 3, 7}, label = "Sac à dos" } }
local activeCategory = nil
local categoryNames = {}  -- Array of category names for TAB navigation
local categoryIndex = 1

-- Original clothing to restore
local originalSkin = nil

-- Component ID for bags
local BAG_COMPONENT = 5

-- Helper: Draw text on screen
local function DrawText2D(text, x, y, scale, centered)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextOutline()
    if centered then
        SetTextCentre(1)
    end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Helper: Draw background rect
local function DrawBackground(x, y, w, h, r, g, b, a)
    DrawRect(x, y, w, h, r, g, b, a)
end

-- Get number of drawables for bags
local function GetMaxDrawables()
    local playerPed = PlayerPedId()
    return GetNumberOfPedDrawableVariations(playerPed, BAG_COMPONENT)
end

-- Get number of textures for current drawable
local function GetMaxTextures()
    local playerPed = PlayerPedId()
    return GetNumberOfPedTextureVariations(playerPed, BAG_COMPONENT, currentDrawable)
end

-- Apply bag to ped
local function ApplyBag(drawable, texture)
    local playerPed = PlayerPedId()
    SetPedComponentVariation(playerPed, BAG_COMPONENT, drawable, texture, 0)
end

-- Get current sex
local function GetCurrentSex()
    local playerPed = PlayerPedId()
    local model = GetEntityModel(playerPed)
    if model == GetHashKey("mp_m_freemode_01") then
        return "male"
  else
        return "female"
  end
end

-- Save original clothing
local function SaveOriginalSkin()
    local playerPed = PlayerPedId()
    originalSkin = {
        drawable = GetPedDrawableVariation(playerPed, BAG_COMPONENT),
        texture = GetPedTextureVariation(playerPed, BAG_COMPONENT)
    }
end

-- Restore original clothing
local function RestoreOriginalSkin()
    if originalSkin then
        ApplyBag(originalSkin.drawable, originalSkin.texture)
    end
end

-- Check if drawable is in a category
local function GetCategoryForDrawable(drawable)
    for name, data in pairs(categories) do
        for _, d in ipairs(data.drawables) do
            if d == drawable then
                return name
            end
        end
    end
    return nil
end

-- Add drawable to active category
local function AddToCategory()
    if not activeCategory then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Catégorie Items',
            message = "Aucune liste active. Appuyez sur N pour en créer une."
      })
        return
    end

    -- Remove from any existing category first
    for name, data in pairs(categories) do
        for i, d in ipairs(data.drawables) do
            if d == currentDrawable then
                table.remove(data.drawables, i)
                break
            end
        end
    end

    -- Add to active category
    table.insert(categories[activeCategory].drawables, currentDrawable)

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Catégorie Items',
        message = string.format("Drawable #%d ajouté à '%s'.", currentDrawable, activeCategory)
    })
end

-- Remove drawable from current category
local function RemoveFromCategory()
    local cat = GetCategoryForDrawable(currentDrawable)
    if not cat then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Catégorie Items',
            message = "Ce drawable n'est dans aucune liste."
      })
        return
    end

    for i, d in ipairs(categories[cat].drawables) do
        if d == currentDrawable then
            table.remove(categories[cat].drawables, i)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Catégorie Items',
                message = string.format("Drawable #%d retiré de '%s'.", currentDrawable, cat)
            })
            return
        end
    end
end

-- Switch to next category
local function NextCategory()
    if #categoryNames == 0 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Catégorie Items',
            message = "Aucune liste. Appuyez sur N pour en créer une."
      })
        return
    end

    categoryIndex = categoryIndex + 1
    if categoryIndex > #categoryNames then
        categoryIndex = 1
    end
    activeCategory = categoryNames[categoryIndex]

    VFW.ShowNotification({
        type = 'STAFF', variant = 'INFO', subtitle = 'Catégorie Items',
        message = string.format("Liste active: %s.", activeCategory)
    })
end

-- Create new category
local function CreateNewCategory()
    -- Use native keyboard input
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 50)

    CreateThread(function()
        while UpdateOnscreenKeyboard() == 0 do
            Wait(0)
        end

        if GetOnscreenKeyboardResult() then
            local name = GetOnscreenKeyboardResult()
            if name and name ~= "" then
                if categories[name] then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Catégorie Items',
                        message = "Cette liste existe déjà."
                  })
                    return
                end

                categories[name] = {
                    drawables = {},
                    label = name
                }
                table.insert(categoryNames, name)
                activeCategory = name
                categoryIndex = #categoryNames

                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Catégorie Items',
                    message = string.format("Liste '%s' créée et activée.", name)
                })
            end
        end
    end)
end

-- Navigate drawables
local function NextDrawable()
    currentDrawable = currentDrawable + 1
    if currentDrawable >= maxDrawables then
        currentDrawable = 0
    end
    currentTexture = 0
    maxTextures = GetMaxTextures()
    ApplyBag(currentDrawable, currentTexture)
end

local function PrevDrawable()
    currentDrawable = currentDrawable - 1
    if currentDrawable < 0 then
        currentDrawable = maxDrawables - 1
    end
    currentTexture = 0
    maxTextures = GetMaxTextures()
    ApplyBag(currentDrawable, currentTexture)
end

-- Navigate textures
local function NextTexture()
    if maxTextures <= 1 then return end
    currentTexture = currentTexture + 1
    if currentTexture >= maxTextures then
        currentTexture = 0
    end
    ApplyBag(currentDrawable, currentTexture)
end

local function PrevTexture()
    if maxTextures <= 1 then return end
    currentTexture = currentTexture - 1
    if currentTexture < 0 then
        currentTexture = maxTextures - 1
    end
    ApplyBag(currentDrawable, currentTexture)
end

-- Draw HUD
local function DrawHUD()
    -- Top info panel
    DrawBackground(0.5, 0.08, 0.35, 0.1, 0, 0, 0, 180)

    local sexLabel = currentSex == "male" and "Homme" or "Femme"
  DrawText2D(string.format("~y~Drawable #%d, texture #%d~s~, ~c~%s", currentDrawable, currentTexture, sexLabel), 0.5, 0.04, 0.5, true)

    -- Category info
    local catInfo = "~r~Aucune liste active"
  if activeCategory then
        local count = #categories[activeCategory].drawables
        catInfo = string.format("~g~Liste %s, %d sacs~s~", activeCategory, count)
    end
    DrawText2D(catInfo, 0.5, 0.08, 0.4, true)

    -- Current drawable category
    local currentCat = GetCategoryForDrawable(currentDrawable)
    if currentCat then
        DrawText2D(string.format("~b~Dans: %s", currentCat), 0.5, 0.11, 0.35, true)
    end

    -- Controls panel (bottom right)
    DrawBackground(0.88, 0.75, 0.22, 0.35, 0, 0, 0, 180)

    local controlsY = 0.60
    local lineHeight = 0.025

    DrawText2D("~y~CONTROLES~s~", 0.88, controlsY, 0.4, true)
    controlsY = controlsY + lineHeight * 1.5

    DrawText2D("~b~<- / ->~s~ Drawable", 0.88, controlsY, 0.3, true)
    controlsY = controlsY + lineHeight

    DrawText2D("~b~UP / DOWN~s~ Texture", 0.88, controlsY, 0.3, true)
    controlsY = controlsY + lineHeight

    DrawText2D("~g~ENTER~s~ Ajouter liste", 0.88, controlsY, 0.3, true)
    controlsY = controlsY + lineHeight

    DrawText2D("~o~N~s~ Nouvelle liste", 0.88, controlsY, 0.3, true)
    controlsY = controlsY + lineHeight

    DrawText2D("~p~TAB~s~ Changer liste", 0.88, controlsY, 0.3, true)
    controlsY = controlsY + lineHeight

    DrawText2D("~r~BACKSPACE~s~ Retirer", 0.88, controlsY, 0.3, true)
    controlsY = controlsY + lineHeight

    DrawText2D("~r~ESC~s~ Quitter", 0.88, controlsY, 0.3, true)

    -- Categories summary (bottom left)
    if #categoryNames > 0 then
        local summaryHeight = 0.05 + (#categoryNames * 0.025)
        DrawBackground(0.12, 0.75, 0.22, summaryHeight, 0, 0, 0, 180)

        local summaryY = 0.75 - (summaryHeight / 2) + 0.02
        DrawText2D("~y~LISTES~s~", 0.12, summaryY, 0.35, true)
        summaryY = summaryY + 0.03

        for i, name in ipairs(categoryNames) do
            local count = #categories[name].drawables
            local prefix = (name == activeCategory) and "~g~> " or " "
          DrawText2D(string.format("%s%s (%d)", prefix, name, count), 0.12, summaryY, 0.28, true)
            summaryY = summaryY + 0.025
        end
    end
end

-- Control loop
local function ControlLoop()
    -- Arrow keys for navigation
    DisableControlAction(0, 172, true) -- UP
    DisableControlAction(0, 173, true) -- DOWN
    DisableControlAction(0, 174, true) -- LEFT
    DisableControlAction(0, 175, true) -- RIGHT
    DisableControlAction(0, 191, true) -- ENTER
    DisableControlAction(0, 194, true) -- BACKSPACE
    DisableControlAction(0, 37, true)  -- TAB
    DisableControlAction(0, 249, true) -- N

    -- LEFT - Previous drawable
    if IsDisabledControlJustPressed(0, 174) then
        PrevDrawable()
    end

    -- RIGHT - Next drawable
    if IsDisabledControlJustPressed(0, 175) then
        NextDrawable()
    end

    -- UP - Previous texture
    if IsDisabledControlJustPressed(0, 172) then
        PrevTexture()
    end

    -- DOWN - Next texture
    if IsDisabledControlJustPressed(0, 173) then
        NextTexture()
    end

    -- ENTER - Add to category
    if IsDisabledControlJustPressed(0, 191) then
        AddToCategory()
    end

    -- BACKSPACE - Remove from category
    if IsDisabledControlJustPressed(0, 194) then
        RemoveFromCategory()
    end

    -- TAB - Switch category
    if IsDisabledControlJustPressed(0, 37) then
        NextCategory()
    end

    -- N - New category
    if IsDisabledControlJustPressed(0, 249) then
        CreateNewCategory()
    end

    -- ESC - Quit
    if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 322) then
        BagCategorizer.Stop(false)
    end
end

-- Start categorizer
function BagCategorizer.Start()
    if BagCategorizer.active then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Catégorie Items',
            message = "Le catégoriseur est déjà actif."
      })
        return
    end

    -- Check staff permission
    if not StaffMenu or not StaffMenu.adminChecked then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Catégorie Items',
            message = "Vous devez être en service staff pour utiliser cet outil."
      })
        return
    end

    BagCategorizer.active = true

    -- Save original skin
    SaveOriginalSkin()

    -- Get current sex
    currentSex = GetCurrentSex()

    -- Initialize
    maxDrawables = GetMaxDrawables()
    currentDrawable = 0
    currentTexture = 0
    maxTextures = GetMaxTextures()

    -- Load existing categories from server
    local existingCategories = TriggerServerCallback("vfw:bagCategorizer:getCategories", currentSex)
    if existingCategories then
        categories = existingCategories.categories or {}
        categoryNames = existingCategories.names or {}
        if #categoryNames > 0 then
            activeCategory = categoryNames[1]
            categoryIndex = 1
        end
    end

    -- Apply first bag
    ApplyBag(currentDrawable, currentTexture)

    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Catégorie Items',
        message = string.format("Catégoriseur activé - %d drawables trouvés.", maxDrawables)
    })

    -- Main loop
    CreateThread(function()
        while BagCategorizer.active do
            DrawHUD()
            ControlLoop()
            Wait(0)
        end
    end)
end

-- Stop categorizer
function BagCategorizer.Stop(save)
    if not BagCategorizer.active then return end

    BagCategorizer.active = false

    -- Restore original skin
    RestoreOriginalSkin()

    VFW.ShowNotification({
        type = 'STAFF', variant = 'INFO', subtitle = 'Catégorie Items',
        message = save and "Catégories sauvegardées." or "Catégoriseur fermé sans sauvegarder."
  })
end

-- Save to database
function BagCategorizer.Save()
    if not BagCategorizer.active then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Catégorie Items',
            message = "Le catégoriseur n'est pas actif."
      })
        return
    end

    -- Check if we have categories
    local totalBags = 0
    for _, data in pairs(categories) do
        totalBags = totalBags + #data.drawables
    end

    if totalBags == 0 then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'INFO', subtitle = 'Catégorie Items',
            message = "Aucun sac à sauvegarder."
      })
        return
    end

    -- Send to server
    local success = TriggerServerCallback("vfw:bagCategorizer:save", currentSex, categories)

    if success then
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Catégorie Items',
            message = string.format("%d sacs sauvegardés en base de données.", totalBags)
        })
        BagCategorizer.Stop(true)
    else
        VFW.ShowNotification({
            type = 'STAFF', variant = 'ERROR', subtitle = 'Catégorie Items',
            message = "Erreur lors de la sauvegarde."
      })
    end
end

-- Export for menu integration
_G.BagCategorizer = BagCategorizer
