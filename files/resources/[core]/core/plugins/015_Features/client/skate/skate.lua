--[[
    BDX-Skate - Client-side Skateboarding System
    Gère les mécaniques de skateboard, les tricks, le shop et les animations côté client

    Fichier déobfusqué par Claude - Structure complète restaurée
]]

--[[============================================================================
    SECTION 1: VARIABLES D'ÉTAT GLOBALES
    Flags et états utilisés dans tout le script
==============================================================================]]

-- Flags d'état du joueur
local isRotating = false          -- Le joueur effectue une rotation en l'air
local isHighSpeed = false         -- Le joueur est en pose haute vitesse
local isPlayingSpeedSound = false -- Le son de vitesse est en cours
local isPickingUp = false         -- Le joueur ramasse le skateboard
local isBoardPlaced = false       -- Le skateboard est posé au sol

-- Variables d'état du skateboard (anciennement globales implicites)
local Breaking = false
local Stand = false
local Regular = true
local Static = true
local Attach = false
local PerformingCoffin = false
local effect = false

--[[============================================================================
    SECTION 2: CHEMINS DES FICHIERS AUDIO
    Définition des sons et musiques du jeu
==============================================================================]]

local SOUND_LAND = "nui://core/stream/[Sounds]/Land.MP3"
local SOUND_OLLIE = "nui://core/stream/[Sounds]/Ollie.MP3"
local SOUND_SPEED = "nui://core/stream/[Sounds]/Speed.MP3"
local SOUND_BREAK = "nui://core/stream/[Sounds]/Break.MP3"
local SOUND_SPEEDSTEP = "nui://core/nui/streamnds/SpeedStep.MP3"

-- Musiques de fond
local MUSIC_1 = "nui://BDX-Skate/nui/music/LAADS-LoveYou.mp3"
local MUSIC_2 = "nui://BDX-Skate/nui/music/MaxBrhon-AIMidtempo.mp3"
local MUSIC_3 = "nui://BDX-Skate/nui/music/Rameses&Veela-NeverKnewMe.mp3"
local MUSIC_4 = "nui://BDX-Skate/nui/music/RobbieMendez-HomeHouse.mp3"
local MUSIC_5 = "nui://BDX-Skate/nui/music/Ghostnaps-GrowApartGarage.mp3"

-- Sons de score
local SOUND_SCORE = "nui://BDX-Skate/nui/sounds/Score.mp3"
local SOUND_MISS = "nui://BDX-Skate/nui/sounds/MissScore.mp3"

--[[============================================================================
    SECTION 3: VARIABLES DE JEU
    États des tricks et du score
==============================================================================]]

local currentScore = 0            -- Score actuel du joueur
local isDoingAirTrick = false     -- Un trick aérien est en cours
local isPlayingAirAnim = false    -- L'animation aérienne est en cours
local isDoingSpeedStep = false    -- Le speed step est en cours
local isJumping = false           -- Le joueur est en train de sauter
local isConnectedToBoard = false  -- Le joueur est connecté au skateboard
local isDoingGrabTrick = false    -- Un grab trick est en cours
local isDoingManual = false       -- Un manual est en cours
local waitTime = 2000             -- Délai entre les vérifications (ms)

--[[============================================================================
    SECTION 4: MODÈLES DE SKATEBOARD
    Noms des modèles pour les styles modern et classic
==============================================================================]]

-- Modèles Modern
--local modernDeck = "board_1"
--local modernTrucks = "trucks_2"
--local modernWheels = "wheels_10"
--
---- Modèles Classic
--local classicDeck = "c_deck_1"
--local classicTrucks = "c_trucks_2"
--local classicWheels = "c_wheels_10"
-- Modèles Modern
local modernDeck = "board_1"
local modernTrucks = "board_1"
local modernWheels = "board_1"

-- Modèles Classic
local classicDeck = "board_1"
local classicTrucks = "board_1"
local classicWheels = "board_1"

-- Style actuel (modern ou classic)
local skateStyle = "modern"

--[[============================================================================
    SECTION 5: MODULE PRINCIPAL SKATING
    Table contenant toutes les méthodes du système de skateboard
==============================================================================]]

local Skating = {}


--[[============================================================================
    SECTION 6: VARIABLES UI/MENU
    États de l'interface utilisateur
==============================================================================]]

local isMenuOpen = false          -- Le menu du shop est ouvert
local currentShopName = nil       -- Nom du shop actuel
local isLoading = false           -- Chargement en cours

-- Dernière animation de trick jouée (pour la synchronisation)
local lastTrickAnim = nil

--[[============================================================================
    SECTION 7: TABLE DES TRICKS
    Définition de tous les tricks disponibles dans le jeu
==============================================================================]]

SkateTricks = {
    -- Trick 1: Shuvit
    {
        type = "Trick",
        label = "Skate: Rotation planche",
        dict = "bodhix@skate@anims",
        animin = "kick_ln",
        animout = "kick_out",
        flag = 65546,
        trickin = "shuvit",
        trickout = "",
        animidle = "",
        score = 300
    },
    -- Trick 2: KickFlip
    {
        type = "Trick",
        label = "Skate: Flip latéral",
        dict = "bodhix@skate@anims",
        animin = "kick_ln",
        animout = "kick_out",
        flag = 65546,
        trickin = "kickflip",
        trickout = "",
        animidle = "",
        score = 350
    },
    -- Trick 3: LaserFlip
    {
        type = "Trick",
        label = "Skate: Flip laser",
        dict = "bodhix@skate@anims",
        animin = "kick_ln",
        animout = "kick_out",
        flag = 65546,
        trickin = "laserflip",
        trickout = "",
        animidle = "",
        score = 400
    },
    -- Trick 4: TreFlip
    {
        type = "Trick",
        label = "Skate: Triple flip",
        dict = "bodhix@skate@anims",
        animin = "kick_ln",
        animout = "kick_out",
        flag = 65546,
        trickin = "treflip",
        trickout = "",
        animidle = "",
        score = 450
    },
    -- Trick 5: Impossible
    {
        type = "Trick",
        label = "Skate: L'impossible",
        dict = "bodhix@skate@anims",
        animin = "kick_ln",
        animout = "kick_out",
        flag = 65546,
        trickin = "impossible",
        trickout = "",
        animidle = "",
        score = 600
    },
    -- Trick 6: ForwardFlip
    {
        type = "Trick",
        label = "Skate: Salto avant",
        dict = "bodhix@skate@anims",
        animin = "kick_ln",
        animout = "kick_out",
        flag = 65546,
        trickin = "forwardflip",
        trickout = "",
        animidle = "",
        score = 500
    },
    -- Trick 7: Christ Air (Trick aérien)
    {
        type = "Air",
        label = "Skate: Pose en croix",
        dict = "bodhix@skate@anims",
        animin = "t_pose_start",
        animout = "t_pose_end",
        flag = 65546,
        trickin = "christ_start",
        trickout = "christ_end",
        animidle = "",
        score = 750
    },
    -- Trick 8: RocketAir Grab (Trick aérien)
    {
        type = "Air",
        label = "Skate: Fusée aérienne",
        dict = "bodhix@skate@anims",
        animin = "rocket_pose_start",
        animout = "rocket_pose_end",
        flag = 65546,
        trickin = "rocket_start",
        trickout = "rocket_end",
        animidle = "",
        score = 650
    },
    -- Trick 9: Nose Manual
    {
        type = "Manual",
        label = "Skate: Équilibre avant",
        dict = "bodhix@skate@anims",
        animin = "p_nose_manual_start",
        animout = "p_nose_manual_end",
        flag = 131080,
        trickin = "nose_manual_start",
        trickout = "nose_manual_end",
        animidle = "nose_manual_pose",
        score = 100
    },
    -- Trick 10: Manual
    {
        type = "Manual",
        label = "Skate: Équilibre arrière",
        dict = "bodhix@skate@anims",
        animin = "p_nose_manual_end",
        animout = "p_manual_end",
        flag = 131080,
        trickin = "manual_start",
        trickout = "manual_end",
        animidle = "manual_pose",
        score = 100
    },
    -- Trick 11: Speed (au sol)
    {
        type = "Floor",
        label = "Skate: Accélération",
        dict = "bodhix@skate@anims",
        animin = "",
        animout = "",
        flag = 65546,
        trickin = "SkateVelocity",
        trickout = "",
        animidle = "",
        score = 0
    },
    -- Trick 12: Coffin (au sol)
    {
        type = "Floor",
        label = "Skate: Position allongée",
        dict = "bodhix@skate@anims",
        animin = "",
        animout = "",
        flag = 65546,
        trickin = "Coffin",
        trickout = "",
        animidle = "",
        score = 250
    }
}


-- ============================================
-- SISTEMA DE NOTIFICACIONES EN PANTALLA (Instructional Buttons)
-- ============================================

local skateInstructionalButtonId = generateUniqueID() -- Asegúrate de que generateUniqueID() esté disponible
local instructionalButtons = instructionalButtons or {} -- Asegúrate de tener una tabla global donde se almacenen las indicaciones

Skating.UI = {
    Show = function(buttons)
        -- Asigna la lista de botones al ID único
        instructionalButtons[skateInstructionalButtonId] = buttons
    end,

    Hide = function()
        -- Oculta las indicaciones asignando una tabla vacía
        instructionalButtons[skateInstructionalButtonId] = {}
    end
}

--[[============================================================================
    SECTION 8: CALLBACKS NUI - LANGUE
    Récupération de la ConfigNewSkateuration de langue pour l'interface
==============================================================================]]

RegisterNUICallback("getLanguage", function(data, cb)
    cb(ConfigNewSkate.Language.Menu)
end)

--[[============================================================================
    SECTION 9: FONCTIONS UTILITAIRES
    Fonctions helper utilisées dans tout le script
==============================================================================]]

--[[
    LoadAnimDict
    Charge un dictionnaire d'animation et attend qu'il soit prêt

    @param animDict - Nom du dictionnaire d'animation à charger
]]
function LoadAnimDict(animDict)
    local attempts = 0
    RequestAnimDict(animDict)

    while not HasAnimDictLoaded(animDict) do
        attempts = attempts + 1
        if attempts > 500 then
            --print("ERROR: Something happened while trying to load a bike trick.")
            break
        end
        Wait(0)
    end
end

--[[
    CanRide
    Vérifie si le joueur peut monter sur le skateboard

    @return boolean - true si le joueur peut monter
]]
function CanRide()
    local playerPed = PlayerPedId()

    if IsPedOnFoot(playerPed) then
        -- Vérifier que le joueur n'est pas dans un état qui empêche le skateboard
        local isSwimming = IsPedSwimming(playerPed)
        local isInVehicle = IsPedInAnyVehicle(playerPed, false)
        local isClimbing = IsPedClimbing(playerPed)
        local isVaulting = IsPedVaulting(playerPed)
        local isRagdoll = IsPedRagdoll(playerPed)

        return not isRagdoll and not isSwimming and not isInVehicle and not isClimbing and not isVaulting
    end

    return false
end

--[[
    StopSkateAnimations
    Arrête toutes les animations de skateboard en cours sur le joueur
]]
function StopSkateAnimations()
    local playerPed = PlayerPedId()
    local animDict = "bodhix@skate@anims"

   local animations = {
        "stand_pose",
        "pre_jump_loop",
        "rail_pose",
        "speed_pose",
        "restpose_idle",
        "restpose_in",
        "restpose_out",
        "restpose_reverse",
        "backguards_idle"
   }

    for _, anim in ipairs(animations) do
        StopAnimTask(playerPed, animDict, anim, 1.0)
    end
end

--[[
    Vmag
    Calcule la magnitude (longueur) d'un vecteur de vélocité

    @param velocity - Vecteur3 de vélocité
    @return number - Magnitude du vecteur
]]
function Vmag(velocity)
    return math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
end

--[[============================================================================
    SECTION 10: EVENT DE DÉMARRAGE DU SKATEBOARD
    Déclenché quand le joueur utilise l'item skateboard
==============================================================================]]

local visualProp = nil
IsSkateOnBack = false
local autoPlaceOnGround = false

-- Exclure le cruiser (véhicule invisible du skate) du context menu vehicle
VFW.ContextExcludeModel("vehicle", "cruiser")

-- Bouton custom "Sortir" = poser le skate directement au sol (sans passer par le dos)
VFW.Inventory.ContextMenu.AddButton("skateboard", {
    id = "sortir",
    label = "Sortir",
    icon = ":arrow:",
    event = "skating:client:start",
    serverEvent = "skating:server:removeSkateItem",
    order = 2
})

-- Dynamiquement : renommer "Utiliser" et gérer la visibilité de "Sortir" selon l'état
-- Pas sur le dos → "Utiliser" = "Mettre sur le dos", "Sortir" visible
-- Sur le dos     → "Utiliser" = "Ranger",            "Sortir" masqué
local lastSkateOnBack = nil
Citizen.CreateThread(function()
    while true do
        if IsSkateOnBack ~= lastSkateOnBack then
            lastSkateOnBack = IsSkateOnBack
            if IsSkateOnBack then
                VFW.Inventory.ContextMenu.RenameButton("skateboard", "use", "Ranger")
                VFW.Inventory.ContextMenu.RemoveButton("skateboard", "sortir")
            else
                VFW.Inventory.ContextMenu.RenameButton("skateboard", "use", "Mettre sur le dos")
                VFW.Inventory.ContextMenu.RestoreButton("skateboard", "sortir")
            end
        end
        Wait(500)
    end
end)

