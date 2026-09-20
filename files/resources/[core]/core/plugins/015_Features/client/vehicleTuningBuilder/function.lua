VehicleTuningBuilder = {}
VehicleTuningBuilder.cache = {}

function VehicleTuningBuilder:FindById(id)
    for i = 1, #self.cache do
        if self.cache[i].id == id then
            return self.cache[i], i
        end
    end
end

function VehicleTuningBuilder:Clear()
    self.cache = {}
end

function VehicleTuningBuilder:AddOrUpdate(point)
    local existing, index = self:FindById(point.id)

    if existing then
        self.cache[index] = point
    else
        self.cache[#self.cache + 1] = point
    end
end

function VehicleTuningBuilder:Remove(id)
    local _, index = self:FindById(id)

    if index then
        table.remove(self.cache, index)
    end
end

function VehicleTuningBuilder:IsPlayerReady()
    local ped <const> = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return false, "Vous devez être dans un véhicule."
   end

    local vehicle <const> = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) then
        return false, "Véhicule introuvable."
   end

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return false, "Vous devez être au volant."
   end

    return true, vehicle
end

-- VUI Menu for player extra véhicule
local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/extraveh.png")

local extraVehMenu = VUI:CreateMenu("EXTRA VÉHICULE", defaultBanner, true)
local extraVehPerf = VUI:CreateSubMenu(extraVehMenu, "PERFORMANCE", defaultBanner, true)
local extraVehExtras = VUI:CreateSubMenu(extraVehMenu, "EXTRAS", defaultBanner, true)
local extraVehDivers = VUI:CreateSubMenu(extraVehMenu, "DIVERS", defaultBanner, true)

local extraVehVehicle = nil
local extraVehMenuPoint = nil

local performanceIndices = {
    { index = 11, name = "Moteur" },
    { index = 12, name = "Freins" },
    { index = 13, name = "Transmission" },
    { index = 15, name = "Suspension" },
}

local function getModLabel(vehicle, modType, modIndex)
    if modIndex < 0 then return "Stock" end
    local label = GetLabelText(GetModTextLabel(vehicle, modType, modIndex))
    if label == "NULL" then
        return "Mod " .. (modIndex + 1)
    end
    return label
end

-- Main menu
extraVehMenu.OnOpen(function()
    extraVehMenu.ClearItems()
    local vehicle = extraVehVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local modelHash = GetEntityModel(vehicle)
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
    if vehicleName == "NULL" then
        vehicleName = GetDisplayNameFromVehicleModel(modelHash)
    end

    extraVehMenu.Title(vehicleName, VFW.Math.Trim(GetVehicleNumberPlateText(vehicle)))

    extraVehMenu.Button(":bolt: PERFORMANCE", "Moteur, freins, transmission, suspension, turbo", nil, "chevron", false, function() end, extraVehPerf)
    extraVehMenu.Button(":wrench: EXTRAS", "Activer ou désactiver les extras visuels", nil, "chevron", false, function() end, extraVehExtras)
    extraVehMenu.Button(":palette: DIVERS", "Livrées et options diverses", nil, "chevron", false, function() end, extraVehDivers)
end)

-- Performance submenu (sans blindage)
extraVehPerf.OnOpen(function()
    extraVehPerf.ClearItems()
    local vehicle = extraVehVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    SetVehicleModKit(vehicle, 0)

    extraVehPerf.Button(":rocket: TOUT AU MAXIMUM", nil, nil, "arrow", false, function()
        SetVehicleModKit(vehicle, 0)
        for _, perf in ipairs(performanceIndices) do
            local max = GetNumVehicleMods(vehicle, perf.index) - 1
            if max >= 0 then
                SetVehicleMod(vehicle, perf.index, max, false)
            end
        end
        ToggleVehicleMod(vehicle, 18, true)
        VFW.ShowNotification({ type = "VERT", content = "Performance au maximum." })
        extraVehPerf.refresh()
    end)

    extraVehPerf.Separator("COMPOSANTS")

    for _, perf in ipairs(performanceIndices) do
        local numMods = GetNumVehicleMods(vehicle, perf.index)
        if numMods > 0 then
            local currentMod = GetVehicleMod(vehicle, perf.index)
            local items = { "Stock" }
            for i = 0, numMods - 1 do
                local label = getModLabel(vehicle, perf.index, i)
                table.insert(items, label)
            end
            local currentIdx = currentMod + 2
            extraVehPerf.List(perf.name, nil, false, items, currentIdx, function(idx)
                if idx == 1 then
                    SetVehicleMod(vehicle, perf.index, -1, false)
                else
                    SetVehicleMod(vehicle, perf.index, idx - 2, false)
                end
            end)
        end
    end

    local hasTurbo = IsToggleModOn(vehicle, 18)
    extraVehPerf.Checkbox("Turbo", nil, false, hasTurbo, function(checked)
        ToggleVehicleMod(vehicle, 18, checked)
    end)
end)

