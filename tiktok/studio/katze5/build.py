import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(meow1=1.1, meow2=2.3, boop1=3.4, boop2=3.9, boop3=4.4, eye=5.0, close=6.6, again=7.6, end=9.2)
ev = [(0, 'birds', 9.2, 1.0), ('meow1', 'meow', 0.55, 1.0), ('meow2', 'meow', 0.8, 1.3),
      ('boop1', 'boop', 0.3, 1.0), ('boop2', 'boop', 0.3, 1.0), ('boop3', 'boop', 0.3, 1.0), ('eye', 'tick', 0.2, 2.0), (5.1, 'purr', 1.4, 0.8)]
ev += [(0.2 + i * 1.6, 'rustle', 0.7, 0.35, dict(seed=i)) for i in range(2)]
build('katze5', EV, ev)
