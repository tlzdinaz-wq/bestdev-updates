---@meta _
---@diagnostic disable: duplicate-doc-field

-- ═══════════════════════════════════════════════════════════════
-- Images de vêtements (green screen) — stockées sur FiveManage.
--   * Le hub Gestion → Images → Vêtements → « Générer les images »
--     envoie chaque image détourée (webp base64) : elle est uploadée sur
--     FiveManage (clé FIVEMANAGE_MEDIA_API_KEY / fivemanage:key /
--     core_fivemanage_media_key, dossier core_fivemanage_outfits_path) et
--     son URL est mémorisée dans interface/brand/outfits_greenscreener/manifest.json :
--         { male = { clothing = { shoes = { ["12.webp"] = "https://…" } } } }
--   * vfw:server:getOutfitImages (tout joueur) : table des URLs, lue par
--     VFW.OutfitImage côté client (boutiques, créateur de personnage).
--   * vfw:server:getOutfitsManifest (staff) : même table, pour repérer
--     les vêtements sans image dans le hub.
-- ═══════════════════════════════════════════════════════════════

local MANIFEST_FILE = "interface/brand/outfits_greenscreener/manifest.json"
local MAX_B64 = 1500000 -- ~1,1 Mo décodés : un webp 512² pèse 20-150 Ko

local SEXES = { male = true, female = true }
local FOLDERS = {
    clothing = { torso2 = true, leg = true, shoes = true, mask = true, accessory = true, undershirt = true, torso = true, bags = true, armor = true, decals = true },
    props    = { hat = true, glasses = true, ear = true, watch = true, bracelet = true },
}

local manifest = nil
local broadcastTimer = nil

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("dev")
        or xPlayer.hasPermission("gestion_items")
        or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin")
        or xPlayer.hasPermission("server_management") then
        return xPlayer
    end
    return nil
end

local VARIABLE <const> = "outfit_images_manifest"

--- La liste des images de tenues est doublee en base de donnees.
---
--- Elle ne vivait que dans ce fichier, a l interieur de la ressource. Un client qui
--- remplace le dossier `core` pour se mettre a jour perdait toutes les images deja
--- generees : il fallait tout refaire, piece par piece.
---
--- Le fichier reste ce qu'on lit ; la base n'en est que la copie de secours.
local function mirrorToDatabase(data)
    if not VFW.Variables or not VFW.Variables.SetVariable then return end
    pcall(VFW.Variables.SetVariable, VARIABLE, data)
end

---@return table|nil liste, boolean consultee
local function readFromDatabase()
    if not VFW.Variables or not VFW.Variables.GetVariable then return nil, false end

    local ok, stored = pcall(VFW.Variables.GetVariable, VARIABLE)
    if not ok then return nil, false end
    if type(stored) ~= "table" or not next(stored) then return nil, true end
    return stored, true
end

local function loadManifest()
    if manifest then return manifest end
    manifest = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), MANIFEST_FILE)
    if type(raw) == "string" and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            for sex, kinds in pairs(decoded) do
                if SEXES[sex] and type(kinds) == "table" then
                    for kind, folders in pairs(kinds) do
                        if FOLDERS[kind] and type(folders) == "table" then
                            for folder, files in pairs(folders) do
                                if type(files) == "table" then
                                    for filename, url in pairs(files) do
                                        if type(filename) == "string" and type(url) == "string" and url:match("^https://") then
                                            manifest[sex] = manifest[sex] or {}
                                            manifest[sex][kind] = manifest[sex][kind] or {}
                                            manifest[sex][kind][folder] = manifest[sex][kind][folder] or {}
                                            manifest[sex][kind][folder][filename] = url
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            console.warn("[outfits] manifest.json illisible, liste repartie de zéro.")
        end
    end

    -- Fichier absent : la copie en base prend le relais. Le fichier sera reecrit au
    -- prochain enregistrement.
    if not next(manifest) then
        local stored, consulted = readFromDatabase()
        if stored then
            manifest = stored
            console.warn("[outfits] manifest.json manquant : liste restauree depuis la base.")
        elseif not consulted then
            -- Base pas encore joignable : ne rien retenir, sinon cette liste vide
            -- tiendrait lieu de verite pour toute la duree du serveur.
            local empty = manifest
            manifest = nil
            return empty
        end
    end

    return manifest
