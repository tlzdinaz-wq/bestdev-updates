---@meta _
---@diagnostic disable: duplicate-doc-field

---@class MyFaction
---@field MyCrewLevel any
MyFaction = {}

local LEVELS <const> = {
    { rank = "D", level = 5, xpRequired = 0 },
    { rank = "C", level = 10, xpRequired = 1000  },
    { rank = "B", level = 25, xpRequired = 20000   },
    { rank = "A", level = 50, xpRequired = 75000  },
    { rank = "S", level = 100, xpRequired = 200000  }
}

local nextLevelXpTarget = 0

---@param xp number
---@return number T
local function getProgressionPercentage(xp)
    -- Si xp est nil, retourner 0
    if not xp then
        return 0
    end

    -- Si l'XP est supérieure ou égale à celle du dernier niveau, retourner 100%
    if xp >= LEVELS[#LEVELS].xpRequired then
        return 100
    end

    local nextLevelTarget = 0

    -- Trouver le prochain niveau d'XP requis
    for i = 1, #LEVELS do
        if xp < LEVELS[i].xpRequired then
            nextLevelTarget = LEVELS[i].xpRequired
            nextLevelXpTarget = LEVELS[i].xpRequired
            break
        end
    end

    -- Si aucun niveau suivant n'a été trouvé (cas impossible normalement)
    if nextLevelTarget == 0 then
        return 100
    end

    -- Calcul simple: (XP actuelle / XP requise pour le prochain niveau) * 100
    local percentage = (xp / nextLevelTarget) * 100

    return percentage
end

---Get CrewRank
function GetCrewRank()
    local MY_CREW <const> = VFW.PlayerData.faction.name
    MyFaction.MyCrewLevel = TriggerServerCallback('core:faction:getCrewInfosForRadial', MY_CREW)

    local xp = MyFaction.MyCrewLevel
    local rank = "D"

    if xp == nil then
        xp = 0
    end

    for i = 1, #LEVELS do
        local levelInfo = LEVELS[i]
        if xp < levelInfo.xpRequired then
            rank = levelInfo.rank
            if i > 1 then
                rank = LEVELS[i - 1].rank
            end

            break
        elseif i == #LEVELS then
            rank = levelInfo.rank
        end
    end

    return rank
end

--- OpenFactionMenu - Ouvre le menu VUI faction
---@return any
function OpenFactionMenu()
    if IsPlayerInTIG() then
        VFW.ShowNotification({type = 'ROUGE', content = "Le menu faction est désactivé pendant les TIG"})
        return
    end

    if Death.isDead or VFW.PlayerData.dead then
        return
    end

    local MY_CREW <const> = VFW.PlayerData.faction.name
    if MY_CREW == "nocrew" then
        return
    end

    exports['core']:OpenFactionMenu()
end

---Load VFW.MyFaction
function VFW.LoadMyFaction()
    while (not VFW.PlayerData) do
        Wait(1000)
    end
    
    while (not VFW.PlayerData.faction) do
        Wait(1000)
    end

    local FACTION <const> = VFW.PlayerData.faction.name
    if FACTION == "nocrew" then
        return
    end

    VFW.RegisterInput("factionmenu", "Menu faction", "keyboard", "F6", OpenFactionMenu)

end

CreateThread(function()
    VFW.LoadMyFaction()
end)

---@param Faction any
RegisterNetEvent("vfw:setFaction", function(Faction)
    VFW.LoadMyFaction()
end)

---@param name string
---@param data table
RegisterNetEvent("core:faction:updateFaction", function(name, data)
    VFW.Factions.Cache.Factions = nil
    if VFW.PlayerData.faction and name == VFW.PlayerData.faction.name then
        MyFaction.MyCrewLevel = data.xp
        VFW.PlayerData.faction.devise = data.devise
    end
end)
