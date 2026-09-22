local function findAccount(accounts, name)
    for i = 1, #accounts do
        if accounts[i].name == name then
            return accounts[i], i
        end
    end
end

local function ensureAccount(accounts, name)
    local account = findAccount(accounts, name)
    if account then return account end

    local cfg = Config.Accounts and Config.Accounts[name] or {}
    account = {
        name = name,
        money = Config.StartingAccountMoney[name] or 0,
        label = cfg.label or name,
        round = cfg.round ~= false,
    }
    accounts[#accounts + 1] = account
    return account
end

function VFW.CreateExtendedPlayer(source, row, account)
    source = tonumber(source)

    local self = {}

    self.source = source
    self.charId = row.id
    self.charNum = row.char_slot
    self.identifier = row.identifier
    self.accountId = row.account_id
    self.playerName = GetPlayerName(source) or "unknown"

    self.firstName = row.firstname
    self.lastName = row.lastname
    self.name = ("%s %s"):format(row.firstname, row.lastname)
    self.dateofbirth = row.dateofbirth
    self.sex = row.sex
    self.birthplace = row.birthplace
    self.height = row.height
    self.address = row.address
    self.mugshot = row.mugshot

    self.skin = row.skin or {}
    self.tattoos = row.tattoos or {}
    self.accounts = row.accounts or {}
    for name in pairs(Config.Accounts or {}) do
        ensureAccount(self.accounts, name)
    end
    ensureAccount(self.accounts, "money")
    self.inventory = row.inventory or {}
    self.loadout = row.loadout or {}
    self.licenses = row.licenses or {}
    self.metadata = row.metadata or {}
    self.maxWeight = row.max_weight or Config.MaxWeight
    self.weight = 0
    self.dead = row.is_dead == 1
    self.group = row.group or "user"
    self.faction = row.faction or ""

    self.job = VFW.DB.BuildJob(row.job, row.job_grade)
    self.job.onDuty = row.job_duty == 1
    self.job2 = row.job2 ~= "" and VFW.DB.BuildJob(row.job2, row.job2_grade) or nil

    if VFW.HydrateNiveau6Permissions then
        VFW.HydrateNiveau6Permissions(account)
    end
    self.globalData = account
    self.uuid = account.uuid
    self.permissions = account.permissions or {}
    self.vipTier = account.vip_tier or 0

    self.coords = row.coords or Config.DefaultSpawns[1]
    self.lastCoords = self.coords

    local function push(event, ...)
        TriggerClientEvent(event, self.source, ...)
    end

    function self.triggerEvent(event, ...)
        push(event, ...)
    end

    function self.setPlayerData(key, val)
        self[key] = val
        push("vfw:updatePlayerData", key, val)
    end

    function self.getPlayerData()
        return {
            source = self.source,
            serverId = self.source,
            charId = self.charId,
            charNum = self.charNum,
            identifier = self.identifier,
            playerName = self.playerName,
            firstName = self.firstName,
            lastName = self.lastName,
            name = self.name,
            dateofbirth = self.dateofbirth,
            sex = self.sex,
            birthplace = self.birthplace,
            height = self.height,
            address = self.address,
            mugshot = self.mugshot,
            skin = self.skin,
            tattoos = self.tattoos,
            accounts = self.accounts,
            inventory = self.inventory,
            loadout = self.loadout,
            licenses = self.licenses,
            metadata = self.metadata,
            maxWeight = self.maxWeight,
            weight = self.weight,
            dead = self.dead,
            group = self.group,
            faction = self.faction,
            job = self.job,
            job2 = self.job2,
            coords = self.coords,
            ped = 0,
            loaded = true,
            shortcuts = self.metadata.shortcuts or {},
            shortcutsActive = self.metadata.shortcutsActive or false,
            tier = self.vipTier,
        }
    end

    function self.getCoords(withHeading)
        local ped = GetPlayerPed(self.source)
        if not ped or ped == 0 then
            return self.lastCoords
        end

        local c = GetEntityCoords(ped)
        if withHeading then
            return { x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(ped) }
        end
        return { x = c.x, y = c.y, z = c.z }
    end

    function self.updateCoords()
        self.lastCoords = self.getCoords(true)
        self.coords = self.lastCoords
        return self.lastCoords
    end

    function self.setCoords(coords)
        local ped = GetPlayerPed(self.source)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        if coords.heading then
            SetEntityHeading(ped, coords.heading)
        end
        self.lastCoords = coords
        self.coords = coords
    end

    function self.kick(reason)
        DropPlayer(self.source, reason or "Vous avez été expulsé.")
    end

    function self.showNotification(data)
        push("vfw:showNotification", data)
    end

    function self.showHelpNotification(msg, thisFrame, beep, duration)
        push("vfw:showHelpNotification", msg, thisFrame, beep, duration)
    end

    function self.hasPermission(permission)
        if not permission or permission == "" then return true end
        if self.globalData and VFW.IsNiveau6Role and VFW.IsNiveau6Role(self.globalData.role) then return true end
        return self.permissions[permission] == true
    end

    function self.setPermission(permission, value)
        self.permissions[permission] = value and true or nil
        self.globalData.permissions = self.permissions
        MySQL.update("UPDATE users SET permissions = ? WHERE id = ?", { VFW.DB.Encode(self.permissions), self.accountId })
        push("vfw:updatePlayerGlobalData", self.getGlobalData())
    end

    function self.getGlobalData()
        local data = {
            id = self.globalData.id,
            uuid = self.uuid,
            permissions = self.permissions,
            vip_tier = self.vipTier,
            level = self.globalData.level or 0,
            spacecoins = self.globalData.spacecoins or 0,
            role = self.globalData.role or "user",
            roleId = self.globalData.role_id or 0,
        }
        if VFW.HydrateNiveau6Permissions then
            VFW.HydrateNiveau6Permissions(data)
            self.permissions = data.permissions
            self.globalData.permissions = data.permissions
            self.globalData.role = data.role
        end
        return data
    end

    function self.getAccount(name)
        return (findAccount(self.accounts, name))
    end

    function self.setAccountMoney(name, money, reason)
        money = math.floor(money + 0.5)
        if money < 0 then money = 0 end

        local account = ensureAccount(self.accounts, name)

        account.money = money
        push("vfw:setAccountMoney", account)
        TriggerEvent("vfw:setAccountMoney", self.source, name, money, reason)
    end

    function self.addAccountMoney(name, money, reason)
        if money <= 0 then return end
        local account = ensureAccount(self.accounts, name)
        self.setAccountMoney(name, account.money + money, reason)
    end

    function self.removeAccountMoney(name, money, reason)
        if money <= 0 then return end
        local account = findAccount(self.accounts, name)
        if not account then return end
        self.setAccountMoney(name, account.money - money, reason)
    end

    function self.getMoney()
        local account = findAccount(self.accounts, "money")
        return account and account.money or 0
    end

    function self.getInventoryItem(name)
        for i = 1, #self.inventory do
            if self.inventory[i].name == name then
                return self.inventory[i]
            end
        end
    end

    function self.haveItem(name, count)
        local item = self.getInventoryItem(name)
        return item ~= nil and item.count >= (count or 1)
    end

    function self.getWeight()
        local weight = 0
        for i = 1, #self.inventory do
            local entry = self.inventory[i]
            local def = VFW.Items[entry.name]
            weight = weight + ((def and def.weight or 0) * entry.count)
        end
        self.weight = weight
        return weight
    end

    function self.canCarryItem(name, count)
        local def = VFW.Items[name]
        if not def then return false end
        return (self.getWeight() + (def.weight * count)) <= self.maxWeight
    end

    function self.addInventoryItem(name, count, metadata, notify)
        local def = VFW.Items[name]
        if not def then
            console.warn(("addInventoryItem: item inconnu '%s'"):format(tostring(name)))
            return false
        end

        count = count or 1
        local item = self.getInventoryItem(name)
        if item then
            item.count = item.count + count
        else
            item = { name = name, count = count, label = def.label, weight = def.weight, metadata = metadata }
            self.inventory[#self.inventory + 1] = item
        end

        self.getWeight()
        push("vfw:addInventoryItem", name, item.count, notify ~= false)
        TriggerEvent("vfw:inventory:added", self.source, name, count)
        return true
    end

    function self.removeInventoryItem(name, count, metadata, notify)
        count = count or 1
        local item = self.getInventoryItem(name)
        if not item or item.count < count then return false end

        item.count = item.count - count
        if item.count <= 0 then
            for i = 1, #self.inventory do
                if self.inventory[i].name == name then
                    table.remove(self.inventory, i)
                    break
                end
            end
            item.count = 0
        end

        self.getWeight()
        push("vfw:removeInventoryItem", name, item.count, notify ~= false)
        TriggerEvent("vfw:inventory:removed", self.source, name, count)
        return true
    end

    function self.setMaxWeight(weight)
        self.maxWeight = weight
        push("vfw:setMaxWeight", weight)
    end

    function self.getLoadoutWeapon(name)
        for i = 1, #self.loadout do
            if self.loadout[i].name == name then
                return self.loadout[i], i
            end
        end
    end

    function self.hasWeapon(name)
        return self.getLoadoutWeapon(name) ~= nil
    end

    function self.addWeapon(name, ammo)
        if self.hasWeapon(name) then return false end
        local weapon = VFW.GetWeapon and select(2, VFW.GetWeapon(name)) or nil
        self.loadout[#self.loadout + 1] = {
            name = name,
            ammo = ammo or 0,
            label = weapon and weapon.label or name,
            components = {},
            tintIndex = 0,
        }
        push("vfw:addWeaponClient", name, ammo or 0)
        return true
    end

    function self.removeWeapon(name)
        local _, index = self.getLoadoutWeapon(name)
        if not index then return false end
        table.remove(self.loadout, index)
        push("vfw:removeWeaponClient", name)
        return true
    end

    function self.addWeaponAmmo(name, ammo)
        local weapon = self.getLoadoutWeapon(name)
        if not weapon then return false end
        weapon.ammo = weapon.ammo + ammo
        push("vfw:setWeaponAmmoClient", name, weapon.ammo)
        return true
    end

    function self.setWeaponAmmo(name, ammo)
        local weapon = self.getLoadoutWeapon(name)
        if not weapon then return false end
        weapon.ammo = ammo
        return true
    end

    function self.addWeaponComponent(name, component)
        local weapon = self.getLoadoutWeapon(name)
        if not weapon then return false end
        for i = 1, #weapon.components do
            if weapon.components[i] == component then return false end
        end
        weapon.components[#weapon.components + 1] = component
        push("vfw:addWeaponComponentClient", name, component)
        return true
    end

    function self.removeWeaponComponent(name, component)
        local weapon = self.getLoadoutWeapon(name)
        if not weapon then return false end
        for i = 1, #weapon.components do
            if weapon.components[i] == component then
                table.remove(weapon.components, i)
                push("vfw:removeWeaponComponent", name, component)
                return true
            end
        end
        return false
    end

    function self.setWeaponTint(name, tintIndex)
        local weapon = self.getLoadoutWeapon(name)
        if not weapon then return false end
        weapon.tintIndex = tintIndex
        push("vfw:setWeaponTint", joaat(name), tintIndex)
        return true
    end

    function self.getJob()
        return self.job
    end

    function self.setJob(name, grade, onDuty)
        local previous = self.job
        self.job = VFW.DB.BuildJob(name, grade)
        if onDuty ~= nil then
            self.job.onDuty = onDuty
        end
        push("vfw:updatePlayerData", "job", self.job)
        TriggerEvent("vfw:setJob", self.source, self.job, previous)
    end

    function self.setJob2(name, grade)
        local previous = self.job2
        self.job2 = name ~= "" and VFW.DB.BuildJob(name, grade) or nil
        push("vfw:updatePlayerData", "job2", self.job2)
        TriggerEvent("vfw:setJob2", self.source, self.job2, previous)
    end

    function self.setDuty(onDuty)
        self.job.onDuty = onDuty and true or false
        push("vfw:updatePlayerData", "job", self.job)
        TriggerEvent("vfw:setDuty", self.source, self.job.onDuty)
    end

    function self.setFaction(faction)
        self.faction = faction or ""
        push("vfw:setFaction", self.faction)
    end

    function self.setGroup(group)
        self.group = group
        push("vfw:setGroup", group)
    end

    function self.getLicense(name)
        for i = 1, #self.licenses do
            if self.licenses[i].type == name then
                return self.licenses[i]
            end
        end
    end

    function self.addLicense(name, label)
        if self.getLicense(name) then return false end
        self.licenses[#self.licenses + 1] = { type = name, label = label or name }
        self.setPlayerData("licenses", self.licenses)
        return true
    end

    function self.removeLicense(name)
        for i = 1, #self.licenses do
            if self.licenses[i].type == name then
                table.remove(self.licenses, i)
                self.setPlayerData("licenses", self.licenses)
                return true
            end
        end
        return false
    end

    function self.getMeta(key, subKey)
        if not key then return self.metadata end
        local value = self.metadata[key]
        if subKey and type(value) == "table" then
            return value[subKey]
        end
        return value
    end

    function self.setMeta(key, value, subValue)
        if subValue ~= nil then
            if type(self.metadata[key]) ~= "table" then
                self.metadata[key] = {}
            end
            self.metadata[key][value] = subValue
        else
            self.metadata[key] = value
        end
        self.setPlayerData("metadata", self.metadata)
    end

    function self.handcuff()
        Player(self.source).state:set("isCuffed", true, true)
        push("vfw:handcuff")
    end

    function self.uncuff()
        Player(self.source).state:set("isCuffed", false, true)
        push("vfw:uncuff")
    end

    function self.revive()
        self.dead = false
        self.setMeta("health", 200)
        push("vfw:revivePlayer")
    end

    function self.save()
        self.updateCoords()
        VFW.DB.SaveCharacter(self)
    end

    return self
end
