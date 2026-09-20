---@meta _
---@diagnostic disable: duplicate-doc-field

local banQuery = nil

--- .BuildBansMenu
---@return any
function StaffMenu.BuildBansMenu()
    local perms = VFW.PlayerGlobalData.permissions or {}
    local firstLabel = banQuery == nil and "RECHERCHER" or "RECHERCHER:"
  local lastLabel = banQuery == nil and "UN BAN" or banQuery

    StaffMenu.bans.Button(firstLabel, lastLabel, nil, "search", false, function()
        if banQuery ~= nil then
            banQuery = nil
            StaffMenu.bans.refresh()
            return
        end

        banQuery = VFW.Nui.KeyboardInput(true, "Entrez un Ban ID")
        if banQuery == nil or banQuery == "" then
            return
        end

        StaffMenu.bans.refresh()
    end)

    StaffMenu.bans.Separator(nil)

    if next(StaffMenu.data.banList) then
        for k, v in pairs(StaffMenu.data.banList) do
            if banQuery == nil or v.id == tonumber(banQuery) then
                if perms["ban"] then
                    StaffMenu.bans.Button(v.by, v.id, nil, "chevron", false, function()
                        TriggerServerEvent("core:ban:unbanplayer", v.id)
                        banQuery = nil
                        StaffMenu.data.banList = TriggerServerCallback("core:ban:getbans") or {}
                        StaffMenu.bans.refresh()
                    end)
                else
                    StaffMenu.bans.Button(v.by, v.id, nil, nil, false, function() end)
                end
            end
        end
    end
end
