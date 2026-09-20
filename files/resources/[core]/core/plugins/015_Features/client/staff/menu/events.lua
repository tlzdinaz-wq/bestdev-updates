---@meta _
---@diagnostic disable: duplicate-doc-field

local function GetStaffTitle()
    return StaffMenu.menuContext == 'animator' and VFW.AnimatorTitle() or VFW.StaffTitle()
end

local IplList = {
    {
        name = "Criminal Enterprise",
        dlc = true,
        tp = vector3(850.32891845703, -3001.0517578125, -49.999843597412),
    },
    {
        name = "The Contract Studio",
        dlc = true,
        tp = vector3(-999.20227050781, -66.02400970459, -100.00311279297),
    },
    {
        name = "Bikers Clubhouse 1",
        dlc = true,
        tp = vector3(1107.04, -3157.399, -37.51859),
    },
    {
        name = "Bikers Clubhouse 2",
        dlc = true,
        tp = vector3(998.4809, -3164.711, -38.90733),
    },
    {
        name = "Bikers Cocaine",
        dlc = true,
        tp = vector3(1093.6, -3196.6, -38.99841),
    },
    {
        name = "Bikers Counterfeit cash factory",
        dlc = true,
        tp = vector3(1121.897, -3195.338, -40.4025),
    },
    {
        name = "Bikers Document forgery",
        dlc = true,
        tp = vector3(1165.0, -3196.6, -39.01306),
    },
    {
        name = "Bikers Meth",
        dlc = true,
        tp = vector3(1009.5, -3196.6, -38.99682),
    },
    {
        name = "Bikers Weed farm",
        dlc = true,
        tp = vector3(1051.491, -3196.536, -39.14842),
    },
    {
        name = "Casino Arcade",
        tp = vector3(2730.0, -380.0, -49.0),
        dlc = true
    },
    {
        name = "Cayo Club",
        tp = vector3(1550.0, 250.0, -48.0),
        dlc = true
    },
    {
        name = "IAA Facility",
        tp = vector3(2155.07, 2920.88, -62.9),
        dlc = true
    },
    {
        name = "IAA Server Room",
        tp = vector3(2154.85, 2921.07, -82.08),
        dlc = true
    },
    {
        name = "Doomsday",
        tp = vector3(460.6, 4815.69, -60.0),
        dlc = true
    },
    {
        name = "Doomsday Bunker",
        tp = vector3(532.79187011719, 5914.458984375, -159.08006286621),
        dlc = true
    },
    {
        name = "Aircraft",
        tp = vector3(3085.1760253906, -4688.5556640625, 26.251892089844),
        dlc = true
    },
    {
        name = "Plane Hangar",
        tp = vector3(-1267.0, -3013.135, -49.5),
        dlc = true
    },
    {
        name = "Import/Export",
        tp = vector3(994.5925, -3002.594, -39.64699),
        dlc = true
    },
    {
        name = "CEO VEHICLES SHOP",
        tp = vector3(730.63916015625, -2993.2373046875, -38.999904632568),
        dlc = true
    },
    {
        name = "Coroner",
        tp = vector3(240.97831726074, -1366.2081298828, 38.534381866455),
    },
    {
        name = "Bunker",
        tp = vector3(901.29949951172, -3223.8515625, -99.25749206543),
    },
    {
        name = "Cinema",
        tp = vector3(-1426.8258056641, -256.29141235352, 15.782796859741),
    },
    {
        name = "TunerGarage",
        tp = vector3(-1350.0, 160.0, -100.0),
        dlc = true
    },
    {
        name = "TunerMethLab",
        tp = vector3(981.9999, -143.0, -50.0),
        dlc = true
    },
    {
        name = "TunerMeetup",
        tp = vector3(-2000.0, 1113.211, -25.36243),
        dlc = true
    },
    {
        name = "MpSecurityGarage",
        tp = vector3(-1071.4387, -77.033875, -93.525505),
        dlc = true
    },
    {
        name = "MpSecurityMusicRoofTop",
        tp = vector3(-592.6896, 273.1052, 116.302444),
        dlc = true
    },
    {
        name = "MpSecurityStudio",
        tp = vector3(-1000.7252, -70.559875, -98.10669),
        dlc = true
    },
    {
        name = "MpSecurityBillboards",
        tp = vector3(-592.6896, 273.1052, 116.302444),
        dlc = true
    },
    {
        name = "MpSecurityOffice1",
        tp = vector3(-1021.86084, -427.74564, 68.95764),
        dlc = true
    },
    {
        name = "MpSecurityOffice2",
        tp = vector3(383.4156, -59.878227, 108.4595),
        dlc = true
    },
    {
        name = "MpSecurityOffice3",
        tp = vector3(-1004.23035, -761.2084, 66.99069),
        dlc = true
    },
    {
        name = "MpSecurityOffice4",
        tp = vector3(-587.87213, -716.84937, 118.10156),
        dlc = true
    },
    {
        name = "CriminalEnterpriseSmeonFix",
        tp = vector3(-50.2248, -1098.8325, 26.049742),
        dlc = true
    },
    {
        name = "CriminalEnterpriseVehicleWarehouse",
        tp = vector3(800.13696, -3001.4297, -65.14074),
        dlc = true
    },
    {
        name = "CriminalEnterpriseWarehouse",
        tp = vector3(849.1047, -3000.209, -45.974354),
        dlc = true
    },
    {
        name = "DrugWarsFreakshop",
        tp = vector3(570.9713, -420.0727, -70.000),
        dlc = true
    },
    {
        name = "DrugWarsGarage",
        tp = vector3(519.2477, -2618.788, -50.000),
        dlc = true
    },
    {
        name = "DrugWarsLab",
        tp = vector3(483.4252, -2625.071, -50.000),
        dlc = true
    },
    {
        name = "MercenariesClub",
        tp = vector3(1202.407, -3251.251, -50.000),
        dlc = true
    },
    {
        name = "MercenariesLab",
        tp = vector3(-1916.119, 3749.719, -100.000),
        dlc = true
    },
    {
        name = "ChopShopCargoShip",
        tp = vector3(-344.4349, -4062.832, 17.000),
        dlc = true
    },
    {
        name = "ChopShopCartelGarage",
        tp = vector3(1220.133, -2277.844, -50.000),
        dlc = true
    },
    {
        name = "ChopShopLifeguard",
        tp = vector3(-1488.153, -1021.166, 5.000),
        dlc = true
    }
}
local selectedIPL = {}
local lastPos = nil
local tpIPL = false
local freezObject = false
local tableGive, IdtblGive = { "Joueur", "Radius" }, 1
local TypeGive = 1

