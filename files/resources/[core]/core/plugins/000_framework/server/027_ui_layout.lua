---@meta _
---@diagnostic disable: duplicate-doc-field

-- Orientation globale HUD / menu / notifications.
-- Fichier : config/ui_layout.json (survit aux reboots).

VFW.UiLayout = VFW.UiLayout or {}

local JSON_FILE = "config/ui_layout.json"
local KEYS = { "hud", "menu", "notif" }
local POS_KEYS = { "minimap", "status", "health", "speedo", "logo", "vui", "notif" }
local cache = nil

local function norm(value, fallback)
    if value == "horizontal" or value == "vertical" then
        return value
    end
    return fallback or "vertical"
end

local function defaults()
    return {
        hud = "vertical",
        menu = "vertical",
        notif = "vertical",
    }
end

local function sanitizeBox(src)
    if type(src) ~= "table" then return nil end
    local x = tonumber(src.x)
    local y = tonumber(src.y)
    if not x or not y then return nil end
    return {
        x = x,
        y = y,
        w = tonumber(src.w) or 15.0,
        h = tonumber(src.h) or 12.0,
    }
end

local function sanitizePositions(data)
    if type(data) ~= "table" then return nil end
    local out = {}
    local any = false
    for i = 1, #POS_KEYS do
        local key = POS_KEYS[i]
        local box = sanitizeBox(data[key])
        if box then
            out[key] = box
            any = true
        end
    end
    if not any then return nil end
    if data.custom == true then
        out.custom = true
    end
    return out
end

local function playerOverride(data)
    local positions = sanitizePositions(data)
    if not positions or positions.custom ~= true then
        return nil
    end
    return positions
end

local function sanitize(data)
    local out = defaults()
    if type(data) ~= "table" then
        return out
    end
    for i = 1, #KEYS do
        local key = KEYS[i]
        out[key] = norm(data[key], out[key])
    end
    out.positions = sanitizePositions(data.positions)
    return out
end

local function encode(data)
    return json.encode(sanitize(data))
end

local function loadFile()
    if cache then
        return cache
    end
    local raw = LoadResourceFile(GetCurrentResourceName(), JSON_FILE)
    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            cache = sanitize(decoded)
            return cache
        end
    end
    cache = defaults()
    return cache
end

local function saveFile(data)
    local body = encode(data)
    local ok = SaveResourceFile(GetCurrentResourceName(), JSON_FILE, body, -1)
    if not ok then
        return false
    end
    cache = sanitize(data)
    return true
end

function VFW.UiLayout.Get()
    return sanitize(loadFile())
end

function VFW.UiLayout.Set(data)
    local current = loadFile()
    if type(data) ~= "table" then
        data = {}
    end
    if data.positions == nil then
        data.positions = current.positions
    end
    if not saveFile(data) then
        return false, "Impossible d'écrire config/ui_layout.json."
    end
    TriggerClientEvent("core:ui:orientation", -1, cache)
    return true
end

function VFW.UiLayout.GetPositions()
    local data = VFW.UiLayout.Get()
    return data.positions
end

function VFW.UiLayout.SetPositions(positions)
    local current = loadFile()
    current.positions = sanitizePositions(positions)
    if not saveFile(current) then
        return false, "Impossible d'écrire config/ui_layout.json."
    end
    TriggerClientEvent("core:ui:positions", -1, cache.positions)
    return true
end

RegisterServerCallback("uiLayout:get", function(_source)
    return VFW.UiLayout.Get()
end)

local function playerLayout(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.getMeta then return nil end
    return playerOverride(xPlayer.getMeta("hudLayout"))
end

local function persistMetadata(xPlayer)
    if not xPlayer or not xPlayer.identifier then return false end
    local encoded = VFW.DB and VFW.DB.Encode and VFW.DB.Encode(xPlayer.metadata) or json.encode(xPlayer.metadata or {})
    local ok = pcall(function()
        MySQL.update.await("UPDATE characters SET metadata = ? WHERE identifier = ?", {
            encoded,
            xPlayer.identifier,
        })
    end)
    if not ok and VFW.DB and VFW.DB.SaveCharacter then
        pcall(VFW.DB.SaveCharacter, xPlayer)
    end
    return ok
end

RegisterServerCallback("hudLayout:getMine", function(source)
    return playerLayout(source)
end)

RegisterServerCallback("hudLayout:saveMine", function(source, data)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.setMeta then
        return { ok = false, error = "Joueur introuvable." }
    end
    if type(data) == "string" then
        local ok, decoded = pcall(json.decode, data)
        data = ok and decoded or nil
    end
    local positions = sanitizePositions((type(data) == "table" and (data.layout or data)) or nil)
    if not positions then
        return { ok = false, error = "Données invalides." }
    end
    positions.custom = true
    xPlayer.setMeta("hudLayout", positions)
    persistMetadata(xPlayer)
    return { ok = true }
end)

RegisterServerCallback("hudLayout:clearMine", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.setMeta then
        return { ok = false, error = "Joueur introuvable." }
    end
    xPlayer.setMeta("hudLayout", nil)
    persistMetadata(xPlayer)
    return { ok = true }
end)

local function resolveSource(src, xPlayer)
    if type(src) == "number" then return src end
    return xPlayer and xPlayer.source
end

local function pushServerPositions(src)
    if type(src) ~= "number" then return end
    local positions = VFW.UiLayout.GetPositions()
    if type(positions) == "table" then
        TriggerClientEvent("core:ui:positions", src, positions)
    end
end

local function pushPersonal(src, xPlayer)
    src = resolveSource(src, xPlayer)
    if type(src) ~= "number" then return end
    pushServerPositions(src)
    local saved = xPlayer and xPlayer.getMeta and playerOverride(xPlayer.getMeta("hudLayout")) or nil
    if saved then
        TriggerClientEvent("core:hudlayout:personal", src, saved)
    end
end

AddEventHandler("vfw:characterLoaded", function(source, xPlayer)
    pushPersonal(source, xPlayer)
end)

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    pushPersonal(source, xPlayer)
end)

AddEventHandler("onResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    loadFile()
    CreateThread(function()
        Wait(1500)
        local positions = VFW.UiLayout.GetPositions()
        if type(positions) == "table" then
            TriggerClientEvent("core:ui:positions", -1, positions)
        end
    end)
end)

