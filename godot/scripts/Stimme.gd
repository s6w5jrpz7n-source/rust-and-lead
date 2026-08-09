class_name Stimme
## Wo die gesprochene Fassung einer Sprechzeile liegt — und wie man sie findet.
##
## ## Der Text IST der Schluessel
##
## Es gibt keine Zuordnungstabelle. Die Kennung einer Zeile ist der SHA-256 ihres Textes, auf
## zwoelf Stellen gekuerzt; die Tondatei heisst danach. Das Spiel hat den Text ohnehin in der
## Hand, wenn es ihn anzeigt — es kann die Datei also ausrechnen, statt sie nachzuschlagen.
##
## Das hat drei Folgen, und alle drei sind der Grund dafuer:
##
##  * **Keine Kennungen im Quelltext.** Kein Durchnummerieren, keine Zeile, die beim Verschieben
##    ihre Nummer verliert, keine zweite Datei, die mit der ersten synchron gehalten werden muss.
##
##  * **Eine geaenderte Zeile verliert ihre Aufnahme.** Wer den Text umschreibt, bekommt eine
##    neue Kennung, die alte Datei wird nicht mehr gefunden, und die Figur schweigt, waehrend
##    der neue Satz auf der Tafel steht. Das ist genau richtig herum. Die Alternative — dieselbe
##    Datei bleibt zugeordnet — hiesse: Sie spricht den ALTEN Satz, waehrend der neue dasteht,
##    und das faellt beim Testen niemandem auf, weil man auf die Schrift sieht und nicht hoert.
##
##  * **Derselbe Satz an zwei Stellen ist EINE Aufnahme.** Nicht aus Sparsamkeit, sondern weil
##    es gar keine zweite geben kann.
##
## ## Ohne Ton faellt nichts aus
##
## `hat()` ist falsch, solange keine Datei da ist, und dann laeuft alles wie bisher: Die Tafel
## zeigt den Text, die Anzeigedauer kommt aus `speech_dauer`. Das Spiel ist zu keinem Zeitpunkt
## darauf angewiesen, dass vertont wurde — es ist immer nur eine Zeile weiter vertont als
## vorher.
##
## ## Erzeugt wird das anderswo
##
##   python3 docs/build_spiel_stimmen.py     # Zeilen aus dem Quelltext einsammeln
##   python3 docs/azure_tts.py --spiel       # rendern nach assets/voice/

const ORDNER: String = "res://assets/voice/"
## MP3 und nicht Ogg: Godot spielt Ogg **Vorbis**, Azure liefert Ogg **Opus** — zwei Formate mit
## demselben Behaeltnis, und das eine kann Godot nicht. MP3 koennen beide, also entfaellt ein
## Umwandlungsschritt, den sonst jeder einzeln haette machen muessen.
const ENDUNG: String = ".mp3"


## Die Kennung einer Zeile.
##
## Muss Zeichen fuer Zeichen dasselbe liefern wie `kennung()` in
## `docs/build_spiel_stimmen.py` — beide hashen die UTF-8-Bytes des Textes mit SHA-256 und
## nehmen die ersten zwoelf Stellen. Der Test rechnet das an bekannten Werten nach; wenn diese
## beiden je auseinanderlaufen, sucht das Spiel Dateien, die es nicht gibt, und niemand sieht
## warum — es ist einfach still.
static func kennung(text: String) -> String:
	return text.sha256_text().substr(0, 12)


static func pfad(text: String) -> String:
	return ORDNER + kennung(text) + ENDUNG


## Gibt es zu dieser Zeile eine Aufnahme?
static func hat(text: String) -> bool:
	return ResourceLoader.exists(pfad(text))


## Die Aufnahme, oder `null`.
static func laden(text: String) -> AudioStream:
	var p: String = pfad(text)
	if not ResourceLoader.exists(p):
		return null
	return load(p) as AudioStream
