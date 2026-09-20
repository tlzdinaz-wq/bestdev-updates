---@meta _
---@diagnostic disable: duplicate-doc-field

-- DVM Checkpoint Editor - Client
-- Staff tool for creating new driving exam routes
-- Context menu integration is in world_context_menu.lua

-- State variables exposed via VFW for context menu access
VFW.DVMRouteRecording = false
VFW.DVMCurrentRoute = nil

-- Initialize route recording
function VFW.DVMStartRouteRecording(category, examCenterId)
    VFW.DVMRouteRecording = true
    VFW.DVMCurrentRoute = {
        category = category,
        examCenter = examCenterId,
        checkpoints = {}
    }

    VFW.ShowNotification({
        type = 'success',
        content = string.format("Enregistrement de route commencé: %s (Centre %d)", category, examCenterId),
        duration = 5
    })
end

-- Add checkpoint to current route
function VFW.DVMAddCheckpoint(coords)
    if not VFW.DVMRouteRecording then
        VFW.ShowNotification({
            type = 'error',
            content = "Aucune route en cours d'enregistrement",
            duration = 3
        })
        return
    end

    -- Use CreateThread with delay to allow context menu to close first
    Wait(500)  -- Allow context menu to close and release focus

    local speedInput = VFW.Nui.KeyboardInput(true, "Limite de vitesse (30-130 km/h)")
    if not speedInput or speedInput == "" then
        VFW.ShowNotification({
            type = 'warning',
            content = "Ajout de checkpoint annulé",
            duration = 3
        })
        return
    end

    local speed = tonumber(speedInput)
    if not speed or speed < 30 or speed > 130 then
        VFW.ShowNotification({
            type = 'error',
            content = "Cette vitesse n'est pas valide. Entrez un nombre entre 30 et 130",
            duration = 3
        })
        return
    end

    table.insert(VFW.DVMCurrentRoute.checkpoints, {
        coords = coords,
        speed = speed
    })

    VFW.ShowNotification({
        type = 'success',
        content = string.format("Checkpoint #%d ajouté (limite: %d km/h)", #VFW.DVMCurrentRoute.checkpoints, speed),
        duration = 3
    })
end

-- Remove last checkpoint
function VFW.DVMRemoveLastCheckpoint()
    if not VFW.DVMRouteRecording or #VFW.DVMCurrentRoute.checkpoints == 0 then
        VFW.ShowNotification({
            type = 'error',
            content = "Aucun checkpoint à supprimer",
            duration = 3
        })
        return
    end

    table.remove(VFW.DVMCurrentRoute.checkpoints)
    VFW.ShowNotification({
        type = 'success',
        content = string.format("Checkpoint supprimé. Total: %d", #VFW.DVMCurrentRoute.checkpoints),
        duration = 3
    })
end

-- Finish and export route
function VFW.DVMFinishRoute()
    if not VFW.DVMRouteRecording then
        VFW.ShowNotification({
            type = 'error',
            content = "Aucune route en cours d'enregistrement",
            duration = 3
        })
        return
    end

    if #VFW.DVMCurrentRoute.checkpoints < 2 then
        VFW.ShowNotification({
            type = 'error',
            content = "Au moins 2 checkpoints requis",
            duration = 3
        })
        return
    end

    Wait(500)  -- Allow context menu to close

    -- Get route name via input box
    local nameInput = VFW.Nui.KeyboardInput(true, "Nom de la route")
    if not nameInput or nameInput == "" or #nameInput < 3 then
        VFW.ShowNotification({
            type = 'error',
            content = "Ce nom n'est pas valide (minimum 3 caractères)",
            duration = 3
        })
        return
    end

    VFW.DVMCurrentRoute.name = nameInput

    -- Get route description via input box
    local descriptionInput = VFW.Nui.KeyboardInput(true, "Description de la route")
    if not descriptionInput or descriptionInput == "" or #descriptionInput < 5 then
        VFW.ShowNotification({
            type = 'error',
            content = "Cette description n'est pas valide (minimum 5 caractères)",
            duration = 3
        })
        return
    end

    VFW.DVMCurrentRoute.description = descriptionInput

    -- Send to server for export (formatted output will come back via callback)
    TriggerServerEvent("dvm:editor:export", VFW.DVMCurrentRoute)

    -- Reset state
    VFW.DVMRouteRecording = false
    VFW.DVMCurrentRoute = nil

    VFW.ShowNotification({
        type = 'success',
        content = "Route exportée! Consultez votre console F8",
        duration = 5
    })
end

-- Cancel route recording
function VFW.DVMCancelRoute()
    if not VFW.DVMRouteRecording then
        VFW.ShowNotification({
            type = 'error',
            content = "Aucune route en cours d'enregistrement",
            duration = 3
        })
        return
    end

    VFW.DVMRouteRecording = false
    VFW.DVMCurrentRoute = nil

    VFW.ShowNotification({
        type = 'warning',
        content = "Enregistrement de route annulé",
        duration = 3
    })
end

-- Visual feedback thread
CreateThread(function()
    while true do
        if VFW.DVMRouteRecording and VFW.DVMCurrentRoute and #VFW.DVMCurrentRoute.checkpoints > 0 then
            local checkpoints = VFW.DVMCurrentRoute.checkpoints

            -- Draw checkpoint markers and numbers
            for i, cp in ipairs(checkpoints) do
                local coords = cp.coords

                -- Draw yellow cylinder marker
                DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    3.0, 3.0, 2.0, 255, 255, 0, 200, false, true, 2, false, nil, nil, false)

                -- Draw checkpoint number
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z + 1.0)
                if onScreen then
                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(255, 255, 255, 255)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    SetTextCentre(true)
                    AddTextComponentString(tostring(i))
                    DrawText(screenX, screenY)
                end

                -- Draw line to next checkpoint
                if i < #checkpoints then
                    local nextCoords = checkpoints[i + 1].coords
                    DrawLine(coords.x, coords.y, coords.z, nextCoords.x, nextCoords.y, nextCoords.z, 0, 255, 0, 200)
                end
            end

            -- Draw on-screen info
            local examCenterName = Config.DVM.ExamCenters[VFW.DVMCurrentRoute.examCenter] and
                                   Config.DVM.ExamCenters[VFW.DVMCurrentRoute.examCenter].name or
                                   "Centre " .. VFW.DVMCurrentRoute.examCenter

            SetTextScale(0.4, 0.4)
            SetTextFont(4)
            SetTextProportional(true)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(false)
            AddTextComponentString(string.format(
                "~y~Enregistrement Route DVM~w~\nCatégorie: ~b~%s~w~\nCentre: ~g~%s~w~\nCheckpoints: ~o~%d",
                VFW.DVMCurrentRoute.category,
                examCenterName,
                #VFW.DVMCurrentRoute.checkpoints
            ))
            DrawText(0.85, 0.05)

            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Handle formatted route export result from server
RegisterNetEvent("dvm:editor:exportResult")
AddEventHandler("dvm:editor:exportResult", function(formattedRoute)
    print("^2========================================^7")
    print("^3DVM Route Export - Ready to Paste^7")
    print("^2========================================^7")
    print(type(formattedRoute) == "table" and formattedRoute.json or formattedRoute)
    print("^2========================================^7")
    print("^6Copy the code above and paste into Config.DVM.DrivingRoutes[category]^7")
    print("^2========================================^7")
end)

-- Cleanup on disconnect
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        VFW.DVMRouteRecording = false
        VFW.DVMCurrentRoute = nil
    end
end)
