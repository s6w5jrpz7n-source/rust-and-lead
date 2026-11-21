# DER TOD HAT MONTAG – animierter Sketch (schwarzer Humor)
# spk: T = Tod (müde, zynisch), C = Chef (der Teufel, Video-Call), G = Kunde (frisch verstorben, Geist)
# Textsyntax: {Anzeige|gesprochen}  |  cues: (Wortindex der Anzeige, Cue-Name, SFX oder None)

SPEAKERS = {
    'T': dict(model='de_DE-thorsten-high', length=1.06, noise=0.5, noise_w=0.6, pitch=0.84, rms=0.15,
              af='highpass=f=55,equalizer=f=150:t=q:w=1:g=4,aecho=0.8:0.6:35:0.15'),
    'C': dict(model='de_DE-thorsten_emotional-medium', emo='amused', length=0.86, noise=0.7, noise_w=0.9, pitch=1.1, rms=0.12,
              af='highpass=f=260,lowpass=f=3800,equalizer=f=1500:t=q:w=1:g=4'),
    'G': dict(model='de_DE-thorsten_emotional-medium', emo='surprised', length=0.9, noise=0.667, noise_w=0.8, pitch=1.32, rms=0.12),
}
MUSIC = dict(bpm=84, gain=0.11)

LINES = [
    # ---------------- BÜRO, 6 UHR ----------------
    dict(id='a1', spk='T', scene='office', text='Montag. Sechs Uhr.', cues=[(0, 'wake', None)]),
    dict(id='a2', spk='T', scene='office', text='Ich bin todmüde.', cues=[(2, 'todmuede', 'ding')]),
    dict(id='a3', spk='T', scene='office', text='Und ich weiß, wovon ich rede.', gap=0.4),

    # ---------------- TICKETS ----------------
    dict(id='b1', spk='T', scene='inbox', text='{4.812|Viertausendachthundertzwölf} offene Fälle.',
         cues=[(0, 'count', 'tick')]),
    dict(id='b2', spk='T', scene='inbox', text='Und alle wollen persönlich abgeholt werden.',
         cues=[(3, 'persoenlich', None)]),

    # ---------------- MEETING ----------------
    dict(id='c1', spk='C', scene='meeting', text='Guten Morgen, Team! Neue Zielvorgabe: mehr Kundennähe!',
         cues=[(0, 'callIn', 'notif'), (4, 'goal', 'ding')]),
    dict(id='c2', spk='T', scene='meeting', text='Ich bin der Tod. Näher als ich kommt keiner.', gap=0.4,
         cues=[(4, 'naeher', None)]),
    dict(id='c3', spk='C', scene='meeting', text='Super Energie! Kommt ins Protokoll!',
         cues=[(0, 'chat', 'pop')]),

    # ---------------- STRASSE ----------------
    dict(id='d1', spk='G', emo='surprised', scene='street',
         text='Moment! Ich bin tot? Ich hab doch nur kurz aufs Handy geschaut!',
         cues=[(0, 'ghostIn', 'whoosh_s'), (3, 'tot', None)]),
    dict(id='d2', spk='T', scene='street', text='Sie sind heute schon der Dritte. Und es ist erst neun.',
         cues=[(5, 'third', 'ding')]),
    dict(id='d3', spk='G', emo='angry', scene='street', text='Kann ich mich beschweren?'),
    dict(id='d4', spk='T', scene='street', text='Natürlich. Formular {7b.|sieben B.} Bearbeitungszeit: eine Ewigkeit.',
         cues=[(1, 'form', 'pop'), (5, 'ewig', 'stamp')]),

    # ---------------- KÜNDIGUNG ----------------
    dict(id='e1', spk='T', scene='quit', text='Wissen Sie was, Chef? Ich kündige.',
         cues=[(5, 'kuendige', 'stamp')]),
    dict(id='e2', spk='C', scene='quit', text='Kein Problem! Ihre Kündigungsfrist beträgt nur… die Ewigkeit!', gap=0.8,
         cues=[(7, 'infinity', 'stamp')]),
    dict(id='e3', spk='T', scene='quit', text='Ich hol mir noch einen Kaffee.', cues=[(0, 'coffee', None)]),

    # ---------------- OUTRO ----------------
    dict(id='f1', spk='T', scene='outro', text='Und du? Du schaust das hier gerade während der Arbeit?',
         cues=[(0, 'close', 'whoosh_s')]),
    dict(id='f2', spk='T', scene='outro', text='Wir sehen uns.', gap=2.0, cues=[(0, 'glow', 'sting')]),
]
EXTRA_CUES = [('ring', 'a1', 'start', -0.3, 'ring')]
SCENES = ['office', 'inbox', 'meeting', 'street', 'quit', 'outro']
