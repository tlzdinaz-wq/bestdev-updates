-- ============================================
-- ATM CONTEXT MENU - Props ATM existants + ATM Customs
-- Utilise les fonctions du système Banking (015_Banking)
-- ============================================

-- COMMANDE SUPPRIMÉE : /debugatm

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function hasItem(itemName)
    if not VFW or not VFW.PlayerData or not VFW.PlayerData.inventory then
        return false
    end
    for _, item in pairs(VFW.PlayerData.inventory) do
        if item.name == itemName and item.count and item.count > 0 then
            return true
        end
    end
    return false
end

-- ============================================
-- FONCTIONS PARTAGÉES (pour ATM props ET customs)
-- ============================================

-- Variable pour sauvegarder la position du joueur (ATM customs)
local savedPlayerPosATM = nil
local savedPlayerHeadingATM = nil
local isCustomATMOpen = false

-- Fonction helper pour obtenir le Z du sol à une position donnée
local function GetSafeGroundZ(x, y, z)
    local groundZ = z
    local found, resultZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if found then
        groundZ = resultZ
    else
        -- Essayer avec une hauteur plus grande si le premier essai échoue
        found, resultZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
        if found then
            groundZ = resultZ
        end
    end
    return groundZ
end

--- Pour les ATM custom créés via le builder:
--- L'admin se place EXACTEMENT où le joueur doit être téléporté
--- Les coordonnées stockées sont la position du joueur, pas de l'ATM
--- Le heading stocké est le heading du joueur (direction où il regarde)
--- @param atmCoords vector3 Coordonnées où le joueur doit être TP (position de l'admin lors de la création)
--- @param atmHeading number Heading du joueur (direction où il doit regarder)
local function GetPositionFacingATMCustom(atmCoords, atmHeading)
    -- Utiliser directement les coordonnées stockées (position de l'admin)
    -- avec GetSafeGroundZ pour s'assurer que le Z est correct
    local targetZ = GetSafeGroundZ(atmCoords.x, atmCoords.y, atmCoords.z)

    local playerPos = vector3(atmCoords.x, atmCoords.y, targetZ)
    local playerHeading = atmHeading

    return playerPos, playerHeading
end

--- Ouvre l'interface bancaire ATM (utilise le système Banking existant)
--- @param atmCoords vector3 Coordonnées de l'ATM
--- @param atmHeading number Heading de l'ATM
function OpenATMBankInterface(atmCoords, atmHeading)
    if isCustomATMOpen then return end

    -- Fermer le context menu d'abord et attendre qu'il soit fermé
    if VFW.CloseContextMenu then
        VFW.CloseContextMenu()
        Wait(150)
    end

    local playerPed = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedPlayerPosATM = GetEntityCoords(playerPed)
    savedPlayerHeadingATM = GetEntityHeading(playerPed)

    -- Calculer la position face à l'ATM
    local targetPos, targetHeading = GetPositionFacingATMCustom(atmCoords, atmHeading)

    -- Fade out avant téléportation
    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do Wait(10) end

    -- Téléporter le joueur face à l'ATM
    SetEntityCoords(playerPed, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
    SetEntityHeading(playerPed, targetHeading)

    Wait(100)

    -- Freeze le joueur
    FreezeEntityPosition(playerPed, true)

    -- Animation ATM
    local animDict = "amb@prop_human_atm@male@idle_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end
    TaskPlayAnim(playerPed, animDict, "idle_a", 2.0, 2.0, -1, 49, 0, false, false, false)

    -- Fade in
    DoScreenFadeIn(300)
    while not IsScreenFadedIn() do Wait(10) end

    isCustomATMOpen = true

    -- Utiliser Web.Banking si disponible
    if Web and Web.Banking then
        Web.Banking(true)
        Wait(50)
        VFW.Nui.Focus(true)
    else
        -- Si pas de banking, unfreeze et restaurer
        FreezeEntityPosition(playerPed, false)
        ClearPedTasks(playerPed)
        isCustomATMOpen = false
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Interface ATM bancaire non disponible"
        })
    end
end

--- Ferme l'interface ATM custom et restaure la position
function CloseATMBankInterface()
    if not isCustomATMOpen then return end

    local playerPed = PlayerPedId()

    -- Arrêter l'animation
    ClearPedTasks(playerPed)

    -- Unfreeze
    FreezeEntityPosition(playerPed, false)

    isCustomATMOpen = false
    savedPlayerPosATM = nil
    savedPlayerHeadingATM = nil
end

-- Event pour fermer l'ATM custom quand le banking se ferme
-- (Le callback principal est dans banking.lua, on écoute juste l'event)
RegisterNetEvent("core:banking:closed")
AddEventHandler("core:banking:closed", function()
    if isCustomATMOpen then
        local playerPed = PlayerPedId()
        ClearPedTasks(playerPed)
        FreezeEntityPosition(playerPed, false)
        isCustomATMOpen = false
        savedPlayerPosATM = nil
        savedPlayerHeadingATM = nil
    end
end)

--- Effet jackpot (billets qui volent)
--- @param atmCoords vector3 Coordonnées de l'ATM
--- @param atmHeading number Heading de l'ATM
function PlayJackpotEffectsAtCoords(atmCoords, atmHeading)
    PlaySoundFromCoord(-1, "Alarm_Warning", atmCoords.x, atmCoords.y, atmCoords.z, "DLC_HEIST_HACKING_SNAKE_SOUNDS", true, 30.0, false)

    local ptfxDict = "core"
    RequestNamedPtfxAsset(ptfxDict)
    while not HasNamedPtfxAssetLoaded(ptfxDict) do Wait(10) end

    UseParticleFxAssetNextCall(ptfxDict)
    local sparkEffect = StartParticleFxLoopedAtCoord("ent_amb_spark_lg_spk", atmCoords.x, atmCoords.y, atmCoords.z + 0.8, 0.0, 0.0, 0.0, 1.0, false, false, false, false)

    local moneyModel = GetHashKey("prop_money_bag_01")
    RequestModel(moneyModel)
    while not HasModelLoaded(moneyModel) do Wait(10) end

    local forwardX = -math.sin(math.rad(atmHeading))
    local forwardY = math.cos(math.rad(atmHeading))
    local moneyProps = {}

    for i = 1, 8 do
        Wait(150)
        local prop = VFW.OneSync.CreateObject(moneyModel, vector3(atmCoords.x + forwardX * 0.5, atmCoords.y + forwardY * 0.5, atmCoords.z + 0.6))
        if DoesEntityExist(prop) then
            ApplyForceToEntity(prop, 1, forwardX * 2.0, forwardY * 2.0, 3.0 + math.random() * 2.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
            table.insert(moneyProps, prop)
        end
    end

    SetModelAsNoLongerNeeded(moneyModel)

    SetTimeout(3000, function()
        if sparkEffect then StopParticleFxLooped(sparkEffect, false) end
        RemoveNamedPtfxAsset(ptfxDict)
    end)

    SetTimeout(15000, function()
        for _, prop in ipairs(moneyProps) do
            if DoesEntityExist(prop) then DeleteEntity(prop) end
        end
    end)
end

--- Lance le hack d'un ATM (utilise StartHacking du système existant)
--- @param atmNetId string|number NetId ou identifiant de l'ATM
--- @param atmCoords vector3 Coordonnées de l'ATM
--- @param atmHeading number Heading de l'ATM
function StartATMHack(atmNetId, atmCoords, atmHeading)
    -- Fermer le context menu d'abord
    if VFW.CloseContextMenu then
        VFW.CloseContextMenu()
        Wait(100)
    end

    -- Vérifier si StartHacking existe (système de hacking)
    if not StartHacking then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Système de hacking non disponible"
        })
        return
    end

    -- Demander au serveur de démarrer le hack
    local success, errorMsg, sessionId, hackParams = TriggerServerCallback("core:atm:StartHack", atmNetId, atmCoords)

    if not success then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = errorMsg or "Impossible de pirater cet ATM"
        })
        return
    end

    local method = hackParams and hackParams.method or "usb"
    local ped = PlayerPedId()
    local isJackpot = hackParams and hackParams.jackpot or false

    if method == "drill" then
        -- Foreuse : charger anim + prop + son + particules
        local drillDict = "anim@heists@fleeca_bank@drilling"
        local drillPropName = "hei_prop_heist_drill"
        local drillHash = GetHashKey(drillPropName)
        local ptfxAsset = "core"
        local drillObj = nil
        local sparkFx = nil
        local cleanupDone = false

        -- Demande le contrôle réseau d'une entité, indispensable avant DeleteEntity
        -- sur un objet networked dont on n'est plus owner.
        local function requestControl(entity)
            if not entity or not DoesEntityExist(entity) then return false end
            if NetworkHasControlOfEntity(entity) then return true end
            NetworkRequestControlOfEntity(entity)
            local deadline = GetGameTimer() + 1000
            while not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
                NetworkRequestControlOfEntity(entity)
                Wait(0)
            end
            return NetworkHasControlOfEntity(entity)
        end

        local function forceDeleteDrill(obj)
            if not obj or not DoesEntityExist(obj) then return end
            requestControl(obj)
            SetEntityAsMissionEntity(obj, true, true)
            if IsEntityAttached(obj) then
                DetachEntity(obj, true, true)
            end
            local handle = obj
            DeleteEntity(handle)
            if DoesEntityExist(handle) then
                DeleteObject(handle)
            end
        end

        -- Sweep des foreuses orphelines attachées à un ped donné (utile après
        -- respawn : le `ped` capturé n'est plus valide, il faut aussi vérifier
        -- le ped courant).
        local function sweepAttachedDrills(targetPed)
            if not targetPed or not DoesEntityExist(targetPed) then return end
            for _, obj in ipairs(GetGamePool('CObject')) do
                if DoesEntityExist(obj) and GetEntityModel(obj) == drillHash and IsEntityAttachedToEntity(obj, targetPed) then
                    forceDeleteDrill(obj)
                end
            end
        end

        local function cleanupDrill()
            if cleanupDone then return end
            cleanupDone = true

            local currentPed = PlayerPedId()
            ClearPedTasks(currentPed)
            ClearPedTasksImmediately(currentPed)
            if ped ~= currentPed and DoesEntityExist(ped) then
                ClearPedTasks(ped)
            end

            forceDeleteDrill(drillObj)
            drillObj = nil

            -- Fallback : props attachés au ped initial ET au ped courant
            -- (couvre le cas du respawn et celui d'une perte d'ownership).
            sweepAttachedDrills(ped)
            sweepAttachedDrills(currentPed)

            if sparkFx then StopParticleFxLooped(sparkFx, false); sparkFx = nil end
            RemoveNamedPtfxAsset(ptfxAsset)
            if StopSyncedDrillSound then
                StopSyncedDrillSound()
            end
            RemoveAnimDict(drillDict)
            SetModelAsNoLongerNeeded(drillHash)

            -- Seconde passe différée : si la suppression a échoué (ownership
            -- non encore acquise, prop pas encore networké côté local), on
            -- réessaie à T+500ms et T+1500ms avant d'abandonner.
            CreateThread(function()
                for _, delay in ipairs({ 500, 1000 }) do
                    Wait(delay)
                    sweepAttachedDrills(ped)
                    sweepAttachedDrills(PlayerPedId())
                end
            end)
        end

        -- Watchdog : si le joueur meurt pendant le perçage, cleanup quand même.
        CreateThread(function()
            while not cleanupDone do
                if IsPedDeadOrDying(ped, true) then
                    cleanupDrill()
                    return
                end
                Wait(500)
            end
        end)

        RequestAnimDict(drillDict)
        RequestModel(drillHash)
        RequestNamedPtfxAsset(ptfxAsset)

        while not HasAnimDictLoaded(drillDict) do Wait(10) end
        while not HasModelLoaded(drillHash) do Wait(10) end
        while not HasNamedPtfxAssetLoaded(ptfxAsset) do Wait(10) end

        -- Jouer l'animation
        TaskPlayAnim(ped, drillDict, "drill_straight_idle", 8.0, -4.0, -1, 1, 0, false, false, false)

        -- Attacher le prop de perceuse a la main droite
        local drillCoords = GetEntityCoords(ped)
        drillObj = VFW.OneSync.CreateObject(drillHash, drillCoords)
        AttachEntityToEntity(drillObj, ped, GetPedBoneIndex(ped, 0x6F06),
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            true, true, false, true, 0, true)

        -- Particules d'etincelles sur l'ATM
        UseParticleFxAssetNextCall(ptfxAsset)
        sparkFx = StartParticleFxLoopedAtCoord("ent_amb_spark_lg_spk",
            atmCoords.x, atmCoords.y, atmCoords.z + 0.5,
            0.0, 0.0, 0.0, 1.0, false, false, false, false)

        -- Son de perceuse synchronise
        if StartSyncedDrillSound then
            StartSyncedDrillSound(vector3(atmCoords.x, atmCoords.y, atmCoords.z))
        end

        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Perçage de l'ATM en cours..."
        })

        Wait(100)

        -- Progressbar 2 minutes
        local drillSuccess = VFW.Nui.ProgressBar("Perçage de l'ATM", 120000)

        -- Cleanup : animation, prop, particules, son
        cleanupDrill()

        if drillSuccess then
            if isJackpot then
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "JACKPOT! L'ATM déconne et crache des billets!"
                })
                PlayJackpotEffectsAtCoords(atmCoords, atmHeading)
            else
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "ATM forcé ! Argent récupéré"
                })
            end
        else
            VFW.ShowNotification({
                type = 'ILLEGAL',
                message = "Perçage interrompu"
            })
        end

        TriggerServerEvent("core:atm:FinishHack", drillSuccess, sessionId)
    else
        -- USB : emote type + mini-jeu hacking
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Début du piratage de l'ATM..."
        })

        EmoteCommandStart("type", ped, nil)

        Wait(100)

        StartHacking('circuit', 'medium', nil, function(hackSuccess)
            EmoteCancel()
            ClearPedTasks(ped)

            if hackSuccess then
                if isJackpot then
                    VFW.ShowNotification({
                        type = 'ILLEGAL',
                        message = "JACKPOT! L'ATM déconne et crache des billets!"
                    })
                    PlayJackpotEffectsAtCoords(atmCoords, atmHeading)
                else
                    VFW.ShowNotification({
                        type = 'ILLEGAL',
                        message = "Piratage réussi ! Argent récupéré"
                    })
                end
            else
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Piratage échoué"
                })
            end

            TriggerServerEvent("core:atm:FinishHack", hackSuccess, sessionId)
        end)
    end
end

-- ============================================
-- NOTE: Les boutons pour les props ATM sont déjà enregistrés
-- dans 015_Banking/client/banking.lua via VFW.ContextRegisterPosition
-- Ce fichier fournit uniquement les fonctions partagées pour les ATM customs
-- ============================================

-- Event pour l'alerte police (jackpot)
RegisterNetEvent("core:atm:jackpotAlert")
AddEventHandler("core:atm:jackpotAlert", function(atmPos)
    print("[ATM] Jackpot alert - police jobs not configured yet")
end)
