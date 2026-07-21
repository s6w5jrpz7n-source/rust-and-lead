class_name CombatData extends RefCounted
## CombatData — verbindliche Kampf-Registries & Konstanten (Master-GDD §6, §7.1, §7.3).
##
## Reine Daten-/Konstantenklasse (nie instanziiert). Zugriff statisch:
##   CombatData.WEAPONS, CombatData.ENEMY_TYPES, CombatData.xp_for_kill(target), ...
##
## Schadensarten & Klassen werden bewusst als String-Konstanten geführt (GDD-konform,
## save-/datenfreundlich, identisch zu den im Prototyp verifizierten Werten).

# ── Schadensarten ─────────────────────────────────────────────────────────────
const KINETIC: String = "KINETIC"
const GALVANIC: String = "GALVANIC"
const ALCHEMICAL: String = "ALCHEMICAL"
const THERMAL: String = "THERMAL"

# ── Gegner-Klassen ────────────────────────────────────────────────────────────
const BIOLOGICAL: String = "BIOLOGICAL"
const MECHANICAL: String = "MECHANICAL"

# ── Status-Effekte ────────────────────────────────────────────────────────────
const FX_NONE: String = ""
const FX_STUN: String = "SHORT_CIRCUIT_STUN"    # Kurzschluss (4 s bewegungsunfähig)
const FX_BLEED: String = "BLEEDING_DOT"         # Verbluten (DOT, organisch)
const FX_BURN: String = "OVERHEAT_DOT"          # Überhitzung (DOT)
const FX_CORRODE: String = "ARMOR_CORRODED"     # Korrosion (Rüstungs-Debuff)

const STUN_MS: int = 4000
const DOT_MS: int = 3000
const DOT_TICK_SEC: float = 0.4

# ── Boss-/Elite-/Superboss-Konstanten ─────────────────────────────────────────
const BOSS_HP: int = 700
const BOSS_CONTACT: int = 28
const BOSS_GOLD: int = 20
const SUPERBOSS_MULT: int = 4

## Waffen-Loadout (Schadensart-Umschalter). Karabiner immer verfügbar; Rest nach Reveal.
const WEAPONS: Dictionary = {
	"karabiner": { "name": "Blei-Karabiner", "type": KINETIC, "base": 20, "fire_ms": 200, "acid": 0, "always": true },
	"voltgun":   { "name": "Leydener Volt-Karabiner", "type": GALVANIC, "base": 16, "fire_ms": 240, "acid": 0, "always": false },
	"saeure":    { "name": "Säure-Sprüher", "type": ALCHEMICAL, "base": 12, "fire_ms": 210, "acid": 10, "always": false },
	"brenner":   { "name": "Dampf-Brenner", "type": THERMAL, "base": 14, "fire_ms": 170, "acid": 0, "always": false },
}

## Gegner-Statblöcke (Master-GDD §7.3). `ranged` = Fernkämpfer-Parameter.
const ENEMY_TYPES: Dictionary = {
	"outlaw":    { "name": "Grenzgänger", "class": BIOLOGICAL, "sub": "outlaw", "hp": 55, "speed": 82, "armor": 0, "contact": 12, "gold_min": 1, "gold_max": 3 },
	"fauna":     { "name": "Ölfresser-Ratte", "class": BIOLOGICAL, "sub": "fauna", "hp": 32, "speed": 122, "armor": 0, "contact": 9, "gold_min": 1, "gold_max": 2, "swarm": true },
	"revolver":  { "name": "Revolverheld", "class": BIOLOGICAL, "sub": "outlaw", "hp": 48, "speed": 72, "armor": 0, "contact": 10, "gold_min": 2, "gold_max": 3, "ranged": { "min": 150, "max": 360, "dmg": 9, "rate": 1500 } },
	"konstrukt": { "name": "Konzern-Konstrukt", "class": MECHANICAL, "sub": "konstrukt", "hp": 95, "speed": 54, "armor": 15, "contact": 13, "gold_min": 2, "gold_max": 4, "ranged": { "min": 130, "max": 340, "dmg": 8, "rate": 1300 } },
	"klaeffer":  { "name": "Kessel-Kläffer", "class": MECHANICAL, "sub": "klaeffer", "hp": 40, "speed": 138, "armor": 5, "contact": 10, "gold_min": 1, "gold_max": 3, "swarm": true },
	"goliath":   { "name": "Schwerer Ernter", "class": MECHANICAL, "sub": "goliath", "hp": 900, "speed": 40, "armor": 30, "contact": 28, "gold_min": 24, "gold_max": 24, "front_immune": true, "boss": true },
}

# ── Ableitungen ───────────────────────────────────────────────────────────────

## XP für einen Kill (Master-GDD §7.5): Superboss 300, Elite 50, sonst max(3, hp/11).
static func xp_for_kill(target) -> int:
	if target.is_superboss:
		return 300
	if target.is_elite:
		return 50
	return maxi(3, roundi(float(target.max_health) / 11.0))

## Effektive Säure-Potenz einer Waffe inkl. Waffen-Level (Säure-Sprüher +2/Stufe).
static func weapon_acid(weapon_id: String, weapon_level: int) -> int:
	var w: Dictionary = WEAPONS.get(weapon_id, WEAPONS["karabiner"])
	return int(w["acid"]) + (weapon_level * 2 if weapon_id == "saeure" else 0)
