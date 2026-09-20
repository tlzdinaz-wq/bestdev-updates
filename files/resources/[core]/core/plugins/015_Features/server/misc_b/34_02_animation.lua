local phase = {}
local lastEmote = {}
local emoteProps = {}
local sharedRequests = {}

local function clearProps(source)
    local slots = emoteProps[source]
    if not slots then return end
    for propId, index in pairs(slots) do
        if VFW.NetAttached and VFW.NetAttached.Detach then
            pcall(VFW.NetAttached.Detach, source, index)
        end
        slots[propId] = nil
    end
    emoteProps[source] = nil
end

local function clearPhase(source)
    if not phase[source] then return end
    phase[source] = nil
    TriggerClientEvent("vfw:newanim:phaseClear", -1, source)
end

AddEventHandler("vfw:newanim:synced", function(source, emote)
    lastEmote[source] = emote
end)

AddEventHandler("vfw:playerDropped", function(source)
    clearProps(source)
    if phase[source] then
        phase[source] = nil
        TriggerClientEvent("vfw:newanim:phaseClear", -1, source)
    end
    lastEmote[source] = nil
    sharedRequests[source] = nil
end)

RegisterNetEvent("vfw:newanim:phaseStart", function(animDict, animName, duration, inheritFrom)
    local source = source
    if type(animDict) ~= "string" or type(animName) ~= "string" then return end
    if #animDict > 128 or #animName > 128 then return end
    local dur = tonumber(duration)
    if not dur or dur ~= dur or dur <= 0 or dur > 3600000 then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local startedAt = GetGameTimer()
    local from = tonumber(inheritFrom)
    if from and phase[from] and phase[from].animDict == animDict and phase[from].animName == animName then
        startedAt = phase[from].startedAt
    end

    phase[source] = {
        animDict = animDict,
        animName = animName,
        startedAt = startedAt,
        duration = math.floor(dur),
    }

    TriggerClientEvent("vfw:newanim:phaseBroadcast", -1, source, animDict, animName, startedAt, math.floor(dur), GetGameTimer())
end)

RegisterNetEvent("vfw:newanim:phaseStop", function()
    local source = source
    clearPhase(source)
end)

MiscB.Cb("vfw:newanim:phaseSnapshot", function(source)
    local entries = {}
    for src, entry in pairs(phase) do
        entries[#entries + 1] = {
            src = src,
            animDict = entry.animDict,
            animName = entry.animName,
            startedAt = entry.startedAt,
            duration = entry.duration,
        }
    end
    return { serverNow = GetGameTimer(), entries = entries }
end)

MiscB.Cb("vfw:newanim:copy", function(source, targetId)
    local target = tonumber(targetId)
    if not target then return nil end
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return nil end
    local emote = lastEmote[target]
    if type(emote) ~= "string" or emote == "" then return nil end
    return emote
end)

RegisterNetEvent("vfw:newanim:spawnProp", function(propModel, boneTag, offset, rotation, propId, propRotOrder)
    local source = source
    if type(propModel) ~= "string" and type(propModel) ~= "number" then return end
    if type(propModel) == "string" and #propModel > 96 then return end
    if type(boneTag) ~= "string" and type(boneTag) ~= "number" then return end
    local id = tonumber(propId)
    if not id or id < 1 or id > 4 then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not VFW.NetAttached or not VFW.NetAttached.Attach then return end

    emoteProps[source] = emoteProps[source] or {}
    local previous = emoteProps[source][id]
    if previous then
        pcall(VFW.NetAttached.Detach, source, previous)
        emoteProps[source][id] = nil
    end

    local off = MiscB.Plain(offset, { x = 0.0, y = 0.0, z = 0.0 })
    local rot = MiscB.Plain(rotation, { x = 0.0, y = 0.0, z = 0.0 })

    local index = VFW.NetAttached.Attach(source, {
        id = ("emoteprop_%d_%d"):format(source, id),
        group = "emoteprop",
        model = propModel,
        attach = {
            boneTag = boneTag,
            offset = off,
            rotation = rot,
            rotOrder = tonumber(propRotOrder) or 1,
            detachWhenDead = true,
            detachWhenRagdoll = true,
        },
    })

    if index ~= nil then
        emoteProps[source][id] = index
    end
end)

