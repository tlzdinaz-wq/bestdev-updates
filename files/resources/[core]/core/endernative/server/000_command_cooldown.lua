-- ═══════════════════════════════════════════════════════════════
-- Cooldown des commandes serveur (Gestion > Développeurs > Bypass cooldown)
--
-- Enveloppe RegisterCommand pour toutes les commandes enregistrées ensuite par
-- cette ressource. La configuration (cooldown simple, max d'utilisations,
-- cooldown après la limite) et les joueurs exemptés sont gérés par
-- plugins/015_Features/server/staff/306_dev_tools.lua (variables `dev_cooldowns`
-- et `dev_cooldown_bypass`). Sans configuration, aucune commande n'est limitée.
-- ═══════════════════════════════════════════════════════════════

local wrapped = {}   -- nom -> true
local usage = {}     -- source -> { [nom] = { last, uses, blockedUntil } }

local function Data(name)
    local d = VFW.Variables and VFW.Variables.Datas and VFW.Variables.Datas[name]
    return type(d) == "table" and d or {}
end

function VFW.ReloadCommandCooldowns()
    -- Les données vivent dans VFW.Variables.Datas : rien à recharger, on garde
    -- la fonction pour compatibilité avec 306_dev_tools.lua.
end

function VFW.ListWrappedCommands()
    local out = {}
    for name in pairs(wrapped) do out[#out + 1] = name end
    table.sort(out)
    return out
end

local function Notify(source, message)
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF", variant = "ERROR", subtitle = "Cooldown", message = message, content = message,
    })
end

local function Remaining(seconds)
    if seconds >= 60 then return ("%d min"):format(math.ceil(seconds / 60)) end
    return ("%d s"):format(seconds)
end

--- Autorise ou non l'exécution d'une commande par un joueur (compte les usages).
---@param source number
---@param name string
---@return boolean
function VFW.CommandCooldownAllows(source, name)
    local cfg = Data("dev_cooldowns")[name]
    if type(cfg) ~= "table" then return true end

    local xPlayer = VFW.GetPlayerFromId and VFW.GetPlayerFromId(source)
    if xPlayer and xPlayer.accountId and Data("dev_cooldown_bypass")[tostring(xPlayer.accountId)] then
        return true
    end

    usage[source] = usage[source] or {}
    local u = usage[source][name] or {}
    usage[source][name] = u
    local now = os.time()

    if u.blockedUntil and now < u.blockedUntil then
        Notify(source, ("/%s : limite atteinte, réessayez dans %s."):format(name, Remaining(u.blockedUntil - now)))
        return false
    end

    local cooldown = tonumber(cfg.cooldown) or 0
    if cooldown > 0 and u.last and (now - u.last) < cooldown then
        Notify(source, ("/%s : cooldown, réessayez dans %s."):format(name, Remaining(cooldown - (now - u.last))))
        return false
    end

    local maxUses = tonumber(cfg.maxUses) or 0
    if maxUses > 0 then
        u.uses = (u.uses or 0) + 1
        if u.uses >= maxUses then
            u.uses = 0
            local after = tonumber(cfg.usageCooldown) or 0
            if after > 0 then u.blockedUntil = now + after end
        end
    end

    u.last = now
    return true
end

local _RegisterCommand = RegisterCommand
RegisterCommand = function(name, handler, restricted)
    if type(name) ~= "string" or type(handler) ~= "function" then
        return _RegisterCommand(name, handler, restricted)
    end
    wrapped[name] = true
    return _RegisterCommand(name, function(source, args, raw)
        if source and source > 0 and not VFW.CommandCooldownAllows(source, name) then
            return
        end
        return handler(source, args, raw)
    end, restricted)
end

AddEventHandler("playerDropped", function()
    usage[source] = nil
end)
