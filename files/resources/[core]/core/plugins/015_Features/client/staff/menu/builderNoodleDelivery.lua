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
    for _, name in ipairs(NoodleConfig.DeliveryAllowedItems) do
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
    local societyGain = math.floor(total * (NoodleConfig.DeliverySocietyPercent or 20) / 100)
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

StaffMenu.builderNoodleDelivery.OnOpen(function()
    RemovePreviewNpc()
    BuildDeliverableItems()

    local allClients = TriggerServerCallback("noodle:delivery:getAllClients") or {}

    StaffMenu.builderNoodleDelivery.Separator("CONFIGURATION")

    StaffMenu.builderNoodleDelivery.Button(
        "Configurer les paramètres",
        "Pourboires, % société, distances, véhicule",
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderNoodleDeliveryConfig
    )

    StaffMenu.builderNoodleDelivery.Separator("EMPLACEMENTS NOODLE")

    for jobName, loc in pairs(NoodleConfig.Locations) do
        local clientCount = #(allClients[jobName] or {})

        StaffMenu.builderNoodleDelivery.Button(
            loc.label or jobName,
            clientCount .. (clientCount > 1 and " clients configur\195\169s" or " client configur\195\169"),
            nil,
            "chevron",
            false,
            function()
                selectedJobName = jobName
            end,
            StaffMenu.builderNoodleDeliveryList
        )
    end
end)

StaffMenu.builderNoodleDeliveryList.OnOpen(function()
    RemovePreviewNpc()
    if not selectedJobName then return end

    local loc = NoodleConfig.Locations[selectedJobName]
    local locLabel = loc and loc.label or selectedJobName

    StaffMenu.builderNoodleDeliveryList.Separator(string.upper(locLabel))

    StaffMenu.builderNoodleDeliveryList.Button(
        "+ AJOUTER UN CLIENT",
        "Cr\195\169er un nouveau client de livraison",
        nil,
        "chevron",
        false,
        function()
            ResetCreateData(selectedJobName)
        end,
        StaffMenu.builderNoodleDeliveryCreate
    )

    local clients = TriggerServerCallback("noodle:delivery:getClients", selectedJobName) or {}

    if #clients > 0 then
        StaffMenu.builderNoodleDeliveryList.Separator("CLIENTS (" .. #clients .. ")")

        for _, client in ipairs(clients) do
            local total, empGain, socGain = ComputeEstimatedGains(client.orderItems)
            StaffMenu.builderNoodleDeliveryList.Button(
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
                StaffMenu.builderNoodleDeliveryEdit
            )
        end
    else
        StaffMenu.builderNoodleDeliveryList.Button(
            "Aucun client",
            "Ajoutez des clients avec le bouton ci-dessus",
            nil,
            nil,
            true,
            function() end
        )
    end
end)

StaffMenu.builderNoodleDeliveryCreate.OnOpen(function()
    StaffMenu.builderNoodleDeliveryCreate.Button(
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
            VFW.ShowNotification({ type = "VERT", content = string.format("Position captur\195\169e: %.2f, %.2f, %.2f", coords.x, coords.y, coords.z) })
            StaffMenu.builderNoodleDeliveryCreate.close()
            Wait(100)
            StaffMenu.builderNoodleDeliveryCreate.open()
        end
    )

    StaffMenu.builderNoodleDeliveryCreate.Button(
        "NOM DU CLIENT",
        "Actuel: " .. createData.npcName,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du client", createData.npcName)
            if input and input ~= "" then
                createData.npcName = input
                StaffMenu.builderNoodleDeliveryCreate.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryCreate.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryCreate.Button(
        "MODELE PED",
        "Actuel: " .. createData.npcModel,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Mod\195\168le du PED", createData.npcModel)
            if input and input ~= "" then
                createData.npcModel = input
                if createData.x ~= 0 then
                    SpawnPreviewNpc(input, createData.x, createData.y, createData.z, createData.heading)
                end
                StaffMenu.builderNoodleDeliveryCreate.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryCreate.open()
            end
        end
    )

    local totalCreate, empCreate, socCreate = ComputeEstimatedGains(createData.orderItems)
    local tipInfo = "Pourboire: " .. (NoodleConfig.DeliveryTipChance or 30) .. "% chance (" .. (NoodleConfig.DeliveryTipMin or 5) .. "-" .. VFW.Math.FormatMoney(NoodleConfig.DeliveryTipMax or 20) .. ")"
  StaffMenu.builderNoodleDeliveryCreate.Button(
        "GAINS ESTIM\195\137S",
        "Total: " .. VFW.Math.FormatMoney(totalCreate) .. " | Employ\195\169: " .. VFW.Math.FormatMoney(empCreate) .. " | Soci\195\169t\195\169: " .. VFW.Math.FormatMoney(socCreate) .. " (" .. (NoodleConfig.DeliverySocietyPercent or 20) .. "%) | " .. tipInfo,
        nil,
        nil,
        true,
        function() end
    )

    StaffMenu.builderNoodleDeliveryCreate.Button(
        "CONFIGURER LA COMMANDE",
        FormatOrderItems(createData.orderItems),
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderNoodleDeliveryCreateOrder
    )

    StaffMenu.builderNoodleDeliveryCreate.Separator("ACTIONS")

    StaffMenu.builderNoodleDeliveryCreate.Button(
        "PREVIEW NPC",
        "Afficher un aper\195\167u du NPC \195\160 la position captur\195\169e",
        nil,
        nil,
        false,
        function()
            if createData.x == 0 and createData.y == 0 then
                VFW.ShowNotification({ type = "ROUGE", content = "Capturez d'abord une position." })
                return
            end
            SpawnPreviewNpc(createData.npcModel, createData.x, createData.y, createData.z, createData.heading)
            VFW.ShowNotification({ type = "VERT", content = "Preview NPC cr\195\169\195\169." })
        end
    )

    StaffMenu.builderNoodleDeliveryCreate.Button(
        "VALIDER",
        "Cr\195\169er le client de livraison",
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

            local success, id = TriggerServerCallback("noodle:delivery:addClient", createData)
            if success then
                RemovePreviewNpc()
                VFW.ShowNotification({ type = "VERT", content = "Client de livraison cr\195\169\195\169, ID " .. tostring(id) })
                StaffMenu.builderNoodleDeliveryCreate.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryList.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = id or "Erreur lors de la cr\195\169ation." })
            end
        end
    )
end)

