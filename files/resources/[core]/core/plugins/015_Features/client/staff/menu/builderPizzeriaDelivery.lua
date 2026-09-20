local selectedJobName = nil
local selectedClient = nil
local previewNpc = nil

local createData = {
    jobName = nil,
    npcName = "Client",
    npcModel = "a_m_y_business_01",
    x = 0.0,
    y = 0.0,
    z = 0.0,
    heading = 0.0,
    orderItems = {}
}

local editData = {
    orderItems = {}
}

local deliverableItems = {}

local function BuildDeliverableItems()
    if #deliverableItems > 0 then return end
    for _, name in ipairs(PizzeriaConfig.DeliveryAllowedItems) do
        local itemData = VFW.Items and VFW.Items[name]
        local label = itemData and itemData.label or name
        table.insert(deliverableItems, { name = name, label = label })
    end
end

local function SpawnPreviewNpc(modelName, x, y, z, heading)
    if previewNpc and DoesEntityExist(previewNpc) then
        DeleteEntity(previewNpc)
        previewNpc = nil
    end

    local model = GetHashKey(modelName)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return end

    previewNpc = CreatePed(4, model, x, y, z - 1.0, heading, false, false)
    SetEntityInvincible(previewNpc, true)
    SetBlockingOfNonTemporaryEvents(previewNpc, true)
    FreezeEntityPosition(previewNpc, true)
    SetPedCanRagdoll(previewNpc, false)
    SetModelAsNoLongerNeeded(model)
end

local function RemovePreviewNpc()
    if previewNpc and DoesEntityExist(previewNpc) then
        DeleteEntity(previewNpc)
        previewNpc = nil
    end
end

local function FormatOrderItems(orderItems)
    if not orderItems or #orderItems == 0 then return "Aucun item" end
    local parts = {}
    for _, item in ipairs(orderItems) do
        local itemData = VFW.Items and VFW.Items[item.name]
        local label = itemData and itemData.label or item.name
        if item.price and item.price > 0 then
            table.insert(parts, item.count .. "x " .. label .. " (" .. VFW.Math.FormatMoney(item.price) .. "/u)")
        else
            table.insert(parts, item.count .. "x " .. label)
        end
    end
    return table.concat(parts, ", ")
end

local function ComputeEstimatedGains(orderItems)
    local total = 0
    for _, item in ipairs(orderItems) do
        total = total + ((item.price or 0) * item.count)
    end
    local societyGain = math.floor(total * (PizzeriaConfig.DeliverySocietyPercent or 20) / 100)
    local employeeGain = total - societyGain
    return total, employeeGain, societyGain
end

local function ResetCreateData(jobName)
    createData = {
        jobName = jobName,
        npcName = "Client",
        npcModel = "a_m_y_business_01",
        x = 0.0,
        y = 0.0,
        z = 0.0,
        heading = 0.0,
        orderItems = {}
    }
end

StaffMenu.builderPizzeriaDelivery.OnOpen(function()
    RemovePreviewNpc()
    BuildDeliverableItems()

    local allClients = TriggerServerCallback("pizzeria:delivery:getAllClients") or {}

    StaffMenu.builderPizzeriaDelivery.Separator("CONFIGURATION")

    StaffMenu.builderPizzeriaDelivery.Button(
        "Configurer les paramètres",
        "Pourboires, % société, distances, véhicule",
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderPizzeriaDeliveryConfig
    )

    StaffMenu.builderPizzeriaDelivery.Separator("EMPLACEMENTS PIZZERIA")

    for jobName, loc in pairs(PizzeriaConfig.Locations) do
        local clientCount = #(allClients[jobName] or {})

        StaffMenu.builderPizzeriaDelivery.Button(
            loc.label or jobName,
            clientCount .. (clientCount > 1 and " clients configur\195\169s" or " client configur\195\169"),
            nil,
            "chevron",
            false,
            function()
                selectedJobName = jobName
            end,
            StaffMenu.builderPizzeriaDeliveryList
        )
    end
end)

