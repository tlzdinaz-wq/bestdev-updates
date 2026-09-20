local RANK_NAMES = { "chef", "souschef", "soldat", "membre", "recrue" }
local RANK_LABELS = { "Chef", "Sous-chef", "Soldat", "Membre", "Recrue" }

local DEFAULT_CREW_PERMS = {
    chef = { recruit = true, promote = true, demote = true, kick = true, manage_permissions = true,
             manage_crew = true, orders = true, manage_property = true, manage_garage = true },
    souschef = { recruit = true, promote = true, demote = true, kick = true, manage_permissions = false,
                 manage_crew = true, orders = true, manage_property = true, manage_garage = true },
    soldat = { recruit = false, promote = false, demote = false, kick = false, manage_permissions = false,
               manage_crew = false, orders = true, manage_property = false, manage_garage = true },
    membre = { recruit = false, promote = false, demote = false, kick = false, manage_permissions = false,
               manage_crew = false, orders = false, manage_property = false, manage_garage = false },
    recrue = { recruit = false, promote = false, demote = false, kick = false, manage_permissions = false,
               manage_crew = false, orders = false, manage_property = false, manage_garage = false },
}

local GRADE_PERMS = {
    "canAccessTablet", "canRecruit", "canKick", "canPromote",
    "canDemote", "canManageChest", "canManageGrades",
}

local POS_KEYS = {
    posLaboratory = true,
    posCraft = true,
    posStockage = true,
    posGarage = true,
}

local FIELD_KEYS = {
    label = true,
    devise = true,
    image = true,
    banner = true,
    color = true,
}

local hubReady = false

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("gestion_faction")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

local function gradeDefaults(isBoss)
    local out = {}
    for i = 1, #GRADE_PERMS do
        out[GRADE_PERMS[i]] = isBoss and true or false
    end
    out.canAccessTablet = true
    return out
end

