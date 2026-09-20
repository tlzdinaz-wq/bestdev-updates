---@meta _
---@diagnostic disable: duplicate-doc-field

while not VFW do Wait(100) end
while not VFW.PlayerLoaded do Wait(100) end

local accountType = 1
local isBankingOpen = false
local currentAtmEntity = nil
local savedPlayerPos = nil
local savedPlayerHeading = nil

-- Variables pour le braquage ATM
local isRobbingATM = false
local robberyAtmEntity = nil
local robberySavedPos = nil
local robberySavedHeading = nil

-- Variables pour la caméra fixe
local atmCamera = nil

-- Cache pour la vérification des items ATM (éviter callback serveur chaque frame)
local hackItemCache = { hasItem = false, method = nil, timestamp = 0 }
local HACK_ITEM_CACHE_DURATION = 2000 -- 2 secondes

--- Vérifie si le joueur possède un outil de braquage ATM (via callback serveur avec cache)
--- @return boolean
local function HasATMHackItem()
    local currentTime = GetGameTimer()
    if (currentTime - hackItemCache.timestamp) > HACK_ITEM_CACHE_DURATION then
        local result, method = TriggerServerCallback("core:atm:hasHackItem")
        hackItemCache = { hasItem = result or false, method = method, timestamp = currentTime }
    end
    return hackItemCache.hasItem
end

-- Fonction pour créer une caméra fixe sur l'ATM
local function CreateATMCamera(atmEntity)
    if atmCamera then
        DestroyCam(atmCamera, false)
        atmCamera = nil
    end

    local atmCoords = GetEntityCoords(atmEntity)
    local atmHeading = GetEntityHeading(atmEntity)

    -- Position de la caméra : en plongée dans le dos du joueur
    -- Le joueur est à 0.8m devant l'ATM, la caméra est à ~1.5m (légèrement derrière lui) et en hauteur
    local rad = math.rad(atmHeading)
    local camOffsetX = math.sin(rad) * 1.5
    local camOffsetY = math.cos(rad) * 1.5
    local camPos = vector3(atmCoords.x - camOffsetX, atmCoords.y - camOffsetY, atmCoords.z + 2.3)

    -- Point à regarder : vers l'ATM (en bas) pour l'effet plongée
    local lookAtPos = vector3(atmCoords.x, atmCoords.y, atmCoords.z + 0.7)

    atmCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(atmCamera, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(atmCamera, lookAtPos.x, lookAtPos.y, lookAtPos.z)
    SetCamFov(atmCamera, 55.0)
    SetCamActive(atmCamera, true)
    RenderScriptCams(true, false, 0, true, true)
end

-- Fonction pour détruire la caméra fixe
local function DestroyATMCamera()
    if atmCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(atmCamera, false)
        atmCamera = nil
    end
end

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

-- Fonction pour obtenir la position face à l'ATM
local function GetPositionFacingATM(atmEntity)
    local atmCoords = GetEntityCoords(atmEntity)
    local atmHeading = GetEntityHeading(atmEntity)

    -- Utiliser GetOffsetFromEntityInWorldCoords pour une position précise
    -- L'ATM heading pointe vers le mur, donc Y négatif = devant l'écran
    -- X = 0 pour être centré, Y = -0.9 pour être devant, Z = 0 pour même hauteur
    local targetPos = GetOffsetFromEntityInWorldCoords(atmEntity, 0.0, -0.9, 0.0)

    -- Obtenir le Z du sol à la position cible (évite de tomber dans le sol)
    local targetZ = GetSafeGroundZ(targetPos.x, targetPos.y, atmCoords.z)

    local playerPos = vector3(targetPos.x, targetPos.y, targetZ)
    -- Le joueur doit faire FACE à l'ATM (même direction que le heading de l'ATM)
    local playerHeading = atmHeading

    return playerPos, playerHeading
end

-- Fonction pour démarrer l'animation de carte bancaire
local function StartATMAnimation()
    local playerPed = PlayerPedId()

    -- Charger le dictionnaire d'animation
    local animDict = "amb@prop_human_atm@male@idle_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    -- Jouer l'animation (idle devant ATM)
    TaskPlayAnim(playerPed, animDict, "idle_a", 2.0, 2.0, -1, 49, 0, false, false, false)
end

-- Fonction pour arrêter l'animation
local function StopATMAnimation()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
end

