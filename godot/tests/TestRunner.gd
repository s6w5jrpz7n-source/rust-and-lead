extends Node
## TestRunner — abhängigkeitsfreie headless Test-Suite für das gesamte Backend.
##
## Ausführen (kein GUT-Addon nötig):  godot --headless --path godot
## (oder im Editor: Projekt starten). Exit-Code 0 = alle Tests bestanden, 1 = Fehler.
##
## Deterministisch: geprüft werden die exakten Zahlenwerte aus dem Master-GDD. Zufalls-
## behaftete Status-Auslösungen werden umgangen, indem Status direkt über apply_status()
## gesetzt wird (Schaden selbst ist deterministisch).

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("──────────────────────────────────────────────")
	print("  Rust & Lead — Backend Test-Suite")
	print("──────────────────────────────────────────────")
	_test_combat_engine()
	_test_quest_manager()
	_test_tycoon_manager()
	_test_grid_inventory()
	_test_world_manager()
	print("──────────────────────────────────────────────")
	print("  Ergebnis: %d bestanden, %d fehlgeschlagen" % [_passed, _failed])
	print("──────────────────────────────────────────────")
	get_tree().call_deferred("quit", 1 if _failed > 0 else 0)


func _check(label: String, condition: bool, info: String = "") -> void:
	if condition:
		_passed += 1
		print("  [OK]   ", label)
	else:
		_failed += 1
		printerr("  [FAIL] ", label, ("  -> " + info) if info != "" else "")


func _reset_state() -> void:
	GameState.current_chapter = 1
	GameState.is_revealed = false
	GameState.chosen_guild = null
	GameState.level = 1
	GameState.xp = 0
	GameState.gold = 0
	GameState.potions = 3
	GameState.kills = 0
	GameState.inventory = { "schrott": 0, "zahnrad": 0, "dampfkern": 0 }
	GameState.economy = { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 }
	GameState.quests = {}
	GameState.quest_base = {}
	GameState.flags_ui = { "reveal_playing": false }


# ── Modul 1: CombatEngine ─────────────────────────────────────────────────────
func _test_combat_engine() -> void:
	print("· CombatEngine (Modul 1)")
	var now: int = Time.get_ticks_msec()

	var mech := CombatTarget.from_type("konstrukt")   # MECHANICAL, armor 15
	_check("Galvanik vs Mech = 2.5x", CombatEngine.calculate(CombatData.GALVANIC, mech, 40).damage == 100)
	_check("Kinetik vs Mech = max(1, dmg-armor)", CombatEngine.calculate(CombatData.KINETIC, mech, 40).damage == 25)
	_check("Thermik vs Leichtbau-Automat = 1.2x", CombatEngine.calculate(CombatData.THERMAL, mech, 40).damage == 48)

	var bio := CombatTarget.from_type("outlaw")        # BIOLOGICAL, armor 0
	_check("Kinetik vs Bio = 1.5x", CombatEngine.calculate(CombatData.KINETIC, bio, 40).damage == 60)
	_check("Galvanik vs Bio = 0.4x (Isolierung)", CombatEngine.calculate(CombatData.GALVANIC, bio, 40).damage == 16)
	_check("Thermik vs Bio = 1.3x", CombatEngine.calculate(CombatData.THERMAL, bio, 40).damage == 52)

	# Front-Immunität (Goliath, armor 30): frontal 0 Kinetik, Flanke normal, nach Korrosion voll.
	var goliath := CombatTarget.from_type("goliath")
	var frontal := CombatEngine.calculate(CombatData.KINETIC, goliath, 40)
	_check("Goliath frontal immun (Kinetik = 0)", frontal.damage == 0 and frontal.immune == true)
	_check("Goliath Flanke umgeht Immunität", CombatEngine.calculate(CombatData.KINETIC, goliath, 40, 10, false).damage == 10)
	_check("Thermik vs Goliath = 0.6x (widersteht)", CombatEngine.calculate(CombatData.THERMAL, goliath, 40).damage == 24)
	_check("Alchemie flaggt Korrosion", CombatEngine.calculate(CombatData.ALCHEMICAL, goliath, 12).effect == CombatData.FX_CORRODE)
	CombatEngine.apply_status(goliath, CombatData.FX_CORRODE, now, 30)   # Panzerung 30 -> 0
	_check("Korrosion senkt Panzerung auf 0", goliath.armor == 0)
	_check("Nach Korrosion trifft Kinetik frontal voll", CombatEngine.calculate(CombatData.KINETIC, goliath, 40).damage == 40)

	# Mitigations-Formel 100/(100+armor*9).
	_check("Mitigation armor 0 = voll", CombatEngine.mitigate_damage(100, 0) == 100)
	_check("Mitigation armor 10 = 53", CombatEngine.mitigate_damage(100, 10) == 53)

	# Status: Stun & DOT.
	var t := CombatTarget.from_type("konstrukt")
	CombatEngine.apply_status(t, CombatData.FX_STUN, now)
	_check("Kurzschluss-Stun aktiv", t.is_stunned(now + 3999) and not t.is_stunned(now + 4001))
	CombatEngine.apply_status(t, CombatData.FX_BLEED, now)
	var dot_dmg: int = CombatEngine.tick_dot(t, now + 100, 0.5)   # >= 0.4s -> tickt
	_check("Verbluten-DOT fügt Schaden zu", dot_dmg > 0 and t.health < t.max_health)
	_check("DOT läuft nach 3s ab", CombatEngine.tick_dot(t, now + 4000, 0.5) == 0 and not t.has_dot())

	# XP pro Kill.
	_check("XP Superboss = 300", CombatData.xp_for_kill(CombatTarget.from_type("goliath", {"superboss": true})) == 300)
	_check("XP Elite = 50", CombatData.xp_for_kill(CombatTarget.from_type("outlaw", {"elite": true})) == 50)


