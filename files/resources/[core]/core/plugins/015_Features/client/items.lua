---@meta _
---@diagnostic disable: duplicate-doc-field

local function syncGraffitiFocus()
    Wait(200)
    if IsNuiFocused() then
        VFW.Nui._hasFocus = true
        VFW.Nui._hasCursor = true
    end
    while IsNuiFocused() do
        Wait(500)
    end
    VFW.Nui._hasFocus = false
    VFW.Nui._hasCursor = false
end

RegisterNetEvent("vfw:graffiti:use", function(type)
    VFW.CloseInventory()
    if type == "spray" then
        TriggerEvent("rtx_graffiti:OpenGraffitiMenuEvent")
    elseif type == "clean" then
        TriggerEvent("rtx_graffiti:GraffitiClean")
    end
    CreateThread(syncGraffitiFocus)
end)

local cig = false
local cigmodel = "prop_cs_ciggy_01"
local cig_net = nil
local cigar = false
local cigarmodel = "lux_prop_cigar_01_luxe"
local cigar_net = nil
local duration = 0



RegisterNetEvent("core:UseCigar", function()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()


    if IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(playerPed) then
        TriggerServerEvent("core:MiaCooperSousBBL69", "cigarette", 1)
        return
    end

    -- 🔹 Animación con props
    local animData = {
        "rick_drugemotes@animations",
        "cigarntorch_clip",
        "Cuban Cigar",
        AnimationOptions = {
            EmoteDuration = -1,
            EmoteLoop = true,
            EmoteMoving = true, -- ✅ permite caminar
            BlendInSpeed = 8.0,
            BlendOutSpeed = 8.0,
            Prop = 'rick_torchlighter',
            PropBone = 58869,
            PropPlacement = { 0.05, 0.03, 0.07, 0.0, 0.0, 70.0 },
            SecondProp = 'prop_sh_cigar_01',
            SecondPropBone = 4170,
            SecondPropPlacement = { 0.02, -0.02, 0.03, 0.0, 90.0, 0.0 },
        }

    }

    PlayAnimation(playerPed, animData)

    local maxDuration = 120000
    local elapsed = 0
    local active = true


    while active and elapsed < maxDuration do
        Wait(10)
        elapsed = elapsed + 10

        VFW.ShowHelpNotification("Presiona ~INPUT_PICKUP~ para dejar de fumar", true)


        if VFW.Interact.JustPressed(0, 38) then -- E
            active = false
        end
    end

    StopAnimation(playerPed)
end)


--COCAINE

RegisterNetEvent("core:CokeEffect", function()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()


    -- 🔹 Animación de consumo con props
    local animData = {
        "rick_drugemotes@animations",
        "cokesniff_clip",
        "Coke sniff",
        AnimationOptions = {
            EmoteDuration = 6000,
            EmoteLoop = false,
            BlendInSpeed = 8.0,
            BlendOutSpeed = 8.0,
            Prop = 'prop_meth_bag_01',
            PropBone = 57005,
            PropPlacement = { 0.1, -0.02, -0.02, 98.0, 2.0, -50.0 },
            SecondProp = 'tr_prop_tr_note_rolled_01a',
            SecondPropBone = 4170,
            SecondPropPlacement = { 0.03, -0.02, -0.03, 80.0, 0.0, 0.0 },
        }
    }

    PlayAnimation(playerPed, animData)
    Wait(6000)

    StopAnimation(playerPed)

    -- 🔹 Aplicar efectos visuales y físicos
    SetTimecycleModifier("spectator5")
    SetPedMotionBlur(playerPed, true)
    SetPedIsDrunk(playerPed, true)
    SetPedMoveRateOverride(playerId, 5.0)
    SetRunSprintMultiplierForPlayer(playerId, 1.10)
    AnimpostfxPlay("DrugsTrevorClownsFight", 4000, true)
    ShakeGameplayCam("VIBRATE_SHAKE", 2.5)

    -- 🔹 Duración del efecto
    Wait(35000)

    -- 🔻 Limpieza
    SetPedMoveRateOverride(playerId, 1.0)
    SetRunSprintMultiplierForPlayer(playerId, 1.0)
    SetPedIsDrunk(playerPed, false)
    SetPedMotionBlur(playerPed, false)
    ResetPedMovementClipset(playerPed)
    AnimpostfxStopAll()
    ShakeGameplayCam("VIBRATE_SHAKE", 0.0)
    SetTimecycleModifierStrength(0.0)

end)








