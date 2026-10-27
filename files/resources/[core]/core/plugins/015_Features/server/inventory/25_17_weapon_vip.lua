local Inv = VFW.Inventory

-- Personnalisation des armes du menu VIP (« Personnaliser mes armes ») : teinte et skins cosmétiques.
-- Le menu envoyait vfw:weapon:setTint, vfw:weapon:applyCosmeticComponent et vfw:weapon:removeCosmeticComponent,
-- mais aucun code serveur n'y répondait : rien ne s'appliquait et rien n'était gardé.

local MAX_TINT, MAX_TINT_MK2 = 7, 31

local function vipAllowed(xPlayer)
    local cfg = VIPConfig and VIPConfig.WeaponCustomization
    if cfg and cfg.enabled == false then return false end

    local tier = 0
    if Staff29 and Staff29.VIP and Staff29.VIP.GetPlayerTier then
        tier = Staff29.VIP.GetPlayerTier(xPlayer)
        local tierCfg = Staff29.VIP.GetTierConfig and Staff29.VIP.GetTierConfig(tier)
        if tierCfg and tierCfg.weaponCustomization ~= nil then
            return tonumber(tierCfg.weaponCustomization) == 1
        end
    else
        tier = tonumber(xPlayer.vipTier) or 0
    end
    return tier >= ((cfg and cfg.minVipTier) or 1)
end

local function refuse(xPlayer, message)
    if xPlayer.showNotification then
        xPlayer.showNotification({ type = "STAFF", variant = "ERROR", subtitle = "Armes VIP", message = message })
    end
end

local function weaponConfig(name)
    if type(name) ~= "string" then return nil end
    local upper = name:upper()
    for _, w in ipairs(Config.Weapons or {}) do
        if w.name and w.name:upper() == upper then return w end
    end
    return nil
end

--- L'arme du joueur et sa fiche de config, ou nil.
local function ownWeapon(xPlayer, weaponId)
    if type(weaponId) ~= "string" then return nil end
    local entry = Inv.FindWeaponById(Inv.PlayerList(xPlayer), weaponId)
    if not entry then return nil end
    return entry, weaponConfig(entry.name)
end

local function allowedPlayer(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if not (Feat27 and Feat27.RateLimit) or Feat27.RateLimit(source, "weaponVip", 150) then
        if not vipAllowed(xPlayer) then
            refuse(xPlayer, "La personnalisation des armes est réservée aux VIP.")
            return nil
        end
        return xPlayer
    end
    return nil
end

Inv.RegisterNet("vfw:weapon:setTint", function(weaponId, tintIndex)
    local source = source
    local xPlayer = allowedPlayer(source)
    if not xPlayer then return end

    local entry, cfg = ownWeapon(xPlayer, weaponId)
    if not entry or not cfg then return end
    if cfg.noTint or cfg.airsoft then return refuse(xPlayer, "Cette arme n'a pas de teinte.") end

    local tint = math.tointeger(tonumber(tintIndex))
    local max = cfg.name:upper():find("_MK2", 1, true) and MAX_TINT_MK2 or MAX_TINT
    if not tint or tint < 0 or tint > max then return end

    if Inv.SetWeaponTint(xPlayer, weaponId, tint) then
        TriggerClientEvent("vfw:weapon:tintUpdated", source, weaponId, tint)
    end
end)

local function cosmeticOf(cfg, componentHash)
    if type(componentHash) ~= "string" or not IsCosmeticComponent(componentHash) then return false end
    for _, comp in ipairs(cfg.components or {}) do
        if comp.hash == componentHash then return true end
    end
    return false
end

local function changeCosmetic(source, weaponId, componentHash, add)
    local xPlayer = allowedPlayer(source)
    if not xPlayer then return end

    local entry, cfg = ownWeapon(xPlayer, weaponId)
    if not entry or not cfg or not cosmeticOf(cfg, componentHash) then return end

    local components, found = {}, false
    for _, existing in ipairs(type(entry.meta.components) == "table" and entry.meta.components or {}) do
        if existing == componentHash then
            found = true
            if add then components[#components + 1] = existing end
        else
            components[#components + 1] = existing
        end
    end
    if add and not found then components[#components + 1] = componentHash end

    -- un seul skin à la fois : ceux de la même arme se remplacent
    if add and not found then
        local kept = {}
        for _, existing in ipairs(components) do
            if existing == componentHash or not cosmeticOf(cfg, existing) then kept[#kept + 1] = existing end
        end
        components = kept
    end

    if Inv.SetWeaponComponents(xPlayer, weaponId, components) then
        TriggerClientEvent("vfw:weapon:componentUpdated", source, weaponId, components)
    end
end

Inv.RegisterNet("vfw:weapon:applyCosmeticComponent", function(weaponId, componentHash)
    changeCosmetic(source, weaponId, componentHash, true)
end)

Inv.RegisterNet("vfw:weapon:removeCosmeticComponent", function(weaponId, componentHash)
    changeCosmetic(source, weaponId, componentHash, false)
end)