-- Context menu "Récupérer le skate" sur le véhicule (cruiser invisible) au sol
VFW.ContextAddButton("vehicle", " Récupérer le skate", function(vehicle)
    if not Skating.Entities or not DoesEntityExist(Skating.Entities) then return false end
    if vehicle ~= Skating.Entities then return false end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    return dist < 3.0 and not isConnectedToBoard
end, function(vehicle)
    local ped = PlayerPedId()
    RequestAnimDict("random@domestic")
    while not HasAnimDictLoaded("random@domestic") do Wait(0) end
    TaskPlayAnim(ped, "random@domestic", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(1000)
    ClearPedTasks(ped)
    Skating.Clear()
    TriggerServerEvent("skating:server:pickupSkate")
end, nil, nil, { ignoreExclusion = true })

-- Context menu "Mettre sur le dos" sur le véhicule (cruiser invisible) au sol
VFW.ContextAddButton("vehicle", " Mettre sur le dos", function(vehicle)
    if not Skating.Entities or not DoesEntityExist(Skating.Entities) then return false end
    if vehicle ~= Skating.Entities then return false end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    return dist < 3.0 and not isConnectedToBoard and not IsSkateOnBack
end, function(vehicle)
    local ped = PlayerPedId()
    RequestAnimDict("random@domestic")
    while not HasAnimDictLoaded("random@domestic") do Wait(0) end
    TaskPlayAnim(ped, "random@domestic", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(1000)
    ClearPedTasks(ped)
    Skating.Connect("pickupskateboard")
end, nil, nil, { ignoreExclusion = true })

RegisterNetEvent("skating:client:start")
AddEventHandler("skating:client:start", function()
    if visualProp and DoesEntityExist(visualProp) then
        DeleteEntity(visualProp)
        visualProp = nil
        IsSkateOnBack = false
    end
    local ped = PlayerPedId()
    RequestAnimDict("random@domestic")
    while not HasAnimDictLoaded("random@domestic") do Wait(0) end
    TaskPlayAnim(ped, "random@domestic", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(1000)
    ClearPedTasks(ped)
    autoPlaceOnGround = true
    Skating.Start()
end)

function SpawnVisualSkate(ped)
    local playerPed = ped
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    -- Calculamos el spawn igual que en tu Skating.Spawn para que el objeto se cree "bien"
   local forwardVector = GetEntityForwardVector(playerPed) * 2.0
    local spawnCoords = playerCoords + forwardVector

    local deckModel = currentSkateModel or "board_1"

   -- Cargar modelo
    RequestModel(GetHashKey(deckModel))
    while not HasModelLoaded(GetHashKey(deckModel)) do Wait(0) end

    -- Crear el objeto en la misma posición relativa que el funcional
    visualProp = VFW.OneSync.CreateObject(deckModel, spawnCoords)

    -- TUS VALORES EXACTOS DE ATTACH
    AttachEntityToEntity(
            visualProp,
            playerPed,
            GetPedBoneIndex(playerPed, 24818),
            0.05, -0.17, -0.01,    -- Posición
            -87.00, 234.00, -4.00, -- Rotación
            true, true, false, true, 1, true
    )

    -- Animation de rangement
    LoadAnimDict("bodhix@skate@anims")
    TaskPlayAnim(playerPed, "bodhix@skate@anims", "saveboard", 8.0, -8.0, 1500, 49, 0, false, false, false)

    IsSkateOnBack = true
end

RegisterNetEvent("skating:client:manager")
AddEventHandler("skating:client:manager", function(mode)
    local ped = PlayerPedId()

    if mode == "visual" then
        if Skating.Entities and DoesEntityExist(Skating.Entities) then
            Skating.Clear()
            Wait(100)
            SpawnVisualSkate(ped)
        elseif visualProp and DoesEntityExist(visualProp) then
            DeleteEntity(visualProp)
            visualProp = nil
            IsSkateOnBack = false
            VFW.ShowNotification({ type = 'VERT', content = "Skate rangé correctement" })
        else
            SpawnVisualSkate(ped)
        end
    elseif mode == "funcional" then
        if visualProp and DoesEntityExist(visualProp) then
            DeleteEntity(visualProp)
            visualProp = nil
            IsSkateOnBack = false
        end

        if not Skating.Entities or not DoesEntityExist(Skating.Entities) then
            Skating.Start()
        end
    end
end)

--[[============================================================================
    SECTION 11: MÉTHODES DU MODULE SKATING
    Gestion du cycle de vie du skateboard
==============================================================================]]

function Skating.Start()
    -- Vérifier si le skateboard existe déjà
    if Skating.Entities and DoesEntityExist(Skating.Entities) then
        -- Skateboard déjà existant, continuer
        return  -- :check: FIX: evitar duplicados
    elseif not CanRide() then
        return
    end

    -- Spawner le skateboard
    Skating.Spawn()

    -- Auto-placer au sol si demandé (depuis le context menu "Sortir le skate")
    if autoPlaceOnGround then
        autoPlaceOnGround = false
        Skating.Connect("placeskateboard")
        Wait(100)
        Skating.ConnectPlayer(true)
    end

    -- Boucle principale de gestion du skateboard
    while DoesEntityExist(Skating.Entities) and DoesEntityExist(Skating.Player) do
        local delayMs = 100
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local boardCoords = GetEntityCoords(Skating.Entities)
        local distance = #(playerCoords - boardCoords)

        local hasWater, waterZ = GetWaterHeight(boardCoords.x, boardCoords.y, boardCoords.z)
        if hasWater and waterZ and boardCoords.z - waterZ < 1.0 then
            Skating.Clear()
            break
        end

        if GetEntitySubmergedLevel(Skating.Entities) > 0.0 or IsPedSwimming(playerPed) then
            Skating.Clear()
            break
        end

        if distance <= ConfigNewSkate.LoseConnectionDistance then
            delayMs = 10

            Skating.HandleKeys(distance)

            if not NetworkHasControlOfEntity(Skating.Player) then
                NetworkRequestControlOfEntity(Skating.Player)
            elseif not NetworkHasControlOfEntity(Skating.Entities) then
                NetworkRequestControlOfEntity(Skating.Entities)
            end
        else
            TaskVehicleTempAction(Skating.Player, Skating.Entities, 6, 2500)
        end

        Wait(delayMs)
    end
end


--[[
    Skating.MustRagdoll
    Vérifie si le joueur doit passer en ragdoll (chute)

    @return boolean - true si le joueur doit ragdoll
]]
function Skating.MustRagdoll()
    local boardEntity = Skating.Entities

    -- Vérifier que le skateboard existe
    if not boardEntity or not DoesEntityExist(boardEntity) then
        --print(":x: No Skating.Entities")
        return false
    end

    local playerPed = PlayerPedId()
    local rotX, rotY = table.unpack(GetEntityRotation(boardEntity, 2))
    local speed = GetEntitySpeed(boardEntity) * 3.6  -- Convertir en km/h
   local heightAboveGround = GetEntityHeightAboveGround(Skating.Deck)


    local hasCollided = HasEntityCollidedWithAnything(playerPed)
    local isDead = IsPedDeadOrDying(playerPed, false)

    -- Ragdoll si mort ou collision à haute vitesse
    if isDead or (hasCollided and speed > 5.0) then
        return true
    end

    -- Ragdoll si trop haut ou rotation excessive
    if heightAboveGround > ConfigNewSkate.maxFallSurvival then
        return true
    end

    if rotX > 180.0 or rotX < -180.0 then
        if IsEntityInAir(boardEntity) and speed < 5.0 then
            return true
        end
    end

    -- Ragdoll si proche du sol pendant certains tricks
    if heightAboveGround < 0.8 and isDoingGrabTrick then
        return true
    end

    if heightAboveGround < 0.6 and isPlayingAirAnim then
        return true
    end

    return false
end

--[[
    Skating.Restore
    Restaure l'état normal du joueur après un trick
]]
function Skating.Restore()
    isJumping = false
    isDoingGrabTrick = false
    isDoingManual = false
    isDoingAirTrick = false

    -- Synchroniser l'animation de repos avec le serveur
    TriggerServerEvent("Skating-sv:SyncTrick", "stand")

    -- Arrêter les animations de skate
    StopSkateAnimations()
end

--[[============================================================================
    SECTION 12: THREAD PRINCIPAL - CONTRÔLES ET INTERACTIONS
    Gère les touches de contrôle du skateboard
==============================================================================]]

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(waitTime)
        local playerPed = PlayerPedId()

        -- Si el skate existe
        if Skating.Deck and DoesEntityExist(Skating.Deck) then
            waitTime = 0 -- Respuesta rápida
            local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(Skating.Deck))

            -- ============================================
            -- LÓGICA DEL UI HELPER
            -- ============================================

            -- CASO 1: MONTADO EN EL SKATE (isConnectedToBoard)
            if isConnectedToBoard then
                Skating.UI.Show({
                    { control = 23, label = "Descendre du skate" }, -- F
                    { control = 22, label = "Sauter" }             -- ESPACE
                })

                -- CASO 2: SKATE EN LA ESPALDA (IsSkateOnBack)
            elseif IsSkateOnBack then
                Skating.UI.Show({
                    { control = 23, label = "Poser le skate par terre" } -- F
                })

                -- CASO 3: SKATE EN EL SUELO (CERCA)
            elseif not isConnectedToBoard and not IsSkateOnBack and dist < 2.0 then
                Skating.UI.Show({
                    { control = 23, label = "Monter sur le skate" },  -- F
                    { control = 47, label = "Récupérer le skate" },   -- G
                    { control = 74, label = "Mettre sur le dos" }     -- H
                })

                -- CASO 4: Ocultar UI
            else
                Skating.UI.Hide()
            end
            -- TECLA F (23): MONTAR / DESMONTAR
            if IsControlJustPressed(0, 23) and not isDoingManual and not IsPedRagdoll(playerPed) then

                if IsSkateOnBack then
                    -- BAJAR DE LA ESPALDA CON ANIMACIÓN (Nuevo Flujo)
                    --print(":arrow: Bajando skate con animación...")
                    local playerPed = PlayerPedId()

                    isPickingUp = true -- Bloquea la acción hasta que termine la animación

                    -- 1. Reproducir animación de sacar de la espalda
                    RequestAnimDict("bodhix@skate@anims")
                    while not HasAnimDictLoaded("bodhix@skate@anims") do Wait(0) end

                    -- Usamos 'unboard_pickup'
                    TaskPlayAnim(playerPed, "bodhix@skate@anims", "unboard_pickup",
                            8.0, -8.0, 1000, 131128, 0, false, false, false)

                    -- 2. Esperar la duración de la animación
                    Wait(700)
                    ClearPedTasksImmediately(playerPed)

                    -- 3. Conectar la tabla al vehículo en el suelo y montar
                    Skating.Connect("placeskateboard") -- Trae el vehículo y pega el deck
                    Wait(100)
                    Skating.ConnectPlayer(true) -- Monta al jugador

                    isPickingUp = false -- Desbloquear la acción

                elseif isConnectedToBoard then
                    -- DESCENDRE DU SKATE : détacher le joueur, le skate continue de rouler
                    if not Breaking and GetEntityHeightAboveGround(Skating.Entities) <= 0.5 then
                        DetachEntity(playerPed, false, true)
                        SetPedRagdollOnCollision(playerPed, false)
                        isConnectedToBoard = false
                        IsSkateOnBack = false
                        isBoardPlaced = true
                        ClearPedTasksImmediately(playerPed)
                        TriggerServerEvent("Skating:DesyncBoard")
                    end

                elseif not isConnectedToBoard and not IsSkateOnBack then
                    -- Si está en el suelo pero no estamos montados (Tu lógica existente)
                    local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(Skating.Deck))
                    if dist < 2.0 then
                        Skating.ConnectPlayer(true)
                    end
                end
            end

            -- G (47) : Récupérer le skate (au sol, proche, pas monté, pas sur le dos)
            if IsControlJustPressed(0, 47) and not isConnectedToBoard and not IsSkateOnBack and not isPickingUp then
                local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(Skating.Deck))
                if dist < 2.0 then
                    isPickingUp = true
                    RequestAnimDict("random@domestic")
                    while not HasAnimDictLoaded("random@domestic") do Wait(0) end
                    TaskPlayAnim(playerPed, "random@domestic", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
                    Wait(1000)
                    ClearPedTasks(playerPed)
                    Skating.Clear()
                    TriggerServerEvent("skating:server:pickupSkate")
                    isPickingUp = false
                end
            end

            -- H (74) : Mettre sur le dos (au sol, proche, pas monté, pas sur le dos)
            if IsControlJustPressed(0, 74) and not isConnectedToBoard and not IsSkateOnBack and not isPickingUp then
                local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(Skating.Deck))
                if dist < 2.0 then
                    isPickingUp = true
                    RequestAnimDict("random@domestic")
                    while not HasAnimDictLoaded("random@domestic") do Wait(0) end
                    TaskPlayAnim(playerPed, "random@domestic", "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
                    Wait(1000)
                    ClearPedTasks(playerPed)
                    Skating.Connect("pickupskateboard")
                    isPickingUp = false
                end
            end

            -- LOGICA DE MOVIMIENTO Y SALTO (Solo si estamos conectados)
            if isConnectedToBoard then
                -- Asegurar que el conductor invisible esté dentro
                if not IsPedInVehicle(Skating.Player, Skating.Entities, false) then
                    TaskWarpPedIntoVehicle(Skating.Player, Skating.Entities, -1)
                end

                -- Mantener código original de saltos y trucos aquí...
                -- (Tu lógica de SPACE / Tricks existente va aquí)
                if IsControlJustPressed(0, 22) and isConnectedToBoard and not isDoingManual then
                    if not IsEntityInAir(Skating.Entities) then
                        isJumping = true

                        -- Vérifier si le joueur est en position de repos
                        local isResting =
                        IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "restpose_idle", 3) or
                                IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "backguards_idle", 3)

                        if isResting then
                            --print(":target: THREAD INPUT → restpose_reverse")
                            TaskPlayAnim(playerPed, "bodhix@skate@anims", "restpose_reverse", 8.0, -8.0, -1, 1, 0, false, false, false)
                            Wait(450)
                        end

                        --print(":target: THREAD INPUT → pre_jump_loop")
                        TaskPlayAnim(playerPed, "bodhix@skate@anims", "pre_jump_loop", 5.0, 8.0, -1, 1, 0, false, false, false)

                        -- Charger la puissance du saut
                        local holdTime = 0
                        while IsControlPressed(0, 22) do
                            Wait(10)
                            holdTime = holdTime + 10
                        end

                        local jumpHeight = math.min((ConfigNewSkate.maxJumpHeigh * holdTime) / 250.0, ConfigNewSkate.maxJumpHeigh)
                        local velocity = GetEntityVelocity(Skating.Entities)

                        if isConnectedToBoard then
                            --print(":target: THREAD INPUT → ollie")
                            TaskPlayAnim(playerPed, "bodhix@skate@anims", "ollie", 8.0, 8.0, -1, 65544, 0.0, false, 4127, false)

                            SetEntityVelocity(Skating.Entities, velocity.x, velocity.y, velocity.z + jumpHeight)
                            PlayAudio2(SOUND_OLLIE)

                            Wait(900)

                            if not IsPedRagdoll(playerPed) and isConnectedToBoard then
                                if not isDoingManual and not isDoingGrabTrick and not isDoingAirTrick then
                                    --print(":target: THREAD INPUT → rail_pose")
                                    TaskPlayAnim(playerPed, "bodhix@skate@anims", "rail_pose", 8.0, -8.0, -1, 1, 0.0, false, false, false)
                                end
                            end

                            while GetEntityHeightAboveGround(Skating.Entities) > 0.7 do
                                if HasEntityCollidedWithAnything(Skating.Entities) then
                                    break
                                end
                                Wait(1)
                            end

                            if not IsPedRagdoll(playerPed) and isConnectedToBoard then
                                if not isDoingAirTrick and not isDoingManual and not isDoingGrabTrick then
                                    --print(":target: THREAD INPUT → stand_pose (landing)")
                                    TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
                                    PlayAudio2(SOUND_LAND)
                                end
                            end
                        end

                        isJumping = false
                    end
                end
            else
                -- Si no estamos montados, esperar un poco más para ahorrar recursos
                if IsSkateOnBack then waitTime = 10 end
            end

        else
            waitTime = 1000
        end
    end