RegisterNetEvent("core:FentanylEffect", function()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()


    -- 🔹 Animación de consumo con props
    local animData = {
        "rick_drugemotes@animations",
        "takingpills_clip",
        "Taking Pills",
        AnimationOptions = {
            Prop = 'prop_cs_pills',
            PropBone = 18905,
            PropPlacement = { 0.12, 0.03, 0.0, -57.0, 90.0, 0.0 },
        }
    }


    PlayAnimation(playerPed, animData)
    Wait(6000)

    StopAnimation(playerPed) -- ✅ Limpia props justo después de la animación

    -- 🔹 Activar efectos visuales
    SetTimecycleModifier("spectator5")
    SetPedMotionBlur(playerPed, true)
    SetPedIsDrunk(playerPed, true)
    SetPedMoveRateOverride(playerId, 5.0)
    SetRunSprintMultiplierForPlayer(playerId, 1.10)
    AnimpostfxPlay("DrugsTrevorClownsFight", 4000, true)
    ShakeGameplayCam("VIBRATE_SHAKE", 2.5)

    -- 🔹 Duración del efecto
    Wait(35000)

    -- 🔻 Limpieza de efectos visuales y físicos

    SetPedMoveRateOverride(playerId, 1.0)
    SetRunSprintMultiplierForPlayer(playerId, 1.0)
    SetPedIsDrunk(playerPed, false)
    SetPedMotionBlur(playerPed, false)
    ResetPedMovementClipset(playerPed)
    AnimpostfxStopAll()
    ShakeGameplayCam("VIBRATE_SHAKE", 0.0)
    SetTimecycleModifierStrength(0.0)

end)





RegisterNetEvent("core:WeedEffect", function()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()


    -- 🔹 Animación de consumo con prop
    local animData = {
        "rick_drugemotes@animations",
        "rollblunt1_clip",
        "Roll Blunt",
        AnimationOptions = {
            EmoteLoop = false,
            BlendInSpeed = 8.0,
            BlendOutSpeed = 8.0,
            Prop = 'p_cs_joint_02',
            PropBone = 18905,
            PropPlacement = { 0.13, 0.07, 0.02, 0.0, 30.0, 150.0 },
        }
    }

    PlayAnimation(playerPed, animData)
    Wait(35000)

    StopAnimation(playerPed)

    -- 🔹 Activar efectos visuales y físicos
    RequestAnimSet("MOVE_M@DRUNK@slightlydrunk")
    local timeout = GetGameTimer() + 5000
    while not HasAnimSetLoaded("MOVE_M@DRUNK@slightlydrunk") do
        Wait(0)
        if GetGameTimer() > timeout then
            break
        end
    end

    SetTimecycleModifier("spectator6")
    SetPedMotionBlur(playerPed, true)
    SetPedMovementClipset(playerPed, "MOVE_M@DRUNK@slightlydrunk", true)
    SetPedIsDrunk(playerPed, true)
    AnimpostfxPlay("ChopVision", 4000, true)
    ShakeGameplayCam("DRUNK_SHAKE", 1.0)

    -- 🔹 Duración del efecto
    Wait(35000)

    -- 🔻 Limpieza
    SetPedMoveRateOverride(playerId, 1.0)
    SetRunSprintMultiplierForPlayer(playerId, 1.0)
    SetPedIsDrunk(playerPed, false)
    SetPedMotionBlur(playerPed, false)
    ResetPedMovementClipset(playerPed)
    AnimpostfxStopAll()
    ShakeGameplayCam("DRUNK_SHAKE", 0.0)
    SetTimecycleModifierStrength(0.0)

end)


