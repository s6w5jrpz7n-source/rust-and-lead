extends Node3D
## Der Titelbildschirm — und damit **immer** der Anfang, nicht nur wenn es Spielstände gibt.
##
## Ein Titelbild, das je nach Speicherstand mal da ist und mal nicht, ist kein Anfang, sondern
## ein Dialogfeld. Also steht er auch beim allerersten Start, und „Spiel laden" ist dann
## ausgegraut statt versteckt — ein Eintrag, der auftaucht und verschwindet, lässt den ganzen
## Bildschirm springen.
##
## ## Ein festes Bild, und zwar das LETZTE des Films
##
## Der erste Entwurf ließ die echte Welt hinter dem Menü sehr langsam rotieren. Das Argument
## dafür war, dass ein Standbild gegen das Spiel altert, sobald jemand die Palisade umbaut. Das
## stimmt und wiegt trotzdem leichter als das, was dabei herauskam: Ein Titelbild soll STEHEN.
## Es ist das erste Versprechen, das ein Spiel gibt, und ein Versprechen, das sich dreht, ist
## eine Bildschirmschoner-Ansicht.
##
## Genommen wird deshalb das **letzte Bild des Intro-Films** — und das ist mehr als eine
## Notlösung: Wer „Neues Spiel" wählt, sieht den Film laufen, und der endet genau dort, wo der
## Titel angefangen hat. Das Standbild ist damit kein Aushang neben dem Spiel, sondern sein
## erster Bildinhalt.
##
## Die Welt wird hier gar nicht mehr geladen. Der Titel startet sofort, und die Overworld hat
## keinen Sonderzustand mehr zu kennen — die Flagge dafür ist mit diesem Entwurf weggefallen.

const OVERWORLD := preload("res://scenes/Overworld.tscn")
const TITELBILD := preload("res://assets/ui/titelbild.webp")
const SAVE_SLOT: int = 0

var _wurzel: Control = null
var _eintraege: Array = []          # [Button, Kennung]
var _blatt: Control = null          # das gerade offene Unterblatt (Einstellungen/Steuerung/…)


func _ready() -> void:
	_bau_oberflaeche()


# ── Die Oberfläche ────────────────────────────────────────────────────────────
## Der Titel liegt DIREKT im Bild, ohne Kasten und ohne Panel — nur mit einem weichen dunklen
## Verlauf dahinter, damit die Schrift auch über hellem Sand lesbar bleibt. Die Einträge stehen
## rechtsbündig in einer Spalte, damit die Stadtmitte frei bleibt: Sie ist das Bild.
func _bau_oberflaeche() -> void:
	var lage := CanvasLayer.new()
	add_child(lage)
	_wurzel = Control.new()
	_wurzel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wurzel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lage.add_child(_wurzel)
	# Das Bild fuellt den Rahmen und behaelt sein Seitenverhaeltnis. `COVERED` und nicht
	# `SCALE`: Auf einem Telefon im Hochformat wuerde ein gestrecktes Bild die Figur in die
	# Breite ziehen, und ein Titelbild mit verzerrtem Gesicht ist schlimmer als ein
	# beschnittenes.
	var bild := TextureRect.new()
	bild.texture = TITELBILD
	bild.set_anchors_preset(Control.PRESET_FULL_RECT)
	bild.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bild.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wurzel.add_child(bild)
	# Zwei weiche Schleier, keiner flaechig: einer von oben fuer den Titel, einer von rechts
	# fuer die Menuespalte. Nachgemessen liegt die Helligkeit dort bei 64 bzw. 85 von 255 —
	# hell genug, dass helle Schrift ohne Hilfe verschwaende, dunkel genug, dass ein leichter
	# Schleier reicht. Ein flaechiges Abdunkeln haette dem Bild genau das genommen, wofuer es
	# da ist.
	_wurzel.add_child(_schleier(Vector2(0.0, 0.0), Vector2(0.0, 0.42), 0.72))
	_wurzel.add_child(_schleier(Vector2(1.0, 0.0), Vector2(0.52, 0.0), 0.78))
	var titel := Label.new()
	titel.text = "RUST & LEAD"
	titel.add_theme_font_size_override("font_size", 78)
	titel.add_theme_color_override("font_color", Color(0.93, 0.86, 0.72))
	# Rostkante: ein warmer Umriss statt eines Schlagschattens. Ein Schatten hätte die Schrift
	# vom Bild abgehoben; der Umriss lässt sie darin liegen.
	titel.add_theme_color_override("font_outline_color", Color(0.36, 0.16, 0.07))
	titel.add_theme_constant_override("outline_size", 10)
	titel.position = Vector2(78.0, 74.0)
	_wurzel.add_child(titel)
	var unter := Label.new()
	unter.text = "Ein Steampunk-Western"
	unter.add_theme_font_size_override("font_size", 21)
	unter.add_theme_color_override("font_color", Color(0.72, 0.66, 0.56))
	# 186 und nicht 162: Bei 78 px Schriftgroesse reicht der Titelkasten bis etwa 170 hinunter,
	# und die Unterzeile sass in seinen Unterlaengen. Im Bild klebten beide aneinander.
	unter.position = Vector2(86.0, 186.0)
	_wurzel.add_child(unter)

	var spalte := VBoxContainer.new()
	spalte.alignment = BoxContainer.ALIGNMENT_END
	spalte.add_theme_constant_override("separation", 6)
	spalte.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	spalte.position = Vector2(-330.0, -150.0)
	spalte.custom_minimum_size = Vector2(300.0, 0.0)
	_wurzel.add_child(spalte)
	for e in _menue():
		var kennung: String = String(e[0])
		var b := Button.new()
		b.text = String(e[1])
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.flat = true
		b.add_theme_font_size_override("font_size", 26)
		b.add_theme_color_override("font_color", Color(0.90, 0.85, 0.76))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.80, 0.38))
		b.add_theme_color_override("font_disabled_color", Color(0.44, 0.42, 0.40))
		b.custom_minimum_size = Vector2(300.0, 44.0)
		b.disabled = bool(e[2])
		b.pressed.connect(_gewaehlt.bind(kennung))
		spalte.add_child(b)
		_eintraege.append([b, kennung])


