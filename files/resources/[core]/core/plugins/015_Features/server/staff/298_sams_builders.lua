local function hospitalRows()
    return Staff29.Query("SELECT id, name, pos, active, blip_enabled FROM sams_hospitals ORDER BY id ASC")
end

local function hospitalArray()
    local rows = hospitalRows()
    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            id = row.id,
            name = row.name or "",
            pos = Staff29.Decode(row.pos, { x = 0.0, y = 0.0, z = 0.0, h = 0.0 }),
            active = row.active == 1,
            blipEnabled = row.blip_enabled == 1,
        }
    end
    return out
end

local function hospitalMap()
    local list = hospitalArray()
    local out = {}
    for i = 1, #list do
        out[list[i].id] = {
            name = list[i].name,
            pos = list[i].pos,
            active = list[i].active,
            blipEnabled = list[i].blipEnabled,
        }
    end
    return out
end

local function syncHospitals(target)
    TriggerClientEvent("sn_sams:hospital:sync", target or -1, hospitalMap())
end

local function pharmacyArray()
    local rows = Staff29.Query(
        "SELECT id, name, pos, npc_pos, active, blip_enabled FROM sams_pharmacies ORDER BY id ASC")
    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        n = n + 1
        out[n] = {
            id = row.id,
            name = row.name or "",
            pos = Staff29.Decode(row.pos, { x = 0.0, y = 0.0, z = 0.0 }),
            npcPos = Staff29.Decode(row.npc_pos, { x = 0.0, y = 0.0, z = 0.0, h = 0.0 }),
            active = row.active == 1,
            blipEnabled = row.blip_enabled == 1,
        }
    end
    return out
end

local function pharmacyMap()
    local list = pharmacyArray()
    local out = {}
    for i = 1, #list do
        out[list[i].id] = {
            name = list[i].name,
            pos = list[i].pos,
            npcPos = list[i].npcPos,
            active = list[i].active,
            blipEnabled = list[i].blipEnabled,
        }
    end
    return out
end

local function syncPharmacies(target)
    TriggerClientEvent("sn_sams:pharmacy:sync", target or -1, pharmacyMap())
end

local function pharmacyItems()
    local rows = Staff29.Query("SELECT id, name, label, price, is_sams_item FROM sams_pharmacy_items ORDER BY id ASC")
    local out, n = {}, 0
    for i = 1, #rows do
        local row = rows[i]
        local item = VFW.Items and VFW.Items[row.name]
        n = n + 1
        out[n] = {
            id = row.id,
            name = row.name,
            label = row.label or (item and item.label) or row.name,
            price = tonumber(row.price) or 0,
            isSamsItem = row.is_sams_item == 1,
        }
    end
    return out
end

local function invalidateItems()
    TriggerClientEvent("sn_sams:pharmacy:invalidateItemsCache", -1)
end

Staff29.Cb("sn_sams:hospital:getHospitals", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return hospitalArray()
end)

Staff29.Cb("sn_sams:hospital:getSpawns", function(source, hospitalId)
    local id = Staff29.ToInt(hospitalId, 1, 2147483647)
    if not id then return {} end

    local rows = Staff29.Query("SELECT id, pos FROM sams_hospital_spawns WHERE hospital_id = ? ORDER BY id ASC", { id })
    local out, n = {}, 0
    for i = 1, #rows do
        n = n + 1
        out[n] = { id = rows[i].id, pos = Staff29.Decode(rows[i].pos, { x = 0.0, y = 0.0, z = 0.0, h = 0.0 }) }
    end
    return out
end)

RegisterNetEvent("sn_sams:hospital:create", function(data)
    local source = source
    if not Staff29.IsTable(data) then return end

    local xPlayer = Staff29.Require(source, "hospital_builder")
    if not xPlayer then return end

    local name = Staff29.Clean(data.name, 80) or "Hôpital"
    local pos = Staff29.IsTable(data.pos) and data.pos or nil
    if not pos then return end

    Staff29.Insert([[
        INSERT INTO sams_hospitals (name, pos, active, blip_enabled) VALUES (?, ?, ?, ?)
    ]], { name, Staff29.Encode(pos), data.active ~= false and 1 or 0, data.blipEnabled ~= false and 1 or 0 })

    syncHospitals()
end)

