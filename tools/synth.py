# -*- coding: utf-8 -*-
"""
بلوک‌های پایه برای ساختن صدا — موج، نویز، پاکت، فیلتر، طنین.

همه‌چیز با numpy ساخته می‌شود؛ هیچ فایل بیرونی و هیچ دانلودی لازم نیست.
نرخ نمونه‌برداری همه‌جا ۴۴۱۰۰ است و خروجی هر تابع یک آرایه‌ی float در بازه‌ی [-1, 1].
"""
import numpy as np

SR = 44100
rng = np.random.default_rng(20261013)


def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def silence(dur):
    return np.zeros(int(SR * dur))


# ── موج‌ها ─────────────────────────────────────────────────────────────

def sine(freq, dur, phase=0.0):
    """موج سینوسی. freq می‌تواند عدد باشد یا آرایه‌ای هم‌طول (برای گلیساندو)."""
    x = t(dur)
    f = np.full_like(x, freq, dtype=float) if np.isscalar(freq) else np.resize(np.asarray(freq, float), x.shape)
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def saw(freq, dur):
    x = t(dur)
    f = np.full_like(x, freq, dtype=float) if np.isscalar(freq) else np.resize(np.asarray(freq, float), x.shape)
    ph = np.cumsum(f) / SR
    return 2 * (ph - np.floor(ph + 0.5))


def square(freq, dur, duty=0.5):
    x = t(dur)
    f = np.full_like(x, freq, dtype=float) if np.isscalar(freq) else np.resize(np.asarray(freq, float), x.shape)
    ph = np.cumsum(f) / SR
    return np.where((ph - np.floor(ph)) < duty, 1.0, -1.0)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def glide(f0, f1, dur, curve=1.0):
    """سُر خوردن فرکانس از f0 به f1 — پایه‌ی خیلی از صداهای حیوانی."""
    x = np.linspace(0, 1, int(SR * dur))
    return f0 + (f1 - f0) * (x ** curve)


def ramp(a, b, dur, curve=1.0):
    x = np.linspace(0, 1, int(SR * dur))
    return a + (b - a) * (x ** curve)


# ── پاکت‌ها ────────────────────────────────────────────────────────────

def adsr(x, a=0.01, d=0.1, s=0.7, r=0.2):
    """پاکت کلاسیک حمله/افت/نگه/رهایش."""
    n = len(x)
    na, nd = int(SR * a), int(SR * d)
    nr = int(SR * r)
    ns = max(0, n - na - nd - nr)
    env = np.concatenate([
        np.linspace(0, 1, na),
        np.linspace(1, s, nd),
        np.full(ns, s),
        np.linspace(s, 0, nr),
    ])
    return x * np.resize(env, n)


def perc(x, decay=4.0):
    """افت نمایی — برای ضربه‌ها و زنگ‌ها."""
    return x * np.exp(-decay * np.linspace(0, 1, len(x)) * len(x) / SR * 4)


def fade(x, ms=12):
    """محو کردن ابتدا و انتها تا صدا «کلیک» ندهد."""
    n = min(int(SR * ms / 1000), len(x) // 2)
    if n < 2:
        return x
    y = x.copy()
    y[:n] *= np.linspace(0, 1, n)
    y[-n:] *= np.linspace(1, 0, n)
    return y


def env_shape(x, points):
    """پاکت دلخواه از روی چند نقطه‌ی (نسبت زمان، دامنه)."""
    xs = np.array([p[0] for p in points], float)
    ys = np.array([p[1] for p in points], float)
    return x * np.interp(np.linspace(0, 1, len(x)), xs, ys)


# ── فیلترها (یک‌قطبی، بدون scipy) ──────────────────────────────────────

def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandpass(x, low, high):
    return lowpass(highpass(x, low), high)


def resonate(x, freq, q=24.0):
    """فیلتر رزونانسی دو قطبی — برای ساختن فورمنت‌های صدای حیوان."""
    w = 2 * np.pi * freq / SR
    r = np.exp(-w / (2 * q))
    a1, a2 = -2 * r * np.cos(w), r * r
    y = np.zeros_like(x)
    for i in range(2, len(x)):
        y[i] = x[i] - a1 * y[i - 1] - a2 * y[i - 2]
    return y * (1 - r)


def formants(src, freqs, gains=None, q=18.0):
    """چند فورمنت روی یک منبع — همان کاری که حنجره با صدا می‌کند."""
    gains = gains or [1.0] * len(freqs)
    out = np.zeros_like(src)
    for f, g in zip(freqs, gains):
        out += g * resonate(src, f, q)
    return out


# ── فضا ────────────────────────────────────────────────────────────────

def echo(x, delay=0.12, decay=0.35, times=3):
    y = x.copy()
    for k in range(1, times + 1):
        d = int(SR * delay * k)
        if d >= len(x):
            break
        y[d:] += x[:-d] * (decay ** k)
    return y


def reverb(x, amount=0.25):
    y = x.copy()
    for d, g in ((0.029, 0.6), (0.047, 0.45), (0.071, 0.35), (0.113, 0.25)):
        n = int(SR * d)
        if n < len(x):
            y[n:] += x[:-n] * g * amount
    return y


def tremolo(x, rate, depth=0.5):
    # زمان را از طول خودِ آرایه می‌سازیم، نه از dur، تا گرد شدن اعشار طول را یکی کم نکند
    ticks = np.arange(len(x)) / SR
    return x * (1 - depth + depth * (0.5 + 0.5 * np.sin(2 * np.pi * rate * ticks)))


# ── ترکیب ──────────────────────────────────────────────────────────────

def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def seq(*parts):
    return np.concatenate(parts)


def at(base, piece, start):
    """قطعه را از ثانیه‌ی start روی پایه سوار می‌کند."""
    i = int(SR * start)
    if i >= len(base):
        return base
    n = min(len(piece), len(base) - i)
    base[i:i + n] += piece[:n]
    return base


def normalize(x, peak=0.89):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 1e-9 else x


def finish(x, ms=15, peak=0.89):
    """آخرین پاس روی هر صدا: محو لبه‌ها، نرمال‌سازی، بریدن سرریز."""
    return np.clip(normalize(fade(x, ms), peak), -1.0, 1.0)
