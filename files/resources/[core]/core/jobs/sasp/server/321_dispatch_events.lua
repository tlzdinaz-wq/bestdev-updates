VFW.JobsCommon = VFW.JobsCommon or {}
VFW.Dispatch = VFW.Dispatch or {}

local JC = VFW.JobsCommon
local Dispatch = VFW.Dispatch

local VEHICLE_CLASS_TYPE = {
    [8] = "moto",
    [13] = "bike",
    [14] = "boat",
    [15] = "heli",
    [16] = "heli",
}

local function vehicleTypeOf(vehicle)
    local class = GetVehicleClass(vehicle)
    return VEHICLE_CLASS_TYPE[class] or "car"
end

RegisterNetEvent("dispatch:saveUnitNumber", function(unitNumber)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local unit = JC.Str(unitNumber, 16)
    if not unit then return end
    unit = unit:gsub("%s+", "")
    if unit == "" then return end

    if not JC.Throttle(source, "dispatch:unitnumber", 500) then return end

    local record = Dispatch.EnsureUnit(xPlayer)
    if record.unitNumber == unit then return end

    record.unitNumber = unit
    record.job = xPlayer.job and xPlayer.job.name or record.job
    Dispatch.SaveUnit(record)

    if record.inService then Dispatch.PushUnits() end
end)

RegisterNetEvent("dispatch:server:setServiceState", function(inService, unitNumber)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Dispatch.IsAllowed(xPlayer) then return end

    if inService ~= nil and type(inService) ~= "boolean" then
        inService = inService == true or inService == 1
    end

    local record = Dispatch.EnsureUnit(xPlayer)
    record.inService = inService == true
    record.job = xPlayer.job and xPlayer.job.name or record.job

    local unit = JC.Str(unitNumber, 16)
    if unit then
        unit = unit:gsub("%s+", "")
        if unit ~= "" then record.unitNumber = unit end
    end

    Dispatch.SaveUnit(record)
    Dispatch.PushUnits()
end)

RegisterNetEvent("dispatch:server:updateUnitIcon", function(unitId, iconType)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    local id = JC.Int(unitId, 1)
    local icon = JC.Str(iconType, 32)
    if not id or not icon then return end

    local target = VFW.GetPlayerFromId(id)
    if target then
        local record = Dispatch.EnsureUnit(target)
        record.iconType = icon
        Dispatch.SaveUnit(record)
    end

    Dispatch.Broadcast("dispatch:client:updateUnitIcon", id, icon)
end)

RegisterNetEvent("dispatch:server:updateGroups", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    if type(data) ~= "table" then return end

    Dispatch.SaveGroups(xPlayer.job.name, data)
    Dispatch.Broadcast("dispatch:client:setGroups", data)
end)

local function pushCall(payload)
    local stored = Dispatch.StoreCall(payload)
    if PoliceAlertZones and PoliceAlertZones.BroadcastCall then
        PoliceAlertZones.BroadcastCall(stored)
    else
        Dispatch.Broadcast("dispatch:client:receiveNotification", stored)
    end
    return stored
end

Dispatch.PushCall = pushCall

RegisterNetEvent("dispatch:server:addCall", function(payload)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(payload) ~= "table" then return end
    if not Dispatch.IsAllowed(xPlayer) then return end

    if not JC.Throttle(source, "dispatch:addcall", 5000) then return end

    local coords = JC.Vec(payload.coords) or { x = 0.0, y = 0.0, z = 0.0 }
    local playerCoords = JC.Coords(source)
    if playerCoords then
        coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z }
    end

    local style = {}
    if type(payload.style) == "table" then
        style = {
            useGradient = payload.style.useGradient == true,
            color = JC.Str(payload.style.color, 32) or "#1e90ff",
            color2 = JC.Str(payload.style.color2, 32) or "#1e90ff",
        }
    end

    local record = Dispatch.EnsureUnit(xPlayer)

    local level = JC.Int(payload.level, 1, 3) or 1
    local clean = {
        type = JC.Str(payload.type, 32) or "backup",
        category = JC.Str(payload.category, 32) or "backup",
        level = level,
        code = level,
        icon = JC.Str(payload.icon, 32) or "fa-bell",
        jobName = JC.Str(payload.jobName, 64) or xPlayer.job.name,
        unitNumber = record.unitNumber ~= "" and record.unitNumber or tostring(source),
        street = JC.Str(payload.street, 128) or "",
        coords = coords,
        title = JC.Str(payload.title, 255) or "Appel",
        message = JC.Str(payload.message, 1000) or "",
        style = style,
        blipSprite = JC.Int(payload.blipSprite, 0, 900) or 161,
        blipColor = JC.Int(payload.blipColor, 0, 90) or 3,
        blipUseBig = payload.blipUseBig ~= false,
        blipBigSprite = JC.Int(payload.blipBigSprite, 0, 900) or 670,
        blipBigColor = JC.Int(payload.blipBigColor, 0, 90) or 3,
    }

    pushCall(clean)
