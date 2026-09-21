# Assets de marque

Ce dossier est la base d'assets de l'interface. Toutes les images affichées par
la NUI sont résolues à partir d'ici, via la ConVar `core_brand_cdn_base`.

## Comment ça marche

`server.cfg` définit :

```
set core_brand_cdn_base "https://cfx-nui-core/interface/brand"
```

Cette valeur est lue par `config/branding.lua` (`BRANDING.cdnBase`), par
`plugins/000_framework/shared/001_main.lua` (`VFW.CDN_BASE`) et par `eve_bridge`.
Le chemin `https://cfx-nui-core/...` désigne le dossier `interface/brand` de la
resource `core` : les images sont servies par le serveur de fichiers de FiveM,
sans aucune requête vers l'extérieur.

Pour héberger les assets sur votre propre CDN, il suffit de remplacer cette seule
ConVar par l'URL de votre hébergement, en respectant l'arborescence ci-dessous.
Aucune modification de code n'est nécessaire.

## Ce qui est fourni

Le dossier contient **160 fichiers, 4,1 Mo au total** (dont les 46 portraits des parents du créateur, 2,9 Mo). Tous les chemins d'image que
l'interface réclame sont couverts : plus aucun écran n'affiche d'image manquante.

**Ce sont des placeholders, pas des visuels finaux.** Ils sont dessinés dans la
palette de la base (`core_brand_color_*`), lisibles et cohérents entre eux, mais ils
ne remplacent pas vos propres visuels. Remplacez-les au fur et à mesure, en gardant
exactement le même nom et la même extension : les chemins sont codés en dur dans
l'interface, `logo_wn.png` doit rester `logo_wn.png`.

**Ils sont à la charte EVE.** Les 60 visuels qui portaient le bleu de la base ont
été recolorés en violet par rotation de teinte bornée à la bande bleue : la
saturation et la luminosité d'origine sont conservées, seul le ton change. Le
ré-encodage est sans perte (WebP lossless, PNG), d'où le poids passé de 396 à
868 Ko — invisible à l'usage, mais si vous préférez la finesse d'origine,
ré-encodez en WebP qualité 92.

Trois familles ont été **volontairement épargnées** : `badges/`, `notifications/`,
`job/` et `entreprise/`, plus `icons/ecola.webp` et `icons/sprunk.png`. Ce sont
des enseignes du monde de GTA (LSPD, SAMS, Weazel News, Sprunk, Ecola…) : leur
couleur est leur identité, pas la vôtre.

Les deux logos de `logo/` sont **vectoriels** et redessinés depuis la charte EVE :
symbole à 16 pétales en dégradé `#7263EE` → `#40378A`, mot EVE en blanc, boîte
320×96. `logo_red.svg` reprend la gamme rubis de la charte (`#EE637F` → `#8A3748`).

| Famille | Fichiers | Format et taille | Rôle |
|---|---|---|---|
| racine | 2 | 160x160 | image de repli générique (`placeholder.svg`, `placeholder.webp`) |
| `logo/` | 2 | SVG 320x96 | logo principal et variante rouge (ConVars `core_brand_logo`, `core_brand_logo_red`) |
| `PPA/` | 1 | 849x521 | fond du permis de port d'arme, document à fond clair |
| `assets/catalogues/` | 4 | 200x200 | vignettes du catalogue de vêtements et de tatouages |
| `autoecole/` | 6 | 1112x793 et icônes 64 à 96 | fond de la tablette d'examen et boutons |
| `badges/` | 5 | 350x560 | planche carte plus écusson de chaque service |
| `boombox/` | 4 | bandeau 490x120, vignettes 220x140 | en-tête et actions de l'enceinte portable |
| `boutique/` | 3 | SVG 24x24, jeton 96x96 | flèches de navigation et jeton de monnaie |
| `character-creator/` | 2 + `parents/` 46 | 1280x720, 640x320, portraits 256x256 | fond de dressing, fond de l'aperçu Héritage et portraits des parents (`parents/<Prénom>.png`, sprites du créateur GTA Online, source GTA Wiki) |
| `entreprise/` | 4 | 96 à 256 | enseignes des commerces et écusson par défaut |
| `gestion-propriete/` | 1 | 445x140 | bandeau d'en-tête |
| `icons/` | 5 | 40 à 128 | pictogrammes divers de l'interface |
| `illegal/` | 1 | 96x96 | coche de validation |
| `inventory/` | 1 | 160x160 | sac de tenues |
| `items/` | 3 | 160x160 | objet inconnu et repli d'objet |
| `job/` | 3 | 128x128 | logos des trois métiers à panneau dédié |
| `notifications/` | 8 | 128x128 | écussons des services qui émettent des alertes |
| `nurse/` | 4 | bandeau 490x80, icônes 48 à 120 | menu de soin |
| `others/` | 4 | 200x260 et 300x520 | silhouettes de genre et cadres de talkie |
| `outfits_greenscreener/` | 1 | SVG 160x160 | vignette « aucun » du créateur de personnage |
| `premium/` | 3 | 1138x656 et 374x656 | fond et bannières de l'écran d'offres |
| `radialmenus/` | 1 | 48x48 | pointeur du menu radial |
| `radio/` | 13 | châssis 420x760, boutons 18 à 75 | talkie et ses commandes |
| `shops/logos/` | 1 | SVG 260x90 | enseigne de la supérette |
| `tabletteIllegale/` | 13 | châssis 1856x1260, icônes 46 à 300 | tablette et ses écrans |
| `weazel/` | 1 | 490x120 | bandeau d'annonce de presse |

