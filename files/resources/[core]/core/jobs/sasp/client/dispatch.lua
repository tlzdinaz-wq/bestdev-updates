local ESX = VFW

local dispatchOpen = false
local lastGunshotAlert = 0
local GUNSHOT_COOLDOWN = 15000
local DispatchBlips = {}
local dispatchMuted = false
local positionBlipsEnabled = false
local PositionBlips = {}
local lastVehType = nil
local VehicleBlipOverrides = nil
local braceletPingBlip = nil
local braceletProp = nil

local function CreateBraceletPingBlip(coords)
    if not coords or not coords.x or not coords.y then
        return
    end

    if braceletPingBlip and DoesBlipExist(braceletPingBlip) then
        RemoveBlip(braceletPingBlip)
        braceletPingBlip = nil
    end

    local cfg    = Config.BraceletPingBlip or {}
    local sprite = cfg.sprite or 480
    local color  = cfg.color  or 1
    local scale  = cfg.scale  or 1.0
    local label  = cfg.label  or "Bracelet électronique"

    braceletPingBlip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, (coords.z or 0.0) + 0.0)

    SetBlipSprite(braceletPingBlip, sprite)
    SetBlipColour(braceletPingBlip, color)
    SetBlipScale(braceletPingBlip, scale)
    SetBlipAsShortRange(braceletPingBlip, false)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(braceletPingBlip)

    CreateThread(function()
        Wait(15000)
        if braceletPingBlip and DoesBlipExist(braceletPingBlip) then
            RemoveBlip(braceletPingBlip)
        end
        braceletPingBlip = nil
    end)
end

local function DeleteBraceletProp()
    if braceletProp and DoesEntityExist(braceletProp) then
        DeleteEntity(braceletProp)
    end
    braceletProp = nil
end

