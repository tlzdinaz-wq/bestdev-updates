-- ========================================================================
-- AFK SHOP CLIENT - VUI Menu Version
-- Handles VUI menu interface and NPC interaction for AFK shop
-- ========================================================================

local VUI = exports["VUI"]
local shopNPC = nil
local isShopOpen = false
local playerPoints = 0
local shopCasesCache = nil

local defaultBanner = VFW.CDN.Get("banners/f5.png")

-- Convert config prizes to NUI format
local function ConvertPrizesToNUI(prizes)
    local nuiPrizes = {}
    for i, prize in ipairs(prizes) do
        local image = VFW.CDN.Get("items/weapon_pistol.webp")
        if prize.type == "money" then
            image = VFW.CDN.Get("items/money.webp")
        elseif prize.type == "item" then
            image = VFW.CDN.Get("items/" .. (prize.itemName or "weapon_pistol") .. ".webp")
        elseif prize.type == "weapon" then
            image = VFW.CDN.Get("items/" .. (prize.itemName or "weapon_pistol") .. ".webp")
        elseif prize.type == "vehicle" then
            image = VFW.CDN.Get("items/key.webp")
        elseif prize.type == "case" then
            image = VFW.CDN.Get("items/weapon_briefcase.webp")
        end

        table.insert(nuiPrizes, {
            id = string.format("prize_%d", i),
            name = prize.name,
            type = prize.type,
            rarity = prize.rarity,
            chance = prize.chance,
            image = image,
            amount = prize.amount,
            itemName = prize.itemName,
            itemCount = prize.count,
            vehicleModel = prize.vehicleModel,
        })
    end
    return nuiPrizes
end

-- Build NUI prize data from server result
local function BuildNUIPrize(prize)
    local image = VFW.CDN.Get("items/weapon_pistol.webp")
    if prize.type == "money" then
        image = VFW.CDN.Get("items/money.webp")
    elseif prize.type == "item" then
        image = VFW.CDN.Get("items/" .. (prize.itemName or "weapon_pistol") .. ".webp")
    elseif prize.type == "weapon" then
        image = VFW.CDN.Get("items/" .. (prize.itemName or "weapon_pistol") .. ".webp")
    elseif prize.type == "vehicle" then
        image = VFW.CDN.Get("items/key.webp")
    elseif prize.type == "case" then
        image = VFW.CDN.Get("items/weapon_briefcase.webp")
    end

    return {
        id = "won_prize",
        name = prize.name,
        type = prize.type,
        rarity = prize.rarity,
        chance = prize.chance or 0,
        image = image,
        amount = prize.amount,
        itemName = prize.itemName,
        itemCount = prize.itemCount,
        vehicleModel = prize.vehicleModel,
    }
end

-- ========================================================================
-- NPC CONFIGURATION
-- ========================================================================

local ShopNPCConfig = {
    model = "a_f_y_business_01",
    position = vector3(478.0, 4808.0, -58.384),
    heading = 0.0,
    interactionRadius = 2.5,
}

-- ========================================================================
-- VUI MENUS
-- ========================================================================

local mainMenu = VUI:CreateMenu("Boutique AFK", VFW.CDN.Get("banners/shop_afk.png"), true)

-- ========================================================================
-- HELPER FUNCTIONS
-- ========================================================================

-- Draw 3D text function
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- ========================================================================
-- MENU BUILDERS
-- ========================================================================

-- Sorted cases cache for OnIndexChange lookup
local sortedCasesCache = {}

-- Load cases from server
local function LoadShopCases()
    local cases = TriggerServerCallback('core:afkshop:getShopCases')
    if cases and type(cases) == "table" then
        shopCasesCache = cases
    elseif not shopCasesCache then
        -- Fallback to config if server callback fails
        shopCasesCache = AFKConfig.Shop and AFKConfig.Shop.cases or {}
    end
end

-- Get sorted cases
local function GetSortedCases()
    local sortedCases = {}
    local cases = shopCasesCache or {}
    for id, caseData in pairs(cases) do
        table.insert(sortedCases, { id = id, data = caseData })
    end
    table.sort(sortedCases, function(a, b)
        return a.data.price < b.data.price
    end)
    return sortedCases
end

