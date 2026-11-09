#!/usr/bin/env python3
"""Builds the static Castlei website into site/ (landing page, privacy policy,
terms, account deletion). No JavaScript; one stylesheet.

Edit the constants below (and the page text) and rerun:
    python3 tool/build_site.py
Deploy with:  firebase deploy --only hosting --project castlei
"""
import html
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent / "site"

NAME = "Castlei"
OPERATOR = "Ian Andwati"
EMAIL = "andwatiian@gmail.com"
DOMAIN = "castlei.andwati.com"
EFFECTIVE = "November 9, 2026"
YEAR = "2026"
GA_ID = "G-CS2NHYQYX0"  # Firebase web app "Castlei website" (Google Analytics 4)


def page(slug, title, description, body, nav_current=""):
    url = f"https://{DOMAIN}/" + ("" if slug == "index" else slug)
    links = [
        ("/#features", "Features"),
        ("/#plus", "Plus"),
        ("/privacy", "Privacy"),
        ("/terms", "Terms"),
    ]
    nav = "".join(
        f'<a href="{h}"{" aria-current=page" if h.strip("/") == nav_current else ""}>{t}</a>'
        for h, t in links
    )
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(description)}">
<link rel="canonical" href="{url}">
<meta name="theme-color" content="#0f4f49">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{NAME}">
<meta property="og:title" content="{html.escape(title)}">
<meta property="og:description" content="{html.escape(description)}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="https://{DOMAIN}/img/og.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.ico" sizes="48x48">
<link rel="icon" type="image/png" href="/img/icon-192.png" sizes="192x192">
<link rel="apple-touch-icon" href="/img/apple-touch-icon.png">
<link rel="stylesheet" href="/css/site.css">
<script src="/js/analytics.js" defer></script>
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<header class="top">
  <div class="wrap bar">
    <a class="brand" href="/"><img src="/img/icon-192.png" width="36" height="36" alt="">{NAME}</a>
    <nav aria-label="Main">{nav}</nav>
  </div>
</header>
<main id="main">
{body}
</main>
<footer class="foot">
  <div class="wrap">
    <div class="foot-grid">
      <div>
        <p class="brand small"><img src="/img/icon-192.png" width="28" height="28" alt="">{NAME}</p>
        <p class="muted">A private chess companion for Android.<br>Play Stockfish, review your games, drill tactics and openings.</p>
      </div>
      <div>
        <p class="label">Legal</p>
        <p><a href="/privacy">Privacy policy</a><br><a href="/terms">Terms of use</a><br><a href="/delete-account">Delete your account</a><br><button type="button" class="linklike" id="analytics-settings">Analytics settings</button></p>
      </div>
      <div>
        <p class="label">Contact</p>
        <p><a href="mailto:{EMAIL}">{EMAIL}</a></p>
      </div>
    </div>
    <p class="muted fine">&copy; {YEAR} {OPERATOR}. {NAME} and the Castlei logo are trademarks of {OPERATOR}.
    Includes open-source software; see <a href="/terms#open-source">Terms</a>.</p>
  </div>
</footer>
</body>
</html>
"""


def legal(slug, title, description, lead, sections, nav_current):
    toc = "".join(f'<li><a href="#{i}">{html.escape(t)}</a></li>' for i, t, _ in sections)
    body = "".join(
        f'<section id="{i}"><h2>{html.escape(t)}</h2>{c}</section>' for i, t, c in sections
    )
    return page(
        slug,
        f"{title} | {NAME}",
        description,
        f"""<div class="wrap legal">
<p class="eyebrow">{NAME}</p>
<h1>{title}</h1>
<p class="muted">Effective {EFFECTIVE}</p>
<p class="lead">{lead}</p>
<nav class="toc" aria-label="On this page"><p class="label">On this page</p><ol>{toc}</ol></nav>
{body}
</div>""",
        nav_current,
    )


# ----------------------------------------------------------------------------
# Landing page
# ----------------------------------------------------------------------------
def phone(src, alt, extra=""):
    return f'<figure class="phone {extra}"><img src="/img/{src}" width="540" height="1200" alt="{html.escape(alt)}" loading="lazy"></figure>'


INDEX = page(
    "index",
    f"{NAME} | Your private chess companion",
    "Play Stockfish, review your games with an evaluation graph, and drill tactics and opening repertoires. Works offline. Android.",
    f"""
