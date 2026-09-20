-- ═══════════════════════════════════════════════════════════════
-- Outils développeur (Gestion > Développeurs) — côté serveur
--
-- Ces callbacks étaient appelés par les anciens menus VUI mais n'existaient
-- pas dans cette base. Stockage : table `variables` (VFW.Variables) pour les
-- petites configs, `logs_staff` pour les sanctions / confiscations,
-- `bag_categories` pour le poids des sacs.
--
--   antiban        vfw:antiban:list / add / remove          + VFW.IsAntiban(accountId)
--   cooldown       vfw:cooldown:*                            + VFW.CommandCooldownAllows (wrapper RegisterCommand, 000_command_cooldown.lua)
--   sanctions      vfw:staff:getSanctionsCount / resetPlayerSanctions
--   staffinv       vfw:staffinv:listCleans / getCleanDetail / restoreClean / markHandled
--   webhooks       vfw:webhooks:list / set / test / toggle / remove   (overrides lus par 024_logs.lua)
--   stafflogs      vfw:stafflogs:getRecent / clearRecent / getQueue / clearQueue / deleteQueue
--   bagweight      bagweight:getConfig / setWeight / removeWeight     (table bag_categories)
--   gpbplates      gpbplates:getConfig / setAllowed                   + VFW.GpbPlatesAllowed(sex, drawable)
--   starterpack    starterpack:getConfig / setBank / setCash / addItem / removeItem + VFW.GetStarterPack()
--   potions        vfw:dev:giveRestrictedItem
--   mappings       core:getAllMapCoords / createMapCoord / updateMapCoord / deleteMapCoord
-- ═══════════════════════════════════════════════════════════════

local function Var(name)
    local ok, data = pcall(VFW.Variables.GetVariable, name)
    if not ok or type(data) ~= "table" then return {} end
    return data
end

local function SaveVar(name, data)
    VFW.Variables.SetVariable(name, data)
end

local function Require(source, ...)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end
    if xPlayer.hasPermission("gestion") then return xPlayer end
    for i = 1, select("#", ...) do
        if xPlayer.hasPermission(select(i, ...)) then return xPlayer end
    end
    return nil
end

local function Clean(v, max)
    if type(v) ~= "string" then return nil end
    v = v:gsub("^%s+", ""):gsub("%s+$", "")
    if v == "" then return nil end
    return v:sub(1, max or 128)
end

local function AccountName(accountId)
    local row = Staff29.Single("SELECT name FROM users WHERE id = ?", { accountId })
    return row and row.name or nil
end

local function OnlineByAccount(accountId)
    for _, p in pairs(VFW.Players) do
        if tostring(p.accountId) == tostring(accountId) then return p end
    end
    return nil
end

local function Audit(source, action, payload)
    TriggerEvent("vfw:logs:staff", source, action, payload)
end

-- ═══════════════════════════════════════════════════════════════
-- Antiban : joueurs protégés contre kick / ban (vérifié par 298_sanctions.lua)
-- ═══════════════════════════════════════════════════════════════

function VFW.IsAntiban(accountId)
    if accountId == nil then return false end
    local data = Var("dev_antiban")
    return data[tostring(accountId)] ~= nil
end

