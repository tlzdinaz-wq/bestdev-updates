
local VUI = exports["VUI"]
local SellMenu = {}
local banner <const> = exports["core"]:GetVUIBanner("default")
local currentVehicleEntity = nil
local menuLocationId = nil

local function notif(content, subtitle)
    local cfg = menuLocationId and VehicleResellerConfigs and VehicleResellerConfigs[menuLocationId]
    local npcImage = cfg and cfg.npc_image or VFW.CDN.Get("others/vehicle_sell_seller.png")
    VFW.ShowNotification({
        type = "JOB",
        title = "Vendeur Véhicule",
        subtitle = subtitle or "Information",
        image = npcImage,
        content = content
    })
end

SellMenu.main = VUI:CreateMenu("MENU VENTE DE VEHICULE", banner, true)
SellMenu.currentSales = VUI:CreateSubMenu(SellMenu.main, "VOS VENTES EN COURS", banner, true)
SellMenu.saleDetails = VUI:CreateSubMenu(SellMenu.currentSales, "DETAILS DE LA VENTE", banner, true)

SellMenu.main.OnOpen(function()
    isSellMenuOpen = true
end)

SellMenu.currentSales.OnOpen(function()
    isSellMenuOpen = true

    local salesList <const> = TriggerServerCallback("vfw:vehicle:getCurrentSales", menuLocationId)
    local count = 0

    for _, SaleData in pairs(salesList) do
        SellMenu.currentSales.Button((SaleData.model):upper(), "Prix: "..VFW.Math.FormatMoney(SaleData.price).." | Plaque: "..SaleData.plate, nil, "chevron", false, function()
            SellMenu.saleDetails.data = SaleData
        end, SellMenu.saleDetails)

        count = count + 1
    end

    if count == 0 then
        SellMenu.currentSales.Button("Aucune vente en cours", nil, nil, nil, false, function() end)
    end

end)

SellMenu.saleDetails.OnOpen(function()
    isSellMenuOpen = true
    local sale <const> = SellMenu.saleDetails.data

    if not sale then
        return
    end

    SellMenu.saleDetails.Separator("INFORMATIONS")
    SellMenu.saleDetails.Button("Modèle: "..(sale.model):upper(), nil, nil, nil, false, function() end)
    SellMenu.saleDetails.Button("Plaque: "..sale.plate, nil, nil, nil, false, function() end)
    SellMenu.saleDetails.Button("Prix: "..VFW.Math.FormatMoney(sale.price), nil, nil, nil, false, function() end)
    SellMenu.saleDetails.Button("Mis en vente le: "..sale.created_at, nil, nil, nil, false, function() end)
    SellMenu.saleDetails.Button("Expire le: "..sale.expires_at, nil, nil, nil, false, function() end)

    SellMenu.saleDetails.Separator("ACTIONS")
    SellMenu.saleDetails.Button("Retirer de la vente", "Annuler la vente de ce véhicule", nil, "chevron", false, function()
        local bResponse <const> = VFW.Nui.ConfirmPopup("Retirer de la vente", "Êtes-vous sûr de vouloir retirer ce véhicule de la vente ?")
        if bResponse then
            TriggerServerEvent("vfw:vehicle:cancelSale", menuLocationId, sale.plate)
        end
    end, SellMenu.currentSales)
end)

SellMenu.main.OnClose(function()
    isSellMenuOpen = false
end)

