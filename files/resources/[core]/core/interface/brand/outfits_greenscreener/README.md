# Images des vêtements

Générées depuis le hub Gestion → Images → Vêtements (« Générer les images ») :
capture sur fond vert, détourage, puis **upload sur FiveManage** avec la clé
`FIVEMANAGE_MEDIA_API_KEY` de `server.cfg` (dossier `core_fivemanage_outfits_path`).

`manifest.json` (écrit par le serveur) associe chaque fichier à son URL :

    { "male": { "clothing": { "shoes": { "12.webp": "https://…", "12_1.webp": "https://…" } } } }

Côté client, `VFW.OutfitImage(sexe, kind, dossier, drawable, texture)` renvoie cette
URL, ou à défaut le chemin CDN historique `outfits_greenscreener/<sexe>/<kind>/<dossier>/<d>[_<t>].webp`
(fichiers déposés ici ou sur le CDN externe). `aucun.svg` = vignette « Aucun ».
