Staff29 = Staff29 or {}

local function safeCall(fn, sql, params, fallback)
    if not fn then return fallback end
    local ok, res = pcall(fn, sql, params)
    if not ok then
        console.warn(("[staff29] SQL: %s | %s"):format(tostring(res), tostring(sql)))
        return fallback
    end
    if res == nil then return fallback end
    return res
end

function Staff29.Query(sql, params)
    return safeCall(MySQL.query.await, sql, params, {})
end

function Staff29.Single(sql, params)
    return safeCall(MySQL.single.await, sql, params, nil)
end

function Staff29.Scalar(sql, params, fallback)
    local value = safeCall(MySQL.scalar.await, sql, params, fallback)
    if value == nil then return fallback end
    return value
end

function Staff29.Insert(sql, params)
    return safeCall(MySQL.insert.await, sql, params, nil)
end

function Staff29.Update(sql, params)
    return safeCall(MySQL.update.await, sql, params, 0)
end

function Staff29.Decode(value, fallback)
    return VFW.DB.Decode(value, fallback)
end

function Staff29.Encode(value)
    return VFW.DB.Encode(value)
end

function Staff29.IsNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Staff29.ToInt(value, min, max)
    local n = tonumber(value)
    if not n or n ~= n then return nil end
    n = math.floor(n)
    if min and n < min then return nil end
    if max and n > max then return nil end
    return n
end

function Staff29.IsString(value, maxLen)
    if type(value) ~= "string" then return false end
    if value == "" then return false end
    if maxLen and #value > maxLen then return false end
    return true
end

function Staff29.Clean(value, maxLen)
    if type(value) ~= "string" then return nil end
    local out = value:gsub("[%z\1-\8\11\12\14-\31]", "")
    out = out:sub(1, maxLen or 255)
    return out
end

function Staff29.IsTable(value)
    return type(value) == "table"
end

function Staff29.Vec(value)
    if type(value) ~= "table" then return nil end
    local x = tonumber(value.x or value[1])
    local y = tonumber(value.y or value[2])
    local z = tonumber(value.z or value[3])
    if not x or not y or not z then return nil end
    return { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
end

function Staff29.Now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function Staff29.Period()
    return os.date("%Y-%m")
end

function Staff29.Cb(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[staff29] callback '%s' déjà enregistré ailleurs : %s"):format(name, tostring(err)))
        return false
    end
    return true
end

function Staff29.Notify(source, variant, subtitle, message)
    if not source or source == 0 then return end
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF",
        variant = variant or "INFO",
        subtitle = subtitle or "Information",
        message = message or "",
        content = message or "",
    })
end

function Staff29.EventBlocked(eventName, source)
    if TestServer and TestServer.IsBlockedEvent and TestServer.IsBlockedEvent(eventName) then
        if TestServer.NotifyBlocked then TestServer.NotifyBlocked(source) end
        return true
    end
    return false
end

Staff29.Permissions = {}

function Staff29.Permissions.All()
    return Config.Permissions or {}
end

function Staff29.Permissions.Exists(key)
    if type(key) ~= "string" then return false end
    return (Config.Permissions or {})[key] ~= nil
end

function Staff29.Permissions.Count()
    local n = 0
    for _ in pairs(Config.Permissions or {}) do n = n + 1 end
    return n
end

function Staff29.Permissions.Keys(category)
    local out, n = {}, 0
    for key, def in pairs(Config.Permissions or {}) do
        if not category or def.category == category then
            n = n + 1
            out[n] = key
        end
    end
    table.sort(out)
    return out
end

function Staff29.Permissions.Label(key)
    local def = (Config.Permissions or {})[key]
    return def and def.label or key
end

function Staff29.Has(source, permission)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission(permission)
end

function Staff29.Require(source, permission)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if permission and permission ~= "" and not xPlayer.hasPermission(permission) then
        Staff29.Notify(source, "ERROR", "Permissions", "Vous n'avez pas la permission requise.")
        return nil
    end
    return xPlayer
end

