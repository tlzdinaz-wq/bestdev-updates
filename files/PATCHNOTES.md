# Patch notes — Best Dev (core v1.12.17) — 20/09/2026

## Corrections
- **Compteur** : il suivait encore le coin bas-droit (ancien `transform`). Il se place maintenant dans le cadre, comme le reste du HUD.

---

# Patch notes — Best Dev (core v1.12.16) — 20/09/2026

## HUD statut
- Vie / armure : barres fines, pastille ronde (cœur / bouclier) cerclée de la couleur.
- Faim / soif / oxygène : anneaux plus épais, icône au centre, plus de pourcentage affiché.
- Thèmes Néon / Cercles / Minimal, couleurs F5 et éditeur de positions conservés.

---

# Patch notes — Best Dev (core v1.12.15) — 20/09/2026

## Interfaces

### Positions (F5 et Gestion)
- Le **menu VUI** suit vraiment le cadre : plus seulement un rectangle vide. Si tu le places à droite, le logo HUD passe de l’autre côté.
- Les **notifications** se placent à l’endroit exact du cadre (pile Best Dev), sans casser le reste du HUD (échelle, boussole, faim / vie).
- **Gestion → Positions des interfaces** : un cadre **Fiche joueur** (carte staff : ID session, UUID, etc.) pour tout le serveur. Il n’apparaît **pas** dans le F5 : un joueur ne peut pas l’écraser avec son HUD perso.
- Les positions serveur restent après reboot (`config/ui_layout.json`). Tant qu’un joueur n’a pas validé un layout F5, il suit Gestion. **Réinitialiser** le ramène au layout serveur.

### HUD
- L’ID affiché en haut à droite est l’**ID de session** (celui du serveur), plus l’identifiant unique de compte.

## Corrections
- Déplacer les notifications ne déforme plus le HUD entier.
- La fiche staff et les aperçus à côté du menu suivent la position du menu (ou la position enregistrée en Gestion).

---

# Patch notes — Best Dev (core v1.12.14) — 20/09/2026

## Nouveautés

### Chat (touche T)
- Nouveau chat, aux couleurs et au logo du serveur. `T` ouvre la saisie (touche rebindable dans Paramètres → Touches → FiveM), `Entrée` envoie, `Échap` ferme.
- Tape `/` : les commandes s'affichent au fur et à mesure avec leurs paramètres et leur description ; `Tab` complète, le paramètre en cours est surligné avec son aide.
- `↑ ↓` : navigation dans les suggestions, sinon historique de tes messages. Codes couleur `^1`…`^9`, `^*` gras, `^r` reset.
- Chat fermé : les derniers messages restent quelques secondes puis s'effacent.
- Compatible avec tous les scripts existants (`chat:addMessage`, suggestions, templates). Commandes `/say` (console) et `/clearchat`.

