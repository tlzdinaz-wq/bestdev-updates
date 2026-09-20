local craftingOpen = false
local isCrafting = false
local craftingJobName = nil
local milkshakeOpen = false
local isMilkshaking = false
local milkshakeJobName = nil
local NOODLE_LOGO = VFW.CDN.Get("entreprise/noodle.png")

local function getSortedCraftingSlots(jobName)
    local loc = NoodleConfig.Locations[jobName]
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

local function getSortedMilkshakeSlots(jobName)
    local loc = NoodleConfig.Locations[jobName]
    if not loc or not loc.MilkshakeStation then return {} end

    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local sorted = {}

    for slotName, slotData in pairs(loc.MilkshakeStation.slots) do
        table.insert(sorted, { name = slotName, dist = #(playerPos - slotData.pos) })
    end

    table.sort(sorted, function(a, b) return a.dist < b.dist end)
    return sorted
end

function Noodle_OpenCrafting(jobName)
    if craftingOpen or isCrafting then return end

    local slots = TriggerServerCallback("noodle:crafting:getData", jobName)
    if not slots then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Service", image = NOODLE_LOGO, content = "Vous devez être en service." })
        return
    end

    craftingOpen = true
    craftingJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "noodle:crafting:visible",
        data = true
    })

    SendNUIMessage({
        action = "noodle:crafting:data",
        data = {
            title = "NOODLE",
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
        action = "noodle:crafting:visible",
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
        action = "noodle:progress:start",
        data = {
            duration = duration,
            cycle = cycle,
            total = total
        }
    })
end

local function hideProgress()
    SendNUIMessage({
        action = "noodle:progress:hide",
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

RegisterNUICallback("noodle:crafting:craft", function(data, cb)
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

    local loc = NoodleConfig.Locations[jobName]
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
        local success, msg = TriggerServerCallback("noodle:crafting:claimSlot", jobName, slot.name)
        if success then
            claimedSlot = slot.name
            break
        end
        errMsg = msg
    end

    if not claimedSlot then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Préparation", image = NOODLE_LOGO, content = errMsg or "Tous les postes sont occupés." })
        isCrafting = false
        return
    end

    local slotData = loc.CraftingTable.slots[claimedSlot]
    local animCfg = NoodleConfig.SharedAnim.crafting
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
        local success, craftErrMsg, craftTime = TriggerServerCallback("noodle:crafting:craftOne", jobName, recipeId)

        if not success then
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Préparation", image = NOODLE_LOGO, content = craftErrMsg or "Une erreur est survenue lors de la fabrication." })
            break
        end

        local duration = (craftTime or 5) * 1000
        local completed = waitCraftProgress(duration, i, quantity, animCfg.dict, animCfg.name)

        if not completed then
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Préparation", image = NOODLE_LOGO, content = "La fabrication a été annulée." })
            break
        end

        local result = TriggerServerCallback("noodle:crafting:completeOne", jobName, recipeId)
        if result then
            crafted = crafted + 1
        else
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Préparation", image = NOODLE_LOGO, content = "Une erreur est survenue lors de la finalisation." })
            break
        end
    end

    stopCraftingAnimation()
    TriggerServerCallback("noodle:crafting:releaseSlot", jobName, claimedSlot)

    if crafted > 0 then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Préparation", image = NOODLE_LOGO, content = "La fabrication est terminée ! (" .. crafted .. "/" .. quantity .. ")" })
    end

    isCrafting = false
end)

RegisterNUICallback("noodle:crafting:close", function(_, cb)
    closeCrafting()
    cb({ ok = true })
end)

function Noodle_OpenMilkshake(jobName)
    if milkshakeOpen or isMilkshaking then return end

    local slots = TriggerServerCallback("noodle:milkshake:getData", jobName)
    if not slots then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Service", image = NOODLE_LOGO, content = "Vous devez être en service." })
        return
    end

    milkshakeOpen = true
    milkshakeJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "noodle:milkshake:visible",
        data = true
    })

    SendNUIMessage({
        action = "noodle:milkshake:data",
        data = {
            jobName = jobName,
            slots = slots
        }
    })
end

local function closeMilkshake()
    if not milkshakeOpen then return end
    milkshakeOpen = false
    milkshakeJobName = nil
    VFW.Nui.Focus(false, false)

    SendNUIMessage({
        action = "noodle:milkshake:visible",
        data = false
    })
end

RegisterNUICallback("noodle:milkshake:craft", function(data, cb)
    if not milkshakeOpen then
        cb({ ok = false })
        return
    end

    local recipeId = data.itemId
    local quantity = data.quantity or 1
    local jobName = data.jobName or milkshakeJobName

    closeMilkshake()
    cb({ ok = true })

    isMilkshaking = true

    local loc = NoodleConfig.Locations[jobName]
    if not loc or not loc.MilkshakeStation then
        isMilkshaking = false
        return
    end

    local sortedSlots = getSortedMilkshakeSlots(jobName)
    if #sortedSlots == 0 then
        isMilkshaking = false
        return
    end

    local claimedSlot = nil
    local errMsg
    for _, slot in ipairs(sortedSlots) do
        local success, msg = TriggerServerCallback("noodle:milkshake:claimSlot", jobName, slot.name)
        if success then
            claimedSlot = slot.name
            break
        end
        errMsg = msg
    end

    if not claimedSlot then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Milkshake", image = NOODLE_LOGO, content = errMsg or "Tous les postes sont occupés." })
        isMilkshaking = false
        return
    end

    local slotData = loc.MilkshakeStation.slots[claimedSlot]
    local animCfg = NoodleConfig.SharedAnim.milkshake
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
        local success, craftErrMsg, craftTime = TriggerServerCallback("noodle:milkshake:craftOne", jobName, recipeId)

        if not success then
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Milkshake", image = NOODLE_LOGO, content = craftErrMsg or "Une erreur est survenue lors de la préparation." })
            break
        end

        local duration = (craftTime or 4) * 1000
        local completed = waitCraftProgress(duration, i, quantity, animCfg.dict, animCfg.name)

        if not completed then
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Milkshake", image = NOODLE_LOGO, content = "La préparation a été annulée." })
            break
        end

        local result = TriggerServerCallback("noodle:milkshake:completeOne", jobName, recipeId)
        if result then
            crafted = crafted + 1
        else
            VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Milkshake", image = NOODLE_LOGO, content = "Une erreur est survenue lors de la finalisation." })
            break
        end
    end

    stopCraftingAnimation()
    TriggerServerCallback("noodle:milkshake:releaseSlot", jobName, claimedSlot)

    if crafted > 0 then
        VFW.ShowNotification({ type = "JOB", title = "Noodle", subtitle = "Milkshake", image = NOODLE_LOGO, content = "Le milkshake est terminé ! (" .. crafted .. "/" .. quantity .. ")" })
    end

    isMilkshaking = false
end)

RegisterNUICallback("noodle:milkshake:close", function(_, cb)
    closeMilkshake()
    cb({ ok = true })
end)
