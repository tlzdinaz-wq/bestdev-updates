---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Config
-- ============================================================
local CRUTCH_MODEL = -1035084591 -- v_med_crutch01
local CLIP_SET = "move_lester_CaneUp"
local PICKUP_ANIM = { dict = "pickup_object", name = "pickup_low" }
local LOAD_TIMEOUT = 5000 -- ms

local Localization = {
    ragdoll = "Vous ne pouvez pas utiliser de béquille après avoir fait une chute!",
    falling = "Vous ne pouvez pas utiliser de béquille pendant une chute!",
    combat  = "Vous ne pouvez pas utiliser de béquille pendant un combat!",
    dead    = "Vous ne pouvez pas utiliser de béquille lorsque vous êtes en coma!",
    vehicle = "Vous ne pouvez pas utiliser de béquille dans un véhicule!",
    weapon  = "Vous ne pouvez pas utiliser de béquille lorsque vous avez équipé une arme!",
    pickup  = "Appuyez sur ~INPUT_PICKUP~ pour prendre votre béquille!"
}

-- ============================================================
-- State
-- ============================================================
local isUsingCrutch = false
local crutchObject = nil
local walkStyle = nil

-- ============================================================
-- Safe async loaders (with timeout)
-- ============================================================

---@param set string
---@return boolean
local function safeLoadClipSet(set)
    if HasClipSetLoaded(set) then return true end
    RequestClipSet(set)
    local startTime = GetGameTimer()
    while not HasClipSetLoaded(set) do
        if (GetGameTimer() - startTime) > LOAD_TIMEOUT then return false end
        Wait(10)
    end
    return true
end

---@param dict string
---@return boolean
local function safeLoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local startTime = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if (GetGameTimer() - startTime) > LOAD_TIMEOUT then return false end
        Wait(10)
    end
    return true
end

---@param model number
---@return boolean
local function safeLoadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local startTime = GetGameTimer()
    while not HasModelLoaded(model) do
        if (GetGameTimer() - startTime) > LOAD_TIMEOUT then return false end
        Wait(10)
    end
    return true
end

-- ============================================================
-- Crutch logic
-- ============================================================

--- Create and attach crutch object to player
---@return boolean success
local function createCrutch()
    if not safeLoadModel(CRUTCH_MODEL) then return false end

    local playerPed = PlayerPedId()
    crutchObject = CreateObject(CRUTCH_MODEL, GetEntityCoords(playerPed), false, false, false)
    AttachEntityToEntity(crutchObject, playerPed, 70, 1.18, -0.36, -0.20, -20.0, -87.0, -20.0, true, true, false, true, 1, true)
    return true
end

--- Check if player can equip crutch
---@return boolean canEquip, string|nil reason
local function canPlayerEquipCrutch()
    local playerPed = PlayerPedId()
    local _, weaponHash = GetCurrentPedWeapon(playerPed)

    if weaponHash ~= 0 and weaponHash ~= joaat("WEAPON_UNARMED") then
        return false, Localization.weapon
    elseif IsPedInAnyVehicle(playerPed, false) then
        return false, Localization.vehicle
    elseif IsEntityDead(playerPed) then
        return false, Localization.dead
    elseif IsPedInMeleeCombat(playerPed) then
        return false, Localization.combat
    elseif IsPedFalling(playerPed) then
        return false, Localization.falling
    elseif IsPedRagdoll(playerPed) then
        return false, Localization.ragdoll
    end

    return true
end

--- Unequip crutch and restore walk style
local function unequipCrutch()
    isUsingCrutch = false
    if DoesEntityExist(crutchObject) then
        DeleteEntity(crutchObject)
    end
    crutchObject = nil

    local playerPed = PlayerPedId()
    SetPedMaxMoveBlendRatio(playerPed, 3.0)
    if walkStyle then
        if safeLoadClipSet(walkStyle) then
            SetPedMovementClipset(playerPed, walkStyle, 1.0)
            RemoveClipSet(walkStyle)
        end
    else
        ResetPedMovementClipset(playerPed)
    end
end

