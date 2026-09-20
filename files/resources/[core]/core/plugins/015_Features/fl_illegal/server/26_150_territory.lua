Territories = Territories or {}

local Territory = {
    list = {},
    settings = {},
    factions = {},
}

local BUILDER_PERM = "territory_builder"

local function CanStaff(xPlayer)
    if not xPlayer then return false end
    return xPlayer.hasPermission(BUILDER_PERM) or xPlayer.hasPermission("gestion_territoires")
end
local DEFAULT_SETTINGS = {
    enabled = true,
    salesThreshold = 50,
    ownershipDurationHours = 72,
    ownerBonusPercent = 15,
    alertChancePercent = 10,
}

local function LoadSettings()
    Territory.settings = IL.LoadSettings("faction_territories_settings", DEFAULT_SETTINGS)
end

local function LoadTerritories()
    Territory.list = {}
    local rows = IL.Query("SELECT * FROM faction_territories ORDER BY id")
    for i = 1, #rows do
        local row = rows[i]
        Territory.list[#Territory.list + 1] = {
            id = row.id,
            name = row.name,
            polygon = IL.Decode(row.polygon, {}),
            display_number = row.display_number,
            display_color = row.display_color,
            owner = row.owner,
            owned_since = IL.Int(row.owned_since, 0),
            sales_count = IL.Int(row.sales_count, 0),
        }
    end
end

-- `faction_territories`.`owner` est un id numerique, mais les bandes vivent
-- dans `crews`, indexee par nom. `factions` (35_domaine.sql) porte cet id :
-- on la remet a jour depuis `crews` avant chaque lecture, sinon une bande
-- creee en jeu ne peut jamais posseder de territoire.
local function SyncFactionsFromCrews()
    IL.Execute([[
        INSERT IGNORE INTO factions (name, label, color)
        SELECT c.name, c.label, c.color FROM crews c
    ]])
    IL.Execute([[
        UPDATE factions f
        INNER JOIN crews c ON c.name = f.name
        SET f.label = c.label, f.color = c.color
    ]])
end

local function LoadFactions()
    Territory.factions = {}
    SyncFactionsFromCrews()
    local rows = IL.Query("SELECT * FROM factions")
    for i = 1, #rows do
        local row = rows[i]
        Territory.factions[#Territory.factions + 1] = {
            id = row.id,
            name = row.name,
            label = row.label or row.name,
            color = row.color,
        }
    end

    if #Territory.factions == 0 and VFW and VFW.Factions then
        local index = 0
        for name, faction in pairs(VFW.Factions) do
            index = index + 1
            Territory.factions[#Territory.factions + 1] = {
                id = (type(faction) == "table" and faction.id) or index,
                name = name,
                label = (type(faction) == "table" and faction.label) or name,
                color = type(faction) == "table" and faction.color or nil,
            }
        end
    end
end

local function FactionById(id)
    for i = 1, #Territory.factions do
        if Territory.factions[i].id == id then return Territory.factions[i] end
    end
    return nil
end

local function FactionByName(name)
    for i = 1, #Territory.factions do
        if Territory.factions[i].name == name then return Territory.factions[i] end
    end
    return nil
end

local function FindTerritory(territoryId)
    for i = 1, #Territory.list do
        if Territory.list[i].id == territoryId then return Territory.list[i], i end
    end
    return nil, nil
end

local function PointInPolygon(x, y, polygon)
    if not IL.IsTable(polygon) or #polygon < 3 then return false end
    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local pi = polygon[i]
        local pj = polygon[j]
        local xi, yi = IL.Num(pi.x, 0.0), IL.Num(pi.y, 0.0)
        local xj, yj = IL.Num(pj.x, 0.0), IL.Num(pj.y, 0.0)
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) ~= 0 and (yj - yi) or 0.0001) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function Refresh()
    LoadTerritories()
    TriggerClientEvent("core:factionTerritories:refresh", -1)
end

