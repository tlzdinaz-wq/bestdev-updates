-- Configuration mxrveuh_sirens (intégré au core)
-- Renommé Config -> SirensConfig pour éviter la collision avec le global du core.
--
--TYPE:
--    pn: Police Nationale
--    gn: Gendarmerie Nationale
--    pm: Police Municipale
--    ap: Administration Pénitentiaire
--    douane: Douane Française
--    pompiers: Pompiers
--    samu: SAMU
--    ambulance: Ambulance Privée
--    alternative: Hors service
--
--HORN:
--    1 (default): Horn Car
--    2: Horn Truck

SirensConfig = {
    { type = "pn", model = "police", horn = 1, extra = { 1, 2, 3, 4 } },
    { type = "gn", model = "meganegn", horn = 1, extra = { 1, 2, 3, 4 } },
}
