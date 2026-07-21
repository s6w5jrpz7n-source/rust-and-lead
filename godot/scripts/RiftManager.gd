class_name RiftManager extends RefCounted
## RiftManager — Endlosmodus „Der Abstieg": rotierende Biome, Modifikatoren & Tiefen-Skalierung
## (Master-GDD §7.5.6/§7.5.6a/§8.1). Portiert aus dem validierten Web-Prototyp (`ABYSS_BIOMES`,
## `ABYSS_MODS`, `mapHpMul`/`scatterEnemies` für den Abstieg).
##
## Reine Logik/Daten (`class_name`, statisch). Determinismus: der Modifikator-Wurf nimmt optional
## einen `roll` (0..1) statt `randf()`.

const BAND: int = 5   # Biom-Wechsel alle 5 Ebenen

## Rotierende Biome (Farben sind View; hier id/Name/Stollen-Label/Ankunfts-Ausruf).
const BIOMES: Array = [
	{ "id": "stollen", "name": "Verlassene Stollen", "decor": "STOLLEN", "callout": "Verlassene Stollen. Hier endete die Minengesellschaft — hier beginnst du." },
	{ "id": "frost", "name": "Frostkavernen", "decor": "EISHÖHLE", "callout": "Frostkavernen. Der Atem gefröre — hättest du noch einen." },
	{ "id": "magma", "name": "Magma-Schlund", "decor": "MAGMA", "callout": "Magma-Schlund. Der Fels glüht, das Öl in deinen Adern kocht." },
	{ "id": "sporen", "name": "Sporentiefe", "decor": "SPOREN", "callout": "Sporentiefe. Etwas Lebendiges wächst durch den Stahl." },
	{ "id": "herz", "name": "Fleisch-Maschinen-Tiefe", "decor": "HERZ", "callout": "Fleisch und Getriebe verschmelzen. Du bist dem Herzen nah." },
]

## Zufalls-Modifikatoren je Ebene.
const MODS: Array = [
	{ "id": "horde", "name": "Andrang", "desc": "mehr Gegner" },
	{ "id": "brute", "name": "Überdruck", "desc": "zäher & härter" },
	{ "id": "swift", "name": "Rasende Meute", "desc": "schnellere Gegner" },
	{ "id": "elite", "name": "Elite-Nest", "desc": "mehr Elite-Bosse" },
]

# ── Biome ─────────────────────────────────────────────────────────────────────

static func band_of(depth: int) -> int:
	return int(floor((maxi(1, depth) - 1) / float(BAND)))

## Biom einer Tiefe (rotiert alle BAND Ebenen).
static func biome_for(depth: int) -> Dictionary:
	return BIOMES[band_of(depth) % BIOMES.size()]

## Wechselt beim Abstieg von `prev_depth` nach `depth` das Biom? (Für den Ankunfts-Ausruf.)
static func biome_changed(prev_depth: int, depth: int) -> bool:
	return biome_for(prev_depth)["id"] != biome_for(depth)["id"]

# ── Modifikator ───────────────────────────────────────────────────────────────

static func roll_mod(roll: float = -1.0) -> Dictionary:
	var r: float = roll if roll >= 0.0 else randf()
	var idx: int = clampi(int(floor(r * MODS.size())), 0, MODS.size() - 1)
	return MODS[idx]

# ── Tiefen-Skalierung ─────────────────────────────────────────────────────────

## Gegner-Lebens-Faktor: +50 % pro Ebene, ×1.3 bei „Überdruck", plus New Game+ (+60 %/Zyklus).
static func enemy_hp_mul(depth: int, mod_id: String, ng_plus: int = 0) -> float:
	var mul: float = 1.0 + (maxi(1, depth) - 1) * 0.5
	if mod_id == "brute":
		mul *= 1.3
	mul *= 1.0 + ng_plus * 0.6
	return mul

## „Rasende Meute" erhöht das Tempo um 25 %.
static func enemy_speed_mul(mod_id: String) -> float:
	return 1.25 if mod_id == "swift" else 1.0

## Dichte-Faktor: +20 % pro Ebene, ×1.5 bei „Andrang".
static func density(depth: int, mod_id: String) -> float:
	var d: float = 1.0 + (maxi(1, depth) - 1) * 0.2
	if mod_id == "horde":
		d *= 1.5
	return d

## Elite-Zahl: Basis + eine pro drei Ebenen, +2 bei „Elite-Nest".
static func elite_count(depth: int, base_elites: int, mod_id: String) -> int:
	var e: int = base_elites + int(floor(depth / 3.0))
	if mod_id == "elite":
		e += 2
	return e

## Alle drei Ebenen wartet ein mit der Tiefe skalierter Minen-Titan (Superboss).
static func has_superboss(depth: int) -> bool:
	return depth % 3 == 0
