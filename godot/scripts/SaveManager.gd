class_name SaveManager extends RefCounted
## SaveManager — Persistenz des Spielstands (Master-GDD §2.3). Serialisiert genau die
## `GameState`-Felder in eine Dictionary/JSON und stellt sie defensiv wieder her.
##
## Reine Logik (`class_name`, statisch). JSON-tauglich & versionsstabil: Quest-Zustände bleiben
## Strings, Zahlen werden beim Laden defensiv gecastet (JSON kennt nur Floats). Fehlende/kaputte
## Felder fallen auf sichere Defaults zurück (Korruptionsschutz).

const SAVE_VERSION: int = 1

# ── Serialisierung ────────────────────────────────────────────────────────────

## Momentaufnahme der persistenten GameState-Felder (Container werden tief kopiert).
static func serialize() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"current_chapter": GameState.current_chapter,
		"is_revealed": GameState.is_revealed,
		"chosen_guild": GameState.chosen_guild,
		"level": GameState.level,
		"xp": GameState.xp,
		"perk_points": GameState.perk_points,
		"perks": GameState.perks.duplicate(true),
		"gold": GameState.gold,
		"potions": GameState.potions,
		"inventory": GameState.inventory.duplicate(true),
		"economy": GameState.economy.duplicate(true),
		"kills": GameState.kills,
		"quests": GameState.quests.duplicate(true),
		"quest_base": GameState.quest_base.duplicate(true),
		"memories_found": GameState.memories_found,
		"memorials_seen": GameState.memorials_seen.duplicate(),
		"family_buried": GameState.family_buried,
		"codex": GameState.codex.duplicate(),
	}

## Stellt den Zustand aus einer Dictionary wieder her. Defensiv: fehlende Felder → Default,
## Zahlen werden gecastet (JSON-Floats → int), Pflicht-Schlüssel garantiert.
static func deserialize(data: Dictionary) -> void:
	GameState.current_chapter = int(data.get("current_chapter", 1))
	GameState.is_revealed = bool(data.get("is_revealed", false))
	var g: Variant = data.get("chosen_guild", null)
	GameState.chosen_guild = String(g) if g != null else null
	GameState.level = maxi(1, int(data.get("level", 1)))
	GameState.xp = maxi(0, int(data.get("xp", 0)))
	GameState.perk_points = maxi(0, int(data.get("perk_points", 0)))
	GameState.perks = _int_dict(data.get("perks", {}))
	GameState.gold = maxi(0, int(data.get("gold", 0)))
	GameState.potions = maxi(0, int(data.get("potions", 3)))
	GameState.inventory = _int_dict_with_defaults(data.get("inventory", {}), { "schrott": 0, "zahnrad": 0, "dampfkern": 0 })
	GameState.economy = _int_dict_with_defaults(data.get("economy", {}), { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 })
	GameState.kills = maxi(0, int(data.get("kills", 0)))
	GameState.quests = (data.get("quests", {}) as Dictionary).duplicate(true)
	GameState.quest_base = _int_dict(data.get("quest_base", {}))
	GameState.memories_found = clampi(int(data.get("memories_found", 0)), 0, MemoryManager.chain_length())
	GameState.memorials_seen = _str_array(data.get("memorials_seen", []))
	GameState.family_buried = bool(data.get("family_buried", false))
	GameState.codex = _str_array(data.get("codex", []))

# ── JSON ──────────────────────────────────────────────────────────────────────

static func to_json() -> String:
	return JSON.stringify(serialize())

## Lädt aus einem JSON-String; gibt Erfolg zurück (false bei Parse-Fehler/Nicht-Dictionary).
static func from_json(s: String) -> bool:
	var parsed: Variant = JSON.parse_string(s)
	if parsed is Dictionary:
		deserialize(parsed)
		return true
	return false

# ── Datei-Slots ───────────────────────────────────────────────────────────────

static func slot_path(slot: int) -> String:
	return "user://rustlead_save_%d.json" % slot

static func save_to_slot(slot: int) -> bool:
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(to_json())
	f.close()
	return true

static func load_from_slot(slot: int) -> bool:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var s: String = f.get_as_text()
	f.close()
	return from_json(s)

static func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

# ── Helfer ────────────────────────────────────────────────────────────────────

static func _int_dict(src: Variant) -> Dictionary:
	var out: Dictionary = {}
	if src is Dictionary:
		for k in src:
			out[k] = int(src[k])
	return out

static func _int_dict_with_defaults(src: Variant, defaults: Dictionary) -> Dictionary:
	var out: Dictionary = defaults.duplicate()
	if src is Dictionary:
		for k in src:
			out[k] = int(src[k])
	return out

static func _str_array(src: Variant) -> Array:
	var out: Array = []
	if src is Array:
		for v in src:
			out.append(String(v))
	return out