<section class="hero">
  <div class="wrap hero-grid">
    <div>
      <p class="eyebrow">For Android</p>
      <h1>A little practice.<br>A stronger game.</h1>
      <p class="lead">{NAME} is a private chess companion. Play the Stockfish engine at five levels, review your games, and drill tactics and opening lines. It works fully offline.</p>
      <p class="cta">
        <span class="pill">Coming soon to Google Play</span>
        <a class="btn ghost" data-event="early_access_click" href="mailto:{EMAIL}?subject={NAME}%20early%20access">Ask for early access</a>
      </p>
      <ul class="ticks">
        <li>No account needed</li>
        <li>Stockfish on your device</li>
        <li>Your games stay on your phone</li>
      </ul>
    </div>
    <div class="hero-art">{phone("game.webp", "A game in progress in Castlei showing the French Defense opening name, the board with the last move highlighted, and the move list.")}</div>
  </div>
  <div class="battlements" aria-hidden="true"></div>
</section>

<section id="features" class="wrap section">
  <p class="eyebrow">What you can do</p>
  <h2>Everything a serious practice session needs</h2>
  <div class="cards">
    <article class="card"><h3>Play Stockfish</h3><p>Five difficulty levels from Gentle to Maximum, optional clocks, hints, takebacks and custom start positions. The engine runs on your device, so there is no waiting for a server.</p></article>
    <article class="card"><h3>Review your games</h3><p>Every move is compared with the engine's best. An evaluation graph shows where a game turned, and moves are marked as inaccuracies, mistakes or blunders, plus missed or allowed forced mates.</p></article>
    <article class="card"><h3>Daily tactics</h3><p>Thousands of puzzles from the open Lichess database, filtered by rating and theme, with hints and the full solution on request. They work offline, and you can add more packs.</p></article>
    <article class="card"><h3>Opening repertoires</h3><p>Build your own lines, then drill them with spaced repetition at 1, 3, 7, 14 and 30 day intervals. Transpositions are recognised, and opening names appear as you play.</p></article>
    <article class="card"><h3>Your library</h3><p>Import and export PGN, keep studies with variations, comments and arrows, search and filter your games, and mark favourites.</p></article>
    <article class="card"><h3>Private by design</h3><p>Your games live in a local database. Sign in only if you want cloud backup. Crash, performance and usage reports are anonymous and can each be switched off.</p></article>
  </div>
</section>

<section class="shots">
  <div class="wrap">
    <p class="eyebrow">A look inside</p>
    <h2>Calm, readable, made for the board</h2>
    <div class="shot-row">
      {phone("home.webp", "The Castlei home screen with a resume-game card, daily tactics and progress shortcuts, and a recent games list.")}
      {phone("puzzles.webp", "A tactical puzzle with rating and theme filters, a progress bar and hint and reveal buttons.")}
      {phone("study.webp", "The Study tab with the analysis board, tactical puzzles, puzzle collections and opening repertoires.")}
    </div>
  </div>
</section>

<section id="plus" class="wrap section">
  <p class="eyebrow">{NAME} Plus</p>
  <h2>Free to use. One optional unlock.</h2>
  <p class="lead narrow">Everything above is free. {NAME} Plus is a one-time purchase, with no subscription, that adds automatic cloud backup. It is not available yet; this is what it will include.</p>
  <div class="table-wrap">
  <table class="plans">
    <thead><tr><th scope="col">Cloud backup</th><th scope="col">Free</th><th scope="col">Plus</th></tr></thead>
    <tbody>
      <tr><th scope="row">Back up your games on demand</th><td>Yes, latest copy</td><td>Yes</td></tr>
      <tr><th scope="row">Automatic backup after finished games and daily</th><td>&ndash;</td><td>Yes</td></tr>
      <tr><th scope="row">Previous versions kept</th><td>1</td><td>5</td></tr>
      <tr><th scope="row">Export a backup file to your own storage</th><td>Yes</td><td>Yes</td></tr>
      <tr><th scope="row">Everything else in {NAME}</th><td>Free</td><td>Free</td></tr>
    </tbody>
  </table>
  </div>
</section>

<section class="wrap section oss">
  <p class="eyebrow">Open source</p>
  <h2>Built on great open-source work</h2>
  <p class="narrow">{NAME} stands on the Stockfish chess engine, the Lichess puzzle and opening data, the dartchess rules library, Flutter, and many other projects, each under its own license. The full list is in the app under Settings &rarr; About &rarr; Open-source software. Source code for GPL-licensed components is available on request at <a href="mailto:{EMAIL}">{EMAIL}</a>.</p>
</section>

<section class="wrap section last">
  <h2>Questions?</h2>
  <p class="narrow">Write to <a href="mailto:{EMAIL}">{EMAIL}</a>. To remove your account and cloud data, see <a href="/delete-account">Delete your account</a>.</p>
