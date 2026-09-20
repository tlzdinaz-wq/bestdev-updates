local RANK_NAMES = { "chef", "souschef", "soldat", "membre", "recrue" }
local RANK_LABELS = { "Chef", "Sous-chef", "Soldat", "Membre", "Recrue" }

local CREW_PERMS = {
    "recruit", "promote", "demote", "kick", "manage_permissions",
    "manage_crew", "orders", "manage_property", "manage_garage",
}

local DEFAULT_PERMS = {
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

local RANK_TIERS = {
    { rank = "D", xp = 0 },
    { rank = "C", xp = 1000 },
    { rank = "B", xp = 20000 },
    { rank = "A", xp = 75000 },
    { rank = "S", xp = 200000 },
}

local ACTIVITIES = { "drugs_sell", "heist", "drugs_production", "kill" }
local INVITE_TTL = 30

local invites = {}

local Fac = {}

function Fac.EmptyPerms()
    local out = {}
    for i = 1, #RANK_NAMES do
        local name = RANK_NAMES[i]
        out[name] = {}
        for j = 1, #CREW_PERMS do
            out[name][CREW_PERMS[j]] = DEFAULT_PERMS[name][CREW_PERMS[j]] == true
        end
    end
    return out
end

function Fac.GetCrew(crewName)
    if not Staff29.IsString(crewName, 60) then return nil end
    if crewName == "nocrew" or crewName == "nofaction" then return nil end
    return Staff29.Single("SELECT * FROM crews WHERE name = ?", { crewName })
end

function Fac.GetPerms(crewName)
    local perms = Fac.EmptyPerms()
    if not crewName then return perms end

    local rows = Staff29.Query("SELECT grade_name, permissions FROM crew_permissions WHERE crew_name = ?", { crewName })
    for i = 1, #rows do
        local row = rows[i]
        local decoded = Staff29.Decode(row.permissions, nil)
        if type(decoded) == "table" and perms[row.grade_name] then
            for j = 1, #CREW_PERMS do
                local key = CREW_PERMS[j]
                if decoded[key] ~= nil then
                    perms[row.grade_name][key] = decoded[key] == true
                end
            end
        end
    end

    return perms
end

function Fac.GetMember(crewName, identifier)
    if not crewName or not identifier then return nil end
    return Staff29.Single("SELECT * FROM crew_members WHERE crew_name = ? AND identifier = ?",
        { crewName, identifier })
end

function Fac.GetRank(crewName, identifier)
    local member = Fac.GetMember(crewName, identifier)
    local rank = member and tonumber(member.rank) or 5
    if rank < 1 then rank = 1 end
    if rank > 5 then rank = 5 end
    return rank
end

function Fac.RankName(rank)
    return RANK_NAMES[rank] or "recrue"
end

function Fac.Build(identifier)
    local member = Staff29.Single("SELECT * FROM crew_members WHERE identifier = ? LIMIT 1", { identifier })
    if not member then
        return {
            name = "nocrew",
            label = "Aucune faction",
            type = "crew",
            devise = "",
            place = 2,
            xp = 0,
            rank = 5,
            grade = 5,
            grade_name = "recrue",
            grade_label = "Recrue",
            permissions = Fac.EmptyPerms(),
        }
    end

    local crew = Fac.GetCrew(member.crew_name)
    local rank = tonumber(member.rank) or 5
    if rank < 1 then rank = 1 end
    if rank > 5 then rank = 5 end

    return {
        name = member.crew_name,
        label = crew and crew.label or member.crew_name,
        type = crew and crew.type or "crew",
        activity = crew and crew.activity or "",
        devise = crew and crew.devise or "",
        place = crew and tonumber(crew.place) or 2,
        xp = crew and tonumber(crew.xp) or 0,
        color = crew and crew.color or "#FFFFFF",
        rank = rank,
        grade = rank,
        grade_name = RANK_NAMES[rank],
        grade_label = RANK_LABELS[rank],
        permissions = Fac.GetPerms(member.crew_name),
    }
end

function Fac.Push(xPlayer)
    if not xPlayer then return end
    local data = Fac.Build(xPlayer.identifier)
    xPlayer.faction = data.name ~= "nocrew" and data.name or ""
    xPlayer.triggerEvent("vfw:updatePlayerData", "faction", data)
    xPlayer.triggerEvent("vfw:setFaction", data)
    return data
end

function Fac.PushCrew(crewName)
    if not crewName then return end
    for _, xPlayer in pairs(VFW.Players) do
        if xPlayer.faction == crewName then
            Fac.Push(xPlayer)
        end
    end
end

function Fac.BroadcastUpdate(crewName)
    local crew = Fac.GetCrew(crewName)
    if not crew then return end
    TriggerClientEvent("core:faction:updateFaction", -1, crewName, {
        xp = tonumber(crew.xp) or 0,
        devise = crew.devise or "",
    })
end

function Fac.RankLetter(xp)
    xp = tonumber(xp) or 0
    local rank, nextTarget = "D", RANK_TIERS[2].xp

    for i = 1, #RANK_TIERS do
        if xp >= RANK_TIERS[i].xp then
            rank = RANK_TIERS[i].rank
            nextTarget = RANK_TIERS[i + 1] and RANK_TIERS[i + 1].xp or nil
        end
    end

    local percentage = 100
    if nextTarget and nextTarget > 0 then
        percentage = (xp / nextTarget) * 100
        if percentage > 100 then percentage = 100 end
    end

    return rank, percentage
end

Staff29.Factions = Fac

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    Fac.Push(xPlayer)
end)

