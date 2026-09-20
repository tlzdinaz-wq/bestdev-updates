local sfind = string.find
local supper = string.upper
local slower = string.lower

local searchText = ""

local weaponsByName = {}
for _, w in ipairs(Config.Weapons) do
    weaponsByName[supper(w.name)] = w
end

local function GetCategory(name)
    if sfind(name, "PISTOL") or sfind(name, "REVOLVER") or sfind(name, "STUNGUN") or sfind(name, "STUNROD") then
        return "PISTOLETS"
  end
    if sfind(name, "SHOTGUN") or sfind(name, "MUSKET") then
        return "SHOTGUNS"
  end
    if sfind(name, "SMG") or name == "WEAPON_COMBATPDW" or name == "WEAPON_MACHINEPISTOL" or name == "WEAPON_MINISMG" or name == "WEAPON_TECPISTOL" then
        return "SMG"
  end
    if sfind(name, "SNIPER") or sfind(name, "MARKSMAN") or sfind(name, "PRECISION") then
        return "SNIPERS"
  end
    if name == "WEAPON_MG" or name == "WEAPON_COMBATMG" or name == "WEAPON_COMBATMG_MK2" or name == "WEAPON_GUSENBERG" then
        return "MITRAILLEUSES"
  end
    if sfind(name, "LAUNCHER") or sfind(name, "MINIGUN") or sfind(name, "RPG") or sfind(name, "RAILGUN") or sfind(name, "FIREWORK") then
        return "LOURDES"
  end
    if sfind(name, "RIFLE") then
        return "FUSILS D'ASSAUT"
  end
    return nil
end

local categoryOrder = {
    "PISTOLETS",
    "SMG",
    "FUSILS D'ASSAUT",
    "SHOTGUNS",
    "SNIPERS",
    "MITRAILLEUSES",
    "LOURDES",
}

local function BuildHostageWeaponsMenu()
    if not StaffMenu or not StaffMenu.builderHostageWeapons then return end

    local allowed = GlobalState.HostageWeaponsAllowed or {}
    local Button = StaffMenu.builderHostageWeapons.Button
    local Separator = StaffMenu.builderHostageWeapons.Separator

    local categorized = {}
    for _, cat in ipairs(categoryOrder) do
        categorized[cat] = {}
    end

    for itemName, item in pairs(VFW.Items) do
        if item.type == "weapons" then
            local upperName = supper(itemName)
            local configWeapon = weaponsByName[upperName]
            local isMelee = configWeapon and configWeapon.melee or false
            local isThrowable = configWeapon and configWeapon.throwable or false

            if not configWeapon then
                isMelee = not GetCategory(upperName)
            end

            if not isMelee and not isThrowable then
                if upperName ~= "WEAPON_FIREEXTINGUISHER" and upperName ~= "WEAPON_PETROLCAN" and upperName ~= "WEAPON_HAZARDCAN" then
                    local cat = GetCategory(upperName) or "AUTRE"
                  if not categorized[cat] then categorized[cat] = {} end
                    table.insert(categorized[cat], { name = upperName, label = item.label })
                end
            end
        end
    end

    for _, cat in ipairs(categoryOrder) do
        table.sort(categorized[cat], function(a, b) return a.label < b.label end)
    end

    local totalAllowed = 0
    for _ in pairs(allowed) do totalAllowed = totalAllowed + 1 end

    Separator("RECHERCHE")

    Button("Rechercher une arme", searchText ~= "" and ("Recherche : " .. searchText) or nil, nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher une arme", searchText)
        if input then
            searchText = input
            StaffMenu.builderHostageWeapons.refresh()
        end
    end)

    if searchText ~= "" then
        Button("Effacer la recherche", nil, nil, "trash", false, function()
            searchText = ""
          StaffMenu.builderHostageWeapons.refresh()
        end)
    end

    Separator("ACTIONS RAPIDES")

    Button("Tout activer", totalAllowed .. (totalAllowed > 1 and " armes autorisées" or " arme autorisée"), nil, "check", false, function()
        local success = TriggerServerCallback("vfw:hostageWeapons:setAll", true)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Prise d\'otage', message = "Toutes les armes activées." })
            Wait(200)
            StaffMenu.builderHostageWeapons.refresh()
        end
    end)

    Button("Tout désactiver", nil, nil, "trash", false, function()
        local success = TriggerServerCallback("vfw:hostageWeapons:setAll", false)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Prise d\'otage', message = "Toutes les armes désactivées." })
            Wait(200)
            StaffMenu.builderHostageWeapons.refresh()
        end
    end)

    local searchLower = searchText ~= "" and slower(searchText) or nil

    for _, cat in ipairs(categoryOrder) do
        local weapons = categorized[cat]
        if #weapons > 0 then
            local filtered = weapons
            if searchLower then
                filtered = {}
                for _, w in ipairs(weapons) do
                    if sfind(slower(w.label), searchLower, 1, true) or sfind(slower(w.name), searchLower, 1, true) then
                        table.insert(filtered, w)
                    end
                end
            end

            if #filtered > 0 then
                Separator(cat)
                for _, w in ipairs(filtered) do
                    local isAllowed = allowed[w.name] == true
                    local icon = isAllowed and "check" or "empty"
                  local desc = isAllowed and "Autorisée pour otage" or "Non autorisée"
                  Button(w.label, desc, nil, icon, false, function()
                        local newState = TriggerServerCallback("vfw:hostageWeapons:toggle", w.name)
                        if newState ~= nil then
                            local stateText = newState and "autorisée" or "retirée"
                          VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Prise d\'otage', message = w.label .. " " .. stateText .. "." })
                            Wait(200)
                            StaffMenu.builderHostageWeapons.refresh()
                        end
                    end)
                end
            end
        end
    end
end

if StaffMenu.builderHostageWeapons and StaffMenu.builderHostageWeapons.OnOpen then
    StaffMenu.builderHostageWeapons.OnOpen(function()
        StaffMenu.builderHostageWeapons.ClearItems()
        BuildHostageWeaponsMenu()
    end)
end