</section>
""",
)

# ----------------------------------------------------------------------------
# Privacy policy
# ----------------------------------------------------------------------------
PRIVACY = legal(
    "privacy",
    "Privacy policy",
    f"How {NAME} handles your data: what stays on your device, what is optional, and how to control or delete it.",
    f"{NAME} is built to work on your device. Your games and training stay there unless you choose to back them up. This policy explains what is collected when you use the app, why, and the choices you have. It applies to the {NAME} Android app and this website.",
    [
        ("who", "Who we are", f"<p>{NAME} is developed by {OPERATOR}, an individual developer (&ldquo;we&rdquo;, &ldquo;us&rdquo;). For privacy questions or requests write to <a href=\"mailto:{EMAIL}\">{EMAIL}</a>.</p>"),
        ("short", "The short version", """<ul>
<li>Your games, studies, drills and statistics are stored <strong>on your device</strong>.</li>
<li>An account is <strong>optional</strong>. You only need one for cloud backup.</li>
<li>Crash reports, performance timings and usage analytics are <strong>anonymous, on by default, and each can be switched off</strong> in Settings.</li>
<li>We never collect your positions, moves, comments, game titles or the contents of your files as analytics or crash data.</li>
<li>We do not sell your data, show ads, or use it for advertising.</li>
<li>This website uses analytics cookies <strong>only if you accept</strong>.</li>
</ul>"""),
        ("device", "Data that stays on your device", """<p>Games and their variations, comments and annotations, engine analysis results, repertoires and drill schedules, puzzle history, statistics, installed puzzle packs, and your preferences are stored in a local database in the app's private storage. We do not receive this data unless you use cloud backup, export a file, or share a diagnostics report yourself. Uninstalling the app removes it from your device.</p>
<p>Reminder notifications (due drills, the daily puzzle, an unfinished game) are scheduled on your device. They send no data to us.</p>"""),
        ("account", "Your account (optional)", f"""<p>If you choose to sign in, we use <strong>Firebase Authentication</strong> (Google) with Sign in with Google. We receive the identifiers Google provides for the account you pick: a unique account ID, your email address, your display name and your profile picture address. We use them to sign you in, to keep your cloud backups private to you, and to answer your requests. You can sign out or delete your account at any time (see <a href="/delete-account">Delete your account</a>).</p>"""),
        ("backup", "Cloud backup (only if you sign in)", """<p>When you tap <em>Back up now</em>, or when automatic backup runs after you unlock {name} Plus, the app uploads a backup archive to <strong>Cloud Firestore</strong>. The archive contains the data listed under &ldquo;Data that stays on your device&rdquo;: your games with their variations and comments, analysis results, repertoires, drill schedules, training history, the list of installed puzzle packs, and your preferences. It does not contain your email address.</p>
<p>The archive is stored in your own private area, in a Google data center in the United States (multi-region), and can only be read or deleted by your account through security rules. We keep your latest copy (up to five versions with Plus). Backups are removed when you delete them, when older versions are replaced, and when you delete your account. They are encrypted in transit and at rest by Google.</p>""".replace("{name}", NAME)),
        ("diagnostics", "Crash reports, performance and usage analytics", """<p>To fix problems and improve the app we use Google Firebase services. Each one has its own switch in <em>Settings &rarr; Privacy and diagnostics</em>, and each is <strong>on by default</strong>.</p>
<ul>
<li><strong>Crash reports (Firebase Crashlytics):</strong> the technical details of a crash or handled error, such as the stack trace, an error type and a short, scrubbed message, the app and engine versions, the device model and operating system version, and a Firebase installation ID. Error messages are cleaned of board positions (FEN), PGN headers and file paths before they are sent.</li>
<li><strong>Performance monitoring (Firebase Performance Monitoring):</strong> timings such as app start, engine search speed, import and backup durations, network request durations and frame rendering, with device and network characteristics (device model, operating system, app version, network type, approximate country).</li>
<li><strong>Usage analytics (Firebase Analytics):</strong> which screens and features are used and game outcomes as broad categories (for example win, loss or draw, difficulty level, game length range, whether hints were used), together with a Firebase installation ID, device and app details, and an approximate location derived from your IP address (the IP address itself is not stored). We do not use advertising identifiers, and ad personalisation is disabled.</li>
<li><strong>Announcements (Firebase Cloud Messaging and In-App Messaging):</strong> if enabled, the app registers with Firebase to receive occasional announcements, using a messaging registration token and the Firebase installation ID. You can turn announcements off in <em>Settings &rarr; Notifications</em>.</li>
<li><strong>Remote settings (Firebase Remote Config):</strong> the app periodically downloads configuration values (for example engine time limits); this involves your IP address and a Firebase installation ID.</li>
</ul>
<p>This information is not linked to the content of your games and we do not use it to identify you. Crashlytics data is kept for 90 days; the other services keep data for the standard periods set by Firebase, after which it is deleted automatically.</p>"""),
        ("website", "This website", f"""<p>When you visit this website we do not set analytics cookies unless you choose <em>Accept</em> in the banner. If you accept, we use <strong>Google Analytics</strong> (through Firebase) to count visits and see which pages and links are used. It records the pages you view and the links you click, your approximate location (country or city, derived from your IP address, which is not stored), the browser, device and language, and how you arrived (for example from a search or another site). It sets two cookies, <code>_ga</code> and <code>_ga_*</code>, which last up to 13 months and contain a random identifier. We do not use Google Signals, advertising features or ad personalisation, and we do not combine this data with the {NAME} app or with anything that identifies you.</p>
