local prop = {}
local lastEmote = {}
local clonePed = nil
local clonePed2 = nil -- Second clone for shared emote preview
local animalPed = nil -- Animal ped for animal emote preview
local animalPreviewProps = {} -- Props for animal preview
local previewLocalProps = {} -- Safety-net : toutes les entités prop créées localement en preview (anti-leak)
local previewVehicle = nil -- Vehicle for vehicle animation preview
local currentPreviewId = 0 -- ID pour tracker la preview actuelle
local hideClonePreview = false -- Flag pour cacher le clone (véhicules, démarches)
local isSharedPreview = false -- Flag pour décaler la preview des emotes partagées vers la gauche
local sharedPreviewOptions = nil -- AnimationOptions à appliquer pour positionner clonePed2 relatif à clonePed
local clonePed2Attached = false -- Track si clonePed2 est attaché à clonePed (Attachto)
local isWalkPreview = false -- Flag pour les previews de marche (clone bouge librement)
local walkPreviewThread = nil -- Thread pour la marche en boucle
local zoom = false
local id = 0
local lastAnimation = nil
local currentAction = {}
local currentAnimationPlayed = nil
local currentAnimDict = nil
local emoteSelect = false
local previewMode = false
local opening = false
local cachedCategories = nil
local animOverrides = {}

-- Listen for override updates from server (broadcast)
RegisterNetEvent("vfw:animManager:overridesUpdated", function(overrides)
    animOverrides = overrides or {}
    cachedCategories = nil
end)

-- Animations personnalisées (custom_anims.lua) : RP a changé, on reconstruit les catégories
RegisterNetEvent("vfw:animManager:customUpdated", function()
    cachedCategories = nil
end)
local hasActiveEmoteProps = false -- Track if player has props from emote
local pendingVehicleAnimation = false -- Flag pour indiquer qu'une animation véhicule va être jouée

function VFW.GetPedAnimationIsPlaying()
    if currentAnimDict and currentAnimationPlayed then
        return { currentAnimDict, currentAnimationPlayed }
    end
    return nil
end

-- Animal models for preview
local AnimalModels = {
    rottweiler = "a_c_rottweiler",  -- Gros chien
    pug = "a_c_pug",                 -- Petit chien
    cat = "a_c_cat_01",              -- Chat
    default = "a_c_rottweiler"       -- Par défaut: gros chien
}

-- Liste complète des modèles animaux (pour vérifier si le joueur est un animal)
local AllAnimalModels = {
    -- Chiens
    [`a_c_rottweiler`] = true,
    [`a_c_pug`] = true,
    [`a_c_poodle`] = true,
    [`a_c_husky`] = true,
    [`a_c_retriever`] = true,
    [`a_c_shepherd`] = true,
    [`a_c_westy`] = true,
    [`a_c_chop`] = true,
    [`a_c_chop_02`] = true,
    -- Chats
    [`a_c_cat_01`] = true,
    -- Autres animaux
    [`a_c_boar`] = true,
    [`a_c_chickenhawk`] = true,
    [`a_c_chimp`] = true,
    [`a_c_chimp_02`] = true,
    [`a_c_cormorant`] = true,
    [`a_c_cow`] = true,
    [`a_c_coyote`] = true,
    [`a_c_crow`] = true,
    [`a_c_deer`] = true,
    [`a_c_dolphin`] = true,
    [`a_c_fish`] = true,
    [`a_c_hen`] = true,
    [`a_c_humpback`] = true,
    [`a_c_killerwhale`] = true,
    [`a_c_mtlion`] = true,
    [`a_c_pig`] = true,
    [`a_c_pigeon`] = true,
    [`a_c_rabbit_01`] = true,
    [`a_c_rabbit_02`] = true,
    [`a_c_rat`] = true,
    [`a_c_rhesus`] = true,
    [`a_c_seagull`] = true,
    [`a_c_sharkhammer`] = true,
    [`a_c_sharktiger`] = true,
    [`a_c_stingray`] = true,
}

-- Fonction pour vérifier si un ped est un animal
local function IsPedAnimal(ped)
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    local model = GetEntityModel(ped)
    return AllAnimalModels[model] == true
end

-- Fonction pour détecter le type d'animal depuis le nom de l'emote
local function GetAnimalTypeFromEmote(emoteName)
    if not emoteName then return nil end
    local name = string.lower(emoteName)

    -- Gros chien (bdog)
    if string.sub(name, 1, 4) == "bdog" then
        return "rottweiler"
    -- Petit chien (sdog)
    elseif string.sub(name, 1, 4) == "sdog" then
        return "pug"
    -- Chat (chat)
    elseif string.sub(name, 1, 4) == "chat" then
        return "cat"
    end

    return nil
end

