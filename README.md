# Memoria Artis

French static website built with [Eleventy](https://www.11ty.dev/) and [pnpm](https://pnpm.io/). No remote fonts, trackers or server application are required. Local and GitHub Pages preview builds keep search indexing disabled. No photograph, publisher identity or public contact address has been invented.

## Setup

```bash
pnpm install
```

## Preview

```bash
pnpm dev
```

Open `http://localhost:8080/fr/` on this machine, or `http://<your-lan-ip>:8080/fr/` from a phone on the same network (the dev server listens on `0.0.0.0`). Stop with Ctrl+C. Generated links and assets are relative so the same build also works under a project Pages mount such as `/website/`.

```bash
pnpm build
pnpm check
```

`pnpm build` writes the site to `_site/`. `pnpm check` verifies the generated French pages, internal links/assets at both the domain root and `/website/`, redirects, skip anchors, one H1 per page, editorial copy, three activities, two stages, five method steps, diagram content, photo slots and contact labels. It currently expects the unconfigured contact preview.

## Change words

1. Edit the Markdown pages in `src/fr/` (`index.md`, `le-projet.md`, `notre-demarche.md`, `contact.md`, …).
2. Page copy uses standard Markdown and YAML front matter. Keep the existing front-matter keys (`heading`, `intro`, `activities`, CTAs, image slot ids, …) so the layouts keep working.
3. Shared navigation, footer and form wording live in `src/_data/ui.json`. The illustrative diagram is in `src/_data/example.json`.
4. Run `pnpm build` (or keep `pnpm dev` running). Do not edit generated HTML in `_site/` directly.

Layouts live in `src/_includes/layouts/`. `src/assets/site.css` controls appearance; `src/assets/site.js` controls the menu, preview validation and subject preselection. Content remains readable and navigation remains available without JavaScript.

## Replace image areas

The seven photo slots have a defined editorial role and proportions. In a working preview, they show a short brief on a stone surface. In a production build, missing images disappear and the layout becomes a clean text composition, with no empty frames or provisional captions. The planning descriptions never become alt text or captions. See `PHOTOGRAPHIES.md` for the complete list.

1. Put an optimised photograph in `src/assets/`, using a simple filename (for example `atelier-bois.webp`).
2. In `src/_data/images.json`, complete its `src` (`/assets/atelier-bois.webp`), original `source`, written `permission`, displayed `credit`, actual `width` and `height`, French `alt` after inspecting the image, and optional factual `caption`. Adjust `focalPoint` and `focalPointMobile`, such as `50% 40%`, independently. `ratio` and `ratioMobile` define the frame proportions, such as `4 / 5`.
3. Keep permission/source records and the internal `brief` in this source file; only the approved caption, image credit and alt text are rendered with a real photograph. Do not put personal information or private documents into `src/assets/`.
4. Rebuild and inspect the crop on mobile. The hero loads promptly; other images load lazily.

To inspect the final typography when images are missing, without supplying fake publisher/contact details:

```bash
pnpm build:layout-preview
```

This remains a non-indexable preview with the current contact/legal notices. It is not a production build. The real production build also omits missing images, and still requires the verified launch information below.

## Configure contact

There is currently no delivery service or confirmed recipient. The preview form cannot submit and cannot show delivery success. It provides labels, local subject preselection (`sujet=savoir-faire`, `partenariat`, `soutien`) and inline validation for review. Entering text sends nothing to any service.

For the simplest launch, put the **approved public email address** in `site.config.json` as `contactEmail`. Rebuilding replaces the entire form and its helper/privacy copy with a visible email link. No backend or credentials are needed for that email-only release. The address is public; never place secrets in configuration.

A future working form requires a separate secure endpoint with server-side validation, request size limits, rate limiting, a honeypot, verified sender, Reply-To sanitisation and server-only secrets. Replace the preview form only after implementing that endpoint. Preserve entered text on failure and announce success only when the delivery provider accepts the message. The UI strings for those states are already in `ui.json`. A disabled preview is never a substitute for a working production contact method.

## Before a public release

Complete the checklist in `LAUNCH-CHECKLIST.md`. In `site.config.json`, supply the approved production origin, contact email, publisher name, public correspondence address and real hosting provider/contact. Complete `src/fr/confidentialite.md` for the actual email and hosting setup, then set `privacyApproved` to `true` after review. Do not add private addresses without explicit approval.

```bash
pnpm build:production
```

The public build stops when required details are missing. It emits canonical URLs, a sitemap with configured routes and indexable robots rules. Preview builds emit `noindex` and `Disallow: /`. The origin must be an HTTPS origin such as the actual production domain, with no path. No alternate-language metadata is emitted for nonexistent translations.

Deploy **only the contents of `_site/`**. Do not upload this entire repository: it includes internal source/configuration and launch notes. `/` redirects consistently to `/fr/` using an HTML redirect and fallback link; configure an equivalent HTTP 302/301 redirect on the chosen host when available.

## GitHub Pages

Pushing to `main` runs `.github/workflows/pages.yml`: install with pnpm, build the preview site, run checks, then publish `_site/` with GitHub Actions. In the repository settings, set Pages to **GitHub Actions**. Until launch details are confirmed, the workflow publishes the non-indexable preview build (`pnpm build`). Switch the workflow to `pnpm build:production` only after `site.config.json` and the privacy notice are approved.

## Add a language later

Duplicate the `src/fr/` pages under another locale folder with translated slugs and front matter. Add matching UI/image/example data files, then link equivalent pages with a language switcher and language-alternate metadata only after all translations exist. French remains the default `/` destination.

## Repository layout

```text
src/fr/                  Page content (Markdown + YAML front matter)
src/_includes/layouts/   Page layouts
src/_data/               UI strings, routes, images, example diagram
src/assets/              CSS, JS and future photographs
scripts/check.mjs        Post-build verification
site.config.json         Launch configuration (email, origin, publisher)
_site/                   Generated output (not committed)
```
