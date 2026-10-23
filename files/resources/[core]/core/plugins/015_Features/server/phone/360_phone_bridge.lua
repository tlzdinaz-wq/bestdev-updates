---@meta _
---@diagnostic disable: duplicate-doc-field

-- Pont VFW -> sd-phone (resources/[tel]/sd-phone).
--
-- sd-phone ne connaît ni VFW ni son inventaire : il parle à un « framework » par une couche de
-- pont (bridge/). Plutôt que de lui faire copier l'objet VFW entier à chaque appel (le joueur
-- porte son skin, son inventaire, ses permissions...), on expose ici une API étroite et stable,
-- toujours résolue au moment de l'appel — elle survit donc à un redémarrage de `core`.
--
-- Argent : l'espèces est l'item `money` de l'inventaire (compte « money » ignoré), la banque est
-- le compte `bank`, l'argent sale est l'item `dirty_money`. C'est ce que fait déjà le module de
-- banque (310_bank_core) ; on s'aligne dessus pour que le téléphone et l'ATM voient les mêmes
-- soldes.

local CASH_ITEM <const> = "money"
local BLACK_ITEM <const> = "dirty_money"

local function player(source)
    source = tonumber(source)
    if not source then return nil end
    return VFW.GetPlayerFromId(source)
end

local function inv()
    return VFW.Inventory
end

local function jobView(job)
    if type(job) ~= "table" then return nil end
    return {
        name = job.name,
        label = job.label,
        type = job.type,
        grade = tonumber(job.grade) or 0,
        gradeName = job.grade_name,
        gradeLabel = job.grade_label,
        isBoss = job.grade_is_boss == true,
        onDuty = job.onDuty == true,
    }
end

-- ---------------------------------------------------------------------------
-- Joueur
-- ---------------------------------------------------------------------------

--- Vue légère d'un joueur chargé. Nil tant qu'aucun personnage n'est en jeu.
exports("PhonePlayer", function(source)
    local xPlayer = player(source)
    if not xPlayer then return nil end

    return {
        source = xPlayer.source,
        identifier = xPlayer.identifier,
        charId = xPlayer.charId,
        firstName = xPlayer.firstName,
        lastName = xPlayer.lastName,
        name = xPlayer.name,
        dateofbirth = xPlayer.dateofbirth,
        sex = xPlayer.sex,
        group = xPlayer.group,
        job = jobView(xPlayer.job),
        job2 = jobView(xPlayer.job2),
    }
end)

--- `{ [identifier] = source }` pour tous les personnages en jeu : une seule traversée de
--- ressource au lieu d'un appel par joueur.
exports("PhoneOnlineMap", function()
    local out = {}
    for _, xPlayer in pairs(VFW.Players) do
        if type(xPlayer) == "table" and xPlayer.identifier then
            out[xPlayer.identifier] = xPlayer.source
        end
    end
    return out
end)

exports("PhoneSourceByIdentifier", function(identifier)
    if type(identifier) ~= "string" or identifier == "" then return nil end
    local xPlayer = VFW.GetPlayerFromIdentifier(identifier)
    return xPlayer and xPlayer.source or nil
end)

exports("PhoneGetMeta", function(source, key)
    local xPlayer = player(source)
    if not xPlayer or type(key) ~= "string" then return nil end
    return xPlayer.getMeta(key)
end)

exports("PhoneNotify", function(source, message, kind)
    local xPlayer = player(source)
    if not xPlayer then return false end
    xPlayer.showNotification({
        type = kind == "error" and "ROUGE" or "VERT",
        content = tostring(message or ""),
    })
    return true
end)

-- ---------------------------------------------------------------------------
-- Argent
-- ---------------------------------------------------------------------------

local function moneyKind(kind)
    if kind == "bank" then return "bank" end
    if kind == "black" or kind == "black_money" or kind == "dirty" then return "black" end
    return "cash"
end

local function amountOf(value)
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then return 0 end
    return n
end

local function itemCount(xPlayer, name)
    local Inv = inv()
    if not (Inv and Inv.PlayerList and Inv.CountByName) then return 0 end
    return math.floor(tonumber(Inv.CountByName(Inv.PlayerList(xPlayer), name)) or 0)
end

