# -*- coding: utf-8 -*-
"""
صدای حیوانات — ساخته‌شده با سنتز فورمنتی.

روش: یک منبع صدا (موج ارّه‌ای برای صدای دارِ حنجره، یا نویز برای بخش بادی)
از چند فیلتر رزونانسی رد می‌شود که نقش دهان و حلق حیوان را بازی می‌کنند،
و زیر و بمی صدا در طول زمان تغییر می‌کند.

اینها «کارتونی» هستند نه ضبط واقعی: برای بازی کودکانه قابل تشخیص‌اند،
ولی جای صدای ضبط‌شده‌ی واقعی را نمی‌گیرند.
"""
import numpy as np
from synth import (SR, sine, saw, square, noise, glide, ramp, perc, fade, adsr, env_shape,
                   lowpass, highpass, bandpass, formants, echo, reverb, tremolo,
                   mix, seq, at, silence, finish, t)


def lion():
    """غُرِّش شیر: زیرِ بم، فورمنت‌های پایین، نویز نفَس روی آن."""
    d = 1.9
    f = glide(118, 72, d, curve=0.55)
    src = saw(f, d) * 0.8 + noise(d) * 0.22
    body = formants(src, [180, 420, 1050, 2200], [1.0, 0.75, 0.4, 0.15], q=11)
    body = env_shape(body, [(0, 0), (0.09, 1.0), (0.45, 0.92), (0.78, 0.55), (1, 0)])
    breath = lowpass(noise(d), 700) * 0.28
    breath = env_shape(breath, [(0, 0), (0.15, 0.9), (1, 0)])
    rumble = sine(glide(58, 38, d), d) * 0.35
    return finish(reverb(mix(body, breath, rumble), 0.3))


def cow():
    """مُو کشیدن گاو: شروع بالا، افت طولانی، فورمنت باز."""
    d = 1.7
    f = np.concatenate([glide(150, 205, 0.35, 0.6), glide(205, 128, d - 0.35, 1.4)])
    src = saw(f, d) * 0.85 + noise(d) * 0.1
    body = formants(src, [330, 760, 1600], [1.0, 0.6, 0.22], q=13)
    body = env_shape(body, [(0, 0), (0.12, 1.0), (0.55, 0.95), (1, 0)])
    return finish(reverb(body, 0.22))


def dog():
    """دو پارسِ کوتاه و تند."""
    def bark():
        d = 0.26
        f = glide(430, 190, d, 0.45)
        src = saw(f, d) * 0.75 + noise(d) * 0.35
        b = formants(src, [520, 1250, 2600], [1.0, 0.7, 0.4], q=9)
        return env_shape(b, [(0, 0), (0.04, 1.0), (0.25, 0.6), (1, 0)])
    return finish(seq(bark(), silence(0.16), bark() * 0.88, silence(0.1)))


def cat():
    """میو: فرکانس بالا می‌رود و برمی‌گردد."""
    d = 0.95
    f = np.concatenate([glide(520, 860, 0.3, 0.7), glide(860, 430, 0.65, 1.2)])
    src = saw(f, d) * 0.8 + noise(d) * 0.08
    body = formants(src, [860, 1750, 3100], [1.0, 0.65, 0.3], q=15)
    body = env_shape(body, [(0, 0), (0.1, 1.0), (0.6, 0.85), (1, 0)])
    return finish(reverb(body, 0.14))


def rabbit():
    """خرگوش تقریباً بی‌صداست: چند جیرجیر خیلی کوتاه و نرم."""
    def squeak(f0):
        d = 0.09
        s = sine(glide(f0, f0 * 1.5, d), d) * 0.7 + sine(glide(f0 * 2, f0 * 3, d), d) * 0.2
        return env_shape(s, [(0, 0), (0.2, 1.0), (1, 0)])
    return finish(seq(squeak(900), silence(0.07), squeak(1080), silence(0.06), squeak(960), silence(0.1)))


def bird():
    """چهچهه: چند سُر سریع رو به بالا با ویبراتو."""
    out = silence(1.5)
    pos = 0.05
    for f0, f1, d in ((2100, 3200, 0.11), (2600, 3500, 0.09), (1900, 3000, 0.13),
                      (2800, 2200, 0.1), (2200, 3400, 0.12)):
        c = sine(glide(f0, f1, d, 0.8), d)
        c = tremolo(c, 38, 0.3)
        c = env_shape(c, [(0, 0), (0.15, 1.0), (0.7, 0.8), (1, 0)])
        out = at(out, c * 0.85, pos)
        pos += d + 0.08
    return finish(reverb(out, 0.2))


