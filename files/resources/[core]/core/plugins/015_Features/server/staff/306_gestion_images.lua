---@meta _
---@diagnostic disable: duplicate-doc-field

-- Hub Gestion > Gérer les images (items, sociétés, factions, bannières, mugshots)

local ITEM_CAT_LABELS = {
    weapon = "Armes",
    weapons = "Armes",
    consumable = "Consommables",
    drink = "Boissons",
    food = "Nourriture",
    objects = "Objets",
    item = "Objets",
    items = "Objets",
    gpb = "GPB",
    ammo = "Munitions",
    drugs = "Drogues",
    component = "Composants",
    tint = "Teintes",
    misc = "Divers",
}

local ready = false
local settingsReady = false
local PAUSE_STORE = "pause_menu"
local PAUSE_TILES = { "personnage", "carte", "boutique", "reglages", "support" }
VFW.GestionImages = VFW.GestionImages or {}
VFW.GestionImages.Cache = VFW.GestionImages.Cache or {}

local function cacheGet(scope, key)
    local bucket = VFW.GestionImages.Cache[scope]
    if type(bucket) ~= "table" then return "" end
    local value = bucket[key]
    return type(value) == "string" and value or ""
end

local function cacheSet(scope, key, url)
    VFW.GestionImages.Cache[scope] = VFW.GestionImages.Cache[scope] or {}
    VFW.GestionImages.Cache[scope][key] = url or ""
end

function VFW.GestionImages.Get(scope, key)
    return cacheGet(scope, key)
end

function VFW.GestionImages.Persist(scope, key, url)
    return persistSetting(scope, key, url)
end

local persistSetting, loadSettingsCache, applyPersistedImages

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

local function ensureTables()
    if ready then return end
    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS faction_hub (
            faction_name   VARCHAR(60)  NOT NULL,
            image          VARCHAR(1024) DEFAULT NULL,
            banner         VARCHAR(1024) DEFAULT NULL,
            active         TINYINT(1)   NOT NULL DEFAULT 0,
            posLaboratory  LONGTEXT     DEFAULT NULL,
            posCraft       LONGTEXT     DEFAULT NULL,
            posStockage    LONGTEXT     DEFAULT NULL,
            posGarage      LONGTEXT     DEFAULT NULL,
            PRIMARY KEY (faction_name)
        )
    ]], {})
    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS banner_templates (
            id    INT(11)      NOT NULL AUTO_INCREMENT,
            kind  VARCHAR(32)  NOT NULL,
            name  VARCHAR(100) NOT NULL,
            url   VARCHAR(1024) NOT NULL,
            PRIMARY KEY (id),
            KEY idx_banner_templates_kind (kind)
        )
    ]], {})
    Staff29.Query([[
        CREATE TABLE IF NOT EXISTS gestion_images_settings (
            scope    VARCHAR(32)  NOT NULL,
            item_key VARCHAR(128) NOT NULL,
            url      VARCHAR(1024) NOT NULL DEFAULT '',
            PRIMARY KEY (scope, item_key)
        )
    ]], {})
    Staff29.Query("ALTER TABLE items MODIFY COLUMN `image` VARCHAR(1024) DEFAULT NULL", {})
    Staff29.Query("ALTER TABLE societies MODIFY COLUMN `image` VARCHAR(1024) DEFAULT NULL", {})
    Staff29.Query("ALTER TABLE societies MODIFY COLUMN `banner` VARCHAR(1024) DEFAULT NULL", {})
    Staff29.Query("ALTER TABLE characters MODIFY COLUMN `mugshot` VARCHAR(1024) DEFAULT NULL", {})
    Staff29.Query("ALTER TABLE faction_hub MODIFY COLUMN `image` VARCHAR(1024) DEFAULT NULL", {})
    Staff29.Query("ALTER TABLE faction_hub MODIFY COLUMN `banner` VARCHAR(1024) DEFAULT NULL", {})
    Staff29.Query("ALTER TABLE banner_templates MODIFY COLUMN `url` VARCHAR(1024) NOT NULL", {})
    ready = true
end

