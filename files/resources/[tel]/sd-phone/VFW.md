# sd-phone sur VFW (framework du serveur)

sd-phone ne connaît nativement que QBox, QBCore, ESX, ox_core et ND. Cette copie a un **sixième
backend : `vfw`**, qui pilote la ressource `core`. Ce fichier dit ce qui a été branché, où, et
comment le vérifier.

## Principe

Le pont de sd-phone (`bridge/`) ne copie jamais l'objet VFW (skin, inventaire, permissions : il
est lourd). Il appelle des **exports `Phone*` de `core`**, résolus à chaque appel, donc valables
après un redémarrage de `core` :

| Côté | Fichier |
|---|---|
| `core` — serveur | `resources/[core]/core/plugins/015_Features/server/phone/360_phone_bridge.lua` |
| `core` — client | `resources/[core]/core/plugins/015_Features/client/phone.lua` |
| sd-phone — appel des exports | `bridge/shared/vfw.lua` (`vfw.call`) |
| sd-phone — détection | `bridge/shared/framework.lua` (`GetResourceState('core')`, testé en premier) |

Le premier échec de chaque export est écrit dans la console (`[sd-phone:vfw] core export … failed`),
sinon une erreur côté `core` ressemblerait à un joueur absent.

## Correspondance des données

| Notion sd-phone | Équivalent VFW |
|---|---|
| identifiant du personnage | `characters.identifier` (`char1:license:…`) |
| espèces | item d'inventaire `money` |
| banque | compte `bank` |
| argent sale | item `dirty_money` |
| société d'un métier | table `society_accounts` (via `VFW.Bank`) |
| véhicules | `owned_vehicles` (+ tables `garages` et `pounds` pour les noms et positions) |
| propriétés | `properties` + `property_access` (liste seule) |
| annuaire de numéros | `character_phones` — **recopié par sd-phone** à chaque attribution |
| fiche citoyen (MDT) | `characters` joint à `character_phones` |

## Ce qui est branché

- **Joueur, métier, grade, patron, service** : métier principal et `job2`. Le patron vient du
  drapeau `is_boss` du grade (pas de seuil à régler).
- **Argent** : espèces, banque, argent sale ; virement vers un personnage **hors ligne** (même
  fonction que la banque de `core`).
- **Items** : ajout, retrait, comptage, poids, **métadonnées par emplacement** (téléphones
  uniques / cartes SIM possibles), objet utilisable. Les variantes de téléphone et la SIM sont
  créées dans la table `items` au démarrage (`SeedEsxItems`).
- **Sociétés** : solde, dépôt, retrait, grades (`job_grades`), employés (`characters`).
- **Garages / fourrière** : liste, statut, position du garage ou de la fourrière.
- **Logement** : liste des propriétés (verrouillage et clés restent dans le menu de `core`).
- **Numéros** : à l'arrivée d'un personnage, sd-phone reprend le numéro déjà présent dans
  `character_phones` (posé par le gouvernement avant sd-phone) ; sinon il en attribue un. La
  tablette du gouvernement passe par l'export `setPhoneNumberByIdentifier`.
- **Notifications** : celles de `core` (pas de boîte ox_lib dans un coin).
- **TIG** : le téléphone est désactivé pendant les travaux d'intérêt général.
- **Applications maison** (LifeInvader, Weazel News, Taxi) : toujours enregistrées via les
  exports `lb-phone`, que sd-phone sait répondre.

## Entreprises : tous les métiers, y compris ceux de Gestion

L'annuaire de l'application Services liste **tous les métiers du serveur** — ceux déjà en base comme
ceux créés plus tard dans le builder de Gestion — et suit chaque création, modification ou
suppression **sans redémarrage**. Un métier sans société (ou sans logo) apparaît quand même, avec un
badge emoji. Le logo, l'adresse, la position (repère de la carte, sinon point du patron) et la couleur
d'accent viennent de la société du métier quand elle existe. Le chemin :

- `core` annonce `vfw:society:changed` à chaque rechargement ou suppression d'une société et à
  chaque rechargement des métiers (`modules/society/server/220_society_store.lua`) ;
- sd-phone relit l'export `PhoneCompanies` et réécrit `config.Services.Companies` en place
  (`server/vfwcompanies.lua`), puis reconstruit les index de `server/services/actions.lua` ;
- les entrées écrites à la main dans `configs/services.lua` (lignes 911 / 912 / 913...) restent
  prioritaires ; elles reçoivent seulement le logo, et l'adresse / la position si elles n'en ont pas.
  Le bloc `Auto` règle les exclusions et le badge par type de société.

