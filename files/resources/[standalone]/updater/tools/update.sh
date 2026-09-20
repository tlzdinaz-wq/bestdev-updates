#!/usr/bin/env bash
# Mise à jour de la base — Linux, à lancer à côté du serveur (./update.sh à la racine).
#   ./update.sh            vérifie puis applique (télécharge uniquement les fichiers modifiés)
#   ./update.sh check      liste ce qui changerait, sans rien toucher
#   ./update.sh force      écrase aussi les fichiers modifiés localement
# Source : update_url dans server.cfg (racine HTTP contenant manifest.txt et files/…).
# Dépendances : bash, curl, sha256sum (coreutils).
set -u

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATER_DIR="$(dirname "$TOOLS_DIR")"
ROOT="$(cd "$UPDATER_DIR/../../.." && pwd)"
STATE="$UPDATER_DIR/state.txt"
STATE_JSON="$UPDATER_DIR/state.json"
MODE="${1:-}"
FORCE=0; CHECK=0
[ "$MODE" = "force" ] && FORCE=1
[ "$MODE" = "check" ] && CHECK=1

info()  { printf '\033[36m[update]\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m[update]\033[0m %s\n' "$*"; }
fail()  { printf '\033[31m[update]\033[0m %s\n' "$*"; }

command -v curl >/dev/null || { fail "curl est requis."; exit 1; }
command -v sha256sum >/dev/null || { fail "sha256sum est requis."; exit 1; }

