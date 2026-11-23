# KLARTEXT #2 – Wohnungsanzeigen, ehrlich übersetzt
# spk: H = gut gelaunte Makler-Stimme, N = zynischer Übersetzer
# Textsyntax: {Anzeige|gesprochen}; *Wort* = rot hervorgehoben  |  cues: (Wortindex, Cue-Name, SFX oder None)

SPEAKERS = {
    'N': dict(model='de_DE-thorsten-high', length=1.0, noise=0.45, noise_w=0.6, pitch=None, rms=0.14,
              af='highpass=f=70,equalizer=f=180:t=q:w=1:g=3,equalizer=f=3000:t=q:w=1:g=2'),
    'H': dict(model='de_DE-thorsten_emotional-medium', emo='amused', length=0.86, noise=0.7, noise_w=0.9, pitch=1.14, rms=0.12),
}
MUSIC = dict(bpm=92, gain=0.17)

ITEMS = [
    ('Gemütlich.', 'Klein. *Sehr* klein.'),
    ('Zentrale Lage.', 'Hauptstraße. Die Fenster bleiben *zu.*'),
    ('Altbaucharme.', 'Schimmel mit *Geschichte.*'),
    ('Lichtdurchflutet.', 'Im Sommer {*38 Grad.*|achtunddreißig Grad.}'),
    ('Teilmöbliert.', 'Ein Stuhl. Er *wackelt.*'),
    ('Ablöse für die Einbauküche: {4.000 €.|viertausend Euro.}', 'Für eine Herdplatte. Die *nicht geht.*'),
    ('Besichtigung am Samstag.', 'Du und {*80*|achtzig} andere.'),
    ('Wir melden uns!', 'Die Wohnung kriegt der *Neffe* vom Vermieter.'),
]

LINES = [dict(id='k0', spk='N', scene='hook', text='Wohnungsanzeigen. Ehrlich übersetzt.', gap=0.45,
              cues=[(0, 'k0', None), (1, 'honest', 'glitch')])]
for i, (ad, real) in enumerate(ITEMS, 1):
    LINES.append(dict(id=f'i{i}', spk='H', scene='deck', text=ad, gap=0.18, cues=[(0, f'i{i}', 'type')]))
    LINES.append(dict(id=f'r{i}', spk='N', scene='deck', text=real, gap=0.9 if i == len(ITEMS) else 0.72,
                      cues=[(0, f'r{i}', 'glitch')]))
LINES += [
    dict(id='o1', spk='N', scene='outro', text='Schick das jemandem auf Wohnungssuche.', gap=0.35, cues=[(0, 'o1', 'hit')]),
    dict(id='o2', spk='N', scene='outro', text='Es liegt nicht an dir. Nur am Markt. Und an deinem *Gehalt.*', gap=1.9,
         cues=[(5, 'cv', 'type')]),
]
EXTRA_CUES = [('notif', f'r{len(ITEMS)}', 'end', -0.35, 'notif')]
SCENES = ['hook', 'deck', 'outro']
