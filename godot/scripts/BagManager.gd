class_name BagManager
## Beutel — aufgesammelte Ausrüstung, begrenzt durch das Grid-Inventar (GDD §7.4).
##
## `GameState.bag` ist eine flache Liste; der Platzbedarf steckt in den **Fußabdrücken**:
## Eine Rüstung belegt 2×2 Zellen, eine Waffe 2×1, alles andere 1×1. Deshalb ist „voll" nicht
## einfach eine Stückzahl — fünf Rüstungen brauchen so viel Platz wie zwanzig Helme.
##
## Gerechnet wird mit dem echten `GridInventoryBackend` (Modul 3), das bislang von keiner
## Spielszene benutzt wurde: Vor jedem Einpacken wird das Raster aus der Liste nachgebaut und
## gefragt, ob das neue Teil noch hineinpasst. Bei einer Handvoll Teilen ist das billiger als
## ein zweiter, parallel gepflegter Zustand — und es kann nicht auseinanderlaufen.

const COLS: int = 5    # GDD §7.4: „Das Grid ist 5 Spalten breit"
const ROWS: int = 12

## Fußabdruck je Ausrüstungs-Slot (GDD §7.4 „Grid-Fußabdruck").
const FOOTPRINT: Dictionary = {
	"armor": Vector2i(2, 2), "weapon": Vector2i(2, 1),
	"helmet": Vector2i(1, 1), "gadget": Vector2i(1, 1), "boots": Vector2i(1, 1),
	"plate": Vector2i(1, 1),
}


static func footprint(gear: Dictionary) -> Vector2i:
	return FOOTPRINT.get(String(gear.get("slot", "")), Vector2i(1, 1))


## Baut das Raster aus der aktuellen Beutel-Liste nach. `extra` testet zusätzlich ein noch
## nicht eingepacktes Teil — so beantwortet dieselbe Funktion „ist voll?" und „passt das noch?".
static func _pack(extra: Dictionary = {}) -> bool:
	var grid := GridInventoryBackend.new(COLS, ROWS)
	var uid: int = 0
	for item in GameState.bag:
		var f: Vector2i = footprint(item)
		if not grid.place_first(uid, f.x, f.y):
			return false
		uid += 1
	if extra.is_empty():
		return true
	var fe: Vector2i = footprint(extra)
	return grid.place_first(uid, fe.x, fe.y)


static func has_room_for(gear: Dictionary) -> bool:
	return _pack(gear)


## WO im Raster jedes Teil liegt: Beutel-Index → Rect2i(Spalte, Zeile, Breite, Höhe).
##
## Bisher hat `_pack` die Belegung berechnet und weggeworfen — es brauchte nur ein Ja/Nein.
## Ein Beutel, den man SIEHT, braucht sie: Dass eine Rüstung 2×2 Zellen frisst und ein Helm
## eine, ist genau der Unterschied zwischen einem Raster und einer Stückzahl. Dieselbe Packung
## wie in `_pack`, damit Anzeige und Kapazitätsprüfung nicht auseinanderlaufen können.
static func layout() -> Array:
	var grid := GridInventoryBackend.new(COLS, ROWS)
	var out: Array = []
	for i in GameState.bag.size():
		var f: Vector2i = footprint(GameState.bag[i])
		if not grid.place_first(i, f.x, f.y):
			out.append(Rect2i(-1, -1, f.x, f.y))   # passt nicht mehr; sollte nie vorkommen
			continue
		out.append(grid.placement_of(i))
	return out


static func add(gear: Dictionary) -> bool:
	if gear.is_empty() or not has_room_for(gear):
		return false
	GameState.bag.append(gear)
	return true


static func remove_at(index: int) -> Dictionary:
	if index < 0 or index >= GameState.bag.size():
		return {}
	var g: Dictionary = GameState.bag[index]
	GameState.bag.remove_at(index)
	return g


## Belegte Zellen — für die Kopfzeile „x/y Plätze".
static func used_cells() -> int:
	var n: int = 0
	for item in GameState.bag:
		var f: Vector2i = footprint(item)
		n += f.x * f.y
	return n


static func total_cells() -> int:
	return COLS * ROWS


## Ein Teil aus dem Beutel anlegen. Das bisher getragene wandert zurück in den Beutel — es
## einfach fallenzulassen wäre die Art von stillem Verlust, die man erst drei Kämpfe später
## bemerkt. Passt es nicht mehr hinein, scheitert der Tausch lieber ganz.
static func equip_from_bag(index: int) -> bool:
	if index < 0 or index >= GameState.bag.size():
		return false
	var gear: Dictionary = GameState.bag[index]
	var slot: String = String(gear.get("slot", ""))
	if not EquipManager.slot_accepts(slot, gear):
		return false
	var old: Dictionary = EquipManager.equipped(slot)
	GameState.bag.remove_at(index)
	if not old.is_empty() and not add(old):
		GameState.bag.insert(index, gear)   # Rolle rückwärts: Zustand bleibt exakt wie vorher
		return false
	return EquipManager.equip_item(gear, slot)


## Getragenes Teil ablegen — zurück in den Beutel, wenn Platz ist.
static func unequip_to_bag(slot: String) -> bool:
	var worn: Dictionary = EquipManager.equipped(slot)
	if worn.is_empty() or not has_room_for(worn):
		return false
	EquipManager.unequip(slot)
	return add(worn)


## Verschrotten: Ausrüstung zu Schrott recyceln (GDD §7.4 „Ablegen/Verschrotten", 1–4 ▬ je
## Seltenheit). Der Beutel läuft sonst zu, und Beute, die man nicht loswird, ist Ballast.
static func scrap_at(index: int) -> int:
	var g: Dictionary = remove_at(index)
	if g.is_empty():
		return 0
	var tier: int = ProgressionManager.RARITY_ORDER.find(String(g.get("rarity", "common")))
	var scrap: int = clampi(tier + 1, 1, 4)
	GameState.add_item("schrott", scrap)
	return scrap
