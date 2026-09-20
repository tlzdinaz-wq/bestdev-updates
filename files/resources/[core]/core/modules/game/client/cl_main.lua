---@meta _
---@diagnostic disable: duplicate-doc-field

-- Actions table to hold all action-related functions and variables
---@class Actions
---@field _index any
---@field inVehicle any
---@field enteringVehicle any
---@field inPauseMenu any
---@field currentWeapon any
Actions = {}
Actions._index = Actions

Actions.inVehicle = false -- Boolean to track if the player is in a vehicle
Actions.enteringVehicle = false -- Boolean to track if the player is entering a vehicle
Actions.inPauseMenu = false -- Boolean to track if the pause menu is active
Actions.currentWeapon = false -- Variable to store the current weapon of the player

--- Get the seat the player is in within the vehicle
-- @return number The seat index the player is in, or -1 if not found
function Actions:GetSeatPedIsIn()
    for i = -1, 16 do
        if GetPedInVehicleSeat(self.vehicle, i) == VFW.PlayerData.ped then
            return i
        end
    end

    return -1
end

--- Get data about the current vehicle
-- @return string, number, string The display name, network ID, and plate of the vehicle
function Actions:GetVehicleData()
    if not self.vehicle or not DoesEntityExist(self.vehicle) then
        return "null", 0, "null"
    end

    local vehicleModel = GetEntityModel(self.vehicle)
    local displayName = GetEntityArchetypeName(self.vehicle)
    local netId = NetworkGetEntityIsNetworked(self.vehicle) and
                      VehToNet(self.vehicle) or 0
    local plate = GetVehicleNumberPlateText(self.vehicle)

    return displayName, netId, plate
end

--- Set the vehicle status in the player data
function Actions:SetVehicleStatus()
    VFW.SetPlayerData("vehicle", self.vehicle)
    VFW.SetPlayerData("seat", self.seat)
end

--- Track the player's coordinates and update the player data
function Actions:TrackPedCoords()
    local playerPed = VFW.PlayerData.ped
    local coords = GetEntityCoords(playerPed)

    VFW.SetPlayerData("coords", coords)
end

--- Track the player's ped and update the player data if it changes
function Actions:TrackPed()
    local playerPed = VFW.PlayerData.ped
    local newPed = PlayerPedId()

    if playerPed ~= newPed then
        VFW.SetPlayerData("ped", newPed)

        TriggerEvent("vfw:playerPedChanged", newPed)
    end
end

--- Track the pause menu status and trigger events if it changes
function Actions:TrackPauseMenu()
    local isActive = IsPauseMenuActive()

    if isActive ~= self.inPauseMenu then
        self.inPauseMenu = isActive
        TriggerEvent("vfw:pauseMenuActive", isActive)
    end
end

--- Handle the player entering a vehicle
function Actions:EnterVehicle()
    self.seat = GetSeatPedIsTryingToEnter(VFW.PlayerData.ped)

    local _, netId, plate = self:GetVehicleData()

    self.enteringVehicle = true
    TriggerEvent("vfw:enteringVehicle", self.vehicle, plate, self.seat, netId)
    TriggerServerEvent("vfw:enteringVehicle", plate, self.seat, netId)

    self:SetVehicleStatus()
end

--- Reset the vehicle data to default values
function Actions:ResetVehicleData()
    self.enteringVehicle = false
    self.vehicle = false
    self.seat = false
    self.inVehicle = false

    self:SetVehicleStatus()
end

--- Handle the player aborting vehicle entry
function Actions:EnterAborted()
    self:ResetVehicleData()

    TriggerEvent("vfw:enteringVehicleAborted")
    TriggerServerEvent("vfw:enteringVehicleAborted")
end

--- Handle the player warping into a vehicle
function Actions:WarpEnter()
    self.enteringVehicle = false
    self.inVehicle = true

    self.seat = self:GetSeatPedIsIn()

    local displayName, netId, plate = self:GetVehicleData()

    self:SetVehicleStatus()
    TriggerEvent("vfw:enteredVehicle", self.vehicle, plate, self.seat,
                 displayName, netId)
    TriggerServerEvent("vfw:enteredVehicle", plate, self.seat, displayName,
                       netId)
end

--- Handle the player exiting a vehicle
function Actions:ExitVehicle()
    local currentVehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)

    if currentVehicle ~= self.vehicle or VFW.PlayerData.dead then
        local displayName, netId, plate = self:GetVehicleData()

        TriggerEvent("vfw:exitedVehicle", self.vehicle, plate, self.seat, displayName, netId)
        TriggerServerEvent("vfw:exitedVehicle", plate, self.seat, displayName, netId)

        self:ResetVehicleData()
    end
end

--- Track the vehicle the player is interacting with
function Actions:TrackVehicle()
    if not self.inVehicle and not VFW.PlayerData.dead then
        local tempVehicle = GetVehiclePedIsTryingToEnter(VFW.PlayerData.ped)

        if DoesEntityExist(tempVehicle) and not self.enteringVehicle then
            self.vehicle = tempVehicle
            self:EnterVehicle()
        elseif not DoesEntityExist(tempVehicle) and
            not IsPedInAnyVehicle(VFW.PlayerData.ped, true) and
            self.enteringVehicle then
            self:EnterAborted()
        elseif IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
            self.vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
            self:WarpEnter()
        end
    elseif self.inVehicle then
        self:ExitVehicle()
        self:TrackSeat()
    end
end

--- Track the seat the player is in within the vehicle
function Actions:TrackSeat()
    if not self.inVehicle then
        return
    end

    local newSeat = self:GetSeatPedIsIn()
    if newSeat ~= self.seat then
        self.seat = newSeat
        VFW.SetPlayerData("seat", self.seat)
        TriggerEvent("vfw:vehicleSeatChanged", self.seat)
    end
end

--- Track the weapon the player is holding and update the player data
function Actions:TrackWeapon()
    ---@type number|false
    local newWeapon = GetSelectedPedWeapon(VFW.PlayerData.ped)
    newWeapon = newWeapon ~= joaat('WEAPON_UNARMED') and newWeapon or false

    if newWeapon ~= self.currentWeapon then
        self.currentWeapon = newWeapon
        VFW.SetPlayerData("weapon", self.currentWeapon)

        if not self.currentWeapon then
            TriggerEvent("vfw:weaponChanged")
        end
    end
end

function Actions:Init()
    CreateThread(function()
        while VFW.PlayerLoaded do
            self:TrackPed()
            self:TrackPedCoords()
            self:TrackPauseMenu()
            self:TrackVehicle()
            self:TrackWeapon()
            Wait(500)
        end
    end)
end
