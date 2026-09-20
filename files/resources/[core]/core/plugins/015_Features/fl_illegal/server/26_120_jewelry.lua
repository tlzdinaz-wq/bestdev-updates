local Jewelry = {
    config = { computerPos = { x = 0.0, y = 0.0, z = 0.0 }, computerHeading = 0.0, displayCases = {} },
    settings = {},
    robbedCases = {},
    robbery = nil,
    hacking = nil,
}

local BUILDER_PERM = "builder_jewelry"
local HACK_ITEM = "jewelry_hacking_device"
local ROBBERY_DURATION = 600
local RESTORE_DELAY = 900
local COOLDOWN = 3600
local MIN_POLICE = 0
local LOOT_ITEMS = { "jewelry_ring", "jewelry_earrings", "jewelry_necklace" }
local lastRobbery = 0

local DEFAULT_SETTINGS = {
    mapBlipPosition = "",
    policeBlipDuration = 300,
}

local function LoadConfig()
    local row = IL.Single("SELECT * FROM jewelry_config WHERE id = 1")
    if not row then return end
    Jewelry.config = {
        computerPos = {
            x = IL.Num(row.computer_x, 0.0),
            y = IL.Num(row.computer_y, 0.0),
            z = IL.Num(row.computer_z, 0.0),
        },
        computerHeading = IL.Num(row.computer_heading, 0.0),
        displayCases = IL.Decode(row.display_cases, {}),
    }
end

local function LoadSettings()
    Jewelry.settings = IL.LoadSettings("jewelry_settings", DEFAULT_SETTINGS)
end

local function RobberyRemainingMs()
    if not Jewelry.robbery then return 0 end
    return math.max(0, (Jewelry.robbery.endsAt - IL.Now()) * 1000)
end

local function EndRobbery(expired)
    if not Jewelry.robbery then return end
    Jewelry.robbery = nil
    TriggerClientEvent("core:jewelry:syncRobberyState", -1, false, 0)
    if expired then
        TriggerClientEvent("core:jewelry:robberyExpired", -1)
    else
        TriggerClientEvent("core:jewelry:robberyFinished", -1)
    end

    SetTimeout(RESTORE_DELAY * 1000, function()
        Jewelry.robbedCases = {}
        TriggerClientEvent("core:jewelry:syncRobbedCases", -1, {})
        TriggerClientEvent("core:jewelry:restoreVitrines", -1)
        TriggerClientEvent("core:jewelry:syncRestoreVitrines", -1)
    end)
end

IL.OnReady(function()
    LoadConfig()
    LoadSettings()
    TriggerClientEvent("core:jewelry:configReloaded", -1, Jewelry.config, Jewelry.settings)
end)

IL.OnPlayerLoaded(function(source)
    TriggerClientEvent("core:jewelry:configReloaded", source, Jewelry.config, Jewelry.settings)
    TriggerClientEvent("core:jewelry:syncRobbedCases", source, Jewelry.robbedCases)
    if Jewelry.robbery then
        TriggerClientEvent("core:jewelry:syncRobberyState", source, true, RobberyRemainingMs())
    end
    if Jewelry.hacking then
        TriggerClientEvent("core:jewelry:syncHackingState", source, true, Jewelry.hacking.source)
    end
end)

IL.OnPlayerDropped(function(source)
    if Jewelry.hacking and Jewelry.hacking.source == source then
        Jewelry.hacking = nil
        TriggerClientEvent("core:jewelry:syncHackingState", -1, false, 0)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if Jewelry.robbery and IL.Now() >= Jewelry.robbery.endsAt then
            EndRobbery(true)
        end
        if Jewelry.hacking and IL.Now() - Jewelry.hacking.startedAt > 300 then
            Jewelry.hacking = nil
            TriggerClientEvent("core:jewelry:syncHackingState", -1, false, 0)
        end
    end
end)

RegisterNetEvent("core:jewelry:requestConfig", function()
    local source = source
    TriggerClientEvent("core:jewelry:configReloaded", source, Jewelry.config, Jewelry.settings)
end)

IL.RegisterCallback("core:jewelry:hasHackingDevice", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return false end
    return xPlayer.haveItem(HACK_ITEM, 1)
end)

IL.RegisterCallback("core:jewelry:checkRobberyRequirements", function(source)
    local xPlayer = IL.Player(source)
    if not xPlayer then return { canRob = false, reason = "Joueur introuvable" } end

    if Jewelry.hacking then return { canRob = false, reason = "Un piratage est deja en cours" } end
    if Jewelry.robbery then return { canRob = false, reason = "Un braquage est deja en cours" } end

    if lastRobbery > 0 and (IL.Now() - lastRobbery) < COOLDOWN then
        return { canRob = false, reason = "La bijouterie a ete braquee recemment" }
    end

    if MIN_POLICE > 0 and IL.PoliceOnDutyCount() < MIN_POLICE then
        return { canRob = false, reason = "Trop peu de policiers en service" }
    end

    if not xPlayer.haveItem(HACK_ITEM, 1) then
        return { canRob = false, reason = "Il vous faut un dispositif de piratage" }
    end

    return { canRob = true, reason = "" }
end)

IL.RegisterCallback("core:jewelry:getRobbedCases", function(source)
    return Jewelry.robbedCases
end)

IL.RegisterCallback("core:jewelry:getRobberyState", function(source)
    if not Jewelry.robbery then
        return { active = false, endTime = 0 }
    end
    return { active = true, endTime = RobberyRemainingMs() }
end)