local function SpawnBraceletProp()
    DeleteBraceletProp()

    if not Config.Bracelet or Config.Bracelet.Mode ~= "prop" then
        return
    end

    local ped = PlayerPedId()
    local cfg = Config.Bracelet.Prop
    if not cfg or not cfg.model then return end

    local model = GetHashKey(cfg.model)
    if not IsModelInCdimage(model) then
        print("[Bracelet] Model introuvable :", cfg.model)
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    braceletProp = CreateObject(model, 0.0, 0.0, 0.0, false, true, false)
    SetEntityCollision(braceletProp, false, false)
    SetEntityCompletelyDisableCollision(braceletProp, true, true)
    SetEntityInvincible(braceletProp, true)
    SetEntityProofs(braceletProp, true, true, true, true, true, true, true, true)

    local bone = cfg.bone or 14201
    local pos  = cfg.pos  or vector3(0.0, 0.0, 0.0)
    local rot  = cfg.rot  or vector3(0.0, 0.0, 0.0)

    AttachEntityToEntity(
        braceletProp, ped, GetPedBoneIndex(ped, bone),
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(model)
end

local BraceletComponentIndexes = {
    mask       = 1,
    face       = 0,
    hair       = 2,
    arms       = 3,
    legs       = 4,
    bags       = 5,
    shoes      = 6,
    accessories= 7,
    undershirt = 8,
    bodyarmor  = 9,
    decals     = 10,
    tops       = 11,
}

local function IsFreemodeModel(model)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

local function GetBraceletPedData()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return nil end

    local cfg = Config.Bracelet and Config.Bracelet.Clothes
    if not cfg then return nil end

    local model = GetEntityModel(ped)
    if not IsFreemodeModel(model) then
        print("[Bracelet] Ped n'est pas un freemode, on n'applique pas les vêtements")
        return nil
    end

    local isMale = (model == `mp_m_freemode_01`)
    local data = isMale and cfg.male or cfg.female
    if not data then return nil end

    local compKey = data.componentKey or "mask"
    local compIdx = BraceletComponentIndexes[compKey] or 1

    return {
        ped      = ped,
        compIdx  = compIdx,
        drawable = data.drawable or 0,
        texture  = data.texture or 0
    }
end

local function GetBraceletClearData()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return nil end

    local cfg = Config.Bracelet and Config.Bracelet.Clothes
    if not cfg or not cfg.Clear then return nil end

    local model = GetEntityModel(ped)
    if not IsFreemodeModel(model) then
        print("[Bracelet] Ped n'est pas un freemode (clear), on n'y touche pas")
        return nil
    end

    local clear = cfg.Clear
    local compKey = clear.componentKey or "mask"
    local compIdx = BraceletComponentIndexes[compKey] or 1

    return {
        ped      = ped,
        compIdx  = compIdx,
        drawable = clear.drawable or 0,
        texture  = clear.texture or 0
    }
end

local function ApplyBraceletClothes()
    if not Config.Bracelet or Config.Bracelet.Mode ~= "clothes" then
        return
    end

    local info = GetBraceletPedData()
    if not info then
        print("[Bracelet] Pas d'info ped")
        return
    end

    SetPedComponentVariation(
        info.ped,
        info.compIdx,
        info.drawable,
        info.texture,
        0
    )
end

local function ClearBraceletClothes()
    if not Config.Bracelet or Config.Bracelet.Mode ~= "clothes" then
        return
    end

    local info = GetBraceletClearData()
    if not info then return end

    SetPedComponentVariation(
        info.ped,
        info.compIdx,
        info.drawable,
        info.texture,
        0
    )
end

local function BuildVehicleBlipOverrides()
    VehicleBlipOverrides = {}

    if not Config.TrackedVehicles then
        return
    end

    for job, list in pairs(Config.TrackedVehicles) do
        if type(list) == "table" then
            VehicleBlipOverrides[job] = {}
            for _, v in ipairs(list) do
                if type(v) == "table" and v.model then
                    local hash = GetHashKey(v.model)
                    VehicleBlipOverrides[job][hash] = {
                        sprite = v.sprite,
                        color  = v.color,
                        scale  = v.scale,
                    }
                end
            end
        end
    end
end

local function PlayDispatchBaseSound()
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", false)
end

local function RemoveDispatchBlip(notifId)
    if not notifId then return end

    local entry = DispatchBlips[notifId]
    if not entry then return end

    if type(entry) == "table" then
        for _, blip in pairs(entry) do
            if blip and DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    else
        if entry and DoesBlipExist(entry) then
            RemoveBlip(entry)
        end
    end

    DispatchBlips[notifId] = nil
end

local function RemoveAllDispatchBlips()
    for id, entry in pairs(DispatchBlips) do
        if type(entry) == "table" then
            for _, blip in pairs(entry) do
                if blip and DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
        else
            if entry and DoesBlipExist(entry) then
                RemoveBlip(entry)
            end
        end
    end
    DispatchBlips = {}
end

local function CreateDispatchBlip(notif)
    if not notif or not notif.coords or not notif.coords.x or not notif.coords.y then
        return
    end

    local x = notif.coords.x + 0.0
    local y = notif.coords.y + 0.0
    local z = (notif.coords.z or 0.0) + 0.0

    local id = notif.alertId or notif.id
    if not id then
        return
    end

    local blipSet = {}

    local sprite   = notif.blipSprite or nil
    local color    = notif.blipColor or 0
    local bigColor = notif.blipBigColor or color

    if notif.blipUseBig then
        local radiusBlip = AddBlipForRadius(x, y, z, 20.0)
        SetBlipColour(radiusBlip, bigColor)
        SetBlipAlpha(radiusBlip, 120)
        blipSet.big = radiusBlip
    end

    if sprite then
        local blip = AddBlipForCoord(x, y, z)
        SetBlipSprite(blip, sprite)
        SetBlipColour(blip, color)
        SetBlipScale(blip, 0.5)
        SetBlipAsShortRange(blip, false)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(notif.title or "Alerte")
        EndTextCommandSetBlipName(blip)

        blipSet.main = blip
        SetBlipAlpha(blip, 255)
    end

    if next(blipSet) ~= nil then
        DispatchBlips[id] = blipSet
    end
end

local function GetJobLabel()
    local data = ESX.GetPlayerData()
    if data and data.job then
        local jobName = data.job.name
        local jobLabel = data.job.label

        if Config.JobLabels and Config.JobLabels[jobName] then
            return Config.JobLabels[jobName]
        end

        return jobLabel or jobName or "Inconnu"
    end

    return "Inconnu"
end

local function CloseDispatch()
    if not dispatchOpen then return end

    dispatchOpen = false

    VFW.Nui.Focus(false)

    SendNUIMessage({
        action = 'close'
    })
end

local function OpenDispatch()
    if dispatchOpen then return end

    local data = ESX.GetPlayerData()
    local job  = data and data.job and data.job.name

    if not job or not Config.AllowedJobs[job] then
        ESX.ShowNotification("~r~Vous n'avez pas l'autorisation nécessaire pour cela")
        return
    end

    dispatchOpen = true

    VFW.Nui.Focus(true, true)

    local jobLabel = GetJobLabel()

    SendNUIMessage({
        action = 'open'
    })

    SendNUIMessage({
        action = 'setJob',
        jobName = jobLabel
    })

    if Config.GroupCodes then
        SendNUIMessage({
            action = 'setGroupCodes',
            codes  = Config.GroupCodes
        })
    end

    if Config.AdvancedSearchPalettes then
        SendNUIMessage({
            action   = 'setAdvancedPalettes',
            palettes = Config.AdvancedSearchPalettes
        })
    end

    ESX.TriggerServerCallback('dispatch:getUnitNumber', function(savedUnit)
        if savedUnit and savedUnit ~= "" then
            SendNUIMessage({
                action     = 'setUnitNumber',
                unitNumber = savedUnit
            })
        end
    end)

    CreateThread(function()
        while dispatchOpen do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 143, true)
            Wait(0)
        end
    end)
