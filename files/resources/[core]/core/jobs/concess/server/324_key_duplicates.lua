VFW.Concess = VFW.Concess or {}

local Concess = VFW.Concess

-- Doubles de clés (clés permanentes du staff, doubles remis par un concessionnaire).
--
-- La table vient du SQL d'installation avec 4 colonnes (id, plate, identifier, created_at), alors que le code écrit aussi
-- qui a remis la clé (granted_by) et le concessionnaire (concess_id) : chaque remise échouait (« Les clés n'ont pas pu être
-- remises »), et le double du concessionnaire annonçait pourtant un succès. On complète la table au démarrage.

local COLUMNS = {
    { name = "granted_by", definition = "VARCHAR(64) DEFAULT NULL" },
    { name = "concess_id", definition = "INT(11) DEFAULT NULL" },
}

local function ensureSchema()
    pcall(MySQL.query.await, [[
        CREATE TABLE IF NOT EXISTS `concess_key_duplicates` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `plate` VARCHAR(12) NOT NULL,
            `identifier` VARCHAR(64) NOT NULL,
            `granted_by` VARCHAR(64) DEFAULT NULL,
            `concess_id` INT(11) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `plate` (`plate`)
        )
    ]])

    for i = 1, #COLUMNS do
        local column = COLUMNS[i]
        local ok, found = pcall(MySQL.scalar.await, [[
            SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'concess_key_duplicates' AND COLUMN_NAME = ?
        ]], { column.name })

        if ok and (tonumber(found) or 0) == 0 then
            local altered, err = pcall(MySQL.query.await,
                ("ALTER TABLE `concess_key_duplicates` ADD COLUMN `%s` %s"):format(column.name, column.definition))
            if not altered then
                console.error(("[clés] colonne %s impossible à ajouter : %s"):format(column.name, tostring(err)))
            end
        end
    end
end

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    local ok, err = pcall(ensureSchema)
    if not ok then console.error("[clés] préparation de la table des doubles de clés : " .. tostring(err)) end
end)

--- Remet un double de clés à `identifier` pour `plate`. Vrai quand la clé existe ensuite (posée maintenant ou déjà là),
--- faux si la base refuse. Pas de doublon : une même plaque et un même joueur ne donnent qu'une ligne.
---@param plate string
---@param identifier string
---@param grantedBy string|nil  qui remet la clé
---@param concessId number|nil  concessionnaire à l'origine du double (aucun pour une clé du staff)
---@return boolean
function Concess.GrantKeyDuplicate(plate, identifier, grantedBy, concessId)
    if type(plate) ~= "string" or plate == "" then return false end
    if type(identifier) ~= "string" or identifier == "" then return false end

    local readable, existing = pcall(MySQL.scalar.await,
        "SELECT id FROM concess_key_duplicates WHERE plate = ? AND identifier = ? LIMIT 1", { plate, identifier })
    if not readable then return false end
    if existing then return true end

    local by = tostring(grantedBy or "")
    local written
    if tonumber(concessId) then
        written = pcall(MySQL.insert.await, [[
            INSERT INTO concess_key_duplicates (plate, identifier, granted_by, concess_id) VALUES (?, ?, ?, ?)
        ]], { plate, identifier, by, tonumber(concessId) })
    else
        written = pcall(MySQL.insert.await, [[
            INSERT INTO concess_key_duplicates (plate, identifier, granted_by, concess_id) VALUES (?, ?, ?, NULL)
        ]], { plate, identifier, by })
    end
    if written then return true end

    -- colonnes complémentaires indisponibles (ALTER refusé) : la clé ne demande de toute façon que la plaque et le joueur
    return pcall(MySQL.insert.await,
        "INSERT INTO concess_key_duplicates (plate, identifier) VALUES (?, ?)", { plate, identifier }) == true
end
