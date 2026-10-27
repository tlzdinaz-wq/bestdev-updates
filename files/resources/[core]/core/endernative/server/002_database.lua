VFW.DB = {}

local function decode(value, fallback)
    if value == nil or value == "" then return fallback end
    if type(value) == "table" then return value end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

VFW.DB.Decode = decode

--- Un drapeau lu en base (colonne TINYINT(1)) est-il levé ?
---
--- oxmysql renvoie ces colonnes en BOOLÉENS (true / false) et les autres entiers en nombres. Le code du
--- serveur, lui, les compare volontiers à 1 : or `true == 1` est faux et `tonumber(true)` vaut nil, de
--- sorte qu'un drapeau levé se lisait comme éteint (véhicule « déjà sorti » de tous les garages, service
--- et état de mort perdus à la connexion...). Vrai ici pour true, 1 et "1" ; faux pour tout le reste.
---@param value any
---@return boolean
function VFW.DB.IsSet(value)
    if value == true then return true end
    return tonumber(value) == 1
end

function VFW.DB.Encode(value)
    return json.encode(value or {})
end

local function humanizeItemName(name)
    return (name:gsub("_", " "):gsub("(%S+)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

local function itemLabel(name, description)
    if type(description) == "string" then
        local dash = description:match("^(.-) %- ")
        if dash and #dash >= 2 and #dash <= 48 and not dash:find("%.") then
            return dash
        end
    end
    return humanizeItemName(name)
end

local function itemInventoryType(name)
    if name:sub(1, 7) == "weapon_" then return "weapons" end
    return "items"
end

local function itemWeight(name, kind)
    if name == "money" or name == "dirty_money" then return 0 end
    local configured = VFW.ItemWeights and VFW.ItemWeights[name]
    if type(configured) == "number" and configured >= 0 then return configured end
    if kind == "weapons" then return 1500 end
    if name:sub(1, 5) == "ammo_" then return 1 end
    return 100
end

local function itemDataJson(name, description)
    local consumable = name == "cigarette" or name == "cigar" or name == "ticket_gratter"
    if type(description) == "string" and description:find("Restaure", 1, true) then
        consumable = true
    end
    if consumable then
        return json.encode({ type = "consumable" })
    end
    return json.encode({ type = "objects" })
end

local CLOTHING_ITEMS = {
    { name = "top", label = "Haut", type = "clothes", image = "items/top.webp", description = "Vetement haut equipable." },
    { name = "bottom", label = "Pantalon", type = "clothes", image = "items/bottom.webp", description = "Pantalon equipable." },
    { name = "shoe", label = "Chaussures", type = "clothes", image = "items/shoe.webp", description = "Chaussures equipables." },
    { name = "hat", label = "Chapeau", type = "clothes", image = "items/hat.webp", description = "Chapeau equipable." },
    { name = "accessory", label = "Accessoire", type = "clothes", image = "items/accessory.webp", description = "Accessoire equipable." },
    { name = "arms", label = "Bras", type = "clothes", image = "items/arms.webp", description = "Bras de tenue equipables." },
    { name = "outfit", label = "Tenue", type = "outfit", image = "items/outfit.webp", description = "Tenue complete equipable." },
}

function VFW.DB.EnsureClothingItems()
    local values, params = {}, {}

    for i = 1, #CLOTHING_ITEMS do
        local item = CLOTHING_ITEMS[i]
        values[#values + 1] = "(?, ?, ?, 0, 0, 0, ?, ?, ?)"
        params[#params + 1] = item.name
        params[#params + 1] = item.label
        params[#params + 1] = item.type
        params[#params + 1] = item.image
        params[#params + 1] = item.description
        params[#params + 1] = json.encode({ type = "objects" })
    end

    MySQL.insert.await(
        "INSERT INTO items (name, label, type, weight, premium, perm, image, description, data) VALUES " .. table.concat(values, ", ") ..
        " ON DUPLICATE KEY UPDATE type = VALUES(type), weight = 0",
        params
    )
end

function VFW.DB.SeedItemsIfEmpty()
    local catalog = VFW.ItemDescriptions
    if type(catalog) ~= "table" then
        console.warn("Items: catalogue introuvable, table `items` laissée vide")
        return
    end

    local values, params = {}, {}
    local inserted = 0

    local function flush()
        if #values == 0 then return end
        MySQL.insert.await(
            "INSERT IGNORE INTO items (name, label, type, weight, premium, perm, image, description, data) VALUES " .. table.concat(values, ", "),
            params
        )
        inserted = inserted + #values
        values, params = {}, {}
    end

    for name, description in pairs(catalog) do
        if type(name) == "string" and name ~= "" then
            local kind = itemInventoryType(name)
            values[#values + 1] = "(?, ?, ?, ?, 0, 0, ?, ?, ?)"
            params[#params + 1] = name
            params[#params + 1] = itemLabel(name, description)
            params[#params + 1] = kind
            params[#params + 1] = itemWeight(name, kind)
            params[#params + 1] = ("items/%s.webp"):format(name)
            params[#params + 1] = type(description) == "string" and description or ""
            params[#params + 1] = itemDataJson(name, description)
            if #values >= 40 then flush() end
        end
    end
    flush()

    -- INSERT IGNORE conserve les réglages SQL existants tout en ajoutant les
    -- nouveaux objets du catalogue aux bases déjà initialisées.
    console.init("Items", ("%d objets vérifiés depuis le catalogue"):format(inserted))
end

--- Drapeau d'un item (colonne facultative de `items`).
---
--- Notre table n'a ni `can_remove`, ni `rare`, ni `usable` : `row.can_remove == 1` était alors faux pour
--- TOUS les items, qui se retrouvaient « non jetables » (« Cet objet ne peut pas être jeté »). Colonne
--- absente = valeur par défaut ; colonne présente = lecture tolérante (true, 1 et "1" sont levés).
---@param value any
---@param default boolean
---@return boolean
local function itemFlag(value, default)
    if value == nil then return default end
    return VFW.DB.IsSet(value)
end

--- Poids : les valeurs de config/item_weights.lua (1 = 5 g) ne s'appliquaient qu'aux items créés à la
--- première amorce de la table. Une base déjà remplie gardait l'ancien poids posé par défaut (un fusil
--- d'assaut à 1500, une bouteille d'eau à 100), tant que sql/items_poids.sql n'était pas importé à la main.
---
--- Fait ici, une seule fois, ce que fait ce script : seuls les items encore à un poids posé par défaut
--- (100, 1 ou 1500) changent, un poids réglé à la main dans Gestion > Items est gardé. La table
--- `items_poids_sauvegarde` garde les poids d'origine ; elle sert aussi de repère « déjà fait » (le script
--- SQL la crée de la même façon). Pour rejouer : la supprimer, puis relancer le serveur.
---@return number changed
function VFW.DB.ApplyConfiguredWeights()
    local configured = VFW.ItemWeights
    if type(configured) ~= "table" then return 0 end

    local marker = MySQL.scalar.await(
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'items_poids_sauvegarde'")
    if (tonumber(marker) or 0) > 0 then return 0 end

    -- Sans sauvegarde, pas de modification : sans repère « déjà fait », les poids réglés à la main
    -- seraient réécrits à chaque démarrage.
    MySQL.query.await("CREATE TABLE `items_poids_sauvegarde` AS SELECT `name`, `weight` FROM `items`")

    local changed = 0
    for name, weight in pairs(configured) do
        if type(name) == "string" and type(weight) == "number" and weight >= 0 then
            local affected = MySQL.update.await(
                "UPDATE `items` SET `weight` = ? WHERE `name` = ? AND `weight` IN (100, 1, 1500) AND `weight` <> ?",
                { weight, name, weight })
            changed = changed + (tonumber(affected) or 0)
        end
    end

    console.init("Items", ("%d poids remis à l'échelle (1 = 5 g), sauvegarde dans items_poids_sauvegarde"):format(changed))
    return changed
end

-- Relecture seule : utilisable pour recuperer un catalogue dont le chargement
-- initial a echoue, sans amorcage ni migration lors d'une ouverture de menu.
function VFW.DB.RefreshItemsCatalog()
    local rows = MySQL.query.await("SELECT * FROM items")
    if type(rows) ~= "table" then error("[items] La lecture SQL du catalogue n'a pas renvoye de liste.") end
    if #rows == 0 and type(VFW.Items) == "table" and next(VFW.Items) ~= nil then
        console.error("[items] Lecture du catalogue vide : conservation du catalogue deja charge.")
        return VFW.Items
    end
    local items = {}
    for i = 1, #rows do
        local row = rows[i]
        local data = decode(row.data, {})
        if type(data) ~= "table" then data = {} end
        if not data.type then data.type = "objects" end

        local image = row.image
        if type(data) == "table" and type(data.image) == "string" and data.image ~= "" then
            image = data.image
        elseif type(image) ~= "string" or image == "" then
            -- Le fichier réellement présent, quelle que soit son extension : un pack
            -- d'icônes en PNG est ainsi pris en compte sans rien changer en base.
            image = (VFW.ItemImageRelPath and VFW.ItemImageRelPath(row.name)) or ("items/%s.webp"):format(row.name)
        end

        items[row.name] = {
            name = row.name,
            label = row.label,
            type = row.type,
            weight = row.weight,
            rare = itemFlag(row.rare, false),
            canRemove = itemFlag(row.can_remove, true),
            usable = itemFlag(row.usable, false),
            premium = VFW.DB.IsSet(row.premium),
            perm = row.perm == 1,
            image = image,
            description = row.description,
            data = data,
        }
    end
    VFW.Items = items
    console.init("Items", ("%d items chargés"):format(#rows))
    return items
end

function VFW.DB.LoadItems()
    -- Une erreur de migration/amorcage ne doit pas cacher les definitions qui
    -- existent deja en base. La lecture reste stricte et ne vide pas un cache sain.
    local ok, err = pcall(VFW.DB.SeedItemsIfEmpty)
    if not ok then console.warn("[items] Amorcage impossible : " .. tostring(err)) end
    ok, err = pcall(VFW.DB.EnsureClothingItems)
    if not ok then console.warn("[items] Migration vetements impossible : " .. tostring(err)) end
    ok, err = pcall(VFW.DB.ApplyConfiguredWeights)
    if not ok then console.warn("[items] Poids non remis a l'echelle : " .. tostring(err)) end
    return VFW.DB.RefreshItemsCatalog()
end

function VFW.DB.LoadJobs()
    local jobRows = MySQL.query.await("SELECT * FROM jobs") or {}
    local gradeRows = MySQL.query.await("SELECT * FROM job_grades ORDER BY `job_name`, `grade`") or {}

    local jobs = {}
    for i = 1, #jobRows do
        local row = jobRows[i]
        jobs[row.name] = {
            name = row.name,
            label = row.label,
            type = row.type,
            whitelisted = VFW.DB.IsSet(row.whitelisted),
            grades = {},
        }
    end

    for i = 1, #gradeRows do
        local row = gradeRows[i]
        local job = jobs[row.job_name]
        if job then
            job.grades[tostring(row.grade)] = {
                grade = row.grade,
                name = row.name,
                label = row.label,
                salary = row.salary,
                isBoss = row.is_boss == 1 or row.is_boss == true or row.is_boss == "1",
                permissions = decode(row.permissions, {}),
            }
        end
    end

    if not jobs.unemployed then
        jobs.unemployed = {
            name = "unemployed",
            label = "Sans emploi",
            type = "job",
            whitelisted = false,
            grades = { ["0"] = { grade = 0, name = "unemployed", label = "Sans emploi", salary = 200, isBoss = false, permissions = {} } },
        }
    end

    VFW.Jobs = jobs
    console.init("Jobs", ("%d métiers chargés"):format(#jobRows))
    return jobs
end

function VFW.DB.BuildJob(name, grade)
    local jobs = type(VFW.Jobs) == "table" and VFW.Jobs or {}
    local job = jobs[name] or jobs.unemployed

    -- BuildJob peut etre appele par un joueur deja connecte pendant que le
    -- callback MySQL.ready recharge encore les metiers. Ne jamais laisser ce
    -- court delai faire planter le chargement du personnage.
    if not job then
        job = {
            name = "unemployed",
            label = "Sans emploi",
            type = "job",
            whitelisted = false,
            grades = {
                ["0"] = {
                    grade = 0,
                    name = "unemployed",
                    label = "Sans emploi",
                    salary = 200,
                    isBoss = false,
                    permissions = {},
                },
            },
        }
    end

    grade = tonumber(grade) or 0

    local grades = type(job.grades) == "table" and job.grades or {}
    local gradeData = grades[tostring(grade)]
    if not gradeData then
        local _, first = next(grades)
        gradeData = first or { grade = 0, name = "unknown", label = "Inconnu", salary = 0, isBoss = false, permissions = {} }
        grade = gradeData.grade
    end

    return {
        name = job.name,
        label = job.label,
        type = job.type,
        grade = grade,
        grade_name = gradeData.name,
        grade_label = gradeData.label,
        grade_salary = gradeData.salary,
        grade_is_boss = gradeData.isBoss,
        permissions = gradeData.permissions or {},
        onDuty = Config.DefaultJobDuty and true or false,
    }
end

function VFW.IsOwnerIdentifier(identifier)
    if type(identifier) ~= "string" or identifier == "" then return false end
    local owners = Config.OwnerIdentifiers
    if type(owners) ~= "table" then return false end
    for i = 1, #owners do
        local owner = owners[i]
        if type(owner) == "string" and owner ~= "" then
            if identifier == owner or identifier:find(owner, 1, true) then
                return true
            end
        end
    end
    return false
end

if not VFW.BuildFullPermissions then
    function VFW.BuildFullPermissions()
        local all = { dev = true, staff = true, admin = true }
        for key in pairs(Config.Permissions or {}) do
            all[key] = true
        end
        return all
    end
end

local function permCount(t)
    local n = 0
    if type(t) == "table" then
        for _ in pairs(t) do n = n + 1 end
    end
    return n
end

function VFW.DB.EnsureNiveau6Account(account)
    if not account then return account end
    local before = permCount(account.permissions)
    if VFW.HydrateNiveau6Permissions then
        VFW.HydrateNiveau6Permissions(account)
    elseif VFW.IsNiveau6Role and VFW.IsNiveau6Role(account.role) then
        account.role = "niveau_6"
        account.permissions = VFW.BuildFullPermissions()
    end
    if account.role == "niveau_6" and account.id and permCount(account.permissions) > before then
        MySQL.update.await(
            "UPDATE users SET role = ?, permissions = ? WHERE id = ?",
            { "niveau_6", json.encode(account.permissions), account.id }
        )
    end
    return account
end

function VFW.DB.ApplyOwnerAccount(account)
    if not account or not VFW.IsOwnerIdentifier(account.identifier) then
        return account
    end

    local all = VFW.BuildFullPermissions()
    account.role = "niveau_6"
    account.permissions = all
    account.vip_tier = math.max(tonumber(account.vip_tier) or 0, 3)

    MySQL.update.await(
        "UPDATE users SET role = ?, permissions = ?, vip_tier = ? WHERE id = ?",
        { "niveau_6", json.encode(all), account.vip_tier, account.id }
    )
    return account
end

local usersIdAutoIncrement = nil

local function playerUuidFromAccountId(accountId)
    local numericId = tonumber(accountId)
    if not numericId or numericId < 1 or numericId % 1 ~= 0 then
        error(("Identifiant de compte invalide pour générer l'UUID : %s"):format(tostring(accountId)))
    end

    return tostring(math.floor(numericId))
end

--- Aligne l'UUID affiche sur l'identifiant du compte.
---
--- Rien ici ne doit refuser une connexion : l'UUID est une commodite d'affichage. Un compte
--- dont l'`id` est inattendu, ou dont la mise a jour echoue (index unique en conflit apres
--- une manipulation en base), entrainait l'echec du chargement et le joueur voyait
--- « Erreur lors du chargement de votre compte » sans que personne ne sache pourquoi.
--- On journalise l'anomalie et on laisse entrer.
local function ensureSequentialPlayerUuid(account)
    if not account then return account end

    local ok, uuid = pcall(playerUuidFromAccountId, account.id)
    if not ok then
        console.warn(("[comptes] UUID non calculable pour le compte %s : %s")
            :format(tostring(account.id), tostring(uuid)))
        return account
    end

    if tostring(account.uuid or "") == uuid then
        return account
    end

    local updated = pcall(MySQL.update.await, "UPDATE users SET uuid = ? WHERE id = ?",
        { uuid, account.id })

    if updated then
        account.uuid = uuid
    else
        console.warn(("[comptes] UUID %s non enregistre pour le compte %s (conflit en base)")
            :format(uuid, tostring(account.id)))
        if account.uuid == nil or account.uuid == "" then account.uuid = uuid end
    end

    return account
end

--- Un identifiant utilisable, ou nil.
---
--- Zero n'est pas un identifiant : c'est ce que rend MySQL quand la colonne n'est
--- pas en auto-increment, ou quand l'insertion n'a rien produit.
---@param value any
---@return number|nil
local function usableId(value)
    local id = tonumber(value)
    if not id or id < 1 or id % 1 ~= 0 then return nil end
    return math.floor(id)
end

--- Attribue un identifiant de compte quand `users.id` n'est pas en auto-increment.
---
--- La table de sequence est creee en AUTO_INCREMENT, mais `CREATE TABLE IF NOT
--- EXISTS` ne corrige pas une table deja presente sans lui. Sur ces bases, l'insertion
--- rendait 0, la relecture rendait 0, et la generation de l'UUID levait une erreur :
--- la connexion etait refusee avec « Identifiant de compte invalide pour generer
--- l'UUID : 0 ». Plus personne ne pouvait creer de compte.
---
--- On attribue donc l'identifiant nous-memes quand la sequence ne le fait pas.
---@param identifier string
---@return string
local function nextLegacyAccountId(identifier)
    local existing = usableId(MySQL.scalar.await(
        "SELECT id FROM player_uuid_sequence WHERE identifier = ? LIMIT 1",
        { identifier }
    ))
    if existing then return playerUuidFromAccountId(existing) end

    local id = usableId(MySQL.insert.await([[
        INSERT INTO player_uuid_sequence (identifier)
        VALUES (?)
        ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id)
    ]], { identifier }))

    if not id then
        id = usableId(MySQL.scalar.await(
            "SELECT id FROM player_uuid_sequence WHERE identifier = ? LIMIT 1",
            { identifier }
        ))
    end

    -- La sequence ne numerote pas : on prend le relais. La ligne a peut-etre ete
    -- creee avec l'identifiant 0, on la remplace par une ligne correctement numerotee.
    if not id then
        console.warn(("[comptes] la table player_uuid_sequence ne numerote pas "
            .. "(colonne `id` sans AUTO_INCREMENT) : attribution manuelle pour %s")
            :format(identifier))

        MySQL.query.await("DELETE FROM player_uuid_sequence WHERE identifier = ? AND id < 1",
            { identifier })

        local nextId = usableId(MySQL.scalar.await(
            "SELECT COALESCE(MAX(id), 0) + 1 FROM player_uuid_sequence"))
        if not nextId then nextId = 1 end

        local ok = pcall(MySQL.insert.await,
            "INSERT INTO player_uuid_sequence (id, identifier) VALUES (?, ?)",
            { nextId, identifier })

        if ok then
            id = nextId
        else
            -- Course entre deux connexions simultanees : la ligne existe desormais.
            id = usableId(MySQL.scalar.await(
                "SELECT id FROM player_uuid_sequence WHERE identifier = ? LIMIT 1",
                { identifier }
            ))
        end
    end

    if not id then
        error("Impossible d'attribuer un identifiant de compte : verifiez que la colonne "
            .. "`id` de `users` est en AUTO_INCREMENT")
    end

    return playerUuidFromAccountId(id)
end

function VFW.DB.EnsureSequentialPlayerUuids()
    local autoIncrementColumn = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'id'
          AND EXTRA LIKE '%auto_increment%'
    ]])
    usersIdAutoIncrement = (tonumber(autoIncrementColumn) or 0) > 0

    if not usersIdAutoIncrement then
        local invalidLegacyId = MySQL.scalar.await([[
            SELECT 1
            FROM users
            WHERE id NOT REGEXP '^[1-9][0-9]*$'
            LIMIT 1
        ]])
        if invalidLegacyId then
            error("Les anciens identifiants de compte ne sont pas numériques : migration UUID automatique impossible")
        end

        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS player_uuid_sequence (
                id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                identifier VARCHAR(64) NOT NULL,
                PRIMARY KEY (id),
                UNIQUE KEY uk_player_uuid_sequence_identifier (identifier)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]])

        -- `CREATE TABLE IF NOT EXISTS` ne corrige pas une table deja presente. Sur une
        -- base ou `player_uuid_sequence` existait sans AUTO_INCREMENT, l'insertion
        -- rendait 0 et plus aucun compte ne pouvait etre cree. On repare la table :
        -- elle nous appartient, personne d'autre ne s'en sert.
        local sequenceNumbers = MySQL.scalar.await([[
            SELECT COUNT(*)
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'player_uuid_sequence'
              AND COLUMN_NAME = 'id'
              AND EXTRA LIKE '%auto_increment%'
        ]])

        if (tonumber(sequenceNumbers) or 0) == 0 then
            console.warn("[comptes] player_uuid_sequence sans AUTO_INCREMENT : reparation")
            MySQL.query.await("DELETE FROM player_uuid_sequence WHERE id < 1")
            pcall(MySQL.query.await,
                "ALTER TABLE player_uuid_sequence MODIFY `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT")
        end

        MySQL.query.await([[
            INSERT IGNORE INTO player_uuid_sequence (id, identifier)
            SELECT CAST(u.id AS UNSIGNED), u.identifier
            FROM users u
            LEFT JOIN player_uuid_sequence sequence_row ON sequence_row.identifier = u.identifier
            WHERE sequence_row.identifier IS NULL
            ORDER BY CAST(u.id AS UNSIGNED)
        ]])

        local invalidSequence = MySQL.scalar.await([[
            SELECT 1
            FROM users u
            LEFT JOIN player_uuid_sequence sequence_row ON sequence_row.identifier = u.identifier
            WHERE sequence_row.id IS NULL
               OR sequence_row.id <> CAST(u.id AS UNSIGNED)
            LIMIT 1
        ]])
        if invalidSequence then
            error("La séquence des identifiants joueurs ne correspond pas aux comptes existants")
        end
    end

    local needsMigration = MySQL.scalar.await([[
        SELECT 1
        FROM users
        WHERE uuid IS NULL OR CAST(uuid AS BINARY) <> CAST(id AS BINARY)
        LIMIT 1
    ]])
    if not needsMigration then return end

    local migrated = MySQL.transaction.await({
        {
            query = "UPDATE users SET uuid = NULL WHERE uuid IS NULL OR CAST(uuid AS BINARY) <> CAST(id AS BINARY)",
            values = {},
        },
        {
            query = "UPDATE users SET uuid = CAST(id AS CHAR) WHERE uuid IS NULL",
            values = {},
        },
    })

    if not migrated then
        error("Impossible de convertir les UUID joueurs en identifiants séquentiels")
    end
end

function VFW.DB.LoadAccount(identifier)
    local row = MySQL.single.await("SELECT * FROM users WHERE identifier = ?", { identifier })
    if row then
        row = ensureSequentialPlayerUuid(row)
        row.permissions = decode(row.permissions, {})
        return VFW.DB.EnsureNiveau6Account(VFW.DB.ApplyOwnerAccount(row))
    end

    local isOwner = VFW.IsOwnerIdentifier(identifier)
    local perms = isOwner and VFW.BuildFullPermissions() or {}
    local role = isOwner and "niveau_6" or "user"
    local vip = isOwner and 3 or 0

    -- Le mode d'identifiant est determine au demarrage. S'il manque (etape de boot qui n'a
    -- pas abouti), on le redemande ici plutot que de refuser le joueur d'emblee.
    if usersIdAutoIncrement == nil then
        pcall(VFW.DB.EnsureSequentialPlayerUuids)
    end

    if usersIdAutoIncrement == nil then
        error("Le mode d'identifiant des comptes n'a pas été initialisé")
    end

    --- Le compte a-t-il ete cree entre-temps ? Deux tentatives de connexion rapprochees, ou
    --- une insertion refusee pour doublon, doivent se terminer par une relecture et non par
    --- un refus definitif.
    local function reread()
        local row = MySQL.single.await("SELECT * FROM users WHERE identifier = ?", { identifier })
        if not row then return nil end
        row.permissions = decode(row.permissions, {})
        return ensureSequentialPlayerUuid(row)
    end

    local id, uuid
    if usersIdAutoIncrement then
        local okInsert, inserted = pcall(MySQL.insert.await,
            "INSERT INTO users (identifier, slots, role, permissions, vip_tier) VALUES (?, ?, ?, ?, ?)",
            { identifier, Config.Multicharacter.Slots, role, json.encode(perms), vip }
        )

        if not okInsert then
            console.warn(("[comptes] creation refusee pour %s : %s"):format(identifier, tostring(inserted)))
            local existing = reread()
            if existing then return VFW.DB.EnsureNiveau6Account(VFW.DB.ApplyOwnerAccount(existing)) end
            error(inserted)
        end

        id = inserted
        -- Certaines versions d'oxmysql renvoient 0 au lieu de l'identifiant insere.
        if not id or tonumber(id) == 0 then
            id = MySQL.scalar.await("SELECT id FROM users WHERE identifier = ? LIMIT 1", { identifier })
        end

        local okUuid, computed = pcall(playerUuidFromAccountId, id)
        if okUuid then
            uuid = computed
            pcall(MySQL.update.await, "UPDATE users SET uuid = ? WHERE id = ?", { uuid, id })
        else
            console.warn(("[comptes] UUID non calculable a la creation de %s : %s")
                :format(identifier, tostring(computed)))
            uuid = tostring(id or "")
        end
    else
        id = nextLegacyAccountId(identifier)
        uuid = id

        local okInsert, err = pcall(MySQL.insert.await,
            "INSERT INTO users (id, identifier, uuid, slots, role, permissions, vip_tier) VALUES (?, ?, ?, ?, ?, ?, ?)",
            { id, identifier, uuid, Config.Multicharacter.Slots, role, json.encode(perms), vip }
        )

        if not okInsert then
            console.warn(("[comptes] creation refusee pour %s : %s"):format(identifier, tostring(err)))
            local existing = reread()
            if existing then return VFW.DB.EnsureNiveau6Account(VFW.DB.ApplyOwnerAccount(existing)) end
            error(err)
        end
    end

    return VFW.DB.EnsureNiveau6Account(VFW.DB.ApplyOwnerAccount({
        id = id,
        identifier = identifier,
        uuid = uuid,
        permissions = perms,
        role = role,
        role_id = 0,
        level = 0,
        vip_tier = vip,
        spacecoins = 0,
        slots = Config.Multicharacter.Slots,
        playtime = 0,
        banned = 0,
    }))
end

function VFW.DB.LoadCharacters(accountId)
    local rows = MySQL.query.await(
        "SELECT * FROM characters WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot ASC",
        { accountId }
    ) or {}

    for i = 1, #rows do
        local row = rows[i]
        row.skin = decode(row.skin, {})
        row.coords = decode(row.coords, Config.DefaultSpawns[1])
        row.accounts = decode(row.accounts, {})
        row.inventory = decode(row.inventory, {})
        row.loadout = decode(row.loadout, {})
        row.licenses = decode(row.licenses, {})
        row.metadata = decode(row.metadata, {})
        row.tattoos = decode(row.tattoos, {})
    end

    return rows
end

function VFW.DB.LoadCharacter(identifier)
    local row = MySQL.single.await("SELECT * FROM characters WHERE identifier = ? AND deleted_at IS NULL", { identifier })
    if not row then return nil end

    row.skin = decode(row.skin, {})
    row.coords = decode(row.coords, Config.DefaultSpawns[1])
    row.accounts = decode(row.accounts, {})
    row.inventory = decode(row.inventory, {})
    row.loadout = decode(row.loadout, {})
    row.licenses = decode(row.licenses, {})
    row.metadata = decode(row.metadata, {})
    row.tattoos = decode(row.tattoos, {})
    return row
end

function VFW.DB.CreateCharacter(accountId, slot, identifier, data)
    local accounts = {}
    for name, cfg in pairs(Config.Accounts) do
        accounts[#accounts + 1] = {
            name = name,
            money = Config.StartingAccountMoney[name] or 0,
            label = cfg.label,
            round = cfg.round,
        }
    end
    if not Config.Accounts.money then
        table.insert(accounts, 1, { name = "money", money = Config.StartingAccountMoney.money or 0, label = "Espèces", round = true })
    end

    local spawn = Config.DefaultSpawns[1]
    local coords = { x = spawn.x, y = spawn.y, z = spawn.z, heading = spawn.heading or 0.0 }

    local inventory = {}
    if Config.StartingInventoryItems then
        for name, count in pairs(Config.StartingInventoryItems) do
            inventory[#inventory + 1] = { name = name, count = count }
        end
    end

    -- Starter pack configuré en jeu (Gestion > Développeurs) : prime sur la config
    local starter = VFW.GetStarterPack and VFW.GetStarterPack() or nil
    if starter then
        for _, account in ipairs(accounts) do
            if account.name == "bank" and tonumber(starter.bank) then account.money = math.floor(tonumber(starter.bank)) end
            if account.name == "money" and tonumber(starter.cash) then account.money = math.floor(tonumber(starter.cash)) end
        end
        -- une liste d'items réglée par le staff prime, même vide (« tout supprimer » ne remet pas les items par défaut)
        if type(starter.items) == "table" and (#starter.items > 0 or starter.itemsConfigured == true) then
            inventory = {}
            for _, it in ipairs(starter.items) do
                if type(it.name) == "string" and (tonumber(it.count) or 0) > 0 then
                    inventory[#inventory + 1] = { name = it.name, count = math.floor(tonumber(it.count)) }
                end
            end
        end
    end

    local id = MySQL.insert.await([[
        INSERT INTO characters
            (identifier, account_id, char_slot, firstname, lastname, dateofbirth, sex, birthplace,
             height, skin, tattoos, mugshot, coords, accounts, inventory, loadout, licenses, metadata, max_weight)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        identifier, accountId, slot,
        data.firstname or "", data.lastname or "", data.dateofbirth or "",
        data.sex or "m", data.birthplace or "", tonumber(data.height) or 175,
        VFW.DB.Encode(data.skin), VFW.DB.Encode(data.tattoos), data.mugshot or "",
        VFW.DB.Encode(coords), VFW.DB.Encode(accounts), VFW.DB.Encode(inventory),
        VFW.DB.Encode({}), VFW.DB.Encode({}),
        VFW.DB.Encode({ health = 200, armor = 0, hunger = 100, thirst = 100 }),
        Config.MaxWeight,
    })

    if data.tattoos then
        for i = 1, #data.tattoos do
            local t = data.tattoos[i]
            MySQL.insert.await(
                "INSERT INTO character_tattoos (identifier, collection, hash, zone) VALUES (?, ?, ?, ?)",
                { identifier, t.Collection or "", t.Hash or t.HashName or "", t.zone or "" }
            )
        end
    end

    return id
end

function VFW.DB.SaveCharacter(xPlayer)
    if not xPlayer or not xPlayer.identifier then return end

    MySQL.update([[
        UPDATE characters SET
            firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, birthplace = ?, height = ?,
            skin = ?, tattoos = ?, mugshot = ?, coords = ?,
            job = ?, job_grade = ?, job_duty = ?, job2 = ?, job2_grade = ?, faction = ?, `group` = ?,
            accounts = ?, inventory = ?, loadout = ?, licenses = ?, metadata = ?,
            address = ?, max_weight = ?, is_dead = ?
        WHERE identifier = ?
    ]], {
        xPlayer.firstName, xPlayer.lastName, xPlayer.dateofbirth, xPlayer.sex, xPlayer.birthplace, xPlayer.height,
        VFW.DB.Encode(xPlayer.skin), VFW.DB.Encode(xPlayer.tattoos), xPlayer.mugshot or "",
        VFW.DB.Encode(xPlayer.getCoords(true)),
        xPlayer.job.name, xPlayer.job.grade, xPlayer.job.onDuty and 1 or 0,
        xPlayer.job2 and xPlayer.job2.name or "", xPlayer.job2 and xPlayer.job2.grade or 0,
        xPlayer.faction or "", xPlayer.group or "user",
        VFW.DB.Encode(xPlayer.accounts), VFW.DB.Encode(xPlayer.inventory),
        VFW.DB.Encode(xPlayer.loadout), VFW.DB.Encode(xPlayer.licenses),
        VFW.DB.Encode(xPlayer.metadata),
        xPlayer.address or "", xPlayer.maxWeight or Config.MaxWeight,
        xPlayer.dead and 1 or 0,
        xPlayer.identifier,
    })
end

function VFW.DB.SaveAll()
    for _, xPlayer in pairs(VFW.Players) do
        VFW.DB.SaveCharacter(xPlayer)
    end
end

-- Démarrage de la base de données.
--
-- Ces étapes s'enchaînaient sans protection : la moindre erreur de l'une d'elles (table
-- absente, colonne manquante, requête refusée) interrompait la suite, `VFW.Ready` n'était
-- jamais posé, et TOUS les joueurs étaient alors refusés au bout de 30 secondes avec
-- « Le serveur n'a pas fini de démarrer » — sans rien dans la console pour dire laquelle
-- avait lâché.
--
-- Chaque étape est désormais isolée et nommée : une étape qui échoue est signalée en clair,
-- les autres se poursuivent, et le serveur devient utilisable au lieu de rester fermé.
local function bootStep(label, fn)
    local ok, err = pcall(fn)
    if ok then return true end

    console.error(("[Démarrage] étape « %s » en échec : %s"):format(label, tostring(err)))
    return false
end

MySQL.ready(function()
    -- Permet de distinguer « la base n'a jamais répondu » d'une étape de démarrage ratée
    -- quand un joueur se fait refuser la connexion.
    VFW.DbCallbackFired = true

    local failed = {}

    local steps = {
        { "UUID des comptes", VFW.DB.EnsureSequentialPlayerUuids },
        { "chargement des métiers", VFW.DB.LoadJobs },
        { "chargement des items", VFW.DB.LoadItems },
        { "permissions des propriétaires", function()
            local all = VFW.BuildFullPermissions()
            local encoded = json.encode(all)

            for i = 1, #(Config.OwnerIdentifiers or {}) do
                local owner = Config.OwnerIdentifiers[i]
                if type(owner) == "string" and owner ~= "" then
                    MySQL.update.await(
                        "UPDATE users SET role = ?, permissions = ?, vip_tier = GREATEST(IFNULL(vip_tier, 0), 3) WHERE identifier = ? OR identifier LIKE ?",
                        { "niveau_6", encoded, owner, "%" .. owner .. "%" }
                    )
                end
            end
        end },
    }

    for i = 1, #steps do
        if not bootStep(steps[i][1], steps[i][2]) then
            failed[#failed + 1] = steps[i][1]
        end
    end

    VFW.Ready = true

    if #failed > 0 then
        console.error(("[Démarrage] serveur ouvert malgré %d étape(s) en échec : %s"):format(
            #failed, table.concat(failed, ", ")))
        console.error("[Démarrage] vérifiez la base de données (tables manquantes ou schéma incomplet).")
    end

    console.init("Core", "Base de données prête")
end)

CreateThread(function()
    while true do
        Wait(5 * 60000)
        VFW.DB.SaveAll()
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    VFW.DB.SaveAll()
end)
