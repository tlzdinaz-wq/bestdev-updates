---@meta _
---@diagnostic disable: duplicate-doc-field

local dataPlayerDroppedText = {}
VFW.HidePlayerDroppedText = false

RegisterCommand('hideplayerdroppedtext', function()
    if not VFW.PlayerData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["staff_menu"] then
        return
    end

    VFW.HidePlayerDroppedText = not VFW.HidePlayerDroppedText

    if VFW.HidePlayerDroppedText then
        VFW.ShowNotification({ type = 'VERT', content = "Affichage des déconnexions désactivé." })
    else
        VFW.ShowNotification({ type = 'VERT', content = "Affichage des déconnexions activé." })
    end
end)

VFW.AddChatSuggestion('/hideplayerdroppedtext', 'Masquer/afficher les messages de déconnexion des joueurs')

local maxDistance = 2500
local viewDistance = 500

CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end

    if not VFW.PlayerData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["staff_menu"] then
        return
    end

    while true do
        if VFW.HidePlayerDroppedText then
            Wait(2500)
        else
            local counterNearPlayer = 0

            for playerId, player in pairs(dataPlayerDroppedText) do
                if GetGameTimer() > player.start + 30000 then
                    dataPlayerDroppedText[playerId] = nil
                else
                    local dist = Vdist2(GetEntityCoords(VFW.PlayerData.ped, false), player.coords.x, player.coords.y, player.coords.z)

                    local alpha
                    if dist < viewDistance then
                        alpha = 255
                    else
                        alpha = math.floor(255 - ((dist - viewDistance) / (maxDistance - viewDistance)) * 255)
                    end

                    local size
                    if dist < viewDistance then
                        size = 0.2
                    else
                        size = 0.2 - ((dist - (viewDistance-200)) / (maxDistance - (viewDistance-200))) * (0.2 - 0.1)
                    end

                    if dist < maxDistance then
                        counterNearPlayer = counterNearPlayer + 1
                        SetTextScale(0.0, size)
                        SetTextFont(0)
                        SetTextProportional(0.2)
                        SetTextColour(250, 250, 250, alpha)
                        SetTextDropshadow(1, 1, 1, 1, 255)
                        SetTextEdge(2, 0, 0, 0, 150)
                        SetTextDropShadow()
                        SetTextOutline()
                        SetTextEntry("STRING")
                        SetTextCentre(1)
                        AddTextComponentString('Le joueur ~y~ID ~s~: '..player.source_id..' (~y~UUID ~s~: '..player.id_perso..') s\'est déconnecté\n~y~Raison ~s~: '..player.reason)
                        SetDrawOrigin(player.coords.x, player.coords.y, player.coords.z, 0)
                        DrawText(0.0, 0.0)
                        ClearDrawOrigin()
                    end
                end
            end

            if next(dataPlayerDroppedText) and counterNearPlayer > 0 then
                Wait(0)
            elseif next(dataPlayerDroppedText) then
                Wait(300)
            else
                Wait(1500)
            end
        end
    end
end)

---@param data table
RegisterNetEvent('core:sendPlayerDroppedText', function(data)
    if not VFW.PlayerData or not VFW.PlayerGlobalData.permissions or not VFW.PlayerGlobalData.permissions["staff_menu"] then
        return
    end

    dataPlayerDroppedText[data.src] = {
        coords = data.coords,
        name = data.name,
        reason = data.raison,
        start = GetGameTimer(),
        id_perso = data.id_perso,
        source_id = data.source_id,
    }
end)
