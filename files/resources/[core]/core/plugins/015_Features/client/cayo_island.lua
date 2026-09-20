-- ══════════════════════════════════════════════════════════════════
-- Cayo Perico — chargement dynamique de l'île
-- ══════════════════════════════════════════════════════════════════
-- L'île de Cayo Perico n'est PAS chargée par défaut sur FiveM (même
-- avec le bon gamebuild). On l'active via l'« island hopper » quand le
-- joueur s'en approche, et on restaure Los Santos quand il s'éloigne.
--
-- ⚠️ Ce native échange la map : la ville et l'île ne sont pas chargées
-- en même temps. Le basculement se fait loin en mer, donc invisible en
-- pratique. (Pour avoir les deux maps simultanément il faut une
-- ressource IPL d'île séparée — voir avec le dev si souhaité.)
-- ══════════════════════════════════════════════════════════════════

-- Centre de l'île de Cayo Perico (milieu du terrain, pas la plage sud).
local ISLAND_CENTER = vector3(4920.0, -5400.0, 10.0)
-- Rayon d'activation : assez large pour le streaming à l'approche, mais
-- BIEN inférieur à la distance du port sud de LS (~4500 u) pour ne JAMAIS
-- décharger Los Santos quand on est sur le continent.
local ENABLE_RADIUS = 3000.0

local islandActive = false

local function setIsland(state)
    -- SET_ISLAND_HOPPER_ENABLED : charge le terrain de l'île / retire la ville
    Citizen.InvokeNative(0x9A9D1BA639675CF1, "HeistIsland", state)
    -- bascule la minimap / map de pause sur celle de l'île
    Citizen.InvokeNative(0x5E1460624D194A38, state)
    islandActive = state
end

CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local near = #(coords - ISLAND_CENTER) < ENABLE_RADIUS

        if near and not islandActive then
            setIsland(true)
        elseif not near and islandActive then
            setIsland(false)
        end

        Wait(2000)
    end
end)
