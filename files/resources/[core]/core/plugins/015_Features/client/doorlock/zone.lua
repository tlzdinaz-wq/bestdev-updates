local function getOxClosestDoor()
    local ok, door = pcall(function()
        return exports['ox_doorlock']:getClosestDoor()
    end)
    if ok and door and door.distance and door.maxDistance and door.distance < door.maxDistance then
        return door
    end
    return nil
end

local function isEntityDoor(entity, door)
    if not entity or entity == 0 or not door then return false end
    local entModel = GetEntityModel(entity)
    local entCoords = GetEntityCoords(entity)
    local function matches(model, coords)
        if not model or not coords then return false end
        if entModel ~= model then return false end
        return #(entCoords - vector3(coords.x, coords.y, coords.z)) < 1.5
    end
    if door.doors then
        for i = 1, #door.doors do
            local d = door.doors[i]
            if matches(d.model, d.coords) then return true end
        end
        return false
    end
    return matches(door.model, door.coords)
end

VFW.ContextAddButton("object", ":unlock: Ouvrir la porte", function(entity)
    local door = getOxClosestDoor()
    if not door or door.state ~= 1 then return false end
    return isEntityDoor(entity, door)
end, function()
    local door = getOxClosestDoor()
    if door then
        exports['ox_doorlock']:useClosestDoor()
    end
end)

VFW.ContextAddButton("object", ":lock: Fermer la porte", function(entity)
    local door = getOxClosestDoor()
    if not door or door.state ~= 0 then return false end
    return isEntityDoor(entity, door)
end, function()
    local door = getOxClosestDoor()
    if door then
        exports['ox_doorlock']:useClosestDoor()
    end
end)

VFW.ContextAddButton("object", " Défoncer la porte", function(entity)
    local hasBelier = false
    for _, item in ipairs(VFW.PlayerData.inventory or {}) do
        if item.name == "belier" and item.count > 0 then
            hasBelier = true
            break
        end
    end
    if not hasBelier then return false end
    local door = getOxClosestDoor()
    if not door or door.state ~= 1 then return false end
    return isEntityDoor(entity, door)
end, function()
    local door = getOxClosestDoor()
    if door then
        local ped = PlayerPedId()
        local dict = "timetable@jimmy@doorknock@"
       local anim = "knockdoor_idle"

       RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        RemoveAnimDict(dict)

        Wait(500)

        local ended = false
        CreateThread(function()
            while not ended do
                Wait(0)
                DisableAllControlActions(0)
            end
        end)

        local valide = VFW.Nui.ProgressBar("Enfoncement de la porte ...", 30000)

        ended = true
        ClearPedTasks(ped)

        if valide and door.id then
            TriggerServerEvent("ox_doorlock:setState", door.id, 0)
            VFW.ShowNotification({ type = 'VERT', content = "Porte défoncée avec le bélier !" })
        end
    end
end)

-- Re-sync quand le joueur est chargé
AddEventHandler("vfw:playerLoaded", function()
    Wait(2000)
    if #Doorlock.cache == 0 then
        Doorlock:SyncServerCache()
    end
end)

local currentNearDoorId = nil
local currentNearSource = nil
local currentNearLockState = nil

local _doorlockDetailKvp = GetResourceKvpString("doorlock_detail_enabled")
local doorlockDetailEnabled = (_doorlockDetailKvp == nil or _doorlockDetailKvp == "1")

local function sendNuiMode()
    SendNUIMessage({
        action = "doorlock:setMode",
        data = { enabled = doorlockDetailEnabled }
    })
end

CreateThread(function()
    Wait(500)
    sendNuiMode()
end)

AddEventHandler("core:doorlock:setDetailMode", function(enabled)
    doorlockDetailEnabled = enabled and true or false
    sendNuiMode()
end)

local function sendNuiShow(id, source, isLocked, label)
    currentNearDoorId = id
    currentNearSource = source
    currentNearLockState = isLocked
    SendNUIMessage({
        action = "doorlock:show",
        data = {
            isLocked = isLocked,
            label = label or ""
       }
    })
end

local function sendNuiHide()
    if currentNearDoorId then
        currentNearDoorId = nil
        currentNearSource = nil
        currentNearLockState = nil
        SendNUIMessage({ action = "doorlock:hide" })
    end
end

function Doorlock:SendNuiStatus(doorlock)
    sendNuiShow(doorlock.id, "custom", doorlock.isLocked, doorlock.label)
end

function Doorlock:HideNuiStatus()
    if currentNearSource == "custom" or currentNearSource == nil then
        sendNuiHide()
    end
end

Citizen.CreateThread(function()
    Doorlock:SyncServerCache()

    local sleep = 1000
    local doorlock
    local doorlockCoords
    local dist

    while true do
        sleep = 1000

        for i = 1, #Doorlock.cache do
            doorlock = Doorlock.cache[i]
            doorlockCoords = vector3(doorlock.coords.x, doorlock.coords.y, doorlock.coords.z)
            dist = #(GetEntityCoords(PlayerPedId()) - doorlockCoords)

            if dist > doorlock.maxInteractDistance then
                goto skip
            end

            sleep = 0

            if currentNearDoorId ~= doorlock.id or currentNearSource ~= "custom" or currentNearLockState ~= doorlock.isLocked then
                Doorlock:SendNuiStatus(doorlock)
            end

            if VFW.Interact.JustReleased(0, 51) then
                local isMotelDoor <const> = Doorlock.motelDoorlockIds[doorlock.id]
                local prevState

                if isMotelDoor then
                    prevState = DoorSystemGetDoorState(doorlock.doorsData[1].hash)
                end

                local success <const> = Doorlock:InteractWithDoor(doorlock.id, doorlock.doorsData, doorlock.access, doorlock.pincode)

                if isMotelDoor and success then
                    local isOpening <const> = prevState ~= 0
                    VFW.ShowNotification({
                        type = "JOB",
                        title = "Motel",
                        subtitle = "Chambre",
                        content = isOpening and "Vous avez ouvert la porte" or "Vous avez fermé la porte"
                   })
                end
            end

            ::skip::
        end

        Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    local prevOxId = nil
    local prevOxState = nil

    while true do
        if currentNearSource ~= "custom" then
            local ok, door = pcall(function()
                return exports['ox_doorlock']:getClosestDoor()
            end)

            if ok and door and door.distance and door.maxDistance and door.distance < door.maxDistance then
                local isLocked = door.state == 1
                if prevOxId ~= door.id or prevOxState ~= isLocked then
                    sendNuiShow(door.id, "ox", isLocked, door.name)
                    prevOxId = door.id
                    prevOxState = isLocked
                end
                Wait(0)
            else
                if currentNearSource == "ox" then
                    sendNuiHide()
                end
                prevOxId = nil
                prevOxState = nil
                Wait(500)
            end
        else
            prevOxId = nil
            prevOxState = nil
            Wait(500)
        end
    end
end)