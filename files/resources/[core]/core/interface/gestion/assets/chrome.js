(function () {
  // Le menu traite Retour arrière comme « revenir ». Tant que la saisie est ouverte,
  // la touche ne doit effacer que le texte.
  document.addEventListener('keydown', function (e) {
    var el = e.target
    if (!el || !el.closest || !el.closest('.gh-modal')) return
    e.stopPropagation()
  })

  var last = { hud: 'vertical', menu: 'vertical', notif: 'vertical', gestionBg: '' }
  var panel = null
  var wired = false

  function resourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'core'
  }

  function post(name, payload) {
    return fetch('https://' + resourceName() + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload || {})
    }).then(function (r) { return r.json() }).catch(function () {
      return { ok: false, error: 'Pas de réponse du jeu.' }
    })
  }

  function cleanUrl(value) {
    var url = String(value || '').trim()
    if (!url) return ''
    var lower = url.toLowerCase()
    if (lower.indexOf('https://') !== 0 && lower.indexOf('http://') !== 0) return ''
    return url.slice(0, 1024)
  }

  function setBg(url) {
    url = cleanUrl(url)
    last.gestionBg = url
    var root = document.documentElement
    if (url) {
      root.style.setProperty('--gh-bg', 'url("' + url.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '")')
      root.classList.add('gh-has-bg')
    } else {
      root.style.setProperty('--gh-bg', 'none')
      root.classList.remove('gh-has-bg')
    }
    var input = document.getElementById('gh-bg-url')
    if (input && document.activeElement !== input) input.value = url
  }

  window.__setGestionBg = setBg

  function applyLayout(data) {
    if (!data || !data.ok) return
    if (data.hud) last.hud = data.hud
    if (data.menu) last.menu = data.menu
    if (data.notif) last.notif = data.notif
    setBg(data.gestionBg || '')
  }

  function loadLayout() {
    post('gestion:uilayout:open', {}).then(applyLayout)
  }

  function ensurePanel() {
    if (panel) return panel
    panel = document.createElement('div')
    panel.className = 'gh-bgpanel'
    panel.innerHTML = [
      '<div class="gh-bgpanel-card">',
      '<b>Fond de la tablette</b>',
      '<p>Colle un lien direct image (https). Enregistré pour tout le serveur.</p>',
      '<input id="gh-bg-url" type="url" maxlength="1024" placeholder="https://i.imgur.com/exemple.jpg" spellcheck="false">',
      '<div class="gh-bgpanel-bar">',
      '<button type="button" id="gh-bg-save">Enregistrer</button>',
      '<button type="button" class="is-ghost" id="gh-bg-clear">Retirer</button>',
      '<button type="button" class="is-ghost" id="gh-bg-close">Fermer</button>',
      '</div>',
      '<div class="gh-bgpanel-msg" id="gh-bg-msg"></div>',
      '</div>'
    ].join('')
    document.body.appendChild(panel)
    panel.addEventListener('click', function (ev) {
      if (ev.target === panel) panel.classList.remove('is-on')
    })
    document.getElementById('gh-bg-close').addEventListener('click', function () {
      panel.classList.remove('is-on')
    })
    document.getElementById('gh-bg-clear').addEventListener('click', function () {
      document.getElementById('gh-bg-url').value = ''
      saveBg('')
    })
    document.getElementById('gh-bg-save').addEventListener('click', function () {
      saveBg(document.getElementById('gh-bg-url').value)
    })
    return panel
  }

  function setMsg(text, err) {
    var el = document.getElementById('gh-bg-msg')
    if (!el) return
    el.textContent = text || ''
    el.classList.toggle('is-err', !!err)
  }

  function saveBg(url) {
    url = cleanUrl(url)
    setBg(url)
    setMsg('Enregistrement…', false)
    post('gestion:uilayout:save', {
      hud: last.hud,
      menu: last.menu,
      notif: last.notif,
      gestionBg: url
    }).then(function (res) {
      if (!res || !res.ok) {
        setMsg((res && res.error) || 'Enregistrement impossible.', true)
        return
      }
      applyLayout(res)
      setMsg(url ? 'Fond enregistré.' : 'Fond retiré.')
    })
  }

  function openPanel() {
    ensurePanel()
    setMsg('')
    document.getElementById('gh-bg-url').value = last.gestionBg || ''
    panel.classList.add('is-on')
    loadLayout()
  }

  function wireButtons() {
    var actions = document.querySelector('.gh-topbar-actions')
    if (!actions || actions.dataset.ghChrome) return
    actions.dataset.ghChrome = '1'
    var btn = document.createElement('button')
    btn.type = 'button'
    btn.className = 'gh-iconbtn gh-bgbtn'
    btn.title = 'Fond tablette'
    btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="10" r="1.4"/><path d="M21 16l-5.2-5.2a1.5 1.5 0 0 0-2.1 0L6 18"/></svg>'
    btn.addEventListener('click', openPanel)
    actions.insertBefore(btn, actions.firstChild)
  }

  function tick() {
    wireButtons()
    if (document.querySelector('.gh-root') && !wired) {
      wired = true
      loadLayout()
    }
    if (!document.querySelector('.gh-root')) wired = false
  }

  setInterval(tick, 400)
  document.addEventListener('DOMContentLoaded', tick)
})()