-- Fonction pour démarrer l'animation de hacking (debout avec tablette - même que /e tablet)
local function StartHackingAnimation()
    local playerPed = PlayerPedId()

    -- Animation identique à /e tablet
    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    local animName = "base"
    local animFlag = 1 | 8 | 16 | 32 | 1048576 -- Loop + upper body

    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(playerPed, animDict, animName, 8.0, -4.0, -1, animFlag, 0, false, false, false)
    end
end

-- Fonction pour arrêter l'animation de hacking
local function StopHackingAnimation()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    ClearPedTasksImmediately(playerPed)
end

-- Fonction pour obtenir la position de hacking (devant l'ATM)
local function GetHackingPositionFacingATM(atmEntity)
    local atmCoords = GetEntityCoords(atmEntity)
    local atmHeading = GetEntityHeading(atmEntity)

    -- Utiliser GetOffsetFromEntityInWorldCoords pour une position précise
    -- L'ATM heading pointe vers le mur, donc Y négatif = devant l'écran
    -- X = 0 pour être centré, Y = -0.9 pour être devant, Z = 0 pour même hauteur
    local targetPos = GetOffsetFromEntityInWorldCoords(atmEntity, 0.0, -0.9, 0.0)

    -- Obtenir le Z du sol à la position cible (évite de tomber dans le sol)
    local targetZ = GetSafeGroundZ(targetPos.x, targetPos.y, atmCoords.z)

    local playerPos = vector3(targetPos.x, targetPos.y, targetZ)
    -- Le joueur doit faire FACE à l'ATM (même direction que le heading de l'ATM)
    local playerHeading = atmHeading

    return playerPos, playerHeading
end

local function OpenATMInterface(atmEntity)
    if isBankingOpen then return end

    -- Fermer le context menu s'il est ouvert et attendre qu'il soit fermé
    if VFW.CloseContextMenu then
        VFW.CloseContextMenu()
        -- Attendre que le context menu soit complètement fermé et que le focus NUI soit libéré
        Wait(150)
    end

    local playerPed = PlayerPedId()

    -- Sauvegarder la position actuelle du joueur
    savedPlayerPos = GetEntityCoords(playerPed)
    savedPlayerHeading = GetEntityHeading(playerPed)
    currentAtmEntity = atmEntity

    -- Obtenir la position face à l'ATM
    local targetPos, targetHeading = GetPositionFacingATM(atmEntity)

    -- Fade out AVANT la téléportation pour masquer le TP
    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do
        Wait(10)
    end

    -- Téléporter le joueur face à l'ATM
    SetEntityCoords(playerPed, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
    SetEntityHeading(playerPed, targetHeading)

    Wait(100)

    -- Freeze le joueur
    FreezeEntityPosition(playerPed, true)

    -- Démarrer l'animation
    StartATMAnimation()

    -- Fade in après le positionnement
    DoScreenFadeIn(300)
    while not IsScreenFadedIn() do
        Wait(10)
    end

    isBankingOpen = true

    -- Safety timeout: unfreeze player if banking doesn't open properly after 10 seconds
    local openTime = GetGameTimer()
    CreateThread(function()
        Wait(10000) -- 10 second timeout
        if isBankingOpen and currentAtmEntity == atmEntity then
            -- Check if player is still frozen after 10 seconds
            local currentTime = GetGameTimer()
            if (currentTime - openTime) >= 10000 then

                local ped = PlayerPedId()
                FreezeEntityPosition(ped, false)
                StopATMAnimation()
            end
        end
    end)

    -- Ouvrir l'interface bancaire
    Web.Banking(true)

    -- S'assurer que le focus NUI est bien actif après tout
    VFW.Nui.Focus(true, false)
end

-- Fonction pour fermer l'interface bancaire (ATM ou guichet)
local function CloseBankingInterface()
    if not isBankingOpen then return end

    local playerPed = PlayerPedId()

    -- Si on était sur un ATM, arrêter l'animation et unfreeze
    if currentAtmEntity then
        StopATMAnimation()
        FreezeEntityPosition(playerPed, false)
    end

    -- Fermer l'interface
    Web.Banking(false)

    isBankingOpen = false
    currentAtmEntity = nil
    savedPlayerPos = nil
    savedPlayerHeading = nil
end

-- Alias pour compatibilité
local function CloseATMInterface()
    CloseBankingInterface()
end

RegisterNuiCallback("nui:banking:close", function(data, cb)
    CloseATMInterface()
    -- Notifier les autres scripts que le banking est fermé (pour ATM custom, etc.)
    TriggerEvent("core:banking:closed")
    cb('ok')
end)

-- Thread pour détecter la touche Escape et fermer l'interface + désactiver contrôles
CreateThread(function()
    while true do
        -- Désactivation des contrôles pour le menu banque ATM
        if isBankingOpen and currentAtmEntity then
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 30, true)  -- MoveLeftRight
            DisableControlAction(0, 31, true)  -- MoveUpDown
            DisableControlAction(0, 32, true)  -- MoveUp
            DisableControlAction(0, 33, true)  -- MoveDown
            DisableControlAction(0, 34, true)  -- MoveLeft
            DisableControlAction(0, 35, true)  -- MoveRight
            DisableControlAction(0, 36, true)  -- Duck
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 44, true)  -- Cover
            DisableControlAction(0, 37, true)  -- Select Weapon
            DisableControlAction(0, 75, true)  -- Exit Vehicle
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 264, true) -- Melee Attack 2
        end

        -- Désactivation des contrôles pour le braquage ATM
        if isRobbingATM then
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 30, true)  -- MoveLeftRight
            DisableControlAction(0, 31, true)  -- MoveUpDown
            DisableControlAction(0, 32, true)  -- MoveUp
            DisableControlAction(0, 33, true)  -- MoveDown
            DisableControlAction(0, 34, true)  -- MoveLeft
            DisableControlAction(0, 35, true)  -- MoveRight
            DisableControlAction(0, 36, true)  -- Duck
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 44, true)  -- Cover
            DisableControlAction(0, 37, true)  -- Select Weapon
            DisableControlAction(0, 75, true)  -- Exit Vehicle
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 264, true) -- Melee Attack 2
        end

        -- Fermer avec Escape (fonctionne pour ATM et guichet)
        if isBankingOpen then
            if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 322) then
                CloseBankingInterface()
            end
        end

        Wait(0)
    end
