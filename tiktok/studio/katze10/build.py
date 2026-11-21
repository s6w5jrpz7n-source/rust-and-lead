import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(h1=0.0, h2=1.6, h3=3.2, h4=4.6, sunset=6.0, glare=6.4, band=7.4, again=8.5, end=9.0)
ev = [(0, 'soft', 6.0, 1.0), (0.4, 'purr', 5.4, 0.5)] + [(EV[h], 'boing', 0.45, 0.8) for h in ('h1', 'h2', 'h3', 'h4', 'again')] + [('sunset', 'womp', 1.6, 1.0)]
build('katze10', EV, ev)
