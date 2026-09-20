local Harvest = {
    staticSpots = {},
    dynamicSpots = {},
    transformSpots = {},
    staticSessions = {},
    dynamicBusy = {},
    transformBusy = {},
    spotCooldown = {},
}

local BUILDER_PERM = "illegal_activities_builder"
local SPOT_RANGE = 6.0
local TRANSFORM_TIMEOUT = 120

local function LoadStaticSpots()
    Harvest.staticSpots = {}
    local rows = IL.Query("SELECT * FROM illegal_static_harvest_spots")
    for i = 1, #rows do
        local row = rows[i]
        Harvest.staticSpots[row.id] = {
            id = row.id,
            name = row.name or "Recolte",
            coords = IL.Decode(row.coords, {}),
            item_output = row.item_output,
            output_quantity = IL.Int(row.output_quantity, 1),
            harvest_time = IL.Int(row.harvest_time, 5000),
            animation_type = row.animation_type or "standing",
            blip_enabled = IL.Bool(row.blip_enabled),
            blip_sprite = IL.Int(row.blip_sprite, 1),
            blip_color = IL.Int(row.blip_color, 1),
            blip_scale = IL.Num(row.blip_scale, 0.5),
            blip_label = row.blip_label or row.name,
            faction_restriction = row.faction_restriction or "",
            faction_grade_min = IL.Int(row.faction_grade_min, 0),
            interaction = {
                key = IL.Int(row.interaction_key, 38),
                text = row.interaction_text or "Appuyez pour recolter",
                circleColor = { r = 139, g = 0, b = 0, a = 150 },
            },
        }
    end
end

local function LoadDynamicSpots()
    Harvest.dynamicSpots = {}
    local rows = IL.Query("SELECT * FROM illegal_harvest_spots")
    for i = 1, #rows do
        local row = rows[i]
        Harvest.dynamicSpots[row.id] = {
            id = row.id,
            name = row.name or "Recolte",
            coords_x = IL.Num(row.coords_x, 0.0),
            coords_y = IL.Num(row.coords_y, 0.0),
            coords_z = IL.Num(row.coords_z, 0.0),
            rotation_z = IL.Num(row.rotation_z, 0.0),
            marker_x = row.marker_x, marker_y = row.marker_y, marker_z = row.marker_z,
            prop_model = row.prop_model,
            item_output = row.item_output,
            output_quantity = IL.Int(row.output_quantity, 1),
            harvest_time = IL.Int(row.harvest_time, 5000),
            cooldown_seconds = IL.Int(row.cooldown_seconds, 0),
            animation_type = row.animation_type or "predefined",
            animation_dict = row.animation_dict,
            animation_name = row.animation_name,
            animation_preset = row.animation_preset,
            animation_prop = row.animation_prop,
            blip_enabled = IL.Bool(row.blip_enabled),
            blip_sprite = IL.Int(row.blip_sprite, 1),
            blip_color = IL.Int(row.blip_color, 1),
            blip_scale = IL.Num(row.blip_scale, 0.5),
            blip_label = row.blip_label or row.name,
            faction_restriction = row.faction_restriction or "",
            faction_grade_min = IL.Int(row.faction_grade_min, 0),
        }
    end
end

local function LoadTransformSpots()
    Harvest.transformSpots = {}
    local rows = IL.Query("SELECT * FROM illegal_transform_spots")
    for i = 1, #rows do
        local row = rows[i]
        Harvest.transformSpots[row.id] = {
            id = row.id,
            name = row.name or "Transformation",
            coords_x = IL.Num(row.coords_x, 0.0),
            coords_y = IL.Num(row.coords_y, 0.0),
            coords_z = IL.Num(row.coords_z, 0.0),
            rotation_z = IL.Num(row.rotation_z, 0.0),
            marker_x = row.marker_x, marker_y = row.marker_y, marker_z = row.marker_z,
            prop_model = row.prop_model,
            input_item = row.input_item,
            input_quantity = IL.Int(row.input_quantity, 1),
            output_item = row.output_item,
            output_quantity = IL.Int(row.output_quantity, 1),
            transform_time = IL.Int(row.transform_time, 5000),
            cooldown_seconds = IL.Int(row.cooldown_seconds, 0),
            animation_type = row.animation_type or "predefined",
            animation_dict = row.animation_dict,
            animation_name = row.animation_name,
            animation_preset = row.animation_preset,
            animation_prop = row.animation_prop,
            blip_enabled = IL.Bool(row.blip_enabled),
            blip_sprite = IL.Int(row.blip_sprite, 1),
            blip_color = IL.Int(row.blip_color, 1),
            blip_scale = IL.Num(row.blip_scale, 0.5),
            blip_label = row.blip_label or row.name,
            faction_restriction = row.faction_restriction or "",
            faction_grade_min = IL.Int(row.faction_grade_min, 0),
        }
    end