<p>If you decline, or your browser sends a Global Privacy Control or Do Not Track signal, no analytics script is loaded. You can change your choice at any time with <em>Analytics settings</em> in the footer of every page. Declining or withdrawing deletes the analytics cookies it set. The legal basis is your consent. Like any web host, Firebase Hosting keeps standard server logs (such as IP address and requested page) for security and operation.</p>"""),
        ("share", "Diagnostics reports you choose to send", f"""<p><em>Settings &rarr; Privacy and diagnostics &rarr; Diagnostics</em> shows a snapshot of what {NAME} knows on your device: app and operating system versions, which switches are on, counts of games and drills, and a short list of recent scrubbed events. It contains no games, positions, comments, titles, names, email address or file names. Nothing is sent unless you tap <em>Send diagnostics</em> and choose where to share it, for example by email to us.</p>"""),
        ("purchases", f"Purchases ({NAME} Plus)", f"""<p>When {NAME} Plus becomes available, the purchase is handled by Google Play. Google processes your payment and we do not receive your card or payment details. The app will receive confirmation of whether the purchase is active on your Google account so it can unlock the feature.</p>"""),
        ("use", "How we use data and why", """<ul>
<li><strong>To provide the app and the features you ask for</strong> (sign-in, cloud backup, restore). Basis: performing our agreement with you.</li>
<li><strong>To keep the app working and improve it</strong> (crash, performance and usage data). Basis: our legitimate interest in a reliable app, and your consent where the law requires it; you can withdraw it any time with the switches in Settings.</li>
<li><strong>To answer your messages and requests.</strong> Basis: legitimate interest and legal obligations.</li>
</ul>"""),
        ("sharing", "Who we share data with", """<p>We use Google LLC (Firebase and Google Play) as a service provider to run the features above. Google processes data on our behalf under its own terms and privacy policy. We do not sell personal data and we do not share it with advertisers or data brokers. We may disclose data if the law requires it.</p>
<p>Data processed by Google may be stored and processed in the United States and other countries where Google operates. Where required, transfers rely on the safeguards Google provides.</p>"""),
        ("retention", "How long we keep data", """<p>Data on your device stays until you delete it or uninstall the app. Cloud backups and your account are kept until you delete them. Crash, performance and analytics data are deleted automatically after the Firebase retention periods described above. Messages you send us are kept as long as needed to deal with your request.</p>"""),
        ("rights", "Your choices and rights", f"""<p>You can switch off crash reports, performance monitoring, usage analytics, announcements and reminders in Settings, sign out at any time, and delete your account and cloud backups from within the app.</p>
