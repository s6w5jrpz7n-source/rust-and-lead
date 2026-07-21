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
	_test_memory_manager()
	_test_encounter_manager()
	_test_progression_manager()
	_test_rift_manager()
	_test_save_manager()
	_test_equip_manager()
	_test_player_stats()
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
	GameState.perk_points = 0
	GameState.perks = {}
	GameState.upgrades = { "damage": 0, "firerate": 0, "hp": 0, "speed": 0, "regen": 0, "magnet": 0 }
	GameState.ng_plus = 0
	GameState.gold = 0
	GameState.potions = 3
	GameState.kills = 0
	GameState.inventory = { "schrott": 0, "zahnrad": 0, "dampfkern": 0 }
	GameState.equip = {}
	GameState.economy = { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 }
	GameState.quests = {}
	GameState.quest_base = {}
	GameState.flags_ui = { "reveal_playing": false }
	GameState.memories_found = 0
	GameState.memorials_seen = []
	GameState.family_buried = false
	GameState.codex = []


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

	# ── Biom-Zonierung (§1.6.3) ──
	_check("Biom Hub-Umland = Wüste", WorldManager.biome_at(Vector2(300, 300)) == "desert")
	_check("Biom Salzpfanne", WorldManager.biome_at(Vector2(250, 680)) == "salt")
	_check("Biom Grüne Senke", WorldManager.biome_at(Vector2(550, 250)) == "oasis")
	_check("Biom Rostwald", WorldManager.biome_at(Vector2(1120, 1080)) == "rostwald")
	_check("Biom Kupfer-Hochland", WorldManager.biome_at(Vector2(1750, 1350)) == "kupfer_hochland")
	_check("Biom Smog-Ödland (Sektor 3)", WorldManager.biome_at(Vector2(0, 1600)) == "smog_oedland")
	# Zonen überlappen nicht (jedes Zentrum liefert sein eigenes Biom)
	var centers_ok: bool = true
	for id in ["salt", "oasis", "rostwald", "kupfer_hochland"]:
		var b: Dictionary = WorldManager.BIOMES[id]
		if WorldManager.biome_at(Vector2(float(b["cx"]), float(b["cy"]))) != id:
			centers_ok = false
	_check("Zonen-Zentren eindeutig (kein Overlap)", centers_ok)

	# Gegner-Leitmix je Biom (deterministisch via roll = 0.0 -> erster Pool-Eintrag)
	_check("Rostwald pre = Wildnis (fauna zuerst)", WorldManager.pick_enemy_type("rostwald", false, 0.0) == "fauna")
	_check("Hochland post = mechanisch (konstrukt zuerst)", WorldManager.pick_enemy_type("kupfer_hochland", true, 0.0) == "konstrukt")
	_check("Salzpfanne pre = menschlich (revolver zuerst)", WorldManager.pick_enemy_type("salt", false, 0.0) == "revolver")
	_check("Salzpfanne pre-Reveal ohne Maschinen", not _pool_has(WorldManager.enemy_pool("salt", false), "konstrukt"))
	_check("Desert post enthält Kläffer (nach Reveal)", _pool_has(WorldManager.enemy_pool("desert", true), "klaeffer"))
	_check("Unbekanntes Biom fällt auf Wüste zurück", WorldManager.enemy_pool("nonexistent", false) == WorldManager.enemy_pool("desert", false))

	# Zonen erben Sektor-Gating (§1.7)
	GameState.current_chapter = 1
	GameState.set_building_level("laboratory", 0)
	_check("Rostwald vor Kap.4 gesperrt (Sektor 2)", WorldManager.is_biome_unlocked("rostwald") == false)
	_check("Wüste immer offen (Sektor 1)", WorldManager.is_biome_unlocked("desert") == true)
	GameState.current_chapter = 5
	_check("Rostwald nach Reveal offen", WorldManager.is_biome_unlocked("rostwald") == true)
	_check("Smog-Ödland ohne Filter gesperrt (Sektor 3)", WorldManager.is_biome_unlocked("smog_oedland") == false)
	GameState.set_building_level("laboratory", 3)
	_check("Smog-Ödland mit Filter offen", WorldManager.is_biome_unlocked("smog_oedland") == true)
	_check("Unique-Champion-Chance = 30%", is_equal_approx(WorldManager.UNIQUE_CHAMPION_CHANCE, 0.30))


func _pool_has(pool: Array, type_id: String) -> bool:
	for p in pool:
		if String(p[0]) == type_id:
			return true
	return false


