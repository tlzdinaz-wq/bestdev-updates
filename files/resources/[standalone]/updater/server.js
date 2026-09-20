/*  Updater — met la base à jour depuis la console serveur.
 *
 *  update            vérifie puis applique (télécharge uniquement les fichiers modifiés)
 *  update check      liste ce qui changerait, sans rien toucher
 *  update force      applique en écrasant aussi les fichiers modifiés localement
 *  update restart    applique puis redémarre les ressources touchées
 *  update version    version installée / disponible
 *
 *  Côté hébergement (convar update_url) :
 *      <update_url>/manifest.json   { version, date, notes, files: { "chemin": { h, s } }, protected: [...] }
 *      <update_url>/files/<chemin>  contenu de chaque fichier
 *
 *  Sécurité des fichiers modifiés par le serveur : un fichier dont le hash local ne
 *  correspond plus à la version installée (state.json) n'est jamais écrasé sans
 *  `force` — la nouvelle version est posée à côté avec l'extension .new. Les fichiers
 *  « protégés » du manifest (configs, images de marque) suivent la même règle quand
 *  aucun état n'est connu. Les anciens fichiers remplacés sont copiés dans backup/<version>/.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const crypto = require('crypto');

const RES = GetCurrentResourceName();
const RES_DIR = GetResourcePath(RES);
const STATE_FILE = path.join(RES_DIR, 'state.json');
const BACKUP_DIR = path.join(RES_DIR, 'backup');
const NEVER = new Set(['server.cfg', 'permissions.cfg']);
const NO_RESTART = new Set(['updater', 'oxmysql', 'ox_lib', 'monitor']);
const CONCURRENCY = 4;

// Racine du serveur = dossier qui contient `resources`
function serverRoot() {
    let dir = path.resolve(RES_DIR);
    for (let i = 0; i < 6; i++) {
        if (path.basename(dir) === 'resources') return path.dirname(dir);
        dir = path.dirname(dir);
    }
    throw new Error('dossier resources introuvable depuis ' + RES_DIR);
}

const log = (...a) => console.log('^5[update]^7', ...a);
const warn = (...a) => console.log('^3[update]^7', ...a);
const err = (...a) => console.log('^1[update]^7', ...a);

function sha256(file) {
    return new Promise((resolve, reject) => {
        const h = crypto.createHash('sha256');
        fs.createReadStream(file).on('data', d => h.update(d)).on('end', () => resolve(h.digest('hex'))).on('error', reject);
    });
}

function fetchBuffer(url, redirects = 5) {
    return new Promise((resolve, reject) => {
        const mod = url.startsWith('http:') ? http : https;
        const req = mod.get(url, { headers: { 'User-Agent': 'bestdev-updater/1.0', 'Cache-Control': 'no-cache' } }, res => {
            if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location && redirects > 0) {
                res.resume();
                return resolve(fetchBuffer(new URL(res.headers.location, url).toString(), redirects - 1));
            }
            if (res.statusCode !== 200) {
                res.resume();
                return reject(new Error('HTTP ' + res.statusCode + ' ' + url));
            }
            const chunks = [];
            res.on('data', c => chunks.push(c));
            res.on('end', () => resolve(Buffer.concat(chunks)));
            res.on('error', reject);
        });
        req.on('error', reject);
        req.setTimeout(60000, () => req.destroy(new Error('timeout ' + url)));
    });
}

// GitHub : raw.githubusercontent.com met la branche en cache plusieurs minutes (manifest ou
// fichiers périmés → hash différent). On demande le commit courant à l'API et on lit tout
// depuis ce commit précis (URL immuable, jamais en cache).
async function resolveBase(base) {
    const m = base.match(/^https:\/\/raw\.githubusercontent\.com\/([^/]+)\/([^/]+)\/([^/]+)\/?$/);
    if (!m) return base;
    try {
        const info = JSON.parse((await fetchBuffer('https://api.github.com/repos/' + m[1] + '/' + m[2] + '/commits/' + m[3])).toString('utf8'));
        if (info && typeof info.sha === 'string' && /^[0-9a-f]{40}$/.test(info.sha)) {
            return 'https://raw.githubusercontent.com/' + m[1] + '/' + m[2] + '/' + info.sha;
        }
    } catch (e) {
        warn('API GitHub indisponible (' + e.message + ') : lecture directe de la branche, un cache de quelques minutes est possible.');
    }
    return base;
}

function safeRel(rel) {
    const norm = rel.replace(/\\/g, '/');
    if (!norm || norm.startsWith('/') || /^[a-zA-Z]:/.test(norm) || norm.split('/').includes('..')) return null;
    return norm;
}

function readState() {
    try { return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch (_) { return null; }
}

function writeState(state) {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 1));
}

function matchProtected(rel, patterns) {
    return (patterns || []).some(p => {
        const re = new RegExp('^' + p.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*\*/g, '§§').replace(/\*/g, '[^/]*').replace(/§§/g, '.*') + '$');
        return re.test(rel);
    });
}

