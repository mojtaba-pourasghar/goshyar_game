#!/usr/bin/env python3
"""
آیکون‌های دسته‌بندی و مدال‌ها را به‌صورت وکتور می‌سازد و PNG می‌دهد.

اینها با SVG کشیده می‌شوند (گرادیان شعاعی، سایه‌ی نرم، هایلایت براق) تا به
حال‌وهوای طرح مرجع نزدیک باشند. برای آیکون، وکتور ابزار درستی است و نتیجه‌اش
در هر اندازه‌ای تمیز می‌ماند.

    python3 tools/make_icons.py

خروجی: app/src/main/res/drawable/ic_cat_*.png و ic_badge_*.png
"""
import os
import sys

try:
    import cairosvg
except ImportError:
    sys.exit("cairosvg نصب نیست.  →  pip install cairosvg")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "app", "src", "main", "res", "drawable")
SIZE = 256


def svg(body, bg_from, bg_to):
    """یک کارت گرد با گرادیان، سایه و هایلایت، و شکل دلخواه وسطش."""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="{SIZE}" height="{SIZE}">
  <defs>
    <radialGradient id="bg" cx="35%" cy="28%" r="85%">
      <stop offset="0%" stop-color="{bg_from}"/>
      <stop offset="100%" stop-color="{bg_to}"/>
    </radialGradient>
    <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.38"/>
      <stop offset="55%" stop-color="#ffffff" stop-opacity="0.06"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
    <filter id="drop" x="-30%" y="-30%" width="160%" height="170%">
      <feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="#000000" flood-opacity="0.22"/>
    </filter>
    <filter id="soft" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="1.2" flood-color="#000000" flood-opacity="0.28"/>
    </filter>
  </defs>
  <g filter="url(#drop)">
    <rect x="8" y="8" width="104" height="104" rx="30" fill="url(#bg)"/>
    <rect x="8" y="8" width="104" height="52" rx="26" fill="url(#gloss)"/>
  </g>
  <g filter="url(#soft)" fill="#ffffff">{body}</g>
