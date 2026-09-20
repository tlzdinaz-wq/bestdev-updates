local dynamicTransformSpots = {}
local dynamicTransformProps = {}
local dynamicTransformBlips = {}
local isNearTransformSpot = false
local currentTransformSpot = nil
local isTransforming = false
local currentTransformSpotId = nil

local RefreshTransformSpotBlips

local PRESET_ANIMATIONS = {
    ["ramasser_sol"]    = { dict = "pickup_object",                              anim = "pickup_low",                                       prop = nil },
    ["fouiller_sac"]    = { dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",   anim = "machinic_loop_mechandise",                         prop = nil },
    ["cuisiner"]        = { dict = "amb@prop_human_bbq@male@base",               anim = "base",                                             prop = nil },
    ["melanger"]        = { dict = "anim@amb@business@coc@coc_packing_hi@",      anim = "coc_packing_hi",                                   prop = nil },
    ["emballer"]        = { dict = "anim@amb@business@weed@weed_packing_hi@male",anim = "weed_packing_hi_male",                             prop = nil },
    ["couper"]          = { dict = "anim@amb@business@weed@weed_sorting_out@",   anim = "sorting_out_worker_b",                             prop = nil },
    ["recolter_plante"] = { dict = "amb@medic@standing@kneel@base",              anim = "base",                                             prop = nil },
    ["forger"]          = { dict = "mini@repair",                                anim = "fixing_a_player",                                  prop = nil },
    ["assembler"]       = { dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", anim = "weed_inspecting_lo_right_hand_amy_skater_01", prop = nil },
    ["injecter"]        = { dict = "mp_player_intdrink",                         anim = "loop_bottle",                                      prop = nil },
    ["piocher"]         = { dict = "melee@large_wpn@streamed_core",              anim = "ground_attack_on_spot",                            prop = nil },
    ["scier"]           = { dict = "amb@world_human_welding@male@base",          anim = "base",                                             prop = nil },
    ["presser_cocaine"] = { dict = "anim@amb@business@coc@coc_unpack_cut@",      anim = "fullcut_cycle_cokecutter",                         prop = nil },
    ["couper_cocaine"]  = { dict = "anim@amb@business@coc@coc_unpack_cut@",      anim = "fullcut_cycle_cokecutter",                         prop = nil },
    ["chimie_meth"]     = { dict = "anim@amb@business@coc@coc_unpack_cut@",      anim = "fullcut_cycle_cokecutter",                         prop = nil },
    ["peser_meth"]      = { dict = "mp_heists@keypad@",                          anim = "idle_a",                                           prop = nil },
    ["fabriquer"]       = { dict = "amb@prop_human_seat_sewing@female@base",     anim = "base",                                             prop = nil },
}

local function RequestAnimDictSync(dict)
    if not dict or dict == "" then return false end
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
        return { dict = spot.animation_dict, anim = spot.animation_name, prop = spot.animation_prop }
    elseif spot.animation_type == "predefined" and spot.animation_preset then
        local preset = PRESET_ANIMATIONS[spot.animation_preset]
        if preset then
            return { dict = preset.dict, anim = preset.anim, prop = preset.prop }
        end
    end
    return { dict = "anim@amb@business@coc@coc_unpack_cut@", anim = "fullcut_cycle_cokecutter", prop = nil }
end

local function CanAccessSpot(spot)
    if not spot.faction_restriction or spot.faction_restriction == "" then
        return true
    end

    local playerFaction = VFW.PlayerData.faction
    if not playerFaction or playerFaction.name ~= spot.faction_restriction then
        return false
    end

    if spot.faction_grade_min and spot.faction_grade_min > 0 then
        local playerGrade = playerFaction.grade or 0
        if playerGrade < spot.faction_grade_min then
            return false
        end
    end

    return true
end

local function RequestModelSync(model)
    if type(model) == "string" then
        model = GetHashKey(model)
    end
    if not IsModelInCdimage(model) then
        return false
    end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function SpawnTransformSpotProp(spotId, spot)
    if not spot.prop_model or spot.prop_model == "" then
        return nil
    end

    if dynamicTransformProps[spotId] and DoesEntityExist(dynamicTransformProps[spotId]) then
        DeleteEntity(dynamicTransformProps[spotId])
    end

    if not RequestModelSync(spot.prop_model) then
        return nil
    end

    local modelHash = GetHashKey(spot.prop_model)
    local prop = CreateObject(modelHash, spot.coords_x, spot.coords_y, spot.coords_z, false, false, false)

    if not DoesEntityExist(prop) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    SetEntityHeading(prop, spot.rotation_z or 0.0)
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, true, true)
    SetEntityInvincible(prop, true)
    SetEntityCanBeDamaged(prop, false)

    SetModelAsNoLongerNeeded(modelHash)

    dynamicTransformProps[spotId] = prop
    return prop
end

local function DeleteTransformSpotProp(spotId)
    if dynamicTransformProps[spotId] and DoesEntityExist(dynamicTransformProps[spotId]) then
        DeleteEntity(dynamicTransformProps[spotId])
        dynamicTransformProps[spotId] = nil
    end
end

local function CreateTransformSpotBlip(spotId, spot)
    if not spot.blip_enabled then return end
    if not CanAccessSpot(spot) then return end

    if dynamicTransformBlips[spotId] and DoesBlipExist(dynamicTransformBlips[spotId]) then
        RemoveBlip(dynamicTransformBlips[spotId])
    end

    local blip = AddBlipForCoord(spot.coords_x, spot.coords_y, spot.coords_z)
    SetBlipSprite(blip, spot.blip_sprite or 1)
    SetBlipColour(blip, spot.blip_color or 1)
    SetBlipScale(blip, spot.blip_scale or 0.5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(spot.blip_label or spot.name)
    EndTextCommandSetBlipName(blip)

    dynamicTransformBlips[spotId] = blip
end

local function DeleteTransformSpotBlip(spotId)
    if dynamicTransformBlips[spotId] and DoesBlipExist(dynamicTransformBlips[spotId]) then
        RemoveBlip(dynamicTransformBlips[spotId])
        dynamicTransformBlips[spotId] = nil
    end
end

local function SpawnAllTransformSpots()
    for spotId, spot in pairs(dynamicTransformSpots) do
        SpawnTransformSpotProp(spotId, spot)
        CreateTransformSpotBlip(spotId, spot)
    end
end

local function DeleteAllTransformSpots()
    for spotId, _ in pairs(dynamicTransformProps) do
        DeleteTransformSpotProp(spotId)
    end
    for spotId, _ in pairs(dynamicTransformBlips) do
        DeleteTransformSpotBlip(spotId)
    end
end

local spotsLoaded = false
local spotsLoading = false

local function LoadDynamicTransformSpots()
    if spotsLoading then return end
    spotsLoading = true

    if not TriggerServerCallback then
        spotsLoading = false
        Citizen.SetTimeout(2000, LoadDynamicTransformSpots)
        return
    end

    local spots = TriggerServerCallback("illegalBuilder:getTransformSpots")
    if not spots then
        spotsLoading = false
        Citizen.SetTimeout(5000, function()
            if not spotsLoaded then
                LoadDynamicTransformSpots()
            end
        end)
        return
    end

    DeleteAllTransformSpots()
    dynamicTransformSpots = {}

    for _, spot in pairs(spots) do
        dynamicTransformSpots[spot.id] = spot
    end
    spotsLoaded = true

    SpawnAllTransformSpots()
    spotsLoading = false
end

local function StartTransform(spotId)
    local spot = dynamicTransformSpots[spotId]
    if not spot then return end

    if not CanAccessSpot(spot) then
        return
    end

    if isTransforming then
        return
    end

    local canTransform = TriggerServerCallback("illegalBuilder:canTransform", spotId)
    if not canTransform or not canTransform.success then
        if canTransform and canTransform.message then
            VFW.ShowNotification({ type = "ROUGE", content = canTransform.message })
        end
        return
    end

    isTransforming = true
    currentTransformSpotId = spotId

    local playerPed = PlayerPedId()
    SetEntityHeading(playerPed, spot.rotation_z or 0.0)

    FreezeEntityPosition(playerPed, true)

    local anim = GetSpotAnimation(spot)
    if RequestAnimDictSync(anim.dict) then
        TaskPlayAnim(playerPed, anim.dict, anim.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    local itemData = VFW.Items[spot.output_item]
    local itemLabel = itemData and itemData.label or spot.output_item or "inconnu"

    local duration = spot.transform_time or 3000

    -- pcall pour garantir le cleanup même si la NUI ProgressBar crash
    -- ou ne renvoie jamais nui:progress:finish.
    local ok, completed = pcall(function()
        return VFW.Nui.ProgressBar(string.format("Transformation de %s en cours...", itemLabel), duration, true)
    end)

    -- CLEANUP GARANTI: toujours exécuté
    local finishedSpotId = currentTransformSpotId
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    isTransforming = false
    currentTransformSpotId = nil

    if ok and completed and finishedSpotId then
        TriggerServerEvent("illegalBuilder:completeTransform", finishedSpotId)
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    LoadDynamicTransformSpots()
end)

AddEventHandler("vfw:playerLoaded", function()
    Citizen.Wait(1000)
    LoadDynamicTransformSpots()
    Citizen.Wait(2000)
    RefreshTransformSpotBlips()
end)

AddEventHandler("playerSpawned", function()
    Citizen.Wait(1000)
    if not spotsLoaded then
        LoadDynamicTransformSpots()
    end
end)

Citizen.CreateThread(function()
    while true do
        if isTransforming then
            if isNearTransformSpot then
                isNearTransformSpot = false
                currentTransformSpot = nil
            end
            Citizen.Wait(250)
        else
            local sleep = 500
            local playerCoords = GetEntityCoords(PlayerPedId())
            local foundSpot = nil

            for spotId, spot in pairs(dynamicTransformSpots) do
                local spotCoords = vector3(spot.coords_x, spot.coords_y, spot.coords_z)
                local distance = #(playerCoords - spotCoords)

                if distance < 8.0 then
                    sleep = 0

                    if distance > 1.5 then
                        local markerX, markerY, markerZ
                        if spot.marker_x and spot.marker_y and spot.marker_z then
                            markerX, markerY, markerZ = spot.marker_x, spot.marker_y, spot.marker_z
                        else
                            markerX, markerY, markerZ = spotCoords.x, spotCoords.y, spotCoords.z
                        end
                        DrawMarker(
                            22,
                            markerX, markerY, markerZ - 0.4,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.4, 0.4, 0.4,
                            0, 100, 255, 200,
                            true, true,
                            2, false,
                            nil, nil, false
                        )
                    end

                    if not foundSpot then
                        local interactCoords
                        if spot.marker_x and spot.marker_y and spot.marker_z then
                            interactCoords = vector3(spot.marker_x, spot.marker_y, spot.marker_z)
                        else
                            interactCoords = spotCoords
                        end
                        if #(playerCoords - interactCoords) < 1.5 then
                            foundSpot = { id = spotId, spot = spot }
                        end
                    end
                end
            end

            if foundSpot then
                if not isNearTransformSpot or currentTransformSpot ~= foundSpot.id then
                    isNearTransformSpot = true
                    currentTransformSpot = foundSpot.id
                end

                local canAccess = CanAccessSpot(foundSpot.spot)
                local accessText = canAccess and "~w~Appuyez sur ~y~[E]~w~ pour transformer" or "~r~Accès restreint"

                VFW.ShowHelpNotification(string.format("~b~%s~s~\n%s", foundSpot.spot.name or "Transformation", accessText))

                if canAccess and VFW.Interact.JustPressed(0, 38) then
                    StartTransform(foundSpot.id)
                end
            else
                if isNearTransformSpot then
                    isNearTransformSpot = false
                    currentTransformSpot = nil
                end
            end

            Citizen.Wait(sleep)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)

        for spotId, spot in pairs(dynamicTransformSpots) do
            local prop = dynamicTransformProps[spotId]
            if spot.prop_model and spot.prop_model ~= "" then
                if not prop or not DoesEntityExist(prop) then
                    SpawnTransformSpotProp(spotId, spot)
                end
            end
        end
    end
end)

RegisterNetEvent("illegalBuilder:refreshTransformSpots", function(spots)
    DeleteAllTransformSpots()
    dynamicTransformSpots = {}

    if spots then
        for _, spot in pairs(spots) do
            dynamicTransformSpots[spot.id] = spot
        end
        spotsLoaded = true
    end

    SpawnAllTransformSpots()
end)

RegisterNetEvent("illegalBuilder:syncTransformSpots")
AddEventHandler("illegalBuilder:syncTransformSpots", function(spots)
    DeleteAllTransformSpots()
    dynamicTransformSpots = {}

    if spots then
        for _, spot in pairs(spots) do
            dynamicTransformSpots[spot.id] = spot
        end
        spotsLoaded = true
    end

    SpawnAllTransformSpots()
end)

RegisterNetEvent("illegalBuilder:transformSpotCreated", function(spot)
    if not spot or not spot.id then return end
    dynamicTransformSpots[spot.id] = spot
    SpawnTransformSpotProp(spot.id, spot)
    CreateTransformSpotBlip(spot.id, spot)
end)

RegisterNetEvent("illegalBuilder:transformSpotUpdated", function(spot)
    if not spot or not spot.id then return end
    DeleteTransformSpotProp(spot.id)
    DeleteTransformSpotBlip(spot.id)
    dynamicTransformSpots[spot.id] = spot
    SpawnTransformSpotProp(spot.id, spot)
    CreateTransformSpotBlip(spot.id, spot)
end)

RegisterNetEvent("illegalBuilder:transformSpotDeleted", function(spotId)
    DeleteTransformSpotProp(spotId)
    DeleteTransformSpotBlip(spotId)
    dynamicTransformSpots[spotId] = nil
end)

RegisterNetEvent("illegalBuilder:transformComplete", function(spotId, outputItem, quantity)
end)

RegisterNetEvent("illegalBuilder:transformFailed", function(message)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteAllTransformSpots()
        if isTransforming then
            FreezeEntityPosition(PlayerPedId(), false)
            isTransforming = false
            currentTransformSpotId = nil
        end
    end
end)

exports('getDynamicTransformSpots', function()
    return dynamicTransformSpots
end)

exports('getDynamicTransformProp', function(spotId)
    return dynamicTransformProps[spotId]
end)

exports('refreshDynamicTransformSpots', function()
    LoadDynamicTransformSpots()
end)

exports('isTransforming', function()
    return isTransforming
end)

RefreshTransformSpotBlips = function()
    for spotId, _ in pairs(dynamicTransformBlips) do
        DeleteTransformSpotBlip(spotId)
    end
    for spotId, spot in pairs(dynamicTransformSpots) do
        CreateTransformSpotBlip(spotId, spot)
    end
end

RegisterNetEvent("vfw:setFaction")
AddEventHandler("vfw:setFaction", function()
    Citizen.Wait(100)
    RefreshTransformSpotBlips()
end)

