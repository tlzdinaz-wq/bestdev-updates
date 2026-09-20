local emergencyVehicles = {}
local tempKeys = {}

local NUMERIC_KEYS = {
    "monthlyCoins", "hourlyCoins", "inventoryWeight", "stateAid", "impoundDiscount",
    "trunkBonus", "dynastyBonus", "propsPermanent", "propsTemporary", "respawnTime",
    "interimMultiplier", "gofastMultiplier", "drugDealingMultiplier", "ppaLeger", "ppaLourd",
    "plate_changes_per_month", "driftMode", "weaponCustomization", "freecam",
}

local function defaultTierConfig(tier)
    local props = VIPConfig.GetPropsLimits(tier) or { permanent = 0, temporary = 0 }
    local emergency = VIPConfig.EmergencyVehicle[tier]
    local minTier = 1

    return {
        inventoryWeight = VIPConfig.GetInventoryWeight(tier),
        stateAid = VIPConfig.GetStateAidAmount(tier),
        hourlyCoins = VIPConfig.GetHourlyCoins(tier),
        monthlyCoins = VIPConfig.GetMonthlyCoins(tier),
        impoundDiscount = VIPConfig.GetImpoundDiscount(tier),
        trunkBonus = VIPConfig.GetTrunkBonus(tier),
        dynastyBonus = VIPConfig.GetDynastyBonus(tier),
        propsPermanent = props.permanent or 0,
        propsTemporary = props.temporary or 0,
        respawnTime = VIPConfig.RespawnTime[tier] or VIPConfig.RespawnTime[0] or 600,
        interimMultiplier = VIPConfig.GetInterimSellMultiplier(tier),
        gofastMultiplier = VIPConfig.GetGofastMultiplier(tier),
        drugDealingMultiplier = VIPConfig.GetDrugDealingMultiplier(tier),
        ppaLeger = (VIPConfig.WeaponPermit.enabled and tier >= VIPConfig.WeaponPermit.minVipTier) and 1 or 0,
        ppaLourd = (VIPConfig.WeaponPermit.enabled and tier >= 2) and 1 or 0,
        plate_changes_per_month = VIPConfig.PlateChangesPerMonth[tier] or 0,
        emergency_vehicle_model = emergency and emergency.model or "",
        emergency_vehicle_label = emergency and emergency.label or "",
        driftMode = tier >= minTier and 1 or 0,
        weaponCustomization = (VIPConfig.WeaponCustomization.enabled and tier >= VIPConfig.WeaponCustomization.minVipTier) and 1 or 0,
        freecam = (VIPConfig.Freecam.enabled and tier >= VIPConfig.Freecam.minVipTier) and 1 or 0,
    }
end

local function getTierConfig(tier)
    local config = defaultTierConfig(tier)
    local row = Staff29.Single("SELECT * FROM vip_tier_config WHERE tier = ?", { tier })

    if row then
        for i = 1, #NUMERIC_KEYS do
            local key = NUMERIC_KEYS[i]
            if row[key] ~= nil then
                local value = tonumber(row[key])
                if value then config[key] = value end
            end
        end
        if type(row.emergency_vehicle_model) == "string" and row.emergency_vehicle_model ~= "" then
            config.emergency_vehicle_model = row.emergency_vehicle_model
        end
        if type(row.emergency_vehicle_label) == "string" and row.emergency_vehicle_label ~= "" then
            config.emergency_vehicle_label = row.emergency_vehicle_label
        end
    end

    return config
end

local function playerTier(xPlayer)
    if not xPlayer then return 0 end
    local tier = tonumber(xPlayer.vipTier) or 0
    if tier == 0 then
        if xPlayer.hasPermission("vip_gold") then tier = 3
        elseif xPlayer.hasPermission("vip_silver") then tier = 2
        elseif xPlayer.hasPermission("vip_bronze") then tier = 1 end
    end
    if tier < 0 then tier = 0 end
    if tier > 3 then tier = 3 end
    return tier
end

Staff29.VIP = {
    GetTierConfig = getTierConfig,
    GetPlayerTier = playerTier,
}

Staff29.Cb("vip:getTierValues", function(source, tier)
    local requested = Staff29.ToInt(tier, 0, 3)
    if not requested then
        local xPlayer = VFW.GetPlayerFromId(source)
        requested = playerTier(xPlayer)
    end
    return { success = true, config = getTierConfig(requested) }
end)

