// Logo d'entreprise dans l'application Services de sd-phone (VFW).
//
// L'interface est livrée compilée (web/build/assets) : le badge d'une entreprise ne sait afficher
// qu'un emoji sur un disque de couleur. Ce script lui apprend à afficher un logo (image) à la place
// de l'emoji, quand le serveur en envoie un (champ `logo` des entreprises et des conversations,
// voir server/services/actions.lua).
//
// Idempotent, et à relancer après chaque mise à jour de sd-phone (le nom du fichier compilé change
// avec son contenu, d'où la recherche par motif) :
//
//     node patches/vfw/apply-services-logo.mjs
//
// Ce que le script change dans Services-*.js :
//   1. le composant de badge `W` reçoit `logo` et affiche <img> (repli sur l'emoji si l'image
//      ne charge pas) ;
//   2. ses trois points d'appel (fiche d'entreprise, ligne de conversation, en-tête de
//      conversation) transmettent `logo`.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const assets = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'web', 'build', 'assets');
const candidates = readdirSync(assets).filter((f) => /^Services-.*\.js$/.test(f));
if (candidates.length !== 1) {
  console.error(`attendu un seul Services-*.js dans ${assets}, trouvé : ${candidates.join(', ') || 'aucun'}`);
  process.exit(1);
}

const file = join(assets, candidates[0]);
let src = readFileSync(file, 'utf8');

if (src.includes('/*vfw-logo*/')) {
  console.log(`${candidates[0]} : déjà patché`);
  process.exit(0);
}

const BADGE_OLD =
  'function W({color:e,emoji:t,size:n=50}){return(0,U.jsx)(`div`,{className:`flex shrink-0 items-center justify-center rounded-full leading-none`,style:{background:e,width:n,height:n,fontSize:Math.round(n*.52)},children:t})}';
const BADGE_NEW =
  'function W({color:e,emoji:t,logo:l,size:n=50}){/*vfw-logo*/let[b,B]=(0,H.useState)(!1);return(0,U.jsx)(`div`,{className:`flex shrink-0 items-center justify-center overflow-hidden rounded-full leading-none`,style:{background:e,width:n,height:n,fontSize:Math.round(n*.52)},children:l&&!b?(0,U.jsx)(`img`,{src:l,alt:``,draggable:!1,onError:()=>B(!0),style:{width:`100%`,height:`100%`,objectFit:`cover`}}):t})}';

const CALLS = [
  ['W,{color:e.color,emoji:e.emoji,size:58}', 'W,{color:e.color,emoji:e.emoji,logo:e.logo,size:58}', 2],
  ['W,{color:t.color,emoji:t.emoji,size:64}', 'W,{color:t.color,emoji:t.emoji,logo:t.logo,size:64}', 1],
];

function replaceExactly(text, from, to, expected) {
  const parts = text.split(from);
  const found = parts.length - 1;
  if (found !== expected) {
    console.error(`motif trouvé ${found} fois au lieu de ${expected} : ${from.slice(0, 70)}…`);
    console.error('Le bundle a changé : revoir les motifs de ce script avant de continuer.');
    process.exit(1);
  }
  return parts.join(to);
}

src = replaceExactly(src, BADGE_OLD, BADGE_NEW, 1);
for (const [from, to, expected] of CALLS) src = replaceExactly(src, from, to, expected);

writeFileSync(file, src);
console.log(`${candidates[0]} : logo d'entreprise ajouté (badge + 3 points d'appel)`);
