---@type table Framework detection (bridge.shared.framework): this file does nothing unless it is VFW.
local framework = require 'bridge.shared.framework'
if framework.name ~= 'vfw' then return end

---@type table sd-phone config root (configs/config.lua).
local config = require 'configs.config'
---@type table Services config (configs/services.lua): Companies, plus the Auto block read here.
local SV     = config.Services
---@type table Auto block of the Services config; Enabled = false leaves the hand-written list alone.
local AUTO   = SV.Auto or {}
if AUTO.Enabled == false then return end

---@type table core-export helpers (bridge.shared.vfw).
local vfw = require 'bridge.shared.vfw'

-- L'annuaire de l'application Services vient de deux sources :
--   * `Companies` (configs/services.lua), écrit à la main : c'est là que vivent les lignes
--     téléphoniques (911...). Ces entrées sont prioritaires pour un même métier ;
--   * TOUS les métiers du serveur, lus par l'export PhoneCompanies : ceux déjà en base comme ceux
--     créés ensuite dans Gestion (builder de métiers de core). Le logo, l'adresse, la position et
--     la couleur d'accent viennent de la société du métier quand elle existe ; un métier qui n'en
--     a pas encore apparaît quand même, avec un badge emoji.
-- La liste est réécrite EN PLACE (SV.Companies reste la même table) parce que plusieurs modules la
-- tiennent par référence ; leurs index sont reconstruits juste après.

---@type table[] Entrées écrites à la main, figées avant que la liste devienne dynamique.
local STATIC = {}
for i, company in ipairs(SV.Companies or {}) do STATIC[i] = company end

SV.Companies = SV.Companies or {}
---@type table[] La liste vivante, vue par tous les modules.
local LIVE = SV.Companies

---@param array string[]|nil
---@return table<string, true>
local function setOf(array)
    local out = {}
    for _, value in ipairs(type(array) == 'table' and array or {}) do out[value] = true end
    return out
end

---@type table<string, true> Métiers jamais listés.
local EXCLUDE_JOBS  = setOf(AUTO.ExcludeJobs)
---@type table<string, true> Types de société jamais listés.
local EXCLUDE_TYPES = setOf(AUTO.ExcludeTypes)
---@type table<string, true> Métiers sans emploi, jamais une entreprise.
local NO_JOB        = setOf(SV.JobBlacklist or { 'unemployed' })
NO_JOB[SV.UnemployedJob or 'unemployed'] = true

---Copie superficielle d'une entrée de config, pour lui ajouter des champs sans toucher l'original.
---@param entry table
---@return table
local function copyOf(entry)
    local out = {}
    for k, v in pairs(entry) do out[k] = v end
    return out
end

---@param society table entrée de PhoneCompanies
---@return table style { emoji, color } du type de la société, sinon le style par défaut
local function styleFor(society)
    local types = type(AUTO.Types) == 'table' and AUTO.Types or {}
    return types[society.type] or AUTO.Default or {}
end

---Une entreprise du téléphone à partir d'un métier (et de sa société, si elle existe).
---@param society table entrée de PhoneCompanies
---@return table company
local function companyFrom(society)
    local style = styleFor(society)
    local default = AUTO.Default or {}

    return {
        job      = society.name,
        label    = society.label,
        location = society.address or '',
        -- Le badge sans logo : l'accent choisi dans le builder, sinon celui du type.
        color    = society.color or style.color or default.color or '#5E5CE6',
        emoji    = style.emoji or default.emoji or '🏢',
        logo     = society.logo,
        canCall  = false,
        coords   = society.position,
    }
end

---Complète une entrée écrite à la main avec ce que Gestion sait de la même entreprise : le logo
---toujours, l'adresse et la position seulement si la config n'en donne pas.
---@param entry table copie de l'entrée de config
---@param society table entrée de PhoneCompanies
local function enrich(entry, society)
    entry.logo = entry.logo or society.logo
    if entry.location == nil or entry.location == '' then entry.location = society.address or '' end
    if entry.coords == nil then entry.coords = society.position end
end

---Recompose la liste vivante : entrées à la main d'abord (ordre de la config), puis les sociétés
---de Gestion par ordre alphabétique.
---@return boolean refreshed faux quand core ne répond pas (la liste reste telle quelle)
local function refresh()
    local societies = vfw.call('PhoneCompanies')
    if type(societies) ~= 'table' then return false end

    local byName = {}
    for _, society in ipairs(societies) do byName[society.name] = society end

    local merged, taken = {}, {}
    for _, entry in ipairs(STATIC) do
        local copy = copyOf(entry)
        local society = byName[entry.job]
        if society then enrich(copy, society) end
        merged[#merged + 1] = copy
        taken[entry.job] = true
    end

    for _, society in ipairs(societies) do
        if not taken[society.name]
            and not EXCLUDE_JOBS[society.name]
            and not EXCLUDE_TYPES[society.type or '']
            and not NO_JOB[society.name] then
            merged[#merged + 1] = companyFrom(society)
        end
    end

    for i = #LIVE, 1, -1 do LIVE[i] = nil end
    for i, company in ipairs(merged) do LIVE[i] = company end

    require('server.services.actions').refreshCompanies()
    require('server.services.invoices').refreshCompanies()
    return true
end

---@type boolean Une relecture est déjà programmée.
local queued = false

---Relecture groupée : créer un métier déclenche plusieurs rechargements de société d'affilée
---(création, grades, diffusion), une seule lecture suffit.
local function scheduleRefresh()
    if queued then return end
    queued = true
    SetTimeout(750, function()
        queued = false
        local ok, result = pcall(refresh)
        if not ok then
            print(('^1[sd-phone:vfw]^0 company directory refresh failed: %s'):format(tostring(result)))
        end
    end)
end

AddEventHandler('vfw:society:changed', scheduleRefresh)

-- core peut démarrer avant ou être redémarré après sd-phone : dans les deux cas, on relit dès
-- qu'il est là. `reboot_core` ne relance pas sd-phone.
AddEventHandler('onResourceStart', function(resource)
    if resource == 'core' then scheduleRefresh() end
end)

-- Premier remplissage : les sociétés se chargent un peu après le démarrage de core.
CreateThread(function()
    for _ = 1, 60 do
        if vfw.ready() and refresh() then
            local count = 0
            for _, company in ipairs(LIVE) do if company.logo then count = count + 1 end end
            print(('^2[sd-phone:vfw]^0 company directory: %d entries (%d with a logo)'):format(#LIVE, count))
            return
        end
        Wait(1000)
    end
    print('^3[sd-phone:vfw]^0 company directory: core never answered PhoneCompanies; using configs/services.lua only')
end)
