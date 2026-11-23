import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(point=2.4, walk=3.0, sniff=3.8, back=5.0, scratch2=5.6, eye=7.0, band=7.3, end=9.0)
build('katze9', EV, [(0.0, 'scratch', 2.4, 1.0), ('point', 'boop', 0.3, 1.0), ('sniff', 'squeak', 0.4, 0.6), ('scratch2', 'scratch', 2.0, 1.3), (6.6, 'rustle', 0.8, 0.8), (7.7, 'purr', 1.3, 0.8), (8.3, 'scratch', 0.7, 1.0)])
