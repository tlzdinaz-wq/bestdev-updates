VFW.DB = {}

local function decode(value, fallback)
    if value == nil or value == "" then return fallback end
    if type(value) == "table" then return value end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

VFW.DB.Decode = decode

function VFW.DB.Encode(value)
    return json.encode(value or {})
end

local function humanizeItemName(name)
    return (name:gsub("_", " "):gsub("(%S+)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end))
end

local function itemLabel(name, description)
    if type(description) == "string" then
        local dash = description:match("^(.-) %- ")
        if dash and #dash >= 2 and #dash <= 48 and not dash:find("%.") then
            return dash
        end
    end
    return humanizeItemName(name)
end

local function itemInventoryType(name)
    if name:sub(1, 7) == "weapon_" then return "weapons" end
    return "items"
end

local function itemWeight(name, kind)
    if name == "money" or name == "dirty_money" then return 0 end
    if kind == "weapons" then return 1500 end
    if name:sub(1, 5) == "ammo_" then return 1 end
    return 100
end

local function itemDataJson(name, description)
    local consumable = name == "cigarette" or name == "cigar" or name == "ticket_gratter"
    if type(description) == "string" and description:find("Restaure", 1, true) then
        consumable = true
    end
    if consumable then
        return json.encode({ type = "consumable" })
    end
    return json.encode({ type = "objects" })
end

function VFW.DB.SeedItemsIfEmpty()
    local count = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM items") or 0) or 0
    if count > 0 then return end

    local catalog = VFW.ItemDescriptions
    if type(catalog) ~= "table" then
        console.warn("Items: catalogue introuvable, table `items` laissée vide")
        return
    end

    local values, params = {}, {}
    local inserted = 0

    local function flush()
        if #values == 0 then return end
        MySQL.insert.await(
            "INSERT IGNORE INTO items (name, label, type, weight, premium, perm, image, description, data) VALUES " .. table.concat(values, ", "),
            params
        )
        inserted = inserted + #values
        values, params = {}, {}
    end

    for name, description in pairs(catalog) do
        if type(name) == "string" and name ~= "" then
            local kind = itemInventoryType(name)
            values[#values + 1] = "(?, ?, ?, ?, 0, 0, ?, ?, ?)"
            params[#params + 1] = name
            params[#params + 1] = itemLabel(name, description)
            params[#params + 1] = kind
            params[#params + 1] = itemWeight(name, kind)
            params[#params + 1] = ("items/%s.webp"):format(name)
            params[#params + 1] = type(description) == "string" and description or ""
            params[#params + 1] = itemDataJson(name, description)
            if #values >= 40 then flush() end
        end
    end
    flush()

    console.init("Items", ("%d objets amorcés depuis le catalogue"):format(inserted))
end

function VFW.DB.LoadItems()
    VFW.DB.SeedItemsIfEmpty()
    local rows = MySQL.query.await("SELECT * FROM items") or {}
    local items = {}
    for i = 1, #rows do
        local row = rows[i]
        local data = decode(row.data, {})
        if not data.type then data.type = "objects" end

        local image = row.image
        if type(data) == "table" and type(data.image) == "string" and data.image ~= "" then
            image = data.image
        elseif type(image) ~= "string" or image == "" then
            image = ("items/%s.webp"):format(row.name)
        end

        items[row.name] = {
            name = row.name,
            label = row.label,
            type = row.type,
            weight = row.weight,
            rare = row.rare == 1,
            canRemove = row.can_remove == 1,
            usable = row.usable == 1,
            premium = row.premium == 1,
            perm = row.perm == 1,
            image = image,
            description = row.description,
            data = data,
        }
    end
    VFW.Items = items
    console.init("Items", ("%d items chargés"):format(#rows))
    return items
end

function VFW.DB.LoadJobs()
    local jobRows = MySQL.query.await("SELECT * FROM jobs") or {}
    local gradeRows = MySQL.query.await("SELECT * FROM job_grades ORDER BY `job_name`, `grade`") or {}

    local jobs = {}
    for i = 1, #jobRows do
        local row = jobRows[i]
        jobs[row.name] = {
            name = row.name,
            label = row.label,
            type = row.type,
            whitelisted = row.whitelisted == 1,
            grades = {},
        }
    end

    for i = 1, #gradeRows do
        local row = gradeRows[i]
        local job = jobs[row.job_name]
        if job then
            job.grades[tostring(row.grade)] = {
                grade = row.grade,
                name = row.name,
                label = row.label,
                salary = row.salary,
                isBoss = row.is_boss == 1 or row.is_boss == true or row.is_boss == "1",
                permissions = decode(row.permissions, {}),
            }
        end
    end

    if not jobs.unemployed then
        jobs.unemployed = {
            name = "unemployed",
            label = "Sans emploi",
            type = "job",
            whitelisted = false,
            grades = { ["0"] = { grade = 0, name = "unemployed", label = "Sans emploi", salary = 200, isBoss = false, permissions = {} } },
        }
    end

    VFW.Jobs = jobs
    console.init("Jobs", ("%d métiers chargés"):format(#jobRows))
    return jobs
end

function VFW.DB.BuildJob(name, grade)
    local job = VFW.Jobs[name] or VFW.Jobs.unemployed
    grade = tonumber(grade) or 0

    local gradeData = job.grades[tostring(grade)]
    if not gradeData then
        local _, first = next(job.grades)
        gradeData = first or { grade = 0, name = "unknown", label = "Inconnu", salary = 0, isBoss = false, permissions = {} }
        grade = gradeData.grade
    end

    return {
        name = job.name,
        label = job.label,
        type = job.type,
        grade = grade,
        grade_name = gradeData.name,
        grade_label = gradeData.label,
        grade_salary = gradeData.salary,
        grade_is_boss = gradeData.isBoss,
        permissions = gradeData.permissions or {},
        onDuty = Config.DefaultJobDuty and true or false,
    }
end

function VFW.IsOwnerIdentifier(identifier)
    if type(identifier) ~= "string" or identifier == "" then return false end
    local owners = Config.OwnerIdentifiers
    if type(owners) ~= "table" then return false end
    for i = 1, #owners do
        local owner = owners[i]
        if type(owner) == "string" and owner ~= "" then
            if identifier == owner or identifier:find(owner, 1, true) then
                return true
            end
        end
    end
    return false
end

if not VFW.BuildFullPermissions then
    function VFW.BuildFullPermissions()
        local all = { dev = true, staff = true, admin = true }
        for key in pairs(Config.Permissions or {}) do
            all[key] = true
        end
        return all
    end
end

local function permCount(t)
    local n = 0
    if type(t) == "table" then
        for _ in pairs(t) do n = n + 1 end
    end
    return n
end

function VFW.DB.EnsureNiveau6Account(account)
    if not account then return account end
    local before = permCount(account.permissions)
    if VFW.HydrateNiveau6Permissions then
        VFW.HydrateNiveau6Permissions(account)
    elseif VFW.IsNiveau6Role and VFW.IsNiveau6Role(account.role) then
        account.role = "niveau_6"
        account.permissions = VFW.BuildFullPermissions()
    end
    if account.role == "niveau_6" and account.id and permCount(account.permissions) > before then
        MySQL.update.await(
            "UPDATE users SET role = ?, permissions = ? WHERE id = ?",
            { "niveau_6", json.encode(account.permissions), account.id }
        )
    end
    return account
end

function VFW.DB.ApplyOwnerAccount(account)
    if not account or not VFW.IsOwnerIdentifier(account.identifier) then
        return account
    end

    local all = VFW.BuildFullPermissions()
    account.role = "niveau_6"
    account.permissions = all
    account.vip_tier = math.max(tonumber(account.vip_tier) or 0, 3)

    MySQL.update.await(
        "UPDATE users SET role = ?, permissions = ?, vip_tier = ? WHERE id = ?",
        { "niveau_6", json.encode(all), account.vip_tier, account.id }
    )
    return account
end

function VFW.DB.LoadAccount(identifier)
    local row = MySQL.single.await("SELECT * FROM users WHERE identifier = ?", { identifier })
    if row then
        row.permissions = decode(row.permissions, {})
        return VFW.DB.EnsureNiveau6Account(VFW.DB.ApplyOwnerAccount(row))
    end

    local id = VFW.GenerateUUID and VFW.GenerateUUID() or tostring(math.random(1, 2 ^ 31))
    local isOwner = VFW.IsOwnerIdentifier(identifier)
    local perms = isOwner and VFW.BuildFullPermissions() or {}
    local role = isOwner and "niveau_6" or "user"
    local vip = isOwner and 3 or 0

    MySQL.insert.await(
        "INSERT INTO users (id, identifier, uuid, slots, role, permissions, vip_tier) VALUES (?, ?, ?, ?, ?, ?, ?)",
        { id, identifier, id, Config.Multicharacter.Slots, role, json.encode(perms), vip }
    )

    return VFW.DB.EnsureNiveau6Account(VFW.DB.ApplyOwnerAccount({
        id = id,
        identifier = identifier,
        uuid = id,
        permissions = perms,
        role = role,
        role_id = 0,
        level = 0,
        vip_tier = vip,
        spacecoins = 0,
        slots = Config.Multicharacter.Slots,
        playtime = 0,
        banned = 0,
    }))
end

function VFW.DB.LoadCharacters(accountId)
    local rows = MySQL.query.await(
        "SELECT * FROM characters WHERE account_id = ? AND deleted_at IS NULL ORDER BY char_slot ASC",
        { accountId }
    ) or {}

    for i = 1, #rows do
        local row = rows[i]
        row.skin = decode(row.skin, {})
        row.coords = decode(row.coords, Config.DefaultSpawns[1])
        row.accounts = decode(row.accounts, {})
        row.inventory = decode(row.inventory, {})
        row.loadout = decode(row.loadout, {})
        row.licenses = decode(row.licenses, {})
        row.metadata = decode(row.metadata, {})
        row.tattoos = decode(row.tattoos, {})
    end

    return rows
end

function VFW.DB.LoadCharacter(identifier)
    local row = MySQL.single.await("SELECT * FROM characters WHERE identifier = ? AND deleted_at IS NULL", { identifier })
    if not row then return nil end

    row.skin = decode(row.skin, {})
    row.coords = decode(row.coords, Config.DefaultSpawns[1])
    row.accounts = decode(row.accounts, {})
    row.inventory = decode(row.inventory, {})
    row.loadout = decode(row.loadout, {})
    row.licenses = decode(row.licenses, {})
    row.metadata = decode(row.metadata, {})
    row.tattoos = decode(row.tattoos, {})
    return row
end

function VFW.DB.CreateCharacter(accountId, slot, identifier, data)
    local accounts = {}
    for name, cfg in pairs(Config.Accounts) do
        accounts[#accounts + 1] = {
            name = name,
            money = Config.StartingAccountMoney[name] or 0,
            label = cfg.label,
            round = cfg.round,
        }
    end
    if not Config.Accounts.money then
        table.insert(accounts, 1, { name = "money", money = Config.StartingAccountMoney.money or 0, label = "Espèces", round = true })
    end

    local spawn = Config.DefaultSpawns[1]
    local coords = { x = spawn.x, y = spawn.y, z = spawn.z, heading = spawn.heading or 0.0 }

    local inventory = {}
    if Config.StartingInventoryItems then
        for name, count in pairs(Config.StartingInventoryItems) do
            inventory[#inventory + 1] = { name = name, count = count }
        end
    end

    -- Starter pack configuré en jeu (Gestion > Développeurs) : prime sur la config
    local starter = VFW.GetStarterPack and VFW.GetStarterPack() or nil
    if starter then
        for _, account in ipairs(accounts) do
            if account.name == "bank" and tonumber(starter.bank) then account.money = math.floor(tonumber(starter.bank)) end
            if account.name == "money" and tonumber(starter.cash) then account.money = math.floor(tonumber(starter.cash)) end
        end
        if type(starter.items) == "table" and #starter.items > 0 then
            inventory = {}
            for _, it in ipairs(starter.items) do
                if type(it.name) == "string" and (tonumber(it.count) or 0) > 0 then
                    inventory[#inventory + 1] = { name = it.name, count = math.floor(tonumber(it.count)) }
                end
            end
        end
    end

    local id = MySQL.insert.await([[
        INSERT INTO characters
            (identifier, account_id, char_slot, firstname, lastname, dateofbirth, sex, birthplace,
             height, skin, tattoos, mugshot, coords, accounts, inventory, loadout, licenses, metadata, max_weight)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        identifier, accountId, slot,
        data.firstname or "", data.lastname or "", data.dateofbirth or "",
        data.sex or "m", data.birthplace or "", tonumber(data.height) or 175,
        VFW.DB.Encode(data.skin), VFW.DB.Encode(data.tattoos), data.mugshot or "",
        VFW.DB.Encode(coords), VFW.DB.Encode(accounts), VFW.DB.Encode(inventory),
        VFW.DB.Encode({}), VFW.DB.Encode({}),
        VFW.DB.Encode({ health = 200, armor = 0, hunger = 100, thirst = 100 }),
        Config.MaxWeight,
    })

    if data.tattoos then
        for i = 1, #data.tattoos do
            local t = data.tattoos[i]
            MySQL.insert.await(
                "INSERT INTO character_tattoos (identifier, collection, hash, zone) VALUES (?, ?, ?, ?)",
                { identifier, t.Collection or "", t.Hash or t.HashName or "", t.zone or "" }
            )
        end
    end

    return id
end

function VFW.DB.SaveCharacter(xPlayer)
    if not xPlayer or not xPlayer.identifier then return end

    MySQL.update([[
        UPDATE characters SET
            firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, birthplace = ?, height = ?,
            skin = ?, tattoos = ?, mugshot = ?, coords = ?,
            job = ?, job_grade = ?, job_duty = ?, job2 = ?, job2_grade = ?, faction = ?, `group` = ?,
            accounts = ?, inventory = ?, loadout = ?, licenses = ?, metadata = ?,
            address = ?, max_weight = ?, is_dead = ?
        WHERE identifier = ?
    ]], {
        xPlayer.firstName, xPlayer.lastName, xPlayer.dateofbirth, xPlayer.sex, xPlayer.birthplace, xPlayer.height,
        VFW.DB.Encode(xPlayer.skin), VFW.DB.Encode(xPlayer.tattoos), xPlayer.mugshot or "",
        VFW.DB.Encode(xPlayer.getCoords(true)),
        xPlayer.job.name, xPlayer.job.grade, xPlayer.job.onDuty and 1 or 0,
        xPlayer.job2 and xPlayer.job2.name or "", xPlayer.job2 and xPlayer.job2.grade or 0,
        xPlayer.faction or "", xPlayer.group or "user",
        VFW.DB.Encode(xPlayer.accounts), VFW.DB.Encode(xPlayer.inventory),
        VFW.DB.Encode(xPlayer.loadout), VFW.DB.Encode(xPlayer.licenses),
        VFW.DB.Encode(xPlayer.metadata),
        xPlayer.address or "", xPlayer.maxWeight or Config.MaxWeight,
        xPlayer.dead and 1 or 0,
        xPlayer.identifier,
    })
end

function VFW.DB.SaveAll()
    for _, xPlayer in pairs(VFW.Players) do
        VFW.DB.SaveCharacter(xPlayer)
    end
end

MySQL.ready(function()
    VFW.DB.LoadJobs()
    VFW.DB.LoadItems()

    local all = VFW.BuildFullPermissions()
    local encoded = json.encode(all)
    for i = 1, #(Config.OwnerIdentifiers or {}) do
        local owner = Config.OwnerIdentifiers[i]
        if type(owner) == "string" and owner ~= "" then
            MySQL.update.await(
                "UPDATE users SET role = ?, permissions = ?, vip_tier = GREATEST(IFNULL(vip_tier, 0), 3) WHERE identifier = ? OR identifier LIKE ?",
                { "niveau_6", encoded, owner, "%" .. owner .. "%" }
            )
        end
    end

    VFW.Ready = true
    console.init("Core", "Base de données prête")
end)

CreateThread(function()
    while true do
        Wait(5 * 60000)
        VFW.DB.SaveAll()
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    VFW.DB.SaveAll()
end)
