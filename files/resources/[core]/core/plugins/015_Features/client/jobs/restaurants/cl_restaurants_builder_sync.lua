local ConfigMapping = {
    burgershot = BurgerShotConfig,
    bean_coffee = BeanCoffeeConfig,
    uwu_cafe = UwuCafeConfig,
    pizzeria = PizzeriaConfig,
    pearls = PearlsConfig,
    noodle = NoodleConfig
}

RegisterNetEvent("restaurants_builder:syncConfig", function(allConfigs)
    if not allConfigs then return end
    for key, data in pairs(allConfigs) do
        local cfg = ConfigMapping[key]
        if cfg then
            cfg.DeliveryTipChance = data.tip_chance
            cfg.DeliveryTipMin = data.tip_min
            cfg.DeliveryTipMax = data.tip_max
            cfg.DeliverySocietyPercent = data.society_percent
            cfg.DeliveryStartMaxDistance = data.delivery_max_distance
            cfg.DeliveryNpcSpawnDistance = data.delivery_npc_distance
            cfg.DeliveryVehicleModels = data.vehicle_models or {}
        end
    end
end)