# ── MemoryManager: Erinnerungs-Walzen & Familien-Bogen (§8.3) ─────────────────
func _test_memory_manager() -> void:
	print("· MemoryManager (roter Faden §8.3)")
	_reset_state()

	# Kette: 16 geordnete Fragmente, jedes mit Titel+Text.
	_check("Erinnerungskette = 16", MemoryManager.chain_length() == 16)
	var all_data: bool = true
	for m in MemoryManager.MEMORIES:
		if String(m.get("title", "")) == "" or String(m.get("text", "")) == "":
			all_data = false
	_check("jedes Fragment hat Titel+Text", all_data)
	_check("next_memory = erstes Fragment", MemoryManager.next_memory()["title"] == "Der Nagel")

	# Bergen rückt die Kette vor und schaltet beim ersten Fund den Drop-Logik-Codex frei.
	var m0: Dictionary = MemoryManager.recover_memory()
	_check("recover gibt Fragment 1", m0["title"] == "Der Nagel" and GameState.memories_found == 1)
	_check("erster Fund schaltet 'steuerwalzen' frei", GameState.codex_has("steuerwalzen"))
	_check("next_memory rückt vor", MemoryManager.next_memory()["title"] == "Kaffee, zu früh")

	# Drop-Wahrscheinlichkeit: deterministisch via roll (3 % normal, 50 % Boss).
	_check("recovery_chance normal = 0.03", is_equal_approx(MemoryManager.recovery_chance(false), 0.03))
	_check("recovery_chance Boss = 0.50", is_equal_approx(MemoryManager.recovery_chance(true), 0.50))
	var before: int = GameState.memories_found
	_check("roll 0.02 < 0.03 -> Fund", not MemoryManager.try_recover_memory(false, 0.02).is_empty() and GameState.memories_found == before + 1)
	_check("roll 0.04 >= 0.03 -> kein Fund", MemoryManager.try_recover_memory(false, 0.04).is_empty())
	_check("Boss roll 0.40 < 0.50 -> Fund", not MemoryManager.try_recover_memory(true, 0.40).is_empty())

	# Vollsammlung: Kette füllen, dann sperrt weiteres Bergen.
	while not MemoryManager.is_complete():
		MemoryManager.recover_memory()
	_check("Kette voll bei 16", GameState.memories_found == 16 and MemoryManager.is_complete())
	_check("recover bei voller Kette = {}", MemoryManager.recover_memory().is_empty())
	_check("Erfolg 'Jeremiah Hale' (rememberer)", MemoryManager.is_rememberer())

	# Erinnerungspunkte: Türrahmen/Foto schalten 'familie' frei, liefern Flashback-Zeilen.
	_reset_state()
	var door: Dictionary = MemoryManager.play_memorial("doorframe")
	_check("doorframe erstmalig gesehen", door["first_seen"] == true and GameState.memorials_seen.has("doorframe"))
	_check("doorframe schaltet 'familie' frei", GameState.codex_has("familie"))
	_check("doorframe liefert Flashback-Zeilen", door["lines"].size() >= 3 and door["graves_state"] == "")
	_check("doorframe zweiter Besuch nicht mehr 'first'", MemoryManager.play_memorial("doorframe")["first_seen"] == false)
	_check("photo schaltet ebenfalls 'familie'", not MemoryManager.play_memorial("photo").is_empty())

	# Providence-Gating: erst nach dem Erwachen offen.
	GameState.is_revealed = false
	_check("Providence vor Reveal verschlossen", MemoryManager.is_providence_open() == false)
	GameState.is_revealed = true
	_check("Providence nach Reveal offen", MemoryManager.is_providence_open() == true)

	# Gräber gestuft: unvollständig -> kein Begräbnis.
	_reset_state()
	GameState.memories_found = 5
	var g_inc: Dictionary = MemoryManager.play_memorial("graves")
	_check("Gräber unvollständig", g_inc["graves_state"] == "incomplete")
	_check("bury_family scheitert unvollständig", MemoryManager.bury_family() == false and GameState.family_buried == false)

	# Gräber vollständig: Begräbnis setzt Zustand, Codex, Erfolg — und ist einmalig.
	GameState.memories_found = 16
	_check("Gräber bereit bei 16/16", MemoryManager.play_memorial("graves")["graves_state"] == "ready")
	_check("bury_family erfolgreich", MemoryManager.bury_family() == true and GameState.family_buried)
	_check("Begräbnis schaltet 'heimkehr' frei", GameState.codex_has("heimkehr") and GameState.codex_has("familie"))
	_check("Erfolg 'Heimkehr' (homecoming)", MemoryManager.is_homecoming())
	_check("Gräber danach 'buried'", MemoryManager.graves_state() == "buried")
	_check("bury_family zweimal = false", MemoryManager.bury_family() == false)


