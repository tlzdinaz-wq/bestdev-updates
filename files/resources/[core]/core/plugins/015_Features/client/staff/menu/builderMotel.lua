-- Submenus are created in _manager.lua

-- State variables
local selectedMotel = nil
local selectedRoom = nil
local selectedDoorContext = nil -- { index, door/dlId, source = "add"|"edit" }
local newMotelData = {}
local newRoomData = {}

-- Forward declarations
local StartIconOffsetMode

-- Promotion tiers (hours → label)
local PROMO_TIERS <const> = {
    { hours = "24", label = "24h (1 jour)" },
    { hours = "48", label = "48h (2 jours)" },
    { hours = "72", label = "72h (3 jours)" },
}

--- Format doorlock IDs array for display in menu buttons
--- @param ids table|nil array of doorlock IDs
--- @return string
local function FormatDoorlockIds(ids)
    if not ids or #ids == 0 then return "Aucune" end
    local parts = {}
    for _, id in ipairs(ids) do
        parts[#parts + 1] = "#" .. id
    end
    return table.concat(parts, ", ")
end

--- Format promotions for display in menu buttons
--- @param promotions table|nil
--- @return string
local function FormatPromotions(promotions)
    if not promotions then return "Aucune" end
    local parts = {}
    for _, tier in ipairs(PROMO_TIERS) do
        local val = promotions[tier.hours]
        if val then
            parts[#parts + 1] = ("%s: -%d%%"):format(tier.hours .. "h", val)
        end
    end
    if #parts == 0 then return "Aucune" end
    return table.concat(parts, " · ")
end

-- Log action labels
local logActionLabels = {
    rent = "Location",
    checkout = "Départ",
    extend = "Prolongation",
    expiration = "Expiration",
    staff_assign = "Attribution Staff",
    staff_evict = "Expulsion Staff",
    staff_extend = "Prolongation Staff",
    chest_saved = "Coffre sauvegardé",
}

-- ════════════════════════════════════════════
--  Door Selection (Raycast)
-- ════════════════════════════════════════════

local function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation <const> = GetGameplayCamRot()
    local cameraCoord <const> = GetGameplayCamCoord()
    local direction <const> = RotationToDirection(cameraRotation)
    local destination <const> = vector3(
        cameraCoord.x + direction.x * distance,
        cameraCoord.y + direction.y * distance,
        cameraCoord.z + direction.z * distance
    )
    local _, hit, coords, _, entity = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return hit, coords, entity
end

--- Select a door visually with raycast (same system as Fleeca builder)
--- @return entity|nil, vector3|nil the selected entity and its coords
local function SelectDoorVisually()
    local selectionActive = true
    local currentEntity = nil
    local selectedEntity = nil
    local selectedCoords = nil

    CreateThread(function()
        while selectionActive do
            Wait(0)

            VFW.ShowHelpNotification("~INPUT_CONTEXT~ Sélectionner la porte ~n~~INPUT_FRONTEND_RRIGHT~ Annuler")

            if currentEntity and currentEntity ~= selectedEntity then
                SetEntityDrawOutline(currentEntity, false)
            end

            local hit, coords, entity = RayCastGamePlayCamera(15.0)

            if DoesEntityExist(entity) and GetEntityType(entity) ~= 0 then
                local success, model = pcall(GetEntityModel, entity)
                if success and model ~= 0 then
                    currentEntity = entity
                    SetEntityDrawOutline(currentEntity, true)

                    if VFW.Interact.JustPressed(0, 51) then -- E
                        selectedEntity = entity
                        selectedCoords = GetEntityCoords(entity)
                        selectionActive = false
                    end
                end
            end

            if IsControlJustPressed(0, 194) then -- Backspace
                if currentEntity then
                    SetEntityDrawOutline(currentEntity, false)
                end
                selectionActive = false
            end
        end

        if currentEntity and not selectedEntity then
            SetEntityDrawOutline(currentEntity, false)
        end
        if selectedEntity then
            SetEntityDrawOutline(selectedEntity, false)
        end
    end)

    while selectionActive do
        Wait(100)
    end

    return selectedEntity, selectedCoords
end

--- Find an existing doorlock matching a door entity
--- @param entity number the door entity
--- @return number|nil the doorlock ID if found
local function FindDoorlockByEntity(entity)
    local entityModel <const> = GetEntityModel(entity)
    local entityCoords <const> = GetEntityCoords(entity)

    for _, doorlockData in pairs(Doorlock.cache) do
        if doorlockData.doorsData then
            for _, door in pairs(doorlockData.doorsData) do
                if door.model == entityModel then
                    local dist = #(vector3(door.coords.x, door.coords.y, door.coords.z) - entityCoords)
                    if dist < 1.0 then
                        return doorlockData.id
                    end
                end
            end
        end
    end

    return nil
end

-- ════════════════════════════════════════════
--  Main Motel Builder Menu
-- ════════════════════════════════════════════

StaffMenu.builderMotel.OnOpen(function()
    StaffMenu.builderMotel.ClearItems()

    StaffMenu.builderMotel.Separator(":building: GESTION MOTELS")

    StaffMenu.builderMotel.Button(":plus: Créer un motel", "Configurer et ajouter un nouveau motel", nil, "chevron", false, function()
        newMotelData = {}
    end, StaffMenu.motelCreate)

    StaffMenu.builderMotel.Button(":report: Gérer les motels", "Modifier ou supprimer les motels existants", nil, "chevron", false, function()
    end, StaffMenu.motelManage)
end)

-- ════════════════════════════════════════════
--  Create Motel Menu
-- ════════════════════════════════════════════

StaffMenu.motelCreate.OnOpen(function()
    StaffMenu.motelCreate.ClearItems()

    StaffMenu.motelCreate.Separator(":building: NOUVEAU MOTEL")

    -- Name
    StaffMenu.motelCreate.Button(
        ":edit: Nom: " .. (newMotelData.name or "Non défini"),
        "Définir le nom du motel",
        nil, "chevron", false,
        function()
            local name <const> = VFW.Nui.KeyboardInput(true, "Nom du motel")
            if name and string.len(name) > 0 then
                newMotelData.name = name
                StaffMenu.motelCreate.refresh()
            end
        end
    )

    -- NPC Position
    StaffMenu.motelCreate.Button(
        newMotelData.npcCoords and ":pin: Position PNJ définie" or ":pin: Position PNJ: Non définie",
        "Utilise votre position actuelle",
        nil, "chevron", false,
        function()
            local playerPed <const> = PlayerPedId()
            local coords <const> = GetEntityCoords(playerPed)
            local heading <const> = GetEntityHeading(playerPed)

            newMotelData.npcCoords = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                h = heading
            }

            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Position du PNJ enregistrée' })
            StaffMenu.motelCreate.refresh()
        end
    )

    StaffMenu.motelCreate.Separator(":money: TARIFS")

    -- Price per hour
    StaffMenu.motelCreate.Button(
        ":clock: Prix/heure: " .. VFW.Math.FormatMoney(newMotelData.pricePerHour or "500"),
        "Prix de location par heure",
        nil, "chevron", false,
        function()
            local price <const> = tonumber(VFW.Nui.KeyboardInput(true, "Prix par heure (" .. LOCALE.currencySymbol .. ")"))
            if price and price > 0 then
                newMotelData.pricePerHour = price
                StaffMenu.motelCreate.refresh()
            end
        end
    )

    -- Duplicate key price
    StaffMenu.motelCreate.Button(
        ":key: Prix double clé: " .. VFW.Math.FormatMoney(newMotelData.duplicateKeyPrice or "0"),
        "0 = gratuit",
        nil, "chevron", false,
        function()
            local price <const> = tonumber(VFW.Nui.KeyboardInput(true, "Prix du double de clé (" .. LOCALE.currencySymbol .. ", 0 = gratuit)"))
            if price and price >= 0 then
                newMotelData.duplicateKeyPrice = price
                StaffMenu.motelCreate.refresh()
            end
        end
    )

    StaffMenu.motelCreate.Separator(":box: COFFRES (défaut)")

    -- Chest max weight
    StaffMenu.motelCreate.Button(
        ":scales: Poids max: " .. (newMotelData.chestMaxWeight or "50"),
        "Poids par défaut des coffres de chambre",
        nil, "chevron", false,
        function()
            local weight <const> = tonumber(VFW.Nui.KeyboardInput(true, "Poids max coffre (défaut: 50)"))
            if weight and weight > 0 then
                newMotelData.chestMaxWeight = weight
                StaffMenu.motelCreate.refresh()
            end
        end
    )

    -- Chest max slots
    StaffMenu.motelCreate.Button(
        ":folder: Slots max: " .. (newMotelData.chestMaxSlots or "20"),
        "Nombre de slots par défaut",
        nil, "chevron", false,
        function()
            local slots <const> = tonumber(VFW.Nui.KeyboardInput(true, "Slots max coffre (défaut: 20)"))
            if slots and slots > 0 then
                newMotelData.chestMaxSlots = slots
                StaffMenu.motelCreate.refresh()
            end
        end
    )

    StaffMenu.motelCreate.Separator(":tag: PROMOTIONS")

    for _, tier in ipairs(PROMO_TIERS) do
        local currentVal = newMotelData.promotions and newMotelData.promotions[tier.hours]
        local display = currentVal and ("-" .. currentVal .. "%") or "Aucune"

      StaffMenu.motelCreate.Button(
            (":tag: %s: %s"):format(tier.label, display),
            "Réduction pour cette durée (0 = supprimer)",
            nil, "chevron", false,
            function()
                local val <const> = tonumber(VFW.Nui.KeyboardInput(true, ("Réduction %% pour %s (0 = supprimer)"):format(tier.label)))
                if val then
                    if not newMotelData.promotions then
                        newMotelData.promotions = {}
                    end
                    if val > 0 and val <= 100 then
                        newMotelData.promotions[tier.hours] = val
                    else
                        newMotelData.promotions[tier.hours] = nil
                    end
                    if not next(newMotelData.promotions) then
                        newMotelData.promotions = nil
                    end
                    StaffMenu.motelCreate.refresh()
                end
            end
        )
    end

    StaffMenu.motelCreate.Separator("")

    -- Confirm creation
    StaffMenu.motelCreate.Button(":check: CRÉER LE MOTEL", "Valider et créer le motel", nil, "check", false, function()
        if not newMotelData.name then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Vous devez définir un nom' })
            return
        end

        if not newMotelData.npcCoords then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Vous devez définir la position du PNJ' })
            return
        end

        TriggerServerEvent("motel:server:admin:createMotel", {
            name = newMotelData.name,
            pricePerHour = newMotelData.pricePerHour or 500,
            duplicateKeyPrice = newMotelData.duplicateKeyPrice or 0,
            npcModel = newMotelData.npcModel or "s_f_y_shop_mid",
            npcCoords = newMotelData.npcCoords,
            blipSprite = 475,
            blipColor = 5,
            chestMaxWeight = newMotelData.chestMaxWeight or 50,
            chestMaxSlots = newMotelData.chestMaxSlots or 20,
            promotions = newMotelData.promotions
        })

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Motel "' .. newMotelData.name .. '" créé' })
        newMotelData = {}
        StaffMenu.motelCreate.close()
        StaffMenu.motelCreate.parent.open()
    end)
end)

-- ════════════════════════════════════════════
--  Manage Motels Menu (list)
-- ════════════════════════════════════════════

StaffMenu.motelManage.OnOpen(function()
    StaffMenu.motelManage.ClearItems()

    StaffMenu.motelManage.Separator(":report: MOTELS EXISTANTS")

    local motels <const> = TriggerServerCallback("motel:server:getAllMotels")

    if not motels or #motels == 0 then
        StaffMenu.motelManage.Button("Aucun motel", "Créez un motel d'abord", nil, nil, true, function() end)
        return
    end

    for _, motel in ipairs(motels) do
        local roomCount = motel.roomCount or 0
        StaffMenu.motelManage.Button(
            ":building: " .. motel.name,
            ("ID: %d · %s/h · %d chambre%s"):format(motel.id, VFW.Math.FormatMoney(motel.pricePerHour), roomCount, roomCount > 1 and "s" or ""),
            nil, "chevron", false,
            function()
                selectedMotel = motel
            end,
            StaffMenu.motelEdit
        )
    end
end)

-- ════════════════════════════════════════════
--  Edit Motel Menu (hub with submenus)
-- ════════════════════════════════════════════

StaffMenu.motelEdit.OnOpen(function()
    StaffMenu.motelEdit.ClearItems()

    if not selectedMotel then
        StaffMenu.motelEdit.Button("Erreur", "Aucun motel sélectionné", nil, nil, true, function() end)
        return
    end

    StaffMenu.motelEdit.Separator(":building: " .. selectedMotel.name:upper())

    -- Edit name
    StaffMenu.motelEdit.Button(
        ":edit: Nom: " .. selectedMotel.name,
        "Modifier le nom du motel",
        nil, "chevron", false,
        function()
            local newName <const> = VFW.Nui.KeyboardInput(true, "Nouveau nom du motel")
            if newName and string.len(newName) > 0 then
                selectedMotel.name = newName
                StaffMenu.motelEdit.refresh()
            end
        end
    )

    StaffMenu.motelEdit.Separator("")

    -- Sub-menu: Pricing
    StaffMenu.motelEdit.Button(
        ":money: Tarifs",
        ("%s/h · Clé: %s"):format(VFW.Math.FormatMoney(selectedMotel.pricePerHour), VFW.Math.FormatMoney(selectedMotel.duplicateKeyPrice or 0)),
        nil, "chevron", false,
        function() end,
        StaffMenu.motelEditPricing
    )

    -- Sub-menu: Chest config
    StaffMenu.motelEdit.Button(
        ":box: Coffres",
        ("Poids: %d · Slots: %d"):format(selectedMotel.chestMaxWeight or 50, selectedMotel.chestMaxSlots or 20),
        nil, "chevron", false,
        function() end,
        StaffMenu.motelEditChest
    )

    -- Sub-menu: Position
    StaffMenu.motelEdit.Button(
        ":pin: Position & PNJ",
        "Téléportation et repositionnement du PNJ",
        nil, "chevron", false,
        function() end,
        StaffMenu.motelEditPosition
    )

    -- Sub-menu: Rooms
    StaffMenu.motelEdit.Button(
        ":door: Chambres",
        "Ajouter, modifier ou supprimer des chambres",
        nil, "chevron", false,
        function() end,
        StaffMenu.motelRooms
    )

    -- Blip toggle
    local blipEnabled = selectedMotel.blipEnabled ~= false
    StaffMenu.motelEdit.Button(
        blipEnabled and ":pin: Blip: :dot-green: Activé" or ":pin: Blip: :dot-red: Désactivé",
        "Afficher/masquer le blip sur la carte",
        nil, "chevron", false,
        function()
            selectedMotel.blipEnabled = not blipEnabled
            StaffMenu.motelEdit.refresh()
        end
    )

    -- Sub-menu: Logs
    StaffMenu.motelEdit.Button(
        ":report: Logs",
        "Historique d'activité de ce motel",
        nil, "chevron", false,
        function() end,
        StaffMenu.motelLogs
    )

    StaffMenu.motelEdit.Separator("")

    -- Save changes
    StaffMenu.motelEdit.Button(":save: Enregistrer", "Sauvegarder toutes les modifications", nil, "check", false, function()
        TriggerServerEvent("motel:server:admin:updateMotel", {
            id = selectedMotel.id,
            name = selectedMotel.name,
            pricePerHour = selectedMotel.pricePerHour,
            duplicateKeyPrice = selectedMotel.duplicateKeyPrice or 0,
            npcModel = selectedMotel.npcModel,
            npcCoords = selectedMotel.npcCoords,
            blipSprite = selectedMotel.blipSprite,
            blipColor = selectedMotel.blipColor,
            blipEnabled = selectedMotel.blipEnabled ~= false,
            chestMaxWeight = selectedMotel.chestMaxWeight or 50,
            chestMaxSlots = selectedMotel.chestMaxSlots or 20,
            promotions = selectedMotel.promotions
        })
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Motel modifié' })
    end)

    -- Delete motel
    StaffMenu.motelEdit.Button(":trash: Supprimer le motel", "Supprimer définitivement ce motel", nil, "trash", false, function()
        local confirm <const> = VFW.Nui.KeyboardInput(true, "Tapez OUI pour confirmer la suppression")
        if confirm and string.upper(confirm) == "OUI" then
            TriggerServerEvent("motel:server:admin:deleteMotel", selectedMotel.id)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Motel supprimé' })
            selectedMotel = nil
            StaffMenu.motelManage.close()
            StaffMenu.motelManage.parent.open()
        end
    end)
end)

-- ════════════════════════════════════════════
--  Edit Motel → Pricing Submenu
-- ════════════════════════════════════════════

StaffMenu.motelEditPricing.OnOpen(function()
    StaffMenu.motelEditPricing.ClearItems()

    if not selectedMotel then return end

    StaffMenu.motelEditPricing.Separator(":money: TARIFS · " .. selectedMotel.name:upper())

    -- Price per hour
    StaffMenu.motelEditPricing.Button(
        ":clock: Prix/heure: " .. VFW.Math.FormatMoney(selectedMotel.pricePerHour),
        "Prix de location par heure",
        nil, "chevron", false,
        function()
            local newPrice <const> = tonumber(VFW.Nui.KeyboardInput(true, "Nouveau prix par heure (" .. LOCALE.currencySymbol .. ")"))
            if newPrice and newPrice > 0 then
                selectedMotel.pricePerHour = newPrice
                StaffMenu.motelEditPricing.refresh()
            end
        end
    )

    -- Duplicate key price
    StaffMenu.motelEditPricing.Button(
        ":key: Prix double clé: " .. VFW.Math.FormatMoney(selectedMotel.duplicateKeyPrice or 0),
        "0 = gratuit",
        nil, "chevron", false,
        function()
            local newPrice <const> = tonumber(VFW.Nui.KeyboardInput(true, "Prix du double de clé (" .. LOCALE.currencySymbol .. ", 0 = gratuit)"))
            if newPrice and newPrice >= 0 then
                selectedMotel.duplicateKeyPrice = newPrice
                StaffMenu.motelEditPricing.refresh()
            end
        end
    )

    StaffMenu.motelEditPricing.Separator(":tag: PROMOTIONS")

    for _, tier in ipairs(PROMO_TIERS) do
        local currentVal = selectedMotel.promotions and selectedMotel.promotions[tier.hours]
        local display = currentVal and ("-" .. currentVal .. "%") or "Aucune"

      StaffMenu.motelEditPricing.Button(
            (":tag: %s: %s"):format(tier.label, display),
            "Réduction pour cette durée (0 = supprimer)",
            nil, "chevron", false,
            function()
                local val <const> = tonumber(VFW.Nui.KeyboardInput(true, ("Réduction %% pour %s (0 = supprimer)"):format(tier.label)))
                if val then
                    if not selectedMotel.promotions then
                        selectedMotel.promotions = {}
                    end
                    if val > 0 and val <= 100 then
                        selectedMotel.promotions[tier.hours] = val
                    else
                        selectedMotel.promotions[tier.hours] = nil
                    end
                    -- Clean up empty table
                    if not next(selectedMotel.promotions) then
                        selectedMotel.promotions = nil
                    end
                    StaffMenu.motelEditPricing.refresh()
                end
            end
        )
    end

    -- Reset all promotions
    StaffMenu.motelEditPricing.Button(
        ":trash: Supprimer toutes les promotions",
        FormatPromotions(selectedMotel.promotions),
        nil, "trash", false,
        function()
            selectedMotel.promotions = nil
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Promotions supprimées' })
            StaffMenu.motelEditPricing.refresh()
        end
    )
end)

-- ════════════════════════════════════════════
--  Edit Motel → Chest Config Submenu
-- ════════════════════════════════════════════

StaffMenu.motelEditChest.OnOpen(function()
    StaffMenu.motelEditChest.ClearItems()

    if not selectedMotel then return end

    StaffMenu.motelEditChest.Separator(":box: COFFRES · " .. selectedMotel.name:upper())

    -- Chest max weight
    StaffMenu.motelEditChest.Button(
        ":scales: Poids max: " .. (selectedMotel.chestMaxWeight or 50),
        "Poids maximum par défaut des coffres",
        nil, "chevron", false,
        function()
            local weight <const> = tonumber(VFW.Nui.KeyboardInput(true, "Poids max coffre (défaut: 50)"))
            if weight and weight > 0 then
                selectedMotel.chestMaxWeight = weight
                StaffMenu.motelEditChest.refresh()
            end
        end
    )

    -- Chest max slots
    StaffMenu.motelEditChest.Button(
        ":folder: Slots max: " .. (selectedMotel.chestMaxSlots or 20),
        "Nombre de slots par défaut des coffres",
        nil, "chevron", false,
        function()
            local slots <const> = tonumber(VFW.Nui.KeyboardInput(true, "Slots max coffre (défaut: 20)"))
            if slots and slots > 0 then
                selectedMotel.chestMaxSlots = slots
                StaffMenu.motelEditChest.refresh()
            end
        end
    )
end)

-- ════════════════════════════════════════════
--  Edit Motel → Position Submenu
-- ════════════════════════════════════════════

StaffMenu.motelEditPosition.OnOpen(function()
    StaffMenu.motelEditPosition.ClearItems()

    if not selectedMotel then return end

    StaffMenu.motelEditPosition.Separator(":pin: POSITION · " .. selectedMotel.name:upper())

    -- Teleport to motel
    StaffMenu.motelEditPosition.Button(
        ":rocket: Se téléporter au motel",
        "Téléportation à la position du PNJ",
        nil, "chevron", false,
        function()
            if selectedMotel.npcCoords then
                local coords <const> = selectedMotel.npcCoords
                SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                SetEntityHeading(PlayerPedId(), coords.h or 0.0)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Téléporté au motel "' .. selectedMotel.name .. '"' })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Aucune position définie pour ce motel' })
            end
        end
    )

    -- Update NPC position
    StaffMenu.motelEditPosition.Button(
        ":pin: Repositionner le PNJ",
        "Déplacer le PNJ et le blip à votre position actuelle",
        nil, "chevron", false,
        function()
            local playerPed <const> = PlayerPedId()
            local coords <const> = GetEntityCoords(playerPed)
            local heading <const> = GetEntityHeading(playerPed)

            selectedMotel.npcCoords = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                h = heading
            }

            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Position du PNJ mise à jour (pensez à enregistrer)' })
            StaffMenu.motelEditPosition.refresh()
        end
    )
