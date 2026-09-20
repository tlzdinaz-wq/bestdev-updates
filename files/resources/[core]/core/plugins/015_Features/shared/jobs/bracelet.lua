---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Jobs.Menu.Bracelet = {
    ["lspd"] = {
        Point = {
            { coords = {
                vector3(475.32, -1013.91, 25.21),
                vector3(-1110.14, -855.85, 3.87),
            }, zone = {
                name = "bracelet_lspd",
                interactLabel = "Bracelet",
                interactKey = "E",
                interactIcons = "point",
                onPress = function()
                    if VFW.PlayerData.job.onDuty then
                        Wait(150)
                        local playerId = VFW.StartSelect(5.0, true)
                        if playerId then
                            TriggerServerEvent("core:jobs:setBracelet", GetPlayerServerId(playerId))
                        end
                    else
                        VFW.ShowNotification({
                            type = 'ROUGE',
                            content = "Vous devez être en service pour accéder à cette fonctionnalité."
                        })
                    end
                end
            }, blip = { sprite = 189, color = 29, scale = 0.5, label = "LSPD - Bracelet"}},
        }
    },

    ["lssd"] = {
        Point = {
            { coords = {
                vector3(1829.68, 3686.59, 28.66),
            }, zone = {
                name = "bracelet_lssd",
                interactLabel = "Bracelet",
                interactKey = "E",
                interactIcons = "point",
                onPress = function()
                    if VFW.PlayerData.job.onDuty then
                        Wait(150)
                        local playerId = VFW.StartSelect(5.0, true)
                        if playerId then
                            TriggerServerEvent("core:jobs:setBracelet", GetPlayerServerId(playerId))
                        end
                    else
                        VFW.ShowNotification({
                            type = 'ROUGE',
                            content = "Vous devez être en service pour accéder à cette fonctionnalité."
                        })
                    end
                end
            }, blip = { sprite = 189, color = 17, scale = 0.5, label = "LSSD - Bracelet"}},
        }
    },
}
