class_name GridInventoryBackend extends RefCounted
## GridInventoryBackend — reines, mathematisches Diablo-Style-Grid (Master-GDD §7.4).
##
## Validiert Item-Platzierung VOR jeder UI-Zeichnung. Keine Rendering-/Szenen-Abhängigkeit.
## High-Performance: das 2D-Gitter wird als flaches `PackedInt32Array` gehalten
## (Index = row × cols + col), Zelle = `EMPTY` (-1) oder die `uid` (int) eines Items.
## Zusätzlich merkt sich `_placements` je uid das belegte Rechteck (O(1)-Entfernen).

const EMPTY: int = -1

var cols: int = 10
var rows: int = 8
var _cells: PackedInt32Array = PackedInt32Array()
var _placements: Dictionary = {}   # uid (int) -> Rect2i(col, row, width, height)


func _init(p_cols: int = 10, p_rows: int = 8) -> void:
	cols = maxi(1, p_cols)
	rows = maxi(1, p_rows)
	_cells.resize(cols * rows)
	_cells.fill(EMPTY)


# ── Item-Fußabdrücke (GDD §7.4) ───────────────────────────────────────────────
## Rüstung 2×2, Waffe 2×1, schwere Waffe 3×1, alles andere (Helm/Stiefel/Gadget/
## Panzerplatte/Material-Stapel) 1×1. Rückgabe als Vector2i(width, height).
static func footprint(kind: String) -> Vector2i:
	match kind:
		"armor":
			return Vector2i(2, 2)
		"weapon":
			return Vector2i(2, 1)
		"heavy_weapon":
			return Vector2i(3, 1)
		_:
			return Vector2i(1, 1)   # helmet, boots, gadget, plate, material


# ── Basis-Zugriff ─────────────────────────────────────────────────────────────
func _index(col: int, row: int) -> int:
	return row * cols + col

func in_bounds(col: int, row: int) -> bool:
	return col >= 0 and row >= 0 and col < cols and row < rows

## Inhalt einer Zelle: uid oder EMPTY (auch für Out-of-Bounds -> EMPTY).
func cell(col: int, row: int) -> int:
	if not in_bounds(col, row):
		return EMPTY
	return _cells[_index(col, row)]


# ── Footprint-Prüfung ─────────────────────────────────────────────────────────
## Ist der rechteckige Block (col,row,width,height) vollständig frei UND innerhalb der
## Grenzen? O(width×height).
func can_fit_item(col: int, row: int, width: int, height: int) -> bool:
	if width <= 0 or height <= 0:
		return false
	if col < 0 or row < 0 or col + width > cols or row + height > rows:
		return false
	for r in range(row, row + height):
		for c in range(col, col + width):
			if _cells[_index(c, r)] != EMPTY:
				return false
	return true


# ── Einfügen / Entfernen ──────────────────────────────────────────────────────
## Belegt den Zellblock mit der uid, wenn die Validierung besteht. false bei
## ungültiger Position, Überlappung, oder bereits platzierter uid (Korruptionsschutz).
func insert_item(item_uid: int, col: int, row: int, width: int, height: int) -> bool:
	assert(item_uid != EMPTY, "GridInventoryBackend: uid darf nicht EMPTY (-1) sein")
	if _placements.has(item_uid):
		return false   # dieselbe uid nie doppelt platzieren
	if not can_fit_item(col, row, width, height):
		return false
	for r in range(row, row + height):
		for c in range(col, col + width):
			_cells[_index(c, r)] = item_uid
	_placements[item_uid] = Rect2i(col, row, width, height)
	return true

## Findet alle von der uid belegten Koordinaten und setzt sie zurück auf EMPTY.
## Kein Effekt, wenn die uid nicht platziert ist (idempotent).
func remove_item(item_uid: int) -> void:
	if not _placements.has(item_uid):
		return
	var rect: Rect2i = _placements[item_uid]
	for r in range(rect.position.y, rect.position.y + rect.size.y):
		for c in range(rect.position.x, rect.position.x + rect.size.x):
			_cells[_index(c, r)] = EMPTY
	_placements.erase(item_uid)


# ── Auto-Platzierung (Loot-Drop) ──────────────────────────────────────────────
## Scannt zeilenweise (row-major) nach dem ersten Block, der ein Item der Größe
## width×height aufnehmen kann. Rückgabe Vector2i(col,row), oder (-1,-1) falls kein Platz.
func find_first_empty_space(width: int, height: int) -> Vector2i:
	for row in range(rows):
		for col in range(cols):
			if can_fit_item(col, row, width, height):
				return Vector2i(col, row)
	return Vector2i(-1, -1)

## Komfort: sucht den ersten freien Platz und fügt dort ein. false, wenn kein Platz.
func place_first(item_uid: int, width: int, height: int) -> bool:
	var pos: Vector2i = find_first_empty_space(width, height)
	if pos.x < 0:
		return false
	return insert_item(item_uid, pos.x, pos.y, width, height)


# ── Kapazitäts-Abfragen ───────────────────────────────────────────────────────
func total_cells() -> int:
	return cols * rows

func used_cells() -> int:
	var n: int = 0
	for v in _cells:
		if v != EMPTY:
			n += 1
	return n

func free_cells() -> int:
	return total_cells() - used_cells()

func has_item(item_uid: int) -> bool:
	return _placements.has(item_uid)

## Belegtes Rechteck einer uid (Rect2i) oder Rect2i() (leer), falls nicht platziert.
func placement_of(item_uid: int) -> Rect2i:
	if not _placements.has(item_uid):
		return Rect2i()
	return _placements[item_uid]

func clear() -> void:
	_cells.fill(EMPTY)
	_placements.clear()
