---@meta _
---@diagnostic disable: duplicate-doc-field

local Ammunitions = {}
local AmmunitionBlips = {}
local AmmunitionNPCs = {}
local GlobalAmmunitionItems = nil

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

RegisterNetEvent("core:ammunition:invalidateGlobalItemsCache")
AddEventHandler("core:ammunition:invalidateGlobalItemsCache", function()
    GlobalAmmunitionItems = nil
end)

local function OpenAmmunitionShop(ammunitionId)
    if not GlobalAmmunitionItems then
        GlobalAmmunitionItems = TriggerServerCallback("core:ammunition:getGlobalItems") or {}
    end

    local products = {}
    for _, item in ipairs(GlobalAmmunitionItems) do
        local category = item.category or "tous"

        table.insert(products, {
            name = item.label or item.name,
            price = item.price or 0,
            image = VFW.ItemImageUrl(item.name, VFW.Items and VFW.Items[item.name]),
            category = category,
            itemName = item.name
        })
    end

    local freshAccounts = TriggerServerCallback("core:ammunition:getPlayerAccounts")
    local playerMoney = freshAccounts and freshAccounts.cash or (VFW.PlayerData.money or 0)
    local playerBank = freshAccounts and freshAccounts.bank or 0

    SendNUIMessage({
        action = "openAmmunition",
        data = {
            products = products,
            playerName = VFW.PlayerData.firstName,
            playerMoney = playerMoney,
            playerBank = playerBank
        }
    })

    VFW.Nui.Focus(true)
end

function GetAmmunitions()
    return Ammunitions
end

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

CreateThread(function()
    Wait(1000)
    TriggerServerEvent("core:ammunition:requestAmmunitionsList")
end)

local npcModels = {
    `s_m_y_ammucity_01`,
    `s_m_m_ammucountry`
}

local function IsAmmunitionNPCModel(model)
    for _, m in ipairs(npcModels) do
        if model == m then
            return true
        end
    end
    return false
end

local function CleanupNPCAtPosition(pos)
    local targetPos = vector3(pos.x, pos.y, pos.z)

    for ped in EnumeratePeds() do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local model = GetEntityModel(ped)
            if IsAmmunitionNPCModel(model) then
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

local function CleanupAllAmmunitionNPCs()
    for id, npc in pairs(AmmunitionNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        AmmunitionNPCs[id] = nil
    end

    for id, ammunition in pairs(Ammunitions) do
        if ammunition.npcPos then
            CleanupNPCAtPosition(ammunition.npcPos)
        end
    end
end

local function GetClosestAmmunition()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, ammunition in pairs(Ammunitions) do
        if ammunition.active and ammunition.npcPos then
            local npcPos = vector3(ammunition.npcPos.x, ammunition.npcPos.y, ammunition.npcPos.z)
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

        if not AmmunitionNPCs then
            AmmunitionNPCs = {}
        end

        local closestNPC = nil
        local closestNPCDist = 999999.0

        for id, npc in pairs(AmmunitionNPCs) do
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
                if IsAmmunitionNPCModel(model) then
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
            local ammunitionId = GetClosestAmmunition()

            if ammunitionId then
                ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir l'armurerie")

                if VFW.Interact.JustPressed(0, 38) then
                    OpenAmmunitionShop(ammunitionId)
                end
            end
        end

        Wait(wait)
    end
end)

local function CleanupAmmunition(id)
    if AmmunitionBlips[id] and DoesBlipExist(AmmunitionBlips[id]) then
        RemoveBlip(AmmunitionBlips[id])
        AmmunitionBlips[id] = nil
    end

    if AmmunitionNPCs[id] and DoesEntityExist(AmmunitionNPCs[id]) then
        DeleteEntity(AmmunitionNPCs[id])
        AmmunitionNPCs[id] = nil
    end
end

local function SetupAmmunition(id, ammunition)
    if ammunition.active then
        if ammunition.blipEnabled then
            if not AmmunitionBlips[id] or not DoesBlipExist(AmmunitionBlips[id]) then
                local blip = AddBlipForCoord(ammunition.pos.x, ammunition.pos.y, ammunition.pos.z)

                SetBlipSprite(blip, 110)
                SetBlipScale(blip, 0.5)
                SetBlipColour(blip, 1)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Armurerie")
                EndTextCommandSetBlipName(blip)

                AmmunitionBlips[id] = blip
            end
        else
            if AmmunitionBlips[id] and DoesBlipExist(AmmunitionBlips[id]) then
                RemoveBlip(AmmunitionBlips[id])
                AmmunitionBlips[id] = nil
            end
        end

        if ammunition.npcPos then
            if not AmmunitionNPCs[id] or not DoesEntityExist(AmmunitionNPCs[id]) then
                CleanupNPCAtPosition(ammunition.npcPos)

                local coords = {
                    x = ammunition.npcPos.x,
                    y = ammunition.npcPos.y,
                    z = ammunition.npcPos.z - 1.0,
                    w = ammunition.npcPos.h or 0.0
                }

                local npc = VFW.CreatePed(coords, "s_m_y_ammucity_01")

                if npc and DoesEntityExist(npc) then
                    SetEntityInvincible(npc, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    SetPedCanRagdoll(npc, false)
                    SetEntityMaxHealth(npc, 200)
                    SetEntityHealth(npc, 200)

                    ClearPedTasks(npc)
                    TaskStandStill(npc, -1)

                    AmmunitionNPCs[id] = npc
                end
            end
        else
            if AmmunitionNPCs[id] and DoesEntityExist(AmmunitionNPCs[id]) then
                DeleteEntity(AmmunitionNPCs[id])
                AmmunitionNPCs[id] = nil
            end
        end
    else
        CleanupAmmunition(id)
    end
end

local isFirstSync = true

RegisterNetEvent("core:ammunition:syncAmmunitions")
AddEventHandler("core:ammunition:syncAmmunitions", function(ammunitions)
    if isFirstSync then
        CleanupAllAmmunitionNPCs()
        isFirstSync = false
    end

    for id, _ in pairs(AmmunitionBlips) do
        if not ammunitions[id] then
            CleanupAmmunition(id)
        end
    end

    Ammunitions = ammunitions

    for id, ammunition in pairs(ammunitions) do
        SetupAmmunition(id, ammunition)
    end
end)

RegisterNetEvent("core:ammunition:receiveAmmunitionsList")
AddEventHandler("core:ammunition:receiveAmmunitionsList", function(ammunitions)
    TriggerEvent("core:ammunition:syncAmmunitions", ammunitions)
end)

RegisterNetEvent("core:ammunition:cleanupAllNPCs")
AddEventHandler("core:ammunition:cleanupAllNPCs", function()
    CleanupAllAmmunitionNPCs()
    isFirstSync = true
end)

RegisterNUICallback('closeAmmunition', function(data, cb)
    VFW.Nui.Focus(false)
    cb('ok')
end)

RegisterNUICallback('ammunitionPurchaseItems', function(data, cb)
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

    local result = TriggerServerCallback('core:ammunition:purchaseItems', purchaseData, total, paymentMethod)

    if result and result.success then
        VFW.ShowNotification({
            type = 'VERT',
            message = "Achat effectué !"
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
                message = message
            })
        end
        cb({ success = false, message = message })
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(AmmunitionBlips) do
            CleanupAmmunition(id)
        end
    end
end)
