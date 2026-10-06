(function () {
    'use strict';

    // Sibling of the React root: AFK updates never re-render the other HUDs.
    var panel = document.createElement('section');
    panel.className = 'afk-timer';
    panel.hidden = true;
    panel.setAttribute('aria-label', 'Session en zone AFK');
    panel.innerHTML = '<header class="afk-timer__header">' +
        '<span class="afk-timer__badge"><svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="10" cy="10" r="7.2"/><path d="M10 5.5V10l3 2" stroke-linecap="round" stroke-linejoin="round"/></svg>ZONE AFK</span>' +
        '<span class="afk-timer__status">EN COURS</span></header>' +
        '<div class="afk-timer__body"><div><time class="afk-timer__clock">00:00:00</time><span class="afk-timer__label">DURÉE DE SESSION</span></div>' +
        '<div class="afk-timer__points"><b class="afk-timer__points-value">0</b><span class="afk-timer__label afk-timer__points-label">POINTS AFK</span></div></div>';
    document.body.appendChild(panel);

    var clock = panel.querySelector('.afk-timer__clock');
    var points = panel.querySelector('.afk-timer__points-value');
    var pointsLabel = panel.querySelector('.afk-timer__points-label');
    var elapsedBase = 0;
    var anchor = 0;
    var interval = null;
    var compactPoints = new Intl.NumberFormat('fr-FR', { notation: 'compact', maximumFractionDigits: 1 });

    function nonNegative(value, fallback) {
        var number = Number(value);
        return Number.isFinite(number) && number >= 0 ? Math.floor(number) : fallback;
    }

    function renderClock() {
        var elapsed = Math.floor(elapsedBase + Math.max(0, performance.now() - anchor) / 1000);
        var hours = Math.floor(elapsed / 3600);
        var minutes = Math.floor((elapsed % 3600) / 60);
        var seconds = elapsed % 60;
        clock.textContent = String(hours).padStart(2, '0') + ':' +
            String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
        clock.dateTime = 'PT' + elapsed + 'S';
    }

    function renderPoints(value) {
        var total = nonNegative(value, 0);
        points.textContent = total > 999999 ? compactPoints.format(total) : String(total);
        points.title = String(total) + ' points AFK';
        points.classList.toggle('is-long', points.textContent.length > 5);
        pointsLabel.textContent = total === 1 ? 'POINT AFK' : 'POINTS AFK';
    }

    function synchronizeClock(data) {
        elapsedBase = nonNegative(data.elapsed, 0);
        // The host stamps before queueing: iframe boot must not reset session time.
        var receivedAt = Number(data.receivedAt);
        if (Number.isFinite(receivedAt) && receivedAt > 0) {
            elapsedBase += Math.max(0, Date.now() - receivedAt) / 1000;
        }
        anchor = performance.now();
        renderClock();
    }

    function hide() {
        panel.hidden = true;
        if (interval !== null) clearInterval(interval);
        interval = null;
    }

    window.addEventListener('message', function (event) {
        var message = event && event.data;
        if (!message || typeof message.action !== 'string') return;
        var data = message.data && typeof message.data === 'object' ? message.data : {};
        switch (message.action) {
            case 'hud:afk:show':
                synchronizeClock(data);
                renderPoints(data.points);
                panel.hidden = false;
                if (interval === null) interval = setInterval(renderClock, 1000);
                break;
            case 'hud:afk:update':
                if (panel.hidden) return;
                if (Object.prototype.hasOwnProperty.call(data, 'points')) renderPoints(data.points);
                if (Object.prototype.hasOwnProperty.call(data, 'elapsed')) synchronizeClock(data);
                break;
            case 'hud:afk:hide':
                hide();
                break;
        }
    });
    window.addEventListener('pagehide', hide);
})();
