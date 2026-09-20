---@meta _
---@diagnostic disable: duplicate-doc-field

local BurglaryHouses = {}
local BurglaryInteriors = {}
local BurglarySettings = {}
local robberyBlips = {}
local houseBlips = {}
local ActiveBurglaries = {}
local PostRobberyHouses = {}

-- Item requis pour le cambriolage
local REQUIRED_ITEM = "kit_de_crochetage"

-- Helper pour vérifier si dans une instance (utilise l'export de cl_instances.lua)
local function IsInInstance()
    return exports.core:IsInBurglaryInstance()
end

-- Vérifier si le joueur a l'item requis dans son inventaire
local function HasRequiredItem()
    local xPlayer = VFW.GetPlayerData()
    if xPlayer and xPlayer.haveItem then
        return xPlayer.haveItem(REQUIRED_ITEM)
    end
    return false
end

-- Callback pour le serveur
RegisterClientCallback("core:burglary:hasRequiredItem", function()
    return HasRequiredItem()
end)

local function ShowHelp(text)
    VFW.ShowHelpNotification(text)
end

-- FloatingInteraction helpers
local floatingInteractionShown = false
local currentFloatingHouseId = nil

local function ShowFloatingInteraction(houseId, worldPos, isBeingRobbed, canRob, reason, isPostRobbery)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + 0.3)

    if not onScreen then
        if floatingInteractionShown then
            SendNUIMessage({
                action = "floatingInteraction:hide"
            })
            floatingInteractionShown = false
            currentFloatingHouseId = nil
        end
        return
    end

    local data = {
        id = "burglary_" .. tostring(houseId),
        title = "Cambriolage",
        subtitle = nil,
        screenX = screenX,
        screenY = screenY,
        buttons = {}
    }

    if isPostRobbery then
        data.subtitle = "Porte ouverte"
        data.buttons = {
            { label = "Entrer", key = "E", icon = "home" }
        }
    elseif isBeingRobbed then
        data.subtitle = "Cambriolage en cours"
        data.buttons = {
            { label = "Rejoindre", key = "E", icon = "home" }
        }
    else
        data.subtitle = "Disponible"
        data.buttons = {
            { label = "Cambrioler", key = "E", icon = "home" }
        }
    end

    if floatingInteractionShown and currentFloatingHouseId == houseId then
        SendNUIMessage({
            action = "floatingInteraction:update",
            data = data
        })
    else
        SendNUIMessage({
            action = "floatingInteraction:show",
            data = data
        })
        floatingInteractionShown = true
        currentFloatingHouseId = houseId
    end
end

local function HideFloatingInteraction()
    if floatingInteractionShown then
        SendNUIMessage({
            action = "floatingInteraction:hide"
        })
        floatingInteractionShown = false
        currentFloatingHouseId = nil
    end
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

local function GetClosestHouse()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest = nil
    local closestDist = 999999.0

    for id, house in pairs(BurglaryHouses) do
        if house.active then
            local dist = #(coords - vector3(house.entryPos.x, house.entryPos.y, house.entryPos.z))
            if dist < closestDist then
                closest = id
                closestDist = dist
            end
        end
    end

    return closest, closestDist
end

local function StartHouseRobbery(houseId)
    local canRob, reason = TriggerServerCallback("core:burglary:canStartRobbery", houseId)

    if not canRob then
        VFW.ShowNotification({
            type = 'ILLEGAL',
            message = reason or "Impossible de cambrioler maintenant"
        })
        return
    end

    local playerPed = PlayerPedId()

    -- Animation de crochetage
    local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    local animName = "machinic_loop_mechandplayer"

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    -- Jouer l'animation en boucle
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Déterminer la difficulté en fonction des settings
    local difficulty = BurglarySettings.lockpick_difficulty or "medium"

    -- Utiliser le système de hacking centralisé
    StartHacking("lockpick", difficulty, 60, function(success)
        -- Arrêter l'animation
        ClearPedTasksImmediately(playerPed)
        RemoveAnimDict(animDict)

        if success then
            VFW.ShowNotification({
                type = 'ILLEGAL',
                message = "Serrure crochetée !"
            })
            TriggerServerEvent("core:burglary:startRobbery", houseId)
        else
            VFW.ShowNotification({
                type = 'ILLEGAL',
                message = "Échec du crochetage..."
            })
            TriggerServerEvent("core:burglary:useLockpickKit")
        end
    end)
end

local function CreateHouseBlip(id, house)
    if houseBlips[id] and DoesBlipExist(houseBlips[id]) then
        return -- Blip déjà existant
    end

    local blip = AddBlipForCoord(house.entryPos.x, house.entryPos.y, house.entryPos.z)
    SetBlipSprite(blip, 255) -- Icône de clef
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Cambriolage")
    EndTextCommandSetBlipName(blip)

    houseBlips[id] = blip
end

local function RemoveHouseBlip(id)
    if houseBlips[id] and DoesBlipExist(houseBlips[id]) then
        RemoveBlip(houseBlips[id])
        houseBlips[id] = nil
    end
end

local function UpdateHouseBlips()
    for id, house in pairs(BurglaryHouses) do
        if house.active and house.blipEnabled then
            CreateHouseBlip(id, house)
        else
            RemoveHouseBlip(id)
        end
    end
end