-- Fonction pour créer un ped animal pour la preview
local function CreateAnimalPreviewPed(animalType, position, heading, previewId)
    -- S'assurer qu'aucun animal de preview n'existe
    if animalPed and DoesEntityExist(animalPed) then
        SetEntityAsMissionEntity(animalPed, true, true)
        DeletePed(animalPed)
        animalPed = nil
    end

    local model = AnimalModels[animalType] or AnimalModels.default
    local modelHash = joaat(model)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        -- Vérifier si la preview a été annulée pendant le chargement
        if previewId and currentPreviewId ~= previewId then
            SetModelAsNoLongerNeeded(modelHash)
            return nil
        end
        Wait(10)
        timeout = timeout + 1
    end

    -- Vérifier à nouveau après le chargement
    if previewId and currentPreviewId ~= previewId then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    if not HasModelLoaded(modelHash) then
        return nil
    end

    local ped = CreatePed(28, modelHash, position.x, position.y, position.z, heading, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    -- Si la preview a été annulée pendant la création, supprimer immédiatement
    if previewId and currentPreviewId ~= previewId then
        if ped and DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, true, true)
            DeletePed(ped)
        end
        return nil
    end

    if DoesEntityExist(ped) then
        SetPedFleeAttributes(ped, 0, 0)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdollFromPlayerImpact(ped, false)
        SetPedCanRagdoll(ped, false)
        SetPedDiesWhenInjured(ped, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetEntityCompletelyDisableCollision(ped, true, false)
        SetEntityAlpha(ped, 204, false)
    end

    return ped
end

-- Fonction pour supprimer les props de preview animale
local function DeleteAnimalPreviewProps()
    for i, propEntity in pairs(animalPreviewProps) do
        if propEntity and DoesEntityExist(propEntity) then
            SetEntityAsMissionEntity(propEntity, true, true)
            DeleteEntity(propEntity)
        end
    end
    animalPreviewProps = {}
end

-- Fonction pour supprimer le ped animal et ses props
local function DeleteAnimalPreviewPed()
    -- Supprimer les props d'abord
    DeleteAnimalPreviewProps()

    local pedToDelete = animalPed
    animalPed = nil

    if pedToDelete and DoesEntityExist(pedToDelete) then
        SetEntityAsMissionEntity(pedToDelete, true, true)
        DeletePed(pedToDelete)
    end
end

-- Fonction pour attacher un prop à un ped animal pour la preview
local function AttachAnimalPreviewProp(ped, propModel, boneTag, placement, propId)
    if not propModel or not placement or #placement < 6 then
        return nil
    end

    local propHash = joaat(propModel)
    RequestModel(propHash)
    local timeout = 0
    while not HasModelLoaded(propHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(propHash) then
        return nil
    end

    local propEntity = CreateObject(propHash, GetEntityCoords(ped), false, false, false)
    SetModelAsNoLongerNeeded(propHash)

    if propEntity and DoesEntityExist(propEntity) then
        local boneIndex = 0
        if type(boneTag) == 'number' then
            boneIndex = GetPedBoneIndex(ped, boneTag)
        elseif type(boneTag) == 'string' then
            boneIndex = GetEntityBoneIndexByName(ped, boneTag)
        end

        AttachEntityToEntity(
            propEntity, ped, boneIndex,
            placement[1] or 0.0, placement[2] or 0.0, placement[3] or 0.0,
            placement[4] or 0.0, placement[5] or 0.0, placement[6] or 0.0,
            true, true, false, true, 1, true
        )

        animalPreviewProps[propId] = propEntity
        return propEntity
    end

    return nil
end

-- Fonction pour supprimer le véhicule de preview
local function DeletePreviewVehicle()
    local vehToDelete = previewVehicle
    previewVehicle = nil

    if vehToDelete and DoesEntityExist(vehToDelete) then
        -- Retirer le ped du véhicule d'abord
        if clonePed and DoesEntityExist(clonePed) then
            if GetVehiclePedIsIn(clonePed, false) == vehToDelete then
                ClearPedTasksImmediately(clonePed)
                local vehPos = GetEntityCoords(vehToDelete)
                SetEntityCoords(clonePed, vehPos.x, vehPos.y, vehPos.z + 1.0, false, false, false, true)
            end
        end

        SetEntityAsMissionEntity(vehToDelete, true, true)
        DeleteVehicle(vehToDelete)
    end
end

-- Fonction pour nettoyer les props d'un ped (sans Wait)
local function CleanupPedPropsImmediate(ped)
    if not ped or not prop[ped] then return end

    for i = 1, 2 do
        if prop[ped][i] and type(prop[ped][i]) ~= "boolean" and DoesEntityExist(prop[ped][i]) then
            SetEntityAsMissionEntity(prop[ped][i], true, true)
            DeleteEntity(prop[ped][i])
        end
        prop[ped][i] = nil
    end
    prop[ped] = nil
end

-- Fonction de nettoyage complet pour les previews (SANS Wait)
local function CleanupAllPreviews()
    -- Safety-net : supprimer toute entité prop locale créée en preview,
    -- même orpheline (perdue à cause d'une race entre AttachProp et un nouveau preview)
    for i = 1, #previewLocalProps do
        local ent = previewLocalProps[i]
        if ent and DoesEntityExist(ent) then
            SetEntityAsMissionEntity(ent, true, true)
            DeleteEntity(ent)
        end
    end
    previewLocalProps = {}

    -- Nettoyer animal
    DeleteAnimalPreviewProps()
    if animalPed and DoesEntityExist(animalPed) then
        SetEntityAsMissionEntity(animalPed, true, true)
        DeletePed(animalPed)
    end
    animalPed = nil

    -- Nettoyer véhicule - sortir le ped d'abord
    if previewVehicle and DoesEntityExist(previewVehicle) then
        if clonePed and DoesEntityExist(clonePed) then
            if GetVehiclePedIsIn(clonePed, false) == previewVehicle then
                ClearPedTasksImmediately(clonePed)
                -- Sortir le ped du véhicule proprement
                local vehPos = GetEntityCoords(previewVehicle)
                SetEntityCoords(clonePed, vehPos.x, vehPos.y, vehPos.z + 1.0, false, false, false, true)
            end
        end
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteVehicle(previewVehicle)
    end
    previewVehicle = nil

    -- Nettoyer les props du clonePed
    if clonePed then
        CleanupPedPropsImmediate(clonePed)
        if DoesEntityExist(clonePed) then
            ClearPedTasksImmediately(clonePed)
        end
    end

    -- Nettoyer les props du clonePed2
    if clonePed2 then
        CleanupPedPropsImmediate(clonePed2)
        if DoesEntityExist(clonePed2) then
            ClearPedTasksImmediately(clonePed2)
        end
    end
end

-- Fonction pour créer un véhicule de preview
local function CreatePreviewVehicle(position, heading)
    -- S'assurer qu'aucun véhicule de preview n'existe
    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end

    local vehicleModel = "sultan" -- Véhicule basique pour la preview
    local modelHash = joaat(vehicleModel)

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        return nil
    end

    local vehicle = CreateVehicle(modelHash, position.x, position.y, position.z, heading, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    if DoesEntityExist(vehicle) then
        -- Configurer le véhicule de preview
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetEntityAlpha(vehicle, 204, false)
        -- NE PAS freezer le véhicule pour permettre les repositionnements dans le loop principal
        SetVehicleDoorsLocked(vehicle, 2)
        SetEntityInvincible(vehicle, true)
        SetEntityCompletelyDisableCollision(vehicle, true, false)
        SetVehicleEngineOn(vehicle, false, true, true)

        previewVehicle = vehicle
        return vehicle
    end

    return nil
end

-- Fonction pour détecter le siège depuis le nom de l'animation véhicule
local function GetVehicleSeatFromEmoteName(emoteName)
    if not emoteName then return -1 end -- -1 = driver seat par défaut
    local name = string.lower(emoteName)

    -- Animations avec "r" à la fin = passager (droite)
    -- Animations avec "l" à la fin = conducteur (gauche)
    if string.match(name, "r$") or string.match(name, "right") then
        return 0 -- Siège passager avant
    end

    return -1 -- Siège conducteur par défaut
end

--Functions

--- CleanUpProps
---@param ped number Ped handle
---@return any
local function CleanUpProps(ped)
    if not ped or not prop[ped] then
        return
    end

    currentAction[ped] = 'cleaning'

    -- For local player, trigger server to delete network props
    if ped == VFW.PlayerData.ped then
        for i = 1, 2 do
            if prop[ped][i] then
                TriggerServerEvent("vfw:newanim:deleteProp", i)
                prop[ped][i] = nil
            end
        end
        hasActiveEmoteProps = false
    else
        -- For preview ped or other local entities, delete locally
        for i = 1, 2 do
            if prop[ped][i] and type(prop[ped][i]) ~= "boolean" and DoesEntityExist(prop[ped][i]) then
                DeleteEntity(prop[ped][i])
                local timeout = 0

                while DoesEntityExist(prop[ped][i]) and timeout < 50 do
                    Wait(0)
                    timeout = timeout + 1
                end

                prop[ped][i] = nil
            end
        end
    end

    prop[ped] = nil

    currentAction[ped] = nil
end

--- Force cleanup all emote props for the local player (safety net)
local function ForceCleanupEmoteProps()
    local ped = VFW.PlayerData.ped
    if not ped then return end

    -- Delete props via server
    TriggerServerEvent("vfw:newanim:deleteAllProps")

    -- Clear local tracking
    if prop[ped] then
        prop[ped] = nil
    end
    hasActiveEmoteProps = false
    lastEmote[ped] = nil
    currentAnimationPlayed = nil
    currentAnimDict = nil
end

-- Thread de surveillance pour nettoyer les props si l'animation se termine de façon inattendue
-- Utilise un compteur de tolérance pour éviter de supprimer les props sur un faux négatif de IsEntityPlayingAnim
CreateThread(function()
    local missedChecks = 0
    local TOLERANCE = 5 -- Nombre de checks consécutifs avant cleanup (5 secondes)

    while true do
        Wait(1000) -- Check every second

        local ped = VFW.PlayerData.ped
        if ped and hasActiveEmoteProps then
            -- Vérifier si le joueur fait encore l'animation
            local stillPlaying = false
            if currentAnimDict and currentAnimationPlayed then
                stillPlaying = IsEntityPlayingAnim(ped, currentAnimDict, currentAnimationPlayed, 3)
            end

            -- Si le joueur a une arme en main, nettoyer les props d'emote
            local currentWeapon = GetSelectedPedWeapon(ped)
            local hasWeaponOut = currentWeapon ~= `weapon_unarmed`

            if hasWeaponOut then
                -- Arme sortie = cleanup immédiat (intentionnel)
                missedChecks = 0
                ForceCleanupEmoteProps()
            elseif not stillPlaying then
                -- Animation pas détectée - incrémenter le compteur au lieu de cleanup immédiat
                missedChecks = missedChecks + 1
                if missedChecks >= TOLERANCE then
                    missedChecks = 0
                    ForceCleanupEmoteProps()
                end
            else
                -- Animation joue normalement, reset le compteur
                missedChecks = 0
            end
        else
            missedChecks = 0
        end
    end
end)

--- DetachIfAttached
---@param ped number Ped handle
local function DetachIfAttached(ped)
    if IsEntityAttached(ped) then
        DetachEntity(ped, true, false)
    end
end

--- PlayWalk
---@param ped number Ped handle
---@param walk any
---@return any
local function PlayWalk(ped, walk)
    if not walk then
        return
    end

    RequestWalking(walk)
    SetPedMovementClipset(ped, walk, 0.2)
    RemoveAnimSet(walk)
    if ped == VFW.PlayerData.ped then
        SetResourceKvp("walkstyle", walk)
        -- Sync with server for other players to copy
        TriggerServerEvent("vfw:animation:syncWalk", walk)
    end
end

local function ResetWalk(ped)
    ResetPedMovementClipset(ped, 0.0)
    if ped == VFW.PlayerData.ped then
        DeleteResourceKvp("walkstyle")
        -- Sync with server
        TriggerServerEvent("vfw:animation:syncWalk", nil)
    end
end

--- PlayExpression
---@param ped number Ped handle
---@param expression any
---@return any
local function PlayExpression(ped, expression)
    if not expression then
        return
    end

    SetFacialIdleAnimOverride(ped, expression, 0)
    if ped == VFW.PlayerData.ped then
        SetResourceKvp("expression", expression)
    end
end

function HasActiveEmote(ped)
    if not ped then
        ped = VFW.PlayerData.ped
    end
    return lastEmote[ped] ~= nil or hasActiveEmoteProps
end

function StopAnimation(ped, instant)
    if not DoesEntityExist(ped) then
        return
    end

    -- Clear tracking if it exists
    if lastEmote[ped] ~= nil then
        lastEmote[ped] = nil
    end

    -- 1. Detach first (simple, no Wait)
    if not IsPedInAnyVehicle(ped, false) then
        DetachIfAttached(ped)
    end

    -- 2. Clean up props
    CleanUpProps(ped)

    -- 3. Stop animation / clear tasks
    local usedSmoothStop = false
    if not instant and currentAnimDict and currentAnimationPlayed then
        if IsEntityPlayingAnim(ped, currentAnimDict, currentAnimationPlayed, 3) then
            StopAnimTask(ped, currentAnimDict, currentAnimationPlayed, -1.0)
            usedSmoothStop = true
        end
    end

    if not usedSmoothStop then
        if not IsPedInAnyVehicle(ped, false) then
            if instant then
                ClearPedTasksImmediately(ped)
            else
                ClearPedTasks(ped)
            end
        else
            ClearPedSecondaryTask(ped)
        end
    end

    -- 4. Reset animation tracking (after StopAnimTask uses the values)
    if ped == VFW.PlayerData.ped then
        currentAnimDict = nil
        currentAnimationPlayed = nil
        TriggerServerEvent("vfw:newanim:phaseStop")
    end
end

--- EmoteCancel
function EmoteCancel()
    local ped = VFW.PlayerData and VFW.PlayerData.ped or PlayerPedId()

    -- 1. Detach first (simple, no Wait)
    if ped and ped ~= 0 then
        DetachIfAttached(ped)

        -- 2. Clean up props
        CleanUpProps(ped)
    end

    -- 3. Reset tracking
    local wasScenario = lastAnimation and lastAnimation[1] == "Scenario"
    currentAnimDict = nil
    currentAnimationPlayed = nil
    if ped and ped ~= 0 then
        lastEmote[ped] = nil
    end
    lastAnimation = nil
    TriggerServerEvent("vfw:newanim:phaseStop")

    -- 4. Stop tasks. Scenarios ignore the smooth blend-out of ClearPedTasks,
    -- so they need ClearPedTasksImmediately to actually interrupt.
    if ped and ped ~= 0 then
        if wasScenario then
            ClearPedTasksImmediately(ped)
        else
            ClearPedTasks(ped)
        end
    end
end

--- PlayAnimation
---@param ped number Ped handle
---@param animationData table
---@param skipStop? boolean Skip StopAnimation (for shared emotes where caller handles cleanup)
---@return any
function PlayAnimation(ped, animationData, skipStop)
    if not ped or ped == 0 then
        return
    end

    local isPreviewPed = ped ~= VFW.PlayerData.ped

    if not animationData or type(animationData) ~= "table" then
        return
    end


    if animationData[1] == "Scenario" then
        StopAnimation(ped) -- Nettoie tout
        TaskStartScenarioInPlace(ped, animationData[2], 0, true)
        lastAnimation = animationData
        currentAction[ped] = nil
        lastEmote[ped] = id
        id = id + 1
        if ped == VFW.PlayerData.ped and not previewMode then
            PendingPhaseInherit = nil
            TriggerServerEvent("vfw:newanim:phaseStop")
        end
        return
    end

    if skipStop then
        -- Shared emotes: NO semaphore wait (would yield and cause drift between SetEntityCoords and TaskPlayAnim)
        -- NO StopAnimation, NO ClearPedTasks, NO yields
        -- TaskPlayAnim will override the current animation task automatically
        currentAction[ped] = 'playing'
        if ped == VFW.PlayerData.ped then
            currentAnimDict = nil
            currentAnimationPlayed = nil
        end
    else
        while currentAction[ped] ~= nil do
            Wait(0)
        end
        currentAction[ped] = 'playing'
        StopAnimation(ped)
    end

    local animDict = animationData[1]
    local animName = animationData[2]

    if not animName or not animDict then
        currentAction[ped] = nil
        return
    end

    local currentId = id
    lastEmote[ped] = currentId
    id = id + 1

    -- Thread dédié pour désactiver Control 22 ET gérer l'annulation en véhicule
    local isInVehicle = IsPedInAnyVehicle(ped, false)

    if isInVehicle then
        -- Capturer le flag d'animation véhicule et le reset immédiatement
        local shouldBlockMovement = pendingVehicleAnimation
        pendingVehicleAnimation = false

        CreateThread(function()
            local animId = currentId
            local threadAnimDict = animDict
            local threadAnimName = animName
            while lastEmote[ped] == animId do
                DisableControlAction(0, 22, true)  -- Désactive dans control group 0
                DisableControlAction(1, 22, true)  -- Désactive dans control group 1

                -- Bloquer les contrôles de mouvement VÉHICULE pour les animations véhicule
                if shouldBlockMovement then
                    DisableControlAction(0, 71, true)  -- W - VehicleAccelerate
                    DisableControlAction(0, 72, true)  -- S - VehicleBrake
                    DisableControlAction(0, 63, true)  -- A/D - VehicleMoveLeftRight
                    DisableControlAction(0, 64, true)  -- Steering (mouse)
                    DisableControlAction(0, 79, true)  -- C - VehicleLookBehind
                    DisableControlAction(0, 80, true)  -- VehicleCinCam
                end

                -- Détecter X même quand le control est désactivé (contourne le NUI focus)
                if IsDisabledControlJustPressed(0, 22) or IsControlJustPressed(0, 22) then
                    -- Annuler l'animation directement
                    lastEmote[ped] = nil

                    -- NE PAS détacher si en véhicule (sinon on sort du véhicule)
                    -- On détache seulement pour les animations partagées (attaché à un autre ped)
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if not vehicle or vehicle == 0 then
                        -- Pas en véhicule, on peut détacher (pour animations partagées)
                        if IsEntityAttached(ped) then
                            DetachEntity(ped, true, true)
                            Wait(50)
                        end
                    end

                    CleanUpProps(ped)

                    -- Stopper l'animation avec blend-out fluide
                    if threadAnimDict and threadAnimName and IsEntityPlayingAnim(ped, threadAnimDict, threadAnimName, 3) then
                        StopAnimTask(ped, threadAnimDict, threadAnimName, -1.0)
                    else
                        ClearPedSecondaryTask(ped)
                    end

                    -- Reset animation tracking
                    if ped == VFW.PlayerData.ped then
                        currentAnimDict = nil
                        currentAnimationPlayed = nil
                    end

                    break  -- Sortir du thread
                end

                Wait(0)
            end
        end)
    end

    if not prop[ped] then
        prop[ped] = {}
    end

    RequestAnimDict(animDict)
    local timeout = 0

    while not HasAnimDictLoaded(animDict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasAnimDictLoaded(animDict) then
        currentAction[ped] = nil
        return
    end


    if lastEmote[ped] ~= currentId then
        RemoveAnimDict(animDict)
        currentAction[ped] = nil
        return
    end

    local movementType = 0

    if VFW.PlayerData.vehicle ~= nil and VFW.PlayerData.vehicle ~= false then
        if animationData.AnimationOptions and animationData.AnimationOptions.FullBody then
            movementType = 35
        else
            movementType = 51
        end
    elseif animationData.AnimationOptions then
        movementType = animationData.AnimationOptions.EmoteMoving and 51
                or animationData.AnimationOptions.EmoteLoop and 1
                or animationData.AnimationOptions.EmoteStuck and 50
                or animationData.AnimationOptions.FullBody and 35
                or movementType
    end

    -- Ne mettre à jour les variables de tracking que pour le joueur (pas les peds de preview)
    if ped == VFW.PlayerData.ped then
        currentAnimDict = animDict
        currentAnimationPlayed = animName
    end

    -- Pour les previews, on ignore la durée et on boucle l'animation
    local duration = animationData.AnimationOptions?.EmoteDuration or -1
    if previewMode then
        duration = -1 -- Boucle infinie pour les previews
    end


    TaskPlayAnim(
            ped,
            animDict,
            animName,
            animationData.AnimationOptions?.BlendInSpeed or 5.0,
            animationData.AnimationOptions?.BlendOutSpeed or 5.0,
            duration,
            movementType,
            0,
            false,
            false,
            false
    )

    -- Phase-lock registration: only the local player ped, no preview clones.
    -- Sends server the anim duration so every observer can compute the same
    -- phase from the shared server clock. PendingPhaseInherit is set by the
    -- "Copier l'emote (synchro)" button so the new emote inherits the
    -- target's startedAt and locks onto the same beat.
    if ped == VFW.PlayerData.ped and not previewMode then
        local animDurMs = math.floor((GetAnimDuration(animDict, animName) or 0) * 1000)
        if animDurMs > 0 then
            local inheritFrom = PendingPhaseInherit
            PendingPhaseInherit = nil
            TriggerServerEvent("vfw:newanim:phaseStart", animDict, animName, animDurMs, inheritFrom)
        else
            PendingPhaseInherit = nil
            TriggerServerEvent("vfw:newanim:phaseStop")
        end
    end

    if isPreviewPed then
        Wait(100)
    end

    -- Ne PAS décharger le dictionnaire pour pouvoir stopper l'animation avec StopAnimTask
    -- RemoveAnimDict(animDict)

    --- AttachProp
    ---@param propModel any
    ---@param boneTag any Bone ID (number like 57005) or bone name (string)
    ---@param placement any
    ---@param propId number|string
    ---@return any
    local function AttachProp(propModel, boneTag, placement, propId, rotOrder)
        if not propModel or type(placement) ~= "table" or #placement ~= 6 then
            return
        end

        if lastEmote[ped] ~= currentId then
            return
        end

        local propRotOrder = rotOrder or 1 -- Default ZYX (1)

        -- Mark that we're tracking this prop
        prop[ped][propId] = true

        -- Only local player gets network props, preview ped uses local props
        if ped == VFW.PlayerData.ped and not previewMode then
            -- Convert placement array to vec3 for offset and rotation
            local offset = vector3(placement[1], placement[2], placement[3])
            local rotation = vector3(placement[4], placement[5], placement[6])

            -- Send original bone tag/ID to server (NOT converted to index)
            -- NetAttachedEntity will handle the bone conversion on the client side
            TriggerServerEvent("vfw:newanim:spawnProp", propModel, boneTag, offset, rotation, propId, propRotOrder)
            hasActiveEmoteProps = true -- Mark that we have active props
        else
            -- Preview ped or other peds use local prop spawning
            if prop[ped][propId] == true then
                prop[ped][propId] = nil
            end

            if prop[ped][propId] and DoesEntityExist(prop[ped][propId]) then
                DeleteEntity(prop[ped][propId])
                local timeout = 0

                while DoesEntityExist(prop[ped][propId]) and timeout < 50 do
                    Wait(0)
                    timeout = timeout + 1
                end

                prop[ped][propId] = nil
            end

            RequestModel(propModel)
            timeout = 0
            while not HasModelLoaded(propModel) and timeout < 1000 do
                Wait(0)
                timeout = timeout + 1
            end

            if not HasModelLoaded(propModel) then
                console.debug("Timeout while loading prop model: " .. propModel)
                return
            end

            if lastEmote[ped] ~= currentId then
                SetModelAsNoLongerNeeded(propModel)
                return
            end

            prop[ped][propId] = CreateObject(propModel, GetEntityCoords(ped), false, false, false)
            SetModelAsNoLongerNeeded(propModel)

            if prop[ped][propId] and DoesEntityExist(prop[ped][propId]) then
                previewLocalProps[#previewLocalProps + 1] = prop[ped][propId]
                -- For local attachment, convert boneTag to boneIndex
                local boneIndex = 0
                if type(boneTag) == 'number' then
                    boneIndex = GetPedBoneIndex(ped, boneTag)
                elseif type(boneTag) == 'string' then
                    boneIndex = GetEntityBoneIndexByName(ped, boneTag)
                end

                AttachEntityToEntity(
                        prop[ped][propId], ped, boneIndex,
                        placement[1], placement[2], placement[3],
                        placement[4], placement[5], placement[6],
                        true, true, false, true, propRotOrder, true
                )
            end
        end
    end

    if animationData.AnimationOptions then
        local animRotOrder = animationData.AnimationOptions.RotOrder

        if animationData.AnimationOptions.Prop and animationData.AnimationOptions.Prop ~= "" then
            local propModel = joaat(animationData.AnimationOptions.Prop)
            -- Pass the original bone tag/ID, not converted to index
            local boneTag = animationData.AnimationOptions.PropBone or 57005
            AttachProp(propModel, boneTag, animationData.AnimationOptions.PropPlacement, 1, animRotOrder)
        end

        if animationData.AnimationOptions.SecondProp and animationData.AnimationOptions.SecondProp ~= "" then
            local propModel = joaat(animationData.AnimationOptions.SecondProp)
            -- Pass the original bone tag/ID, not converted to index
            local boneTag = animationData.AnimationOptions.SecondPropBone or 57005
            AttachProp(propModel, boneTag, animationData.AnimationOptions.SecondPropPlacement, 2, animRotOrder)
        end
    end

    lastAnimation = animationData
    currentAction[ped] = nil
end



local function ConvertToCategories()
    local animations = {}
    local icons = {}
    local labels = {}

    for categoryName, group in pairs(RP) do
        if not animations[categoryName] then
            animations[categoryName] = {}
        end
        icons[categoryName] = group.icon or "🎬"
        labels[categoryName] = group.label or categoryName

        local groupType = type(group.type) == "string" and group.type or "emote"

        for key, v in pairs(group) do
            if type(v) == "table" then
                local override = animOverrides[key]

                -- Skip disabled animations
                if override and override.disabled then
                    goto continue
                end

                local name = key
                local dist = v[1]
                local label = (override and override.label) or v[3] or v[2] or key
                local targetCategory = (override and override.category) or categoryName

                -- Ensure target category exists
                if not animations[targetCategory] then
                    animations[targetCategory] = {}
                    icons[targetCategory] = icons[targetCategory] or (RP[targetCategory] and RP[targetCategory].icon or "🎬")
                    labels[targetCategory] = labels[targetCategory] or (RP[targetCategory] and RP[targetCategory].label or targetCategory)
                end

                local anim = {
                    name = name,
                    dist = dist,
                    label = label,
                    category = targetCategory,
                    type = groupType,
                    shared = (categoryName == "Shared"),
                    previewDisabled = override and override.previewDisabled or nil,
                }

                if v.AnimationOptions then
                    anim.options = v.AnimationOptions
                end

                table.insert(animations[targetCategory], anim)
                ::continue::
            end
        end
    end

    -- Remove empty categories
    for catName, catAnims in pairs(animations) do
        if #catAnims == 0 then
            animations[catName] = nil
        end
    end

    return {
        animations = animations,
        icons = icons,
        labels = labels
    }
end


function EmoteCommandStart(data, ped, shared)
    local name = string.lower(data)
    local playerPed = ped and ped or VFW.PlayerData.ped
    local isPreviewPed = playerPed ~= VFW.PlayerData.ped

    -- Bloquer les emotes pendant un carry : sinon /e sit + /porter + /cancelemote
    -- provoque un clip-floor (carrier ancre par le scenario, B encore attache).
    if not isPreviewPed and (
        (VFW.IsCarrying and VFW.IsCarrying()) or
        (VFW.IsBeingCarried and VFW.IsBeingCarried())
    ) then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas faire d'emote pendant un portage."
        })
        return
    end

    if shared then
        if emoteSelect then
            local target = VFW.StartSelect(5.0, true)
            if not target then
                VFW.ShowNotification({
                    type = 'ORANGE',
                    content = "Aucune personne à proximité pour cette emote"
                })
                emoteSelect = false
                return
            end

            console.debug("Sended to " .. target)
            TriggerServerEvent("vfw:newanim:requestShared", GetPlayerServerId(target), name)
            emoteSelect = false
        end

        return
    end

    if RP.Emotes[name] ~= nil then
        PlayAnimation(playerPed, RP.Emotes[name])
    elseif RP.Dances[name] ~= nil then
        PlayAnimation(playerPed, RP.Dances[name])
    elseif RP.PropEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.PropEmotes[name])
    elseif RP.ActivitesEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.ActivitesEmotes[name])
    elseif RP.GestesEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.GestesEmotes[name])
    elseif RP.PositionsEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.PositionsEmotes[name])
    elseif RP.SportEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.SportEmotes[name])
    elseif RP.GangEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.GangEmotes[name])
    elseif RP.AutresEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.AutresEmotes[name])
    elseif RP.Vehicules[name] ~= nil then
        -- Vérifier que le joueur est dans un véhicule
        if not IsPedInAnyVehicle(playerPed, false) then
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Vous devez être dans un véhicule pour cette animation"
            })
            return
        end
        -- Définir le flag AVANT PlayAnimation pour que le thread capture l'info
        pendingVehicleAnimation = true
        PlayAnimation(playerPed, RP.Vehicules[name])
    elseif RP.Exits[name] ~= nil then
        PlayAnimation(playerPed, RP.Exits[name])
    elseif RP.AnimalEmotes[name] ~= nil then
        -- Vérifier si le joueur est un ped animal
        if not IsPedAnimal(playerPed) then
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Cette emote est réservée aux animaux"
            })
            return
        end
        PlayAnimation(playerPed, RP.AnimalEmotes[name])
    elseif RP.SanteEmotes[name] ~= nil then
        PlayAnimation(playerPed, RP.SanteEmotes[name])
    else
        -- Catégorie hors liste (ex. animation personnalisée) : recherche générique
        for _, group in pairs(RP) do
            if type(group) == "table" and group.type ~= "walk" and group.type ~= "expresion" and type(group[name]) == "table" then
                PlayAnimation(playerPed, group[name])
                return
            end
        end
    end
