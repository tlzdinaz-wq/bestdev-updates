// Mise a jour d'une installation Best Dev directement sur l'hebergeur.
//
// Beaucoup d'hebergeurs FiveM ne donnent qu'un acces FTP : impossible d'y lancer
// update.bat ou update.sh. Cet outil fait le travail depuis votre machine — il lit la
// version installee a distance, telecharge les archives de mise a jour publiees, et
// televerse uniquement les fichiers qui changent.
//
// Lancement :  npm install  puis  npm start
// Puis ouvrir http://127.0.0.1:7788
//
// Les identifiants ne sont ni enregistres ni transmis ailleurs qu'a votre hebergeur :
// ils vivent le temps de la requete, en memoire.

import { createServer } from 'node:http'
import { randomBytes, timingSafeEqual } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { inflateRawSync } from 'node:zlib'
import { fileURLToPath } from 'node:url'
import { dirname, join, extname } from 'node:path'

const HERE = dirname(fileURLToPath(import.meta.url))
const PORT = Number(process.env.PORT || 7788)

// Par defaut l'outil n'ecoute que sur la machine qui le lance : rien n'est joignable de
// l'exterieur. `--public` (ou HOST=0.0.0.0) l'expose sur toutes les interfaces, pour qu'il
// soit atteignable a l'IP du serveur — indispensable quand on le lance sur l'hebergeur et
// qu'on l'ouvre depuis chez soi.
//
// Expose, il devient une porte vers les fichiers du serveur : une cle d'acces est alors
// exigee a chaque requete. Elle est tiree au hasard au demarrage, ou fixee par UPDATER_KEY.
const PUBLIC = process.argv.includes('--public') || process.env.HOST === '0.0.0.0'
const HOST = PUBLIC ? '0.0.0.0' : '127.0.0.1'
const KEY = PUBLIC ? (process.env.UPDATER_KEY || randomBytes(9).toString('base64url')) : null

// Source des mises a jour : la meme que celle du publicateur.
const config = JSON.parse(await readFile(join(HERE, '..', 'release.config.json'), 'utf8'))
const DOWNLOAD_BASE = (config.downloadBase || '').replace(/\/$/, '')

const STATE_PATH = 'resources/[standalone]/updater/state.txt'

// ── Archives zip (lecture seule, sans dependance) ───────────────────────────────────────
//
// Les archives publiees sont en deflate simple. Plutot que d'ajouter une bibliotheque
// pour les lire, on parcourt le repertoire central nous-memes : c'est une centaine de
// lignes et ca evite une dependance de plus a maintenir.

function readZip(buffer) {
  const end = findEndOfCentralDirectory(buffer)
  if (!end) throw new Error('Archive illisible (fin de repertoire introuvable).')

  const count = buffer.readUInt16LE(end + 10)
  let offset = buffer.readUInt32LE(end + 16)
  const entries = []

  for (let i = 0; i < count; i++) {
    if (buffer.readUInt32LE(offset) !== 0x02014b50) break

    const method = buffer.readUInt16LE(offset + 10)
    const compressedSize = buffer.readUInt32LE(offset + 20)
    const nameLength = buffer.readUInt16LE(offset + 28)
    const extraLength = buffer.readUInt16LE(offset + 30)
    const commentLength = buffer.readUInt16LE(offset + 32)
    const localOffset = buffer.readUInt32LE(offset + 42)
    const name = buffer.toString('utf8', offset + 46, offset + 46 + nameLength)

    if (!name.endsWith('/')) {
      entries.push({ name, method, compressedSize, localOffset })
    }

    offset += 46 + nameLength + extraLength + commentLength
  }

  return entries.map(entry => ({
    name: entry.name,
    data: () => extract(buffer, entry),
  }))
}

function findEndOfCentralDirectory(buffer) {
  for (let i = buffer.length - 22; i >= 0 && i > buffer.length - 66000; i--) {
    if (buffer.readUInt32LE(i) === 0x06054b50) return i
  }
  return null
}

function extract(buffer, entry) {
  const nameLength = buffer.readUInt16LE(entry.localOffset + 26)
  const extraLength = buffer.readUInt16LE(entry.localOffset + 28)
  const start = entry.localOffset + 30 + nameLength + extraLength
  const raw = buffer.subarray(start, start + entry.compressedSize)
  return entry.method === 0 ? Buffer.from(raw) : inflateRawSync(raw)
}

