-- HUD job / gang / liquide / banque. Affiché par défaut, masqué depuis le F5.

local hideEco = GetResourceKvpString("hide_player_eco") == "1"
local pushEco

local ECO_STYLES = {
    { id = "classic", label = "Classique" },
    { id = "glass", label = "Verre" },
    { id = "neon", label = "Néon" },
    { id = "ribbon", label = "Ruban" },
    { id = "orbs", label = "Orbes" },
    { id = "line", label = "Ligne" },
    { id = "columns", label = "Colonnes" },
    { id = "tickets", label = "Tickets" },
    { id = "hex", label = "Hexagones" },
    { id = "stack", label = "Pile" },
    { id = "chips", label = "Jetons" },
    { id = "receipt", label = "Reçu" },
}

function EcoHudStyleList()
    local labels = {}
    for i = 1, #ECO_STYLES do
        labels[i] = ECO_STYLES[i].label
    end
    return labels
end

function EcoHudStyleAt(index)
    local entry = ECO_STYLES[tonumber(index) or 0]
    return entry and entry.id or "classic"
end

function EcoHudStyleId()
    local style = GetResourceKvpString("player_eco_style") or "classic"
    for i = 1, #ECO_STYLES do
        if ECO_STYLES[i].id == style then
            return style, i
        end
    end
    return "classic", 1
end

function ApplyEcoHudStyle(style)
    local found = false
    for i = 1, #ECO_STYLES do
        if ECO_STYLES[i].id == style then
            found = true
            break
        end
    end
    if not found then style = "classic" end
    SetResourceKvp("player_eco_style", style)
    pushEco()
end

local function moneyText(amount)
    local n = math.floor(tonumber(amount) or 0)
    local negative = n < 0
    local digits = tostring(math.abs(n))
    local formatted = digits:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
    if negative then
        formatted = "-" .. formatted
    end
    return formatted .. " $"
end

local function cashAmount()
    local total = 0
    local inventory = VFW.PlayerData and VFW.PlayerData.inventory
    if type(inventory) == "table" then
        for i = 1, #inventory do
            local item = inventory[i]
            if item and item.name == "money" then
                total = total + (tonumber(item.count) or 0)
            end
        end
    end
    if total == 0 and VFW.GetAccount then
        local account = VFW.GetAccount("money")
        if account then
            total = tonumber(account.money) or 0
        end
    end
    return total
end

local function bankAmount()
    if not VFW.GetAccount then return 0 end
    local account = VFW.GetAccount("bank")
    return account and (tonumber(account.money) or 0) or 0
end

local function jobLabel()
    local job = VFW.PlayerData and VFW.PlayerData.job
    if type(job) ~= "table" or not job.name or job.name == "unemployed" then
        return "Sans emploi"
    end
    return job.label or job.name
end

local function gangLabel()
    local faction = VFW.PlayerData and VFW.PlayerData.faction
    if type(faction) == "table" then
        if faction.name and faction.name ~= "" and faction.name ~= "nocrew" then
            return faction.label or faction.name
        end
    elseif type(faction) == "string" and faction ~= "" and faction ~= "nocrew" then
        return faction
    end

    local job2 = VFW.PlayerData and VFW.PlayerData.job2
    if type(job2) == "table" and job2.name and job2.name ~= "" and job2.name ~= "unemployed" and job2.name ~= "nocrew" then
        return job2.label or job2.name
    end
    return "Aucun"
end

function pushEco()
    SendNUIMessage({
        action = "nui:playerEco",
        data = {
            visible = not hideEco,
            job = jobLabel(),
            gang = gangLabel(),
            cash = moneyText(cashAmount()),
            bank = moneyText(bankAmount()),
            style = select(1, EcoHudStyleId()),
        }
    })
end

function TogglePlayerEcoHud(hidden)
    hideEco = hidden == true
    SetResourceKvp("hide_player_eco", hideEco and "1" or "0")
    pushEco()
end

RegisterNetEvent("vfw:setJob", function()
    pushEco()
end)

RegisterNetEvent("vfw:setFaction", function()
    pushEco()
end)

RegisterNetEvent("vfw:setAccountMoney", function()
    pushEco()
end)

RegisterNetEvent("vfw:addInventoryItem", function()
    pushEco()
end)

RegisterNetEvent("vfw:removeInventoryItem", function()
    pushEco()
end)

AddEventHandler("vfw:setPlayerData", function(key)
    if key == "job" or key == "job2" or key == "faction" or key == "accounts" or key == "inventory" then
        pushEco()
    end
end)

CreateThread(function()
    while not (VFW.PlayerData and VFW.PlayerData.job) do
        Wait(500)
    end
    pushEco()
    while true do
        Wait(hideEco and 4000 or 1500)
        pushEco()
    end
end)
