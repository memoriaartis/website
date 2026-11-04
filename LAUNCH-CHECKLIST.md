# Private launch handover — do not deploy this file

- [ ] Confirm a working public email address; put it in `site.config.json` to enable the email-only release.
- [ ] Confirm the publisher identity and legal status; use only verified claims.
- [ ] Supply a correspondence address explicitly approved for publication.
- [ ] Confirm the production domain and hosting provider, including hosting contact details.
- [ ] Complete the privacy notice: responsible publisher, email and hosting processors, logs, processing locations, retention and data request process. Review before enabling `privacyApproved`.
- [ ] Supply approved photographs of a precise craft gesture, an inhabited workshop and a tool/material detail. Record source, permission, credit, dimensions, reviewed alt text and focal point in `content/images.json`. Typography-led layout can remain if approved photographs are unavailable.
- [ ] Review 360, 390, 768 and 1440 pixel layouts in a browser; inspect overflow, image crops, heading wraps and console errors.
- [ ] Check keyboard navigation, visible focus, Escape/menu behaviour, all three subject query values and an unknown value, inline validation, and no-JavaScript readability.
- [ ] Test email-only contact on the target device, or fully implement/test a separate secure form endpoint before enabling submissions.
- [ ] Build with `-Production -OutputDirectory dist`; check canonical origin, sitemap and robots rules.
- [ ] Deploy only after the owner gives deployment instructions. Upload only `dist/` contents; keep source and this checklist private.
