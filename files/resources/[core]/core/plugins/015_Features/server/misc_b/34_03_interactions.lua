local carrying = {}
local carriedBy = {}
local escorting = {}
local escortedBy = {}
local searchConsent = {}
local headbagged = {}

local HEADBAG_ITEM = "sactete"
local MAX_INTERACT_DIST = 5.0
local GOUV_JOBS = { "gouvernement", "gouvernement_cayo" }

local function stopCarry(carrier)
    local target = carrying[carrier]
    if not target then return end
    carrying[carrier] = nil
    carriedBy[target] = nil
    TriggerClientEvent("CarryPeople:cl_stop", target)
    TriggerClientEvent("CarryPeople:cl_stop", carrier)
end

local function stopEscort(escorter)
    local target = escorting[escorter]
    if not target then return end
    escorting[escorter] = nil
    escortedBy[target] = nil
    TriggerClientEvent("core:escort:attached", target, false, escorter)
end

local function isCuffed(target)
    if not target then return false end
    local ok, state = pcall(function() return Player(target).state.isCuffed end)
    if ok and state == true then return true end
    local xTarget = VFW.GetPlayerFromId(target)
    if xTarget and xTarget.metadata and xTarget.metadata.isCuffed then return true end
    return false
end

local function closeEnough(a, b, dist)
    local xa, xb = VFW.GetPlayerFromId(a), VFW.GetPlayerFromId(b)
    if not xa or not xb then return false end
    return MiscB.Dist(xa.getCoords(), xb.getCoords()) <= (dist or MAX_INTERACT_DIST)
end

AddEventHandler("vfw:playerDropped", function(source)
    stopCarry(source)
    if carriedBy[source] then
        local carrier = carriedBy[source]
        carrying[carrier] = nil
        carriedBy[source] = nil
        TriggerClientEvent("CarryPeople:cl_stop", carrier)
    end
    stopEscort(source)
    if escortedBy[source] then
        local escorter = escortedBy[source]
        escorting[escorter] = nil
        escortedBy[source] = nil
    end
    if searchConsent[source] then
        local agent = searchConsent[source].agent
        searchConsent[source] = nil
        if agent and VFW.GetPlayerFromId(agent) then
            VFW.ShowNotification(agent, { type = "ROUGE", content = "La personne s'est deconnectee." })
        end
    end
    for target, data in pairs(searchConsent) do
        if data.agent == source then
            searchConsent[target] = nil
            TriggerClientEvent("gouvernement:dismissSearchConsent", target)
        end
    end
    headbagged[source] = nil
end)