RegisterNetEvent("core:MethEffect", function()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()


    -- 🔹 Animación de consumo con props
    local animData = {
        "rick_drugemotes@animations",
        "methsmoke_clip",
        "Meth Pipe Smoking",
        AnimationOptions = {
            Prop = 'rick_torchlighter',
            PropBone = 58869,
            PropPlacement = { 0.04, 0.05, 0.05, 0.0, 21.0, 90.0 },
            SecondProp = 'prop_cs_meth_pipe',
            SecondPropBone = 4170,
            SecondPropPlacement = { 0.02, -0.01, -0.02, 90.0, 1.0, 0.0 },
        }
    }

    PlayAnimation(playerPed, animData)
    Wait(6000)

    StopAnimation(playerPed)

    -- 🔹 Activar efectos visuales y físicos
    RequestAnimSet("move_m@drunk@slightlydrunk")
    local timeout = GetGameTimer() + 5000
    while not HasAnimSetLoaded("move_m@drunk@slightlydrunk") do
        Wait(0)
        if GetGameTimer() > timeout then
            break
        end
    end

    SetPedMotionBlur(playerPed, true)
    SetPedMovementClipset(playerPed, "move_m@drunk@slightlydrunk", true)
    SetPedIsDrunk(playerPed, true)
    SetTimecycleModifier("spectator5")
    AnimpostfxPlay("SuccessMichael", 4000, true)
    ShakeGameplayCam("DRUNK_SHAKE", 1.5)

    -- 🔹 Duración del efecto
    Wait(35000)

    -- 🔻 Limpieza
    SetPedMoveRateOverride(playerId, 1.0)
    SetRunSprintMultiplierForPlayer(playerId, 1.0)
    SetPedIsDrunk(playerPed, false)
    SetPedMotionBlur(playerPed, false)
    ResetPedMovementClipset(playerPed)
    AnimpostfxStopAll()
    ShakeGameplayCam("DRUNK_SHAKE", 0.0)
    SetTimecycleModifierStrength(0.0)

end)


local usePince = false
local originalHair = nil

--- requestModel
---@param model any
---@return boolean
local function requestModel(model)
    RequestModel(model)
    local timeout = 50
    while not HasModelLoaded(model) and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end
    return HasModelLoaded(model)
end

--- requestAnimDict
---@param animDict any
local function requestAnimDict(animDict)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
end

RegisterNetEvent("core:UsePince", function()
    local ped = PlayerPedId()
    local currentHair = GetPedDrawableVariation(ped, 2)

    if currentHair == 0 then
        VFW.ShowNotification({ type = "ORANGE", content = "Vous n'avez pas de cheveux." })
        return
    end

    if not usePince then
        originalHair = {
            drawable = currentHair,
            texture = GetPedTextureVariation(ped, 2)
        }
        usePince = true
        local isMale = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01")
        local pinceHair = isMale and 73 or 83
        SetPedComponentVariation(ped, 2, pinceHair, 0, 2)
        VFW.ShowNotification({ type = "VERT", content = "Vous avez attaché vos cheveux." })
    else
        usePince = false
        if originalHair then
            SetPedComponentVariation(ped, 2, originalHair.drawable, originalHair.texture, 2)
        end
        VFW.ShowNotification({ type = "VERT", content = "Vous avez détaché vos cheveux." })
    end
end)

local isScratchCardOpen = false

RegisterNetEvent("core:UseScratchCard", function(config)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local seatIndex = -2
        for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
            if GetPedInVehicleSeat(vehicle, i) == ped then
                seatIndex = i
                break
            end
        end
        if seatIndex == -1 then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous ne pouvez pas gratter un ticket en conduisant"
            })
            return
        end
    end

    VFW.CloseInventory()
    isScratchCardOpen = true
    FreezeEntityPosition(ped, true)
    VFW.Nui.Focus(true, false)
    SendNUIMessage({
        action = "nui:scratchcard:open",
        data = config or {}
    })
end)

