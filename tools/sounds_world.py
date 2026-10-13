# -*- coding: utf-8 -*-
"""صداهای خانه، طبیعت، موسیقی، حرفه‌ها و فضا."""
import numpy as np
from synth import (SR, sine, saw, square, noise, glide, ramp, perc, fade, adsr,
                   env_shape, lowpass, highpass, bandpass, resonate, formants,
                   echo, reverb, tremolo, mix, seq, at, silence, finish, t)


# ── وسایل خانه ────────────────────────────────────────────────────────

def doorbell():
    """دینگ‌دانگ: دو نت زنگوله‌ای."""
    def chime(f, d=1.0):
        x = (sine(f, d) + 0.5 * sine(f * 2.76, d) + 0.25 * sine(f * 5.4, d))
        return env_shape(x, [(0, 0), (0.01, 1.0), (1, 0)]) * np.exp(-3.2 * np.linspace(0, 1, int(SR * d)))
    return finish(reverb(seq(chime(660), chime(523) * 0.95), 0.3))


def clock():
    """تیک‌تاک: چهار ضربه‌ی خشک."""
    out = silence(3.3)
    for i in range(4):
        click = highpass(noise(0.03), 2200)
        click = env_shape(click, [(0, 1.0), (0.12, 0.35), (1, 0)])
        body = sine(1400 if i % 2 == 0 else 1150, 0.03)
        body = env_shape(body, [(0, 1.0), (1, 0)]) * 0.5
        out = at(out, (click + body) * 0.9, 0.2 + i * 0.75)
    return finish(out)


def phone():
    """زنگ تلفن قدیمی: دو دوره‌ی لرزان."""
    def ring(d=1.0):
        warble = (square(np.full(int(SR * d), 20.0), d, 0.5) + 1) / 2
        tone = sine(1000, d) * warble + sine(800, d) * (1 - warble)
        return env_shape(tone, [(0, 0), (0.02, 1.0), (0.97, 1.0), (1, 0)]) * 0.75
    return finish(seq(ring(), silence(0.45), ring()))


def vacuum():
    """جاروبرقی: موتور + جریان هوا، با بالا آمدن و پایین رفتن دور."""
    d = 2.6
    rpm = np.concatenate([ramp(60, 185, 0.5, 0.6), np.full(int(SR * 1.5), 185.0),
                          ramp(185, 70, d - 2.0, 1.3)])
    motor = saw(rpm, d) * 0.5 + saw(rpm * 2.01, d) * 0.2
    motor = lowpass(motor, 1400)
    air = bandpass(noise(d), 600, 5200) * 0.45
    x = mix(motor, air)
    return finish(env_shape(x, [(0, 0), (0.08, 1.0), (0.85, 0.9), (1, 0)]))


def kettle():
    """کتری: سوتِ نازک که کم‌کم بلند می‌شود، روی جوشِ آب."""
    d = 2.8
    whistle = sine(glide(2050, 2250, d, 0.4), d) * 0.55 + sine(glide(4100, 4500, d, 0.4), d) * 0.18
    whistle = env_shape(whistle, [(0, 0), (0.35, 0.3), (0.7, 1.0), (0.95, 1.0), (1, 0)])
    boil = bandpass(noise(d), 300, 2600) * 0.3
    boil = tremolo(boil, 9, 0.5)
    return finish(mix(whistle, boil))


def washer():
    """ماشین لباسشویی: چرخش آهسته با آب."""
    d = 3.0
    drum = saw(np.full(int(SR * d), 52.0), d) * 0.4
    drum = lowpass(drum, 420)
    drum = tremolo(drum, 1.5, 0.6)
    water = bandpass(noise(d), 200, 1800) * 0.3
    water = tremolo(water, 1.5, 0.45)
    return finish(env_shape(mix(drum, water), [(0, 0), (0.06, 1.0), (0.92, 1.0), (1, 0)]))


def tap():
    """شیر آب: جریان پیوسته با پاشش."""
    d = 2.4
    stream = bandpass(noise(d), 500, 7000) * 0.55
    splash = bandpass(noise(d), 1500, 9000) * 0.25
    splash = tremolo(splash, 17, 0.6)
    low = lowpass(noise(d), 350) * 0.2
    return finish(env_shape(mix(stream, splash, low), [(0, 0), (0.07, 1.0), (0.9, 1.0), (1, 0)]))


