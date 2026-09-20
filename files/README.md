# Base NoFace — édition communautaire FiveM

## 📦 Versions unbuild et prochaines mises à jour

**Les sources unbuild des interfaces ne sont pas incluses dans ce téléchargement. Pour obtenir les versions unbuild des scripts et connaître leurs modalités d'accès, rejoins mon Discord.**

**Reste sur le serveur Discord pour suivre les prochaines updates, les corrections et les annonces du projet. Tu peux également inviter tes amis pour qu'ils retrouvent les versions directement à la source.**

### 👉 [Rejoindre le Discord — ak4therapyst / 7M Therapyst](https://discord.gg/HFHHMezSYF)

> Une base FiveM ESX complète, reconstruite, modernisée et préparée pour la communauté par **ak4therapyst — 7M Therapyst**.

[![Discord](https://img.shields.io/badge/Discord-Rejoindre%20la%20communauté-5865F2?logo=discord&logoColor=white)](https://discord.gg/HFHHMezSYF)
[![FiveM](https://img.shields.io/badge/FiveM-Serveur%20RP-F40552?logo=fivem&logoColor=white)](https://fivem.net/)
[![ESX](https://img.shields.io/badge/Framework-ESX-35A7FF)](https://github.com/esx-framework)

## Le projet

Cette édition publique de la Base NoFace rassemble un serveur roleplay français basé sur **ESX 1.13.4**, `ox_inventory`, `ox_lib`, `oxmysql`, OneSync Infinity et la ressource centrale `_GM`.

Le projet a demandé un important travail de reconstruction et d'intégration : restauration de nombreux modules serveur manquants, raccordement des contrats client/serveur, correction des dépendances, consolidation SQL, francisation et modernisation de plusieurs interfaces NUI.

### Travail réalisé par ak4therapyst / 7M Therapyst

- reconstruction d'une grande partie du fonctionnement serveur de `_GM` ;
- remise en état des ressources `nf-*` et `nf_*` ;
- réparation des dépendances et de l'ordre de démarrage FiveM ;
- intégration ESX, ox_inventory, ox_lib et oxmysql ;
- reconstruction et modernisation du constructeur d'intérieurs et de propriétés ;
- modernisation des interfaces F1, ECHAP, banque, vêtements, tatouages et barber ;
- correction de nombreux échanges Lua ↔ NUI ;
- restauration des systèmes de personnages, métiers, propriétés et activités ;
- création d'un schéma SQL global rejouable ;
- nettoyage des secrets et préparation de cette édition communautaire.

Le développement, les mises à jour et le support communautaire sont centralisés ici :

## **[Discord officiel — ak4therapyst / 7M Therapyst](https://discord.gg/HFHHMezSYF)**

## Contenu principal

- `_GM`, cœur du gamemode NoFace ;
- créateur et sélection de personnages `17mov_CharacterSystem` ;
- vêtements, tatouages et barber ;
- constructeur de shells et système immobilier ;
- emplois et outils de police ;
- banque avec RxBanking ;
- inventaire, portes, voix et bridges ESX ;
- activités et modules `nf-*` / `nf_*` ;
- interfaces NUI compilées pour FiveM ;
- installation SQL complète dans `avrex.sql` (base nommée `avrex`).

## Arborescence

```text
Base Avrex/
├── resources/          Ressources FiveM
├── avrex.sql           Schéma SQL complet (crée la base `avrex`)
├── install.sql         Crée uniquement la base `avrex`
└── server.cfg          Configuration et ordre de démarrage
```

## Prérequis

- un artifact FXServer récent ;
- MariaDB ou MySQL ;
- une clé de licence FiveM obtenue sur [Cfx.re Keymaster](https://keymaster.fivem.net/) ;
- OneSync activé ;
- les droits de redistribution nécessaires pour les ressources tierces utilisées.

## Installation

### 1. Préparer la base de données

Importe `avrex.sql` : il crée la base `avrex` si elle n'existe pas, puis toutes les tables.

```text
avrex.sql
```

Le fichier est rejouable : les tables utilisent `CREATE TABLE IF NOT EXISTS`.

### 2. Configurer `server.cfg`

Remplace les valeurs suivantes :

```cfg
sv_hostname "VOTRE NOM DE SERVEUR"
sets sv_projectName "VOTRE NOM DE SERVEUR"
sets sv_projectDesc "VOTRE DESCRIPTION DE SERVEUR"

set sv_licenseKey "VOTRE_CLE_FIVEM"
set steam_webApiKey ""
set mysql_connection_string "mysql://VOTRE_UTILISATEUR:VOTRE_MOT_DE_PASSE@127.0.0.1/avrex?charset=utf8mb4"
```

La clé Steam Web API est facultative. Laisse sa valeur vide si aucune ressource ne l'utilise.

Pour les images hébergées (mugshots, factions et images de vêtements générées depuis le hub Gestion → Images → Vêtements), renseigne ta clé FiveManage de type **Media** (https://fivemanage.com) dans le bloc dédié de `server.cfg` :

```cfg
set FIVEMANAGE_MEDIA_API_KEY "TA_CLE_MEDIA"
set core_fivemanage_outfits_path "outfits"
```

Sans clé, la génération des images de vêtements est désactivée (message dans la console et dans le hub).

## Mises à jour

La ressource `updater` met la base à jour depuis la console du serveur, sans rien télécharger d'autre que ce qui a changé :

```
update            vérifie puis applique
update check      liste ce qui changerait, sans rien toucher
update force      écrase aussi les fichiers que tu as modifiés
update restart    applique puis redémarre les ressources touchées
update version    version installée / disponible
```

Renseigne `set update_url "https://…"` dans `server.cfg` (adresse donnée avec la base). Un fichier que tu as modifié (config, images…) n'est jamais écrasé : la nouvelle version est posée à côté avec l'extension `.new`, à toi de reporter tes changements. Les anciens fichiers remplacés sont gardés dans `resources/[standalone]/updater/backup/<version>/`. `server.cfg` et `permissions.cfg` ne sont jamais touchés ; quand une nouvelle ressource arrive, la console te rappelle d'ajouter son `ensure`.

Le chat (ressource `chat`, touche **T**, rebindable dans les paramètres FiveM) propose la complétion des commandes avec `Tab`. `chat_global_messages` dans `server.cfg` décide si les messages libres sont diffusés à tout le serveur (`true`) ou si seules les commandes sont acceptées (`false`).

Adapte également `sv_maxclients`, le build GTA imposé et les ressources activées à ton installation. Ne change pas l'ordre des `ensure` sans vérifier les dépendances décrites dans le fichier.

### 3. Se mettre administrateur

La base utilise deux systèmes complémentaires : les permissions ACE de FiveM et le groupe ESX enregistré en base de données. Configure les deux pour que tous les menus et toutes les commandes reconnaissent correctement l'administrateur.

#### A. Ajouter l'identifiant Cfx aux permissions ACE

Connecte-toi une première fois, puis utilise `status` dans la console serveur. Repère ton identifiant sous la forme `license:abcdef...`.

Dans `permissions.cfg`, remplace uniquement `votre_license` par la partie située après `license:` :

```cfg
add_principal identifier.license:votre_license group.superadmin
add_ace identifier.license:votre_license gm.owner allow
```

Exemple : si `status` affiche `license:123456`, écris `identifier.license:123456`.

Recharge ensuite le fichier dans la console serveur :

```text
exec permissions.cfg
```

Un redémarrage complet du serveur fonctionne également.

#### B. Définir le groupe ESX

Une fois connecté, récupère ton ID serveur avec `status`, puis exécute dans la **console serveur** :

```text
setgroup ID_SERVEUR admin
save ID_SERVEUR
```

Exemple pour le joueur ayant l'ID serveur `1` :

```text
setgroup 1 admin
save 1
```

La commande `save` force immédiatement l'enregistrement du groupe avec les autres données du personnage. La valeur historique `superadmin` est automatiquement convertie en `admin` par cette version d'ESX ; utilise donc directement `admin`.

Pour confirmer le résultat, utilise en jeu :

```text
/group
```

Le compte doit maintenant être reconnu par les commandes ESX, les contrôles ACE et les menus administratifs de `_GM`.

### 4. Configuration Discord facultative

L'invitation communautaire affichée par défaut est :

```text
https://discord.gg/HFHHMezSYF
```

Le bot Discord est désactivé tant que les deux convars suivantes restent vides :

```cfg
set DISCORD_BOT_TOKEN ""
set DISCORD_GUILD_ID ""
```

Pour utiliser les rôles Discord du sélecteur de personnages, crée ton propre bot, invite-le sur ta guilde avec le Server Members Intent, puis renseigne ces deux valeurs uniquement dans ta copie privée de `server.cfg`.

Le Rich Presence Discord est également désactivé par défaut. Crée tes applications Discord, configure leurs assets `noface` et `nfacademy`, puis remplace les deux valeurs `0` suivantes par leurs identifiants d'application :

```cfg
setr NOFACE_DISCORD_APP_ID "0"
setr NOFACE_DISCORD_APP_ID_FA "0"
```

Ne publie jamais un token de bot, une clé FiveM, une clé Steam, un webhook complet ou un mot de passe MySQL.

### 5. Démarrer le serveur

Depuis le dossier contenant `server.cfg`, lance ton artifact FXServer en adaptant le chemin de l'exécutable :

```powershell
Chemin\vers\FXServer.exe +exec server.cfg
```

## Personnaliser le menu ÉCHAP sans recompiler

Ouvre `resources/[noface]/_GM/src/addons/UI/client/fl_config.lua`. Tous les réglages ci-dessous sont lus par l'interface compilée. Les sources React de `_GM` ne sont pas nécessaires et ne sont pas distribuées dans cette édition.

```lua
GM.UI.Config = GM.UI.Config or {}
GM.UI.Config.PauseMenu = {
    shopEnabled = false,
    title = "NOFACE",
    titleSuffix = "DROP",
    showLogo = true,
    logo = "assets/pausemenu/logo.png",
    showTrademark = true,
    trademark = "assets/pausemenu/trademark.png",
}
```

### Changer le titre NOFACEDROP

`title` est la partie en gras et `titleSuffix` la partie plus fine. Les deux textes restent blancs et sont collés sans espace ajouté automatiquement. Par exemple, pour afficher **MON SERVEUR** :

```lua
title = "MON ",
titleSuffix = "SERVEUR",
```

Pour un titre entièrement en gras, mets tout dans `title` et laisse `titleSuffix = ""`.

### Retirer le symbole TM

Mets `showTrademark = false`. Il disparaît complètement, sans supprimer d'image ni modifier le JavaScript. Pour le remettre, utilise `true`. Le champ `trademark` permet aussi de remplacer son image.

### Remplacer le logo NF

Place ton PNG transparent dans `resources/[noface]/_GM/src/html/assets/pausemenu/`, par exemple `mon-logo.png`, puis renseigne :

```lua
logo = "assets/pausemenu/mon-logo.png",
```

Le chemin part de `_GM/src/html/` : ne mets ni chemin Windows, ni `src/html/` devant. PNG, WebP et SVG sont acceptés. Un fichier carré et transparent donne le meilleur résultat. Tous les fichiers sous `src/html/assets/` sont déjà déclarés au manifest. `showLogo = false` masque le logo au-dessus des cartes.

### Afficher la boutique

Mets `shopEnabled = true` dans le même fichier. Cela affiche la carte Boutique et les badges de monnaie/abonnement du menu ÉCHAP. `false` les masque. Ce réglage contrôle l'accès visuel depuis ÉCHAP : il ne configure pas les paiements Tebex et ne désactive pas les autres accès éventuels à la boutique.

La configuration métier de la boutique se trouve dans `_GM/src/addons/Players/modules/tebex/shared/fl_config.lua`. Les secrets de paiement doivent rester dans les convars serveur de ta copie privée de `server.cfg`.

Après modification du fichier Lua ou ajout/remplacement d'une image, redémarre `_GM` depuis la console serveur, puis rouvre ÉCHAP :

```text
restart _GM
```

Fais cette opération sur un serveur de développement ou pendant une maintenance, car `_GM` contient aussi le reste du gamemode. Si une ancienne image reste affichée, utilise un nouveau nom de fichier et actualise le chemin dans la configuration. Aucune installation npm ni recompilation n'est nécessaire pour ces réglages.

## Sécurité avant mise en ligne

Avant chaque publication ou dépôt Git :

- vérifie que `server.cfg` contient uniquement des placeholders ;
- ne joins jamais une base de données runtime, un dossier `cache`, `txData` ou des logs ;
- ne publie aucun `.env`, token Discord, webhook, clé API ou identifiant administrateur personnel ;
- ne joins pas les `node_modules` des sources web ;
- renouvelle immédiatement toute clé accidentellement publiée.

Le `.gitignore` fourni protège les emplacements les plus courants, mais il ne remplace pas une vérification avant publication.

## État et support

La base a fait l'objet de validations statiques et de nombreux essais en jeu pendant sa reconstruction. Une installation FiveM reste dépendante de ses artifacts, de sa base SQL, des versions de ressources et de sa configuration locale. Lis la console serveur et le F8 client lors du premier démarrage.

Pour les corrections, améliorations, futures mises à jour et présentations de projets :

### **ak4therapyst — 7M Therapyst**

### **Discord : [discord.gg/HFHHMezSYF](https://discord.gg/HFHHMezSYF)**

## Crédits et droits

Cette édition correspond au travail de reconstruction, d'intégration, de correction et de modernisation réalisé par **ak4therapyst / 7M Therapyst**.

Les bibliothèques et ressources tierces restent la propriété de leurs auteurs respectifs. Leurs mentions, licences et liens de support d'origine doivent être conservés. La présence d'un fichier dans ce package ne remplace pas une autorisation de redistribution : vérifie les conditions de chaque ressource, particulièrement pour les scripts commerciaux ou protégés par escrow.

Merci à toutes les personnes qui testeront, documenteront les erreurs proprement et contribueront à faire évoluer cette base.