end


VFW.RegisterInput("openNewAnimation", "Menu des emotes", "keyboard", "K", function()
    -- Ne pas ouvrir le menu emotes si le Prop Placer est actif (K = gizmo mode)
    if _G.PropPlacer and _G.PropPlacer.active then
        return
    end

    if IsPlayerInMugshot() then return end
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées pendant les TIG"
        })
        return
    end

    if LocalPlayer.state.isCuffed then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées quand vous êtes menotté"
        })
        return
    end

    if Death.isDead or VFW.PlayerData.dead then
        return
    end

    if SN_SAMS and SN_SAMS.IsMDTOpen and SN_SAMS.IsMDTOpen() then
        return
    end

    if opening then
        return
    end

    if not open then
        opening = true
        open = true
        Wait(200)
        animOverrides = TriggerServerCallback("vfw:animManager:getOverrides") or {}
        cachedCategories = ConvertToCategories()
        VFW.Nui.newanimation(true, cachedCategories)


        if open then
            SetCursorLocation(0.5, 0.5)
        end

        -- Cacher le clone par défaut jusqu'à ce qu'une preview normale soit demandée
        hideClonePreview = true

        local inVehicle = IsPedInAnyVehicle(VFW.PlayerData.ped, false)

        if not inVehicle then
            clonePed = ClonePed(VFW.PlayerData.ped, false, true, true)
            SetEntityAsMissionEntity(clonePed, true, true)
            SetPedAudioFootstepLoud(clonePed, false)
            SetPedAudioFootstepQuiet(clonePed, false)
            SetPedFleeAttributes(clonePed, 0, 0)
            SetBlockingOfNonTemporaryEvents(clonePed, true)
            SetPedCanRagdollFromPlayerImpact(clonePed, false)
            SetPedCanRagdoll(clonePed, false)
            SetPedDiesWhenInjured(clonePed, false)
            FreezeEntityPosition(clonePed, true)
            SetEntityInvincible(clonePed, true)
            DisablePedPainAudio(clonePed, true)
            SetEntityCompletelyDisableCollision(clonePed, true, false)
            -- Désactive aussi la collision côté entité (et garde la physique pour que les anims tournent).
            SetEntityCollision(clonePed, false, true)
            SetPedConfigFlag(clonePed, 52, true)
            SetEntityVisible(clonePed, false)

            -- Create second clone for shared emote preview
            clonePed2 = ClonePed(VFW.PlayerData.ped, false, true, true)
            SetEntityAsMissionEntity(clonePed2, true, true)
            SetPedAudioFootstepLoud(clonePed2, false)
            SetPedAudioFootstepQuiet(clonePed2, false)
            SetPedFleeAttributes(clonePed2, 0, 0)
            SetBlockingOfNonTemporaryEvents(clonePed2, true)
            SetPedCanRagdollFromPlayerImpact(clonePed2, false)
            SetPedCanRagdoll(clonePed2, false)
            SetPedDiesWhenInjured(clonePed2, false)
            FreezeEntityPosition(clonePed2, true)
            SetEntityInvincible(clonePed2, true)
            DisablePedPainAudio(clonePed2, true)
            SetEntityCompletelyDisableCollision(clonePed2, true, false)
            SetEntityCollision(clonePed2, false, true)
            SetPedConfigFlag(clonePed2, 52, true)
            SetEntityVisible(clonePed2, false)
        end

        opening = false

        local posBuffer = {}
        local bufferSize = 5

        CreateThread(function()
            while open do
                Wait(4)
                local camRot = GetGameplayCamRot(2)
                local pitch = camRot.x
                local t = math.max(0.0, math.min(1.0, (pitch + 70.0) / 120.0))

                -- Décaler vers la gauche pour les emotes partagées (pour voir les 2 personnages)
                local screenX = zoom and (0.58 + t * 0.06) or (isSharedPreview and (0.45 + t * 0.06) or (0.62 + t * 0.06))
                local screenY = zoom and (0.50 + t * 0.30) or (0.45 + t * 0.40)
                local depth = zoom and (4.0 - t * 1.0) or (isSharedPreview and (6.5 - t * 1.5) or (5.5 - t * 1.5))

                local world, normal = GetWorldCoordFromScreenCoord(screenX, screenY)
                local target = world + normal * depth

                posBuffer[#posBuffer + 1] = target
                if #posBuffer > bufferSize then
                    table.remove(posBuffer, 1)
                end
                local smoothPos = vector3(0.0, 0.0, 0.0)
                for _, p in ipairs(posBuffer) do
                    smoothPos = smoothPos + p
                end
                smoothPos = smoothPos / #posBuffer

                if hideClonePreview then
                    SetEntityVisible(clonePed, false)
                    SetEntityAlpha(clonePed, 0, false)
                else
                    SetEntityVisible(clonePed, true)
                    SetEntityAlpha(clonePed, 204, false)
                end

                -- Ne pas repositionner le clone pendant les previews de marche (il doit bouger)
                if not isWalkPreview then
                    SetEntityCoords(clonePed, smoothPos.x, smoothPos.y, smoothPos.z, false, false, false, true)
                    SetEntityRotation(clonePed, camRot.x * -1.0, 0.0, camRot.z + 180.0, 2, false)
                    ForcePedMotionState(clonePed, `MotionState_None`, false, 1, true)
                end

                if clonePed2 and DoesEntityExist(clonePed2) then
                    if hideClonePreview then
                        SetEntityVisible(clonePed2, false)
                    else
                        SetEntityAlpha(clonePed2, 204, false)
                    end

                    if isSharedPreview and sharedPreviewOptions then
                        local opts = sharedPreviewOptions
                        if opts.Attachto then
                            -- Attacher une seule fois ; après attach, clonePed2 suit clonePed automatiquement
                            if not clonePed2Attached then
                                local bone = opts.bone or 0
                                AttachEntityToEntity(clonePed2, clonePed, GetPedBoneIndex(clonePed, bone),
                                    opts.xPos or 0.0, opts.yPos or 0.0, opts.zPos or 0.0,
                                    opts.xRot or 0.0, opts.yRot or 0.0, opts.zRot or 0.0,
                                    false, false, false, true, 1, true)
                                clonePed2Attached = true
                            end
                        else
                            -- SyncOffset : positionner clonePed2 relatif à clonePed à chaque frame
                            local SyncOffsetFront = opts.SyncOffsetFront or 1.0
                            local SyncOffsetSide = opts.SyncOffsetSide or 0.0
                            local SyncOffsetHeight = opts.SyncOffsetHeight or 0.0
                            local SyncOffsetHeading = opts.SyncOffsetHeading or 180.1

                            local coords = GetOffsetFromEntityInWorldCoords(clonePed, SyncOffsetSide, SyncOffsetFront, SyncOffsetHeight)
                            local headingClone = GetEntityHeading(clonePed)
                            SetEntityCoordsNoOffset(clonePed2, coords.x, coords.y, coords.z, false, false, false)
                            SetEntityHeading(clonePed2, headingClone - SyncOffsetHeading)
                            ForcePedMotionState(clonePed2, `MotionState_None`, false, 1, true)
                        end
                    else
                        -- Fallback : ancien décalage fixe (au cas où sharedPreviewOptions absent)
                        local headingRad = math.rad(camRot.z + 180.0)
                        local pos2X = smoothPos.x + math.sin(headingRad) * 1.0
                        local pos2Y = smoothPos.y + math.cos(headingRad) * 1.0
                        SetEntityCoords(clonePed2, pos2X, pos2Y, smoothPos.z, false, false, false, true)
                        SetEntityRotation(clonePed2, camRot.x * -1.0, 0.0, camRot.z, 2, false)
                        ForcePedMotionState(clonePed2, `MotionState_None`, false, 1, true)
                    end
                end

                if animalPed and DoesEntityExist(animalPed) then
                    SetEntityCoords(animalPed, smoothPos.x, smoothPos.y, smoothPos.z, false, false, false, true)
                    SetEntityRotation(animalPed, camRot.x * -1.0, 0.0, camRot.z + 180.0, 2, false)
                end

                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 142, open)
                DisableControlAction(0, 18, open)
                DisableControlAction(0, 322, open)
                DisableControlAction(0, 106, open)
                DisableControlAction(0, 263, true)
                DisableControlAction(0, 264, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 143, true)
            end
        end)
    else
        -- Annuler toute preview en cours
        currentPreviewId = currentPreviewId + 1
        hideClonePreview = false
        isSharedPreview = false
        isWalkPreview = false
        sharedPreviewOptions = nil
        if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
            DetachEntity(clonePed2, true, false)
            clonePed2Attached = false
        end

        -- Nettoyage complet
        CleanupAllPreviews()

        if clonePed and DoesEntityExist(clonePed) then
            DeletePed(clonePed)
            clonePed = nil
        end

        if clonePed2 and DoesEntityExist(clonePed2) then
            DeletePed(clonePed2)
            clonePed2 = nil
        end

        open = false
        previewMode = false
        VFW.Nui.newanimation(false)
    end