end)

-- ════════════════════════════════════════════
--  Rooms Management Menu
-- ════════════════════════════════════════════

--- Format remaining time for admin display (seconds remaining)
local function FormatTimeRemaining(secondsLeft)
    if secondsLeft <= 0 then return "Expiré" end
    local days = math.floor(secondsLeft / 86400)
    local hours = math.floor((secondsLeft % 86400) / 3600)
    local minutes = math.floor((secondsLeft % 3600) / 60)
    if days > 0 then return ("%dj %dh"):format(days, hours) end
    if hours > 0 then return ("%dh %dm"):format(hours, minutes) end
    return ("%dm"):format(minutes)
end

StaffMenu.motelRooms.OnOpen(function()
    StaffMenu.motelRooms.ClearItems()

    if not selectedMotel then return end

    StaffMenu.motelRooms.Separator(":door: CHAMBRES · " .. selectedMotel.name:upper())

    -- Add room button
    StaffMenu.motelRooms.Button(
        ":plus: Ajouter une chambre",
        "Configurer et ajouter une nouvelle chambre",
        nil, "chevron", false,
        function()
            newRoomData = {}
        end,
        StaffMenu.motelAddRoom
    )

    -- List existing rooms
    local motelDetails <const> = TriggerServerCallback("motel:server:getMotelDetails", selectedMotel.id)

    if not motelDetails or not motelDetails.rooms or #motelDetails.rooms == 0 then
        StaffMenu.motelRooms.Separator("")
        StaffMenu.motelRooms.Button("Aucune chambre", "Ajoutez une chambre d'abord", nil, nil, true, function() end)
        return
    end

    StaffMenu.motelRooms.Separator(":report: CHAMBRES EXISTANTES")

    for _, room in ipairs(motelDetails.rooms) do
        local statusIcon, statusText

        if room.available then
            statusIcon = ":dot-green:"
          statusText = "Libre"
      elseif room.rental then
            statusIcon = ":dot-red:"
          local timeLeft = FormatTimeRemaining(room.rental.remainingSeconds)
            statusText = ("%s · %s"):format(room.rental.playerName, timeLeft)
        else
            statusIcon = ":dot-red:"
          statusText = "Occupée"
      end

        local chestIcon = room.chestCoords and " :box:" or ""

      StaffMenu.motelRooms.Button(
            ("%s Chambre %d · %s%s"):format(statusIcon, room.roomNumber, room.label, chestIcon),
            statusText,
            nil, "chevron", false,
            function()
                selectedRoom = room
            end,
            StaffMenu.motelRoomDetail
        )
    end
end)

