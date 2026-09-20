---@meta _
---@diagnostic disable: duplicate-doc-field

local lastJob = nil
local contextMenu = {}

--[[
    ========================================
    JOB CONTEXT MENU REGISTRY
    ========================================

    Permet aux jobs d'enregistrer dynamiquement leurs actions
    dans le menu contextuel depuis leurs propres fichiers.

    Usage depuis un job:

    local registry = exports["core"]:getJobContextRegistry()

    -- Enregistrer une action véhicule
    registry.registerVehicle("mecano", {
        label = ":wrench: Réparer",
        callback = function(vehicle) ... end,
        condition = function(vehicle) return true end, -- optionnel
        style = { color = { 255, 0, 0 } } -- optionnel
    })

    -- Enregistrer une action ped
    registry.registerPed("police", {
        label = ":search: Fouiller",
        callback = function(ped) ... end
    })

    -- Enregistrer une action world
    registry.registerWorld("police", {
        label = ":pin: Poser un cône",
        callback = function(worldPosition) ... end
    })

    -- Support multi-jobs
    registry.registerVehicle({"mecano", "bennys"}, { ... })
]]

---@class JobContextRegistry
local JobContextRegistry = {
    actions = {
        vehicle = {},
        ped = {},
        world = {}
    },
    submenuLabels = {
        vehicle = {},
        ped = {},
        world = {}
    },
    typeActions = {
        vehicle = {},
        ped = {},
        world = {}
    },
    typeSubmenuLabels = {
        vehicle = {},
        ped = {},
        world = {}
    }
}

--- Set a custom submenu label for a job
---@param jobNames string|string[] Job name(s)
---@param category string "vehicle" | "ped" | "world"
---@param label string Custom label for the submenu button
function JobContextRegistry.setSubmenuLabel(jobNames, category, label)
    local jobs = type(jobNames) == "table" and jobNames or { jobNames }

    for _, jobName in ipairs(jobs) do
        if JobContextRegistry.submenuLabels[category] then
            JobContextRegistry.submenuLabels[category][jobName] = label
        end
    end
end

--- Set a custom submenu label for a society type
---@param societyType string Society type (e.g., "mechanic", "concess")
---@param category string "vehicle" | "ped" | "world"
---@param label string Custom label for the submenu button
function JobContextRegistry.setSubmenuLabelByType(societyType, category, label)
    if JobContextRegistry.typeSubmenuLabels[category] then
        JobContextRegistry.typeSubmenuLabels[category][societyType] = label
    end
end

--- Get the submenu label for a job (returns custom or default job label)
---@param jobName string Job name
---@param category string "vehicle" | "ped" | "world"
---@return string
function JobContextRegistry.getSubmenuLabel(jobName, category)
    if JobContextRegistry.submenuLabels[category] and JobContextRegistry.submenuLabels[category][jobName] then
        return JobContextRegistry.submenuLabels[category][jobName]
    end
    -- Fallback to type-based label
    if Society.data and Society.data.type then
        if JobContextRegistry.typeSubmenuLabels[category] and JobContextRegistry.typeSubmenuLabels[category][Society.data.type] then
            return JobContextRegistry.typeSubmenuLabels[category][Society.data.type]
        end
    end
    return VFW.PlayerData.job.label
end

--- Register a vehicle context action for one or more jobs
---@param jobNames string|string[] Job name(s)
---@param action table { label: string, callback: function, condition?: function, style?: table }
function JobContextRegistry.registerVehicle(jobNames, action)
    local jobs = type(jobNames) == "table" and jobNames or { jobNames }

    for _, jobName in ipairs(jobs) do
        if not JobContextRegistry.actions.vehicle[jobName] then
            JobContextRegistry.actions.vehicle[jobName] = {}
        end
        table.insert(JobContextRegistry.actions.vehicle[jobName], action)

        -- Also add to VFW.Jobs.ContextMenu for compatibility
        if not VFW.Jobs.ContextMenu[jobName] then
            VFW.Jobs.ContextMenu[jobName] = { veh = {}, ped = {}, world = {} }
        end
        if not VFW.Jobs.ContextMenu[jobName].veh then
            VFW.Jobs.ContextMenu[jobName].veh = {}
        end
        table.insert(VFW.Jobs.ContextMenu[jobName].veh, action)
    end