end)

RegisterNUICallback('nui:newanimation:select', function(data, cb)
    cb("ok")

    if not open then
        return
    end

    if pendingPropCreation then
        -- Si une création de prop est en cours, on attend qu'elle se termine
        Wait(50)
    end

    -- Vérifier si c'est une animation véhicule et si le joueur est dans un véhicule
    -- data[3] = category, data[4] = type
    local isVehicleAnim = data[3] == "Vehicules"
    if isVehicleAnim then
        if not IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
            VFW.ShowNotification({
                type = 'ORANGE',
                content = "Vous devez être dans un véhicule pour cette animation"
            })
            return
        end
        -- Définir le flag AVANT d'appeler EmoteCommandStart/PlayAnimation
        pendingVehicleAnimation = true
    end

    -- Notify partner to cancel (partnerOnly: don't cancel self, we're starting a new emote)
    TriggerServerEvent("vfw:newanim:cancelSharedAnim", true)
    targetPlayerId = nil

    StopAnimation(VFW.PlayerData.ped)

    previewMode = false

    if data[4] == "walk" then
        if data[2] ~= "aucun" then
            PlayWalk(VFW.PlayerData.ped, data[2])
        else
            ResetPedMovementClipset(VFW.PlayerData.ped)
            DeleteResourceKvp("walkstyle")
        end
    elseif data[4] == "expresion" then
        if data[2] ~= "aucun" then
            PlayExpression(VFW.PlayerData.ped, data[2])
        else
            ClearFacialIdleAnimOverride(VFW.PlayerData.ped)
            DeleteResourceKvp("expression")
        end
    elseif data[4] == "Normal" or data[1] == "Cowboy" or data[1] == "Gangster" then
        if data[1] == "Normal" then
            hillbillyAS = false
            gangsterAS = false
        elseif data[1] == "Cowboy" then
            hillbillyAS = true
            gangsterAS = false
        elseif data[1] == "Gangster" then
            hillbillyAS = false
            gangsterAS = true
        end

        Thread()
    else
        emoteSelect = true
        EmoteCommandStart(data[1], VFW.PlayerData.ped, data[5] or nil)
        TriggerServerEvent("vfw:newanim:sync", data[1])
    end
end)

