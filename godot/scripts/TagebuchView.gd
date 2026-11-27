extends CanvasLayer
## Das Tagebuch — Kapitel, Aufträge, und was der Held herausgefunden hat.
##
## ## Warum es drei getrennte Listen sind
##
## **Aufträge** sind, was jemand von einem will. **Notizen** sind, was man selbst zusammen-
## gereimt hat. **Gegenstände** sind, was man dabei hat. Die drei zu mischen wäre bequemer zu
## bauen und beim Spielen unbrauchbar: Wer nicht weiterkommt, sucht entweder „was war nochmal
## zu tun" oder „was weiß ich über die Naht" — und das sind zwei verschiedene Suchen.
##
## Die Aufträge stehen unter ihrem **Kapitel**, und offene stehen vor erledigten. Daran sieht
## man auf einen Blick das, was in dieser Bauform zählt: wie viel noch fehlt, bis die
## Schlussszene aufgeht.

const KapitelDaten = preload("res://scripts/KapitelDaten.gd")
const Schrift = preload("res://scripts/Schrift.gd")
const MissionDaten = preload("res://scripts/MissionDaten.gd")
const Palette = preload("res://scripts/Palette.gd")
const Welt = preload("res://scripts/Welt.gd")

signal geschlossen

enum Blatt { AUFTRAEGE, NOTIZEN, SACHEN }

var _blatt: int = Blatt.AUFTRAEGE
var _flaeche: Control = null


func _ready() -> void:
	layer = 30
	_flaeche = Control.new()
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.mouse_filter = Control.MOUSE_FILTER_STOP
	_flaeche.draw.connect(_zeichnen)
	_flaeche.gui_input.connect(_eingabe)
	add_child(_flaeche)


func zeigen() -> void:
	visible = true
	_flaeche.queue_redraw()


