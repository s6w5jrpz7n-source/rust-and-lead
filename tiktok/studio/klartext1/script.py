# KLARTEXT #1 – Stellenanzeigen, ehrlich übersetzt
# spk: H = übermotivierte HR-Stimme, N = zynischer Übersetzer
# Textsyntax: {Anzeige|gesprochen}; *Wort* = rot hervorgehoben  |  cues: (Wortindex, Cue-Name, SFX oder None)

SPEAKERS = {
    'N': dict(model='de_DE-thorsten-high', length=1.0, noise=0.45, noise_w=0.6, pitch=None, rms=0.14,
              af='highpass=f=70,equalizer=f=180:t=q:w=1:g=3,equalizer=f=3000:t=q:w=1:g=2'),
    'H': dict(model='de_DE-thorsten_emotional-medium', emo='amused', length=0.86, noise=0.7, noise_w=0.9, pitch=1.14, rms=0.12),
}
MUSIC = dict(bpm=98, gain=0.17)

ITEMS = [
    ('Wir sind wie eine Familie.', 'Wir zahlen schlecht. Aber mit *Liebe.*'),
    ('Flache Hierarchien.', 'Keiner ist zuständig. Aber *du* bist schuld.'),
    ('Ein dynamisches Umfeld.', 'Chaos. Seit {*19*|neunzehn} Jahren.'),
    ('Hohe Eigenverantwortung.', 'Es gibt *keine* Einarbeitung.'),
    ('Belastbarkeit.', 'Überstunden. *Unbezahlt.*'),
    ('Ein wettbewerbsfähiges Gehalt.', 'Weniger, als du denkst. Und du denkst schon *wenig.*'),
    ('Obstkorb und kostenloser Kaffee.', 'Das ist deine *Gehaltserhöhung.*'),
    ('Wir freuen uns auf deine Bewerbung!', 'Die automatische Absage kommt in {*8*|acht} *Monaten.*'),
]


LINES = [dict(id='k0', spk='N', scene='hook', text='Stellenanzeigen. Ehrlich übersetzt.', gap=0.45,
              cues=[(0, 'k0', None), (1, 'honest', 'glitch')])]
for i, (hr, real) in enumerate(ITEMS, 1):
    LINES.append(dict(id=f'i{i}', spk='H', scene='deck', text=hr, gap=0.18, cues=[(0, f'i{i}', 'type')]))
    LINES.append(dict(id=f'r{i}', spk='N', scene='deck', text=real, gap=0.75 if i == len(ITEMS) else 0.5,
                      cues=[(0, f'r{i}', 'glitch')]))
LINES += [
    dict(id='o1', spk='N', scene='outro', text='Schick das deinem Chef.', gap=0.35, cues=[(0, 'o1', 'hit')]),
    dict(id='o2', spk='N', scene='outro', text='Und dann aktualisier deinen Lebenslauf.', gap=1.9, cues=[(4, 'cv', 'type')]),
]
EXTRA_CUES = [('notif', f'r{len(ITEMS)}', 'end', -0.35, 'notif')]
SCENES = ['hook', 'deck', 'outro']