end

local function IsDispatchNotification(msg)
    msg = tostring(msg or ""):lower()
    return msg:find("appel n°") 
        or msg:find("alertes") 
        or msg:find("backup")
        or msg:find("coup de feu")
end

local function ClearPositionBlips()
    for id, blip in pairs(PositionBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    PositionBlips = {}
end

local function DetectVehTypeFromServerId(serverId)
    if not serverId then return nil end

    local player = GetPlayerFromServerId(serverId)
    if player == -1 then
        return nil
    end

    local ped = GetPlayerPed(player)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        return nil
    end

    local class = GetVehicleClass(veh)

    if class == 15 then
        return "heli"
    elseif class == 14 then
        return "boat"
    elseif class == 8 then
        return "moto"
    elseif class == 13 then
        return "bike"
    else
        return "car"
    end
end

local function GetJobBlipSpriteAndColor(job, vehType, vehModel)
    if not VehicleBlipOverrides then
        BuildVehicleBlipOverrides()
    end

    local overrideSprite, overrideColor, overrideScale

    if vehModel and VehicleBlipOverrides and VehicleBlipOverrides[job] then
        local ov = VehicleBlipOverrides[job][vehModel]
        if ov then
            overrideSprite = ov.sprite
            overrideColor  = ov.color
            overrideScale  = ov.scale
        end
    end

    local cfg     = Config.JobBlips and Config.JobBlips[job] or nil
    local color   = overrideColor or (cfg and cfg.color) or 3
    local sprites = cfg and cfg.sprites or {}

    local sprite
    if overrideSprite then
        sprite = overrideSprite
    elseif vehType and sprites[vehType] then
        sprite = sprites[vehType]
    elseif sprites.car then
        sprite = sprites.car
    else
        sprite = 56
    end

    local scale = overrideScale or 0.9

    return sprite, color, scale
end

local function GetPatrolLabel(vehType)
    if vehType == "heli" then
        return "Hélico de patrouille"
    elseif vehType == "moto" then
        return "Moto de patrouille"
    elseif vehType == "boat" then
        return "Bateau de patrouille"
    else
        return "Véhicule de patrouille"
    end
end

local function GetPatrolBlipLabel(u)
    local vehType     = u.vehType or "car"
    local patrolLabel = GetPatrolLabel(vehType)
    local unitNumber  = u.unitNumber

    if unitNumber and unitNumber ~= "" then
        return ("[%s] %s"):format(unitNumber, patrolLabel)
    else
        return patrolLabel
    end
end

local function UpdatePositionBlips(list)
    local activeIds = {}
    local myId = GetPlayerServerId(PlayerId())

    for _, u in ipairs(list) do
        local id      = u.id
        local coords  = u.coords
        local ownerId = u.ownerId

        if id and coords and ownerId ~= myId then
            activeIds[id] = true

            local blip = PositionBlips[id]
            local sprite, color, scale = GetJobBlipSpriteAndColor(u.job, u.vehType or "car", u.model)
            local label = GetPatrolBlipLabel(u)

            if not blip or not DoesBlipExist(blip) then
                blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
                SetBlipSprite(blip, sprite)
                SetBlipColour(blip, color)
                SetBlipScale(blip, scale)
                SetBlipAsShortRange(blip, false)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(label)
                EndTextCommandSetBlipName(blip)

                PositionBlips[id] = blip
            else
                SetBlipSprite(blip, sprite)
                SetBlipColour(blip, color)
                SetBlipScale(blip, scale)
                SetBlipCoords(blip, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end

    for id, blip in pairs(PositionBlips) do
        if not activeIds[id] then
            if blip and DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            PositionBlips[id] = nil
        end
    end
end

CreateThread(function()
    while true do
        if positionBlipsEnabled then
            local data = ESX.GetPlayerData()
            local job  = data and data.job and data.job.name or nil

            if job then
                ESX.TriggerServerCallback('dispatch:getJobPositions', function(list)
                    if positionBlipsEnabled then
                        UpdatePositionBlips(list or {})
                    end
                end)
            end

            Wait(2500)
        else
            Wait(1000)
        end
    end
end)

RegisterNUICallback('togglePositions', function(data, cb)
    if data and data.enabled ~= nil then
        positionBlipsEnabled = data.enabled == true
    else
        positionBlipsEnabled = not positionBlipsEnabled
    end

    if not positionBlipsEnabled then
        ClearPositionBlips()
    end

    cb('ok')
end)

RegisterNetEvent('dispatch:client:jobNotify', function(msg)
    if dispatchMuted then
        return
    end

    ESX.ShowNotification(msg)
end)

RegisterNUICallback('saveUnitNumber', function(data, cb)
    local unitNumber = tostring(data.unitNumber or ""):gsub("%s+", "")
    if unitNumber ~= "" then
        TriggerServerEvent('dispatch:saveUnitNumber', unitNumber)
    end
    cb('ok')
end)


RegisterNetEvent('d_dispatch:setBracelets', function(list)
    SendNUIMessage({
        action    = "setBracelets",
        bracelets = list
    })
end)

RegisterNetEvent('d_dispatch:addBracelet', function(b)
    SendNUIMessage({
        action   = "addBracelet",
        bracelet = b
    })
end)

RegisterNetEvent('d_dispatch:updateBracelet', function(b)
    SendNUIMessage({
        action   = "updateBracelet",
        bracelet = b
    })
end)

RegisterNetEvent('d_dispatch:removeBracelet', function(id)
    SendNUIMessage({
        action = "removeBracelet",
        id     = id
    })
end)

RegisterNUICallback('updateBracelet', function(data, cb)
    if not data or not data.id then
        cb({})
        return
    end

    TriggerServerEvent('dispatch_bracelet:updateBracelet', data.id, {
        name         = data.name or "",
        reason       = data.reason or "",
        description  = data.description or "",
        paletteIndex = data.paletteIndex or 0
    })
    cb({})
end)

RegisterNUICallback('braceletPing', function(data, cb)
    local id = tonumber(data.id)
    if id then
        TriggerServerEvent('dispatch_bracelet:ping', id)
    end
    cb({})
end)

RegisterNUICallback('braceletRemove', function(data, cb)
    local id = tonumber(data.id)
    if id then
        TriggerServerEvent('dispatch_bracelet:removeBracelet', id)
    end
    cb({})
end)

RegisterNetEvent('dispatch:client:removeNotification', function(notifId)
    RemoveDispatchBlip(notifId)

    SendNUIMessage({
        action = 'removeNotification',
        notifId = notifId
    })
end)

RegisterNetEvent('dispatch:client:removeAllNotifications', function()
    RemoveAllDispatchBlips()

    SendNUIMessage({
        action = 'removeAllNotifications'
    })
end)

RegisterNetEvent('dispatch:client:updateAssignedUnits', function(notifId, assignments)
    SendNUIMessage({
        action = 'updateAssignedUnits',
        notifId = notifId,
        assignments = assignments or {}
    })
end)

local function ToggleDispatch()
    if dispatchOpen then
        CloseDispatch()
    else
        OpenDispatch()
    end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) or not IsPedArmed(ped, 4) then
            Wait(500)
            goto continue
        end

        Wait(50)

        if IsPedShooting(ped) then
            local now = GetGameTimer()

            if now - lastGunshotAlert > GUNSHOT_COOLDOWN then
                lastGunshotAlert = now

                local coords = GetEntityCoords(ped)
                local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                local streetName = GetStreetNameFromHashKey(streetHash) or "inconnue"

                TriggerServerEvent('dispatch:server:gunshotAlert', {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    street = streetName
                })
            end
        end

        ::continue::
    end
end)