# ── EncounterManager: Mini-Dungeons & Unique-Champions (§8.2) ─────────────────
func _test_encounter_manager() -> void:
	print("· EncounterManager (Mini-Dungeons & Champions §8.2)")
	_reset_state()

	# Roster-Parität: Kläffer ist im Backend vorhanden (Hallen-Thema nutzt ihn).
	_check("Kläffer im Roster (Parität)", CombatData.ENEMY_TYPES.has("klaeffer"))
	_check("Kläffer ist mechanischer Schwarm", String(CombatData.ENEMY_TYPES["klaeffer"]["class"]) == "MECHANICAL" and bool(CombatData.ENEMY_TYPES["klaeffer"].get("swarm", false)))

	# Hallen-Themen: 3, deterministisch via roll (0.0 -> erstes).
	_check("3 Hallen-Themen", EncounterManager.HALL_THEMES.size() == 3)
	_check("roll 0.0 -> Rattennest", EncounterManager.roll_hall_theme(0.0)["id"] == "rats")
	_check("roll 0.99 -> Banditenloch", EncounterManager.roll_hall_theme(0.99)["id"] == "outlaws")
	var theme_types_ok: bool = true
	for th in EncounterManager.HALL_THEMES:
		if not CombatData.ENEMY_TYPES.has(String(th["type"])):
			theme_types_ok = false
	_check("alle Themen-Typen im Roster", theme_types_ok)

	# Champion-Wurf: ~30 % (WorldManager.UNIQUE_CHAMPION_CHANCE); deterministisch via roll.
	_check("roll 0.10 < 0.30 -> Champion", EncounterManager.is_unique_pack(0.10) == true)
	_check("roll 0.50 >= 0.30 -> kein Champion", EncounterManager.is_unique_pack(0.50) == false)
	var rats: Dictionary = EncounterManager.roll_hall_theme(0.0)
	_check("Rudel normal = Themen-Anzahl", EncounterManager.pack_size(rats, false) == 11)
	_check("Rudel mit Champion = +3", EncounterManager.pack_size(rats, true) == 14)

	# Champion-Namen: aus der Liste, deterministisch.
	_check("champion_name(0.0) = erster", EncounterManager.champion_name(0.0) == EncounterManager.UNIQUE_NAMES[0])
	_check("champion_name in Liste", EncounterManager.UNIQUE_NAMES.has(EncounterManager.champion_name(0.99)))

	# Champion-Aufbau: ×6 Leben (× Faktor), +Panzerung, benannt, als Boss & Unique.
	var champ: CombatTarget = EncounterManager.make_champion("klaeffer", 0.0, 1.0)
	var base_hp: int = int(CombatData.ENEMY_TYPES["klaeffer"]["hp"])   # 40
	_check("Champion HP = 6x Basis", champ.max_health == base_hp * 6 and champ.health == champ.max_health)
	_check("Champion +Panzerung", champ.armor == int(CombatData.ENEMY_TYPES["klaeffer"]["armor"]) + 6)
	_check("Champion ist Unique+Boss", champ.is_unique and champ.is_boss)
	_check("Champion benannt", champ.display_name == EncounterManager.UNIQUE_NAMES[0])
	var champ2: CombatTarget = EncounterManager.make_champion("outlaw", 0.0, 1.5)
	_check("hp_mul skaliert Leben", champ2.max_health == roundi(int(CombatData.ENEMY_TYPES["outlaw"]["hp"]) * 6.0 * 1.5))

	# Beute-Kontrakt: garantiertes Legendary aus benennbaren Slots, zählt als Boss-Kill.
	var loot: Dictionary = EncounterManager.champion_loot()
	_check("Champion-Beute garantiert Legendary", loot["legendary_guaranteed"] == true)
	_check("Legendary-Slots benennbar", loot["legendary_slots"] == ["weapon", "armor", "gadget", "boots", "helmet"])
	_check("Champion-Beute: 2 Boss-Kisten, x2 Gold", int(loot["boss_chests"]) == 2 and int(loot["gold_mult"]) == 2)
	_check("Champion zählt als Boss-Kill", loot["counts_as_boss"] == true)

	# Konkrete Champion-Beute via ProgressionManager: garantiertes benanntes Legendary.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var reward: Dictionary = EncounterManager.champion_reward(rng)
	_check("Champion-Reward: Legendary", String(reward["gear"]["rarity"]) == "legendary" and reward["gear"].has("legendary_power"))
	_check("Champion-Reward: Slot benennbar", EncounterManager.CHAMPION_LEGENDARY_SLOTS.has(String(reward["gear"]["slot"])))
	_check("Champion-Reward: zählt als Boss", reward["counts_as_boss"] == true)


