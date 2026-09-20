local JobEquipments = {}
local EquipmentBlips = {}
local EquipmentNPCs = {}
local EquipmentMarkers = {}

local npcModel = `s_m_y_armymech_01`

local function isPlayerJobInEquipment(equipment, jobName)
    if not equipment or not equipment.jobs then return false end
    for _, j in ipairs(equipment.jobs) do
        if j == jobName then return true end
    end
    return false
end

local function GetInteractionPos(equipment)
    return equipment.npcPos or equipment.pos
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
    for id, npc in pairs(EquipmentNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
        EquipmentNPCs[id] = nil
    end
    for id, equipment in pairs(JobEquipments) do
        if equipment.npcPos then
            CleanupNPCAtPosition(equipment.npcPos)
        end
    end
    EquipmentMarkers = {}
end

local function CleanupBlip(id)
    if EquipmentBlips[id] and DoesBlipExist(EquipmentBlips[id]) then
        RemoveBlip(EquipmentBlips[id])
        EquipmentBlips[id] = nil
    end
end

local function CleanupEquipment(id)
    CleanupBlip(id)
    if EquipmentNPCs[id] and DoesEntityExist(EquipmentNPCs[id]) then
        DeleteEntity(EquipmentNPCs[id])
        EquipmentNPCs[id] = nil
    end
    EquipmentMarkers[id] = nil
end

local function RefreshBlips()
    local jobName = GetPlayerJobName()

    for id, _ in pairs(EquipmentBlips) do
        CleanupBlip(id)
    end

    for id, equipment in pairs(JobEquipments) do
        local shouldShow = equipment.active and equipment.blipEnabled and jobName and isPlayerJobInEquipment(equipment, jobName)

        if shouldShow then
            local blip = AddBlipForCoord(equipment.pos.x, equipment.pos.y, equipment.pos.z)
            SetBlipSprite(blip, 365)
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 3)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or equipment.name or "\xC3\x89quipement"
            AddTextComponentString(jobLabel .. " \xE2\x80\xA2 \xC3\x89quipement")
            EndTextCommandSetBlipName(blip)
            EquipmentBlips[id] = blip
        end
    end
end

local function SetupEquipment(id, equipment)
    if equipment.active then
        if equipment.npcPos then
            EquipmentMarkers[id] = nil
            if not EquipmentNPCs[id] or not DoesEntityExist(EquipmentNPCs[id]) then
                CleanupNPCAtPosition(equipment.npcPos)
                local coords = {
                    x = equipment.npcPos.x,
                    y = equipment.npcPos.y,
                    z = equipment.npcPos.z - 1.0,
                    w = equipment.npcPos.h or 0.0
                }
                local npc = VFW.CreatePed(coords, equipment.npcModel or "s_m_y_armymech_01")
                if npc and DoesEntityExist(npc) then
                    SetEntityInvincible(npc, true)
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    SetPedCanRagdoll(npc, false)
                    ClearPedTasks(npc)
                    TaskStandStill(npc, -1)
                    EquipmentNPCs[id] = npc
                end
            end
        else
            if EquipmentNPCs[id] and DoesEntityExist(EquipmentNPCs[id]) then
                DeleteEntity(EquipmentNPCs[id])
                EquipmentNPCs[id] = nil
            end
            EquipmentMarkers[id] = true
        end
    else
        CleanupEquipment(id)
    end
end

local function GetClosestEquipment()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, equipment in pairs(JobEquipments) do
        if equipment.active then
            local interactPos = GetInteractionPos(equipment)
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

local function OpenEquipmentMenu(equipmentId)
    local items, canViewLogs = TriggerServerCallback("core:jobEquipment:getItemsForPlayer", equipmentId)
    if not items or #items == 0 then
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Informations Équipement", content = "Aucun item disponible pour votre grade" })
        return
    end

    local list = {}
    for _, item in ipairs(items) do
        table.insert(list, {
            id = item.id,
            item_name = item.item_name,
            label = item.label,
            max_stock = item.max_stock,
            current_out = item.current_out,
            available = item.available,
            playerHas = item.playerHas,
            maxPerPlayer = item.maxPerPlayer or 1,
            playerHasCount = item.playerHasCount or 0
        })
    end

    SendNUIMessage({
        action = "openJobEquipment",
        data = {
            equipmentId = equipmentId,
            items = list,
            canViewLogs = canViewLogs
        }
    })
    VFW.Nui.Focus(true)
end

local isFirstSync = true

RegisterNetEvent("core:jobEquipment:sync")
AddEventHandler("core:jobEquipment:sync", function(equipments)
    if isFirstSync then
        CleanupAll()
        isFirstSync = false
    end

    for id, _ in pairs(EquipmentBlips) do
        if not equipments[id] then
            CleanupEquipment(id)
        end
    end

    JobEquipments = equipments

    for id, equipment in pairs(equipments) do
        SetupEquipment(id, equipment)
    end

    RefreshBlips()
end)

RegisterNetEvent("vfw:playerLoaded")
AddEventHandler("vfw:playerLoaded", function()
    TriggerServerEvent("core:jobEquipment:requestSync")
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

        local closestId, closestDist = GetClosestEquipment()

        if closestId and closestDist < 15.0 then
            local equipment = JobEquipments[closestId]

            if equipment and EquipmentMarkers[closestId] then
                wait = 0
                local markerPos = equipment.pos
                local time = GetGameTimer() / 1000.0
                local bobZ = math.sin(time * 0.4) * 0.05
                local rotZ = (time * 30.0) % 360.0
                DrawMarker(29, markerPos.x, markerPos.y, markerPos.z + 0.3 + bobZ, 0.0, 0.0, 0.0, 0.0, 0.0, rotZ, 0.4, 0.4, 0.4, 0, 200, 100, 200, true, false, 2, true, nil, false)
            end

            if closestDist < 3.0 then
                local playerJob = VFW.PlayerData and VFW.PlayerData.job
                if equipment and playerJob and isPlayerJobInEquipment(equipment, playerJob.name) then
                    wait = 0
                    ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir l'équipement")
                    if VFW.Interact.JustPressed(0, 38) then
                        OpenEquipmentMenu(closestId)
                    end
                end
            end
        end

        Wait(wait)
    end
end)

RegisterNUICallback("closeJobEquipment", function(data, cb)
    VFW.Nui.Focus(false)
    cb("ok")
end)

RegisterNUICallback("jobEquipmentTakeItem", function(data, cb)
    local quantity = tonumber(data.quantity) or 1
    local result = TriggerServerCallback("core:jobEquipment:takeItem", data.itemId, quantity)
    if result and result.success then
        VFW.ShowNotification({ type = 'VERT', subtitle = "Informations Équipement", content = result.message })
    else
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Informations Équipement", content = result and result.message or "Erreur" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("jobEquipmentReturnItem", function(data, cb)
    local quantity = tonumber(data.quantity) or 1
    local result = TriggerServerCallback("core:jobEquipment:returnItem", data.itemId, quantity)
    if result and result.success then
        VFW.ShowNotification({ type = 'VERT', subtitle = "Informations Équipement", content = result.message })
    else
        VFW.ShowNotification({ type = 'ROUGE', subtitle = "Informations Équipement", content = result and result.message or "Erreur" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("jobEquipmentGetLogs", function(data, cb)
    local logs = TriggerServerCallback("core:jobEquipment:getLogs", data.equipmentId, 50)
    cb(logs or {})
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(EquipmentBlips) do
            CleanupEquipment(id)
        end
    end
end)
