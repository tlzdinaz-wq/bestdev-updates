# Mise à jour Best Dev par FTP / SFTP

Applique les mises à jour publiées **directement sur l'hébergeur**, sans accès console.
Utile pour les hébergeurs FiveM qui ne donnent qu'un accès FTP : `update.bat` et `update.sh`
ne peuvent pas y tourner.

## Lancer

Double-cliquez sur **`LANCER.bat`**. La page s'ouvre sur <http://127.0.0.1:7788>.

À la première utilisation, les composants nécessaires s'installent tout seuls
(il faut [Node.js](https://nodejs.org) sur la machine).

En ligne de commande : `npm install` puis `npm start`.

## Utiliser

1. Choisir le protocole : **FTP**, **FTPS** (FTP chiffré) ou **SFTP** (sur SSH).
2. Renseigner hôte, port, utilisateur, mot de passe.
3. **Dossier du serveur** : celui qui *contient* `resources/` et `server.cfg`.
   Laisser vide si c'est la racine de l'accès FTP.
4. **Tester la connexion** — l'outil vérifie l'accès, trouve `resources/`, et lit la version
   installée dans `resources/[standalone]/updater/state.txt`.
5. **Mettre à jour** — il télécharge les archives publiées depuis la version installée
   jusqu'à la dernière, et téléverse uniquement les fichiers concernés.

Redémarrer le serveur à la fin.

## Ce qu'il fait exactement

- Lit la version installée **sur l'hébergeur**, pas sur votre machine.
- Applique **toutes** les versions manquantes, dans l'ordre : un serveur en retard de cinq
  versions reçoit les cinq archives, fusionnées pour n'envoyer chaque fichier qu'une fois,
  dans sa version la plus récente.
- Écrit la nouvelle version dans `state.txt` à la fin, pour que la prochaine mise à jour
  reparte du bon point.
- Ne supprime jamais de fichier.

## Fichiers `.new`

Les fichiers protégés — configurations, images de marque — arrivent en `<nom>.new` et
n'écrasent rien. Comparez-les avec les vôtres et reportez ce qui vous intéresse.
C'est le même principe qu'une installation manuelle par zip.

## Identifiants

Ils ne sont **ni enregistrés ni transmis ailleurs qu'à votre hébergeur**. Ils restent en
mémoire le temps de l'opération, sur votre machine. Le serveur n'écoute que sur
`127.0.0.1` : rien n'est accessible depuis l'extérieur.

## Si ça bloque

| Message | Cause |
|---|---|
| « aucun dossier resources ici » | Le dossier du serveur est faux : indiquez celui qui contient `resources/` |
| « Impossible de lire la version installée » | `state.txt` absent — installation jamais mise à jour, ou mauvais dossier |
| « Rien à appliquer entre X et Y » | La version installée est plus récente que la cible |
| Connexion refusée | Vérifiez le port : 21 en FTP/FTPS, 22 en SFTP |