# ── ProgressionManager: Itemization (Seltenheiten, Affixe, Legendaries, Tech) §8.1 ──
func _test_progression_manager() -> void:
	print("· ProgressionManager (Itemization §8.1)")
	_reset_state()

	# Seltenheiten.
	_check("4 Seltenheiten", ProgressionManager.RARITY_ORDER.size() == 4)
	_check("Legendär mult 4.2", is_equal_approx(float(ProgressionManager.RARITY["legendary"]["mult"]), 4.2))

	# Affix-Roll: deterministisch via quality_roll. q=0.5 -> Faktor 1.0, val = round(base*mult*factor).
	var aff: Dictionary = ProgressionManager.roll_affix("hp", 1.0, 14.0 / 12.0, 0.5)
	_check("roll_affix hp @q0.5 = 14", int(aff["val"]) == 14 and is_equal_approx(float(aff["q"]), 0.5))
	_check("roll_affix Wert >= 1", int(ProgressionManager.roll_affix("armor", 1.0, 0.1, 0.0)["val"]) >= 1)

	# Seltenheits-Wurf deterministisch.
	_check("roll_rarity 0.0 = common", ProgressionManager.roll_rarity(0.0, 0.0) == "common")
	_check("roll_rarity 0.999 = legendary", ProgressionManager.roll_rarity(0.0, 0.999) == "legendary")

	# make_gear (seedbar): Struktur, Affix-Anzahl je Seltenheit, Legendär-Kraft.
	var grng := RandomNumberGenerator.new()
	grng.seed = 7
	var epic: Dictionary = ProgressionManager.make_gear("armor", "epic", "", grng)
	_check("make_gear Slot/Seltenheit", String(epic["slot"]) == "armor" and String(epic["rarity"]) == "epic")
	_check("make_gear Haupt-Stat (armor)", String(epic["stat"]["key"]) == "armor" and int(epic["stat"]["val"]) >= 1)
	_check("make_gear epic = 2 Affixe", (epic["affixes"] as Array).size() == 2)
	var common: Dictionary = ProgressionManager.make_gear("boots", "common", "", grng)
	_check("make_gear common = 0 Affixe", (common["affixes"] as Array).size() == 0)

	# Legendär: benannte Kraft; erzwungene Boss-Kraft.
	var leg: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "", grng)
	_check("Legendär hat benannte Kraft", leg.has("legendary_power") and String(leg["name"]) != "")
	var forced: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", grng)
	_check("force_power -> Golem-Faust", String(forced["legendary_power"]) == "overcharge" and String(forced["name"]) == "Golem-Faust")
	var vane: Dictionary = ProgressionManager.make_gear("armor", "legendary", "vaneward", grng)
	_check("force_power -> Wachsherz-Kürass", String(vane["name"]) == "Wachsherz-Kürass")

	# Ableitungen: Wert, Stat-Summe, Fußabdruck.
	_check("gear_value legendär > common", ProgressionManager.gear_value(leg) > ProgressionManager.gear_value(common))
	_check("gear_stat_of armor summiert", ProgressionManager.gear_stat_of(epic, "armor") >= int(epic["stat"]["val"]))
	_check("gear_foot Rüstung 2x2", ProgressionManager.gear_foot(epic) == Vector2i(2, 2))
	_check("gear_cells Rüstung = 4", ProgressionManager.gear_cells(epic) == 4)

	# Tech-Modul: Haupt-Stat skaliert mit Seltenheit.
	var tech: Dictionary = ProgressionManager.make_tech("schaden", "rare")
	_check("make_tech Stat = round(base*mult)", int(tech["stat"]["val"]) == roundi(5.0 * 1.8) and String(tech["slot"]) == "tech")

	# ── Perk-Baum (Fallout-Achse §7.5.1) ──
	_reset_state()
	_check("3 Perk-Zweige", ProgressionManager.PERK_BRANCHES.size() == 3)
	# Kauf: Punkt vorhanden, Tier 1 sofort; Rang & Punkte aktualisieren, Wirkwert = Rang×per.
	GameState.level = 1
	GameState.perk_points = 3
	_check("scharf kaufbar (Tier 1)", ProgressionManager.perk_can_buy("scharf"))
	_check("buy_perk scharf", ProgressionManager.buy_perk("scharf") == true and ProgressionManager.perk_rank("scharf") == 1)
	_check("Punkt abgezogen", GameState.perk_points == 2)
	_check("perk_val = Rang×per (4)", ProgressionManager.perk_val("scharf") == 4)
	ProgressionManager.buy_perk("scharf")
	_check("perk_val Rang 2 = 8", ProgressionManager.perk_val("scharf") == 8)
	ProgressionManager.buy_perk("scharf")
	_check("Max-Rang: nicht weiter kaufbar", ProgressionManager.perk_can_buy("scharf") == false and GameState.perk_points == 0)

	# Tier-Gating: Kapstein braucht Level 14 + 6 Punkte im Zweig.
	_reset_state()
	GameState.level = 5
	GameState.perk_points = 20
	_check("Kapstein Level 5 gesperrt", ProgressionManager.perk_can_buy("cap_gun") == false)
	GameState.level = 14
	# 6 Punkte im gun-Zweig investieren.
	ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf")
	ProgressionManager.buy_perk("schnell"); ProgressionManager.buy_perk("schnell"); ProgressionManager.buy_perk("schnell")
	_check("Zweig-Punkte gun = 6", ProgressionManager.branch_points("gun") == 6)
	_check("Kapstein jetzt kaufbar", ProgressionManager.perk_can_buy("cap_gun"))
	ProgressionManager.buy_perk("cap_gun")
	_check("has_cap gun", ProgressionManager.has_cap("gun"))
	# XOR: nur ein Kapstein — die anderen sind gesperrt.
	GameState.level = 14
	# genug tech-Punkte für Tier 4 investieren, damit nur die xor-Sperre greift.
	ProgressionManager.buy_perk("gurt"); ProgressionManager.buy_perk("gurt"); ProgressionManager.buy_perk("gurt")
	ProgressionManager.buy_perk("aasgeier"); ProgressionManager.buy_perk("aasgeier"); ProgressionManager.buy_perk("aasgeier")
	_check("zweiter Kapstein xor-gesperrt", ProgressionManager.perk_can_buy("cap_tech") == false and ProgressionManager.xor_blocked("cap_tech"))

	# Respec: erst nach Reveal, erstattet Ränge als Punkte, kostet Gold + Dampfkern.
	_reset_state()
	GameState.level = 5
	GameState.perk_points = 3
	ProgressionManager.buy_perk("zaeh"); ProgressionManager.buy_perk("panzer")   # 2 Ränge im grit-Zweig
	GameState.is_revealed = false
	_check("Respec vor Reveal gesperrt", ProgressionManager.do_respec() == false)
	GameState.is_revealed = true
	GameState.gold = 1000
	GameState.add_item("dampfkern", 2)
	var pts_before: int = GameState.perk_points
	_check("do_respec erfolgreich", ProgressionManager.do_respec() == true)
	_check("Ränge erstattet (+2 Punkte)", GameState.perk_points == pts_before + 2 and GameState.perks.is_empty())
	_check("Respec zieht Dampfkern ab", GameState.item_count("dampfkern") == 1)