function Territories.GetAtCoords(coords, xPlayer)
    if not coords then return nil, 0 end
    for i = 1, #Territory.list do
        local territory = Territory.list[i]
        if PointInPolygon(coords.x, coords.y, territory.polygon) then
            local bonus = 0
            if xPlayer and territory.owner then
                local faction = FactionByName(IL.FactionName(xPlayer))
                if faction and faction.id == territory.owner then
                    bonus = IL.Num(Territory.settings.ownerBonusPercent, 0)
                end
            end
            return territory, bonus
        end
    end
    return nil, 0
end

function Territories.RegisterSale(territoryId, xPlayer)
    local territory = FindTerritory(territoryId)
    if not territory then return end

    territory.sales_count = territory.sales_count + 1
    IL.Execute("UPDATE faction_territories SET sales_count = sales_count + 1 WHERE id = ?", { territoryId })

    if not IL.Bool(Territory.settings.enabled) then return end

    local threshold = IL.Int(Territory.settings.salesThreshold, 50)
    if threshold <= 0 then return end

    local faction = FactionByName(IL.FactionName(xPlayer))
    if not faction then return end

    local duration = IL.Int(Territory.settings.ownershipDurationHours, 72) * 3600
    local now = IL.Now()
    local expired = territory.owned_since > 0 and (now - territory.owned_since) > duration

    if territory.owner == faction.id then
        if expired then
            territory.owned_since = now
            IL.Execute("UPDATE faction_territories SET owned_since = ? WHERE id = ?", { now, territoryId })
        end
        return
    end

    if territory.sales_count >= threshold or expired or not territory.owner then
        territory.owner = faction.id
        territory.owned_since = now
        territory.sales_count = 0
        IL.Execute("UPDATE faction_territories SET owner = ?, owned_since = ?, sales_count = 0 WHERE id = ?", {
            faction.id, now, territoryId,
        })
        TriggerClientEvent("core:factionTerritories:refresh", -1)
    end
end

IL.OnReady(function()
    LoadSettings()
    LoadTerritories()
    LoadFactions()
end)

IL.RegisterCallback("core:factionTerritories:getAll", function(source)
    return Territory.list
end)

IL.RegisterCallback("core:factionTerritories:getFactions", function(source)
    if #Territory.factions == 0 then LoadFactions() end
    return Territory.factions
end)

IL.RegisterCallback("core:factionTerritories:getSettings", function(source)
    return {
        enabled = IL.Bool(Territory.settings.enabled),
        salesThreshold = IL.Int(Territory.settings.salesThreshold, 50),
        ownershipDurationHours = IL.Int(Territory.settings.ownershipDurationHours, 72),
        ownerBonusPercent = IL.Num(Territory.settings.ownerBonusPercent, 15),
        alertChancePercent = IL.Num(Territory.settings.alertChancePercent, 10),
    }
end)

IL.RegisterCallback("core:factionTerritories:getAtPosition", function(source)
    local xPlayer = IL.Player(source)
    local coords = IL.Coords(source)
    if not coords then return nil end
    local territory = Territories.GetAtCoords(coords, xPlayer)
    return territory
end)

