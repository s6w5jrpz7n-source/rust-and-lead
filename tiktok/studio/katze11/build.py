# SÜSSES KATZENVIDEO: „Ihr erster Schnee“ – Kätzchen, Schnee, Hatschi, Schneehaufen, Einkuscheln (Schleife, ohne Sprache)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from catsfx import build  # noqa: E402
EV = dict(look=1.0, tap1=2.1, tap2=2.7, out=3.6, step=4.0, flake=5.2, sneeze=6.2, pounce=7.5, dive=8.1, pop=9.5, inside=11.0, blink=11.9, band=11.4, end=14.5)
build('katze11', EV, [(0, 'musicbox', 14.5, 1.0), ('tap1', 'boop', 0.3, 0.8), ('tap2', 'boop', 0.3, 0.8), ('look', 'tinymeow', 0.35, 0.9),
                      ('step', 'crunch', 1.2, 0.9), ('sneeze', 'sneeze', 0.6, 1.0), ('pounce', 'whoosh', 0.5, 0.6), ('dive', 'poof', 0.6, 1.0),
                      ('pop', 'boing', 0.45, 0.6), (9.9, 'tinymeow', 0.3, 0.9), ('inside', 'purr', 3.4, 0.9), ('blink', 'chime', 0.6, 0.5)])