Staff29.Cb("vip:getEmergencyVehicleModel", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Erreur interne", hasActive = false, label = "", model = "" }
    end

    local tier = playerTier(xPlayer)
    if tier < 1 then
        return { success = false, message = "Réservé aux VIP", hasActive = false, label = "", model = "" }
    end

    local config = getTierConfig(tier)
    if config.emergency_vehicle_model == "" then
        return { success = false, message = "Aucun véhicule d'urgence pour votre palier",
                 hasActive = false, label = "", model = "" }
    end

    local active = emergencyVehicles[xPlayer.identifier]
    local hasActive = false
    if active and DoesEntityExist(active.entity) then
        hasActive = true
    elseif active then
        emergencyVehicles[xPlayer.identifier] = nil
    end

    return {
        success = true,
        message = "",
        hasActive = hasActive,
        label = config.emergency_vehicle_label,
        model = config.emergency_vehicle_model,
    }
end)

RegisterNetEvent("vip:spawnEmergencyVehicle", function(x, y, z, heading)
    local source = source

    local px, py, pz = tonumber(x), tonumber(y), tonumber(z)
    local h = tonumber(heading) or 0.0
    if not px or not py or not pz then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Staff29.RateLimit(source, "vipEmergency", 10000) then return end

    local tier = playerTier(xPlayer)
    if tier < 1 then return end

    local config = getTierConfig(tier)
    if config.emergency_vehicle_model == "" then return end

    local active = emergencyVehicles[xPlayer.identifier]
    if active and DoesEntityExist(active.entity) then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "VIP",
            message = "Vous avez déjà un véhicule d'urgence en circulation.",
        })
        return
    end

    local coords = xPlayer.getCoords()
    if coords then
        local dx, dy, dz = coords.x - px, coords.y - py, coords.z - pz
        if (dx * dx + dy * dy + dz * dz) > 400.0 then return end
    end

    local ok, vehicle = pcall(CreateVehicle, joaat(config.emergency_vehicle_model), px + 0.0, py + 0.0, pz + 0.0, h + 0.0, true, true)
    if not ok or not vehicle or vehicle == 0 then return end

    local tries = 0
    while not DoesEntityExist(vehicle) and tries < 50 do
        Wait(10)
        tries = tries + 1
    end
    if not DoesEntityExist(vehicle) then return end

    local plate = ("VIP%05d"):format(math.random(0, 99999))
    pcall(SetVehicleNumberPlateText, vehicle, plate)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    emergencyVehicles[xPlayer.identifier] = { entity = vehicle, netId = netId, plate = plate }

    tempKeys[plate] = tempKeys[plate] or {}
    tempKeys[plate][xPlayer.identifier] = true

    xPlayer.triggerEvent("vip:emergencyVehicleSpawned", netId)
end)

AddEventHandler("vfw:vehicle:tempKeyAdded", function(_, _, plate, identifier)
    if type(plate) ~= "string" or type(identifier) ~= "string" then return end

    local clean = Staff29.Clean(plate, 12)
    if not clean then return end

    tempKeys[clean] = tempKeys[clean] or {}
    tempKeys[clean][identifier] = true
end)

AddEventHandler("vfw:vehicle:tempKeyRemoved", function(plate)
    if type(plate) ~= "string" then return end

    local clean = Staff29.Clean(plate, 12)
    if not clean then return end

    tempKeys[clean] = nil
end)

function Staff29.HasTemporaryVehicleKey(plate, identifier)
    local entry = tempKeys[plate]
    return entry ~= nil and entry[identifier] == true
end

local function currentPeriod()
    return Staff29.Period()
end

Staff29.Cb("vip:getPlateChangeInfo", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, message = "Erreur interne", remainingChanges = 0, maxChanges = 0, vehicles = {} }
    end

    local tier = playerTier(xPlayer)
    local config = getTierConfig(tier)
    local maxChanges = math.floor(tonumber(config.plate_changes_per_month) or 0)

    if maxChanges <= 0 then
        return { success = false, message = "Votre palier VIP ne permet pas de changer de plaque",
                 remainingChanges = 0, maxChanges = 0, vehicles = {} }
    end

    local used = Staff29.Scalar(
        "SELECT used FROM vip_plate_changes WHERE identifier = ? AND period = ?",
        { xPlayer.identifier, currentPeriod() }, 0) or 0

    local rows = Staff29.Query(
        "SELECT plate, vehName FROM owned_vehicles WHERE owner = ? AND stored = 1", { xPlayer.identifier })

    local vehicles, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        vehicles[n] = { model = rows[i].vehName or "", plate = rows[i].plate }
    end

    return {
        success = true,
        message = "",
        remainingChanges = math.max(0, maxChanges - (tonumber(used) or 0)),
        maxChanges = maxChanges,
        vehicles = vehicles,
    }
end)

