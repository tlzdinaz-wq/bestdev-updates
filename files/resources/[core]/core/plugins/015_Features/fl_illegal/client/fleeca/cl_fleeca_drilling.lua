---@meta _
---@diagnostic disable: duplicate-doc-field

local Drilling = {
    dict = "anim@heists@fleeca_bank@drilling",
    drillProp = "hei_prop_heist_drill",  -- Prop de perceuse (comme Pacific)
    prEffect = "FM_Mission_Controler",
    ObjectDrill = nil,
    ObjectBag = nil,
    SynchroS = nil,
    ScalformMoov = nil,
    netScal = nil,
    getVaria = 0,
    helpScaleform = nil,
    drillSoundID = nil,
    isActive = false,
    callback = nil,
    -- Variables pour sauvegarder la position avant TP (comme Pacific)
    savedPosition = nil,
    savedHeading = nil
}

local function RequestAndWaitDict(dictName)
    if dictName and DoesAnimDictExist(dictName) and not HasAnimDictLoaded(dictName) then
        RequestAnimDict(dictName)
        local timeout = GetGameTimer() + 5000
        while not HasAnimDictLoaded(dictName) do
            if GetGameTimer() > timeout then return false end
            Citizen.Wait(100)
        end
    end
    return true
end

local function RequestAndWaitModel(modelName)
    local modelHash = GetHashKey(modelName)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        local timeout = GetGameTimer() + 5000
        while not HasModelLoaded(modelHash) do
            if GetGameTimer() > timeout then return nil end
            Citizen.Wait(100)
        end
    end
    return modelHash
end

local function SetScaleformParams(scaleform, data)
    data = data or {}
    for k,v in pairs(data) do
        PushScaleformMovieFunction(scaleform, v.name)
        if v.param then
            for _,par in pairs(v.param) do
                if math.type(par) == "integer" then
                    PushScaleformMovieFunctionParameterInt(par)
                elseif type(par) == "boolean" then
                    PushScaleformMovieFunctionParameterBool(par)
                elseif math.type(par) == "float" then
                    PushScaleformMovieFunctionParameterFloat(par)
                elseif type(par) == "string" then
                    PushScaleformMovieFunctionParameterString(par)
                end
            end
        end
        if v.func then v.func() end
        PopScaleformMovieFunctionVoid()
    end
end

local function CreateScaleform(name, data)
    if not name or string.len(name) <= 0 then return end
    local scaleform = RequestScaleformMovie(name)

    local timeout = GetGameTimer() + 5000
    while not HasScaleformMovieLoaded(scaleform) do
        if GetGameTimer() > timeout then
            return nil
        end
        Citizen.Wait(0)
    end

    SetScaleformParams(scaleform, data)
    return scaleform
end

local function StopSoundAndParticle(bool)
    -- Simplified version without drill-specific effects
end

local function CleanupDrilling()
    local pPed = PlayerPedId()

    -- Arreter le son synchronise pour tous les joueurs
    if StopSyncedDrillSound then
        StopSyncedDrillSound()
    end

    -- Supprimer le prop de perceuse (comme Pacific)
    if Drilling.ObjectDrill and DoesEntityExist(Drilling.ObjectDrill) then
        DetachEntity(Drilling.ObjectDrill, true, true)
        DeleteEntity(Drilling.ObjectDrill)
        Drilling.ObjectDrill = nil
    end

    local cleanupEntities = {
        Drilling.ObjectBag,
        Drilling.ScalformMoov,
        Drilling.helpScaleform,
    }

    for _, entity in pairs(cleanupEntities) do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    if Drilling.SynchroS then
        NetworkStopSynchronisedScene(Drilling.SynchroS)
        Drilling.SynchroS = nil
    end

    local animDicts = {
        Drilling.dict,
    }

    for _, animDict in pairs(animDicts) do
        RemoveAnimDict(animDict)
    end

    local audioBanks = {
        [[DLC_MPHEIST\HEIST_FLEECA_DRILL]],
        [[DLC_MPHEIST\HEIST_FLEECA_DRILL_2]],
    }

    for _, audioBank in pairs(audioBanks) do
        ReleaseScriptAudioBank(audioBank, false)
    end

    if Drilling.getVaria ~= 0 then
        SetPedComponentVariation(pPed, 5, Drilling.getVaria, 0, 2)
    end

    if Drilling.netScal then
        StopParticleFxLooped(Drilling.netScal, 0)
        Drilling.netScal = nil
        RemoveNamedPtfxAsset(Drilling.prEffect)
    end

    -- Libérer le modèle de la perceuse
    SetModelAsNoLongerNeeded(GetHashKey(Drilling.drillProp))

    ClearPedTasks(pPed)

    -- Réafficher le HUD custom (comme Pacific)
    VFW.Nui.HudVisible(true)

    -- Retour à la position sauvegardée avec fade (comme Pacific)
    if Drilling.savedPosition then
        DoScreenFadeOut(400)
        Citizen.Wait(450)

        SetEntityCoordsNoOffset(pPed, Drilling.savedPosition.x, Drilling.savedPosition.y, Drilling.savedPosition.z, false, false, false)
        if Drilling.savedHeading then
            SetEntityHeading(pPed, Drilling.savedHeading)
        end

        Citizen.Wait(100)
        DoScreenFadeIn(400)
    end

    FreezeEntityPosition(pPed, false)

    if Drilling.drillButtonId then
        instructionalButtons[Drilling.drillButtonId] = nil
        Drilling.drillButtonId = nil
    end

    Drilling.ObjectBag = nil
    Drilling.ScalformMoov = nil
    Drilling.helpScaleform = nil
    Drilling.getVaria = 0
    Drilling.isActive = false
    Drilling.savedPosition = nil
    Drilling.savedHeading = nil