RegisterNetEvent("CarryPeople:sync", function(targetSrc)
    local source = source
    local target = tonumber(targetSrc)
    if not target or target == source then return end
    if not MiscB.Rate(source, "carry", 500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not closeEnough(source, target, MAX_INTERACT_DIST) then return end
    if carriedBy[target] or carrying[target] then return end
    if carrying[source] then stopCarry(source) end

    carrying[source] = target
    carriedBy[target] = source
    TriggerClientEvent("CarryPeople:syncTarget", target, source)
end)

RegisterNetEvent("CarryPeople:stop", function(targetSrc)
    local source = source
    local current = carrying[source]
    if not current then
        local target = tonumber(targetSrc)
        if target and carriedBy[target] == source then
            carrying[source] = target
        else
            return
        end
    end
    stopCarry(source)
end)

RegisterNetEvent("CarryPeople:requestStop", function()
    local source = source
    local carrier = carriedBy[source]
    if not carrier then return end
    stopCarry(carrier)
end)

RegisterNetEvent("interaction:tackle", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "tackle", 4000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not closeEnough(source, target, 3.5) then return end

    TriggerClientEvent("interaction:tackle:attacker", source, target)
    TriggerClientEvent("interaction:tackle:victim", target, source)
end)

RegisterNetEvent("headbag:server:apply", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "headbag", 1000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not closeEnough(source, target, 3.5) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Cible trop loin." })
        return
    end
    if headbagged[target] then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Cette personne a deja un sac sur la tete." })
        return
    end
    if not xPlayer.haveItem(HEADBAG_ITEM, 1) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous n'avez pas de sac." })
        return
    end
    if not xPlayer.removeInventoryItem(HEADBAG_ITEM, 1) then return end

    headbagged[target] = source
    TriggerClientEvent("headbag:apply", target)
    VFW.ShowNotification(source, { type = "VERT", content = "Sac pose sur la tete." })
end)

RegisterNetEvent("headbag:server:remove", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target then return end
    if not MiscB.Rate(source, "headbag_rm", 1000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not closeEnough(source, target, 3.5) then return end
    if not headbagged[target] then return end

    headbagged[target] = nil
    TriggerClientEvent("headbag:remove", target)

    if xPlayer.canCarryItem(HEADBAG_ITEM, 1) then
        xPlayer.addInventoryItem(HEADBAG_ITEM, 1)
    end
end)

RegisterNetEvent("headbag:server:selfRemoveGiveItem", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not headbagged[source] then return end

    headbagged[source] = nil
    if xPlayer.canCarryItem(HEADBAG_ITEM, 1) then
        xPlayer.addInventoryItem(HEADBAG_ITEM, 1)
    end
end)

local function doHandcuff(source, target, consumeItem, uncuffItem)
    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then
        return { success = false, message = "Personne introuvable." }
    end
    if not closeEnough(source, target, 3.5) then
        return { success = false, message = "La personne est trop loin." }
    end

    local cuffed = isCuffed(target)

    if cuffed then
        if uncuffItem and not xPlayer.haveItem(uncuffItem, 1) then
            return { success = false, message = "Il vous manque l'outil necessaire." }
        end
        xTarget.uncuff()
        local ped = GetPlayerPed(target)
        if ped and ped ~= 0 then
            TriggerClientEvent("core:handcuff:cufferAnim", source, NetworkGetNetworkIdFromEntity(ped), true)
        end
        if escortedBy[target] then
            stopEscort(escortedBy[target])
        end
        return { success = true, message = "Personne detachee." }
    end

    if consumeItem then
        if not xPlayer.haveItem(consumeItem, 1) then
            return { success = false, message = "Il vous manque l'objet necessaire." }
        end
        if not xPlayer.removeInventoryItem(consumeItem, 1) then
            return { success = false, message = "Il vous manque l'objet necessaire." }
        end
    end

    TriggerClientEvent("vfw:handcuff:holsterWeapon", target)
    xTarget.handcuff()
    local ped = GetPlayerPed(target)
    if ped and ped ~= 0 then
        TriggerClientEvent("core:handcuff:cufferAnim", source, NetworkGetNetworkIdFromEntity(ped), false)
    end
    return { success = true, message = "Personne attachee." }
end

RegisterNetEvent("police:toggleHandcuff", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "cuff", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end

    local result = doHandcuff(source, target, nil, nil)
    VFW.ShowNotification(source, { type = result.success and "VERT" or "ROUGE", content = result.message })
end)

RegisterNetEvent("gouvernement:toggleHandcuff", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "cuff", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.HasJob(xPlayer, GOUV_JOBS) then return end

    local result = doHandcuff(source, target, nil, nil)
    VFW.ShowNotification(source, { type = result.success and "VERT" or "ROUGE", content = result.message })
end)

MiscB.Cb("faction:menu:handcuff", function(source, targetServerId)
    local target = tonumber(targetServerId)
    if not target or target == source then
        return { success = false, message = "Personne introuvable." }
    end
    if not MiscB.Rate(source, "cuff", 1500) then
        return { success = false, message = "Trop rapide." }
    end
    if isCuffed(target) then
        return { success = false, message = "Cette personne est deja attachee." }
    end
    return doHandcuff(source, target, "serflex", nil)
end)

MiscB.Cb("faction:menu:uncuff", function(source, targetServerId)
    local target = tonumber(targetServerId)
    if not target or target == source then
        return { success = false, message = "Personne introuvable." }
    end
    if not MiscB.Rate(source, "cuff", 1500) then
        return { success = false, message = "Trop rapide." }
    end
    if not isCuffed(target) then
        return { success = false, message = "Cette personne n'est pas attachee." }
    end
    return doHandcuff(source, target, nil, "pince_serflex")
end)

MiscB.Cb("vfw:faction:isPlayerCuffed", function(source, targetServerId)
    local target = tonumber(targetServerId)
    if not target then return false end
    return isCuffed(target)
end)

local function startEscort(source, target)
    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return false end
    if not closeEnough(source, target, 3.5) then return false end
    if escorting[source] then return false end
    if escortedBy[target] then return false end

    escorting[source] = target
    escortedBy[target] = source
    TriggerClientEvent("core:escort:attached", target, true, source)
    return true
end

RegisterNetEvent("vfw:faction:escort:start", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "escort", 800) then return end
    startEscort(source, target)
end)

RegisterNetEvent("vfw:faction:escort:stop", function(targetServerId)
    local source = source
    stopEscort(source)
end)

RegisterNetEvent("police:escort", function(serverId)
    local source = source
    local target = tonumber(serverId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "escort", 800) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end

    if escorting[source] then
        stopEscort(source)
        return
    end

    if not isCuffed(target) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "La personne doit etre menottee." })
        return
    end

    if startEscort(source, target) then
        VFW.ShowNotification(source, { type = "VERT", content = "Vous escortez la personne." })
    end
