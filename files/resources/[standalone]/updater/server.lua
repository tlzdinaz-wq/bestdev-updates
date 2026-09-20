--[[
    Updater — met la base à jour depuis la console serveur (Lua : le runtime Node de
    FXServer n'autorise plus l'accès disque hors du dossier de la ressource).

      update            vérifie puis applique (télécharge uniquement les fichiers modifiés)
      update check      liste ce qui changerait, sans rien toucher
      update force      applique en écrasant aussi les fichiers modifiés localement
      update restart    applique puis redémarre les ressources touchées
      update version    version installée / disponible

    Hébergement (convar update_url) :
      <update_url>/manifest.json   { version, date, notes, protected, files = { [chemin] = { h = sha256, s = taille } } }
      <update_url>/files/<chemin>  contenu de chaque fichier

    Un fichier modifié localement (hash ≠ version installée, state.json) n'est jamais écrasé
    sans `force` : la nouvelle version est posée à côté en `.new`. Les fichiers « protégés »
    du manifest (configs, images) suivent la même règle quand l'état est inconnu et ne sont
    jamais supprimés. Les fichiers remplacés sont copiés dans backup/<version>/.
    server.cfg et permissions.cfg ne sont jamais touchés ; seul resources/ est géré.
]]

local RES = GetCurrentResourceName()
-- GetResourcePath peut renvoyer "…/resources//[standalone]/updater" : on normalise les slashs
local RES_DIR = GetResourcePath(RES):gsub("\\", "/"):gsub("/+", "/"):gsub("/+$", "")
local STATE_FILE = "state.json"
local NEVER = { ["server.cfg"] = true, ["permissions.cfg"] = true }
local NO_RESTART = { updater = true, oxmysql = true, ox_lib = true, monitor = true }
local CONCURRENCY = 4
-- pas de `package` dans le Lua de FXServer : on détecte Windows au chemin (lettre de lecteur / antislash)
local RAW_DIR = GetResourcePath(RES)
local IS_WINDOWS = RAW_DIR:match("^%a:") ~= nil or RAW_DIR:find("\\", 1, true) ~= nil

local function log(msg) print("^5[update]^7 " .. msg) end
local function warn(msg) print("^3[update]^7 " .. msg) end
local function err(msg) print("^1[update]^7 " .. msg) end

-- Racine du serveur = dossier qui contient `resources`
local function serverRoot()
    local dir = RES_DIR
    for _ = 1, 6 do
        local parent, name = dir:match("^(.*)/([^/]+)$")
        if not parent then break end
        if name == "resources" then return parent end
        dir = parent
    end
    error("dossier resources introuvable depuis " .. RES_DIR)
end

-- ── SHA-256 (Lua 5.4, entiers 64 bits) ────────────────────────────
local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}
local M32 = 0xffffffff
local function rrot(x, n) return ((x >> n) | (x << (32 - n))) & M32 end

local function sha256(data)
    local len = #data
    data = data .. "\128" .. string.rep("\0", (55 - len) % 64) .. string.pack(">I8", len * 8)
    local h0, h1, h2, h3 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
    local h4, h5, h6, h7 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    local w = {}
    local unpack = string.unpack
    local n = 0
    for chunk = 1, #data, 64 do
        -- ~3 Mo/s en Lua pur : on rend la main au serveur tous les 16 Ko pour ne pas bloquer le tick
        n = n + 1
        if Wait and (n & 255) == 0 then Wait(0) end
        for i = 0, 15 do w[i] = unpack(">I4", data, chunk + i * 4) end
        for i = 16, 63 do
            local w15, w2 = w[i - 15], w[i - 2]
            local s0 = rrot(w15, 7) ~ rrot(w15, 18) ~ (w15 >> 3)
            local s1 = rrot(w2, 17) ~ rrot(w2, 19) ~ (w2 >> 10)
            w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & M32
        end
        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
        for i = 0, 63 do
            local S1 = rrot(e, 6) ~ rrot(e, 11) ~ rrot(e, 25)
            local ch = (e & f) ~ ((~e) & g)
            local t1 = (h + S1 + ch + K[i + 1] + w[i]) & M32
            local S0 = rrot(a, 2) ~ rrot(a, 13) ~ rrot(a, 22)
            local maj = (a & b) ~ (a & c) ~ (b & c)
            local t2 = (S0 + maj) & M32
            h, g, f, e, d, c, b, a = g, f, e, (d + t1) & M32, c, b, a, (t1 + t2) & M32
        end
        h0, h1, h2, h3 = (h0 + a) & M32, (h1 + b) & M32, (h2 + c) & M32, (h3 + d) & M32
        h4, h5, h6, h7 = (h4 + e) & M32, (h5 + f) & M32, (h6 + g) & M32, (h7 + h) & M32
    end
    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
