# COMEDY (Archivfilm): „Familienessen 1950 – ehrlich synchronisiert“
# Bildquelle: „A Date With Your Family“ (1950), Prelinger Archives, gemeinfrei (archive.org/details/DateWith1950).
# SHOTS: pro Zeile Liste von (Quell-Start, Quell-Ende) in Sekunden; reicht das Material nicht, steht das letzte Bild.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402

ENGINE = 'chatterbox'
RADIO = 'highpass=f=220,lowpass=f=4200,equalizer=f=1800:t=q:w=1:g=3'
FILM = 'highpass=f=160,lowpass=f=6000'
SPEAKERS = {
    'N': dict(model='de_DE-thorsten-high', ref='refs/host.wav', exag=0.8, cfg=0.45, rms=0.15, af=RADIO),
    'V': dict(model='de_DE-thorsten-high', ref='refs/uwe.wav', exag=0.6, cfg=0.5, rms=0.14, af=FILM),
    'S': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.7, cfg=0.45, rms=0.14, af=FILM),
    'T': dict(model='de_DE-thorsten-high', ref='refs/sabine.wav', exag=0.8, cfg=0.45, rms=0.14, af=FILM),
    'K': dict(model='de_DE-thorsten-high', ref='refs/kevin.wav', exag=0.7, cfg=0.45, rms=0.14, pitch=1.45, af=FILM),
}
MUSIC = dict(style='retro', bpm=132, gain=0.16)
LINES = [
    L('c1', '^hook:pop So sah ein perfektes Familienessen {1950|neunzehnhundertfünfzig} aus. ^ang:recscratch Angeblich.', 'N', gap=0.45),
    L('c2', 'Vater kommt von der Arbeit. Acht Stunden im Büro. ^nix:ding Gemacht hat er genau nichts.', 'N', gap=0.35),
    L('c3', 'Papa, warum ist Mama immer so müde?', 'K', gap=0.3),
    L('c4', '^ehe:rimshot Weil sie mit mir verheiratet ist.', 'V', gap=0.9),
    L('c5', 'Lieber Gott, lass heute bitte keinen über Politik reden.', 'V', gap=0.35),
    L('c6', 'Dann verteilt Vater das Essen. Das größte Stück kriegt das Lieblingskind. ^alle:ding Alle wissen, wer es ist.', 'N', gap=0.35),
    L('c7', 'Der Sohn starrt auf seinen Schoß. Er hat noch kein Handy. ^uebt:rimshot Aber er übt schon mal.', 'N', gap=0.8),
    L('c8', '^studium:pop Ich hab übrigens mein Studium abgebrochen.', 'S', gap=0.35),
    L('c9', 'Vater kaut einfach weiter. ^fussball:pop Gefühle zeigt er nur beim Fußball.', 'N', gap=0.35),
    L('c10', '^tor:pop Und ich hab beim Einparken das Garagentor mitgenommen.', 'T', gap=0.25),
    L('c11', '^still:recscratch Stille.', 'N', gap=1.6),
    L('c12', 'Hahaha. ^erbe:stamp Ihr seid beide enterbt.', 'V', gap=0.5),
    L('c13', 'Zum Nachtisch gibt es Kuchen. Und Schweigen. ^weih:ding Bis Weihnachten.', 'N', gap=0.5),
    L('c14', '^cta:pop Schick das in deine Familiengruppe. Mal sehen, wer zuerst reagiert.', 'N', gap=2.0),
]
SCENES = ['s']
EXPORT = dict(src='DateWith1950.mp4', shots={
    'c1': [(286, 296)], 'c2': [(183, 197)], 'c3': [(244, 247)], 'c4': [(247, 252)], 'c5': [(306, 311)],
    'c6': [(311, 323)], 'c7': [(400, 403), (422, 425)], 'c8': [(441, 446)], 'c9': [(425, 432)],
    'c10': [(452, 458)], 'c11': [(472.5, 476)], 'c12': [(518, 524)], 'c13': [(540, 550)], 'c14': [(592, 597)],
}, zoom={'c4': 1.12, 'c11': 1.25, 'c12': 1.15, 'c8': 1.08},
   stickers={'c4': '💍', 'c7': '📱', 'c8': '🎓❌', 'c10': '🚗💥', 'c11': '😬', 'c12': '💸', 'c13': '🍰'},
   names={'V': 'Vater', 'S': 'Sohn', 'T': 'Tochter', 'K': 'der Kleine'})
