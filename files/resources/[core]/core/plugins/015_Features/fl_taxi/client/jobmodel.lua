local model <const> = JobModel.new("taxi")
:setLabel("Taxi")
:activateBuilder("taxi")
:addAddonField({
    type = "number",
    name = "tarifPerMeter",
    label = "Tarif par mètre ($)"
})
:addAddonField({
    type = "number",
    name = "playerPercent",
    label = "Pourcentage joueur (%)"
})
:addAddonField({
    type = "number",
    name = "commandTimeout",
    label = "Délai de commande (min)"
})
