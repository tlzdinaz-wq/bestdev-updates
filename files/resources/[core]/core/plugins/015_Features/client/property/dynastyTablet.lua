---@meta _
---@diagnostic disable: duplicate-doc-field

local DynastyPricesCache = {}

-- Receive dynasty prices sync from server
RegisterNetEvent('dynastyPrices:syncConfig')
AddEventHandler('dynastyPrices:syncConfig', function(data)
    DynastyPricesCache = data or {}
end)

local dynastyTabletOpen = false
local previewId = 0
local inPreviewMode = false
local lastSelectedCategory = "Appartement"
local lastSelectedProperty = nil
local savedPlayerPosition = nil
local savedPlayerHeading = nil
local isAgentMode = false
local isStaffMode = false
local isMinimized = false
local minimizeThreadActive = false
local tabletControlThreadActive = false
local escThreadActive = false

-- Tablet prop/animation
local tabletProp = nil
local TABLET_ANIM_DICT = "amb@world_human_seat_wall_tablet@female@base"
local TABLET_ANIM_NAME = "base"
local TABLET_PROP_MODEL = "prop_cs_tablet"

--- Start tablet animation + attach prop on the player ped
local function StartTabletAnim()
    local ped = PlayerPedId()

    RequestAnimDict(TABLET_ANIM_DICT)
    while not HasAnimDictLoaded(TABLET_ANIM_DICT) do
        Wait(10)
    end

    RequestModel(TABLET_PROP_MODEL)
    while not HasModelLoaded(TABLET_PROP_MODEL) do
        Wait(10)
    end

    -- Play tablet holding animation (flag 49 = loop + upper body + allow movement)
    TaskPlayAnim(ped, TABLET_ANIM_DICT, TABLET_ANIM_NAME, 3.0, 3.0, -1, 49, 0, false, false, false)

    -- Attach tablet prop to left hand (bone 28422)
    tabletProp = CreateObject(GetHashKey(TABLET_PROP_MODEL), 0, 0, 0, false, true, true)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(TABLET_PROP_MODEL)
    RemoveAnimDict(TABLET_ANIM_DICT)
end

--- Stop tablet animation + delete prop
local function StopTabletAnim()
    local ped = PlayerPedId()

    ClearPedTasks(ped)

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

--- Forward declarations for mutual references
local MinimizeTablet
local RestoreTablet
local StartTabletControlThread
local CloseDynastyTabletFull

--- Mapping from tablet category ID to server type
local categoryToType = {
    ["Appartement"] = "Habitations",
    ["Garage"] = "Garage",
    ["Entrepot"] = "Entrepot"
}

--- Categories for the Dynasty tablet
local categories = {
    { id = "Appartement", label = "Habitations", icon = "home" },
    { id = "Garage", label = "Garages", icon = "car" },
    { id = "Entrepot", label = "Entrepots", icon = "warehouse" }
}

--- Get image path for property
---@param categoryId string
---@param propId string
---@return string
local function GetPropertyImage(categoryId, propId)
    -- Image paths based on category
    local basePath = "assets/catalogues/habitation/preview/"
    return basePath .. propId .. ".webp"
end

--- Transform Property data to tablet format
---@return table
local function GetPropertiesForTablet()
    local properties = {}

    for _, category in ipairs(categories) do
        local categoryId = category.id
        properties[categoryId] = {}

        if Property[categoryId] and Property[categoryId].data then
            for _, prop in ipairs(Property[categoryId].data) do
                local prices = DynastyPricesCache[categoryId] and DynastyPricesCache[categoryId][prop.id]
                local sellEnabled = prices and prices.enabled or false
                local rentEnabled = prices and prices.rentEnabled or false

                -- Visible if at least one contract type is offered (allows rent-only listings).
                if sellEnabled or rentEnabled then
                    local propertyData = {
                        id = prop.id,
                        name = prop.name,
                        price = sellEnabled and (prices and prices.sell or 0) or 0,
                        rentPrice = rentEnabled and (prices and prices.rent or 0) or nil,
                        sellEnabled = sellEnabled,
                        rentEnabled = rentEnabled,
                        type = categoryId,
                        image = GetPropertyImage(categoryId, prop.id),
                        interior = prop.interior or prop.id,
                        rooms = prop.rooms,
                        bathrooms = prop.bathrooms,
                        surface = prop.surface,
                        garage = prop.maxPlaces, -- For garages, use maxPlaces as garage count
                        description = prop.description
                    }
                    table.insert(properties[categoryId], propertyData)
                end
            end
        end
    end

    return properties
