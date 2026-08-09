class_name ProgressionManager extends RefCounted
## ProgressionManager — Itemization (Diablo-Achse): Seltenheiten, Affixe mit Roll-Varianz,
## legendäre Kräfte und Tech-Module (Master-GDD §7.4.3/§7.5.2/§8.1).
##
## Reine Logik/Daten (`class_name`, statisch). Portiert aus dem validierten Web-Prototyp
## (`RARITY`, `rollAffix`, `makeGear`, `rollRarity`, `LEGENDARIES`, `makeTech`).
## Determinismus: die Würfe nehmen einen `RandomNumberGenerator` (seedbar) bzw. einen
## `quality_roll`/`roll` (0..1) statt globalem `randf()` — so ist die Erzeugung testbar.
##
## Enthält außerdem den Fallout-Perk-Baum (Zweige/Tiers/Capstones/Respec, §7.5.1), der über
## `GameState.perks`/`perk_points` arbeitet.

static var _uid: int = 1

# ── Seltenheiten ──────────────────────────────────────────────────────────────
const RARITY: Dictionary = {
	"common":    { "name": "Gewöhnlich", "mult": 1.0, "w": 58, "req": 1 },
	"rare":      { "name": "Selten", "mult": 1.8, "w": 26, "req": 3 },
	"epic":      { "name": "Episch", "mult": 2.8, "w": 12, "req": 7 },
	"legendary": { "name": "Legendär", "mult": 4.2, "w": 4, "req": 11 },
}
const RARITY_ORDER: Array = ["common", "rare", "epic", "legendary"]

## Ab welcher Stufe man ein Teil tragen darf — als SPANNE je Seltenheit, nicht als eine Zahl.
##
## Vorher hatte jedes epische Teil dieselbe Anforderung: Stufe 7. Damit war "episch" eine
## Schranke und keine Auswahl — man konnte gar nichts davon tragen, und ab Stufe 7 dann alles.
## Zwischen einem schwachen und einem starken Fundstueck derselben Farbe lag kein Unterschied,
## den die Stufe abgebildet haette.
##
## Jetzt entscheidet der WURF. Er bestimmt ohnehin schon, wie stark das Teil ist (siehe
## `roll_affix`); dieselbe Zahl bestimmt jetzt auch, ab wann man es tragen darf. Damit gilt
## automatisch, was gelten soll: Ein schwaches episches Teil traegt man ab Stufe 1, ein starkes
## erst ab zwoelf — und man kann sich nicht das eine ohne das andere aussuchen.
##
## Legendaeres faengt nicht bei 1 an. Es ist die einzige Gattung mit einer eigenen Kraft, und
## eine Kraft, die man in der ersten Spielminute bekommt, ist keine Belohnung mehr.
## `common` bleibt bei 1, als einzige Gattung ohne Spanne. Nicht aus Bequemlichkeit: Der Prolog
## legt dem Helden einen GEWOEHNLICHEN Karabiner in die Hand, und mit einer Spanne von 1 bis 3
## haette der bei jedem dritten Spielstart Stufe 2 oder 3 verlangt — er haette seine eigene
## Startwaffe nicht anlegen koennen. Gewoehnlich ist der Grundzustand; ihn zu verriegeln bringt
## nichts und kann alles kaputtmachen. Die Testsuite hat es gefangen.
const REQ_SPANNE: Dictionary = {
	"common":    [1, 1],
	"rare":      [1, 7],
	"epic":      [1, 12],
	"legendary": [4, 20],
}


## Die Stufenanforderung aus dem Wurf. `guete` ist 0…1 — derselbe Wert, der die Staerke setzt.
static func req_fuer(rarity: String, guete: float) -> int:
	var sp: Array = REQ_SPANNE.get(rarity, [1, 1])
	return int(round(lerpf(float(sp[0]), float(sp[1]), clampf(guete, 0.0, 1.0))))

