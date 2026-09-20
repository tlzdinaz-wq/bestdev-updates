local function ShowJobNotification(content, isError)
    local societyImage = TriggerServerCallback("core:get:societyImage")
    local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or "Information"
    local notifType = isError and 'ROUGE' or 'JOB'
    VFW.ShowNotification({
        type = notifType,
        image = societyImage,
        title = jobLabel,
        subtitle = "Information",
        content = content
    })
end

local sellingPed = nil
local sellingBlip = nil

RegisterNetEvent("farm:tabac:sellingPed", function(pos)
    if sellingPed then
        DeleteEntity(sellingPed)
        sellingPed = nil
    end
    if sellingBlip and DoesBlipExist(sellingBlip) then
        RemoveBlip(sellingBlip)
        sellingBlip = nil
    end

    if pos and pos.x ~= 0.0 then
        sellingPed = VFW.CreatePed(vector4(pos.x, pos.y, pos.z, pos.heading), "a_m_y_business_02")

        FreezeEntityPosition(sellingPed, false)
        Wait(5000)
        FreezeEntityPosition(sellingPed, true)

        local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or ""
        sellingBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
        SetBlipSprite(sellingBlip, 480)
        SetBlipDisplay(sellingBlip, 4)
        SetBlipScale(sellingBlip, 0.7)
        SetBlipColour(sellingBlip, 2)
        SetBlipAsShortRange(sellingBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(jobLabel .. " · Vente")
        EndTextCommandSetBlipName(sellingBlip)
    end
end)

local inHarvest = false
local inSelling = false
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        local hasGoodJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == "tabac"

        -- 1. LOGIQUE DE RÉCOLTE (Plantes)
        for i = 1, #TabacConfig.plants do
            local plantCoords = TabacConfig.plants[i]
            local dist = #(pCoords - plantCoords)

            if dist < 2.0 and hasGoodJob then
                wait = 0
                ---- Marker Vert pour la récolte (Type 1: Cylindre)
                --DrawMarker(25, plantCoords.x, plantCoords.y, plantCoords.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5,  0, 0, 255, 200, false, false, 2, nil, nil, false)

                if dist < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récolter")

                    if VFW.Interact.JustReleased(0, 38) and not inHarvest then
                        inHarvest = true
                        -- Touche E
                        TaskStartScenarioInPlace(ped, "world_human_gardener_plant", 0, true)

                        local success = VFW.Nui.ProgressBar("Récolte du tabac...", 5000)
                        ClearPedTasksImmediately(ped)

                        if success then
                            TriggerServerEvent("farm:tabac:give", i, "harvest")
                        end

                        inHarvest = false
                    end
                end
            end
        end

        -- 2. LOGIQUE DE SÉCHAGE (Traitement)
        for i = 1, #TabacConfig.processing do
            local procCoords = TabacConfig.processing[i]
            local dist = #(pCoords - procCoords)

            if dist < 2.0 and hasGoodJob then
                wait = 0
                -- Marker Orange pour le traitement (Séchage) (Type 1: Cylindre)
                DrawMarker(25, procCoords.x, procCoords.y, procCoords.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 0, 255, 200, false, false, 2, nil, nil, false)

                if dist < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour sécher le tabac")

                    if VFW.Interact.JustReleased(0, 38) then
                        -- Touche E
                        local canProcess = TriggerServerCallback("farm:tabac:canProcess", "process")

                        -- Animation plus sûre (Bricolage à hauteur de taille)
                        if canProcess then
                            local animDict = "mini@repair"
                            local animName = "fixing_a_player"

                            RequestAnimDict(animDict)
                            local timeout = 0
                            while not HasAnimDictLoaded(animDict) and timeout < 50 do
                                Wait(50)
                                timeout = timeout + 1
                            end

                            -- On joue l'animation même si le chargement a pris du temps, si dispo
                            if HasAnimDictLoaded(animDict) then
                                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                            end

                            local success = VFW.Nui.ProgressBar("Séchage du tabac...", 5000)

                            ClearPedTasks(ped)
                            RemoveAnimDict(animDict)

                            if success then
                                TriggerServerEvent("farm:tabac:give", i, "process")
                            end
                        else
                            ShowJobNotification("Vous n'avez pas assez de feuilles de tabac.", false)
                        end
                    end
                end
            end
        end

        for i = 1, #TabacConfig.packaging do
            local packCoords = TabacConfig.packaging[i]
            local dist = #(pCoords - packCoords)

            if dist < 2.0 and hasGoodJob then
                wait = 0
                -- Marker Bleu pour la conditionnement (Type 1: Cylindre)
                DrawMarker(25, packCoords.x, packCoords.y, packCoords.z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5,  0, 0, 255, 200, false, false, 2, nil, nil, false)

                if dist < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour emballer les cigarettes")

                    if VFW.Interact.JustReleased(0, 38) then
                        -- Touche E
                        local canPackaging = TriggerServerCallback("farm:tabac:canProcess", "packaging")

                        if canPackaging then

                            local animDict = "mini@repair"
                            local animName = "fixing_a_player"

                            RequestAnimDict(animDict)
                            local timeout = 0
                            while not HasAnimDictLoaded(animDict) and timeout < 50 do
                                Wait(50)
                                timeout = timeout + 1
                            end

                            -- On joue l'animation même si le chargement a pris du temps, si dispo
                            if HasAnimDictLoaded(animDict) then
                                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                            end
                            local success = VFW.Nui.ProgressBar("Emballage des cigarettes...", 5000)
                            ClearPedTasks(ped)
                            RemoveAnimDict(animDict)

                            if success then
                                TriggerServerEvent("farm:tabac:give", i, "selling")
                            end
                        end
                    end
                end
            end
        end

        if sellingPed and #(GetEntityCoords(sellingPed) - pCoords) < 2.5 then
            wait = 0
            if #(GetEntityCoords(sellingPed) - pCoords) < 1.5 then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre votre production")
                if VFW.Interact.JustReleased(0, 38) and not inSelling then
                    local canSell = TriggerServerCallback("farm:tabac:canProcess", "selling")
                    if canSell then
                        inSelling = true

                        Citizen.CreateThread(function()
                            local animDict = "mp_common"
                            RequestAnimDict(animDict)
                            while not HasAnimDictLoaded(animDict) do
                                Wait(50)
                            end

                            TaskTurnPedToFaceEntity(ped, sellingPed, 5000)
                            TaskPlayAnim(ped, animDict, "givetake1_a", 8.0, -8.0, 5000, 0, 0, false, false, false)

                            local success = VFW.Nui.ProgressBar("Vente...", 5000)

                            ClearPedTasks(ped)

                            if success then
                                TriggerServerEvent("farm:tabac:selling")
                            else
                                ShowJobNotification("Vente annulée.", false)
                            end

                            inSelling = false
                        end)
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)

