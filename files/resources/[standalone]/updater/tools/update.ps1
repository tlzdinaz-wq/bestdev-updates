<#
  Mise à jour de la base — script Windows, à lancer à côté du serveur (update.bat à la racine).
  Le serveur peut tourner, mais les ressources modifiées ne prennent effet qu'après un
  redémarrage (restart <ressource> ou redémarrage du serveur).

    update.bat            vérifie puis applique (télécharge uniquement les fichiers modifiés)
    update.bat check      liste ce qui changerait, sans rien toucher
    update.bat force      écrase aussi les fichiers modifiés localement

  Source : update_url dans server.cfg (racine HTTP contenant manifest.txt et files/…).
  Un fichier modifié localement (hash différent de la version installée) n'est jamais écrasé
  sans « force » : la nouvelle version est posée à côté en .new. Les fichiers protégés
  (configs, images) ne sont jamais supprimés. Les fichiers remplacés sont copiés dans
  resources\[standalone]\updater\backup\<version>\.
#>
param(
    [switch]$Check,
    [switch]$Force,
    [string]$Url = ''
)

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$updaterDir = Split-Path -Parent $toolsDir
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $updaterDir))   # …\resources\[standalone]\updater\tools → racine
$stateFile = Join-Path $updaterDir 'state.txt'
$stateJson = Join-Path $updaterDir 'state.json'

function Info($m)  { Write-Host "[update] $m" -ForegroundColor Cyan }
function Warn($m)  { Write-Host "[update] $m" -ForegroundColor Yellow }
function Fail($m)  { Write-Host "[update] $m" -ForegroundColor Red }

# ── source ─────────────────────────────────────────────────────
if (-not $Url) {
    $cfg = Join-Path $root 'server.cfg'
    if (Test-Path -LiteralPath $cfg) {
        $m = [regex]::Match((Get-Content -LiteralPath $cfg -Raw), 'set\s+update_url\s+"([^"]+)"')
        if ($m.Success) { $Url = $m.Groups[1].Value }
    }
}
if (-not $Url) { Fail 'update_url introuvable : ajoute set update_url "https://..." dans server.cfg ou passe -Url.'; exit 1 }
$Url = $Url.TrimEnd('/')

# GitHub : lire depuis le commit exact (raw.githubusercontent met la branche en cache)
$gh = [regex]::Match($Url, '^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/?$')
if ($gh.Success) {
    try {
        $info = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'bestdev-updater' } -Uri ("https://api.github.com/repos/{0}/{1}/commits/{2}" -f $gh.Groups[1].Value, $gh.Groups[2].Value, $gh.Groups[3].Value)
        if ($info.sha -match '^[0-9a-f]{40}$') { $Url = "https://raw.githubusercontent.com/{0}/{1}/{2}" -f $gh.Groups[1].Value, $gh.Groups[2].Value, $info.sha }
    } catch { Warn "API GitHub indisponible : lecture directe de la branche (cache de quelques minutes possible)." }
}

function Get-Remote($rel) {
    $enc = ($rel -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
    return "$Url/files/$enc"
}

# ── manifest ───────────────────────────────────────────────────
Info "lecture du manifest…"
try { $manifestText = (Invoke-WebRequest -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } -Uri "$Url/manifest.txt?t=$([DateTimeOffset]::Now.ToUnixTimeSeconds())").Content }
catch { Fail "manifest introuvable : $($_.Exception.Message)"; exit 1 }

$remoteVersion = '?'; $remoteDate = ''
$protected = New-Object System.Collections.Generic.List[string]
$files = @{}      # rel -> @{ h=...; s=... }
foreach ($line in ($manifestText -split "`n")) {
    $line = $line.TrimEnd("`r")
    if (-not $line) { continue }
    $parts = $line -split "`t"
    if ($parts[0] -eq '#version') { $remoteVersion = $parts[1]; if ($parts.Count -gt 2) { $remoteDate = $parts[2] }; continue }
    if ($parts[0] -eq '#protected') { $protected.Add($parts[1]); continue }
    if ($parts.Count -lt 3) { continue }
    $rel = $parts[2]
    if ($rel -notmatch '^resources/' -or $rel -match '(^|/)\.\.(/|$)') { continue }
    $files[$rel] = @{ h = $parts[0]; s = [int64]$parts[1] }
}
if ($files.Count -eq 0) { Fail "manifest vide ou invalide."; exit 1 }

function GlobToRegex($g) {
    $r = [regex]::Escape($g).Replace('\*\*/', '§§/').Replace('\*\*', '§§').Replace('\*', '[^/]*')
    $r = $r.Replace('§§/', '(?:.*/)?').Replace('§§', '.*')
    return "^$r$"
}
$protectedRe = $protected | ForEach-Object { GlobToRegex $_ }
function IsProtected($rel) { foreach ($re in $protectedRe) { if ($rel -match $re) { return $true } }; return $false }

