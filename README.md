# Memoria Artis

French static website, built on Windows with PowerShell. No packages, remote fonts, trackers or server application are required. The checked-in HTML is a **review preview**, with search indexing disabled. No photograph, publisher identity or public contact address has been invented.

## Preview

From this folder in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/preview.ps1
```

Open `http://localhost:8080/website/fr/` to review the GitHub Pages mount, or `http://localhost:8080/fr/` for the domain-root layout. Both entry URLs (`/` and `/website/`) redirect to the corresponding French home page. Stop the preview with Ctrl+C. Use a local server rather than opening HTML files directly. Generated links, assets and the entry redirect are relative. The execution policy flag applies only to the launched process. Preview serving exposes generated French pages and public assets, not configuration or source files. This editorial/visual revision is local only; pushing to `main` would update the public GitHub Pages site and requires the owner's instruction.

## Change words

1. Open `content/home.fr.md`, `project.fr.md`, `approach.fr.md` or `contact.fr.md`.
2. Edit the French paragraphs or labels after `**H1:**`, `**H2:**` and the other markers. Keep the section separators (`### ...`) and their order. Section names are internal and never appear on the site. The home page has six sections: opening, encounter, three activities, explanation, two stages and invitation. The association page has six: opening, reason to act, beneficiaries, contribution, origin and invitation. The approach page has five: opening, five method steps, illustrative example, sources/access and future uses. Keep the five numbered method headings. Edit the diagram labels and text in `content/example.fr.json`.
3. Edit shared navigation, footer and form wording in `content/ui.fr.json`; page titles and descriptions in `content/metadata.fr.json`.
4. Run the build command above. It updates all six HTML pages together. Do not edit generated HTML directly.

`scripts/build.ps1` contains shared rendering. `assets/site.css` controls appearance; `assets/site.js` controls the menu, preview validation and subject preselection. Content remains readable and navigation remains available without JavaScript.

## Replace image areas

The seven photo slots have a defined editorial role and proportions. In a working preview, they show a short brief on a stone surface. In a production build, missing images disappear and the layout becomes a clean text composition, with no empty frames or provisional captions. The planning descriptions never become alt text or captions. See `PHOTOGRAPHIES.md` for the complete list.

1. Put an optimised photograph in `assets/`, using a simple filename (for example `atelier-bois.webp`).
2. In `content/images.fr.json`, complete its `src` (`/assets/atelier-bois.webp`), original `source`, written `permission`, displayed `credit`, actual `width` and `height`, French `alt` after inspecting the image, and optional factual `caption`. Adjust `focalPoint` and `focalPointMobile`, such as `50% 40%`, independently. `ratio` and `ratioMobile` define the frame proportions, such as `4 / 5`.
3. Keep permission/source records and the internal `brief` in this source file; only the approved caption, image credit and alt text are rendered with a real photograph. Do not put personal information or private documents into `assets/`.
4. Rebuild and inspect the crop on mobile. The hero loads promptly; other images load lazily.

To inspect the final typography when images are missing, without supplying fake publisher/contact details:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -OmitMissingImages -OutputDirectory .preview/final-layout
```

This remains a non-indexable preview with the current contact/legal notices. It is not a production build. The real `-Production` build also omits missing images, and still requires the verified launch information below.

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

Add a route map under a real locale key in `content/routes.json`, using translated slugs. Create matching `ui.LOCALE.json`, `metadata.LOCALE.json`, `images.LOCALE.json`, `example.LOCALE.json` and the six `PAGE.LOCALE.md` files. Keep structural markers in English; translate all rendered labels, paragraphs, photo briefs, captions and alt text. Use the same templates with `-Locale LOCALE -OutputDirectory dist` after building French. Add the locale to the preview server allowlist, and add a switcher between equivalent stable page IDs plus language-alternate metadata only after all translations exist. French remains the default `/` destination. The shared rendering does not need to be duplicated.

## Verification

`scripts/check.ps1` checks the generated French preview pages, internal links/assets at both the domain root and `/website/`, redirects, skip anchors, one H1 per page, editorial copy, three activities, two stages, five method steps, diagram content, photo slots and contact labels. It currently expects the unconfigured contact preview.

With the preview server running and Microsoft Edge installed, the optional native browser checks need no Node or third-party packages:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/browser-check.ps1
```

This launches a separate invisible Edge profile, then closes it. It checks all six pages at 360, 390, 768 and 1440 px; horizontal overflow; missing images; keyboard focus and Menu Enter/Tab/Escape; contact subject preselection and inline errors; retained form content; no-JavaScript navigation; the mounted entry redirect; and relevant console errors. Screenshots are saved in `.preview/screens/`. These checks passed for the current revision; desktop/mobile screenshots were also visually inspected. Real contact delivery is unavailable until configured. Approved photographs and their actual crops still need review when supplied.
