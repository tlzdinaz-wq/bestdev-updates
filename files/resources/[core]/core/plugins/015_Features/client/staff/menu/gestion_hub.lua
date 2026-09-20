---@meta _
---@diagnostic disable: duplicate-doc-field

-- Hub de gestion (NUI) : remplace la navigation VUI "GESTION DE GLOBAL" > "BUILDERS"
-- par une grille de catégories. Un clic sur une catégorie ouvre un sous-menu de tuiles
-- dans le hub (comme les builders). Un outil VUI s'ouvre DANS le hub (VUI.OpenInHub) :
-- le NUI VUI n'est pas affiché, les messages sont relayés via "vui:hub:message".
--
-- Les groupes de builders sont générés depuis StaffMenu.builderEntries
-- (buildersMenu.lua) : un séparateur = une catégorie, les boutons qui suivent = ses outils.

--- Une fonction reçue d'une autre ressource (ex. `menu.open` créé par l'export VUI
--- CreateSubMenu) n'est pas de type "function" mais une table appelable (funcref).
---@param f any
---@return boolean
local function IsCallable(f)
    if type(f) == "function" then return true end
    if type(f) == "table" then
        local mt = getmetatable(f)
        return mt ~= nil and mt.__call ~= nil
    end
    return false
end

-- Appel avec `:` obligatoire : le proxy d'exports FiveM est `function(self, ...)`,
-- un appel avec `.` décale les arguments (openFn devient self).
local function OpenVuiInHub(openFn, returnFn)
    if not IsCallable(openFn) then return end
    exports["VUI"]:OpenInHub(openFn, returnFn)
end

local hubOpen = false
local hubMinimized = false
local hubData = nil

local function HasPerm(perms, need)
    if VFW.HasStaffPerm then
        if not need then return true end
        if type(need) == "string" then return VFW.HasStaffPerm(need) end
        if type(need) == "table" then
            for i = 1, #need do
                if VFW.HasStaffPerm(need[i]) then return true end
            end
            return false
        end
    end
    local role = VFW.PlayerGlobalData and VFW.PlayerGlobalData.role
    if role == "niveau_6" then return true end
    if not need then return true end
    if type(need) == "string" then return perms[need] == true end
    if type(need) == "table" then
        for i = 1, #need do
            if perms[need[i]] then return true end
        end
    end
    return false
end