RegisterNetEvent("sn_sams:hospital:update", function(hospitalId, field, value)
    local source = source
    local id = Staff29.ToInt(hospitalId, 1, 2147483647)
    if not id or not Staff29.IsString(field, 32) then return end

    local xPlayer = Staff29.Require(source, "hospital_builder")
    if not xPlayer then return end

    if field == "name" then
        local name = Staff29.Clean(value, 80)
        if not name then return end
        Staff29.Update("UPDATE sams_hospitals SET name = ? WHERE id = ?", { name, id })
    elseif field == "pos" then
        if not Staff29.IsTable(value) then return end
        Staff29.Update("UPDATE sams_hospitals SET pos = ? WHERE id = ?", { Staff29.Encode(value), id })
    elseif field == "active" then
        Staff29.Update("UPDATE sams_hospitals SET active = ? WHERE id = ?", { value and 1 or 0, id })
    elseif field == "blipEnabled" then
        Staff29.Update("UPDATE sams_hospitals SET blip_enabled = ? WHERE id = ?", { value and 1 or 0, id })
    else
        return
    end

    syncHospitals()
end)

RegisterNetEvent("sn_sams:hospital:delete", function(hospitalId)
    local source = source
    if Staff29.EventBlocked("sn_sams:hospital:delete", source) then return end

    local id = Staff29.ToInt(hospitalId, 1, 2147483647)
    if not id then return end

    local xPlayer = Staff29.Require(source, "hospital_builder")
    if not xPlayer then return end

    Staff29.Update("DELETE FROM sams_hospital_spawns WHERE hospital_id = ?", { id })
    Staff29.Update("DELETE FROM sams_hospitals WHERE id = ?", { id })

    syncHospitals()
end)

RegisterNetEvent("sn_sams:hospital:addSpawn", function(hospitalId, pos)
    local source = source
    local id = Staff29.ToInt(hospitalId, 1, 2147483647)
    if not id or not Staff29.IsTable(pos) then return end

    local xPlayer = Staff29.Require(source, "hospital_builder")
    if not xPlayer then return end

    Staff29.Insert("INSERT INTO sams_hospital_spawns (hospital_id, pos) VALUES (?, ?)", { id, Staff29.Encode(pos) })
end)

RegisterNetEvent("sn_sams:hospital:removeSpawn", function(spawnId)
    local source = source
    if Staff29.EventBlocked("sn_sams:hospital:removeSpawn", source) then return end

    local id = Staff29.ToInt(spawnId, 1, 2147483647)
    if not id then return end

    local xPlayer = Staff29.Require(source, "hospital_builder")
    if not xPlayer then return end

    Staff29.Update("DELETE FROM sams_hospital_spawns WHERE id = ?", { id })
end)

Staff29.Cb("sn_sams:pharmacy:getPharmacies", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return pharmacyArray()
end)

Staff29.Cb("sn_sams:pharmacy:getItems", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return pharmacyItems()
end)

RegisterNetEvent("sn_sams:pharmacy:create", function(shopData)
    local source = source
    if not Staff29.IsTable(shopData) then return end

    local xPlayer = Staff29.Require(source, "pharmacy_builder")
    if not xPlayer then return end

    local name = Staff29.Clean(shopData.name, 80) or "Pharmacie"
    if not Staff29.IsTable(shopData.pos) then return end

    Staff29.Insert([[
        INSERT INTO sams_pharmacies (name, pos, npc_pos, active, blip_enabled) VALUES (?, ?, ?, ?, ?)
    ]], { name, Staff29.Encode(shopData.pos), Staff29.Encode(shopData.npcPos or shopData.pos),
          shopData.active ~= false and 1 or 0, shopData.blipEnabled ~= false and 1 or 0 })

    syncPharmacies()
end)

