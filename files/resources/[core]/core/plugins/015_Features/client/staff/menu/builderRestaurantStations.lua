-- ══════════════════════════════════════════════════════════════════
-- Builder — Positions des stations de restaurant (menu F10)
-- ══════════════════════════════════════════════════════════════════
-- Navigation : Restaurant -> Emplacement -> Station -> Point.
-- Permet de déplacer toute une station (en conservant la disposition)
-- ou chaque point/slot individuellement à la position du staff.
-- ══════════════════════════════════════════════════════════════════

local Util = RestaurantStations

local RESTAURANTS = {
    { key = "burgershot",  label = "BurgerShot" },
    { key = "pizzeria",    label = "Pizzeria" },
    { key = "pearls",      label = "Pearls" },
    { key = "noodle",      label = "Noodle" },
    { key = "bean_coffee", label = "Bean Coffee" },
    { key = "uwu_cafe",    label = "UwU Cafe" },
}

-- sélection courante
local sel = { key = nil, loc = nil, station = nil, point = nil }

local function notify(msg, ok)
    VFW.ShowNotification({ type = ok and "VERT" or "ROUGE", content = msg })
end

local function reopen(menu)
    menu.close()
    Wait(120)
    menu.open()
end

local function stationLabel(stKey)
    return Util.StationLabels[stKey] or stKey
end

-- station live sélectionnée
local function getStation()
    local cfg = Util.GetConfig(sel.key)
    if not cfg or not cfg.Locations then return nil end
    local loc = cfg.Locations[sel.loc]
    if type(loc) ~= "table" then return nil end
    local st = loc[sel.station]
    if type(st) ~= "table" then return nil end
    return st
end

