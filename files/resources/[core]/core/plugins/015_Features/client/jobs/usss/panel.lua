-- ============================================================
-- USSS MDT - Client
-- Opens/closes the USSS MDT panel
-- ============================================================

local isUSSS_MDTOpen = false

function OpenUSSSPanel()
    if isUSSS_MDTOpen then return end

    if not VFW.PlayerData or not VFW.PlayerData.job then return end
    if not VFW.PlayerData.job.name or not string.lower(VFW.PlayerData.job.name):find("usss") then return end

    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = "JOB",
            title = "USSS",
            subtitle = "Accès",
            image = VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "usss") .. ".png"),
            content = "Vous devez être en service"
        })
        return
    end

    isUSSS_MDTOpen = true

    SendNUIMessage({
        action = "nui:usss:openPanel",
        data = {
            playerName = (VFW.PlayerData.firstName or "") .. " " .. (VFW.PlayerData.lastName or ""),
            playerGrade = VFW.PlayerData.job.grade_label or "",
            jobLabel = VFW.PlayerData.job.label or "USSS",
            playerMugshot = VFW.PlayerData.mugshot or "",
            logo = VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "usss") .. ".png"),
        }
    })

    VFW.Nui.Focus(true, false)
end

function CloseUSSSPanel()
    if not isUSSS_MDTOpen then return end
    isUSSS_MDTOpen = false
    VFW.Nui.Focus(false, false)
end

-- NUI Callbacks
RegisterNUICallback("usss:closePanel", function(_, cb)
    CloseUSSSPanel()
    cb({})
end)

RegisterNUICallback("usss:getAllCitizens", function(data, cb)
    local ok, err = pcall(function()
        if type(data) == "string" then data = json.decode(data) end
        local result = TriggerServerCallback("usss:getAllCitizens", data or {})
        cb(result or {})
    end)
    if not ok then
        print("[USSS] getAllCitizens error: " .. tostring(err))
        cb({})
    end
end)

RegisterNUICallback("usss:searchCitizens", function(data, cb)
    local ok, err = pcall(function()
        if type(data) == "string" then data = json.decode(data) end
        local result = TriggerServerCallback("usss:searchCitizens", data or {})
        cb(result or {})
    end)
    if not ok then
        print("[USSS] searchCitizens error: " .. tostring(err))
        cb({})
    end
end)

RegisterNUICallback("usss:getCitizenProfile", function(data, cb)
    local ok, err = pcall(function()
        if type(data) == "string" then data = json.decode(data) end
        local result = TriggerServerCallback("usss:getCitizenProfile", data)
        cb(result or {})
    end)
    if not ok then cb({}) end
end)

RegisterNUICallback("usss:getWantedNotices", function(_, cb)
    local ok, err = pcall(function()
        local result = TriggerServerCallback("usss:getWantedNotices")
        cb(result or {})
    end)
    if not ok then cb({}) end
end)

RegisterNUICallback("usss:createWantedNotice", function(data, cb)
    local ok, err = pcall(function()
        if type(data) == "string" then data = json.decode(data) end
        local result = TriggerServerCallback("usss:createWantedNotice", data)
        cb(result or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNUICallback("usss:removeWantedNotice", function(data, cb)
    local ok, err = pcall(function()
        if type(data) == "string" then data = json.decode(data) end
        local result = TriggerServerCallback("usss:removeWantedNotice", data)
        cb(result or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNUICallback("usss:getWantedVehicles", function(_, cb)
    local ok, err = pcall(function()
        local result = TriggerServerCallback("usss:getWantedVehicles")
        cb(result or {})
    end)
    if not ok then cb({}) end
end)

RegisterNUICallback("usss:getOfficers", function(_, cb)
    local ok, err = pcall(function()
        local result = TriggerServerCallback("usss:getOfficers")
        cb(result or {})
    end)
    if not ok then cb({}) end
end)

RegisterNUICallback("usss:createAlert", function(data, cb)
    local ok, err = pcall(function()
        if type(data) == "string" then data = json.decode(data) end
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
        local location = crossing and (street .. " / " .. crossing) or street

        TriggerServerEvent("usss:dispatch:create", {
            level = data.level or "routine",
            title = data.title or "Alerte USSS",
            description = data.description or "",
            location = location,
            x = coords.x,
            y = coords.y,
            z = coords.z,
        })
        cb({ success = true })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNUICallback("usss:getActiveAlerts", function(_, cb)
    local ok, err = pcall(function()
        local result = TriggerServerCallback("usss:getActiveAlerts")
        cb(result or {})
    end)
    if not ok then cb({}) end
end)

RegisterNUICallback("usss:setAlertWaypoint", function(data, cb)
    cb({})
    if not data or not data.x or not data.y then return end
    SetNewWaypoint(data.x + 0.0, data.y + 0.0)
    VFW.ShowNotification({ type = "VERT", content = "Position mise sur le GPS" })
end)

-- ============================================================
-- USSS UNITS
-- ============================================================

RegisterNUICallback("usss:units:getData", function(_, cb)
    local ok, err = pcall(function()
        local result = TriggerServerCallback("usss:units:getData")
        cb(result or { matricule = nil, units = {}, myUnitId = nil })
    end)
    if not ok then cb({ matricule = nil, units = {}, myUnitId = nil }) end
end)

RegisterNUICallback("usss:units:createUnit", function(data, cb)
    if type(data) == "string" then data = json.decode(data) end
    TriggerServerEvent("usss:units:createUnit", data)
    cb({})
end)

RegisterNUICallback("usss:units:joinUnit", function(data, cb)
    if type(data) == "string" then data = json.decode(data) end
    TriggerServerEvent("usss:units:joinUnit", data)
    cb({})
end)

RegisterNUICallback("usss:units:leaveUnit", function(_, cb)
    TriggerServerEvent("usss:units:leaveUnit")
    cb({})
end)

RegisterNUICallback("usss:units:changeMatricule", function(data, cb)
    if type(data) == "string" then data = json.decode(data) end
    TriggerServerEvent("usss:units:changeMatricule", data)
    cb({})
end)

-- Listen for server-pushed unit updates
RegisterNetEvent("usss:units:updated", function(unitsData)
    SendNUIMessage({
        action = "nui:usss:unitsUpdated",
        data = unitsData
    })
end)

-- Keybind to open USSS MDT
RegisterCommand("openUSSSPanel", function()
    OpenUSSSPanel()
end, false)
