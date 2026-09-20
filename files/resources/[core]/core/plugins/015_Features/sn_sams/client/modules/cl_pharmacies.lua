---@meta _
---@diagnostic disable: duplicate-doc-field

local Pharmacies = {}
local PharmacyBlips = {}
local PharmacyNPCs = {}
local PharmacyItemsCache = nil

local npcModel = `s_m_m_doctor_01`

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

RegisterNetEvent("sn_sams:pharmacy:invalidateItemsCache")
AddEventHandler("sn_sams:pharmacy:invalidateItemsCache", function()
    PharmacyItemsCache = nil
end)

local function OpenPharmacyShop(pharmacyId)
    local result = TriggerServerCallback("sn_sams:pharmacy:getItemsForShop") or {}
    local itemsList = result.items or {}
    local isSams = result.isSams or false
    local canUseSociety = result.canUseSociety or false
    local societyMoney = result.societyMoney or 0

    PharmacyItemsCache = itemsList

    local products = {}
    for _, item in ipairs(PharmacyItemsCache) do
        table.insert(products, {
            name = item.label or item.name,
            price = item.price or 0,
            image = VFW.ItemImageUrl(item.name, VFW.Items and VFW.Items[item.name]),
            category = "medicaments",
            itemName = item.name,
            isSamsItem = item.isSamsItem or false
        })
    end

    local playerMoney = result.cash or (VFW.PlayerData.money or 0)
    local playerBank = result.bank or 0

    SendNUIMessage({
        action = "openPharmacy",
        data = {
            products = products,
            playerName = VFW.PlayerData.firstName,
            playerMoney = playerMoney,
            playerBank = playerBank,
            isSams = isSams,
            canUseSociety = canUseSociety,
            societyMoney = societyMoney
        }
    })

    VFW.Nui.Focus(true, false)
end

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

local function CleanupNPCAtPosition(pos)
    local targetPos = vector3(pos.x, pos.y, pos.z)

    for ped in EnumeratePeds() do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local model = GetEntityModel(ped)
            if model == npcModel then
                local pedCoords = GetEntityCoords(ped)
                if #(pedCoords - targetPos) < 0.5 then
                    DeleteEntity(ped)
                    return true
                end
            end
        end
    end

    return false
end

local function CleanupAllPharmacyNPCs()
    for id, npc in pairs(PharmacyNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        PharmacyNPCs[id] = nil
    end

    for id, pharmacy in pairs(Pharmacies) do
        if pharmacy.npcPos then
            CleanupNPCAtPosition(pharmacy.npcPos)
        end
    end
end

local function GetClosestPharmacy()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, pharmacy in pairs(Pharmacies) do
        if pharmacy.active and pharmacy.npcPos then
            local npcPos = vector3(pharmacy.npcPos.x, pharmacy.npcPos.y, pharmacy.npcPos.z)
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

        if not PharmacyNPCs then
            PharmacyNPCs = {}
        end

        local closestNPC = nil
        local closestNPCDist = 999999.0

        for id, npc in pairs(PharmacyNPCs) do
            if DoesEntityExist(npc) then
                local npcCoords = GetEntityCoords(npc)
                local dist = #(playerCoords - npcCoords)
                if dist < closestNPCDist then
                    closestNPC = npc
                    closestNPCDist = dist
                end
            end
        end

        for ped in EnumeratePeds() do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
                local model = GetEntityModel(ped)
                if model == npcModel then
                    local pedCoords = GetEntityCoords(ped)
                    local dist = #(playerCoords - pedCoords)
                    if dist < closestNPCDist then
                        closestNPC = ped
                        closestNPCDist = dist
                    end
                end
            end
        end

        if closestNPC and closestNPCDist < 3.0 then
            wait = 0
            local pharmacyId = GetClosestPharmacy()

            if pharmacyId then
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la pharmacie")

                if VFW.Interact.JustPressed(0, 38) then
                    OpenPharmacyShop(pharmacyId)
                end
            end
        end

        Wait(wait)
    end
end)

local function CleanupPharmacy(id)
    if PharmacyBlips[id] and DoesBlipExist(PharmacyBlips[id]) then
        RemoveBlip(PharmacyBlips[id])
        PharmacyBlips[id] = nil
    end

    if PharmacyNPCs[id] and DoesEntityExist(PharmacyNPCs[id]) then
        DeleteEntity(PharmacyNPCs[id])
        PharmacyNPCs[id] = nil
    end
end

