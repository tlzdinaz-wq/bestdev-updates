---@meta _
---@diagnostic disable: duplicate-doc-field

-- Police Actions - Client-side event handlers for police tackle animation

local function getPoliceImg()
    return VFW.CDN.Get("entreprise/" .. (VFW.PlayerData.job.name or "sasp") .. ".png")
end

local function policeNotif(subtitle, message)
    VFW.ShowNotification({
        type     = "JOB",
        title    = VFW.PlayerData and VFW.PlayerData.job.label or "SASP",
        subtitle = subtitle,
        image    = getPoliceImg(),
        content  = message
    })
end

-- Tackle animation (received by the TARGET)
RegisterNetEvent("police:tackle:anim")
AddEventHandler("police:tackle:anim", function(officerSource)
    local ped = PlayerPedId()
    local dict = "missminuteman_1ig_2"
    local anim = "tasered_2"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 3000, 2, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(ped)
    RemoveAnimDict(dict)
end)

-- Tackle animation (received by the OFFICER)
RegisterNetEvent("police:tackle:anim:officer")
AddEventHandler("police:tackle:anim:officer", function()
    local ped = PlayerPedId()
    local dict = "missminuteman_1ig_2"
    local anim = "yourside_punch"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(ped)
    RemoveAnimDict(dict)
end)

-- ============================================================
-- BRACELET: Remote shock (received by the TARGET)
-- ============================================================

RegisterNetEvent("police:braceletShock")
AddEventHandler("police:braceletShock", function()
    local ped = PlayerPedId()

    -- If in a vehicle, force exit first
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        TaskLeaveVehicle(ped, vehicle, 16)
        local timeout = 40
        while GetVehiclePedIsIn(ped, false) ~= 0 and timeout > 0 do
            Wait(100)
            timeout = timeout - 1
        end
        ped = PlayerPedId()
    end

    policeNotif("Bracelet Électronique", "Votre bracelet électronique vous a envoyé une décharge !")

    -- Ragdoll to make the player fall to the ground
    SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false)

    Wait(5000)
    ClearPedTasks(ped)
end)

-- ============================================================
-- BRACELET: Remote message (received by the TARGET)
-- ============================================================

RegisterNetEvent("police:braceletMessage")
AddEventHandler("police:braceletMessage", function(message, agentName, agentMatricule)
    if not message or message == "" then return end
    local prefix = "Message"
    if agentName and agentMatricule then
        prefix = "Message de l'agent " .. agentMatricule .. " : "
    elseif agentName then
        prefix = "Message de " .. agentName .. " : "
    end
    policeNotif("Communication Bracelet", prefix .. message)
end)

-- ============================================================
-- POLICE PRISON: Client-side events
-- ============================================================

-- Tenue de prisonnier — appliquée directement via SetPedComponentVariation
-- Composants : {slotId, drawable, texture}
-- Slot 3=arms, 4=pants, 5=bags, 7=chain, 8=tshirt, 9=bproof, 11=torso
local prisonerOutfit = {
    { 8,  1,  12 }, -- tshirt: drawable 1, variation 12 (orange)
    { 11, 1,  12 }, -- haut: drawable 1, variation 12 (orange)
    { 3,  0,  0 },  -- bras: 0
    { 4,  5,  8 },  -- pantalon: drawable 5, variation 8
    { 7,  0,  0 },  -- chain: aucun
    { 5,  0,  0 },  -- bags: aucun
    { 9,  0,  0 },  -- bproof: aucun
    { 1,  0,  0 },  -- mask: aucun
}

local function applyPrisonerOutfit()
    local ped = PlayerPedId()
    for _, entry in ipairs(prisonerOutfit) do
        SetPedComponentVariation(ped, entry[1], entry[2], entry[3], 2)
    end
end

-- Prison timer state
local prisonEndTime = nil
local hasEscaped = false

-- Release NPC state
local pendingSavedSkin = nil
local releaseNPC = nil
local RELEASE_NPC_COORDS = vector4(1845.96, 2585.85, 44.67, 270.0)
local RELEASE_NPC_MODEL = "s_m_m_prisguard_01"

-- Apply prisoner outfit (received by the TARGET)
-- saveSkin: true on first imprisonment, false on reconnect (skin already saved server-side)
RegisterNetEvent("police:prison:apply")
AddEventHandler("police:prison:apply", function(duration, saveSkin)
    hasEscaped = false
    prisonEndTime = GetGameTimer() + (duration * 60 * 1000)

    -- Wait for teleport to settle
    Wait(1000)

    TriggerEvent('skinchanger:getSkin', function(skin)
        if saveSkin then
            TriggerServerEvent("police:prison:saveSkin", skin)
        end

        applyPrisonerOutfit()
    end)
end)

