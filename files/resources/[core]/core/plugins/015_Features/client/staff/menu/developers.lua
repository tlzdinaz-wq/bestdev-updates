---@meta _
---@diagnostic disable: duplicate-doc-field

StaffMenu.isInDevMode = true
StaffMenu.PrintPropsAndEntities = true
StaffMenu.hasDevWeight = false

--- .BuildDevelopersMenu
function StaffMenu.BuildDevelopersMenu()
    local perms = VFW.StaffPerms()
    StaffMenu.developers.Checkbox(":monitor: MODE DÉVELOPPEUR", nil, false, StaffMenu.isInDevMode, function(_checked)
        StaffMenu.isInDevMode = _checked
        VFW.ShowNotification({
            type = 'STAFF', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Outils Dev',
            message = _checked and "Mode développeur activé." or "Mode développeur désactivé."
      })
    end)

    StaffMenu.developers.Checkbox(":search: PRINT PROPS & ENTITIES", nil, false, StaffMenu.PrintPropsAndEntities, function(_checked)
        StaffMenu.PrintPropsAndEntities = _checked
        VFW.ShowNotification({
            type = 'STAFF', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Outils Dev',
            message = _checked and "Print Props & Entities activé." or "Print Props & Entities désactivé."
      })
    end)

    StaffMenu.developers.Checkbox(":scales: POIDS DÉVELOPPEUR", "Activer le poids max de 5000 kg", false, StaffMenu.hasDevWeight, function(_checked)
        StaffMenu.hasDevWeight = _checked
        TriggerServerEvent("vfw:staff:toggleDevWeight", _checked)
        VFW.ShowNotification({
            type = 'STAFF', variant = _checked and 'SUCCESS' or 'INFO', subtitle = 'Outils Dev',
            message = _checked and "Poids développeur activé (5000 kg)." or "Poids développeur désactivé."
      })
    end)

    StaffMenu.developers.Separator()

    StaffMenu.developers.Button(":film: CRÉATION DE CAMÉRA", nil, nil, "chevron", false, function()
    end, StaffMenu.camera)


    if perms["gestion_items"] then
        StaffMenu.developers.Button(":box: ITEMS", nil, nil, "chevron", false, function()
        end, StaffMenu.gestionItems)
    end

    if perms["wipe"] then
        StaffMenu.developers.Button(":monitor: GESTION TÉLÉPHONE", "Supprimer messages, mails, posts d'un joueur", nil, "chevron", false, function() end, StaffMenu.gestionPhone)
    end

    if perms["dev"] then
        StaffMenu.developers.Button(":car: LISTE DES VÉHICULES", "Consulter la liste des véhicules du serveur", nil, "chevron", false, function() end, StaffMenu.carlistMain)
    end

    StaffMenu.developers.Separator(":wrench: OUTILS DE DÉVELOPPEMENT")

    if perms["manage_anim"] then
        StaffMenu.developers.Button(":film: ANIMATION MANAGER", "Gérer les animations", nil, "chevron", false, function()
        end, StaffMenu.animManager)
    end

    if perms["dev"] then
        StaffMenu.developers.Button(":ruler: APPLIQUER UNE TAILLE", "Modifier la taille du ped d'un joueur (0.1 - 2.0). Entrer 1 pour réinitialiser.", nil, nil, false, function()
            local idInput = VFW.Nui.KeyboardInput(true, "ID du joueur cible", "")
            if not idInput or idInput == "" then return end
            local targetId = tonumber(idInput)
            if not targetId then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Cet identifiant n'est pas valide." })
                return
            end

            local scaleInput = VFW.Nui.KeyboardInput(true, "Taille du ped (0.1 - 2.0)", "1.0")
            if not scaleInput or scaleInput == "" then return end
            local scale = tonumber((scaleInput:gsub(",", ".")))
            if not scale then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Cette valeur n'est pas valide." })
                return
            end

            local success, applied = TriggerServerCallback("vfw:staff:applyPedScale", targetId, scale)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Dev', message = "Taille " .. tostring(applied) .. " appliquée sur [" .. targetId .. "]" })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Impossible d'appliquer la taille." })
            end
        end)
    end

    StaffMenu.developers.Button(":pin: PRINT COORDS", "Afficher les coordonnées dans la console F8", nil, nil, false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        -- Print to F8 console
        print(string.format("^2Coordonnées:^0 x=%.2f, y=%.2f, z=%.2f, heading=%.2f", coords.x, coords.y, coords.z, heading))
        print(string.format("^3Vector3:^0 vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z))
        print(string.format("^3Vector4:^0 vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading))

        -- Also show notification
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Dev',
            message = "Coordonnées affichées dans la console F8."
      })
    end)

    StaffMenu.developers.Button(":pin: PRINT GROUND COORDS", "Afficher les coordonnées du sol dans la console F8", nil, nil, false, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        -- Get ground Z position
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        if found then
            coords = vector3(coords.x, coords.y, groundZ)
        end

        -- Print to F8 console
        print(string.format("^2Coordonnées Sol:^0 x=%.2f, y=%.2f, z=%.2f, heading=%.2f", coords.x, coords.y, coords.z, heading))
        print(string.format("^3Vector3:^0 vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z))
        print(string.format("^3Vector4:^0 vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading))

        -- Also show notification
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Dev',
            message = "Coordonnées du sol affichées dans la console F8."
      })
    end)

    StaffMenu.developers.Button(":ruler: PROP PLACER", "Outil de placement de props", nil, "chevron", false, function()
        -- Only allow in dev mode
        if not StaffMenu.isInDevMode then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev',
                message = "Activez le mode développeur pour utiliser cet outil."
          })
            return
        end

        -- Start prop placer and open menu
        if PropPlacer and PropPlacer.Toggle then
            if not PropPlacer.active then
                PropPlacer.Toggle()
            end

            -- Build the menu
            if StaffMenu.BuildPropPlacerMenu then
                StaffMenu.BuildPropPlacerMenu()
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev',
                message = "Prop Placer non disponible."
          })
        end
    end, StaffMenu.propPlacer)

    StaffMenu.developers.Button(":scales: GESTION POIDS JOUEURS", "Modifier le poids des joueurs", nil, "chevron", false, function()
    end, StaffMenu.weightManagement)

    StaffMenu.developers.Button(":map: LISTE DES MAPPINGS", "Gérer les mappings de la carte (Dev only)", nil, "chevron", false, function()
        if not StaffMenu.isInDevMode then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Activez le mode développeur pour utiliser cet outil." })
            return
        end
        -- open the submenu
    end, StaffMenu.mapCoords)

    if perms["staff_logs"] then
        StaffMenu.developers.Button(":report: STAFF LOGS", "Voir les logs envoyés et la file d'attente", nil, "chevron", false, function()
        end, StaffMenu.staffLogs)
    end

    if perms["dev"] then
        StaffMenu.developers.Button(":report: WEBHOOKS LOGS", "Configurer les webhooks Discord par type de log", nil, "chevron", false, function()
        end, StaffMenu.webhookLogs)
    end

    if perms["gestion_items"] then
        StaffMenu.developers.Separator(":target: ACTIONS DE MASSE")

        StaffMenu.developers.Button(":gift: DONNER ITEM À TOUS", nil, nil, "chevron", false, function()
            -- Refresh items list when opening the menu
            StaffMenu.itemSearchQuery = nil
        end, StaffMenu.giveAllItems)
    end

    if perms["dev"] then
        StaffMenu.developers.Button(":clock: BYPASS COOLDOWN", "Gérer les bypass de cooldown commandes staff", nil, "chevron", false, function()
        end, StaffMenu.bypassCooldown)

        StaffMenu.developers.Button(":shield: ANTIBAN", "Gérer la liste des joueurs protégés", nil, "chevron", false, function()
        end, StaffMenu.antibanMenu)

        StaffMenu.developers.Button(":trash: RESET SANCTIONS JOUEUR", "Supprimer toutes les sanctions d'un joueur (warns/kicks/bans/TIG)", nil, "chevron", false, function()
            StaffMenu.resetSanctionsQuery = nil
            StaffMenu.resetSanctionsResults = {}
            StaffMenu.resetSanctionsSelected = nil
        end, StaffMenu.resetSanctions)
    end

    if perms["restore_inventory"] then
        StaffMenu.developers.Button(":refresh: RESTAURATION INVENTAIRE", "Restaurer un inventaire confisqué (10 jours)", nil, "chevron", false, function()
            StaffMenu._inventoryRestoreFilter = StaffMenu._inventoryRestoreFilter or "pending"
      end, StaffMenu.inventoryRestore)
    end

    if perms["dev"] then

        StaffMenu.developers.Button(":ban: VEHICULE BLACKLIST", "Bloquer le spawn de modèles de véhicules", nil, "chevron", false, function()
        end, StaffMenu.vehBlacklist)

        StaffMenu.developers.Button(":flask: POTIONS", "Gérer les potions de farm", nil, "chevron", false, function()
        end, StaffMenu.potionsMenu)

        StaffMenu.developers.Button(":box: POIDS DES SACS", "Configurer le poids par modèle de sac", nil, "chevron", false, function()
        end, StaffMenu.bagWeightBuilder)

        StaffMenu.developers.Button(":shield: PLAQUES GPB", "Autoriser ou bloquer les plaques par type de GPB", nil, "chevron", false, function()
        end, StaffMenu.gpbPlatesBuilder)

        StaffMenu.developers.Button(":gift: STARTER PACK", "Configurer le pack de départ des nouveaux joueurs", nil, "chevron", false, function()
        end, StaffMenu.starterPack)

        StaffMenu.developers.Button(":megaphone: NOTIFICATIONS PÉRIODIQUES", "Créer et gérer des notifications automatiques", nil, nil, false, function()
            if StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
                OpenPeriodicNotificationsPanel()
                return
            end
            OpenPeriodicNotificationsPanel()
        end)

        StaffMenu.developers.Button(":image: GÉRER LES IMAGES", "Visualiser et refaire les mugshots des joueurs", nil, nil, false, function()
            if StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
                StaffMenu.OpenImageManager()
                return
            end
            StaffMenu.OpenImageManager()
        end)

        StaffMenu.developers.Button(" SPAWNPOINTS GARAGE", "Outil de placement des spawnPoints garage (mirror/array)", nil, nil, false, function()
            StaffMenu.OpenGarageSpawnPointsBuilder()
        end)

    end
