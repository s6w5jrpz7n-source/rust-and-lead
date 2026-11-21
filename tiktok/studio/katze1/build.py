#!/usr/bin/env python3
"""Audio + Timeline: leise Spannung, Klirren beim Schubsen, Fall, Scherben, Schnurren. Länge ~9,6 s (Schleife)."""
import json, os, subprocess
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'build', 'katze1'); os.makedirs(OUT, exist_ok=True)
SR, FPS = 44100, 30
EV = dict(look=1.2, paw=2.0, n1=2.7, n2=3.8, flick=4.7, n3=5.5, fall=6.0, crash=6.75, back=7.2, blink=7.9, end=9.6)


def tt(d): return np.arange(int(d * SR)) / SR
def noise(d, s=0): return np.random.default_rng(s).standard_normal(int(d * SR))


def clink(f=2600):
    t = tt(0.5)
    return 0.22 * sum(a * np.sin(2 * np.pi * f * k * t) * np.exp(-t * (14 + 6 * k)) for k, a in [(1, 1), (1.53, 0.5), (2.7, 0.3)])


def main():
    total = EV['end']; n = int(total * SR); y = np.zeros(n + SR)
    def add(s, t0):
        a = int(t0 * SR); y[a:a + len(s)] += s[:len(y) - a]
    t = tt(EV['crash'])  # Spannung: tiefer Ton, langsam lauter
    pad = (np.sin(2 * np.pi * 55 * t) + 0.6 * np.sin(2 * np.pi * 82.4 * t) + 0.3 * np.sin(2 * np.pi * 110 * t * (1 + 0.002 * np.sin(2 * np.pi * 0.5 * t))))
    add(0.05 * pad * np.minimum(1, t / 2) * (0.6 + 0.4 * t / EV['crash']), 0)
    for k, f in [('n1', 2600), ('n2', 2750), ('n3', 2500)]: add(clink(f), EV[k])
    tf = tt(0.75); add(0.18 * noise(0.75, 3) * np.sin(np.pi * tf / 0.75) ** 2 * (tf / 0.75), EV['fall'])
    tc = tt(1.2)
    crash = 0.9 * noise(1.2, 5) * np.exp(-tc * 9) + 0.6 * np.sin(2 * np.pi * 60 * tc) * np.exp(-tc * 14)
    for i in range(10):
        a = int(i * 0.035 * SR); f = 2500 + 3000 * np.random.default_rng(i).random(); tt2 = tc[:len(tc) - a]
        crash[a:] += 0.2 * np.sin(2 * np.pi * f * tt2) * np.exp(-tt2 * 18)
    add(crash, EV['crash'])
    tp = tt(EV['end'] - EV['back'])
    purr = noise(EV['end'] - EV['back'], 9) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 25 * tp)))
    purr = np.convolve(purr, np.ones(60) / 60, 'same') * 0.6 * np.minimum(1, tp / 0.6) * np.minimum(1, (tp[-1] - tp) / 0.4)
    add(purr, EV['back'])
    mix = y[:n]; mix = np.tanh(mix / (np.abs(mix).max() + 1e-6) * 1.2) / np.tanh(1.2) * 0.95
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', 'pipe:0',
                    '-af', 'loudnorm=I=-16:TP=-1.0:LRA=11', '-ar', str(SR), '-ac', '2', os.path.join(OUT, 'audio.wav')],
                   input=mix.astype(np.float32).tobytes(), check=True)
    tl = dict(fps=FPS, duration=total, lines=[], cues=EV, scenes={}, sceneOrder=[], mouth=[], data=dict(ev=EV))
    open(os.path.join(OUT, 'timeline.js'), 'w').write('window.TL = ' + json.dumps(tl) + ';\n')
    json.dump(tl, open(os.path.join(OUT, 'timeline.json'), 'w'), indent=1)
    print('ok', total)


if __name__ == '__main__':
    main()