end)


--[[============================================================================
    SECTION 13: THREAD - GESTION DES ANIMATIONS DE VITESSE
    Gère les poses du joueur selon la vitesse du skateboard
==============================================================================]]

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(waitTime)

        -- Skip si pas de skate actif
        if not Skating.Entities or not DoesEntityExist(Skating.Entities) then
            goto continue_section13
        end

        -- Mort du joueur → nettoyer le skate (pas de return, le thread continue)
        if IsPedDeadOrDying(PlayerPedId(), false) then
            Skating.Restore()
            isConnectedToBoard = false
            Skating.Clear()
            goto continue_section13
        end

        -- Collision forte à haute vitesse
        do
            local velocity = GetEntityVelocity(Skating.Entities)
            local speed = Vmag(velocity)

            if HasEntityCollidedWithAnything(Skating.Entities) and speed > 10.0 then
                isConnectedToBoard = false
                isJumping = false
                isDoingManual = false
                isDoingGrabTrick = false
                isDoingAirTrick = false

                TaskPlayAnim(PlayerPedId(), "ragdoll@human", "fall_front", 8.0, -8.0, -1, 1, 0, false, false, false)
                Skating.Clear()
                goto continue_section13
            end
        end

        do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local boardCoords = GetEntityCoords(Skating.Entities)
        local distance = #(playerCoords - boardCoords)
        local velocity = GetEntityVelocity(Skating.Entities)
        local speed = Vmag(velocity)

        if distance < ConfigNewSkate.LoseConnectionDistance and isConnectedToBoard then

            --print("THREAD VELOCIDAD → speed:", speed, "isJumping:", isJumping)

            SetEntityInvincible(Skating.Entities, true)
            StopCurrentPlayingAmbientSpeech(playerPed)

            if not IsEntityInAir(Skating.Entities) and not isJumping and not isPickingUp
                    and not isDoingManual and not isDoingGrabTrick and not Breaking
                    and not isDoingSpeedStep and not isDoingAirTrick then
                if not IsSkateOnBack then
                    if not IsControlPressed(0, 33) and not IsControlPressed(0, 22) then

                        -- :check: RETURN 1
                        if Breaking then
                            --print(":x: RETURN 1 → Breaking = true (mató el thread)")
                            --return
                        end

                        -- Ahora sí, las animaciones de velocidad
                        if speed < 1.0 then
                            if not Stand then
                                if not IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "coffin_in", 3) then
                                    Stand = true

                                    if not IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "restpose_idle", 3) then

                                        Wait(450)
                                        StopAudio(1)

                                        -- :check: RETURN 2
                                        if isDoingManual or isDoingGrabTrick or isDoingSpeedStep
                                                or isDoingAirTrick or isPickingUp or not isConnectedToBoard then
                                            --print(":x: RETURN 2 → Estado bloqueante después de restpose_idle")
                                            --return
                                        end

                                        Static = true
                                    end

                                    isHighSpeed = false
                                    Regular = false
                                end
                            end

                        elseif speed >= 1.0 and speed < 7.0 then
                            if not Regular then
                                if not IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "coffin_in", 3) then
                                    Regular = true
                                    isHighSpeed = false
                                    Stand = false

                                    if Static then
                                        --print(":target: THREAD VELOCIDAD → Ejecutando restpose_out")
                                        TaskPlayAnim(playerPed, "bodhix@skate@anims", "restpose_out", 8.0, 2.0, -1, 1, 1.0, false, false, false)
                                        Static = false
                                    end

                                    PlayAudio(SOUND_SPEED)
                                    Wait(950)

                                    -- :check: RETURN 3
                                    if  isDoingManual or isDoingGrabTrick or isDoingSpeedStep
                                            or isDoingAirTrick or isPickingUp or not isConnectedToBoard then

                                        -- Si entramos aquí, el estado es bloqueante (p. ej., te desconectaste).
                                        -- Simplemente no hacemos nada y el hilo continuará.

                                    else
                                        -- Solo si el estado NO es bloqueante, aplicamos la pose de stand
                                        --print(":target: THREAD VELOCIDAD → Ejecutando stand_pose")
                                        TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
                                    end

                                end
                            end

                        elseif speed > 7.0 then
                            if not isHighSpeed then
                                if not IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "coffin_in", 3) then
                                    isHighSpeed = true
                                    Regular = false
                                    Stand = false

                                    -- :check: RETURN 4
                                    -- :check: RETURN 4 (CORREGIDO con else)
                                    if isJumping or isDoingManual or isDoingGrabTrick or isDoingSpeedStep
                                            or isDoingAirTrick or isPickingUp or not isConnectedToBoard then
                                        --print(":x: RETURN 4 → Estado bloqueante antes de speed_pose. Saltando.")
                                        -- return <-- ¡ELIMINADO!
                                    else
                                        --print(":target: THREAD VELOCIDAD → Ejecutando speed_pose")
                                        TaskPlayAnim(playerPed, "bodhix@skate@anims", "speed_pose", 5.0, 8.0, -1, 1, 0, false, false, false)
                                    end

                                    --print(":target: THREAD VELOCIDAD → Ejecutando speed_pose")
                                    TaskPlayAnim(playerPed, "bodhix@skate@anims", "speed_pose", 5.0, 8.0, -1, 1, 0, false, false, false)
                                end
                            end
                        end
                    end

                end
            end
        end
        end -- ferme le do block
        ::continue_section13::
    end
end)


--[[============================================================================
    SECTION 14: SKATING.HANDLEKEYS
    Gère les contrôles de direction du skateboard
==============================================================================]]

function Skating.HandleKeys(distance)
    local playerPed = PlayerPedId()

    -- Lire les contrôles de direction
    local forward = IsControlPressed(0, 32)   -- W
    local backward = IsControlPressed(0, 33)  -- S
    local left = IsControlPressed(0, 34)      -- A
    local right = IsControlPressed(0, 35)     -- D
    local sprint = IsControlPressed(0, 21)    -- Shift

    local velocity = GetEntityVelocity(Skating.Entities)
    local speed = Vmag(velocity)

    --print((":search: [HandleKeys] → Speed: %.2f | F:%s B:%s L:%s R:%s Sprint:%s | Connected:%s"):format(
    --        speed,
    --        tostring(forward),
    --        tostring(backward),
    --        tostring(left),
    --        tostring(right),
    --        tostring(sprint),
    --        tostring(isConnectedToBoard)
    --))

    ----------------------------------------------------------------------
    -- FREINAGE (S)
    ----------------------------------------------------------------------
    if backward and isConnectedToBoard and not isJumping and not isDoingManual then

        --print(" [HandleKeys] → Freinage detectado (S)")

        if not Breaking then
            Breaking = true

            local brakeAnim = "break_1"
           TaskPlayAnim(playerPed, "bodhix@skate@anims", "p_" .. brakeAnim .. "_in", 8.0, 8.0, -1, 65544, 0.0, false, false, false)
            TriggerServerEvent("Skating-sv:SyncTrick", brakeAnim .. "_in")
            PlayAudio2(SOUND_BREAK)


            while IsControlPressed(0, 33) do
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "p_" .. brakeAnim .. "_idle", 8.0, 8.0, -1, 65544, 0.0, false, false, false)
                TaskVehicleTempAction(Skating.Player, Skating.Entities, 22, 100)
                Wait(50)
            end

            -- Animación de salida
            if isConnectedToBoard then
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "p_" .. brakeAnim .. "_out", 8.0, 8.0, -1, 65544, 0.0, false, false, false)
                TriggerServerEvent("Skating-sv:SyncTrick", brakeAnim .. "_out")
                Wait(150)

                if not isDoingAirTrick and not isDoingManual and not isDoingGrabTrick then
                    TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
                end
            end

            Breaking = false
        end
    end

    ----------------------------------------------------------------------
    -- AVANCE (W)
    ----------------------------------------------------------------------
    if forward and isConnectedToBoard then
        local action = sprint and 30 or 9
        --print(":car: [HandleKeys] → Avanzando (W) | Acción:", action)
        TaskVehicleTempAction(Skating.Player, Skating.Entities, action, 1)
    end

    ----------------------------------------------------------------------
    -- GIRO IZQUIERDA (A)
    ----------------------------------------------------------------------
    if left and isConnectedToBoard then
        local action = sprint and 13 or (forward and 7 or 4)
        --print(":back: [HandleKeys] → Girando IZQUIERDA (A) | Acción:", action)
        TaskVehicleTempAction(Skating.Player, Skating.Entities, action, 1)
    end

    ----------------------------------------------------------------------
    -- GIRO DERECHA (D)
    ----------------------------------------------------------------------
    if right and isConnectedToBoard then
        local action = sprint and 14 or (forward and 8 or 5)
        --print("↪ [HandleKeys] → Girando DERECHA (D) | Acción:", action)
        TaskVehicleTempAction(Skating.Player, Skating.Entities, action, 1)
    end

    ----------------------------------------------------------------------
    -- POSICIÓN DE REPOSO
    ----------------------------------------------------------------------
    if not forward and not backward and not left and not right then
        if speed <= 1.0 and isConnectedToBoard and not isJumping and not isDoingAirTrick
                and not isDoingManual and not isDoingGrabTrick then

            --print(" [HandleKeys] → Entrando en posición de reposo")

            local isRestingIdle = IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "restpose_idle", 3)
            local isRestingIn = IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "restpose_in", 3)

            if not isRestingIdle and not isRestingIn then
                --print(" [HandleKeys] → Reproduciendo restpose_in → restpose_idle")
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "restpose_in", 8.0, 2.0, -1, 1, 1.0, false, false, false)
                Wait(450)
                StopAudio(1)
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "restpose_idle", 8.0, 2.0, -1, 1, 1.0, false, false, false)
            end

            --TaskPlayAnim(playerPed, "bodhix@skate@anims", "backguards_idle", 8.0, 8.0, -1, 1, 0.0, false, false, false)
        end
    end
end


--[[============================================================================
    SECTION 15: SKATING.SPAWN
    Crée le skateboard et le place dans le monde
==============================================================================]]

-- Skating.Place supprimé (code mort, remplacé par Skating.Spawn)

--[[
    Skating.Spawn
    Fonction principale de création du skateboard complet
]]

RegisterNetEvent('skate:client:updateModel', function(modelName)
    currentSkateModel = modelName
    --print("^2[SkateSystem]^7 Modelo actual listo para usar: " .. modelName)
end)

-- ==========================================
-- CALLBACK DE LA TIENDA (NUI -> CLIENT -> SERVER)
-- ==========================================
local purchaseCb = nil

-- Cambiamos 'selectSkate' por 'buySkate' para que React lo encuentre
RegisterNUICallback('nui:SkateShop:buySkate', function(data, cb)
    if data and data.model then
        purchaseCb = cb
        -- Enviamos al servidor VFW
        TriggerServerEvent('skate:server:processPurchase', data.model, data.price, data.method)
    else
        cb({success = false})
    end
end)

-- Evento que recibe la respuesta del servidor y le avisa a React
RegisterNetEvent('skate:client:purchaseResponse', function(success, reason)
    if purchaseCb then
        purchaseCb({success = success, reason = reason})
        purchaseCb = nil
    end
end)