-- ════════════════════════════════════════════
--  Room Detail Menu (view, assign, evict, extend, delete)
-- ════════════════════════════════════════════

local DURATION_OPTIONS <const> = { "4h", "8h", "16h", "1j", "2j", "3j" }
local DURATION_HOURS <const> = { 4, 8, 16, 24, 48, 72 }

StaffMenu.motelRoomDetail.OnOpen(function()
    StaffMenu.motelRoomDetail.ClearItems()

    if not selectedRoom or not selectedMotel then return end

    local chestIcon = selectedRoom.chestCoords and " :box:" or ""
  StaffMenu.motelRoomDetail.Separator((":home: CHAMBRE %d · %s%s"):format(selectedRoom.roomNumber, selectedRoom.label, chestIcon))

    if selectedRoom.available or not selectedRoom.rental then
        -- Assign to a connected player
        StaffMenu.motelRoomDetail.Button(
            ":key: Attribuer à un joueur",
            "Attribuer gratuitement cette chambre",
            nil, "chevron", false,
            function() end,
            StaffMenu.motelAssignPlayer
        )
    else
        -- ── Room is OCCUPIED ──
        local timeLeft = FormatTimeRemaining(selectedRoom.rental.remainingSeconds)

        StaffMenu.motelRoomDetail.Button(
            ":dot-red: Occupée par " .. selectedRoom.rental.playerName,
            "Temps restant: " .. timeLeft,
            nil, nil, true,
            function() end
        )

        StaffMenu.motelRoomDetail.Separator(":clock: GESTION LOCATION")

        -- Extend rental
        StaffMenu.motelRoomDetail.List2(
            ":hourglass: Prolonger",
            "Choisir la durée de prolongation",
            false,
            DURATION_OPTIONS,
            1,
            function(index) end,
            function(index)
                local hours <const> = DURATION_HOURS[index]

                local currentDuration = selectedRoom.rental.totalDurationHours
                local newTotal = currentDuration + hours

                if newTotal > 72 then
                    local confirm <const> = VFW.Nui.KeyboardInput(true,
                        ("Durée totale: %dh (max: 72h). Tapez OUI pour confirmer"):format(math.floor(newTotal))
                    )
                    if not confirm or string.upper(confirm) ~= "OUI" then
                        return
                    end
                end

                local result <const> = TriggerServerCallback("motel:server:admin:extendRoom", {
                    roomId = selectedRoom.id,
                    hours = hours
                })

                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = result.message })
                    selectedRoom.rental.remainingSeconds = selectedRoom.rental.remainingSeconds + (hours * 3600)
                    selectedRoom.rental.totalDurationHours = selectedRoom.rental.totalDurationHours + hours
                    StaffMenu.motelRoomDetail.refresh()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = result and result.message or "Erreur" })
                end
            end
        )

        StaffMenu.motelRoomDetail.Separator(":door: EXPULSION")

        -- Evict with refund
        StaffMenu.motelRoomDetail.Button(
            ":money: Expulser (avec remboursement)",
            "Expulser et rembourser le temps restant",
            nil, "chevron", false,
            function()
                local confirm <const> = VFW.Nui.KeyboardInput(true,
                    ("Expulser %s AVEC remboursement ? Tapez OUI"):format(selectedRoom.rental.playerName)
                )
                if not confirm or string.upper(confirm) ~= "OUI" then return end

                local result <const> = TriggerServerCallback("motel:server:admin:evictRoom", {
                    roomId = selectedRoom.id,
                    refund = true
                })

                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = result.message })
                    StaffMenu.motelRooms.open()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = result and result.message or "Erreur" })
                end
            end
        )

        -- Evict without refund
        StaffMenu.motelRoomDetail.Button(
            ":ban: Expulser (sans remboursement)",
            "Expulser sans rembourser",
            nil, "chevron", false,
            function()
                local confirm <const> = VFW.Nui.KeyboardInput(true,
                    ("Expulser %s SANS remboursement ? Tapez OUI"):format(selectedRoom.rental.playerName)
                )
                if not confirm or string.upper(confirm) ~= "OUI" then return end

                local result <const> = TriggerServerCallback("motel:server:admin:evictRoom", {
                    roomId = selectedRoom.id,
                    refund = false
                })

                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = result.message })
                    StaffMenu.motelRooms.open()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = result and result.message or "Erreur" })
                end
            end
        )
    end

    StaffMenu.motelRoomDetail.Separator("")

    -- Modify room
    StaffMenu.motelRoomDetail.Button(
        ":edit: Modifier la chambre",
        "Changer le nom, prix, porte, coffre...",
        nil, "chevron", false,
        function() end,
        StaffMenu.motelRoomEdit
    )

    -- Delete room (always available)
    StaffMenu.motelRoomDetail.Button(
        ":trash: Supprimer la chambre",
        "Supprimer définitivement cette chambre",
        nil, "trash", false,
        function()
            local confirm <const> = VFW.Nui.KeyboardInput(true,
                ("Tapez OUI pour supprimer la chambre %d"):format(selectedRoom.roomNumber)
            )
            if confirm and string.upper(confirm) == "OUI" then
                TriggerServerEvent("motel:server:admin:removeRoom", selectedRoom.id)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Chambre supprimée' })
                selectedRoom = nil
                StaffMenu.motelRooms.open()
            end
        end
    )
