-- Builder Gestion Items LTD
-- Manage the global LTD items list (label + supermarket / spacemarket / catalog prices)
-- Backed by the `ltd_items` DB table and synced live to LTDItems.List on every client.

local tSelectedItem = nil

local function fmtPrice(value)
    if value == nil then return "-" end
    return VFW.Math.FormatMoney(value)
end

local function findEntry(itemName)
    if not LTDItems or not LTDItems.List then return nil end
    for _, entry in ipairs(LTDItems.List) do
        if entry.item == itemName then return entry end
    end
    return nil
end

local function inputNumber(title)
    local input = VFW.Nui.KeyboardInput(true, title)
    if input == nil or input == "" then return false end
    if tostring(input):lower() == "nil" or tostring(input) == "0" then return nil end
    return tonumber(input)
end

-- ==================== MAIN MENU ====================

function StaffMenu.BuildLTDItemsMenu()
    StaffMenu.builderLTDItems.Separator("ACTIONS")

    StaffMenu.builderLTDItems.Button(
        "AJOUTER UN ITEM",
        "Créer un nouvel item dans le catalogue",
        nil,
        "chevron",
        false,
        function()
            local name = VFW.Nui.KeyboardInput(true, "Nom DB de l'item (items.name)")
            if not name or name == "" then return end
            tSelectedItem = {
                item = name,
                label = name,
                normalPrice = nil,
                buyPrice = nil,
                sellPrice = 0,
                isNew = true
            }
        end,
        StaffMenu.ltdItemEdit
    )

    StaffMenu.builderLTDItems.Button(
        ":refresh: SYNCHRONISER (ÉCRASE TOUT)",
        "Applique les prix à tous les LTD existants",
        nil,
        "chevron",
        false,
        function()
            local result = TriggerServerCallback("vfw:ltd:items:syncAll")
            if result and result.success then
                VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "LTD", message = "Synchronisation terminée." })
            else
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "LTD", message = (result and result.error) or "Erreur lors de la sync." })
            end
        end
    )

    if not LTDItems or not LTDItems.List or #LTDItems.List == 0 then
        StaffMenu.builderLTDItems.Separator("AUCUN ITEM CHARGÉ")
        return
    end

    StaffMenu.builderLTDItems.Separator(("ITEMS (%d)"):format(#LTDItems.List))

    for _, entry in ipairs(LTDItems.List) do
        local desc = ("Supérette: %s | Market: %s | Catalogue: %s"):format(
            fmtPrice(entry.normalPrice),
            fmtPrice(entry.buyPrice),
            fmtPrice(entry.sellPrice)
        )
        local item = entry.item
        StaffMenu.builderLTDItems.Button(entry.label or item, desc, nil, "chevron", false, function()
            tSelectedItem = {
                item = item,
                label = entry.label or item,
                normalPrice = entry.normalPrice,
                buyPrice = entry.buyPrice,
                sellPrice = entry.sellPrice or 0,
                isNew = false
            }
        end, StaffMenu.ltdItemEdit)
    end
end

StaffMenu.builderLTDItems.OnOpen(function()
    StaffMenu.BuildLTDItemsMenu()
end)

-- ==================== EDIT MENU ====================

local function refreshFromCache()
    if not tSelectedItem or tSelectedItem.isNew then return end
    local entry = findEntry(tSelectedItem.item)
    if entry then
        tSelectedItem.label = entry.label or tSelectedItem.item
        tSelectedItem.normalPrice = entry.normalPrice
        tSelectedItem.buyPrice = entry.buyPrice
        tSelectedItem.sellPrice = entry.sellPrice or 0
    end
end

local function persist()
    if not tSelectedItem then return end
    local result = TriggerServerCallback("vfw:ltd:items:upsert", {
        item = tSelectedItem.item,
        label = tSelectedItem.label,
        normalPrice = tSelectedItem.normalPrice,
        buyPrice = tSelectedItem.buyPrice,
        sellPrice = tSelectedItem.sellPrice
    })
    if result and result.success then
        tSelectedItem.isNew = false
        VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "LTD", message = "Item enregistré." })
    else
        VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "LTD", message = (result and result.error) or "Erreur." })
    end
end

local function BuildLTDItemEdit()
    if not tSelectedItem then return end
    refreshFromCache()

    StaffMenu.ltdItemEdit.Separator(tSelectedItem.item)

    StaffMenu.ltdItemEdit.Button("LABEL", tSelectedItem.label or "-", nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Label de l'item")
        if input and input ~= "" then
            tSelectedItem.label = input
            persist()
            StaffMenu.ltdItemEdit.refresh()
        end
    end)

    StaffMenu.ltdItemEdit.Button("PRIX SUPÉRETTE (NORMAL)", fmtPrice(tSelectedItem.normalPrice), "Tapez 0 pour retirer", "chevron", false, function()
        local value = inputNumber("Prix supérette (" .. LOCALE.currencySymbol .. ")")
        if value == false then return end
        tSelectedItem.normalPrice = value
        persist()
        StaffMenu.ltdItemEdit.refresh()
    end)

    StaffMenu.ltdItemEdit.Button("PRIX ACHAT MARKET", fmtPrice(tSelectedItem.buyPrice), "Tapez 0 pour retirer", "chevron", false, function()
        local value = inputNumber("Prix d'achat Market (" .. LOCALE.currencySymbol .. ")")
        if value == false then return end
        tSelectedItem.buyPrice = value
        persist()
        StaffMenu.ltdItemEdit.refresh()
    end)

    StaffMenu.ltdItemEdit.Button("PRIX CATALOGUE LTD (REVENTE)", fmtPrice(tSelectedItem.sellPrice), nil, "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Prix catalogue LTD (" .. LOCALE.currencySymbol .. ")")
        if input and tonumber(input) then
            tSelectedItem.sellPrice = tonumber(input)
            persist()
            StaffMenu.ltdItemEdit.refresh()
        end
    end)

    StaffMenu.ltdItemEdit.Separator("ACTIONS")

    StaffMenu.ltdItemEdit.Button(":save: ENREGISTRER", "Sauvegarder en base", nil, "chevron", false, function()
        persist()
    end)

    StaffMenu.ltdItemEdit.Button(":trash: SUPPRIMER", "Retirer cet item du catalogue LTD", nil, "chevron", false, function()
        local result = TriggerServerCallback("vfw:ltd:items:remove", tSelectedItem.item)
        if result and result.success then
            VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "LTD", message = "Item supprimé." })
            tSelectedItem = nil
            StaffMenu.ltdItemEdit.close()
        else
            VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "LTD", message = (result and result.error) or "Erreur." })
        end
    end)
end

StaffMenu.ltdItemEdit.OnOpen(function()
    BuildLTDItemEdit()
end)