-- Restore skin on prison release (received by the TARGET)
-- Skin is NOT restored immediately - player must talk to the guard NPC
RegisterNetEvent("police:prison:release")
AddEventHandler("police:prison:release", function(savedSkin, isEscape)
    prisonEndTime = nil

    if savedSkin and type(savedSkin) == "table" and next(savedSkin) then
        pendingSavedSkin = savedSkin
    else
        -- Fallback: load skin from database
        local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
        if skin and type(skin) == "table" and next(skin) then
            pendingSavedSkin = skin
        end
    end

    if not isEscape then
        policeNotif("Prison", "Vous avez été libéré.")
    end
end)

-- Update prison timer when sentence is reduced
RegisterNetEvent("police:prison:updateTimer")
AddEventHandler("police:prison:updateTimer", function(remainingMinutes)
    prisonEndTime = GetGameTimer() + (remainingMinutes * 60 * 1000)
end)

-- Prison timer HUD
CreateThread(function()
    while true do
        if prisonEndTime then
            local remaining = prisonEndTime - GetGameTimer()
            if remaining <= 0 then
                prisonEndTime = nil
            else
                local totalSec = math.ceil(remaining / 1000)
                local min = math.floor(totalSec / 60)
                local sec = totalSec % 60
                local timerText = string.format("~w~Temps restant en prison : ~r~%02d:%02d", min, sec)

                SetTextFont(4)
                SetTextScale(0.5, 0.5)
                SetTextColour(255, 255, 255, 255)
                SetTextOutline()
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString(timerText)
                DrawText(0.5, 0.02)
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ============================================================
-- PRISON ESCAPE: Detect when prisoner leaves the prison zone
-- ============================================================
local PRISON_CENTER = vector3(1747.58, 2537.37, 44.57)
local PRISON_RADIUS = 500.0

CreateThread(function()
    while true do
        if prisonEndTime and not hasEscaped then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - PRISON_CENTER)

            if dist > PRISON_RADIUS then
                hasEscaped = true
                prisonEndTime = nil
                TriggerServerEvent("police:prison:escaped")
            end

            Wait(2000)
        else
            Wait(5000)
        end
    end
end)

-- Reset escape flag on prison apply
RegisterNetEvent("police:prison:resetEscape")
AddEventHandler("police:prison:resetEscape", function()
    hasEscaped = false
end)

-- ============================================================
-- RELEASE NPC: Guard NPC to recover clothes after prison
-- ============================================================

local function spawnReleaseNPC()
    if releaseNPC and DoesEntityExist(releaseNPC) then return end

    releaseNPC = VFW.CreatePed(
        vector4(RELEASE_NPC_COORDS.x, RELEASE_NPC_COORDS.y, RELEASE_NPC_COORDS.z - 1.0, RELEASE_NPC_COORDS.w),
        RELEASE_NPC_MODEL
    )

    if releaseNPC and DoesEntityExist(releaseNPC) then
        PlaceObjectOnGroundProperly(releaseNPC)
        SetEntityInvincible(releaseNPC, true)
        SetBlockingOfNonTemporaryEvents(releaseNPC, true)
        FreezeEntityPosition(releaseNPC, true)
    end
end

-- Spawn NPC on resource start
CreateThread(function()
    Wait(2000)
    spawnReleaseNPC()
end)

-- Interaction thread: E key near release NPC
CreateThread(function()
    while true do
        if pendingSavedSkin and releaseNPC and DoesEntityExist(releaseNPC) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local npcCoords = GetEntityCoords(releaseNPC)
            local dist = #(playerCoords - npcCoords)

            if dist < 2.5 then
                VFW.ShowHelpNotification("~INPUT_CONTEXT~ Récupérer vos affaires")

                if VFW.Interact.JustPressed(0, 38) then -- E key
                    TriggerEvent('skinchanger:loadSkin', pendingSavedSkin)
                    policeNotif("Prison", "Vous avez récupéré vos affaires")
                    TriggerServerEvent("police:prison:clothesClaimed")
                    pendingSavedSkin = nil
                end

                Wait(0)
            else
                Wait(500)
            end
        else
            Wait(1000)
        end
    end
end)

-- ============================================================
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if releaseNPC and DoesEntityExist(releaseNPC) then
            DeleteEntity(releaseNPC)
            releaseNPC = nil
        end
    end
end)
