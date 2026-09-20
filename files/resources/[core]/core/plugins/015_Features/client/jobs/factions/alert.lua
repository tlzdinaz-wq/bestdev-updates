---@meta _
---@diagnostic disable: duplicate-doc-field

local alerteTable = {}

RegisterNetEvent("core:alert:callIncoming")
---@param job any
---@param pos vector3|table
---@param targetData table
---@param msg any
---@param type any
AddEventHandler("core:alert:callIncoming", function(job, pos, targetData, msg, type)
    local posPlayer = GetEntityCoords(VFW.PlayerData.ped)
    local pointA = vector3(posPlayer.x, posPlayer.y, posPlayer.z)
    local pointB = vector3(pos.x, pos.y, pos.z)
    local dist = CalculateTravelDistanceBetweenPoints(pointA.x, pointA.y, pointA.z, pointB.x, pointB.y, pointB.z)
    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(pos.x, pos.y, pos.z))
    local title = "Centrale"
    if job == "lspd" then
        title = "POLICE"
    elseif job == "sams_pib" or job == "sams_pab" then
        title = "SAMS"
    elseif job == "lssd" then
        title = "SHERIFF"
    elseif job == "lsfd" then
        title = "POMPIERS"
    elseif job == "usss" then
        title = "SECURITE"
    elseif job == "cayomilice" then
        title = "MILICE CAYO"
    elseif IsPoliceJob and IsPoliceJob(job) then
        -- saspsud / saspnord / sasp / autres jobs police — utilise le label société si dispo
        title = (Society and Society.minifiedList and Society.minifiedList[job] and Society.minifiedList[job].label and string.upper(Society.minifiedList[job].label)) or string.upper(job)
    elseif IsMiliceJob and IsMiliceJob(job) then
        title = (Society and Society.minifiedList and Society.minifiedList[job] and Society.minifiedList[job].label and string.upper(Society.minifiedList[job].label)) or string.upper(job)
    end

    VFW.ShowNotification({
        type = 'ALERTEJOBS',
        jobicon = './police.svg',
        title = targetData.name ~= '' and title or "CENTRALE",
        content = msg or '',
        name = msg or '',
        adress = streetName,
        duration = 10,
        distance = math.ceil(dist),
    })

    table.insert(alerteTable, {
        job = job,
        hour = GlobalState.OsDateHM,
        name = targetData.name ~= '' and targetData.name or "Inconnu(e)",
        street = streetName,
        mess = msg or '',
        pos = pos,
        targetData = targetData,
        type = type
    })

    PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)

    if msg and string.find(msg, "PANIC") then
        CreateThread(function()
            for _ = 1, 2 do
                Wait(500)
                PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 0)
            end
        end)
    end

    local timer = GetGameTimer() + 10000

    while true do
        if GetGameTimer() > timer then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous avez ignoré l'appel"
            })
            return
        elseif IsControlJustPressed(0, 246) then
            if type == "illegal" then
                TriggerServerEvent('core:alert:callAccept', job, pos, targetData, "illegal")
            elseif type == "drugs" then
                TriggerServerEvent('core:alert:callAccept', job, pos, targetData, "drugs")
            elseif type == "weapon" then
                TriggerServerEvent('core:alert:callAccept', job, pos, targetData, "weapon")
            else
                TriggerServerEvent('core:alert:callAccept', job, pos, targetData)
            end

            return
        elseif IsControlJustPressed(0, 306) then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous avez refusé l'appel"
            })
            return
        end

        Wait(0)
    end
end)

local blips = nil
local call = false

RegisterNetEvent("core:alert:callAccepted")
---@param pos vector3|table
---@param type any
AddEventHandler("core:alert:callAccepted", function(pos, type)
    local coords = vector3(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)

    CreateThread(function()
        SetWaypointOff()

        if call then
            RemoveBlip(blips)
            call = false
        end

        blips = AddBlipForCoord(coords)
        SetBlipScale(blips, 0.5)

        call = true

        SetBlipRoute(blips, true)

        VFW.ShowNotification({
            type = 'VERT',
            content = "Vous avez pris l'appel"
        })

        while true do
            Wait(1000)

            if #(coords - GetEntityCoords(VFW.PlayerData.ped)) < 10.0 then
                RemoveBlip(blips)
                return
            end
        end
    end)
end)

