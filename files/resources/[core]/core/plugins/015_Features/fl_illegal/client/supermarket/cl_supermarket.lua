---@meta _
---@diagnostic disable: duplicate-doc-field


local isRobbingAPU = false
local isRobbingSafe = false
local currentSupermarket = nil
local robberyBlips = {}
local apuPed = nil
local lastRobberyAttempt = 0 -- To prevent spam

local Supermarkets = {}

local SupermarketBlips = {}
local SupermarketAPUs = {}
local APURecoveryTimers = {}
local shockedAPUs = {}
local robbingAPUs = {}
local robbingSafes = {}

local SupermarketSettings = {
    InteractDistance = 3.0,
    SafeInteractDistance = 1.5,
    PoliceBlipDuration = 300000,
    APU = {
        AnimDict = "missheist_agency2ahands_up",
        AnimName = "handsup_anxious",
        RobberyTime = 45
    },
    Safe = {
        RobberyTime = 30 -- Time to empty the safe after cracking it
    }
}

-- Armes blanches autorisées pour le braquage
local MeleeWeapons = {
    [`WEAPON_KNIFE`] = true,
    [`WEAPON_NIGHTSTICK`] = true,
    [`WEAPON_HAMMER`] = true,
    [`WEAPON_BAT`] = true,
    [`WEAPON_CROWBAR`] = true,
    [`WEAPON_GOLFCLUB`] = true,
    [`WEAPON_BOTTLE`] = true,
    [`WEAPON_DAGGER`] = true,
    [`WEAPON_HATCHET`] = true,
    [`WEAPON_KNUCKLE`] = true,
    [`WEAPON_MACHETE`] = true,
    [`WEAPON_FLASHLIGHT`] = true,
    [`WEAPON_SWITCHBLADE`] = true,
    [`WEAPON_POOLCUE`] = true,
    [`WEAPON_WRENCH`] = true,
    [`WEAPON_BATTLEAXE`] = true,
    [`WEAPON_STONE_HATCHET`] = true,
}

local function IsMeleeWeapon(weaponHash)
    return MeleeWeapons[weaponHash] == true
end

--- E ou Entrée pour ouvrir le magasin (certains joueurs utilisent Entrée au lieu de E)
local function IsShopOpenPressed()
    return VFW.Interact.JustPressed(0, 38)
        or IsControlJustPressed(0, 191) -- INPUT_FRONTEND_ACCEPT (Entrée)
        or IsControlJustPressed(0, 201) -- INPUT_FRONTEND_ACCEPT_ALT
end

local function GetLocalPlayerAccounts()
    local cash = 0
    if VFW.PlayerData and VFW.PlayerData.inventory then
        for _, item in ipairs(VFW.PlayerData.inventory) do
            if item.name == "money" then
                cash = cash + (tonumber(item.count) or 0)
            end
        end
    end

    local bank = 0
    local bankAccount = VFW.GetAccount and VFW.GetAccount("bank")
    if bankAccount then
        bank = tonumber(bankAccount.money) or 0
    end

    return cash, bank
end

local function ResolvePurchaseResult(result, cb)
    if result and result.success then
        VFW.ShowNotification({
            type = 'VERT',
            content = "Achat effectué !"
        })

        SendNUIMessage({
            action = "updateShopLTDMoney",
            data = {
                playerMoney = result.cash or 0,
                playerBank = result.bank or 0
            }
        })

        cb({ success = true })
        return
    end

    local message = result and result.message or "Erreur lors de l'achat"
    if message:find("inventaire") then
        VFW.ShowNotification({
            type = "JOB",
            title = "Inventaire",
            subtitle = "CAPACITÉ MAXIMALE",
            logo = VFW.CDN.Get("icons/inventory.png"),
            content = message
        })
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = message
        })
    end
    cb({ success = false, message = message })
end

-- Cache pour l'état APU (éviter spam de callbacks serveur)
local apuStateCache = {}
local APU_CACHE_DURATION = 1000 -- 1 seconde de cache

-- Cache pour canRob APU (éviter callback serveur chaque frame)
local canRobCache = {}
local CAN_ROB_CACHE_DURATION = 2000 -- 2 secondes de cache

-- Global items cache for automatic stores
local GlobalShopItems = nil
local isInAutomaticZone = false
local currentAutomaticSupermarket = nil

-- Event to invalidate cache when catalog is updated
RegisterNetEvent("core:supermarket:invalidateGlobalItemsCache")
AddEventHandler("core:supermarket:invalidateGlobalItemsCache", function()
    GlobalShopItems = nil -- Force reload on next shop open
end)