end)

RegisterNuiCallback("nui:banking:withdraw", function(data, cb)
    local amount = tonumber(data)

    if amount then
        local valide = TriggerServerCallback('vfw:banking:withdraw', amount, accountType)

        if valide then
            Wait(200)
            Web.Banking(true)
        end
    end
    cb('ok')
end)

RegisterNuiCallback("nui:banking:transfer", function(data, cb)
    local amount = tonumber(data.montant)
    local target = data.iban

    if amount and target then
        local valide = TriggerServerCallback('vfw:banking:transfer', amount, target, accountType)

        if valide then
            Wait(200)
            Web.Banking(true)
        end
    else
        cb(false)
    end
end)

RegisterNuiCallback("nui:banking:deposit", function(data, cb)
    local amount = tonumber(data)

    if amount then
        local valide = TriggerServerCallback('vfw:banking:deposit', amount, accountType)

        if valide then
            Wait(200)
            Web.Banking(true)
        end
    end
    cb('ok')
end)

RegisterNuiCallback("nui:banking:account", function(data, cb)
    if data == "business" then
        accountType = 2
    else
        accountType = 1
    end

    Web.Banking(true)
    cb('ok')
end)

RegisterNuiCallback("nui:banking:payInvoice", function(data, cb)
    TriggerServerEvent("vfw:invoice:pay", data.invoiceId, data.method)
    Wait(500)
    Web.Banking(true)
    cb({ ok = true })
end)

