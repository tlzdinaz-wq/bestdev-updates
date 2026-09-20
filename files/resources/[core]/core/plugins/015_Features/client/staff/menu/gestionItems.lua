---@meta _
---@diagnostic disable: duplicate-doc-field

local itemQuery = nil
local lastItem = nil
local _editItem = nil

-- Pagination : sans ça, VFW.Items (souvent 1000+) freeze le NUI à l'ouverture.
local GESTION_ITEMS_PER_PAGE = 20
local gestionItemsPage = 1

--- .BuildGestionItemsMenu
---@return any
function StaffMenu.BuildGestionItemsMenu()
    local menu = StaffMenu.gestionItems
    local firstLabel = itemQuery == nil and "RECHERCHER" or "RECHERCHER:"
    local lastLabel = itemQuery == nil and "UN ITEM" or itemQuery

    -- Navigation par 7e argument (submenu) : le handler VUI empile pour le retour
    -- et ouvre le sous-menu SANS envoyer vui:menu:close (pas de course NUI). Le
    -- OnOpen de createItem (BuildCreateItemMenu) est alors bien déclenché.
    menu.Button(":plus: CRÉER UN ITEM", "Créer et enregistrer un nouvel item en base de données", nil, "chevron", false, nil, StaffMenu.createItem)

    menu.Separator(nil)

    menu.Button(firstLabel, lastLabel, nil, "search", false, function()
        if itemQuery ~= nil then
            itemQuery = nil
            gestionItemsPage = 1
            menu.refresh()
            return
        end

        local query = VFW.Nui.KeyboardInput(true, "Entrez un nom ou un label")
        if query == nil or query == "" then
            return
        end

        itemQuery = query
        gestionItemsPage = 1
        menu.refresh()
    end)

    menu.Separator(nil)

    -- Filtrer + trier avant pagination (évite de créer des centaines de boutons NUI).
    local filtered = {}
    local queryLower = itemQuery and string.lower(tostring(itemQuery)) or nil
    for itemName, item in pairs(VFW.Items) do
        local itemLabel = item.label or itemName
        if not queryLower
            or string.find(string.lower(itemName), queryLower, 1, true)
            or string.find(string.lower(itemLabel), queryLower, 1, true) then
            filtered[#filtered + 1] = {
                name = itemName,
                label = itemLabel,
                weight = item.weight or 0,
            }
        end
    end

    table.sort(filtered, function(a, b)
        return a.label < b.label
    end)

    local total = #filtered
    local totalPages = math.max(1, math.ceil(total / GESTION_ITEMS_PER_PAGE))
    if gestionItemsPage > totalPages then gestionItemsPage = totalPages end
    if gestionItemsPage < 1 then gestionItemsPage = 1 end

    local startIndex = (gestionItemsPage - 1) * GESTION_ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + GESTION_ITEMS_PER_PAGE - 1, total)

    if totalPages > 1 then
        menu.Separator("Page " .. gestionItemsPage .. "/" .. totalPages, total .. " items")
        if gestionItemsPage > 1 then
            menu.Button(":back: PAGE PRÉCÉDENTE", "Page " .. (gestionItemsPage - 1) .. "/" .. totalPages, nil, "arrow", false, function()
                gestionItemsPage = gestionItemsPage - 1
                menu.refresh()
            end)
        end
        if gestionItemsPage < totalPages then
            menu.Button("PAGE SUIVANTE :arrow:", "Page " .. (gestionItemsPage + 1) .. "/" .. totalPages, nil, "arrow", false, function()
                gestionItemsPage = gestionItemsPage + 1
                menu.refresh()
            end)
        end
        menu.Separator(nil)
    elseif total > 0 then
        menu.Separator(total .. " items")
    end

    for i = startIndex, endIndex do
        local entry = filtered[i]
        if entry then
            menu.Button(entry.label, entry.name, entry.weight .. " kg", "chevron", false, function()
                lastItem = entry.name
                _editItem = nil
            end, StaffMenu.selectItem)
        end
    end

    if total == 0 then
        menu.Button("Aucun item", itemQuery and "Aucun résultat pour cette recherche" or "Aucun item enregistré", nil, "chevron", true, function() end)
    end
end