-- Open shop for automatic supermarkets (using new ShopLTD component)
local function OpenAutomaticShop(supermarketId)
    -- Load global items if not cached
    if not GlobalShopItems then
        GlobalShopItems = TriggerServerCallback("core:supermarket:getGlobalItems") or {}
    end

    -- Transform items for ShopLTD format
    local products = {}
    for _, item in ipairs(GlobalShopItems) do
        local rawCategory = string.lower(item.category or "")
        local category
        if rawCategory == "food" or rawCategory == "nourriture" then
            category = "nourriture"
        else
            category = "divers"
        end

        table.insert(products, {
            name = item.label or item.name,
            price = item.price or 0,
            image = VFW.ItemImageUrl(item.name, VFW.Items and VFW.Items[item.name]),
            category = category,
            itemName = item.name
        })
    end

    -- Forcer un refresh des comptes depuis le serveur
    local freshAccounts = TriggerServerCallback("core:supermarket:getPlayerAccounts")
    local fallbackCash, fallbackBank = GetLocalPlayerAccounts()
    local playerMoney = freshAccounts and tonumber(freshAccounts.cash) or fallbackCash
    local playerBank = freshAccounts and tonumber(freshAccounts.bank) or fallbackBank

    SendNUIMessage({
        action = "openShopLTD",
        data = {
            products = products,
            playerName = VFW.PlayerData.firstName,
            playerMoney = playerMoney,
            playerBank = playerBank
        }
    })

    VFW.Nui.Focus(true, false)
end

function GetSupermarkets()
    return Supermarkets
end

-- Helper function for showing help text without sound (copied from whitening)
local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

-- Utility function to convert rotation to direction vector
local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

CreateThread(function()
    Wait(1000)
        TriggerServerEvent("core:supermarket:requestSupermarketsList")
end)

local apuModels = {
    `mp_m_shopkeep_01`,
    `s_f_y_shop_low`,
    `s_f_y_shop_mid`,
    `s_m_y_shop_mask`
}

local function IsAPUModel(model)
    for _, m in ipairs(apuModels) do
        if model == m then
            return true
        end
    end
    return false
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function GetClosestSupermarket()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, supermarket in pairs(Supermarkets) do
        -- Inclure toutes les superettes actives avec un APU (braquables ou non, quel que soit storeType)
        if supermarket.active and supermarket.apuPos then
            -- Calculer distance par rapport à la position APU (pas pos du store)
            local apuPos = vector3(supermarket.apuPos.x, supermarket.apuPos.y, supermarket.apuPos.z)
            local dist = #(coords - apuPos)
            if dist < closestDist then
                closest = id
                closestDist = dist
            end
        end
    end

    return closest, closestDist
end

