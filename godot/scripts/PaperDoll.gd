extends Control
## Die Puppe — getragene Ausrüstung als Figur statt als Liste (GDD §7.4).
##
## Bis hierher stand links im Charakter-Bildschirm eine Textliste: „Helm — leer", „Rüstung —
## Verstärkte Kesselweste (+7 armor)". Dieselbe Information, und trotzdem etwas anderes: Eine
## Liste beantwortet „was trage ich?" erst, nachdem man sie gelesen hat. Eine Puppe beantwortet
## „wo ist noch eine Lücke?" mit einem Blick — und genau das ist die Frage, mit der man den
## Bildschirm aufmacht.
##
## GEZEICHNET, nicht aus Knöpfen gebaut — dieselbe Entscheidung wie beim Beutel-Raster
## (`InventoryGrid`) und aus denselben Gründen: dreizehn Steuerelemente, die bei jedem Öffnen
## neu entstünden, gegen eine Fläche, deren Treffer über `slot_at()` zurückgerechnet wird. So
## lassen sich außerdem Verbindungslinien von der Fassung zum Körperteil ziehen, was mit
## Knöpfen gar nicht ginge.
##
## Die Puppe rechnet nichts. Was in einer Fassung steckt, steht in `EquipManager`; was ein Tipp
## bedeutet, entscheidet `CharacterScreen`. Hier steht nur, wie es aussieht und welche Fassung
## getroffen wurde.

signal picked(slot: String)

const UiAssets = preload("res://scripts/UiAssets.gd")

const W: float = 430.0
const H: float = 436.0
const BOX: float = 54.0          # Kantenlänge einer Ausrüstungs-Fassung
const PLATE_BOX: float = 34.0    # Platten sind kleiner: acht Stück brauchen sonst zwei Spalten
const TOUCH_SLACK: float = 4.0   # dieselbe Daumen-Toleranz wie im Beutel-Raster

## Die fünf großen Fassungen, in Bildschirmkoordinaten der Puppe.
##
## Zwei Spalten links und rechts der Figur statt einer Reihe darunter: Der Helm gehört über den
## Kopf, die Stiefel unter die Füße, und die Waffe an die Hand. Sobald eine Fassung dort liegt,
## wo das Teil am Körper sitzt, muss man die Beschriftung nicht mehr lesen.
const SLOT_POS: Dictionary = {
	"helmet": Vector2(188.0, 6.0),
	"weapon": Vector2(16.0, 86.0),
	"armor":  Vector2(360.0, 86.0),
	"gadget": Vector2(16.0, 166.0),
	"boots":  Vector2(360.0, 166.0),
}
## Wohin die Verbindungslinie zeigt — der Punkt am Körper, zu dem die Fassung gehört.
const SLOT_ANCHOR: Dictionary = {
	"helmet": Vector2(215.0, 78.0),
	"weapon": Vector2(172.0, 172.0),
	"armor":  Vector2(215.0, 160.0),
	"gadget": Vector2(186.0, 232.0),
	"boots":  Vector2(240.0, 318.0),
}
## Die Figur als Rechteck — Kopfoberkante bis Fußsohle, Armspitze bis Armspitze.
##
## Steht hier als Zahl und nicht nur im Zeichencode, weil genau daran der erste Entwurf
## gescheitert ist: Der Helm-Kasten lag auf dem Kopf. Im Bild sah es aus, als hätte die Figur
## keinen — und der Test, der Fassungen gegen Fassungen prüfte, hat es nicht gesehen, weil eine
## Fassung eben keine Figur ist. Jetzt prüft er beides.
const FIGURE_RECT: Rect2 = Rect2(161.0, 72.0, 108.0, 258.0)
## Platten: zwei Reihen à vier, unter der Figur. Sie hängen an keinem Körperteil (es sind
## Einschübe im Chassis), deshalb ohne Verbindungslinie und als eigener Block.
const PLATE_ROW_Y: float = 348.0
const PLATE_X0: float = 96.0
const PLATE_STEP: float = 44.0

var selected: String = ""        # Fassungs-Id, "" = nichts gewählt


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Treffer prüft `slot_at`, nicht die GUI
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)


## Lage jeder Fassung als Rechteck (puppen-lokal). Eine Quelle für Zeichnen UND Treffer —
## zwei getrennte Koordinatensätze laufen garantiert irgendwann auseinander.
static func slot_rects() -> Dictionary:
	var out: Dictionary = {}
	for s in SLOT_POS:
		out[s] = Rect2(SLOT_POS[s], Vector2(BOX, BOX))
	for i in EquipManager.PLATE_SLOTS.size():
		var spalte: int = i % 4
		var reihe: int = i / 4
		out[String(EquipManager.PLATE_SLOTS[i])] = Rect2(
			Vector2(PLATE_X0 + float(spalte) * PLATE_STEP,
				PLATE_ROW_Y + float(reihe) * PLATE_STEP),
			Vector2(PLATE_BOX, PLATE_BOX))
	return out