-- liste des points éditables d'une station
local function listPoints(st)
    local pts = {}
    if st.center then pts[#pts + 1] = { id = "center", label = "Zone (centre)", hasHeading = false } end
    if st.coords then pts[#pts + 1] = { id = "coords", label = "Zone", hasHeading = true } end
    if st.slots then
        local names = {}
        for n in pairs(st.slots) do names[#names + 1] = n end
        table.sort(names)
        for _, n in ipairs(names) do
            pts[#pts + 1] = { id = "slot:" .. n, label = "Slot " .. n, hasHeading = true }
        end
    end
    return pts
end

-- position + cap d'un point
local function getPoint(st, id)
    if id == "center" then return st.center, nil end
    if id == "coords" then return st.coords, st.heading end
    local name = id:match("^slot:(.+)$")
    if name and st.slots and st.slots[name] then
        return st.slots[name].pos, st.slots[name].heading
    end
    return nil
end

-- snapshot de la station avec UN point modifié
local function snapWithPointChanged(st, id, x, y, z, heading)
    local snap = Util.Snapshot(st)
    if id == "center" then
        snap.center = { x = x, y = y, z = z }
    elseif id == "coords" then
        snap.coords = { x = x, y = y, z = z }
        if heading ~= nil then snap.heading = heading end
    else
        local name = id:match("^slot:(.+)$")
        if name and snap.slots and snap.slots[name] then
            snap.slots[name] = {
                x = x, y = y, z = z,
                heading = heading ~= nil and heading or snap.slots[name].heading,
            }
        end
    end
    return snap
end

-- déplace toute la station vers le joueur (conserve la disposition)
local function moveWholeStation(st)
    local snap = Util.Snapshot(st)
    local ref = snap.center or snap.coords
    if not ref and snap.slots then
        local sx, sy, sz, n = 0, 0, 0, 0
        for _, s in pairs(snap.slots) do
            sx, sy, sz, n = sx + s.x, sy + s.y, sz + s.z, n + 1
        end
        if n > 0 then ref = { x = sx / n, y = sy / n, z = sz / n } end
    end
    if not ref then return nil end

    local p = GetEntityCoords(PlayerPedId())
    local dx, dy, dz = p.x - ref.x, p.y - ref.y, p.z - ref.z

    if snap.center then
        snap.center = { x = snap.center.x + dx, y = snap.center.y + dy, z = snap.center.z + dz }
    end
    if snap.coords then
        snap.coords = { x = snap.coords.x + dx, y = snap.coords.y + dy, z = snap.coords.z + dz }
    end
    if snap.slots then
        for n2, s in pairs(snap.slots) do
            snap.slots[n2] = { x = s.x + dx, y = s.y + dy, z = s.z + dz, heading = s.heading }
        end
    end
    return snap
end

-- envoie une mise à jour + applique localement (feedback immédiat)
local function sendUpdate(snap)
    local ok = TriggerServerCallback("restaurant_stations:update", sel.key, sel.loc, sel.station, snap)
    if ok then
        local st = getStation()
        if st then Util.Apply(st, snap) end
    end
    return ok
end

-- ══════════════════════════════════════════════════════════════════
-- Menus
-- ══════════════════════════════════════════════════════════════════

-- Niveau 1 : restaurants
StaffMenu.builderRestaurantStations.OnOpen(function()
    StaffMenu.builderRestaurantStations.Separator("RESTAURANTS")
    for _, r in ipairs(RESTAURANTS) do
        local cfg = Util.GetConfig(r.key)
        local count = 0
        if cfg and cfg.Locations then
            for _ in pairs(cfg.Locations) do count = count + 1 end
        end
        StaffMenu.builderRestaurantStations.Button(r.label, count .. (count > 1 and " emplacements" or " emplacement"), nil, "chevron", false, function()
            sel.key = r.key
        end, StaffMenu.builderRestaurantStationsLoc)
    end
end)

-- Niveau 2 : emplacements
StaffMenu.builderRestaurantStationsLoc.OnOpen(function()
    local cfg = Util.GetConfig(sel.key)
    if not cfg or not cfg.Locations then return end

    StaffMenu.builderRestaurantStationsLoc.Separator("EMPLACEMENTS")

    local keys = {}
    for k in pairs(cfg.Locations) do keys[#keys + 1] = k end
    table.sort(keys)

    for _, locKey in ipairs(keys) do
        local loc = cfg.Locations[locKey]
        local label = (type(loc) == "table" and loc.label) or locKey
        local n = 0
        Util.ForEachStation({ Locations = { [locKey] = loc } }, function() n = n + 1 end)
        StaffMenu.builderRestaurantStationsLoc.Button(label, n .. (n > 1 and " stations" or " station"), nil, "chevron", false, function()
            sel.loc = locKey
        end, StaffMenu.builderRestaurantStationsList)
    end
end)

-- Niveau 3 : stations d'un emplacement
StaffMenu.builderRestaurantStationsList.OnOpen(function()
    local cfg = Util.GetConfig(sel.key)
    if not cfg or not cfg.Locations then return end
    local loc = cfg.Locations[sel.loc]
    if type(loc) ~= "table" then return end

    StaffMenu.builderRestaurantStationsList.Separator(string.upper(loc.label or sel.loc))

    StaffMenu.builderRestaurantStationsList.Button(
        "+ Ajouter une station",
        "Créer une nouvelle station à cet emplacement",
        nil, "chevron", false,
        function() end,
        StaffMenu.builderRestaurantStationsCreate
    )

    StaffMenu.builderRestaurantStationsList.Separator("STATIONS EXISTANTES")

    local stKeys = {}
    for stKey, st in pairs(loc) do
        if type(st) == "table" and (st.center or st.coords or st.slots) then
            stKeys[#stKeys + 1] = stKey
        end
    end
    table.sort(stKeys)

    for _, stKey in ipairs(stKeys) do
        local st = loc[stKey]
        local ref = st.center or st.coords
        local sub = ref and string.format("%.1f, %.1f, %.1f", ref.x, ref.y, ref.z) or "slots"
        StaffMenu.builderRestaurantStationsList.Button(stationLabel(stKey), sub, nil, "chevron", false, function()
            sel.station = stKey
        end, StaffMenu.builderRestaurantStationsDetail)
    end
end)

-- Niveau 3 bis : créer une station
StaffMenu.builderRestaurantStationsCreate.OnOpen(function()
    StaffMenu.builderRestaurantStationsCreate.Separator("TYPES DISPONIBLES")

    local types = TriggerServerCallback("restaurant_stations:getCreatable", sel.key, sel.loc) or {}
    if #types == 0 then
        StaffMenu.builderRestaurantStationsCreate.Button(
            "Aucun type disponible",
            "Toutes les stations supportées existent déjà ici",
            nil, nil, true, function() end
        )
        return
    end

    for _, stKey in ipairs(types) do
        StaffMenu.builderRestaurantStationsCreate.Button(
            stationLabel(stKey),
            "Créer à ma position actuelle",
            nil, nil, false,
            function()
                local ped = PlayerPedId()
                local p = GetEntityCoords(ped)
                local h = GetEntityHeading(ped)
                local ok = TriggerServerCallback("restaurant_stations:create", sel.key, sel.loc, stKey, p.x, p.y, p.z, h)
                notify(ok and "Station créée." or "Échec de la création.", ok and true or false)
                reopen(StaffMenu.builderRestaurantStationsCreate)
            end
        )
    end
end)

-- Niveau 4 : actions sur une station
StaffMenu.builderRestaurantStationsDetail.OnOpen(function()
    local st = getStation()
    if not st then return end

    StaffMenu.builderRestaurantStationsDetail.Separator(stationLabel(sel.station))

    StaffMenu.builderRestaurantStationsDetail.Button(
        "Déplacer toute la station à ma position",
        "Conserve la disposition (slots déplacés ensemble)",
        nil, nil, false,
        function()
            local st2 = getStation()
            if not st2 then return end
            local snap = moveWholeStation(st2)
            if not snap then notify("Station sans point de référence.", false) return end
            local ok = sendUpdate(snap)
            notify(ok and "Station déplacée." or "Échec du déplacement.", ok and true or false)
            reopen(StaffMenu.builderRestaurantStationsDetail)
        end
    )

    StaffMenu.builderRestaurantStationsDetail.Separator("POINTS ET SLOTS")
    StaffMenu.builderRestaurantStationsDetail.Button(
        "+ Ajouter un slot",
        "Crée un point d'interaction à ma position",
        nil, nil, false,
        function()
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)
            local ok = TriggerServerCallback("restaurant_stations:addSlot", sel.key, sel.loc, sel.station, p.x, p.y, p.z, h)
            notify(ok and "Slot ajouté." or "Échec de l'ajout.", ok and true or false)
            reopen(StaffMenu.builderRestaurantStationsDetail)
        end
    )
    for _, pt in ipairs(listPoints(st)) do
        local pos, heading = getPoint(st, pt.id)
        local sub = pos and string.format("%.1f, %.1f, %.1f", pos.x, pos.y, pos.z) or "?"
        if pt.hasHeading and heading then sub = sub .. string.format("  |  cap %.0f°", heading) end
        StaffMenu.builderRestaurantStationsDetail.Button(pt.label, sub, nil, "chevron", false, function()
            sel.point = pt.id
        end, StaffMenu.builderRestaurantStationsPoint)
    end

    StaffMenu.builderRestaurantStationsDetail.Separator("ACTIONS")
    StaffMenu.builderRestaurantStationsDetail.Button(
        "Réinitialiser cette station",
        "Revenir à l'état d'origine du jeu",
        nil, nil, false,
        function()
            local ok = TriggerServerCallback("restaurant_stations:reset", sel.key, sel.loc, sel.station)
            notify(ok and "Station réinitialisée." or "Échec de la réinitialisation.", ok and true or false)
            reopen(StaffMenu.builderRestaurantStationsDetail)
        end
    )
    StaffMenu.builderRestaurantStationsDetail.Button(
        "Supprimer cette station",
        "Retire la station de cet emplacement",
        nil, "trash", false,
        function()
            local ok = TriggerServerCallback("restaurant_stations:delete", sel.key, sel.loc, sel.station)
            notify(ok and "Station supprimée." or "Échec de la suppression.", ok and true or false)
            StaffMenu.builderRestaurantStationsDetail.close()
            Wait(120)
            StaffMenu.builderRestaurantStationsList.open()
        end
    )
end)

-- Niveau 5 : édition d'un point / slot
StaffMenu.builderRestaurantStationsPoint.OnOpen(function()
    local st = getStation()
    if not st or not sel.point then return end

    local pos, heading = getPoint(st, sel.point)
    local hasHeading = (sel.point ~= "center")

    StaffMenu.builderRestaurantStationsPoint.Separator("POINT")
    StaffMenu.builderRestaurantStationsPoint.Button(
        pos and string.format("Position : %.2f, %.2f, %.2f", pos.x, pos.y, pos.z) or "Position : ?",
        (hasHeading and heading) and string.format("Cap actuel : %.0f°", heading) or "",
        nil, nil, true, function() end
    )

    StaffMenu.builderRestaurantStationsPoint.Button(
        "Définir à ma position",
        "Place ce point là où vous vous tenez",
        nil, nil, false,
        function()
            local st2 = getStation()
            if not st2 then return end
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            local h = hasHeading and GetEntityHeading(ped) or nil
            local snap = snapWithPointChanged(st2, sel.point, p.x, p.y, p.z, h)
            local ok = sendUpdate(snap)
            notify(ok and "Point déplacé." or "Échec.", ok and true or false)
            reopen(StaffMenu.builderRestaurantStationsPoint)
        end
    )

    if hasHeading then
        StaffMenu.builderRestaurantStationsPoint.Button(
            "Orientation = la mienne",
            "Aligne le cap sur votre orientation actuelle",
            nil, nil, false,
            function()
                local st2 = getStation()
                if not st2 then return end
                local p2 = getPoint(st2, sel.point)
                if not p2 then return end
                local h = GetEntityHeading(PlayerPedId())
                local snap = snapWithPointChanged(st2, sel.point, p2.x, p2.y, p2.z, h)
                local ok = sendUpdate(snap)
                notify(ok and "Orientation mise à jour." or "Échec.", ok and true or false)
                reopen(StaffMenu.builderRestaurantStationsPoint)
            end
        )
    end

    -- suppression d'un slot (uniquement pour les slots, pas center/coords)
    if sel.point:match("^slot:") then
        StaffMenu.builderRestaurantStationsPoint.Separator("ACTIONS")
        StaffMenu.builderRestaurantStationsPoint.Button(
            "Supprimer ce slot",
            "Retire ce point d'interaction",
            nil, "trash", false,
            function()
                local name = sel.point:match("^slot:(.+)$")
                local ok = TriggerServerCallback("restaurant_stations:removeSlot", sel.key, sel.loc, sel.station, name)
                notify(ok and "Slot supprimé." or "Échec de la suppression.", ok and true or false)
                StaffMenu.builderRestaurantStationsPoint.close()
                Wait(120)
                StaffMenu.builderRestaurantStationsDetail.open()
            end
        )
    end
end)
