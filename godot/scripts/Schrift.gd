extends RefCounted
## Die Schrift des Spiels — an einer Stelle, damit sie niemand umgeht.
##
## ## Warum es diese drei Zeilen gibt
##
## `ThemeDB.fallback_font` ist NICHT die eingestellte Schrift, sondern Godots eingebaute
## Notloesung. Wer sie in `draw_string()` steckt, bekommt auf dem Rechner zufaellig etwas
## Lesbares und auf dem Telefon leere Kaestchen — und merkt es erst dort. Das ist in diesem
## Projekt schon einmal in fuenf Dateien gleichzeitig passiert; seitdem sucht
## `TestRunner._test_zeichen()` den Namen im Quelltext und laesst den Lauf rot werden.
##
## `get_theme_default_font()` waere die richtige Antwort — aber die Methode gehoert `Control`,
## und die Buehne des Abenteuers ist ein `Node2D`. Also wird die Datei geladen, die auch in
## `project.godot` unter `gui/theme/custom_font` steht. Einmal, und dann gemerkt.

const PFAD: String = "res://assets/fonts/DejaVuSans.ttf"

static var _gemerkt: Font = null


## Die Projektschrift.
static func schrift() -> Font:
	if _gemerkt == null:
		if ResourceLoader.exists(PFAD):
			_gemerkt = load(PFAD) as Font
		else:
			# Ohne Datei lieber Godots Vorgabe als gar nichts: Ein Spiel ohne Schrift ist
			# unbedienbar, eines mit der falschen nur haesslich.
			_gemerkt = ThemeDB.get_default_theme().default_font
	return _gemerkt