RegisterNUICallback("nui:newanimation:refocus", function(_, cb)
    cb("ok")
    -- 👇 vuelves a aplicar tu helper que ya maneja focus y desactiva ESC
    VFW.Nui.refocus();
end)

RegisterNUICallback("nui:newanimation:input", function(data, cb)
    cb("ok")

    if (data.value) then
        VFW.Nui.Focus(true, false)
    else
        VFW.Nui.Focus(true, true)
    end

    if not open then
        VFW.Nui.Focus(false, false)
    end
end)


RegisterNUICallback('nui:newanimation:close', function(data, cb)
    cb("ok")

    if not open then
        return
    end

    -- Annuler toute preview en cours
    currentPreviewId = currentPreviewId + 1
    hideClonePreview = false
    isSharedPreview = false
    isWalkPreview = false
    sharedPreviewOptions = nil
    if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
        DetachEntity(clonePed2, true, false)
        clonePed2Attached = false
    end

    -- Nettoyage complet des previews
    CleanupAllPreviews()

    -- Supprimer les clones
    if clonePed and DoesEntityExist(clonePed) then
        DeletePed(clonePed)
        clonePed = nil
    end

    if clonePed2 and DoesEntityExist(clonePed2) then
        DeletePed(clonePed2)
        clonePed2 = nil
    end

    open = false
    previewMode = false
    VFW.Nui.newanimation(false)

    CreateThread(function()
        local endTime = GetGameTimer() + 500
        while GetGameTimer() < endTime do
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        end
    end)
end)

