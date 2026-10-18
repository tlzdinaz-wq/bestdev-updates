(function () {
  var styles = { classic: true, glass: true, neon: true, ribbon: true, orbs: true, line: true }
  var alias = { compact: 'glass', bar: 'ribbon', minimal: 'line', pills: 'orbs' }
  var lastPlace = null
  var STORE = 'aurora_staff_hud_place'

  function place(data) {
    if (!data) return
    var x = Number(data.x)
    var y = Number(data.y)
    if (!isFinite(x) || !isFinite(y)) return
    lastPlace = { x: x, y: y }
    try { localStorage.setItem(STORE, JSON.stringify(lastPlace)) } catch (err) {}
    var root = document.documentElement
    root.classList.add('sd-placed')
    root.style.setProperty('--sd-left', x + '%')
    root.style.setProperty('--sd-top', y + '%')
  }

  function applyStyle(name) {
    if (alias[name]) name = alias[name]
    if (typeof name !== 'string' || !styles[name]) name = 'classic'
    var root = document.documentElement
    Object.keys(styles).forEach(function (id) {
      root.classList.remove('sd-style-' + id)
    })
    root.classList.add('sd-style-' + name)
    if (lastPlace) place(lastPlace)
  }

  try {
    var saved = JSON.parse(localStorage.getItem(STORE) || 'null')
    if (saved) place(saved)
  } catch (err) {}

  window.addEventListener('message', function (e) {
    var msg = e && e.data
    if (!msg || !msg.action) return
    if (msg.action === 'staffHud:place') place(msg.data)
    if (msg.action === 'staffHud:style') {
      applyStyle(typeof msg.data === 'string' ? msg.data : (msg.data && msg.data.style))
    }
  })
})()
