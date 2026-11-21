# WELTRAUM-QUIZ – 10 Fragen, immer schwerer
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from quizlib import HOST, quiz_lines  # noqa: E402

ENGINE, SPEAKERS = 'chatterbox', HOST
MUSIC = dict(bpm=124, gain=0.16)
# (Frage (Anzeige), gesprochen, Emoji, Antworten, richtig, gesprochene Auflösung)
Q = [
    ('Welcher Planet heißt „der Rote Planet“?', 'Der rote Planet?', '🔴', ['Venus', 'Mars', 'Jupiter'], 1, 'Mars!'),
    ('Welcher Planet ist der größte?', 'Der größte Planet?', '🪐', ['Saturn', 'Neptun', 'Jupiter'], 2, 'Jupiter!'),
    ('Wie viele Planeten hat unser Sonnensystem?', 'Wie viele Planeten?', '☀️', ['7', '8', '9'], 1, 'Acht!'),
    ('Wie lange braucht Sonnenlicht bis zur Erde?', 'Sonnenlicht bis zur Erde?', '⏱️', ['8 Sekunden', '8 Minuten', '8 Stunden'], 1, 'Acht Minuten!'),
    ('Welcher Planet ist der heißeste?', 'Der heißeste Planet?', '🔥', ['Merkur', 'Venus', 'Mars'], 1, 'Venus! Nicht Merkur.'),
    ('Welcher Planet hat die meisten bekannten Monde?', 'Die meisten Monde?', '🌙', ['Saturn', 'Jupiter', 'Uranus'], 0, 'Saturn!'),
    ('Wie heißt der größte Vulkan im Sonnensystem?', 'Der größte Vulkan?', '🌋', ['Mauna Kea', 'Ätna', 'Olympus Mons'], 2, 'Olympus Mons, auf dem Mars!'),
    ('Wie heißt der größte Mond im Sonnensystem?', 'Der größte Mond?', '🌕', ['Titan', 'Ganymed', 'Europa'], 1, 'Ganymed!'),
    ('Welcher Stern ist der Sonne am nächsten?', 'Der nächste Stern?', '⭐', ['Sirius', 'Proxima Centauri', 'Polarstern'], 1, 'Proxima Centauri!'),
    ('Wie heißt die Grenze, ab der offiziell das Weltall beginnt?', 'Wo beginnt das Weltall?', '🚀',
     ['Kármán-Linie', 'Roche-Grenze', 'Van-Allen-Gürtel'], 0, 'Die Karman-Linie! In hundert Kilometern Höhe.'),
]
LINES, EXTRA_CUES = quiz_lines('Zehn Fragen zum Weltall. Immer schwerer. Wer alle zehn schafft, ist ein Genie. Los geht’s!',
                               [dict(say=s, answer=a) for _, s, _, _, _, a in Q])
SCENES = ['quiz']
EXPORT = dict(
    title='WELTRAUM-QUIZ', sub='Nur Genies schaffen 10/10', theme=['#0b0f2e', '#000004'], hot=['#2b0a2e', '#08000c'], stars=True,
    ratings=[['0–4', 'Erdling'], ['5–7', 'Astronaut'], ['8–9', 'Astrophysiker'], ['10', 'GENIE']],
    questions=[dict(text=t, visual=dict(type='emoji', e=e), opts=o, right=r) for t, _, e, o, r, _ in Q],
)
