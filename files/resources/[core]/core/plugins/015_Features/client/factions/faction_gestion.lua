---@meta _
---@diagnostic disable: duplicate-doc-field

local sourcePlayer, crewMembers, perms, players

local crewProperties = nil -- Get it once, too much data to process for the server
local crewVehicles = nil -- Get it once, too much data to process for the server
local crewTerritories = nil -- Get it once, too much data to process for the server

local open = false

---Set PedInInstance
local function setPedInInstance()
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local typeCrew = "gang"
    VFW.Factions.CreateCamera(VFW.Factions.CrewPlayerGestionCam[typeCrew], VFW.Factions.CrewPedsGestionCam[typeCrew])
end

CREW_ACTIVITY_TYPE = {
    ["drugs_sell"] = {
        speciality = "Dealer",
    },
    ["heist"] = {
        speciality = "Braqueur",
    },
    ["drugs_production"] = {
        speciality = "Farmeur",
    },
    ["kill"] = {
        speciality = "Kills",
    },
}

local activityLabels = {
    drugs_sell = "Vente de drogue",
    heist = "Braquage",
    drugs_production = "Production de drogue",
    kill = "Meurtre"
}

local SpecialiteFromLabel = {
    ["Vente de drogue"] = "Dealer",
    ["Braquage"] = "Braqueur",
    ["Production de drogue"] = "Farmeur",
    ["Meurtre"] = "Kill"
}

--- formatActivity
---@param activities any
function formatActivity(activities)
    local scoresByActivity = {}

    for member, acts in pairs(activities) do
        for activity, score in pairs(acts) do
            scoresByActivity[activity] = scoresByActivity[activity] or {}
            table.insert(scoresByActivity[activity], {
                member = member,
                score = score
            })
        end
    end

    -- 2. Calcul des classements
    local rankings = {} -- [activity][member] = classement

    for activity, scores in pairs(scoresByActivity) do
        table.sort(scores, function(a, b)
            return a.score > b.score
        end)

        rankings[activity] = {}
        for rank, data in ipairs(scores) do
            rankings[activity][data.member] = rank
        end
    end

    -- 3. Construire les tableaux finaux par membre
    local results = {}

    for member, acts in pairs(activities) do
        results[member] = {}

        for activity, score in pairs(acts) do
            table.insert(results[member], {
                type = "activity",
                label = activityLabels[activity] or activity,
                score = score,
                classement = rankings[activity][member] or 0
            })
        end
    end

    return results
end

---Get SpecialityByClassement
---@param classement any
function getSpecialityByClassement(classement)
    local specialite = "Inconnu"
    local maxScore = -1

    for _, activity in ipairs(classement) do
        if activity.score > maxScore then
            maxScore = activity.score
            specialite = SpecialiteFromLabel[activity.label] or "Inconnu"
        end
    end

    return specialite
end

--- formatPlaytime
---@param seconds any
---@return any
function formatPlaytime(seconds)
    if seconds == nil then
        return
    end

    seconds = tonumber(seconds) or 0

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if hours > 0 then
        return string.format("%dh %dmin", hours, minutes)
    else
        return string.format("%dmin", minutes)
    end
end

