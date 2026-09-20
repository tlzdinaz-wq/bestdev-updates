TeleportBuilder = {}
TeleportBuilder.cache = {}

function TeleportBuilder:FindIndexById(pointId)
    for i = 1, #self.cache do
        if self.cache[i].id == pointId then
            return i
        end
    end
end

function TeleportBuilder:Upsert(point)
    local idx <const> = self:FindIndexById(point.id)

    if idx then
        self.cache[idx] = point
    else
        self.cache[#self.cache + 1] = point
    end
end

function TeleportBuilder:Remove(pointId)
    local idx <const> = self:FindIndexById(pointId)

    if idx then
        table.remove(self.cache, idx)
    end
end
