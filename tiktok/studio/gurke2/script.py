# Dr. Gurke erklärt – Folge 2: Der Klamottenstuhl
# spk: N = Erzähler, G = Dr. Gurke  |  emo (nur G): amused, angry, disgusted, neutral, surprised, whisper
# Textsyntax: {Anzeige|gesprochen}  |  cues: (Wortindex der Anzeige, Cue-Name, SFX oder None)

LINES = [
    # ---------------- HOOK ----------------
    dict(id='h1', spk='N', scene='hook',
         text='In fast jedem Schlafzimmer steht ein Möbelstück, auf dem noch nie jemand gesessen hat.',
         cues=[(6, 'chair', None), (12, 'zero', 'pop')]),
    dict(id='h2', spk='N', scene='hook', text='Der Klamottenstuhl.', gap=0.5,
         cues=[(1, 'title', 'stamp')]),
    dict(id='h3', spk='G', emo='amused', scene='hook',
         text='Guten Tag. {Dr.|Doktor} Gurke. Ich erforsche dieses Phänomen seit Jahren.',
         cues=[(0, 'gIn', 'pop'), (2, 'name', None)]),
    dict(id='h4', spk='G', emo='neutral', scene='hook',
         text='Meinen eigenen Stuhl habe ich seit {2019|zweitausendneunzehn} nicht mehr gesehen.',
         cues=[(2, 'vermisst', 'pop')]),

    # ---------------- SCHRÖDINGER ----------------
    dict(id='q1', spk='N', scene='quantum', text='Auf den Stuhl kommt alles, was zu sauber für die Wäsche ist.',
         cues=[(0, 'pull', 'pop'), (10, 'waesche', 'boing')]),
    dict(id='q2', spk='N', scene='quantum', text='Aber zu dreckig für den Schrank.',
         cues=[(5, 'schrank', 'boing')]),
    dict(id='q3', spk='G', emo='surprised', scene='quantum',
         text='Schrödingers Pullover! Gleichzeitig sauber {UND|und} dreckig!',
         cues=[(0, 'schroedinger', 'ding'), (3, 'both', None)]),
    dict(id='q4', spk='N', scene='quantum', text='Erst wenn du dran riechst, entscheidet sich sein Zustand.',
         cues=[(4, 'sniff', 'sniff')]),
    dict(id='q5', spk='G', emo='disgusted', scene='quantum', text='Geht noch.', gap=0.9,
         cues=[(0, 'gehtnoch', 'stamp')]),

    # ---------------- SCHICHTEN ----------------
    dict(id='l1', spk='G', emo='angry', scene='layers', text='Problem Nummer {1:|eins:} Der Stuhl wächst!',
         cues=[(0, 'gIn1', 'pop')]),
    dict(id='l2', spk='N', scene='layers', text='Wie Gesteinsschichten. Ganz oben: die Jeans von gestern.',
         cues=[(1, 'strata', None), (5, 'layer1', 'pop')]),
    dict(id='l3', spk='N', scene='layers', text='In der Mitte: die Sommerjacke vom letzten Jahr.',
         cues=[(4, 'layer2', 'pop')]),
    dict(id='l4', spk='N', scene='layers',
         text='Und ganz unten: Dinge, die die Wissenschaft noch nicht benennen kann.',
         cues=[(3, 'layer3', 'drone')]),
    dict(id='l5', spk='G', emo='whisper', scene='layers',
         text='Ich habe da unten mal einen Socken gefunden. Er war älter als ich.', gap=0.6,
         cues=[(6, 'sock', 'pop'), (10, 'older', 'boing')]),

    # ---------------- SCHWERKRAFT ----------------
    dict(id='g1', spk='G', emo='angry', scene='gravity', text='Problem Nummer {2:|zwei:} Er zieht alles an!',
         cues=[(0, 'gIn2', 'pop')]),
    dict(id='g2', spk='N', scene='gravity',
         text='Ab etwa {2 Kilo|zwei Kilo} Wäsche entwickelt der Stuhl eine eigene Schwerkraft.',
         cues=[(2, 'kilo', 'ding'), (9, 'swirl', 'swirl')]),
    dict(id='g3', spk='N', scene='gravity', text='Ladekabel. Kopfhörer. Haargummis.',
         cues=[(0, 'item1', 'pop'), (1, 'item2', 'pop'), (2, 'item3', 'pop')]),
    dict(id='g4', spk='N', scene='gravity', text='Alles, was in seine Nähe kommt, verschwindet. Für immer.', gap=0.5,
         cues=[(6, 'vanish', 'whoosh'), (7, 'forever', 'stamp')]),

    # ---------------- LÖSUNG ----------------
    dict(id='x1', spk='N', scene='solution', text='Was also tun? Aufräumen?',
         cues=[(3, 'aufr', None)]),
    dict(id='x2', spk='G', emo='angry', scene='solution',
         text='{AUFRÄUMEN?!|Aufräumen?} Wir sind doch keine Tiere!',
         cues=[(0, 'stampNo', 'stamp')]),
    dict(id='x3', spk='G', emo='amused', scene='solution',
         text='Die wissenschaftliche Lösung: ein zweiter Stuhl.',
         cues=[(4, 'chair2', 'boing')]),
    dict(id='x4', spk='N', scene='solution', text='Nach etwa {3|drei} Wochen ist auch der zweite Stuhl voll.',
         cues=[(2, 'weeks', 'whoosh_s'), (9, 'full2', 'pop')]),
    dict(id='x5', spk='G', emo='surprised', scene='solution', text='Dann eben ein dritter Stuhl! Und ein vierter!',
         cues=[(3, 'chair3', 'boing'), (7, 'chair4', 'boing')]),
    dict(id='x6', spk='N', scene='solution',
         text='Herzlichen Glückwunsch. Du hast gerade den Kleiderschrank erfunden.',
         cues=[(0, 'merge', 'whoosh'), (6, 'wardrobe', 'tada')]),
    dict(id='x7', spk='G', emo='neutral', scene='solution', text='Und den benutzt natürlich niemand.', gap=1.7,
         cues=[(2, 'open', 'whoosh_s'), (4, 'empty', 'crickets')]),

    # ---------------- OUTRO ----------------
    dict(id='o1', spk='N', scene='outro', text='Schick das der Person mit dem Klamottenstuhl.',
         cues=[(0, 'cta', 'whoosh_s')]),
    dict(id='o2', spk='N', scene='outro', text='Du weißt genau, wer gemeint ist.', gap=0.5,
         cues=[(0, 'know', None)]),
    dict(id='o3', spk='G', emo='whisper', scene='outro', text='Oder dreh dich mal um.', gap=1.1,
         cues=[(0, 'creep', 'drone'), (4, 'eyes', 'sting')]),
]

SCENES = ['hook', 'quantum', 'layers', 'gravity', 'solution', 'outro']
