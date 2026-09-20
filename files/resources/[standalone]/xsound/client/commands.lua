-- Commande streamermode déplacée dans boombox.lua

AddEventHandler("xsound:streamerMode", function(status)
    if status then
        for k, v in pairs(soundInfo) do
            Destroy(v.id)
        end
    end
end)