<p>Depending on where you live (for example under the EU and UK GDPR, the Kenya Data Protection Act, or California privacy law) you may have the right to access, correct, delete or export your personal data, to object to or restrict certain processing, to withdraw consent, and to complain to your data protection authority. To use these rights email <a href="mailto:{EMAIL}">{EMAIL}</a> from the address linked to your account. We may need to confirm it is you.</p>"""),
        ("children", "Children", f"""<p>{NAME} is not directed at children under 13 (or the higher age required where you live), and we do not knowingly collect their personal data. If you believe a child has signed in, contact us and we will delete the account.</p>"""),
        ("security", "Security", """<p>Data is encrypted in transit, cloud backups are protected by per-account security rules, and we keep access to Firebase limited. No system is completely secure, so we encourage you to keep your own exported backups.</p>"""),
        ("changes", "Changes to this policy", f"""<p>We may update this policy as the app changes. The effective date above shows the latest version, and we will tell you in the app about significant changes.</p>"""),
        ("contact", "Contact", f"""<p>{OPERATOR}<br><a href="mailto:{EMAIL}">{EMAIL}</a></p>"""),
    ],
    "privacy",
)

# ----------------------------------------------------------------------------
# Terms
# ----------------------------------------------------------------------------
TERMS = legal(
    "terms",
    "Terms of use",
    f"The terms for using the {NAME} app, cloud backup and {NAME} Plus.",
    f"These terms are the agreement between you and {OPERATOR} (&ldquo;we&rdquo;, &ldquo;us&rdquo;) about using {NAME}. Please read them. By installing or using the app you agree to them.",
    [
        ("app", "The app", f"""<p>{NAME} is a chess practice app for Android. We grant you a personal, non-exclusive, non-transferable right to install and use it on devices you own or control, for your own non-commercial use, subject to these terms and to the licenses of the open-source components described below.</p>"""),
        ("accounts", "Accounts", """<p>An account is optional and is only needed for cloud backup. You are responsible for your Google account and for activity under it. Provide accurate information and tell us if you suspect unauthorised use.</p>"""),
        ("backup", "Cloud backup", f"""<p>Cloud backup is provided on a best-effort basis to help you restore your games on a new device. It may be interrupted, limited or changed. It is <strong>not a guarantee</strong> that your data will always be available, so please also keep an exported backup file (<em>Settings &rarr; Export backup file</em>). We may remove accounts or backups that are abused, or that stay inactive for a long period after reasonable notice where we can reach you.</p>"""),
        ("plus", f"{NAME} Plus", f"""<p>{NAME} Plus is an optional one-time purchase made through Google Play that unlocks the features described in the app and on our website, currently automatic cloud backup and a longer backup history. Prices and availability are shown in the store before you buy. Payments, taxes, refunds and cancellations are handled by Google Play under its terms; we do not process your payment. The purchase is tied to your Google account and is not transferable. We may change what {NAME} Plus includes, but we will not remove features you have already paid for without a fair alternative or refund.</p>"""),
        ("use", "Acceptable use", """<p>Do not misuse the app or the services behind it. In particular do not attempt to break or overload our services or other users' access, reverse engineer the cloud features to bypass limits or security rules, use the app unlawfully, or upload content that is unlawful or infringes others' rights. Nothing here restricts the rights you have under the open-source licenses of the open-source components.</p>"""),
        ("content", "Your content", """<p>Your games, studies, comments and other content stay yours. We receive a backup of it only if you use cloud backup, and only use it to provide that backup and restore it to you. We do not review or use it for any other purpose.</p>"""),
        ("analysis", "Chess analysis", """<p>The engine, evaluations, move labels, opening names and puzzle solutions are tools to help you learn. Engine strength settings are not human ratings and are not an official rating. Analysis can be wrong or incomplete, and results depend on your device and the time given.</p>"""),
        ("open-source", "Open-source software and trademarks", f"""<p>{NAME} includes open-source software, including the Stockfish chess engine and the dartchess library (GPL-3.0), the Lichess puzzle and opening data (CC0), the Fraunces typeface (SIL Open Font License) and many other packages, each under its own license. The notices are in the app under <em>Settings &rarr; About &rarr; Open-source software</em>. These terms do not limit any rights you have under those licenses. Source code for the GPL-licensed components is available on request at <a href="mailto:{EMAIL}">{EMAIL}</a>.</p>
<p>The {NAME} name, logo and original artwork are our trademarks and property. The licenses above do not give you the right to use them, for example to name a modified version of the app.</p>"""),
        ("third", "Third-party services", """<p>The app relies on services from Google (Firebase, Google Play, Sign in with Google). Your use of them is also subject to their terms and privacy policies.</p>"""),
        ("warranty", "No warranty", f"""<p>The app and services are provided &ldquo;as is&rdquo; and &ldquo;as available&rdquo;. To the extent the law allows, we do not give any warranty that the app will be uninterrupted or error-free, or fit for a particular purpose. Nothing in these terms excludes warranties or rights you have under mandatory consumer law where you live.</p>"""),
        ("liability", "Limits on liability", """<p>To the extent the law allows, we are not liable for indirect or consequential losses, lost data or lost profits arising from your use of the app. Our total liability for any claim relating to the app is limited to the amount you paid us for it (if anything) in the twelve months before the claim. Nothing in these terms limits liability that cannot be limited by law, including liability for death or personal injury caused by negligence or for fraud.</p>"""),
        ("end", "Ending", """<p>You can stop using the app at any time by uninstalling it and, if you wish, deleting your account (see <a href="/delete-account">Delete your account</a>). We may suspend or end access to cloud features if you break these terms or to protect the service.</p>"""),
        ("changes", "Changes", """<p>We may update these terms. The effective date above shows the latest version, and we will tell you in the app about significant changes. If you keep using the app after a change takes effect, you accept the updated terms.</p>"""),
        ("law", "Law", """<p>These terms are interpreted according to the law that applies to them where you live, and they do not take away any mandatory consumer rights you have there. If part of the terms cannot be enforced, the rest still applies.</p>"""),
        ("contact", "Contact", f"""<p>{OPERATOR}<br><a href="mailto:{EMAIL}">{EMAIL}</a></p>"""),
    ],
    "terms",
)

# ----------------------------------------------------------------------------
# Delete account / data deletion (needed for the Play Console data safety form)
# ----------------------------------------------------------------------------
DELETE = page(
    "delete-account",
    f"Delete your account | {NAME}",
    f"How to delete your {NAME} account and the cloud data linked to it.",
    f"""<div class="wrap legal">
