class_name InventoryGrid extends Control
## Der Beutel als RASTER (GDD §7.4) — 5 Spalten, 12 Zeilen, Fußabdrücke sichtbar.
##
## Vorher war der Beutel eine Liste mit der Zeile „2 Plätze" am Ende. Das ist dieselbe
## Information und trotzdem etwas völlig anderes: Ein Raster beantwortet die Frage „passt das
## noch?" mit einem Blick, eine Liste mit Kopfrechnen. Und der Fußabdruck ist bei uns eine
## echte Entscheidung — eine Rüstung frisst vier Zellen, ein Helm eine.
##
## Gezeichnet statt aus Knöpfen gebaut. Ein Knopf je Zelle wären 60 Steuerelemente, die bei
## jedem Öffnen neu entstehen; gezeichnet ist es eine Fläche, und der Tipp wird über
## `cell_at()` zurückgerechnet. Auf dem Handy ist das zudem der einzige Weg, Teile über mehrere
## Zellen als EIN Feld erscheinen zu lassen.
##
## Der Bildschirm daneben (`CharacterScreen`) entscheidet, was ein Tipp bedeutet — hier steht
## nur, wie es aussieht und welche Zelle getroffen wurde.

signal picked(bag_index: int)

const UiAssets = preload("res://scripts/UiAssets.gd")

## Zellenkante in Pixeln (bei 1280×720 Bezugsauflösung). 41 statt der ersten 44: Zwölf Zeilen
## à 44 + 3 Fuge sind 561 px, und zusammen mit Kopfzeile und Fußzeile der Tafel ragte die
## unterste Reihe in die Hinweiszeile. 41 ergibt 525 px und passt.
const CELL: float = 41.0
const GAP: float = 3.0          # Fuge zwischen den Zellen
## Mindestgröße einer Trefferfläche für einen Daumen. Ein 1×1-Teil ist 44 px groß, also knapp
## darunter — deshalb wird beim Tippen um `TOUCH_SLACK` großzügig gerundet, statt die Zellen
## aufzublasen (12 Zeilen × 48 px passen sonst nicht mehr auf 720 px Höhe).
const TOUCH_SLACK: float = 4.0

var selected: int = -1          # Beutel-Index, -1 = nichts gewählt

var _layout: Array = []         # Beutel-Index → Rect2i, aus `BagManager.layout()`


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Treffer prüft `cell_at`, nicht die GUI
	custom_minimum_size = grid_size()
	refresh()


static func grid_size() -> Vector2:
	return Vector2(float(BagManager.COLS) * (CELL + GAP) - GAP,
		float(BagManager.ROWS) * (CELL + GAP) - GAP)


func refresh() -> void:
	_layout = BagManager.layout()
	if selected >= GameState.bag.size():
		selected = -1
	queue_redraw()


## Welches Teil liegt unter diesem Punkt? (-1 = leere Zelle oder daneben)
##
## `at` ist bildschirmrelativ; gerechnet wird gegen die eigene Lage, damit der Aufrufer die
## Verschachtelung nicht kennen muss.
func cell_at(at: Vector2) -> int:
	var lokal: Vector2 = at - global_position
	var s: Vector2 = grid_size()
	if lokal.x < -TOUCH_SLACK or lokal.y < -TOUCH_SLACK \
			or lokal.x > s.x + TOUCH_SLACK or lokal.y > s.y + TOUCH_SLACK:
		return -1
	var spalte: int = int(floor(clampf(lokal.x, 0.0, s.x - 1.0) / (CELL + GAP)))
	var zeile: int = int(floor(clampf(lokal.y, 0.0, s.y - 1.0) / (CELL + GAP)))
	for i in _layout.size():
		var r: Rect2i = _layout[i]
		if r.position.x < 0:
			continue
		if spalte >= r.position.x and spalte < r.position.x + r.size.x \
				and zeile >= r.position.y and zeile < r.position.y + r.size.y:
			return i
	return -1


