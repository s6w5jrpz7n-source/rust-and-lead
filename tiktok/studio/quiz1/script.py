# HAUPTSTÄDTE-QUIZ – 10 Fragen, immer schwerer. Wer alle 10 schafft, ist ein Genie.
# spk: Q = Quizmaster  |  Textsyntax: {Anzeige|gesprochen}

ENGINE = 'chatterbox'
SPEAKERS = {
    'Q': dict(model='de_DE-thorsten-high', ref='refs/host.wav', exag=0.75, cfg=0.5, length=1.0, noise=0.5, noise_w=0.6,
              rms=0.15, af='highpass=f=70,equalizer=f=3000:t=q:w=1:g=2'),
}
MUSIC = dict(bpm=128, gain=0.16)
COUNTDOWN = 2.3

# (Land, ISO-A3, richtige Antwort (Anzeige|gesprochen), Antworten A/B/C, Index der richtigen)
QUESTIONS = [
    ('Frankreich', 'FRA', 'Paris', ['Lyon', 'Paris', 'Marseille'], 1),
    ('Italien', 'ITA', 'Rom', ['Rom', 'Mailand', 'Neapel'], 0),
    ('Spanien', 'ESP', 'Madrid', ['Barcelona', 'Sevilla', 'Madrid'], 2),
    ('Kanada', 'CAN', 'Ottawa', ['Toronto', 'Ottawa', 'Vancouver'], 1),
    ('Australien', 'AUS', '{Canberra!|Kenberra!}', ['Canberra', 'Sydney', 'Melbourne'], 0),
    ('Türkei', 'TUR', 'Ankara', ['Istanbul', 'Izmir', 'Ankara'], 2),
    ('Brasilien', 'BRA', 'Brasília', ['Rio de Janeiro', 'Brasília', 'São Paulo'], 1),
    ('Kasachstan', 'KAZ', 'Astana', ['Astana', 'Almaty', 'Schymkent'], 0),
    ('Myanmar', 'MMR', '{Naypyidaw!|Nepjidoh!}', ['Rangun', 'Mandalay', 'Naypyidaw'], 2),
    ('Burkina Faso', 'BFA', '{Ouagadougou!|Wagadugu!}', ['Bamako', 'Ouagadougou', 'Niamey'], 1),
]

LINES = [dict(id='intro', spk='Q', scene='quiz', text='Zehn Hauptstädte. Jede schwerer als die davor. Wer alle zehn schafft, ist ein Genie. Los geht’s!',
              gap=0.35, cues=[(0, 'title', 'hit'), (8, 'genie', 'ding'), (12, 'go', 'whoosh')])]
EXTRA_CUES = []
for i, (land, iso, ans, opts, k) in enumerate(QUESTIONS, 1):
    if i == 8:
        LINES.append(dict(id='h8', spk='Q', scene='quiz', text='Jetzt wird’s schwer.', gap=0.15, cues=[(0, 'hard', 'hit')]))
    if i == 10:
        LINES.append(dict(id='h10', spk='Q', scene='quiz', text='Letzte Frage. Nur für Genies.', gap=0.15, cues=[(0, 'last', 'hit')]))
    q = '{Türkei?|Die Türkei?}' if land == 'Türkei' else f'{land}?'
    extra = dict(exag=0.45, seed=7) if land == 'Burkina Faso' else {}
    LINES.append(dict(id=f'q{i}', spk='Q', scene='quiz', text=q, gap=COUNTDOWN, cues=[(0, f'q{i}', 'whoosh_s')], **extra))
    a = ans if '{' in ans else f'{ans}!'
    LINES.append(dict(id=f'a{i}', spk='Q', scene='quiz', text=a, gap=0.4, cues=[(0, f'a{i}', 'ding')]))
    EXTRA_CUES += [(f'tk{i}_{j}', f'q{i}', 'end', 0.12 + j * 0.72, 'tick') for j in range(3)]
LINES.append(dict(id='o1', spk='Q', scene='quiz', text='Wie viele hattest du? Schreib’s in die Kommentare!', gap=2.6,
                  cues=[(0, 'outro', 'tada')]))
SCENES = ['quiz']