Web.Banking = function(visible)
    if not visible then
        -- Fermeture: envoyer visible = false et retirer le focus
        SendNUIMessage({
            action = "nui:banking:visible",
            data = { visible = false }
        })
        VFW.Nui.Focus(false, false)
        isBankingOpen = false
        return
    end

    isBankingOpen = true

    local cash = 0
    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.name == "money" then
            cash = cash + (tonumber(item.count) or 0)
        end
    end

    local accountData = TriggerServerCallback("vfw:banking:getMyAccount")
    local societyAccountData = TriggerServerCallback("vfw:banking:getMySocietyAccount")
    local societyMoney = 0

    if (accountType == 2) then
        societyMoney = societyAccountData.bank
    end

    -- 4. Envoyer les données complètes
    SendNUIMessage({
        action = "nui:banking:data",
        data = {
            navBar = {
                visible = true,
                name = (VFW.PlayerData.firstName .. " " .. VFW.PlayerData.lastName),
                jobLabel = VFW.PlayerData.job.label,
                isBoss = (VFW.PlayerData.job.grade == 4) or false,
                mugshot = VFW.PlayerData.mugshot,
                current = accountType == 2 and societyAccountData.iban or accountData.iban,
                type = accountType == 1 and "player" or "",
                accounts = {
                    societyAccountData
                }
            },
            myAccount = {
                visible = true,
                type = "account",
                society = (accountType == 2) or false,
                bank = (accountType == 1) and accountData.bank or (accountType == 2 and (societyMoney)),
                cash = cash,
                card = {
                    number = (accountType == 1) and accountData.iban or (accountType == 2 and societyAccountData.iban or ""),
                    data = (accountType == 1) and ("07/27") or (accountType == 2 and ("07/28")),
                    name = (accountType == 1) and (VFW.PlayerData.firstName .. " " .. VFW.PlayerData.lastName) or (accountType == 2 and societyAccountData.label or "")
                },
                maxAmount = "999999999", -- Pas de limite de dépôt
                isVip = false,
                isVipPlus = false,
            },
            statistiques = {
                visible = true,
                history = (accountType == 1) and (accountData.stats or {}) or (societyAccountData and societyAccountData.stats or {})
            },
            transfer = {
                visible = true,
            },
            transactions = {
                visible = true,
                history = (accountType == 1) and accountData.transactions or (accountType == 2 and societyAccountData.transactions or {})
            },
            invoices = TriggerServerCallback("vfw:getInvoices") or {}
        }
    })

    -- 2. Afficher l'UI
    SendNUIMessage({
        action = "nui:banking:visible",
        data = { visible = true }
    })

    VFW.Nui.Focus(true, false)
end

local atmModels = {
    [joaat("prop_atm_01")] = true,
    [joaat("prop_atm_02")] = true,
    [joaat("prop_atm_03")] = true,
    [joaat("prop_fleeca_atm")] = true
}

local atmPoints = {} -- { [posKey] = { zone = zone, contextId = contextId } }

-- Helper to generate a unique key from position
local function GetPosKey(pos)
    return string.format("%.1f_%.1f_%.1f", pos.x, pos.y, pos.z)
end