end)

-- ════════════════════════════════════════════
--  Assign Player Menu (list connected players)
-- ════════════════════════════════════════════

StaffMenu.motelAssignPlayer.OnOpen(function()
    StaffMenu.motelAssignPlayer.ClearItems()

    if not selectedRoom or not selectedMotel then return end

    StaffMenu.motelAssignPlayer.Separator(":key: ATTRIBUER · CHAMBRE " .. selectedRoom.roomNumber)

    local playerList <const> = StaffMenu.FetchPlayerList(false) or {}

    local hasPlayers = false
    for _ in pairs(playerList) do hasPlayers = true; break end

    if not hasPlayers then
        StaffMenu.motelAssignPlayer.Button("Aucun joueur connecté", nil, nil, nil, true, function() end)
        return
    end

    for _, player in pairs(playerList) do
        StaffMenu.motelAssignPlayer.List2(
            ":user: " .. player.name,
            ("ID: %d"):format(player.source),
            false,
            DURATION_OPTIONS,
            1,
            function(index) end,
            function(index)
                local hours <const> = DURATION_HOURS[index]

                local result <const> = TriggerServerCallback("motel:server:admin:assignRoom", {
                    roomId = selectedRoom.id,
                    targetSource = player.source,
                    hours = hours
                })

                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = result.message })
                    StaffMenu.motelRooms.open()
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = result and result.message or "Erreur" })
                end
            end
        )
    end