## Was auf dem Titelbildschirm steht — und was daran nicht selbstverständlich ist.
##
## Gefragt war „New Game, Load Game, Credits, Tutorial — was fehlt noch?". Es fehlten drei, und
## zwei davon sind keine Bequemlichkeit:
##
##  * **Einstellungen.** Ohne Lautstärkeregler ist ein Spiel mit Schusswaffen auf einem Telefon
##    unzumutbar. Das ist kein Komfort, das ist die Bedingung dafür, dass es jemand im Bus
##    anfassen kann.
##  * **Steuerung.** Das Spiel läuft auf Handy *und* Tastatur. Wer am Rechner sitzt, sucht sonst
##    blind nach `[E]`, `[R]`, `[Tab]`, `[Q]`, `[M]` — nichts davon steht irgendwo.
##  * **Beenden**, aber nur auf dem Desktop. Auf dem Handy beendet man Apps anders, und ein
##    Knopf, der dort nichts Sinnvolles tut, ist schlimmer als keiner.
##
## Nicht aufgenommen: ein „Fortsetzen" neben „Spiel laden". Beim ersten Start wäre es tot, und
## danach wäre es dasselbe wie der zweite Eintrag mit einem anderen Wort.
func _menue() -> Array:
	var hat_stand: bool = SaveManager.has_slot(SAVE_SLOT)
	var eintraege: Array = [
		["neu", "Neues Spiel", false],
		["laden", "Spiel laden", not hat_stand],
		["tutorial", "Tutorial", false],
		["einstellungen", "Einstellungen", false],
		["steuerung", "Steuerung", false],
		["credits", "Credits", false],
	]
	if not OS.has_feature("mobile"):
		eintraege.append(["beenden", "Beenden", false])
	return eintraege


func _gewaehlt(kennung: String) -> void:
	match kennung:
		"neu":
			_starten(true, false)
		"laden":
			_starten(false, false)
		"tutorial":
			_starten(true, true)
		"beenden":
			get_tree().quit()
		_:
			_blatt_zeigen(kennung)


## Ins Spiel. `frisch` setzt den Prolog zurück, `tutorial` schaltet zusätzlich die Hinweistafeln
## ein.
##
## Das Tutorial ist **derselbe Prolog** mit eingeblendeten Sätzen und kein zweiter Inhalt. Ein
## eigener Tutorial-Abschnitt hieße zwei Anfänge zu pflegen, und einer davon wird schlechter.
func _starten(frisch: bool, tutorial: bool) -> void:
	GameState.tutorial = tutorial
	if frisch:
		# Die Datei loeschen reicht NICHT. `GameState` ist ein Autoload und ueberlebt den
		# Szenenwechsel: Wer im Titel „Neues Spiel" waehlt, nachdem er schon einmal gespielt
		# hat, brachte sonst Gold, Stufe und — schlimmer — die erledigten Prolog-Marken mit.
		# Der Film waere gelaufen und danach haette die Figur wortlos in der Grube gestanden.
		SaveManager.delete_slot(SAVE_SLOT)
		GameState.neu_beginnen()
	get_tree().change_scene_to_packed(OVERWORLD)


