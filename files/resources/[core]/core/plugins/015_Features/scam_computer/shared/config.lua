---@meta _
---@diagnostic disable: duplicate-doc-field

-- =====================================================================
-- Scam Computer — Configuration partagée (client + serveur)
-- Chargée via shared_scripts ("plugins/**/shared/**")
-- =====================================================================

ScamConfig = {}

-- Item d'inventaire qui ouvre le terminal (déclaré dans la table `items`)
ScamConfig.Item = "scam_tablet"

-- L'item est-il consommé à l'utilisation ? (une tablette ne se consomme pas)
ScamConfig.ConsumeItem = false

-- Multiplicateur appliqué au montant retiré vers l'argent liquide du joueur
ScamConfig.RewardMultiplier = 1.0

-- Plafond de sécurité anti-abus : montant maximal retirable en une fois
ScamConfig.MaxWithdraw = 1000000

-- Animation jouée lorsque le terminal est ouvert
ScamConfig.Animation = {
    dict = "amb@world_human_seat_wall_tablet@female@base",
    name = "base",
}