--- Equip crutch with monitoring thread
local function equipCrutch()
    local playerPed = PlayerPedId()
    local canEquip, msg = canPlayerEquipCrutch()
    if not canEquip then
        VFW.ShowNotification({ type = "ERROR", content = msg })
        return
    end

    if not safeLoadClipSet(CLIP_SET) then return end
    SetPedMovementClipset(playerPed, CLIP_SET, 1.0)
    RemoveClipSet(CLIP_SET)
    SetPedMaxMoveBlendRatio(playerPed, 1.0)

    if not createCrutch() then return end
    isUsingCrutch = true

    -- Disable sprint, jump & melee every frame
    CreateThread(function()
        while isUsingCrutch do
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 140, true) -- Melee light
            DisableControlAction(0, 141, true) -- Melee heavy
            DisableControlAction(0, 142, true) -- Melee alternate
            Wait(0)
        end
    end)

    CreateThread(function()
        local fallCount = 0

        while isUsingCrutch do
            Wait(500)

            local ped = PlayerPedId()
            local _, weaponHash = GetCurrentPedWeapon(ped)
            local hasWeapon = weaponHash ~= 0 and weaponHash ~= joaat("WEAPON_UNARMED")

            if IsPedInAnyVehicle(ped, true) or hasWeapon then
                -- Hide crutch in vehicle / with weapon
                if DoesEntityExist(crutchObject) then
                    DeleteEntity(crutchObject)
                    crutchObject = nil
                end

            elseif not crutchObject or not DoesEntityExist(crutchObject) then
                -- Recreate crutch after it was hidden
                Wait(750)
                if not isUsingCrutch then break end
                createCrutch()

            elseif not IsEntityAttachedToEntity(crutchObject, ped) then
                -- Crutch detached: let player pick it up
                local traceObject = true

                while traceObject and isUsingCrutch do
                    local wait = 0
                    if not DoesEntityExist(crutchObject) then
                        traceObject = false
                    elseif IsPedFalling(ped) or IsPedRagdoll(ped) then
                        wait = 250
                    else
                        local dist = #(GetEntityCoords(ped) - GetEntityCoords(crutchObject))
                        if dist < 2.0 then
                            VFW.ShowHelpNotification(Localization.pickup)
                            if VFW.Interact.JustReleased(0, 38) then
                                if safeLoadAnimDict(PICKUP_ANIM.dict) then
                                    TaskPlayAnim(ped, PICKUP_ANIM.dict, PICKUP_ANIM.name, 2.0, 2.0, -1, 0, 0, false, false, false)

                                    local attempts = 0
                                    while not IsEntityPlayingAnim(ped, PICKUP_ANIM.dict, PICKUP_ANIM.name, 3) and attempts < 25 do
                                        attempts = attempts + 1
                                        Wait(50)
                                    end

                                    if attempts >= 25 then
                                        ClearPedTasks(ped)
                                    else
                                        Wait(800)
                                    end

                                    RemoveAnimDict(PICKUP_ANIM.dict)
                                end

                                DeleteEntity(crutchObject)
                                crutchObject = nil
                                Wait(900)
                                createCrutch()
                                traceObject = false
                            end
                        elseif dist < 200.0 then
                            wait = dist * 10
                        else
                            traceObject = false
                        end
                    end

                    Wait(wait)
                end

            elseif IsPedRagdoll(ped) or IsEntityDead(ped) then
                DetachEntity(crutchObject, true, true)

            elseif IsPedInMeleeCombat(ped) then
                Wait(400)
                DetachEntity(crutchObject, true, true)

            elseif IsPedFalling(ped) then
                fallCount = fallCount + 1
                if fallCount > 3 then
                    DetachEntity(crutchObject, true, true)
                    fallCount = 0
                end

            elseif fallCount > 0 then
                fallCount = fallCount - 1
            end
        end
    end)
end

--- Toggle crutch on/off
local function toggleCrutch()
    if isUsingCrutch then
        unequipCrutch()
    else
        equipCrutch()
    end
end

-- ============================================================
-- Exports
-- ============================================================
exports('SetWalkStyle', function(walk)
    walkStyle = walk
end)

-- ============================================================
-- Event
-- ============================================================
RegisterNetEvent("sn_sams:useBequille", function()
    toggleCrutch()
end)
