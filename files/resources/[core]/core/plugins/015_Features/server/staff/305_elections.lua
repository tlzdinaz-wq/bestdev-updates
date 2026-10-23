-- Votes et scrutins : tout le cote serveur.
--
-- Le menu staff (client/staff/menu/builderElections.lua) appelle douze points d'entree.
-- Aucun n'existait, et aucune table non plus : cliquer sur « Creer un vote » ou
-- « Gerer les votes » ouvrait un sous-menu qui interrogeait le vide. Les callbacks
-- attendaient leur delai d'expiration puis rendaient nil, les evenements partaient
-- sans destinataire — d'ou l'impression que rien ne se passe.
--
-- Quatre tables : le scrutin, ses propositions, ses points de vote dans le monde, et
-- les bulletins. Elles sont creees au demarrage si elles manquent, comme ailleurs
-- dans la base.

local PERMISSION <const> = "builder_elections"
local MAX_PROPOSALS <const> = 12
local MAX_POINTS <const> = 20

local ready = false

local function ensureTables()
    if ready then return end

    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS elections (
            id             INT(11)      NOT NULL AUTO_INCREMENT,
            name           VARCHAR(120) NOT NULL,
            description    TEXT         DEFAULT NULL,
            active         TINYINT(1)   NOT NULL DEFAULT 1,
            duration_hours INT(11)      NOT NULL DEFAULT 24,
            created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            ends_at        DATETIME     DEFAULT NULL,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS election_proposals (
            id          INT(11)      NOT NULL AUTO_INCREMENT,
            election_id INT(11)      NOT NULL,
            label       VARCHAR(160) NOT NULL,
            PRIMARY KEY (id),
            KEY idx_election_proposals_election (election_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS election_points (
            id          INT(11) NOT NULL AUTO_INCREMENT,
            election_id INT(11) NOT NULL,
            x           DOUBLE  NOT NULL DEFAULT 0,
            y           DOUBLE  NOT NULL DEFAULT 0,
            z           DOUBLE  NOT NULL DEFAULT 0,
            PRIMARY KEY (id),
            KEY idx_election_points_election (election_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- L'unicite sur (scrutin, personnage) est ce qui empeche de voter deux fois :
    -- un controle en Lua se contourne par deux clics simultanes, pas une cle unique.
    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS election_votes (
            id           INT(11)     NOT NULL AUTO_INCREMENT,
            election_id  INT(11)     NOT NULL,
            proposal_id  INT(11)     NOT NULL,
            character_id VARCHAR(64) NOT NULL,
            created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uk_election_votes_one (election_id, character_id),
            KEY idx_election_votes_proposal (proposal_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    ready = true
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end

    ensureTables()
end)

---@param source number
---@return table|nil
local function staff(source)
    ensureTables()

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if xPlayer.hasPermission(PERMISSION)
        or xPlayer.hasPermission("gestion")
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end

    Staff29.Notify(source, "ERROR", "Votes", "Vous n'avez pas la permission requise.")
    return nil
end

--- Identifie le votant. Le personnage, pas le compte : deux personnages d'un meme
--- joueur votent separement, comme deux habitants.
---@param xPlayer table
---@return string|nil
local function voterOf(xPlayer)
    local id = xPlayer and (xPlayer.charId or xPlayer.identifier)
    return id and tostring(id) or nil
end

---@param row table
---@return number
local function remainingSeconds(row)
    if not row.ends_at then return 0 end

    local left = Staff29.Scalar("SELECT TIMESTAMPDIFF(SECOND, NOW(), ?)", { row.ends_at }, 0)
    local value = tonumber(left) or 0
    return value > 0 and math.floor(value) or 0
end

---@param electionId number
---@return table
local function proposalsOf(electionId)
    return Staff29.Query(
        "SELECT id, label FROM election_proposals WHERE election_id = ? ORDER BY id ASC", { electionId }) or {}
end

---@param electionId number
---@return table
local function pointsOf(electionId)
    local rows = Staff29.Query(
        "SELECT id, x, y, z FROM election_points WHERE election_id = ? ORDER BY id ASC", { electionId }) or {}

    local out = {}
    for i = 1, #rows do
        out[i] = {
            id = rows[i].id,
            electionId = electionId,
            x = tonumber(rows[i].x) or 0.0,
            y = tonumber(rows[i].y) or 0.0,
            z = tonumber(rows[i].z) or 0.0,
        }
    end

    return out
end

---@param electionId number
---@return number
local function totalVotesOf(electionId)
    return tonumber(Staff29.Scalar(
        "SELECT COUNT(*) FROM election_votes WHERE election_id = ?", { electionId }, 0)) or 0
end

---@param row table
---@return table
local function buildElection(row)
    return {
        id = row.id,
        name = row.name,
        description = row.description or "",
        active = (row.active == 1 or row.active == true) and 1 or 0,
        duration_hours = tonumber(row.duration_hours) or 24,
        ends_at = row.ends_at,
        remainingSeconds = remainingSeconds(row),
        totalVotes = totalVotesOf(row.id),
        proposals = proposalsOf(row.id),
        points = pointsOf(row.id),
    }
end

--- Un scrutin dont le terme est passe se ferme tout seul.
---
--- Sans ça, un vote reste ouvert indefiniment si personne ne pense a le fermer a la
--- main, et la duree choisie a la creation ne veut plus rien dire.
local function closeExpired()
    Staff29.Update([[
        UPDATE elections SET active = 0
        WHERE active = 1 AND ends_at IS NOT NULL AND ends_at <= NOW()
    ]])
end

-- ═══════════════════════════════════════════════════════════════
-- Lectures
-- ═══════════════════════════════════════════════════════════════

Staff29.Cb("elections:getAll", function(source)
    if not staff(source) then return {} end
    closeExpired()

    local rows = Staff29.Query("SELECT * FROM elections ORDER BY id DESC") or {}
    local out = {}
    for i = 1, #rows do out[i] = buildElection(rows[i]) end

    return out
end)

Staff29.Cb("elections:getOne", function(source, electionId)
    if not staff(source) then return nil end

    local id = Staff29.ToInt(electionId, 1)
    if not id then return nil end

    local row = Staff29.Single("SELECT * FROM elections WHERE id = ?", { id })
    return row and buildElection(row) or nil
end)

--- Les scrutins ouverts, pour les points de vote dans le monde.
---
--- Accessible a tout le monde : c'est ce qui fait apparaitre les urnes aux joueurs.
Staff29.Cb("elections:getActive", function(source)
    ensureTables()
    closeExpired()

    local rows = Staff29.Query("SELECT * FROM elections WHERE active = 1 ORDER BY id DESC") or {}
    local out = {}
    for i = 1, #rows do out[i] = buildElection(rows[i]) end

    return out
end)

Staff29.Cb("elections:getResults", function(source, electionId)
    ensureTables()

    local id = Staff29.ToInt(electionId, 1)
    if not id then return nil end

    local rows = Staff29.Query([[
        SELECT p.id, p.label, COUNT(v.id) AS vote_count
        FROM election_proposals p
        LEFT JOIN election_votes v ON v.proposal_id = p.id
        WHERE p.election_id = ?
        GROUP BY p.id, p.label
        ORDER BY p.id ASC
    ]], { id }) or {}

    local proposals = {}
    for i = 1, #rows do
        proposals[i] = {
            id = rows[i].id,
            label = rows[i].label,
            vote_count = tonumber(rows[i].vote_count) or 0,
        }
    end

    return { totalVotes = totalVotesOf(id), proposals = proposals }
end)

Staff29.Cb("elections:hasVoted", function(source, electionId)
    ensureTables()

    local xPlayer = VFW.GetPlayerFromId(source)
    local voter = voterOf(xPlayer)
    local id = Staff29.ToInt(electionId, 1)
    if not voter or not id then return { voted = false } end

    local row = Staff29.Single([[
        SELECT v.proposal_id, p.label
        FROM election_votes v
        LEFT JOIN election_proposals p ON p.id = v.proposal_id
        WHERE v.election_id = ? AND v.character_id = ?
    ]], { id, voter })

    if not row then return { voted = false } end

    return { voted = true, proposalId = row.proposal_id, proposalLabel = row.label or "" }
end)

-- ═══════════════════════════════════════════════════════════════
-- Le vote
-- ═══════════════════════════════════════════════════════════════

Staff29.Cb("elections:vote", function(source, electionId, proposalId)
    ensureTables()
    closeExpired()

    local xPlayer = VFW.GetPlayerFromId(source)
    local voter = voterOf(xPlayer)
    local id = Staff29.ToInt(electionId, 1)
    local choice = Staff29.ToInt(proposalId, 1)

    if not voter or not id or not choice then
        return { success = false, reason = "Ce vote n'est pas valide." }
    end

    if not Staff29.RateLimit(source, "elections:vote", 1000) then
        return { success = false, reason = "Patientez un instant." }
    end

    local election = Staff29.Single("SELECT active FROM elections WHERE id = ?", { id })
    if not election then return { success = false, reason = "Ce scrutin n'existe plus." } end
    if not (election.active == 1 or election.active == true) then
        return { success = false, reason = "Ce scrutin est termine." }
    end

    -- La proposition doit appartenir a ce scrutin : sinon on voterait pour le bulletin
    -- d'un autre en changeant un nombre.
    local belongs = Staff29.Scalar(
        "SELECT COUNT(*) FROM election_proposals WHERE id = ? AND election_id = ?", { choice, id }, 0)
    if (tonumber(belongs) or 0) == 0 then
        return { success = false, reason = "Cette proposition n'existe pas." }
    end

    local ok = pcall(Staff29.Insert,
        "INSERT INTO election_votes (election_id, proposal_id, character_id) VALUES (?, ?, ?)",
        { id, choice, voter })

    if not ok then
        -- La cle unique a parle : ce personnage avait deja vote.
        return { success = false, reason = "Vous avez deja vote pour ce scrutin." }
    end

    return { success = true }
end)

-- ═══════════════════════════════════════════════════════════════
-- Gestion
-- ═══════════════════════════════════════════════════════════════

Staff29.Cb("elections:create", function(source, payload)
    local xPlayer = staff(source)
    if not xPlayer then return { success = false, reason = "Permission refusee." } end

    local data = Staff29.IsTable(payload)
    if not data then return { success = false, reason = "Donnees invalides." } end

    local name = Staff29.Clean(data.name, 120)
    local description = Staff29.Clean(data.description, 1000) or ""
    local proposals = Staff29.IsTable(data.proposals) or {}
    local points = Staff29.IsTable(data.points) or {}
    local hours = Staff29.ToInt(data.durationHours, 1, 8760) or 24

    if not name then return { success = false, reason = "Le nom est obligatoire." } end
    if #proposals < 2 then return { success = false, reason = "Il faut au moins deux propositions." } end
    if #points < 1 then return { success = false, reason = "Il faut au moins un point de vote." } end
    if #proposals > MAX_PROPOSALS then return { success = false, reason = "Trop de propositions." } end
    if #points > MAX_POINTS then return { success = false, reason = "Trop de points de vote." } end

    local electionId = Staff29.Insert([[
        INSERT INTO elections (name, description, active, duration_hours, ends_at)
        VALUES (?, ?, 1, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))
    ]], { name, description, hours, hours })

    if not electionId then return { success = false, reason = "Enregistrement refuse." } end

    for i = 1, #proposals do
        local entry = proposals[i]
        local label = Staff29.Clean(type(entry) == "table" and entry.label or entry, 160)
        if label then
            Staff29.Insert("INSERT INTO election_proposals (election_id, label) VALUES (?, ?)",
                { electionId, label })
        end
    end

    for i = 1, #points do
        local point = Staff29.Vec(points[i])
        if point then
            Staff29.Insert("INSERT INTO election_points (election_id, x, y, z) VALUES (?, ?, ?, ?)",
                { electionId, point.x, point.y, point.z })
        end
    end

    TriggerClientEvent("elections:refresh", -1)
    return { success = true, id = electionId }
end)

Staff29.Cb("elections:delete", function(source, electionId)
    if not staff(source) then return false end

    local id = Staff29.ToInt(electionId, 1)
    if not id then return false end

    Staff29.Update("DELETE FROM election_votes WHERE election_id = ?", { id })
    Staff29.Update("DELETE FROM election_proposals WHERE election_id = ?", { id })
    Staff29.Update("DELETE FROM election_points WHERE election_id = ?", { id })
    Staff29.Update("DELETE FROM elections WHERE id = ?", { id })

    TriggerClientEvent("elections:refresh", -1)
    return true
end)

RegisterNetEvent("elections:endNow", function(electionId)
    local source = source
    if not staff(source) then return end

    local id = Staff29.ToInt(electionId, 1)
    if not id then return end

    Staff29.Update("UPDATE elections SET active = 0, ends_at = NOW() WHERE id = ?", { id })
    TriggerClientEvent("elections:refresh", -1)
end)

RegisterNetEvent("elections:toggleActive", function(electionId, active)
    local source = source
    if not staff(source) then return end

    local id = Staff29.ToInt(electionId, 1)
    if not id then return end

    local wanted = (active == true or active == 1) and 1 or 0

    -- Rouvrir un scrutin dont le terme est passe le refermerait aussitot : on lui rend
    -- sa duree a partir de maintenant.
    if wanted == 1 then
        Staff29.Update([[
            UPDATE elections
            SET active = 1,
                ends_at = CASE
                    WHEN ends_at IS NULL OR ends_at <= NOW()
                    THEN DATE_ADD(NOW(), INTERVAL duration_hours HOUR)
                    ELSE ends_at
                END
            WHERE id = ?
        ]], { id })
    else
        Staff29.Update("UPDATE elections SET active = 0 WHERE id = ?", { id })
    end

    TriggerClientEvent("elections:refresh", -1)
end)

RegisterNetEvent("elections:addPoint", function(electionId, coords)
    local source = source
    if not staff(source) then return end

    local id = Staff29.ToInt(electionId, 1)
    local point = Staff29.Vec(coords)
    if not id or not point then return end

    local count = tonumber(Staff29.Scalar(
        "SELECT COUNT(*) FROM election_points WHERE election_id = ?", { id }, 0)) or 0
    if count >= MAX_POINTS then
        Staff29.Notify(source, "ERROR", "Votes", "Ce scrutin a deja le maximum de points de vote.")
        return
    end

    Staff29.Insert("INSERT INTO election_points (election_id, x, y, z) VALUES (?, ?, ?, ?)",
        { id, point.x, point.y, point.z })

    TriggerClientEvent("elections:refresh", -1)
end)

RegisterNetEvent("elections:removePoint", function(pointId)
    local source = source
    if not staff(source) then return end

    local id = Staff29.ToInt(pointId, 1)
    if not id then return end

    Staff29.Update("DELETE FROM election_points WHERE id = ?", { id })
    TriggerClientEvent("elections:refresh", -1)
end)