RegisterCommand('opendispatch', function()
    ToggleDispatch()
end, false)

-- RegisterKeyMapping('opendispatch', 'Ouvrir le Dispatch', 'keyboard', Config.OpenKey)

RegisterNetEvent('ddispatch:setServiceStatus')
AddEventHandler('ddispatch:setServiceStatus', function(status)
    SendNUIMessage({
        action = 'setServiceFromF1',
        inService = status
    })
end)

RegisterNetEvent('ddispatch:setUnitNumber')
AddEventHandler('ddispatch:setUnitNumber', function(unitNum)
    if unitNum and unitNum ~= "" then
        TriggerServerEvent('dispatch:saveUnitNumber', unitNum)
        
        SendNUIMessage({
            action = 'setUnitNumber',
            unitNumber = unitNum
        })
    end
end)

CreateThread(function()
    while true do
        if dispatchOpen then
            if IsControlJustPressed(0, 322) then
                CloseDispatch()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterNUICallback('close', function(data, cb)
    CloseDispatch()
    cb('ok')
end)

RegisterNUICallback('requestUnits', function(data, cb)
    ESX.TriggerServerCallback('dispatch:getUnits', function(units)
        SendNUIMessage({
            action = 'setUnits',
            units = units
        })
        cb('ok')
    end)
end)

RegisterNetEvent('dispatch:client:setUnits', function(units)
    SendNUIMessage({
        action = 'setUnits',
        units  = units or {}
    })
end)

RegisterNUICallback("setServiceState", function(data, cb)
    local inService  = data.inService
    local unitNumber = data.unitNumber

    TriggerServerEvent("dispatch:server:setServiceState", inService, unitNumber)

    if cb then
        cb({ ok = true })
    end
end)

RegisterNUICallback('searchQuery', function(data, cb)
    local queryType = data.type
    local queryValue = data.value

    ESX.TriggerServerCallback('dispatch:search', function(result)
        SendNUIMessage({
            action = 'searchResult',
            result = result
        })
        cb('ok')
    end, queryType, queryValue)
end)

RegisterNUICallback('requestNotifications', function(data, cb)
    ESX.TriggerServerCallback('dispatch:getNotifications', function(result)
        SendNUIMessage({
            action        = 'setNotifications',
            notifications = result.notifications or {},
            assignments   = result.assignments or {}
        })
        cb('ok')
    end)
end)

RegisterNUICallback('requestBracelets', function(data, cb)
    ESX.TriggerServerCallback('dispatch:getBracelets', function(list)
        SendNUIMessage({
            action = 'setBracelets',
            bracelets = list
        })
        cb('ok')
    end)
end)

RegisterNetEvent('dispatch:client:receiveNotification', function(data)
    EndTextCommandThefeedPostTicker(false, true)

    local isBackup = data.category == 'backup' or data.type == 'backup'
    local level    = data.level or data.backupLevel or 1

    if dispatchMuted then
        if dispatchOpen then
            SendNUIMessage({
                action = 'pushNotification',
                notification = data
            })
        end
        return
    end

    if isBackup and level == 3 then
        SendNUIMessage({
            action = 'playBackup3Sound'
        })
    else
        PlayDispatchBaseSound()
    end

    CreateDispatchBlip(data)

    if dispatchOpen then
        SendNUIMessage({
            action = 'pushNotification',
            notification = data
        })
    else
        SendNUIMessage({
            action       = 'tempNotification',
            notification = data,
            duration     = 5000
        })
    end
end)

RegisterNUICallback('notificationAction', function(data, cb)
    local action    = data.action
    local notifId   = data.notifId
    local coords    = data.coords
    local matricule = data.matricule or nil

    if action == 'assignAllUnits' then
        if notifId then
            TriggerServerEvent('dispatch:server:assignAllUnits', notifId)
        end

    elseif action == 'accept' then
        if coords and coords.x and coords.y then
            SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
        end

        if notifId then
            TriggerServerEvent('dispatch:server:notifyCallAccepted', notifId, matricule)
        end

    elseif action == 'reject' then
        if notifId then
            TriggerServerEvent('dispatch:server:notifyCallRejected', notifId, matricule)
        end

    elseif action == 'remove' then
        if notifId then
            RemoveDispatchBlip(notifId)
            TriggerServerEvent('dispatch:server:notifyCallRemoved', notifId, matricule)
        end

    elseif action == 'removeAll' then
        RemoveAllDispatchBlips()
        TriggerServerEvent('dispatch:server:notifyAllCallsCleared', matricule)

    end

    cb('ok')
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if dispatchOpen then
            VFW.Nui.Focus(false)
        end
    end
end)

CreateThread(function()
    Wait(1000)
    dispatchOpen = false
    VFW.Nui.Focus(false)
    SendNUIMessage({ action = 'close' })
end)

local function HandleBackupSignal(level, style, data, cb)
    local unitNumber = data.unitNumber or ""
    local jobName    = data.jobName or GetJobLabel()

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash) or "zone inconnue"

    local unit = unitNumber ~= "" and unitNumber or tostring(GetPlayerServerId(PlayerId()))

    local title   = ("Backup %s niveau %d"):format(jobName, level)
    local message = ("Besoin d'aide dans la <b>%s</b> par l'agent <b>%s</b>"):format(streetName, unit)

    local uiStyle = {
        useGradient = style.useGradient or false,
        color       = style.color or "#1e90ff",
        color2      = style.color2 or style.color or "#1e90ff"
    }

    local blipSprite    = style.blipSprite    or 161
    local blipColor     = style.blipColor     or 3
    local blipBigSprite = style.blipBigSprite or 670
    local blipBigColor  = style.blipBigColor  or blipColor

    local payload = {
        type       = "backup",
        category   = "backup",

        level      = level,
        code       = level,
        icon       = "fa-bell",

        jobName    = jobName,
        unitNumber = unit,
        street     = streetName,
        coords     = { x = coords.x, y = coords.y, z = coords.z },

        title      = title,
        message    = message,

        style         = uiStyle,

        blipSprite    = blipSprite,
        blipColor     = blipColor,

        blipUseBig    = true,
        blipBigSprite = blipBigSprite,
        blipBigColor  = blipBigColor,
    }

    ExecuteCommand('me fait une demande de backup')
    TriggerServerEvent('dispatch:server:addCall', payload)
    cb("ok")