## Die Farbe je Seltenheitsstufe.
##
## Sie stand in `OverworldView` — und vier andere Dateien griffen quer dorthin, darunter der
## Charakterschirm und das Beutelraster. Eine Oberfläche, die die WELTSZENE laden muss, um zu
## wissen, wie blau „selten" ist, hängt an etwas, mit dem sie nichts zu tun hat. Die Farbe
## gehört zur Seltenheit, also hierher — neben den Namen und das Gewicht.
const RARITY_COLOR: Dictionary = {
	"common": Color(0.80, 0.80, 0.78), "rare": Color(0.36, 0.62, 1.0),
	"epic": Color(0.74, 0.44, 0.96), "legendary": Color(1.0, 0.78, 0.26),
}
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
const SUB_BASE: Dictionary = { "damage": 5, "firerate": 10, "hp": 12, "armor": 3, "speed": 14,
	"crit": 5, "accuracy": 8, "reload": 8 }   ## `accuracy` verengt den Streukegel (PlayerStats.spread_deg)

## Wie ein Wert heisst, wenn ihn jemand LIEST.
##
## Die Schluessel oben sind Programmiernamen und muessen englisch bleiben — sie stehen in
## Spielstaenden, in Beutetabellen und in `PlayerStats`. Nur haben sie genau so auch auf dem
## Bildschirm gestanden: „+10 damage" im Beutel, im Regal und in der Beschreibung, mitten in
## einem Spiel, dessen Text sonst durchgehend deutsch ist. Aufgefallen ist es auf dem ersten
## Bild von Wandas Regal — gelesen hatte diese Zeile vorher niemand.
##
## Unbekannte Schluessel fallen auf sich selbst zurueck (`wert_name`), damit ein neuer Wert
## sichtbar durchrutscht statt einen leeren Platz zu hinterlassen.
const WERT_NAMEN: Dictionary = {
	"damage": "Schaden", "firerate": "Feuerrate", "hp": "Leben", "armor": "Rüstung",
	"speed": "Tempo", "crit": "Kritisch", "accuracy": "Präzision", "reload": "Nachladen",
}


static func wert_name(key: String) -> String:
	return String(WERT_NAMEN.get(key, key))


