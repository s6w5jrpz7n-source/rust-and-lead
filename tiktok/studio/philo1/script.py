# PHILOSOPHIE #1: Diogenes von Sinope (Kyniker, ca. 400–323 v. Chr.)
# Quellen der Anekdoten: Diogenes Laertios VI (Tonkrug, Schale, Platons Huhn, Laterne), Plutarch, Alexander 14 (Sonne, "Wäre ich nicht Alexander …").
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import NARR, L  # noqa: E402

ENGINE = 'chatterbox'
SPEAKERS = {'P': NARR['P']}
MUSIC = dict(style='lyra', bpm=76, gain=0.12)
P = 'P'
LINES = [
    L('d1', '^hook:hit Alexander der Große bot ihm jeden Wunsch an. Und er sagte nur: ^sonne:pluck Geh mir aus der Sonne.', P, gap=0.5),
    L('d2', '^name:whoosh_s Das ist Diogenes. ^title:pluck Der frechste Philosoph der Geschichte.', P, gap=0.4),
    L('d3', '^tonne:pop Er lebte in einer Tonne. ^krug:pop Na ja, eigentlich in einem riesigen Tonkrug.', P),
    L('d4', '^besitz:pop Er besaß nur einen Mantel und eine Schale. ^kind:pop Dann sah er ein Kind, das mit den Händen trank. ^weg:smash Und warf die Schale weg.', P, gap=0.4),
    L('d5', '^platon:whoosh_s Platon nannte den Menschen ein federloses Wesen auf zwei Beinen. ^huhn:boing Da rupfte Diogenes ein Huhn und rief: ^seht:hit Seht her, Platons Mensch!', P, gap=0.45),
    L('d7', '^alex:drum Dann kam, der Legende nach, Alexander der Große. ^wunsch:ding Er sagte: Wünsch dir, was du willst.', P, gap=0.5),
    L('d8', '^blinz:pop Diogenes blinzelte nur hoch. ^aus:stamp Geh mir ein bisschen aus der Sonne.', P, gap=0.5),
    L('d9', '^staun:whoosh_s Alexander soll gesagt haben: Wäre ich nicht Alexander, ^wollte:ding wollte ich Diogenes sein.', P, gap=0.5),
    L('d10', '^lehre:pluck Seine Idee: Wer wenig braucht, ist frei. ^sklave:stamp Wer alles haben will, wird zum Sklaven seiner Wünsche.', P, gap=0.5),
    L('d11', '^cta:whoosh_s Was könntest du weglassen? Schreib’s in die Kommentare.', P, gap=2.0),
]
SCENES = ['s']
