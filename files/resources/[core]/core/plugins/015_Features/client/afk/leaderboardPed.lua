-- ========================================================================
-- AFK FULL RANKING NPC
-- Spawns a ped inside the AFK zone that opens a UI with the full VIP-points ranking
-- ========================================================================

local rankingNPC = nil
local isRankingOpen = false

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))
    local scale = (1 / dist) * 2 * ((1 / GetGameplayCamFov()) * 100)
    SetTextScale(0.0, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

local function SpawnRankingNPC()
    local cfg = AFKConfig.RankingNPC
    if not cfg then return end
    if rankingNPC and DoesEntityExist(rankingNPC) then return end

    local model = GetHashKey(cfg.model)
    VFW.Streaming.RequestModel(model)

    rankingNPC = CreatePed(4, model, cfg.position.x, cfg.position.y, cfg.position.z, cfg.heading, false, true)

    if DoesEntityExist(rankingNPC) then
        Wait(100)
        local groundZ = cfg.position.z
        local found, z = GetGroundZFor_3dCoord(cfg.position.x, cfg.position.y, cfg.position.z + 2.0, false)
        if found then groundZ = z end
        SetEntityCoords(rankingNPC, cfg.position.x, cfg.position.y, groundZ, false, false, false, false)
        SetEntityHeading(rankingNPC, cfg.heading)
        FreezeEntityPosition(rankingNPC, true)
        SetEntityInvincible(rankingNPC, true)
        SetBlockingOfNonTemporaryEvents(rankingNPC, true)
        SetPedCanRagdoll(rankingNPC, false)
        TaskStartScenarioInPlace(rankingNPC, "WORLD_HUMAN_CLIPBOARD", 0, true)
    end

    SetModelAsNoLongerNeeded(model)
end

local function CleanupRankingNPC()
    if rankingNPC and DoesEntityExist(rankingNPC) then
        DeleteEntity(rankingNPC)
    end
    rankingNPC = nil
end

local function CloseRanking()
    if not isRankingOpen then return end
    isRankingOpen = false
    SendNUIMessage({ action = 'vipRanking:hide' })
    VFW.Nui.Focus(false)
end

local function OpenRanking()
    if isRankingOpen then return end
    local payload = TriggerServerCallback('core:afk:getFullLeaderboard')
    if not payload then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de récupérer le classement" })
        return
    end
    isRankingOpen = true
    SendNUIMessage({
        action = 'vipRanking:show',
        data = payload,
    })
    VFW.Nui.Focus(true, false)
end

local function StartInteractionLoop()
    CreateThread(function()
        local cfg = AFKConfig.RankingNPC
        while exports['core']:IsInAFKZone() do
            local sleep = 500
            if rankingNPC and DoesEntityExist(rankingNPC) then
                local ped = PlayerPedId()
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(rankingNPC))
                if dist < (cfg.interactionRadius or 2.0) then
                    sleep = 0
                    local npcCoords = GetEntityCoords(rankingNPC)
                    DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, "~y~[E]~w~ Classement AFK")
                    if VFW.Interact.JustPressed(0, 38) and not isRankingOpen then
                        OpenRanking()
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

RegisterNetEvent('core:afk:entered', function()
    SetTimeout(1000, function()
        SpawnRankingNPC()
        StartInteractionLoop()
    end)
end)

RegisterNetEvent('core:afk:exited', function()
    CloseRanking()
    CleanupRankingNPC()
end)

RegisterNUICallback('vipRanking:close', function(_, cb)
    CloseRanking()
    cb({})
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupRankingNPC()
    end
end)
