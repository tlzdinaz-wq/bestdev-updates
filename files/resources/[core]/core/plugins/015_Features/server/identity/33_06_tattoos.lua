local Cl = VFW.Cloths

local MAX_TATTOOS = 120

local ZONES = {
    head = "ZONE_HEAD",
    torso = "ZONE_TORSO",
    leftArm = "ZONE_LEFT_ARM",
    rightArm = "ZONE_RIGHT_ARM",
    leftLeg = "ZONE_LEFT_LEG",
    rightLeg = "ZONE_RIGHT_LEG",
}

local function validName(value)
    if type(value) ~= "string" then return nil end
    if value == "" or #value > 64 then return nil end
    if not value:match("^[%w_%-%.]+$") then return nil end
    return value
end

function Cl.GetTattoos(xPlayer)
    if type(xPlayer.tattoos) ~= "table" then
        xPlayer.tattoos = {}
    end

    local out = {}
    for i = 1, #xPlayer.tattoos do
        local entry = xPlayer.tattoos[i]
        if type(entry) == "table" and entry.Collection then
            out[#out + 1] = {
                Collection = entry.Collection,
                Hash = entry.Hash or entry.HashName,
                zone = entry.zone,
            }
        end
    end
    return out
end

function Cl.PersistTattoos(xPlayer, list)
    local clean = {}
    for i = 1, #list do
        local entry = list[i]
        local collection = validName(entry.Collection)
        local hash = validName(entry.Hash or entry.HashName)
        if collection and hash then
            clean[#clean + 1] = {
                Collection = collection,
                Hash = hash,
                zone = Cl.Str(entry.zone, 32),
            }
        end
        if #clean >= MAX_TATTOOS then break end
    end

    xPlayer.tattoos = clean
    MySQL.update("UPDATE characters SET tattoos = ? WHERE identifier = ?", {
        VFW.DB.Encode(clean), xPlayer.identifier,
    })

    MySQL.query("DELETE FROM character_tattoos WHERE identifier = ?", { xPlayer.identifier })
    for i = 1, #clean do
        MySQL.insert("INSERT INTO character_tattoos (identifier, collection, hash, zone) VALUES (?, ?, ?, ?)", {
            xPlayer.identifier, clean[i].Collection, clean[i].Hash, clean[i].zone or "",
        })
    end

    xPlayer.setPlayerData("tattoos", clean)
    return clean
end

local function hasTattoo(list, collection, hash)
    for i = 1, #list do
        if list[i].Collection == collection and (list[i].Hash == hash) then
            return i
        end
    end
    return nil
end

local function pushTattoos(xPlayer, list)
    TriggerClientEvent("core:client:setTattoo", xPlayer.source, list)
end

RegisterServerCallback("core:server:getTattoo", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return Cl.GetTattoos(xPlayer)
end)

RegisterNetEvent("core:server:setTattoo", function(dataTattoo, _price)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(dataTattoo) ~= "table" then return end
    if not Cl.RateLimit(source, "settattoo", 250) then return end

    local collection = validName(dataTattoo.Collection)
    local hash = validName(dataTattoo.Hash or dataTattoo.HashName)
    if not collection or not hash then return end

    local list = Cl.GetTattoos(xPlayer)
    if hasTattoo(list, collection, hash) then return end
    if #list >= MAX_TATTOOS then
        Cl.Notify(source, "Vous avez atteint la limite de tatouages.")
        return
    end

    local gender = Cl.GenderOf(xPlayer)
    local price = Cl.PriceOf(gender, "tattoo")

    if not Cl.Charge(xPlayer, "cash", price, "tattoo") then
        Cl.Notify(source, "Fonds insuffisants.")
        pushTattoos(xPlayer, list)
        return
    end

    list[#list + 1] = { Collection = collection, Hash = hash, zone = Cl.Str(dataTattoo.zone, 32) }
    local saved = Cl.PersistTattoos(xPlayer, list)
    pushTattoos(xPlayer, saved)
end)

RegisterNetEvent("core:server:removeTattoo", function(collection, hash)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Cl.RateLimit(source, "removetattoo", 250) then return end

    local coll = validName(collection)
    local hsh = validName(hash)
    if not coll or not hsh then return end

    local list = Cl.GetTattoos(xPlayer)
    local index = hasTattoo(list, coll, hsh)
    if not index then return end

    table.remove(list, index)
    local saved = Cl.PersistTattoos(xPlayer, list)
    pushTattoos(xPlayer, saved)
end)

RegisterServerCallback("core:server:buyTattoo", function(source, data, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(data) ~= "table" then return false end
    if not Cl.RateLimit(source, "buytattoo", 250) then return false end

    local collection = validName(data.collection or data.Collection)
    local hash = validName(data.overlay or data.Hash)
    if not collection or not hash then return false end

    local list = Cl.GetTattoos(xPlayer)
    if hasTattoo(list, collection, hash) then return true end
    if #list >= MAX_TATTOOS then
        Cl.Notify(source, "Vous avez atteint la limite de tatouages.")
        return false
    end

    local gender = Cl.GenderOf(xPlayer)
    local price = Cl.PriceOf(gender, "tattoo")
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, price, "tattoo") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    local zone = data.zone
    if type(zone) == "string" then
        zone = ZONES[zone] or zone
    else
        zone = nil
    end

    list[#list + 1] = { Collection = collection, Hash = hash, zone = Cl.Str(zone, 32) }
    local saved = Cl.PersistTattoos(xPlayer, list)
    pushTattoos(xPlayer, saved)

    return true
end)

RegisterServerCallback("core:server:applyTattooChanges", function(source, formattedTattoos, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(formattedTattoos) ~= "table" then return false end
    if not Cl.RateLimit(source, "applytattoos", 500) then return false end

    local wanted = {}
    for i = 1, #formattedTattoos do
        local entry = formattedTattoos[i]
        if type(entry) == "table" then
            local collection = validName(entry.Collection)
            local hash = validName(entry.Hash or entry.HashName)
            if collection and hash then
                wanted[#wanted + 1] = { Collection = collection, Hash = hash, zone = Cl.Str(entry.zone, 32) }
            end
        end
        if #wanted >= MAX_TATTOOS then break end
    end

    local current = Cl.GetTattoos(xPlayer)

    local added = 0
    for i = 1, #wanted do
        if not hasTattoo(current, wanted[i].Collection, wanted[i].Hash) then
            added = added + 1
        end
    end

    local removed = 0
    for i = 1, #current do
        if not hasTattoo(wanted, current[i].Collection, current[i].Hash) then
            removed = removed + 1
        end
    end

    local gender = Cl.GenderOf(xPlayer)
    local unit = Cl.PriceOf(gender, "tattoo")
    local total = (added * unit) + (removed * math.floor(unit / 2))
    local method = (paymentMethod == "bank") and "bank" or "cash"

    if not Cl.Charge(xPlayer, method, total, "tattoo-changes") then
        Cl.Notify(source, "Fonds insuffisants.")
        return false
    end

    local saved = Cl.PersistTattoos(xPlayer, wanted)
    pushTattoos(xPlayer, saved)

    return true
end)