# ── RiftManager: Abstieg-Endlosmodus (Biome, Mods, Tiefen-Skalierung) §7.5.6/§8.1 ──
func _test_rift_manager() -> void:
	print("· RiftManager (Abstieg §7.5.6)")

	# Biome rotieren alle 5 Ebenen, dann von vorn.
	_check("5 Abstieg-Biome", RiftManager.BIOMES.size() == 5)
	var ids: Array = []
	for d in [1, 6, 11, 16, 21, 26]:
		ids.append(String(RiftManager.biome_for(d)["id"]))
	_check("Biom-Rotation stollen..herz..stollen", str(ids) == str(["stollen", "frost", "magma", "sporen", "herz", "stollen"]))
	_check("Biom-Wechsel bei Bandgrenze (5->6)", RiftManager.biome_changed(5, 6) == true)
	_check("kein Wechsel im Band (11->12)", RiftManager.biome_changed(11, 12) == false)

	# Modifikatoren.
	_check("4 Modifikatoren", RiftManager.MODS.size() == 4)
	_check("roll_mod 0.0 = Andrang", String(RiftManager.roll_mod(0.0)["id"]) == "horde")
	_check("roll_mod 0.99 = Elite-Nest", String(RiftManager.roll_mod(0.99)["id"]) == "elite")

	# Tiefen-Skalierung (deterministische Formeln).
	_check("HP-Faktor Ebene 3 = 2.0", is_equal_approx(RiftManager.enemy_hp_mul(3, "", 0), 2.0))
	_check("HP-Faktor Ebene 3 + Überdruck = 2.6", is_equal_approx(RiftManager.enemy_hp_mul(3, "brute", 0), 2.6))
	_check("HP-Faktor Ebene 1 + NG+1 = 1.6", is_equal_approx(RiftManager.enemy_hp_mul(1, "", 1), 1.6))
	_check("Rasende Meute = Tempo x1.25", is_equal_approx(RiftManager.enemy_speed_mul("swift"), 1.25))
	_check("Dichte Ebene 6 + Andrang = 3.0", is_equal_approx(RiftManager.density(6, "horde"), 3.0))
	_check("Elite-Zahl Ebene 9 (Basis 1) = 4", RiftManager.elite_count(9, 1, "") == 4)
	_check("Elite-Nest +2", RiftManager.elite_count(9, 1, "elite") == 6)

	# Superboss alle 3 Ebenen.
	_check("Superboss auf Ebene 3", RiftManager.has_superboss(3))
	_check("Superboss auf Ebene 6", RiftManager.has_superboss(6))
	_check("kein Superboss auf Ebene 4", not RiftManager.has_superboss(4))


