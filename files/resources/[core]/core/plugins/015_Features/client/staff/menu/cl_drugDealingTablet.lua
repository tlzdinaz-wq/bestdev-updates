local isTabletOpen = false
local pendingZonesData = nil

local function FormatZones(loadedZones)
    local result = {}
    if not loadedZones then return result end

    if loadedZones.allowed then
        for _, zone in ipairs(loadedZones.allowed) do
            zone.zoneType = "allowed"
          result[#result + 1] = zone
        end
    end

    if loadedZones.restricted then
        for _, zone in ipairs(loadedZones.restricted) do
            zone.zoneType = "restricted"
          result[#result + 1] = zone
        end
    end

    return result
end

local function FetchZones()
    pendingZonesData = nil
    TriggerServerEvent("core:drugdealing:admin:getZones")

    local timeout = 50
    while pendingZonesData == nil and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end

    return pendingZonesData or { allowed = {}, restricted = {} }
end

RegisterNetEvent("core:drugdealing:admin:zonesData")
AddEventHandler("core:drugdealing:admin:zonesData", function(zones)
    pendingZonesData = zones
end)

local function GetPolygonCenter(polygon)
    if not polygon or #polygon == 0 then return nil end
    local sumX, sumY = 0, 0
    for i = 1, #polygon do
        sumX = sumX + (polygon[i].x or 0)
        sumY = sumY + (polygon[i].y or 0)
    end
    return { x = sumX / #polygon, y = sumY / #polygon }
end

local function OpenDrugDealingTablet()
    if isTabletOpen then return end

    local pg = VFW.PlayerGlobalData
    if not pg or not pg.permissions then return end
    if not pg.permissions["builder_drug_dealing"] then
        VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Vente Drogue", message = "Pas la permission" })
        return
    end

    isTabletOpen = true

    local rawZones = FetchZones()
    local coords = GetEntityCoords(PlayerPedId())

    SendNUIMessage({
        action = "nui:adminDrugZones:open",
        data = {
            zones = FormatZones(rawZones),
            playerCoords = { x = coords.x, y = coords.y },
        }
    })

    VFW.Nui.Focus(true)
end

local function CloseDrugDealingTablet()
    if not isTabletOpen then return end
    isTabletOpen = false
    SendNUIMessage({ action = "nui:adminDrugZones:close" })
    VFW.Nui.Focus(false)
end

RegisterNUICallback("adminDrugZones:close", function(_, cb)
    CloseDrugDealingTablet()
    cb({})
end)

RegisterNUICallback("adminDrugZones:refreshData", function(_, cb)
    local rawZones = FetchZones()
    local coords = GetEntityCoords(PlayerPedId())
    cb({ zones = FormatZones(rawZones), playerCoords = { x = coords.x, y = coords.y } })
end)

RegisterNUICallback("adminDrugZones:create", function(data, cb)
    if not data or not data.name or not data.points or #data.points < 3 then
        cb({ success = false })
        return
    end

    TriggerServerEvent("core:drugdealing:admin:createZone", {
        name = data.name,
        zoneType = data.zoneType or "allowed",
        shape = "polygon",
        polygon = data.points,
    })

    Wait(500)
    cb({ success = true })
end)

RegisterNUICallback("adminDrugZones:delete", function(data, cb)
    if not data or not data.id then
        cb({ success = false })
        return
    end

    TriggerServerEvent("core:drugdealing:admin:deleteZone", data.id)
    cb({ success = true })
end)

RegisterNUICallback("adminDrugZones:toggleActive", function(data, cb)
    if not data or not data.id then
        cb({ success = false })
        return
    end

    TriggerServerEvent("core:drugdealing:admin:updateZone", data.id, "active", data.active)
    cb({ success = true })
end)

RegisterNUICallback("adminDrugZones:teleport", function(data, cb)
    cb({})
    if not data or not data.id then return end

    local rawZones = FetchZones()
    local allZones = FormatZones(rawZones)

    for i = 1, #allZones do
        local zone = allZones[i]
        if zone.id == data.id then
            local center = nil

            if zone.shape == "circle" and zone.center then
                center = zone.center
            elseif zone.shape == "polygon" and zone.polygon and #zone.polygon >= 1 then
                center = GetPolygonCenter(zone.polygon)
            end

            if center then
                local ped = PlayerPedId()
                SetEntityCoords(ped, center.x, center.y, 300.0, false, false, false, false)
                Wait(500)
                local found, groundZ = GetGroundZFor_3dCoord(center.x, center.y, 300.0, false)
                if found then
                    SetEntityCoords(ped, center.x, center.y, groundZ + 1.0, false, false, false, false)
                else
                    SetEntityCoords(ped, center.x, center.y, (center.z or 30.0) + 1.0, false, false, false, false)
                end
                VFW.ShowNotification({ type = "STAFF", variant = "INFO", subtitle = "Vente Drogue", message = "Téléporté au centre de " .. zone.name })
            end
            break
        end
    end
end)

exports('OpenDrugDealingTablet', function()
    OpenDrugDealingTablet()
end)
