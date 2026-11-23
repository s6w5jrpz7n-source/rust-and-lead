import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(look=1.0, step=2.0, settle=2.7, box2=4.5, dil=5.0, jump=5.8, land=6.3, blink=7.6, end=9.4)
ev = [('step', 'rustle', 0.7, 1.0), ('settle', 'boing', 0.5, 0.8), ('box2', 'boop', 0.3, 1.0), (EV['box2'] + 0.1, 'ding', 0.8, 0.6),
      ('jump', 'whoosh', 0.5, 1.0), ('land', 'boing', 0.5, 1.0), (EV['land'] + 0.05, 'rustle', 0.6, 1.0, dict(seed=3)), (6.9, 'purr', 2.4, 1.0)]
build('katze4', EV, ev)
