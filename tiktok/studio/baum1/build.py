#!/usr/bin/env python3
"""Baut Audio (Jingle Bells – gemeinfrei – auf Glöckchen, pro Stufe langsamer/tiefer/trauriger) und timeline.js."""
import json, os, subprocess
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'build', 'baum1'); os.makedirs(OUT, exist_ok=True)
SR, FPS = 44100, 30

STAGES = [  # Etikett, Untertitel, Bildtext, Dauer, Tempo, Halbtöne, Moll, Leiern
    ('TAG 1', '1. Advent', 'So frisch. So schön. So viel Hoffnung.', 4.4, 132, 0, False, 0.0),
    ('TAG 12', 'Mitte Dezember', 'Die Katze hat entschieden: Das ist jetzt ihrer.', 3.7, 124, 0, False, 0.003),
    ('HEILIGABEND', '24. Dezember', 'Hält. Gerade so.', 3.5, 114, -1, False, 0.005),
    ('SILVESTER', '31. Dezember', 'Nadeln: 40 %. Lametta: 100 %.', 3.7, 100, -2, True, 0.008),
    ('FEBRUAR', 'Woche 9', '„Den bringen wir nächste Woche raus.“', 3.7, 84, -4, True, 0.012),
    ('OSTERN', 'April', 'Er hat jetzt einen neuen Job.', 4.3, 70, -5, True, 0.018),
]
END = 2.6
MEL = [(64, 1), (64, 1), (64, 2), (64, 1), (64, 1), (64, 2), (64, 1), (67, 1), (60, 1.5), (62, 0.5), (64, 4),
       (65, 1), (65, 1), (65, 1.5), (65, 0.5), (65, 1), (64, 1), (64, 1), (64, 0.5), (64, 0.5), (64, 1), (62, 1), (62, 1),
       (64, 1), (62, 2), (67, 2)]
BASS = [48, 48, 48, 48, 53, 48, 55, 55]


def tt(d):
    return np.arange(int(d * SR)) / SR


def bell(f, d, wob=0.0):
    t = tt(d)
    vib = 1 + wob * np.sin(2 * np.pi * 5.5 * t)
    y = sum(a * np.sin(2 * np.pi * f * k * np.cumsum(vib) / SR) * np.exp(-t * (3 + k)) for k, a in [(1, 1), (2, 0.45), (3, 0.22), (4.2, 0.12)])
    return y * np.minimum(1, t * 400)


def bass(f, d):
    t = tt(d)
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * np.exp(-t * 1.6) * np.minimum(1, t * 200)


def midi(n):
    return 440 * 2 ** ((n - 69) / 12)


def stage_music(d, bpm, semi, minor, wob):
    beat = 60 / bpm
    y = np.zeros(int(d * SR) + SR)
    t0 = 0.0
    for n, b in MEL * 2:
        if t0 >= d:
            break
        if minor and n % 12 == 4:
            n -= 1  # große Terz -> kleine Terz
        s = bell(midi(n + semi), min(2.5, b * beat + 0.8), wob)
        a = int(t0 * SR); y[a:a + len(s)] += 0.32 * s[:len(y) - a]
        t0 += b * beat
    for i in range(int(d / (4 * beat)) + 1):
        s = bass(midi(BASS[i % 8] + semi), 4 * beat)
        a = int(i * 4 * beat * SR); y[a:a + len(s)] += 0.22 * s[:len(y) - a]
        for j in range(4):  # Schlittenglöckchen
            sh = np.random.default_rng(i * 4 + j).standard_normal(int(0.06 * SR)) * np.exp(-tt(0.06) * 60) * 0.05
            a = int((i * 4 + j) * beat * SR); y[a:a + len(sh)] += sh[:len(y) - a]
    return y[:int(d * SR)]


def noise(d, seed=0):
    return np.random.default_rng(seed).standard_normal(int(d * SR))