end)

RegisterNetEvent("gouvernement:escort", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "escort", 800) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.HasJob(xPlayer, GOUV_JOBS) then return end

    if escorting[source] then
        stopEscort(source)
        return
    end
    startEscort(source, target)
end)

RegisterNetEvent("police:stopEscort", function()
    local source = source
    stopEscort(source)
end)

MiscB.Cb("police:isEscortingSomeone", function(source)
    return escorting[source] ~= nil
end)

RegisterNetEvent("police:putInVehicle", function(serverId, netId)
    local source = source
    local target = tonumber(serverId)
    local net = tonumber(netId)
    if not target or not net then return end
    if not MiscB.Rate(source, "putveh", 1000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not MiscB.IsLawEnforcement(xPlayer) then return end
    if not closeEnough(source, target, 6.0) then return end

    if escorting[source] == target then
        stopEscort(source)
    end

    TriggerClientEvent("gouvernement:putInVehicle", target, net, source)
end)

local function openSearch(agent, target, origin)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return end
    TriggerClientEvent("gouvernement:startSearch", agent, target, true, MiscB.CharName(xTarget))
end

local function requestSearch(source, target, origin)
    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not closeEnough(source, target, 3.5) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "La personne est trop loin." })
        return
    end

    if isCuffed(target) then
        openSearch(source, target, origin)
        return
    end

    searchConsent[target] = { agent = source, origin = origin, at = GetGameTimer() }
    TriggerClientEvent("gouvernement:showSearchConsent", target, MiscB.CharName(xPlayer), origin)
    VFW.ShowNotification(source, { type = "JAUNE", content = "Demande de fouille envoyee." })
end

RegisterNetEvent("police:search", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "search", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.IsLawEnforcement(xPlayer) then return end
    requestSearch(source, target, "police")
end)

RegisterNetEvent("gouvernement:search", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "search", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not MiscB.HasJob(xPlayer, GOUV_JOBS) then return end
    requestSearch(source, target, "gouvernement")
end)

local function consentResponse(source, accepted, origin)
    local pending = searchConsent[source]
    if not pending then return end
    searchConsent[source] = nil

    local agent = pending.agent
    if not VFW.GetPlayerFromId(agent) then return end

    if accepted ~= true then
        VFW.ShowNotification(agent, { type = "ROUGE", content = "La fouille a ete refusee." })
        return
    end

    TriggerClientEvent("gouvernement:freezeForSearch", source, agent)
    local xTarget = VFW.GetPlayerFromId(source)
    TriggerClientEvent("gouvernement:startSearch", agent, source, false, MiscB.CharName(xTarget))
end

RegisterNetEvent("police:searchConsentResponse", function(accepted)
    local source = source
    consentResponse(source, accepted == true, "police")
end)

RegisterNetEvent("gouvernement:searchConsentResponse", function(accepted)
    local source = source
    consentResponse(source, accepted == true, "gouvernement")
end)