-- Extras submenu
extraVehExtras.OnOpen(function()
    extraVehExtras.ClearItems()
    local vehicle = extraVehVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local hasExtras = false
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            hasExtras = true
            local enabled = IsVehicleExtraTurnedOn(vehicle, i)
            extraVehExtras.Checkbox("Extra " .. i, nil, false, enabled, function(checked)
                SetVehicleExtra(vehicle, i, not checked)
            end)
        end
    end

    if not hasExtras then
        extraVehExtras.Separator("Aucun extra disponible")
    end
end)

-- Divers submenu (livrées)
extraVehDivers.OnOpen(function()
    extraVehDivers.ClearItems()
    local vehicle = extraVehVehicle
    if not vehicle or not DoesEntityExist(vehicle) then return end

    SetVehicleModKit(vehicle, 0)

    extraVehDivers.Separator("LIVRÉES")

    local liveryCount = GetVehicleLiveryCount(vehicle)
    local modLiveryCount = GetNumVehicleMods(vehicle, 48)

    if liveryCount > 0 then
        local currentLivery = GetVehicleLivery(vehicle)
        local liveryItems = { "Aucune" }
        for i = 0, liveryCount - 1 do
            local name = GetLabelText(GetLiveryName(vehicle, i))
            if name == "NULL" then name = "Motif " .. (i + 1) end
            table.insert(liveryItems, name)
        end
        extraVehDivers.List("Livrée", nil, false, liveryItems, (currentLivery or -1) + 2, function(idx)
            if idx == 1 then
                SetVehicleLivery(vehicle, -1)
            else
                SetVehicleLivery(vehicle, idx - 2)
            end
        end)
    elseif modLiveryCount > 0 then
        local currentModLivery = GetVehicleMod(vehicle, 48)
        local modLiveryItems = { "Aucune" }
        for i = 0, modLiveryCount - 1 do
            local name = GetLabelText(GetModTextLabel(vehicle, 48, i))
            if name == "NULL" then name = "Motif " .. (i + 1) end
            table.insert(modLiveryItems, name)
        end
        extraVehDivers.List("Livrée (mod)", nil, false, modLiveryItems, (currentModLivery or -1) + 2, function(idx)
            if idx == 1 then
                SetVehicleMod(vehicle, 48, -1, false)
            else
                SetVehicleMod(vehicle, 48, idx - 2, false)
            end
        end)
    else
        extraVehDivers.Separator("Aucune livrée disponible")
    end

    extraVehDivers.Separator("OPTIONS")

    local hasXenon = IsToggleModOn(vehicle, 22)
    extraVehDivers.Checkbox("Phares Xenon", nil, false, hasXenon, function(checked)
        ToggleVehicleMod(vehicle, 22, checked)
    end)
end)

function VehicleTuningBuilder:OpenMenu(point)
    local ready, vehicleOrMessage = self:IsPlayerReady()

    if not ready then
        VFW.ShowNotification({
            type = "ROUGE",
            content = vehicleOrMessage
        })
        return
    end

    if not VFW.PlayerData.job or VFW.PlayerData.job.name ~= point.jobRequired then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous n'avez pas le bon job."
       })
        return
    end

    if point.gradeMin and point.gradeMin > 0 then
        local grade <const> = VFW.PlayerData.job.grade or 0

        if grade < point.gradeMin then
            VFW.ShowNotification({
                type = "ROUGE",
                content = "Grade insuffisant."
           })
            return
        end
    end

    extraVehVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    SetVehicleModKit(extraVehVehicle, 0)
    extraVehMenuPoint = point
    extraVehMenu.open()
end

-- Anti-bug: close menu if player moves too far from the point
CreateThread(function()
    while true do
        Wait(1000)

        if extraVehMenuPoint then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pointCoords = vector3(extraVehMenuPoint.coords.x, extraVehMenuPoint.coords.y, extraVehMenuPoint.coords.z)

            if #(playerCoords - pointCoords) > 8.0 then
                extraVehMenu.close()
                extraVehVehicle = nil
                extraVehMenuPoint = nil
            end
        end
    end
end)