func _eingabe(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		var wo: Vector2 = (e as InputEventMouseButton).position
		# Die drei Reiter oben
		for i in range(3):
			if Rect2(60.0 + float(i) * 170.0, 46.0, 160.0, 36.0).has_point(wo):
				_blatt = i
				_flaeche.queue_redraw()
				return
		geschlossen.emit()
	elif e is InputEventKey and (e as InputEventKey).pressed:
		geschlossen.emit()


func _zeichnen() -> void:
	var c: Control = _flaeche
	var r: Vector2 = c.size
	var schrift: Font = Schrift.schrift()

	c.draw_rect(Rect2(Vector2.ZERO, r), Color(Palette.RUSS.r, Palette.RUSS.g, Palette.RUSS.b,
		0.93), true)

	var k: int = GameState.current_chapter
	c.draw_string(schrift, Vector2(60.0, 34.0),
		"Kapitel %d — %s" % [k, KapitelDaten.titel(k)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.MESSING)

	var namen: Array = ["Aufträge", "Was ich weiß", "Dabei"]
	for i in range(3):
		var feld: Rect2 = Rect2(60.0 + float(i) * 170.0, 46.0, 160.0, 36.0)
		var an: bool = (i == _blatt)
		c.draw_rect(feld, Color(Palette.LEDER.r, Palette.LEDER.g, Palette.LEDER.b,
			0.5 if an else 0.22), true)
		c.draw_rect(feld, Palette.SANDLICHT if an else Palette.RAHMEN, false, 2.0)
		c.draw_string(schrift, feld.position + Vector2(14.0, 25.0), str(namen[i]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			Palette.SANDLICHT if an else Palette.SCHRIFT_MATT)

	var y: float = 120.0
	match _blatt:
		Blatt.AUFTRAEGE: y = _auftraege(c, schrift, y, r)
		Blatt.NOTIZEN: y = _notizen(c, schrift, y, r)
		_: y = _sachen(c, schrift, y, r)

	c.draw_string(schrift, Vector2(60.0, r.y - 26.0),
		"Irgendwohin klicken oder eine Taste drücken — zurück ins Spiel.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.SCHRIFT_MATT)


func _auftraege(c: Control, schrift: Font, y: float, r: Vector2) -> float:
	var k: int = GameState.current_chapter
	var offen: Array = KapitelDaten.offen(k, func(id: String) -> bool:
		return Welt.mission_fertig(id))

	for kennung in KapitelDaten.missionen(k):
		var m: Dictionary = MissionDaten.mission(str(kennung))
		var ist_fertig: bool = Welt.mission_fertig(str(kennung))
		var laeuft: bool = Welt.mission_laeuft(str(kennung))
		var kopf: String = str(m.get("titel", kennung))
		if ist_fertig:
			kopf = "✓ " + kopf
		elif not laeuft:
			kopf = "· " + kopf + "  (noch nicht angenommen)"
		c.draw_string(schrift, Vector2(60.0, y), kopf, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Palette.SCHRIFT_MATT if ist_fertig else Palette.SANDLICHT)
		y += 26.0

		if laeuft:
			var f: Array = Welt.fortschritt(str(kennung))
			var schritte: Array = m.get("schritte", []) as Array
			for i in range(schritte.size()):
				var s: Dictionary = schritte[i] as Dictionary
				var getan: bool = i < int(f[0])
				c.draw_string(schrift, Vector2(92.0, y),
					("✓ " if getan else "– ") + str(s.get("text", "")),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
					Palette.SCHRIFT_MATT if getan else Palette.SCHRIFT)
				y += 22.0
		elif not ist_fertig:
			c.draw_string(schrift, Vector2(92.0, y), str(m.get("anriss", "")),
				HORIZONTAL_ALIGNMENT_LEFT, r.x - 160.0, 16, Palette.SCHRIFT_MATT)
			y += 22.0
		y += 8.0

	# Der Hinweis auf die Schlussszene — das ist die wichtigste Zeile dieser Seite.
	y += 10.0
	var s2: Dictionary = KapitelDaten.schluss(k)
	if offen.is_empty() and not KapitelDaten.missionen(k).is_empty():
		c.draw_string(schrift, Vector2(60.0, y),
			"Alles erledigt. %s — %s" % [str(s2.get("titel", "")), str(s2.get("anriss", ""))],
			HORIZONTAL_ALIGNMENT_LEFT, r.x - 120.0, 18, Palette.GALVANISCH)
	else:
		c.draw_string(schrift, Vector2(60.0, y),
			"Noch offen: %d. Erst dann geht es weiter." % offen.size(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.SCHRIFT_MATT)
	return y


func _notizen(c: Control, schrift: Font, y: float, r: Vector2) -> float:
	if GameState.notizen.is_empty():
		c.draw_string(schrift, Vector2(60.0, y), "Noch nichts, was sich zusammenreimen ließe.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.SCHRIFT_MATT)
		return y
	for kennung in GameState.notizen:
		var n: Dictionary = MissionDaten.notiz(str(kennung))
		c.draw_string(schrift, Vector2(60.0, y), str(n.get("titel", kennung)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.SANDLICHT)
		y += 26.0
		var hoch: float = _mehrzeilig(c, schrift, Vector2(60.0, y), str(n.get("text", "")),
			r.x - 120.0, 17, Palette.SCHRIFT)
		y += hoch + 16.0
	return y


func _sachen(c: Control, schrift: Font, y: float, r: Vector2) -> float:
	if GameState.beutel.is_empty():
		c.draw_string(schrift, Vector2(60.0, y), "Die Taschen sind leer.",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.SCHRIFT_MATT)
		return y
	for kennung in GameState.beutel:
		var g: Dictionary = MissionDaten.gegenstand(str(kennung))
		c.draw_string(schrift, Vector2(60.0, y), str(g.get("name", kennung)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.SANDLICHT)
		y += 26.0
		var hoch: float = _mehrzeilig(c, schrift, Vector2(60.0, y), str(g.get("text", "")),
			r.x - 120.0, 17, Palette.SCHRIFT)
		y += hoch + 16.0
	return y


## Mehrzeiligen Text zeichnen und zurückgeben, wie hoch er wurde.
##
## `draw_multiline_string` zeichnet, sagt aber nicht, wie viel Platz es gebraucht hat — und
## ohne diese Zahl überschreibt der nächste Eintrag den vorigen, sobald ein Text zweizeilig
## wird. Also wird die Höhe vorher gemessen.
func _mehrzeilig(c: Control, schrift: Font, wo: Vector2, text: String, breite: float,
		groesse: int, farbe: Color) -> float:
	c.draw_multiline_string(schrift, wo, text, HORIZONTAL_ALIGNMENT_LEFT, breite, groesse,
		-1, farbe)
	return schrift.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, breite,
		groesse).y
