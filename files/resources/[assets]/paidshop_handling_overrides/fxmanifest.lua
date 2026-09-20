fx_version 'cerulean'
game 'gta5'

author 'EVE'
description 'Reglages de handling des vehicules de la boutique, equilibres RP par tier'
version '1.0.0'

-- 31 handlings RP-balanced pour la boutique payante
-- 21 véhicules custom (gutti, fjesko, bmwg07, ftecnica, etc.) +
-- 10 overrides vanilla (sultan, buffalo2, sultanrs, comet5, kuruma2, etc.)
--
-- Voir docs/plans/2026-05-05-paidshop-vehicles-handling.md pour le détail
-- des tiers, philosophie d'équilibrage et audit prod.

files {
    'data/handling.meta',
}

data_file 'HANDLING_FILE' 'data/handling.meta'