</svg>'''


# ── دسته‌بندی‌ها ───────────────────────────────────────────────────────
PAW = ('<ellipse cx="60" cy="72" rx="20" ry="16"/>'
       '<ellipse cx="42" cy="50" rx="7.5" ry="10"/>'
       '<ellipse cx="55" cy="43" rx="7.5" ry="10.5"/>'
       '<ellipse cx="69" cy="43" rx="7.5" ry="10.5"/>'
       '<ellipse cx="81" cy="51" rx="7.5" ry="10"/>')

HOUSE = ('<path d="M60 34 L92 60 L84 60 L84 86 Q84 90 80 90 L40 90 Q36 90 36 86 L36 60 L28 60 Z"/>'
         '<rect x="52" y="68" width="16" height="22" rx="3" fill="#ffffff" opacity="0.55"/>')

LEAF = ('<path d="M78 36 Q86 62 68 80 Q50 96 40 86 Q32 76 42 60 Q54 40 78 36 Z"/>'
        '<path d="M74 42 Q56 58 46 84" stroke="#ffffff" stroke-width="2.6" fill="none" opacity="0.5"/>')

NOTE = ('<path d="M74 28 L74 70 Q74 80 64 82 Q54 84 54 76 Q54 68 64 67 Q68 66.6 70 68 L70 42 L50 47 L50 78 '
        'Q50 88 40 90 Q30 92 30 84 Q30 76 40 75 Q44 74.6 46 76 L46 40 Z"/>')

CASE = ('<rect x="30" y="48" width="60" height="42" rx="7"/>'
        '<path d="M48 48 L48 42 Q48 36 54 36 L66 36 Q72 36 72 42 L72 48" '
        'stroke="#ffffff" stroke-width="6" fill="none" stroke-linecap="round"/>'
        '<rect x="30" y="64" width="60" height="5" fill="#ffffff" opacity="0.45"/>')

ROCKET = ('<path d="M60 26 Q74 42 74 62 L74 74 L46 74 L46 62 Q46 42 60 26 Z"/>'
          '<circle cx="60" cy="52" r="7" fill="#ffffff" opacity="0.55"/>'
          '<path d="M46 64 L34 78 L46 74 Z"/><path d="M74 64 L86 78 L74 74 Z"/>'
          '<path d="M53 76 Q60 94 67 76 Z" opacity="0.8"/>')

CATEGORIES = {
    "ic_cat_animals":     (PAW,    "#FFB85C", "#F57C00"),
    "ic_cat_home":        (HOUSE,  "#7BD88F", "#2E9E4F"),
    "ic_cat_nature":      (LEAF,   "#4FD6E8", "#0097A7"),
    "ic_cat_music":       (NOTE,   "#F978AE", "#D81B60"),
    "ic_cat_professions": (CASE,   "#B07BE8", "#6A1B9A"),
    "ic_cat_science":     (ROCKET, "#6FA8FF", "#1565C0"),
}

# ── مدال‌ها ───────────────────────────────────────────────────────────
STAR = ('<path d="M60 30 L69 52 L93 54 L75 69 L80 92 L60 80 L40 92 L45 69 L27 54 L51 52 Z"/>')
TROPHY = ('<path d="M44 34 L76 34 L74 60 Q74 72 60 72 Q46 72 46 60 Z"/>'
          '<path d="M44 40 L34 40 Q30 40 30 46 Q30 56 44 58" stroke="#ffffff" stroke-width="5" fill="none"/>'
          '<path d="M76 40 L86 40 Q90 40 90 46 Q90 56 76 58" stroke="#ffffff" stroke-width="5" fill="none"/>'
          '<rect x="55" y="72" width="10" height="12"/><rect x="44" y="84" width="32" height="8" rx="3"/>')
# لالهٔ گوش: حلقهٔ بیرونی + حلزونی داخل + نرمهٔ پایین
EAR = ('<path d="M40 60 Q40 30 62 30 Q84 30 84 58 Q84 72 74 82 Q66 90 64 98 '
       'Q62 106 54 104 Q46 102 48 92 Q50 80 60 72 Q68 66 68 58 Q68 46 58 46 '
       'Q48 46 48 60 Q48 66 42 66 Q36 66 40 60 Z"/>'
       '<path d="M58 58 Q62 58 62 64 Q62 72 54 80" stroke="#ffffff" stroke-width="4" '
       'fill="none" stroke-linecap="round" opacity="0.55"/>')
# مغز: دو نیم‌کره با شیارها
BRAIN = ('<path d="M58 32 Q42 32 36 44 Q26 50 30 62 Q26 74 38 80 Q42 92 58 90 Z"/>'
         '<path d="M62 32 Q78 32 84 44 Q94 50 90 62 Q94 74 82 80 Q78 92 62 90 Z"/>'
         '<path d="M46 44 Q54 50 46 58 Q54 64 46 74" stroke="#ffffff" stroke-width="3" '
         'fill="none" stroke-linecap="round" opacity="0.5"/>'
         '<path d="M74 44 Q66 50 74 58 Q66 64 74 74" stroke="#ffffff" stroke-width="3" '
         'fill="none" stroke-linecap="round" opacity="0.5"/>')
MEDAL = ('<circle cx="60" cy="68" r="22"/>'
         '<path d="M48 48 L40 24 L54 24 L60 42 Z" opacity="0.85"/>'
         '<path d="M72 48 L80 24 L66 24 L60 42 Z" opacity="0.85"/>'
         '<circle cx="60" cy="68" r="12" fill="#ffffff" opacity="0.45"/>')
CROWN = ('<path d="M30 78 L36 42 L50 60 L60 34 L70 60 L84 42 L90 78 Z"/>'
         '<rect x="30" y="80" width="60" height="9" rx="4"/>')
FOOT = ('<ellipse cx="60" cy="70" rx="17" ry="21"/>'
        '<circle cx="44" cy="44" r="6"/><circle cx="56" cy="38" r="6.5"/>'
        '<circle cx="68" cy="38" r="6.5"/><circle cx="79" cy="45" r="6"/>')

BADGES = {
    "ic_badge_first":  (FOOT,   "#9FD8FF", "#1976D2"),
    "ic_badge_shop":   (TROPHY, "#FFD66B", "#F9A825"),
    "ic_badge_nature": (LEAF,   "#8BE6A8", "#2E7D32"),
    "ic_badge_animal": (PAW,    "#FFBE7A", "#EF6C00"),
    "ic_badge_memory": (BRAIN,  "#D3A7F5", "#7B1FA2"),
    "ic_badge_ear":    (EAR,    "#7FE3EC", "#00838F"),
    "ic_badge_hero":   (CROWN,  "#FFD36B", "#C77800"),
}

EXTRA = {
    "ic_gold_star": (STAR,  "#FFDC73", "#F9A825"),
    "ic_medal":     (MEDAL, "#FFD66B", "#E65100"),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    made = 0
    for group in (CATEGORIES, BADGES, EXTRA):
        for name, (body, c1, c2) in group.items():
            path = os.path.join(OUT, name + ".png")
            cairosvg.svg2png(bytestring=svg(body, c1, c2).encode("utf-8"),
                             write_to=path, output_width=SIZE, output_height=SIZE)
            print(f"✅ {name}.png  {os.path.getsize(path) // 1024} KB")
            made += 1
    print(f"\n{made} آیکون در {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