end

-- ── fichiers ──────────────────────────────────────────────────────
local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("a")
    f:close()
    return data
end

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end

local function quote(path)
    if IS_WINDOWS then return '"' .. path:gsub("/", "\\") .. '"' end
    return "'" .. path:gsub("'", "'\\''") .. "'"
end

local function mkdirp(dir)
    if not os.execute then return end
    if IS_WINDOWS then
        os.execute('if not exist ' .. quote(dir) .. ' mkdir ' .. quote(dir) .. ' >nul 2>&1')
    else
        os.execute("mkdir -p " .. quote(dir) .. " >/dev/null 2>&1")
    end
end

local function writeFile(path, data)
    local dir = path:match("^(.*)/[^/]+$")
    if dir then mkdirp(dir) end
    local tmp = path .. ".updtmp"
    local f = io.open(tmp, "wb")
    if not f then return false, "ouverture impossible" end
    local ok = f:write(data)
    f:close()
    if not ok then os.remove(tmp) return false, "écriture impossible" end
    os.remove(path)
    local moved, mvErr = os.rename(tmp, path)
    if not moved then os.remove(tmp) return false, tostring(mvErr) end
    return true
end

local function copyFile(src, dst)
    local data = readFile(src)
    if not data then return false end
    return (writeFile(dst, data))
end

local function safeRel(rel)
    if type(rel) ~= "string" then return nil end
    rel = rel:gsub("\\", "/")
    if rel == "" or rel:sub(1, 1) == "/" or rel:match("^%a:") then return nil end
    for seg in rel:gmatch("[^/]+") do
        if seg == ".." then return nil end
    end
    if rel:sub(1, 10) ~= "resources/" then return nil end
    return rel
end

local function resourceOf(rel)
    local rest = rel:sub(11)
    for seg in rest:gmatch("[^/]+") do
        if seg:sub(1, 1) ~= "[" then return seg end
    end
    return nil
end

