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
		"upgrades": GameState.upgrades.duplicate(true),
		"ng_plus": GameState.ng_plus,
		"gold": GameState.gold,
		"potions": GameState.potions,
		"inventory": GameState.inventory.duplicate(true),
		"equip": GameState.equip.duplicate(true),
		"bag": GameState.bag.duplicate(true),
		"ammo": GameState.ammo.duplicate(true),
		"mag": GameState.mag.duplicate(true),
		"cam_zoom": GameState.cam_zoom,
		"fog": GameState.fog.duplicate(),
		"economy": GameState.economy.duplicate(true),
		"kills": GameState.kills,
		"quests": GameState.quests.duplicate(true),
		"tracked_quest": GameState.tracked_quest,
		"weapons": GameState.weapons.duplicate(),
		"weapon_id": GameState.weapon_id,
		"prolog_done": GameState.prolog_done,
		"saw_rustwater": GameState.saw_rustwater,
		"saw_wake": GameState.saw_wake,
		"saw_vista": GameState.saw_vista,
		"erst_gegner_done": GameState.erst_gegner_done,
		# Die Schluessel. Sie FEHLTEN hier, und das war still und teuer: Wer drei Anfuehrer
		# erlegt, das Spiel beendet und wiederkommt, stand ohne sie da — die Beutekammer wieder
		# zu, und der einzige Hinweis waere ein Spieler gewesen, der sich fragt, ob er sie
		# geträumt hat. Ein neues Feld in `GameState` ist erst fertig, wenn es hier steht.
		"schluessel": GameState.schluessel,
		"met": GameState.met.duplicate(),
		"hour": GameState.hour,
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
	GameState.upgrades = _int_dict_with_defaults(data.get("upgrades", {}), { "damage": 0, "firerate": 0, "reload": 0, "hp": 0, "speed": 0, "regen": 0, "magnet": 0 })
	GameState.ng_plus = maxi(0, int(data.get("ng_plus", 0)))
	GameState.gold = maxi(0, int(data.get("gold", 0)))
	GameState.potions = maxi(0, int(data.get("potions", 3)))
	GameState.inventory = _int_dict_with_defaults(data.get("inventory", {}), { "schrott": 0, "zahnrad": 0, "dampfkern": 0 })
	GameState.equip = (data.get("equip", {}) as Dictionary).duplicate(true)
	GameState.bag = (data.get("bag", []) as Array).duplicate(true)
	# Fehlt der Block (Altstand vor der Munition), gibt es den vollen Startvorrat statt null —
	# ein geladenes Spiel, in dem man nicht schiessen kann, waere schlimmer als eines mit
	# geschenkter Munition.
	GameState.ammo = _int_dict_with_defaults(data.get("ammo", {}), AmmoData.fresh())
	GameState.mag = _int_dict_with_defaults(data.get("mag", {}), AmmoData.fresh_mags())
	GameState.cam_zoom = clampi(int(data.get("cam_zoom", OverworldView.CAM_ZOOM_DEFAULT)),
		0, OverworldView.CAM_ZOOM_STEPS.size() - 1)
	# Altstand ohne Nebel: Dann galt die ganze Karte als bekannt, und das soll auch so bleiben —
	# jemandem nachträglich die Karte wieder zuzuziehen, die er schon gelaufen ist, wäre die
	# unfreundlichste Art, eine neue Funktion einzuführen. Ein leeres Feld heisst „alles bekannt",
	# ein befülltes heisst „nur diese Zellen"; `FogOfWar` kennt diese Unterscheidung nicht, also
	# wird hier bei fehlendem Block die halbe Welt um Rustwater aufgedeckt.
	GameState.fog = {}
	var gespeichert: Dictionary = data.get("fog", {}) as Dictionary
	if gespeichert.is_empty():
		FogOfWar.fresh()
	else:
		for k in gespeichert:
			GameState.fog[int(k)] = 1
	GameState.economy = _int_dict_with_defaults(data.get("economy", {}), { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 })
	GameState.kills = maxi(0, int(data.get("kills", 0)))
	GameState.quests = (data.get("quests", {}) as Dictionary).duplicate(true)
	GameState.tracked_quest = String(data.get("tracked_quest", ""))
	GameState.weapons = Array(data.get("weapons", []))
	GameState.weapon_id = String(data.get("weapon_id", ""))
	GameState.prolog_done = bool(data.get("prolog_done", false))
	GameState.saw_rustwater = bool(data.get("saw_rustwater", false))
	GameState.saw_wake = bool(data.get("saw_wake", false))
	GameState.saw_vista = bool(data.get("saw_vista", false))
	GameState.erst_gegner_done = bool(data.get("erst_gegner_done", false))
	GameState.schluessel = maxi(0, int(data.get("schluessel", 0)))
	GameState.met = (data.get("met", {}) as Dictionary).duplicate()
	GameState.hour = float(data.get("hour", 7.5))
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


## Spielstand loeschen — die einzige Art, den Prolog noch einmal zu sehen.
##
## Das Spiel speichert automatisch, es gibt also keinen Zustand „noch nicht gespeichert": Wer
## einmal gestartet ist, faengt beim naechsten Mal mit Spielstand an und sieht das Aufwachen in
## der Grube nie wieder. Waehrend am Anfang gebaut wird, braucht es dafuer einen Weg.
##
## `true`, wenn danach wirklich keine Datei mehr da ist.
static func delete_slot(slot: int) -> bool:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return not FileAccess.file_exists(path)

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
