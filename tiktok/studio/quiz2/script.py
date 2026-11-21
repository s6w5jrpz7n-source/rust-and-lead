# FLAGGEN-QUIZ – 10 Flaggen, immer schwerer
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from quizlib import HOST, ZAHL, quiz_lines  # noqa: E402

ENGINE, SPEAKERS = 'chatterbox', HOST
MUSIC = dict(bpm=128, gain=0.16)
# (Flaggen-ID, Antworten, richtig, gesprochene Auflösung)
Q = [
    ('JPN', ['China', 'Japan', 'Südkorea'], 1, 'Japan!'),
    ('ITA', ['Irland', 'Mexiko', 'Italien'], 2, 'Italien!'),
    ('CHE', ['Schweiz', 'Dänemark', 'Österreich'], 0, 'Die Schweiz!'),
    ('SWE', ['Norwegen', 'Schweden', 'Finnland'], 1, 'Schweden!'),
    ('GRC', ['Uruguay', 'Israel', 'Griechenland'], 2, 'Griechenland!'),
    ('COL', ['Kolumbien', 'Ecuador', 'Venezuela'], 0, 'Kolumbien!'),
    ('BGD', ['Japan', 'Bangladesch', 'Palau'], 1, 'Bangladesch!'),
    ('SYC', ['Mauritius', 'Komoren', 'Seychellen'], 2, 'Die Seychellen!'),
    ('NPL', ['Bhutan', 'Nepal', 'Sri Lanka'], 1, 'Nepal!'),
    ('MCO', ['Indonesien', 'Polen', 'Monaco'], 2, 'Monaco! Indonesiens Flagge ist breiter.'),
]
LINES, EXTRA_CUES = quiz_lines('Zehn Flaggen. Jede schwerer als die davor. Wer alle zehn erkennt, ist ein Genie. Los geht’s!',
                               [dict(say=f'Flagge {ZAHL[i]}!', answer=a, qextra=dict(seed=11) if i in (2, 5) else {})
                                for i, (_, _, _, a) in enumerate(Q)])
SCENES = ['quiz']
EXPORT = dict(
    title='FLAGGEN-QUIZ', sub='Nur Genies schaffen 10/10', theme=['#12204a', '#060b24'], hot=['#3b0a1e', '#170410'],
    ratings=[['0–4', 'Tourist'], ['5–7', 'Weltenbummler'], ['8–9', 'Diplomat'], ['10', 'GENIE']],
    questions=[dict(text='Welches Land?', visual=dict(type='flag', id=f), opts=o, right=r) for f, o, r, _ in Q],
)