## Welche Fassung liegt unter diesem Punkt? ("" = daneben.) `at` ist bildschirmrelativ.
func slot_at(at: Vector2) -> String:
	var lokal: Vector2 = at - global_position
	for s in slot_rects():
		if (slot_rects()[s] as Rect2).grow(TOUCH_SLACK).has_point(lokal):
			return String(s)
	return ""


## Tipp verarbeiten. `true`, wenn er hier verbraucht wurde.
func tap(at: Vector2) -> bool:
	var lokal: Vector2 = at - global_position
	if not Rect2(Vector2.ZERO, Vector2(W, H)).grow(TOUCH_SLACK).has_point(lokal):
		return false
	var treffer: String = slot_at(at)
	# Nochmal auf dieselbe Fassung tippen hebt die Wahl auf — wie im Beutel-Raster. Ohne das
	# gibt es auf dem Handy keinen Weg, eine Auswahl loszuwerden, ohne alles zu schließen.
	selected = "" if treffer == selected else treffer
	queue_redraw()
	picked.emit(selected)
	return true


func refresh() -> void:
	queue_redraw()


# ── Zeichnen ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_figure()
	var schrift: Font = get_theme_default_font()
	var rects: Dictionary = slot_rects()
	# Verbindungslinien ZUERST: Sie laufen unter den Fassungen durch, nicht über sie.
	for s in SLOT_POS:
		var r: Rect2 = rects[s]
		draw_line(r.position + r.size * 0.5, SLOT_ANCHOR[s], Color(0.42, 0.36, 0.26, 0.55), 1.0)
	for s in rects:
		_draw_slot(String(s), rects[s], schrift)
	# Beschriftung des Plattenblocks — bei acht gleichen Kästchen ist sonst nicht klar, was es ist.
	if schrift != null:
		draw_string(schrift, Vector2(PLATE_X0, PLATE_ROW_Y - 8.0),
			"Panzerplatten & Tech-Module", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(0.62, 0.57, 0.44, 0.9))


## Eine Fassung: Vertiefung, Rahmen in Seltenheitsfarbe, Sinnbild.
##
## Der Rahmen trägt die Seltenheit, wie im Beutel — dieselbe Farbe für dieselbe Bedeutung, sonst
## muss man zwei Sprachen lernen. Eine LEERE Fassung ist bewusst nicht nur „ohne Rahmen", sondern
## bekommt einen gestrichelten: Ein fehlender Rahmen liest sich als Hintergrund, ein gestrichelter
## als Platz, an den etwas gehört.
func _draw_slot(slot: String, r: Rect2, schrift: Font) -> void:
	var typ: String = EquipManager.slot_type(slot)
	var g: Dictionary = EquipManager.equipped(slot)
	draw_rect(r, Color(0.10, 0.09, 0.08, 0.92))
	if g.is_empty():
		_draw_dashed_rect(r, Color(0.34, 0.30, 0.23, 0.85))
	else:
		var col: Color = OverworldView.RARITY_COLOR.get(String(g.get("rarity", "common")),
			Color.WHITE)
		draw_rect(r, Color(col.r, col.g, col.b, 0.20))
		draw_rect(r, col, false, 2.0)
	if slot == selected:
		# Doppelt umrandet statt eingefärbt: Die Farbe TRÄGT hier Bedeutung (Seltenheit), die
		# darf die Auswahl nicht überschreiben. Gleiche Regel wie im Beutel-Raster.
		draw_rect(r.grow(3.0), Color(1.0, 0.94, 0.72, 0.95), false, 2.0)
	if schrift == null:
		return
	var tint: Color = Color(0.50, 0.45, 0.36) if g.is_empty() \
		else OverworldView.RARITY_COLOR.get(String(g.get("rarity", "common")), Color.WHITE)
	# Eine LEERE Fassung zeigt ihr Sinnbild gedaempft: Sie sagt damit nicht nur „hier fehlt
	# etwas", sondern auch „hier gehoert ein Helm hin" — bei dreizehn Fassungen der Unterschied
	# zwischen einer Puppe und einem Formular.
	if UiAssets.draw_fitted(self, "icon_" + typ, r.grow(-4.0),
			Color(tint.r, tint.g, tint.b, 0.32 if g.is_empty() else 1.0)):
		return
	var zeichen: String = String(InventoryGrid.SLOT_ICON.get(typ, "?"))
	var groesse: float = 24.0 if r.size.x > 40.0 else 16.0
	var mass: Vector2 = schrift.get_string_size(zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1, int(groesse))
	draw_string(schrift, r.position + (r.size - mass) * 0.5 + Vector2(0.0, mass.y * 0.78),
		zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1, int(groesse), tint)


