-- Paid Shop Client-Side Implementation

---@class PaidShopClient
local PaidShopClient = {}

-- Variables
local display = false
local previewVehicle = nil
local isInPreview = false
local previewCam = nil
local originalCoords = nil
local originalAlpha = nil
local currentVehicleData = nil
local isAdmin = false
local currentCoins = 0
local testDriveEndTime = 0
local testDriveInteriorId = nil
local testDriveButtonsId = nil
-- Snapshot des items reçus du serveur (à jour avec la BDD) : sert au lookup
-- côté preview puisque PaidShopConfig.Items côté client reste sur la version
-- statique de config/paidshop.lua (LoadItemsFromDB est server-side).
local cachedShopItems = nil

-- Test drive location (aéroport LSIA piste)
local TEST_DRIVE_COORDS = vector4(-1639.0, -3091.0, 13.94, 330.0)
local TEST_DRIVE_DURATION = 60 -- secondes

-- ====================================================================
-- Analytics buffer (relays events from NUI to server in batches)
-- See docs/plans/2026-05-21-dashboard-paidshop-analytics-design.md
-- ====================================================================
local analyticsBuffer = {}
local ANALYTICS_FLUSH_MAX = 50
local ANALYTICS_FLUSH_INTERVAL_MS = 60000  -- 60s

local function flushAnalytics()
    if #analyticsBuffer == 0 then return end
    local batch = analyticsBuffer
    analyticsBuffer = {}
    TriggerServerEvent('paidshop:analytics:flush', batch)
end

-- NUI callback: receive a single event from the React side
RegisterNUICallback('paidshop:analyticsEvent', function(data, cb)
    if type(data) ~= "table" or type(data.event_type) ~= "string" then
        cb({ ok = false })
        return
    end
    analyticsBuffer[#analyticsBuffer + 1] = {
        event_type  = data.event_type,
        category    = data.category,
        item_name   = data.item_name,
        price       = data.price,
        fail_reason = data.fail_reason,
    }
    if #analyticsBuffer >= ANALYTICS_FLUSH_MAX then
        flushAnalytics()
    end
    cb({ ok = true })
end)

-- Periodic flush
CreateThread(function()
    while true do
        Wait(ANALYTICS_FLUSH_INTERVAL_MS)
        flushAnalytics()
    end
end)

