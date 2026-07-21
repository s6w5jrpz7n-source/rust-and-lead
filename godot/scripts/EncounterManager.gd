class_name EncounterManager extends RefCounted
## EncounterManager — Mini-Dungeons (Kritter-Hallen) & Unique-Champions (Master-GDD §7.5.6a/§8.2).
##
## Reine Logik/Daten (`class_name`, statisch). Portiert aus dem validierten Web-Prototyp
## (`CRITTER_THEMES`, `spawnUniqueLeader`, Champion-Beute). Determinismus: alle Würfe nehmen
## optional einen `roll`/`name_roll` (0..1) statt `randf()`, damit die Pfade testbar sind.
##
## Hinweis: `champion_loot()` liefert den **Beute-Kontrakt** (garantiertes Legendary etc.);
## die konkrete Item-Erzeugung ist Aufgabe des noch offenen `ProgressionManager` (§8.1).

# ── Kritter-Hallen-Themen (Palette/Schwarm-Art pro Betreten neu gewürfelt) ────
const HALL_THEMES: Array = [
	{ "id": "rats", "name": "Rattennest", "type": "fauna", "count": 11 },
	{ "id": "klaeffer", "name": "Kläffer-Wurf", "type": "klaeffer", "count": 9 },
	{ "id": "outlaws", "name": "Banditenloch", "type": "outlaw", "count": 7 },
]

# ── Unique-Champions (Diablo-Pack): benannte Anführer mit garantiertem Legendary ──
const UNIQUE_NAMES: Array = [
	"Rostzahn, der Grubenkönig",
	"Blechhaut die Unersättliche",
	"Öldarm der Verschlinger",
	"Sable Schnellklaue",
	"Die Rasselnde Mutter",
	"Kessel-Baronin Vex",
]

## Slots mit benannten Legendaries — ein Champion lässt garantiert eines davon fallen.
const CHAMPION_LEGENDARY_SLOTS: Array = ["weapon", "armor", "gadget", "boots", "helmet"]

# ── Hallen-Themen ─────────────────────────────────────────────────────────────

## Würfelt ein Hallen-Thema. `roll` (0..1) macht die Auswahl deterministisch.
static func roll_hall_theme(roll: float = -1.0) -> Dictionary:
	var r: float = roll if roll >= 0.0 else randf()
	var idx: int = clampi(int(floor(r * HALL_THEMES.size())), 0, HALL_THEMES.size() - 1)
	return HALL_THEMES[idx]

# ── Champion-Wurf & Rudelgröße ────────────────────────────────────────────────

## ~30 %: der Hallen-Anführer ist ein Unique-Champion (WorldManager.UNIQUE_CHAMPION_CHANCE).
static func is_unique_pack(roll: float = -1.0) -> bool:
	var r: float = roll if roll >= 0.0 else randf()
	return r < WorldManager.UNIQUE_CHAMPION_CHANCE

## Rudelgröße: Basis aus dem Thema, ein Champion führt drei zusätzliche Kritter.
static func pack_size(theme: Dictionary, is_unique: bool) -> int:
	return int(theme["count"]) + (3 if is_unique else 0)

static func champion_name(name_roll: float = -1.0) -> String:
	var r: float = name_roll if name_roll >= 0.0 else randf()
	var idx: int = clampi(int(floor(r * UNIQUE_NAMES.size())), 0, UNIQUE_NAMES.size() - 1)
	return UNIQUE_NAMES[idx]

# ── Champion-Aufbau ───────────────────────────────────────────────────────────

## Baut den Unique-Anführer aus einem Basis-Typ: ×6 Leben (× Skalierung), +Panzerung,
## ×1.5 Kontaktschaden, benannt, als Boss (eigene Lebensleiste). `hp_mul` = Tiefen-/NG+-Faktor.
static func make_champion(base_type: String, name_roll: float = -1.0, hp_mul: float = 1.0) -> CombatTarget:
	var t: Dictionary = CombatData.ENEMY_TYPES[base_type]
	var e := CombatTarget.from_type(base_type)
	e.is_unique = true
	e.is_boss = true
	e.max_health = roundi(int(t["hp"]) * 6.0 * hp_mul)
	e.health = e.max_health
	e.armor = int(t.get("armor", 0)) + 6
	e.max_armor = e.armor
	e.contact_dps = roundi(int(t.get("contact", 0)) * 1.5)
	e.gold = 45
	e.display_name = champion_name(name_roll)
	return e

# ── Beute-Kontrakt (Item-Erzeugung: ProgressionManager, §8.1) ─────────────────

## Was ein erlegter Champion garantiert abwirft. Der Loot-Layer setzt das um.
static func champion_loot() -> Dictionary:
	return {
		"legendary_guaranteed": true,
		"legendary_slots": CHAMPION_LEGENDARY_SLOTS,
		"boss_chests": 2,
		"gold_mult": 2,
		"counts_as_boss": true,
	}
