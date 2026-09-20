Doorlock = {}
Doorlock.cache = {}
Doorlock.motelDoorlockIds = {}

--- Sync the doorlock cache from the server
function Doorlock:SyncServerCache()
    local doors <const> = TriggerServerCallback("doorlock:getAllDoorlock")

    if not doors or not next(doors) then
        return
    end

    Doorlock:ReformatDoorlock(doors)
end

--- Reformat the doorlock data received from the server
--- @param doors table the doorlock data
function Doorlock:ReformatDoorlock(doors)
    for _, doorlock in pairs(doors) do
        self.cache[#self.cache + 1] = doorlock
        self:CreateDoorLock(doorlock.doorsData, doorlock.id)
    end
end

--- Find a doorlock by its ID
--- @param id number the ID of the doorlock
--- @return number | nil
function Doorlock:FindDoorlockById(id)
    for i = 1, #self.cache do
        local doorlock <const> = self.cache[i]

        if doorlock.id == id then
            return i, doorlock
        end
    end
end

--- Interact with a door (open/close)
---@param doorlockId number the ID of the doorlock
function Doorlock:InteractWithDoor(doorlockId, doorsData, access, pincode)
    local state <const> = DoorSystemGetDoorState(doorsData[1].hash)

    if state == 0 then
        return self:CloseDoor(doorlockId, access, pincode)
    else
        return self:OpenDoor(doorlockId, access, pincode)
    end
end

--- Close a door
--- @param doorlockId number the ID of the doorlock
function Doorlock:CloseDoor(doorlockId, access, pincode)
    if not access and not pincode then
        TriggerServerEvent("doorlock:server:toggleDoor", 1, doorlockId)
        return true
    end

    if not self:CanInteractWithDoor(doorlockId, access, pincode) then
        return false
    end

    TriggerServerEvent("doorlock:server:toggleDoor", 1, doorlockId, access, pincode)
    return true
end

--- Open a door if the player has access or the correct pincode
--- @param doorlockId number the ID of the doorlock
--- @param access table the access permissions
--- @param pincode number the pincode
function Doorlock:OpenDoor(doorlockId, access, pincode)
    if not access and not pincode then
        TriggerServerEvent("doorlock:server:toggleDoor", 0, doorlockId)
        return true
    end

    if not self:CanInteractWithDoor(doorlockId, access, pincode) then
        return false
    end

    TriggerServerEvent("doorlock:server:toggleDoor", 0, doorlockId, access, pincode)
    return true
end

--- Convert rotation to direction
--- @param rotation table the rotation
--- @return table the direction
function Doorlock:RotationToDirection(rotation)
	local adjustedRotation <const> = {
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}

	local direction <const> = {
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}

	return direction
end

--- Raycast from the gameplay camera
--- @param distance number the distance of the raycast
--- @return boolean, vector3, entity hit, hit coords, hit entity
function Doorlock:RayCastGamePlayCamera(distance)
    local cameraRotation <const> = GetGameplayCamRot()
	local cameraCoord <const> = GetGameplayCamCoord()
	local direction <const> = self:RotationToDirection(cameraRotation)

	local destination <const> = {
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}

	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end

--- Select doors for a doorlock
--- @param doorlockData table the existing doors data to reselect doors
--- @return table | nil, vector3 | nil the selected doors and the mid coords if
function Doorlock:SelectDoorlock(doorlockData)
    local doors = doorlockData or {}

    for i = 1, #doors do
        local door = doors[i]
        SetEntityDrawOutline(door.entity, true)
    end

    local doors = self:StartSelectDoorlock(doors)

    if not doors or not next(doors) then
        return
    end

    local formattedDoors <const>, midCoords <const> = self:ReformatSelectedDoors(doors)

    return formattedDoors, midCoords
end

--- Start the doorlock selection process
function Doorlock:StartSelectDoorlock()
    local currentEntity
    local doorNumber = 0
    local doors = {}

    while true do
        VFW.ShowHelpNotification("~INPUT_CONTEXT~ Ajouter une porte ~n~~INPUT_FRONTEND_RRIGHT~ Annuler la création du doorlock ~n~~INPUT_CREATOR_RS~ Retirer la dernière porte porte ~n~~INPUT_FRONTEND_ACCEPT~ Valider le doorlock")

        if currentEntity and not doors[currentEntity] then
            SetEntityDrawOutline(currentEntity, false)
        end

        local hit, coords, entity = self:RayCastGamePlayCamera(15.0)

        if not DoesEntityExist(entity) then
            goto skip
        end

        currentEntity = entity
        SetEntityDrawOutline(currentEntity, true)

        if IsControlJustPressed(0, 201) then
            if next(doors) then
                self:RemoveOutline(doors, currentEntity)
                return doors
            end

            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous devez sélectionner au moins une porte pour créer un doorlock."
            })
        end

        if VFW.Interact.JustPressed(0, 51) then
            if doorNumber == 2 then
                goto skipInsert
            end

            local model = GetEntityModel(entity)
            if model == 0 then
                goto skipInsert
            end

            doorNumber += 1
            doors[entity] = {
                model = model,
                coords = GetEntityCoords(entity),
                heading = GetEntityHeading(entity)
            }

            ::skipInsert::
        end

        if IsControlJustPressed(0, 194) then
            self:RemoveOutline(doors, currentEntity)
            return
        end

        if IsControlJustPressed(0, 251) then
            doorNumber -= 1
            self:RemoveLastIndex(doors)
        end

        ::skip::

        Wait(0)
    end
