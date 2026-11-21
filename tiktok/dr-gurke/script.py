# Dr. Gurke – Skript
# spk: N = Erzähler, G = Dr. Gurke
# Textsyntax: {Anzeige|gesprochen}  -> Untertitel zeigt "Anzeige", Stimme spricht "gesprochen"
# cues: Liste von (Wortindex der Anzeige, Cue-Name, SFX oder None)

LINES = [
    # ---------------- HOOK ----------------
    dict(id='h1', spk='N', scene='hook',
         text='Forscher haben endlich eine Methode gegen Leute gefunden, die ewig das Klo blockieren.'),
    dict(id='h2', spk='N', scene='hook', text='Und der {Schlüssel…|Schlüssel}', gap=0.6,
         cues=[(0, 'drum', 'drum')]),
    dict(id='h3', spk='N', scene='hook', text='ist eine Gurke.',
         cues=[(2, 'gurkeIn', 'pop')]),
    dict(id='h4', spk='G', emo='amused', scene='hook',
         text='Guten Tag. {Dr.|Doktor} Gurke. Gurkologisches Institut.'),
    dict(id='h5', spk='N', scene='hook', text='Moment. Woran hast du gerade gedacht?',
         cues=[(1, 'sus', None)]),
    dict(id='h6', spk='G', emo='angry', scene='hook',
         text='{NEIN!|Nein!} {NICHT|Nicht} {SO!|so!} Was stimmt nicht mit {dir?!|dir?}',
         cues=[(1, 'stamp1', 'stamp')]),

    # ---------------- PROBLEM ----------------
    dict(id='p1', spk='N', scene='problem', text='Also. Nochmal von vorne.'),
    dict(id='p2', spk='N', scene='problem',
         text='Du kennst sie: Leute, die {20|zwanzig} Minuten auf dem Klo sitzen, während draußen die Schlange wächst.',
         cues=[(5, 'twenty', 'tick'), (12, 'queue', None)]),
    dict(id='p3', spk='N', scene='problem', text='Und dann jammern: Ich kann nicht.',
         cues=[(3, 'whine', 'boing')]),

    # ---------------- HANDY ----------------
    dict(id='f1', spk='G', emo='angry', scene='phone', text='Problem Nummer {1:|eins:} das Handy!',
         cues=[(0, 'gIn1', 'pop')]),
    dict(id='f2', spk='N', scene='phone',
         text='In einer Studie aus Boston nahmen {2/3|zwei Drittel} das Handy mit aufs Klo.',
         cues=[(6, 'pie', 'ding')]),
    dict(id='f3', spk='N', scene='phone',
         text='Und genau die hatten ein um {46|sechsundvierzig} {%|Prozent} höheres Risiko für Hämorrhoiden.',
         cues=[(6, 'stat46', 'ding')]),
    dict(id='f4', spk='N', scene='phone', text='Wer scrollt, sitzt länger. Und der Druck steigt.',
         cues=[(2, 'longer', None), (6, 'druck', 'rise')]),

    # ---------------- HALTUNG ----------------
    dict(id='s1', spk='G', emo='angry', scene='posture', text='Problem Nummer {2:|zwei:} Du sitzt falsch!',
         cues=[(0, 'gIn2', 'pop')]),
    dict(id='s2', spk='N', scene='posture',
         text='Im Sitzen hält ein Muskel deinen Enddarm abgeknickt, wie einen Gartenschlauch.',
         cues=[(4, 'muscle', None), (7, 'kink', 'tick'), (10, 'hose', None)]),
    dict(id='s3', spk='N', scene='posture', text='In der Hocke wird er gerade.',
         cues=[(2, 'squat', 'whoosh_s'), (5, 'straight', 'ding')]),
    dict(id='s4', spk='N', scene='posture',
         text='In einer Studie brauchten Leute in der Hocke im Schnitt {51|einundfünfzig} Sekunden. Im Sitzen rund {2|zwei} Minuten.',
         cues=[(0, 'bars', None), (10, 'bar1', 'ding'), (15, 'bar2', 'ding')]),
    dict(id='s5', spk='N', scene='posture', text='Die Lösung: ein kleiner Hocker unter die Füße.',
         cues=[(4, 'stool', 'boing')]),

    # ---------------- METHODE ----------------
    dict(id='m1', spk='G', emo='surprised', scene='method', text='Und jetzt: meine Methode!',
         cues=[(3, 'stamp2', 'stamp')]),
    dict(id='m2', spk='G', emo='angry', scene='method', text='Beckenbodentraining!',
         cues=[(0, 'bbt', 'ding')]),
    dict(id='m3', spk='G', emo='angry', scene='method',
         text='Anspannen, als würdest du einen Pups zurückhalten!',
         cues=[(0, 'tense', 'rise'), (5, 'pups', None)]),
    dict(id='m4', spk='G', emo='angry', scene='method', text='Halten!', cues=[(0, 'hold', None)]),
    dict(id='m5', spk='G', emo='neutral', scene='method', text='Und locker lassen!',
         cues=[(1, 'relax', 'whoosh_s')]),
    dict(id='m6', spk='G', emo='angry', scene='method', text='{20|Zwanzig} Wiederholungen!',
         cues=[(0, 'reps', None)]),
    dict(id='m7', spk='G', emo='angry', scene='method', text='{1!|Eins!}', gap=0.3, cues=[(0, 'c1', 'tick')]),
    dict(id='m8', spk='G', emo='angry', scene='method', text='{2!|Zwei!}', gap=0.3, cues=[(0, 'c2', 'tick')]),
    dict(id='m9', spk='G', emo='angry', scene='method', text='{3!|Drei!}', gap=1.7, cues=[(0, 'c3', 'tick')]),
    dict(id='m10', spk='G', emo='angry', scene='method', text='{20!|Zwanzig!} Sehr gut, Soldat!',
         cues=[(0, 'c20', 'tada')]),

    # ---------------- TIPPS ----------------
    dict(id='t1', spk='N', scene='tips',
         text='Wer seinen Beckenboden spürt, kann ihn auf dem Klo auch gezielt entspannen.',
         cues=[(11, 'entspannen', None)]),
    dict(id='t2', spk='N', scene='tips', text='Dazu: genug trinken, Ballaststoffe essen, nicht pressen.',
         cues=[(2, 'card1', 'pop'), (3, 'card2', 'pop'), (5, 'card3', 'pop')]),
    dict(id='t3', spk='N', scene='tips', text='Und nach {10|zehn} Minuten: aufstehen.',
         cues=[(2, 'card4', 'pop'), (4, 'stand', None)]),

    # ---------------- OUTRO ----------------
    dict(id='o1', spk='G', emo='neutral', scene='outro',
         text='Ich bin eine Gurke. Ich gehöre in den Salat.',
         cues=[(8, 'salad', 'boing')]),
    dict(id='o2', spk='G', emo='angry', scene='outro', text='Und {NIRGENDWO|nirgendwo} sonst!',
         cues=[(1, 'nirgendwo', 'stamp')]),
    dict(id='o3', spk='N', scene='outro', text='Schick das dem Klo-Blockierer in deinem Leben.',
         cues=[(0, 'cta', 'whoosh_s')]),
    dict(id='o4', spk='N', scene='outro', text='Und bei Dauerproblemen: ab zum Arzt.',
         cues=[(5, 'arzt', 'ding')]),
]

SCENES = ['hook', 'problem', 'phone', 'posture', 'method', 'tips', 'outro']