<p class="eyebrow">{NAME}</p>
<h1>Delete your account and data</h1>
<p class="lead">This page explains how to delete your {NAME} account and cloud backups. It applies to the app &ldquo;{NAME}&rdquo; by {OPERATOR}.</p>

<section id="in-app"><h2>Delete it in the app</h2>
<ol>
<li>Open {NAME} and go to <strong>Settings</strong> (the gear on the home screen).</li>
<li>Under <strong>Account</strong>, tap <strong>Delete account and cloud data</strong>.</li>
<li>Confirm. Your cloud backups and your sign-in account are deleted.</li>
</ol>
<p>If the app asks you to sign in again first, sign out, sign back in and repeat the steps. That is a security check.</p>
</section>

<section id="by-email"><h2>Or ask us to delete it</h2>
<p>If you can no longer open the app, email <a href="mailto:{EMAIL}?subject=Delete%20my%20{NAME}%20account">{EMAIL}</a> from the address used to sign in with the subject &ldquo;Delete my {NAME} account&rdquo;. We delete the account and its backups, normally within 30 days, and confirm by email.</p>
</section>

<section id="what"><h2>What is deleted</h2>
<ul>
<li><strong>Deleted:</strong> your sign-in account, its profile details (email, name, picture address), and every cloud backup stored for it.</li>
<li><strong>Stays on your device:</strong> your games and training data. Delete it by uninstalling the app or clearing the app's storage in Android settings. Export a backup file first if you want to keep it.</li>
<li><strong>Anonymous diagnostics</strong> (crash reports, performance timings and usage analytics) are not linked to your account and expire automatically under Firebase's retention periods. Switch them off any time in <em>Settings &rarr; Privacy and diagnostics</em>.</li>
</ul>
<p>More detail is in the <a href="/privacy">privacy policy</a>.</p>
</section>
</div>""",
)

NOT_FOUND = page(
    "404",
    f"Page not found | {NAME}",
    "The page you were looking for does not exist.",
    f"""<div class="wrap legal"><h1>Page not found</h1><p class="lead">That page does not exist. Try the <a href="/">home page</a> or the <a href="/privacy">privacy policy</a>.</p></div>""",
)

CSS = """
:root{
  --bg:#f6f1e7; --card:#fffbf3; --ink:#1c2a27; --muted:#56645f; --line:#d8cfbb;
  --pine:#0f4f49; --pine-ink:#f6f1e7; --teal:#0f6b63; --coral:#e98a70; --coral-ink:#2a0d04; --brass:#8a6416;
  --radius:18px; --font-body:system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",sans-serif;
}
@media (prefers-color-scheme: dark){
  :root{ --bg:#0f1a18; --card:#162321; --ink:#e8efea; --muted:#a9bbb5; --line:#2c423e; --pine:#14504a; --teal:#7fd1c4; --brass:#e3b85c; }
}
@font-face{font-family:Fraunces;src:url(/fonts/Fraunces.ttf) format("truetype");font-weight:100 900;font-display:swap}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
@media (prefers-reduced-motion: reduce){html{scroll-behavior:auto}}
body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.6 var(--font-body);-webkit-font-smoothing:antialiased}
img{max-width:100%;height:auto}
a{color:var(--teal);text-underline-offset:3px}
a:hover{text-decoration-thickness:2px}
:focus-visible{outline:3px solid var(--coral);outline-offset:3px;border-radius:6px}
.wrap{width:min(1100px,100% - 40px);margin-inline:auto}
.skip{position:absolute;left:-999px;top:8px;background:var(--ink);color:var(--bg);padding:10px 14px;border-radius:8px;z-index:10}
.skip:focus{left:8px}
h1,h2,h3{font-family:Fraunces,Georgia,serif;font-weight:600;line-height:1.12;letter-spacing:-.01em;margin:0 0 .4em}
h1{font-size:clamp(2.3rem,6vw,4rem)}
h2{font-size:clamp(1.7rem,3.6vw,2.4rem)}
h3{font-size:1.25rem}
.eyebrow,.label{font-size:.8rem;font-weight:700;letter-spacing:.12em;text-transform:uppercase;color:var(--brass);margin:0 0 .6rem}
.label{color:var(--muted)}
.lead{font-size:1.2rem;color:var(--muted)}
.muted{color:var(--muted)}
.narrow{max-width:62ch}
.fine{font-size:.88rem}