-- glob (`*` dans un segment, `**` = zéro ou plusieurs segments) contre un chemin
local function split(s)
    local out = {}
    for seg in s:gmatch("[^/]+") do out[#out + 1] = seg end
    return out
end
local function segMatch(pat, seg)
    local lp = "^" .. pat:gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0"):gsub("%*", ".*") .. "$"
    return seg:match(lp) ~= nil
end
local function globMatch(pattern, path)
    local ps, ss = split(pattern), split(path)
    local function rec(pi, si)
        if pi > #ps then return si > #ss end
        if ps[pi] == "**" then
            for k = si, #ss + 1 do
                if rec(pi + 1, k) then return true end
            end
            return false
        end
        if si > #ss then return false end
        if not segMatch(ps[pi], ss[si]) then return false end
        return rec(pi + 1, si + 1)
    end
    return rec(1, 1)
end
local function isProtected(rel, patterns)
    for _, p in ipairs(patterns or {}) do
        if globMatch(p, rel) then return true end
    end
    return false
end

-- ── état installé ─────────────────────────────────────────────────
local function readState()
    local raw = LoadResourceFile(RES, STATE_FILE)
    if not raw or raw == "" then return nil end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" then return data end
    return nil
end

local function writeState(state)
    SaveResourceFile(RES, STATE_FILE, json.encode(state), -1)
end

-- ── HTTP ──────────────────────────────────────────────────────────
local function httpGet(url)
    local p = promise.new()
    local done = false
    PerformHttpRequest(url, function(status, body)
        if done then return end
        done = true
        p:resolve({ status = status, body = body })
    end, "GET", "", { ["User-Agent"] = "bestdev-updater/2.0", ["Cache-Control"] = "no-cache" })
    SetTimeout(120000, function()
        if done then return end
        done = true
        p:resolve({ status = 0, body = nil })
    end)
    return Citizen.Await(p)
end

local function encodePath(rel)
    return (rel:gsub("[^%w%-%._~/]", function(c) return string.format("%%%02X", c:byte()) end))
end

-- GitHub : raw.githubusercontent.com met la branche en cache plusieurs minutes ; on lit
-- tout depuis le commit courant (URL immuable) obtenu via l'API.
local function resolveBase(base)
    local user, repo, branch = base:match("^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/?$")
    if not user then return base end
    local r = httpGet(("https://api.github.com/repos/%s/%s/commits/%s"):format(user, repo, branch))
    if r.status == 200 and r.body then
        local ok, info = pcall(json.decode, r.body)
        if ok and type(info) == "table" and type(info.sha) == "string" and info.sha:match("^%x+$") and #info.sha == 40 then
            return ("https://raw.githubusercontent.com/%s/%s/%s"):format(user, repo, info.sha)
        end
    end
    warn("API GitHub indisponible (HTTP " .. tostring(r.status) .. ") : lecture directe de la branche, un cache de quelques minutes est possible.")
    return base
end

-- ── planification ─────────────────────────────────────────────────
local function plan(manifest, state, force, root)
    local out = { download = {}, skipped = {}, deleted = {}, keep = {}, same = {}, pendingNew = {}, unchanged = 0 }
    local files = manifest.files or {}
    local known = (state and state.files) or {}

    local rels = {}
    for rel in pairs(files) do rels[#rels + 1] = rel end
    table.sort(rels)

    for _, rel in ipairs(rels) do
        local safe = safeRel(rel)
        local base = safe and safe:match("([^/]+)$")
        if safe and not NEVER[base] then
            local remote = files[rel]
            local abs = root .. "/" .. safe
            local installed = known[rel]
            local localHash = nil
            if fileExists(abs) then
                -- hash local seulement si la version publiée diffère de la version installée
                -- (ou si l'état est inconnu) : les fichiers inchangés ne sont pas relus
                if installed == remote.h then
                    localHash = remote.h
                else
                    local data = readFile(abs)
                    localHash = data and sha256(data) or nil
                end
            end
            if localHash == remote.h then
                out.unchanged = out.unchanged + 1
                out.same[#out.same + 1] = { rel = safe, h = remote.h }
            else
                local modified = localHash ~= nil and installed ~= nil and localHash ~= installed
                local unknownProtected = localHash ~= nil and installed == nil and isProtected(safe, manifest.protected)
                if not force and (modified or unknownProtected) then
                    local pending = false
                    if fileExists(abs .. ".new") then
                        local d = readFile(abs .. ".new")
                        pending = d ~= nil and sha256(d) == remote.h
                    end
                    if pending then
                        out.pendingNew[#out.pendingNew + 1] = safe
                    else
                        out.skipped[#out.skipped + 1] = { rel = safe, remote = remote, reason = modified and "modifié localement" or "fichier protégé (état inconnu)" }
                    end
                else
                    out.download[#out.download + 1] = { rel = safe, remote = remote, existed = localHash ~= nil }
                end
            end
        end
    end

    -- présents dans l'état installé, absents du manifest → supprimés par la mise à jour
    for rel, h in pairs(known) do
        if not files[rel] then
            local safe = safeRel(rel)
            if safe and not isProtected(safe, manifest.protected) then
                local abs = root .. "/" .. safe
                if fileExists(abs) then
                    local data = readFile(abs)
                    local localHash = data and sha256(data) or nil
                    if force or localHash == h then
                        out.deleted[#out.deleted + 1] = safe
                    else
                        out.keep[#out.keep + 1] = safe
                    end
                end
            end
        end
    end
    return out
end

local function fmtSize(n)
    if n > 1048576 then return string.format("%.1f Mo", n / 1048576) end
    if n > 1024 then return string.format("%d Ko", n // 1024) end
    return n .. " o"
end

-- exécute worker(item) sur la liste avec CONCURRENCY threads
local function runPool(items, worker)
    local errors = {}
    local nextIdx, active = 1, 0
    local p = promise.new()
    local total = #items
    if total == 0 then return errors end
    local function launch()
        while active < CONCURRENCY and nextIdx <= total do
            local item = items[nextIdx]
            nextIdx = nextIdx + 1
            active = active + 1
            CreateThread(function()
                local ok, e = pcall(worker, item)
                if not ok then errors[#errors + 1] = { item = item, error = tostring(e) } end
                active = active - 1
                if nextIdx > total and active == 0 then p:resolve(true) else launch() end
            end)
        end
    end
    launch()
    Citizen.Await(p)
    return errors
end

local function apply(manifest, p, state, base, root)
    local version = tostring(manifest.version or "inconnue")
    local backupRoot = RES_DIR .. "/backup/" .. version:gsub("[^%w%.%-]", "_")
    local touched = {}
    local newFiles = {}
    if state and state.files then for k, v in pairs(state.files) do newFiles[k] = v end end
    local done = 0

    local errors = runPool(p.download, function(item)
        local url = base .. "/files/" .. encodePath(item.rel)
        local r = httpGet(url)
        if r.status ~= 200 or not r.body then error("HTTP " .. tostring(r.status) .. " " .. item.rel) end
        if sha256(r.body) ~= item.remote.h then error("hash différent après téléchargement (" .. item.rel .. ")") end
        local abs = root .. "/" .. item.rel
        if item.existed then copyFile(abs, backupRoot .. "/" .. item.rel) end
        local ok, why = writeFile(abs, r.body)
        if not ok then error((why or "écriture refusée") .. " (" .. item.rel .. ")") end
        newFiles[item.rel] = item.remote.h
        local r2 = resourceOf(item.rel)
        if r2 then touched[r2] = true end
        done = done + 1
        if done % 25 == 0 then log(done .. "/" .. #p.download .. " fichiers…") end
    end)

    local sideErrors = runPool(p.skipped, function(item)
        local r = httpGet(base .. "/files/" .. encodePath(item.rel))
        if r.status ~= 200 or not r.body then error("HTTP " .. tostring(r.status) .. " " .. item.rel) end
        local ok, why = writeFile(root .. "/" .. item.rel .. ".new", r.body)
        if not ok then error((why or "écriture refusée") .. " (" .. item.rel .. ".new)") end
    end)
    for _, e in ipairs(sideErrors) do errors[#errors + 1] = e end

    for _, rel in ipairs(p.deleted) do
        local abs = root .. "/" .. rel
        copyFile(abs, backupRoot .. "/" .. rel)
        local ok, why = os.remove(abs)
        if ok then
            newFiles[rel] = nil
            local r2 = resourceOf(rel)
            if r2 then touched[r2] = true end
        else
            errors[#errors + 1] = { item = { rel = rel }, error = tostring(why) }
        end
    end
    for _, s in ipairs(p.same) do newFiles[s.rel] = s.h end

    writeState({
        version = (#errors > 0) and ((state and state.version) or "partielle") or version,
        date = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        files = newFiles,
    })

    local list = {}
    for r2 in pairs(touched) do if not NO_RESTART[r2] then list[#list + 1] = r2 end end
    table.sort(list)
    return { errors = errors, touched = list, backupRoot = backupRoot }
end

-- ── commande ──────────────────────────────────────────────────────
local busy = false

local function command(args)
    if busy then warn("une mise à jour est déjà en cours.") return end
    busy = true
    local ok, e = pcall(function()
        local mode = (args[1] or ""):lower()
        local configured = GetConvar("update_url", ""):gsub("/+$", "")
        local state = readState()
        local root = serverRoot()

        if mode == "version" then
            log("version installée : " .. ((state and state.version) or "inconnue") .. ((state and state.date) and (" (" .. state.date:sub(1, 10) .. ")") or ""))
            if configured == "" then warn("update_url non défini dans server.cfg : impossible de vérifier la version disponible.") return end
        end
        if configured == "" then err('définis `set update_url "https://…"` dans server.cfg (racine contenant manifest.json).') return end
        local base = resolveBase(configured)

        local r = httpGet(base .. "/manifest.json?t=" .. os.time())
        if r.status ~= 200 or not r.body then err("manifest introuvable (HTTP " .. tostring(r.status) .. ").") return end
        local okj, manifest = pcall(json.decode, r.body)
        if not okj or type(manifest) ~= "table" or type(manifest.files) ~= "table" then err("manifest invalide.") return end

        if mode == "version" then
            log("version disponible : " .. tostring(manifest.version) .. (manifest.date and (" (" .. tostring(manifest.date):sub(1, 10) .. ")") or ""))
            return
        end

        local force = mode == "force"
        local doRestart = mode == "restart"
        local p = plan(manifest, state, force, root)
        local total = 0
        for _, d in ipairs(p.download) do total = total + (tonumber(d.remote.s) or 0) end

        log(("version %s → %s : %d fichier(s) à télécharger (%s), %d modifié(s) localement, %d à supprimer, %d à jour."):format(
            (state and state.version) or "?", tostring(manifest.version), #p.download, fmtSize(total), #p.skipped, #p.deleted, p.unchanged))
        if manifest.notes and manifest.notes ~= "" and (mode == "check" or #p.download > 0 or #p.skipped > 0) then
            for line in tostring(manifest.notes):gmatch("[^\n]+") do print("  " .. line) end
        end

        if mode == "check" then
            for _, d in ipairs(p.download) do print("  ^2+^7 " .. d.rel .. (d.existed and "" or "  (nouveau)")) end
            for _, s in ipairs(p.skipped) do print("  ^3~^7 " .. s.rel .. "  → " .. s.reason .. ", sera posé en .new") end
            for _, d in ipairs(p.deleted) do print("  ^1-^7 " .. d) end
            for _, k in ipairs(p.keep) do print("  ^3!^7 " .. k .. "  (supprimé par la mise à jour mais modifié localement : conservé)") end
            for _, n in ipairs(p.pendingNew) do print("  ^3~^7 " .. n .. "  → modifié localement, nouvelle version déjà dans " .. n .. ".new") end
            if #p.download == 0 and #p.skipped == 0 and #p.deleted == 0 then log("rien à faire, la base est à jour.") end
            return
        end

        if #p.download == 0 and #p.skipped == 0 and #p.deleted == 0 then
            log("rien à faire, la base est à jour.")
            for _, n in ipairs(p.pendingNew) do warn(n .. " : modifié localement, la nouvelle version t’attend dans " .. n .. ".new") end
            local files = {}
            for rel, info in pairs(manifest.files) do files[rel] = info.h end
            writeState({ version = manifest.version, date = os.date("!%Y-%m-%dT%H:%M:%SZ"), files = files })
            return
        end

        local res = apply(manifest, p, state, base, root)
        if #res.errors > 0 then
            for _, e2 in ipairs(res.errors) do err("échec : " .. tostring(e2.item.rel or "?") .. " — " .. tostring(e2.error)) end
            err(#res.errors .. " erreur(s). Relance `update` pour réessayer.")
        else
            log("mise à jour " .. tostring(manifest.version) .. " appliquée. Sauvegarde des anciens fichiers : " .. res.backupRoot:gsub("^" .. root:gsub("%p", "%%%0") .. "/", ""))
        end
        for _, s in ipairs(p.skipped) do warn(s.rel .. " : " .. s.reason .. " → nouvelle version dans " .. s.rel .. ".new") end
        for _, k in ipairs(p.keep) do warn(k .. " : supprimé par la mise à jour mais modifié localement, conservé.") end

        local selfUpdated = false
        for _, d in ipairs(p.download) do
            if d.rel:sub(1, #("resources/[standalone]/updater/")) == "resources/[standalone]/updater/" then selfUpdated = true end
        end
        if selfUpdated then
            log("updater mis à jour : redémarrage automatique dans 2 s…")
            SetTimeout(2000, function() ExecuteCommand("restart " .. RES) end)
        end
        if #res.touched > 0 then
            if doRestart then
                for _, r2 in ipairs(res.touched) do
                    log("restart " .. r2)
                    ExecuteCommand("restart " .. r2)
                end
            else
                log("ressources à redémarrer : " .. table.concat(res.touched, ", ") .. "   (ou : update restart)")
            end
        end
        for _, d in ipairs(p.download) do
            if not d.existed and d.rel:match("/fxmanifest%.lua$") then
                warn("une nouvelle ressource a été ajoutée : vérifie les `ensure` de server.cfg (voir les notes).")
                break
            end
        end
    end)
    busy = false
    if not ok then err(tostring(e)) end
end

RegisterCommand("update", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), "command.update") then return end
    CreateThread(function() command(args or {}) end)
end, true)

AddEventHandler("onResourceStart", function(res)
    if res ~= RES then return end
    local state = readState()
    log("version installée : " .. ((state and state.version) or "inconnue") .. ". Commandes : update, update check, update force, update restart, update version")
    if GetConvar("update_url", "") == "" then warn("update_url non défini dans server.cfg.") end
end)