-- Variables pour le Props Editor amélioré
local currentEventProp = nil
local eventPropsData = {
    model = nil,
    position = { coords = nil, rotation = nil }
}
local freezeEventObject = false
local gizmoActiveEvent = false
local simplePlacingEvent = false
local openedEventMenu = false

-- Variable pour la preview au survol
local hoverPreviewProp = nil

-- Fonction pour supprimer la preview au survol
local function DeleteHoverPreview()
    if hoverPreviewProp and DoesEntityExist(hoverPreviewProp) then
        DeleteEntity(hoverPreviewProp)
    end
    hoverPreviewProp = nil
end

-- Fonction pour spawn la preview au survol (très transparent)
local function SpawnHoverPreview(model)
    DeleteHoverPreview()

    if not model then return end

    local modelHash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(modelHash) then
        return
    end

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnPos = coords + forward * 3.0

    local spawned = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)

    DeleteHoverPreview()
    hoverPreviewProp = spawned

    if hoverPreviewProp and DoesEntityExist(hoverPreviewProp) then
        SetEntityAlpha(hoverPreviewProp, 100, false)
        FreezeEntityPosition(hoverPreviewProp, true)
        SetEntityCollision(hoverPreviewProp, false, false)
        PlaceObjectOnGroundProperly(hoverPreviewProp)
    end

    SetModelAsNoLongerNeeded(modelHash)
end

-- Fonction pour spawn un props en preview (transparence)
local function SpawnPropsPreviewEvent(model, position)
    if currentEventProp and DoesEntityExist(currentEventProp) then
        DeleteEntity(currentEventProp)
        currentEventProp = nil
    end

    local modelHash = type(model) == "number" and model or GetHashKey(model)
    if not IsModelInCdimage(modelHash) then
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'ERROR',
            subtitle = 'Gestion Events',
            message = "Ce modèle n'est pas valide : " .. tostring(model) .. "."
      })
        return false
    end

    VFW.Game.SpawnLocalObject(model, position, function(props)
        currentEventProp = props
        SetEntityAlpha(currentEventProp, 150, false)
        FreezeEntityPosition(currentEventProp, true)
        SetEntityCollision(currentEventProp, false, true)
    end)

    if not currentEventProp or not DoesEntityExist(currentEventProp) then
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'ERROR',
            subtitle = 'Gestion Events',
            message = "Échec du spawn du props."
      })
        return false
    end

    return true
