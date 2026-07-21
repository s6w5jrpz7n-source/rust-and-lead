class_name PlayerStats extends RefCounted
## PlayerStats — effektive Kampfwerte des Spielers (Master-GDD §6/§7.5). Aggregiert **alle**
## portierten Systeme zu den finalen Zahlen: Basis-Waffe (`CombatData`) + Werkstatt-Upgrades
## (`GameState.upgrades`) + angelegte Ausrüstung (`EquipManager`) + Perks (`ProgressionManager`)
## + getragene/Set-verliehene legendäre Kräfte (`EquipManager.has_power`).
##
## Reine Logik (`class_name`, statisch), deterministisch. Das ist der „Kapstein", der Perks, Sets
## und Legendaries in tatsächliche Offense/Defense übersetzt. Formeln 1:1 aus dem Prototyp.

const BASE_SPEED: float = 240.0
const BASE_REGEN: int = 8
const BASE_MAGNET: int = 130
const SPREAD_BASE: int = 7

# ── Interne Helfer ────────────────────────────────────────────────────────────

## Eine legendäre Kraft aktiv (direkt getragen ODER von einem Set verliehen)?
static func _power(p: String) -> bool:
	return EquipManager.has_power(p)

## Kapstein-Effekt eines Zweigs aktiv — als Perk gewählt ODER von einem Set verliehen.
static func _cap(branch: String) -> bool:
	return ProgressionManager.has_cap(branch) or EquipManager.has_power("cap_" + branch)

static func _up(key: String) -> int:
	return int(GameState.upgrades.get(key, 0))

static func _energy(weapon_id: String) -> bool:
	return weapon_id != "karabiner"   # alle außer Karabiner nutzen Energiekristalle

# ── Offense ───────────────────────────────────────────────────────────────────

## Schaden pro Schuss: Basis + Upgrade + Waffen-Level + Ausrüstung + Scharfschütze
## (+ Überladung bei Energiewaffen), × Golem-Faust (+18 %).
static func damage_per_bullet(weapon_id: String, weapon_level: int = 0) -> int:
	var w: Dictionary = CombatData.WEAPONS[weapon_id]
	var base: float = int(w["base"]) + _up("damage") * 6 + weapon_level * 5 \
		+ EquipManager.stat_total("damage") + ProgressionManager.perk_val("scharf")
	if _energy(weapon_id):
		base += ProgressionManager.perk_val("ueberlad")
	return roundi(base * (1.18 if _power("overcharge") else 1.0))

## Feuerintervall (ms, kleiner = schneller). `overheated` = Kapstein „Überhitzter Kessel" unter 30 % HP.
static func fire_ms(weapon_id: String, overheated: bool = false) -> int:
	var w: Dictionary = CombatData.WEAPONS[weapon_id]
	var v: float = (int(w["fire_ms"]) - _up("firerate") * 22 - EquipManager.stat_total("firerate")) \
		* (1.0 - ProgressionManager.perk_val("schnell") / 100.0)
	if overheated:
		v *= 0.67
	return maxi(50, roundi(v))

## Krit-Chance (0..1): Krit-Perk + Ausrüstung(+Set-Crit) + Kupferlinsen-Visier (+8 %) + Gun-Kapstein (+10 %).
static func crit_chance() -> float:
	return ProgressionManager.perk_val("krit") / 100.0 + EquipManager.stat_total("crit") / 100.0 \
		+ (0.08 if _power("critbase") else 0.0) + (0.10 if _cap("gun") else 0.0)

## Krit-Multiplikator: 2×, mit Panzerbrecher-Synergie 2.5×.
static func crit_mult() -> float:
	return 2.0 + (0.5 if ProgressionManager.perk_rank("brecher") > 0 else 0.0)

static func armor_pen() -> int:
	return ProgressionManager.perk_val("brecher")

## Projektile des Spezialschusses (+4 mit Dolores' letzter Trommel).
static func spread_count() -> int:
	return SPREAD_BASE + (4 if _power("spread11") else 0)

## Durchschlag zusätzlicher Gegner (Iron-Rail-Durchschlag).
static func pierce() -> int:
	return 1 if _power("pierce") else 0

# ── Defense & Utility ─────────────────────────────────────────────────────────

static func player_armor() -> int:
	return EquipManager.stat_total("armor") + ProgressionManager.perk_val("panzer")

## Erlittener-Schaden-Faktor: Rüstungs-Mitigation × Eisernes Chassis (−20 %) × Wachsherz-Kürass (−15 %).
static func damage_taken_mul() -> float:
	var a: int = player_armor()
	return (100.0 / (100.0 + a * 9.0)) * (0.8 if _cap("grit") else 1.0) * (0.85 if _power("vaneward") else 1.0)

## Effektives maximales Leben: Basis + Upgrade + Ausrüstung + Level + Zähigkeit,
## × Eisernes Chassis (+20 %) × Kesselschädel-Haube (+15 %).
static func max_hp() -> int:
	var base: float = GameState.PLAYER_BASE_HP + _up("hp") * 25 + EquipManager.stat_total("hp") \
		+ (GameState.level - 1) * GameState.LEVEL_HP_BONUS + ProgressionManager.perk_val("zaeh")
	return roundi(base * (1.2 if _cap("grit") else 1.0) * (1.15 if _power("toughplate") else 1.0))

static func move_speed() -> float:
	return (BASE_SPEED + _up("speed") * 30 + EquipManager.stat_total("speed")) * (1.12 if _power("quicksole") else 1.0)

static func regen_rate() -> int:
	return BASE_REGEN + _up("regen") * 4 + ProgressionManager.perk_val("heilung") + (6 if _power("autovent") else 0)

static func magnet_dist() -> int:
	return BASE_MAGNET + _up("magnet") * 45 \
		+ (60 if ProgressionManager.perk_rank("pluender") > 0 else 0) + (60 if _power("plunder") else 0)

## Gold-/Beute-Faktor: Plünderer-Perk + Plünderer-Sohlen (+25 %) + New Game+ (+35 %/Zyklus).
static func loot_mul() -> float:
	return 1.0 + ProgressionManager.perk_val("pluender") / 100.0 \
		+ (0.25 if _power("plunder") else 0.0) + GameState.ng_plus * 0.35
