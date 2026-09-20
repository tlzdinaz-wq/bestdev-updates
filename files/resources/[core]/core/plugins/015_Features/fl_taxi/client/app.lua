-- =====================
-- Taxi App (lb-phone custom app)
-- =====================

local APP_ID <const> = "taxi-app"

local function SendAppMessage(event, data)
    exports["lb-phone"]:SendCustomAppMessage(APP_ID, {
        action = event,
        data = data
    })
end

-- Track pending requests (driver side)
local driverPendingRequests = {}

local function GetLocationLabel(coords)
    if not coords then return "Position inconnue", "" end
    local x, y, z = coords.x, coords.y, coords.z
    if not x or not y or not z then return "Position inconnue", "" end

    local streetHash, crossingHash = GetStreetNameAtCoord(x, y, z)
    local street = streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or ""
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or ""

    local zoneCode = GetNameOfZone(x, y, z)
    local zoneName = zoneCode and GetLabelText(zoneCode) or ""
    if zoneName == "NULL" then zoneName = "" end

    local location
    if street ~= "" and crossing ~= "" then
        location = street .. " / " .. crossing
    elseif street ~= "" then
        location = street
    elseif zoneName ~= "" then
        location = zoneName
    else
        location = "Position inconnue"
    end

    return location, zoneName
end

-- Client position tracking (30s interval)
local positionTrackingActive = false

local function StartClientPositionTracking()
    if positionTrackingActive then return end
    positionTrackingActive = true

    CreateThread(function()
        while positionTrackingActive do
            Wait(30000)
            if not positionTrackingActive then break end
            local pos = GetEntityCoords(PlayerPedId())
            TriggerServerEvent("taxi:ride:updatePosition", pos)
        end
    end)
end

local function StopClientPositionTracking()
    positionTrackingActive = false
end

-- =====================
-- App Registration
-- =====================

local appConfig = {
    identifier = APP_ID,
    name = "Taxi",
    description = "Reservez un taxi en quelques secondes",
    developer = "Taxi Co.",
    defaultApp = true,
    size = 1200,
    icon = "https://cfx-nui-core/plugins/015_Features/ui/taxi-app/icon.svg",
    ui = "https://cfx-nui-core/plugins/015_Features/ui/taxi-app/index.html",
    fixBlur = true,
}

local function RegisterTaxiApp()
    local ok, added
    for attempt = 1, 5 do
        ok, added = pcall(exports["lb-phone"].AddCustomApp, exports["lb-phone"], appConfig)
        if ok and added then break end
        Wait(2000)
    end
end

CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(500)
    end

    local waited = 0
    while GetResourceState("lb-phone") ~= "started" do
        waited = waited + 1
        if waited > 60 then return end
        Wait(500)
    end

    Wait(2000)
    RegisterTaxiApp()
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= "lb-phone" then return end
    Wait(2000)
    RegisterTaxiApp()
end)

-- =====================
-- NUI Callbacks (App UI -> Client Lua)
-- =====================