end

--- Add counts to categories
---@return table
local function GetCategoriesWithCounts()
    local cats = {}
    for _, cat in ipairs(categories) do
        local count = 0
        if Property[cat.id] and Property[cat.id].data then
            for _, prop in ipairs(Property[cat.id].data) do
                local prices = DynastyPricesCache[cat.id] and DynastyPricesCache[cat.id][prop.id]
                -- Count any property that is at least listed (sale or rental),
                -- matching the visibility rule in GetPropertiesForTablet.
                if prices and (prices.enabled or prices.rentEnabled) then
                    count = count + 1
                end
            end
        end
        table.insert(cats, {
            id = cat.id,
            label = cat.label,
            icon = cat.icon,
            count = count
        })
    end
    return cats
end

--- ESC detection thread (same pattern as banking)
--- Closes the entire tablet when ESC is pressed
local function StartEscThread()
    if escThreadActive then return end
    escThreadActive = true
    CreateThread(function()
        while escThreadActive and dynastyTabletOpen do
            Wait(0)
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) then
                CloseDynastyTabletFull()
                break
            end
        end
        escThreadActive = false
    end)
end

--- Open the Dynasty tablet
---@param selectedCategory string|nil
---@param agentMode boolean|nil If true, opens in agent mode with create property option
---@param staffMode boolean|nil If true, opens in staff mode (management only, no cooldowns)
function VFW.OpenDynastyTablet(selectedCategory, agentMode, staffMode)
    if dynastyTabletOpen then
        return
    end

    -- Only set agentMode if explicitly passed (not nil)
    if agentMode ~= nil then
        isAgentMode = agentMode
    end

    -- Set staff mode
    if staffMode ~= nil then
        isStaffMode = staffMode
    end

    dynastyTabletOpen = true
    VFW.Nui.Focus(true, false)
    VFW.Nui.HudVisible(false)

    -- Play tablet holding animation on the player
    StartTabletAnim()

    SendNUIMessage({
        action = "dynastyTablet:open",
        data = {
            categories = GetCategoriesWithCounts(),
            properties = GetPropertiesForTablet(),
            selectedCategory = selectedCategory or lastSelectedCategory or "Appartement",
            isAgent = isAgentMode,
            isStaff = isStaffMode,
            isBoss = isAgentMode and VFW.PlayerData.job.grade >= 98 or false
        }
    })

    -- ESC detection thread (like banking — closes entire tablet)
    StartEscThread()

    -- Start TAB control thread for agent mode minimize
    StartTabletControlThread()
end

--- Close the Dynasty tablet (UI only)
local function CloseTabletUI()
    if not dynastyTabletOpen and not isMinimized then
        return
    end

    dynastyTabletOpen = false
    isMinimized = false
    minimizeThreadActive = false
    tabletControlThreadActive = false
    escThreadActive = false
    VFW.Nui.Focus(false, false)
    VFW.Nui.HudVisible(true)

    -- Stop tablet animation + remove prop
    StopTabletAnim()

    SendNUIMessage({
        action = "dynastyTablet:close"
    })
end

--- Hide the preview overlay
local function HidePreviewOverlay()
    SendNUIMessage({
        action = "dynastyTablet:hidePreviewOverlay"
    })
end