-- Build main shop menu
local function BuildMainMenu()
    local cases = shopCasesCache or {}
    local hasCases = false
    for _ in pairs(cases) do hasCases = true break end
    if not hasCases then
        mainMenu.Button("Aucune caisse disponible", nil, nil, nil, true, function() end)
        return
    end

    -- Header with points (Title for visibility)
    mainMenu.Title("Points AFK: " .. playerPoints)
    mainMenu.Separator("CAISSES DISPONIBLES")

    -- Sort cases by price and cache
    sortedCasesCache = GetSortedCases()

    -- Add case buttons (no panel, using CasePreview instead)
    for _, caseInfo in ipairs(sortedCasesCache) do
        local caseId = caseInfo.id
        local caseData = caseInfo.data
        local canAfford = playerPoints >= caseData.price
        local priceLabel = caseData.price .. " pts"
        local subtitle = canAfford
            and (caseData.description or "Cliquez pour acheter")
            or "Points insuffisants (" .. (caseData.price - playerPoints) .. " manquants)"

        mainMenu.Button(
            caseData.name,
            subtitle,
            priceLabel,
            canAfford and "chevron" or nil,
            false,  -- Never disabled, allows navigation on all cases
            function()
                if not canAfford then
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = "Points insuffisants! Il vous manque " .. (caseData.price - playerPoints) .. " points"
                    })
                    return
                end

                -- Buy + open in one call (server deducts points, selects prize, awards it)
                local result = TriggerServerCallback('core:afkshop:buyCase', caseId)

                if result and result.success then
                    playerPoints = result.newPoints or (playerPoints - caseData.price)

                    -- Close VUI menu and show scan animation
                    mainMenu.close()

                    local nuiPrize = BuildNUIPrize(result.prize)
                    local nuiPrizes = ConvertPrizesToNUI(caseData.prizes)
                    local nuiCase = {
                        id = caseId,
                        name = caseData.name,
                        description = caseData.description or "",
                        price = caseData.price,
                        image = caseData.image or "",
                        prizes = nuiPrizes,
                    }

                    SendNUIMessage({
                        action = 'afkshop:scanCase',
                        data = {
                            caseItem = nuiCase,
                            wonPrize = nuiPrize,
                            rarityColors = {
                                ['1'] = '#9ca3af',
                                ['2'] = '#6bdb6b',
                                ['3'] = '#4a90e2',
                                ['4'] = '#f4b245',
                            },
                        },
                    })

                    VFW.Nui.Focus(true, false)
                else
                    VFW.ShowNotification({
                        type = 'ROUGE',
                        content = result and result.error or "Erreur lors de l'achat"
                    })
                end
            end
        )
    end
end

-- ========================================================================
-- MENU CALLBACKS
-- ========================================================================

mainMenu.OnOpen(function()
    isShopOpen = true
    -- Refresh points and cases when opening
    playerPoints = TriggerServerCallback('core:afk:getPoints') or 0
    LoadShopCases()
    BuildMainMenu()

    -- Show preview for first case after a small delay (menu needs to render first)
    SetTimeout(100, function()
        if #sortedCasesCache > 0 then
            local firstCase = sortedCasesCache[1]
            mainMenu.CasePreview(
                firstCase.data.name,
                firstCase.data.description,
                firstCase.data.price,
                playerPoints,
                firstCase.data.prizes
            )
        end
    end)
end)

mainMenu.OnIndexChange(function(index)
    -- Index offset: Title (1) + Separator (1) = 2 items before cases
    local caseIndex = index - 2

    if caseIndex >= 1 and caseIndex <= #sortedCasesCache then
        local caseInfo = sortedCasesCache[caseIndex]
        mainMenu.CasePreview(
            caseInfo.data.name,
            caseInfo.data.description,
            caseInfo.data.price,
            playerPoints,
            caseInfo.data.prizes
        )
    else
        mainMenu.CloseCasePreview()
    end
end)

mainMenu.OnClose(function()
    isShopOpen = false
    mainMenu.CloseCasePreview()
end)

-- ========================================================================
-- NPC MANAGEMENT
-- ========================================================================