--- .BuildSelectItemMenu
---@return any
function StaffMenu.BuildSelectItemMenu()
    StaffMenu.selectItem.Separator("ITEM", lastItem)

    StaffMenu.selectItem.Separator(nil)

    StaffMenu.selectItem.Button("SUPPRIMER", "Supprimer définitivement cet item de la base de données du serveur", nil, "chevron", false, function()
        local confirm = VFW.Nui.KeyboardInput(true, "Êtes-vous sûr de vouloir supprimer cet item ? (OUI/NON)")
        if confirm == nil or confirm == "" then
            return
        end

        if confirm:lower() == "oui" then
            StaffMenu.selectItem.close()
            VFW.Items[lastItem] = nil
            TriggerServerEvent("vfw:staff:deleteItem", lastItem)
        end
    end)

    StaffMenu.selectItem.Button("MODIFIER", "Modifier les propriétés de cet item (label, poids, description...)", nil, "chevron", false, function()
        _editItem = nil
    end, StaffMenu.editGestionItem)
end

-- Aligné sur 000_framework/server/001_common.lua (et createItem serveur).
---@param rawType any
---@return string
local function getTypeInventory(rawType)
    if rawType == "weapon" then
        return "weapons"
    elseif rawType == "consumable" or rawType == "drink" then
        return "food"
    elseif rawType == "objects" or rawType == "gpb" or rawType == "ammo" or rawType == "drugs" or rawType == "component" or rawType == "tint" or rawType == "misc" then
        return "items"
    else
        return rawType
    end
end

-- Types d'items sélectionnables dans la liste déroulante (ordre d'affichage).
local ITEM_TYPES = { "objects", "consumable", "drugs", "weapon", "ammo", "component", "tint", "gpb" }

-- Libellés lisibles pour l'affichage à droite du sélecteur de type.
local ITEM_TYPE_LABELS = {
    objects    = "Objet standard",
    consumable = "Consommable",
    drugs      = "Drogue",
    weapon     = "Arme",
    ammo       = "Munition",
    component  = "Composant d'arme",
    tint       = "Teinte d'arme",
    gpb        = "GPB",
}

--- Valeur affichée à droite d'un bouton (placeholder si vide).
---@param v any
---@return string
local function dispVal(v)
    if v == nil or v == "" then return "Non défini" end
    return tostring(v)
end

---@param v any
---@return boolean
local function toBool(v)
    return v == true or v == 1 or v == "1"
end

--- Devine le type brut (data.type) si absent, à partir du type inventaire.
---@param item table
---@return string|nil
local function inferRawItemType(item)
    if item.data and type(item.data.type) == "string" and item.data.type ~= "" then
        return item.data.type
    end
    if item.type == "weapons" then return "weapon" end
    if item.type == "food" then return "consumable" end
    if item.type == "items" then return "objects" end
    return nil
end

-- État du formulaire de création (persistant entre les ouvertures du menu).
-- ⚠️ NE PAS nommer une variable `type` ici : ça masquerait la fonction globale
--    `type()` pour tout le reste du fichier.
local newItem = { name = nil, label = nil, itemType = nil, weight = nil, data = {}, premium = false, perm = false }

--- Réinitialise le formulaire de création.
local function resetNewItem()
    newItem = { name = nil, label = nil, itemType = nil, weight = nil, data = {}, premium = false, perm = false }
end

