-- Builder PNJ : les lignes de spawn A -> B sur les trottoirs (menu staff > Builder > SPAWN PNJ).
--
-- Le menu appelait sept callbacks serveur (`vfw:pnj:builder:*`) qui n'existaient pas : l'appel restait sans
-- reponse et le menu affichait « Chargement du menu... » indefiniment. Les voici.
--
-- Les lignes sont gardees dans la variable serveur `pnj_lines` (comme les modeles de television) : aucune
-- table a creer, rien a importer. Une ligne = { id, pointA = {x,y,z}, pointB = {x,y,z} }.
--
-- Cote jeu, `VFW.PNJ.Lines.List()` et `VFW.PNJ.Lines.RandomPoint(id)` donnent acces aux lignes aux scripts qui
-- veulent y faire apparaitre des PNJ (vendeurs de drogue...).

local VARIABLE <const> = "pnj_lines"
local PERMISSION <const> = "pnj_builder"
local MIN_LENGTH <const> = 1.0            -- meme seuil que la capture cote client
local TEST_GROUP <const> = "pnj_builder_test"

local testByPlayer = {}                   -- source -> netId du PNJ de test

-- ---------------------------------------------------------------------------
-- Lignes
-- ---------------------------------------------------------------------------

--- Un client envoie GetEntityCoords() tel quel : un vector3, pas une table.
local function readPoint(value)
    local kind = type(value)
    if kind ~= "table" and kind ~= "vector3" and kind ~= "vector4" then return nil end

    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z or x ~= x or y ~= y or z ~= z then return nil end

    return { x = math.floor(x * 100 + 0.5) / 100, y = math.floor(y * 100 + 0.5) / 100, z = math.floor(z * 100 + 0.5) / 100 }
end

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function stored()
    local data = VFW.Variables.GetVariable(VARIABLE)
    if type(data) ~= "table" then return {} end
    return data
end

local function save(list)
    VFW.Variables.SetVariable(VARIABLE, list)
    VFW.Variables.Flush(VARIABLE)
end

local function indexOf(list, id)
    local wanted = tostring(id):lower()
    for i = 1, #list do
        if tostring(list[i].id):lower() == wanted then return i end
    end
    return nil
end

local function cleanId(value)
    if type(value) ~= "string" then return nil end
    local id = value:gsub("^%s+", ""):gsub("%s+$", "")
    if id == "" or #id > 48 or not id:match("^[%w_%-]+$") then return nil end
    return id
end

local function nextAutoId(list)
    local highest = 0
    for i = 1, #list do
        local n = tonumber(tostring(list[i].id):match("^trottoir_(%d+)$"))
        if n and n > highest then highest = n end
    end
    return ("trottoir_%02d"):format(highest + 1)
end

local function copyLines(list)
    local out = {}
    for i = 1, #list do
        local line = list[i]
        if type(line) == "table" and type(line.pointA) == "table" and type(line.pointB) == "table" then
            out[#out + 1] = {
                id = line.id,
                pointA = { x = line.pointA.x, y = line.pointA.y, z = line.pointA.z },
                pointB = { x = line.pointB.x, y = line.pointB.y, z = line.pointB.z },
            }
        end
    end
    table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return out
end

local function pointOnLine(line, t)
    return {
        x = line.pointA.x + (line.pointB.x - line.pointA.x) * t,
        y = line.pointA.y + (line.pointB.y - line.pointA.y) * t,
        z = line.pointA.z + (line.pointB.z - line.pointA.z) * t,
    }
end

--- Cap le long de la ligne (A vers B), en degres GTA.
local function headingOf(line)
    local dx, dy = line.pointB.x - line.pointA.x, line.pointB.y - line.pointA.y
    return (-math.deg(math.atan(dx, dy))) % 360.0
end

VFW.PNJ = VFW.PNJ or {}
VFW.PNJ.Lines = {
    List = function() return copyLines(stored()) end,
    RandomPoint = function(id)
        local list = stored()
        local i = indexOf(list, id)
        if not i then return nil end
        local t = math.random()
        return pointOnLine(list[i], t), headingOf(list[i])
    end,
}

-- ---------------------------------------------------------------------------
-- Callbacks du menu
-- ---------------------------------------------------------------------------

--- Le joueur peut-il utiliser le builder ? Sinon, la reponse toute prete.
local function allowed(source)
    local xPlayer = Staff29.Require(source, PERMISSION)
    if xPlayer then return xPlayer end
    return nil, { success = false, error = "Vous n'avez pas la permission requise." }
