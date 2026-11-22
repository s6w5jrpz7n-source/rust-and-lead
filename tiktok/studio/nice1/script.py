# STORYTIME-SKETCH: „Der Nice Guy“ (Skript vom Nutzer) – Ich-Erzähler + Kollege, Büro
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {
    'I': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.8, cfg=0.45, rms=0.15, af='highpass=f=70'),
    'K': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.85, cfg=0.4, rms=0.15, af='highpass=f=70'),
}
MUSIC = dict(bpm=96, gain=0.09)
LINES = [
    L('n1', '^hook:pop Kennt ihr diesen Typen, der immer sagt: ^nice:ding Ich bin der Nice Guy?', 'I', gap=0.3),
    L('n2', '^kompl:whoosh_s Der, der euch ungefragt Komplimente macht, wie:', 'I', gap=0.15),
    L('k1', '^gew:pop Für dein Gewicht siehst du echt okay aus.', 'K', gap=0.5),
    L('n3', '^gestern:whoosh_s Gestern hat der Arschloch-Kollege wieder seine große Klappe aufgerissen.', 'I', gap=0.3),
    L('k2', '^ey:pop Ey, deine Freundin ist ja richtig … charmant. ^alter:stamp Für ihr Alter.', 'K', gap=0.5),
    L('n4', '^laechel:ding Ich hab gelächelt.', 'I', gap=0.4),
    L('n5', '^ruhig:whoosh_s Dann hab ich ihm ganz ruhig erzählt, dass seine Ex ihn gestern bei Tinder ^status:notif mit dem Status: Suche jemanden, der wenigstens weiß, wo die Klitoris ist, gematcht hat.', 'I', gap=0.4),
    L('n6', '^hund:pop Und dass sein Hund ihn mehr mag als seine eigene Mutter.', 'I', gap=0.3),
    L('n7', '^tot:sting Und dass der Hund gestern gestorben ist.', 'I', gap=0.5),
    L('n8', '^lw:rimshot An Langeweile.', 'I', gap=0.6),
    L('n9', '^pudel:boing Er stand da wie ein vollgeschissener Pudel und hat nur Hä gesagt.', 'I', gap=0.4),
    L('n10', '^bro:pop Keine Sorge, Bro. Du bist immer noch der Nice Guy. ^niemand:stamp Nur halt der, den niemand will.', 'I', gap=0.5),
    L('n11', '^weg:whoosh Dann bin ich gegangen. ^schrei:hit Er hat hinter mir hergeschrien.', 'I', gap=0.3),
    L('n12', '^finger:pop Ich hab nur den Mittelfinger gehoben und gedacht:', 'I', gap=0.35),
    L('n13', '^fried:drone Manche Menschen sind so nutzlos, ^ablehn:stamp dass selbst der Friedhof sie ablehnen würde.', 'I', gap=2.0),
]
SCENES = ['s']
EXPORT = dict(names={'K': 'KOLLEGE'})
