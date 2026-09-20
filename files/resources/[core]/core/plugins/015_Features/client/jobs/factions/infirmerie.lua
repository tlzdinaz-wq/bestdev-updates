---@meta _
---@diagnostic disable: duplicate-doc-field

local bedModels = {
    [-119016924] = true,
}
local bedPoints = {}
local open = false

--- openNurseMenu
local function openNurseMenu()
    open = not open

    if open then
        local health = IsPedMale(VFW.PlayerData.ped) and (GetEntityHealth(VFW.PlayerData.ped) - 100) or GetEntityHealth(VFW.PlayerData.ped)

        VFW.Nui.NurseMenu(true, {
            firstname = VFW.PlayerData.firstName,
            lastname = VFW.PlayerData.lastName,
            birthdate = VFW.PlayerData.dateofbirth,
            care_cost = 150,
            health = health,
            mugshot = VFW.PlayerData.mugshot
        })
    else
        VFW.Nui.NurseMenu(false)
    end
end

--- Sleep
---@param object any
local function Sleep(object)
    local playerPed = VFW.PlayerData.ped
    local objectHeading = GetEntityHeading(object)
    local bedOffset = GetEntityCoords(object)

    SetEntityCoords(playerPed, bedOffset.x, bedOffset.y, bedOffset.z)
    SetEntityHeading(playerPed, objectHeading + 180.0)

    ExecuteCommand("e sleep")
end

RegisterNuiCallback("nui:nurseMenu:send", function(data)
    if not data then
        return
    end

    open = false
    VFW.Nui.NurseMenu(false)
    Worlds.Zone.HideInteract(false)
    SetTimeout(150,function()
        local duration = VFW.Nui.ProgressBar("L'infirmière est en train de vous soigner...", 1000 * 30)

        if duration then
            SetEntityHealth(VFW.PlayerData.ped, GetEntityHealth(VFW.PlayerData.ped) + 100)
            ExecuteCommand("+clearAnim")
            TriggerServerEvent("vfw:server:nurse:heal")
            Worlds.Zone.HideInteract(true)
        end
    end)
end)

RegisterNuiCallback("nui:nurseMenu:close", function()
    open = false
    VFW.Nui.NurseMenu(false)
    ExecuteCommand("+clearAnim")
end)

CreateThread(function()
    while true do
        local medicMans = ((GlobalState['serviceCount_sams'] or 0) + (GlobalState['serviceCount_lsfd'] or 0))

        for _, entity in pairs(GetGamePool("CObject")) do
            local model = GetEntityModel(entity)
            local objectPos = GetEntityCoords(entity)

            if medicMans >= 3 then
                if bedPoints[objectPos] then
                    Worlds.Zone.Remove(bedPoints[objectPos])
                    bedPoints[objectPos] = nil
                end

                goto skip
            end

            if not bedPoints[objectPos] then
                if bedModels[model] then
                    bedPoints[objectPos] = Worlds.Zone.Create(vector3(objectPos.x, objectPos.y, objectPos.z + 0.7), 2, false, function()
                        VFW.RegisterInteraction("nurse", function()
                            if entity and DoesEntityExist(entity) then
                                Sleep(entity)
                                openNurseMenu()
                            end
                        end)
                    end, function()
                        VFW.RemoveInteraction("nurse")
                    end, "Soigner", "E", "Banque")
                end
            end

            ::skip::
        end

        Wait(5000)
    end
end)
