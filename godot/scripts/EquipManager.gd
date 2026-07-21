class_name EquipManager extends RefCounted
## EquipManager — Ausrüstungs-/Loadout-Schicht (Master-GDD §7.4/§7.4.4). Legt Gear/Tech in Slots,
## aggregiert Stats & getragene legendäre Kräfte und wertet **legendäre Sets** aus (Sammel-Boni).
##
## Reine Logik (`class_name`, statisch) über `GameState.equip`. Set-Boni können — solange das Set
## getragen wird — eine legendäre Kraft **verleihen** („Set schaltet Perk frei"), die dann von
## `has_power()` genauso gemeldet wird wie ein direkt getragenes Legendary.

const GEAR_SLOTS: Array = ["helmet", "armor", "weapon", "gadget", "boots"]
const PLATE_SLOTS: Array = ["plate1", "plate2", "plate3", "plate4", "plate5", "plate6", "plate7", "plate8"]

# ── Legendäre Sets: `pieces` = legendäre Kraft-ids; `bonuses` = Schwelle -> Bonus. ──
## Ein Bonus kann Stats geben (`stat`) und/oder eine Kraft verleihen (`grant_power`).
const SETS: Dictionary = {
	"direktorat": {
		"name": "Direktorat der Iron Rail",
		"pieces": ["vaneward", "overcharge"],
		"bonuses": {
			2: { "name": "Eiserner Wille", "grant_power": "cap_grit", "desc": "Trägt beide Direktorats-Relikte: Eisernes Chassis dauerhaft aktiv (−20 % Schaden, Stun-immun)." },
		},
	},
	"grenzland": {
		"name": "Grenzland-Legende",
		"pieces": ["spread11", "plunder", "critbase"],
		"bonuses": {
			2: { "name": "Ruf der Grenze", "stat": { "crit": 8 }, "desc": "+8 % Krit-Chance." },
			3: { "name": "Legende komplett", "grant_power": "critchain", "desc": "Kritische Treffer prallen zu einem zweiten Ziel ab." },
		},
	},
}

# ── Slots ─────────────────────────────────────────────────────────────────────

static func all_slots() -> Array:
	return GEAR_SLOTS + PLATE_SLOTS

static func slot_type(equip_slot: String) -> String:
	return "plate" if equip_slot.begins_with("plate") else equip_slot

## Nimmt der Slot dieses Teil? Platten-Slots akzeptieren Platten UND Tech-Module; sonst exakter Typ.
static func slot_accepts(equip_slot: String, gear: Dictionary) -> bool:
	var t: String = slot_type(equip_slot)
	var gs: String = String(gear.get("slot", ""))
	if t == "plate":
		return gs == "plate" or gs == "tech"
	return t == gs

static func equipped(slot: String) -> Dictionary:
	var g: Variant = GameState.equip.get(slot, {})
	return g if g is Dictionary else {}

static func is_equipped(slot: String) -> bool:
	return not equipped(slot).is_empty()

## Legt ein Teil in einen Slot (muss passen). Gibt Erfolg zurück; ersetzt vorhandenes still.
static func equip_item(gear: Dictionary, slot: String) -> bool:
	if not slot_accepts(slot, gear):
		return false
	GameState.equip[slot] = gear
	return true

static func unequip(slot: String) -> Dictionary:
	var g: Dictionary = equipped(slot)
	GameState.equip.erase(slot)
	return g

## Alle angelegten Teile.
static func worn() -> Array:
	var out: Array = []
	for s in GameState.equip:
		var g: Variant = GameState.equip[s]
		if g is Dictionary and not (g as Dictionary).is_empty():
			out.append(g)
	return out

# ── Aggregation ───────────────────────────────────────────────────────────────

## Summe eines Stats über alle angelegten Teile (Ausrüstung) plus aktive Set-Stat-Boni.
static func stat_total(key: String) -> int:
	var s: int = 0
	for g in worn():
		s += ProgressionManager.gear_stat_of(g, key)
	s += set_stat_bonus(key)
	return s

## Direkt getragene legendäre Kräfte.
static func worn_legendary_powers() -> Array:
	var out: Array = []
	for g in worn():
		if g.has("legendary_power"):
			out.append(String(g["legendary_power"]))
	return out

# ── Legendäre Sets ────────────────────────────────────────────────────────────

## Wie viele Teile eines Sets sind angelegt (über die legendären Kräfte identifiziert)?
static func set_piece_count(set_id: String) -> int:
	var powers: Array = worn_legendary_powers()
	var c: int = 0
	for p in SETS[set_id]["pieces"]:
		if powers.has(String(p)):
			c += 1
	return c

## Alle aktuell aktiven Set-Boni (Schwelle erreicht), quer über alle Sets.
static func active_bonuses() -> Array:
	var out: Array = []
	for sid in SETS:
		var cnt: int = set_piece_count(sid)
		for thr in SETS[sid]["bonuses"]:
			if cnt >= int(thr):
				out.append(SETS[sid]["bonuses"][thr])
	return out

## Kräfte, die aktive Set-Boni verleihen (das „Set schaltet Perk frei").
static func granted_powers() -> Array:
	var out: Array = []
	for b in active_bonuses():
		if b.has("grant_power"):
			out.append(String(b["grant_power"]))
	return out

## Stat-Bonus aus aktiven Set-Boni für einen Key.
static func set_stat_bonus(key: String) -> int:
	var s: int = 0
	for b in active_bonuses():
		if b.has("stat") and (b["stat"] as Dictionary).has(key):
			s += int(b["stat"][key])
	return s

## Trägt der Spieler diese Kraft — direkt als Legendary ODER über einen aktiven Set-Bonus?
static func has_power(power: String) -> bool:
	return worn_legendary_powers().has(power) or granted_powers().has(power)
