--RegisterCommand("item", function()
--    TriggerServerEvent("vfw:itemPool:requestOpen")
--end)

RegisterNetEvent("vfw:itemPool:open")
AddEventHandler("vfw:itemPool:open", function(allItems)
    VFW.OpenInventory({
        inventory = allItems,
        name = "Tous les Items",
        maxWeight = 9999,
        weight = 0,
        maxSlots = #allItems,
        search = false,
        type = "item_pool",
        infiniteItems = true,

    })
end)