# ── Modul (Quest): QuestManager ───────────────────────────────────────────────
func _test_quest_manager() -> void:
	print("· QuestManager")
	_reset_state()

	# Reveal (Kapitel 4 -> 5).
	GameState.current_chapter = 4
	QuestManager.trigger_chapter_4_reveal()
	_check("Reveal setzt is_revealed & reveal_playing", GameState.is_revealed and GameState.flags_ui["reveal_playing"] == true)
	QuestManager.trigger_chapter_4_reveal()   # zweiter Aufruf: idempotent, kein Effekt
	_check("Reveal ist idempotent (Kapitel noch 4)", GameState.current_chapter == 4 and GameState.is_revealed == true)
	QuestManager.finish_reveal()
	_check("finish_reveal hebt auf Kapitel 5", GameState.current_chapter == 5 and GameState.flags_ui["reveal_playing"] == false)

	# Gildenwahl (Kapitel-5-Gate, exklusiv).
	_check("choose_guild rebels ok", QuestManager.choose_guild("rebels") == true and GameState.chosen_guild == "rebels")
	_check("zweite Gildenwahl blockiert", QuestManager.choose_guild("corp") == false)
	_check("fremde Gilde gesperrt", QuestManager.can_access_guild("corp") == false)

	# Kill-Quest via questBase.
	_check("accept q_rebels5", QuestManager.accept_quest("q_rebels5") == true)
	_check("questBase eingefroren", int(GameState.quest_base["q_rebels5"]) == GameState.kills)
	_check("fremde Gilden-Quest geblockt", QuestManager.accept_quest("q_corp5") == false)
	for i in 12:
		GameState.add_kill()
	var prog: Dictionary = QuestManager.check_quest_progress("q_rebels5")
	_check("Fortschritt 12/12", prog["current"] == 12 and prog["complete"] == true)
	var gold_before: int = GameState.gold
	_check("complete q_rebels5", QuestManager.complete_quest("q_rebels5") == true)
	_check("Belohnung Gold +250", GameState.gold == gold_before + 250)
	_check("Belohnung Dampfkern +1", GameState.item_count("dampfkern") == 1)
	_check("Kapitel-Sprung -> 8", GameState.current_chapter == 8)
	_check("Doppel-Abgabe blockiert", QuestManager.complete_quest("q_rebels5") == false)

	# Collect-Quest (Schmuggler) mit Item-Abzug — eigener Reset.
	_reset_state()
	GameState.is_revealed = true
	GameState.current_chapter = 5
	QuestManager.choose_guild("smugglers")
	QuestManager.accept_quest("q_smug5")   # 3 Dampfkerne sammeln
	_check("Collect nicht komplett ohne Items", QuestManager.complete_quest("q_smug5") == false)
	GameState.add_item("dampfkern", 3)
	_check("Collect komplett mit 3 Dampfkernen", QuestManager.is_quest_complete("q_smug5"))
	_check("complete q_smug5", QuestManager.complete_quest("q_smug5") == true)
	_check("Collect zieht Items ab", GameState.item_count("dampfkern") == 0)
	_check("Collect Gold +300", GameState.gold == 300)