end

-- ── Bag Weight Builder ──

local bagSavedSkin = nil
local bagSex = "m"
local bagSkinRestored = false

local function bagPreview(drawableId)
    if not bagSkinRestored and bagSavedSkin then
        TriggerEvent('skinchanger:loadSkin', bagSavedSkin)
        Wait(200)
        bagSkinRestored = true
    end
    SetPedComponentVariation(PlayerPedId(), 5, drawableId, 0, 2)
end

local function getBagGroups()
    local ped = PlayerPedId()
    local maxDrawables = GetNumberOfPedDrawableVariations(ped, 5)
    local bags = {}

    for i = 0, maxDrawables - 1 do
        bags[#bags + 1] = { representative = i, drawables = { i } }
    end

    return bags
end

StaffMenu.bagWeightBuilder.OnOpen(function()
    local bagConfig = TriggerServerCallback("bagweight:getConfig") or {}

    TriggerEvent('skinchanger:getSkin', function(skin)
        bagSavedSkin = skin
        bagSex = skin.sex == 1 and "f" or "m"
  end)

    local groups = getBagGroups()

    for _, bag in ipairs(groups) do
        local rep = bag.representative
        local key = bagSex .. "_" .. tostring(rep)
        local weight = bagConfig[key]
        local weightLabel = weight and (tostring(weight) .. " kg") or "Défaut (10 kg)"
      local label = ("Sac #%d"):format(rep)

        StaffMenu.bagWeightBuilder.Button(label, weightLabel, nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, ("Poids %s (kg, -1 = supprimer config)"):format(label), tostring(weight or 10))
            if input and input ~= "" then
                local w = tonumber(input)
                if w and w >= 0 then
                    TriggerServerCallback("bagweight:setWeight", bagSex, rep, w)
                elseif w and w == -1 then
                    TriggerServerCallback("bagweight:removeWeight", bagSex, rep)
                end
            end
            StaffMenu.bagWeightBuilder.refresh()
        end)
    end

    StaffMenu.bagWeightBuilder.OnIndexChange(function(index)
        local bag = groups[index]
        if bag then
            bagPreview(bag.representative)
        end
    end)

    if groups[1] then
        bagPreview(groups[1].representative)
    end
end)

StaffMenu.bagWeightBuilder.OnClose(function()
    if bagSavedSkin then
        TriggerEvent('skinchanger:loadSkin', bagSavedSkin)
        bagSavedSkin = nil
    end
    bagSkinRestored = false
end)

-- ── GPB Plates Builder ──

local gpbSavedSkin = nil
local gpbSex = "m"
local gpbSkinRestored = false

local function gpbPreview(drawableId)
    if not gpbSkinRestored and gpbSavedSkin then
        TriggerEvent('skinchanger:loadSkin', gpbSavedSkin)
        Wait(200)
        gpbSkinRestored = true
    end
    SetPedComponentVariation(PlayerPedId(), 9, drawableId, 0, 2)
end

