Feat27 = Feat27 or {}

local requests = {}
local clientRequest = {}
local driverRequest = {}

local function onDutyDrivers(exceptSource)
    local out = {}
    if not VFW or not VFW.Players then return out end
    for src, xPlayer in pairs(VFW.Players) do
        if src ~= exceptSource and TaxiServer.IsOnDuty(xPlayer) then
            out[#out + 1] = src
        end
    end
    return out
end

local function broadcastIdleDrivers(event, exceptSource, ...)
    local drivers = onDutyDrivers(exceptSource)
    for i = 1, #drivers do
        if not driverRequest[drivers[i]] then
            TriggerClientEvent(event, drivers[i], ...)
        end
    end
end

local function persistRide(request)
    MySQL.insert("INSERT INTO taxi_rides (`request_id`, `client_identifier`, `client_name`, `client_phone`, `society`, `pos_x`, `pos_y`, `pos_z`, `status`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        request.id, request.clientIdentifier, request.clientName, request.clientPhone or "",
        request.society or "", request.position.x, request.position.y, request.position.z, "pending",
    })
end

local function updateRideStatus(request, status)
    local column = status == "accepted" and "accepted_at" or (status == "completed" and "completed_at" or nil)
    if column then
        MySQL.update(("UPDATE taxi_rides SET `status` = ?, `driver_identifier` = ?, `driver_name` = ?, `driver_phone` = ?, `%s` = NOW() WHERE `request_id` = ?"):format(column), {
            status, request.driverIdentifier, request.driverName, request.driverPhone or "", request.id,
        })
    else
        MySQL.update("UPDATE taxi_rides SET `status` = ? WHERE `request_id` = ?", { status, request.id })
    end
end

local function removeRequest(requestId)
    local request = requests[requestId]
    if not request then return nil end
    requests[requestId] = nil
    if request.clientSrc and clientRequest[request.clientSrc] == requestId then
        clientRequest[request.clientSrc] = nil
    end
    if request.driverSrc and driverRequest[request.driverSrc] == requestId then
        driverRequest[request.driverSrc] = nil
    end
    return request
end

local function expireRequest(requestId)
    local request = requests[requestId]
    if not request or request.driverSrc then return end

    removeRequest(requestId)
    updateRideStatus(request, "cancelled")

    if request.clientSrc then
        TriggerClientEvent("taxi:app:noDriverAvailable", request.clientSrc, "timeout")
    end
    broadcastIdleDrivers("taxi:driver:rideCancelled", nil, requestId, "La demande a expiré.")
end

RegisterNetEvent("taxi:ride:request", function(pos)
    local source = source
    if not Feat27.IsVec(pos) then return end
    if not Feat27.RateLimit(source, "taxi:request", 3000) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    if clientRequest[source] then
        TriggerClientEvent("taxi:app:noDriverAvailable", source, "already")
        return
    end

    local drivers = onDutyDrivers(source)
    if #drivers == 0 then
        TriggerClientEvent("taxi:app:noDriverAvailable", source, "none")
        return
    end

    local society = ""
    local timeout = 10
    for i = 1, #drivers do
        local driver = VFW.GetPlayerFromId(drivers[i])
        if driver then
            society = driver.job.name
            local cfg = TaxiServer.SocietyConfig(society)
            if cfg then timeout = cfg.commandTimeout or 10 end
            break
        end
    end

    local requestId = Feat27.Uuid()
    local request = {
        id = requestId,
        clientSrc = source,
        clientIdentifier = xPlayer.identifier,
        clientName = xPlayer.name or xPlayer.playerName,
        clientPhone = TaxiServer.GetPhone(source),
        position = Feat27.Plain(pos),
        society = society,
        arrived = false,
        createdAt = os.time(),
    }

    requests[requestId] = request
    clientRequest[source] = requestId
    persistRide(request)

    for i = 1, #drivers do
        TriggerClientEvent("taxi:driver:newRequest", drivers[i], requestId, request.clientName, request.position, request.clientPhone)
    end

    local delay = math.floor((tonumber(timeout) or 10) * 60000)
    if delay < 30000 then delay = 30000 end
    SetTimeout(delay, function()
        expireRequest(requestId)
    end)
end)

RegisterNetEvent("taxi:ride:accept", function(requestId)
    local source = source
    if requestId == nil then return end
    local id = tostring(requestId)

    if not Feat27.RateLimit(source, "taxi:accept", 500) then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not TaxiServer.IsOnDuty(xPlayer) then return end

    local request = requests[id]
    if not request or request.driverSrc then return end
    if driverRequest[source] then return end

    request.driverSrc = source
    request.driverIdentifier = xPlayer.identifier
    request.driverName = xPlayer.name or xPlayer.playerName
    request.driverPhone = TaxiServer.GetPhone(source)
    request.society = xPlayer.job.name
    driverRequest[source] = id

    updateRideStatus(request, "accepted")

    local societyLabel = Feat27.Society.GetLabel(xPlayer.job.name)

    TriggerClientEvent("taxi:driver:rideConfirmed", source, request.clientSrc, request.position, request.clientName, request.clientPhone)
    if request.clientSrc then
        TriggerClientEvent("taxi:app:rideAccepted", request.clientSrc, request.driverName, societyLabel, request.driverPhone)
    end
    broadcastIdleDrivers("taxi:driver:rideTaken", source, request.driverName, id)
end)