end)

RegisterNetEvent("dispatch:server:gunshotAlert", function(data)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(data) ~= "table" then return end

    if not JC.Throttle(source, "dispatch:gunshot", 15000) then return end

    local coords = JC.Coords(source)
    if not coords then return end

    local street = JC.Str(data.street, 128) or "zone inconnue"

    pushCall({
        type = "gunshot",
        category = "gunshot",
        level = 2,
        code = 2,
        icon = "fa-gun",
        jobName = "",
        unitNumber = "",
        street = street,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        title = "Coups de feu",
        message = ("Coups de feu signales dans la <b>%s</b>"):format(street),
        style = { useGradient = true, color = "#0000006e", color2 = "#c235166e" },
        blipSprite = 313,
        blipColor = 1,
        blipUseBig = true,
        blipBigSprite = 670,
        blipBigColor = 1,
    })
end)

RegisterNetEvent("dispatch:server:assignAllUnits", function(notifId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    if not JC.Throttle(source, "dispatch:assignall", 1000) then return end

    local call = Dispatch.Call(notifId)
    if not call then return end

    local list = Dispatch.UnitList()
    for i = 1, #list do
        if list[i].unitNumber ~= "" then
            Dispatch.SetAssignment(call.id, list[i].unitNumber, "assigned")
        end
    end

    Dispatch.Broadcast("dispatch:client:updateAssignedUnits", call.id, Dispatch.CallAssignments(call.id))
    Dispatch.Broadcast("dispatch:client:setNotifWaypoint", call.coords)
end)

RegisterNetEvent("dispatch:server:notifyCallAccepted", function(notifId, matricule)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    local call = Dispatch.Call(notifId)
    if not call then return end

    local record = Dispatch.EnsureUnit(xPlayer)
    local unit = JC.Str(matricule, 16) or record.unitNumber
    if not unit or unit == "" then unit = tostring(source) end

    Dispatch.SetAssignment(call.id, unit, "accepted")
    Dispatch.Broadcast("dispatch:client:updateAssignedUnits", call.id, Dispatch.CallAssignments(call.id))
    Dispatch.Broadcast("dispatch:client:jobNotify", ("Appel n°%s pris en charge par %s"):format(call.id, unit))
end)

RegisterNetEvent("dispatch:server:notifyCallRejected", function(notifId, matricule)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end

    local call = Dispatch.Call(notifId)
    if not call then return end

    local record = Dispatch.EnsureUnit(xPlayer)
    local unit = JC.Str(matricule, 16) or record.unitNumber
    if not unit or unit == "" then unit = tostring(source) end

    Dispatch.SetAssignment(call.id, unit, "rejected")
    Dispatch.Broadcast("dispatch:client:updateAssignedUnits", call.id, Dispatch.CallAssignments(call.id))
end)

RegisterNetEvent("dispatch:server:notifyCallRemoved", function(notifId, matricule)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    if matricule ~= nil and type(matricule) ~= "string" and type(matricule) ~= "number" then return end

    local call = Dispatch.Call(notifId)
    if not call then return end

    Dispatch.RemoveCall(call.id)
    Dispatch.Broadcast("dispatch:client:removeNotification", call.id)
end)

RegisterNetEvent("dispatch:server:notifyAllCallsCleared", function(matricule)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return end
    if matricule ~= nil and type(matricule) ~= "string" and type(matricule) ~= "number" then return end

    if not JC.Throttle(source, "dispatch:clearall", 5000) then return end

    Dispatch.ClearCalls()
    Dispatch.Broadcast("dispatch:client:removeAllNotifications")
end)

JC.Cb("dispatch:getJobPositions", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return {} end

    local out = {}
    local players = VFW.GetPlayers()

    for i = 1, #players do
        local targetId = players[i]
        local target = VFW.GetPlayerFromId(targetId)

        if target and Dispatch.IsAllowed(target) then
            local unit = Dispatch.Unit(target.identifier)
            if unit and unit.inService then
                local ped = GetPlayerPed(targetId)
                if ped and ped ~= 0 and DoesEntityExist(ped) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                        local coords = GetEntityCoords(vehicle)
                        out[#out + 1] = {
                            id = ("unit_%d"):format(targetId),
                            coords = { x = coords.x, y = coords.y, z = coords.z },
                            ownerId = targetId,
                            job = target.job.name,
                            vehType = vehicleTypeOf(vehicle),
                            model = GetEntityModel(vehicle),
                            unitNumber = unit.unitNumber ~= "" and unit.unitNumber or nil,
                        }
                    end
                end
            end
        end
    end

    return out
end)

JC.Cb("dispatch:search", function(source, queryType, queryValue)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not Dispatch.IsAllowed(xPlayer) then return {} end

    local kind = JC.Str(queryType, 32) or "citizen"
    local value = JC.Str(queryValue, 64)
    if not value then return {} end

    local like = "%" .. value .. "%"

    if kind == "plate" or kind == "vehicle" or kind == "plaque" then
        local rows = JC.Query([[
            SELECT ov.plate, ov.vehName, ov.model, ov.label, ov.owner,
                   c.firstname, c.lastname
            FROM owned_vehicles ov
            LEFT JOIN characters c ON c.identifier = ov.owner
            WHERE ov.plate LIKE ? LIMIT 25
        ]], { like })

        local out = {}
        for i = 1, #rows do
            out[i] = {
                type = "plate",
                plate = rows[i].plate,
                model = rows[i].vehName ~= "" and rows[i].vehName or rows[i].model,
                label = rows[i].label or "",
                owner = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or ""),
            }
        end
        return out
    end

    local rows = JC.Query([[
        SELECT id, identifier, firstname, lastname, dateofbirth, sex, job, job_grade
        FROM characters
        WHERE firstname LIKE ? OR lastname LIKE ? OR CONCAT(firstname, ' ', lastname) LIKE ?
        LIMIT 25
    ]], { like, like, like })

    local out = {}
    for i = 1, #rows do
        out[i] = {
            type = "citizen",
            id = rows[i].id,
            identifier = rows[i].identifier,
            firstname = rows[i].firstname or "",
            lastname = rows[i].lastname or "",
            name = ("%s %s"):format(rows[i].firstname or "", rows[i].lastname or ""),
            dateofbirth = rows[i].dateofbirth or "",
            sex = rows[i].sex or "",
            job = rows[i].job or "",
            jobGrade = rows[i].job_grade or 0,
        }
    end
    return out
end)