end

RegisterNUICallback('backupSignal1', function(data, cb)
    HandleBackupSignal(1, {
        useGradient   = true,
        color         = "#0000006e",
        color2        = "#109c2360",
        blipSprite    = 309,
        blipColor     = 2,
        blipBigSprite = 670,
        blipBigColor  = 2,
    }, data, cb)
end)

RegisterNUICallback('backupSignal2', function(data, cb)
    HandleBackupSignal(2, {
        useGradient   = true,
        color         = "#0000006e",
        color2        = "#c586116e",
        blipSprite    = 309,
        blipColor     = 46,
        blipBigSprite = 670,
        blipBigColor  = 46,
    }, data, cb)
end)

RegisterNUICallback('backupSignal3', function(data, cb)
    HandleBackupSignal(3, {
        useGradient   = true,
        color         = "#0000006e",
        color2        = "#c235166e",
        blipSprite    = 309,
        blipColor     = 1,
        blipBigSprite = 670,
        blipBigColor  = 1,
    }, data, cb)
end)

RegisterNetEvent('dispatch:client:setNotifWaypoint', function(coords)
    if coords and coords.x and coords.y then
        SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
    end
end)

RegisterNUICallback('setMuted', function(data, cb)
    dispatchMuted = data.muted == true
    cb('ok')
end)

