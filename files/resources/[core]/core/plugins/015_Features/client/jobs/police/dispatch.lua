---@meta _
---@diagnostic disable: duplicate-doc-field

local dispatchNotifActive = false
local distanceUpdateThread = false
local dispatchPanelOpen = false
local receivedAlerts = {} -- alertId -> alert data (for waypoint coords)

local function decodeNuiData(data)
    if type(data) == "string" then
        local ok, decoded = pcall(json.decode, data)
        if ok then
            return decoded
        end
    end
    return data
end

-- ============================================================
-- DISTRICT SYSTEM (6 zones)
-- ============================================================

local function getDistrict(x, y)
    if y > 1500 then
        return "Blaine County"
    end
    if y > 200 then
        return "Vinewood"
    end
    if x < -1200 then
        return "Ouest"
    end
    if x > 500 then
        return "Est"
    end
    if y > -1100 then
        return "Central"
    end
    return "Sud"
end

-- ============================================================
-- DISPATCH PANEL OPEN/CLOSE (called from F4 menu)
-- ============================================================

function OpenDispatchPanel()
    if dispatchPanelOpen then
        return
    end

    if not VFW.PlayerData or not VFW.PlayerData.job then
        return
    end

    if not IsPoliceJob(VFW.PlayerData.job.name) then
        return
    end

    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = "JOB", title = VFW.PlayerData.job.label or VFW.PlayerData.job.name or "sasp", subtitle = "Dispatch", image = VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png"), content = "Vous devez être en service" })
        return
    end

    dispatchPanelOpen = true

    local jobName = VFW.PlayerData.job.name
    local jobLabel = VFW.PlayerData.job.label or jobName or "Police"

    SendNUIMessage({
        action = "nui:PoliceDispatch:panelVisible",
        data = true,
    })

    SendNUIMessage({
        action = "nui:PoliceDispatch:setJobLabel",
        data = jobLabel,
    })

    -- Cursor visible + game controls still work (drive, walk, etc.)
    VFW.Nui.Focus(true, true)

    -- Block combat + camera movement
    CreateThread(function()
        while dispatchPanelOpen do
            DisableControlAction(0, 1, true)    -- Look LR
            DisableControlAction(0, 2, true)    -- Look UD
            DisableControlAction(0, 24, true)   -- Attack
            DisableControlAction(0, 25, true)   -- Aim
            DisableControlAction(0, 47, true)   -- Weapon (G)
            DisableControlAction(0, 58, true)   -- Weapon (throw)
            DisableControlAction(0, 140, true)  -- Melee light
            DisableControlAction(0, 141, true)  -- Melee heavy
            DisableControlAction(0, 142, true)  -- Melee alternate
            DisableControlAction(0, 143, true)  -- Melee block
            DisableControlAction(0, 263, true)  -- Melee attack 1
            DisableControlAction(0, 264, true)  -- Melee attack 2
            DisableControlAction(0, 257, true)  -- Attack 2
            DisableControlAction(0, 45, true)   -- Reload
            DisableControlAction(0, 37, true)   -- Select weapon
            Wait(0)
        end
    end)
end

function CloseDispatchPanel()
    if not dispatchPanelOpen then
        return
    end
    dispatchPanelOpen = false

    SendNUIMessage({
        action = "nui:PoliceDispatch:panelVisible",
        data = false,
    })

    -- If dispatch was opened from F4 VUI menu, restore VUI cursor instead of killing focus
    if _G._dispatchOpenedFromF4 then
        _G._dispatchOpenedFromF4 = false
        VFW.Nui.Focus(false, false)
    else
        VFW.Nui.Focus(false, false)
    end
end

-- Command for cross-resource access (F4 menu)
RegisterCommand("openDispatchPanel", function()
    OpenDispatchPanel()
end, false)

-- Configurable keybind (appears in FiveM Settings > Key Bindings)
RegisterCommand("+toggleDispatch", function()
    if dispatchPanelOpen then
        CloseDispatchPanel()
    else
        OpenDispatchPanel()
    end
end, false)

RegisterCommand("-toggleDispatch", function()
end, false)

RegisterKeyMapping("+toggleDispatch", "Ouvrir/Fermer le Dispatch", "keyboard", "l")

RegisterNuiCallback("dispatch:closePanel", function(_, cb)
    CloseDispatchPanel()
    cb("ok")
end)