local function getGpbList()
    local ped = PlayerPedId()
    local maxDrawables = GetNumberOfPedDrawableVariations(ped, 9)
    local list = {}

    for i = 0, maxDrawables - 1 do
        list[#list + 1] = i
    end

    return list
end

StaffMenu.gpbPlatesBuilder.OnOpen(function()
    local gpbConfig = TriggerServerCallback("gpbplates:getConfig") or {}

    TriggerEvent('skinchanger:getSkin', function(skin)
        gpbSavedSkin = skin
        gpbSex = skin.sex == 1 and "f" or "m"
  end)

    local drawables = getGpbList()

    for _, drawableId in ipairs(drawables) do
        local key = gpbSex .. "_" .. tostring(drawableId)
        local allowed = gpbConfig[key] ~= false
        local statusLabel = allowed and ":check: Plaques autorisées" or ":x: Plaques interdites"
      local label = ("GPB #%d"):format(drawableId)

        StaffMenu.gpbPlatesBuilder.Button(label, statusLabel, nil, "chevron", false, function()
            local newAllowed = not allowed
            TriggerServerCallback("gpbplates:setAllowed", gpbSex, drawableId, newAllowed)
            StaffMenu.gpbPlatesBuilder.refresh()
        end)
    end

    StaffMenu.gpbPlatesBuilder.OnIndexChange(function(index)
        local drawableId = drawables[index]
        if drawableId then
            gpbPreview(drawableId)
        end
    end)

    if drawables[1] then
        gpbPreview(drawables[1])
    end
end)

StaffMenu.gpbPlatesBuilder.OnClose(function()
    if gpbSavedSkin then
        TriggerEvent('skinchanger:loadSkin', gpbSavedSkin)
        gpbSavedSkin = nil
    end
    gpbSkinRestored = false
end)

-- ── Starter Pack Menu ──

StaffMenu.starterPack.OnOpen(function()
    local config = TriggerServerCallback("starterpack:getConfig")
    if not config then
        StaffMenu.starterPack.Button("Erreur", "Impossible de charger la configuration", nil, nil, true, function() end)
        return
    end

    StaffMenu.starterPack.Separator(":money: ARGENT DE DÉPART")

    StaffMenu.starterPack.Button(":building: Banque : " .. VFW.Math.FormatMoney(config.bank or 0), "Modifier le montant en banque", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant en banque", tostring(config.bank or 0))
        if not input or input == "" then return end
        local amount = tonumber(input)
        if not amount or amount < 0 then
            VFW.ShowNotification({ type = "ROUGE", content = "Ce montant n'est pas valide" })
            return
        end
        local result = TriggerServerCallback("starterpack:setBank", amount)
        if result then
            VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Starter Pack", message = "Banque mise à jour : " .. VFW.Math.FormatMoney(amount) })
        end
        StaffMenu.starterPack.refresh()
    end)

    StaffMenu.starterPack.Button(":money: Cash : " .. VFW.Math.FormatMoney(config.cash or 0), "Modifier le montant en liquide", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Montant en liquide", tostring(config.cash or 0))
        if not input or input == "" then return end
        local amount = tonumber(input)
        if not amount or amount < 0 then
            VFW.ShowNotification({ type = "ROUGE", content = "Ce montant n'est pas valide" })
            return
        end
        local result = TriggerServerCallback("starterpack:setCash", amount)
        if result then
            VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Starter Pack", message = "Cash mis à jour : " .. VFW.Math.FormatMoney(amount) })
        end
        StaffMenu.starterPack.refresh()
    end)

    StaffMenu.starterPack.Separator(":box: ITEMS DE DÉPART")

    local items = config.items
    if type(items) == "table" and #items > 0 then
        for _, item in ipairs(items) do
            local itemData = VFW.Items and VFW.Items[item.name]
            local label = itemData and itemData.label or item.name
            StaffMenu.starterPack.Button(label .. " (x" .. tostring(item.count) .. ")", "Cliquer pour supprimer", nil, "trash", false, function()
                local result = TriggerServerCallback("starterpack:removeItem", item.name)
                if result then
                    VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Starter Pack", message = label .. " retiré du starter pack" })
                end
                StaffMenu.starterPack.refresh()
            end)
        end
    else
        StaffMenu.starterPack.Button("Aucun item", "Le starter pack ne contient aucun item", nil, nil, true, function() end)
    end

    StaffMenu.starterPack.Separator()

    StaffMenu.starterPack.Button(":plus: Ajouter un item", "Ajouter un item au starter pack", nil, "chevron", false, function()
        local itemName = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: bread)")
        if not itemName or itemName == "" then return end

        local countInput = VFW.Nui.KeyboardInput(true, "Quantité", "1")
        if not countInput or countInput == "" then return end
        local count = tonumber(countInput)
        if not count or count <= 0 then
            VFW.ShowNotification({ type = "ROUGE", content = "Cette quantité n'est pas valide" })
            return
        end

        local result = TriggerServerCallback("starterpack:addItem", itemName, count)
        if result then
            local itemData = VFW.Items and VFW.Items[itemName]
            local label = itemData and itemData.label or itemName
            VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Starter Pack", message = label .. " (x" .. tostring(count) .. ") ajouté" })
        end
        StaffMenu.starterPack.refresh()
    end)
end)

-- ── Potions Menu ──

local function GivePotionToPlayer(potionItem, label)
    local idInput = VFW.Nui.KeyboardInput(true, "ID serveur du joueur (ou 'me')")
    if not idInput or idInput == "" then return end

    local qtyInput = VFW.Nui.KeyboardInput(true, "Quantité")
    if not qtyInput or qtyInput == "" then return end

    local qty = tonumber(qtyInput)
    if not qty or qty <= 0 then
        VFW.ShowNotification({ type = "ROUGE", content = "Cette quantité n'est pas valide" })
        return
    end

    local targetId = idInput == "me" and GetPlayerServerId(PlayerId()) or tonumber(idInput)
    if not targetId then
        VFW.ShowNotification({ type = "ROUGE", content = "Cet identifiant n'est pas valide" })
        return
    end

    local res = TriggerServerCallback("vfw:dev:giveRestrictedItem", {
        targetId = targetId,
        item = potionItem,
        amount = qty
    })

    if res and res.success then
        VFW.ShowNotification({ type = "VERT", content = res.message })
    else
        VFW.ShowNotification({ type = "ROUGE", content = res and res.message or "Erreur" })
    end
end

