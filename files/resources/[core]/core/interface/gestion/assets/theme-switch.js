// Gestion — choisir entre l'ancienne interface et la tablette.
//
// L'apparence « tablette » est posee par deux feuilles de style qui s'ajoutent a
// l'interface d'origine : `theme.css` (le chassis) et `pages.css` (l'interieur).
// Ni l'une ni l'autre ne contient de logique : les desactiver rend l'interface telle
// qu'elle etait avant, sans rien perdre des mises a jour du panneau, qui vivent dans
// le code de l'interface et dans le Lua.
//
// Le choix est garde sur la machine de chaque membre du staff. Rien ne part au
// serveur : c'est un confort d'affichage, pas un reglage de jeu.
//
// L'application initiale est faite par un petit script en tete d'`index.html`, et
// non ici : charge en `defer`, ce fichier s'executerait apres le premier rendu et on
// verrait la tablette apparaitre puis disparaitre.

(function () {
  var KEY = 'gestion-apparence'
  var CLASSIC = 'classique'
  var IDS = ['gh-theme-css', 'gh-pages-css']

  function isClassic() {
    try {
      return localStorage.getItem(KEY) === CLASSIC
    } catch (e) {
      // Navigation privee ou stockage bloque : on reste sur la tablette.
      return false
    }
  }

  function apply(classic) {
    for (var i = 0; i < IDS.length; i++) {
      var sheet = document.getElementById(IDS[i])
      if (sheet) sheet.disabled = classic
    }
    document.documentElement.classList.toggle('gh-classique', classic)
  }

  function save(classic) {
    try {
      if (classic) localStorage.setItem(KEY, CLASSIC)
      else localStorage.removeItem(KEY)
    } catch (e) {
      // Le choix vaudra pour la session en cours.
    }
  }

  function label(btn, classic) {
    btn.title = classic ? 'Revenir a la tablette' : 'Revenir a l\'ancienne interface'
    btn.setAttribute('aria-pressed', classic ? 'true' : 'false')
  }

  // Deux carres qui se chevauchent : on bascule d'une presentation a l'autre.
  var ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"'
    + ' stroke-linecap="round" stroke-linejoin="round">'
    + '<rect x="3" y="3" width="13" height="13" rx="2"/>'
    + '<path d="M8 21h11a2 2 0 0 0 2-2V8"/></svg>'

  function wire() {
    var actions = document.querySelector('.gh-topbar-actions')
    if (!actions || actions.dataset.ghSwitch) return
    actions.dataset.ghSwitch = '1'

    var btn = document.createElement('button')
    btn.type = 'button'
    btn.className = 'gh-iconbtn gh-skinbtn'
    btn.innerHTML = ICON
    label(btn, isClassic())

    btn.addEventListener('click', function () {
      var classic = !isClassic()
      save(classic)
      apply(classic)
      label(btn, classic)
    })

    actions.insertBefore(btn, actions.firstChild)
  }

  // Le panneau est monte et demonte par l'interface : on repose le bouton quand il
  // reapparait, comme le fait chrome.js pour le sien.
  setInterval(wire, 400)
  document.addEventListener('DOMContentLoaded', wire)
})()
