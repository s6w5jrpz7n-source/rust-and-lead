import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(look=1.0, dil=1.6, jump=2.2, o1=3.0, o2=3.6, o3=4.2, o4=4.8, star=5.3, top=5.6, blink=7.4, end=9.3)
ev = [(0, 'bells', 2.6, 1.0), ('jump', 'whoosh', 0.4, 1.0), ('jump', 'rustle', 3.2, 1.2)]
ev += [(EV[o] + 0.45, 'clink', 0.5, 1.0, dict(f=f)) for o, f in [('o1', 2400), ('o2', 2800), ('o3', 2200), ('o4', 2600)]]
ev += [(EV['o3'] + 0.5, 'crash', 0.6, 0.35), (EV['star'] + 0.55, 'thump', 0.4, 1.0), ('top', 'tada', 1.2, 1.0), (6.8, 'purr', 2.5, 1.0)]
build('katze6', EV, ev)