function StaffMenu.BuildPotionsMenu()
    local categories = {
        {
            separator = ":bolt: BOOST x2",
            potions = {
                { item = "potion_1", emoji = ":clock:" },
                { item = "potion_2", emoji = ":clock:" },
                { item = "potion_3", emoji = ":clock:" },
            }
        },
        {
            separator = ":shield: BOOST x3",
            potions = {
                { item = "potion_4", emoji = ":clock:" },
                { item = "potion_5", emoji = ":clock:" },
                { item = "potion_6", emoji = ":clock:" },
            }
        },
        {
            separator = ":fire: BOOST x4",
            potions = {
                { item = "potion_7", emoji = ":clock:" },
                { item = "potion_8", emoji = ":clock:" },
                { item = "potion_9", emoji = ":clock:" },
            }
        },
    }

    for _, category in ipairs(categories) do
        StaffMenu.potionsMenu.Separator(category.separator)
        for _, potion in ipairs(category.potions) do
            local itemData = VFW.Items[potion.item]
            local label = itemData and itemData.label or potion.item
            StaffMenu.potionsMenu.Button(potion.emoji .. " " .. label, "Donner à un joueur", nil, "chevron", false, function()
                GivePotionToPlayer(potion.item, label)
            end)
        end
    end
end

-- ── Staff Logs — Logs récents ──

function StaffMenu.BuildStaffLogsRecentMenu()
    StaffMenu.staffLogsRecent.ClearItems()

    StaffMenu.staffLogsRecent.Button(":refresh: Rafraîchir", nil, nil, nil, false, function()
        StaffMenu.BuildStaffLogsRecentMenu()
    end)

    StaffMenu.staffLogsRecent.Button(":trash: Clear", "Vider la liste des logs récents", nil, nil, false, function()
        TriggerServerCallback("vfw:stafflogs:clearRecent")
        StaffMenu.BuildStaffLogsRecentMenu()
    end)

    local logs = TriggerServerCallback("vfw:stafflogs:getRecent") or {}

    if #logs == 0 then
        StaffMenu.staffLogsRecent.Separator("Aucun log récent")
        return
    end

    StaffMenu.staffLogsRecent.Separator(#logs .. " derniers logs envoyés")

    for _, log in ipairs(logs) do
        local label = "[" .. (log.category or "?") .. "] " .. (log.type or "?")
        local desc  = (log.source or "?") .. " : " .. (log.message or "")
        StaffMenu.staffLogsRecent.Button(label, desc, nil, "chevron", false, function()
            StaffMenu.selectedLog = log
        end, StaffMenu.staffLogsDetail)
    end
end

-- ── Staff Logs — Détail d'un log ──

function StaffMenu.BuildStaffLogsDetailMenu()
    StaffMenu.staffLogsDetail.ClearItems()

    local log = StaffMenu.selectedLog
    if not log then
        StaffMenu.staffLogsDetail.Separator("Aucun log sélectionné")
        return
    end

    StaffMenu.staffLogsDetail.Separator("[" .. (log.category or "?") .. "] " .. (log.type or "?"))

    -- Message
    if log.message and log.message ~= "" then
        StaffMenu.staffLogsDetail.Button(":chat: Message", log.message, nil, nil, true, function() end)
    end

    -- Timestamp
    if log.timestamp and log.timestamp ~= "" then
        StaffMenu.staffLogsDetail.Button(":clock: Date", log.timestamp, nil, nil, true, function() end)
    end

    -- Source
    StaffMenu.staffLogsDetail.Separator("SOURCE")
    StaffMenu.staffLogsDetail.Button(":user: " .. (log.source or "?"), log.sourceId or "?", nil, nil, true, function()
        if log.sourceId then
            VFW.Clipboard(log.sourceId)
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = "Identifiant copié." })
        end
    end)

    -- Target
    if log.target then
        StaffMenu.staffLogsDetail.Separator("CIBLE")
        StaffMenu.staffLogsDetail.Button(":target: " .. log.target, log.targetId or "?", nil, nil, true, function()
            if log.targetId then
                VFW.Clipboard(log.targetId)
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = "Identifiant copié." })
            end
        end)
    end

    -- Coords
    if log.coords then
        local coordStr = string.format("%.1f, %.1f, %.1f", log.coords.x or 0, log.coords.y or 0, log.coords.z or 0)
        StaffMenu.staffLogsDetail.Separator("POSITION")
        StaffMenu.staffLogsDetail.Button(":pin: Coordonnées", coordStr, nil, nil, true, function()
            VFW.Clipboard(coordStr)
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = "Coordonnées copiées." })
        end)
    end

    -- Data
    if log.data and next(log.data) then
        StaffMenu.staffLogsDetail.Separator("DONNÉES")
        for key, value in pairs(log.data) do
            local valStr = type(value) == "table" and json.encode(value) or tostring(value)
            StaffMenu.staffLogsDetail.Button(tostring(key), valStr, nil, nil, true, function()
                VFW.Clipboard(valStr)
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = tostring(key) .. " copié." })
            end)
        end
    end

end

-- ── Staff Logs — File d'attente ──