Les dimensions ont été relevées dans le CSS qui affiche chaque image
(`interface/build/assets/index-yMOrF4qJ.css`), pour que le placeholder occupe la
même surface que le visuel définitif. Deux exemples : `.PPA` impose un rapport de
1697/1042, `#NurseMenu .Banner img` impose une hauteur de 80 pixels sur toute la
largeur du panneau.

## Ce qui reste à fournir

### Deux fichiers audio

- `radio/off.ogg`
- `radio/on.ogg`

Ce sont les deux sons de mise en marche et d'arrêt du talkie. Aucun son n'est
fourni, et l'absence est sans conséquence : le navigateur intégré ignore
silencieusement une source audio introuvable, le talkie reste utilisable.
Déposez deux fichiers `.ogg` courts pour les activer.

### Les familles à nom variable

Voir la section suivante. Le nom du fichier dépend de la donnée envoyée par le
serveur, il est donc impossible de tout produire à l'avance.

## Chemins construits à l'exécution

Ces familles prennent un nom variable. La colonne « repli » indique si
l'interface prévoit un visuel de secours quand le fichier demandé n'existe pas.

| Préfixe | Nom construit | Repli prévu par l'interface |
|---|---|---|
| `items/` | `<nom de l'objet>.webp` | partiel : `items/unknown.webp` et `items/placeholder.svg` sont fournis, mais seuls quelques écrans les utilisent. Ailleurs l'image est simplement masquée, ou rien n'est prévu |
| `entreprise/` | `<identifiant>.png` | oui : `entreprise/sasp.png`, fourni, sert de valeur par défaut |
| `outfits_greenscreener/` | `<sexe>/<clothing ou props>/<emplacement>/<drawable>.webp` | oui : une image embarquée dans l'interface, rien à déposer ici |
| `lifeinvader/profile/` | `<identifiant du joueur>` | oui, et ce ne sont pas des images : l'interface lit du JSON et bascule sur un avatar intégré si la réponse n'est pas un succès. Aucun fichier à fournir |
| `badges/` | `<service>-background.webp` | non. Cinq services sont fournis en placeholder : `lspd`, `lssd`, `usss`, `sams`, `lsfd`. Ajoutez un fichier par service supplémentaire |
| `shops/logos/` | `<nom du magasin>.webp` | non. Les magasins dont le nom commence par `vending_` n'affichent pas de logo, les autres réclament un fichier |
| `assets/catalogues/tattoos/` | `<identifiant>.webp` | non. Trois identifiants sont présents dans le catalogue livré et sont fournis |
| `autoecole/` | `<image de la question>` | non. Le nom vient de la base de questions d'examen, à fournir avec elle. Format attendu : 919x346 |

Deux conséquences pratiques :

- pour `badges/`, `shops/logos/` et les images de questions d'auto-école, un
  fichier manquant reste une image cassée. Complétez ces trois familles en même
  temps que vous ajoutez un service, un magasin ou une question ;
- pour `items/`, la couverture dépend de votre catalogue d'objets. Le nom du
  fichier est le nom technique de l'objet, en minuscules, suivi de `.webp`.

## Carte satellite : traitée en CSS

`map/satelite/{z}/{x}/{y}.jpg` alimente la carte des territoires. **Aucune tuile
n'est fournie, et c'est réglé** : la carte a reçu un fond de plan dessiné en CSS.
Rien ne manque à l'écran, et le dossier `map/` n'existe pas.

Ce que fait le code, relevé dans le bundle de l'interface :

