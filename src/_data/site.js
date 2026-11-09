import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const production = process.env.SITE_PRODUCTION === "1";

function loadConfig() {
  const config = JSON.parse(fs.readFileSync(path.join(rootDir, "site.config.json"), "utf8"));
  if (
    config.contactEmail &&
    (!/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(config.contactEmail) ||
      /[\r\n]/.test(config.contactEmail))
  ) {
    throw new Error("Contact email is invalid.");
  }

  const origin = (config.origin || "").replace(/\/$/, "");
  if (origin && !/^https:\/\/[^/\s?#]+$/.test(origin)) {
    throw new Error("Origin must be an HTTPS origin without a path.");
  }

  if (production) {
    for (const key of [
      "origin",
      "contactEmail",
      "publisherName",
      "publisherAddress",
      "hostingName",
      "hostingContact",
    ]) {
      if (!config[key]) {
        throw new Error(`Public build blocked: configure ${key} in site.config.json.`);
      }
    }
    if (!config.privacyApproved) {
      throw new Error(
        "Public build blocked: complete the privacy notice and approve privacyApproved.",
      );
    }
  }

  return { ...config, origin };
}

export default {
  production,
  omitMissingImages: process.env.OMIT_MISSING_IMAGES === "1" || production,
  config: loadConfig(),
  year: new Date().getFullYear(),
  rootDir,
};
