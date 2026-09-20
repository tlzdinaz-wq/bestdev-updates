Feat27 = Feat27 or {}

RegisterServerCallback("paidshop:getOwnedPeds", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = MySQL.query.await("SELECT `ped_model`, `name`, `image` FROM owned_peds WHERE `identifier` = ? ORDER BY `id` ASC", {
        xPlayer.identifier,
    }) or {}

    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local definition = PaidShop.FindItem("peds", row.ped_model)
        out[i] = {
            pedModel = row.ped_model,
            name = row.name ~= "" and row.name or (definition and definition.name) or row.ped_model,
            image = row.image ~= "" and row.image or (definition and definition.image) or "",
        }
    end
    return out
end)

RegisterServerCallback("paidshop:verifyPedOwnership", function(source, pedModel)
    if type(pedModel) ~= "string" or pedModel == "" then return false end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    local row = MySQL.single.await("SELECT `id` FROM owned_peds WHERE `identifier` = ? AND `ped_model` = ?", {
        xPlayer.identifier, pedModel,
    })

    return row ~= nil
end)

function PaidShop.GrantPed(identifier, pedModel, name, image)
    if type(identifier) ~= "string" or type(pedModel) ~= "string" then return false end
    MySQL.query.await("INSERT IGNORE INTO owned_peds (`identifier`, `ped_model`, `name`, `image`) VALUES (?, ?, ?, ?)", {
        identifier, pedModel, name or pedModel, image or "",
    })
    return true
end