--- Close everything and cleanup
CloseDynastyTabletFull = function()
    isMinimized = false
    minimizeThreadActive = false
    tabletControlThreadActive = false
    escThreadActive = false
    CloseTabletUI()
    HidePreviewOverlay()
    inPreviewMode = false
    lastSelectedProperty = nil
    isAgentMode = false
    isStaffMode = false

    -- Clean up tablet animation camera
    if VFW.Cam:Get("dynastyTabletAnim") then
        VFW.Cam:Destroy("dynastyTabletAnim")
    end
end

--- Get property by ID
---@param propertyId string
---@return table|nil
local function GetPropertyById(propertyId)
    for _, category in ipairs(categories) do
        local categoryId = category.id
        if Property[categoryId] and Property[categoryId].data then
            for _, prop in ipairs(Property[categoryId].data) do
                if prop.id == propertyId then
                    return prop
                end
            end
        end
    end
    return nil
end

--- Exit preview mode and return to tablet
local function ExitPreviewMode()
    if not inPreviewMode then
        return
    end

    inPreviewMode = false
    previewId = previewId + 1
    local ped = PlayerPedId()

    -- Hide the preview overlay
    HidePreviewOverlay()

    DoScreenFadeOut(250)
    Wait(250)

    -- Teleport back to saved position
    if savedPlayerPosition then
        SetEntityCoordsNoOffset(ped, savedPlayerPosition.x, savedPlayerPosition.y, savedPlayerPosition.z, false, false, false)
        SetEntityHeading(ped, savedPlayerHeading or 0.0)
        savedPlayerPosition = nil
        savedPlayerHeading = nil
    end

    Wait(500)
    DoScreenFadeIn(500)

    -- Reopen the tablet with the same category
    VFW.OpenDynastyTablet(lastSelectedCategory)
end

--- NUI Callback: Close tablet
RegisterNUICallback("dynastyTablet:close", function(_, cb)
    CloseDynastyTabletFull()
    cb({})
end)

--- NUI Callback: Update selected category
RegisterNUICallback("dynastyTablet:selectCategory", function(data, cb)
    if data.category then
        lastSelectedCategory = data.category
    end
    cb({})
end)

--- NUI Callback: Preview property (teleport player to interior)
RegisterNUICallback("dynastyTablet:preview", function(data, cb)
    local property = GetPropertyById(data.propertyId)
    if not property then
        cb({ success = false })
        return
    end

    -- Save current state
    lastSelectedCategory = data.category or lastSelectedCategory
    lastSelectedProperty = data.propertyId
    local propertyName = data.name or property.name or "Propriété"

    -- Save player position before teleport
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    savedPlayerPosition = vec3(playerCoords.x, playerCoords.y, playerCoords.z)
    savedPlayerHeading = GetEntityHeading(ped)

    -- Close tablet UI first
    CloseTabletUI()

    -- Clean up tablet animation camera
    if VFW.Cam:Get("dynastyTabletAnim") then
        VFW.Cam:Destroy("dynastyTabletAnim")
    end

    previewId = previewId + 1
    local currentId = previewId
    inPreviewMode = true

    DoScreenFadeOut(250)
    Wait(250)

    if currentId ~= previewId then
        cb({ success = false })
        return
    end

    -- Load IPL if needed
    if property.ipl then
        property.ipl()
    else
        local interiorCoords = property.cam.CamCoords
        PinInteriorInMemory(GetInteriorAtCoords(interiorCoords.x, interiorCoords.y, interiorCoords.z))
    end

    Wait(500)

    if currentId ~= previewId then
        cb({ success = false })
        return
    end

    -- Teleport player to property entry point
    local spawnCoords = property.pos or property.leave or property.cam.CamCoords
    local spawnHeading = property.spawnHeading or property.cam.CamRot.z or 0.0

    SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(ped, spawnHeading)

    Wait(100)

    DoScreenFadeIn(250)

    -- Show the preview overlay with property name
    SendNUIMessage({
        action = "dynastyTablet:showPreviewOverlay",
        data = {
            propertyName = propertyName
        }
    })

    -- Start preview control thread
    CreateThread(function()
        while inPreviewMode and currentId == previewId do
            Wait(0)

            -- Exit on Escape or Backspace
            if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then -- ESC or Backspace
                ExitPreviewMode()
                break
            end

            -- Disable attack controls while in preview
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 140, true) -- Melee light
            DisableControlAction(0, 141, true) -- Melee heavy
            DisableControlAction(0, 142, true) -- Melee light 2
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true) -- Melee
        end
    end)

    cb({ success = true })