local function LockAPU(ped)
    if not ped or not DoesEntityExist(ped) then return end
    ClearPedTasks(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedFleeAttributes(ped, 0, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedConfigFlag(ped, 17, true)
    SetPedConfigFlag(ped, 32, true)
    SetPedConfigFlag(ped, 281, true)
end

local function StartAPURobberyAnimation(ped)
    RequestAnimDict(SupermarketSettings.APU.AnimDict)
    while not HasAnimDictLoaded(SupermarketSettings.APU.AnimDict) do
        Wait(10)
    end

    LockAPU(ped)
    TaskPlayAnim(ped, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
end

local function KeepAPUInShockState(ped, supermarketId)

    LockAPU(ped)

    RequestAnimDict(SupermarketSettings.APU.AnimDict)
    while not HasAnimDictLoaded(SupermarketSettings.APU.AnimDict) do
        Wait(10)
    end

    TaskPlayAnim(ped, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Set timer for 5 minutes (300000ms)
    APURecoveryTimers[supermarketId] = GetGameTimer() + 300000

    -- Create thread to monitor and restore APU after 5 minutes
    CreateThread(function()
        while APURecoveryTimers[supermarketId] and GetGameTimer() < APURecoveryTimers[supermarketId] do
            -- Keep the animation playing every 10 seconds to prevent it from stopping
            if DoesEntityExist(ped) then
                if not IsEntityPlayingAnim(ped, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 3) then
                    TaskPlayAnim(ped, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end
            Wait(10000) -- Check every 10 seconds
        end

        -- 5 minutes passed, stop shock anim but keep APU locked
        if DoesEntityExist(ped) and APURecoveryTimers[supermarketId] then
            ClearPedTasks(ped)
            TaskStandStill(ped, -1)
            LockAPU(ped)
            APURecoveryTimers[supermarketId] = nil
        end
    end)
end

local function StartAPURobbery(supermarketId, ped)

    if isRobbingAPU then
        return
    end

    local canRob, reason = TriggerServerCallback("core:supermarket:canRobAPU", supermarketId)

    if not canRob then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Impossible de braquer maintenant"
        })
        return
    end

    isRobbingAPU = true
    currentSupermarket = supermarketId
    apuPed = ped
    canRobCache[supermarketId] = nil -- Invalider le cache

    TriggerServerEvent("core:supermarket:startAPURobbery", supermarketId)

    StartAPURobberyAnimation(ped)

    -- Notification debut du braquage
    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Maintenez le vendeur en joue pendant qu'il vous donne l'argent"
    })

    -- Notification police au debut du braquage
    VFW.ShowNotification({
        type = 'ILLEGAL',
        message = "Les forces de l'ordre ont été prévenues"
    })

    local robberyTime = SupermarketSettings.APU.RobberyTime

    -- APU voicelines pendant le braquage
    CreateThread(function()
        local voicelines = {
            "GENERIC_FRIGHTENED_HIGH",
            "GENERIC_FRIGHTENED_MED",
            "GENERIC_SHOCKED_HIGH",
            "GENERIC_SHOCKED_MED",
            "SHOCKED_HIGH",
        }
        Wait(1500)
        while isRobbingAPU do
            if DoesEntityExist(ped) then
                PlayAmbientSpeech1(ped, voicelines[math.random(#voicelines)], "SPEECH_PARAMS_FORCE_SHOUTED")
            end
            Wait(math.random(4000, 6500))
        end
    end)

    -- Create timer thread
    CreateThread(function()
        local endAt = GetGameTimer() + (robberyTime * 1000)

        while isRobbingAPU and GetGameTimer() < endAt do
            -- Afficher le temps restant
            local timeLeft = math.ceil((endAt - GetGameTimer()) / 1000)
            ShowHelp(string.format("~g~Braquage en cours~w~ - Restez près du vendeur (~y~%ds~w~)", timeLeft))

            -- Check distance
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = GetEntityCoords(ped)
            if #(playerCoords - pedCoords) > 15.0 then
                -- Player moved too far
                TriggerServerEvent("core:supermarket:cancelAPURobbery", supermarketId, "distance")
                KeepAPUInShockState(apuPed, supermarketId)
                isRobbingAPU = false
                currentSupermarket = nil
                apuPed = nil
                VFW.ShowNotification({
                    type = 'ILLEGAL',
                    message = "Vous vous êtes trop éloigné !"
                })
                return
            end

            Wait(100)
        end

        -- Robbery completed if we exit the loop normally
        if isRobbingAPU then
            TriggerServerEvent("core:supermarket:completeAPURobbery", supermarketId)
            KeepAPUInShockState(apuPed, supermarketId)
            isRobbingAPU = false
            currentSupermarket = nil
            apuPed = nil
        end
    end)
end

-- Safe Robbery using SafeCracking minigame
local pendingSafeRobbery = nil

-- Calcule le heading pour faire face à une position cible
local function GetHeadingTowardPosition(fromPos, toPos)
    local dx = toPos.x - fromPos.x
    local dy = toPos.y - fromPos.y
    local heading = math.deg(math.atan(dx, dy))
    if heading < 0 then heading = heading + 360 end
    return heading
end

-- Fonction pour reset tous les états de braquage coffre
local function ResetSafeRobberyState()
    local playerPed = PlayerPedId()
    ClearPedTasksImmediately(playerPed)
    isRobbingSafe = false
    currentSupermarket = nil
    pendingSafeRobbery = nil
    VFW.Nui.Focus(false)
end

local function StartSafeRobbery(supermarketId)
    if isRobbingSafe then return end

    local canRob, reason = TriggerServerCallback("core:supermarket:canRobSafe", supermarketId)

    if not canRob then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Impossible de braquer le coffre maintenant"
        })
        return
    end

    isRobbingSafe = true
    currentSupermarket = supermarketId
    pendingSafeRobbery = supermarketId

    local playerPed = PlayerPedId()
    local supermarket = Supermarkets[supermarketId]

    -- Orienter le joueur vers le coffre AVANT le minigame
    -- Utilise le heading enregistré par le staff (safePos.h) pour que le joueur soit dans la bonne direction
    if supermarket and supermarket.safePos then
        if supermarket.safePos.h then
            -- Utiliser le heading enregistré (direction du staff lors de la création)
            SetEntityHeading(playerPed, supermarket.safePos.h)
        else
            -- Fallback: calculer le heading vers le coffre si h n'existe pas
            local playerPos = GetEntityCoords(playerPed)
            local safePos = vector3(supermarket.safePos.x, supermarket.safePos.y, supermarket.safePos.z)
            local headingToSafe = GetHeadingTowardPosition(playerPos, safePos)
            SetEntityHeading(playerPed, headingToSafe)
        end
    end

    -- Lancer l'animation de crochetage PENDANT le minigame (tourner le cadran)
    local hackAnimDict = "mini@safe_cracking"
    local hackAnimName = "idle_base"

    RequestAnimDict(hackAnimDict)
    while not HasAnimDictLoaded(hackAnimDict) do
        Wait(10)
    end

    TaskPlayAnim(playerPed, hackAnimDict, hackAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Open SafeCracking NUI minigame
    SendNUIMessage({
        action = "safeCracking:open",
        data = {
            difficulty = 2 -- Medium difficulty (3-4 numbers to find)
        }
    })
    VFW.Nui.Focus(true)

    -- Timeout de sécurité - si pas de réponse NUI après 60 secondes, reset
    SetTimeout(60000, function()
        if pendingSafeRobbery == supermarketId then
            ResetSafeRobberyState()
        end
    end)
end

-- Handle SafeCracking minigame result
RegisterNUICallback("safeCracking:result", function(data, cb)
    VFW.Nui.Focus(false)
    cb({ success = true }) -- Return valid JSON

    local playerPed = PlayerPedId()
    local supermarketId = pendingSafeRobbery

    -- Toujours reset pendingSafeRobbery en premier
    pendingSafeRobbery = nil

    if not supermarketId then
        -- Pas de braquage en cours, juste reset
        ClearPedTasksImmediately(playerPed)
        isRobbingSafe = false
        currentSupermarket = nil
        return
    end

    if data.cancelled then
        -- Player cancelled - arrêter l'animation et reset tout
        ClearPedTasksImmediately(playerPed)
        isRobbingSafe = false
        currentSupermarket = nil
        -- Invalider le cache pour cette superette
        apuStateCache[supermarketId] = nil
        -- Fermer explicitement le NUI
        SendNUIMessage({ action = "safeCracking:close" })
        return
    end

    if data.success then
        -- Success - arrêter l'animation de hack et lancer l'animation de récolte
        ClearPedTasksImmediately(playerPed)

        -- Lancer l'animation de récolte (grab cash)
        local grabAnimDict = "anim@heists@ornate_bank@grab_cash"
        local grabAnimName = "grab"

        RequestAnimDict(grabAnimDict)
        while not HasAnimDictLoaded(grabAnimDict) do
            Wait(10)
        end

        TaskPlayAnim(playerPed, grabAnimDict, grabAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)

        TriggerServerEvent("core:supermarket:startSafeRobbery", supermarketId)

        -- Timer for safe opening
        local robberyTime = SupermarketSettings.Safe.RobberyTime

        CreateThread(function()
            local endAt = GetGameTimer() + (robberyTime * 1000)

            while isRobbingSafe and GetGameTimer() < endAt do
                Wait(100)
            end

            if isRobbingSafe then
                -- Robbery complete
                ClearPedTasksImmediately(PlayerPedId())
                TriggerServerEvent("core:supermarket:completeSafeRobbery", supermarketId)
                isRobbingSafe = false
                currentSupermarket = nil
                -- Invalider le cache
                apuStateCache[supermarketId] = nil
            end
        end)
    else
        -- Failed minigame - arrêter l'animation
        ClearPedTasksImmediately(playerPed)
        isRobbingSafe = false
        currentSupermarket = nil
        -- Invalider le cache
        apuStateCache[supermarketId] = nil
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = "Vous avez raté le crochetage du coffre"
        })
    end
end)

-- APU monitoring thread (no death handling since APU is invincible)
CreateThread(function()
    while true do
        -- Keep thread for potential future monitoring needs
        Wait(5000) -- Check less frequently since APUs are invincible
    end
end)

-- Safe marker thread - Draw ground markers for safes
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())

        for id, supermarket in pairs(Supermarkets) do
            if supermarket.active and supermarket.canRob and supermarket.safePos then
                local isBeingRobbed = robbingSafes[id] and robbingSafes[id].isRobbing

                if not isBeingRobbed then
                    local safePos = vector3(supermarket.safePos.x, supermarket.safePos.y, supermarket.safePos.z)
                    local dist = #(playerCoords - safePos)

                    if dist < 50.0 then
                        DrawMarker(1, -- Type: Cylinder
                            safePos.x, safePos.y, safePos.z - 1.0, -- Position
                            0.0, 0.0, 0.0, -- Direction
                            0.0, 0.0, 0.0, -- Rotation
                            1.0, 1.0, 0.1, -- Scale (width, depth, height)
                            255, 0, 0, 100, -- Color (Red with transparency)
                            false, true, 2, false, nil, nil, false -- bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts
                        )
                    end
                end
            end
        end

        Wait(0)
    end
