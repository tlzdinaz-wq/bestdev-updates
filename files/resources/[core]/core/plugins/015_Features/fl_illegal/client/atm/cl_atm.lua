---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================
-- ATM CUSTOM ZONES - Zones invisibles sur les ATMs du mapping
-- Utilise les mêmes fonctions que les ATM props (cl_atm_context_menu.lua)
-- ============================================

local customATMPositions = {}       -- Liste des ATM customs depuis la BDD
local registeredPositions = {}      -- { [atmId] = positionId } - IDs enregistrés dans le context menu
local adminMode = false             -- Mode admin pour afficher les zones vertes

-- Dimensions de la hitbox ATM (pour l'affichage admin seulement)
local ATM_BOX = {
    width = 1.2,
    depth = 1.0,
    height = 1.8
}

-- Rayon de détection pour le context menu
local ATM_DETECTION_RADIUS = 1.0

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Cache pour la vérification de l'item USB (éviter callback serveur chaque frame)
local hackItemCache = { hasItem = false, timestamp = 0 }
local HACK_ITEM_CACHE_DURATION = 2000 -- 2 secondes

--- Vérifie si le joueur possède l'item USB de piratage (via callback serveur avec cache)
local function HasATMHackItem()
    local currentTime = GetGameTimer()
    if (currentTime - hackItemCache.timestamp) > HACK_ITEM_CACHE_DURATION then
        local result = TriggerServerCallback("core:atm:hasHackItem")
        hackItemCache = { hasItem = result or false, timestamp = currentTime }
    end
    return hackItemCache.hasItem
end

-- ============================================
-- CONTEXT MENU REGISTRATION
-- ============================================

--- Désenregistre toutes les positions ATM du context menu
local function UnregisterAllPositions()
    local count = 0
    for atmId, posId in pairs(registeredPositions) do
        if VFW.ContextUnregisterPosition and posId then
            local success = pcall(function()
                VFW.ContextUnregisterPosition(posId)
            end)
            if success then
                count = count + 1
            end
        end
    end
    registeredPositions = {}
    if count > 0 then
        -- print("[ATM] " .. count .. " zones ATM custom désenregistrées")
    end
end

--- Enregistre une position ATM dans le context menu
local function RegisterATMPosition(atmData)
    if not VFW.ContextRegisterPosition then
        print("[ATM] ERREUR: VFW.ContextRegisterPosition non disponible")
        return nil
    end

    -- Position au centre de l'ATM (légèrement plus haut pour que le raycast touche)
    local position = vector3(atmData.x, atmData.y, atmData.z + 0.8)

    -- Enregistrer la zone avec détection par rayon
    local positionId = VFW.ContextRegisterPosition(position, ATM_DETECTION_RADIUS)

    if not positionId or positionId <= 0 then
        -- print("[ATM] ERREUR: Échec enregistrement position pour ATM " .. atmData.id)
        return nil
    end

    local atmCoords = vector3(atmData.x, atmData.y, atmData.z)
    local atmHeading = atmData.heading or 0.0
    local atmNetId = "custom_" .. atmData.id
    local atmId = atmData.id

    local function isATMStillValid()
        for _, atm in ipairs(customATMPositions) do
            if atm.id == atmId then return true end
        end
        return false
    end

    VFW.ContextAddPositionButton(positionId, ":money: Ouvrir le distributeur", function()
        if not isATMStillValid() then return false end
        return #(GetEntityCoords(PlayerPedId()) - atmCoords) < 2.5
    end, function(worldPos)
        OpenATMBankInterface(atmCoords, atmHeading)
    end, { icon = 'credit-card' }, nil, nil)

    VFW.ContextAddPositionButton(positionId, ":unlock: Braquer l'ATM", function()
        if not isATMStillValid() then return false end
        if not HasATMHackItem() then return false end
        return #(GetEntityCoords(PlayerPedId()) - atmCoords) < 2.5
    end, function(worldPos)
        StartATMHack(atmNetId, atmCoords, atmHeading)
    end, { icon = 'mask' }, nil, nil)

    registeredPositions[atmData.id] = positionId
    -- print("[ATM] Zone ATM custom enregistrée: " .. (atmData.name or "ATM") .. " (ID: " .. atmData.id .. ")")

    return positionId
end

-- ============================================
-- ADMIN MODE (Affichage des zones vertes)
-- ============================================

--- Dessine le texte 3D
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

--- Dessine les markers admin pour les zones ATM
local function DrawAdminMarkers()
    local playerCoords = GetEntityCoords(PlayerPedId())

    for _, atmData in ipairs(customATMPositions) do
        if atmData.active ~= false and atmData.active ~= 0 then
            local atmPos = vector3(atmData.x, atmData.y, atmData.z)
            local dist = #(playerCoords - atmPos)

            if dist < 100.0 then
                local heading = atmData.heading or 0.0

                -- Box verte semi-transparente
                DrawMarker(1,
                    atmData.x, atmData.y, atmData.z + (ATM_BOX.height / 2),
                    0.0, 0.0, 0.0,
                    0.0, 0.0, heading,
                    ATM_BOX.width, ATM_BOX.depth, ATM_BOX.height,
                    0, 255, 0, 80,
                    false, false, 2, false, nil, nil, false
                )

                -- Flèche jaune (direction)
                local rad = math.rad(heading)
                local arrowX = atmData.x - math.sin(rad) * 1.0
                local arrowY = atmData.y + math.cos(rad) * 1.0
                DrawMarker(2,
                    arrowX, arrowY, atmData.z + 0.5,
                    0.0, 180.0, 0.0,
                    0.4, 0.4, 0.4,
                    255, 255, 0, 200,
                    true, false, 2, false, nil, nil, false
                )

                -- Texte
                if dist < 15.0 then
                    DrawText3D(atmData.x, atmData.y, atmData.z + ATM_BOX.height + 0.5,
                        (atmData.name or "ATM Custom") .. " (ID: " .. atmData.id .. ")")
                end
            end
        end
    end
end

-- Thread pour afficher les markers en mode admin
CreateThread(function()
    while true do
        if adminMode and #customATMPositions > 0 then
            DrawAdminMarkers()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ============================================
-- SYNCHRONISATION AVEC LE SERVEUR
-- ============================================

--- Force le refresh complet des ATM customs
local function ForceRefreshATMPositions()
    -- D'abord désenregistrer TOUTES les anciennes positions
    UnregisterAllPositions()

    -- Puis réenregistrer seulement celles qui existent encore
    local count = 0
    for _, atmData in ipairs(customATMPositions) do
        if atmData.active ~= false and atmData.active ~= 0 then
            if RegisterATMPosition(atmData) then
                count = count + 1
            end
        end
    end

    -- print("[ATM] Refresh complet: " .. count .. " zones ATM custom actives")
end

-- Event principal de synchronisation (reçu de tous les clients)
RegisterNetEvent("core:atm:syncCustomPositions")
AddEventHandler("core:atm:syncCustomPositions", function(positions)
    -- Sauvegarder l'ancien count pour détecter les changements
    local oldCount = #customATMPositions

    -- Mettre à jour la liste (toujours, même si vide)
    customATMPositions = positions or {}

    local newCount = #customATMPositions
    -- print("[ATM] Sync reçu: " .. oldCount .. " -> " .. newCount .. " positions ATM custom")

    -- Toujours rafraîchir les positions (important pour les suppressions!)
    ForceRefreshATMPositions()
end)

-- Event de confirmation de sync (pour l'admin qui a fait l'action)
RegisterNetEvent("core:atm:syncComplete")
AddEventHandler("core:atm:syncComplete", function()
    -- print("[ATM] Synchronisation complète confirmée par le serveur")
    -- Forcer un refresh du menu builder si ouvert
    if StaffMenu and StaffMenu.ListCustomATMsMenu and StaffMenu.ListCustomATMsMenu.isOpen then
        StaffMenu.ListCustomATMsMenu.refresh()
    end
end)

-- Charger les ATM customs au démarrage
CreateThread(function()
    Wait(5000)
    local positions = TriggerServerCallback("core:atm:getCustomPositions")
    if positions then
        customATMPositions = positions
        -- print("[ATM] Chargé " .. #customATMPositions .. " positions ATM custom au démarrage")
        ForceRefreshATMPositions()
    else
        customATMPositions = {}
        -- print("[ATM] Aucun ATM custom trouvé au démarrage")
    end
end)

-- ============================================
-- EXPORTS POUR LE MENU ADMIN
-- ============================================

exports("GetCustomATMPositions", function()
    return customATMPositions
end)

exports("SetATMAdminMode", function(enabled)
    adminMode = enabled
    -- print("[ATM] Mode admin: " .. tostring(enabled))
end)

exports("IsATMAdminMode", function()
    return adminMode
end)

exports("RefreshATMPositions", function()
    -- Recharger depuis le serveur et refresh
    local positions = TriggerServerCallback("core:atm:getCustomPositions")
    if positions then
        customATMPositions = positions
    else
        customATMPositions = {}
    end

    -- Désenregistrer toutes les anciennes positions
    UnregisterAllPositions()

    -- Réenregistrer les positions actives
    local count = 0
    for _, atmData in ipairs(customATMPositions) do
        if atmData.active ~= false and atmData.active ~= 0 then
            if RegisterATMPosition(atmData) then
                count = count + 1
            end
        end
    end
    -- print("[ATM] Export RefreshATMPositions: " .. count .. " zones rafraîchies")
end)

-- COMMANDE SUPPRIMÉE : /atm_admin

-- ============================================
-- POLICE ALERTS
-- ============================================

RegisterNetEvent("core:atm:policeAlert", function(atmPos)
    if VFW.PlayerData and VFW.PlayerData.job and IsPoliceJob and IsPoliceJob(VFW.PlayerData.job.name) then
        VFW.ShowNotification({ type = 'ILLEGAL', message = "Alerte: Piratage d'ATM en cours" })

        local blip = AddBlipForCoord(atmPos.x, atmPos.y, atmPos.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 1)
        SetBlipRoute(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Piratage ATM")
        EndTextCommandSetBlipName(blip)

        SetTimeout((Config.ATM_PoliceBlipDuration or 300) * 1000, function()
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end)
    end
end)

-- ============================================
-- CLEANUP
-- ============================================

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        UnregisterAllPositions()
        adminMode = false
    end
end)