RegisterNetEvent("taxi:ride:cancel", function()
    local source = source
    if not Feat27.RateLimit(source, "taxi:cancel", 400) then return end

    local asDriver = driverRequest[source]
    if asDriver then
        local request = removeRequest(asDriver)
        if request then
            updateRideStatus(request, "cancelled")
            if request.clientSrc then
                TriggerClientEvent("taxi:app:rideCancelled", request.clientSrc, "Le chauffeur a annulé la course.")
            end
        end
        return
    end

    local asClient = clientRequest[source]
    if not asClient then return end

    local request = removeRequest(asClient)
    if not request then return end
    updateRideStatus(request, "cancelled")

    if request.driverSrc then
        TriggerClientEvent("taxi:driver:activeRideCancelled", request.driverSrc, "Le client a annulé la course.")
        TriggerClientEvent("taxi:driver:rideCancelled", request.driverSrc, request.id, "Le client a annulé la course.")
    else
        broadcastIdleDrivers("taxi:driver:rideCancelled", nil, request.id, "Le client a annulé la course.")
    end
end)

RegisterNetEvent("taxi:ride:complete", function()
    local source = source
    if not Feat27.RateLimit(source, "taxi:complete", 500) then return end

    local id = driverRequest[source] or clientRequest[source]
    if not id then return end

    local request = removeRequest(id)
    if not request then return end
    updateRideStatus(request, "completed")

    if request.clientSrc then
        TriggerClientEvent("taxi:app:rideCompleted", request.clientSrc)
    end
    if request.driverSrc then
        TriggerClientEvent("taxi:driver:rideCompleted", request.driverSrc)
    end
end)

RegisterNetEvent("taxi:ride:updatePosition", function(pos)
    local source = source
    if not Feat27.IsVec(pos) then return end
    if not Feat27.RateLimit(source, "taxi:pos", 1000) then return end

    local id = clientRequest[source]
    if not id then return end

    local request = requests[id]
    if not request then return end

    request.position = Feat27.Plain(pos)
    if request.driverSrc then
        TriggerClientEvent("taxi:driver:clientPositionUpdate", request.driverSrc, request.position)
    end
end)

RegisterNetEvent("taxi:ride:requestClientPosition", function()
    local source = source
    if not Feat27.RateLimit(source, "taxi:reqpos", 1500) then return end

    local id = driverRequest[source]
    if not id then return end

    local request = requests[id]
    if not request or not request.clientSrc then return end

    TriggerClientEvent("taxi:client:sendPositionNow", request.clientSrc)
    TriggerClientEvent("taxi:driver:clientPositionUpdate", source, request.position)
end)

RegisterNetEvent("taxi:ride:driverArrived", function()
    local source = source
    if not Feat27.RateLimit(source, "taxi:arrived", 2000) then return end

    local id = driverRequest[source]
    if not id then return end

    local request = requests[id]
    if not request or request.arrived then return end

    request.arrived = true
    updateRideStatus(request, "arrived")

    if request.clientSrc then
        TriggerClientEvent("taxi:app:driverArrived", request.clientSrc, request.driverName)
    end
    TriggerClientEvent("taxi:driver:arrivedAtClient", source)
end)

RegisterServerCallback("taxi:getDriverActiveRide", function(source)
    local id = driverRequest[source]
    if not id then return nil end

    local request = requests[id]
    if not request then return nil end

    return {
        clientId = request.clientSrc,
        clientName = request.clientName,
        clientPhone = request.clientPhone,
        position = { x = request.position.x, y = request.position.y, z = request.position.z },
        arrived = request.arrived == true,
    }
end)

RegisterServerCallback("taxi:getPendingRides", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not TaxiServer.IsOnDuty(xPlayer) then return {} end

    local out = {}
    for id, request in pairs(requests) do
        if not request.driverSrc then
            out[#out + 1] = {
                requestId = id,
                clientName = request.clientName,
                clientPhone = request.clientPhone,
                position = { x = request.position.x, y = request.position.y, z = request.position.z },
            }
        end
    end
    return out
end)

RegisterServerCallback("taxi:getRideStatus", function(source)
    local id = clientRequest[source]
    if not id then return nil end

    local request = requests[id]
    if not request then return nil end

    if not request.driverSrc then
        return { status = "pending", arrived = false }
    end

    return {
        status = "accepted",
        driverName = request.driverName,
        societyLabel = Feat27.Society.GetLabel(request.society),
        driverPhone = request.driverPhone,
        arrived = request.arrived == true,
    }
end)

local function releasePlayer(source)
    local asDriver = driverRequest[source]
    if asDriver then
        local request = removeRequest(asDriver)
        if request then
            updateRideStatus(request, "cancelled")
            if request.clientSrc then
                TriggerClientEvent("taxi:app:rideCancelled", request.clientSrc, "Le chauffeur n'est plus disponible.")
            end
        end
    end

    local asClient = clientRequest[source]
    if asClient then
        local request = removeRequest(asClient)
        if request then
            updateRideStatus(request, "cancelled")
            if request.driverSrc then
                TriggerClientEvent("taxi:driver:activeRideCancelled", request.driverSrc, "Le client s'est déconnecté.")
                TriggerClientEvent("taxi:driver:rideCancelled", request.driverSrc, request.id, "Le client s'est déconnecté.")
            else
                broadcastIdleDrivers("taxi:driver:rideCancelled", nil, request.id, "Le client s'est déconnecté.")
            end
        end
    end
end

AddEventHandler("vfw:playerDropped", function(source)
    releasePlayer(source)
end)

AddEventHandler("vfw:setJob", function(source, job)
    if not job or job.type ~= "taxi" then
        if driverRequest[source] then releasePlayer(source) end
    end
end)

AddEventHandler("vfw:setDuty", function(source, onDuty)
    if not onDuty and driverRequest[source] then
        releasePlayer(source)
    end
end)