end)

-- Main detection thread
CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not SupermarketAPUs then
            SupermarketAPUs = {}
        end

        -- Check for AUTOMATIC stores (zone-based, no APU - non braquable)
        local foundAutomatic = false
        for id, supermarket in pairs(Supermarkets) do
            local sType = supermarket.storeType or "robbable"
            if supermarket.active and sType == "automatic" then
                local storePos = vector3(supermarket.pos.x, supermarket.pos.y, supermarket.pos.z)
                local zoneRadius = supermarket.zoneRadius or 2.0
                local dist = #(playerCoords - storePos)

                if dist < zoneRadius then
                    wait = 0
                    foundAutomatic = true
                    isInAutomaticZone = true
                    currentAutomaticSupermarket = id

                    -- Vérifier si le joueur a une arme en main dans une superette non braquable
                    local currentWeapon = VFW.PlayerData.weapon or 0
                    local weaponUnarmed = GetHashKey("WEAPON_UNARMED")
                    local hasWeapon = currentWeapon ~= 0 and currentWeapon ~= weaponUnarmed

                    if hasWeapon then
                        ShowHelp("~r~Cette supérette n'est pas braquable")
                    else
                        ShowHelp("Appuyez sur ~INPUT_CONTEXT~ ou ~INPUT_FRONTEND_ACCEPT~ pour ouvrir le magasin")

                        if IsShopOpenPressed() then
                            OpenAutomaticShop(id)
                        end
                    end
                    break
                end
            end
        end

        if not foundAutomatic then
            isInAutomaticZone = false
            currentAutomaticSupermarket = nil
        end

        -- Check for ROBBABLE stores (APU-based)
        if not foundAutomatic then
            local closestPed = nil
            local closestPedDist = 999999.0

            -- Method 1: Check our tracked APUs first
            for id, apu in pairs(SupermarketAPUs) do
                if DoesEntityExist(apu) then
                    local pedCoords = GetEntityCoords(apu)
                    local dist = #(playerCoords - pedCoords)
                    if dist < closestPedDist then
                        closestPed = apu
                        closestPedDist = dist
                    end
                end
            end

            -- Method 2: Scan all peds (backup)
            for ped in EnumeratePeds() do
                if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
                    local model = GetEntityModel(ped)
                    if IsAPUModel(model) then
                        local pedCoords = GetEntityCoords(ped)
                        local dist = #(playerCoords - pedCoords)
                        if dist < closestPedDist then
                            closestPed = ped
                            closestPedDist = dist
                        end
                    end
                end
            end

            -- Check if near a supermarket APU (store with APU)
            if closestPed and closestPedDist < SupermarketSettings.InteractDistance then
                wait = 0
                local supermarketId = GetClosestSupermarket()

                local isBeingRobbed = robbingAPUs[supermarketId] and robbingAPUs[supermarketId].isRobbing

                if supermarketId and not isRobbingAPU and not isRobbingSafe and not isBeingRobbed then
                    local supermarket = Supermarkets[supermarketId]
                    local canRob = supermarket and supermarket.canRob or false

                    -- Check if player has a weapon out using VFW system
                    local currentWeapon = VFW.PlayerData.weapon or 0
                    local weaponUnarmed = GetHashKey("WEAPON_UNARMED")
                    local hasWeapon = currentWeapon ~= 0 and currentWeapon ~= weaponUnarmed
                    local hasMeleeWeapon = IsMeleeWeapon(currentWeapon)
                    local isAiming = IsPlayerFreeAiming(PlayerId())
                    local isTargetingPed = false
                    local canRobWithMelee = false

                    if hasWeapon then
                        if hasMeleeWeapon then
                            -- Arme blanche: proche + appuyer sur E pour menacer
                            if closestPedDist < 2.0 then
                                canRobWithMelee = true
                            end
                        elseif isAiming then
                            -- Arme à feu: viser l'APU
                            local aimingAtEntity, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())

                            if aimingAtEntity and targetEntity == closestPed then
                                isTargetingPed = true
                            end
                        end
                    end

                    -- Vérifier le cooldown (avec cache pour éviter de bloquer chaque frame)
                    local currentTime = GetGameTimer()
                    local robCache = canRobCache[supermarketId]
                    if not robCache or (currentTime - robCache.timestamp) > CAN_ROB_CACHE_DURATION then
                        local result, reason = TriggerServerCallback("core:supermarket:canRobAPU", supermarketId)
                        canRobCache[supermarketId] = { canRob = result, reason = reason, timestamp = currentTime }
                        robCache = canRobCache[supermarketId]
                    end
                    local canRobNow = robCache.canRob

                    -- Vérifier si la superette est braquable avant de permettre le braquage
                    if hasWeapon and not canRob then
                        -- Superette non braquable avec arme
                        ShowHelp("~r~Cette supérette n'est pas braquable")
                    elseif hasWeapon and canRob and not canRobNow then
                        -- Afficher la vraie raison du serveur (police, cooldown, quota, etc.)
                        ShowHelp("~r~" .. (robCache.reason or "Ce magasin a déjà été braqué récemment"))
                    elseif hasWeapon and canRob and isTargetingPed then
                        ShowHelp("~g~Maintenez le vendeur en joue~w~ pour le braquer")

                        local currentTime = GetGameTimer()
                        if currentTime - lastRobberyAttempt > 2000 then
                            lastRobberyAttempt = currentTime
                            StartAPURobbery(supermarketId, closestPed)
                        end
                    elseif hasWeapon and canRob and canRobWithMelee then
                        ShowHelp("Appuyez sur ~INPUT_CONTEXT~ pour menacer le vendeur")

                        if VFW.Interact.JustPressed(0, 38) then
                            local currentTime = GetGameTimer()
                            if currentTime - lastRobberyAttempt > 2000 then
                                lastRobberyAttempt = currentTime
                                StartAPURobbery(supermarketId, closestPed)
                            end
                        end
                    elseif hasWeapon and canRob and not hasMeleeWeapon and closestPedDist < SupermarketSettings.InteractDistance then
                        ShowHelp("~y~Visez le vendeur avec votre arme~w~ pour le braquer")
                    elseif hasWeapon and canRob and hasMeleeWeapon and closestPedDist >= 2.0 then
                        ShowHelp("~y~Rapprochez-vous du vendeur~w~ pour le menacer")
                    else
                        ShowHelp("Appuyez sur ~INPUT_CONTEXT~ ou ~INPUT_FRONTEND_ACCEPT~ pour ouvrir le magasin")

                        if IsShopOpenPressed() then
                            OpenAutomaticShop(supermarketId)
                        end
                    end
                end
            end

            -- Check for safe interaction (only for stores with canRob = true and safePos)
            if currentSupermarket == nil and not isRobbingAPU and not isRobbingSafe then
                for id, supermarket in pairs(Supermarkets) do
                    if supermarket.active and supermarket.canRob and supermarket.safePos then
                        local isBeingRobbed = robbingSafes[id] and robbingSafes[id].isRobbing

                        if not isBeingRobbed then
                            local safePos = vector3(supermarket.safePos.x, supermarket.safePos.y, supermarket.safePos.z)
                            local dist = #(playerCoords - safePos)

                            if dist < SupermarketSettings.SafeInteractDistance then
                                wait = 0

                                -- Utiliser le cache pour éviter spam de callbacks serveur
                                local currentTime = GetGameTimer()
                                local cache = apuStateCache[id]

                                if not cache or (currentTime - cache.timestamp) > APU_CACHE_DURATION then
                                    -- Rafraîchir le cache
                                    local apuRobbed, timeLeft = TriggerServerCallback("core:supermarket:getAPUState", id)
                                    apuStateCache[id] = {
                                        apuRobbed = apuRobbed,
                                        timeLeft = timeLeft,
                                        timestamp = currentTime
                                    }
                                    cache = apuStateCache[id]
                                end

                                if not cache.apuRobbed then
                                    ShowHelp("~r~Vous devez d'abord braquer le vendeur")
                                elseif cache.timeLeft <= 0 then
                                    ShowHelp("~r~Trop tard ! Le coffre s'est verrouillé")
                                else
                                    local minutes = math.floor(cache.timeLeft / 60)
                                    local seconds = cache.timeLeft % 60
                                    ShowHelp(string.format("~g~[E]~w~ Forcez le coffre (~y~%02d:%02d~w~ restantes)", minutes, seconds))

                                    if VFW.Interact.JustPressed(0, 38) then
                                        StartSafeRobbery(id)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