end

--- Register a ped context action for one or more jobs
---@param jobNames string|string[] Job name(s)
---@param action table { label: string, callback: function, condition?: function, style?: table }
function JobContextRegistry.registerPed(jobNames, action)
    local jobs = type(jobNames) == "table" and jobNames or { jobNames }

    for _, jobName in ipairs(jobs) do
        if not JobContextRegistry.actions.ped[jobName] then
            JobContextRegistry.actions.ped[jobName] = {}
        end
        table.insert(JobContextRegistry.actions.ped[jobName], action)

        -- Also add to VFW.Jobs.ContextMenu for compatibility
        if not VFW.Jobs.ContextMenu[jobName] then
            VFW.Jobs.ContextMenu[jobName] = { veh = {}, ped = {}, world = {} }
        end
        if not VFW.Jobs.ContextMenu[jobName].ped then
            VFW.Jobs.ContextMenu[jobName].ped = {}
        end
        table.insert(VFW.Jobs.ContextMenu[jobName].ped, action)
    end
end

--- Register a world context action for one or more jobs
---@param jobNames string|string[] Job name(s)
---@param action table { label: string, callback: function, condition?: function, style?: table }
function JobContextRegistry.registerWorld(jobNames, action)
    local jobs = type(jobNames) == "table" and jobNames or { jobNames }

    for _, jobName in ipairs(jobs) do
        if not JobContextRegistry.actions.world[jobName] then
            JobContextRegistry.actions.world[jobName] = {}
        end
        table.insert(JobContextRegistry.actions.world[jobName], action)

        -- Also add to VFW.Jobs.ContextMenu for compatibility
        if not VFW.Jobs.ContextMenu[jobName] then
            VFW.Jobs.ContextMenu[jobName] = { veh = {}, ped = {}, world = {} }
        end
        if not VFW.Jobs.ContextMenu[jobName].world then
            VFW.Jobs.ContextMenu[jobName].world = {}
        end
        table.insert(VFW.Jobs.ContextMenu[jobName].world, action)
    end
end

--- Register a vehicle context action for a society type
---@param societyType string Society type (e.g., "mechanic")
---@param action table { label: string, callback: function, condition?: function, style?: table }
function JobContextRegistry.registerVehicleByType(societyType, action)
    if not JobContextRegistry.typeActions.vehicle[societyType] then
        JobContextRegistry.typeActions.vehicle[societyType] = {}
    end
    table.insert(JobContextRegistry.typeActions.vehicle[societyType], action)
end

--- Register a ped context action for a society type
---@param societyType string Society type (e.g., "mechanic")
---@param action table { label: string, callback: function, condition?: function, style?: table }
function JobContextRegistry.registerPedByType(societyType, action)
    if not JobContextRegistry.typeActions.ped[societyType] then
        JobContextRegistry.typeActions.ped[societyType] = {}
    end
    table.insert(JobContextRegistry.typeActions.ped[societyType], action)
end

--- Register a world context action for a society type
---@param societyType string Society type (e.g., "mechanic")
---@param action table { label: string, callback: function, condition?: function, style?: table }
function JobContextRegistry.registerWorldByType(societyType, action)
    if not JobContextRegistry.typeActions.world[societyType] then
        JobContextRegistry.typeActions.world[societyType] = {}
    end
    table.insert(JobContextRegistry.typeActions.world[societyType], action)
end

