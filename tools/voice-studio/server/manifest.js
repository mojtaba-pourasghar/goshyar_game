// Reading res/raw/audio_manifest.txt — the one source of what گوش‌یار says.
//
// Every line is «key | the words on screen | the words as they are said». The third column is
// what gets recorded: every word given its vowels, so the service reads it the way a Persian
// speaker would.

import fs from "node:fs";
import path from "node:path";

// The groups follow گوش‌یار's key convention, which is written out at the top of the manifest:
//     ui_   صفحه‌ها        cat_  دسته‌بندی‌ها     snd_  نام صداها
//     fs    پیدا کردن منبع صدا    wm   این صدا مال کیه؟
//     sq    ترتیب صداها           am   مأموریت شنیداری
//     fb_   بازخورد عمومی        bdg_  مدال‌ها
const GROUPS = [
  { id: "ui",       test: (k) => k.startsWith("ui_"),  label: "صفحه‌ها" },
  { id: "cats",     test: (k) => k.startsWith("cat_"), label: "دسته‌بندی‌ها" },
  { id: "sounds",   test: (k) => k.startsWith("snd_"), label: "نام صداها" },
  { id: "find",     test: (k) => /^fs\d/.test(k),      label: "بازی ۱ — پیدا کردن منبع صدا" },
  { id: "who",      test: (k) => /^wm\d/.test(k),      label: "بازی ۲ — این صدا مال کیه؟" },
  { id: "sequence", test: (k) => /^sq\d/.test(k),      label: "بازی ۳ — ترتیب صداها" },
  { id: "mission",  test: (k) => /^am\d/.test(k),      label: "بازی ۴ — مأموریت شنیداری" },
  { id: "feedback", test: (k) => k.startsWith("fb_"),  label: "بازخوردهای عمومی" },
  { id: "badges",   test: (k) => k.startsWith("bdg_"), label: "مدال‌ها" },
];

function groupOf(key) {
  return (GROUPS.find((g) => g.test(key)) || { id: "other" }).id;
}

/**
 * The «فصل» filter of the maths studio became the مرحله filter here: the four games are
 * numbered, so a key like fs07_x belongs to level 7. Everything that is not a game line
 * (screens, categories, sound names, feedback, badges) has no level and returns null.
 */
function levelOf(key) {
  const m = key.match(/^(?:fs|wm|sq|am)(\d{2})/);
  return m ? Number(m[1]) : null;
}

export function readManifest(manifestPath) {
  const text = fs.readFileSync(manifestPath, "utf8");
  const lines = [];
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#") || !line.includes("|")) continue;
    const cols = line.split("|").map((c) => c.trim());
    const [key, written] = cols;
    const spoken = cols[2] && cols[2].length ? cols[2] : written;
    if (!key || !written) continue;
    lines.push({ key, written, spoken, group: groupOf(key), chapter: levelOf(key) });
  }
  return lines;
}

/** Which keys already have a file in the output directory, whatever the extension. */
export function existingKeys(outDir) {
  const done = new Map();
  if (!outDir || !fs.existsSync(outDir)) return done;
  for (const name of fs.readdirSync(outDir)) {
    const ext = path.extname(name).toLowerCase();
    if (![".ogg", ".mp3", ".wav"].includes(ext)) continue;
    const full = path.join(outDir, name);
    let size = 0;
    try {
      size = fs.statSync(full).size;
    } catch {
      continue;
    }
    // a near-empty file is the wreck of a failed attempt, not a recording
    if (size < 512) continue;
    done.set(path.basename(name, ext), { name, size });
  }
  return done;
}

export const GROUP_LABELS = Object.fromEntries(GROUPS.map((g) => [g.id, g.label]));
