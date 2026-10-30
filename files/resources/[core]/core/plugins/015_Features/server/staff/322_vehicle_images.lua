-- Images des véhicules générées depuis Gestion > Images > Véhicules (« Générer les images ») : le client photographie chaque
-- modèle sur fond vert, la page NUI le détoure, l'image part sur FiveManage et son adresse est gardée ici, en base (table
-- vehicle_images) : elle survit aux mises à jour de la base, qui remplacent le dossier core.
-- Les joueurs reçoivent la table modèle -> adresse (VFW.VehicleImage côté client : concessionnaire, vente de véhicule).

local MAX_B64 = 1500000 -- ~1,1 Mo décodés : un webp 512² pèse 20-150 Ko
local FOLDER_CONVAR = "core_fivemanage_vehicles_path"

local images = {}   -- [model] = url
local loaded = false

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

local function cleanModel(value)
    if type(value) ~= "string" then return nil end
    value = value:lower()
    if not value:match("^[%w_%-]+$") or #value > 64 then return nil end
    return value
end

local function folder()
    local f = GetConvar(FOLDER_CONVAR, "")
    if f ~= "" then return f end
    return "vehicles"
end

local function broadcast(changes)
    TriggerClientEvent("core:vehicleImages:changed", -1, changes)
end

CreateThread(function()
    while not VFW.Ready do Wait(250) end
    local ok, err = pcall(MySQL.query.await, [[
        CREATE TABLE IF NOT EXISTS `vehicle_images` (
            `model` VARCHAR(64) NOT NULL,
            `url` VARCHAR(512) NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`model`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    if not ok then
        console.error("[images véhicules] table vehicle_images : " .. tostring(err))
        return
    end
    local okRows, rows = pcall(MySQL.query.await, "SELECT model, url FROM vehicle_images")
    if okRows and type(rows) == "table" then
        for i = 1, #rows do
            local model = cleanModel(rows[i].model)
            if model and type(rows[i].url) == "string" and rows[i].url ~= "" then images[model] = rows[i].url end
        end
    end
    loaded = true
    broadcast(images)
end)

VFW.VehicleImages = VFW.VehicleImages or {}

--- Adresse de l'image générée d'un modèle, ou nil.
function VFW.VehicleImages.Get(model)
    model = cleanModel(model)
    return model and images[model] or nil
end

--- Toutes les images générées : { [model] = url }.
function VFW.VehicleImages.All()
    local out = {}
    for model, url in pairs(images) do out[model] = url end
    return out
end

-- Ouvert à tous : les joueurs en ont besoin pour afficher les véhicules (concessionnaire, vente).
RegisterServerCallback("vfw:server:getVehicleImages", function()
    return VFW.VehicleImages.All()
end)

RegisterNetEvent("core:vehicleImages:saveCapture", function(payload)
    local src = source
    local function reply(ok, err, url)
        TriggerClientEvent("core:vehicleImages:saveResult", src, {
            id = type(payload) == "table" and payload.id or nil,
            ok = ok, error = err, url = url,
        })
    end

    if not staffOk(src) then return reply(false, "Permission refusée.") end
    if type(payload) ~= "table" or type(payload.id) ~= "string" then return reply(false, "Requête invalide.") end
    if not loaded then return reply(false, "Les images de véhicules ne sont pas encore chargées, réessaie dans un instant.") end
    if not (VFW.FiveManage and VFW.FiveManage.ApiKey and VFW.FiveManage.ApiKey()) then
        return reply(false, "Clé FiveManage absente : renseigne FIVEMANAGE_MEDIA_API_KEY dans server.cfg.")
    end

    local model = cleanModel(payload.model)
    if not model then return reply(false, "Modèle invalide.") end

    local b64 = payload.base64
    if type(b64) ~= "string" or b64 == "" then return reply(false, "Image absente.") end
    b64 = b64:gsub("^data:[^,]*,", "")
    if #b64 > MAX_B64 then return reply(false, "Image trop lourde.") end
    -- "UklGR" = "RIFF" en base64 : on n'uploade que du webp
    if b64:sub(1, 5) ~= "UklGR" then return reply(false, "Format inattendu (webp attendu).") end

    local url = VFW.FiveManage.UploadBase64("data:image/webp;base64," .. b64, model .. ".webp", folder())
    if not url then return reply(false, "Upload FiveManage échoué (voir la console serveur).") end

    local ok, err = pcall(MySQL.query.await, [[
        INSERT INTO vehicle_images (model, url) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE url = VALUES(url)
    ]], { model, url })
    if not ok then
        console.error("[images véhicules] enregistrement de " .. model .. " : " .. tostring(err))
        return reply(false, "Image envoyée mais pas enregistrée en base (voir la console serveur).")
    end

    images[model] = url
    broadcast({ [model] = url })
    reply(true, nil, url)
end)

-- Supprimer l'image générée d'un modèle (le modèle revient dans la liste des véhicules sans image).
RegisterServerCallback("vfw:server:deleteVehicleImage", function(source, model)
    if not staffOk(source) then return false end
    model = cleanModel(model)
    if not model or not images[model] then return false end
    local ok = pcall(MySQL.update.await, "DELETE FROM vehicle_images WHERE model = ?", { model })
    if not ok then return false end
    images[model] = nil
    broadcast({ [model] = false })
    return true
end)

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not (VFW.FiveManage and VFW.FiveManage.ApiKey and VFW.FiveManage.ApiKey()) then
        console.warn("[images véhicules] clé FiveManage absente (FIVEMANAGE_MEDIA_API_KEY) : la génération des images de véhicules est désactivée.")
    end
end)
