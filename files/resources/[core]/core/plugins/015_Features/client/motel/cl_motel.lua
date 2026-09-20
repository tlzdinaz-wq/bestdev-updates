local spawnedNPCs = {}
local motelBlips = {}
local motelsData = {}
local motelRoomChests = {}
local isReceptionOpen = false
local currentMotelId = nil
local currentNpcPed = nil
local clipboardObj = nil
local pencilObj = nil

-- ════════════════════════════════════════════
--  Helpers
-- ════════════════════════════════════════════

--- Load an animation dictionary with timeout
--- @param dict string
--- @param timeout number milliseconds (default 5000)
--- @return boolean
local function LoadAnimDict(dict, timeout)
    timeout = timeout or 5000
    RequestAnimDict(dict)
    local start <const> = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - start > timeout then
            return false
        end
        Wait(50)
    end
    return true
end

--- Refresh motel data in NUI if open for specific motel
--- @param motelId number
local function RefreshMotelData(motelId)
    if not isReceptionOpen or currentMotelId ~= motelId then
        return
    end

    local data <const> = TriggerServerCallback("motel:server:getMotelData", motelId)
    if data then
        SendNUIMessage({
            action = "nui:motel:data",
            data = data
        })
    end
end

--- Delete a prop safely and return nil
--- @param prop number|nil
--- @return nil
local function DeleteProp(prop)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    return nil
end

-- ════════════════════════════════════════════
--  NPC & Blip Management
-- ════════════════════════════════════════════

--- Spawn NPC for a motel
--- @param motelData table
local function SpawnMotelNPC(motelData)
    if spawnedNPCs[motelData.id] then
        return
    end

    local coords <const> = motelData.npcCoords
    local npc <const> = VFW.CreatePed(
        vector4(coords.x, coords.y, coords.z - 1.0, coords.h or 0.0),
        motelData.npcModel or "s_f_y_shop_mid"
    )

    PlaceObjectOnGroundProperly(npc)
    FreezeEntityPosition(npc, true)

    local npcCoords <const> = GetEntityCoords(npc)
    spawnedNPCs[motelData.id] = {
        ped = npc,
        coords = npcCoords,
        motelId = motelData.id
    }
end

--- Remove NPC for a motel
--- @param motelId number
local function RemoveMotelNPC(motelId)
    local npcData <const> = spawnedNPCs[motelId]
    if not npcData then return end

    if DoesEntityExist(npcData.ped) then
        DeleteEntity(npcData.ped)
    end

    spawnedNPCs[motelId] = nil
end

--- Create blip for a motel
--- @param motelData table
local function CreateMotelBlip(motelData)
    if motelBlips[motelData.id] then
        return
    end

    if motelData.blipEnabled == false then
        return
    end

    local coords <const> = motelData.npcCoords
    local blip <const> = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, motelData.blipSprite or 475)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, motelData.blipColor or 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Motel")
    EndTextCommandSetBlipName(blip)

    motelBlips[motelData.id] = blip
end

--- Remove blip for a motel
--- @param motelId number
local function RemoveMotelBlip(motelId)
    local blip <const> = motelBlips[motelId]
    if blip then
        RemoveBlip(blip)
        motelBlips[motelId] = nil
    end
end

--- Spawn all motel NPCs and blips
local function SpawnAllMotels()
    for _, motelData in pairs(motelsData) do
        SpawnMotelNPC(motelData)
        CreateMotelBlip(motelData)
    end
end

--- Clean up all NPCs and blips
local function CleanupAll()
    for motelId, _ in pairs(spawnedNPCs) do
        RemoveMotelNPC(motelId)
    end

    for motelId, _ in pairs(motelBlips) do
        RemoveMotelBlip(motelId)
    end

    spawnedNPCs = {}
    motelBlips = {}
    motelRoomChests = {}
end

-- ════════════════════════════════════════════
--  Clipboard Props & Animation
-- ════════════════════════════════════════════

--- Check if the player is roughly facing the NPC (within ~60° cone)
--- @param ped number
--- @param targetCoords vector3
--- @return boolean
local function IsFacingCoords(ped, targetCoords)
    local pedCoords <const> = GetEntityCoords(ped)
    local pedHeading <const> = GetEntityHeading(ped)
    local dx <const> = targetCoords.x - pedCoords.x
    local dy <const> = targetCoords.y - pedCoords.y
    local angleToTarget <const> = math.deg(math.atan(dx, dy)) % 360
    local headingNorm <const> = pedHeading % 360
    local diff <const> = math.abs(angleToTarget - headingNorm)
    return diff < 60.0 or diff > 300.0
end

