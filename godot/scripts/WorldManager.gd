class_name WorldManager extends RefCounted
## WorldManager — Weltgeografie, Sektoren & Progressions-Gating (Master-GDD §1.6/§1.7).
##
## Reine Logik/Daten (`class_name`, statisch — kein Autoload nötig). Alle Gate-Zustände
## werden aus `GameState` abgeleitet (Kapitel, Gilde, Gebäudestufe); es gibt keinen
## dupliziten Zustand, der auseinanderlaufen könnte.
##
## Koordinatensystem: Ursprung (0,0) SW-Ecke, X = West→Ost, Y = Süd→Nord, jeweils 0…2000 m.

# ── Sektorgrenzen (horizontale Y-Linien) ──────────────────────────────────────
const WORLD_SIZE: int = 2000
const BORDER_S1_S2_Y: int = 800     # Sprengtore (Hard Gate 1)
const BORDER_S2_S3_Y: int = 1500    # Smog-Linie (Hard Gate 2), == SMOG_LINE_Y
const SMOG_LINE_Y: int = 1500

# ── Gating-Parameter ──────────────────────────────────────────────────────────
const BLAST_GATE_CHAPTER: int = 5              # ab hier ist der Panzerzug durchgebrochen
const REFINERY_BUILDING: String = "laboratory" # Raffinerie/Labor fürs Smog-Gate (§1.7.2)
const FILTER_REQUIRED_LEVEL: int = 3           # Alchemie-Filter ab Gebäudestufe 3
const SMOG_LETHAL_SECONDS: float = 3.0         # Smog tickt Leben in 3 s auf 0

## Fraktions-HQs → besitzende Gilde (für dynamische Feindseligkeit, §1.7.3).
const BASE_GUILD: Dictionary = {
	"fort_freedom": "rebels",
	"sektor01": "corp",
	"rogues_landing": "smugglers",
}

## Points of Interest (Master-GDD §1.6.1). `sector` 1–3; `multilevel`/`floors` für Dungeons.
const POIS: Dictionary = {
	# ── Sektor 1 (Kapitel 1–4) ──
	"rustwater":            { "name": "Rustwater Hub & Basis", "x": 300, "y": 300, "sector": 1, "type": "hub" },
	"schrott_minen":        { "name": "Die Schrott-Minen", "x": 150, "y": 450, "sector": 1, "type": "dungeon", "multilevel": true, "floors": 3 },
	"rattengestruepp":      { "name": "Das Rattengestrüpp", "x": 500, "y": 200, "sector": 1, "type": "hunting" },
	"zugdepot":             { "name": "Iron Rail Zugdepot", "x": 450, "y": 750, "sector": 1, "type": "boss_arena", "gate": "blast" },
	# ── Sektor 2 (Kapitel 5–8) ──
	"fort_freedom":         { "name": "Fort Freedom", "x": 200, "y": 1200, "sector": 2, "type": "base", "guild": "rebels" },
	"sektor01":             { "name": "Sektor 01", "x": 1700, "y": 1300, "sector": 2, "type": "base", "guild": "corp" },
	"rogues_landing":       { "name": "Rogue's Landing", "x": 950, "y": 950, "sector": 2, "type": "base", "guild": "smugglers" },
	"alchemie_raffinerie":  { "name": "Alchemie-Raffinerie", "x": 1000, "y": 1450, "sector": 2, "type": "refinery", "gate": "smog" },
	# ── Sektor 3 (Kapitel 9–12) ──
	"goliath_testgelaende": { "name": "Goliath-Testgelände", "x": 600, "y": 1750, "sector": 3, "type": "openworld" },
	"schmelzoefen_vulcan":  { "name": "Schmelzöfen von Vulcan", "x": 1400, "y": 1800, "sector": 3, "type": "dungeon", "multilevel": true, "floors": 4 },
	"eisernes_herz":        { "name": "Das Eiserne Herz", "x": 1000, "y": 1950, "sector": 3, "type": "final_dungeon", "multilevel": true, "floors": 5 },
}


# ── POI-Abfragen ──────────────────────────────────────────────────────────────

static func has_poi(poi_id: String) -> bool:
	return POIS.has(poi_id)

static func poi(poi_id: String) -> Dictionary:
	assert(POIS.has(poi_id), "WorldManager: unbekannter POI '%s'" % poi_id)
	return POIS[poi_id]

