--- @class Society
--- Public catalog points (dynasty) - visible to all players

local catalogActive = false

local function loadPublicCatalogPoints()
    -- Stop existing marker threads
    catalogActive = false
    Wait(100)

    local points = TriggerServerCallback("vfw:dynasty:getCatalogPoints")
    if not points or #points == 0 then
        return
    end

    catalogActive = true

    for _, point in ipairs(points) do
        local pos = vector3(point.x, point.y, point.z)
        local heading = point.h or 0

        CreateThread(function()
            while catalogActive do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - pos)

                if distance < 10.0 then
                    DrawMarker(
                            25,
                            pos.x, pos.y, pos.z,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.8, 0.8, 0.8,
                            45, 135, 255, 200,
                            false, true, 2, false,
                            nil, nil, false
                    )

                    if distance < 1.5 then
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le ~b~Catalogue")

                        if VFW.Interact.JustPressed(0, 38) then
                            if heading ~= 0 then
                                SetEntityHeading(PlayerPedId(), heading)
                            end

                            if VFW.OpenDynastyTablet then
                                VFW.OpenDynastyTablet(nil, false)
                            else
                                VFW.ShowNotification({
                                    type = 'ROUGE',
                                    content = "Le catalogue n'est pas disponible pour le moment."
                                })
                            end
                        end
                    end

                    Wait(0)
                else
                    Wait(500)
                end
            end
        end)
    end
end

-- Load catalog points for all players on ready
RegisterNetEvent("vfw:playerReady", function()
    loadPublicCatalogPoints()
end)

-- Reload when a dynasty society is created or modified
RegisterNetEvent("vfw:dynasty:catalogUpdated", function()
    loadPublicCatalogPoints()
end)

-- Keep empty functions for Society.load/unload compatibility
function Society.initCatalog() end
function Society.unloadCatalog() end
