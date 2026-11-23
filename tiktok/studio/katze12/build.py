# SÜSSES KATZENVIDEO (lang): „ein tag mit mimi“ – 6 Kapitel, ~63 s, ohne Sprache
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(
    c1=0.0, wake=2.2, yawn=3.6, stretch=5.6, sit=7.6, m1=9.0,
    c2=10.5, eat=11.5, look2=15.2, lick=16.6, happy2=18.8,
    c3=20.5, ball=21.2, pounce=23.0, chase=25.0, tangle=27.2, huh=29.6,
    c4=31.5, tap1=32.6, tap2=33.2, out=34.4, flake=36.0, sneeze=37.0, pounce4=38.6, dive=39.2, pop=40.8,
    c5=44.0, hand=45.2, pet=46.0, bump=49.0,
    c6=53.0, curl=54.5, blink=56.5, sleep=58.0, band=58.5, end=63.0)
ev = [(0, 'musicbox', 63.0, 1.0),
      ('yawn', 'yawn', 1.0, 1.0), ('stretch', 'boing', 0.45, 0.4), ('m1', 'tinymeow', 0.35, 1.0),
      ('eat', 'nom', 3.4, 0.9), ('lick', 'lick', 1.8, 0.8), ('happy2', 'tinymeow', 0.3, 0.8),
      ('ball', 'roll', 1.6, 1.0), ('pounce', 'whoosh', 0.4, 0.5), ('chase', 'roll', 1.8, 0.9), ('tangle', 'boing', 0.5, 0.5), ('huh', 'tinymeow', 0.3, 0.9),
      ('tap1', 'boop', 0.3, 0.8), ('tap2', 'boop', 0.3, 0.8), ('out', 'crunch', 1.2, 0.9), ('sneeze', 'sneeze', 0.6, 1.0), ('pounce4', 'whoosh', 0.5, 0.5),
      ('dive', 'poof', 0.6, 1.0), ('pop', 'boing', 0.45, 0.5), (41.3, 'tinymeow', 0.3, 0.9),
      ('pet', 'purr', 6.5, 1.0), ('bump', 'chime', 0.6, 0.5),
      ('curl', 'purr', 4.0, 0.6), ('blink', 'chime', 0.6, 0.4)]
build('katze12', EV, ev)
