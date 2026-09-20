---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Jobs.Menu.CustomFaction = {
    lspd = {
        Point = {
            Ped = {
                { pedModel = "s_m_y_cop_01", coords = {
                    {x = -1069.37, y = -878.75, z = 4.0},
                    {x = -1074.46, y = -792.21, z = 3.87},
                    {x = 463.27, y = -1019.18, z = 27.1},
                }, zone = {
                    name = "menu_custom_lspd",
                    interactLabel = "Custom",
                    interactKey = "E",
                    interactIcons = "Custom",
                    onPress = function()
                        if VFW.PlayerData.job.onDuty then
                            if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
                                local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                                if GetVehicleClass(veh) == 18 then
                                    VFW.Jobs.Menu.MenuCustom(veh)
                                else
                                    VFW.ShowNotification({
                                        type = 'ROUGE',
                                        content = "Ceci n'est pas un véhicule de fonction"
                                    })
                                end
                            end
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Vous devez être en service pour accéder à cette fonctionnalité."
                            })
                        end
                    end
                }, blip = { sprite = 402, color = 29, scale = 0.5, label = "LSPD - Menu Custom"}},
            },
        }
    },
    lssd = {
        Point = {
            Ped = {
                { pedModel = "s_m_y_cop_01", coords = {
                    {x = 1870.61, y = 3688.44, z = 32.81},
                    {x = -458.83, y = 7125.59, z = 20.63},
                }, zone = {
                    name = "menu_custom_lssd",
                    interactLabel = "Custom",
                    interactKey = "E",
                    interactIcons = "Custom",
                    onPress = function()
                        if VFW.PlayerData.job.onDuty then
                            if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
                                local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                                if GetVehicleClass(veh) == 18 then
                                    VFW.Jobs.Menu.MenuCustom(veh)
                                else
                                    VFW.ShowNotification({
                                        type = 'ROUGE',
                                        content = "Ceci n'est pas un véhicule de fonction"
                                    })
                                end
                            end
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Vous devez être en service pour accéder à cette fonctionnalité."
                            })
                        end
                    end
                }, blip = { sprite = 402, color = 17, scale = 0.5, label = "LSSD - Menu Custom"}},
            },
        }
    },
    lsfd = {
        Point = {
            Ped = {
                { pedModel = "s_m_y_cop_01", coords = {
                    {x = -1044.21, y = -1325.99, z = 4.25},
                   vector3(-437.89, 7056.32, 21.19)
                }, zone = {
                    name = "menu_custom_lsfd",
                    interactLabel = "Custom",
                    interactKey = "E",
                    interactIcons = "Custom",
                    onPress = function()
                        if VFW.PlayerData.job.onDuty then
                            if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
                                local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                                if GetVehicleClass(veh) == 18 then
                                    VFW.Jobs.Menu.MenuCustom(veh)
                                else
                                    VFW.ShowNotification({
                                        type = 'ROUGE',
                                        content = "Ceci n'est pas un véhicule de fonction"
                                    })
                                end
                            end
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Vous devez être en service pour accéder à cette fonctionnalité."
                            })
                        end
                    end
                }, blip = { sprite = 402, color = 1, scale = 0.5, label = "LSFD - Menu Custom"}},
            },
        }
    },
    sams = {
        Point = {
            Ped = {
                { pedModel = "s_m_y_cop_01", coords = {
                    {x = 320.86, y = -541.31, z = 27.75},
                    {x = -576.84, y = 7385.65, z = 11.83},
                }, zone = {
                    name = "menu_custom_sams",
                    interactLabel = "Custom",
                    interactKey = "E",
                    interactIcons = "Custom",
                    onPress = function()
                        if VFW.PlayerData.job.onDuty then
                            if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
                                local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                                if GetVehicleClass(veh) == 18 then
                                    VFW.Jobs.Menu.MenuCustom(veh)
                                else
                                    VFW.ShowNotification({
                                        type = 'ROUGE',
                                        content = "Ceci n'est pas un véhicule de fonction"
                                    })
                                end
                            end
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Vous devez être en service pour accéder à cette fonctionnalité."
                            })
                        end
                    end
                }, blip = { sprite = 402, color = 2, scale = 0.5, label = "SAMS - Menu Custom"}},
            },
        }
    },
    usss = {
        Point = {
            Ped = {
                { pedModel = "s_m_y_cop_01", coords = {
                    {x = 2575.1, y = -381.18, z = 91.99},
                }, zone = {
                    name = "menu_custom_usss",
                    interactLabel = "Custom",
                    interactKey = "E",
                    interactIcons = "Custom",
                    onPress = function()
                        if VFW.PlayerData.job.onDuty then
                            if IsPedInAnyVehicle(VFW.PlayerData.ped, false) then
                                local veh = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
                                if GetVehicleClass(veh) == 18 then
                                    VFW.Jobs.Menu.MenuCustom(veh)
                                else
                                    VFW.ShowNotification({
                                        type = 'ROUGE',
                                        content = "Ceci n'est pas un véhicule de fonction"
                                    })
                                end
                            end
                        else
                            VFW.ShowNotification({
                                type = 'ROUGE',
                                content = "Vous devez être en service pour accéder à cette fonctionnalité."
                            })
                        end
                    end
                }, blip = { sprite = 402, color = 3, scale = 0.5, label = "USSS - Menu Custom"}},
            },
        }
    },
}