local function SetupPharmacy(id, pharmacy)
    if pharmacy.active then
        if pharmacy.blipEnabled and pharmacy.pos then
            -- Supprimer l'ancien blip s'il existe (position a pu changer)
            if PharmacyBlips[id] and DoesBlipExist(PharmacyBlips[id]) then
                RemoveBlip(PharmacyBlips[id])
                PharmacyBlips[id] = nil
            end

            local blip = AddBlipForCoord(pharmacy.pos.x, pharmacy.pos.y, pharmacy.pos.z)

            SetBlipSprite(blip, 51)
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 2)
            SetBlipAsShortRange(blip, true)
            SetBlipDisplay(blip, 4)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Pharmacie")
            EndTextCommandSetBlipName(blip)

            PharmacyBlips[id] = blip
        else
            if PharmacyBlips[id] and DoesBlipExist(PharmacyBlips[id]) then
                RemoveBlip(PharmacyBlips[id])
                PharmacyBlips[id] = nil
            end
        end

        if pharmacy.npcPos then
            -- Supprimer l'ancien NPC s'il existe (position a pu changer)
            if PharmacyNPCs[id] and DoesEntityExist(PharmacyNPCs[id]) then
                DeleteEntity(PharmacyNPCs[id])
                PharmacyNPCs[id] = nil
            end

            CleanupNPCAtPosition(pharmacy.npcPos)

            local coords = {
                x = pharmacy.npcPos.x,
                y = pharmacy.npcPos.y,
                z = pharmacy.npcPos.z - 1.0,
                w = pharmacy.npcPos.h or 0.0
            }

            local npc = VFW.CreatePed(coords, "s_m_m_doctor_01")

            if npc and DoesEntityExist(npc) then
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                SetPedCanRagdoll(npc, false)
                SetEntityMaxHealth(npc, 200)
                SetEntityHealth(npc, 200)

                ClearPedTasks(npc)
                TaskStandStill(npc, -1)

                PharmacyNPCs[id] = npc
            end
        else
            if PharmacyNPCs[id] and DoesEntityExist(PharmacyNPCs[id]) then
                DeleteEntity(PharmacyNPCs[id])
                PharmacyNPCs[id] = nil
            end
        end
    else
        CleanupPharmacy(id)
    end
end

local isFirstSync = true
local hasReceivedSync = false

RegisterNetEvent("sn_sams:pharmacy:sync")
AddEventHandler("sn_sams:pharmacy:sync", function(pharmacies)
    if isFirstSync then
        CleanupAllPharmacyNPCs()
        isFirstSync = false
    end

    for id, _ in pairs(PharmacyBlips) do
        if not pharmacies[id] then
            CleanupPharmacy(id)
        end
    end

    Pharmacies = pharmacies
    hasReceivedSync = true

    for id, pharmacy in pairs(pharmacies) do
        SetupPharmacy(id, pharmacy)
    end
end)

CreateThread(function()
    Wait(10000)
    if not hasReceivedSync or not next(Pharmacies) then
        TriggerServerEvent("sn_sams:pharmacy:requestSync")
    end
end)

RegisterNetEvent("sn_sams:pharmacy:cleanupAllNPCs")
AddEventHandler("sn_sams:pharmacy:cleanupAllNPCs", function()
    CleanupAllPharmacyNPCs()
    isFirstSync = true
end)

RegisterNUICallback('closePharmacy', function(data, cb)
    VFW.Nui.Focus(false, false)
    cb('ok')
end)

RegisterNUICallback('pharmacyPurchaseItems', function(data, cb)
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

    local result = TriggerServerCallback('sn_sams:pharmacy:purchaseItems', purchaseData, total, paymentMethod)

    if result and result.success then
        VFW.ShowNotification({
            type = 'JOB',
            title = 'Pharmacie',
            subtitle = 'ACHAT',
            content = "Achat effectué !"
        })
        cb({ success = true })
    else
        local message = result and result.message or "Erreur lors de l'achat"
        if message:find("inventaire") then
            VFW.ShowNotification({
                type = "JOB",
                title = "Inventaire",
                subtitle = "CAPACITE MAXIMALE",
                logo = VFW.CDN.Get("icons/inventory.png"),
                content = message
            })
        else
            VFW.ShowNotification({
                type = 'JOB',
                title = 'Pharmacie',
                subtitle = 'ERREUR',
                content = message
            })
        end
        cb({ success = false, message = message })
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(PharmacyBlips) do
            CleanupPharmacy(id)
        end
    end
end)
