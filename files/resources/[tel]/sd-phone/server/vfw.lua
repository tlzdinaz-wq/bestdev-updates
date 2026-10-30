---@type table Framework detection (bridge.shared.framework): this file does nothing unless it is VFW.
local framework = require 'bridge.shared.framework'
if framework.name ~= 'vfw' then return end

---@type table Settings persistence (server.settings.store): phone_settings rows, numbers.
local store    = require 'server.settings.store'
---@type table Unique-phone / SIM feature flags (server.sim.state).
local simState = require 'server.sim.state'

-- Numéros de téléphone : l'annuaire `character_phones` de VFW et la table de sd-phone doivent
-- raconter la même histoire. La table de sd-phone fait foi (le miroir est écrit par
-- store.setPhoneNumber) ; ce fichier ne fait que deux choses :
--   1. à l'arrivée d'un personnage, il reprend le numéro déjà présent dans l'annuaire s'il en a
--      un (attribué à la main par le gouvernement avant sd-phone), sinon il en attribue un ;
--   2. il expose l'export qui permet à l'annuaire d'imposer un numéro (tablette du gouvernement).

---@type integer Longueur minimale / maximale d'un numéro accepté depuis l'annuaire.
local MIN_DIGITS, MAX_DIGITS = 3, 15

---Le numéro de l'annuaire VFW pour un personnage, en chiffres seuls. Nil si absent ou invalide.
---@param identifier string
---@return string|nil digits
local function directoryNumber(identifier)
    local ok, raw = pcall(function()
        return MySQL.scalar.await('SELECT phone FROM character_phones WHERE identifier = ? LIMIT 1', { identifier })
    end)
    if not ok or type(raw) ~= 'string' then return nil end

    local digits = raw:gsub('%D', '')
    if #digits < MIN_DIGITS or #digits > MAX_DIGITS or digits:sub(1, 1) == '0' then return nil end
    return digits
end

---Donne un numéro à un personnage qui vient d'arriver, une seule fois.
---@param source number
local function onCharacterLoaded(source)
    -- Les SIM portent les numéros en mode « téléphones uniques » : rien à attribuer ici.
    if simState.active and not simState.character then return end

    local player = require 'bridge.server.player'
    local identifier = player.getRealIdentifier(source)
    if not identifier then return end

    if store.getPhoneNumber(identifier) then return end

    local wanted = directoryNumber(identifier)
    if wanted and not store.numberExists(wanted) then
        store.setPhoneNumber(identifier, wanted)
        TriggerEvent('sd-phone:server:number:assigned', identifier, wanted)
        return
    end

    store.ensurePhoneNumber(identifier)
end

AddEventHandler('vfw:characterLoaded', function(source)
    -- Le personnage n'est pas encore résolu par le pont à cet instant précis : on laisse
    -- l'événement de chargement aller au bout avant de lire son identifiant.
    SetTimeout(500, function()
        local ok, err = pcall(onCharacterLoaded, source)
        if not ok then print(('^1[sd-phone:vfw]^0 number assignment failed: %s'):format(tostring(err))) end
    end)
end)

---Server export: impose `number` à un personnage (par identifiant), pour la tablette du
---gouvernement. Refuse un numéro déjà pris. Hors ligne comme en ligne.
---@param identifier string characters.identifier
---@param number string numéro, formaté ou non
---@return boolean ok
---@return string|nil reason 'invalid' | 'taken' | 'unsupported'
exports('setPhoneNumberByIdentifier', function(identifier, number)
    if simState.active and not simState.character then return false, 'unsupported' end
    if type(identifier) ~= 'string' or identifier == '' then return false, 'invalid' end

    local digits = (tostring(number or ''):gsub('%D', ''))
    if #digits < MIN_DIGITS or #digits > MAX_DIGITS or digits:sub(1, 1) == '0' then
        return false, 'invalid'
    end

    local owner = store.getCitizenByNumber(digits)
    if owner and owner ~= identifier then return false, 'taken' end

    store.setPhoneNumber(identifier, digits)
    return true
end)