Staff29.Cb("core:faction:getCrewInfosForRadial", function(source, crewName)
    local crew = Fac.GetCrew(crewName)
    if not crew then return 0 end
    return tonumber(crew.xp) or 0
end)

Staff29.Cb("core:faction:requestCraftPosition", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local crew = Fac.GetCrew(xPlayer.faction)
    if not crew then return nil end

    local pos = Staff29.Vec(Staff29.Decode(crew.craft_pos, nil))
    if not pos then return nil end
    return pos
end)

Staff29.Cb("core:faction:getMyCraftItems", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not Staff29.IsString(xPlayer.faction, 60) then return {} end

    local rank = Fac.GetRank(xPlayer.faction, xPlayer.identifier)
    local rows = Staff29.Query(
        "SELECT recipe, min_rank FROM crew_craft_recipes WHERE crew_name = ?", { xPlayer.faction })

    local out, n = {}, 0
    for i = 1, #rows do
        local minRank = tonumber(rows[i].min_rank) or 5
        if rank <= minRank then
            local decoded = Staff29.Decode(rows[i].recipe, nil)
            if type(decoded) == "table" and type(decoded.recipe) == "table" then
                n = n + 1
                out[n] = decoded
            end
        end
    end

    return out
end)

Staff29.Cb("core:faction:getClonePed", function(source, factionName)
    local crew = Fac.GetCrew(factionName)
    if not crew then return nil, nil, nil, nil end

    local members = Staff29.Query(
        "SELECT identifier FROM crew_members WHERE crew_name = ? ORDER BY rank ASC, joined_at ASC LIMIT 2",
        { factionName })

    local skins, tattoos = {}, {}
    for i = 1, #members do
        local row = Staff29.Single(
            "SELECT skin, tattoos FROM characters WHERE identifier = ? AND deleted_at IS NULL",
            { members[i].identifier })
        skins[i] = row and Staff29.Decode(row.skin, nil) or nil
        tattoos[i] = row and Staff29.Decode(row.tattoos, {}) or {}
    end

    return skins[1], tattoos[1], skins[2], tattoos[2]
end)