--- Play the give/receive animation between NPC and player, then attach clipboard
--- @param npcPed number
local function StartClipboard(npcPed)
    local ped <const> = PlayerPedId()
    local npcCoords <const> = GetEntityCoords(npcPed)
    local playerCoords <const> = GetEntityCoords(ped)

    -- Freeze player during the whole interaction
    FreezeEntityPosition(ped, true)

    -- Turn player toward NPC if not already facing
    if not IsFacingCoords(ped, npcCoords) then
        local facingHeading <const> = math.deg(math.atan(npcCoords.x - playerCoords.x, npcCoords.y - playerCoords.y)) % 360
        SetEntityHeading(ped, facingHeading)
        Wait(100)
    end

    -- NPC turns toward the player
    local newPlayerCoords <const> = GetEntityCoords(ped)
    TaskTurnPedToFaceCoord(npcPed, newPlayerCoords.x, newPlayerCoords.y, newPlayerCoords.z, 1000)
    Wait(800)

    -- Preload everything (with timeout to prevent infinite loop)
    if not LoadAnimDict("mp_common") then FreezeEntityPosition(ped, false) return end
    if not LoadAnimDict("missheistdockssetup1clipboard@base") then FreezeEntityPosition(ped, false) return end

    VFW.Streaming.RequestModel(GetHashKey("prop_notepad_01"))
    VFW.Streaming.RequestModel(GetHashKey("prop_pencil_01"))

    -- NPC gives, player receives
    TaskPlayAnim(npcPed, "mp_common", "givetake1_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(300)
    TaskPlayAnim(ped, "mp_common", "givetake1_b", 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(1200)

    -- Attach clipboard + pencil to player
    clipboardObj = CreateObject(GetHashKey("prop_notepad_01"), 0, 0, 0, false, true, true)
    AttachEntityToEntity(clipboardObj, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.02, 0.05, 10.0, 0.0, 0.0, true, true, false, true, 1, true)

    pencilObj = CreateObject(GetHashKey("prop_pencil_01"), 0, 0, 0, false, true, true)
    AttachEntityToEntity(pencilObj, ped, GetPedBoneIndex(ped, 58866), 0.12, 0.0, 0.001, -150.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Player holds clipboard
    TaskPlayAnim(ped, "missheistdockssetup1clipboard@base", "base", 8.0, -8.0, -1, 49, 0, false, false, false)

    -- NPC returns to its idle scenario
    TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
end

--- Give back clipboard to NPC and clean up
--- @param npcPed number|nil
local function StopClipboard(npcPed)
    local ped <const> = PlayerPedId()

    -- Delete props first (always, even if animation fails)
    clipboardObj = DeleteProp(clipboardObj)
    pencilObj = DeleteProp(pencilObj)

    -- Give-back animation if NPC is nearby
    if npcPed and DoesEntityExist(npcPed) then
        local playerCoords <const> = GetEntityCoords(ped)
        TaskTurnPedToFaceCoord(npcPed, playerCoords.x, playerCoords.y, playerCoords.z, 500)

        if LoadAnimDict("mp_common", 2000) then
            TaskPlayAnim(ped, "mp_common", "givetake1_a", 8.0, -8.0, 1500, 0, 0, false, false, false)
            Wait(300)
            TaskPlayAnim(npcPed, "mp_common", "givetake1_b", 8.0, -8.0, 1500, 0, 0, false, false, false)
            Wait(1200)
        end

        TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    -- Release streaming assets
    RemoveAnimDict("mp_common")
    RemoveAnimDict("missheistdockssetup1clipboard@base")
    SetModelAsNoLongerNeeded(GetHashKey("prop_notepad_01"))
    SetModelAsNoLongerNeeded(GetHashKey("prop_pencil_01"))
end

-- ════════════════════════════════════════════
--  NUI Management
-- ════════════════════════════════════════════

--- Open the motel reception NUI
--- @param motelId number
--- @param npcPed number
local function OpenMotelReception(motelId, npcPed)
    if isReceptionOpen then return end

    isReceptionOpen = true
    currentMotelId = motelId
    currentNpcPed = npcPed

    StartClipboard(npcPed)

    SendNUIMessage({
        action = "nui:motel:visible",
        data = true
    })

    VFW.Nui.Focus(true)
    VFW.Nui.HudVisible(false)
    VFW.DisableEscapeMenu(true)

    -- Fetch data from server
    local data <const> = TriggerServerCallback("motel:server:getMotelData", motelId)

    if data then
        SendNUIMessage({
            action = "nui:motel:data",
            data = data
        })
    end
end

--- Close the motel reception NUI
local function CloseMotelReception()
    if not isReceptionOpen then return end

    -- Capture NPC ref before clearing state
    local npcPed <const> = currentNpcPed

    isReceptionOpen = false
    currentMotelId = nil
    currentNpcPed = nil

    SendNUIMessage({
        action = "nui:motel:visible",
        data = false
    })

    VFW.Nui.Focus(false)
    VFW.Nui.HudVisible(true)
    VFW.DisableEscapeMenu(false)

    StopClipboard(npcPed)
end

-- ════════════════════════════════════════════
--  NUI Callbacks
-- ════════════════════════════════════════════

RegisterNUICallback("nui:motel:close", function(_, cb)
    CloseMotelReception()
    cb("ok")
end)

RegisterNUICallback("nui:motel:rent", function(data, cb)
    if not isReceptionOpen or not currentMotelId then
        cb({ success = false, message = "Interface fermée" })
        return
    end

    local result <const> = TriggerServerCallback("motel:server:rentRoom", {
        roomId = data.roomId,
        hours = data.hours,
        method = data.method or "cash"
    })

    if result and result.success then
        RefreshMotelData(currentMotelId)
    end

    cb(result or { success = false, message = "Erreur" })
end)

RegisterNUICallback("nui:motel:checkout", function(data, cb)
    if not isReceptionOpen then
        cb({ success = false, message = "Interface fermée" })
        return
    end

    local result <const> = TriggerServerCallback("motel:server:checkoutRoom", {
        roomId = data.roomId
    })

    if result and result.success and currentMotelId then
        RefreshMotelData(currentMotelId)
    end

    cb(result or { success = false, message = "Erreur" })
end)

RegisterNUICallback("nui:motel:duplicateKey", function(data, cb)
    if not isReceptionOpen then
        cb({ success = false, message = "Interface fermée" })
        return
    end

    local result <const> = TriggerServerCallback("motel:server:duplicateKey", {
        roomId = data.roomId,
        reason = data.reason,
        method = data.method or "cash"
    })

    cb(result or { success = false, message = "Erreur" })
end)

RegisterNUICallback("nui:motel:extend", function(data, cb)
    if not isReceptionOpen then
        cb({ success = false, message = "Interface fermée" })
        return
    end

    local result <const> = TriggerServerCallback("motel:server:extendRental", {
        roomId = data.roomId,
        hours = data.hours,
        method = data.method or "cash"
    })

    if result and result.success and currentMotelId then
        RefreshMotelData(currentMotelId)
    end

    cb(result or { success = false, message = "Erreur" })
end)

RegisterNUICallback("nui:motel:claimStorage", function(data, cb)
    if not isReceptionOpen then
        cb({ success = false, message = "Interface fermée" })
        return
    end

    local result <const> = TriggerServerCallback("motel:server:claimStorage", data.storageId)

    if result and result.success and currentMotelId then
        RefreshMotelData(currentMotelId)
    end

    cb(result or { success = false, message = "Erreur" })
end)

-- ════════════════════════════════════════════
--  Proximity Loops
-- ════════════════════════════════════════════

CreateThread(function()
    while true do
        local sleep = 500
        local playerPed <const> = PlayerPedId()
        local playerCoords <const> = GetEntityCoords(playerPed)

        for _, npcData in pairs(spawnedNPCs) do
            local distance <const> = #(playerCoords - npcData.coords)

            if distance < 20.0 then
                sleep = 100

                if distance < 2.0 then
                    sleep = 5

                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder à la réception")

                    if VFW.Interact.JustPressed(0, 38) then -- E key
                        OpenMotelReception(npcData.motelId, npcData.ped)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Chest proximity thread
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed <const> = PlayerPedId()
        local playerCoords <const> = GetEntityCoords(playerPed)

        for _, chestData in pairs(motelRoomChests) do
            local coords <const> = chestData.chestCoords
            local chestPos <const> = vector3(coords.x, coords.y, coords.z)
            local distance <const> = #(playerCoords - chestPos)

            if distance < 8.0 then
                sleep = 0

                -- Draw marker
                DrawMarker(25, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 0, 0, 255, 255, false, true, 2, nil, nil, false)

                if distance < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le coffre")

                    if VFW.Interact.JustPressed(0, 38) then -- E key
                        local result <const> = TriggerServerCallback("motel:server:openChest", chestData.roomId)

                        if result and result.success then
                            VFW.OpenChest(result.chestId, "motel", result.maxSlots)
                        else
                            VFW.ShowNotification({ type = "JOB", title = "Motel", subtitle = "Coffre", content = result and result.message or "Impossible d'ouvrir le coffre" })
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ════════════════════════════════════════════
--  Server Sync Events
-- ════════════════════════════════════════════

--- New motel created
RegisterNetEvent("motel:client:motelCreated", function(motelData)
    motelsData[motelData.id] = motelData
    SpawnMotelNPC(motelData)
    CreateMotelBlip(motelData)
end)

--- Motel deleted
RegisterNetEvent("motel:client:motelDeleted", function(motelId)
    motelsData[motelId] = nil
    RemoveMotelNPC(motelId)
    RemoveMotelBlip(motelId)
end)

--- Motel updated
RegisterNetEvent("motel:client:motelUpdated", function(motelData)
    -- Remove old NPC/blip and recreate
    RemoveMotelNPC(motelData.id)
    RemoveMotelBlip(motelData.id)

    motelsData[motelData.id] = motelData
    SpawnMotelNPC(motelData)
    CreateMotelBlip(motelData)
end)

--- Room rented (refresh NUI if open)
RegisterNetEvent("motel:client:roomRented", function(motelId)
    RefreshMotelData(motelId)
end)

--- Room checked out (refresh NUI if open)
RegisterNetEvent("motel:client:roomCheckedOut", function(motelId)
    RefreshMotelData(motelId)
end)

--- Rental expired notification
RegisterNetEvent("motel:client:rentalExpired", function(motelId)
    RefreshMotelData(motelId)
end)

--- Room added (refresh NUI if open + update chest/doorlock cache)
RegisterNetEvent("motel:client:roomAdded", function(motelId, roomData)
    RefreshMotelData(motelId)

    if roomData and roomData.doorlockIds then
        for _, dlId in ipairs(roomData.doorlockIds) do
            Doorlock.motelDoorlockIds[dlId] = true
            local _, dl = Doorlock:FindDoorlockById(dlId)
            if dl then
                dl.iconOffset = roomData.iconOffsets and roomData.iconOffsets[tostring(dlId)] or nil
            end
        end
    end

    if roomData and roomData.chestCoords then
        motelRoomChests[roomData.id] = {
            roomId = roomData.id,
            motelId = motelId,
            roomNumber = roomData.roomNumber,
            chestCoords = roomData.chestCoords
        }
    end
end)

--- Room removed (refresh NUI if open + update chest/doorlock cache)
RegisterNetEvent("motel:client:roomRemoved", function(motelId, roomId, doorlockIds)
    RefreshMotelData(motelId)
    motelRoomChests[roomId] = nil
    if doorlockIds then
        for _, dlId in ipairs(doorlockIds) do
            Doorlock.motelDoorlockIds[dlId] = nil
        end
    end
end)

--- Room updated (refresh NUI if open + update chest cache)
RegisterNetEvent("motel:client:roomUpdated", function(motelId, roomData)
    RefreshMotelData(motelId)

    if roomData and roomData.id then
        if roomData.chestCoords then
            motelRoomChests[roomData.id] = {
                roomId = roomData.id,
                motelId = motelId,
                roomNumber = roomData.roomNumber,
                chestCoords = roomData.chestCoords
            }
        else
            motelRoomChests[roomData.id] = nil
        end

        -- Update iconOffset on all doorlock cache entries (per-door offsets)
        if roomData.doorlockIds then
            for _, dlId in ipairs(roomData.doorlockIds) do
                Doorlock.motelDoorlockIds[dlId] = true
                local _, dl = Doorlock:FindDoorlockById(dlId)
                if dl then
                    dl.iconOffset = roomData.iconOffsets and roomData.iconOffsets[tostring(dlId)] or nil
                end
            end
        end
    end
end)

--- Use motel key to toggle door from inventory
RegisterNetEvent("motel:client:useKey", function(doorlockId, pincode)
    local _, doorlock = Doorlock:FindDoorlockById(doorlockId)
    if not doorlock then return end

    Doorlock:InteractWithDoor(doorlockId, doorlock.doorsData, doorlock.access, pincode)
end)

-- ════════════════════════════════════════════
--  Init & Cleanup
-- ════════════════════════════════════════════

-- Request motels on player loaded
AddEventHandler("vfw:playerLoaded", function()
    CleanupAll()

    local motels <const> = TriggerServerCallback("motel:server:getAllMotels")

    if motels then
        for _, motelData in pairs(motels) do
            motelsData[motelData.id] = motelData
        end

        SpawnAllMotels()
    end

    -- Load motel doorlock IDs (for doorlock interaction check + iconOffset)
    local doorlockEntries <const> = TriggerServerCallback("motel:server:getMotelDoorlockIds")
    Doorlock.motelDoorlockIds = {}
    if doorlockEntries then
        for _, entry in ipairs(doorlockEntries) do
            Doorlock.motelDoorlockIds[entry.id] = true
            if entry.iconOffset then
                local _, dl = Doorlock:FindDoorlockById(entry.id)
                if dl then dl.iconOffset = entry.iconOffset end
            end
        end
    end

    -- Load chest positions for proximity detection
    local chests <const> = TriggerServerCallback("motel:server:getRoomChests")

    if chests then
        for _, chestData in ipairs(chests) do
            motelRoomChests[chestData.roomId] = chestData
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    CloseMotelReception()
    CleanupAll()
end)
