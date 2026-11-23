# SKETCH 2: „Die Hölle hat sich verändert“ 🔥 – Arbeitswelt und Firmenkultur (Skript vom Nutzer)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'M': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.7, cfg=0.45, rms=0.14, af='highpass=f=70'),
    'T': dict(model='de_DE-thorsten-high', ref='refs/teufel.wav', exag=0.55, cfg=0.5, rms=0.15, pitch=0.88, af='highpass=f=50,aecho=0.8:0.6:60:0.2'),
    'P': dict(model='de_DE-thorsten-high', ref='refs/hr.wav', exag=1.0, cfg=0.35, rms=0.14, af='highpass=f=100'),
}
LINES = [
    L('h1', '^start:drone Okay. Wo werde ich gefoltert?', 'M', gap=0.5),
    L('h2', '^door:whoosh Wir arbeiten hier inzwischen mit moderneren Methoden.', 'T', gap=0.6),
    L('h3', '^hr:jingle Bei uns sind wir alle eine große Familie!', 'P', gap=0.5),
    L('h4', '^grab:whoosh_s Ich würde gern noch mal das Feuer sehen.', 'M', gap=2.4),
]
SCENES = ['s']
EXPORT = dict(names={'M': 'MANN', 'T': 'TEUFEL', 'P': 'PERSONALCHEFIN'})