-- Event handlers
-- Désactivé: pas de blips police car les métiers police n'existent pas
-- RegisterNetEvent("core:supermarket:createPoliceBlip")
-- AddEventHandler("core:supermarket:createPoliceBlip", function(supermarketId, supermarketName, message)
-- end)

-- Function to clean up a supermarket's blip and APU
local function CleanupSupermarket(id)
    -- Remove blip
    if SupermarketBlips[id] and DoesBlipExist(SupermarketBlips[id]) then
        RemoveBlip(SupermarketBlips[id])
        SupermarketBlips[id] = nil
    end

    -- Remove APU
    if SupermarketAPUs[id] and DoesEntityExist(SupermarketAPUs[id]) then
        DeleteEntity(SupermarketAPUs[id])
        SupermarketAPUs[id] = nil
    end
end

-- Function to create/update a supermarket's blip and APU
local function SetupSupermarket(id, supermarket)
    if supermarket.active then
        -- Create or update blip (only if blip is enabled)
        if supermarket.blipEnabled then
            -- Remove existing blip to recreate at potentially new position
            if SupermarketBlips[id] and DoesBlipExist(SupermarketBlips[id]) then
                RemoveBlip(SupermarketBlips[id])
                SupermarketBlips[id] = nil
            end

            local blip = AddBlipForCoord(supermarket.pos.x, supermarket.pos.y, supermarket.pos.z)

            SetBlipSprite(blip, 52) -- Default store icon
            SetBlipScale(blip, 0.5)
            SetBlipColour(blip, 2) -- Green
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Superette 24/7")
            EndTextCommandSetBlipName(blip)

            SupermarketBlips[id] = blip
        else
            -- Remove blip if disabled
            if SupermarketBlips[id] and DoesBlipExist(SupermarketBlips[id]) then
                RemoveBlip(SupermarketBlips[id])
                SupermarketBlips[id] = nil
            end
        end

        -- Create APU for any store that has apuPos defined (regardless of storeType)
        if supermarket.apuPos then
            -- Remove existing APU to recreate at potentially new position
            if SupermarketAPUs[id] and DoesEntityExist(SupermarketAPUs[id]) then
                DeleteEntity(SupermarketAPUs[id])
                SupermarketAPUs[id] = nil
            end

            -- Use VFW.CreatePed with proper coordinates
            local coords = {
                x = supermarket.apuPos.x,
                y = supermarket.apuPos.y,
                z = supermarket.apuPos.z - 1.0,
                w = supermarket.apuPos.h or 0.0  -- heading
            }

            local apu = VFW.CreatePed(coords, "mp_m_shopkeep_01")

            if apu and DoesEntityExist(apu) then
                SetEntityMaxHealth(apu, 200)
                SetEntityHealth(apu, 200)

                ClearPedTasks(apu)
                TaskStandStill(apu, -1)

                LockAPU(apu)

                SupermarketAPUs[id] = apu
            end
        else
            -- No apuPos defined, clean up any existing APU
            if SupermarketAPUs[id] and DoesEntityExist(SupermarketAPUs[id]) then
                DeleteEntity(SupermarketAPUs[id])
                SupermarketAPUs[id] = nil
            end
        end
    else
        -- Clean up if not active
        CleanupSupermarket(id)
    end
