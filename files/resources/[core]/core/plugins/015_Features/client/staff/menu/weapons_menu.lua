---@meta _
---@diagnostic disable: duplicate-doc-field

local sfind = string.find
local supper = string.upper
local slower = string.lower

local weaponsByName = {}
for _, w in ipairs(Config.Weapons) do
    weaponsByName[supper(w.name)] = w
end

local function GetCategory(name)
    if sfind(name, "PISTOL") or sfind(name, "REVOLVER") or sfind(name, "STUNGUN") or sfind(name, "STUNROD") then return "Pistolets" end
    if sfind(name, "SHOTGUN") or sfind(name, "MUSKET") then return "Fusils a pompe" end
    if sfind(name, "SMG") or name == "WEAPON_COMBATPDW" or name == "WEAPON_MACHINEPISTOL" or name == "WEAPON_MINISMG" or name == "WEAPON_TECPISTOL" then return "Mitraillettes" end
    if sfind(name, "SNIPER") or sfind(name, "MARKSMAN") or sfind(name, "PRECISION") then return "Fusils de sniper" end
    if name == "WEAPON_MG" or name == "WEAPON_COMBATMG" or name == "WEAPON_COMBATMG_MK2" or name == "WEAPON_GUSENBERG" then return "Mitrailleuses" end
    if sfind(name, "LAUNCHER") or sfind(name, "MINIGUN") or sfind(name, "RPG") or sfind(name, "RAILGUN") or sfind(name, "FIREWORK") then return "Armes lourdes" end
    if sfind(name, "RIFLE") then return "Fusils d'assaut" end
    return nil
end

local categoryOrder = {
    "Pistolets",
    "Mitraillettes",
    "Fusils d'assaut",
    "Fusils a pompe",
    "Fusils de sniper",
    "Mitrailleuses",
    "Armes lourdes",
    "Melee",
    "Explosifs",
    "Autre",
}

local function BuildWeaponCategories()
    local categories = {}
    for _, cat in ipairs(categoryOrder) do
        categories[cat] = {}
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

            local cat
            if isThrowable then
                cat = "Explosifs"
          elseif isMelee then
                cat = "Melee"
          else
                cat = GetCategory(upperName) or "Autre"
          end

            if not categories[cat] then categories[cat] = {} end
            table.insert(categories[cat], { name = item.label, model = upperName })
        end
    end

    for _, cat in ipairs(categoryOrder) do
        if categories[cat] then
            table.sort(categories[cat], function(a, b) return a.name < b.name end)
        end
    end

    return categories
end

local weaponData = {
    selectedCategory = nil,
    giveToSelf = true,
    targetPlayer = nil,
    infiniteAmmo = false,
    maxAmmo = false
}

local function GetWeaponTarget()
    if weaponData.giveToSelf then
        return GetPlayerServerId(PlayerId()), true
    end

    return tonumber(weaponData.targetPlayer), false
end

function StaffMenu.BuildWeaponsMenu()
    local categories = BuildWeaponCategories()

    StaffMenu.weapons.Separator("DONNER DES ARMES")

    StaffMenu.weapons.Checkbox("SE DONNER A SOI-MEME", "Donner l'arme a vous-meme (desactiver pour viser un autre joueur par ID)", false, weaponData.giveToSelf, function(_checked)
        weaponData.giveToSelf = _checked

        if not _checked then
            local playerId = VFW.Nui.KeyboardInput(true, "ID du joueur cible", "")
            weaponData.targetPlayer = tonumber(playerId)

            if not weaponData.targetPlayer then
                weaponData.giveToSelf = true
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Armes',
                    message = "Cet identifiant n'est pas valide, mode soi-meme active"
              })
            end
        end
    end)

    StaffMenu.weapons.Checkbox("MUNITIONS INFINIES", "Ne jamais manquer de munitions pour les armes donnees", false, weaponData.infiniteAmmo, function(_checked)
        weaponData.infiniteAmmo = _checked
        if _checked then
            weaponData.maxAmmo = false
        end
    end)

    StaffMenu.weapons.Checkbox("MUNITIONS MAX", "Donner 999 munitions a chaque arme donnee (désactive les munitions infinies)", false, weaponData.maxAmmo, function(_checked)
        weaponData.maxAmmo = _checked
        if _checked then
            weaponData.infiniteAmmo = false
        end
    end)

    StaffMenu.weapons.Separator("CATEGORIES D'ARMES")

    for _, catName in ipairs(categoryOrder) do
        local weapons = categories[catName]
        if weapons and #weapons > 0 then
            StaffMenu.weapons.Button(catName, string.format("%d armes", #weapons), nil, "chevron", false, function()
                weaponData.selectedCategory = catName
            end, StaffMenu.weaponsList)
        end
    end

    StaffMenu.weapons.Separator("ACTIONS RAPIDES")

    StaffMenu.weapons.Button("DONNER TOUTES LES ARMES", "Donner toutes les armes de toutes les categories au joueur selectionne", nil, "check", false, function()
        local target = GetWeaponTarget()

        if target then
            for _, catName in ipairs(categoryOrder) do
                local weapons = categories[catName]
                if weapons then
                    for _, weapon in ipairs(weapons) do
                        StaffMenu.GiveWeapon(target, weapon.model)
                    end
                end
            end

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Armes',
                message = "Toutes les armes donnees"
          })
        end
    end)

    StaffMenu.weapons.Button("RETIRER TOUTES LES ARMES", "Retirer immediatement toutes les armes du joueur selectionne", nil, "trash", false, function()
        local target = GetWeaponTarget()

        if target then
            if weaponData.giveToSelf then
                RemoveAllPedWeapons(PlayerPedId(), true)
            else
                TriggerServerEvent("vfw:staff:removeAllWeapons", target)
            end

            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Gestion Armes',
                message = "Toutes les armes retirees"
          })
        end
    end)
end

function StaffMenu.BuildWeaponsListMenu()
    if not weaponData.selectedCategory then return end

    local categories = BuildWeaponCategories()
    local weapons = categories[weaponData.selectedCategory]

    if not weapons then return end

    StaffMenu.weaponsList.Separator(supper(weaponData.selectedCategory))

    for _, weapon in ipairs(weapons) do
        StaffMenu.weaponsList.Button(weapon.name, weapon.model, nil, "chevron", false, function()
            local target = GetWeaponTarget()

            if target then
                StaffMenu.GiveWeapon(target, weapon.model)

                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Armes',
                    message = "Arme donnee: " .. weapon.name
                })
            end
        end)
    end
end

function StaffMenu.GiveWeapon(target, weaponModel)
    local weaponHash = GetHashKey(weaponModel)
    local selfServerId = GetPlayerServerId(PlayerId())

    if tonumber(target) == selfServerId then
        local playerPed = PlayerPedId()
        GiveWeaponToPed(playerPed, weaponHash, weaponData.maxAmmo and 999 or 250, false, false)

        if weaponData.infiniteAmmo then
            SetPedInfiniteAmmo(playerPed, true, weaponHash)
        end
    else
        TriggerServerEvent("vfw:staff:giveWeapon", target, weaponModel, weaponData.maxAmmo and 999 or 250, weaponData.infiniteAmmo)
    end
end
