--[[
    Updater — vérifie depuis la console si la base est à jour.

      update            liste ce qui a changé depuis la version installée (ne modifie rien)
      update version    version installée / disponible

    L'application se fait HORS du serveur, à la racine (dossier qui contient server.cfg) :
      Windows : update.bat            Linux : ./update.sh
      (+ `check` pour voir sans appliquer, `force` pour écraser aussi les fichiers modifiés localement)
    Le runtime de FXServer interdit à une ressource d'écrire en dehors de son propre dossier,
    la console ne peut donc que vérifier ; les scripts téléchargent uniquement les fichiers
    modifiés, gardent une sauvegarde dans backup/<version>/ et posent en `.new` la nouvelle
    version des fichiers modifiés localement (configs, images de marque…).

    Hébergement (convar update_url) :
      <update_url>/manifest.json   { version, date, notes, protected, files = { [chemin] = { h = sha256, s = taille } } }
      <update_url>/manifest.txt    même contenu, une ligne par fichier (lu par update.bat / update.sh)
      <update_url>/files/<chemin>  contenu de chaque fichier
]]

local RES = GetCurrentResourceName()
-- GetResourcePath peut renvoyer "…/resources//[standalone]/updater" : on normalise les slashs
local RES_DIR = GetResourcePath(RES):gsub("\\", "/"):gsub("/+", "/"):gsub("/+$", "")
local NEVER = { ["server.cfg"] = true, ["permissions.cfg"] = true }
-- pas de `package` dans le Lua de FXServer : on détecte Windows au chemin (lettre de lecteur / antislash)
local RAW_DIR = GetResourcePath(RES)
local IS_WINDOWS = RAW_DIR:match("^%a:") ~= nil or RAW_DIR:find("\\", 1, true) ~= nil
local APPLY_HINT = IS_WINDOWS and "update.bat (double-clic à la racine du serveur)" or "./update.sh (à la racine du serveur)"

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

-- ── fichiers (lecture seule) ──────────────────────────────────────
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

-- ── état installé : state.txt (écrit par update.bat / update.sh) ou state.json (archive) ──
local function readState()
    local txt = LoadResourceFile(RES, "state.txt")
    if txt and txt ~= "" then
        local state = { files = {} }
        for line in txt:gmatch("[^\r\n]+") do
            local a, b, c = line:match("^([^\t]*)\t([^\t]*)\t?(.*)$")
            if a == "#version" then
                state.version, state.date = b, c
            elseif a and #a == 64 and b ~= "" then
                state.files[b] = a
            end
        end
        if state.version then return state end
    end
    local raw = LoadResourceFile(RES, "state.json")
    if not raw or raw == "" then return nil end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" then return data end
    return nil
end

-- ── HTTP ──────────────────────────────────────────────────────────
local function httpGet(url)
    local p = promise.new()
    local done = false
    PerformHttpRequest(url, function(status, body)
        if done then return end
        done = true
        p:resolve({ status = status, body = body })
    end, "GET", "", { ["User-Agent"] = "bestdev-updater/3.0", ["Cache-Control"] = "no-cache" })
    SetTimeout(120000, function()
        if done then return end
        done = true
        p:resolve({ status = 0, body = nil })
    end)
    return Citizen.Await(p)
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

local function fetchManifest(configured)
    local base = resolveBase(configured)
    local r = httpGet(base .. "/manifest.json?t=" .. os.time())
    if r.status ~= 200 or not r.body then return nil, "manifest introuvable (HTTP " .. tostring(r.status) .. ")." end
    local ok, manifest = pcall(json.decode, r.body)
    if not ok or type(manifest) ~= "table" or type(manifest.files) ~= "table" then return nil, "manifest invalide." end
    return manifest
end