Staff29.Cb("core:crew:getInfos", function(source, crewName)
    local xPlayer = VFW.GetPlayerFromId(source)
    local crew = Fac.GetCrew(crewName)

    if not xPlayer or not crew or xPlayer.faction ~= crewName then
        return { perms = Fac.EmptyPerms(), devise = "", place = 2, members = {}, activities = {} }
    end

    local rows = Staff29.Query([[
        SELECT m.identifier, m.rank, m.xp, m.role, m.seniority, m.status, m.joined_at,
               c.firstname, c.lastname, c.mugshot, c.account_id
        FROM crew_members m
        LEFT JOIN characters c ON c.identifier = m.identifier
        WHERE m.crew_name = ? ORDER BY m.rank ASC
    ]], { crewName })

    local members, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local playTime = Staff29.Scalar("SELECT playtime FROM users WHERE id = ?", { row.account_id }, 0) or 0
        n = n + 1
        members[n] = {
            identifier = row.identifier,
            fname = row.firstname or "",
            lname = row.lastname or "",
            playTime = tonumber(playTime) or 0,
            xp = tonumber(row.xp) or 0,
            rank = tonumber(row.rank) or 5,
            mugshot = row.mugshot or "",
            role = row.role or RANK_LABELS[tonumber(row.rank) or 5] or "Recrue",
            seniority = tostring(row.joined_at or row.seniority or ""),
            status = row.status or "offline",
        }
        if VFW.GetPlayerFromIdentifier(row.identifier) then
            members[n].status = "online"
        end
    end

    local activityRows = Staff29.Query(
        "SELECT identifier, activity, score FROM crew_activities WHERE crew_name = ?", { crewName })

    local activities = {}
    for i = 1, #members do
        activities[members[i].identifier] = {}
        for j = 1, #ACTIVITIES do
            activities[members[i].identifier][ACTIVITIES[j]] = 0
        end
    end
    for i = 1, #activityRows do
        local row = activityRows[i]
        activities[row.identifier] = activities[row.identifier] or {}
        activities[row.identifier][row.activity] = tonumber(row.score) or 0
    end

    return {
        perms = Fac.GetPerms(crewName),
        devise = crew.devise or "",
        place = tonumber(crew.place) or 2,
        members = members,
        activities = activities,
    }
end)

Staff29.Cb("core:crew:getNumberOfTerritories", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return 0 end

    local count = tonumber(Staff29.Scalar(
        "SELECT COUNT(*) FROM faction_territories WHERE owner_crew = ?", { xPlayer.faction }, 0)) or 0
    if count == 0 then
        count = tonumber(Staff29.Scalar(
            "SELECT COUNT(*) FROM faction_territories WHERE owner = ?", { xPlayer.faction }, 0)) or 0
    end
    return count
end)

