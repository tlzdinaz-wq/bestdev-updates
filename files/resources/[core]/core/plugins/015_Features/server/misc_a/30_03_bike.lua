local BIKE_MODELS = {
    ["cruiser"] = true,
    ["bmx"] = true,
    ["fixter"] = true,
    ["scorcher"] = true,
    ["tribike"] = true,
    ["tribike2"] = true,
    ["tribike3"] = true,
}

local FALLBACK_BIKE_ITEM = "bmx"

local function bikeItemFor(model)
    if Misc30.ItemExists(model) then return model end
    if Misc30.ItemExists("velo_" .. model) then return "velo_" .. model end
    if Misc30.ItemExists(FALLBACK_BIKE_ITEM) then return FALLBACK_BIKE_ITEM end
    return nil
end

CreateThread(function()
    Wait(4000)
    for model in pairs(BIKE_MODELS) do
        local itemName = model
        if Misc30.ItemExists(itemName) then
            Misc30.UsableItem(itemName, function(xPlayer, entry)
                if not xPlayer then return end
                if entry and entry.name ~= itemName then return end
                local inv = Misc30.Inv()
                if inv and entry then
                    if not inv.RemoveFromSlot(inv.PlayerList(xPlayer), entry.slot, 1) then return end
                    inv.PushPlayer(xPlayer)
                end
                TriggerClientEvent("core:client:UseBike", xPlayer.source, itemName)
            end)
        end
    end
end)

RegisterNetEvent("core:server:pickupBike", function(bikeModel, netId)
    local source = source

    if not Misc30.IsString(bikeModel, 32) then return end

    local model = bikeModel:lower()
    if not BIKE_MODELS[model] then return end

    local id = Misc30.ToInt(netId, 1)
    if not id then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if not Misc30.RateLimit(source, "pickupBike", 1500) then return end

    local entity = Misc30.EntityFromNet(id)
    if not entity then return end

    if GetEntityType(entity) ~= 2 then return end
    if GetEntityModel(entity) ~= joaat(model) then return end

    local playerCoords = Misc30.PlayerCoords(source)
    if not playerCoords then return end
    if #(playerCoords - GetEntityCoords(entity)) > 6.0 then return end

    for seat = -1, 3 do
        local occupant = GetPedInVehicleSeat(entity, seat)
        if occupant and occupant ~= 0 then return end
    end

    local itemName = bikeItemFor(model)
    if not itemName then
        Misc30.Notify(source, "ROUGE", "Ce velo ne peut pas etre range.")
        return
    end

    local inv = Misc30.Inv()
    if inv and inv.CanCarry and not inv.CanCarry(xPlayer, itemName, 1) then
        Misc30.Notify(source, "ROUGE", "Vous ne pouvez pas porter ce velo.")
        return
    end

    DeleteEntity(entity)

    if not Misc30.GiveItem(xPlayer, itemName, 1) then
        Misc30.Notify(source, "ROUGE", "Impossible de ranger le velo.")
        return
    end

    Misc30.Notify(source, "VERT", "Vous avez range le velo.")
end)