--- .BuildEditGestionItemMenu
--- Formulaire d'édition aligné sur la création (type, image, premium, perm, etc.).
---@return any
function StaffMenu.BuildEditGestionItemMenu()
    local m = StaffMenu.editGestionItem
    m.ClearItems()

    local item = VFW.Items[lastItem]
    if not item then
        m.Button("ERREUR", "Item introuvable", nil, "chevron", true, function() end)
        return
    end

    if not _editItem then
        local dataCopy = {}
        if item.data then
            for k, v in pairs(item.data) do
                dataCopy[k] = v
            end
        end
        if not dataCopy.type then
            dataCopy.type = inferRawItemType(item)
        end
        _editItem = {
            label = item.label,
            weight = item.weight,
            premium = toBool(item.premium),
            perm = toBool(item.perm),
            data = dataCopy,
        }
    end

    _editItem.data = _editItem.data or {}
    local d = _editItem.data
    local t = d.type

    local isConsumable = t == "consumable"
    local isDrugs      = t == "drugs"
    local isWeapon     = t == "weapon"
    local isAmmo       = t == "ammo"
    local usesEffects  = isConsumable or isDrugs

    m.Separator("IDENTITÉ", lastItem)

    m.Button("Label", "Nom affiché au joueur dans son inventaire", dispVal(_editItem.label), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Label", _editItem.label or "")
        if v == nil or v == "" then return end
        _editItem.label = v
        m.refresh()
    end)

    m.Separator("CATÉGORIE")

    local typeItems = { "À choisir" }
    local typeIndex = 1
    for i, tp in ipairs(ITEM_TYPES) do
        typeItems[#typeItems + 1] = ITEM_TYPE_LABELS[tp] or tp
        if tp == t then typeIndex = i + 1 end
    end
    m.List("Type d'item", "Détermine les champs disponibles ci-dessous", false, typeItems, typeIndex, function(idx)
        local selected = ITEM_TYPES[idx - 1]
        d.type = selected
        m.refresh()
    end)

    m.Separator("PROPRIÉTÉS")

    m.Button("Poids", "Poids en kg occupé dans l'inventaire (ex: 20)", dispVal(_editItem.weight), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Poids [ex: 20]", tostring(_editItem.weight or ""))
        if v == nil or v == "" then return end
        _editItem.weight = tonumber(v)
        m.refresh()
    end)

    m.Button("Prix d'achat", "Prix de vente en magasin, laissez vide si non vendable", dispVal(d.buyPrice), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Prix [ex: 100]", d.buyPrice and tostring(d.buyPrice) or "")
        if v == nil then return end
        d.buyPrice = (v ~= "" and tonumber(v)) or nil
        m.refresh()
    end)

    m.Button("Description", "Texte affiché dans l'inventaire / tooltip", dispVal(d.description), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez la description de l'item", d.description or "")
        if v == nil then return end
        d.description = (v ~= "" and v) or nil
        m.refresh()
    end)

    if usesEffects then
        m.Separator("CONSOMMATION")

        if isConsumable then
            m.Button("Faim", "Points de faim rendus à la consommation, en %", dispVal(d.hunger), "chevron", false, function()
                local v = VFW.Nui.KeyboardInput(true, "Entrez la Faim en % [ex: 10]", d.hunger and tostring(d.hunger) or "")
                if v == nil or v == "" then return end
                d.hunger = v
                m.refresh()
            end)

            m.Button("Soif", "Points de soif rendus à la consommation, en %", dispVal(d.thirst), "chevron", false, function()
                local v = VFW.Nui.KeyboardInput(true, "Entrez la Soif en % [ex: 12]", d.thirst and tostring(d.thirst) or "")
                if v == nil or v == "" then return end
                d.thirst = v
                m.refresh()
            end)
        end

        m.Button("Effet", "Effet spécial appliqué à la consommation (ex: heal)", dispVal(d.effect), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez l'effet [ex: heal]", d.effect or "")
            if v == nil or v == "" then return end
            d.effect = v
            m.refresh()
        end)

        m.Button("Durée", "Durée de l'animation / de l'effet en secondes", dispVal(d.duration), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez la Duree [ex: 12]", d.duration and tostring(d.duration) or "")
            if v == nil or v == "" then return end
            d.duration = v
            m.refresh()
        end)

        m.Button("Expiration", "Nombre de jours avant péremption", dispVal(d.expiration), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez l'Expiration en jour [ex: 12]", d.expiration and tostring(d.expiration) or "")
            if v == nil then return end
            d.expiration = (v ~= "" and v) or nil
            m.refresh()
        end)

        if isConsumable then
            m.Checkbox("Alcool", "Applique les effets d'alcool (vision floue, désinhibition)", false, toBool(d.alcool), function(_checked)
                d.alcool = _checked
                m.refresh()
            end)
        end

        if isDrugs then
            m.Checkbox("Drogue", "Marque l'item comme stupéfiant (effets et détection police)", false, toBool(d.drugs), function(_checked)
                d.drugs = _checked
                m.refresh()
            end)
        end
    end

    if isWeapon or isAmmo then
        m.Separator("MUNITIONS")

        m.Button("Type de munition", "ammo_pistol, ammo_rifle, ammo_shotgun... Vide = détection auto", dispVal(d.ammoType), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez le type d'ammo [vide = auto]", d.ammoType or "")
            if v == nil then return end
            d.ammoType = (v ~= "" and v) or nil
            m.refresh()
        end)
    end

    m.Separator("AVANCÉ (optionnel)")

    m.Button("Animation", "Animation jouée lors de l'utilisation", dispVal(d.anim), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez l'anim", d.anim or "")
        if v == nil or v == "" then return end
        d.anim = v
        m.refresh()
    end)

    m.Button("Prop en main", "Objet 3D tenu en main lors de l'utilisation", dispVal(d.prop), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez le prop", d.prop or "")
        if v == nil or v == "" then return end
        d.prop = v
        m.refresh()
    end)

    m.Button("Prop au sol", "Objet 3D affiché quand l'item est jeté au sol", dispVal(d.drop), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez le drop", d.drop or "")
        if v == nil or v == "" then return end
        d.drop = v
        m.refresh()
    end)

    m.Button("Image (URL)", "Lien direct. Laissez vide = image CDN items/<nom>.webp", dispVal(d.image), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez l'URL de l'image [vide = CDN]", d.image or "")
        if v == nil then return end
        d.image = (v ~= "" and v) or nil
        m.refresh()
    end)

    m.Separator("OPTIONS")

    m.Checkbox("Droppable", "Autoriser le joueur à poser cet item au sol depuis son inventaire", false, d.droppable ~= false, function(_checked)
        d.droppable = _checked
        m.refresh()
    end)

    m.Checkbox("Premium", "Item réservé ou obtenu via la boutique premium", false, toBool(_editItem.premium), function(_checked)
        _editItem.premium = _checked
        m.refresh()
    end)

    m.Checkbox("Permanent", "Item non supprimable au wipe, conservé de façon permanente", false, toBool(_editItem.perm), function(_checked)
        _editItem.perm = _checked
        m.refresh()
    end)

    m.Separator("VALIDATION")

    m.Button("✓ Enregistrer", "Sauvegarder les modifications en base de données", nil, "chevron", false, function()
        if not _editItem.label or _editItem.label == "" then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Items', message = "Le label est obligatoire." })
            return
        end
        if _editItem.weight == nil then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Items', message = "Le poids est obligatoire." })
            return
        end
        TriggerServerEvent("vfw:staff:saveItem", lastItem, _editItem)
    end)
end

RegisterNetEvent("vfw:staff:saveItem:response", function(success)
    if success then
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Items', message = 'Item sauvegardé.' })
        _editItem = nil
        if StaffMenu.editGestionItem.opened then
            StaffMenu.editGestionItem.refresh()
        end
    else
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Items', message = 'Erreur lors de la sauvegarde.' })
        _editItem = nil
    end
end)

---Create StaffMenu.BuildItemMenu
--- Formulaire de création d'item, organisé en sections. Les champs spécifiques
--- (consommation, munitions...) n'apparaissent que si le TYPE sélectionné les
--- concerne, pour garder un rendu épuré et intuitif.
---@return any
function StaffMenu.BuildCreateItemMenu()
    local m = StaffMenu.createItem
    m.ClearItems()
    newItem.data = newItem.data or {}
    local d = newItem.data
    local t = d.type -- type brut sélectionné (nil tant que non choisi)

    -- Catégories dérivées du type, qui pilotent l'affichage des sections.
    local isConsumable = t == "consumable"
    local isDrugs      = t == "drugs"
    local isWeapon     = t == "weapon"
    local isAmmo       = t == "ammo"
    local usesEffects  = isConsumable or isDrugs

    -- ─────────────────────────── IDENTITÉ ───────────────────────────
    m.Separator("IDENTITÉ")

    m.Button("Nom (identifiant)", "Identifiant unique et technique, sans espace ni majuscule (ex: water)", dispVal(newItem.name), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Name (identifiant unique, ex: water)")
        if v == nil or v == "" then return end
        -- Nom TOUJOURS en minuscules : la détection d'arme (string.find(name, "weapon_"))
        -- et les lookups VFW.Items[string.lower(name)] sont sensibles à la casse. Un nom
        -- comme "WEAPON_DEAGLE" s'afficherait mais serait injouable ("objet non utilisable").
        newItem.name = string.lower(v)
        m.refresh()
    end)

    m.Button("Label", "Nom affiché au joueur dans son inventaire (ex: Bouteille d'eau)", dispVal(newItem.label), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Label")
        if v == nil or v == "" then return end
        newItem.label = v
        m.refresh()
    end)

    -- ─────────────────────────── CATÉGORIE ───────────────────────────
    m.Separator("CATÉGORIE")

    -- Liste déroulante des types. Le 1er élément est une sentinelle "non choisi".
    local typeItems = { "À choisir" }
    local typeIndex = 1
    for i, tp in ipairs(ITEM_TYPES) do
        typeItems[#typeItems + 1] = ITEM_TYPE_LABELS[tp] or tp
        if tp == t then typeIndex = i + 1 end
    end
    m.List("Type d'item", "Détermine les champs disponibles ci-dessous", false, typeItems, typeIndex, function(idx)
        local selected = ITEM_TYPES[idx - 1] -- idx 1 = sentinelle
        if not selected then
            d.type = nil
            newItem.itemType = nil
        else
            d.type = selected
            newItem.itemType = getTypeInventory(selected)
        end
        m.refresh()
    end)

    -- ─────────────────────────── PROPRIÉTÉS ───────────────────────────
    m.Separator("PROPRIÉTÉS")

    m.Button("Poids", "Poids en kg occupé dans l'inventaire (ex: 20)", dispVal(newItem.weight), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Poids [ex: 20]")
        if v == nil or v == "" then return end
        newItem.weight = tonumber(v)
        m.refresh()
    end)

    m.Button("Prix d'achat", "Prix de vente en magasin, laissez vide si non vendable (ex: 100)", dispVal(d.buyPrice), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez un Prix [ex: 100]")
        if v == nil or v == "" then return end
        d.buyPrice = tonumber(v)
        m.refresh()
    end)

    -- ──────────────── CONSOMMATION (consommable / drogue) ────────────────
    if usesEffects then
        m.Separator("CONSOMMATION")

        if isConsumable then
            m.Button("Faim", "Points de faim rendus à la consommation, en % (ex: 10)", dispVal(d.hunger), "chevron", false, function()
                local v = VFW.Nui.KeyboardInput(true, "Entrez la Faim en % [ex: 10]")
                if v == nil or v == "" then return end
                d.hunger = v
                m.refresh()
            end)

            m.Button("Soif", "Points de soif rendus à la consommation, en % (ex: 12)", dispVal(d.thirst), "chevron", false, function()
                local v = VFW.Nui.KeyboardInput(true, "Entrez la Soif en % [ex: 12]")
                if v == nil or v == "" then return end
                d.thirst = v
                m.refresh()
            end)
        end

        m.Button("Effet", "Effet spécial appliqué à la consommation (ex: heal)", dispVal(d.effect), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez l'effet [ex: heal]")
            if v == nil or v == "" then return end
            d.effect = v
            m.refresh()
        end)

        m.Button("Durée", "Durée de l'animation / de l'effet en secondes (ex: 12)", dispVal(d.duration), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez la Duree [ex: 12]")
            if v == nil or v == "" then return end
            d.duration = v
            m.refresh()
        end)

        m.Button("Expiration", "Nombre de jours avant péremption, laissez vide si non périssable (ex: 12)", dispVal(d.expiration), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez l'Expiration en jour [ex: 12]")
            if v == nil or v == "" then return end
            d.expiration = v
            m.refresh()
        end)

        if isConsumable then
            m.Checkbox("Alcool", "Applique les effets d'alcool (vision floue, désinhibition)", false, d.alcool or false, function(_checked)
                d.alcool = _checked
                m.refresh()
            end)
        end

        if isDrugs then
            m.Checkbox("Drogue", "Marque l'item comme stupéfiant (effets et détection police)", false, d.drugs or false, function(_checked)
                d.drugs = _checked
                m.refresh()
            end)
        end
    end

    -- ──────────────── MUNITIONS (arme / munition) ────────────────
    if isWeapon or isAmmo then
        m.Separator("MUNITIONS")

        m.Button("Type de munition", "Item de munition consommé au rechargement. Valeurs valides : ammo_pistol, ammo_rifle, ammo_shotgun, ammo_snip, ammo_heavy, ammo_launcher... Laissez vide pour détection auto d'après le nom de l'arme.", dispVal(d.ammoType), "chevron", false, function()
            local v = VFW.Nui.KeyboardInput(true, "Entrez le type d'ammo, par exemple ammo_rifle ou ammo_pistol, ou laissez vide pour une détection automatique")
            if v == nil then return end
            d.ammoType = (v ~= "" and v) or nil
            m.refresh()
        end)
    end

    -- ──────────────── AVANCÉ (visuel, optionnel, tous types) ────────────────
    m.Separator("AVANCÉ (optionnel)")

    m.Button("Animation", "Animation jouée lors de l'utilisation (ex: anim@mp_player_intcelebrationmale@salute)", dispVal(d.anim), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez l'anim [ex: anim@mp_player_intcelebrationmale@salute]")
        if v == nil or v == "" then return end
        d.anim = v
        m.refresh()
    end)

    m.Button("Prop en main", "Objet 3D tenu en main lors de l'utilisation (ex: prop_cs_hand_radio)", dispVal(d.prop), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez le prop [ex: prop_cs_hand_radio]")
        if v == nil or v == "" then return end
        d.prop = v
        m.refresh()
    end)

    m.Button("Prop au sol", "Objet 3D affiché quand l'item est jeté au sol (ex: prop_cs_hand_radio)", dispVal(d.drop), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez le drop [ex: prop_cs_hand_radio]")
        if v == nil or v == "" then return end
        d.drop = v
        m.refresh()
    end)

    m.Button("Image (URL)", "Lien direct de l'image. Laissez vide pour utiliser l'image CDN par défaut (items/<nom>.webp)", dispVal(d.image), "chevron", false, function()
        local v = VFW.Nui.KeyboardInput(true, "Entrez l'URL de l'image [laisser vide = CDN par défaut]")
        if v == nil then return end
        d.image = (v ~= "" and v) or nil
        m.refresh()
    end)

    -- ─────────────────────────── OPTIONS ───────────────────────────
    m.Separator("OPTIONS")

    m.Checkbox("Premium", "Item réservé ou obtenu via la boutique premium", false, newItem.premium, function(_checked)
        newItem.premium = _checked
        m.refresh()
    end)

    m.Checkbox("Permanent", "Item non supprimable au wipe, conservé de façon permanente", false, newItem.perm, function(_checked)
        newItem.perm = _checked
        m.refresh()
    end)

    -- ─────────────────────────── VALIDATION ───────────────────────────
    m.Separator("VALIDATION")

    -- Sous-titre dynamique : indique ce qu'il reste à renseigner.
    local missing = {}
    if not (newItem.name and newItem.name ~= "") then missing[#missing + 1] = "Nom" end
    if not (newItem.label and newItem.label ~= "") then missing[#missing + 1] = "Label" end
    if not newItem.itemType then missing[#missing + 1] = "Type" end
    if not newItem.weight then missing[#missing + 1] = "Poids" end

    local validSubtitle = #missing == 0
        and "Tout est prêt, enregistrez le nouvel item en base de données"
        or ("Champs obligatoires manquants : " .. table.concat(missing, ", "))

    m.Button("✓ Créer l'item", validSubtitle, #missing == 0 and "Prêt" or "Incomplet", "chevron", false, function()
        if #missing > 0 then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Items', message = "Renseignez au minimum : " .. table.concat(missing, ", ") .. "." })
            return
        end

        if VFW.Items[newItem.name] then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Items', message = "Un item nommé '" .. newItem.name .. "' existe déjà." })
            return
        end

        TriggerServerEvent("vfw:staff:createItem", newItem.name, newItem.label, newItem.weight, newItem.data, newItem.premium, newItem.perm)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Items', message = "Item '" .. newItem.name .. "' créé." })
        resetNewItem()
        m.close()
    end)
end