-- Toggle keyboard pass-through when typing in inputs
RegisterNuiCallback("dispatch:setKeyboardFocus", function(data, cb)
    data = decodeNuiData(data)
    local focused = data and data.focused or false
    if dispatchPanelOpen then
        SetNuiFocusKeepInput(not focused)
    end
    cb("ok")
end)

-- Close panel on ESC
CreateThread(function()
    while true do
        if dispatchPanelOpen and IsControlJustPressed(0, 322) then
            -- ESC
            CloseDispatchPanel()
        end
        Wait(dispatchPanelOpen and 0 or 500)
    end
end)

-- ============================================================
-- NUI CALLBACKS (React -> Lua)
-- ============================================================

RegisterNuiCallback("dispatch:createAlert", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        -- Inject player coords for GPS waypoint + district
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        data.x = coords.x
        data.y = coords.y
        data.z = coords.z
        data.district = getDistrict(coords.x, coords.y)
        TriggerServerEvent("police:dispatch:create", data)
    end)
    cb("ok")
end)

RegisterNuiCallback("dispatch:acceptAlert", function(data, cb)
    data = decodeNuiData(data)
    local alertId = data and data.alertId
    if alertId then
        TriggerServerEvent("police:dispatch:accept", alertId)
        -- Place waypoint from cached alert coords
        local cached = receivedAlerts[alertId]
        if cached and cached.x and cached.y then
            SetNewWaypoint(cached.x + 0.0, cached.y + 0.0)
        end
    end
    cb("ok")
end)

RegisterNuiCallback("dispatch:refuseAlert", function(data, cb)
    -- Client-only: just remove the notification from NUI
    cb("ok")
end)

RegisterNuiCallback("dispatch:assignAll", function(data, cb)
    data = decodeNuiData(data)
    local alertId = data and data.alertId
    if alertId then
        TriggerServerEvent("police:dispatch:assignAll", alertId)
    end
    cb("ok")
end)

RegisterNuiCallback("dispatch:getActiveAlerts", function(_, cb)
    pcall(function()
        local response = TriggerServerCallback("police:dispatch:getActiveAlerts")
        cb(response or {})
    end)
end)

RegisterNuiCallback("dispatch:getHistory", function(_, cb)
    pcall(function()
        local response = TriggerServerCallback("police:dispatch:getHistory")
        cb(response or {})
    end)
end)

RegisterNuiCallback("dispatch:resendAlert", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        local alertId = data and data.alertId
        if alertId then
            TriggerServerEvent("police:dispatch:resend", alertId)
        end
    end)
    cb("ok")
end)

RegisterNuiCallback("dispatch:closeAlert", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        local alertId = data and data.alertId
        if alertId then
            TriggerServerEvent("police:dispatch:close", alertId)
        end
    end)
    cb("ok")
end)

RegisterNuiCallback("dispatch:getPlayerLocation", function(_, cb)
    pcall(function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
        local location = crossing and (street .. " / " .. crossing) or street
        cb({ location = location, district = getDistrict(coords.x, coords.y), x = coords.x, y = coords.y, z = coords.z })
    end)
end)

-- ============================================================
-- BACKUP REQUEST (sub-header buttons)
-- ============================================================

RegisterNuiCallback("dispatch:requestBackup", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        local level = data and tonumber(data.level) or 1
        -- Fire legacy SASP backup event
        TriggerServerEvent("dispatch:server:requestBackup", level)

        -- Also create a dispatch alert for the new system
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
        local location = crossing and (street .. " / " .. crossing) or street

        local levelNames = { "routine", "priority", "critical" }
        local levelTitles = { "Backup niveau 1", "Backup niveau 2", "Backup niveau 3 - URGENT" }

        local matricule = nil
        pcall(function()
            local unitsData = TriggerServerCallback("police:units:getData")
            if unitsData and unitsData.matricule then
                matricule = unitsData.matricule
            end
        end)

        local desc = "Demande envoyée par l'agent"
        if matricule then
            desc = desc .. " (Matricule " .. tostring(matricule) .. ")"
        end

        TriggerServerEvent("police:dispatch:create", {
            level = levelNames[level] or "routine",
            title = levelTitles[level] or "Demande de backup",
            description = desc,
            location = location,
            district = getDistrict(coords.x, coords.y),
            x = coords.x,
            y = coords.y,
            z = coords.z,
        })
    end)
    cb("ok")
