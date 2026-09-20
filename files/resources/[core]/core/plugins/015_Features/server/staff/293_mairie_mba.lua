local MBA_KEYS = {
    BASKETBALL = true, BOXING = true, CONCERT = true, CURLING = true, DERBY = true,
    FAMEorSHAME = true, FASHION = true, FOOTBALL = true, ICEHOCKEY = true,
    GOKARTA = true, GOKARTB = true, TRACKMANIAA = true, TRACKMANIAB = true,
    TRACKMANIAC = true, TRACKMANIAD = true, MMA = true, EMPTY = true,
    PAINTBALL = true, ROCKETLEAGUE = true, WRESTLING = true,
}

local CHURCH_KEYS = {
    n_church = true, m_church = true, f_church = true, d_church = true,
}

local ENTITY_SET_VARS = {
    mba = "entityset_mba",
    church1 = "entityset_church1",
    church2 = "entityset_church2",
    church3 = "entityset_church3",
}

local DEFAULT_SETS = {
    mba = "EMPTY",
    church1 = "n_church",
    church2 = "n_church",
    church3 = "n_church",
}

local function getSet(key)
    local value = VFW.Variables.GetVariable(ENTITY_SET_VARS[key])
    if type(value) == "table" then value = value.set end
    if type(value) ~= "string" or value == "" then return DEFAULT_SETS[key] end
    return value
end

local function setSet(key, value)
    VFW.Variables.SetVariable(ENTITY_SET_VARS[key], { set = value })
end

RegisterNetEvent("MBA:AskForEntitySet", function()
    local source = source
    if not VFW.GetPlayerFromId(source) then return end
    TriggerClientEvent("MBA:SendEntitySet", source, getSet("mba"))
end)

RegisterNetEvent("Church1:AskForEntitySet", function()
    local source = source
    if not VFW.GetPlayerFromId(source) then return end
    TriggerClientEvent("Church1:SendEntitySet", source, getSet("church1"))
end)

RegisterNetEvent("Church2:AskForEntitySet", function()
    local source = source
    if not VFW.GetPlayerFromId(source) then return end
    TriggerClientEvent("Church2:SendEntitySet", source, getSet("church2"))
end)

RegisterNetEvent("Church3:AskForEntitySet", function()
    local source = source
    if not VFW.GetPlayerFromId(source) then return end
    TriggerClientEvent("Church3:SendEntitySet", source, getSet("church3"))
end)

RegisterNetEvent("MBA:ChangeEntitySet", function(key)
    local source = source
    local xPlayer = Staff29.Require(source, "perm_batiment")
    if not xPlayer then return end
    if not Staff29.IsString(key, 40) or not MBA_KEYS[key] then return end

    setSet("mba", key)
    TriggerClientEvent("MBA:SendEntitySet", -1, key)
end)

local function registerChurchChange(index)
    local storeKey = "church" .. index
    RegisterNetEvent(("Church%d:ChangeEntitySet"):format(index), function(key)
        local source = source
        local xPlayer = Staff29.Require(source, "perm_batiment")
        if not xPlayer then return end
        if not Staff29.IsString(key, 40) or not CHURCH_KEYS[key] then return end

        setSet(storeKey, key)
        TriggerClientEvent(("Church%d:SendEntitySet"):format(index), -1, key)
    end)
end

registerChurchChange(1)
registerChurchChange(2)
registerChurchChange(3)

Staff29.Cb("mairie:photo:pay", function(source, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        return { success = false, error = "Erreur interne." }
    end

    if paymentMethod ~= "cash" and paymentMethod ~= "bank" then
        return { success = false, error = "Ce moyen de paiement n'est pas valide." }
    end

    if not Staff29.RateLimit(source, "mairie:photo", 3000) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local price = (MairieConfig and MairieConfig.Photo and MairieConfig.Photo.price) or 500
    price = math.floor(price)

    local accountName = paymentMethod == "cash" and "money" or "bank"
    local account = xPlayer.getAccount(accountName)

    if not account or account.money < price then
        return {
            success = false,
            error = paymentMethod == "cash"
                and "Vous n'avez pas assez d'espèces."
                or "Votre compte bancaire est insuffisant.",
        }
    end

    xPlayer.removeAccountMoney(accountName, price, "mairie-photo")

    return { success = true, error = "" }
end)