RegisterNUICallback('updateGroups', function(data, cb)
    local groups = data.groups or {}
    TriggerServerEvent('dispatch:server:updateGroups', groups)
    cb('ok')
end)

RegisterNetEvent('dispatch:client:setGroups', function(groups)
    SendNUIMessage({
        action = 'setGroups',
        groups = groups or {}
    })
end)

RegisterNetEvent('dispatch:client:updateUnitIcon', function(unitId, iconType)
    SendNUIMessage({
        action  = 'updateUnitIcon',
        unitId  = unitId,
        iconType = iconType
    })
end)

RegisterNUICallback('updateUnitIcon', function(data, cb)
    local unitId = tonumber(data.unitId)
    local iconType = data.iconType
    if unitId and iconType then
        TriggerServerEvent('dispatch:server:updateUnitIcon', unitId, iconType)
    end
    cb('ok')
end)

RegisterNUICallback("requestAdvancedRecords", function(data, cb)
    TriggerServerEvent("dispatch:server:requestAdvancedRecords")
    if cb then cb({ ok = true }) end
end)

RegisterNetEvent("dispatch:client:setAdvancedRecords", function(records)
    SendNUIMessage({
        action = "setAdvancedRecords",
        records = records or {}
    })
end)

RegisterNetEvent("dispatch:client:addAdvancedRecord", function(record)
    SendNUIMessage({
        action = "addAdvancedRecord",
        record = record or {}
    })
end)

