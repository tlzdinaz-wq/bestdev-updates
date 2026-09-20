---@meta _
---@diagnostic disable: duplicate-doc-field

local FireworkShops = {}
local FireworkNPCs = {}
local FireworkNPCsCreating = {}
local GlobalFireworkItems = nil

local function EnumeratePeds()
    return coroutine.wrap(function()
        local ped = 0
        repeat
            ped = FindFirstPed(ped)
            if ped ~= 0 then
                coroutine.yield(ped)
            end
        until not FindNextPed(ped)
        EndFindPed(ped)
    end)
end

RegisterNetEvent("core:firework:invalidateGlobalItemsCache")
AddEventHandler("core:firework:invalidateGlobalItemsCache", function()
    GlobalFireworkItems = nil
end)

local function OpenFireworkShop(shopId)
    -- Check if shop is active
    local shop = FireworkShops[shopId]
    if not shop or not shop.active then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Je n'ai plus de stock malheureusement, repasse plus tard."
        })
        return
    end

    -- Load global items if not cached
    if not GlobalFireworkItems then
        GlobalFireworkItems = TriggerServerCallback("core:firework:getGlobalItems") or {}
    end

    -- Check if there are any items available
    if not GlobalFireworkItems or #GlobalFireworkItems == 0 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Je n'ai plus de stock malheureusement, repasse plus tard."
        })
        return
    end

    -- Transform items for FireworkShop format
    local products = {}
    for _, item in ipairs(GlobalFireworkItems) do
        local category = item.category or "tous"

        table.insert(products, {
            name = item.label or item.name,
            price = item.price or 0,
            image = VFW.ItemImageUrl(item.name, VFW.Items and VFW.Items[item.name]),
            category = category,
            itemName = item.name
        })
    end

    -- Get fresh accounts from server
    local freshAccounts = TriggerServerCallback("core:firework:getPlayerAccounts")
    local playerMoney = freshAccounts and freshAccounts.cash or (VFW.PlayerData.money or 0)
    local playerBank = freshAccounts and freshAccounts.bank or 0

    SendNUIMessage({
        action = "openFireworkShop",
        data = {
            products = products,
            playerName = VFW.PlayerData.firstName,
            playerMoney = playerMoney,
            playerBank = playerBank
        }
    })

    VFW.Nui.Focus(true, false)
end

function GetFireworkShops()
    return FireworkShops
end

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

CreateThread(function()
    Wait(1000)
    TriggerServerEvent("core:firework:requestShopsList")
end)

local function GetClosestFireworkShop()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, shop in pairs(FireworkShops) do
        if shop.active and shop.npcPos then
            local npcPos = vector3(shop.npcPos.x, shop.npcPos.y, shop.npcPos.z)
            local dist = #(coords - npcPos)
            if dist < closestDist then
                closest = id
                closestDist = dist
            end
        end
    end

    return closest, closestDist
end

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not FireworkNPCs then
            FireworkNPCs = {}
        end

        local closestNPC = nil
        local closestNPCDist = 999999.0

        -- Check tracked NPCs first
        for id, npc in pairs(FireworkNPCs) do
            if DoesEntityExist(npc) then
                local npcCoords = GetEntityCoords(npc)
                local dist = #(playerCoords - npcCoords)
                if dist < closestNPCDist then
                    closestNPC = npc
                    closestNPCDist = dist
                end
            end
        end

        -- Scan all peds as backup
        for ped in EnumeratePeds() do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
                -- Check if this ped is one of our firework NPCs by position
                for id, shop in pairs(FireworkShops) do
                    if shop.npcPos then
                        local npcPos = vector3(shop.npcPos.x, shop.npcPos.y, shop.npcPos.z)
                        local pedCoords = GetEntityCoords(ped)
                        if #(pedCoords - npcPos) < 1.0 then
                            local dist = #(playerCoords - pedCoords)
                            if dist < closestNPCDist then
                                closestNPC = ped
                                closestNPCDist = dist
                            end
                        end
                    end
                end
            end
        end

        if closestNPC and closestNPCDist < 3.0 then
            wait = 0
            local shopId = GetClosestFireworkShop()

            if shopId then
                local shop = FireworkShops[shopId]
                
                -- Check if shop is active
                if not shop.active then
                    ShowHelp("~r~Je n'ai plus de stock malheureusement, repasse plus tard.")
                else
                    ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la boutique de feux d'artifice")

                    if VFW.Interact.JustPressed(0, 38) then
                        OpenFireworkShop(shopId)
                    end
                end
            end
        end

        Wait(wait)
    end
