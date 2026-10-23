---@meta _
---@diagnostic disable: duplicate-doc-field

-- Téléphone du serveur : sd-phone (resources/[tel]/sd-phone). lb-phone n'est plus installé ;
-- sd-phone répond encore aux exports `lb-phone` (AddCustomApp, SendNotification...), ce qui
-- permet aux applications maison (LifeInvader, Weazel, Taxi) de continuer à s'y enregistrer.

--- Ressources téléphone connues, par ordre de préférence.
local PHONE_RESOURCES <const> = { "sd-phone", "lb-phone" }

--- Nom de la ressource téléphone démarrée, ou nil.
---@return string|nil
function VFW.PhoneResource()
    for i = 1, #PHONE_RESOURCES do
        if GetResourceState(PHONE_RESOURCES[i]) == "started" then
            return PHONE_RESOURCES[i]
        end
    end
    return nil
end

--- Vrai si `resourceName` est une ressource téléphone (démarrage ou arrêt à surveiller).
---@param resourceName string
---@return boolean
function VFW.IsPhoneResource(resourceName)
    for i = 1, #PHONE_RESOURCES do
        if PHONE_RESOURCES[i] == resourceName then return true end
    end
    return false
end

--- .ForceClosePhone
function VFW.ForceClosePhone()
    local phone = VFW.PhoneResource()
    if not phone then return end

    if phone == "sd-phone" then
        if exports["sd-phone"]:isOpen() then
            exports["sd-phone"]:close()
        end
        return
    end

    if exports["lb-phone"]:IsOpen() then
        exports["lb-phone"]:ToggleOpen(false)
    end
end

RegisterNetEvent("vfw:openTablet", function()
    VFW.CloseInventory()

    -- Pas de tablette dans sd-phone : le même téléphone s'ouvre en grand écran (pliable).
    if GetResourceState("lb-tablet") == "started" then
        exports["lb-tablet"]:ToggleOpen()
    elseif GetResourceState("sd-phone") == "started" then
        exports["sd-phone"]:open()
    end
end)

-- ---------------------------------------------------------------------------
-- Pont sd-phone (bridge/client de sd-phone) : une vue légère du joueur local.
-- ---------------------------------------------------------------------------

local function jobView(job)
    if type(job) ~= "table" then return nil end
    return {
        name = job.name,
        grade = tonumber(job.grade) or 0,
        isBoss = job.grade_is_boss == true,
        onDuty = job.onDuty == true,
    }
end

local NOTIFY_COLORS <const> = {
    error = "ROUGE",
    success = "VERT",
    warning = "ORANGE",
    warn = "ORANGE",
    inform = "BLEU",
    info = "BLEU",
}

--- Affiche une notification du serveur pour le compte du téléphone (toasts d'erreur, de succès...).
exports("PhoneClientNotify", function(message, kind)
    if type(message) ~= "string" or message == "" then return end
    VFW.ShowNotification({
        type = NOTIFY_COLORS[kind or "inform"] or "BLEU",
        content = message,
    })
end)

--- Nombre d'exemplaires de `name` dans l'inventaire du personnage local.
exports("PhoneClientItemCount", function(name)
    if type(name) ~= "string" then return 0 end

    local inventory = VFW.PlayerData and VFW.PlayerData.inventory
    if type(inventory) ~= "table" then return 0 end

    local total = 0
    for i = 1, #inventory do
        local entry = inventory[i]
        if entry.name == name then total = total + (tonumber(entry.count) or 0) end
    end
    return total
end)

--- Libellé d'un item du catalogue, ou nil.
exports("PhoneClientItemLabel", function(name)
    local def = type(VFW.Items) == "table" and VFW.Items[name]
    return def and def.label or nil
end)

--- URL de l'icône d'un item (CDN du serveur).
exports("PhoneClientItemImage", function(name)
    if type(name) ~= "string" or name == "" then return nil end
    local def = type(VFW.Items) == "table" and VFW.Items[name]
    local path = def and type(def.image) == "string" and def.image ~= "" and def.image
        or ("items/%s.webp"):format(name)
    return VFW.CdnUrl(path)
end)

--- Données minimales du personnage local, ou nil avant son chargement.
exports("PhoneClientPlayer", function()
    if not VFW.PlayerLoaded then return nil end

    local data = VFW.PlayerData or {}
    return {
        identifier = data.identifier,
        job = jobView(data.job),
        job2 = jobView(data.job2),
        metadata = data.metadata or {},
        dead = data.dead == true,
    }
end)
