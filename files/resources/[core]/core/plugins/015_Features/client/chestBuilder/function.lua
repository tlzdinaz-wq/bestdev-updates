ChestBuilder = {}
ChestBuilder.cache = {}

ChestBuilder.blipsCache = {}

local function capitaliser(s)
    if not s or s == "" then
        return ""
    end
    return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

RegisterNetEvent("vfw:setJob", function(job)
    VFW.PlayerData.job = job
    if ChestBuilder.RefreshAllBlips then
        ChestBuilder:RefreshAllBlips()
    end
end)

RegisterNetEvent("vfw:setFaction", function(faction)
    if faction then
        VFW.PlayerData.faction = faction
    end
    if ChestBuilder.RefreshAllBlips then
        ChestBuilder:RefreshAllBlips()
    end
end)

--- Cache un coffre dont le grade minimal d'accès est plus haut que celui du joueur.
--- On prend le seuil le plus bas entre dépôt et retrait : si le joueur peut au moins
--- faire l'une des deux opérations, le coffre reste visible.
--- @param chest table chest data from cache
--- @return boolean
function ChestBuilder:PlayerCanSeeChest(chest)
    if not chest or not chest.accessName or chest.accessName == "" then
        return true
    end

    local putGrade = tonumber(chest.gradeMinPut) or 0
    local takeGrade = tonumber(chest.gradeMinTake) or 0
    local minGrade = math.min(putGrade, takeGrade)

    if minGrade <= 0 then
        return true
    end

    local job = VFW.PlayerData and VFW.PlayerData.job
    if job and job.name == chest.accessName then
        return (tonumber(job.grade) or 0) >= minGrade
    end

    local faction = VFW.PlayerData and VFW.PlayerData.faction
    if faction and faction.name == chest.accessName then
        return (tonumber(faction.grade) or 0) >= minGrade
    end

    return false
end

