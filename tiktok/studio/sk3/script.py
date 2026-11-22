# SKETCH 3: „Gemeinsame Interessen“ 🍷 – Dating und True Crime (Skript vom Nutzer)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'F': dict(model='de_DE-thorsten-high', ref='refs/date.wav', exag=0.85, cfg=0.4, rms=0.14, af='highpass=f=90'),
    'M': dict(model='de_DE-thorsten-high', ref='refs/notar.wav', exag=0.4, cfg=0.5, rms=0.14, af='highpass=f=70'),
}
MUSIC = dict(style='romance', bpm=84, gain=0.3, stop='d4')
LINES = [
    L('d1', '^start:pop Ich schlafe jeden Abend mit {True-Crime-Podcasts|Tru-Kreim-Podcasts} ein.', 'F', gap=0.45),
    L('d2', '^cut:click Ich höre die auch. Aber diese Recherchefehler nerven.', 'M', gap=0.4),
    L('d3', 'Was für Fehler?', 'F', gap=0.7),
    L('d4', '^zwei:sting Bei mir haben sie zwei vergessen.', 'M', gap=1.5),
    L('d5', '^brot:pop Noch Brot?', 'M', gap=2.4),
]
SCENES = ['s']
EXPORT = dict(names={'F': 'SIE', 'M': 'ER'})
