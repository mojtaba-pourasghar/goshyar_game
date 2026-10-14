// صدای حیوان‌ها و وسایل — the effects the game asks «whose sound is this?» about.
//
// The list comes from assets/content/levels.json («sounds»: id, title, category, audio), so a
// sound added there shows up here with no other step. A replaced file is written over
// assets/audio/sfx/<name>.mp3, the path the app already plays, and goes into the APK with the
// next build.
//
// docs/audio/sfx_sources.json (in git) records, for every file that was replaced here, where
// the recording came from and under what licence. A sound with no entry is still the
// synthesised placeholder carried over from the Java version.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const AUDIO_EXT = /\.(mp3|wav|ogg|oga|m4a|aac|flac|webm|opus|aif|aiff|wma|mp4)$/i;

export function createSfx({ app, normalize, say }) {
  const levelsFile = path.join(app, "assets/content/levels.json");
  const sourcesFile = path.join(app, "docs/audio/sfx_sources.json");

  const readLevels = () => JSON.parse(fs.readFileSync(levelsFile, "utf8"));

  const readSources = () => {
    try {
      return JSON.parse(fs.readFileSync(sourcesFile, "utf8"));
    } catch {
      return {
        note: "صدای حیوان‌ها و وسایل که با فایل واقعی جایگزین شده‌اند. صدایی که اینجا نیست هنوز همان صدای سنتزیِ نسخه‌ی قبلی است.",
        files: {},
      };
    }
  };

  const writeSources = (data) => {
    fs.mkdirSync(path.dirname(sourcesFile), { recursive: true });
    const files = Object.fromEntries(Object.entries(data.files).sort(([a], [b]) => a.localeCompare(b)));
    const temp = sourcesFile + ".tmp";
    fs.writeFileSync(temp, JSON.stringify({ ...data, files }, null, 2) + "\n", "utf8");
    fs.renameSync(temp, sourcesFile);
  };

  const soundOf = (id) => {
    const sound = (readLevels().sounds || []).find((s) => s.id === id);
    if (!sound) throw new Error(`صدای «${id}» در levels.json نیست`);
    return sound;
  };

  const fileOf = (id) => {
    try {
      return path.join(app, "assets", soundOf(id).audio);
    } catch {
      return null;
    }
  };

  return {
    sourcesFile,
    fileOf,

    list() {
      const levels = readLevels();
      const sources = readSources().files;
      const categories = Object.fromEntries((levels.categories || []).map((c) => [c.id, c.title]));
      return {
        sourcesFile,
        categories: (levels.categories || []).map((c) => ({ id: c.id, title: c.title })),
        sounds: (levels.sounds || []).map((s) => {
          const file = path.join(app, "assets", s.audio);
          const exists = fs.existsSync(file);
          return {
            id: s.id,
            title: s.title,
            category: s.category,
            categoryTitle: categories[s.category] || s.category,
            file: s.audio,
            exists,
            size: exists ? fs.statSync(file).size : 0,
            stamp: exists ? fs.statSync(file).mtimeMs : 0,
            real: Boolean(sources[s.id]),
            source: sources[s.id] || null,
          };
        }),
      };
    },

    /** Cleans the dropped file with ffmpeg and writes it over the sound's own path. */
    async replace(id, buffer, { name = "", source = "", license = "", maxSeconds = 6 } = {}) {
      const sound = soundOf(id);
      if (name && !AUDIO_EXT.test(name)) throw new Error(`«${name}» فایلِ صوتی به نظر نمی‌رسد`);
      const target = path.join(app, "assets", sound.audio);
      const temp = fs.mkdtempSync(path.join(os.tmpdir(), "goshyar-sfx-"));
      const input = path.join(temp, "in" + (path.extname(name) || ".bin"));
      const output = path.join(temp, "out.mp3");
      try {
        fs.writeFileSync(input, buffer);
        const done = await normalize(input, output, maxSeconds);
        if (!done.ok) throw new Error(`ffmpeg نتوانست فایل را بخواند: ${done.error || "؟"}`);
        if (fs.statSync(output).size < 1024) throw new Error("خروجی تقریباً خالی است — فایل صدا دارد؟");
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.copyFileSync(output, target);
      } finally {
        fs.rmSync(temp, { recursive: true, force: true });
      }

      const data = readSources();
      data.files[id] = {
        file: sound.audio,
        original: name,
        source: source.trim(),
        license: license.trim(),
        at: new Date().toISOString(),
      };
      writeSources(data);
      const size = fs.statSync(target).size;
      say("ok", `صدای «${sound.title}» جایگزین شد ← ${sound.audio} (${Math.round(size / 1024)} کیلوبایت)`);
      return { ok: true, id, file: sound.audio, size };
    },

    /** Source and licence can be filled in after the file was replaced. */
    setMeta(id, { source, license }) {
      soundOf(id);
      const data = readSources();
      if (!data.files[id]) throw new Error("این صدا هنوز جایگزین نشده است");
      if (typeof source === "string") data.files[id].source = source.trim();
      if (typeof license === "string") data.files[id].license = license.trim();
      writeSources(data);
      return { ok: true };
    },
  };
}