Staff29.Cb("core:crew:getProperties", function(source, crewName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction ~= crewName then return {} end
    return Staff29.Query("SELECT * FROM crew_properties WHERE crew_name = ?", { crewName })
end)

Staff29.Cb("core:crew:getVehicles", function(source, crewName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction ~= crewName then return {} end
    return Staff29.Query("SELECT * FROM crew_vehicles WHERE crew_name = ?", { crewName })
end)

Staff29.Cb("core:crew:getTerritories", function(source, crewName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction ~= crewName then return {} end

    local rows = Staff29.Query("SELECT * FROM faction_territories WHERE owner_crew = ?", { crewName })
    if #rows == 0 then
        rows = Staff29.Query("SELECT * FROM faction_territories WHERE owner = ?", { crewName })
    end

    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            id = row.id,
            name = row.name or "",
            polygon = Staff29.Decode(row.polygon, {}),
            display_number = tonumber(row.display_number) or n,
            display_color = row.display_color or "#FFFFFF",
        }
    end
    return out
end)

Staff29.Cb("core:crew:getFactionInfluence", function(source, crewName)
    local crew = Fac.GetCrew(crewName)
    if not crew then return 0 end
    return tonumber(crew.influence) or 0
end)

Staff29.Cb("core:crew:getFactionRank", function(source, crewName)
    local crew = Fac.GetCrew(crewName)
    if not crew then return "D", 0 end
    return Fac.RankLetter(crew.xp)
end)

Staff29.Cb("core:faction:requestMemberCam", function(source, identifier)
    if not Staff29.IsString(identifier, 80) then return nil, {} end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return nil, {} end

    local member = Fac.GetMember(xPlayer.faction, identifier)
    if not member then return nil, {} end

    local row = Staff29.Single(
        "SELECT skin, tattoos FROM characters WHERE identifier = ? AND deleted_at IS NULL", { identifier })
    if not row then return nil, {} end

    return Staff29.Decode(row.skin, nil), Staff29.Decode(row.tattoos, {})
end)

Staff29.Cb("core:factions:canCreateCrew", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if xPlayer.hasPermission("gestion_faction") then return true end
    local enabled = VFW.Variables.GetVariable("crew_creation_enabled")
    return enabled == true
end)

Staff29.Cb("core:orga:updateRole", function(source, orgaType, currentRole, isPromoted, targetIdentifier)
    if not Staff29.IsString(targetIdentifier, 80) then return false, currentRole, "Cette cible n'est pas valide" end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return false, currentRole, "Vous n'avez pas de faction" end

    local crewName = xPlayer.faction
    local member = Fac.GetMember(crewName, targetIdentifier)
    if not member then return false, currentRole, "Membre introuvable" end

    local myRank = Fac.GetRank(crewName, xPlayer.identifier)
    local perms = Fac.GetPerms(crewName)
    local myPerms = perms[Fac.RankName(myRank)] or {}

    local permission = isPromoted and "promote" or "demote"
    if not myPerms[permission] then return false, currentRole, "Permission insuffisante" end

    local targetRank = tonumber(member.rank) or 5
    if targetRank <= myRank and xPlayer.identifier ~= targetIdentifier then
        return false, currentRole, "Vous ne pouvez pas modifier ce membre"
    end

    local newRank = isPromoted and (targetRank - 1) or (targetRank + 1)
    if newRank < 1 then return false, currentRole, "Rang maximum atteint" end
    if newRank > 5 then return false, currentRole, "Rang minimum atteint" end
    if newRank <= myRank and myRank ~= 1 then return false, currentRole, "Rang trop élevé" end

    Staff29.Update("UPDATE crew_members SET rank = ?, role = ? WHERE crew_name = ? AND identifier = ?",
        { newRank, RANK_LABELS[newRank], crewName, targetIdentifier })

    local online = VFW.GetPlayerFromIdentifier(targetIdentifier)
    if online then Fac.Push(online) end

    return true, newRank, "Rang mis à jour"
end)

RegisterNetEvent("core:faction:leavemyCrew", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return end

    local crewName = xPlayer.faction
    local rank = Fac.GetRank(crewName, xPlayer.identifier)

    if rank == 1 then
        local others = Staff29.Scalar(
            "SELECT COUNT(*) FROM crew_members WHERE crew_name = ? AND identifier <> ?",
            { crewName, xPlayer.identifier }, 0) or 0
        if others > 0 then
            xPlayer.showNotification({
                type = "STAFF", variant = "ERROR", subtitle = "Faction",
                message = "Le chef ne peut pas quitter une faction qui a encore des membres.",
            })
            return
        end
    end

    Staff29.Update("DELETE FROM crew_members WHERE crew_name = ? AND identifier = ?", { crewName, xPlayer.identifier })
    Staff29.Update("DELETE FROM crew_activities WHERE crew_name = ? AND identifier = ?",
        { crewName, xPlayer.identifier })

    Fac.Push(xPlayer)
    TriggerClientEvent("core:UpdateCrewCount", source, crewName, false)
end)

RegisterNetEvent("core:faction:invitePlayer", function(idS)
    local source = source
    local targetId = Staff29.ToInt(idS, 1, 1024)
    if not targetId then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return end

    local crewName = xPlayer.faction
    local rank = Fac.GetRank(crewName, xPlayer.identifier)
    local perms = Fac.GetPerms(crewName)

    if not (perms[Fac.RankName(rank)] or {}).recruit then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Vous n'avez pas le droit de recruter.",
        })
        return
    end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return end
    if target.source == source then return end
    if target.faction ~= "" then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Ce joueur appartient déjà à une faction.",
        })
        return
    end
    if not Staff29.Distance(source, targetId, 6.0) then return end

    local crew = Fac.GetCrew(crewName)
    if not crew then return end

    invites[target.identifier] = {
        crewName = crewName,
        inviter = xPlayer.identifier,
        inviterSource = source,
        expiresAt = os.time() + INVITE_TTL,
    }

    target.triggerEvent("core:faction:invitePlayer", crewName, crew.label or crewName, source, crew.image)
