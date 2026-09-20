local sfind = string.find
local supper = string.upper
local slower = string.lower

local searchText = ""
local selectedWeapon = nil

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

local function GetWeaponDesc(name, config)
    if not config then
        return "Défaut GTA"
  end

    if config.isMelee then
        local parts = {}
        if config.oneshot then
            table.insert(parts, "One-shot KO")
        elseif config.hitsToKO > 0 then
            table.insert(parts, config.hitsToKO .. (config.hitsToKO > 1 and " coups KO" or " coup KO"))
        end
        if config.canKill then
            table.insert(parts, "peut tuer")
        else
            table.insert(parts, "KO uniquement")
        end
        if #parts == 0 then return "Défaut GTA" end
        return table.concat(parts, ", ")
    else
        local parts = {}
        if config.bulletsToKill > 0 then
            table.insert(parts, config.bulletsToKill .. (config.bulletsToKill > 1 and " balles" or " balle"))
            if config.bulletsToKillArmor and config.bulletsToKillArmor > 0 then
                table.insert(parts, config.bulletsToKillArmor .. " avec armure")
            end
            table.insert(parts, "x" .. config.headshotMultiplier .. " headshot")
        end
        if #parts == 0 then return "Défaut GTA" end
        return table.concat(parts, ", ")
    end
end

local function HasConfig(config)
    if not config then return false end
    if config.isMelee then
        return config.hitsToKO > 0 or config.oneshot or config.canKill
    else
        return config.bulletsToKill > 0
    end
end

