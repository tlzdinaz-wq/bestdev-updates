CreateThread(function()
    -- l'inventaire n'expose pas de global `Inv` (local dans ses fichiers) : on attendait jusqu'à abandonner, et la
    -- radio, le mégaphone, le sac sur la tête et la tablette restaient « pas utilisables »
    local Inv = VFW.Inventory
    local tries = 0
    while (type(Inv) ~= "table" or type(Inv.RegisterUsableItem) ~= "function") and tries < 200 do
        Wait(100)
        tries = tries + 1
        Inv = VFW.Inventory
    end

    if type(Inv) ~= "table" or type(Inv.RegisterUsableItem) ~= "function" then
        console.warn("[misc_b] Inv.RegisterUsableItem indisponible, items non enregistres")
        return
    end

    local function clientEvent(event, ...)
        local extra = { ... }
        return function(xPlayer)
            if not xPlayer then return false end
            TriggerClientEvent(event, xPlayer.source, table.unpack(extra))
            return true
        end
    end

    Inv.RegisterUsableItem("scam_tablet", clientEvent("scamComputer:open"))
    Inv.RegisterUsableItem("sactete", clientEvent("headbag:client:useFromInventory"))
    Inv.RegisterUsableItem("megaphone", clientEvent("megaphone:use"))
    Inv.RegisterUsableItem("radio_public", clientEvent("radio:activated", "public"))
    Inv.RegisterUsableItem("radio_job", clientEvent("radio:activated", "job"))
end)
