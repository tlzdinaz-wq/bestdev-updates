local function ShowJobNotification(content, isError)
    local societyImage = TriggerServerCallback("core:get:societyImage")
    local jobLabel = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.label or "Information"
    local notifType = isError and 'ROUGE' or 'JOB'
    local notif = {
        type = notifType,
        subtitle = "Information",
        content = content
    }

    if notifType == 'JOB' then
        notif.image = societyImage
        notif.title = jobLabel
    end

    VFW.ShowNotification(notif)
end

local sellingPed = nil
local sellingBlip = nil

local plantModelHashes = {}
for _, modelStr in pairs(CbdShopConfig.entityPlant) do
    plantModelHashes[tonumber(modelStr)] = true
end

-- Main Reset Event
RegisterNetEvent("farm:cbdshop:sellingPed", function(pos)
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
local cbdCraftOpen = false

local function GetPlayerItemCount(itemName)
    local count = 0
    for _, item in pairs(VFW.PlayerData.inventory) do
        if item.name == itemName then
            count = count + item.count
        end
    end
    return count
end

local function BuildCbdCraftData()
    local recipes = {}
    for _, recipe in ipairs(CbdShopConfig.crafting.recipes) do
        local ingredients = {}
        local maxCraftable = 999999

        for _, ing in ipairs(recipe.ingredients) do
            local playerHas = GetPlayerItemCount(ing.name)
            local canMake = math.floor(playerHas / ing.quantity)
            if canMake < maxCraftable then maxCraftable = canMake end

            ingredients[#ingredients + 1] = {
                name = ing.name,
                label = VFW.Items[ing.name] and VFW.Items[ing.name].label or ing.name,
                amount = ing.quantity,
                hasEnough = playerHas >= ing.quantity,
                playerHas = playerHas,
            }
        end

        recipes[#recipes + 1] = {
            id = recipe.output,
            label = recipe.label,
            craftTime = recipe.craftTime,
            ingredients = ingredients,
            maxCraftable = maxCraftable,
        }
    end
    return recipes
end

local function OpenCbdCraft()
    cbdCraftOpen = true
    local data = BuildCbdCraftData()

    SendNUIMessage({ action = "cbdshop:craft:visible", data = true })
    SendNUIMessage({ action = "cbdshop:craft:data", data = { recipes = data } })
    VFW.Nui.Focus(true, false)
end

local function CloseCbdCraft()
    cbdCraftOpen = false
    SendNUIMessage({ action = "cbdshop:craft:visible", data = false })
    VFW.Nui.Focus(false, false)
end

local function RefreshCbdCraft()
    if not cbdCraftOpen then return end
    local data = BuildCbdCraftData()
    SendNUIMessage({ action = "cbdshop:craft:data", data = { recipes = data } })
end

RegisterNUICallback("cbdshop:craft:close", function(_, cb)
    CloseCbdCraft()
    cb("ok")
end)

local pendingCraft = nil

RegisterNUICallback("cbdshop:craft:craft", function(data, cb)
    local recipeId = data.recipeId
    local qty = tonumber(data.quantity) or 1

    local recipe = nil
    for _, r in ipairs(CbdShopConfig.crafting.recipes) do
        if r.output == recipeId then
            recipe = r
            break
        end
    end

    if not recipe then
        cb("fail")
        return
    end

    pendingCraft = { recipe = recipe, recipeId = recipeId, quantity = qty }
    cb("ok")
    CloseCbdCraft()
end)

Citizen.CreateThread(function()
    while true do
        if pendingCraft then
            local craft = pendingCraft
            pendingCraft = nil
            inHarvest = true

            local ped = PlayerPedId()

            local animDict = "anim@gangops@facility@servers@"
            local animName = "hotwire"
            RequestAnimDict(animDict)
            local timeout = 0
            while not HasAnimDictLoaded(animDict) do
                Wait(50)
                timeout = timeout + 50
                if timeout > 5000 then break end
            end

            if HasAnimDictLoaded(animDict) then
                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
            end

            local success = VFW.Nui.ProgressBar("Fabrication de " .. craft.recipe.label .. "...", craft.recipe.craftTime * craft.quantity)

            ClearPedTasks(ped)
            if HasAnimDictLoaded(animDict) then
                RemoveAnimDict(animDict)
            end

            if success then
                local serverResult = TriggerServerCallback("farm:cbdshop:craft", craft.recipeId, craft.quantity)
                if not serverResult then
                    ShowJobNotification("Impossible de fabriquer.", true)
                end
            else
                ShowJobNotification("Fabrication annulée.", true)
            end

            inHarvest = false
            OpenCbdCraft()
        end
        Wait(200)
    end
end)

-- Main Thread
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local hasCbdJob = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name == "cbdshop"

        -- Plant Harvesting Logic
        if hasCbdJob and not inHarvest then
            local closestPlant, closestDist, closestCoords = nil, 1.5, nil
            -- Using GetGamePool is the modern and safer way to iterate entities
            local objects = GetGamePool('CObject')

            for _, obj in ipairs(objects) do
                if DoesEntityExist(obj) and plantModelHashes[GetEntityModel(obj)] then
                    local oCoords = GetEntityCoords(obj)
                    local dist = #(pCoords - oCoords)

                    if dist < closestDist then
                        closestDist = dist
                        closestPlant = obj
                        closestCoords = oCoords
                    end
                end
            end

            if closestPlant then
                wait = 0 -- Make loop faster for responsiveness
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récolter feuille de CBD")
                DrawMarker(25, closestCoords.x, closestCoords.y, closestCoords.z, 0, 0, 0, 0, 180.0, 0, 1.0, 1.0, 1.0, 0, 0, 255, 255, false, true, 2, nil, nil, false)
                if VFW.Interact.JustReleased(0, 38) then
                    inHarvest = true

                    -- New Animation Sequence
                    local harvestAnimDict = "anim@amb@nightclub@mini@drinking@drinking_shots@ped_b@normal"
                    local harvestAnimName = "pickup"

                    RequestAnimDict(harvestAnimDict)
                    while not HasAnimDictLoaded(harvestAnimDict) do
                        Wait(50)
                    end

                    TaskPlayAnim(ped, harvestAnimDict, harvestAnimName, 8.0, -8.0, 5000, 0, 0, false, false, false) -- 5000ms duration
                    local success = VFW.Nui.ProgressBar("Récolte en cours...", 3000)


                    if success then
                        ClearPedTasksImmediately(ped)
                        RemoveAnimDict(harvestAnimDict) -- Clean up anim dict
                        TriggerServerEvent("farm:cbdshop:give", nil, "harvest", closestCoords)
                    end

                    inHarvest = false
                end
            end
        end

        -- Processing Logic
        if hasCbdJob and not inHarvest then
            for itemName, coords in pairs(CbdShopConfig.processing) do
                local procCoords = vec3(coords.x, coords.y, coords.z)
                local dist = #(vec3(pCoords.x, pCoords.y, pCoords.z) - vec3(procCoords.x, procCoords.y, procCoords.z))

                if dist < 2 then
                    wait = 0

                    DrawMarker(25, procCoords.x, procCoords.y, procCoords.z, 0, 0, 0, 0, 180.0, 0, 0.7, 0.7, 0.7, 0, 0, 255, 255, false, true, 2, nil, nil, false)

                    if dist < 1.5 then
                        VFW.ShowHelpNotification(("Appuyez sur ~INPUT_CONTEXT~ pour lancer la fabrication de %s"):format(VFW.Items[itemName] and VFW.Items[itemName].label or itemName))
                        if VFW.Interact.JustReleased(0, 38) then
                            local canProcess = TriggerServerCallback("farm:cbdshop:canProcess", "processing")
                            if canProcess then
                                inHarvest = true

                                TaskTurnPedToFaceCoord(ped, procCoords.x, procCoords.y, procCoords.z, 1000)

                                local animDict = "anim@gangops@facility@servers@"
                                local animName = "hotwire"
                                RequestAnimDict(animDict)
                                while not HasAnimDictLoaded(animDict) do
                                    Wait(50)
                                end

                                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

                                local success = VFW.Nui.ProgressBar("Transformation en cours...", 10000)

                                ClearPedTasks(ped)
                                RemoveAnimDict(animDict)

                                if success then
                                    TriggerServerEvent("farm:cbdshop:give", itemName, "process")
                                end
                                SetTimeout(1000, function()
                                    inHarvest = false
                                end)

                            else
                                ShowJobNotification("Vous n'avez pas de feuille de CBD.", false)
                            end
                        end

                    end
                end
            end
            -- Crafting Table Logic
            local craftCoords = CbdShopConfig.crafting.coords
            local craftDist = #(pCoords - vec3(craftCoords.x, craftCoords.y, craftCoords.z))

            if craftDist < 2.0 then
                wait = 0
                DrawMarker(25, craftCoords.x, craftCoords.y, craftCoords.z, 0, 0, 0, 0, 180.0, 0, 0.7, 0.7, 0.7, 0, 0, 255, 255, false, true, 2, nil, nil, false)
                if craftDist < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la table de fabrication")
                    if VFW.Interact.JustReleased(0, 38) then
                        OpenCbdCraft()
                    end
                end
            end

            if sellingPed and #(GetEntityCoords(sellingPed) - pCoords) < 2.5 then
                wait = 0
                if #(GetEntityCoords(sellingPed) - pCoords) < 1.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre vos produits")
                    if VFW.Interact.JustReleased(0, 38) and not inSelling then
                        local canSell = TriggerServerCallback("farm:cbdshop:canProcess", "selling")
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
                                    TriggerServerEvent("farm:cbdshop:selling")
                                else
                                    ShowJobNotification("Vente annulée.", false)
                                end

                                inSelling = false
                            end)
                        else
                            ShowJobNotification("Vous n'avez rien à vendre.", false)
                        end
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)