-- Fonction pour trouver l'ATM le plus proche du joueur
local function FindNearestATM(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestATM = nil
    local nearestDist = maxDistance or 3.0

    for _, entity in pairs(GetGamePool("CObject")) do
        local model = GetEntityModel(entity)
        if atmModels[model] then
            local atmCoords = GetEntityCoords(entity)
            local dist = #(playerCoords - atmCoords)
            if dist < nearestDist then
                nearestDist = dist
                nearestATM = entity
            end
        end
    end

    return nearestATM
end

--RegisterCommand("testbank", function()
--    print("^2[BANKING DEBUG] Opening banking UI...^0")
--    -- Pour le test, on ouvre sans ATM (utilise l'ancienne méthode)
--    Web.Banking(true)
--end, false)

-- Thread pour détecter les ATM et enregistrer les zones d'interaction
CreateThread(function()
    while true do
        for _, entity in pairs(GetGamePool("CObject")) do
            local model = GetEntityModel(entity)
            local objectPos = GetEntityCoords(entity)
            local posKey = GetPosKey(objectPos)

            if not atmPoints[posKey] and atmModels[model] then
                local atmPos = vector3(objectPos.x, objectPos.y, objectPos.z + 0.7)

                -- Register position for context menu (rayon 1.5m pour le clic droit)
                local contextId = VFW.ContextRegisterPosition(atmPos, 1.5)

                -- Add context menu button for ATM banking
                VFW.ContextAddPositionButton(contextId, ":money: Ouvrir le distributeur", function()
                    return #(GetEntityCoords(PlayerPedId()) - atmPos) < 2.5
                end, function()
                    local atmEntity = FindNearestATM(2.0)
                    if atmEntity then
                        OpenATMInterface(atmEntity)
                    else
                        VFW.ShowNotification({
                            type = 'ROUGE',
                            content = "ATM introuvable"
                        })
                    end
                end, {})

                -- Add context menu button for ATM robbery (visible seulement si le joueur a l'USB)
                VFW.ContextAddPositionButton(contextId, ":unlock: Braquer l'ATM", function()
                    return HasATMHackItem() and #(GetEntityCoords(PlayerPedId()) - atmPos) < 2.5
                end, function(worldPos, registeredPos)
                    if isRobbingATM then return end

                    -- Fermer le context menu et attendre qu'il soit fermé
                    if VFW.CloseContextMenu then
                        VFW.CloseContextMenu()
                        Wait(150)
                    end

                    local atmEntity = FindNearestATM(2.0)
                    if not atmEntity then
                        VFW.ShowNotification({
                            type = 'ROUGE',
                            content = "ATM introuvable"
                        })
                        return
                    end

                    local atmCoords = GetEntityCoords(atmEntity)

                    -- Forcer le networking si nécessaire (objets du mapping)
                    if not NetworkGetEntityIsNetworked(atmEntity) then
                        NetworkRegisterEntityAsNetworked(atmEntity)
                    end
                    local atmNetId = NetworkGetEntityIsNetworked(atmEntity) and NetworkGetNetworkIdFromEntity(atmEntity) or 0

                    local success, errorMsg, sessionId, hackParams = TriggerServerCallback("core:atm:StartHack", atmNetId, atmCoords)

                    if not success then
                        VFW.ShowNotification({
                            type = 'ROUGE',
                            content = errorMsg or "Impossible de pirater cet ATM"
                        })
                        return
                    end

                    local method = hackParams and hackParams.method or "usb"

                    -- Sauvegarder la position actuelle
                    local playerPed = PlayerPedId()
                    robberySavedPos = GetEntityCoords(playerPed)
                    robberySavedHeading = GetEntityHeading(playerPed)
                    robberyAtmEntity = atmEntity

                    -- Obtenir la position de hacking face à l'ATM
                    local targetPos, targetHeading = GetHackingPositionFacingATM(atmEntity)

                    -- Fade out avant téléportation
                    DoScreenFadeOut(400)
                    while not IsScreenFadedOut() do
                        Wait(10)
                    end

                    -- Téléporter le joueur
                    SetEntityCoords(playerPed, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
                    SetEntityHeading(playerPed, targetHeading)

                    Wait(100)

                    -- Freeze le joueur
                    FreezeEntityPosition(playerPed, true)

                    if method == "drill" then
                        -- Foreuse : charger anim + prop + son + particules
                        local drillDict = "anim@heists@fleeca_bank@drilling"
                        local drillPropName = "hei_prop_heist_drill"
                        local ptfxAsset = "core"
                        local drillObj = nil
                        local sparkFx = nil

                        RequestAnimDict(drillDict)
                        RequestModel(GetHashKey(drillPropName))
                        RequestNamedPtfxAsset(ptfxAsset)

                        while not HasAnimDictLoaded(drillDict) do Wait(10) end
                        while not HasModelLoaded(GetHashKey(drillPropName)) do Wait(10) end
                        while not HasNamedPtfxAssetLoaded(ptfxAsset) do Wait(10) end

                        -- Jouer l'animation
                        TaskPlayAnim(playerPed, drillDict, "drill_straight_idle", 8.0, -4.0, -1, 1, 0, false, false, false)

                        -- Attacher le prop de perceuse a la main droite
                        local drillCoords = GetEntityCoords(playerPed)
                        drillObj = VFW.OneSync.CreateObject(drillPropName, drillCoords)
                        AttachEntityToEntity(drillObj, playerPed, GetPedBoneIndex(playerPed, 0x6F06),
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            true, true, false, true, 0, true)

                        -- Particules d'etincelles sur l'ATM
                        UseParticleFxAssetNextCall(ptfxAsset)
                        sparkFx = StartParticleFxLoopedAtCoord("ent_amb_spark_lg_spk",
                            targetPos.x, targetPos.y, targetPos.z + 0.5,
                            0.0, 0.0, 0.0, 1.0, false, false, false, false)

                        -- Son de perceuse synchronise
                        if StartSyncedDrillSound then
                            StartSyncedDrillSound(vector3(targetPos.x, targetPos.y, targetPos.z))
                        end
                    else
                        -- USB : emote type (piratage)
                        EmoteCommandStart("type", playerPed, nil)
                    end

                    -- Fade in apres teleportation
                    DoScreenFadeIn(400)
                    while not IsScreenFadedIn() do
                        Wait(10)
                    end

                    isRobbingATM = true

                    if method == "drill" then
                        VFW.ShowNotification({
                            type = 'JAUNE',
                            content = "Perçage de l'ATM en cours..."
                        })

                        Wait(100)

                        -- Foreuse : progressbar 2 minutes
                        local drillSuccess = VFW.Nui.ProgressBar("Perçage de l'ATM", 120000)

                        -- Cleanup : animation, prop, particules, son
                        local ped = PlayerPedId()
                        ClearPedTasks(ped)
                        ClearPedTasksImmediately(ped)

                        if drillObj and DoesEntityExist(drillObj) then
                            DetachEntity(drillObj, true, true)
                            DeleteEntity(drillObj)
                        end
                        if sparkFx then StopParticleFxLooped(sparkFx, false) end
                        RemoveNamedPtfxAsset("core")
                        if StopSyncedDrillSound then
                            StopSyncedDrillSound()
                        end
                        RemoveAnimDict("anim@heists@fleeca_bank@drilling")
                        SetModelAsNoLongerNeeded(GetHashKey("hei_prop_heist_drill"))

                        -- Restaurer la position initiale avec fade
                        if robberySavedPos then
                            DoScreenFadeOut(400)
                            Wait(450)

                            SetEntityCoordsNoOffset(ped, robberySavedPos.x, robberySavedPos.y, robberySavedPos.z, false, false, false)
                            if robberySavedHeading then
                                SetEntityHeading(ped, robberySavedHeading)
                            end

                            Wait(100)
                            DoScreenFadeIn(400)
                        end

                        FreezeEntityPosition(ped, false)

                        isRobbingATM = false
                        robberyAtmEntity = nil
                        robberySavedPos = nil
                        robberySavedHeading = nil

                        if drillSuccess then
                            VFW.ShowNotification({
                                type = 'VERT',
                                content = "ATM forcé ! Argent récupéré"
                            })
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Perçage interrompu"
                            })
                        end

                        TriggerServerEvent("core:atm:FinishHack", drillSuccess, sessionId)
                    else
                        VFW.ShowNotification({
                            type = 'JAUNE',
                            content = "Début du piratage de l'ATM..."
                        })

                        Wait(100)

                        -- USB : mini-jeu hacking
                        StartHacking('circuit', 'medium', nil, function(hackSuccess)
                            local ped = PlayerPedId()
                            StopHackingAnimation()

                            if robberySavedPos then
                                DoScreenFadeOut(400)
                                Wait(450)

                                SetEntityCoordsNoOffset(ped, robberySavedPos.x, robberySavedPos.y, robberySavedPos.z, false, false, false)
                                if robberySavedHeading then
                                    SetEntityHeading(ped, robberySavedHeading)
                                end

                                Wait(100)
                                DoScreenFadeIn(400)
                            end

                            FreezeEntityPosition(ped, false)

                            isRobbingATM = false
                            robberyAtmEntity = nil
                            robberySavedPos = nil
                            robberySavedHeading = nil

                            if hackSuccess then
                                VFW.ShowNotification({
                                    type = 'VERT',
                                    content = "Piratage réussi ! Argent récupéré"
                                })
                            else
                                VFW.ShowNotification({
                                    type = 'ROUGE',
                                    content = "Piratage échoué"
                                })
                            end

                            TriggerServerEvent("core:atm:FinishHack", hackSuccess, sessionId)
                        end)
                    end
                end, {})

                -- Create interaction zone (E key) - rayon 1m pour "Appuyer sur E"
                local zone = Worlds.Zone.Create(atmPos, 1.0, true, function()
                    VFW.RegisterInteraction("atm", function()
                        local atmEntity = FindNearestATM(2.0)
                        if atmEntity then
                            OpenATMInterface(atmEntity)
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "ATM introuvable"
                            })
                        end
                    end)
                end, function()
                    VFW.RemoveInteraction("atm")
                    accountType = 1
                end)

                atmPoints[posKey] = {
                    zone = zone,
                    contextId = contextId,
                    pos = atmPos
                }
            end
        end

        Wait(5000)
    end
end)

-- Thread pour les blips ATM dynamiques (apparaissent à proximité)
local ATM_BLIP_RANGE = 150.0
local activeAtmBlips = {} -- { [posKey] = blipHandle }

CreateThread(function()
    while true do
        Wait(1000)

        local playerPos = GetEntityCoords(PlayerPedId())

        for posKey, data in pairs(atmPoints) do
            local dist = #(playerPos - data.pos)

            if dist < ATM_BLIP_RANGE and not activeAtmBlips[posKey] then
                local blip = AddBlipForCoord(data.pos.x, data.pos.y, data.pos.z)
                SetBlipSprite(blip, 207)
                SetBlipScale(blip, 0.5)
                SetBlipColour(blip, 3)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentSubstringPlayerName("ATM")
                EndTextCommandSetBlipName(blip)
                activeAtmBlips[posKey] = blip
            elseif dist >= ATM_BLIP_RANGE and activeAtmBlips[posKey] then
                RemoveBlip(activeAtmBlips[posKey])
                activeAtmBlips[posKey] = nil
            end
        end
    end
end)