Staff29.Cb("vip:checkPlateAvailable", function(source, data)
    if not Staff29.IsTable(data) then return { available = false, message = "Les informations envoyées ne sont pas valides" } end

    local newPlate = Staff29.Clean(data.newPlate, 8)
    if not newPlate or newPlate == "" then return { available = false, message = "Cette plaque n'est pas valide" } end

    newPlate = newPlate:upper()
    if not newPlate:match("^[A-Z0-9 ]+$") then
        return { available = false, message = "Caractères non autorisés" }
    end

    local exists = Staff29.Scalar("SELECT COUNT(*) FROM owned_vehicles WHERE plate = ?", { newPlate }, 0) or 0
    if exists > 0 then return { available = false, message = "Cette plaque est déjà utilisée" } end

    return { available = true, message = "" }
end)

Staff29.Cb("vip:changePlate", function(source, data)
    if not Staff29.IsTable(data) then return { success = false, message = "Les informations envoyées ne sont pas valides" } end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Erreur interne" } end
    if not Staff29.RateLimit(source, "vipChangePlate", 3000) then
        return { success = false, message = "Veuillez patienter" }
    end

    local oldPlate = Staff29.Clean(data.oldPlate, 12)
    local newPlate = Staff29.Clean(data.newPlate, 8)
    if not oldPlate or not newPlate or newPlate == "" then
        return { success = false, message = "Cette plaque n'est pas valide" }
    end

    newPlate = newPlate:upper()
    if not newPlate:match("^[A-Z0-9 ]+$") then
        return { success = false, message = "Caractères non autorisés" }
    end

    local tier = playerTier(xPlayer)
    local config = getTierConfig(tier)
    local maxChanges = math.floor(tonumber(config.plate_changes_per_month) or 0)
    if maxChanges <= 0 then
        return { success = false, message = "Votre palier VIP ne permet pas de changer de plaque" }
    end

    local period = currentPeriod()
    local used = tonumber(Staff29.Scalar(
        "SELECT used FROM vip_plate_changes WHERE identifier = ? AND period = ?",
        { xPlayer.identifier, period }, 0)) or 0

    if used >= maxChanges then
        return { success = false, message = "Quota mensuel épuisé" }
    end

    local row = Staff29.Single("SELECT plate, owner, stored FROM owned_vehicles WHERE plate = ?", { oldPlate })
    if not row or row.owner ~= xPlayer.identifier then
        return { success = false, message = "Ce véhicule ne vous appartient pas" }
    end
    if row.stored ~= 1 then
        return { success = false, message = "Le véhicule doit être rangé au garage" }
    end

    local exists = Staff29.Scalar("SELECT COUNT(*) FROM owned_vehicles WHERE plate = ?", { newPlate }, 0) or 0
    if exists > 0 then return { success = false, message = "Cette plaque est déjà utilisée" } end

    Staff29.Update("UPDATE owned_vehicles SET plate = ? WHERE plate = ?", { newPlate, oldPlate })
    Staff29.Update([[
        INSERT INTO vip_plate_changes (identifier, period, used) VALUES (?, ?, 1)
        ON DUPLICATE KEY UPDATE used = used + 1
    ]], { xPlayer.identifier, period })

    return { success = true, message = ("Plaque changée en %s"):format(newPlate) }
end)

Staff29.Cb("vip:getMonthlyVehiclesCallback", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, vehicles = {}, hasClaimed = false } end

    local tier = playerTier(xPlayer)
    if tier < 1 then return { success = false, vehicles = {}, hasClaimed = false } end

    local period = currentPeriod()
    local rows = Staff29.Query([[
        SELECT vehicle_model, vehicle_label, vehicle_category FROM vip_monthly_vehicles
        WHERE tier <= ? AND (period = ? OR period IS NULL OR period = '')
    ]], { tier, period })

    local claimed = Staff29.Scalar(
        "SELECT COUNT(*) FROM vip_monthly_claims WHERE identifier = ? AND period = ?",
        { xPlayer.identifier, period }, 0) or 0

    return {
        success = true,
        vehicles = rows,
        hasClaimed = (tonumber(claimed) or 0) > 0,
    }
end)