// ── Telechargement ──────────────────────────────────────────────────────────────────────

async function download(url) {
  const response = await fetch(url)
  if (!response.ok) {
    const error = new Error(`${response.status} sur ${url}`)
    error.status = response.status
    throw error
  }
  return Buffer.from(await response.arrayBuffer())
}

async function latestVersion() {
  const manifest = JSON.parse((await download(`${DOWNLOAD_BASE}/manifest.json`)).toString('utf8'))
  return manifest.version
}

/** 1.12.56 -> [1, 12, 56] */
function parseVersion(value) {
  const parts = String(value || '').trim().split('.').map(Number)
  if (parts.length !== 3 || parts.some(Number.isNaN)) return null
  return parts
}

function compareVersions(a, b) {
  for (let i = 0; i < 3; i++) {
    if (a[i] !== b[i]) return a[i] - b[i]
  }
  return 0
}

/**
 * Les archives a appliquer entre la version installee et la cible.
 *
 * Chaque archive publiee ne contient que les fichiers modifies par SA version : un serveur
 * en retard de plusieurs versions a donc besoin de toutes celles qui le separent de la
 * cible, appliquees dans l'ordre. Une version sans archive publiee est simplement ignoree.
 */
function versionsBetween(from, to) {
  const start = parseVersion(from)
  const end = parseVersion(to)
  if (!start || !end || compareVersions(start, end) >= 0) return []

  const out = []
  for (let patch = start[2] + 1; patch <= end[2]; patch++) {
    out.push(`${end[0]}.${end[1]}.${patch}`)
  }
  return out
}

// ── Transports ──────────────────────────────────────────────────────────────────────────

async function openFtp(form, secure) {
  const { Client } = await import('basic-ftp')
  const client = new Client(30000)
  client.ftp.verbose = false

  await client.access({
    host: form.host,
    port: Number(form.port) || 21,
    user: form.user,
    password: form.password,
    secure,
    secureOptions: { rejectUnauthorized: false },
  })

  return {
    async list(path) {
      const items = await client.list(path)
      return items.map(item => item.name)
    },
    async read(path) {
      const chunks = []
      const { Writable } = await import('node:stream')
      await client.downloadTo(new Writable({
        write(chunk, _enc, cb) { chunks.push(chunk); cb() },
      }), path)
      return Buffer.concat(chunks)
    },
    async write(path, data) {
      const { Readable } = await import('node:stream')
      const slash = path.lastIndexOf('/')
      if (slash > 0) await client.ensureDir(path.slice(0, slash))
      await client.uploadFrom(Readable.from(data), path)
      await client.cd('/')
    },
    close() { client.close() },
  }
}

async function openSftp(form) {
  const SftpClient = (await import('ssh2-sftp-client')).default
  const client = new SftpClient()

  await client.connect({
    host: form.host,
    port: Number(form.port) || 22,
    username: form.user,
    password: form.password,
    readyTimeout: 30000,
  })

  return {
    async list(path) {
      const items = await client.list(path)
      return items.map(item => item.name)
    },
    async read(path) {
      return client.get(path)
    },
    async write(path, data) {
      const slash = path.lastIndexOf('/')
      if (slash > 0) await client.mkdir(path.slice(0, slash), true)
      await client.put(data, path)
    },
    async close() { await client.end() },
  }
}

/**
 * Accepte une chaine de connexion collee telle quelle dans le champ hote.
 *
 * Les hebergeurs donnent souvent `sftp://utilisateur@machine:2022/chemin` d'un bloc. Colle
 * dans le champ hote, la resolution DNS echoue sur toute la chaine (EAI_FAIL) et le
 * protocole choisi dans la liste ne correspond plus. On decoupe donc ce qui est reconnu,
 * sans jamais ecraser ce que l'utilisateur a saisi lui-meme.
 */