exports("PhoneMoneyGet", function(source, kind)
    local xPlayer = player(source)
    if not xPlayer then return 0 end

    kind = moneyKind(kind)
    if kind == "bank" then
        local account = xPlayer.getAccount("bank")
        return math.floor(tonumber(account and account.money) or 0)
    end
    return itemCount(xPlayer, kind == "black" and BLACK_ITEM or CASH_ITEM)
end)

exports("PhoneMoneyAdd", function(source, kind, amount, reason)
    local xPlayer = player(source)
    amount = amountOf(amount)
    if not xPlayer or amount <= 0 then return false end

    kind = moneyKind(kind)
    if kind == "bank" then
        xPlayer.addAccountMoney("bank", amount, reason or "sd-phone")
        return true
    end

    local Inv = inv()
    if not (Inv and Inv.GivePlayerItem) then return false end
    local added = Inv.GivePlayerItem(xPlayer, kind == "black" and BLACK_ITEM or CASH_ITEM, amount, nil, false)
    return (tonumber(added) or 0) >= amount
end)

--- Retire `amount` ; faux (et rien n'est retiré) si le solde ne suffit pas.
exports("PhoneMoneyRemove", function(source, kind, amount, reason)
    local xPlayer = player(source)
    amount = amountOf(amount)
    if not xPlayer or amount <= 0 then return false end

    kind = moneyKind(kind)
    if kind == "bank" then
        local account = xPlayer.getAccount("bank")
        if math.floor(tonumber(account and account.money) or 0) < amount then return false end
        xPlayer.removeAccountMoney("bank", amount, reason or "sd-phone")
        return true
    end

    local item = kind == "black" and BLACK_ITEM or CASH_ITEM
    if itemCount(xPlayer, item) < amount then return false end

    local Inv = inv()
    if not (Inv and Inv.TakePlayerItem) then return false end
    local removed = Inv.TakePlayerItem(xPlayer, item, amount, false)
    return (tonumber(removed) or 0) >= amount
end)

-- ---------------------------------------------------------------------------
-- Inventaire
-- ---------------------------------------------------------------------------

local function entryView(entry)
    return {
        slot = entry.slot,
        name = entry.name,
        count = entry.count,
        metadata = type(entry.meta) == "table" and entry.meta or {},
    }
end

exports("PhoneItemExists", function(name)
    local Inv = inv()
    return Inv and Inv.Exists and Inv.Exists(name) == true or false
end)

exports("PhoneItemLabel", function(name)
    local def = VFW.Items and VFW.Items[name]
    return def and def.label or nil
end)

exports("PhoneItemCount", function(source, name)
    local xPlayer = player(source)
    if not xPlayer or type(name) ~= "string" then return 0 end
    return itemCount(xPlayer, name)
end)

exports("PhoneItemAdd", function(source, name, count, metadata)
    local xPlayer = player(source)
    local Inv = inv()
    count = amountOf(count)
    if not xPlayer or not Inv or count <= 0 then return false end
    local added = Inv.GivePlayerItem(xPlayer, name, count, metadata, false)
    return (tonumber(added) or 0) >= count
end)

exports("PhoneItemRemove", function(source, name, count)
    local xPlayer = player(source)
    local Inv = inv()
    count = amountOf(count)
    if not xPlayer or not Inv or count <= 0 then return false end
    if itemCount(xPlayer, name) < count then return false end
    local removed = Inv.TakePlayerItem(xPlayer, name, count, false)
    return (tonumber(removed) or 0) >= count
end)

exports("PhoneItemCanCarry", function(source, name, count)
    local xPlayer = player(source)
    local Inv = inv()
    count = amountOf(count)
    if not xPlayer or not Inv or not Inv.Exists(name) then return false end
    if count <= 0 then return true end
    return Inv.CanCarry(xPlayer, name, count) == true
end)

--- Chaque emplacement qui contient `name`, métadonnées comprises.
exports("PhoneItemSearch", function(source, name)
    local xPlayer = player(source)
    local Inv = inv()
    local out = {}
    if not xPlayer or not Inv or type(name) ~= "string" then return out end

    local list = Inv.PlayerList(xPlayer)
    for i = 1, #list do
        if list[i].name == name then out[#out + 1] = entryView(list[i]) end
    end
    return out
end)

exports("PhoneItemSlot", function(source, slot)
    local xPlayer = player(source)
    local Inv = inv()
    if not xPlayer or not Inv then return nil end

    local entry = Inv.FindSlot(Inv.PlayerList(xPlayer), tonumber(slot))
    return entry and entryView(entry) or nil
end)

--- Remplace les métadonnées de l'emplacement (pas de fusion), puis rafraîchit l'inventaire.
--- Un emplacement qui change de métadonnées doit rester seul dans sa pile : deux téléphones
--- aux numéros différents ne fusionnent pas, c'est ce que `MetaKey` garantit côté VFW.
exports("PhoneItemSetMeta", function(source, slot, metadata)
    local xPlayer = player(source)
    local Inv = inv()
    if not xPlayer or not Inv then return false end

    local entry = Inv.FindSlot(Inv.PlayerList(xPlayer), tonumber(slot))
    if not entry then return false end

    entry.meta = Inv.SanitizeMeta(metadata)
    Inv.PushPlayer(xPlayer)
    return true
end)

exports("PhoneItemRemoveSlot", function(source, name, slot, count)
    local xPlayer = player(source)
    local Inv = inv()
    if not xPlayer or not Inv then return false end

    local list = Inv.PlayerList(xPlayer)
    local entry = Inv.FindSlot(list, tonumber(slot))
    if not entry or entry.name ~= name then return false end

    local taken = Inv.RemoveFromSlot(list, tonumber(slot), amountOf(count) > 0 and amountOf(count) or 1)
    if not taken then return false end
    Inv.PushPlayer(xPlayer)
    return true
end)

--- Déclare `name` utilisable ; l'usage revient à sd-phone par l'évènement serveur
--- `vfw:phone:itemUsed` (source, name, slot, metadata). Un seul gestionnaire par item côté VFW,
--- d'où le relais par évènement : plusieurs ressources peuvent s'y brancher.
exports("PhoneRegisterUsable", function(name)
    local Inv = inv()
    if type(name) ~= "string" or name == "" or not Inv or not Inv.RegisterUsableItem then
        return false
    end

    return Inv.RegisterUsableItem(name, function(xPlayer, entry)
        TriggerEvent("vfw:phone:itemUsed", xPlayer.source, name, entry.slot, entry.meta or {})
    end)
end)

-- ---------------------------------------------------------------------------
-- Métier
-- ---------------------------------------------------------------------------

exports("PhoneJobLabel", function(name)
    local job = VFW.Jobs and VFW.Jobs[name]
    return job and job.label or nil
end)

exports("PhoneSetJob", function(source, name, grade)
    local xPlayer = player(source)
    if not xPlayer or type(name) ~= "string" or name == "" then return false end
    if not (VFW.Jobs and VFW.Jobs[name]) then return false end
    xPlayer.setJob(name, tonumber(grade) or 0)
    return true
end)

exports("PhoneSetDuty", function(source, onDuty)
    local xPlayer = player(source)
    if not xPlayer then return false end
    xPlayer.setDuty(onDuty == true)
    return true
end)

-- ---------------------------------------------------------------------------
-- Sociétés (compte partagé d'un métier)
-- ---------------------------------------------------------------------------

exports("PhoneSocietyGet", function(jobName)
    return VFW.Bank.GetSocietyMoney(jobName)
end)

exports("PhoneSocietyAdd", function(jobName, amount)
    amount = amountOf(amount)
    if amount <= 0 or type(jobName) ~= "string" or jobName == "" then return false end
    VFW.Bank.AddSocietyMoney(jobName, amount)
    return true
end)

--- Faux si le compte ne contient pas assez : le solde ne passe jamais sous zéro.
exports("PhoneSocietyTake", function(jobName, amount)
    return VFW.Bank.TakeSocietyMoney(jobName, amount) == true
end)

-- ---------------------------------------------------------------------------
-- Catalogue d'items
-- ---------------------------------------------------------------------------

--- Crée dans la table `items` les objets que sd-phone attend (variantes de téléphone, carte SIM)
--- et qui n'y sont pas encore, puis recharge le catalogue en mémoire et chez les clients.
--- `list` : `{ { name, label, weight?, image?, description? } }`. N'écrase jamais une ligne
--- existante (réglages de poids / image faits depuis le hub de gestion conservés).
---@return string[] inserted noms des objets créés
exports("PhoneEnsureItems", function(list)
    local inserted = {}
    if type(list) ~= "table" then return inserted end

    for i = 1, #list do
        local entry = list[i]
        if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= ""
            and not (VFW.Items and VFW.Items[entry.name]) then
            local image = type(entry.image) == "string" and entry.image ~= "" and entry.image
                or ("items/%s.webp"):format(entry.name)

            MySQL.insert.await([[
                INSERT IGNORE INTO items (name, label, type, weight, premium, perm, image, description, data)
                VALUES (?, ?, 'items', ?, 0, 0, ?, ?, ?)
            ]], {
                entry.name,
                tostring(entry.label or entry.name):sub(1, 100),
                math.max(0, math.floor(tonumber(entry.weight) or (VFW.ItemWeights and VFW.ItemWeights[entry.name]) or 100)),
                image,
                tostring(entry.description or ""):sub(1, 500),
                json.encode({ type = "objects" }),
            })
            inserted[#inserted + 1] = entry.name
        end
    end

    if #inserted > 0 then
        local ok, err = pcall(VFW.DB.RefreshItemsCatalog)
        if not ok then
            console.warn(("[sd-phone] catalogue d'items non rechargé : %s"):format(tostring(err)))
        else
            TriggerClientEvent("vfw:loadItems", -1, VFW.Items)
        end
    end

    return inserted
end)

-- ---------------------------------------------------------------------------
-- Virement vers un personnage hors ligne
-- ---------------------------------------------------------------------------

--- Crédite le compte bancaire d'un personnage identifié par `identifier`, connecté ou non (la
--- ligne `characters.accounts` est réécrite s'il est hors ligne). C'est la même fonction que
--- celle du module de banque : un virement du téléphone arrive donc comme un virement d'ATM.
exports("PhoneCreditIdentifier", function(identifier, amount, reason)
    return VFW.Bank.CreditIdentifier(identifier, amountOf(amount), reason or "sd-phone") == true
end)

-- ---------------------------------------------------------------------------
-- Entreprises (annuaire de l'application Services)
-- ---------------------------------------------------------------------------

local function validHex(value)
    return type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

local function planarPoint(point)
    if type(point) ~= "table" then return nil end
    local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
    if not x or not y then return nil end
    return { x = x, y = y, z = z or 0.0 }
end

--- Tous les métiers du serveur, tels que le téléphone les affiche comme entreprises : nom du
--- métier, libellé, logo (URL complète), adresse, position et couleur d'accent.
---
--- Le point de départ est la liste des MÉTIERS, pas celle des sociétés : un métier existant peut ne
--- pas (encore) de ligne dans `societies` — c'est le cas de la plupart des métiers déjà en
--- base — et il doit apparaître quand même, sans logo. Ce que le builder a saisi pour lui (logo,
--- adresse, repère, accent) s'ajoute quand la société existe.
--- Un métier se joint, se message et se met en service par son nom, d'où ce point de départ.
---@return table[]
exports("PhoneCompanies", function()
    local out = {}
    local societies = VFW.Society and VFW.Society.GetAll and VFW.Society.GetAll() or {}

    for name, job in pairs(VFW.Jobs or {}) do
        if type(name) == "string" and name ~= "unemployed" and type(job) == "table" then
            local society = type(societies[name]) == "table" and societies[name] or {}
            local image = type(society.image) == "string" and society.image or ""
            local blip = type(society.blip) == "table" and society.blip or {}
            local custom = type(society.custom) == "table" and society.custom or {}

            -- Le repère de la carte quand il est activé, sinon le point de gestion du patron.
            local position = (blip.enabled and planarPoint(blip.position)) or planarPoint(society.management)

            local label = society.label
            if type(label) ~= "string" or label == "" then label = job.label end

            out[#out + 1] = {
                name = name,
                label = (type(label) == "string" and label ~= "") and label or name,
                type = society.type or job.type,
                logo = image ~= "" and VFW.CdnUrl(image) or nil,
                address = type(society.address) == "string" and society.address or "",
                position = position,
                color = validHex(custom.announceTitleColor) and custom.announceTitleColor or nil,
            }
        end
    end

    table.sort(out, function(a, b) return tostring(a.label):lower() < tostring(b.label):lower() end)
    return out
end)