Staff29.Cb("vip:claimMonthlyVehicleCallback", function(source, vehicleModel)
    if not Staff29.IsString(vehicleModel, 64) then
        return { success = false, message = "Ce véhicule n'est pas valide" }
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Erreur interne" } end

    local tier = playerTier(xPlayer)
    if tier < 1 then return { success = false, message = "Réservé aux VIP" } end
    if not Staff29.RateLimit(source, "vipMonthlyClaim", 3000) then
        return { success = false, message = "Veuillez patienter" }
    end

    local period = currentPeriod()
    local claimed = Staff29.Scalar(
        "SELECT COUNT(*) FROM vip_monthly_claims WHERE identifier = ? AND period = ?",
        { xPlayer.identifier, period }, 0) or 0
    if (tonumber(claimed) or 0) > 0 then
        return { success = false, message = "Vous avez déjà récupéré votre véhicule du mois" }
    end

    local row = Staff29.Single([[
        SELECT vehicle_model, vehicle_label FROM vip_monthly_vehicles
        WHERE vehicle_model = ? AND tier <= ?
    ]], { vehicleModel, tier })
    if not row then return { success = false, message = "Véhicule indisponible pour votre palier" } end

    local plate = ("VIP%05d"):format(math.random(0, 99999))
    while (Staff29.Scalar("SELECT COUNT(*) FROM owned_vehicles WHERE plate = ?", { plate }, 0) or 0) > 0 do
        plate = ("VIP%05d"):format(math.random(0, 99999))
    end

    Staff29.Insert([[
        INSERT INTO owned_vehicles (plate, owner, vehName, label, props, stored, pounded)
        VALUES (?, ?, ?, ?, ?, 1, 0)
    ]], { plate, xPlayer.identifier, row.vehicle_model, row.vehicle_label or row.vehicle_model,
          Staff29.Encode({ model = joaat(row.vehicle_model), plate = plate }) })

    Staff29.Insert([[
        INSERT INTO vip_monthly_claims (identifier, period, vehicle_model, claimed_at) VALUES (?, ?, ?, ?)
    ]], { xPlayer.identifier, period, row.vehicle_model, Staff29.Now() })

    return {
        success = true,
        message = ("%s ajouté à votre garage (%s)"):format(row.vehicle_label or row.vehicle_model, plate),
    }
end)

Staff29.Cb("vip:getSpawnedVehicles", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = Staff29.Query(
        "SELECT plate, vehName FROM owned_vehicles WHERE owner = ? AND stored = 0", { xPlayer.identifier })

    local byPlate = {}
    for i = 1, #rows do
        byPlate[rows[i].plate] = rows[i].vehName or ""
    end

    local out, n = {}, 0
    local ok, vehicles = pcall(GetAllVehicles)
    if ok and type(vehicles) == "table" then
        for i = 1, #vehicles do
            local entity = vehicles[i]
            if DoesEntityExist(entity) then
                local okPlate, plate = pcall(GetVehicleNumberPlateText, entity)
                if okPlate and type(plate) == "string" then
                    plate = plate:gsub("%s+$", "")
                    if byPlate[plate] then
                        local coords = GetEntityCoords(entity)
                        n = n + 1
                        out[n] = {
                            model = byPlate[plate],
                            plate = plate,
                            pos = { x = coords.x, y = coords.y, z = coords.z },
                        }
                        byPlate[plate] = nil
                    end
                end
            end
        end
    end

    return out
end)

Staff29.Cb("vip:ppa:getDates", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { leger = nil, lourd = nil } end

    local rows = Staff29.Query(
        "SELECT type, issued_at, valid_until FROM vip_ppa WHERE identifier = ?", { xPlayer.identifier })

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[row.type] = {
            issuedAt = tostring(row.issued_at or ""),
            validUntil = tostring(row.valid_until or ""),
        }
    end

    return { leger = out.leger, lourd = out.lourd }
end)

function Staff29.GrantPPA(identifier, kind, days)
    if kind ~= "leger" and kind ~= "lourd" then return false end
    days = tonumber(days) or 30

    local issued = os.date("%d/%m/%Y")
    local until_ = os.date("%d/%m/%Y", os.time() + days * 86400)

    Staff29.Update([[
        INSERT INTO vip_ppa (identifier, type, issued_at, valid_until) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE issued_at = VALUES(issued_at), valid_until = VALUES(valid_until)
    ]], { identifier, kind, issued, until_ })

    return true, issued, until_
end

VFW.RegisterCommand("setvip", "boutique", function(source, xPlayer, args)
    local targetId = tonumber(args and args[1])
    local tier = Staff29.ToInt(args and args[2], 0, 3)
    local target = targetId and VFW.GetPlayerFromId(targetId) or nil

    if not target or tier == nil then
        Staff29.Notify(source, "ERROR", "VIP", "Usage : /setvip [id] [0-3]")
        return
    end

    target.vipTier = tier
    target.globalData.vip_tier = tier
    Staff29.Update("UPDATE users SET vip_tier = ? WHERE id = ?", { tier, target.accountId })

    target.triggerEvent("vfw:updatePlayerGlobalData", target.getGlobalData())
    target.triggerEvent("vip:updateStatus", { tier = tier })

    Staff29.Notify(source, "SUCCESS", "VIP", ("%s est désormais palier %d."):format(target.name, tier))
end, {
    help = "Définir le palier VIP d'un joueur.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "tier", help = "0 à 3" },
    },
})

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    if not xPlayer then return end

    local active = emergencyVehicles[xPlayer.identifier]
    if active and active.entity and DoesEntityExist(active.entity) then
        pcall(DeleteEntity, active.entity)
    end
    emergencyVehicles[xPlayer.identifier] = nil
end)
