#!/usr/bin/env python3
"""One-off migration: legacy levels.json -> assets/content/{levels,voice_lines}.json"""
import json
import sys

legacy_path, out_dir = sys.argv[1], sys.argv[2]
legacy = json.load(open(legacy_path, encoding="utf-8"))

# ---------------------------------------------------------------- levels.json
CAT_META = {
    "animals": ("pets", "#FF8A1F", "حیوانات"),
    "home": ("house", "#F25C3B", "وسایل خانه"),
    "nature": ("eco", "#2FBF71", "طبیعت"),
    "music": ("music", "#E9478F", "موسیقی"),
    "professions": ("work", "#3B82F6", "حرفه‌ها"),
    "science": ("rocket", "#8E44EC", "فضا و علم"),
}
CAT_BLURB = {
    "animals": "صدای حیوان‌های جنگل و مزرعه",
    "home": "صداهایی که هر روز در خانه می‌شنوی",
    "nature": "باران، باد، دریا و رودخانه",
    "music": "سازهای شاد و پرصدا",
    "professions": "صدای ابزار و ماشین‌های امدادی",
    "science": "موشک، ربات و سفینه",
}

MODE_META = {
    "who_made_sound": dict(prefix="who", title="این صدا مال کیه؟", subtitle="صاحب صدا را پیدا کن",
                           icon="hearing", color="#FF8A1F", scene="meadow"),
    "find_source": dict(prefix="find", title="صدای مخفی را پیدا کن", subtitle="صدا از کجا می‌آید؟",
                        icon="travel_explore", color="#7C3AED", scene="forest_day"),
    "sequence": dict(prefix="seq", title="ترتیب صداها", subtitle="صداها را به ترتیب بچین",
                     icon="queue_music", color="#0EA5A4", scene="meadow"),
    "audio_mission": dict(prefix="mission", title="مأموریت شنیداری", subtitle="چند صدا می‌شنوی؟",
                          icon="nights_stay", color="#3B4FD8", scene="forest_night"),
}
MODE_ORDER = ["who_made_sound", "find_source", "sequence", "audio_mission"]
SCENE_FOR_BG = {"bg_sunny_forest": "forest_day", "bg_farm": "farm", "bg_home": "home",
                "bg_city": "city", "bg_night_forest": "forest_night"}

out = {
    "version": 2,
    "migratedFrom": "goshyar_game@7fd09f8 app/src/main/assets/levels.json",
    "scoring": {"correctPoints": 20, "firstTryBonus": 5, "pointsPerRank": 500,
                "stars": {"three": 0, "two": 1}},
    "categoryPlay": {"rounds": 5, "options": 3},
    "categories": [],
    "sounds": [],
    "places": [],
    "modes": [],
    "achievements": [],
}
for c in legacy["categories"]:
    icon, color, title = CAT_META[c["id"]]
    out["categories"].append({"id": c["id"], "title": title, "blurb": CAT_BLURB[c["id"]],
                              "icon": icon, "color": color})
for s in legacy["sounds"]:
    out["sounds"].append({"id": s["id"], "title": s["title"], "category": s["category"],
                          "image": "images/sounds/%s.webp" % s["id"],
                          "audio": "audio/" + s["audio"]})
for p in legacy["places"]:
    out["places"].append({"id": p["id"], "title": p["title"],
                          "image": "images/places/%s.webp" % p["id"]})

modes_by_id = {m["id"]: m for m in legacy["modes"]}
for mid in MODE_ORDER:
    m = modes_by_id[mid]
    meta = MODE_META[mid]
    mode = {"id": mid, "title": meta["title"], "subtitle": meta["subtitle"], "icon": meta["icon"],
            "color": meta["color"], "scene": meta["scene"], "voicePrefix": meta["prefix"], "levels": []}
    for l in m["levels"]:
        lvl = {"n": l["n"]}
        if mid in ("who_made_sound", "find_source"):
            lvl["sound"] = l["sound"]
            lvl["answer"] = l.get("answer", l["sound"])
            lvl["options"] = l["options"]
        elif mid == "sequence":
            lvl["sequence"] = l["sequence"]
        else:
            lvl["sceneTitle"] = l["scene"]
            lvl["scene"] = SCENE_FOR_BG[l["background"]]
            lvl["layers"] = l["layers"]
            lvl["answer"] = l["answer"]
            lvl["options"] = l["options"]
        mode["levels"].append(lvl)
    out["modes"].append(mode)

