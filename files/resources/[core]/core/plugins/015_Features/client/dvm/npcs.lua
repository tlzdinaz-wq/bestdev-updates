---@diagnostic disable: duplicate-doc-field, duplicate-set-field

local spawnedNPCs = {}
local isNearNPC = false
local currentExamCenter = nil

---@description Attach tablet prop to a ped (optimized for clipboard animation)
---@param ped number
---@return number|nil
local function AttachTabletToPed(ped)
    if not ped or not DoesEntityExist(ped) then return nil end

    local tabletProp = joaat("prop_cs_tablet")
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do
        Wait(100)
    end

    local pedCoords = GetEntityCoords(ped)
    local tablet = CreateObject(tabletProp, pedCoords.x, pedCoords.y, pedCoords.z, false, false, true)
    SetEntityAsMissionEntity(tablet, true, true)

    -- Attach to hand (0x8CBD) for clipboard animation
    AttachEntityToEntity(tablet, ped, GetPedBoneIndex(ped, 0x8CBD),
        0.123, 0.074, 0.106,         -- offset X, Y, Z
        -10.854, -46.517, -139.788,  -- rotation X, Y, Z
        false, false, false, false, 0, true)

    SetModelAsNoLongerNeeded(tabletProp)
    return tablet
end

---@description Spawn NPCs at all exam centers
local function SpawnExamCenterNPCs()
    -- Delete any existing NPCs and tablets first
    for _, npcData in pairs(spawnedNPCs) do
        if npcData.tablet and DoesEntityExist(npcData.tablet) then
            DeleteEntity(npcData.tablet)
        end
        if DoesEntityExist(npcData.ped) then
            DeleteEntity(npcData.ped)
        end
    end
    spawnedNPCs = {}

    -- Spawn NPCs at each exam center
    for centerIndex, center in ipairs(Config.DVM.ExamCenters) do
        if center.npc then
            local npcData = center.npc

            -- Create the NPC using VFW.CreatePed
            local npc = VFW.CreatePed(npcData.coords, npcData.model)

            -- Clear the default clipboard scenario from VFW.CreatePed
            ClearPedTasksImmediately(npc)

            -- Load and play clipboard animation (makes ped hold and look at tablet)
            local animDict = "amb@world_human_clipboard@male@idle_a"
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Wait(100)
            end
            TaskPlayAnim(npc, animDict, "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)

            -- Attach tablet to NPC
            local tablet = AttachTabletToPed(npc)

            -- Store the NPC data
            table.insert(spawnedNPCs, {
                ped = npc,
                tablet = tablet,
                coords = vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z),
                centerIndex = centerIndex,
                center = center
            })
        end
    end
end

---@description Check if player is near any exam center NPC
local function CheckPlayerProximity()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local wasNearNPC = isNearNPC
    isNearNPC = false
    currentExamCenter = nil

    for _, npcData in pairs(spawnedNPCs) do
        local distance = #(playerCoords - npcData.coords)

        if distance < 2.5 then
            isNearNPC = true
            currentExamCenter = npcData.center
            break
        end
    end

    -- Show/hide help text
    if isNearNPC and not wasNearNPC then
        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder à l'auto-école")
    end
end

---@description Handle input when near NPC
local function HandleNPCInteraction()
    if isNearNPC and VFW.Interact.JustPressed(0, 38) then -- E key
        -- Open DVM menu
        VFW.OpenDVMNui()
    end
end

-- Initialize NPCs when resource starts
CreateThread(function()
    Wait(1000) -- Wait for game to load
    SpawnExamCenterNPCs()
end)

-- Main thread for proximity checking
CreateThread(function()
    while true do
        local sleep = 500

        if #spawnedNPCs > 0 then
            CheckPlayerProximity()

            if isNearNPC then
                sleep = 0
                HandleNPCInteraction()

                -- Display help text continuously while near
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder à l'auto-école")
            end
        end

        Wait(sleep)
    end
end)

-- Clean up NPCs and tablets when resource stops
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, npcData in pairs(spawnedNPCs) do
        if npcData.tablet and DoesEntityExist(npcData.tablet) then
            DeleteEntity(npcData.tablet)
        end
        if DoesEntityExist(npcData.ped) then
            DeleteEntity(npcData.ped)
        end
    end

    spawnedNPCs = {}
end)