local function purgeUnit(xPlayer)
    if not xPlayer then return end
    local record = Dispatch.Unit(xPlayer.identifier)
    if not record then return end
    if not record.inService then return end
    record.inService = false
    Dispatch.SaveUnit(record)
    Dispatch.PushUnits()
end

AddEventHandler("vfw:playerDropped", function(_, xPlayer)
    purgeUnit(xPlayer)
end)

AddEventHandler("vfw:setJob", function(playerSource)
    local src = playerSource
    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return end
    if Dispatch.IsAllowed(xPlayer) then return end
    purgeUnit(xPlayer)
end)

AddEventHandler("vfw:playerLoaded", function(playerSource)
    local src = playerSource
    CreateThread(function()
        Wait(4000)
        local xPlayer = VFW.GetPlayerFromId(src)
        if not xPlayer or not Dispatch.IsAllowed(xPlayer) then return end

        Dispatch.EnsureUnit(xPlayer)
        TriggerClientEvent("dispatch:client:setUnits", src, Dispatch.UnitList())
        TriggerClientEvent("dispatch:client:setGroups", src, Dispatch.Groups(xPlayer.job.name))
        TriggerClientEvent("d_dispatch:setBracelets", src, Dispatch.BraceletList and Dispatch.BraceletList() or {})
    end)
end)
