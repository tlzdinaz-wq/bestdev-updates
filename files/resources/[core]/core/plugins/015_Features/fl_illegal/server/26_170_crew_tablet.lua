local Tablet = {
    viewers = {},
    requests = {},
    requestSeq = 0,
}

local PERM_KEYS = {
    "canAccessTablet", "canRecruit", "canKick", "canPromote",
    "canDemote", "canManageChest", "canManageGrades",
}

local REQUEST_TTL = 60

local function DefaultPermissions(isBoss)
    local out = {}
    for i = 1, #PERM_KEYS do
        out[PERM_KEYS[i]] = isBoss and true or false
    end
    out.canAccessTablet = true
    return out
end

local function NormalizePermissions(raw, isBoss)
    local out = DefaultPermissions(isBoss)
    if IL.IsTable(raw) then
        for i = 1, #PERM_KEYS do
            local key = PERM_KEYS[i]
            if raw[key] ~= nil then
                out[key] = raw[key] == true
            end
        end
    end
    return out
end

local function Initials(label)
    if type(label) ~= "string" or label == "" then return "??" end
    local letters = ""
    for word in label:gmatch("%S+") do
        letters = letters .. word:sub(1, 1):upper()
        if #letters >= 3 then break end
    end
    if letters == "" then letters = label:sub(1, 2):upper() end
    return letters
end

local function EnsureGrades(factionName)
    local rows = IL.Query("SELECT * FROM faction_grades WHERE faction_name = ? ORDER BY level DESC", { factionName })
    if #rows > 0 then return rows end

    IL.Execute([[
        INSERT IGNORE INTO faction_grades (faction_name, name, level, color, permissions)
        VALUES (?, 'Patron', 10, '#e53935', ?), (?, 'Membre', 0, '#9e9e9e', ?)
    ]], {
        factionName, IL.Encode(DefaultPermissions(true)),
        factionName, IL.Encode(DefaultPermissions(false)),
    })

    return IL.Query("SELECT * FROM faction_grades WHERE faction_name = ? ORDER BY level DESC", { factionName })
end

local function GradeList(factionName)
    local rows = EnsureGrades(factionName)
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local level = IL.Int(row.level, 0)
        out[#out + 1] = {
            id = row.id,
            name = row.name,
            level = level,
            color = row.color or "#9e9e9e",
            permissions = NormalizePermissions(IL.Decode(row.permissions, nil), level >= 10),
        }
    end
    table.sort(out, function(a, b) return a.level > b.level end)
    return out
end

local function EnsureMeta(factionName)
    local row = IL.Single("SELECT * FROM faction_meta WHERE faction_name = ?", { factionName })
    if row then return row end
    IL.Execute("INSERT IGNORE INTO faction_meta (faction_name) VALUES (?)", { factionName })
    return IL.Single("SELECT * FROM faction_meta WHERE faction_name = ?", { factionName }) or {}
end

local function MemberRow(factionName, permId)
    return IL.Single("SELECT * FROM faction_members WHERE faction_name = ? AND identifier = ?", { factionName, permId })
end