RegisterNetEvent("sn_sams:pharmacy:update", function(shopId, field, value)
    local source = source
    local id = Staff29.ToInt(shopId, 1, 2147483647)
    if not id or not Staff29.IsString(field, 32) then return end

    local xPlayer = Staff29.Require(source, "pharmacy_builder")
    if not xPlayer then return end

    if field == "pos" then
        if not Staff29.IsTable(value) then return end
        Staff29.Update("UPDATE sams_pharmacies SET pos = ? WHERE id = ?", { Staff29.Encode(value), id })
    elseif field == "npcPos" then
        if not Staff29.IsTable(value) then return end
        Staff29.Update("UPDATE sams_pharmacies SET npc_pos = ? WHERE id = ?", { Staff29.Encode(value), id })
    elseif field == "active" then
        Staff29.Update("UPDATE sams_pharmacies SET active = ? WHERE id = ?", { value and 1 or 0, id })
    elseif field == "blipEnabled" then
        Staff29.Update("UPDATE sams_pharmacies SET blip_enabled = ? WHERE id = ?", { value and 1 or 0, id })
    elseif field == "name" then
        local name = Staff29.Clean(value, 80)
        if not name then return end
        Staff29.Update("UPDATE sams_pharmacies SET name = ? WHERE id = ?", { name, id })
    else
        return
    end

    syncPharmacies()
end)

RegisterNetEvent("sn_sams:pharmacy:delete", function(shopId)
    local source = source
    if Staff29.EventBlocked("sn_sams:pharmacy:delete", source) then return end

    local id = Staff29.ToInt(shopId, 1, 2147483647)
    if not id then return end

    local xPlayer = Staff29.Require(source, "pharmacy_builder")
    if not xPlayer then return end

    Staff29.Update("DELETE FROM sams_pharmacies WHERE id = ?", { id })
    syncPharmacies()
end)

RegisterNetEvent("sn_sams:pharmacy:addItem", function(itemName, price, isSamsItem)
    local source = source
    if not Staff29.IsString(itemName, 60) then return end

    local value = Staff29.ToInt(price, 0, 10000000)
    if not value then return end

    local xPlayer = Staff29.Require(source, "pharmacy_builder")
    if not xPlayer then return end

    local item = VFW.Items and VFW.Items[itemName]
    Staff29.Update([[
        INSERT INTO sams_pharmacy_items (name, label, price, is_sams_item) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), price = VALUES(price), is_sams_item = VALUES(is_sams_item)
    ]], { itemName, item and item.label or itemName, value, isSamsItem and 1 or 0 })

    invalidateItems()
end)

RegisterNetEvent("sn_sams:pharmacy:updateItem", function(itemName, price, isSamsItem)
    local source = source
    if not Staff29.IsString(itemName, 60) then return end

    local value = Staff29.ToInt(price, 0, 10000000)
    if not value then return end

    local xPlayer = Staff29.Require(source, "pharmacy_builder")
    if not xPlayer then return end

    Staff29.Update("UPDATE sams_pharmacy_items SET price = ?, is_sams_item = ? WHERE name = ?",
        { value, isSamsItem and 1 or 0, itemName })

    invalidateItems()
end)

RegisterNetEvent("sn_sams:pharmacy:removeItem", function(itemName)
    local source = source
    if Staff29.EventBlocked("sn_sams:pharmacy:removeItem", source) then return end
    if not Staff29.IsString(itemName, 60) then return end

    local xPlayer = Staff29.Require(source, "pharmacy_builder")
    if not xPlayer then return end

    Staff29.Update("DELETE FROM sams_pharmacy_items WHERE name = ?", { itemName })
    invalidateItems()
end)

RegisterNetEvent("sn_sams:pharmacy:requestSync", function()
    local source = source
    if not VFW.GetPlayerFromId(source) then return end
    syncPharmacies(source)
    TriggerClientEvent("sn_sams:hospital:sync", source, hospitalMap())
end)