RegisterNUICallback("taxi-app:getInfo", function(_, cb)
    local isTaxi = TriggerServerCallback("taxi:isJobTaxi")
    local job = VFW.PlayerData.job
    local onDuty = isTaxi == true and job and job.onDuty or false

    if isTaxi then
        -- Check if driver has an active ride
        local activeRide = TriggerServerCallback("taxi:getDriverActiveRide")
        if activeRide then
            local location, zone = GetLocationLabel(activeRide.position)
            TriggerEvent("taxi:internal:restorePlayerRide", activeRide.clientId, activeRide.position, activeRide.clientName, activeRide.arrived)
            activeRide.location = location
            activeRide.zone = zone
            activeRide.position = nil
            activeRide.clientId = nil
            cb({
                isTaxi = true,
                onDuty = onDuty,
                activeRide = activeRide,
                rideStatus = nil,
                pendingRequests = {},
            })
        else
            -- Driver: fetch pending rides from server
            local serverRides = TriggerServerCallback("taxi:getPendingRides")
            if serverRides then
                driverPendingRequests = {}
                for _, ride in ipairs(serverRides) do
                    local location, zone = GetLocationLabel(ride.position)
                    driverPendingRequests[tostring(ride.requestId)] = {
                        clientName = ride.clientName,
                        clientPhone = ride.clientPhone,
                        location = location,
                        zone = zone,
                    }
                end
            end

            cb({
                isTaxi = true,
                onDuty = onDuty,
                activeRide = nil,
                rideStatus = nil,
                pendingRequests = driverPendingRequests,
            })
        end
    else
        -- Client: get ride status
        local rideStatus = TriggerServerCallback("taxi:getRideStatus")
        cb({
            isTaxi = false,
            onDuty = false,
            rideStatus = rideStatus,
            pendingRequests = nil,
        })
    end
end)

RegisterNUICallback("taxi-app:requestRide", function(_, cb)
    local pos = GetEntityCoords(PlayerPedId())
    TriggerServerEvent("taxi:ride:request", pos)
    StartClientPositionTracking()
    cb({ ok = true })
end)

RegisterNUICallback("taxi-app:cancelRide", function(_, cb)
    StopClientPositionTracking()
    TriggerServerEvent("taxi:ride:cancel")
    cb({ ok = true })
end)

RegisterNUICallback("taxi-app:acceptRide", function(data, cb)
    if not data or not data.requestId then
        cb({ ok = false })
        return
    end

    TriggerServerEvent("taxi:ride:accept", data.requestId)
    cb({ ok = true })
end)

RegisterNUICallback("taxi-app:driverCancelRide", function(_, cb)
    TriggerServerEvent("taxi:ride:cancel")
    TriggerEvent("taxi:internal:cancelRide")
    cb({ ok = true })
end)

RegisterNUICallback("taxi-app:clientCompleteRide", function(_, cb)
    StopClientPositionTracking()
    TriggerServerEvent("taxi:ride:complete")
    cb({ ok = true })
end)

-- =====================
-- Client Events (Server -> Client -> App UI)
-- =====================

-- Client: driver requested an immediate position update (locate button)
RegisterNetEvent("taxi:client:sendPositionNow", function()
    local pos = GetEntityCoords(PlayerPedId())
    TriggerServerEvent("taxi:ride:updatePosition", pos)
end)

-- Client: ride accepted by a driver
RegisterNetEvent("taxi:app:rideAccepted", function(driverName, societyLabel, driverPhone)
    SendAppMessage("rideAccepted", {
        driverName = driverName,
        societyLabel = societyLabel or "Taxi",
        driverPhone = driverPhone,
    })

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Chauffeur en route",
        content = driverName .. " (" .. (societyLabel or "Taxi") .. ") arrive vers vous",
    })
end)

-- Client: no driver available
RegisterNetEvent("taxi:app:noDriverAvailable", function(reason)
    StopClientPositionTracking()
    SendAppMessage("noDriverAvailable", { reason = reason })

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = reason == "timeout" and "Délai expiré" or "Aucun chauffeur",
        content = reason == "timeout" and "Aucun chauffeur n'a accepté votre demande" or "Aucun taxi n'est disponible pour le moment",
    })
end)

-- Client: ride cancelled by driver
RegisterNetEvent("taxi:app:rideCancelled", function(reason)
    StopClientPositionTracking()
    SendAppMessage("rideCancelled", {})

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Course annulée",
        content = reason or "La course a été annulée",
    })
end)

-- Client: driver arrived at pickup zone (ride still active)
RegisterNetEvent("taxi:app:driverArrived", function(_driverName)
    SendAppMessage("driverArrived", {})

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Chauffeur arrivé",
        content = "Votre chauffeur est arrivé au point de prise en charge",
    })
end)

