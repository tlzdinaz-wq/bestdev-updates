---@meta _
---@diagnostic disable: duplicate-doc-field

local POLICE_IMG = VFW.CDN.Get("entreprise/%s.png")

local isPanelOpen = false
local isPanelMinimized = false
local tabletProp = nil
local tabletAnimActive = false

local TABLET_DICT = "amb@world_human_seat_wall_tablet@female@base"
local TABLET_ANIM = "base"
local TABLET_PROP = "prop_cs_tablet"

local function StartTabletAnim()
    local ped = PlayerPedId()

    RequestAnimDict(TABLET_DICT)
    while not HasAnimDictLoaded(TABLET_DICT) do Wait(10) end

    RequestModel(TABLET_PROP)
    while not HasModelLoaded(TABLET_PROP) do Wait(10) end

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end

    tabletProp = CreateObject(GetHashKey(TABLET_PROP), 0.0, 0.0, 0.0, false, true, false)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422),
        -0.01, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )

    TaskPlayAnim(ped, TABLET_DICT, TABLET_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
    tabletAnimActive = true
end

local function StopTabletAnim()
    tabletAnimActive = false
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

-- Cleanup prop si la resource restart
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    StopTabletAnim()
end)

--- Open Police Panel (MDT)
VFW.Nui.policePanel = function(visible)
    if visible then
        local playerPermissions = TriggerServerCallback("police:getPlayerPermissions")

        if not VFW.PlayerData or not VFW.PlayerData.job then return end

        local playerName = (VFW.PlayerData.firstName or "") .. " " .. (VFW.PlayerData.lastName or "")
        local playerGrade = VFW.PlayerData.job.grade_label or VFW.PlayerData.job.grade

        local isBoss = VFW.PlayerData.job.grade_is_boss or (tonumber(VFW.PlayerData.job.grade) or 0) >= 98

        local mugshot = TriggerServerCallback("vfw:server:getMugshot")
        if not mugshot or mugshot == "" then
            mugshot = VFW.PlayerData.mugshot or ""
        end

        SendNUIMessage({
            action = "nui:PolicePanel:data",
            data = {
                job = VFW.PlayerData.job.name,
                jobLabel = VFW.PlayerData.job.label or VFW.PlayerData.job.name,
                playerGrade = playerGrade,
                playerName = playerName,
                playerMugshot = mugshot,
                permissions = playerPermissions or {},
                isBoss = isBoss,
                logo = POLICE_IMG:format(VFW.PlayerData.job.name),
            }
        })
    end

    SendNUIMessage({
        action = "nui:PolicePanel:visible",
        data = visible
    })

    VFW.Nui.Focus(visible)
    isPanelOpen = visible

    -- Immediate prop/anim cleanup on close
    if not visible then
        isPanelMinimized = false
        StopTabletAnim()
    end

    if visible then
        -- Boucle de desactivation des controles + minimize/restore (Espace)
        CreateThread(function()
            while isPanelOpen do
                if isPanelMinimized then
                    Wait(0)
                    if IsControlJustPressed(0, 22) then -- Space
                        isPanelMinimized = false
                        VFW.Nui.Focus(true)
                        StartTabletAnim()
                        SendNUIMessage({
                            action = "nui:PolicePanel:restore",
                            data = {}
                        })
                    end
                else
                    Wait(0)
                    DisableControlAction(0, 245, true) -- T (chat)
                end
            end
        end)

        -- Tablet prop + animation
        CreateThread(function()
            if not isPanelOpen then return end
            StartTabletAnim()

            -- Boucle de refresh anim (uniquement quand pas minimise)
            while isPanelOpen do
                if tabletAnimActive and not isPanelMinimized then
                    if not IsEntityPlayingAnim(PlayerPedId(), TABLET_DICT, TABLET_ANIM, 3) then
                        TaskPlayAnim(PlayerPedId(), TABLET_DICT, TABLET_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
                    end
                end
                Wait(500)
            end

            StopTabletAnim()
        end)
    end
end

function OpenPolicePanel()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({ type = "JOB", title = VFW.PlayerData.job.name or "sasp", subtitle = "Accès", image = VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png"), content = "Vous devez être en service" })
        return
    end

    if not IsLawEnforcementJob(VFW.PlayerData.job.name) then
        return
    end

    VFW.Nui.policePanel(true)
end

RegisterNuiCallback("nui:closePolicePanel", function(_, cb)
    VFW.Nui.policePanel(false)
    isPanelOpen = false
    isPanelMinimized = false
    cb("ok")
end)

-- Minimiser la tablette (retire le prop + anim)
RegisterNuiCallback("nui:PolicePanel:minimize", function(_, cb)
    if isPanelOpen and not isPanelMinimized then
        isPanelMinimized = true
        VFW.Nui.Focus(false)
        StopTabletAnim()
        SendNUIMessage({
            action = "nui:PolicePanel:minimized",
            data = {}
        })
    end
    cb("ok")
end)

-- Helper function to ensure data is decoded from JSON if needed
local function ensureDecoded(data)
    if data == nil or data == json.null then
        return nil
    end

    if type(data) == "string" then
        if string.sub(data, 1, 1) == "{" or string.sub(data, 1, 1) == "[" then
            local success, decoded = pcall(json.decode, data)
            if success then
                return decoded
            else
                return data
            end
        else
            return data
        end
    end

    return data
end

-- NUI Callbacks for police data
RegisterNuiCallback("police:getAllCitizens", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getAllCitizens", data or {})
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:searchCitizens", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:searchCitizens", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:searchVehicles", function(data, cb)
    data = ensureDecoded(data)
    local ok, response = pcall(TriggerServerCallback, "police:searchVehicles", data)
    if not ok or not response then
        cb({})
        return
    end

    for _, v in ipairs(response) do
        local hash = type(v.model) == "number" and v.model or joaat(tostring(v.model))
        local make = GetMakeNameFromVehicleModel(hash) or ""
        local name = GetLabelText(GetDisplayNameFromVehicleModel(hash)) or ""
        if make ~= "" and make ~= "NULL" and name ~= "" and name ~= "NULL" then
            v.model = make .. " " .. name
        elseif name ~= "" and name ~= "NULL" then
            v.model = name
        else
            v.model = "Inconnu"
        end
    end

    cb(response)
end)

RegisterNuiCallback("police:getCitizenProfile", function(data, cb)
    data = ensureDecoded(data)
    local ok, response = pcall(TriggerServerCallback, "police:getCitizenProfile", data)
    if not ok or not response then
        cb({})
        return
    end

    if response.vehicles then
        for _, v in ipairs(response.vehicles) do
            local hash = type(v.model) == "number" and v.model or joaat(tostring(v.model))
            local make = GetMakeNameFromVehicleModel(hash) or ""
            local name = GetLabelText(GetDisplayNameFromVehicleModel(hash)) or ""
            if make ~= "" and make ~= "NULL" and name ~= "" and name ~= "NULL" then
                v.model = make .. " " .. name
            elseif name ~= "" and name ~= "NULL" then
                v.model = name
            else
                v.model = "Inconnu"
            end
        end
    end

    cb(response)
end)

RegisterNuiCallback("police:getAuthoredCounts", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getAuthoredCounts", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getAuthoredRecords", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getAuthoredRecords", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getOfficers", function(data, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getOfficers")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

-- Bracelet tracking
local braceletBlipsActive = false

RegisterNuiCallback("police:getBraceletPlayers", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getBraceletPlayers", data)
        if response then
            for _, player in ipairs(response) do
                if player.online ~= false then
                    local streetHash, crossingHash = GetStreetNameAtCoord(player.x, player.y, player.z)
                    local street = GetStreetNameFromHashKey(streetHash)
                    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or nil
                    player.zone = crossing and (street .. " / " .. crossing) or street
                end
            end
        end
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("prison:getPrisoners", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getPrisoners")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("prison:release", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        if data and data.targetId then
            TriggerServerEvent("police:releasePrisoner", data.targetId)
        end
        cb("ok")
    end)
    if not ok then cb("error") end
end)

RegisterNuiCallback("prison:reduceSentence", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        if data and data.targetId and data.minutes then
            TriggerServerEvent("police:reduceSentence", data.targetId, data.minutes)
        end
        cb("ok")
    end)
    if not ok then cb("error") end
end)

RegisterNuiCallback("police:toggleBraceletBlips", function(data, cb)
    braceletBlipsActive = not braceletBlipsActive
    TriggerServerEvent("core:jobs:activeBlips", braceletBlipsActive)
    cb({ active = braceletBlipsActive })
end)

RegisterNuiCallback("police:braceletShock", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:braceletShock", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:braceletMessage", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:braceletMessage", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

-- MDT record reading callbacks
RegisterNuiCallback("police:getCitizenTrafficTickets", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenTrafficTickets", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getCitizenArrestReports", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenArrestReports", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getCitizenCriminalRecords", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenCriminalRecords", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getCitizenComplaints", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenComplaints", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getCitizenDepositions", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenDepositions", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

-- MDT record creation callbacks
RegisterNuiCallback("police:createTrafficTicket", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createTrafficTicket", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:createArrestReport", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createArrestReport", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:createCriminalRecord", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createCriminalRecord", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:createCriminalRecordBatch", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createCriminalRecordBatch", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:createComplaint", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createComplaint", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:createDeposition", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createDeposition", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

-- Intervention reports callbacks
RegisterNuiCallback("police:getCitizenInterventionReports", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenInterventionReports", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:createInterventionReport", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createInterventionReport", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

-- Seizure reports callbacks
RegisterNuiCallback("police:getCitizenSeizureReports", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenSeizureReports", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:createSeizureReport", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createSeizureReport", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:resolveMatricule", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:resolveMatricule", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:searchItems", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:searchItems", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

-- Warrants callbacks
RegisterNuiCallback("police:getWarrants", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getWarrants", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:createWarrant", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createWarrant", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:updateWarrantStatus", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:updateWarrantStatus", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:getMagistrates", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getMagistrates")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

-- Fines callbacks
RegisterNuiCallback("police:getFineTypes", function(data, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getFineTypes")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getCitizenFines", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getCitizenFines", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:createFine", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:createFine", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:getDossiers", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getDossiers")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getDossierDetail", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:getDossierDetail", data)
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:getDcpQuota", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getDcpQuota")
        cb(response or { allowed = false, remaining = 0 })
    end)
    if not ok then cb({ allowed = false, remaining = 0 }) end
end)

RegisterNuiCallback("police:deleteRecord", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:deleteRecord", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:editRecord", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:editRecord", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:cancelFine", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:cancelFine", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:togglePPA", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:togglePPA", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

-- Dashboard callbacks
RegisterNuiCallback("police:getDashboard", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getDashboard")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("police:addWantedVehicle", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:addWantedVehicle", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:removeWantedVehicle", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:removeWantedVehicle", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:addAnnouncement", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:addAnnouncement", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:removeAnnouncement", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:removeAnnouncement", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:isCitizenNearby", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local identifier = data and data.identifier
        if not identifier then cb({ nearby = false }) return end

        local nearby = false
        local myCoords = GetEntityCoords(PlayerPedId())

        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then
                local serverId = GetPlayerServerId(playerId)
                local ped = GetPlayerPed(playerId)
                if ped and DoesEntityExist(ped) then
                    local dist = #(myCoords - GetEntityCoords(ped))
                    if dist <= 10.0 then
                        -- Vérifier si c'est le bon citoyen via le serveur
                        local isMatch = TriggerServerCallback("police:checkCitizenIdentifier", serverId, identifier)
                        if isMatch then
                            nearby = true
                            break
                        end
                    end
                end
            end
        end

        cb({ nearby = nearby })
    end)
    if not ok then cb({ nearby = false }) end
end)

RegisterNuiCallback("police:addWantedNotice", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:addWantedNotice", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)

RegisterNuiCallback("police:removeWantedNotice", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:removeWantedNotice", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)


-- MDT Logs (boss only)
RegisterNuiCallback("police:getMdtLogs", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getMdtLogs")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

-- Settings: grade permissions
RegisterNuiCallback("police:getGradesPermissions", function(_, cb)
    local ok, err = pcall(function()
        local response = TriggerServerCallback("police:getGradesPermissions")
        cb(response or {})
    end)
    if not ok then
        print("[MDT] Error in getGradesPermissions: " .. tostring(err))
        cb({})
    end
end)

RegisterNuiCallback("police:updateGradePermissions", function(data, cb)
    local ok, err = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("police:updateGradePermissions", data)
        cb(response or { success = false })
    end)
    if not ok then
        print("[MDT] Error in updateGradePermissions: " .. tostring(err))
        cb({ success = false })
    end
end)

-- Refresh panel when permissions change (triggered by server)
RegisterNetEvent("police:refreshPanel", function()
    if isPanelOpen then
        VFW.Nui.policePanel(true)
    end
end)

-- Relay server-side citizen update to NUI
RegisterNetEvent("police:nui:citizenUpdated", function(identifier)
    SendNUIMessage({ action = "nui:citizen:updated", data = { identifier = identifier } })
end)

RegisterNuiCallback("police:getImpoundedVehicles", function(_, cb)
    local ok = pcall(function()
        local response = TriggerServerCallback("police:getImpoundedVehicles")
        if response then
            for _, v in ipairs(response) do
                local hash = type(v.model) == "number" and v.model or joaat(tostring(v.model))
                local make = GetMakeNameFromVehicleModel(hash) or ""
                local name = GetLabelText(GetDisplayNameFromVehicleModel(hash)) or ""
                if make ~= "" and make ~= "NULL" and name ~= "" and name ~= "NULL" then
                    v.model = make .. " " .. name
                elseif name ~= "" and name ~= "NULL" then
                    v.model = name
                else
                    v.model = "Inconnu"
                end
                v.firstname = v.owner_firstname
                v.lastname = v.owner_lastname
            end
        end
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("cayo_visa:milice:listVisaCitizens", function(_, cb)
    local ok = pcall(function()
        local response = TriggerServerCallback("cayo_visa:milice:listVisaCitizens")
        cb(response or {})
    end)
    if not ok then cb({}) end
end)

RegisterNuiCallback("cayo_visa:milice:updateExpiration", function(data, cb)
    local ok = pcall(function()
        data = ensureDecoded(data)
        local response = TriggerServerCallback("cayo_visa:milice:updateExpiration", data)
        cb(response or { success = false })
    end)
    if not ok then cb({ success = false }) end
end)
