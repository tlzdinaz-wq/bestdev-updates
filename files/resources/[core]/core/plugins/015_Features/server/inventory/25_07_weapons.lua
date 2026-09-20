local Inv = VFW.Inventory

Inv.Equipped = Inv.Equipped or {}
Inv.BackWeapons = Inv.BackWeapons or {}

local lastAmmoSave = {}
local lastReload = {}

local RELOAD_COOLDOWN = 2000
local AMMO_SAVE_THROTTLE = 800
local MAX_CLIP_CEILING = 250

local customWeaponAmmo = {
    ["WEAPON_AR15"] = "ammo_rifle",
    ["WEAPON_HK416"] = "ammo_rifle",
    ["WEAPON_KS1"] = "ammo_rifle",
    ["WEAPON_M4A1CD"] = "ammo_rifle",
    ["WEAPON_GLOCK20"] = "ammo_pistol",
    ["WEAPON_PDGLOCK17"] = "ammo_pistol",
    ["WEAPON_SIG_SAUCER"] = "ammo_pistol",
    ["WEAPON_SWMP9L"] = "ammo_pistol",
    ["WEAPON_PDPT700"] = "ammo_heavy",
}

local validAmmoTypes = {
    ["ammo_pistol"] = true,
    ["ammo_rifle"] = true,
    ["ammo_shotgun"] = true,
    ["ammo_snip"] = true,
    ["ammo_heavy"] = true,
    ["ammo_airsoft"] = true,
    ["ammo_beanbag"] = true,
    ["ammo_launcher"] = true,
    ["ammo_musquet"] = true,
    ["ammo_flare"] = true,
    ["ammo_rocket"] = true,
}

local function ammoItemForWeapon(weaponName)
    if type(weaponName) ~= "string" then return nil end
    local name = weaponName:upper()

    if customWeaponAmmo[name] then return customWeaponAmmo[name] end
    if name:find("AIRSOFT") then return "ammo_airsoft" end
    if name:find("BEANBAG") then return "ammo_beanbag" end
    if name:find("MUSKET") then return "ammo_musquet" end
    if name:find("FLAREGUN") then return "ammo_flare" end
    if name:find("COMPACTLAUNCHER") or name:find("HOMINGLAUNCHER") then return "ammo_rocket" end
    if name:find("LAUNCHER") or name:find("RPG") or name:find("FIREWORK") then return "ammo_launcher" end
    if name:find("COMBATMG") or name == "WEAPON_MG" or name:find("MINIGUN") or name:find("RAILGUN") or name:find("HEAVYSNIPER") then return "ammo_heavy" end
    if name:find("MARKSMANRIFLE") or name:find("PRECISIONRIFLE") or name:find("SNIPERRIFLE") then return "ammo_snip" end
    if name:find("PISTOL") or name:find("REVOLVER") then return "ammo_pistol" end
    if name:find("SMG") or name:find("PDW") or name:find("GUSENBERG") or name:find("RAYCARBINE") then return "ammo_rifle" end
    if name:find("RIFLE") then return "ammo_rifle" end
    if name:find("SHOTGUN") then return "ammo_shotgun" end
    return nil
end

function Inv.WeaponHash(name)
    if type(name) ~= "string" then return 0 end
    return joaat(name:upper())
end

function Inv.FindWeaponByHash(list, hash)
    hash = tonumber(hash)
    if not hash then return nil end
    for i = 1, #list do
        if Inv.IsWeapon(list[i].name) and Inv.WeaponHash(list[i].name) == hash then
            return list[i]
        end
    end
    return nil
end

function Inv.FindWeaponById(list, weaponId)
    if type(weaponId) ~= "string" then return nil end
    for i = 1, #list do
        local meta = list[i].meta
        if meta and meta.weaponId == weaponId then
            return list[i]
        end
    end
    return nil
end

local function safeMaxClip(entry)
    local value = entry and entry.meta and tonumber(entry.meta.maxClip) or nil
    if not value or value <= 0 then return 30 end
    if value > MAX_CLIP_CEILING then return MAX_CLIP_CEILING end
    return math.floor(value)
