(function () {
  function setBrand(data) {
    if (!data || typeof data !== 'object') return
    var name = String(data.name || '').trim()
    if (!name && typeof data.staffTitle === 'string') {
      name = data.staffTitle.replace(/\s+Staff$/i, '').trim()
    }
    if (!name) return
    var safe = name.replace(/["\\]/g, '')
    var root = document.documentElement.style
    root.setProperty('--vui-brand-staff', '"' + safe + ' Staff"')
    root.setProperty('--vui-brand-name', '"' + safe + '"')
  }

  function setOffset(data) {
    var root = document.documentElement
    if (!data || !data.enabled) {
      root.classList.remove('vui-free', 'vui-free-right')
      return
    }
    var x = Number(data.x)
    var y = Number(data.y)
    var w = Number(data.w)
    if (!isFinite(x)) x = 2
    if (!isFinite(y)) y = 2.2
    if (!isFinite(w) || w <= 0) w = 26
    var side = data.side === 'right' || data.side === 'left'
      ? data.side
      : (x + w / 2 >= 50 ? 'right' : 'left')
    root.classList.add('vui-free')
    root.classList.toggle('vui-free-right', side === 'right')
    root.style.setProperty('--vui-left', x + '%')
    root.style.setProperty('--vui-top', y + '%')
    root.style.setProperty('--vui-width', w + '%')
  }

  function setPreviewOffset(data) {
    var root = document.documentElement
    var tag = document.getElementById('vui-preview-place')
    if (!tag) {
      tag = document.createElement('style')
      tag.id = 'vui-preview-place'
      document.head.appendChild(tag)
    }
    if (!data || !data.enabled) {
      root.classList.remove('vui-preview-free')
      tag.textContent = ''
      return
    }
    var x = Number(data.x)
    var y = Number(data.y)
    if (!isFinite(x)) x = 29.5
    if (!isFinite(y)) y = 2.2
    root.classList.add('vui-preview-free')
    root.style.setProperty('--vui-preview-left', x + '%')
    root.style.setProperty('--vui-preview-top', y + '%')
    tag.textContent =
      '.vui__menu__playerPreview{' +
        'position:fixed!important;' +
        'left:' + x + '%!important;' +
        'top:' + y + '%!important;' +
        'right:auto!important;' +
        'bottom:auto!important;' +
      '}'
  }

  window.addEventListener('message', function (e) {
    var msg = e && e.data
    if (!msg) return
    if (msg.action === 'vui:setBranding') setBrand(msg.data)
    if (msg.action === 'vui:setOffset') setOffset(msg.data)
    if (msg.action === 'vui:setPreviewOffset') setPreviewOffset(msg.data)
    if (msg.action === 'vui:setOrientation') {
      document.documentElement.classList.toggle('ui-orient-menu-h', msg.data && msg.data.orientation === 'horizontal')
    }
  })

  function boot() {
    var resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'VUI'
    fetch('https://' + resource + '/vui:getBranding', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}'
    }).then(function (r) { return r.json() }).then(setBrand).catch(function () {})
    fetch('https://' + resource + '/vui:getOffset', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}'
    }).then(function (r) { return r.json() }).then(setOffset).catch(function () {})
    fetch('https://' + resource + '/vui:getPreviewOffset', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}'
    }).then(function (r) { return r.json() }).then(setPreviewOffset).catch(function () {})
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot)
  } else {
    boot()
  }
})()
