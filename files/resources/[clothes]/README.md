# Packs de vêtements

Dossier prévu pour les packs de vêtements (un dossier = une ressource ; `ensure [clothes]` dans `server.cfg`
démarre tout ce qui s'y trouve, sous-dossiers `[…]` compris). Le comptage des vêtements dans le magasin,
le créateur et le skinchanger prend en compte les packs (vanilla + DLC + collections addon).

## Pack *addon* (ajoute de nouveaux vêtements)

Format collection (Durty Cloth Tool, etc.) : `fxmanifest.lua` avec `files { 'mp_m_freemode_01_<nom>_shop.meta' }`
+ `data_file 'SHOP_PED_APPAREL_META_FILE' …`, et dans `stream/` **le `.ymt` de la collection ET les modèles /
textures** `mp_m_freemode_01_<nom>^jbib_000_u.ydd`, `…^jbib_diff_000_a_uni.ytd`. Un pack livré sans ses
`.ydd` / `.ytd` liste ses vêtements mais ils sont invisibles. Les nouveaux IDs apparaissent automatiquement partout.

## Pack *replace* (remplace le look d'un vêtement existant)

Fichiers nommés comme ceux du jeu : `mp_m_freemode_01^jbib_017_u.ydd`, `mp_m_freemode_01^jbib_diff_017_a_uni.ytd`…
Aucun nouvel ID n'apparaît : ce sont les vêtements déjà présents qui changent d'apparence.

```
[clothes]/mon-pack-replace/
├─ fxmanifest.lua
└─ stream/
   ├─ mp_m_freemode_01^jbib_017_u.ydd
   └─ mp_m_freemode_01^jbib_diff_017_a_uni.ytd
```

`fxmanifest.lua` (les vieux packs livrés avec un `__resource.lua` vide ne remplacent pas les fichiers du jeu :
il faut `this_is_a_map 'yes'`, qui force les fichiers streamés à passer devant ceux du jeu) :

```lua
fx_version 'cerulean'
game 'gta5'

description 'Pack replace vêtements'
this_is_a_map 'yes'
```

## Les limites du jeu (à connaître avant d'empiler les packs)

- **Slots de définitions (`.ymt`) par sexe** : GTA n'accepte qu'un petit nombre de collections de vêtements en plus
  des siennes, et ce nombre baisse à chaque build : ~10 sur 3095, ~8 sur 3258, **~5 sur 3570** (build de la base),
  ~4 sur 3717. Un `.ymt` de trop est **ignoré en silence** : ses vêtements sont listés mais invisibles. Compte
  les `mp_m_freemode_01_*.ymt` (homme) et `mp_f_freemode_01_*.ymt` (femme) de tous tes packs, `creaturemetadata`
  (talons, expressions) compris. Trop de packs → fusionner les collections (Durty Cloth Tool) ou baisser le build.
- **255 drawables par composant et par collection**, 26 textures par drawable.
- **16 Mo par fichier streamé** (limite moteur, aucune option serveur) : au-delà, le fichier est ignoré
  (le vêtement reste invisible). À compresser / découper.
- **Pool de textures** : `increase_pool_size "TxdStore" 26000` dans `server.cfg` (maximum Cfx) évite le plafond
  quand des milliers de `.ytd` s'ajoutent. Les joueurs redémarrent leur jeu une fois à la première connexion.
- Rien d'autre que des `.ydd .ytd .ymt .yft .ydr` dans `stream/` (pas de `dlc.rpf`, `desktop.ini`, images…).
- Après ajout : `refresh` puis redémarrage complet du serveur, et **les joueurs doivent se reconnecter**.
- Les vignettes du magasin / créateur sont des captures : après un pack replace, régénérer les images
  concernées (Gestion → Images → Vêtements).