ACH_ICON = {"first_step": "flag", "sound_shop": "construction", "nature_friend": "eco",
            "animal_expert": "pets", "memory_master": "psychology", "sharp_ear": "hearing",
            "audio_hero": "emoji_events"}
for a in legacy["achievements"]:
    rule = "levels>=all" if a["id"] == "audio_hero" else a["rule"]
    out["achievements"].append({"id": a["id"], "title": a["title"], "desc": a["desc"],
                                "icon": ACH_ICON[a["id"]], "rule": rule})

json.dump(out, open(out_dir + "/levels.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)

# ----------------------------------------------------------- voice_lines.json
lines = []


def add(id_, text, event, screen, group=None, delay=0, note=None):
    item = {"id": id_, "text": text, "event": event, "screen": screen,
            "file": "voice/%s.mp3" % id_.replace(".", "_")}
    if group:
        item["group"] = group
    if delay:
        item["delayMs"] = delay
    if note:
        item["note"] = note
    lines.append(item)


# --- صفحه‌ها
add("app.splash.welcome", "سلام! من گوش‌یار هستم. بازی کن، گوش بده، کشف کن!", "splash.shown", "splash", delay=500)
add("app.intro.1", "سلام دوست کوچولوی من! من گوش‌یار هستم، یک خرس کوچولو که عاشق صداهاست.", "intro.page1", "intro", delay=300)
add("app.intro.2", "امروز می‌خواهیم با گوش‌هایمان صداهای جالب را پیدا کنیم.", "intro.page2", "intro", delay=300)
add("app.intro.3", "اول خوب گوش بده، بعد عکس درست را لمس کن. آماده‌ای؟ پس بزن بریم!", "intro.page3", "intro", delay=300)
add("app.home.greet.1", "سلام دوباره! امروز کدام بازی را دوست داری؟", "home.shown", "home", group="home.greet", delay=400)
add("app.home.greet.2", "خوش برگشتی! یک دسته را انتخاب کن.", "home.shown", "home", group="home.greet", delay=400)
add("app.home.greet.3", "گوش‌هایت آماده‌اند؟ بیا یک بازی انتخاب کنیم.", "home.shown", "home", group="home.greet", delay=400)
add("app.games.hub", "چهار بازی داریم. هر کدام را دوست داری، لمس کن.", "games.shown", "games", delay=300)
add("app.library.hint", "اینجا خانه‌ی صداهاست. روی هر عکس بزن تا صدایش را بشنوی.", "library.shown", "library", delay=300)
add("app.progress.shown", "ببین چقدر ستاره جمع کرده‌ای! آفرین به تو.", "progress.shown", "progress", delay=300)
add("app.badges.shown", "این‌ها مدال‌های تو هستند. مدال‌های کم‌رنگ هنوز منتظر تو هستند!", "badges.shown", "badges", delay=300)
add("app.settings.shown", "اینجا بزرگ‌ترها صدای من و موسیقی را تنظیم می‌کنند.", "settings.shown", "settings", delay=300)
add("app.parent.gate", "این بخش برای بزرگ‌ترهاست. لطفاً از یک بزرگ‌تر کمک بگیر.", "parent_gate.shown", "parent_gate")
add("app.downloads.shown", "این‌ها صداها و تصویرهایی هستند که روی گوشی ذخیره شده‌اند.", "downloads.shown", "downloads", delay=300)

# --- دسته‌ها
CAT_INTRO = {
    "animals": "بیا به صدای حیوان‌ها گوش بدهیم!",
    "home": "بیا صداهای خانه را پیدا کنیم!",
    "nature": "بیا به صدای طبیعت گوش بدهیم!",
    "music": "بیا سازها را از صدایشان بشناسیم!",
    "professions": "بیا ببینیم این صداها مال چه کاری هستند!",
    "science": "بیا به صداهای فضا و علم گوش بدهیم!",
}
for cid, text in CAT_INTRO.items():
    add("cat.%s.intro" % cid, text, "category.opened", "category")
add("cat.mission", "یک صدا پخش می‌شود. عکس صاحب صدا را لمس کن.", "category.start", "category_game")
add("cat.complete", "همه‌ی صداهای این دور را پیدا کردی! آفرین!", "category.complete", "result")

# --- بازی‌ها: خوشامد و مأموریت
MODE_TEXT = {
    "who": ("بازی «این صدا مال کیه؟» شروع شد!", "یک صدا پخش می‌شود. خوب گوش بده و صاحب صدا را پیدا کن."),
    "find": ("به بازی «صدای مخفی» خوش آمدی!", "گوش بده و بگو این صدا از کدام جا می‌آید."),
    "seq": ("بازی ترتیب صداها! حافظه‌ات را آماده کن.", "چند صدا پشت سر هم می‌آید. همان ترتیب را با عکس‌ها بچین."),
    "mission": ("مأموریت شنیداری شروع شد!", "چشم‌هایت را ببند و خوب گوش کن. چند صدای مختلف می‌شنوی؟"),
}
for p, (welcome, mission) in MODE_TEXT.items():
    add("%s.welcome" % p, welcome, "mode.opened", "level_map")
    add("%s.mission" % p, mission, "mode.first_level", "game")

# --- دعوت به گوش دادن (قبل از پخش صدا)
for i, t in enumerate(["هیس! خوب گوش بده.", "گوش‌هایت را تیز کن!", "آماده‌ای؟ صدا می‌آید...",
                       "گوش کن... چه صدایی می‌شنوی؟"], 1):
    add("listen.invite.%d" % i, t, "game.before_sound", "game", group="listen.invite",
        note="قبل از پخش صدای اصلی؛ صدای بازی ۳۰۰ میلی‌ثانیه بعد از پایان این جمله پخش می‌شود")

# --- پرسش عمومی (بازی دسته‌ها)
for i, t in enumerate(["این صدا مال کیه؟", "کی این صدا را درآورد؟", "صاحب این صدا را پیدا کن!"], 1):
    add("question.who.%d" % i, t, "game.after_sound", "category_game", group="question.who")

# --- بازخورد
for i, t in enumerate(["آفرین! درست بود!", "عالی بود!", "ای ول! گوش‌هایت خیلی تیز است!",
                       "درسته! چه خوب گوش دادی!", "همین بود! باریکلا!", "هورا! پیدایش کردی!"], 1):
    add("feedback.correct.%d" % i, t, "game.correct", "feedback", group="feedback.correct")
for i, t in enumerate(["اشکالی ندارد. یک بار دیگر گوش کن.", "نزدیک بود! دوباره امتحان کن.",
                       "این یکی نبود. بیا دوباره گوش بدهیم.", "نگران نباش، با هم پیدایش می‌کنیم."], 1):
    add("feedback.wrong.%d" % i, t, "game.wrong", "feedback", group="feedback.wrong")
for i, t in enumerate(["اگر صدا را خوب نشنیدی، دکمه‌ی آبی را بزن تا دوباره پخش شود.",
                       "می‌توانی صدا را دوباره بشنوی. دکمه‌ی گوش را لمس کن."], 1):
    add("replay.tip.%d" % i, t, "game.replay_tip", "game", group="replay.tip",
        note="بعد از دومین پاسخ اشتباه پشت سر هم")
for i, t in enumerate(["هنوز فکر می‌کنی؟ عجله نکن.", "یکی از عکس‌ها را لمس کن."], 1):
    add("idle.nudge.%d" % i, t, "game.idle", "game", group="idle.nudge", note="۱۲ ثانیه بی‌پاسخ")

# --- پایان مرحله، ستاره‌ها، مرحله‌ی بعد
for i, t in enumerate(["مرحله تمام شد! ستاره‌هایت را ببین.", "تبریک! این مرحله را بردی.",
                       "عالی بود! امتیازهایت را گرفتی."], 1):
    add("level.complete.%d" % i, t, "level.complete", "result", group="level.complete")
add("result.stars.3", "سه ستاره! فوق‌العاده بودی!", "result.stars3", "result", delay=600)
add("result.stars.2", "دو ستاره! خیلی خوب بود.", "result.stars2", "result", delay=600)
add("result.stars.1", "یک ستاره! دفعه‌ی بعد بهتر هم می‌شود.", "result.stars1", "result", delay=600)
for i, t in enumerate(["آماده‌ی مرحله‌ی بعد هستی؟", "برویم سراغ صدای بعدی!", "مرحله‌ی بعد منتظر توست!"], 1):
    add("level.next.%d" % i, t, "level.next", "result", group="level.next")
add("mode.done", "همه‌ی مرحله‌های این بازی تمام شد! تو یک قهرمان شنیداری هستی.", "mode.done", "result")
add("all.done", "باورم نمی‌شود! همه‌ی مرحله‌ها را تمام کردی. گوش‌های تو حرف ندارد!", "all.done", "result")
add("seq.your_turn", "حالا نوبت توست! عکس‌ها را به ترتیب لمس کن.", "sequence.played", "game")

# --- توقف، ادامه، خروج
add("session.pause", "بازی را نگه داشتیم. هر وقت آماده بودی، ادامه بده.", "game.paused", "pause")
add("session.resume", "خوش برگشتی! بیا ادامه بدهیم.", "game.resumed", "pause")
add("session.restart", "از اول شروع می‌کنیم!", "game.restart", "pause")
add("session.exit_ask", "می‌خواهی از بازی بیرون بروی؟", "game.exit_ask", "pause")
add("session.bye", "خداحافظ دوست من! زود برگرد.", "game.exit", "pause")

# --- مدال‌ها
BADGE = {
    "first_step": "مدال اولین قدم مال توست! اولین مرحله را تمام کردی.",
    "sound_shop": "مدال کارگاه صداها را گرفتی! پنج مرحله را بردی.",
    "nature_friend": "مدال دوست طبیعت مال توست! صدای طبیعت را خوب می‌شناسی.",
    "animal_expert": "مدال کارشناس حیوانات را گرفتی! صدای حیوان‌ها را عالی می‌شناسی.",
    "memory_master": "مدال استاد حافظه مال توست! ترتیب صداها را خوب یادت می‌ماند.",
    "sharp_ear": "مدال گوش تیز را گرفتی! ده جواب درست پشت سر هم!",
    "audio_hero": "مدال قهرمان شنیداری! بزرگ‌ترین مدال بازی مال توست.",
}
for bid, t in BADGE.items():
    add("badge.%s" % bid, t, "badge.unlocked", "result")

# --- مرحله‌ها: پرسش (q)، راهنمایی بعد از اشتباه (hint)، تشویق ویژه (ok)
LEVELS = {
    "find": [
        ("یک صدای قشنگ می‌آید. این صدا از کجا می‌آید؟", "جایی را پیدا کن که درخت‌های زیادی دارد.", "آفرین! پرنده در جنگل آواز می‌خواند."),
        ("خوب گوش کن! صاحب این صدا کجا زندگی می‌کند؟", "این حیوان علف می‌خورد و به ما شیر می‌دهد. خانه‌اش کجاست؟", "درسته! گاو در مزرعه زندگی می‌کند."),
        ("این صدا را کجا می‌شنوی؟ خوب فکر کن.", "وقتی مهمان می‌آید، این صدا را می‌شنویم.", "آفرین! زنگ در مال خانه است."),
        ("گوش کن... این صدا ما را به کجا می‌برد؟", "جایی با آب خیلی زیاد و موج‌های بزرگ.", "درسته! این صدای موج‌های دریا بود."),
        ("یک چیزی سوت می‌زند! این صدا از کدام اتاق می‌آید؟", "جایی که غذا می‌پزیم و چای درست می‌کنیم.", "عالی! کتری در آشپزخانه سوت می‌زند."),
        ("صدای آب می‌آید! این آب کجاست؟", "آبی که از روی سنگ‌ها می‌گذرد و جلو می‌رود.", "آفرین! این صدای آب رودخانه بود."),
        ("آژیر می‌آید! این صدا را بیشتر کجا می‌شنویم؟", "جایی با خیابان، ماشین و ساختمان‌های بلند.", "درسته! آمبولانس در شهر به کمک مردم می‌رود."),
        ("وای، چه صدای بلندی! این صدا به کجا می‌رود؟", "خیلی بالا، بالاتر از ابرها، پیش ستاره‌ها.", "آفرین! موشک به فضا پرواز می‌کند."),
        ("صدای وزش می‌آید... این صدا در کدام جا می‌پیچد؟", "جایی تاریک و سنگی در دل کوه.", "عالی! باد در غار می‌پیچد و صدا می‌کند."),
        ("یک دوست کوچولو صدا می‌کند. او کجاست؟", "جایی سبز با چمن، درخت و یک حوض کوچک.", "درسته! قورباغه کنار حوض پارک بود."),
    ],
    "who": [
        ("خوب گوش کن. این صدا مال کدام حیوان است؟", "این حیوان سبیل دارد و دوست دارد با کاموا بازی کند.", "آفرین! این صدای گربه بود. میو!"),
        ("اوه، چه صدای بلندی! صاحبش کیست؟", "این حیوان یال بزرگی دارد و به او می‌گویند سلطان جنگل.", "درسته! این غرش شیر بود."),
        ("این صدا را می‌شناسی؟ صاحبش را پیدا کن.", "این پرنده کنار آب زندگی می‌کند و خوب شنا می‌کند.", "عالی! این صدای اردک بود. کوآک کوآک!"),
        ("یک وسیله صدا می‌دهد. کدام است؟", "با این وسیله می‌توانی با مادربزرگ حرف بزنی.", "آفرین! این صدای تلفن بود."),
        ("صدای یک حیوان خیلی بزرگ! حدس بزن کیست.", "این حیوان خرطوم دراز و گوش‌های بزرگ دارد.", "درسته! این صدای فیل بود."),
        ("این صدای طبیعت است. فکر می‌کنی چیست؟", "از ابرها می‌آید و زمین را خیس می‌کند.", "آفرین! این صدای باران بود."),
        ("یک ساز می‌نوازد. کدام ساز است؟", "این ساز سیم دارد و با انگشت نواخته می‌شود.", "عالی! این صدای گیتار بود."),
        ("یک وسیله‌ی خانه روشن شده. کدام است؟", "این وسیله خاک فرش را جمع می‌کند.", "درسته! این صدای جاروبرقی بود."),
        ("آژیر! کدام ماشین دارد می‌آید؟", "این ماشین قرمز است، نردبان دارد و آتش را خاموش می‌کند.", "آفرین! این ماشین آتش‌نشانی بود."),
        ("بیپ بوپ! این صدای چیست؟", "این دوست فلزی راه می‌رود و چراغ‌های رنگی دارد.", "عالی! این صدای ربات بود."),
    ],
    "seq": [
        ("سه صدا پشت سر هم می‌آید. خوب گوش کن و یادت بماند.", "صدای اول را یادت باشد، بعد دومی، بعد سومی. می‌توانی دوباره گوش کنی.", "آفرین! ترتیب را درست چیدی."),
        ("دوباره سه صدا! این بار چه صداهایی می‌آید؟", "با انگشت‌هایت بشمار: یک، دو، سه.", "عالی! حافظه‌ات خیلی خوب است."),
        ("گوش کن و ترتیب صداها را به خاطر بسپار.", "در ذهنت بگو: اول این، بعد این، بعد این.", "درسته! هر سه سر جایشان هستند."),
        ("این بار چهار صدا! کمی سخت‌تر شد.", "دو صدای اول را یادت باشد، بعد دو صدای بعدی را.", "آفرین! چهار صدا را درست چیدی."),
        ("چهار صدای مزرعه! ترتیبشان یادت نرود.", "فکر کن در مزرعه راه می‌روی و حیوان‌ها را یکی‌یکی می‌بینی.", "عالی! مثل یک کشاورز دقیق گوش دادی."),
        ("چهار ساز موسیقی! با دقت گوش کن.", "هر ساز صدای خودش را دارد: یکی نازک، یکی بم، یکی ضربی.", "درسته! گوش موسیقی تو عالی است."),
        ("پنج صدا! یک نفس عمیق بکش و گوش کن.", "برای هر صدا یک تصویر در ذهنت بساز.", "آفرین! پنج صدا کار سختی بود."),
        ("آخرین مرحله! پنج صدای فضایی. تو می‌توانی!", "عجله نکن. دو بار گوش کن و بعد بچین.", "باورم نمی‌شود! سخت‌ترین مرحله را بردی."),
    ],
    "mission": [
        ("به جنگل رسیدیم! چشم‌هایت را ببند. چند صدای مختلف می‌شنوی؟", "صداها روی هم هستند. سعی کن یکی‌یکی جدایشان کنی.", "آفرین! سه صدا بود: پرنده، باد و رودخانه."),
        ("صبح بخیر مزرعه! بشمار چند صدا می‌شنوی.", "صبح زود حیوان‌های مزرعه بیدار می‌شوند. هر کدام صدای خودش را دارد.", "درسته! چهار صدا بود."),
        ("عصر است و ما در خانه‌ایم. چند صدای مختلف می‌شنوی؟", "به چیزهایی فکر کن که تیک‌تاک می‌کنند، سوت می‌زنند یا زنگ می‌زنند.", "عالی! سه صدا بود."),
        ("وسط شهر شلوغ! خوب گوش کن و بشمار.", "شهر صداهای زیادی دارد. دقت کن، دو آژیر با هم فرق دارند.", "آفرین! پنج صدا بود. شهر چقدر شلوغ است!"),
        ("شب شده و جنگل آرام است. این سخت‌ترین مأموریت است. چند صدا می‌شنوی؟", "بعضی صداها خیلی آرام‌اند. با دقت گوش کن.", "فوق‌العاده بود! پنج صدا را شنیدی."),
    ],
}
for p, items in LEVELS.items():
    for i, (q, hint, ok) in enumerate(items, 1):
        base = "%s.%02d" % (p, i)
        add(base + ".q", q, "game.after_sound" if p != "seq" else "game.level_start", "game",
            note="پاسخ را لو نمی‌دهد")
        add(base + ".hint", hint, "game.wrong", "game", note="بعد از بازخورد اشتباه")
        add(base + ".ok", ok, "game.correct", "feedback")

# --- نام صداها (کتابخانه‌ی صداها و بعد از پاسخ درست در بازی دسته‌ها)
SND = {
    "lion": "این صدای شیر بود. شیر غرش می‌کند!",
    "cow": "این صدای گاو بود. گاو ماغ می‌کشد.",
    "dog": "این صدای سگ بود. سگ هاپ‌هاپ می‌کند.",
    "cat": "این صدای گربه بود. گربه میو میو می‌کند.",
    "rabbit": "این صدای خرگوش بود. خرگوش خیلی آرام است.",
    "bird": "این صدای پرنده بود. پرنده‌ها صبح‌ها آواز می‌خوانند.",
    "sheep": "این صدای گوسفند بود. گوسفند بع‌بع می‌کند.",
    "horse": "این صدای اسب بود. اسب شیهه می‌کشد.",
    "duck": "این صدای اردک بود. اردک کنار آب زندگی می‌کند.",
    "frog": "این صدای قورباغه بود. قورباغه قورقور می‌کند.",
    "elephant": "این صدای فیل بود. فیل با خرطومش صدا می‌کند.",
    "rooster": "این صدای خروس بود. خروس صبح زود همه را بیدار می‌کند.",
    "doorbell": "این صدای زنگ در بود. یک نفر پشت در است!",
    "clock": "این صدای ساعت بود. ساعت تیک‌تاک می‌کند.",
    "phone": "این صدای تلفن بود. یک نفر زنگ می‌زند!",
    "vacuum": "این صدای جاروبرقی بود. جاروبرقی خانه را تمیز می‌کند.",
    "kettle": "این صدای کتری بود. آب که جوش بیاید، کتری سوت می‌زند.",
    "washer": "این صدای ماشین لباسشویی بود. لباس‌ها را می‌چرخاند.",
    "tap": "این صدای شیر آب بود. آب از شیر می‌ریزد.",
    "door": "این صدای در بود. در باز و بسته می‌شود.",
    "rain": "این صدای باران بود. قطره‌ها روی زمین می‌ریزند.",
    "thunder": "این صدای رعد بود. بعد از برق آسمان می‌آید.",
    "wind": "این صدای باد بود. باد بین درخت‌ها می‌پیچد.",
    "sea": "این صدای دریا بود. موج‌ها می‌آیند و می‌روند.",
    "river": "این صدای رودخانه بود. آب روی سنگ‌ها می‌دود.",
    "fire": "این صدای آتش بود. چوب‌ها ترق‌ترق می‌کنند.",
    "waterfall": "این صدای آبشار بود. آب از بالا پایین می‌ریزد.",
    "drum": "این صدای طبل بود. بوم بوم بوم!",
    "piano": "این صدای پیانو بود. پیانو کلیدهای سیاه و سفید دارد.",
    "guitar": "این صدای گیتار بود. گیتار سیم دارد.",
    "violin": "این صدای ویولن بود. ویولن را با آرشه می‌نوازند.",
    "flute": "این صدای فلوت بود. فلوت را با فوت می‌نوازند.",
    "bell": "این صدای زنگوله بود. جرینگ جرینگ!",
    "tambourine": "این صدای دف بود. دف یک ساز گرد ایرانی است.",
    "hammer": "این صدای چکش بود. نجار با چکش میخ می‌کوبد.",
    "saw": "این صدای اره بود. با اره چوب را می‌برند.",
    "ambulance": "این صدای آمبولانس بود. آمبولانس به بیمار کمک می‌کند.",
    "firetruck": "این صدای ماشین آتش‌نشانی بود. آتش‌نشان‌ها آتش را خاموش می‌کنند.",
    "police": "این صدای ماشین پلیس بود. پلیس مراقب ماست.",
    "scissors": "این صدای قیچی بود. قیچی کاغذ را می‌برد.",
    "typing": "این صدای تایپ کردن بود. انگشت‌ها روی دکمه‌ها می‌زنند.",
    "rocket": "این صدای موشک بود. موشک به آسمان می‌رود.",
    "robot": "این صدای ربات بود. ربات بیپ بوپ می‌کند.",
    "spaceship": "این صدای سفینه بود. سفینه بین ستاره‌ها سفر می‌کند.",
    "satellite": "این صدای ماهواره بود. ماهواره دور زمین می‌چرخد.",
    "laser": "این صدای لیزر بود. لیزر یک نور باریک است.",
}
ids = [s["id"] for s in legacy["sounds"]]
assert set(ids) == set(SND), set(ids) ^ set(SND)
for sid in ids:
    add("snd.%s" % sid, SND[sid], "sound.named", "library",
        note="بعد از پخش صدا در کتابخانه، یا بعد از پاسخ درست در بازی دسته‌ها")

seen = set()
for l in lines:
    assert l["id"] not in seen, l["id"]
    seen.add(l["id"])

voice = {
    "version": 1,
    "language": "fa-IR",
    "speaker": "گوش‌یار — خرس مهربان؛ صدای گرم، شاد و آرام، مناسب کودک ۳ تا ۸ سال",
    "format": {"container": "mp3", "sampleRate": 44100, "channels": 1, "bitrateKbps": 96,
               "loudnessLufs": -16, "silenceMs": {"head": 80, "tail": 150}},
    "lines": lines,
}
json.dump(voice, open(out_dir + "/voice_lines.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print(len(lines), "voice lines;", sum(len(m["levels"]) for m in out["modes"]), "levels")