function StaffMenu.BuildStaffLogsQueueMenu()
    StaffMenu.staffLogsQueue.ClearItems()

    StaffMenu.staffLogsQueue.Button(":refresh: Rafraîchir", nil, nil, nil, false, function()
        StaffMenu.BuildStaffLogsQueueMenu()
    end)

    StaffMenu.staffLogsQueue.Button(":trash: Clear", "Vider toute la file d'attente", nil, nil, false, function()
        TriggerServerCallback("vfw:stafflogs:clearQueue")
        StaffMenu.BuildStaffLogsQueueMenu()
    end)

    local logs, errorInfo = TriggerServerCallback("vfw:stafflogs:getQueue")
    logs = logs or {}

    if errorInfo then
        StaffMenu.staffLogsQueue.Separator(":warning: ERREUR API")
        StaffMenu.staffLogsQueue.Button(
            "HTTP " .. tostring(errorInfo.statusCode),
            errorInfo.errorCount .. " tentatives échouées, " .. errorInfo.count .. " logs en attente",
            nil, nil, false, function() end
        )
        StaffMenu.staffLogsQueue.Separator()
    else
        StaffMenu.staffLogsQueue.Separator(":check: API opérationnelle")
    end

    if #logs == 0 then
        StaffMenu.staffLogsQueue.Separator("File d'attente vide")
        return
    end

    StaffMenu.staffLogsQueue.Separator(#logs .. " logs en attente")

    for _, log in ipairs(logs) do
        local label = "[" .. (log.category or "?") .. "] " .. (log.type or "?")
        local desc  = (log.source or "?") .. " : " .. (log.message or "")
        StaffMenu.staffLogsQueue.Button(label, desc, nil, "chevron", false, function()
            StaffMenu.selectedQueueLog = log
            StaffMenu.queueErrorInfo = errorInfo
        end, StaffMenu.staffLogsQueueDetail)
    end
end

-- ── Staff Logs — Détail d'un log en file d'attente ──

function StaffMenu.BuildStaffLogsQueueDetailMenu()
    StaffMenu.staffLogsQueueDetail.ClearItems()

    local log = StaffMenu.selectedQueueLog
    if not log then
        StaffMenu.staffLogsQueueDetail.Separator("Aucun log sélectionné")
        return
    end

    StaffMenu.staffLogsQueueDetail.Separator("[" .. (log.category or "?") .. "] " .. (log.type or "?"))

    -- Error info
    local errInfo = StaffMenu.queueErrorInfo
    if errInfo then
        StaffMenu.staffLogsQueueDetail.Separator(":warning: ERREUR")
        StaffMenu.staffLogsQueueDetail.Button(":x: HTTP " .. tostring(errInfo.statusCode), errInfo.errorCount .. " tentatives échouées", nil, nil, true, function() end)
    end

    -- Message
    if log.message and log.message ~= "" then
        StaffMenu.staffLogsQueueDetail.Button(":chat: Message", log.message, nil, nil, true, function() end)
    end

    -- Timestamp
    if log.timestamp and log.timestamp ~= "" then
        StaffMenu.staffLogsQueueDetail.Button(":clock: Date", log.timestamp, nil, nil, true, function() end)
    end

    -- Source
    StaffMenu.staffLogsQueueDetail.Separator("SOURCE")
    StaffMenu.staffLogsQueueDetail.Button(":user: " .. (log.source or "?"), log.sourceId or "?", nil, nil, true, function()
        if log.sourceId then
            VFW.Clipboard(log.sourceId)
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = "Identifiant copié." })
        end
    end)

    -- Target
    if log.target then
        StaffMenu.staffLogsQueueDetail.Separator("CIBLE")
        StaffMenu.staffLogsQueueDetail.Button(":target: " .. log.target, log.targetId or "?", nil, nil, true, function()
            if log.targetId then
                VFW.Clipboard(log.targetId)
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = "Identifiant copié." })
            end
        end)
    end

    -- Coords
    if log.coords then
        local coordStr = string.format("%.1f, %.1f, %.1f", log.coords.x or 0, log.coords.y or 0, log.coords.z or 0)
        StaffMenu.staffLogsQueueDetail.Separator("POSITION")
        StaffMenu.staffLogsQueueDetail.Button(":pin: Coordonnées", coordStr, nil, nil, true, function()
            VFW.Clipboard(coordStr)
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = "Coordonnées copiées." })
        end)
    end

    -- Data
    if log.data and next(log.data) then
        StaffMenu.staffLogsQueueDetail.Separator("DONNÉES")
        for key, value in pairs(log.data) do
            local valStr = type(value) == "table" and json.encode(value) or tostring(value)
            StaffMenu.staffLogsQueueDetail.Button(tostring(key), valStr, nil, nil, true, function()
                VFW.Clipboard(valStr)
                VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Logs', message = tostring(key) .. " copié." })
            end)
        end
    end

    -- Delete button
    StaffMenu.staffLogsQueueDetail.Separator()
    StaffMenu.staffLogsQueueDetail.Button(":trash: Supprimer ce log", "Retirer de la file d'attente", nil, nil, false, function()
        if log.index then
            TriggerServerCallback("vfw:stafflogs:deleteQueue", log.index)
            StaffMenu.selectedQueueLog = nil
            StaffMenu.staffLogsQueueDetail.close()
            StaffMenu.BuildStaffLogsQueueMenu()
        end
    end)
end

-- ── Ouvrir les sous-menus au OnOpen ──

StaffMenu.staffLogs.OnOpen(function()
    StaffMenu.staffLogs.ClearItems()
    StaffMenu.staffLogs.Button(":refresh: Rafraîchir", nil, nil, nil, false, function()
        StaffMenu.staffLogs.close()
        StaffMenu.staffLogs.open()
    end)
    StaffMenu.staffLogs.Button(":document: LOGS RÉCENTS", "Les derniers logs ont été envoyés", nil, "chevron", false, function()
    end, StaffMenu.staffLogsRecent)
    StaffMenu.staffLogs.Button(":hourglass: FILE D'ATTENTE", "Logs en attente d'envoi et raison des échecs", nil, "chevron", false, function()
    end, StaffMenu.staffLogsQueue)
end)

StaffMenu.staffLogsRecent.OnOpen(function()
    StaffMenu.BuildStaffLogsRecentMenu()
end)

StaffMenu.staffLogsDetail.OnOpen(function()
    StaffMenu.BuildStaffLogsDetailMenu()
end)

StaffMenu.staffLogsQueue.OnOpen(function()
    StaffMenu.BuildStaffLogsQueueMenu()
end)

StaffMenu.staffLogsQueueDetail.OnOpen(function()
    StaffMenu.BuildStaffLogsQueueDetailMenu()
end)

-- ── Bypass Cooldown Menu ──

-- ── Gestion des commandes cooldown ──