Citizen.CreateThread(function()
    while true do
        if isScratchCardOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNuiCallback("scratchcard:result", function(data, cb)
    local revealed = {}
    if data.revealed then
        for i = 1, 20 do
            revealed[i] = data.revealed[tostring(i - 1)] or data.revealed[i - 1] or false
        end
    end

    if data.next then
        TriggerServerEvent("core:scratchcard:close", {
            revealed = revealed,
            amount = data.amount or 0,
            next = true
        })
    else
        isScratchCardOpen = false
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        VFW.Nui.Focus(false, false)
        EnableAllControlActions(0)

        TriggerServerEvent("core:scratchcard:close", {
            revealed = revealed,
            amount = data.amount or 0
        })
    end

    cb({})
end)

RegisterNetEvent("core:scratchcard:nomore", function()
    isScratchCardOpen = false
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    VFW.Nui.Focus(false, false)
    EnableAllControlActions(0)
    SendNUIMessage({
        action = "nui:scratchcard:close"
    })
end)

local useMakeup = false

--- StartSceneMakeup
---@param cb function Callback function
local function StartSceneMakeup(cb)
    local propModel = "prop_makeup_brush"

    requestModel(propModel)
    SetModelAsNoLongerNeeded(propModel)

    requestAnimDict("ebrwny_spray")

    local propObject = VFW.OneSync.CreateObject(propModel, GetEntityCoords(VFW.PlayerData.ped))
    local xOffset, yOffset, zOffset = 0.08, -0.02, 0.0
    local xRot, yRot, zRot = 50.0, 90.0, 0.0

    AttachEntityToEntity(propObject, VFW.PlayerData.ped, 72, xOffset, yOffset, zOffset, xRot, yRot, zRot, true, true, false, true, 1, true)
    TaskPlayAnim(VFW.PlayerData.ped, "ebrwny_spray", "ebrwny_hair", 8.0, 8.0, -1, 16, 0, true, false, false)
    Wait(1500)

    Wait(4000)
    SetModelAsNoLongerNeeded(propModel)
    DeleteObject(propObject)
    ClearPedTasks(VFW.PlayerData.ped)

    cb()
end

RegisterNetEvent("core:UseMakeup", function()
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")

    if skin.sex ~= 0 then
        if not useMakeup then
            useMakeup = true
            StartSceneMakeup(function()
                SetPedHeadOverlay(VFW.PlayerData.ped, 4, 0, (0 / 10) + 0.0) -- Makeup + opacity
                SetPedHeadOverlay(VFW.PlayerData.ped, 8, 0, (0 / 10) + 0.0) -- Lipstick + opacity
            end)
        else
            useMakeup = false
            StartSceneMakeup(function()
                SetPedHeadOverlay(VFW.PlayerData.ped, 4, skin.makeup_1, (skin.makeup_2 / 10) + 0.0) -- Makeup + opacity
                SetPedHeadOverlay(VFW.PlayerData.ped, 8, skin.lipstick_1, (skin.lipstick_2 / 10) + 0.0) -- Lipstick + opacity
            end)
        end
    end
end)

--- Rick3D est un asset Tebex chiffré. Sans licence Keymaster, basculer sur props/anims GTA.
local function isRick3dConsumablesEnabled()
    return GetConvar("core_use_rick3d_consumables", "0") == "1"
        and GetResourceState("rick3d-drinkfood") == "started"
end

local function usesRick3dAssets(itemData)
    if not itemData then return false end
    if type(itemData.anim) == "string" and itemData.anim:sub(1, 7) == "rick3d@" then return true end
    if type(itemData.prop) == "string" and itemData.prop:sub(1, 7) == "rick3d_" then return true end
    if type(itemData.secondProp) == "string" and itemData.secondProp:sub(1, 7) == "rick3d_" then return true end
    return false
end

local function resolveConsumableFallback(itemData)
    local isFood = itemData.hunger and itemData.hunger > 0
    local isDrink = itemData.thirst and itemData.thirst > 0

    if isFood then
        return {
            animDict = "mp_player_inteat@burger",
            animName = "mp_player_int_eat_burger",
            propModel = "prop_sandwich_01",
            propBone = 18905,
            propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 },
        }
    end

    if isDrink then
        local propName = type(itemData.prop) == "string" and itemData.prop or ""
        if itemData.animName == "drinks7_clip" or propName:find("hotchocolate", 1, true) then
            return {
                animDict = "amb@world_human_drinking@coffee@male@idle_a",
                animName = "idle_c",
                propModel = "p_amb_coffeecup_01",
                propBone = 28422,
                propPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
            }
        end
        return {
            animDict = "amb@world_human_drinking@beer@male@idle_a",
            animName = "idle_c",
            propModel = "prop_ld_flow_bottle",
            propBone = 28422,
            propPlacement = { 0.0, 0.0, -0.05, 0.0, 0.0, 0.0 },
        }
    end

    return {
        animDict = "mp_player_inteat@burger",
        animName = "mp_player_int_eat_burger",
        propModel = "prop_food_bs_burg3",
        propBone = 18905,
        propPlacement = { 0.13, 0.05, 0.02, -50.0, 16.0, 60.0 },
    }
