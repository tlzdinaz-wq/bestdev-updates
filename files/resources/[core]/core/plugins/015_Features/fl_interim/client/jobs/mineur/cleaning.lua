local cleaningBlip
local centerBlip
local isCleaning = false
local inCleanArea = false
local areaData

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function ShowHelpNotification(text)
    VFW.ShowHelpNotification(text)
end

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end

local function makeProp(data, freeze, synced)
    local model = data.prop
    local coords = data.coords or vec4(0,0,0,0)
    if not model then return nil end
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, true, synced or false)
    SetEntityCollision(obj, false, false)
    if freeze then FreezeEntityPosition(obj, true) end
    return obj
end

local function loadAnimDict(dict)
    if not dict then return end
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local deadline = GetGameTimer() + 5000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
            Wait(0)
        end
    end
end

local function removeCleaningArea()
    if cleaningBlip then RemoveBlip(cleaningBlip) cleaningBlip = nil end
    if centerBlip then RemoveBlip(centerBlip) centerBlip = nil end
    areaData = nil
    inCleanArea = false
    ClearAllHelpMessages()
end

local
function IsPedFacingWater(ped)
    local pos = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)

    local underFeet = TestProbeAgainstWater(pos.x, pos.y, pos.z + 0.3, pos.x, pos.y, pos.z - 2.0)
    if underFeet then
        return true
    end

    local anglesToCheck = {-30.0, -15.0, 0.0, 15.0, 30.0}
    for _, angle in ipairs(anglesToCheck) do
        local rotatedForward = vector3(
                forward.x * math.cos(math.rad(angle)) - forward.y * math.sin(math.rad(angle)),
                forward.x * math.sin(math.rad(angle)) + forward.y * math.cos(math.rad(angle)),
                forward.z
        )
        local checkPos = pos + rotatedForward * 2.0
        if TestProbeAgainstWater(pos.x, pos.y, pos.z + 0.3, checkPos.x, checkPos.y, checkPos.z) then
            return true
        end
    end

    return false
end


RegisterNetEvent("interim:miner:setCleanArea", function(area)
    removeCleaningArea()
    if not area then return end
    areaData = area

    cleaningBlip = AddBlipForRadius(area.x, area.y, area.z, area.radius or 30.0)
    SetBlipHighDetail(cleaningBlip, true)
    SetBlipColour(cleaningBlip, 3)
    SetBlipAlpha(cleaningBlip, 120)

    centerBlip = AddBlipForCoord(area.x, area.y, area.z)
    SetBlipSprite(centerBlip, 467)
    SetBlipColour(centerBlip, 46)
    SetBlipScale(centerBlip, 0.5)
    SetBlipAsShortRange(centerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Mineur • Nettoyage")
    EndTextCommandSetBlipName(centerBlip)

    CreateThread(function()
        while areaData do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            inCleanArea = #(coords - vector3(areaData.x, areaData.y, areaData.z)) <= (areaData.radius or 30.0)

            if inCleanArea and not isCleaning then
                ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour nettoyer vos minerais.")
                if VFW.Interact.JustReleased(0, 38) then
                    if IsPedFacingWater(ped) then
                        CreateThread(function()
                            local deadline = GetGameTimer() + 7000
                            while GetGameTimer() < deadline and not isCleaning do
                                DisableControlAction(0, 38, true)
                                Wait(0)
                            end
                        end)
                        TriggerServerEvent("interim:miner:requestClean")
                    else
                        notify("ROUGE", "Mets-toi bien face à l’eau pour laver le minerai.")
                    end
                end
            elseif not inCleanArea then
                ClearAllHelpMessages()
            end

            Wait(inCleanArea and 0 or 400)
        end
    end)
end)

RegisterNetEvent("interim:miner:stopCleaning", function()
    removeCleaningArea()
end)

RegisterNetEvent("interim:miner:cleaningStart", function(payload)
    ClearAllHelpMessages()



    local ped = PlayerPedId()
    isCleaning = true

    CreateThread(function()
        while isCleaning do
            DisableControlAction(0, 38, true)
            Wait(0)
        end
    end)

    local dict = (payload and payload.dict) or "amb@prop_human_bum_bin@idle_b"
    local name = (payload and payload.name) or "idle_d"
    local flag = (payload and payload.flag) or 49
    local delay = (payload and tonumber(payload.delay)) or 5000
    loadAnimDict(dict)
    local rock = makeProp({ prop = "prop_rock_5_smash1" }, false, true)
    AttachEntityToEntity(rock, ped, GetPedBoneIndex(ped, 60309), 0.1, 0.0, 0.05, 90.0, -90.0, 90.0, true, true, false, true, 1, true)
    TaskPlayAnim(ped, dict, name, 3.0, -1.0, delay, flag, 0.0, false, false, false)
    ShowHelpNotification("Nettoyage du minerai en cours...")
    SetTimeout(delay, function()
        ClearPedTasks(ped)
        if DoesEntityExist(rock) then DeleteEntity(rock) end
        isCleaning = false
    end)
end)