RegisterNetEvent("vfw:newanim:deleteProp", function(propId)
    local source = source
    local id = tonumber(propId)
    if not id then return end
    local slots = emoteProps[source]
    if not slots or slots[id] == nil then return end
    if VFW.NetAttached and VFW.NetAttached.Detach then
        pcall(VFW.NetAttached.Detach, source, slots[id])
    end
    slots[id] = nil
end)

RegisterNetEvent("vfw:newanim:deleteAllProps", function()
    local source = source
    clearProps(source)
    if VFW.NetAttached and VFW.NetAttached.DetachGroup then
        pcall(VFW.NetAttached.DetachGroup, source, "emoteprop")
    end
end)

RegisterNetEvent("vfw:newanim:requestShared", function(targetId, emote)
    local source = source
    local target = tonumber(targetId)
    if not target or type(emote) ~= "string" or #emote > 96 then return end
    if target == source then return end
    if not MiscB.Rate(source, "newanim_shared", 1000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end

    if MiscB.Dist(xPlayer.getCoords(), xTarget.getCoords()) > 10.0 then return end

    sharedRequests[target] = { from = source, emote = emote, at = GetGameTimer() }

    local askerName = MiscB.CharName(xPlayer)
    TriggerClientEvent("vfw:newanim:askShared", target, source, askerName, emote)
end)

RegisterNetEvent("vfw:newanim:acceptShared", function(askerId, emote)
    local source = source
    local asker = tonumber(askerId)
    if not asker or type(emote) ~= "string" then return end

    local pending = sharedRequests[source]
    if not pending or pending.from ~= asker then return end
    if (GetGameTimer() - pending.at) > 60000 then
        sharedRequests[source] = nil
        return
    end
    sharedRequests[source] = nil

    local xAsker = VFW.GetPlayerFromId(asker)
    if not xAsker then return end

    TriggerClientEvent("nSyncPlayEmote", source, pending.emote, asker)
    TriggerClientEvent("nSyncPlayEmoteSource", asker, pending.emote, source)
end)

RegisterNetEvent("vfw:newanim:refuseShared", function(askerId)
    local source = source
    local asker = tonumber(askerId)
    if not asker then return end
    if sharedRequests[source] and sharedRequests[source].from == asker then
        sharedRequests[source] = nil
    end
    local xAsker = VFW.GetPlayerFromId(asker)
    if not xAsker then return end
    VFW.ShowNotification(asker, { type = "ROUGE", content = "Votre demande d'animation a ete refusee." })
end)

RegisterNetEvent("vfw:newanim:cancelSharedAnim", function(alsoTarget)
    local source = source
    clearPhase(source)
    clearProps(source)
    lastEmote[source] = nil

    if alsoTarget == true then
        for target, pending in pairs(sharedRequests) do
            if pending.from == source then
                sharedRequests[target] = nil
            end
        end
    end
end)

MiscB.Cb("vfw:animation:getWalk", function(source, targetId)
    local target = tonumber(targetId)
    if not target then return nil end
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return nil end
    local walk = xTarget.getMeta and xTarget.getMeta("walkstyle") or nil
    if type(walk) ~= "string" or walk == "" then return nil end
    return walk
end)

MiscB.Cb("vfw:animManager:getOverrides", function(source)
    if not VFW.Variables or not VFW.Variables.GetVariable then return {} end
    local ok, data = pcall(VFW.Variables.GetVariable, "anim_overrides")
    if not ok or type(data) ~= "table" then return {} end
    return data
end)

-- ═══════════════════════════════════════════════════════════════
-- Animation Manager : sauvegarde des overrides + animations personnalisées
-- (Gestion > Développeurs > Animation manager / Ajouter une animation)
-- ═══════════════════════════════════════════════════════════════

local function CanManageAnims(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission("manage_anim") or xPlayer.hasPermission("dev") or xPlayer.hasPermission("gestion")
end

local function CleanStr(v, max)
    if type(v) ~= "string" then return nil end
    v = v:gsub("^%s+", ""):gsub("%s+$", "")
    if v == "" then return nil end
    return v:sub(1, max or 128)
end

local function GetVar(name)
    local ok, data = pcall(VFW.Variables.GetVariable, name)
    if not ok or type(data) ~= "table" then return {} end
    return data
end

-- Overrides (activer/désactiver, renommer, preview, catégorie) : l'event était
-- envoyé par le client mais jamais traité côté serveur -> rien n'était sauvegardé.
RegisterNetEvent("vfw:animManager:setOverride", function(name, override)
    local source = source
    if not CanManageAnims(source) then return end
    name = CleanStr(name, 64)
    if not name then return end

    local data = GetVar("anim_overrides")
    if type(override) == "table" then
        local clean = {
            disabled = override.disabled == true or nil,
            previewDisabled = override.previewDisabled == true or nil,
            label = CleanStr(override.label, 64),
            category = CleanStr(override.category, 64),
        }
        data[name] = next(clean) and clean or nil
    else
        data[name] = nil
    end

    VFW.Variables.SetVariable("anim_overrides", data)
    TriggerClientEvent("vfw:animManager:overridesUpdated", -1, data)
end)

--- Valide une animation personnalisée envoyée par le client.
---@param def table
---@return table|nil clean, string|nil err
local function SanitizeCustomAnim(def)
    if type(def) ~= "table" then return nil, "Données invalides." end

    local key = CleanStr(def.key, 40)
    if not key then return nil, "Identifiant manquant." end
    key = key:lower():gsub("[^%w_]", "")
    if key == "" then return nil, "Identifiant invalide (lettres, chiffres et _ uniquement)." end

    local category = CleanStr(def.category, 64)
    if not category then return nil, "Catégorie manquante." end
    local label = CleanStr(def.label, 64)
    if not label then return nil, "Nom manquant." end

    local kind = def.kind
    if kind ~= "walk" and kind ~= "expression" and kind ~= "scenario" then kind = "emote" end

    local clean = { key = key, category = category, label = label, kind = kind }

    if kind == "walk" then
        clean.dict = CleanStr(def.dict, 128)
        if not clean.dict then return nil, "Clipset de marche manquant." end
    elseif kind == "expression" then
        clean.dict = CleanStr(def.dict, 128)
        if not clean.dict then return nil, "Nom de l'expression manquant." end
    elseif kind == "scenario" then
        clean.anim = CleanStr(def.anim, 128)
        if not clean.anim then return nil, "Nom du scénario manquant." end
    else
        clean.dict = CleanStr(def.dict, 128)
        clean.anim = CleanStr(def.anim, 128)
        if not clean.dict or not clean.anim then return nil, "Dictionnaire et animation obligatoires." end

        local o = type(def.options) == "table" and def.options or {}
        local opts = {
            loop = o.loop == true or nil,
            moving = o.moving == true or nil,
            stuck = o.stuck == true or nil,
            fullBody = o.fullBody == true or nil,
            duration = tonumber(o.duration),
        }
        if opts.duration and opts.duration <= 0 then opts.duration = nil end

        local prop = CleanStr(o.prop, 64)
        if prop then
            opts.prop = prop
            opts.propBone = tonumber(o.propBone) or 57005
            local pl = type(o.propPlacement) == "table" and o.propPlacement or {}
            opts.propPlacement = {}
            for i = 1, 6 do
                opts.propPlacement[i] = tonumber(pl[i]) or 0.0
            end
        end
        clean.options = opts
    end

    return clean
end

MiscB.Cb("vfw:animManager:getCustom", function(source)
    return GetVar("anim_custom")
end)

RegisterNetEvent("vfw:animManager:setCustom", function(def)
    local source = source
    if not CanManageAnims(source) then return end

    local clean, err = SanitizeCustomAnim(def)
    if not clean then
        VFW.ShowNotification(source, { type = "ROUGE", content = err })
        return
    end

    local data = GetVar("anim_custom")
    data[clean.key] = clean
    VFW.Variables.SetVariable("anim_custom", data)
    TriggerClientEvent("vfw:animManager:customUpdated", -1, data)
    VFW.ShowNotification(source, { type = "VERT", content = ("Animation « %s » enregistrée."):format(clean.label) })
end)

RegisterNetEvent("vfw:animManager:deleteCustom", function(key)
    local source = source
    if not CanManageAnims(source) then return end
    key = CleanStr(key, 40)
    if not key then return end

    local data = GetVar("anim_custom")
    if not data[key] then return end
    data[key] = nil
    VFW.Variables.SetVariable("anim_custom", data)
    TriggerClientEvent("vfw:animManager:customUpdated", -1, data)
    VFW.ShowNotification(source, { type = "VERT", content = "Animation supprimée." })
end)