Staff29.Cb("sn_sams:pharmacy:getItemsForShop", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { items = {}, isSams = false, canUseSociety = false, societyMoney = 0, cash = 0, bank = 0 }
    end

    local SAMS = Staff29.SAMS
    local isSams = SAMS.HasJob(xPlayer)
    local canBuySams = isSams and SAMS.Can(xPlayer, "pharmacy_buy_sams_items")
    local canUseSociety = isSams and SAMS.Can(xPlayer, "pharmacy_society_payment")

    local all = pharmacyItems()
    local items, n = {}, 0
    for i = 1, #all do
        if not all[i].isSamsItem or canBuySams then
            n = n + 1
            items[n] = {
                name = all[i].name,
                label = all[i].label,
                price = all[i].price,
                isSamsItem = all[i].isSamsItem,
            }
        end
    end

    local societyMoney = 0
    if canUseSociety then
        societyMoney = Staff29.Boss.GetSocietyMoney(xPlayer.job.name)
    end

    local cash = xPlayer.getAccount("money")
    local bank = xPlayer.getAccount("bank")

    return {
        items = items,
        isSams = isSams,
        canUseSociety = canUseSociety,
        societyMoney = societyMoney,
        cash = cash and cash.money or 0,
        bank = bank and bank.money or 0,
    }
end)

Staff29.Cb("sn_sams:pharmacy:purchaseItems", function(source, purchaseData, total, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Erreur interne" } end
    if not Staff29.IsTable(purchaseData) or #purchaseData == 0 then
        return { success = false, message = "Panier vide" }
    end
    if not Staff29.RateLimit(source, "pharmacyBuy", 1500) then
        return { success = false, message = "Veuillez patienter" }
    end

    local SAMS = Staff29.SAMS
    local isSams = SAMS.HasJob(xPlayer)
    local canBuySams = isSams and SAMS.Can(xPlayer, "pharmacy_buy_sams_items")
    local canUseSociety = isSams and SAMS.Can(xPlayer, "pharmacy_society_payment")

    local catalog = {}
    local all = pharmacyItems()
    for i = 1, #all do catalog[all[i].name] = all[i] end

    local computed = 0
    local lines, n = {}, 0

    for i = 1, #purchaseData do
        local entry = purchaseData[i]
        if not Staff29.IsTable(entry) then return { success = false, message = "Votre panier n'est pas valide" } end

        local name = entry.name
        local quantity = Staff29.ToInt(entry.quantity, 1, 100)
        if not Staff29.IsString(name, 60) or not quantity then
            return { success = false, message = "Votre panier n'est pas valide" }
        end

        local product = catalog[name]
        if not product then return { success = false, message = "Article indisponible" } end
        if product.isSamsItem and not canBuySams then
            return { success = false, message = "Article réservé au personnel SAMS" }
        end

        computed = computed + (product.price * quantity)
        n = n + 1
        lines[n] = { name = name, quantity = quantity }
    end

    if computed <= 0 then return { success = false, message = "Votre panier n'est pas valide" } end

    for i = 1, #lines do
        if not xPlayer.canCarryItem(lines[i].name, lines[i].quantity) then
            return { success = false, message = "Votre inventaire est plein (capacité maximale)." }
        end
    end

    if paymentMethod == "society" then
        if not canUseSociety then return { success = false, message = "Paiement société non autorisé" } end
        local debited = Staff29.Update(
            "UPDATE society_accounts SET money = money - ? WHERE job_name = ? AND money >= ?",
            { computed, xPlayer.job.name, computed })
        if (tonumber(debited) or 0) < 1 then
            return { success = false, message = "Fonds de société insuffisants" }
        end
    elseif paymentMethod == "cash" or paymentMethod == "bank" then
        local accountName = paymentMethod == "cash" and "money" or "bank"
        local account = xPlayer.getAccount(accountName)
        if not account or account.money < computed then
            return { success = false, message = "Fonds insuffisants" }
        end
        xPlayer.removeAccountMoney(accountName, computed, "pharmacy")
    else
        return { success = false, message = "Ce moyen de paiement n'est pas valide" }
    end

    for i = 1, #lines do
        xPlayer.addInventoryItem(lines[i].name, lines[i].quantity, nil, true)
    end

    return { success = true, message = ("Achat effectué (%d$)"):format(computed) }
end)

AddEventHandler("vfw:playerLoaded", function(source)
    if not source or source == 0 then return end
    VFW.SetTimeout(2000, function()
        if not VFW.GetPlayerFromId(source) then return end
        TriggerClientEvent("sn_sams:hospital:sync", source, hospitalMap())
        syncPharmacies(source)
    end)
end)
