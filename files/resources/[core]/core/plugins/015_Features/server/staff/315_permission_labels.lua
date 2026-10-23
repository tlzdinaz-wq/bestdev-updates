-- Noms des permissions : modifiables depuis Gestion > Permissions.
--
-- Les permissions viennent de config/permissions/config.lua avec un nom ecrit en dur
-- (« Actions de zone (Revive + Soigner) »...). Renommer ne touche jamais la cle (`zone_actions`) : c'est elle
-- que les roles, les commandes et le reste du code utilisent. Seul le libelle affiche change, partout,
-- puisque tous les menus lisent `Config.Permissions[cle].label`.
--
-- Les noms choisis sont gardes dans la variable `permission_labels` (cle -> libelle) et reappliques a chaque
-- demarrage, cote serveur et chez chaque joueur.

local VARIABLE <const> = "permission_labels"
local PERMISSION <const> = "gestion_perm"
local MAX_LENGTH <const> = 80

local original = {}   -- cle -> libelle d'origine, pour pouvoir revenir en arriere

local function overrides()
    local data = VFW.Variables.GetVariable(VARIABLE)
    if type(data) ~= "table" then return {} end
    return data
end

--- Met `Config.Permissions` d'accord avec les noms choisis (et restaure les autres).
local function apply()
    local map = overrides()

    for key, def in pairs(Config.Permissions or {}) do
        if type(def) == "table" then
            local custom = map[key]
            if type(custom) == "string" and custom ~= "" then
                if original[key] == nil then original[key] = def.label or key end
                def.label = custom
            elseif original[key] ~= nil then
                def.label = original[key]
                original[key] = nil
            end
        end
    end

    return map
end

--- Les noms choisis, a un seul exemplaire par cle existante.
local function snapshot()
    local out = {}
    for key, label in pairs(overrides()) do
        if type(label) == "string" and Staff29.Permissions.Exists(key) then out[key] = label end
    end
    return out
end

AddEventHandler("vfw:variables:loaded", function()
    apply()
    TriggerClientEvent("core:permissions:labels", -1, snapshot())
end)

-- Rechargement de la ressource : les variables sont deja en memoire.
CreateThread(function()
    Wait(0)
    if next(overrides()) ~= nil then apply() end
end)

AddEventHandler("vfw:playerLoaded", function(source)
    TriggerClientEvent("core:permissions:labels", source, snapshot())
end)

--- Renomme une permission (`label` vide ou egal au nom d'origine : retour au nom d'origine).
Staff29.Cb("vfw:staff:renamePermission", function(source, key, label)
    local xPlayer = Staff29.Require(source, PERMISSION)
    if not xPlayer then return false, "Vous n'avez pas la permission requise." end
    if not Staff29.RateLimit(source, "perm_rename", 300) then return false, "Veuillez patienter un instant." end

    if type(key) ~= "string" or not Staff29.Permissions.Exists(key) then
        return false, "Cette permission n'existe pas."
    end

    local text = Staff29.Clean(type(label) == "string" and label or "", MAX_LENGTH)
    text = text and text:gsub("^%s+", ""):gsub("%s+$", "") or ""

    local map = overrides()
    local before = (Config.Permissions[key] or {}).label

    if text == "" or text == original[key] then
        map[key] = nil
    else
        map[key] = text
    end

    VFW.Variables.SetVariable(VARIABLE, map)
    VFW.Variables.Flush(VARIABLE)
    apply()

    local labels = snapshot()
    TriggerClientEvent("core:permissions:labels", -1, labels)
    TriggerEvent("vfw:logs:staff", source, "permission_rename", { key = key, from = before, to = (Config.Permissions[key] or {}).label })

    return true, labels
end)

-- Utilise par les tests ; sans effet en jeu.
PermissionLabels = { apply = apply, snapshot = snapshot }