end

local function giveWeaponToPlayer(source, entry, ammo)
    local hash = Inv.WeaponHash(entry.name)
    local ped = GetPlayerPed(source)
    local given = false

    if ped and ped ~= 0 then
        given = pcall(function()
            GiveWeaponToPed(ped, hash, ammo or 0, false, true)
            SetCurrentPedWeapon(ped, hash, true)
        end)
    end

    if not given then
        TriggerClientEvent("vfw:staff:receiveWeapon", source, entry.name:upper(), ammo or 0, false)
    end
end

local function removeWeaponsFromPlayer(source)
    local ped = GetPlayerPed(source)
    local removed = false

    if ped and ped ~= 0 then
        removed = pcall(function()
            RemoveAllPedWeapons(ped, true)
        end)
    end

    if not removed then
        TriggerClientEvent("vfw:staff:removeWeapons", source)
    end
end

function Inv.UnequipWeapon(xPlayer, silent)
    local current = Inv.Equipped[xPlayer.source]
    if not current then return end

    Inv.Equipped[xPlayer.source] = nil

    if not silent then
        TriggerClientEvent("vfw:weaponChange", xPlayer.source, current.weaponId)
    end

    SetTimeout(1400, function()
        if Inv.Equipped[xPlayer.source] then return end
        removeWeaponsFromPlayer(xPlayer.source)
    end)
end

