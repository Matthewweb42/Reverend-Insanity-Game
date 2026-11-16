"""Generate game assets from properly licensed sources (no AI images).

  * Icons: game-icons.net set (CC BY 3.0) via the @iconify-json/game-icons npm package,
    rendered white-on-transparent so the game can tint them by path colour.
  * Fonts: OFL fonts from @fontsource npm packages, subset where large.
  * Audio: synthesised here from scratch (Karplus-Strong plucked strings, drums, gongs)
    and encoded to Ogg Vorbis with ffmpeg. Original work, CC0.

Usage:
  npm pack @iconify-json/game-icons @fontsource/cinzel @fontsource/noto-serif \
      @fontsource/noto-sans-symbols @fontsource/noto-sans-symbols-2 @fontsource/noto-emoji  (into a download dir)
  python3 tools/gen_assets.py --dl <download dir>
Requires: pip install cairosvg fonttools brotli numpy ; ffmpeg on PATH.
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GAME = os.path.join(ROOT, "game")
ICON_DIR = os.path.join(GAME, "assets", "icons")
FONT_DIR = os.path.join(GAME, "assets", "fonts")
AUDIO_DIR = os.path.join(GAME, "assets", "audio")

UI_ICONS = [
    "coins", "heart-plus", "water-drop", "pause-button", "play-button", "fast-forward-button", "lotus", "card-pick",
    "shop", "anvil", "castle", "conversation", "archery-target", "scroll-unfurled", "save", "cog", "footprint",
    "crossed-swords", "shield", "biceps", "broken-bone", "skull-crossed-bones", "lightning-storm", "island", "yin-yang",
    "crystal-growth", "open-book", "hand-bandage", "hourglass", "laurel-crown", "scales", "treasure-map", "padlock",
    "magnifying-glass", "meditation", "sword-clash", "run", "backpack", "chest", "trophy-cup", "exit-door", "house",
    "sun", "moon", "sunrise", "cancel", "check-mark", "info", "star-formation", "family-tree", "tied-scroll", "dice-six-faces-five",
    "fire-dash", "closed-doors", "village", "eye-target", "dragon-spiral", "heart-tower", "wheat", "beehive",
    "cauldron", "graveyard", "circle", "flower-twirl", "pine-tree", "sands-of-time", "gems", "spell-book", "wizard-face",
    "eagle-emblem", "stone-tower", "watchtower", "pagoda", "temple-gate", "warlock-eye", "sprout", "fox-head",
]


def find_pkg(dl, prefix):
    hits = sorted(glob.glob(os.path.join(dl, prefix + "*.tgz")))
    if not hits:
        sys.exit("missing package %s in %s (npm pack it first)" % (prefix, dl))
    return hits[-1]


def extract(tgz, tmp):
    d = os.path.join(tmp, os.path.basename(tgz)[:-4])
    os.makedirs(d, exist_ok=True)
    with tarfile.open(tgz) as t:
        t.extractall(d, filter="data")
    return os.path.join(d, "package")


# ------------------------------------------------------------------ icons ---
def render_icons(pkg):
    import cairosvg
    data = json.load(open(os.path.join(pkg, "icons.json")))
    icons = data["icons"]
    aliases = data.get("aliases", {})
    w = data.get("width", 512)
    h = data.get("height", 512)
    wanted = set(UI_ICONS)
    used = os.path.join(ROOT, "tools", "content", "icons_used.txt")
    if os.path.exists(used):
        wanted |= set(x.strip() for x in open(used) if x.strip())
    os.makedirs(ICON_DIR, exist_ok=True)
    missing = []
    for name in sorted(wanted):
        src = name
        if src not in icons and src in aliases:
            src = aliases[src]["parent"]
        if src not in icons:
            missing.append(name)
            continue
        body = icons[src]["body"]
        # Game-icons ship a black square background path + white glyph in some variants; the
        # iconify set uses currentColor. Force white so the engine can modulate colour.
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="128" height="128" '
               'style="color:#ffffff" fill="#ffffff">%s</svg>') % (w, h, body.replace("currentColor", "#ffffff"))
        cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(ICON_DIR, name + ".png"),
                         output_width=128, output_height=128)
    # application icon: lotus on ink disc
    lotus = icons["lotus"]["body"].replace("currentColor", "#f1d27a")
    app = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="256" height="256">'
           '<circle cx="256" cy="256" r="250" fill="#1b1612" stroke="#c9a24a" stroke-width="12"/>'
           '<g transform="translate(76 76) scale(0.7)" fill="#f1d27a">%s</g></svg>') % lotus
    cairosvg.svg2png(bytestring=app.encode(), write_to=os.path.join(ICON_DIR, "app_icon.png"), output_width=256, output_height=256)
    print("icons: %d rendered, missing: %s" % (len(wanted) - len(missing), ", ".join(missing) or "none"))
    return missing


# ------------------------------------------------------------------ fonts ---
def copy_fonts(dl, tmp):
    from fontTools import subset
    os.makedirs(FONT_DIR, exist_ok=True)
    plan = [
        ("@fontsource/cinzel", "fontsource-cinzel", ["cinzel-latin-400-normal.woff2", "cinzel-latin-700-normal.woff2"]),
        ("@fontsource/noto-serif", "fontsource-noto-serif", ["noto-serif-latin-400-normal.woff2", "noto-serif-latin-700-normal.woff2",
                                                             "noto-serif-latin-400-italic.woff2"]),
        ("@fontsource/noto-sans-symbols", "fontsource-noto-sans-symbols-5", ["noto-sans-symbols-symbols-400-normal.woff2"]),
        ("@fontsource/noto-sans-symbols-2", "fontsource-noto-sans-symbols-2", ["noto-sans-symbols-2-symbols-400-normal.woff2",
                                                                               "noto-sans-symbols-2-math-400-normal.woff2"]),
    ]
    for _, prefix, files in plan:
        pkg = extract(find_pkg(dl, prefix), tmp)
        for f in files:
            shutil.copy(os.path.join(pkg, "files", f), os.path.join(FONT_DIR, f))
        lic = os.path.join(pkg, "LICENSE")
        if os.path.exists(lic):
            shutil.copy(lic, os.path.join(FONT_DIR, prefix.replace("fontsource-", "") + "-LICENSE.txt"))
    # Noto Emoji (monochrome, OFL) only for U+270A raised fist; subset it hard.
    pkg = extract(find_pkg(dl, "fontsource-noto-emoji"), tmp)
    src = os.path.join(pkg, "files", "noto-emoji-emoji-400-normal.woff2")
    outp = os.path.join(FONT_DIR, "noto-emoji-fist.woff2")
    subset.main([src, "--unicodes=U+270A,U+2668,U+25CB", "--flavor=woff2", "--output-file=" + outp])
    shutil.copy(os.path.join(pkg, "LICENSE"), os.path.join(FONT_DIR, "noto-emoji-LICENSE.txt"))
    print("fonts copied")


# ------------------------------------------------------------------ audio ---
SR = 22050
PENTA = [0, 2, 4, 7, 9]  # major pentatonic (gong scale)


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def pluck(freq, dur, decay=0.996, bright=0.5, rng=None):
    rng = rng or np.random.default_rng(1)
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, period) * bright + (1 - bright) * np.sin(np.linspace(0, 2 * np.pi, period))
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % period]
        nxt = buf[(i + 1) % period]
        buf[i % period] = decay * 0.5 * (buf[i % period] + nxt)
    env = np.minimum(1.0, np.linspace(0, 60, n))
    return out * env


def gong(freq, dur, rng=None):
    t = np.linspace(0, dur, int(SR * dur), False)
    partials = [1, 1.47, 2.09, 2.56, 3.21, 4.12]
    s = sum(np.sin(2 * np.pi * freq * p * t + p) * (0.9 ** i) * np.exp(-t * (0.6 + i * 0.5)) for i, p in enumerate(partials))
    wobble = 1 + 0.003 * np.sin(2 * np.pi * 3 * t)
    return s * wobble * np.minimum(1, t * 80)


def drum(dur=0.5, freq=70, noise=0.3, rng=None):
    rng = rng or np.random.default_rng(2)
    t = np.linspace(0, dur, int(SR * dur), False)
    f = freq * (1 + 1.5 * np.exp(-t * 30))
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
    nz = rng.uniform(-1, 1, len(t)) * np.exp(-t * 40) * noise
    return body + nz


def noise_burst(dur, lp=0.2, decay=10, rng=None):
    rng = rng or np.random.default_rng(3)
    n = int(SR * dur)
    x = rng.uniform(-1, 1, n)
    y = np.zeros(n)
    a = lp
    for i in range(1, n):
        y[i] = y[i - 1] + a * (x[i] - y[i - 1])
    t = np.linspace(0, dur, n, False)
    return y * np.exp(-t * decay)


def drone(freq, dur):
    t = np.linspace(0, dur, int(SR * dur), False)
    s = 0.5 * np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 1.5 * t) + 0.15 * np.sin(2 * np.pi * freq * 2.01 * t)
    lfo = 0.75 + 0.25 * np.sin(2 * np.pi * 0.08 * t)
    return s * lfo


def mix(dst, src, at, gain=1.0):
    i = int(at * SR)
    j = min(len(dst), i + len(src))
    if i < len(dst):
        dst[i:j] += src[: j - i] * gain


def reverb(x, amt=0.25):
    out = x.copy()
    for d, g in ((0.031, 0.5), (0.047, 0.4), (0.071, 0.33), (0.113, 0.25), (0.173, 0.18), (0.29, 0.12)):
        k = int(d * SR)
        out[k:] += x[:-k] * g * amt * 2
    return out


def S(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def normalise(x, peak=0.85):
    m = np.max(np.abs(x)) or 1
    return x / m * peak


def melody(rng, bars, base, beat, density=0.6, octaves=2):
    notes = []
    t = 0.0
    deg = 0
    while t < bars * 4 * beat:
        if rng.random() < density:
            deg = int(np.clip(deg + rng.integers(-2, 3), 0, len(PENTA) * octaves - 1))
            m = base + 12 * (deg // len(PENTA)) + PENTA[deg % len(PENTA)]
            notes.append((t, m))
        t += beat * (2 if rng.random() < 0.3 else 1)
    return notes


def song(seed, dur, base, beat, drums=False, drone_note=None, density=0.55, dark=False):
    rng = np.random.default_rng(seed)
    out = np.zeros(int(SR * dur))
    if drone_note:
        out += drone(midi_hz(drone_note), dur) * 0.18
    for t, m in melody(rng, int(dur / (4 * beat)), base, beat, density):
        if t > dur - 2:
            break
        mix(out, pluck(midi_hz(m), 2.2, decay=0.997, bright=0.35 if dark else 0.5, rng=rng), t, 0.5)
        if rng.random() < 0.25:
            mix(out, pluck(midi_hz(m + 12), 1.2, decay=0.995, rng=rng), t + beat / 2, 0.22)
    if drums:
        k = 0
        t = 0.0
        while t < dur - 1:
            mix(out, drum(0.45, 60 if k % 4 == 0 else 85, 0.25 if k % 2 else 0.4, rng), t, 0.55 if k % 4 == 0 else 0.35)
            t += beat
            k += 1
    # gentle loop crossfade: fade the last second into the first
    fade = int(SR * 1.0)
    out[:fade] = out[:fade] * np.linspace(0, 1, fade) + out[-fade:] * np.linspace(1, 0, fade)
    out = out[:-fade]
    return normalise(reverb(out, 0.3), 0.7)


def write_ogg(name, x):
    os.makedirs(AUDIO_DIR, exist_ok=True)
    wav = os.path.join(tempfile.gettempdir(), name + ".wav")
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dst = os.path.join(AUDIO_DIR, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", dst], check=True)
    os.remove(wav)


def make_audio():
    write_ogg("music_menu", song(11, 48, 57, 0.75, drone_note=45, density=0.45))
    write_ogg("music_world", song(23, 56, 60, 0.6, drone_note=48, density=0.5))
    write_ogg("music_combat", song(37, 40, 57, 0.32, drums=True, drone_note=45, density=0.7, dark=True))
    trib = song(41, 40, 52, 0.4, drums=True, drone_note=40, density=0.5, dark=True)
    rng = np.random.default_rng(5)
    for t in (2, 9, 17, 26, 33):
        mix(trib, noise_burst(3.0, 0.05, 1.5, rng), t, 0.9)
    write_ogg("music_tribulation", normalise(trib, 0.75))
    write_ogg("music_immortal", song(53, 56, 62, 0.7, drone_note=50, density=0.4))
    # sfx
    rng = np.random.default_rng(7)
    write_ogg("sfx_click", normalise(pluck(midi_hz(84), 0.12, 0.99, rng=rng), 0.5))
    write_ogg("sfx_card", normalise(S(noise_burst(0.25, 0.35, 18, rng), 0.4 * pluck(midi_hz(76), 0.25, rng=rng)), 0.6))
    write_ogg("sfx_hit", normalise(drum(0.35, 90, 0.9, rng), 0.8))
    write_ogg("sfx_hit_heavy", normalise(S(drum(0.6, 55, 1.0, rng), noise_burst(0.5, 0.1, 6, rng)), 0.9))
    write_ogg("sfx_shield", normalise(gong(midi_hz(88), 0.6), 0.5))
    write_ogg("sfx_heal", normalise(S(*(np.pad(pluck(midi_hz(72 + p), 0.8, rng=rng), (int(i * 0.07 * SR), 0))[: int(SR * 1.0)]
                                        for i, p in enumerate([0, 4, 7, 12]))), 0.6))
    write_ogg("sfx_poison", normalise(noise_burst(0.5, 0.05, 5, rng) * np.sin(np.linspace(0, 60, int(SR * 0.5))), 0.6))
    write_ogg("sfx_buff", normalise(pluck(midi_hz(67), 0.5, rng=rng) + pluck(midi_hz(74), 0.5, rng=rng), 0.6))
    write_ogg("sfx_coin", normalise(S(*(np.pad(gong(midi_hz(96 + p), 0.25), (int(i * 0.05 * SR), 0))[: int(SR * 0.4)] for i, p in enumerate([0, 5]))), 0.5))
    write_ogg("sfx_gong", normalise(gong(midi_hz(45), 4.0), 0.85))
    write_ogg("sfx_fail", normalise(S(gong(midi_hz(40), 2.0) * 0.7, noise_burst(1.0, 0.03, 3, rng)), 0.7))
    write_ogg("sfx_page", normalise(noise_burst(0.2, 0.5, 25, rng), 0.4))
    write_ogg("sfx_summon", normalise(S(drone(midi_hz(43), 0.9) * np.exp(-np.linspace(0, 3, int(SR * 0.9))), drum(0.9, 50, 0.3, rng)), 0.7))
    write_ogg("sfx_killer", normalise(S(gong(midi_hz(38), 2.5), drum(1.0, 45, 1.0, rng), noise_burst(1.5, 0.08, 3, rng)), 0.95))
    write_ogg("sfx_thunder", normalise(S(noise_burst(2.5, 0.04, 1.8, rng), drum(1.5, 35, 0.6, rng)), 0.95))
    write_ogg("sfx_victory", normalise(S(*(np.pad(pluck(midi_hz(60 + p), 1.6, rng=rng), (int(i * 0.18 * SR), 0))[: int(SR * 2.4)]
                                           for i, p in enumerate([0, 4, 7, 12, 16]))), 0.7))
    write_ogg("sfx_defeat", normalise(S(*(np.pad(pluck(midi_hz(57 - p), 1.6, 0.995, 0.3, rng=rng), (int(i * 0.25 * SR), 0))[: int(SR * 2.4)]
                                          for i, p in enumerate([0, 3, 7, 12]))), 0.7))
    print("audio written")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dl", default=os.path.join(ROOT, "..", "assets_dl"))
    ap.add_argument("--skip-audio", action="store_true")
    a = ap.parse_args()
    tmp = tempfile.mkdtemp()
    pkg = extract(find_pkg(a.dl, "iconify-json-game-icons"), tmp)
    render_icons(pkg)
    copy_fonts(a.dl, tmp)
    if not a.skip_audio:
        make_audio()
    shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
