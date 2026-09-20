GarageIllegal = {}
GarageIllegal.points = {}

function GarageIllegal:ClearAll()
    self.points = {}
end

function GarageIllegal:FindById(id)
    for i = 1, #self.points do
        if self.points[i].id == id then
            return self.points[i], i
        end
    end
end

function GarageIllegal:SetPoints(points)
    self:ClearAll()
    if not points then return end
    for i = 1, #points do
        self.points[#self.points + 1] = points[i]
    end
end

function GarageIllegal:AddPoint(point)
    if self:FindById(point.id) then return end
    self.points[#self.points + 1] = point
end

function GarageIllegal:UpdatePoint(point)
    local existing, index = self:FindById(point.id)
    if not existing then return self:AddPoint(point) end
    self.points[index] = point
end

function GarageIllegal:DeletePoint(id)
    local _, index = self:FindById(id)
    if not index then return end
    table.remove(self.points, index)
end

function GarageIllegal:CanUse(point)
    if not point then return false end
    local jobs = point.allowedJobs or {}
    local factions = point.allowedFactions or {}
    if #jobs == 0 and #factions == 0 then return true end

    local job = VFW.PlayerData and VFW.PlayerData.job and VFW.PlayerData.job.name
    local faction = VFW.PlayerData and VFW.PlayerData.faction and VFW.PlayerData.faction.name
    for i = 1, #jobs do
        if jobs[i] == job then return true end
    end
    for i = 1, #factions do
        if factions[i] == faction then return true end
    end
    return false
end
