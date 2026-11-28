extends CanvasLayer
## Das Gespräch — Portrait, gesprochener Satz, und eine Reihe Sinnbilder zur Auswahl.
##
## ## Der Aufbau ist der von Baphomets Fluch
##
##     ┌──────────────────────────────────────────────────────┐
##     │                                                      │
##     │   (das Bühnenbild bleibt sichtbar, nur abgedunkelt)  │
##     │                                                      │
##     │  ┌────────┐                                          │
##     │  │Portrait│  „Du siehst aus wie durchgekaut und       │
##     │  │        │   wieder ausgespuckt.“                    │
##     │  └────────┘                                          │
##     │  ( ? ) ( M ) ( ✦ ) ( ⌷ )      ← Sinnbilder mit Text   │
##     └──────────────────────────────────────────────────────┘
##
## Entscheidend ist, was **nicht** passiert: Das Bild wird nicht ersetzt. Fallout 2 blendet für
## Gespräche auf einen eigenen Schirm um; Baphomets Fluch lässt den Ort stehen und legt nur
## Text und Auswahl darüber. Man sieht also weiter, wo man ist und wer sonst noch dasteht — und
## genau deshalb fühlt sich ein Gespräch dort wie ein Teil der Szene an und nicht wie ein Menü.
##
## ## Die Stimme kommt umsonst
##
## `Stimme.hat(text)` prüft, ob zu diesem Satz eine Aufnahme existiert — der Dateiname ist der
## SHA-256 des Textes. Alle Sätze, die aus `DialogData` übernommen wurden, sind damit vertont,
## ohne dass hier etwas zuzuordnen wäre. Fehlt eine Aufnahme, steht der Satz einfach da; das
## Spiel merkt es nicht einmal.

const GespraechDaten = preload("res://scripts/GespraechDaten.gd")
const Schrift = preload("res://scripts/Schrift.gd")
const Palette = preload("res://scripts/Palette.gd")
const Sinnbild = preload("res://scripts/Sinnbild.gd")
const Stimme = preload("res://scripts/Stimme.gd")
const Welt = preload("res://scripts/Welt.gd")

## Wie lange ein Satz ohne Aufnahme steht.
const SATZ_MIN: float = 1.6
const SATZ_JE_ZEICHEN: float = 0.048

## Masse der Sinnbild-Reihe.
const BILD_GROESSE: float = 54.0
const BILD_ABSTAND: float = 14.0
const REIHE_HOEHE: float = 112.0

signal fertig

var _baum: String = ""
var _knoten: String = ""
var _saetze: Array = []
var _rest: float = 0.0
var _antworten: Array = []
var _ueber: int = -1

var _flaeche: Control = null
var _ton: AudioStreamPlayer = null

## Wohin nach einem Wirkungstext weitergegangen wird (siehe `_satz_starten`).
var _nach_text: String = ""
var _warte_auf_text: bool = false


func _ready() -> void:
	layer = 20
	_flaeche = Control.new()
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.mouse_filter = Control.MOUSE_FILTER_STOP
	_flaeche.draw.connect(_zeichnen)
	_flaeche.gui_input.connect(_eingabe)
	add_child(_flaeche)
	_ton = AudioStreamPlayer.new()
	add_child(_ton)
	set_process(true)


## Ein Gespräch beginnen.
func beginnen(baum: String) -> void:
	_baum = baum
	if GespraechDaten.baum(baum).is_empty():
		push_warning("Gespräch unbekannt: %s" % baum)
		fertig.emit()
		return
	_zu_knoten(str(GespraechDaten.baum(baum).get("start", "")))


func _zu_knoten(knoten: String) -> void:
	_knoten = knoten
	if knoten == "" or GespraechDaten.knoten(_baum, knoten).is_empty():
		_beenden()
		return
	_saetze = GespraechDaten.saetze(_baum, knoten, GameState.is_revealed).duplicate()
	_antworten = []
	_ueber = -1
	_satz_starten()