def sfx(kind, d=0.5):
    t = tt(d)
    if kind == 'whoosh':
        return 0.25 * noise(d, 3) * np.sin(np.pi * t / d) ** 2
    if kind == 'tinkle':
        y = np.zeros(len(t))
        for i in range(6):
            a = int(i * 0.07 * SR); f = 3000 + i * 230; tt2 = t[:len(t) - a]
            y[a:] += 0.05 * np.sin(2 * np.pi * f * tt2) * np.exp(-tt2 * 25)
        return y
    if kind == 'pop':
        return 0.5 * noise(d, 9) * np.exp(-t * 18) + 0.4 * np.sin(2 * np.pi * 70 * t) * np.exp(-t * 12)
    if kind == 'rain':
        return 0.05 * noise(d, 4)
    if kind == 'bird':
        y = np.zeros(len(t))
        for i in range(3):
            a = int(i * 0.18 * SR); tt2 = t[:int(0.12 * SR)]
            f = 3500 + 1500 * np.sin(np.pi * tt2 / 0.12)
            y[a:a + len(tt2)] += 0.08 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * tt2 / 0.12)
        return y
    if kind == 'scratch':
        f = 300 + 1200 * np.abs(np.sin(2 * np.pi * 3 * t))
        return 0.35 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 4) + 0.2 * noise(d, 7) * np.exp(-t * 6)
    if kind == 'ding':
        return 0.3 * np.sin(2 * np.pi * 1318 * t) * np.exp(-t * 5)
    raise ValueError(kind)


def main():
    total = sum(s[3] for s in STAGES) + END
    n = int(total * SR)
    mus, fx = np.zeros(n + SR), np.zeros(n + SR)
    stages, t0 = [], 0.0
    for i, (lab, sub, cap, d, bpm, semi, minor, wob) in enumerate(STAGES):
        m = stage_music(d + 0.15, bpm, semi, minor, wob)
        fade = np.ones(len(m)); k = int(0.15 * SR); fade[-k:] = np.linspace(1, 0, k)
        a = int(t0 * SR); mus[a:a + len(m)] += m * fade
        if i > 0:
            s = sfx('whoosh', 0.35); b = int((t0 - 0.12) * SR); fx[b:b + len(s)] += s
        extra = {1: [('tinkle', 1.0, 1.2)], 2: [('tinkle', 0.6, 1.2), ('tinkle', 2.0, 1.2)], 3: [('pop', 0.8, 0.6), ('pop', 1.7, 0.6), ('pop', 2.4, 0.6)],
                 4: [('rain', 0.0, d)], 5: [('bird', 0.5, 0.6), ('bird', 2.2, 0.6)]}.get(i, [])
        for kind, off, dd in extra:
            s = sfx(kind, dd); b = int((t0 + off) * SR); fx[b:b + len(s)] += s[:len(fx) - b]
        stages.append(dict(label=lab, sub=sub, cap=cap, t0=round(t0, 3), t1=round(t0 + d, 3)))
        t0 += d
    s = sfx('scratch', 0.7); b = int(t0 * SR); fx[b:b + len(s)] += s
    s = sfx('ding', 0.9); b = int((t0 + 0.8) * SR); fx[b:b + len(s)] += s
    mix = (mus + fx)[:n]
    mix = np.tanh(mix / (np.abs(mix).max() + 1e-6) * 1.3) / np.tanh(1.3) * 0.95
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '1', '-i', 'pipe:0',
                    '-af', 'loudnorm=I=-14:TP=-1.0:LRA=11', '-ar', str(SR), '-ac', '2', os.path.join(OUT, 'audio.wav')],
                   input=mix.astype(np.float32).tobytes(), check=True)
    tl = dict(fps=FPS, duration=round(total, 3), lines=[], cues={'end': round(t0, 3)}, scenes={}, sceneOrder=[], mouth=[],
              data=dict(stages=stages, end=round(t0, 3)))
    open(os.path.join(OUT, 'timeline.js'), 'w').write('window.TL = ' + json.dumps(tl, ensure_ascii=False) + ';\n')
    json.dump(tl, open(os.path.join(OUT, 'timeline.json'), 'w'), ensure_ascii=False, indent=1)
    print('Dauer', round(total, 2), [s['t0'] for s in stages])


if __name__ == '__main__':
    main()