- la carte est une carte à tuiles classique, avec un repère sur mesure dont
  l'échelle vaut 2 puissance z et dont la transformation est
  `(0.02072, 117.3, -0.0205, 172.8)` ;
- les limites `[[8425, -5655], [-4055, 6690]]` se projettent exactement sur
  0 à 256 pixels au zoom 0. Autrement dit la carte entière tient dans une seule
  tuile au niveau 0, et chaque niveau suivant en compte quatre fois plus ;
- les niveaux utilisés vont de 1 à 5, le niveau d'ouverture est 3. Cela
  représente 4 plus 16 plus 64 plus 256 plus 1024, soit **1364 tuiles** ;
- aucune tuile de secours n'est déclarée sur la couche, et aucun niveau natif
  maximal n'est fixé. L'interface ne sait donc pas ré-échantillonner un niveau
  inférieur : il faudrait fournir tous les niveaux, ou aucun ;
- une tuile absente ne produit pas d'image cassée. La feuille de style garde
  `.leaflet-tile` en `visibility:hidden` et ne la révèle qu'une fois la tuile
  chargée. Le seul défaut visible était donc le fond du conteneur, un aplat uni
  sans caractère.

### Ce qui a été fait

Trois règles ont été ajoutées **en fin** de
`interface/build/assets/index-yMOrF4qJ.css`, sans rien réécrire de l'existant :

- un fond de plan sur `.leaflet-container` : dégradé sombre de la palette, double
  quadrillage de 40 et 200 pixels, halo central. Les polygones de territoires,
  qui sont dessinés à moitié opaques avec un contour de leur couleur, et les
  pastilles numérotées restent parfaitement lisibles par-dessus ;
- une garde qui force à zéro l'opacité des tuiles non chargées, pour que rien
  n'apparaisse même si un thème modifiait la visibilité par défaut ;
- un vignettage discret sur `.Map .leaflet-container`.

Le lien vers cette feuille de style porte désormais `?v=2` dans
`interface/build/index.html`, pour que le navigateur intégré ne serve pas la
version mise en cache.

### Si vous voulez une vraie carte

Déposez la pyramide de tuiles ici, en 256 pixels, niveaux 1 à 5. **Aucune des
trois règles n'est à retirer** : elles ne masquent que les tuiles non chargées,
vos tuiles s'afficheront donc normalement, et le fond de plan disparaîtra
derrière elles. Comptez 1364 fichiers pour couvrir tous les niveaux.

Si vous préfériez malgré tout un fond neutre en fichiers plutôt qu'en CSS, 1364
tuiles unies pèsent environ 0,9 Mo, 2,7 Mo avec une grille. Le poids n'est pas le
sujet : ce sont 1364 fichiers de plus à transférer à chaque joueur au chargement
de la resource, pour un rendu que ces trois règles obtiennent sans aucun fichier.

## Écran de chargement

Les pochettes `music1.jpg` et `music2.jpg` et les pistes `music/music1.mp3` et
`music/music2.mp3` **ne sont pas dans ce dossier** : elles sont attendues sous
`modules/loadingscreen/`, qui a sa propre base d'URL.

**Les deux pochettes sont fournies**, en 300x300, dessinées pour rester lisibles
une fois découpées en cercle de 100 pixels par le lecteur. Ce sont des visuels
abstraits qui n'imitent aucune jaquette existante. Ce sont des placeholders.

**Aucun fichier audio n'est fourni.** Les deux titres inscrits en dur dans
l'interface sont des enregistrements commerciaux : les diffuser sur un serveur
suppose des droits que seul le propriétaire du serveur peut obtenir. Remplacez
les deux titres par de la musique dont vous détenez les droits, ou retirez le
lecteur. En l'état, le lecteur s'affiche et reste utilisable : la lecture d'une
source absente est interceptée et ignorée.

## Remplacer un placeholder

1. Gardez le nom et l'extension exacts. Le format est déduit de l'extension par le
   serveur de fichiers de FiveM : un fichier SVG renommé en `.webp` ne s'affiche pas.
2. Respectez le rapport largeur sur hauteur indiqué dans le tableau. Les tailles
   d'affichage sont fixées par le CSS, une image au mauvais rapport sera étirée.
3. Conservez la transparence là où le placeholder en a : les pictogrammes de la
   tablette et les boutons du talkie sont posés sur des fonds colorés.
4. Aucun redémarrage du serveur n'est nécessaire pour tester : rechargez la
   resource `core`.

Le dossier entier est déclaré dans `fxmanifest.lua` par `"interface/brand/**/*"`,
tout fichier ajouté est servi sans autre déclaration.
