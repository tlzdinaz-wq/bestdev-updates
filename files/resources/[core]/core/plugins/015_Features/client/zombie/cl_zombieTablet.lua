local isDrawerOpen = false
-- Garde séparée pendant l'aller-retour serveur : la carte ne peut s'ouvrir qu'une fois les
-- zones connues (le bundle les attend dans le message d'ouverture, il n'a pas de rafraîchissement),
-- et sans ce drapeau un second clic lançait une deuxième requête.
local isOpening = false

local function FetchZones()
    return TriggerServerCallback("zombie:getZones") or {}
end

local function OpenZombieZoneDrawer()
    if isDrawerOpen or isOpening then return end

    local pg = VFW.PlayerGlobalData
    if not pg or not pg.permissions then return end
    if not pg.permissions["builder_zombie"] then
        VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Zombie", message = "Pas la permission" })
        return
    end

    -- La carte s'ouvre tout de suite avec les zones déjà reçues. Attendre le callback
    -- bloquait l'affichage (jusqu'au délai du callback) et le menu staff reprenait
    -- le focus : la tablette était visible, mais plus rien n'était cliquable.
    local coords = GetEntityCoords(PlayerPedId())
    local zones = (VFW.GetZombieZones and VFW.GetZombieZones()) or {}
    isDrawerOpen = true

    SendNUIMessage({
        action = "nui:zombieZoneDrawer:open",
        data = {
            zones = zones,
            playerCoords = { x = coords.x, y = coords.y },
        }
    })
    VFW.Nui.Focus(true)

    SetTimeout(600, function()
        if isDrawerOpen then VFW.Nui.Focus(true) end
    end)

    if #zones > 0 then return end

    isOpening = true
    CreateThread(function()
        local fresh = FetchZones()
        isOpening = false
        if not isDrawerOpen then return end
        local now = GetEntityCoords(PlayerPedId())
        SendNUIMessage({
            action = "nui:zombieZoneDrawer:open",
            data = {
                zones = fresh,
                playerCoords = { x = now.x, y = now.y },
            }
        })
        VFW.Nui.Focus(true)
    end)
end

local function CloseZombieZoneDrawer()
    if not isDrawerOpen then return end
    isDrawerOpen = false
    SendNUIMessage({ action = "nui:zombieZoneDrawer:close" })
    VFW.Nui.Focus(false)
end

RegisterNUICallback("zombieZoneDrawer:close", function(_, cb)
    CloseZombieZoneDrawer()
    cb({})
end)

RegisterNUICallback("zombieZoneDrawer:refreshData", function(_, cb)
    local zones = FetchZones()
    local coords = GetEntityCoords(PlayerPedId())
    cb({ zones = zones, playerCoords = { x = coords.x, y = coords.y } })
end)

RegisterNUICallback("zombieZoneDrawer:create", function(data, cb)
    if not data or not data.name or not data.points or #data.points < 3 then
        cb({ success = false })
        return
    end

    local result = TriggerServerCallback("zombie:createZone", {
        name = data.name,
        polygon = data.points,
        max_zombies = data.max_zombies or 10,
    })

    if result and result.success then
        local zones = FetchZones()
        local coords = GetEntityCoords(PlayerPedId())
        cb({ success = true, zones = zones, playerCoords = { x = coords.x, y = coords.y } })
    else
        cb({ success = false })
    end
end)

exports("OpenZombieZoneDrawer", function()
    OpenZombieZoneDrawer()
end)
