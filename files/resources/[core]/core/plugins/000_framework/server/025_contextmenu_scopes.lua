-- Scopes du menu contextuel (ALT).
--
-- Les sous-menus d'information ne calculent pas leurs valeurs eux-mêmes : ils se lient
-- à un « scope », une table que le serveur résout à l'ouverture et renvoie au client.
-- C'est voulu — l'argent, le job ou le propriétaire d'un véhicule n'ont rien à faire
-- côté client, et le serveur vérifie au passage qui a le droit de les lire.
--
-- Le registre existait (025_contextmenu.lua), les menus s'y liaient — mais **aucun
-- scope n'y a jamais été enregistré**. La résolution retombait sur une table vide, et
-- toutes les lignes affichaient « N/A » :
--
--   • ALT sur soi    → Actions Staff > Mes informations
--   • ALT sur autrui → Action Staff > Infos
--   • ALT véhicule   → Action Staff > Infos & Joueurs (plaque, propriétaire)
--
-- Les noms des champs suivent ceux que les menus réclament ; les renommer ici casse
-- l'affichage là-bas.

local MENU_PERMISSION <const> = "contextmenu"

--- Droit de consulter la fiche de quelqu'un d'autre.
---@param xPlayer table Le joueur qui ouvre le menu.
---@return boolean
local function canInspectOthers(xPlayer)
    if not xPlayer or not xPlayer.hasPermission then return false end
    return xPlayer.hasPermission(MENU_PERMISSION)
        or xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("admin")
end

--- Montant lisible : « 12 500 $ ».
---@param amount number|nil
---@return string
local function moneyText(amount)
    local value = math.floor(tonumber(amount) or 0)
    local sign = value < 0 and "-" or ""
    local digits = tostring(math.abs(value))

    -- Séparateur de milliers posé de droite à gauche.
    local spaced = digits:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^%s+", "")
    return ("%s%s $"):format(sign, spaced)
end

---@param xPlayer table
---@param name string
---@return number
local function accountMoney(xPlayer, name)
    if not xPlayer.getAccount then return 0 end
    local account = xPlayer.getAccount(name)
    return account and tonumber(account.money) or 0
end

--- Temps de jeu lisible : « 12 h 34 ».
---@param seconds number|nil
---@return string
local function playtimeText(seconds)
    local total = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)

    if hours > 0 then
        return ("%d h %02d"):format(hours, minutes)
    end
    return ("%d min"):format(minutes)
end

--- Temps de jeu du joueur, session en cours comprise.
---@param xPlayer table
---@return number seconds
local function playtimeOf(xPlayer)
    local total = 0
    if xPlayer.globalData then
        total = tonumber(xPlayer.globalData.playtime) or 0
    end
    if xPlayer.sessionStart then
        total = total + math.max(0, os.time() - xPlayer.sessionStart)
    end
    return total
end

--- Métier avec son grade : « Police — Lieutenant ».
---@param job table|nil
---@return string|nil
local function jobText(job)
    if type(job) ~= "table" then return nil end

    local label = job.label or job.name
    if not label or label == "" then return nil end

    local grade = job.grade_label
    if grade and grade ~= "" and grade ~= label then
        return ("%s — %s"):format(label, grade)
    end
    return label
end

-- ══════════════════════════════════════════════════════════════════════════
-- player:identity — la fiche d'un joueur
--
-- Le même scope sert pour soi et pour autrui : la cible est le joueur derrière le
-- ped visé, et c'est soi-même quand on ouvre le menu sur son propre personnage.
-- ══════════════════════════════════════════════════════════════════════════

---@param source number Le joueur qui ouvre le menu.
---@param ent table Ce qui est visé.
---@param xPlayer table
---@return table|false
local function resolveIdentity(source, ent, xPlayer)
    local targetSource = tonumber(ent.targetSource)

    if not targetSource then
        -- Un ped visé sans joueur identifié n'est pas forcément soi : plutôt que de
        -- risquer d'afficher sa propre fiche sous le nom d'un autre, on ne rend rien.
        local targeted = ent.entity
        if targeted and targeted ~= 0 and targeted ~= GetPlayerPed(source) then
            return false
        end
        targetSource = source
    end

    -- Lire sa propre fiche ne demande rien ; lire celle d'un autre, oui.
    if targetSource ~= source and not canInspectOthers(xPlayer) then
        return false
    end

    local target = targetSource == source and xPlayer or VFW.GetPlayerFromId(targetSource)
    if not target then return false end

    local height = tonumber(target.height)

    return {
        targetSource = targetSource,
        firstName = target.firstName,
        lastName = target.lastName,
        date_of_birth = target.dateofbirth,
        height = height and ("%d cm"):format(math.floor(height)) or nil,
        job_label = jobText(target.job),
        job2_label = jobText(target.job2),
        money = moneyText(target.getMoney and target.getMoney() or 0),
        bank = moneyText(accountMoney(target, "bank")),
        black_money = moneyText(accountMoney(target, "black_money")),
        total_playtime = playtimeText(playtimeOf(target)),
    }
end

-- ══════════════════════════════════════════════════════════════════════════
-- vehicle:staff_info — plaque et propriétaire d'un véhicule
-- ══════════════════════════════════════════════════════════════════════════

--- Plaque sans les espaces de remplissage que le jeu ajoute.
---@param entity number|nil
---@return string|nil
local function plateOf(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end

    local plate = GetVehicleNumberPlateText(entity)
    if type(plate) ~= "string" then return nil end

    plate = plate:gsub("^%s+", ""):gsub("%s+$", "")
    return plate ~= "" and plate or nil
end

---@param source number
---@param ent table
---@param xPlayer table
---@return table|false
local function resolveVehicle(source, ent, xPlayer)
    if not canInspectOthers(xPlayer) then return false end

    local scope = { plate = plateOf(ent.entity) }
    if not scope.plate then return scope end

    -- Un véhicule non immatriculé — spawn staff, véhicule d'ambiance — n'a pas de
    -- ligne en base : on renvoie la plaque seule plutôt que de laisser le menu vide.
    local row = MySQL.single.await([[
        SELECT ov.owner_charid, c.firstname, c.lastname
        FROM owned_vehicles ov
        LEFT JOIN characters c ON c.id = ov.owner_charid
        WHERE ov.plate = ?
        LIMIT 1
    ]], { scope.plate })

    if not row then return scope end

    scope.ownerId = row.owner_charid
    if row.firstname and row.lastname then
        scope.ownerName = ("%s %s"):format(row.firstname, row.lastname)
    end

    return scope
end

-- 025_contextmenu.lua, qui tient le registre, est chargé juste avant celui-ci — mais
-- cet ordre tient au tri des fichiers par le serveur. On attend que le registre
-- existe plutôt que de le supposer : une erreur ici emporterait tout le démarrage.
CreateThread(function()
    while not (VFW.ContextMenu and VFW.ContextMenu.RegisterScope) do
        Wait(0)
    end

    VFW.ContextMenu.RegisterScope("player:identity", resolveIdentity)
    VFW.ContextMenu.RegisterScope("vehicle:staff_info", resolveVehicle)
end)
