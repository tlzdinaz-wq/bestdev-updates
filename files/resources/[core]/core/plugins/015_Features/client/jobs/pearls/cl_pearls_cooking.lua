local isCooking = false
local cookingOpen = false
local cookingProp = nil
local cookingJobName = nil
local PEARLS_LOGO = VFW.CDN.Get("entreprise/pearl.png")

local function attachProp(ped, animCfg)
    if not animCfg.prop then return nil end

    local propHash = GetHashKey(animCfg.prop.model)
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(10)
    end

    local obj = CreateObject(propHash, 0.0, 0.0, 0.0, false, true, false)
    local p = animCfg.prop.placement
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, animCfg.prop.bone),
        p[1], p[2], p[3], p[4], p[5], p[6],
        true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(propHash)
    return obj
end

local function deleteProp()
    if cookingProp and DoesEntityExist(cookingProp) then
        DeleteEntity(cookingProp)
    end
    cookingProp = nil
end

local function getStationConfig(stationType, jobName)
    local loc = PearlsConfig.Locations[jobName]
    if not loc then return nil end
    if stationType == "grill" then
        return loc.GrillStation
    elseif stationType == "fryer" then
        return loc.FryerStation
    end
    return nil
end

local function getSortedSlots(stationCfg)
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local slots = {}

    for slotName, slotData in pairs(stationCfg.slots) do
        table.insert(slots, { name = slotName, dist = #(playerPos - slotData.pos) })
    end

    table.sort(slots, function(a, b) return a.dist < b.dist end)
    return slots
end

local function closeCookingMenu()
    if not cookingOpen then return end
    cookingOpen = false
    cookingJobName = nil
    VFW.Nui.Focus(false, false)
    SendNUIMessage({ action = "pearls:cooking:visible", data = false })
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

local function waitCookProgress(duration, cycle, total, animDict, animName)
    local startTime = GetGameTimer()
    local ped = PlayerPedId()

    showProgress(duration, cycle, total)

    while true do
        Citizen.Wait(0)

        if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
            TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end

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

local function startCookingLoop(stationType, jobName, inputItem, outputItem, quantity)
    local stationCfg = getStationConfig(stationType, jobName)
    if not stationCfg then return end

    local animCfg = PearlsConfig.SharedAnim[stationType]
    if not animCfg then return end

    local sortedSlots = getSortedSlots(stationCfg)
    if #sortedSlots == 0 then return end

    local slotName = nil
    local success, errMsg

    for _, slot in ipairs(sortedSlots) do
        success, errMsg = TriggerServerCallback("pearls:cooking:claimSlot", jobName, stationType, slot.name, inputItem)
        if success then
            slotName = slot.name
            break
        end
    end

    if not slotName then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Cuisine", image = PEARLS_LOGO, content = errMsg or "Tous les postes sont occupés." })
        return
    end

    isCooking = true
    local ped = PlayerPedId()
    local slotData = stationCfg.slots[slotName]

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, slotData.pos.x, slotData.pos.y, GetEntityCoords(ped).z - 1.0, false, false, false, false)
    Wait(200)
    SetEntityHeading(ped, slotData.heading)

    RequestAnimDict(animCfg.dict)
    while not HasAnimDictLoaded(animCfg.dict) do
        Wait(10)
    end

    cookingProp = attachProp(ped, animCfg)
    TaskPlayAnim(ped, animCfg.dict, animCfg.name, 8.0, -8.0, -1, 1, 0, false, false, false)

    local cooked = 0

    for i = 1, quantity do
        local claimOk = TriggerServerCallback("pearls:cooking:cookOne", jobName, stationType, slotName, inputItem)
        if not claimOk then
            if cooked == 0 then
                VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Cuisine", image = PEARLS_LOGO, content = "Il vous manque l'ingrédient nécessaire." })
            end
            break
        end

        local completed = waitCookProgress(stationCfg.duration, i, quantity, animCfg.dict, animCfg.name)

        if not completed then
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Cuisine", image = PEARLS_LOGO, content = "La cuisson a été annulée." })
            break
        end

        local result = TriggerServerCallback("pearls:cooking:completeOne", jobName, stationType, slotName, inputItem, outputItem)
        if result then
            cooked = cooked + 1
        else
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Cuisine", image = PEARLS_LOGO, content = "Une erreur est survenue lors de la cuisson." })
            break
        end
    end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    deleteProp()

    TriggerServerCallback("pearls:cooking:cancel", jobName, stationType, slotName)

    if cooked > 0 then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Cuisine", image = PEARLS_LOGO, content = "La cuisson est terminée ! (" .. cooked .. "/" .. quantity .. ")" })
    end

    isCooking = false
end

function Pearls_StartCooking(stationType, jobName)
    if isCooking or cookingOpen then return end

    local recipes = TriggerServerCallback("pearls:cooking:getRecipes", jobName, stationType)
    if not recipes then
        VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Service", image = PEARLS_LOGO, content = "Vous devez être en service." })
        return
    end

    if #recipes == 1 then
        local recipe = recipes[1]
        if not recipe.hasInput or recipe.playerHas < 1 then
            VFW.ShowNotification({ type = "JOB", title = "Pearls", subtitle = "Cuisine", image = PEARLS_LOGO, content = "Vous ne possédez pas l'ingrédient nécessaire." })
            return
        end
        startCookingLoop(stationType, jobName, recipe.input, recipe.output, recipe.playerHas)
        return
    end

    cookingOpen = true
    cookingJobName = jobName
    VFW.Nui.Focus(true, false)

    SendNUIMessage({ action = "pearls:cooking:visible", data = true })
    SendNUIMessage({
        action = "pearls:cooking:data",
        data = {
            stationType = stationType,
            jobName = jobName,
            recipes = recipes
        }
    })
end

RegisterNUICallback("pearls:cooking:select", function(data, cb)
    if not cookingOpen then
        cb({ ok = false })
        return
    end

    local jobName = data.jobName or cookingJobName
    closeCookingMenu()
    cb({ ok = true })

    startCookingLoop(data.stationType, jobName, data.input, data.output, data.quantity or 1)
end)

RegisterNUICallback("pearls:cooking:close", function(_, cb)
    closeCookingMenu()
    cb({ ok = true })
end)

RegisterNetEvent("pearls:cooking:slotUpdate", function(stationType, slotName, occupied)
end)
