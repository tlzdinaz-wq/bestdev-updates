---@meta _
---@diagnostic disable: duplicate-doc-field

local Cfg = SN_SAMS.Config.Stretcher
local MAX_DISTANCE = 2.75

local stretcherModelSet = {}
for _, hash in ipairs(Cfg.modelHashes) do
    stretcherModelSet[GetHashKey(hash)] = true
end

local ambulanceConfigMap = {}
for _, config in ipairs(Cfg.Vehicles) do
    ambulanceConfigMap[GetHashKey(config.modelHash)] = config
end

--- Check if vehicle is a stretcher within interaction distance
---@param vehicle number
---@return boolean
local function isStretcherNearby(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    if not stretcherModelSet[GetEntityModel(vehicle)] then return false end
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(vehicle))
    return distance < MAX_DISTANCE
end

--- Check if player is on-duty SAMS/LSFD
---@param vehicle number
---@return boolean
local function isStretcherNearbyOnDuty(vehicle)
    return isStretcherNearby(vehicle) and SN_SAMS.IsOnDuty()
end

--- Check if vehicle is a supported ambulance with stretcher extra
---@param vehicle number
---@return boolean
local function isAmbulanceWithStretcher(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    if stretcherModelSet[GetEntityModel(vehicle)] then return false end
    local config = ambulanceConfigMap[GetEntityModel(vehicle)]
    if not config or not config.stretcherExtra then return false end
    if not SN_SAMS.IsOnDuty() then return false end
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(vehicle))
    if distance > (config.dist or 8.0) then return false end
    return DoesExtraExist(vehicle, config.stretcherExtra) and IsVehicleExtraTurnedOn(vehicle, config.stretcherExtra)
end

-- ============================================================
-- Context menu: Sortir le brancard (ambulance vehicles)
-- ============================================================

VFW.ContextAddButton("vehicle", ":home: Sortir le brancard", function(vehicle)
    return isAmbulanceWithStretcher(vehicle)
end, function(vehicle)
    VFW.OpenContextMenu()
    TriggerEvent("sn_sams:stretcher:deployFromVehicle", VehToNet(vehicle))
end)

-- ============================================================
-- Catégorie: Actions
-- ============================================================

VFW.ContextAddButton("vehicle", " Se lever", function(vehicle)
    return isStretcherNearby(vehicle) and IsEntityAttachedToEntity(PlayerPedId(), vehicle)
end, function()
    TriggerEvent("StretcherGetUp")
end)

VFW.ContextAddButton("vehicle", ":door: Sortir du véhicule", function(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    if not IsEntityAttachedToEntity(PlayerPedId(), vehicle) then return false end
    return ambulanceConfigMap[GetEntityModel(vehicle)] ~= nil
end, function()
    TriggerEvent("StretcherGetUp")
end)

VFW.ContextAddButton("vehicle", ":car: Pousser le brancard", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end, function()
    TriggerEvent("StretcherTake")
end)

-- ============================================================
-- Catégorie: Équipement (en service uniquement)
-- ============================================================

local equipementMenu = VFW.ContextAddSubmenu("vehicle", " Équipement", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end)

VFW.ContextAddButton("vehicle", ":home: Tête-repos", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end, function()
    TriggerEvent("ToggleHeadrest")
end, {}, equipementMenu)

VFW.ContextAddButton("vehicle", " Plan dur", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end, function()
    TriggerEvent("ToggleBackboard")
end, {}, equipementMenu)

VFW.ContextAddButton("vehicle", " Moniteur", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end, function()
    TriggerEvent("ToggleMonitor")
end, {}, equipementMenu)

VFW.ContextAddButton("vehicle", " Sac rouge", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end, function()
    TriggerEvent("ToggleRedBag")
end, {}, equipementMenu)

VFW.ContextAddButton("vehicle", " Sac bleu", function(vehicle)
    return isStretcherNearbyOnDuty(vehicle)
end, function()
    TriggerEvent("ToggleBlueBag")
end, {}, equipementMenu)

-- ============================================================
-- Catégorie: Positions assises
-- ============================================================

local assisMenu = VFW.ContextAddSubmenu("vehicle", ":box: Positions assises", function(vehicle)
    return isStretcherNearby(vehicle)
end)

VFW.ContextAddButton("vehicle", ":arrow: À droite", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherSitRight")
end, {}, assisMenu)

VFW.ContextAddButton("vehicle", ":back: À gauche", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherSitLeft")
end, {}, assisMenu)

VFW.ContextAddButton("vehicle", ":arrow: Au bout", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherSitEnd")
end, {}, assisMenu)

VFW.ContextAddButton("vehicle", ":arrow: Droit", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherSitUpright")
end, {}, assisMenu)

VFW.ContextAddButton("vehicle", " Jambes croisées", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherSitUprightLegsCrossed")
end, {}, assisMenu)

VFW.ContextAddButton("vehicle", " Genoux repliés", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherSitUprightKneesTucked")
end, {}, assisMenu)

-- ============================================================
-- Catégorie: Positions allongées
-- ============================================================

local allongeMenu = VFW.ContextAddSubmenu("vehicle", " Positions allongées", function(vehicle)
    return isStretcherNearby(vehicle)
end)

VFW.ContextAddButton("vehicle", ":back: Sur le côté", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherLieBack")
end, {}, allongeMenu)

VFW.ContextAddButton("vehicle", ":arrow: À plat ventre", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherLieProne")
end, {}, allongeMenu)

VFW.ContextAddButton("vehicle", "↗ Semi-allongé", function(vehicle)
    return isStretcherNearby(vehicle)
end, function()
    TriggerEvent("StretcherLieUpright")
end, {}, allongeMenu)