function Skating.Spawn()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed) * 2.0
    local spawnCoords = playerCoords + forwardVector

    -- 1. Cargar Modelos (Solo el Deck dinámico y el Ped)
    local deckModel = currentSkateModel or "board_1"

   -- Limpiamos trucks y wheels, solo cargamos lo necesario
    Skating.LoadModels({
        GetHashKey("cruiser"),
        GetHashKey(deckModel),
        68070371 -- Hash del conductor invisible
    })

    -- 2. Crear Vehículo Invisible (via VFW comme le système BMX)
    Skating.Entities = VFW.Game.SpawnVehicle(GetHashKey("cruiser"), vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z), heading)

    if not Skating.Entities or not DoesEntityExist(Skating.Entities) then
        return
    end

    SetVehicleEngineOn(Skating.Entities, false, true, true)
    SetVehicleUndriveable(Skating.Entities, true)
    SetVehicleSilent(Skating.Entities, true)
    SetEntityVisible(Skating.Entities, false)
    SetEntityCollision(Skating.Entities, false, true)

    -- 3. Crear el Deck (Objeto visual que compraste)
    Skating.Deck = VFW.OneSync.CreateObject(deckModel, spawnCoords)
    SetEntityAsMissionEntity(Skating.Deck, true, true)

    -- 4. Crear Conductor Invisible
    Skating.Player = VFW.OneSync.CreatePed(12, 68070371, spawnCoords, heading)
    SetEntityAsMissionEntity(Skating.Player, true, true)

    -- Desactivar físicas del Ped
    SetEntityCollision(Skating.Player, false, false)
    FreezeEntityPosition(Skating.Player, true)
    SetPedCanRagdoll(Skating.Player, false)
    SetEntityVisible(Skating.Player, false)

    -- 5. Attachments
    TaskWarpPedIntoVehicle(Skating.Player, Skating.Entities, -1)

    -- Attach Deck a la espalda
    AttachEntityToEntity(Skating.Deck, playerPed, GetPedBoneIndex(playerPed, 24818), 0.05, -0.17, -0.01, -87.00, 234.00, -4.00, true, true, false, true, 1, true)

    -- Garder le véhicule invisible près du joueur (ne PAS le mettre sous la map sinon le water check le détruit)
    FreezeEntityPosition(Skating.Entities, true)

    -- 7. Estados
    IsSkateOnBack = true
    isConnectedToBoard = false
    isPickingUp = false

    -- Animación
    LoadAnimDict("bodhix@skate@anims")
    TaskPlayAnim(playerPed, "bodhix@skate@anims", "saveboard", 8.0, -8.0, 1500, 49, 0, false, false, false)

    --print(":check: Spawn completado con el modelo: " .. deckModel)
end


