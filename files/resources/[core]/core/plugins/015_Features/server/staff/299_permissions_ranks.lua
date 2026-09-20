Staff299 = Staff299 or {}

local ROLES_VARIABLE = "staff_roles"
local DEV_ROLE = "niveau_6"
local DEFAULT_ROLE = "user"
local ROLE_LEVEL_MAX = 100
local PHONE_PAGE_SIZE = 20

local FACTION_GRADE_PERMS = {
    "canAccessTablet", "canRecruit", "canKick", "canPromote",
    "canDemote", "canManageChest", "canManageGrades",
}

local CREW_RANK_LABELS = { "Chef", "Sous-chef", "Soldat", "Membre", "Recrue" }

local RANK_COLOR_HEX = {
    white = "#FFFFFF",
    red = "#E53935",
    green = "#43A047",
    blue = "#1E88E5",
    yellow = "#FDD835",
    orange = "#FB8C00",
    purple = "#8E24AA",
    pink = "#D81B60",
    grey = "#9E9E9E",
}

local SEED_ROLES = {
    { id = "user", name = "Utilisateur", level = 0, color = "#9E9E9E" },
    { id = "animator", name = "Animateur", level = 15, color = "#8E24AA" },
    { id = "niveau_1", name = "Niveau 1", level = 20, color = "#43A047" },
    { id = "niveau_2", name = "Niveau 2", level = 30, color = "#1E88E5" },
    { id = "niveau_3", name = "Niveau 3", level = 40, color = "#FB8C00" },
    { id = "niveau_4", name = "Niveau 4", level = 50, color = "#D81B60" },
    { id = "niveau_5", name = "Niveau 5", level = 60, color = "#E53935" },
    { id = DEV_ROLE, name = "Niveau 6", level = ROLE_LEVEL_MAX, color = "#FFFFFF" },
}

local rolesCache = nil

local function hexColor(value, fallback)
    if type(value) ~= "string" then return fallback end
    local hex = value:match("^#?(%x%x%x%x%x%x)$")
    if not hex then return fallback end
    return "#" .. hex:upper()
end

local function hexToInt(value)
    if type(value) ~= "string" then return 0 end
    local hex = value:match("^#?(%x%x%x%x%x%x)$")
    if not hex then return 0 end
    return tonumber(hex, 16) or 0
end

local function slug(value, maxLen)
    if type(value) ~= "string" then return nil end
    local out = value:lower()
    out = out:gsub("[^%w_]", "_")
    out = out:gsub("_+", "_")
    out = out:gsub("^_+", "")
    out = out:gsub("_+$", "")
    if out == "" then return nil end
    return out:sub(1, maxLen or 32)
end

local EXTRA_PERM_KEYS = { dev = true, staff = true, admin = true }

local function allPermissionKeys()
    if VFW.BuildFullPermissions then
        return VFW.BuildFullPermissions()
    end
    local out = { dev = true, staff = true, admin = true }
    for key in pairs(Config.Permissions or {}) do
        out[key] = true
    end
    return out
end

local function permissionSet(input)
    local out = {}
    if type(input) ~= "table" then return out end

    for key, value in pairs(input) do
        local name = nil
        if type(key) == "number" and type(value) == "string" then
            name = value
        elseif type(key) == "string" and value == true then
            name = key
        end
        if name and (Staff29.Permissions.Exists(name) or EXTRA_PERM_KEYS[name]) then
            out[name] = true
        end
    end

    return out
end

local function copySet(input)
    local out = {}
    for key in pairs(input or {}) do out[key] = true end
    return out
end

local function countSet(input)
    local n = 0
    for _ in pairs(input or {}) do n = n + 1 end
    return n
end

local function seedRoles()
    local out = {}
    for i = 1, #SEED_ROLES do
        local entry = SEED_ROLES[i]
        out[entry.id] = {
            name = entry.name,
            level = entry.level,
            color = entry.color,
            permissions = entry.id == DEV_ROLE and allPermissionKeys() or {},
        }
    end
    return out
end

local function ensureDevRole(roles)
    if type(roles) ~= "table" then return false end
    local full = allPermissionKeys()
    local role = roles[DEV_ROLE]
    if not role then
        roles[DEV_ROLE] = {
            name = "Niveau 6",
            level = ROLE_LEVEL_MAX,
            color = "#FFFFFF",
            permissions = full,
        }
        return true
    end
    local changed = false
    if (role.level or 0) < ROLE_LEVEL_MAX then
        role.level = ROLE_LEVEL_MAX
        changed = true
    end
    role.permissions = role.permissions or {}
    for key in pairs(full) do
        if role.permissions[key] ~= true then
            role.permissions[key] = true
            changed = true
        end
    end
    return changed
end

local function persistRoles(roles)
    ensureDevRole(roles)
    rolesCache = roles

    if VFW.Variables and VFW.Variables.Datas then
        VFW.Variables.Datas[ROLES_VARIABLE] = roles
    end

    Staff29.Update([[
        INSERT INTO variables (name, data) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data)
    ]], { ROLES_VARIABLE, Staff29.Encode(roles) })
end

local function loadRoles()
    if rolesCache then return rolesCache end

    local row = Staff29.Single("SELECT data FROM variables WHERE name = ?", { ROLES_VARIABLE })
    local decoded = row and Staff29.Decode(row.data, nil) or nil

    local out = {}
    if type(decoded) == "table" then
        for id, data in pairs(decoded) do
            if type(id) == "string" and type(data) == "table" then
                out[id] = {
                    name = type(data.name) == "string" and data.name or id,
                    level = Staff29.ToInt(data.level, 0, ROLE_LEVEL_MAX) or 0,
                    color = hexColor(data.color, "#FFFFFF"),
                    permissions = permissionSet(data.permissions),
                }
            end
        end
    end

    if next(out) == nil then
        out = seedRoles()
        persistRoles(out)
        return out
    end

    if ensureDevRole(out) then
        persistRoles(out)
        return out
    end

    rolesCache = out
    return out
end

