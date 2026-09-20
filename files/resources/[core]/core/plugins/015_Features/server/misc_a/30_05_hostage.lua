local heldBy = {}
local holding = {}

local MAX_HOSTAGE_DISTANCE = 6.0

local EXCLUDED_WEAPONS = {
    ["WEAPON_UNARMED"] = true,
    ["WEAPON_PETROLCAN"] = true,
    ["WEAPON_FIREEXTINGUISHER"] = true,
    ["WEAPON_HAZARDCAN"] = true,
    ["WEAPON_FERTILIZERCAN"] = true,
    ["WEAPON_PARACHUTE"] = true,
    ["WEAPON_FLARE"] = true,
    ["WEAPON_BALL"] = true,
    ["WEAPON_SNOWBALL"] = true,
    ["WEAPON_MOLOTOV"] = true,
    ["WEAPON_GRENADE"] = true,
    ["WEAPON_STICKYBOMB"] = true,
    ["WEAPON_PROXMINE"] = true,
    ["WEAPON_PIPEBOMB"] = true,
    ["WEAPON_BZGAS"] = true,
    ["WEAPON_SMOKEGRENADE"] = true,
    ["WEAPON_RPG"] = true,
    ["WEAPON_GRENADELAUNCHER"] = true,
    ["WEAPON_MINIGUN"] = true,
    ["WEAPON_FIREWORK"] = true,
    ["WEAPON_RAILGUN"] = true,
    ["WEAPON_HOMINGLAUNCHER"] = true,
    ["WEAPON_COMPACTLAUNCHER"] = true,
    ["WEAPON_RAYPISTOL"] = true,
    ["WEAPON_RAYCARBINE"] = true,
    ["WEAPON_RAYMINIGUN"] = true,
}

local function buildAllowedWeapons()
    local allowed = {}

    if type(Config) == "table" and type(Config.Weapons) == "table" then
        for i = 1, #Config.Weapons do
            local weapon = Config.Weapons[i]
            local name = type(weapon) == "table" and weapon.name or nil
            if type(name) == "string" then
                local upper = name:upper()
                if not weapon.melee
                    and not EXCLUDED_WEAPONS[upper]
                    and not upper:find("AIRSOFT", 1, true)
                    and not upper:find("KNIFE", 1, true)
                then
                    allowed[upper] = true
                end
            end
        end
    end

    if next(allowed) == nil then
        allowed["WEAPON_PISTOL"] = true
        allowed["WEAPON_COMBATPISTOL"] = true
        allowed["WEAPON_APPISTOL"] = true
        allowed["WEAPON_HEAVYPISTOL"] = true
        allowed["WEAPON_SNSPISTOL"] = true
        allowed["WEAPON_VINTAGEPISTOL"] = true
        allowed["WEAPON_REVOLVER"] = true
        allowed["WEAPON_MICROSMG"] = true
        allowed["WEAPON_SMG"] = true
        allowed["WEAPON_ASSAULTRIFLE"] = true
        allowed["WEAPON_CARBINERIFLE"] = true
        allowed["WEAPON_PUMPSHOTGUN"] = true
        allowed["WEAPON_SAWNOFFSHOTGUN"] = true
    end

    return allowed
end

local allowedWeapons = {}

CreateThread(function()
    Wait(2000)
    allowedWeapons = buildAllowedWeapons()
    GlobalState.HostageWeaponsAllowed = allowedWeapons
end)

local function playerHasAllowedWeapon(xPlayer)
    if not xPlayer then return false end

    local inv = Misc30.Inv()

    if inv and type(inv.Equipped) == "table" then
        local equipped = inv.Equipped[xPlayer.source]
        if type(equipped) == "table" and type(equipped.name) == "string" then
            return allowedWeapons[equipped.name:upper()] == true
        end
    end

    if type(xPlayer.loadout) == "table" then
        for i = 1, #xPlayer.loadout do
            local entry = xPlayer.loadout[i]
            local name = type(entry) == "table" and entry.name or nil
            if type(name) == "string" and allowedWeapons[name:upper()] then
                return true
            end
        end
    end

    if inv and inv.PlayerList then
        local ok, list = pcall(inv.PlayerList, xPlayer)
        if ok and type(list) == "table" then
            for i = 1, #list do
                local name = list[i].name
                if type(name) == "string" and allowedWeapons[name:upper()] then
                    return true
                end
            end
        end
    end

    return false
end

local function releasePair(holderSrc, killed)
    local victim = holding[holderSrc]
    if not victim then return false end

    holding[holderSrc] = nil
    if heldBy[victim] == holderSrc then
        heldBy[victim] = nil
    end

    if VFW.GetPlayerFromId(victim) then
        if killed then
            TriggerClientEvent("Hostage:cl_kill", victim)
        else
            TriggerClientEvent("Hostage:cl_release", victim)
        end
    end

    return true
end

RegisterNetEvent("Hostage:sync", function(targetSrc)
    local source = source

    local target = Misc30.ToInt(targetSrc, 1)
    if not target or target == source then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if not Misc30.RateLimit(source, "hostageSync", 1000) then return end

    if holding[source] then
        releasePair(source, false)
    end

    if heldBy[target] or holding[target] or heldBy[source] then return end

    if not Misc30.NearPlayers(source, target, MAX_HOSTAGE_DISTANCE) then
        Misc30.Notify(source, "ROUGE", "Cette personne est trop loin.")
        return
    end

    if not playerHasAllowedWeapon(xPlayer) then
        Misc30.Notify(source, "ROUGE", "Cette arme ne permet pas de prendre en otage.")
        return
    end

    holding[source] = target
    heldBy[target] = source

    TriggerClientEvent("Hostage:syncTarget", target, source)

    if VFW.Logs and VFW.Logs.Simple then
        pcall(VFW.Logs.Simple, "hostage", ("%s prend %s en otage"):format(
            Misc30.PlayerName(xPlayer), Misc30.PlayerName(xTarget)))
    end
end)

RegisterNetEvent("Hostage:release", function()
    local source = source
    releasePair(source, false)
end)

RegisterNetEvent("Hostage:kill", function()
    local source = source

    local victim = holding[source]
    if not victim then return end

    if not Misc30.RateLimit(source, "hostageKill", 1000) then return end
    if not Misc30.NearPlayers(source, victim, MAX_HOSTAGE_DISTANCE + 2.0) then
        releasePair(source, false)
        return
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xVictim = VFW.GetPlayerFromId(victim)

    releasePair(source, true)

    if VFW.Logs and VFW.Logs.Simple then
        pcall(VFW.Logs.Simple, "hostage", ("%s execute l'otage %s"):format(
            Misc30.PlayerName(xPlayer), Misc30.PlayerName(xVictim)))
    end
end)

AddEventHandler("vfw:playerDropped", function(source)
    if holding[source] then
        releasePair(source, false)
    end

    local holder = heldBy[source]
    if holder then
        heldBy[source] = nil
        if holding[holder] == source then
            holding[holder] = nil
        end
        if VFW.GetPlayerFromId(holder) then
            TriggerClientEvent("Hostage:cl_holderStop", holder)
        end
    end
end)

AddEventHandler("vfw:onPlayerDeath", function(source)
    local src = tonumber(source)
    if not src then return end
    if holding[src] then
        releasePair(src, false)
    end
end)

function Misc30.IsHoldingHostage(source)
    return holding[tonumber(source) or 0] ~= nil
end

function Misc30.IsHostage(source)
    return heldBy[tonumber(source) or 0] ~= nil
end
