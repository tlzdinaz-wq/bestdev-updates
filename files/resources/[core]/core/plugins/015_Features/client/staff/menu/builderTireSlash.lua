local sfind = string.find
local supper = string.upper
local slower = string.lower

local searchText = ""

local weaponsByName = {}
for _, w in ipairs(Config.Weapons) do
    weaponsByName[supper(w.name)] = w
end

local function GetCategory(name)
    if sfind(name, "PISTOL") or sfind(name, "REVOLVER") or sfind(name, "STUNGUN") or sfind(name, "STUNROD") then return "PISTOLETS" end
    if sfind(name, "SHOTGUN") or sfind(name, "MUSKET") then return "SHOTGUNS" end
    if sfind(name, "SMG") or name == "WEAPON_COMBATPDW" or name == "WEAPON_MACHINEPISTOL" or name == "WEAPON_MINISMG" or name == "WEAPON_TECPISTOL" then return "SMG" end
    if sfind(name, "SNIPER") or sfind(name, "MARKSMAN") or sfind(name, "PRECISION") then return "SNIPERS" end
    if name == "WEAPON_MG" or name == "WEAPON_COMBATMG" or name == "WEAPON_COMBATMG_MK2" or name == "WEAPON_GUSENBERG" then return "MITRAILLEUSES" end
    if sfind(name, "LAUNCHER") or sfind(name, "MINIGUN") or sfind(name, "RPG") or sfind(name, "RAILGUN") or sfind(name, "FIREWORK") then return "LOURDES" end
    if sfind(name, "RIFLE") then return "FUSILS D'ASSAUT" end
    return nil
end

local function BuildTireSlashMenu()
    if not StaffMenu or not StaffMenu.builderTireSlash then return end

    local allowed = GlobalState.TireSlashAllowed or {}
    local Button = StaffMenu.builderTireSlash.Button
    local Separator = StaffMenu.builderTireSlash.Separator

    local weapons = {}
    for itemName, item in pairs(VFW.Items) do
        if item.type == "weapons" then
            local upperName = supper(itemName)
            local configWeapon = weaponsByName[upperName]
            local isMelee = configWeapon and configWeapon.melee or false

            if not configWeapon then
                isMelee = not GetCategory(upperName)
            end

            if isMelee then
                table.insert(weapons, { name = upperName, label = item.label })
            end
        end
    end
    table.sort(weapons, function(a, b) return a.label < b.label end)

    local totalAllowed = 0
    for _ in pairs(allowed) do totalAllowed = totalAllowed + 1 end

    Separator("RECHERCHE")

    Button("Rechercher une arme", searchText ~= "" and ("Recherche : " .. searchText) or nil, nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher une arme", searchText)
        if input then
            searchText = input
            StaffMenu.builderTireSlash.refresh()
        end
    end)

    if searchText ~= "" then
        Button("Effacer la recherche", nil, nil, "trash", false, function()
            searchText = ""
          StaffMenu.builderTireSlash.refresh()
        end)
    end

    Separator("ACTIONS RAPIDES")

    Button("Tout activer", totalAllowed .. (totalAllowed > 1 and " armes autorisées" or " arme autorisée"), nil, "check", false, function()
        local success = TriggerServerCallback("vfw:tireSlash:setAll", true)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Crever pneus', message = "Toutes les armes activées." })
            Wait(200)
            StaffMenu.builderTireSlash.refresh()
        end
    end)

    Button("Tout désactiver", nil, nil, "trash", false, function()
        local success = TriggerServerCallback("vfw:tireSlash:setAll", false)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Crever pneus', message = "Toutes les armes désactivées." })
            Wait(200)
            StaffMenu.builderTireSlash.refresh()
        end
    end)

    local searchLower = searchText ~= "" and slower(searchText) or nil

    Separator("ARMES")

    for _, w in ipairs(weapons) do
        local show = true
        if searchLower then
            show = sfind(slower(w.label), searchLower, 1, true) or sfind(slower(w.name), searchLower, 1, true)
        end

        if show then
            local isAllowed = allowed[w.name] == true
            local icon = isAllowed and "check" or "empty"
          local desc = isAllowed and "Peut crever les pneus" or "Ne peut pas crever les pneus"
          Button(w.label, desc, nil, icon, false, function()
                local newState = TriggerServerCallback("vfw:tireSlash:toggle", w.name)
                if newState ~= nil then
                    local stateText = newState and "activée" or "désactivée"
                  VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Crever pneus', message = w.label .. " " .. stateText .. "." })
                    Wait(200)
                    StaffMenu.builderTireSlash.refresh()
                end
            end)
        end
    end
end

if StaffMenu.builderTireSlash and StaffMenu.builderTireSlash.OnOpen then
    StaffMenu.builderTireSlash.OnOpen(function()
        StaffMenu.builderTireSlash.ClearItems()
        BuildTireSlashMenu()
    end)
end
