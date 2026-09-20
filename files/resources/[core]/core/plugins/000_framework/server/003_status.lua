local function clamp(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 100 then return 100 end
    return value
end

RegisterNetEvent("vfw:status:update", function(thirst, hunger)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(thirst) ~= "number" or type(hunger) ~= "number" then return end

    local currentThirst = clamp(xPlayer.metadata.thirst == nil and 100 or xPlayer.metadata.thirst)
    local currentHunger = clamp(xPlayer.metadata.hunger == nil and 100 or xPlayer.metadata.hunger)

    thirst = clamp(thirst)
    hunger = clamp(hunger)

    if thirst > currentThirst then thirst = currentThirst end
    if hunger > currentHunger then hunger = currentHunger end

    xPlayer.metadata.thirst = thirst
    xPlayer.metadata.hunger = hunger
end)

function VFW.SetStatus(source, hunger, thirst)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if hunger ~= nil then xPlayer.metadata.hunger = clamp(hunger) end
    if thirst ~= nil then xPlayer.metadata.thirst = clamp(thirst) end

    TriggerClientEvent("vfw:status:forceUpdate", source, xPlayer.metadata.thirst, xPlayer.metadata.hunger)
end

function VFW.AddStatus(source, hunger, thirst)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    VFW.SetStatus(source,
        (xPlayer.metadata.hunger or 100) + (hunger or 0),
        (xPlayer.metadata.thirst or 100) + (thirst or 0)
    )
end

function VFW.ConsumeItem(source, itemName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local def = VFW.Items[itemName]
    if not def then return false end

    if not xPlayer.removeInventoryItem(itemName, 1) then return false end

    local data = def.data or {}
    VFW.AddStatus(source, data.hunger or 0, data.thirst or 0)

    TriggerClientEvent("vfw:eat", source, itemName)
    return true
end

RegisterNetEvent("vfw:newanim:sync", function(emote)
    local source = source
    if type(emote) ~= "string" then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local nearby = VFW.GetPlayersInRadius(xPlayer.getCoords(), 25.0)
    for i = 1, #nearby do
        if nearby[i].source ~= source then
            TriggerClientEvent("vfw:newanim:play", nearby[i].source, source, emote)
        end
    end

    TriggerEvent("vfw:newanim:synced", source, emote)
end)

RegisterNetEvent("vfw:animation:syncWalk", function(walk)
    local source = source
    if walk ~= nil and (type(walk) ~= "string" or #walk > 64) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.setMeta("walkstyle", walk)
    Player(source).state:set("walkstyle", walk, true)
end)

CreateThread(function()
    while true do
        Wait(60000)
        for source, xPlayer in pairs(VFW.Players) do
            local stats = {
                health = GetEntityHealth(GetPlayerPed(source)),
                armor = xPlayer.metadata.armor or 0,
                hunger = xPlayer.metadata.hunger or 100,
                thirst = xPlayer.metadata.thirst or 100,
                stamina = 100,
            }
            TriggerClientEvent("statushud:updateStats", source, stats)
        end
    end
end)

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    TriggerClientEvent("statushud:updatePlayerInfo", source, {
        id = tonumber(source) or 0,
        firstName = xPlayer.firstName,
        lastName = xPlayer.lastName,
        age = xPlayer.dateofbirth,
    })
end)
