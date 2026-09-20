DepositBuilder = {}
DepositBuilder.cache = {}

function DepositBuilder:FindIndexById(pointId)
    for i = 1, #self.cache do
        if self.cache[i].id == pointId then
            return i
        end
    end
end

function DepositBuilder:FindById(pointId)
    local idx <const> = self:FindIndexById(pointId)
    return idx and self.cache[idx] or nil
end

function DepositBuilder:Upsert(point)
    local idx <const> = self:FindIndexById(point.id)
    if idx then
        self.cache[idx] = point
    else
        self.cache[#self.cache + 1] = point
    end
end

function DepositBuilder:Remove(pointId)
    local idx <const> = self:FindIndexById(pointId)
    if idx then
        table.remove(self.cache, idx)
    end
end
