-- Builder « Positions prison ».
--
-- Les quatre points de la prison étaient écrits en dur dans le code du métier
-- police : un serveur avec sa propre prison n'avait aucun moyen de les
-- déplacer. Ce menu les prend là où le staff se tient, et le serveur les garde
-- (voir server/misc_b/34_17_prison.lua).
--
-- Chaque position se règle en allant se placer à l'endroit voulu : c'est plus
-- sûr que de taper des coordonnées, et l'orientation du personnage sert de cap.

local positions = nil

local POINTS <const> = {
    {
        key = "cell",
        label = "CELLULE",
        desc = "Ou arrive un joueur incarcere",
    },
    {
        key = "release",
        label = "POINT DE LIBERATION",
        desc = "Ou est depose un joueur qui sort de prison",
    },
    {
        key = "guard",
        label = "GARDIEN DE SORTIE",
        desc = "Le PNJ qui rend ses affaires au sortant",
    },
}

local function fetch()
    positions = TriggerServerCallback("prison:getPositions") or {}
    return positions
end

local function coordText(point)
    if type(point) ~= "table" or not point.x then return "Non definie" end
    return ("%.1f, %.1f, %.1f"):format(point.x, point.y, point.z)
end

--- La position du staff, cap compris.
---@return table
local function here()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = GetEntityHeading(ped),
    }
end

local function save(changed)
    local result = TriggerServerCallback("prison:savePositions", changed)
    if type(result) == "table" and result.ok then
        positions = result.positions or positions
        VFW.ShowNotification({
            type = "STAFF", variant = "SUCCESS", subtitle = "Prison",
            message = "Position enregistree.",
        })
        return true
    end

    VFW.ShowNotification({
        type = "STAFF", variant = "ERROR", subtitle = "Prison",
        message = (type(result) == "table" and result.error) or "Enregistrement impossible.",
    })
    return false
end

--- .BuildPrisonPositionsMenu
function StaffMenu.BuildPrisonPositionsMenu()
    local menu = StaffMenu.builderPrison
    local current = positions or fetch()

    menu.Separator("POSITIONS DE LA PRISON")

    for i = 1, #POINTS do
        local entry = POINTS[i]
        local point = current[entry.key]

        menu.Button(entry.label, entry.desc, coordText(point), "chevron", false, function()
            local copy = {}
            for key, value in pairs(current) do copy[key] = value end
            copy[entry.key] = here()

            if save(copy) then
                current = positions
                menu.refresh()
            end
        end)
    end

    menu.Separator("ZONE DE DETENTION")

    local zone = current.zone or {}
    menu.Button("CENTRE DE LA ZONE", "Au-dela du rayon, le prisonnier est considere en evasion",
        coordText(zone), "chevron", false, function()
        local copy = {}
        for key, value in pairs(current) do copy[key] = value end
        local point = here()
        copy.zone = { x = point.x, y = point.y, z = point.z, radius = zone.radius or 500.0 }

        if save(copy) then
            current = positions
            menu.refresh()
        end
    end)

    menu.Button("RAYON DE LA ZONE", "En metres, entre 20 et 2000",
        ("%.0f m"):format(zone.radius or 500.0), "chevron", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rayon de la zone en metres", tostring(math.floor(zone.radius or 500)))
        local radius = tonumber(input)
        if not radius then return end

        local copy = {}
        for key, value in pairs(current) do copy[key] = value end
        copy.zone = { x = zone.x, y = zone.y, z = zone.z, radius = radius }

        if save(copy) then
            current = positions
            menu.refresh()
        end
    end)

    menu.Separator("VERIFIER")

    menu.Button("ALLER A LA CELLULE", "Se teleporter sur la position enregistree", nil, "chevron", false, function()
        local point = current.cell
        if type(point) ~= "table" or not point.x then return end
        local ped = PlayerPedId()
        SetEntityCoords(ped, point.x + 0.0, point.y + 0.0, point.z + 0.0, false, false, false, false)
        if point.h then SetEntityHeading(ped, point.h + 0.0) end
    end)

    menu.Button("REMETTRE LES POSITIONS D'ORIGINE", "Celles livrees avec la base (prison de Bolingbroke)",
        nil, "trash", false, function()
        local result = TriggerServerCallback("prison:resetPositions")
        if type(result) == "table" and result.ok then
            positions = result.positions
            current = positions
            VFW.ShowNotification({
                type = "STAFF", variant = "SUCCESS", subtitle = "Prison",
                message = "Positions d'origine retablies.",
            })
            menu.refresh()
        else
            VFW.ShowNotification({
                type = "STAFF", variant = "ERROR", subtitle = "Prison",
                message = (type(result) == "table" and result.error) or "Action impossible.",
            })
        end
    end)
end

StaffMenu.builderPrison.OnOpen(function()
    fetch()
    StaffMenu.BuildPrisonPositionsMenu()
end)
