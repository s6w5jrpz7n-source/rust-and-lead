# WISSENSCHAFT: Herleitung von E = mc² mit Einsteins Lichtkasten (1906)
# Annahmen: (1) Licht der Energie E trägt den Impuls p = E/c (Maxwell, gemessen als Strahlungsdruck)
#           (2) ohne äußere Kraft bleibt der Schwerpunkt eines abgeschlossenen Systems in Ruhe.
# Näherung: Der Kasten bewegt sich kaum (Δx ≪ L); die exakte Rechnung liefert dasselbe Ergebnis.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from quizlib import HOST  # noqa: E402

ENGINE = 'chatterbox'
SPEAKERS = {'Q': dict(HOST['Q'], exag=0.55)}
MUSIC = dict(bpm=96, gain=0.1)

LINES = [
    dict(id='n1', spk='Q', scene='emc', text='{E = mc².|E gleich em zeh Quadrat.} Jeder kennt die Formel. Aber woher kommt sie? Hier ist die Herleitung. In einer Minute.',
         gap=0.4, cues=[(0, 'hook', 'hit'), (6, 'woher', None)]),
    dict(id='n2', spk='Q', scene='emc', text='Stell dir einen Kasten im leeren Weltall vor. Masse {M,|groß em,} Länge {L.|el.}',
         cues=[(3, 'box', 'whoosh_s'), (9, 'M', 'pop'), (11, 'L', 'pop')]),
    dict(id='n3', spk='Q', scene='emc', text='Links blitzt ein Lichtpuls auf, mit der Energie E.',
         cues=[(3, 'flash', 'ding')]),
    dict(id='n4', spk='Q', scene='emc', text='Licht hat Impuls. Das folgt aus Maxwells Gleichungen: {p = E/c.|pe gleich E durch zeh.}',
         cues=[(2, 'impuls', None), (8, 'eq1', 'pop')]),
    dict(id='n5', spk='Q', scene='emc', text='Impulserhaltung! Der Kasten bekommt einen Rückstoß nach links, mit {v = E/(Mc).|vau gleich E durch groß em zeh.}',
         cues=[(5, 'recoil', 'whoosh_s'), (9, 'eq2', 'pop')]),
    dict(id='n6', spk='Q', scene='emc', text='Das Licht braucht für die Strecke L ungefähr die Zeit {L/c.|el durch zeh.}',
         cues=[(10, 'eq3', 'pop')]),
    dict(id='n7', spk='Q', scene='emc', text='In dieser Zeit rutscht der Kasten ein winziges Stück nach links. {Δx = v·t = EL/(Mc²).|Delta iks gleich vau mal te. Also E el durch groß em zeh Quadrat.}',
         cues=[(3, 'dx', None), (11, 'eq4', 'pop')]),
    dict(id='n8', spk='Q', scene='emc', text='Aber Moment! Ohne äußere Kraft kann sich der Schwerpunkt nicht bewegen.', gap=0.4,
         cues=[(0, 'aber', 'stamp'), (8, 'cm', 'ding')]),
    dict(id='n9', spk='Q', scene='emc', text='Also muss das Licht Masse mitgenommen haben, von links nach rechts. Damit der Schwerpunkt bleibt, gilt: {m·L = M·Δx.|klein em mal el gleich groß em mal Delta iks.}',
         cues=[(4, 'mass', 'pop'), (16, 'eq5', 'pop')]),
    dict(id='n10', spk='Q', scene='emc', text='Einsetzen. L und M kürzen sich weg. Übrig bleibt: {m = E/c².|em gleich E durch zeh Quadrat.}',
         cues=[(0, 'insert', 'whoosh_s'), (4, 'cancel', 'tick'), (9, 'eq6', 'pop')]),
    dict(id='n11', spk='Q', scene='emc', text='Oder anders geschrieben:', gap=0.5, cues=[(0, 'anders', 'drum')]),
    dict(id='n12', spk='Q', scene='emc', text='{E = mc².|E gleich em zeh Quadrat!}', gap=0.6, cues=[(0, 'reveal', 'tada')]),
    dict(id='n13', spk='Q', scene='emc', text='Energie hat Masse. Die Sonne verliert so jede Sekunde rund {4 Millionen|vier Millionen} Tonnen. Als Licht.',
         cues=[(0, 'sun', 'whoosh'), (9, 'tonnen', 'ding')]),
    dict(id='n14', spk='Q', scene='emc', text='Folg mir für Teil zwei: Warum nichts schneller ist als Licht.', gap=2.0,
         cues=[(0, 'cta', 'whoosh_s')]),
]
SCENES = ['emc']
