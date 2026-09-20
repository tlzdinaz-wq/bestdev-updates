local LB = {}

function LB.Num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

function LB.Int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

function LB.Str(value, fallback)
    if type(value) == "string" then return value end
    return fallback
end

function LB.IsTable(value)
    return type(value) == "table"
end

function LB.Bool(value)
    if value == nil then return false end
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    if type(value) == "string" then return value == "1" or value == "true" end
    return false
end

function LB.Now()
    return os.time()
end

function LB.Clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function LB.Decode(value, fallback)
    if value == nil then return fallback end
    if type(value) == "table" then return value end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

function LB.Encode(value)
    return json.encode(value)
end

function LB.Query(query, params)
    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return {}
    end
    return result or {}
end

function LB.Single(query, params)
    local ok, result = pcall(function()
        return MySQL.single.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Scalar(query, params)
    local ok, result = pcall(function()
        return MySQL.scalar.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Insert(query, params)
    local ok, result = pcall(function()
        return MySQL.insert.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return nil
    end
    return result
end

function LB.Execute(query, params)
    local ok, result = pcall(function()
        return MySQL.update.await(query, params or {})
    end)
    if not ok then
        console.warn(("[illegal] SQL error: %s"):format(tostring(result)))
        return 0
    end
    return result or 0
end

function LB.Player(source)
    if not VFW or not VFW.GetPlayerFromId then return nil end
    return VFW.GetPlayerFromId(source)
end

function LB.Coords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function LB.DistanceTo(source, x, y, z)
    local coords = LB.Coords(source)
    if not coords then return 9999.0 end
    local dx, dy, dz = coords.x - (x or 0.0), coords.y - (y or 0.0), coords.z - (z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function LB.Notify(source, kind, message)
    if not source or not message then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = kind or "ILLEGAL",
        message = message,
        content = message,
    })
end

function LB.ItemLabel(itemName)
    if VFW and VFW.Items and VFW.Items[itemName] and VFW.Items[itemName].label then
        return VFW.Items[itemName].label
    end
    return itemName
end

function LB.ItemExists(itemName)
    return VFW ~= nil and VFW.Items ~= nil and VFW.Items[itemName] ~= nil
end

function LB.GiveItem(xPlayer, itemName, count, notify)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not LB.ItemExists(itemName) then return false end
    if not xPlayer.canCarryItem(itemName, count) then return false end
    return xPlayer.addInventoryItem(itemName, count, nil, notify ~= false)
end

function LB.TakeItem(xPlayer, itemName, count)
    if not xPlayer or type(itemName) ~= "string" then return false end
    count = math.floor(tonumber(count) or 1)
    if count <= 0 then return false end
    if not xPlayer.haveItem(itemName, count) then return false end
    return xPlayer.removeInventoryItem(itemName, count, nil, true)
end

function LB.AccountMoney(xPlayer, account)
    if not xPlayer then return 0 end
    local acc = xPlayer.getAccount(account)
    return acc and acc.money or 0
end

function LB.GiveMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    xPlayer.addAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function LB.TakeMoney(xPlayer, account, amount, reason)
    if not xPlayer or not amount or amount <= 0 then return false end
    local acc = xPlayer.getAccount(account)
    if not acc or acc.money < amount then return false end
    xPlayer.removeAccountMoney(account, math.floor(amount), reason or "illegal")
    return true
end

function LB.RegisterCallback(name, fn)
    if type(name) ~= "string" or type(fn) ~= "function" then return false end
    local ok, err = pcall(RegisterServerCallback, name, fn)
    if not ok then
        console.warn(("[illegal] impossible d'enregistrer le callback '%s': %s"):format(name, tostring(err)))
        return false
    end
    return true
end

function LB.OnReady(fn)
    if type(fn) ~= "function" then return end
    CreateThread(function()
        local attempts = 0
        while not (VFW and VFW.Ready) and attempts < 200 do
            Wait(250)
            attempts = attempts + 1
        end
        Wait(800)
        local ok, err = pcall(fn)
        if not ok then
            console.warn(("[illegal] erreur d'initialisation: %s"):format(tostring(err)))
        end
    end)
end

function LB.OnPlayerLoaded(fn)
    if type(fn) ~= "function" then return end
    AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
        local src = source
        CreateThread(function()
            Wait(2500)
            pcall(fn, src, xPlayer)
        end)
    end)
end

function LB.OnPlayerDropped(fn)
    if type(fn) ~= "function" then return end
    AddEventHandler("vfw:playerDropped", function(source, xPlayer)
        pcall(fn, source, xPlayer)
    end)
end

local Labo = {
    list = {},
    access = {},
    harvestPoints = {},
    transformPoints = {},
    inside = {},
    harvestBusy = {},
    transformBusy = {},
    attacks = {},
    attackCooldown = {},
    cache = { labos = nil, builtAt = 0 },
}

local BUILDER_PERM = "labo_builder"
local BUCKET_OFFSET = (LaboConfig and LaboConfig.bucketOffset) or 20000
local SPOT_RANGE = 6.0
local TRANSFORM_TIMEOUT = 120
local ATTACK_DURATION = 900
local ATTACK_TICK = 5
local MOLOTOV_HASH = GetHashKey("WEAPON_MOLOTOV")

local function Num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

local function Int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

local function Bool(value)
    if value == nil then return false end
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    if type(value) == "string" then return value == "1" or value == "true" end
    return false
end

local function FactionName(xPlayer)
    if not xPlayer then return "" end
    local faction = xPlayer.faction
    if type(faction) == "table" then return faction.name or "" end
    if type(faction) == "string" then return faction end
    return ""
end

local function FactionLabel(xPlayer)
    if not xPlayer then return "" end
    local faction = xPlayer.faction
    if type(faction) == "table" then return faction.label or faction.name or "" end
    if type(faction) == "string" then return faction end
    return ""
end

local function LoadLabos()
    Labo.list = {}
    local rows = LB.Query("SELECT * FROM labos ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        Labo.list[row.id] = {
            id = row.id,
            name = row.name or ("labo_" .. tostring(row.id)),
            label = row.label or row.name or "Laboratoire",
            owner_faction = row.owner_faction or "no_owner",
            door_x = Num(row.door_x, 0.0), door_y = Num(row.door_y, 0.0),
            door_z = Num(row.door_z, 0.0), door_heading = Num(row.door_heading, 0.0),
            interior_x = Num(row.interior_x, 0.0), interior_y = Num(row.interior_y, 0.0),
            interior_z = Num(row.interior_z, 0.0), interior_heading = Num(row.interior_heading, 0.0),
            chest_x = row.chest_x and Num(row.chest_x, nil) or nil,
            chest_y = row.chest_y and Num(row.chest_y, nil) or nil,
            chest_z = row.chest_z and Num(row.chest_z, nil) or nil,
            chest_max_slots = Int(row.chest_max_slots, 20),
            management_x = row.management_x and Num(row.management_x, nil) or nil,
            management_y = row.management_y and Num(row.management_y, nil) or nil,
            management_z = row.management_z and Num(row.management_z, nil) or nil,
            blip_sprite = Int(row.blip_sprite, 499),
            blip_color = Int(row.blip_color, 1),
            blip_scale = Num(row.blip_scale, 0.5),
            bucket_id = Int(row.bucket_id, BUCKET_OFFSET + row.id),
            last_attacked = Int(row.last_attacked, 0),
        }
    end
    Labo.cache.labos = nil
end

local function LoadAccess()
    Labo.access = {}
    local rows = LB.Query("SELECT * FROM labo_access ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        local laboId = row.labo_id
        Labo.access[laboId] = Labo.access[laboId] or {}
        local list = Labo.access[laboId]
        list[#list + 1] = {
            id = row.id,
            labo_id = laboId,
            access_type = row.access_type or "faction",
            faction_name = row.faction_name,
            faction_label = row.faction_label,
            player_identifier = row.player_identifier,
            player_name = row.player_name,
            chest_access = Int(row.chest_access, 0),
            management_access = Int(row.management_access, 0),
        }
    end
    Labo.cache.labos = nil
end

local function LoadPoints()
    Labo.harvestPoints = {}
    local harvestRows = LB.Query("SELECT * FROM labo_harvest_points ORDER BY id")
    for i = 1, #harvestRows do
        local row = harvestRows[i]
        Labo.harvestPoints[row.id] = {
            id = row.id,
            labo_id = row.labo_id,
            coords_x = Num(row.coords_x, 0.0), coords_y = Num(row.coords_y, 0.0), coords_z = Num(row.coords_z, 0.0),
            rotation_z = Num(row.rotation_z, 0.0),
            marker_x = row.marker_x, marker_y = row.marker_y, marker_z = row.marker_z,
            prop_model = row.prop_model,
            label = row.label,
            item_output = row.item_output,
            output_quantity = Int(row.output_quantity, 1),
            harvest_time = Int(row.harvest_time, 5000),
            cooldown_seconds = Int(row.cooldown_seconds, 0),
            animation_type = row.animation_type or "predefined",
            animation_dict = row.animation_dict,
            animation_name = row.animation_name,
            animation_preset = row.animation_preset,
            animation_prop = row.animation_prop,
        }
    end

    Labo.transformPoints = {}
    local transformRows = LB.Query("SELECT * FROM labo_transform_points ORDER BY id")
    for i = 1, #transformRows do
        local row = transformRows[i]
        Labo.transformPoints[row.id] = {
            id = row.id,
            labo_id = row.labo_id,
            coords_x = Num(row.coords_x, 0.0), coords_y = Num(row.coords_y, 0.0), coords_z = Num(row.coords_z, 0.0),
            rotation_z = Num(row.rotation_z, 0.0),
            marker_x = row.marker_x, marker_y = row.marker_y, marker_z = row.marker_z,
            prop_model = row.prop_model,
            label = row.label,
            input_item = row.input_item,
            input_quantity = Int(row.input_quantity, 1),
            output_item = row.output_item,
            output_quantity = Int(row.output_quantity, 1),
            transform_time = Int(row.transform_time, 5000),
            cooldown_seconds = Int(row.cooldown_seconds, 0),
            animation_type = row.animation_type or "predefined",
            animation_dict = row.animation_dict,
            animation_name = row.animation_name,
            animation_preset = row.animation_preset,
            animation_prop = row.animation_prop,
        }
    end
end

local function AccessFor(laboId, xPlayer)
    local labo = Labo.list[laboId]
    if not labo or not xPlayer then
        return { has = false, chest = false, management = false, owner = false }
    end

    local factionName = FactionName(xPlayer)
    local isOwner = labo.owner_faction ~= "no_owner" and labo.owner_faction ~= "" and labo.owner_faction == factionName

    local result = { has = isOwner, chest = isOwner, management = isOwner, owner = isOwner }

    local list = Labo.access[laboId] or {}
    for i = 1, #list do
        local entry = list[i]
        if entry.access_type == "faction" and entry.faction_name == factionName and factionName ~= "" then
            result.has = true
            if entry.chest_access == 1 then result.chest = true end
            if entry.management_access == 1 then result.management = true end
        elseif entry.access_type == "player" and entry.player_identifier == xPlayer.identifier then
            result.has = true
            if entry.chest_access == 1 then result.chest = true end
            if entry.management_access == 1 then result.management = true end
        end
    end

    return result
end

local function InteriorPayload(laboId, xPlayer)
    local labo = Labo.list[laboId]
    if not labo then return nil end
    local access = AccessFor(laboId, xPlayer)
    return {
        id = labo.id,
        interior_x = labo.interior_x,
        interior_y = labo.interior_y,
        interior_z = labo.interior_z,
        interior_heading = labo.interior_heading,
        label = labo.label,
        chest_x = labo.chest_x,
        chest_y = labo.chest_y,
        chest_z = labo.chest_z,
        chest_max_slots = labo.chest_max_slots,
        management_x = labo.management_x,
        management_y = labo.management_y,
        management_z = labo.management_z,
        is_owner = access.owner,
        management_access = access.management,
    }
end

local function LabosFor(xPlayer)
    local out = {}
    for id, labo in pairs(Labo.list) do
        local access = AccessFor(id, xPlayer)
        out[id] = {
            id = labo.id,
            name = labo.name,
            label = labo.label,
            door_x = labo.door_x,
            door_y = labo.door_y,
            door_z = labo.door_z,
            door_heading = labo.door_heading,
            has_access = access.has,
            owner_faction = labo.owner_faction,
            blip_sprite = labo.blip_sprite,
            blip_color = labo.blip_color,
            blip_scale = labo.blip_scale,
        }
    end
    return out
end

local function ExitLabo(source, notify)
    local state = Labo.inside[source]
    if not state then return end

    Labo.inside[source] = nil
    SetPlayerRoutingBucket(source, 0)

    local labo = Labo.list[state.laboId]
    if labo then
        TriggerClientEvent("labo:exitInterior", source, {
            door_x = labo.door_x,
            door_y = labo.door_y,
            door_z = labo.door_z,
            door_heading = labo.door_heading,
        })
    else
        TriggerClientEvent("labo:exitInterior", source, { door_x = 0.0, door_y = 0.0, door_z = 70.0, door_heading = 0.0 })
    end

    if notify then
        TriggerClientEvent("labo:notify", source, notify)
    end
end

local function CooldownKey(kind, spotId)
    return kind .. ":" .. tostring(spotId)
end

local spotCooldown = {}

local function OnCooldown(kind, spotId, seconds)
    if not seconds or seconds <= 0 then return false, 0 end
    local last = spotCooldown[CooldownKey(kind, spotId)]
    if not last then return false, 0 end
    local remaining = seconds - (LB.Now() - last)
    if remaining <= 0 then return false, 0 end
    return true, remaining
end

local function SetCooldown(kind, spotId)
    spotCooldown[CooldownKey(kind, spotId)] = LB.Now()
end

LB.OnReady(function()
    LoadLabos()
    LoadAccess()
    LoadPoints()
end)

LB.OnPlayerDropped(function(source)
    Labo.inside[source] = nil
    for spotId, holder in pairs(Labo.harvestBusy) do
        if holder.source == source then Labo.harvestBusy[spotId] = nil end
    end
    for spotId, holder in pairs(Labo.transformBusy) do
        if holder.source == source then Labo.transformBusy[spotId] = nil end
    end
end)

CreateThread(function()
    while true do
        Wait(15000)
        local now = LB.Now()
        for spotId, holder in pairs(Labo.transformBusy) do
            if now - holder.startedAt > TRANSFORM_TIMEOUT then
                Labo.transformBusy[spotId] = nil
            end
        end
        for spotId, holder in pairs(Labo.harvestBusy) do
            if now - holder.startedAt > TRANSFORM_TIMEOUT then
                Labo.harvestBusy[spotId] = nil
            end
        end
    end
end)

LB.RegisterCallback("labo:getLabos", function(source)
    local xPlayer = LB.Player(source)
    return LabosFor(xPlayer)
end)

LB.RegisterCallback("labo:checkReconnect", function(source)
    local xPlayer = LB.Player(source)
    if not xPlayer then return nil end
    local state = Labo.inside[source]
    if not state then return nil end
    return InteriorPayload(state.laboId, xPlayer)
end)

LB.RegisterCallback("labo:bucketCheck", function(source)
    local state = Labo.inside[source]
    if not state then return nil end
    local xPlayer = LB.Player(source)
    if not xPlayer then return nil end
    return InteriorPayload(state.laboId, xPlayer)
end)

LB.RegisterCallback("labo:getInteriorData", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return nil end
    return InteriorPayload(id, xPlayer)
end)

LB.RegisterCallback("labo:canOpenChest", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return false end

    local state = Labo.inside[source]
    if not state or state.laboId ~= id then return false end

    local access = AccessFor(id, xPlayer)
    return access.chest == true
end)

RegisterNetEvent("labo:enter", function(laboId)
    local source = source
    local xPlayer = LB.Player(source)
    if not xPlayer then return end

    local id = Int(laboId, nil)
    if not id then return end

    local labo = Labo.list[id]
    if not labo then return end
    if Labo.inside[source] then return end

    local access = AccessFor(id, xPlayer)
    if not access.has then
        TriggerClientEvent("labo:notify", source, "Vous n'avez pas acces a ce laboratoire.")
        return
    end

    if LB.DistanceTo(source, labo.door_x, labo.door_y, labo.door_z) > 10.0 then
        TriggerClientEvent("labo:notify", source, "Vous etes trop loin de la porte.")
        return
    end

    Labo.inside[source] = { laboId = id, enteredAt = LB.Now() }
    SetPlayerRoutingBucket(source, labo.bucket_id or (BUCKET_OFFSET + id))
    TriggerClientEvent("labo:enterInterior", source, InteriorPayload(id, xPlayer))
end)

RegisterNetEvent("labo:exit", function()
    local source = source
    ExitLabo(source, nil)
end)

LB.RegisterCallback("labo:getHarvestPoints", function(source, laboId)
    local id = Int(laboId, nil)
    if not id then return {} end

    local out = {}
    for _, point in pairs(Labo.harvestPoints) do
        if point.labo_id == id then
            out[#out + 1] = point
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

LB.RegisterCallback("labo:getTransformPoints", function(source, laboId)
    local id = Int(laboId, nil)
    if not id then return {} end

    local out = {}
    for _, point in pairs(Labo.transformPoints) do
        if point.labo_id == id then
            out[#out + 1] = point
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end)

LB.RegisterCallback("labo:canHarvest", function(source, spotId)
    local xPlayer = LB.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local id = Int(spotId, nil)
    local point = id and Labo.harvestPoints[id] or nil
    if not point then return { success = false, message = "Point introuvable" } end

    local state = Labo.inside[source]
    if not state or state.laboId ~= point.labo_id then
        return { success = false, message = "Vous n'etes pas dans ce laboratoire" }
    end

    local busy = Labo.harvestBusy[id]
    if busy and busy.source ~= source and (LB.Now() - busy.startedAt) < 60 then
        return { success = false, message = "Poste deja occupe" }
    end

    local onCd, remaining = OnCooldown("harvest", id, point.cooldown_seconds)
    if onCd then
        return { success = false, message = ("Disponible dans %ds"):format(math.ceil(remaining)) }
    end

    if LB.DistanceTo(source, point.coords_x, point.coords_y, point.coords_z) > SPOT_RANGE then
        return { success = false, message = "Vous etes trop loin" }
    end

    if not xPlayer.canCarryItem(point.item_output, point.output_quantity) then
        return { success = false, message = "Votre inventaire est plein" }
    end

    Labo.harvestBusy[id] = { source = source, startedAt = LB.Now() }
    return { success = true }
end)

RegisterNetEvent("labo:completeHarvest", function(spotId)
    local source = source
    local xPlayer = LB.Player(source)
    if not xPlayer then return end

    local id = Int(spotId, nil)
    local point = id and Labo.harvestPoints[id] or nil
    if not point then return end

    local busy = Labo.harvestBusy[id]
    if not busy or busy.source ~= source then return end
    Labo.harvestBusy[id] = nil

    local state = Labo.inside[source]
    if not state or state.laboId ~= point.labo_id then return end
    if LB.DistanceTo(source, point.coords_x, point.coords_y, point.coords_z) > SPOT_RANGE then return end

    SetCooldown("harvest", id)

    if not LB.GiveItem(xPlayer, point.item_output, point.output_quantity, true) then
        TriggerClientEvent("labo:notify", source, "Votre inventaire est plein.")
        return
    end

    LB.Execute([[
        INSERT INTO labo_stats (labo_id, action, identifier, item_name, quantity)
        VALUES (?, 'harvest', ?, ?, ?)
    ]], { point.labo_id, xPlayer.identifier, point.item_output, point.output_quantity })
end)

RegisterNetEvent("labo:stopHarvesting", function(spotId)
    local source = source
    local id = Int(spotId, nil)
    if not id then return end
    local busy = Labo.harvestBusy[id]
    if busy and busy.source == source then
        Labo.harvestBusy[id] = nil
    end
end)

LB.RegisterCallback("labo:canTransform", function(source, spotId)
    local xPlayer = LB.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local id = Int(spotId, nil)
    local point = id and Labo.transformPoints[id] or nil
    if not point then return { success = false, message = "Point introuvable" } end

    local state = Labo.inside[source]
    if not state or state.laboId ~= point.labo_id then
        return { success = false, message = "Vous n'etes pas dans ce laboratoire" }
    end

    local busy = Labo.transformBusy[id]
    if busy and busy.source ~= source and (LB.Now() - busy.startedAt) < 60 then
        return { success = false, message = "Poste deja occupe" }
    end

    local onCd, remaining = OnCooldown("transform", id, point.cooldown_seconds)
    if onCd then
        return { success = false, message = ("Disponible dans %ds"):format(math.ceil(remaining)) }
    end

    if LB.DistanceTo(source, point.coords_x, point.coords_y, point.coords_z) > SPOT_RANGE then
        return { success = false, message = "Vous etes trop loin" }
    end

    if point.input_item and point.input_item ~= "" then
        if not xPlayer.haveItem(point.input_item, point.input_quantity) then
            return {
                success = false,
                message = ("Il vous faut %dx %s"):format(point.input_quantity, LB.ItemLabel(point.input_item)),
            }
        end
    end

    if not xPlayer.canCarryItem(point.output_item, point.output_quantity) then
        return { success = false, message = "Votre inventaire est plein" }
    end

    Labo.transformBusy[id] = { source = source, startedAt = LB.Now() }
    return { success = true }
end)

RegisterNetEvent("labo:completeTransform", function(spotId)
    local source = source
    local xPlayer = LB.Player(source)
    if not xPlayer then return end

    local id = Int(spotId, nil)
    local point = id and Labo.transformPoints[id] or nil
    if not point then return end

    local busy = Labo.transformBusy[id]
    if not busy or busy.source ~= source then return end
    Labo.transformBusy[id] = nil

    local state = Labo.inside[source]
    if not state or state.laboId ~= point.labo_id then return end
    if LB.DistanceTo(source, point.coords_x, point.coords_y, point.coords_z) > SPOT_RANGE then return end

    if point.input_item and point.input_item ~= "" then
        if not LB.TakeItem(xPlayer, point.input_item, point.input_quantity) then
            TriggerClientEvent("labo:notify", source, "Ingredients manquants.")
            return
        end
    end

    SetCooldown("transform", id)

    if not LB.GiveItem(xPlayer, point.output_item, point.output_quantity, true) then
        if point.input_item and point.input_item ~= "" then
            LB.GiveItem(xPlayer, point.input_item, point.input_quantity, false)
        end
        TriggerClientEvent("labo:notify", source, "Votre inventaire est plein.")
        return
    end

    LB.Execute([[
        INSERT INTO labo_stats (labo_id, action, identifier, item_name, quantity)
        VALUES (?, 'transform', ?, ?, ?)
    ]], { point.labo_id, xPlayer.identifier, point.output_item, point.output_quantity })
end)

LB.RegisterCallback("labo:getAccessList", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return {} end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return {} end

    local out = {}
    local list = Labo.access[id] or {}
    for i = 1, #list do
        local entry = list[i]
        out[#out + 1] = {
            id = entry.id,
            access_type = entry.access_type,
            faction_name = entry.faction_name,
            faction_label = entry.faction_label,
            player_name = entry.player_name,
            chest_access = entry.chest_access,
            management_access = entry.management_access,
        }
    end
    return out
end)

local function FindAccess(accessId)
    for laboId, list in pairs(Labo.access) do
        for i = 1, #list do
            if list[i].id == accessId then return list[i], laboId end
        end
    end
    return nil, nil
end

LB.RegisterCallback("labo:toggleChestAccess", function(source, accessId)
    local xPlayer = LB.Player(source)
    local id = Int(accessId, nil)
    if not xPlayer or not id then return false end

    local entry, laboId = FindAccess(id)
    if not entry then return false end

    local access = AccessFor(laboId, xPlayer)
    if not access.owner and not access.management then return false end

    local newValue = entry.chest_access == 1 and 0 or 1
    LB.Execute("UPDATE labo_access SET chest_access = ? WHERE id = ?", { newValue, id })
    entry.chest_access = newValue
    return true
end)

LB.RegisterCallback("labo:toggleManagementAccess", function(source, accessId)
    local xPlayer = LB.Player(source)
    local id = Int(accessId, nil)
    if not xPlayer or not id then return false end

    local entry, laboId = FindAccess(id)
    if not entry then return false end

    local access = AccessFor(laboId, xPlayer)
    if not access.owner then return false end

    local newValue = entry.management_access == 1 and 0 or 1
    LB.Execute("UPDATE labo_access SET management_access = ? WHERE id = ?", { newValue, id })
    entry.management_access = newValue
    return true
end)

LB.RegisterCallback("labo:removeAccess", function(source, accessId)
    local xPlayer = LB.Player(source)
    local id = Int(accessId, nil)
    if not xPlayer or not id then return false end

    local entry, laboId = FindAccess(id)
    if not entry then return false end

    local access = AccessFor(laboId, xPlayer)
    if not access.owner and not access.management then return false end

    LB.Execute("DELETE FROM labo_access WHERE id = ?", { id })
    LoadAccess()
    return true
end)

LB.RegisterCallback("labo:getFactionMembers", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return {} end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return {} end

    local labo = Labo.list[id]
    if not labo or labo.owner_faction == "no_owner" then return {} end

    local rows = LB.Query([[
        SELECT identifier, name, grade_level FROM faction_members WHERE faction_name = ? ORDER BY grade_level DESC
    ]], { labo.owner_faction })

    if #rows == 0 then
        rows = LB.Query([[
            SELECT identifier, CONCAT(firstname, ' ', lastname) AS name, job2_grade AS grade_level
            FROM characters WHERE faction = ? AND deleted_at IS NULL
        ]], { labo.owner_faction })
    end

    local grants = {}
    local list = Labo.access[id] or {}
    for i = 1, #list do
        if list[i].access_type == "player" and list[i].player_identifier then
            grants[list[i].player_identifier] = list[i]
        end
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local grant = grants[row.identifier]
        out[#out + 1] = {
            identifier = row.identifier,
            name = row.name or "Inconnu",
            grade = Int(row.grade_level, 0),
            chestAccess = grant ~= nil and grant.chest_access == 1,
            managementAccess = grant ~= nil and grant.management_access == 1,
        }
    end
    return out
end)

LB.RegisterCallback("labo:toggleMemberPerm", function(source, laboId, identifier, name, permType)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return false end
    if type(identifier) ~= "string" then return false end
    if permType ~= "chest" and permType ~= "management" then return false end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return false end
    if permType == "management" and not access.owner then return false end

    local column = permType == "chest" and "chest_access" or "management_access"

    local existing = LB.Single([[
        SELECT * FROM labo_access WHERE labo_id = ? AND access_type = 'player' AND player_identifier = ?
    ]], { id, identifier })

    if existing then
        local current = Int(existing[column], 0)
        LB.Execute(("UPDATE labo_access SET %s = ? WHERE id = ?"):format(column), {
            current == 1 and 0 or 1, existing.id,
        })
    else
        LB.Execute(([[
            INSERT INTO labo_access (labo_id, access_type, player_identifier, player_name, %s)
            VALUES (?, 'player', ?, ?, 1)
        ]]):format(column), { id, identifier, type(name) == "string" and name or "Inconnu" })
    end

    LoadAccess()
    return true
end)

LB.RegisterCallback("labo:getFactions", function(source)
    local xPlayer = LB.Player(source)
    if not xPlayer then return {} end

    local out = {}
    local rows = LB.Query("SELECT name, label FROM crews")
    for i = 1, #rows do
        out[#out + 1] = { name = rows[i].name, label = rows[i].label or rows[i].name }
    end

    if #out == 0 and VFW and VFW.Factions then
        for name, faction in pairs(VFW.Factions) do
            out[#out + 1] = {
                name = name,
                label = (type(faction) == "table" and faction.label) or name,
            }
        end
    end

    return out
end)

LB.RegisterCallback("labo:addFactionAccess", function(source, laboId, factionName, chestAccess)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return false end
    if type(factionName) ~= "string" or factionName == "" then return false end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return false end

    local labo = Labo.list[id]
    if not labo then return false end
    if labo.owner_faction == factionName then return false end

    local existing = LB.Single([[
        SELECT id FROM labo_access WHERE labo_id = ? AND access_type = 'faction' AND faction_name = ?
    ]], { id, factionName })
    if existing then return false end

    local label = factionName
    local row = LB.Single("SELECT label FROM crews WHERE name = ?", { factionName })
    if row and row.label then label = row.label end

    LB.Execute([[
        INSERT INTO labo_access (labo_id, access_type, faction_name, faction_label, chest_access, management_access)
        VALUES (?, 'faction', ?, ?, ?, 0)
    ]], { id, factionName, label, chestAccess == true and 1 or 0 })

    LoadAccess()
    return true
end)

LB.RegisterCallback("labo:getNearbyPlayers", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return {} end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return {} end

    local labo = Labo.list[id]
    if not labo then return {} end

    local doorCoords = vector3(labo.door_x, labo.door_y, labo.door_z)
    local players = VFW.GetPlayersInRadius(doorCoords, 8.0)

    local out = {}
    for i = 1, #players do
        local other = players[i]
        if other.source ~= source then
            out[#out + 1] = { serverId = other.source, name = other.name }
        end
    end
    return out
end)

LB.RegisterCallback("labo:addPlayerAccess", function(source, laboId, targetServerId, chestAccess)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    local targetId = Int(targetServerId, nil)
    if not xPlayer or not id or not targetId then return false, "Cette demande n'a pas pu être traitée" end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return false, "Permission refusee" end

    local xTarget = LB.Player(targetId)
    if not xTarget then return false, "Joueur introuvable" end

    local labo = Labo.list[id]
    if not labo then return false, "Laboratoire introuvable" end

    if LB.DistanceTo(targetId, labo.door_x, labo.door_y, labo.door_z) > 10.0 then
        return false, "Le joueur doit etre devant la porte"
    end

    local existing = LB.Single([[
        SELECT id FROM labo_access WHERE labo_id = ? AND access_type = 'player' AND player_identifier = ?
    ]], { id, xTarget.identifier })
    if existing then return false, "Ce joueur a deja un acces" end

    LB.Execute([[
        INSERT INTO labo_access (labo_id, access_type, player_identifier, player_name, chest_access, management_access)
        VALUES (?, 'player', ?, ?, ?, 0)
    ]], { id, xTarget.identifier, xTarget.name, chestAccess == true and 1 or 0 })

    LoadAccess()
    return true, nil
end)

LB.RegisterCallback("labo:transferOwnership", function(source, laboId, factionName)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return false end
    if type(factionName) ~= "string" or factionName == "" then return false end

    local access = AccessFor(id, xPlayer)
    if not access.owner then return false end

    LB.Execute("UPDATE labos SET owner_faction = ? WHERE id = ?", { factionName, id })
    LB.Execute("DELETE FROM labo_access WHERE labo_id = ?", { id })

    LoadLabos()
    LoadAccess()

    for src, state in pairs(Labo.inside) do
        if state.laboId == id then
            ExitLabo(src, "La propriete du laboratoire a change.")
        end
    end

    TriggerClientEvent("labo:refreshBlips", -1)
    return true
end)

LB.RegisterCallback("labo:getStats", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return nil end

    local access = AccessFor(id, xPlayer)
    if not access.owner and not access.management then return nil end

    local harvestTotal = LB.Scalar("SELECT COUNT(*) FROM labo_stats WHERE labo_id = ? AND action = 'harvest'", { id })
    local harvest24h = LB.Scalar([[
        SELECT COUNT(*) FROM labo_stats WHERE labo_id = ? AND action = 'harvest'
        AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ]], { id })
    local transformTotal = LB.Scalar("SELECT COUNT(*) FROM labo_stats WHERE labo_id = ? AND action = 'transform'", { id })
    local transform24h = LB.Scalar([[
        SELECT COUNT(*) FROM labo_stats WHERE labo_id = ? AND action = 'transform'
        AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ]], { id })

    return {
        harvestTotal = Int(harvestTotal, 0),
        harvest24h = Int(harvest24h, 0),
        transformTotal = Int(transformTotal, 0),
        transform24h = Int(transform24h, 0),
    }
end)

local function DefenderSources(factionName)
    local out = {}
    if factionName == "" or factionName == "no_owner" then return out end
    for src, xPlayer in pairs(VFW.Players or {}) do
        if FactionName(xPlayer) == factionName then
            out[#out + 1] = src
        end
    end
    return out
end

local function AttackerSources(laboId, attackerFaction)
    local labo = Labo.list[laboId]
    local out = {}
    if not labo then return out end
    local doorCoords = vector3(labo.door_x, labo.door_y, labo.door_z)
    local players = VFW.GetPlayersInRadius(doorCoords, 40.0)
    for i = 1, #players do
        if FactionName(players[i]) == attackerFaction then
            out[#out + 1] = players[i].source
        end
    end
    return out
end

local function EndAttack(laboId, success)
    local attack = Labo.attacks[laboId]
    if not attack then return end
    Labo.attacks[laboId] = nil

    LB.Execute("UPDATE labo_attacks SET progress = ?, success = ?, ended_at = NOW() WHERE id = ?", {
        attack.progress, success and 1 or 0, attack.dbId,
    })

    TriggerClientEvent("labo:attackEnd", -1, laboId)

    local labo = Labo.list[laboId]
    if success and labo then
        LB.Execute("UPDATE labos SET owner_faction = ? WHERE id = ?", { attack.attackerFaction, laboId })
        LB.Execute("DELETE FROM labo_access WHERE labo_id = ?", { laboId })
        LoadLabos()
        LoadAccess()

        for src, state in pairs(Labo.inside) do
            if state.laboId == laboId then
                ExitLabo(src, "Le laboratoire a change de main.")
            end
        end
        TriggerClientEvent("labo:refreshBlips", -1)
    end

    local message = success and "Le laboratoire a ete capture !" or "L'attaque a echoue."
    local targets = AttackerSources(laboId, attack.attackerFaction)
    for i = 1, #targets do
        TriggerClientEvent("labo:attackResult", targets[i], { success = success, message = message })
    end
    local defenders = DefenderSources(attack.defenderFaction)
    for i = 1, #defenders do
        TriggerClientEvent("labo:attackResult", defenders[i], { success = not success, message = success and "Vous avez perdu le laboratoire." or "Vous avez repousse l'attaque." })
    end
end

LB.RegisterCallback("labo:preCheckAttack", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return { ok = false, message = "Laboratoire introuvable" } end

    local labo = Labo.list[id]
    if not labo then return { ok = false, message = "Laboratoire introuvable" } end
    if labo.owner_faction == "no_owner" or labo.owner_faction == "" then
        return { ok = false, message = "Ce laboratoire n'appartient a personne" }
    end

    local factionName = FactionName(xPlayer)
    if factionName == "" then return { ok = false, message = "Vous n'avez pas d'organisation" } end
    if factionName == labo.owner_faction then return { ok = false, message = "" } end

    if Labo.attacks[id] then return { ok = false, message = "Une attaque est deja en cours" } end

    local cooldownMinutes = (LaboConfig and LaboConfig.attackCooldownMinutes) or 2880
    if labo.last_attacked > 0 and (LB.Now() - labo.last_attacked) < cooldownMinutes * 60 then
        return { ok = false, message = "Ce laboratoire a ete attaque recemment" }
    end

    local minOnline = (LaboConfig and LaboConfig.minFactionOnline) or 1
    if #DefenderSources(labo.owner_faction) < minOnline then
        return { ok = false, message = "Aucun defenseur en ligne" }
    end

    return { ok = true, message = "Vous pouvez lancer l'attaque en incendiant la porte." }
end)

LB.RegisterCallback("labo:startAttack", function(source, laboId)
    local xPlayer = LB.Player(source)
    local id = Int(laboId, nil)
    if not xPlayer or not id then return { success = false, message = "Laboratoire introuvable" } end

    local labo = Labo.list[id]
    if not labo then return { success = false, message = "Laboratoire introuvable" } end
    if Labo.attacks[id] then return { success = false, message = "Une attaque est deja en cours" } end

    local factionName = FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Vous n'avez pas d'organisation" } end
    if factionName == labo.owner_faction then return { success = false, message = "C'est votre laboratoire" } end
    if labo.owner_faction == "no_owner" or labo.owner_faction == "" then
        return { success = false, message = "Ce laboratoire n'appartient a personne" }
    end

    local cooldownMinutes = (LaboConfig and LaboConfig.attackCooldownMinutes) or 2880
    if labo.last_attacked > 0 and (LB.Now() - labo.last_attacked) < cooldownMinutes * 60 then
        return { success = false, message = "Ce laboratoire a ete attaque recemment" }
    end

    if LB.DistanceTo(source, labo.door_x, labo.door_y, labo.door_z) > 12.0 then
        return { success = false, message = "Vous etes trop loin de la porte" }
    end

    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 and GetSelectedPedWeapon then
        local ok, weapon = pcall(GetSelectedPedWeapon, ped)
        if ok and weapon and weapon ~= MOLOTOV_HASH then
            return { success = false, message = "Il vous faut un cocktail molotov equipe" }
        end
    end

    local minOnline = (LaboConfig and LaboConfig.minFactionOnline) or 1
    if #DefenderSources(labo.owner_faction) < minOnline then
        return { success = false, message = "Aucun defenseur en ligne" }
    end

    local now = LB.Now()
    labo.last_attacked = now
    LB.Execute("UPDATE labos SET last_attacked = ? WHERE id = ?", { now, id })

    local dbId = LB.Insert([[
        INSERT INTO labo_attacks (labo_id, attacker_faction, defender_faction, progress)
        VALUES (?, ?, ?, 0)
    ]], { id, factionName, labo.owner_faction })

    Labo.attacks[id] = {
        dbId = dbId,
        laboId = id,
        attackerFaction = factionName,
        attackerLabel = FactionLabel(xPlayer),
        defenderFaction = labo.owner_faction,
        defenderLabel = labo.owner_faction,
        progress = 0,
        startedAt = now,
        endsAt = now + ATTACK_DURATION,
    }

    local defenders = DefenderSources(labo.owner_faction)
    for i = 1, #defenders do
        TriggerClientEvent("labo:attackAlert", defenders[i], {
            laboId = id,
            laboName = labo.label,
            attackerFaction = FactionLabel(xPlayer),
            door_x = labo.door_x,
            door_y = labo.door_y,
            door_z = labo.door_z,
        })
    end

    return { success = true, message = "Attaque lancee" }
end)

CreateThread(function()
    while true do
        Wait(ATTACK_TICK * 1000)
        local running = {}
        for laboId in pairs(Labo.attacks) do
            running[#running + 1] = laboId
        end
        for index = 1, #running do
            local laboId = running[index]
            local attack = Labo.attacks[laboId]
            local labo = Labo.list[laboId]
            if attack and not labo then
                Labo.attacks[laboId] = nil
            elseif attack then
                local attackers = AttackerSources(laboId, attack.attackerFaction)
                local defenders = {}
                local doorCoords = vector3(labo.door_x, labo.door_y, labo.door_z)
                local nearby = VFW.GetPlayersInRadius(doorCoords, 40.0)
                for i = 1, #nearby do
                    if FactionName(nearby[i]) == attack.defenderFaction then
                        defenders[#defenders + 1] = nearby[i].source
                    end
                end

                local paused = #attackers == 0 or #defenders > #attackers
                if not paused then
                    attack.progress = math.min(100, attack.progress + (ATTACK_TICK * 100 / ATTACK_DURATION) * 4)
                end

                local timeLeft = math.max(0, attack.endsAt - LB.Now())

                for i = 1, #attackers do
                    TriggerClientEvent("labo:attackProgress", attackers[i], laboId, attack.progress, paused,
                        timeLeft, labo.label, #attackers, #defenders, false, attack.attackerLabel, attack.defenderLabel)
                end
                for i = 1, #defenders do
                    TriggerClientEvent("labo:attackProgress", defenders[i], laboId, attack.progress, paused,
                        timeLeft, labo.label, #attackers, #defenders, true, attack.attackerLabel, attack.defenderLabel)
                end

                if attack.progress >= 100 then
                    EndAttack(laboId, true)
                elseif timeLeft <= 0 then
                    EndAttack(laboId, false)
                end
            end
        end
    end
end)

RegisterNetEvent("laboBuilder:reload", function()
    local source = source
    local xPlayer = LB.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end

    LoadLabos()
    LoadAccess()
    LoadPoints()
    TriggerClientEvent("laboBuilder:syncLabos", -1)
    TriggerClientEvent("labo:refreshBlips", -1)
end)
