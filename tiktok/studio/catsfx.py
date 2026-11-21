"""Synthetische Geräusche + Baukasten für die Katzen-Serie „der drang, …“ (ohne Sprache)."""
import json, os, subprocess
import numpy as np

SR, FPS = 44100, 30


def tt(d): return np.arange(int(d * SR)) / SR
def noise(d, s=0): return np.random.default_rng(s).standard_normal(int(d * SR))


def lowpass(x, k=40): return np.convolve(x, np.ones(k) / k, 'same')


def sfx(kind, d=0.5, f=2600, seed=0):
    t = tt(d)
    if kind == 'clink':
        return 0.22 * sum(a * np.sin(2 * np.pi * f * k * t) * np.exp(-t * (14 + 6 * k)) for k, a in [(1, 1), (1.53, 0.5), (2.7, 0.3)])
    if kind == 'crash':
        y = 0.9 * noise(d, 5 + seed) * np.exp(-t * 9) + 0.6 * np.sin(2 * np.pi * 60 * t) * np.exp(-t * 14)
        for i in range(10):
            a = int(i * 0.035 * SR); ff = 2500 + 3000 * np.random.default_rng(i + seed).random(); t2 = t[:len(t) - a]
            y[a:] += 0.2 * np.sin(2 * np.pi * ff * t2) * np.exp(-t2 * 18)
        return y
    if kind == 'thump':
        return 0.8 * np.sin(2 * np.pi * (55 + 60 * np.exp(-t * 40)) * t) * np.exp(-t * 18) + 0.15 * lowpass(noise(d, seed), 20) * np.exp(-t * 30)
    if kind == 'whoosh':
        return 0.3 * lowpass(noise(d, 3 + seed), 8) * np.sin(np.pi * t / d) ** 2 * 3
    if kind == 'purr':
        p = noise(d, 9) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 25 * t)))
        return lowpass(p, 60) * 0.6 * np.minimum(1, t / 0.6) * np.minimum(1, (d - t) / 0.4)
    if kind == 'meow':  # Cartoon-Miau: Sägezahn mit Tonhöhenbogen, Formant-artig gefiltert
        f0 = 520 + 260 * np.sin(np.pi * np.clip(t / d, 0, 1)) - 180 * (t / d) ** 2
        ph = 2 * np.pi * np.cumsum(f0) / SR
        y = sum(np.sin(k * ph) / k for k in range(1, 9))
        env = np.minimum(1, t / 0.05) * np.minimum(1, (d - t) / 0.12)
        vow = 0.5 + 0.5 * np.sin(np.pi * np.clip(t / d * 1.2, 0, 1))
        return 0.18 * y * env * (0.6 + 0.4 * vow) * (1 + 0.05 * np.sin(2 * np.pi * 6 * t))
    if kind == 'boop':
        return 0.35 * np.sin(2 * np.pi * (700 + 500 * np.exp(-t * 30)) * t) * np.exp(-t * 20)
    if kind == 'key':
        return 0.25 * lowpass(noise(d, seed), 3) * np.exp(-t * 300)
    if kind == 'mash':
        y = np.zeros(len(t))
        for i in range(int(d * 28)):
            a = int(i / 28 * SR + np.random.default_rng(i).random() * 400); c = 0.22 * lowpass(noise(0.03, i), 3) * np.exp(-tt(0.03) * 260)
            y[a:a + len(c)] += c[:len(y) - a]
        return y
    if kind == 'ding':
        return 0.3 * (np.sin(2 * np.pi * 1318 * t) + 0.4 * np.sin(2 * np.pi * 1976 * t)) * np.exp(-t * 5)
    if kind == 'beep':
        return 0.15 * np.sign(np.sin(2 * np.pi * 880 * t)) * (t < 0.18)
    if kind == 'rustle':
        return 0.2 * lowpass(noise(d, 11 + seed), 6) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 7 * t))) * np.sin(np.pi * t / d)
    if kind == 'boing':
        ff = 160 + 240 * np.exp(-t * 5) * (1 + 0.35 * np.sin(2 * np.pi * 14 * t))
        return 0.4 * np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.exp(-t * 5.5) * np.minimum(1, t * 300)
    if kind == 'squeak':
        ff = 900 + 500 * np.sin(np.pi * t / d)
        return 0.15 * np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.sin(np.pi * t / d)
    if kind == 'tick':
        return 0.12 * np.sin(2 * np.pi * 3000 * t) * np.exp(-t * 120)
    if kind == 'bells':  # Anfang von Jingle Bells (gemeinfrei)
        y = np.zeros(len(t)); t0 = 0.0
        for n, b in [(64, 1), (64, 1), (64, 2), (64, 1), (64, 1), (64, 2), (64, 1), (67, 1), (60, 1.5), (62, 0.5), (64, 4)]:
            fr = 440 * 2 ** ((n - 69) / 12); a = int(t0 * SR); t2 = t[:max(0, len(t) - a)]
            if len(t2): y[a:] += 0.18 * sum(c * np.sin(2 * np.pi * fr * k * t2) * np.exp(-t2 * (3 + k)) for k, c in [(1, 1), (2, 0.4), (3, 0.2)])
            t0 += b * 0.22
        return y
    if kind == 'tada':
        y = np.zeros(len(t))
        for i, fr in enumerate([523.25, 659.25, 783.99, 1046.5]):
            a = int(i * 0.08 * SR); t2 = t[:len(t) - a]
            y[a:] += 0.18 * (2 / np.pi) * np.arcsin(np.sin(2 * np.pi * fr * t2)) * np.exp(-t2 * 2.5)
        return y
    if kind == 'pad':
        return 0.05 * (np.sin(2 * np.pi * 55 * t) + 0.6 * np.sin(2 * np.pi * 82.4 * t) + 0.3 * np.sin(2 * np.pi * 110 * t)) * np.minimum(1, t / 1.5) * np.minimum(1, (d - t) / 0.5)
    if kind == 'night':
        return 0.02 * lowpass(noise(d, 21), 80) + 0.03 * np.sin(2 * np.pi * 3000 * t) * (np.sin(2 * np.pi * 1 * t) > 0.995)
    if kind == 'birds':
        y = np.zeros(len(t))
        for i in range(int(d * 1.5)):
            a = int((i / 1.5 + np.random.default_rng(i).random() * 0.3) * SR); t2 = tt(0.12)
            ff = 3500 + 1500 * np.sin(np.pi * t2 / 0.12); c = 0.05 * np.sin(2 * np.pi * np.cumsum(ff) / SR) * np.sin(np.pi * t2 / 0.12)
            y[a:a + len(c)] += c[:len(y) - a]
        return y
    raise ValueError(kind)


