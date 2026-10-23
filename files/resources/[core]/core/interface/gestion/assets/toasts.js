(function () {
  'use strict'

  var layer = null

  function getLayer() {
    if (layer && layer.isConnected) return layer
    layer = document.createElement('div')
    layer.id = 'gestion-toast-layer'
    layer.setAttribute('aria-live', 'polite')
    document.body.appendChild(layer)
    return layer
  }

  function cleanText(value) {
    return String(value == null ? '' : value)
      .replace(/<[^>]*>/g, '')
      .replace(/~[a-zA-Z]+~/g, '')
      .trim()
  }

  function showToast(data) {
    data = data && typeof data === 'object' ? data : { message: data }
    var message = cleanText(data.message || data.content || data.mainMessage)
    if (!message) return

    var variant = cleanText(data.variant || data.level || 'info').toLowerCase()
    if (variant === 'danger' || variant === 'failed') variant = 'error'
    if (variant === 'success') variant = 'success'
    if (variant !== 'error' && variant !== 'warning' && variant !== 'success') variant = 'info'

    var durationSeconds = Number(data.duration)
    if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) durationSeconds = 5
    var duration = Math.max(1800, Math.min(15000, durationSeconds * 1000))

    var toast = document.createElement('div')
    toast.className = 'gestion-toast'
    toast.dataset.variant = variant
    toast.style.setProperty('--toast-duration', duration + 'ms')

    var title = document.createElement('p')
    title.className = 'gestion-toast__title'
    title.textContent = cleanText(data.subtitle || data.title || 'Gestion') || 'Gestion'

    var body = document.createElement('p')
    body.className = 'gestion-toast__message'
    body.textContent = message

    var timer = document.createElement('span')
    timer.className = 'gestion-toast__timer'
    toast.appendChild(title)
    toast.appendChild(body)
    toast.appendChild(timer)

    var host = getLayer()
    host.prepend(toast)
    while (host.children.length > 4) host.lastElementChild.remove()

    window.setTimeout(function () {
      toast.classList.add('is-leaving')
      window.setTimeout(function () { toast.remove() }, 220)
    }, duration)
  }

  window.addEventListener('message', function (event) {
    var payload = event && event.data
    if (!payload || payload.action !== 'gestion:toast') return
    showToast(payload.data)
  })
})()
