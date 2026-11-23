import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(m1=0.0, open=1.0, look=1.5, think=2.3, turn=4.0, close=4.5, glare=5.2, band=7.2, m2=8.4, end=9.0)
build('katze7', EV, [('m1', 'meow', 0.5, 1.0), ('open', 'creak', 0.8, 1.0), (1.1, 'rain', 3.8, 1.0), ('close', 'thump', 0.4, 1.0), ('m2', 'meow', 0.6, 1.2), ('think', 'tick', 0.2, 1.5)])
