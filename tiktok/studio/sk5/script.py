# SKETCH 5: „Bis dass der Tod uns scheidet“ 💍 – Ehe und Prioritäten (Skript vom Nutzer)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'G': dict(model='de_DE-thorsten-high', ref='refs/geist.wav', exag=0.9, cfg=0.4, rms=0.15, af='highpass=f=120,aecho=0.8:0.7:90|160:0.35|0.2'),
    'M': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.5, cfg=0.5, rms=0.14, af='highpass=f=70'),
}
LINES = [
    L('g1', '^ghost:ghost Drei Wochen bin ich tot. Und du bist schon wieder auf Tinder?!', 'G', gap=0.45),
    L('g2', '^lamp:click Schatz. Wir haben gesagt: bis dass der Tod uns scheidet.', 'M', gap=0.4),
    L('g3', '^foto:pop Ich habe den Vertrag erfüllt.', 'M', gap=0.6),
    L('g4', '^flicker:flicker Gut. Dann kommen wir jetzt zur Wohnungsübergabe.', 'G', gap=3.2),
]
EXTRA_CUES = [('slam', 'g4', 'end', 0.35, 'slam')]
SCENES = ['s']
EXPORT = dict(names={'G': 'SIE (†)', 'M': 'ER'})