function Inv.EquipWeapon(xPlayer, entry)
    if not xPlayer or not entry then return end

    entry.meta = entry.meta or {}
    if type(entry.meta.weaponId) ~= "string" or entry.meta.weaponId == "" then
        entry.meta.weaponId = Inv.NewWeaponId()
    end

    local source = xPlayer.source
    local current = Inv.Equipped[source]

    if current and current.weaponId == entry.meta.weaponId then
        Inv.UnequipWeapon(xPlayer)
        return
    end

    local hash = Inv.WeaponHash(entry.name)
    local ammo = math.floor(tonumber(entry.meta.ammo) or 0)
    if ammo < 0 then ammo = 0 end

    local components = {}
    if type(entry.meta.components) == "table" then
        for i = 1, #entry.meta.components do
            local component = entry.meta.components[i]
            if type(component) == "string" or type(component) == "number" then
                components[#components + 1] = component
            end
        end
    end

    removeWeaponsFromPlayer(source)
    giveWeaponToPlayer(source, entry, ammo)

    Inv.Equipped[source] = {
        weaponId = entry.meta.weaponId,
        name = entry.name,
        hash = hash,
        slot = entry.slot,
        components = components,
        tint = tonumber(entry.meta.tintIdx),
    }

    TriggerClientEvent("vfw:weapon:setEquipAmmo", source, hash, ammo)
    TriggerClientEvent("vfw:weapon:applyEquipComponents", source, hash, components, tonumber(entry.meta.tintIdx), ammo)
    TriggerClientEvent("vfw:weaponChange", source, entry.meta.weaponId)
end

Inv.RegisterNet("vfw:weapon:requestEquippedSync", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local current = Inv.Equipped[source]
    if not current then return end

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindWeaponById(list, current.weaponId)
    if not entry then
        Inv.Equipped[source] = nil
        return
    end

    local ammo = math.floor(tonumber(entry.meta and entry.meta.ammo) or 0)
    giveWeaponToPlayer(source, entry, ammo)
    TriggerClientEvent("vfw:weapon:applyEquipComponents", source, current.hash, current.components, current.tint, ammo)
end)

Inv.RegisterNet("vfw:weapon:saveAmmoState", function(weaponHash, clip)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local hash = tonumber(weaponHash)
    local ammo = math.floor(tonumber(clip) or -1)
    if not hash or ammo < 0 then return end
    if ammo > MAX_CLIP_CEILING then ammo = MAX_CLIP_CEILING end

    local now = GetGameTimer()
    local key = ("%d:%d"):format(source, hash)
    if lastAmmoSave[key] and (now - lastAmmoSave[key].time) < AMMO_SAVE_THROTTLE and lastAmmoSave[key].ammo == ammo then
        return
    end
    lastAmmoSave[key] = { time = now, ammo = ammo }

    local list = Inv.PlayerList(xPlayer)

    local entry
    local current = Inv.Equipped[source]
    if current and current.hash == hash then
        entry = Inv.FindWeaponById(list, current.weaponId)
    end
    if not entry then
        entry = Inv.FindWeaponByHash(list, hash)
    end
    if not entry then return end

    entry.meta = entry.meta or {}
    entry.meta.ammo = ammo
end)

Inv.RegisterNet("vfw:weapon:reportMaxClip", function(weaponHash, maxClip)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local hash = tonumber(weaponHash)
    local value = math.floor(tonumber(maxClip) or 0)
    if not hash or value <= 0 then return end
    if value > MAX_CLIP_CEILING then value = MAX_CLIP_CEILING end

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindWeaponByHash(list, hash)
    if not entry then return end

    entry.meta = entry.meta or {}
    entry.meta.maxClip = value
end)

Inv.RegisterNet("vfw:weapon:reload", function(weaponHash)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local hash = tonumber(weaponHash)
    if not hash then return end

    local now = GetGameTimer()
    if lastReload[source] and (now - lastReload[source]) < RELOAD_COOLDOWN then return end
    lastReload[source] = now

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindWeaponByHash(list, hash)
    if not entry then
        TriggerClientEvent("vfw:weapon:reloadDenied", source, "no_ammo")
        return
    end

    local def = Inv.Def(entry.name)
    local configured = def and def.data and def.data.ammoType
    local ammoType = (type(configured) == "string" and validAmmoTypes[configured] and configured)
        or ammoItemForWeapon(entry.name)

    if not ammoType or not validAmmoTypes[ammoType] then
        TriggerClientEvent("vfw:weapon:reloadDenied", source, "no_ammo")
        return
    end

    local available = Inv.CountByName(list, ammoType)
    if available <= 0 then
        TriggerClientEvent("vfw:weapon:reloadDenied", source, "no_ammo")
        return
    end

    local maxClip = safeMaxClip(entry)
    entry.meta = entry.meta or {}
    local currentClip = math.floor(tonumber(entry.meta.ammo) or 0)
    if currentClip < 0 then currentClip = 0 end
    if currentClip > maxClip then currentClip = maxClip end

    local needed = maxClip - currentClip
    if needed <= 0 then return end

    local taken = math.min(needed, available)
    if taken <= 0 then
        TriggerClientEvent("vfw:weapon:reloadDenied", source, "no_ammo")
        return
    end

    Inv.RemoveByName(list, ammoType, taken)
    entry.meta.ammo = currentClip + taken

    TriggerClientEvent("vfw:weapon:addAmmo", source, hash, taken, maxClip)
    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterNet("vfw:weapon:used", function(weaponHash)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local hash = tonumber(weaponHash)
    if not hash then return end

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindWeaponByHash(list, hash)
    if not entry then return end

    local weaponData = VFW.GetWeaponFromHash and VFW.GetWeaponFromHash(hash) or nil
    if not weaponData or not weaponData.throwable then return end

    Inv.RemoveFromSlot(list, entry.slot, 1)

    local current = Inv.Equipped[source]
    if current and current.weaponId == (entry.meta and entry.meta.weaponId) then
        Inv.Equipped[source] = nil
    end

    Inv.PushPlayer(xPlayer)
end)

Inv.RegisterNet("vfw:weapon:syncBackWeapon", function(weaponName, weaponMeta)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(weaponName) ~= "string" then return end
    if not Inv.Exists(weaponName) then return end

    local meta = type(weaponMeta) == "table" and Inv.SanitizeMeta(weaponMeta) or {}
    Inv.BackWeapons[source] = { name = weaponName, meta = meta or {} }

    TriggerClientEvent("vfw:weapon:otherPlayerBackWeapon", -1, source, weaponName, meta or {})
end)

Inv.RegisterNet("vfw:weapon:syncRemoveBackWeapon", function()
    local source = source
    Inv.BackWeapons[source] = nil
    TriggerClientEvent("vfw:weapon:otherPlayerRemoveBackWeapon", -1, source)
end)

Inv.RegisterNet("vfw:weapon:requestBackWeapons", function()
    local source = source
    for playerId, data in pairs(Inv.BackWeapons) do
        if playerId ~= source then
            TriggerClientEvent("vfw:weapon:otherPlayerBackWeapon", source, playerId, data.name, data.meta)
        end
    end
end)

AddEventHandler("vfw:playerDropped", function(source)
    Inv.Equipped[source] = nil
    lastReload[source] = nil

    if Inv.BackWeapons[source] then
        Inv.BackWeapons[source] = nil
        TriggerClientEvent("vfw:weapon:otherPlayerRemoveBackWeapon", -1, source)
    end

    for key in pairs(lastAmmoSave) do
        if key:sub(1, #tostring(source) + 1) == (tostring(source) .. ":") then
            lastAmmoSave[key] = nil
        end
    end
end)

local defaultBackWeapons = {
    "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2",
    "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE", "WEAPON_SPECIALCARBINE_MK2", "WEAPON_BULLPUPRIFLE",
    "WEAPON_BULLPUPRIFLE_MK2", "WEAPON_COMPACTRIFLE", "WEAPON_MILITARYRIFLE", "WEAPON_HEAVYRIFLE",
    "WEAPON_PUMPSHOTGUN", "WEAPON_PUMPSHOTGUN_MK2", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_ASSAULTSHOTGUN",
    "WEAPON_BULLPUPSHOTGUN", "WEAPON_HEAVYSHOTGUN", "WEAPON_COMBATSHOTGUN", "WEAPON_MUSKET",
    "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2", "WEAPON_PRECISIONRIFLE", "WEAPON_GUSENBERG", "WEAPON_COMBATMG",
    "WEAPON_COMBATMG_MK2", "WEAPON_MG", "WEAPON_AR15", "WEAPON_HK416", "WEAPON_KS1", "WEAPON_M4A1CD",
    "WEAPON_PDPT700",
}

local defaultDrivebyPassenger = {
    "WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_PISTOL50",
    "WEAPON_SNSPISTOL", "WEAPON_SNSPISTOL_MK2", "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL",
    "WEAPON_MACHINEPISTOL", "WEAPON_REVOLVER", "WEAPON_REVOLVER_MK2", "WEAPON_DOUBLEACTION",
    "WEAPON_MICROSMG", "WEAPON_MINISMG", "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG",
    "WEAPON_GLOCK20", "WEAPON_PDGLOCK17", "WEAPON_SIG_SAUCER", "WEAPON_SWMP9L",
}

local defaultDrivebyDriver = {
    "WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_PISTOL50",
    "WEAPON_SNSPISTOL", "WEAPON_SNSPISTOL_MK2", "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL",
    "WEAPON_MICROSMG", "WEAPON_GLOCK20", "WEAPON_PDGLOCK17", "WEAPON_SIG_SAUCER", "WEAPON_SWMP9L",
}

local function toSet(list)
    local out = {}
    for i = 1, #list do
        out[list[i]] = true
    end
    return out
end

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if GlobalState.WeaponBackAllowed == nil then
        GlobalState.WeaponBackAllowed = toSet(defaultBackWeapons)
    end
    if GlobalState.DrivebyAllowedDriver == nil then
        GlobalState.DrivebyAllowedDriver = toSet(defaultDrivebyDriver)
    end
    if GlobalState.DrivebyAllowedPassenger == nil then
        GlobalState.DrivebyAllowedPassenger = toSet(defaultDrivebyPassenger)
    end
end)
