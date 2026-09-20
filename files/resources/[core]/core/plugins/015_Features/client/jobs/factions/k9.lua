---@meta _
---@diagnostic disable: duplicate-doc-field

local DOG_BREEDS = {
    'Berger Allemand',
    'Husky',
    'Rottweiler',
}
local DOG_MODELS = {
    'a_c_shepherd',
    'a_c_husky',
    'a_c_rottweiler',
}

local k9Dog = nil
local k9DogName = nil
local k9Blip = nil
local currentDogIndex = 1
local isAttacking = false
local _k9ActiveMenu = nil

--- ShowNotification
---@param message string
---@param type any
local function ShowNotification(message, type)
    VFW.ShowNotification({
        type = type or 'INFO',
        content = message
    })
end

--- Command_Sit
---@param ped number Ped handle
local function Command_Sit(ped)
    ClearPedTasks(ped)

    if not IsEntityPlayingAnim(ped, "creatures@rottweiler@amb@world_dog_sitting@idle_a", "idle_b", 3) then
        RequestAnimDict("creatures@rottweiler@amb@world_dog_sitting@idle_a")
        while not HasAnimDictLoaded("creatures@rottweiler@amb@world_dog_sitting@idle_a") do
            Wait(0)
        end

        TaskPlayAnim(ped, "creatures@rottweiler@amb@world_dog_sitting@idle_a", "idle_b", 8.0, -4.0, -1, 1, 0.0)
    end
end

--- Command_Stay
---@param ped number Ped handle
local function Command_Stay(ped)
    ClearPedTasks(ped)
    RequestAnimDict("amb@lo_res_idles@")

    while not HasAnimDictLoaded("amb@lo_res_idles@") do
        Wait(0)
    end

    TaskPlayAnim(ped, "amb@lo_res_idles@", "creatures_world_rottweiler_standing_lo_res_base", 8.0, -4.0, -1, 1, 0.0)
end

--- Command_Paw
---@param ped number Ped handle
local function Command_Paw(ped)
    ClearPedTasks(ped)
    RequestAnimDict("creatures@rottweiler@tricks@")

    while not HasAnimDictLoaded("creatures@rottweiler@tricks@") do
        Wait(0)
    end

    TaskPlayAnim(ped, "creatures@rottweiler@tricks@", "paw_right_loop", 8.0, -4.0, -1, 1, 0.0)
end

--- Command_Beg
---@param ped number Ped handle
local function Command_Beg(ped)
    ClearPedTasks(ped)
    RequestAnimDict("creatures@rottweiler@tricks@")

    while not HasAnimDictLoaded("creatures@rottweiler@tricks@") do
        Wait(0)
    end

    TaskPlayAnim(ped, "creatures@rottweiler@tricks@", "beg_loop", 8.0, -4.0, -1, 1, 0.0)
end

--- Command_Follow
---@param ped number Ped handle
local function Command_Follow(ped)
    ClearPedTasks(ped)
    DetachEntity(ped)
    TaskFollowToOffsetOfEntity(ped, VFW.PlayerData.ped, 0.5, 0.0, 0.0, 7.0, -1, 0.2, true)
end

--- Command_Bark
---@param ped number Ped handle
local function Command_Bark(ped)
    ClearPedTasks(ped)

    if not IsEntityPlayingAnim(ped, "creatures@rottweiler@amb@world_dog_barking@idle_a", "idle_a", 3) then
        RequestAnimDict("creatures@rottweiler@amb@world_dog_barking@idle_a")
        while not HasAnimDictLoaded("creatures@rottweiler@amb@world_dog_barking@idle_a") do
            Wait(0)
        end

        TaskPlayAnim(ped, "creatures@rottweiler@amb@world_dog_barking@idle_a", "idle_a", 8.0, -4.0, -1, 1, 0.0)
    end
end

--- Command_Lay
---@param ped number Ped handle
local function Command_Lay(ped)
    ClearPedTasks(ped)

    if not IsEntityPlayingAnim(ped, "creatures@rottweiler@amb@sleep_in_kennel@", "sleep_in_kennel", 3) then
        RequestAnimDict("creatures@rottweiler@amb@sleep_in_kennel@")
        while not HasAnimDictLoaded("creatures@rottweiler@amb@sleep_in_kennel@") do
            Wait(0)
        end

        TaskPlayAnim(ped, "creatures@rottweiler@amb@sleep_in_kennel@", "sleep_in_kennel", 8.0, -4.0, -1, 1, 0.0)
    end
