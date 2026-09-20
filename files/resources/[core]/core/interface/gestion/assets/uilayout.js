(function () {
  var page = null

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

  function ensurePage() {
    if (page) return page
    page = document.createElement('div')
    page.className = 'ul-page'
    page.innerHTML = [
      '<h2>Orientation des interfaces</h2>',
      '<p>Choix serveur pour tous les joueurs. Enregistré dans ui_layout.json, donc ça reste après reboot. Chaque joueur peut encore changer le sien dans F5.</p>',
      '<div class="ul-grid">',
      '<label class="ul-card"><div><strong>HUD</strong><span>Staff, faim / soif, vie</span></div><select id="ul-hud"><option value="vertical">Vertical</option><option value="horizontal">Horizontal</option></select></label>',
      '<label class="ul-card"><div><strong>Menus</strong><span>Menus VUI</span></div><select id="ul-menu"><option value="vertical">Vertical</option><option value="horizontal">Horizontal</option></select></label>',
      '<label class="ul-card"><div><strong>Notifications</strong><span>File des notifications</span></div><select id="ul-notif"><option value="vertical">Vertical</option><option value="horizontal">Horizontal</option></select></label>',
      '</div>',
      '<div class="ul-bar"><button type="button" id="ul-save">Enregistrer pour tous</button><button type="button" class="is-ghost" id="ul-back">Retour</button></div>',
      '<div class="ul-msg" id="ul-msg"></div>'
    ].join('')
    document.body.appendChild(page)
    document.getElementById('ul-back').addEventListener('click', hide)
    document.getElementById('ul-save').addEventListener('click', save)
    return page
  }

  function setMsg(text, err) {
    var el = document.getElementById('ul-msg')
    if (!el) return
    el.textContent = text || ''
    el.classList.toggle('is-err', !!err)
  }

  function fill(data) {
    ;['hud', 'menu', 'notif'].forEach(function (key) {
      var el = document.getElementById('ul-' + key)
      if (el && data[key]) el.value = data[key]
    })
  }

  function hide() {
    if (page) page.classList.remove('is-on')
  }

  function open() {
    ensurePage()
    setMsg('')
    page.classList.add('is-on')
    post('gestion:uilayout:open', {}).then(function (res) {
      if (!res || !res.ok) {
        setMsg((res && res.error) || 'Impossible de charger.', true)
        return
      }
      fill(res)
    })
  }

  function save() {
    var payload = {
      hud: document.getElementById('ul-hud').value,
      menu: document.getElementById('ul-menu').value,
      notif: document.getElementById('ul-notif').value
    }
    post('gestion:uilayout:save', payload).then(function (res) {
      if (!res || !res.ok) {
        setMsg((res && res.error) || 'Enregistrement impossible.', true)
        return
      }
      fill(res)
      setMsg(res.message || 'Enregistré pour tous les joueurs.')
    })
  }

  window.__openUiLayout = open
})()