function VFW.OpenSellMenu(locationId, vehicleToSell)
    isSellMenuOpen = true
    menuLocationId = locationId

    local npcBusy = TriggerServerCallback("vfw:vehicle:isNpcBusy", locationId) or false

    local freshAccounts = TriggerServerCallback("vfw:vehicle:getPlayerAccounts")
    local playerMoney = freshAccounts and freshAccounts.cash or (VFW.PlayerData.money or 0)
    local playerBank = freshAccounts and freshAccounts.bank or 0

    local validVehicleToSell = nil
    if vehicleToSell and vehicleToSell.plate then
        local vehicles = TriggerServerCallback("vfw:vehicle:getAllVehicles") or {}
        local plate = vehicleToSell.plate:gsub("%s+", "")

        for _, veh in ipairs(vehicles) do
            local vehPlate = veh.plate:gsub("%s+", "")
            if vehPlate == plate then
                validVehicleToSell = vehicleToSell
                break
            end
        end
    end

    currentVehicleEntity = validVehicleToSell and validVehicleToSell.vehicle or nil

    local salesList = TriggerServerCallback("vfw:vehicle:getPublicSales", locationId) or {}
    local formattedListings = {}

    for _, sale in pairs(salesList) do
        local modelName = sale.model

        if not modelName or type(modelName) == "number" then
            goto continueListings
        end

        modelName = tostring(modelName)

        if modelName:match("^%-?%d+$") then
            goto continueListings
        end

        table.insert(formattedListings, {
            id = sale.plate,
            name = modelName:upper(),
            model = modelName,
            plate = sale.plate,
            price = sale.price,
            seller = sale.sellerName or "Inconnu",
            owner = sale.owner,
            image = "https://docs.fivem.net/vehicles/" .. modelName .. ".webp",
            performance = {
                moteur = sale.props and sale.props.modEngine or 0,
                frein = sale.props and sale.props.modBrakes or 0,
                transmission = sale.props and sale.props.modTransmission or 0,
                suspension = sale.props and sale.props.modSuspension or 0,
            }
        })

        ::continueListings::
    end

    local mySales = TriggerServerCallback("vfw:vehicle:getCurrentSales", locationId) or {}
    local formattedMySales = {}

    for _, sale in pairs(mySales) do
        local modelName = sale.model

        if not modelName or type(modelName) == "number" then
            goto continueMySales
        end

        modelName = tostring(modelName)

        if modelName:match("^%-?%d+$") then
            goto continueMySales
        end

        table.insert(formattedMySales, {
            id = sale.plate,
            name = modelName:upper(),
            model = modelName,
            plate = sale.plate,
            price = sale.price,
            createdAt = sale.created_at,
            expiresAt = sale.expires_at,
            image = "https://docs.fivem.net/vehicles/" .. modelName .. ".webp",
            performance = {
                moteur = sale.props and sale.props.modEngine or 0,
                frein = sale.props and sale.props.modBrakes or 0,
                transmission = sale.props and sale.props.modTransmission or 0,
                suspension = sale.props and sale.props.modSuspension or 0,
            }
        })

        ::continueMySales::
    end

    local history = TriggerServerCallback("vfw:vehicle:getSellHistory") or {}

    local currentVehicle = nil
    if validVehicleToSell then
        local modelName = validVehicleToSell.model or "unknown"
        currentVehicle = {
            id = validVehicleToSell.plate,
            name = (validVehicleToSell.displayName and validVehicleToSell.displayName ~= "NULL") and validVehicleToSell.displayName or modelName:upper(),
            model = modelName,
            plate = validVehicleToSell.plate,
            image = "https://docs.fivem.net/vehicles/" .. modelName .. ".webp",
            condition = validVehicleToSell.condition or 100,
            performance = {
                moteur = validVehicleToSell.mods and validVehicleToSell.mods.modEngine or 0,
                frein = validVehicleToSell.mods and validVehicleToSell.mods.modBrakes or 0,
                transmission = validVehicleToSell.mods and validVehicleToSell.mods.modTransmission or 0,
                suspension = validVehicleToSell.mods and validVehicleToSell.mods.modSuspension or 0,
            }
        }
    end

    SendNUIMessage({
        action = "openVehicleSell",
        data = {
            playerMoney = playerMoney,
            playerBank = playerBank,
            currentVehicle = currentVehicle,
            listings = formattedListings,
            myListings = formattedMySales,
            history = history,
            npcBusy = npcBusy
        }
    })
    VFW.Nui.Focus(true)
end


function VFW.CloseSellMenu()
    isSellMenuOpen = false
    currentVehicleEntity = nil
    SendNUIMessage({
        action = "closeVehicleSell",
        data = {}
    })
    VFW.Nui.Focus(false)
end

RegisterNUICallback("closeVehicleSell", function(_, cb)
    VFW.CloseSellMenu()
    cb("ok")
end)

RegisterNUICallback("vehicleSell:navigate", function(data, cb)
    cb("ok")
end)

RegisterNUICallback("vehicleSell:noVehicle", function(_, cb)
    notif("Vous devez garer un véhicule à proximité du vendeur pour le mettre en vente.")
    cb("ok")
end)