## Zusatz-Affixe je Slot (Haupt-Stat ergibt sich aus GEAR_SLOTS).
const AFFIX_POOL: Dictionary = {
	"weapon": ["firerate", "crit", "damage", "accuracy", "reload"],
	"armor":  ["hp", "speed", "armor"],
	"helmet": ["armor", "hp", "crit", "accuracy"],
	"gadget": ["damage", "firerate", "crit", "accuracy", "reload"],
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
## Grammatisches Geschlecht der Ausrüstungs-Slots — fürs Beugen der Adjektive.
const SLOT_GENUS: Dictionary = {
	"helmet": "m",  # der Helm
	"armor": "f",   # die Rüstung
	"weapon": "f",  # die Waffe
	"gadget": "n",  # das Gadget
	"boots": "m",   # der Stiefel
	"plate": "f",   # die Panzerplatte
}

## „Schwer" gebeugt — „Schwere Karabiner" waere Plural, gemeint ist einer.
static func _schwer(genus: String) -> String:
	match genus:
		"f":
			return "Schwere"
		"n":
			return "Schweres"
	return "Schwerer"


## Waffen-GATTUNGEN. Dieselben ids wie in `CombatData.WEAPONS`, dazu Hauptwort und Geschlecht.
##
## Bis hierher war jede gefundene Waffe eine „Rostige Waffe" — eine Kategorie ohne Gattung. Nach
## Diablo-Muster gehoert beides zusammen: Die GATTUNG bestimmt, wie geschossen wird (Feuerrate,
## Magazin, Schadensart), die SELTENHEIT bestimmt, wie gut dieses Stueck ist. „Rostiger
## Karabiner" und „Praezisions-Karabiner" schiessen gleich und treffen verschieden hart.
##
## In der 3D-Ansicht sieht das alles gleich aus — bewusst. Der Unterschied gehoert ins Inventar,
## wo man ihn liest und vergleicht, nicht an die Figur, wo er aus zehn Metern verschwaende.
const WEAPON_KINDS: Dictionary = {
	"karabiner": { "noun": "Karabiner", "genus": "m" },
	"gatling":   { "noun": "Gatling", "genus": "f" },
	"voltgun":   { "noun": "Volt-Karabiner", "genus": "m" },
	"saeure":    { "noun": "Säure-Sprüher", "genus": "m" },
	"brenner":   { "noun": "Dampf-Brenner", "genus": "m" },
}


## Setzt Adjektiv und Gegenstand zu einem Namen zusammen — grammatisch richtig.
##
## Die Adjektivliste steht in männlicher Form da („Rostiger", „Kupferner"), weil der Prototyp
## sie nie mit weiblichen Slots kombinieren musste. Seit die Beute mit Namen auf dem BODEN
## liegt, liest man „Rostiger Rüstung" bei jedem einzelnen Fund — vorher stand es nur eine
## Sekunde lang in einer Meldung.
##
## Starke Deklination ohne Artikel: männlich -er, weiblich -e, sächlich -es. Wortstämme mit
## Bindestrich („Präzisions-", „Iron-Rail-") werden nicht gebeugt, sondern direkt angehängt —
## „Präzisions- Helm" mit Leerzeichen ist kein Wort.
static func _compose(word: String, slot: String) -> String:
	return _compose_noun(word, String(GEAR_SLOTS[slot]["name"]),
		String(SLOT_GENUS.get(slot, "m")))


## Wie `_compose`, aber mit ausdruecklichem Hauptwort. Gebraucht, seit eine Waffe nicht mehr
## „Waffe" heisst, sondern „Karabiner" oder „Gatling" — und die haben eigene Geschlechter.
static func _compose_noun(word: String, noun: String, genus: String) -> String:
	if word.ends_with("-"):
		return word + noun
	if not word.ends_with("er"):
		return word + " " + noun
	var stem: String = word.substr(0, word.length() - 2)
	match genus:
		"f":
			return stem + "e " + noun
		"n":
			return stem + "es " + noun
	return word + " " + noun


static func make_gear(slot: String, rarity: String, force_power: String = "",
		rng: RandomNumberGenerator = null, kind: String = "") -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var def: Dictionary = GEAR_SLOTS[slot]
	var r: Dictionary = RARITY[rarity]
	var adj: Array = GEAR_ADJ[rarity]
	var big: bool = false
	var extra_mul: float = 1.0
	var wort: String = String(adj[rng.randi_range(0, adj.size() - 1)])
	var base_name: String = _compose(wort, slot)
	if slot == "weapon":
		# Ohne Vorgabe eine Gattung auswuerfeln. Die Waffe traegt sie mit, denn sie entscheidet
		# im Kampf ueber Feuerrate, Magazin und Schadensart.
		if kind == "" or not WEAPON_KINDS.has(kind):
			var kinds: Array = WEAPON_KINDS.keys()
			kind = String(kinds[rng.randi_range(0, kinds.size() - 1)])
		var kd: Dictionary = WEAPON_KINDS[kind]
		base_name = _compose_noun(wort, String(kd["noun"]), String(kd["genus"]))
		if rng.randf() < 0.3:
			big = true
			extra_mul = 1.4
			base_name = _schwer(String(kd["genus"])) + " " + base_name
	else:
		kind = ""
	var stat_key: String = String(def["stat"])
	var factor: float = (float(def["base"]) / float(SUB_BASE.get(stat_key, def["base"]))) * extra_mul
	# EIN Wurf fuer beides: Staerke und Stufenanforderung. Zwei getrennte Wuerfe koennten ein
	# schwaches Teil mit hoher Anforderung ergeben — und das waere keine Abstufung, sondern Pech.
	var guete: float = rng.randf()
	var primary: Dictionary = roll_affix(stat_key, float(r["mult"]), factor, guete)
	_uid += 1
	var g: Dictionary = {
		"uid": _uid, "slot": slot, "rarity": rarity, "req": req_fuer(rarity, guete), "big": big,
		"name": base_name, "stat": primary, "affixes": [], "desc": String(GEAR_FLAVOR.get(slot, "")),
	}
	if kind != "":
		g["kind"] = kind
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
		# Tech-Module wuerfeln ihren Wert nicht aus — er steht fest je Seltenheit. Also auch
		# eine feste Anforderung, und zwar die MITTE der Spanne: Sie sollen sich zwischen den
		# schwachen und den starken Fundstuecken derselben Farbe einordnen, nicht davor.
		"uid": _uid, "slot": "tech", "tech_type": tech_type, "rarity": rarity,
		"req": req_fuer(rarity, 0.5),
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


# ── Perk-Baum (Fallout-Achse, Master-GDD §7.5.1) ──────────────────────────────
## Drei Zweige; Tiers nach Level & investierten Punkten gestaffelt; Tier 4 = exklusiver Kapstein.
const PERK_BRANCHES: Array = [
	{ "id": "gun", "name": "Revolverheld", "blurb": "Blei & Präzision" },
	{ "id": "tech", "name": "Kesseltreiber", "blurb": "Dampf & Energie" },
	{ "id": "grit", "name": "Grenzgänger", "blurb": "Zähigkeit & Beute" },
]
## Tier -> {lvl: Mindest-Level, inv: Mindest-Punkte im Zweig}.
const PERK_TIER: Dictionary = {
	1: { "lvl": 1, "inv": 0 }, 2: { "lvl": 5, "inv": 2 }, 3: { "lvl": 10, "inv": 4 }, 4: { "lvl": 14, "inv": 6 },
}
const PERKS: Dictionary = {
	"scharf":   { "branch": "gun", "tier": 1, "max": 3, "per": 4, "name": "Scharfschütze" },
	"schnell":  { "branch": "gun", "tier": 1, "max": 3, "per": 7, "name": "Schnellschuss" },
	"krit":     { "branch": "gun", "tier": 2, "max": 3, "per": 8, "name": "Krit-Treffer" },
	"brecher":  { "branch": "gun", "tier": 3, "max": 1, "per": 10, "name": "Panzerbrecher" },
	"gurt":     { "branch": "tech", "tier": 1, "max": 3, "per": 25, "name": "Munitionsgurt" },
	"aasgeier": { "branch": "tech", "tier": 1, "max": 3, "per": 25, "name": "Aasgeier" },
	"ueberlad": { "branch": "tech", "tier": 2, "max": 3, "per": 5, "name": "Überladung" },
	"granat":   { "branch": "tech", "tier": 3, "max": 1, "per": 35, "name": "Granatmeister" },
	"zaeh":     { "branch": "grit", "tier": 1, "max": 3, "per": 25, "name": "Zähigkeit" },
	"panzer":   { "branch": "grit", "tier": 1, "max": 3, "per": 4, "name": "Panzerhaut" },
	"heilung":  { "branch": "grit", "tier": 2, "max": 3, "per": 3, "name": "Selbstheilung" },
	"pluender": { "branch": "grit", "tier": 3, "max": 1, "per": 25, "name": "Plünderer" },
	"cap_gun":  { "branch": "gun", "tier": 4, "max": 1, "per": 0, "xor": "cap", "name": "Ballistischer Rechenkern" },
	"cap_tech": { "branch": "tech", "tier": 4, "max": 1, "per": 0, "xor": "cap", "name": "Überhitzter Kessel" },
	"cap_grit": { "branch": "grit", "tier": 4, "max": 1, "per": 0, "xor": "cap", "name": "Eisernes Chassis" },
}

static func perk_rank(id: String) -> int:
	return int(GameState.perks.get(id, 0))

## Wirkwert eines Perks (Rang × per).
static func perk_val(id: String) -> int:
	return perk_rank(id) * int(PERKS.get(id, {}).get("per", 0))

## Summe der investierten Ränge in einem Zweig (staffelt die Tiers).
static func branch_points(branch: String) -> int:
	var s: int = 0
	for pid in PERKS:
		if String(PERKS[pid]["branch"]) == branch:
			s += perk_rank(pid)
	return s

## Tier-Freischaltung: Level hoch genug UND genug Punkte im Zweig investiert.
static func perk_tier_ok(id: String) -> bool:
	var t: Dictionary = PERK_TIER[int(PERKS[id]["tier"])]
	return GameState.level >= int(t["lvl"]) and branch_points(String(PERKS[id]["branch"])) >= int(t["inv"])

## Exklusiv-Gruppe (Kapsteine, xor "cap"): ist bereits ein ANDERER Perk der Gruppe aktiv?
static func xor_blocked(id: String) -> bool:
	var x: Variant = PERKS[id].get("xor", null)
	if x == null:
		return false
	for pid in PERKS:
		if pid != id and PERKS[pid].get("xor", null) == x and perk_rank(pid) > 0:
			return true
	return false

static func has_cap(branch: String) -> bool:
	return perk_rank("cap_" + branch) > 0

## Wie viele Punkte eine Stufe insgesamt eingebracht hat.
##
## `stufe - 1`, weil man auf Stufe 1 anfaengt: Der erste Punkt kommt mit dem ERSTEN Aufstieg.
static func verdiente_punkte(stufe: int) -> int:
	return maxi(0, stufe - 1) * GameState.PERK_PUNKTE_JE_STUFE


## Wie viele schon in Raenge gesteckt wurden.
static func ausgegebene_punkte() -> int:
	var n: int = 0
	for pid in GameState.perks:
		n += int(GameState.perks[pid])
	return n


## Bringt `perk_points` mit Stufe und Raengen in Einklang.
##
## Das ist die Reparatur fuer alte Spielstaende. Punkte wurden bis eben ueberhaupt nie vergeben;
## wer jetzt mit Stufe drei laedt, haette weiterhin null — der Fehler waere behoben und der
## Spieler merkte nichts davon, weil sein Schaden schon entstanden ist.
##
## Sie ERHOEHT NUR. Ein Gleichsetzen waere falsch: Nach einer Neuverdrahtung (`do_respec`)
## liegen erstattete Punkte auf der Hand, ohne dass ein Rang dafuer steht — die kassierte ein
## `=` ein. Und so ist sie mehrfach aufrufbar, ohne dass etwas doppelt herauskommt.
static func punkte_abgleichen() -> void:
	var soll: int = verdiente_punkte(GameState.level) - ausgegebene_punkte()
	if GameState.perk_points < soll:
		GameState.perk_points = soll


static func perk_can_buy(id: String) -> bool:
	if not PERKS.has(id):
		return false
	return GameState.perk_points > 0 and perk_rank(id) < int(PERKS[id]["max"]) and perk_tier_ok(id) and not xor_blocked(id)

## Kauft einen Perk-Rang (ein Punkt). Gibt Erfolg zurück.
static func buy_perk(id: String) -> bool:
	if not perk_can_buy(id):
		return false
	GameState.perks[id] = perk_rank(id) + 1
	GameState.perk_points -= 1
	return true

## Respec-Kosten: „Neuverdrahtung des Rechenkerns" (Gold + 1 Dampfkern).
static func respec_cost() -> Dictionary:
	return { "gold": 150 + GameState.level * 20, "kern": 1 }

## Respec (erst nach dem Erwachen): erstattet alle Ränge als Punkte, leert die Perks, zieht Kosten ab.
static func do_respec() -> bool:
	if not GameState.is_revealed:
		return false
	var c: Dictionary = respec_cost()
	if GameState.gold < int(c["gold"]) or GameState.item_count("dampfkern") < int(c["kern"]):
		return false
	var refunded: int = 0
	for pid in GameState.perks:
		refunded += int(GameState.perks[pid])
	GameState.gold -= int(c["gold"])
	GameState.remove_item("dampfkern", int(c["kern"]))
	GameState.perks = {}
	GameState.perk_points += refunded
	return true