end

-- Handle both sync events (initial sync and menu requests)
RegisterNetEvent("core:supermarket:syncSupermarkets")
AddEventHandler("core:supermarket:syncSupermarkets", function(supermarkets)
    local count = 0
    local autoCount = 0
    local robbableCount = 0

    for id, sm in pairs(supermarkets) do
        count = count + 1
        local sType = sm.storeType or "nil"
        -- print(("[SUPERMARKET DEBUG] ID: %s | Name: %s | Type: %s | Active: %s | Blip: %s"):format(
        --     tostring(id),
        --     tostring(sm.name),
        --     tostring(sType),
        --     tostring(sm.active),
        --     tostring(sm.blipEnabled)
        -- ))
        if sType == "automatic" then
            autoCount = autoCount + 1
        else
            robbableCount = robbableCount + 1
        end
    end

    -- print(("[SUPERMARKET DEBUG] Total: %d | Automatic: %d | Robbable: %d"):format(count, autoCount, robbableCount))

    -- First, clean up any supermarkets that no longer exist
    for id, _ in pairs(SupermarketBlips) do
        if not supermarkets[id] then
            CleanupSupermarket(id)
        end
    end

    -- Store supermarkets locally
    Supermarkets = supermarkets

    -- Create/update blips and APUs for all supermarkets
    for id, supermarket in pairs(supermarkets) do
        SetupSupermarket(id, supermarket)
    end
end)

