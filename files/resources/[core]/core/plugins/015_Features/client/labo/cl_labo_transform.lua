local laboTransformSpots = {}
local laboTransformProps = {}
local isTransforming = false
local transformSpotsLoading = false
local isNearTransformSpot = false
local currentTransformSpot = nil
local keyMustBeReleased = false
local lastHelpNotif = 0

local PRESET_ANIMATIONS = {
    ["ramasser_sol"] = { dict = "pickup_object", anim = "pickup_low" },
    ["fouiller_sac"] = { dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", anim = "machinic_loop_mechandise" },
    ["cuisiner"] = { dict = "amb@prop_human_bbq@male@base", anim = "base" },
    ["melanger"] = { dict = "anim@gangops@facility@servers@", anim = "hotwire" },
    ["emballer"] = { dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", anim = "weed_inspecting_lo_right_hand_amy_skater_01" },
    ["couper"] = { dict = "anim@amb@business@weed@weed_sorting_out@", anim = "sorting_out_worker_b" },
    ["recolter_plante"] = { dict = "amb@medic@standing@kneel@base", anim = "base" },
    ["forger"] = { dict = "mini@repair", anim = "fixing_a_player" },
    ["assembler"] = { dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", anim = "weed_inspecting_lo_right_hand_amy_skater_01" },
    ["injecter"] = { dict = "mp_player_intdrink", anim = "loop_bottle" },
    ["piocher"] = { dict = "amb@world_human_gardener_plant@male@base", anim = "base" },
    ["scier"] = { dict = "amb@world_human_welding@male@base", anim = "base" },
    ["fabriquer"] = { dict = "amb@prop_human_seat_sewing@female@base", anim = "base" },
    ["recolter"] = { dict = "amb@medic@standing@kneel@base", anim = "base" },
    ["chimie_meth"] = {
        dict = "anim@amb@business@coc@coc_unpack_cut@", anim = "fullcut_cycle_cokecutter"
    },
    ["peser_meth"] = {
        dict = "mp_heists@keypad@", anim = "idle_a"
    },
    ["couper_cocaine"] = {
        dict = "anim@amb@business@coc@coc_unpack_cut@", anim = "fullcut_cycle_cokecutter"
    },
    ["presser_cocaine"] = {
        dict = "anim@amb@business@coc@coc_unpack_cut@", anim = "fullcut_cycle_cokecutter"
    }
}

local function RequestModelSync(model)
    if type(model) == "string" then model = GetHashKey(model) end
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function RequestAnimDictSync(dict)
    if not DoesAnimDictExist(dict) then return false end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function GetSpotAnimation(spot)
    if spot.animation_type == "custom" and spot.animation_dict and spot.animation_name then
        return { dict = spot.animation_dict, anim = spot.animation_name }
    elseif spot.animation_type == "predefined" and spot.animation_preset then
        local preset = PRESET_ANIMATIONS[spot.animation_preset]
        if preset then return preset end
    end
    return { dict = "anim@gangops@facility@servers@", anim = "hotwire" }
end

local function AttachAnimProp(ped, propModel, bone, placement)
    if not propModel or propModel == "" then return nil end
    if not RequestModelSync(propModel) then return nil end
    local hash = GetHashKey(propModel)
    local obj = CreateObject(hash, GetEntityCoords(ped), false, false, false)
    if not obj or not DoesEntityExist(obj) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    local p = placement or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, bone or 57005), p[1], p[2], p[3], p[4], p[5], p[6], true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function DeleteAnimProp(entity)
    if entity and DoesEntityExist(entity) then
        DetachEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function SpawnTransformProp(spotId, spot)
    if not spot.prop_model or spot.prop_model == "" then return end
    if laboTransformProps[spotId] and DoesEntityExist(laboTransformProps[spotId]) then
        DeleteEntity(laboTransformProps[spotId])
    end
    if not RequestModelSync(spot.prop_model) then return end
    local modelHash = GetHashKey(spot.prop_model)
    local prop = CreateObject(modelHash, spot.coords_x, spot.coords_y, spot.coords_z, false, false, false)
    if not DoesEntityExist(prop) then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    SetEntityHeading(prop, spot.rotation_z or 0.0)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityInvincible(prop, true)
    SetModelAsNoLongerNeeded(modelHash)
    laboTransformProps[spotId] = prop
end

local function DeleteTransformProp(spotId)
    if laboTransformProps[spotId] and DoesEntityExist(laboTransformProps[spotId]) then
        DeleteEntity(laboTransformProps[spotId])
        laboTransformProps[spotId] = nil
    end
end

local function SpawnAllTransformProps()
    for spotId, spot in pairs(laboTransformSpots) do
        SpawnTransformProp(spotId, spot)
    end
end

local function DeleteAllTransformProps()
    for spotId, _ in pairs(laboTransformProps) do
        DeleteTransformProp(spotId)
    end
end

local function LoadLaboTransformSpots(laboId)
    if transformSpotsLoading then return end
    transformSpotsLoading = true

    DeleteAllTransformProps()
    laboTransformSpots = {}
    if not laboId then
        transformSpotsLoading = false
        return
    end
    local spots = TriggerServerCallback("labo:getTransformPoints", laboId)
    if spots then
        for _, spot in ipairs(spots) do
            laboTransformSpots[spot.id] = spot
        end
    end
    SpawnAllTransformProps()
    transformSpotsLoading = false
end

local function StartTransform(spotId)
    local spot = laboTransformSpots[spotId]
    if not spot or isTransforming then return end

    local canTransform = TriggerServerCallback("labo:canTransform", spotId)
    if not canTransform or not canTransform.success then
        if canTransform and canTransform.message then
            VFW.ShowNotification({ type = "ROUGE", content = canTransform.message })
        end
        return
    end

    isTransforming = true
    CreateThread(function()
        while isTransforming do
            DisableControlAction(0, 38, true)
            Wait(0)
        end
    end)
    local playerPed = PlayerPedId()
    SetEntityHeading(playerPed, spot.rotation_z or 0.0)
    FreezeEntityPosition(playerPed, true)

    local anim = GetSpotAnimation(spot)
    if RequestAnimDictSync(anim.dict) then
        TaskPlayAnim(playerPed, anim.dict, anim.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    local propModel = spot.animation_prop
    if (not propModel or propModel == "") and anim.prop then
        propModel = anim.prop
    end
    local animProp = AttachAnimProp(playerPed, propModel, anim.propBone, anim.propPlacement)

    local itemData = VFW.Items[spot.output_item]
    local displayLabel = spot.label or (itemData and itemData.label) or spot.output_item or "inconnu"
    local duration = spot.transform_time or 3000

    -- pcall pour garantir que le cleanup ait lieu même si la NUI ProgressBar
    -- crash ou ne renvoie jamais nui:progress:finish.
    local ok, completed = pcall(function()
        return VFW.Nui.ProgressBar(string.format("Transformation de %s en cours...", displayLabel), duration, true)
    end)

    -- CLEANUP GARANTI: toujours exécuté avant tout retour
    DeleteAnimProp(animProp)
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    isTransforming = false

    if ok and completed then
        TriggerServerEvent("labo:completeTransform", spotId)
    end
end

RegisterNetEvent("labo:enterInterior", function(data)
    LoadLaboTransformSpots(data.id)
end)

RegisterNetEvent("labo:exitInterior", function()
    DeleteAllTransformProps()
    laboTransformSpots = {}
end)

RegisterNetEvent("labo:refreshPoints", function(laboId)
    LoadLaboTransformSpots(laboId)
end)

CreateThread(function()
    while true do
        local sleep = 500

        if isTransforming then
            if isNearTransformSpot then
                isNearTransformSpot = false
                currentTransformSpot = nil
            end
            keyMustBeReleased = true
            sleep = 250
        elseif next(laboTransformSpots) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local foundSpot = nil

            for spotId, spot in pairs(laboTransformSpots) do
                local spotCoords = vector3(spot.coords_x, spot.coords_y, spot.coords_z)
                local distance = #(playerCoords - spotCoords)

                if distance < 8.0 then
                    sleep = 0
                    if distance > 1.5 then
                        local mx, my, mz = spot.coords_x, spot.coords_y, spot.coords_z
                        if spot.marker_x and spot.marker_y and spot.marker_z then
                            mx, my, mz = spot.marker_x, spot.marker_y, spot.marker_z
                        end
                        DrawMarker(22, mx, my, mz - 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.4, 0, 100, 255, 200, true, true, 2, false, nil, nil, false)
                    end

                    if not foundSpot then
                        local ix, iy, iz = spot.coords_x, spot.coords_y, spot.coords_z
                        if spot.marker_x and spot.marker_y and spot.marker_z then
                            ix, iy, iz = spot.marker_x, spot.marker_y, spot.marker_z
                        end
                        if #(playerCoords - vector3(ix, iy, iz)) < 1.5 then
                            foundSpot = { id = spotId, spot = spot }
                        end
                    end
                end
            end

            if foundSpot then
                local isNewSpot = not isNearTransformSpot or currentTransformSpot ~= foundSpot.id
                if isNewSpot then
                    isNearTransformSpot = true
                    currentTransformSpot = foundSpot.id
                end

                local itemData = VFW.Items[foundSpot.spot.output_item]
                local displayLabel = foundSpot.spot.label or (itemData and itemData.label) or foundSpot.spot.output_item or "Transformation"

                if isNewSpot and VFW.Interact.Pressed(0, 38) then
                    keyMustBeReleased = true
                end

                local now = GetGameTimer()
                if isNewSpot or now - lastHelpNotif > 250 then
                    VFW.ShowHelpNotification(string.format("~b~Transformation de %s~s~\n~w~Appuyez sur ~y~[E]~w~ pour transformer", displayLabel))
                    lastHelpNotif = now
                end

                if keyMustBeReleased then
                    if not VFW.Interact.Pressed(0, 38) then
                        keyMustBeReleased = false
                    end
                elseif VFW.Interact.JustPressed(0, 38) then
                    keyMustBeReleased = true
                    CreateThread(function()
                        local deadline = GetGameTimer() + 7000
                        while GetGameTimer() < deadline and not isTransforming do
                            DisableControlAction(0, 38, true)
                            Wait(0)
                        end
                    end)
                    StartTransform(foundSpot.id)
                end
            elseif isNearTransformSpot then
                isNearTransformSpot = false
                currentTransformSpot = nil
                keyMustBeReleased = false
                lastHelpNotif = 0
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        for spotId, spot in pairs(laboTransformSpots) do
            if spot.prop_model and spot.prop_model ~= "" then
                if not laboTransformProps[spotId] or not DoesEntityExist(laboTransformProps[spotId]) then
                    SpawnTransformProp(spotId, spot)
                end
            end
        end
    end
end)