StaffMenu.builderPizzeriaDeliveryList.OnOpen(function()
    RemovePreviewNpc()
    if not selectedJobName then return end

    local loc = PizzeriaConfig.Locations[selectedJobName]
    local locLabel = loc and loc.label or selectedJobName

    StaffMenu.builderPizzeriaDeliveryList.Separator(string.upper(locLabel))

    StaffMenu.builderPizzeriaDeliveryList.Button(
        "+ AJOUTER UN CLIENT",
        "Cr\195\169er un nouveau client de livraison",
        nil,
        "chevron",
        false,
        function()
            ResetCreateData(selectedJobName)
        end,
        StaffMenu.builderPizzeriaDeliveryCreate
    )

    local clients = TriggerServerCallback("pizzeria:delivery:getClients", selectedJobName) or {}

    if #clients > 0 then
        StaffMenu.builderPizzeriaDeliveryList.Separator("CLIENTS (" .. #clients .. ")")

        for _, client in ipairs(clients) do
            local total, empGain, socGain = ComputeEstimatedGains(client.orderItems)
            StaffMenu.builderPizzeriaDeliveryList.Button(
                client.npcName,
                "Total: " .. VFW.Math.FormatMoney(total) .. " (Emp: " .. VFW.Math.FormatMoney(empGain) .. " | Soc: " .. VFW.Math.FormatMoney(socGain) .. ") | " .. FormatOrderItems(client.orderItems),
                nil,
                "chevron",
                false,
                function()
                    selectedClient = client
                    editData.orderItems = {}
                    for _, oi in ipairs(client.orderItems or {}) do
                        table.insert(editData.orderItems, { name = oi.name, count = oi.count, price = oi.price or 0 })
                    end
                end,
                StaffMenu.builderPizzeriaDeliveryEdit
            )
        end
    else
        StaffMenu.builderPizzeriaDeliveryList.Button(
            "Aucun client",
            "Ajoutez des clients avec le bouton ci-dessus",
            nil,
            nil,
            true,
            function() end
        )
    end
end)

StaffMenu.builderPizzeriaDeliveryCreate.OnOpen(function()
    StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "CAPTURER LA POSITION",
        string.format("Actuelle: %.2f, %.2f, %.2f (H: %.1f)", createData.x, createData.y, createData.z, createData.heading),
        nil,
        nil,
        false,
        function()
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            createData.x = coords.x
            createData.y = coords.y
            createData.z = coords.z
            createData.heading = heading
            VFW.ShowNotification({ type = "VERT", content = string.format("Position capturée: %.2f, %.2f, %.2f", coords.x, coords.y, coords.z) })
            StaffMenu.builderPizzeriaDeliveryCreate.close()
            Wait(100)
            StaffMenu.builderPizzeriaDeliveryCreate.open()
        end
    )

    StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "NOM DU CLIENT",
        "Actuel: " .. createData.npcName,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du client", createData.npcName)
            if input and input ~= "" then
                createData.npcName = input
                StaffMenu.builderPizzeriaDeliveryCreate.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryCreate.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "MODELE PED",
        "Actuel: " .. createData.npcModel,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Modèle du PED", createData.npcModel)
            if input and input ~= "" then
                createData.npcModel = input
                if createData.x ~= 0 then
                    SpawnPreviewNpc(input, createData.x, createData.y, createData.z, createData.heading)
                end
                StaffMenu.builderPizzeriaDeliveryCreate.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryCreate.open()
            end
        end
    )

    local totalCreate, empCreate, socCreate = ComputeEstimatedGains(createData.orderItems)
    local tipInfo = "Pourboire: " .. (PizzeriaConfig.DeliveryTipChance or 30) .. "% chance (" .. (PizzeriaConfig.DeliveryTipMin or 5) .. "-" .. VFW.Math.FormatMoney(PizzeriaConfig.DeliveryTipMax or 20) .. ")"
  StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "GAINS ESTIMÉS",
        "Total: " .. VFW.Math.FormatMoney(totalCreate) .. " | Employé: " .. VFW.Math.FormatMoney(empCreate) .. " | Société: " .. VFW.Math.FormatMoney(socCreate) .. " (" .. (PizzeriaConfig.DeliverySocietyPercent or 20) .. "%) | " .. tipInfo,
        nil,
        nil,
        true,
        function() end
    )

    StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "CONFIGURER LA COMMANDE",
        FormatOrderItems(createData.orderItems),
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderPizzeriaDeliveryCreateOrder
    )

    StaffMenu.builderPizzeriaDeliveryCreate.Separator("ACTIONS")

    StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "PREVIEW NPC",
        "Afficher un aperçu du NPC à la position capturée",
        nil,
        nil,
        false,
        function()
            if createData.x == 0 and createData.y == 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Capturez d'abord une position." })
                return
            end
            SpawnPreviewNpc(createData.npcModel, createData.x, createData.y, createData.z, createData.heading)
            VFW.ShowNotification({ type = "VERT", content = "Preview NPC créé." })
        end
    )

    StaffMenu.builderPizzeriaDeliveryCreate.Button(
        "VALIDER",
        "Créer le client de livraison",
        nil,
        "check",
        false,
        function()
            if createData.x == 0 and createData.y == 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Capturez d'abord une position." })
                return
            end
            if #createData.orderItems == 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Configurez au moins un item dans la commande." })
                return
            end

            local success, id = TriggerServerCallback("pizzeria:delivery:addClient", createData)
            if success then
                RemovePreviewNpc()
                VFW.ShowNotification({ type = "VERT", content = "Client de livraison créé, ID " .. tostring(id) })
                StaffMenu.builderPizzeriaDeliveryCreate.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryList.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = id or "Erreur lors de la création." })
            end
        end
    )