--- Get the access permissions and set the chest in the formatted cache
--- @param chests table the list of chests to reformat
function ChestBuilder:ReformatChest(chests)
    if not chests or not next(chests) then
        return
    end

    Wait(5000)

    for i = 1, #chests do
        local chestList <const> = chests[i]

        for _, chestData in pairs(chestList) do
            ChestBuilder.cache[#ChestBuilder.cache + 1] = chestData

            if chestData.accessName and chestData.accessName ~= "" and ChestBuilder:PlayerCanSeeChest(chestData) then
                if not ChestBuilder.blipsCache[chestData.accessName] then
                    ChestBuilder.blipsCache[chestData.accessName] = {}
                end

                if not ChestBuilder.blipsCache[chestData.accessName][chestData.id] then
                    local factionName = VFW.PlayerData and VFW.PlayerData.faction and VFW.PlayerData.faction.name
                    local blipLabel
                    if factionName and chestData.accessName == factionName then
                        blipLabel = VFW.PlayerData.faction.label or chestData.accessName
                    else
                        blipLabel = VFW.PlayerData and VFW.PlayerData.job.label or chestData.accessName
                    end
                    ChestBuilder.blipsCache[chestData.accessName][chestData.id] = {
                        label = blipLabel .. " • Coffre",
                        blips = nil,
                        coords = vector3(chestData.coords.x, chestData.coords.y, chestData.coords.z),
                    }
                end
            end

        end
    end
end

function ChestBuilder:CreateBlips()
    if not next(ChestBuilder.blipsCache) then
        return
    end

    local factionName = VFW.PlayerData and VFW.PlayerData.faction and VFW.PlayerData.faction.name

    for groupName, chests in pairs(ChestBuilder.blipsCache) do
        local isFaction = factionName and groupName == factionName
        for chestId, chest in pairs(chests) do
            ChestBuilder.blipsCache[groupName][chestId].blips = AddBlipForCoord(chest.coords.x, chest.coords.y, chest.coords.z)
            SetBlipSprite(ChestBuilder.blipsCache[groupName][chestId].blips, 568)
            SetBlipScale(ChestBuilder.blipsCache[groupName][chestId].blips, 0.5)
            SetBlipColour(ChestBuilder.blipsCache[groupName][chestId].blips, isFaction and 1 or 3)
            SetBlipAsShortRange(ChestBuilder.blipsCache[groupName][chestId].blips, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(chest.label)
            EndTextCommandSetBlipName(ChestBuilder.blipsCache[groupName][chestId].blips)
        end
    end
end

function ChestBuilder:CreateBlip(chest)
    if not chest.accessName or chest.accessName == "" then
        return
    end
    if not ChestBuilder:PlayerCanSeeChest(chest) then
        return
    end
    if not ChestBuilder.blipsCache[chest.accessName] then
        ChestBuilder.blipsCache[chest.accessName] = {}
    end
    Wait(5000)
    local factionName = VFW.PlayerData and VFW.PlayerData.faction and VFW.PlayerData.faction.name
    local isFaction = factionName and chest.accessName == factionName
    local blipLabel
    if isFaction then
        blipLabel = VFW.PlayerData.faction.label or chest.accessName
    else
        blipLabel = VFW.PlayerData and VFW.PlayerData.job.label or chest.accessLabel or chest.accessName
    end
    ChestBuilder.blipsCache[chest.accessName][chest.id] = {
        label = blipLabel .. " • Coffre",
        blips = nil,
        coords = vector3(chest.coords.x, chest.coords.y, chest.coords.z),
    }

    ChestBuilder.blipsCache[chest.accessName][chest.id].blips = AddBlipForCoord(chest.coords.x, chest.coords.y, chest.coords.z)
    SetBlipSprite(ChestBuilder.blipsCache[chest.accessName][chest.id].blips, 568)
    SetBlipScale(ChestBuilder.blipsCache[chest.accessName][chest.id].blips, 0.5)
    SetBlipColour(ChestBuilder.blipsCache[chest.accessName][chest.id].blips, isFaction and 1 or 3)
    SetBlipAsShortRange(ChestBuilder.blipsCache[chest.accessName][chest.id].blips, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(ChestBuilder.blipsCache[chest.accessName][chest.id].label)
    EndTextCommandSetBlipName(ChestBuilder.blipsCache[chest.accessName][chest.id].blips)
end

function ChestBuilder:RemoveBlipForChest(chest)
    if not chest.accessName or chest.accessName == "" then
        return
    end
    if not ChestBuilder.blipsCache[chest.accessName] then
        return
    end
    if not ChestBuilder.blipsCache[chest.accessName][chest.id] then
        return
    end
    RemoveBlip(ChestBuilder.blipsCache[chest.accessName][chest.id].blips)
    ChestBuilder.blipsCache[chest.accessName][chest.id] = nil
end

--- Recalcule la visibilité de chaque coffre du cache et synchronise les blips.
--- Utilisé après un changement de job/faction ou de grade pour faire (dis)apparaître
--- les blips des coffres dont le grade min vient de changer de statut.
function ChestBuilder:RefreshAllBlips()
    for i = 1, #ChestBuilder.cache do
        local chest = ChestBuilder.cache[i]
        if chest and chest.accessName and chest.accessName ~= "" then
            local hasBlip = ChestBuilder.blipsCache[chest.accessName]
                and ChestBuilder.blipsCache[chest.accessName][chest.id]
                and ChestBuilder.blipsCache[chest.accessName][chest.id].blips

            if ChestBuilder:PlayerCanSeeChest(chest) then
                if not hasBlip then
                    ChestBuilder:CreateBlip(chest)
                end
            else
                if hasBlip then
                    ChestBuilder:RemoveBlipForChest(chest)
                end
            end
        end
    end
end

--- Find a chest zone by its ID
--- @param zoneId number the ID of the zone to find
--- @return table | nil, number | nil
function ChestBuilder:FindZoneById(zoneId)
    for i = 1, #ChestBuilder.cache do
        local chest <const> = ChestBuilder.cache[i]

        if chest.id == zoneId then
            return chest, i
        end
    end
end

function ChestBuilder:OpenChest(id, zonePincode)
    if not zonePincode then
        TriggerServerEvent("chestBuilder:server:openChest", id)
        return
    end

    local pincode <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le pin code du coffre (max 9 chiffres)"))

    if not pincode or pincode <= 0 or #tostring(pincode) > 9 then
        return VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce code PIN n'est pas valide"
        })
    end

    TriggerServerEvent("chestBuilder:server:openChest", id, pincode)
end

function ChestBuilder:DeleteZoneByAccessName(accessName)
    if not accessName or accessName == "" then
        return
    end

    for i = #ChestBuilder.cache, 1, -1 do
        local chest <const> = ChestBuilder.cache[i]

        if chest.accessName == accessName then
            if ChestBuilder.blipsCache[accessName] then
                if ChestBuilder.blipsCache[accessName][chest.id] then
                    RemoveBlip(ChestBuilder.blipsCache[accessName][chest.id].blips)
                    ChestBuilder.blipsCache[accessName][chest.id] = nil
                end
            end
            table.remove(ChestBuilder.cache, i)
        end
    end
end