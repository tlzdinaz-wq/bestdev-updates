---
--- Locale / mentalité serveur (US ou FR).
--- Source unique de vérité pour la DEVISE et le FORMAT DES NOMBRES / DATES.
--- Chargé en `shared` via `config/*.lua` (donc côté client ET serveur, AVANT les
--- plugins), au même titre que `branding.lua`.
---
--- ⚠️ La LANGUE de l'interface reste le FRANÇAIS dans les deux modes. Seuls la
---    devise, le séparateur de nombres, les unités et le format de date changent.
---
--- SOURCE DE VÉRITÉ : le champ `uiModel` ("fr"/"us") du manifest branding du
---    panel EVE (https://panel.eve-rp.fr/api/branding/<slug>). Il est appliqué à
---    chaud, comme les couleurs/logos, via `ApplyMentaServer()` :
---      - serveur : plugins/000_framework/server/026_eve_branding.lua
---      - client  : plugins/000_framework/client/branding_nui.lua
---    La ConVar `core_menta_server` n'est plus qu'un DÉFAUT d'amorçage (avant que
---    le manifest ne soit chargé) et un fallback si le bridge est indisponible.
---
--- Pour formater un montant, NE PAS coder le symbole en dur : utiliser
---    `VFW.Math.FormatMoney(montant)` côté Lua (voir shared/011_math.lua)
---    ou `formatMoney(montant)` côté NUI (voir interface/src/utils/math.ts).
---

---@class LocalePreset
---@field currencySymbol string    Symbole de la devise ("$", "€")
---@field currencyPosition string  "prefix" ($1,000) ou "suffix" (1 000 €)
---@field thousandsSep string      Séparateur des milliers
---@field decimalSep string        Séparateur décimal
---@field currencyName string      Nom de la devise (au pluriel) pour les phrases
---@field currencyCode string      Code ISO (USD / EUR)
---@field speedUnit string         Unité de vitesse ("mph", "km/h")
---@field distanceUnit string      Unité de distance ("mi", "km")
---@field dateFormat string        Gabarit de date (dayjs-like)
---@field clock24h boolean         Horloge 24h (true) ou 12h AM/PM (false)

---@type table<string, LocalePreset>
local PRESETS = {
    US = {
        currencySymbol   = "$",
        currencyPosition = "prefix",
        thousandsSep     = ",",
        decimalSep       = ".",
        currencyName     = "dollars",
        currencyCode     = "USD",
        speedUnit        = "mph",
        distanceUnit     = "mi",
        dateFormat       = "MM/DD/YYYY",
        clock24h         = false,
    },
    FR = {
        currencySymbol   = "€",
        currencyPosition = "suffix",
        thousandsSep     = " ",
        decimalSep       = ",",
        currencyName     = "euros",
        currencyCode     = "EUR",
        speedUnit        = "km/h",
        distanceUnit     = "km",
        dateFormat       = "DD/MM/YYYY",
        clock24h         = true,
    },
}

--- Normalise une valeur de modèle (panel `uiModel`, ConVar, etc.) vers une clé de
--- preset. Accepte "fr"/"FR"/"us"/"US" (et variantes de casse/espaces).
---@param model any
---@return string|nil  "US" | "FR" | nil si non reconnu
local function normalizeMenta(model)
    if type(model) ~= "string" then return nil end
    local key = model:gsub("%s+", ""):upper()
    if PRESETS[key] then return key end
    return nil
end

-- Mentalité du serveur : "US" (défaut d'amorçage) ou "FR". Surchargée à chaud par
-- le panel via ApplyMentaServer(). La ConVar n'est qu'un fallback pré-manifest.
MENTA_SERVER = normalizeMenta(GetConvar("core_menta_server", "US")) or "US"

--- Preset de locale actif. Lecture seule côté appelant : consommer via
--- VFW.Math.FormatMoney (Lua) ou le helper NUI. Réassigné par ApplyMentaServer.
---@type LocalePreset
LOCALE = PRESETS[MENTA_SERVER]

--- Applique une mentalité serveur (US/FR) à chaud. Appelé par le pont branding
--- serveur ET client à partir du `uiModel` du panel. Met à jour `MENTA_SERVER`
--- et `LOCALE` (les helpers FormatMoney/GroupDigits relisent LOCALE à chaque appel,
--- donc le changement s'applique immédiatement aux formatages suivants).
---@param model any  "fr"/"us" (insensible à la casse) — ignoré si non reconnu
---@return boolean changed  true si la mentalité a effectivement changé
function ApplyMentaServer(model)
    local key = normalizeMenta(model)
    if not key then return false end
    if key == MENTA_SERVER then return false end
    MENTA_SERVER = key
    LOCALE = PRESETS[key]
    return true
end
