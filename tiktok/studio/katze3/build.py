import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(pop=2.3, flop=3.5, send=5.6, blink=7.3, end=9.3)
ev = [(i * 0.11, 'key', 0.05, 1.0, dict(seed=i)) for i in range(20)]
ev += [('pop', 'squeak', 0.3, 0.8), ('flop', 'thump', 0.35, 1.0), (3.6, 'mash', 2.2, 1.0), (5.0, 'beep', 0.2, 0.8), ('send', 'ding', 0.9, 1.0), (6.4, 'purr', 2.8, 1.0)]
build('katze3', EV, ev)
