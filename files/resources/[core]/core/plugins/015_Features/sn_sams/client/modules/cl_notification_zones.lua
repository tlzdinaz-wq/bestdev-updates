-- ============================================================
-- Module: Zones de notification personnelles SAMS
-- Permet aux agents de muter les notifications dans certaines zones
-- Stockage KVP client (donnees personnelles)
-- ============================================================

local KVP_KEY = "sams_mute_zones"
local MAX_ZONES = 10

SN_SAMS.MuteZones = {}

-- ============================================================
-- Persistence KVP
-- ============================================================

--- Charge les zones depuis le KVP
local function loadZones()
    local raw = GetResourceKvpString(KVP_KEY)
    if raw and raw ~= "" then
        local decoded = json.decode(raw)
        if type(decoded) == "table" then
            SN_SAMS.MuteZones = decoded
        end
    end
end

--- Sauvegarde les zones dans le KVP
local function saveZones()
    SetResourceKvp(KVP_KEY, json.encode(SN_SAMS.MuteZones))
end

-- Charger au demarrage
loadZones()

-- ============================================================
-- Fonction de test: coordonnees dans une zone mutee?
-- ============================================================

--- Verifie si des coordonnees se trouvent dans une zone mutee
--- Si chevauchement entre zone mutee et zone active, la zone active a priorite
---@param coords table {x, y, z}
---@return boolean
function SN_SAMS.IsInMutedZone(coords)
    if not coords or not coords.x or not coords.y then return false end

    local inMuted = false

    for _, zone in ipairs(SN_SAMS.MuteZones) do
        local dx = coords.x - zone.x
        local dy = coords.y - zone.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= zone.radius then
            if not zone.muted then
                return false -- zone active = priorite, on envoie la notif
            end
            inMuted = true
        end
    end

    return inMuted
end

-- ============================================================
-- NUI Callbacks (communication avec le MDT React)
-- ============================================================

--- Le MDT envoie les zones mises a jour
RegisterNUICallback("nui:sams:saveZones", function(data, cb)
    if type(data) == "table" and type(data.zones) == "table" then
        -- Limiter a MAX_ZONES
        local zones = {}
        for i = 1, math.min(#data.zones, MAX_ZONES) do
            local z = data.zones[i]
            if z.id and z.name and z.x and z.y and z.radius then
                zones[#zones + 1] = {
                    id = tostring(z.id),
                    name = tostring(z.name),
                    x = tonumber(z.x) or 0,
                    y = tonumber(z.y) or 0,
                    radius = tonumber(z.radius) or 500,
                    muted = z.muted == true,
                }
            end
        end
        SN_SAMS.MuteZones = zones
        saveZones()
    end
    cb("ok")
end)

--- Le MDT demande les zones actuelles
RegisterNUICallback("nui:sams:getZones", function(_, cb)
    cb(SN_SAMS.MuteZones or {})
end)

-- ============================================================
-- Menu F4: Toggle rapide des zones mutees
-- ============================================================

local JobMenuRegistry = exports.core:getJobMenuRegistry()
local samsJobs = { "sams_pib", "sams_pab" }

local zonesSubMenu = JobMenuRegistry.createSubMenu(samsJobs, "sams_zones", "Zones de notification")

zonesSubMenu.OnOpen(function()
    if #SN_SAMS.MuteZones == 0 then
        zonesSubMenu.Button("Aucune zone", "Créez des zones dans le MDT", nil)
        return
    end

    for i, zone in ipairs(SN_SAMS.MuteZones) do
        local statusText = zone.muted and "Mutée" or "Active"
        zonesSubMenu.Checkbox(
            zone.name,
            statusText .. " (rayon: " .. math.floor(zone.radius) .. "m)",
            false,
            zone.muted,
            function(checked)
                SN_SAMS.MuteZones[i].muted = checked
                saveZones()
                zonesSubMenu.refresh()
            end
        )
    end
end)

JobMenuRegistry.register(samsJobs, function(menu, subMenus)
    menu.Button("Zones de notification", "Muter/démuter les alertes par zone", nil, "chevron", false, function()
    end, subMenus["sams_zones"])
end, 60)
