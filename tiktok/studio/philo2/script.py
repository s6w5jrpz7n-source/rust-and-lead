# PHILOSOPHIE #2: Epiktet (Stoiker, ca. 50–135 n. Chr., als Sklave geboren)
# Bein-Anekdote: Kelsos, überliefert bei Origenes, Contra Celsum VII 53. Lehre: Encheiridion 1 und 5.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import NARR, L  # noqa: E402

ENGINE = 'chatterbox'
SPEAKERS = {'P': NARR['P']}
MUSIC = dict(style='lyra', bpm=72, gain=0.12)
P = 'P'
LINES = [
    L('e1', '^hook:groan Sein Herr verdrehte ihm das Bein. ^ruhig:pluck Er sagte ganz ruhig: Wenn du so weitermachst, brichst du es.', P, gap=0.5),
    L('e2', '^knack:crack Es brach. ^gesagt:ding Und er sagte nur: Hab ich doch gesagt.', P, gap=0.5),
    L('e3', '^name:whoosh_s So erzählt es eine antike Quelle. Der Mann heißt Epiktet. ^sklave:stamp Ein Sklave im Römischen Reich, vor fast {2000|zweitausend} Jahren.', P, gap=0.4),
    L('e4', '^frei:pluck Später kam er frei und wurde einer der berühmtesten Lehrer der Stoa.', P, gap=0.4),
    L('e5', '^satz:whoosh_s Seine wichtigste Lehre passt in einen Satz: Manche Dinge liegen in unserer Macht. ^nicht:stamp Andere nicht.', P, gap=0.45),
    L('e6', '^ja:pop In deiner Macht: ^j1:pop deine Gedanken. ^j2:pop Deine Entscheidungen. ^j3:pop Wie du reagierst.', P, gap=0.4),
    L('e7', '^nein:pop Nicht in deiner Macht: ^n1:pop das Wetter. ^n2:pop Der Stau. ^n3:pop Was andere über dich denken.', P, gap=0.45),
    L('e8', '^zitat:ding Sein berühmtester Satz: Nicht die Dinge beunruhigen uns, sondern unsere Meinungen über die Dinge.', P, gap=0.5),
    L('e9', '^nehmen:pluck Man konnte ihm alles nehmen. ^f1:pop Seine Freiheit. ^f2:crack Sein Bein. ^ruhe:ding Aber nicht seine Ruhe.', P, gap=0.5),
    L('e10', '^cta:whoosh_s Worüber ärgerst du dich, obwohl du es nicht ändern kannst? Schreib’s in die Kommentare.', P, gap=2.0),
]
SCENES = ['s']