local function fail(message)
    return { ok = false, error = message or "Action impossible." }
end

local function cleanStored(raw, maxLen)
    if type(raw) ~= "string" then return "" end
    local out = Staff29.Clean(raw:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^[\"']", ""):gsub("[\"']$", ""), maxLen or 1024) or ""
    if out == "" then return "" end
    if out:match("^r2%.fivemanage%.com/") or out:match("^[%w%-]+%.fivemanage%.com/") or out:match("^[%w%-]+%.fmfile%.com/") then
        out = "https://" .. out
    end
    if out:match("^https?://") or out:match("^nui://") then return out end
    out = out:gsub("\\", "/"):gsub("^/+", ""):gsub("%.%./", "")
    return out
end

local function resolveUrl(raw, fallbackPath)
    if type(raw) == "string" and raw ~= "" then
        if raw:match("^https?://") or raw:match("^nui://") then return raw end
        if VFW.CdnUrl then return VFW.CdnUrl(raw) end
        return raw
    end
    if fallbackPath and fallbackPath ~= "" then
        if VFW.CdnUrl then return VFW.CdnUrl(fallbackPath) end
        return fallbackPath
    end
    return ""
end

persistSetting = function(scope, key, url)
    if type(scope) ~= "string" or scope == "" or type(key) ~= "string" or key == "" then
        return false
    end
    ensureTables()
    local stored = cleanStored(url, 1024)
    cacheSet(scope, key, stored)
    Staff29.Update([[
        INSERT INTO gestion_images_settings (scope, item_key, url) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE url = VALUES(url)
    ]], { scope, key, stored })
    return true
end

loadSettingsCache = function()
    ensureTables()
    local rows = Staff29.Query("SELECT scope, item_key, url FROM gestion_images_settings", {}) or {}
    VFW.GestionImages.Cache = {}
    for i = 1, #rows do
        local row = rows[i]
        if type(row.scope) == "string" and type(row.item_key) == "string" then
            cacheSet(row.scope, row.item_key, type(row.url) == "string" and row.url or "")
        end
    end
    settingsReady = true
end

applyPersistedImages = function()
    loadSettingsCache()

    local items = VFW.GestionImages.Cache.item or {}
    for name, url in pairs(items) do
        if type(name) == "string" and VFW.Items and VFW.Items[name] and type(url) == "string" and url ~= "" then
            local current = VFW.Items[name]
            local data = {}
            if type(current.data) == "table" then
                for k, v in pairs(current.data) do data[k] = v end
            end
            data.image = url
            current.image = url
            current.data = data
            VFW.Items[name] = current
            TriggerClientEvent("vfw:items:update", -1, name, current)
        end
    end

    if VFW.Society and VFW.Society.Get then
        local images = VFW.GestionImages.Cache.society_image or {}
        for name, url in pairs(images) do
            local society = VFW.Society.Get(name)
            if society and type(url) == "string" then
                society.image = url
            end
        end
        local banners = VFW.GestionImages.Cache.society_banner or {}
        for name, url in pairs(banners) do
            local society = VFW.Society.Get(name)
            if society and type(url) == "string" then
                society.banner = url
            end
        end
    end

    if VFW.Variables and VFW.Variables.SetVariable then
        local branding = (VFW.Branding and VFW.Branding.GetOverrides and VFW.Branding.GetOverrides()) or {}
        local logo = cacheGet("global", "logo")
        local banner = cacheGet("global", "banner")
        if logo ~= "" then branding.logo = logo end
        if banner ~= "" then branding.banner = banner end
        if logo ~= "" or banner ~= "" then
            if VFW.Branding and VFW.Branding.SetOverride then
                if logo ~= "" then VFW.Branding.SetOverride("logo", logo) end
                if banner ~= "" then VFW.Branding.SetOverride("banner", banner) end
            else
                VFW.Variables.SetVariable("global_branding", branding)
                if VFW.Branding and VFW.Branding.Push then VFW.Branding.Push(-1) end
            end
        end

        local pause = {}
        for i = 1, #PAUSE_TILES do
            local id = PAUSE_TILES[i]
            pause[id] = cacheGet("pause", id)
        end
        VFW.Variables.SetVariable("pause_menu", pause)
        local resolved = {}
        for i = 1, #PAUSE_TILES do
            local id = PAUSE_TILES[i]
            resolved[id] = resolveUrl(pause[id])
        end
        TriggerClientEvent("core:pausemenu:images", -1, resolved)
    end

    local mugs = VFW.GestionImages.Cache.mugshot or {}
    for id, url in pairs(mugs) do
        local charId = tonumber(id)
        if charId and type(url) == "string" and url ~= "" then
            Staff29.Update("UPDATE characters SET mugshot = ? WHERE id = ? AND (mugshot IS NULL OR mugshot = '')", { url, charId })
        end
    end