def sheep():
    """بع‌بع: ویبراتوی تند روی زیرِ ثابت، همان لرزش معروف."""
    d = 1.15
    f = glide(330, 275, d, 1.1) * (1 + 0.1 * np.sin(2 * np.pi * 15 * t(d)))
    src = saw(f, d) * 0.85 + noise(d) * 0.12
    body = formants(src, [640, 1400, 2500], [1.0, 0.6, 0.25], q=12)
    body = env_shape(body, [(0, 0), (0.08, 1.0), (0.7, 0.8), (1, 0)])
    return finish(reverb(body, 0.18))


def horse():
    """شیهه: سُرِ بلند رو به پایین با لرزش."""
    d = 1.5
    f = glide(560, 190, d, 1.6) * (1 + 0.14 * np.sin(2 * np.pi * 22 * t(d)))
    src = saw(f, d) * 0.8 + noise(d) * 0.25
    body = formants(src, [700, 1500, 2700], [1.0, 0.65, 0.3], q=10)
    body = env_shape(body, [(0, 0), (0.06, 1.0), (0.5, 0.85), (0.85, 0.45), (1, 0)])
    puff = highpass(noise(d), 1800) * 0.12
    puff = env_shape(puff, [(0, 0), (0.75, 0.3), (0.95, 1.0), (1, 0)])
    return finish(reverb(mix(body, puff), 0.25))


def duck():
    """کواک‌کواک: سه تای کوتاه و بینی."""
    def quack():
        d = 0.17
        f = glide(330, 240, d, 0.5)
        src = saw(f, d) * 0.9 + noise(d) * 0.2
        q = formants(src, [900, 1900, 2900], [1.0, 0.85, 0.5], q=8)
        return env_shape(q, [(0, 0), (0.08, 1.0), (0.4, 0.7), (1, 0)])
    return finish(seq(quack(), silence(0.1), quack() * 0.9, silence(0.09), quack() * 0.8, silence(0.1)))


def frog():
    """قورقور: ضربان تند روی زیرِ بم."""
    d = 1.1
    pulse = (square(np.full(int(SR * d), 42.0), d, 0.35) + 1) / 2
    f = glide(210, 175, d)
    src = saw(f, d) * pulse
    body = formants(src, [420, 900, 1700], [1.0, 0.55, 0.2], q=14)
    body = env_shape(body, [(0, 0), (0.1, 1.0), (0.8, 0.9), (1, 0)])
    return finish(reverb(body, 0.3))


def elephant():
    """شیپور فیل: سُرِ تند رو به بالا و نگه‌داشتن بلند."""
    d = 1.8
    f = np.concatenate([glide(210, 680, 0.3, 0.5), glide(680, 560, 1.0, 1.0),
                        glide(560, 230, d - 1.3, 1.5)])
    src = saw(f, d) * 0.85
    body = formants(src, [640, 1250, 2100], [1.0, 0.7, 0.35], q=9)
    body = env_shape(body, [(0, 0), (0.08, 1.0), (0.6, 0.95), (0.85, 0.6), (1, 0)])
    rumble = sine(glide(70, 48, d), d) * 0.3
    return finish(reverb(mix(body, rumble), 0.35))


def rooster():
    """قوقولی‌قوقو: چهار هجای پلکانی."""
    parts = []
    for f0, f1, d, g in ((620, 700, 0.22, 1.0), (760, 820, 0.2, 0.95),
                         (560, 620, 0.3, 0.9), (680, 420, 0.55, 0.85)):
        f = glide(f0, f1, d, 0.8) * (1 + 0.06 * np.sin(2 * np.pi * 18 * t(d)))
        src = saw(f, d) * 0.85 + noise(d) * 0.18
        p = formants(src, [820, 1700, 2900], [1.0, 0.7, 0.4], q=10)
        parts.append(env_shape(p, [(0, 0), (0.07, 1.0), (0.7, 0.85), (1, 0)]) * g)
        parts.append(silence(0.05))
    return finish(reverb(seq(*parts), 0.22))


ANIMALS = {
    "animals_lion": lion, "animals_cow": cow, "animals_dog": dog, "animals_cat": cat,
    "animals_rabbit": rabbit, "animals_bird": bird, "animals_sheep": sheep,
    "animals_horse": horse, "animals_duck": duck, "animals_frog": frog,
    "animals_elephant": elephant, "animals_rooster": rooster,
}
