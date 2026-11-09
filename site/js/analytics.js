(function () {
  'use strict';
  var ID = 'G-CS2NHYQYX0';
  var KEY = 'castlei-analytics-consent';

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

  function closeBanner() {
    var b = document.getElementById('consent');
    if (b) b.remove();
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

  function showBanner() {
    if (document.getElementById('consent')) return;
    var box = document.createElement('div');
    box.className = 'consent';
    box.id = 'consent';
    box.setAttribute('role', 'region');
    box.setAttribute('aria-label', 'Analytics cookies');

    var p = document.createElement('p');
    p.appendChild(document.createTextNode(
      'May we use Google Analytics cookies to count visits and see which pages are useful? ' +
      'No ads and your data is never sold. '));
    var a = document.createElement('a');
    a.href = '/privacy#website';
    a.textContent = 'Details';
    p.appendChild(a);
    box.appendChild(p);

    var row = document.createElement('div');
    row.className = 'row';
    var yes = document.createElement('button');
    yes.type = 'button';
    yes.className = 'primary';
    yes.textContent = 'Accept analytics';
    yes.addEventListener('click', function () { choose('granted'); });
    var no = document.createElement('button');
    no.type = 'button';
    no.textContent = 'Decline';
    no.addEventListener('click', function () { choose('denied'); });
    row.appendChild(yes);
    row.appendChild(no);
    box.appendChild(row);
    document.body.appendChild(box);
    yes.focus({ preventScroll: true });
  }

  document.addEventListener('DOMContentLoaded', function () {
    var choice = stored();
    if (choice === 'granted') {
      loadAnalytics();
    } else if (!choice && !signal) {
      showBanner();
    }
    var settings = document.getElementById('analytics-settings');
    if (settings) settings.addEventListener('click', showBanner);
  });

  // Measure clicks on elements marked data-event (only after consent).
  document.addEventListener('click', function (e) {
    var el = e.target.closest ? e.target.closest('[data-event]') : null;
    if (el && window.gtag && stored() === 'granted') {
      window.gtag('event', el.getAttribute('data-event'));
    }
  });
})();