--- OpenCrewGestion
---@return any
function OpenCrewGestion()

    Wait(250)

    open = true
    VFW.Nui.Radial(nil, false)
    local playerCrew = VFW.PlayerData.faction.name
    if playerCrew == "nocrew" then
        return
    end

    local crewInfo = TriggerServerCallback("core:crew:getInfos", playerCrew)
    perms = (not crewInfo.perms and {}) or (type(crewInfo.perms) == "string" and json.decode(crewInfo.perms) or crewInfo.perms)
    local numberOfTerritories = TriggerServerCallback("core:crew:getNumberOfTerritories")
    crewProperties = TriggerServerCallback("core:crew:getProperties", playerCrew)
    crewVehicles = TriggerServerCallback("core:crew:getVehicles", playerCrew)
    crewTerritories = TriggerServerCallback("core:crew:getTerritories", playerCrew)
    local crewInfluence = TriggerServerCallback("core:crew:getFactionInfluence", playerCrew)
    crewInfo.place = crewInfo.place or 2

    local permissions = VFW.PlayerData.faction.permissions

    local formatedActivities = formatActivity(crewInfo.activities)
    local membersData = {}

    for k, v in pairs(crewInfo.members) do
        if not v.rank then
            v.rank = 1
        end

        if v.rank < 1 then
            v.rank = 1
        elseif v.rank > 5 then
            v.rank = 5
        end

        console.debug("member", json.encode(v, { indent = true }))

        local classement = formatedActivities[v.identifier] or {}
        local speciality = getSpecialityByClassement(classement)

        table.insert(classement, {
            type = "total",
            label = "Temps de jeu",
            score = formatPlaytime(v.playTime),
            classement = 1,
            playTime = v.playTime,
        })

        membersData[#membersData + 1] = {
            identifier = v.identifier,
            fname = v.fname,
            lname = v.lname,
            PlayTime = formatPlaytime(v.playTime),
            time = v.playTime,
            xp = v.xp,
            rank = v.rank,
            Information = {
                mugshot = v.mugshot,
                roles = v.role,
                seniority = v.seniority,
                speciality = speciality,
                status = v.status,
                classements = classement or {},
            }
        }
    end

    local factionRank, nextRankPercentage = TriggerServerCallback("core:crew:getFactionRank", playerCrew)
    setPedInInstance()

    console.debug("perm", json.encode(perms, { indent = true }))

    VFW.Nui.FactionGestion(true, {
        type = "crew",
        crewType = "gang",
        nextRankPercent = nextRankPercentage,
        name = playerCrew,
        label = VFW.PlayerData.faction.label,
        devise = crewInfo.devise,
        colorsList = VFW.Factions.crew.Colors,
        infos = {
            { label = "Rang", value = factionRank or "D" },
            { label = "Influence", value = crewInfluence or 0 },
            { label = "Territoires", value = numberOfTerritories or 0 },
        },
        menuColor = VFW.Factions.crew.menuColor,
        permissions = {
            {
                edit = true,
                id = 1,
                fname = "Chef",
                lname = "",
                permission = {
                    {
                        fname = "Recruter un joueur",
                        idname = "recruit",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["chef"].recruit or false,
                    },
                    {
                        fname = "Promouvoir un joueur",
                        idname = "promote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["chef"].promote or false,
                    },
                    {
                        fname = "Rétrograder un joueur",
                        idname = "demote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["chef"].demote or false,
                    },
                    {
                        fname = "Exclure un joueur",
                        idname = "kick",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["chef"].kick or false,
                    },
                    {
                        fname = "Gérer les permissions",
                        idname = "manage_permissions",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["chef"].manage_permissions or false,
                    },
                    {
                        fname = "Gestion",
                        idname = "manage_crew",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["chef"].manage_crew or false,
                    },
                    {
                        fname = "Commande",
                        idname = "orders",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["chef"].orders or false,
                    },
                    {
                        fname = "Gérer les propriétés",
                        idname = "manage_property",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["chef"].manage_property or false,
                    },
                    {
                        fname = "Gérer les véhicules",
                        idname = "manage_garage",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["chef"].manage_garage or false,
                    },
                }
            },
            {
                edit = true,
                id = 1,
                fname = "Souschef",
                lname = "",
                permission = {
                    {
                        fname = "Recruter un joueur",
                        idname = "recruit",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["souschef"].recruit or false,
                    },
                    {
                        fname = "Promouvoir un joueur",
                        idname = "promote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["souschef"].promote or false,
                    },
                    {
                        fname = "Rétrograder un joueur",
                        idname = "demote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["souschef"].demote or false,
                    },
                    {
                        fname = "Exclure un joueur",
                        idname = "kick",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["souschef"].kick or false,
                    },
                    {
                        fname = "Gérer les permissions",
                        idname = "manage_permissions",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["souschef"].manage_permissions or false,
                    },
                    {
                        fname = "Gestion",
                        idname = "manage_crew",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["souschef"].manage_crew or false,
                    },
                    {
                        fname = "Commande",
                        idname = "orders",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["souschef"].orders or false,
                    },
                    {
                        fname = "Gérer les propriétés",
                        idname = "manage_property",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["souschef"].manage_property or false,
                    },
                    {
                        fname = "Gérer les véhicules",
                        idname = "manage_garage",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["souschef"].manage_garage or false,
                    },
                }
            },
            {
                edit = true,
                id = 1,
                fname = "Soldat",
                lname = "",
                permission = {
                    {
                        fname = "Recruter un joueur",
                        idname = "recruit",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["soldat"].recruit or false,
                    },
                    {
                        fname = "Promouvoir un joueur",
                        idname = "promote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["soldat"].promote or false,
                    },
                    {
                        fname = "Rétrograder un joueur",
                        idname = "demote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["soldat"].demote or false,
                    },
                    {
                        fname = "Exclure un joueur",
                        idname = "kick",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["soldat"].kick or false,
                    },
                    {
                        fname = "Gérer les permissions",
                        idname = "manage_permissions",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["soldat"].manage_permissions or false,
                    },
                    {
                        fname = "Gestion",
                        idname = "manage_crew",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["soldat"].manage_crew or false,
                    },
                    {
                        fname = "Commande",
                        idname = "orders",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["soldat"].orders or false,
                    },
                    {
                        fname = "Gérer les propriétés",
                        idname = "manage_property",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["soldat"].manage_property or false,
                    },
                    {
                        fname = "Gérer les véhicules",
                        idname = "manage_garage",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["soldat"].manage_garage or false,
                    },
                }
            },
            {
                edit = true,
                id = 1,
                fname = "Membre",
                lname = "",
                permission = {
                    {
                        fname = "Recruter un joueur",
                        idname = "recruit",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["membre"].recruit or false,
                    },
                    {
                        fname = "Promouvoir un joueur",
                        idname = "promote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["membre"].promote or false,
                    },
                    {
                        fname = "Rétrograder un joueur",
                        idname = "demote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["membre"].demote or false,
                    },
                    {
                        fname = "Exclure un joueur",
                        idname = "kick",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["membre"].kick or false,
                    },
                    {
                        fname = "Gérer les permissions",
                        idname = "manage_permissions",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["membre"].manage_permissions or false,
                    },
                    {
                        fname = "Gestion",
                        idname = "manage_crew",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["membre"].manage_crew or false,
                    },
                    {
                        fname = "Commande",
                        idname = "orders",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["membre"].orders or false,
                    },
                    {
                        fname = "Gérer les propriétés",
                        idname = "manage_property",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["membre"].manage_property or false,
                    },
                    {
                        fname = "Gérer les véhicules",
                        idname = "manage_garage",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["membre"].manage_garage or false,
                    },
                }
            },
            {
                edit = true,
                id = 1,
                fname = "Recrue",
                lname = "",
                permission = {
                    {
                        fname = "Recruter un joueur",
                        idname = "recruit",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["recrue"].recruit or false,
                    },
                    {
                        fname = "Promouvoir un joueur",
                        idname = "promote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["recrue"].promote or false,
                    },
                    {
                        fname = "Rétrograder un joueur",
                        idname = "demote",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["recrue"].demote or false,
                    },
                    {
                        fname = "Exclure un joueur",
                        idname = "kick",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["recrue"].kick or false,
                    },
                    {
                        fname = "Gérer les permissions",
                        idname = "manage_permissions",
                        lname = "",
                        id = 2,
                        IsAcces = permissions["recrue"].manage_permissions or false,
                    },
                    {
                        fname = "Gestion",
                        idname = "manage_crew",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["recrue"].manage_crew or false,
                    },
                    {
                        fname = "Commande",
                        idname = "orders",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["recrue"].orders or false,
                    },
                    {
                        fname = "Gérer les propriétés",
                        idname = "manage_property",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["recrue"].manage_property or false,
                    },
                    {
                        fname = "Gérer les véhicules",
                        idname = "manage_garage",
                        lname = "",
                        id = 3,
                        IsAcces = permissions["recrue"].manage_garage or false,
                    },
                }
            },
        },
        members = membersData,
        properties = crewProperties or {},
        vehs = crewVehicles,
        territories = crewTerritories
    })

    --VFW.Nui.FactionGestion(true, {
    --    color_title = (crewInfo.colorIndex or 1),
    --    background = crewInfo.color,
    --    crewName = playerCrew,
    --    influence = (crewInfluence or 0),
    --    crewDevise = crewInfo.devise,
    --    place = crewInfo.place,
    --    membres = #crewInfo.members,
    --    rang = (factionRank or "D"),
    --    territoires = (numberOfTerritories or 0),
    --    recrute = perms.recruit or 1,
    --    exclure = perms.kick or 1,
    --    editPerm = perms.permissions or 1,
    --    nextRankPercent = nextRankPercentage,
    --    editMembres = perms.promote or 1,
    --    --sendDm = perms.sendDm or 1,
    --    crewOrEnterprise = true,
    --    nbrRank = 5,
    --    jobLabel = "",
    --    players = (membersData or {}),
    --    properties = crewProperties or {},
    --    vehs = crewVehicles,
    --
    --    Managements = {
    --        {
    --            edit = true,
    --            id = 1,
    --            fname = "Chef",
    --            lname = "",
    --            permission = {
    --                {
    --                    fname = "Recruter un joueur",
    --                    idname = "recruit",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["chef"].recruit or false,
    --                },
    --                {
    --                    fname = "Promouvoir un joueur",
    --                    idname = "promote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["chef"].promote or false,
    --                },
    --                {
    --                    fname = "Rétrograder un joueur",
    --                    idname = "demote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["chef"].demote or false,
    --                },
    --                {
    --                    fname = "Exclure un joueur",
    --                    idname = "kick",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["chef"].kick or false,
    --                },
    --                {
    --                    fname = "Gérer les permissions",
    --                    idname = "manage_permissions",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["chef"].manage_permissions or false,
    --                },
    --                {
    --                    fname = "Gestion",
    --                    idname = "manage_crew",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["chef"].manage_crew or false,
    --                },
    --                {
    --                    fname = "Commande",
    --                    idname = "orders",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["chef"].orders or false,
    --                },
    --                {
    --                    fname = "Gérer les propriétés",
    --                    idname = "manage_property",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["chef"].manage_property or false,
    --                },
    --                {
    --                    fname = "Gérer les véhicules",
    --                    idname = "manage_garage",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["chef"].manage_garage or false,
    --                },
    --
    --            }
    --        },
    --        {
    --            edit = true,
    --            id = 1,
    --            fname = "Souschef",
    --            lname = "",
    --            permission = {
    --                {
    --                    fname = "Recruter un joueur",
    --                    idname = "recruit",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["souschef"].recruit or false,
    --                },
    --                {
    --                    fname = "Promouvoir un joueur",
    --                    idname = "promote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["souschef"].promote or false,
    --                },
    --                {
    --                    fname = "Rétrograder un joueur",
    --                    idname = "demote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["souschef"].demote or false,
    --                },
    --                {
    --                    fname = "Exclure un joueur",
    --                    idname = "kick",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["souschef"].kick or false,
    --                },
    --                {
    --                    fname = "Gérer les permissions",
    --                    idname = "manage_permissions",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["souschef"].manage_permissions or false,
    --                },
    --                {
    --                    fname = "Gestion",
    --                    idname = "manage_crew",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["souschef"].manage_crew or false,
    --                },
    --                {
    --                    fname = "Commande",
    --                    idname = "orders",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["souschef"].orders or false,
    --                },
    --                {
    --                    fname = "Gérer les propriétés",
    --                    idname = "manage_property",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["souschef"].manage_property or false,
    --                },
    --                {
    --                    fname = "Gérer les véhicules",
    --                    idname = "manage_garage",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["souschef"].manage_garage or false,
    --                },
    --            }
    --        },
    --        {
    --            edit = true,
    --            id = 1,
    --            fname = "Soldat",
    --            lname = "",
    --            permission = {
    --                {
    --                    fname = "Recruter un joueur",
    --                    idname = "recruit",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["soldat"].recruit or false,
    --                },
    --                {
    --                    fname = "Promouvoir un joueur",
    --                    idname = "promote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["soldat"].promote or false,
    --                },
    --                {
    --                    fname = "Rétrograder un joueur",
    --                    idname = "demote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["soldat"].demote or false,
    --                },
    --                {
    --                    fname = "Exclure un joueur",
    --                    idname = "kick",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["soldat"].kick or false,
    --                },
    --                {
    --                    fname = "Gérer les permissions",
    --                    idname = "manage_permissions",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["soldat"].manage_permissions or false,
    --                },
    --                {
    --                    fname = "Gestion",
    --                    idname = "manage_crew",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["soldat"].manage_crew or false,
    --                },
    --                {
    --                    fname = "Commande",
    --                    idname = "orders",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["soldat"].orders or false,
    --                },
    --                {
    --                    fname = "Gérer les propriétés",
    --                    idname = "manage_property",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["soldat"].manage_property or false,
    --                },
    --                {
    --                    fname = "Gérer les véhicules",
    --                    idname = "manage_garage",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["soldat"].manage_garage or false,
    --                },
    --            }
    --        },
    --        {
    --            edit = true,
    --            id = 1,
    --            fname = "Membre",
    --            lname = "",
    --            permission = {
    --                {
    --                    fname = "Recruter un joueur",
    --                    idname = "recruit",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["membre"].recruit or false,
    --                },
    --                {
    --                    fname = "Promouvoir un joueur",
    --                    idname = "promote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["membre"].promote or false,
    --                },
    --                {
    --                    fname = "Rétrograder un joueur",
    --                    idname = "demote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["membre"].demote or false,
    --                },
    --                {
    --                    fname = "Exclure un joueur",
    --                    idname = "kick",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["membre"].kick or false,
    --                },
    --                {
    --                    fname = "Gérer les permissions",
    --                    idname = "manage_permissions",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["membre"].manage_permissions or false,
    --                },
    --                {
    --                    fname = "Gestion",
    --                    idname = "manage_crew",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["membre"].manage_crew or false,
    --                },
    --                {
    --                    fname = "Commande",
    --                    idname = "orders",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["membre"].orders or false,
    --                },
    --                {
    --                    fname = "Gérer les propriétés",
    --                    idname = "manage_property",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["membre"].manage_property or false,
    --                },
    --                {
    --                    fname = "Gérer les véhicules",
    --                    idname = "manage_garage",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["membre"].manage_garage or false,
    --                },
    --            }
    --        },
    --        {
    --            edit = true,
    --            id = 1,
    --            fname = "Recrue",
    --            lname = "",
    --            permission = {
    --                {
    --                    fname = "Recruter un joueur",
    --                    idname = "recruit",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["recrue"].recruit or false,
    --                },
    --                {
    --                    fname = "Promouvoir un joueur",
    --                    idname = "promote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["recrue"].promote or false,
    --                },
    --                {
    --                    fname = "Rétrograder un joueur",
    --                    idname = "demote",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["recrue"].demote or false,
    --                },
    --                {
    --                    fname = "Exclure un joueur",
    --                    idname = "kick",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["recrue"].kick or false,
    --                },
    --                {
    --                    fname = "Gérer les permissions",
    --                    idname = "manage_permissions",
    --                    lname = "",
    --                    id = 2,
    --                    IsAcces = permissions["recrue"].manage_permissions or false,
    --                },
    --                {
    --                    fname = "Gestion",
    --                    idname = "manage_crew",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["recrue"].manage_crew or false,
    --                },
    --                {
    --                    fname = "Commande",
    --                    idname = "orders",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["recrue"].orders or false,
    --                },
    --                {
    --                    fname = "Gérer les propriétés",
    --                    idname = "manage_property",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["recrue"].manage_property or false,
    --                },
    --                {
    --                    fname = "Gérer les véhicules",
    --                    idname = "manage_garage",
    --                    lname = "",
    --                    id = 3,
    --                    IsAcces = permissions["recrue"].manage_garage or false,
    --                },
    --
    --            }
    --        },
    --    },
    --    MembersData = membersData
    --});