-- ── comparaison base installée / version publiée ──────────────────
local function plan(manifest, state, root)
    local out = { download = {}, skipped = {}, deleted = {}, keep = {}, pendingNew = {}, unchanged = 0 }
    local files = manifest.files or {}
    local known = (state and state.files) or {}

    local rels = {}
    for rel in pairs(files) do rels[#rels + 1] = rel end
    table.sort(rels)

    if not state then log("première vérification : calcul de l'empreinte de chaque fichier (" .. #rels .. "), cela peut prendre une à deux minutes…") end
    for idx, rel in ipairs(rels) do
        -- 3 300 fichiers à vérifier : on rend la main au serveur régulièrement (pas de hitch)
        if Wait and idx % 150 == 0 then Wait(0) end
        if not state and idx % 500 == 0 then log(("vérification %d / %d…"):format(idx, #rels)) end
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
            else
                local modified = localHash ~= nil and installed ~= nil and localHash ~= installed
                local unknownProtected = localHash ~= nil and installed == nil and isProtected(safe, manifest.protected)
                if modified or unknownProtected then
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
                    if localHash == h then
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

-- ── commande ──────────────────────────────────────────────────────
local busy = false
local function command(args)
    if busy then warn("une vérification est déjà en cours.") return end
    busy = true
    local ok, e = pcall(function()
        local mode = (args[1] or ""):lower()
        local configured = GetConvar("update_url", ""):gsub("/+$", "")
        local state = readState()
        local root = serverRoot()

        if mode == "force" or mode == "restart" or mode == "apply" then
            warn("la console ne peut que vérifier (FXServer interdit l'écriture hors de la ressource). Pour appliquer : " .. APPLY_HINT .. (mode == "force" and " avec l'argument `force`" or "") .. ".")
            mode = "check"
        end
        if mode == "version" then
            log("version installée : " .. ((state and state.version) or "inconnue") .. ((state and state.date) and (" (" .. state.date:sub(1, 10) .. ")") or ""))
        end
        if configured == "" then err('définis `set update_url "https://…"` dans server.cfg (racine contenant manifest.json).') return end

        local manifest, merr = fetchManifest(configured)
        if not manifest then err(merr) return end
        if mode == "version" then
            log("version disponible : " .. tostring(manifest.version) .. (manifest.date and (" (" .. tostring(manifest.date):sub(1, 10) .. ")") or ""))
            return
        end

        local p = plan(manifest, state, root)
        local total = 0
        for _, d in ipairs(p.download) do total = total + (tonumber(d.remote.s) or 0) end
        log(("version %s → %s : %d fichier(s) à télécharger (%s), %d modifié(s) localement, %d à supprimer, %d à jour."):format(
            (state and state.version) or "?", tostring(manifest.version), #p.download, fmtSize(total), #p.skipped, #p.deleted, p.unchanged))
        if manifest.notes and manifest.notes ~= "" and (#p.download > 0 or #p.skipped > 0) then
            for line in tostring(manifest.notes):gmatch("[^\n]+") do print("  " .. line) end
        end
        for _, d in ipairs(p.download) do print("  ^2+^7 " .. d.rel .. (d.existed and "" or "  (nouveau)")) end
        for _, s in ipairs(p.skipped) do print("  ^3~^7 " .. s.rel .. "  → " .. s.reason .. ", sera posé en .new") end
        for _, d in ipairs(p.deleted) do print("  ^1-^7 " .. d) end
        for _, k in ipairs(p.keep) do print("  ^3!^7 " .. k .. "  (supprimé par la mise à jour mais modifié localement : conservé)") end
        for _, n in ipairs(p.pendingNew) do print("  ^3~^7 " .. n .. "  → modifié localement, nouvelle version déjà dans " .. n .. ".new") end

        if #p.download == 0 and #p.skipped == 0 and #p.deleted == 0 then
            log("rien à faire, la base est à jour.")
        else
            log("pour appliquer : " .. APPLY_HINT .. ", puis redémarre le serveur.")
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
    log("version installée : " .. ((state and state.version) or "inconnue") .. ". `update` vérifie ; " .. APPLY_HINT .. " applique.")
    local configured = GetConvar("update_url", ""):gsub("/+$", "")
    if configured == "" then warn("update_url non défini dans server.cfg.") return end
    -- au démarrage : un seul appel HTTP pour signaler une nouvelle version (pas de lecture des fichiers)
    if GetConvar("update_check_on_start", "true") ~= "true" then return end
    CreateThread(function()
        Wait(5000)
        local manifest = fetchManifest(configured)
        if not manifest then return end
        local installed = state and state.version
        if manifest.version and manifest.version ~= installed then
            warn(("nouvelle version disponible : %s (installée : %s). `update` pour le détail, %s pour l'appliquer."):format(tostring(manifest.version), tostring(installed or "inconnue"), APPLY_HINT))
        end
    end)
end)