RegisterNUICallback("vehicleSell:sell", function(data, cb)
    local plate = data.plate
    local price = data.price

    if not plate or not price or price <= 0 then
        notif("Les informations envoyées ne sont pas valides.")
        cb("error")
        return
    end

    local vehicles = TriggerServerCallback("vfw:vehicle:getAllVehicles") or {}
    local vehicleData = nil

    for _, veh in ipairs(vehicles) do
        local vehPlate = veh.plate:gsub("%s+", "")
        if vehPlate == plate then
            vehicleData = veh
            break
        end
    end

    if not vehicleData then
        notif("Ce véhicule ne vous appartient pas.")
        cb("error")
        return
    end

    local vehicleEntity = currentVehicleEntity

    if not vehicleEntity or not DoesEntityExist(vehicleEntity) then
        notif("Véhicule introuvable à proximité.")
        cb("error")
        return
    end

    VFW.CloseSellMenu()
    cb("ok")

    local locId = menuLocationId
    VehicleReseller:PlaySellAnimation(locId, vehicleEntity, vehicleData, price, function(success)
        currentVehicleEntity = nil
    end)
end)

RegisterNUICallback("vehicleSell:buy", function(data, cb)
    local vehicleId = data.vehicleId
    local paymentMethod = data.paymentMethod or "banque"

    if not vehicleId then
        notif("Les informations envoyées ne sont pas valides.")
        cb("error")
        return
    end

    local salesList = TriggerServerCallback("vfw:vehicle:getPublicSales", menuLocationId) or {}
    local vehicleData = nil

    for _, sale in pairs(salesList) do
        if sale.plate == vehicleId then
            vehicleData = sale
            break
        end
    end

    if not vehicleData then
        notif("Ce véhicule n'est plus en vente.")
        cb("error")
        return
    end

    VFW.CloseSellMenu()
    cb("ok")

    local locId = menuLocationId
    VehicleReseller:PlayBuyAnimation(locId, vehicleData, paymentMethod, function(success)
        if not success then
            notif("L'achat a été annulé.")
        end
    end)
end)

RegisterNUICallback("vehicleSell:cancelListing", function(data, cb)
    local vehicleId = data.vehicleId

    if not vehicleId then
        notif("Les informations envoyées ne sont pas valides.")
        cb("error")
        return
    end

    TriggerServerEvent("vfw:vehicle:cancelSale", menuLocationId, vehicleId)
    notif("Demande de retrait envoyée au vendeur.", "Annulation")
    cb("ok")
end)

SellMenu.paymentMethod = VUI:CreateSubMenu(SellMenu.main, "MODE DE PAIEMENT", banner, true)

function VFW.OpenPaymentMenu(vehicleData, model, vehiclePrice)
    SellMenu.paymentMethod.vehicleData = vehicleData
    SellMenu.paymentMethod.model = model
    SellMenu.paymentMethod.price = vehiclePrice
    SellMenu.paymentMethod.open()
end

SellMenu.paymentMethod.OnOpen(function()
    local vehData = SellMenu.paymentMethod.vehicleData
    local model = SellMenu.paymentMethod.model
    local price = SellMenu.paymentMethod.price

    if not vehData or not model or not price then
        return
    end

    SellMenu.paymentMethod.Separator("INFORMATIONS")
    SellMenu.paymentMethod.Button("Véhicule: "..model, nil, nil, nil, false, function() end)
    SellMenu.paymentMethod.Button("Prix: "..VFW.Math.FormatMoney(price), nil, nil, nil, false, function() end)

    SellMenu.paymentMethod.Separator("CHOISIR LE MODE DE PAIEMENT")

    SellMenu.paymentMethod.Button("Payer en Cash", "Payer avec l'argent liquide", nil, "chevron", false, function()
        local response = VFW.Nui.ConfirmPopup("Achat en Cash", ("Êtes-vous sûr de vouloir acheter le véhicule %s pour %s en cash ?"):format(model, VFW.Math.FormatMoney(price)))
        if response then
            TriggerServerEvent("vfw:vehicle:buyVehicle", menuLocationId, vehData, "cash")
            SellMenu.paymentMethod.close()
        end
    end)

    SellMenu.paymentMethod.Button("Payer par Banque", "Payer avec votre compte bancaire", nil, "chevron", false, function()
        local response = VFW.Nui.ConfirmPopup("Achat par Banque", ("Êtes-vous sûr de vouloir acheter le véhicule %s pour %s par banque ?"):format(model, VFW.Math.FormatMoney(price)))
        if response then
            TriggerServerEvent("vfw:vehicle:buyVehicle", menuLocationId, vehData, "banque")
            SellMenu.paymentMethod.close()
        end
    end)
end)
