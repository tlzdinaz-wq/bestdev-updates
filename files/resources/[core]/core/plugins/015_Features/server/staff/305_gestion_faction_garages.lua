local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("gestion_faction")
        or xPlayer.hasPermission("manage_garages")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function factionsCatalog()
    local rows = MySQL.query.await([[
        SELECT name, label FROM crews
        WHERE name NOT IN ('nocrew', 'nofaction')
        ORDER BY label ASC
    ]]) or {}
    local out = {}
    for i = 1, #rows do
        local name = tostring(rows[i].name or "")
        if name ~= "" then
            out[#out + 1] = {
                name = name,
                label = tostring(rows[i].label or name),
            }
        end
    end
    return out
end

local function factionLabelOf(name, catalog)
    if type(name) ~= "string" or name == "" then return "" end
    for i = 1, #(catalog or {}) do
        if catalog[i].name == name then
            return catalog[i].label or name
        end
    end
    return name
end

local function flattenGarages(catalog)
    local Garages = VFW.Garages
    local out = {}
    if not Garages or type(Garages.list) ~= "table" then return out end

    for _, garage in pairs(Garages.list) do
        if garage and (garage.type == "faction" or garage.type == "gang") then
            local access = type(garage.access) == "table" and garage.access or {}
            local faction = tostring(access.name or "")
            local spawns = type(garage.spawnPosition) == "table" and garage.spawnPosition or {}
            out[#out + 1] = {
                id = garage.id,
                name = garage.name,
                type = garage.type,
                vehType = tonumber(garage.vehType) or 1,
                position = garage.position,
                spawnPosition = spawns,
                deletePosition = garage.deletePosition,
                secondaryGarage = garage.secondaryGarage == true,
                access = access,
                faction = faction,
                factionLabel = factionLabelOf(faction, catalog),
                spawnCount = #spawns,
            }
        end
    end

    table.sort(out, function(a, b)
        return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
    end)
    return out
end