end

local StartSimplePlacementEvent, StartGizmoModeEvent

StartSimplePlacementEvent = function(menu)
    if not currentEventProp or not DoesEntityExist(currentEventProp) then
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'ERROR',
            subtitle = 'Gestion Events',
            message = "Aucun props à positionner."
      })
        return
    end

    openedEventMenu = true
    simplePlacingEvent = true
    menu.close()

    local _simplePlaceInstructionalId = VFW.AddInstructionalButtons({
        { label = "Poser l'objet", control = 38 },
        { label = "Tourner", control = 241 },
        { label = "Mode avancé", control = 47 },
        { label = "Annuler", control = 200 },
    })

    local currentHeading = GetEntityHeading(currentEventProp)
    local placing = true
    local useGizmo = false

    while placing do
        Wait(0)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)
        local targetPos = pCoords + fwd * 2.5

        SetEntityCoords(currentEventProp, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(currentEventProp)
        SetEntityHeading(currentEventProp, currentHeading)

        DisableControlAction(0, 15, true)
        DisableControlAction(0, 16, true)
        if IsDisabledControlJustPressed(0, 15) then
            currentHeading = currentHeading + 15.0
        end
        if IsDisabledControlJustPressed(0, 16) then
            currentHeading = currentHeading - 15.0
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(ped, true)

        if VFW.Interact.JustPressed(0, 38) then
            placing = false
        end

        if IsControlJustPressed(0, 47) then
            placing = false
            useGizmo = true
        end

        if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
            placing = false
            VFW.RemoveInstructionalButtons(_simplePlaceInstructionalId)
            simplePlacingEvent = false
            openedEventMenu = false
            Wait(100)
            menu.open()
            return
        end
    end

    VFW.RemoveInstructionalButtons(_simplePlaceInstructionalId)

    if useGizmo then
        StartGizmoModeEvent(menu)
        return
    end

    eventPropsData.position = {
        coords = GetEntityCoords(currentEventProp),
        rotation = GetEntityRotation(currentEventProp)
    }

    VFW.ShowNotification({
        type = 'STAFF',
        title = GetStaffTitle(),
        variant = 'SUCCESS',
        subtitle = 'Gestion Events',
        message = "Position mise à jour."
  })

    simplePlacingEvent = false
    openedEventMenu = false
    Wait(100)
    menu.open()
end

StartGizmoModeEvent = function(menu)
    if not currentEventProp or not DoesEntityExist(currentEventProp) then
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'ERROR',
            subtitle = 'Gestion Events',
            message = "Aucun props à modifier."
      })
        return
    end

    gizmoActiveEvent = true
    menu.close()

    local data <const> = exports["core"]:useGizmo(currentEventProp)

    gizmoActiveEvent = false

    if data and data.switchedBack then
        StartSimplePlacementEvent(menu)
    elseif data and data.handle and DoesEntityExist(data.handle) then
        eventPropsData.position = {
            coords = data.position,
            rotation = data.rotation
        }
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'SUCCESS',
            subtitle = 'Gestion Events',
            message = "Position mise à jour."
      })
        simplePlacingEvent = false
        openedEventMenu = false
        Wait(100)
        menu.open()
    else
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'INFO',
            subtitle = 'Gestion Events',
            message = "Modification annulée."
      })
        simplePlacingEvent = false
        openedEventMenu = false
        Wait(100)
        menu.open()
    end
end

-- Fonction pour placer définitivement l'objet (visible par tous)
local function PlaceEventObject()
    if not currentEventProp or not DoesEntityExist(currentEventProp) then
        return false
    end

    -- Récupérer la position et rotation de l'objet preview
    local coords = GetEntityCoords(currentEventProp)
    local rotation = GetEntityRotation(currentEventProp)
    local model = eventPropsData.model

    -- Supprimer l'objet preview local
    DeleteEntity(currentEventProp)
    currentEventProp = nil

    -- Demander au serveur de créer l'objet réseau (visible par tous)
    local result = TriggerServerCallback("vfw:staff:spawnNetworkObject", model, coords, rotation, freezeEventObject)

    if result and result.success then
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'SUCCESS',
            subtitle = 'Gestion Events',
            message = "Objet placé: " .. model .. "."
      })

        -- Reset
        eventPropsData = { model = nil, position = { coords = nil, rotation = nil } }
        return true
    else
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'ERROR',
            subtitle = 'Gestion Events',
            message = "Erreur lors du placement de l'objet."
      })
        return false
    end