# ── Die Unterblätter ──────────────────────────────────────────────────────────
func _blatt_zeigen(art: String) -> void:
	if _blatt != null and is_instance_valid(_blatt):
		_blatt.queue_free()
	var tafel := PanelContainer.new()
	tafel.set_anchors_preset(Control.PRESET_CENTER)
	tafel.position = Vector2(-330.0, -230.0)
	tafel.custom_minimum_size = Vector2(660.0, 0.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	tafel.add_child(box)
	var kopf := Label.new()
	kopf.add_theme_font_size_override("font_size", 30)
	kopf.add_theme_color_override("font_color", Color(1.0, 0.80, 0.38))
	box.add_child(kopf)
	match art:
		"einstellungen":
			kopf.text = "Einstellungen"
			for regler in [["Gesamt", "Master"], ["Musik", "Music"], ["Effekte", "SFX"],
					["Sprache", "Voice"]]:
				box.add_child(_regler(String(regler[0]), String(regler[1])))
		"steuerung":
			kopf.text = "Steuerung"
			box.add_child(_text(_steuerung_text()))
		"credits":
			kopf.text = "Credits"
			box.add_child(_text(_credits_text()))
	var zu := Button.new()
	zu.text = "Zurück"
	zu.add_theme_font_size_override("font_size", 22)
	zu.pressed.connect(func() -> void:
		if _blatt != null and is_instance_valid(_blatt):
			_blatt.queue_free()
		_blatt = null)
	box.add_child(zu)
	_wurzel.add_child(tafel)
	_blatt = tafel


## Ein weicher Verlauf von einer Bildkante nach innen.
func _schleier(von: Vector2, bis: Vector2, deckung: float) -> TextureRect:
	var lauf := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(0.03, 0.02, 0.02, deckung))
	g.set_offset(1, 1.0)
	g.set_color(1, Color(0.03, 0.02, 0.02, 0.0))
	lauf.gradient = g
	lauf.fill_from = von
	lauf.fill_to = bis
	var t := TextureRect.new()
	t.texture = lauf
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _text(s: String) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.88, 0.84, 0.78))
	return l


## Ein Lautstärkeregler, der auf einen echten Audio-Bus geht.
##
## Der Bus wird angelegt, falls es ihn noch nicht gibt: Ein Regler, der nur eine Zahl in einer
## Einstellungsdatei verschiebt, ist eine Attrappe, und die fällt spätestens auf, wenn jemand
## sie benutzt.
func _regler(name: String, bus: String) -> Control:
	var zeile := HBoxContainer.new()
	zeile.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = name
	l.custom_minimum_size = Vector2(120.0, 0.0)
	l.add_theme_font_size_override("font_size", 19)
	zeile.add_child(l)
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0 and bus != "Master":
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus)
		AudioServer.set_bus_send(idx, "Master")
	if idx < 0:
		idx = 0
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.custom_minimum_size = Vector2(360.0, 24.0)
	s.value = db_to_linear(AudioServer.get_bus_volume_db(idx))
	s.value_changed.connect(func(v: float) -> void:
		# Bei null wird stummgeschaltet statt auf −inf gerechnet: `linear_to_db(0)` ist −inf,
		# und damit rechnet Godots Mischer nicht sauber weiter.
		AudioServer.set_bus_mute(idx, v <= 0.001)
		if v > 0.001:
			AudioServer.set_bus_volume_db(idx, linear_to_db(v)))
	zeile.add_child(s)
	return zeile


func _steuerung_text() -> String:
	return """Laufen        Ziehen (Finger/Maus) · WASD · Pfeiltasten
Schießen      Knopf unten rechts · Leertaste (zielt selbst)
Nachladen     [R]
Rucksack      [Tab]
Charakter     [C]
Weltkarte     [M]
Auftrag       [Q] wechselt das verfolgte Ziel
Handeln       [E] — aufsitzen, Truhe öffnen, ansprechen
Zoom          [+] / [−] · zwei Finger
Überspringen  Tippen bricht Film und Kamerafahrt ab
Prolog neu    [F9] zweimal"""


func _credits_text() -> String:
	return """Rust & Lead

Entwurf, Code und Welt      Der Namenlose und eine Maschine
Modelle                     siehe assets/CREDITS.md
Ton                         synthetisch erzeugt (tools/sfx/make_sfx.py)
Motor                       Godot 4.3

Alle Texte und Kommentare in diesem Projekt sind deutsch —
auch der Code. Das ist Absicht: Wer die Welt baut, soll in
ihrer Sprache denken."""