--[[============================================================================
    SECTION 16: SKATING.CONNECT
    Gère la connexion/déconnexion du joueur au skateboard
==============================================================================]]
function PlaceSkateOnGround()
    -- 1. Raycast desde el DECK (el que toca el suelo)
    local x, y, z = table.unpack(GetEntityCoords(Skating.Deck))

    local rayHandle = StartShapeTestRay(
            x, y, z + 1.0,
            x, y, z - 5.0,
            1,
            PlayerPedId(),
            0
    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    if hit then
        -- 2. Ajustar el VEHÍCULO invisible usando la altura detectada
        SetEntityCoords(
                Skating.Entities,
                hitCoords.x,
                hitCoords.y,
                hitCoords.z + 0.02,
                false, false, false, true
        )

        --print(":check: [PlaceSkate] → Ajustado al suelo correctamente (basado en DECK)")
    else
        --print(":x: [PlaceSkate] → No se detectó suelo con raycast")
    end
end




function Skating.Connect(action)
    local playerPed = PlayerPedId()

    if action == "placeskateboard" then
        if not DoesEntityExist(Skating.Entities) then return end

        --print(":arrow: Bajando skate al suelo...")

        -- 1. Desactivar colisión temporalmente para evitar "atropello" al spawnear
        SetEntityCollision(Skating.Entities, false, true)
        SetEntityNoCollisionEntity(Skating.Entities, playerPed, false)

        -- 2. Traer el vehículo invisible a la posición del jugador
        local coords = GetEntityCoords(playerPed)
        local forward = GetEntityForwardVector(playerPed)
        local spawnPos = coords + (forward * 0.5) -- Más cerca (0.5 en vez de 1.0)

        FreezeEntityPosition(Skating.Entities, false)
        SetEntityCoords(Skating.Entities, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
        SetEntityHeading(Skating.Entities, GetEntityHeading(playerPed))
        SetVehicleOnGroundProperly(Skating.Entities)

        -- 3. Despegar de la espalda y pegar al vehículo
        DetachEntity(Skating.Deck, true, true)
        AttachEntityToEntity(Skating.Deck, Skating.Entities, 0, 0.0, 0.0, -0.4, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        isBoardPlaced = true
        IsSkateOnBack = false

        -- NOTA: La colisión se reactivará en ConnectPlayer para seguridad

    elseif action == "pickupskateboard" then
        SetEntityCollision(Skating.Entities, false, true)
        FreezeEntityPosition(Skating.Entities, true)

        DetachEntity(Skating.Deck, true, true)
        AttachEntityToEntity(Skating.Deck, playerPed, GetPedBoneIndex(playerPed, 24818), 0.05, -0.17, -0.01, -87.00, 234.00, -4.00, true, true, false, true, 1, true)

        IsSkateOnBack = true
        isBoardPlaced = false
        isConnectedToBoard = false
    end
end


--[[============================================================================
    SECTION 17: SKATING.CLEAR
    Supprime toutes les entités du skateboard
==============================================================================]]

function Skating.Clear()
    Skating.UI.Hide()

    -- Sauvegarder les refs avant cleanup
    local ents = Skating.Entities
    local deck = Skating.Deck
    local player = Skating.Player

    -- Arrêter les animations d'abord (avant de supprimer les entités)
    StopSkateAnimations()

    -- Détacher avant de supprimer
    if ents and DoesEntityExist(ents) then
        DetachEntity(ents, true, true)
    end

    -- Supprimer les entités (vérifier existence avant chaque suppression)
    if deck and DoesEntityExist(deck) then DeleteEntity(deck) end
    if ents and DoesEntityExist(ents) then DeleteVehicle(ents) end
    if player and DoesEntityExist(player) then DeleteEntity(player) end

    -- Reset des refs entités
    Skating.Entities = nil
    Skating.Deck = nil
    Skating.Player = nil

    -- Notifier le serveur
    TriggerServerEvent("Skating:DesyncBoard", -1)

    -- Réinitialiser tous les états
    Attach = false
    isConnectedToBoard = false
    isPickingUp = false
    isBoardPlaced = false
    IsSkateOnBack = false
    Breaking = false
    waitTime = 2000

    -- Désactiver le ragdoll sur collision
    SetPedRagdollOnCollision(PlayerPedId(), false)
end

--[[============================================================================
    SECTION 18: SKATING.PICKUP ET SKATING.CONNECTPLAYER
    Gestion du ramassage et de la connexion au skateboard
==============================================================================]]

-- Skating.PickUp supprimé (code mort, remplacé par Skating.Clear)

--[[
    Skating.ConnectPlayer
    Connecte ou déconnecte le joueur du skateboard

    @param connect - boolean: true pour connecter, false pour déconnecter
]]
function Skating.ConnectPlayer(connect)
    local playerPed = PlayerPedId()

    --print(":dot-blue: [ConnectPlayer] → Ejecutando función | connect =", connect)

    if connect then
            --print(":check: [ConnectPlayer] → Conectando jugador al skate...")

            isConnectedToBoard = true
        Skating.JustConnected = GetGameTimer()

        isPickingUp = false
            IsSkateOnBack = false

            LoadAnimDict("bodhix@skate@anims")

            --print(":search: [ConnectPlayer] → Validando entidades...")
            --print("  Skating.Entities:", Skating.Entities, "Existe:", DoesEntityExist(Skating.Entities))
            --print("  Skating.Deck:", Skating.Deck, "Existe:", DoesEntityExist(Skating.Deck))

            SetEntityCollision(Skating.Entities, true, true)

            --print(":dot-blue: [ConnectPlayer] → Attaching player to skateboard | Style:", skateStyle)


        AttachEntityToEntity(
                playerPed,
                Skating.Entities,
                0,
                0.0, 0.0, 0.40,
                0.0, 0.0, 0.0,
                true, true, false, true, 1, true
        )

            --print(":check: [ConnectPlayer] → Player ATTACHED al skate")

            --print(":dot-blue: [ConnectPlayer] → Attaching DECK/TRUCKS/WHEELS...")

            -- El deck YA está bien posicionado por PlaceSkate, solo lo pegamos lógico al vehículo
            AttachEntityToEntity(
                    Skating.Deck,
                    Skating.Entities,
                    0,
                    0.0, 0.0, -0.5,
                    0.0, 0.0, 0.0,
                    true, true, false, true, 1, true
            )

            --AttachEntityToEntity(
            --        Skating.Trucks,
            --        Skating.Deck,
            --        0,
            --        0.0, 0.0, 0.0,
            --        0.0, 0.0, 0.0,
            --        true, true, false, true, 1, true
            --)
            --
            --AttachEntityToEntity(
            --        Skating.Wheels,
            --        Skating.Deck,
            --        0,
            --        0.0, 0.0, 0.0,
            --        0.0, 0.0, 0.0,
            --        true, true, false, true, 1, true
            --)

            --print(":check: [ConnectPlayer] → Deck, Trucks y Wheels ATTACHED correctamente")

            TaskPlayAnim(
                    playerPed,
                    "bodhix@skate@anims",
                    "stand_pose",
                    8.0, 2.0, -1, 1, 1.0, false, false, false
            )

            TriggerServerEvent("Skating:SyncBoard",
                    ObjToNet(Skating.Deck)
                    --ObjToNet(Skating.Trucks),
                    --ObjToNet(Skating.Wheels)
            )

            SetPedRagdollOnCollision(playerPed, true)
            --print(":check: [ConnectPlayer] → CONEXIÓN COMPLETA :check:")



    else
        --print(":dot-red: [ConnectPlayer] → DESCONECTANDO jugador del skate...")

        isConnectedToBoard = false
        --print(":dot-blue: Estado: isConnectedToBoard=false")

        --print(":dot-blue: [ConnectPlayer] → Detaching player...")
        DetachEntity(playerPed, false, true)

        --print(":dot-blue: [ConnectPlayer] → Desactivando ragdoll...")
        SetPedRagdollOnCollision(playerPed, false)

        --print(":dot-blue: [ConnectPlayer] → Reproduciendo animación saveboard...")
        isPickingUp = true

        -- [MODIFICACIÓN 1: Usar una duración fija de 1000ms en lugar de -1 (loop)]
        TaskPlayAnim(playerPed, "bodhix@skate@anims", "saveboard",
                8.0, -8.0, 1000, 131128, 0, false, false, false)

        Wait(500)

        --print(":dot-blue: [ConnectPlayer] → Attaching board to BACK | Style:", skateStyle)

        --AttachEntityToEntity(Skating.Deck, playerPed, GetPedBoneIndex(playerPed, 18905),
        --        0.22, 0.0, -0.1,
        --        -25.0, 0.0, 0.0,
        --        true, true, false, true, 1, true)

        IsSkateOnBack = true
        --print(":check: [ConnectPlayer] → Skate ATTACHED al BACK")

        -- [MODIFICACIÓN 2: LÍNEA CLAVE PARA RECUPERAR EL MOVIMIENTO]
        -- Esto cancela inmediatamente todas las tareas del PED (incluida la animación 'saveboard')
        ClearPedTasksImmediately(playerPed)
        --print(":check: Tareas de animación canceladas. Control liberado.")

        -- Detenemos la flag después de liberar el control
        isPickingUp = false

        --print(":dot-blue: [ConnectPlayer] → Desincronizando con el servidor...")
        TriggerServerEvent("Skating:DesyncBoard")

        --print(":check: [ConnectPlayer] → DESCONEXIÓN COMPLETA :check:")
    end
end


--[[============================================================================
    SECTION 19: SKATING.LOADMODELS ET UNLOADMODELS
    Gestion du chargement et déchargement des modèles 3D
==============================================================================]]

function Skating.LoadModels(models)
    --print(":dot-blue: [LoadModels] → Iniciando carga de modelos...")

    for _, model in ipairs(models) do
        --print(":dot-blue: [LoadModels] → Intentando cargar modelo:", model)

        if not IsModelValid(model) then
            --print(":x: [LoadModels] → Modelo INVALIDO:", model)
        else
            --print(":check: [LoadModels] → Modelo válido:", model)
        end

        RequestModel(model)

        local timeout = 0
        while not HasModelLoaded(model) do
            timeout = timeout + 1
            if timeout > 100 then
                --print(":x: [LoadModels] → ERROR: Modelo NO carga:", model)
                break
            end
            Wait(50)
        end

        if HasModelLoaded(model) then
            --print(":check: [LoadModels] → Modelo cargado correctamente:", model)
        end
    end

    --print(":check: [LoadModels] → Finalizado")
end


function Skating.UnloadModels()
    if Skating.Deck then SetModelAsNoLongerNeeded(GetEntityModel(Skating.Deck)) end
    --if Skating.Trucks then SetModelAsNoLongerNeeded(GetEntityModel(Skating.Trucks)) end
    --if Skating.Wheels then SetModelAsNoLongerNeeded(GetEntityModel(Skating.Wheels)) end
    SetModelAsNoLongerNeeded(GetHashKey("cruiser"))
end

--[[============================================================================
    SECTION 20: FONCTIONS DE TRICKS
    PlayTrick, TaskManual, AirStunts
==============================================================================]]

--[[
    PlayTrick
    Exécute un flip trick (kickflip, shuvit, etc.)

    @param animDict - Dictionnaire d'animation
    @param animIn - Animation d'entrée
    @param animOut - Animation de sortie
    @param flag - Flags d'animation
    @param trickIn - Nom du trick (début)
    @param trickOut - Nom du trick (fin)
    @param animIdle - Animation idle
    @param score - Points gagnés
    @param trickIndex - Index du trick dans la table
]]
function PlayTrick(animDict, animIn, animOut, flag, trickIn, trickOut, animIdle, score, trickIndex)
    if not isConnectedToBoard then
        --print(":x: [PlayTrick] → No conectado al skate, cancelando trick")
        return
    end

    local playerPed = PlayerPedId()
   local heightAboveGround = GetEntityHeightAboveGround(Skating.Deck)



    -- DEBUG PRINCIPAL
    --print((":search: [PlayTrick] → heightAboveGround = %.3f | MinGroundHeight = %.3f")
    --        :format(heightAboveGround, ConfigNewSkate.MinGroundHeight))

    -- Vérifier que le skateboard est en l'air
    if heightAboveGround > ConfigNewSkate.MinGroundHeight then

        --print(":check: [PlayTrick] → Condición de aire cumplida, intentando activar trick aéreo...")

        if not isDoingAirTrick and not isDoingManual and not isDoingGrabTrick then

            --print(":check: [PlayTrick] → No hay otros estados activos, iniciando trick aéreo:", trickIn)
            isDoingAirTrick = true

            -- Charger les animations
            --print(":dot-blue: [PlayTrick] → Cargando animaciones:", animDict, "y skateboard@tricks")
            LoadAnimDict(animDict)
            LoadAnimDict("skateboard@tricks")

            -- Jouer l'animation du joueur
            --print(":film: [PlayTrick] → Reproduciendo animIn:", animIn)
            TaskPlayAnim(playerPed, animDict, animIn, 8.0, 8.0, -1, flag, 0.0, false, false, false)

            -- Synchroniser le trick du skateboard
            --print(":refresh: [PlayTrick] → Enviando SyncTrick al servidor:", trickIn)
            TriggerServerEvent("Skating-sv:SyncTrick", trickIn)

            -- Attendre que l'animation se termine ou qu'on touche le sol
            --print(":hourglass: [PlayTrick] → Esperando que heightAboveGround baje de 0.7...")
            while GetEntityHeightAboveGround(Skating.Deck) > 0.7 do
                local h = GetEntityHeightAboveGround(Skating.Deck)
                --print(("  ↳ Altura actual: %.3f"):format(h))

                if HasEntityCollidedWithAnything(Skating.Deck) then
                    --print(":warning: [PlayTrick] → Colisión detectada, saliendo del loop")
                    break
                end
                Wait(1)
            end

            -- Jouer l'animation de sortie
            if not IsPedRagdoll(playerPed) and isConnectedToBoard then
                --print(":film: [PlayTrick] → Reproduciendo animOut:", animOut)
                TaskPlayAnim(playerPed, animDict, animOut, 8.0, 2.0, -1, 65544, 0.0, false, false, false)
            end

            Wait(400)

            -- Retour à la position normale après l'atterrissage
            if not IsPedRagdoll(playerPed) and isConnectedToBoard and not isDoingManual and not isDoingGrabTrick and not isJumping then
                --print(":film: [PlayTrick] → Reproduciendo rail_pose")
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "rail_pose", 8.0, 2.0, -1, 1, 0.0, false, false, false)
            end

            -- Attendre l'atterrissage
            --print(":hourglass: [PlayTrick] → Esperando aterrizaje (height < 0.7)...")
            while GetEntityHeightAboveGround(Skating.Deck) > 0.7 do
                local h = GetEntityHeightAboveGround(Skating.Deck)
                --print(("  ↳ Altura actual: %.3f"):format(h))

                if HasEntityCollidedWithAnything(Skating.Deck) then
                    --print(":warning: [PlayTrick] → Colisión detectada durante aterrizaje")
                    break
                end
                Wait(1)
            end

            -- Son d'atterrissage et score
            --print(":check: [PlayTrick] → Trick completado, sumando score:", score)
            PlayAudio2(SOUND_LAND)
            SetScore(score)

            isDoingAirTrick = false
            isJumping = false

            -- Vérifier les conditions pour l'animation finale
            if isJumping or isDoingManual or isDoingGrabTrick or isDoingSpeedStep
                    or isDoingAirTrick or isPickingUp or not isConnectedToBoard then
                --print(":warning: [PlayTrick] → Condiciones no válidas para animación final, cancelando")
                return
            end

            -- Animation de retour à la normale
            --print(":film: [PlayTrick] → Reproduciendo stand_pose final")
            if not IsPedRagdoll(playerPed) and isConnectedToBoard and not isDoingManual and not isDoingGrabTrick then
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
            end

        else
            --print(":x: [PlayTrick] → No se puede hacer trick aéreo: otro estado activo")
        end

    else

    end
end


--[[
    TaskManual
    Exécute un manual ou nose manual

    @param animDict - Dictionnaire d'animation
    @param animIn - Animation d'entrée
    @param animOut - Animation de sortie
    @param flag - Flags d'animation
    @param trickIn - Nom du trick (début)
    @param trickOut - Nom du trick (fin)
    @param animIdle - Animation idle (pose)
    @param score - Points gagnés
    @param trickIndex - Index du trick
]]
function TaskManual(animDict, animIn, animOut, flag, trickIn, trickOut, animIdle, score, trickIndex)
    if not isConnectedToBoard then return end

    local playerPed = PlayerPedId()
   local heightAboveGround = GetEntityHeightAboveGround(Skating.Deck)



    -- Vérifier que le skateboard est au sol
    if heightAboveGround < ConfigNewSkate.MinGroundHeight then
        if not isDoingManual then
            isDoingManual = true

            LoadAnimDict(animDict)
            LoadAnimDict("skateboard@tricks")

            -- Jouer l'animation d'entrée
            TaskPlayAnim(playerPed, animDict, animIn, 8.0, 8.0, -1, flag, 0.0, false, false, false)
            TriggerServerEvent("Skating-sv:SyncTrick", trickIn)

            Wait(500)

            -- Maintenir la pose du manual
            TaskPlayAnim(playerPed, animDict, animIdle, 8.0, 8.0, -1, flag, 0.0, false, false, false)

            -- Accumuler le score pendant le manual
            local manualTime = 0
            while IsEntityPlayingAnim(playerPed, animDict, animIdle, 3) do
                Wait(100)
                manualTime = manualTime + 100

                -- Ajouter des points toutes les secondes
                if manualTime % 1000 == 0 then
                    SetScore(score)
                end

                -- Arrêter si le joueur saute ou ragdoll
                if isJumping or IsPedRagdoll(playerPed) or not isConnectedToBoard then
                    break
                end
            end

            -- Animation de sortie
            if isConnectedToBoard and not IsPedRagdoll(playerPed) then
                TaskPlayAnim(playerPed, animDict, animOut, 8.0, 8.0, -1, flag, 0.0, false, false, false)
                TriggerServerEvent("Skating-sv:SyncTrick", trickOut)
                Wait(300)

                TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
            end

            isDoingManual = false
        end
    end
end

--[[
    AirStunts
    Exécute un grab trick en l'air (Christ Air, Rocket Air)

    @param animDict - Dictionnaire d'animation
    @param animIn - Animation d'entrée
    @param animOut - Animation de sortie
    @param flag - Flags d'animation
    @param trickIn - Nom du trick (début)
    @param trickOut - Nom du trick (fin)
    @param animIdle - Animation idle
    @param score - Points gagnés
    @param trickIndex - Index du trick
]]
function AirStunts(animDict, animIn, animOut, flag, trickIn, trickOut, animIdle, score, trickIndex)
    if not isConnectedToBoard then
        --print(":x: [AirStunts] Cancelado: No estás conectado al skate.")
        return
    end

    local playerPed = PlayerPedId()
   local heightAboveGround = GetEntityHeightAboveGround(Skating.Deck)



    --print(":dot-blue: [AirStunts] Altura detectada:", heightAboveGround)

    -- Verificar que el skateboard está suficientemente en el aire
    if heightAboveGround > 1.5 then
        --print(":check: [AirStunts] Altura suficiente para iniciar truco aéreo.")

        if not isDoingGrabTrick and not isDoingManual and not isDoingAirTrick then
            --print(":check: [AirStunts] Condiciones válidas. Iniciando truco aéreo:", trickIn)

            isDoingGrabTrick = true
            isPlayingAirAnim = true

            LoadAnimDict(animDict)
            LoadAnimDict("skateboard@tricks")

            -- Animación de entrada
            --print(":film: [AirStunts] Reproduciendo animIn:", animIn)
            TaskPlayAnim(playerPed, animDict, animIn, 8.0, 8.0, -1, flag, 0.0, false, false, false)

            --print(":signal: [AirStunts] Enviando trickIn al servidor:", trickIn)
            TriggerServerEvent("Skating-sv:SyncTrick", trickIn)

            -- Mantener pose en el aire
            while GetEntityHeightAboveGround(Skating.Deck) > 0.8 do
                if HasEntityCollidedWithAnything(Skating.Entities) then
                    --print(":warning: [AirStunts] Colisión detectada durante el truco.")
                    break
                end
                Wait(1)
            end

            isPlayingAirAnim = false
            --print(":dot-blue: [AirStunts] Fin de la animación aérea principal.")

            -- Animación de salida
            if isConnectedToBoard and not IsPedRagdoll(playerPed) then
                --print(":film: [AirStunts] Reproduciendo animOut:", animOut)
                TaskPlayAnim(playerPed, animDict, animOut, 8.0, 8.0, -1, flag, 0.0, false, false, false)

                --print(":signal: [AirStunts] Enviando trickOut al servidor:", trickOut)
                TriggerServerEvent("Skating-sv:SyncTrick", trickOut)
            else
                --print(":x: [AirStunts] No se pudo reproducir animOut (ragdoll o desconectado).")
            end

            -- Esperar aterrizaje
            while GetEntityHeightAboveGround(Skating.Entities) > 0.7 do
                if HasEntityCollidedWithAnything(Skating.Entities) then
                    --print(":warning: [AirStunts] Colisión detectada antes del aterrizaje.")
                    break
                end
                Wait(1)
            end

            --print(":check: [AirStunts] Aterrizaje detectado. Reproduciendo sonido y sumando score:", score)
            PlayAudio2(SOUND_LAND)
            SetScore(score)

            isDoingGrabTrick = false
            isJumping = false

            -- Verificar si se puede volver a stand_pose
            if isJumping or isDoingManual or isDoingGrabTrick or isDoingSpeedStep
                    or isDoingAirTrick or isPickingUp or not isConnectedToBoard then

                --print(":warning: [AirStunts] No se puede volver a stand_pose por estado inválido.")
                return
            end

            if not IsPedRagdoll(playerPed) and isConnectedToBoard then
                --print(":film: [AirStunts] Volviendo a stand_pose.")
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
            else
                --print(":x: [AirStunts] No se pudo reproducir stand_pose.")
            end
        else
            --print(":x: [AirStunts] No se puede iniciar truco: ya hay otro truco activo.")
        end
    else
        --print(":x: [AirStunts] Altura insuficiente para truco aéreo:", heightAboveGround)
    end
end


--[[============================================================================
    SECTION 21: SYNCHRONISATION DES TRICKS
    Event pour synchroniser les animations de tricks entre clients
==============================================================================]]

RegisterNetEvent("Skating-cl:SyncTrick")
AddEventHandler("Skating-cl:SyncTrick", function(trickName, deckNetId, trucksNetId, wheelsNetId)
    if not deckNetId then return end

    -- Convertir les network IDs en entités locales
    local deck = NetToObj(deckNetId)
    --local trucks = NetToObj(trucksNetId)
    --local wheels = NetToObj(wheelsNetId)

    local trickAnimDict = "skateboard@tricks"
   LoadAnimDict(trickAnimDict)

    if ConfigNewSkate.Debug then
        --print("Skateboard Trick:", trickName)
    end

    -- Jouer l'animation sur chaque partie du skateboard
    for _, entity in pairs({deck}) do
        if DoesEntityExist(entity) then
            -- Arrêter l'animation précédente
            StopEntityAnim(entity, lastTrickAnim, trickAnimDict, -8.0)

            -- Jouer la nouvelle animation
            PlayEntityAnim(entity, trickName, trickAnimDict, 8.0, false, true, false, 0.0, 0)

            lastTrickAnim = trickName
        end
    end
end)


--[[============================================================================
    SECTION 22: ENREGISTREMENT DES COMMANDES DE TRICKS
    Crée les key bindings pour chaque trick
==============================================================================]]
--[[ DEBUG COMMAND DISABLED
RegisterCommand("skatedebug", function()
    if not Skating.Entities or not DoesEntityExist(Skating.Entities) then
        --print("No existe Skating.Entities")
        return
    end

    local height = GetEntityHeightAboveGround(Skating.Entities)
    local inAir = IsEntityInAir(Skating.Entities)

    --print("====================================")
    --print(" DEBUG SKATE")
    --print(" Altura real: " .. string.format("%.3f", height))
    --print(" IsEntityInAir(): " .. tostring(inAir))
    --print("====================================")
end)
--]]

Citizen.CreateThread(function()
    --print(":dot-blue: [Tricks] → Iniciando registro de comandos de trucos...")

    for index, trick in ipairs(SkateTricks) do
        -- Crear nombre del comando
        local commandName = "BDX-Skate" .. index

        --print(string.format(
        --        ":check: [Tricks] → Registrando comando: %s | Trick #%d | Label: %s | Tipo: %s",
        --        commandName, index, trick.label, trick.type
        --))

        RegisterCommand(commandName, function()
            --print(":dot-blue: [Tricks] → Comando ejecutado:", commandName)

            if not isConnectedToBoard then
                --print(":x: [Tricks] → No estás conectado al skate. Truco cancelado.")
                return
            end

            --print(":check: [Tricks] → Jugador conectado al skate. Procesando truco...")

            if trick.type == "Trick" then
                ----print(string.format(
                --        ":film: [Tricks] → Ejecutando TRICK normal: %s (index %d)",
                --        trick.trickin, index
                --))

                PlayTrick(
                        trick.dict, trick.animin, trick.animout, trick.flag,
                        trick.trickin, trick.trickout, trick.animidle, trick.score, index
                )

            elseif trick.type == "Air" then
                --print(string.format(
                --        ":rocket: [Tricks] → Ejecutando TRICK AÉREO: %s (index %d)",
                --        trick.trickin, index
                --))

                AirStunts(
                        trick.dict, trick.animin, trick.animout, trick.flag,
                        trick.trickin, trick.trickout, trick.animidle, trick.score, index
                )


            elseif trick.type == "Manual" then
                if isDoingGrabTrick then
                    --print(":warning: [Tricks] → Manual bloqueado: estás haciendo un grab trick.")
                    return
                end

                --print(string.format(
                --        " [Tricks] → Ejecutando MANUAL: %s (index %d)",
                --        trick.trickin, index
                --))

                TaskManual(
                        trick.dict, trick.animin, trick.animout, trick.flag,
                        trick.trickin, trick.trickout, trick.animidle, trick.score, index
                )

            elseif trick.type == "Floor" then
                if isDoingManual then
                    --print(":warning: [Tricks] → Trick de suelo bloqueado: estás en manual.")
                    return
                end

                --print(string.format(
                --        ":warning: [Tricks] → Ejecutando TRICK DE SUELO: %s (index %d)",
                --        trick.trickin, index
                --))

                TriggerEvent(trick.trickin, -1)
            end
        end, false)

        -- Registrar key mapping
        RegisterKeyMapping(commandName, trick.label, "keyboard", "")
        --print(string.format(
        --        ":wrench: [Tricks] → KeyMapping registrado para %s (%s)",
        --        commandName, trick.label
        --))
    end

    --print(":check: [Tricks] → Registro de todos los trucos completado :check:")
end)


--[[============================================================================
    SECTION 23: EVENT COFFIN
    Trick au sol - Le joueur s'allonge sur le skateboard
==============================================================================]]

RegisterNetEvent("Coffin")
AddEventHandler("Coffin", function()
    local boardEntity = Skating.Entities
   local heightAboveGround = GetEntityHeightAboveGround(Skating.Deck)



    -- Vérifier que le skateboard est au sol
    if heightAboveGround < ConfigNewSkate.MinGroundHeight then
        LoadAnimDict("bodhix@skate@anims")
        local playerPed = PlayerPedId()

        if not isDoingSpeedStep then
            SetScore(250)

            -- Toggle coffin
            if IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "coffin_in", 3) then
                -- Sortir du coffin
                PerformingCoffin = true
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "coffin_out", 8.0, -8.0, -1, 180234, 0.0, false, false, false)
                Citizen.Wait(1200)
                ClearPedSecondaryTask(playerPed)
                TaskPlayAnim(PlayerPedId(), "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
            else
                -- Entrer en coffin
                PerformingCoffin = false
                TaskPlayAnim(playerPed, "bodhix@skate@anims", "coffin_in", 8.0, -8.0, -1, 180234, 0.0, false, false, false)
            end
        end
    end
end)

--[[============================================================================
    SECTION 24: EVENT SKATEVELOCITY
    Boost de vitesse - Le joueur pousse pour accélérer
==============================================================================]]

RegisterNetEvent("SkateVelocity")
AddEventHandler("SkateVelocity", function()

    --print(":bolt: [SkateVelocity] → Evento recibido")

    local boardEntity = Skating.Entities
    local velocity = GetEntityVelocity(boardEntity)
    local speed = Vmag(velocity)
    local heightAboveGround = GetEntityHeightAboveGround(Skating.Deck)

    --print((":bolt: [SkateVelocity] → Velocidad actual: %.2f | Altura: %.2f"):format(speed, heightAboveGround))

    -- Verificar que el skateboard está al suelo
    if heightAboveGround >= ConfigNewSkate.MinGroundHeight then
        --print(":ban: [SkateVelocity] → Cancelado: el skate NO está en el suelo")
        return
    end

    if isDoingSpeedStep then
        --print(":ban: [SkateVelocity] → Cancelado: ya está haciendo speed step")
        return
    end

    LoadAnimDict("bodhix@skate@anims")
    --print(":check: [SkateVelocity] → Diccionario cargado")

    local playerPed = PlayerPedId()

    -- Verificar coffin
    if IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "coffin_in", 3) then
        --print(":ban: [SkateVelocity] → Cancelado: anim coffin_in activa")
        return
    end

    if IsEntityPlayingAnim(playerPed, "bodhix@skate@anims", "coffin_out", 3) then
        --print(":ban: [SkateVelocity] → Cancelado: anim coffin_out activa")
        return
    end

    --print(":check: [SkateVelocity] → No está en coffin, continuando...")

    isDoingSpeedStep = true
    --print(":check: [SkateVelocity] → isDoingSpeedStep = true")

    -- Animación de empuje
    --print(":film: [SkateVelocity] → Reproduciendo animación: speed_in")
    TaskPlayAnim(playerPed, "bodhix@skate@anims", "speed_step", 8.0, -8.0, -1, 65544, 0.0, false, false, false)

    -- Sonido
    --print(":megaphone: [SkateVelocity] → Reproduciendo sonido SPEEDSTEP")
    PlayAudio2(SOUND_SPEEDSTEP)

    -- Boost
    local boostForce = 15.0
    local maxBoostForce = 20.0
    local forwardVector = GetEntityForwardVector(playerPed)
    local normalBoost = forwardVector * boostForce
    local maxBoost = forwardVector * maxBoostForce

    if speed < 15.0 then
        --print(":rocket: [SkateVelocity] → Aplicando BOOST NORMAL")
        --print(("  → Boost: %.2f %.2f %.2f"):format(normalBoost.x, normalBoost.y, normalBoost.z))
        SetEntityVelocity(boardEntity, velocity.x + normalBoost.x, velocity.y + normalBoost.y, velocity.z)
    else
        --print(":rocket: [SkateVelocity] → Aplicando BOOST MAX (x0.3)")
        --print(("  → Boost: %.2f %.2f %.2f"):format(maxBoost.x * 0.3, maxBoost.y * 0.3, maxBoost.z * 0.3))
        SetEntityVelocity(boardEntity, velocity.x + maxBoost.x * 0.3, velocity.y + maxBoost.y * 0.3, velocity.z)
    end

    Wait(600)

    -- Volver a stand pose
    if isConnectedToBoard and not IsPedRagdoll(playerPed) and not isDoingManual and not isDoingGrabTrick then
        --print(":film: [SkateVelocity] → Reproduciendo stand_pose")
        TaskPlayAnim(playerPed, "bodhix@skate@anims", "stand_pose", 8.0, 2.0, -1, 1, 1.0, false, false, false)
    else
        --print(":ban: [SkateVelocity] → No se pudo reproducir stand_pose (estado inválido)")
    end

    isDoingSpeedStep = false
    --print(":check: [SkateVelocity] → isDoingSpeedStep = false (FIN)")

end)

