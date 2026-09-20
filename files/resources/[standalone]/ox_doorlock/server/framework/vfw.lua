--[[
    ox_doorlock — adaptateur framework VFW (core)

    Adapté de server/framework/es_extended.lua au contrat de _SERVER_SPEC/_API_NOYAU.md.

    Deux pièges de chargement à respecter, ne pas « simplifier » :

    1. Ce fichier est listé dans server_scripts AVANT server/main.lua, et main.lua
       redéfinit RemoveItem / DoesPlayerHaveItem / GetPlayer au top-level. Toutes
       nos définitions doivent donc rester dans SetTimeout(0, ...) pour s'exécuter
       APRÈS le top-level de main.lua et gagner. es_extended.lua fait pareil, pour
       exactement cette raison.

    2. server/utils.lua ne connaît que { es_extended, ND_Core, ox_core, qbx_core }
       et ne require() donc jamais ce fichier — il affiche au démarrage
       « no compatible framework was loaded ». C'est cosmétique : le fichier est
       chargé directement par server_scripts et les globales sont bien posées.

    EVE n'a PAS ox_inventory. Les implémentations par défaut de main.lua tapent
    exports.ox_inventory et échoueraient : on les remplace intégralement par
    l'inventaire natif de VFW (xPlayer.getInventoryItem / removeInventoryItem).
]]

local resourceName = 'core'

local function resolveShared()
    -- core n'est pas forcément déjà démarré : on réessaie au lieu d'abandonner.
    for _ = 1, 100 do
        local ok, shared = pcall(function()
            return exports[resourceName]:getSharedObject()
        end)

        if ok and type(shared) == 'table' and shared.GetPlayerFromId then
            return shared
        end

        Wait(100)
    end
end

SetTimeout(0, function()
    local VFW = resolveShared()

    if not VFW then
        warn(("ox_doorlock: '%s' n'expose pas getSharedObject, les portes par metier/item ne fonctionneront pas")
            :format(resourceName))
        return
    end

    GetPlayer = VFW.GetPlayerFromId

    ---@param playerId number
    ---@param item string
    function RemoveItem(playerId, item)
        local player = GetPlayer(playerId)

        if player then player.removeInventoryItem(item, 1) end
    end

    ---@param player table  xPlayer
    ---@param items string[] | { name: string, remove?: boolean, metadata?: string }[]
    ---@param removeItem? boolean
    ---@return string?
    function DoesPlayerHaveItem(player, items, removeItem)
        for i = 1, #items do
            local item = items[i]
            local itemName = item.name or item
            local data = player.getInventoryItem(itemName)

            if data and (data.count or 0) > 0 then
                if removeItem or item.remove then
                    player.removeInventoryItem(itemName, 1, item.metadata)
                end

                return itemName
            end
        end
    end
end)

---Identifiant de personnage comparé à door.characters.
---charId = characters.id (numérique, stable). On retombe sur l'identifiant
---"char{n}:license:xxx" si le joueur n'est pas encore complètement chargé.
---@param player table  xPlayer
---@return number|string
function GetCharacterId(player)
    return player.charId or player.identifier
end

---VFW a quatre axes d'appartenance : job, job2 (métier secondaire), faction et
---group (rang staff). door.groups peut viser n'importe lequel.
---@param player table  xPlayer
---@return { name: string, grade: number }[]
local function membershipsOf(player)
    local list = {}

    if type(player.job) == 'table' and player.job.name then
        list[#list + 1] = { name = player.job.name, grade = player.job.grade or 0 }
    end

    if type(player.job2) == 'table' and player.job2.name then
        list[#list + 1] = { name = player.job2.name, grade = player.job2.grade or 0 }
    end

    if type(player.faction) == 'string' and player.faction ~= '' then
        list[#list + 1] = { name = player.faction, grade = 0 }
    elseif type(player.faction) == 'table' and player.faction.name then
        list[#list + 1] = { name = player.faction.name, grade = player.faction.grade or 0 }
    end

    if type(player.group) == 'string' and player.group ~= '' then
        list[#list + 1] = { name = player.group, grade = 0 }
    end

    return list
end

---@param player table  xPlayer
---@param filter string | string[] | table<string, number>
---@return string? name, number? grade
function IsPlayerInGroup(player, filter)
    local memberships = membershipsOf(player)
    local filterType = type(filter)

    if filterType == 'string' then
        for i = 1, #memberships do
            if memberships[i].name == filter then
                return memberships[i].name, memberships[i].grade
            end
        end

        return
    end

    if filterType ~= 'table' then return end

    local tabletype = table.type(filter)

    if tabletype == 'hash' then
        for i = 1, #memberships do
            local grade = filter[memberships[i].name]

            if grade and grade <= memberships[i].grade then
                return memberships[i].name, memberships[i].grade
            end
        end
    elseif tabletype == 'array' then
        for i = 1, #filter do
            for j = 1, #memberships do
                if memberships[j].name == filter[i] then
                    return memberships[j].name, memberships[j].grade
                end
            end
        end
    end
end