local function EnsureMember(factionName, xPlayer)
    if not xPlayer then return nil end
    local row = MemberRow(factionName, xPlayer.identifier)
    if row then
        IL.Execute("UPDATE faction_members SET name = ?, last_seen = NOW() WHERE id = ?", { xPlayer.name, row.id })
        return row
    end

    local grades = GradeList(factionName)
    local lowest = grades[#grades]
    IL.Execute([[
        INSERT INTO faction_members (faction_name, identifier, name, grade_level, joined_at, last_seen)
        VALUES (?, ?, ?, ?, NOW(), NOW())
    ]], { factionName, xPlayer.identifier, xPlayer.name, lowest and lowest.level or 0 })

    return MemberRow(factionName, xPlayer.identifier)
end

local function FindGradeByLevel(grades, level)
    for i = 1, #grades do
        if grades[i].level == level then return grades[i] end
    end
    return grades[#grades]
end

local function OnlineByIdentifier(identifier)
    if not VFW or not VFW.PlayersByIdentifier then return nil end
    return VFW.PlayersByIdentifier[identifier]
end

local function MyGrade(factionName, xPlayer)
    local grades = GradeList(factionName)
    local member = EnsureMember(factionName, xPlayer)
    local level = member and IL.Int(member.grade_level, 0) or 0
    return FindGradeByLevel(grades, level), grades, member
end

local function HasPerm(factionName, xPlayer, permission)
    local grade = MyGrade(factionName, xPlayer)
    if not grade then return false end
    return grade.permissions[permission] == true
end

local function ChestList(factionName)
    local rows = IL.Query("SELECT * FROM faction_chests WHERE faction_name = ?", { factionName })
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            accessName = row.access_name or row.id,
            name = row.name or row.id,
            gradeMinTake = IL.Int(row.grade_min_take, 0),
            gradeMinPut = IL.Int(row.grade_min_put, 0),
            gradeMinHistory = IL.Int(row.grade_min_history, 0),
            maxWeight = IL.Int(row.max_weight, 100000),
            weight = 0,
        }
    end
    return out
end

local function ChestHistory(factionName, chestId, limit)
    limit = IL.Clamp(IL.Int(limit, 50), 1, 200)
    local rows
    if chestId and chestId ~= "all" then
        rows = IL.Query([[
            SELECT h.* FROM faction_chest_history h
            INNER JOIN faction_chests c ON c.id = h.chest_id
            WHERE c.faction_name = ? AND h.chest_id = ?
            ORDER BY h.id DESC LIMIT ]] .. limit, { factionName, chestId })
    else
        rows = IL.Query([[
            SELECT h.* FROM faction_chest_history h
            INNER JOIN faction_chests c ON c.id = h.chest_id
            WHERE c.faction_name = ?
            ORDER BY h.id DESC LIMIT ]] .. limit, { factionName })
    end

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        out[#out + 1] = {
            id = row.id,
            memberName = row.member_name,
            memberId = row.member_id,
            action = row.action,
            itemName = row.item_name,
            quantity = IL.Int(row.quantity, 0),
            date = tostring(row.date),
        }
    end
    return out
end

local function NearbyRecruitable(source, factionName)
    local out = {}
    local coords = IL.Coords(source)
    if not coords then return out end

    local players = VFW.GetPlayersInRadius(coords, 12.0)
    for i = 1, #players do
        local other = players[i]
        if other.source ~= source and IL.FactionName(other) ~= factionName then
            out[#out + 1] = { source = other.source, name = other.name, permId = other.identifier }
        end
    end
    return out
end

local function BuildData(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" or factionName == "nofaction" or factionName == "nocrew" then return nil end

    local grade, grades, member = MyGrade(factionName, xPlayer)
    if not grade or not grade.permissions.canAccessTablet then return nil end

    local meta = EnsureMeta(factionName)
    local label = IL.FactionLabel(xPlayer)
    if label == "" then label = factionName end

    local memberRows = IL.Query("SELECT * FROM faction_members WHERE faction_name = ? ORDER BY grade_level DESC, name ASC", { factionName })
    local members = {}
    for i = 1, #memberRows do
        local row = memberRows[i]
        local level = IL.Int(row.grade_level, 0)
        local gradeData = FindGradeByLevel(grades, level)
        local online = OnlineByIdentifier(row.identifier)
        members[#members + 1] = {
            odid = row.identifier,
            permId = row.identifier,
            name = row.name or "Inconnu",
            gradeId = gradeData and gradeData.id or 0,
            gradeName = gradeData and gradeData.name or "Membre",
            gradeLevel = level,
            joinedAt = row.joined_at and tostring(row.joined_at) or "",
            lastSeen = row.last_seen and tostring(row.last_seen) or nil,
            isOnline = online ~= nil,
        }
    end

    return {
        factionId = factionName,
        factionName = label,
        factionDesc = meta.description or "",
        factionColor = meta.color or "#e53935",
        factionInitials = Initials(label),
        factionMotto = meta.motto or "",
        myGrade = grade,
        myPermId = xPlayer.identifier,
        grades = grades,
        members = members,
        chestConfig = {
            minGradeDeposit = IL.Int(meta.chest_min_deposit, 0),
            minGradeWithdraw = IL.Int(meta.chest_min_withdraw, 0),
            minGradeHistory = IL.Int(meta.chest_min_history, 0),
        },
        chests = ChestList(factionName),
        chestHistory = ChestHistory(factionName, "all", 25),
        recruitablePlayers = NearbyRecruitable(source, factionName),
    }
end

local function PushUpdate(factionName)
    local targets, n = {}, 0
    for source in pairs(Tablet.viewers) do
        n = n + 1
        targets[n] = source
    end

    for i = 1, n do
        local source = targets[i]
        if Tablet.viewers[source] then
            local xPlayer = IL.Player(source)
            if xPlayer and IL.FactionName(xPlayer) == factionName then
                local data = BuildData(source)
                if data then
                    TriggerClientEvent("core:faction-tablet:updateData", source, data)
                else
                    TriggerClientEvent("core:faction-tablet:forceClose", source)
                    Tablet.viewers[source] = nil
                end
            end
        end
    end
end

IL.OnPlayerDropped(function(source)
    Tablet.viewers[source] = nil
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    local factionName = IL.FactionName(xPlayer)
    if factionName ~= "" and factionName ~= "nofaction" and factionName ~= "nocrew" then
        EnsureMember(factionName, xPlayer)
    end
end)

CreateThread(function()
    while true do
        Wait(15000)
        local now = IL.Now()
        local expired, count = {}, 0
        for id, request in pairs(Tablet.requests) do
            if now - request.createdAt > REQUEST_TTL then
                count = count + 1
                expired[count] = request.dbId
                Tablet.requests[id] = nil
            end
        end
        for i = 1, count do
            IL.Execute("UPDATE faction_recruit_requests SET status = 'expired' WHERE id = ?", { expired[i] })
        end
    end
end)

IL.RegisterCallback("core:faction-tablet:registerViewer", function(source)
    Tablet.viewers[source] = true
    return true
end)

IL.RegisterCallback("core:faction-tablet:unregisterViewer", function(source)
    Tablet.viewers[source] = nil
    return true
end)

IL.RegisterCallback("core:faction-tablet:canAccessTablet", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" or factionName == "nofaction" or factionName == "nocrew" then return false end

    return HasPerm(factionName, xPlayer, "canAccessTablet")
end)

IL.RegisterCallback("core:faction-tablet:getData", function(source)
    return BuildData(source)
end)

IL.RegisterCallback("core:faction-tablet:getNearbyPlayers", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return {} end
    return NearbyRecruitable(source, IL.FactionName(xPlayer))
end)

IL.RegisterCallback("core:faction-tablet:getChestHistory", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, history = {} } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, history = {} } end

    local chestId = "all"
    local limit = 50
    if IL.IsTable(data) then
        chestId = IL.Str(data.chestId, "all")
        limit = IL.Int(data.limit, 50)
    end

    return { success = true, history = ChestHistory(factionName, chestId, limit) }
end)

IL.RegisterCallback("core:faction-tablet:recruit", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Vous n'avez pas d'organisation" } end
    if not HasPerm(factionName, xPlayer, "canRecruit") then
        return { success = false, message = "Vous n'avez pas la permission de recruter" }
    end

    local targetSource = IL.Int(data.targetSource, nil)
    local targetPermId = IL.Str(data.targetPermId, nil)
    local gradeId = IL.Int(data.gradeId, nil)
    if not targetSource or not gradeId then return { success = false, message = "Cette cible n'est pas valide" } end

    local xTarget = IL.Player(targetSource)
    if not xTarget then return { success = false, message = "Joueur introuvable" } end
    if targetPermId and xTarget.identifier ~= targetPermId then
        return { success = false, message = "Joueur introuvable" }
    end
    if IL.FactionName(xTarget) == factionName then
        return { success = false, message = "Ce joueur est deja membre" }
    end

    local grades = GradeList(factionName)
    local targetGrade = nil
    for i = 1, #grades do
        if grades[i].id == gradeId then targetGrade = grades[i] end
    end
    if not targetGrade then return { success = false, message = "Ce grade n'est pas valide" } end

    local meta = EnsureMeta(factionName)
    local dbId = IL.Insert([[
        INSERT INTO faction_recruit_requests (faction_name, recruiter_perm_id, target_perm_id, grade_id, status)
        VALUES (?, ?, ?, ?, 'pending')
    ]], { factionName, xPlayer.identifier, xTarget.identifier, gradeId })

    Tablet.requestSeq = Tablet.requestSeq + 1
    local requestId = ("req_%d_%d"):format(source, Tablet.requestSeq)

    Tablet.requests[requestId] = {
        dbId = dbId,
        factionName = factionName,
        recruiter = source,
        targetIdentifier = xTarget.identifier,
        targetSource = targetSource,
        gradeId = gradeId,
        gradeLevel = targetGrade.level,
        createdAt = IL.Now(),
    }

    TriggerClientEvent("core:faction-tablet:recruitmentRequest", targetSource, {
        requestId = requestId,
        recruiterName = xPlayer.name,
        factionLabel = IL.FactionLabel(xPlayer),
        factionColor = meta.color or "#e53935",
        factionLogo = meta.logo or "",
        gradeName = targetGrade.name,
    })

    return { success = true, message = "Demande envoyee" }
end)

IL.RegisterCallback("core:faction-tablet:respondRecruitment", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local requestId = data.requestId
    if requestId == nil then return { success = false, message = "Demande introuvable" } end

    local request = Tablet.requests[requestId]
    if not request or request.targetIdentifier ~= xPlayer.identifier then
        return { success = false, message = "Demande introuvable ou expiree" }
    end

    Tablet.requests[requestId] = nil

    if data.accepted ~= true then
        IL.Execute("UPDATE faction_recruit_requests SET status = 'declined' WHERE id = ?", { request.dbId })
        if IL.Player(request.recruiter) then
            IL.Notify(request.recruiter, "ILLEGAL", ("%s a refuse votre invitation."):format(xPlayer.name))
        end
        return { success = true, message = "Invitation refusee" }
    end

    IL.Execute("UPDATE faction_recruit_requests SET status = 'accepted' WHERE id = ?", { request.dbId })
    IL.Execute("DELETE FROM faction_members WHERE identifier = ?", { xPlayer.identifier })
    IL.Execute([[
        INSERT INTO faction_members (faction_name, identifier, name, grade_level, joined_at, last_seen)
        VALUES (?, ?, ?, ?, NOW(), NOW())
    ]], { request.factionName, xPlayer.identifier, xPlayer.name, request.gradeLevel })

    IL.Execute("UPDATE characters SET faction = ? WHERE identifier = ?", { request.factionName, xPlayer.identifier })
    xPlayer.setFaction(request.factionName)

    PushUpdate(request.factionName)
    return { success = true, message = "Vous avez rejoint l'organisation" }
end)

local function ChangeGrade(source, permId, delta, absoluteLevel)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end

    local permission = absoluteLevel ~= nil and "canManageGrades" or (delta > 0 and "canPromote" or "canDemote")
    if not HasPerm(factionName, xPlayer, permission) then
        return { success = false, message = "Permission refusee" }
    end

    local member = MemberRow(factionName, permId)
    if not member then return { success = false, message = "Membre introuvable" } end

    local grades = GradeList(factionName)
    local myGrade = MyGrade(factionName, xPlayer)
    local currentLevel = IL.Int(member.grade_level, 0)

    if myGrade and currentLevel >= myGrade.level and member.identifier ~= xPlayer.identifier then
        return { success = false, message = "Vous ne pouvez pas gerer ce membre" }
    end

    local targetLevel
    if absoluteLevel ~= nil then
        targetLevel = absoluteLevel
    else
        local sorted = {}
        for i = 1, #grades do sorted[#sorted + 1] = grades[i].level end
        table.sort(sorted)
        local index = nil
        for i = 1, #sorted do
            if sorted[i] == currentLevel then
                index = i
                break
            end
        end
        if not index then return { success = false, message = "Grade introuvable" } end
        local newIndex = index + delta
        if newIndex < 1 or newIndex > #sorted then
            return { success = false, message = "Grade limite atteint" }
        end
        targetLevel = sorted[newIndex]
    end

    local exists = false
    for i = 1, #grades do
        if grades[i].level == targetLevel then exists = true end
    end
    if not exists then return { success = false, message = "Ce grade n'est pas valide" } end

    if myGrade and targetLevel >= myGrade.level and member.identifier ~= xPlayer.identifier then
        return { success = false, message = "Vous ne pouvez pas donner ce grade" }
    end

    IL.Execute("UPDATE faction_members SET grade_level = ? WHERE id = ?", { targetLevel, member.id })
    PushUpdate(factionName)
    return { success = true, message = "Grade mis a jour" }
end

IL.RegisterCallback("core:faction-tablet:promote", function(source, data)
    if not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end
    local permId = IL.Str(data.permId, nil)
    if not permId then return { success = false, message = "Ce membre n'est pas valide" } end
    return ChangeGrade(source, permId, 1, nil)
end)

IL.RegisterCallback("core:faction-tablet:demote", function(source, data)
    if not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end
    local permId = IL.Str(data.permId, nil)
    if not permId then return { success = false, message = "Ce membre n'est pas valide" } end
    return ChangeGrade(source, permId, -1, nil)
end)

IL.RegisterCallback("core:faction-tablet:setGrade", function(source, data)
    if not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end
    local permId = IL.Str(data.permId, nil)
    local level = IL.Int(data.gradeLevel, nil)
    if not permId or not level then return { success = false, message = "Cette demande n'a pas pu être traitée" } end
    return ChangeGrade(source, permId, 0, level)
end)

IL.RegisterCallback("core:faction-tablet:kick", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canKick") then
        return { success = false, message = "Permission refusee" }
    end

    local permId = IL.Str(data.permId, nil)
    if not permId then return { success = false, message = "Ce membre n'est pas valide" } end
    if permId == xPlayer.identifier then return { success = false, message = "Vous ne pouvez pas vous exclure" } end

    local member = MemberRow(factionName, permId)
    if not member then return { success = false, message = "Membre introuvable" } end

    local myGrade = MyGrade(factionName, xPlayer)
    if myGrade and IL.Int(member.grade_level, 0) >= myGrade.level then
        return { success = false, message = "Vous ne pouvez pas exclure ce membre" }
    end

    IL.Execute("DELETE FROM faction_members WHERE id = ?", { member.id })
    IL.Execute("UPDATE characters SET faction = '' WHERE identifier = ?", { permId })

    local xTarget = OnlineByIdentifier(permId)
    if xTarget then
        xTarget.setFaction("")
        TriggerClientEvent("core:faction-tablet:forceClose", xTarget.source)
        Tablet.viewers[xTarget.source] = nil
    end

    PushUpdate(factionName)
    return { success = true, message = "Membre exclu" }
end)

IL.RegisterCallback("core:faction-tablet:updateChestConfig", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageChest") then
        return { success = false, message = "Permission refusee" }
    end

    EnsureMeta(factionName)
    IL.Execute([[
        UPDATE faction_meta SET chest_min_deposit = ?, chest_min_withdraw = ?, chest_min_history = ?
        WHERE faction_name = ?
    ]], {
        IL.Int(data.minGradeDeposit, 0),
        IL.Int(data.minGradeWithdraw, 0),
        IL.Int(data.minGradeHistory, 0),
        factionName,
    })

    PushUpdate(factionName)
    return { success = true, message = "Configuration mise a jour" }
end)

IL.RegisterCallback("core:faction-tablet:updateChestAccess", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageChest") then
        return { success = false, message = "Permission refusee" }
    end

    local chestId = IL.Str(data.id, nil)
    local kind = IL.Str(data.type, nil)
    local newGrade = IL.Int(data.newGrade, nil)
    if not chestId or not kind or not newGrade then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local column
    if kind == "take" or kind == "withdraw" then
        column = "grade_min_take"
    elseif kind == "put" or kind == "deposit" then
        column = "grade_min_put"
    elseif kind == "history" then
        column = "grade_min_history"
    else
        return { success = false, message = "Ce type n'est pas valide" }
    end

    IL.Execute(("UPDATE faction_chests SET %s = ? WHERE id = ? AND faction_name = ?"):format(column), {
        newGrade, chestId, factionName,
    })

    PushUpdate(factionName)
    return { success = true, message = "Acces mis a jour" }
end)

IL.RegisterCallback("core:faction-tablet:updateGradePermissions", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageGrades") then
        return { success = false, message = "Permission refusee" }
    end

    local gradeId = IL.Int(data.gradeId, nil)
    if not gradeId then return { success = false, message = "Ce grade n'est pas valide" } end

    local row = IL.Single("SELECT * FROM faction_grades WHERE id = ? AND faction_name = ?", { gradeId, factionName })
    if not row then return { success = false, message = "Grade introuvable" } end

    local permissions = NormalizePermissions(data.permissions, IL.Int(row.level, 0) >= 10)
    IL.Execute("UPDATE faction_grades SET permissions = ? WHERE id = ?", { IL.Encode(permissions), gradeId })

    PushUpdate(factionName)
    return { success = true, message = "Permissions mises a jour" }
end)

IL.RegisterCallback("core:faction-tablet:createGrade", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageGrades") then
        return { success = false, message = "Permission refusee" }
    end

    local name = IL.Str(data.name, nil)
    local level = IL.Int(data.level, nil)
    if not name or name == "" or not level then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local myGrade = MyGrade(factionName, xPlayer)
    if myGrade and level >= myGrade.level then
        return { success = false, message = "Niveau trop eleve" }
    end

    local existing = IL.Single("SELECT id FROM faction_grades WHERE faction_name = ? AND level = ?", { factionName, level })
    if existing then return { success = false, message = "Ce niveau existe deja" } end

    IL.Execute([[
        INSERT INTO faction_grades (faction_name, name, level, color, permissions)
        VALUES (?, ?, ?, '#9e9e9e', ?)
    ]], { factionName, name, level, IL.Encode(DefaultPermissions(false)) })

    PushUpdate(factionName)
    return { success = true, message = "Grade cree" }
end)

IL.RegisterCallback("core:faction-tablet:deleteGrade", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageGrades") then
        return { success = false, message = "Permission refusee" }
    end

    local level = IL.Int(data.gradeLevel, nil)
    if not level then return { success = false, message = "Ce grade n'est pas valide" } end

    local grades = GradeList(factionName)
    if #grades <= 1 then return { success = false, message = "Impossible de supprimer le dernier grade" } end

    local used = IL.Single("SELECT id FROM faction_members WHERE faction_name = ? AND grade_level = ? LIMIT 1", { factionName, level })
    if used then return { success = false, message = "Des membres utilisent ce grade" } end

    IL.Execute("DELETE FROM faction_grades WHERE faction_name = ? AND level = ?", { factionName, level })
    PushUpdate(factionName)
    return { success = true, message = "Grade supprime" }
end)

IL.RegisterCallback("core:faction-tablet:renameGrade", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageGrades") then
        return { success = false, message = "Permission refusee" }
    end

    local level = IL.Int(data.gradeLevel, nil)
    local newName = IL.Str(data.newName, nil)
    if not level or not newName or newName == "" then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    IL.Execute("UPDATE faction_grades SET name = ? WHERE faction_name = ? AND level = ?", { newName, factionName, level })
    PushUpdate(factionName)
    return { success = true, message = "Grade renomme" }
end)

IL.RegisterCallback("nui:faction-tablet:swapGradeLevels", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageGrades") then
        return { success = false, message = "Permission refusee" }
    end

    local grade1Id = IL.Int(data.grade1Id, nil)
    local grade1Level = IL.Int(data.grade1NewLevel, nil)
    local grade2Id = IL.Int(data.grade2Id, nil)
    local grade2Level = IL.Int(data.grade2NewLevel, nil)
    if not grade1Id or not grade1Level or not grade2Id or not grade2Level then
        return { success = false, message = "Cette demande n'a pas pu être traitée" }
    end

    local row1 = IL.Single("SELECT * FROM faction_grades WHERE id = ? AND faction_name = ?", { grade1Id, factionName })
    local row2 = IL.Single("SELECT * FROM faction_grades WHERE id = ? AND faction_name = ?", { grade2Id, factionName })
    if not row1 or not row2 then return { success = false, message = "Grade introuvable" } end

    IL.Execute("UPDATE faction_grades SET level = ? WHERE id = ?", { -1, grade1Id })
    IL.Execute("UPDATE faction_grades SET level = ? WHERE id = ?", { grade2Level, grade2Id })
    IL.Execute("UPDATE faction_grades SET level = ? WHERE id = ?", { grade1Level, grade1Id })

    IL.Execute("UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = ?", {
        grade1Level, factionName, IL.Int(row1.level, 0),
    })
    IL.Execute("UPDATE faction_members SET grade_level = ? WHERE faction_name = ? AND grade_level = ?", {
        grade2Level, factionName, IL.Int(row2.level, 0),
    })

    PushUpdate(factionName)
    return { success = true, message = "Grades reorganises" }
end)

IL.RegisterCallback("core:faction-tablet:updateMotto", function(source, data)
    local xPlayer = IL.Player(source)
    if not xPlayer or not IL.IsTable(data) then return { success = false, message = "Cette demande n'a pas pu être traitée" } end

    local factionName = IL.FactionName(xPlayer)
    if factionName == "" then return { success = false, message = "Aucune organisation" } end
    if not HasPerm(factionName, xPlayer, "canManageGrades") then
        return { success = false, message = "Permission refusee" }
    end

    local motto = IL.Str(data.motto, "")
    if #motto > 255 then motto = motto:sub(1, 255) end

    EnsureMeta(factionName)
    IL.Execute("UPDATE faction_meta SET motto = ? WHERE faction_name = ?", { motto, factionName })

    PushUpdate(factionName)
    return { success = true, message = "Devise mise a jour" }
end)
