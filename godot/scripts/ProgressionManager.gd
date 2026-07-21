class_name ProgressionManager extends RefCounted
## ProgressionManager — Itemization (Diablo-Achse): Seltenheiten, Affixe mit Roll-Varianz,
## legendäre Kräfte und Tech-Module (Master-GDD §7.4.3/§7.5.2/§8.1).
##
## Reine Logik/Daten (`class_name`, statisch). Portiert aus dem validierten Web-Prototyp
## (`RARITY`, `rollAffix`, `makeGear`, `rollRarity`, `LEGENDARIES`, `makeTech`).
## Determinismus: die Würfe nehmen einen `RandomNumberGenerator` (seedbar) bzw. einen
## `quality_roll`/`roll` (0..1) statt globalem `randf()` — so ist die Erzeugung testbar.
##
## Offen (Folge-Port): der Fallout-Perk-Baum (Zweige/Tiers/Capstones/Respec).

static var _uid: int = 1

# ── Seltenheiten ──────────────────────────────────────────────────────────────
const RARITY: Dictionary = {
	"common":    { "name": "Gewöhnlich", "mult": 1.0, "w": 58, "req": 1 },
	"rare":      { "name": "Selten", "mult": 1.8, "w": 26, "req": 3 },
	"epic":      { "name": "Episch", "mult": 2.8, "w": 12, "req": 7 },
	"legendary": { "name": "Legendär", "mult": 4.2, "w": 4, "req": 11 },
}
const RARITY_ORDER: Array = ["common", "rare", "epic", "legendary"]
const AFFIX_COUNT: Dictionary = { "common": 0, "rare": 1, "epic": 2, "legendary": 3 }
const GEAR_ADJ: Dictionary = {
	"common": ["Rostiger", "Abgenutzter", "Einfacher"],
	"rare": ["Kupferner", "Verstärkter", "Gehärteter"],
	"epic": ["Dampfbetriebener", "Alchemistischer", "Präzisions-"],
	"legendary": ["Titanischer", "Legendärer", "Iron-Rail-"],
}

# ── Ausrüstungsslots (Haupt-Stat + Basiswert je Slot) ─────────────────────────
const GEAR_SLOTS: Dictionary = {
	"helmet": { "name": "Helm", "stat": "hp", "base": 14 },
	"armor":  { "name": "Rüstung", "stat": "armor", "base": 4 },
	"weapon": { "name": "Waffe", "stat": "damage", "base": 6 },
	"gadget": { "name": "Gadget", "stat": "firerate", "base": 14 },
	"boots":  { "name": "Stiefel", "stat": "speed", "base": 18 },
	"plate":  { "name": "Panzerplatte", "stat": "armor", "base": 3 },
}
const SUB_BASE: Dictionary = { "damage": 5, "firerate": 10, "hp": 12, "armor": 3, "speed": 14, "crit": 5 }
## Zusatz-Affixe je Slot (Haupt-Stat ergibt sich aus GEAR_SLOTS).
const AFFIX_POOL: Dictionary = {
	"weapon": ["firerate", "crit", "damage"],
	"armor":  ["hp", "speed", "armor"],
	"helmet": ["armor", "hp", "crit"],
	"gadget": ["damage", "firerate", "crit"],
	"boots":  ["armor", "hp", "speed"],
}
const GEAR_FLAVOR: Dictionary = {
	"weapon": "Der Rückstoß erzählt Geschichten.",
	"armor":  "Vernietete Platten, gehärtet im Kesselfeuer.",
	"helmet": "Ein gutes Visier ist die halbe Miete.",
	"gadget": "Dampfgetriebene Spielerei mit echtem Nutzen.",
	"boots":  "Getragen auf tausend Meilen Staub.",
	"plate":  "Ein Schild aus Schrott und Sturheit.",
}

