--[[
    reboot_core — configuration

    Redémarrage en cascade de `core` et de tout ce qui en dépend, dans l'ordre.

    Pourquoi une cascade : redémarrer `core` seul laisse les resources qui ont
    capté l'objet partagé (exports['core']:getSharedObject()) pointant vers une
    table morte. Il faut les relancer APRÈS core, dans l'ordre de dépendance.
]]

RebootConfig = {}

RebootConfig.Command = "rebootcore"
RebootConfig.Ace     = "command.rebootcore"

--[[
    Ordre de redémarrage. Doit rester un ordre de dépendance valide :
    VUI (UI dont core déclare la dépendance) -> core -> consommateurs de core.

    Une resource absente ou non démarrée est ignorée sans erreur, la liste peut
    donc rester exhaustive même si vous désactivez des resources dans server.cfg.

    Volontairement ABSENTS de la cascade :
      - oxmysql / ox_lib : les redémarrer coupe le pool MySQL et casse toutes
        les autres resources. Ils n'ont pas besoin de connaître core.
      - WaveShield : chargé en shared_script par ~30 resources, un restart
        isolé n'a pas de sens.
]]
RebootConfig.Cascade = {
    "VUI",
    "core",
    "eve_bridge",
    "ox_doorlock",
    "lightbar",
}

-- Délai entre stop et start, et entre deux resources (ms).
RebootConfig.DelayBetween = 1500

-- Laisser à core le temps de recharger items/jobs avant de relancer la suite.
RebootConfig.CoreSettleDelay = 4000

RebootConfig.WarnPlayers = true

RebootConfig.WarnMessage =
    "Redémarrage du framework en cours, un court freeze est possible."
