# -*- coding: utf-8 -*-
"""گوش‌یار — خرس ماسکوت، هشت ژست، همه از یک سازنده تا کاراکتر یکی بماند."""
from svgkit import (grad, flat, ell, circ, rect, path, line, eye, shine,
                    shadow, ground)

POSES = ["idle", "listening", "thinking", "happy",
         "celebrating", "encouraging", "surprised", "sleeping"]


def headphones():
    """کمان و دو گوشی آبی — نشانه‌ی همیشگی گوش‌یار."""
    return (
        # کمان از بالای سر می‌گذرد، نه روی پیشانی
        line("M58 74 Q100 24 142 74", flat("blue", False), 10)
        + line("M58 74 Q100 27 142 74", grad("blue"), 6.5)
        + rect(48, 60, 21, 32, grad("blue"), 10)
        + rect(131, 60, 21, 32, grad("blue"), 10)
        + rect(65, 66, 9, 20, flat("dark", False), 4.5)
        + rect(126, 66, 9, 20, flat("dark", False), 4.5)
        + shine(54, 68, 4, 8, 0.35)
    )


def vest():
    """جلیقه‌ی فیروزه‌ای با لوگوی موج صدا."""
    bars = ""
    for i, h in enumerate((7, 12, 16, 11, 6)):
        x = 88 + i * 6
        bars += rect(x, 126 - h / 2, 3.4, h, "#ffffff", 1.7, extra=' opacity="0.95"')
    return (
        # جلیقه با لبه‌های گرد، نه جعبه‌ای
        path("M74 103 Q100 97 126 103 Q134 120 131 141 "
             "Q100 153 69 141 Q66 120 74 103 Z", grad("teal"))
        + shine(85, 114, 9, 15, 0.22, -18)
        + bars
    )


def bear(pose="idle"):
    p = []
    p.append(shadow(178, 48))

    # دست‌ها پشت بدن
    arms = {
        "celebrating": [(62, 98, -34), (138, 98, 34)],
        "encouraging": [(56, 100, -28), (146, 128, 12)],
        "listening":   [(58, 128, 8), (140, 94, 30)],
        "thinking":    [(58, 128, 8), (126, 90, 40)],
        "surprised":   [(52, 108, -18), (148, 108, 18)],
        "sleeping":    [(60, 134, 10), (140, 134, -10)],
    }.get(pose, [(58, 128, 8), (142, 128, -8)])
    for ax, ay, rot in arms:
        p.append(ell(ax, ay, 11, 15, grad("fur"), rot))

    # پاها
    p.append(ell(84, 158, 14, 10, grad("fur")))
    p.append(ell(116, 158, 14, 10, grad("fur")))

    # بدن
    p.append(ell(100, 126, 32, 30, grad("fur")))
    p.append(vest())

    # گوش‌ها
    for ex in (68, 132):
        p.append(circ(ex, 50, 13, grad("fur")))
        p.append(circ(ex, 51, 7, grad("snout")))

    # سر
    p.append(ell(100, 72, 34, 31, grad("fur")))
    p.append(shine(88, 58, 11, 8, 0.26, -20))

    # چشم‌ها
    closed = pose in ("sleeping",)
    happy = pose in ("celebrating", "happy")
    big = 9.5 if pose == "surprised" else 7.5
    p.append(eye(87, 70, big, closed, happy))
    p.append(eye(113, 70, big, closed, happy))

    # پوزه و بینی
    p.append(ell(100, 86, 15, 11, grad("snout")))
    p.append(ell(100, 81, 6, 4.4, flat("dark", False)))
    p.append(shine(98, 80, 2, 1.4, 0.5))

    # دهان
    if pose == "surprised":
        p.append(ell(100, 93, 4.5, 6, flat("dark", False)))
    elif pose in ("celebrating", "happy"):
        p.append(path("M92 89 Q100 99 108 89 Z", flat("dark", False)))
        p.append(path("M95 94 Q100 98 105 94 Z", flat("pink", False)))
    else:
        p.append(line("M95 90 Q100 94 105 90", flat("dark", False), 2.4))

    p.append(headphones())

    # تزئین ژست
    if pose == "celebrating":
        spots = [(40, 44, "gold"), (160, 40, "cyan"), (32, 86, "pink"),
                 (168, 82, "gold"), (52, 24, "cyan"), (148, 22, "pink"),
                 (26, 62, "gold"), (174, 60, "cyan")]
        for i, (x, y, col) in enumerate(spots):
            p.append(rect(x, y, 7, 7, flat(col, False), 2, rot=i * 32,
                          extra=' opacity="0.9"'))
    if pose == "listening":
        for i in range(3):
            r = 16 + i * 9
            p.append(line(f"M{156} {72 - r * 0.6} A{r} {r} 0 0 1 {156} {72 + r * 0.6}",
                          flat("cyan", False), 3.4, extra=' opacity="0.85"'))
    if pose == "thinking":
        p.append(circ(152, 34, 11, flat("grey", True), ' opacity="0.9"'))
        p.append(circ(140, 48, 5, flat("grey", True), ' opacity="0.9"'))
        p.append(circ(133, 57, 3, flat("grey", True), ' opacity="0.9"'))
        p.append(line("M149 31 Q153 27 156 31 Q157 35 152 37", flat("dark", False), 2.6))
        p.append(circ(152, 41, 1.6, flat("dark", False)))
    if pose == "sleeping":
        for i, (x, y, s) in enumerate(((138, 46, 7), (150, 33, 9), (164, 19, 11))):
            p.append(line(f"M{x} {y} h{s} l-{s} {s} h{s}", flat("grey", False), 2.6))
    if pose == "encouraging":
        # دست بالا، حالت سلام
        p.append(line("M50 92 l-5 -7 M56 88 l-3 -8 M62 86 l0 -8",
                      flat("fur", False), 2.4, extra=' opacity="0.7"'))

    return "".join(p)
