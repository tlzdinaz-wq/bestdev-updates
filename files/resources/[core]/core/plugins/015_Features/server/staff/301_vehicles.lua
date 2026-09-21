VFW = VFW or {}
VFW.Vehicles = VFW.Vehicles or {}

local CONTEXT_RANGE = 25.0
local ASSIGN_RANGE = 15.0
local MAX_PLATE_LENGTH = 12
local MAX_MODEL_LENGTH = 32
local MAX_REASON_LENGTH = 120
local BLACKLIST_KEY = "vehicleBlacklist"

local staffOriginalProps = {}

local function vehiclesApi()
    local api = VFW.Vehicles
    if type(api) ~= "table" then return nil end
    if type(api.GetByPlate) ~= "function" then return nil end
    if type(api.Query) ~= "function" then return nil end
    return api
end

local function notify(source, variant, message)
    if not source or source == 0 then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF",
        variant = variant,
        subtitle = "Véhicules",
        message = message,
        content = message,
    })
end

local function logStaff(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, action, payload)
end

local function rateOk(source, key, delay)
    if Feat27 and type(Feat27.RateLimit) == "function" then
        return Feat27.RateLimit(source, key, delay or 400)
    end
    return true
end

local function staffPlayer(source, permission)
    if type(permission) ~= "string" or permission == "" then return nil end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission(permission) then return nil end
    return xPlayer
end

local function plateForms(raw)
    if type(raw) ~= "string" then return nil, nil end
    local trimmed = raw:gsub("^%s+", "")
    trimmed = trimmed:gsub("%s+$", "")
    if trimmed == "" or #trimmed > MAX_PLATE_LENGTH then return nil, nil end
    return trimmed, trimmed:upper()
end

local function cleanModel(raw)
    if type(raw) ~= "string" then return nil end
    local model = raw:gsub("%s+", "")
    if model == "" or #model > MAX_MODEL_LENGTH then return nil end
    model = model:lower()
    if model:match("^[a-z0-9_%-]+$") == nil then return nil end
    return model
end

local function findRow(raw)
    local trimmed, normalized = plateForms(raw)
    if not trimmed then return nil end
    local api = vehiclesApi()
    if not api then return nil end
    local row = api.GetByPlate(normalized)
    if not row then row = api.GetByPlate(trimmed) end
    if not row then return nil end
    return row, trimmed, normalized
end

local function findEntityByPlate(raw)
    local trimmed, normalized = plateForms(raw)
    if not trimmed then return nil end
    local all = GetAllVehicles() or {}
    for i = 1, #all do
        local veh = all[i]
        if DoesEntityExist(veh) then
            local current = GetVehicleNumberPlateText(veh)
            local currentTrimmed, currentNormalized = plateForms(current)
            if currentTrimmed and (currentTrimmed == trimmed or currentNormalized == normalized) then
                return veh
            end
        end
    end
    return nil
end

local function playerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function withinRange(source, entity, range)
    local coords = playerCoords(source)
    if not coords then return false end
    local target = GetEntityCoords(entity)
    local dx = coords.x - target.x
    local dy = coords.y - target.y
    local dz = coords.z - target.z
    local maximum = range or CONTEXT_RANGE
    return (dx * dx + dy * dy + dz * dz) <= (maximum * maximum)
end

local function statusOf(row)
    if tonumber(row.pounded) == 1 then return "fourriere" end
    if tonumber(row.stored) == 1 then return "garage" end
    return "sorti"
end

local function propertyPlates()
    local out = {}
    local ok, rows = pcall(MySQL.query.await, "SELECT plate FROM property_garage_vehicles", {})
    if not ok or type(rows) ~= "table" then return out end
    for i = 1, #rows do
        local trimmed, normalized = plateForms(rows[i].plate)
        if trimmed then
            out[trimmed] = true
            out[normalized] = true
        end
    end
    return out
end

local function blacklistEntries()
    if type(ConfigManager) ~= "table" then return {} end
    if type(ConfigManager.GetOverride) ~= "function" then return {} end

    local stored = ConfigManager.GetOverride(BLACKLIST_KEY)
    if type(stored) ~= "table" then return {} end

    local out = {}
    for i = 1, #stored do
        local entry = stored[i]
        if type(entry) == "table" and type(entry.model) == "string" and entry.model ~= "" then
            out[#out + 1] = {
                model = entry.model,
                reason = type(entry.reason) == "string" and entry.reason or "",
                added_by = type(entry.added_by) == "string" and entry.added_by or "",
            }
        end
    end
    return out
end

local function blacklistSave(list)
    if type(ConfigManager) ~= "table" or type(ConfigManager.Set) ~= "function" then return false end
    return ConfigManager.Set(BLACKLIST_KEY, list) == true
end

function VFW.Vehicles.IsModelBlacklisted(model)
    local wanted = cleanModel(model)
    if not wanted then return false end
    local list = blacklistEntries()
    for i = 1, #list do
        if list[i].model:lower() == wanted then return true end
    end
    return false
end

function VFW.Vehicles.GetStaffOriginalProps(plate)
    local trimmed, normalized = plateForms(plate)
    if not trimmed then return nil end
    local entry = staffOriginalProps[normalized]
    if not entry then return nil end
    return entry.props
end

local function carlistHasModel(model)
    local catalog = VFW.Staff and VFW.Staff.Carlist
    if type(catalog) ~= "table" then return false end
    for _, entries in pairs(catalog) do
        if type(entries) == "table" then
            for i = 1, #entries do
                local entry = entries[i]
                if type(entry) == "table" and type(entry.model) == "string" and entry.model:lower() == model then
                    return true
                end
            end
        end
    end
    return false
end

