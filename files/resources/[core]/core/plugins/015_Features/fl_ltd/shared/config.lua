LTDDelivery = LTDDelivery or {}

LTDDelivery.Config = {
    -- Le LTD fonctionne maintenant comme une boutique publique classique.
    -- L'ancien métier, son catalogue de société et ses missions sont désactivés.
    EnableJobSystem = false,
    EnableSocietyCatalog = false,
    SimpleShopMode = true,

    BoxProp = "prop_cs_cardbox_01",
    BoxAnim = {
        dict = "anim@heists@box_carry@",
        name = "idle"
    },
    Cooldown = 2000,

    DefaultPricePerBox = 150,
    DefaultPricePerBoxSociety = 50,
    DefaultVehicle = "speedo",

    DefaultNpcModel = "a_m_m_indian_01",
    DefaultNpcName = "Client",
    NpcSpawnDistance = 50.0
}
