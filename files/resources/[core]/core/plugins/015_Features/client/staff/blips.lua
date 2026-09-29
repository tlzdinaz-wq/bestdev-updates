---@meta _
---@diagnostic disable: duplicate-doc-field

-- Blips staff : un blip par joueur connecté, envoyé par le serveur toutes les 2,5 s
-- (plugins/000_framework/server/006_staff.lua). Activé avec le mode staff / animateur,
-- retiré dès qu'il est coupé.

local blips = {}
local active = false

local function removeAll()
    for id, blip in pairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        blips[id] = nil
    end
end

local function labelFor(player)
    local label = ("[%s] %s"):format(player.id, player.name or "Joueur")
    if player.staff then return label .. " (staff)" end
    if player.job then return ("%s — %s"):format(label, player.job) end
    return label
end

local function applyStyle(blip, player)
    SetBlipSprite(blip, player.staff and 480 or 1)
    SetBlipScale(blip, player.staff and 0.85 or 0.75)
    SetBlipColour(blip, player.staff and 5 or 0)
    SetBlipAsShortRange(blip, false)
    SetBlipCategory(blip, 7)
    ShowHeadingIndicatorOnBlip(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(labelFor(player))
    EndTextCommandSetBlipName(blip)
end

RegisterNetEvent("Admin:blips", function(enabled, players)
    if enabled ~= true then
        active = false
        removeAll()
        return
    end

    active = true
    if type(players) ~= "table" then return end

    local myId = GetPlayerServerId(PlayerId())
    local seen = {}

    for i = 1, #players do
        local player = players[i]
        if type(player) == "table" and player.id and player.id ~= myId and player.x then
            seen[player.id] = true
            local blip = blips[player.id]

            if not blip or not DoesBlipExist(blip) then
                blip = AddBlipForCoord(player.x, player.y, player.z)
                blips[player.id] = blip
            else
                SetBlipCoords(blip, player.x, player.y, player.z)
            end

            applyStyle(blip, player)
        end
    end

    -- Joueurs partis depuis le dernier envoi
    for id, blip in pairs(blips) do
        if not seen[id] then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            blips[id] = nil
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    removeAll()
end)

--- Les blips sont-ils affichés ?
---@return boolean
function StaffMenu_BlipsActive()
    return active
end
