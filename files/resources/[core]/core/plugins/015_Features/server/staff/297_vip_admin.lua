local TIER_LABELS = { [0] = "Aucun", [1] = "Bronze", [2] = "Silver", [3] = "Gold" }

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `vip_status` (
            `identifier` VARCHAR(64) NOT NULL,
            `expires_at` DATETIME DEFAULT NULL,
            PRIMARY KEY (`identifier`)
        )
    ]])
end)

local function requireBoutique(source)
    return Staff29.Require(source, "boutique")
end

local function applyVip(target, tier, days)
    tier = Staff29.ToInt(tier, 0, 3) or 0
    target.vipTier = tier
    if target.globalData then target.globalData.vip_tier = tier end
    Staff29.Update("UPDATE users SET vip_tier = ? WHERE id = ?", { tier, target.accountId })
    Staff29.Update("UPDATE paidshop_accounts SET vip_tier = ? WHERE identifier = ?", { tier, target.identifier })

    if tier <= 0 then
        Staff29.Update("DELETE FROM vip_status WHERE identifier = ?", { target.identifier })
    elseif days and tonumber(days) and tonumber(days) > 0 then
        local seconds = math.floor(tonumber(days) * 86400)
        Staff29.Update([[
            INSERT INTO vip_status (identifier, expires_at) VALUES (?, DATE_ADD(NOW(), INTERVAL ? SECOND))
            ON DUPLICATE KEY UPDATE expires_at = VALUES(expires_at)
        ]], { target.identifier, seconds })
    else
        Staff29.Update([[
            INSERT INTO vip_status (identifier, expires_at) VALUES (?, NULL)
            ON DUPLICATE KEY UPDATE expires_at = NULL
        ]], { target.identifier })
    end

    target.triggerEvent("vfw:updatePlayerGlobalData", target.getGlobalData())
    target.triggerEvent("vip:updateStatus", { tier = tier })
end

local function expiryInfo(identifier)
    local row = Staff29.Single("SELECT expires_at, TIMESTAMPDIFF(SECOND, NOW(), expires_at) AS delta FROM vip_status WHERE identifier = ?", { identifier })
    if not row then
        return "Illimité", "Illimité", nil
    end
    if not row.expires_at then
        return "Illimité", "Illimité", nil
    end
    local delta = tonumber(row.delta) or 0
    if delta <= 0 then
        return "Expiré", tostring(row.expires_at), 0
    end
    local days = math.floor(delta / 86400)
    local hours = math.floor((delta % 86400) / 3600)
    local remaining = days > 0 and ("%dj %dh"):format(days, hours) or ("%dh"):format(hours)
    return remaining, tostring(row.expires_at), delta
end

local function serializeVehicle(row)
    return {
        id = row.id,
        vip_tier = math.floor(tonumber(row.tier) or 1),
        vehicle_model = row.vehicle_model,
        vehicle_label = row.vehicle_label or row.vehicle_model,
        vehicle_category = row.vehicle_category or "Autre",
        period = row.period,
    }
end

Staff29.Cb("vip:admin:getMonthlyVehicles", function(source)
    if not requireBoutique(source) then return { success = false, vehicles = {} } end
    local rows = Staff29.Query("SELECT * FROM vip_monthly_vehicles ORDER BY tier ASC, id ASC") or {}
    local vehicles = {}
    for i = 1, #rows do
        vehicles[i] = serializeVehicle(rows[i])
    end
    return { success = true, vehicles = vehicles }
end)

Staff29.Cb("vip:admin:addMonthlyVehicleCallback", function(source, data)
    if not requireBoutique(source) then return { success = false, message = "Non autorisé" } end
    if type(data) ~= "table" then return { success = false, message = "Données invalides" } end
    local tier = Staff29.ToInt(data.tier, 1, 3)
    local model = Staff29.Clean(data.model, 60)
    local label = Staff29.Clean(data.label, 100)
    if not tier or not model or not label then
        return { success = false, message = "Remplissez tous les champs" }
    end
    local category = Staff29.Clean(data.category, 60) or "Autre"
    local period = Staff29.Period()
    Staff29.Insert([[
        INSERT INTO vip_monthly_vehicles (tier, period, vehicle_model, vehicle_label, vehicle_category)
        VALUES (?, ?, ?, ?, ?)
    ]], { tier, period, model:lower(), label, category })
    return { success = true, message = "Véhicule ajouté" }
end)

Staff29.Cb("vip:admin:removeMonthlyVehicleCallback", function(source, id)
    if not requireBoutique(source) then return { success = false, message = "Non autorisé" } end
    id = tonumber(id)
    if not id then return { success = false, message = "Identifiant invalide" } end
    Staff29.Update("DELETE FROM vip_monthly_vehicles WHERE id = ?", { id })
    return { success = true }
end)

