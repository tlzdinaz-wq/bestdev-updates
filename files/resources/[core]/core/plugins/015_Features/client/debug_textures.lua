--[[
    /debugtextures - Full client texture & streaming refresh (no relog).

    Pipeline (un seul shot) :
      1. Re-applique components / props / decals du ped joueur
      2. Refresh livery / colors / plate / dirt / extras de tous les véhicules en scène
      3. Clear blood/wetness/dirt sur les peds proches
      4. Force world re-stream via NewLoadSceneStart sur ~500m
      5. Player switch invisible (out → purge zone → in) pour vider le pool YTD
         et forcer le streamer à recharger proprement
]]

local function refreshPedTextures(ped)
    if not DoesEntityExist(ped) then return end

    for comp = 0, 11 do
        local drawable = GetPedDrawableVariation(ped, comp)
        local texture  = GetPedTextureVariation(ped, comp)
        local palette  = GetPedPaletteVariation(ped, comp)
        if drawable >= 0 and texture >= 0 then
            SetPedComponentVariation(ped, comp, drawable, texture, palette)
        end
    end

    for prop = 0, 7 do
        local pDraw = GetPedPropIndex(ped, prop)
        local pTex  = GetPedPropTextureIndex(ped, prop)
        if pDraw ~= -1 then
            SetPedPropIndex(ped, prop, pDraw, pTex, true)
        end
    end

    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
end

local function refreshVehicleTextures(veh)
    if not DoesEntityExist(veh) then return end

    local livery = GetVehicleLivery(veh)
    if livery ~= -1 then SetVehicleLivery(veh, livery) end

    local livery2 = GetVehicleLivery2(veh)
    if livery2 and livery2 ~= -1 then SetVehicleLivery2(veh, livery2) end

    local plate = GetVehicleNumberPlateText(veh)
    local plateIdx = GetVehicleNumberPlateTextIndex(veh)
    if plate then SetVehicleNumberPlateText(veh, plate) end
    SetVehicleNumberPlateTextIndex(veh, plateIdx)

    local p, s = GetVehicleColours(veh)
    SetVehicleColours(veh, p, s)
    local pr, pg, pb = GetVehicleCustomPrimaryColour(veh)
    if pr then SetVehicleCustomPrimaryColour(veh, pr, pg, pb) end
    local sr, sg, sb = GetVehicleCustomSecondaryColour(veh)
    if sr then SetVehicleCustomSecondaryColour(veh, sr, sg, sb) end

    SetVehicleDirtLevel(veh, GetVehicleDirtLevel(veh))

    for extra = 0, 14 do
        if DoesExtraExist(veh, extra) then
            local enabled = IsVehicleExtraTurnedOn(veh, extra)
            SetVehicleExtra(veh, extra, not enabled)
            SetVehicleExtra(veh, extra, not enabled)
        end
    end

    SetVehicleWindowTint(veh, GetVehicleWindowTint(veh))
end

local function refreshAllVehiclesInScene()
    local handle, veh = FindFirstVehicle()
    local success
    if handle ~= -1 then
        repeat
            refreshVehicleTextures(veh)
            success, veh = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end
end

local function refreshNearbyPeds()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local handle, ped = FindFirstPed()
    local success
    if handle ~= -1 then
        repeat
            if not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - playerCoords) < 50.0 then
                ClearPedBloodDamage(ped)
                ClearPedWetness(ped)
                ClearPedEnvDirt(ped)
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end
end

local function forceWorldRestream(coords)
    ClearFocus()
    Wait(0)

    SetReducePedModelBudget(true)
    SetReduceVehicleModelBudget(true)
    Wait(50)
    SetReducePedModelBudget(false)
    SetReduceVehicleModelBudget(false)

    NewLoadSceneStart(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 500.0, 0)
    local timeout = GetGameTimer() + 3000
    while not IsNewLoadSceneLoaded() and GetGameTimer() < timeout do Wait(0) end
    NewLoadSceneStop()

    SetFocusEntity(PlayerPedId())
end

local function playerSwitchPurge(coords, heading, veh)
    SwitchOutPlayer(PlayerPedId(), 0, 1)
    local outTimeout = GetGameTimer() + 3000
    while GetPlayerSwitchState() ~= 5 and GetGameTimer() < outTimeout do Wait(0) end

    ClearAreaOfEverything(coords.x, coords.y, coords.z, 100.0, false, false, false, false)
    Wait(200)

    SwitchInPlayer(PlayerPedId())
    local inTimeout = GetGameTimer() + 5000
    while GetPlayerSwitchState() ~= 12 and GetGameTimer() < inTimeout do Wait(0) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, heading)
    if veh and DoesEntityExist(veh) then
        SetPedIntoVehicle(ped, veh, -1)
    end
end

local running = false

RegisterCommand("debugtextures", function()
    if running then return end
    running = true

    CreateThread(function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then veh = nil end

        DoScreenFadeOut(300)
        local fadeTimeout = GetGameTimer() + 1000
        while not IsScreenFadedOut() and GetGameTimer() < fadeTimeout do Wait(0) end

        refreshPedTextures(PlayerPedId())
        if veh then refreshVehicleTextures(veh) end
        refreshAllVehiclesInScene()
        refreshNearbyPeds()

        forceWorldRestream(coords)
        playerSwitchPurge(coords, heading, veh)

        DoScreenFadeIn(500)
        running = false
    end)
end, false)