RegisterNUICallback('nui:newanimation:preview', function(data, cb)
    cb("ok")

    if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then return end

    -- Cacher le clone immédiatement au début de chaque preview
    hideClonePreview = true

    -- Incrémenter l'ID de preview pour annuler les anciennes
    currentPreviewId = currentPreviewId + 1
    local myPreviewId = currentPreviewId

    local emoteName = string.lower(data[1])
    local category = data[4]
    local animalType = GetAnimalTypeFromEmote(emoteName)


    -- Cancel les PlayAnimation en cours sur les clones
    if clonePed then
        lastEmote[clonePed] = nil
        currentAction[clonePed] = nil
    end
    if clonePed2 then
        lastEmote[clonePed2] = nil
        currentAction[clonePed2] = nil
    end

    -- Nettoyage immédiat complet (sans Wait)
    CleanupAllPreviews()

    -- Vérifier si cette preview est toujours active
    if currentPreviewId ~= myPreviewId then
        return
    end

    previewMode = true
    isSharedPreview = false -- Reset par défaut, sera activé pour les emotes partagées
    isWalkPreview = false -- Reset par défaut, sera activé pour les walks
    sharedPreviewOptions = nil -- Reset par défaut, sera défini pour les emotes partagées
    if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
        DetachEntity(clonePed2, true, false)
        clonePed2Attached = false
    end

    -- ========== ANIMAL EMOTE ==========
    if animalType and RP.AnimalEmotes and RP.AnimalEmotes[emoteName] then
        if clonePed and DoesEntityExist(clonePed) then
            SetEntityVisible(clonePed, false)
        end
        if clonePed2 and DoesEntityExist(clonePed2) then
            SetEntityVisible(clonePed2, false)
        end

        zoom = false
        local pos = GetEntityCoords(clonePed)
        local heading = GetEntityHeading(clonePed)

        animalPed = CreateAnimalPreviewPed(animalType, pos, heading, myPreviewId)

        -- Si la création a été annulée (retourne nil), on sort
        if not animalPed then return end
        if currentPreviewId ~= myPreviewId then return end

        if animalPed and DoesEntityExist(animalPed) then
            local animData = RP.AnimalEmotes[emoteName]
            local dict = animData[1]
            local anim = animData[2]

            if dict and anim then
                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do
                    if currentPreviewId ~= myPreviewId then
                        -- Supprimer l'animal si la preview est annulée pendant le chargement
                        DeleteAnimalPreviewPed()
                        return
                    end
                    Wait(0)
                end

                if currentPreviewId ~= myPreviewId then
                    DeleteAnimalPreviewPed()
                    return
                end

                TaskPlayAnim(animalPed, dict, anim, 2.0, 2.0, -1, 1, 0, false, false, false)

                -- Attacher les props
                if animData.AnimationOptions and animData.AnimationOptions.Prop then
                    local propBone = animData.AnimationOptions.PropBone or 31086
                    AttachAnimalPreviewProp(animalPed, animData.AnimationOptions.Prop, propBone, animData.AnimationOptions.PropPlacement, 1)
                end
                if animData.AnimationOptions and animData.AnimationOptions.SecondProp then
                    local propBone = animData.AnimationOptions.SecondPropBone or 31086
                    AttachAnimalPreviewProp(animalPed, animData.AnimationOptions.SecondProp, propBone, animData.AnimationOptions.SecondPropPlacement, 2)
                end
            end
        end
        return
    end

    -- ========== VEHICLE ANIMATION ==========
    -- Preview non disponible pour les animations véhicules
    if category == "Vehicules" and RP.Vehicules and RP.Vehicules[emoteName] then
        hideClonePreview = true
        if clonePed and DoesEntityExist(clonePed) then
            SetEntityVisible(clonePed, false)
            SetEntityAlpha(clonePed, 0, false)
        end
        if clonePed2 and DoesEntityExist(clonePed2) then
            SetEntityVisible(clonePed2, false)
            SetEntityAlpha(clonePed2, 0, false)
        end
        return
    end

    -- ========== WALK STYLES ==========
    -- Preview des démarches : le clone marche en cercle pour montrer le style
    if data[3] == "walk" then
        hideClonePreview = false
        isWalkPreview = true

        if clonePed2 and DoesEntityExist(clonePed2) then
            SetEntityVisible(clonePed2, false)
            SetEntityAlpha(clonePed2, 0, false)
        end

        if clonePed and DoesEntityExist(clonePed) then
            SetEntityVisible(clonePed, true)
            SetEntityAlpha(clonePed, 204, false)

            -- Appliquer le style de marche
            local walkStyle = data[2]
            if walkStyle and walkStyle ~= "aucun" then
                RequestAnimSet(walkStyle)
                local timeout = 0
                while not HasAnimSetLoaded(walkStyle) and timeout < 50 do
                    Wait(10)
                    timeout = timeout + 1
                end
                if HasAnimSetLoaded(walkStyle) then
                    SetPedMovementClipset(clonePed, walkStyle, 0.2)
                end
            else
                ResetPedMovementClipset(clonePed, 0.0)
            end

            -- Défreezer le clone pour qu'il puisse marcher
            FreezeEntityPosition(clonePed, false)
            SetEntityCollision(clonePed, true, true)
            SetEntityNoCollisionEntity(clonePed, VFW.PlayerData.ped, false)

            -- Arrêter l'ancien thread de marche s'il existe
            if walkPreviewThread then
                walkPreviewThread = nil
            end

            -- Thread pour faire marcher le clone en cercle
            local myPreviewId = currentPreviewId
            local previewWalkStyle = walkStyle
            walkPreviewThread = CreateThread(function()
                local startPos = GetEntityCoords(clonePed)
                local radius = 1.5
                local angle = 0.0
                local speed = 1.0 -- Vitesse de marche normale

                while open and isWalkPreview and currentPreviewId == myPreviewId do
                    if clonePed and DoesEntityExist(clonePed) then
                        -- Sécurité : repositionner le clone s'il tombe sous le sol
                        local clonePos = GetEntityCoords(clonePed)
                        if clonePos.z < startPos.z - 2.0 then
                            SetEntityCoords(clonePed, startPos.x, startPos.y, startPos.z, false, false, false, true)
                        end

                        -- Calculer le prochain point sur le cercle
                        angle = angle + 0.02
                        if angle > math.pi * 2 then
                            angle = 0
                        end

                        local targetX = startPos.x + math.cos(angle) * radius
                        local targetY = startPos.y + math.sin(angle) * radius
                        local targetZ = startPos.z

                        -- Réappliquer le clipset avant chaque mouvement (TaskGoStraightToCoord le reset)
                        if previewWalkStyle and previewWalkStyle ~= "aucun" then
                            SetPedMovementClipset(clonePed, previewWalkStyle, 0.0)
                        end

                        -- Faire marcher le clone vers le point
                        TaskGoStraightToCoord(clonePed, targetX, targetY, targetZ, speed, -1, 0.0, 0.0)
                    end
                    Wait(500)
                end

                -- Refreezer le clone à la fin
                if clonePed and DoesEntityExist(clonePed) then
                    FreezeEntityPosition(clonePed, true)
                    ClearPedTasksImmediately(clonePed)
                    ResetPedMovementClipset(clonePed, 0.0)
                end
            end)
        end
        return
    end

    -- Reset du flag pour les previews normales
    hideClonePreview = false

    -- Normal human emote preview
    SetEntityVisible(clonePed, true)
    ClearPedTasksImmediately(clonePed)
    ResetPedMovementClipset(clonePed, 0.0)
    ClearFacialIdleAnimOverride(clonePed)


    -- Hide clonePed2 by default
    if clonePed2 and DoesEntityExist(clonePed2) then
        SetEntityVisible(clonePed2, false)
        ClearPedTasksImmediately(clonePed2)
    end

    zoom = (data[3] == "expresion")

    previewMode = true

    if data[3] == "expresion" and data[2] ~= "aucun" then
        PlayExpression(clonePed, data[2])
    else

        -- Check if this is a shared emote
        local isShared = RP.Shared and RP.Shared[emoteName]

        -- Vérifier dans quelle table RP l'emote existe

        if RP.Shared and RP.Shared[emoteName] then
            -- Activer le décalage vers la gauche pour voir les 2 personnages
            isSharedPreview = true

            local sharedData = RP.Shared[emoteName]
            local targetEmoteName = sharedData[4] -- The target emote name (e.g., "handshake2" for "handshake")

            -- Detach clonePed2 d'une éventuelle preview précédente avant de reconfigurer
            if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
                DetachEntity(clonePed2, true, false)
                clonePed2Attached = false
            end

            -- Capture les AnimationOptions pour positionner clonePed2 comme dans le vrai event :
            -- target.AnimationOptions positionne le target relatif au source (priorité), sinon source.AnimationOptions
            local targetData = targetEmoteName and RP.Shared[targetEmoteName]
            sharedPreviewOptions = (targetData and targetData.AnimationOptions)
                or (sharedData.AnimationOptions)
                or nil

            -- Show and animate clonePed2 for shared emote preview
            if clonePed2 and DoesEntityExist(clonePed2) and targetEmoteName then
                SetEntityVisible(clonePed2, true)

                -- Play the main emote on clonePed1 (directly from RP.Shared data)
                local dict1 = sharedData[1]
                local anim1 = sharedData[2]

                if dict1 and anim1 then
                    RequestAnimDict(dict1)
                    local timeout1 = 0
                    while not HasAnimDictLoaded(dict1) and timeout1 < 100 do
                        Wait(10)
                        timeout1 = timeout1 + 1
                    end

                    if HasAnimDictLoaded(dict1) then
                        local flags1 = 1 -- Loop
                        if sharedData.AnimationOptions and sharedData.AnimationOptions.EmoteLoop then
                            flags1 = 1
                        end
                        TaskPlayAnim(clonePed, dict1, anim1, 2.0, 2.0, -1, flags1, 0, false, false, false)
                    end
                end

                -- Play the target emote on clonePed2
                if RP.Shared[targetEmoteName] then
                    local targetData = RP.Shared[targetEmoteName]
                    local dict2 = targetData[1]
                    local anim2 = targetData[2]

                    if dict2 and anim2 then
                        RequestAnimDict(dict2)
                        local timeout2 = 0
                        while not HasAnimDictLoaded(dict2) and timeout2 < 100 do
                            Wait(10)
                            timeout2 = timeout2 + 1
                        end

                        if HasAnimDictLoaded(dict2) then
                            local flags2 = 1 -- Loop
                            if targetData.AnimationOptions and targetData.AnimationOptions.EmoteLoop then
                                flags2 = 1
                            end
                            TaskPlayAnim(clonePed2, dict2, anim2, 2.0, 2.0, -1, flags2, 0, false, false, false)
                        end
                    end
                end
            else
                -- No target emote, just play the main one directly
                local dict1 = sharedData[1]
                local anim1 = sharedData[2]

                if dict1 and anim1 then
                    RequestAnimDict(dict1)
                    local timeout1 = 0
                    while not HasAnimDictLoaded(dict1) and timeout1 < 100 do
                        Wait(10)
                        timeout1 = timeout1 + 1
                    end

                    if HasAnimDictLoaded(dict1) then
                        TaskPlayAnim(clonePed, dict1, anim1, 2.0, 2.0, -1, 1, 0, false, false, false)
                    end
                end
            end
        else
            -- Regular emote - désactiver le décalage
            isSharedPreview = false
            isWalkPreview = false
            sharedPreviewOptions = nil
            if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
                DetachEntity(clonePed2, true, false)
                clonePed2Attached = false
            end
            EmoteCommandStart(data[1], clonePed)
        end
    end
end)