## Tipp verarbeiten. `true`, wenn er hier verbraucht wurde.
func tap(at: Vector2) -> bool:
	var s: Vector2 = grid_size()
	if not Rect2(global_position - Vector2(TOUCH_SLACK, TOUCH_SLACK),
			s + Vector2(TOUCH_SLACK, TOUCH_SLACK) * 2.0).has_point(at):
		return false
	var treffer: int = cell_at(at)
	# Nochmal auf dasselbe Teil tippen hebt die Wahl auf — sonst gibt es auf dem Handy keinen
	# Weg, eine Auswahl loszuwerden, ohne den ganzen Bildschirm zu schliessen.
	selected = -1 if treffer == selected else treffer
	queue_redraw()
	picked.emit(selected)
	return true


func _rect_of(r: Rect2i) -> Rect2:
	return Rect2(Vector2(float(r.position.x) * (CELL + GAP), float(r.position.y) * (CELL + GAP)),
		Vector2(float(r.size.x) * (CELL + GAP) - GAP, float(r.size.y) * (CELL + GAP) - GAP))


func _draw() -> void:
	# 1. Leeres Raster: jede Zelle als eigene Vertiefung. Ein durchgehendes Gitter aus Linien
	#    liest sich als Tabelle, einzelne Felder als Fächer, in die etwas hineingehört.
	for zeile in BagManager.ROWS:
		for spalte in BagManager.COLS:
			draw_rect(_rect_of(Rect2i(spalte, zeile, 1, 1)), Color(0.10, 0.09, 0.08, 0.85))
			draw_rect(_rect_of(Rect2i(spalte, zeile, 1, 1)), Color(0.28, 0.24, 0.19, 0.9),
				false, 1.0)
	# 2. Die Teile darüber, jedes über seinen ganzen Fußabdruck.
	var schrift: Font = get_theme_default_font()
	for i in _layout.size():
		var r: Rect2i = _layout[i]
		if r.position.x < 0 or i >= GameState.bag.size():
			continue
		var g: Dictionary = GameState.bag[i]
		var col: Color = ProgressionManager.RARITY_COLOR.get(String(g.get("rarity", "common")),
			Color.WHITE)
		var feld: Rect2 = _rect_of(r)
		draw_rect(feld, Color(col.r, col.g, col.b, 0.22))
		draw_rect(feld, col, false, 2.0 if i == selected else 1.0)
		if i == selected:
			# Ausgewähltes Feld doppelt umrandet statt farblich verändert: Die Farbe TRÄGT hier
			# Bedeutung (Seltenheit), die darf die Auswahl nicht überschreiben.
			draw_rect(feld.grow(3.0), Color(1.0, 0.94, 0.72, 0.95), false, 2.0)
		# Sinnbild der Kategorie, mittig — als Grafik, wenn eine liegt, sonst als Zeichen.
		# Ein Zeichen ist auf jedem Betriebssystem ein anderes; ein gemalter Helm passt zum
		# Spiel, Apples Bauarbeiterhelm nicht.
		var slot: String = String(g.get("slot", ""))
		if not UiAssets.draw_fitted(self, "icon_" + slot, feld.grow(-4.0)):
			var zeichen: String = String(SLOT_ICON.get(slot, "?"))
			var groesse: Vector2 = schrift.get_string_size(zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
			draw_string(schrift, feld.position + (feld.size - groesse) * 0.5 + Vector2(0.0, groesse.y * 0.78),
				zeichen, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)


## Sinnbild je Ausrüstungs-Kategorie. Bewusst hier und nicht in `ProgressionManager`: Das ist
## eine Darstellungsfrage, keine Spielregel.
const SLOT_ICON: Dictionary = {
	"helmet": "◓", "armor": "♜", "weapon": "⚔", "gadget": "⚙", "boots": "◣", "plate": "▦",
}
