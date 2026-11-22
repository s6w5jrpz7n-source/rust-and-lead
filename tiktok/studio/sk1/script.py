# SKETCH 1: „Ein letztes Mal“ ⚰️ – Erbschaft und gespielte Trauer (Skript vom Nutzer)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'S': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.85, cfg=0.4, rms=0.14, af='highpass=f=70,aecho=0.8:0.5:40:0.12'),
    'B': dict(model='de_DE-thorsten-high', ref='refs/bestatterin.wav', exag=0.35, cfg=0.5, rms=0.13, af='highpass=f=90,aecho=0.8:0.5:40:0.12'),
}
MUSIC = dict(style='organ', bpm=40, gain=0.35, stop='s3')
LINES = [
    L('s1', '^start:drone Papa … bitte. Mach noch ein einziges Mal die Augen auf.', 'S', gap=0.6),
    L('s2', '^hand:whoosh_s Sie müssen ihn loslassen.', 'B', gap=0.45),
    L('s3', '^turn:recscratch Sobald {Face ID|Fejs Ei Di} funktioniert.', 'S', gap=3.4),
]
EXTRA_CUES = [('fail', 's3', 'end', 0.5, 'buzz'), ('sister', 's3', 'end', 1.8, 'pop')]
SCENES = ['s']
EXPORT = dict(names={'S': 'SOHN', 'B': 'BESTATTERIN'})