end

local function DynamicSpotArray()
    local out = {}
    for _, spot in pairs(Harvest.dynamicSpots) do
        out[#out + 1] = spot
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function TransformSpotArray()
    local out = {}
    for _, spot in pairs(Harvest.transformSpots) do
        out[#out + 1] = spot
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function CooldownKey(kind, spotId)
    return kind .. ":" .. tostring(spotId)
end

local function OnCooldown(kind, spotId, seconds)
    if not seconds or seconds <= 0 then return false, 0 end
    local key = CooldownKey(kind, spotId)
    local last = Harvest.spotCooldown[key]
    if not last then return false, 0 end
    local remaining = seconds - (IL.Now() - last)
    if remaining <= 0 then return false, 0 end
    return true, remaining
end

local function SetCooldown(kind, spotId)
    Harvest.spotCooldown[CooldownKey(kind, spotId)] = IL.Now()
end

local function TooEarly(startedAt, durationMs)
    local required = math.floor(IL.Int(durationMs, 0) / 1000) - 1
    if required <= 0 then return false end
    return (IL.Now() - startedAt) < required
end

IL.OnReady(function()
    LoadStaticSpots()
    LoadDynamicSpots()
    LoadTransformSpots()
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("illegalBuilder:syncHarvestSpots", source, DynamicSpotArray())
    TriggerClientEvent("illegalBuilder:syncTransformSpots", source, TransformSpotArray())
    TriggerClientEvent("illegalHarvesting:refreshSpots", source, Harvest.staticSpots)
end)

IL.OnPlayerDropped(function(source)
    Harvest.staticSessions[source] = nil
    for spotId, holder in pairs(Harvest.dynamicBusy) do
        if holder.source == source then Harvest.dynamicBusy[spotId] = nil end
    end
    for spotId, holder in pairs(Harvest.transformBusy) do
        if holder.source == source then Harvest.transformBusy[spotId] = nil end
    end
end)

AddEventHandler("illegal:internal:syncHarvestSpots", function(target)
    TriggerClientEvent("illegalBuilder:syncHarvestSpots", target or -1, DynamicSpotArray())
end)

AddEventHandler("illegal:internal:syncTransformSpots", function(target)
    TriggerClientEvent("illegalBuilder:syncTransformSpots", target or -1, TransformSpotArray())
end)

CreateThread(function()
    while true do
        Wait(15000)
        local now = IL.Now()
        for spotId, holder in pairs(Harvest.transformBusy) do
            if now - holder.startedAt > TRANSFORM_TIMEOUT then
                Harvest.transformBusy[spotId] = nil
            end
        end
        for spotId, holder in pairs(Harvest.dynamicBusy) do
            if now - holder.startedAt > TRANSFORM_TIMEOUT then
                Harvest.dynamicBusy[spotId] = nil
            end
        end
        for source, session in pairs(Harvest.staticSessions) do
            if now - session.startedAt > TRANSFORM_TIMEOUT then
                Harvest.staticSessions[source] = nil
            end
        end
    end
end)

IL.RegisterCallback("illegalHarvesting:getSpots", function(source)
    local xPlayer = IL.Player(source)
    local out = {}
    for id, spot in pairs(Harvest.staticSpots) do
        if IL.HasFactionAccess(xPlayer, spot.faction_restriction, spot.faction_grade_min) then
            out[id] = spot
        end
    end
    return out
end)

RegisterNetEvent("illegalHarvesting:startHarvest", function(spotId, coordIndex)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(spotId, nil)
    coordIndex = IL.Int(coordIndex, 1)
    if not id then return end

    local spot = Harvest.staticSpots[id]
    if not spot then return end

    if not IL.HasFactionAccess(xPlayer, spot.faction_restriction, spot.faction_grade_min) then
        TriggerClientEvent("illegalHarvesting:notify", source, "ROUGE", "Acces refuse")
        return
    end

    if Harvest.staticSessions[source] then
        TriggerClientEvent("illegalHarvesting:notify", source, "ROUGE", "Recolte deja en cours")
        return
    end

    local coordsList = spot.coords
    local target = nil
    if IL.IsTable(coordsList) then
        if coordsList.x then
            target = coordsList
        else
            target = coordsList[coordIndex] or coordsList[1]
        end
    end
    if target then
        if IL.DistanceTo(source, IL.Num(target.x, 0.0), IL.Num(target.y, 0.0), IL.Num(target.z, 0.0)) > SPOT_RANGE then
            TriggerClientEvent("illegalHarvesting:notify", source, "ROUGE", "Vous etes trop loin")
            return
        end
    end

    if not xPlayer.canCarryItem(spot.item_output, spot.output_quantity) then
        TriggerClientEvent("illegalHarvesting:notify", source, "ROUGE", "Votre inventaire est plein")
        return
    end

    Harvest.staticSessions[source] = {
        spotId = id,
        coordIndex = coordIndex,
        startedAt = IL.Now(),
    }

    TriggerClientEvent("illegalHarvesting:startHarvestProgress", source, {
        harvestTime = spot.harvest_time,
        animationType = spot.animation_type,
        spotId = id,
        coordIndex = coordIndex,
    })

    local token = Harvest.staticSessions[source]
    SetTimeout(spot.harvest_time + 250, function()
        local current = Harvest.staticSessions[source]
        if current ~= token then return end
        Harvest.staticSessions[source] = nil

        local player = IL.Player(source)
        if not player then return end

        if IL.GiveItem(player, spot.item_output, spot.output_quantity, true) then
            TriggerClientEvent("illegalHarvesting:harvestComplete", source)
        else
            TriggerClientEvent("illegalHarvesting:cancelHarvest", source)
            TriggerClientEvent("illegalHarvesting:notify", source, "ROUGE", "Votre inventaire est plein")
        end
    end)
end)

RegisterNetEvent("illegalHarvesting:cancelHarvest", function()
    local source = source
    if not Harvest.staticSessions[source] then return end
    Harvest.staticSessions[source] = nil
    TriggerClientEvent("illegalHarvesting:cancelHarvest", source)
end)

IL.RegisterCallback("illegalBuilder:getHarvestSpots", function(source)
    return DynamicSpotArray()
end)

IL.RegisterCallback("illegalBuilder:canHarvest", function(source, spotId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local id = IL.Int(spotId, nil)
    local spot = id and Harvest.dynamicSpots[id] or nil
    if not spot then return { success = false, message = "Spot introuvable" } end

    if not IL.HasFactionAccess(xPlayer, spot.faction_restriction, spot.faction_grade_min) then
        return { success = false, message = "Acces refuse" }
    end

    local busy = Harvest.dynamicBusy[id]
    if busy and busy.source ~= source and (IL.Now() - busy.startedAt) < 60 then
        return { success = false, message = "Spot deja occupe" }
    end

    local onCd, remaining = OnCooldown("harvest", id, spot.cooldown_seconds)
    if onCd then
        return { success = false, message = ("Disponible dans %ds"):format(math.ceil(remaining)) }
    end

    if IL.DistanceTo(source, spot.coords_x, spot.coords_y, spot.coords_z) > SPOT_RANGE then
        return { success = false, message = "Vous etes trop loin" }
    end

    if not xPlayer.canCarryItem(spot.item_output, spot.output_quantity) then
        return { success = false, message = "Votre inventaire est plein" }
    end

    Harvest.dynamicBusy[id] = { source = source, startedAt = IL.Now() }
    return { success = true }
end)

RegisterNetEvent("illegalBuilder:completeHarvest", function(spotId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(spotId, nil)
    local spot = id and Harvest.dynamicSpots[id] or nil
    if not spot then return end

    local busy = Harvest.dynamicBusy[id]
    if not busy or busy.source ~= source then return end
    if TooEarly(busy.startedAt, spot.harvest_time) then return end
    Harvest.dynamicBusy[id] = nil

    if IL.DistanceTo(source, spot.coords_x, spot.coords_y, spot.coords_z) > SPOT_RANGE then return end

    SetCooldown("harvest", id)

    if IL.GiveItem(xPlayer, spot.item_output, spot.output_quantity, true) then
        TriggerClientEvent("illegalBuilder:harvestComplete", source, id, spot.item_output, spot.output_quantity)
    else
        IL.Notify(source, "ROUGE", "Votre inventaire est plein.")
    end
end)

RegisterNetEvent("illegalBuilder:stopHarvesting", function(spotId)
    local source = source
    local id = IL.Int(spotId, nil)
    if not id then return end
    local busy = Harvest.dynamicBusy[id]
    if busy and busy.source == source then
        Harvest.dynamicBusy[id] = nil
    end
end)

IL.RegisterCallback("illegalBuilder:getTransformSpots", function(source)
    return TransformSpotArray()
end)

IL.RegisterCallback("illegalBuilder:canTransform", function(source, spotId)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local id = IL.Int(spotId, nil)
    local spot = id and Harvest.transformSpots[id] or nil
    if not spot then return { success = false, message = "Spot introuvable" } end

    if not IL.HasFactionAccess(xPlayer, spot.faction_restriction, spot.faction_grade_min) then
        return { success = false, message = "Acces refuse" }
    end

    local busy = Harvest.transformBusy[id]
    if busy and busy.source ~= source and (IL.Now() - busy.startedAt) < 60 then
        return { success = false, message = "Poste deja occupe" }
    end

    local onCd, remaining = OnCooldown("transform", id, spot.cooldown_seconds)
    if onCd then
        return { success = false, message = ("Disponible dans %ds"):format(math.ceil(remaining)) }
    end

    if IL.DistanceTo(source, spot.coords_x, spot.coords_y, spot.coords_z) > SPOT_RANGE then
        return { success = false, message = "Vous etes trop loin" }
    end

    if spot.input_item ~= "" and not xPlayer.haveItem(spot.input_item, spot.input_quantity) then
        return { success = false, message = ("Il vous faut %dx %s"):format(spot.input_quantity, IL.ItemLabel(spot.input_item)) }
    end

    if not xPlayer.canCarryItem(spot.output_item, spot.output_quantity) then
        return { success = false, message = "Votre inventaire est plein" }
    end

    Harvest.transformBusy[id] = { source = source, startedAt = IL.Now() }
    return { success = true }
end)

RegisterNetEvent("illegalBuilder:completeTransform", function(spotId)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local id = IL.Int(spotId, nil)
    local spot = id and Harvest.transformSpots[id] or nil
    if not spot then return end

    local busy = Harvest.transformBusy[id]
    if not busy or busy.source ~= source then return end
    if TooEarly(busy.startedAt, spot.transform_time) then return end
    Harvest.transformBusy[id] = nil

    if IL.DistanceTo(source, spot.coords_x, spot.coords_y, spot.coords_z) > SPOT_RANGE then return end

    if spot.input_item ~= "" then
        if not IL.TakeItem(xPlayer, spot.input_item, spot.input_quantity) then
            TriggerClientEvent("illegalBuilder:transformFailed", source, "Ingredients manquants")
            return
        end
    end

    SetCooldown("transform", id)

    if IL.GiveItem(xPlayer, spot.output_item, spot.output_quantity, true) then
        TriggerClientEvent("illegalBuilder:transformComplete", source, id, spot.output_item, spot.output_quantity)
    else
        TriggerClientEvent("illegalBuilder:transformFailed", source, "Inventaire plein")
    end
end)

AddEventHandler("illegal:internal:reloadSpots", function()
    LoadStaticSpots()
    LoadDynamicSpots()
    LoadTransformSpots()
    TriggerClientEvent("illegalBuilder:refreshHarvestSpots", -1, DynamicSpotArray())
    TriggerClientEvent("illegalBuilder:refreshTransformSpots", -1, TransformSpotArray())
    TriggerClientEvent("illegalHarvesting:refreshSpots", -1, Harvest.staticSpots)
    TriggerClientEvent("illegalBuilder:syncHarvestSpots", -1, DynamicSpotArray())
    TriggerClientEvent("illegalBuilder:syncTransformSpots", -1, TransformSpotArray())
end)

RegisterNetEvent("illegalBuilder:reloadSpots", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    TriggerEvent("illegal:internal:reloadSpots")
end)
