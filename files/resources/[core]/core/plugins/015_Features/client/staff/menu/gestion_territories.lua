---@meta _
---@diagnostic disable: duplicate-doc-field

-- Panneau natif "Territoires factions" du hub Gestion.

local function Guard()
    if not (StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen()) then return false end
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    return perms["gestion_territoires"] == true or perms["territory_builder"] == true
end

local function CirclePolygon(cx, cy, radius, steps)
    local poly = {}
    local n = steps or 16
    for i = 0, n - 1 do
        local a = (i / n) * math.pi * 2
        poly[#poly + 1] = { x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius }
    end
    return poly
end

local function CopyPoly(raw)
    local poly = {}
    if type(raw) ~= "table" then return poly end
    for i = 1, #raw do
        local p = raw[i]
        if type(p) == "table" then
            poly[#poly + 1] = { x = tonumber(p.x) or 0.0, y = tonumber(p.y) or 0.0 }
        end
    end
    return poly
end

local function FactionOf(factions, owner)
    if owner == nil then return nil end
    local id = tonumber(owner)
    for i = 1, #(factions or {}) do
        local f = factions[i]
        if f and (tonumber(f.id) == id or f.name == owner) then
            return f
        end
    end
    return nil
end

local function Payload()
    local territories = TriggerServerCallback("core:factionTerritories:getAll") or {}
    local factions = TriggerServerCallback("core:factionTerritories:getFactions") or {}
    local settings = TriggerServerCallback("core:factionTerritories:getSettings") or {}
    local coords = GetEntityCoords(PlayerPedId())
    local list = {}
    for i = 1, #territories do
        local t = territories[i]
        local faction = FactionOf(factions, t.owner)
        local color = t.display_color
        if type(color) ~= "string" or color == "" then
            color = (faction and faction.color) or "#7263EE"
        end
        list[#list + 1] = {
            id = t.id,
            name = t.name,
            polygon = CopyPoly(t.polygon),
            display_number = t.display_number,
            display_color = t.display_color,
            color = color,
            owner = t.owner,
            ownerLabel = faction and (faction.label or faction.name) or "Neutre",
            owned_since = t.owned_since or 0,
            sales_count = t.sales_count or 0,
            active = true,
        }
    end
    return {
        ok = true,
        territories = list,
        factions = factions,
        settings = {
            enabled = settings.enabled == true,
            salesThreshold = tonumber(settings.salesThreshold) or 50,
            ownershipDurationHours = tonumber(settings.ownershipDurationHours) or 72,
            ownerBonusPercent = tonumber(settings.ownerBonusPercent) or 15,
            alertChancePercent = tonumber(settings.alertChancePercent) or 10,
        },
        player = { x = coords.x + 0.0, y = coords.y + 0.0 },
    }
end

local function AfterMutation()
    Wait(450)
    return Payload()
end

local function CleanName(value)
    if type(value) ~= "string" then return "" end
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function ParseNumber(value)
    if value == nil or value == "" or value == false then return false end
    local n = tonumber(value)
    if not n then return nil end
    n = math.floor(n)
    if n < 0 or n > 999 then return nil end
    return n
end

local function ParseColor(value)
    if value == nil or value == "" or value == false then return false end
    if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then return value end
    return nil
end

RegisterNuiCallback("gestion:territories:open", function(_, cb)
    if not Guard() then
        cb({ ok = false, error = "Vous n'avez pas la permission de gérer les territoires." })
        return
    end
    cb(Payload())
end)

RegisterNuiCallback("gestion:territories:refresh", function(_, cb)
    if not Guard() then cb({ ok = false }) return end
    cb(Payload())
end)

RegisterNuiCallback("gestion:territories:create", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" then cb({ ok = false, error = "Données invalides." }) return end
    local name = CleanName(data.name)
    if name == "" then
        cb({ ok = false, error = "Indique un nom de territoire." })
        return
    end
    local polygon = data.polygon
    if type(polygon) ~= "table" or #polygon < 3 then
        local radius = tonumber(data.radius)
        if not radius or radius < 20 or radius > 2500 then
            cb({ ok = false, error = "Dessine un polygone (3 points) ou indique un rayon entre 20 et 2500 m." })
            return
        end
        local coords = GetEntityCoords(PlayerPedId())
        polygon = CirclePolygon(coords.x, coords.y, radius, 16)
    end
    local displayNumber = ParseNumber(data.displayNumber)
    if displayNumber == nil then
        cb({ ok = false, error = "Le numéro d'affichage doit être entre 0 et 999." })
        return
    end
    local displayColor = ParseColor(data.displayColor)
    if displayColor == nil then
        cb({ ok = false, error = "Couleur invalide (format #RRGGBB)." })
        return
    end
    if displayNumber == false then displayNumber = nil end
    if displayColor == false then displayColor = nil end
    TriggerServerEvent("core:factionTerritories:create", name, CopyPoly(polygon), displayNumber, displayColor)
    cb(AfterMutation())
end)

RegisterNuiCallback("gestion:territories:update", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" or data.territoryId == nil then
        cb({ ok = false, error = "Territoire invalide." })
        return
    end
    local updateData = {}
    local name = CleanName(data.name)
    if name ~= "" then updateData.name = name end
    if data.displayNumber ~= nil then
        local n = ParseNumber(data.displayNumber)
        if n == nil then
            cb({ ok = false, error = "Le numéro d'affichage doit être entre 0 et 999." })
            return
        end
        updateData.display_number = n
    end
    if data.displayColor ~= nil then
        local c = ParseColor(data.displayColor)
        if c == nil then
            cb({ ok = false, error = "Couleur invalide (format #RRGGBB)." })
            return
        end
        updateData.display_color = c
    end
    if next(updateData) then
        TriggerServerEvent("core:factionTerritories:update", data.territoryId, updateData)
    end
    if data.owner ~= nil then
        local owner = data.owner
        if owner == "" or owner == false then owner = false end
        TriggerServerEvent("core:factionTerritories:adminSetOwner", data.territoryId, owner)
    end
    cb(AfterMutation())
end)

RegisterNuiCallback("gestion:territories:delete", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if not data or data.territoryId == nil then
        cb({ ok = false, error = "Territoire invalide." })
        return
    end
    TriggerServerEvent("core:factionTerritories:delete", data.territoryId)
    cb(AfterMutation())
end)

RegisterNuiCallback("gestion:territories:teleport", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = Payload()
    local id = data and tonumber(data.territoryId)
    for i = 1, #payload.territories do
        local t = payload.territories[i]
        if tonumber(t.id) == id and t.polygon and #t.polygon >= 3 then
            local sumX, sumY = 0.0, 0.0
            for n = 1, #t.polygon do
                sumX = sumX + t.polygon[n].x
                sumY = sumY + t.polygon[n].y
            end
            local cx, cy = sumX / #t.polygon, sumY / #t.polygon
            local found, groundZ = GetGroundZFor_3dCoord(cx, cy, 1000.0, false)
            if not found then groundZ = 50.0 end
            SetEntityCoords(PlayerPedId(), cx, cy, groundZ + 1.0, false, false, false, false)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Territoires',
                message = "Téléporté au centre de " .. tostring(t.name) .. ".",
            })
            payload.player = { x = cx, y = cy }
            cb(payload)
            return
        end
    end
    cb({ ok = false, error = "Territoire introuvable." })
end)

