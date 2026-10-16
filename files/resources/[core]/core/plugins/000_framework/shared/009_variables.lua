---@meta _
---@diagnostic disable: duplicate-doc-field

local isServerSide = IsDuplicityVersion();

if isServerSide then 
    VFW.Variables = {
---@class Datas
        Datas = {},
---@class NeedSaves
        NeedSaves = {},
---@class SaveID
        SaveID = {}
    }

---Get VFW.Variables.Variable
---@param name string
---@return any
    function VFW.Variables.GetVariable(name)
        return VFW.Variables.Datas[name] or {}
    end

---Set VFW.Variables.Variable
---@param name string
---@param value any
    function VFW.Variables.SetVariable(name, value)
        VFW.Variables.Datas[name] = value
        VFW.Variables.NeedSaves[name] = true
        VFW.Variables.SaveID[name] = math.random(1, 9999)
    end

    local UPSERT_VARIABLE = [[
        INSERT INTO variables (`name`, `data`)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)
    ]]

    local function writeRow(name, data)
        if type(MySQL) ~= "table" then return false end
        local encoded = json.encode(data)
        if MySQL.update and MySQL.update.await then
            local ok, err = pcall(MySQL.update.await, UPSERT_VARIABLE, { name, encoded })
            if not ok then
                console.warn(("[Variables] Flush %s : %s"):format(name, tostring(err)))
                return false
            end
            return true
        end
        if MySQL.Async and MySQL.Async.execute then
            MySQL.Async.execute(UPSERT_VARIABLE, { name, encoded })
            return true
        end
        return false
    end

    function VFW.Variables.Flush(name)
        if type(name) ~= "string" or name == "" then return false end
        local data = VFW.Variables.Datas[name]
        if data == nil then return false end
        if writeRow(name, data) then
            VFW.Variables.NeedSaves[name] = nil
            return true
        end
        VFW.Variables.NeedSaves[name] = true
        return false
    end

    -- lastid is used to check if the client has already the same version has the server, if so, no need to send again and flood the network
    RegisterServerCallback("core:variables:getVariables", function(source, name, lastid)
        if VFW.Variables.SaveID[name] ~= lastid then 
            return VFW.Variables.Datas[name], VFW.Variables.SaveID[name]
        end

        return false
    end)

    -- Save system
    CreateThread(function()
        while true do 
            Wait(60000)
            for name in pairs(VFW.Variables.NeedSaves) do
                if VFW.Variables.NeedSaves[name] ~= nil then 
                    VFW.Variables.NeedSaves[name] = nil
                    local data = VFW.Variables.Datas[name]
                    if data then
                        if not writeRow(name, data) then
                            VFW.Variables.NeedSaves[name] = true
                        end
                    end
                end
            end
        end
    end)

    local CREATE_VARIABLES = [[
        CREATE TABLE IF NOT EXISTS variables (
            `name` VARCHAR(100) NOT NULL,
            `data` LONGTEXT DEFAULT NULL,
            PRIMARY KEY (`name`)
        )
    ]]

    -- Load system. Ce fichier est un shared_script : il s'exécute avant
    -- @oxmysql/lib/MySQL.lua (server_scripts). On attend donc l'API.
    CreateThread(function()
        while type(MySQL) ~= "table" or type(MySQL.ready) ~= "function" do
            Wait(100)
        end

        MySQL.ready(function()
            pcall(MySQL.query.await, CREATE_VARIABLES)
            local ok, result = pcall(MySQL.query.await, "SELECT * FROM variables")
            if not ok then
                console.error("[Core:Variables] Impossible de charger les variables : " .. tostring(result))
                return
            end
            result = result or {}
            for i = 1, #result do
                local name = result[i].name
                if not VFW.Variables.NeedSaves[name] then
                    local decoded = result[i].data
                    if type(decoded) == "string" and decoded ~= "" then
                        local parsedOk, parsed = pcall(json.decode, decoded)
                        decoded = parsedOk and parsed or {}
                    end
                    VFW.Variables.Datas[name] = decoded
                    VFW.Variables.SaveID[name] = math.random(1, 9999)
                end
            end
            console.init("Variables", ("Toutes les variables chargees (%d)"):format(#result))
            TriggerEvent("vfw:variables:loaded")
            if VFW.Branding and VFW.Branding.Push then
                VFW.Branding.Push(-1)
            end
        end)
    end)

else
    VFW.Variables = {
---@class Datas
        Datas = {},
---@class LastIds
        LastIds = {}
    }
---Get VFW.Variables.Variable
---@param name string
---@return any
    function VFW.Variables.GetVariable(name)
        -- If new data from the last time we checked, we update it otherwise we return the current data that is the same as the serverside since its the same lastid
        local newDatas, newId = TriggerServerCallback("core:variables:getVariables", name, VFW.Variables.LastIds[name])
        if newDatas then 
            VFW.Variables.Datas[name] = newDatas
            VFW.Variables.LastIds[name] = newId
        end

        return VFW.Variables.Datas[name]
    end
end