StaffMenu.builderNoodleDeliveryCreateOrder.OnOpen(function()
    StaffMenu.builderNoodleDeliveryCreateOrder.Separator("COMMANDE ACTUELLE")

    if #createData.orderItems > 0 then
        for i, item in ipairs(createData.orderItems) do
            local itemData = VFW.Items and VFW.Items[item.name]
            local label = itemData and itemData.label or item.name
            local priceStr = item.price and item.price > 0 and (" (" .. VFW.Math.FormatMoney(item.price) .. "/u)") or ""
          StaffMenu.builderNoodleDeliveryCreateOrder.Button(
                item.count .. "x " .. label .. priceStr,
                "Cliquez pour retirer",
                nil,
                "trash",
                false,
                function()
                    table.remove(createData.orderItems, i)
                    VFW.ShowNotification({ type = "VERT", content = label .. " retir\195\169 de la commande." })
                    StaffMenu.builderNoodleDeliveryCreateOrder.close()
                    Wait(100)
                    StaffMenu.builderNoodleDeliveryCreateOrder.open()
                end
            )
        end
    else
        StaffMenu.builderNoodleDeliveryCreateOrder.Button(
            "Aucun item",
            "Ajoutez des items ci-dessous",
            nil,
            nil,
            true,
            function() end
        )
    end

    StaffMenu.builderNoodleDeliveryCreateOrder.Separator("AJOUTER UN ITEM")

    for _, item in ipairs(deliverableItems) do
        StaffMenu.builderNoodleDeliveryCreateOrder.Button(
            item.label,
            item.name,
            nil,
            nil,
            false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Quantit\195\169 pour " .. item.label, "1")
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
                        VFW.ShowNotification({ type = "VERT", content = qty .. "x " .. item.label .. " (" .. VFW.Math.FormatMoney(price) .. "/u) ajout\195\169." })
                        StaffMenu.builderNoodleDeliveryCreateOrder.close()
                        Wait(100)
                        StaffMenu.builderNoodleDeliveryCreateOrder.open()
                    end
                end
            end
        )
    end
end)

