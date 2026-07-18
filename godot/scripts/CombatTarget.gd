class_name CombatTarget extends RefCounted
## CombatTarget — veränderlicher Kampf-Zustand einer Einheit (Gegner oder Spieler-Proxy).
##
## Kapselt alles, was die CombatEngine liest/verändert: Klassifizierung, Panzerung,
## Leben, Status (Stun/DOT). Wird typischerweise an einen 3D-Node gehängt, ist aber
## bewusst logik-only (RefCounted) und ohne Szenen-Abhängigkeit — damit voll testbar.

var type_id: String = ""
var classification: String = CombatData.BIOLOGICAL   # BIOLOGICAL | MECHANICAL
var sub: String = "outlaw"                            # z. B. "goliath" (Front-Immunität)
var max_health: int = 1
var health: int = 1
var armor: int = 0
var max_armor: int = 0
var front_immune: bool = false                        # Kinetik prallt frontal ab, bis Säure ätzt
var contact_dps: int = 0
var gold: int = 0
var ranged: Dictionary = {}                           # {} = Nahkämpfer

var is_boss: bool = false
var is_elite: bool = false
var is_superboss: bool = false

# ── Status ────────────────────────────────────────────────────────────────────
var stun_until: int = 0                               # ms (Time.get_ticks_msec()); 0 = kein Stun
var dot: Dictionary = {}                              # {} = kein DOT; sonst {type,dps,until,accum}


## Baut ein Ziel aus einem Roster-Typ (CombatData.ENEMY_TYPES).
## opts: { "elite": bool, "superboss": bool, "depth": int } — depth skaliert für
## Multilevel-Dungeons (GDD §1.6): jede Ebene erhöht Leben & Panzerung.
static func from_type(type_id: String, opts: Dictionary = {}) -> CombatTarget:
	assert(CombatData.ENEMY_TYPES.has(type_id), "CombatTarget: unbekannter Typ '%s'" % type_id)
	var t: Dictionary = CombatData.ENEMY_TYPES[type_id]
	var e := CombatTarget.new()
	e.type_id = type_id
	e.classification = String(t["class"])
	e.sub = String(t["sub"])
	e.max_health = int(t["hp"])
	e.armor = int(t.get("armor", 0))
	e.front_immune = bool(t.get("front_immune", false))
	e.contact_dps = int(t.get("contact", 0))
	e.is_boss = bool(t.get("boss", false))
	e.gold = randi_range(int(t["gold_min"]), int(t["gold_max"]))
	if t.has("ranged"):
		e.ranged = (t["ranged"] as Dictionary).duplicate()

	# Elite-Modifikator: hebt schwache Typen auf Boss-Niveau.
	if bool(opts.get("elite", false)):
		e.is_elite = true
		e.max_health = maxi(e.max_health, CombatData.BOSS_HP)
		e.contact_dps = maxi(e.contact_dps, CombatData.BOSS_CONTACT)
		e.gold = CombatData.BOSS_GOLD

	# Superboss (Dungeon-Endgegner, tiefste Ebene): 4x Boss-Leben, front-immun.
	if bool(opts.get("superboss", false)):
		e.is_superboss = true
		e.max_health = CombatData.BOSS_HP * CombatData.SUPERBOSS_MULT
		e.armor = 25
		e.front_immune = true
		e.contact_dps = roundi(CombatData.BOSS_CONTACT * 1.6)
		e.gold = CombatData.BOSS_GOLD * CombatData.SUPERBOSS_MULT

	# Tiefen-Skalierung (Multilevel-Dungeon): +25% Leben, +15% Panzerung pro Ebene.
	var depth: int = int(opts.get("depth", 0))
	if depth > 0:
		e.max_health = roundi(e.max_health * (1.0 + depth * 0.25))
		e.armor = roundi(e.armor * (1.0 + depth * 0.15))

	e.max_armor = e.armor
	e.health = e.max_health
	return e


func take_damage(amount: int) -> void:
	# Untere Grenze 0 (kein negatives Leben -> keine Zustandskorruption).
	health = maxi(0, health - maxi(0, amount))

func is_dead() -> bool:
	return health <= 0

func is_stunned(now_ms: int) -> bool:
	return now_ms < stun_until

func has_dot() -> bool:
	return not dot.is_empty()
