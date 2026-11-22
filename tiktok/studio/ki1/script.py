# KI-VIDEO: „Ich lasse eine KI meine TikToks machen“ – Blick hinter die Kulissen dieses Studios.
# Bildmaterial: Ausschnitte aus eigenen, hier erzeugten Videos (build/ki1/clips via ki1/clips.py).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from storylib import L  # noqa: E402
ENGINE = 'chatterbox'
SPEAKERS = {'N': dict(model='de_DE-thorsten-high', ref='refs/host.wav', exag=0.65, cfg=0.45, rms=0.15, af='highpass=f=70,equalizer=f=3000:t=q:w=1:g=2')}
MUSIC = dict(bpm=112, gain=0.12)
LINES = [
    L('ki1', '^hook:type Ich schreibe einen einzigen Satz. ^boom:hit Und eine {KI|Ka-I} macht daraus ein komplettes Video.', 'N', gap=0.3),
    L('ki2', '^mont:whoosh_s Keins dieser Videos hat ein Mensch gezeichnet. ^stimme0:pop Und keins hat ein Mensch gesprochen.', 'N', gap=0.35),
    L('ki3', '^claude:ding Die {KI|Ka-I} heißt {Claude|Klohd}. Ich sage nur, was ich will. ^bsp:type Zum Beispiel: Mach ein Video über Autos, die sich helfen.', 'N', gap=0.35),
    L('ki4', '^skript:whoosh_s Schritt eins: {Claude|Klohd} schreibt das {Drehbuch.|Dreh-Buch.}', 'N', gap=0.3),
    L('ki5', '^code:whoosh_s Schritt zwei: {Claude|Klohd} zeichnet jede Figur. ^pinsel:pop Nicht mit dem Pinsel, sondern programmiert.', 'N', gap=0.3),
    L('ki6', '^stimme:whoosh_s Schritt drei: Die Stimmen kommen von einem kostenlosen {KI-Sprachmodell.|Ka-I-Sprachmodell.} ^musik:ding Musik und Geräusche programmiert {Claude|Klohd} gleich mit.', 'N', gap=0.3),
    L('ki7', '^render:whoosh_s Schritt vier: {Claude|Klohd} setzt alles Bild für Bild zu einem Video zusammen. ^fps:tick Dreißig Bilder pro Sekunde.', 'N', gap=0.35),
    L('ki8', '^fix:pop Und wenn mir was nicht gefällt, sage ich einfach: ^groesser:boing Mach die Autos größer.', 'N', gap=0.5),
    L('ki9', '^fast:hit Komplett ohne Arbeit? Fast. ^post:pop Posten muss ich noch selbst.', 'N', gap=0.4),
    L('ki10', '^cta:tada Was soll {Claude|Klohd} als Nächstes machen? Schreib’s in die Kommentare!', 'N', gap=2.0),
]
SCENES = ['s']
EXPORT = dict(montage=['katze', 'philo', 'hist', 'hell', 'iw', 'quiz', 'emc', 'auto'])