end)

StaffMenu.builderPizzeriaDeliveryCreateOrder.OnOpen(function()
    StaffMenu.builderPizzeriaDeliveryCreateOrder.Separator("COMMANDE ACTUELLE")

    if #createData.orderItems > 0 then
        for i, item in ipairs(createData.orderItems) do
            local itemData = VFW.Items and VFW.Items[item.name]
            local label = itemData and itemData.label or item.name
            local priceStr = item.price and item.price > 0 and (" (" .. VFW.Math.FormatMoney(item.price) .. "/u)") or ""
          StaffMenu.builderPizzeriaDeliveryCreateOrder.Button(
                item.count .. "x " .. label .. priceStr,
                "Cliquez pour retirer",
                nil,
                "trash",
                false,
                function()
                    table.remove(createData.orderItems, i)
                    VFW.ShowNotification({ type = "VERT", content = label .. " retiré de la commande." })
                    StaffMenu.builderPizzeriaDeliveryCreateOrder.close()
                    Wait(100)
                    StaffMenu.builderPizzeriaDeliveryCreateOrder.open()
                end
            )
        end
    else
        StaffMenu.builderPizzeriaDeliveryCreateOrder.Button(
            "Aucun item",
            "Ajoutez des items ci-dessous",
            nil,
            nil,
            true,
            function() end
        )
    end

    StaffMenu.builderPizzeriaDeliveryCreateOrder.Separator("AJOUTER UN ITEM")

    for _, item in ipairs(deliverableItems) do
        StaffMenu.builderPizzeriaDeliveryCreateOrder.Button(
            item.label,
            item.name,
            nil,
            nil,
            false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Quantité pour " .. item.label, "1")
                if input and tonumber(input) and tonumber(input) > 0 then
                    local qty = tonumber(input)
                    local priceInput = VFW.Nui.KeyboardInput(true, "Prix unitaire (" .. LOCALE.currencySymbol .. ")", "10")
                    if priceInput and tonumber(priceInput) and tonumber(priceInput) >= 0 then
                        local price = tonumber(priceInput)
                        local found = false
                        for _, existing in ipairs(createData.orderItems) do
                            if existing.name == item.name and existing.price == price then
                                existing.count = existing.count + qty
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(createData.orderItems, { name = item.name, count = qty, price = price })
                        end
                        VFW.ShowNotification({ type = "VERT", content = qty .. "x " .. item.label .. " (" .. VFW.Math.FormatMoney(price) .. "/u) ajouté." })
                        StaffMenu.builderPizzeriaDeliveryCreateOrder.close()
                        Wait(100)
                        StaffMenu.builderPizzeriaDeliveryCreateOrder.open()
                    end
                end
            end
        )
    end
end)

