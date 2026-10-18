-- Points de faction : ce que le jeu en sait.
--
-- Le panneau de gestion fait placer quatre points par faction — laboratoire, craft,
-- stockage, garage — et les enregistre dans `faction_hub`. Jusqu'ici, un seul de ces
-- points etait lu par le jeu : le craft, via `core:faction:requestCraftPosition`.
--
-- Les trois autres n'etaient consultes que par les menus staff, pour afficher
-- « Configure ». Rien ne creait de zone, de marqueur ni de blip : le staff placait
-- des points qui n'existaient nulle part en jeu.
--
-- Ce fichier expose les positions au membre de la faction concernee, et seulement a
-- lui. Le client en fait des zones (client/factions/faction_points.lua).

local POINT_COLUMNS <const> = {
    { id = "laboratory", column = "posLaboratory", label = "Laboratoire" },
    { id = "craft", column = "posCraft", label = "Craft" },
    { id = "storage", column = "posStockage", label = "Stockage" },
    { id = "garage", column = "posGarage", label = "Garage" },
}

---@param xPlayer table
---@return string|nil
local function factionOf(xPlayer)
    local faction = xPlayer and xPlayer.faction

    if type(faction) == "table" then faction = faction.name end
    if type(faction) ~= "string" or faction == "" then return nil end
    if faction == "nofaction" or faction == "nocrew" then return nil end

    return faction
end

---@param raw any
---@return table|nil
local function position(raw)
    local vec = Staff29.Vec(Staff29.Decode(raw, nil))
    if not vec then return nil end

    -- Une position jamais posee vaut 0,0,0 en base : ce n'est pas un endroit, c'est
    -- l'absence d'endroit. La renvoyer poserait une zone au centre de la carte.
    if (tonumber(vec.x) or 0) == 0 and (tonumber(vec.y) or 0) == 0 and (tonumber(vec.z) or 0) == 0 then
        return nil
    end

    return vec
end

--- Les points de la faction du joueur.
---
--- Rend une liste vide tant que la faction n'est pas activee : tant que le staff n'a
--- pas termine la configuration, rien ne doit apparaitre en jeu.
Staff29.Cb("core:faction:getHubPoints", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local faction = factionOf(xPlayer)
    if not faction then return {} end

    local row = Staff29.Single("SELECT * FROM faction_hub WHERE faction_name = ?", { faction })
    if not row then return {} end
    if not (row.active == 1 or row.active == true) then return {} end

    local out = {}
    for i = 1, #POINT_COLUMNS do
        local point = POINT_COLUMNS[i]
        local pos = position(row[point.column])

        if pos then
            out[#out + 1] = { id = point.id, label = point.label, pos = pos }
        end
    end

    return out
end)