local function rolePower(roleId)
    if type(roleId) ~= "string" then return 0 end
    local role = loadRoles()[roleId]
    if not role then return 0 end
    return role.level or 0
end

local function actorContext(xPlayer)
    local data = xPlayer.getGlobalData() or {}
    local roleId = type(data.role) == "string" and data.role or DEFAULT_ROLE

    return {
        role = roleId,
        isDev = roleId == DEV_ROLE,
        power = rolePower(roleId),
        level = tonumber(data.level) or 0,
    }
end

local function canGrantPermission(ctx, xPlayer, key)
    if EXTRA_PERM_KEYS[key] then
        return ctx.isDev == true
    end
    if not Staff29.Permissions.Exists(key) then return false end
    if ctx.isDev then return true end
    return xPlayer.hasPermission(key) == true
end

local function canActOn(ctx, target)
    if ctx.isDev then return true end
    local other = actorContext(target)
    if other.isDev then return false end
    return ctx.power >= other.power and ctx.level >= other.level
end

local function canManageRole(ctx, role)
    if ctx.isDev then return true end
    return (role.level or 0) <= ctx.power
end

local function pushGlobalData(target)
    target.triggerEvent("vfw:updatePlayerGlobalData", target.getGlobalData())
end

local function logStaff(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, action, payload)
end

