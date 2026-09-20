ZoneSafe = {}
ZoneSafe.cache = {}

function ZoneSafe:IsPointInPolygon(points, x, y)
    if not points or #points < 3 then
        return false
    end

    local inZone = false
    local j = #points

    for i = 1, #points do
        local pi = points[i]
        local pj = points[j]

        if pi and pj then
            if ((pi.y < y and pj.y >= y) or (pj.y < y and pi.y >= y)) and (pi.x <= x or pj.x <= x) then
                if pi.x + (y - pi.y) / (pj.y - pi.y) * (pj.x - pi.x) < x then
                    inZone = not inZone
                end
            end
        end

        j = i
    end

    return inZone
end

function ZoneSafe:GetPolygonCenter(points)
    if not points or #points == 0 then
        return vector3(0, 0, 0)
    end

    local totalX, totalY, totalZ = 0, 0, 0

    for i = 1, #points do
        local point = points[i]
        totalX = totalX + point.x
        totalY = totalY + point.y
        totalZ = totalZ + (point.z or 0)
    end

    return vector3(totalX / #points, totalY / #points, totalZ / #points)
end

function ZoneSafe:GetPolygonRadius(points, center)
    if not points or #points == 0 then
        return 0
    end

    local maxDist = 0

    for i = 1, #points do
        local point = points[i]
        local dist = #(vector2(point.x, point.y) - vector2(center.x, center.y))
        if dist > maxDist then
            maxDist = dist
        end
    end

    return maxDist
end

function ZoneSafe:HasWeaponRestriction(zone)
    if not zone or not zone.actionDisabled then
        return false
    end

    for i = 1, #zone.actionDisabled do
        if zone.actionDisabled[i] == 45 then
            return true
        end
    end

    return false
end

function ZoneSafe:EnteredOnZone(zone)
    if zone.playerInZone then
        return
    end

    zone.playerInZone = true

    local isBypass <const> = self:GetPlayerJobIsByPass(zone.bypassJob)

    if VFW.SetSafeZone then
        VFW.SetSafeZone(true, isBypass)
    end

    SendNUIMessage({
        action = 'nui:safezone:visible',
        data = {
            visible = true
        }
    })

    if self:HasWeaponRestriction(zone) and not isBypass then
        TriggerServerEvent('zonesafe:server:forceHolster')
    end
end

function ZoneSafe:ExitedZone(zone)
    if not zone.playerInZone then
        return
    end

    zone.playerInZone = false

    self:ResetSpecialActions()

    -- Check if still in any other zone before syncing with legacy system
    local stillInZone = false
    for i = 1, #self.cache do
        if self.cache[i].playerInZone then
            stillInZone = true
            break
        end
    end

    if not stillInZone and VFW.SetSafeZone then
        VFW.SetSafeZone(false)
    end

    SendNUIMessage({
        action = 'nui:safezone:visible',
        data = {
            visible = stillInZone
        }
    })
end

function ZoneSafe:SyncSafeZone()
    local safeZones <const> = TriggerServerCallback("core:getAllSafeZones")

    if not safeZones or not next(safeZones) then
        return
    end

    ZoneSafe:ReformatZones(safeZones)
end

ZoneSafe.lastSafePosition = nil
ZoneSafe.carkillActive = false
ZoneSafe.degatsActive = false

function ZoneSafe:GetGroundCoords(coords)
    local startPos = vector3(coords.x, coords.y, coords.z + 1.0)
    local endPos = vector3(coords.x, coords.y, coords.z - 100.0)
    local hit, _, _, _, z = GetShapeTestResult(StartShapeTestRay(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z, 1 + 16, PlayerPedId(), 0))

    if hit == 1 and z then
        return vector3(coords.x, coords.y, z.z + 1.0)
    end

    return nil
end

-- Si l'une des controls de bagarre "principales" est désactivée, on disable aussi
-- les variantes melee (R+autre touche, gamepad, etc.) que les anciennes zones en DB
-- ne contiennent pas forcément.
local MELEE_EXTRA_CONTROLS <const> = { 140, 141, 142, 257, 331 }
local MELEE_TRIGGER_CONTROLS <const> = { [24] = true, [25] = true, [263] = true, [264] = true }

function ZoneSafe:ApplyDisabledAction(disabledActions)
    if not disabledActions then
        return
    end

    local ped = PlayerPedId()
    local hasMeleeRestriction = false

    for i = 1, #disabledActions do
        local action = disabledActions[i]

        if action == "degats" then
            self.degatsActive = true
            SetEntityInvincible(ped, true)
            SetEntityProofs(ped, true, true, true, true, true, true, true, true)
            SetEntityCanBeDamaged(ped, false)
        elseif action == "carkill" then
            self.carkillActive = true

            if IsPedRagdoll(ped) then
                local pedCoords = GetEntityCoords(ped)
                local groundPos = self:GetGroundCoords(pedCoords)

                -- Si le sol est trop loin (chute), on laisse le ragdoll naturel
                if groundPos and math.abs(pedCoords.z - groundPos.z) < 3.0 then
                    ClearPedTasksImmediately(ped)
                    SetPedToRagdoll(ped, 0, 0, 0, false, false, false)
                    SetEntityCoords(ped, groundPos.x, groundPos.y, groundPos.z, false, false, false, false)
                    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                end
            elseif not IsPedInAnyVehicle(ped, false) and not IsPedFalling(ped) then
                self.lastSafePosition = GetEntityCoords(ped)
            end
        elseif type(action) == "number" then
            DisableControlAction(0, action, true)
            if MELEE_TRIGGER_CONTROLS[action] then
                hasMeleeRestriction = true
            end
        end
    end

    if hasMeleeRestriction then
        for i = 1, #MELEE_EXTRA_CONTROLS do
            DisableControlAction(0, MELEE_EXTRA_CONTROLS[i], true)
        end
    end
end

function ZoneSafe:ResetSpecialActions()
    local ped = PlayerPedId()

    if self.degatsActive then
        SetEntityInvincible(ped, false)
        SetEntityProofs(ped, false, false, false, false, false, false, false, false)
        SetEntityCanBeDamaged(ped, true)
        self.degatsActive = false
    end

    if self.carkillActive then
        self.carkillActive = false
    end

    self.lastSafePosition = nil
end

function ZoneSafe:ReformatZones(zones)
    for i = 1, #zones do
        local zone = zones[i]
        zone.center = self:GetPolygonCenter(zone.points)
        zone.radius = self:GetPolygonRadius(zone.points, zone.center)
        self.cache[#self.cache + 1] = zone
    end
end

function ZoneSafe:FindZoneByName(name)
    for i = 1, #self.cache do
        local zone <const> = self.cache[i]

        if zone.name == name then
            return zone, i
        end
    end
end

function ZoneSafe:RemoveZone(name)
    if not name then
        return
    end

    local zone <const>, index <const> = ZoneSafe:FindZoneByName(name)

    if not index then
        return
    end

    if zone and zone.playerInZone then
        self:ExitedZone(zone)
    end

    table.remove(self.cache, index)
end

function ZoneSafe:AddZone(zoneData)
    if not zoneData then
        return
    end

    if self:FindZoneByName(zoneData.name) then
        return
    end

    zoneData.center = self:GetPolygonCenter(zoneData.points)
    zoneData.radius = self:GetPolygonRadius(zoneData.points, zoneData.center)
    self.cache[#self.cache + 1] = zoneData
end

function ZoneSafe:UpdateZone(oldName, newData)
    if not oldName or not newData then
        return
    end

    local zone <const>, index <const> = ZoneSafe:FindZoneByName(oldName)

    if not zone or not index then
        return
    end

    local wasInZone = zone.playerInZone

    if wasInZone then
        self:ResetSpecialActions()
    end

    newData.center = self:GetPolygonCenter(newData.points)
    newData.radius = self:GetPolygonRadius(newData.points, newData.center)
    newData.playerInZone = wasInZone
    self.cache[index] = newData
end

function ZoneSafe:GetPlayerJobIsByPass(byPassJobs)
    if not byPassJobs or not next(byPassJobs) then
        return
    end

    local playerJob <const> = VFW.PlayerData.job.name

    if not playerJob or playerJob == "unemployed" then
        return
    end

    for i = 1, #byPassJobs do
        if byPassJobs[i] == playerJob then
            return true
        end
    end
end

RegisterNetEvent('zonesafe:client:add', function(zoneData)
    ZoneSafe:AddZone(zoneData)
end)

RegisterNetEvent('zonesafe:client:remove', function(name)
    ZoneSafe:RemoveZone(name)
end)

RegisterNetEvent('zonesafe:client:update', function(oldName, newData)
    ZoneSafe:UpdateZone(oldName, newData)
end)
