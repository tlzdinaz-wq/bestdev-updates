local JobArmories = {}
local ArmoryBlips = {}
local ArmoryNPCs = {}
local ArmoryMarkers = {}

local npcModel = `s_m_y_armymech_01`

local function isPlayerJobInArmory(armory, jobName)
    if not armory or not armory.jobs then return false end
    for _, j in ipairs(armory.jobs) do
        if j == jobName then return true end
    end
    return false
end

local function GetInteractionPos(armory)
    return armory.npcPos or armory.pos
end

local function GetPlayerJobName()
    local playerJob = VFW.PlayerData and VFW.PlayerData.job
    return playerJob and playerJob.name or nil
end

local function CleanupNPCAtPosition(pos)
    local targetPos = vector3(pos.x, pos.y, pos.z)
    local handle, ped = FindFirstPed()
    local success
    repeat
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            if GetEntityModel(ped) == npcModel then
                local pedCoords = GetEntityCoords(ped)
                if #(pedCoords - targetPos) < 0.5 then
                    DeleteEntity(ped)
                    return true
                end
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return false
end

local function CleanupAll()
    for id, npc in pairs(ArmoryNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        ArmoryNPCs[id] = nil
    end
    for id, armory in pairs(JobArmories) do
        if armory.npcPos then
            CleanupNPCAtPosition(armory.npcPos)
        end
    end
    ArmoryMarkers = {}
end

local function CleanupBlip(id)
    if ArmoryBlips[id] and DoesBlipExist(ArmoryBlips[id]) then
        RemoveBlip(ArmoryBlips[id])
        ArmoryBlips[id] = nil
    end
end

local function CleanupArmory(id)
    CleanupBlip(id)
    if ArmoryNPCs[id] and DoesEntityExist(ArmoryNPCs[id]) then
        DeleteEntity(ArmoryNPCs[id])
        ArmoryNPCs[id] = nil
    end
    ArmoryMarkers[id] = nil
end

local function RefreshBlips()
    local jobName = GetPlayerJobName()

    for id, _ in pairs(ArmoryBlips) do
        CleanupBlip(id)
    end

    for id, armory in pairs(JobArmories) do
        local shouldShow = armory.active and armory.blipEnabled and jobName and isPlayerJobInArmory(armory, jobName)

        if shouldShow then
            local blip = AddBlipForCoord(armory.pos.x, armory.pos.y, armory.pos.z)
            SetBlipSprite(blip, 110)
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or armory.name or "Armurerie"
            AddTextComponentString(jobLabel .. " \xE2\x80\xA2 Armurerie")
            EndTextCommandSetBlipName(blip)
            ArmoryBlips[id] = blip
        end
    end
end

local function SetupArmory(id, armory)
    if armory.active then
        if armory.npcPos then
            ArmoryMarkers[id] = nil
            if not ArmoryNPCs[id] or not DoesEntityExist(ArmoryNPCs[id]) then
                CleanupNPCAtPosition(armory.npcPos)
                local coords = {
                    x = armory.npcPos.x,
                    y = armory.npcPos.y,
                    z = armory.npcPos.z - 1.0,
                    w = armory.npcPos.h or 0.0
                }
                local npc = VFW.CreatePed(coords, armory.npcModel or "s_m_y_armymech_01")
                if npc and DoesEntityExist(npc) then
                    SetEntityInvincible(npc, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    SetPedCanRagdoll(npc, false)
                    ClearPedTasks(npc)
                    TaskStandStill(npc, -1)
                    ArmoryNPCs[id] = npc
                end
            end
        else
            if ArmoryNPCs[id] and DoesEntityExist(ArmoryNPCs[id]) then
                DeleteEntity(ArmoryNPCs[id])
                ArmoryNPCs[id] = nil
            end
            ArmoryMarkers[id] = true
        end
    else
        CleanupArmory(id)
    end
end

local function GetClosestArmory()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, armory in pairs(JobArmories) do
        if armory.active then
            local interactPos = GetInteractionPos(armory)
            if interactPos then
                local pos = vector3(interactPos.x, interactPos.y, interactPos.z)
                local dist = #(coords - pos)
                if dist < closestDist then
                    closest = id
                    closestDist = dist
                end
            end
        end
    end

    return closest, closestDist
end

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

local function OpenArmoryMenu(armoryId)
    local weapons, canViewLogs = TriggerServerCallback("core:jobArmory:getWeaponsForPlayer", armoryId)
    if not weapons or #weapons == 0 then
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Informations Armurerie", content = "Aucune arme disponible pour votre grade" })
        return
    end

    local items = {}
    for _, w in ipairs(weapons) do
        table.insert(items, {
            id = w.id,
            item_name = w.item_name,
            label = w.label,
            max_stock = w.max_stock,
            current_out = w.current_out,
            available = w.available,
            playerHas = w.playerHas,
            maxPerPlayer = w.maxPerPlayer or 1,
            playerHasCount = w.playerHasCount or 0
        })
    end

    SendNUIMessage({
        action = "openJobArmory",
        data = {
            armoryId = armoryId,
            weapons = items,
            canViewLogs = canViewLogs
        }
    })
    VFW.Nui.Focus(true)
end

local isFirstSync = true

RegisterNetEvent("core:jobArmory:sync")
AddEventHandler("core:jobArmory:sync", function(armories)
    if isFirstSync then
        CleanupAll()
        isFirstSync = false
    end

    local oldIds = {}
    for id in pairs(ArmoryBlips) do oldIds[id] = true end
    for id in pairs(ArmoryNPCs) do oldIds[id] = true end
    for id in pairs(JobArmories) do oldIds[id] = true end
    for id in pairs(oldIds) do
        if not armories[id] then
            CleanupArmory(id)
        end
    end

    JobArmories = armories

    for id, armory in pairs(armories) do
        SetupArmory(id, armory)
    end

    RefreshBlips()
end)

RegisterNetEvent("vfw:playerLoaded")
AddEventHandler("vfw:playerLoaded", function()
    TriggerServerEvent("core:jobArmory:requestSync")
end)

RegisterNetEvent("vfw:setJob")
AddEventHandler("vfw:setJob", function()
    RefreshBlips()
end)

RegisterNetEvent("vfw:client:changeDuty")
AddEventHandler("vfw:client:changeDuty", function()
    RefreshBlips()
end)

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local closestId, closestDist = GetClosestArmory()

        if closestId and closestDist < 15.0 then
            local armory = JobArmories[closestId]

            if armory and ArmoryMarkers[closestId] then
                wait = 0
                local markerPos = armory.pos
                local time = GetGameTimer() / 1000.0
                local bobZ = math.sin(time * 0.4) * 0.05
                local rotZ = (time * 30.0) % 360.0
                DrawMarker(29, markerPos.x, markerPos.y, markerPos.z + 0.3 + bobZ, 0.0, 0.0, 0.0, 0.0, 0.0, rotZ, 0.4, 0.4, 0.4, 0, 100, 255, 200, true, false, 2, true, nil, false)
            end

            if closestDist < 3.0 then
                local playerJob = VFW.PlayerData and VFW.PlayerData.job
                if armory and playerJob and isPlayerJobInArmory(armory, playerJob.name) then
                    wait = 0
                    ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir l'armurerie")
                    if VFW.Interact.JustPressed(0, 38) then
                        OpenArmoryMenu(closestId)
                    end
                end
            end
        end

        Wait(wait)
    end
end)

RegisterNUICallback("closeJobArmory", function(data, cb)
    VFW.Nui.Focus(false)
    cb("ok")
end)

RegisterNUICallback("jobArmoryTakeWeapon", function(data, cb)
    local result = TriggerServerCallback("core:jobArmory:takeWeapon", data.weaponId)
    if result and result.success then
        VFW.ShowNotification({ type = 'VERT', subtitle = "Informations Armurerie", content = result.message })
    else
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Informations Armurerie", content = result and result.message or "Erreur" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("jobArmoryReturnWeapon", function(data, cb)
    local result = TriggerServerCallback("core:jobArmory:returnWeapon", data.weaponId)
    if result and result.success then
        VFW.ShowNotification({ type = 'VERT', subtitle = "Informations Armurerie", content = result.message })
    else
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Informations Armurerie", content = result and result.message or "Erreur" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("jobArmoryGetLogs", function(data, cb)
    local logs = TriggerServerCallback("core:jobArmory:getLogs", data.armoryId, 50)
    cb(logs or {})
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(ArmoryBlips) do
            CleanupArmory(id)
        end
    end
end)
