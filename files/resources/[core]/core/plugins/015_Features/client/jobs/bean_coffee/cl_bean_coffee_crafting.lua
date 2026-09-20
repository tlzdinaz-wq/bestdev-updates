local craftingOpen = false
local isCrafting = false
local craftingJobName = nil
local granitaOpen = false
local isGraniting = false
local granitaJobName = nil
local BEAN_COFFEE_LOGO = VFW.CDN.Get("entreprise/bean.png")

local function getSortedCraftingSlots(jobName)
    local loc = BeanCoffeeConfig.Locations[jobName]
    if not loc or not loc.CraftingTable then return {} end

    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local sorted = {}

    for slotName, slotData in pairs(loc.CraftingTable.slots) do
        table.insert(sorted, { name = slotName, dist = #(playerPos - slotData.pos) })
    end

    table.sort(sorted, function(a, b) return a.dist < b.dist end)
    return sorted
end

local function getSortedGranitaSlots(jobName)
    local loc = BeanCoffeeConfig.Locations[jobName]
    if not loc or not loc.GranitaStation then return {} end

    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local sorted = {}

    for slotName, slotData in pairs(loc.GranitaStation.slots) do
        table.insert(sorted, { name = slotName, dist = #(playerPos - slotData.pos) })
    end

    table.sort(sorted, function(a, b) return a.dist < b.dist end)
    return sorted
end

function BeanCoffee_OpenCrafting(jobName)
    if craftingOpen or isCrafting then return end

    local slots = TriggerServerCallback("bean_coffee:crafting:getData", jobName)
    if not slots then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Service", image = BEAN_COFFEE_LOGO, content = "Vous devez être en service." })
        return
    end

    craftingOpen = true
    craftingJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "bean_coffee:crafting:visible",
        data = true
    })

    SendNUIMessage({
        action = "bean_coffee:crafting:data",
        data = {
            title = "BEAN COFFEE",
            jobName = jobName,
            slots = slots
        }
    })
end

local function closeCrafting()
    if not craftingOpen then return end
    craftingOpen = false
    craftingJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "bean_coffee:crafting:visible",
        data = false
    })
end

local function stopCraftingAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
end

local function showProgress(duration, cycle, total)
    SendNUIMessage({
        action = "bean_coffee:progress:start",
        data = {
            duration = duration,
            cycle = cycle,
            total = total
        }
    })
end

local function hideProgress()
    SendNUIMessage({
        action = "bean_coffee:progress:hide",
        data = {}
    })
end

local function waitCraftProgress(duration, cycle, total, animDict, animName)
    local startTime = GetGameTimer()
    local ped = PlayerPedId()

    ClearPedTasks(ped)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, duration, 0, 0, false, false, false)
    showProgress(duration, cycle, total)

    while true do
        Citizen.Wait(0)

        DisableJobMovementControls()

        if IsControlJustPressed(0, 73) or IsControlJustPressed(0, 177) then
            hideProgress()
            return false
        end

        if (GetGameTimer() - startTime) >= duration then
            hideProgress()
            return true
        end
    end
end

RegisterNUICallback("bean_coffee:crafting:craft", function(data, cb)
    if not craftingOpen then
        cb({ ok = false })
        return
    end

    local recipeId = data.itemId
    local quantity = data.quantity or 1
    local jobName = data.jobName or craftingJobName

    closeCrafting()
    cb({ ok = true })

    isCrafting = true

    local loc = BeanCoffeeConfig.Locations[jobName]
    if not loc or not loc.CraftingTable then
        isCrafting = false
        return
    end

    local sortedSlots = getSortedCraftingSlots(jobName)
    if #sortedSlots == 0 then
        isCrafting = false
        return
    end

    local claimedSlot = nil
    local errMsg
    for _, slot in ipairs(sortedSlots) do
        local success, msg = TriggerServerCallback("bean_coffee:crafting:claimSlot", jobName, slot.name)
        if success then
            claimedSlot = slot.name
            break
        end
        errMsg = msg
    end

    if not claimedSlot then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Préparation", image = BEAN_COFFEE_LOGO, content = errMsg or "Tous les postes sont occupés." })
        isCrafting = false
        return
    end

    local slotData = loc.CraftingTable.slots[claimedSlot]
    local animCfg = BeanCoffeeConfig.SharedAnim.crafting
    local ped = PlayerPedId()

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, slotData.pos.x, slotData.pos.y, GetEntityCoords(ped).z - 1.0, false, false, false, false)
    Wait(200)
    SetEntityHeading(ped, slotData.heading)

    RequestAnimDict(animCfg.dict)
    while not HasAnimDictLoaded(animCfg.dict) do
        Wait(10)
    end

    local crafted = 0

    for i = 1, quantity do
        local success, craftErrMsg, craftTime = TriggerServerCallback("bean_coffee:crafting:craftOne", jobName, recipeId)

        if not success then
            VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Préparation", image = BEAN_COFFEE_LOGO, content = craftErrMsg or "Une erreur est survenue lors de la fabrication." })
            break
        end

        local duration = (craftTime or 5) * 1000
        local completed = waitCraftProgress(duration, i, quantity, animCfg.dict, animCfg.name)

        if not completed then
            VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Préparation", image = BEAN_COFFEE_LOGO, content = "La fabrication a été annulée." })
            break
        end

        local result = TriggerServerCallback("bean_coffee:crafting:completeOne", jobName, recipeId)
        if result then
            crafted = crafted + 1
        else
            VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Préparation", image = BEAN_COFFEE_LOGO, content = "Une erreur est survenue lors de la finalisation." })
            break
        end
    end

    stopCraftingAnimation()
    TriggerServerCallback("bean_coffee:crafting:releaseSlot", jobName, claimedSlot)

    if crafted > 0 then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Préparation", image = BEAN_COFFEE_LOGO, content = "La fabrication est terminée ! (" .. crafted .. "/" .. quantity .. ")" })
    end

    isCrafting = false