Staff29.Cb("vip:admin:getTierConfig", function(source, tier)
    if not requireBoutique(source) then return { success = false, config = {} } end
    local requested = Staff29.ToInt(tier, 1, 3)
    if not requested then return { success = false, config = {} } end
    local getter = Staff29.VIP and Staff29.VIP.GetTierConfig
    local config = getter and getter(requested) or {}
    return { success = true, config = config }
end)

Staff29.Cb("vip:admin:setTierConfigValue", function(source, data)
    if not requireBoutique(source) then return { success = false, message = "Non autorisé" } end
    if type(data) ~= "table" then return { success = false, message = "Données invalides" } end
    local tier = Staff29.ToInt(data.tier, 1, 3)
    local key = type(data.key) == "string" and data.key or nil
    if not tier or not key then return { success = false, message = "Clé invalide" } end

    local allowed = {
        monthlyCoins = true, hourlyCoins = true, inventoryWeight = true, stateAid = true,
        impoundDiscount = true, trunkBonus = true, dynastyBonus = true, propsPermanent = true,
        propsTemporary = true, respawnTime = true, interimMultiplier = true, gofastMultiplier = true,
        drugDealingMultiplier = true, ppaLeger = true, ppaLourd = true, plate_changes_per_month = true,
        driftMode = true, weaponCustomization = true, freecam = true,
        emergency_vehicle_label = true, emergency_vehicle_model = true,
    }
    if not allowed[key] then return { success = false, message = "Clé inconnue" } end

    local value = data.value
    if key == "emergency_vehicle_label" or key == "emergency_vehicle_model" then
        value = Staff29.Clean(tostring(value or ""), 100) or ""
        if key == "emergency_vehicle_model" then value = value:lower() end
    else
        value = tonumber(value)
        if value == nil then return { success = false, message = "Cette valeur n'est pas valide" } end
    end

    Staff29.Update("INSERT IGNORE INTO vip_tier_config (tier) VALUES (?)", { tier })
    Staff29.Update(("UPDATE vip_tier_config SET `%s` = ? WHERE tier = ?"):format(key), { value, tier })
    return { success = true }
end)

Staff29.Cb("vip:admin:getPlayerVIPStatus", function(source, serverId)
    if not requireBoutique(source) then return { success = false, message = "Non autorisé" } end
    local target = VFW.GetPlayerFromId(tonumber(serverId))
    if not target then return { success = false, message = "Joueur introuvable" } end
    local remaining, expiry = expiryInfo(target.identifier)
    local tier = math.floor(tonumber(target.vipTier) or 0)
    return {
        success = true,
        serverId = target.source,
        playerName = target.name or target.playerName,
        identifier = target.identifier,
        tier = tier,
        tierLabel = (VIPConfig and VIPConfig.GetTierLabel and VIPConfig.GetTierLabel(tier)) or TIER_LABELS[tier] or tostring(tier),
        remaining = remaining,
        expiryFormatted = expiry,
    }
end)

Staff29.Cb("vip:admin:setPlayerVIP", function(source, data)
    if not requireBoutique(source) then return { success = false, message = "Non autorisé" } end
    if type(data) ~= "table" then return { success = false, message = "Données invalides" } end
    local target = VFW.GetPlayerFromId(tonumber(data.serverId))
    if not target then return { success = false, message = "Joueur introuvable" } end
    local tier = Staff29.ToInt(data.tier, 1, 3)
    if not tier then return { success = false, message = "Tier invalide" } end
    applyVip(target, tier, data.days)
    local label = (VIPConfig and VIPConfig.GetTierLabel and VIPConfig.GetTierLabel(tier)) or TIER_LABELS[tier]
    return { success = true, message = ("%s est désormais %s"):format(target.name or target.playerName, label) }
end)

Staff29.Cb("vip:admin:removePlayerVIP", function(source, serverId)
    if not requireBoutique(source) then return { success = false, message = "Non autorisé" } end
    local target = VFW.GetPlayerFromId(tonumber(serverId))
    if not target then return { success = false, message = "Joueur introuvable" } end
    applyVip(target, 0, nil)
    return { success = true, message = ("VIP retiré à %s"):format(target.name or target.playerName) }
end)

Staff29.Cb("vip:admin:listVIPPlayers", function(source)
    if not requireBoutique(source) then return { success = false, players = {} } end
    local players = {}
    for _, xPlayer in pairs(VFW.Players) do
        local tier = math.floor(tonumber(xPlayer.vipTier) or 0)
        if tier > 0 then
            local remaining, expiry = expiryInfo(xPlayer.identifier)
            players[#players + 1] = {
                serverId = xPlayer.source,
                playerName = xPlayer.name or xPlayer.playerName,
                identifier = xPlayer.identifier,
                tier = tier,
                tierLabel = (VIPConfig and VIPConfig.GetTierLabel and VIPConfig.GetTierLabel(tier)) or TIER_LABELS[tier] or tostring(tier),
                remaining = remaining,
                expiryFormatted = expiry,
            }
        end
    end
    table.sort(players, function(a, b) return (a.tier or 0) > (b.tier or 0) end)
    return { success = true, players = players }
end)