end

--- Command_Attack
---@param ped number Ped handle
local function Command_Attack(ped)
    DetachEntity(ped)
    local target = nil
    local selectedPlayer = VFW.StartSelect(30.0, true)

    if selectedPlayer ~= nil then
        target = GetPlayerPed(selectedPlayer)
    else
        return
    end

    ClearPedTasks(ped)

    if target and IsEntityAPed(target) then
        isAttacking = true
        TaskCombatPed(ped, target, 0, 16)

        CreateThread(function()
            while isAttacking and not IsPedDeadOrDying(target, true) do
                SetPedMoveRateOverride(ped, 1.25)
                Wait(0)
            end
        end)
    end
end

--- EnterVehicle
---@param ped number Ped handle
---@return any
local function EnterVehicle(ped)
    if not IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
        ShowNotification("Vous devez être dans un véhicule", "ROUGE")
        return
    end

    ClearPedTasks(ped)
    local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
    local vehHeading = GetEntityHeading(vehicle)

    TaskGoToEntity(ped, vehicle, -1, 0.5, 100, 1073741824, 0)
    TaskAchieveHeading(ped, vehHeading, -1)

    RequestAnimDict("creatures@rottweiler@in_vehicle@van")
    RequestAnimDict("creatures@rottweiler@amb@world_dog_sitting@base")

    while not HasAnimDictLoaded("creatures@rottweiler@in_vehicle@van") or
            not HasAnimDictLoaded("creatures@rottweiler@amb@world_dog_sitting@base") do
        Wait(0)
    end

    TaskPlayAnim(ped, "creatures@rottweiler@in_vehicle@van", "get_in", 8.0, -4.0, -1, 2, 0.0)
    Wait(700)
    ClearPedTasks(ped)
    AttachEntityToEntity(ped, vehicle, GetEntityBoneIndexByName(vehicle, "seat_pside_r"), 0.0, 0.0, 0.25)
    TaskPlayAnim(ped, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 8.0, -4.0, -1, 2, 0.0)
end

--- ExitVehicle
---@param ped number Ped handle
local function ExitVehicle(ped)
    local vehicle = GetEntityAttachedTo(ped)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        ShowNotification("Le chien n'est pas dans un véhicule", "ROUGE")
        return
    end

    local vehPos = GetEntityCoords(vehicle)
    local forwardX = GetEntityForwardVector(vehicle).x * 3.7
    local forwardY = GetEntityForwardVector(vehicle).y * 3.7
    local _, groundZ = GetGroundZFor_3dCoord(vehPos.x, vehPos.y, vehPos.z, 0)

    ClearPedTasks(ped)
    DetachEntity(ped)
    SetEntityCoords(ped, vehPos.x - forwardX, vehPos.y - forwardY, groundZ)
    Command_Follow(ped)
end

--- DismissDog
---@param ped number Ped handle
local function DismissDog(ped)
    ClearPedTasks(ped)
    DeletePed(ped)
    RemoveBlip(k9Blip)

    k9Dog = nil
    k9DogName = nil
    k9Blip = nil
end

