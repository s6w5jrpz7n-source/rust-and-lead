class_name CombatEngine extends RefCounted
## CombatEngine — mathematische Kampf- & Mitigations-Engine (Master-GDD §6.2/§6.3).
## (Modul 1; hervorgegangen aus dem früheren DamageEngine, um Mitigations-Formel und
##  Flanken-Logik ergänzt.)
##
## Stateless: alle Methoden sind `static`, kein Autoload nötig — Aufruf direkt als
## `CombatEngine.calculate(...)` / `CombatEngine.resolve_hit(...)`. Die Werte entsprechen
## exakt der im Web-Prototyp verifizierten Wechselwirkungs-Matrix (Tests DMG_MATRIX,
## STATUS_FX). Reihenfolge der Faktoren ist verbindlich. Nutzt CombatData (Konstanten/
## Registries) und operiert auf CombatTarget (veränderlicher Zustand).

## Berechnet den Schaden einer Schadensart gegen ein Ziel.
## `from_front` = Angriff auf die Frontpanzerung; nur relevant für front-immune Einheiten
## (Goliath, Minen-Titan): frontal prallt Kinetik ab, bis Säure die Panzerung auf 0 ätzt —
## eine Flanke (from_front = false) umgeht die Immunität und nutzt normale Panzerungs-Minderung.
## Rückgabe: { "damage": int, "effect": String, "immune": bool }.
## Verändert das Ziel NICHT (Ausnahme: Korrosion wird in apply_status angewandt).
static func calculate(damage_type: String, target: CombatTarget, base_damage: int, acid_potency: int = 10, from_front: bool = true) -> Dictionary:
	var dmg: float = float(base_damage)
	var effect: String = CombatData.FX_NONE
	var cls: String = target.classification
	var armor: int = target.armor

	if cls == CombatData.MECHANICAL:
		match damage_type:
			CombatData.GALVANIC:
				dmg *= 2.5                                   # Automaten: massiver Bonus (2.5x)
				if randf() < 0.40:
					effect = CombatData.FX_STUN
			CombatData.KINETIC:
				if target.front_immune and from_front:
					# Frontal immun, solange Panzerung > 0 (Säure muss sie erst zersetzen).
					dmg = 0.0 if armor > 0 else float(base_damage)
				else:
					dmg = float(maxi(1, base_damage - armor))        # Panzerung schluckt Blei (Flanke/normal)
			CombatData.THERMAL:
				dmg *= (0.6 if target.sub == "goliath" else 1.2)     # Goliath widersteht, Leichtbau brennt
			CombatData.ALCHEMICAL:
				if armor > 0:
					effect = CombatData.FX_CORRODE                   # zersetzt Rüstung (in apply_status)
	elif cls == CombatData.BIOLOGICAL:
		match damage_type:
			CombatData.KINETIC:
				dmg *= 1.5                                   # Fleisch: Bonus
				if randf() < 0.33:
					effect = CombatData.FX_BLEED
			CombatData.GALVANIC:
				dmg *= 0.4                                   # biologische Isolierung dämpft
			CombatData.THERMAL:
				dmg *= 1.3
				if randf() < 0.50:
					effect = CombatData.FX_BURN
			CombatData.ALCHEMICAL:
				pass                                         # Basisschaden (keine Rüstung)

	var final_damage: int = maxi(0, roundi(dmg))
	return { "damage": final_damage, "effect": effect, "immune": final_damage <= 0 }


## Wendet einen Status-Effekt auf das Ziel an. `now_ms` = Time.get_ticks_msec().
static func apply_status(target: CombatTarget, effect: String, now_ms: int, acid_potency: int = 10) -> void:
	if target == null or target.is_dead():
		return
	match effect:
		CombatData.FX_STUN:
			target.stun_until = now_ms + CombatData.STUN_MS
		CombatData.FX_BLEED:
			target.dot = { "type": "BLEED", "dps": maxf(4.0, target.max_health * 0.04), "until": now_ms + CombatData.DOT_MS, "accum": 0.0 }
		CombatData.FX_BURN:
			target.dot = { "type": "BURN", "dps": maxf(5.0, target.max_health * 0.05), "until": now_ms + CombatData.DOT_MS, "accum": 0.0 }
		CombatData.FX_CORRODE:
			target.armor = maxi(0, target.armor - acid_potency)


## Tickt einen aktiven DOT (Verbluten/Überhitzung). In Ticks von DOT_TICK_SEC (0,4 s),
## damit Schadenszahlen lesbar bleiben. Wendet den Schaden am Ziel an und gibt ihn zurück
## (0 = kein Tick fällig / kein DOT). Läuft der DOT ab, wird er entfernt.
static func tick_dot(target: CombatTarget, now_ms: int, delta_sec: float) -> int:
	if target == null or not target.has_dot():
		return 0
	if now_ms >= int(target.dot["until"]):
		target.dot = {}
		return 0
	target.dot["accum"] = float(target.dot["accum"]) + delta_sec
	if float(target.dot["accum"]) < CombatData.DOT_TICK_SEC:
		return 0
	var dmg: int = roundi(float(target.dot["dps"]) * float(target.dot["accum"]))
	target.dot["accum"] = 0.0
	if dmg > 0:
		target.take_damage(dmg)
	return dmg


## Kompletter Treffer: Schaden berechnen, Status anwenden, Schaden zufügen.
## `from_front` reicht die Flanken-Logik durch (siehe calculate()).
## Rückgabe wie calculate(), zusätzlich { "killed": bool }.
static func resolve_hit(damage_type: String, target: CombatTarget, base_damage: int, acid_potency: int, now_ms: int, from_front: bool = true) -> Dictionary:
	var res: Dictionary = calculate(damage_type, target, base_damage, acid_potency, from_front)
	if String(res["effect"]) != CombatData.FX_NONE:
		apply_status(target, String(res["effect"]), now_ms, acid_potency)
	if int(res["damage"]) > 0:
		target.take_damage(int(res["damage"]))
	res["killed"] = target.is_dead()
	return res


## Schadensminderung durch Rüstung/Panzerplatten (GDD §6.2, exakte Formel):
##   final_damage = incoming_damage × (100 / (100 + armor_value × 9))
## Die Kurve ist steigend und **gedeckelt** (nähert sich 0, erreicht sie nie): jeder
## Rüstungspunkt bringt weniger Zusatzschutz als der vorige -> keine Unverwundbarkeit.
static func player_damage_taken_mul(armor_value: int) -> float:
	return 100.0 / (100.0 + armor_value * 9.0)

## Wendet die Mitigations-Formel an und liefert den finalen (ganzzahligen) Schaden.
static func mitigate_damage(incoming_damage: int, armor_value: int) -> int:
	return maxi(0, roundi(incoming_damage * player_damage_taken_mul(armor_value)))
