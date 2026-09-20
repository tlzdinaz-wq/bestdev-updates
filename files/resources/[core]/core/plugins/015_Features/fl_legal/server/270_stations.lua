Feat27 = Feat27 or {}

local stations = {}
local stationRecipes = {}
local craftSessions = {}
local loaded = false

local DEFAULT_CRAFT_TIME = 3000
local MIN_CYCLE_INTERVAL = 40
local MAX_QUANTITY = 50
local INTERACT_RADIUS = 8.0

local function decode(value, fallback)
    if VFW and VFW.DB and VFW.DB.Decode then
        return VFW.DB.Decode(value, fallback)
    end
    if type(value) == "table" then return value end
    if value == nil or value == "" then return fallback end
    local ok, res = pcall(json.decode, value)
    if ok and res ~= nil then return res end
    return fallback
end

local function buildStation(row)
    return {
        id = row.id,
        name = row.name or "Station",
        coords_x = row.coords_x + 0.0,
        coords_y = row.coords_y + 0.0,
        coords_z = row.coords_z + 0.0,
        rotation_z = (row.rotation_z or 0.0) + 0.0,
        marker_x = row.marker_x and (row.marker_x + 0.0) or nil,
        marker_y = row.marker_y and (row.marker_y + 0.0) or nil,
        marker_z = row.marker_z and (row.marker_z + 0.0) or nil,
        prop_model = row.prop_model,
        blip_enabled = (row.blip_enabled == 1 or row.blip_enabled == true),
        blip_sprite = row.blip_sprite,
        blip_color = row.blip_color,
        blip_scale = row.blip_scale and (row.blip_scale + 0.0) or nil,
        blip_label = row.blip_label,
        job_restriction = row.job_restriction or "",
        job_grade_min = row.job_grade_min or 0,
    }
end

local function loadStations()
    local rows = MySQL.query.await("SELECT * FROM legal_stations") or {}
    local out = {}
    for i = 1, #rows do
        local station = buildStation(rows[i])
        out[station.id] = station
    end
    stations = out

    local links = MySQL.query.await([[
        SELECT lsr.station_id, lsr.slot_key, lsr.position, cr.*
        FROM legal_station_recipes lsr
        INNER JOIN crafting_recipes cr ON cr.id = lsr.recipe_id
        ORDER BY lsr.station_id ASC, lsr.position ASC, lsr.id ASC
    ]]) or {}

    local recipes = {}
    for i = 1, #links do
        local row = links[i]
        local list = recipes[row.station_id]
        if not list then
            list = {}
            recipes[row.station_id] = list
        end
        local slotKey = row.slot_key
        if type(slotKey) ~= "string" or slotKey == "" then
            slotKey = row.name
        end
        list[#list + 1] = {
            id = slotKey,
            recipeDbId = row.id,
            name = row.name,
            label = row.label ~= "" and row.label or row.name,
            image = row.image or "",
            item = row.output_item,
            outputItem = row.output_item,
            outputCount = row.output_count or 1,
            craftTime = row.craft_time or DEFAULT_CRAFT_TIME,
            isLegal = true,
            ingredients = decode(row.ingredients, {}),
        }
    end
    stationRecipes = recipes
    loaded = true
    return stations
end

local function stationMap()
    if not loaded then
        pcall(loadStations)
    end
    return stations
end

local function canAccess(xPlayer, station)
    if not station then return false end
    local restriction = station.job_restriction
    if not restriction or restriction == "" then return true end
    if not xPlayer or not xPlayer.job then return false end
    if xPlayer.job.name ~= restriction then return false end
    local minGrade = tonumber(station.job_grade_min) or 0
    if minGrade > 0 and (tonumber(xPlayer.job.grade) or 0) < minGrade then return false end
    return true
end

local function stationCoords(station)
    if station.marker_x and station.marker_y and station.marker_z then
        return vector3(station.marker_x, station.marker_y, station.marker_z)
    end
    return vector3(station.coords_x, station.coords_y, station.coords_z)
end

local function isNearStation(source, station)
    local coords = Feat27.PlayerCoords(source)
    if not coords then return false end
    return #(coords - stationCoords(station)) <= INTERACT_RADIUS
end