local isUsingBang = false

-- Configuration centralisée
local Config = {
    Animation = {
        dict = "mp_player_intdrink",
        name = "loop_bottle",
        flag = 49 -- Enable upper body only + repeat
    },
    Prop = {
        model = "prop_sh_bong_01",
        bone = 60309, -- SKEL_L_Hand (main gauche)
        offset = vector3(0.0, 0.0, -0.15),
        rotation = vector3(0.0, 0.0, 50.0)
    },
    Duration = 45000,
    Effect = {
        name = "DrugsDrivingIn",
        duration = 30000
    },
    LoadTimeout = 5000
}

-- Fonction pour charger les assets
local function LoadAssets(dict, model)
    RequestAnimDict(dict)
    RequestModel(model)

    local timeout = Config.LoadTimeout
    local startTime = GetGameTimer()

    while not (HasAnimDictLoaded(dict) and HasModelLoaded(model)) do
        if GetGameTimer() - startTime > timeout then
            return false
        end
        Wait(100)
    end

    return true
end

-- Fonction pour nettoyer les assets
local function UnloadAssets(dict, model)
    if HasAnimDictLoaded(dict) then
        RemoveAnimDict(dict)
    end
    if HasModelLoaded(model) then
        SetModelAsNoLongerNeeded(model)
    end