def door():
    """در: جیرجیر لولا و بعد بسته شدن."""
    d = 1.3
    creak = saw(glide(240, 150, d * 0.75, 1.2), d * 0.75) * 0.3
    creak = formants(creak, [600, 1500], [1.0, 0.5], q=20)
    creak = env_shape(creak, [(0, 0), (0.1, 0.8), (0.6, 1.0), (1, 0)])
    creak = tremolo(creak, 11, 0.5)
    thud = lowpass(noise(0.22), 300) * 1.0
    thud = env_shape(thud, [(0, 1.0), (0.15, 0.5), (1, 0)])
    knock = sine(110, 0.22) * 0.6
    knock = env_shape(knock, [(0, 1.0), (1, 0)])
    return finish(seq(creak, mix(thud, knock)))


# ── طبیعت ─────────────────────────────────────────────────────────────

def rain():
    d = 4.0
    sheet = bandpass(noise(d), 700, 9000) * 0.42
    out = sheet.copy()
    for _ in range(140):                       # قطره‌های جدا روی پرده‌ی باران
        pos = float(np.random.uniform(0, d - 0.05))
        drop = highpass(noise(0.025), 3000)
        drop = env_shape(drop, [(0, 1.0), (0.2, 0.3), (1, 0)]) * np.random.uniform(0.1, 0.35)
        out = at(out, drop, pos)
    return finish(env_shape(out, [(0, 0), (0.05, 1.0), (0.93, 1.0), (1, 0)]))


def thunder():
    d = 3.4
    crack = highpass(noise(0.12), 2000) * 1.0
    crack = env_shape(crack, [(0, 1.0), (0.1, 0.4), (1, 0)])
    boom = lowpass(noise(d), 180) * 0.9
    boom = env_shape(boom, [(0, 0.2), (0.06, 1.0), (0.3, 0.7), (0.6, 0.45), (1, 0)])
    rumble = lowpass(noise(d), 70) * 0.6
    rumble = env_shape(rumble, [(0, 0.1), (0.2, 1.0), (1, 0)])
    out = mix(boom, rumble)
    out = at(out, crack, 0.0)
    return finish(reverb(out, 0.5))


def wind():
    d = 4.0
    base = lowpass(noise(d), 900) * 0.55
    gust = lowpass(noise(d), 4) * 6.0                  # پوشِ آهسته‌ی وزش
    gust = np.clip(0.45 + gust, 0.15, 1.0)
    whistle = sine(glide(520, 700, d, 0.5), d) * 0.08
    return finish(env_shape(base * gust + whistle, [(0, 0), (0.08, 1.0), (0.9, 1.0), (1, 0)]))


def sea():
    d = 4.5
    out = silence(d)
    for i, pos in enumerate(np.arange(0.1, d - 1.3, 1.45)):
        w = 1.3
        body = bandpass(noise(w), 200, 5000)
        body = env_shape(body, [(0, 0), (0.3, 1.0), (0.5, 0.75), (1, 0)]) * 0.6
        foam = highpass(noise(w), 4000)
        foam = env_shape(foam, [(0, 0), (0.42, 1.0), (1, 0)]) * 0.22
        out = at(out, body + foam, float(pos))
    return finish(env_shape(out, [(0, 0), (0.05, 1.0), (0.93, 1.0), (1, 0)]))


def river():
    d = 4.0
    flow = bandpass(noise(d), 400, 6000) * 0.45
    burble = bandpass(noise(d), 900, 3000) * 0.25
    burble = tremolo(burble, 6.5, 0.55)
    return finish(env_shape(mix(flow, burble), [(0, 0), (0.06, 1.0), (0.93, 1.0), (1, 0)]))


def fire():
    d = 4.0
    hiss = bandpass(noise(d), 300, 4000) * 0.3
    out = hiss.copy()
    for _ in range(45):                         # تِرَق‌تِرَقِ چوب
        pos = float(np.random.uniform(0, d - 0.08))
        crack = highpass(noise(0.045), 1800)
        crack = env_shape(crack, [(0, 1.0), (0.1, 0.3), (1, 0)]) * np.random.uniform(0.2, 0.75)
        out = at(out, crack, pos)
    return finish(env_shape(out, [(0, 0), (0.05, 1.0), (0.93, 1.0), (1, 0)]))


def waterfall():
    d = 4.0
    roar = lowpass(noise(d), 1800) * 0.5
    spray = bandpass(noise(d), 2000, 11000) * 0.35
    deep = lowpass(noise(d), 180) * 0.3
    return finish(env_shape(mix(roar, spray, deep), [(0, 0), (0.06, 1.0), (0.93, 1.0), (1, 0)]))


# ── موسیقی ────────────────────────────────────────────────────────────