-- Client: ride finished (either side clicked Terminer)
RegisterNetEvent("taxi:app:rideCompleted", function()
    StopClientPositionTracking()
    SendAppMessage("rideCompleted", {})

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Course terminée",
        content = "Bonne route !",
    })
end)

-- =====================
-- Driver Events (Server -> Client -> App UI)
-- =====================

-- New ride request
RegisterNetEvent("taxi:driver:newRequest", function(requestId, clientName, position, clientPhone)
    local location, zone = GetLocationLabel(position)

    driverPendingRequests[tostring(requestId)] = {
        clientName = clientName,
        clientPhone = clientPhone,
        location = location,
        zone = zone,
    }

    SendAppMessage("newRequest", {
        requestId = requestId,
        clientName = clientName,
        clientPhone = clientPhone,
        location = location,
        zone = zone,
    })

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Nouvelle course",
        content = clientName .. " demande un taxi - " .. location,
    })
end)

-- Ride taken by another driver
RegisterNetEvent("taxi:driver:rideTaken", function(_driverName, requestId)
    if requestId then
        driverPendingRequests[tostring(requestId)] = nil

        SendAppMessage("requestRemoved", {
            requestId = requestId,
        })
    end
end)

-- Ride confirmed (this driver accepted)
RegisterNetEvent("taxi:driver:rideConfirmed", function(_clientId, position, clientName, clientPhone)
    -- Clear all pending requests (driver is now on a ride)
    driverPendingRequests = {}

    local location, zone = GetLocationLabel(position)

    SendAppMessage("rideConfirmed", {
        clientName = clientName,
        clientPhone = clientPhone,
        location = location,
        zone = zone,
    })
end)

-- Driver: reached pickup zone (proximity check fired)
RegisterNetEvent("taxi:driver:arrivedAtClient", function()
    SendAppMessage("driverArrivedAtClient", {})

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Client à proximité",
        content = "Validez la fin de la course une fois le client à bord",
    })
end)

-- Active ride cancelled (client cancelled or disconnected)
RegisterNetEvent("taxi:driver:activeRideCancelled", function(message)
    SendAppMessage("activeRideCancelled", {})

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Course annulée",
        content = message or "La course a été annulée",
    })
end)

-- Driver: ride completed (either side validated)
RegisterNetEvent("taxi:driver:rideCompleted", function()
    SendAppMessage("rideCompleted", {})

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Course terminée",
        content = "Bonne route !",
    })
end)

-- Client cancelled their ride request or disconnected
RegisterNetEvent("taxi:driver:rideCancelled", function(requestId, notifMessage)
    if requestId then
        driverPendingRequests[tostring(requestId)] = nil

        SendAppMessage("requestRemoved", {
            requestId = requestId,
        })
    end

    exports["lb-phone"]:SendNotification({
        app = APP_ID,
        title = "Course annulée",
        content = notifMessage or "La course a été annulée",
    })
end)

-- Job change: refresh app role and duty status
RegisterNetEvent("vfw:setJob", function()
    Wait(500)
    local isTaxi = TriggerServerCallback("taxi:isJobTaxi")
    local job = VFW.PlayerData.job
    local onDuty = isTaxi == true and job and job.onDuty or false

    if not isTaxi then
        driverPendingRequests = {}
        StopClientPositionTracking()
    end

    SendAppMessage("jobUpdate", {
        isTaxi = isTaxi == true,
        onDuty = onDuty,
    })
end)

-- Duty toggle: update app duty status
RegisterNetEvent("vfw:client:changeDuty", function(state)
    local isTaxi = TriggerServerCallback("taxi:isJobTaxi")
    if not isTaxi then
        StopClientPositionTracking()
        return
    end

    if not state then
        driverPendingRequests = {}
        StopClientPositionTracking()
    end

    SendAppMessage("jobUpdate", {
        isTaxi = true,
        onDuty = state == true,
    })
end)
