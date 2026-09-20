VFW = VFW or {}

VFW.ItemDescriptions = {
    -- =====================================================
    -- MUNITIONS
    -- =====================================================
    ["ammo_airsoft"] = "Billes en plastique pour armes d'airsoft. Inoffensives mais réalistes.",
    ["ammo_beanbag"] = "Cartouche non-létale projetant un sac lesté. Utilisée pour neutraliser sans blesser.",
    ["ammo_flare"] = "Cartouche de détresse tirant une fusée lumineuse pour signaler sa position.",
    ["ammo_heavy"] = "Munitions lourdes pour mitrailleuses et armes de gros calibre.",
    ["ammo_launcher"] = "Munitions pour lance-grenades et lance-roquettes. Très destructrices.",
    ["ammo_musquet"] = "Balle ronde en plomb pour mousquet. Utilisée lors de la chasse.",
    ["ammo_pistol"] = "Munitions légères pour pistolets et revolvers.",
    ["ammo_rifle"] = "Munitions moyennes pour fusils d'assaut et carabines.",
    ["ammo_rocket"] = "Roquette explosive pour lance-missiles. Usage militaire uniquement.",
    ["ammo_shotgun"] = "Cartouches à chevrotine pour fusils à pompe.",
    ["ammo_snip"] = "Cartouches de précision pour fusils sniper.",

    -- =====================================================
    -- MATÉRIAUX ET RESSOURCES
    -- =====================================================
    ["acier"] = "Lingot d'acier utilisé dans la fabrication de plaques de protection et d'équipements.",
    ["charcoal"] = "Charbon extrait des mines.",
    ["charcoal_dirty"] = "Charbon sale récupéré en mine. Nécessite un nettoyage.",
    ["cuivre"] = "Cuivre raffiné, matériau de base pour la fabrication de munitions.",
    ["cuivre_dirty"] = "Cuivre brut extrait des mines. Doit être nettoyé.",
    ["cuivre_gpb"] = "Cuivre de qualité supérieure utilisé dans la fabrication d'item illégal.",
    ["gold"] = "Or pur extrait des mines. Très précieux.",
    ["gold_bar"] = "Lingot d'or massif. Objet de très grande valeur.",
    ["gold_dirty"] = "Or brut non raffiné, récupéré en mine. Doit être nettoyé.",
    ["papier"] = "Feuilles de papier utilisables pour diverses utilités.",
    ["poudre_noir"] = "Poudre noire explosive, ingrédient essentiel pour fabriquer des munitions.",
    ["rawwood"] = "Bûche de bois brut récoltée. Peut être transformée en planches.",
    ["tissu"] = "Rouleau de tissu utilisé dans la fabrication de gilets pare-balles et vêtements.",
    ["vis"] = "Vis métalliques utilisées comme composant de crafting.",
    ["wooden_plank"] = "Planche de bois découpée, utilisée dans la construction et le crafting.",
    ["cordes"] = "Corde solide permettant d'attacher un véhicule pour le dépanner.",
    ["pieces_arme"] = "Pièces détachées d'armes à feu, nécessaires pour le crafting d'armes illégales.",

    -- =====================================================
    -- PROTECTION / ARMURE
    -- =====================================================
    ["armor_plate_heavy"] = "Plaque de blindage lourde offrant une protection maximale (100%).",
    ["armor_plate_light"] = "Plaque de blindage légère offrant une protection basique (30%).",
    ["armor_plate_medium"] = "Plaque de blindage moyenne offrant une bonne protection (60%).",
    ["gpb"] = "Gilet pare-balles équipable. Accepte des plaques de protection (légère, moyenne ou lourde).",

    -- =====================================================
    -- BLUEPRINTS (Plans de fabrication)
    -- =====================================================
    ["blueprint_petoire"] = "Plan de fabrication pour un Pétoire (HK PM710). Nécessaire pour le craft illégal.",
    ["blueprint_microsmg"] = "Plan de fabrication pour un Micro SMG. Nécessaire pour le craft illégal.",
    ["blueprint_tec9"] = "Plan de fabrication pour un TEC-9. Nécessaire pour le craft illégal.",
    ["blueprint_pistol"] = "Plan de fabrication pour un Beretta 92 FS. Nécessaire pour le craft illégal.",
    ["blueprint_pistol50"] = "Plan de fabrication pour un Desert Eagle .50. Nécessaire pour le craft illégal.",
    ["blueprint_pumpshotgun"] = "Plan de fabrication pour un Remington 870. Nécessaire pour le craft illégal.",
    ["blueprint_sawnoffshotgun"] = "Plan de fabrication pour un fusil à canon scié. Nécessaire pour le craft illégal.",
    ["blueprint_smg"] = "Plan de fabrication pour un MP5. Nécessaire pour le craft illégal.",

    -- =====================================================
    -- COMPOSANTS D'ARMES
    -- =====================================================
    -- Chargeurs
    ["wcomponent_clip_default_pistol"] = "Chargeur standard pour pistolet. Capacité de base.",
    ["wcomponent_clip_default_smg"] = "Chargeur standard pour mitraillette. Capacité de base.",
    ["wcomponent_clip_default_rifle"] = "Chargeur standard pour fusil d'assaut. Capacité de base.",
    ["wcomponent_clip_default_mg"] = "Chargeur standard pour mitrailleuse. Capacité de base.",
    ["wcomponent_clip_default_shotgun"] = "Tube de chargement standard pour fusil à pompe.",
    ["wcomponent_clip_default_sniper"] = "Chargeur standard pour fusil de précision.",
    ["wcomponent_clip_extended_pistol"] = "Chargeur allongé pour pistolet. Capacité augmentée.",
    ["wcomponent_clip_extended_smg"] = "Chargeur allongé pour mitraillette. Capacité augmentée.",
    ["wcomponent_clip_extended_rifle"] = "Chargeur allongé pour fusil d'assaut. Capacité augmentée.",
    ["wcomponent_clip_extended_mg"] = "Chargeur allongé pour mitrailleuse. Capacité augmentée.",
    ["wcomponent_clip_extended_shotgun"] = "Chargeur allongé pour fusil à pompe. Capacité augmentée.",
    ["wcomponent_clip_extended_sniper"] = "Chargeur allongé pour fusil sniper. Capacité augmentée.",
    ["wcomponent_clip_drum_smg"] = "Chargeur tambour pour mitraillette. Grande capacité de munitions.",
    ["wcomponent_clip_drum_rifle"] = "Chargeur tambour pour fusil. Grande capacité de munitions.",
    ["wcomponent_clip_drum_shotgun"] = "Chargeur tambour pour fusil à pompe. Grande capacité.",
    ["wcomponent_clip_box_rifle"] = "Chargeur boîte pour fusil. Capacité intermédiaire.",
    -- Optiques
    ["wcomponent_scope"] = "Lunette de visée basique améliorant la précision à moyenne distance.",
    ["wcomponent_scope_small"] = "Petite lunette macro pour améliorer la visée rapprochée.",
    ["wcomponent_scope_medium"] = "Lunette moyenne offrant un bon compromis portée/visibilité.",
    ["wcomponent_scope_large"] = "Lunette longue portée pour le tir à grande distance.",
    ["wcomponent_scope_zoom"] = "Lunette à zoom variable pour le tir de précision.",
    ["wcomponent_scope_advanced"] = "Lunette avancée avec réticule amélioré et zoom supérieur.",
    ["wcomponent_scope_holo"] = "Viseur holographique pour une acquisition rapide de cible.",
    ["wcomponent_scope_nightvision"] = "Lunette à vision nocturne pour les opérations de nuit.",
    ["wcomponent_scope_thermal"] = "Lunette thermique détectant les signatures de chaleur.",
    -- Accessoires
    ["wcomponent_flashlight"] = "Lampe tactique montée sur rail pour éclairer en situation de combat.",
    ["wcomponent_suppressor"] = "Silencieux réduisant le bruit et la signature visuelle des tirs.",
    ["wcomponent_compensator"] = "Compensateur de recul améliorant la stabilité lors du tir automatique.",
    ["wcomponent_grip"] = "Poignée avant ergonomique réduisant le recul et améliorant le contrôle.",
    -- Canons
    ["wcomponent_barrel_default"] = "Canon standard offrant des performances équilibrées.",
    ["wcomponent_barrel_heavy"] = "Canon lourd améliorant la précision au détriment de la mobilité.",
    -- Freins de bouche
    ["wcomponent_muzzle_bell"] = "Frein de bouche en cloche réduisant le relèvement du canon.",
    ["wcomponent_muzzle_fat"] = "Frein de bouche large pour une réduction maximale du recul.",
    ["wcomponent_muzzle_flat"] = "Frein de bouche plat offrant un bon contrôle latéral.",
    ["wcomponent_muzzle_heavy"] = "Frein de bouche lourd pour les armes à fort recul.",
    ["wcomponent_muzzle_precision"] = "Frein de bouche de précision optimisé pour le tir à distance.",
    ["wcomponent_muzzle_slanted"] = "Frein de bouche incliné compensant la dérive latérale.",
    ["wcomponent_muzzle_split"] = "Frein de bouche divisé répartissant les gaz de manière uniforme.",
    ["wcomponent_muzzle_squared"] = "Frein de bouche carré offrant une réduction de recul polyvalente.",
    ["wcomponent_muzzle_tactical"] = "Frein de bouche tactique pour un usage opérationnel.",

    -- =====================================================
    -- ARMES - PISTOLETS
    -- =====================================================
    ["weapon_pistol"] = "Beretta 92 FS - Pistolet semi-automatique fiable et précis. Craftable avec blueprint.",
    ["weapon_combatpistol"] = "Glock 17 - Pistolet de combat robuste et polyvalent. Craftable avec blueprint.",
    ["weapon_pistol50"] = "Desert Eagle .50 - Pistolet surpuissant à gros calibre. Craftable avec blueprint.",
    ["weapon_heavypistol"] = "Colt M45 - Pistolet lourd à fort pouvoir d'arrêt. Craft MC niveau C.",
    ["weapon_snspistol"] = "HK PM710 - Petit pistolet compact facilement dissimulable. Craft Mafia niveau B.",
    ["weapon_snspistol_mk2"] = "Version améliorée du HK PM710 avec performances supérieures.",
    ["weapon_vintagepistol"] = "FN 1922 - Pistolet vintage de collection au charme rétro.",
    ["weapon_appistol"] = "Pistolet automatique avec cadence de tir élevée.",
    ["weapon_ceramicpistol"] = "Pistolet en céramique indétectable aux portiques de sécurité.",
    ["weapon_gadgetpistol"] = "Pistolet compact et discret, facile à dissimuler.",
    ["weapon_marksmanpistol"] = "Pistolet de précision à un coup, très puissant mais lent.",
    ["weapon_pistolxm3"] = "Pistolet XM3 - Modèle tactique moderne haute performance.",
    ["weapon_pistol_mk2"] = "Pistolet Beretta amélioré avec accessoires MK2.",
    ["weapon_machinepistol"] = "TEC-9 - Pistolet-mitrailleur compact à haute cadence. Craft Orga niveau B.",
    ["weapon_glock20"] = "Glock 20 - Pistolet calibre 10mm à fort pouvoir d'arrêt.",
    ["weapon_sig_saucer"] = "Sig Sauer - Pistolet de précision utilisé par les forces spéciales.",
    ["weapon_swmp9l"] = "Smith & Wesson M&P9 - Pistolet moderne fiable et ergonomique.",
    ["weapon_pdglock17"] = "Glock 17 réservé aux forces de l'ordre (PD).",

    -- =====================================================
    -- ARMES - REVOLVERS
    -- =====================================================
    ["weapon_revolver"] = "Taurus - Revolver puissant à barillet. Craft Mafia niveau B.",
    ["weapon_revolver_mk2"] = "Revolver amélioré avec performances MK2.",
    ["weapon_doubleaction"] = "Colt M1878 - Revolver double action classique. Craft MC niveau B.",
    ["weapon_navyrevolver"] = "Revolver Navy - Revolver historique de style militaire.",

    -- =====================================================
    -- ARMES - MITRAILLETTES / SMG
    -- =====================================================
    ["weapon_microsmg"] = "Mini Uzi - Micro-mitraillette compacte à haute cadence. Craftable avec blueprint.",
    ["weapon_smg"] = "H&K MP5 - Mitraillette polyvalente et précise. Craftable avec blueprint.",
    ["weapon_smg_mk2"] = "MP5 améliorée avec accessoires MK2 et meilleures performances.",
    ["weapon_minismg"] = "Skorpion VZ.61 - Mini-mitraillette ultra-compacte. Craft MC niveau B.",
    ["weapon_combatpdw"] = "Mitraillette de combat PDW pour engagements rapprochés.",
    ["weapon_assaultsmg"] = "Mitraillette d'assaut à fort taux de pénétration.",
    ["weapon_gusenberg"] = "Thompson M1928 - Mitraillette historique 'Tommy Gun'. Craft Mafia niveau A.",

    -- =====================================================
    -- ARMES - FUSILS D'ASSAUT
    -- =====================================================
    ["weapon_assaultrifle"] = "AK-47 - Fusil d'assaut emblématique, puissant et fiable. Craft Mafia/Orga niveau S.",
    ["weapon_assaultrifle_mk2"] = "AK-47 amélioré avec accessoires MK2.",
    ["weapon_carbinerifle"] = "SIG MCX - Carabine modulaire 5.56mm, version long barrel. Précise et maniable.",
    ["weapon_carbinerifle_mk2"] = "SIG MCX améliorée avec accessoires MK2.",
    ["weapon_advancedrifle"] = "Fusil avancé à haute technologie avec grande cadence de tir.",
    ["weapon_specialcarbine"] = "G36C - Carabine spéciale compacte et maniable.",
    ["weapon_specialcarbine_mk2"] = "G36C améliorée avec accessoires MK2.",
    ["weapon_bullpuprifle"] = "Fusil bullpup compact avec chargeur derrière la détente.",
    ["weapon_bullpuprifle_mk2"] = "Fusil bullpup amélioré avec accessoires MK2.",
    ["weapon_compactrifle"] = "Fusil compact adapté aux espaces restreints et véhicules.",
    ["weapon_militaryrifle"] = "AUG - Fusil militaire autrichien de haute précision.",
    ["weapon_heavyrifle"] = "SCAR-H - Fusil lourd à fort pouvoir d'arrêt.",
    ["weapon_tacticalrifle"] = "M4 tactique - Fusil modulaire pour opérations spéciales.",
    ["weapon_battlerifle"] = "Fusil de bataille pour engagements à moyenne et longue portée.",
    ["weapon_ar15"] = "AR-15 réservé aux forces de l'ordre (PD).",
    ["weapon_hk416"] = "HK416 - Fusil d'assaut de qualité militaire supérieure.",
    ["weapon_m4a1cd"] = "M4A1 - Variante personnalisée haute performance.",
    ["weapon_ks1"] = "KAC KS-1 - Carabine tactique compacte et légère.",

    -- =====================================================
    -- ARMES - FUSILS À POMPE
    -- =====================================================
    ["weapon_pumpshotgun"] = "Remington 870 - Fusil à pompe classique et dévastateur. Craftable avec blueprint.",
    ["weapon_pumpshotgun_mk2"] = "Remington 870 amélioré avec accessoires MK2.",
    ["weapon_sawnoffshotgun"] = "Mossberg 500 à canon scié - Compact et destructeur. Craftable avec blueprint.",
    ["weapon_assaultshotgun"] = "UTS-15 - Fusil à pompe d'assaut semi-automatique.",
    ["weapon_bullpupshotgun"] = "Fusil à pompe bullpup compact et maniable.",
    ["weapon_heavyshotgun"] = "Saiga - Fusil à pompe lourd semi-automatique à grande capacité.",
    ["weapon_combatshotgun"] = "SPAS-12 - Fusil à pompe de combat polyvalent. Craft MC niveau S.",
    ["weapon_dbshotgun"] = "Fusil à double canon - Deux coups dévastateurs.",
    ["weapon_autoshotgun"] = "Striker - Fusil à pompe automatique à barillet rotatif.",
    ["weapon_m870"] = "M870 - Fusil à pompe tactique pour les forces de l'ordre.",

    -- =====================================================
    -- ARMES - FUSILS DE PRÉCISION
    -- =====================================================
    ["weapon_sniperrifle"] = "L96 - Fusil sniper bolt-action de haute précision.",
    ["weapon_heavysniper"] = "Fusil sniper lourd anti-matériel à très longue portée.",
    ["weapon_heavysniper_mk2"] = "Sniper lourd amélioré avec munitions spéciales MK2.",
    ["weapon_marksmanrifle"] = "Fusil de tireur d'élite semi-automatique à moyenne portée.",
    ["weapon_marksmanrifle_mk2"] = "Fusil de tireur amélioré avec accessoires MK2.",
    ["weapon_precisionrifle"] = "Fusil de précision bolt-action pour le tir à très longue distance.",
    ["weapon_pdpt700"] = "Remington M700 - Fusil de précision réservé aux forces de l'ordre (PD).",

    -- =====================================================
    -- ARMES - MITRAILLEUSES
    -- =====================================================
    ["weapon_mg"] = "Mitrailleuse légère à haute cadence de tir et grande capacité.",
    ["weapon_combatmg"] = "Mitrailleuse de combat avec bipied intégré pour le tir soutenu.",
    ["weapon_combatmg_mk2"] = "Mitrailleuse de combat améliorée avec accessoires MK2.",

    -- =====================================================
    -- ARMES - LANCEURS
    -- =====================================================
    ["weapon_compactlauncher"] = "Lance-grenades compact utilisable en véhicule.",
    ["weapon_hominglauncher"] = "Lance-missiles à tête chercheuse. Verrouillage automatique sur cible.",
    ["weapon_firework"] = "Lanceur pyrotechnique tirant des feux d'artifice festifs.",
    ["weapon_lesslauncher"] = "Lanceur 40mm non-létal pour les forces de l'ordre.",

    -- =====================================================
    -- ARMES - MÊLÉE
    -- =====================================================
    ["weapon_bat"] = "Batte de baseball en bois. Arme de mêlée contondante.",
    ["weapon_bottle"] = "Bouteille cassée improvisée comme arme tranchante.",
    ["weapon_crowbar"] = "Pied de biche métallique. Outil polyvalent et arme de mêlée.",
    ["weapon_flashlight"] = "Lampe torche Maglite utilisable comme arme contondante.",
    ["weapon_golfclub"] = "Club de golf détourné en arme de mêlée.",
    ["weapon_hammer"] = "Marteau de chantier. Outil et arme contondante.",
    ["weapon_hatchet"] = "Hachette compacte, utile pour couper et se défendre.",
    ["weapon_knife"] = "Couteau de combat à lame fixe. Arme de mêlée tranchante. Craft Gang niveau D.",
    ["weapon_knuckle"] = "Poing américain en métal renforçant les coups de poing. Craft Gang niveau D.",
    ["weapon_machete"] = "Machette à lame large pour le combat rapproché. Craft Gang niveau C.",
    ["weapon_nightstick"] = "Matraque de police pour le maintien de l'ordre.",
    ["weapon_poolcue"] = "Queue de billard détournée en arme de mêlée.",
    ["weapon_sledgehammer"] = "Masse de démolition à deux mains. Très lourde et puissante. Craft Gang niveau C.",
    ["weapon_stone_hatchet"] = "Hachette primitive en pierre. Arme de mêlée rustique.",
    ["weapon_switchblade"] = "Couteau à cran d'arrêt, compact et dissimulable. Craft Gang niveau D.",
    ["weapon_wrench"] = "Clé anglaise utilisable comme arme contondante.",
    ["weapon_battleaxe"] = "Hache de guerre médiévale à deux tranchants.",
    ["weapon_aspbaton"] = "Matraque télescopique ASP réservée aux forces de l'ordre.",

    -- =====================================================
    -- ARMES - SPÉCIALES / NON-LÉTALES
    -- =====================================================
    ["weapon_stungun"] = "Taser standard des forces de l'ordre. Neutralise temporairement la personne visée.",
    ["weapon_taserx"] = "Taser X jaune - Version améliorée du taser standard.",
    ["weapon_gtaserx"] = "Taser X vert - Variante verte du taser amélioré.",
    ["weapon_beanbag"] = "Fusil à beanbag non-létal pour neutraliser sans tuer.",
    ["weapon_beanbag2"] = "Fusil à beanbag orange - Variante non-létale.",
    ["weapon_bzgas"] = "Grenade de gaz BZ incapacitant. Usage maintien de l'ordre.",
    ["weapon_fireextinguisher"] = "Extincteur utilisable pour éteindre les incendies.",
    ["weapon_petrolcan"] = "Bidon d'essence permettant de ravitailler ou créer des traînées inflammables.",
    ["weapon_flare"] = "Fusée de détresse lumineuse pour signaler sa position.",
    ["weapon_flaregun"] = "Pistolet de détresse tirant des fusées éclairantes.",
    ["weapon_railgun"] = "Fusil de laser game pour les activités récréatives.",
    ["weapon_raycarbine"] = "Carabine laser futuriste à usage récréatif.",
    ["weapon_rayminigun"] = "Minigun laser futuriste à usage récréatif.",
    ["weapon_raypistol"] = "Pistolet laser futuriste à usage récréatif.",
    ["weapon_musket"] = "Mousquet à poudre noire. Arme historique utilisée pour la chasse.",

    -- =====================================================
    -- ARMES - EXPLOSIFS
    -- =====================================================
    ["weapon_grenade"] = "Grenade à fragmentation explosive avec délai de détonation.",
    ["weapon_molotov"] = "Cocktail Molotov incendiaire. Crée une zone de feu à l'impact.",
    ["weapon_pipebomb"] = "Bombe artisanale fabriquée avec des matériaux de récupération.",
    ["weapon_stickybomb"] = "Bombe collante C4 déclenchable à distance.",
    ["weapon_ball"] = "Balle de baseball. Projectile inoffensif.",
    ["weapon_snowball"] = "Boule de neige festive. Parfaitement inoffensive.",

    -- =====================================================
    -- ARMES - AIRSOFT
    -- =====================================================
    ["weapon_airsoftburst"] = "Réplique airsoft en mode burst. Utilise des billes en plastique.",
    ["weapon_airsoftc4a1"] = "Réplique airsoft C4A1. Fusil d'assaut pour le loisir.",
    ["weapon_airsoftdrago"] = "Réplique airsoft Drago. Pistolet compact de loisir.",
    ["weapon_airsoftfalcon57"] = "Réplique airsoft Falcon-57. Pistolet de loisir.",
    ["weapon_airsoftgk36"] = "Réplique airsoft GK36. Fusil compact de loisir.",
    ["weapon_airsoftkalash47"] = "Réplique airsoft Kalash-47. Réplique AK pour le loisir.",
    ["weapon_airsoftmq14"] = "Réplique airsoft MQ14. Fusil lourd de loisir.",
    ["weapon_airsoftphantom5"] = "Réplique airsoft Phantom-5. SMG compact de loisir.",
    ["weapon_airsoftpredator90"] = "Réplique airsoft Predator-90. Fusil à pompe de loisir.",
    ["weapon_airsoftr594"] = "Réplique airsoft R594. Mitrailleuse de loisir.",
    ["weapon_airsoftstorm"] = "Réplique airsoft Storm. Fusil d'assaut de loisir.",
    ["weapon_airsoftt870"] = "Réplique airsoft Tactical 870. Fusil à pompe de loisir.",
    ["weapon_airsofttitan"] = "Réplique airsoft Titan. Pistolet compact de loisir.",
    ["weapon_airsoftviper"] = "Réplique airsoft Viper. SMG de loisir.",
    ["weapon_airsoftxte"] = "Réplique airsoft XTE. Pistolet de loisir.",

    -- =====================================================
    -- NOURRITURE - BURGERS (BurgerShot)
    -- =====================================================
    ["burger_classic"] = "Burger classique du BurgerShot. Restaure 40% de faim. Ingrédients : pain, steak, fromage, salade, sauce.",
    ["burger_epice"] = "Burger épicé du BurgerShot avec sauce piquante. Restaure 45% de faim.",
    ["burger_veggie"] = "Burger végétarien du BurgerShot avec steak veggie. Restaure 35% de faim.",
    ["pain_burger"] = "Pain à burger moelleux, base essentielle pour la préparation des burgers.",
    ["steak_boeuf_cru"] = "Steak de boeuf cru à cuire sur le grill du BurgerShot.",
    ["steak_boeuf_cuit"] = "Steak de boeuf grillé, prêt à garnir un burger.",
    ["steak_vegetarien_cru"] = "Steak végétarien cru à base de légumes, à cuire.",
    ["steak_vegetarien"] = "Steak végétarien cuit, alternative sans viande pour burgers.",
    ["sauce_burgershot"] = "Sauce signature du BurgerShot pour garnir les burgers.",
    ["sauce_epice"] = "Sauce épicée piquante pour relever les plats.",
    ["sac_burgershot"] = "Sac de livraison BurgerShot pour les commandes à emporter.",

    -- =====================================================
    -- NOURRITURE - PIZZAS (Pizzeria)
    -- =====================================================
    ["pizza_margherita"] = "Pizza Margherita classique cuite au four. Restaure 45% de faim.",
    ["pizza_margherita_crue"] = "Pizza Margherita crue prête à être enfournée.",
    ["pizza_pepperoni"] = "Pizza Pepperoni garnie de rondelles de pepperoni. Restaure 45% de faim.",
    ["pizza_pepperoni_crue"] = "Pizza Pepperoni crue prête à être enfournée.",
    ["pizza_champignon"] = "Pizza aux champignons frais. Restaure 40% de faim.",
    ["pizza_champignon_crue"] = "Pizza aux champignons crue prête à être enfournée.",
    ["pizza_4fromages"] = "Pizza 4 Fromages gratinée mozzarella, parmesan, gorgonzola et chèvre. Restaure 50% de faim.",
    ["pizza_4fromages_crue"] = "Pizza 4 Fromages crue prête à être enfournée.",
    ["pate_pizza"] = "Pâte à pizza fraîche, base pour toutes les pizzas.",
    ["sauce_tomate"] = "Sauce tomate maison pour garnir pizzas et plats.",
    ["mozzarella"] = "Fromage mozzarella fondant pour les pizzas.",
    ["parmesan"] = "Parmesan affiné en copeaux, fromage italien savoureux.",
    ["gorgonzola"] = "Gorgonzola crémeux à pâte persillée, fromage italien typé.",
    ["chevre"] = "Fromage de chèvre frais en rondelles, doux et crémeux.",
    ["pepperoni"] = "Rondelles de pepperoni épicé pour garnir les pizzas.",
    ["basilic"] = "Feuilles de basilic frais, herbe aromatique pour la cuisine.",
    ["origan"] = "Origan séché, épice aromatique pour les pizzas et plats italiens.",
    ["champignons"] = "Champignons frais pour garnir pizzas et plats.",

    -- =====================================================
    -- NOURRITURE - ASIATIQUE (Noodle Exchange)
    -- =====================================================
    ["ramen"] = "Bol de ramen japonais fumant avec nouilles, porc et oeuf. Restaure 50% de faim.",
    ["sushi"] = "Assortiment de sushis frais au saumon et riz vinaigré. Restaure 45% de faim.",
    ["pho"] = "Soupe Pho vietnamienne au boeuf et herbes fraîches. Restaure 45% de faim.",
    ["nouilles"] = "Nouilles cuites prêtes à être utilisées dans les recettes.",
    ["nouilles_crues"] = "Nouilles crues à cuire avant utilisation en cuisine.",
    ["riz_cru"] = "Riz cru à cuire, base pour sushis et accompagnements.",
    ["riz_sushi"] = "Riz vinaigré préparé pour confectionner des sushis.",
    ["vinaigre_riz"] = "Vinaigre de riz pour assaisonner le riz à sushi.",
    ["algues_nori"] = "Feuilles d'algues nori pour envelopper les sushis.",
    ["saumon_cru"] = "Filet de saumon cru frais pour la préparation de sushis.",
    ["porc_chashu"] = "Porc Chashu braisé, garniture traditionnelle du ramen.",
    ["oeuf_marine"] = "Oeuf mariné dans la sauce soja, accompagnement du ramen.",
    ["oignon_vert"] = "Oignon vert frais émincé pour garnir les plats asiatiques.",
    ["bouillon_cru"] = "Bouillon brut non assaisonné, base pour les soupes.",
    ["bouillon_parfume"] = "Bouillon parfumé aux épices, prêt pour le pho.",
    ["bouillon_soja"] = "Bouillon de soja savoureux, base pour le ramen.",
    ["pousses_soja"] = "Pousses de soja croquantes pour garnir le pho.",

    -- =====================================================
    -- NOURRITURE - PÂTISSERIES (Bean Coffee / UwU Cafe)
    -- =====================================================
    ["beignet"] = "Beignet doré et sucré. Restaure 30% de faim.",
    ["croissant"] = "Croissant au beurre frais et croustillant. Restaure 25% de faim.",
    ["donut"] = "Donut classique glacé. Restaure 25% de faim.",
    ["donut_chocolat"] = "Donut au glaçage chocolat. Restaure 25% de faim.",
    ["donut_framboise"] = "Donut au glaçage framboise. Restaure 25% de faim.",
    ["pate_a_beignet"] = "Pâte à beignet crue, prête à être frite.",
    ["pate_a_donut"] = "Pâte à donut crue à cuire et glacer.",
    ["pate_feuilletee"] = "Pâte feuilletée au beurre pour croissants et viennoiseries.",
    ["glacage_chocolat"] = "Glaçage au chocolat pour les donuts.",
    ["glacage_framboise"] = "Glaçage à la framboise pour les donuts.",
    ["sucre_glace"] = "Sucre glace fin pour saupoudrer les pâtisseries.",

    -- =====================================================
    -- NOURRITURE - FRUITS DE MER (Pearls)
    -- =====================================================
    ["truite_fumee"] = "Truite fumée grillée, plat savoureux et riche. Restaure 50% de faim.",
    ["truite_emballee"] = "Truite emballée fraîche, prête à être cuisinée.",
    ["truite_de_mer"] = "Truite de mer fraîchement pêchée. Poisson de qualité.",
    ["homard_bleu_cuit"] = "Homard bleu cuit, mets rare et délicat. Restaure 55% de faim.",
    ["homard_bleu_emballe"] = "Homard bleu emballé frais, prêt à être cuisiné.",
    ["homard_orange_cuit"] = "Homard orange cuit, mets savoureux et généreux. Restaure 55% de faim.",
    ["homard_orange_emballe"] = "Homard orange emballé frais, prêt à être cuisiné.",

    -- =====================================================
    -- NOURRITURE - DIVERS
    -- =====================================================
    ["frite"] = "Barquette de frites dorées et croustillantes. Restaure 15% de faim.",
    ["frite_crue"] = "Frites surgelées prêtes à frire.",
    ["bread"] = "Pain frais cuit au four, aliment de base nourrissant. Restaure 20% de faim.",
    ["chocolat_bar"] = "Barre chocolatée énergétique. Restaure 20% de faim.",
    ["chips_bowl"] = "Paquet de chips croustillantes. Restaure 20% de faim.",
    ["noisettes"] = "Noisettes grillées, en-cas sain et croquant.",

    -- =====================================================
    -- NOURRITURE - INGRÉDIENTS CUISINE
    -- =====================================================
    ["beurre"] = "Plaquette de beurre frais pour la cuisine et pâtisserie.",
    ["fromage"] = "Fromage à fondre pour garnir burgers et plats.",
    ["salade"] = "Feuilles de salade fraîche pour garnir les plats.",
    ["oeuf"] = "Oeuf frais de poule, ingrédient polyvalent en cuisine.",
    ["lait"] = "Bouteille de lait frais pour les boissons et la cuisine.",
    ["huile_olive"] = "Huile d'olive vierge extra pour la cuisine méditerranéenne.",
    ["huile_friture"] = "Huile de friture pour la cuisson des frites et beignets.",
    ["boeuf"] = "Morceau de boeuf cru pour la cuisine.",

    -- =====================================================
    -- VIANDES DE CHASSE
    -- =====================================================
    ["meat_boar"] = "Viande de sanglier fraîchement chassée. Gibier savoureux.",
    ["meat_deer"] = "Viande de cerf tendre issue de la chasse. Gibier noble.",
    ["meat_rabbit"] = "Viande de lapin chassé. Gibier léger et délicat.",

    -- =====================================================
    -- POISSONS (Pêche)
    -- =====================================================
    ["saumon"] = "Saumon frais pêché en mer. Poisson noble très apprécié.",
    ["sardine"] = "Sardine fraîche, petit poisson argenté pêché en mer.",
    ["anchois"] = "Anchois frais pêché en mer, petit poisson savoureux.",
    ["dorade"] = "Dorade royale, poisson de qualité à la chair fine.",
    ["maquereau"] = "Maquereau frais, poisson gras riche en oméga-3.",
    ["merlan"] = "Merlan, poisson blanc à la chair délicate.",
    ["bar"] = "Bar (loup de mer), poisson noble prisé des pêcheurs.",

    -- =====================================================
    -- RAISINS ET VINS (Vigneron)
    -- =====================================================
    ["red_grapes"] = "Grappe de raisin rosé, récoltée dans les vignes pour la production de vin.",
    ["white_grapes"] = "Grappe de raisin blanc, utilisée pour le vin blanc et le vin jaune.",
    ["yellow_grapes"] = "Grappe de raisin jaune, variété spéciale pour le vin jaune.",
    ["wine_red"] = "Bouteille de vin rosé de qualité, issu des vignobles locaux.",
    ["wine_white"] = "Bouteille de vin blanc frais et fruité.",
    ["wine_yellow"] = "Bouteille de vin jaune rare et caractéristique.",

    -- =====================================================
    -- BOISSONS - CAFÉS (Bean Coffee / UwU Cafe)
    -- =====================================================
    ["coffee"] = "Café chaud classique pour un coup de boost. Restaure 15% de soif.",
    ["espresso_petit"] = "Petit espresso serré et corsé. Restaure 15% de soif.",
    ["espresso_moyen"] = "Espresso moyen bien dosé. Restaure 25% de soif.",
    ["espresso_grand"] = "Grand espresso pour les amateurs de café fort. Restaure 35% de soif.",
    ["latte_petit"] = "Petit latte onctueux au lait mousseux. Restaure 15% de soif.",
    ["latte_moyen"] = "Latte moyen crémeux et doux. Restaure 25% de soif.",
    ["latte_grand"] = "Grand latte généreux pour une pause prolongée. Restaure 35% de soif.",
    ["cappuccino_petit"] = "Petit cappuccino avec mousse de lait. Restaure 15% de soif.",
    ["cappuccino_moyen"] = "Cappuccino moyen équilibré et mousseux. Restaure 25% de soif.",
    ["cappuccino_grand"] = "Grand cappuccino crémeux et réconfortant. Restaure 35% de soif.",
    ["sac_grain_espresso"] = "Sac de grains de café espresso pour la préparation.",
    ["sac_grain_latte"] = "Sac de grains de café latte, torréfaction douce.",
    ["sac_grain_cappuccino"] = "Sac de grains de café cappuccino, torréfaction moyenne.",

    -- =====================================================
    -- BOISSONS - GRANITAS (Bean Coffee / UwU Cafe)
    -- =====================================================
    ["granita_citron"] = "Granita au citron glacée et rafraîchissante. Restaure 30% de soif.",
    ["granita_tropical"] = "Granita aux fruits tropicaux givrée. Restaure 30% de soif.",
    ["granita_menthe"] = "Granita à la menthe fraîche et vivifiante. Restaure 30% de soif.",
    ["granita_lagoon"] = "Granita lagoon bleue exotique. Restaure 30% de soif.",
    ["sirop_citron"] = "Sirop de citron concentré pour granitas et boissons.",
    ["sirop_tropical"] = "Sirop tropical fruité pour granitas et cocktails.",
    ["sirop_menthe"] = "Sirop de menthe verte pour granitas et boissons.",
    ["sirop_lagoon"] = "Sirop lagoon bleu pour granitas et cocktails exotiques.",
    ["glace_pilee"] = "Glace pilée pour la préparation de granitas et cocktails.",

    -- =====================================================
    -- BOISSONS - MILKSHAKES
    -- =====================================================
    ["milkshake_vanille"] = "Milkshake à la vanille onctueux et crémeux. Restaure 25% de soif.",
    ["milkshake_chocolat"] = "Milkshake au chocolat gourmand et riche. Restaure 25% de soif.",
    ["milkshake_cafe"] = "Milkshake au café pour un plaisir glacé caféiné. Restaure 20% de soif.",
    ["glace_vanille"] = "Boule de glace vanille pour milkshakes et desserts.",
    ["glace_chocolat"] = "Boule de glace chocolat pour milkshakes et desserts.",
    ["glace_cafe"] = "Boule de glace café pour milkshakes et desserts.",

    -- =====================================================
    -- BOISSONS - SODAS
    -- =====================================================
    ["cola"] = "Canette de Cola rafraîchissante. Restaure 25% de soif.",
    ["cola_25cl"] = "Petit gobelet de Cola 25cl. Restaure 15% de soif.",
    ["cola_33cl"] = "Gobelet moyen de Cola 33cl. Restaure 20% de soif.",
    ["cola_50cl"] = "Grand gobelet de Cola 50cl. Restaure 30% de soif.",
    ["sprunk"] = "Canette de Sprunk pétillante au citron vert. Restaure 25% de soif.",
    ["sprunk_25cl"] = "Petit gobelet de Sprunk 25cl. Restaure 15% de soif.",
    ["sprunk_33cl"] = "Gobelet moyen de Sprunk 33cl. Restaure 20% de soif.",
    ["sprunk_50cl"] = "Grand gobelet de Sprunk 50cl. Restaure 30% de soif.",
    ["fut_cola"] = "Fût de Cola pour les distributeurs et restaurants.",
    ["fut_sprunk"] = "Fût de Sprunk pour les distributeurs et restaurants.",

    -- =====================================================
    -- BOISSONS - SANS ALCOOL
    -- =====================================================
    ["water"] = "Bouteille d'eau plate fraîche et hydratante. Restaure 30% de soif.",
    ["eau_plate"] = "Bouteille d'eau plate minérale. Restaure 30% de soif.",
    ["cafe"] = "Tasse de café chaud et corsé. Restaure 15% de soif.",
    ["jus_orange"] = "Jus d'orange frais pressé, riche en vitamines. Restaure 30% de soif.",
    ["jus_pomme"] = "Jus de pomme naturel et rafraîchissant. Restaure 30% de soif.",
    ["the_glace"] = "Thé glacé désaltérant et léger. Restaure 30% de soif.",
    ["limonade"] = "Limonade pétillante faite maison. Restaure 30% de soif.",
    ["bang"] = "Boisson énergisante Bang pour un boost d'énergie.",
    ["empty_bang"] = "Canette de Bang vide. Recyclable.",

    -- =====================================================
    -- BOISSONS - BIÈRES
    -- =====================================================
    ["biere_blonde_generique"] = "Bière blonde classique et légère. Restaure 20% de soif. Alcoolisée.",
    ["biere_brune"] = "Bière brune aux arômes torréfiés et maltés. Restaure 20% de soif. Alcoolisée.",
    ["biere_ambree"] = "Bière ambrée aux notes caramélisées. Restaure 20% de soif. Alcoolisée.",
    ["biere_blanche"] = "Bière blanche légère et fruitée. Restaure 20% de soif. Alcoolisée.",
    ["biere_noire"] = "Bière noire robuste de type stout. Restaure 20% de soif. Alcoolisée.",
    ["biere_unicorn"] = "Bière brassée par le Vanilla Unicorn. Restaure 5% de soif. Alcoolisée.",
    ["biere_yellowjack"] = "Bière brassée par le Yellow Jack Inn. Restaure 5% de soif. Alcoolisée.",
    ["biere_asgard"] = "Bière brassée par l'Asgard Bar. Restaure 5% de soif. Alcoolisée.",
    ["biere_irishpub"] = "Bière brassée par l'Irish Pub. Restaure 5% de soif. Alcoolisée.",
    ["biere_henhouse"] = "Bière brassée par le Hen House. Restaure 5% de soif. Alcoolisée.",
    ["biere_billard"] = "Bière brassée par le 8Billard. Restaure 5% de soif. Alcoolisée.",

    -- =====================================================
    -- BOISSONS - ALCOOLS FORTS
    -- =====================================================
    ["vodka"] = "Bouteille de vodka pure. Restaure 15% de soif. Alcoolisée.",
    ["whisky_sec"] = "Verre de whisky sec servi pur. Restaure 15% de soif. Alcoolisé.",
    ["bourbon"] = "Bourbon américain aux notes boisées et vanillées. Restaure 15% de soif. Alcoolisé.",
    ["rhum_pur"] = "Rhum pur ambré des Caraïbes. Restaure 15% de soif. Alcoolisé.",
    ["tequila"] = "Tequila mexicaine, idéale en shot. Restaure 15% de soif. Alcoolisée.",
    ["cognac"] = "Cognac français raffiné et chaleureux. Restaure 15% de soif. Alcoolisé.",
    ["pastis"] = "Pastis anisé provençal, à diluer avec de l'eau. Restaure 15% de soif. Alcoolisé.",
    ["champagne"] = "Bouteille de champagne festif et pétillant. Restaure 20% de soif. Alcoolisée.",
    ["moonshine_generique"] = "Moonshine artisanal distillé clandestinement. Restaure 15% de soif. Alcoolisé.",
    ["cidre_generique"] = "Cidre artisanal de pomme, doux et fruité. Restaure 20% de soif. Alcoolisé.",

    -- =====================================================
    -- BOISSONS - COCKTAILS
    -- =====================================================
    ["mojito"] = "Mojito frais à la menthe et au citron vert. Restaure 25% de soif. Alcoolisé.",
    ["margarita"] = "Margarita classique au bord salé. Restaure 25% de soif. Alcoolisée.",
    ["pina_colada"] = "Pina Colada tropicale à la noix de coco et ananas. Restaure 25% de soif. Alcoolisée.",
    ["cosmopolitan"] = "Cosmopolitan élégant à la canneberge. Restaure 25% de soif. Alcoolisé.",
    ["bloody_mary"] = "Bloody Mary épicé au jus de tomate et vodka. Restaure 25% de soif. Alcoolisé.",
    ["punch"] = "Punch fruité et festif, mélange de rhum et jus. Restaure 25% de soif. Alcoolisé.",

    -- =====================================================
    -- CARTES DE RESTAURANTS / BARS
    -- =====================================================
    ["unicorn_carte"] = "Carte du Vanilla Unicorn. Permet de consulter le menu du bar.",
    ["yellowjack_carte"] = "Carte du Yellow Jack Inn. Permet de consulter le menu du bar western.",
    ["asgard_carte"] = "Carte de l'Asgard Bar. Permet de consulter le menu du bar de plage.",
    ["irishpub_carte"] = "Carte de l'Irish Pub. Permet de consulter le menu du pub irlandais.",
    ["henhouse_carte"] = "Carte du Hen House. Permet de consulter le menu du bar fermier.",
    ["billard_carte"] = "Carte du 8Billard. Permet de consulter le menu du bar billard.",
    ["burgershot_carte"] = "Carte du BurgerShot. Permet de consulter le menu fast-food.",
    ["pizzeria_carte"] = "Carte de la Pizzeria. Permet de consulter le menu pizza.",
    ["pearls_carte"] = "Carte du Pearls. Permet de consulter le menu fruits de mer.",
    ["noodle_carte"] = "Carte du Noodle Exchange. Permet de consulter le menu asiatique.",
    ["bean_coffee_carte"] = "Carte du Bean Coffee. Permet de consulter le menu café.",
    ["uwu_cafe_carte"] = "Carte du UwU Cafe. Permet de consulter le menu café-pâtisserie.",

    -- =====================================================
    -- DROGUES
    -- =====================================================
    ["cocaine"] = "Substance illégale provoquant des effets visuels à l'usage.",
    ["meth"] = "Cristaux de méthamphétamine. Substance illégale dangereuse avec effets visuels.",
    ["weed"] = "Herbe de cannabis. Substance illégale avec effets visuels à l'usage.",
    ["pochon_cocaine"] = "Pochon de cocaïne conditionné pour la revente.",
    ["pochon_meth"] = "Pochon de méthamphétamine conditionné pour la revente.",
    ["pochon_weed"] = "Pochon de cannabis conditionné pour la revente.",
    ["pochon_ecstasy"] = "Pochon d'ecstasy conditionné pour la revente.",
    ["pochon_vide"] = "Pochon vide pour conditionner des substances illégales.",
    ["weed_gofast"] = "Colis de weed en gros pour le transport rapide.",

    -- =====================================================
    -- CBD (Légal)
    -- =====================================================
    ["cannabis_flower"] = "Fleur de CBD légale aux propriétés relaxantes.",
    ["cbd_candy"] = "Bonbon au CBD aux vertus apaisantes. Légal.",
    ["cbd_joint"] = "Discret et efficace, idéal pour les amateurs.",
    ["cbd_joint_1"] = "Un équilibre parfait entre durée et intensité, à savourer tranquillement.",
    ["cbd_joint_2"] = "Une fumette longue, puissante et mémorable pour les vrais connaisseurs.",
    ["cbd_leaf"] = "Feuille de CBD séchée pour infusion ou préparation.",
    ["cbd_oil"] = "Huile de CBD concentrée aux propriétés thérapeutiques.",

    -- =====================================================
    -- TABAC
    -- =====================================================
    ["cigarette"] = "Cigarette allumable avec animation de fumée.",
    ["cigarette_paquet"] = "Paquet de cigarettes contenant plusieurs unités.",
    ["e_cigarette"] = "Cigarette électronique avec vapeur aromatisée.",
    ["e_cigarette_cbd"] = "Idéal pour découvrir le produit ou garder une option discrète.",
    ["e_cigarette_cbd_1"] = "Un excellent compromis entre puissance et praticité, facile à transporter.",
    ["e_cigarette_cbd_2"] = "Concentré, puissant et rentable, parfait pour les consommateurs réguliers.",
    ["paper_joint"] = "Feuille à rouler pour confectionner des joints.",
    ["paper_tabacco"] = "Feuille de tabac pour rouler des cigarettes.",

    -- =====================================================
    -- OUTILS
    -- =====================================================
    ["chalumeau"] = "Chalumeau à découper pour le travail des métaux et le crochetage.",
    ["foreuse"] = "Foreuse industrielle pour percer les coffres-forts.",
    ["laptop"] = "Ordinateur portable pour l'usage quotidien.",
    ["tablet"] = "Tablette tactile connectée avec accès aux applications.",
    ["casque_audio"] = "Un casque audio de bonne qualité, idéal pour écouter de la musique.",
    ["pince"] = "Pince à cheveux utilisable permettant de s'attacher les cheveux.",
    ["pince_serflex"] = "Pince coupante pour retirer les serflex et liens.",
    ["serflex"] = "Liens de serrage en plastique pour attacher temporairement.",
    ["kit_de_crochetage"] = "Kit professionnel de crochetage pour ouvrir les serrures.",
    ["kit_de_crochetage_veh"] = "Kit professionnel de crochetage pour ouvrir les serrures de véhicules.",
    ["cleankit"] = "Kit de nettoyage pour entretenir les véhicules.",
    ["repairkit"] = "Kit de réparation mécanique pour remettre un véhicule en état.",
    ["fastrepairkit"] = "Kit de réparation d'urgence pour une réparation rapide sur le terrain.",
    ["kitcarrosserie"] = "Kit de carrosserie pour réparer les dégâts esthétiques d'un véhicule.",
    ["fishroad"] = "Canne à pêche pour attraper des poissons en bord de mer.",
    ["bait"] = "Appât vivant pour attirer les poissons sur l'hameçon.",
    ["jumelle"] = "Jumelles permettant d'observer à longue distance. Zoom interactif.",
    ["megaphone"] = "Mégaphone amplificateur de voix pour s'adresser à une foule.",
    ["boombox"] = "Enceinte portable Bluetooth pour diffuser de la musique dans la rue.",
    ["scuba_mask"] = "Masque de plongée avec tuba pour explorer les fonds marins.",
    ["gadget_parachute"] = "Parachute déployable pour sauter en hauteur en toute sécurité.",

    -- =====================================================
    -- VÉHICULES PORTABLES
    -- =====================================================
    ["bmx"] = "Vélo BMX pliable à sortir de l'inventaire et utiliser.",
    ["skateboard"] = "Skateboard utilisable pour se déplacer en ville. Non stockable.",

    -- =====================================================
    -- MÉDICAL
    -- =====================================================
    ["medikit"] = "Kit médical d'urgence pour soigner les blessures et restaurer la santé.",
    ["medikit_sams"] = "Kit de réanimation professionnel du SAMS. Usage médical uniquement.",
    ["band"] = "Bandage standard pour soigner les blessures légères.",
    ["band_sams"] = "Bandage professionnel du SAMS pour les soins médicaux.",
    ["bequille"] = "Béquille médicale pour aider un patient à marcher.",
    ["froulant"] = "Fauteuil roulant pour transporter un patient blessé.",
    ["sams_paper_document"] = "Document médical officiel du SAMS.",
    ["ethylotest"] = "Éthylotest pour mesurer le taux d'alcoolémie d'une personne. Usage police.",
    ["poudre"] = "Kit de test de poudre pour analyser des substances suspectes. Usage police uniquement.",
    ["gsr_kit"] = "Kit de détection de résidus de tir (GSR).",
    ["bracelet_electronique"] = "Bracelet électronique de surveillance judiciaire. Posé par les forces de l'ordre.",

    -- =====================================================
    -- POLICE / SÉCURITÉ
    -- =====================================================
    ["handcuff"] = "Menottes métalliques pour immobiliser un suspect.",
    ["handcuff_key"] = "Clé de menottes pour libérer une personne menottée.",
    ["herse"] = "Herse déployable sur la route pour crever les pneus des véhicules en fuite.",
    ["sabot"] = "Sabot de roue pour immobiliser un véhicule stationné illégalement.",
    ["radar_gun"] = "Radar de vitesse portatif pour contrôler la vitesse des véhicules.",
    ["fingerprint_scanner"] = "Lecteur d'empreintes digitales pour identifier les suspects.",
    ["sactete"] = "Sac sur la tête pour aveugler temporairement une personne.",
    ["carte_memoire_bodycam"] = "Carte mémoire pour bodycam policière. Enregistrement des interventions. Non stockable.",

    -- =====================================================
    -- COMMUNICATION
    -- =====================================================
    ["phone"] = "Téléphone portable avec accès aux appels, SMS et applications.",
    ["radio_public"] = "Radio publique permettant de communiquer sur les fréquences ouvertes.",
    ["radio_job"] = "Radio professionnelle sur fréquence privée.",
    ["radio_encoder"] = "Encodeur radio pour programmer et sécuriser les fréquences radio.",

    -- =====================================================
    -- CLÉS ET ACCÈS
    -- =====================================================
    ["keys"] = "Clé de véhicule permettant de démarrer et verrouiller votre voiture.",
    ["key_motel"] = "Clé de chambre de motel pour accéder à votre logement temporaire.",

    -- =====================================================
    -- ARGENT
    -- =====================================================
    ["money"] = "Argent liquide en billets. Devise principale.",
    ["dirty_money"] = "Argent sale obtenu illégalement. Doit être blanchi avant utilisation.",
    ["casino_chips"] = "Jetons de casino échangeables contre de l'argent au comptoir.",

    -- =====================================================
    -- HACKING / BRAQUAGE
    -- =====================================================
    ["usb_piratage_atm"] = "Clé USB de piratage pour hacker les distributeurs automatiques.",
    ["usb_piratage_fleeca"] = "Clé USB de piratage pour forcer l'accès aux coffres Fleeca.",
    ["jewelry_hacking_device"] = "Clé USB spécialisée pour hacker le système de sécurité de la bijouterie.",
    ["jewelry_earrings"] = "Boucles d'oreilles volées à la bijouterie. Objet de valeur recelable.",
    ["jewelry_necklace"] = "Collier en diamant dérobé. Objet de grande valeur recelable.",
    ["jewelry_ring"] = "Bague en or volée. Objet de valeur recelable.",

    -- =====================================================
    -- VÊTEMENTS / ACCESSOIRES
    -- =====================================================
    ["clothes_bag"] = "Sac de vêtements contenant une tenue complète à enfiler.",

    -- =====================================================
    -- POTIONS (Buffs de farm)
    -- =====================================================
    ["potion_1"] = "Potion multipliant les gains de farm par 2 pendant 2 heures.",
    ["potion_2"] = "Potion multipliant les gains de farm par 2 pendant 4 heures.",
    ["potion_3"] = "Potion multipliant les gains de farm par 2 pendant 6 heures.",
    ["potion_4"] = "Potion multipliant les gains de farm par 3 pendant 2 heures.",
    ["potion_5"] = "Potion multipliant les gains de farm par 3 pendant 4 heures.",
    ["potion_6"] = "Potion multipliant les gains de farm par 3 pendant 6 heures.",
    ["potion_7"] = "Potion multipliant les gains de farm par 4 pendant 2 heures.",
    ["potion_8"] = "Potion multipliant les gains de farm par 4 pendant 4 heures.",
    ["potion_9"] = "Potion multipliant les gains de farm par 4 pendant 6 heures.",

    -- =====================================================
    -- FEUX D'ARTIFICE
    -- =====================================================
    ["fireworks_box_normal"] = "Boîte de feux d'artifice standard. Spectacle pyrotechnique modéré.",
    ["fireworks_box_mega"] = "Boîte de feux d'artifice Mega. Grand spectacle pyrotechnique.",
    ["fireworks_box_ultimate"] = "Boîte de feux d'artifice Ultimate. Spectacle pyrotechnique exceptionnel.",
    ["fireworks_pyro_small"] = "Petit feu d'artifice pyrotechnique. Effet lumineux discret.",
    ["fireworks_pyro_medium"] = "Feu d'artifice pyrotechnique moyen. Bel effet lumineux.",
    ["fireworks_pyro_large"] = "Grand feu d'artifice pyrotechnique. Effet spectaculaire.",
    ["fireworks_pyro_mega"] = "Feu d'artifice pyrotechnique Mega. Explosion de couleurs.",
    ["fireworks_pyro_fontain"] = "Fontaine pyrotechnique projetant des gerbes d'étincelles.",
    ["fireworks_pyro_pirate"] = "Feu d'artifice pirate avec effets sonores et visuels uniques.",
    ["fireworks_pyro_rug"] = "Tapis pyrotechnique créant un effet au sol spectaculaire.",
    ["fireworks_pyro_ruglong"] = "Tapis pyrotechnique long pour un effet au sol prolongé.",
    ["fireworks_pyro_flare1"] = "Fusée pyro Flare I. Effet lumineux en altitude.",
    ["fireworks_pyro_flare2"] = "Fusée pyro Flare II. Effet lumineux amélioré.",
    ["fireworks_pyro_flare3"] = "Fusée pyro Flare III. Effet lumineux intense.",
    ["fireworks_rocket"] = "Fusée de feu d'artifice classique avec traînée colorée.",
    ["fireworks_solar_flare"] = "Fusée éclairante solaire projetant une lumière aveuglante.",

    -- =====================================================
    -- CONTRATS / DOCUMENTS
    -- =====================================================
    ["employment_contract"] = "Contrat de travail officiel pour embaucher un employé.",
    ["dynasty_contract"] = "Contrat de bail Dynasty 8 pour la location d'un logement.",

    -- =====================================================
    -- DIVERS
    -- =====================================================
    ["ticket_gratter"] = "Ticket à gratter avec possibilité de gagner entre 500$ et 500 000$.",
    ["spray"] = "Bombe de peinture pour réaliser des graffitis sur les murs.",
    ["spray_remover"] = "Produit nettoyant pour effacer les graffitis et tags.",
    ["ltd_box"] = "Carton de livraison LTD pour les missions de livraison.",
    ["plane_hint"] = "Indice de localisation d'un crash d'avion contenant du butin.",
    ["sunken_crate"] = "Caisse engloutie récupérée en plongée sous-marine. Objet de valeur.",
    ["ancient_relic"] = "Relique antique découverte en plongée. Artefact de grande valeur.",
    ["rusty_gold_coin"] = "Pièce d'or rouillée trouvée en plongée. Objet de collection.",
    ["corne_ivoire"] = "Corne d'ivoire rare et précieuse. Objet de contrebande.",
    ["petrol_barrel"] = "Baril de pétrole brut. Ressource industrielle précieuse.",
    ["empty_barrel"] = "Baril vide réutilisable pour le stockage.",
    ["barley"] = "Grain d'orge utilisé dans la fabrication de bière artisanale.",
    ["belier"] = "Bélier de porte pour forcer l'entrée des portes verrouillées.",

}