RegisterNetEvent("gouvernement:searchDone", function(targetId)
    local source = source
    local target = tonumber(targetId)
    if not target then return end
    if not VFW.GetPlayerFromId(target) then return end
    TriggerClientEvent("gouvernement:clearSearchAnim", target)
end)

RegisterNetEvent("vfw:k9:searchItems", function(targetServerId)
    local source = source
    local target = tonumber(targetServerId)
    if not target or target == source then return end
    if not MiscB.Rate(source, "k9search", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not MiscB.IsLawEnforcement(xPlayer) then return end
    if not closeEnough(source, target, 6.0) then return end

    TriggerClientEvent("gouvernement:startSearch", source, target, true, MiscB.CharName(xTarget))
end)

RegisterNetEvent("core:useBadge", function(targetServerId, data)
    local source = source
    local target = tonumber(targetServerId)
    if not target or type(data) ~= "table" then return end
    if not MiscB.Rate(source, "badge", 1500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    local xTarget = VFW.GetPlayerFromId(target)
    if not xPlayer or not xTarget then return end
    if not closeEnough(source, target, 6.0) then return end

    TriggerClientEvent("core:useBadgeTarget", target, {
        service = MiscB.Str(data.service, 64) or "",
        name = MiscB.Str(data.name, 64) or MiscB.CharName(xPlayer),
        matricule = MiscB.Str(tostring(data.matricule or ""), 16),
        grade = MiscB.Str(data.grade, 64) or "",
        photo = MiscB.Str(data.photo, 512) or "",
        disisions = MiscB.Str(data.disisions, 256) or "",
    })
end)

RegisterNetEvent("core:removeItems", function(itemName, count)
    local source = source
    if type(itemName) ~= "string" or #itemName > 64 then return end
    local n = MiscB.ToInt(count, 1, 100)
    if not n then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.removeInventoryItem(itemName, n)
end)

MiscB.Cb("core:server:jobs:GetPatientIdentity", function(source, targetServerId)
    local target = tonumber(targetServerId)
    if not target then return nil end
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return nil end

    local age = 0
    local dob = xTarget.dateofbirth
    if type(dob) == "string" then
        local d, m, y = dob:match("(%d+)[/-](%d+)[/-](%d+)")
        if not d then
            y, m, d = dob:match("(%d+)[/-](%d+)[/-](%d+)")
        end
        if y then
            local year = tonumber(y) or 0
            if year > 1900 then
                age = tonumber(os.date("%Y")) - year
            end
        end
    end

    return {
        prenom = xTarget.firstName or "",
        nom = xTarget.lastName or "",
        age = age,
        sexe = xTarget.sex or "",
    }
end)

MiscB.Cb("sn_sams:isSamsOnDuty", function(source)
    local players = MiscB.PlayersWithJobs({ "sams", "ambulance", "ems" })
    for i = 1, #players do
        local xPlayer = players[i]
        if xPlayer and type(xPlayer.job) == "table" and xPlayer.job.onDuty then
            return true
        end
    end
    return false
end)

local SKATE_ITEM = "skateboard"
local skateOut = {}

RegisterNetEvent("skating:server:spawnSkate", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not MiscB.Rate(source, "skate", 800) then return end
    TriggerClientEvent("skating:client:start", source)
end)

RegisterNetEvent("skating:server:removeSkateItem", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if skateOut[source] then return end
    if not xPlayer.haveItem(SKATE_ITEM, 1) then return end
    if xPlayer.removeInventoryItem(SKATE_ITEM, 1) then
        skateOut[source] = true
    end
end)

RegisterNetEvent("skating:server:pickupSkate", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not skateOut[source] then return end
    if not xPlayer.canCarryItem(SKATE_ITEM, 1) then
        VFW.ShowNotification(source, { type = "ROUGE", content = "Vous ne pouvez pas porter le skate." })
        return
    end
    skateOut[source] = nil
    xPlayer.addInventoryItem(SKATE_ITEM, 1)
end)

AddEventHandler("vfw:playerDropped", function(source)
    skateOut[source] = nil
end)