--- BuildK9Items - Builds K9 menu items into the given VUI menu
--- Called from menu.lua for police and USSS tool submenus
---@param menu table VUI menu/submenu to add items to
function BuildK9Items(menu)
    _k9ActiveMenu = menu

    if not k9Dog then
        menu.Button("Nom du chien", nil, k9DogName, nil, false, function()
            local result = VFW.Nui.KeyboardInput(true, "Nom du chien")
            if result then
                k9DogName = result
            end

            menu.refresh()
        end)

        menu.List("Race du chien", nil, false, DOG_BREEDS, currentDogIndex, function(index, item)
            currentDogIndex = index
        end)

        menu.Button("Appeler le chien", nil, nil, "chevron", false, function()
            if not k9DogName then
                ShowNotification("Vous devez donner un nom au chien !", "ROUGE")
                return
            end

            local model = DOG_MODELS[currentDogIndex]
            RequestModel(joaat(model))
            while not HasModelLoaded(joaat(model)) do
                Wait(0)
            end

            local pos = GetOffsetFromEntityInWorldCoords(VFW.PlayerData.ped, 0.0, 2.0, 0.0)
            local heading = GetEntityHeading(VFW.PlayerData.ped)
            local _, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)

            k9Dog = VFW.OneSync.CreatePed(28, model, vector3(pos.x, pos.y, groundZ), heading)

            GiveWeaponToPed(k9Dog, joaat('WEAPON_ANIMAL'), true, true)
            SetBlockingOfNonTemporaryEvents(k9Dog, true)
            SetPedFleeAttributes(k9Dog, 0, false)
            SetPedCombatAttributes(k9Dog, 3, true)
            SetPedCombatAttributes(k9Dog, 46, true)
            SetPedCombatAttributes(k9Dog, 58, true)

            k9Blip = AddBlipForEntity(k9Dog)
            SetBlipAsFriendly(k9Blip, true)
            SetBlipScale(k9Blip, 0.5)
            SetBlipDisplay(k9Blip, 2)
            SetBlipShowCone(k9Blip, true)
            SetBlipAsShortRange(k9Blip, false)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(k9DogName)
            EndTextCommandSetBlipName(k9Blip)

            Command_Follow(k9Dog)

            -- Thread de surveillance de la mort du chien
            local dogRef = k9Dog
            CreateThread(function()
                while dogRef and DoesEntityExist(dogRef) and k9Dog == dogRef do
                    if IsPedDeadOrDying(dogRef, true) then
                        ShowNotification(k9DogName .. " a été tué.", "ROUGE")
                        DismissDog(dogRef)
                        if _k9ActiveMenu then
                            _k9ActiveMenu.refresh()
                        end
                        break
                    end
                    Wait(1000)
                end
            end)

            menu.refresh()
        end)
    else
        if IsPedDeadOrDying(k9Dog, true) then
            ShowNotification(k9DogName .. " a été tué !", "ROUGE")
            DismissDog(k9Dog)
            menu.refresh()
            return
        end

        menu.Button("Assis", nil, nil, "chevron", false, function()
            Command_Sit(k9Dog)
        end)

        menu.Button("Suivre/Rappeler", nil, nil, "chevron", false, function()
            Command_Follow(k9Dog)
        end)

        menu.Button("Pas bouger", nil, nil, "chevron", false, function()
            Command_Stay(k9Dog)
        end)

        menu.Button("Aboyer", nil, nil, "chevron", false, function()
            Command_Bark(k9Dog)
        end)

        menu.Button("Couché", nil, nil, "chevron", false, function()
            Command_Lay(k9Dog)
        end)

        menu.Button("Réclamer", nil, nil, "chevron", false, function()
            Command_Beg(k9Dog)
        end)

        menu.Button("Donner la patte", nil, nil, "chevron", false, function()
            Command_Paw(k9Dog)
        end)

        menu.Button(isAttacking and "Arrêter l'attaque" or "Attaquer", nil, nil, "chevron", false, function()
            if isAttacking then
                isAttacking = false
                ClearPedTasksImmediately(k9Dog)
                ShowNotification("Le chien a arrêté l'attaque.", "VERT")
                menu.refresh()
            else
                menu.SaveIndex()
                menu.close()
                Wait(200)
                Command_Attack(k9Dog)
                Wait(300)
                menu.open()
            end
        end)

        menu.Button("Recherche Stupéfiant ou Armes", nil, nil, "chevron", false, function()
            menu.close()
            Wait(200)

            local target = VFW.StartSelect(30.0, true)

            if target == nil then
                ShowNotification("Aucun joueur sélectionné.", "ROUGE")
                menu.open()
                return
            end

            -- Le chien va vers la cible et renifle
            local targetPed = GetPlayerPed(target)
            if targetPed and DoesEntityExist(targetPed) then
                ClearPedTasks(k9Dog)
                TaskGoToEntity(k9Dog, targetPed, -1, 1.0, 7.0, 1073741824, 0)
                Wait(2000)
                Command_Bark(k9Dog)
            end

            TriggerServerEvent("vfw:k9:searchItems", GetPlayerServerId(target))
            Wait(300)
            menu.open()
        end)

        menu.Button("Entrer dans le véhicule", nil, nil, "chevron", false, function()
            EnterVehicle(k9Dog)
        end)

        menu.Button("Sortir du véhicule", nil, nil, "chevron", false, function()
            ExitVehicle(k9Dog)
        end)

        menu.Button("Renvoyer le chien", nil, nil, "chevron", false, function()
            DismissDog(k9Dog)
            menu.refresh()
        end)
    end
end
