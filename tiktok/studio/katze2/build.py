import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(dil=1.3, go=2.2, p1=2.2, p2=3.05, p3=3.95, lamp=4.35, p4=4.8, stop=5.6, blink=7.2, end=9.2)
ev = [(0, 'night', 9.2, 1.0)] + [(float(i), 'tick', 0.1, 1.0) for i in range(10)]
for p in ('p1', 'p2', 'p3', 'p4'):
    ev.append((p, 'whoosh', 0.5, 1.0))
    for j in range(6): ev.append((EV[p] + 0.05 + j * 0.11, 'thump', 0.25, 0.7, dict(seed=j)))
ev += [(EV['p2'] + 0.25, 'boing', 0.5, 0.8), ('lamp', 'crash', 1.0, 0.6), ('stop', 'thump', 0.3, 0.5), (EV['stop'] + 0.9, 'purr', 2.6, 1.0)]
build('katze2', EV, ev)