end)

-- ============================================================
-- OPEN CITIZEN IN MDT (from dispatch search)
-- ============================================================

RegisterNuiCallback("dispatch:openCitizenInMDT", function(data, cb)
    cb("ok")
    data = decodeNuiData(data)
    local citizenId = data and tonumber(data.citizenId)
    if not citizenId then
        return
    end

    -- Exécuter dans un thread pour ne pas bloquer le callback
    CreateThread(function()
        CloseDispatchPanel()
        Wait(100)
        VFW.Nui.policePanel(true)
        Wait(200)
        SendNUIMessage({
            action = "nui:PolicePanel:openCitizen",
            data = citizenId,
        })
    end)
end)

-- ============================================================
-- SEARCH CALLBACKS (proxy to MDT server callbacks)
-- ============================================================

RegisterNuiCallback("dispatch:searchCitizen", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        local response = TriggerServerCallback("police:searchCitizens", data)
        cb(response or {})
    end)
end)

RegisterNuiCallback("dispatch:searchVehicle", function(data, cb)
    data = decodeNuiData(data)
    local ok, response = pcall(TriggerServerCallback, "police:searchVehicles", data)
    if ok and response then
        -- Resolve model hashes to human-readable names
        for _, v in ipairs(response) do
            if v.model then
                local hash = tonumber(v.model)
                if hash then
                    local makeName = GetMakeNameFromVehicleModel(hash)
                    local modelName = GetDisplayNameFromVehicleModel(hash)
                    local make = makeName and GetLabelText(makeName) or ""
                    local model = modelName and GetLabelText(modelName) or ""
                    if make == "NULL" then
                        make = ""
                    end
                    if model == "NULL" then
                        model = tostring(hash)
                    end
                    v.model = (make ~= "" and (make .. " ") or "") .. model
                end
            end
        end
        cb(response)
    else
        cb({})
    end
end)

-- ============================================================
-- OFFICER COUNT
-- ============================================================

RegisterNuiCallback("dispatch:getOfficerCount", function(_, cb)
    local ok = pcall(function()
        local officers = TriggerServerCallback("police:getOfficers") or {}
        local count = 0
        for i = 1, #officers do
            if officers[i].online then count = count + 1 end
        end
        cb({ count = count })
    end)
    if not ok then cb({ count = 0 }) end
end)

-- ============================================================
-- SERVER EVENTS (Server -> Client -> NUI)
-- ============================================================

