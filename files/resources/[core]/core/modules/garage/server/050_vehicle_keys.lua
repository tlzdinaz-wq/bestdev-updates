VFW.VehicleKeys = VFW.VehicleKeys or {}

local Keys = VFW.VehicleKeys

-- Clés de véhicule : l'objet `keys` dont la plaque est en métadonnée. C'est ce que lisent toutes les vérifications de clés
-- (verrouillage, coffre, menu staff : Staff29.PlayerHasVehicleKey). Elles suivent le garage : remises quand le véhicule
-- sort, retirées quand il est rangé.

local ITEM <const> = "keys"

local function normalize(plate)
    if type(plate) ~= "string" then return nil end
    local trimmed = plate:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil end
    return trimmed:upper()
end

local function isKeyFor(entry, wanted)
    if type(entry) ~= "table" or entry.name ~= ITEM or type(entry.meta) ~= "table" then return false end
    return normalize(entry.meta.plate) == wanted
end

--- Le joueur a-t-il dans son inventaire la clé (l'objet `keys`) de cette plaque ? C'est la seule vérification de clé :
--- Staff29.PlayerHasVehicleKey s'appuie dessus pour le verrouillage.
---@param xPlayer table
---@param plate string
---@return boolean
function Keys.Has(xPlayer, plate)
    local Inv = VFW.Inventory
    local wanted = normalize(plate)
    if not (wanted and xPlayer and Inv and Inv.PlayerList) then return false end

    local list = Inv.PlayerList(xPlayer)
    for i = 1, #list do
        if isKeyFor(list[i], wanted) then return true end
    end
    return false
end

--- Remet la clé d'un véhicule au joueur. Renvoie "given" ou "already" (il l'a déjà), sinon nil et la raison.
--- `copy` à true : une clé de plus même s'il en a déjà une (double remis par le concessionnaire).
---@param xPlayer table
---@param plate string
---@param copy boolean|nil
---@return string|nil result, string|nil reason
function Keys.Give(xPlayer, plate, copy)
    local Inv = VFW.Inventory
    local wanted = normalize(plate)
    if not wanted then return nil, "plaque illisible" end
    if not (xPlayer and Inv and Inv.GivePlayerItem and Inv.PlayerList and Inv.Exists) then return nil, "inventaire indisponible" end
    if not Inv.Exists(ITEM) then return nil, "l'objet « keys » n'existe pas : ajoutez-le dans Gestion > Items" end

    if not copy and Keys.Has(xPlayer, wanted) then return "already" end

    local added = Inv.GivePlayerItem(xPlayer, ITEM, 1, {
        plate = wanted,
        description = ("Clés du véhicule %s"):format(wanted),
    }, true)
    if (added or 0) <= 0 then return nil, "inventaire plein" end
    return "given"
end

--- Le véhicule change de propriétaire : l'ancien perd sa clé (s'il est connecté) et le nouveau reçoit la sienne si le
--- véhicule est sorti. Rangé au garage, personne n'a de clé : elle est remise à la sortie.
---@param plate string
---@param previousIdentifier string|nil identifiant de l'ancien propriétaire
---@param xNewOwner table|nil
---@return string|nil result, string|nil reason "given" | "already" | "stored" (rien à remettre), sinon nil et la raison
function Keys.Transfer(plate, previousIdentifier, xNewOwner)
    local previous = previousIdentifier and VFW.GetPlayerFromIdentifier and VFW.GetPlayerFromIdentifier(previousIdentifier)
    if previous then Keys.Remove(previous, plate) end

    if not xNewOwner then return "stored" end

    local Vehicles = VFW.Vehicles
    local entity = Vehicles and Vehicles.FindEntityByPlate and Vehicles.FindEntityByPlate(plate)
    if not (entity and DoesEntityExist(entity)) then return "stored" end

    return Keys.Give(xNewOwner, plate)
end

--- Retire de l'inventaire du joueur toutes les clés de cette plaque. Renvoie le nombre de clés retirées.
---@param xPlayer table
---@param plate string
---@return number
function Keys.Remove(xPlayer, plate)
    local Inv = VFW.Inventory
    local wanted = normalize(plate)
    if not (wanted and xPlayer and Inv and Inv.PlayerList and Inv.RemoveFromSlot) then return 0 end

    local list = Inv.PlayerList(xPlayer)
    local removed = 0
    -- à rebours : retirer une entrée décale celles qui la suivent
    for i = #list, 1, -1 do
        local entry = list[i]
        if isKeyFor(entry, wanted) then
            local taken = Inv.RemoveFromSlot(list, entry.slot, entry.count)
            if taken then removed = removed + taken.count end
        end
    end

    if removed > 0 and Inv.PushPlayer then Inv.PushPlayer(xPlayer) end
    return removed
end

--- Retire les clés de cette plaque à tous les joueurs connectés (véhicule de société : les clés sont celles du groupe).
---@param plate string
---@return number
function Keys.RemoveEverywhere(plate)
    local total = 0
    for _, id in ipairs(GetPlayers()) do
        local xPlayer = VFW.GetPlayerFromId(tonumber(id))
        if xPlayer then total = total + Keys.Remove(xPlayer, plate) end
    end
    return total
end
