---@meta _
---@diagnostic disable: duplicate-doc-field

local COLORS <const> = {
    SELECT = { 94, 108, 182, 55 },
    YELLOW = { 255, 255, 0, 155 },
    WHITE = { 255, 255, 255, 55 },
}

local selectedEntities = {}

---Create VFW.OutlineInstance
---@param level any
---@param color any
---@param alpha any
function VFW.CreateOutlineInstance(level, color, alpha)
    local self = {}

    self.level = level
    self.color = COLORS[color] or COLORS.WHITE
    self.alpha = alpha or 204

--- .selectEntity
---@param entity any
    function self.selectEntity(entity)
        if self.entity then
            self:deselectEntity(self.entity)
        end

        if selectedEntities[entity] then
            if selectedEntities[entity].level > self.level then
                return
            end

            selectedEntities[entity].entity = nil
        end

        self.entity = entity
        selectedEntities[self.entity] = self
        SetEntityAlpha(self.entity, self.alpha, false)
        SetEntityDrawOutline(self.entity, true)
        SetEntityDrawOutlineColor(self.color[1], self.color[2], self.color[3], self.color[4])
        SetEntityDrawOutlineShader(1)
    end

--- .deselectEntity
---@return any
    function self.deselectEntity()
        if not self.entity then
            return
        end

        selectedEntities[self.entity] = nil
        SetEntityAlpha(self.entity, 255, false)
        SetEntityDrawOutline(self.entity, false)
        self.entity = nil
    end

    return self
end