# -*- coding: utf-8 -*-
"""
ابزار کشیدن تصویرهای وکتور گوش‌یار.

سبک: شکل‌های گرد و نرم، سایه‌روشن ملایم با گرادیان شعاعی، برق کوچک روی چشم‌ها،
پس‌زمینه‌ی سفید تمیز — همان حال‌وهوای طرح مرجع.

هر تصویر یک تابع است که رشته‌ی SVG برمی‌گرداند؛ render() آن را PNG می‌کند.
"""
import os

import cairosvg

VIEW = 200          # دستگاه مختصات همه‌ی تصویرها: ۲۰۰×۲۰۰
SIZE = 512          # اندازه‌ی خروجی PNG


# ── پالت ───────────────────────────────────────────────────────────────
C = {
    "fur":       ("#F0A24E", "#D4762A"),
    "fur_light": ("#FFD9A8", "#F0A24E"),
    "snout":     ("#FFE2BC", "#F3C38C"),
    "teal":      ("#2BC2CE", "#0D8E99"),
    "blue":      ("#5B9BF0", "#2F6FD0"),
    "dark":      ("#4A382C", "#241A14"),
    "white":     ("#FFFFFF", "#E6EBF2"),
    "grey":      ("#C8D0DA", "#98A4B4"),
    "black":     ("#4A4A4A", "#242424"),
    "gold":      ("#FFD56B", "#F0A516"),
    "silver":    ("#E2E8F0", "#A9B4C2"),
    "red":       ("#FF7A6E", "#E23B3B"),
    "green":     ("#6FD27C", "#2E9E4F"),
    "grass":     ("#79DA85", "#3FA34D"),
    "water":     ("#67D3F5", "#1E9BD0"),
    "wood":      ("#C98F56", "#8A5A2B"),
    "pink":      ("#FFA3C6", "#E8508F"),
    "purple":    ("#B98BF0", "#7E22CE"),
    "cyan":      ("#6EE2F0", "#12A8C0"),
    "yellow":    ("#FFDE6B", "#F0BE10"),
    "orange":    ("#FFB266", "#F07A1A"),
    "brown":     ("#A9743F", "#63411F"),
    "cream":     ("#FFF4DE", "#E8D3AC"),
    "sky":       ("#B9E4FF", "#6FBDF0"),
    "night":     ("#4B5A9E", "#232C57"),
    "stone":     ("#C4C9D0", "#8A9099"),
    "sand":      ("#FFE1A8", "#E0B463"),
}

_defs = []
_seen = set()


def grad(name):
    """گرادیان شعاعی با نور از بالا-چپ — همان نورپردازی همه‌ی تصویرها."""
    key = "g_" + name
    if key not in _seen:
        lo, hi = C[name]
        _seen.add(key)
        _defs.append(
            f'<radialGradient id="{key}" cx="33%" cy="27%" r="78%">'
            f'<stop offset="0%" stop-color="{lo}"/>'
            f'<stop offset="100%" stop-color="{hi}"/></radialGradient>'
        )
    return f"url(#{key})"


def flat(name, light=True):
    return C[name][0 if light else 1]


# ── شکل‌های پایه ───────────────────────────────────────────────────────

def ell(cx, cy, rx, ry, fill, rot=None, extra=""):
    t = f' transform="rotate({rot} {cx} {cy})"' if rot else ""
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}"{t}{extra}/>'


def circ(cx, cy, r, fill, extra=""):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"{extra}/>'


def rect(x, y, w, h, fill, r=0, rot=None, extra=""):
    t = f' transform="rotate({rot} {x + w / 2} {y + h / 2})"' if rot else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"{t}{extra}/>'


def path(d, fill, extra=""):
    return f'<path d="{d}" fill="{fill}"{extra}/>'


def line(d, stroke, w=3, cap="round", extra=""):
    return (f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{w}" '
            f'stroke-linecap="{cap}" stroke-linejoin="round"{extra}/>')


def eye(cx, cy, r=7.5, closed=False, happy=False):
    """چشم با برق — یا بسته/خندان به شکل کمان."""
    if closed or happy:
        d = (f"M{cx - r} {cy + 2} Q{cx} {cy - r - 1} {cx + r} {cy + 2}" if happy
             else f"M{cx - r} {cy} Q{cx} {cy + r} {cx + r} {cy}")
        return line(d, flat("dark", False), 3.2)
    return (circ(cx, cy, r, flat("dark", False))
            + circ(cx - r * 0.3, cy - r * 0.35, r * 0.34, "#ffffff"))


def shine(cx, cy, rx, ry, op=0.3, rot=None):
    """برق نرم روی سطح، همان هایلایت طرح مرجع."""
    return ell(cx, cy, rx, ry, "#ffffff", rot, f' opacity="{op}"')


def ground(cy=168, rx=62, fill=None):
    """تکه چمن یا سایه‌ی زیر سوژه."""
    return ell(100, cy, rx, 12, fill or grad("grass"))


def shadow(cy=176, rx=52):
    return ell(100, cy, rx, 8, "#9aa4b4", extra=' opacity="0.16"')


# ── ساخت و خروجی ──────────────────────────────────────────────────────

def svg(body):
    global _defs, _seen
    d = "".join(_defs)
    _defs, _seen = [], set()
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VIEW} {VIEW}" '
            f'width="{SIZE}" height="{SIZE}">'
            f'<defs>{d}'
            f'<filter id="soft" x="-25%" y="-25%" width="150%" height="150%">'
            f'<feDropShadow dx="0" dy="2.2" stdDeviation="2.4" flood-color="#2b2b2b" '
            f'flood-opacity="0.2"/></filter></defs>'
            f'<g filter="url(#soft)">{body}</g></svg>')


def render(name, body, out_dir, size=SIZE):
    """یک تصویر را به PNG می‌نویسد و مسیرش را برمی‌گرداند."""
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, name + ".png")
    cairosvg.svg2png(bytestring=svg(body).encode("utf-8"), write_to=out,
                     output_width=size, output_height=size)
    return out
