# KÖRPER-QUIZ – 10 Fragen zum menschlichen Körper, immer schwerer
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from quizlib import HOST, quiz_lines  # noqa: E402

ENGINE, SPEAKERS = 'chatterbox', HOST
MUSIC = dict(bpm=126, gain=0.16)
Q = [
    ('Was ist das größte Organ des Menschen?', 'Das größte Organ?', '🧍', ['Leber', 'Haut', 'Lunge'], 1, 'Die Haut!'),
    ('Wie viele Zähne hat ein Erwachsener – mit Weisheitszähnen?', 'Wie viele Zähne?', '🦷', ['28', '32', '36'], 1, 'Zweiunddreißig!'),
    ('Wie viele Knochen hat ein erwachsener Mensch?', 'Wie viele Knochen?', '🦴', ['106', '206', '306'], 1, 'Zweihundertsechs!'),
    ('Wie oft schlägt dein Herz ungefähr pro Tag?', 'Herzschläge pro Tag?', '🫀', ['10.000', '100.000', '1 Million'], 1, 'Rund hunderttausend Mal!'),
    ('Welches Organ kann nachwachsen?', 'Welches Organ wächst nach?', '🔁', ['Niere', 'Herz', 'Leber'], 2, 'Die Leber!'),
    ('Wie heißt der kleinste Knochen im Körper?', 'Der kleinste Knochen?', '👂', ['Hammer', 'Steigbügel', 'Amboss'], 1, 'Der Steigbügel, im Ohr!'),
    ('Welche Blutgruppe ist der Universalspender?', 'Der Universalspender?', '🩸', ['AB positiv', '0 negativ', 'A negativ'], 1, 'Null negativ!'),
    ('Wie heißt der Oberschenkelknochen?', 'Der Oberschenkelknochen?', '🦵', ['Humerus', 'Tibia', 'Femur'], 2, 'Femur!'),
    ('Welcher Teil des Gehirns steuert das Gleichgewicht?', 'Was steuert das Gleichgewicht?', '🧠', ['Kleinhirn', 'Großhirn', 'Hypothalamus'], 0, 'Das Kleinhirn!'),
    ('Wie lang sind alle deine Blutgefäße zusammen?', 'Alle Blutgefäße zusammen?', '🌍', ['1.000 km', '10.000 km', '100.000 km'], 2, 'Rund hunderttausend Kilometer! Zweimal um die Erde.'),
]
LINES, EXTRA_CUES = quiz_lines('Zehn Fragen zu deinem Körper. Immer schwerer. Wer alle zehn schafft, ist ein Genie. Los geht’s!',
                               [dict(say=s, answer=a) for _, s, _, _, _, a in Q])
SCENES = ['quiz']
EXPORT = dict(
    title='KÖRPER-QUIZ', sub='Nur Genies schaffen 10/10', theme=['#0b3a3f', '#03161a'], hot=['#3b0a1e', '#170410'],
    ratings=[['0–4', 'Patient'], ['5–7', 'Sanitäter'], ['8–9', 'Chefarzt'], ['10', 'GENIE']],
    questions=[dict(text=t, visual=dict(type='emoji', e=e), opts=o, right=r) for t, _, e, o, r, _ in Q],
)