--[[============================================================================
    SECTION 25: FONCTIONS AUDIO
    Gestion de la lecture des sons et musiques
==============================================================================]]

-- Variables audio globales
local audioFilePath19 = SOUND_SCORE
local audioFilePath20 = SOUND_MISS

--[[
    PlayAudio
    Joue un fichier audio via NUI (looping)

    @param audioPath - Chemin du fichier audio
]]
function PlayAudio(audioPath)
    SendNUIMessage({
        action = "playAudio",
        url = audioPath
    })
end

--[[
    PlayAudio2
    Joue un fichier audio via NUI (one-shot)

    @param audioPath - Chemin du fichier audio
]]
function PlayAudio2(audioPath)
    SendNUIMessage({
        action = "playAudio2",
        url = audioPath
    })
end

--[[
    StopAudio
    Arrête la lecture audio

    @param channel - Canal audio à arrêter (1 ou 2)
]]
function StopAudio(channel)
    SendNUIMessage({
        action = "stopAudio",
        channel = channel
    })
end

--[[
    PlayScoreAudio
    Joue le son de score

    @param audioPath - Chemin du fichier audio de score
]]
function PlayScoreAudio(audioPath)
    SendNUIMessage({
        action = "playScoreAudio",
        url = audioPath
    })
end

--[[============================================================================
    SECTION 26: SYSTÈME DE SCORE
    Gestion du score du joueur
==============================================================================]]

--[[
    SetScore
    Ajoute des points au score du joueur

    @param points - Nombre de points à ajouter
]]
function SetScore(points)
    local playerPed = PlayerPedId()

    -- Ajouter les points au score
    currentScore = currentScore + points

    -- Envoyer le score au serveur
    TriggerServerEvent("updatePlayerScoreSkate", currentScore)

    -- Jouer le son de score si en jeu
    if InGame then
        if IsPedRagdoll(playerPed) then
            PlayScoreAudio(audioFilePath20)  -- Son d'échec
        else
            PlayScoreAudio(audioFilePath19)  -- Son de succès
        end
    end
end

--[[
    Event: ResertScoreSkate
    Remet le score à zéro
]]
RegisterNetEvent("ResertScoreSkate")
AddEventHandler("ResertScoreSkate", function()
    currentScore = 0
end)

--[[============================================================================
    SECTION 27: SYSTÈME DE MUSIQUE
    Gestion de la musique de fond pendant les mini-jeux
==============================================================================]]

-- Table des musiques disponibles
local musicTracks = {MUSIC_1, MUSIC_2, MUSIC_3, MUSIC_4, MUSIC_5}
local currentMusicIndex = 1