-- Configuration cigarette (animation "Fumer 2" du menu emotes)
local CigConfig = {
    Animation = {
        dict = "amb@world_human_aa_smoke@male@idle_a",
        name = "idle_c",
        flag = 49 -- Upper body only, permet de marcher
    },
    Prop = {
        model = "ng_proc_cigarette01a",
        bone = 28422, -- PH_R_Hand (main droite)
        offset = vector3(0.0, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    },
    Duration = 60000 -- 60 secondes max
}

local isSmoking = false

-- Fonction pour créer la fumée de cigarette
local function CreateCigSmoke(playerPed)
    local ptfxAsset = "scr_bikersGunrunin"
    local boneIndex = GetPedBoneIndex(playerPed, 31086) -- SKEL_Head

    RequestNamedPtfxAsset(ptfxAsset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(ptfxAsset) do
        if GetGameTimer() > timeout then
            ptfxAsset = "core"
            RequestNamedPtfxAsset(ptfxAsset)
            while not HasNamedPtfxAssetLoaded(ptfxAsset) do
                Wait(100)
            end
            break
        end
        Wait(100)
    end

    UseParticleFxAssetNextCall(ptfxAsset)

    local particle
    if ptfxAsset == "scr_bikersGunrunin" then
        particle = StartParticleFxLoopedOnEntityBone("scr_bia_fentanyl_smoke", playerPed, 0.0, 0.1, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.3, false, false, false)
    else
        particle = StartParticleFxLoopedOnEntityBone("exp_grd_bzgas_smoke", playerPed, 0.0, 0.1, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.08, false, false, false)
    end

    return particle, ptfxAsset
end

RegisterNetEvent("core:UseCigarette", function()
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(playerPed) then
        ShowJobNotification(("Vous ne pouvez pas fumer %s"):format(IsPedInAnyVehicle(playerPed, false) and "dans un véhicule" or "en étant mort"), false)
        return
    end

    if isSmoking then
        ShowJobNotification("Vous fumez déjà.", false)
        return
    end

    isSmoking = true

    local propHash = GetHashKey(CigConfig.Prop.model)

    -- Chargement des assets
    RequestAnimDict(CigConfig.Animation.dict)
    RequestModel(propHash)

    local timeout = GetGameTimer() + 5000
    while not (HasAnimDictLoaded(CigConfig.Animation.dict) and HasModelLoaded(propHash)) do
        if GetGameTimer() > timeout then
            ShowJobNotification("Erreur de chargement.", false)
            isSmoking = false
            return
        end
        Wait(100)
    end

    -- Création du prop (cigarette)
    local coords = GetEntityCoords(playerPed)
    local cig = CreateObject(propHash, coords.x, coords.y, coords.z, false, true, false)

    if DoesEntityExist(cig) then
        local bone = GetPedBoneIndex(playerPed, CigConfig.Prop.bone)
        AttachEntityToEntity(
            cig, playerPed, bone,
            CigConfig.Prop.offset.x, CigConfig.Prop.offset.y, CigConfig.Prop.offset.z,
            CigConfig.Prop.rotation.x, CigConfig.Prop.rotation.y, CigConfig.Prop.rotation.z,
            true, true, false, true, 1, true
        )
    end

    -- Jouer l'animation (permet de marcher)
    TaskPlayAnim(playerPed, CigConfig.Animation.dict, CigConfig.Animation.name, 8.0, -8.0, -1, CigConfig.Animation.flag, 0, false, false, false)

    -- Lancer la fumée
    local smokeParticle, smokeAsset = CreateCigSmoke(playerPed)

    -- Boucle principale
    local duration = 0
    local isCancelled = false

    -- Thread pour la notification
    CreateThread(function()
        while isSmoking and not isCancelled do
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour arrêter de fumer")
            if VFW.Interact.JustPressed(0, 38) then -- Touche E
                isCancelled = true
                break
            end
            Wait(10)
        end
    end)

    while not isCancelled and duration < CigConfig.Duration do
        duration = duration + 100
        Wait(100)
    end

    -- Nettoyage
    if smokeParticle then
        StopParticleFxLooped(smokeParticle, false)
    end
    if smokeAsset then
        RemoveNamedPtfxAsset(smokeAsset)
    end

    if DoesEntityExist(cig) then
        DeleteEntity(cig)
    end

    ClearPedTasks(playerPed)
    RemoveAnimDict(CigConfig.Animation.dict)
    SetModelAsNoLongerNeeded(propHash)

    isSmoking = false
end)