end

RegisterNetEvent("core:UseConsumable", function(itemName, itemData)
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(playerPed) then
        return
    end

    if not itemData then
        return
    end

    VFW.CloseInventory()

    local isFood = itemData.hunger and itemData.hunger > 0
    local isDrink = itemData.thirst and itemData.thirst > 0

    -- Support pour animations et props Rick3D personnalisés
    local animDict, animName, propModel, propBone, propPlacement
    local duration = itemData.duration or 8000

    -- Si l'item a une animation Rick3D personnalisée, l'utiliser
    if itemData.anim and itemData.animName then
        animDict = itemData.anim
        animName = itemData.animName
        propModel = itemData.prop or "prop_amb_beer_bottle"
        propBone = itemData.propBone or 58869
        propPlacement = itemData.propPlacement or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
    -- Sinon utiliser les animations par défaut
    elseif isFood then
        animDict = "mp_player_inteat@burger"
        animName = "mp_player_int_eat_burger"
        propModel = itemData.prop or "prop_food_bs_burg3"
        propBone = 28422
        propPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
        duration = 6000
    elseif isDrink then
        animDict = "amb@world_human_drinking@beer@male@idle_a"
        animName = "idle_a"
        propModel = itemData.prop or "prop_amb_beer_bottle"
        propBone = 28422
        propPlacement = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
        duration = 8000
    else
        return
    end

    local secondProp = itemData.secondProp
    local secondPropBone = itemData.secondPropBone
    local secondPropPlacement = itemData.secondPropPlacement

    if usesRick3dAssets(itemData) and not isRick3dConsumablesEnabled() then
        local fallback = resolveConsumableFallback(itemData)
        animDict = fallback.animDict
        animName = fallback.animName
        propModel = fallback.propModel
        propBone = fallback.propBone
        propPlacement = fallback.propPlacement
        secondProp = nil
        secondPropBone = nil
        secondPropPlacement = nil
    end

    local animData = {
        animDict,
        animName,
        itemName,
        AnimationOptions = {
            EmoteDuration = duration,
            EmoteLoop = false,
            EmoteMoving = true,
            BlendInSpeed = 8.0,
            BlendOutSpeed = 8.0,
            Prop = propModel,
            PropBone = propBone,
            PropPlacement = propPlacement,
            RotOrder = itemData.rotOrder,
            SecondProp = secondProp,
            SecondPropBone = secondPropBone,
            SecondPropPlacement = secondPropPlacement,
        }
    }

    SetPedCanHeadIk(playerPed, false)
    SetPedConfigFlag(playerPed, 36, true)

    SetFacialIdleAnimOverride(playerPed, "eating_1", 0)

    local consuming = true
    Citizen.CreateThread(function()
        while consuming do
            SetPedCanHeadIk(playerPed, false)
            Wait(0)
        end
    end)

    PlayAnimation(playerPed, animData)
    Wait(duration)
    StopAnimation(playerPed)

    consuming = false
    SetPedCanHeadIk(playerPed, true)
    SetPedConfigFlag(playerPed, 36, false)
    ClearFacialIdleAnimOverride(playerPed)

    if itemData.alcool and itemData.thirst then
        TriggerEvent("core:addAlcohol", itemData.thirst * 1000)
    end
end)