# ── SaveManager: Persistenz (serialize/deserialize, JSON, Datei-Slots) §2.3 ───
func _test_save_manager() -> void:
	print("· SaveManager (Persistenz §2.3)")
	_reset_state()

	# Einen bunten Zustand aufbauen.
	GameState.current_chapter = 8
	GameState.is_revealed = true
	GameState.chosen_guild = "rebels"
	GameState.level = 12
	GameState.xp = 55
	GameState.perk_points = 2
	GameState.perks = { "scharf": 3, "krit": 1 }
	GameState.gold = 777
	GameState.inventory = { "schrott": 4, "zahnrad": 1, "dampfkern": 2 }
	GameState.set_building_level("saloon", 3)
	GameState.kills = 140
	GameState.quests = { "q_rebels5": "done", "q_rebels8": "active" }
	GameState.quest_base = { "q_rebels8": 120 }
	GameState.memories_found = 9
	GameState.memorials_seen = ["doorframe", "photo"]
	GameState.family_buried = false
	GameState.codex = ["reveal", "steuerwalzen", "familie"]
	var srng := RandomNumberGenerator.new(); srng.seed = 1
	GameState.equip = { "weapon": ProgressionManager.make_gear("weapon", "legendary", "overcharge", srng) }

	# Dictionary-Roundtrip: serialisieren, Zustand zurücksetzen, wiederherstellen.
	var snap: Dictionary = SaveManager.serialize()
	_check("Save trägt Version", int(snap["version"]) == SaveManager.SAVE_VERSION)
	_reset_state()
	_check("Reset leert Zustand", GameState.level == 1 and GameState.gold == 0)
	SaveManager.deserialize(snap)
	_check("Roundtrip: Kapitel/Gilde", GameState.current_chapter == 8 and GameState.chosen_guild == "rebels")
	_check("Roundtrip: Level/Gold", GameState.level == 12 and GameState.gold == 777)
	_check("Roundtrip: Perks", ProgressionManager.perk_rank("scharf") == 3 and GameState.perk_points == 2)
	_check("Roundtrip: Quests", String(GameState.quests["q_rebels5"]) == "done" and int(GameState.quest_base["q_rebels8"]) == 120)
	_check("Roundtrip: roter Faden", GameState.memories_found == 9 and GameState.memorials_seen == ["doorframe", "photo"] and GameState.codex.has("familie"))
	_check("Roundtrip: Gebäude", GameState.building_level("saloon") == 3)
	_check("Roundtrip: Loadout", EquipManager.is_equipped("weapon") and String(EquipManager.equipped("weapon")["legendary_power"]) == "overcharge")

	# JSON-Roundtrip (Zahlen kommen als Float zurück -> defensiver Cast).
	var json: String = SaveManager.to_json()
	_reset_state()
	_check("from_json ok", SaveManager.from_json(json) == true)
	_check("JSON-Roundtrip: Level/Kills als int", GameState.level == 12 and GameState.kills == 140 and typeof(GameState.level) == TYPE_INT)
	_check("JSON-Roundtrip: Inventar", GameState.item_count("dampfkern") == 2)
	_check("from_json Müll = false", SaveManager.from_json("nicht json {{{") == false)

	# Defensiv: leere Daten -> sichere Defaults, kein Crash.
	_reset_state()
	SaveManager.deserialize({})
	_check("Defaults aus leerer Save", GameState.level == 1 and GameState.current_chapter == 1 and GameState.chosen_guild == null and GameState.item_count("schrott") == 0)

	# Datei-Slot-Roundtrip (user://, headless verfügbar).
	_reset_state()
	GameState.level = 20
	GameState.gold = 999
	GameState.chosen_guild = "smugglers"
	_check("save_to_slot", SaveManager.save_to_slot(3) == true and SaveManager.has_slot(3))
	_reset_state()
	_check("load_from_slot", SaveManager.load_from_slot(3) == true and GameState.level == 20 and GameState.gold == 999 and GameState.chosen_guild == "smugglers")
	_check("load leerer Slot = false", SaveManager.load_from_slot(9) == false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.slot_path(3)))