URL="${UPDATE_URL:-}"
if [ -z "$URL" ] && [ -f "$ROOT/server.cfg" ]; then
  URL="$(sed -nE 's/^[[:space:]]*set[[:space:]]+update_url[[:space:]]+"([^"]+)".*/\1/p' "$ROOT/server.cfg" | head -n1)"
fi
[ -z "$URL" ] && { fail 'update_url introuvable : ajoute set update_url "https://…" dans server.cfg (ou variable UPDATE_URL).'; exit 1; }
URL="${URL%/}"

# GitHub : lire depuis le commit exact (raw.githubusercontent met la branche en cache)
if [[ "$URL" =~ ^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/?$ ]]; then
  U="${BASH_REMATCH[1]}"; R="${BASH_REMATCH[2]}"; B="${BASH_REMATCH[3]}"
  SHA="$(curl -fsSL -H 'User-Agent: bestdev-updater' "https://api.github.com/repos/$U/$R/commits/$B" 2>/dev/null | sed -nE 's/^[[:space:]]*"sha":[[:space:]]*"([0-9a-f]{40})".*/\1/p' | head -n1)"
  if [ -n "$SHA" ]; then URL="https://raw.githubusercontent.com/$U/$R/$SHA"; else warn "API GitHub indisponible : lecture directe de la branche (cache de quelques minutes possible)."; fi
fi

urlencode() { local s="$1" out="" c; for (( i=0; i<${#s}; i++ )); do c="${s:i:1}"; case "$c" in [a-zA-Z0-9.~_/-]) out+="$c";; *) out+="$(printf '%%%02X' "'$c")";; esac; done; printf '%s' "$out"; }
remote_url() { printf '%s/files/%s' "$URL" "$(urlencode "$1")"; }
hash_of() { sha256sum "$1" | cut -d' ' -f1; }

TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
info "lecture du manifest…"
curl -fsSL -H 'Cache-Control: no-cache' "$URL/manifest.txt?t=$(date +%s)" -o "$TMPD/manifest.txt" || { fail "manifest introuvable ($URL/manifest.txt)."; exit 1; }

REMOTE_VERSION="?"; PROTECTED=()
declare -A FILES SIZES INSTALLED NEWSTATE SAME
while IFS=$'\t' read -r a b c; do
  case "$a" in
    '#version') REMOTE_VERSION="$b";;
    '#protected') PROTECTED+=("$b");;
    '') ;;
    *) [[ "$c" == resources/* ]] || continue; [[ "$c" == *"/../"* || "$c" == ../* ]] && continue; FILES["$c"]="$a"; SIZES["$c"]="$b";;
  esac
done < "$TMPD/manifest.txt"
[ "${#FILES[@]}" -eq 0 ] && { fail "manifest vide ou invalide."; exit 1; }

# glob → regex (** = plusieurs dossiers, * = dans un segment)
glob_re() { local g="$1"; g="$(printf '%s' "$g" | sed -e 's/[.+^$(){}|\\]/\\&/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')"; g="${g//\*\*\//§§/}"; g="${g//\*\*/§§}"; g="${g//\*/[^\/]*}"; g="${g//§§\//(.*\/)?}"; g="${g//§§/.*}"; printf '^%s$' "$g"; }
PROT_RE=(); for p in "${PROTECTED[@]}"; do PROT_RE+=("$(glob_re "$p")"); done
is_protected() { local rel="$1" re; for re in "${PROT_RE[@]}"; do [[ "$rel" =~ $re ]] && return 0; done; return 1; }

INSTALLED_VERSION="inconnue"
if [ -f "$STATE" ]; then
  while IFS=$'\t' read -r a b c; do
    if [ "$a" = '#version' ]; then INSTALLED_VERSION="$b"; elif [ -n "$b" ]; then INSTALLED["$b"]="$a"; fi
  done < "$STATE"
elif [ -f "$STATE_JSON" ]; then
  INSTALLED_VERSION="$(sed -nE 's/.*"version":[[:space:]]*"([^"]+)".*/\1/p' "$STATE_JSON" | head -n1)"
  while IFS= read -r line; do INSTALLED["${line#*|}"]="${line%%|*}"; done < <(tr ',' '\n' < "$STATE_JSON" | sed -nE 's/.*"(resources\/[^"]+)":[[:space:]]*"([0-9a-f]{64})".*/\2|\1/p')
fi

DOWNLOAD=(); SKIPPED=(); DELETED=(); KEPT=(); UNCHANGED=0; TOTAL=0
mapfile -t RELS < <(printf '%s\n' "${!FILES[@]}" | sort)
FIRST=0; [ "${#INSTALLED[@]}" -eq 0 ] && FIRST=1 && info "première vérification : empreinte de chaque fichier (${#RELS[@]}), patiente une à deux minutes…"
i=0
for rel in "${RELS[@]}"; do
  i=$((i+1)); [ $FIRST -eq 1 ] && [ $((i % 500)) -eq 0 ] && info "vérification $i / ${#RELS[@]}…"
  remote="${FILES[$rel]}"; abs="$ROOT/$rel"; local_hash=""
  if [ -f "$abs" ]; then
    if [ "${INSTALLED[$rel]:-}" = "$remote" ]; then local_hash="$remote"; else local_hash="$(hash_of "$abs")"; fi
  fi
  if [ "$local_hash" = "$remote" ]; then UNCHANGED=$((UNCHANGED+1)); SAME["$rel"]="$remote"; continue; fi
  inst="${INSTALLED[$rel]:-}"
  modified=0; [ -n "$local_hash" ] && [ -n "$inst" ] && [ "$local_hash" != "$inst" ] && modified=1
  unkprot=0; [ -n "$local_hash" ] && [ -z "$inst" ] && is_protected "$rel" && unkprot=1
  if [ $FORCE -eq 0 ] && { [ $modified -eq 1 ] || [ $unkprot -eq 1 ]; }; then
    if [ $modified -eq 1 ]; then SKIPPED+=("$rel|modifié localement"); else SKIPPED+=("$rel|fichier protégé (état inconnu)"); fi
  else
    ex=0; [ -n "$local_hash" ] && ex=1
    DOWNLOAD+=("$rel|$ex"); TOTAL=$((TOTAL + ${SIZES[$rel]:-0}))
  fi
done
for rel in "${!INSTALLED[@]}"; do
  [ -n "${FILES[$rel]:-}" ] && continue
  [[ "$rel" == resources/* ]] || continue
  is_protected "$rel" && continue
  abs="$ROOT/$rel"; [ -f "$abs" ] || continue
  if [ $FORCE -eq 1 ] || [ "$(hash_of "$abs")" = "${INSTALLED[$rel]}" ]; then DELETED+=("$rel"); else KEPT+=("$rel"); fi
done

info "version $INSTALLED_VERSION → $REMOTE_VERSION : ${#DOWNLOAD[@]} fichier(s) à télécharger ($((TOTAL/1024)) Ko), ${#SKIPPED[@]} modifié(s) localement, ${#DELETED[@]} à supprimer, $UNCHANGED à jour."

if [ $CHECK -eq 1 ]; then
  for d in "${DOWNLOAD[@]}"; do rel="${d%|*}"; ex="${d#*|}"; printf '  \033[32m+\033[0m %s%s\n' "$rel" "$([ "$ex" = 0 ] && echo '  (nouveau)')"; done
  for s in "${SKIPPED[@]}"; do printf '  \033[33m~\033[0m %s  → %s, sera posé en .new\n' "${s%|*}" "${s#*|}"; done
  for d in "${DELETED[@]}"; do printf '  \033[31m-\033[0m %s\n' "$d"; done
  for k in "${KEPT[@]}"; do printf '  \033[33m!\033[0m %s  (supprimé par la mise à jour mais modifié localement : conservé)\n' "$k"; done
  [ "${#DOWNLOAD[@]}" -eq 0 ] && [ "${#SKIPPED[@]}" -eq 0 ] && [ "${#DELETED[@]}" -eq 0 ] && info "rien à faire, la base est à jour."
  exit 0
fi

BACKUP="$UPDATER_DIR/backup/$(printf '%s' "$REMOTE_VERSION" | tr -c 'A-Za-z0-9._-' '_')"
for k in "${!INSTALLED[@]}"; do NEWSTATE["$k"]="${INSTALLED[$k]}"; done
# téléchargements dans le dossier temporaire puis déplacés (jamais de fichier temporaire dans resources/)
ERRORS=0; declare -A TOUCHED=(); n=0; tn=0
res_of() { local r="${1#resources/}" seg; IFS='/' read -ra segs <<< "$r"; for seg in "${segs[@]}"; do [[ "$seg" == \[* ]] && continue; printf '%s' "$seg"; return; done; }
for d in "${DOWNLOAD[@]}"; do
  rel="${d%|*}"; ex="${d#*|}"; abs="$ROOT/$rel"; n=$((n+1)); tn=$((tn+1)); tmp="$TMPD/$tn.tmp"
  mkdir -p "$(dirname "$abs")"
  if curl -fsSL "$(remote_url "$rel")" -o "$tmp" && [ "$(hash_of "$tmp")" = "${FILES[$rel]}" ]; then
    if [ "$ex" = 1 ]; then mkdir -p "$(dirname "$BACKUP/$rel")"; cp -p "$abs" "$BACKUP/$rel" 2>/dev/null; fi
    if mv -f "$tmp" "$abs"; then NEWSTATE["$rel"]="${FILES[$rel]}"; TOUCHED["$(res_of "$rel")"]=1; else ERRORS=$((ERRORS+1)); fail "écriture impossible : $rel"; rm -f "$tmp"; fi
  else
    ERRORS=$((ERRORS+1)); fail "échec : $rel (téléchargement ou hash différent)"; rm -f "$tmp"
  fi
  [ $((n % 25)) -eq 0 ] && info "$n / ${#DOWNLOAD[@]} fichiers…"
done
for s in "${SKIPPED[@]}"; do
  rel="${s%|*}"; abs="$ROOT/$rel"; mkdir -p "$(dirname "$abs")"; tn=$((tn+1)); tmp="$TMPD/$tn.tmp"
  if curl -fsSL "$(remote_url "$rel")" -o "$tmp" && mv -f "$tmp" "$abs.new"; then warn "$rel : ${s#*|} → nouvelle version dans $rel.new"; else ERRORS=$((ERRORS+1)); fail "échec (.new) : $rel"; rm -f "$tmp"; fi
done
for rel in "${DELETED[@]}"; do
  abs="$ROOT/$rel"; mkdir -p "$(dirname "$BACKUP/$rel")"; cp -p "$abs" "$BACKUP/$rel" 2>/dev/null
  if rm -f "$abs"; then unset 'NEWSTATE[$rel]'; TOUCHED["$(res_of "$rel")"]=1; else ERRORS=$((ERRORS+1)); fail "suppression impossible : $rel"; fi
done
for k in "${KEPT[@]}"; do warn "$k : supprimé par la mise à jour mais modifié localement, conservé."; done
for k in "${!SAME[@]}"; do NEWSTATE["$k"]="${SAME[$k]}"; done

STATE_VERSION="$REMOTE_VERSION"; [ $ERRORS -gt 0 ] && STATE_VERSION="$INSTALLED_VERSION"
{ printf '#version\t%s\t%s\n' "$STATE_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; printf '%s\n' "${!NEWSTATE[@]}" | sort | while IFS= read -r k; do printf '%s\t%s\n' "${NEWSTATE[$k]}" "$k"; done; } > "$STATE"
rm -f "$STATE_JSON"

if [ $ERRORS -gt 0 ]; then fail "$ERRORS erreur(s). Relance ./update.sh pour réessayer."
elif [ "${#DOWNLOAD[@]}" -eq 0 ] && [ "${#DELETED[@]}" -eq 0 ]; then info "rien à faire, la base est à jour."
else info "mise à jour $REMOTE_VERSION appliquée. Sauvegarde des anciens fichiers : $BACKUP"; fi
if [ "${#TOUCHED[@]}" -gt 0 ]; then
  info "ressources à redémarrer : $(printf '%s\n' "${!TOUCHED[@]}" | sort | tr '\n' ' ')  (ou redémarre le serveur)"
  for d in "${DOWNLOAD[@]}"; do rel="${d%|*}"; ex="${d#*|}"; if [ "$ex" = 0 ] && [[ "$rel" == */fxmanifest.lua ]]; then warn "une nouvelle ressource a été ajoutée : vérifie les ensure de server.cfg."; break; fi; done
fi
exit $(( ERRORS > 0 ? 1 : 0 ))