## Gestrichelter Rahmen. Godot kennt keinen — vier Kanten in Stücken gezeichnet.
func _draw_dashed_rect(r: Rect2, col: Color) -> void:
	var strich: float = 5.0
	var x: float = r.position.x
	while x < r.end.x:
		var bis: float = minf(x + strich, r.end.x)
		draw_line(Vector2(x, r.position.y), Vector2(bis, r.position.y), col, 1.0)
		draw_line(Vector2(x, r.end.y), Vector2(bis, r.end.y), col, 1.0)
		x += strich * 2.0
	var y: float = r.position.y
	while y < r.end.y:
		var bis2: float = minf(y + strich, r.end.y)
		draw_line(Vector2(r.position.x, y), Vector2(r.position.x, bis2), col, 1.0)
		draw_line(Vector2(r.end.x, y), Vector2(r.end.x, bis2), col, 1.0)
		y += strich * 2.0


## Die Figur selbst: eine Silhouette aus Grundformen.
##
## Bewusst KEIN Bild. Ein gemaltes Chassis wäre schöner, wäre aber eine Datei, die es noch nicht
## gibt, und die Puppe soll heute funktionieren. Die Silhouette hat außerdem einen Vorteil, den
## ein Bild nicht hätte: Sie ist an derselben Stelle wie die Ankerpunkte definiert, verrutscht
## also nie gegen die Verbindungslinien.
func _draw_figure() -> void:
	# Liegt eine gemalte Silhouette (`doll_body.png`), gewinnt sie. Sie wird in `FIGURE_RECT`
	# eingepasst — also genau in das Rechteck, um das herum die Fassungen sitzen und gegen das
	# der Test prueft. Damit kann kein Bild die Fassungen verdecken, egal wie es zugeschnitten ist.
	if UiAssets.draw_fitted(self, "doll_body", FIGURE_RECT):
		return
	var haut := Color(0.26, 0.23, 0.19, 0.95)
	var kante := Color(0.44, 0.38, 0.28, 0.9)
	var mx: float = FIGURE_RECT.position.x + FIGURE_RECT.size.x * 0.5
	# Kopf — die Oberkante ist FIGURE_RECT.position.y, damit der Helm-Kasten darüber Platz hat
	draw_circle(Vector2(mx, 92.0), 20.0, haut)
	draw_arc(Vector2(mx, 92.0), 20.0, 0.0, TAU, 28, kante, 1.4)
	# Hals
	draw_rect(Rect2(mx - 7.0, 110.0, 14.0, 12.0), haut)
	# Rumpf — oben breit (Schultern), zur Hüfte schmaler
	var rumpf: PackedVector2Array = PackedVector2Array([
		Vector2(mx - 40.0, 122.0), Vector2(mx + 40.0, 122.0),
		Vector2(mx + 30.0, 220.0), Vector2(mx - 30.0, 220.0)])
	draw_colored_polygon(rumpf, haut)
	_draw_outline(rumpf, kante)
	# Arme
	for seite in [-1.0, 1.0]:
		var arm: PackedVector2Array = PackedVector2Array([
			Vector2(mx + seite * 40.0, 124.0), Vector2(mx + seite * 54.0, 128.0),
			Vector2(mx + seite * 50.0, 216.0), Vector2(mx + seite * 36.0, 212.0)])
		draw_colored_polygon(arm, haut)
		_draw_outline(arm, kante)
	# Hüfte
	draw_rect(Rect2(mx - 30.0, 220.0, 60.0, 20.0), haut)
	# Beine
	for seite2 in [-1.0, 1.0]:
		var bein: PackedVector2Array = PackedVector2Array([
			Vector2(mx + seite2 * 4.0, 240.0), Vector2(mx + seite2 * 28.0, 240.0),
			Vector2(mx + seite2 * 24.0, 330.0), Vector2(mx + seite2 * 6.0, 330.0)])
		draw_colored_polygon(bein, haut)
		_draw_outline(bein, kante)


func _draw_outline(punkte: PackedVector2Array, col: Color) -> void:
	for i in punkte.size():
		draw_line(punkte[i], punkte[(i + 1) % punkte.size()], col, 1.4)