end

Staff29.Cb("vfw:pnj:builder:getLines", function(source)
    local xPlayer = allowed(source)
    if not xPlayer then return {} end
    return copyLines(stored())
end)

Staff29.Cb("vfw:pnj:builder:autoCreateLine", function(source, pa, pb)
    local xPlayer, refusal = allowed(source)
    if not xPlayer then return refusal end
    if not Staff29.RateLimit(source, "pnj_line", 500) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local a, b = readPoint(pa), readPoint(pb)
    if not a or not b then return { success = false, error = "Positions invalides." } end
    if distance(a, b) < MIN_LENGTH then return { success = false, error = "La ligne est trop courte." } end

    local list = stored()
    local id = nextAutoId(list)
    list[#list + 1] = { id = id, pointA = a, pointB = b }
    save(list)

    return { success = true, id = id }
end)

Staff29.Cb("vfw:pnj:builder:createLine", function(source, id, pa, pb)
    local xPlayer, refusal = allowed(source)
    if not xPlayer then return refusal end
    if not Staff29.RateLimit(source, "pnj_line", 500) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local clean = cleanId(id)
    if not clean then
        return { success = false, error = "ID invalide : lettres, chiffres, _ et - (48 caracteres au plus)." }
    end

    local a, b = readPoint(pa), readPoint(pb)
    if not a or not b then return { success = false, error = "Positions invalides." } end

    local list = stored()
    if indexOf(list, clean) then return { success = false, error = "Cet ID existe deja." } end

    list[#list + 1] = { id = clean, pointA = a, pointB = b }
    save(list)

    return { success = true, id = clean }
end)

Staff29.Cb("vfw:pnj:builder:updatePoint", function(source, id, which, pos)
    local xPlayer, refusal = allowed(source)
    if not xPlayer then return refusal end
    if not Staff29.RateLimit(source, "pnj_line", 300) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    local side = type(which) == "string" and which:lower() or ""
    if side ~= "a" and side ~= "b" then return { success = false, error = "Point inconnu." } end

    local point = readPoint(pos)
    if not point then return { success = false, error = "Position invalide." } end

    local list = stored()
    local i = indexOf(list, id)
    if not i then return { success = false, error = "Ligne introuvable." } end

    list[i][side == "a" and "pointA" or "pointB"] = point
    save(list)

    return { success = true }
end)

Staff29.Cb("vfw:pnj:builder:deleteLine", function(source, id)
    local xPlayer, refusal = allowed(source)
    if not xPlayer then return refusal end

    local list = stored()
    local i = indexOf(list, id)
    if not i then return { success = false, error = "Ligne introuvable." } end

    table.remove(list, i)
    save(list)

    return { success = true }
end)

local function despawnTest(source)
    local netId = testByPlayer[source]
    testByPlayer[source] = nil
    if netId then VFW.PNJ.Delete(netId) end
end

Staff29.Cb("vfw:pnj:builder:testSpawn", function(source, id, model)
    local xPlayer, refusal = allowed(source)
    if not xPlayer then return refusal end
    if not Staff29.RateLimit(source, "pnj_test", 1000) then
        return { success = false, error = "Veuillez patienter un instant." }
    end

    if type(model) ~= "string" or #model > 64 or not model:match("^[%w_]+$") then
        return { success = false, error = "Modele invalide." }
    end

    local list = stored()
    local i = indexOf(list, id)
    if not i then return { success = false, error = "Ligne introuvable." } end

    -- Un seul PNJ de test par staff : le precedent part avant que le suivant n'arrive.
    despawnTest(source)

    local line = list[i]
    local netId = VFW.PNJ.Create(model, pointOnLine(line, math.random()), headingOf(line), {
        freeze = true,
        invincible = true,
        group = TEST_GROUP,
    })

    if not netId then
        return { success = false, error = "Le PNJ n'a pas pu apparaitre (modele inconnu ?)." }
    end

    testByPlayer[source] = netId
    return { success = true, netId = netId }
end)

Staff29.Cb("vfw:pnj:builder:despawnTest", function(source)
    local xPlayer, refusal = allowed(source)
    if not xPlayer then return refusal end

    despawnTest(source)
    return { success = true }
end)

AddEventHandler("playerDropped", function()
    local dropped = source
    if dropped then despawnTest(dropped) end
end)

-- Utilise par les tests ; sans effet en jeu.
PNJBuilder = { readPoint = readPoint, headingOf = headingOf, nextAutoId = nextAutoId }