def _pluck(freq, dur, bright=0.5):
    """سیم زخمه‌ای به روش کارپلاس–استرانگ."""
    n = int(SR * dur)
    plen = max(2, int(SR / freq))
    buf = np.random.uniform(-1, 1, plen)
    out = np.empty(n)
    for i in range(n):
        out[i] = buf[i % plen]
        nxt = (i + 1) % plen
        buf[i % plen] = (buf[i % plen] + buf[nxt]) * 0.5 * (0.993 + 0.005 * bright)
    return out


def drum():
    out = silence(2.0)
    for i, pos in enumerate((0.05, 0.45, 0.85, 1.25)):
        d = 0.6
        head = sine(glide(170, 62, d, 0.35), d) * 0.9
        head = env_shape(head, [(0, 1.0), (0.15, 0.5), (1, 0)])
        slap = highpass(noise(0.05), 1200) * 0.4
        slap = env_shape(slap, [(0, 1.0), (1, 0)])
        out = at(out, head * (1.0 if i % 2 == 0 else 0.7), pos)
        out = at(out, slap, pos)
    return finish(reverb(out, 0.2))


def piano():
    out = silence(2.6)
    for pos, f in ((0.05, 261.63), (0.45, 329.63), (0.85, 392.00), (1.25, 523.25)):
        d = 1.3
        x = np.zeros(int(SR * d))
        for k, g in ((1, 1.0), (2, 0.42), (3, 0.22), (4, 0.12), (5, 0.07)):
            x += sine(f * k * (1 + 0.0007 * k * k), d) * g     # کشیدگیِ سیم پیانو
        x *= np.exp(-2.6 * np.linspace(0, 1, len(x)))
        hammer = highpass(noise(0.012), 2500) * 0.25
        out = at(out, env_shape(x, [(0, 0), (0.004, 1.0), (1, 0)]) * 0.55, pos)
        out = at(out, hammer, pos)
    return finish(reverb(out, 0.25))


def guitar():
    out = silence(2.6)
    for pos, f in ((0.05, 196.00), (0.4, 246.94), (0.75, 293.66), (1.1, 392.00)):
        x = _pluck(f, 1.4, bright=0.7) * 0.55
        x = env_shape(x, [(0, 0), (0.005, 1.0), (1, 0)])
        out = at(out, x, pos)
    return finish(reverb(out, 0.22))


def violin():
    d = 2.4
    f = np.concatenate([np.full(int(SR * 0.9), 440.0), glide(440, 523.25, 0.2),
                        np.full(int(SR * 1.3), 523.25)])
    f = f[:int(SR * d)] * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * t(d)))   # ویبراتو
    x = saw(f, d) * 0.5
    x = formants(x, [450, 1100, 2400, 3400], [1.0, 0.6, 0.35, 0.2], q=7)
    bow = highpass(noise(d), 4000) * 0.05
    x = env_shape(mix(x, bow), [(0, 0), (0.12, 1.0), (0.88, 0.95), (1, 0)])
    return finish(reverb(x, 0.3))


def flute():
    out = silence(2.6)
    for pos, f in ((0.05, 523.25), (0.6, 587.33), (1.15, 659.25)):
        d = 0.75
        tone = sine(f * (1 + 0.006 * np.sin(2 * np.pi * 5 * t(d))), d) * 0.65
        tone += sine(f * 2, d) * 0.08
        breath = bandpass(noise(d), 2000, 8000) * 0.1
        x = env_shape(mix(tone, breath), [(0, 0), (0.12, 1.0), (0.8, 0.9), (1, 0)])
        out = at(out, x, pos)
    return finish(reverb(out, 0.3))


def bell():
    out = silence(2.6)
    for pos in (0.05, 0.42, 0.79):
        d = 1.6
        f = 1180.0
        x = np.zeros(int(SR * d))
        for r, g in ((1.0, 1.0), (2.76, 0.6), (5.4, 0.35), (8.9, 0.18)):
            x += sine(f * r, d) * g * np.exp(-np.linspace(0, 1, int(SR * d)) * (2.5 + r * 0.6))
        out = at(out, env_shape(x, [(0, 0), (0.003, 1.0), (1, 0)]) * 0.42, pos)
    return finish(reverb(out, 0.35))


def tambourine():
    out = silence(2.0)
    for i, pos in enumerate((0.05, 0.42, 0.79, 1.16)):
        skin = sine(glide(240, 150, 0.2, 0.4), 0.2) * 0.4
        skin = env_shape(skin, [(0, 1.0), (1, 0)])
        jingle = highpass(noise(0.45), 5000) * 0.5
        jingle = env_shape(jingle, [(0, 1.0), (0.1, 0.5), (0.4, 0.2), (1, 0)])
        out = at(out, mix(skin, jingle) * (1.0 if i % 2 == 0 else 0.7), pos)
    return finish(reverb(out, 0.25))


