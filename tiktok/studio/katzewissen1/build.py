import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(s1=0.0, s2=3.0, s3=6.0, s4=9.0, s5=12.0, card=15.0, end=17.0)
ev = [(0, 'soft', 17.0, 1.0)] + [(EV[s], 'boop', 0.3, 1.0) for s in ('s2', 's3', 's4', 's5', 'card')] + [(9.2, 'purr', 2.6, 0.8), ('card', 'ding', 0.9, 0.8)]
build('katzewissen1', EV, ev)