end)

RegisterNetEvent("core:faction:acceptInvite", function(name, src)
    local source = source
    if not Staff29.IsString(name, 60) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if xPlayer.faction ~= "" then return end

    local invite = invites[xPlayer.identifier]
    if not invite or invite.crewName ~= name then return end
    if os.time() > invite.expiresAt then
        invites[xPlayer.identifier] = nil
        return
    end

    invites[xPlayer.identifier] = nil

    local crew = Fac.GetCrew(name)
    if not crew then return end

    Staff29.Update([[
        INSERT INTO crew_members (crew_name, identifier, rank, xp, role, seniority, status, joined_at)
        VALUES (?, ?, 5, 0, ?, ?, 'online', ?)
        ON DUPLICATE KEY UPDATE rank = VALUES(rank)
    ]], { name, xPlayer.identifier, RANK_LABELS[5], Staff29.Now(), Staff29.Now() })

    Fac.Push(xPlayer)
    Fac.PushCrew(name)
    TriggerClientEvent("core:UpdateCrewCount", source, name, true)

    local inviter = VFW.GetPlayerFromId(tonumber(src) or invite.inviterSource)
    if inviter then
        inviter.showNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "Faction",
            message = ("%s a rejoint la faction."):format(xPlayer.name),
        })
    end
end)

RegisterNetEvent("core:factions:askCreationCrew", function(name, hierarchie, crewBdd, devise, placement)
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local cleanName = Staff29.Clean(name, 40)
    local cleanDevise = Staff29.Clean(devise, 120) or ""
    local activity = Staff29.Clean(crewBdd, 40)

    if not cleanName or cleanName == "" or not activity then return end
    if not Staff29.IsString(hierarchie, 60) then return end

    if not xPlayer.hasPermission("gestion_faction") then
        local allowed = VFW.Variables.GetVariable("crew_creation_enabled")
        if allowed ~= true then
            xPlayer.showNotification({
                type = "STAFF", variant = "ERROR", subtitle = "Faction",
                message = "La création de factions est désactivée.",
            })
            return
        end
    end

    if xPlayer.faction ~= "" then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Vous appartenez déjà à une faction.",
        })
        return
    end

    local orgaType = "crew"
    local typeTable = VFW.Factions and VFW.Factions[orgaType]
    if typeTable and typeTable.Types and not typeTable.Types[activity] then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Ce type d'organisation n'est pas valide.",
        })
        return
    end

    local internalName = cleanName:lower():gsub("[^%w]", "_"):sub(1, 40)
    if internalName == "" then return end

    local exists = Staff29.Scalar("SELECT COUNT(*) FROM crews WHERE name = ?", { internalName }, 0) or 0
    if exists > 0 then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Ce nom de faction est déjà pris.",
        })
        return
    end

    local place = 2
    if type(placement) == "number" then
        place = math.floor(placement)
    elseif type(placement) == "string" then
        for i = 1, #(VFW.Factions and VFW.Factions.Placement or {}) do
            if VFW.Factions.Placement[i] == placement then place = i end
        end
    end

    Staff29.Insert([[
        INSERT INTO crews (name, label, type, activity, hierarchie, devise, place, xp, influence, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?)
    ]], { internalName, cleanName, orgaType, activity, hierarchie, cleanDevise, place, Staff29.Now() })

    for i = 1, #RANK_NAMES do
        Staff29.Update([[
            INSERT INTO crew_permissions (crew_name, grade_name, permissions) VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
        ]], { internalName, RANK_NAMES[i], Staff29.Encode(DEFAULT_PERMS[RANK_NAMES[i]]) })
    end

    Staff29.Update([[
        INSERT INTO crew_members (crew_name, identifier, rank, xp, role, seniority, status, joined_at)
        VALUES (?, ?, 1, 0, ?, ?, 'online', ?)
        ON DUPLICATE KEY UPDATE crew_name = VALUES(crew_name), rank = 1
    ]], { internalName, xPlayer.identifier, RANK_LABELS[1], Staff29.Now(), Staff29.Now() })

    Fac.Push(xPlayer)
    TriggerClientEvent("core:UpdateCrewCount", source, internalName, true)

    xPlayer.showNotification({
        type = "STAFF", variant = "SUCCESS", subtitle = "Faction",
        message = ("La faction %s a été créée."):format(cleanName),
    })