end)

-- ════════════════════════════════════════════
--  Add Room Menu (with Doorlock Selection)
-- ════════════════════════════════════════════

StaffMenu.motelAddRoom.OnOpen(function()
    StaffMenu.motelAddRoom.ClearItems()

    if not selectedMotel then return end

    StaffMenu.motelAddRoom.Separator(":plus: NOUVELLE CHAMBRE · " .. selectedMotel.name:upper())

    -- Room number
    StaffMenu.motelAddRoom.Button(
        ":hash: Numéro: " .. (newRoomData.roomNumber or "Non défini"),
        "Numéro de la chambre",
        nil, "chevron", false,
        function()
            local num <const> = tonumber(VFW.Nui.KeyboardInput(true, "Numéro de la chambre"))
            if num and num > 0 then
                newRoomData.roomNumber = num
                StaffMenu.motelAddRoom.refresh()
            end
        end
    )

    -- Room label
    StaffMenu.motelAddRoom.Button(
        ":edit: Nom: " .. (newRoomData.label or "Non défini"),
        "Label de la chambre (ex: Chambre 101)",
        nil, "chevron", false,
        function()
            local label <const> = VFW.Nui.KeyboardInput(true, "Nom de la chambre")
            if label and string.len(label) > 0 then
                newRoomData.label = label
                StaffMenu.motelAddRoom.refresh()
            end
        end
    )

    -- Doorlocks section (doors are stored as pending data until room is saved)
    -- Each entry is either { existingId = number } or { model, coords, heading }
    if not newRoomData.doors then newRoomData.doors = {} end

    StaffMenu.motelAddRoom.Separator(":lock: PORTES (" .. #newRoomData.doors .. ")")

    if not newRoomData.iconOffsets then newRoomData.iconOffsets = {} end

    for i, door in ipairs(newRoomData.doors) do
        local doorLabel = door.existingId and (":lock: Porte #" .. door.existingId) or (":lock: Nouvelle porte #" .. i)
        StaffMenu.motelAddRoom.Button(
            doorLabel,
            "Téléporter, cadenas, retirer",
            nil, "chevron", false,
            function()
                selectedDoorContext = { index = i, door = door, source = "add" }
            end,
            StaffMenu.motelAddDoorActions
        )
    end

    StaffMenu.motelAddRoom.Button(
        ":plus: Ajouter une porte",
        "Visez la porte de la chambre et appuyez sur E",
        nil, "chevron", false,
        function()
            StaffMenu.motelAddRoom.close()

            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Motel', message = 'Visez la porte et appuyez sur E' })

            local entity, coords = SelectDoorVisually()

            if not entity or not coords then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Sélection annulée' })
                StaffMenu.motelAddRoom.open()
                return
            end

            -- Check if this door already belongs to a doorlock
            local existingDoorlockId <const> = FindDoorlockByEntity(entity)

            if existingDoorlockId then
                -- Check duplicate
                for _, d in ipairs(newRoomData.doors) do
                    if d.existingId == existingDoorlockId then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Cette porte est déjà ajoutée' })
                        StaffMenu.motelAddRoom.open()
                        return
                    end
                end
                newRoomData.doors[#newRoomData.doors + 1] = { existingId = existingDoorlockId }
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Doorlock existant trouvé: #' .. existingDoorlockId })
            else
                -- Store door data for deferred creation (no doorlock created yet)
                local model <const> = GetEntityModel(entity)
                local heading <const> = GetEntityHeading(entity)
                newRoomData.doors[#newRoomData.doors + 1] = {
                    model = model,
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    heading = heading
                }
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Porte enregistrée (sera créée à la sauvegarde)' })
            end

            StaffMenu.motelAddRoom.open()
        end
    )

    StaffMenu.motelAddRoom.Separator(":settings: OPTIONS")

    -- Price override (optional)
    StaffMenu.motelAddRoom.Button(
        ":money: Prix custom: " .. (newRoomData.priceOverride and (VFW.Math.FormatMoney(newRoomData.priceOverride)) or "Prix du motel"),
        "Laisser vide pour utiliser le prix du motel",
        nil, "chevron", false,
        function()
            local price <const> = tonumber(VFW.Nui.KeyboardInput(true, "Prix custom (vide = prix motel)"))
            newRoomData.priceOverride = price
            StaffMenu.motelAddRoom.refresh()
        end
    )

    -- Chest placement (optional)
    StaffMenu.motelAddRoom.Button(
        newRoomData.chestCoords and ":box: Coffre positionné :check:" or ":box: Placer un coffre (optionnel)",
        newRoomData.chestCoords and "Cliquez pour retirer le coffre" or "Utilise votre position actuelle",
        nil, "chevron", false,
        function()
            if newRoomData.chestCoords then
                -- Remove chest
                newRoomData.chestCoords = nil
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Coffre retiré' })
            else
                -- Set chest coords
                local playerPed <const> = PlayerPedId()
                local coords <const> = GetEntityCoords(playerPed)

                newRoomData.chestCoords = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                }

                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Position du coffre enregistrée' })
            end
            StaffMenu.motelAddRoom.refresh()
        end
    )

    StaffMenu.motelAddRoom.Separator(":tag: PROMOTIONS (override)")

    StaffMenu.motelAddRoom.Button(
        ":tag: Promotions: " .. FormatPromotions(newRoomData.promotions),
        "Promotions spécifiques à cette chambre (écrase le motel)",
        nil, "chevron", false,
        function() end,
        StaffMenu.motelAddRoomPromos
    )

    StaffMenu.motelAddRoom.Separator("")

    -- Confirm
    StaffMenu.motelAddRoom.Button(":check: Ajouter la chambre", "Valider et ajouter la chambre au motel", nil, "check", false, function()
        if not newRoomData.roomNumber then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Définissez un numéro de chambre' })
            return
        end

        if not newRoomData.label then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Définissez un nom pour la chambre' })
            return
        end

        if not newRoomData.doors or #newRoomData.doors == 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Sélectionnez au moins une porte' })
            return
        end

        -- Separate existing doorlock IDs and pending door data
        local existingIds = {}
        local pendingDoors = {}
        for _, door in ipairs(newRoomData.doors) do
            if door.existingId then
                existingIds[#existingIds + 1] = door.existingId
            else
                pendingDoors[#pendingDoors + 1] = { model = door.model, coords = door.coords, heading = door.heading }
            end
        end

        TriggerServerEvent("motel:server:admin:addRoom", {
            motelId = selectedMotel.id,
            roomNumber = newRoomData.roomNumber,
            label = newRoomData.label,
            doorlockIds = existingIds,
            pendingDoors = pendingDoors,
            priceOverride = newRoomData.priceOverride,
            chestCoords = newRoomData.chestCoords,
            promotions = newRoomData.promotions,
            iconOffsets = newRoomData.iconOffsets
        })

        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Chambre "' .. newRoomData.label .. '" ajoutée' })
        newRoomData = {}
        StaffMenu.motelRooms.open()
    end)
end)

-- ════════════════════════════════════════════
--  Edit Room Menu (modify existing room)
-- ════════════════════════════════════════════

--- Interactive icon offset positioning mode for motel room padlock
--- @param doorlockId number doorlock to preview against
--- @param initialOffset table|nil starting offset {x,y,z}
--- @param onDone function called with (confirmed, newOffset) — confirmed=false means cancel
StartIconOffsetMode = function(doorlockId, initialOffset, onDone)
    local _, doorlock = Doorlock:FindDoorlockById(doorlockId)
    if not doorlock then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Doorlock introuvable dans le cache' })
        onDone(false, initialOffset)
        return
    end

    local off = initialOffset
        and { x = tonumber(initialOffset.x) or 0.0, y = tonumber(initialOffset.y) or 0.0, z = tonumber(initialOffset.z) or 0.0 }
        or  { x = 0.0, y = 0.0, z = 0.0 }
    local step = 0.025
    local active = true

    -- Vecteur "droite" local de la porte : déplacement horizontal qui reste sur la surface
    -- heading 0 = Nord (+Y), 90 = Ouest (-X) → right = (cos(h), sin(h), 0)
    local doorHeading = (doorlock.doorsData and doorlock.doorsData[1] and doorlock.doorsData[1].heading) or 0.0
    local hRad = math.rad(doorHeading)
    local rightX = math.cos(hRad)
    local rightY = math.sin(hRad)

    RequestStreamedTextureDict('mpsafecracking', false)

    local motelDoorButtonId = generateUniqueID(8)

    CreateThread(function()
        -- Attendre que VUI ait fini de se fermer et relâcher le focus NUI
        Wait(300)
        VFW.Nui.Focus(false)

        instructionalButtons[motelDoorButtonId] = {
            { control = 201, label = "Confirmer" },
            { control = 194, label = "Annuler" },
            { control = 174, control2 = 175, label = "Gauche/Droite" },
            { control = 172, control2 = 173, label = "Haut/Bas" },
        }

        while active do
            if HasStreamedTextureDictLoaded('mpsafecracking') then
                local doorCoords = vector3(doorlock.coords.x, doorlock.coords.y, doorlock.coords.z)

                -- Live preview (yellow tint)
                SetDrawOrigin(doorCoords.x + off.x, doorCoords.y + off.y, doorCoords.z + off.z)
                DrawSprite('mpsafecracking', 'lock_closed', 0, 0, 0.018, 0.018 * GetAspectRatio(true), 0, 255, 215, 0, 230)
                ClearDrawOrigin()

                -- Gauche/Droite : déplacement le long de la surface de la porte (vecteur right local)
                if IsDisabledControlJustPressed(0, 174) then
                    off.x = off.x - step * rightX
                    off.y = off.y - step * rightY
                end
                if IsDisabledControlJustPressed(0, 175) then
                    off.x = off.x + step * rightX
                    off.y = off.y + step * rightY
                end

                -- Haut/Bas : axe Z monde (vertical)
                if IsDisabledControlJustPressed(0, 172) then off.z = off.z + step end
                if IsDisabledControlJustPressed(0, 173) then off.z = off.z - step end

                -- Entrée = confirmer (groupe 2 = frontend controls)
                if IsControlJustReleased(2, 201) then
                    active = false
                    instructionalButtons[motelDoorButtonId] = nil
                    onDone(true, off)
                    return
                end

                -- Suppr = annuler/revert (groupe 2)
                if IsControlJustReleased(2, 194) then
                    active = false
                    instructionalButtons[motelDoorButtonId] = nil
                    onDone(false, initialOffset)
                    return
                end
            end

            Wait(0)
        end
    end)
end

local editRoomData = {}

StaffMenu.motelRoomEdit.OnOpen(function()
    StaffMenu.motelRoomEdit.ClearItems()

    if not selectedRoom or not selectedMotel then return end

    -- Init edit data from current room values (only on first open, not on refresh)
    if not editRoomData or editRoomData._roomId ~= selectedRoom.id then
        editRoomData = {
            _roomId = selectedRoom.id,
            label = selectedRoom.label,
            roomNumber = selectedRoom.roomNumber,
            priceOverride = selectedRoom.priceOverride,
            doorlockIds = selectedRoom.doorlockIds or {},
            chestCoords = selectedRoom.chestCoords,
            chestMaxWeight = selectedRoom.chestMaxWeight,
            chestMaxSlots = selectedRoom.chestMaxSlots,
            promotions = selectedRoom.promotions,
            iconOffsets = selectedRoom.iconOffsets or {}
        }
    end

    StaffMenu.motelRoomEdit.Separator(":edit: MODIFIER · CHAMBRE " .. selectedRoom.roomNumber)

    -- Label
    StaffMenu.motelRoomEdit.Button(
        ":edit: Nom: " .. editRoomData.label,
        "Modifier le nom de la chambre",
        nil, "chevron", false,
        function()
            local label <const> = VFW.Nui.KeyboardInput(true, "Nom de la chambre")
            if label and string.len(label) > 0 then
                editRoomData.label = label
                StaffMenu.motelRoomEdit.refresh()
            end
        end
    )

    -- Room number
    StaffMenu.motelRoomEdit.Button(
        ":hash: Numéro: " .. editRoomData.roomNumber,
        "Modifier le numéro de la chambre",
        nil, "chevron", false,
        function()
            local num <const> = tonumber(VFW.Nui.KeyboardInput(true, "Numéro de la chambre"))
            if num and num > 0 then
                editRoomData.roomNumber = num
                StaffMenu.motelRoomEdit.refresh()
            end
        end
    )

    -- Price override
    StaffMenu.motelRoomEdit.Button(
        ":money: Prix custom: " .. (editRoomData.priceOverride and (VFW.Math.FormatMoney(editRoomData.priceOverride)) or "Prix du motel"),
        "Laisser vide pour utiliser le prix du motel",
        nil, "chevron", false,
        function()
            local price <const> = tonumber(VFW.Nui.KeyboardInput(true, "Prix custom (vide = prix motel)"))
            editRoomData.priceOverride = price
            StaffMenu.motelRoomEdit.refresh()
        end
    )

    -- Doorlocks section
    if not editRoomData.doorlockIds then editRoomData.doorlockIds = {} end

    StaffMenu.motelRoomEdit.Separator(":lock: PORTES (" .. #editRoomData.doorlockIds .. ")")

    if not editRoomData.iconOffsets then editRoomData.iconOffsets = {} end

    for i, dlId in ipairs(editRoomData.doorlockIds) do
        StaffMenu.motelRoomEdit.Button(
            ":lock: Porte #" .. dlId,
            "Téléporter, cadenas, retirer",
            nil, "chevron", false,
            function()
                selectedDoorContext = { index = i, dlId = dlId, source = "edit" }
            end,
            StaffMenu.motelEditDoorActions
        )
    end

    StaffMenu.motelRoomEdit.Button(
        ":plus: Ajouter une porte",
        "Visez la porte et appuyez sur E",
        nil, "chevron", false,
        function()
            StaffMenu.motelRoomEdit.close()

            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Motel', message = 'Visez la porte et appuyez sur E' })

            local entity, coords = SelectDoorVisually()

            if not entity or not coords then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Sélection annulée' })
                StaffMenu.motelRoomEdit.open()
                return
            end

            local existingDoorlockId <const> = FindDoorlockByEntity(entity)
            local doorlockToAdd = nil

            if existingDoorlockId then
                doorlockToAdd = existingDoorlockId
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Doorlock trouvé: #' .. existingDoorlockId })
            else
                local model <const> = GetEntityModel(entity)
                local heading <const> = GetEntityHeading(entity)

                local newId = TriggerServerCallback("doorlock:server:createCallback",
                    "Motel - " .. (editRoomData.label or "Chambre"),
                    2.0,
                    { x = coords.x, y = coords.y, z = coords.z },
                    { { model = model, coords = { x = coords.x, y = coords.y, z = coords.z }, heading = heading } },
                    nil,
                    nil
                )

                if newId then
                    doorlockToAdd = newId
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Nouveau doorlock créé: #' .. newId })
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Erreur lors de la création du doorlock' })
                end
            end

            if doorlockToAdd then
                -- Check for duplicates
                local alreadyAdded = false
                for _, id in ipairs(editRoomData.doorlockIds) do
                    if id == doorlockToAdd then alreadyAdded = true break end
                end
                if not alreadyAdded then
                    editRoomData.doorlockIds[#editRoomData.doorlockIds + 1] = doorlockToAdd
                else
                    VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Cette porte est déjà ajoutée' })
                end
            end

            StaffMenu.motelRoomEdit.open()
        end
    )

    StaffMenu.motelRoomEdit.Separator(":box: COFFRE")

    -- Chest placement
    StaffMenu.motelRoomEdit.Button(
        editRoomData.chestCoords and ":box: Coffre positionné :check:" or ":box: Pas de coffre",
        editRoomData.chestCoords and "Cliquez pour retirer le coffre" or "Cliquez pour placer un coffre à votre position",
        nil, "chevron", false,
        function()
            if editRoomData.chestCoords then
                editRoomData.chestCoords = nil
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Coffre retiré' })
            else
                local playerPed <const> = PlayerPedId()
                local coords <const> = GetEntityCoords(playerPed)

                editRoomData.chestCoords = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                }

                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Position du coffre enregistrée' })
            end
            StaffMenu.motelRoomEdit.refresh()
        end
    )

    StaffMenu.motelRoomEdit.Separator(":tag: PROMOTIONS (override)")

    StaffMenu.motelRoomEdit.Button(
        ":tag: Promotions: " .. FormatPromotions(editRoomData.promotions),
        "Promotions spécifiques à cette chambre (écrase le motel)",
        nil, "chevron", false,
        function() end,
        StaffMenu.motelEditRoomPromos
    )

    StaffMenu.motelRoomEdit.Separator("")

    -- Save
    StaffMenu.motelRoomEdit.Button(":save: Enregistrer", "Sauvegarder les modifications", nil, "check", false, function()
        local result <const> = TriggerServerCallback("motel:server:admin:updateRoom", {
            roomId = selectedRoom.id,
            label = editRoomData.label,
            roomNumber = editRoomData.roomNumber,
            priceOverride = editRoomData.priceOverride,
            doorlockIds = editRoomData.doorlockIds,
            chestCoords = editRoomData.chestCoords,
            chestMaxWeight = editRoomData.chestMaxWeight,
            chestMaxSlots = editRoomData.chestMaxSlots,
            promotions = editRoomData.promotions,
            iconOffsets = editRoomData.iconOffsets
        })

        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = result.message })
            -- Update selectedRoom for parent menu refresh
            selectedRoom.label = editRoomData.label
            selectedRoom.roomNumber = editRoomData.roomNumber
            selectedRoom.priceOverride = editRoomData.priceOverride
            selectedRoom.doorlockIds = editRoomData.doorlockIds
            selectedRoom.chestCoords = editRoomData.chestCoords
            selectedRoom.promotions = editRoomData.promotions
            selectedRoom.iconOffsets = editRoomData.iconOffsets
            editRoomData = {} -- Reset so next open reloads fresh data
            StaffMenu.motelRoomDetail.open()
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = result and result.message or "Erreur" })
        end
    end)
end)