RegisterNUICallback("nui:newanimation:stopPreview", function(_, cb)
    cb("ok")

    -- Annuler toute preview en cours
    currentPreviewId = currentPreviewId + 1
    hideClonePreview = true
    isSharedPreview = false
    isWalkPreview = false
    sharedPreviewOptions = nil
    if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
        DetachEntity(clonePed2, true, false)
        clonePed2Attached = false
    end

    -- Cancel les PlayAnimation en cours sur les clones
    if clonePed then
        lastEmote[clonePed] = nil
        currentAction[clonePed] = nil
    end
    if clonePed2 then
        lastEmote[clonePed2] = nil
        currentAction[clonePed2] = nil
    end

    -- Nettoyage complet
    CleanupAllPreviews()

    if clonePed and DoesEntityExist(clonePed) then
        ResetPedMovementClipset(clonePed, 0.0)
        ClearFacialIdleAnimOverride(clonePed)
    end

    previewMode = false
end)

RegisterNUICallback("nui:newanimation:cancel", function(_, cb)
    cb("ok")
    if (lastAnimation and lastAnimation[VFW.PlayerData.ped] ~= nil) or lastEmote[VFW.PlayerData.ped] ~= nil then
        -- Cancel via server to propagate to shared emote partner
        TriggerServerEvent("vfw:newanim:cancelSharedAnim")
    end
end)

