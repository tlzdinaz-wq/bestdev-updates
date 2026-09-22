local Garages = VFW.Garages
local Vehicles = VFW.Vehicles

local exiting = {}

local function repairPrice()
    return (GarageConfig and GarageConfig.RepairPrice) or 1000
end

local function pickSpawnCoords(garage, requested)
    if type(requested) == "table" and tonumber(requested.x) and tonumber(requested.y) and tonumber(requested.z) then
        local candidate = {
            x = tonumber(requested.x) + 0.0,
            y = tonumber(requested.y) + 0.0,
            z = tonumber(requested.z) + 0.0,
            w = tonumber(requested.w) or 0.0,
        }

        local spawns = garage and garage.spawnPosition or nil
        if type(spawns) == "table" and #spawns > 0 then
            for i = 1, #spawns do
                if Vehicles.Distance(candidate, spawns[i]) < 6.0 then
                    return candidate
                end
            end
            local fallback = spawns[1]
            return {
                x = tonumber(fallback.x) + 0.0,
                y = tonumber(fallback.y) + 0.0,
                z = tonumber(fallback.z) + 0.0,
                w = tonumber(fallback.w) or 0.0,
            }
        end

        return candidate
    end

    local spawns = garage and garage.spawnPosition or nil
    if type(spawns) == "table" and spawns[1] then
        local fallback = spawns[1]
        return {
            x = tonumber(fallback.x) + 0.0,
            y = tonumber(fallback.y) + 0.0,
            z = tonumber(fallback.z) + 0.0,
            w = tonumber(fallback.w) or 0.0,
        }
    end
end

RegisterNetEvent("garage:exitVehicle", function(garageId, plate, spawnCoords, repair)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(garageId)
    if not id then return end

    local garage = Garages.Get(id)
    if not garage then return end

    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return end

    if exiting[normalized] then return end
    exiting[normalized] = true
    SetTimeout(3000, function()
        exiting[normalized] = nil
    end)

    if not Vehicles.HasGarageAccess(xPlayer, garage) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Vous n'avez pas accès à ce garage.")
        return
    end

    local row = Vehicles.GetByPlate(normalized)
    if not row then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule est introuvable.")
        return
    end

    if not Vehicles.CanUseVehicle(xPlayer, row, garage) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule ne vous appartient pas.")
        return
    end

    if row.pounded == 1 then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule est en fourrière.")
        return
    end

    local rowGarageId = tonumber(row.garage_id)
    local orphanAtPublic = rowGarageId == nil and garage.type == "public"
    if rowGarageId ~= id and not orphanAtPublic then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule n'est pas rangé dans ce garage.")
        return
    end

    if row.stored ~= 1 then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule est déjà sorti.")
        return
    end

    local coords = pickSpawnCoords(garage, spawnCoords)
    if not coords then
        Vehicles.Notify(source, "ROUGE", "Garage", "Aucune place de spawn disponible.")
        return
    end

    local doRepair = false
    if repair == true then
        if row.engineHealth <= 300.0 or row.bodyHealth <= 300.0 then
            local price = repairPrice()
            local ok = Vehicles.Charge(xPlayer, "bank", price, "garage-reparation")
            if not ok then
                ok = Vehicles.Charge(xPlayer, "cash", price, "garage-reparation")
            end
            if not ok then
                Vehicles.Notify(source, "ROUGE", "Garage", "Fonds insuffisants pour la réparation.")
                return
            end
            doRepair = true
            row.engineHealth = 1000.0
            row.bodyHealth = 1000.0
        end
    end

    Vehicles.DeleteByPlate(normalized)

    local props = Vehicles.BuildProps(row)
    local vehicle, netId = Vehicles.Spawn(source, row.vehName, coords, coords.w, props)
    if not vehicle or not netId then
        Vehicles.Notify(source, "ROUGE", "Garage", "Impossible de faire sortir le véhicule.")
        return
    end

    MySQL.update.await([[
        UPDATE owned_vehicles SET stored = 0, engineHealth = ?, bodyHealth = ? WHERE plate = ?
    ]], { row.engineHealth, row.bodyHealth, normalized })

    TriggerClientEvent("garage:placeVehicleOnGround", source, netId)
    if doRepair then
        TriggerClientEvent("vfw:repairVehicle", source, netId)
    end
end)

