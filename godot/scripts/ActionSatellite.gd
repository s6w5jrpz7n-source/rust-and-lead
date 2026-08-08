class_name ActionSatellite extends Control
## Ein kleiner Knopf am Rand des Schussknopfes.
##
## Der Schussknopf ist groß und liegt dort, wo der Daumen ruht. Alles, was man **im Gefecht**
## braucht, gehört in dieselbe Handbewegung — und nicht an den anderen Bildschirmrand, wo man
## den Daumen erst hinbringen muss, während jemand auf einen schießt. Also legen sich die
## kleinen Knöpfe wie Trabanten außen um ihn herum.
##
## Sie sind **kleiner** und **außen**, und beides ist Absicht: Wer im Gefecht blind greift,
## trifft die Mitte. Ein Fehlgriff soll den Schuss auslösen und nicht den Trank verbrauchen —
## deshalb hat der Schussknopf die Vorfahrt, und die Trabanten fangen erst außerhalb seines
## Randes an.
##
## Das Symbol wird **gemalt**, nicht gesetzt. Die erste Fassung schrieb ein Reagenzglas-Emoji
## in den Knopf — und Godots eingebaute Schrift kennt kein einziges Symbol, also stand dort im
## Spiel ein leeres Kästchen mit einer Zahl daneben. Gemalte Punkte können das nicht: Sie
## sehen auf jedem Gerät gleich aus und hängen an keiner Schrift. Siehe `HudGlyph`.

## Radius des Trabanten und wie weit seine Mitte vom Schussknopf entfernt sitzt.
const RADIUS: float = 26.0
## Der Abstand ist der Schussknopfradius PLUS der eigene plus ein Spalt: So berühren sich die
## Trefferflächen nicht. Ein Trabant, der in den Schussknopf hineinragt, ist ein Trank, den man
## beim Zielen trinkt.
const SPALT: float = 6.0
const TOUCH_SLACK: float = 1.22

var zeichen: String = ""          ## Name aus `HudGlyph.Z`, oder "trank" fuer den gemalten Flakon
var zahl: int = 0                 ## kleine Zahl unten rechts; < 0 = keine
var aktiv: bool = true            ## ausgegraut, wenn nichts zu holen ist
var gedrueckt: bool = false
signal ausgeloest


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Treffer prüft `hits()`, wie beim Schussknopf
	custom_minimum_size = Vector2(RADIUS * 2.0, RADIUS * 2.0)
	size = Vector2(RADIUS * 2.0, RADIUS * 2.0)


func center() -> Vector2:
	return global_position + size * 0.5


func hits(at: Vector2) -> bool:
	return aktiv and at.distance_to(center()) <= RADIUS * TOUCH_SLACK


func setzen(z: String, n: int, an: bool) -> void:
	if z == zeichen and n == zahl and an == aktiv:
		return   # nur bei Wechsel neu zeichnen, nicht sechzigmal pro Sekunde
	zeichen = z
	zahl = n
	aktiv = an
	queue_redraw()


func druecken(an: bool) -> void:
	if an == gedrueckt:
		return
	gedrueckt = an
	queue_redraw()
	if an and aktiv:
		ausgeloest.emit()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var fill := Color(0.20, 0.26, 0.24, 0.62)
	var rim := Color(0.62, 0.82, 0.74, 0.70)
	if not aktiv:
		fill = Color(0.16, 0.16, 0.16, 0.45)
		rim = Color(0.42, 0.42, 0.42, 0.45)
	elif gedrueckt:
		fill = Color(0.42, 0.72, 0.58, 0.85)
		rim = Color(0.90, 1.0, 0.94, 0.95)
	draw_circle(c, RADIUS, fill)
	draw_arc(c, RADIUS, 0.0, TAU, 32, rim, 2.5, true)
	var schrift: Font = get_theme_default_font()
	# `trank` wird GEMALT, nicht gesetzt. Ein Schriftzeichen haengt daran, dass die Schrift es
	# ueberhaupt kennt — und genau daran ist die erste Fassung gescheitert: Godots eingebaute
	# Schrift hat kein einziges Symbol, der Knopf zeigte ein leeres Kaestchen. Gemalte Punkte
	# koennen das nicht. Alles andere darf weiter ein Zeichen sein (`HudGlyph.Z`).
	if zeichen == "trank":
		var vorne: Color = rim if aktiv else Color(0.55, 0.55, 0.55, 0.7)
		var saft: Color = Color(0.86, 0.24, 0.32, 0.85) if aktiv else Color(0.34, 0.30, 0.30, 0.5)
		HudGlyph.zeichne_flakon(self, c, RADIUS * 0.92, vorne, saft)
	elif zeichen != "":
		var gr: Vector2 = schrift.get_string_size(zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		draw_string(schrift, c - gr * 0.5 + Vector2(0.0, gr.y * 0.36), zeichen,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
			rim if aktiv else Color(0.55, 0.55, 0.55, 0.7))
	# Die Zahl sitzt unten rechts im Knopf, nicht daneben: Sie gehört zum Vorrat und nicht zum
	# Bildschirmrand — und wer den Daumen darüber hat, verdeckt sie sonst.
	if zahl >= 0:
		var t: String = str(zahl)
		var gz: Vector2 = schrift.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		var wo: Vector2 = c + Vector2(RADIUS * 0.34, RADIUS * 0.56)
		draw_circle(wo, 10.0, Color(0.05, 0.05, 0.05, 0.72))
		draw_string(schrift, wo - gz * 0.5 + Vector2(0.0, gz.y * 0.36), t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(1.0, 0.94, 0.82) if aktiv else Color(0.55, 0.55, 0.55))
