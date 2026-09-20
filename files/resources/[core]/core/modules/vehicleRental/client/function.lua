tVehicleRental = tVehicleRental or {}

--- Function to open the vehicle rental menu
--- @param iType number rental type
function tVehicleRental:OpenCarRentalMenu(iType)
    local tActiveRental = TriggerServerCallback("core:vehicleRental:getActiveRental", iType)

    SendNUIMessage({
        action = 'nui:visible',
        data = true
    })

    Wait(100)

    local type = {
        'vehicle',
        'boat',
        'cayo',
    }

    local tVehicleData <const> = self.tVehicleConfig[iType]

    local freshAccounts = TriggerServerCallback("core:vehicleRental:getPlayerAccounts")
    local iMoney = freshAccounts and freshAccounts.cash or (VFW.PlayerData.money or 0)
    local iBank = freshAccounts and freshAccounts.bank or 0

    SendNUIMessage({
        action = 'nui:vehicleRental:open',
        data = {
            vehicles = tVehicleData,
            remainingTime = 3600000,
            type = type[iType],
            activeRental = tActiveRental,
            money = iMoney,
            bank = iBank,
        },
    })

    VFW.Nui.Focus(true, false)
end

--- Function to close the vehicle rental menu
function tVehicleRental:CloseNui()
    VFW.Nui.Focus(false, false)
end

--- Function to get rental data by ID
--- @param iId number rental ID
--- @return table|nil, number|nil (rental data or nil if not found, index in the list or nil)
function tVehicleRental:GetRentalData(iId)
    for i = 1, #self.List do
        local tData <const> = self.List[i]
        if tData?.iId == iId then
            return tData, i
        end
    end

    return nil
end

--- Function to create a vehicle rental point
--- @param tData table rental data
function tVehicleRental:Create(tData)
    local tBlip <const> = self.Blip[tData.iType] or self.Blip[1]
    tData.ePed = VFW.CreatePed(tData.tPos, tData.sPedModel)
    tData.oBlip = VFW.CreateBlipInternal(tData.tPos, tBlip.sprite, tBlip.color, tBlip.scale, tBlip.name)
end

--- Function to initialize all vehicle rental points
function tVehicleRental:Init()
    for i = 1, #self.List do
        local tRentalData <const> = self.List[i]
        if not tRentalData then goto continue end

        self:Create(tRentalData)

        ::continue::
    end
end

--- Function to delete a vehicle rental point by ID
--- @param iId number rental ID
function tVehicleRental:Delete(iId)
    for i = 1, #self.List do
        local tRentalData <const> = self.List[i]
        if tRentalData?.iId ~= iId then goto continue end

        local ePed <const> = tRentalData.ePed
        if ePed and DoesEntityExist(ePed) then
            DeleteEntity(ePed)
        end

        local oBlip <const> = tRentalData.oBlip
        if oBlip and DoesBlipExist(oBlip) then
            RemoveBlip(oBlip)
        end

        self.List[i] = nil

        ::continue::
    end
end

--- Function to delete all vehicle rental points
function tVehicleRental:DeleteAll()
    for i = #self.List, 1, -1 do
        self:Delete(self.List[i].iId)
    end
end