static func poi_position(poi_id: String) -> Vector2:
	var p: Dictionary = poi(poi_id)
	return Vector2(float(p["x"]), float(p["y"]))

static func dungeon_floors(poi_id: String) -> int:
	# 0 = kein (multilevel) Dungeon; 1 = einstufige Arena (z. B. Zugdepot).
	var p: Dictionary = poi(poi_id)
	if bool(p.get("multilevel", false)):
		return int(p.get("floors", 1))
	return 1 if String(p.get("type", "")) == "boss_arena" else 0

static func nearest_poi(pos: Vector2) -> String:
	var best_id: String = ""
	var best_d: float = INF
	for id in POIS.keys():
		var d: float = pos.distance_squared_to(poi_position(id))
		if d < best_d:
			best_d = d
			best_id = id
	return best_id


# ── Sektor-Logik ──────────────────────────────────────────────────────────────

static func sector_of_y(y: float) -> int:
	if y < BORDER_S1_S2_Y:
		return 1
	if y < BORDER_S2_S3_Y:
		return 2
	return 3

static func sector_of_pos(pos: Vector2) -> int:
	return sector_of_y(pos.y)


# ── Gate 1: Iron-Rail-Sprengtore (Y = 800), Kapitel-4-Reveal ──────────────────

## Ist der Panzerzug durch die Sprengtore gebrochen? (Kapitel 4 abgeschlossen.)
static func is_blast_gate_open() -> bool:
	return GameState.current_chapter >= BLAST_GATE_CHAPTER

## Darf der Spieler die Nordgrenze von Sektor 1 (Y = 800) überschreiten?
## Prüft nur die tatsächliche Nord-Querung; Bewegung innerhalb eines Sektors ist frei.
static func can_cross_blast_line(from_y: float, to_y: float) -> bool:
	var crossing_north: bool = from_y < BORDER_S1_S2_Y and to_y >= BORDER_S1_S2_Y
	if crossing_north:
		return is_blast_gate_open()
	return true


# ── Gate 2: Alchemistische Smog-Linie (Y = 1500), Raffinerie-Stufe 3 ──────────

## Hat das Chassis den Alchemie-Filter (Raffinerie/Labor auf Stufe 3)?
static func has_alchemie_filter() -> bool:
	return GameState.building_level(REFINERY_BUILDING) >= FILTER_REQUIRED_LEVEL

static func is_in_smog(pos: Vector2) -> bool:
	return pos.y >= SMOG_LINE_Y

## Umwelt-DOT der Smog-Zone für diesen Frame. Ohne Filter tödlich (max_hp in 3 s auf 0);
## mit Filter oder außerhalb der Zone 0. Der Player-Controller wendet das Ergebnis an.
static func smog_dot_damage(pos: Vector2, delta_sec: float) -> int:
	if not is_in_smog(pos) or has_alchemie_filter():
		return 0
	return ceili(float(GameState.max_hp()) / SMOG_LETHAL_SECONDS * delta_sec)


# ── Sektor-Zutritt (kombiniert) ───────────────────────────────────────────────

## Grundsätzlicher Zutritt zu einem Sektor (Story-/Ausrüstungs-Gate).
## Sektor 3 ist zwar physisch betretbar, aber ohne Filter durch den Smog-DOT tödlich —
## `can_enter_sector(3)` bildet die *sichere* Zugänglichkeit ab.
static func can_enter_sector(sector: int) -> bool:
	match sector:
		1:
			return true
		2:
			return is_blast_gate_open()
		3:
			return is_blast_gate_open() and has_alchemie_filter()
	return false


# ── Gate 3: Dynamische Fraktions-Feindseligkeit (Sektor 2) ────────────────────

## Ist ein Fraktions-HQ feindlich? Vor der Gildenwahl niemand; danach jedes fremde HQ
## (Geschützturm-Aggro & Verstärkung, §1.7.3). Basiert allein auf `GameState.chosen_guild`.
static func is_base_hostile(base_id: String) -> bool:
	if GameState.chosen_guild == null:
		return false
	var owner: Variant = BASE_GUILD.get(base_id, null)
	if owner == null:
		return false
	return owner != GameState.chosen_guild

## Ist ein Fraktions-HQ friedlich betretbar (Händler/Truhe/Dialog)?
static func is_base_friendly(base_id: String) -> bool:
	if not BASE_GUILD.has(base_id):
		return true
	return not is_base_hostile(base_id)
