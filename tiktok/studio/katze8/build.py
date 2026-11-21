import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(butt=1.2, face=3.0, lie=4.6, chat1=5.0, chat2=5.8, leave=6.8, band=7.6, end=9.4)
ev = [(0.0, 'whoosh', 0.6, 0.8), ('butt', 'boop', 0.3, 1.0), (1.6, 'boop', 0.3, 0.8), (2.1, 'boop', 0.3, 0.9), ('face', 'squeak', 0.4, 0.8),
      ('lie', 'thump', 0.35, 1.0), (4.7, 'mash', 0.8, 0.8), ('chat1', 'chime', 0.6, 1.0), ('chat2', 'chime', 0.6, 1.0), (5.0, 'purr', 1.8, 0.8), ('leave', 'whoosh', 0.5, 0.8), (8.6, 'whoosh', 0.6, 0.8)]
build('katze8', EV, ev)