end)

RegisterNUICallback("bean_coffee:crafting:close", function(_, cb)
    closeCrafting()
    cb({ ok = true })
end)

function BeanCoffee_OpenGranita(jobName)
    if granitaOpen or isGraniting then return end

    local slots = TriggerServerCallback("bean_coffee:granita:getData", jobName)
    if not slots then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Service", image = BEAN_COFFEE_LOGO, content = "Vous devez être en service." })
        return
    end

    granitaOpen = true
    granitaJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "bean_coffee:granita:visible",
        data = true
    })

    SendNUIMessage({
        action = "bean_coffee:granita:data",
        data = {
            jobName = jobName,
            slots = slots
        }
    })
end

local function closeGranita()
    if not granitaOpen then return end
    granitaOpen = false
    granitaJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "bean_coffee:granita:visible",
        data = false
    })
end

RegisterNUICallback("bean_coffee:granita:craft", function(data, cb)
    if not granitaOpen then
        cb({ ok = false })
        return
    end

    local recipeId = data.itemId
    local quantity = data.quantity or 1
    local jobName = data.jobName or granitaJobName

    closeGranita()
    cb({ ok = true })

    isGraniting = true

    local loc = BeanCoffeeConfig.Locations[jobName]
    if not loc or not loc.GranitaStation then
        isGraniting = false
        return
    end

    local sortedSlots = getSortedGranitaSlots(jobName)
    if #sortedSlots == 0 then
        isGraniting = false
        return
    end

    local claimedSlot = nil
    local errMsg
    for _, slot in ipairs(sortedSlots) do
        local success, msg = TriggerServerCallback("bean_coffee:granita:claimSlot", jobName, slot.name)
        if success then
            claimedSlot = slot.name
            break
        end
        errMsg = msg
    end

    if not claimedSlot then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Granita", image = BEAN_COFFEE_LOGO, content = errMsg or "Tous les postes sont occupés." })
        isGraniting = false
        return
    end

    local slotData = loc.GranitaStation.slots[claimedSlot]
    local animCfg = BeanCoffeeConfig.SharedAnim.granita
    local ped = PlayerPedId()

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, slotData.pos.x, slotData.pos.y, GetEntityCoords(ped).z - 1.0, false, false, false, false)
    Wait(200)
    SetEntityHeading(ped, slotData.heading)

    RequestAnimDict(animCfg.dict)
    while not HasAnimDictLoaded(animCfg.dict) do
        Wait(10)
    end

    local crafted = 0

    for i = 1, quantity do
        local success, craftErrMsg, craftTime = TriggerServerCallback("bean_coffee:granita:craftOne", jobName, recipeId)

        if not success then
            VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Granita", image = BEAN_COFFEE_LOGO, content = craftErrMsg or "Une erreur est survenue lors de la préparation." })
            break
        end

        local duration = (craftTime or 4) * 1000
        local completed = waitCraftProgress(duration, i, quantity, animCfg.dict, animCfg.name)

        if not completed then
            VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Granita", image = BEAN_COFFEE_LOGO, content = "La préparation a été annulée." })
            break
        end

        local result = TriggerServerCallback("bean_coffee:granita:completeOne", jobName, recipeId)
        if result then
            crafted = crafted + 1
        else
            VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Granita", image = BEAN_COFFEE_LOGO, content = "Une erreur est survenue lors de la finalisation." })
            break
        end
    end

    stopCraftingAnimation()
    TriggerServerCallback("bean_coffee:granita:releaseSlot", jobName, claimedSlot)

    if crafted > 0 then
        VFW.ShowNotification({ type = "JOB", title = "Bean Coffee", subtitle = "Granita", image = BEAN_COFFEE_LOGO, content = "Le granita est terminé ! (" .. crafted .. "/" .. quantity .. ")" })
    end

    isGraniting = false
end)

RegisterNUICallback("bean_coffee:granita:close", function(_, cb)
    closeGranita()
    cb({ ok = true })
end)