# ── حرفه‌ها ───────────────────────────────────────────────────────────

def hammer():
    out = silence(2.4)
    for pos in (0.1, 0.65, 1.2, 1.7):
        hit = lowpass(noise(0.08), 900) * 0.8
        hit = env_shape(hit, [(0, 1.0), (0.1, 0.3), (1, 0)])
        ring = sine(2300, 0.25) * 0.2 + sine(3100, 0.25) * 0.1
        ring = env_shape(ring, [(0, 1.0), (1, 0)])
        wood = sine(glide(180, 90, 0.1), 0.1) * 0.5
        wood = env_shape(wood, [(0, 1.0), (1, 0)])
        out = at(out, mix(hit, ring, wood), pos)
    return finish(reverb(out, 0.3))


def hand_saw():
    out = silence(3.2)
    for i, pos in enumerate(np.arange(0.1, 2.9, 0.7)):
        d = 0.5
        rasp = bandpass(noise(d), 800, 6000)
        rasp = tremolo(rasp, 26, 0.6)
        rasp = env_shape(rasp, [(0, 0), (0.2, 1.0), (0.7, 0.8), (1, 0)]) * 0.6
        out = at(out, rasp * (1.0 if i % 2 == 0 else 0.75), float(pos))
    return finish(out)


def _siren(f_lo, f_hi, rate, d, wave="sine", harsh=0.0):
    sweep = f_lo + (f_hi - f_lo) * (0.5 + 0.5 * np.sin(2 * np.pi * rate * t(d)))
    x = sine(sweep, d) * 0.6
    if harsh:
        x += square(sweep, d, 0.5) * harsh
    x += sine(sweep * 2, d) * 0.15
    return env_shape(x, [(0, 0), (0.05, 1.0), (0.95, 1.0), (1, 0)])


def ambulance():
    return finish(reverb(_siren(650, 980, 1.6, 3.2, harsh=0.12), 0.25))


def firetruck():
    """آژیر آتش‌نشانی: سُرِ آهسته‌تر و بم‌تر، با بوقِ بم زیرش."""
    d = 3.4
    s = _siren(420, 760, 0.8, d, harsh=0.2)
    horn = sine(135, d) * 0.12 + sine(270, d) * 0.06
    horn = tremolo(horn, 0.8, 0.8)
    return finish(reverb(mix(s, horn), 0.3))


def police():
    """آژیر پلیس: تند و دوضربی."""
    d = 3.0
    fast = _siren(780, 1250, 3.2, d, harsh=0.15)
    return finish(reverb(fast, 0.22))


def scissors():
    out = silence(2.0)
    for pos in (0.1, 0.55, 1.0, 1.45):
        snip = highpass(noise(0.07), 3500) * 0.7
        snip = env_shape(snip, [(0, 1.0), (0.15, 0.4), (1, 0)])
        ting = sine(4200, 0.09) * 0.2
        ting = env_shape(ting, [(0, 1.0), (1, 0)])
        out = at(out, mix(snip, ting), pos)
    return finish(out)


def typing():
    out = silence(3.0)
    pos = 0.1
    while pos < 2.85:
        key = highpass(noise(0.018), 1800) * np.random.uniform(0.45, 0.8)
        key = env_shape(key, [(0, 1.0), (0.15, 0.25), (1, 0)])
        body = sine(np.random.uniform(300, 520), 0.02) * 0.25
        body = env_shape(body, [(0, 1.0), (1, 0)])
        out = at(out, mix(key, body), pos)
        pos += float(np.random.uniform(0.09, 0.2))
    return finish(out)


# ── فضا و علم ─────────────────────────────────────────────────────────

def rocket():
    d = 4.0
    thrust = lowpass(noise(d), 500) * 0.7
    thrust = env_shape(thrust, [(0, 0), (0.12, 1.0), (0.6, 0.9), (1, 0.2)])
    crackle = bandpass(noise(d), 1000, 7000) * 0.3
    crackle = env_shape(crackle, [(0, 0), (0.1, 1.0), (1, 0.15)])
    rumble = sine(glide(45, 28, d), d) * 0.45
    whoosh = sine(glide(300, 90, d, 1.6), d) * 0.15
    return finish(mix(thrust, crackle, rumble, whoosh))


