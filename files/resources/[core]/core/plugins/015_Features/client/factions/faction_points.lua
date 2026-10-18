---@meta _
---@diagnostic disable: duplicate-doc-field

-- Points de faction : leur presence dans le monde.
--
-- Le panneau de gestion fait placer quatre points par faction, mais un seul etait lu
-- par le jeu : le craft (voir faction_craft.lua). Les trois autres etaient enregistres
-- et jamais utilises — pas de zone, pas de marqueur, pas de blip. Le staff les plaçait
-- et ne les retrouvait nulle part.
--
-- Ce fichier pose une zone sur chaque point configure, pour les membres de la faction
-- concernee uniquement, et un blip sur la carte.
--
-- Le craft garde son propre fichier : il a sa logique de recettes et fonctionnait
-- deja. On ne lui pose donc ici qu'un blip, pas une seconde zone.

local ZONE_RADIUS <const> = 1.5

local STYLE <const> = {
    laboratory = { blip = 499, color = 5, action = nil },
    craft = { blip = 566, color = 49, action = nil },
    storage = { blip = 478, color = 2, action = "storage" },
    garage = { blip = 357, color = 3, action = nil },
}

local zones = {}
local blips = {}

local function clearPoints()
    for i = 1, #zones do
        Worlds.Zone.Remove(zones[i])
    end
    zones = {}

    for i = 1, #blips do
        if DoesBlipExist(blips[i]) then RemoveBlip(blips[i]) end
    end
    blips = {}
end

---@param pos table
---@param label string
---@param style table
local function addBlip(pos, label, style)
    local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, style.blip)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, style.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)

    blips[#blips + 1] = blip
end

--- Le stockage de la faction : un coffre partage, identifie par le nom de la faction.
local function openStorage()
    local faction = VFW.PlayerData and VFW.PlayerData.faction
    local name = type(faction) == "table" and faction.name or faction
    if type(name) ~= "string" or name == "" then return end

    VFW.OpenChest("faction_" .. name, "stockage", 100)
end

local ACTIONS <const> = {
    storage = openStorage,
}

---@param point table
local function addZone(point)
    local style = STYLE[point.id]
    if not style then return end

    addBlip(point.pos, point.label, style)

    -- Le craft a deja sa zone et sa logique ailleurs : on ne la doublerait que pour
    -- lui poser une seconde invite au meme endroit.
    local action = style.action and ACTIONS[style.action]
    if not action then return end

    local key = ("Faction:%s"):format(point.id)

    zones[#zones + 1] = Worlds.Zone.Create(point.pos, ZONE_RADIUS, false, function()
        VFW.RegisterInteraction(key, action)
    end, function()
        VFW.RemoveInteraction(key)
    end, point.label, "E", "CraftIllegal", { "#FF3939", "#FF0000" })
end

local function loadPoints()
    clearPoints()

    local points = TriggerServerCallback("core:faction:getHubPoints")
    if type(points) ~= "table" then return end

    for i = 1, #points do
        addZone(points[i])
    end
end

RegisterNetEvent("vfw:setFaction", function()
    loadPoints()
end)

-- Le staff vient de modifier une faction : les positions ont pu bouger, ou la faction
-- vient d'etre activee.
RegisterNetEvent("core:gestion-factions:refresh", function()
    loadPoints()
end)

RegisterNetEvent("vfw:playerLoaded", function()
    while not VFW.PlayerData do Wait(1000) end
    while not VFW.PlayerData.faction do Wait(1000) end

    loadPoints()
end)

AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() ~= resource then return end
    clearPoints()
end)
