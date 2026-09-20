local isTabletOpen = false

local function FormatJobsToArray(rawJobs)
    local result = {}
    if not rawJobs then return result end
    for jobName, jobData in pairs(rawJobs) do
        if jobName ~= "unemployed" then
            result[#result + 1] = { name = jobName, label = jobData.label or jobName }
        end
    end
    table.sort(result, function(a, b) return a.label < b.label end)
    return result
end

local function FormatZones(zones)
    local result = {}
    for i = 1, #zones do
        local z = zones[i]
        result[#result + 1] = {
            name = z.name,
            label = z.label,
            points = z.points or {},
            height = z.height or 10.0,
            actionDisabled = z.actionDisabled or {},
            bypassJob = z.bypassJob or {},
        }
    end
    return result
end

local function OpenSafeZoneTablet()
    if isTabletOpen then return end

    local pg = VFW.PlayerGlobalData
    if not pg or not pg.permissions then return end
    if not pg.permissions["zonesafe_builder"] then
        VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Zones Safe", message = "Pas la permission" })
        return
    end

    isTabletOpen = true

    local zones = TriggerServerCallback("core:getAllSafeZones") or {}
    local rawJobs = TriggerServerCallback("vfw:staff:getJobs") or {}
    local coords = GetEntityCoords(PlayerPedId())

    SendNUIMessage({
        action = "nui:adminSafeZones:open",
        data = {
            zones = FormatZones(zones),
            jobs = FormatJobsToArray(rawJobs),
            playerCoords = { x = coords.x, y = coords.y },
        }
    })

    VFW.Nui.Focus(true)
end

local function CloseSafeZoneTablet()
    if not isTabletOpen then return end
    isTabletOpen = false
    SendNUIMessage({ action = "nui:adminSafeZones:close" })
    VFW.Nui.Focus(false)
end

RegisterNUICallback("adminSafeZones:close", function(_, cb)
    CloseSafeZoneTablet()
    cb({})
end)

RegisterNUICallback("adminSafeZones:refreshData", function(_, cb)
    local zones = TriggerServerCallback("core:getAllSafeZones") or {}
    local rawJobs = TriggerServerCallback("vfw:staff:getJobs") or {}
    local coords = GetEntityCoords(PlayerPedId())
    cb({ zones = FormatZones(zones), jobs = FormatJobsToArray(rawJobs), playerCoords = { x = coords.x, y = coords.y } })
end)

RegisterNUICallback("adminSafeZones:create", function(data, cb)
    if not data or not data.name or not data.points or #data.points < 3 then
        cb({ success = false })
        return
    end

    local playerZ = GetEntityCoords(PlayerPedId()).z
    local points = {}
    for i = 1, #data.points do
        points[#points + 1] = {
            x = data.points[i].x,
            y = data.points[i].y,
            z = playerZ,
        }
    end

    TriggerServerEvent("zonesafe:server:create",
        data.name,
        data.label,
        points,
        data.height or 10.0,
        data.actionDisabled or {},
        data.bypassJob or {}
    )

    cb({ success = true })
end)

RegisterNUICallback("adminSafeZones:update", function(data, cb)
    if not data or not data.oldName or not data.name or not data.points or #data.points < 3 then
        cb({ success = false })
        return
    end

    local playerZ = GetEntityCoords(PlayerPedId()).z
    local points = {}
    for i = 1, #data.points do
        points[#points + 1] = {
            x = data.points[i].x,
            y = data.points[i].y,
            z = data.points[i].z or playerZ,
        }
    end

    TriggerServerEvent("zonesafe:server:update",
        data.oldName,
        data.name,
        data.label,
        points,
        data.height or 10.0,
        data.actionDisabled or {},
        data.bypassJob or {}
    )

    cb({ success = true })
end)

RegisterNUICallback("adminSafeZones:delete", function(data, cb)
    if not data or not data.name then
        cb({ success = false })
        return
    end

    TriggerServerEvent("zonesafe:server:delete", data.name)
    cb({ success = true })
end)

RegisterNUICallback("adminSafeZones:teleport", function(data, cb)
    cb({})
    if not data or not data.name then return end

    local zones = TriggerServerCallback("core:getAllSafeZones") or {}
    for i = 1, #zones do
        local zone = zones[i]
        if zone.name == data.name and zone.points and #zone.points >= 1 then
            local center = ZoneSafe:GetPolygonCenter(zone.points)
            local ped = PlayerPedId()
            SetEntityCoords(ped, center.x, center.y, 300.0, false, false, false, false)
            Wait(500)
            local found, groundZ = GetGroundZFor_3dCoord(center.x, center.y, 300.0, false)
            if found then
                SetEntityCoords(ped, center.x, center.y, groundZ + 1.0, false, false, false, false)
            else
                SetEntityCoords(ped, center.x, center.y, center.z + 1.0, false, false, false, false)
            end
            VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Zones Safe", message = "Téléporté au centre de " .. zone.label })
            break
        end
    end
end)

exports('OpenSafeZoneTablet', function()
    OpenSafeZoneTablet()
end)