-- Catégories du hub (sous-menus en tuiles, comme les builders).
-- items.submenu = clé StaffMenu ; items.action = action Lua locale ; items.perm = permission extra.
local directCategories = {
    {
        id = "permissions", label = "PERMISSIONS", icon = "lock", perm = "gestion_perm",
        items = {
            { label = "Rôles staff", desc = "Créer, modifier et attribuer les rôles et permissions", icon = "lock", action = "roles_panel", opens = "roles" },
        },
    },
    {
        id = "serveur", label = "SERVEUR", icon = "settings", perm = { "server_management", "dev" },
        items = {
            { label = "Configuration serveur", desc = "Nom, Discord, et une couleur qui change toute la charte", icon = "palette", opens = "branding" },
            { label = "Loading screen", desc = "Vidéo ou image de fond, musique d’attente — visible à la connexion", icon = "film", opens = "loadingscreen" },
            { label = "Positions des interfaces", desc = "Déplacer HUD, menus et minimap pour tous les joueurs (comme F5)", icon = "settings", action = "hud_layout_server" },
            { label = "Tablette météo", desc = "Zones météo autour de toi ou sur la carte", icon = "globe", perm = "server_management", action = "weather_tablet", opens = "weather" },
            { label = "Météo, heure et stats", desc = "Heure, gel du temps, statistiques serveur", icon = "clock", perm = "server_management", action = "server_panel", opens = "server" },
            { label = "Nettoyer la zone", desc = "Supprimer véhicules, peds et objets autour de vous", icon = "trash", perm = "clean_zone", action = "clear_zone" },
            { label = "Gérer les images", desc = "Logo, bannière, pause, items, sociétés, mugshots", icon = "image", opens = "images" },
            { label = "Notifications périodiques", desc = "Notifications automatiques", icon = "megaphone", opens = "notifs" },
            { label = "Starter pack", desc = "Argent et items de départ des nouveaux joueurs", icon = "gift", opens = "dev", dev = "starterpack" },
            { label = "Staff logs", desc = "Logs envoyés et file d'attente", icon = "report", perm = "staff_logs", opens = "dev", dev = "stafflogs" },
            { label = "Webhooks logs", desc = "Webhooks Discord par type de log", icon = "report", opens = "dev", dev = "webhooks" },
            { label = "Gestion téléphone", desc = "Messages, mails, posts, certifications d'un numéro", icon = "chat", perm = "wipe", opens = "dev", dev = "phone" },
            { label = "Donner à tous", desc = "Items ou argent à tous les joueurs connectés", icon = "gift", perm = "gestion_items", opens = "dev", dev = "giveall" },
            { label = "Bypass cooldown", desc = "Cooldowns des commandes staff et joueurs exemptés", icon = "clock", opens = "dev", dev = "cooldown" },
            { label = "Antiban", desc = "Joueurs protégés contre ban / kick", icon = "shield", opens = "dev", dev = "antiban" },
            { label = "Reset sanctions", desc = "Supprimer l'historique de sanctions d'un joueur", icon = "trash", opens = "dev", dev = "sanctions" },
            { label = "Restauration inventaire", desc = "Restaurer un inventaire confisqué", icon = "refresh", perm = "restore_inventory", opens = "dev", dev = "invrestore" },
        },
    },
    {
        id = "videos", label = "VIDÉOS", icon = "film", perm = "video_management",
        items = {
            { label = "Gestion des vidéos", desc = "Lien YouTube, cible, plein écran, lancer / arrêter", icon = "film", action = "videos_panel", opens = "videos", intent = "manage" },
            { label = "Diffuser à tous", desc = "Lancer une vidéo YouTube pour tout le serveur", icon = "monitor", action = "videos_panel", opens = "videos", intent = "broadcast" },
            { label = "Arrêter pour tous", desc = "Couper toutes les vidéos en cours", icon = "close", action = "videos_panel", opens = "videos", intent = "stop" },
        },
    },
    {
        id = "inventaire", label = "INVENTAIRE", icon = "box", perm = { "dev", "gestion_items" },
        items = {
            { label = "Items", desc = "Créer, modifier et supprimer les items", icon = "box", perm = "gestion_items", opens = "dev", dev = "items" },
            { label = "Poids des joueurs", desc = "Poids max personnalisé par joueur", icon = "scales", opens = "dev", dev = "weight" },
            { label = "Poids des sacs", desc = "Poids max par modèle de sac", icon = "bag", opens = "dev", dev = "bags" },
            { label = "Plaques GPB", desc = "Autoriser ou bloquer les plaques par GPB", icon = "shield", opens = "dev", dev = "gpb" },
            { label = "Potions", desc = "Donner des potions de farm", icon = "flask", opens = "dev", dev = "potions" },
            { label = "Véhicule blacklist", desc = "Bloquer le spawn de modèles", icon = "ban", opens = "dev", dev = "vehblacklist" },
        },
    },
    {
        id = "dev", label = "DÉVELOPPEURS", icon = "monitor", perm = "dev",
        items = {
            { label = "Options développeur", desc = "Mode développeur, print props & entities, poids développeur", icon = "settings", opens = "dev", dev = "devstate" },
            { label = "Création de caméra", desc = "Freecam, flou, effets, FOV, export / import de configuration", icon = "camera", opens = "dev", dev = "camera" },
            { label = "Liste des véhicules", desc = "Parcourir, prévisualiser et spawn les véhicules", icon = "car", opens = "dev", dev = "carlist" },
            { label = "Animation manager", desc = "Activer, renommer, déplacer les animations", icon = "film", perm = "manage_anim", opens = "dev", dev = "animmanager" },
            { label = "Ajouter une animation", desc = "Créer, modifier ou supprimer une animation, marche ou expression personnalisée", icon = "plus", perm = "manage_anim", action = "anims_panel", opens = "anims" },
            { label = "Appliquer une taille", desc = "Modifier la taille du ped d'un joueur", icon = "ruler", opens = "dev", dev = "pedscale" },
            { label = "Print coords", desc = "Afficher les coordonnées dans F8", icon = "pin", action = "print_coords" },
            { label = "Print ground coords", desc = "Coordonnées au sol dans F8", icon = "pin", action = "print_ground" },
            { label = "Prop placer", desc = "Placement d'objets sur le ped (gizmo)", icon = "ruler", opens = "dev", dev = "propplacer" },
            { label = "Liste des mappings", desc = "Mappings de la carte (mode développeur)", icon = "map", opens = "dev", dev = "mappings" },
        },
    },
    {
        id = "events", label = "EVENTS SPÉCIAUX", icon = "sparkles", perm = "events",
        items = {
            { label = "Blackout", desc = "Couper ou rétablir les éclairages de la ville", icon = "bolt", action = "blackout" },
            { label = "Incendie", desc = "Créer et gérer des incendies", icon = "fire", submenu = "fireMenu" },
            { label = "Feu d'artifice", desc = "Lancer un spectacle pyrotechnique", icon = "sparkles", submenu = "fireworkMenu" },
            { label = "Séisme", desc = "Déclencher un séisme", icon = "globe", submenu = "earthquakeMenu" },
        },
    },
}