local function BuildWeaponDamageDetailMenu()
    if not selectedWeapon or not StaffMenu.builderWeaponDamageDetail then return end

    local w = selectedWeapon
    local damageConfig = GlobalState.WeaponDamageConfig or {}
    local config = damageConfig[w.name]
    local Button = StaffMenu.builderWeaponDamageDetail.Button
    local Separator = StaffMenu.builderWeaponDamageDetail.Separator

    Separator(w.label)

    if w.isMelee then
        local currentHits = config and config.hitsToKO or 0
        local currentCanKill = config and config.canKill or false
        local currentOneshot = config and config.oneshot or false

        Button(
            "Coups pour KO",
            currentHits > 0 and (currentHits .. (currentHits > 1 and " coups" or " coup")) or "Défaut GTA",
            nil, nil, false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nombre de coups (1-20, 0 = défaut)")
                if not input then return end
                local val = tonumber(input)
                if not val or val < 0 or val > 20 then
                    VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide (0-20)" })
                    return
                end
                local success = TriggerServerCallback("vfw:weaponDamage:update", w.name, "hitsToKO", math.floor(val))
                if success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " : " .. val .. (val > 1 and " coups pour KO" or " coup pour KO") })
                    Wait(200)
                    StaffMenu.builderWeaponDamageDetail.refresh()
                end
            end
        )

        Button(
            "Peut tuer",
            currentCanKill and "Oui - l'arme peut tuer" or "Non - KO uniquement",
            nil, currentCanKill and "check" or "empty", false,
            function()
                local success = TriggerServerCallback("vfw:weaponDamage:update", w.name, "canKill", not currentCanKill)
                if success then
                    local stateText = not currentCanKill and "peut tuer" or "KO uniquement"
                  VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " : " .. stateText })
                    Wait(200)
                    StaffMenu.builderWeaponDamageDetail.refresh()
                end
            end
        )

        Button(
            "One-shot KO",
            currentOneshot and "Activé - KO en un coup" or "Désactivé",
            nil, currentOneshot and "check" or "empty", false,
            function()
                local success = TriggerServerCallback("vfw:weaponDamage:update", w.name, "oneshot", not currentOneshot)
                if success then
                    local stateText = not currentOneshot and "activé" or "désactivé"
                  VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " : one-shot " .. stateText })
                    Wait(200)
                    StaffMenu.builderWeaponDamageDetail.refresh()
                end
            end
        )
    else
        local currentBullets = config and config.bulletsToKill or 0
        local currentBulletsArmor = config and config.bulletsToKillArmor or 0
        local currentMultiplier = config and config.headshotMultiplier or 2.0

        Button(
            "Balles pour tuer",
            currentBullets > 0 and (currentBullets .. (currentBullets > 1 and " balles" or " balle")) or "Défaut GTA",
            nil, nil, false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nombre de balles (1-30, 0 = défaut)")
                if not input then return end
                local val = tonumber(input)
                if not val or val < 0 or val > 30 then
                    VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide (0-30)" })
                    return
                end
                local success = TriggerServerCallback("vfw:weaponDamage:update", w.name, "bulletsToKill", math.floor(val))
                if success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " : " .. val .. (val > 1 and " balles pour tuer" or " balle pour tuer") })
                    Wait(200)
                    StaffMenu.builderWeaponDamageDetail.refresh()
                end
            end
        )

        Button(
            "Balles pour tuer (avec armure)",
            currentBulletsArmor > 0 and (currentBulletsArmor .. (currentBulletsArmor > 1 and " balles" or " balle")) or "Non configuré",
            nil, nil, false,
            function()
                local input = VFW.Nui.KeyboardInput(true, "Nombre de balles avec armure (1-50, 0 = désactiver)")
                if not input then return end
                local val = tonumber(input)
                if not val or val < 0 or val > 50 then
                    VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide (0-50)" })
                    return
                end
                local success = TriggerServerCallback("vfw:weaponDamage:update", w.name, "bulletsToKillArmor", math.floor(val))
                if success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " : " .. val .. (val > 1 and " balles avec armure" or " balle avec armure") })
                    Wait(200)
                    StaffMenu.builderWeaponDamageDetail.refresh()
                end
            end
        )

        local multiplierOptions = {}
        for i = 10, 50, 5 do
            table.insert(multiplierOptions, { label = "x" .. (i / 10), value = tostring(i / 10) })
        end

        Button(
            "Multiplicateur headshot",
            "x" .. currentMultiplier,
            nil, nil, false,
            function()
                local result = VFW.Nui.ChoiceInput("Multiplicateur headshot", "Dégâts multipliés lors d'un tir à la tête", multiplierOptions)
                if not result then return end
                local val = tonumber(result)
                if not val then return end
                local success = TriggerServerCallback("vfw:weaponDamage:update", w.name, "headshotMultiplier", val)
                if success then
                    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " : x" .. val .. " headshot" })
                    Wait(200)
                    StaffMenu.builderWeaponDamageDetail.refresh()
                end
            end
        )
    end

    Separator("ACTIONS")

    Button("Réinitialiser", "Revenir aux dégâts GTA par défaut", nil, "trash", false, function()
        local success = TriggerServerCallback("vfw:weaponDamage:reset", w.name)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = w.label .. " réinitialisé" })
            Wait(200)
            StaffMenu.builderWeaponDamageDetail.refresh()
        end
    end)
end