RegisterNetEvent("garage:storeVehicle", function(garageId, props)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(garageId)
    if not id then return end

    local garage = Garages.Get(id)
    if not garage then return end

    if type(props) ~= "table" then return end

    local normalized = Vehicles.NormalizePlate(props.plate)
    if not normalized then return end

    if not Vehicles.HasGarageAccess(xPlayer, garage) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Vous n'avez pas accès à ce garage.")
        return
    end

    local row = Vehicles.GetByPlate(normalized)
    if not row then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule n'est pas immatriculé.")
        return
    end

    if not Vehicles.CanUseVehicle(xPlayer, row, garage) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule ne vous appartient pas.")
        return
    end

    local isGroupVehicle = row.group_type ~= nil and row.group_type ~= ""
    if not isGroupVehicle and Vehicles.IsGroupGarage(garage) and not garage.secondaryGarage then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce garage n'accepte pas les véhicules personnels.")
        return
    end

    local playerCoords = Vehicles.PlayerCoords(source)
    if playerCoords and type(garage.deletePosition) == "table" and tonumber(garage.deletePosition.x) then
        if Vehicles.Distance(playerCoords, garage.deletePosition) > 40.0 then
            Vehicles.Notify(source, "ROUGE", "Garage", "Vous êtes trop loin du garage.")
            return
        end
    end

    local engineHealth, bodyHealth, fuelLevel, turbo = Vehicles.ExtractHealth(props, row)

    props.plate = normalized

    local entity = nil
    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        local inVehicle = GetVehiclePedIsIn(ped)
        if inVehicle and inVehicle ~= 0 and DoesEntityExist(inVehicle) then
            local entityPlate = Vehicles.NormalizePlate(GetVehicleNumberPlateText(inVehicle) or "")
            if entityPlate == normalized then
                entity = inVehicle
            end
        end
    end

    if not entity then
        Vehicles.Notify(source, "ROUGE", "Garage", "Vous devez être dans ce véhicule pour le ranger.")
        return
    end

    props.model = GetEntityModel(entity)
    DeleteEntity(entity)

    MySQL.update.await([[
        UPDATE owned_vehicles SET props = ?, garage_id = ?, stored = 1, pounded = 0, pound_id = NULL,
        engineHealth = ?, bodyHealth = ?, fuelLevel = ?, modTurbo = ? WHERE plate = ?
    ]], {
        VFW.DB.Encode(props),
        id,
        engineHealth,
        bodyHealth,
        fuelLevel,
        turbo and 1 or 0,
        normalized,
    })

    Vehicles.Notify(source, "VERT", "Garage", "Véhicule rangé.")
end)

