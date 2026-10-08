---@meta _
---@diagnostic disable: duplicate-doc-field

-- Hub Gestion > Serveur > Création de personnage
--
-- Règle l'écran que le joueur voit avant d'entrer en jeu : la musique d'ambiance, le
-- nombre de slots et le slot réservé aux VIP, la suppression de personnage.
--
-- Les valeurs vivent dans ConfigManager (table `vfw_config`), pas dans les fichiers de
-- config : elles doivent survivre aux mises à jour de la base, que `config/multicharacter/
-- config.lua` écraserait. Ce fichier ne fournit que les valeurs d'origine, servant de
-- repli et de bouton « rétablir ».

local SETTINGS_KEY <const> = "charCreator"

local DEFAULTS <const> = {
    musicEnabled = false,
    musicUrl = "",
    musicVolume = 30,
    slots = 2,
    vipSlotFrom = 2,
}

local function clampInt(value, low, high, fallback)
    local n = tonumber(value)
    if not n then return fallback end
    n = math.floor(n + 0.5)
    if n < low then return low end
    if n > high then return high end
    return n
end

--- Une URL d'audio, ou rien.
---
--- Les hébergeurs d'images que la base utilise déjà (FiveManage) sont souvent collés sans
--- le `https://` ; on le remet plutôt que de refuser la valeur.
local function cleanUrl(value)
    local raw = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    raw = raw:gsub("^[\"']", ""):gsub("[\"']$", "")
    if raw == "" then return "" end
    if raw:match("^https?://") then return raw:sub(1, 500) end
    if raw:match("^[%w%-%.]+%.%a%a+/") then return ("https://" .. raw):sub(1, 500) end
    return ""
end

local function normalize(raw)
    local src = type(raw) == "table" and raw or {}
    local slots = clampInt(src.slots, 1, 8, DEFAULTS.slots)
    return {
        musicEnabled = src.musicEnabled == true,
        musicUrl = cleanUrl(src.musicUrl),
        musicVolume = clampInt(src.musicVolume, 0, 100, DEFAULTS.musicVolume),
        slots = slots,
        -- 0 = aucun slot VIP ; sinon le premier slot verrouillé, jamais au-delà du dernier.
        vipSlotFrom = clampInt(src.vipSlotFrom, 0, slots + 1, DEFAULTS.vipSlotFrom),
    }
end

--- Réglages effectifs, overrides compris.
---
--- Exposé sur VFW parce que `server/multicharacter.lua` en a besoin pour le nombre de
--- slots, et que l'ordre de chargement des plugins ne garantit pas l'inverse.
function VFW.CharCreatorSettings()
    local stored = nil
    if type(ConfigManager) == "table" and type(ConfigManager.GetOverride) == "function" then
        stored = ConfigManager.GetOverride(SETTINGS_KEY)
    end

    if type(stored) ~= "table" then
        local fallback = {}
        for key, value in pairs(DEFAULTS) do fallback[key] = value end
        return fallback
    end

    return normalize(stored)
end

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
        or xPlayer.hasPermission("server_management") then
        return xPlayer
    end
    return nil
end

local function fail(message)
    return { ok = false, error = message or "Action impossible." }
end

local function panel()
    local settings = VFW.CharCreatorSettings()
    return {
        ok = true,
        settings = settings,
        defaults = DEFAULTS,
    }
end

-- Lu par n'importe quel joueur : l'écran de sélection s'affiche avant que le personnage
-- soit chargé, donc avant toute notion de permission.
Staff29.Cb("charCreator:getSettings", function()
    return VFW.CharCreatorSettings()
end)

Staff29.Cb("gestionCharCreator:hubPanel", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    return panel()
end)

Staff29.Cb("gestionCharCreator:save", function(source, data)
    local xPlayer = staffOk(source)
    if not xPlayer then return fail("Permission refusée.") end

    if type(data) == "string" then
        local decodedOk, decoded = pcall(json.decode, data)
        data = decodedOk and decoded or nil
    end
    if type(data) ~= "table" then return fail("Données invalides.") end

    if type(ConfigManager) ~= "table" or type(ConfigManager.Set) ~= "function" then
        return fail("ConfigManager indisponible : impossible d enregistrer.")
    end

    if data.reset == true then
        ConfigManager.Unset(SETTINGS_KEY)
        local out = panel()
        out.message = "Réglages d origine rétablis."
        TriggerClientEvent("charCreator:settings", -1, out.settings)
        return out
    end

    local clean = normalize(data)

    if clean.musicEnabled and clean.musicUrl == "" then
        return fail("Indiquez un lien de musique, ou décochez la musique.")
    end
    if data.musicUrl ~= nil and tostring(data.musicUrl):gsub("%s", "") ~= "" and clean.musicUrl == "" then
        return fail("Lien de musique invalide : attendu une URL http(s) vers un .mp3.")
    end

    ConfigManager.Set(SETTINGS_KEY, clean)

    -- Les joueurs déjà sur l écran de sélection voient le changement sans se reconnecter.
    TriggerClientEvent("charCreator:settings", -1, clean)

    local out = panel()
    out.message = "Écran de création enregistré."
    return out
end)