--[[
    Event: PlayMusicSkate
    Joue une musique aléatoire
]]
RegisterNetEvent("PlayMusicSkate")
AddEventHandler("PlayMusicSkate", function()
    local randomIndex = math.random(1, #musicTracks)
    PlayAudio(musicTracks[randomIndex])
end)

--[[
    Event: EndSoundSkate
    Arrête la musique à la fin du jeu
]]
RegisterNetEvent("EndSoundSkate")
AddEventHandler("EndSoundSkate", function()
    StopAudio(1)
end)

--[[============================================================================
    SECTION 28: EFFET DE FEU (STELLA)
    Effet visuel spécial avec des flammes sur les mains
==============================================================================]]

RegisterNetEvent("FireStellaSkate")
AddEventHandler("FireStellaSkate", function()
    local leftHand = true
    local rightHand = true

    if not effect then
        effect = true
        local playerPed = GetPlayerPed(-1)
        local coords = GetEntityCoords(GetPlayerPed(PlayerId()), false)

        -- Supprimer les anciens effets
        local oldLeft = GetClosestObjectOfType(coords.x, coords.y, coords.z, 15.0, GetHashKey("NotzfireLeft"), false, false, false)
        local oldRight = GetClosestObjectOfType(coords.x, coords.y, coords.z, 15.0, GetHashKey("NotzfireRight"), false, false, false)

        if oldLeft ~= 0 then DeleteObject(oldLeft) end
        if oldRight ~= 0 then DeleteObject(oldRight) end

        local x, y, z = table.unpack(GetEntityCoords(playerPed))

        -- Créer l'effet sur la main gauche
        if leftHand then
            local propLeft = CreateObject(GetHashKey("NotzfireLeft"), x, y, z + 0.5, false, true, true)
            local boneLeft = GetPedBoneIndex(playerPed, 14201)
            AttachEntityToEntity(propLeft, playerPed, boneLeft, 0.0, 0.0, 0.0, 0.0, 90.0, 350.0, true, true, false, true, 1, true)
            SetEntityNoCollisionEntity(propLeft, playerPed, false)
            SetEntityCollision(propLeft, false, true)
        end

        -- Créer l'effet sur la main droite
        if rightHand then
            local propRight = CreateObject(GetHashKey("NotzfireRight"), x, y, z + 0.5, false, true, true)
            local boneRight = GetPedBoneIndex(playerPed, 52301)
            AttachEntityToEntity(propRight, playerPed, boneRight, 0.0, 0.0, 0.0, 0.0, 90.0, -180.0, true, true, false, true, 1, true)
            SetEntityNoCollisionEntity(propRight, playerPed, false)
            SetEntityCollision(propRight, false, true)
        end
    else
        -- Désactiver l'effet
        effect = false
        local playerPed = GetPlayerPed(-1)
        local coords = GetEntityCoords(GetPlayerPed(PlayerId()), false)

        local oldLeft = GetClosestObjectOfType(coords.x, coords.y, coords.z, 15.0, GetHashKey("NotzfireLeft"), false, false, false)
        local oldRight = GetClosestObjectOfType(coords.x, coords.y, coords.z, 15.0, GetHashKey("NotzfireRight"), false, false, false)

        if oldLeft ~= 0 then DeleteObject(oldLeft) end
        if oldRight ~= 0 then DeleteObject(oldRight) end
    end
end)

--[[============================================================================
    SECTION 29: SYSTÈME DE CAMÉRA DU SHOP
    Gestion de la caméra pour l'interface du shop
==============================================================================]]

-- Variables de caméra
local shopCamera = nil
local defaultFov = 50.0

--[[
    MoveCameraToCoords
    Déplace la caméra vers des coordonnées spécifiques pour le shop

    @param x, y, z - Coordonnées de la caméra
    @param rotX, rotY, rotZ - Rotation de la caméra
]]
function MoveCameraToCoords(x, y, z, rotX, rotY, rotZ)
    -- Créer une nouvelle caméra
    shopCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(shopCamera, x, y, z)
    SetCamRot(shopCamera, rotX, rotY, rotZ, 2)
    SetCamFov(shopCamera, defaultFov)

    -- Activer la caméra avec transition
    SetCamActive(shopCamera, true)
    RenderScriptCams(true, true, 1000, true, false)
end

--[[
    RestoreCamera
    Restaure la caméra normale du joueur
]]
function RestoreCamera()
    if shopCamera then
        RenderScriptCams(false, true, 1000, true, false)
        DestroyCam(shopCamera, false)
        shopCamera = nil
    end
end

--[[============================================================================
    SECTION 30: PREVIEW DU SHOP
    Gestion des pièces de skateboard affichées dans le shop
==============================================================================]]

-- Entités de preview
local CDeck = nil
local CTrucks = nil
local CWheels = nil

--[[
    PlaceSkatePart
    Place une pièce de skateboard dans le shop pour la preview

    @param partType - Type de pièce (Deck, Trucks, Wheels)
    @param modelName - Nom du modèle à afficher
]]
function PlaceSkatePart(partType, modelName)
    isLoading = true

    -- Charger le modèle
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    -- Obtenir la position de preview depuis la ConfigNewSkate
    local shopConfigNewSkate = ConfigNewSkate.Shops.ShopPeds
    local previewCoords = nil
    local previewHeading = 0.0
    local previewRotation = 0.0

    -- Trouver les coordonnées de preview pour le shop actuel
    for _, shop in ipairs(shopConfigNewSkate) do
        if shop.StoreName == currentShopName then
            previewCoords = shop.PreviewCoords
            previewHeading = shop.PreviewHeading or 0.0
            previewRotation = shop.PreviewRotation or 0.0
            break
        end
    end

    if not previewCoords then
        isLoading = false
        return
    end

    -- Créer l'objet
    local entity = CreateObject(modelHash, previewCoords.x, previewCoords.y, previewCoords.z, false, false, false)

    while not DoesEntityExist(entity) do
        Wait(0)
    end

    -- ConfigNewSkateurer l'entité
    FreezeEntityPosition(entity, true)
    SetEntityRotation(entity, 180.0, previewRotation, previewHeading, 2, true)
    SetModelAsNoLongerNeeded(modelHash)

    -- Stocker l'entité selon le type
    if partType == "Deck" then
        CDeck = entity
        isLoading = false

    elseif partType == "Trucks" then
        --CTrucks = entity
        --isLoading = false

        -- Attacher les trucks au deck
        --AttachEntityToEntity(CTrucks, CDeck, GetEntityBoneIndexByName(CDeck, 39433),
        --        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

    elseif partType == "Wheels" then
        --CWheels = entity
        --isLoading = false

        -- Attacher les roues au deck
        --AttachEntityToEntity(CWheels, CDeck, GetEntityBoneIndexByName(CDeck, 39433),
        --        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    end
end

--[[
    UnloadSkatePart
    Supprime une pièce de skateboard de la preview

    @param partType - Type de pièce à supprimer (Deck, Trucks, Wheels)
]]
function UnloadSkatePart(partType)
    if partType == "Deck" then
        DeleteEntity(CDeck)
        CDeck = nil

    elseif partType == "Trucks" then
        --DetachEntity(CTrucks, false, false)
        --DeleteEntity(CTrucks)
        --CTrucks = nil

    elseif partType == "Wheels" then
        --DetachEntity(CWheels, false, false)
        --DeleteEntity(CWheels)
        --CWheels = nil
    end
end

--[[============================================================================
    SECTION 31: EVENTS DU MENU SHOP
    Gestion de l'ouverture et fermeture du menu
==============================================================================]]

--[[
    Event: menu:open
    Ouvre le menu du shop
]]
RegisterNetEvent("menu:open")
AddEventHandler("menu:open", function(shopName)
    if ConfigNewSkate.Debug then
        --print("Opening shop at:", shopName)
    end

    currentShopName = shopName
    isMenuOpen = true

    -- Activer le focus NUI
    VFW.Nui.Focus(true)

    -- Afficher le conteneur NUI
    SendNUIMessage({
        action = "showContainer"
   })
end)

--[[
    Event: menu:lockError
    Affiche un message d'erreur si le shop est occupé
]]
RegisterNetEvent("menu:lockError")
AddEventHandler("menu:lockError", function()
    if ConfigNewSkate.Framework == "qb" then
        local QBCore = exports[ConfigNewSkate.FrameworkResourceName or "qb-core"]:GetCoreObject()
        QBCore.Functions.Notify(ConfigNewSkate.Language.Info.warning, "primary")
    elseif ConfigNewSkate.Framework == "esx" then
        ESX = exports[ConfigNewSkate.FrameworkResourceName or "es_extended"]:getSharedObject()
        ESX.ShowNotification(ConfigNewSkate.Language.Info.warning)
    end
end)

--[[
    Event: SStore:PurchaseFailed
    Affiche un message d'erreur si l'achat échoue (pas assez d'argent)
]]
RegisterNetEvent("SStore:PurchaseFailed")
AddEventHandler("SStore:PurchaseFailed", function()
    if ConfigNewSkate.Framework == "qb" then
        local QBCore = exports[ConfigNewSkate.FrameworkResourceName or "qb-core"]:GetCoreObject()
        QBCore.Functions.Notify(ConfigNewSkate.Language.Info.noMoney, "error")
    elseif ConfigNewSkate.Framework == "esx" then
        ESX = exports[ConfigNewSkate.FrameworkResourceName or "es_extended"]:getSharedObject()
        ESX.ShowNotification(ConfigNewSkate.Language.Info.noMoney)
    end
end)

--[[============================================================================
    SECTION 32: CALLBACKS NUI - INTERACTIONS SHOP
    Gestion des interactions avec l'interface du shop
==============================================================================]]

--[[
    NUI Callback: closeMenu
    Ferme le menu du shop
]]
RegisterNUICallback("closeMenu", function(data, cb)
    isMenuOpen = false
    VFW.Nui.Focus(false)

    -- Libérer le shop sur le serveur
    TriggerServerEvent("menu:release")

    -- Supprimer les entités de preview
    if CDeck then DeleteEntity(CDeck) CDeck = nil end
    --if CTrucks then DeleteEntity(CTrucks) CTrucks = nil end
    --if CWheels then DeleteEntity(CWheels) CWheels = nil end

    -- Restaurer la caméra
    RestoreCamera()

    cb("ok")
end)

--[[
    NUI Callback: purchaseItem
    Traite l'achat d'un item
]]
RegisterNUICallback("purchaseItem", function(data, cb)
    local itemType = data.type
    local itemId = tostring(data.id)

    -- Validation
    if not itemType or not itemId then
        if ConfigNewSkate.Debug then
            --print("^1[ERROR] Invalid purchase request!^0")
        end
        cb("error")
        return
    end

    if ConfigNewSkate.Debug then
        --print("Client: Purchasing " .. itemType .. " Model: " .. itemId)
    end

    -- Vérifier si le joueur possède déjà cet item
    local ownsItem = false
    if skateStyle == "modern" then
        if itemType == "deck" then
            ownsItem = ("board_" .. itemId) == modernDeck
        end
    elseif skateStyle == "classic" then
        if itemType == "deck" then
            ownsItem = ("c_deck_" .. itemId) == classicDeck
        end
    end

    if ownsItem then
        -- Afficher un message d'erreur
        if ConfigNewSkate.Framework == "qb" then
            local QBCore = exports[ConfigNewSkate.FrameworkResourceName or "qb-core"]:GetCoreObject()
            QBCore.Functions.Notify(ConfigNewSkate.Language.Info.error, "primary")
        elseif ConfigNewSkate.Framework == "esx" then
            ESX = exports[ConfigNewSkate.FrameworkResourceName or "es_extended"]:getSharedObject()
            ESX.ShowNotification(ConfigNewSkate.Language.Info.error)
        end
        cb("error")
        return
    end

    -- Envoyer la demande d'achat au serveur
    TriggerServerEvent("bodhix:purchaseItem", itemType, itemId, skateStyle)
    cb("ok")
end)

--[[
    Event: bodhix-skate:purchase
    Réception de la confirmation d'achat depuis le serveur
]]
RegisterNetEvent("bodhix-skate:purchase")
AddEventHandler("bodhix-skate:purchase", function(itemType, modelName)
    if itemType == "deck" then
        if skateStyle == "modern" then
            modernDeck = modelName
        else
            classicDeck = modelName
        end
    elseif itemType == "trucks" then
        if skateStyle == "modern" then
            modernTrucks = modelName
        else
            classicTrucks = modelName
        end
    elseif itemType == "wheels" then
        if skateStyle == "modern" then
            modernWheels = modelName
        else
            classicWheels = modelName
        end
    end

    -- Afficher une notification de succès
    if ConfigNewSkate.Framework == "qb" then
        local QBCore = exports[ConfigNewSkate.FrameworkResourceName or "qb-core"]:GetCoreObject()
        QBCore.Functions.Notify(ConfigNewSkate.Language.Info.purchase, "success")
    elseif ConfigNewSkate.Framework == "esx" then
        ESX = exports[ConfigNewSkate.FrameworkResourceName or "es_extended"]:getSharedObject()
        ESX.ShowNotification(ConfigNewSkate.Language.Info.purchase)
    end

    -- Sauvegarder l'état
    SaveModelState()
end)

--[[
    NUI Callback: deckSelected
    Sélection d'un deck dans le shop (preview)
]]
RegisterNUICallback("deckSelected", function(data, cb)
    if isLoading then return end

    local deckId = data.id
    local prefix = (skateStyle == "classic") and "deck_" or "board_"
   local baseName = prefix .. deckId
    local fullPrefix = (skateStyle == "classic") and "c_" or ""
   local modelName = fullPrefix .. baseName

    -- Supprimer l'ancien deck de preview
    UnloadSkatePart("Deck")

    -- Attendre que l'ancien soit supprimé
    while DoesEntityExist(CDeck) or isLoading do
        wait(10)
    end

    -- Placer le nouveau deck
    PlaceSkatePart("Deck", modelName)

    if ConfigNewSkate.Debug then
        --print("Deck item selected:", modelName)
    end

    cb("ok")
end)

--[[
    NUI Callback: trucksSelected
    Sélection de trucks dans le shop (preview)
]]
RegisterNUICallback("trucksSelected", function(data, cb)
    if isLoading then return end

    local trucksId = data.id
    local baseName = "trucks_" .. trucksId
    local fullPrefix = (skateStyle == "classic") and "c_" or ""
   local modelName = fullPrefix .. baseName

    -- Supprimer les anciens trucks de preview
    UnloadSkatePart("Trucks")

    while DoesEntityExist(CTrucks) or isLoading do
        wait(10)
    end

    -- Placer les nouveaux trucks
    PlaceSkatePart("Trucks", modelName)

    if ConfigNewSkate.Debug then
        --print("Trucks item selected:", modelName)
    end

    cb("ok")
end)

--[[
    NUI Callback: wheelsSelected
    Sélection de roues dans le shop (preview)
]]
RegisterNUICallback("wheelsSelected", function(data, cb)
    if isLoading then return end

    local wheelsId = data.id
    local baseName = "wheels_" .. wheelsId
    local fullPrefix = (skateStyle == "classic") and "c_" or ""
   local modelName = fullPrefix .. baseName

    -- Supprimer les anciennes roues de preview
    UnloadSkatePart("Wheels")

    while DoesEntityExist(CWheels) or isLoading do
        wait(10)
    end

    -- Placer les nouvelles roues
    PlaceSkatePart("Wheels", modelName)

    if ConfigNewSkate.Debug then
        --print("Wheels item selected:", modelName)
    end

    cb("ok")
end)

--[[
    NUI Callback: styleChanged
    Changement de style (modern/classic)
]]
RegisterNUICallback("styleChanged", function(data, cb)
    local newStyle = data.style

    if newStyle == "modern" or newStyle == "classic" then
        skateStyle = newStyle
        SaveModelState()

        if ConfigNewSkate.Debug then
            --print("Style changed to:", skateStyle)
        end
    end

    cb("ok")
end)

--[[============================================================================
    SECTION 33: SAUVEGARDE ET CHARGEMENT DE L'ÉTAT
    Persistance des préférences du joueur via KVP
==============================================================================]]

--[[
    SaveModelState
    Sauvegarde les modèles de skateboard actuels dans le KVP
]]
function SaveModelState()
    if skateStyle == "modern" then
        -- Sauvegarder le style
        if skateStyle then
            SetResourceKvp("SkateStyle", skateStyle)
        end

        -- Sauvegarder les modèles modern
        if modernDeck then
            SetResourceKvp("CustomDeck", modernDeck)
        end
        if modernTrucks then
            SetResourceKvp("CustomTrucks", modernTrucks)
        end
        if modernWheels then
            SetResourceKvp("CustomWheels", modernWheels)
        end

    elseif skateStyle == "classic" then
        -- Sauvegarder le style
        if skateStyle then
            SetResourceKvp("SkateStyle", skateStyle)
        end

        -- Sauvegarder les modèles classic
        if classicDeck then
            SetResourceKvp("C_CustomDeck", classicDeck)
        end
        if classicTrucks then
            SetResourceKvp("C_CustomTrucks", classicTrucks)
        end
        if classicWheels then
            SetResourceKvp("C_CustomWheels", classicWheels)
        end
    end
end

--[[
    LoadModelState
    Charge les modèles de skateboard sauvegardés depuis le KVP
]]
function LoadModelState()
    -- Charger le style
    local savedStyle = GetResourceKvpString("SkateStyle")
    skateStyle = savedStyle or "modern"

   -- Charger les modèles modern
    local savedDeck = GetResourceKvpString("CustomDeck")
    modernDeck = savedDeck or "board_1"

   local savedTrucks = GetResourceKvpString("CustomTrucks")
    modernTrucks = savedTrucks or "trucks_2"

   local savedWheels = GetResourceKvpString("CustomWheels")
    modernWheels = savedWheels or "wheels_10"

   -- Charger les modèles classic
    local savedClassicDeck = GetResourceKvpString("C_CustomDeck")
    classicDeck = savedClassicDeck or "c_deck_1"

   local savedClassicTrucks = GetResourceKvpString("C_CustomTrucks")
    classicTrucks = savedClassicTrucks or "c_trucks_2"

   local savedClassicWheels = GetResourceKvpString("C_CustomWheels")
    classicWheels = savedClassicWheels or "c_wheels_10"

   if ConfigNewSkate.Debug then
        --print("Loaded Model States:", modernDeck, modernTrucks, modernWheels)
    end
end

-- Charger l'état au démarrage
Citizen.CreateThread(function()
    LoadModelState()
end)

--[[============================================================================
    SECTION 34: NETTOYAGE - EVENTS DE DÉCONNEXION
    Nettoyage des entités quand le joueur se déconnecte ou la ressource s'arrête
==============================================================================]]

--[[
    Event: playerDropped
    Nettoyage quand le joueur se déconnecte
]]
AddEventHandler("playerDropped", function(reason)
    -- Supprimer le skateboard
    Skating.Clear()

    -- Supprimer les entités du skateboard si elles existent
    if DoesEntityExist(Skating.Entities) then
        DetachEntity(Skating.Entities)
        DeleteVehicle(Skating.Entities)
        DeleteEntity(Skating.Player)
    end

    -- Supprimer les entités de preview du shop
    if DoesEntityExist(CDeck) then DeleteEntity(CDeck) end
    if DoesEntityExist(CTrucks) then DeleteEntity(CTrucks) end
    if DoesEntityExist(CWheels) then DeleteEntity(CWheels) end

    -- Arrêter les animations
    StopSkateAnimations()

    -- Restaurer la caméra
    RestoreCamera()
end)

--[[
    Event: onResourceStop
    Nettoyage quand la ressource s'arrête
]]
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Supprimer le skateboard
        Skating.Clear()

        -- Supprimer les entités du skateboard
        if DoesEntityExist(Skating.Entities) then
            DetachEntity(Skating.Entities)
            DeleteVehicle(Skating.Entities)
            DeleteEntity(Skating.Player)
        end

        -- Supprimer les entités de preview du shop
        if DoesEntityExist(CDeck) then DeleteEntity(CDeck) end
        if DoesEntityExist(CTrucks) then DeleteEntity(CTrucks) end
        if DoesEntityExist(CWheels) then DeleteEntity(CWheels) end

        -- Arrêter les animations
        StopSkateAnimations()

        -- Restaurer la caméra
        RestoreCamera()
    end
end)

--[[============================================================================
    FIN DU FICHIER
    BDX-Skate - Client-side Skateboarding System
    Développé par Bodhix's Studio
    Déobfusqué et documenté pour une meilleure lisibilité
==============================================================================]]

--RegisterCommand("skate", function()
--    TriggerEvent("bodhix-skating:client:start")
--end)


--RegisterCommand("boneskate", function()
--    local ent = Skating.Entities or GetVehiclePedIsIn(PlayerPedId(), false)
--
--    if not ent or not DoesEntityExist(ent) then
--        print(":x: No existe el skate o vehículo.")
--        return
--    end
--
--    print(":dot-blue: LISTA DE HUESOS DEL SKATE:")
--    for i = 0, 200 do
--        local boneIndex = GetEntityBoneIndexByName(ent, tostring(i))
--        if boneIndex ~= -1 then
--            print("Bone index:", i, "→", GetEntityBoneName(ent, boneIndex))
--        end
--    end
--
--    -- Huesos comunes de vehículos
--    local common = {
--        "chassis", "chassis_dummy", "bodyshell",
--        "wheel_lf", "wheel_rf", "wheel_lr", "wheel_rr",
--        "seat_dside_f", "seat_pside_f","seat_f"
--    }
--
--    print(":dot-blue: HUESOS COMUNES:")
--    for _, name in ipairs(common) do
--        print(name, "→", GetEntityBoneIndexByName(ent, name))
--    end
--end)
--
--RegisterCommand("skatedebug2", function()
--    print("Deck height:", GetEntityHeightAboveGround(Skating.Deck))
--    print("Vehicle height:", GetEntityHeightAboveGround(Skating.Entities))
--end)
--
--local animDebug = false
--
--RegisterCommand("animdebug", function()
--    animDebug = not animDebug
--    print(":dot-blue: AnimDebug:", animDebug and "ON" or "OFF")
--
--    if animDebug then
--        Citizen.CreateThread(function()
--            while animDebug do
--                local ped = PlayerPedId()
--                local dict = "bodhix@skate@anims"
--
--                -- Recorremos TODAS las animaciones del diccionario por índice
--                for i = 1, 200 do
--                    local anim = string.format("anim_%02d", i)
--                    if IsEntityPlayingAnim(ped, dict, anim, 3) then
--                        print(":film: ACTIVA:", dict, anim)
--                    end
--                end
--
--                -- Chequeamos animaciones conocidas por nombre
--                local knownAnims = {
--                    "backguards_idle",
--                    "coffin_in",
--                    "coffin_out",
--                    "kick_in",
--                    "kick_out",
--                    "manual_pose",
--                    "nose_manual_pose",
--                    "ollie",
--                    "p_break_1_idle",
--                    "p_break_1_in",
--                    "p_break_1_out",
--                    "p_break_2_idle",
--                    "p_break_2_in",
--                    "p_break_2_out",
--                    "p_manual_end",
--                    "p_manual_start",
--                    "p_nose_manual_end",
--                    "p_nose_manual_start",
--                    "p_pickup_in",
--                    "p_pickup_out",
--                    "pre_jump",
--                    "pre_jump_loop",
--                    "rail_pose",
--                    "restpose_idle",
--                    "restpose_in",
--                    "restpose_out",
--                    "restpose_reverse",
--                    "rocket_pose_end",
--                    "rocket_pose_start",
--                    "saveboard",
--                    "speed_pose",
--                    "speed_step",
--                    "stand_pose",
--                    "t_pose_end",
--                    "t_pose_start",
--                    "unboard_pickup"
--                }
--
--                for _, anim in ipairs(knownAnims) do
--                    if IsEntityPlayingAnim(ped, dict, anim, 3) then
--                        print(":check: ACTIVA:", anim)
--                    end
--                end
--
--                Citizen.Wait(100)
--            end
--        end)
--    end
--end)
--
--
--local skateProp = nil
--
------ Pose inicial de tu attach original
--local currentOffset = vector3(0.05, -0.17, -0.01)
--local currentRotation = vector3(-79.0, 243.0, 13.0)
--local currentBone = 24818 -- bone del skate
--
--RegisterCommand("editSkateRot", function()
--    local ped = PlayerPedId()
--    local model = `board_1`
--
--    RequestModel(model)
--    while not HasModelLoaded(model) do Wait(10) end
--
--    if skateProp and DoesEntityExist(skateProp) then
--        DeleteEntity(skateProp)
--    end
--
--    skateProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
--
--    local boneIndex = GetPedBoneIndex(ped, currentBone)
--
--    AttachEntityToEntity(
--            skateProp,
--            ped,
--            boneIndex,
--            currentOffset.x, currentOffset.y, currentOffset.z,
--            currentRotation.x, currentRotation.y, currentRotation.z,
--            true, true, false, true, 1, true
--    )
--
--    print(" Editando ROTACIÓN del skate")
--end)
--
--function updateSkateAttachment()
--    if skateProp and DoesEntityExist(skateProp) then
--        DetachEntity(skateProp, true, true)
--
--        local ped = PlayerPedId()
--        local boneIndex = GetPedBoneIndex(ped, currentBone)
--
--        AttachEntityToEntity(
--                skateProp,
--                ped,
--                boneIndex,
--                currentOffset.x, currentOffset.y, currentOffset.z,
--                currentRotation.x, currentRotation.y, currentRotation.z,
--                true, true, false, true, 1, true
--        )
--    end
--end
--
--Citizen.CreateThread(function()
--    while true do
--        Citizen.Wait(0)
--
--        -- :check: ROTACIÓN con WASDQE
--        if IsControlPressed(0, 172) then -- W → rotar X +
--            currentRotation = vector3(currentRotation.x + 1.0, currentRotation.y, currentRotation.z)
--            updateSkateAttachment()
--            print("Rot X:", currentRotation.x)
--            Wait(100)
--
--        elseif IsControlPressed(0, 173) then -- S → rotar X -
--            currentRotation = vector3(currentRotation.x - 1.0, currentRotation.y, currentRotation.z)
--            updateSkateAttachment()
--            print("Rot X:", currentRotation.x)
--            Wait(100)
--
--        elseif IsControlPressed(0, 174) then -- A → rotar Z -
--            currentRotation = vector3(currentRotation.x, currentRotation.y, currentRotation.z - 1.0)
--            updateSkateAttachment()
--            print("Rot Z:", currentRotation.z)
--            Wait(100)
--
--        elseif IsControlPressed(0, 175) then -- D → rotar Z +
--            currentRotation = vector3(currentRotation.x, currentRotation.y, currentRotation.z + 1.0)
--            updateSkateAttachment()
--            print("Rot Z:", currentRotation.z)
--            Wait(100)
--        end
--
--        if IsControlPressed(0, 44) then -- Q → rotar Y -
--            currentRotation = vector3(currentRotation.x, currentRotation.y - 1.0, currentRotation.z)
--            updateSkateAttachment()
--            print("Rot Y:", currentRotation.y)
--            Wait(100)
--
--        elseif VFW.Interact.Pressed(0, 38) then -- E → rotar Y +
--            currentRotation = vector3(currentRotation.x, currentRotation.y + 1.0, currentRotation.z)
--            updateSkateAttachment()
--            print("Rot Y:", currentRotation.y)
--            Wait(100)
--        end
--
--        -- Aplicar rotación en tiempo real
--        if skateProp and DoesEntityExist(skateProp) then
--            SetEntityRotation(skateProp, currentRotation.x, currentRotation.y, currentRotation.z, 2, true)
--        end
--
--        -- Mostrar valores actuales
--        if IsControlPressed(0, 177) then -- BACKSPACE
--            print(":compass: Rotación actual:")
--            print(("vector3(%.2f, %.2f, %.2f)"):format(currentRotation.x, currentRotation.y, currentRotation.z))
--            Wait(500)
--        end
--    end
--end)
--
--AddEventHandler("onResourceStop", function(resourceName)
--    if resourceName ~= GetCurrentResourceName() then return end
--
--    if skateProp and DoesEntityExist(skateProp) then
--        DeleteEntity(skateProp)
--        skateProp = nil
--        dbgPrint(":trash: Prop eliminado en onResourceStop")
--    end
--end)


--local currentOffset = vector3(0.05, -0.17, -0.01)
--local currentRotation = vector3(-79.0, 243.0, 13.0)
--local currentBone = 24818 -- bone actual del skate
--
--RegisterCommand("editSkateProp", function()
--    local ped = PlayerPedId()
--    local model = `board_1`
--
--    RequestModel(model)
--    while not HasModelLoaded(model) do Wait(10) end
--
--    if skateProp and DoesEntityExist(skateProp) then
--        DeleteEntity(skateProp)
--    end
--
--    skateProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
--
--    local boneIndex = GetPedBoneIndex(ped, currentBone)
--
--    AttachEntityToEntity(
--            skateProp,
--            ped,
--            boneIndex,
--            currentOffset.x, currentOffset.y, currentOffset.z,
--            currentRotation.x, currentRotation.y, currentRotation.z,
--            true, true, false, true, 1, true
--    )
--
--    print(" Skate prop cargado para edición")
--    print("Offset inicial:", currentOffset)
--    print("Rotación inicial:", currentRotation)
--end)
--
--function updateSkateAttachment()
--    if skateProp and DoesEntityExist(skateProp) then
--        DetachEntity(skateProp, true, true)
--
--        local ped = PlayerPedId()
--        local boneIndex = GetPedBoneIndex(ped, currentBone)
--
--        AttachEntityToEntity(
--                skateProp,
--                ped,
--                boneIndex,
--                currentOffset.x, currentOffset.y, currentOffset.z,
--                currentRotation.x, currentRotation.y, currentRotation.z,
--                true, true, false, true, 1, true
--        )
--    end
--end
--
--Citizen.CreateThread(function()
--    while true do
--        Citizen.Wait(0)
--
--        -- Mover offset
--        if IsControlPressed(0, 172) then -- W
--            currentOffset = vector3(currentOffset.x, currentOffset.y, currentOffset.z + 0.01)
--            updateSkateAttachment()
--            print("Z:", currentOffset.z)
--            Wait(100)
--        elseif IsControlPressed(0, 173) then -- S
--            currentOffset = vector3(currentOffset.x, currentOffset.y, currentOffset.z - 0.01)
--            updateSkateAttachment()
--            print("Z:", currentOffset.z)
--            Wait(100)
--        elseif IsControlPressed(0, 174) then -- A
--            currentOffset = vector3(currentOffset.x - 0.01, currentOffset.y, currentOffset.z)
--            updateSkateAttachment()
--            print("X:", currentOffset.x)
--            Wait(100)
--        elseif IsControlPressed(0, 175) then -- D
--            currentOffset = vector3(currentOffset.x + 0.01, currentOffset.y, currentOffset.z)
--            updateSkateAttachment()
--            print("X:", currentOffset.x)
--            Wait(100)
--        end
--
--        if IsControlPressed(0, 44) then -- Q
--            currentOffset = vector3(currentOffset.x, currentOffset.y - 0.01, currentOffset.z)
--            updateSkateAttachment()
--            print("Y:", currentOffset.y)
--            Wait(100)
--        elseif VFW.Interact.Pressed(0, 38) then -- E
--            currentOffset = vector3(currentOffset.x, currentOffset.y + 0.01, currentOffset.z)
--            updateSkateAttachment()
--            print("Y:", currentOffset.y)
--            Wait(100)
--        end
--
--        -- Rotación en tiempo real (flechas + Q/E si quieres reactivarlo)
--        if skateProp and DoesEntityExist(skateProp) then
--            SetEntityRotation(skateProp, currentRotation.x, currentRotation.y, currentRotation.z, 2, true)
--        end
--
--        -- Mostrar valores actuales
--        if IsControlPressed(0, 177) then -- BACKSPACE
--            print(":report: Offset actual:")
--            print(("vector3(%.2f, %.2f, %.2f)"):format(currentOffset.x, currentOffset.y, currentOffset.z))
--            print(":compass: Rotación actual:")
--            print(("vector3(%.2f, %.2f, %.2f)"):format(currentRotation.x, currentRotation.y, currentRotation.z))
--            Wait(500)
--        end
--    end
--end)