end)

RegisterNetEvent("core:faction:update", function(updateType, name, devise, place)
    local source = source

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return end

    local crewName = xPlayer.faction
    local rank = Fac.GetRank(crewName, xPlayer.identifier)
    local perms = Fac.GetPerms(crewName)
    if not (perms[Fac.RankName(rank)] or {}).manage_crew then return end

    if updateType == nil or type(updateType) ~= "string" then updateType = "all" end

    if (updateType == "all" or updateType == "name") and Staff29.IsString(name, 40) then
        Staff29.Update("UPDATE crews SET label = ? WHERE name = ?", { Staff29.Clean(name, 40), crewName })
    end

    if (updateType == "all" or updateType == "devise") and type(devise) == "string" then
        Staff29.Update("UPDATE crews SET devise = ? WHERE name = ?", { Staff29.Clean(devise, 120) or "", crewName })
    end

    if updateType == "all" or updateType == "place" then
        local placeId = Staff29.ToInt(place, 1, 10)
        if placeId then
            Staff29.Update("UPDATE crews SET place = ? WHERE name = ?", { placeId, crewName })
        end
    end

    Fac.PushCrew(crewName)
    Fac.BroadcastUpdate(crewName)
end)

RegisterNetEvent("core:crew:getPlayerInfo", function(_token, crewName, playerId)
    local source = source
    if not Staff29.IsString(crewName, 60) or not Staff29.IsString(playerId, 80) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction ~= crewName then return end

    local member = Fac.GetMember(crewName, playerId)
    if not member then return end

    local row = Staff29.Single(
        "SELECT firstname, lastname, mugshot FROM characters WHERE identifier = ?", { playerId })

    xPlayer.triggerEvent("core:crew:playerInfo", {
        identifier = playerId,
        crewName = crewName,
        rank = tonumber(member.rank) or 5,
        role = member.role or "",
        xp = tonumber(member.xp) or 0,
        fname = row and row.firstname or "",
        lname = row and row.lastname or "",
        mugshot = row and row.mugshot or "",
    })
end)

RegisterNetEvent("core:crew:changePlayerRankInCrew", function(_token, crewName, playerId, newRank)
    local source = source
    if not Staff29.IsString(crewName, 60) or not Staff29.IsString(playerId, 80) then return end

    local rank = Staff29.ToInt(newRank, 1, 5)
    if not rank then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction ~= crewName then return end

    local member = Fac.GetMember(crewName, playerId)
    if not member then return end

    local currentRank = tonumber(member.rank) or 5
    local myRank = Fac.GetRank(crewName, xPlayer.identifier)
    local perms = Fac.GetPerms(crewName)
    local myPerms = perms[Fac.RankName(myRank)] or {}

    local permission = rank < currentRank and "promote" or "demote"
    if not myPerms[permission] then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Vous n'avez pas les permissions pour faire cela.",
        })
        return
    end

    if currentRank <= myRank or rank <= myRank then
        if myRank ~= 1 then
            xPlayer.showNotification({
                type = "STAFF", variant = "ERROR", subtitle = "Faction",
                message = "Rang cible trop élevé.",
            })
            return
        end
    end

    if rank == 1 and myRank ~= 1 then return end

    Staff29.Update("UPDATE crew_members SET rank = ?, role = ? WHERE crew_name = ? AND identifier = ?",
        { rank, RANK_LABELS[rank], crewName, playerId })

    local online = VFW.GetPlayerFromIdentifier(playerId)
    if online then Fac.Push(online) end