# ── Modul 2: TycoonManager ────────────────────────────────────────────────────
func _test_tycoon_manager() -> void:
	print("· TycoonManager (Modul 2)")
	_reset_state()
	TycoonManager.sim_seconds = 0.0
	TycoonManager._boost_until = { "saloon": 0.0, "forge": 0.0, "distillery": 0.0 }

	GameState.set_building_level("saloon", 3)      # 3*1
	GameState.set_building_level("forge", 2)       # 2*2
	GameState.set_building_level("distillery", 1)  # 1*4
	_check("income_per_sec = 3+4+4 = 11", TycoonManager.income_per_sec() == 11)

	# Kostenkurve base*(level+1).
	_check("upgrade_cost saloon (lvl3) = 400", TycoonManager.upgrade_cost("saloon") == 400)
	_check("upgrade_cost forge (lvl2) = 660", TycoonManager.upgrade_cost("forge") == 660)

	# Ausbau bucht ganzzahlig ab.
	GameState.gold = 500
	_check("try_upgrade saloon", TycoonManager.try_upgrade("saloon") == true)
	_check("Gold abgezogen (500-400)", GameState.gold == 100)
	_check("Stufe erhöht auf 4", GameState.building_level("saloon") == 4)
	GameState.gold = 0
	_check("try_upgrade ohne Gold scheitert", TycoonManager.try_upgrade("saloon") == false)

	# Ripple-Matrix.
	TycoonManager.activate_boost("forge", 60.0)
	_check("Forge-Boost aktiv", TycoonManager.is_boost_active("forge"))
	_check("Kosten-Rabatt -10%", is_equal_approx(TycoonManager.cost_multiplier(), 0.9))
	TycoonManager.activate_boost("distillery", 60.0)
	_check("Verkaufswert +20%", TycoonManager.sell_value(200) == 240)
	# Saloon-Boost: +15% auf Schmiede-Komponente. saloon3 + forge2(4*1.15=4.6) + distillery1(4) = 11.6 -> 12
	TycoonManager.activate_boost("saloon", 60.0)
	GameState.set_building_level("saloon", 3)
	_check("Saloon-Ripple hebt Schmiede (-> 12)", TycoonManager.income_per_sec() == 12)
	# Booster laufen über die Sim-Uhr ab.
	TycoonManager.sim_seconds = 100.0
	_check("Booster nach Ablauf inaktiv", not TycoonManager.is_boost_active("forge"))

	# Aktiver Tick schreibt ganzzahlig Gold.
	_reset_state()
	GameState.set_building_level("saloon", 5)   # 5 Gold/Sek
	GameState.gold = 0
	TycoonManager._tick_second()
	_check("Sekunden-Tick schreibt +5 Gold", GameState.gold == 5)