# ── état installé ──────────────────────────────────────────────
$installed = @{}; $installedVersion = 'inconnue'
if (Test-Path -LiteralPath $stateFile) {
    foreach ($line in (Get-Content -LiteralPath $stateFile)) {
        $p = $line -split "`t"
        if ($p[0] -eq '#version') { $installedVersion = $p[1]; continue }
        if ($p.Count -ge 2) { $installed[$p[1]] = $p[0] }
    }
} elseif (Test-Path -LiteralPath $stateJson) {
    try {
        $js = Get-Content -LiteralPath $stateJson -Raw | ConvertFrom-Json
        if ($js.version) { $installedVersion = $js.version }
        if ($js.files) { foreach ($prop in $js.files.PSObject.Properties) { $installed[$prop.Name] = $prop.Value } }
    } catch {}
}

function Sha256($path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLower() }

# ── plan ───────────────────────────────────────────────────────
$download = @(); $skipped = @(); $deleted = @(); $kept = @(); $same = @{}; $unchanged = 0
$rels = $files.Keys | Sort-Object
$firstRun = ($installed.Count -eq 0)
if ($firstRun) { Info "première vérification : empreinte de chaque fichier ($($rels.Count)), patiente une à deux minutes…" }
$i = 0
foreach ($rel in $rels) {
    $i++
    if ($firstRun -and ($i % 500 -eq 0)) { Info "vérification $i / $($rels.Count)…" }
    $remote = $files[$rel]
    $abs = Join-Path $root ($rel -replace '/', '\')
    $exists = Test-Path -LiteralPath $abs -PathType Leaf
    $localHash = $null
    if ($exists) {
        if ($installed.ContainsKey($rel) -and $installed[$rel] -eq $remote.h) { $localHash = $remote.h }
        else { $localHash = Sha256 $abs }
    }
    if ($localHash -eq $remote.h) { $unchanged++; $same[$rel] = $remote.h; continue }
    $inst = $installed[$rel]
    $modified = ($localHash -ne $null) -and ($inst -ne $null) -and ($localHash -ne $inst)
    $unknownProtected = ($localHash -ne $null) -and ($inst -eq $null) -and (IsProtected $rel)
    if (-not $Force -and ($modified -or $unknownProtected)) {
        $skipped += @{ rel = $rel; h = $remote.h; reason = $(if ($modified) { 'modifié localement' } else { 'fichier protégé (état inconnu)' }) }
    } else {
        $download += @{ rel = $rel; h = $remote.h; s = $remote.s; existed = $exists }
    }
}
foreach ($rel in @($installed.Keys)) {
    if ($files.ContainsKey($rel)) { continue }
    if ($rel -notmatch '^resources/' -or (IsProtected $rel)) { continue }
    $abs = Join-Path $root ($rel -replace '/', '\')
    if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) { continue }
    if ($Force -or ((Sha256 $abs) -eq $installed[$rel])) { $deleted += $rel } else { $kept += $rel }
}

$totalBytes = ($download | ForEach-Object { $_.s } | Measure-Object -Sum).Sum
if (-not $totalBytes) { $totalBytes = 0 }
Info ("version {0} → {1} : {2} fichier(s) à télécharger ({3:N1} Ko), {4} modifié(s) localement, {5} à supprimer, {6} à jour." -f $installedVersion, $remoteVersion, $download.Count, ($totalBytes / 1KB), $skipped.Count, $deleted.Count, $unchanged)

if ($Check) {
    foreach ($d in $download) { Write-Host ("  + {0}{1}" -f $d.rel, $(if ($d.existed) { '' } else { '  (nouveau)' })) -ForegroundColor Green }
    foreach ($s in $skipped) { Write-Host ("  ~ {0}  → {1}, sera posé en .new" -f $s.rel, $s.reason) -ForegroundColor Yellow }
    foreach ($d in $deleted) { Write-Host "  - $d" -ForegroundColor Red }
    foreach ($k in $kept) { Write-Host "  ! $k  (supprimé par la mise à jour mais modifié localement : conservé)" -ForegroundColor Yellow }
    if ($download.Count -eq 0 -and $skipped.Count -eq 0 -and $deleted.Count -eq 0) { Info "rien à faire, la base est à jour." }
    exit 0
}

# ── application ────────────────────────────────────────────────
# Les chemins contiennent des crochets ([core]) : PowerShell les lit comme des jokers dans
# -Path/-OutFile. On télécharge dans un dossier temporaire sans crochets et on copie
# avec les méthodes .NET (chemins littéraux).
$tmpDir = Join-Path $env:TEMP ('bestdev-update-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($tmpDir) | Out-Null
$tmpN = 0
$backupRoot = Join-Path $updaterDir ("backup\" + ($remoteVersion -replace '[^\w.-]', '_'))
$newState = @{}; foreach ($k in $installed.Keys) { $newState[$k] = $installed[$k] }
$errors = 0; $touched = @{}
$n = 0
foreach ($d in $download) {
    $n++
    $abs = Join-Path $root ($d.rel -replace '/', '\')
    $tmpN++; $tmp = Join-Path $tmpDir "$tmpN.tmp"
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $abs)) | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri (Get-Remote $d.rel) -OutFile $tmp
        if ((Sha256 $tmp) -ne $d.h) { throw "hash différent après téléchargement" }
        if ($d.existed) {
            $bak = Join-Path $backupRoot ($d.rel -replace '/', '\')
            [IO.Directory]::CreateDirectory((Split-Path -Parent $bak)) | Out-Null
            [IO.File]::Copy($abs, $bak, $true)
        }
        [IO.File]::Copy($tmp, $abs, $true)
        [IO.File]::Delete($tmp)
        $newState[$d.rel] = $d.h
        $m = [regex]::Match($d.rel, '^resources/(?:\[[^\]]+\]/)*([^/\[]+)/'); if ($m.Success) { $touched[$m.Groups[1].Value] = $true }
        if ($n % 25 -eq 0) { Info "$n / $($download.Count) fichiers…" }
    } catch {
        $errors++
        Fail ("échec : {0} — {1}" -f $d.rel, $_.Exception.Message)
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
}
foreach ($s in $skipped) {
    $abs = Join-Path $root ($s.rel -replace '/', '\')
    $tmpN++; $tmp = Join-Path $tmpDir "$tmpN.tmp"
    try { Invoke-WebRequest -UseBasicParsing -Uri (Get-Remote $s.rel) -OutFile $tmp; [IO.File]::Copy($tmp, "$abs.new", $true); [IO.File]::Delete($tmp); Warn ("{0} : {1} → nouvelle version dans {0}.new" -f $s.rel, $s.reason) }
    catch { $errors++; Fail ("échec (.new) : {0} — {1}" -f $s.rel, $_.Exception.Message) }
}
foreach ($rel in $deleted) {
    $abs = Join-Path $root ($rel -replace '/', '\')
    try {
        $bak = Join-Path $backupRoot ($rel -replace '/', '\')
        [IO.Directory]::CreateDirectory((Split-Path -Parent $bak)) | Out-Null
        [IO.File]::Copy($abs, $bak, $true)
        [IO.File]::Delete($abs)
        $newState.Remove($rel)
        $m = [regex]::Match($rel, '^resources/(?:\[[^\]]+\]/)*([^/\[]+)/'); if ($m.Success) { $touched[$m.Groups[1].Value] = $true }
    } catch { $errors++; Fail ("suppression impossible : {0} — {1}" -f $rel, $_.Exception.Message) }
}
foreach ($k in $kept) { Warn "$k : supprimé par la mise à jour mais modifié localement, conservé." }
try { [IO.Directory]::Delete($tmpDir, $true) } catch {}
foreach ($k in $same.Keys) { $newState[$k] = $same[$k] }

# ── état ───────────────────────────────────────────────────────
$stateVersion = $(if ($errors -gt 0) { $installedVersion } else { $remoteVersion })
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("#version`t$stateVersion`t$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))")
foreach ($k in ($newState.Keys | Sort-Object)) { [void]$sb.AppendLine("$($newState[$k])`t$k") }
[IO.File]::WriteAllText($stateFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
if (Test-Path -LiteralPath $stateJson) { Remove-Item -LiteralPath $stateJson -Force -ErrorAction SilentlyContinue }

if ($errors -gt 0) { Fail "$errors erreur(s). Relance update.bat pour réessayer." }
elseif ($download.Count -eq 0 -and $deleted.Count -eq 0) { Info "rien à faire, la base est à jour." }
else { Info "mise à jour $remoteVersion appliquée. Sauvegarde des anciens fichiers : $backupRoot" }
if ($touched.Count -gt 0) {
    Info ("ressources à redémarrer : " + (($touched.Keys | Sort-Object) -join ', ') + "   (ou redémarre le serveur)")
    if ($download | Where-Object { -not $_.existed -and $_.rel -match '/fxmanifest\.lua$' }) { Warn 'une nouvelle ressource a été ajoutée : vérifie les ensure de server.cfg.' }
}
exit $(if ($errors -gt 0) { 1 } else { 0 })
