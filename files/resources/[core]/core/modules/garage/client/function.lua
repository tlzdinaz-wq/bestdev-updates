Garage = {}
Garage.list = {}
Garage.currentGarage = {}
Garage.currentVehicle = {}
Garage.camera = nil
Garage.vehicle = nil
Garage.isOpen = false
Garage.previewVehicle = nil


local markerTypes = {
    ["voiture/moto"] = 36,
    ["bateaux"] = 35,
    ["avion"] = 34
}

local blipNames = {
    "Voiture",
    "Bateau",
    "Avion"
}


function Garage:DrawMarker(coords, type)


    DrawMarker(
        markerTypes[type] or markerTypes[1],
        coords.x, coords.y, coords.z + 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 1.0,
        0, 0, 255, 255,
        false, false, 2, true, nil, false
    )
end

local listNameBlips <const> = {
    public = "Garage Public",
    society = "Garage Société",
    gang = "Garage Gang",
    faction = "Garage Faction",
    private = "Garage Personnel"
}

--- Initialize a garage (blip, ped, etc)
--- @param garage table garage data
function Garage:init(garage)
    if not garage or not garage.id then
        return
    end

    local existing = self.list[garage.id]
    if existing then
        if existing.blip and DoesBlipExist(existing.blip) then
            RemoveBlip(existing.blip)
        end
        if existing.ped and DoesEntityExist(existing.ped) then
            DeleteEntity(existing.ped)
        end
    end

    self.list[garage.id] = garage

    local blipLabel = listNameBlips[garage.type]
    local pedCoords <const> = vector4(garage.position.x, garage.position.y, garage.position.z, garage.position.w or 0.0)

    if (garage.type == "society" or garage.type == "gang" or garage.type == "faction") and garage.access and garage.access.name then
        local accessLabel = garage.access.label or garage.access.name
        blipLabel = ("%s  • Garage - %s"):format(accessLabel, blipNames[tonumber(garage.vehType)] or blipNames[1])
    end

    if garage.type == "public" then
        blipLabel = blipLabel .. (" • %s"):format(blipNames[tonumber(garage.vehType)] or blipNames[1])
    end

    -- Fallback to default vehType if missing
    local vehType = garage.vehType

    -- Determine blip sprite based on vehType
    local blipSprite
    if vehType == 2 then
        blipSprite = 427
    elseif vehType == 3 then
        blipSprite = 359
    elseif garage.type == "public" then
        blipSprite = 830
    else
        blipSprite = 357
    end

    -- Determine ped model based on vehType
    local pedModel
    if vehType == 2 then
        pedModel = "cs_floyd" -- Sailor
    elseif vehType == 3 then
        pedModel = "s_m_m_pilot_01"  -- Pilot
    else
        pedModel = "s_m_y_xmech_01"  -- Mechanic (default)
    end

    garage.blip = Worlds.Blips.Create(garage.position, blipSprite, garage.type ~= "faction" and 26 or 1, 0.5, blipLabel)

    -- Ne pas créer de ped pour les garages faction (marker à la place)
    if garage.type ~= "faction" then
        garage.ped = VFW.CreatePed(pedCoords, pedModel)
        SetEntityCollision(garage.ped, false, false)
    end
end

--- Find a garage by its id
--- @param id number garage id
--- @return table|nil garage, number|nil key (id) of the garage in the list
function Garage:FindGarageById(id)
    if id == nil then return end
    local direct = Garage.list[id] or Garage.list[tonumber(id)] or Garage.list[tostring(id)]
    if direct then
        return direct, direct.id
    end

    for k, garage in pairs(Garage.list) do
        if garage and tonumber(garage.id) == tonumber(id) then
            return garage, k
        end
    end
end


function formatVehiclesLabel(vehicles)
    local formatedVehicle = {}
    for k, v in pairs(vehicles or {}) do
        v.label = Garage.GetVehicleLabel(v.vehName)
        v.name = v.vehName
        table.insert(formatedVehicle, v)
    end
    return formatedVehicle
end

local vehTypeToLabel = {
    "voiture/moto",
    "bateau",
    "avion"
}

--- Open the garage UI
function Garage:Open()
    local privateVehicles = {}
    local societyVehicles = {}

    local garageData, repairPrice <const> = TriggerServerCallback("garage:getGarageData", Garage.currentGarage.id)

    local location = vehTypeToLabel[Garage.currentGarage.vehType]
    if Garage.currentGarage.type == "society" then
        location = "Garage " .. VFW.PlayerData.job.label
    elseif Garage.currentGarage.type == "faction" then
        location = "Garage " .. VFW.PlayerData.faction.label
    end



    SendNUIMessage({
        action = "nui:vehicleStorage:open",
        data = {
            type = Garage.currentGarage.type,
            hasSecondaryGarage = Garage.currentGarage.secondaryGarage,
            location = location,
            privateVehicles =  formatVehiclesLabel(garageData.privateVehicles) or {},
            societyVehicles = formatVehiclesLabel(garageData.groupVehicles) or {},
            gangVehicles = formatVehiclesLabel( garageData.groupVehicles) or{},
            factionVehicles = formatVehiclesLabel( garageData.groupVehicles) or{},
            canManage = garageData.canManage,
            isSocietyStorage = Garage.currentGarage.type == "society",
            isGangStorage = Garage.currentGarage.type == "faction",
            repairPrice = repairPrice
        }
    })

    Garage.isOpen = true
    VFW.Nui.Focus(true, false)
    VFW.Nui.HudVisible(false)