# ── EquipManager: Loadout, Stat-Aggregation & legendäre Sets §7.4/§7.4.4 ──────
func _test_equip_manager() -> void:
	print("· EquipManager (Loadout & Sets §7.4.4)")
	_reset_state()
	GameState.equip = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	# Slot-Akzeptanz.
	var wpn: Dictionary = ProgressionManager.make_gear("weapon", "rare", "", rng)
	var arm: Dictionary = ProgressionManager.make_gear("armor", "rare", "", rng)
	var tech: Dictionary = ProgressionManager.make_tech("schaden", "epic")
	_check("Waffe passt in weapon-Slot", EquipManager.slot_accepts("weapon", wpn))
	_check("Waffe passt NICHT in helmet-Slot", EquipManager.slot_accepts("helmet", wpn) == false)
	_check("Tech-Modul passt in plate-Slot", EquipManager.slot_accepts("plate1", tech))
	_check("Rüstung passt NICHT in plate-Slot", EquipManager.slot_accepts("plate1", arm) == false)

	# Anlegen/Ablegen.
	_check("equip Waffe", EquipManager.equip_item(wpn, "weapon") and EquipManager.is_equipped("weapon"))
	_check("equip in falschen Slot scheitert", EquipManager.equip_item(wpn, "helmet") == false)
	EquipManager.equip_item(arm, "armor")
	EquipManager.equip_item(tech, "plate1")
	_check("3 Teile getragen", EquipManager.worn().size() == 3)
	var removed: Dictionary = EquipManager.unequip("plate1")
	_check("unequip gibt Teil zurück & leert Slot", not removed.is_empty() and not EquipManager.is_equipped("plate1"))

	# Stat-Aggregation über angelegte Teile.
	_reset_state(); GameState.equip = {}
	var a1: Dictionary = ProgressionManager.make_gear("armor", "epic", "", rng)
	var h1: Dictionary = ProgressionManager.make_gear("helmet", "epic", "", rng)
	EquipManager.equip_item(a1, "armor")
	EquipManager.equip_item(h1, "helmet")
	var expected_armor: int = ProgressionManager.gear_stat_of(a1, "armor") + ProgressionManager.gear_stat_of(h1, "armor")
	_check("stat_total armor summiert Loadout", EquipManager.stat_total("armor") == expected_armor)

	# ── Legendäre Sets ──
	_reset_state(); GameState.equip = {}
	# Direktorat (2-teilig): Wachsherz-Kürass (vaneward) + Golem-Faust (overcharge).
	var vane: Dictionary = ProgressionManager.make_gear("armor", "legendary", "vaneward", rng)
	var golem: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	EquipManager.equip_item(vane, "armor")
	_check("Set 1/2: noch kein Bonus", EquipManager.set_piece_count("direktorat") == 1 and EquipManager.granted_powers().is_empty())
	_check("nur getragene Kraft vaneward aktiv", EquipManager.has_power("vaneward") and not EquipManager.has_power("cap_grit"))
	EquipManager.equip_item(golem, "weapon")
	_check("Set 2/2 vollständig", EquipManager.set_piece_count("direktorat") == 2)
	_check("Set verleiht Perk cap_grit", EquipManager.has_power("cap_grit") and EquipManager.granted_powers().has("cap_grit"))

	# Grenzland (3-teilig): gestufte Boni (2 -> Krit-Stat, 3 -> critchain).
	_reset_state(); GameState.equip = {}
	var trommel: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "spread11", rng)
	var sohlen: Dictionary = ProgressionManager.make_gear("boots", "legendary", "plunder", rng)
	var visier: Dictionary = ProgressionManager.make_gear("helmet", "legendary", "critbase", rng)
	EquipManager.equip_item(trommel, "weapon")
	EquipManager.equip_item(sohlen, "boots")
	_check("Grenzland 2/3: +8 Krit-Bonus", EquipManager.set_piece_count("grenzland") == 2 and EquipManager.set_stat_bonus("crit") == 8)
	_check("Grenzland 2/3: noch kein critchain", EquipManager.has_power("critchain") == false)
	EquipManager.equip_item(visier, "helmet")
	_check("Grenzland 3/3: verleiht critchain", EquipManager.set_piece_count("grenzland") == 3 and EquipManager.has_power("critchain"))


