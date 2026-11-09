(function () {
  'use strict';
  var ID = 'G-CS2NHYQYX0';
  var KEY = 'castlei-analytics-consent';
  var COOKIE_ID = ID.replace('G-', '');

  // Respect Global Privacy Control / Do Not Track: no banner, no analytics.
  var signal = navigator.globalPrivacyControl === true ||
    navigator.doNotTrack === '1' || window.doNotTrack === '1';

  function stored() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function save(v) { try { localStorage.setItem(KEY, v); } catch (e) { /* ignore */ } }

  function clearCookies() {
    var host = location.hostname, parts = host.split('.');
    var domains = ['', 'domain=' + host + ';', 'domain=.' + parts.slice(-2).join('.') + ';'];
    document.cookie.split(';').forEach(function (c) {
      var name = c.split('=')[0].trim();
      if (name === '_ga' || name.indexOf('_ga_') === 0) {
        domains.forEach(function (d) { document.cookie = name + '=; Max-Age=0; path=/; ' + d; });
      }
    });
  }

  function loadAnalytics() {
    if (window.__castleiGA) return;
    window.__castleiGA = true;
    window['ga-disable-' + ID] = false;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', ID, {
      allow_google_signals: false,
      allow_ad_personalization_signals: false,
      cookie_expires: 33696000
    });
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(ID);
    document.head.appendChild(s);
  }

  var opener = null;

  function closeBanner() {
    var b = document.getElementById('consent');
    if (b) b.remove();
    document.removeEventListener('keydown', onKey);
    if (opener && document.contains(opener)) opener.focus();
    opener = null;
  }

  function choose(value) {
    var wasGranted = stored() === 'granted';
    save(value);
    closeBanner();
    if (value === 'granted') {
      loadAnalytics();
    } else {
      window['ga-disable-' + ID] = true;
      clearCookies();
      if (wasGranted || window.__castleiGA) location.reload();
    }
  }

  // Escape closes the banner and counts as "Decline".
  function onKey(e) { if (e.key === 'Escape') choose('denied'); }

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text) n.textContent = text;
    return n;
  }

  function icon() {
    var ns = 'http://www.w3.org/2000/svg';
    var svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('width', '28');
    svg.setAttribute('height', '28');
    svg.setAttribute('aria-hidden', 'true');
    svg.setAttribute('class', 'consent-icon');
    var path = document.createElementNS(ns, 'path');
    path.setAttribute('fill', 'currentColor');
    path.setAttribute('d', 'M12 2a10 10 0 1 0 10 10 4 4 0 0 1-4-4 4 4 0 0 1-4-4 2 2 0 0 0-2-2zM8.5 9a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3zm4 4.5a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3zM8 15a1 1 0 1 1 0 2 1 1 0 0 1 0-2z');
    svg.appendChild(path);
    return svg;
  }

  function showBanner(fromButton) {
    if (document.getElementById('consent')) return;
    opener = fromButton || null;
    var current = stored();

    var box = el('div', 'consent');
    box.id = 'consent';
    box.setAttribute('role', 'dialog');
    box.setAttribute('aria-modal', 'false');
    box.setAttribute('aria-labelledby', 'consent-title');
    box.setAttribute('aria-describedby', 'consent-text');
    box.tabIndex = -1;

    var head = el('div', 'consent-head');
    head.appendChild(icon());
    var title = el('h2', 'consent-title', 'Analytics cookies');
    title.id = 'consent-title';
    head.appendChild(title);
    var x = el('button', 'consent-x', '×');
    x.type = 'button';
    x.setAttribute('aria-label', 'Decline and close');
    x.addEventListener('click', function () { choose('denied'); });
    head.appendChild(x);
    box.appendChild(head);

    var text = el('p', 'consent-text',
      'May we use Google Analytics to count visits and see which pages help? ' +
      'No ads, nothing is sold, and the site works the same if you decline.');
    text.id = 'consent-text';
    box.appendChild(text);
    if (current) {
      box.appendChild(el('p', 'consent-status',
        'Your current choice: ' + (current === 'granted' ? 'accepted' : 'declined') + '.'));
    }

    var more = el('details', 'consent-more');
    more.appendChild(el('summary', '', 'What is collected?'));
    var ul = el('ul');
    [
      'Pages viewed and links clicked, your browser, device and language.',
      'Approximate location (country or city) from your IP address, which is not stored.',
      'How you arrived, for example from a search or another site.',
      'Two cookies, _ga and _ga_' + COOKIE_ID + ', with a random ID. They last up to 13 months.',
      'No Google Signals, no advertising features, no ad personalisation.'
    ].forEach(function (t) { ul.appendChild(el('li', '', t)); });
    more.appendChild(ul);
    var link = el('p', 'consent-link');
    var a = el('a', '', 'Read the privacy policy');
    a.href = '/privacy#website';
    link.appendChild(a);
    more.appendChild(link);
    box.appendChild(more);

    // Equal prominence: identical styling, size and placement rules.
    var row = el('div', 'consent-actions');
    var no = el('button', 'consent-btn', 'Decline');
    no.type = 'button';
    no.addEventListener('click', function () { choose('denied'); });
    var yes = el('button', 'consent-btn', 'Accept');
    yes.type = 'button';
    yes.addEventListener('click', function () { choose('granted'); });
    row.appendChild(no);
    row.appendChild(yes);
    box.appendChild(row);

    document.body.appendChild(box);
    document.addEventListener('keydown', onKey);
    // Move focus to the dialog itself (not a button) so nothing is pre-selected.
    box.focus({ preventScroll: true });
  }

  document.addEventListener('DOMContentLoaded', function () {
    var choice = stored();
    if (choice === 'granted') {
      loadAnalytics();
    } else if (!choice && !signal) {
      showBanner(null);
    }
    var settings = document.getElementById('analytics-settings');
    if (settings) settings.addEventListener('click', function () { showBanner(settings); });
  });

  // Measure clicks on elements marked data-event (only after consent).
  document.addEventListener('click', function (e) {
    var t = e.target.closest ? e.target.closest('[data-event]') : null;
    if (t && window.gtag && stored() === 'granted') {
      window.gtag('event', t.getAttribute('data-event'));
    }
  });
})();