local function BuildWeaponDamageMenu()
    if not StaffMenu or not StaffMenu.builderWeaponDamage then return end

    local damageConfig = GlobalState.WeaponDamageConfig or {}
    local Button = StaffMenu.builderWeaponDamage.Button
    local Separator = StaffMenu.builderWeaponDamage.Separator

    local firearmCategories = {}
    for _, cat in ipairs(categoryOrder) do
        firearmCategories[cat] = {}
    end
    local meleeWeapons = {}

    for itemName, item in pairs(VFW.Items) do
        if item.type == "weapons" then
            local upperName = supper(itemName)
            local configWeapon = weaponsByName[upperName]
            local isMelee = configWeapon and configWeapon.melee or false
            local isThrowable = configWeapon and configWeapon.throwable or false

            if not configWeapon then
                isMelee = not GetCategory(upperName)
            end

            if isThrowable then
            elseif isMelee then
                table.insert(meleeWeapons, { name = upperName, label = item.label, isMelee = true })
            else
                if upperName ~= "WEAPON_FIREEXTINGUISHER" and upperName ~= "WEAPON_PETROLCAN" and upperName ~= "WEAPON_HAZARDCAN" then
                    local cat = GetCategory(upperName) or "AUTRE"
                  if not firearmCategories[cat] then firearmCategories[cat] = {} end
                    table.insert(firearmCategories[cat], { name = upperName, label = item.label, isMelee = false })
                end
            end
        end
    end

    for _, cat in ipairs(categoryOrder) do
        table.sort(firearmCategories[cat], function(a, b) return a.label < b.label end)
    end
    table.sort(meleeWeapons, function(a, b) return a.label < b.label end)

    local totalConfigured = 0
    for _ in pairs(damageConfig) do totalConfigured = totalConfigured + 1 end

    Separator("RECHERCHE")

    Button("Rechercher une arme", searchText ~= "" and ("Recherche : " .. searchText) or nil, nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher une arme", searchText)
        if input then
            searchText = input
            StaffMenu.builderWeaponDamage.refresh()
        end
    end)

    if searchText ~= "" then
        Button("Effacer la recherche", nil, nil, "trash", false, function()
            searchText = ""
          StaffMenu.builderWeaponDamage.refresh()
        end)
    end

    Separator("ACTIONS RAPIDES")

    Button("Tout réinitialiser", totalConfigured .. (totalConfigured > 1 and " armes configurées" or " arme configurée"), nil, "trash", false, function()
        local success = TriggerServerCallback("vfw:weaponDamage:resetAll")
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Dégâts', message = "Toutes les configurations supprimées" })
            Wait(200)
            StaffMenu.builderWeaponDamage.refresh()
        end
    end)

    local searchLower = searchText ~= "" and slower(searchText) or nil

    for _, cat in ipairs(categoryOrder) do
        local weapons = firearmCategories[cat]
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
                    local config = damageConfig[w.name]
                    local hasConf = HasConfig(config)
                    local icon = hasConf and "check" or "empty"
                  local desc = GetWeaponDesc(w.name, config)
                    Button(w.label, desc, nil, icon, false, function()
                        selectedWeapon = w
                        if StaffMenu.builderWeaponDamageDetail.SetTitle then
                            StaffMenu.builderWeaponDamageDetail.SetTitle(supper(w.label))
                        end
                    end, StaffMenu.builderWeaponDamageDetail)
                end
            end
        end
    end

    if #meleeWeapons > 0 then
        local filtered = meleeWeapons
        if searchLower then
            filtered = {}
            for _, w in ipairs(meleeWeapons) do
                if sfind(slower(w.label), searchLower, 1, true) or sfind(slower(w.name), searchLower, 1, true) then
                    table.insert(filtered, w)
                end
            end
        end

        if #filtered > 0 then
            Separator("MELEE")
            for _, w in ipairs(filtered) do
                local config = damageConfig[w.name]
                local hasConf = HasConfig(config)
                local icon = hasConf and "check" or "empty"
              local desc = GetWeaponDesc(w.name, config)
                Button(w.label, desc, nil, icon, false, function()
                    selectedWeapon = w
                    if StaffMenu.builderWeaponDamageDetail.SetTitle then
                        StaffMenu.builderWeaponDamageDetail.SetTitle(supper(w.label))
                    end
                end, StaffMenu.builderWeaponDamageDetail)
            end
        end
    end
end

if StaffMenu.builderWeaponDamage and StaffMenu.builderWeaponDamage.OnOpen then
    StaffMenu.builderWeaponDamage.OnOpen(function()
        StaffMenu.builderWeaponDamage.ClearItems()
        BuildWeaponDamageMenu()
    end)
end

if StaffMenu.builderWeaponDamageDetail and StaffMenu.builderWeaponDamageDetail.OnOpen then
    StaffMenu.builderWeaponDamageDetail.OnOpen(function()
        StaffMenu.builderWeaponDamageDetail.ClearItems()
        BuildWeaponDamageDetailMenu()
    end)
end