local function spawnAheadOf(source, distance)
    local coords = playerCoords(source)
    if not coords then return nil, 0.0 end

    local ped = GetPlayerPed(source)
    local heading = (ped and ped ~= 0) and GetEntityHeading(ped) or 0.0
    local radians = math.rad(heading)
    local offset = distance or 4.0

    return {
        x = coords.x - math.sin(radians) * offset,
        y = coords.y + math.cos(radians) * offset,
        z = coords.z,
    }, heading
end

local function refreshVehicleMenus(source, state)
    TriggerClientEvent("vfw:staff:refreshVehicleActionsMenu", source, state)
    TriggerClientEvent("vfw:staff:refreshVehicleExtraActionsMenu", source, state)
end

local function persistProps(row, props)
    local api = vehiclesApi()
    if not api or type(props) ~= "table" then return false end

    local engineHealth, bodyHealth, fuelLevel, turbo = api.ExtractHealth(props, row)
    props.plate = row.plate

    MySQL.update.await([[
        UPDATE owned_vehicles SET props = ?, engineHealth = ?, bodyHealth = ?, fuelLevel = ?, modTurbo = ?
        WHERE plate = ?
    ]], {
        VFW.DB.Encode(props),
        engineHealth,
        bodyHealth,
        fuelLevel,
        turbo and 1 or 0,
        row.plate,
    })

    return true
end

local function pushPropsToEntity(plate, props)
    if type(props) ~= "table" then return end
    local entity = findEntityByPlate(plate)
    if not entity or not DoesEntityExist(entity) then return end
    Entity(entity).state:set("VehicleProperties", props, true)
end

local function grantTemporaryKey(target, plate, identifier)
    local trimmed, normalized = plateForms(plate)
    if not trimmed then return false end

    local state = Player(target).state
    state:set("tempVehicleKey:" .. trimmed, "staff", true)
    if normalized ~= trimmed then
        state:set("tempVehicleKey:" .. normalized, "staff", true)
    end

    TriggerClientEvent("vfw:vehicle:keyTemporarly:added", target, "staff", trimmed)
    if type(identifier) == "string" and identifier ~= "" then
        TriggerEvent("vfw:vehicle:tempKeyAdded", target, "staff", trimmed, identifier)
    end

    return true
end

local function grantPermanentKey(plate, identifier, grantedBy)
    local trimmed = plateForms(plate)
    if not trimmed then return false end
    if type(identifier) ~= "string" or identifier == "" then return false end

    local ok = pcall(MySQL.insert.await, [[
        INSERT IGNORE INTO concess_key_duplicates (plate, identifier, granted_by, concess_id)
        VALUES (?, ?, ?, NULL)
    ]], { trimmed, identifier, tostring(grantedBy or "") })

    return ok == true
end

local function transferOwnership(source, xPlayer, plate, targetId, action)
    local row, trimmed = findRow(plate)
    if not row then
        notify(source, "ERROR", "Ce véhicule n'est pas enregistré.")
        return false
    end

    local id = tonumber(targetId)
    if not id then
        notify(source, "ERROR", "Cet identifiant n'est pas valide.")
        return false
    end

    local xTarget = VFW.GetPlayerFromId(id)
    if not xTarget then
        notify(source, "ERROR", "Ce joueur n'est pas connecté.")
        return false
    end

    if row.group_type and row.group_type ~= "" then
        notify(source, "ERROR", "Ce véhicule appartient à une entreprise ou à une faction.")
        return false
    end

    if xTarget.identifier == row.owner then
        notify(source, "INFO", "Ce joueur possède déjà ce véhicule.")
        return false
    end

    MySQL.update.await("UPDATE owned_vehicles SET owner = ?, owner_charid = ? WHERE plate = ?", {
        xTarget.identifier,
        xTarget.charId,
        row.plate,
    })

    notify(source, "SUCCESS", ("Le véhicule %s appartient maintenant à %s."):format(row.plate, xTarget.name))
    notify(xTarget.source, "SUCCESS", ("Vous avez reçu le véhicule %s."):format(row.plate))

    logStaff(source, action or "vehicle_transfer", {
        plate = row.plate,
        previousOwner = row.owner,
        newOwner = xTarget.identifier,
        target = xTarget.source,
    })

    return true, row, trimmed
end

local function applyVehicleState(source, xPlayer, plate, state, props, action)
    if state ~= "garage" and state ~= "fourriere" then return end

    local row = findRow(plate)
    if not row then
        notify(source, "ERROR", "Ce véhicule n'est pas enregistré.")
        return
    end

    if type(props) == "table" then
        persistProps(row, props)
    end

    if state == "garage" then
        MySQL.update.await([[
            UPDATE owned_vehicles SET stored = 1, pounded = 0, pound_id = NULL WHERE plate = ?
        ]], { row.plate })
    else
        MySQL.update.await([[
            UPDATE owned_vehicles SET stored = 0, pounded = 1 WHERE plate = ?
        ]], { row.plate })
    end

    local entity = findEntityByPlate(row.plate)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    if state == "garage" then
        notify(source, "SUCCESS", ("Le véhicule %s est rangé au garage."):format(row.plate))
    else
        notify(source, "SUCCESS", ("Le véhicule %s est placé en fourrière."):format(row.plate))
    end

    logStaff(source, action or "vehicle_state", { plate = row.plate, state = state, owner = row.owner })
    refreshVehicleMenus(source, state)
end