--- Get all registered actions for a job
---@param jobName string Job name
---@return table { vehicle: table[], ped: table[], world: table[] }
function JobContextRegistry.getActions(jobName)
    return {
        vehicle = JobContextRegistry.actions.vehicle[jobName] or {},
        ped = JobContextRegistry.actions.ped[jobName] or {},
        world = JobContextRegistry.actions.world[jobName] or {}
    }
end

-- Export the registry
exports("getJobContextRegistry", function()
    return JobContextRegistry
end)

-- Convenience exports
exports("registerJobContextVehicle", function(jobNames, action)
    JobContextRegistry.registerVehicle(jobNames, action)
end)

exports("registerJobContextPed", function(jobNames, action)
    JobContextRegistry.registerPed(jobNames, action)
end)

exports("registerJobContextWorld", function(jobNames, action)
    JobContextRegistry.registerWorld(jobNames, action)
end)

exports("setJobContextSubmenuLabel", function(jobNames, category, label)
    JobContextRegistry.setSubmenuLabel(jobNames, category, label)
end)

local function getVehicleContextDistance()
    if Society.data and Society.data.type == "mechanic" then
        return 4.5
    end
    return 2.75
end

---Load ContextMenu
local function loadContextMenu()
    -- Determine the society type for type-based actions
    local societyType = Society.data and Society.data.type or nil

    -- Check if there are any actions to load (job-based or type-based)
    local hasJobActions = VFW.Jobs.ContextMenu[lastJob] ~= nil
    local hasTypeActions = societyType and (
        (JobContextRegistry.typeActions.vehicle[societyType] and #JobContextRegistry.typeActions.vehicle[societyType] > 0) or
        (JobContextRegistry.typeActions.ped[societyType] and #JobContextRegistry.typeActions.ped[societyType] > 0) or
        (JobContextRegistry.typeActions.world[societyType] and #JobContextRegistry.typeActions.world[societyType] > 0)
    )

    -- Wait for job-based actions only if no type-based actions exist
    if not hasTypeActions then
        local waited = 0
        while not next(VFW.Jobs.ContextMenu) and waited < 5000 do
            Wait(100)
            waited = waited + 100
        end
    end

    if not lastJob then
        return
    end

    -- If no actions at all, return
    if not VFW.Jobs.ContextMenu[lastJob] and not hasTypeActions then
        return
    end

---@class contextMenu
    contextMenu = {}

    -- Get custom labels or fallback to job label
    local pedLabel = JobContextRegistry.getSubmenuLabel(lastJob, "ped")
    local vehicleLabel = JobContextRegistry.getSubmenuLabel(lastJob, "vehicle")
    local worldLabel = JobContextRegistry.getSubmenuLabel(lastJob, "world")

    local submenupedsKey = ("%submenupedsKey"):format(lastJob)
    contextMenu[submenupedsKey] = VFW.ContextAddSubmenu("ped", pedLabel, function(ped)
        local isPlayer = NetworkGetPlayerIndexFromPed(ped)
        local pId = GetPlayerServerId(isPlayer)
        local source = GetPlayerServerId(PlayerId())
        local isSamePlayer = pId ~= source
        local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(ped))
        return distance < 2.75 and IsPedAPlayer(ped) and lastJob ~= "unemployed" and VFW.PlayerData.job.onDuty and isSamePlayer and not VFW.IsPlayerInTIG()
    end, {
        color = { 44, 135, 255 }
    }, nil, { order = 1 })

    local submenuvehKey = ("%submenuvehKey"):format(lastJob)
    contextMenu[submenuvehKey] = VFW.ContextAddSubmenu("vehicle", vehicleLabel, function(vehicle)
        local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(vehicle))
        return distance < getVehicleContextDistance() and lastJob ~= "unemployed" and VFW.PlayerData.job.onDuty and not VFW.IsPlayerInTIG()
    end, {
        color = { 44, 135, 255 }
    }, nil, { order = 1 })


    local submenuworldKey = ("%submenuworldKey"):format(lastJob)
    contextMenu[submenuworldKey] = VFW.ContextAddSubmenu("world", worldLabel, function()
        return lastJob ~= "unemployed" and VFW.PlayerData.job.onDuty and not VFW.IsPlayerInTIG()
    end, {
        color = { 44, 135, 255 }
    }, nil, { order = 1 })

    -- Collect all actions: job-based + type-based
    local allActions = { veh = {}, ped = {}, world = {} }

    -- Add job-based actions
    if VFW.Jobs.ContextMenu[lastJob] then
        for category, actions in pairs(VFW.Jobs.ContextMenu[lastJob]) do
            for _, action in ipairs(actions) do
                table.insert(allActions[category], action)
            end
        end
    end

    -- Add type-based actions
    if societyType then
        if JobContextRegistry.typeActions.vehicle[societyType] then
            for _, action in ipairs(JobContextRegistry.typeActions.vehicle[societyType]) do
                table.insert(allActions.veh, action)
            end
        end
        if JobContextRegistry.typeActions.ped[societyType] then
            for _, action in ipairs(JobContextRegistry.typeActions.ped[societyType]) do
                table.insert(allActions.ped, action)
            end
        end
        if JobContextRegistry.typeActions.world[societyType] then
            for _, action in ipairs(JobContextRegistry.typeActions.world[societyType]) do
                table.insert(allActions.world, action)
            end
        end
    end

    for category, actions in pairs(allActions) do
        for _, action in ipairs(actions) do
            if category == "veh" then
                VFW.ContextAddButton("vehicle", action.label, function(vehicle)
                    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(vehicle))
                    local base = distance < getVehicleContextDistance() and lastJob ~= "unemployed" and VFW.PlayerData.job.onDuty and not VFW.IsPlayerInTIG()
                    if not base then return false end
                    if action.condition then return action.condition(vehicle) end
                    return true
                end, function(vehicle)
                    SetTimeout(500, function()
                        action.callback(vehicle)
                    end)
                end, action.style or {}, contextMenu[submenuvehKey])
            elseif category == "ped" then
                VFW.ContextAddButton("ped", action.label, function(ped)
                    local isPlayer = NetworkGetPlayerIndexFromPed(ped)
                    local pId = GetPlayerServerId(isPlayer)
                    local source = GetPlayerServerId(PlayerId())
                    local isSamePlayer = pId ~= source
                    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(ped))
                    return distance < 2.75 and IsPedAPlayer(ped) and lastJob ~= "unemployed" and VFW.PlayerData.job.onDuty and isSamePlayer and not VFW.IsPlayerInTIG()
                end, function(ped)
                    SetTimeout(500, function()
                        action.callback(ped)
                    end)
                end, action.style or {}, contextMenu[submenupedsKey])
            elseif category == "world" then
                VFW.ContextAddButton("world", action.label, function()
                    return lastJob ~= "unemployed" and VFW.PlayerData.job.onDuty and not VFW.IsPlayerInTIG()
                end, function(_, worldPosition)
                    SetTimeout(500, function()
                        action.callback(worldPosition)
                    end)
                end, action.style or {}, contextMenu[submenuworldKey])
            end
        end
    end
end

--- clearContextMenu
local function clearContextMenu()

    for key, _ in pairs(contextMenu) do
        VFW.ContextRemoveButton(contextMenu[key])
        contextMenu[key] = nil
    end
end

---@param Job table Job data
RegisterNetEvent("vfw:setJob", function(Job)
    if Job.name == lastJob then
        return
    end

    clearContextMenu()
    if Job.name == "unemployed" then
        lastJob = nil
        return
    end

    lastJob = Job.name
    Wait(500)
    loadContextMenu()
end)

RegisterNetEvent("vfw:playerReady", function()
    if lastJob then
        clearContextMenu()
        lastJob = nil
    end

    if VFW.PlayerData.job.name == "unemployed" then
        return
    end

    lastJob = VFW.PlayerData.job.name
    loadContextMenu()
end)