StaffMenu.builderPizzeriaDeliveryEdit.OnOpen(function()
    if not selectedClient then return end

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "CAPTURER LA POSITION",
        string.format("Actuelle: %.2f, %.2f, %.2f (H: %.1f)", selectedClient.x, selectedClient.y, selectedClient.z, selectedClient.heading),
        nil,
        nil,
        false,
        function()
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            selectedClient.x = coords.x
            selectedClient.y = coords.y
            selectedClient.z = coords.z
            selectedClient.heading = heading
            VFW.ShowNotification({ type = "VERT", content = "Position mise à jour." })
            StaffMenu.builderPizzeriaDeliveryEdit.close()
            Wait(100)
            StaffMenu.builderPizzeriaDeliveryEdit.open()
        end
    )

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "NOM DU CLIENT",
        "Actuel: " .. selectedClient.npcName,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du client", selectedClient.npcName)
            if input and input ~= "" then
                selectedClient.npcName = input
                StaffMenu.builderPizzeriaDeliveryEdit.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryEdit.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "MODELE PED",
        "Actuel: " .. selectedClient.npcModel,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Modèle du PED", selectedClient.npcModel)
            if input and input ~= "" then
                selectedClient.npcModel = input
                SpawnPreviewNpc(input, selectedClient.x, selectedClient.y, selectedClient.z, selectedClient.heading)
                StaffMenu.builderPizzeriaDeliveryEdit.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryEdit.open()
            end
        end
    )

    local totalEdit, empEdit, socEdit = ComputeEstimatedGains(editData.orderItems)
    local tipInfoEdit = "Pourboire: " .. (PizzeriaConfig.DeliveryTipChance or 30) .. "% chance (" .. (PizzeriaConfig.DeliveryTipMin or 5) .. "-" .. VFW.Math.FormatMoney(PizzeriaConfig.DeliveryTipMax or 20) .. ")"
  StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "GAINS ESTIMÉS",
        "Total: " .. VFW.Math.FormatMoney(totalEdit) .. " | Employé: " .. VFW.Math.FormatMoney(empEdit) .. " | Société: " .. VFW.Math.FormatMoney(socEdit) .. " (" .. (PizzeriaConfig.DeliverySocietyPercent or 20) .. "%) | " .. tipInfoEdit,
        nil,
        nil,
        true,
        function() end
    )

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "CONFIGURER LA COMMANDE",
        FormatOrderItems(editData.orderItems),
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderPizzeriaDeliveryOrder
    )

    StaffMenu.builderPizzeriaDeliveryEdit.Separator("ACTIONS")

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "PREVIEW NPC",
        "Afficher un aperçu du NPC",
        nil,
        nil,
        false,
        function()
            SpawnPreviewNpc(selectedClient.npcModel, selectedClient.x, selectedClient.y, selectedClient.z, selectedClient.heading)
            VFW.ShowNotification({ type = "VERT", content = "Preview NPC créé." })
        end
    )

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "SAUVEGARDER",
        "Enregistrer les modifications",
        nil,
        "check",
        false,
        function()
            if #editData.orderItems == 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Configurez au moins un item dans la commande." })
                return
            end

            local data = {
                npcName = selectedClient.npcName,
                npcModel = selectedClient.npcModel,
                x = selectedClient.x,
                y = selectedClient.y,
                z = selectedClient.z,
                heading = selectedClient.heading,
                orderItems = editData.orderItems
            }

            local success = TriggerServerCallback("pizzeria:delivery:updateClient", selectedClient.id, data)
            if success then
                RemovePreviewNpc()
                VFW.ShowNotification({ type = "VERT", content = "Client mis à jour." })
                StaffMenu.builderPizzeriaDeliveryEdit.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryList.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la mise à jour." })
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryEdit.Button(
        "SUPPRIMER",
        "Supprimer ce client de livraison",
        nil,
        "trash",
        false,
        function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer la suppression", "")
            if confirm and confirm:lower() == "oui" then
                local success = TriggerServerCallback("pizzeria:delivery:deleteClient", selectedClient.id)
                if success then
                    RemovePreviewNpc()
                    VFW.ShowNotification({ type = "VERT", content = "Client supprimé." })
                    StaffMenu.builderPizzeriaDeliveryEdit.close()
                    Wait(100)
                    StaffMenu.builderPizzeriaDeliveryList.open()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la suppression." })
                end
            end
        end
    )