local function spawnOwnedVehicle(source, xPlayer, plate, targetSource)
    local api = vehiclesApi()
    if not api then return end

    local row = findRow(plate)
    if not row then
        notify(source, "ERROR", "Ce véhicule n'est pas enregistré.")
        return
    end

    local existing = findEntityByPlate(row.plate)
    if existing and DoesEntityExist(existing) then
        notify(source, "ERROR", "Ce véhicule est déjà sorti.")
        return
    end

    if tonumber(row.pounded) == 1 then
        notify(source, "ERROR", "Ce véhicule est en fourrière. Sortez-le de la fourrière avant de le faire apparaître.")
        return
    end

    local model = row.vehName
    if type(model) ~= "string" or model == "" then
        notify(source, "ERROR", "Le modèle de ce véhicule est introuvable.")
        return
    end

    local coords, heading = spawnAheadOf(targetSource, 4.0)
    if not coords then
        notify(source, "ERROR", "La position du joueur est introuvable.")
        return
    end

    local props = api.BuildProps(row)
    local vehicle, netId = api.Spawn(targetSource, model, coords, heading, props)
    if not vehicle or not netId then
        notify(source, "ERROR", "Ce véhicule n'a pas pu apparaître.")
        return
    end

    MySQL.update.await("UPDATE owned_vehicles SET stored = 0 WHERE plate = ?", { row.plate })

    TriggerClientEvent("garage:placeVehicleOnGround", targetSource, netId)
    notify(source, "SUCCESS", ("Le véhicule %s est apparu."):format(row.plate))

    logStaff(source, "vehicle_spawn_owned", {
        plate = row.plate,
        owner = row.owner,
        target = targetSource,
    })

    refreshVehicleMenus(source, "sorti")
end

local function contextVehicle(source, ent)
    if type(ent) ~= "table" then return nil end

    local entity = ent.entity
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityType(entity) ~= 2 then return nil end
    if not withinRange(source, entity, CONTEXT_RANGE) then return nil end

    return entity
end

local function relayApply(source, action, entity, extra)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if not netId or netId == 0 then return false end
    TriggerClientEvent("vfw:vehicle:apply", source, action, netId, extra)
    return true
end

local function contextRelay(action, message)
    return function(source, ent)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end
        if not relayApply(source, action, entity) then
            return { ok = false, err = "Ce véhicule n'est pas synchronisé." }
        end
        return { ok = true, msg = message }
    end
end

RegisterServerCallback("vfw:staff:isVehicleSpawned", function(source, plate)
    local xPlayer = staffPlayer(source, "staff_menu")
    if not xPlayer then return false end

    local entity = findEntityByPlate(plate)
    if not entity or not DoesEntityExist(entity) then return false end

    local coords = GetEntityCoords(entity)
    return true, { x = coords.x, y = coords.y, z = coords.z }
end)

RegisterServerCallback("core:server:GetAllVehicle", function(source, targetId)
    local empty = { owned = {}, job = {}, faction = {} }

    local xPlayer = staffPlayer(source, "staff_menu")
    if not xPlayer then return empty end

    local id = tonumber(targetId)
    if not id then return empty end

    local xTarget = VFW.GetPlayerFromId(id)
    if not xTarget then return empty end

    local api = vehiclesApi()
    if not api then return empty end

    local lists = { owned = {}, job = {}, faction = {} }
    local properties = propertyPlates()

    local function push(bucket, rows)
        if type(rows) ~= "table" then return end
        for i = 1, #rows do
            local row = rows[i]
            local status = statusOf(row)
            if status == "sorti" and properties[row.plate] then status = "propriete" end
            bucket[#bucket + 1] = {
                plate = row.plate,
                name = row.vehName or row.model or "",
                label = row.label or "",
                stored = status,
            }
        end
    end

    local okOwned, owned = pcall(api.Query, [[
        SELECT * FROM owned_vehicles
        WHERE owner = ? AND (group_type IS NULL OR group_type = '')
        ORDER BY vehName ASC
    ]], { xTarget.identifier })
    if okOwned then push(lists.owned, owned) end

    local jobName = api.GetJob(xTarget)
    if type(jobName) == "string" and jobName ~= "" and jobName ~= "unemployed" then
        local okJob, jobRows = pcall(api.Query, [[
            SELECT * FROM owned_vehicles
            WHERE group_type = 'society' AND group_name = ?
            ORDER BY vehName ASC
        ]], { jobName })
        if okJob then push(lists.job, jobRows) end
    end

    local factionName = api.GetFaction(xTarget)
    if type(factionName) == "string" and factionName ~= "" then
        local okFaction, factionRows = pcall(api.Query, [[
            SELECT * FROM owned_vehicles
            WHERE group_type = 'faction' AND group_name = ?
            ORDER BY vehName ASC
        ]], { factionName })
        if okFaction then push(lists.faction, factionRows) end
    end

    return lists
end)

RegisterServerCallback("core:server:GetTypeVehicle", function(source, targetId, kind)
    local empty = { owned = {}, job = {}, faction = {} }
    if kind ~= "owned" and kind ~= "job" and kind ~= "faction" then return empty end

    local xPlayer = staffPlayer(source, "staff_menu")
    if not xPlayer then return empty end

    local id = tonumber(targetId)
    if not id then return empty end

    local xTarget = VFW.GetPlayerFromId(id)
    if not xTarget then return empty end

    local api = vehiclesApi()
    if not api then return empty end

    local lists = { owned = {}, job = {}, faction = {} }
    local properties = propertyPlates()
    local rows

    if kind == "owned" then
        local ok, result = pcall(api.Query, [[
            SELECT * FROM owned_vehicles
            WHERE owner = ? AND (group_type IS NULL OR group_type = '')
            ORDER BY vehName ASC
        ]], { xTarget.identifier })
        if ok then rows = result end
    elseif kind == "job" then
        local jobName = api.GetJob(xTarget)
        if type(jobName) == "string" and jobName ~= "" and jobName ~= "unemployed" then
            local ok, result = pcall(api.Query, [[
                SELECT * FROM owned_vehicles
                WHERE group_type = 'society' AND group_name = ?
                ORDER BY vehName ASC
            ]], { jobName })
            if ok then rows = result end
        end
    else
        local factionName = api.GetFaction(xTarget)
        if type(factionName) == "string" and factionName ~= "" then
            local ok, result = pcall(api.Query, [[
                SELECT * FROM owned_vehicles
                WHERE group_type = 'faction' AND group_name = ?
                ORDER BY vehName ASC
            ]], { factionName })
            if ok then rows = result end
        end
    end

    if type(rows) == "table" then
        for i = 1, #rows do
            local row = rows[i]
            local status = statusOf(row)
            if status == "sorti" and properties[row.plate] then status = "propriete" end
            lists[kind][#lists[kind] + 1] = {
                plate = row.plate,
                name = row.vehName or row.model or "",
                label = row.label or "",
                stored = status,
            }
        end
    end

    return lists
end)

