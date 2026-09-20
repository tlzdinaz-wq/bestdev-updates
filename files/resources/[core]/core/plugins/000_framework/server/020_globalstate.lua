local WEAPON_DAMAGE_KEY = "weapon_damage_config"
local ANTIATTACH_KEY = "antiattach_enabled"

local weaponDamage = {}
local loaded = false

local FIELDS = {
    hitsToKO = "number",
    canKill = "boolean",
    oneshot = "boolean",
    bulletsToKill = "number",
    bulletsToKillArmor = "number",
    headshotMultiplier = "number",
}

local MELEE_FIELDS = {
    hitsToKO = true,
    oneshot = true,
}

local function isMeleeWeapon(weaponName)
    local weapon = VFW.GetWeaponFromHash(weaponName)
    if type(weapon) == "table" then
        return weapon.melee and true or false
    end
    local list = VFW.GetWeaponList(false)
    if type(list) == "table" then
        for i = 1, #list do
            if list[i].name == weaponName then
                return list[i].melee and true or false
            end
        end
    end
    return false
end

local function newEntry(weaponName, field)
    return {
        isMelee = isMeleeWeapon(weaponName) or MELEE_FIELDS[field] or false,
        hitsToKO = 0,
        canKill = false,
        oneshot = false,
        bulletsToKill = 0,
        bulletsToKillArmor = 0,
        headshotMultiplier = 1.0,
    }
end

local function isEmptyEntry(entry)
    return entry.hitsToKO == 0
        and entry.canKill == false
        and entry.oneshot == false
        and entry.bulletsToKill == 0
        and entry.bulletsToKillArmor == 0
        and (entry.headshotMultiplier or 1.0) <= 1.0
end

local function publish()
    GlobalState.WeaponDamageConfig = weaponDamage
end

local function persist()
    VFW.Variables.SetVariable(WEAPON_DAMAGE_KEY, weaponDamage)
    publish()
end

function VFW.GetWeaponDamageConfig(weaponName)
    if type(weaponName) ~= "string" then return weaponDamage end
    return weaponDamage[string.upper(weaponName)]
end

CreateThread(function()
    local waited = 0
    while not VFW.Ready and waited < 30000 do
        Wait(100)
        waited = waited + 100
    end
    Wait(1500)

    local stored = VFW.Variables.GetVariable(WEAPON_DAMAGE_KEY)
    if type(stored) == "table" then
        for name, entry in pairs(stored) do
            if type(name) == "string" and type(entry) == "table" then
                weaponDamage[string.upper(name)] = entry
            end
        end
    end

    local antiAttach = VFW.Variables.GetVariable(ANTIATTACH_KEY)
    if type(antiAttach) == "table" and antiAttach.enabled ~= nil then
        GlobalState.AntiAttachEnabled = antiAttach.enabled and true or false
    elseif GlobalState.AntiAttachEnabled == nil then
        GlobalState.AntiAttachEnabled = true
    end

    loaded = true
    publish()
    console.init("WeaponDamage", ("%d arme(s) configuree(s)"):format(VFW.Table.SizeOf(weaponDamage)))
end)

RegisterServerCallback("vfw:weaponDamage:update", function(source, weaponName, field, value)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("builder_weapon_damage") then return false end
    if type(weaponName) ~= "string" or weaponName == "" then return false end
    if type(field) ~= "string" or not FIELDS[field] then return false end
    if not loaded then return false end

    local expected = FIELDS[field]
    if expected == "number" then
        value = tonumber(value)
        if not value then return false end
        if value < 0 then return false end
        if field == "hitsToKO" and value > 20 then return false end
        if field == "headshotMultiplier" and value > 10 then return false end
        if (field == "bulletsToKill" or field == "bulletsToKillArmor") and value > 100 then return false end
    else
        value = value and true or false
    end

    weaponName = string.upper(weaponName)

    local entry = weaponDamage[weaponName] or newEntry(weaponName, field)
    entry[field] = value

    if MELEE_FIELDS[field] then
        entry.isMelee = true
    end

    if isEmptyEntry(entry) then
        weaponDamage[weaponName] = nil
    else
        weaponDamage[weaponName] = entry
    end

    persist()
    TriggerEvent("vfw:logs:staff", source, "weapon_damage", { weapon = weaponName, field = field, value = value })
    return true
end)