end)

local function CleanupFireworkShop(id)
    if FireworkNPCs[id] and DoesEntityExist(FireworkNPCs[id]) then
        DeleteEntity(FireworkNPCs[id])
        FireworkNPCs[id] = nil
    end
end

local function SetupFireworkShop(id, shop)
    if shop.active then
        if shop.npcPos then
            if FireworkNPCsCreating[id] then return end
            if FireworkNPCs[id] and DoesEntityExist(FireworkNPCs[id]) then return end

            FireworkNPCsCreating[id] = true

            local coords = {
                x = shop.npcPos.x,
                y = shop.npcPos.y,
                z = shop.npcPos.z - 1.0,
                w = shop.npcPos.h or 0.0
            }

            local npcModel = shop.npcModel or "mp_m_shopkeep_01"
            local npc = VFW.CreatePed(coords, npcModel)

            if npc and DoesEntityExist(npc) then
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                SetPedCanRagdoll(npc, false)
                SetEntityMaxHealth(npc, 200)
                SetEntityHealth(npc, 200)

                ClearPedTasks(npc)
                TaskStandStill(npc, -1)

                FireworkNPCs[id] = npc
            end

            FireworkNPCsCreating[id] = nil
        else
            if FireworkNPCs[id] and DoesEntityExist(FireworkNPCs[id]) then
                DeleteEntity(FireworkNPCs[id])
                FireworkNPCs[id] = nil
            end
        end
    else
        CleanupFireworkShop(id)
    end
end

RegisterNetEvent("core:firework:syncShops")
AddEventHandler("core:firework:syncShops", function(shops)
    for id, npc in pairs(FireworkNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        FireworkNPCs[id] = nil
    end

    FireworkShops = shops

    for id, shop in pairs(shops) do
        SetupFireworkShop(id, shop)
    end
end)


RegisterNetEvent("core:firework:cleanupAllNPCs")
AddEventHandler("core:firework:cleanupAllNPCs", function()
    for id, npc in pairs(FireworkNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        FireworkNPCs[id] = nil
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeFireworkShop', function(data, cb)
    VFW.Nui.Focus(false)
    cb('ok')
end)

RegisterNUICallback('fireworkPurchaseItems', function(data, cb)
    local items = data.items or {}
    local total = data.total or 0
    local paymentMethod = data.paymentMethod or "cash"

    if #items == 0 then
        cb({ success = false, message = "Panier vide" })
        return
    end

    local purchaseData = {}
    for _, item in ipairs(items) do
        table.insert(purchaseData, {
            name = item.itemName or item.name,
            quantity = item.quantity or 1,
            price = item.price or 0
        })
    end

    local result = TriggerServerCallback('core:firework:purchaseItems', purchaseData, total, paymentMethod)

    if result and result.success then
        VFW.ShowNotification({
            type = 'VERT',
            content = "Achat effectué !"
        })

        -- Update money display
        SendNUIMessage({
            action = "updateFireworkMoney",
            data = {
                playerMoney = result.cash or 0,
                playerBank = result.bank or 0
            }
        })

        cb({ success = true })
    else
        local message = result and result.message or "Erreur lors de l'achat"
        if message:find("inventaire") then
            VFW.ShowNotification({
                type = "JOB",
                title = "Inventaire",
                subtitle = "CAPACITÉ MAXIMALE",
                logo = VFW.CDN.Get("icons/inventory.png"),
                content = message
            })
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = message
            })
        end
        cb({ success = false, message = message })
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(FireworkNPCs) do
            CleanupFireworkShop(id)
        end
    end
end)