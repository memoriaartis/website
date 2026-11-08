import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const siteDir = process.env.SITE_DIR
  ? path.resolve(process.env.SITE_DIR)
  : path.join(rootDir, "_site");

const routes = JSON.parse(fs.readFileSync(path.join(rootDir, "src/_data/routes.json"), "utf8"));
const images = JSON.parse(fs.readFileSync(path.join(rootDir, "src/_data/images.json"), "utf8"));
const example = JSON.parse(fs.readFileSync(path.join(rootDir, "src/_data/example.json"), "utf8"));

const expectedCopy = {
  home: [
    "Préserver les savoir-faire. Rendre leur transmission possible.",
    "Tout commence par une rencontre",
    "Faire découvrir",
    "Documenter en profondeur",
    "Relier et préserver",
    "Documenter pour que quelqu’un puisse comprendre",
    "01 — Constituer la base de connaissances",
    "02 — Développer la plateforme de transmission",
    "Parlons-en",
  ],
  project: [
    "Une expérience à partager, une mémoire à faire vivre",
    "Aux artisans",
    "Aux personnes qui apprennent",
    "Aux acteurs de la transmission",
    "À l’origine de Memoria Artis",
    "Contacter l’association",
  ],
  approach: [
    "Du geste observé à l’explication que l’on retrouve",
    "Préparer avec l’artisan",
    "Recueillir les gestes et les explications",
    "Structurer et vérifier",
    "Archiver avec les sources",
    "Préparer la restitution",
    "Proposer un savoir-faire à documenter",
  ],
  contact: [
    "Partons de votre proposition",
    "Artisans et ateliers",
    "Écoles, institutions et partenaires",
    "Soutenir l’association",
  ],
};

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function decodeEntities(text) {
  return text
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&mdash;/g, "—")
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)));
}

function stripTags(html) {
  return decodeEntities(html.replace(/<[^>]+>/g, " ")).replace(/\s+/g, " ");
}

function resolveLocal(fromPermalink, url, mount = "") {
  const pageUrl = new URL(`https://preview.invalid${mount}${fromPermalink}`);
  const resolved = new URL(url, pageUrl);
  assert(
    resolved.pathname.startsWith(`${mount}/`) || resolved.pathname === mount,
    `Link escapes hosting mount: ${url} from ${pageUrl}`,
  );
  let localPath = resolved.pathname.slice(mount.length);
  if (localPath.endsWith("/")) localPath += "index.html";
  return path.join(siteDir, localPath.replace(/^\//, ""));
}

let count = 0;
for (const [id, permalink] of Object.entries(routes)) {
  const file = path.join(siteDir, permalink.replace(/^\//, ""), "index.html");
  const html = fs.readFileSync(file, "utf8");

  assert((html.match(/<h1[ >]/g) || []).length === 1, `One H1 required: ${file}`);
  assert(html.includes("lang='fr'"), `French language missing: ${file}`);
  assert(html.includes("content='noindex, nofollow'"), `Preview indexing protection missing: ${file}`);
  assert(!html.includes("Implementation note"), `Internal notes exposed: ${file}`);
  assert(!html.includes("Consigne de r"), `Internal update instructions exposed: ${file}`);
  assert(!html.includes("Hello Gr"), `Old content remains: ${file}`);

  for (const match of html.matchAll(/(?:href|src)='([^']+)'/g)) {
    const url = decodeEntities(match[1]);
    if (url.startsWith("#")) {
      assert(html.includes(`id='${url.slice(1)}'`), `Missing anchor: ${url}`);
      continue;
    }
    if (/^[a-z]+:/i.test(url) || url.startsWith("//")) continue;
    for (const mount of ["", "/website"]) {
      assert(
        fs.existsSync(resolveLocal(permalink, url, mount)),
        `Broken local URL: ${url} from ${permalink} (mount ${mount || "/"})`,
      );
    }
  }

  if (expectedCopy[id]) {
    const rendered = stripTags(html);
    for (const text of expectedCopy[id]) {
      assert(rendered.includes(text), `Editorial copy missing on ${id}: ${text}`);
    }
  }

  count += 1;
}

const homeHtml = fs.readFileSync(path.join(siteDir, "fr/index.html"), "utf8");
assert((homeHtml.match(/<article>/g) || []).length === 5, "Home must have three activities and two stages.");

const approach = fs.readFileSync(path.join(siteDir, "fr/notre-demarche/index.html"), "utf8");
const method = approach.match(/<ol class='steps'>([\s\S]*?)<\/ol>/)?.[1] || "";
assert((method.match(/<li>/g) || []).length === 5, "Approach must have five method steps.");
assert(approach.includes("class='knowledge-example'"), "Illustrative explanation must have a linked information diagram.");
assert(approach.includes(example.label), "Example must be clearly labelled as illustrative.");
for (const node of example.nodes) {
  assert(approach.includes(node.text), "Example source/relationship missing.");
}

let planned = 0;
for (const [name, slot] of Object.entries(images)) {
  assert(slot.brief, `Missing photo direction: ${name}`);
  if (!slot.src) planned += 1;
}
const allPages = Object.values(routes)
  .map((permalink) =>
    fs.readFileSync(path.join(siteDir, permalink.replace(/^\//, ""), "index.html"), "utf8"),
  )
  .join("");
assert(
  (allPages.match(/data-preview-image=/g) || []).length === planned,
  "Photo slots must all appear in the review preview.",
);

const contact = fs.readFileSync(path.join(siteDir, "fr/contact/index.html"), "utf8");
assert(contact.includes("type='submit' disabled"), "Unconfigured contact must not accept submission.");
for (const subject of ["savoir-faire", "partenariat", "soutien", "autre"]) {
  assert(contact.includes(`value='${subject}'`), `Missing subject: ${subject}`);
}
for (const field of ["name", "email", "organisation", "subject", "message"]) {
  assert(contact.includes(`for='${field}'`), `Missing label: ${field}`);
}

const entry = fs.readFileSync(path.join(siteDir, "index.html"), "utf8");
const redirect = entry.match(/url=([^'"]+)/)?.[1];
for (const mount of ["", "/website"]) {
  const resolved = new URL(redirect, `https://preview.invalid${mount}/`);
  assert(resolved.pathname === `${mount}/fr/`, `Entry redirect escapes hosting mount: ${resolved}`);
}

console.log(
  `Passed: ${count} pages, links/assets at root and /website/, entry redirects, anchors, exact editorial copy, headings, contact labels and preview safety.`,
);
