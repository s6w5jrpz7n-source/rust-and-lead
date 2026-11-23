# GESCHICHTE #2: Violet Jessop (1887–1971), "Miss Unsinkable"
# Olympic–HMS Hawke-Kollision 20.09.1911 (keine Toten); Titanic 15.04.1912 (Boot 16, Baby); Britannic 21.11.1916 (Mine, 55 min,
# Boot in die Schrauben gezogen, Kopf am Kiel; Zahnbürste). Danach bis 1950 auf See, gestorben 1971 mit 83 in Suffolk.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import NARR, L  # noqa: E402

ENGINE = 'chatterbox'
SPEAKERS = {'H': NARR['H']}
MUSIC = dict(style='drama', bpm=66, gain=0.3)
H = 'H'
LINES = [
    L('v1', '^hook:hit Diese Frau überlebte den Untergang der Titanic. ^zwei:stamp Und das war erst ihr zweites Schiffsunglück.', H, gap=0.5),
    L('v2', '^name:horn Violet {Jessop,|Dschessop,} Stewardess. ^spitz:ding Spitzname: die Unsinkbare.', H, gap=0.5),
    L('v3', '^u1:whoosh Unglück eins: {1911.|Neunzehnhundertelf.} Die {Olympic,|Olümpik,} Schwesterschiff der Titanic, ^crash:boom kollidiert mit einem Kriegsschiff. Violet ist an Bord. ^alle:ding Alle überleben.', H, gap=0.5),
    L('v4', '^u2:whoosh Unglück zwei: sieben Monate später, die Titanic. ^boot:splash Violet kommt in Rettungsboot {16.|sechzehn.} ^baby:pop Ein Offizier drückt ihr ein Baby in die Arme.', H, gap=0.4),
    L('v5', '^morgen:horn Am nächsten Morgen, auf dem Rettungsschiff, ^weg:whoosh_s reißt ihr eine Frau das Baby aus den Armen. ^wort:stamp Ohne ein Wort.', H, gap=0.5),
    L('v6', '^u3:whoosh Unglück drei: Erster Weltkrieg. Violet ist Krankenschwester auf dem dritten Schwesterschiff, der {Britannic.|Britannik.} ^laz:pop Jetzt ein Lazarettschiff.', H, gap=0.4),
    L('v7', '^datum:type {21. November 1916.|Einundzwanzigster November neunzehnhundertsechzehn.} ^boom:boom Eine Explosion, wahrscheinlich eine Seemine. ^min:tick Das Schiff sinkt in {55|fünfundfünfzig} Minuten.', H, gap=0.4),
    L('v8', '^zahn:pop Violet rennt zurück in ihre Kabine. Und holt ihre Zahnbürste. ^vermisst:ding Die hatte sie nach der Titanic am meisten vermisst.', H, gap=0.4),
    L('v9', '^schraube:groan Ihr Rettungsboot wird in die Schiffsschrauben gezogen. ^spring:splash Violet springt, ^sog:bubbles wird unter Wasser gesogen ^kopf:hit und schlägt mit dem Kopf gegen den Kiel.', H, gap=0.5),
    L('v10', '^ueberlebt:ding Sie überlebt. ^haare:pop Ihre dicken Haare hätten den Schlag abgefedert, sagte sie.', H, gap=0.5),
    L('v11', '^danach:whoosh_s Danach fährt sie noch über vierzig Jahre zur See. ^tod:ding Sie stirbt {1971,|neunzehnhunderteinundsiebzig,} mit {83.|dreiundachtzig.} ^land:pop An Land.', H, gap=0.6),
    L('v12', '^cta:whoosh_s Wärst du nach der Titanic noch mal auf ein Schiff gestiegen? Schreib’s in die Kommentare.', H, gap=2.0),
]
SCENES = ['s']
next(l for l in LINES if l['id'] == 'v4')['seed'] = 7  # neuer Take: „Unglück zwei“ war undeutlich