-- ════════════════════════════════════════════
--  Add Room → Promotions Submenu
-- ════════════════════════════════════════════

StaffMenu.motelAddRoomPromos.OnOpen(function()
    StaffMenu.motelAddRoomPromos.ClearItems()

    StaffMenu.motelAddRoomPromos.Separator(":tag: PROMOTIONS · NOUVELLE CHAMBRE")

    for _, tier in ipairs(PROMO_TIERS) do
        local currentVal = newRoomData.promotions and newRoomData.promotions[tier.hours]
        local display = currentVal and ("-" .. currentVal .. "%") or "Aucune"

      StaffMenu.motelAddRoomPromos.Button(
            (":tag: %s: %s"):format(tier.label, display),
            "Réduction pour cette durée (0 = supprimer)",
            nil, "chevron", false,
            function()
                local val <const> = tonumber(VFW.Nui.KeyboardInput(true, ("Réduction %% pour %s (0 = supprimer)"):format(tier.label)))
                if val then
                    if not newRoomData.promotions then
                        newRoomData.promotions = {}
                    end
                    if val > 0 and val <= 100 then
                        newRoomData.promotions[tier.hours] = val
                    else
                        newRoomData.promotions[tier.hours] = nil
                    end
                    if not next(newRoomData.promotions) then
                        newRoomData.promotions = nil
                    end
                    StaffMenu.motelAddRoomPromos.refresh()
                end
            end
        )
    end

    StaffMenu.motelAddRoomPromos.Separator("")

    StaffMenu.motelAddRoomPromos.Button(
        ":trash: Supprimer toutes les promotions",
        FormatPromotions(newRoomData.promotions),
        nil, "trash", false,
        function()
            newRoomData.promotions = nil
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Promotions supprimées' })
            StaffMenu.motelAddRoomPromos.refresh()
        end
    )
end)