func _satz_starten() -> void:
	if _saetze.is_empty():
		# Stand hier ein Wirkungstext (die Figur hat etwas getan), geht es danach zu dem
		# Knoten weiter, den die Antwort nennt -- und nicht zurueck in die Auswahl. Ohne
		# diese Weiche bliebe das Gespraech nach jeder wirksamen Antwort stehen.
		if _warte_auf_text:
			_warte_auf_text = false
			_zu_knoten(_nach_text)
			return
		_antworten_zeigen()
		return
	var t: String = str(_saetze[0])
	_rest = SATZ_MIN + float(t.length()) * SATZ_JE_ZEICHEN
	if Stimme.hat(t):
		var strom: AudioStream = Stimme.laden(t)
		if strom != null:
			_ton.stream = strom
			_ton.play()
			# Die Aufnahme bestimmt die Dauer, nicht die Schätzung. Sonst verschwindet der
			# Untertitel mitten im Satz, und zwar genau bei den langen — also bei denen, bei
			# denen es am meisten stört.
			_rest = maxf(_rest, strom.get_length() + 0.25)
	_flaeche.queue_redraw()


func _antworten_zeigen() -> void:
	_antworten = GespraechDaten.antworten(_baum, _knoten, GameState.is_revealed,
		func(f: String) -> bool: return Welt.flagge(f),
		func(g: String) -> bool: return Welt.im_beutel(g))
	if _antworten.is_empty():
		_beenden()
		return
	_flaeche.queue_redraw()


func _process(delta: float) -> void:
	if _saetze.is_empty() or _rest <= 0.0:
		return
	_rest -= delta
	if _rest <= 0.0:
		_saetze.remove_at(0)
		_satz_starten()


func _beenden() -> void:
	_ton.stop()
	fertig.emit()


# ── Eingabe ───────────────────────────────────────────────────────────────────