end)

StaffMenu.builderPizzeriaDeliveryOrder.OnOpen(function()
    if not selectedClient then return end

    StaffMenu.builderPizzeriaDeliveryOrder.Separator("COMMANDE ACTUELLE")

    if #editData.orderItems > 0 then
        for i, item in ipairs(editData.orderItems) do
            local itemData = VFW.Items and VFW.Items[item.name]
            local label = itemData and itemData.label or item.name
            local priceStr = item.price and item.price > 0 and (" (" .. VFW.Math.FormatMoney(item.price) .. "/u)") or ""
          StaffMenu.builderPizzeriaDeliveryOrder.Button(
                item.count .. "x " .. label .. priceStr,
                "Cliquez pour retirer",
                nil,
                "trash",
                false,
                function()
                    table.remove(editData.orderItems, i)
                    VFW.ShowNotification({ type = "VERT", content = label .. " retiré de la commande." })
                    StaffMenu.builderPizzeriaDeliveryOrder.close()
                    Wait(100)
                    StaffMenu.builderPizzeriaDeliveryOrder.open()
                end
            )
        end
    else
        StaffMenu.builderPizzeriaDeliveryOrder.Button(
            "Aucun item",
            "Ajoutez des items ci-dessous",
            nil,
            nil,
            true,
            function() end
        )
    end

    StaffMenu.builderPizzeriaDeliveryOrder.Separator("AJOUTER UN ITEM")

    BuildDeliverableItems()

    for _, item in ipairs(deliverableItems) do
        StaffMenu.builderPizzeriaDeliveryOrder.Button(
            item.label,
            item.name,
            nil,
            nil,
            false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Quantité pour " .. item.label, "1")
                if input and tonumber(input) and tonumber(input) > 0 then
                    local qty = tonumber(input)
                    local priceInput = VFW.Nui.KeyboardInput(true, "Prix unitaire (" .. LOCALE.currencySymbol .. ")", "10")
                    if priceInput and tonumber(priceInput) and tonumber(priceInput) >= 0 then
                        local price = tonumber(priceInput)
                        local found = false
                        for _, existing in ipairs(editData.orderItems) do
                            if existing.name == item.name and existing.price == price then
                                existing.count = existing.count + qty
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(editData.orderItems, { name = item.name, count = qty, price = price })
                        end
                        VFW.ShowNotification({ type = "VERT", content = qty .. "x " .. item.label .. " (" .. VFW.Math.FormatMoney(price) .. "/u) ajouté." })
                        StaffMenu.builderPizzeriaDeliveryOrder.close()
                        Wait(100)
                        StaffMenu.builderPizzeriaDeliveryOrder.open()
                    end
                end
            end
        )
    end
end)

local pizzeriaConfigData = {}
local pizzeriaConfigLoaded = false