function Staff29.Distance(sourceA, sourceB, maxDistance)
    local a = VFW.GetPlayerFromId(sourceA)
    local b = VFW.GetPlayerFromId(sourceB)
    if not a or not b then return false end
    local ca, cb = a.getCoords(), b.getCoords()
    if not ca or not cb then return false end
    local dx, dy, dz = ca.x - cb.x, ca.y - cb.y, ca.z - cb.z
    return (dx * dx + dy * dy + dz * dz) <= (maxDistance * maxDistance)
end

local rateBuckets = {}

function Staff29.RateLimit(source, key, intervalMs)
    local bucket = rateBuckets[source]
    if not bucket then
        bucket = {}
        rateBuckets[source] = bucket
    end
    local now = GetGameTimer()
    if bucket[key] and (now - bucket[key]) < intervalMs then
        return false
    end
    bucket[key] = now
    return true
end

AddEventHandler("vfw:playerDropped", function(source)
    rateBuckets[source] = nil
end)

if TestServer and TestServer.Block then
    TestServer.Block("callback",
        "core:jobs:deleteRole",
        "core:jobs:fireEmployee",
        "core:societyLockers:deleteArchivedLocker"
    )

    TestServer.Block("event",
        "sn_sams:hospital:delete",
        "sn_sams:hospital:removeSpawn",
        "sn_sams:pharmacy:delete",
        "sn_sams:pharmacy:removeItem",
        "sn_sams:deleteReport",
        "sn_sams:deleteDocument",
        "sn_sams:deleteAnnouncement",
        "sn_sams:deleteNote",
        "sn_sams:deleteTreatment",
        "sn_sams:deleteProcedure",
        "core:crew:removePlayerFromCrew"
    )
end

if TestServer and TestServer.enabled and Config.TestServer and Config.TestServer.GrantAllPermissions then
    AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
        if not xPlayer then return end
        for key in pairs(Config.Permissions or {}) do
            xPlayer.permissions[key] = true
        end
        xPlayer.globalData.permissions = xPlayer.permissions
        xPlayer.triggerEvent("vfw:updatePlayerGlobalData", xPlayer.getGlobalData())
    end)
end

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    if not xPlayer or not xPlayer.globalData then return end
    local isOwner = VFW.IsOwnerIdentifier and VFW.IsOwnerIdentifier(xPlayer.globalData.identifier)
    local isNiveau6 = VFW.IsNiveau6Role and VFW.IsNiveau6Role(xPlayer.globalData.role)
    if not isOwner and not isNiveau6 then return end

    local all = VFW.BuildFullPermissions()
    xPlayer.permissions = all
    xPlayer.globalData.permissions = all
    xPlayer.globalData.role = "niveau_6"
    xPlayer.triggerEvent("vfw:updatePlayerGlobalData", xPlayer.getGlobalData())
    if xPlayer.accountId then
        MySQL.update("UPDATE users SET role = ?, permissions = ? WHERE id = ?", {
            "niveau_6", json.encode(all), xPlayer.accountId
        })
    end
end)

Staff29.Cb("vfw:staff:syncMyAccess", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { role = "user", permissions = {} }
    end

    local role = (xPlayer.globalData and xPlayer.globalData.role) or "user"
    local perms

    if (VFW.IsNiveau6Role and VFW.IsNiveau6Role(role))
        or (VFW.IsOwnerIdentifier and xPlayer.globalData and VFW.IsOwnerIdentifier(xPlayer.globalData.identifier))
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin") then
        perms = VFW.BuildFullPermissions()
        role = "niveau_6"
        xPlayer.permissions = perms
        if xPlayer.globalData then
            xPlayer.globalData.permissions = perms
            xPlayer.globalData.role = role
        end
    else
        perms = {}
        for key in pairs(Config.Permissions or {}) do
            if xPlayer.hasPermission(key) then
                perms[key] = true
            end
        end
        for _, extra in ipairs({ "dev", "staff", "admin" }) do
            if xPlayer.hasPermission(extra) then
                perms[extra] = true
            end
        end
    end

    if VFW.IsSparseStaffPerms and VFW.IsSparseStaffPerms(perms) then
        perms = VFW.BuildFullPermissions()
        xPlayer.permissions = perms
        if xPlayer.globalData then
            xPlayer.globalData.permissions = perms
        end
    end

    return { role = role, permissions = perms }
end)