StaffMenu.builderNoodleDeliveryEdit.OnOpen(function()
    if not selectedClient then return end

    StaffMenu.builderNoodleDeliveryEdit.Button(
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
            VFW.ShowNotification({ type = "VERT", content = "Position mise \195\160 jour." })
            StaffMenu.builderNoodleDeliveryEdit.close()
            Wait(100)
            StaffMenu.builderNoodleDeliveryEdit.open()
        end
    )

    StaffMenu.builderNoodleDeliveryEdit.Button(
        "NOM DU CLIENT",
        "Actuel: " .. selectedClient.npcName,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du client", selectedClient.npcName)
            if input and input ~= "" then
                selectedClient.npcName = input
                StaffMenu.builderNoodleDeliveryEdit.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryEdit.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryEdit.Button(
        "MODELE PED",
        "Actuel: " .. selectedClient.npcModel,
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Mod\195\168le du PED", selectedClient.npcModel)
            if input and input ~= "" then
                selectedClient.npcModel = input
                SpawnPreviewNpc(input, selectedClient.x, selectedClient.y, selectedClient.z, selectedClient.heading)
                StaffMenu.builderNoodleDeliveryEdit.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryEdit.open()
            end
        end
    )

    local totalEdit, empEdit, socEdit = ComputeEstimatedGains(editData.orderItems)
    local tipInfoEdit = "Pourboire: " .. (NoodleConfig.DeliveryTipChance or 30) .. "% chance (" .. (NoodleConfig.DeliveryTipMin or 5) .. "-" .. VFW.Math.FormatMoney(NoodleConfig.DeliveryTipMax or 20) .. ")"
  StaffMenu.builderNoodleDeliveryEdit.Button(
        "GAINS ESTIM\195\137S",
        "Total: " .. VFW.Math.FormatMoney(totalEdit) .. " | Employ\195\169: " .. VFW.Math.FormatMoney(empEdit) .. " | Soci\195\169t\195\169: " .. VFW.Math.FormatMoney(socEdit) .. " (" .. (NoodleConfig.DeliverySocietyPercent or 20) .. "%) | " .. tipInfoEdit,
        nil,
        nil,
        true,
        function() end
    )

    StaffMenu.builderNoodleDeliveryEdit.Button(
        "CONFIGURER LA COMMANDE",
        FormatOrderItems(editData.orderItems),
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderNoodleDeliveryOrder
    )

    StaffMenu.builderNoodleDeliveryEdit.Separator("ACTIONS")

    StaffMenu.builderNoodleDeliveryEdit.Button(
        "PREVIEW NPC",
        "Afficher un aper\195\167u du NPC",
        nil,
        nil,
        false,
        function()
            SpawnPreviewNpc(selectedClient.npcModel, selectedClient.x, selectedClient.y, selectedClient.z, selectedClient.heading)
            VFW.ShowNotification({ type = "VERT", content = "Preview NPC cr\195\169\195\169." })
        end
    )

    StaffMenu.builderNoodleDeliveryEdit.Button(
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

            local success = TriggerServerCallback("noodle:delivery:updateClient", selectedClient.id, data)
            if success then
                RemovePreviewNpc()
                VFW.ShowNotification({ type = "VERT", content = "Client mis \195\160 jour." })
                StaffMenu.builderNoodleDeliveryEdit.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryList.open()
            else
                VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la mise \195\160 jour." })
            end
        end
    )

    StaffMenu.builderNoodleDeliveryEdit.Button(
        "SUPPRIMER",
        "Supprimer ce client de livraison",
        nil,
        "trash",
        false,
        function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'oui' pour confirmer la suppression", "")
            if confirm and confirm:lower() == "oui" then
                local success = TriggerServerCallback("noodle:delivery:deleteClient", selectedClient.id)
                if success then
                    RemovePreviewNpc()
                    VFW.ShowNotification({ type = "VERT", content = "Client supprim\195\169." })
                    StaffMenu.builderNoodleDeliveryEdit.close()
                    Wait(100)
                    StaffMenu.builderNoodleDeliveryList.open()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = "Erreur lors de la suppression." })
                end
            end
        end
    )