local function slugName(raw)
    if type(raw) ~= "string" then return nil end
    local out = raw:lower():gsub("%s+", "_"):gsub("[^%w_]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
    out = out:sub(1, 40)
    if out == "" or out == "nocrew" or out == "nofaction" then return nil end
    return out
end

local function hexColor(raw, fallback)
    if type(raw) ~= "string" then return fallback end
    local hex = raw:match("^#?(%x%x%x%x%x%x)$")
    if not hex then return fallback end
    return "#" .. hex:upper()
end

local function isFivemanageUrl(url)
    if type(url) ~= "string" or url == "" then return false end
    local host = url:match("^https?://([^/%?]+)")
    if not host then return false end
    host = host:lower()
    return host:find("fivemanage%.com", 1, false) ~= nil or host:find("fmfile%.com", 1, false) ~= nil
end

local function cleanUrl(raw)
    if raw == nil then return "" end
    if type(raw) ~= "string" then return "" end
    local out = Staff29.Clean(raw:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^[\"']", ""):gsub("[\"']$", ""), 512) or ""
    if out == "" then return "" end
    if out:find("[%z\n\r]") then return "" end
    if out:match("^r2%.fivemanage%.com/") or out:match("^[%w%-]+%.fivemanage%.com/") or out:match("^[%w%-]+%.fmfile%.com/") then
        out = "https://" .. out
    end
    if not out:match("^https?://") then return "" end
    return out
end

local mediaCache = { at = 0, items = {} }

local function fivemanageKey()
    local keys = {
        GetConvar("FIVEMANAGE_MEDIA_API_KEY", ""),
        GetConvar("fivemanage:key", ""),
        GetConvar("core_fivemanage_media_key", ""),
    }
    for i = 1, #keys do
        if type(keys[i]) == "string" and keys[i] ~= "" then return keys[i] end
    end
    return nil
end

local function parseFivemanageList(body)
    local ok, decoded = pcall(json.decode, body or "")
    if not ok or type(decoded) ~= "table" then return {} end
    local source = decoded.data or decoded.files or decoded.items or decoded
    if type(source) == "table" and source.files then source = source.files end
    if type(source) ~= "table" then return {} end
    local out = {}
    for i = 1, #source do
        local row = source[i]
        if type(row) == "table" then
            local url = row.url or row.originalUrl or row.original_url
            if type(url) == "string" and url:match("^https?://") then
                out[#out + 1] = {
                    id = row.id or url,
                    name = row.filename or row.name or row.id or "Image",
                    url = url,
                }
            end
        elseif type(row) == "string" and row:match("^https?://") then
            out[#out + 1] = { id = row, name = "Image", url = row }
        end
    end
    return out
end

local function fetchFivemanageImages()
    local key = fivemanageKey()
    if not key then return {} end
    local now = GetGameTimer()
    if mediaCache.at > 0 and (now - mediaCache.at) < 30000 then
        return mediaCache.items
    end

    local path = GetConvar("core_fivemanage_path", "")
    local url = "https://api.fivemanage.com/api/v3/file?type=image&limit=100"
    if type(path) == "string" and path ~= "" then
        url = url .. "&path=" .. path
    end

    local p = promise.new()
    local done = false
    PerformHttpRequest(url, function(status, body)
        if done then return end
        done = true
        if status == 200 then
            p:resolve(parseFivemanageList(body))
        else
            p:resolve({})
        end
    end, "GET", "", {
        Authorization = key,
        Accept = "application/json",
    })
    SetTimeout(4000, function()
        if done then return end
        done = true
        p:resolve({})
    end)

    local items = Citizen.Await(p) or {}
    mediaCache.at = GetGameTimer()
    mediaCache.items = items
    return items
end

local function mediaLibrary()
    local seen, out = {}, {}
    local function push(id, name, url)
        if type(url) ~= "string" or url == "" or seen[url] then return end
        seen[url] = true
        out[#out + 1] = { id = id or url, name = name or "Image", url = url }
    end

    local fm = fetchFivemanageImages()
    for i = 1, #fm do
        push(fm[i].id, fm[i].name, fm[i].url)
    end

    local rows = Staff29.Query("SELECT faction_name, image, banner FROM faction_hub", {})
    for i = 1, #rows do
        if rows[i].image and rows[i].image ~= "" then
            push(rows[i].image, rows[i].faction_name .. " (logo)", rows[i].image)
        end
        if rows[i].banner and rows[i].banner ~= "" then
            push(rows[i].banner, rows[i].faction_name .. " (bannière)", rows[i].banner)
        end
    end

    return out
end

local function decodePos(raw)
    local vec = Staff29.Vec(Staff29.Decode(raw, nil))
    if not vec then return { x = 0.0, y = 0.0, z = 0.0 } end
    return vec
end

local function posSet(pos)
    if type(pos) ~= "table" then return false end
    return (tonumber(pos.x) or 0) ~= 0 or (tonumber(pos.y) or 0) ~= 0 or (tonumber(pos.z) or 0) ~= 0
end

local function charName(identifier)
    local row = Staff29.Single(
        "SELECT firstname, lastname FROM characters WHERE identifier = ? AND deleted_at IS NULL",
        { identifier }
    )
    if not row then return "Inconnu" end
    local first = row.firstname or ""
    local last = row.lastname or ""
    local name = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
    return name ~= "" and name or "Inconnu"
end

local function ensureTables()
    if hubReady then return end
    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS faction_hub (
            faction_name   VARCHAR(60)  NOT NULL,
            image          VARCHAR(512) DEFAULT NULL,
            banner         VARCHAR(512) DEFAULT NULL,
            active         TINYINT(1)   NOT NULL DEFAULT 0,
            posLaboratory  LONGTEXT     DEFAULT NULL,
            posCraft       LONGTEXT     DEFAULT NULL,
            posStockage    LONGTEXT     DEFAULT NULL,
            posGarage      LONGTEXT     DEFAULT NULL,
            PRIMARY KEY (faction_name)
        )
    ]], {})
    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS banner_templates (
            id    INT(11)      NOT NULL AUTO_INCREMENT,
            kind  VARCHAR(32)  NOT NULL,
            name  VARCHAR(100) NOT NULL,
            url   VARCHAR(512) NOT NULL,
            PRIMARY KEY (id),
            KEY idx_banner_templates_kind (kind)
        )
    ]], {})
    hubReady = true
end

local function crewRow(name)
    if not Staff29.IsString(name, 60) then return nil end
    if name == "nocrew" or name == "nofaction" then return nil end
    return Staff29.Single("SELECT * FROM crews WHERE name = ?", { name })
end

local function hubRow(name)
    ensureTables()
    return Staff29.Single("SELECT * FROM faction_hub WHERE faction_name = ?", { name })
end