# ── Modul 3: GridInventoryBackend ─────────────────────────────────────────────
func _test_grid_inventory() -> void:
	print("· GridInventoryBackend (Modul 3)")
	var grid := GridInventoryBackend.new(10, 8)

	_check("Footprint Rüstung 2x2", GridInventoryBackend.footprint("armor") == Vector2i(2, 2))
	_check("Footprint Waffe 2x1", GridInventoryBackend.footprint("weapon") == Vector2i(2, 1))
	_check("Footprint schwere Waffe 3x1", GridInventoryBackend.footprint("heavy_weapon") == Vector2i(3, 1))
	_check("Footprint Kleinteil 1x1", GridInventoryBackend.footprint("helmet") == Vector2i(1, 1))

	_check("leeres Grid: 80 frei", grid.free_cells() == 80)
	_check("can_fit 2x2 @ (0,0)", grid.can_fit_item(0, 0, 2, 2) == true)
	_check("insert 2x2 @ (0,0)", grid.insert_item(101, 0, 0, 2, 2) == true)
	_check("belegte Zelle nicht frei", grid.can_fit_item(0, 0, 1, 1) == false)
	_check("used_cells = 4", grid.used_cells() == 4)
	_check("Überlappung abgelehnt", grid.insert_item(102, 1, 1, 2, 2) == false)
	_check("dieselbe uid nicht doppelt", grid.insert_item(101, 5, 5, 1, 1) == false)

	# Grenzen.
	_check("Out-of-Bounds (Breite) abgelehnt", grid.can_fit_item(9, 0, 2, 1) == false)
	_check("Out-of-Bounds (Höhe) abgelehnt", grid.can_fit_item(0, 7, 1, 2) == false)

	# Auto-Platzierung row-major.
	var pos: Vector2i = grid.find_first_empty_space(3, 1)
	_check("find_first_empty_space (3x1) = (2,0)", pos == Vector2i(2, 0))
	_check("place_first schwere Waffe", grid.place_first(103, 3, 1) == true)

	# Entfernen gibt alle Zellen frei.
	grid.remove_item(101)
	_check("remove_item gibt 4 Zellen frei", grid.can_fit_item(0, 0, 2, 2) == true and grid.has_item(101) == false)

	# Voll-Szenario: kein Platz.
	var small := GridInventoryBackend.new(2, 2)
	small.insert_item(1, 0, 0, 2, 2)
	_check("volles Grid: kein Platz", small.find_first_empty_space(1, 1) == Vector2i(-1, -1))


# ── WorldManager ──────────────────────────────────────────────────────────────
func _test_world_manager() -> void:
	print("· WorldManager")
	_reset_state()

	_check("Sektor Y=300 -> 1", WorldManager.sector_of_y(300) == 1)
	_check("Sektor Y=1000 -> 2", WorldManager.sector_of_y(1000) == 2)
	_check("Sektor Y=1600 -> 3", WorldManager.sector_of_y(1600) == 3)
	_check("POI Koordinaten (Eisernes Herz)", WorldManager.poi_position("eisernes_herz") == Vector2(1000, 1950))
	_check("Dungeon-Ebenen Schmelzöfen = 4", WorldManager.dungeon_floors("schmelzoefen_vulcan") == 4)

	# Gate 1: Sprengtore.
	GameState.current_chapter = 1
	_check("Sprengtore vor Kap.4 zu", WorldManager.is_blast_gate_open() == false)
	_check("Nord-Querung blockiert", WorldManager.can_cross_blast_line(700, 850) == false)
	GameState.current_chapter = 5
	_check("Sprengtore nach Kap.4 offen", WorldManager.is_blast_gate_open() == true)
	_check("Nord-Querung frei", WorldManager.can_cross_blast_line(700, 850) == true)

	# Gate 2: Smog-Linie.
	GameState.set_building_level("laboratory", 0)
	_check("kein Filter ohne Labor-Stufe 3", WorldManager.has_alchemie_filter() == false)
	_check("Smog tödlich (>0 DOT)", WorldManager.smog_dot_damage(Vector2(0, 1600), 1.0) > 0)
	GameState.set_building_level("laboratory", 3)
	_check("Labor Stufe 3 -> Filter", WorldManager.has_alchemie_filter() == true)
	_check("mit Filter kein Smog-Schaden", WorldManager.smog_dot_damage(Vector2(0, 1600), 1.0) == 0)

	# Gate 3: Fraktions-Feindseligkeit.
	GameState.chosen_guild = null
	_check("vor Wahl kein HQ feindlich", WorldManager.is_base_hostile("sektor01") == false)
	GameState.chosen_guild = "rebels"
	_check("Rebellen -> Sektor 01 feindlich", WorldManager.is_base_hostile("sektor01") == true)
	_check("eigenes HQ freundlich", WorldManager.is_base_friendly("fort_freedom") == true)