# ── PlayerStats: effektive Kampfwerte (Kapstein: alle Systeme zusammen) §6/§7.5 ──
func _test_player_stats() -> void:
	print("· PlayerStats (effektive Werte — Kapstein)")
	_reset_state()
	GameState.equip = {}

	# Basiswerte ohne Boni.
	_check("Basis-Schaden Karabiner = 20", PlayerStats.damage_per_bullet("karabiner") == 20)
	_check("Basis-Feuerrate Karabiner = 200", PlayerStats.fire_ms("karabiner") == 200)
	_check("Basis max_hp (L1) = 100", PlayerStats.max_hp() == 100)
	_check("Basis Krit = 0", is_equal_approx(PlayerStats.crit_chance(), 0.0))
	_check("Krit-Mult = 2.0", is_equal_approx(PlayerStats.crit_mult(), 2.0))
	_check("Schaden-genommen-Faktor (0 Rüstung) = 1.0", is_equal_approx(PlayerStats.damage_taken_mul(), 1.0))
	_check("Basis Tempo/Regen/Magnet/Loot", PlayerStats.move_speed() == 240.0 and PlayerStats.regen_rate() == 8 and PlayerStats.magnet_dist() == 130 and is_equal_approx(PlayerStats.loot_mul(), 1.0))
	_check("Basis Spread=7, Pierce=0", PlayerStats.spread_count() == 7 and PlayerStats.pierce() == 0)

	# Perk-Beitrag: Scharfschütze Rang 3 (+4/Rang) -> +12 Schaden.
	GameState.level = 1
	GameState.perk_points = 3
	ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf")
	_check("Perk Scharfschütze: Schaden 20+12 = 32", PlayerStats.damage_per_bullet("karabiner") == 32)

	# Werkstatt-Upgrade + Ausrüstung + Legendär-Kraft (overcharge x1.18).
	_reset_state(); GameState.equip = {}
	GameState.upgrades["damage"] = 2   # +12
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var wpn: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	var dmg_stat: int = ProgressionManager.gear_stat_of(wpn, "damage")
	EquipManager.equip_item(wpn, "weapon")
	var expected: int = roundi((20 + 12 + dmg_stat) * 1.18)
	_check("Upgrade+Ausrüstung+Golem-Faust (x1.18)", PlayerStats.damage_per_bullet("karabiner") == expected)

	# Set-Integration: Direktorat verleiht cap_grit -> max_hp x1.2 & Schaden-genommen x0.8.
	_reset_state(); GameState.equip = {}
	var hp_base: int = PlayerStats.max_hp()   # 100
	var vane: Dictionary = ProgressionManager.make_gear("armor", "legendary", "vaneward", rng)
	var golem: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	EquipManager.equip_item(vane, "armor")
	EquipManager.equip_item(golem, "weapon")
	var hp_stat: int = ProgressionManager.gear_stat_of(vane, "hp")   # Rüstung hat i. d. R. keinen hp-Stat -> 0
	_check("Set cap_grit hebt max_hp um x1.2", PlayerStats.max_hp() == roundi((hp_base + hp_stat) * 1.2))
	# Schaden genommen: (100/(100+armor*9)) * 0.8 (Wachsherz-Kürass zusätzlich x0.85).
	var armor: int = PlayerStats.player_armor()
	var expected_dtm: float = (100.0 / (100.0 + armor * 9.0)) * 0.8 * 0.85
	_check("Set+Kürass senken Schaden-genommen", is_equal_approx(PlayerStats.damage_taken_mul(), expected_dtm))

	# Beute & Spread über Legendaries + NG+.
	_reset_state(); GameState.equip = {}
	GameState.ng_plus = 2   # +0.70
	var sohlen: Dictionary = ProgressionManager.make_gear("boots", "legendary", "plunder", rng)
	var trommel: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "spread11", rng)
	EquipManager.equip_item(sohlen, "boots")
	EquipManager.equip_item(trommel, "weapon")
	_check("Loot-Faktor: Plünderer(+0.25)+NG+2(+0.70) = 1.95", is_equal_approx(PlayerStats.loot_mul(), 1.95))
	_check("Spread mit Dolores' Trommel = 11", PlayerStats.spread_count() == 11)
	_check("Magnet +Plünderer-Sohlen (+60)", PlayerStats.magnet_dist() == 130 + 60)
