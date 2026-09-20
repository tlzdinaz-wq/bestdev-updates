---@meta _
---@diagnostic disable: duplicate-doc-field

local poleDance = {
    { position = vector4(106.57, -1291.72, 21.08, 29.73), spawn = true },
    { position = vector4(111.12, -1295.4, 21.08, 8.33), spawn = true },
    { position = vector4(107.33, -1297.37, 21.08, 66.3), spawn = true },
    { position = vector4(122.13, -1289.88, 20.91, 223.73), spawn = true },
    { position = vector4(116.16, -1279.18, 20.91, 88.27), spawn = true },
}

--- PoleDance
local function PoleDance()
    local self = {}

    self.poleProps = {}
    self.isDancing = false

    function self:requestModel(model)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(100)
        end
    end

    function self:requestAnimDict(animDict)
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(100)
        end
    end

    function self:Create()
        for k, v in pairs(poleDance) do
            if v.spawn then
                self:requestModel('prop_strip_pole_01')

                local pole = CreateObject(joaat('prop_strip_pole_01'), v.position.x, v.position.y, v.position.z, false, false, false)
                self.poleProps[#self.poleProps + 1] = pole
            end
        end
    end

    function self:Destroy()
        for _, pole in ipairs(self.poleProps) do
            if DoesEntityExist(pole) then
                DeleteObject(pole)
            end
        end
    end

    function self:getClosestPolePosition()
        local playerPos = GetEntityCoords(VFW.PlayerData.ped)
        local closestDistance = math.huge
        local closestPole = nil

        for _, point in ipairs(poleDance) do
            local distance = #(vector3(point.position.x, point.position.y, point.position.z) - playerPos)
            if distance < closestDistance then
                closestDistance = distance
                closestPole = point.position
            end
        end

        return closestPole, closestDistance
    end

    function self:Start(args)
        local position = GetEntityCoords(VFW.PlayerData.ped)
        local usePolePosition = false

        if not args.coords then
            args.coords = position
        end

        if args.dance then
            local closestPole, distance = self:getClosestPolePosition()

            if closestPole and distance <= 2.0 then
                usePolePosition = true
                local scene = NetworkCreateSynchronisedScene(closestPole.x + 0.07, closestPole.y + 0.3, closestPole.z + 1.15, 0.0, 0.0, 0.0, 2, false, true, 1065353216, 0, 1.3)

                NetworkAddPedToSynchronisedScene(VFW.PlayerData.ped, scene, 'mini@strip_club@pole_dance@pole_dance' .. args.dance, 'pd_dance_0' .. args.dance, 1.5, -4.0, 1, 1, 1148846080, 0)
                NetworkStartSynchronisedScene(scene)
                self.isDancing = true
            end
        elseif args.lapdance then
            self:requestAnimDict(args.dict)
            TaskPlayAnim(VFW.PlayerData.ped, args.dict, args.anim, 1.0, 1.0, -1, 1, 0, 0, 0, 0)
            self.isDancing = true
        else
            local closestPole, distance = self:getClosestPolePosition()

            if closestPole and distance <= 2.0 then
                usePolePosition = true
                args.coords = closestPole

                local scene = NetworkCreateSynchronisedScene(args.coords.x + 0.07, args.coords.y + 0.3, args.coords.z + 1.15, 0.0, 0.0, 0.0, 2, false, true, 1065353216, 0, 1.3)

                NetworkAddPedToSynchronisedScene(VFW.PlayerData.ped, scene, 'mini@strip_club@pole_dance@pole_dance' .. args.dance, 'pd_dance_0' .. args.dance, 1.5, -4.0, 1, 1, 1148846080, 0)
                NetworkStartSynchronisedScene(scene)
                self.isDancing = true
            end
        end
    end

    function self:Stop()
        if self.isDancing then
            ClearPedTasks(VFW.PlayerData.ped)
            self.isDancing = false
        end
    end

    return self
end

local PropsContext_Poledance = VFW.ContextAddSubmenu("object", "Pole Dance", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, {}, nil)

local PoleDanceInstance = PoleDance()

VFW.ContextAddButton("object", "Arrêter la danse", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Stop()
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Pole Dance #1", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({ dance = 1 })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Pole Dance #2", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({ dance = 2 })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Pole Dance #3", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({ dance = 3 })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Lap Dance #1", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({
        lapdance = 1,
        anim = 'lap_dance_girl',
        dict = 'mp_safehouse'
    })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Lap Dance #2", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({
        lapdance = 2,
        anim = 'priv_dance_idle',
        dict = 'mini@strip_club@private_dance@idle'
    })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Lap Dance #3", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({
        lapdance = 3,
        anim = 'priv_dance_p1',
        dict = 'mini@strip_club@private_dance@part1'
    })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Lap Dance #4", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({
        lapdance = 4,
        anim = 'priv_dance_p2',
        dict = 'mini@strip_club@private_dance@part2'
    })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Lap Dance #5", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({
        lapdance = 5,
        anim = 'priv_dance_p3',
        dict = 'mini@strip_club@private_dance@part3'
    })
end, {}, PropsContext_Poledance)

VFW.ContextAddButton("object", "Lap Dance #6", function(object)
    local distance = #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(object))
    return distance < 2.75 and DoesEntityExist(object) and GetEntityModel(object) and GetEntityModel(object) == 2088900873
end, function(object)
    PoleDanceInstance:Start({
        lapdance = 6,
        anim = 'yacht_ld_f',
        dict = 'oddjobs@assassinate@multi@yachttarget@lapdance'
    })
end, {}, PropsContext_Poledance)

---@param resourceName number Player ID
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    PoleDanceInstance:Create()
end)

---@param resourceName number Player ID
AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    PoleDanceInstance:Destroy()
end)