RegisterNetEvent("core:jewelry:startHack", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if Jewelry.hacking or Jewelry.robbery then return end
    if not xPlayer.haveItem(HACK_ITEM, 1) then return end

    Jewelry.hacking = { source = source, startedAt = IL.Now() }
    TriggerClientEvent("core:jewelry:syncHackingState", -1, true, source)
end)

RegisterNetEvent("core:jewelry:hackSuccess", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    if not Jewelry.hacking or Jewelry.hacking.source ~= source then return end
    if Jewelry.robbery then return end

    Jewelry.hacking = nil
    TriggerClientEvent("core:jewelry:syncHackingState", -1, false, 0)

    IL.TakeItem(xPlayer, HACK_ITEM, 1)

    local now = IL.Now()
    lastRobbery = now
    Jewelry.robbedCases = {}
    Jewelry.robbery = { source = source, startedAt = now, endsAt = now + ROBBERY_DURATION }

    TriggerClientEvent("core:jewelry:syncRobbedCases", -1, {})
    TriggerClientEvent("core:jewelry:syncRobberyState", -1, true, ROBBERY_DURATION * 1000)
end)

RegisterNetEvent("core:jewelry:failHack", function()
    local source = source
    if not Jewelry.hacking or Jewelry.hacking.source ~= source then return end
    Jewelry.hacking = nil
    TriggerClientEvent("core:jewelry:syncHackingState", -1, false, 0)
end)

RegisterNetEvent("core:jewelry:hackFailed", function()
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end
    IL.TakeItem(xPlayer, HACK_ITEM, 1)
end)

RegisterNetEvent("core:jewelry:triggerPoliceAlert", function()
    local source = source
    if not Jewelry.robbery then return end

    local coords = IL.Coords(source)
    if not coords then
        coords = Jewelry.config.computerPos
    end
    IL.AlertPolice("core:jewelry:createPoliceBlip", { x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNetEvent("core:jewelry:breakVitrine", function(caseData)
    local source = source
    if not IL.IsTable(caseData) then return end
    if not Jewelry.robbery then return end

    for _, target in pairs(VFW.Players or {}) do
        if target.source ~= source then
            TriggerClientEvent("core:jewelry:syncBreakVitrine", target.source, caseData)
        end
    end
end)

RegisterNetEvent("core:jewelry:robCase", function(caseIndex)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer then return end

    local index = IL.Int(caseIndex, nil)
    if not index then return end
    if not Jewelry.robbery then return end
    if Jewelry.robbedCases[index] then return end

    local cases = Jewelry.config.displayCases
    if IL.IsTable(cases) and #cases > 0 then
        local target = cases[index]
        if not target then return end
        if IL.DistanceTo(source, IL.Num(target.x, 0.0), IL.Num(target.y, 0.0), IL.Num(target.z, 0.0)) > 8.0 then
            return
        end
    end

    Jewelry.robbedCases[index] = true

    local given = false
    for i = 1, #LOOT_ITEMS do
        local itemName = LOOT_ITEMS[i]
        if IL.ItemExists(itemName) then
            local count = math.random(1, 3)
            if IL.GiveItem(xPlayer, itemName, count, true) then
                given = true
            end
        end
    end
    if not given then
        IL.GiveMoney(xPlayer, "black_money", math.random(2000, 4000), "jewelry")
    end

    TriggerClientEvent("core:jewelry:syncRobbedCases", -1, Jewelry.robbedCases)

    local total = IL.IsTable(cases) and #cases or 0
    if total > 0 then
        local robbed = 0
        for _ in pairs(Jewelry.robbedCases) do robbed = robbed + 1 end
        if robbed >= total then
            EndRobbery(false)
        end
    end
end)

RegisterNetEvent("core:jewelry:updateSettings", function(key, value)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if type(key) ~= "string" or DEFAULT_SETTINGS[key] == nil then return end
    if type(value) ~= "string" and type(value) ~= "number" then return end

    IL.SaveSetting("jewelry_settings", key, value)
    Jewelry.settings[key] = value
    TriggerClientEvent("core:jewelry:settingsUpdated", -1, Jewelry.settings)
end)

RegisterNetEvent("core:jewelry:updateConfig", function(config)
    local source = source
    local xPlayer = IL.Player(source)
    if not xPlayer or not xPlayer.hasPermission(BUILDER_PERM) then return end
    if not IL.IsTable(config) then return end

    local computer = IL.IsTable(config.computerPos) and config.computerPos or {}
    IL.Execute([[
        INSERT INTO jewelry_config (id, computer_x, computer_y, computer_z, computer_heading, display_cases)
        VALUES (1, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE computer_x = VALUES(computer_x), computer_y = VALUES(computer_y),
            computer_z = VALUES(computer_z), computer_heading = VALUES(computer_heading),
            display_cases = VALUES(display_cases)
    ]], {
        IL.Num(computer.x, 0.0), IL.Num(computer.y, 0.0), IL.Num(computer.z, 0.0),
        IL.Num(config.computerHeading, 0.0),
        IL.Encode(IL.IsTable(config.displayCases) and config.displayCases or {}),
    })

    LoadConfig()
    TriggerClientEvent("core:jewelry:configUpdated", -1, Jewelry.config)
end)

VFW.RegisterCommand("bijouteriemap", BUILDER_PERM, function(source, xPlayer)
    if not xPlayer then return end
    TriggerClientEvent("core:jewelry:setMapLocation", source)
end, {
    help = "Definit la position de la bijouterie sur la carte",
    params = {},
})