RegisterNUICallback("nui:newanimation:resetwalk", function(_, cb)
    cb("ok")
    ResetPedMovementClipset(VFW.PlayerData.ped, 0.0)
    DeleteResourceKvp("walkstyle")
    VFW.ShowNotification({
        type = 'VERT',
        content = 'Style de marche réinitialisé'
    })
end)


RegisterCommand("setwalkstyle", function(_, args)
    if IsPlayerInMugshot() then return end
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les styles de marche sont désactivés pendant les TIG"
        })
        return
    end

    if #args < 1 then
        return
    end

    local walkStyle = string.lower(args[1])
    PlayWalk(VFW.PlayerData.ped, walkStyle)

    VFW.ShowNotification({
        type = 'VERT',
        content = 'Style de marche appliqué'
    })
end, false)


RegisterCommand("playemote", function(_, args)
    if IsPlayerInMugshot() then return end
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées pendant les TIG"
        })
        return
    end
    if LocalPlayer.state.isCuffed then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées quand vous êtes menotté"
        })
        return
    end

    if #args < 1 then
        return
    end

    local emoteName = string.lower(args[1])
    EmoteCommandStart(emoteName, VFW.PlayerData.ped, nil)
    TriggerServerEvent("vfw:newanim:sync", emoteName)
end, false)


RegisterCommand("e", function(_, args)
    if IsPlayerInMugshot() then return end
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées pendant les TIG"
        })
        return
    end
    if LocalPlayer.state.isCuffed then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées quand vous êtes menotté"
        })
        return
    end

    if #args < 1 then
        return
    end

    local emoteName = string.lower(args[1])
    EmoteCommandStart(emoteName, VFW.PlayerData.ped, nil)
    TriggerServerEvent("vfw:newanim:sync", emoteName)
end, false)

VFW.AddChatSuggestion('/e', 'Jouer une emote', {
    { name = "emote", help = "Nom de l'emote (ex: wave, sit, dance)" }
})


RegisterCommand("cancelemote", function()
    if IsPlayerInMugshot() then return end
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées pendant les TIG"
        })
        return
    end

    -- Cancel via server to propagate to shared emote partner
    TriggerServerEvent("vfw:newanim:cancelSharedAnim")
end, false)


RegisterCommand("resetwalkstyle", function()
    ResetWalk(VFW.PlayerData.ped)

    VFW.ShowNotification({
        type = 'VERT',
        content = 'Style de marche réinitialisé'
    })
end, false)


-- Keybind X pour annuler l'animation en vehicule
VFW.RegisterInput("cancelAnimInVehicle", "Annuler animation (vehicule)", "keyboard", "X", function()
    -- Ne fonctionne que si le joueur est dans un vehicule
    if not VFW.PlayerData.vehicle then
        return
    end

    local ped = VFW.PlayerData.ped

    -- Ne rien faire si pas d'emote active
    if not HasActiveEmote(ped) then
        return
    end

    -- Cancel via server to propagate to shared emote partner
    TriggerServerEvent("vfw:newanim:cancelSharedAnim")
end)

--- VFW.CopyAnimation
--- Copies the animation from another player
---@param targetPlayerId number Server ID of the target player
function VFW.CopyAnimation(targetPlayerId)
    if IsPlayerInMugshot() then return end
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les emotes sont désactivées pendant les TIG"
        })
        return
    end

    -- Get the animation name from the server
    local animName = TriggerServerCallback("vfw:newanim:copy", targetPlayerId)

    if not animName then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Le joueur ne fait aucune animation"
        })
        return
    end

    local animNameLower = string.lower(animName)

    -- Check if it's a synchronized animation
    local isSharedAnim = false
    if RP.Shared and RP.Shared[animNameLower] then
        isSharedAnim = true
    end

    -- If it's a shared animation, use the shared system
    if isSharedAnim then
        emoteSelect = true
        EmoteCommandStart(animNameLower, VFW.PlayerData.ped, true)
        VFW.ShowNotification({
            type = 'INFO',
            content = "Sélectionnez un joueur pour l'animation partagée"
        })
    else
        -- Regular animation, just play it
        EmoteCommandStart(animNameLower, VFW.PlayerData.ped, false)
        TriggerServerEvent("vfw:newanim:sync", animNameLower)
        VFW.ShowNotification({
            type = 'VERT',
            content = "Animation copiée"
        })
    end
end

-- Fonction pour nettoyer le menu emote (preview + fermeture)
local function CleanupEmoteMenu()
    -- Annuler toute preview en cours
    currentPreviewId = currentPreviewId + 1
    isSharedPreview = false
    isWalkPreview = false
    sharedPreviewOptions = nil
    if clonePed2Attached and clonePed2 and DoesEntityExist(clonePed2) then
        DetachEntity(clonePed2, true, false)
        clonePed2Attached = false
    end

    -- Nettoyage complet
    CleanupAllPreviews()

    if clonePed and DoesEntityExist(clonePed) then
        DeletePed(clonePed)
        clonePed = nil
    end
    if clonePed2 and DoesEntityExist(clonePed2) then
        DeletePed(clonePed2)
        clonePed2 = nil
    end

    if open then
        open = false
        VFW.Nui.newanimation(false)
    end
    previewMode = false
end

-- Nettoyage automatique quand le joueur meurt
AddEventHandler("vfw:onPlayerDeath", CleanupEmoteMenu)

-- Alternative: écouter le statebag de mort si l'event n'existe pas
AddStateBagChangeHandler("dead", "player:" .. GetPlayerServerId(PlayerId()), function(_, _, value)
    if value == true then
        CleanupEmoteMenu()
    end
end)

