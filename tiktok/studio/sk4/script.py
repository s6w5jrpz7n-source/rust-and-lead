# SKETCH 4: „Omas Lieblingsenkel“ 👵 – Familie, Geld und käufliche Zuneigung (Skript vom Nutzer)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'E': dict(model='de_DE-thorsten-high', ref='refs/enkelin.wav', exag=0.8, cfg=0.45, rms=0.14, af='highpass=f=100'),
    'O': dict(model='de_DE-thorsten-high', ref='refs/oma.wav', exag=0.5, cfg=0.5, rms=0.14, af='highpass=f=90,vibrato=f=5:d=0.05'),
}
LINES = [
    L('o1', '^ring:ring Oma, seit gestern rufen dich plötzlich alle an!', 'E', gap=0.45),
    L('o2', '^tee:click Ich habe mein Testament in die Familiengruppe geschickt.', 'O', gap=0.45),
    L('o3', '^handy:pop Aber hier steht überall nur: Entwurf.', 'E', gap=0.45),
    L('o4', '^keks:click Ja. Die Abstimmung läuft bis Weihnachten.', 'O', gap=3.4),
]
EXTRA_CUES = [('bell', 'o4', 'end', 0.5, 'doorbell')]
SCENES = ['s']
EXPORT = dict(names={'E': 'ENKELIN', 'O': 'OMA'})
