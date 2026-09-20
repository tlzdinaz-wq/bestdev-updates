---@meta _
---@diagnostic disable: duplicate-doc-field

local inSelect = false
local forceStop = false

-- Les staffs en noclip ou en spectate sont invisibles/intangibles: les exclure
-- de la sélection évite de cibler quelqu'un qu'on ne voit pas. États sync via
-- state bags 'noclipPed' / 'spectatePed' posés dans staff/noclip.lua.
local function filterNoclipPlayers(players)
    local filtered = {}
    for i = 1, #players do
        local pid = players[i]
        local ped = GetPlayerPed(pid)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            local st = Entity(ped).state
            if not st.noclipPed and not st.spectatePed then
                filtered[#filtered + 1] = pid
            end
        end
    end
    return filtered
end

--- .StartSelect
---@param dist any
---@param ignoreSelf any
---@return any
function VFW.StartSelect(dist, ignoreSelf)
    if inSelect then
        return
    end

    -- Check players before showing selection UI
    local initialPlayersList = filterNoclipPlayers(VFW.Game.GetPlayersInArea(GetEntityCoords(VFW.PlayerData.ped), dist, ignoreSelf and {VFW.playerId} or nil))

    -- If no players nearby, return nil immediately
    if #initialPlayersList == 0 then
        return nil
    end

    if #initialPlayersList == 1 then
        return initialPlayersList[1]
    end


    inSelect = true
    SendNUIMessage({
        action = "instructionalBar:show",
        data = {
            items = {
                { keys = { "E" }, label = "Sélectionner" },
                { keys = { "Y" }, label = "Changer" },
                { keys = { "N" }, label = "Annuler" },
            }
        }
    })

    VFW.DisableInterations(true)

    local playerSelected

    while inSelect do
        local playersList = filterNoclipPlayers(VFW.Game.GetPlayersInArea(GetEntityCoords(VFW.PlayerData.ped), dist, ignoreSelf and {VFW.playerId} or nil))
        local selectedHear = false

        for i = 1, #playersList do
            if playersList[i] == playerSelected then
                selectedHear = true
                break
            end
        end

        if not selectedHear then
            playerSelected = playersList[1]
        end

        if playerSelected then
            DrawMarker(21, GetEntityCoords(GetPlayerPed(playerSelected))+vec3(0,0,1), .0, .0, .0, .0, 180.0, .0, .3, .3, .3, 114, 99, 238, 200, 0, 0, 2, 1, nil, nil, 0)
        end

        if VFW.Interact.JustPressed(0, 38) then
            inSelect = false
        elseif IsControlJustPressed(0, 246) then
            if playerSelected then
                for i = 1, #playersList do
                    if playersList[i] == playerSelected then
                        if playersList[i+1] then
                            playerSelected = playersList[i+1]
                        else
                            playerSelected = playersList[1]
                        end

                        break
                    end
                end
            end
        elseif IsControlJustPressed(0, 306) or forceStop then
            inSelect = false
            playerSelected = nil
        end

        Wait(0)
    end

    forceStop = false
    inSelect = false
    VFW.DisableInterations(false)
    SendNUIMessage({
        action = "instructionalBar:hide"
    })
    return playerSelected
end

--- .ForceStopSelect
function VFW.ForceStopSelect()
    if inSelect then
        forceStop = true
    end
end