if not VFW.Staff29PlayerLoadedRelay then
    VFW.Staff29PlayerLoadedRelay = true

    AddEventHandler("vfw:playerLoaded", function(source)
        if not source or source == 0 then return end
        VFW.SetTimeout(1000, function()
            if not VFW.GetPlayerFromId(source) then return end
            TriggerClientEvent("vfw:onPlayerLoaded", source)
        end)
    end)
end

local function resolveTarget(args)
    local id = tonumber(args and args[1])
    if not id then return nil end
    return VFW.GetPlayerFromId(id)
end

VFW.RegisterCommand("givepermission", "gestion_perm", function(source, xPlayer, args)
    local target = resolveTarget(args)
    local permission = args and args[2]

    if not target then
        Staff29.Notify(source, "ERROR", "Permissions", "Joueur introuvable.")
        return
    end

    if not Staff29.Permissions.Exists(permission) then
        Staff29.Notify(source, "ERROR", "Permissions", "Permission inconnue : " .. tostring(permission))
        return
    end

    target.setPermission(permission, true)
    Staff29.Notify(source, "SUCCESS", "Permissions",
        ("%s accordée à %s."):format(Staff29.Permissions.Label(permission), target.name))
    Staff29.Notify(target.source, "INFO", "Permissions",
        ("Vous avez reçu la permission : %s"):format(Staff29.Permissions.Label(permission)))
end, {
    help = "Accorder une permission à un joueur connecté.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "permission", help = "Clé de permission" },
    },
})

VFW.RegisterCommand("removepermission", "gestion_perm", function(source, xPlayer, args)
    local target = resolveTarget(args)
    local permission = args and args[2]

    if not target then
        Staff29.Notify(source, "ERROR", "Permissions", "Joueur introuvable.")
        return
    end

    if not Staff29.Permissions.Exists(permission) then
        Staff29.Notify(source, "ERROR", "Permissions", "Permission inconnue : " .. tostring(permission))
        return
    end

    target.setPermission(permission, false)
    Staff29.Notify(source, "SUCCESS", "Permissions",
        ("%s retirée à %s."):format(Staff29.Permissions.Label(permission), target.name))
end, {
    help = "Retirer une permission à un joueur connecté.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "permission", help = "Clé de permission" },
    },
})

VFW.RegisterCommand("listpermissions", "gestion_perm", function(source, xPlayer, args)
    local category = args and args[1]
    local keys = Staff29.Permissions.Keys(category)

    if source == 0 then
        console.info(("[permissions] %d clés (%s)"):format(#keys, category or "toutes"))
        for i = 1, #keys do
            console.info(("  %s — %s"):format(keys[i], Staff29.Permissions.Label(keys[i])))
        end
        return
    end

    Staff29.Notify(source, "INFO", "Permissions",
        ("%d permissions (%s). Voir la console serveur pour le détail."):format(#keys, category or "toutes"))
    for i = 1, #keys do
        console.info(("  %s — %s"):format(keys[i], Staff29.Permissions.Label(keys[i])))
    end
end, {
    help = "Lister les permissions du serveur.",
    params = { { name = "categorie", help = "server|commands|vehicle|player|gestion (optionnel)" } },
    allowConsole = true,
})

VFW.RegisterCommand("checkpermission", "gestion_perm", function(source, xPlayer, args)
    local target = resolveTarget(args)
    local permission = args and args[2]

    if not target or not Staff29.Permissions.Exists(permission) then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur ou cette permission est introuvable.")
        return
    end

    Staff29.Notify(source, "INFO", "Permissions",
        ("%s : %s = %s"):format(target.name, permission, target.hasPermission(permission) and "oui" or "non"))
end, {
    help = "Vérifier si un joueur possède une permission.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "permission", help = "Clé de permission" },
    },
})

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    console.init("Staff29", ("%d permissions chargées depuis config/permissions/config.lua"):format(Staff29.Permissions.Count()))
end)