end

local function itemCategory(def)
    if type(def) ~= "table" then return "objects" end
    if type(def.data) == "table" and type(def.data.type) == "string" and def.data.type ~= "" then
        return def.data.type
    end
    if def.type == "weapons" then return "weapon" end
    if def.type == "food" then return "consumable" end
    if type(def.type) == "string" and def.type ~= "" then return def.type end
    return "objects"
end

local function itemStored(def, name)
    local bucket = VFW.GestionImages.Cache.item
    if type(bucket) == "table" and bucket[name] ~= nil and bucket[name] ~= "" then
        return bucket[name]
    end
    if type(def) == "table" then
        if type(def.data) == "table" and type(def.data.image) == "string" and def.data.image ~= "" then
            return def.data.image
        end
        if type(def.image) == "string" and def.image ~= "" then
            return def.image
        end
    end
    return ("items/%s.webp"):format(name)
end

local function listItems()
    local out = {}
    local source = VFW.Items
    if type(source) ~= "table" or not next(source) then
        source = {}
        local rows = Staff29.Query("SELECT name, label, type, image, data FROM items", {})
        for i = 1, #rows do
            local row = rows[i]
            source[row.name] = {
                name = row.name,
                label = row.label,
                type = row.type,
                image = row.image,
                data = Staff29.Decode(row.data, {}),
            }
        end
    end
    for name, def in pairs(source) do
        if type(name) == "string" and name ~= "" and type(def) == "table" then
            local stored = itemStored(def, name)
            local category = itemCategory(def)
            local url = resolveUrl(stored, ("items/%s.webp"):format(name))
            out[#out + 1] = {
                name = name,
                label = def.label or name,
                category = category,
                categoryLabel = ITEM_CAT_LABELS[category] or category,
                stored = stored,
                image = url,
                imageUrl = url,
                url = url,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.categoryLabel == b.categoryLabel then
            return tostring(a.label) < tostring(b.label)
        end
        return a.categoryLabel < b.categoryLabel
    end)
    return out
end

local function societyEntry(name, society)
    local image = (society and society.image) or ""
    local banner = (society and society.banner) or ""
    local imgBucket = VFW.GestionImages.Cache.society_image
    local banBucket = VFW.GestionImages.Cache.society_banner
    if type(imgBucket) == "table" and imgBucket[name] ~= nil then image = imgBucket[name] or "" end
    if type(banBucket) == "table" and banBucket[name] ~= nil then banner = banBucket[name] or "" end
    local url = resolveUrl(image, ("job/%s/logo.png"):format(name))
    return {
        name = name,
        label = (society and society.label) or name,
        type = (society and society.type) or "society",
        storedImage = image,
        storedBanner = banner,
        image = url,
        imageUrl = url,
        banner = resolveUrl(banner),
        bannerUrl = resolveUrl(banner),
        url = url,
    }
end