end

local function saveManifest()
    local data = loadManifest()
    local ok = SaveResourceFile(GetCurrentResourceName(), MANIFEST_FILE, json.encode(data), -1)
    if not ok then console.error("[outfits] écriture de " .. MANIFEST_FILE .. " refusée.") end

    mirrorToDatabase(data)
    return ok
end

local function manifestSet(sex, kind, folder, filename, url)
    local m = loadManifest()
    m[sex] = m[sex] or {}
    m[sex][kind] = m[sex][kind] or {}
    m[sex][kind][folder] = m[sex][kind][folder] or {}
    m[sex][kind][folder][filename] = url
end

-- Les clients invalident leur cache d'URLs (regroupé : un seul event par salve d'uploads).
local function scheduleBroadcast()
    if broadcastTimer then return end
    broadcastTimer = true
    SetTimeout(4000, function()
        broadcastTimer = nil
        TriggerClientEvent("core:outfits:changed", -1)
    end)
end

local function outfitsFolder(sex, kind, folder)
    local root = GetConvar("core_fivemanage_outfits_path", "")
    if root == "" then
        local base = GetConvar("core_fivemanage_path", "")
        root = base ~= "" and (base:gsub("^/+", ""):gsub("/+$", "") .. "/outfits") or "outfits"
    end
    root = root:gsub("^/+", ""):gsub("/+$", "")
    return ("%s/%s/%s/%s"):format(root, sex, kind, folder)
end

Staff29.Cb("vfw:server:getOutfitsManifest", function(source)
    if not staffOk(source) then return {} end
    return loadManifest()
end)

RegisterServerCallback("vfw:server:getOutfitImages", function(source)
    if not VFW.GetPlayerFromId(source) then return {} end
    return loadManifest()
end)

RegisterNetEvent("core:outfits:saveCapture", function(payload)
    local src = source
    local function reply(ok, err, url)
        TriggerClientEvent("core:outfits:saveResult", src, {
            id = type(payload) == "table" and payload.id or nil,
            ok = ok, error = err, url = url,
        })
    end

    if not staffOk(src) then return reply(false, "Permission refusée.") end
    if type(payload) ~= "table" or type(payload.id) ~= "string" then return reply(false, "Requête invalide.") end
    if not (VFW.FiveManage and VFW.FiveManage.ApiKey and VFW.FiveManage.ApiKey()) then
        return reply(false, "Clé FiveManage absente : renseigne FIVEMANAGE_MEDIA_API_KEY dans server.cfg.")
    end

    local sex, kind, folder = payload.sex, payload.kind, payload.folder
    local d, t = math.tointeger(tonumber(payload.drawable) or -1), math.tointeger(tonumber(payload.texture) or -1)
    if not SEXES[sex] or not FOLDERS[kind] or not FOLDERS[kind][folder] then return reply(false, "Catégorie invalide.") end
    if not d or not t or d < 0 or t < 0 or d > 5000 or t > 64 then return reply(false, "Drawable / texture invalide.") end

    local b64 = payload.base64
    if type(b64) ~= "string" or b64 == "" then return reply(false, "Image absente.") end
    b64 = b64:gsub("^data:[^,]*,", "")
    if #b64 > MAX_B64 then return reply(false, "Image trop lourde.") end
    -- "UklGR" = "RIFF" en base64 : on n'uploade que du webp
    if b64:sub(1, 5) ~= "UklGR" then return reply(false, "Format inattendu (webp attendu).") end

    local filename = t == 0 and (d .. ".webp") or (d .. "_" .. t .. ".webp")
    local url = VFW.FiveManage.UploadBase64("data:image/webp;base64," .. b64, filename, outfitsFolder(sex, kind, folder))
    if not url then
        return reply(false, "Upload FiveManage échoué (voir la console serveur).")
    end

    manifestSet(sex, kind, folder, filename, url)
    saveManifest()
    scheduleBroadcast()
    reply(true, nil, url)
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not (VFW.FiveManage and VFW.FiveManage.ApiKey and VFW.FiveManage.ApiKey()) then
        console.warn("[outfits] clé FiveManage absente (FIVEMANAGE_MEDIA_API_KEY) : la génération des images de vêtements est désactivée.")
    end
end)
