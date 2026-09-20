---@meta _
---@diagnostic disable: duplicate-doc-field

-- Sous-menu natif "Rôles staff" du hub Gestion (sans VUI).

local CAT_LABELS = {
    server = "Serveur",
    commands = "Commandes",
    vehicle = "Véhicule",
    player = "Joueur",
    gestion = "Gestion",
}

local function IsDev()
    local role = VFW.PlayerGlobalData and (VFW.PlayerGlobalData.role or VFW.PlayerGlobalData.roleId)
    return role == "niveau_6"
end

local function CanGrant(permName)
    if IsDev() then return true end
    local perms = VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions
    return perms and perms[permName] == true
end

local function BuildCatalog()
    local buckets, order = {}, {}
    for name, def in pairs(Config.Permissions or {}) do
        if type(def) == "table" then
            local cat = def.category or "other"
            if not buckets[cat] then
                buckets[cat] = {}
                order[#order + 1] = cat
            end
            buckets[cat][#buckets[cat] + 1] = {
                name = name,
                label = def.label or name,
                description = def.description or "",
                locked = not CanGrant(name),
            }
        end
    end
    table.sort(order)
    local catalog = {}
    for i = 1, #order do
        local cat = order[i]
        table.sort(buckets[cat], function(a, b) return tostring(a.label) < tostring(b.label) end)
        catalog[#catalog + 1] = {
            id = cat,
            label = CAT_LABELS[cat] or cat,
            perms = buckets[cat],
        }
    end
    return catalog
end

local function SerializeRoles()
    local roles = TriggerServerCallback("vfw:staff:getRoles")
    local out = {}
    if type(roles) ~= "table" then return out end
    for id, r in pairs(roles) do
        if type(r) == "table" then
            local perms = {}
            if type(r.permissions) == "table" then
                for key, on in pairs(r.permissions) do
                    if on then perms[#perms + 1] = key end
                end
            end
            table.sort(perms)
            out[#out + 1] = {
                id = tostring(id),
                name = r.name or tostring(id),
                level = tonumber(r.level) or 1,
                color = (type(r.color) == "string" and r.color:match("^#%x%x%x%x%x%x$")) and r.color or "#FFFFFF",
                permissions = perms,
            }
        end
    end
    table.sort(out, function(a, b) return (a.level or 0) > (b.level or 0) end)
    return out
end

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["gestion_perm"] == true
end

local function Payload(extra)
    local data = { ok = true, catalog = BuildCatalog(), roles = SerializeRoles() }
    if type(extra) == "table" then
        for k, v in pairs(extra) do data[k] = v end
    end
    return data
end

RegisterNuiCallback("gestion:roles:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les rôles." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:roles:refresh", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Session expirée." })
        return
    end
    TriggerServerCallback("vfw:staff:reloadRoles")
    cb(Payload())
end)

RegisterNuiCallback("gestion:roles:create", function(data, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission requise." })
        return
    end
    local name = data and data.name
    local level = data and data.level
    local ok, idOrErr = TriggerServerCallback("vfw:staff:createRole", name, level)
    if not ok then
        cb({ ok = false, error = tostring(idOrErr or "Impossible de créer le rôle.") })
        return
    end
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Rôles staff',
        message = "Rôle créé : " .. tostring(name) .. ".",
    })
    cb(Payload({ selectId = idOrErr }))
end)

RegisterNuiCallback("gestion:roles:save", function(data, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission requise." })
        return
    end
    if type(data) ~= "table" or type(data.id) ~= "string" then
        cb({ ok = false, error = "Rôle invalide." })
        return
    end
    TriggerServerEvent("vfw:staff:saveRole", {{
        id = data.id,
        power = tonumber(data.level) or 1,
        color = data.color,
        permissions = data.permissions or {},
    }})
    Wait(250)
    VFW.ShowNotification({
        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Rôles staff',
        message = "Rôle enregistré.",
    })
    cb(Payload({ selectId = data.id }))
end)

RegisterNuiCallback("gestion:roles:delete", function(data, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission requise." })
        return
    end
    local id = data and data.id
    if type(id) ~= "string" or id == "" then
        cb({ ok = false, error = "Rôle invalide." })
        return
    end
    TriggerServerEvent("vfw:staff:deleteRole", id)
    Wait(400)
    TriggerServerCallback("vfw:staff:reloadRoles")
    cb(Payload())
end)
