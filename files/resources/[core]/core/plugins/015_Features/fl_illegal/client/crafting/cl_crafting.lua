local menuOpen = false


local function openIllegalCraftingMenu()
    if menuOpen then
        return
    end

    menuOpen = true

    local craftingData = TriggerServerCallback("illegalCrafting:getStationData")

    VFW.Nui.Focus(true)

    SendNUIMessage({
        action = 'illegalCrafting:visible',
        data = true
    })

    SendNUIMessage({
        action = 'illegalCrafting:data',
        data = {
            title = craftingData.title or 'FABRICATION ILLÉGALE',
            slots = craftingData.slots or {}
        }
    })
end

local function closeIllegalCraftingMenu()
    if not menuOpen then
        return
    end

    menuOpen = false

    VFW.Nui.Focus(false)

    SendNUIMessage({
        action = 'illegalCrafting:visible',
        data = false
    })
end

--RegisterCommand('illegalcraft', function()
--    if IsPlayerInTIG() then
--        VFW.ShowNotification({
--            type = 'ILLEGAL',
--            message = "Cette activité est désactivée pendant les TIG"
--        })
--        return
--    end
--    if menuOpen then
--        closeIllegalCraftingMenu()
--    else
--        openIllegalCraftingMenu()
--    end
--end, false)

RegisterNetEvent('core:illegalCrafting:craft', function(payload)
    if not payload or not payload.itemId then
        return
    end

    if payload.isLegal then
        return
    end

    local isDynamicOpen = exports['core']:isDynamicStationOpen()
    if isDynamicOpen then
        return
    end

    local craftInfo = TriggerServerCallback('illegalCrafting:prepareCraft', {
        itemId = payload.itemId,
        quantity = payload.quantity or 1
    })

    if craftInfo.success then
        TriggerEvent('illegalCrafting:startTimer', payload.itemId, payload.quantity or 1, craftInfo.craftTime, craftInfo.stationId)
    else
        TriggerEvent('illegalCrafting:notify', 'ROUGE', "~r~Erreur: " .. craftInfo.message)
    end
end)

RegisterNetEvent('core:illegalCrafting:forceClose', function()
    closeIllegalCraftingMenu()
end)

RegisterNetEvent('illegalCrafting:openMenu', function()
    openIllegalCraftingMenu()
end)

exports('openIllegalCraftingMenu', function()
    openIllegalCraftingMenu()
end)

exports('closeIllegalCraftingMenu', function()
    closeIllegalCraftingMenu()
end)

exports('refreshCraftingMenu', function()
    if menuOpen then
        local craftingData = TriggerServerCallback("illegalCrafting:getStationData")
        SendNUIMessage({
            action = 'illegalCrafting:data',
            data = {
                title = craftingData.title or 'FABRICATION ILLÉGALE',
                slots = craftingData.slots or {}
            }
        })
    end
end)