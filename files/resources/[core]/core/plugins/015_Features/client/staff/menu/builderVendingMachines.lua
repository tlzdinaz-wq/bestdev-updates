local selectedMachine = nil
local selectedMachineData = nil

local function GetVendingMachineSettings()
    return GlobalState.VendingMachineSettings or {}
end

local function BuildVendingMachineEditMenu()
    if not StaffMenu or not StaffMenu.builderVendingMachineEdit then return end
    if not selectedMachine or not selectedMachineData then return end

    local settings = GetVendingMachineSettings()
    local data = settings[selectedMachine]
    if not data then return end

    selectedMachineData = data

    StaffMenu.builderVendingMachineEdit.Separator(":box: " .. data.label)

    local cooldownText = "Pas de cooldown"
  if data.cooldown and data.cooldown > 0 then
        local minutes = math.floor(data.cooldown / 60000)
        cooldownText = minutes .. " min"
  end
    local priceText = data.price > 0 and (VFW.Math.FormatMoney(data.price)) or "Gratuit"

  StaffMenu.builderVendingMachineEdit.Button("Item actuel: " .. data.itemLabel, "Nom technique: " .. data.item, nil, nil, true, function() end)
    StaffMenu.builderVendingMachineEdit.Button("Prix actuel: " .. priceText, nil, nil, nil, true, function() end)
    StaffMenu.builderVendingMachineEdit.Button("Cooldown actuel: " .. cooldownText, nil, nil, nil, true, function() end)

    StaffMenu.builderVendingMachineEdit.Separator(":settings: MODIFIER")

    StaffMenu.builderVendingMachineEdit.Button(":money: Modifier le prix", nil, nil, "arrow", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Nouveau prix", tostring(data.price))
        if input and input ~= "" then
            local newPrice = tonumber(input)
            if newPrice and newPrice >= 0 then
                local success = TriggerServerCallback("vfw:vendingMachine:updatePrice", selectedMachine, newPrice)
                if success then
                    Wait(100)
                    StaffMenu.builderVendingMachineEdit.refresh()
                end
            else
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Ce prix n'est pas valide."})
            end
        end
    end)

    StaffMenu.builderVendingMachineEdit.Button(":box: Modifier l'item", nil, nil, "arrow", false, function()
        local inputItem = VFW.Nui.KeyboardInput(true, "Nom de l'item (ex: water)", data.item)
        if inputItem and inputItem ~= "" then
            local inputLabel = VFW.Nui.KeyboardInput(true, "Label affiché (ex: Eau)", data.itemLabel)
            if inputLabel and inputLabel ~= "" then
                local success = TriggerServerCallback("vfw:vendingMachine:updateItem", selectedMachine, inputItem, inputLabel)
                if success then
                    Wait(100)
                    StaffMenu.builderVendingMachineEdit.refresh()
                end
            end
        end
    end)

    StaffMenu.builderVendingMachineEdit.Button(":clock: Modifier le cooldown", nil, nil, "arrow", false, function()
        local currentMin = math.floor((data.cooldown or 0) / 60000)
        local input = VFW.Nui.KeyboardInput(true, "Cooldown en minutes (0 = aucun)", tostring(currentMin))
        if input and input ~= "" then
            local newMinutes = tonumber(input)
            if newMinutes and newMinutes >= 0 then
                local newCooldown = newMinutes * 60000
                local success = TriggerServerCallback("vfw:vendingMachine:updateCooldown", selectedMachine, newCooldown)
                if success then
                    Wait(100)
                    StaffMenu.builderVendingMachineEdit.refresh()
                end
            else
                VFW.ShowNotification({type = 'STAFF', variant = 'ERROR', subtitle = 'Builder', message = "Cette valeur n'est pas valide."})
            end
        end
    end)
end

local function BuildVendingMachinesMenu()
    if not StaffMenu or not StaffMenu.builderVendingMachines then return end

    local settings = GetVendingMachineSettings()

    StaffMenu.builderVendingMachines.Separator(":cart: DISTRIBUTEURS")

    if not settings or next(settings) == nil then
        StaffMenu.builderVendingMachines.Button("Aucun distributeur configuré", "Les paramètres n'ont pas été chargés", nil, nil, true, function() end)
        return
    end

    for modelName, data in pairs(settings) do
        local cooldownText = "Pas de cooldown"
      if data.cooldown and data.cooldown > 0 then
            local minutes = math.floor(data.cooldown / 60000)
            cooldownText = minutes .. " min"
      end

        local priceText = data.price > 0 and (VFW.Math.FormatMoney(data.price)) or "Gratuit"
      local description = data.itemLabel .. " | " .. priceText .. " | " .. cooldownText

        StaffMenu.builderVendingMachines.Button(
            ":box: " .. data.label,
            description,
            nil,
            "chevron",
            false,
            function()
                selectedMachine = modelName
                selectedMachineData = data
            end,
            StaffMenu.builderVendingMachineEdit
        )
    end
end

if StaffMenu.builderVendingMachines and StaffMenu.builderVendingMachines.OnOpen then
    StaffMenu.builderVendingMachines.OnOpen(function()
        StaffMenu.builderVendingMachines.ClearItems()
        BuildVendingMachinesMenu()
    end)
end

if StaffMenu.builderVendingMachineEdit and StaffMenu.builderVendingMachineEdit.OnOpen then
    StaffMenu.builderVendingMachineEdit.OnOpen(function()
        StaffMenu.builderVendingMachineEdit.ClearItems()
        BuildVendingMachineEditMenu()
    end)
end