local function AntibanList()
    local data = Var("dev_antiban")
    local out = {}
    for id, entry in pairs(data) do
        out[#out + 1] = { uniqueId = tonumber(id) or id, name = entry.name or ("UID " .. id), online = OnlineByAccount(id) ~= nil, by = entry.by, at = entry.at }
    end
    table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return out
end

Staff29.Cb("vfw:antiban:list", function(source)
    if not Require(source, "dev") then return {} end
    return AntibanList()
end)

Staff29.Cb("vfw:antiban:add", function(source, uniqueId)
    local xPlayer = Require(source, "dev")
    if not xPlayer then return { success = false, message = "Permission développeur requise." } end
    local id = tostring(math.floor(tonumber(uniqueId) or 0))
    if id == "0" then return { success = false, message = "Identifiant invalide." } end
    local name = AccountName(id)
    if not name then return { success = false, message = "Aucun compte avec cet ID unique." } end
    local data = Var("dev_antiban")
    if data[id] then return { success = false, message = name .. " est déjà protégé." } end
    data[id] = { name = name, by = xPlayer.name, at = os.time() }
    SaveVar("dev_antiban", data)
    Audit(source, "dev_antiban_add", { target = id, name = name })
    return { success = true, message = name .. " est maintenant protégé contre ban / kick." }
end)

Staff29.Cb("vfw:antiban:remove", function(source, uniqueId)
    if not Require(source, "dev") then return { success = false, message = "Permission développeur requise." } end
    local id = tostring(math.floor(tonumber(uniqueId) or 0))
    local data = Var("dev_antiban")
    if not data[id] then return { success = false, message = "Ce joueur n'est pas protégé." } end
    local name = data[id].name
    data[id] = nil
    SaveVar("dev_antiban", data)
    Audit(source, "dev_antiban_remove", { target = id, name = name })
    return { success = true, message = (name or "Le joueur") .. " n'est plus protégé." }
end)

-- ═══════════════════════════════════════════════════════════════
-- Cooldown des commandes serveur (voir endernative/server/000_command_cooldown.lua)
-- ═══════════════════════════════════════════════════════════════

Staff29.Cb("vfw:cooldown:getCommands", function(source)
    if not Require(source, "dev") then return {} end
    local cfg = Var("dev_cooldowns")
    local names = VFW.ListWrappedCommands and VFW.ListWrappedCommands() or {}
    local out = {}
    for _, name in ipairs(names) do
        local c = cfg[name] or {}
        out[#out + 1] = { name = name, cooldown = tonumber(c.cooldown) or 0, maxUses = tonumber(c.maxUses) or 0, usageCooldown = tonumber(c.usageCooldown) or 0 }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end)

Staff29.Cb("vfw:cooldown:updateCommand", function(source, name, field, value)
    if not Require(source, "dev") then return { success = false, message = "Permission développeur requise." } end
    name = Clean(name, 64)
    if not name then return { success = false, message = "Commande inconnue." } end
    if field ~= "cooldown" and field ~= "maxUses" and field ~= "usageCooldown" then return { success = false, message = "Champ inconnu." } end
    local v = math.floor(tonumber(value) or -1)
    if v < 0 then return { success = false, message = "Valeur invalide." } end
    local cfg = Var("dev_cooldowns")
    cfg[name] = cfg[name] or {}
    cfg[name][field] = v
    if (cfg[name].cooldown or 0) == 0 and (cfg[name].maxUses or 0) == 0 and (cfg[name].usageCooldown or 0) == 0 then
        cfg[name] = nil
    end
    SaveVar("dev_cooldowns", cfg)
    if VFW.ReloadCommandCooldowns then VFW.ReloadCommandCooldowns() end
    Audit(source, "dev_cooldown_update", { command = name, field = field, value = v })
    return { success = true, message = ("/%s : %s = %d"):format(name, field, v) }
end)

Staff29.Cb("vfw:cooldown:listBypasses", function(source)
    if not Require(source, "dev") then return {} end
    local data = Var("dev_cooldown_bypass")
    local out = {}
    for id, entry in pairs(data) do
        out[#out + 1] = { uniqueId = tonumber(id) or id, name = entry.name or ("UID " .. id), online = OnlineByAccount(id) ~= nil }
    end
    table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return out
end)

Staff29.Cb("vfw:cooldown:addBypass", function(source, uniqueId)
    local xPlayer = Require(source, "dev")
    if not xPlayer then return { success = false, message = "Permission développeur requise." } end
    local id = tostring(math.floor(tonumber(uniqueId) or 0))
    local name = AccountName(id)
    if not name then return { success = false, message = "Aucun compte avec cet ID unique." } end
    local data = Var("dev_cooldown_bypass")
    if data[id] then return { success = false, message = name .. " a déjà un bypass." } end
    data[id] = { name = name, by = xPlayer.name, at = os.time() }
    SaveVar("dev_cooldown_bypass", data)
    if VFW.ReloadCommandCooldowns then VFW.ReloadCommandCooldowns() end
    return { success = true, message = name .. " ignore désormais les cooldowns." }
end)

Staff29.Cb("vfw:cooldown:removeBypass", function(source, uniqueId)
    if not Require(source, "dev") then return { success = false, message = "Permission développeur requise." } end
    local id = tostring(math.floor(tonumber(uniqueId) or 0))
    local data = Var("dev_cooldown_bypass")
    if not data[id] then return { success = false, message = "Aucun bypass pour cet ID." } end
    local name = data[id].name
    data[id] = nil
    SaveVar("dev_cooldown_bypass", data)
    if VFW.ReloadCommandCooldowns then VFW.ReloadCommandCooldowns() end
    return { success = true, message = (name or "Le joueur") .. " est de nouveau soumis aux cooldowns." }
end)

-- ═══════════════════════════════════════════════════════════════
-- Sanctions : comptage et reset complet (logs_staff, actions sanction_*)
-- ═══════════════════════════════════════════════════════════════

local SANCTION_ACTIONS = { warns = "sanction_warn", kicks = "sanction_kick", bans = "sanction_ban", tigs = "sanction_tig", tigWeapons = "sanction_tigweapon" }

local function AccountFilter(accountId)
    local escaped = tostring(accountId):gsub("[%%_\\]", "\\%0")
    return ("%%\"accountId\":\"%s\"%%"):format(escaped)
end

Staff29.Cb("vfw:staff:getSanctionsCount", function(source, accountId)
    if not Require(source, "dev") then return {} end
    accountId = tostring(accountId or "")
    if accountId == "" then return {} end
    local out = {}
    for key, action in pairs(SANCTION_ACTIONS) do
        out[key] = tonumber(Staff29.Scalar("SELECT COUNT(*) FROM logs_staff WHERE action = ? AND payload LIKE ?", { action, AccountFilter(accountId) }, 0)) or 0
    end
    return out
end)

Staff29.Cb("vfw:staff:resetPlayerSanctions", function(source, accountId)
    local xPlayer = Require(source, "dev")
    if not xPlayer then return { success = false, message = "Permission développeur requise." } end
    accountId = tostring(accountId or "")
    if accountId == "" then return { success = false, message = "Joueur inconnu." } end

    local deleted = 0
    for _, action in pairs(SANCTION_ACTIONS) do
        deleted = deleted + (tonumber(Staff29.Update("DELETE FROM logs_staff WHERE action = ? AND payload LIKE ?", { action, AccountFilter(accountId) })) or 0)
    end

    -- Lever le flag ban sauf ban anticheat
    local identifier = Staff29.Scalar("SELECT identifier FROM users WHERE id = ?", { accountId })
    local acBans = identifier and tonumber(Staff29.Scalar("SELECT COUNT(*) FROM anticheat_bans WHERE license = ?", { identifier }, 0)) or 0
    if (acBans or 0) == 0 then
        Staff29.Update("UPDATE users SET banned = 0 WHERE id = ?", { accountId })
    end

    Audit(source, "dev_reset_sanctions", { target = accountId, deleted = deleted })
    return { success = true, deleted = deleted }
end)

-- ═══════════════════════════════════════════════════════════════
-- Restauration d'inventaire : snapshots `items_clean` de logs_staff (10 jours)
-- ═══════════════════════════════════════════════════════════════

local RESTORE_DAYS = 10

local function CleanRows(status)
    local rows = Staff29.Query(([[
        SELECT l.id, l.source_id, l.payload, UNIX_TIMESTAMP(l.created_at) AS created, u.name AS staff_name
        FROM logs_staff l
        LEFT JOIN characters c ON c.id = l.char_id
        LEFT JOIN users u ON u.id = c.account_id
        WHERE l.action = 'items_clean' AND l.created_at >= DATE_SUB(NOW(), INTERVAL %d DAY)
        ORDER BY l.id DESC LIMIT 200
    ]]):format(RESTORE_DAYS), {}) or {}
    local out = {}
    local now = os.time()
    for i = 1, #rows do
        local row = rows[i]
        local p = Staff29.Decode(row.payload, nil)
        if type(p) == "table" then
            local st = p.status or "pending"
            if not status or st == status then
                local uid = Staff29.Scalar("SELECT account_id FROM characters WHERE identifier = ?", { p.identifier })
                out[#out + 1] = {
                    id = row.id,
                    status = st,
                    target_name = p.name,
                    target_uid = uid or "?",
                    identifier = p.identifier,
                    item_count = type(p.removed) == "table" and #p.removed or 0,
                    staff_name = row.staff_name or p.staffName or "?",
                    created_age_sec = now - (tonumber(row.created) or now),
                    restored_by_name = p.restoredBy,
                }
            end
        end
    end
    return out
end

Staff29.Cb("vfw:staffinv:listCleans", function(source, status)
    if not Require(source, "restore_inventory") then return {} end
    return CleanRows(type(status) == "string" and status or nil)
end)

local function ReadClean(id)
    local row = Staff29.Single("SELECT id, payload, UNIX_TIMESTAMP(created_at) AS created FROM logs_staff WHERE id = ? AND action = 'items_clean'", { tonumber(id) or 0 })
    if not row then return nil end
    local p = Staff29.Decode(row.payload, nil)
    if type(p) ~= "table" then return nil end
    return row, p
end

Staff29.Cb("vfw:staffinv:getCleanDetail", function(source, id)
    if not Require(source, "restore_inventory") then return nil end
    local row, p = ReadClean(id)
    if not row then return nil end
    local items = {}
    for _, it in ipairs(p.removed or {}) do
        local def = VFW.Items and VFW.Items[it.name]
        items[#items + 1] = { name = it.name, count = it.count, label = def and def.label or it.name, meta = it.meta }
    end
    local uid = Staff29.Scalar("SELECT account_id FROM characters WHERE identifier = ?", { p.identifier })
    return {
        id = row.id, status = p.status or "pending", target_name = p.name, target_uid = uid or "?", identifier = p.identifier,
        staff_name = p.staffName or "?", created_age_sec = os.time() - (tonumber(row.created) or os.time()),
        restored_by_name = p.restoredBy, items = items,
    }
end)

Staff29.Cb("vfw:staffinv:restoreClean", function(source, id)
    local xPlayer = Require(source, "restore_inventory")
    if not xPlayer then return { success = false, message = "Permission restore_inventory requise." } end
    local row, p = ReadClean(id)
    if not row then return { success = false, message = "Snapshot introuvable." } end
    if (p.status or "pending") ~= "pending" then return { success = false, message = "Snapshot déjà clôturé." } end

    local target = VFW.PlayersByIdentifier and VFW.PlayersByIdentifier[p.identifier] or nil
    if not target then
        return { success = false, message = "Le joueur doit être connecté sur ce personnage pour la restauration." }
    end

    local given = 0
    for _, it in ipairs(p.removed or {}) do
        if type(it.name) == "string" and (tonumber(it.count) or 0) > 0 and VFW.Items[it.name] then
            target.addInventoryItem(it.name, math.floor(tonumber(it.count)), it.meta, false)
            given = given + 1
        end
    end

    p.status = "restored"
    p.restoredBy = xPlayer.name
    p.restoredAt = os.time()
    Staff29.Update("UPDATE logs_staff SET payload = ? WHERE id = ?", { Staff29.Encode(p), row.id })
    Audit(source, "dev_inventory_restore", { snapshot = row.id, target = p.identifier, items = given })
    return { success = true, message = ("%d item%s restauré%s à %s."):format(given, given > 1 and "s" or "", given > 1 and "s" or "", p.name or "?") }
end)

Staff29.Cb("vfw:staffinv:markHandled", function(source, id)
    local xPlayer = Require(source, "restore_inventory")
    if not xPlayer then return { success = false, message = "Permission restore_inventory requise." } end
    local row, p = ReadClean(id)
    if not row then return { success = false, message = "Snapshot introuvable." } end
    if (p.status or "pending") ~= "pending" then return { success = false, message = "Snapshot déjà clôturé." } end
    p.status = "handled"
    p.handledBy = xPlayer.name
    Staff29.Update("UPDATE logs_staff SET payload = ? WHERE id = ?", { Staff29.Encode(p), row.id })
    return { success = true, message = "Snapshot marqué comme traité." }
end)

-- ═══════════════════════════════════════════════════════════════
-- Webhooks Discord : surcharge des chemins de logs.config (024_logs.lua)
-- ═══════════════════════════════════════════════════════════════

local WEBHOOK_GROUP_LABELS = { general = "Général", reports = "Reports", society = "Sociétés", banking = "Banque", staff = "Staff", ac = "Anticheat" }

local function WebhookPaths()
    local out = {}
    if type(logs) ~= "table" or type(logs.config) ~= "table" then return out end
    local groups = {}
    for g in pairs(logs.config) do groups[#groups + 1] = g end
    table.sort(groups)
    for _, g in ipairs(groups) do
        local node = logs.config[g]
        if type(node) == "table" then
            local keys = {}
            for k, v in pairs(node) do if type(v) == "string" then keys[#keys + 1] = k end end
            table.sort(keys)
            for _, k in ipairs(keys) do
                out[#out + 1] = { category = g .. "." .. k, group = g, key = k, label = (WEBHOOK_GROUP_LABELS[g] or g) .. " · " .. k, default = node[k] }
            end
        end
    end
    return out
end

function VFW.GetWebhookOverride(path)
    local data = Var("dev_webhooks")
    local entry = data[path]
    if type(entry) ~= "table" then return nil end
    if entry.enabled == false then return "" end -- désactivé explicitement
    if type(entry.url) == "string" and entry.url ~= "" then return entry.url end
    return nil
end

Staff29.Cb("vfw:webhooks:list", function(source)
    if not Require(source, "dev") then return {} end
    local overrides = Var("dev_webhooks")
    local out = {}
    for _, p in ipairs(WebhookPaths()) do
        local ov = overrides[p.category]
        local url = (ov and ov.url and ov.url ~= "") and ov.url or (p.default ~= "" and p.default or "")
        out[#out + 1] = { category = p.category, label = p.label, url = url, enabled = ov and ov.enabled ~= false or (url ~= "" and not ov), fromConfig = not (ov and ov.url and ov.url ~= "") and p.default ~= "" }
    end
    return out
end)

Staff29.Cb("vfw:webhooks:set", function(source, category, url)
    if not Require(source, "dev") then return false, "Permission développeur requise." end
    category = Clean(category, 64)
    url = Clean(url, 512)
    if not category or not url then return false, "Catégorie ou URL manquante." end
    if not url:match("^https://discord%.com/api/webhooks/") and not url:match("^https://discordapp%.com/api/webhooks/") then
        return false, "URL de webhook Discord invalide."
    end
    local data = Var("dev_webhooks")
    data[category] = { url = url, enabled = true }
    SaveVar("dev_webhooks", data)
    Audit(source, "dev_webhook_set", { category = category })
    return true
end)

Staff29.Cb("vfw:webhooks:toggle", function(source, category, enabled)
    if not Require(source, "dev") then return false end
    category = Clean(category, 64)
    if not category then return false end
    local data = Var("dev_webhooks")
    data[category] = data[category] or {}
    data[category].enabled = enabled == true
    SaveVar("dev_webhooks", data)
    return true
end)

Staff29.Cb("vfw:webhooks:remove", function(source, category)
    if not Require(source, "dev") then return false end
    category = Clean(category, 64)
    if not category then return false end
    local data = Var("dev_webhooks")
    -- Supprimer = plus d'URL et désactivé (même si logs.config en définit une)
    data[category] = { url = "", enabled = false }
    SaveVar("dev_webhooks", data)
    Audit(source, "dev_webhook_remove", { category = category })
    return true
end)

Staff29.Cb("vfw:webhooks:test", function(source, category)
    if not Require(source, "dev") then return false, "Permission développeur requise." end
    category = Clean(category, 64)
    if not category then return false, "Catégorie manquante." end
    if not VFW.Logs or not VFW.Logs.Send then return false, "Module logs indisponible." end
    local ok = VFW.Logs.Send(category, {
        title = "Test de webhook",
        description = ("Catégorie `%s` — envoyé par %s"):format(category, VFW.Logs.Describe(source)),
        color = 3066993,
    })
    if not ok then return false, "Aucune URL active pour cette catégorie." end
    return true
end)

-- ═══════════════════════════════════════════════════════════════
-- Staff logs : derniers envois + échecs (alimenté par 024_logs.lua)
-- ═══════════════════════════════════════════════════════════════

Staff29.Cb("vfw:stafflogs:getRecent", function(source)
    if not Require(source, "staff_logs") then return {} end
    return VFW.Logs and VFW.Logs.Recent and VFW.Logs.Recent() or {}
end)

Staff29.Cb("vfw:stafflogs:clearRecent", function(source)
    if not Require(source, "staff_logs") then return false end
    if VFW.Logs and VFW.Logs.ClearRecent then VFW.Logs.ClearRecent() end
    return true
end)

Staff29.Cb("vfw:stafflogs:getQueue", function(source)
    if not Require(source, "staff_logs") then return {}, nil end
    if not VFW.Logs or not VFW.Logs.Queue then return {}, nil end
    return VFW.Logs.Queue()
end)

Staff29.Cb("vfw:stafflogs:clearQueue", function(source)
    if not Require(source, "staff_logs") then return false end
    if VFW.Logs and VFW.Logs.ClearQueue then VFW.Logs.ClearQueue() end
    return true
end)

Staff29.Cb("vfw:stafflogs:deleteQueue", function(source, index)
    if not Require(source, "staff_logs") then return false end
    if VFW.Logs and VFW.Logs.DeleteQueued then VFW.Logs.DeleteQueued(index) end
    return true
end)

-- ═══════════════════════════════════════════════════════════════
-- Poids des sacs : table bag_categories (capacité par drawable / sexe)
-- ═══════════════════════════════════════════════════════════════

local function BagSex(sex)
    return (sex == "f" or sex == "w" or sex == "female") and "w" or "m"
end

Staff29.Cb("bagweight:getConfig", function(source)
    if not Require(source, "dev") then return {} end
    local rows = Staff29.Query("SELECT sex, drawable_id, capacity FROM bag_categories", {}) or {}
    local out = {}
    for i = 1, #rows do
        local r = rows[i]
        local sexKey = BagSex(r.sex) == "w" and "f" or "m"
        out[sexKey .. "_" .. tostring(r.drawable_id)] = tonumber(r.capacity) or 0
    end
    return out
end)

Staff29.Cb("bagweight:setWeight", function(source, sex, drawableId, weight)
    if not Require(source, "dev") then return false end
    local s = BagSex(sex)
    local d = math.floor(tonumber(drawableId) or -1)
    local w = math.floor(tonumber(weight) or -1)
    if d < 0 or w < 0 then return false end
    local existing = Staff29.Single("SELECT id FROM bag_categories WHERE sex = ? AND drawable_id = ?", { s, d })
    if existing then
        Staff29.Update("UPDATE bag_categories SET capacity = ? WHERE id = ?", { w, existing.id })
    else
        Staff29.Insert("INSERT INTO bag_categories (label, sex, drawable_id, capacity) VALUES (?, ?, ?, ?)", { ("Sac #%d"):format(d), s, d, w })
    end
    if VFW.Inventory and VFW.Inventory.ReloadBagCategories then VFW.Inventory.ReloadBagCategories() end
    Audit(source, "dev_bag_weight", { sex = s, drawable = d, weight = w })
    return true
end)

Staff29.Cb("bagweight:removeWeight", function(source, sex, drawableId)
    if not Require(source, "dev") then return false end
    local s = BagSex(sex)
    local d = math.floor(tonumber(drawableId) or -1)
    if d < 0 then return false end
    Staff29.Update("DELETE FROM bag_categories WHERE sex = ? AND drawable_id = ?", { s, d })
    if VFW.Inventory and VFW.Inventory.ReloadBagCategories then VFW.Inventory.ReloadBagCategories() end
    return true
end)

-- ═══════════════════════════════════════════════════════════════
-- Plaques GPB : autorisation par drawable (vérifié à l'équipement d'une plaque)
-- ═══════════════════════════════════════════════════════════════

function VFW.GpbPlatesAllowed(sex, drawableId)
    local data = Var("dev_gpb_plates")
    local key = (BagSex(sex) == "w" and "f" or "m") .. "_" .. tostring(math.floor(tonumber(drawableId) or 0))
    return data[key] ~= false
end

Staff29.Cb("gpbplates:getConfig", function(source)
    if not Require(source, "dev") then return {} end
    return Var("dev_gpb_plates")
end)

Staff29.Cb("gpbplates:setAllowed", function(source, sex, drawableId, allowed)
    if not Require(source, "dev") then return false end
    local key = (BagSex(sex) == "w" and "f" or "m") .. "_" .. tostring(math.floor(tonumber(drawableId) or 0))
    local data = Var("dev_gpb_plates")
    if allowed == true then data[key] = nil else data[key] = false end
    SaveVar("dev_gpb_plates", data)
    return true
end)

-- ═══════════════════════════════════════════════════════════════
-- Starter pack : argent + items des nouveaux personnages (utilisé par VFW.DB.CreateCharacter)
-- ═══════════════════════════════════════════════════════════════

function VFW.GetStarterPack()
    local data = Var("dev_starterpack")
    if next(data) == nil then return nil end
    return data
end

local function StarterConfig()
    local data = Var("dev_starterpack")
    return {
        bank = tonumber(data.bank) or (Config.StartingAccountMoney and Config.StartingAccountMoney.bank) or 0,
        cash = tonumber(data.cash) or (Config.StartingAccountMoney and Config.StartingAccountMoney.money) or 0,
        items = type(data.items) == "table" and data.items or {},
    }
end

Staff29.Cb("starterpack:getConfig", function(source)
    if not Require(source, "dev") then return nil end
    return StarterConfig()
end)

local function StarterSave(mutator)
    local data = Var("dev_starterpack")
    data.items = type(data.items) == "table" and data.items or {}
    mutator(data)
    SaveVar("dev_starterpack", data)
end

Staff29.Cb("starterpack:setBank", function(source, amount)
    if not Require(source, "dev") then return false end
    local v = math.floor(tonumber(amount) or -1); if v < 0 then return false end
    StarterSave(function(d) d.bank = v end)
    Audit(source, "dev_starterpack", { bank = v })
    return true
end)

Staff29.Cb("starterpack:setCash", function(source, amount)
    if not Require(source, "dev") then return false end
    local v = math.floor(tonumber(amount) or -1); if v < 0 then return false end
    StarterSave(function(d) d.cash = v end)
    Audit(source, "dev_starterpack", { cash = v })
    return true
end)

Staff29.Cb("starterpack:addItem", function(source, name, count)
    if not Require(source, "dev") then return false end
    name = Clean(name, 64)
    local c = math.floor(tonumber(count) or 0)
    if not name or not VFW.Items[name] or c <= 0 then return false end
    StarterSave(function(d)
        for _, it in ipairs(d.items) do
            if it.name == name then it.count = c return end
        end
        d.items[#d.items + 1] = { name = name, count = c }
    end)
    return true
end)

Staff29.Cb("starterpack:removeItem", function(source, name)
    if not Require(source, "dev") then return false end
    StarterSave(function(d)
        for i = #d.items, 1, -1 do
            if d.items[i].name == name then table.remove(d.items, i) end
        end
    end)
    return true
end)

-- ═══════════════════════════════════════════════════════════════
-- Potions : donner un item restreint à un joueur
-- ═══════════════════════════════════════════════════════════════

Staff29.Cb("vfw:dev:giveRestrictedItem", function(source, data)
    if not Require(source, "dev") then return { success = false, message = "Permission développeur requise." } end
    if type(data) ~= "table" then return { success = false, message = "Données invalides." } end
    local item = Clean(data.item, 64)
    if not item or not VFW.Items[item] or not item:match("^potion_%d+$") then return { success = false, message = "Item non autorisé." } end
    local amount = math.floor(tonumber(data.amount) or 0)
    if amount <= 0 or amount > 100 then return { success = false, message = "Quantité invalide (1-100)." } end
    local target = VFW.GetPlayerFromId(tonumber(data.targetId))
    if not target then return { success = false, message = "Joueur introuvable." } end
    target.addInventoryItem(item, amount, nil, true)
    Audit(source, "dev_give_potion", { target = target.source, item = item, amount = amount })
    return { success = true, message = ("%d× %s donné%s à %s."):format(amount, VFW.Items[item].label or item, amount > 1 and "s" or "", target.name or ("#" .. target.source)) }
end)

-- ═══════════════════════════════════════════════════════════════
-- Mappings de la carte (registre développeur)
-- ═══════════════════════════════════════════════════════════════

local MAP_TYPES = { legal = true, illegal = true, other = true }

Staff29.Cb("core:getAllMapCoords", function(source)
    if not Require(source, "dev") then return {} end
    local data = Var("dev_map_coords")
    return type(data.list) == "table" and data.list or {}
end)

local function MapSave(mutator)
    local data = Var("dev_map_coords")
    data.list = type(data.list) == "table" and data.list or {}
    data.nextId = tonumber(data.nextId) or 1
    mutator(data)
    SaveVar("dev_map_coords", data)
end

local function CleanPos(pos)
    if type(pos) ~= "table" then return nil end
    local x, y, z = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

RegisterNetEvent("core:createMapCoord", function(payload)
    local source = source
    if not Require(source, "dev") or type(payload) ~= "table" then return end
    local name = Clean(payload.name, 64)
    local pos = CleanPos(payload.position)
    if not name or not pos then return end
    MapSave(function(d)
        d.list[#d.list + 1] = { id = d.nextId, name = name, type = MAP_TYPES[payload.type] and payload.type or "legal", position = pos, by = VFW.GetPlayerFromId(source).name, at = os.time() }
        d.nextId = d.nextId + 1
    end)
end)

RegisterNetEvent("core:updateMapCoord", function(id, payload)
    local source = source
    if not Require(source, "dev") or type(payload) ~= "table" then return end
    local name = Clean(payload.name, 64)
    local pos = CleanPos(payload.position)
    if not name or not pos then return end
    MapSave(function(d)
        for _, m in ipairs(d.list) do
            if m.id == tonumber(id) then
                m.name, m.position = name, pos
                m.type = MAP_TYPES[payload.type] and payload.type or m.type
            end
        end
    end)
end)

RegisterNetEvent("core:deleteMapCoord", function(id)
    local source = source
    if not Require(source, "dev") then return end
    MapSave(function(d)
        for i = #d.list, 1, -1 do
            if d.list[i].id == tonumber(id) then table.remove(d.list, i) end
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════
-- Gestion téléphone : cette base n'embarque pas de ressource téléphone
-- (lb-phone absent) ; la liste des numéros fonctionne (character_phones),
-- les actions sur le contenu répondent explicitement au staff.
-- ═══════════════════════════════════════════════════════════════

local function PhoneUnavailable(source)
    local state = GetResourceState("lb-phone")
    Staff29.Notify(source, "ERROR", "Gestion téléphone",
        state == "started" and "Intégration du contenu téléphone non configurée sur cette base."
        or "Aucune ressource téléphone (lb-phone) installée : rien à supprimer.")
end

RegisterNetEvent("vfw:staff:phone:wipeApp", function()
    local source = source
    if not Require(source, "wipe") then return end
    PhoneUnavailable(source)
end)

RegisterNetEvent("vfw:staff:phone:deleteHistoryItems", function()
    local source = source
    if not Require(source, "wipe") then return end
    PhoneUnavailable(source)
end)

RegisterNetEvent("vfw:staff:phone:setCertif", function()
    local source = source
    if not Require(source, "wipe") then return end
    PhoneUnavailable(source)
end)