local function normalizeIngredients(raw)
    local out = {}
    if type(raw) ~= "table" then return out end
    for key, value in pairs(raw) do
        if type(value) == "table" then
            local name = value.item or value.name or key
            local count = tonumber(value.count or value.quantity or value.amount) or 1
            if type(name) == "string" then
                out[#out + 1] = { item = name, count = math.max(1, math.floor(count)) }
            end
        elseif type(key) == "string" then
            out[#out + 1] = { item = key, count = math.max(1, math.floor(tonumber(value) or 1)) }
        end
    end
    return out
end

local function findRecipe(stationId, recipeId)
    local list = stationRecipes[stationId]
    if not list then return nil end
    for i = 1, #list do
        if list[i].recipeDbId == recipeId then return list[i] end
    end
    return nil
end

RegisterServerCallback("legalBuilder:getStations", function(source, callback)
    local map = stationMap()
    if type(callback) == "function" then
        pcall(callback, map)
    end
    return map
end)

RegisterServerCallback("legalBuilder:getStationRecipesForNUI", function(source, stationId)
    local id = tonumber(stationId)
    if not id then return {} end
    stationMap()

    local xPlayer = VFW.GetPlayerFromId(source)
    local station = stations[id]
    if not station or not canAccess(xPlayer, station) then return {} end

    local list = stationRecipes[id] or {}
    local out = {}
    for i = 1, #list do
        local slot = list[i]
        out[i] = {
            id = slot.id,
            recipeDbId = slot.recipeDbId,
            name = slot.name,
            label = slot.label,
            image = slot.image,
            item = slot.item,
            outputItem = slot.outputItem,
            outputCount = slot.outputCount,
            craftTime = slot.craftTime,
            isLegal = true,
            ingredients = slot.ingredients,
        }
    end
    return out
end)

pcall(RegisterServerCallback, "illegalBuilder:getRecipeIdByName", function(source, recipeName)
    if type(recipeName) ~= "string" or recipeName == "" then return nil end
    local row = MySQL.single.await("SELECT `id` FROM crafting_recipes WHERE `name` = ?", { recipeName })
    if not row then return nil end
    return row.id
end)

RegisterServerCallback("legalBuilder:prepareCraft", function(source, payload)
    local src = source
    if type(payload) ~= "table" then
        return { success = false, message = "Cette demande n'a pas pu être traitée" }
    end

    if not Feat27.RateLimit(src, "legal:prepareCraft", 500) then
        return { success = false, message = "Veuillez patienter" }
    end

    local xPlayer = VFW.GetPlayerFromId(src)
    if not xPlayer then return { success = false, message = "Joueur introuvable" } end

    stationMap()

    local stationId = tonumber(payload.stationId)
    local recipeId = tonumber(payload.recipeId)
    local quantity = math.floor(tonumber(payload.quantity) or 1)

    if not stationId or not recipeId then
        return { success = false, message = "Cette station ou cette recette n'est pas valide" }
    end
    if quantity < 1 then quantity = 1 end
    if quantity > MAX_QUANTITY then quantity = MAX_QUANTITY end

    local station = stations[stationId]
    if not station then return { success = false, message = "Station introuvable" } end
    if not canAccess(xPlayer, station) then return { success = false, message = "Accès refusé à cette station" } end
    if not isNearStation(src, station) then return { success = false, message = "Vous êtes trop loin de la station" } end

    local recipe = findRecipe(stationId, recipeId)
    if not recipe then return { success = false, message = "Recette indisponible sur cette station" } end

    local ingredients = normalizeIngredients(recipe.ingredients)
    for i = 1, #ingredients do
        local need = ingredients[i]
        if not Feat27.Inv.Has(xPlayer, need.item, need.count) then
            return { success = false, message = ("Il vous manque %s"):format(Feat27.Inv.Label(need.item)) }
        end
    end

    if not Feat27.Inv.CanCarry(xPlayer, recipe.outputItem, recipe.outputCount) then
        return { success = false, message = "Votre inventaire est plein" }
    end

    craftSessions[src] = {
        stationId = stationId,
        recipeId = recipeId,
        remaining = quantity,
        nextAt = 0,
        startedAt = GetGameTimer(),
    }

    return { success = true, totalCycles = quantity }
end)

RegisterNetEvent("legalBuilder:completeCraftCycle", function()
    local source = source
    local session = craftSessions[source]
    if not session then return end

    local now = GetGameTimer()
    if now < session.nextAt then return end
    session.nextAt = now + MIN_CYCLE_INTERVAL

    if session.remaining <= 0 then
        craftSessions[source] = nil
        return
    end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then
        craftSessions[source] = nil
        return
    end

    local station = stations[session.stationId]
    if not station or not canAccess(xPlayer, station) or not isNearStation(source, station) then
        craftSessions[source] = nil
        Feat27.NotifyError(source, "Fabrication interrompue.")
        return
    end

    local recipe = findRecipe(session.stationId, session.recipeId)
    if not recipe then
        craftSessions[source] = nil
        return
    end

    local ingredients = normalizeIngredients(recipe.ingredients)
    for i = 1, #ingredients do
        if not Feat27.Inv.Has(xPlayer, ingredients[i].item, ingredients[i].count) then
            craftSessions[source] = nil
            Feat27.NotifyError(source, "Ingrédients insuffisants.")
            return
        end
    end

    if not Feat27.Inv.CanCarry(xPlayer, recipe.outputItem, recipe.outputCount) then
        craftSessions[source] = nil
        Feat27.NotifyError(source, "Votre inventaire est plein.")
        return
    end

    for i = 1, #ingredients do
        Feat27.Inv.Take(xPlayer, ingredients[i].item, ingredients[i].count, false)
    end
    Feat27.Inv.Give(xPlayer, recipe.outputItem, recipe.outputCount, nil, true)

    session.remaining = session.remaining - 1
    if session.remaining <= 0 then
        craftSessions[source] = nil
    end
end)

RegisterNetEvent("legalBuilder:requestSync", function()
    local source = source
    if not Feat27.RateLimit(source, "legal:requestSync", 2000) then return end
    TriggerClientEvent("legalBuilder:syncStations", source, stationMap())
end)

AddEventHandler("vfw:playerDropped", function(source)
    craftSessions[source] = nil
end)

function Feat27.LegalStations()
    return stationMap()
end

function Feat27.RefreshLegalStations(broadcast)
    loadStations()
    if broadcast then
        TriggerClientEvent("legalBuilder:refreshStations", -1, stations)
    end
    return stations
end

function Feat27.CreateLegalStation(data)
    if type(data) ~= "table" then return nil end
    local id = MySQL.insert.await([[
        INSERT INTO legal_stations
            (name, coords_x, coords_y, coords_z, rotation_z, marker_x, marker_y, marker_z, prop_model,
             blip_enabled, blip_sprite, blip_color, blip_scale, blip_label, job_restriction, job_grade_min)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        tostring(data.name or "Station"),
        tonumber(data.coords_x) or 0.0, tonumber(data.coords_y) or 0.0, tonumber(data.coords_z) or 0.0,
        tonumber(data.rotation_z) or 0.0,
        tonumber(data.marker_x), tonumber(data.marker_y), tonumber(data.marker_z),
        data.prop_model,
        data.blip_enabled and 1 or 0,
        tonumber(data.blip_sprite), tonumber(data.blip_color), tonumber(data.blip_scale),
        data.blip_label,
        data.job_restriction or "",
        tonumber(data.job_grade_min) or 0,
    })
    if not id then return nil end

    local row = MySQL.single.await("SELECT * FROM legal_stations WHERE id = ?", { id })
    if not row then return nil end

    local station = buildStation(row)
    stations[station.id] = station
    TriggerClientEvent("legalBuilder:stationCreated", -1, station)
    return station
end

function Feat27.DeleteLegalStation(stationId)
    local id = tonumber(stationId)
    if not id then return false end
    MySQL.query.await("DELETE FROM legal_station_recipes WHERE station_id = ?", { id })
    MySQL.query.await("DELETE FROM legal_stations WHERE id = ?", { id })
    stations[id] = nil
    stationRecipes[id] = nil
    TriggerClientEvent("legalBuilder:stationDeleted", -1, id)
    return true
end

exports("getLegalStationsServer", function()
    return stationMap()
end)

CreateThread(function()
    while not VFW or not VFW.Ready do Wait(200) end
    Wait(500)
    local ok, err = pcall(loadStations)
    if not ok then
        console.warn(("fl_legal: chargement des stations impossible (%s)"):format(tostring(err)))
    else
        console.init("fl_legal", ("%d station(s) légale(s) chargée(s)"):format(#(MySQL.query.await("SELECT id FROM legal_stations") or {})))
    end
end)