end)

--- NUI Callback: Buy/Create property (agent only) — legacy
RegisterNUICallback("dynastyTablet:buy", function(data, cb)
    if not isAgentMode then
        VFW.ShowNotification({
            type = 'DYNASTY_ERROR',
            content = "Vous devez être agent Dynasty 8 en service pour créer une propriété."
        })
        cb({ success = false })
        return
    end

    -- Close tablet first
    CloseDynastyTabletFull()

    -- Get property data
    local property = GetPropertyById(data.propertyId)
    if not property then
        VFW.ShowNotification({
            type = 'DYNASTY_ERROR',
            content = "Propriété introuvable."
        })
        cb({ success = false })
        return
    end

    -- Open property creation menu with pre-selected property
    Wait(500)
    VFW.CreateProperty()

    cb({ success = true })
end)

--- NUI Callback: Get nearby players for contract selection
RegisterNUICallback("dynastyTablet:getNearbyPlayers", function(_, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local nearbyPlayers = VFW.Game.GetPlayersInArea(coords, 5.0, {VFW.playerId})

    local serverIds = {}
    for _, playerId in ipairs(nearbyPlayers) do
        local serverId = GetPlayerServerId(playerId)
        if serverId and serverId > 0 then
            serverIds[#serverIds + 1] = serverId
        end
    end

    local infos = TriggerServerCallback("dynasty:getNearbyPlayersInfo", serverIds) or {}
    local playerList = {}
    for _, entry in ipairs(infos) do
        playerList[#playerList + 1] = {
            serverId = entry.serverId,
            name = entry.name or ("Personne #" .. entry.serverId),
            jobLabel = entry.job and entry.job.label or nil,
            crewLabel = entry.crew and entry.crew.label or nil,
        }
    end

    cb({ players = playerList })
end)

--- NUI Callback: Capture position by closing tablet, letting player walk, press E to confirm
RegisterNUICallback("dynastyTablet:capturePosition", function(data, cb)
    local captureType = data.type or "ped" -- "ped" or "vehicle"
    local isPed = captureType == "ped"

    -- Minimize the tablet so player can move freely
    MinimizeTablet()
    Wait(300)

    local capturing = true
    local confirmed = false
    local capturedPos = nil
    local previewVehicle = nil

    -- Vehicle preview: spawn a transparent preview vehicle
    if not isPed then
        local model = GetHashKey("sultan")
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        if HasModelLoaded(model) then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            previewVehicle = CreateVehicle(model, pos.x, pos.y, pos.z, heading, false, false)
            SetEntityAlpha(previewVehicle, 150, false)
            SetEntityCollision(previewVehicle, false, false)
            FreezeEntityPosition(previewVehicle, true)
            SetEntityInvincible(previewVehicle, true)
            SetVehicleDoorsLocked(previewVehicle, 2)
            SetModelAsNoLongerNeeded(model)
        end
    end

    -- Draw marker + help text thread
    CreateThread(function()
        while capturing do
            Wait(0)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local _, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)

            if isPed then
                -- Green circle marker for pedestrian
                DrawMarker(25, pos.x, pos.y, groundZ + 0.02, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.5, 45, 124, 40, 180, false, true, 2, false, nil, nil, false)
                VFW.ShowHelpNotification("Placez-vous à l'endroit souhaité pour le ~g~Point piéton~s~\nAppuyez sur ~INPUT_CONTEXT~ pour confirmer\nAppuyez sur ~INPUT_CELLPHONE_CANCEL~ pour annuler", nil, false)
            else
                -- Vehicle marker (type 36) + update preview vehicle position/heading
                DrawMarker(36, pos.x, pos.y, groundZ + 0.02, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 1.5, 255, 165, 0, 180, false, true, 2, false, nil, nil, false)

                if previewVehicle and DoesEntityExist(previewVehicle) then
                    SetEntityCoords(previewVehicle, pos.x, pos.y, groundZ, false, false, false, false)
                    SetEntityHeading(previewVehicle, heading)
                end

                VFW.ShowHelpNotification("Placez-vous et orientez-vous pour le ~o~Point véhicule~s~\nLe véhicule spawn dans cette direction\nAppuyez sur ~INPUT_CONTEXT~ pour confirmer\nAppuyez sur ~INPUT_CELLPHONE_CANCEL~ pour annuler", nil, false)
            end

            -- E to confirm
            if VFW.Interact.JustPressed(0, 51) then
                capturedPos = { x = pos.x, y = pos.y, z = groundZ, w = heading }
                confirmed = true
                capturing = false
            end

            -- Backspace to cancel
            if IsControlJustPressed(0, 177) then
                capturing = false
            end
        end
    end)

    -- Wait for capture to finish
    while capturing do
        Wait(100)
    end

    -- Cleanup preview vehicle
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end

    -- Restore the tablet
    RestoreTablet()
    Wait(200)

    if confirmed and capturedPos then
        cb(capturedPos)
    else
        cb({})
    end
end)

--- NUI Callback: Create property from tablet form (agent only)
--- Player is already selected in the React UI
RegisterNUICallback("dynastyTablet:createProperty", function(data, cb)
    if not isAgentMode then
        VFW.ShowNotification({
            type = 'DYNASTY_ERROR',
            content = "Vous devez être agent Dynasty 8 en service pour créer une propriété."
        })
        cb({ success = false })
        return
    end

    local targetServerId = data.targetServerId
    if not targetServerId or targetServerId == 0 then
        VFW.ShowNotification({
            type = 'DYNASTY_ERROR',
            content = "Aucune personne sélectionnée."
        })
        cb({ success = false })
        return
    end

    -- Get player position (use pedPos if provided, otherwise current position)
    local posData
    if data.pedPos and data.pedPos.x then
        posData = data.pedPos
    else
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        posData = { x = pos.x, y = pos.y, z = pos.z, w = heading }
    end

    -- Close tablet
    CloseDynastyTabletFull()

    -- Send contract proposal to server
    local contractData = {
        targetServerId = targetServerId,
        propertyName = data.propertyName,
        customName = data.customName or "",
        category = data.category,
        capacity = data.capacity or "aucun",
        duration = data.duration or 1,
        contractType = data.contractType or "sale",
        ownerType = data.ownerType or "citizen",
        pos = posData
    }

    -- Forward vehiclePos for garages
    if data.vehiclePos and data.vehiclePos.x then
        contractData.vehiclePos = data.vehiclePos
    end

    local success, message = TriggerServerCallback("dynasty:proposeContract", contractData)

    if success then
        VFW.ShowNotification({
            type = 'DYNASTY_SUCCESS',
            content = message or "Offre de contrat envoyée au client."
        })
    else
        VFW.ShowNotification({
            type = 'DYNASTY_ERROR',
            content = message or "Erreur lors de l'envoi du contrat."
        })
    end

    cb({ success = success })
end)

--- NUI Callback: Get properties for management tab
RegisterNUICallback("dynastyTablet:getManageProperties", function(_, cb)
    local callbackName = isStaffMode and "staff:getAllProperties" or "dynasty:getSocietyProperties"
    local properties = TriggerServerCallback(callbackName)
    cb({ properties = properties or {} })
end)

--- NUI Callback: Delete property from management tab
RegisterNUICallback("dynastyTablet:deleteProperty", function(data, cb)
    local result = TriggerServerCallback("dynasty:deleteProperty", data.propertyId, isStaffMode or false)
    cb(result or { success = false, message = "Erreur" })
end)

--- NUI Callback: Extend rental from management tab
RegisterNUICallback("dynastyTablet:extendRental", function(data, cb)
    local result = TriggerServerCallback("dynasty:extendRental", data.propertyId, data.weeks)
    cb(result or { success = false, message = "Erreur" })
end)

--- Start a thread that watches for TAB while the tablet is open (agent mode)
--- Uses IsDisabledControlJustPressed because NUI has focus and blocks normal controls
StartTabletControlThread = function()
    if not isAgentMode or tabletControlThreadActive then
        return
    end

    tabletControlThreadActive = true
    CreateThread(function()
        while tabletControlThreadActive and dynastyTabletOpen do
            Wait(0)
            DisableControlAction(0, 37, true) -- Disable TAB so it doesn't trigger weapon select

            if IsDisabledControlJustPressed(0, 37) then -- TAB
                MinimizeTablet()
                break
            end
        end
        tabletControlThreadActive = false
    end)
end

--- Restore tablet from minimized state
RestoreTablet = function()
    if not isMinimized then
        return
    end

    isMinimized = false
    minimizeThreadActive = false
    dynastyTabletOpen = true
    VFW.Nui.Focus(true, false)
    VFW.Nui.HudVisible(false)

    -- Resume tablet animation
    StartTabletAnim()

    SendNUIMessage({
        action = "dynastyTablet:restore"
    })

    -- Restart the TAB control thread for agent mode
    StartTabletControlThread()
end

--- Minimize the tablet (Lua-initiated, tells React to update)
MinimizeTablet = function()
    if not isAgentMode or not dynastyTabletOpen then
        return
    end

    isMinimized = true
    dynastyTabletOpen = false
    tabletControlThreadActive = false
    VFW.Nui.Focus(false, false)
    VFW.Nui.HudVisible(true)

    -- Stop tablet animation so the player can move freely
    StopTabletAnim()

    -- Destroy tablet animation camera so the player can move freely
    if VFW.Cam:Get("dynastyTabletAnim") then
        VFW.Cam:Destroy("dynastyTabletAnim")
    end

    -- Tell React to switch to minimized state
    SendNUIMessage({
        action = "dynastyTablet:minimized"
    })

    -- Start thread to listen for ESC to restore tablet
    if not minimizeThreadActive then
        minimizeThreadActive = true
        CreateThread(function()
            while minimizeThreadActive and isMinimized do
                Wait(0)

                -- Backspace (control 177) to restore
                if IsControlJustPressed(0, 177) then
                    RestoreTablet()
                    break
                end
            end
            minimizeThreadActive = false
        end)
    end
end

--- NUI Callback: Minimize tablet (from React button click)
RegisterNUICallback("dynastyTablet:minimize", function(_, cb)
    MinimizeTablet()
    cb({})
end)


--- Register Dynasty menu items for all societies of type "dynasty"
-- plugins/**/client/ loads after modules/**/client/ so exports are available
local JobMenuRegistry = exports.core:getJobMenuRegistry()
if JobMenuRegistry then
    JobMenuRegistry.registerByType("dynasty", function(menu, subMenus)
        menu.Separator("Dynasty 8")

        menu.Button("Catalogue immobilier", "Consulter et créer des propriétés", nil, "chevron", false, function()
            menu.close()
            VFW.OpenDynastyTablet(nil, true)
        end)
    end, 30)
end

--- Event to force close the tablet
RegisterNetEvent("vfw:dynastyTablet:close", function()
    CloseDynastyTabletFull()
end)

--- Public catalog points (accessible to everyone)
-- Public catalog points are now handled by modules/society/client/catalog.lua