local function CreateHouseBlips()
    for id, blip in pairs(houseBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    houseBlips = {}

    UpdateHouseBlips()
end

local MARKER_DISPLAY_RADIUS = 15.0 -- Afficher le marker au sol à 15m

-- Cache pour le statut de cambriolage (évite de spam le serveur)
local cachedCanRob = {}
local cachedCanRobTime = {}
local CACHE_DURATION = 2000 -- 2 secondes

local function GetCachedCanRob(houseId)
    local now = GetGameTimer()
    if cachedCanRobTime[houseId] and (now - cachedCanRobTime[houseId]) < CACHE_DURATION then
        return cachedCanRob[houseId].canRob, cachedCanRob[houseId].reason
    end

    local canRob, reason = TriggerServerCallback("core:burglary:canStartRobbery", houseId)
    cachedCanRob[houseId] = { canRob = canRob, reason = reason }
    cachedCanRobTime[houseId] = now
    return canRob, reason
end

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not IsInInstance() then
            local closestHouseId, closestDist = GetClosestHouse()

            -- Afficher le marker au sol quand on est à moins de 15m
            if closestHouseId and closestDist < MARKER_DISPLAY_RADIUS then
                wait = 0
                local house = BurglaryHouses[closestHouseId]
                if house then
                    local markerPos = vector3(house.entryPos.x, house.entryPos.y, house.entryPos.z - 1.5)
                    -- Marker type 25 = petit cercle au sol
                    DrawMarker(25, markerPos.x, markerPos.y, markerPos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.5, 255, 100, 100, 150, false, false, 2, false, nil, nil, false)
                end
            end

            if closestHouseId and closestDist < 2.0 then
                wait = 0

                local house = BurglaryHouses[closestHouseId]
                local isBeingRobbed = ActiveBurglaries[closestHouseId]
                local isPostRobbery = PostRobberyHouses[closestHouseId]

                -- Vérifier si on peut cambrioler AVANT d'afficher l'interaction
                local canRob, reason = false, nil
                if isPostRobbery then
                    canRob = false
                    reason = nil
                elseif not isBeingRobbed then
                    canRob, reason = GetCachedCanRob(closestHouseId)
                end

                -- Afficher le floatingInteraction avec le statut
                if house then
                    ShowFloatingInteraction(closestHouseId, vector3(house.entryPos.x, house.entryPos.y, house.entryPos.z), isBeingRobbed, canRob, reason, isPostRobbery)
                end

                if VFW.Interact.JustPressed(0, 38) then
                    if isPostRobbery then
                        HideFloatingInteraction()
                        TriggerServerEvent("core:burglary:visitPostRobbery", closestHouseId)
                    else
                        local status = TriggerServerCallback("core:burglary:getInstanceStatus", closestHouseId)

                        if status and status.active then
                            -- Instance active - rejoindre directement sans lockpick
                            HideFloatingInteraction()
                            TriggerServerEvent("core:burglary:joinInstance", closestHouseId)
                        elseif canRob then
                            -- Pas d'instance et peut cambrioler - démarrer un nouveau cambriolage
                            HideFloatingInteraction()
                            StartHouseRobbery(closestHouseId)
                        else
                            VFW.ShowNotification({
                                type = 'ILLEGAL',
                                message = reason or "Impossible de cambrioler maintenant"
                            })
                        end
                    end
                end
            else
                -- Cacher le floatingInteraction si on s'éloigne
                HideFloatingInteraction()
            end
        else
            -- En instance, cacher le floatingInteraction
            HideFloatingInteraction()
        end

        Wait(wait)
    end
end)

RegisterNetEvent("core:burglary:syncData")
AddEventHandler("core:burglary:syncData", function(data)
    BurglaryHouses = data.houses or {}
    BurglaryInteriors = data.interiors or {}
    BurglarySettings = data.settings or {}

    CreateHouseBlips()
end)

RegisterNetEvent("core:burglary:createPoliceBlip")
AddEventHandler("core:burglary:createPoliceBlip", function(houseId, position)
    if IsPoliceJob(VFW.PlayerData.job.name) then
        local blip = AddBlipForCoord(position.x, position.y, position.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("10-31 - Cambriolage en cours")
        EndTextCommandSetBlipName(blip)

        table.insert(robberyBlips, blip)

        SetTimeout(300000, function()
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end)
    end
end)

RegisterNetEvent("core:burglary:syncHouseState")
AddEventHandler("core:burglary:syncHouseState", function(houseId, isActive)
    if isActive then
        ActiveBurglaries[houseId] = true
    else
        ActiveBurglaries[houseId] = nil
    end
end)

RegisterNetEvent("core:burglary:postRobbery")
AddEventHandler("core:burglary:postRobbery", function(houseId, isPostRobbery)
    if isPostRobbery then
        PostRobberyHouses[houseId] = true
    else
        PostRobberyHouses[houseId] = nil
    end
    -- Invalider le cache pour cette maison
    cachedCanRobTime[houseId] = nil
end)

-- Events enterInstance et exitInstance sont gérés dans cl_instances.lua

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in ipairs(robberyBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end

        HideFloatingInteraction()
        ActiveBurglaries = {}
        PostRobberyHouses = {}
    end
end)

-- Chargement initial des données au démarrage du client
local function LoadBurglaryData()
    local houses = TriggerServerCallback("core:burglary:getHouses")
    local interiors = TriggerServerCallback("core:burglary:getInteriors")
    local settings = TriggerServerCallback("core:burglary:getSettings")

    if houses then
        BurglaryHouses = houses
    end
    if interiors then
        BurglaryInteriors = interiors
    end
    if settings then
        BurglarySettings = settings
    end

    CreateHouseBlips()

    -- Charger l'état post-robbery
    local postRobbery = TriggerServerCallback("core:burglary:getPostRobberyHouses")
    if postRobbery then
        PostRobberyHouses = postRobbery
    end
end

CreateThread(function()
    Wait(3000) -- Attendre que le serveur soit prêt
    LoadBurglaryData()
end)