RegisterNuiCallback("gestion:territories:gps", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    local payload = Payload()
    local id = data and tonumber(data.territoryId)
    for i = 1, #payload.territories do
        local t = payload.territories[i]
        if tonumber(t.id) == id and t.polygon and #t.polygon >= 3 then
            local sumX, sumY = 0.0, 0.0
            for n = 1, #t.polygon do
                sumX = sumX + t.polygon[n].x
                sumY = sumY + t.polygon[n].y
            end
            SetNewWaypoint(sumX / #t.polygon, sumY / #t.polygon)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Territoires',
                message = "GPS défini vers " .. tostring(t.name) .. ".",
            })
            cb({ ok = true })
            return
        end
    end
    cb({ ok = false, error = "Territoire introuvable." })
end)

RegisterNuiCallback("gestion:territories:saveSettings", function(data, cb)
    if not Guard() then cb({ ok = false }) return end
    if type(data) ~= "table" then cb({ ok = false, error = "Données invalides." }) return end
    TriggerServerEvent("core:factionTerritories:saveSettings", {
        enabled = data.enabled == true,
        salesThreshold = tonumber(data.salesThreshold),
        ownershipDurationHours = tonumber(data.ownershipDurationHours),
        ownerBonusPercent = tonumber(data.ownerBonusPercent),
        alertChancePercent = tonumber(data.alertChancePercent),
    })
    local payload = AfterMutation()
    payload.message = "Paramètres enregistrés."
    cb(payload)
end)
