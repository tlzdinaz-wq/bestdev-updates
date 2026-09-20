---@meta _
---@diagnostic disable: duplicate-doc-field

--- .Factions.SendGestionData
function VFW.Factions.SendGestionData()
    local sendTable = {}
    local newFactions = TriggerServerCallback("core:factions:getNewOrganizations")

    -- Traitement des nouvelles factions
    local nbr = 0

    for k, v in pairs(newFactions or {}) do
        nbr += 1
        sendTable[nbr] = {
            id = nbr,
            name = v.name,
            started = false,
            moto = v.devise,
            lead = v.creator or "?",
            level = 0,
            image = v.image,
            experience = 0,
            color = v.color,
            type = v.hierarchie and VFW.Factions.crew.TypesFromHierarchy[v.hierarchie] or "normal",
            posLaboratory = v.posLaboratory or { x = 0, y = 0, z = 0 },
            posCraft = v.posCraft or { x = 0, y = 0, z = 0 },
            posStockage = v.posStockage or { x = 0, y = 0, z = 0 },
            posGarage = v.posGarage or { x = 0, y = 0, z = 0 },
---@class members
            members = {},
---@class vehicles
            vehicles = {},
---@class territories
            territories = {},
---@class properties
            properties = {},
---@class shops
            shops = {}
        }
    end

    local faction = TriggerServerCallback("core:factions:getOrganizations")

    local nbr2 = nbr

    for k, v in pairs(faction) do

        console.debug("Liste des membres de la faction ", json.encode(v.members, { indent = true }))
        nbr2 += 1
        sendTable[nbr2] = {
            id = nbr2,
            name = v.name,
            started = true,
            moto = v.devise,
            image = v.image or "",
            lead = v.creator or "Aucun",
            color = v.color,
            type = v.type,
            experience = tonumber(v.xp) or 0,
            level = 4,
            posLaboratory = v.posLaboratory or { x = 0, y = 0, z = 0 },
            posCraft = v.posCraft or { x = 0, y = 0, z = 0 },
            posStockage = v.posStockage or { x = 0, y = 0, z = 0 },
            posGarage = v.posGarage or { x = 0, y = 0, z = 0 },
            members = v.members or {},
            vehicles = v.vehicles or {},
            territories = v.territories or {},
            properties = v.properties or {},
            shops = v.shops or {}
        }
    end

    local sendTableXP = {
        {
            rang = "D",
            xp = 0,
        },
        {
            rang = "C",
            xp = 2500,
        },
        {
            rang = "B",
            xp = 7500,
        },
        {
            rang = "A",
            xp = 15000,
        },
        {
            rang = "S",
            xp = 30000,
        },
    }

    console.debug("Send crews to front")
    --console.debug(json.encode(sendTable, { indent = true }))
    SendNUIMessage({
        action = "nui:server-gestion-crews:setCrews",
        data = sendTable
    })
    SendNUIMessage({
        action = "nui:server-gestion-illegal:sendTabletXP",
        data = sendTableXP
    })
end

RegisterNuiCallback("nui:server-gestion-crew:getPos", function(_, cb)
    console.debug("pos", GetEntityCoords(VFW.PlayerData.ped))
    cb({pos = json.encode(GetEntityCoords(VFW.PlayerData.ped))})
end)

RegisterNuiCallback("nui:server-gestion-compagnies:wipe", function(data)
    console.debug(json.encode(data))
end)

RegisterNuiCallback("nui:server-gestion-crews:addMember", function(data, cb)
    console.debug("add member", json.encode(data))
    local isAdd = TriggerServerCallback("core:gestion-factions:addMember", data)

    cb(isAdd)
end)

RegisterNuiCallback("nui:server-gestion-crews:addVehicle", function(data, cb)
    console.debug("add vehicle", json.encode(data))
    local vehicle = data.vehicle
    if not IsModelValid(vehicle) then
        cb({state = false})
    end

    local isAdd = TriggerServerCallback("core:gestion-factions:addVehicle", data)
    cb(isAdd)
end)

RegisterNuiCallback("nui:server-gestion-crews:start", function(data)
    console.debug(json.encode(data))
    TriggerServerEvent("core:gestion-factions:start", data)
end)

RegisterNuiCallback("nui:server-gestion-crews:save", function(data)
    console.debug("data ", json.encode(data, {indent = true}))
    TriggerServerEvent("core:gestion-factions:save", data, VFW.Factions.crew.TypesFromHierarchy[data.hierarchie])
end)

RegisterNUICallback("nui:server-gestion-crews:wipe", function(data)
    console.debug("nui:server-gestion-crews:wipe", json.encode(data, {indent =true}))
    TriggerServerEvent("core:gestion-factions:delete", data, "wipe")
end)

RegisterNUICallback("nui:server-gestion-crews:delete", function(data)
    console.debug("nui:server-gestion-crews:delete", json.encode(data, {indent =true}))
    TriggerServerEvent("core:gestion-factions:delete", data, "delete")
end)

RegisterNuiCallback("nui:server-gestion-crews:join", function(data)
    TriggerServerEvent("core:gestion-factions:join", data)
end)

if Config.EnableDebug then
    RegisterCommand("valideCrew", function(source, args)
        TriggerServerEvent("core:gestion-factions:start", args[1])
    end)
end

---@param name string
RegisterNetEvent("core:faction:deleteFaction", function(name)
    if VFW.PlayerData.faction.name == name then
        VFW.PlayerData.faction.name = "nofaction"
      VFW.PlayerData.faction.grade = 0
        VFW.PlayerData.faction.label = "Aucune faction"
  end
end)
