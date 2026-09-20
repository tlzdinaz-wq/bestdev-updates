--- @class JobModel
JobModel = {}
JobModel.__index = JobModel

JobModel.list = {}

JobModel.types = {
    ["dj"] = { label = "Gestion DJ", submenu = "manageDJ" },
    --["outfit"] = { label = "Gestion Tenues", submenu = "manageOutfit" },
    --["storage"] = { label = "Gestion Coffres", submenu = "manageStorage" },
    ["customs"] = { label = "Gestion Customs", submenu = "manageCustoms" },
    ["craft"] = { label = "Points de récolte", submenu = "manageCraft" },
    ["concess"] = { label = "Options personnalisées", submenu = "manageConcess" },
    ["ltd"] = { label = "Gestion Livraisons", submenu = "manageLTD" },
    ["catalog"] = { label = "Points Catalogue", submenu = "manageCatalog" },
    ["taxi"] = { label = "Gestion Taxi", submenu = "manageTaxi" }
}

JobModel.defaultTypes = {
    ["outfit"] = true, 
    ["storage"] = true
}

--- @param name string
--- @return JobModel
function JobModel.new(name)
    local self = setmetatable({}, JobModel)

    self.name = name
    self.label = nil
    self.activeBuilders = {}

    for k, v in pairs(JobModel.defaultTypes) do
        self.activeBuilders[k] = v
    end
    
    self.addonFields = {}

    JobModel.list[name] = self

    return self
end

--- @param name string
function JobModel.get(name)
    return JobModel.list[name]
end

function JobModel.getAll()
    return JobModel.list
end

--- @param name string
function JobModel.getType(name)
    return JobModel.types[name]
end

function JobModel.getAllTypes()
    return JobModel.types
end

--- @param label string
--- @return JobModel
function JobModel:setLabel(label)
    assert(type(label) == "string", "Label must be a string")

    self.label = label

    return self
end

--- @param builder string
--- @return JobModel
function JobModel:activateBuilder(builder)
    assert(type(builder) == "string", "Builder must be a string")

    if not JobModel.types[builder] then
        return error("Invalid builder type")
    end

    self.activeBuilders[builder] = true

    return self
end

--- @param builder string
--- @return JobModel
function JobModel:disableBuilder(builder)
    assert(type(builder) == "string", "Builder must be a string")

    if self.activeBuilders[builder] then
        self.activeBuilders[builder] = nil
    end

    return self
end

--- @param field table {type: string, name: string, label: string, required: boolean}
--- @return JobModel
function JobModel:addAddonField(field)
    assert(type(field) == "table", "Field must be a table")

    if not field.type or not field.label or not field.name then
        return error("Field must have a type, label and name")
    end

    self.addonFields[#self.addonFields + 1] = field

    return self
end