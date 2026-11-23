# NEUES FORMAT: Die Rettungsflitzer – Autos erleben kleine Abenteuer und helfen sich (eigene Figuren, für Kinder)
# Folge 1: „Flitzi steckt fest“
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'N': dict(model='de_DE-thorsten-high', ref='refs/hr.wav', exag=0.7, cfg=0.45, rms=0.14, af='highpass=f=90'),
    'F': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.95, cfg=0.4, rms=0.14, pitch=1.38, af='highpass=f=140'),
    'T': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.75, cfg=0.45, rms=0.15, pitch=0.95, af='highpass=f=60'),
    'R': dict(model='de_DE-thorsten-high', ref='refs/date.wav', exag=0.75, cfg=0.45, rms=0.14, af='highpass=f=100'),
}
MUSIC = dict(style='kids', bpm=118, gain=0.3)
LINES = [
    L('k1', '^start:hupe Es hat geregnet in Räderstadt. Flitzi fährt fröhlich durch die Pfützen.', 'N', gap=0.35),
    L('k2', '^tut:hupe Tüt tüt! Pfützen sind die besten!', 'F', gap=0.4),
    L('k3', '^matsch:squish Oh nein! Ich stecke im Matsch fest!', 'F', gap=0.25),
    L('k4', '^dreh:spin Meine Räder drehen durch. Hilfe! Kann mir jemand helfen?', 'F', gap=0.5),
    L('k5', '^toni:engine Keine Sorge, Flitzi! Toni ist da. Ich zieh dich raus!', 'T', gap=0.3),
    L('k6', '^zug:whoosh_s Hau … ruck! Puh. Der Matsch ist zu stark.', 'T', gap=0.5),
    L('k7', '^frida:siren Ich hab eine Idee! Ich mach den Matsch ganz weich.', 'R', gap=0.3),
    L('k8', '^spritz:spray Wasser marsch!', 'R', gap=0.6),
    L('k9', '^zug2:whoosh_s Jetzt noch mal! Hau … ruck!', 'T', gap=0.2),
    L('k10', '^frei:boing Juhu! Ich bin frei!', 'F', gap=0.35),
    L('k11', '^wasch:sparkle Und zum Schluss gibt es noch eine Autowäsche. Blitzeblank!', 'R', gap=0.4),
    L('k12', 'Danke, ihr zwei! Ihr seid die Besten!', 'F', gap=0.3),
    L('k13', '^zusammen:tada Zusammen schaffen wir alles!', 'N', gap=0.4),
    L('k14', '^ende:hupe Welches Auto soll als Nächstes ein Abenteuer erleben?', 'N', gap=2.0),
]
SCENES = ['s']
EXPORT = dict(names={'F': 'FLITZI', 'T': 'TONI', 'R': 'FRIDA'})
