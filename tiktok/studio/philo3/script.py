# PHILOSOPHIE #3: Das Schiff des Theseus (Plutarch, Theseus 23; Erweiterung durch Thomas Hobbes, De Corpore 1655)
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import NARR, L  # noqa: E402

ENGINE = 'chatterbox'
SPEAKERS = {'P': NARR['P']}
MUSIC = dict(style='lyra', bpm=80, gain=0.12)
P = 'P'
LINES = [
    L('t1', '^hook:hit Bist du eigentlich noch derselbe Mensch wie vor zehn Jahren? ^raetsel:pluck Die alten Griechen hatten dafür ein Rätsel.', P, gap=0.45),
    L('t2', '^schiff:whoosh Theseus, der Held, der den Minotaurus besiegt hat, kehrt mit seinem Schiff nach Athen zurück.', P, gap=0.4),
    L('t3', '^museum:pop Die Athener bewahren das Schiff auf. ^jahre:tick Jahrhundertelang.', P, gap=0.4),
    L('t4', '^morsch:groan Doch das Holz verrottet. ^p1:pop Also ersetzen sie eine morsche Planke. ^p2:pop Dann noch eine. ^p3:pop Und noch eine.', P, gap=0.4),
    L('t5', '^null:stamp Irgendwann ist kein einziges Originalteil mehr übrig. ^frage:ding Ist das noch das Schiff des Theseus?', P, gap=0.5),
    L('t6', '^hobbes:whoosh_s Der Philosoph Thomas Hobbes machte es später noch schlimmer: ^b:pop Jemand sammelt alle alten Planken und baut daraus ein zweites Schiff.', P, gap=0.4),
    L('t7', '^ab:drum Welches ist jetzt das echte? ^a:pop Schiff A ^bb:pop oder Schiff B?', P, gap=0.6),
    L('t8', '^du:whoosh Und jetzt zu dir: Viele Zellen in deinem Körper werden ständig ersetzt. ^haut:pop Deine Haut zum Beispiel alle paar Wochen.', P, gap=0.4),
    L('t9', '^version:glitch Bist du also noch du? ^erinn:pluck Oder nur eine neue Version, mit denselben Erinnerungen?', P, gap=0.5),
    L('t10', '^cta:whoosh_s Schiff A oder Schiff B? Schreib’s in die Kommentare.', P, gap=2.0),
]
SCENES = ['s']
