local Garages = VFW.Garages
local Vehicles = VFW.Vehicles

local function toGarageRow(row)
    return {
        plate = row.plate,
        vehName = row.vehName,
        engineHealth = row.engineHealth,
        bodyHealth = row.bodyHealth,
        fuelLevel = row.fuelLevel,
        pounded = row.pounded == 1,
        stored = row.stored == 1,
        props = row.props,
    }
end

local function fetchPrivateVehicles(xPlayer, garageId, adoptOrphans)
    local query = [[
        SELECT * FROM owned_vehicles
        WHERE owner = ? AND (group_type IS NULL OR group_type = '')
          AND garage_id = ? AND stored = 1 AND pounded = 0
    ]]

    if adoptOrphans then
        query = [[
            SELECT * FROM owned_vehicles
            WHERE owner = ? AND (group_type IS NULL OR group_type = '')
              AND (garage_id = ? OR garage_id IS NULL) AND stored = 1 AND pounded = 0
        ]]
    end

    local rows = Vehicles.Query(query, { xPlayer.identifier, garageId })

    local out = {}
    for i = 1, #rows do
        out[#out + 1] = toGarageRow(rows[i])
    end
    return out
end

local function fetchGroupVehicles(garage, garageId)
    local groupType, groupName = Vehicles.GarageGroup(garage)
    if not groupType then return {} end

    local rows = Vehicles.Query([[
        SELECT * FROM owned_vehicles
        WHERE group_type = ? AND group_name = ? AND garage_id = ? AND pounded = 0
    ]], { groupType, groupName, garageId })

    local out = {}
    for i = 1, #rows do
        out[#out + 1] = toGarageRow(rows[i])
    end
    return out
end

RegisterServerCallback("garage:getGarageData", function(source, garageId)
    local repairPrice = (GarageConfig and GarageConfig.RepairPrice) or 1000
    local empty = { privateVehicles = {}, groupVehicles = {}, canManage = false }

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return empty, repairPrice end

    local id = tonumber(garageId)
    if not id then return empty, repairPrice end

    local garage = Garages.Get(id)
    if not garage then return empty, repairPrice end

    if not Vehicles.HasGarageAccess(xPlayer, garage) then
        return empty, repairPrice
    end

    local privateVehicles = {}
    if not Vehicles.IsGroupGarage(garage) or garage.secondaryGarage then
        local ok, result = pcall(fetchPrivateVehicles, xPlayer, id, garage.type == "public")
        if ok and type(result) == "table" then
            privateVehicles = result
        else
            console.error(("garage:getGarageData privateVehicles: %s"):format(tostring(result)))
        end
    end

    local groupVehicles = {}
    local okGroup, groupResult = pcall(fetchGroupVehicles, garage, id)
    if okGroup and type(groupResult) == "table" then
        groupVehicles = groupResult
    else
        console.error(("garage:getGarageData groupVehicles: %s"):format(tostring(groupResult)))
    end

    return {
        privateVehicles = privateVehicles,
        groupVehicles = groupVehicles,
        canManage = Vehicles.CanManageGarage(xPlayer, garage),
    }, repairPrice
end)

RegisterServerCallback("garage:getAllPlayerVehicles", function(source, garageId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local ok, rows = pcall(Vehicles.Query, [[
        SELECT * FROM owned_vehicles
        WHERE owner = ? AND (group_type IS NULL OR group_type = '') AND pounded = 0
        ORDER BY vehName ASC
    ]], { xPlayer.identifier })

    if not ok or type(rows) ~= "table" then
        console.error(("garage:getAllPlayerVehicles: %s"):format(tostring(rows)))
        return {}
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local entry = toGarageRow(row)
        entry.label = row.label
        out[#out + 1] = entry
    end

    return out
end)

RegisterServerCallback("garage:labelOverride:getAll", function(source)
    if not Garages.loaded then
        Garages.LoadLabelOverrides()
    end
    return Garages.labelOverrides or {}
end)

RegisterServerCallback("garage:labelOverride:set", function(source, model, label)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_garages") then return false end
    if type(model) ~= "string" or type(label) ~= "string" then return false end

    local key = model:lower():gsub("%s+", "")
    if key == "" or #key > 64 then return false end

    local value = label:sub(1, 128)
    if value == "" then return false end

    MySQL.update.await([[
        INSERT INTO vehicle_label_overrides (model, label) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label)
    ]], { key, value })

    Garages.labelOverrides[key] = value
    TriggerClientEvent("garage:labelOverride:set", -1, key, value)
    return true
end)

RegisterServerCallback("garage:labelOverride:delete", function(source, model)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("manage_garages") then return false end
    if type(model) ~= "string" then return false end

    local key = model:lower():gsub("%s+", "")
    if key == "" then return false end

    MySQL.update.await("DELETE FROM vehicle_label_overrides WHERE model = ?", { key })
    Garages.labelOverrides[key] = nil
    TriggerClientEvent("garage:labelOverride:delete", -1, key)
    return true
end)

RegisterServerCallback("core:getAllGarages", function(source, garageType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    garageType = type(garageType) == "string" and garageType or "public"

    if not Garages.CanEdit(xPlayer, garageType) then return {} end

    if garageType == "public" then
        local out = {}
        for id, garage in pairs(Garages.list) do
            if garage.type == "public" then
                out[id] = Garages.Serialize(garage)
            end
        end
        return out
    end

    local wanted = { society = true }
    if garageType == "faction" or garageType == "gang" then
        wanted = { faction = true, gang = true }
    end

    local out = {}
    for id, garage in pairs(Garages.list) do
        if wanted[garage.type] and garage.access and garage.access.name then
            local groupName = garage.access.name
            out[groupName] = out[groupName] or {}
            out[groupName][id] = Garages.Serialize(garage)
        end
    end
    return out
end)

RegisterServerCallback("core:updateGarage", function(source, id, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local garageId = tonumber(id)
    if not garageId then return false end

    local existing = Garages.Get(garageId)
    if not existing then return false end

    if not Garages.CanEdit(xPlayer, existing.type) then return false end

    local data = Garages.Sanitize(payload, existing.type)
    if not data then return false end
    if not Garages.CanEdit(xPlayer, data.type) then return false end

    data.id = garageId
    Garages.Update(garageId, data)

    if existing.type ~= data.type or (existing.access and existing.access.name) ~= (data.access and data.access.name) then
        TriggerClientEvent("garage:delete:list", -1, garageId)
    end

    Garages.SendGarageEvent("garage:modify:list", garageId, data)
    return true
end)

RegisterServerCallback("garage:addVehicleToGarageSociety", function(source, garageId, vehModel, vehLabel)
    return VFW.Garages.AddGroupVehicle(source, garageId, vehModel, vehLabel, "society")
end)

RegisterServerCallback("garage:addVehicleToGarageFaction", function(source, garageId, vehModel, vehLabel)
    return VFW.Garages.AddGroupVehicle(source, garageId, vehModel, vehLabel, "faction")
end)

RegisterServerCallback("garage:removeVehicleFromSociety", function(source, plate, garageId)
    return VFW.Garages.RemoveGroupVehicle(source, plate, garageId)
end)

RegisterServerCallback("garage:removeVehicleFromFaction", function(source, plate, garageId)
    return VFW.Garages.RemoveGroupVehicle(source, plate, garageId)
end)

function Garages.AddGroupVehicle(source, garageId, vehModel, vehLabel, expectedKind)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(vehModel) ~= "string" or vehModel == "" then return false end
    if type(vehLabel) ~= "string" or vehLabel == "" then return false end

    local id = tonumber(garageId)
    if not id then return false end

    local garage = Garages.Get(id)
    if not garage then return false end

    local groupType, groupName = Vehicles.GarageGroup(garage)
    if not groupType then return false end
    if expectedKind == "society" and groupType ~= "society" then return false end
    if expectedKind == "faction" and groupType ~= "faction" then return false end

    if not Garages.CanEdit(xPlayer, garage.type) and not Vehicles.CanManageGarage(xPlayer, garage) then
        return false
    end

    local model = vehModel:lower():gsub("%s+", "")
    if model == "" or #model > 64 then return false end

    local plate = Vehicles.GeneratePlate()
    local label = vehLabel:sub(1, 96)

    MySQL.insert.await([[
        INSERT INTO owned_vehicles (plate, owner, owner_charid, vehName, model, label, props, garage_id, stored, pounded,
        engineHealth, bodyHealth, fuelLevel, modTurbo, group_type, group_name)
        VALUES (?, '', NULL, ?, ?, ?, ?, ?, 1, 0, 1000, 1000, 100, 0, ?, ?)
    ]], {
        plate,
        model,
        model,
        label,
        VFW.DB.Encode({ plate = plate, model = joaat(model), engineHealth = 1000.0, bodyHealth = 1000.0, fuelLevel = 100.0 }),
        id,
        groupType,
        groupName,
    })

    return { plate = plate, vehName = model, label = label, name = model }
end

function Garages.RemoveGroupVehicle(source, plate, garageId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return false end

    local id = tonumber(garageId)
    local garage = id and Garages.Get(id) or nil

    local row = Vehicles.GetByPlate(normalized)
    if not row then return false end
    if not row.group_type or row.group_type == "" then return false end

    if garage then
        local groupType, groupName = Vehicles.GarageGroup(garage)
        if not groupType or row.group_type ~= groupType or row.group_name ~= groupName then
            return false
        end
        if not Garages.CanEdit(xPlayer, garage.type) and not Vehicles.CanManageGarage(xPlayer, garage) then
            return false
        end
    elseif not xPlayer.hasPermission("manage_garages") and not xPlayer.hasPermission("gestion_faction") then
        return false
    end

    Vehicles.DeleteByPlate(normalized)

    if row.owner and row.owner ~= "" then
        MySQL.update.await([[
            UPDATE owned_vehicles SET group_type = NULL, group_name = NULL, garage_id = NULL, stored = 1
            WHERE plate = ?
        ]], { normalized })
    else
        MySQL.update.await("DELETE FROM owned_vehicles WHERE plate = ?", { normalized })
    end

    return true
end