local function listSocieties()
    local out = {}
    local all = (VFW.Society and VFW.Society.GetAll and VFW.Society.GetAll()) or {}
    if type(all) == "table" and next(all) then
        for name, society in pairs(all) do
            if type(name) == "string" and name ~= "" then
                out[#out + 1] = societyEntry(name, society)
            end
        end
    else
        local rows = Staff29.Query("SELECT name, label, type, image, banner FROM societies ORDER BY label ASC", {})
        for i = 1, #rows do
            out[#out + 1] = societyEntry(rows[i].name, rows[i])
        end
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

local function listFactions()
    ensureTables()
    local hubs = {}
    local hubRows = Staff29.Query("SELECT faction_name, image, banner FROM faction_hub", {})
    for i = 1, #hubRows do
        hubs[hubRows[i].faction_name] = hubRows[i]
    end
    local out = {}
    local crews = Staff29.Query("SELECT name, label FROM crews ORDER BY label ASC", {})
    for i = 1, #crews do
        local crew = crews[i]
        if crew.name ~= "nocrew" and crew.name ~= "nofaction" then
            local hub = hubs[crew.name] or {}
            local image = hub.image or ""
            local banner = hub.banner or ""
            local imgBucket = VFW.GestionImages.Cache.faction_image
            local banBucket = VFW.GestionImages.Cache.faction_banner
            if type(imgBucket) == "table" and imgBucket[crew.name] ~= nil then image = imgBucket[crew.name] or "" end
            if type(banBucket) == "table" and banBucket[crew.name] ~= nil then banner = banBucket[crew.name] or "" end
            out[#out + 1] = {
                name = crew.name,
                label = crew.label or crew.name,
                storedImage = image,
                storedBanner = banner,
                image = resolveUrl(image),
                imageUrl = resolveUrl(image),
                banner = resolveUrl(banner),
                bannerUrl = resolveUrl(banner),
                url = resolveUrl(image),
                mugshot = resolveUrl(image),
            }
        end
    end
    return out
end

local function listBanners(kind)
    ensureTables()
    local key = kind == "metier" and "metier" or "faction"
    local rows = Staff29.Query(
        "SELECT id, name, url FROM banner_templates WHERE kind = ? ORDER BY name ASC",
        { key }
    )
    local out = {}
    for i = 1, #rows do
        local url = resolveUrl(rows[i].url)
        out[#out + 1] = {
            id = rows[i].id,
            name = rows[i].name,
            url = url,
            imageUrl = url,
            image = url,
        }
    end
    return out
end

local function listMugshots()
    local rows = Staff29.Query([[
        SELECT id, firstname, lastname, identifier, mugshot
        FROM characters
        WHERE deleted_at IS NULL
        ORDER BY (mugshot IS NULL OR mugshot = ''), lastname ASC, firstname ASC
        LIMIT 800
    ]], {})
    local out = {}
    for i = 1, #rows do
        local row = rows[i]
        local first = row.firstname or ""
        local last = row.lastname or ""
        local name = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then name = row.identifier or ("#" .. tostring(row.id)) end
        local url = resolveUrl(row.mugshot)
        local bucket = VFW.GestionImages.Cache.mugshot
        if type(bucket) == "table" and bucket[tostring(row.id)] ~= nil and bucket[tostring(row.id)] ~= "" then
            url = resolveUrl(bucket[tostring(row.id)])
        end
        out[#out + 1] = {
            charId = row.id,
            id = row.id,
            firstname = first,
            lastname = last,
            identifier = row.identifier,
            name = name,
            mugshot = url,
            imageUrl = url,
            image = url,
            url = url,
        }
    end
    return out
end

local function pauseRaw()
    local raw = VFW.Variables and VFW.Variables.GetVariable and VFW.Variables.GetVariable(PAUSE_STORE)
    if type(raw) ~= "table" then raw = {} end
    local out = {}
    for i = 1, #PAUSE_TILES do
        local id = PAUSE_TILES[i]
        out[id] = type(raw[id]) == "string" and raw[id] or ""
        local bucket = VFW.GestionImages.Cache.pause
        if type(bucket) == "table" and bucket[id] ~= nil then
            out[id] = bucket[id] or ""
        end
    end
    return out
end

local function pauseResolved()
    local raw = pauseRaw()
    local out = {}
    for i = 1, #PAUSE_TILES do
        local id = PAUSE_TILES[i]
        out[id] = resolveUrl(raw[id])
    end
    return out
end

local function pausePanel()
    local raw = pauseRaw()
    local out = {}
    for i = 1, #PAUSE_TILES do
        local id = PAUSE_TILES[i]
        out[id] = {
            stored = raw[id],
            url = resolveUrl(raw[id]),
        }
    end
    return out
end

local function pushPauseImages(target)
    TriggerClientEvent("core:pausemenu:images", target or -1, pauseResolved())
end

local function setPauseTile(field, url)
    local okField = false
    for i = 1, #PAUSE_TILES do
        if PAUSE_TILES[i] == field then
            okField = true
            break
        end
    end
    if not okField then return false, "Tuile invalide." end
    if not (VFW.Variables and VFW.Variables.SetVariable) then
        return false, "Sauvegarde indisponible."
    end
    local current = pauseRaw()
    current[field] = cleanStored(url, 1024)
    persistSetting("pause", field, current[field])
    VFW.Variables.SetVariable(PAUSE_STORE, current)
    if VFW.Variables.Flush then
        VFW.Variables.Flush(PAUSE_STORE)
    end
    pushPauseImages(-1)
    return true
end

local function globalBranding()
    local ov = { logo = "", banner = "" }
    if VFW.Branding and VFW.Branding.GetOverrides then
        ov = VFW.Branding.GetOverrides() or ov
    end
    local storedLogo = cacheGet("global", "logo")
    local storedBanner = cacheGet("global", "banner")
    if storedLogo ~= "" then ov.logo = storedLogo end
    if storedBanner ~= "" then ov.banner = storedBanner end
    local built = VFW.Branding and VFW.Branding.Build and VFW.Branding.Build() or {}
    return {
        globalLogo = ov.logo or "",
        globalBanner = ov.banner or "",
        globalLogoUrl = resolveUrl(ov.logo ~= "" and ov.logo or (built.logo or "")),
        globalBannerUrl = resolveUrl(ov.banner ~= "" and ov.banner or (built.banner or "")),
    }
end

local function panel()
    ensureTables()
    if not settingsReady then loadSettingsCache() end
    local items = listItems()
    local societies = listSocieties()
    local factions = listFactions()
    local bannersMetier = listBanners("metier")
    local bannersFaction = listBanners("faction")
    local mugshots = listMugshots()
    local withMug = 0
    for i = 1, #mugshots do
        if mugshots[i].imageUrl ~= "" then withMug = withMug + 1 end
    end
    local branding = globalBranding()
    return {
        ok = true,
        cdnBase = (VFW.CDN_BASE or ""),
        items = items,
        societies = societies,
        factions = factions,
        bannersMetier = bannersMetier,
        bannersFaction = bannersFaction,
        mugshots = mugshots,
        globalLogo = branding.globalLogo,
        globalBanner = branding.globalBanner,
        globalLogoUrl = branding.globalLogoUrl,
        globalBannerUrl = branding.globalBannerUrl,
        pauseTiles = pausePanel(),
        stats = {
            items = #items,
            societies = #societies,
            factions = #factions,
            bannersMetier = #bannersMetier,
            bannersFaction = #bannersFaction,
            mugshots = withMug,
        },
    }
end

local function setItemImage(name, url)
    if type(name) ~= "string" or name == "" or not VFW.Items or not VFW.Items[name] then
        return false, "Item introuvable."
    end
    ensureTables()
    local current = VFW.Items[name]
    local stored = cleanStored(url, 1024)
    persistSetting("item", name, stored)
    local data = {}
    if type(current.data) == "table" then
        for k, v in pairs(current.data) do data[k] = v end
    end
    if stored == "" then
        data.image = nil
    else
        data.image = stored
    end
    local imageCol = stored ~= "" and stored or ("items/%s.webp"):format(name)
    Staff29.Update("UPDATE items SET image = ?, data = ? WHERE name = ?", {
        imageCol, Staff29.Encode(data), name,
    })
    current.image = imageCol
    current.data = data
    VFW.Items[name] = current
    TriggerClientEvent("vfw:items:update", -1, name, current)
    return true
end

local function setSocietyField(name, field, url)
    if type(name) ~= "string" or name == "" then return false, "Société introuvable." end
    if field ~= "image" and field ~= "banner" then return false, "Champ invalide." end
    local society = VFW.Society and VFW.Society.Get and VFW.Society.Get(name)
    if not society then return false, "Société introuvable." end
    local stored = cleanStored(url, 1024)
    persistSetting(field == "banner" and "society_banner" or "society_image", name, stored)
    if field == "banner" then
        Staff29.Update("UPDATE societies SET banner = ? WHERE name = ?", { stored, name })
    else
        Staff29.Update("UPDATE societies SET image = ? WHERE name = ?", { stored, name })
    end
    if VFW.Society.Reload then VFW.Society.Reload(name) end
    local reloaded = VFW.Society.Get and VFW.Society.Get(name)
    if reloaded then
        if field == "banner" then reloaded.banner = stored else reloaded.image = stored end
    end
    if VFW.Society.BroadcastToJob then VFW.Society.BroadcastToJob(name) end
    return true
end

local function setFactionField(name, field, url)
    if type(name) ~= "string" or name == "" then return false, "Faction introuvable." end
    if field ~= "image" and field ~= "banner" then return false, "Champ invalide." end
    local crew = Staff29.Single("SELECT name FROM crews WHERE name = ?", { name })
    if not crew or name == "nocrew" or name == "nofaction" then return false, "Faction introuvable." end
    ensureTables()
    local stored = cleanStored(url, 1024)
    persistSetting(field == "banner" and "faction_banner" or "faction_image", name, stored)
    if field == "image" then
        Staff29.Update([[
            INSERT INTO faction_hub (faction_name, image) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE image = VALUES(image)
        ]], { name, stored })
    else
        Staff29.Update([[
            INSERT INTO faction_hub (faction_name, banner) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE banner = VALUES(banner)
        ]], { name, stored })
    end
    if Staff29.Factions and Staff29.Factions.PushCrew then
        Staff29.Factions.PushCrew(name)
    end
    return true
end

local function addBanner(kind, name, url)
    local key = kind == "metier" and "metier" or (kind == "faction" and "faction" or nil)
    local label = Staff29.Clean(name, 100)
    local link = cleanStored(url, 1024)
    if not key or not label or label:gsub("%s", "") == "" or link == "" or not link:match("^https?://") then
        return false, "Nom et URL https requis."
    end
    ensureTables()
    Staff29.Insert("INSERT INTO banner_templates (kind, name, url) VALUES (?, ?, ?)", { key, label, link })
    persistSetting("banner_" .. key, label, link)
    return true
end

local function deleteBanner(id)
    local rowId = Staff29.ToInt(id, 1)
    if not rowId then return false, "Bannière introuvable." end
    ensureTables()
    Staff29.Update("DELETE FROM banner_templates WHERE id = ?", { rowId })
    return true
end

local function deleteMugshot(charId)
    local id = Staff29.ToInt(charId, 1)
    if not id then return false, "Personnage introuvable." end
    Staff29.Update("UPDATE characters SET mugshot = '' WHERE id = ?", { id })
    persistSetting("mugshot", tostring(id), "")
    return true
end

local function setGlobalBrand(field, url)
    if not VFW.Branding or not VFW.Branding.SetOverride then
        return false, "Branding indisponible."
    end
    if field ~= "logo" and field ~= "banner" then
        return false, "Champ invalide."
    end
    local stored = cleanStored(url, 1024)
    persistSetting("global", field, stored)
    return VFW.Branding.SetOverride(field, stored)
end

Staff29.Cb("gestionImages:hubPanel", function(source)
    if not staffOk(source) then return fail("Permission refusée.") end
    return panel()
end)

Staff29.Cb("gestionImages:save", function(source, data)
    if not staffOk(source) then return fail("Permission refusée.") end
    if type(data) ~= "table" then return fail("Données invalides.") end
    if type(data.data) == "table" then
        for k, v in pairs(data.data) do
            if data[k] == nil then data[k] = v end
        end
    end
    local action = data.action
    local url = data.url or data.link or data.value or ""
    local ok, err
    if action == "item" then
        ok, err = setItemImage(data.name, url)
    elseif action == "society" then
        ok, err = setSocietyField(data.name, data.field or "image", url)
    elseif action == "faction" then
        ok, err = setFactionField(data.name, data.field or "image", url)
    elseif action == "bannerAdd" then
        ok, err = addBanner(data.kind, data.name, url)
    elseif action == "bannerDelete" then
        ok, err = deleteBanner(data.id)
    elseif action == "mugshotDelete" then
        ok, err = deleteMugshot(data.charId or data.id)
    elseif action == "global" then
        ok, err = setGlobalBrand(data.field or "logo", url)
    elseif action == "pause" then
        ok, err = setPauseTile(data.field, url)
    else
        return fail("Action inconnue.")
    end
    if not ok then return fail(err) end
    if action == "global" then
        local branding = globalBranding()
        branding.ok = true
        branding.message = "Enregistré. Le logo / la bannière s’applique tout de suite."
        return branding
    end
    if action == "pause" then
        return {
            ok = true,
            message = "Enregistré.",
            pauseTiles = pausePanel(),
        }
    end
    local out = panel()
    out.message = "Enregistré."
    return out
end)

-- Callbacks attendus par l'ancien image manager (NUI principale)
Staff29.Cb("vfw:server:getCdnItems", function(source)
    if not staffOk(source) then return {} end
    return listItems()
end)

Staff29.Cb("vfw:server:getCdnSocieties", function(source)
    if not staffOk(source) then return {} end
    return listSocieties()
end)

Staff29.Cb("vfw:server:getCdnFactions", function(source)
    if not staffOk(source) then return {} end
    return listFactions()
end)

Staff29.Cb("vfw:server:getMugshotsWithInfo", function(source)
    if not staffOk(source) then return {} end
    return listMugshots()
end)

Staff29.Cb("vfw:server:getCdnVehicles", function(source)
    if not staffOk(source) then return {} end
    if not (VFW.CDN and VFW.CDN.IsConfigured and VFW.CDN.IsConfigured() and VFW.CDN.List) then
        return {}
    end
    local ok, files = VFW.CDN.List("vehicles")
    if not ok or type(files) ~= "table" then return {} end
    local out = {}
    for i = 1, #files do
        local entry = files[i]
        local path = entry.path or entry.name or ""
        local stem = path:match("([^/]+)%.[^/%.]+$") or path:match("([^/]+)$") or path
        out[#out + 1] = {
            name = stem,
            model = stem,
            imageUrl = entry.url or resolveUrl(path),
            url = entry.url or resolveUrl(path),
        }
    end
    return out
end)

Staff29.Cb("vfw:server:updateSocietyImage", function(source, name, url)
    if not staffOk(source) then return false end
    local ok = setSocietyField(name, "image", url or "")
    return ok == true
end)

Staff29.Cb("vfw:server:updateFactionImage", function(source, name, url)
    if not staffOk(source) then return false end
    local ok = setFactionField(name, "image", url or "")
    return ok == true
end)

Staff29.Cb("vfw:server:deleteSocietyImage", function(source, name)
    if not staffOk(source) then return false end
    local ok = setSocietyField(name, "image", "")
    return ok == true
end)

Staff29.Cb("vfw:server:deleteFactionImage", function(source, name)
    if not staffOk(source) then return false end
    local ok = setFactionField(name, "image", "")
    return ok == true
end)

Staff29.Cb("vfw:server:deleteItemImage", function(source, name)
    if not staffOk(source) then return false end
    local ok = setItemImage(name, "")
    return ok == true
end)

Staff29.Cb("vfw:server:deleteMugshot", function(source, charId)
    if not staffOk(source) then return false end
    local ok = deleteMugshot(charId)
    return ok == true
end)

RegisterNetEvent("core:pausemenu:request", function()
    pushPauseImages(source)
end)

AddEventHandler("vfw:playerLoaded", function(playerId)
    pushPauseImages(playerId)
end)

CreateThread(function()
    Wait(4000)
    applyPersistedImages()
    pushPauseImages(-1)
end)

AddEventHandler("vfw:variables:loaded", function()
    applyPersistedImages()
end)
