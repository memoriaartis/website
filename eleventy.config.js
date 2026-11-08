import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import markdownIt from "markdown-it";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)));
const md = markdownIt({ html: false, breaks: false, linkify: false });
const escape = md.utils.escapeHtml;

function relativizeUrls(content, pageUrl) {
  if (!pageUrl || typeof content !== "string") return content;
  const depth = pageUrl.split("/").filter(Boolean).length;
  const prefix = "../".repeat(depth);
  return content.replace(
    /\b(href|src)=(['"])\/(?!\/)([^'"]*)\2/g,
    (_match, attribute, quote, target) => `${attribute}=${quote}${prefix}${target}${quote}`,
  );
}

function photoVisible(id, images, { production, omitMissingImages }) {
  const record = images[id];
  if (!record) throw new Error(`Unknown image slot: ${id}`);
  if (record.src) return true;
  return !(production || omitMissingImages);
}

function renderPhoto(id, images, ui, { production, omitMissingImages }) {
  const record = images[id];
  if (!record) throw new Error(`Unknown image slot: ${id}`);
  for (const key of ["ratio", "ratioMobile"]) {
    if (!/^\d+ \/ \d+$/.test(record[key])) throw new Error(`Invalid ratio for ${id}`);
  }

  const ratioStyle = `--photo-ratio:${record.ratio};--photo-ratio-mobile:${record.ratioMobile}`;
  if (!record.src) {
    if (production || omitMissingImages) return "";
    return `<figure class='photo photo-planning' style='${ratioStyle}' data-preview-image='${id}'><div class='photo-plan'><span>${escape(ui.photoPreview)}</span><p>${escape(record.brief)}</p></div></figure>`;
  }

  for (const field of ["source", "permission", "credit", "width", "height"]) {
    if (!record[field]) throw new Error(`Image ${id} requires ${field}.`);
  }
  if (record.alt == null) {
    throw new Error(`Image ${id} requires reviewed alt text (empty for decorative imagery).`);
  }
  if (!/^\/assets\/[a-zA-Z0-9/_.-]+$/.test(record.src) || record.src.includes("..")) {
    throw new Error("Images must be local assets.");
  }
  if (!fs.existsSync(path.join(rootDir, "src", record.src.replace(/^\//, "")))) {
    throw new Error(`Missing image: ${record.src}`);
  }
  if (!/^\d{1,3}% \d{1,3}%$/.test(record.focalPoint)) {
    throw new Error("Image focalPoint must contain two percentages.");
  }
  if (!/^\d{1,3}% \d{1,3}%$/.test(record.focalPointMobile)) {
    throw new Error("Image focalPointMobile must contain two percentages.");
  }
  if (Number(record.width) <= 0 || Number(record.height) <= 0) {
    throw new Error("Image dimensions must be positive.");
  }

  const loading = id === "hero" ? "fetchpriority='high'" : "loading='lazy'";
  const caption = record.caption ? `<span>${escape(record.caption)}</span>` : "";
  return `<figure class='photo' style='${ratioStyle};--photo-focus:${record.focalPoint};--photo-focus-mobile:${record.focalPointMobile}'><div class='photo-frame'><img src='${escape(record.src)}' alt='${escape(record.alt)}' width='${record.width}' height='${record.height}' ${loading}></div><figcaption>${caption}<span class='image-credit'>${escape(record.credit)}</span></figcaption></figure>`;
}

/** @param {import("@11ty/eleventy").UserConfig} eleventyConfig */
export default function (eleventyConfig) {
  eleventyConfig.setLibrary("md", md);
  eleventyConfig.setServerOptions({ host: "0.0.0.0" });
  eleventyConfig.addPassthroughCopy({ "src/assets": "assets" });
  eleventyConfig.addWatchTarget("site.config.json");

  eleventyConfig.addFilter("md", (value) => (value ? md.render(String(value)) : ""));

  eleventyConfig.addFilter("hasPhoto", function (id) {
    return photoVisible(id, this.ctx.images, this.ctx.site);
  });

  eleventyConfig.addFilter("photo", function (id) {
    return renderPhoto(id, this.ctx.images, this.ctx.ui, this.ctx.site);
  });

  eleventyConfig.addTransform("relativize-urls", function (content, outputPath) {
    if (!outputPath || !outputPath.endsWith(".html")) return content;
    return relativizeUrls(content, this.page?.url);
  });

  return {
    dir: {
      input: "src",
      includes: "_includes",
      data: "_data",
      output: "_site",
    },
    htmlTemplateEngine: "njk",
    markdownTemplateEngine: "njk",
    templateFormats: ["njk", "md", "html"],
  };
}
