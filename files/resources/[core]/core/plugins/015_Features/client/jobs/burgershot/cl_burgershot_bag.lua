local bagOpen = false
local bagJobName = nil
local BURGERSHOT_LOGO = VFW.CDN.Get("entreprise/burgershot.png")

function BurgerShot_OpenBag(jobName)
    if bagOpen then return end

    local result = TriggerServerCallback("burgershot:bag:getData", jobName)
    if not result then
        VFW.ShowNotification({ type = "JOB", title = "BurgerShot", subtitle = "Service", image = BURGERSHOT_LOGO, content = "Vous devez être en service." })
        return
    end

    bagOpen = true
    bagJobName = jobName

    SendNUIMessage({
        action = "burgershot:bag:update",
        data = {
            bags = result.bags,
            inventoryItems = result.inventoryItems
        }
    })
end

local function closeBag()
    if not bagOpen then return end
    bagOpen = false
    bagJobName = nil
end

function BurgerShot_CloseBag()
    closeBag()
end

local function refreshBagData()
    if not bagOpen or not bagJobName then return end
    local result = TriggerServerCallback("burgershot:bag:getData", bagJobName)
    if result then
        SendNUIMessage({
            action = "burgershot:bag:update",
            data = {
                bags = result.bags,
                inventoryItems = result.inventoryItems
            }
        })
    end
end

RegisterNUICallback("burgershot:bag:addItem", function(data, cb)
    if not bagOpen or not bagJobName then
        cb({ ok = false })
        return
    end

    local success, errMsg, updated = TriggerServerCallback(
        "burgershot:bag:addItem",
        bagJobName,
        data.bagSlot,
        data.itemName,
        data.quantity or 1
    )

    if not success then
        VFW.ShowNotification({ type = "JOB", title = "BurgerShot", subtitle = "Sac", image = BURGERSHOT_LOGO, content = errMsg or "Erreur." })
        cb({ ok = false })
        return
    end

    if updated then
        SendNUIMessage({
            action = "burgershot:bag:update",
            data = {
                bags = updated.bags,
                inventoryItems = updated.inventoryItems
            }
        })
    end

    cb({ ok = true })
end)

RegisterNUICallback("burgershot:bag:removeItem", function(data, cb)
    if not bagOpen or not bagJobName then
        cb({ ok = false })
        return
    end

    local success, errMsg, updated = TriggerServerCallback(
        "burgershot:bag:removeItem",
        bagJobName,
        data.bagSlot,
        data.itemName,
        data.quantity or 1
    )

    if not success then
        VFW.ShowNotification({ type = "JOB", title = "BurgerShot", subtitle = "Sac", image = BURGERSHOT_LOGO, content = errMsg or "Erreur." })
        cb({ ok = false })
        return
    end

    if updated then
        SendNUIMessage({
            action = "burgershot:bag:update",
            data = {
                bags = updated.bags,
                inventoryItems = updated.inventoryItems
            }
        })
    end

    cb({ ok = true })
end)

RegisterNUICallback("burgershot:bag:close", function(_, cb)
    closeBag()
    cb({ ok = true })
end)