# ── Legendäre mit benannter Kraft (Regeländerung, nicht nur Stats). `boss` = exklusiv. ──
const LEGENDARIES: Dictionary = {
	"weapon": [
		{ "power": "spread11", "name": "Dolores' letzte Trommel", "desc": "Spezialschuss feuert 11 statt 7 Projektile." },
		{ "power": "pierce", "name": "Iron-Rail-Durchschlag", "desc": "Kugeln durchschlagen einen zusätzlichen Gegner." },
		{ "power": "galvcrit", "name": "Galvanische Trommel", "desc": "Kritische Treffer lösen einen Kurzschluss (Stun) aus." },
		{ "power": "critchain", "name": "Ballistischer Rechenkern", "desc": "Krits prallen zu einem zweiten Ziel ab." },
		{ "power": "overcharge", "name": "Golem-Faust", "desc": "+18 % Schaden auf alle Treffer.", "boss": "golem" },
	],
	"armor": [
		{ "power": "slamward", "name": "Titan-Kolben-Panzer", "desc": "Boss-Flächenschläge treffen dich nur halb so hart." },
		{ "power": "lifekill", "name": "Blutdampf-Kessel", "desc": "Jeder Kill heilt dich um 3 % deines Lebens." },
		{ "power": "vaneward", "name": "Wachsherz-Kürass", "desc": "Du erleidest 15 % weniger Schaden aus allen Quellen.", "boss": "vane" },
	],
	"gadget": [
		{ "power": "ammothrift", "name": "Sparventil-Uhr", "desc": "25 % Chance, keine Munition zu verbrauchen." },
		{ "power": "autovent", "name": "Selbstschmier-Ventil", "desc": "Regeneriert dein Leben deutlich schneller." },
	],
	"boots": [
		{ "power": "plunder", "name": "Plünderer-Sohlen", "desc": "+25 % Gold und ein stärkerer Loot-Magnet." },
		{ "power": "quicksole", "name": "Quecksilber-Sohlen", "desc": "+12 % Bewegungstempo." },
	],
	"helmet": [
		{ "power": "critbase", "name": "Kupferlinsen-Visier", "desc": "+8 % Grund-Kritchance auf alle Treffer." },
		{ "power": "toughplate", "name": "Kesselschädel-Haube", "desc": "+15 % maximales Leben." },
	],
}

# ── Tech-Module (8 Platten-/Tech-Slots): offensive/Utility-Boni statt Rüstung. ──
const TECH_TYPES: Dictionary = {
	"schaden":  { "name": "Schaden-Chip", "stat": "damage", "base": 5, "desc": "Justiert den Lauf auf tödliche Präzision." },
	"nachlade": { "name": "Nachlade-Servo", "stat": "firerate", "base": 12, "desc": "Ein Servo, das den Hahn im Akkord spannt." },
	"laufwerk": { "name": "Laufwerk-Modul", "stat": "speed", "base": 16, "desc": "Hydraulische Gelenke für mehr Tempo." },
	"vital":    { "name": "Vital-Kern", "stat": "hp", "base": 12, "desc": "Ein pochender Dampfkern, der dich am Leben hält." },
	"panzer":   { "name": "Panzer-Kern", "stat": "armor", "base": 3, "desc": "Verstärkt die Chassis-Platten von innen." },
}


# ── Würfe (deterministisch über roll/rng) ─────────────────────────────────────

## Ein Affix mit Roll-Varianz (70–130 %). `quality_roll` (0..1) macht Wert & Güte testbar.
## Ergebnis: {key, val (>=1), q (0..1 normalisierte Roll-Güte)}.
static func roll_affix(key: String, mult: float, factor: float, quality_roll: float = -1.0) -> Dictionary:
	var qroll: float = quality_roll if quality_roll >= 0.0 else randf()
	var q: float = 0.7 + qroll * 0.6
	var base: float = float(SUB_BASE.get(key, 5)) * mult * factor
	return { "key": key, "val": maxi(1, roundi(base * q)), "q": minf(1.0, (q - 0.7) / 0.6) }

## Gewichtete Seltenheit; `bias` (>0) hebt seltene Stufen an. `roll` (0..1) macht es testbar.
static func roll_rarity(bias: float, roll: float = -1.0) -> String:
	var weighted: Array = []
	var total: float = 0.0
	for i in RARITY_ORDER.size():
		var k: String = RARITY_ORDER[i]
		var w: float = maxf(0.5, float(RARITY[k]["w"]) + bias * i * 6.0)
		weighted.append([k, w])
		total += w
	var x: float = (roll if roll >= 0.0 else randf()) * total
	for pw in weighted:
		x -= float(pw[1])
		if x <= 0.0:
			return String(pw[0])
	return "common"

