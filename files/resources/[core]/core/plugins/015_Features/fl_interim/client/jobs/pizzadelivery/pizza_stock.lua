isCarryingPizza = false

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end

local function stopCarryingPizzaAnimation()
    local ped = PlayerPedId()

    for i = 0, GetNumberOfPedPropDrawables(ped, 0) do
        local obj = GetPedPropIndex(ped, i)
        if obj ~= -1 then
            ClearPedProp(ped, i)
        end
    end

    local count = 0
    for i = 0, 255 do
        local obj = GetClosestObjectOfType(GetEntityCoords(ped), 3.0, GetHashKey("prop_pizza_box_02"), false, false, false)
        if obj and obj ~= 0 and IsEntityAttachedToEntity(obj, ped) then
            DetachEntity(obj, true, true)
            DeleteObject(obj)
            DeleteEntity(obj)
            count = count + 1
            if count > 5 then break end
        else
            break
        end
    end

    ExecuteCommand("e c")
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

function StartCarryingPizza()
    local PlayerData = VFW.GetPlayerData()

    if isCarryingPizza then
        VFW.ShowNotification({ type = "ROUGE", content = "Vous transportez déjà une pizza." })
        return
    end

    local pickup = TriggerServerCallback("interim:pizza:canPickupPizza")
    if not pickup then return end

    isCarryingPizza = true
    ExecuteCommand("e c")
    EmoteCommandStart("carrypizza", PlayerPedId())
end

function StartCarryingPizzaFromTrunk()
    local PlayerData = VFW.GetPlayerData()

    if isCarryingPizza then
        VFW.ShowNotification({ type = "ROUGE", content = "Vous transportez déjà une pizza." })
        return
    end

    isCarryingPizza = true
    ExecuteCommand("e c")
    EmoteCommandStart("carrypizza", PlayerPedId())
end

function StopCarryingPizzaFromTrunk()
    local PlayerData = VFW.GetPlayerData()

    if not isCarryingPizza then return end
    isCarryingPizza = false
    ExecuteCommand("cancelemote")
end

function StopCarryingPizza(skipServer)
    local PlayerData = VFW.GetPlayerData()

    if not isCarryingPizza and not skipServer then
        return
    end

    if not skipServer then
        local droppizza = TriggerServerCallback("interim:pizza:canDropPizza")
        if not droppizza then return end
    end

    isCarryingPizza = false
    ExecuteCommand("cancelemote")
end

AddEventHandler("vfw:startko", function()
    if isCarryingPizza then
        StopCarryingPizza(true)
    end
end)