RegisterNetEvent("core:supermarket:receiveSupermarketsList")
AddEventHandler("core:supermarket:receiveSupermarketsList", function(supermarkets)
    TriggerEvent("core:supermarket:syncSupermarkets", supermarkets)
end)

RegisterNetEvent("core:supermarket:cleanupAllAPUs")
AddEventHandler("core:supermarket:cleanupAllAPUs", function()

    for id, apu in pairs(SupermarketAPUs) do
        if DoesEntityExist(apu) then
            DeleteEntity(apu)
        end
        SupermarketAPUs[id] = nil
    end

    local cleanupCount = 0
    for ped in EnumeratePeds() do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local model = GetEntityModel(ped)
            if IsAPUModel(model) then
                DeleteEntity(ped)
                cleanupCount = cleanupCount + 1
            end
        end
    end
    isRobbingAPU = false
    isRobbingSafe = false
    currentSupermarket = nil
    apuPed = nil
    shockedAPUs = {}
    robbingAPUs = {}
    robbingSafes = {}
end)

RegisterNetEvent("core:supermarket:syncAPUShocked")
AddEventHandler("core:supermarket:syncAPUShocked", function(supermarketId, isShocked)
    if isShocked then
        shockedAPUs[supermarketId] = {
            isShocked = true,
            timestamp = GetGameTimer()
        }

        local apu = SupermarketAPUs[supermarketId]
        if apu and DoesEntityExist(apu) then
            RequestAnimDict(SupermarketSettings.APU.AnimDict)
            while not HasAnimDictLoaded(SupermarketSettings.APU.AnimDict) do
                Wait(10)
            end

            LockAPU(apu)
            TaskPlayAnim(apu, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 8.0, -8.0, -1, 49, 0, false, false, false)

            CreateThread(function()
                while shockedAPUs[supermarketId] and shockedAPUs[supermarketId].isShocked do
                    if DoesEntityExist(apu) then
                        if not IsEntityPlayingAnim(apu, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 3) then
                            TaskPlayAnim(apu, SupermarketSettings.APU.AnimDict, SupermarketSettings.APU.AnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
                        end
                    end
                    Wait(10000)
                end
            end)
        end
    else
        shockedAPUs[supermarketId] = nil

        local apu = SupermarketAPUs[supermarketId]
        if apu and DoesEntityExist(apu) then
            ClearPedTasks(apu)
            TaskStandStill(apu, -1)
            LockAPU(apu)
        end
    end
end)

RegisterNetEvent("core:supermarket:syncAPURobberyState")
AddEventHandler("core:supermarket:syncAPURobberyState", function(supermarketId, isRobbing, playerId)
    if isRobbing then
        robbingAPUs[supermarketId] = {
            isRobbing = true,
            playerId = playerId
        }
    else
        robbingAPUs[supermarketId] = nil
    end
end)

RegisterNetEvent("core:supermarket:syncSafeRobberyState")
AddEventHandler("core:supermarket:syncSafeRobberyState", function(supermarketId, isRobbing, playerId)
    if isRobbing then
        robbingSafes[supermarketId] = {
            isRobbing = true,
            playerId = playerId
        }
    else
        robbingSafes[supermarketId] = nil
    end
end)

-- Utility function for enumerating peds
function EnumeratePeds()
    return coroutine.wrap(function()
        local ped = 0
        repeat
            ped = FindFirstPed(ped)
            if ped ~= 0 then
                coroutine.yield(ped)
            end
        until not FindNextPed(ped)
        EndFindPed(ped)
    end)
end

-- NUI Callbacks pour le nouveau ShopLTD
RegisterNUICallback('closeShopLTD', function(data, cb)
    VFW.Nui.Focus(false)
    cb('ok')
end)

RegisterNUICallback('purchaseItems', function(data, cb)
    local items = data.items or {}
    local total = tonumber(data.total) or 0
    local paymentMethod = data.paymentMethod or "cash"

    if type(items) ~= "table" or next(items) == nil then
        cb({ success = false, message = "Panier vide" })
        return
    end

    local purchaseData = {}
    for _, item in ipairs(items) do
        if type(item) == "table" then
            table.insert(purchaseData, {
                name = item.itemName or item.name,
                quantity = tonumber(item.quantity) or 1,
                price = tonumber(item.price) or 0
            })
        end
    end

    if #purchaseData == 0 then
        cb({ success = false, message = "Panier vide" })
        return
    end

    -- Éviter le deadlock Citizen.Await dans le callback NUI
    CreateThread(function()
        local ok, result = pcall(function()
            return TriggerServerCallback('core:supermarket:purchaseItems', purchaseData, total, paymentMethod)
        end)

        if not ok then
            print(("[ShopLTD] Erreur achat: %s"):format(tostring(result)))
            cb({ success = false, message = "Erreur interne lors de l'achat" })
            return
        end

        ResolvePurchaseResult(result, cb)
    end)
end)

-- Legacy NUI Callbacks (pour compatibilité avec anciens systèmes)
RegisterNUICallback('shops:buy', function(data, cb)
    local shopType = data.shopType
    local shopName = data.shopName or ""

    -- Ignorer les distributeurs automatiques (gérés par object_context_menu.lua)
    if string.find(shopName, "^vending_") then
        return
    end

    if shopType == "ltd" then
        local result = TriggerServerCallback('shops:buy', data)

        if result and result.success then
            VFW.Nui.Focus(false)
            cb({ success = true })
        elseif result and not result.success then
            local message = result.message or "Erreur lors de l achat"
            if message:find("inventaire") then
                VFW.ShowNotification({
                    type = "JOB",
                    title = "Inventaire",
                    subtitle = "CAPACITÉ MAXIMALE",
                    logo = VFW.CDN.Get("icons/inventory.png"),
                    content = message
                })
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = message
                })
            end
            cb({ success = false, message = message })
        else
            cb({ success = false, message = "Erreur inconnue" })
        end
    else
        cb({ success = false, message = "Type de magasin non supporté" })
    end
end)

RegisterNUICallback('shops:close', function(data, cb)
    TriggerServerEvent('shops:close')
    VFW.Nui.Focus(false)
    cb('ok')
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in ipairs(robberyBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        for id, _ in pairs(SupermarketBlips) do
            CleanupSupermarket(id)
        end
    end
end)