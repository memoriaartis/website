# Private launch handover — do not deploy this file

- [ ] Confirm a working public email address; put it in `site.config.json` to enable the email-only release.
- [ ] Confirm the publisher identity and legal status; use only verified claims.
- [ ] Supply a correspondence address explicitly approved for publication.
- [ ] Confirm the production domain and hosting provider, including hosting contact details.
- [ ] Complete the privacy notice: responsible publisher, email and hosting processors, logs, processing locations, retention and data request process. Review before enabling `privacyApproved`.
- [ ] Supply approved photographs following `PHOTOGRAPHIES.md`. Record source, permission, credit, optional caption, dimensions, reviewed alt text and desktop/mobile focal points in `src/_data/images.json`. Missing photographs are omitted in production; a clean typography-led layout can remain.
- [x] Review the current preview at 360, 390, 768 and 1440 pixels in Edge: no horizontal overflow, broken images or relevant console errors. Review actual photographic crops after assets are supplied.
- [x] Check keyboard navigation, visible focus, Enter/Tab/Escape menu behaviour, all three subject query values and an unknown value, inline validation, retained text, and no-JavaScript readability.
- [ ] Test email-only contact on the target device, or fully implement/test a separate secure form endpoint before enabling submissions.
- [ ] Build with `pnpm build:production`; check canonical origin, sitemap and robots rules.
- [ ] Deploy only after the owner gives deployment instructions. Publish only `_site/` contents (GitHub Actions does this from `main`); keep source and this checklist private.