-- ════════════════════════════════════════════
--  Edit Room → Promotions Submenu
-- ════════════════════════════════════════════

StaffMenu.motelEditRoomPromos.OnOpen(function()
    StaffMenu.motelEditRoomPromos.ClearItems()

    StaffMenu.motelEditRoomPromos.Separator(":tag: PROMOTIONS · CHAMBRE " .. (selectedRoom and selectedRoom.roomNumber or "?"))

    for _, tier in ipairs(PROMO_TIERS) do
        local currentVal = editRoomData.promotions and editRoomData.promotions[tier.hours]
        local display = currentVal and ("-" .. currentVal .. "%") or "Aucune"

      StaffMenu.motelEditRoomPromos.Button(
            (":tag: %s: %s"):format(tier.label, display),
            "Réduction pour cette durée (0 = supprimer)",
            nil, "chevron", false,
            function()
                local val <const> = tonumber(VFW.Nui.KeyboardInput(true, ("Réduction %% pour %s (0 = supprimer)"):format(tier.label)))
                if val then
                    if not editRoomData.promotions then
                        editRoomData.promotions = {}
                    end
                    if val > 0 and val <= 100 then
                        editRoomData.promotions[tier.hours] = val
                    else
                        editRoomData.promotions[tier.hours] = nil
                    end
                    if not next(editRoomData.promotions) then
                        editRoomData.promotions = nil
                    end
                    StaffMenu.motelEditRoomPromos.refresh()
                end
            end
        )
    end

    StaffMenu.motelEditRoomPromos.Separator("")

    StaffMenu.motelEditRoomPromos.Button(
        ":trash: Supprimer toutes les promotions",
        FormatPromotions(editRoomData.promotions),
        nil, "trash", false,
        function()
            editRoomData.promotions = nil
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Promotions supprimées' })
            StaffMenu.motelEditRoomPromos.refresh()
        end
    )
end)