end)

RegisterNetEvent("core:crew:removePlayerFromCrew", function(_token, crewName, playerId, license)
    local source = source
    if Staff29.EventBlocked("core:crew:removePlayerFromCrew", source) then return end
    if not Staff29.IsString(crewName, 60) then return end

    local identifier = Staff29.IsString(playerId, 80) and playerId or license
    if not Staff29.IsString(identifier, 80) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction ~= crewName then return end
    if identifier == xPlayer.identifier then return end

    local member = Fac.GetMember(crewName, identifier)
    if not member then return end

    local myRank = Fac.GetRank(crewName, xPlayer.identifier)
    local perms = Fac.GetPerms(crewName)
    if not (perms[Fac.RankName(myRank)] or {}).kick then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Vous n'avez pas les permissions pour faire cela.",
        })
        return
    end

    if (tonumber(member.rank) or 5) <= myRank then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Vous ne pouvez pas exclure ce membre.",
        })
        return
    end

    Staff29.Update("DELETE FROM crew_members WHERE crew_name = ? AND identifier = ?", { crewName, identifier })
    Staff29.Update("DELETE FROM crew_activities WHERE crew_name = ? AND identifier = ?", { crewName, identifier })

    local online = VFW.GetPlayerFromIdentifier(identifier)
    if online then
        Fac.Push(online)
        online.showNotification({
            type = "STAFF", variant = "WARNING", subtitle = "Faction",
            message = "Vous avez été exclu de votre faction.",
        })
        TriggerClientEvent("core:UpdateCrewCount", online.source, crewName, false)
    end

    Fac.PushCrew(crewName)
end)

RegisterNetEvent("core:orga:savePermissions", function(orgaType, data, grade)
    local source = source
    if not Staff29.IsTable(data) or not Staff29.IsString(grade, 20) then return end

    local gradeName = grade:lower()
    local valid = false
    for i = 1, #RANK_NAMES do
        if RANK_NAMES[i] == gradeName then valid = true break end
    end
    if not valid then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or xPlayer.faction == "" then return end

    local crewName = xPlayer.faction
    local myRank = Fac.GetRank(crewName, xPlayer.identifier)
    local perms = Fac.GetPerms(crewName)

    if not (perms[Fac.RankName(myRank)] or {}).manage_permissions then
        xPlayer.showNotification({
            type = "STAFF", variant = "ERROR", subtitle = "Faction",
            message = "Vous n'avez pas les permissions pour faire cela.",
        })
        return
    end

    local newGradePerms = {}
    for i = 1, #CREW_PERMS do
        local key = CREW_PERMS[i]
        if data[key] ~= nil then
            newGradePerms[key] = data[key] == true
        else
            newGradePerms[key] = perms[gradeName][key] == true
        end
    end

    if gradeName == "chef" then
        newGradePerms.manage_permissions = true
    end

    Staff29.Update([[
        INSERT INTO crew_permissions (crew_name, grade_name, permissions) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
    ]], { crewName, gradeName, Staff29.Encode(newGradePerms) })

    local updated = Fac.GetPerms(crewName)
    for _, player in pairs(VFW.Players) do
        if player.faction == crewName then
            player.triggerEvent("core:crew:updatePerms", updated)
        end
    end
end)

AddEventHandler("vfw:playerDropped", function(source, xPlayer)
    if xPlayer and xPlayer.identifier then
        invites[xPlayer.identifier] = nil
    end
end)