RegisterNetEvent("core:alert:takeCall")
---@param type any
AddEventHandler("core:alert:takeCall", function(type)
    if type == 'noAnswer' then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Personne ne peut venir actuellement"
        })
    elseif type == 'callAlrdyActive' then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = 'Veuillez rappeler dans quelques instants'
        })
    elseif type == "callTake" then
        VFW.ShowNotification({
            type = 'CLOCHE',
            content = "Quelqu'un arrive !"
        })
    end
end)

--- MakePanicCall
function MakePanicCall()
    local job = VFW.PlayerData and VFW.PlayerData.job
    if not job then return end

    if not job.onDuty then return end
    if job.type ~= "faction" and not IsLawEnforcementJob(job.name) then return end

    local panicMsg = "PANIC BUTTON (" .. VFW.PlayerData.lastName .. " " .. VFW.PlayerData.firstName .. ")"
    if IsPoliceJob(job.name) then
        for jobName in pairs(PoliceJobsList or {}) do
            TriggerServerEvent('core:alert:makeCall', jobName, GetEntityCoords(VFW.PlayerData.ped), false, panicMsg)
        end
    else
        TriggerServerEvent('core:alert:makeCall', job.name, GetEntityCoords(VFW.PlayerData.ped), false, panicMsg)
    end
end

local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/f5.png")
local mainmenu = VUI:CreateMenu("Historique des appels", defaultBanner, true)

--- OpenAlerteMenu
local function OpenAlerteMenu()
    if alerteTable ~= nil then
        if call then
            mainmenu.Button("Annuler le", "dernier appel", nil, "chevron", false, function()
                if call then
                    RemoveBlip(blips)
                    call = false
                end
            end)
        else
            mainmenu.Button("Aucun", "dernier appel", nil, "chevron", false, function()
                if call then
                    RemoveBlip(blips)
                    call = false
                end
            end)
        end

        for k, v in pairs(alerteTable) do
            if k >= #alerteTable - 8 and k <= #alerteTable then
                mainmenu.Button(tostring(v.mess), tostring(v.street), tostring(v.hour), nil, false, function()
                    if v.type == "illegal" then
                        TriggerServerEvent('core:alert:callAccept', v.job, v.pos, v.targetData, "illegal")
                    elseif v.type == "drugs" then
                        TriggerServerEvent('core:alert:callAccept', v.job, v.pos, v.targetData, "drugs")
                    elseif v.type == "weapon" then
                        TriggerServerEvent('core:alert:callAccept', v.job, v.pos, v.targetData, "weapon")
                    else
                        TriggerServerEvent('core:alert:callAccept', v.job, v.pos, v.targetData)
                    end

                    VFW.ShowNotification({
                        type = 'CLOCHE',
                        content = "Vous avez pris l'appel"
                    })
                end)
            end
        end
    else
        mainmenu.Button("Aucun", "appel", nil, "chevron", false, function()
            if call then
                RemoveBlip(blips)
                call = false
            end
        end)
    end

    mainmenu.toggle()
end

-- RegisterKeyMapping("+OpenAlerteMenu", "Menu appels", "keyboard", "F4")
RegisterCommand("+OpenAlerteMenu", function()
    if IsPlayerInTIG() then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Les menus sont désactivés pendant les TIG"
        })
        return
    end

    if (Death and Death.isDead) or VFW.PlayerData.dead then
        return
    end

    local jn = VFW.PlayerData.job.name
    local isLE = IsLawEnforcementJob and IsLawEnforcementJob(jn)
    if VFW.PlayerData.job.onDuty and (VFW.PlayerData.job.type == "faction" or isLE) then
        if jn == "lspd" then
            mainmenu.ChangeBanner("menu_title_police")
        elseif jn == "lssd" then
            mainmenu.ChangeBanner("menu_title_lssd")
        elseif jn == "sams_pib" or jn == "sams_pab" then
            mainmenu.ChangeBanner("menu_title_ems")
        elseif jn == "lsfd" then
            mainmenu.ChangeBanner("menu_title_lsfd")
        elseif jn == "usss" then
            mainmenu.ChangeBanner("menu_title_usss")
        elseif IsPoliceJob and IsPoliceJob(jn) then
            mainmenu.ChangeBanner("menu_title_" .. jn)
        elseif IsMiliceJob and IsMiliceJob(jn) then
            mainmenu.ChangeBanner("menu_title_" .. jn)
        end

        OpenAlerteMenu()
    end
end)
