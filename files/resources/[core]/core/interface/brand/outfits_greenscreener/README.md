# Images des vêtements

Générées depuis le hub Gestion → Images → Vêtements (« Générer les images ») :
capture sur fond vert, détourage, puis **upload sur FiveManage** avec la clé
`FIVEMANAGE_MEDIA_API_KEY` de `server.cfg` (dossier `core_fivemanage_outfits_path`).

Catégories photographiables (même liste que la boutique) :

- vêtements : `torso2` (haut), `undershirt`, `torso` (bras), `leg`, `shoes`, `bags`, `armor`, `decals`, `mask`, `accessory`
- props : `hat`, `glasses`, `watch`, `ear`, `bracelet`

`manifest.json` (écrit par le serveur) associe chaque fichier à son URL :

    { "male": { "clothing": { "shoes": { "12.webp": "https://…", "12_1.webp": "https://…" } } } }

Côté client, `VFW.OutfitImage(sexe, kind, dossier, drawable, texture)` renvoie cette
URL, ou à défaut la vignette `aucun.svg`.