.top{position:sticky;top:0;z-index:5;background:color-mix(in srgb,var(--bg) 88%,transparent);backdrop-filter:blur(10px);border-bottom:1px solid var(--line)}
.bar{display:flex;align-items:center;justify-content:space-between;gap:16px;min-height:64px}
.brand{display:flex;align-items:center;gap:10px;font:600 1.4rem Fraunces,Georgia,serif;color:var(--ink);text-decoration:none}
.brand img{border-radius:9px}
.brand.small{font-size:1.15rem;margin:0 0 8px}
header nav{display:flex;flex-wrap:nowrap;white-space:nowrap}
header nav a{color:var(--ink);text-decoration:none;margin-left:18px;font-weight:600;font-size:.95rem}
header nav a:hover,header nav a[aria-current]{color:var(--teal);text-decoration:underline}
@media (max-width:640px){header nav a{margin-left:12px;font-size:.85rem}.brand{font-size:1.2rem}.brand img{width:30px;height:30px}}

.hero{background:var(--pine);color:var(--pine-ink);position:relative;overflow:hidden}
.hero .eyebrow{color:var(--coral)}
.hero .lead{color:color-mix(in srgb,var(--pine-ink) 82%,transparent)}
.hero a{color:var(--pine-ink)}
.hero-grid{display:grid;grid-template-columns:1.1fr .9fr;gap:40px;align-items:center;padding:64px 0 90px}
@media (max-width:820px){.hero-grid{grid-template-columns:1fr;padding:44px 0 70px}.hero-art{order:-1}.hero-art .phone{max-width:260px;margin-inline:auto}}
.cta{display:flex;flex-wrap:wrap;gap:12px;align-items:center;margin:26px 0 18px}
.pill{background:var(--coral);color:var(--coral-ink);font-weight:700;padding:13px 22px;border-radius:999px}
.btn{display:inline-block;padding:12px 20px;border-radius:999px;font-weight:700;text-decoration:none}
.btn.ghost{border:2px solid color-mix(in srgb,var(--pine-ink) 55%,transparent)}
.btn.ghost:hover{background:color-mix(in srgb,var(--pine-ink) 12%,transparent)}
.ticks{list-style:none;padding:0;margin:0;display:flex;flex-wrap:wrap;gap:8px 22px}
.ticks li::before{content:"\\2713";color:var(--coral);font-weight:900;margin-right:8px}
.battlements{position:absolute;left:0;right:0;bottom:0;height:26px;opacity:.16;background:
 linear-gradient(var(--pine-ink),var(--pine-ink)) bottom/100% 14px no-repeat,
 repeating-linear-gradient(90deg,var(--pine-ink) 0 36px,transparent 36px 72px) top/100% 12px no-repeat}

.phone{margin:0;border-radius:34px;border:6px solid #0b1412;background:#0b1412;box-shadow:0 24px 50px rgba(0,0,0,.35);overflow:hidden;max-width:300px}
.phone img{display:block;width:100%}
.section{padding:72px 0}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:18px;margin-top:28px}
.card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:24px}
.card p{margin:.2em 0 0;color:var(--muted)}
.shots{background:var(--card);border-block:1px solid var(--line);padding:72px 0}
.shot-row{display:flex;gap:28px;justify-content:center;flex-wrap:wrap;margin-top:34px}
.shot-row .phone{width:min(240px,70vw)}
.table-wrap{overflow-x:auto;margin-top:26px}
.plans{border-collapse:collapse;width:100%;min-width:480px;background:var(--card);border:1px solid var(--line);border-radius:var(--radius);overflow:hidden}
.plans th,.plans td{padding:14px 18px;text-align:left;border-bottom:1px solid var(--line)}
.plans thead th{background:var(--pine);color:var(--pine-ink);font-size:.85rem;letter-spacing:.06em;text-transform:uppercase}
.plans tbody th{font-weight:600}
.plans tr:last-child th,.plans tr:last-child td{border-bottom:0}
.oss{border-top:1px solid var(--line)}
.last{padding-bottom:96px}