RegisterNetEvent("police:dispatch:incoming", function(alert)
    if not alert then
        return
    end

    -- Cache alert for waypoint coords (limiter à 50 entrées)
    if alert.id then
        receivedAlerts[alert.id] = alert
        local count = 0
        local oldest = nil
        local oldestId = nil
        for id, a in pairs(receivedAlerts) do
            count = count + 1
            if not oldest or (a.time or 0) < oldest then
                oldest = a.time or 0
                oldestId = id
            end
        end
        if count > 50 and oldestId then
            receivedAlerts[oldestId] = nil
        end
    end

    -- Compute initial distance
    if alert.x and alert.y and alert.z then
        local myCoords = GetEntityCoords(PlayerPedId())
        alert.distance = math.floor(#(myCoords - vector3(alert.x, alert.y, alert.z)))
    end

    -- Send to NUI for notification display
    SendNUIMessage({
        action = "nui:PoliceDispatch:incoming",
        data = alert,
    })

    dispatchNotifActive = true
    startDistanceUpdateThread()
end)

RegisterNetEvent("police:dispatch:alertUpdated", function(alert)
    if not alert then
        return
    end

    SendNUIMessage({
        action = "nui:PoliceDispatch:alertUpdated",
        data = alert,
    })
end)

RegisterNetEvent("police:dispatch:setWaypoint", function(x, y)
    if x and y then
        SetNewWaypoint(x + 0.0, y + 0.0)
    end
end)

-- ============================================================
-- KEYBINDS (Y = accept, N = refuse)
-- ============================================================

RegisterCommand("+dispatchAccept", function()
    if not dispatchNotifActive then
        return
    end
    SendNUIMessage({
        action = "nui:PoliceDispatch:keyAction",
        data = { key = "accept" },
    })
end, false)

RegisterCommand("-dispatchAccept", function()
end, false)

RegisterCommand("+dispatchRefuse", function()
    if not dispatchNotifActive then
        return
    end
    SendNUIMessage({
        action = "nui:PoliceDispatch:keyAction",
        data = { key = "refuse" },
    })
end, false)

RegisterCommand("-dispatchRefuse", function()
end, false)

RegisterKeyMapping("+dispatchAccept", "Accepter Dispatch", "keyboard", "y")
RegisterKeyMapping("+dispatchRefuse", "Refuser Dispatch", "keyboard", "n")

-- ============================================================
-- DISTANCE UPDATE THREAD
-- ============================================================

function startDistanceUpdateThread()
    if distanceUpdateThread then
        return
    end
    distanceUpdateThread = true

    CreateThread(function()
        local maxTime = GetGameTimer() + 120000 -- 2 min max de sécurité
        while dispatchNotifActive and GetGameTimer() < maxTime do
            Wait(2000)

            if not dispatchNotifActive then
                break
            end

            local ped = PlayerPedId()
            local myCoords = GetEntityCoords(ped)

            -- Get street name for current location + district
            local streetHash, crossingHash = GetStreetNameAtCoord(myCoords.x, myCoords.y, myCoords.z)
            local street = GetStreetNameFromHashKey(streetHash)
            local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
            local currentLocation = crossing and (street .. " / " .. crossing) or street
            local currentDistrict = getDistrict(myCoords.x, myCoords.y)

            local distances = {}
            for id, a in pairs(receivedAlerts) do
                if a.x and a.y and a.z then
                    local dist = #(myCoords - vector3(a.x, a.y, a.z))
                    distances[id] = math.floor(dist)
                end
            end

            SendNUIMessage({
                action = "nui:PoliceDispatch:updateDistances",
                data = {
                    playerCoords = { x = myCoords.x, y = myCoords.y, z = myCoords.z },
                    currentLocation = currentLocation,
                    currentDistrict = currentDistrict,
                    distances = distances,
                },
            })
        end

        dispatchNotifActive = false
        distanceUpdateThread = false
    end)
end

-- ============================================================
-- NUI event to update notification active state
-- ============================================================

RegisterNuiCallback("dispatch:setNotifActive", function(data, cb)
    data = decodeNuiData(data)
    dispatchNotifActive = data and data.active or false
    cb("ok")
end)

-- ============================================================
-- UNIT MANAGEMENT NUI CALLBACKS
-- ============================================================

RegisterNuiCallback("units:getData", function(_, cb)
    pcall(function()
        local response = TriggerServerCallback("police:units:getData")
        cb(response or { matricule = nil, units = {}, myUnitId = nil })
    end)
end)

RegisterNuiCallback("units:createUnit", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        if data and data.name then
            TriggerServerEvent("police:units:createUnit", data)
        end
    end)
    cb("ok")
end)

RegisterNuiCallback("units:joinUnit", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        if data and data.unitId then
            TriggerServerEvent("police:units:joinUnit", data)
        end
    end)
    cb("ok")
end)

RegisterNuiCallback("units:leaveUnit", function(_, cb)
    pcall(function()
        TriggerServerEvent("police:units:leaveUnit")
    end)
    cb("ok")
end)

RegisterNuiCallback("units:changeMatricule", function(data, cb)
    pcall(function()
        if type(data) == "string" then
            local ok, decoded = pcall(json.decode, data)
            if ok then
                data = decoded
            end
        end
        if data and data.matricule then
            TriggerServerEvent("police:units:changeMatricule", data)
        end
    end)
    cb("ok")
end)

-- Server -> Client -> NUI: units updated
RegisterNetEvent("police:units:updated", function(unitsData)
    if not unitsData then
        return
    end
    SendNUIMessage({
        action = "nui:police:unitsUpdated",
        data = unitsData,
    })
end)

-- ============================================================
-- CLEANUP on duty change / resource stop
-- ============================================================

RegisterNetEvent("vfw:setJob", function()
    -- When job changes, clear dispatch notifications and close panel
    SendNUIMessage({
        action = "nui:PoliceDispatch:clear",
        data = {},
    })
    dispatchNotifActive = false
    receivedAlerts = {}
    CloseDispatchPanel()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    dispatchNotifActive = false
    distanceUpdateThread = false
    if dispatchPanelOpen then
        dispatchPanelOpen = false
        VFW.Nui.Focus(false)
    end
    receivedAlerts = {}
end)