end

local function StartDrillingMinigame(safePos, callback)
    if Drilling.isActive then return end

    Drilling.isActive = true
    Drilling.callback = callback

    Citizen.CreateThread(function()
        VFW.Nui.HudVisible(false)

        local pPed = PlayerPedId()
        local safePosVec = vec3(safePos.x, safePos.y, safePos.z)

        Drilling.savedPosition = GetEntityCoords(pPed)
        Drilling.savedHeading = GetEntityHeading(pPed)

        RequestScriptAudioBank([[DLC_MPHEIST\HEIST_FLEECA_DRILL]], false)
        RequestScriptAudioBank([[DLC_MPHEIST\HEIST_FLEECA_DRILL_2]], false)

        local dictLoaded = RequestAndWaitDict(Drilling.dict)
        local drillHash = RequestAndWaitModel(Drilling.drillProp)

        if not dictLoaded or not drillHash then
            Drilling.isActive = false
            VFW.Nui.HudVisible(true)
            if callback then callback(false) end
            return
        end

        FreezeEntityPosition(pPed, true)
        DoScreenFadeOut(400)
        Citizen.Wait(450)

        ClearPedTasksImmediately(pPed)
        SetEntityCoordsNoOffset(pPed, safePos.x, safePos.y, safePos.z, false, false, false)
        local heading = safePos.h or safePos.heading or 0.0
        SetEntityHeading(pPed, heading)

        Citizen.Wait(100)
        DoScreenFadeIn(400)
        FreezeEntityPosition(pPed, false)

        RequestNamedPtfxAsset(Drilling.prEffect)
        local ptfxTimeout = GetGameTimer() + 5000
        while not HasNamedPtfxAssetLoaded(Drilling.prEffect) do
            if GetGameTimer() > ptfxTimeout then break end
            Citizen.Wait(0)
        end

        local scaleform = CreateScaleform("drilling", {
            {name = "SET_SPEED", param = {0.1}},
            {name = "SET_HOLE_DEPTH", param = {0.6}},
            {name = "SET_DRILL_POSITION", param = {0.3}},
            {name = "SET_TEMPERATURE", param = {0.0}}
        })

        if not scaleform then
            Drilling.isActive = false
            VFW.Nui.HudVisible(true)
            CleanupDrilling()
            if callback then callback(false) end
            return
        end

        local playerCoords = GetEntityCoords(pPed)
        Drilling.ObjectDrill = VFW.OneSync.CreateObject(drillHash, playerCoords)

        AttachEntityToEntity(Drilling.ObjectDrill, pPed, GetPedBoneIndex(pPed, 0x6F06),
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            true, true, false, true, 0, true)

        TaskPlayAnim(pPed, Drilling.dict, "drill_straight_idle", 8.0, -8.0, -1, 1, 0, false, false, false)

        Drilling.ScalformMoov = scaleform

        local drillButtonId = generateUniqueID(8)
        Drilling.drillButtonId = drillButtonId
        instructionalButtons[drillButtonId] = {
            { control = 51, label = "Allumer/Eteindre" },
            { control = 24, label = "Pousser" },
            { control = 194, label = "Quitter" },
        }
        local Scal1 = 0.0
        local Scal2 = 0.0
        local Scal3 = 0.0
        local Scal4 = 0.0
        local RaterScal = false
        local SoundScal = false
        local SoundId = 1.0
        local drillSoundPlaying = false -- Track si le son synchronise est en cours

        while Drilling.isActive do
            Citizen.Wait(0)

            if not Drilling.ScalformMoov or not HasScaleformMovieLoaded(Drilling.ScalformMoov) then
                CleanupDrilling()
                if Drilling.callback then
                    Drilling.callback(false)
                    Drilling.callback = nil
                end
                return
            end

            if IsEntityDead(PlayerPedId()) or #(GetEntityCoords(PlayerPedId()) - safePosVec) > 30 then
                CleanupDrilling()
                if Drilling.callback then
                    Drilling.callback(false)
                    Drilling.callback = nil
                end
                return
            end

            if not IsEntityPlayingAnim(pPed, Drilling.dict, "drill_straight_idle", 3) then
                TaskPlayAnim(pPed, Drilling.dict, "drill_straight_idle", 8.0, -8.0, -1, 1, 0, false, false, false)
            end

            DrawScaleformMovieFullscreen(Drilling.ScalformMoov, 255, 255, 255, 255)

            HideHudAndRadarThisFrame()
            for i = 1, 22 do
                HideHudComponentThisFrame(i)
            end

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            if IsControlJustPressed(0, 194) then
                CleanupDrilling()
                if Drilling.callback then
                    Drilling.callback(false)
                    Drilling.callback = nil
                end
                return
            end

            local Press237, Press238 = IsControlPressed(0, 237), IsControlPressed(0, 238)
            local StartSca = false

            if Press237 and ((Scal4 >= 0.225 and Scal4 <= 0.325 and Scal1 <= 0.325) or (Scal4 >= 0.35 and Scal4 <= 0.45 and Scal1 <= 0.45) or (Scal4 >= 0.5 and Scal4 <= 0.6 and Scal1 <= 0.6) or (Scal4 >= 0.625 and Scal4 <= 0.725 and Scal1 <= 0.725)) then
                StartSca = true
                if SoundId ~= 0.5 then
                    SoundId = 0.5
                    if Drilling.drillSoundID then
                        SetVariableOnSound(Drilling.drillSoundID, "DrillState", 0.5)
                    end
                end
            end

            if not StartSca and SoundId == 0.5 then
                SoundId = 0.0
                if Drilling.drillSoundID then
                    SetVariableOnSound(Drilling.drillSoundID, "DrillState", 0.0)
                end
            end

            if VFW.Interact.JustPressed(0, 51) and not RaterScal then
                SoundScal = not SoundScal
                StopSoundAndParticle(SoundScal)

                if SoundScal and not drillSoundPlaying then
                    if StartSyncedDrillSound then
                        StartSyncedDrillSound(safePos)
                    end
                    drillSoundPlaying = true
                elseif not SoundScal and drillSoundPlaying then
                    if StopSyncedDrillSound then
                        StopSyncedDrillSound()
                    end
                    drillSoundPlaying = false
                end
            end

            if SoundScal and Scal2 < 0.5 then
                Scal2 = math.max(0, math.min(0.5, Scal2 + 0.005))
            elseif not SoundScal and Scal2 > 0.0 then
                Scal2 = math.max(0, math.min(0.5, Scal2 - 0.005))
            end

            if not RaterScal and Press237 and SoundScal then
                Scal4 = math.max(0, math.min(1.0, Scal4 + 0.001 * (StartSca and 0.5 or 1.0)))
                if Scal4 > Scal1 then
                    Scal1 = math.max(0, math.min(1.0, Scal1 + 0.001))
                end
                if Scal1 > 0.1 and Scal1 - Scal4 <= 0.01 then
                    Scal3 = math.max(0, math.min(1.0, Scal3 + (StartSca and 0.005 or 0.002)))
                end
            end

            if not RaterScal and Press238 and SoundScal then
                Scal4 = math.max(0, math.min(1.0, Scal4 - 0.0025))
            end

            if not Press238 and not Press237 and Scal3 > 0.0 then
                Scal3 = math.max(0, math.min(1.0, Scal3 - 0.0015))
            end

            if Scal3 > 0.7 and not RaterScal then
                RaterScal = true
                PlaySoundFrontend(-1, "Drill_Pin_Break", "DLC_HEIST_FLEECA_SOUNDSET", true)
                StopSoundAndParticle()

                if drillSoundPlaying then
                    if StopSyncedDrillSound then
                        StopSyncedDrillSound()
                    end
                    drillSoundPlaying = false
                end
                SoundScal = false
            elseif RaterScal then
                if Scal3 < 0.1 then
                    RaterScal = false
                end
                Scal2 = 0.0
                Scal4 = math.max(0, math.min(1.0, Scal4 - 0.0075))
            end

            if Scal1 >= 0.96 then
                SetScaleformMovieAsNoLongerNeeded(Drilling.ScalformMoov)
                Drilling.ScalformMoov = nil

                CleanupDrilling()

                if Drilling.callback then
                    Drilling.callback(true)
                    Drilling.callback = nil
                end
                return
            end

            CallScaleformMovieFunctionFloatParams(Drilling.ScalformMoov, "SET_SPEED", Scal2 * (StartSca and 0.5 or 1.0), -1082130432, -1082130432, -1082130432, -1082130432)
            CallScaleformMovieFunctionFloatParams(Drilling.ScalformMoov, "SET_HOLE_DEPTH", Scal1, -1082130432, -1082130432, -1082130432, -1082130432)
            CallScaleformMovieFunctionFloatParams(Drilling.ScalformMoov, "SET_DRILL_POSITION", Scal4, -1082130432, -1082130432, -1082130432, -1082130432)
            CallScaleformMovieFunctionFloatParams(Drilling.ScalformMoov, "SET_TEMPERATURE", Scal3, -1082130432, -1082130432, -1082130432, -1082130432)
        end
    end)
end

function StartFleecaDrilling(safePos, callback)
    StartDrillingMinigame(safePos, callback)
end

function IsDrilling()
    return Drilling.isActive
end
