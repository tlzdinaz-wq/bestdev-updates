local PochonShopNPC = nil
local PochonShopConfig = { price = 50, dirty_money_price = 75, dirty_money_allowed = false }

local NPC_COORDS = { x = -1175.01, y = -1574.34, z = 3.37, w = 122.29 }
local NPC_MODEL = "s_m_y_dealer_01"
local INTERACTION_DIST = 3.0

local function SpawnNPC()
    if PochonShopNPC and DoesEntityExist(PochonShopNPC) then
        DeleteEntity(PochonShopNPC)
        PochonShopNPC = nil
    end

    local npc = VFW.CreatePed(NPC_COORDS, NPC_MODEL)

    if npc and DoesEntityExist(npc) then
        SetEntityInvincible(npc, true)
        FreezeEntityPosition(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedCanRagdoll(npc, false)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_DRUG_DEALER", 0, true)
        PochonShopNPC = npc
    end
end

local function OpenShop()
    local result = TriggerServerCallback("pochonShop:getShopData")
    if not result then return end

    local itemInfo = VFW.Items["pochon_vide"]
    local itemLabel = itemInfo and itemInfo.label or "Pochon vide"

    SendNUIMessage({
        action = "openPochonShop",
        data = {
            itemName = "pochon_vide",
            itemLabel = itemLabel,
            itemImage = VFW.CDN.Get("items/pochon_vide.webp"),
            price = result.price,
            dirtyMoneyPrice = result.dirtyMoneyPrice,
            dirtyMoneyAllowed = result.dirty_money_allowed,
            playerMoney = result.playerMoney,
            playerBank = result.playerBank,
            dirtyMoney = result.dirtyMoney
        }
    })

    VFW.Nui.Focus(true, false)
end

RegisterNetEvent("pochonShop:syncConfig")
AddEventHandler("pochonShop:syncConfig", function(config)
    if config then
        PochonShopConfig.price = config.price or 50
        PochonShopConfig.dirty_money_price = config.dirty_money_price or 75
        PochonShopConfig.dirty_money_allowed = config.dirty_money_allowed or false
    end
end)

RegisterNUICallback("closePochonShop", function(_, cb)
    VFW.Nui.Focus(false, false)
    cb("ok")
end)

RegisterNUICallback("pochonShopPurchase", function(data, cb)
    local quantity = data.quantity
    local paymentMethod = data.paymentMethod

    local result = TriggerServerCallback("pochonShop:purchase", quantity, paymentMethod)

    if result and result.success then
        VFW.ShowNotification({
            type = "VERT",
            content = "Achat effectué !"
        })
        cb({ success = true })
    else
        local message = result and result.message or "Erreur lors de l'achat"
        VFW.ShowNotification({
            type = "ROUGE",
            content = message
        })
        cb({ success = false, message = message })
    end
end)

CreateThread(function()
    Wait(3000)
    SpawnNPC()
end)

CreateThread(function()
    while true do
        local wait = 1000

        if PochonShopNPC and DoesEntityExist(PochonShopNPC) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local npcCoords = GetEntityCoords(PochonShopNPC)
            local dist = #(playerCoords - npcCoords)

            if dist < INTERACTION_DIST then
                wait = 0
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour acheter des pochons")

                if VFW.Interact.JustPressed(0, 38) then
                    OpenShop()
                end
            end
        end

        Wait(wait)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if PochonShopNPC and DoesEntityExist(PochonShopNPC) then
            DeleteEntity(PochonShopNPC)
            PochonShopNPC = nil
        end
    end
end)