-- Open UI
function PaidShopClient.OpenUI()
    if display then return end

    if not isInPreview then
        display = true
        VFW.Nui.Focus(true, false)
        VFW.Nui.HudVisible(false)

        SendNUIMessage({
            action = "paidshop:show"
        })

        -- Get admin status
        isAdmin = TriggerServerCallback('paidshop:isPlayerBoutiqueAdmin')

        -- Get player info
        local info = TriggerServerCallback('paidshop:getPlayerInfo')

        if info then
            currentCoins = info.spacecoins

            SendNUIMessage({
                action = "paidshop:updateUserInfo",
                data = {
                    identifier = info.identifier,
                    name = info.name,
                    mugshot = VFW.PlayerData.mugshot,
                    vip_tier = info.vip_tier or 0
                }
            })

            SendNUIMessage({
                action = "paidshop:updateCoins",
                data = {
                    spacecoins = info.spacecoins
                }
            })
        end

        -- Get shop data
        local shopData = TriggerServerCallback('paidshop:getShopData')
        if not shopData then
            SendNUIMessage({ action = "paidshop:uiNotification", data = { type = "ERROR", message = "Impossible de charger la boutique", duration = 5 } })
            PaidShopClient.CloseUI()
            return
        end
        cachedShopItems = shopData.items
        SendNUIMessage({
            action = "paidshop:initializeData",
            data = {
                categories = shopData.categories,
                items = shopData.items,
                rarityColors = shopData.rarityColors,
                isAdmin = isAdmin
            }
        })

        -- Get purchase history
        local history = TriggerServerCallback('paidshop:getPurchaseHistory')
        SendNUIMessage({
            action = "paidshop:updatePurchaseHistory",
            data = {
                history = history
            }
        })

        -- Get pending items count
        local items = TriggerServerCallback('paidshop:getPendingItems') or {}
        SendNUIMessage({
            action = "paidshop:updatePendingItemCount",
            data = {
                count = #items
            }
        })

        -- Auto-select daily_reward category : désactivé (catégorie retirée de la
        -- sidebar, le bonus quotidien vit dans l'ActivityRail).
    end
end

-- Close UI
function PaidShopClient.CloseUI()
    if not isInPreview then
        display = false
        VFW.Nui.Focus(false, false)
        VFW.Nui.HudVisible(true)
        -- Flush analytics buffer before closing the shop UI (best-effort)
        flushAnalytics()
        SendNUIMessage({
            action = "paidshop:hide"
        })
    end
end

-- Start vehicle preview (now works with any category that has preview)
function PaidShopClient.StartPreview(itemName, category)
    category = category or 'vehicules' -- Default for backwards compatibility

    -- Get category configuration
    local categoryConfig = PaidShopConfig.GetCategoryConfig(category)
    if not categoryConfig then
        return
    end

    -- Check if category requires preview
    if not categoryConfig.requiresPreview then
        return
    end

    -- Find the item in the category. Source de vérité : le snapshot reçu du
    -- serveur (à jour avec la BDD). Fallback sur la config statique pour les
    -- catégories non remontées par LoadItemsFromDB.
    currentVehicleData = nil
    local function lookup(items)
        if not items then return nil end
        for _, item in ipairs(items) do
            if item.spawnName == itemName then
                return item
            end
        end
        return nil
    end

    local found = lookup(cachedShopItems and cachedShopItems[category])
        or lookup(PaidShopConfig.Items[category])

    if not found then
        return
    end

    currentVehicleData = found
    currentVehicleData.category = category -- Store category for later use

    isInPreview = true
    testDriveEndTime = 0 -- Empêcher le thread de checker pendant le setup
    display = false
    VFW.Nui.Focus(false, false)
    SendNUIMessage({
        action = "paidshop:hide"
    })

    local ped = PlayerPedId()
    originalCoords = GetEntityCoords(ped)

    -- Charger le modèle
    local modelHash = GetHashKey(itemName)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(1)
        timeout = timeout + 1
    end
    if timeout >= 5000 then
        PaidShopClient.StopPreview()
        return
    end

    -- Générer une instance pour isoler le joueur
    testDriveInteriorId = GetInteriorAtCoords(TEST_DRIVE_COORDS.x, TEST_DRIVE_COORDS.y, TEST_DRIVE_COORDS.z)

    -- Téléporter le joueur
    DoScreenFadeOut(500)
    Wait(500)

    SetEntityCoords(ped, TEST_DRIVE_COORDS.x, TEST_DRIVE_COORDS.y, TEST_DRIVE_COORDS.z, false, false, false, false)
    SetEntityHeading(ped, TEST_DRIVE_COORDS.w)

    -- Attendre le chargement de la zone
    RequestCollisionAtCoord(TEST_DRIVE_COORDS.x, TEST_DRIVE_COORDS.y, TEST_DRIVE_COORDS.z)
    while not HasCollisionLoadedAroundEntity(ped) do Wait(10) end

    -- Créer le véhicule et mettre le joueur dedans
    previewVehicle = CreateVehicle(modelHash, TEST_DRIVE_COORDS.x, TEST_DRIVE_COORDS.y, TEST_DRIVE_COORDS.z, TEST_DRIVE_COORDS.w, false, false)
    SetEntityInvincible(previewVehicle, true)
    SetVehicleDirtLevel(previewVehicle, 0.0)
    SetVehicleEngineOn(previewVehicle, true, true, false)
    SetVehicleNumberPlateText(previewVehicle, "ESSAI")
    SetModelAsNoLongerNeeded(modelHash)

    TaskWarpPedIntoVehicle(ped, previewVehicle, -1)
    Wait(500) -- Attendre que le warp soit effectif

    -- Isoler le joueur (instance)
    NetworkSetInSpectatorMode(true, ped)
    NetworkSetInSpectatorMode(false, ped)
    SetEntityVisible(ped, true, false)

    -- Timer (démarré après le warp)
    testDriveEndTime = GetGameTimer() + (TEST_DRIVE_DURATION * 1000)

    -- Instructional buttons
    testDriveButtonsId = VFW.AddInstructionalButtons({
        { label = "Revenir à la boutique", control = 73 },
    })

    -- Réafficher le HUD gameplay pendant le test drive : le speedometer est
    -- gated par `nui:hud:visible` côté React, donc sans ça il reste caché.
    VFW.Nui.HudVisible(true)

    DoScreenFadeIn(500)
end

-- Buy preview vehicle
function PaidShopClient.BuyPreviewVehicle()
    if not currentVehicleData then return end

    -- Enable NUI focus so the modal can receive input
    VFW.Nui.Focus(true, true)

    -- Timeout thread to release focus if no callback fires
    CreateThread(function()
        local waited = 0
        while waited < 30000 do
            Wait(1000)
            waited = waited + 1000
            if not isInPreview then return end
        end
        -- If still in preview after 30s, release focus
        if isInPreview then
            VFW.Nui.Focus(false, false)
        end
    end)

    -- Show the purchase confirmation modal
    SendNUIMessage({
        action = 'paidshop:showPurchaseConfirm',
        vehicleName = currentVehicleData.name,
        vehicleModel = currentVehicleData.spawnName,
        vehiclePrice = currentVehicleData.price
    })
end

-- Handle the modal response
RegisterNUICallback('paidshop:confirmPurchase', function(data, cb)
    if not currentVehicleData then
        cb('ok')
        return
    end

    -- Disable NUI focus after modal interaction
    VFW.Nui.Focus(false, false)

    if data.confirmed then
        local category = currentVehicleData.category or 'vehicules' -- Use stored category
        local categoryConfig = PaidShopConfig.GetCategoryConfig(category)

        -- Use the new generic purchase handler
        local success, message, newBalance = TriggerServerCallback('paidshop:purchaseItem', currentVehicleData.spawnName, 1, category)

        if success then
            SendNUIMessage({ action = "paidshop:uiNotification", data = { type = "SUCCESS", message = "Vous avez acheté " .. currentVehicleData.name, duration = 5 } })
            if newBalance then
                currentCoins = newBalance
            end
            PaidShopClient.StopPreview()
        else
            SendNUIMessage({ action = "paidshop:uiNotification", data = { type = "ERROR", message = message or "Erreur lors de l'achat", duration = 5 } })
        end
    else
        SendNUIMessage({ action = "paidshop:uiNotification", data = { type = "WARNING", message = "Achat annulé", duration = 3 } })
    end

    cb('ok')
end)

-- Stop preview (test drive)
function PaidShopClient.StopPreview()
    if not isInPreview then return end
    isInPreview = false

    DoScreenFadeOut(500)
    Wait(500)

    local ped = PlayerPedId()

    -- Sortir le joueur du véhicule si nécessaire
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveAnyVehicle(ped, 0, 0)
        Wait(100)
    end

    -- Supprimer le véhicule
    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end

    -- Téléporter le joueur à sa position d'origine
    if originalCoords then
        SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
    end

    testDriveEndTime = 0
    testDriveInteriorId = nil
    currentVehicleData = nil

    if testDriveButtonsId then
        VFW.RemoveInstructionalButtons(testDriveButtonsId)
        testDriveButtonsId = nil
    end

    DoScreenFadeIn(500)
    PaidShopClient.OpenUI()
end

-- Test drive thread
CreateThread(function()
    while true do
        Wait(0)
        if isInPreview then
            local ped = PlayerPedId()
            local remaining = math.max(0, math.ceil((testDriveEndTime - GetGameTimer()) / 1000))

            -- Timer pas encore initialisé (warp en cours) → attendre
            if testDriveEndTime == 0 then
                goto continue
            end

            -- Timer expiré → fin du test drive
            if remaining <= 0 then
                PaidShopClient.StopPreview()
                goto continue
            end

            -- Le joueur est sorti du véhicule → fin du test drive
            if not IsPedInAnyVehicle(ped, false) then
                PaidShopClient.StopPreview()
                goto continue
            end

            -- Appui sur X → fin du test drive
            if IsControlJustPressed(0, 73) then
                PaidShopClient.StopPreview()
                goto continue
            end

            -- F (sortir du véhicule) → fin du test drive
            if IsControlJustPressed(0, 75) or IsDisabledControlJustPressed(0, 75) then
                PaidShopClient.StopPreview()
                goto continue
            end
            DisableControlAction(0, 75, true) -- Empêcher la sortie native

            -- Véhicule invincible
            if previewVehicle and DoesEntityExist(previewVehicle) then
                SetEntityInvincible(previewVehicle, true)
                SetVehicleFixed(previewVehicle)
            end

            -- Afficher le timer
            local timerColor = remaining <= 10 and "~r~" or "~g~"
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("ESSAI VÉHICULE " .. timerColor .. remaining .. "s")
            DrawText(0.5, 0.88)

            ::continue::
        else
            Wait(500)
        end
    end
end)

 --Command to open shop
RegisterCommand('paidshop', function()
    if not isInPreview then
        PaidShopClient.OpenUI()
    end
end, false)

 --/boutique command disabled
 RegisterCommand('boutique', function()
     if not isInPreview then
         PaidShopClient.OpenUI()
     end
 end, false)

 --F1 keybind disabled — use /boutique instead
 VFW.RegisterInput("OpenPaidShop", "Boutique", "keyboard", "F1", function()
     if isInPreview then return end
     if VFW.IsPlayerInTIG() then return end
     if display then
         PaidShopClient.CloseUI()
     else
         PaidShopClient.OpenUI()
     end
 end)

-- NUI Callbacks

-- Close UI
RegisterNUICallback('paidshop:close', function(data, cb)
    PaidShopClient.CloseUI()
    cb('ok')
end)

-- Preview vehicle
RegisterNUICallback('paidshop:previewVehicle', function(data, cb)
    PaidShopClient.StartPreview(data.vehicle, data.category)
    cb('ok')
end)

-- Buy item
RegisterNUICallback('paidshop:buyItem', function(data, cb)
    if not data.itemName then
        cb({ success = false, message = "Nom de l'item manquant" })
        return
    end

    if not data.category then
        cb({ success = false, message = "Catégorie manquante" })
        return
    end

    local quantity = tonumber(data.quantity) or 1

    local success, message, newBalance = TriggerServerCallback('paidshop:buyItem', data.itemName, quantity, data.category, data.isOpeningCase)

    if success and newBalance then
        currentCoins = newBalance
        SendNUIMessage({
            action = "paidshop:updateCoins",
            data = {
                spacecoins = newBalance
            }
        })
    end

    cb({
        success = success,
        message = message
    })
end)

-- Gift item to another player
RegisterNUICallback('paidshop:giftItem', function(data, cb)
    if not data.itemName then
        cb({ success = false, message = "Nom de l'item manquant" })
        return
    end

    if not data.category then
        cb({ success = false, message = "Categorie manquante" })
        return
    end

    local targetUniqueId = tonumber(data.targetUniqueId)
    if not targetUniqueId or targetUniqueId < 1 then
        cb({ success = false, message = "Cet ID boutique du joueur n'est pas valide" })
        return
    end

    local quantity = tonumber(data.quantity) or 1

    local success, message, newBalance = TriggerServerCallback('paidshop:giftItem', data.itemName, quantity, data.category, targetUniqueId)

    if success and newBalance then
        currentCoins = newBalance
        SendNUIMessage({
            action = "paidshop:updateCoins",
            data = {
                spacecoins = newBalance
            }
        })
    end

    cb({
        success = success,
        message = message
    })
end)

-- Get box winning item
RegisterNUICallback('paidshop:getBoxWinningItem', function(data, cb)
    local result = TriggerServerCallback('paidshop:getBoxWinningItem', data.caseId)
    cb(result or {error=true, message="Action impossible pour le moment"})
end)

-- Case prize won
RegisterNUICallback('paidshop:casePrizeWon', function(data, cb)
    local success, message = TriggerServerCallback('paidshop:casePrizeWon', data.caseId, data.prizeItem)

    if not success then
        SendNUIMessage({ action = "paidshop:uiNotification", data = { type = "ERROR", message = message or "Erreur lors de la réception du prix", duration = 5 } })
    end

    cb('ok')
end)

-- Get pending items
RegisterNUICallback('paidshop:getPendingItems', function(data, cb)
    local items = TriggerServerCallback('paidshop:getPendingItems')
    cb(items)
end)

-- Claim item
RegisterNUICallback('paidshop:claimItem', function(data, cb)
    if not data.itemId then
        cb({ success = false, message = "ID de l'item manquant" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:claimItem', data.itemId)

    if success then
        -- Refresh pending items list
        local items = TriggerServerCallback('paidshop:getPendingItems')
        SendNUIMessage({
            action = "paidshop:updatePendingItemCount",
            data = {
                count = #items
            }
        })
    end

    cb({ success = success, message = message })
end)

-- Refund item
RegisterNUICallback('paidshop:refundItem', function(data, cb)
    if not data.itemId then
        cb({ success = false, message = "ID de l'item manquant" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:refundItem', data.itemId)

    if success then
        -- Refresh pending items list
        local items = TriggerServerCallback('paidshop:getPendingItems')
        SendNUIMessage({
            action = "paidshop:updatePendingItemCount",
            data = {
                count = #items
            }
        })
    end

    cb({ success = success, message = message })
end)

-- Admin: Add Coins
RegisterNUICallback('paidshop:adminAddCoins', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)

    if not targetId or not amount then
        cb({ success = false, message = "Cet identifiant ou ce montant n'est pas valide" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:addCoinsAdmin', targetId, amount)
    cb({ success = success, message = message })
end)

-- Admin: Remove Coins
RegisterNUICallback('paidshop:adminRemoveCoins', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)

    if not targetId or not amount then
        cb({ success = false, message = "Cet identifiant ou ce montant n'est pas valide" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:removeCoinsAdmin', targetId, amount)
    cb({ success = success, message = message })
end)

-- Open Tebex link in external browser
RegisterNUICallback('paidshop:openTebexLink', function(data, cb)
    if data.url then
        Web.OpenUrl(data.url)
    end
    cb('ok')
end)

-- Admin: Edit Item
RegisterNUICallback('paidshop:editItem', function(data, cb)
    if not isAdmin then
        cb({ success = false, message = "Non autorisé" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:editItemServer', data.item, data.category)

    if success then
        -- Refresh shop data after successful edit
        local shopData = TriggerServerCallback('paidshop:getShopData')
        if shopData then
            SendNUIMessage({
                action = "paidshop:initializeData",
                data = {
                    categories = shopData.categories,
                    items = shopData.items,
                    rarityColors = shopData.rarityColors,
                    isAdmin = isAdmin
                }
            })
        end
    end

    cb({ success = success, message = message })
end)

-- Admin: Delete Item
RegisterNUICallback('paidshop:deleteItem', function(data, cb)
    if not isAdmin then
        cb({ success = false, message = "Non autorisé" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:deleteItemServer', data.spawnName, data.category)

    if success then
        -- Refresh shop data after successful delete
        local shopData = TriggerServerCallback('paidshop:getShopData')
        if shopData then
            SendNUIMessage({
                action = "paidshop:initializeData",
                data = {
                    categories = shopData.categories,
                    items = shopData.items,
                    rarityColors = shopData.rarityColors,
                    isAdmin = isAdmin
                }
            })
        end
    end

    cb({ success = success, message = message })
end)

-- Admin: Add Item
RegisterNUICallback('paidshop:addItem', function(data, cb)
    if not isAdmin then
        cb({ success = false, message = "Non autorisé" })
        return
    end

    local success, message = TriggerServerCallback('paidshop:addItemServer', data.item, data.category)

    if success then
        -- Refresh shop data after successful add
        local shopData = TriggerServerCallback('paidshop:getShopData')
        if shopData then
            SendNUIMessage({
                action = "paidshop:initializeData",
                data = {
                    categories = shopData.categories,
                    items = shopData.items,
                    rarityColors = shopData.rarityColors,
                    isAdmin = isAdmin
                }
            })
        end
    end

    cb({ success = success, message = message })
end)

-- Refresh Items
RegisterNUICallback('paidshop:refreshItems', function(data, cb)
    local shopData = TriggerServerCallback('paidshop:getShopData')
    if not shopData then
        cb({success=false})
        return
    end
    SendNUIMessage({
        action = "paidshop:initializeData",
        data = {
            categories = shopData.categories,
            items = shopData.items,
            rarityColors = shopData.rarityColors,
            isAdmin = isAdmin
        }
    })
    cb('ok')
end)

-- Get daily claim status
RegisterNUICallback('paidshop:getDailyClaimStatus', function(data, cb)
    local status = TriggerServerCallback('paidshop:getDailyClaimStatus')
    cb(status)
end)

-- Réclamer le bonus quotidien (ActivityRail simple claim)
RegisterNUICallback('paidshop:claimDailyReward', function(data, cb)
    local result = TriggerServerCallback('paidshop:claimDailyReward')
    cb(result or { success = false, message = "Erreur de communication serveur." })
end)

RegisterNUICallback('paidshop:getDailyRewardWheel', function(data, cb)
    local result = TriggerServerCallback('paidshop:getDailyRewardWheel')
    cb(result or { classic = {}, vip = {}, classicClaimed = false, vipClaimed = false })
end)

RegisterNUICallback('paidshop:spinDailyReward', function(data, cb)
    local result = TriggerServerCallback('paidshop:spinDailyReward', data)
    cb(result or { success = false, message = "Erreur" })
end)

-- ========================================================================
-- CAISSE SCANNER NUI CALLBACKS
-- ========================================================================

RegisterNUICallback('paidshop:getDisplayedCases', function(_, cb)
    local result = TriggerServerCallback('paidshop:getDisplayedCases')
    cb(result or { cases = {}, reveals = {} })
end)

RegisterNUICallback('paidshop:scanCase', function(data, cb)
    if not data or not data.caseId then
        cb({ success = false, error = "ID manquant" })
        return
    end
    local result = TriggerServerCallback('paidshop:scanCase', data.caseId)
    cb(result or { success = false, error = "Action impossible pour le moment" })
end)

RegisterNUICallback('paidshop:buyRevealedCase', function(data, cb)
    if not data or not data.caseId then
        cb({ success = false, error = "ID manquant" })
        return
    end
    local result = TriggerServerCallback('paidshop:buyRevealedCase', data.caseId)
    if result and result.success and result.newCoins ~= nil then
        currentCoins = result.newCoins
        SendNUIMessage({
            action = "paidshop:updateCoins",
            data = { spacecoins = result.newCoins }
        })
    end
    cb(result or { success = false, error = "Action impossible pour le moment" })
end)

-- Network Events

-- Receive UI notification from server
RegisterNetEvent('paidshop:uiNotification')
AddEventHandler('paidshop:uiNotification', function(data)
    SendNUIMessage({ action = "paidshop:uiNotification", data = data })
end)

-- Synchronise l'état "récompense quotidienne réclamée" côté NUI quel que soit le flux serveur
RegisterNetEvent('paidshop:dailyRewardClaimed')
AddEventHandler('paidshop:dailyRewardClaimed', function()
    SendNUIMessage({ action = "paidshop:dailyRewardClaimed" })
end)

-- Live activity ticker — forwards server broadcast to NUI
RegisterNetEvent('paidshop:liveActivity')
AddEventHandler('paidshop:liveActivity', function(data)
    SendNUIMessage({ action = "paidshop:liveActivity", data = data })
end)

-- Update Coins
RegisterNetEvent('paidshop:updateCoins')
AddEventHandler('paidshop:updateCoins', function(spacecoins)
    currentCoins = spacecoins
    SendNUIMessage({
        action = "paidshop:updateCoins",
        data = {
            spacecoins = spacecoins
        }
    })
end)

-- Update pending item count
RegisterNetEvent('paidshop:updatePendingItemCount')
AddEventHandler('paidshop:updatePendingItemCount', function(count)
    SendNUIMessage({
        action = "paidshop:updatePendingItemCount",
        data = {
            count = count
        }
    })
end)

-- Update admin status
RegisterNetEvent('paidshop:updateAdminStatus')
AddEventHandler('paidshop:updateAdminStatus', function(admin)
    isAdmin = admin
    if display then
        SendNUIMessage({
            action = "paidshop:updateAdminStatus",
            data = {
                isAdmin = isAdmin
            }
        })
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end

    if isInPreview then
        local ped = PlayerPedId()
        if originalCoords then
            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
        end
        isInPreview = false
        testDriveEndTime = 0
    end

    if display then
        PaidShopClient.CloseUI()
    end
end)