end

-- Fonction pour reset les données du props editor
local function ResetEventPropsData()
    if currentEventProp and DoesEntityExist(currentEventProp) then
        DeleteEntity(currentEventProp)
    end
    currentEventProp = nil
    eventPropsData = { model = nil, position = { coords = nil, rotation = nil } }
end

-- Fonction pour refresh le menu
local function RefreshEventMenu(menu)
    openedEventMenu = true
    menu.refresh()
    openedEventMenu = false
end

-- Fonction de cleanup exposée pour le OnClose du menu
function StaffMenu.CleanupEventPropsPreview()
    if gizmoActiveEvent or simplePlacingEvent then return end
    ResetEventPropsData()
    freezeEventObject = false
end

--- SpawnProps (ancienne fonction gardée pour compatibilité)
---@param obj any
---@param freeze any
local function SpawnProps(obj, freeze)
    local modelHash = joaat(obj)
    if not IsModelInCdimage(modelHash) then
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'ERROR',
            subtitle = 'Gestion Events',
            message = "Ce modèle n'est pas valide: " .. tostring(obj) .. "."
      })
        return
    end

    local playerPed = VFW.PlayerData.ped
    local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
    local objCoords = coords + forward * 2.5
    local heading = GetEntityHeading(playerPed)
    local placed = false
    local objS = VFW.OneSync.CreateObject(modelHash, objCoords, heading)

    SetEntityHeading(objS, heading)
    PlaceObjectOnGroundProperly(objS)
    SetEntityAlpha(objS, 170, false)
    SetEntityCollision(objS, false, true)

    while not placed do
        coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        objCoords = coords + forward * 2.5
        SetEntityCoords(objS, objCoords.x, objCoords.y, objCoords.z, false, false, false, true)
        PlaceObjectOnGroundProperly(objS)

        if IsControlPressed(0, 190) then
            heading = heading + 0.5
        elseif IsControlPressed(0, 189) then
            heading = heading - 0.5
        end

        SetEntityHeading(objS, heading)

        VFW.ShowHelpNotification(
            "Appuyez sur ~INPUT_CONTEXT~ pour placer l'objet\n~INPUT_FRONTEND_LEFT~ ou ~INPUT_FRONTEND_RIGHT~ Pour faire pivoter l'objet")

        if VFW.Interact.JustPressed(0, 38) then
            placed = true
        end

        DisableControlAction(0, 22, true)

        Wait(0)
    end

    ResetEntityAlpha(objS)
    SetEntityCollision(objS, true, true)
    FreezeEntityPosition(objS, freeze)
    if NetworkGetEntityIsNetworked(objS) then
        local netId = NetworkGetNetworkIdFromEntity(objS)
        SetNetworkIdCanMigrate(netId, true)
        Entity(objS).state:set("eventPropNetId", netId, true)
        TriggerServerEvent("vfw:staff:saveObject", {
            name = obj,
            id = objS,
            geneartedId = netId,
        })
    end
end

--- .BuildEventsMenu
function StaffMenu.BuildEventsMenu()
    StaffMenu.events.Button(":globe: Afficher", "la liste des points TP", nil, "chevron", false, function()
    end, StaffMenu.eventsTpIpl)

    StaffMenu.events.Button(":building: IPL", nil, nil, "chevron", false, function()
    end, StaffMenu.eventsIpl)

    StaffMenu.events.Button(":mask: PROPS EDITOR", nil, nil, "chevron", false, function()
    end, StaffMenu.propseditor)
end

--- .BuildEventsTpIplMenu
function StaffMenu.BuildEventsTpIplMenu()
    for tpIplId,tpIplData in pairs(VFW.ListTpIpl) do
        local tableTpIpl, IdtblTpIpl = { "TP", "Supprimer" }, 1

        StaffMenu.eventsTpIpl.List(tpIplId, tpIplData.ipl.name, false, tableTpIpl, IdtblTpIpl, function(index, item)
            if item == "TP" then
                SetPedCoordsKeepVehicle(PlayerPedId(), vector3(tpIplData.enter.x, tpIplData.enter.y, tpIplData.enter.z - 1.0))
            elseif item == "Supprimer" then
                local confirmation = VFW.Nui.ChoiceInput("Suppression", "Êtes-vous sûr de vouloir supprimer ce point de TP ?", {
                    { label = "Confirmer", value = "confirm" },
                    { label = "Annuler", value = "cancel" }
                })

                if confirmation == "confirm" then
                    TriggerServerEvent("core:event:removetpipl", tpIplId)
                    Wait(200)
                    StaffMenu.eventsTpIpl.refresh()
                end
            end
        end)
    end

    if VFW.ListTpIpl == nil or next(VFW.ListTpIpl) == nil then
        StaffMenu.eventsTpIpl.Separator(" ")
        StaffMenu.eventsTpIpl.Separator("Aucun point de tp trouvé")
        StaffMenu.eventsTpIpl.Separator(" ")
    end