RegisterServerCallback("vfw:weaponDamage:reset", function(source, weaponName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("builder_weapon_damage") then return false end
    if type(weaponName) ~= "string" or weaponName == "" then return false end
    if not loaded then return false end

    weaponDamage[string.upper(weaponName)] = nil
    persist()
    TriggerEvent("vfw:logs:staff", source, "weapon_damage_reset", { weapon = string.upper(weaponName) })
    return true
end)

RegisterServerCallback("vfw:weaponDamage:resetAll", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.hasPermission("builder_weapon_damage") then return false end
    if not loaded then return false end

    weaponDamage = {}
    persist()
    TriggerEvent("vfw:logs:staff", source, "weapon_damage_reset_all", {})
    return true
end)

local BASE_HEALTH_POOL = 100.0

AddEventHandler("weaponDamageEvent", function(sender, data)
    local shooter = tonumber(sender)
    if not shooter or type(data) ~= "table" then return end
    if not VFW.GetPlayerFromId(shooter) then return end

    local weapon = VFW.GetWeaponFromHash(data.weaponType)
    if type(weapon) ~= "table" or type(weapon.name) ~= "string" then return end

    local config = weaponDamage[string.upper(weapon.name)]
    if not config or config.isMelee then return end

    local multiplier = tonumber(config.headshotMultiplier) or 1.0
    local bullets = tonumber(config.bulletsToKill) or 0
    if multiplier <= 1.0 or bullets <= 0 then return end

    local perBullet = BASE_HEALTH_POOL / bullets
    local bonus = math.floor(perBullet * (multiplier - 1.0))
    if bonus <= 0 then return end

    local targets = data.hitGlobalIds
    if type(targets) ~= "table" then return end

    for i = 1, #targets do
        local netId = tonumber(targets[i])
        if netId and netId ~= 0 then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                local victim = NetworkGetEntityOwner(entity)
                if victim and victim > 0 then
                    TriggerClientEvent("ac:checkHeadshot", victim, { netId = netId, bonusDamage = bonus })
                end
            end
        end
    end
end)

VFW.RegisterCommand("antiattach", "staff_menu", function(source, xPlayer, args)
    local wanted
    local arg = args and args[1]
    if arg == "on" or arg == "1" or arg == "true" then
        wanted = true
    elseif arg == "off" or arg == "0" or arg == "false" then
        wanted = false
    else
        wanted = not (GlobalState.AntiAttachEnabled ~= false)
    end

    GlobalState.AntiAttachEnabled = wanted
    VFW.Variables.SetVariable(ANTIATTACH_KEY, { enabled = wanted })

    if xPlayer then
        xPlayer.showNotification({
            type = "STAFF",
            variant = wanted and "SUCCESS" or "WARNING",
            subtitle = "AntiAttach",
            message = wanted and "Scan anti-attach active." or "Scan anti-attach desactive.",
        })
    else
        console.info(("AntiAttach %s"):format(wanted and "active" or "desactive"))
    end

    TriggerEvent("vfw:logs:staff", source, "antiattach", { enabled = wanted })
end, {
    help = "Activer / desactiver le scan anti-attach",
    params = { { name = "etat", help = "on ou off (vide = bascule)" } },
    allowConsole = true,
})

AddEventHandler("vfw:playerLoaded", function()
    VFW.SetGlobalPlayerCount()
end)

AddEventHandler("vfw:characterLoaded", function()
    VFW.SetGlobalPlayerCount()
end)

AddEventHandler("vfw:playerDropped", function()
    VFW.SetGlobalPlayerCount()
end)
