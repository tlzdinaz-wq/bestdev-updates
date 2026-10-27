-- L'ajout, la modification et le retrait d'une zone sont reçus dans function.lua (zonesafe:client:add / update /
-- remove). Ici : ce que le serveur demande au joueur quand il entre dans une zone.

-- Entrée dans une zone où sortir une arme est interdit : on range celle qu'il a en main.
RegisterNetEvent('zonesafe:client:holster', function()
    local ped = PlayerPedId()
    if GetSelectedPedWeapon(ped) == `WEAPON_UNARMED` then
        return
    end

    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    LastWeaponId = nil
end)
