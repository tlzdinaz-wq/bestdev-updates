-- Listes d'armes réglables par le staff : drive-by (pilote / passager) et armes portées dans le dos.
--
-- Les menus Builders > DRIVE-BY et Builders > ARMES DANS LE DOS appellent
-- `vfw:driveby:toggle`, `vfw:driveby:setAll`, `vfw:weaponBack:toggle` et `vfw:weaponBack:setAll`.
-- Le client lit les listes dans `GlobalState` (voir 25_07_weapons.lua, qui pose les valeurs par défaut
-- tant que rien n'a été enregistré). Ici on les modifie ET on les garde dans la table `variables` : sans
-- ça un redémarrage du serveur remettait les listes par défaut.

local LISTS <const> = {
    driveby_driver    = { global = "DrivebyAllowedDriver",    variable = "driveby_allowed_driver",    permission = "builder_driveby",     label = "Drive-by pilote" },
    driveby_passenger = { global = "DrivebyAllowedPassenger", variable = "driveby_allowed_passenger", permission = "builder_driveby",     label = "Drive-by passager" },
    weapon_back       = { global = "WeaponBackAllowed",       variable = "weapon_back_allowed",       permission = "builder_weapon_back", label = "Armes dans le dos" },
}

local MAX_NAME <const> = 64

--- Une arme du catalogue (nom en majuscules), ou nil.
local function weaponName(value)
    if type(value) ~= "string" or value == "" or #value > MAX_NAME then return nil end
    local item = VFW.Items and (VFW.Items[value] or VFW.Items[value:lower()] or VFW.Items[value:upper()])
    if type(item) ~= "table" or item.type ~= "weapons" then return nil end
    return value:upper()
end

--- La liste enregistrée (ensemble NOM -> true), ou nil si rien n'a encore été enregistré.
local function savedSet(list)
    local data = VFW.Variables.Datas[list.variable]
    if type(data) ~= "table" then return nil end
    local set = {}
    for key, value in pairs(data) do
        if type(key) == "number" and type(value) == "string" then
            set[value:upper()] = true
        elseif type(key) == "string" and value == true then
            set[key:upper()] = true
        end
    end
    return set
end

--- Pose la liste dans GlobalState (une nouvelle table, sinon rien n'est répliqué aux clients).
local function publish(list, set)
    GlobalState[list.global] = set
end

local function copy(set)
    local out = {}
    for name in pairs(set or {}) do out[name] = true end
    return out
end

--- Enregistre la liste (tableau trié : stable d'un enregistrement à l'autre) et la publie.
local function save(list, set)
    local names = {}
    for name in pairs(set) do names[#names + 1] = name end
    table.sort(names)
    VFW.Variables.SetVariable(list.variable, names)
    VFW.Variables.Flush(list.variable)
    publish(list, set)
end

--- Applique les listes enregistrées par-dessus les valeurs par défaut.
local function applySaved()
    for _, list in pairs(LISTS) do
        local set = savedSet(list)
        if set then publish(list, set) end
    end
end

AddEventHandler("vfw:variables:loaded", applySaved)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    -- 25_07_weapons.lua pose les valeurs par défaut au même moment : on repasse après lui.
    CreateThread(function()
        Wait(0)
        applySaved()
    end)
end)

local function deny(source, message)
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF", variant = "ERROR", subtitle = "Armes", message = message, content = message,
    })
end

--- Le joueur et la liste visée, ou nil (la raison est alors envoyée au joueur).
local function resolve(source, key)
    local list = LISTS[key]
    if not list then return nil end
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not xPlayer.hasPermission(list.permission) then
        deny(source, "Vous n'avez pas la permission requise.")
        return nil
    end
    return list
end

local function seatKey(seatType)
    if seatType == "driver" then return "driveby_driver" end
    if seatType == "passenger" then return "driveby_passenger" end
    return nil
end

local function toggle(source, key, weapon)
    local list = resolve(source, key)
    if not list then return nil end

    local name = weaponName(weapon)
    if not name then
        deny(source, "Cette arme n'existe pas.")
        return nil
    end

    local set = copy(GlobalState[list.global])
    local state = not set[name]
    set[name] = state and true or nil
    save(list, set)

    TriggerEvent("vfw:logs:staff", source, "weapon_list_toggle", { list = list.label, weapon = name, allowed = state })
    return state
end

--- `names` : les armes affichées par le menu (« Tout activer » ne touche que celles-là). Sans liste, toutes
--- les armes à feu du catalogue.
local function setAll(source, key, enable, names)
    local list = resolve(source, key)
    if not list then return false end

    local set = {}
    if enable then
        if type(names) == "table" then
            for i = 1, math.min(#names, 1000) do
                local name = weaponName(names[i])
                if name then set[name] = true end
            end
        else
            for _, weapon in ipairs(Config.Weapons or {}) do
                if not weapon.melee and not weapon.throwable then
                    local name = weaponName(weapon.name)
                    if name then set[name] = true end
                end
            end
        end
    end

    save(list, set)
    TriggerEvent("vfw:logs:staff", source, "weapon_list_all", { list = list.label, allowed = enable and true or false })
    return true
end

RegisterServerCallback("vfw:driveby:toggle", function(source, weapon, seatType)
    local key = seatKey(seatType)
    if not key then return nil end
    return toggle(source, key, weapon)
end)

RegisterServerCallback("vfw:driveby:setAll", function(source, enable, seatType, names)
    local key = seatKey(seatType)
    if not key then return false end
    return setAll(source, key, enable == true, names)
end)

RegisterServerCallback("vfw:weaponBack:toggle", function(source, weapon)
    return toggle(source, "weapon_back", weapon)
end)

RegisterServerCallback("vfw:weaponBack:setAll", function(source, enable, names)
    return setAll(source, "weapon_back", enable == true, names)
end)

-- Utilisé par les tests ; sans effet en jeu.
WeaponLists = { applySaved = applySaved }