function normalizeTarget(input) {
  const form = { ...input }
  let host = String(form.host || '').trim()

  const scheme = host.match(/^([a-z][a-z0-9+.-]*):\/\//i)
  if (scheme) {
    const name = scheme[1].toLowerCase()
    if (name === 'sftp' || name === 'ssh') form.protocol = 'sftp'
    else if (name === 'ftps') form.protocol = 'ftps'
    else if (name === 'ftp') form.protocol = 'ftp'
    host = host.slice(scheme[0].length)
  }

  const at = host.lastIndexOf('@')
  if (at !== -1) {
    const credentials = host.slice(0, at)
    host = host.slice(at + 1)
    const colon = credentials.indexOf(':')
    const user = colon === -1 ? credentials : credentials.slice(0, colon)
    const password = colon === -1 ? '' : credentials.slice(colon + 1)
    if (!form.user && user) form.user = decodeURIComponent(user)
    if (!form.password && password) form.password = decodeURIComponent(password)
  }

  const slash = host.indexOf('/')
  if (slash !== -1) {
    const path = host.slice(slash)
    host = host.slice(0, slash)
    if (!form.remotePath && path !== '/') form.remotePath = path
  }

  const port = host.match(/:(\d{1,5})$/)
  if (port) {
    host = host.slice(0, port.index)
    if (!form.port) form.port = port[1]
  }

  form.host = host.replace(/\/+$/, '')
  if (!form.port) form.port = form.protocol === 'sftp' ? '22' : '21'

  return form
}

function connect(form) {
  if (form.protocol === 'sftp') return openSftp(form)
  return openFtp(form, form.protocol === 'ftps')
}

function remotePath(form, relative) {
  const base = String(form.remotePath || '').replace(/\\/g, '/').replace(/\/+$/, '')
  return base ? `${base}/${relative}` : relative
}

// ── Actions ─────────────────────────────────────────────────────────────────────────────

async function testConnection(input) {
  const form = normalizeTarget(input)
  const client = await connect(form)
  try {
    const base = remotePath(form, '').replace(/\/$/, '') || '.'
    const entries = await client.list(base || '/')

    const hasResources = entries.includes('resources')
    let installed = null

    if (hasResources) {
      try {
        installed = (await client.read(remotePath(form, STATE_PATH))).toString('utf8').trim()
      } catch {
        installed = null
      }
    }

    return {
      ok: true,
      hasResources,
      installed,
      entries: entries.slice(0, 40),
      latest: await latestVersion(),
      // Ce que l'outil a compris : la page le reinjecte dans le formulaire, pour que
      // l'utilisateur voie ce qui sera utilise au lieu de le deviner.
      parsed: {
        protocol: form.protocol,
        host: form.host,
        port: String(form.port),
        user: form.user,
        remotePath: form.remotePath || '',
      },
    }
  } finally {
    await client.close()
  }
}

async function runUpdate(input, send) {
  const form = normalizeTarget(input)
  send('info', `Connexion a ${form.host}:${form.port} en ${form.protocol.toUpperCase()}...`)
  const client = await connect(form)

  try {
    const target = form.targetVersion || await latestVersion()
    send('info', `Derniere version publiee : ${target}`)

    let installed = form.installedVersion || null
    if (!installed) {
      try {
        installed = (await client.read(remotePath(form, STATE_PATH))).toString('utf8').trim()
        send('info', `Version installee lue sur l'hebergeur : ${installed}`)
      } catch {
        throw new Error(
          "Impossible de lire la version installee (resources/[standalone]/updater/state.txt). "
          + "Verifiez le chemin distant, ou indiquez la version a la main.")
      }
    } else {
      send('info', `Version installee indiquee : ${installed}`)
    }

    if (installed === target) {
      send('done', 'Le serveur est deja a jour. Rien a faire.')
      return
    }

    const versions = versionsBetween(installed, target)
    if (versions.length === 0) {
      throw new Error(`Rien a appliquer entre ${installed} et ${target}. Verifiez les numeros de version.`)
    }

    send('info', `${versions.length} version(s) a appliquer : ${versions.join(', ')}`)

    // Fusion des archives : une version plus recente remplace la precedente pour un meme
    // fichier, on n'envoie donc chaque fichier qu'une fois, dans sa derniere version.
    const files = new Map()

    for (const version of versions) {
      const url = `${DOWNLOAD_BASE}/bestdev-v${version}.zip`
      let archive
      try {
        archive = await download(url)
      } catch (error) {
        if (error.status === 404) {
          send('warn', `Version ${version} : aucune archive publiee, ignoree.`)
          continue
        }
        throw error
      }

      let kept = 0
      for (const entry of readZip(archive)) {
        if (!entry.name.startsWith('resources/') && !entry.name.endsWith('.bat') && !entry.name.endsWith('.sh')) {
          continue
        }
        files.set(entry.name, entry.data())
        kept++
      }
      send('info', `Version ${version} : ${kept} fichier(s).`)
    }

    if (files.size === 0) {
      throw new Error('Aucun fichier a televerser. Les archives sont peut-etre vides.')
    }

    send('info', `${files.size} fichier(s) a envoyer.`)

    let done = 0
    for (const [name, data] of files) {
      await client.write(remotePath(form, name), data)
      done++
      send('progress', name, { done, total: files.size })
    }

    await client.write(remotePath(form, STATE_PATH), Buffer.from(target, 'utf8'))
    send('info', `Version enregistree sur l'hebergeur : ${target}`)

    send('done',
      `Termine : ${files.size} fichier(s) envoye(s). Redemarrez le serveur, `
      + `puis reportez les fichiers « .new » si la mise a jour en contient.`)
  } finally {
    await client.close()
  }
}

// ── Serveur ─────────────────────────────────────────────────────────────────────────────

const MIME = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8' }

async function body(request) {
  const chunks = []
  for await (const chunk of request) chunks.push(chunk)
  return JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}')
}

