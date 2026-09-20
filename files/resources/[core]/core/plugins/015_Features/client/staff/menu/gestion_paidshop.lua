---@meta _
---@diagnostic disable: duplicate-doc-field

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["boutique"] == true
end

local function Dual(ok, msg)
    if ok then
        return { ok = true, message = type(msg) == "string" and msg or nil }
    end
    return { ok = false, error = (type(msg) == "string" and msg) or "Action impossible." }
end

local function ShopPayload()
    local shop = TriggerServerCallback("paidshop:getShopData") or {}
    local catOk, categories = TriggerServerCallback("paidshop:adminGetAllCategories")
    local daily = TriggerServerCallback("paidshop:getDailyRewards") or {}
    local streak = TriggerServerCallback("paidshop:adminGetDailyStreak") or {}
    local displayed = TriggerServerCallback("paidshop:builder:getDisplayedCases") or {}
    local available = TriggerServerCallback("paidshop:builder:getAvailableCases") or {}
    local pourMoi = TriggerServerCallback("paidshop:adminGetPourMoiPool") or {}
    return {
        ok = true,
        categories = shop.categories or {},
        items = shop.items or {},
        adminCategories = (catOk and categories) or {},
        daily = daily,
        streakSlots = (streak.success and streak.slots) or {},
        displayedCases = displayed.displayedCases or {},
        availableCases = available.availableCases or {},
        pourMoi = pourMoi.pool or {},
    }
end

RegisterNuiCallback("gestion:paidshop:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission boutique." })
        return
    end
    cb(ShopPayload())
end)

RegisterNuiCallback("gestion:paidshop:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(ShopPayload())
end)

RegisterNuiCallback("gestion:paidshop:saveItem", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local item = data and data.item
    local category = data and data.category
    if type(item) ~= "table" or type(category) ~= "string" then
        cb({ ok = false, error = "Article invalide." })
        return
    end
    local ok, msg = TriggerServerCallback("paidshop:editItemServer", item, category)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:addItem", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local item = data and data.item
    local category = data and data.category
    if type(item) ~= "table" or type(category) ~= "string" then
        cb({ ok = false, error = "Article invalide." })
        return
    end
    local ok, msg = TriggerServerCallback("paidshop:addItemServer", item, category)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:deleteItem", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:deleteItemServer", data and data.spawnName, data and data.category)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:setFeatured", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:setFeaturedItem", data and data.category, data and data.spawnName)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:toggleCategory", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:adminSetCategoryEnabled", data and data.id, data and data.enabled)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:coins", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local action = data and data.action
    local targetId = tonumber(data and data.targetId)
    local amount = tonumber(data and data.amount)
    if action == "lookup" then
        local ok, info = TriggerServerCallback("paidshop:getCoinsAdmin", targetId)
        if not ok then cb(Dual(false, info)) return end
        cb({ ok = true, coins = info })
        return
    end
    local event = action == "remove" and "paidshop:removeCoinsAdmin" or "paidshop:addCoinsAdmin"
    local ok, msg = TriggerServerCallback(event, targetId, amount)
    cb(Dual(ok, msg))
end)

RegisterNuiCallback("gestion:paidshop:give", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback(
        "paidshop:giveItemAdmin",
        data and data.mode,
        data and data.targetValue,
        data and data.spawnName,
        data and data.category,
        data and data.quantity
    )
    cb(Dual(ok, msg))
end)

RegisterNuiCallback("gestion:paidshop:dailyAdd", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:addDailyReward", data)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:dailyEdit", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:editDailyReward", data)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:dailyDelete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:deleteDailyReward", data and data.spawnName)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:streakSave", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback("paidshop:adminEditDailyStreakSlot", data and data.slot, data and data.draft)
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:scannerSet", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local res = TriggerServerCallback("paidshop:builder:setDisplayedCases", data and data.list)
    if not res or not res.success then
        cb({ ok = false, error = (res and res.error) or "Erreur lors de la sauvegarde" })
        return
    end
    local payload = ShopPayload()
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:pourMoiAdd", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback(
        "paidshop:adminAddPourMoiItem",
        data and data.sourceCategory,
        data and data.sourceSpawnName,
        data and data.rarity,
        data and data.reductionPercent
    )
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:pourMoiUpdate", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback(
        "paidshop:adminUpdatePourMoiItem",
        data and data.sourceCategory,
        data and data.sourceSpawnName,
        data and data.rarity,
        data and data.reductionPercent
    )
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)

RegisterNuiCallback("gestion:paidshop:pourMoiRemove", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local ok, msg = TriggerServerCallback(
        "paidshop:adminRemovePourMoiItem",
        data and data.sourceCategory,
        data and data.sourceSpawnName
    )
    if not ok then cb(Dual(false, msg)) return end
    local payload = ShopPayload()
    payload.message = msg
    cb(payload)
end)