RegisterServerCallback("vfw:staff:getPlayerVehiclesByUUID", function(source, uuid)
    local xPlayer = staffPlayer(source, "staff_vehicle_delete_bdd")
    if not xPlayer then return {} end
    if type(uuid) ~= "string" or uuid == "" or #uuid > 64 then return {} end

    local account = MySQL.single.await("SELECT id FROM users WHERE uuid = ?", { uuid })
    if not account then return {} end

    local characters = MySQL.query.await([[
        SELECT id, identifier, firstname, lastname FROM characters
        WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot ASC
    ]], { account.id }) or {}

    local properties = propertyPlates()
    local out = {}

    for i = 1, #characters do
        local character = characters[i]
        local rows = MySQL.query.await([[
            SELECT plate, vehName, model, label, stored, pounded FROM owned_vehicles
            WHERE owner = ? ORDER BY vehName ASC
        ]], { character.identifier }) or {}

        local vehicles = {}
        for j = 1, #rows do
            local row = rows[j]
            local status = statusOf(row)
            if status == "sorti" and properties[row.plate] then status = "propriete" end
            vehicles[#vehicles + 1] = {
                plate = row.plate,
                model = row.vehName ~= "" and row.vehName or row.model,
                status = status,
            }
        end

        out[#out + 1] = {
            name = ("%s %s"):format(character.firstname or "", character.lastname or ""),
            vehicles = vehicles,
        }
    end

    logStaff(source, "vehicle_lookup_uuid", { uuid = uuid, characters = #out })
    return out
end)

RegisterServerCallback("vfw:staff:assignSelfVehicle", function(source, plate, model, netId, props)
    local failure = { success = false }

    local xPlayer = staffPlayer(source, "alt_assign_vehicle")
    if not xPlayer then return failure end
    if not rateOk(source, "staff:assignVehicle", 1500) then return failure end

    local trimmed, normalized = plateForms(plate)
    if not trimmed then return failure end

    local cleaned = cleanModel(model)
    if not cleaned then return failure end

    local id = tonumber(netId)
    if not id or id <= 0 then return failure end

    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        notify(source, "ERROR", "Ce véhicule n'est pas synchronisé.")
        return failure
    end

    if GetEntityType(entity) ~= 2 then return failure end
    if not withinRange(source, entity, ASSIGN_RANGE) then
        notify(source, "ERROR", "Vous êtes trop loin de ce véhicule.")
        return failure
    end

    local _, entityNormalized = plateForms(GetVehicleNumberPlateText(entity))
    if entityNormalized ~= normalized then
        notify(source, "ERROR", "La plaque de ce véhicule ne correspond pas.")
        return failure
    end

    if joaat(cleaned) ~= GetEntityModel(entity) then
        notify(source, "ERROR", "Ce nom de modèle ne correspond pas au véhicule.")
        return failure
    end

    local api = vehiclesApi()
    if not api then return failure end

    if api.GetByPlate(normalized) or api.GetByPlate(trimmed) then
        notify(source, "ERROR", "Cette plaque est déjà enregistrée.")
        return failure
    end

    local safeProps = type(props) == "table" and props or {}
    safeProps.plate = normalized
    safeProps.model = joaat(cleaned)

    local engineHealth, bodyHealth, fuelLevel, turbo = api.ExtractHealth(safeProps, nil)

    local ok = pcall(MySQL.insert.await, [[
        INSERT INTO owned_vehicles
            (plate, owner, owner_charid, vehName, model, label, props, stored, pounded, engineHealth, bodyHealth, fuelLevel, modTurbo)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?)
    ]], {
        normalized,
        xPlayer.identifier,
        xPlayer.charId,
        cleaned,
        cleaned,
        cleaned,
        VFW.DB.Encode(safeProps),
        engineHealth,
        bodyHealth,
        fuelLevel,
        turbo and 1 or 0,
    })

    if not ok then
        notify(source, "ERROR", "Ce véhicule n'a pas pu être enregistré.")
        return failure
    end

    local state = Entity(entity).state
    state:set("OwnedVehicle", true, true)
    state:set("VehicleProperties", safeProps, true)

    notify(source, "SUCCESS", ("Le véhicule %s est enregistré à votre nom."):format(normalized))
    logStaff(source, "vehicle_assign_self", { plate = normalized, model = cleaned })

    return { success = true, plate = normalized, stored = "sorti", model = cleaned }
end)

RegisterServerCallback("vfw:vehicle:changePlate", function(source, oldPlate, newPlate)
    local xPlayer = staffPlayer(source, "change_plate")
    if not xPlayer then return false end
    if not rateOk(source, "staff:changePlate", 1000) then return false end

    local wantedTrimmed = plateForms(newPlate)
    if not wantedTrimmed or #wantedTrimmed > 8 then return false end
    if wantedTrimmed:match("^[A-Za-z0-9 ]+$") == nil then return false end

    local wanted = wantedTrimmed:upper()

    local row, currentTrimmed = findRow(oldPlate)
    if not row then return false end
    if wanted == row.plate then return false end

    local api = vehiclesApi()
    if not api then return false end
    if api.GetByPlate(wanted) or api.GetByPlate(wantedTrimmed) then return false end

    local props = type(row.props) == "table" and row.props or {}
    props.plate = wanted

    local ok = pcall(MySQL.update.await, "UPDATE owned_vehicles SET plate = ?, props = ? WHERE plate = ?", {
        wanted,
        VFW.DB.Encode(props),
        row.plate,
    })
    if not ok then return false end

    pcall(MySQL.update.await, "UPDATE concess_key_duplicates SET plate = ? WHERE plate = ?", { wanted, row.plate })
    pcall(MySQL.update.await, "UPDATE concess_key_duplicates SET plate = ? WHERE plate = ?", { wanted, currentTrimmed })
    pcall(MySQL.update.await, "UPDATE property_garage_vehicles SET plate = ? WHERE plate = ?", { wanted, row.plate })
    pcall(MySQL.update.await, "UPDATE property_garage_vehicles SET plate = ? WHERE plate = ?", { wanted, currentTrimmed })

    pushPropsToEntity(row.plate, props)

    logStaff(source, "vehicle_change_plate", { from = row.plate, to = wanted, owner = row.owner })
    return true
end)

--- Le joueur a-t-il les clés de ce véhicule ? (propriétaire, véhicule de son job / sa faction,
--- objet « keys », clé temporaire job / staff, double de clé concession). Un véhicule inconnu
--- de la base (PNJ, spawn staff) est considéré accessible à tous.
---@param source number
---@param plate string
---@return boolean
function Staff29.PlayerHasVehicleKey(source, plate)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local trimmed, normalized = plateForms(plate)
    if not trimmed then return false end

    local api = vehiclesApi()
    if not api then return false end

    local row = api.GetByPlate(normalized) or api.GetByPlate(trimmed)
    if not row then return true end

    if api.OwnsVehicle(xPlayer, row) then return true end

    local groupType = row.group_type
    if type(groupType) == "string" and groupType ~= "" then
        local groupName = tostring(row.group_name or "")
        if groupName ~= "" then
            if groupType == "society" and api.GetJob(xPlayer) == groupName then return true end
            if groupType ~= "society" then
                local factionName = api.GetFaction(xPlayer)
                if factionName ~= "" and factionName == groupName then return true end
            end
        end
    end

    local inventory = xPlayer.inventory
    if type(inventory) == "table" then
        for i = 1, #inventory do
            local entry = inventory[i]
            if entry.name == "keys" and type(entry.meta) == "table" then
                local owned = entry.meta.plate
                if owned == trimmed or owned == normalized then return true end
            end
        end
    end

    local state = Player(source).state
    if state["tempVehicleKey:" .. trimmed] ~= nil then return true end
    if state["tempVehicleKey:" .. normalized] ~= nil then return true end

    if Staff29 and type(Staff29.HasTemporaryVehicleKey) == "function" then
        if Staff29.HasTemporaryVehicleKey(trimmed, xPlayer.identifier) then return true end
        if Staff29.HasTemporaryVehicleKey(normalized, xPlayer.identifier) then return true end
    end

    local concess = VFW.Concess
    if concess and type(concess.HasKeyDuplicate) == "function" then
        if concess.HasKeyDuplicate(trimmed, xPlayer.identifier) then return true end
        if concess.HasKeyDuplicate(normalized, xPlayer.identifier) then return true end
    end

    return false
end
VFW.PlayerHasVehicleKey = Staff29.PlayerHasVehicleKey

RegisterServerCallback("vfw:context:hasVehicleKey", function(source, plate)
    return Staff29.PlayerHasVehicleKey(source, plate)
end)

RegisterServerCallback("vfw:staff:vehBlacklist:list", function(source)
    local xPlayer = staffPlayer(source, "dev_tools")
    if not xPlayer then return {} end
    return blacklistEntries()
end)

RegisterServerCallback("vfw:staff:vehBlacklist:add", function(source, model, reason)
    local xPlayer = staffPlayer(source, "dev_tools")
    if not xPlayer then return { success = false, message = "Vous n'avez pas la permission." } end

    local cleaned = cleanModel(model)
    if not cleaned then return { success = false, message = "Ce nom de modèle n'est pas valide." } end

    local text = ""
    if type(reason) == "string" then
        text = reason:gsub("[%z\1-\31]", ""):sub(1, MAX_REASON_LENGTH)
    end

    local list = blacklistEntries()
    for i = 1, #list do
        if list[i].model:lower() == cleaned then
            return { success = false, message = "Ce modèle est déjà bloqué." }
        end
    end

    list[#list + 1] = { model = cleaned, reason = text, added_by = xPlayer.name or "" }

    if not blacklistSave(list) then
        return { success = false, message = "La liste n'a pas pu être enregistrée." }
    end

    logStaff(source, "vehicle_blacklist_add", { model = cleaned, reason = text })
    return { success = true, message = ("Le modèle %s est bloqué."):format(cleaned) }
end)

RegisterServerCallback("vfw:staff:vehBlacklist:remove", function(source, model)
    local xPlayer = staffPlayer(source, "dev_tools")
    if not xPlayer then return { success = false, message = "Vous n'avez pas la permission." } end

    local cleaned = cleanModel(model)
    if not cleaned then return { success = false, message = "Ce nom de modèle n'est pas valide." } end

    local list = blacklistEntries()
    local kept = {}
    local removed = false

    for i = 1, #list do
        if list[i].model:lower() == cleaned then
            removed = true
        else
            kept[#kept + 1] = list[i]
        end
    end

    if not removed then
        return { success = false, message = "Ce modèle n'est pas dans la liste." }
    end

    if not blacklistSave(kept) then
        return { success = false, message = "La liste n'a pas pu être enregistrée." }
    end

    logStaff(source, "vehicle_blacklist_remove", { model = cleaned })
    return { success = true, message = ("Le modèle %s est débloqué."):format(cleaned) }
end)

RegisterNetEvent("vfw:staff:deleteVehicle", function(netId)
    local source = source
    local xPlayer = staffPlayer(source, "delete_veh")
    if not xPlayer then return end
    if not rateOk(source, "staff:deleteVehicle", 300) then return end

    local id = tonumber(netId)
    if not id or id <= 0 then return end

    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end
    if not withinRange(source, entity, CONTEXT_RANGE) then return end

    local plate = plateForms(GetVehicleNumberPlateText(entity))
    DeleteEntity(entity)

    logStaff(source, "vehicle_delete_entity", { plate = plate or "" })
end)

RegisterNetEvent("vfw:staff:menu:spawnVehicle", function(model)
    local source = source
    local xPlayer = staffPlayer(source, "spawn_veh")
    if not xPlayer then return end
    if not rateOk(source, "staff:menuSpawn", 1000) then return end

    local cleaned = cleanModel(model)
    if not cleaned then
        notify(source, "ERROR", "Ce modèle n'est pas valide.")
        return
    end

    if VFW.Vehicles.IsModelBlacklisted(cleaned) then
        notify(source, "ERROR", "Ce modèle est bloqué.")
        return
    end

    if not Feat27 or type(Feat27.SpawnVehicle) ~= "function" then return end

    local coords, heading = spawnAheadOf(source, 4.0)
    if not coords then return end

    local hash = joaat(cleaned)
    local vehicleType = VFW.GetVehicleType and VFW.GetVehicleType(hash, source) or "automobile"
    local netId, spawned = Feat27.SpawnVehicle(hash, coords, heading, vehicleType)

    if not netId then
        notify(source, "ERROR", "Ce véhicule n'a pas pu apparaître.")
        return
    end
    if VFW.MarkStaffVehicle then VFW.MarkStaffVehicle(spawned or NetworkGetEntityFromNetworkId(netId)) end

    notify(source, "SUCCESS", "Le véhicule est apparu.")
    logStaff(source, "vehicle_spawn_menu", { model = cleaned, coords = coords })
end)

RegisterNetEvent("vfw:staff:carlist:spawnVehicle", function(model, livery)
    local source = source
    local xPlayer = staffPlayer(source, "dev_tools")
    if not xPlayer then return end
    if not rateOk(source, "staff:carlistSpawn", 1000) then return end

    local cleaned = cleanModel(model)
    if not cleaned then return end

    if not carlistHasModel(cleaned) then
        notify(source, "ERROR", "Ce modèle ne fait pas partie du catalogue.")
        return
    end

    if VFW.Vehicles.IsModelBlacklisted(cleaned) then
        notify(source, "ERROR", "Ce modèle est bloqué.")
        return
    end

    if not Feat27 or type(Feat27.SpawnVehicle) ~= "function" then return end

    local coords, heading = spawnAheadOf(source, 6.0)
    if not coords then return end

    local hash = joaat(cleaned)
    local vehicleType = VFW.GetVehicleType and VFW.GetVehicleType(hash, source) or "automobile"
    local netId, vehicle = Feat27.SpawnVehicle(hash, coords, heading, vehicleType)

    if not netId then
        notify(source, "ERROR", "Ce véhicule n'a pas pu apparaître.")
        return
    end

    if VFW.MarkStaffVehicle then VFW.MarkStaffVehicle(vehicle or NetworkGetEntityFromNetworkId(netId)) end

    local index = tonumber(livery)
    if vehicle and DoesEntityExist(vehicle) and index and index >= 0 and index <= 64 then
        index = math.floor(index)
        Entity(vehicle).state:set("VehicleProperties", { modLivery = index, livery = index }, true)
    end

    notify(source, "SUCCESS", "Le véhicule est apparu.")
    logStaff(source, "vehicle_spawn_carlist", { model = cleaned, livery = index or 0 })
end)

RegisterNetEvent("vfw:staff:spawnVehicleForPlayer", function(targetId, plate)
    local source = source
    local xPlayer = staffPlayer(source, "staff_vehicle_spawn")
    if not xPlayer then return end
    if not rateOk(source, "staff:spawnForPlayer", 1000) then return end

    local id = tonumber(targetId)
    if not id then return end

    local xTarget = VFW.GetPlayerFromId(id)
    if not xTarget then
        notify(source, "ERROR", "Ce joueur n'est pas connecté.")
        return
    end

    spawnOwnedVehicle(source, xPlayer, plate, xTarget.source)
end)

RegisterNetEvent("vfw:staff:lookupSpawnVehicle", function(plate)
    local source = source
    local xPlayer = staffPlayer(source, "staff_vehicle_spawn")
    if not xPlayer then return end
    if not rateOk(source, "staff:lookupSpawn", 1000) then return end

    spawnOwnedVehicle(source, xPlayer, plate, source)
end)

RegisterNetEvent("vfw:staff:setVehicleState", function(plate, state, props)
    local source = source
    local xPlayer = staffPlayer(source, "staff_vehicle_state")
    if not xPlayer then return end
    if not rateOk(source, "staff:setVehicleState", 600) then return end

    applyVehicleState(source, xPlayer, plate, state, props, "vehicle_state")
end)

RegisterNetEvent("vfw:staff:lookupSetVehicleState", function(plate, state, props)
    local source = source
    local xPlayer = staffPlayer(source, "staff_vehicle_state")
    if not xPlayer then return end
    if not rateOk(source, "staff:lookupSetVehicleState", 600) then return end

    applyVehicleState(source, xPlayer, plate, state, props, "vehicle_state_lookup")
end)

RegisterNetEvent("vfw:staff:deleteSpawnedVehicle", function(plate)
    local source = source
    local xPlayer = staffPlayer(source, "staff_vehicle_delete_spawned")
    if not xPlayer then return end
    if not rateOk(source, "staff:deleteSpawned", 600) then return end

    local entity = findEntityByPlate(plate)
    if not entity or not DoesEntityExist(entity) then
        notify(source, "ERROR", "Aucun véhicule sorti ne porte cette plaque.")
        return
    end

    DeleteEntity(entity)

    local row = findRow(plate)
    if row and tonumber(row.pounded) ~= 1 then
        MySQL.update.await("UPDATE owned_vehicles SET stored = 1 WHERE plate = ?", { row.plate })
    end

    notify(source, "SUCCESS", "Le véhicule a été retiré de la carte.")
    logStaff(source, "vehicle_delete_spawned", { plate = row and row.plate or "" })
    refreshVehicleMenus(source, "garage")
end)

RegisterNetEvent("vfw:staff:transferVehicle", function(plate, targetId)
    local source = source
    local xPlayer = staffPlayer(source, "alt_give_vehicle")
    if not xPlayer then return end
    if not rateOk(source, "staff:transferVehicle", 1500) then return end

    transferOwnership(source, xPlayer, plate, targetId, "vehicle_transfer_menu")
end)

RegisterNetEvent("vfw:staff:saveVehicleCustom", function(plate, props)
    local source = source
    local xPlayer = staffPlayer(source, "staff_custom_permanent")
    if not xPlayer then return end
    if not rateOk(source, "staff:saveCustom", 800) then return end
    if type(props) ~= "table" then return end

    local row = findRow(plate)
    if not row then
        notify(source, "ERROR", "Ce véhicule n'est pas enregistré.")
        return
    end

    if not persistProps(row, props) then return end

    pushPropsToEntity(row.plate, props)

    notify(source, "SUCCESS", ("Les modifications du véhicule %s sont enregistrées."):format(row.plate))
    logStaff(source, "vehicle_save_custom", { plate = row.plate, owner = row.owner })
end)

RegisterNetEvent("vfw:staff:setTempCustom", function(plate, originalProps)
    local source = source
    local xPlayer = staffPlayer(source, "staff_custom")
    if not xPlayer then return end
    if not rateOk(source, "staff:setTempCustom", 800) then return end
    if type(originalProps) ~= "table" then return end

    local trimmed, normalized = plateForms(plate)
    if not trimmed then return end

    staffOriginalProps[normalized] = {
        props = originalProps,
        source = source,
        at = os.time(),
    }
end)

RegisterNetEvent("vfw:staff:removeVeh", function(plate)
    local source = source
    local xPlayer = staffPlayer(source, "staff_vehicle_delete_bdd")
    if not xPlayer then return end
    if not rateOk(source, "staff:removeVeh", 1000) then return end

    local row, trimmed = findRow(plate)
    if not row then
        notify(source, "ERROR", "Ce véhicule n'est pas enregistré.")
        return
    end

    local entity = findEntityByPlate(row.plate)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    MySQL.update.await("DELETE FROM owned_vehicles WHERE plate = ?", { row.plate })
    pcall(MySQL.update.await, "DELETE FROM concess_key_duplicates WHERE plate = ? OR plate = ?", { row.plate, trimmed })
    pcall(MySQL.update.await, "DELETE FROM property_garage_vehicles WHERE plate = ? OR plate = ?", { row.plate, trimmed })

    notify(source, "SUCCESS", ("Le véhicule %s est supprimé."):format(row.plate))
    logStaff(source, "vehicle_remove_db", { plate = row.plate, owner = row.owner, model = row.vehName })
end)

RegisterNetEvent("vfw:staff:openLockedTrunk", function(netId)
    local source = source
    local xPlayer = staffPlayer(source, "contextmenu")
    if not xPlayer then return end
    if not rateOk(source, "staff:openLockedTrunk", 800) then return end

    local id = tonumber(netId)
    if not id or id <= 0 then return end

    local entity = NetworkGetEntityFromNetworkId(id)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end
    if not withinRange(source, entity, CONTEXT_RANGE) then return end

    Entity(entity).state:set("doorsLocked", false, true)

    local plate = plateForms(GetVehicleNumberPlateText(entity))
    logStaff(source, "vehicle_unlock_trunk", { plate = plate or "" })
end)

AddEventHandler("vfw:playerDropped", function(source)
    for plate, entry in pairs(staffOriginalProps) do
        if entry.source == source then
            staffOriginalProps[plate] = nil
        end
    end
end)

local function registerContextActions()
    if type(VFW.ContextMenu) ~= "table" then return false end
    if type(VFW.ContextMenu.RegisterAction) ~= "function" then return false end

    local register = VFW.ContextMenu.RegisterAction

    register("vehicle:windowsOpenAll", contextRelay("vehicle:windowsOpenAll", "Fenêtres ouvertes"), "alt_vehicle_management")
    register("vehicle:windowsCloseAll", contextRelay("vehicle:windowsCloseAll", "Fenêtres fermées"), "alt_vehicle_management")
    register("vehicle:doorsOpenAll", contextRelay("vehicle:doorsOpenAll", "Portières ouvertes"), "alt_vehicle_management")
    register("vehicle:doorsCloseAll", contextRelay("vehicle:doorsCloseAll", "Portières fermées"), "alt_vehicle_management")
    register("vehicle:trunkToggle", contextRelay("vehicle:trunkToggle", "Coffre basculé"), "alt_vehicle_management")
    register("vehicle:engineToggle", contextRelay("vehicle:engineToggle", "Moteur basculé"), "alt_vehicle_management")
    register("vehicle:immobilizeToggle", contextRelay("vehicle:immobilizeToggle", "Immobilisation basculée"), "alt_vehicle_management")
    register("vehicle:flip180", contextRelay("vehicle:flip180", "Véhicule remis sur ses roues"), "alt_vehicle_management")
    register("vehicle:repair", contextRelay("vehicle:repair", "Véhicule réparé"), "alt_repair_vehicle")
    register("vehicle:clean", contextRelay("vehicle:clean", "Véhicule nettoyé"), "alt_repair_vehicle")
    register("vehicle:removeWheels", contextRelay("vehicle:removeWheels", "Roues retirées"), "devcontextmenu")
    register("vehicle:destroyEngine", contextRelay("vehicle:destroyEngine", "Moteur détruit"), "devcontextmenu")
    register("vehicle:soap", contextRelay("vehicle:soap", "Adhérence réduite pendant une minute"), "devcontextmenu")

    register("vehicle:doorToggle", function(source, ent, _, extra)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local door = tonumber(type(extra) == "table" and extra.door or nil)
        if not door or door < 0 or door > 5 then return { ok = false, err = "Cette portière n'existe pas." } end

        relayApply(source, "vehicle:doorToggle", entity, { door = math.floor(door) })
        return { ok = true, msg = "Portière basculée" }
    end, "alt_vehicle_management")

    register("vehicle:setAlpha", function(source, ent, _, extra)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local alpha = tonumber(type(extra) == "table" and extra.alpha or nil)
        if not alpha then return { ok = false, err = "Cette valeur n'est pas valide." } end
        alpha = math.floor(alpha)
        if alpha < 0 then alpha = 0 end
        if alpha > 255 then alpha = 255 end

        relayApply(source, "vehicle:setAlpha", entity, { alpha = alpha })
        return { ok = true, msg = alpha >= 255 and "Véhicule visible" or "Visibilité réduite" }
    end, "alt_vehicle_hide")

    register("vehicle:refuel", function(source, ent)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local state = Entity(entity).state
        state:set("fuel", 100.0, true)
        state:set("VehicleFuel", 100.0, true)
        relayApply(source, "vehicle:refuel", entity)

        return { ok = true, msg = "Plein effectué" }
    end, "alt_repair_vehicle")

    register("vehicle:delete", function(source, ent)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local plate = plateForms(GetVehicleNumberPlateText(entity))
        DeleteEntity(entity)

        logStaff(source, "vehicle_delete_entity", { plate = plate or "" })
        return { ok = true, msg = "Véhicule supprimé" }
    end, "alt_delete_entity")

    register("vehicle:lockToggle", function(source, ent)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local state = Entity(entity).state
        local locked = state.doorsLocked == true
        local newState = not locked
        state:set("doorsLocked", newState, true)

        local plate = plateForms(GetVehicleNumberPlateText(entity))
        TriggerEvent("vfw:vehicle:lockToggled", source, NetworkGetNetworkIdFromEntity(entity), newState)
        logStaff(source, "vehicle_lock_toggle", { plate = plate or "", locked = newState })

        return { ok = true, msg = newState and "Véhicule verrouillé" or "Véhicule déverrouillé" }
    end, "alt_vehicle_management")

    register("vehicle:getKeysTemp", function(source, ent, _, extra, xPlayer)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local plate = plateForms(GetVehicleNumberPlateText(entity))
        if not plate then return { ok = false, err = "La plaque de ce véhicule est illisible." } end

        local targetId = tonumber(type(extra) == "table" and (extra.targetId or extra.target) or nil) or source
        local xTarget = VFW.GetPlayerFromId(targetId)
        if not xTarget then return { ok = false, err = "Ce joueur n'est pas connecté." } end

        if not grantTemporaryKey(xTarget.source, plate, xTarget.identifier) then
            return { ok = false, err = "Les clés n'ont pas pu être remises." }
        end

        logStaff(source, "vehicle_keys_temp", { plate = plate, target = xTarget.source })

        if xTarget.source ~= source then
            notify(xTarget.source, "SUCCESS", ("Vous avez les clés du véhicule %s jusqu'au redémarrage."):format(plate))
            return { ok = true, msg = "Clés temporaires remises" }
        end

        return { ok = true, msg = "Clés temporaires obtenues" }
    end, "vehicle_keys_temp")

    register("vehicle:getKeys", function(source, ent, _, extra, xPlayer)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end

        local plate = plateForms(GetVehicleNumberPlateText(entity))
        if not plate then return { ok = false, err = "La plaque de ce véhicule est illisible." } end

        local row = findRow(plate)
        if not row then return { ok = false, err = "Ce véhicule n'est pas enregistré." } end

        local targetId = tonumber(type(extra) == "table" and (extra.targetId or extra.target) or nil) or source
        local xTarget = VFW.GetPlayerFromId(targetId)
        if not xTarget then return { ok = false, err = "Ce joueur n'est pas connecté." } end

        if not grantPermanentKey(row.plate, xTarget.identifier, xPlayer and xPlayer.identifier) then
            return { ok = false, err = "Les clés n'ont pas pu être remises." }
        end

        grantTemporaryKey(xTarget.source, plate, xTarget.identifier)
        logStaff(source, "vehicle_keys_permanent", { plate = row.plate, target = xTarget.source, owner = row.owner })

        if xTarget.source ~= source then
            notify(xTarget.source, "SUCCESS", ("Vous avez les clés du véhicule %s."):format(row.plate))
            return { ok = true, msg = "Clés permanentes remises" }
        end

        return { ok = true, msg = "Clés permanentes obtenues" }
    end, "vehicle_keys_permanent")

    register("vehicle:give", function(source, ent, _, extra, xPlayer)
        local entity = contextVehicle(source, ent)
        if not entity then return { ok = false, err = "Ce véhicule est trop loin." } end
        if type(extra) ~= "table" then return { ok = false, err = "Cet identifiant n'est pas valide." } end

        local plate = plateForms(GetVehicleNumberPlateText(entity))
        if not plate then return { ok = false, err = "La plaque de ce véhicule est illisible." } end

        local ok = transferOwnership(source, xPlayer, plate, extra.targetId, "vehicle_transfer_context")
        if not ok then return { ok = false, err = "Le transfert n'a pas abouti." } end

        return { ok = true, msg = "Véhicule transféré" }
    end, "alt_give_vehicle")

    return true
end

CreateThread(function()
    for _ = 1, 100 do
        if registerContextActions() then return end
        Wait(100)
    end
end)