end

--- .BuildEventsIplMenu
function StaffMenu.BuildEventsIplMenu()
    for _, v in pairs(IplList) do
        StaffMenu.eventsIpl.Button(v.name, nil, nil, "chevron", false, function()
            selectedIPL = v
        end, StaffMenu.eventsIplSelect)
    end
end

--- .BuildEventsIplSelectMenu
function StaffMenu.BuildEventsIplSelectMenu()
    if selectedIPL and selectedIPL.name then
        StaffMenu.eventsIplSelect.Separator("Nom", selectedIPL.name)

        if not tpIPL then
            StaffMenu.eventsIplSelect.Button("SE TELEPORTER", nil, nil, "chevron", false, function()
                lastPos = GetEntityCoords(VFW.PlayerData.ped)
                tpIPL = true
                SetPedCoordsKeepVehicle(VFW.PlayerData.ped, selectedIPL.tp.x, selectedIPL.tp.y, selectedIPL.tp.z)
                StaffMenu.eventsIplSelect.refresh()
            end)

            StaffMenu.eventsIplSelect.Button("Créer", "un point de tp", nil, "chevron", false, function()
                local name = VFW.Nui.KeyboardInput(true, "Nom du point de tp")

                if name ~= nil and name ~= "" then
                    TriggerServerEvent("core:event:addtpipl", name, GetEntityCoords(PlayerPedId()), selectedIPL)
                    StaffMenu.eventsIplSelect.refresh()
                end
            end)
        else
            StaffMenu.eventsIplSelect.Button("QUITTER", nil, nil, "chevron", false, function()
                tpIPL = false
                SetPedCoordsKeepVehicle(VFW.PlayerData.ped, lastPos.x, lastPos.y, lastPos.z)
                StaffMenu.eventsIplSelect.refresh()
            end)
        end
    end
end

function StaffMenu.BuildpropseditorMenu()
    local placedPropsEvent = TriggerServerCallback("vfw:staff:getObject") or {}
    local count = 0
    for _ in pairs(placedPropsEvent) do count = count + 1 end

    StaffMenu.propseditor.Button(":plus: PLACER UN OBJET", "Créer un nouvel objet temporaire", nil, "chevron", false, function()
    end, StaffMenu.propseditorCreate)

    StaffMenu.propseditor.Button(":report: OBJETS PLACÉS", string.format(count > 1 and "%d objets actuellement" or "%d objet actuellement", count), nil, "chevron", false, function()
    end, StaffMenu.objectListPlaced)

    if count > 0 then
        StaffMenu.propseditor.Button(":trash: TOUT SUPPRIMER", "Supprimer tous les objets placés", nil, nil, false, function()
            local allProps = TriggerServerCallback("vfw:staff:getObject") or {}

            for k, v in pairs(allProps) do
                local entity = v.netId and NetworkGetEntityFromNetworkId(v.netId) or v.id
                if entity and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
                TriggerServerEvent("vfw:staff:deleteObject", k)
            end

            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'SUCCESS',
                subtitle = 'Props Editor',
                message = "Tous les objets ont été supprimés."
          })

            StaffMenu.propseditor.refresh()
        end)
    end
end

--- .BuildpropseditorObjectList (Liste des objets placés)
function StaffMenu.BuildpropseditorObjectList()
    local placedPropsEvent = TriggerServerCallback("vfw:staff:getObject") or {}
    local count = 0
    for _ in pairs(placedPropsEvent) do count = count + 1 end

    if count == 0 then
        StaffMenu.objectListPlaced.Textbox("Aucun objet placé pour le moment.", "Liste vide")
        return
    end

    for k, v in pairs(placedPropsEvent) do
        StaffMenu.objectListPlaced.Button(
            v.name,
            "Cliquer pour gérer",
            nil, "chevron", false,
            function()
                StaffMenu.selectedPropKey = k
                StaffMenu.selectedPropData = v
                StaffMenu.objectPropOptions.open()
            end
        )
    end

    if count > 1 then
        StaffMenu.objectListPlaced.Button(":trash: TOUT SUPPRIMER", string.format("Supprimer les %d objets", count), nil, nil, false, function()
            for k, v in pairs(placedPropsEvent) do
                local entity = v.netId and NetworkGetEntityFromNetworkId(v.netId) or v.id
                if entity and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
                TriggerServerEvent("vfw:staff:deleteObject", k)
            end
            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'SUCCESS',
                subtitle = 'Props Editor',
                message = "Tous les objets ont été supprimés."
          })
            StaffMenu.objectListPlaced.refresh()
        end)
    end