/** Comparaison a duree constante : une cle ne se devine pas a la vitesse des reponses. */
function keyAccepted(provided) {
  if (!KEY) return true
  if (typeof provided !== 'string' || provided.length !== KEY.length) return false
  return timingSafeEqual(Buffer.from(provided), Buffer.from(KEY))
}

const server = createServer(async (request, response) => {
  try {
    if (KEY) {
      const url = new URL(request.url, 'http://x')
      const given = url.searchParams.get('k') || request.headers['x-updater-key']
      if (!keyAccepted(given)) {
        response.writeHead(403, { 'content-type': 'application/json; charset=utf-8' })
        response.end(JSON.stringify({ ok: false, error: "Cle d'acces manquante ou invalide." }))
        return
      }
    }

    // La cle voyage dans l'adresse : tout le routage se fait sur le chemin seul.
    const route = request.url.split('?')[0]

    if (request.method === 'POST' && route === '/api/test') {
      const result = await testConnection(await body(request))
      response.writeHead(200, { 'content-type': 'application/json; charset=utf-8' })
      response.end(JSON.stringify(result))
      return
    }

    if (request.method === 'POST' && route === '/api/update') {
      response.writeHead(200, {
        'content-type': 'application/x-ndjson; charset=utf-8',
        'cache-control': 'no-cache',
      })

      const send = (type, message, extra = {}) => {
        response.write(JSON.stringify({ type, message, ...extra }) + '\n')
      }

      try {
        await runUpdate(await body(request), send)
      } catch (error) {
        send('error', error.message || String(error))
      }

      response.end()
      return
    }

    // La cle voyage dans l'adresse : on retire la requete AVANT de tester la racine,
    // sinon « /?k=... » n'est plus reconnu comme la page d'accueil.
    const file = (route === '/' || route === '') ? '/index.html' : route
    const data = await readFile(join(HERE, 'public', file.replace(/\.\./g, '')))
    response.writeHead(200, { 'content-type': MIME[extname(file)] || 'application/octet-stream' })
    response.end(data)
  } catch (error) {
    response.writeHead(error.code === 'ENOENT' ? 404 : 500, { 'content-type': 'application/json; charset=utf-8' })
    response.end(JSON.stringify({ ok: false, error: error.message || String(error) }))
  }
})

server.listen(PORT, HOST, () => {
  if (!PUBLIC) {
    console.log(`Mise a jour Best Dev : http://127.0.0.1:${PORT}`)
    console.log("Accessible depuis cette machine uniquement. Pour l'ouvrir a distance : node server.mjs --public")
  } else {
    console.log(`Mise a jour Best Dev : http://<ip-du-serveur>:${PORT}/?k=${KEY}`)
    console.log("Ouvert sur toutes les interfaces. Le lien ci-dessus contient la cle d'acces :")
    console.log('sans elle, toute requete est refusee. Ne la diffusez pas.')
  }
  console.log(`Source des mises a jour : ${DOWNLOAD_BASE}`)
})