.legal{padding:56px 0 90px;max-width:780px}
.legal h1{font-size:clamp(2rem,5vw,3rem)}
.legal section{margin-top:40px}
.legal h2{font-size:1.5rem}
.legal ul,.legal ol{padding-left:1.3em}
.legal li{margin:.4em 0}
.toc{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:18px 24px;margin:28px 0}
.toc ol{columns:2;margin:0;padding-left:1.2em}
@media (max-width:640px){.toc ol{columns:1}}
.legal section[id]{scroll-margin-top:84px}

.foot{border-top:1px solid var(--line);padding:44px 0 56px;background:var(--card)}
.foot-grid{display:grid;grid-template-columns:2fr 1fr 1fr;gap:28px}
@media (max-width:640px){.foot-grid{grid-template-columns:1fr}}
.foot p{margin:0 0 10px}
.foot .fine{margin-top:28px}
.linklike{background:none;border:0;padding:0;font:inherit;color:var(--teal);text-decoration:underline;text-underline-offset:3px;cursor:pointer}
.consent{position:fixed;z-index:20;left:16px;bottom:16px;width:min(440px,calc(100vw - 32px));max-height:calc(100vh - 32px);overflow:auto;background:var(--card);color:var(--ink);border:1px solid var(--line);border-radius:22px;padding:20px 22px 22px;box-shadow:0 22px 50px rgba(0,0,0,.30);animation:consent-in .22s ease-out both}
.consent:focus{outline:none}
@keyframes consent-in{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}
@media (prefers-reduced-motion: reduce){.consent{animation:none}}
.consent-head{display:flex;align-items:center;gap:12px;margin-bottom:8px}
.consent-icon{flex:none;color:var(--brass)}
.consent-title{font:600 1.25rem Fraunces,Georgia,serif;margin:0;flex:1}
.consent-x{flex:none;width:36px;height:36px;border-radius:50%;border:0;background:transparent;color:var(--muted);font-size:1.6rem;line-height:1;cursor:pointer}
.consent-x:hover{background:color-mix(in srgb,var(--ink) 9%,transparent);color:var(--ink)}
.consent-text{margin:0 0 10px;font-size:.96rem;line-height:1.5}
.consent-status{margin:0 0 10px;font-size:.88rem;color:var(--muted);font-weight:600}
.consent-more{margin:0 0 16px;font-size:.9rem}
.consent-more summary{cursor:pointer;color:var(--teal);font-weight:600;padding:4px 0}
.consent-more ul{margin:8px 0;padding-left:1.2em;color:var(--muted)}
.consent-more li{margin:.3em 0}
.consent-link{margin:6px 0 0}
.consent-actions{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.consent-btn{font:inherit;font-weight:700;padding:12px 18px;border-radius:999px;border:2px solid var(--teal);background:var(--teal);color:var(--bg);cursor:pointer;min-height:48px}
.consent-btn:hover{filter:brightness(1.1)}
@media (prefers-color-scheme: dark){.consent-btn{color:#00201c}}
@media (max-width:560px){.consent{left:0;right:0;bottom:0;width:auto;max-height:80vh;border-radius:22px 22px 0 0;padding-bottom:calc(22px + env(safe-area-inset-bottom))}}
"""

JS = """(function () {
  'use strict';
  var ID = '__GA_ID__';
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
""".replace('__GA_ID__', GA_ID)

ROBOTS = f"User-agent: *\nAllow: /\nSitemap: https://{DOMAIN}/sitemap.xml\n"
SITEMAP = (
    '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    + "".join(
        f"<url><loc>https://{DOMAIN}/{p}</loc></url>\n"
        for p in ["", "privacy", "terms", "delete-account"]
    )
    + "</urlset>\n"
)

if __name__ == "__main__":
    (ROOT / "css").mkdir(parents=True, exist_ok=True)
    (ROOT / "js").mkdir(parents=True, exist_ok=True)
    for name, content in {
        "index.html": INDEX,
        "privacy.html": PRIVACY,
        "terms.html": TERMS,
        "delete-account.html": DELETE,
        "404.html": NOT_FOUND,
        "css/site.css": CSS,
        "js/analytics.js": JS,
        "robots.txt": ROBOTS,
        "sitemap.xml": SITEMAP,
    }.items():
        (ROOT / name).write_text(content, encoding="utf-8")
    print("site built in", ROOT)
