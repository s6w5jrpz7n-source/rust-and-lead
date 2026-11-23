# GESCHICHTE #1: Charles Joughin, Chefbäcker der Titanic (14./15. April 1912)
# Nach seiner Aussage vor der britischen Untersuchung: Brot (4 Laibe pro Mann) zu den Booten, Platz in Boot 10 nicht genommen,
# Alkohol in der Kabine, Deckstühle über Bord, mit dem Heck ins Wasser "ohne dass der Kopf unterging", ca. 2 h im Wasser,
# im Morgengrauen am umgekippten Faltboot B, dann von einem Rettungsboot aufgenommen. Wassertemperatur ca. −2 °C.
# Historiker halten die 2 Stunden für unwahrscheinlich (Alkohol beschleunigt Unterkühlung) – daher als seine Aussage formuliert.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import NARR, L  # noqa: E402

ENGINE = 'chatterbox'
SPEAKERS = {'H': NARR['H']}
MUSIC = dict(style='drama', bpm=66, gain=0.3)
H = 'H'
LINES = [
    L('j1', '^hook:splash Zwei Stunden im eiskalten Atlantik. ^betr:glug Betrunken. ^ueber:hit Und er hat überlebt. ^sagt:pop Sagt er zumindest.', H, gap=0.5),
    L('j2', '^name:horn Das ist Charles {Joughin,|Dschockin,} Chefbäcker der Titanic. ^datum:type {14. April 1912.|Vierzehnter April neunzehnhundertzwölf.}', H, gap=0.4),
    L('j3', '^eis:groan Das Schiff rammt einen Eisberg. ^brot:pop {Joughin|Dschockin} schickt seine Bäcker mit frischem Brot zu den Rettungsbooten.', H, gap=0.35),
    L('j4', '^boot:whoosh_s Er hilft Frauen und Kindern in die Boote. ^platz:stamp Selbst steigt er nicht ein.', H, gap=0.4),
    L('j5', '^kabine:glug Dann geht er in seine Kabine. Und gönnt sich erst mal ein großes Glas Likör.', H, gap=0.4),
    L('j6', '^stuehle:whoosh Er wirft rund fünfzig Liegestühle ins Meer, als Schwimmhilfen.', H, gap=0.4),
    L('j7', '^heck:groan Als sich das Heck aufrichtet, klettert er ganz nach hinten. ^lift:whoosh Und fährt mit dem Schiff nach unten, wie in einem Aufzug.', H, gap=0.35),
    L('j8', '^kopf:ding Sein Kopf ging dabei nicht mal unter, sagte er später.', H, gap=0.45),
    L('j9', '^grad:hit Das Wasser hat minus zwei Grad. Die meisten überleben darin nur kurze Zeit. ^paddel:splash {Joughin|Dschockin} paddelt einfach weiter. ^zwei:tick Nach eigener Aussage rund zwei Stunden lang.', H, gap=0.4),
    L('j10', '^morgen:ding Im Morgengrauen findet er ein umgekipptes Rettungsboot, klammert sich fest und wird gerettet.', H, gap=0.45),
    L('j11', '^alk:pop Er selbst glaubte: Der Alkohol hat ihn gerettet. ^mythos:stamp Historiker zweifeln. Alkohol lässt dich eher schneller auskühlen. ^raetsel:sting Wie er wirklich überlebte, ist bis heute ein Rätsel.', H, gap=0.6),
    L('j12', '^teaser:drum Aber die unglaublichste Geschichte an Bord gehört einer Stewardess. ^drei:hit Sie überlebte Unglücke auf allen drei Schwesterschiffen. ^teil2:whoosh Ihre Geschichte: in Teil zwei.', H, gap=2.2),
]
SCENES = ['s']
