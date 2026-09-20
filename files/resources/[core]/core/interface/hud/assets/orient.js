(function () {
  function apply(data) {
    if (!data) return
    var root = document.documentElement
    root.classList.toggle('ui-orient-hud-h', data.hud === 'horizontal')
    root.classList.toggle('ui-orient-menu-h', data.menu === 'horizontal')
    root.classList.toggle('ui-orient-notif-h', data.notif === 'horizontal')
  }

  window.addEventListener('message', function (e) {
    var msg = e && e.data
    if (msg && msg.action === 'nui:ui:orientation') apply(msg.data)
  })
})()
