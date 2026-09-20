-- Système de barre d'oxygène
local isUnderwater = false
local oxygenLevel = 100.0

CreateThread(function()
    while true do
        Wait(100)

        local ped = VFW.PlayerData.ped
        if not ped or ped == 0 then
            goto continue
        end

        -- Vérifier si le joueur est sous l'eau
        local wasUnderwater = isUnderwater
        isUnderwater = IsPedSwimmingUnderWater(ped)

        if isUnderwater and not VFW.PlayerIsDiving() then
            local maxOxygenTime = 10.0
            local oxygenTime = GetPlayerUnderwaterTimeRemaining(PlayerId())
            oxygenLevel = math.max(0, math.min(100, (oxygenTime / maxOxygenTime) * 100))

            SendNUIMessage({
                action = "nui:oxygenBar:update",
                data = {
                    visible = true,
                    percent = oxygenLevel
                }
            })
        elseif wasUnderwater and not VFW.PlayerIsDiving() then
            SendNUIMessage({
                action = "nui:oxygenBar:update",
                data = {
                    visible = false,
                    percent = 100
                }
            })
            oxygenLevel = 100.0
        end


        ::continue::
    end
end)