-- Lookup des tuiles des catégories directes (rempli par BuildHubData)
local directItemLookup = {}

--- Sépare le jeton d'icône (":car: GO FAST" -> "car", "GO FAST").
---@param label string
---@return string icon, string text
local function SplitLabel(label)
    label = tostring(label or "")
    local icon = label:match("^%s*:([%w%-]+):")
    local text = label:gsub(":[%w%-]+:", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    -- "CATÉGORIE BRAQUAGES" -> "BRAQUAGES"
    text = text:gsub("^CATÉGORIE%s+", ""):gsub("^CATEGORIE%s+", "")
    return icon or "grid", text
end

--- Construit les données du hub filtrées par les permissions du joueur.
---@return table categories
local function BuildHubData()
    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    local categories = {}
    directItemLookup = {}

    for i = 1, #directCategories do
        local c = directCategories[i]
        if HasPerm(perms, c.perm) then
            local group = { id = c.id, kind = "group", label = c.label, icon = c.icon, items = {} }
            local lookup = {}
            for n = 1, #(c.items or {}) do
                local item = c.items[n]
                if HasPerm(perms, item.perm) and (not item.submenu or StaffMenu[item.submenu]) then
                    local slot = #group.items + 1
                    lookup[slot] = item
                    group.items[slot] = {
                        index = slot, label = item.label, desc = item.desc or "", icon = item.icon or "grid",
                        opens = item.opens or (item.action and "action" or "vui"),
                        intent = item.intent,
                        dev = item.dev,
                    }
                end
            end
            if #group.items > 0 then
                directItemLookup[c.id] = lookup
                categories[#categories + 1] = group
            end
        end
    end

    if perms["builder_menu"] and StaffMenu.builderEntries then
        local entries = StaffMenu.builderEntries
        local group = nil

        for i = 1, #entries do
            local e = entries[i]
            if e.separator then
                if HasPerm(perms, e.perm) then
                    local icon, text = SplitLabel(e.separator)
                    group = { id = "group_" .. i, kind = "group", label = text, icon = icon, items = {} }
                    categories[#categories + 1] = group
                else
                    group = nil
                end
            elseif group and e.label and (HasPerm(perms, e.perm) or (e.altPerm and perms[e.altPerm])) then
                local icon, text = SplitLabel(e.label)
                group.items[#group.items + 1] = {
                    index = i, label = text, desc = e.desc or "", icon = icon,
                    opens = e.opens or ((e.submenu or e.openFn) and "vui" or "action"),
                }
            end
        end

        -- Retirer les groupes vides (aucun outil accessible)
        for i = #categories, 1, -1 do
            local c = categories[i]
            if c.kind == "group" and #c.items == 0 then
                table.remove(categories, i)
            end
        end
    end

    return categories
end

--- Ouvre le hub. `state.category` = catégorie à rouvrir (retour depuis un outil).
---@param state? table
function StaffMenu.OpenGestionHub(state)
    if not VFW.HasStaffPerm("gestion") then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion', message = "Vous n'avez pas la permission d'accéder à la gestion." })
        return
    end

    -- Le hub prend la main : on ferme tout menu VUI encore affiché.
    exports["VUI"]:CloseAll()

    hubData = BuildHubData()
    hubOpen = true
    hubMinimized = false

    SendNUIMessage({
        action = "gestion:open",
        data = {
            brand = VFW.BrandName(),
            categories = hubData,
            state = state,
        },
    })
    VFW.Nui.Focus(true)
end

function StaffMenu.CloseGestionHub()
    if not hubOpen then return end
    hubOpen = false
    hubMinimized = false
    -- Nettoyage des outils natifs (previews, freecam, skin...) — gestion_dev.lua
    TriggerEvent("gestion:hub:closed")
    -- Coupe un éventuel menu VUI encore rendu dans le hub
    exports["VUI"]:CloseAll()
    SendNUIMessage({ action = "gestion:close" })
    VFW.Nui.Focus(false)
end

function StaffMenu.IsGestionHubOpen()
    return hubOpen == true
end

function StaffMenu.IsGestionHubMinimized()
    return hubOpen == true and hubMinimized == true
end

local function ApplyWalkFocus()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

function StaffMenu.MinimizeGestionHub()
    if not hubOpen or hubMinimized then return end
    hubMinimized = true
    SendNUIMessage({ action = "gestion:minimize" })
    ApplyWalkFocus()
end

function StaffMenu.RestoreGestionHub()
    if not hubOpen then return end
    hubMinimized = false
    SendNUIMessage({ action = "gestion:restore" })
    VFW.Nui.Focus(true)
end

function StaffMenu.CoverGestionHub()
    if not hubOpen then return end
    hubMinimized = false
    SendNUIMessage({ action = "gestion:cover" })
end

function StaffMenu.UncoverGestionHub()
    if not hubOpen then return end
    SendNUIMessage({ action = "gestion:uncover" })
    if hubMinimized then
        ApplyWalkFocus()
    else
        VFW.Nui.Focus(true)
    end
end

--- Recolle le focus NUI sur le hub après un clavier / choix (sinon le curseur est perdu).
function StaffMenu.RestoreGestionHubFocus()
    if not hubOpen then return end
    if hubMinimized then
        ApplyWalkFocus()
        return
    end
    VFW.Nui.Focus(true)
end

--- Relais des messages VUI (mode hub) vers le NUI de gestion.
local function RelayVuiToHub(msg)
    if not hubOpen then return end
    SendNUIMessage({ action = "gestion:vui", data = msg })
end

AddEventHandler("vui:hub:message", RelayVuiToHub)
exports("GestionHubVuiMessage", RelayVuiToHub)

AddEventHandler("vui:hub:ended", function()
    if not hubOpen then return end
    StaffMenu.RestoreGestionHubFocus()
end)

AddEventHandler("vui:hub:focus", function()
    StaffMenu.RestoreGestionHubFocus()
end)

local hubBlackout = false
local OpenFromHub

--- Actions locales (clavier, tablettes, toggles) — pas de menu VUI.
---@param action string
local function RunHubAction(action)
    if action == "roles_panel" or action == "server_panel" or action == "weather_tablet" or action == "videos_panel" then
        return
    elseif action == "clear_zone" then
        local radius = tonumber(VFW.Nui.KeyboardInput(true, "Radius (mètres)", "100"))
        if radius and radius > 0 then
            TriggerServerEvent("vfw:staff:clearZone", radius)
        end
    elseif action == "print_coords" then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        print(string.format("^2Coordonnées:^0 x=%.2f, y=%.2f, z=%.2f, heading=%.2f", coords.x, coords.y, coords.z, heading))
        print(string.format("^3Vector3:^0 vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z))
        print(string.format("^3Vector4:^0 vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading))
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Dev', message = "Coordonnées affichées dans la console F8." })
    elseif action == "print_ground" then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        if found then coords = vector3(coords.x, coords.y, groundZ) end
        print(string.format("^2Coordonnées Sol:^0 x=%.2f, y=%.2f, z=%.2f, heading=%.2f", coords.x, coords.y, coords.z, heading))
        print(string.format("^3Vector3:^0 vector3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z))
        print(string.format("^3Vector4:^0 vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading))
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Dev', message = "Coordonnées du sol affichées dans la console F8." })
    elseif action == "ped_scale" then
        local idInput = VFW.Nui.KeyboardInput(true, "ID du joueur cible", "")
        if not idInput or idInput == "" then return end
        local targetId = tonumber(idInput)
        if not targetId then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Cet identifiant n'est pas valide." })
            return
        end
        local scaleInput = VFW.Nui.KeyboardInput(true, "Taille du ped (0.1 - 2.0)", "1.0")
        if not scaleInput or scaleInput == "" then return end
        local scale = tonumber((scaleInput:gsub(",", ".")))
        if not scale then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Cette valeur n'est pas valide." })
            return
        end
        local success, applied = TriggerServerCallback("vfw:staff:applyPedScale", targetId, scale)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Outils Dev', message = "Taille " .. tostring(applied) .. " appliquée sur [" .. targetId .. "]" })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Outils Dev', message = "Impossible d'appliquer la taille." })
        end
    elseif action == "video_all" then
        local videoUrl = VFW.Nui.KeyboardInput(true, "Lien YouTube pour diffusion générale", "")
        if videoUrl and videoUrl ~= "" then
            if string.find(videoUrl, "youtube.com") or string.find(videoUrl, "youtu.be") then
                TriggerServerEvent("vfw:staff:playVideo", videoUrl, 2, 3, -1)
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos', message = "Ce lien n'est pas valide, YouTube uniquement." })
            end
        end
    elseif action == "video_stop_all" then
        local confirm = VFW.Nui.KeyboardInput(true, "Tapez 'CONFIRMER' pour arrêter toutes les vidéos", "")
        if confirm and string.lower(confirm) == "confirmer" then
            TriggerServerEvent("vfw:staff:stopVideoForAll")
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Vidéos', message = "Toutes les vidéos arrêtées." })
        else
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Vidéos', message = "Action annulée." })
        end
    elseif action == "blackout" then
        hubBlackout = not hubBlackout
        TriggerServerEvent("vfw:staff:setBlackout", hubBlackout)
        VFW.ShowNotification({
            type = 'STAFF', variant = 'SUCCESS', subtitle = 'Events',
            message = hubBlackout and "Blackout activé." or "Blackout désactivé.",
        })
    elseif action == "hud_layout_server" then
        StaffMenu.CloseGestionHub()
        CreateThread(function()
            Wait(80)
            if VFW.HudLayout and VFW.HudLayout.StartEditor then
                VFW.HudLayout.StartEditor("server")
            end
        end)
    elseif action == "periodic_notif" then
        OpenPeriodicNotificationsPanel()
    elseif action == "image_manager" then
        StaffMenu.CoverGestionHub()
        StaffMenu.OpenImageManager()
    elseif action == "garage_spawns" then
        OpenFromHub(nil, function()
            StaffMenu.OpenGarageSpawnPointsBuilder()
        end)
    elseif action == "toggle_dev" then
        StaffMenu.isInDevMode = not StaffMenu.isInDevMode
        VFW.ShowNotification({
            type = 'STAFF', variant = StaffMenu.isInDevMode and 'SUCCESS' or 'INFO', subtitle = 'Outils Dev',
            message = StaffMenu.isInDevMode and "Mode développeur activé." or "Mode développeur désactivé.",
        })
    elseif action == "toggle_print_props" then
        StaffMenu.PrintPropsAndEntities = not StaffMenu.PrintPropsAndEntities
        VFW.ShowNotification({
            type = 'STAFF', variant = StaffMenu.PrintPropsAndEntities and 'SUCCESS' or 'INFO', subtitle = 'Outils Dev',
            message = StaffMenu.PrintPropsAndEntities and "Print Props & Entities activé." or "Print Props & Entities désactivé.",
        })
    elseif action == "toggle_dev_weight" then
        StaffMenu.hasDevWeight = not StaffMenu.hasDevWeight
        TriggerServerEvent("vfw:staff:toggleDevWeight", StaffMenu.hasDevWeight)
        VFW.ShowNotification({
            type = 'STAFF', variant = StaffMenu.hasDevWeight and 'SUCCESS' or 'INFO', subtitle = 'Outils Dev',
            message = StaffMenu.hasDevWeight and "Poids développeur activé (5000 kg)." or "Poids développeur désactivé.",
        })
    end
end

--- Ouvre un sous-menu VUI dans le hub (sans fermer le NUI de gestion).
---@param menu table|nil Menu VUI (StaffMenu.xxx)
---@param onClick function|nil Callback du bouton d'origine (exécuté avant l'ouverture)
---@param state table État du hub à restaurer si le hub a été fermé entre-temps
OpenFromHub = function(menu, onClick, state)
    local hasMenu = menu and IsCallable(menu.open)

    if not hasMenu then
        -- Outil externe (tablette, menu hors VUI) : le hub cède la place
        StaffMenu.CloseGestionHub()
        if onClick then
            local ok, err = pcall(onClick)
            if not ok then
                console.error("[GestionHub] onClick error: " .. tostring(err))
            end
        end
        return
    end

    if onClick then
        local ok, err = pcall(onClick)
        if not ok then
            console.error("[GestionHub] onClick error: " .. tostring(err))
        end
    end

    SetTimeout(0, function()
        if not hubOpen then return end
        OpenVuiInHub(menu.open, function()
            if hubOpen then
                StaffMenu.RestoreGestionHubFocus()
            else
                StaffMenu.OpenGestionHub(state)
            end
        end)
    end)
end

RegisterNuiCallback("gestion:close", function(_, cb)
    StaffMenu.CloseGestionHub()
    cb({})
end)

RegisterNuiCallback("gestion:minimize", function(_, cb)
    cb({})
    StaffMenu.MinimizeGestionHub()
end)

RegisterNuiCallback("gestion:restore", function(_, cb)
    cb({})
    StaffMenu.RestoreGestionHub()
end)

RegisterNuiCallback("gestion:select", function(data, cb)
    cb({})
    if not hubOpen or type(data) ~= "table" then return end

    local perms = (VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions) or {}
    local state = { category = data.category }

    if data.kind == "tool" then
        local idx = tonumber(data.index) or 0
        local catId = data.category
        local lookup = catId and directItemLookup[catId]
        if lookup then
            local item = lookup[idx]
            if not item then return end
            for i = 1, #directCategories do
                if directCategories[i].id == catId and not HasPerm(perms, directCategories[i].perm) then return end
            end
            if item.perm and not HasPerm(perms, item.perm) then return end
            if item.action then
                RunHubAction(item.action)
                return
            end
            if item.submenu then
                OpenFromHub(StaffMenu[item.submenu], item.onClick, state)
            end
            return
        end

        local entries = StaffMenu.builderEntries
        local e = entries and entries[idx]
        if not e or not e.label or e.separator then return end
        if not perms["builder_menu"] or (e.perm and not perms[e.perm]) then return end

        if e.submenu then
            OpenFromHub(StaffMenu[e.submenu], e.onClick, state)
        elseif e.openFn then
            OpenFromHub({ open = e.openFn }, e.onClick, state)
        else
            OpenFromHub(nil, e.onClick, state)
        end
    end
end)

RegisterCommand("gestion", function()
    if hubOpen then
        if hubMinimized then
            StaffMenu.RestoreGestionHub()
            return
        end
        StaffMenu.CloseGestionHub()
        return
    end
    StaffMenu.OpenGestionHub()
end, false)

CreateThread(function()
    while true do
        if hubOpen and hubMinimized then
            if IsControlJustPressed(0, 47) then -- G
                StaffMenu.RestoreGestionHub()
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if hubOpen then
        hubOpen = false
        hubMinimized = false
        SetNuiFocus(false, false)
    end
end)