-- Spawn shop NPC
local function SpawnShopNPC()
    if not AFKConfig.Shop or not AFKConfig.Shop.enabled then
        return
    end

    if shopNPC and DoesEntityExist(shopNPC) then
        return
    end

    local cfg = ShopNPCConfig
    local model = GetHashKey(cfg.model)

    VFW.Streaming.RequestModel(model)

    shopNPC = CreatePed(4, model, cfg.position.x, cfg.position.y, cfg.position.z, cfg.heading, false, true)

    if DoesEntityExist(shopNPC) then
        Wait(100)

        -- Get ground Z
        local groundZ = cfg.position.z
        local found, z = GetGroundZFor_3dCoord(cfg.position.x, cfg.position.y, cfg.position.z + 2.0, false)
        if found then
            groundZ = z
        end

        SetEntityCoords(shopNPC, cfg.position.x, cfg.position.y, groundZ, false, false, false, false)
        SetEntityHeading(shopNPC, cfg.heading)

        FreezeEntityPosition(shopNPC, true)
        SetEntityInvincible(shopNPC, true)
        SetBlockingOfNonTemporaryEvents(shopNPC, true)
        SetPedCanRagdoll(shopNPC, false)
        TaskStartScenarioInPlace(shopNPC, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    end

    SetModelAsNoLongerNeeded(model)
end

-- Cleanup shop NPC
local function CleanupShopNPC()
    if shopNPC and DoesEntityExist(shopNPC) then
        DeleteEntity(shopNPC)
        shopNPC = nil
    end
end

-- ========================================================================
-- SHOP UI MANAGEMENT
-- ========================================================================

-- Open shop
local function OpenShop()
    if isShopOpen then return end
    if not AFKConfig.Shop or not AFKConfig.Shop.enabled then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "La boutique AFK n'est pas disponible"
        })
        return
    end

    mainMenu.open()
end

-- Close shop
local function CloseShop()
    if not isShopOpen then return end
    mainMenu.close()
end

-- ========================================================================
-- NPC INTERACTION LOOP
-- ========================================================================

-- Shop interaction thread (only runs when player is in AFK zone)
local function StartShopInteractionLoop()
    CreateThread(function()
        while exports['core']:IsInAFKZone() do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Check shop NPC interaction
            if shopNPC and DoesEntityExist(shopNPC) then
                local npcCoords = GetEntityCoords(shopNPC)
                local dist = #(coords - npcCoords)

                if dist < ShopNPCConfig.interactionRadius then
                    -- Show prompt
                    DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, "~y~[E]~w~ Boutique AFK")

                    if VFW.Interact.JustPressed(0, 38) and not isShopOpen then -- E key
                        OpenShop()
                    end
                end
            end

            Wait(0)
        end
    end)
end

-- ========================================================================
-- EVENTS
-- ========================================================================

-- When player enters AFK zone, spawn shop NPC
RegisterNetEvent('core:afk:entered', function(data)
    if AFKConfig.Shop and AFKConfig.Shop.enabled then
        -- Small delay to let other things spawn first
        SetTimeout(1000, function()
            SpawnShopNPC()
            StartShopInteractionLoop()
        end)
    end
end)

-- When player exits AFK zone, cleanup shop NPC
RegisterNetEvent('core:afk:exited', function(data)
    CloseShop()
    CleanupShopNPC()
end)

-- Points update event
RegisterNetEvent('core:afk:updatePoints', function(totalPoints, pointsEarned)
    playerPoints = totalPoints
    if isShopOpen then
        mainMenu.refresh()
    end
end)

-- ========================================================================
-- COMMANDS
-- ========================================================================

-- Open shop command
RegisterCommand('afkshop', function()
    if not exports['core']:IsInAFKZone() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en zone AFK pour accéder à la boutique"
        })
        return
    end

    if isShopOpen then
        CloseShop()
    else
        OpenShop()
    end
end, false)

-- ========================================================================
-- NUI CALLBACKS
-- ========================================================================

RegisterNUICallback('afkshop:close', function(data, cb)
    VFW.Nui.Focus(false)
    cb({})
end)

RegisterNUICallback('afkshop:showNotification', function(data, cb)
    VFW.ShowNotification({
        type = data.type or 'INFO',
        content = data.content or ''
    })
    cb({})
end)

RegisterNUICallback('afkshop:buyCase', function(data, cb)
    local caseId = data and data.caseId

    if not caseId then
        cb({ success = false, error = "Caisse introuvable" })
        return
    end

    local result = TriggerServerCallback('core:afkshop:buyCase', caseId)

    if not result or not result.success then
        cb({ success = false, error = result and result.error or "Erreur lors de l'achat" })
        return
    end

    cb({
        success = true,
        prize = BuildNUIPrize(result.prize),
        newPoints = result.newPoints,
    })
end)

-- ========================================================================
-- CLEANUP ON RESOURCE STOP
-- ========================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    CloseShop()
    CleanupShopNPC()
    VFW.Nui.Focus(false)
    SendNUIMessage({ action = 'afkshop:hide' })
end)