StaffMenu.builderPizzeriaDeliveryConfig.OnOpen(function()
    if not pizzeriaConfigLoaded then
        local config = TriggerServerCallback("restaurants_builder:getConfig", "pizzeria")
        if config then
            pizzeriaConfigData = {
                tip_chance = config.tip_chance,
                tip_min = config.tip_min,
                tip_max = config.tip_max,
                society_percent = config.society_percent,
                delivery_max_distance = config.delivery_max_distance,
                delivery_npc_distance = config.delivery_npc_distance,
                vehicle_models = config.vehicle_models or {}
            }
        else
            pizzeriaConfigData = {
                tip_chance = PizzeriaConfig.DeliveryTipChance or 30,
                tip_min = PizzeriaConfig.DeliveryTipMin or 5,
                tip_max = PizzeriaConfig.DeliveryTipMax or 20,
                society_percent = PizzeriaConfig.DeliverySocietyPercent or 20,
                delivery_max_distance = PizzeriaConfig.DeliveryStartMaxDistance or 50.0,
                delivery_npc_distance = PizzeriaConfig.DeliveryNpcSpawnDistance or 50.0,
                vehicle_models = PizzeriaConfig.DeliveryVehicleModels or {}
            }
        end
        pizzeriaConfigLoaded = true
    end

    StaffMenu.builderPizzeriaDeliveryConfig.Separator("POURBOIRES")

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "CHANCE",
        pizzeriaConfigData.tip_chance .. "%",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Chance de pourboire (%)", tostring(pizzeriaConfigData.tip_chance))
            if input and tonumber(input) then
                pizzeriaConfigData.tip_chance = math.max(0, math.min(100, tonumber(input)))
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "MINIMUM",
        VFW.Math.FormatMoney(pizzeriaConfigData.tip_min),
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Pourboire minimum (" .. LOCALE.currencySymbol .. ")", tostring(pizzeriaConfigData.tip_min))
            if input and tonumber(input) then
                pizzeriaConfigData.tip_min = math.max(0, tonumber(input))
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "MAXIMUM",
        VFW.Math.FormatMoney(pizzeriaConfigData.tip_max),
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Pourboire maximum (" .. LOCALE.currencySymbol .. ")", tostring(pizzeriaConfigData.tip_max))
            if input and tonumber(input) then
                pizzeriaConfigData.tip_max = math.max(pizzeriaConfigData.tip_min, tonumber(input))
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Separator("LIVRAISON")

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "% SOCIÉTÉ",
        pizzeriaConfigData.society_percent .. "%",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Pourcentage société (%)", tostring(pizzeriaConfigData.society_percent))
            if input and tonumber(input) then
                pizzeriaConfigData.society_percent = math.max(0, math.min(100, tonumber(input)))
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "DISTANCE MAX",
        pizzeriaConfigData.delivery_max_distance .. "m",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Distance max de lancement (m)", tostring(pizzeriaConfigData.delivery_max_distance))
            if input and tonumber(input) then
                pizzeriaConfigData.delivery_max_distance = math.max(1, tonumber(input))
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "DISTANCE SPAWN NPC",
        pizzeriaConfigData.delivery_npc_distance .. "m",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Distance de spawn du NPC (m)", tostring(pizzeriaConfigData.delivery_npc_distance))
            if input and tonumber(input) then
                pizzeriaConfigData.delivery_npc_distance = math.max(1, tonumber(input))
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Separator("VEHICULES AUTORISES")

    if #pizzeriaConfigData.vehicle_models > 0 then
        for i, model in ipairs(pizzeriaConfigData.vehicle_models) do
            StaffMenu.builderPizzeriaDeliveryConfig.Button(
                model,
                "Cliquez pour retirer",
                nil, "trash", false,
                function()
                    table.remove(pizzeriaConfigData.vehicle_models, i)
                    StaffMenu.builderPizzeriaDeliveryConfig.close()
                    Wait(100)
                    StaffMenu.builderPizzeriaDeliveryConfig.open()
                end
            )
        end
    else
        StaffMenu.builderPizzeriaDeliveryConfig.Button(
            "Aucun véhicule requis",
            "Tous les véhicules sont acceptés",
            nil, nil, true,
            function() end
        )
    end

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "+ AJOUTER UN VEHICULE",
        "Ajouter un modèle de véhicule autorisé",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (ex: nspeedo)", "")
            if input and input ~= "" then
                local already = false
                for _, m in ipairs(pizzeriaConfigData.vehicle_models) do
                    if m == input then already = true break end
                end
                if not already then
                    table.insert(pizzeriaConfigData.vehicle_models, input)
                end
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderPizzeriaDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderPizzeriaDeliveryConfig.Separator("ACTIONS")

    StaffMenu.builderPizzeriaDeliveryConfig.Button(
        "SAUVEGARDER",
        "Enregistrer la configuration",
        nil,
        "check",
        false,
        function()
            local success = TriggerServerCallback("restaurants_builder:updateConfig", "pizzeria", pizzeriaConfigData)
            if success then
                pizzeriaConfigLoaded = false
                VFW.ShowNotification({ type = "VERT", content = "Configuration sauvegardée." })
                StaffMenu.builderPizzeriaDeliveryConfig.close()
                StaffMenu.builderPizzeriaDeliveryConfig.parent.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la sauvegarde." })
            end
        end
    )
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        RemovePreviewNpc()
    end
end)
