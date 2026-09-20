PoliceFineTypes = PoliceFineTypes or {}

local types = {}
local loaded = false

local PRESET_CATEGORIES = {
    { id = "contravention", label = "Contravention" },
    { id = "minor", label = "Délit mineur" },
    { id = "major", label = "Délit majeur" },
    { id = "crime", label = "Crime" },
}

local PRESET_IDS = {
    contravention = true,
    minor = true,
    major = true,
    crime = true,
}

local function ensureTable()
    MiscB.Query([[
        CREATE TABLE IF NOT EXISTS police_fine_types (
            id INT NOT NULL AUTO_INCREMENT,
            label VARCHAR(80) NOT NULL,
            category VARCHAR(32) NOT NULL,
            amount INT NOT NULL,
            PRIMARY KEY (id)
        )
    ]], {})
end

local function publicRow(row)
    return {
        id = tonumber(row.id),
        label = tostring(row.label or ""),
        category = tostring(row.category or "minor"),
        amount = tonumber(row.amount) or 0,
    }
end

local function publicList()
    local out = {}
    for i = 1, #types do
        out[i] = publicRow(types[i])
    end
    return out
end

local function syncConfig()
    Config = Config or {}
    Config.FineTypes = publicList()
end

local function categoryLabel(id)
    for i = 1, #PRESET_CATEGORIES do
        if PRESET_CATEGORIES[i].id == id then return PRESET_CATEGORIES[i].label end
    end
    if type(id) ~= "string" or id == "" then return "Autre" end
    return id:sub(1, 1):upper() .. id:sub(2)
end

local function extraCategories()
    local seen = {}
    local extra = {}
    for i = 1, #types do
        local id = types[i].category
        if type(id) == "string" and id ~= "" and not PRESET_IDS[id] and not seen[id] then
            seen[id] = true
            extra[#extra + 1] = { id = id, label = categoryLabel(id) }
        end
    end
    table.sort(extra, function(a, b) return a.label < b.label end)
    return extra
end

local function allCategories()
    local out = {}
    for i = 1, #PRESET_CATEGORIES do
        out[i] = PRESET_CATEGORIES[i]
    end
    local extra = extraCategories()
    for i = 1, #extra do
        out[#out + 1] = extra[i]
    end
    return out
end

local function cleanLabel(raw)
    local name = MiscB.Str(raw, 80)
    if not name then return nil end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" or #name < 2 then return nil end
    return name
end

local function cleanCategory(raw)
    local name = tostring(raw or ""):lower():gsub("%s+", "_"):gsub("[^%w_%-]", "")
    if name == "custom" or name == "" or #name > 32 or not name:match("^[%w_%-]+$") then return nil end
    return name
end

local function cleanAmount(raw)
    return MiscB.ToInt(raw, 1, 5000000)
end

local function findIndex(id)
    local wanted = tonumber(id)
    if not wanted then return nil end
    for i = 1, #types do
        if types[i].id == wanted then return i, types[i] end
    end
    return nil
end

local function loadTypes()
    ensureTable()
    types = {}
    local rows = MiscB.Query("SELECT id, label, category, amount FROM police_fine_types ORDER BY category ASC, amount ASC, id ASC", {})
    if #rows == 0 then
        local seed = (Config and Config.FineTypes) or {}
        for i = 1, #seed do
            local ft = seed[i]
            local label = cleanLabel(ft.label)
            local category = cleanCategory(ft.category) or "minor"
            local amount = cleanAmount(ft.amount)
            if label and amount then
                local id = MiscB.Insert(
                    "INSERT INTO police_fine_types (label, category, amount) VALUES (?, ?, ?)",
                    { label, category, amount }
                )
                if id then
                    types[#types + 1] = { id = id, label = label, category = category, amount = amount }
                end
            end
        end
    else
        for i = 1, #rows do
            types[#types + 1] = publicRow(rows[i])
        end
    end
    loaded = true
    syncConfig()
end

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("builder_fines")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") then
        return xPlayer
    end
    return nil
end

function PoliceFineTypes.List()
    if not loaded then loadTypes() end
    return publicList()
end

function PoliceFineTypes.Get(fineId)
    if not loaded then loadTypes() end
    local _, row = findIndex(fineId)
    return row and publicRow(row) or nil
end

local function payload()
    if not loaded then loadTypes() end
    return {
        ok = true,
        fines = publicList(),
        categories = allCategories(),
        presets = PRESET_CATEGORIES,
    }
end

CreateThread(function()
    local tries = 0
    while not VFW.Ready and tries < 300 do
        Wait(100)
        tries = tries + 1
    end
    Wait(1500)
    loadTypes()
end)

MiscB.Cb("policeFineTypes:getPanel", function(source)
    if not staffOk(source) then return { ok = false } end
    return payload()
end)

MiscB.Cb("police:addFineType", function(source, data)
    if not staffOk(source) then return { success = false, ok = false, message = "Permission refusée." } end
    if not loaded then loadTypes() end
    if type(data) ~= "table" then return { success = false, ok = false, message = "Données invalides." } end
    local label = cleanLabel(data.label)
    local category = cleanCategory(data.category)
    local amount = cleanAmount(data.amount)
    if not label then return { success = false, ok = false, message = "Indique un nom d'infraction." } end
    if not category then return { success = false, ok = false, message = "Catégorie invalide." } end
    if not amount then return { success = false, ok = false, message = "Montant invalide (1 à 5 000 000)." } end
    local id = MiscB.Insert(
        "INSERT INTO police_fine_types (label, category, amount) VALUES (?, ?, ?)",
        { label, category, amount }
    )
    if not id then return { success = false, ok = false, message = "Impossible d'enregistrer l'amende." } end
    types[#types + 1] = { id = id, label = label, category = category, amount = amount }
    syncConfig()
    return { success = true, ok = true, id = id }
end)

MiscB.Cb("police:updateFineType", function(source, data)
    if not staffOk(source) then return { success = false, ok = false, message = "Permission refusée." } end
    if not loaded then loadTypes() end
    if type(data) ~= "table" then return { success = false, ok = false, message = "Données invalides." } end
    local index, row = findIndex(data.id or data.fineId)
    if not row then return { success = false, ok = false, message = "Amende introuvable." } end
    local label = data.label ~= nil and cleanLabel(data.label) or row.label
    local category = data.category ~= nil and cleanCategory(data.category) or row.category
    local amount = data.amount ~= nil and cleanAmount(data.amount) or row.amount
    if not label then return { success = false, ok = false, message = "Nom invalide." } end
    if not category then return { success = false, ok = false, message = "Catégorie invalide." } end
    if not amount then return { success = false, ok = false, message = "Montant invalide." } end
    row.label = label
    row.category = category
    row.amount = amount
    types[index] = row
    MiscB.Update(
        "UPDATE police_fine_types SET label = ?, category = ?, amount = ? WHERE id = ?",
        { label, category, amount, row.id }
    )
    syncConfig()
    return { success = true, ok = true }
end)

MiscB.Cb("police:deleteFineType", function(source, data)
    if not staffOk(source) then return { success = false, ok = false, message = "Permission refusée." } end
    if not loaded then loadTypes() end
    local id = data
    if type(data) == "table" then id = data.id or data.fineId end
    local index, row = findIndex(id)
    if not row then return { success = false, ok = false, message = "Amende introuvable." } end
    MiscB.Update("DELETE FROM police_fine_types WHERE id = ?", { row.id })
    table.remove(types, index)
    syncConfig()
    return { success = true, ok = true }
end)
