-- ============================================================
-- Dynamic Clothes Blacklist Loader - Client
-- Merges DB bans into Config.ClothesBan and Config.VangelicoBan at spawn
-- ============================================================

Config.StaticClothesBan = nil
Config.StaticVangelicoBan = nil

local function MergeDynamicBans(dynamicBans)
    if not dynamicBans then return end

    for gender, categories in pairs(dynamicBans) do
        for dbKey, ids in pairs(categories) do
            -- Keys prefixed with "v:" go to VangelicoBan, others to ClothesBan
            local targetConfig, configKey
            if dbKey:sub(1, 2) == "v:" then
                targetConfig = Config.VangelicoBan
                configKey = dbKey:sub(3) -- strip "v:" prefix
            else
                targetConfig = Config.ClothesBan
                configKey = dbKey
            end

            if targetConfig and targetConfig[gender] then
                if not targetConfig[gender][configKey] then
                    targetConfig[gender][configKey] = {}
                end
                for _, id in ipairs(ids) do
                    if not VFW.Table.TableContains(targetConfig[gender][configKey], id) then
                        table.insert(targetConfig[gender][configKey], id)
                    end
                end
            end
        end
    end
end

local function LoadDynamicBlacklist()
    -- Snapshot static bans only once
    if not Config.StaticClothesBan then
        Config.StaticClothesBan = VFW.DeepCopy(Config.ClothesBan)
    end
    if not Config.StaticVangelicoBan then
        Config.StaticVangelicoBan = VFW.DeepCopy(Config.VangelicoBan)
    end

    -- Restore to static base
    Config.ClothesBan = VFW.DeepCopy(Config.StaticClothesBan)
    Config.VangelicoBan = VFW.DeepCopy(Config.StaticVangelicoBan)

    -- Fetch dynamic bans from server
    local dynamicBans = TriggerServerCallback("clothesBlacklist:getAll")
    if dynamicBans then
        MergeDynamicBans(dynamicBans)
    end
end

-- Load on player spawn
AddEventHandler("playerSpawned", function()
    LoadDynamicBlacklist()
end)

-- Reload when server broadcasts changes
RegisterNetEvent("clothesBlacklist:reload")
AddEventHandler("clothesBlacklist:reload", function()
    LoadDynamicBlacklist()
end)
