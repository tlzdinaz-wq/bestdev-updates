local laboHarvestSpots = {}
local laboHarvestProps = {}
local isHarvesting = false
local harvestSpotsLoading = false
local isNearHarvestSpot = false
local currentHarvestSpot = nil
local keyMustBeReleased = false
local lastHelpNotif = 0

local PRESET_ANIMATIONS = {
    ["ramasser_sol"] = { dict = "pickup_object", anim = "pickup_low" },
    ["fouiller_sac"] = { dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", anim = "machinic_loop_mechandise" },
    ["cuisiner"] = { dict = "amb@prop_human_bbq@male@base", anim = "base" },
    ["melanger"] = { dict = "anim@amb@business@coc@coc_packing_hi@", anim = "coc_packing_hi" },
    ["emballer"] = { dict = "anim@amb@business@weed@weed_packing_hi@male", anim = "weed_packing_hi_male" },
    ["couper"] = { dict = "anim@amb@business@weed@weed_sorting_out@", anim = "sorting_out_worker_b" },
    ["recolter_plante"] = { dict = "amb@medic@standing@kneel@base", anim = "base" },
    ["forger"] = { dict = "mini@repair", anim = "fixing_a_player" },
    ["assembler"] = { dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", anim = "weed_inspecting_lo_right_hand_amy_skater_01" },
    ["injecter"] = { dict = "mp_player_intdrink", anim = "loop_bottle" },
    ["piocher"] = { dict = "melee@large_wpn@streamed_core", anim = "ground_attack_on_spot" },
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
    return { dict = "amb@medic@standing@kneel@base", anim = "base" }
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

local function SpawnHarvestProp(spotId, spot)
    if not spot.prop_model or spot.prop_model == "" then return end
    if laboHarvestProps[spotId] and DoesEntityExist(laboHarvestProps[spotId]) then
        DeleteEntity(laboHarvestProps[spotId])
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
    laboHarvestProps[spotId] = prop
end

local function DeleteHarvestProp(spotId)
    if laboHarvestProps[spotId] and DoesEntityExist(laboHarvestProps[spotId]) then
        DeleteEntity(laboHarvestProps[spotId])
        laboHarvestProps[spotId] = nil
    end
end

local function SpawnAllHarvestProps()
    for spotId, spot in pairs(laboHarvestSpots) do
        SpawnHarvestProp(spotId, spot)
    end
end

local function DeleteAllHarvestProps()
    for spotId, _ in pairs(laboHarvestProps) do
        DeleteHarvestProp(spotId)
    end
end

local function LoadLaboHarvestSpots(laboId)
    if harvestSpotsLoading then return end
    harvestSpotsLoading = true

    DeleteAllHarvestProps()
    laboHarvestSpots = {}
    if not laboId then
        harvestSpotsLoading = false
        return
    end
    local spots = TriggerServerCallback("labo:getHarvestPoints", laboId)
    if spots then
        for _, spot in ipairs(spots) do
            laboHarvestSpots[spot.id] = spot
        end
    end
    SpawnAllHarvestProps()
    harvestSpotsLoading = false
end

local function StartHarvest(spotId)
    local spot = laboHarvestSpots[spotId]
    if not spot or isHarvesting then return end

    local canHarvest = TriggerServerCallback("labo:canHarvest", spotId)
    if not canHarvest or not canHarvest.success then
        if canHarvest and canHarvest.message then
            VFW.ShowNotification({ type = "ROUGE", content = canHarvest.message })
        end
        return
    end

    isHarvesting = true
    CreateThread(function()
        while isHarvesting do
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

    local itemData = VFW.Items[spot.item_output]
    local displayLabel = spot.label or (itemData and itemData.label) or spot.item_output or "inconnu"
    local duration = spot.harvest_time or 3000

    -- pcall pour garantir que le cleanup ait lieu même si la NUI ProgressBar
    -- crash ou ne renvoie jamais nui:progress:finish.
    local ok, completed = pcall(function()
        return VFW.Nui.ProgressBar(string.format("Récolte de %s en cours...", displayLabel), duration, true, false, true)
    end)

    -- CLEANUP GARANTI: toujours exécuté avant tout retour
    DeleteAnimProp(animProp)
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    isHarvesting = false

    if ok and completed then
        TriggerServerEvent("labo:completeHarvest", spotId)
    else
        TriggerServerEvent("labo:stopHarvesting", spotId)
    end
end

RegisterNetEvent("labo:enterInterior", function(data)
    LoadLaboHarvestSpots(data.id)
end)

RegisterNetEvent("labo:exitInterior", function()
    DeleteAllHarvestProps()
    laboHarvestSpots = {}
end)

RegisterNetEvent("labo:refreshPoints", function(laboId)
    LoadLaboHarvestSpots(laboId)
end)

CreateThread(function()
    while true do
        local sleep = 500

        if isHarvesting then
            if isNearHarvestSpot then
                isNearHarvestSpot = false
                currentHarvestSpot = nil
            end
            keyMustBeReleased = true
            sleep = 250
        elseif next(laboHarvestSpots) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local foundSpot = nil

            for spotId, spot in pairs(laboHarvestSpots) do
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

                    local ix, iy, iz = spot.coords_x, spot.coords_y, spot.coords_z
                    if spot.marker_x and spot.marker_y and spot.marker_z then
                        ix, iy, iz = spot.marker_x, spot.marker_y, spot.marker_z
                    end
                    local interactDist = #(playerCoords - vector3(ix, iy, iz))
                    -- Garder le spot LE PLUS PROCHE (pas le premier itéré), sinon
                    -- avec plusieurs points côte-à-côte le `pairs()` peut sélectionner
                    -- un spot voisin déjà occupé par un autre joueur.
                    if interactDist < 1.5 and (not foundSpot or interactDist < foundSpot.dist) then
                        foundSpot = { id = spotId, spot = spot, dist = interactDist }
                    end
                end
            end

            if foundSpot then
                local isNewSpot = not isNearHarvestSpot or currentHarvestSpot ~= foundSpot.id
                if isNewSpot then
                    isNearHarvestSpot = true
                    currentHarvestSpot = foundSpot.id
                end

                local itemData = VFW.Items[foundSpot.spot.item_output]
                local displayLabel = foundSpot.spot.label or (itemData and itemData.label) or foundSpot.spot.item_output or "Récolte"

                if isNewSpot and VFW.Interact.Pressed(0, 38) then
                    keyMustBeReleased = true
                end

                local now = GetGameTimer()
                if isNewSpot or now - lastHelpNotif > 250 then
                    VFW.ShowHelpNotification(string.format("~b~Récolte de %s~s~\n~w~Appuyez sur ~y~[E]~w~ pour récolter", displayLabel))
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
                        while GetGameTimer() < deadline and not isHarvesting do
                            DisableControlAction(0, 38, true)
                            Wait(0)
                        end
                    end)
                    StartHarvest(foundSpot.id)
                end
            elseif isNearHarvestSpot then
                isNearHarvestSpot = false
                currentHarvestSpot = nil
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
        for spotId, spot in pairs(laboHarvestSpots) do
            if spot.prop_model and spot.prop_model ~= "" then
                if not laboHarvestProps[spotId] or not DoesEntityExist(laboHarvestProps[spotId]) then
                    SpawnHarvestProp(spotId, spot)
                end
            end
        end
    end
end)