### Documents (carte d'identité, permis, PPA, carte d'entreprise, badges, visa)
- Nouvelle carte « physique » : relief, reflet holographique, puce, guillochis, entrée en 3D.
- Couleur et icône par type (identité = couleur du serveur, permis = bleu, PPA = rouge, carte pro = vert + logo de l'entreprise, police / EMS, visa).
- Photo pleine hauteur, champs rangés dans un ordre logique, catégories de permis A / B / C avec coche, signature manuscrite, bande de lecture optique, tampon **EXPIRÉ** sur un visa périmé.

### Images de vêtements
- Gestion → Images → Vêtements → **Générer les images** : Homme / Femme puis Haut, Bas, Chaussures, Masque, Accessoire, Chapeau, Lunettes ; option « seulement les vêtements sans image ».
- Capture automatique sur fond vert, détourage, envoi sur **FiveManage** (clé `FIVEMANAGE_MEDIA_API_KEY`), images utilisées aussitôt par les boutiques et le créateur de personnage. La grille se met à jour toute seule. `Retour` interrompt le lot.

### Mises à jour de la base
- Nouvelle ressource `updater` : dans la console, `update` télécharge uniquement les fichiers qui ont changé depuis ta version. `update check` montre ce qui changerait, `update force` écrase aussi tes fichiers modifiés, `update restart` redémarre les ressources touchées, `update version` affiche les versions.
- Tes fichiers modifiés (configs, images…) ne sont jamais écrasés : la nouvelle version est posée à côté en `.new`. Les anciens fichiers remplacés sont gardés dans `updater/backup/<version>/`. `server.cfg` et `permissions.cfg` ne sont jamais touchés.

## Corrections
- Menus : retour au menu d'origine habillé (bandeau + nom du serveur) ; plus de cartes coupées ni de barre de défilement horizontale ; les lignes « Métier / Faction » ne sont plus des sections.
- Chat : Échap / Entrée relâchent bien le curseur, les commandes s'exécutent, la liste des commandes se recharge si le chat est redémarré après `core`.
- Vêtements : tous les vêtements apparaissaient « sans image ».
- Dock staff déplacé sur le bord droit (centré), alerte visuelle quand des reports attendent.

## Configuration (`server.cfg`)
```cfg
ensure chat                              # groupe standalone, avant core
ensure updater

set update_url "https://raw.githubusercontent.com/tlzdinaz-wq/bestdev-updates/main"
set chat_global_messages "true"          # "false" = seules les commandes passent

set FIVEMANAGE_MEDIA_API_KEY "TA_CLE"    # clé Media FiveManage (mugshots, factions, vêtements)
set core_fivemanage_outfits_path "outfits"
```
Redémarrage complet du serveur après ajout des deux ressources.

---

# Patch notes — Best Dev (core v1.12.11) — 20/09/2026

## Corrections
- Les erreurs React `insertBefore` / `removeChild` au chargement sont bloquées à la source : plus de double montage StrictMode, plus d’iframes / châssis 3D injectés dans `document.body` (là où React pose ses portails), et les messages NUI attendent que le cadre soit vraiment prêt (`nui:frameReady`). Plus de `resource core has no UI frame` au boot.
- **Déplacer les interfaces** : plus seulement des carrés vides. HUD, compteur, logo, minimap et un vrai menu VUI d’aperçu suivent le cadre pendant le glisser.
- La minimap GTA suit vraiment le cadre (refresh radar + conversion safezone). Elle ne restait pas en bas à gauche.
- F5 : plus de listes Horizontal / Vertical pour les menus et notifications. Les positions se règlent en les déplaçant.
- Staff → Gestion → **Positions des interfaces** : le même éditeur que F5, mais enregistré pour **tout le serveur**.
- Tant qu’un joueur n’a pas bougé son HUD dans F5, il suit le layout **Gestion serveur**. S’il le déplace dans F5, ses positions perso sont gardées.
- L’éditeur de positions (F5 et Gestion) permet aussi de déplacer les **notifications**.

---

# Patch notes — Best Dev (core v1.12.10) — 20/09/2026

## Interfaces

### Déplacer les interfaces
- Dans **F5 → Options VUI**, le choix d’emplacement fixe (gauche / droite…) est remplacé par **« Déplacer les interfaces »**.
- Tu glisses à la souris : minimap, faim / soif, vie / armure, compteur, logo et menu VUI.
- **Entrée** ou **Valider** enregistre, **Échap** ou **Annuler** annule. Les positions sont gardées sur le joueur (reviennent après reconnexion).
- **« Réinitialiser les positions »** remet tout à l’emplacement par défaut (y compris l’ajustement ultrawide de la minimap).

### Orientation (horizontal / vertical)
- Chaque joueur choisit, toujours dans **F5 → Options VUI**, l’orientation du **HUD**, des **menus** et des **notifications** : *défaut serveur*, *horizontal* ou *vertical*.
- Le choix perso est enregistré localement. S’il n’y a pas de choix, c’est le défaut serveur qui s’applique.
- Côté staff, **Gestion → Orientation des interfaces** règle le défaut pour tout le serveur. Sauvegarde dans un JSON (`config/ui_layout.json`) : ça tient après reboot, et les joueurs déjà connectés le reçoivent tout de suite.

## Corrections
- Écran de sélection des personnages : plus de crash `coords` (la scène n’utilise plus un ancien point `COH` ; le clone est placé par rapport à la caméra). Relog / second chargement NUI ne casse plus le perso affiché.
- Plus de spam d’erreurs React (`insertBefore` / `removeChild`) au chargement : les habillages 3D des tablettes ne touchent plus l’arbre de l’interface, et le layout HUD ne s’applique plus pendant l’écran perso.

---

# Patch notes — Best Dev (core v1.12.9) — 19/09/2026

## Interfaces

### Tablettes (MDT police / DOJ / gouvernement / SAMS, faction, territoires, patron, Dynasty 8, DVM, staff, Weazel, LifeInvader)
- Nouveau châssis « appareil » 3D commun à toutes les tablettes : coque, vitre, fond, inclinaison qui suit la souris.
- Les tablettes qui dessinent sur la carte (zones, météo, territoires) et la tablette patron restent fixes (pas d'inclinaison) pour ne pas décaler les clics.
- Plus de page qui défile quand une tablette est ouverte.

### Tablette patron
- Habillage complet (onglets, listes, modales) aux couleurs de la marque.
- Onglet **Annonces** entièrement refait : champs média avec vignettes, sélecteur de couleur, compteur de caractères, aperçu en direct de la bannière, aide.

### Menu pause
- Nouveau menu pause (tuiles Personnage / Carte / Boutique / Réglages / Support) avec logo et fond configurables depuis le hub Gestion → Images → Pause.
- Support → le message écrit est envoyé comme **report** dans le menu staff (côté serveur : mêmes limites que `/report`).

### Boutique premium
- Interface entièrement refaite (nouvelle structure, pas un simple restyle) : vitrine, catégories, page VIP, caisses, inventaire des achats, cadeaux, confirmation d'achat, récompense quotidienne, notifications.
- Même logique serveur qu'avant (achats, cadeaux, caisses, remboursements, Tebex).

### Menus (VUI)
- Retour au menu d'origine avec l'habillage « verre » : bandeau + nom de marque, titre avec compteur, lignes avec chevrons, sections, interrupteurs, curseurs, aperçus (rapports, sanctions, VIP…) restylés.
- Couleur d'accent et nom pris depuis le branding (`core_brand_*`).

### HUD staff / animateurs
- Nouveau dock vertical (marque, reports, staff en ligne / en service, animateurs) placé sur le **bord droit, centré** ; alerte visuelle quand des reports sont en attente.

### Notifications
- Notifications HUD, aide et annonces re-dessinées (3D, couleurs de marque), en haut à droite.

## Gestion des images → Vêtements
- Nouveau bouton **« Générer les images »** : choix **Homme / Femme** puis **Haut / Bas / Chaussures / Masque / Accessoire / Chapeau / Lunettes**, option « seulement les vêtements sans image », compteur de ce qui reste à faire.
- Capture automatique : le personnage est habillé pièce par pièce sur fond vert, photographié, détouré (fond transparent, recadrage 512×512 webp) puis **envoyé sur FiveManage**. **Retour** interrompt le lot, progression affichée à l'écran.
- Les images sont **utilisées immédiatement** par les boutiques (vêtements, Vangelico) et le créateur de personnage — aucun redémarrage nécessaire.
- La grille se met à jour toute seule à la fin d'un lot (vignettes, compteur « sans image »).
- Correction : la liste des vêtements affichait tout en « Aucune image » (le manifest serveur n'existait pas).

## Configuration (`server.cfg`)
- Bloc **FiveManage** unique et commenté : `FIVEMANAGE_MEDIA_API_KEY` (clé Media) pour mugshots, factions et vêtements ; `core_fivemanage_outfits_path` (dossier des vêtements, `outfits` par défaut) ; `fivemanage:key` (clé Logs, optionnelle pour ox_lib).
- Les clés, identifiants MySQL et licence owner (`permissions.cfg`) sont à renseigner dans les champs prévus ; README mis à jour.

## Développement
- Les **sources des interfaces ne sont plus dans la base** : seuls les builds minifiés sont livrés (`interface/*`, `VUI/web/app`, `tablet3d`, `skin`).
- Commandes staff `/uidev <url>` (pages chargées depuis un serveur Vite avec rechargement à chaud, sans build), `/uidev off`, `/uireload` (recharge les pages NUI sans restart).
- Le résolveur d'images du bundle accepte les URLs absolues (FiveManage, CDN) — patch réappliquable si le bundle est remplacé.

## Corrections diverses
- Menu VUI : cartes coupées / barre de défilement horizontale (colonnes trop larges) ; items d'information « Métier : … / Faction : … » affichés comme des bandeaux et non comme des sections.
- Boutique : la sélection ne fait plus « sauter » le cadre.
- Menus : le nom de marque ne s'affichait pas sur la bannière.