def build(ep, ev, events, extra=None):
    """events: Liste (Zeit|Event-Name, Art, Dauer, Lautstärke, kwargs)."""
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', ep); os.makedirs(out, exist_ok=True)
    total = ev['end']; n = int(total * SR); y = np.zeros(n + 4 * SR)
    for e in events:
        at, kind, d, g = e[:4]; kw = e[4] if len(e) > 4 else {}
        t0 = ev[at] if isinstance(at, str) else at
        s = sfx(kind, d, **kw) * g; a = int(t0 * SR); y[a:a + len(s)] += s[:len(y) - a]
    mix = y[:n]; mix = np.tanh(mix / (np.abs(mix).max() + 1e-6) * 1.2) / np.tanh(1.2) * 0.95
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', 'pipe:0',
                    '-af', 'loudnorm=I=-16:TP=-1.0:LRA=11', '-ar', str(SR), '-ac', '2', os.path.join(out, 'audio.wav')],
                   input=mix.astype(np.float32).tobytes(), check=True)
    tl = dict(fps=FPS, duration=total, lines=[], cues=ev, scenes={}, sceneOrder=[], mouth=[], data=dict(ev=ev, **(extra or {})))
    open(os.path.join(out, 'timeline.js'), 'w').write('window.TL = ' + json.dumps(tl, ensure_ascii=False) + ';\n')
    json.dump(tl, open(os.path.join(out, 'timeline.json'), 'w'), ensure_ascii=False, indent=1)
    print(ep, 'ok', total)