def robot():
    """بیپ‌بوپ: چند نت مربعی پلکانی با گلیچ."""
    out = silence(2.2)
    pos = 0.06
    for f, d in ((440, 0.13), (660, 0.1), (330, 0.14), (880, 0.1), (550, 0.16), (220, 0.2)):
        tone = square(np.full(int(SR * d), float(f)), d, 0.45) * 0.4
        tone += square(np.full(int(SR * d), float(f) * 1.5), d, 0.3) * 0.12
        tone = env_shape(tone, [(0, 0), (0.06, 1.0), (0.85, 1.0), (1, 0)])
        out = at(out, tone, pos)
        pos += d + 0.05
    servo = bandpass(noise(2.2), 1500, 4000) * 0.06
    servo = tremolo(servo, 30, 0.7)
    return finish(mix(out, servo))


def spaceship():
    """وِزوِزِ موتور سفینه با پالس‌های آرام."""
    d = 3.6
    drone = saw(np.full(int(SR * d), 88.0), d) * 0.3 + saw(np.full(int(SR * d), 132.0), d) * 0.18
    drone = lowpass(drone, 1200)
    shimmer = sine(glide(1800, 2400, d, 0.5), d) * 0.1
    shimmer = tremolo(shimmer, 4.5, 0.6)
    pulse = sine(np.full(int(SR * d), 55.0), d) * 0.2
    pulse = tremolo(pulse, 2.0, 0.9)
    return finish(reverb(mix(drone, shimmer, pulse), 0.4))


def satellite():
    """بیپ‌های منظم اسپوتنیک‌وار با نویز ایستا."""
    d = 3.2
    static = bandpass(noise(d), 2000, 6000) * 0.08
    out = static.copy()
    pos = 0.15
    while pos < d - 0.3:
        beep = sine(1050, 0.16) * 0.5
        beep = env_shape(beep, [(0, 0), (0.05, 1.0), (0.9, 1.0), (1, 0)])
        out = at(out, beep, pos)
        pos += 0.55
    return finish(reverb(out, 0.35))


def laser():
    out = silence(1.6)
    for i, pos in enumerate((0.05, 0.45, 0.85)):
        d = 0.3
        z = sine(glide(3000, 350, d, 2.2), d) * 0.55
        z += saw(glide(1500, 180, d, 2.2), d) * 0.2
        z = env_shape(z, [(0, 1.0), (0.3, 0.6), (1, 0)])
        out = at(out, z * (1.0 - i * 0.12), pos)
    return finish(reverb(out, 0.25))


# ── صداهای رابط کاربری ───────────────────────────────────────────────

def ui_success():
    out = silence(1.0)
    for pos, f in ((0.0, 523.25), (0.11, 659.25), (0.22, 783.99)):
        x = sine(f, 0.5) * 0.4 + sine(f * 2, 0.5) * 0.12
        x = env_shape(x, [(0, 0), (0.02, 1.0), (1, 0)])
        out = at(out, x, pos)
    return finish(reverb(out, 0.3))


def ui_fail():
    out = silence(0.8)
    for pos, f in ((0.0, 311.13), (0.16, 233.08)):
        x = sine(f, 0.45) * 0.45 + saw(f, 0.45) * 0.1
        x = env_shape(x, [(0, 0), (0.03, 1.0), (1, 0)])
        out = at(out, x, pos)
    return finish(reverb(out, 0.2))


def ui_tap():
    x = sine(1320, 0.07) * 0.5 + sine(1980, 0.07) * 0.15
    return finish(env_shape(x, [(0, 0), (0.05, 1.0), (1, 0)]), ms=5)


WORLD = {
    "home_doorbell": doorbell, "home_clock": clock, "home_phone": phone,
    "home_vacuum": vacuum, "home_kettle": kettle, "home_washer": washer,
    "home_tap": tap, "home_door": door,

    "nature_rain": rain, "nature_thunder": thunder, "nature_wind": wind,
    "nature_sea": sea, "nature_river": river, "nature_fire": fire,
    "nature_waterfall": waterfall,

    "music_drum": drum, "music_piano": piano, "music_guitar": guitar,
    "music_violin": violin, "music_flute": flute, "music_bell": bell,
    "music_tambourine": tambourine,

    "prof_hammer": hammer, "prof_saw": hand_saw, "prof_ambulance": ambulance,
    "prof_firetruck": firetruck, "prof_police": police, "prof_scissors": scissors,
    "prof_typing": typing,

    "sci_rocket": rocket, "sci_robot": robot, "sci_spaceship": spaceship,
    "sci_satellite": satellite, "sci_laser": laser,

    "ui_success": ui_success, "ui_fail": ui_fail, "ui_tap": ui_tap,
}