Le **logo** s'affiche grâce à un correctif du bundle compilé (le badge ne connaissait que
l'emoji) : `node patches/vfw/apply-services-logo.mjs`. Idempotent, **à relancer après chaque
mise à jour de sd-phone** ; il refuse de rien changer si le bundle ne ressemble plus à ce qu'il attend.

## SQL

Le `esx_items.sql` d'origine de sd-phone ne s'importait pas ici (colonnes `rare` / `can_remove`
inexistantes). `sql/esx_items.sql` (dans le dossier de sd-phone) a été réécrit : il lit les colonnes de la
table `items` de la base sélectionnée et n'écrit que celles qui existent. Un seul fichier pour le schéma
de ce serveur, pour ESX d'origine et pour l'ancien ESX ; relançable sans risque (une ligne existante n'est
jamais modifiée). Il affiche « N item(s) ajouté(s) », ou un message clair si la table ou la base manque.
Importer : sélectionner la base, onglet Importer, choisir le fichier. Ou ne rien faire : sd-phone crée les
mêmes lignes au démarrage. Toutes les autres tables du téléphone sont créées par sd-phone lui-même.
Test : MariaDB 10.4 (XAMPP), mode strict et mode normal. Non testé sur MySQL 8.

## Volontairement laissé de côté

- **Gangs** : pas de notion équivalente dans VFW.
- **Multi-métiers et factures d'entreprise** (`InvoicesEnabled = false`) : liés au modèle
  « métiers sauvegardés » que VFW n'a pas ; `core` a sa propre facturation.
- **Valet** (livraison de véhicule depuis l'appli) : désactivé par défaut ; il ferait apparaître
  un véhicule sans passer par le module de garage de `core`.
- **MDT / EMS / DOJ** : désactivés par défaut (`configs/mdt.lua`). Les lectures de personnes et de
  véhicules sont câblées, la prison et le dispatch ne le sont pas.
- **Prop du téléphone en main** : les modèles `sd_phone_<couleur>` viennent d'une ressource à part
  (`sd-phone-props`), absente ici. Le téléphone fonctionne sans ; la main reste vide.

## Vérifier après un démarrage

1. Console : `Framework detected: vfw`, puis `society provider: vfw (society_accounts)` et
   `registered … VFW item(s)` au premier démarrage.
2. Avoir l'item `phone` (`/giveitem`), appuyer sur **F1** : le téléphone s'ouvre.
3. Ouvrir Banque : le solde est celui du compte `bank` ; faire un virement vers un joueur connecté
   puis vers un personnage hors ligne.
4. `SELECT * FROM character_phones` : une ligne par personnage ayant ouvert une session.
5. Donner un métier au joueur (menu staff) : l'appli Services affiche l'entreprise.

## Pour modifier le pont

Toute lecture ou écriture d'état du jeu passe par un export `Phone*` : ajouter un export dans
`360_phone_bridge.lua`, l'appeler par `vfw.call('NomExport', …)` côté sd-phone. Ne pas lire
l'objet `getSharedObject()` de `core` depuis sd-phone.


## Mettre à jour sd-phone

Méthode utilisée pour passer de 1.0.7 à 1.0.9 (29 octobre 2026) en gardant toutes les modifications ci-dessus :

1. Télécharger le `sd-phone.zip` de la version d'origine installée et celui de la nouvelle version sur
   https://github.com/Samuels-Development/sd-phone/releases, chacun dans un dossier vide.
2. Comparer trois versions fichier par fichier : l'ancienne d'origine, ce dossier, la nouvelle :
   - fichier que tu n'as pas touché : on prend la nouvelle version ;
   - fichier modifié ici et inchangé en amont : on garde le tien ;
   - fichier modifié des deux côtés : fusion à trois (`git merge-file`). Si les deux côtés ont ajouté du code au même
     endroit, garder les deux (cas de `bridge/server/housing.lua` : l'adaptateur `vfw` et le nouvel adaptateur d'amont) ;
   - fichiers ajoutés ici (`VFW.md`, `bridge/shared/vfw.lua`, `server/vfw.lua`, `server/vfwcompanies.lua`,
     `patches/vfw/`, `sql/esx_items.sql`) et `.secret` : jamais touchés.
3. L'interface compilée (`web/build/assets`) est remplacée en bloc par celle de la nouvelle version, puis
   `node patches/vfw/apply-services-logo.mjs` est relancé.
4. Contrôler la syntaxe de tous les fichiers Lua, sauvegarder l'ancien dossier hors de la base, installer, puis
   `restart sd-phone`. Les tables du téléphone se mettent à jour toutes seules au démarrage.
