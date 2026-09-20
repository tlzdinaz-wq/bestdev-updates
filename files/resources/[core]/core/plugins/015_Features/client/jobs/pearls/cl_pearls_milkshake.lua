local milkshakeOpen = false
local isMilkshaking = false
local milkshakeJobName = nil
local PEARLS_LOGO = VFW.CDN.Get("entreprise/pearl.png")

local function getSortedMilkshakeSlots(jobName)
    local loc = PearlsConfig.Locations[jobName]
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

local function stopAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
end

local function showProgress(duration, cycle, total)
    SendNUIMessage({
        action = "pearls:progress:start",
        data = { duration = duration, cycle = cycle, total = total }
    })
end

local function hideProgress()
    SendNUIMessage({ action = "pearls:progress:hide", data = {} })
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

function Pearls_OpenMilkshake(jobName)
    if milkshakeOpen or isMilkshaking then return end

    local slots = TriggerServerCallback("pearls:milkshake:getData", jobName)
    if not slots then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Service", image = PEARLS_LOGO, content = "Vous devez être en service." })
        return
    end

    milkshakeOpen = true
    milkshakeJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({
        action = "pearls:milkshake:visible",
        data = true
    })

    SendNUIMessage({
        action = "pearls:milkshake:data",
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
        action = "pearls:milkshake:visible",
        data = false
    })
end

RegisterNUICallback("pearls:milkshake:craft", function(data, cb)
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

    local loc = PearlsConfig.Locations[jobName]
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
        local success, msg = TriggerServerCallback("pearls:milkshake:claimSlot", jobName, slot.name)
        if success then
            claimedSlot = slot.name
            break
        end
        errMsg = msg
    end

    if not claimedSlot then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Milkshake", image = PEARLS_LOGO, content = errMsg or "Tous les postes sont occupés." })
        isMilkshaking = false
        return
    end

    local slotData = loc.MilkshakeStation.slots[claimedSlot]
    local animCfg = PearlsConfig.SharedAnim.milkshake
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
        local success, craftErrMsg, craftTime = TriggerServerCallback("pearls:milkshake:craftOne", jobName, recipeId)

        if not success then
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Milkshake", image = PEARLS_LOGO, content = craftErrMsg or "Une erreur est survenue lors de la préparation." })
            break
        end

        local duration = (craftTime or 4) * 1000
        local completed = waitCraftProgress(duration, i, quantity, animCfg.dict, animCfg.name)

        if not completed then
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Milkshake", image = PEARLS_LOGO, content = "La préparation a été annulée." })
            break
        end

        local result = TriggerServerCallback("pearls:milkshake:completeOne", jobName, recipeId)
        if result then
            crafted = crafted + 1
        else
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Milkshake", image = PEARLS_LOGO, content = "Une erreur est survenue lors de la finalisation." })
            break
        end
    end

    stopAnimation()
    TriggerServerCallback("pearls:milkshake:releaseSlot", jobName, claimedSlot)

    if crafted > 0 then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Milkshake", image = PEARLS_LOGO, content = "Le milkshake est terminé ! (" .. crafted .. "/" .. quantity .. ")" })
    end

    isMilkshaking = false
end)

RegisterNUICallback("pearls:milkshake:close", function(_, cb)
    closeMilkshake()
    cb({ ok = true })
end)