local function groupVehicles(garageId)
    local Garages = VFW.Garages
    local Vehicles = VFW.Vehicles
    local id = tonumber(garageId)
    if not id or not Garages or not Vehicles then return {} end

    local garage = Garages.Get(id)
    if not garage then return {} end

    local groupType, groupName = Vehicles.GarageGroup(garage)
    if not groupType then return {} end

    local rows = Vehicles.Query([[
        SELECT plate, vehName, model, label FROM owned_vehicles
        WHERE group_type = ? AND group_name = ? AND garage_id = ? AND pounded = 0
        ORDER BY label ASC, plate ASC
    ]], { groupType, groupName, id }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local model = tostring(row.model or row.vehName or "")
        out[#out + 1] = {
            plate = row.plate,
            vehName = row.vehName or model,
            model = model,
            label = row.label or row.vehName or model,
        }
    end
    return out
end

local function hubPanel(selectedId)
    local catalog = factionsCatalog()
    local garages = flattenGarages(catalog)
    local selected = nil
    local sid = tonumber(selectedId)
    if sid then
        for i = 1, #garages do
            if tonumber(garages[i].id) == sid then
                selected = garages[i]
                break
            end
        end
        if selected then
            selected.vehicles = groupVehicles(sid)
        end
    end
    return {
        ok = true,
        garages = garages,
        factions = catalog,
        selected = selected,
    }
end

local function buildPayload(data, catalog)
    if type(data) ~= "table" then return nil, "Données invalides." end

    local faction = tostring(data.faction or (type(data.access) == "table" and data.access.name) or "")
    if faction == "" then
        return nil, "Choisissez une faction."
    end

    local payload = {
        id = tonumber(data.id),
        name = data.name,
        type = "faction",
        vehType = tonumber(data.vehType) or 1,
        position = data.position,
        spawnPosition = data.spawnPosition,
        deletePosition = data.deletePosition,
        secondaryGarage = data.secondaryGarage == true or tonumber(data.secondaryGarage) == 1,
        access = {
            name = faction,
            label = factionLabelOf(faction, catalog),
            rank = 98,
        },
    }

    local sanitized = VFW.Garages.Sanitize(payload, "faction")
    if not sanitized then
        return nil, "Définissez le nom et les 3 positions (entrée, spawn, suppression)."
    end
    return sanitized
end

RegisterServerCallback("gestionFactionGarages:hubPanel", function(source, selectedId)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." }
    end
    return hubPanel(selectedId)
end)

RegisterServerCallback("gestionFactionGarages:create", function(source, data)
    local xPlayer = staffOk(source)
    if not xPlayer then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." }
    end

    local Garages = VFW.Garages
    if not Garages then
        return { ok = false, error = "Garages indisponibles." }
    end

    local catalog = factionsCatalog()
    local sanitized, err = buildPayload(data, catalog)
    if not sanitized then
        return { ok = false, error = err }
    end
    if not Garages.CanEdit(xPlayer, sanitized.type) then
        return { ok = false, error = "Vous n'avez pas la permission de créer ce garage." }
    end

    local id = Garages.Insert(sanitized)
    if not id then
        return { ok = false, error = "Création du garage impossible." }
    end

    if type(data) == "table" and type(data.vehicles) == "table" then
        for i = 1, #data.vehicles do
            local veh = data.vehicles[i]
            if type(veh) == "table" then
                Garages.AddGroupVehicle(source, id, veh.model, veh.label, "faction")
            end
        end
    end

    Garages.SendGarageEvent("garage:add:list", id, sanitized)
    return hubPanel(id)
end)

RegisterServerCallback("gestionFactionGarages:update", function(source, data)
    local xPlayer = staffOk(source)
    if not xPlayer then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." }
    end

    local Garages = VFW.Garages
    if not Garages or type(data) ~= "table" then
        return { ok = false, error = "Mise à jour impossible." }
    end

    local garageId = tonumber(data.id)
    local existing = garageId and Garages.Get(garageId) or nil
    if not existing then
        return { ok = false, error = "Garage introuvable." }
    end
    if not Garages.CanEdit(xPlayer, existing.type) then
        return { ok = false, error = "Vous n'avez pas la permission de modifier ce garage." }
    end

    local sanitized, err = buildPayload(data, factionsCatalog())
    if not sanitized then
        return { ok = false, error = err }
    end

    sanitized.id = garageId
    Garages.Update(garageId, sanitized)

    if existing.type ~= sanitized.type or (existing.access and existing.access.name) ~= (sanitized.access and sanitized.access.name) then
        TriggerClientEvent("garage:delete:list", -1, garageId)
    end
    Garages.SendGarageEvent("garage:modify:list", garageId, sanitized)
    return hubPanel(garageId)
end)

RegisterServerCallback("gestionFactionGarages:delete", function(source, data)
    local xPlayer = staffOk(source)
    if not xPlayer then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." }
    end

    local Garages = VFW.Garages
    local garageId = tonumber(type(data) == "table" and data.id or data)
    local garage = Garages and garageId and Garages.Get(garageId) or nil
    if not garage then
        return { ok = false, error = "Garage introuvable." }
    end
    if not Garages.CanEdit(xPlayer, garage.type) then
        return { ok = false, error = "Vous n'avez pas la permission de supprimer ce garage." }
    end

    Garages.Delete(garageId)
    TriggerClientEvent("garage:delete:list", -1, garageId)
    return hubPanel()
end)

RegisterServerCallback("gestionFactionGarages:addVehicle", function(source, data)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." }
    end
    if type(data) ~= "table" then
        return { ok = false, error = "Véhicule invalide." }
    end

    local added = VFW.Garages.AddGroupVehicle(source, data.id, data.model, data.label, "faction")
    if not added then
        return { ok = false, error = "Impossible d'ajouter ce véhicule." }
    end
    return hubPanel(data.id)
end)

RegisterServerCallback("gestionFactionGarages:removeVehicle", function(source, data)
    if not staffOk(source) then
        return { ok = false, error = "Vous n'avez pas la permission de gérer les garages de faction." }
    end
    if type(data) ~= "table" then
        return { ok = false, error = "Véhicule invalide." }
    end

    local ok = VFW.Garages.RemoveGroupVehicle(source, data.plate, data.id)
    if not ok then
        return { ok = false, error = "Impossible de retirer ce véhicule." }
    end
    return hubPanel(data.id)
end)