RegisterNetEvent("garage:changeVehicleOwner", function(plate, targetServerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return end

    local targetId = tonumber(targetServerId)
    if not targetId then return end

    local xTarget = VFW.GetPlayerFromId(targetId)
    if not xTarget then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce joueur n'est pas connecté.")
        return
    end

    if xTarget.source == xPlayer.source then return end

    local ownerCoords = Vehicles.PlayerCoords(source)
    local targetCoords = Vehicles.PlayerCoords(xTarget.source)
    if not ownerCoords or not targetCoords or Vehicles.Distance(ownerCoords, targetCoords) > 8.0 then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce joueur est trop loin de vous.")
        return
    end

    local row = Vehicles.GetByPlate(normalized)
    if not row then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule est introuvable.")
        return
    end

    if not Vehicles.OwnsVehicle(xPlayer, row) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule ne vous appartient pas.")
        return
    end

    if tonumber(row.stored) ~= 1 then
        Vehicles.Notify(source, "ROUGE", "Garage", "Le véhicule doit être rangé au garage.")
        return
    end

    MySQL.update.await([[
        UPDATE owned_vehicles SET owner = ?, owner_charid = ? WHERE plate = ?
    ]], { xTarget.identifier, xTarget.charId, normalized })

    Vehicles.Notify(source, "VERT", "Garage", ("Véhicule %s transféré."):format(normalized))
    Vehicles.Notify(xTarget.source, "VERT", "Garage", ("Vous avez reçu le véhicule %s."):format(normalized))
end)

RegisterNetEvent("garage:attributeVehicleToSociety", function(plate, garageId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local normalized = Vehicles.NormalizePlate(plate)
    if not normalized then return end

    local id = tonumber(garageId)
    if not id then return end

    local garage = Garages.Get(id)
    if not garage then return end

    local groupType, groupName = Vehicles.GarageGroup(garage)
    if not groupType then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce garage n'appartient à aucun groupe.")
        return
    end

    if not Vehicles.CanManageGarage(xPlayer, garage) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Vous n'avez pas le grade requis.")
        return
    end

    local row = Vehicles.GetByPlate(normalized)
    if not row then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule est introuvable.")
        return
    end

    if not Vehicles.OwnsVehicle(xPlayer, row) then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule ne vous appartient pas.")
        return
    end

    if row.pounded == 1 then
        Vehicles.Notify(source, "ROUGE", "Garage", "Ce véhicule est en fourrière.")
        return
    end

    Vehicles.DeleteByPlate(normalized)

    MySQL.update.await([[
        UPDATE owned_vehicles SET group_type = ?, group_name = ?, garage_id = ?, stored = 1 WHERE plate = ?
    ]], { groupType, groupName, id, normalized })

    Vehicles.Notify(source, "VERT", "Garage", "Véhicule attribué au groupe.")
end)

RegisterNetEvent("garage:removeVehicleFromGroup", function(plate, garageId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if type(plate) ~= "string" then return end

    local ok = Garages.RemoveGroupVehicle(source, plate, garageId)
    if ok then
        Vehicles.Notify(source, "VERT", "Garage", "Véhicule retiré du groupe.")
    else
        Vehicles.Notify(source, "ROUGE", "Garage", "Impossible de retirer ce véhicule.")
    end
end)

local function createGarageFromPayload(source, payload)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable." end

    local data = Garages.Sanitize(payload)
    if not data then
        return false, "Ces données de garage ne sont pas valides."
    end

    if not Garages.CanEdit(xPlayer, data.type) then
        return false, "Vous n'avez pas la permission de créer ce garage."
    end

    local id = Garages.Insert(data)
    if not id then
        return false, "Création du garage impossible."
    end

    if type(payload) == "table" and type(payload.vehicles) == "table" then
        local expectedKind = data.type == "society" and "society" or ((data.type == "faction" or data.type == "gang") and "faction" or nil)
        if expectedKind and Garages.AddGroupVehicle then
            for i = 1, #payload.vehicles do
                local vehicle = payload.vehicles[i]
                if type(vehicle) == "table" then
                    Garages.AddGroupVehicle(source, id, vehicle.model or vehicle.vehName or vehicle.name, vehicle.label, expectedKind)
                end
            end
        end
    end

    Garages.SendGarageEvent("garage:add:list", id, data)
    return true, id
end

RegisterNetEvent("core:createGarage", function(payload)
    local source = source
    local ok, result = createGarageFromPayload(source, payload)
    if not ok then
        Vehicles.Notify(source, "ROUGE", "Garage", result or "Création du garage impossible.")
        return
    end

    Vehicles.Notify(source, "VERT", "Garage", "Garage créé.")
end)

RegisterServerCallback("core:createGarage", function(source, payload)
    local ok, result = createGarageFromPayload(source, payload)
    if not ok then
        return { ok = false, error = result or "Création du garage impossible." }
    end

    return { ok = true, id = result }
end)

RegisterNetEvent("core:deleteGarage", function(garageId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local id = tonumber(garageId)
    if not id then return end

    local garage = Garages.Get(id)
    if not garage then return end

    if not Garages.CanEdit(xPlayer, garage.type) then return end

    Garages.Delete(id)
    TriggerClientEvent("garage:delete:list", -1, id)
    Vehicles.Notify(source, "VERT", "Garage", "Garage supprimé.")
end)

AddEventHandler("vfw:playerLoaded", function(playerSource)
    CreateThread(function()
        local waited = 0
        while not VFW.Garages.loaded and waited < 20000 do
            Wait(250)
            waited = waited + 250
        end

        if not VFW.GetPlayerFromId(playerSource) then return end

        TriggerClientEvent("garage:retrieve:list", playerSource, Garages.BuildRetrievePayload())
        TriggerClientEvent("garage:labelOverride:sync", playerSource, Garages.labelOverrides or {})
    end)
end)

AddEventHandler("vfw:setJob", function(playerSource, job, previous)
    local previousName = type(previous) == "table" and previous.name or nil
    local newName = type(job) == "table" and job.name or nil
    if previousName == newName then return end

    TriggerClientEvent("garage:onGroupChange", playerSource, Garages.BuildGroupPayload(newName), previousName or "")
end)
