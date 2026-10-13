// Writing the two index files the app reads from the host.
//
// The clips and the worksheet PDFs are uploaded by hand to
//   the folder the app is told to fetch clips from, when they are hosted
// and in each folder sits an index.json saying what is there. The app fetches that file first
// and then knows what it may download. Nothing here uploads anything — it only prepares the
// folders so the whole thing can be dragged across in one go.

import fs from "node:fs";
import path from "node:path";

export const AUDIO_BASE = "";   // گوش‌یار bundles its clips; set this only if they are hosted

const AUDIO_EXT = [".ogg", ".mp3", ".wav"];

/**
 * index.json for the narration: every clip in the output folder, keyed the way the app asks
 * for it. Written into the folder itself, so uploading the folder uploads the index with it.
 */
export function writeAudioIndex({ outDir, baseUrl = AUDIO_BASE, speaker = "", appAssets = null }) {
  if (!fs.existsSync(outDir)) throw new Error(`پوشه‌ی خروجی نیست: ${outDir}`);

  const files = {};
  let bytes = 0;
  for (const name of fs.readdirSync(outDir).sort()) {
    const ext = path.extname(name).toLowerCase();
    if (!AUDIO_EXT.includes(ext)) continue;
    // _test-…, _diag-…, _sample-… : the studio's own listening clips, never lesson narration.
    // No lesson key starts with an underscore, so one rule covers all of them — and keeps a
    // voice sample from being treated as though گوش‌یار said it in the game.
    if (name.startsWith("_")) continue;
    const size = fs.statSync(path.join(outDir, name)).size;
    if (size < 512) continue;
    files[path.basename(name, ext)] = name;
    bytes += size;
  }

  const index = {
    baseUrl: baseUrl.endsWith("/") ? baseUrl : baseUrl + "/",
    generatedAt: new Date().toISOString(),
    voice: speaker,
    count: Object.keys(files).length,
    bytes,
    files,
  };
  const json = JSON.stringify(index, null, 2);
  fs.writeFileSync(path.join(outDir, "index.json"), json, "utf8");

  // the app carries a copy so the first launch, before any network, knows the shape of things
  if (appAssets && fs.existsSync(path.dirname(appAssets))) {
    fs.writeFileSync(appAssets, json, "utf8");
  }
  return index;
}

/**
 * A folder name for a worksheet. It becomes part of a URL the app opens, so it stays ASCII:
 * a Persian title has no safe spelling in a path, and a half-encoded one is worse than a plain
 * «karbarg-<n>». The real title lives in info.json and in the index, which is what the app shows.
 */
