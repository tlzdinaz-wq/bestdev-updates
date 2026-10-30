---Pont VFW (framework maison du serveur, ressource `core`).
---
---VFW n'est ni ESX ni QBCore : le joueur y porte son inventaire à emplacements, l'espèces est un
---item, la banque un compte. Plutôt que de copier l'objet VFW dans cette ressource (skin,
---inventaire, permissions... à chaque appel), tout passe par les exports `Phone*` de `core`
---(plugins/015_Features/server/phone/360_phone_bridge.lua), résolus au moment de l'appel : un
---redémarrage de `core` ne casse donc rien ici.
---
---Chargé seulement quand `framework.name == 'vfw'`.
local vfw = {}

---@type string Nom de la ressource framework.
local RESOURCE <const> = 'core'

---@type table<string, boolean> Exports dont l'échec a déjà été signalé (une seule fois chacun).
local reported = {}

---Appelle un export de `core` sans jamais lever : un `core` en cours de redémarrage ou un export
---manquant donne `nil`, ce que tous les appelants traitent déjà comme « joueur introuvable ».
---Le premier échec de chaque export est écrit dans la console, sinon une faute dans `core`
---ressemblerait à un joueur absent et ne se verrait jamais.
---@param name string
---@param ... any
---@return any
function vfw.call(name, ...)
    local ok, a, b = pcall(function(...) return exports[RESOURCE][name](exports[RESOURCE], ...) end, ...)
    if not ok then
        if not reported[name] and GetResourceState(RESOURCE) == 'started' then
            reported[name] = true
            print(('^1[sd-phone:vfw]^0 core export %s failed: %s'):format(name, tostring(a)))
        end
        return nil
    end
    return a, b
end

---Vrai si `core` est démarré.
---@return boolean
function vfw.ready()
    return GetResourceState(RESOURCE) == 'started'
end

if IsDuplicityVersion() then
    -- -----------------------------------------------------------------------
    -- Serveur
    -- -----------------------------------------------------------------------

    ---Vue légère du joueur (identifier, nom, métier). Nil tant qu'aucun personnage n'est chargé.
    ---@param source number
    ---@return table|nil
    function vfw.player(source) return vfw.call('PhonePlayer', source) end

    ---@param source number
    ---@param key string
    ---@return any
    function vfw.meta(source, key) return vfw.call('PhoneGetMeta', source, key) end

    ---`{ [identifier] = source }` pour tous les personnages en jeu.
    ---@return table<string, number>
    function vfw.onlineMap() return vfw.call('PhoneOnlineMap') or {} end

    ---@param identifier string
    ---@return number|nil
    function vfw.sourceByIdentifier(identifier) return vfw.call('PhoneSourceByIdentifier', identifier) end

    return vfw
end

-- ---------------------------------------------------------------------------
-- Client
-- ---------------------------------------------------------------------------

---Vue légère du personnage local (`{ identifier, job, job2, metadata, dead }`), ou nil avant son
---chargement. Un export dédié de `core` (client/phone.lua) plutôt que `getSharedObject()`, qui
---ferait traverser toute la table VFW à chaque appel.
---@return table|nil
function vfw.playerData()
    local data = vfw.call('PhoneClientPlayer')
    if type(data) ~= 'table' then return nil end
    return data
end

return vfw