local function upsertHub(name, fields)
    ensureTables()
    local current = hubRow(name) or {}
    local image = fields.image ~= nil and fields.image or (current.image or "")
    local banner = fields.banner ~= nil and fields.banner or (current.banner or "")
    local active = fields.active
    if active == nil then
        active = tonumber(current.active) or 0
    else
        active = active and 1 or 0
    end
    local posLaboratory = fields.posLaboratory ~= nil and fields.posLaboratory or current.posLaboratory
    local posCraft = fields.posCraft ~= nil and fields.posCraft or current.posCraft
    local posStockage = fields.posStockage ~= nil and fields.posStockage or current.posStockage
    local posGarage = fields.posGarage ~= nil and fields.posGarage or current.posGarage
    Staff29.Update([[
        INSERT INTO faction_hub (faction_name, image, banner, active, posLaboratory, posCraft, posStockage, posGarage)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            image = VALUES(image),
            banner = VALUES(banner),
            active = VALUES(active),
            posLaboratory = VALUES(posLaboratory),
            posCraft = VALUES(posCraft),
            posStockage = VALUES(posStockage),
            posGarage = VALUES(posGarage)
    ]], {
        name, image, banner, active,
        posLaboratory, posCraft, posStockage, posGarage,
    })
end

local function bannersOf(kind)
    ensureTables()
    local rows = Staff29.Query(
        "SELECT id, name, url FROM banner_templates WHERE kind = ? ORDER BY name ASC",
        { kind }
    )
    local out = {}
    for i = 1, #rows do
        out[i] = { id = tonumber(rows[i].id), name = rows[i].name, url = rows[i].url }
    end
    return out
end

local function ensureCrewPerms(name)
    for i = 1, #RANK_NAMES do
        Staff29.Update([[
            INSERT INTO crew_permissions (crew_name, grade_name, permissions) VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE crew_name = crew_name
        ]], { name, RANK_NAMES[i], Staff29.Encode(DEFAULT_CREW_PERMS[RANK_NAMES[i]]) })
    end
end

local function ensureGrades(name)
    local rows = Staff29.Query(
        "SELECT * FROM faction_grades WHERE faction_name = ? ORDER BY level DESC",
        { name }
    )
    if #rows > 0 then return rows end
    Staff29.Update([[
        INSERT IGNORE INTO faction_grades (faction_name, name, level, color, permissions)
        VALUES (?, 'Patron', 10, '#e53935', ?), (?, 'Membre', 0, '#9e9e9e', ?)
    ]], {
        name, Staff29.Encode(gradeDefaults(true)),
        name, Staff29.Encode(gradeDefaults(false)),
    })
    return Staff29.Query(
        "SELECT * FROM faction_grades WHERE faction_name = ? ORDER BY level DESC",
        { name }
    )
end

local function gradeList(name)
    local rows = ensureGrades(name)
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local level = tonumber(row.level) or 0
        out[#out + 1] = {
            grade = level,
            level = level,
            name = row.name or ("Grade " .. level),
            label = row.name or ("Grade " .. level),
            color = row.color or "#9e9e9e",
        }
    end
    table.sort(out, function(a, b) return (a.level or 0) > (b.level or 0) end)
    return out
end