IL.RegisterCallback("core:factionTerritories:getMyTerritories", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return {} end

    local faction = FactionByName(IL.FactionName(xPlayer))
    if not faction then return {} end

    local out = {}
    for i = 1, #Territory.list do
        if Territory.list[i].owner == faction.id then
            out[#out + 1] = Territory.list[i]
        end
    end
    return out
end)

IL.RegisterCallback("core:factionTerritories:getMyFactionData", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return nil end

    local name = IL.FactionName(xPlayer)
    if name == "" then return nil end

    local faction = FactionByName(name)
    if not faction then
        return { id = 0, name = name, label = IL.FactionLabel(xPlayer), color = "#e53935" }
    end

    return {
        id = faction.id,
        name = faction.name,
        label = faction.label,
        color = faction.color or "#e53935",
    }
end)

RegisterNetEvent("core:factionTerritories:create", function(name, polygon, displayNumber, displayColor)
    local source = source
    local xPlayer = IL.Player(source)
    if not CanStaff(xPlayer) then return end

    name = IL.Str(name, nil)
    if not name or name == "" then return end
    if not IL.IsTable(polygon) or #polygon < 3 then return end

    local points = {}
    for i = 1, #polygon do
        local point = polygon[i]
        if IL.IsTable(point) and tonumber(point.x) and tonumber(point.y) then
            points[#points + 1] = { x = tonumber(point.x), y = tonumber(point.y) }
        end
    end
    if #points < 3 then return end

    local number = nil
    if displayNumber ~= nil and tonumber(displayNumber) then
        number = IL.Clamp(IL.Int(displayNumber, 0), 0, 999)
    end

    local color = nil
    if type(displayColor) == "string" and displayColor:match("^#%x%x%x%x%x%x$") then
        color = displayColor
    end

    IL.Insert("INSERT INTO faction_territories (name, polygon, display_number, display_color) VALUES (?, ?, ?, ?)", {
        name, IL.Encode(points), number, color,
    })

    Refresh()
end)

RegisterNetEvent("core:factionTerritories:delete", function(territoryId)
    local source = source
    local xPlayer = IL.Player(source)
    if not CanStaff(xPlayer) then return end

    local id = IL.Int(territoryId, nil)
    if not id then return end

    IL.Execute("DELETE FROM faction_territories WHERE id = ?", { id })
    Refresh()
end)

RegisterNetEvent("core:factionTerritories:update", function(territoryId, updateData)
    local source = source
    local xPlayer = IL.Player(source)
    if not CanStaff(xPlayer) then return end

    local id = IL.Int(territoryId, nil)
    if not id or not IL.IsTable(updateData) then return end

    if type(updateData.name) == "string" and updateData.name ~= "" then
        IL.Execute("UPDATE faction_territories SET name = ? WHERE id = ?", { updateData.name, id })
    end

    if updateData.display_number ~= nil then
        if updateData.display_number == false then
            IL.Execute("UPDATE faction_territories SET display_number = NULL WHERE id = ?", { id })
        elseif tonumber(updateData.display_number) then
            IL.Execute("UPDATE faction_territories SET display_number = ? WHERE id = ?", {
                IL.Clamp(IL.Int(updateData.display_number, 0), 0, 999), id,
            })
        end
    end

    if updateData.display_color ~= nil then
        if updateData.display_color == false then
            IL.Execute("UPDATE faction_territories SET display_color = NULL WHERE id = ?", { id })
        elseif type(updateData.display_color) == "string" and updateData.display_color:match("^#%x%x%x%x%x%x$") then
            IL.Execute("UPDATE faction_territories SET display_color = ? WHERE id = ?", { updateData.display_color, id })
        end
    end

    Refresh()
end)

RegisterNetEvent("core:factionTerritories:adminSetOwner", function(territoryId, owner)
    local source = source
    local xPlayer = IL.Player(source)
    if not CanStaff(xPlayer) then return end

    local id = IL.Int(territoryId, nil)
    if not id then return end

    local ownerId = nil
    if owner ~= nil and owner ~= false then
        ownerId = IL.Int(owner, nil)
        if ownerId and not FactionById(ownerId) then
            ownerId = nil
        end
    end

    IL.Execute("UPDATE faction_territories SET owner = ?, owned_since = ?, sales_count = 0 WHERE id = ?", {
        ownerId, ownerId and IL.Now() or 0, id,
    })

    Refresh()
end)

RegisterNetEvent("core:factionTerritories:saveSettings", function(settings)
    local source = source
    local xPlayer = IL.Player(source)
    if not CanStaff(xPlayer) then return end
    if not IL.IsTable(settings) then return end

    if settings.enabled ~= nil then
        IL.SaveSetting("faction_territories_settings", "enabled", IL.Bool(settings.enabled))
        Territory.settings.enabled = IL.Bool(settings.enabled)
    end

    local numeric = { "salesThreshold", "ownershipDurationHours", "ownerBonusPercent", "alertChancePercent" }
    for i = 1, #numeric do
        local key = numeric[i]
        if settings[key] ~= nil and tonumber(settings[key]) then
            local value = tonumber(settings[key])
            IL.SaveSetting("faction_territories_settings", key, value)
            Territory.settings[key] = value
        end
    end

    TriggerClientEvent("core:factionTerritories:refresh", -1)
end)

RegisterNetEvent("core:factionTerritories:reloadFactions", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not CanStaff(xPlayer) then return end
    LoadFactions()
    Refresh()
end)