end

--- .BuildObjectPropOptions (Options d'un objet placé)
function StaffMenu.BuildObjectPropOptions()
    local k = StaffMenu.selectedPropKey
    local v = StaffMenu.selectedPropData
    if not k or not v then return end

    StaffMenu.objectPropOptions.Separator(v.name)

    StaffMenu.objectPropOptions.Button(":pin: SE TÉLÉPORTER", "Se téléporter à la position de l'objet", nil, nil, false, function()
        local entity = v.netId and NetworkGetEntityFromNetworkId(v.netId) or v.id
        if entity and DoesEntityExist(entity) then
            local coords = GetEntityCoords(entity)
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'SUCCESS',
                subtitle = 'Props Editor',
                message = "Téléporté à l'objet: " .. v.name .. "."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'ERROR',
                subtitle = 'Props Editor',
                message = "L'objet n'existe plus."
          })
        end
    end)

    StaffMenu.objectPropOptions.Button(":trash: SUPPRIMER", "Supprimer cet objet", nil, nil, false, function()
        local entity = v.netId and NetworkGetEntityFromNetworkId(v.netId) or v.id
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        TriggerServerEvent("vfw:staff:deleteObject", k)
        VFW.ShowNotification({
            type = 'STAFF',
            title = GetStaffTitle(),
            variant = 'SUCCESS',
            subtitle = 'Props Editor',
            message = "Objet supprimé: " .. v.name .. "."
      })
        StaffMenu.selectedPropKey = nil
        StaffMenu.selectedPropData = nil
        StaffMenu.objectListPlaced.open()
    end)
end