end)

StaffMenu.builderNoodleDeliveryOrder.OnOpen(function()
    if not selectedClient then return end

    StaffMenu.builderNoodleDeliveryOrder.Separator("COMMANDE ACTUELLE")

    if #editData.orderItems > 0 then
        for i, item in ipairs(editData.orderItems) do
            local itemData = VFW.Items and VFW.Items[item.name]
            local label = itemData and itemData.label or item.name
            local priceStr = item.price and item.price > 0 and (" (" .. VFW.Math.FormatMoney(item.price) .. "/u)") or ""
          StaffMenu.builderNoodleDeliveryOrder.Button(
                item.count .. "x " .. label .. priceStr,
                "Cliquez pour retirer",
                nil,
                "trash",
                false,
                function()
                    table.remove(editData.orderItems, i)
                    VFW.ShowNotification({ type = "VERT", content = label .. " retir\195\169 de la commande." })
                    StaffMenu.builderNoodleDeliveryOrder.close()
                    Wait(100)
                    StaffMenu.builderNoodleDeliveryOrder.open()
                end
            )
        end
    else
        StaffMenu.builderNoodleDeliveryOrder.Button(
            "Aucun item",
            "Ajoutez des items ci-dessous",
            nil,
            nil,
            true,
            function() end
        )
    end

    StaffMenu.builderNoodleDeliveryOrder.Separator("AJOUTER UN ITEM")

    BuildDeliverableItems()

    for _, item in ipairs(deliverableItems) do
        StaffMenu.builderNoodleDeliveryOrder.Button(
            item.label,
            item.name,
            nil,
            nil,
            false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Quantit\195\169 pour " .. item.label, "1")
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
                        VFW.ShowNotification({ type = "VERT", content = qty .. "x " .. item.label .. " (" .. VFW.Math.FormatMoney(price) .. "/u) ajout\195\169." })
                        StaffMenu.builderNoodleDeliveryOrder.close()
                        Wait(100)
                        StaffMenu.builderNoodleDeliveryOrder.open()
                    end
                end
            end
        )
    end
end)

local noodleConfigData = {}
local noodleConfigLoaded = false