function resourceOf(rel) {
    const m = rel.match(/^resources\/(?:\[[^\]]+\]\/)*([^/\[]+)\//);
    return m ? m[1] : null;
}

async function plan(manifest, state, force) {
    const root = serverRoot();
    const out = { download: [], skipped: [], deleted: [], keep: [], same: [], pendingNew: [], unchanged: 0 };
    const files = manifest.files || {};
    const known = state && state.files ? state.files : {};

    for (const rel of Object.keys(files)) {
        const safe = safeRel(rel);
        if (!safe || NEVER.has(path.basename(safe))) continue;
        const remote = files[rel];
        const abs = path.join(root, safe);
        let localHash = null;
        if (fs.existsSync(abs)) {
            try { localHash = await sha256(abs); } catch (_) { localHash = null; }
        }
        if (localHash === remote.h) { out.unchanged++; out.same.push({ rel: safe, h: remote.h }); continue; }
        const installed = known[rel];
        const modified = localHash !== null && installed !== undefined && localHash !== installed;
        const unknownProtected = localHash !== null && installed === undefined && matchProtected(safe, manifest.protected);
        if (!force && (modified || unknownProtected)) {
            // nouvelle version déjà posée en .new lors d'un passage précédent → rien à refaire
            let pending = false;
            try { pending = fs.existsSync(abs + '.new') && (await sha256(abs + '.new')) === remote.h; } catch (_) { }
            if (pending) out.pendingNew.push(safe);
            else out.skipped.push({ rel: safe, remote, reason: modified ? 'modifié localement' : 'fichier protégé (état inconnu)' });
        } else {
            out.download.push({ rel: safe, remote, existed: localHash !== null });
        }
    }

    // fichiers présents dans l'état installé mais absents du manifest → supprimés par la mise à jour
    for (const rel of Object.keys(known)) {
        if (files[rel]) continue;
        const safe = safeRel(rel);
        if (!safe) continue;
        // fichiers protégés (configs, images, données écrites par le serveur) : jamais supprimés
        if (matchProtected(safe, manifest.protected)) continue;
        const abs = path.join(root, safe);
        if (!fs.existsSync(abs)) continue;
        let localHash = null;
        try { localHash = await sha256(abs); } catch (_) { }
        if (force || localHash === known[rel]) out.deleted.push(safe);
        else out.keep.push(safe);
    }
    return out;
}

function fmtSize(n) {
    if (n > 1048576) return (n / 1048576).toFixed(1) + ' Mo';
    if (n > 1024) return Math.round(n / 1024) + ' Ko';
    return n + ' o';
}

async function runPool(items, worker) {
    let i = 0;
    const errors = [];
    const workers = new Array(Math.min(CONCURRENCY, items.length)).fill(0).map(async () => {
        while (i < items.length) {
            const item = items[i++];
            try { await worker(item); } catch (e) { errors.push({ item, error: e }); }
        }
    });
    await Promise.all(workers);
    return errors;
}

async function apply(manifest, p, state, base) {
    const root = serverRoot();
    const version = String(manifest.version || 'inconnue');
    const backupRoot = path.join(BACKUP_DIR, version.replace(/[^\w.-]/g, '_'));
    const touched = new Set();
    const newFiles = state && state.files ? { ...state.files } : {};
    let done = 0;

    const errors = await runPool(p.download, async item => {
        const url = base + '/files/' + item.rel.split('/').map(encodeURIComponent).join('/');
        const buf = await fetchBuffer(url);
        const got = crypto.createHash('sha256').update(buf).digest('hex');
        if (got !== item.remote.h) throw new Error('hash différent après téléchargement (' + item.rel + ')');
        const abs = path.join(root, item.rel);
        fs.mkdirSync(path.dirname(abs), { recursive: true });
        if (item.existed) {
            const bak = path.join(backupRoot, item.rel);
            fs.mkdirSync(path.dirname(bak), { recursive: true });
            try { fs.copyFileSync(abs, bak); } catch (_) { }
        }
        const tmp = abs + '.updtmp';
        fs.writeFileSync(tmp, buf);
        fs.renameSync(tmp, abs);
        newFiles[item.rel] = item.remote.h;
        const r = resourceOf(item.rel);
        if (r) touched.add(r);
        done++;
        if (done % 25 === 0) log(done + '/' + p.download.length + ' fichiers…');
    });

    // fichiers modifiés localement : nouvelle version posée à côté (.new)
    const sideErrors = await runPool(p.skipped, async item => {
        const url = base + '/files/' + item.rel.split('/').map(encodeURIComponent).join('/');
        const buf = await fetchBuffer(url);
        const abs = path.join(root, item.rel + '.new');
        fs.mkdirSync(path.dirname(abs), { recursive: true });
        fs.writeFileSync(abs, buf);
    });

    for (const rel of p.deleted) {
        const abs = path.join(root, rel);
        try {
            const bak = path.join(backupRoot, rel);
            fs.mkdirSync(path.dirname(bak), { recursive: true });
            fs.copyFileSync(abs, bak);
            fs.unlinkSync(abs);
            delete newFiles[rel];
            const r = resourceOf(rel);
            if (r) touched.add(r);
        } catch (e) {
            errors.push({ item: { rel }, error: e });
        }
    }
    // fichiers déjà identiques à la version publiée : hash mémorisé pour les prochaines comparaisons
    for (const s of p.same) newFiles[s.rel] = s.h;

    const failed = errors.length + sideErrors.length;
    writeState({ version: failed ? (state && state.version) || 'partielle' : version, date: new Date().toISOString(), files: newFiles });

    return { errors: errors.concat(sideErrors), touched: [...touched].filter(r => !NO_RESTART.has(r)), backupRoot };
}

let busy = false;

async function command(args) {
    if (busy) { warn('une mise à jour est déjà en cours.'); return; }
    busy = true;
    try {
        const mode = (args[0] || '').toLowerCase();
        const configured = String(GetConvar('update_url', '')).replace(/\/+$/, '');
        const state = readState();

        if (mode === 'version') {
            log('version installée : ' + ((state && state.version) || 'inconnue') + (state && state.date ? ' (' + state.date.slice(0, 10) + ')' : ''));
            if (!configured) { warn('update_url non défini dans server.cfg : impossible de vérifier la version disponible.'); return; }
        }
        if (!configured) { err('définis `set update_url "https://…"` dans server.cfg (racine contenant manifest.json).'); return; }
        const base = await resolveBase(configured);

        let manifest;
        try {
            manifest = JSON.parse((await fetchBuffer(base + '/manifest.json?t=' + Date.now())).toString('utf8'));
        } catch (e) {
            err('manifest introuvable : ' + e.message); return;
        }
        if (!manifest || typeof manifest.files !== 'object') { err('manifest invalide.'); return; }

        if (mode === 'version') {
            log('version disponible : ' + manifest.version + (manifest.date ? ' (' + String(manifest.date).slice(0, 10) + ')' : ''));
            return;
        }

        const force = mode === 'force';
        const doRestart = mode === 'restart';
        const p = await plan(manifest, state, force);
        const total = p.download.reduce((n, d) => n + (d.remote.s || 0), 0);

        log('version ' + ((state && state.version) || '?') + ' → ' + manifest.version + ' : ' + p.download.length + ' fichier(s) à télécharger (' + fmtSize(total) + '), ' + p.skipped.length + ' modifié(s) localement, ' + p.deleted.length + ' à supprimer, ' + p.unchanged + ' à jour.');
        if (manifest.notes && (mode === 'check' || p.download.length || p.skipped.length)) {
            for (const line of String(manifest.notes).split('\n')) console.log('  ' + line);
        }

        if (mode === 'check') {
            for (const d of p.download) console.log('  ^2+^7 ' + d.rel + (d.existed ? '' : '  (nouveau)'));
            for (const s of p.skipped) console.log('  ^3~^7 ' + s.rel + '  → ' + s.reason + ', sera posé en .new');
            for (const d of p.deleted) console.log('  ^1-^7 ' + d);
            for (const k of p.keep) console.log('  ^3!^7 ' + k + '  (supprimé par la mise à jour mais modifié localement : conservé)');
            for (const n of p.pendingNew) console.log('  ^3~^7 ' + n + '  → modifié localement, nouvelle version déjà dans ' + n + '.new');
            if (!p.download.length && !p.skipped.length && !p.deleted.length) log('rien à faire, la base est à jour.');
            return;
        }

        if (!p.download.length && !p.skipped.length && !p.deleted.length) {
            log('rien à faire, la base est à jour.');
            for (const n of p.pendingNew) warn(n + ' : modifié localement, la nouvelle version t’attend dans ' + n + '.new');
            writeState({ version: manifest.version, date: new Date().toISOString(), files: Object.fromEntries(Object.entries(manifest.files).map(([k, v]) => [k, v.h])) });
            return;
        }

        const res = await apply(manifest, p, state, base);
        if (res.errors.length) {
            for (const e of res.errors) err('échec : ' + (e.item.rel || '?') + ' — ' + e.error.message);
            err(res.errors.length + ' erreur(s). Relance `update` pour réessayer.');
        } else {
            log('mise à jour ' + manifest.version + ' appliquée. Sauvegarde des anciens fichiers : ' + path.relative(serverRoot(), res.backupRoot));
        }
        for (const s of p.skipped) warn(s.rel + ' : ' + s.reason + ' → nouvelle version dans ' + s.rel + '.new');
        for (const k of p.keep) warn(k + ' : supprimé par la mise à jour mais modifié localement, conservé.');

        if (res.touched.length) {
            if (doRestart) {
                for (const r of res.touched) {
                    log('restart ' + r);
                    ExecuteCommand('restart ' + r);
                }
            } else {
                log('ressources à redémarrer : ' + res.touched.join(', ') + '   (ou : update restart)');
            }
        }
        if (Object.keys(manifest.files).some(f => /(^|\/)fxmanifest\.lua$/.test(f) && p.download.find(d => d.rel === f && !d.existed))) {
            warn('une nouvelle ressource a été ajoutée : vérifie les `ensure` de server.cfg (voir les notes).');
        }
    } catch (e) {
        err(e.message);
    } finally {
        busy = false;
    }
}

RegisterCommand('update', (source, args) => {
    if (source !== 0 && !IsPlayerAceAllowed(String(source), 'command.update')) return;
    command(args);
}, true);

on('onResourceStart', res => {
    if (res !== RES) return;
    const state = readState();
    log('version installée : ' + ((state && state.version) || 'inconnue') + '. Commandes : update, update check, update force, update restart, update version');
    if (!GetConvar('update_url', '')) warn('update_url non défini dans server.cfg.');
});