--- .BuildPropsEditorCreateMenu (Menu de création d'objet)
function StaffMenu.BuildPropsEditorCreateMenu()
    local hasModel = eventPropsData.model ~= nil and eventPropsData.model ~= ""
  local hasPreview = currentEventProp and DoesEntityExist(currentEventProp)

    StaffMenu.propseditorCreate.Button(":edit: ENTRER MANUELLEMENT", hasModel and ("Modèle: " .. eventPropsData.model) or "Saisir le nom du modèle", nil, "chevron", false, function()
        local modelName = VFW.Nui.KeyboardInput(true, "Nom du props (forge.plebmasters.de/objects)", eventPropsData.model or "")

        if not modelName or modelName == "" then
            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'ERROR',
                subtitle = 'Props Editor',
                message = "Ce nom de modèle n'est pas valide."
          })
            return
        end

        local modelHash = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if not IsModelInCdimage(modelHash) then
            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'ERROR',
                subtitle = 'Props Editor',
                message = "Ce modèle n'est pas valide: " .. tostring(modelName) .. "."
          })
            return
        end

        eventPropsData.model = modelName

        local playerPed = VFW.PlayerData.ped
        local coords = GetEntityCoords(playerPed)
        local forward = GetEntityForwardVector(playerPed)
        local spawnPos = coords + forward * 3.0

        local success = SpawnPropsPreviewEvent(modelName, spawnPos)
        if success then
            VFW.ShowNotification({
                type = 'STAFF',
                title = GetStaffTitle(),
                variant = 'SUCCESS',
                subtitle = 'Props Editor',
                message = "Modèle chargé: " .. modelName .. "."
          })
            StartSimplePlacementEvent(StaffMenu.propseditorCreate)
            return
        end

        StaffMenu.propseditorCreate.refresh()
    end)

    StaffMenu.propseditorCreate.Button(":folder: PARCOURIR LES CATÉGORIES", "Sélectionner depuis la liste", nil, "chevron", false, function()
    end, StaffMenu.propseditorCategories)

    if hasPreview then
        StaffMenu.propseditorCreate.Separator("POSITIONNEMENT")

        StaffMenu.propseditorCreate.Button(":wrench: MODIFIER LA POSITION", "Repositionner l'objet", nil, "chevron", false, function()
            StartSimplePlacementEvent(StaffMenu.propseditorCreate)
        end)

        StaffMenu.propseditorCreate.Button(":refresh: RÉINITIALISER LA POSITION", "Replacer devant vous", nil, nil, false, function()
            local playerPed = VFW.PlayerData.ped
            local coords = GetEntityCoords(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            local spawnPos = coords + forward * 3.0

            if currentEventProp and DoesEntityExist(currentEventProp) then
                SetEntityCoords(currentEventProp, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
                PlaceObjectOnGroundProperly(currentEventProp)
                eventPropsData.position = {
                    coords = GetEntityCoords(currentEventProp),
                    rotation = GetEntityRotation(currentEventProp)
                }
                VFW.ShowNotification({
                    type = 'STAFF',
                    title = GetStaffTitle(),
                    variant = 'SUCCESS',
                    subtitle = 'Props Editor',
                    message = "Position réinitialisée."
              })
            end
        end)

        StaffMenu.propseditorCreate.Checkbox(":sparkles: FREEZE L'OBJET", "L'objet sera immobile après placement", false, freezeEventObject, function(_checked)
            freezeEventObject = _checked
        end)

        StaffMenu.propseditorCreate.Separator(nil)

        StaffMenu.propseditorCreate.Button(":check: PLACER L'OBJET", "Confirmer le placement", nil, nil, false, function()
            if PlaceEventObject() then
                exports["VUI"]:HandleBack()
            end
        end)
    end

    StaffMenu.propseditorCreate.Button(":x: ANNULER", "Supprimer le preview et revenir", nil, nil, false, function()
        ResetEventPropsData()
        exports["VUI"]:HandleBack()
    end)
end

--- .BuildPropsEditorCategoriesMenu (Menu de sélection de catégories)
function StaffMenu.BuildPropsEditorCategoriesMenu()
    local config = TriggerServerCallback("propsBuilder:getConfig")

    if not config or not config.PropsList then
        StaffMenu.propseditorCategories.Textbox("Impossible de charger les catégories.", "Erreur")
        return
    end

    local VUI = exports["VUI"]
    local adminBanner = exports["core"]:GetVUIBanner("admin")

    for categoryName, propsInCategory in pairs(config.PropsList) do
        local propCount = 0
        for _ in pairs(propsInCategory) do propCount = propCount + 1 end

        StaffMenu.propseditorCategories.Button(
            categoryName,
            string.format("%d props disponibles", propCount),
            nil, "chevron", false,
            function()
                -- Créer un sous-menu dynamique pour cette catégorie
                local categoryPropsMenu = VUI:CreateSubMenu(StaffMenu.propseditorCategories, categoryName, adminBanner, true)

                -- Tableau indexé pour mapper index -> model
                local propsIndexMap = {}
                local propSelected = false
                local firstPropModel = nil

                categoryPropsMenu.OnOpen(function()
                    propsIndexMap = {} -- Reset
                    propSelected = false
                    firstPropModel = nil
                    local index = 0

                    for propModel, propLabel in pairs(propsInCategory) do
                        index = index + 1
                        propsIndexMap[index] = propModel

                        -- Sauvegarder le premier prop pour la preview initiale
                        if not firstPropModel then
                            firstPropModel = propModel
                        end

                        categoryPropsMenu.Button(
                            propLabel,
                            propModel,
                            nil, nil, false,
                            function()
                                -- Supprimer la preview hover avant de sélectionner
                                DeleteHoverPreview()
                                propSelected = true

                                local modelHash = GetHashKey(propModel)
                                if not IsModelInCdimage(modelHash) then
                                    VFW.ShowNotification({
                                        type = 'STAFF',
                                        title = GetStaffTitle(),
                                        variant = 'ERROR',
                                        subtitle = 'Props Editor',
                                        message = "Ce modèle n'est pas valide: " .. tostring(propModel) .. "."
                                  })
                                    propSelected = false
                                    return
                                end

                                eventPropsData.model = propModel

                                local playerPed = VFW.PlayerData.ped
                                local coords = GetEntityCoords(playerPed)
                                local forward = GetEntityForwardVector(playerPed)
                                local spawnPos = coords + forward * 3.0

                                local success = SpawnPropsPreviewEvent(propModel, spawnPos)
                                if success then
                                    VFW.ShowNotification({
                                        type = 'STAFF',
                                        title = GetStaffTitle(),
                                        variant = 'SUCCESS',
                                        subtitle = 'Props Editor',
                                        message = "Modèle sélectionné: " .. propLabel .. "."
                                  })
                                    openedEventMenu = true
                                    categoryPropsMenu.close()
                                    StaffMenu.propseditorCategories.close()
                                    StartSimplePlacementEvent(StaffMenu.propseditorCreate)
                                end
                            end
                        )
                    end

                    -- Spawn la preview du premier prop à l'ouverture
                    if firstPropModel then
                        SetTimeout(50, function()
                            SpawnHoverPreview(firstPropModel)
                        end)
                    end
                end)

                -- Preview au survol
                categoryPropsMenu.OnIndexChange(function(idx, item)
                    -- Utiliser item.props.subtitle qui contient le modèle du prop
                    if item and item.props and item.props.subtitle then
                        SpawnHoverPreview(item.props.subtitle)
                    else
                        -- Si on est sur le separator ou un item sans modèle, afficher le premier prop
                        if firstPropModel then
                            SpawnHoverPreview(firstPropModel)
                        else
                            DeleteHoverPreview()
                        end
                    end
                end)

                -- Nettoyer la preview et retourner aux catégories si pas de sélection
                categoryPropsMenu.OnClose(function()
                    DeleteHoverPreview()
                    if not propSelected then
                        SetTimeout(50, function()
                            StaffMenu.propseditorCategories.open()
                        end)
                    end
                end)

                categoryPropsMenu.open()
            end
        )
    end
end

local itemQuery = nil


--- .BuildEventsGiveMenu
---@return any
function StaffMenu.BuildEventsGiveMenu()
    local firstLabel = itemQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = itemQuery == nil and "UN ITEM" or itemQuery

    StaffMenu.eventsGive.Button(firstLabel, lastLabel, nil, "search", false, function()
        if itemQuery ~= nil then
            itemQuery = nil
            StaffMenu.eventsGive.refresh()
            return
        end

        itemQuery = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if itemQuery == nil or itemQuery == "" then
            return
        end

        StaffMenu.eventsGive.refresh()
    end)

    StaffMenu.eventsGive.Separator(nil)

    for itemName, item in pairs(VFW.Items) do
        if not itemQuery or string.find(string.lower(itemName), string.lower(tostring(itemQuery))) or
                string.find(string.lower(item.label), string.lower(tostring(itemQuery))) then
            StaffMenu.eventsGive.Button(item.label, itemName, item.weight .. " kg", "chevron", false, function()
                local playerId, radius = nil, nil

                if TypeGive == 1 then
                    playerId = VFW.Nui.KeyboardInput(true, "ID du joueur", "")
                    if tonumber(playerId) == nil then
                        VFW.ShowNotification({
                            type = 'STAFF',
                            title = GetStaffTitle(),
                            variant = 'ERROR',
                            subtitle = 'Gestion Events',
                            message = "Veuillez entrer un ID valide."
                      })
                        return
                    end
                else
                    radius = VFW.Nui.KeyboardInput(true, "Rayon", "")
                    if tonumber(radius) == nil then
                        VFW.ShowNotification({
                            type = 'STAFF',
                            title = GetStaffTitle(),
                            variant = 'ERROR',
                            subtitle = 'Gestion Events',
                            message = "Veuillez entrer un rayon valide."
                      })
                        return
                    end
                end

                local count = VFW.Nui.KeyboardInput(true, "Quantité", "")
                if tonumber(count) == nil then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Gestion Events',
                        message = "Veuillez entrer une quantité valide."
                  })
                    return
                end

                local duration = VFW.Nui.KeyboardInput(true, "Durée en minutes (max 60)", "")
                if tonumber(duration) == nil then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Gestion Events',
                        message = "Veuillez entrer une durée valide."
                  })
                    return
                end

                if tonumber(duration) > 60 then
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Gestion Events',
                        message = "La durée ne peut pas être supérieure à 60 minutes."
                  })
                    return
                end

                if TypeGive == 1 and tonumber(playerId) and itemName and tonumber(count) and tonumber(duration) then
                    TriggerServerEvent("vfw:staff:giveItemTemp", playerId, itemName, count, duration)
                elseif TypeGive == 2 and tonumber(radius) and itemName and tonumber(count) and tonumber(duration) then
                    TriggerServerEvent("vfw:staff:giveItemTemp", nil, itemName, count, duration, radius)
                else
                    VFW.ShowNotification({
                        type = 'STAFF',
                        variant = 'ERROR',
                        subtitle = 'Gestion Events',
                        message = "Veuillez entrer des informations valides."
                  })
                    return
                end
            end)
        end
    end
end