-- ════════════════════════════════════════════
--  Motel Logs Menu
-- ════════════════════════════════════════════

StaffMenu.motelLogs.OnOpen(function()
    StaffMenu.motelLogs.ClearItems()

    if not selectedMotel then
        StaffMenu.motelLogs.Button("Erreur", "Aucun motel sélectionné", nil, nil, true, function() end)
        return
    end

    StaffMenu.motelLogs.Separator(":report: LOGS · " .. selectedMotel.name:upper())

    local logs = TriggerServerCallback("motel:server:staff:getMotelLogs", selectedMotel.id) or {}

    if #logs == 0 then
        StaffMenu.motelLogs.Button("Aucun log", "Aucun historique pour ce motel", nil, nil, true, function() end)
        return
    end

    for _, log in ipairs(logs) do
        local actionLabel = logActionLabels[log.action] or log.action
        local roomInfo = log.room_label and (" · " .. log.room_label) or ""
      local label = ("[%s] %s%s"):format(log.created_at_formatted or "?", actionLabel, roomInfo)
        local desc = ("%s : %s"):format(log.player_name or "Système", log.details or "")

        StaffMenu.motelLogs.Button(label, desc, nil, "trash", false, function()
            local confirm <const> = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer ce log")
            if not confirm or string.upper(confirm) ~= "OUI" then return end

            local result <const> = TriggerServerCallback("motel:server:staff:deleteLog", log.id)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Log supprimé' })
                StaffMenu.motelLogs.refresh()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = result and result.message or 'Erreur' })
            end
        end)
    end
end)

-- ════════════════════════════════════════════
--  Door Actions Sub-Menu (Add Room)
-- ════════════════════════════════════════════

StaffMenu.motelAddDoorActions.OnOpen(function()
    StaffMenu.motelAddDoorActions.ClearItems()

    local ctx = selectedDoorContext
    if not ctx or ctx.source ~= "add" then return end

    local door = ctx.door
    local doorLabel = door.existingId and ("PORTE #" .. door.existingId) or ("NOUVELLE PORTE #" .. ctx.index)
    StaffMenu.motelAddDoorActions.Separator(":lock: " .. doorLabel)

    -- TP
    local doorCoords = nil
    if door.existingId then
        local _, dl = Doorlock:FindDoorlockById(door.existingId)
        if dl then doorCoords = dl.coords end
    elseif door.coords then
        doorCoords = door.coords
    end

    StaffMenu.motelAddDoorActions.Button(
        ":pin: Téléporter",
        doorCoords and "Se téléporter à cette porte" or "Coordonnées indisponibles",
        nil, "chevron", not doorCoords,
        function()
            if doorCoords then
                StaffMenu.motelAddDoorActions.close()
                SetEntityCoords(PlayerPedId(), doorCoords.x, doorCoords.y, doorCoords.z, false, false, false, true)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Téléporté' })
                Wait(500)
                StaffMenu.motelAddDoorActions.open()
            end
        end
    )

    -- Icon offset (only for existing doorlocks)
    if door.existingId then
        if not newRoomData.iconOffsets then newRoomData.iconOffsets = {} end
        local doorOffset = newRoomData.iconOffsets[tostring(door.existingId)]
        local offsetLabel = doorOffset
            and ("X:%.3f Y:%.3f Z:%.3f"):format(doorOffset.x or 0, doorOffset.y or 0, doorOffset.z or 0)
            or "Défaut"

      StaffMenu.motelAddDoorActions.Button(
            ":lock: Cadenas: " .. offsetLabel,
            "Modifier l'offset du cadenas",
            nil, "chevron", false,
            function()
                StaffMenu.motelAddDoorActions.close()
                StartIconOffsetMode(door.existingId, doorOffset, function(confirmed, newOffset)
                    if confirmed then
                        local isZero = newOffset.x == 0.0 and newOffset.y == 0.0 and newOffset.z == 0.0
                        newRoomData.iconOffsets[tostring(door.existingId)] = isZero and nil or newOffset
                        local _, dl = Doorlock:FindDoorlockById(door.existingId)
                        if dl then dl.iconOffset = newRoomData.iconOffsets[tostring(door.existingId)] end
                    end
                    StaffMenu.motelAddDoorActions.open()
                end)
            end
        )
    end

    -- Delete
    StaffMenu.motelAddDoorActions.Button(
        ":trash: Retirer cette porte",
        door.existingId and ("Supprimer le doorlock #" .. door.existingId) or "Retirer de la liste",
        nil, "trash", false,
        function()
            if door.existingId then
                if newRoomData.iconOffsets then
                    newRoomData.iconOffsets[tostring(door.existingId)] = nil
                end
                TriggerServerEvent("doorlock:server:delete", door.existingId)
            end
            table.remove(newRoomData.doors, ctx.index)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Porte retirée' })
            StaffMenu.motelAddRoom.open()
        end
    )
end)

-- ════════════════════════════════════════════
--  Door Actions Sub-Menu (Edit Room)
-- ════════════════════════════════════════════

StaffMenu.motelEditDoorActions.OnOpen(function()
    StaffMenu.motelEditDoorActions.ClearItems()

    local ctx = selectedDoorContext
    if not ctx or ctx.source ~= "edit" then return end

    local dlId = ctx.dlId
    StaffMenu.motelEditDoorActions.Separator(":lock: PORTE #" .. dlId)

    -- TP
    StaffMenu.motelEditDoorActions.Button(
        ":pin: Téléporter",
        "Se téléporter à cette porte",
        nil, "chevron", false,
        function()
            local _, dl = Doorlock:FindDoorlockById(dlId)
            if dl and dl.coords then
                StaffMenu.motelEditDoorActions.close()
                SetEntityCoords(PlayerPedId(), dl.coords.x, dl.coords.y, dl.coords.z, false, false, false, true)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Téléporté à la porte #' .. dlId })
                Wait(500)
                StaffMenu.motelEditDoorActions.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Motel', message = 'Coordonnées introuvables pour #' .. dlId })
            end
        end
    )

    -- Icon offset
    if not editRoomData.iconOffsets then editRoomData.iconOffsets = {} end
    local doorOffset = editRoomData.iconOffsets[tostring(dlId)]
    local offsetLabel = doorOffset
        and ("X:%.3f Y:%.3f Z:%.3f"):format(doorOffset.x or 0, doorOffset.y or 0, doorOffset.z or 0)
        or "Défaut"

  StaffMenu.motelEditDoorActions.Button(
        ":lock: Cadenas: " .. offsetLabel,
        "Modifier l'offset du cadenas",
        nil, "chevron", false,
        function()
            StaffMenu.motelEditDoorActions.close()
            StartIconOffsetMode(dlId, doorOffset, function(confirmed, newOffset)
                if confirmed then
                    local isZero = newOffset.x == 0.0 and newOffset.y == 0.0 and newOffset.z == 0.0
                    editRoomData.iconOffsets[tostring(dlId)] = isZero and nil or newOffset
                    local _, dl = Doorlock:FindDoorlockById(dlId)
                    if dl then dl.iconOffset = editRoomData.iconOffsets[tostring(dlId)] end
                end
                StaffMenu.motelEditDoorActions.open()
            end)
        end
    )

    -- Delete
    StaffMenu.motelEditDoorActions.Button(
        ":trash: Retirer cette porte",
        "Supprimer le doorlock #" .. dlId,
        nil, "trash", false,
        function()
            table.remove(editRoomData.doorlockIds, ctx.index)
            if editRoomData.iconOffsets then
                editRoomData.iconOffsets[tostring(dlId)] = nil
            end
            TriggerServerEvent("doorlock:server:delete", dlId)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Motel', message = 'Porte #' .. dlId .. ' supprimée' })
            StaffMenu.motelRoomEdit.open()
        end
    )
end)