func _eingabe(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var neu: int = _bild_unter((e as InputEventMouseMotion).position)
		if neu != _ueber:
			_ueber = neu
			_flaeche.queue_redraw()
		return
	if not (e is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = e as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	# Läuft noch ein Satz? Dann überspringt der Klick ihn. Das ist die wichtigste Taste in
	# jedem Adventure, und sie darf nie belegt sein.
	if not _saetze.is_empty():
		_ton.stop()
		_saetze.remove_at(0)
		_satz_starten()
		return

	var i: int = _bild_unter(mb.position)
	if i >= 0:
		_waehlen(i)


func _waehlen(i: int) -> void:
	if i < 0 or i >= _antworten.size():
		return
	var a: Dictionary = _antworten[i] as Dictionary
	if a.has("tut"):
		var text: String = Welt.wirken(a["tut"])
		Welt.missionen_pruefen()
		if text != "":
			_saetze = [text]
			_antworten = []
			_satz_starten()
			# Nach dem Wirkungstext weiter — merken, wohin.
			_nach_text = str(a.get("ziel", ""))
			_warte_auf_text = true
			return
	_zu_knoten(str(a.get("ziel", "")))



## Die Sinnbild-Reihe unten: welches liegt unter `wo`?
func _bild_unter(wo: Vector2) -> int:
	if _antworten.is_empty() or not _saetze.is_empty():
		return -1
	var r: Vector2 = _flaeche.size
	var y: float = r.y - REIHE_HOEHE
	if wo.y < y:
		return -1
	var breite: float = float(_antworten.size()) * (BILD_GROESSE + BILD_ABSTAND) - BILD_ABSTAND
	var x: float = (r.x - breite) * 0.5
	for i in range(_antworten.size()):
		var feld: Rect2 = Rect2(x, y + 8.0, BILD_GROESSE, BILD_GROESSE)
		if feld.has_point(wo):
			return i
		x += BILD_GROESSE + BILD_ABSTAND
	return -1


# ── Zeichnen ──────────────────────────────────────────────────────────────────

func _zeichnen() -> void:
	var c: Control = _flaeche
	var r: Vector2 = c.size
	var schrift: Font = Schrift.schrift()

	# Das Bühnenbild bleibt stehen, nur gedämpft — siehe oben, das ist der ganze Trick.
	c.draw_rect(Rect2(Vector2.ZERO, r), Color(0.0, 0.0, 0.0, 0.28), true)

	# Je Knoten, nicht je Baum: In der Schlussszene wechseln die Sprecher, und mit ihnen
	# Portrait und Name.
	var person: String = GespraechDaten.person_im_knoten(_baum, _knoten)
	var tafel: Rect2 = Rect2(40.0, r.y - REIHE_HOEHE - 168.0, r.x - 80.0, 152.0)
	c.draw_rect(tafel, Color(Palette.TAFEL.r, Palette.TAFEL.g, Palette.TAFEL.b,
		Palette.TAFEL_DECKUNG), true)
	c.draw_rect(tafel, Palette.RAHMEN, false, 2.0)

	# Portrait links in der Tafel
	var bild_feld: Rect2 = Rect2(tafel.position + Vector2(12.0, 12.0), Vector2(128.0, 128.0))
	var bild: Texture2D = Sinnbild.portrait(person)
	if bild != null:
		c.draw_texture_rect(bild, bild_feld, false)
	else:
		Sinnbild.zeichne(c, "person:" + person, bild_feld.position + bild_feld.size * 0.5,
			112.0, Palette.SAND)
	c.draw_rect(bild_feld, Palette.RAHMEN, false, 2.0)

	# Name
	c.draw_string(schrift, tafel.position + Vector2(156.0, 34.0), _name_von(person),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.MESSING)

	# Der Satz
	var satz: String = str(_saetze[0]) if not _saetze.is_empty() else ""
	if satz != "":
		c.draw_multiline_string(schrift, tafel.position + Vector2(156.0, 66.0), satz,
			HORIZONTAL_ALIGNMENT_LEFT, tafel.size.x - 180.0, 20, 3, Palette.SCHRIFT)
		return

	# Die Sinnbild-Reihe
	if _antworten.is_empty():
		return
	var breite: float = float(_antworten.size()) * (BILD_GROESSE + BILD_ABSTAND) - BILD_ABSTAND
	var x: float = (r.x - breite) * 0.5
	var y: float = r.y - REIHE_HOEHE
	for i in range(_antworten.size()):
		var a: Dictionary = _antworten[i] as Dictionary
		var feld: Rect2 = Rect2(x, y + 8.0, BILD_GROESSE, BILD_GROESSE)
		var an: bool = (i == _ueber)
		c.draw_rect(feld, Color(Palette.LEDER.r, Palette.LEDER.g, Palette.LEDER.b,
			0.55 if an else 0.3), true)
		c.draw_rect(feld, Palette.SANDLICHT if an else Palette.RAHMEN, false, 3.0 if an else 1.5)
		Sinnbild.zeichne(c, Sinnbild.fuer_antwort(a), feld.position + feld.size * 0.5,
			BILD_GROESSE * 0.72, Palette.SANDLICHT if an else Palette.SAND)
		x += BILD_GROESSE + BILD_ABSTAND

	# Die Beschriftung des Sinnbilds, über das die Maus fährt. Nur eine — sonst wäre die Reihe
	# eine Textliste mit Bildchen davor, und dann hätte man auch gleich nummerieren können.
	if _ueber >= 0 and _ueber < _antworten.size():
		var text: String = str((_antworten[_ueber] as Dictionary).get("text", ""))
		var tb: float = schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		c.draw_string(schrift, Vector2((r.x - tb) * 0.5, y - 10.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.SANDLICHT)


## Der ausgeschriebene Name einer Person.
##
## Steht in `docs/spiel_stimmen.json`, aber den zur Laufzeit zu laden wäre eine Datei-Operation
## je Gespräch für sechs Zeichenketten. Also hier, und die Testsuite prüft, dass keine Person
## fehlt, die in einem Gesprächsbaum vorkommt.
const NAMEN: Dictionary = {
	"held": "Der Namenlose",
	"mabel": "Mamma „Rusty“ Mabel",
	"silas": "Silas „Kupferauge“ Finch",
	"gideon": "Gideon Cross",
	"doc": "Doc Aris",
	"quentin": "Quentin Vale",
	"dolores": "Dolores",
	"slick": "„Slick“ Sterling",
	"jack": "Kolben-Jack",
}


static func _name_von(person: String) -> String:
	return str(NAMEN.get(person, person.capitalize()))