local function applyPermissionMap(actor, ctx, target, wanted, replace)
    local granted, revoked, refused = {}, {}, 0
    local current = target.permissions or {}

    if replace then
        for key in pairs(copySet(current)) do
            if wanted[key] == nil then
                if canGrantPermission(ctx, actor, key) then
                    target.setPermission(key, false)
                    revoked[#revoked + 1] = key
                else
                    refused = refused + 1
                end
            end
        end
    end

    for key in pairs(wanted) do
        if current[key] ~= true then
            if canGrantPermission(ctx, actor, key) then
                target.setPermission(key, true)
                granted[#granted + 1] = key
            else
                refused = refused + 1
            end
        end
    end

    return granted, revoked, refused
end

local function setTargetRole(target, roleId)
    target.globalData.role = roleId
    if target.accountId then
        Staff29.Update("UPDATE users SET role = ? WHERE id = ?", { roleId, target.accountId })
    end
end

local function gradeDefaults(isBoss)
    local out = {}
    for i = 1, #FACTION_GRADE_PERMS do
        out[FACTION_GRADE_PERMS[i]] = isBoss and true or false
    end
    out.canAccessTablet = true
    return out
end

local function gradePermissions(raw, isBoss)
    local out = gradeDefaults(isBoss)
    if type(raw) == "table" then
        for i = 1, #FACTION_GRADE_PERMS do
            local key = FACTION_GRADE_PERMS[i]
            if raw[key] ~= nil then out[key] = raw[key] == true end
        end
    end
    return out
end

local function factionRow(name)
    if not Staff29.IsString(name, 60) then return nil end
    if name == "nocrew" or name == "nofaction" then return nil end
    return Staff29.Single("SELECT name, label, color FROM crews WHERE name = ?", { name })
end

local function ensureFactionGrades(name)
    local rows = Staff29.Query("SELECT * FROM faction_grades WHERE faction_name = ? ORDER BY level DESC", { name })
    if #rows > 0 then return rows end

    Staff29.Update([[
        INSERT IGNORE INTO faction_grades (faction_name, name, level, color, permissions)
        VALUES (?, 'Patron', 10, '#e53935', ?), (?, 'Membre', 0, '#9e9e9e', ?)
    ]], {
        name, Staff29.Encode(gradeDefaults(true)),
        name, Staff29.Encode(gradeDefaults(false)),
    })

    return Staff29.Query("SELECT * FROM faction_grades WHERE faction_name = ? ORDER BY level DESC", { name })
end

local function gradeMemberCounts(name)
    local out = {}
    local rows = Staff29.Query(
        "SELECT grade_level, COUNT(*) AS total FROM faction_members WHERE faction_name = ? GROUP BY grade_level",
        { name })
    for i = 1, #rows do
        out[tonumber(rows[i].grade_level) or -1] = tonumber(rows[i].total) or 0
    end
    return out
end

local function gradeList(name)
    local rows = ensureFactionGrades(name)
    local counts = gradeMemberCounts(name)
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local level = Staff29.ToInt(row.level, 0, 999) or 0
        out[#out + 1] = {
            level = level,
            label = row.name or ("Grade " .. level),
            permissions = gradePermissions(Staff29.Decode(row.permissions, nil), level >= 10),
            memberCount = counts[level] or 0,
        }
    end

    table.sort(out, function(a, b) return a.level > b.level end)
    return out
end

local function protectedLevels(grades)
    local out = {}
    for i = 1, math.min(2, #grades) do out[grades[i].level] = true end
    return out
end

local function requireFactionStaff(source)
    local xPlayer = Staff29.Require(source, "gestion_faction")
    if not xPlayer then return nil end
    return xPlayer
end

Staff299.Roles = {
    Load = loadRoles,
    Save = persistRoles,
    Power = rolePower,
}

Staff29.Cb("vfw:staff:getRoles", function(source)
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return {}, {} end

    local roles = loadRoles()
    local out, display = {}, {}

    for id, role in pairs(roles) do
        out[id] = {
            name = role.name,
            level = role.level,
            color = role.color,
            permissions = copySet(role.permissions),
        }
        display[#display + 1] = { id = id, name = role.name, color = hexToInt(role.color) }
    end

    table.sort(display, function(a, b) return a.id < b.id end)
    return out, display
end)

Staff29.Cb("vfw:staff:getAvailableRoles", function(source)
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return {} end

    local out = {}
    for id, role in pairs(loadRoles()) do
        out[#out + 1] = { id = id, name = role.name, level = role.level, color = role.color }
    end

    table.sort(out, function(a, b) return (a.level or 0) > (b.level or 0) end)
    return out
end)

Staff29.Cb("vfw:staff:createRole", function(source, roleName, roleLevel)
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return false, "Vous n'avez pas la permission requise" end
    if not Staff29.RateLimit(source, "role_create", 1000) then
        return false, "Veuillez patienter un instant"
    end
    if type(roleName) ~= "string" then
        return false, "Ce nom n'est pas valide"
    end

    local label = Staff29.Clean(roleName, 32)
    if not label or label:gsub("%s", "") == "" then
        return false, "Ce nom n'est pas valide"
    end

    local level = Staff29.ToInt(roleLevel, 0, ROLE_LEVEL_MAX)
    if not level then
        return false, "Ce niveau n'est pas valide"
    end

    local ctx = actorContext(xPlayer)
    if not ctx.isDev and level > ctx.power then
        return false, "Ce niveau dépasse le vôtre"
    end

    local base = slug(label, 28)
    if not base then
        return false, "Ce nom n'est pas valide"
    end

    local roles = loadRoles()
    local id = base
    local suffix = 2
    while roles[id] do
        id = ("%s_%d"):format(base, suffix)
        suffix = suffix + 1
        if suffix > 99 then
            return false, "Ce nom est déjà utilisé"
        end
    end

    roles[id] = { name = label, level = level, color = "#FFFFFF", permissions = {} }
    persistRoles(roles)

    logStaff(source, "role_create", { id = id, name = label, level = level })
    return true, id
end)

Staff29.Cb("vfw:staff:reloadRoles", function(source, done)
    local xPlayer = Staff29.Require(source, "gestion_perm")
    local allowed = xPlayer ~= nil

    if allowed then
        rolesCache = nil
        loadRoles()
    end

    if done ~= nil then
        pcall(function() done(allowed) end)
    end

    return allowed
end)

RegisterNetEvent("vfw:staff:saveRole", function(payload)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:saveRole", source) then return end
    if type(payload) ~= "table" then return end
    if not Staff29.RateLimit(source, "role_save", 750) then return end

    local ctx = actorContext(xPlayer)
    local roles = loadRoles()
    local saved, refused = 0, 0
    local changes = {}

    for i = 1, #payload do
        local entry = payload[i]
        if type(entry) == "table" and type(entry.id) == "string" then
            local role = roles[entry.id]
            local level = role and (Staff29.ToInt(entry.power, 0, ROLE_LEVEL_MAX) or role.level) or nil

            if role and canManageRole(ctx, role) and (ctx.isDev or level <= ctx.power) then
                local wanted = permissionSet(entry.permissions)
                local nextPerms = {}

                for key in pairs(role.permissions) do
                    if not canGrantPermission(ctx, xPlayer, key) then nextPerms[key] = true end
                end
                for key in pairs(wanted) do
                    if canGrantPermission(ctx, xPlayer, key) then nextPerms[key] = true end
                end

                role.level = level
                role.color = hexColor(entry.color, role.color)
                role.permissions = nextPerms
                saved = saved + 1
                changes[#changes + 1] = { id = entry.id, level = level, count = countSet(nextPerms) }
            else
                refused = refused + 1
            end
        end
    end

    if saved > 0 then
        persistRoles(roles)
        logStaff(source, "role_save", { roles = changes })
    end

    if refused > 0 then
        Staff29.Notify(source, "ERROR", "Gestion Permissions",
            "Certains rôles sont au dessus du vôtre et n'ont pas été enregistrés.")
    end
end)

RegisterNetEvent("vfw:staff:deleteRole", function(roleId)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:deleteRole", source) then return end
    if type(roleId) ~= "string" then return end
    if not Staff29.RateLimit(source, "role_delete", 1000) then return end

    if roleId == DEFAULT_ROLE then
        Staff29.Notify(source, "ERROR", "Gestion Permissions", "Ce rôle ne peut pas être supprimé.")
        return
    end

    local roles = loadRoles()
    local role = roles[roleId]
    if not role then
        Staff29.Notify(source, "ERROR", "Gestion Permissions", "Ce rôle est introuvable.")
        return
    end

    local ctx = actorContext(xPlayer)
    if not canManageRole(ctx, role) or ctx.role == roleId then
        Staff29.Notify(source, "ERROR", "Gestion Permissions", "Vous ne pouvez pas supprimer ce rôle.")
        return
    end

    roles[roleId] = nil
    persistRoles(roles)

    local moved = Staff29.Update("UPDATE users SET role = ? WHERE role = ?", { DEFAULT_ROLE, roleId }) or 0

    for _, other in pairs(VFW.Players) do
        if other.globalData and other.globalData.role == roleId then
            other.globalData.role = DEFAULT_ROLE
            pushGlobalData(other)
        end
    end

    logStaff(source, "role_delete", { id = roleId, name = role.name, members = moved })
end)

Staff29.Cb("vfw:staff:getPlayerPermissions", function(source, playerId)
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return {} end

    local target = VFW.GetPlayerFromId(tonumber(playerId))
    if not target then return {} end

    return copySet(target.permissions)
end)

RegisterNetEvent("vfw:staff:setPlayerPermission", function(playerId, permission, enabled)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:setPlayerPermission", source) then return end
    if type(permission) ~= "string" then return end
    if not Staff29.RateLimit(source, "perm_set", 200) then return end

    local target = VFW.GetPlayerFromId(tonumber(playerId))
    if not target then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur est introuvable.")
        return
    end

    if not Staff29.Permissions.Exists(permission) then
        Staff29.Notify(source, "ERROR", "Permissions", "Cette permission n'existe pas.")
        return
    end

    local ctx = actorContext(xPlayer)
    if not canActOn(ctx, target) then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur est au dessus de votre rang.")
        return
    end

    local grant = enabled == true
    if grant and not canGrantPermission(ctx, xPlayer, permission) then
        Staff29.Notify(source, "ERROR", "Permissions", "Vous ne pouvez pas accorder un droit que vous n'avez pas.")
        return
    end

    target.setPermission(permission, grant)

    logStaff(source, grant and "perm_grant" or "perm_revoke", {
        target = target.identifier,
        targetName = target.name,
        targetSource = target.source,
        permission = permission,
    })

    Staff29.Notify(target.source, "INFO", "Permissions",
        grant
            and ("Vous avez reçu le droit : %s"):format(Staff29.Permissions.Label(permission))
            or ("Le droit %s vous a été retiré."):format(Staff29.Permissions.Label(permission)))
end)

local function assignRole(source, xPlayer, playerId, roleId, replace)
    if type(roleId) ~= "string" then return end

    local target = VFW.GetPlayerFromId(tonumber(playerId))
    if not target then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur est introuvable.")
        return
    end

    local role = loadRoles()[roleId]
    if not role then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce rôle est introuvable.")
        return
    end

    local ctx = actorContext(xPlayer)
    if not canActOn(ctx, target) then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur est au dessus de votre rang.")
        return
    end

    if not canManageRole(ctx, role) then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce rôle est au dessus du vôtre.")
        return
    end

    for key in pairs(role.permissions) do
        if not canGrantPermission(ctx, xPlayer, key) then
            Staff29.Notify(source, "ERROR", "Permissions", "Ce rôle contient des droits que vous n'avez pas.")
            return
        end
    end

    local wanted = roleId == DEV_ROLE and allPermissionKeys() or role.permissions
    local granted, revoked, refused = applyPermissionMap(xPlayer, ctx, target, wanted, replace)

    if replace then
        setTargetRole(target, roleId)
    end
    pushGlobalData(target)

    logStaff(source, replace and "role_assign" or "role_preset", {
        target = target.identifier,
        targetName = target.name,
        targetSource = target.source,
        role = roleId,
        granted = granted,
        revoked = revoked,
    })

    if refused > 0 then
        Staff29.Notify(source, "ERROR", "Permissions", "Certains droits n'ont pas pu être appliqués.")
    end

    Staff29.Notify(target.source, "INFO", "Permissions",
        ("Vos droits ont été mis à jour : %s"):format(role.name))
end

RegisterNetEvent("vfw:staff:assignFullRole", function(playerId, roleId)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:assignFullRole", source) then return end
    if not Staff29.RateLimit(source, "role_assign", 750) then return end

    assignRole(source, xPlayer, playerId, roleId, true)
end)

RegisterNetEvent("vfw:staff:assignPresetRole", function(playerId, presetId)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:assignPresetRole", source) then return end
    if not Staff29.RateLimit(source, "role_preset", 750) then return end

    assignRole(source, xPlayer, playerId, presetId, false)
end)

RegisterNetEvent("vfw:staff:removeAllPlayerPermissions", function(playerId)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:removeAllPlayerPermissions", source) then return end
    if not Staff29.RateLimit(source, "perm_wipe", 1000) then return end

    local target = VFW.GetPlayerFromId(tonumber(playerId))
    if not target then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur est introuvable.")
        return
    end

    local ctx = actorContext(xPlayer)
    if not canActOn(ctx, target) then
        Staff29.Notify(source, "ERROR", "Permissions", "Ce joueur est au dessus de votre rang.")
        return
    end

    local removed, refused = {}, 0
    for key in pairs(copySet(target.permissions)) do
        if canGrantPermission(ctx, xPlayer, key) then
            target.setPermission(key, false)
            removed[#removed + 1] = key
        else
            refused = refused + 1
        end
    end

    setTargetRole(target, DEFAULT_ROLE)
    pushGlobalData(target)

    logStaff(source, "perm_wipe", {
        target = target.identifier,
        targetName = target.name,
        targetSource = target.source,
        removed = removed,
    })

    if refused > 0 then
        Staff29.Notify(source, "ERROR", "Permissions", "Certains droits n'ont pas pu être retirés.")
    end

    Staff29.Notify(target.source, "INFO", "Permissions", "Vos droits ont été retirés.")
end)

Staff29.Cb("vfw:staff:getRanksList", function(source)
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return {} end

    local out = {}
    for id, role in pairs(loadRoles()) do
        out[#out + 1] = {
            name = id,
            label = role.name,
            power = role.level,
            color = role.color,
            permissions = copySet(role.permissions),
        }
    end

    table.sort(out, function(a, b) return (a.power or 0) > (b.power or 0) end)
    return out
end)

local function writeRank(source, xPlayer, payload, create)
    if type(payload) ~= "table" then return end

    local ctx = actorContext(xPlayer)
    local roles = loadRoles()

    local id = slug(payload.name, 32)
    if not id then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce nom n'est pas valide.")
        return
    end

    local existing = roles[id]
    if create and existing then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce nom est déjà utilisé.")
        return
    end
    if not create and not existing then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce rang est introuvable.")
        return
    end
    if existing and not canManageRole(ctx, existing) then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce rang est au dessus du vôtre.")
        return
    end

    local label = Staff29.Clean(payload.label, 32)
    if not label or label:gsub("%s", "") == "" then
        label = existing and existing.name or id
    end

    local level = Staff29.ToInt(payload.power, 0, ROLE_LEVEL_MAX)
    if not level then
        level = existing and existing.level or 1
    end
    if not ctx.isDev and level > ctx.power then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce niveau dépasse le vôtre.")
        return
    end

    local color = RANK_COLOR_HEX[payload.color]
        or hexColor(payload.color, existing and existing.color or "#FFFFFF")

    local wanted = permissionSet(payload.permissions)
    local nextPerms = {}

    if existing then
        for key in pairs(existing.permissions) do
            if not canGrantPermission(ctx, xPlayer, key) then nextPerms[key] = true end
        end
    end
    for key in pairs(wanted) do
        if canGrantPermission(ctx, xPlayer, key) then nextPerms[key] = true end
    end

    roles[id] = { name = label, level = level, color = color, permissions = nextPerms }
    persistRoles(roles)

    logStaff(source, create and "rank_create" or "rank_update", {
        id = id, name = label, level = level, count = countSet(nextPerms),
    })
end

RegisterNetEvent("vfw:staff:createRank", function(payload)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:createRank", source) then return end
    if not Staff29.RateLimit(source, "rank_create", 750) then return end

    writeRank(source, xPlayer, payload, true)
end)

RegisterNetEvent("vfw:staff:updateRank", function(payload)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:updateRank", source) then return end
    if not Staff29.RateLimit(source, "rank_update", 750) then return end

    writeRank(source, xPlayer, payload, false)
end)

RegisterNetEvent("vfw:staff:deleteRank", function(rankName)
    local source = source
    local xPlayer = Staff29.Require(source, "gestion_perm")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:deleteRank", source) then return end
    if type(rankName) ~= "string" then return end
    if not Staff29.RateLimit(source, "rank_delete", 1000) then return end

    local id = slug(rankName, 32)
    if not id or id == DEFAULT_ROLE then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce rang ne peut pas être supprimé.")
        return
    end

    local roles = loadRoles()
    local role = roles[id]
    if not role then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Ce rang est introuvable.")
        return
    end

    local ctx = actorContext(xPlayer)
    if not canManageRole(ctx, role) or ctx.role == id then
        Staff29.Notify(source, "ERROR", "Gestion Rangs", "Vous ne pouvez pas supprimer ce rang.")
        return
    end

    roles[id] = nil
    persistRoles(roles)

    local moved = Staff29.Update("UPDATE users SET role = ? WHERE role = ?", { DEFAULT_ROLE, id }) or 0

    for _, other in pairs(VFW.Players) do
        if other.globalData and other.globalData.role == id then
            other.globalData.role = DEFAULT_ROLE
            pushGlobalData(other)
        end
    end

    logStaff(source, "rank_delete", { id = id, name = role.name, members = moved })
end)

RegisterNetEvent("vfw:staff:setJob", function(charId, jobName, gradeLevel)
    local source = source
    local xPlayer = Staff29.Require(source, "setjob")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:setJob", source) then return end
    if not Staff29.RateLimit(source, "set_job", 500) then return end

    local id = Staff29.ToInt(charId, 1)
    if not id or type(jobName) ~= "string" then return end

    local job = VFW.Jobs[jobName]
    if not job then
        Staff29.Notify(source, "ERROR", "Gestion Grades", "Ce métier est introuvable.")
        return
    end

    local grade = Staff29.ToInt(gradeLevel, 0, 999) or 0
    if not job.grades[tostring(grade)] then
        Staff29.Notify(source, "ERROR", "Gestion Grades", "Ce grade est introuvable.")
        return
    end

    local target = VFW.GetPlayerFromCharId(id)
    if target then
        local ctx = actorContext(xPlayer)
        if not canActOn(ctx, target) then
            Staff29.Notify(source, "ERROR", "Gestion Grades", "Ce joueur est au dessus de votre rang.")
            return
        end
        target.setJob(jobName, grade, false)
    end

    local updated = Staff29.Update(
        "UPDATE characters SET job = ?, job_grade = ?, job_duty = 0 WHERE id = ? AND deleted_at IS NULL",
        { jobName, grade, id })

    if (updated or 0) == 0 and not target then
        Staff29.Notify(source, "ERROR", "Gestion Grades", "Ce personnage est introuvable.")
        return
    end

    logStaff(source, "set_job", {
        charId = id,
        job = jobName,
        grade = grade,
        targetSource = target and target.source or nil,
    })

    if target then
        Staff29.Notify(target.source, "INFO", "Métier",
            ("Votre métier est maintenant : %s"):format(job.label or jobName))
    end
end)

RegisterNetEvent("vfw:staff:setFaction", function(charId, factionName, rankLevel)
    local source = source
    local xPlayer = Staff29.Require(source, "setjob2")
    if not xPlayer then return end
    if Staff29.EventBlocked("vfw:staff:setFaction", source) then return end
    if not Staff29.RateLimit(source, "set_faction", 500) then return end

    local id = Staff29.ToInt(charId, 1)
    if not id or type(factionName) ~= "string" then return end

    local target = VFW.GetPlayerFromCharId(id)
    local identifier = target and target.identifier
        or Staff29.Scalar("SELECT identifier FROM characters WHERE id = ? AND deleted_at IS NULL", { id }, nil)

    if not identifier then
        Staff29.Notify(source, "ERROR", "Gestion Factions", "Ce personnage est introuvable.")
        return
    end

    if target then
        local ctx = actorContext(xPlayer)
        if not canActOn(ctx, target) then
            Staff29.Notify(source, "ERROR", "Gestion Factions", "Ce joueur est au dessus de votre rang.")
            return
        end
    end

    local leaving = factionName == "" or factionName == "nocrew" or factionName == "nofaction"

    if leaving then
        Staff29.Update("DELETE FROM crew_members WHERE identifier = ?", { identifier })
        Staff29.Update("UPDATE characters SET faction = '' WHERE id = ?", { id })
    else
        local crew = factionRow(factionName)
        if not crew then
            Staff29.Notify(source, "ERROR", "Gestion Factions", "Cette faction est introuvable.")
            return
        end

        local rank = Staff29.ToInt(rankLevel, 1, #CREW_RANK_LABELS) or #CREW_RANK_LABELS

        Staff29.Update([[
            INSERT INTO crew_members (crew_name, identifier, rank, xp, role, seniority, status, joined_at)
            VALUES (?, ?, ?, 0, ?, ?, 'offline', ?)
            ON DUPLICATE KEY UPDATE crew_name = VALUES(crew_name), rank = VALUES(rank), role = VALUES(role)
        ]], { factionName, identifier, rank, CREW_RANK_LABELS[rank], Staff29.Now(), Staff29.Now() })

        Staff29.Update("UPDATE characters SET faction = ? WHERE id = ?", { factionName, id })
    end

    if target and Staff29.Factions and Staff29.Factions.Push then
        Staff29.Factions.Push(target)
    end

    logStaff(source, "set_faction", {
        charId = id,
        identifier = identifier,
        faction = leaving and "" or factionName,
        rank = leaving and 0 or (Staff29.ToInt(rankLevel, 1, #CREW_RANK_LABELS) or #CREW_RANK_LABELS),
        targetSource = target and target.source or nil,
    })

    if target then
        Staff29.Notify(target.source, "INFO", "Faction",
            leaving and "Vous ne faites plus partie d'une faction."
                or "Votre faction a été mise à jour.")
    end
end)

Staff29.Cb("vfw:staff:grades:getData", function(source, factionName)
    local xPlayer = requireFactionStaff(source)
    if not xPlayer then return nil end

    local crew = factionRow(factionName)
    if not crew then return nil end

    return {
        faction = {
            name = crew.name,
            label = crew.label or crew.name,
            color = hexColor(crew.color, "#7263EE"),
        },
        grades = gradeList(crew.name),
    }
end)

Staff29.Cb("vfw:staff:grades:createGrade", function(source, data)
    local xPlayer = requireFactionStaff(source)
    if not xPlayer then return { success = false, error = "Vous n'avez pas la permission requise." } end
    if not Staff29.IsTable(data) then return { success = false, error = "Cette demande n'a pas pu être traitée." } end
    if not Staff29.RateLimit(source, "grade_create", 500) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local crew = factionRow(data.factionName)
    if not crew then return { success = false, error = "Cette faction est introuvable." } end

    local label = Staff29.Clean(data.gradeName, 64)
    if not label or label:gsub("%s", "") == "" then
        return { success = false, error = "Ce nom n'est pas valide." }
    end

    local grades = gradeList(crew.name)
    local used, maxLevel = {}, 0
    for i = 1, #grades do
        used[grades[i].level] = true
        if grades[i].level > maxLevel then maxLevel = grades[i].level end
    end

    local level = nil
    for candidate = 0, maxLevel - 1 do
        if not used[candidate] then
            level = candidate
            break
        end
    end

    if not level then
        return { success = false, error = "Aucun niveau libre sous le grade le plus haut." }
    end

    local permissions = gradeDefaults(false)
    Staff29.Update([[
        INSERT INTO faction_grades (faction_name, name, level, color, permissions)
        VALUES (?, ?, ?, '#9e9e9e', ?)
    ]], { crew.name, label, level, Staff29.Encode(permissions) })

    logStaff(source, "grade_create", { faction = crew.name, level = level, label = label })

    return {
        success = true,
        grade = { level = level, label = label, permissions = permissions, memberCount = 0 },
    }
end)

Staff29.Cb("vfw:staff:grades:renameGrade", function(source, data)
    local xPlayer = requireFactionStaff(source)
    if not xPlayer then return { success = false, error = "Vous n'avez pas la permission requise." } end
    if not Staff29.IsTable(data) then return { success = false, error = "Cette demande n'a pas pu être traitée." } end
    if not Staff29.RateLimit(source, "grade_rename", 500) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local crew = factionRow(data.factionName)
    if not crew then return { success = false, error = "Cette faction est introuvable." } end

    local level = Staff29.ToInt(data.gradeLevel, 0, 999)
    local label = Staff29.Clean(data.newName, 64)
    if not level or not label or label:gsub("%s", "") == "" then
        return { success = false, error = "Cette demande n'a pas pu être traitée." }
    end

    local updated = Staff29.Update("UPDATE faction_grades SET name = ? WHERE faction_name = ? AND level = ?",
        { label, crew.name, level })

    if (updated or 0) == 0 then
        return { success = false, error = "Ce grade est introuvable." }
    end

    logStaff(source, "grade_rename", { faction = crew.name, level = level, label = label })
    return { success = true }
end)

Staff29.Cb("vfw:staff:grades:deleteGrade", function(source, data)
    local xPlayer = requireFactionStaff(source)
    if not xPlayer then return { success = false, error = "Vous n'avez pas la permission requise." } end
    if not Staff29.IsTable(data) then return { success = false, error = "Cette demande n'a pas pu être traitée." } end
    if not Staff29.RateLimit(source, "grade_delete", 500) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local crew = factionRow(data.factionName)
    if not crew then return { success = false, error = "Cette faction est introuvable." } end

    local level = Staff29.ToInt(data.gradeLevel, 0, 999)
    if not level then return { success = false, error = "Ce grade n'est pas valide." } end

    local grades = gradeList(crew.name)
    if #grades <= 1 then
        return { success = false, error = "Le dernier grade ne peut pas être supprimé." }
    end
    if grades[1] and grades[1].level == level then
        return { success = false, error = "Le grade le plus haut ne peut pas être supprimé." }
    end

    for i = 1, #grades do
        if grades[i].level == level and grades[i].memberCount > 0 then
            return { success = false, error = "Des membres occupent encore ce grade." }
        end
    end

    local removed = Staff29.Update("DELETE FROM faction_grades WHERE faction_name = ? AND level = ?",
        { crew.name, level })

    if (removed or 0) == 0 then
        return { success = false, error = "Ce grade est introuvable." }
    end

    logStaff(source, "grade_delete", { faction = crew.name, level = level })
    return { success = true }
end)

Staff29.Cb("vfw:staff:grades:swapGrades", function(source, data)
    local xPlayer = requireFactionStaff(source)
    if not xPlayer then return { success = false } end
    if not Staff29.IsTable(data) then return { success = false } end
    if not Staff29.RateLimit(source, "grade_swap", 300) then return { success = false } end

    local crew = factionRow(data.factionName)
    if not crew then return { success = false } end

    local levelA = Staff29.ToInt(data.levelA, 0, 999)
    local levelB = Staff29.ToInt(data.levelB, 0, 999)
    if not levelA or not levelB or levelA == levelB then return { success = false } end

    local grades = gradeList(crew.name)
    local locked = protectedLevels(grades)
    if locked[levelA] or locked[levelB] then return { success = false } end

    local found = { [levelA] = false, [levelB] = false }
    for i = 1, #grades do
        if found[grades[i].level] ~= nil then found[grades[i].level] = true end
    end
    if not found[levelA] or not found[levelB] then return { success = false } end

    Staff29.Update("UPDATE faction_grades SET level = -1 WHERE faction_name = ? AND level = ?", { crew.name, levelA })
    Staff29.Update("UPDATE faction_grades SET level = ? WHERE faction_name = ? AND level = ?", { levelA, crew.name, levelB })
    Staff29.Update("UPDATE faction_grades SET level = ? WHERE faction_name = ? AND level = -1", { levelB, crew.name })

    Staff29.Update("UPDATE faction_members SET grade_level = -1 WHERE faction_name = ? AND grade_level = ?", { crew.name, levelA })
    Staff29.Update("UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = ?", { levelA, crew.name, levelB })
    Staff29.Update("UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = -1", { levelB, crew.name })

    logStaff(source, "grade_swap", { faction = crew.name, levelA = levelA, levelB = levelB })
    return { success = true }
end)

Staff29.Cb("vfw:staff:grades:updatePermissions", function(source, data)
    local xPlayer = requireFactionStaff(source)
    if not xPlayer then return { success = false } end
    if not Staff29.IsTable(data) then return { success = false } end
    if not Staff29.RateLimit(source, "grade_perms", 300) then return { success = false } end

    local crew = factionRow(data.factionName)
    if not crew then return { success = false } end

    local level = Staff29.ToInt(data.gradeLevel, 0, 999)
    if not level or not Staff29.IsTable(data.permissions) then return { success = false } end

    local row = Staff29.Single("SELECT level FROM faction_grades WHERE faction_name = ? AND level = ?",
        { crew.name, level })
    if not row then return { success = false } end

    local permissions = gradePermissions(data.permissions, level >= 10)
    Staff29.Update("UPDATE faction_grades SET permissions = ? WHERE faction_name = ? AND level = ?",
        { Staff29.Encode(permissions), crew.name, level })

    logStaff(source, "grade_perms", { faction = crew.name, level = level, permissions = permissions })
    return { success = true }
end)

Staff29.Cb("vfw:staff:checkJob", function(source)
    local xPlayer = Staff29.Require(source, "check_effectifs")
    if not xPlayer then return nil end

    local totals = {}
    local rows = Staff29.Query("SELECT job, COUNT(*) AS total FROM characters WHERE deleted_at IS NULL GROUP BY job")
    for i = 1, #rows do
        totals[rows[i].job] = tonumber(rows[i].total) or 0
    end

    local onDuty = {}
    for _, other in pairs(VFW.Players) do
        local job = other.job
        if job and job.onDuty then
            onDuty[job.name] = (onDuty[job.name] or 0) + 1
        end
    end

    local out = {}
    for name, job in pairs(VFW.Jobs or {}) do
        if name ~= "unemployed" then
            out[#out + 1] = {
                label = job.label or name,
                total = totals[name] or 0,
                onDuty = onDuty[name] or 0,
            }
        end
    end

    table.sort(out, function(a, b)
        if a.total == b.total then return a.label < b.label end
        return a.total > b.total
    end)

    return out
end)

Staff29.Cb("vfw:staff:checkFaction", function(source)
    local xPlayer = Staff29.Require(source, "check_effectifs")
    if not xPlayer then return nil end

    local totals = {}
    local rows = Staff29.Query("SELECT crew_name, COUNT(*) AS total FROM crew_members GROUP BY crew_name")
    for i = 1, #rows do
        totals[rows[i].crew_name] = tonumber(rows[i].total) or 0
    end

    local online = {}
    for _, other in pairs(VFW.Players) do
        local name = type(other.faction) == "table" and other.faction.name or other.faction
        if type(name) == "string" and name ~= "" and name ~= "nocrew" then
            online[name] = (online[name] or 0) + 1
        end
    end

    local out = {}
    local crews = Staff29.Query("SELECT name, label FROM crews")
    for i = 1, #crews do
        local crew = crews[i]
        out[#out + 1] = {
            label = crew.label ~= "" and crew.label or crew.name,
            total = totals[crew.name] or 0,
            online = online[crew.name] or 0,
        }
    end

    table.sort(out, function(a, b)
        if a.total == b.total then return a.label < b.label end
        return a.total > b.total
    end)

    return out
end)

Staff29.Cb("vfw:staff:phone:listAllNumbers", function(source, page, search)
    local xPlayer = Staff29.Require(source, "wipe")
    if not xPlayer then return { items = {}, total = 0, pageSize = PHONE_PAGE_SIZE } end

    local current = Staff29.ToInt(page, 1, 100000) or 1
    local offset = (current - 1) * PHONE_PAGE_SIZE
    local term = Staff29.Clean(search, 40)

    local where = "cp.phone <> ''"
    local params = {}

    if term and term:gsub("%s", "") ~= "" then
        where = where .. " AND (cp.phone LIKE ? OR c.firstname LIKE ? OR c.lastname LIKE ?)"
        local like = "%" .. term .. "%"
        params = { like, like, like }
    end

    local total = Staff29.Scalar(([[
        SELECT COUNT(*) FROM character_phones cp
        LEFT JOIN characters c ON c.identifier = cp.identifier
        WHERE %s
    ]]):format(where), params, 0) or 0

    local listParams = {}
    for i = 1, #params do listParams[i] = params[i] end
    listParams[#listParams + 1] = PHONE_PAGE_SIZE
    listParams[#listParams + 1] = offset

    local rows = Staff29.Query(([[
        SELECT cp.phone AS phone_number, c.firstname, c.lastname, u.uuid AS uuid
        FROM character_phones cp
        LEFT JOIN characters c ON c.identifier = cp.identifier
        LEFT JOIN users u ON u.id = c.account_id
        WHERE %s
        ORDER BY cp.phone ASC
        LIMIT ? OFFSET ?
    ]]):format(where), listParams)

    local items = {}
    for i = 1, #rows do
        local row = rows[i]
        local name = ("%s %s"):format(row.firstname or "", row.lastname or "")
        items[#items + 1] = {
            phone_number = row.phone_number,
            name = name:gsub("^%s+", ""):gsub("%s+$", ""),
            uuid = row.uuid,
            phone_label = "",
        }
    end

    return { items = items, total = total, pageSize = PHONE_PAGE_SIZE }
end)

Staff29.Cb("vfw:staff:phone:getHistory", function(source)
    local xPlayer = Staff29.Require(source, "wipe")
    if not xPlayer then return {} end
    return { supported = false, items = {}, total = 0, pageSize = 10 }
end)

Staff29.Cb("vfw:staff:phone:getCertifs", function(source)
    local xPlayer = Staff29.Require(source, "wipe")
    if not xPlayer then return {} end
    return {}
end)

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(2000)
    local roles = loadRoles()
    local n = 0
    for _ in pairs(roles) do n = n + 1 end
    console.init("Staff299", ("%d rôles staff chargés depuis la table variables"):format(n))
end)

local function sortedRoles()
    local list = {}
    for id, role in pairs(loadRoles()) do
        list[#list + 1] = {
            id = id,
            name = role.name or id,
            level = tonumber(role.level) or 0,
            perms = countSet(role.permissions),
        }
    end
    table.sort(list, function(a, b)
        if a.level == b.level then return a.id < b.id end
        return a.level < b.level
    end)
    return list
end

local function findRole(input)
    if type(input) ~= "string" or input == "" then return nil, nil end
    local roles = loadRoles()
    if roles[input] then return input, roles[input] end
    local needle = input:lower()
    for id, role in pairs(roles) do
        if id:lower() == needle then return id, role end
        if type(role.name) == "string" and role.name:lower() == needle then return id, role end
    end
    return nil, nil
end

local function printRoleHelp()
    print("^3[setperm]^7 Usage : setperm <id> <grade>")
    print("^3[setperm]^7 Exemple : setperm 1 niveau_6")
    print("^3[setperm]^7 Tapez dans la console txAdmin, sans slash.")
    print("^3[setperm]^7 Grades existants :")
    local list = sortedRoles()
    if #list == 0 then
        print("^1[setperm]^7 Aucun grade chargé.")
        return
    end
    for i = 1, #list do
        local row = list[i]
        print(("^3[setperm]^7   %-16s  %s  (niveau %d, %d droit%s)"):format(
            row.id,
            row.name,
            row.level,
            row.perms,
            row.perms > 1 and "s" or ""
        ))
    end
end

local function applyRoleAbsolute(target, roleId, role)
    local wanted = (roleId == DEV_ROLE) and allPermissionKeys() or (role.permissions or {})
    for key in pairs(copySet(target.permissions)) do
        if wanted[key] ~= true then
            target.setPermission(key, false)
        end
    end
    for key in pairs(wanted) do
        if target.permissions[key] ~= true then
            target.setPermission(key, true)
        end
    end
    setTargetRole(target, roleId)
    pushGlobalData(target)
end

local function canConsolePerm(source, xPlayer)
    if source == 0 then return true end
    return xPlayer and (
        xPlayer.hasPermission("gestion_perm")
        or xPlayer.hasPermission("admin")
        or (xPlayer.globalData and xPlayer.globalData.role == DEV_ROLE)
    )
end

VFW.RegisterCommand("setpermhelp", "", function(source, xPlayer)
    if not canConsolePerm(source, xPlayer) then
        Staff29.Notify(source, "ERROR", "Permissions", "Vous n'avez pas la permission d'utiliser cette commande.")
        return
    end
    printRoleHelp()
    if source ~= 0 then
        Staff29.Notify(source, "INFO", "Permissions", "Liste des grades affichée dans la console serveur (F8 serveur).")
    end
end, {
    help = "Lister les grades staff déjà existants (setperm).",
    allowConsole = true,
})

VFW.RegisterCommand("setperm", "", function(source, xPlayer, args)
    if not canConsolePerm(source, xPlayer) then
        Staff29.Notify(source, "ERROR", "Permissions", "Vous n'avez pas la permission d'utiliser cette commande.")
        return
    end

    local playerId = args and args[1]
    local roleInput = args and args[2] and table.concat(args, " ", 2) or nil
    if not playerId or playerId == "" or not roleInput or roleInput == "" then
        printRoleHelp()
        if source ~= 0 then
            Staff29.Notify(source, "ERROR", "Permissions", "Usage : /setperm <id> <grade> — voir setpermhelp.")
        end
        return
    end

    local roleId, role = findRole(roleInput)
    if not role then
        print(("^1[setperm]^7 Grade inconnu : %s — tapez setpermhelp"):format(tostring(roleInput)))
        if source ~= 0 then
            Staff29.Notify(source, "ERROR", "Permissions", "Grade introuvable. Tapez /setpermhelp.")
        end
        return
    end

    local target = VFW.GetPlayerFromId(tonumber(playerId))
    if not target then
        print(("^1[setperm]^7 Joueur introuvable : %s"):format(tostring(playerId)))
        if source ~= 0 then
            Staff29.Notify(source, "ERROR", "Permissions", "Joueur introuvable.")
        end
        return
    end

    if source ~= 0 and xPlayer then
        assignRole(source, xPlayer, target.source, roleId, true)
        return
    end

    applyRoleAbsolute(target, roleId, role)
    logStaff(0, "role_assign", {
        target = target.identifier,
        targetName = target.name,
        targetSource = target.source,
        role = roleId,
        via = "setperm",
    })
    print(("[setperm] %s (#%s) → %s (%s, %d droits)"):format(
        target.name or "?",
        target.source,
        role.name or roleId,
        roleId,
        countSet(role.permissions)
    ))
    Staff29.Notify(target.source, "INFO", "Permissions", ("Vos droits ont été mis à jour : %s"):format(role.name or roleId))
end, {
    help = "Attribuer un grade staff existant à un joueur connecté.",
    params = {
        { name = "id", help = "ID serveur du joueur" },
        { name = "grade", help = "Identifiant du grade (setpermhelp)" },
    },
    allowConsole = true,
})
