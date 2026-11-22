#!/usr/bin/env python3
"""Schneidet Archivfilm-Material passend zur Timeline: ein JPG pro Ausgabe-Frame (build/<ep>/frames/f00000.jpg).
Jede Zeile bekommt ihr Bild ab kurz vor Sprechbeginn bis kurz vor der nächsten Zeile; fehlt Material, steht das letzte Bild."""
import json, os, shutil, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ep = sys.argv[1]
tl = json.load(open(os.path.join(HERE, 'build', ep, 'timeline.json')))
ex = tl['data']; src = os.path.join(HERE, 'build', ex['src'])
LEAD, FPS = 0.15, 30
lines = tl['lines']; total = tl['duration']
slots = []
for i, l in enumerate(lines):
    a = 0.0 if i == 0 else l['start'] - LEAD
    b = total if i == len(lines) - 1 else lines[i + 1]['start'] - LEAD
    slots.append((l['id'], a, b))
parts, filt = [], []
for lid, a, b in slots:
    need = b - a
    shots = ex['shots'][lid]
    for j, (s, e) in enumerate(shots):
        last = j == len(shots) - 1
        d = min(e - s, need) if not last else need
        if d <= 0.01: break
        use = min(e - s, d)
        k = len(parts)
        filt.append(f"[0:v]trim=start={s}:duration={use:.3f},setpts=PTS-STARTPTS,fps={FPS},scale=640:480,setsar=1,"
                    f"tpad=stop_mode=clone:stop_duration={max(0, d - use) + 0.1:.3f},trim=duration={d:.3f}[v{k}]")
        parts.append(k); need -= d
        if need <= 0.01: break
fc = ';'.join(filt) + ';' + ''.join(f'[v{k}]' for k in parts) + f'concat=n={len(parts)}:v=1:a=0,fps={FPS}[out]'
out = os.path.join(HERE, 'build', ep, 'frames'); shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', src, '-filter_complex', fc, '-map', '[out]', '-q:v', '3', '-start_number', '0',
                os.path.join(out, 'f%05d.jpg')], check=True)
n = len(os.listdir(out)); print(ep, 'Frames:', n, 'Soll:', int(total * FPS))
json.dump(dict(slots=slots), open(os.path.join(HERE, 'build', ep, 'cut.json'), 'w'))