local function lowestGradeLevel(name)
    local grades = gradeList(name)
    if #grades == 0 then return 0 end
    return grades[#grades].level or 0
end

local function crewRankFromLevel(name, level)
    local grades = gradeList(name)
    for i = 1, #grades do
        if grades[i].level == level then
            if i > 5 then return 5 end
            return i
        end
    end
    return 5
end

local function pushIdentifier(identifier)
    local xTarget = VFW.GetPlayerFromIdentifier(identifier)
    if xTarget and Staff29.Factions and Staff29.Factions.Push then
        Staff29.Factions.Push(xTarget)
    end
end

local function publicFaction(crew, hub, counts)
    hub = hub or {}
    local hasHub = hub.faction_name ~= nil
    local active = true
    if hasHub then
        active = tonumber(hub.active) == 1
    end
    return {
        name = crew.name,
        label = crew.label or crew.name,
        devise = crew.devise or "",
        image = hub.image or "",
        banner = hub.banner or "",
        color = crew.color or "#e53935",
        active = active,
        memberCount = counts and counts.members or 0,
        gradeCount = counts and counts.grades or 0,
        posLaboratory = decodePos(hub.posLaboratory),
        posCraft = decodePos(hub.posCraft),
        posStockage = decodePos(hub.posStockage),
        posGarage = decodePos(hub.posGarage),
    }
end

local function memberCounts()
    local out = {}
    local crewRows = Staff29.Query("SELECT crew_name, COUNT(*) AS total FROM crew_members GROUP BY crew_name", {})
    for i = 1, #crewRows do
        local name = crewRows[i].crew_name
        out[name] = out[name] or { members = 0, grades = 0 }
        out[name].members = tonumber(crewRows[i].total) or 0
    end
    local facRows = Staff29.Query("SELECT faction_name, COUNT(*) AS total FROM faction_members GROUP BY faction_name", {})
    for i = 1, #facRows do
        local name = facRows[i].faction_name
        out[name] = out[name] or { members = 0, grades = 0 }
        local n = tonumber(facRows[i].total) or 0
        if n > (out[name].members or 0) then out[name].members = n end
    end
    local gradeRows = Staff29.Query("SELECT faction_name, COUNT(*) AS total FROM faction_grades GROUP BY faction_name", {})
    for i = 1, #gradeRows do
        local name = gradeRows[i].faction_name
        out[name] = out[name] or { members = 0, grades = 0 }
        out[name].grades = tonumber(gradeRows[i].total) or 0
    end
    return out
end

local function listAll()
    ensureTables()
    local crews = Staff29.Query("SELECT * FROM crews ORDER BY label ASC", {})
    local hubs = {}
    local hubRows = Staff29.Query("SELECT * FROM faction_hub", {})
    for i = 1, #hubRows do
        hubs[hubRows[i].faction_name] = hubRows[i]
    end
    local counts = memberCounts()
    local out = {}
    for i = 1, #crews do
        local crew = crews[i]
        if crew.name ~= "nocrew" and crew.name ~= "nofaction" then
            out[#out + 1] = publicFaction(crew, hubs[crew.name], counts[crew.name])
        end
    end
    return out
end

local function memberList(name)
    local seen = {}
    local out = {}

    local function push(identifier, gradeLevel, firstname, lastname)
        if not identifier or seen[identifier] then return end
        seen[identifier] = true
        local online = VFW.GetPlayerFromIdentifier(identifier)
        out[#out + 1] = {
            identifier = identifier,
            firstname = firstname or "",
            lastname = lastname or "",
            fname = firstname or "",
            lname = lastname or "",
            faction_grade = tonumber(gradeLevel) or 0,
            grade = tonumber(gradeLevel) or 0,
            isOnline = online ~= nil,
            serverId = online and online.source or nil,
        }
    end

    local facRows = Staff29.Query([[
        SELECT fm.identifier, fm.grade_level, c.firstname, c.lastname
        FROM faction_members fm
        LEFT JOIN characters c ON c.identifier = fm.identifier AND c.deleted_at IS NULL
        WHERE fm.faction_name = ?
        ORDER BY fm.grade_level DESC, c.lastname ASC
    ]], { name })
    for i = 1, #facRows do
        local row = facRows[i]
        push(row.identifier, row.grade_level, row.firstname, row.lastname)
    end

    local crewRows = Staff29.Query([[
        SELECT cm.identifier, cm.rank, c.firstname, c.lastname
        FROM crew_members cm
        LEFT JOIN characters c ON c.identifier = cm.identifier AND c.deleted_at IS NULL
        WHERE cm.crew_name = ?
        ORDER BY cm.rank ASC, c.lastname ASC
    ]], { name })
    for i = 1, #crewRows do
        local row = crewRows[i]
        if not seen[row.identifier] then
            local grades = gradeList(name)
            local rank = tonumber(row.rank) or 5
            local level = grades[rank] and grades[rank].level or lowestGradeLevel(name)
            push(row.identifier, level, row.firstname, row.lastname)
        end
    end

    return out
end

local function refreshClients()
    TriggerClientEvent("core:gestion-factions:refresh", -1)
end

local function attachMember(name, identifier)
    local crew = crewRow(name)
    if not crew then return { state = false, error = "Cette faction est introuvable." } end
    if not Staff29.IsString(identifier, 80) then
        return { state = false, error = "Identifiant invalide." }
    end

    local char = Staff29.Single(
        "SELECT identifier, firstname, lastname, faction FROM characters WHERE identifier = ? AND deleted_at IS NULL",
        { identifier }
    )
    if not char then return { state = false, error = "Personnage introuvable." } end

    local already = Staff29.Single(
        "SELECT crew_name FROM crew_members WHERE identifier = ? LIMIT 1",
        { identifier }
    )
    if already and already.crew_name == name then
        return { state = false, error = "Ce personnage est déjà dans cette faction." }
    end

    local level = lowestGradeLevel(name)
    local rank = crewRankFromLevel(name, level)
    local display = charName(identifier)

    Staff29.Update("DELETE FROM crew_members WHERE identifier = ?", { identifier })
    Staff29.Update("DELETE FROM faction_members WHERE identifier = ?", { identifier })

    Staff29.Update([[
        INSERT INTO crew_members (crew_name, identifier, rank, xp, role, seniority, status, joined_at)
        VALUES (?, ?, ?, 0, ?, ?, 'offline', ?)
        ON DUPLICATE KEY UPDATE crew_name = VALUES(crew_name), rank = VALUES(rank), role = VALUES(role)
    ]], { name, identifier, rank, RANK_LABELS[rank] or "Recrue", Staff29.Now(), Staff29.Now() })

    Staff29.Update([[
        INSERT INTO faction_members (faction_name, identifier, name, grade_level, joined_at, last_seen)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE faction_name = VALUES(faction_name), grade_level = VALUES(grade_level), name = VALUES(name)
    ]], { name, identifier, display, level, Staff29.Now(), Staff29.Now() })

    Staff29.Update("UPDATE characters SET faction = ? WHERE identifier = ?", { name, identifier })
    pushIdentifier(identifier)

    return { state = true, name = display }
end

local function removeMember(name, identifier)
    if not crewRow(name) or not Staff29.IsString(identifier, 80) then return false end
    Staff29.Update("DELETE FROM crew_members WHERE crew_name = ? AND identifier = ?", { name, identifier })
    Staff29.Update("DELETE FROM faction_members WHERE faction_name = ? AND identifier = ?", { name, identifier })
    Staff29.Update("UPDATE characters SET faction = '' WHERE identifier = ? AND faction = ?", { identifier, name })
    pushIdentifier(identifier)
    return true
end

local function hubPanel(selectedName)
    ensureTables()
    local factions = listAll()
    local selected = nil
    if selectedName and selectedName ~= "" then
        for i = 1, #factions do
            if factions[i].name == selectedName then
                selected = factions[i]
                break
            end
        end
        if selected then
            selected.grades = gradeList(selectedName)
            selected.members = memberList(selectedName)
        end
    end
    local banners = bannersOf("faction")
    local media = mediaLibrary()
    local seen = {}
    for i = 1, #media do seen[media[i].url] = true end
    for i = 1, #banners do
        if banners[i].url and not seen[banners[i].url] then
            seen[banners[i].url] = true
            media[#media + 1] = banners[i]
        end
    end
    return {
        ok = true,
        factions = factions,
        banners = banners,
        media = media,
        selected = selected,
    }
end

local function createFaction(name, label, devise, logo, color, banner)
    ensureTables()
    local id = slugName(name)
    local cleanLabel = Staff29.Clean(label, 100)
    if not id or not cleanLabel or cleanLabel:gsub("%s", "") == "" then
        return false
    end
    if crewRow(id) then return false end

    local hex = hexColor(color, "#E53935")
    local motto = Staff29.Clean(devise, 255) or ""
    local image = cleanUrl(logo)
    local flag = cleanUrl(banner)

    Staff29.Insert([[
        INSERT INTO crews (name, label, type, color, activity, hierarchie, devise, place, xp, influence, created_at)
        VALUES (?, ?, 'crew', ?, 'gang', 'Gang de rue', ?, 2, 0, 0, ?)
    ]], { id, cleanLabel, hex, motto, Staff29.Now() })

    upsertHub(id, {
        image = image,
        banner = flag,
        active = false,
    })
    ensureCrewPerms(id)
    ensureGrades(id)
    refreshClients()
    return true
end

Staff29.Cb("core:staff:createFaction", function(source, name, label, devise, logo, color, banner)
    if not staffOk(source) then return false end
    if not Staff29.RateLimit(source, "create_faction", 800) then return false end
    return createFaction(name, label, devise, logo, color, banner)
end)

Staff29.Cb("core:gestion-factions:getAll", function(source)
    if not staffOk(source) then return {} end
    return listAll()
end)

Staff29.Cb("core:gestion-factions:updateField", function(source, name, field, value)
    if not staffOk(source) then return false end
    if not crewRow(name) or not FIELD_KEYS[field] then return false end

    if field == "label" then
        local label = Staff29.Clean(value, 100)
        if not label or label:gsub("%s", "") == "" then return false end
        Staff29.Update("UPDATE crews SET label = ? WHERE name = ?", { label, name })
    elseif field == "devise" then
        Staff29.Update("UPDATE crews SET devise = ? WHERE name = ?", { Staff29.Clean(value, 255) or "", name })
    elseif field == "color" then
        local hex = hexColor(value, nil)
        if not hex then return false end
        Staff29.Update("UPDATE crews SET color = ? WHERE name = ?", { hex, name })
    elseif field == "image" then
        upsertHub(name, { image = cleanUrl(value) })
    elseif field == "banner" then
        upsertHub(name, { banner = cleanUrl(value) })
    end

    if Staff29.Factions and Staff29.Factions.PushCrew then
        Staff29.Factions.PushCrew(name)
    end
    return true
end)

Staff29.Cb("core:gestion-factions:setPosition", function(source, name, key)
    if not staffOk(source) then return false end
    if not crewRow(name) or not POS_KEYS[key] then return false end
    local coords = GetEntityCoords(GetPlayerPed(source))
    if not coords then return false end
    local pos = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
    local encoded = Staff29.Encode(pos)
    local patch = { [key] = encoded }
    upsertHub(name, patch)
    if key == "posCraft" then
        Staff29.Update("UPDATE crews SET craft_pos = ? WHERE name = ?", { encoded, name })
    end
    return true
end)

Staff29.Cb("core:gestion-factions:activate", function(source, name)
    if not staffOk(source) then return false end
    local crew = crewRow(name)
    if not crew then return false end
    local hub = hubRow(name)
    if not hub then return false end
    if not (posSet(decodePos(hub.posLaboratory))
        and posSet(decodePos(hub.posCraft))
        and posSet(decodePos(hub.posStockage))
        and posSet(decodePos(hub.posGarage))) then
        return false
    end
    upsertHub(name, { active = true })
    refreshClients()
    return true
end)

Staff29.Cb("core:gestion-factions:delete", function(source, name)
    if not staffOk(source) then return false end
    if not crewRow(name) then return false end

    local members = Staff29.Query("SELECT identifier FROM crew_members WHERE crew_name = ?", { name })
    local extra = Staff29.Query("SELECT identifier FROM faction_members WHERE faction_name = ?", { name })
    Staff29.Update("DELETE FROM crew_members WHERE crew_name = ?", { name })
    Staff29.Update("DELETE FROM crew_permissions WHERE crew_name = ?", { name })
    Staff29.Update("DELETE FROM faction_members WHERE faction_name = ?", { name })
    Staff29.Update("DELETE FROM faction_grades WHERE faction_name = ?", { name })
    Staff29.Update("DELETE FROM faction_hub WHERE faction_name = ?", { name })
    Staff29.Update("DELETE FROM crews WHERE name = ?", { name })
    Staff29.Update("UPDATE characters SET faction = '' WHERE faction = ?", { name })
    TriggerClientEvent("core:faction:deleteFaction", -1, name)

    local seen = {}
    for i = 1, #members do seen[members[i].identifier] = true end
    for i = 1, #extra do seen[extra[i].identifier] = true end
    for identifier in pairs(seen) do
        pushIdentifier(identifier)
    end
    refreshClients()
    return true
end)

Staff29.Cb("core:gestion-factions:getGrades", function(source, name)
    if not staffOk(source) then return {} end
    if not crewRow(name) then return {} end
    return gradeList(name)
end)

Staff29.Cb("core:gestion-factions:addGrade", function(source, name, gradeName, gradeLabel)
    if not staffOk(source) then return { success = false, error = "Permission refusée." } end
    if not crewRow(name) then return { success = false, error = "Cette faction est introuvable." } end
    ensureGrades(name)
    local label = Staff29.Clean(gradeLabel, 64) or Staff29.Clean(gradeName, 64)
    if not label or label:gsub("%s", "") == "" then
        return { success = false, error = "Ce nom n'est pas valide." }
    end

    local grades = gradeList(name)
    local used, maxLevel = {}, -1
    for i = 1, #grades do
        used[grades[i].level] = true
        if grades[i].level > maxLevel then maxLevel = grades[i].level end
    end

    local level = nil
    if maxLevel >= 0 then
        for candidate = 0, maxLevel - 1 do
            if not used[candidate] then
                level = candidate
                break
            end
        end
    end
    if not level then
        if maxLevel < 97 then
            level = maxLevel + 1
        else
            return { success = false, error = "Aucun niveau libre." }
        end
    end

    Staff29.Update([[
        INSERT INTO faction_grades (faction_name, name, level, color, permissions)
        VALUES (?, ?, ?, '#9e9e9e', ?)
    ]], { name, label, level, Staff29.Encode(gradeDefaults(false)) })

    return { success = true, grade = { level = level, grade = level, label = label, name = label } }
end)

Staff29.Cb("core:gestion-factions:moveGrade", function(source, name, gradeLevel, direction)
    if not staffOk(source) then return { success = false, error = "Permission refusée." } end
    if not crewRow(name) then return { success = false, error = "Cette faction est introuvable." } end
    local level = Staff29.ToInt(gradeLevel, 0, 999)
    if not level then return { success = false, error = "Grade invalide." } end

    local grades = gradeList(name)
    local currentIndex = nil
    for i = 1, #grades do
        if grades[i].level == level then
            currentIndex = i
            break
        end
    end
    if not currentIndex then return { success = false, error = "Ce grade est introuvable." } end

    local other
    if direction == "up" then
        other = grades[currentIndex - 1]
    else
        other = grades[currentIndex + 1]
    end
    if not other then return { success = false, error = "Impossible de déplacer ce grade." } end

    local levelA, levelB = level, other.level
    Staff29.Update("UPDATE faction_grades SET level = -1 WHERE faction_name = ? AND level = ?", { name, levelA })
    Staff29.Update("UPDATE faction_grades SET level = ? WHERE faction_name = ? AND level = ?", { levelA, name, levelB })
    Staff29.Update("UPDATE faction_grades SET level = ? WHERE faction_name = ? AND level = -1", { levelB, name })
    Staff29.Update("UPDATE faction_members SET grade_level = -1 WHERE faction_name = ? AND grade_level = ?", { name, levelA })
    Staff29.Update("UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = ?", { levelA, name, levelB })
    Staff29.Update("UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = -1", { levelB, name })
    return { success = true }
end)

Staff29.Cb("core:gestion-factions:updateGradeLabel", function(source, name, gradeLevel, newLabel)
    if not staffOk(source) then return false end
    if not crewRow(name) then return false end
    local level = Staff29.ToInt(gradeLevel, 0, 999)
    local label = Staff29.Clean(newLabel, 64)
    if not level or not label or label:gsub("%s", "") == "" then return false end
    local updated = Staff29.Update(
        "UPDATE faction_grades SET name = ? WHERE faction_name = ? AND level = ?",
        { label, name, level }
    )
    return (updated or 0) > 0
end)

Staff29.Cb("core:gestion-factions:deleteGrade", function(source, name, gradeLevel)
    if not staffOk(source) then return false end
    if not crewRow(name) then return false end
    local level = Staff29.ToInt(gradeLevel, 0, 999)
    if not level then return false end
    local grades = gradeList(name)
    if #grades <= 1 then return false end
    Staff29.Update("DELETE FROM faction_grades WHERE faction_name = ? AND level = ?", { name, level })
    local fallback = lowestGradeLevel(name)
    Staff29.Update(
        "UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = ?",
        { fallback, name, level }
    )
    return true
end)

Staff29.Cb("core:gestion-factions:getMembers", function(source, name)
    if not staffOk(source) then return {} end
    if not crewRow(name) then return {} end
    return memberList(name)
end)

Staff29.Cb("core:gestion-factions:addMemberById", function(source, data)
    if not staffOk(source) then return { state = false, error = "Permission refusée." } end
    if type(data) ~= "table" then return { state = false, error = "Cette demande n'a pas pu être traitée." } end
    local name = data.faction
    local serverId = Staff29.ToInt(data.serverId, 1, 65535)
    if not crewRow(name) or not serverId then
        return { state = false, error = "Joueur non trouvé." }
    end
    local xTarget = VFW.GetPlayerFromId(serverId)
    if not xTarget or not xTarget.identifier then
        return { state = false, error = "Joueur non trouvé." }
    end
    return attachMember(name, xTarget.identifier)
end)

Staff29.Cb("core:gestion-factions:addMember", function(source, data)
    if not staffOk(source) then return { state = false, error = "Permission refusée." } end
    if type(data) ~= "table" then return { state = false, error = "Cette demande n'a pas pu être traitée." } end
    return attachMember(data.faction, data.identifier)
end)

Staff29.Cb("core:gestion-factions:getCharsByGlobalId", function(source, globalId)
    if not staffOk(source) then return { state = false, error = "Permission refusée." } end
    local accountId = Staff29.ToInt(globalId, 1)
    if not accountId then return { state = false, error = "Cet identifiant n'est pas valide." } end
    local rows = Staff29.Query([[
        SELECT identifier, firstname, lastname, char_slot
        FROM characters
        WHERE account_id = ? AND deleted_at IS NULL
        ORDER BY char_slot ASC
    ]], { accountId })
    if #rows == 0 then
        return { state = false, error = "Aucun personnage trouvé." }
    end
    return { state = true, chars = rows }
end)

Staff29.Cb("core:gestion-factions:updateMemberGrade", function(source, name, identifier, gradeLevel)
    if not staffOk(source) then return false end
    if not crewRow(name) or not Staff29.IsString(identifier, 80) then return false end
    local level = Staff29.ToInt(gradeLevel, 0, 999)
    if not level then return false end
    local grade = Staff29.Single(
        "SELECT level FROM faction_grades WHERE faction_name = ? AND level = ?",
        { name, level }
    )
    if not grade then return false end
    local rank = crewRankFromLevel(name, level)
    Staff29.Update(
        "UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND identifier = ?",
        { level, name, identifier }
    )
    Staff29.Update(
        "UPDATE crew_members SET rank = ?, role = ? WHERE crew_name = ? AND identifier = ?",
        { rank, RANK_LABELS[rank] or "Recrue", name, identifier }
    )
    pushIdentifier(identifier)
    return true
end)

Staff29.Cb("core:gestion-factions:removeMember", function(source, name, identifier)
    if not staffOk(source) then return false end
    return removeMember(name, identifier)
end)

Staff29.Cb("gestionFactions:hubPanel", function(source, selectedName)
    if not staffOk(source) then return { ok = false } end
    return hubPanel(selectedName)
end)

Staff29.Cb("core:staff:getOrganizations", function(source)
    if not staffOk(source) and not Staff29.Has(source, "setjob2") then return {} end
    local rows = Staff29.Query("SELECT name, label, color FROM crews ORDER BY label ASC", {})
    local out = {}
    for i = 1, #rows do
        if rows[i].name ~= "nocrew" and rows[i].name ~= "nofaction" then
            out[#out + 1] = {
                name = rows[i].name,
                label = rows[i].label or rows[i].name,
                color = rows[i].color or "#FFFFFF",
            }
        end
    end
    return out
end)

Staff29.Cb("core:factions:getOrganizations", function(source)
    local rows = listAll()
    local out = {}
    for i = 1, #rows do
        local f = rows[i]
        out[f.name] = {
            name = f.name,
            label = f.label,
            devise = f.devise,
            image = f.image,
            banner = f.banner,
            color = f.color,
            type = "gang",
            xp = 0,
            members = {},
            vehicles = {},
            territories = {},
            properties = {},
            shops = {},
            posLaboratory = f.posLaboratory,
            posCraft = f.posCraft,
            posStockage = f.posStockage,
            posGarage = f.posGarage,
        }
    end
    return out
end)

Staff29.Cb("core:factions:getNewOrganizations", function(source)
    if not staffOk(source) then return {} end
    local rows = listAll()
    local out = {}
    for i = 1, #rows do
        if not rows[i].active then
            out[#out + 1] = rows[i]
        end
    end
    return out
end)

Staff29.Cb("vfw:server:getBannerTemplates", function(source, kind)
    if not staffOk(source) then return {} end
    local key = kind == "metier" and "metier" or "faction"
    return bannersOf(key)
end)

Staff29.Cb("vfw:server:getBannerTemplatesPublic", function(_, kind)
    local key = kind == "metier" and "metier" or "faction"
    return bannersOf(key)
end)

Staff29.Cb("vfw:server:addBannerTemplate", function(source, kind, name, url)
    if not staffOk(source) then return false end
    local key = kind == "metier" and "metier" or (kind == "faction" and "faction" or nil)
    local label = Staff29.Clean(name, 100)
    local link = cleanUrl(url)
    if not key or not label or link == "" then return false end
    ensureTables()
    Staff29.Insert("INSERT INTO banner_templates (kind, name, url) VALUES (?, ?, ?)", { key, label, link })
    return true
end)

Staff29.Cb("vfw:server:deleteBannerTemplate", function(source, id)
    if not staffOk(source) then return false end
    local rowId = Staff29.ToInt(id, 1)
    if not rowId then return false end
    ensureTables()
    Staff29.Update("DELETE FROM banner_templates WHERE id = ?", { rowId })
    return true
end)
