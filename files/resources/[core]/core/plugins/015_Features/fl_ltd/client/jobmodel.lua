local model <const> = JobModel.new("ltd")
:setLabel("LTD Livraison")
:activateBuilder("ltd")
:activateBuilder("catalog")
:addAddonField({
    type = "number",
    name = "pricePerBox",
    label = "Prix par carton (joueur)"
})
:addAddonField({
    type = "number",
    name = "pricePerBoxSociety",
    label = "Prix par carton (entreprise)"
})
:addAddonField({
    type = "string",
    name = "vehicle",
    label = "Véhicule requis"
})