end

--- Remove a garage (blip, ped, etc) by its id
--- @param id number garage id
function Garage:Remove(id)
    local garage, key <const> = Garage:FindGarageById(id)


    if not garage then
        return
    end

    local garageBlip = garage.blip

    if garageBlip and DoesBlipExist(garageBlip) then
        RemoveBlip(garageBlip)
    end

    local garagePed = garage.ped

    if garagePed and DoesEntityExist(garagePed) then
        DeleteEntity(garagePed)
    end

    Garage.list[key] = nil
end

--- Remove all garages (blips, peds, etc)
function Garage.RemoveAll()
    local ids = {}
    for _, garage in pairs(Garage.list) do
        if garage and garage.id then
            ids[#ids + 1] = garage.id
        end
    end
    for i = 1, #ids do
        Garage:Remove(ids[i])
    end
end

--- Close the garage UI
function Garage:Close()
    Garage.isOpen = false
    Garage.previewGeneration = (Garage.previewGeneration or 0) + 1
    Garage:DeletePreview()
    VFW.Nui.Focus(false, false)
    self.currentGarage = {}
    self.currentVehicle = {}
    VFW.Nui.HudVisible(true)
end

function Garage:DeletePreview()
    if Garage.previewVehicle and DoesEntityExist(Garage.previewVehicle) then
        SetEntityAsMissionEntity(Garage.previewVehicle, true, true)
        DeleteEntity(Garage.previewVehicle)
    end
    Garage.previewVehicle = nil
end

local vehicleByType <const> = {
    "tailgater2",
    "dinghy3",
    "velum"
}

--- Function that switches the client to a mode where it chooses a certain position.
---@param sGarageType string Type of garage/storage facility: car | boat | plane
---@return
function Garage:SetExitPoint(vehType)
    local exit = {}
    local vehicleList = {}

    while true do
        VFW.ShowHelpNotification(
            "~INPUT_CONTEXT~ Ajouter une coordonnée ~n~~INPUT_FRONTEND_RRIGHT~ Revenir en arrière ~n~~INPUT_CREATOR_RS~ Annuler le placement des positions ~n~~INPUT_FRONTEND_ACCEPT~ Confirmer les coordonnées")

        if IsControlJustReleased(0, 201) then
            if #exit > 0 then
                Garage:DeleteShowcaseVehicle(vehicleList)
                return exit
            end

            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous devez ajouter au moins une position avant de quitter."
            })
        end

        if VFW.Interact.JustReleased(0, 51) then
            local player <const> = PlayerPedId()
            local playerCoords <const> = GetEntityCoords(player)
            local playerHeading <const> = GetEntityHeading(player)
            local vehicleName <const> = vehicleByType[vehType] or vehicleByType[1]

            local okSpawn, vehicle = pcall(VFW.Game.SpawnVehicle, vehicleName, playerCoords, playerHeading, nil, false)
            if okSpawn and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, true)
                SetEntityCollision(vehicle, false, false)
                SetEntityCompletelyDisableCollision(vehicle, false, false)
                SetEntityAlpha(vehicle, 100)
                vehicleList[#vehicleList + 1] = vehicle
            else
                print(("[garage] aperçu du véhicule impossible (%s), position enregistrée quand même"):format(tostring(vehicle)))
            end

            exit[#exit + 1] = {
                x = playerCoords.x,
                y = playerCoords.y,
                z = playerCoords.z,
                w = playerHeading
            }
        end

        if IsControlJustReleased(0, 194) and #exit > 0 then
            exit[#exit] = nil
            if vehicleList[#vehicleList] then
                DeleteEntity(vehicleList[#vehicleList])
                vehicleList[#vehicleList] = nil
            end
        end

        if IsControlJustReleased(0, 251) then
            Garage:DeleteShowcaseVehicle(vehicleList)
            return {}
        end

        Wait(0)
    end
end

function Garage:DeleteShowcaseVehicle(vehicles)
    for i = 1, #vehicles do
        DeleteEntity(vehicles[i])
    end
end

function Garage:GetAvailableSpawnPosition(spawnCoords)
    if not spawnCoords or not next(spawnCoords) then
        return
    end

    for i = 1, #spawnCoords do
        local spawnPos <const> = spawnCoords[i]
        local vehicle, dist = VFW.Game.GetClosestVehicle(vector3(spawnPos.x, spawnPos.y, spawnPos.z))

        -- Ignorer le véhicule de preview (transparent) pour le calcul de place
        if vehicle == Garage.previewVehicle then
            return spawnPos
        end

        if vehicle == -1 or dist > 2.5 then
            return spawnPos
        end
    end
end

function Garage:DeleteGarageByGroupe(groupName)
    if not Garage.list or not next(Garage.list) then
        return
    end

    local ids = {}
    for _, garage in pairs(Garage.list) do
        if garage and (garage.type == "society" or garage.type == "gang" or garage.type == "faction")
            and garage.access and garage.access.name == groupName then
            ids[#ids + 1] = garage.id
        end
    end
    for i = 1, #ids do
        Garage:Remove(ids[i])
    end
end