end

----OLD

RegisterNUICallback("nui:orgaManagement:UpdateRole", function(data, cb)

    local currentRole = data.currentRole
    local isPromoted = data.up
    local targetIdentifier = data.identifier
    local type = data.type

    console.debug("currentRole", currentRole)
    console.debug("isPromoted", isPromoted)
    console.debug("targetIdentifier", targetIdentifier)

    local success, newRole, message = TriggerServerCallback("core:orga:updateRole", type, currentRole, isPromoted, targetIdentifier)
    cb({ status = success, newRole = newRole, message = message })
end)

local ped = nil

RegisterNUICallback("nui:orgaManagement:close", function()
    if not open then
        return
    end

    console.debug("Closed nui:crew-management:close")
    VFW.Factions.DeleteCams("crewCreation")
    VFW.Cam:Destroy("requestMemberCam")
    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end

    VFW.Nui.FactionGestion(false)
    open = false

    Wait(250)

end)

--- RequestMemberCam
---@param skin any
---@param tattoos any
---@param data table
local function RequestMemberCam(skin, tattoos, data)
    VFW.Cam:Create("requestMemberCam", data)
    ped = VFW.CreatePlayerClone(skin, tattoos, vector3(data.COH.x, data.COH.y, data.COH.z), data.COH.w)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityVisible(ped, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetFocusPosAndVel(data.COH.x, data.COH.y, data.COH.z - 1.0)
    SetEntityCoords(ped, data.COH.x, data.COH.y, data.COH.z)
    Wait(100)
    SetEntityVisible(ped, true, false)
    SetEntityHeading(ped, data.COH.w)
    SetEntityCoords(ped, data.COH.x, data.COH.y, data.COH.z - 1.0)
    VFW.Cam:UpdateAnim(nil, data.Animation, ped)
    DoScreenFadeIn(1000)
end

local cams = {
    ["gang"] = {
        Dof = true,
        CamCoords = { x = 1034.5902099609376, y = -3205.998046875, z = -37.73314666748047 },
        Freeze = false,
        Fov = 40.1,
        DofStrength = 0.9,
        Animation = { anim = "idle", dict = "rcmjosh1" },
        CamRot = { x = -3.75441479682922, y = -0.0, z = -87.5434799194336 },
        COH = { x = 1036.0931396484376, y = -3205.997314453125, z = -38.17283630371094, w = 88.57354736328125 },
    },
    ["mc"] = {
        Dof = true,
        CamCoords = { x = 1104.5599365234376, y = -3159.198486328125, z = -37.0639419555664 },
        Freeze = false,
        Fov = 40.1,
        DofStrength = 0.9,
        Animation = { anim = "idle", dict = "rcmjosh1" },
        CamRot = { x = -2.63497257232666, y = -0.0, z = -25.29972076416015 },
        COH = { x = 1105.33251953125, y = -3157.891845703125, z = -37.51832962036133, w = 150.3196258544922 },
    },
    ["mafia"] = {
        Dof = true,
        CamCoords = { x = 1121.265380859375, y = -3197.34814453125, z = -39.89324188232422 },
        Freeze = false,
        Fov = 40.1,
        DofStrength = 0.9,
        Animation = { anim = "idle_a", dict = "anim@mp_corona_idles@male_d@idle_a" },
        CamRot = { x = -4.55505895614624, y = -0.0, z = -43.39242553710937 },
        COH = { x = 1122.357177734375, y = -3196.371826171875, z = -40.3986587524414, w = 125.58853912353516 },
    },
    ["orga"] = {
        Dof = true,
        CamCoords = { x = 516.5968017578125, y = -2619.0703125, z = -48.56061935424805 },
        Freeze = false,
        Fov = 40.1,
        DofStrength = 0.9,
        Animation = { anim = "idle_a", dict = "anim@mp_corona_idles@male_d@idle_a" },
        CamRot = { x = -3.29659724235534, y = -0.0, z = 2.93613910675048 },
        COH = { x = 516.5828857421875, y = -2617.438232421875, z = -48.99987030029297, w = 178.29026794433595 },
    },
}

RegisterNUICallback("nui:orgaManagement:requestMemberCam", function(data)
    if not open then
        return
    end

    local identifier = data.identifier

    if (identifier) then
        VFW.Nui.Focus(false)

        DoScreenFadeOut(1000)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        local skin, tattoos = TriggerServerCallback("core:faction:requestMemberCam", identifier)

        VFW.Factions.DeleteCams("crewCreation")

        RequestMemberCam(skin, tattoos, cams["gang"])

        VFW.Nui.Focus(true)
    else
        VFW.Nui.Focus(false)

        DoScreenFadeOut(1000)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        VFW.Cam:Destroy("requestMemberCam")

        DeleteEntity(ped)

        DoScreenFadeIn(1000)

        setPedInInstance()

        VFW.Nui.Focus(true)
    end
end)

RegisterNUICallback("nui:orgaManagement:submit", function(data)
    local updateType = data.type
    TriggerServerEvent("core:faction:update", updateType, data.name, data.devise, data.place)
end)

-- TODO Events server
RegisterNUICallback("nui:crew-management:member-submit", function(data)
    local playerId = data.player.license
    if playerId == "error cant find member id" then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "La personne n'a pas été trouvée."
        })
        return
    end

    local crewName = VFW.PlayerData.faction.name
    if data.action == "infoPlayer" then
        TriggerServerEvent("core:crew:getPlayerInfo", token, crewName, playerId)
        return
    elseif data.action == "upPlayer" then
        if (players[sourcePlayer] and players[sourcePlayer]["rank"] or 999) <= perms.editMembres then
            TriggerServerEvent("core:crew:changePlayerRankInCrew", token, crewName, playerId, data.player.rank - 1)
            return
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas les permissions pour faire cela."
            })
            return
        end
    elseif data.action == "downPlayer" then
        if (players[sourcePlayer] and players[sourcePlayer]["rank"] or 999) <= perms.editMembres then
            TriggerServerEvent("core:crew:changePlayerRankInCrew", token, crewName, playerId, data.player.rank + 1)
            return
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas les permissions pour faire cela."
            })
            return
        end
    elseif data.action == "kickPlayer" then
        TriggerServerEvent("core:crew:removePlayerFromCrew", token, crewName, playerId, data.player.license)
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Cette action n'est pas disponible."
        })
        return
    end

    OpenCrewGestion()
end)

RegisterNUICallback("nui:orgaManagement:UpdateRoles", function(data)
    local grade = data.grade
    local perms = data.permissions
    local type = data.type

    local data = {}

    for i = 1, #perms do
        data[perms[i].idname] = perms[i].IsAcces
    end

    TriggerServerEvent("core:orga:savePermissions", type, data, string.lower(grade))
end)

---@param newPerms any
RegisterNetEvent("core:crew:updatePerms", function(newPerms)
    VFW.PlayerData.faction.permissions = newPerms
end)

---Get VFW.MyCrewPermission
---@param name string
---@return boolean
function VFW.GetMyCrewPermission(name)
    local perm = VFW.PlayerData.faction.permissions

    for k, v in pairs(perm) do
        if VFW.PlayerData.faction.grade_name == k then
            if v[name] then
                return true
            else
                return false
            end
        end
    end

    return false
end