RegisterNUICallback("advancedSearchUpdate", function(data, cb)
    TriggerServerEvent("dispatch:server:updateAdvancedRecord", data)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("advancedSearchDelete", function(data, cb)
    TriggerServerEvent("dispatch:server:deleteAdvancedRecord", data.id)
    if cb then cb({ ok = true }) end
end)

RegisterNetEvent("dispatch:client:updateAdvancedRecord", function(record)
    SendNUIMessage({
        action = "updateAdvancedRecord",
        record = record
    })
end)

RegisterNetEvent("dispatch:client:removeAdvancedRecord", function(id)
    SendNUIMessage({
        action = "removeAdvancedRecord",
        id = id
    })
end)

RegisterNUICallback("advancedSearchAdd", function(data, cb)
    TriggerServerEvent("dispatch:server:addAdvancedRecord", data)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("requestAdvancedRecords", function(data, cb)
    TriggerServerEvent("dispatch:server:requestAdvancedRecords")
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("advancedSearchAddCitizen", function(data, cb)
    TriggerServerEvent("dispatch:server:addAdvancedRecordCitizen", data)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("requestAdvancedRecordsCitizen", function(data, cb)
    TriggerServerEvent("dispatch:server:requestAdvancedRecordsCitizen")
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("advancedSearchUpdateCitizen", function(data, cb)
    TriggerServerEvent("dispatch:server:updateAdvancedRecordCitizen", data)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("advancedSearchDeleteCitizen", function(data, cb)
    TriggerServerEvent("dispatch:server:deleteAdvancedRecordCitizen", data.id)
    if cb then cb({ ok = true }) end
end)

RegisterNetEvent("dispatch:client:setAdvancedRecordsCitizen", function(records)
    SendNUIMessage({
        action = "setAdvancedRecordsCitizen",
        records = records or {}
    })
end)

RegisterNetEvent("dispatch:client:addAdvancedRecordCitizen", function(record)
    SendNUIMessage({
        action = "addAdvancedRecordCitizen",
        record = record or {}
    })
end)

RegisterNetEvent("dispatch:client:updateAdvancedRecordCitizen", function(record)
    SendNUIMessage({
        action = "updateAdvancedRecordCitizen",
        record = record or {}
    })
end)

RegisterNetEvent("dispatch:client:removeAdvancedRecordCitizen", function(id)
    SendNUIMessage({
        action = "removeAdvancedRecordCitizen",
        id = id
    })
end)

RegisterNetEvent('dispatch_bracelet:clientApplyBracelet', function()
    ApplyBraceletClothes()

    if Config.Bracelet and Config.Bracelet.Mode == "prop" then
        SpawnBraceletProp()
    end
end)

RegisterNetEvent('dispatch_bracelet:clientRemoveBracelet', function()
    DeleteBraceletProp()
    ClearBraceletClothes()
end)

RegisterNetEvent('dispatch_bracelet:clientPingBlip', function(coords)
    CreateBraceletPingBlip(coords)
end)

-- ====== POLICE ACTIONS CLIENT ======

RegisterNetEvent('dispatch:client:toggleCuffs')
AddEventHandler('dispatch:client:toggleCuffs', function()
    local ped = PlayerPedId()
    -- Toggle handcuff animation
    if IsEntityPlayingAnim(ped, "combat", "combat_idle_01", 3) then
        ClearPedTasksImmediately(ped)
    else
        RequestAnimDict("combat")
        while not HasAnimDictLoaded("combat") do
            Wait(0)
        end
        TaskPlayAnim(ped, "combat", "combat_idle_01", 8.0, -8.0, -1, 1, 0, false, false, false)
    end
end)

RegisterNetEvent('dispatch:client:putInVehicle')
AddEventHandler('dispatch:client:putInVehicle', function()
    local ped = PlayerPedId()
    local vehicleInFront = GetVehicleInFront(ped, 10.0)
    
    if vehicleInFront and vehicleInFront ~= 0 then
        if GetVehicleDoorCount(vehicleInFront) > 0 then
            TaskWarpPedIntoVehicle(ped, vehicleInFront, 1)
        end
    end
end)

RegisterNetEvent('dispatch:client:grabCitizen')
AddEventHandler('dispatch:client:grabCitizen', function(copServerId)
    local ped = PlayerPedId()
    -- Play grab animation
    RequestAnimDict("combat")
    while not HasAnimDictLoaded("combat") do
        Wait(0)
    end
    TaskPlayAnim(ped, "combat", "combat_idle_01", 8.0, -8.0, -1, 1, 0, false, false, false)
end)

function GetVehicleInFront(ped, distance)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forwardX = math.cos(math.rad(heading)) * distance
    local forwardY = math.sin(math.rad(heading)) * distance
    local targetCoords = vector3(coords.x + forwardX, coords.y + forwardY, coords.z)
    
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success
    
    repeat
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(targetCoords - vehCoords)
        if dist < distance then
            table.insert(vehicles, vehicle)
        end
        success, vehicle = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    
    if #vehicles > 0 then
        return vehicles[1]
    end
    return nil
end