VFW.StatusHUD = VFW.StatusHUD or {}

function VFW.StatusHUD.Show(source)
    if not tonumber(source) then return false end
    TriggerClientEvent("statushud:show", source)
    return true
end

function VFW.StatusHUD.Hide(source)
    if not tonumber(source) then return false end
    TriggerClientEvent("statushud:hide", source)
    return true
end

function VFW.StatusHUD.UpdatePlayerInfo(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    TriggerClientEvent("statushud:updatePlayerInfo", xPlayer.source, {
        id = tonumber(xPlayer.source) or tonumber(source) or 0,
        firstName = xPlayer.firstName or "",
        lastName = xPlayer.lastName or "",
        age = xPlayer.dateofbirth or 0,
    })
    return true
end

function VFW.StatusHUD.UpdateStats(source, stats)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer or type(stats) ~= "table" then return false end

    TriggerClientEvent("statushud:updateStats", xPlayer.source, {
        health = tonumber(stats.health) or 100,
        armor = tonumber(stats.armor) or 0,
        hunger = tonumber(stats.hunger) or xPlayer.metadata.hunger or 100,
        thirst = tonumber(stats.thirst) or xPlayer.metadata.thirst or 100,
        stamina = tonumber(stats.stamina) or 100,
    })
    return true
end

function VFW.StatusHUD.UpdateTime(source, gameTime)
    if type(gameTime) ~= "table" then return false end
    TriggerClientEvent("statushud:updateTime", source or -1, {
        hours = tonumber(gameTime.hours) or 0,
        minutes = tonumber(gameTime.minutes) or 0,
        day = tonumber(gameTime.day) or 1,
        month = tonumber(gameTime.month) or 1,
        year = tonumber(gameTime.year) or 2024,
    })
    return true
end

function VFW.StatusHUD.SetTheme(source, theme)
    if type(theme) ~= "string" then return false end
    TriggerClientEvent("vfw:statusHUD:setTheme", source or -1, theme)
    return true
end

function VFW.StatusHUD.SetHPStyle(source, style)
    if style ~= "default" and style ~= "wide" then return false end
    TriggerClientEvent("vfw:statusHUD:setHPStyle", source or -1, style)
    return true
end

function VFW.StatusHUD.SetColor(source, key, r, g, b)
    if key ~= "hunger" and key ~= "thirst" and key ~= "oxygen" then return false end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not r or not g or not b then return false end
    TriggerClientEvent("vfw:statusHUD:setColor", source or -1, key,
        math.max(0, math.min(255, math.floor(r))),
        math.max(0, math.min(255, math.floor(g))),
        math.max(0, math.min(255, math.floor(b))))
    return true
end

function VFW.StatusHUD.ResetColors(source)
    TriggerClientEvent("vfw:statusHUD:resetColors", source or -1)
    return true
end

RegisterNetEvent("vfw:dev:playerLoaded", function(charNum)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    charNum = tonumber(charNum)
    if not charNum then return end

    if Config.EnableDebug then
        console.debug(("[dev] %s a charge le personnage %d"):format(VFW.Logs.Describe(source), charNum))
    end

    TriggerEvent("vfw:dev:playerLoadedServer", source, xPlayer, charNum)
end)

RegisterNetEvent("vfw:sellDrugs:Loaded", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    TriggerEvent("vfw:sellDrugs:playerReady", source, xPlayer)
end)

RegisterNetEvent("core:territories:findZone", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    TriggerEvent("core:territories:resolveZone", source, xPlayer.getCoords())
end)