StaffMenu.builderNoodleDeliveryConfig.OnOpen(function()
    if not noodleConfigLoaded then
        local config = TriggerServerCallback("restaurants_builder:getConfig", "noodle")
        if config then
            noodleConfigData = {
                tip_chance = config.tip_chance,
                tip_min = config.tip_min,
                tip_max = config.tip_max,
                society_percent = config.society_percent,
                delivery_max_distance = config.delivery_max_distance,
                delivery_npc_distance = config.delivery_npc_distance,
                vehicle_models = config.vehicle_models or {}
            }
        else
            noodleConfigData = {
                tip_chance = NoodleConfig.DeliveryTipChance or 30,
                tip_min = NoodleConfig.DeliveryTipMin or 5,
                tip_max = NoodleConfig.DeliveryTipMax or 20,
                society_percent = NoodleConfig.DeliverySocietyPercent or 20,
                delivery_max_distance = NoodleConfig.DeliveryStartMaxDistance or 50.0,
                delivery_npc_distance = NoodleConfig.DeliveryNpcSpawnDistance or 50.0,
                vehicle_models = NoodleConfig.DeliveryVehicleModels or {}
            }
        end
        noodleConfigLoaded = true
    end

    StaffMenu.builderNoodleDeliveryConfig.Separator("POURBOIRES")

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "CHANCE",
        noodleConfigData.tip_chance .. "%",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Chance de pourboire (%)", tostring(noodleConfigData.tip_chance))
            if input and tonumber(input) then
                noodleConfigData.tip_chance = math.max(0, math.min(100, tonumber(input)))
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "MINIMUM",
        VFW.Math.FormatMoney(noodleConfigData.tip_min),
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Pourboire minimum (" .. LOCALE.currencySymbol .. ")", tostring(noodleConfigData.tip_min))
            if input and tonumber(input) then
                noodleConfigData.tip_min = math.max(0, tonumber(input))
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "MAXIMUM",
        VFW.Math.FormatMoney(noodleConfigData.tip_max),
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Pourboire maximum (" .. LOCALE.currencySymbol .. ")", tostring(noodleConfigData.tip_max))
            if input and tonumber(input) then
                noodleConfigData.tip_max = math.max(noodleConfigData.tip_min, tonumber(input))
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Separator("LIVRAISON")

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "% SOCIÉTÉ",
        noodleConfigData.society_percent .. "%",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Pourcentage société (%)", tostring(noodleConfigData.society_percent))
            if input and tonumber(input) then
                noodleConfigData.society_percent = math.max(0, math.min(100, tonumber(input)))
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "DISTANCE MAX",
        noodleConfigData.delivery_max_distance .. "m",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Distance max de lancement (m)", tostring(noodleConfigData.delivery_max_distance))
            if input and tonumber(input) then
                noodleConfigData.delivery_max_distance = math.max(1, tonumber(input))
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "DISTANCE SPAWN NPC",
        noodleConfigData.delivery_npc_distance .. "m",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Distance de spawn du NPC (m)", tostring(noodleConfigData.delivery_npc_distance))
            if input and tonumber(input) then
                noodleConfigData.delivery_npc_distance = math.max(1, tonumber(input))
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Separator("VEHICULES AUTORISES")

    if #noodleConfigData.vehicle_models > 0 then
        for i, model in ipairs(noodleConfigData.vehicle_models) do
            StaffMenu.builderNoodleDeliveryConfig.Button(
                model,
                "Cliquez pour retirer",
                nil, "trash", false,
                function()
                    table.remove(noodleConfigData.vehicle_models, i)
                    StaffMenu.builderNoodleDeliveryConfig.close()
                    Wait(100)
                    StaffMenu.builderNoodleDeliveryConfig.open()
                end
            )
        end
    else
        StaffMenu.builderNoodleDeliveryConfig.Button(
            "Aucun véhicule requis",
            "Tous les véhicules sont acceptés",
            nil, nil, true,
            function() end
        )
    end

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "+ AJOUTER UN VEHICULE",
        "Ajouter un modèle de véhicule autorisé",
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Modèle du véhicule (ex: nspeedo)", "")
            if input and input ~= "" then
                local already = false
                for _, m in ipairs(noodleConfigData.vehicle_models) do
                    if m == input then already = true break end
                end
                if not already then
                    table.insert(noodleConfigData.vehicle_models, input)
                end
                StaffMenu.builderNoodleDeliveryConfig.close()
                Wait(100)
                StaffMenu.builderNoodleDeliveryConfig.open()
            end
        end
    )

    StaffMenu.builderNoodleDeliveryConfig.Separator("ACTIONS")

    StaffMenu.builderNoodleDeliveryConfig.Button(
        "SAUVEGARDER",
        "Enregistrer la configuration",
        nil,
        "check",
        false,
        function()
            local success = TriggerServerCallback("restaurants_builder:updateConfig", "noodle", noodleConfigData)
            if success then
                noodleConfigLoaded = false
                VFW.ShowNotification({ type = "VERT", content = "Configuration sauvegardée." })
                StaffMenu.builderNoodleDeliveryConfig.close()
                StaffMenu.builderNoodleDeliveryConfig.parent.open()
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