end

-- Fonction pour créer l'effet de fumée du bang
local function CreateBangSmoke(playerPed)
    local ptfxAsset = "scr_bikersGunrunin"

    -- Charger l'asset de particules
    RequestNamedPtfxAsset(ptfxAsset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(ptfxAsset) do
        if GetGameTimer() > timeout then
            -- Essayer un autre asset si celui-ci échoue
            ptfxAsset = "core"
            RequestNamedPtfxAsset(ptfxAsset)
            while not HasNamedPtfxAssetLoaded(ptfxAsset) do
                Wait(100)
            end
            break
        end
        Wait(100)
    end

    -- Créer la fumée à la bouche (grosse fumée pour le bang)
    local boneIndex = GetPedBoneIndex(playerPed, 31086) -- SKEL_Head
    UseParticleFxAssetNextCall(ptfxAsset)

    local particle
    if ptfxAsset == "scr_bikersGunrunin" then
        particle = StartParticleFxLoopedOnEntityBone("scr_bia_fentanyl_smoke", playerPed, 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, boneIndex, 5.0, false, false, false)
    else
        particle = StartParticleFxLoopedOnEntityBone("exp_grd_bzgas_smoke", playerPed, 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, boneIndex, 1.5, false, false, false)
    end

    return particle, ptfxAsset
end

-- Fonction pour créer et attacher le prop
local function CreateBongProp(ped, propHash)
    local coords = GetEntityCoords(ped)
    local bong = CreateObject(propHash, coords.x, coords.y, coords.z, false, true, false)

    if not DoesEntityExist(bong) then
        return nil
    end

    local bone = GetPedBoneIndex(ped, Config.Prop.bone)
    AttachEntityToEntity(
            bong, ped, bone,
            Config.Prop.offset.x, Config.Prop.offset.y, Config.Prop.offset.z,
            Config.Prop.rotation.x, Config.Prop.rotation.y, Config.Prop.rotation.z,
            true, true, false, true, 1, true
    )

    return bong
end

local partialDoseCount = 0
local walkingStyle = "MOVE_M@DRUNK@VERYDRUNK"

-- Fonction corrigée pour gérer l'effet
local function ApplyDrugEffect(playerPed, duration)
    -- CORRECTION ICI :
    -- On met 0 pour la durée native car on s'en fiche
    -- On met TRUE pour "looped" (l'effet tourne en boucle tant qu'on ne l'arrête pas)
    StartScreenEffect(Config.Effect.name, 0, true)

    -- Application de la démarche
    RequestAnimSet(walkingStyle)
    while not HasAnimSetLoaded(walkingStyle) do
        Wait(10)
    end
    SetPedMovementClipset(playerPed, walkingStyle, 1.0)

    -- Thread indépendant pour gérer le timer
    CreateThread(function()
        -- Important : Assure-toi que duration est en millisecondes dans ton Config
        -- Ex: 60000 pour 1 minute. Si tu as mis 60, ça durera 0.06 secondes.
        Wait(duration)

        -- Une fois le temps écoulé, on coupe tout manuellement
        StopScreenEffect(Config.Effect.name) -- On force l'arrêt de l'effet
        ResetPedMovementClipset(playerPed, 1.0) -- On remet la marche normale
        RemoveAnimSet(walkingStyle) -- On nettoie la mémoire

        ShowJobNotification("Les effets se dissipent...", true)
    end)
end

RegisterNetEvent("cbdshop:useBang", function(item)
    VFW.CloseInventory()
    Wait(500)

    if isUsingBang then
        ShowJobNotification("Vous utilisez déjà un bang.", true)
        return
    end

    local playerPed = PlayerPedId()

    -- Vérifications de base
    if IsPedInAnyVehicle(playerPed, false) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans un véhicule.", true)
        return
    end
    if IsPedSwimming(playerPed) or IsPedSwimmingUnderWater(playerPed) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans l'eau.", true)
        return
    end

    isUsingBang = true
    local propHash = GetHashKey(Config.Prop.model)

    -- Chargement Assets
    if not LoadAssets(Config.Animation.dict, propHash) then
        ShowJobNotification("Erreur chargement.", true)
        isUsingBang = false
        return
    end

    -- Création Prop
    local bong = CreateBongProp(playerPed, propHash)
    if not bong then
        ShowJobNotification("Erreur création bang.", true)
        isUsingBang = false
        return
    end

    -- Gestion Temps & Cancel (déclaré avant le thread)
    local durationAnim = 10
    local timePassed = 0
    local isCancelled = false
    local smokeParticle = nil
    local smokeAsset = nil

    CreateThread(function()
        while isUsingBang and not isCancelled do
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour arrêter de fumer le bang.")
            if VFW.Interact.JustPressed(1, 38) then -- Touche E
                isCancelled = true
                break
            end
            Wait(10)
        end
    end)

    -- Animation
    TaskPlayAnim(playerPed, Config.Animation.dict, Config.Animation.name, 8.0, -8.0, -1, Config.Animation.flag, 0, false, false, false)

    -- Lancer la fumée immédiatement
    smokeParticle, smokeAsset = CreateBangSmoke(playerPed)



    while timePassed < durationAnim do
        Wait(1000)
        timePassed = timePassed + 1


        if isCancelled then -- Touche E
            break
        end

        if not IsEntityPlayingAnim(playerPed, Config.Animation.dict, Config.Animation.name, 3) then
            isCancelled = true
            break
        end
    end

    -- Nettoyage
    if smokeParticle then
        StopParticleFxLooped(smokeParticle, false)
    end
    if smokeAsset then
        RemoveNamedPtfxAsset(smokeAsset)
    end
    if DoesEntityExist(bong) then DeleteEntity(bong) end
    ClearPedTasks(playerPed)
    UnloadAssets(Config.Animation.dict, propHash)

    -- Résultat
    if not isCancelled and timePassed >= durationAnim then
        -- Succès total
        ShowJobNotification("Grosse latte ! Vous êtes défoncé.", true)
        ApplyDrugEffect(playerPed, Config.Effect.duration)
        partialDoseCount = 0

    else
        -- Annulation
        partialDoseCount = partialDoseCount + 1

        if partialDoseCount >= 2 then
            ShowJobNotification("Ça monte quand même...", true)
            ApplyDrugEffect(playerPed, Config.Effect.duration)
            partialDoseCount = 0
        else
            ShowJobNotification("Vous avez arrêté de tirer. (Petite dose)", true)
        end
    end

    TriggerServerEvent("cbd:useBang:done", isCancelled, item.id)

    isUsingBang = false
end)


-- Configuration bonbon CBD
local CandyConfig = {
    Animation = {
        dict = "mp_player_inteat@burger",
        name = "mp_player_int_eat_burger",
        flag = 49
    },
    Duration = 5000, -- Durée de l'animation
    Effect = {
        name = "DrugsMichaelAliensFightIn", -- Effet plus léger
        duration = 20000 -- 20 secondes d'effet
    }
}

local isUsingCandy = false

-- Fonction pour appliquer l'effet léger du bonbon
local function ApplyCandyEffect(playerPed, duration)
    -- Effet visuel léger
    StartScreenEffect(CandyConfig.Effect.name, 0, true)

    -- Légère modification de la caméra pour simuler un effet relaxant
    local camShakeIntensity = 0.3
    ShakeGameplayCam("DRUNK_SHAKE", camShakeIntensity)

    -- Démarche légèrement modifiée (moins prononcée que le bang)
    local candyWalkStyle = "MOVE_M@DRUNK@SLIGHTLYDRUNK"
    RequestAnimSet(candyWalkStyle)
    while not HasAnimSetLoaded(candyWalkStyle) do
        Wait(10)
    end
    SetPedMovementClipset(playerPed, candyWalkStyle, 0.5)

    -- Thread pour gérer la durée de l'effet
    CreateThread(function()
        Wait(duration)

        -- Arrêt progressif
        StopScreenEffect(CandyConfig.Effect.name)
        StopGameplayCamShaking(true)
        ResetPedMovementClipset(playerPed, 0.5) -- Retour à la démarche normale en douceur
        RemoveAnimSet(candyWalkStyle)

        ShowJobNotification("L'effet du bonbon se dissipe...", true)
    end)
end

RegisterNetEvent("cbdshop:useCandy", function(item)
    VFW.CloseInventory()
    Wait(500)

    if isUsingCandy then
        ShowJobNotification("Vous mangez déjà quelque chose.", true)
        return
    end

    local playerPed = PlayerPedId()

    -- Vérifications
    if IsPedInAnyVehicle(playerPed, false) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans un véhicule.", true)
        return
    end

    isUsingCandy = true

    -- Chargement de l'animation
    RequestAnimDict(CandyConfig.Animation.dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(CandyConfig.Animation.dict) do
        if GetGameTimer() > timeout then
            ShowJobNotification("Erreur de chargement.", true)
            isUsingCandy = false
            return
        end
        Wait(100)
    end

    -- Jouer l'animation
    TaskPlayAnim(playerPed, CandyConfig.Animation.dict, CandyConfig.Animation.name, 8.0, -8.0, CandyConfig.Duration, CandyConfig.Animation.flag, 0, false, false, false)

    -- Progress bar
    local success = VFW.Nui.ProgressBar("Vous mangez un bonbon au CBD...", CandyConfig.Duration)

    -- Nettoyage animation
    ClearPedTasks(playerPed)
    RemoveAnimDict(CandyConfig.Animation.dict)

    if success then
        ShowJobNotification("Mmmh... Vous vous sentez détendu.", true)
        ApplyCandyEffect(playerPed, CandyConfig.Effect.duration)

        -- Notifier le serveur que le bonbon a été consommé
        if item and item.id then
            TriggerServerEvent("cbd:useCandy:done", item.id)
        end
    else
        ShowJobNotification("Vous avez arrêté de manger.", true)
    end

    isUsingCandy = false
end)

-- Configuration cigarette électronique CBD
local VapeConfig = {
    Animation = {
        -- Animation de base (idle avec cigarette)
        baseDict = "amb@world_human_smoking@male@male_a@base",
        baseName = "base",
        -- Animation de taff (main qui monte à la bouche)
        enterDict = "amb@world_human_smoking@male@male_a@enter",
        enterName = "enter",
        -- Animation idle entre les taffs
        idleDict = "amb@world_human_smoking@male@male_a@idle_a",
        idleName = "idle_a",
        -- Animation de sortie
        exitDict = "amb@world_human_smoking@male@male_a@exit",
        exitName = "exit",
        flag = 51 -- 1 (loop) + 2 (stop last frame) + 16 (upper body) + 32 (enable player control) = permet de marcher
    },
    Prop = {
        model = "ba_prop_battle_vape_01", -- Vape pen
        bone = 64097, -- PH_R_Hand (position standard pour cigarette/vape dans les anims smoking)
        offset = vector3(0.015, 0.015, 0.0),
        rotation = vector3(0.0, 0.0, 20.0)
    },
    Duration = 12000, -- Durée totale
    TaffDuration = 3000, -- Durée d'un taff
    TaffCount = 3, -- Nombre de taffs par session
    Effect = {
        name = "DrugsMichaelAliensFightIn",
        duration = 25000 -- 25 secondes d'effet
    }
}

local isUsingVape = false
local vapeTaffCount = 0

-- Fonction pour créer la vapeur/fumée de la vape (effet de nuage qui sort de la bouche)
local function CreateVapeSmoke(playerPed, duration)
    local ptfxAsset = "scr_bikersGunrunin"
    local boneIndex = GetPedBoneIndex(playerPed, 31086) -- SKEL_Head (bouche)

    -- Charger l'asset de particules
    RequestNamedPtfxAsset(ptfxAsset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(ptfxAsset) do
        if GetGameTimer() > timeout then
            -- Fallback sur core
            ptfxAsset = "core"
            RequestNamedPtfxAsset(ptfxAsset)
            while not HasNamedPtfxAssetLoaded(ptfxAsset) do
                Wait(100)
            end
            break
        end
        Wait(100)
    end

    -- Créer la vapeur à la bouche (nuage de vapeur style vape)
    UseParticleFxAssetNextCall(ptfxAsset)

    local particle
    if ptfxAsset == "scr_bikersGunrunin" then
        -- Fumée plus dense et blanche pour la vape
        particle = StartParticleFxLoopedOnEntityBone("scr_bia_fentanyl_smoke", playerPed, 0.0, 0.08, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.4, false, false, false)
    else
        particle = StartParticleFxLoopedOnEntityBone("exp_grd_bzgas_smoke", playerPed, 0.0, 0.08, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.08, false, false, false)
    end

    -- Auto-stop après duration
    if duration and duration > 0 then
        SetTimeout(duration, function()
            if particle then
                StopParticleFxLooped(particle, false)
            end
        end)
    end

    return particle, ptfxAsset
end

-- Fonction pour charger tous les dicts d'animation de la vape
local function LoadVapeAnimDicts()
    local dicts = {
        VapeConfig.Animation.baseDict,
        VapeConfig.Animation.enterDict,
        VapeConfig.Animation.idleDict,
        VapeConfig.Animation.exitDict
    }

    for _, dict in ipairs(dicts) do
        RequestAnimDict(dict)
    end

    local timeout = GetGameTimer() + 5000
    for _, dict in ipairs(dicts) do
        while not HasAnimDictLoaded(dict) do
            if GetGameTimer() > timeout then
                return false
            end
            Wait(50)
        end
    end

    return true
end

-- Fonction pour nettoyer les dicts d'animation de la vape
local function UnloadVapeAnimDicts()
    RemoveAnimDict(VapeConfig.Animation.baseDict)
    RemoveAnimDict(VapeConfig.Animation.enterDict)
    RemoveAnimDict(VapeConfig.Animation.idleDict)
    RemoveAnimDict(VapeConfig.Animation.exitDict)
end

-- Fonction pour appliquer l'effet de la vape
local function ApplyVapeEffect(playerPed, duration)
    -- Effet visuel léger
    StartScreenEffect(VapeConfig.Effect.name, 0, true)

    -- Légère modification de la caméra
    local camShakeIntensity = 0.25
    ShakeGameplayCam("DRUNK_SHAKE", camShakeIntensity)

    -- Démarche légèrement modifiée
    local vapeWalkStyle = "MOVE_M@DRUNK@SLIGHTLYDRUNK"
    RequestAnimSet(vapeWalkStyle)
    while not HasAnimSetLoaded(vapeWalkStyle) do
        Wait(10)
    end
    SetPedMovementClipset(playerPed, vapeWalkStyle, 0.5)

    -- Thread pour gérer la durée de l'effet
    CreateThread(function()
        Wait(duration)

        -- Arrêt progressif
        StopScreenEffect(VapeConfig.Effect.name)
        StopGameplayCamShaking(true)
        ResetPedMovementClipset(playerPed, 0.5)
        RemoveAnimSet(vapeWalkStyle)

        ShowJobNotification("L'effet de la vape se dissipe...", true)
    end)
end

-- Configuration Joint CBD
local JointConfig = {
    Animation = {
        baseDict = "amb@world_human_smoking@male@male_a@base",
        baseName = "base",
        enterDict = "amb@world_human_smoking@male@male_a@enter",
        enterName = "enter",
        idleDict = "amb@world_human_smoking@male@male_a@idle_a",
        idleName = "idle_a",
        exitDict = "amb@world_human_smoking@male@male_a@exit",
        exitName = "exit",
        flag = 51
    },
    Prop = {
        model = "prop_sh_joint_01",
        bone = 0xFA70, -- PH_R_Hand (main droite, même que vape)
        offset =  vec3(0.014, 0.004, 0.013),
        rotation = vec3(-2.027, 1.848, 2.140)
    },
    Effect = {
        name = "DrugsDrivingIn",
        duration = 60000
    },
    TaffDuration = 3000, -- Durée d'un taff
    TaffCount = 3,       -- Nombre de taffs par session
}

local isUsingJoint = false
local jointTaffCount = 0

-- Fonction pour créer la fumée qui sort de la bouche
local function CreateJointSmoke(playerPed, duration)
    local ptfxAsset = "scr_bikersGunrunin"
    local boneIndex = GetPedBoneIndex(playerPed, 31086)

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
    local particle = StartParticleFxLoopedOnEntityBone("scr_bia_fentanyl_smoke", playerPed, 0.0, 0.08, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.5, false, false, false)

    if duration and duration > 0 then
        SetTimeout(duration, function()
            if particle then
                StopParticleFxLooped(particle, false)
            end
        end)
    end

    return particle, ptfxAsset
end

-- Fonction pour créer la fumée du bout du joint (qui brûle)
local function CreateJointBurningSmoke(jointEntity)
    local ptfxAsset = "core"

    RequestNamedPtfxAsset(ptfxAsset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(ptfxAsset) do
        if GetGameTimer() > timeout then
            return nil, nil
        end
        Wait(100)
    end

    UseParticleFxAssetNextCall(ptfxAsset)
    local particle = StartParticleFxLoopedOnEntity("exp_grd_bzgas_smoke", jointEntity, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.08, false, false, false)

    return particle, ptfxAsset
end

-- Fonction pour charger les animations du joint
local function LoadJointAnimDicts()
    local dicts = {
        JointConfig.Animation.baseDict,
        JointConfig.Animation.enterDict,
        JointConfig.Animation.idleDict,
        JointConfig.Animation.exitDict
    }

    for _, dict in ipairs(dicts) do
        RequestAnimDict(dict)
    end

    local timeout = GetGameTimer() + 5000
    for _, dict in ipairs(dicts) do
        while not HasAnimDictLoaded(dict) do
            if GetGameTimer() > timeout then
                return false
            end
            Wait(50)
        end
    end

    return true
end

-- Fonction pour nettoyer les animations du joint
local function UnloadJointAnimDicts()
    RemoveAnimDict(JointConfig.Animation.baseDict)
    RemoveAnimDict(JointConfig.Animation.enterDict)
    RemoveAnimDict(JointConfig.Animation.idleDict)
    RemoveAnimDict(JointConfig.Animation.exitDict)
end

-- Fonction pour appliquer l'effet du joint
local function ApplyJointEffect(playerPed)
    StartScreenEffect(JointConfig.Effect.name, 0, true)
    ShakeGameplayCam("DRUNK_SHAKE", 0.5)

    local jointWalkStyle = "MOVE_M@DRUNK@VERYDRUNK"
    RequestAnimSet(jointWalkStyle)
    while not HasAnimSetLoaded(jointWalkStyle) do
        Wait(10)
    end
    SetPedMovementClipset(playerPed, jointWalkStyle, 1.0)

    CreateThread(function()
        Wait(JointConfig.Effect.duration)

        StopScreenEffect(JointConfig.Effect.name)
        StopGameplayCamShaking(true)
        ResetPedMovementClipset(playerPed, 1.0)
        RemoveAnimSet(jointWalkStyle)

        ShowJobNotification("Les effets du joint se dissipent...", true)
    end)
end

RegisterNetEvent("cbdshop:useJoint", function(item)
    VFW.CloseInventory()
    Wait(500)

    if isUsingJoint then
        ShowJobNotification("Vous fumez déjà.", true)
        return
    end

    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans un véhicule.", true)
        return
    end
    if IsPedSwimming(playerPed) or IsPedSwimmingUnderWater(playerPed) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans l'eau.", true)
        return
    end

    isUsingJoint = true

    local propHash = GetHashKey(JointConfig.Prop.model)

    RequestModel(propHash)
    if not LoadJointAnimDicts() then
        ShowJobNotification("Erreur de chargement des animations.", true)
        isUsingJoint = false
        return
    end

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(propHash) do
        if GetGameTimer() > timeout then
            ShowJobNotification("Erreur de chargement du modèle.", true)
            isUsingJoint = false
            UnloadJointAnimDicts()
            return
        end
        Wait(100)
    end

    -- Création du joint
    local coords = GetEntityCoords(playerPed)
    local joint = CreateObject(propHash, coords.x, coords.y, coords.z, false, true, false)

    local burningParticle = nil
    local burningAsset = nil

    if DoesEntityExist(joint) then
        local boneIndex = GetPedBoneIndex(playerPed, JointConfig.Prop.bone)
        AttachEntityToEntity(
            joint, playerPed, boneIndex,
            JointConfig.Prop.offset.x, JointConfig.Prop.offset.y, JointConfig.Prop.offset.z,
            JointConfig.Prop.rotation.x, JointConfig.Prop.rotation.y, JointConfig.Prop.rotation.z,
            true, true, false, true, 1, true
        )

        -- Fumée du bout du joint qui brûle
        burningParticle, burningAsset = CreateJointBurningSmoke(joint)
    end

    local isCancelled = false
    local taffsDone = 0
    local smokeParticle = nil
    local smokeAsset = nil

    -- Thread pour détecter l'annulation
    CreateThread(function()
        while isUsingJoint and not isCancelled do
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour arrêter de fumer")
            if VFW.Interact.JustPressed(1, 38) then
                isCancelled = true
                break
            end
            Wait(10)
        end
    end)

    -- Animation d'entrée (sort le joint)
    TaskPlayAnim(playerPed, JointConfig.Animation.enterDict, JointConfig.Animation.enterName, 8.0, -8.0, -1, JointConfig.Animation.flag, 0, false, false, false)
    Wait(1500)

    if isCancelled then
        goto cleanup
    end

    -- Boucle de taffs
    for i = 1, JointConfig.TaffCount do
        if isCancelled then break end

        -- Animation idle (tient le joint)
        TaskPlayAnim(playerPed, JointConfig.Animation.idleDict, JointConfig.Animation.idleName, 8.0, -8.0, -1, JointConfig.Animation.flag, 0, false, false, false)
        Wait(800)

        if isCancelled then break end

        -- Animation base (porte à la bouche et fume)
        TaskPlayAnim(playerPed, JointConfig.Animation.baseDict, JointConfig.Animation.baseName, 8.0, -8.0, -1, JointConfig.Animation.flag, 0, false, false, false)
        Wait(1200)

        if isCancelled then break end

        -- Créer l'effet de fumée
        smokeParticle, smokeAsset = CreateJointSmoke(playerPed, 2000)

        Wait(JointConfig.TaffDuration - 1200)

        if isCancelled then break end

        taffsDone = taffsDone + 1

        if taffsDone < JointConfig.TaffCount then
            ShowJobNotification(("Taff %d/%d... Le joint se consume."):format(taffsDone, JointConfig.TaffCount), true)
        end

        if i < JointConfig.TaffCount and not isCancelled then
            TaskPlayAnim(playerPed, JointConfig.Animation.idleDict, JointConfig.Animation.idleName, 8.0, -8.0, -1, JointConfig.Animation.flag, 0, false, false, false)
            Wait(1500)
        end
    end

    ::cleanup::

    if not isCancelled then
        TaskPlayAnim(playerPed, JointConfig.Animation.exitDict, JointConfig.Animation.exitName, 8.0, -8.0, 2000, JointConfig.Animation.flag, 0, false, false, false)
        Wait(1500)
    end

    -- Nettoyage
    if smokeParticle then
        StopParticleFxLooped(smokeParticle, false)
    end
    if smokeAsset then
        RemoveNamedPtfxAsset(smokeAsset)
    end
    if burningParticle then
        StopParticleFxLooped(burningParticle, false)
    end
    if burningAsset then
        RemoveNamedPtfxAsset(burningAsset)
    end
    if DoesEntityExist(joint) then
        DeleteEntity(joint)
    end

    ClearPedTasks(playerPed)
    UnloadJointAnimDicts()
    SetModelAsNoLongerNeeded(propHash)

    if not isCancelled and taffsDone >= JointConfig.TaffCount then
        ShowJobNotification("Vous êtes complètement défoncé !", true)
        ApplyJointEffect(playerPed)

        if item and item.id then
            TriggerServerEvent("cbd:useJoint:done", item.id)
        end
    elseif taffsDone > 0 then
        jointTaffCount = jointTaffCount + taffsDone
        if jointTaffCount >= JointConfig.TaffCount then
            ShowJobNotification("L'effet cumulé commence à se faire sentir...", true)
            ApplyJointEffect(playerPed)
            jointTaffCount = 0
        else
            ShowJobNotification(("Vous avez arrêté après %d taff%s, %d sur %d accumulés."):format(taffsDone, taffsDone > 1 and "s" or "", jointTaffCount, JointConfig.TaffCount), true)
        end
    else
        ShowJobNotification("Vous rangez le joint sans avoir tiré.", true)
    end

    isUsingJoint = false
end)

RegisterNetEvent("cbdshop:useCigarette", function(item)
    VFW.CloseInventory()
    Wait(500)

    if isUsingVape then
        ShowJobNotification("Vous vapotez déjà.", true)
        return
    end

    local playerPed = PlayerPedId()

    -- Vérifications
    if IsPedInAnyVehicle(playerPed, false) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans un véhicule.", true)
        return
    end
    if IsPedSwimming(playerPed) or IsPedSwimmingUnderWater(playerPed) then
        ShowJobNotification("Vous ne pouvez pas faire ça dans l'eau.", true)
        return
    end

    isUsingVape = true

    local propHash = GetHashKey(VapeConfig.Prop.model)

    -- Chargement des assets (animations + prop)
    RequestModel(propHash)
    if not LoadVapeAnimDicts() then
        ShowJobNotification("Erreur de chargement des animations.", true)
        isUsingVape = false
        return
    end

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(propHash) do
        if GetGameTimer() > timeout then
            ShowJobNotification("Erreur de chargement du modèle.", true)
            isUsingVape = false
            UnloadVapeAnimDicts()
            return
        end
        Wait(100)
    end

    -- Création du prop (cigarette électronique)
    local coords = GetEntityCoords(playerPed)
    local vape = CreateObject(propHash, coords.x, coords.y, coords.z, false, true, false)

    if DoesEntityExist(vape) then
        local boneIndex = GetPedBoneIndex(playerPed, VapeConfig.Prop.bone)
        AttachEntityToEntity(
            vape, playerPed, boneIndex,
            VapeConfig.Prop.offset.x, VapeConfig.Prop.offset.y, VapeConfig.Prop.offset.z,
            VapeConfig.Prop.rotation.x, VapeConfig.Prop.rotation.y, VapeConfig.Prop.rotation.z,
            true, true, false, true, 1, true
        )
    end

    -- Variables de contrôle
    local isCancelled = false
    local taffsDone = 0
    local smokeParticle = nil
    local smokeAsset = nil

    -- Thread pour détecter l'annulation (touche E)
    CreateThread(function()
        while isUsingVape and not isCancelled do
            VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour arrêter de vapoter")
            if VFW.Interact.JustPressed(1, 38) then
                isCancelled = true
                break
            end
            Wait(10)
        end
    end)

    -- Animation d'entrée (sort la vape et la prépare)
    TaskPlayAnim(playerPed, VapeConfig.Animation.enterDict, VapeConfig.Animation.enterName, 8.0, -8.0, -1, VapeConfig.Animation.flag, 0, false, false, false)
    Wait(1500)

    if isCancelled then
        goto cleanup
    end

    -- Boucle de taffs
    for i = 1, VapeConfig.TaffCount do
        if isCancelled then break end

        -- Animation idle (tient la vape, regarde autour)
        TaskPlayAnim(playerPed, VapeConfig.Animation.idleDict, VapeConfig.Animation.idleName, 8.0, -8.0, -1, VapeConfig.Animation.flag, 0, false, false, false)
        Wait(800)

        if isCancelled then break end

        -- Animation base (porte la vape à la bouche pour tirer)
        TaskPlayAnim(playerPed, VapeConfig.Animation.baseDict, VapeConfig.Animation.baseName, 8.0, -8.0, -1, VapeConfig.Animation.flag, 0, false, false, false)

        -- Attendre que la main soit à la bouche puis créer la fumée
        Wait(1200)

        if isCancelled then break end

        -- Créer l'effet de vapeur (expire la fumée)
        smokeParticle, smokeAsset = CreateVapeSmoke(playerPed, 2000)

        -- Attendre pendant le taff
        Wait(VapeConfig.TaffDuration - 1200)

        if isCancelled then break end

        taffsDone = taffsDone + 1

        -- Notification de progression
        if taffsDone < VapeConfig.TaffCount then
            ShowJobNotification(("Taff %d/%d... Ça monte doucement."):format(taffsDone, VapeConfig.TaffCount), true)
        end

        -- Petite pause entre les taffs
        if i < VapeConfig.TaffCount and not isCancelled then
            TaskPlayAnim(playerPed, VapeConfig.Animation.idleDict, VapeConfig.Animation.idleName, 8.0, -8.0, -1, VapeConfig.Animation.flag, 0, false, false, false)
            Wait(1500)
        end
    end

    ::cleanup::

    -- Animation de sortie (range la vape)
    if not isCancelled then
        TaskPlayAnim(playerPed, VapeConfig.Animation.exitDict, VapeConfig.Animation.exitName, 8.0, -8.0, 2000, VapeConfig.Animation.flag, 0, false, false, false)
        Wait(1500)
    end

    -- Nettoyage des particules
    if smokeParticle then
        StopParticleFxLooped(smokeParticle, false)
    end
    if smokeAsset then
        RemoveNamedPtfxAsset(smokeAsset)
    end

    -- Suppression du prop
    if DoesEntityExist(vape) then
        DeleteEntity(vape)
    end

    -- Nettoyage des animations
    ClearPedTasks(playerPed)
    UnloadVapeAnimDicts()
    SetModelAsNoLongerNeeded(propHash)

    -- Résultat
    if not isCancelled and taffsDone >= VapeConfig.TaffCount then
        ShowJobNotification("Vous expirez un dernier nuage de vapeur... Vous vous sentez détendu.", true)
        ApplyVapeEffect(playerPed, VapeConfig.Effect.duration)

        if item and item.id then
            TriggerServerEvent("cbd:useCigarette:done", item.id)
        end
    elseif taffsDone > 0 then
        -- A fait quelques taffs mais pas tous
        vapeTaffCount = vapeTaffCount + taffsDone
        if vapeTaffCount >= VapeConfig.TaffCount then
            ShowJobNotification("L'effet cumulé commence à se faire sentir...", true)
            ApplyVapeEffect(playerPed, VapeConfig.Effect.duration * 0.7) -- Effet réduit
            vapeTaffCount = 0
        else
            ShowJobNotification(("Vous avez arrêté après %d taff%s, %d sur %d accumulés."):format(taffsDone, taffsDone > 1 and "s" or "", vapeTaffCount, VapeConfig.TaffCount), true)
        end
    else
        ShowJobNotification("Vous rangez la vape sans avoir tiré.", true)
    end

    isUsingVape = false
end)

-- Nettoyage automatique si le joueur se déconnecte pendant l'action
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and isUsingBang then
        local playerPed = PlayerPedId()
        ClearPedTasks(playerPed)
        isUsingBang = false
    end
end)