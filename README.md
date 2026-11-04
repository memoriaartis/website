# Memoria Artis

French static website, built on Windows with PowerShell. No packages, remote fonts, trackers or server application are required. The checked-in HTML is a **review preview**, with search indexing disabled. No photograph, publisher identity or public contact address has been invented.

## Preview

From this folder in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/preview.ps1
```

Open `http://localhost:8080/fr/`. Stop the preview with Ctrl+C. Use a local server rather than opening HTML files directly. Generated links, assets and the entry redirect are relative, so the same pages work at a domain root and under a project path such as `https://memoriaartis.github.io/website/`. The execution policy flag applies only to the launched process. Preview serving exposes generated French pages and public assets, not configuration or source files.

## Change words

1. Open `content/home.fr.md`, `project.fr.md`, `approach.fr.md` or `contact.fr.md`.
2. Edit the French paragraphs or labels after `**H1:**`, `**H2:**` and the other markers. Keep the section separators (`### ...`) and their order. Section names are internal and never appear on the site. The home page contains an opening, the reason to act, three activities, an explanation, two stages and an invitation. Use `**Closing:**` for the paragraph following both stage columns. On the approach page, keep the five numbered method headings and use `- ` for knowledge-list entries.
3. Edit shared navigation, footer and form wording in `content/ui.fr.json`; page titles and descriptions in `content/metadata.fr.json`.
4. Run the build command above. It updates all six HTML pages together. Do not edit generated HTML directly.

`scripts/build.ps1` contains shared rendering. `assets/site.css` controls appearance; `assets/site.js` controls the menu, preview validation and subject preselection. Content remains readable and navigation remains available without JavaScript.

## Replace image areas

The stone-coloured areas are deliberate decorative spaces until approved photographs exist. They have no invented alt text or public placeholder captions.

1. Put an optimised photograph in `assets/`, using a simple filename (for example `atelier-bois.webp`).
2. In `content/images.json`, complete its `src` (`/assets/atelier-bois.webp`), original `source`, written `permission`, displayed `credit`, actual `width` and `height`, French `alt` after inspecting the image, and `focalPoint` such as `50% 40%`.
3. Keep permission/source records in this source file; only the image credit and alt text are rendered. Do not put personal information or private documents into `assets/`.
4. Rebuild and inspect the crop on mobile. The hero loads promptly; other images load lazily.

## Configure contact

There is currently no delivery service or confirmed recipient. The preview form cannot submit and cannot show delivery success. It provides labels, local subject preselection (`sujet=savoir-faire`, `partenariat`, `soutien`) and inline validation for review. Entering text sends nothing to any service.

For the simplest launch, put the **approved public email address** in `site.config.json` as `contactEmail`. Rebuilding replaces the entire form and its helper/privacy copy with a visible email link. No backend or credentials are needed for that email-only release. The address is public; never place secrets in configuration.

A future working form requires a separate secure endpoint with server-side validation, request size limits, rate limiting, a honeypot, verified sender, Reply-To sanitisation and server-only secrets. Replace the preview form only after implementing that endpoint. Preserve entered text on failure and announce success only when the delivery provider accepts the message. The UI strings for those states are already in `ui.fr.json`. A disabled preview is never a substitute for a working production contact method.

## Before a public release

Complete the checklist in `LAUNCH-CHECKLIST.md`. In `site.config.json`, supply the approved production origin, contact email, publisher name, public correspondence address and real hosting provider/contact. Complete `content/privacy.fr.md` for the actual email and hosting setup, then set `privacyApproved` to `true` after review. Do not add private addresses without explicit approval.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Production -OutputDirectory dist
```

The public build stops when required details are missing. It emits canonical URLs, a sitemap with configured routes and indexable robots rules. Preview builds emit `noindex` and `Disallow: /`. The origin must be an HTTPS origin such as the actual production domain, with no path. No alternate-language metadata is emitted for nonexistent translations.

Deploy **only the contents of `dist/`** to the confirmed static host, configured to serve directory `index.html` files and preserve `/fr/` paths. Do not upload this entire repository: it includes internal source/configuration and launch notes. `/` redirects consistently to `/fr/` using an HTML redirect and fallback link; configure an equivalent HTTP 302/301 redirect on the chosen host when available. No deployment or remote push is performed by these scripts.

## Add a language later

Add a route map under a real locale key in `content/routes.json`, using translated slugs. Create matching `ui.LOCALE.json`, `metadata.LOCALE.json` and the six `PAGE.LOCALE.md` files. Keep the structural markers in English; translate all rendered labels and paragraphs. Use the same templates with `-Locale LOCALE -OutputDirectory dist` after building French. Add the locale to the preview server allowlist, and add a switcher between equivalent stable page IDs plus language-alternate metadata only after all translations exist. French remains the default `/` destination. The shared rendering does not need to be duplicated. Each locale should use reviewed image alt text if imagery is added.

## Verification limits

`scripts/check.ps1` checks generated French preview pages, internal links/assets at both the domain root and `/website/`, entry redirects, skip anchors, one H1 per page, exact editorial text, three activities, two stages, five method steps, the illustrative example, contact labels and disabled submission. It is for the unconfigured preview and intentionally fails after enabling email-only mode. Browser checks at 360, 390, 768 and 1440 pixels, keyboard/focus checks and real contact delivery should be completed before launch. No browser automation or JavaScript runtime is installed in the supplied environment.
