VFW.JobsCommon = VFW.JobsCommon or {}
VFW.BarMenu = VFW.BarMenu or {}

local JC = VFW.JobsCommon
local BarMenu = VFW.BarMenu

local SECTION_ORDER = {
    "BOISSONS", "COCKTAILS", "SNACKS", "BURGERS", "PIZZAS", "PLATS",
    "FRUITS DE MER", "SIDES", "MILKSHAKES", "VIENNOISERIES", "CAFES", "GRANITA",
}

local DEFAULT_PRICES = {
    BOISSONS = 25,
    COCKTAILS = 45,
    SNACKS = 15,
    BURGERS = 60,
    PIZZAS = 70,
    PLATS = 75,
    ["FRUITS DE MER"] = 90,
    SIDES = 20,
    MILKSHAKES = 35,
    VIENNOISERIES = 20,
    CAFES = 25,
    GRANITA = 30,
}

local function canEditCards(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if xPlayer.hasPermission("builder_farm") then return true end
    return JC.IsStaff(xPlayer)
end

local function sectionRank(section)
    for i = 1, #SECTION_ORDER do
        if SECTION_ORDER[i] == section then return i end
    end
    return #SECTION_ORDER + 1
end

function BarMenu.Label(jobName)
    if type(BarsConfig) == "table" then
        for i = 1, #BarsConfig do
            local bar = BarsConfig[i]
            if type(bar) == "table" and bar.jobName == jobName then
                return bar.label or jobName
            end
        end
    end
    if VFW.Jobs and VFW.Jobs[jobName] then return VFW.Jobs[jobName].label or jobName end
    return jobName or "Carte"
end

function BarMenu.Bars()
    local out = {}
    if type(BarsConfig) == "table" then
        for i = 1, #BarsConfig do
            local bar = BarsConfig[i]
            if type(bar) == "table" and type(bar.jobName) == "string" then
                out[#out + 1] = { jobName = bar.jobName, label = bar.label or bar.jobName }
            end
        end
    end
    return out
end

function BarMenu.Seed()
    local existing = JC.Scalar("SELECT COUNT(*) FROM bar_menu_items", {}, 0)
    if (tonumber(existing) or 0) > 0 then return end
    if type(BarsDefaultItems) ~= "table" then return end

    for jobName, items in pairs(BarsDefaultItems) do
        if type(items) == "table" then
            for i = 1, #items do
                local entry = items[i]
                if type(entry) == "table" and type(entry.item) == "string" then
                    local section = entry.section or "BOISSONS"
                    JC.Exec([[
                        INSERT IGNORE INTO bar_menu_items (job_name, item, section, label, description, price, position)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    ]], {
                        jobName,
                        entry.item,
                        section,
                        JC.ItemLabel(entry.item),
                        nil,
                        DEFAULT_PRICES[section] or 25,
                        i,
                    })
                end
            end
        end
    end

    console.info("[BarMenu] Cartes de bars initialisees depuis BarsDefaultItems.")
end

local function itemRows(jobName)
    return JC.Query([[
        SELECT id, job_name, item, section, label, description, price, position
        FROM bar_menu_items WHERE job_name = ? ORDER BY position ASC, id ASC
    ]], { jobName })
end

BarMenu.Rows = itemRows

local function buildSections(jobName, includeZero)
    local rows = itemRows(jobName)
    local bySection = {}
    local order = {}

    for i = 1, #rows do
        local row = rows[i]
        local section = row.section or "BOISSONS"
        local price = JC.Int(row.price, 0) or 0

        if includeZero or price > 0 then
            if not bySection[section] then
                bySection[section] = {}
                order[#order + 1] = section
            end

            local def = VFW.Items and VFW.Items[row.item]
            bySection[section][#bySection[section] + 1] = {
                name = row.item,
                label = JC.Str(row.label, 128) or JC.ItemLabel(row.item),
                description = JC.Str(row.description, 255) or (def and def.description) or nil,
                price = price,
                defaultPrice = DEFAULT_PRICES[section] or 25,
                lastPrice = price,
            }
        end
    end

    table.sort(order, function(a, b) return sectionRank(a) < sectionRank(b) end)

    local sections = {}
    for i = 1, #order do
        sections[#sections + 1] = { title = order[i], items = bySection[order[i]] }
    end

    return sections
end

BarMenu.BuildSections = buildSections

local function resolveJobName(source, jobName)
    local wanted = JC.Str(jobName, 64)
    if wanted then return wanted end

    local xPlayer = VFW.GetPlayerFromId(source)
    if xPlayer and xPlayer.job then return xPlayer.job.name end
    return nil
end

JC.Cb("bar:menu:getItems", function(source, jobName)
    local name = resolveJobName(source, jobName)
    if not name then return nil end

    return {
        barName = BarMenu.Label(name),
        jobName = name,
        sections = buildSections(name, false),
    }
end)

JC.Cb("bar:menu:getConfig", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return nil, "Vous n'avez pas de metier." end

    local name = xPlayer.job.name
    if not JC.IsBoss(xPlayer) and not JC.IsStaff(xPlayer) then
        return nil, "Vous n'avez pas les permissions necessaires."
    end

    local sections = buildSections(name, true)
    if #sections == 0 then
        return { barName = BarMenu.Label(name), jobName = name, sections = {} }, nil
    end

    return { barName = BarMenu.Label(name), jobName = name, sections = sections }, nil
end)

JC.Cb("bar:menu:saveConfig", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return false, "Vous n'avez pas de metier." end

    local name = xPlayer.job.name
    if not JC.IsBoss(xPlayer) and not JC.IsStaff(xPlayer) then
        return false, "Vous n'avez pas les permissions necessaires."
    end

    if type(data) ~= "table" or type(data.sections) ~= "table" then
        return false, "Les informations envoyees ne sont pas valides."
    end

    local updates = 0
    for i = 1, #data.sections do
        local section = data.sections[i]
        if type(section) == "table" and type(section.items) == "table" then
            local title = JC.Str(section.title, 64) or "BOISSONS"
            for j = 1, #section.items do
                local item = section.items[j]
                if type(item) == "table" then
                    local itemName = JC.Str(item.name, 60)
                    local price = JC.Int(item.price, 0, 10000000)
                    if itemName and price then
                        JC.Exec([[
                            UPDATE bar_menu_items SET price = ?, section = ?, position = ?
                            WHERE job_name = ? AND item = ?
                        ]], { price, title:upper(), j, name, itemName })
                        updates = updates + 1
                    end
                end
            end
        end
    end

    if updates == 0 then return false, "Aucun item a enregistrer." end
    return true, "Carte enregistree."
end)

JC.Cb("barcards:getAllBars", function(source)
    if not canEditCards(source) then return {} end
    return BarMenu.Bars()
end)

JC.Cb("barcards:getAllowedItems", function(source, jobName)
    if not canEditCards(source) then return {} end

    local name = JC.Str(jobName, 64)
    if not name then return {} end

    local rows = itemRows(name)
    local out = {}
    for i = 1, #rows do
        out[i] = {
            name = rows[i].item,
            label = JC.Str(rows[i].label, 128) or JC.ItemLabel(rows[i].item),
            section = rows[i].section or "BOISSONS",
            price = JC.Int(rows[i].price, 0) or 0,
        }
    end
    return out
end)

JC.Cb("barcards:searchItems", function(source, query)
    if not canEditCards(source) then return {} end

    local search = JC.Str(query, 60)
    if not search then return {} end

    local rows = JC.Query([[
        SELECT name, label FROM items
        WHERE name LIKE ? OR label LIKE ?
        ORDER BY name ASC LIMIT 40
    ]], { "%" .. search .. "%", "%" .. search .. "%" })

    local out = {}
    for i = 1, #rows do
        out[i] = { name = rows[i].name, label = rows[i].label or rows[i].name }
    end
    return out
end)

JC.Cb("barcards:addItem", function(source, jobName, itemName, section)
    if not canEditCards(source) then
        return false, "Permission insuffisante."
    end

    local name = JC.Str(jobName, 64)
    local item = JC.Str(itemName, 60)
    local sect = JC.Str(section, 64) or "BOISSONS"
    if not name or not item then return false, "Les informations envoyees ne sont pas valides." end

    if not VFW.Items or not VFW.Items[item] then return false, "Item inconnu." end

    local position = tonumber(JC.Scalar(
        "SELECT COALESCE(MAX(position), 0) + 1 FROM bar_menu_items WHERE job_name = ?", { name }, 1)) or 1

    JC.Exec([[
        INSERT INTO bar_menu_items (job_name, item, section, label, price, position)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE section = VALUES(section)
    ]], { name, item, sect:upper(), JC.ItemLabel(item), DEFAULT_PRICES[sect:upper()] or 25, position })

    return true, "Item ajoute."
end)

JC.Cb("barcards:removeItem", function(source, jobName, itemName)
    if not canEditCards(source) then
        return false, "Permission insuffisante."
    end

    local name = JC.Str(jobName, 64)
    local item = JC.Str(itemName, 60)
    if not name or not item then return false, "Les informations envoyees ne sont pas valides." end

    JC.Exec("DELETE FROM bar_menu_items WHERE job_name = ? AND item = ?", { name, item })
    return true, "Item retire."
end)

local cartePoints = {}

function BarMenu.LoadCartePoints()
    local rows = JC.Query("SELECT job_name, x, y, z FROM bar_carte_points ORDER BY id ASC")
    local out = {}

    for i = 1, #rows do
        local row = rows[i]
        local jobName = row.job_name
        if type(jobName) == "string" then
            out[jobName] = out[jobName] or {}
            out[jobName][#out[jobName] + 1] = {
                x = tonumber(row.x) or 0.0,
                y = tonumber(row.y) or 0.0,
                z = tonumber(row.z) or 0.0,
            }
        end
    end

    cartePoints = out
    return cartePoints
end

function BarMenu.GetCartePoints(jobName)
    return cartePoints[jobName] or {}
end

JC.Cb("bar:cartePoints:getAll", function()
    return cartePoints
end)

JC.Cb("bar:cartePoints:get", function(source, jobName)
    if not canEditCards(source) then return {} end

    local name = JC.Str(jobName, 64)
    if not name then return {} end
    return cartePoints[name] or {}
end)

JC.Cb("bar:cartePoints:set", function(source, jobName, points)
    if not canEditCards(source) then
        return false, "Permission insuffisante."
    end

    local name = JC.Str(jobName, 64)
    if not name then return false, "Ce bar n'est pas valide." end
    if type(points) ~= "table" then return false, "Ces points ne sont pas valides." end

    local clean = {}
    for i = 1, #points do
        local point = JC.Vec(points[i])
        if point then clean[#clean + 1] = point end
        if #clean >= 100 then break end
    end

    JC.Exec("DELETE FROM bar_carte_points WHERE job_name = ?", { name })
    for i = 1, #clean do
        JC.Exec("INSERT INTO bar_carte_points (job_name, x, y, z) VALUES (?, ?, ?, ?)",
            { name, clean[i].x, clean[i].y, clean[i].z })
    end

    BarMenu.LoadCartePoints()
    TriggerClientEvent("bar:cartePoints:sync", -1, name, cartePoints[name] or {})

    return true, "Points enregistres."
end)

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    Wait(2000)
    BarMenu.Seed()
    BarMenu.LoadCartePoints()
end)