StaffMenu.cooldownCommandsMenu.OnOpen(function()
    StaffMenu.cooldownCommandsMenu.ClearItems()

    local commands = TriggerServerCallback("vfw:cooldown:getCommands")
    if not commands or #commands == 0 then
        StaffMenu.cooldownCommandsMenu.Button("Aucune commande trouvée", nil, nil, nil, true, function() end)
        return
    end

    local function formatTime(seconds)
        if seconds <= 0 then return "0s" end
        if seconds >= 60 then
            local min = math.floor(seconds / 60)
            local sec = seconds % 60
            if sec > 0 then return min .. "min " .. sec .. "s" end
            return min .. "min"
      end
        return seconds .. "s"
  end

    for _, cmd in ipairs(commands) do
        local details = {}
        if cmd.cooldown > 0 then
            details[#details + 1] = "CD: " .. formatTime(cmd.cooldown)
        end
        if cmd.maxUses > 0 then
            details[#details + 1] = "Max: " .. cmd.maxUses .. " uses"
      end
        if cmd.usageCooldown > 0 then
            details[#details + 1] = "Limit CD: " .. formatTime(cmd.usageCooldown)
        end
        local subtitle = #details > 0 and table.concat(details, " | ") or "Pas de cooldown"

      StaffMenu.cooldownCommandsMenu.Button("/" .. cmd.name, subtitle, nil, "chevron", false, function()
            StaffMenu._editingCommand = cmd
        end, StaffMenu.cooldownEditMenu)
    end
end)

StaffMenu.cooldownEditMenu.OnOpen(function()
    StaffMenu.cooldownEditMenu.ClearItems()
    local cmd = StaffMenu._editingCommand
    if not cmd then return end

    local function formatTime(seconds)
        if seconds <= 0 then return "0s" end
        if seconds >= 60 then
            local min = math.floor(seconds / 60)
            local sec = seconds % 60
            if sec > 0 then return min .. "min " .. sec .. "s" end
            return min .. "min"
      end
        return seconds .. "s"
  end

    StaffMenu.cooldownEditMenu.Button("Commande: /" .. cmd.name, nil, nil, nil, true, function() end)
    StaffMenu.cooldownEditMenu.Separator()

    local cooldownBtn, maxUsesBtn, usageCdBtn

    local function promptAndUpdate(field, promptText, displayKey, btnRef, formatter)
        local input = VFW.Nui.KeyboardInput(true, promptText, "")
        if not input or input == "" or input == "KBD_CANCEL" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Cooldown', message = "Édition annulée." })
            return
        end
        local val = tonumber(input)
        if not val or val < 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Cooldown', message = "Cette valeur n'est pas valide." })
            return
        end
        val = math.floor(val)

        local result = TriggerServerCallback("vfw:cooldown:updateCommand", cmd.name, field, val)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Cooldown', message = result.message })
            cmd[displayKey] = val
            if btnRef and btnRef.Update then
                btnRef.Update({ subtitle = formatter(val) })
            end
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Cooldown', message = (result and result.message) or "Erreur lors de la sauvegarde." })
        end
    end

    cooldownBtn = StaffMenu.cooldownEditMenu.Button("Cooldown simple", formatTime(cmd.cooldown), nil, "chevron", false, function()
        promptAndUpdate("cooldown", "Cooldown en secondes (0 = désactivé)", "cooldown", cooldownBtn, formatTime)
    end)
    maxUsesBtn = StaffMenu.cooldownEditMenu.Button("Max utilisations", tostring(cmd.maxUses), nil, "chevron", false, function()
        promptAndUpdate("maxUses", "Nombre max d'utilisations (0 = illimité)", "maxUses", maxUsesBtn, tostring)
    end)
    usageCdBtn = StaffMenu.cooldownEditMenu.Button("Cooldown après limite", formatTime(cmd.usageCooldown), nil, "chevron", false, function()
        promptAndUpdate("usageCooldown", "Cooldown en secondes après max utilisations", "usageCooldown", usageCdBtn, formatTime)
    end)
end)

-- ── Restauration Inventaire (Cleaner) ──

local function _formatRestoreAge(ageSec)
    local diff = tonumber(ageSec)
    if not diff or diff < 0 then return "?" end
    if diff < 60 then return diff .. "s" end
    if diff < 3600 then return math.floor(diff / 60) .. "min" end
    if diff < 86400 then return math.floor(diff / 3600) .. "h" end
    return math.floor(diff / 86400) .. "j"
end

StaffMenu.inventoryRestore.OnOpen(function()
    StaffMenu.inventoryRestore.ClearItems()

    local filter = StaffMenu._inventoryRestoreFilter or "pending"
  StaffMenu.inventoryRestore.Button("Filtre: " .. (
        filter == "pending" and ":dot-yellow: En attente" or
        filter == "restored" and ":dot-green: Restaurés" or
        filter == "handled" and ":dot-grey: Traités" or "Tous"
  ), "Cliquer pour cycler", nil, nil, false, function()
        local cycle = { pending = "restored", restored = "handled", handled = "all", all = "pending" }
        StaffMenu._inventoryRestoreFilter = cycle[filter] or "pending"
      StaffMenu.inventoryRestore.refresh()
    end)
    StaffMenu.inventoryRestore.Separator()

    local cleans = TriggerServerCallback("vfw:staffinv:listCleans", filter == "all" and nil or filter)
    if not cleans or #cleans == 0 then
        StaffMenu.inventoryRestore.Button("Aucun snapshot trouvé", "Aucune action récente à restaurer", nil, nil, true, function() end)
        return
    end

    for _, clean in ipairs(cleans) do
        local statusIcon = clean.status == "pending" and ":dot-yellow:"
          or clean.status == "restored" and ":dot-green:"
          or ":dot-grey:"
      local label = statusIcon .. " " .. (clean.target_name or "?") .. " (UID " .. tostring(clean.target_uid) .. ")"
      local subtitle = (clean.item_count or 0) .. " items | par " .. (clean.staff_name or "?") .. " | il y a " .. _formatRestoreAge(clean.created_age_sec)
        StaffMenu.inventoryRestore.Button(label, subtitle, nil, "chevron", false, function()
            StaffMenu._selectedClean = clean
        end, StaffMenu.inventoryRestoreDetail)
    end
end)

StaffMenu.inventoryRestoreDetail.OnOpen(function()
    StaffMenu.inventoryRestoreDetail.ClearItems()
    local clean = StaffMenu._selectedClean
    if not clean then
        StaffMenu.inventoryRestoreDetail.Button("Aucun snapshot sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local detail = TriggerServerCallback("vfw:staffinv:getCleanDetail", clean.id)
    if not detail then
        StaffMenu.inventoryRestoreDetail.Button("Snapshot introuvable", nil, nil, nil, true, function() end)
        return
    end

    StaffMenu.inventoryRestoreDetail.Button("Cible: " .. (detail.target_name or "?"), "UID " .. tostring(detail.target_uid), nil, nil, false, function() end)
    StaffMenu.inventoryRestoreDetail.Button("Confisqué par: " .. (detail.staff_name or "?"), "Il y a " .. _formatRestoreAge(detail.created_age_sec), nil, nil, false, function() end)
    StaffMenu.inventoryRestoreDetail.Button("Statut: " .. tostring(detail.status), detail.restored_by_name and ("Restauré par " .. detail.restored_by_name) or nil, nil, nil, false, function() end)
    StaffMenu.inventoryRestoreDetail.Separator("ITEMS (" .. tostring(#detail.items) .. ")")

    for _, it in ipairs(detail.items) do
        local label = (it.label or it.name or "?") .. " ×" .. tostring(it.count or 0)
        local sub = "ID: " .. tostring(it.name)
        if it.meta and next(it.meta) then sub = sub .. " | meta présent" end
        StaffMenu.inventoryRestoreDetail.Button(label, sub, nil, nil, false, function() end)
    end

    StaffMenu.inventoryRestoreDetail.Separator()

    if detail.status == "pending" then
        StaffMenu.inventoryRestoreDetail.Button(":check: RESTAURER", "Rendre tous les items au joueur sélectionné, connecté ou non", nil, nil, false, function()
            local result = TriggerServerCallback("vfw:staffinv:restoreClean", detail.id)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restauration', message = result.message })
                StaffMenu._selectedClean = nil
                StaffMenu.inventoryRestoreDetail.parent.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Restauration', message = (result and result.message) or "Échec" })
            end
        end)

        StaffMenu.inventoryRestoreDetail.Button(":dot-grey: MARQUER COMME TRAITÉ", "Pas de restauration nécessaire (clôture le ticket)", nil, nil, false, function()
            local result = TriggerServerCallback("vfw:staffinv:markHandled", detail.id)
            if result and result.success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Restauration', message = result.message })
                StaffMenu._selectedClean = nil
                StaffMenu.inventoryRestoreDetail.parent.open()
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Restauration', message = (result and result.message) or "Échec" })
            end
        end)
    else
        StaffMenu.inventoryRestoreDetail.Button("Snapshot déjà clôturé", "Aucune action possible", nil, nil, true, function() end)
    end
end)

-- ── Bypass Cooldown Menu ──

StaffMenu.bypassCooldown.OnOpen(function()
    StaffMenu.bypassCooldown.ClearItems()

    StaffMenu.bypassCooldown.Button(":settings: Gestion des commandes", "Modifier cooldowns et limites", nil, "chevron", false, function()
    end, StaffMenu.cooldownCommandsMenu)

    StaffMenu.bypassCooldown.Separator("BYPASS JOUEURS")

    StaffMenu.bypassCooldown.Button(":plus: Ajouter par ID unique", "Entrez l'ID unique du joueur", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "ID unique du joueur")
        local uniqueId = tonumber(input)
        if not uniqueId then
            VFW.ShowNotification({ type = 'ROUGE', content = "Cet identifiant n'est pas valide" })
            return
        end
        local result = TriggerServerCallback("vfw:cooldown:addBypass", uniqueId)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Bypass Cooldown', message = result.message })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Erreur" })
        end
        StaffMenu.bypassCooldown.refresh()
    end)

    StaffMenu.bypassCooldown.Separator("BYPASS ACTIFS")

    local bypasses = TriggerServerCallback("vfw:cooldown:listBypasses")
    if bypasses and #bypasses > 0 then
        for _, bypass in ipairs(bypasses) do
            local statusIcon = bypass.online and ":dot-green:" or ":dot-grey:"
          local label = statusIcon .. " " .. bypass.name .. " (UID: " .. tostring(bypass.uniqueId) .. ")"
          local subtitle = bypass.online and "En ligne, cliquez pour retirer" or "Hors-ligne, cliquez pour retirer"
          StaffMenu.bypassCooldown.Button(label, subtitle, nil, "chevron", false, function()
                local result = TriggerServerCallback("vfw:cooldown:removeBypass", bypass.uniqueId)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Bypass Cooldown', message = result.message })
                else
                    VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Erreur" })
                end
                StaffMenu.bypassCooldown.refresh()
            end)
        end
    else
        StaffMenu.bypassCooldown.Button("Aucun bypass actif", nil, nil, nil, true, function() end)
    end
end)

-- ── Antiban Menu ──

StaffMenu.antibanMenu.OnOpen(function()
    StaffMenu.antibanMenu.ClearItems()

    StaffMenu.antibanMenu.Button(":plus: Ajouter par ID unique", "Protéger un joueur contre le ban/kick", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "ID unique du joueur")
        local uniqueId = tonumber(input)
        if not uniqueId then
            VFW.ShowNotification({ type = 'ROUGE', content = "Cet identifiant n'est pas valide" })
            return
        end
        local result = TriggerServerCallback("vfw:antiban:add", uniqueId)
        if result and result.success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Antiban', message = result.message })
        else
            VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Erreur" })
        end
        StaffMenu.antibanMenu.refresh()
    end)

    StaffMenu.antibanMenu.Separator("JOUEURS PROTÉGÉS")

    local list = TriggerServerCallback("vfw:antiban:list")
    if list and #list > 0 then
        for _, player in ipairs(list) do
            local statusIcon = player.online and ":dot-green:" or ":dot-grey:"
          local subtitle = player.online and "En ligne, cliquez pour retirer" or "Hors-ligne, cliquez pour retirer"
          StaffMenu.antibanMenu.Button(statusIcon .. " " .. player.name .. " (UID: " .. tostring(player.uniqueId) .. ")", subtitle, nil, "chevron", false, function()
                local result = TriggerServerCallback("vfw:antiban:remove", player.uniqueId)
                if result and result.success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Antiban', message = result.message })
                else
                    VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Erreur" })
                end
                StaffMenu.antibanMenu.refresh()
            end)
        end
    else
        StaffMenu.antibanMenu.Button("Aucun joueur protégé", nil, nil, nil, true, function() end)
    end
end)

-- ── Reset Sanctions Menu (Dev only) ──

StaffMenu.resetSanctionsQuery = nil
StaffMenu.resetSanctionsResults = {}
StaffMenu.resetSanctionsSelected = nil

StaffMenu.resetSanctions.OnOpen(function()
    StaffMenu.resetSanctions.ClearItems()

    local query = StaffMenu.resetSanctionsQuery
    local searchLabel = query == nil and "RECHERCHER" or "RECHERCHER:"
  local searchValue = query == nil and "UN JOUEUR (UID / Pseudo / Nom RP)" or query

    StaffMenu.resetSanctions.Button(searchLabel, searchValue, nil, "search", false, function()
        if StaffMenu.resetSanctionsQuery ~= nil then
            StaffMenu.resetSanctionsQuery = nil
            StaffMenu.resetSanctionsResults = {}
            StaffMenu.resetSanctions.refresh()
            return
        end

        local input = VFW.Nui.KeyboardInput(true, "Recherche : UID, pseudo ou nom RP")
        if not input or input == "" then return end

        StaffMenu.resetSanctionsQuery = input
        StaffMenu.resetSanctionsResults = TriggerServerCallback("vfw:staff:searchOfflinePlayers", input) or {}
        StaffMenu.resetSanctions.refresh()
    end)

    StaffMenu.resetSanctions.Separator(nil)

    if not StaffMenu.resetSanctionsQuery then
        StaffMenu.resetSanctions.Button("Entrez une recherche", "UID, pseudo ou nom RP du joueur", nil, nil, true, function() end)
        return
    end

    local results = StaffMenu.resetSanctionsResults or {}

    if #results == 0 then
        StaffMenu.resetSanctions.Separator("~ Aucun résultat ~")
        return
    end

    StaffMenu.resetSanctions.Separator("~ Résultats (" .. #results .. ") ~")

    for _, player in ipairs(results) do
        local statusIcon = player.isOnline and ":dot-green: " or ":dot-grey: "
      local banIcon = player.isBanned and "[BAN] " or ""
      local tigIcon = player.hasTig and "[TIG] " or ""
      local label = statusIcon .. banIcon .. tigIcon .. (player.pseudo or "Sans pseudo")
        local subtitle = "UUID #" .. tostring(player.id) .. " · " .. (player.name or "Inconnu")

        StaffMenu.resetSanctions.Button(label, subtitle, nil, "chevron", false, function()
            StaffMenu.resetSanctionsSelected = player
        end, StaffMenu.resetSanctionsConfirm)
    end
end)

StaffMenu.resetSanctionsConfirm.OnOpen(function()
    StaffMenu.resetSanctionsConfirm.ClearItems()

    local player = StaffMenu.resetSanctionsSelected
    if not player then
        StaffMenu.resetSanctionsConfirm.Button("Aucun joueur sélectionné", nil, nil, nil, true, function() end)
        return
    end

    local counts = TriggerServerCallback("vfw:staff:getSanctionsCount", player.id) or {}
    local total = (counts.warns or 0) + (counts.kicks or 0) + (counts.bans or 0) + (counts.tigs or 0) + (counts.tigWeapons or 0)

    StaffMenu.resetSanctionsConfirm.Separator(":warning: CIBLE")
    StaffMenu.resetSanctionsConfirm.Button(":user: " .. (player.pseudo or "Sans pseudo"), "UUID #" .. tostring(player.id), nil, nil, true, function() end)

    StaffMenu.resetSanctionsConfirm.Separator(":chart: SANCTIONS À SUPPRIMER (" .. total .. ")")
    StaffMenu.resetSanctionsConfirm.Button(":warning: Avertissements", tostring(counts.warns or 0), nil, nil, true, function() end)
    StaffMenu.resetSanctionsConfirm.Button(":user: Expulsions", tostring(counts.kicks or 0), nil, nil, true, function() end)
    StaffMenu.resetSanctionsConfirm.Button(":hammer: Bannissements", tostring(counts.bans or 0), nil, nil, true, function() end)
    StaffMenu.resetSanctionsConfirm.Button(":hammer: TIG", tostring(counts.tigs or 0), nil, nil, true, function() end)
    StaffMenu.resetSanctionsConfirm.Button(":ban: TIG Arme", tostring(counts.tigWeapons or 0), nil, nil, true, function() end)

    StaffMenu.resetSanctionsConfirm.Separator()

    if total == 0 then
        StaffMenu.resetSanctionsConfirm.Button("Aucune sanction à supprimer", nil, nil, nil, true, function() end)
        return
    end

    StaffMenu.resetSanctionsConfirm.Button(":trash: CONFIRMER LE RESET", "Action irréversible, tout l'historique sera supprimé", nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez RESET pour confirmer", "")
        if confirm ~= "RESET" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'INFO', subtitle = 'Reset Sanctions', message = "Reset annulé." })
            return
        end

        local result = TriggerServerCallback("vfw:staff:resetPlayerSanctions", player.id)
        if result and result.success then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Reset Sanctions',
                message = string.format((result.deleted or 0) > 1 and "%d sanctions supprimées pour %s." or "%d sanction supprimée pour %s.", result.deleted or 0, player.pseudo or ("UID " .. player.id))
            })
            StaffMenu.resetSanctionsSelected = nil
            StaffMenu.resetSanctionsConfirm.close()
            if StaffMenu.resetSanctionsQuery then
                StaffMenu.resetSanctionsResults = TriggerServerCallback("vfw:staff:searchOfflinePlayers", StaffMenu.resetSanctionsQuery) or {}
            end
            StaffMenu.resetSanctions.refresh()
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Reset Sanctions',
                message = (result and result.message) or "Échec du reset."
          })
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════════
-- Webhooks Logs — gestion des webhooks Discord par catégorie
-- ══════════════════════════════════════════════════════════════════

--- Liste des catégories et leur état de webhook
function StaffMenu.BuildWebhookLogsMenu()
    StaffMenu.webhookLogs.ClearItems()

    local list = TriggerServerCallback("vfw:webhooks:list") or {}
    if #list == 0 then
        StaffMenu.webhookLogs.Button(":report: ACCÈS REFUSÉ", "Permission développeur requise", nil, nil, true, function() end)
        return
    end

    StaffMenu.webhookLogs.Separator(":report: WEBHOOKS DISCORD PAR CATÉGORIE")

    for _, item in ipairs(list) do
        local hasUrl = item.url ~= nil and item.url ~= ""
        local status
        if not hasUrl then
            status = "Non configuré"
        elseif item.enabled then
            status = "Configuré • actif"
        else
            status = "Configuré • désactivé"
        end

        StaffMenu.webhookLogs.Button(item.label, status, nil, "chevron", false, function()
            StaffMenu.selectedWebhook = item
        end, StaffMenu.webhookLogsEdit)
    end
end

--- Actions sur la catégorie sélectionnée (définir/tester/activer/supprimer)
function StaffMenu.BuildWebhookLogsEditMenu()
    StaffMenu.webhookLogsEdit.ClearItems()

    local item = StaffMenu.selectedWebhook
    if not item then return end

    StaffMenu.webhookLogsEdit.Separator(item.label)

    local hasUrl = item.url ~= nil and item.url ~= ""
    local shown = hasUrl and (string.sub(item.url, 1, 42) .. "…") or "Aucune"
    StaffMenu.webhookLogsEdit.Button(":report: URL ACTUELLE", shown, nil, nil, true, function() end)

    StaffMenu.webhookLogsEdit.Button(":wrench: DÉFINIR / MODIFIER L'URL", "Coller l'URL du webhook Discord", nil, nil, false, function()
        local url = VFW.Nui.KeyboardInput(true, "URL du webhook Discord", item.url or "")
        if not url or url == "" or url == "KBD_CANCEL" then return end

        local ok, err = TriggerServerCallback("vfw:webhooks:set", item.category, url)
        if ok then
            item.url = url
            item.enabled = true
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Webhooks Logs', message = "Webhook enregistré pour " .. item.label .. "." })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Webhooks Logs', message = err or "Échec de l'enregistrement." })
        end
        StaffMenu.webhookLogsEdit.refresh()
    end)

    if hasUrl then
        StaffMenu.webhookLogsEdit.Button(":report: ENVOYER UN TEST", "Poster un message de test sur ce webhook", nil, nil, false, function()
            local ok, err = TriggerServerCallback("vfw:webhooks:test", item.category)
            VFW.ShowNotification({
                type = 'STAFF',
                variant = ok and 'SUCCESS' or 'ERROR',
                subtitle = 'Webhooks Logs',
                message = ok and "Message de test envoyé." or (err or "Échec du test."),
            })
        end)

        StaffMenu.webhookLogsEdit.Checkbox(":monitor: ACTIVÉ", "Activer ou désactiver l'envoi", false, item.enabled, function(checked)
            local ok = TriggerServerCallback("vfw:webhooks:toggle", item.category, checked)
            if ok then item.enabled = checked end
            StaffMenu.webhookLogsEdit.refresh()
        end)

        StaffMenu.webhookLogsEdit.Button(":trash: SUPPRIMER", "Retirer ce webhook", nil, nil, false, function()
            local ok = TriggerServerCallback("vfw:webhooks:remove", item.category)
            if ok then
                item.url = ""
                item.enabled = false
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Webhooks Logs', message = "Webhook supprimé." })
            end
            StaffMenu.webhookLogsEdit.refresh()
        end)
    end
end