end

--- Remove the outline from the selected doors
--- @param doors table the selected doors
--- @param currentEntity entity the current entity
function Doorlock:RemoveOutline(doors, currentEntity)
    if not doors or not next(doors) then
        return
    end

    if currentEntity then
        SetEntityDrawOutline(currentEntity, false)
    end

    for entity, _ in pairs(doors) do
        SetEntityDrawOutline(entity, false)
    end
end

--- Remove the last index from an indexed table
--- @param doors table the indexed table
function Doorlock:RemoveLastIndex(table)
    if not table or not next(table) then
        return VFW.ShowNotification({
            type = 'ROUGE',
            content = "Aucune porte à retirer"
        })
    end

    local lastKey = nil
    
    for key, value in pairs(table) do
        lastKey = key
    end
    
    if lastKey ~= nil then
        SetEntityDrawOutline(lastKey, false)
        table[lastKey] = nil
    end
end

--- Reformat the selected doors into an indexed table and get the mid coords if there is two doors
--- @param doors table the selected doors
--- @return vector3 | nil, table the mid coords and the formatted doors
function Doorlock:ReformatSelectedDoors(doors)
    local formattedDoors = {}

    for entity, data in pairs(doors) do
        formattedDoors[#formattedDoors + 1] = data
    end

    if #formattedDoors < 2 then
        return formattedDoors
    end

    local midCoords <const> = self:GetCoordsBetweenTwoPoints(formattedDoors[1].coords, formattedDoors[2].coords)

    return formattedDoors, midCoords
end

--- Get the coordinates between two points
--- @param coords1 vector3 the first coordinates
--- @param coords2 vector3 the second coordinates
--- @return table the mid coordinates
function Doorlock:GetCoordsBetweenTwoPoints(coords1, coords2)
    return {
        x = (coords1.x + coords2.x) / 2,
        y = (coords1.y + coords2.y) / 2,
        z = (coords1.z + coords2.z) / 2
    }
end

--- Create a door lock in the game world
--- @param doors table the doors data
--- @param doorlockId number the ID of the doorlock
function Doorlock:CreateDoorLock(doors, doorlockId)
    if not doors or not next(doors) then
        return
    end

    local index <const>, doorlock <const> = self:FindDoorlockById(doorlockId)

    doorlock.isLocked = true

    for i = 1, #doors do
        local door <const> = doors[i]
        local doorHash <const> = ("doorlock_%s_%s"):format(doorlockId, i)
        door.hash = doorHash

        AddDoorToSystem(doorHash, door.model, door.coords.x, door.coords.y, door.coords.z, false, false, false)
        DoorSystemSetDoorState(doorHash, 1, false, false)
        DoorSystemSetAutomaticRate(doorHash, 10.0, false, false)
    end
end

--- Check if the player can interact with the door (access or pincode)
--- @param doorlockId number the doorlock ID
--- @param access table the access permissions
--- @param pincode number the pincode
function Doorlock:CanInteractWithDoor(doorlockId, access, pincode)
    local hasAccess <const> = self:CheckAccess(access)

    if access and not hasAccess then
        return
    end

    local hasValidPincode <const> = self:CheckPinCode(doorlockId, pincode)

    if pincode and not hasValidPincode then
        return
    end

    return true
end

--- Check if the player has a key item for this doorlock (motel key auto-unlock)
--- @param doorlockId number the doorlock ID
--- @return number|nil the pincode from the key if found
function Doorlock:FindKeyForDoorlock(doorlockId)
    if not doorlockId or not VFW.PlayerData.inventory then
        return
    end

    for _, item in ipairs(VFW.PlayerData.inventory) do
        if item.name == "key_motel" and item.meta and item.meta.pincode then
            -- Support doorlockIds array (new format)
            if item.meta.doorlockIds then
                for _, id in ipairs(item.meta.doorlockIds) do
                    if id == doorlockId then
                        return item.meta.pincode
                    end
                end
            -- Legacy: single doorlockId
            elseif item.meta.doorlockId == doorlockId then
                return item.meta.pincode
            end
        end
    end
end

--- Check if the entered pincode is correct
--- @param doorlockId number the doorlock ID
--- @param pincode number the pincode
--- @return boolean | nil
function Doorlock:CheckPinCode(doorlockId, pincode)
    if not pincode or pincode <= 0 then
        return
    end

    -- Auto-unlock if player has a key item for this doorlock (motel key)
    local keyPincode <const> = self:FindKeyForDoorlock(doorlockId)
    if keyPincode and keyPincode == pincode then
        return true
    end

    -- Motel door without key: block access
    if self.motelDoorlockIds and self.motelDoorlockIds[doorlockId] then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas les clés de cette chambre"
        })
        return
    end

    -- Fallback: ask for manual pincode entry (non-motel doorlocks)
    local pincodeEntry <const> = tonumber(VFW.Nui.KeyboardInput(true, "Entrer le pincode du doorlock"))

    if not pincodeEntry or pincodeEntry <= 0 or pincodeEntry ~= pincode then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Ce code PIN n'est pas valide"
        })
        return
    end

    return true
end

--- Check if the player has access to the doorlock
--- @param access table the access permissions
--- @return boolean | nil
function Doorlock:CheckAccess(access)
    if not access or not next(access) then
        return
    end

    local playerJob <const> = VFW.PlayerData.job

    if not playerJob then
        return
    end

    for i = 1, #access do
        local job <const> = access[i]

        if job.name == playerJob.name and playerJob.grade >= job.grade then
            return true
        end
    end

    VFW.ShowNotification({
        type = 'ROUGE',
        content = "Vous n'avez pas accès à ce doorlock"
    })
end

--- Remove doors from the game world
--- @param doorsData table the doors data
function Doorlock:RemoveDoor(doorsData)
    if not doorsData or not next(doorsData) then
        return
    end

    for i = 1, #doorsData do
        local door <const> = doorsData[i]
        local doorHash <const> = door.hash

        print("Removing door with hash: " .. tostring(doorHash))

        RemoveDoorFromSystem(doorHash)
    end
end

--- Draw 3D text in the game world
--- @param x number the x coordinate
--- @param y number the y coordinate
--- @param z number the z coordinate
--- @param text string the text to draw
function Doorlock:DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.50, 0.50)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end