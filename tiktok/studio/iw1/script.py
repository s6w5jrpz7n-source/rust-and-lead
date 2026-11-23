# PARODIE: „Wie Infinity War hätte enden sollen“ – eigene Cartoon-Figuren, keine Filmbilder/-musik/-logos.
# Fan-Kritikpunkt: Auf Titan war der Handschuh fast ab, bis Star-Lord zuschlug (und Thor zielte später nicht auf den Kopf).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'M': dict(model='de_DE-thorsten-high', ref='refs/enkelin.wav', exag=0.4, cfg=0.5, rms=0.13, pitch=1.06, af='highpass=f=120'),
    'I': dict(model='de_DE-thorsten-high', ref='refs/host.wav', exag=0.6, cfg=0.45, rms=0.14, af='highpass=f=70'),
    'S': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.95, cfg=0.4, rms=0.14, pitch=1.22, af='highpass=f=120'),
    'Q': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.7, cfg=0.45, rms=0.14, af='highpass=f=70'),
    'D': dict(model='de_DE-thorsten-high', ref='refs/notar.wav', exag=0.45, cfg=0.5, rms=0.14, af='highpass=f=70'),
    'T': dict(model='de_DE-thorsten-high', ref='refs/teufel.wav', exag=0.4, cfg=0.5, rms=0.15, pitch=0.85, af='highpass=f=45'),
    'R': dict(model='de_DE-thorsten-high', ref='refs/thor.wav', exag=0.95, cfg=0.4, rms=0.15, af='highpass=f=60'),
}
MUSIC = dict(style='drama', bpm=72, gain=0.28, stop='a8')
LINES = [
    L('a1', '^start:drone Er schläft. Schnell, zieht ihm den Handschuh aus!', 'M', gap=0.3),
    L('a2', '^zieh:whoosh_s Fast! Kleiner, zieh fester!', 'I', gap=0.25),
    L('a3', 'Ich zieh ja! Der hat Hände wie ein Kühlschrank!', 'S', gap=0.4),
    L('a4', '^quill:pop Moment. Wo ist Gamora?', 'Q', gap=0.35),
    L('a5', 'Er … trauert.', 'M', gap=0.4),
    L('a6', '^fist:rise Du hast sie …', 'Q', gap=2.8),
    L('a8', '^magie:swirl Peter, nicht!', 'D', gap=0.25),
    L('a9', 'Welcher?', 'S', gap=0.08),
    L('a10', 'Welcher von uns?', 'Q', gap=0.35),
    L('a11', 'Der Wütende. Erst den Handschuh. Dann die Gefühle.', 'D', gap=0.4),
    L('a12', '^ab:tada Ich hab ihn!', 'S', gap=0.5),
    L('a13', 'Oh. Mist.', 'T', gap=0.35),
    L('a14', 'So. Jetzt darf ich.', 'Q', gap=0.9),
    L('a15', 'Doc. War das die eine von vierzehn Millionen Möglichkeiten?', 'I', gap=0.3),
    L('a16', 'Ja. Aber psst. Sonst gibt es keinen zweiten Teil.', 'D', gap=0.6),
    L('a17', '^thor:boom Wo ist er? Diesmal ziele ich auf den Kopf!', 'R', gap=0.7),
    L('a18', 'Oh. Schon erledigt?', 'R', gap=2.2),
]
EXTRA_CUES = [('freeze', 'a6', 'end', 0.15, 'recscratch'), ('rewind', 'a6', 'end', 1.6, 'vhs'), ('punch', 'a14', 'end', 0.12, 'hit')]
SCENES = ['s']
EXPORT = dict(names={'M': 'MANTIS', 'I': 'TONY', 'S': 'SPIDEY', 'Q': 'STAR-LORD', 'D': 'STRANGE', 'T': 'THANOS', 'R': 'THOR'})