## Erzeugt ein Ausrüstungsstück. `force_power` erzwingt ein bestimmtes Legendary (z. B. Boss-Drop);
## `rng` (seedbar) macht die Zufalls-Anteile deterministisch. Struktur: {uid, slot, rarity, req,
## big, name, stat{key,val,q}, affixes[], desc, legendary_power?}.
static func make_gear(slot: String, rarity: String, force_power: String = "", rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var def: Dictionary = GEAR_SLOTS[slot]
	var r: Dictionary = RARITY[rarity]
	var adj: Array = GEAR_ADJ[rarity]
	var big: bool = false
	var extra_mul: float = 1.0
	var base_name: String = String(adj[rng.randi_range(0, adj.size() - 1)]) + " " + String(def["name"])
	if slot == "weapon" and rng.randf() < 0.3:
		big = true
		extra_mul = 1.4
		base_name = "Schwere " + base_name
	var stat_key: String = String(def["stat"])
	var factor: float = (float(def["base"]) / float(SUB_BASE.get(stat_key, def["base"]))) * extra_mul
	var primary: Dictionary = roll_affix(stat_key, float(r["mult"]), factor, rng.randf())
	_uid += 1
	var g: Dictionary = {
		"uid": _uid, "slot": slot, "rarity": rarity, "req": int(r["req"]), "big": big,
		"name": base_name, "stat": primary, "affixes": [], "desc": String(GEAR_FLAVOR.get(slot, "")),
	}
	var pool: Array = (AFFIX_POOL.get(slot, []) as Array).duplicate()
	var n: int = int(AFFIX_COUNT.get(rarity, 0))
	for i in n:
		if pool.is_empty():
			break
		var idx: int = rng.randi_range(0, pool.size() - 1)
		var key: String = String(pool[idx])
		pool.remove_at(idx)
		g["affixes"].append(roll_affix(key, float(r["mult"]), 0.4, rng.randf()))
	if rarity == "legendary" and LEGENDARIES.has(slot):
		var candidates: Array = []
		for l in LEGENDARIES[slot]:
			if force_power != "":
				if String(l["power"]) == force_power:
					candidates.append(l)
			elif not l.has("boss"):
				candidates.append(l)
		if candidates.is_empty():
			candidates = LEGENDARIES[slot]
		var leg: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		g["legendary_power"] = String(leg["power"])
		g["name"] = String(leg["name"])
		g["desc"] = String(leg["desc"])
	return g

## Ein Tech-Modul (Haupt-Stat skaliert mit Seltenheit).
static func make_tech(tech_type: String, rarity: String) -> Dictionary:
	var t: Dictionary = TECH_TYPES.get(tech_type, TECH_TYPES["schaden"])
	var r: Dictionary = RARITY[rarity]
	_uid += 1
	return {
		"uid": _uid, "slot": "tech", "tech_type": tech_type, "rarity": rarity, "req": int(r["req"]),
		"name": String(r["name"]) + " " + String(t["name"]),
		"stat": { "key": String(t["stat"]), "val": maxi(1, roundi(float(t["base"]) * float(r["mult"]))) },
		"desc": String(t["desc"]),
	}


# ── Ableitungen ───────────────────────────────────────────────────────────────

## Summe aller Affixe (Haupt + Zusatz) eines Items für einen Stat-Key.
static func gear_stat_of(g: Dictionary, key: String) -> int:
	var s: int = 0
	if g.has("stat") and String(g["stat"]["key"]) == key:
		s += int(g["stat"]["val"])
	for a in g.get("affixes", []):
		if String(a["key"]) == key:
			s += int(a["val"])
	return s

## Grober Marktwert (Verkauf/Vergleich): Seltenheit + Haupt-Stat + Affixe + Legendär-Bonus.
static func gear_value(g: Dictionary) -> int:
	var affix_sum: int = 0
	for a in g.get("affixes", []):
		affix_sum += int(a["val"])
	var leg_bonus: int = 60 if g.has("legendary_power") else 0
	return roundi(float(RARITY[g["rarity"]]["mult"]) * 15.0 + float(g["stat"]["val"]) + affix_sum * 0.8 + leg_bonus)

## Grid-Fußabdruck [Spalten, Zeilen]: Rüstung 2×2, Waffe 2×1 (schwer 3×1), Kleinteile 1×1.
static func gear_foot(g: Dictionary) -> Vector2i:
	if String(g.get("slot", "")) == "armor":
		return Vector2i(2, 2)
	if String(g.get("slot", "")) == "weapon":
		return Vector2i(3, 1) if bool(g.get("big", false)) else Vector2i(2, 1)
	return Vector2i(1, 1)

static func gear_cells(g: Dictionary) -> int:
	var f: Vector2i = gear_foot(g)
	return f.x * f.y
