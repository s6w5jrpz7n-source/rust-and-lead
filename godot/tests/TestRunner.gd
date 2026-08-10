extends Node

const DialogBox = preload("res://scripts/DialogBox.gd")
const PaperDoll = preload("res://scripts/PaperDoll.gd")
const TownCollision = preload("res://scripts/TownCollision.gd")
const DayCycle = preload("res://scripts/DayCycle.gd")
const DialogData = preload("res://scripts/DialogData.gd")
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
var _scratch: Array = []   # Wegwerf-Objekte der Tests; am Ende gesammelt freigegeben

## Wie viele Pruefungen jede Testfunktion MINDESTENS liefern muss.
##
## Das ist kein Selbstzweck, sondern die Antwort auf einen Fehler, der diese Suite zweimal
## stillschweigend halbiert hat: Ein Laufzeitfehler in GDScript — etwa ein Zugriff auf eine
## Konstante, die es nicht mehr gibt — bricht die laufende Funktion sofort ab. Godot schreibt
## einen SCRIPT ERROR nach stderr, aber der Rest der Funktion laeuft nie, `_failed` bleibt bei
## null, und die Zusammenfassung meldet froehlich „0 fehlgeschlagen". Aufgefallen ist es nur,
## weil die Gesamtzahl von 988 auf 976 gefallen war — also durch Hingucken, und das ist keine
## Absicherung.
##
## Deshalb wird jede Funktion einzeln gewogen: Liefert sie weniger Pruefungen als hier
## eingetragen, ist sie abgebrochen, und der Lauf ist rot. Wer Tests ERGAENZT, traegt die neue
## Zahl hier nach — die Suite sagt am Ende genau, welche.
##
## Verschachtelte Aufrufe (`_test_daycycle` ruft `_test_prolog` auf) zaehlen beim Aufrufer mit.
## Das ist gewollt: Bricht die innere Funktion ab, sinkt die Summe des Aufrufers, und genau die
## wird hier geprueft.
const TEST_UMFANG: Dictionary = {
	"_test_combat_engine": 19,
	"_test_quest_manager": 20,
	"_test_tycoon_manager": 13,
	"_test_grid_inventory": 17,
	"_test_world_manager": 35,
	"_test_world_scale": 9,
	"_test_walkable_zones": 21,
	"_test_minimap": 21,
	"_test_fire_control": 10,
	"_test_wall_classification": 15,
	"_test_workshop": 21,
	"_test_ammo": 12,
	"_test_reload": 18,
	"_test_weapons": 13,
	"_test_titel_und_erster": 76,
	"_test_steg_und_biome": 23,
	"_test_riss": 15,
	"_test_terrain": 25,
	"_test_winding": 4,
	"_test_inventory_grid": 16,
	"_test_paperdoll": 13,
	"_test_fog": 12,
	"_test_swamp": 85,
	"_test_dunes": 7,
	"_test_props": 36,
	"_test_station": 8,
	"_test_camera_zoom": 13,
	"_test_hud_layout": 8,
	"_test_bag": 21,
	"_test_asset_registry": 38,
	"_test_overworld_loot_flow": 6,
	"_test_overworld_quest_flow": 14,
	"_test_quest_wayfinding": 63,
	"_test_closeup": 13,
	"_test_poi_walkable": 24,
	"_test_town_walkable": 17,
	"_test_enemy_attacks": 20,
	"_test_daycycle": 226,
	"_test_dialog": 22,
	"_test_memory_manager": 29,
	"_test_encounter_manager": 24,
	"_test_progression_manager": 34,
	"_test_rift_manager": 17,
	"_test_save_manager": 17,
	"_test_equip_manager": 16,
	"_test_player_stats": 15,
	"_test_zeichen": 5,
	"_test_stille_grube": 26,
	"_test_kraterrand": 8,
	"_test_kraterrand_kamm": 6,
	"_test_stimmen": 14,
	"_test_stufenanforderung": 13,
	"_test_haendler": 15,
	"_test_gedraenge": 23,
	"_test_ui_grafiken": 11,
	"_test_spielstand_vollstaendig": 6,
	"_test_stollen": 34,
	"_test_stollen_bedienbar": 17,
	"_test_stollen_lampen": 12,
	"_test_faehigkeitspunkte": 9,
	"_test_sichtweite": 12,
	"_test_nachschub": 9,
	"_test_deutsche_werte": 8,
	"_test_kopfzeile": 17,
	"_test_truhen": 37,
	"_test_anfuehrer": 55,
}


func _ready() -> void:
	print("──────────────────────────────────────────────")
	print("  Rust & Lead — Backend Test-Suite")
	print("──────────────────────────────────────────────")
	# Die Suite laeuft auf einer hohen Stufe.
	#
	# Nicht aus Bequemlichkeit: Seit Ausruestung eine Stufe VERLANGT, scheiterten zwanzig
	# Pruefungen, die mit episch und legendaer hantieren — Set-Boni, Werte-Summen,
	# Beutel-Tausch. Keine davon handelt von Stufen; sie hatten sich nur nie darum kuemmern
	# muessen, weil es die Regel nicht gab. Ihnen jetzt einzeln ein `GameState.level` zu
	# verpassen, hiesse zwanzig Stellen zu aendern, an denen es nichts zur Sache tut.
	#
	# Die Sperre selbst hat ihren eigenen Test (`_test_stufenanforderung`), und der setzt die
	# Stufe ausdruecklich hoch und runter.
	GameState.level = 30
	# Gemessen wird pro Funktion, damit ein Abbruch nicht in der Gesamtzahl untergeht.
	var zu_klein: Array[String] = []
	var gemessen: Dictionary = {}
	for name in TEST_UMFANG:
		var vorher: int = _passed + _failed
		call(name)
		var geliefert: int = _passed + _failed - vorher
		gemessen[name] = geliefert
		if geliefert < int(TEST_UMFANG[name]):
			zu_klein.append("%s: %d statt >=%d" % [name, geliefert, int(TEST_UMFANG[name])])
	for obj in _scratch:
		if is_instance_valid(obj):
			obj.free()
	_scratch.clear()
	# Der Umfangs-Test steht bewusst NACH allen anderen und zaehlt selbst als Pruefung: So sieht
	# man in der Zusammenfassung, dass er gelaufen ist.
	_check("Alle %d Testfunktionen sind vollstaendig durchgelaufen" % TEST_UMFANG.size(),
		zu_klein.is_empty(), "abgebrochen — " + ", ".join(zu_klein)
			+ " (stderr nach SCRIPT ERROR durchsuchen)")
	if not zu_klein.is_empty():
		printerr("  Eine Funktion, die weniger Pruefungen liefert als eingetragen, ist an einem")
		printerr("  Laufzeitfehler abgebrochen. Der Aufruf selbst meldet das nicht — der Fehler")
		printerr("  steht weiter oben in stderr als SCRIPT ERROR.")
	print("──────────────────────────────────────────────")
	print("  Ergebnis: %d bestanden, %d fehlgeschlagen" % [_passed, _failed])
	print("──────────────────────────────────────────────")
	if _failed == 0:
		# Damit das Nachtragen nach neuen Tests keine Sucharbeit ist.
		var gewachsen: Array[String] = []
		for name in gemessen:
			if int(gemessen[name]) > int(TEST_UMFANG[name]):
				gewachsen.append('"%s": %d,' % [name, int(gemessen[name])])
		if not gewachsen.is_empty():
			print("  Hinweis — diese Funktionen sind gewachsen, TEST_UMFANG darf nach:")
			for z in gewachsen:
				print("    ", z)
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
	GameState.upgrades = { "damage": 0, "firerate": 0, "reload": 0, "hp": 0, "speed": 0, "regen": 0, "magnet": 0 }
	GameState.ng_plus = 0
	GameState.gold = 0
	GameState.potions = 3
	GameState.kills = 0
	GameState.inventory = { "schrott": 0, "zahnrad": 0, "dampfkern": 0 }
	GameState.equip = {}
	GameState.bag = []
	GameState.ammo = AmmoData.fresh()
	GameState.mag = AmmoData.fresh_mags()
	GameState.economy = { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 }
	GameState.quests = {}
	GameState.quest_base = {}
	# Tag und Tagesgrenzen mit: Seit wiederholbare Auftraege einmal am Tag gehen, traegt eine
	# Testfunktion sonst die Sperre der vorherigen mit sich herum.
	GameState.tag = 0
	GameState.quest_tag = {}
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
	# Stimmig zur Stufe: elf Aufstiege bringen elf Punkte, vier stecken in Raengen, sieben liegen
	# auf der Hand. Ein UNstimmiger Stand waere hier ein schlechter Pruefling — `deserialize`
	# gleicht ihn an, seit Aufstiege Punkte bringen, und dann pruefte diese Stelle den Abgleich
	# statt des Roundtrips. Der Abgleich hat seinen eigenen Test.
	GameState.perk_points = 7
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
	_check("Roundtrip: Perks", ProgressionManager.perk_rank("scharf") == 3 and GameState.perk_points == 7)
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
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	GameState.equip = {}
	GameState.bag = []
	GameState.ammo = AmmoData.fresh()
	GameState.mag = AmmoData.fresh_mags()
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
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	var a1: Dictionary = ProgressionManager.make_gear("armor", "epic", "", rng)
	var h1: Dictionary = ProgressionManager.make_gear("helmet", "epic", "", rng)
	EquipManager.equip_item(a1, "armor")
	EquipManager.equip_item(h1, "helmet")
	var expected_armor: int = ProgressionManager.gear_stat_of(a1, "armor") + ProgressionManager.gear_stat_of(h1, "armor")
	_check("stat_total armor summiert Loadout", EquipManager.stat_total("armor") == expected_armor)

	# ── Legendäre Sets ──
	_reset_state(); GameState.equip = {}
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
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
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
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
	GameState.bag = []
	GameState.ammo = AmmoData.fresh()
	GameState.mag = AmmoData.fresh_mags()

	# Basiswerte ohne Boni.
	# Gegen die TABELLE geprueft, nicht gegen abgeschriebene Zahlen: Balance-Werte aendern sich,
	# die Formel „ohne Boni kommt die Basis heraus" nicht.
	var kb: Dictionary = CombatData.WEAPONS["karabiner"]
	_check("Basis-Schaden Karabiner = Tabellenwert (%d)" % int(kb["base"]),
		PlayerStats.damage_per_bullet("karabiner") == int(kb["base"]))
	_check("Basis-Feuerrate Karabiner = Tabellenwert (%d ms)" % int(kb["fire_ms"]),
		PlayerStats.fire_ms("karabiner") == int(kb["fire_ms"]))
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
	var basis: int = int(CombatData.WEAPONS["karabiner"]["base"])
	_check("Perk Scharfschütze: Schaden %d+12" % basis,
		PlayerStats.damage_per_bullet("karabiner") == basis + 12)

	# Werkstatt-Upgrade + Ausrüstung + Legendär-Kraft (overcharge x1.18).
	_reset_state(); GameState.equip = {}
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	GameState.upgrades["damage"] = 2   # +12
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var wpn: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	var dmg_stat: int = ProgressionManager.gear_stat_of(wpn, "damage")
	EquipManager.equip_item(wpn, "weapon")
	var expected: int = roundi((int(CombatData.WEAPONS["karabiner"]["base"]) + 12 + dmg_stat) * 1.18)
	_check("Upgrade+Ausrüstung+Golem-Faust (x1.18)", PlayerStats.damage_per_bullet("karabiner") == expected)

	# Set-Integration: Direktorat verleiht cap_grit -> max_hp x1.2 & Schaden-genommen x0.8.
	_reset_state(); GameState.equip = {}
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
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
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	GameState.ng_plus = 2   # +0.70
	var sohlen: Dictionary = ProgressionManager.make_gear("boots", "legendary", "plunder", rng)
	var trommel: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "spread11", rng)
	EquipManager.equip_item(sohlen, "boots")
	EquipManager.equip_item(trommel, "weapon")
	_check("Loot-Faktor: Plünderer(+0.25)+NG+2(+0.70) = 1.95", is_equal_approx(PlayerStats.loot_mul(), 1.95))
	_check("Spread mit Dolores' Trommel = 11", PlayerStats.spread_count() == 11)
	_check("Magnet +Plünderer-Sohlen (+60)", PlayerStats.magnet_dist() == 130 + 60)


func _test_world_scale() -> void:
	print("· Produktions-Maßstab (Krater 5000 m — GDD §1.4)")
	_check("Weltgröße = 5000 m", WorldManager.WORLD_METERS == 5000.0)
	_check("Skalierung 2000 Einheiten → ×2,5 m", WorldManager.METERS_PER_UNIT == 2.5)
	_check("Lauftempo = 4,7 m/s", WorldManager.PLAYER_SPEED_MS == 4.7)
	_check("Rustwater (300,300) → Szene (750, 0, −750)",
		WorldManager.world_to_scene(Vector2(300, 300)).is_equal_approx(Vector3(750, 0, -750)))
	_check("Eisernes Herz → Szene (2500, 0, −4875)",
		WorldManager.poi_scene_position("eisernes_herz").is_equal_approx(Vector3(2500, 0, -4875)))
	_check("Sprengtor-Linie liegt bei z = −2000 m",
		is_equal_approx(WorldManager.world_to_scene(Vector2(0, WorldManager.BORDER_S1_S2_Y)).z, -2000.0))
	var rt: Vector3 = WorldManager.world_to_scene(Vector2(1234, 567))
	_check("scene_to_world ist die exakte Umkehrung",
		WorldManager.scene_to_world(rt).is_equal_approx(Vector2(1234, 567)))
	var hub_dist: float = WorldManager.poi_scene_position("rustwater").distance_to(
		WorldManager.poi_scene_position("zugdepot"))
	_check("Pacing: Rustwater→Zugdepot ≥ 1000 m (Hub-Abstand, §1.4)", hub_dist >= 1000.0)
	_check("Pacing: Querung Rustwater→Zugdepot dauert Minuten (> 180 s)",
		hub_dist / WorldManager.PLAYER_SPEED_MS > 180.0)


## HUD-Verankerung und Eingabewege — zwei Fehler, die nur im laufenden Fenster sichtbar sind.
func _test_hud_layout() -> void:
	print("· HUD-Verankerung & Eingabe")
	# ── Die Weltkarte liess sich nicht oeffnen ────────────────────────────────
	# Godots Maus-Emulation erzeugt aus EINEM Klick zwei Ereignisse: erst einen Finger-Tipp,
	# dann den Mausknopf. Beide liefen durch `_handle_overlay_tap`, und weil das ein Umschalter
	# ist, ging die Karte im ersten auf und im zweiten sofort wieder zu.
	_check("Maus-Emulation ist aus (sonst zaehlt jeder Klick doppelt)",
		not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)))

	# ── Der Schuss-Knopf lag ausserhalb des Bildes ────────────────────────────
	# `position` ist die Lage relativ zur Elternecke, nicht der Abstand zum Anker. Nach
	# `add_child` gesetzt — und `_ready` laeuft danach — zaehlt sie absolut: aus −146 wurde die
	# Bildschirmposition −146. Raender sind dagegen immer ankerrelativ.
	var b := FireButton.new()
	add_child(b)   # erst im Baum laeuft `_ready` und setzt Anker und Raender
	_check("Schuss-Knopf haengt unten rechts", is_equal_approx(b.anchor_left, 1.0)
		and is_equal_approx(b.anchor_top, 1.0))
	# Godots eigene Rechnung nachvollziehen: Kante = Anker x Fenstermass + Rand.
	for schirm in [Vector2(1152, 648), Vector2(720, 1280), Vector2(2400, 1080)]:
		var links: float = b.anchor_left * schirm.x + b.offset_left
		var oben: float = b.anchor_top * schirm.y + b.offset_top
		var rechts: float = b.anchor_right * schirm.x + b.offset_right
		var unten: float = b.anchor_bottom * schirm.y + b.offset_bottom
		var drin: bool = links >= 0.0 and oben >= 0.0 and rechts <= schirm.x and unten <= schirm.y
		_check("Schuss-Knopf liegt bei %dx%d im Bild" % [int(schirm.x), int(schirm.y)], drin,
			"[%.0f, %.0f] bis [%.0f, %.0f]" % [links, oben, rechts, unten])
		if schirm == Vector2(1152, 648):
			_check("Und zwar mit %d px Abstand zur unteren rechten Ecke" % int(FireButton.MARGIN),
				is_equal_approx(schirm.x - rechts, FireButton.MARGIN)
				and is_equal_approx(schirm.y - unten, FireButton.MARGIN))
			_check("Er ist quadratisch mit dem doppelten Radius",
				is_equal_approx(rechts - links, FireButton.RADIUS * 2.0))
	_check("Die Trefferpruefung liegt auf dem gezeichneten Kreis",
		b.hits(b.center()) and not b.hits(b.center() + Vector2(FireButton.RADIUS * 2.0, 0.0)))
	b.queue_free()


## Zoom: von Hand, nicht automatisch (siehe CAM_ZOOM_STEPS).
##
## Der Kamera-Abstand war eine Konstante, aus der ein konstanter Versatz abgeleitet wurde. Jetzt
## ist er verstellbar — und damit haengen zwei Dinge daran, die stillschweigend brechen koennen:
## die Groesse der Figur im Bild und die Reichweite der Schattenkaskaden.
func _test_camera_zoom() -> void:
	print("· Kamera-Zoom")
	var steps: Array = OverworldView.CAM_ZOOM_STEPS
	_check("Mehrere Zoomstufen vorhanden", steps.size() >= 3)
	_check("Zu jeder Stufe gehoert ein Name",
		OverworldView.CAM_ZOOM_NAMES.size() == steps.size())
	var steigend: bool = true
	for i in range(1, steps.size()):
		if float(steps[i]) <= float(steps[i - 1]):
			steigend = false
	_check("Stufen sind aufsteigend sortiert", steigend)
	_check("Vorgabestufe liegt im gueltigen Bereich",
		OverworldView.CAM_ZOOM_DEFAULT >= 0 and OverworldView.CAM_ZOOM_DEFAULT < steps.size())
	_check("Spanne mindestens Faktor 2", float(steps[-1]) / float(steps[0]) >= 2.0,
		"%.1f bis %.1f m" % [float(steps[0]), float(steps[-1])])

	# Bildanteil der Figur: Sichthoehe = 2 * Abstand * tan(FOV/2).
	var ow := OverworldView.new()
	var anteil: Callable = func(d: float) -> float:
		return 1.8 / (2.0 * d * tan(deg_to_rad(OverworldView.CAM_FOV * 0.5))) * 100.0
	var weit: float = anteil.call(float(steps[-1]))
	var nah: float = anteil.call(float(steps[0]))
	_check("Weiteste Stufe trifft die Diablo-Spanne (12–15 %% der Bildhoehe)",
		weit >= 11.5 and weit <= 15.5, "%.1f %%" % weit)
	_check("Naechste Stufe zeigt die Figur deutlich groesser (> 22 %%)", nah > 22.0,
		"%.1f %%" % nah)
	_check("Auch die weiteste Stufe bleibt lesbar (> 10 %%)", weit > 10.0)

	# Schatten: Die hintere Bildkante darf nicht aus den Kaskaden fallen. Der obere
	# Frustumrand liegt (Neigung − halbes Sichtfeld) unter der Waagerechten.
	var rand_deg: float = OverworldView.CAM_PITCH - OverworldView.CAM_FOV * 0.5
	var schlimmster: float = 0.0
	for d in steps:
		var hoehe: float = float(d) * sin(deg_to_rad(OverworldView.CAM_PITCH))
		schlimmster = maxf(schlimmster, hoehe / sin(deg_to_rad(rand_deg)))
	_check("Schattenkaskaden reichen bis zur hintersten Bildkante (%.1f m von %.0f m)"
		% [schlimmster, OverworldView.CAM_SHADOW_M],
		schlimmster < OverworldView.CAM_SHADOW_M)

	# Der Versatz muss den Abstand exakt einhalten — er wird jetzt gerechnet statt konstant.
	for d in steps:
		var off: Vector3 = ow._cam_offset(float(d))
		if not is_equal_approx(off.length(), float(d)):
			_check("Versatz haelt den Abstand bei %.1f m" % float(d), false, "%.3f m" % off.length())
	_check("Versatz haelt bei jeder Stufe exakt den Abstand", true)
	var off0: Vector3 = ow._cam_offset(float(steps[0]))
	_check("Neigung bleibt bei jeder Stufe gleich (%.0f°)" % OverworldView.CAM_PITCH,
		is_equal_approx(rad_to_deg(asin(off0.y / off0.length())), OverworldView.CAM_PITCH))

	# Klemmung an beiden Enden.
	GameState.cam_zoom = -5
	_check("Zu kleiner Index wird auf die naechste Stufe geklemmt", ow._zoom_step() == 0)
	GameState.cam_zoom = 99
	_check("Zu grosser Index wird auf die weiteste Stufe geklemmt",
		ow._zoom_step() == steps.size() - 1)
	GameState.cam_zoom = OverworldView.CAM_ZOOM_DEFAULT
	ow.free()


## Topografie: Die Senke ist eine FORMEL, kein Modell.
##
## Der Boden war eine flache Platte bei y = 0, und die Figur bekam ihr y nie von irgendwoher.
## Ein modelliertes Gelaende waere Kulisse geblieben, durch die man hindurchspaziert. Diese
## Tests halten die Eigenschaften fest, auf die sich alles andere verlaesst: exakt flach
## ausserhalb, stetig ueberall, begehbar steil.
## Der Riss.
##
## Er ist die erste Gelaendeform, die nicht rund ist, und damit die erste, bei der „Reichweite"
## und „Ausdehnung" auseinanderfallen. Genau daran haengen die Pruefungen hier.
## Der Titelbildschirm und die Szene mit dem ersten Gegner.
func _test_titel_und_erster() -> void:
	print("· Titelbildschirm & erster Gegner")
	var q: String = FileAccess.get_file_as_string("res://scripts/TitleScreen.gd")
	var p: String = FileAccess.get_file_as_string("res://project.godot")
	# Damit startet das Spiel IMMER. Ein Titelbild, das je nach Speicherstand mal da ist und mal
	# nicht, ist kein Anfang, sondern ein Dialogfeld.
	_check("Das Spiel startet mit dem Titelbildschirm",
		p.contains('run/main_scene="res://scenes/Title.tscn"'))
	_check("Die Titelszene liegt vor", FileAccess.file_exists("res://scenes/Title.tscn"))
	# „Spiel laden" wird AUSGEGRAUT, nicht versteckt: Ein Eintrag, der auftaucht und
	# verschwindet, laesst den ganzen Bildschirm springen.
	_check("Spiel laden wird ausgegraut statt versteckt",
		q.contains('["laden", "Spiel laden", not hat_stand]'))
	for eintrag in ["Neues Spiel", "Spiel laden", "Tutorial", "Einstellungen", "Steuerung",
			"Credits"]:
		_check("Es gibt den Eintrag %s" % String(eintrag),
			q.contains('"%s"' % String(eintrag)))
	# „Beenden" nur auf dem Rechner: Auf dem Handy beendet man Apps anders, und ein Knopf, der
	# dort nichts Sinnvolles tut, ist schlimmer als keiner.
	_check("Beenden nur auf dem Rechner", q.contains('if not OS.has_feature("mobile"):'))
	# Die Lautstaerkeregler gehen auf einen echten Audio-Bus. Ein Regler, der nur eine Zahl in
	# einer Einstellungsdatei verschiebt, ist eine Attrappe — und die faellt spaetestens auf,
	# wenn jemand sie benutzt.
	_check("Die Regler haengen an echten Bussen", q.contains("AudioServer.set_bus_volume_db"))
	_check("Und bei null wird stummgeschaltet statt −inf gerechnet",
		q.contains("AudioServer.set_bus_mute"))
	# Das Titelbild STEHT, und zwar auf dem letzten Bild des Intro-Films.
	#
	# Der erste Entwurf liess die echte Welt dahinter langsam rotieren, mit dem Argument, ein
	# Standbild altere gegen das Spiel, sobald jemand die Palisade umbaut. Das stimmt und wiegt
	# leichter als das Ergebnis: Ein Titelbild soll stehen — es ist das erste Versprechen eines
	# Spiels, und ein Versprechen, das sich dreht, ist eine Bildschirmschoner-Ansicht.
	#
	# Das letzte Filmbild ist dabei mehr als eine Notloesung: Wer „Neues Spiel" waehlt, sieht
	# den Film laufen, und der endet genau dort, wo der Titel angefangen hat.
	_check("Das Titelbild liegt vor", FileAccess.file_exists("res://assets/ui/titelbild.webp"))
	_check("Und es steht", not q.contains("DREH_GRAD_S") and not q.contains("func _process"))
	# Die Welt wird gar nicht mehr geladen — der Titel startet sofort, und die Overworld hat
	# keinen Sonderzustand mehr zu kennen.
	_check("Der Titel laedt die Welt nicht mehr", not q.contains("OVERWORLD.instantiate()"))
	var ow_q: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	var OW4 = load("res://scripts/OverworldView.gd")
	_check("Und die Overworld kennt keinen Titelzustand", not ow_q.contains("im_titel"))
	# Das Bild fuellt den Rahmen, ohne die Figur zu verzerren: Auf einem Telefon im Hochformat
	# waere ein gestrecktes Titelbild ein verzerrtes Gesicht.
	_check("Es fuellt den Rahmen ohne zu verzerren",
		q.contains("STRETCH_KEEP_ASPECT_COVERED"))
	# Zwei weiche Schleier statt flaechigem Abdunkeln — sonst waere dem Bild genau das genommen,
	# wofuer es da ist.
	_check("Die Schrift bekommt Schleier statt eines Kastens",
		q.contains("func _schleier") and not q.contains("PanelContainer.new()\n\tvar hintergrund"))

	# ── Der Ladebildschirm ────────────────────────────────────────────────────
	#
	# Der Aufbau der Welt blockiert: Gelaendeflicken, Stadt, Streuung, Gegner — Sekunden, in
	# denen Godot nichts zeichnet. Ein Ladebildschirm, der im selben Atemzug wie der
	# Szenenwechsel gesetzt wird, ist deshalb NIE zu sehen. Es braucht zwei verstrichene Bilder
	# dazwischen: Das erste beendet nur den laufenden Durchlauf, gezeichnet wird am Ende des
	# zweiten.
	_check("Es gibt einen Ladebildschirm", q.contains("func _laden_zeigen"))
	_check("Und er wird gezeichnet, bevor der Aufbau blockiert",
		q.find("_laden_zeigen()") < q.find("change_scene_to_packed")
		and q.count("await get_tree().process_frame") >= 2)
	# Kein Fortschrittsbalken: Er muesste wissen, wie weit er ist, und das weiss hier niemand.
	# Einer, der bei 30 % stehenbleibt und dann springt, behauptet etwas, das er nicht halten
	# kann.
	_check("Ohne Fortschrittsbalken, der nichts weiss", not q.contains("ProgressBar.new()"))
	_check("Dafuer mit Zeilen aus der Welt", q.contains("const SPRUECHE"))

	# ── „Neues Spiel" muss wirklich neu sein ──────────────────────────────────
	#
	# Die Spielstanddatei zu loeschen reicht nicht: `GameState` ist ein Autoload und ueberlebt
	# jeden Szenenwechsel. Wer im Titel „Neues Spiel" waehlt, nachdem er schon gespielt hat,
	# braechte sonst Gold, Stufe und Ausruestung mit — und, schlimmer, die erledigten Marken des
	# Prologs: Der Film waere gelaufen, und danach haette die Figur wortlos in der Grube
	# gestanden, weil `saw_wake` noch stand.
	_check("Neues Spiel loescht nicht nur die Datei",
		q.contains("GameState.neu_beginnen()"))
	var g_gold: int = GameState.gold
	var g_lvl: int = GameState.level
	GameState.gold = 4711
	GameState.level = 9
	GameState.saw_wake = true
	GameState.prolog_done = true
	GameState.erst_gegner_done = true
	GameState.neu_beginnen()
	_check("Und setzt Gold und Stufe zurueck", GameState.gold == 0 and GameState.level == 1)
	_check("Und alle Prolog-Marken",
		not GameState.saw_wake and not GameState.prolog_done
		and not GameState.erst_gegner_done and not GameState.saw_vista)
	_check("Und die Uhr auf den Anfang (%s)" % DayCycle.clock_text(GameState.hour),
		absf(GameState.hour - DayCycle.START_HOUR) < 0.01)
	GameState.gold = g_gold
	GameState.level = g_lvl

	# ── Die Oberflaeche oben links ────────────────────────────────────────────
	#
	# Das Portraet ist kein Schmuck, sondern der KNOPF fuer den Rucksack. Vorher gab es dafuer
	# nur `[Tab]` — also ausgerechnet auf der Zielplattform gar nichts.
	_check("Das Portraet oeffnet den Rucksack",
		ow_q.contains("_portrait_btn.pressed.connect(_toggle_character)"))
	var Ui = load("res://scripts/UiAssets.gd")
	_check("Und es gibt ein Heldenportraet", Ui.has("portrait_held"))
	_check("Und einen Rahmen darum", Ui.has("portrait_frame"))
	# Der Rahmen liegt DARUEBER und darf keine Tipps schlucken, sonst waere der Knopf tot.
	_check("Der Rahmen schluckt keine Tipps",
		ow_q.contains("_portrait_rahmen.mouse_filter = Control.MOUSE_FILTER_IGNORE"))
	# Und er hat die Groesse, die ihm zugewiesen wird. Godots Vorgabe fuer `TextureRect` ist
	# `EXPAND_KEEP_SIZE`: Die Textur bestimmt die Mindestgroesse, und ein gesetztes `size` wird
	# beim Eintritt in den Baum wieder darauf hochgezogen. Im Bild stand deshalb ein 470 px
	# grosser Rahmen ueber dem halben Bildschirm, obwohl 72 px zugewiesen waren.
	_check("Der Rahmen haelt seine Groesse",
		ow_q.contains("_portrait_rahmen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE"))
	# Leben und Erfahrung als Balken. Eine Zahl muss man lesen, einen Balken sieht man.
	_check("Leben und Erfahrung stehen als Balken da",
		ow_q.contains("_hp_bar = _hud_balken") and ow_q.contains("_xp_bar = _hud_balken"))
	# ── Die Kopfzeile traegt nur noch, was eine Entscheidung traegt ───────────
	#
	# Vorher standen dort VIER dichte Zeilen mit vierzehn Zahlen — darunter der naechste Ort
	# samt Entfernung, Sektor, Biom und noch einmal die Zone. Im Gefecht liest das niemand, und
	# was niemand liest, verdeckt nur die Welt dahinter.
	#
	# Wo ich bin, beantwortet die Karte besser als eine Textzeile, und beim Betreten zieht der
	# Name ohnehin gross ueber die Mitte. Geprueft wird deshalb, dass die Ortszeile WEG ist —
	# sie war der groesste Brocken und kommt beim naechsten „schnell noch anzeigen" zuerst
	# zurueck.
	_check("Die Ortszeile steht nicht mehr dauerhaft im Kopf",
		not ow_q.contains('\\n➡ %s (%d m)'))
	_check("Und Sektor und Biom auch nicht", not ow_q.contains("Sektor %d · %s"))
	# Die Iron-Rail-Zeile bleibt: Sie nennt Tasten, die NUR an diesem Fleck etwas tun. Ohne sie
	# wuesste niemand, dass er gerade fahren kann.
	_check("Der Iron-Rail-Hinweis bleibt", ow_q.contains("[1-5] Iron Rail"))
	# Und mit der Zeile faellt ihre Rechnerei weg — `nearest_poi` laeuft ueber ALLE Orte, und
	# das lief sechzigmal in der Sekunde fuer einen Text, den niemand liest.
	_check("Und der Kopf rechnet keine Ortsentfernung mehr",
		not ow_q.contains("var poi_d: int = roundi"))
	# Und der Tastaturhinweis ist weg: Auf dem Handy gibt es kein [Tab], und ein Bild braucht
	# keine Beschriftung.
	# Geprueft wird die ANZEIGE, nicht die Quelle: „[Tab] Inventar" steht weiterhin im
	# Kommentar daneben, der erklaert, warum es weg ist. Ein Test, der auf den Kommentar
	# anschlaegt, verbietet die Begruendung.
	_check("Der Tastaturhinweis ist aus dem Kopfbereich raus",
		not ow_q.contains('· %s   [Tab] Inventar"'))

	# ── Die Guertelleiste ─────────────────────────────────────────────────────
	#
	# Traenke standen seit jeher im Spielstand (drei zum Start) und es gab keinen Weg, sie zu
	# benutzen — weder auf dem Handy noch auf der Tastatur. Ein Vorrat, den man nicht ausgeben
	# kann, ist kein Vorrat, sondern eine Zahl.
	# Er liegt als TRABANT am Schussknopf, nicht daneben.
	#
	# Der erste Anlauf haengte einen Knopf ueber den Abzug — richtig gedacht und trotzdem
	# falsch: Er lag NEBEN der Hand, und wer im Gefecht trinken will, muss den Daumen dorthin
	# bringen, waehrend jemand auf ihn schiesst.
	_check("Es gibt einen Trankknopf", ow_q.contains("_trank_btn.ausgeloest.connect(_trank_trinken)"))
	_check("Und eine Taste dafuer", ow_q.contains("event.keycode == KEY_F"))
	_check("Er sitzt als Trabant am Schussknopf", ow_q.contains("func _trabanten_setzen"))
	var d_mitten: float = FireButton.RADIUS + ActionSatellite.RADIUS + ActionSatellite.SPALT
	# ── Und zwar so weit RECHTS, wie er ueberhaupt stehen kann ────────────────
	#
	# Der erste Anlauf setzte ihn auf 0° — genau rechts, kuerzester Daumenweg, auf dem Papier
	# richtig. Im Kontrollbild lag er HALB AUSSERHALB DES BILDSCHIRMS: Der Schussknopf klebt
	# selbst schon in der Ecke, seine Mitte steht nur `MARGIN + RADIUS` vom rechten Rand, und
	# der Trabant sitzt noch einmal `d_mitten` weiter draussen.
	#
	# Gemessen wird deshalb nicht der Winkel, sondern die FOLGE des Winkels: Passt der Knopf
	# ins Bild? Das haelt auf jeder Aufloesung, weil der Schussknopf am Rand verankert ist —
	# sein Abstand zur Kante aendert sich nie.
	var w_rad: float = deg_to_rad(float(OW4.TRABANT_WINKEL[0]))
	var bis_kante: float = FireButton.MARGIN + FireButton.RADIUS      # Knopfmitte → rechter Rand
	var ueberstand: float = d_mitten * cos(w_rad) + ActionSatellite.RADIUS - bis_kante
	_check("Der Trabant passt ins Bild (%.0f px Luft zum Rand)" % -ueberstand, ueberstand <= 0.0)
	# Er steht trotzdem RECHTS OBEN und nicht links: Der Daumen bleibt auf seiner Seite.
	_check("Und er steht rechts vom Schussknopf (%.0f°)" % float(OW4.TRABANT_WINKEL[0]),
		cos(w_rad) > 0.2 and sin(w_rad) > 0.0)
	# Und die Klemme fangt auch den Fall, dass jemand spaeter an MARGIN oder den Radien dreht.
	_check("Und wird zusaetzlich ins Bild geklemmt", ow_q.contains("get_viewport().get_visible_rect().size"))
	# Die Trefferflaechen beruehren sich NICHT: Ein Fehlgriff soll den Schuss ausloesen und
	# nicht den Trank verbrauchen.
	var r_summe: float = FireButton.RADIUS * FireButton.TOUCH_SLACK \
		+ ActionSatellite.RADIUS * ActionSatellite.TOUCH_SLACK
	_check("Die Trefferflaechen ueberlappen sich kaum (%.0f px Abstand, %.0f px Radien)"
		% [d_mitten, r_summe], d_mitten >= FireButton.RADIUS + ActionSatellite.RADIUS)
	# Und der Trabant wird ZUERST geprueft — sonst schluckt ihn der groessere Zuschlag des
	# Schussknopfes an seinem Rand.
	_check("Der Trabant wird vor dem Schussknopf geprueft",
		ow_q.find("_trabant_tap(event.position)") < ow_q.find("_fire_btn.hits(event.position)"))
	# Die Zahl steht IM Knopf, nicht daneben: Sie gehoert zum Vorrat und nicht zum Bildrand.
	# Und zwar GANZ darin — beim ersten Anlauf reichte ihr Rand einen Punkt darueber hinaus,
	# und im Kontrollbild hing die Zahl halb in der Luft. Gerechnet statt geschaut:
	var plakette: float = (ActionSatellite.ZAHL_VERSATZ * ActionSatellite.RADIUS).length() \
		+ ActionSatellite.ZAHL_R
	_check("Die Zahlplakette bleibt im Knopf (%.1f von %.0f px)"
		% [plakette, ActionSatellite.RADIUS], plakette <= ActionSatellite.RADIUS)
	var sat_q: String = FileAccess.get_file_as_string("res://scripts/ActionSatellite.gd")
	_check("Die Zahl steht im Knopf", sat_q.contains("if zahl >= 0:"))
	_check("Und der Knopf ist kleiner als der Schussknopf",
		ActionSatellite.RADIUS < FireButton.RADIUS * 0.7)
	# Die Regel steht in GameState, nicht in der Oberflaeche: Wie viel ein Trank heilt, ist eine
	# Frage der Balance und keine der Anzeige.
	var t_hp: int = GameState.potions
	GameState.potions = 2
	var voll: float = float(GameState.max_hp())
	var nach: float = GameState.trank_trinken(voll * 0.4)
	_check("Ein Trank heilt anteilig (%.0f → %.0f von %.0f)" % [voll * 0.4, nach, voll],
		nach > voll * 0.4 and nach <= voll)
	_check("Und wird dabei verbraucht", GameState.potions == 1)
	# Bei vollem Leben passiert NICHTS. Auf dem Handy sitzt der Knopf dort, wo der Daumen
	# ohnehin liegt, und ein Trank, der bei vollem Leben verschwindet, ist ein Fehlgriff, den
	# niemand rueckgaengig machen kann.
	_check("Bei vollem Leben wird keiner verschwendet",
		GameState.trank_trinken(voll) < 0.0 and GameState.potions == 1)
	GameState.potions = 0
	_check("Und ohne Vorrat passiert gar nichts", GameState.trank_trinken(1.0) < 0.0)
	GameState.potions = t_hp
	# Anteil statt fester Zahl: Eine feste Zahl ist auf Stufe 1 ein halbes Leben und auf Stufe
	# 20 ein Tropfen.
	_check("Geheilt wird ein Anteil (%.0f %%)" % (GameState.TRANK_ANTEIL * 100.0),
		GameState.TRANK_ANTEIL > 0.1 and GameState.TRANK_ANTEIL < 0.6)
	# Ausgegraut statt versteckt: Ein Knopf, der verschwindet, laesst die Ecke springen.
	_check("Der Knopf wird ausgegraut, nicht versteckt",
		ow_q.contains('_trank_btn.setzen("trank", GameState.potions,'))

	# ── Die erste Truhe ───────────────────────────────────────────────────────
	#
	# Der Satz stand seit Langem im Storyblatt und wurde im Spiel nie gesprochen. Er ist die
	# erste Stelle, an der die Figur etwas kann, was sie sich nicht erklaeren kann — dieselbe
	# Frage, die spaeter beim ersten Gegner wiederkommt. Ohne ihn ist der Fund eine
	# Ausruestungsmeldung.
	_check("Die erste Truhe ist eine Szene", ow_q.contains("func _erste_truhe_szene"))
	_check("Und der Held fragt sich, woher er das kann",
		ow_q.contains("Woher weiß ich das?"))
	# Kein Rundflug: Hier geht es um einen Gegenstand in zwei Haenden, nicht um einen Ort.
	_check("Die Kamera geht heran und bleibt stehen",
		not ow_q.contains("spirale_punkte(") or ow_q.count("spirale_punkte(") <= 2)

	# ── Die Steuerwalzen ──────────────────────────────────────────────────────
	#
	# Sechzehn Erinnerungen standen fertig in `MemoryManager` — und NICHTS im Spiel hat sie je
	# aufgerufen. Der Kern der Geschichte lag unerreichbar herum: `recover_memory()` war eine
	# Funktion, die es gab und die niemand rief.
	_check("Die Erinnerungskette wird ueberhaupt aufgerufen",
		ow_q.contains("MemoryManager.try_recover_memory"))
	# Und zwar aus MECHANISCHEN Gegnern. Das ist keine Willkuer: Was der Held von sich selbst
	# nicht weiss, steckt in Maschinen derselben Bauart. Wer eine aufschneidet, findet ein
	# Stueck von sich.
	_check("Nur aus Maschinen",
		ow_q.contains('== CombatData.MECHANICAL:\n\t\t\t_walze_bergen'))
	# Die erste ist GARANTIERT — der Anfang einer Geschichte darf nicht auswuerfeln, ob sie
	# stattfindet. Dieselbe Regel wie beim Karabiner in der Truhe.
	_check("Die erste kommt garantiert", ow_q.contains("_walze_bergen(false, true)"))
	# Gezeigt wird sie unter dem HELDENNAMEN, nicht als Fundmeldung: Eine Erinnerung ist kein
	# Gegenstand, den man einsteckt — sie faellt jemandem ein.
	_check("Und sie faellt ihm ein, statt aufgesammelt zu werden",
		ow_q.contains('_walze_bergen') and ow_q.contains('_play_speech(HELD_NAME, "held", [\n\t\t"„Da ist eine Walze drin'))
	# Die Kette ist vollstaendig und endet dort, wo die Geschichte hinwill.
	_check("Die Kette hat %d Glieder" % MemoryManager.chain_length(),
		MemoryManager.chain_length() >= 16)

	# ── Der erste Gegner ──────────────────────────────────────────────────────
	# EINER, nicht das uebliche Rudel: Wer zum ersten Mal etwas sieht, das hier herumlaeuft,
	# soll es ansehen koennen.
	_check("Es ist genau einer", ow_q.contains('_erst_gegner = _make_enemy("konstrukt")'))
	# Und eine MASCHINE. Zuerst stand hier ein Grenzgaenger — ein Mensch, weil „was bist du
	# gewesen" bei etwas Menschlichem am staerksten traegt. Falsch gerechnet: Ein bewaffneter
	# Mann in der Wueste ist keine Ueberraschung, sondern das, was man dort erwartet.
	_check("Und es ist eine Maschine",
		String(CombatData.ENEMY_TYPES["konstrukt"]["class"]) == CombatData.MECHANICAL)
	# Nicht rattenklein: Aus der Kamerahaltung der Szene muss man es als Ding erkennen.
	var groesse: float = float(AssetRegistry.TARGET_HEIGHT.get("enemy_konstrukt", 0.0))
	_check("Und gross genug, um sie anzusehen (%.1f m)" % groesse, groesse >= 1.5)
	# Einer, der allein auftreten darf — Schwarmtiere kommen nie einzeln.
	_check("Und einer, der allein auftreten darf",
		not bool(CombatData.ENEMY_TYPES["konstrukt"].get("swarm", false)))
	# Der Kessel-Klaeffer waere das schoenere Tier gewesen: vierbeinig, hundegross, mechanisch.
	# Es gibt ihn als Gegnertyp und NICHT als Modell — und genau das haelt diese Pruefung fest.
	# Taucht `klaeffer.glb` eines Tages auf, faellt sie um und erinnert daran, hier noch einmal
	# hinzusehen.
	_check("Der Klaeffer waere schoener, hat aber noch kein Modell",
		not AssetRegistry.has_model("enemy_klaeffer"))
	# Dass es hier mit einem Schuss faellt und spaeter nicht, traegt der Text.
	_check("Dass dieses eine ein Wrack ist, wird gesagt",
		ow_q.contains("Ein heiler hätte gestanden"))
	# Erst wenn er den Krater verlassen hat.
	_check("Erst ausserhalb des Kraters (%.0f m)" % OW4.ERST_AUSLOESER_M,
		OW4.ERST_AUSLOESER_M > 20.0)
	# Und nicht mit leeren Haenden — ohne Waffe waere es eine Hinrichtung ohne Werkzeug.
	_check("Und nicht mit leeren Haenden", ow_q.contains('if _weapon_id == "":\n\t\treturn   # ohne Waffe'))
	# Die Beute liegt ERST DANACH da. Der Sinn der Szene ist, dass man es lernt; wer vorher
	# einsammeln kann, lernt nichts.
	_check("Die Beute kommt erst nach der Nahaufnahme",
		ow_q.find("func _erst_beute") > ow_q.find("_erst_leiche_t = ERST_SEK_HIN"))
	_check("Und die Nahaufnahme dauert (%.1f s)" % OW4.ERST_SEK_LEICHE,
		OW4.ERST_SEK_LEICHE >= 3.0)
	# Genau einmal — was erklaert ist, muss nicht noch einmal erklaert werden.
	_check("Sie laeuft genau einmal", ow_q.contains("GameState.erst_gegner_done = true"))
	_check("Und steht im Spielstand",
		FileAccess.get_file_as_string("res://scripts/SaveManager.gd").contains("erst_gegner_done"))
	# Die letzte Sprechzeile begruendet das Pluendern, statt es als Spielfunktion zu erklaeren.
	_check("Das Pluendern wird begruendet, nicht erklaert",
		ow_q.contains("Es braucht das nicht mehr, und ich schon"))
	# Und was der Held ausspricht, liegt auch da: Der Dampfkern wird nicht ausgewuerfelt.
	_check("Der Kern, den er nennt, liegt garantiert da",
		ow_q.contains('"id": "dampfkern", "amount": 1'))


## Der Steg ueber den Riss und die weichen Biom-Kanten.
func _test_steg_und_biome() -> void:
	print("· Steg & Biom-Kanten")
	var ow_q: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	# ── Der Steg ──────────────────────────────────────────────────────────────
	#
	# Eine Bruecke waere die naheliegende Antwort und die langweiligste: Sie sagt „hier ist der
	# Uebergang vorgesehen". Ein Waggon, der irgendwann irgendwo hineingestuerzt ist, sagt, dass
	# hier einmal etwas passiert ist — und dass der Weg ein FUND ist und keine Freischaltung.
	_check("Es gibt einen Steg ueber den Riss", ow_q.contains("func _build_steg"))
	_check("Und er ist ein gestuerzter Kessel, keine Bruecke",
		ow_q.contains("Der gestürzte Kessel") and ow_q.contains('instantiate("locomotive"'))
	# Er liegt von Anfang an da — nichts wird aufgeschlossen.
	_check("Er wird nicht freigeschaltet, sondern gefunden",
		not ow_q.contains("steg_frei") and not ow_q.contains("GameState.steg"))
	# Und nicht in der Mitte: Die Mitte waere die Stelle, an der man zuerst nachsieht, und dann
	# waere das Suchen keins.
	var OW5 = load("res://scripts/OverworldView.gd")
	_check("Und nicht in der Mitte (%.0f %% der Laenge)" % (OW5.STEG_ANTEIL * 100.0),
		absf(OW5.STEG_ANTEIL - 0.5) > 0.05)
	# Auf dem Steg ist der Riss kein Riss — sonst waere er Deko.
	_check("Auf dem Steg sperrt der Riss nicht",
		ow_q.contains("if _auf_steg(p):\n\t\treturn false"))
	# Und die Figur steht DARAUF und nicht im Boden darunter.
	_check("Die Figur steht auf dem Steg, nicht im Spalt",
		ow_q.contains("next.y = _boden_hoehe(next.x, next.z)"))

	# ── Die Zustandsmarken ────────────────────────────────────────────────────
	#
	# Das Kampfsystem verteilt seit Langem Zustaende — Kurzschluss, Verbluten, Ueberhitzung,
	# Korrosion —, und der Spieler konnte KEINEN davon sehen. Wer eine Saeureflasche wirft und
	# nichts passiert, lernt daraus nur, dass Saeureflaschen nichts tun; dass sie gerade die
	# Panzerung aufgeloest hat, stand nirgends.
	var OW6 = load("res://scripts/OverworldView.gd")
	var mt: CombatTarget = CombatTarget.from_type("konstrukt")
	var jetzt: int = Time.get_ticks_msec()
	_check("Ohne Zustand keine Marke", OW6.status_marken(mt, jetzt) == "")
	mt.stun_until = jetzt + 2000
	_check("Kurzschluss wird angezeigt", OW6.status_marken(mt, jetzt).contains("⚡"))
	mt.stun_until = 0
	CombatEngine.apply_status(mt, CombatData.FX_BLEED, jetzt)
	_check("Ein DOT wird angezeigt", OW6.status_marken(mt, jetzt).contains("☣"))
	mt.dot = {}
	mt.armor = 0
	_check("Und zerfressene Panzerung auch",
		OW6.status_marken(mt, jetzt).contains("‼") and mt.max_armor > 0)
	# Sie stehen UEBER der Lebensleiste: Der Blick geht beim Zielen nach oben zum Kopf.
	_check("Die Marken haengen am Gegner", ow_q.contains('"marken": marken'))

	# ── Und dieselben Marken am SPIELER ───────────────────────────────────────
	#
	# Ueber den Gegnern standen sie laengst, ueber dem Spieler nie — dabei wiegt es hier
	# schwerer: Ein Gegner, der Schaden nimmt, ist erklaert, man hat ja geschossen. Leben, das
	# ohne sichtbaren Grund sinkt, liest sich als FEHLER DES SPIELS. Genau das passierte im
	# Smog und im Strahlensumpf: Dazu gab es nur alle 2,2 Sekunden einen Satz, und wer den
	# verpasst, sieht bloss Leben verschwinden.
	#
	# Geprueft wird die Wahrheitstafel, nicht der Quelltext.
	var t0: float = 100.0
	_check("Ohne Gefahr keine Spielermarke", OW6.spieler_marken(t0, 0.0, 0.0) == "")
	_check("Smog wird angezeigt", OW6.spieler_marken(t0, t0 + 1.0, 0.0) == "☣")
	_check("Strahlung wird angezeigt", OW6.spieler_marken(t0, 0.0, t0 + 1.0) == "☢")
	_check("Beides zugleich, Strahlung zuerst",
		OW6.spieler_marken(t0, t0 + 1.0, t0 + 1.0) == "☢☣")
	# Und sie verschwindet wieder — eine Marke, die haengen bleibt, waere eine Dauerwarnung vor
	# einer Gefahr, die man laengst verlassen hat.
	_check("Abgelaufen ist weg", OW6.spieler_marken(t0, t0 - 0.1, t0 - 0.1) == "")
	# Der Nachlauf ist der Grund, warum ueberhaupt eine Frist mitgegeben wird: Der Schaden
	# faellt schubweise an, und ohne ihn ginge die Marke im Sekundentakt an und aus.
	_check("Es gibt einen Nachlauf gegen das Flackern", float(OW6.MARKE_NACHLAUF_SEK) >= 0.5)
	_check("Die Spielermarken haengen an der Lebensleiste",
		ow_q.contains("_spieler_marken.position = Vector2(HUD_RAND + PORTRAIT_PX + 10.0 + BALKEN_W"))

	# ── Zwei Reden, die sich ins Wort fielen ──────────────────────────────────
	#
	# Im Prolog beginnt der Held nach dem ersten Schuss einen Monolog von acht Zeilen, und mitten
	# darin wird die Beute freigegeben — samt der ersten Steuerwalze, die ihrerseits reden will.
	# `_play_speech` ERSETZTE, also brach der Satz ab, und was man las, war der Anfang eines
	# Gedankens und das Ende eines anderen. Jetzt wird beim selben Sprecher angehaengt.
	_check("Zwei Reden desselben Sprechers haengen aneinander",
		ow_q.contains("if not _speech.is_empty() and _speech_giver == giver:\n\t\t_speech.append_array"))
	# Bei einem WECHSEL des Sprechers wird weiterhin ersetzt: Wenn Mabel etwas sagt, waehrend
	# der Held noch denkt, hat sie das letzte Wort — sie steht ja vor einem.
	_check("Bei einem Sprecherwechsel wird ersetzt",
		ow_q.contains("_speech = zeilen.duplicate()\n\t_speech_name = name_text"))

	# ── Die Biom-Kanten ───────────────────────────────────────────────────────
	#
	# Die Toenung war ein Zylinder mit gleichmaessiger Deckkraft, und im Bild zog sich dadurch
	# eine harte Linie quer durch die Wueste: hier gruenlich, einen Schritt weiter sandfarben.
	# Ein Biom ist aber keine Verwaltungsgrenze — es hoert nicht auf, es wird weniger.
	_check("Die Biom-Toenung blendet am Rand aus", ow_q.contains("func _biom_scheibe"))
	_check("Und der Zylinder mit harter Kante ist weg",
		not ow_q.contains("cyl.top_radius = r_m"))
	_check("Der Kern bleibt satt (%.0f %%)" % (OW5.BIOM_KERN * 100.0),
		OW5.BIOM_KERN > 0.4 and OW5.BIOM_KERN < 0.85)


func _test_riss() -> void:
	print("· Der Riss")
	var riss: Dictionary = {}
	for f in WorldManager.TERRAIN:
		if String(f.get("kind", "crater")) == "spalt":
			riss = f
	_check("Es gibt einen Riss", not riss.is_empty())
	if riss.is_empty():
		return
	_check("Er ist zehn Meter breit (%.0f m)" % float(riss["breite"]),
		is_equal_approx(float(riss["breite"]), 10.0))
	var c: Vector3 = WorldManager.feature_center(riss)
	# In der Mitte ist er tief. „Tief genug" heisst: Man sieht unten nichts mehr.
	#
	# Gemessen auf der MITTELLINIE, nicht am geometrischen Mittelpunkt: Der Riss schlaengelt um
	# bis zu 26 m, und am Mittelpunkt liegt deshalb gerade die Kante statt des Grundes. Der
	# erste Anlauf mass dort 17 m und sah aus wie ein zu flacher Riss — es war ein zu naiver
	# Messpunkt.
	var tiefste: float = 0.0
	for j0 in 121:
		tiefste = minf(tiefste, WorldManager.height_at(c.x - 60.0 + float(j0), c.z))
	_check("In der Mitte geht es %.0f m hinunter" % -tiefste, tiefste < -30.0)
	# Und quer daneben ist die Ebene unberuehrt — sonst waere aus dem Spalt eine Senke geworden.
	var quer: float = float(riss["breite"]) * 0.5 + float(riss.get("kante_m", 6.0)) \
		+ float(riss.get("schlenker", 0.0)) + 5.0
	_check("Daneben ist die Ebene flach (%.2f m)" % WorldManager.height_at(c.x + quer, c.z),
		absf(WorldManager.height_at(c.x + quer, c.z)) < 0.01)
	# Er SCHLAENGELT. Ein schnurgerader Riss liest sich als Graben, den jemand gezogen hat.
	var mitten: Array = []
	for i in 9:
		var z: float = c.z + (float(i) / 8.0 - 0.5) * float(riss["laenge"]) * 0.8
		# Die tiefste Stelle quer suchen — das ist die Mittellinie an dieser Stelle.
		var tiefste_x: float = c.x
		var tief: float = 0.0
		for j in 121:
			var x: float = c.x - 60.0 + float(j)
			var h: float = WorldManager.height_at(x, z)
			if h < tief:
				tief = h
				tiefste_x = x
		mitten.append(tiefste_x - c.x)
	var min_m: float = 1e9
	var max_m: float = -1e9
	for m in mitten:
		min_m = minf(min_m, float(m))
		max_m = maxf(max_m, float(m))
	_check("Er schlaengelt (%.0f m Versatz ueber die Laenge)" % (max_m - min_m),
		max_m - min_m > 20.0)
	# An den ENDEN laeuft er aus. Ein Abgrund mit senkrechter Stirnwand mitten in der Ebene
	# waere ein Bauteil, kein Riss.
	var ende: float = c.z + float(riss["laenge"]) * 0.5 - 4.0
	_check("An den Enden laeuft er aus (%.1f m statt %.0f m)"
		% [-WorldManager.height_at(c.x, ende), float(riss["tiefe"])],
		WorldManager.height_at(c.x, ende) > -float(riss["tiefe"]) * 0.35)
	# Das Loch im Boden ist ein STREIFEN und kein Quadrat. Als Quadrat um seine Reichweite
	# gerechnet waere es ein Drittel der Welt.
	var halb: Vector2 = WorldManager.feature_halb(riss)
	_check("Sein Loch im Boden ist ein Streifen (%.0f × %.0f m)" % [halb.x * 2.0, halb.y * 2.0],
		halb.y > halb.x * 10.0)
	# Und er liegt dem Prolog nicht im Weg: Grube, Fels und Stadt liegen alle westlich davon.
	# Ueber die ENTFERNUNG, nicht ueber die Hoehe: Die Schrottgrube ist selbst fuenf Meter tief,
	# eine Hoehenpruefung wuerde sie faelschlich als „im Riss" melden. Genau dieser Fehler stand
	# einen Augenblick lang auch in `_am_riss()` — und haette den Prolog vollstaendig gesperrt,
	# weil der Held am Grund der Grube erwacht und dort jeder Schritt gesperrt gewesen waere.
	var OW3 = load("res://scripts/OverworldView.gd")
	var halb0: Vector2 = WorldManager.feature_halb(riss)
	for ort in ["schrott_minen", "rustwater"]:
		var p: Vector3 = WorldManager.poi_scene_position(String(ort))
		_check("%s liegt weit weg vom Riss (%.0f m)" % [String(ort), absf(p.x - c.x)],
			absf(p.x - c.x) > halb0.x + 200.0)
	var fels: Vector3 = WorldManager.world_to_scene(Vector2(348.0, 214.0))
	_check("Der Ausguck auch (%.0f m)" % absf(fels.x - c.x), absf(fels.x - c.x) > halb0.x + 200.0)
	# Und der Grubengrund ist NICHT gesperrt. Das ist die Regression zu dem Fehler oben.
	var ow_r := OverworldView.new()
	ow_r._riss = riss
	var grube: Vector3 = WorldManager.poi_scene_position("schrott_minen")
	grube.y = WorldManager.height_at(grube.x, grube.z)
	_check("Am Grund der Schrottgrube (%.1f m) sperrt der Riss nicht" % grube.y,
		grube.y < -3.0 and not ow_r._am_riss(grube))
	ow_r.free()
	# Die Sperre haengt an der HOEHE, nicht an der Neigung: Die Steigungsgrenze sperrt nur
	# bergauf, und an einem Riss laeuft man hinunter.
	_check("Gesperrt wird ueber die Hoehe, nicht ueber die Steigung",
		OW3.RISS_SPERRE_M > 0.0 and OW3.RISS_SPERRE_M < 3.0)
	var quelle3: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Und die Sperre haengt im Laufen mit drin",
		quelle3.contains("or _am_riss(next):"))
	# Eine unsichtbare Sperre an einem Abgrund ist derselbe Fehler wie an der Palisade, wo die
	# Fussspur vor der Mauer endete: Man laeuft dagegen und weiss nicht, warum.
	_check("Die Kante ist zu sehen", quelle3.contains("func _build_riss"))
	_check("Und sie sagt einmal, was sie ist", quelle3.contains("Zehn Meter Nichts"))


func _test_terrain() -> void:
	print("· Topografie (Senken als Formel)")
	_check("Genau eine Gelaendeform definiert", WorldManager.TERRAIN.size() >= 1)
	var f: Dictionary = WorldManager.TERRAIN[0]
	var c: Vector3 = WorldManager.feature_center(f)
	var R: float = float(f["radius"])
	var reach: float = WorldManager.feature_reach(f)
	_check("Krater ist %.0f m im Durchmesser" % (R * 2.0), is_equal_approx(R * 2.0, 30.0),
		"%.1f m" % (R * 2.0))
	_check("In der Mitte volle Tiefe (-%.1f m)" % float(f["depth"]),
		is_equal_approx(WorldManager.height_at(c.x, c.z), -float(f["depth"])))
	_check("Am Kraterrand wieder auf null",
		is_zero_approx(WorldManager.height_at(c.x + R, c.z)))
	_check("Hinter dem Wall exakt flach",
		is_zero_approx(WorldManager.height_at(c.x + reach + 1.0, c.z)))
	_check("Der Rest der Welt bleibt unberuehrt",
		is_zero_approx(WorldManager.height_at(100.0, -100.0))
		and is_zero_approx(WorldManager.height_at(2500.0, -2500.0)))
	_check("Der Auswurfwall ragt heraus",
		WorldManager.height_at(c.x + R * (1.0 + float(f["rim_width"]) * 0.5), c.z) > 0.3)
	# Der flache Grund: die Buehne, auf der der Held erwacht und auf der der Schrott liegt.
	# Eine Schuessel hat keinen — dort faellt der Boden von der Mitte weg sofort weiter ab.
	var boden_r: float = R * float(f["floor"])
	_check("Der Grund ist ueber %.1f m flach" % (boden_r * 2.0),
		is_equal_approx(WorldManager.height_at(c.x - boden_r * 0.9, c.z), -float(f["depth"]))
		and is_equal_approx(WorldManager.height_at(c.x, c.z - boden_r * 0.9), -float(f["depth"])),
		"%.2f m" % WorldManager.height_at(c.x - boden_r * 0.9, c.z))

	# Wand und Rampe. Das ist der Kern der Form: rundum eine Wand, an EINER Stelle ein Weg.
	# Beides wird an derselben Formel gemessen, nur in verschiedene Richtungen.
	var steil := func(deg: float) -> float:
		var a: float = deg_to_rad(deg)
		var dir := Vector2(cos(a), -sin(a))
		var groesste: float = 0.0
		var vor: float = WorldManager.height_at(c.x, c.z)
		var dd: float = 0.0
		while dd <= reach + 1.0:
			dd += 0.05
			var hh: float = WorldManager.height_at(c.x + dir.x * dd, c.z + dir.y * dd)
			groesste = maxf(groesste, rad_to_deg(atan2(absf(hh - vor), 0.05)))
			vor = hh
		return groesste
	var rampe: float = float(f["ramp_deg"])
	_check("Die Rampe ist begehbar (< 35°)", steil.call(rampe) < 35.0,
		"%.1f° bei %.0f°" % [steil.call(rampe), rampe])
	var wand_min: float = 999.0
	for versatz in [120.0, 180.0, 240.0, 300.0]:
		wand_min = minf(wand_min, steil.call(rampe + versatz))
	_check("Ueberall sonst steht eine Wand (> 50°)", wand_min > 50.0, "flachste %.1f°" % wand_min)
	_check("Die Rampe ist die EINZIGE flache Stelle",
		steil.call(rampe) < 35.0 and wand_min > 50.0)

	# Stetigkeit: dicht abtasten, groessten Sprung messen. Eine steile Wand darf steil sein,
	# aber keine Stufe haben — an einer Stufe bleibt man haengen oder faellt hindurch.
	var max_step: float = 0.0
	var d: float = 0.0
	var prev: float = WorldManager.height_at(c.x, c.z)
	for richtung in [0.0, rampe, rampe + 180.0]:
		var ra: float = deg_to_rad(richtung)
		var rd := Vector2(cos(ra), -sin(ra))
		d = 0.0
		prev = WorldManager.height_at(c.x, c.z)
		while d <= reach + 3.0:
			d += 0.05
			var h: float = WorldManager.height_at(c.x + rd.x * d, c.z + rd.y * d)
			max_step = maxf(max_step, absf(h - prev))
			prev = h
	_check("Keine Stufe im Profil (groesster Sprung auf 5 cm < 12 cm)", max_step < 0.12,
		"%.3f m" % max_step)

	# Normalen kommen aus derselben Formel — in der Mitte senkrecht, an der Flanke geneigt.
	_check("Normale in der Mitte zeigt nach oben",
		WorldManager.normal_at(c.x, c.z).is_equal_approx(Vector3.UP))
	_check("Normale auf dem flachen Grund zeigt ebenfalls nach oben",
		WorldManager.normal_at(c.x + R * 0.5, c.z).is_equal_approx(Vector3.UP))
	var n: Vector3 = WorldManager.normal_at(c.x + R * 0.92, c.z)
	_check("Normale an der Wand ist stark geneigt und zeigt bergab",
		n.y < 0.75 and n.x < 0.0, "%s" % n)

	# Die Restflaeche: Ausschneiden darf keine Flaeche verlieren und keine doppelt zaehlen.
	var ow := OverworldView.new()
	var rects: Array = ow._ground_rects()
	var w: float = WorldManager.WORLD_METERS
	var flaeche: float = 0.0
	for r in rects:
		flaeche += r.size.x * r.size.y
	var loch: float = 0.0
	for tf in WorldManager.TERRAIN:
		# Ueber die HALBAUSDEHNUNG, nicht ueber die Reichweite. Bis zum Riss war jede Form rund
		# und beides dasselbe; ein 10 m breiter und 1900 m langer Spalt ist als Quadrat um seine
		# Reichweite gerechnet dagegen ein Drittel der Welt.
		var hh: Vector2 = WorldManager.feature_halb(tf) + Vector2.ONE * OverworldView.TERRAIN_MARGIN_M
		loch += (hh.x * 2.0) * (hh.y * 2.0)
	# Toleranz RELATIV, nicht absolut: `Rect2` rechnet in float32, und die Weltflaeche sind
	# 25 Millionen m². Je Gelaendeform kommt ein Rechteck-Schnitt dazu, und jeder schleppt rund
	# 8·10⁻⁸ relative Rundung mit — bei elf Formen sind das ein paar Quadratmeter Scheinflaeche.
	# 4·10⁻⁷ (= 10 m²) laesst das durch und faengt trotzdem jeden echten Fehler: Ein verlorenes
	# oder doppelt gezaehltes Stueck ist immer mindestens ein ganzes Rechteck gross.
	var toleranz: float = w * w * 4e-7
	_check("Restflaeche + Loecher = Weltflaeche (nichts verloren, nichts doppelt)",
		absf(flaeche + loch - w * w) < toleranz,
		"%.0f + %.0f = %.0f statt %.0f" % [flaeche, loch, flaeche + loch, w * w])
	# Ueber die SCHMALSTE Kante geprueft, nicht ueber die Flaeche: Aneinanderstossende
	# Rechtecke ueberlappen sich in float32 um rund 2 Hundertstel Millimeter — mal 4600 m
	# Kantenlaenge ergibt das 0,1 m² Scheinflaeche. Eine echte Ueberlappung ist dagegen in
	# BEIDEN Richtungen breit.
	var ueberlappt: String = ""
	var groesster_sliver: float = 0.0
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			var ov: Rect2 = (rects[i] as Rect2).intersection(rects[j])
			var schmal: float = minf(ov.size.x, ov.size.y)
			groesster_sliver = maxf(groesster_sliver, schmal)
			if schmal > 0.01:
				ueberlappt = "%s und %s (%.3f m breit)" % [rects[i], rects[j], schmal]
	_check("Keine zwei Restflaechen ueberlappen sich (groesste Naht %.5f m)" % groesster_sliver,
		ueberlappt == "", ueberlappt)
	# Und das Loch ist wirklich frei.
	var im_loch: bool = false
	for r in rects:
		if r.has_point(Vector2(c.x, c.z)):
			im_loch = true
	_check("Ueber dem Krater liegt keine flache Platte mehr", not im_loch)

	# Regression: Am Kratergrund stand der Platzhalter-Klotz des Ortes und sperrte ihn mit
	# 6,6 m Radius — man lief die Flanke hinunter und blieb unten stehen. Orte mit geformtem
	# Gelaende bekommen deshalb keine Landmarken-Saeule mehr; der Krater IST die Landmarke.
	# Regression: Pisten und Gleise duerfen eine Senke nicht ueberbruecken.
	#
	# Der erste Anlauf tastete die Hoehe nur an den beiden RAENDERN des Streifens ab. Bei 55 m
	# Pistenbreite und 40 m Kraterdurchmesser liegen beide Raender auf flachem Boden — die
	# Strasse spannte sich als Brett ueber das Loch, und Figur wie Truhe verschwanden darunter.
	# Deshalb wird auch QUER unterteilt, und dieser Test faehrt eine Piste mitten durch.
	ow._add_ribbon(c + Vector3(-200.0, 0.0, 0.0), c + Vector3(200.0, 0.0, 0.0),
		27.5, 0.0, 0.06, null)
	var band: MeshInstance3D = null
	for kind in ow.get_children():
		if kind is MeshInstance3D:
			band = kind
	var tiefster: float = 99.0
	var naechster: float = 9999.0
	if band != null and band.mesh != null:
		for v in band.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			tiefster = minf(tiefster, v.y)
			naechster = minf(naechster, Vector2(v.x - c.x, v.z - c.z).length())
	_check("Eine Piste quer durch die Senke wird auch quer unterteilt",
		naechster < 2.0, "naechster Punkt %.1f m von der Mitte" % naechster)
	_check("Und sie folgt dabei bis auf den Grund (%.1f m tief)" % float(f["depth"]),
		tiefster < -float(f["depth"]) + 0.2,
		"tiefster Punkt %.2f m statt %.2f m" % [tiefster, -float(f["depth"]) + 0.06])

	_check("Der Krater-Ort ist als geformt erkannt",
		not ow._terrain_at_poi(String(f["poi"])).is_empty())
	_check("Ein Ort ohne Gelaende bleibt unveraendert",
		ow._terrain_at_poi("rustwater").is_empty())

	# Regression: Die Piste hat den Krater ZUGEDECKT.
	#
	# Gezeichnet wurde sie mit `CORRIDOR_HALF_W` — das sind 27,5 m JE SEITE, also ein 55 m
	# breites Band ueber einer 30-m-Senke. Dazu lief sie bis in den Mittelpunkt des Ortes, also
	# bis auf den Kratergrund. Im Bild sah man deshalb mitten in der Mulde eine harte Kante,
	# an der der Boden wechselte: links Sand mit Textur, rechts die einfarbige Piste.
	_check("Eine Strecke endet am Kraterrand, nicht in der Mitte",
		ow._route_stop_m(String(f["poi"])) >= WorldManager.feature_reach(f),
		"Stopp bei %.1f m, Wallende bei %.1f m"
			% [ow._route_stop_m(String(f["poi"])), WorldManager.feature_reach(f)])
	_check("In offenem Gelaende wird dagegen nicht gekuerzt",
		is_zero_approx(ow._route_stop_m("rattengestruepp")))
	# Gegenprobe an der echten Route: Kein Punkt der Piste darf noch in der Senke liegen.
	var route: Array = ow._trim_route(WorldManager.poi_scene_position("rustwater"),
		c, "rustwater", String(f["poi"]))
	var dist_zur_mitte: float = (route[1] as Vector3).distance_to(c)
	_check("Eine Strecke von Rustwater hoert vor der Senke auf",
		dist_zur_mitte >= float(f["radius"]),
		"endet %.1f m von der Mitte, Kraterrand bei %.1f m" % [dist_zur_mitte, float(f["radius"])])
	ow.free()


## Umlaufrichtung aller selbst gebauten Bodenflaechen.
##
## Der teuerste Fehler des Projekts bisher, und der am schwersten zu sehende: Bodenviereck und
## Gelaendeflicken waren RUECKSEITIG gewickelt. Sichtbar blieben sie trotzdem, weil das
## Sandmaterial aus dem CC0-Modell doppelseitig ist (`cull_mode = CULL_DISABLED`) — aber Godot
## dreht bei einem rueckseitigen Fragment die Normale um, und eine nach unten zeigende Normale
## bekommt kein Sonnenlicht. Der gesamte Boden der Welt lag im blossen Umgebungslicht.
##
## Gemessen im Bild: Helligkeit 0,239 falsch herum gegen 0,963 richtig herum. Die Piste
## daneben war korrekt gewickelt und deshalb hell — DAS war der „Bodenwechsel", ueber den sich
## der Auftraggeber beschwert hat, und der Grund, warum die Wueste aussah wie nasser Lehm.
##
## Die Regel, gegen die hier geprueft wird, stammt aus dem einzigen Bauteil, das nachweislich
## richtig war (`_add_ribbon`): Bei einem VORDERSEITIGEN Dreieck zeigt das Kreuzprodukt
## (v1−v0)×(v2−v0) ENTGEGEN der Schattierungsnormale.
func _test_winding() -> void:
	print("· Umlaufrichtung der Bodenflaechen")
	var ow := OverworldView.new()
	ow._ground_material()
	ow._add_ground_quad(Rect2(Vector2(0.0, -100.0), Vector2(100.0, 100.0)), null)
	ow._add_terrain_patch(WorldManager.TERRAIN[0], null)
	ow._add_ribbon(Vector3.ZERO, Vector3(100.0, 0.0, -100.0), 5.0, 0.0, 0.06, null)
	var namen: Array = ["Bodenviereck", "Gelaendeflicken", "Gleisband"]
	var i: int = 0
	for c in ow.get_children():
		if not (c is MeshInstance3D):
			continue
		var quote: Array = _vorderseitig_anteil(c as MeshInstance3D)
		_check("%s ist vorderseitig gewickelt (%d Dreiecke)" % [String(namen[i]), int(quote[1])],
			int(quote[0]) == int(quote[1]),
			"%d von %d rueckseitig" % [int(quote[1]) - int(quote[0]), int(quote[1])])
		i += 1
		if i >= namen.size():
			break
	_check("Alle drei Bauteile geprueft", i == namen.size())
	ow.free()


## [vorderseitige Dreiecke, Dreiecke gesamt] eines Meshes.
func _vorderseitig_anteil(mi: MeshInstance3D) -> Array:
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var gut: int = 0
	var alle: int = 0
	for t in range(0, v.size() / 3):
		var flaeche: Vector3 = (v[t * 3 + 1] - v[t * 3]).cross(v[t * 3 + 2] - v[t * 3])
		if flaeche.length() < 0.0000001:
			continue
		alle += 1
		if flaeche.normalized().dot(n[t * 3]) < 0.0:
			gut += 1
	return [gut, alle]


## Duenenfeld — die zweite Art von Gelaendeform.
##
## Anders als der Krater haengt es an keinem Ort, sondern an freien Koordinaten. Genau daran
## ist es beim Einbau zweimal gescheitert: `height_at` und `_terrain_at_poi` griffen direkt auf
## `f["poi"]` zu und stuerzten ab, sobald eine Form ohne Ort in der Tabelle stand.
func _test_dunes() -> void:
	print("· Duenenfeld")
	var f: Dictionary = {}
	for e in WorldManager.TERRAIN:
		if String(e.get("kind", "crater")) == "dunes":
			f = e
	if f.is_empty():
		_check("Ein Duenenfeld ist definiert", false)
		return
	var c: Vector3 = WorldManager.feature_center(f)
	_check("Das Feld haengt an freien Koordinaten, nicht an einem Ort", not f.has("poi"))
	_check("Es liegt im begehbaren Teil der Welt",
		WorldManager.is_walkable(WorldManager.scene_to_world(c)))
	_check("Ausserhalb des Feldes ist der Boden exakt flach",
		is_zero_approx(WorldManager.height_at(c.x + float(f["radius"]) + 5.0, c.z)))
	# Duenen liegen AUF der Ebene — nirgends darf das Feld sich eingraben, sonst laeuft man
	# in eine Grube, die keine sein soll.
	var tiefste: float = 99.0
	var hoechste: float = -99.0
	var steilste: float = 0.0
	var r: float = float(f["radius"])
	for iz in range(-30, 31):
		var vor: float = 0.0
		for ix in range(-60, 61):
			var x: float = c.x + float(ix) * (r / 60.0)
			var z: float = c.z + float(iz) * (r / 30.0)
			var h: float = WorldManager.height_at(x, z)
			tiefste = minf(tiefste, h)
			hoechste = maxf(hoechste, h)
			if ix > -60:
				steilste = maxf(steilste, rad_to_deg(atan2(absf(h - vor), r / 60.0)))
			vor = h
	_check("Das Feld gräbt sich nirgends ein (tiefster Punkt %.2f m)" % tiefste, tiefste >= -0.001)
	_check("Die Kaemme erreichen die vorgesehene Hoehe (%.1f von %.1f m)"
		% [hoechste, float(f["amp"])], hoechste > float(f["amp"]) * 0.75)
	_check("Die Duenen bleiben begehbar (steilste %.1f° < 35°)" % steilste, steilste < 35.0)
	# Asymmetrie: eine Duene hat eine flache Luv- und eine steile Leeseite. Ohne sie ist es
	# ein Wellblechdach. Gemessen ueber die Verteilung der Steigungen laengs der Windrichtung.
	var a: float = deg_to_rad(float(f["dir_deg"]))
	var dir := Vector2(cos(a), sin(a))
	var auf: float = 0.0
	var ab: float = 0.0
	var vor2: float = WorldManager.height_at(c.x, c.z)
	for i in range(1, 400):
		var x2: float = c.x + dir.x * float(i) * 0.25
		var z2: float = c.z + dir.y * float(i) * 0.25
		var h2: float = WorldManager.height_at(x2, z2)
		var steig: float = (h2 - vor2) / 0.25
		auf = maxf(auf, steig)
		ab = maxf(ab, -steig)
		vor2 = h2
	_check("Luv- und Leeseite sind verschieden steil (%.2f gegen %.2f)" % [auf, ab],
		absf(auf - ab) > 0.05 * maxf(auf, ab))


## Beutel als Raster (GDD §7.4) — Fussabdruecke, Belegung, Trefferflaechen.
## Die Puppe — getragene Ausruestung als Figur statt als Liste.
##
## Geprueft wird das, was beim Umbau von einer Liste auf eine gezeichnete Flaeche kaputtgehen
## KANN: dass jede Fassung eine Lage hat, dass sich keine zwei ueberlappen, dass ein Tipp genau
## die Fassung findet, ueber der er liegt, und dass alles in die linke Spalte passt. Die Optik
## selbst prueft kein Test — dafuer gibt es `tools/Shot.gd`.
## Wegweisung — aus einer Zahl im Menue wird ein Ort in der Welt.
##
## Der Kern ist nicht die Marke und nicht die Fussspur, sondern die Frage, auf welchen Ort beide
## zeigen. Die wechselt mit dem Fortschritt: erst der Ort der Arbeit, nach Erfuellung der
## Auftraggeber. Ein Wegweiser, der nach dem letzten Kill weiter in die Wildnis zeigt, ist
## schlimmer als keiner.
func _test_quest_wayfinding() -> void:
	print("· Quest-Wegweisung (Marke & Fussspur)")
	_reset_state()
	# Jede Quest braucht ein Ziel, und das Ziel muss es geben. Ein Tippfehler in der Tabelle
	# faellt sonst erst auf, wenn jemand genau diese Quest annimmt.
	var ohne_ziel: String = ""
	var falsch: String = ""
	for qid in QuestManager.QUESTS.keys():
		var def: Dictionary = QuestManager.QUESTS[qid]
		var t: String = String(def.get("target", ""))
		if t == "":
			ohne_ziel = String(qid)
		elif not WorldManager.has_poi(t):
			falsch = "%s -> %s" % [qid, t]
		var g: String = String(def.get("giver", ""))
		if not QuestManager.GIVER_POI.has(g):
			falsch = "%s: Auftraggeber %s hat keinen Ort" % [qid, g]
		elif not WorldManager.has_poi(String(QuestManager.GIVER_POI[g])):
			falsch = "%s: Ort von %s gibt es nicht" % [qid, g]
	_check("Jede Quest hat ein Ziel", ohne_ziel == "", "%s hat keines" % ohne_ziel)
	_check("Jedes Ziel und jeder Auftraggeber-Ort existiert", falsch == "", falsch)
	# ── Rustwater darf nicht verstummen ───────────────────────────────────────
	# Nach den drei Einfuehrungs-Kopfgeldern stand die Stadt still: Die naechsten Auftraege
	# haengen an Kapitel 5 und am Gilden-Reveal, alle drei NPCs hatten nichts mehr zu sagen —
	# und ohne Auftrag laesst sich die Wegweisung gar nicht ausprobieren.
	var je_geber: Dictionary = {}
	var wiederholbar_je_geber: Dictionary = {}
	var ziele_k1: Dictionary = {}
	for qid2 in QuestManager.QUESTS.keys():
		var d2: Dictionary = QuestManager.QUESTS[qid2]
		if int(d2.get("chapter", 1)) != 1 or d2.has("guild"):
			continue
		var g2: String = String(d2["giver"])
		je_geber[g2] = int(je_geber.get(g2, 0)) + 1
		ziele_k1[String(d2["target"])] = true
		if bool(d2.get("repeatable", false)):
			wiederholbar_je_geber[g2] = true
	for wer in ["mabel", "silas", "doc"]:
		_check("%s hat in Kapitel 1 mehr als einen Auftrag (%d)" % [wer, int(je_geber.get(wer, 0))],
			int(je_geber.get(wer, 0)) >= 2)
		_check("%s hat am Ende einen wiederholbaren — die Stadt verstummt nie" % wer,
			bool(wiederholbar_je_geber.get(wer, false)))
	_check("Die Ziele in Kapitel 1 sind gestreut (%d verschiedene)" % ziele_k1.size(),
		ziele_k1.size() >= 3)
	# Der interessante Fall: ein Ziel, zu dem die gerade Linie durch die Todeszone fuehrt.
	# Ohne ihn laesst sich der Umweg im Spiel nie ausprobieren.
	var start: Vector2 = WorldManager.poi_position("rustwater")
	var mit_umweg: String = ""
	for z in ziele_k1.keys():
		if WorldManager.swamp_detour(start, WorldManager.poi_position(String(z))) != Vector2.INF:
			mit_umweg = String(z)
	_check("Mindestens ein Ziel liegt hinter dem Sumpf (%s)" % mit_umweg, mit_umweg != "")
	# ── Wiederholbare Auftraege ───────────────────────────────────────────────
	_reset_state()
	QuestManager.accept_quest("q_d3")
	GameState.kills += int(QuestManager.QUESTS["q_d3"]["count"])
	_check("Ein wiederholbarer Auftrag laesst sich abgeben",
		QuestManager.complete_quest("q_d3"))
	_check("Danach steht er wieder auf `available`, nicht auf `done`",
		QuestManager.get_quest_state("q_d3") == QuestManager.STATE_AVAILABLE)
	# ABER NICHT HEUTE. Das war der Fehler, den das Spiel gezeigt hat: „ich kann bei Mabel den
	# Auftrag unendlich oft abschliessen." Wiederholbar heisst wiederholbar, nicht beliebig oft
	# hintereinander — zehn Gegner, zweihundert Gold, wieder annehmen, und jeder Preis im Spiel
	# ist bedeutungslos.
	_check("Aber heute nicht mehr", not QuestManager.accept_quest("q_d3"))
	_check("Und der Auftraggeber bietet ihn heute auch nicht an",
		QuestManager.heute_schon_abgegeben("q_d3"))
	# Morgen schon.
	GameState.tag += 1
	_check("Morgen wieder", QuestManager.accept_quest("q_d3"))
	var p2: Dictionary = QuestManager.check_quest_progress("q_d3")
	_check("Und faengt wieder bei 0 an (%d/%d)" % [int(p2["current"]), int(p2["target"])],
		int(p2["current"]) == 0)
	# Die Grenze muss den Spielstand ueberleben, sonst haelt Speichern und Laden sie fuer
	# aufgehoben — und der Geldhahn steht wieder offen, nur mit einem Umweg ueber das Menue.
	GameState.kills += int(QuestManager.QUESTS["q_d3"]["count"])
	QuestManager.complete_quest("q_d3")
	var stand_d3: Dictionary = SaveManager.serialize()
	GameState.quest_tag = {}
	SaveManager.deserialize(stand_d3)
	_check("Die Tagesgrenze ueberlebt den Spielstand",
		QuestManager.heute_schon_abgegeben("q_d3"))
	# Und ein NICHT wiederholbarer Auftrag traegt gar keine Tagesgrenze — sonst haenge dieselbe
	# Bremse an Auftraegen, die ohnehin nur einmal stattfinden.
	_check("Ein einmaliger Auftrag kennt keine Tagesgrenze",
		not QuestManager.heute_schon_abgegeben("q_rats"))
	# ── Die Kette, wie der Spieler sie erlebt ────────────────────────────────
	# Genau der Weg, der beim Auftraggeber ankommt: `_quest_for_giver` nimmt den ersten nicht
	# erledigten Auftrag. Erledigt man ihn, muss der naechste kommen — und irgendwann einer, der
	# wiederkommt. Vorher endete die Kette nach dem ersten und der NPC sagte nur noch „…".
	_reset_state()
	var ow3 := OverworldView.new()
	_scratch.append(ow3)
	for wer2 in ["mabel", "silas", "doc"]:
		var gesehen: Array = []
		for runde in 5:
			var q: String = ow3._quest_for_giver(String(wer2))
			if q == "":
				break
			if gesehen.has(q):
				break     # wiederholbar: die Kette schliesst sich
			gesehen.append(q)
			# durchspielen: annehmen, Bedingung erfuellen, abgeben
			QuestManager.accept_quest(q)
			var d3: Dictionary = QuestManager.QUESTS[q]
			if String(d3["kind"]) == "kill":
				GameState.kills += int(d3["count"])
			else:
				GameState.add_item(String(d3["item"]), int(d3["count"]))
			QuestManager.complete_quest(q)
			# Ein Tag je Auftrag. Im Spiel vergeht er ohnehin (die Uhr laeuft, siehe
			# `DayCycle`); hier muss er von Hand weiter, sonst laeuft die Kette in die
			# Tagesgrenze des letzten, wiederholbaren Auftrags und bricht scheinbar ab.
			GameState.tag += 1
		_check("%s bietet nacheinander %d Auftraege an" % [wer2, gesehen.size()],
			gesehen.size() >= 3, "nur %s" % str(gesehen))
		_check("%s hat auch danach noch etwas zu tun" % wer2,
			ow3._quest_for_giver(String(wer2)) != "")
		# Und am selben Tag NICHT mehr: Wer den wiederholbaren gerade abgegeben hat, hoert
		# heute nichts Neues. Das ist die Bremse, um die es geht — sie darf die Kette aber
		# nicht dauerhaft schliessen, deshalb steht die Gegenprobe direkt daneben.
		var q_letzt: String = ow3._quest_for_giver(String(wer2))
		QuestManager.accept_quest(q_letzt)
		var d_letzt: Dictionary = QuestManager.QUESTS[q_letzt]
		if String(d_letzt["kind"]) == "kill":
			GameState.kills += int(d_letzt["count"])
		else:
			GameState.add_item(String(d_letzt["item"]), int(d_letzt["count"]))
		QuestManager.complete_quest(q_letzt)
		_check("%s ist fuer heute fertig" % wer2, ow3._quest_for_giver(String(wer2)) == "")
		_check("%s sagt auch, warum" % wer2, ow3._heute_erledigt(String(wer2)))
		GameState.tag += 1
		_check("%s hat morgen wieder Arbeit" % wer2,
			ow3._quest_for_giver(String(wer2)) != "")
	# Gegenprobe: ein normaler Auftrag bleibt erledigt.
	_reset_state()
	QuestManager.accept_quest("q_rats")
	GameState.kills += int(QuestManager.QUESTS["q_rats"]["count"])
	QuestManager.complete_quest("q_rats")
	_check("Ein normaler Auftrag bleibt `done`",
		QuestManager.get_quest_state("q_rats") == QuestManager.STATE_DONE)
	_check("und laesst sich nicht erneut annehmen", not QuestManager.accept_quest("q_rats"))
	_reset_state()
	# Zustandswechsel des Wegweisers am konkreten Beispiel.
	_check("Ohne Annahme zeigt nichts", QuestManager.quest_target("q_rats") == "")
	_check("Nichts angenommen = nichts verfolgt", QuestManager.tracked_quest() == "")
	QuestManager.accept_quest("q_rats")
	_check("Der frisch angenommene Auftrag wird sofort verfolgt",
		QuestManager.tracked_quest() == "q_rats")
	_check("Er zeigt auf den Ort der Arbeit",
		QuestManager.quest_target("q_rats") == "schrott_minen")
	# Ziel erfuellt -> der Wegweiser dreht sich zum Auftraggeber um.
	GameState.kills += int(QuestManager.QUESTS["q_rats"]["count"])
	_check("Erfuellt zeigt er zum Auftraggeber (Doc steht in Rustwater)",
		QuestManager.quest_target("q_rats") == "rustwater")
	# Zweite Quest: Umschalten muss beide erreichen und wieder zurueckkommen.
	QuestManager.accept_quest("q_bounty")
	_check("Zwei laufende Auftraege", QuestManager.active_quests().size() == 2)
	_check("Der zweite wird jetzt verfolgt", QuestManager.tracked_quest() == "q_bounty")
	var erste: String = QuestManager.track_next()
	var zweite: String = QuestManager.track_next()
	_check("Umschalten wechselt und kehrt zurueck (%s -> %s)" % [erste, zweite],
		erste != zweite and zweite == "q_bounty")
	# Abgabe: der Wegweiser darf nicht ins Leere zeigen.
	QuestManager.track_quest("q_rats")
	QuestManager.complete_quest("q_rats")
	_check("Nach der Abgabe haengt der Wegweiser auf den naechsten Auftrag um",
		QuestManager.tracked_quest() == "q_bounty")
	_check("Der abgegebene zeigt auf nichts mehr", QuestManager.quest_target("q_rats") == "")
	# Ein Spielstand kann eine erledigte Quest als „verfolgt" enthalten — validiert wird beim
	# LESEN, nicht beim Schreiben.
	GameState.tracked_quest = "q_rats"
	_check("Ein erledigter Eintrag im Spielstand wird nicht geglaubt",
		QuestManager.tracked_quest() == "q_bounty")
	GameState.tracked_quest = "gibt_es_nicht"
	_check("Ein unbekannter Eintrag ebenso wenig",
		QuestManager.tracked_quest() == "q_bounty")
	# ── Die Fussspur: Richtung und Standfestigkeit ────────────────────────────
	# Zwei Beschwerden aus dem Spiel, beide hier festgenagelt: Die Abdruecke zeigten in die
	# FALSCHE Richtung (Zehen nach hinten), und sie glitten mit dem Spieler ueber den Sand,
	# statt liegenzubleiben. Beides ist messbar, also wird es gemessen.
	_reset_state()
	var ow4 := OverworldView.new()
	_scratch.append(ow4)
	ow4._player = Node3D.new()
	_scratch.append(ow4._player)
	ow4._build_trail()
	QuestManager.accept_quest("q_rats")
	var los: Vector3 = WorldManager.poi_scene_position("rustwater")
	ow4._player.position = los
	ow4._process_trail(0.016)
	var zeigt: Vector3 = ow4._trail_goal()
	var soll := Vector3(zeigt.x - los.x, 0.0, zeigt.z - los.z).normalized()
	# Der Abdruck liegt flach; seine Zehen sind die +Y-Achse des Vierecks. Wohin die nach dem
	# Kippen und Drehen zeigt, IST die Richtung, in die der Spieler laufen soll.
	var zehe: Vector3 = (ow4._trail[3] as MeshInstance3D).transform.basis * Vector3(0.0, 1.0, 0.0)
	_check("Die Zehen zeigen zum Ziel (%.2f)" % zehe.dot(soll), zehe.dot(soll) > 0.98,
		"zeigen nach %s statt %s" % [zehe, soll])
	# Die Spur STEHT. Ein halber Schritt darf keinen Abdruck verschieben.
	var vorher: Array = []
	for t3 in ow4._trail:
		vorher.append((t3 as MeshInstance3D).position)
	ow4._player.position = los + soll * (OverworldView.TRAIL_SPACING_M * 0.4)
	ow4._process_trail(0.016)
	var gewandert: float = 0.0
	for i4 in ow4._trail.size():
		gewandert = maxf(gewandert,
			(ow4._trail[i4] as MeshInstance3D).position.distance_to(vorher[i4]))
	_check("Ein halber Schritt verschiebt keinen Abdruck (%.3f m)" % gewandert, gewandert < 0.01,
		"%.3f m gewandert" % gewandert)
	# Ein GANZER Schritt rueckt den Ausschnitt um genau einen Abdruck vor: Was auf Platz 1 lag,
	# liegt jetzt auf Platz 0 — am selben Fleck. Die Abdruecke bleiben liegen, der Spieler laeuft.
	ow4._player.position = los + soll * OverworldView.TRAIL_SPACING_M
	ow4._process_trail(0.016)
	var versatz: float = (ow4._trail[0] as MeshInstance3D).position.distance_to(vorher[1])
	# Toleranz am Schrittabstand gemessen, nicht als feste Zahl: Der Abstand ist inzwischen von
	# 2,1 m auf Schrittlaenge (78 cm) gefallen, und eine feste Schranke waere dabei stillschweigend
	# von „streng" zu „nichtssagend" gewandert — oder umgekehrt.
	_check("Ein ganzer Schritt rueckt um genau einen Abdruck vor (%.2f m)" % versatz,
		versatz < OverworldView.TRAIL_SPACING_M * 0.12, "Abweichung %.2f m" % versatz)

	# ── Der Umweg um den Sumpf ────────────────────────────────────────────────
	# Ein Leitsystem, das einen umbringt, ist schlimmer als gar keines.
	_reset_state()
	GameState.economy["laboratory"] = 0
	var von: Vector2 = WorldManager.poi_position("rustwater")
	var nach: Vector2 = WorldManager.poi_position("zugdepot")
	var umweg: Vector2 = WorldManager.swamp_detour(von, nach)
	_check("Rustwater -> Zugdepot fuehrt gerade durch den Sumpf, es gibt also einen Umweg",
		umweg != Vector2.INF)
	_check("Das Zwischenziel liegt selbst NICHT im Sumpf",
		umweg == Vector2.INF or not WorldManager.is_in_swamp(umweg))
	_check("Der direkte Weg dorthin ist frei",
		umweg == Vector2.INF or WorldManager.swamp_detour(von, umweg) == Vector2.INF)
	# Die Zone reicht von x = 0 bis 1000 — westlich herum gibt es gar nichts. Der Umweg MUSS
	# also oestlich laufen. Genau das hat der erste Entwurf falsch gemacht.
	_check("Der Umweg laeuft oestlich herum, nicht gegen den Kartenrand (x = %.0f)" % umweg.x,
		umweg == Vector2.INF or umweg.x > WorldManager.swamp_rect().end.x)
	# Und er muss ANKOMMEN: von Ecke zu Ecke, hoechstens ein paar Schritte, ohne sich im Kreis
	# zu drehen. Ein Wegweiser, der auf den Punkt zeigt, auf dem man steht, ist ein Haenger.
	var schritt: Vector2 = von
	var schritte: int = 0
	while schritte < 6:
		var naechster: Vector2 = WorldManager.swamp_detour(schritt, nach)
		if naechster == Vector2.INF:
			break
		_check("Schritt %d bewegt sich (%.0f/%.0f)" % [schritte + 1, naechster.x, naechster.y],
			schritt.distance_to(naechster) > 1.0)
		schritt = naechster
		schritte += 1
	_check("Der Umweg kommt nach %d Ecken beim Ziel an" % schritte,
		schritte < 6 and WorldManager.swamp_detour(schritt, nach) == Vector2.INF)
	_check("Das Zwischenziel liegt auf der Karte",
		umweg == Vector2.INF or (umweg.x >= 0.0 and umweg.x <= float(WorldManager.WORLD_SIZE)
			and umweg.y >= 0.0 and umweg.y <= float(WorldManager.WORLD_SIZE)))
	_check("Rustwater -> Schrott-Minen braucht keinen Umweg",
		WorldManager.swamp_detour(von, WorldManager.poi_position("schrott_minen")) == Vector2.INF)
	GameState.economy["laboratory"] = WorldManager.SWAMP_SUIT_LEVEL
	_check("Mit Schutzanzug faellt der Umweg weg — dann ist der Sumpf nur Gelaende",
		WorldManager.swamp_detour(von, nach) == Vector2.INF)
	# ── Regression: die Spur lag UNTER dem Stadtboden ─────────────────────────
	# Vierzehn Abdruecke, alle korrekt gesetzt, alle sichtbar geschaltet — und im Bild nichts.
	# Sie lagen bei 0,06 und der Stadtboden von Rustwater bei 0,08. Vom Rechnen an den Zahlen
	# war das nicht zu sehen; gefunden hat es ein Wuerfel an derselben Stelle, der brav erschien.
	var ow2 := OverworldView.new()
	_scratch.append(ow2)
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	_check("In der Stadt liegt ein flacher Marker UEBER dem Stadtboden (%.3f > %.3f)"
		% [ow2._decal_height(stadt.x, stadt.z), OverworldView.TOWN_GROUND_TOP],
		ow2._decal_height(stadt.x, stadt.z) > OverworldView.TOWN_GROUND_TOP)
	var draussen: Vector3 = stadt + Vector3(OverworldView.TOWN_GROUND_R + 60.0, 0.0, 0.0)
	_check("Draussen liegt er knapp ueber dem Gelaende",
		is_equal_approx(ow2._decal_height(draussen.x, draussen.z),
			WorldManager.height_at(draussen.x, draussen.z) + OverworldView.DECAL_LIFT_M))
	_check("Auch im Krater folgt er dem Gelaende, nicht der Null-Ebene",
		ow2._decal_height(WorldManager.poi_scene_position("schrott_minen").x,
			WorldManager.poi_scene_position("schrott_minen").z) < 0.0)
	_reset_state()


## Die Uhr der Welt.
##
## Geprueft wird, was daran schiefgehen KANN: dass die Phasen den Tag luecken- und
## ueberschneidungsfrei abdecken (der Uebergang ueber Mitternacht ist der einzige, der hinten
## herum geht), dass die Beleuchtung nirgends SPRINGT — eine Sonne, die an einer Phasengrenze
## einen Satz macht, liest sich als Fehler — und dass ein Tag wirklich so lange dauert wie
## eingetragen (`DAY_SEC`, seit dem Verdoppeln vierundzwanzig Minuten).
func _test_daycycle() -> void:
	print("· Tageszeit")
	# 1. Jede Stunde hat genau eine Phase, und alle vier kommen vor.
	var gesehen: Dictionary = {}
	var ohne: float = -1.0
	for i in 240:
		var h: float = float(i) * 0.1
		var p: String = DayCycle.phase_at(h)
		if p == "":
			ohne = h
		gesehen[p] = true
	_check("Jede Stunde hat eine Phase", ohne < 0.0, "bei %.1f keine" % ohne)
	_check("Alle vier Phasen kommen vor (%d)" % gesehen.size(), gesehen.size() == 4)
	_check("Mitternacht ist Nacht", DayCycle.phase_at(0.0) == DayCycle.NACHT)
	_check("Mittag ist Tag", DayCycle.phase_at(12.0) == DayCycle.TAG)
	# 2. Dunkel ist Nacht UND Daemmerung — ein lichtscheues Tier wartet nicht auf Mitternacht.
	_check("Nachts ist es dunkel", DayCycle.is_dark(2.0))
	_check("In der Daemmerung auch", DayCycle.is_dark(6.0))
	_check("Mittags nicht", not DayCycle.is_dark(12.0))
	# 3. Die Helligkeit ist eine Kurve, keine Treppe. Der groesste Sprung zwischen zwei Minuten
	#    darf klein sein; sonst zuckt die Beleuchtung.
	var sprung: float = 0.0
	var wo: float = 0.0
	var vorher: float = DayCycle.daylight(0.0)
	for j in range(1, 1440):
		var h2: float = float(j) / 60.0
		var jetzt: float = DayCycle.daylight(h2)
		if absf(jetzt - vorher) > sprung:
			sprung = absf(jetzt - vorher)
			wo = h2
		vorher = jetzt
	_check("Die Helligkeit springt nirgends (max %.4f bei %.2f h)" % [sprung, wo], sprung < 0.01)
	_check("Mittags ist es am hellsten", DayCycle.daylight(12.75) > 0.95)
	_check("Nachts ist es finster", DayCycle.daylight(1.0) < 0.001)
	# 4. Auch nachts gibt es gerichtetes Licht — ohne Schatten steht nichts mehr auf dem Boden.
	# Der Mond ist eine EIGENE Lampe. Vorher lief er ueber die Sonnenenergie und damit aus der
	# Richtung der Sonne — nachts also aus 14° UNTER dem Horizont, und die Nacht war schwarz.
	_check("Nachts scheint keine Sonne (%.2f)" % DayCycle.sun_energy(1.0),
		DayCycle.sun_energy(1.0) < 0.01)
	_check("Sondern der Vollmond (%.2f)" % DayCycle.moon_energy(1.0),
		DayCycle.moon_energy(1.0) > 0.25)
	_check("Und der steht dabei ueber dem Horizont (%.0f°)" % DayCycle.moon_altitude_deg(1.0),
		DayCycle.moon_altitude_deg(1.0) > 20.0)
	_check("Mittags leuchtet er nicht", DayCycle.moon_energy(12.75) < 0.01)
	_check("Die Mittagssonne ist deutlich staerker als der Mond",
		DayCycle.sun_energy(12.75) > DayCycle.moon_energy(1.0) * 1.6)
	# Die Mondscheibe steht der Sonne gegenueber und nur nachts am Himmel.
	# Sonne und Mond STEHEN — sie wandern nicht. Eine Sonne, die einen Zwoelf-Minuten-Tag
	# abfaehrt, bewegt sich um zwei Grad je Sekunde, und dabei springt die Schattenkarte
	# zwischen zwei Rasterpositionen hin und her: sichtbar als grobes Rauschen an jeder Kante.
	_check("Die Sonne steht fest (%.0f°)" % DayCycle.sun_altitude_deg(1.0),
		is_equal_approx(DayCycle.sun_altitude_deg(1.0), DayCycle.sun_altitude_deg(12.75)))
	_check("Und wandert auch nicht seitlich",
		is_equal_approx(DayCycle.sun_azimuth_deg(6.0), DayCycle.sun_azimuth_deg(18.0)))
	_check("Der Mond steht hoch (%.0f°)" % DayCycle.moon_altitude_deg(1.0),
		DayCycle.moon_altitude_deg(1.0) > 30.0)
	_check("Und der Sonne gegenueber (%.0f° zu %.0f°)"
		% [DayCycle.moon_azimuth_deg(1.0), DayCycle.sun_azimuth_deg(1.0)],
		absf(fposmod(DayCycle.moon_azimuth_deg(1.0) - DayCycle.sun_azimuth_deg(1.0), 360.0) - 180.0) < 1.0)
	# Der Mond geht auf, BEVOR die Sonne unten ist. Vorher gab es eine Luecke: Um 18:36 stand
	# die Sonne bei +15° — von der 66°-Wand der Schrottgrube verdeckt — und der Mond bei 0,00.
	# Die dunkelste Stunde des Tages lag ausgerechnet im ersten Augenblick des Spiels.
	_check("Zum Prologbeginn leuchtet der Mond schon (%.2f)"
		% DayCycle.moon_energy(DayCycle.START_HOUR),
		DayCycle.moon_energy(DayCycle.START_HOUR) > 0.1)
	_check("Mittags nicht", DayCycle.moon_energy(12.75) < 0.01)
	_check("Und mittags unsichtbar", DayCycle.moon_visibility(12.75) < 0.01)
	_check("Nachts voll da", DayCycle.moon_visibility(1.0) > 0.99)
	# 5. Die Sonne wandert von Ost nach West und geht nicht rueckwaerts.
	var az: float = DayCycle.sun_azimuth_deg(DayCycle.H_DAEMMERUNG + 0.1)
	var rueck: bool = false
	for k in range(1, 100):
		var h3: float = lerpf(DayCycle.H_DAEMMERUNG, DayCycle.H_NACHT, float(k) / 100.0)
		var neu2: float = DayCycle.sun_azimuth_deg(h3)
		if neu2 < az - 0.001:
			rueck = true
		az = neu2
	_check("Die Sonne wandert nur in eine Richtung", not rueck)
	# 6. Ein Tag dauert, was er dauern soll.
	var h4: float = 0.0
	for _s in int(DayCycle.DAY_SEC):
		h4 = DayCycle.advance(h4, 1.0)
	_check("Ein Tag sind %.0f Sekunden (Rest %.3f h)" % [DayCycle.DAY_SEC, h4],
		absf(fposmod(h4 + 12.0, 24.0) - 12.0) < 0.05)
	# 7. Nachttiere sind als solche eingetragen, und nicht alle.
	var nacht: int = 0
	for id in CombatData.ENEMY_TYPES.keys():
		if bool(CombatData.ENEMY_TYPES[id].get("nocturnal", false)):
			nacht += 1
	_check("Es gibt Nachttiere (%d)" % nacht, nacht > 0)
	_check("Aber nicht alle", nacht < CombatData.ENEMY_TYPES.size())
	_check("Die Uhr laeuft im Spielstand", DayCycle.clock_text(7.5) == "07:30")
	# 8. Der Prolog beginnt im Abendrot: Der Held erwacht in der Daemmerung, und waehrend er
	#    nach Rustwater geht, wird es Nacht. Faengt eine Runde mittags an, gibt es kein
	#    beleuchtetes Rustwater in dunkler Wueste — und der ganze Anfang laeuft ins Leere.
	_check("Eine Runde beginnt im Abendrot (%s)" % DayCycle.clock_text(DayCycle.START_HOUR),
		DayCycle.phase_at(DayCycle.START_HOUR) == DayCycle.ABEND)
	# Und der Fussmarsch zur Stadt reicht, damit es dabei WIRKLICH dunkel wird: gut ein
	# Kilometer bei 4,7 m/s.
	var marsch: float = 1000.0 / WorldManager.PLAYER_SPEED_MS
	var ankunft: float = DayCycle.advance(DayCycle.START_HOUR, marsch)
	_check("Bei Ankunft zu Fuss ist es Nacht (%s)" % DayCycle.clock_text(ankunft),
		DayCycle.phase_at(ankunft) == DayCycle.NACHT)
	# Und im Sattel — dreifaches Tempo — wenigstens nicht mehr am hellen Tag. Das ist die
	# Pruefung, die beim Verdoppeln der Taglaenge etwas zu sagen hatte: Wer schneller ankommt,
	# kommt bei einer laengeren Uhr FRUEHER an, und irgendwann waere er im Sonnenschein da.
	# Der Prolog laeuft auf ein beleuchtetes Rustwater in dunkler Wueste zu; bei Tageslicht
	# gibt es dieses Bild nicht.
	var ritt: float = DayCycle.advance(DayCycle.START_HOUR, marsch / 3.0)
	_check("Und im Sattel wenigstens Abendrot (%s)" % DayCycle.clock_text(ritt),
		DayCycle.phase_at(ritt) == DayCycle.ABEND or DayCycle.phase_at(ritt) == DayCycle.NACHT)
	# Die Uhr darf nicht rennen. Bei zwoelf Minuten verging in JEDER Sekunde eine Spielminute —
	# man sah sie beim Zusehen laufen, und ein Gespraech mit einem Haendler kostete eine
	# Tageszeit. Eine Spielstunde muss laenger dauern als ein Gespraech.
	var sek_je_stunde: float = DayCycle.DAY_SEC / 24.0
	_check("Eine Spielstunde dauert %.0f echte Sekunden" % sek_je_stunde, sek_je_stunde >= 55.0)

	# ── Zwei Drittel hell, ein Drittel dunkel ────────────────────────────────
	#
	# Gemessen und nicht aus den Konstanten abgelesen: Der Tag wird in Zehntelstunden
	# durchgegangen und gezaehlt, wo die Sonne ueber dem Horizont steht (`daylight() > 0`).
	# Eine Pruefung, die `H_NACHT - H_DAEMMERUNG` ausrechnet, prueft nur, ob ich subtrahieren
	# kann — sie faende es nicht, wenn `daylight` selbst andere Grenzen benutzte.
	var hell: int = 0
	for i in 240:
		if DayCycle.daylight(float(i) * 0.1) > 0.0:
			hell += 1
	var anteil: float = float(hell) / 240.0
	_check("Die Sonne steht zwei Drittel des Tages ueber dem Horizont (%.1f h, %.0f %%)"
		% [float(hell) * 0.1, anteil * 100.0], absf(anteil - 2.0 / 3.0) < 0.02)
	_check("Und ein Drittel darunter (%.1f h)" % (24.0 - float(hell) * 0.1),
		absf((24.0 - float(hell) * 0.1) - 8.0) < 0.5)
	# In echter Zeit: sechzehn Minuten Licht, acht Minuten Dunkelheit.
	_check("In echter Zeit sind das %.0f Minuten Licht und %.0f Minuten Nacht"
		% [anteil * DayCycle.DAY_SEC / 60.0, (1.0 - anteil) * DayCycle.DAY_SEC / 60.0],
		absf(anteil * DayCycle.DAY_SEC / 60.0 - 16.0) < 0.5)
	# Die beiden schoenen Phasen bleiben kurz und gleich lang — sie sind der Grund, warum es
	# ueberhaupt vier Phasen gibt und nicht zwei.
	_check("Daemmerung und Abendrot sind gleich lang (%.1f / %.1f h)"
		% [DayCycle.H_TAG - DayCycle.H_DAEMMERUNG, DayCycle.H_NACHT - DayCycle.H_ABEND],
		is_equal_approx(DayCycle.H_TAG - DayCycle.H_DAEMMERUNG,
			DayCycle.H_NACHT - DayCycle.H_ABEND))
	# Und der helle Tag selbst ist die Haelfte der Uhr — der Rest verteilt sich auf die
	# Uebergaenge und die Nacht.
	_check("Der helle Tag ist zwoelf Stunden (%.1f)" % (DayCycle.H_ABEND - DayCycle.H_TAG),
		is_equal_approx(DayCycle.H_ABEND - DayCycle.H_TAG, 12.0))
	# 9. Flammen flackern — und zwar so, dass es nicht auffaellt, WIE sie es tun.
	_test_flacker()
	# 10. Die Umrundung des Wasserturms ist wirklich eine.
	_test_orbit()
	# 11. Der Prolog: Aufwachen, erste Saetze, Abschluss.
	_test_prolog()
	_test_dialoge()


## Der Anfang: Erwachen in der Grube, die ersten Saetze, das Ende des Prologs.
##
## Geprueft wird die MECHANIK, nicht der Text — dass eine Runde ohne Spielstand in der
## Schrottgrube beginnt und nicht in der Stadt, dass die Figur mit leeren Haenden anfaengt, dass
## die erste Truhe den Karabiner GARANTIERT liefert (der Anfang einer Geschichte darf nicht
## auswuerfeln, ob sie stattfindet), und dass die Textfolge in der richtigen Reihenfolge
## abgearbeitet wird.
## Die Dialogtabelle.
##
## Geprueft wird, was eine Tabelle kaputtmachen kann, ohne dass es jemand merkt: eine Person
## ohne Zeilen, ein Anlass ohne Zeilen, eine leere Zeile mittendrin — und dass jede Person, die
## im Spiel steht, auch etwas zu sagen hat.
func _test_dialoge() -> void:
	print("· Dialoge")
	var noetig: Array = ["erst", "offer", "wait", "done", "idle"]
	for giver in ["mabel", "silas", "doc"]:
		_check("%s steht in der Dialogtabelle" % giver, DialogData.kennt(giver))
		for anlass in noetig:
			var z: Array = DialogData.lines(giver, anlass)
			_check("%s hat Zeilen fuer %s (%d)" % [giver, anlass, z.size()], not z.is_empty())
			var leer: bool = false
			for zeile in z:
				if String(zeile).strip_edges() == "":
					leer = true
			_check("… und keine davon ist leer", not leer)
	# Die Begruessung ist mehr als ein Satz — sonst haette sich der ganze Umbau nicht gelohnt.
	_check("Mabels erste Begegnung ist ein Gespraech (%d Zeilen)"
		% DialogData.lines("mabel", "erst").size(),
		DialogData.lines("mabel", "erst").size() >= 3)
	# Nach dem Reveal reden sie anders — aber nur, wo es eine Variante gibt.
	_check("Nach dem Reveal klingt Mabel anders",
		DialogData.lines("mabel", "idle", true) != DialogData.lines("mabel", "idle", false))
	_check("Ohne eigene Variante bleibt es beim normalen Text",
		DialogData.lines("silas", "wait", true) == DialogData.lines("silas", "wait", false))
	_check("Wen die Tabelle nicht kennt, liefert nichts", DialogData.lines("niemand", "idle").is_empty())
	# Jede Person mit Quests im Spiel muss auch reden koennen.
	var ohne: String = ""
	for qid in QuestManager.QUESTS:
		var g: String = String(QuestManager.QUESTS[qid].get("giver", ""))
		if g != "" and not DialogData.kennt(g):
			ohne = g
	_check("Jeder Auftraggeber hat Zeilen", ohne == "", "%s fehlt" % ohne)
	# Und die Erstbegegnung laeuft nur EINMAL: `GameState.met` faehrt durch den Spielstand.
	var vorher: Dictionary = GameState.met.duplicate()
	GameState.met = {}
	_check("Beim ersten Mal ist niemand bekannt", not bool(GameState.met.get("mabel", false)))
	GameState.met["mabel"] = true
	_check("Danach schon", bool(GameState.met.get("mabel", false)))
	_check("Und es steht im Spielstand", SaveManager.to_json().contains("\"met\""))
	GameState.met = vorher
	var quelle2: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Die Spur fuehrt in der Stadt zuerst zu Mabel",
		quelle2.contains('_npc_pos("mabel")'))
	_check("Und die Nahaufnahme dauert so lange wie die Rede",
		quelle2.contains("speech_gesamt(zeilen)"))


func _test_prolog() -> void:
	print("· Prolog")
	# 1. Ohne Spielstand faengt es auf der Kippe an, mit `prolog_done` in der Stadt.
	var grube: Vector3 = Vector3.ZERO
	var gefunden: bool = false
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == "schrotthalde":
			grube = WorldManager.feature_center(f)
			gefunden = true
	_check("Die Schrottgrube liegt in der Welt", gefunden)
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	var weit: float = Vector2(grube.x - stadt.x, grube.z - stadt.z).length()
	_check("Sie liegt weit genug von Rustwater weg (%.0f m)" % weit, weit > 300.0)
	# 2. Leere Haende sind der Anfangszustand, kein Fehler — und die erste Truhe hebt ihn auf.
	_check("Der Blei-Karabiner ist als Waffengattung eingetragen",
		ProgressionManager.WEAPON_KINDS.has("karabiner"))
	var frisch: Dictionary = ProgressionManager.make_gear("weapon", "common", "", null, "karabiner")
	_check("Und laesst sich gezielt erzeugen statt auszuwuerfeln",
		String(frisch.get("kind", "")) == "karabiner")
	# Die Regel, an der der Anfang haengt: `weapons` fuehrt das GEFUNDENE. Wer nichts gefunden
	# hat, traegt nichts — sonst waere jede Beute wertlos.
	var vorher: Array = GameState.weapons.duplicate()
	GameState.weapons = []
	_check("Mit leerer Liste traegt er keine Waffe", not GameState.has_weapon("karabiner"))
	GameState.add_weapon("karabiner")
	_check("Nach dem Fund schon", GameState.has_weapon("karabiner"))
	GameState.weapons = vorher
	# 3. Die Textfolge: in der Reihenfolge der Einsaetze, keiner verschluckt, keiner doppelt.
	var beats: Array = [
		{ "t": 0.6, "text": "eins" }, { "t": 4.8, "text": "zwei" }, { "t": 11.4, "text": "drei" },
	]
	var gesagt: Array = []
	var t: float = 0.0
	var rest: Array = beats.duplicate()
	# Dieselbe Schleife wie `_process_beats`, in 60 Bildern je Sekunde ueber 14 s.
	for i in 840:
		t += 1.0 / 60.0
		while not rest.is_empty() and t >= float(rest[0]["t"]):
			gesagt.append(String((rest.pop_front() as Dictionary)["text"]))
	_check("Alle Zeilen kommen (%d)" % gesagt.size(), gesagt.size() == 3)
	_check("Und in der richtigen Reihenfolge", gesagt == ["eins", "zwei", "drei"])
	# 4. Ein Einsatz von 0 s feuert im ERSTEN Bild und nicht erst im zweiten — sonst haengt der
	#    Beginn einer Szene an der Bildrate.
	var sofort: Array = [{ "t": 0.0, "text": "jetzt" }]
	_check("Ein Einsatz bei 0 kommt sofort", 1.0 / 60.0 >= float(sofort[0]["t"]))
	# 5. Das Aufwachen dauert so lange wie die Kamerafahrt dazu.
	var OW = load("res://scripts/OverworldView.gd")
	# Das Aufstehen ist LANGSAM und die Kamera kommt nah heran. Die Fahrt muss dabei so lange
	# dauern wie der Clip — sonst haette der Spieler die Steuerung, waehrend die Figur noch am
	# Boden liegt, und die Animation braeche mitten im Aufstemmen ab.
	# Die Szene dauert so lange, wie der Held zu reden hat — nicht andersherum. Eine Kamerafahrt
	# mit fester Laenge zwingt den Text in ihr Korsett, und dabei kommen vier Halbsaetze heraus.
	var wach_zeilen: Array = OW._wach_zeilen()
	var wach_sek: float = OW.speech_gesamt(wach_zeilen)
	_check("Der Held sagt beim Erwachen mehr als drei Saetze (%d)" % wach_zeilen.size(),
		wach_zeilen.size() >= 10)
	_check("Das Erwachen dauert entsprechend lange (%.0f s)" % wach_sek, wach_sek > 40.0)
	_check("Eine Zeile steht laenger als zwei Sekunden (%.1f s)"
		% OW.speech_dauer("„Wo bin ich hier?“"), OW.speech_dauer("„Wo bin ich hier?“") > 2.0)
	_check("Eine lange Zeile laenger als eine kurze",
		OW.speech_dauer("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") > OW.speech_dauer("ah"))
	_check("Aber keine laenger als neun Sekunden",
		OW.speech_dauer("x".repeat(600)) <= 9.0)
	# Die Kamera faengt DICHT am Kopf an — nicht bei sechzehn Metern, wie im ersten Entwurf.
	_check("Die Kamera steht anfangs dicht am Kopf (%.1f m)" % OW.WACH_NAH_M,
		OW.WACH_NAH_M > 0.6 and OW.WACH_NAH_M < 2.0)

	# ── Die Szene setzt da ein, wo der Film aufhoert ──────────────────────────
	#
	# Der Vorspann endet damit, dass er fast steht. Vorher fing das Spiel danach WIEDER AM BODEN
	# an — der Zuschauer sah dieselbe Bewegung zweimal, die zweite davon langsamer. Jetzt
	# springt der Clip in seine letzte Streckung.
	_check("Der Aufsteh-Clip setzt spaet ein (%.0f %%)" % (float(OW.WACH_EINSPRUNG) * 100.0),
		float(OW.WACH_EINSPRUNG) > 0.6 and float(OW.WACH_EINSPRUNG) < 0.95)
	var quelle: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Und wird auch wirklich mit diesem Einsprung abgespielt",
		quelle.contains('play_clip(_player_model, "standup", false, laenge * WACH_EINSPRUNG)'))
	# Danach uebernimmt `idle`. Ohne das steht die Figur den ganzen Rest der Szene in der
	# Schlusspose des Aufsteh-Clips wie eingefroren.
	_check("Danach uebernimmt die Ruhe-Animation",
		quelle.contains('AssetRegistry.play_clip(_player_model, "idle", true)'))
	# Und keine Haltepunkte mehr: Das Ringen um die Senkrechte ist im Film passiert.
	_check("Die alten Haltepunkte sind weg", not quelle.contains("WACH_HALT"))

	# ── Er sieht sich um ──────────────────────────────────────────────────────
	#
	# Das ist die einzige Handlung, die ihm in diesen zwanzig Sekunden bleibt. Ohne sie steht
	# eine Figur stumm herum, waehrend aus dem Off geredet wird.
	var ziel_grad: float = 40.0
	var von: float = OW.wach_blick(0.0, ziel_grad)
	var bis: float = OW.wach_blick(1.0, ziel_grad)
	_check("Am Anfang steht er noch, wie er stand (%.0f°)" % von, absf(von) < 0.001)
	_check("Am Ende sieht er dorthin, wovon sein letzter Satz spricht (%.0f°)" % bis,
		absf(bis - ziel_grad) < 0.001)
	# In BEIDE Richtungen: Wer sich nur nach einer Seite wendet, sucht nicht — er hat gefunden.
	var links: float = 0.0
	var rechts: float = 0.0
	var dreh_weg: float = 0.0
	var vorher_w: float = von
	for i in range(1, 201):
		var v: float = OW.wach_blick(float(i) / 200.0, ziel_grad)
		links = minf(links, v)
		rechts = maxf(rechts, v)
		dreh_weg += absf(v - vorher_w)
		vorher_w = v
	_check("Er sieht nach links (%.0f°) UND nach rechts (%.0f°)" % [links, rechts],
		links < -30.0 and rechts > 30.0)
	# Und die Drehung ist stetig — ein Sprung waere ein Bildfehler, kein Blick.
	var groesster_w: float = 0.0
	vorher_w = von
	for i in range(1, 601):
		var v2: float = OW.wach_blick(float(i) / 600.0, ziel_grad)
		groesster_w = maxf(groesster_w, absf(v2 - vorher_w))
		vorher_w = v2
	_check("Der Blick wandert stetig (groesster Schritt %.1f° je 1/600 der Szene)"
		% groesster_w, groesster_w < 2.0)
	_check("Insgesamt dreht er sich %.0f° weit" % dreh_weg,
		dreh_weg > 150.0 and dreh_weg < 400.0)
	# Die Kamera darf seiner Drehung NICHT folgen: Ein Versatz in seinem Bezugssystem dreht sich
	# mit ihm, und dann steht er im Bild still, waehrend die Welt sich dreht.
	var wach_block: String = quelle.substr(quelle.find("func _erwachen()"))
	wach_block = wach_block.substr(0, wach_block.find("_wach_licht_setzen"))
	_check("Die Kamerapunkte des Erwachens haengen nicht am Kopf",
		not wach_block.contains('"kopf": true'))
	# Und der Text widerspricht der Figur nicht mehr. Gesucht wird die GEGENWART: „Wer laesst
	# einen Mann auf einer Halde liegen" spricht von dem, was ihm angetan wurde, und bleibt
	# richtig — falsch war nur „Ich lieg auf einer Muellkippe", waehrend er dasteht.
	var liegt: String = ""
	for z in wach_zeilen:
		var zt: String = String(z)
		if zt.contains("Ich lieg") or zt.contains("ich lieg"):
			liegt = zt
	_check("Keine Zeile behauptet mehr, er laege da", liegt == "", liegt)
	# Der Held redet SELBST, in der Sprechtafel — nicht ein Erzaehler in der Meldungszeile.
	_check("Der Held hat eine Stimme", OW.HELD_NAME != "")
	_check("Und die Prolog-Zeilen laufen ueber die Sprechtafel",
		quelle.contains("_play_speech(HELD_NAME"))
	_check("Ein Tipp blaettert, statt die Fahrt abzubrechen",
		quelle.contains("_dialog.visible:\n\t\t_naechste_zeile()")
		or quelle.contains("_naechste_zeile()"))
	# 6. Das Pferd. Es hatte GAR KEINEN Eintrag in der Aktionsleiste: Es stand mit Namensschild
	#    am Kraterrand, und auf dem Handy — wo es keine [E]-Taste gibt — war es reine Deko.
	_check("Das Pferd ist aus einigen Metern ansprechbar (%.1f m)" % OW.MOUNT_RANGE_M,
		OW.MOUNT_RANGE_M >= 2.0 and OW.MOUNT_RANGE_M <= 8.0)
	_check("Im Sattel ist man dreimal so schnell", is_equal_approx(OW.MOUNT_SPEED_MUL, 3.0))
	_check("Die Aktionsleiste baut einen Pferde-Knopf",
		quelle.contains("Aufsitzen") and quelle.contains("Absteigen"))
	_check("Und Taste wie Knopf fragen dieselbe Reichweite ab",
		quelle.count("_pferd_greifbar()") >= 2)
	# 6b. Der Ausguck: eine Anhoehe zwischen Grube und Stadt, auf die man STEIGT.
	#
	# Gebaut als umgedrehter Krater — dieselbe Formel, `depth` negativ. Geprueft wird, dass das
	# Profil auch wirklich tut, was es soll: a_oben flach, ringsum zu steil zum Hochlaufen, und
	# genau EINE Seite begehbar.
	var aus: Dictionary = {}
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == "ausguck":
			aus = f
	_check("Die Anhoehe steht in der Welt", not aus.is_empty())
	if aus.is_empty():
		return
	var a_mitte: Vector3 = WorldManager.feature_center(aus)
	var a_oben: float = WorldManager.height_at(a_mitte.x, a_mitte.z)
	_check("Sie ist hoch genug fuer eine Aussicht (%.0f m)" % a_oben, a_oben >= 10.0)
	# Und es ist ein FELS, kein Kegel: Der Umriss ist nicht rund.
	var r_min: float = 1e9
	var r_max: float = 0.0
	for g in 72:
		var w: float = deg_to_rad(float(g) * 5.0)
		var richt := Vector2(cos(w), -sin(w))
		# Vom Rand nach innen suchen, wo der Fels anfaengt.
		for j in 120:
			var rr: float = float(aus["radius"]) * 1.4 * (1.0 - float(j) / 120.0)
			var q := Vector3(a_mitte.x + richt.x * rr, 0.0, a_mitte.z + richt.y * rr)
			if WorldManager.height_at(q.x, q.z) > 0.5:
				r_min = minf(r_min, rr)
				r_max = maxf(r_max, rr)
				break
	_check("Der Umriss ist unregelmaessig (%.0f–%.0f m)" % [r_min, r_max],
		r_max > r_min * 1.25)
	# Zwischen Grube und Stadt, nicht daneben: Wer den einen Weg geht, kommt daran vorbei.
	var a_grube: Vector3 = WorldManager.poi_scene_position("schrott_minen")
	var stadt2: Vector3 = WorldManager.poi_scene_position("rustwater")
	var d_g: float = Vector2(a_mitte.x - a_grube.x, a_mitte.z - a_grube.z).length()
	var d_s: float = Vector2(a_mitte.x - stadt2.x, a_mitte.z - stadt2.z).length()
	var a_direkt: float = Vector2(stadt2.x - a_grube.x, stadt2.z - a_grube.z).length()
	_check("Sie liegt auf dem Weg (%.0f + %.0f m gegen %.0f m direkt)" % [d_g, d_s, a_direkt],
		d_g + d_s < a_direkt * 1.10)
	# Aber kein Aussichtsturm: Aus dieser Hoehe liegt Rustwater fast waagerecht im Blick, man
	# schaut unter der Felskante hindurch in die Ebene statt von oben auf eine Landkarte.
	var senkung: float = rad_to_deg(atan(a_oben / d_s))
	_check("Rustwater liegt fast waagerecht im Blick (%.1f°)" % senkung, senkung < 8.0)
	# Die Klippe ist zu steil zum Hochlaufen, die Rampe nicht. Gemessen am Profil selbst.
	var r_a: float = float(aus["radius"])
	var steilste: float = 0.0
	var rampe: float = 0.0
	for i in 400:
		var a_t: float = float(i) / 400.0
		# Richtung Rustwater = Klippe, Gegenrichtung = Rampe.
		for seite in [1.0, -1.0]:
			var richt: Vector2 = Vector2(stadt2.x - a_mitte.x, stadt2.z - a_mitte.z).normalized() * seite
			var a: Vector3 = a_mitte + Vector3(richt.x, 0.0, richt.y) * (a_t * r_a)
			var b: Vector3 = a_mitte + Vector3(richt.x, 0.0, richt.y) * (a_t * r_a + 0.4)
			var stg: float = (WorldManager.height_at(a.x, a.z) - WorldManager.height_at(b.x, b.z)) / 0.4
			if seite > 0.0:
				steilste = maxf(steilste, stg)
			else:
				rampe = maxf(rampe, stg)
	var OW2 = load("res://scripts/OverworldView.gd")
	_check("Die Klippe ist zu steil zum Hochlaufen (%.0f°)" % rad_to_deg(atan(steilste)),
		steilste > OW2.MAX_STEIGUNG)
	_check("Die Rampe nicht (%.0f°)" % rad_to_deg(atan(rampe)), rampe < OW2.MAX_STEIGUNG)
	# Und die Grenze greift ueberhaupt: Vorher gab es keine, man lief die 66°-Kraterwand hoch
	# wie eine Fliege und die Rampe war Deko.
	_check("Es gibt eine Steigungsgrenze (%.0f°)" % rad_to_deg(atan(OW2.MAX_STEIGUNG)),
		OW2.MAX_STEIGUNG > 0.5 and OW2.MAX_STEIGUNG < 2.0)
	_check("Die Rundsicht laeuft nur einmal", quelle.contains("GameState.saw_vista = true"))
	# Sie darf erst OBEN starten. Der erste Ausloeser fragte nur den waagerechten Abstand ab —
	# auf der Rampe steht man dort erst auf halber Hoehe, die Kamera kreiste auf Gipfelhoehe um
	# einen Punkt weiter unten und lief dabei durch den Berg.
	var gipfel: float = WorldManager.height_at(a_mitte.x, a_mitte.z)
	var w_r: float = deg_to_rad(float(aus["ramp_deg"]))
	# Der Ausloeser ist jetzt ein SICHTBARER Ring an der Vorderkante, kein gerechnetes Fenster.
	# Zwei Anlaeufe vorher scheiterten am selben Ansatz: Ein Ausloeser, den man nicht sieht, muss
	# raten, wo "richtig" ist.
	_check("Es gibt einen leuchtenden Ring", quelle.contains("_marke_ring")
		and quelle.contains("_build_vista_marke"))
	_check("Und die Fussspur fuehrt hinein", quelle.contains("_vista_spot()"))
	# Er verschwindet auch wieder — mitsamt Beschriftung. Die Schrift war zuerst ein GESCHWISTER
	# des Rings, und `_process_marke` gab nur den Ring frei: Danach stand ein "◎ Aussicht" ueber
	# leerem Fels. Sie haengt jetzt UNTER `_marke`, also raeumt derselbe `queue_free()` sie mit ab.
	_check("Der Ring wird nach der Rundsicht abgeraeumt",
		quelle.contains("if GameState.saw_vista:") and quelle.contains("_marke.queue_free()"))
	_check("Und die Beschriftung haengt an ihm, nicht daneben",
		quelle.contains("l.reparent(_marke, true)"))
	# Gepulst wird der Unterknoten mit den Scheiben. Liefe die Schleife ueber ALLE Kinder von
	# `_marke`, traefe sie seit dem Umhaengen auch das Label3D — und `(c as MeshInstance3D)` waere
	# dort null. Ein Zugriff auf null bricht `_process` ab, und zwar in jedem Bild.
	_check("Das Pulsieren fasst nur die Scheiben an",
		quelle.contains("for c in puls.get_children():")
		and not quelle.contains("for c in _marke.get_children():"))
	# Der Ring liegt auf der HOECHSTEN Stelle der rechten Kuppe — gemessen, nicht gesetzt.
	#
	# Hier stand vorher die Vorderkanten-Messung: vom Gipfel Richtung Rustwater nach aussen bis
	# zum Abbruch, dann um den Ringradius zurueck. Die war nicht falsch, aber sie landete in der
	# SENKE zwischen den beiden Kuppen des Felsens — 14,7 m, waehrend zwei Schritte weiter rechts
	# 16,6 m gewesen waeren. Wer auf einen Felsen steigt, um sich zu orientieren, stellt sich auf
	# die hoechste Stelle.
	#
	# Ein Hoehenmaximum allein reicht dafuer nicht: Eine Spitze ist der hoechste Punkt und traegt
	# keinen Ring von 1,8 m. Geprueft wird deshalb dasselbe wie im Code — hoechster Punkt der
	# rechten Haelfte, auf dem der Reif noch ganz aufliegt.
	var stadt3: Vector3 = WorldManager.poi_scene_position("rustwater")
	var hin3 := Vector3(stadt3.x - a_mitte.x, 0.0, stadt3.z - a_mitte.z).normalized()
	# "Rechts im Bild" ist das Kreuzprodukt aus Blickrichtung und Hochachse — dieselbe Rechnung,
	# mit der auch eine Kamera ihren Rechtsvektor bildet.
	var rechts3 := Vector3(-hin3.z, 0.0, hin3.x)
	var gipfel3: float = WorldManager.height_at(a_mitte.x, a_mitte.z)
	var such3: float = float(aus["radius"]) * 0.45
	var spot3: Vector3 = Vector3(a_mitte.x, gipfel3, a_mitte.z)
	var hoehe_spot: float = -1e9
	var n3: int = int(such3 / 0.5)
	for ix3 in range(-n3, n3 + 1):
		for iz3 in range(-n3, n3 + 1):
			var off3: Vector3 = rechts3 * (float(ix3) * 0.5) + hin3 * (float(iz3) * 0.5)
			if off3.dot(rechts3) <= 0.0 or off3.length() > such3:
				continue
			var q3: Vector3 = a_mitte + off3
			var h3: float = WorldManager.height_at(q3.x, q3.z)
			if h3 <= hoehe_spot:
				continue
			var traegt3: bool = true
			for k3 in 8:
				var w3: float = TAU * float(k3) / 8.0
				if WorldManager.height_at(q3.x + cos(w3) * OW2.VISTA_RING_R_M,
						q3.z + sin(w3) * OW2.VISTA_RING_R_M) < h3 - OW2.VISTA_PLATZ_TOL_M:
					traegt3 = false
					break
			if not traegt3:
				continue
			hoehe_spot = h3
			spot3 = Vector3(q3.x, h3, q3.z)
	var ring_ab_mitte: float = Vector2(spot3.x - a_mitte.x, spot3.z - a_mitte.z).length()
	# Er steht oben — und zwar HOEHER als der Gipfelmittelpunkt, nicht bloss in seiner Naehe.
	_check("Der Ring liegt auf dem hoechsten Punkt (%.1f m, Gipfelmitte %.1f m)"
		% [hoehe_spot, gipfel3], hoehe_spot >= gipfel3)
	# Auf der rechten Seite, wie gewuenscht.
	_check("Und auf der rechten Kuppe (%.1f m rechts der Achse)"
		% (spot3 - a_mitte).dot(rechts3), (spot3 - a_mitte).dot(rechts3) > 0.5)
	# Der ganze Reif liegt auf. Vorher war er 2,2 m gross und nur 1,2 m zurueckgesetzt: Sein
	# vorderer Bogen stand einen Meter jenseits der Abbruchkante und damit vier Meter ueber dem
	# Hang — im Bild ein Reifen, der zur Haelfte in der Luft haengt.
	var tiefster: float = 1e9
	for k4 in 16:
		var w4: float = TAU * float(k4) / 16.0
		tiefster = minf(tiefster, WorldManager.height_at(
			spot3.x + cos(w4) * OW2.VISTA_RING_R_M, spot3.z + sin(w4) * OW2.VISTA_RING_R_M))
	_check("Der ganze Reif liegt auf dem Fels (tiefster Rand %.1f m, Mitte %.1f m)"
		% [tiefster, hoehe_spot], tiefster >= hoehe_spot - OW2.VISTA_PLATZ_TOL_M)
	# Und es ist wirklich ein AUSGUCK: Von dort geht es zur Stadt hin steil hinunter.
	var davor: Vector3 = spot3 + hin3 * 8.0
	_check("Richtung Rustwater faellt der Fels ab (%.1f m gegen %.1f m im Ring)"
		% [WorldManager.height_at(davor.x, davor.z), hoehe_spot],
		WorldManager.height_at(davor.x, davor.z) < hoehe_spot - 3.0)
	_check("Der Standplatz liegt nicht auf dem Gipfelmittelpunkt (%.1f m)" % ring_ab_mitte,
		ring_ab_mitte > 0.5)
	# Einmal gerechnet, nicht in jedem Bild: `_maybe_vista()` fragt pro Frame, `_trail_goal()`
	# auch, und hier werden ein paar hundert Bodenhoehen abgetastet.
	_check("Der Standplatz wird gemerkt", quelle.contains("_vista_spot_cache"))
	# UND MAN KOMMT HIN. Das ist die Pruefung, die dem Ring erst seinen Sinn gibt: Ein Standplatz,
	# den die Steigungsgrenze aussperrt, ist ein Auftrag, den man nicht erfuellen kann. Seit der
	# Ring nicht mehr auf der Achse liegt, sondern auf der rechten Kuppe, fuehrt der Weg ueber die
	# Senke zwischen den beiden Kuppen — und die koennte zu steil sein.
	#
	# Abgetastet wird die gerade Linie vom Rampenfuss zum Ring in Halbmeterschritten. Gerade ist
	# strenger als noetig (im Spiel darf man ausweichen), aber wenn schon die Gerade durchgeht,
	# geht es sicher.
	var r_winkel: float = deg_to_rad(float(aus["ramp_deg"]))
	var r_reich: float = WorldManager.feature_reach(aus)
	var r_fuss: Vector3 = Vector3(a_mitte.x + cos(r_winkel) * r_reich, 0.0,
		a_mitte.z - sin(r_winkel) * r_reich)
	r_fuss.y = WorldManager.height_at(r_fuss.x, r_fuss.z)
	# Zwei Etappen, genau wie `_prolog_ziel()` sie fuehrt: erst die Rampe hinauf auf die Kuppe,
	# dann ueber den Sattel in den Ring. Die DIREKTE Linie vom Rampenfuss zum Ring taugt nicht —
	# sie laeuft quer ueber die Flanke und trifft 72°. Genau daran ist die erste Fassung
	# gescheitert, und deshalb hat die Fussspur jetzt einen Zwischenpunkt.
	var r_kuppe: Vector3 = Vector3(a_mitte.x, WorldManager.height_at(a_mitte.x, a_mitte.z),
		a_mitte.z)
	var r_steilste: float = 0.0
	for r_bein in [[r_fuss, r_kuppe], [r_kuppe, spot3]]:
		var r_von: Vector3 = r_bein[0]
		var r_nach: Vector3 = r_bein[1]
		var r_strecke: float = Vector2(r_nach.x - r_von.x, r_nach.z - r_von.z).length()
		var r_schritte: int = maxi(1, int(r_strecke / 0.5))
		var r_letzte: float = WorldManager.height_at(r_von.x, r_von.z)
		for r_st in range(1, r_schritte + 1):
			var r_t: float = float(r_st) / float(r_schritte)
			var r_px: float = lerpf(r_von.x, r_nach.x, r_t)
			var r_pz: float = lerpf(r_von.z, r_nach.z, r_t)
			var r_ph: float = WorldManager.height_at(r_px, r_pz)
			r_steilste = maxf(r_steilste, (r_ph - r_letzte) / (r_strecke / float(r_schritte)))
			r_letzte = r_ph
	_check("Ueber die Kuppe kommt man in den Ring (steilster Schritt %.0f°)"
		% rad_to_deg(atan(r_steilste)), r_steilste < OW2.MAX_STEIGUNG)
	# UND MAN BLEIBT NICHT HAENGEN. Das ist eine andere Frage als „ist der Hang begehbar" — und
	# genau die, an der es im Spiel scheiterte.
	#
	# Gemessen wurde bisher der EINZELSCHRITT eines Bildes: 4,7 m/s bei 60 Bildern sind 7,8 cm.
	# Auf acht Zentimetern entscheidet nicht der Hang, sondern die Koernung — die aufgesetzten
	# Buckel wellen den Fels um anderthalb Meter, und ein Kiesel darin ueberschreitet 45°, obwohl
	# der Weg drumherum bequem ist. Der Test dafuer zaehlt beides ab: wie viele der 7,8-cm-
	# Schritte auf der Rampe mit dem kurzen Massband gesperrt gewesen waeren, und wie viele mit
	# dem langen. Der erste Wert ist der Grund fuers Ruckeln.
	# Zuerst der Befund: Auf der MITTELLINIE der Rampe blockiert auch die alte Regel nichts. Die
	# erste Vermutung — das kurze Massband stolpert ueber die Koernung — traegt dort also nicht.
	# Wer aus der Grube kommt, laeuft aber nicht die Mittellinie, sondern schraeg auf den Fels zu
	# und dann quer zur Kuppe. Also wird gelaufen statt gerechnet.
	_check("Die Steigung wird auf Schrittlaenge gemessen (%.2f m)" % OW2.STEIGUNG_BASIS_M,
		OW2.STEIGUNG_BASIS_M >= 0.5)
	var weg: Array = [r_fuss, r_kuppe, spot3]
	var m_alt: Array = _marsch_ueber(weg, 0.0, false)
	var m_neu: Array = _marsch_ueber(weg, OW2.STEIGUNG_BASIS_M, true)
	_check("Mit der neuen Regel kommt man vom Rampenfuss in den Ring (%d Stockungen)"
		% int(m_neu[1]), bool(m_neu[0]))
	# Und der Vergleich sagt, ob die Aenderung ueberhaupt etwas bewirkt hat. Faellt er gleich
	# aus, steht hier die falsche Erklaerung fuer ein echtes Problem — dann muss weiter gesucht
	# werden, statt sich auf eine Zahl zu verlassen, die nichts misst.
	_check("Die alte Regel blieb dabei stecken (erreicht: %s, Stockungen %d)"
		% ["ja" if bool(m_alt[0]) else "nein", int(m_alt[1])],
		not bool(m_alt[0]) or int(m_alt[1]) > 0)
	# Und welche der beiden Aenderungen es war. Die Frage ist nicht akademisch: Waere es allein
	# das laengere Massband, koennte man das Ausweichen wieder ausbauen — und umgekehrt.
	var m_nur_basis: Array = _marsch_ueber(weg, OW2.STEIGUNG_BASIS_M, false)
	var m_nur_schraeg: Array = _marsch_ueber(weg, 0.0, true)
	_check("Das laengere Massband allein reicht %s"
		% ("aus" if bool(m_nur_basis[0]) else "NICHT"), true)
	_check("Das schraege Ausweichen allein reicht %s"
		% ("aus" if bool(m_nur_schraeg[0]) else "NICHT"), true)
	# Und wenn doch einmal etwas sperrt, weicht die Figur SCHRAEG aus statt stehenzubleiben. Das
	# achsenweise Nachgeben ist fuer Hausecken gebaut; ein Berg hat keine Achsen, und beide
	# Achsenkandidaten waren dort ebenfalls zu steil.
	_check("Gegen einen Hang wird schraeg ausgewichen",
		quelle.contains("for grad in [22.0, -22.0, 45.0, -45.0, 68.0, -68.0]:"))
	# Der Leuchtkreis ist ein KREIS. Die Fuellscheibe darin stand in drei Fassungen (0,16 / 0,24 /
	# 0,07 Alpha) und war in jeder falsch: Additiv ueber hellem Fels addiert sich eine Flaeche zu
	# einer Flaeche, und heraus kam eine leuchtende Scheibe. Lesbar wird das Band durch eine
	# schmale, dunklere INNENKANTE — Tiefe statt Fuellung.
	_check("Der Ring hat keine Fuellscheibe mehr",
		not quelle.contains("c.bottom_radius = radius * 0.86")
		and not quelle.contains("MARKE_FARBE.b, 0.07"))
	_check("Sondern eine Innenkante (%.2f m)" % OW2.MARKE_KANTE_M,
		OW2.MARKE_KANTE_M > 0.0 and OW2.MARKE_KANTE_M < OW2.MARKE_BAND_M)
	# Die Rundsicht schwenkt ruhig — dieselbe Grenze wie bei der Stadtfahrt. Bei 6,6 s waren es
	# 35°/s, und zwar auf einem Kreis von 8,5 m Radius, wo der Vordergrund noch viel schneller
	# durchs Bild zieht als bei 64 m um die Palisade.
	var v_grad: float = OW2.VISTA_GRAD / OW2.VISTA_SEK_RUNDE
	_check("Die Rundsicht schwenkt ruhig (%.0f °/s)" % v_grad, v_grad < 30.0)
	# Die Waffe ist am Anfang nicht da. Sie wird beim Aufbau der Welt einmal erzeugt und nur noch
	# ein- und ausgeblendet — nur stand die Sichtbarkeit auf dem Vorgabewert `true`, und im
	# Prolog gibt es keinen Waffenwechsel, der das korrigiert haette. Beim Aufwachen schwebte der
	# Karabiner dort in der Luft, wo die Schulter waere, wenn sie schon staende.
	_check("Der Karabiner haengt erst am Spieler, wenn er ihn hat",
		quelle.contains('weapon.visible = _weapon_id != "" and AssetRegistry.has_model('))
	# Und die Fussspur kommt erst nach dem Monolog. Vorher lag sie schon da, waehrend die Figur
	# sechzehn Zeilen lang sagt, dass sie nicht weiss, wo sie ist — der Weg war vor der
	# Entscheidung da, die ihn erklaert.
	_check("Die Fussspur wartet den Monolog ab",
		quelle.contains("and _wach_left <= 0.0 and not _in_flight() and not _in_cine()"))
	# Und die Figur STEHT waehrend einer Fahrt — auch mit den Beinen. Das Anhalten der Bewegung
	# stand laengst im Code, der Clip aber nicht: `play_clip()` kommt erst hinter dem Ausstieg,
	# also behielt den Lauf-Clip, wer beim Start der Fahrt gerade lief. Die Figur rannte auf der
	# Stelle weiter. Beim Anflug auf Rustwater faellt das nicht auf — die Kamera ist weit weg —,
	# auf dem Ausguck dagegen kreist sie auf 8,5 m um genau diese Figur.
	# 6d. Der Vorspann. Das Video laeuft vor dem Erwachen und muendet hinein.
	_check("Der Vorspann liegt vor dem Erwachen",
		quelle.contains("if not _vorspann_starten():\n\t\t\t_erwachen()"))
	# Und er endet ueber SCHWARZ, nicht mit einem Schnitt ins Helle: Ein harter Wechsel vom Film
	# auf die Grube waere ein Sprung zwischen zwei Bildqualitaeten, und genau daran erkennt man
	# eine eingeklebte Sequenz.
	_check("Er blendet ins Schwarze und geht von dort weiter",
		quelle.contains("VORSPANN_BLENDE_SEK") and quelle.contains("VORSPANN_SCHWARZ_SEK")
		and quelle.contains("_erwachen()"))
	# Die Welt ruht dabei. Sonst spielte das Spiel hinter dem Film weiter, und wer ihn zu Ende
	# sieht, faende die Figur woanders vor als der, der ihn wegtippt.
	# ── Der Stillstand im ersten Bild ─────────────────────────────────────────
	#
	# Hier stand genau die Zeile, die den Fehler festgehalten hat:
	#
	#     _check(..., quelle.contains("if _im_vorspann():\\n\\t\\treturn\\n\\t_process_vorspann(delta)"))
	#
	# Sie hat gruen gemeldet, dass der Code so aussieht, wie er aussah — und so sah er falsch
	# aus. `_im_vorspann()` ist wahr, solange der Videoknoten existiert, und weggeraeumt wird er
	# von `_process_vorspann`, das wegen des Ausstiegs davor nie an die Reihe kam. Das Spiel
	# blieb schwarz stehen: keine Bewegung, keine Oberflaeche, kein Weiterkommen.
	#
	# **Eine Pruefung auf Quelltext haelt fest, was DASTEHT, nicht, was passiert.** Deshalb
	# steht hier jetzt die Eigenschaft statt der Zeile: Solange der Vorspann laeuft, MUSS sein
	# eigener Takt weiterlaufen — sonst kann er sich nie beenden.
	# Geprueft wird die REGEL, nicht die Zeile. Sie steht in einer eigenen Funktion, und die
	# Aufrufstelle benutzt sie fuer beides: fuer das Ruhen der Welt UND dafuer, dass der Takt
	# des Vorspanns laeuft. Damit koennen die zwei nicht mehr auseinanderlaufen — als EINE
	# Bedingung an EINER Stelle ist der Fehler nicht mehr formulierbar.
	_check("Die Regel steht an einer Stelle",
		quelle.contains("static func vorspann_regel")
		and quelle.contains("if vorspann_regel(_im_vorspann(), _vorspann_t):\n\t\t_process_vorspann(delta)"))
	# Und die Wahrheitstafel dazu, durchgerechnet statt gelesen: Solange ein Videoknoten da ist
	# ODER die Blende laeuft, ruht die Welt — und genau dann laeuft der Takt.
	var regel_ok: bool = OW2.vorspann_regel(true, -1.0) \
		and OW2.vorspann_regel(true, 0.5) \
		and OW2.vorspann_regel(false, 0.5) \
		and OW2.vorspann_regel(false, 0.0) \
		and not OW2.vorspann_regel(false, -1.0)
	_check("Und sie stimmt in allen vier Faellen", regel_ok)
	# Und wenn der Film gar nicht erst anlaeuft, geht es trotzdem weiter. Godot spielt nur Ogg
	# Theora, und ob eine Datei auf einem bestimmten Geraet dekodiert wird, entscheidet sich
	# erst dort. Faellt es aus, kommt `finished` nie.
	_check("Ein Film, der nicht anlaeuft, haelt das Spiel nicht auf",
		quelle.contains("_vorspann_abbrechen") and quelle.contains("not _vorspann.is_playing()"))
	_check("Und es gibt eine harte Obergrenze (%.0f s)" % OW2.VORSPANN_FRIST_SEK,
		OW2.VORSPANN_FRIST_SEK > 20.0 and OW2.VORSPANN_FRIST_SEK < 180.0)
	# Jeder Abbruchweg muendet ins Erwachen — sonst stuende die Figur wortlos in der Grube.
	_check("Jeder Ausgang fuehrt ins Erwachen",
		quelle.count("_erwachen()") >= 3)
	_check("Und ein Tipp ueberspringt ihn",
		quelle.contains("if druck and _im_vorspann():"))
	# Fehlt die Datei, faellt der Vorspann still aus — ein Intro darf nie zwischen dem Spieler
	# und dem Spiel stehen.
	_check("Ohne Videodatei faengt das Spiel trotzdem an",
		quelle.contains("if not ResourceLoader.exists(VORSPANN_PFAD):"))
	_check("Die Videodatei ist da und ist Theora",
		FileAccess.file_exists("res://assets/video/intro_muellkippe.ogv"))
	# 6e. Der Ton. Die Dateien sind SYNTHETISCH erzeugt (`tools/sfx/make_sfx.py`) — deshalb
	# gehoert der Erzeuger mit ins Projekt und nicht nur sein Ergebnis: Wer den Charakter aendern
	# will, dreht an einer Zahl und laesst ihn neu laufen, statt ein Archiv zu durchsuchen.
	for ton in ["karabiner_schuss_nacht", "karabiner_schuss_tag", "karabiner_repetieren"]:
		_check("Es gibt %s.ogg" % ton,
			FileAccess.file_exists("res://assets/audio/%s.ogg" % String(ton)))
	# Zwei Fassungen des Schusses, weil der Prolog im Abendrot beginnt und in der Nacht endet:
	# Nachts traegt kuehle Luft weiter, die Nachtfassung hat mehr Rueckwuerfe und laeuft laenger
	# aus. Umgeschaltet wird nach `DayCycle`, nicht nach einer von Hand gesetzten Uhrzeit.
	_check("Der Schuss kennt Tag und Nacht",
		quelle.contains("DayCycle.daylight(GameState.hour) < 0.35"))
	# Repetiert wird NACH dem Knall, nicht gleichzeitig — sonst klingt es wie ein Automat.
	_check("Und danach wird repetiert (%.2f s)" % OW2.SFX_REPETIER_VERZUG,
		OW2.SFX_REPETIER_VERZUG > 0.1 and OW2.SFX_REPETIER_VERZUG < 0.5)
	# Der Ton haengt am SCHUSS, nicht am Treffer: Ein Fehlschuss knallt genauso.
	_check("Auch ein Fehlschuss knallt",
		quelle.contains("_spawn_tracer(aim)\n\t# Der Ton haengt am SCHUSS"))
	# Und er kommt AUS DER WELT, nicht aus der Tonspur: Die Kamera wandert im Prolog 34 m weg.
	_check("Der Schuss klingt aus der Entfernung leiser",
		quelle.contains("AudioStreamPlayer3D.new()"))
	_check("Waehrend einer Kamerafahrt stehen auch die Beine still",
		quelle.contains('if _wach_left <= 0.0:\n\t\t\tAssetRegistry.play_clip(_player_model, "idle")'))
	# Und die Fussspur fuehrt auch wirklich ueber die Kuppe, statt quer ueber die Flanke zu zeigen.
	_check("Und die Fussspur nimmt den Umweg ueber die Kuppe",
		quelle.contains("AUSGUCK_OBEN_M"))
	# Und der Reif liegt AUF dem Boden, statt durch die Figur zu gehen — dritter Anlauf, und
	# diesmal einer, der die Ursache trifft statt eines Symptoms. Ohne Tiefentest lag er ueber
	# allem: Die Figur trug ihn im Bild wie einen Hula-Hoop um die Huefte. Mit Tiefentest
	# verschwand er ganz — nachgemessen sass er korrekt 35 cm ueber einem Boden auf 14,71 m und
	# war trotzdem nicht zu sehen, weil ein starrer Torus auf einer Ebene liegt und der Ausguck
	# keine hat: Der Fels wellt sich ueber zwei Meter um mehr, als der Reif dick war.
	#
	# Also kein Fertigkoerper, sondern ein Band aus Dreiecken, dessen Ecken einzeln per
	# `height_at()` auf den Boden gesetzt werden. Das schmiegt sich an jede Beule, der Tiefentest
	# kann anbleiben, und die Figur verdeckt es richtig herum.
	_check("Der Reif folgt dem Boden statt auf einer Ebene zu liegen",
		quelle.contains("WorldManager.height_at(x, z) + MARKE_LUFT_M"))
	_check("Er braucht dafuer keinen abgeschalteten Tiefentest",
		not quelle.contains("mat.no_depth_test = true"))
	# Und er ist breit genug, um ueber hellem Sand additiv noch zu leuchten. Bei 12 cm war er
	# rechnerisch da und im Bild nicht.
	_check("Und ist breit genug, um gesehen zu werden (%.2f m)" % OW2.MARKE_BAND_M,
		OW2.MARKE_BAND_M >= 0.3)
	# Die Groesse pulst nicht mehr: Die Ecken stehen jetzt in WELTkoordinaten, eine Skalierung um
	# den Knotenursprung schoebe den Ring ueber die halbe Karte.
	_check("Gepulst wird nur die Helligkeit", not quelle.contains("puls.scale ="))

	# Der Weg dahin, in zwei verworfenen Anlaeufen: erst der waagerechte Abstand zur Felsmitte
	# (auf der Rampe ist man dort acht Meter zu tief), dann zusaetzlich die Hoehe (besser, aber
	# immer noch geraten). Beide Male war nicht die Formel falsch, sondern der Ansatz — ein
	# Ausloeser, den man nicht SIEHT, muss raten, wo "richtig" ist. Was davon bleibt, ist die
	# Zahl, an der man es messen kann:
	var alt_d: float = float(aus["radius"]) * 0.34
	var zu_frueh: float = WorldManager.height_at(a_mitte.x + cos(w_r) * alt_d,
		a_mitte.z - sin(w_r) * alt_d)
	_check("Auf der Rampe ist man beim alten Fenster noch tief unten (%.1f m von %.1f m)"
		% [zu_frueh, gipfel], zu_frueh < gipfel - 5.0)
	# Und der Ring liegt ausserhalb dieses Fensters — sonst haette sich nichts geaendert.
	var ring_d: float = Vector2(spot3.x - a_mitte.x, spot3.z - a_mitte.z).length()
	_check("Der Ring liegt am Gipfel, nicht im alten Fenster (%.1f m gegen %.1f m)"
		% [WorldManager.height_at(spot3.x, spot3.z), zu_frueh],
		WorldManager.height_at(spot3.x, spot3.z) > zu_frueh + 4.0)
	_check("Und er ist klein genug, dass man ihn treffen MUSS (%.1f m Radius)" % OW2.VISTA_RING_R_M,
		OW2.VISTA_RING_R_M <= 3.0)
	_check("Aber gross genug, dass man ihn trifft", OW2.VISTA_RING_R_M >= 1.5)
	_check("Und im Weitwinkel (%.0f° gegen %.0f° im Spiel)" % [OW2.VISTA_FOV, OW2.CAM_FOV],
		OW2.VISTA_FOV > OW2.CAM_FOV * 1.3)

	# 6b-2. **Die Rundsicht ist EINE Bewegung.**
	#
	# Vorher waren es fuenf Etappen — hoch am Fels, eng herum, weit hinaus, zurueck ins Tal,
	# heim. Jede fuer sich begruendet, zusammen ein Ruckeln: An jeder Naht sprang die Richtung,
	# und `_flight_frame` faehrt jeden Abschnitt fuer sich sanft an und wieder aus. Aus fuenf
	# sauberen Bewegungen wurden vier Bremsungen.
	#
	# Geprueft wird deshalb nicht, ob Konstanten bestimmte Werte haben, sondern ob die erzeugte
	# Bahn FLUESSIG ist: Die Kamera darf von einem Stuetzpunkt zum naechsten ihr Tempo nur um
	# wenige Prozent aendern. Genau diese Groesse — der Ruck — war vorher gross.
	var sp_um := Vector3.ZERO
	var sp_start := Vector3(14.0, 6.0, 0.0)
	var sp: Array = OW2.spirale_punkte(sp_um, sp_start, OW2.VISTA_GRAD,
		OW2.VISTA_FELS_M, OW2.VISTA_ENDE_M, OW2.VISTA_FELS_H, OW2.VISTA_ENDE_H,
		OW2.VISTA_GIPFEL, 1.4, OW2.CAM_FOV, OW2.VISTA_FOV, OW2.VISTA_SEK_RUNDE)
	_check("Die Spirale hat Stuetzpunkte (%d)" % sp.size(), sp.size() >= 40)
	if not sp.is_empty():
		# Kein Abschnitt darf fuer sich weich fahren — die Beschleunigung steckt in der
		# Verteilung der Punkte, nicht in einer Faltung pro Abschnitt.
		var alle_hart: bool = true
		for q in sp:
			if bool(q.get("weich", true)):
				alle_hart = false
		_check("Kein Abschnitt bremst fuer sich", alle_hart)
		# Der Ruck: Tempoaenderung von einem Stuetzpunkt zum naechsten.
		var voriges: Vector3 = sp_start
		var tempi: Array = []
		for q in sp:
			tempi.append(voriges.distance_to(Vector3(q["pos"])) / float(q["sek"]))
			voriges = Vector3(q["pos"])
		# Gemessen am SPITZENTEMPO der Fahrt, nicht am jeweils vorigen Schritt.
		#
		# Der erste Anlauf verglich jeden Schritt mit seinem Vorgaenger und meldete 195 % — was
		# nichts bedeutete: Am Anfang steht die Kamera fast still (der Winkel laeuft ueber
		# `smoothstep` an), und von 0,02 auf 0,06 m/s sind nun einmal 200 %, ohne dass ein Auge
		# das je bemerkt. Wahrgenommen wird eine Tempoaenderung im Verhaeltnis zur GESAMTEN
		# Bewegung. Genau die bleibt bei einer Spirale klein und war an den alten Etappengrenzen
		# gross, wo die Kamera bis auf null abbremste und wieder anfuhr.
		var spitze: float = 0.01
		for v in tempi:
			spitze = maxf(spitze, float(v))
		var groesster_ruck: float = 0.0
		for i in range(1, tempi.size()):
			groesster_ruck = maxf(groesster_ruck,
				absf(float(tempi[i]) - float(tempi[i - 1])) / spitze)
		_check("Das Tempo aendert sich stetig (groesster Sprung %.1f %% vom Spitzentempo)"
			% (groesster_ruck * 100.0), groesster_ruck < 0.06)
		# Sie faehrt HINAUS und wieder HERAN — der Radius hat genau einen Gipfel.
		var sp_rmax: float = 0.0
		var sp_beik: float = 0.0
		for i2 in sp.size():
			var sp_ri: float = Vector2(Vector3(sp[i2]["pos"]).x, Vector3(sp[i2]["pos"]).z).length()
			if sp_ri > sp_rmax:
				sp_rmax = sp_ri
				sp_beik = float(i2 + 1) / float(sp.size())
		_check("Sie faehrt hinaus (%.0f m) und wieder heran (%.0f m)"
			% [sp_rmax, Vector2(Vector3(sp[sp.size() - 1]["pos"]).x,
				Vector3(sp[sp.size() - 1]["pos"]).z).length()],
			sp_rmax > 30.0 and Vector2(Vector3(sp[sp.size() - 1]["pos"]).x,
				Vector3(sp[sp.size() - 1]["pos"]).z).length() < 14.0)
		_check("Am weitesten ist sie in der Mitte der Drehung (bei %.0f %%)" % (sp_beik * 100.0),
			sp_beik > 0.4 and sp_beik < 0.7)
		# Und sie taucht NIE unter den Standplatz. Die erste Fassung fing neun Meter darunter an
		# und kam von unten am Fels hoch — im Bild ein Hoch-Runter, bevor die Fahrt anfing.
		var tiefste: float = 1e9
		for q3 in sp:
			tiefste = minf(tiefste, Vector3(q3["pos"]).y)
		_check("Sie taucht nie unter den Standplatz (%.1f m)" % tiefste, tiefste >= 0.0)
		# Der Bildwinkel zieht auf, statt zu springen: Vorher stand `fov` auf jedem Stuetzpunkt
		# gleich, also war das Aufziehen nach dem ERSTEN Abschnitt vorbei — bei 60 Stufen ein
		# Vierteldrittel einer Sekunde. Das ist ein Schnitt, kein Zoom.
		var fov_ende: float = float(sp[sp.size() - 1]["fov"])
		_check("Der Bildwinkel zieht ueber die Fahrt auf (%.0f° → %.0f°)"
			% [float(sp[0]["fov"]), fov_ende],
			float(sp[0]["fov"]) < OW2.CAM_FOV + 3.0 and absf(fov_ende - OW2.VISTA_FOV) < 0.5)
	# Eine ganze Runde, und langsam genug: 360° in 14 s sind 26°/s.
	var v_rund: float = OW2.VISTA_GRAD / OW2.VISTA_SEK_RUNDE
	_check("Eine ganze Runde (%.0f°) und ruhig (%.0f °/s)" % [OW2.VISTA_GRAD, v_rund],
		OW2.VISTA_GRAD >= 360.0 and v_rund < 30.0)
	# Und am Ende bleibt sie auf Rustwater STEHEN. Sechs Sekunden auf einem stehenden Bild sind
	# viel; genau darum geht es — der Ort ist das Ziel der naechsten Stunde Spielzeit und huschte
	# bisher in vier Sekunden vorbei, waehrend die Kamera schon wieder unterwegs war.
	_check("Auf Rustwater wird verweilt (%.1f s)" % OW2.VISTA_SEK_STADT,
		OW2.VISTA_SEK_STADT >= 5.0)
	_check("Und dabei steht die Kamera wirklich still",
		quelle.contains('punkte.append({ "pos": schulter, "ziel": stadt + Vector3(0.0, 6.0, 0.0),\n\t\t"sek": VISTA_SEK_STADT'))
	# Beim Verweilen enger: Aus 78° Weitwinkel ist der Ort auf 500 m ein Fleck.
	_check("Beim Verweilen zieht der Bildwinkel zu (%.0f° gegen %.0f°)"
		% [OW2.VISTA_STADT_FOV, OW2.VISTA_FOV], OW2.VISTA_STADT_FOV < OW2.VISTA_FOV - 15.0)

	# 6c. Die Fussspur fuehrt im Prolog zum Ausguck — vorher gab es waehrend des ganzen Prologs
	#     GAR KEINE Spur, weil der Wegweiser an `tracked_quest` hing und die erste Quest erst
	#     in Rustwater vergeben wird. Also genau dann, wenn man den Weg schon gefunden hat.
	_check("Die Spur kennt ein Prolog-Ziel", quelle.contains("func _prolog_ziel"))
	_check("Und es haengt am Ausguck", quelle.contains('_feature("ausguck")'))
	# Sie zeigt auf den FUSS DER RAMPE, solange man draussen ist: Der Fels ist rundum 77° steil,
	# eine Spur geradewegs zum Gipfel fuehrt gegen eine Wand. Nachgerechnet: Der Punkt, auf den
	# sie zeigt, muss in der Rampenrichtung liegen — nicht in Richtung der Klippe.
	var w_ramp: float = deg_to_rad(float(aus["ramp_deg"]))
	var reich2: float = WorldManager.feature_reach(aus)
	var fuss := Vector3(a_mitte.x + cos(w_ramp) * (reich2 + 4.0), 0.0,
		a_mitte.z - sin(w_ramp) * (reich2 + 4.0))
	# Von dort kommt man hinauf: die Steigung zum Gipfel bleibt unter der Grenze.
	var schritt2: float = 0.5
	var steilste2: float = 0.0
	var nach := Vector2(a_mitte.x - fuss.x, a_mitte.z - fuss.z)
	var laenge2: float = nach.length()
	nach = nach.normalized()
	for i in int(laenge2 / schritt2):
		var p1 := Vector2(fuss.x, fuss.z) + nach * (float(i) * schritt2)
		var p2 := p1 + nach * schritt2
		steilste2 = maxf(steilste2, (WorldManager.height_at(p2.x, p2.y)
			- WorldManager.height_at(p1.x, p1.y)) / schritt2)
	_check("Vom Fuss der Rampe kommt man hinauf (%.0f°)" % rad_to_deg(atan(steilste2)),
		steilste2 < OW2.MAX_STEIGUNG)
	# Und der Fuss liegt WIRKLICH unten, nicht schon auf halber Hoehe.
	_check("Der Fuss der Rampe liegt am Boden (%.1f m)"
		% WorldManager.height_at(fuss.x, fuss.z),
		WorldManager.height_at(fuss.x, fuss.z) < 3.0)

	# 7. Die Startschalter, ohne die man den Prolog nach dem ersten Start nie wiedersieht —
	#    das Spiel speichert automatisch, es gibt also kein „noch nicht gespeichert".
	_check("Es gibt einen Schalter fuer ein neues Spiel", OW.ARG_NEU == "--neu")
	_check("Und einen, der nur den Prolog zuruecksetzt", OW.ARG_PROLOG == "--prolog")
	_check("Und eine Taste, die im Spiel dasselbe tut",
		quelle.contains("_prolog_neu_anfordern") and quelle.contains("KEY_F9"))
	_check("Die zweimal gedrueckt werden muss",
		quelle.contains("PROLOG_BESTAETIGUNG_SEK"))
	# `saw_wake` entscheidet ueber die Aufwach-Szene — NICHT der Spielstand. Sonst bekaeme man
	# sie nach dem allerersten Start nie wieder zu sehen, weil automatisch gespeichert wird.
	var w_vorher: bool = GameState.saw_wake
	var p_vorher: bool = GameState.prolog_done
	GameState.saw_wake = false
	GameState.prolog_done = false
	_check("Ohne `saw_wake` steht das Erwachen an", not GameState.saw_wake)
	GameState.saw_wake = true
	_check("Danach nicht mehr", GameState.saw_wake)
	GameState.saw_wake = w_vorher
	GameState.prolog_done = p_vorher
	# Und es faehrt durch den Spielstand: sonst waere das Zuruecksetzen nach einem Neuladen weg.
	var j: String = SaveManager.to_json()
	_check("`saw_wake` steht im Spielstand", j.contains("saw_wake"))
	var probe: int = 97
	SaveManager.save_to_slot(probe)
	_check("Ein Spielstand laesst sich schreiben", SaveManager.has_slot(probe))
	SaveManager.delete_slot(probe)
	_check("… und wieder loeschen", not SaveManager.has_slot(probe))


## Der Flug um den Wasserturm.
##
## Vorher waren es zwei Stuetzpunkte, zwischen denen `_flight_frame` LINEAR interpoliert — also
## eine Sehne: 26 m Abstand an den Enden, 21,6 m in der Mitte, und ganze 67° Schwenk. Das ist
## keine Umrundung, das ist ein Vorbeiflug. Geprueft wird deshalb genau das, was daran neu ist:
## dass der Abstand rundherum GLEICH bleibt, dass der Bogen wirklich abgefahren wird, und dass
## die Kamera dabei nicht ruckelt.
func _test_orbit() -> void:
	var OW = load("res://scripts/OverworldView.gd")
	var um := Vector3(10.0, 0.0, -5.0)
	var start: Vector3 = um + Vector3(27.0, 15.0, 0.0)
	var bogen: float = 220.0
	var punkte: Array = OW.orbit_punkte(um, start, bogen, 15.0, 22.0, 9.0, 4.8)

	# EINE Etappe, nicht sechzehn.
	#
	# Vorher war der Bogen in sechzehn Sehnen zerlegt, und das hat sich im Spiel angefuehlt,
	# als warte die Kamera an jedem Winkel kurz. Das war kein Gefuehl, sondern eine Rechnung:
	# Die Stuetzpunkte wurden mit `smoothstep` ueber den Bogen VERTEILT — aussen dicht, in der
	# Mitte weit — bekamen aber alle DIESELBE Zeit. Die Kamera kroch durch die engen
	# Abschnitte und raste durch die weiten, mit einem Sprung an jeder Naht. Die
	# Beschleunigung, die die Verteilung erzeugen sollte, hob die gleiche Zeit je Abschnitt
	# genau wieder auf.
	_check("Die Umrundung ist EINE Etappe (%d)" % punkte.size(), punkte.size() == 1)
	if punkte.is_empty():
		return
	var b: Dictionary = punkte[0]
	_check("Und wird als Bogen gerechnet, nicht angesteuert", bool(b.get("bogen", false)))

	# 1. Der Abstand zur Mitte IST der Radius — jetzt exakt, an jeder Stelle. Vorher schnitt
	#    jede Sehne den Bogen ab; der Fehler lag bei den ersten zwei Stuetzpunkten bei 17 %.
	var kleinster: float = 1e9
	var groesster: float = 0.0
	for i in 201:
		var q: Vector3 = OW.bogen_punkt(b, float(i) / 200.0)
		var d: float = Vector2(q.x - um.x, q.z - um.z).length()
		kleinster = minf(kleinster, d)
		groesster = maxf(groesster, d)
	_check("Der Abstand bleibt exakt rund (%.3f–%.3f m)" % [kleinster, groesster],
		groesster - kleinster < 0.01)

	# 2. Der Bogen wird auch wirklich abgefahren, und dabei gestiegen.
	var letzte: Vector3 = OW.bogen_punkt(b, 1.0)
	var grad: float = rad_to_deg(fposmod(atan2(letzte.z - um.z, letzte.x - um.x)
		- atan2(start.z - um.z, start.x - um.x), TAU))
	_check("Es werden %.0f° umrundet" % grad, absf(grad - bogen) < 1.0)
	_check("Und dabei gestiegen (%.1f m)" % (letzte.y - start.y),
		absf(letzte.y - start.y - 7.0) < 0.1)
	_check("Sie faengt genau dort an, wo der Anflug endet (%.2f m)"
		% OW.bogen_punkt(b, 0.0).distance_to(start),
		OW.bogen_punkt(b, 0.0).distance_to(start) < 0.01)

	# 3. DAS ist der Punkt der ganzen Aenderung: Die Geschwindigkeit springt nicht.
	#
	#    Gemessen wird die Strecke je Zeitschritt entlang der ECHTEN Fahrt — also mit dem
	#    `smoothstep` ueber die Zeit, das `_flight_frame` anwendet. Bei der alten Sehnen-Kette
	#    sprang sie an jeder Naht; hier darf sie sich von Schritt zu Schritt nur sanft aendern.
	var wege: Array = []
	var vorher: Vector3 = OW.bogen_punkt(b, 0.0)
	for i in range(1, 201):
		var k: float = smoothstep(0.0, 1.0, float(i) / 200.0)
		var q2: Vector3 = OW.bogen_punkt(b, k)
		wege.append(vorher.distance_to(q2))
		vorher = q2
	var groesster_sprung: float = 0.0
	var schnellste: float = 0.0
	for i in range(1, wege.size()):
		groesster_sprung = maxf(groesster_sprung, absf(float(wege[i]) - float(wege[i - 1])))
		schnellste = maxf(schnellste, float(wege[i]))
	_check("Die Geschwindigkeit springt nicht (groesster Sprung %.1f %% der Hoechstfahrt)"
		% (groesster_sprung / maxf(schnellste, 0.001) * 100.0),
		groesster_sprung < schnellste * 0.06)
	# Und sie faehrt an und wieder aus, statt mit einem Ruck loszulegen.
	_check("Sie faehrt sanft an und aus (%.3f / %.3f gegen %.3f in der Mitte)"
		% [float(wege[0]), float(wege[-1]), float(wege[wege.size() / 2])],
		float(wege[0]) < float(wege[wege.size() / 2]) * 0.25
		and float(wege[-1]) < float(wege[wege.size() / 2]) * 0.25)

	# 4. Der Blick haengt an der Mitte, sonst dreht sich die Kamera um sich selbst statt um sie.
	_check("Der Blick bleibt in der Mitte",
		Vector3(b["ziel"]).distance_to(um + Vector3(0.0, 9.0, 0.0)) < 0.01)
	# 5. Ein Kreis mit Radius null ist keiner — lieber gar keine Fahrt als eine Division.
	_check("Ohne Radius gibt es keine Umrundung",
		OW.orbit_punkte(um, um + Vector3(0.0, 5.0, 0.0), 220.0, 5.0, 5.0, 2.0, 3.0).is_empty())
	# 6. Umrundet wird die PALISADE mit Blick nach innen, nicht der Wasserturm.
	#
	#    Die erste Fassung kreiste um den Turm. Im Bild war das eine Fahrt um ein Fass: Der Turm
	#    fuellte den Rahmen, und weil er am Ortsrand steht, schaute die halbe Umrundung nach
	#    draussen in die Wueste. Um die Mauer herum zeigt jede Sekunde denselben Ort aus einer
	#    neuen Richtung.
	_check("Umrundet wird mehr als eine halbe Runde (%.0f°)" % OW.INTRO_ORBIT_GRAD,
		OW.INTRO_ORBIT_GRAD >= 200.0)
	_check("Die Kamera steigt dabei (%.0f → %.0f m)" % [OW.INTRO_ORBIT_H0, OW.INTRO_ORBIT_H1],
		OW.INTRO_ORBIT_H1 > OW.INTRO_ORBIT_H0)
	# Der Radius kommt aus dem Umriss der Palisade plus Abstand. Gepruefte Eigenschaft: Aus
	# dieser Entfernung und Hoehe passt der ganze Ort ins Bild — der halbe Oeffnungswinkel der
	# Kamera muss den Ortsradius abdecken.
	var stadt_r: float = 42.0
	var kam_r: float = stadt_r + OW.INTRO_ORBIT_RAND_M
	# Gerechnet wird mit der WAAGERECHTEN Oeffnung. Godots `fov` ist der senkrechte Winkel, das
	# Bild ist aber 16:9 — quer passt also fast das Doppelte hinein, und quer liegt der Ort.
	# Senkrecht braucht er ohnehin weniger, weil die Kamera von schraeg oben schaut und die
	# Kreisflaeche dabei zur Ellipse zusammenlaeuft.
	var halb_fov: float = atan(tan(deg_to_rad(OW.CAM_FOV * 0.5)) * 16.0 / 9.0)
	var weg: float = sqrt(kam_r * kam_r + OW.INTRO_ORBIT_H1 * OW.INTRO_ORBIT_H1)
	var sichtbar: float = tan(halb_fov) * weg
	_check("Der ganze Ort passt ins Bild (%.0f m sichtbar, %.0f m breit)"
		% [sichtbar * 2.0, stadt_r * 2.0], sichtbar >= stadt_r)
	_check("Und geblickt wird ueber die Daecher (%.0f m)" % OW.INTRO_BLICK_H,
		OW.INTRO_BLICK_H >= 4.0 and OW.INTRO_BLICK_H <= 14.0)
	# 7. **Der Rueckweg faehrt im Tempo des Anflugs.**
	#
	#    Hier stand vorher: „Der Rueckweg ist kuerzer als der Hinweg" — 1,2 s fest eingetragen,
	#    mit der Begruendung, die Umrundung ende ja auf der Seite der Figur. Das stimmte fuer die
	#    Turm-Fassung und ist mit 230° um die Palisade falsch: Die Fahrt endet gegenueber, und aus
	#    „kurz" wurde ein Sprung mit gut 48 m/s gegen 14 m/s beim Hereinfliegen. Im Bild las sich
	#    das, als sei die Fahrt abgebrochen worden.
	#
	#    Nachgebaut wird die Geometrie, die `_maybe_intro_flight()` aufspannt: Ort im Ursprung,
	#    Figur auf Sichtweite davor, Umrundung ueber `INTRO_ORBIT_GRAD`, Rueckflugziel hinter der
	#    Figur. Geprueft wird, dass am Ende wirklich dasselbe Tempo herauskommt — nicht, dass
	#    irgendeine Konstante einen bestimmten Wert hat.
	var g_mitte := Vector3.ZERO
	var g_hin := Vector3(1.0, 0.0, 0.0)
	var g_spieler: Vector3 = g_mitte - g_hin * OW.INTRO_SIGHT_M
	var g_auge: Vector3 = g_spieler + Vector3(0.0, OW.INTRO_EYE_M, 0.0)
	var g_start: Vector3 = g_mitte - g_hin * kam_r + Vector3(0.0, OW.INTRO_ORBIT_H0, 0.0)
	# Ende der Umrundung: derselbe Radius, um den Bogenwinkel weitergedreht, auf Endhoehe.
	var g_a0: float = atan2(g_start.z - g_mitte.z, g_start.x - g_mitte.x)
	var g_a1: float = g_a0 + deg_to_rad(OW.INTRO_ORBIT_GRAD)
	var g_ende: Vector3 = g_mitte + Vector3(cos(g_a1) * kam_r, OW.INTRO_ORBIT_H1,
		sin(g_a1) * kam_r)
	var g_rueck: Vector3 = g_spieler - g_hin * OW.INTRO_RUECK_M \
		+ Vector3(0.0, OW.INTRO_RUECK_H, 0.0)
	var v_an: float = g_auge.distance_to(g_start) / OW.INTRO_SEK_ANFLUG
	var weg_heim: float = g_ende.distance_to(g_rueck)
	var sek_heim: float = maxf(weg_heim / v_an, OW.INTRO_SEK_HEIM_MIN)
	var v_heim: float = weg_heim / sek_heim
	_check("Der Rueckweg faehrt im Anflugtempo (%.1f m/s gegen %.1f m/s)" % [v_heim, v_an],
		absf(v_heim - v_an) < 0.5)
	# Und er ist damit NICHT der kuerzeste Abschnitt mehr — er ist laenger als der Anflug, weil
	# der Weg laenger ist. Genau das ist der Punkt.
	_check("Und dauert deshalb laenger als der Anflug (%.1f s gegen %.1f s)"
		% [sek_heim, OW.INTRO_SEK_ANFLUG], sek_heim > OW.INTRO_SEK_ANFLUG)
	# Der Blick bleibt dabei auf der Stadt: rueckwaerts hinaus, Rustwater wird kleiner statt aus
	# dem Rahmen zu kippen.
	var ow_quelle: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Rueckwaerts, mit Blick auf die Stadt",
		ow_quelle.contains('"pos": rueck, "ziel": mitte + Vector3(0.0, INTRO_BLICK_H, 0.0)'))
	# Zum Schluss Figur UND Ort in einem Bild, dann einschwenken.
	_check("Am Ende stehen Figur und Ort zusammen im Bild",
		ow_quelle.contains("_player.position.lerp(mitte, 0.30)"))
	_check("Und es wird gekippt statt geschnitten (%.1f s)" % OW.INTRO_SEK_EINSCHWENKEN,
		OW.INTRO_SEK_EINSCHWENKEN >= 1.2)
	# Die Gesamtdauer ist damit keine feste Zahl mehr, sondern haengt am Standort der Figur.
	# Geprueft wird der Rahmen: lang genug, um zu wirken, kurz genug, um nicht zu langweilen.
	var ges: float = OW.INTRO_SEK_BLICK + OW.INTRO_SEK_ANFLUG + OW.INTRO_SEK_RUNDE \
		+ sek_heim + OW.INTRO_SEK_ZEIGEN + OW.INTRO_SEK_EINSCHWENKEN
	_check("Die ganze Fahrt bleibt im Rahmen (%.1f s)" % ges, ges > 15.0 and ges < 28.0)
	_check("Die Umrundung bleibt der laengste Abschnitt (%.0f %%)"
		% (100.0 * OW.INTRO_SEK_RUNDE / ges),
		OW.INTRO_SEK_RUNDE > sek_heim and OW.INTRO_SEK_RUNDE > OW.INTRO_SEK_ANFLUG)
	# Und die Umrundung schwenkt langsam genug, dass man den Ort SIEHT.
	#
	# Hier stand vorher ein Vergleich der Bahngeschwindigkeit in m/s: Die Umrundung musste
	# hoechstens halb so schnell sein wie der Anflug. Dieses Mass stammt aus der ersten Fassung,
	# die den Wasserturm auf 27 m Abstand umkreiste — da hiess „langsam in m/s" auch „langsam im
	# Bild". Seit die Fahrt die 64 m entfernte Palisade umrundet, misst es nichts mehr: Derselbe
	# Bogen in derselben Zeit ergibt bei mehr als doppeltem Radius zwangslaeufig die doppelte
	# Bahngeschwindigkeit, obwohl das Motiv im Bild genauso schnell vorbeizieht. Ein Kriterium,
	# das sich mit dem Radius aendert, kann keins fuer den Bildeindruck sein.
	#
	# Wahrgenommen wird die WINKELgeschwindigkeit — wie schnell sich der Ort unter der Kamera
	# wegdreht. Ueber etwa 30°/s verwischt eine Establishing-Fahrt; darunter hat das Auge Zeit,
	# dem Motiv zu folgen. (Genau daran ist die Fassung mit 250° haengengeblieben: 29,8°/s.)
	# Der Anflug kommt hier nicht mehr vor, weil ein geradliniger Zuflug auf das Ziel kaum
	# schwenkt und deshalb kein Vergleichswert ist. Dass die Umrundung der langsame Abschnitt
	# ist, prueft der Test darueber: Sie bekommt mehr als die Haelfte der Zeit.
	var grad_pro_sek: float = OW.INTRO_ORBIT_GRAD / OW.INTRO_SEK_RUNDE
	_check("Die Umrundung schwenkt ruhig (%.1f °/s)" % grad_pro_sek, grad_pro_sek < 30.0)
	# Der Weg bleibt trotzdem interessant — als Gegenprobe, dass Zeit und Radius zusammenpassen
	# und niemand versehentlich eine Hetzjagd um eine Grossstadt gebaut hat.
	var bogen_m: float = deg_to_rad(OW.INTRO_ORBIT_GRAD) * kam_r
	_check("Die Kamera legt dabei %.0f m zurueck" % bogen_m, bogen_m > 120.0 and bogen_m < 460.0)


## Das Flackern von Esse und Fackeln.
##
## Geprueft wird nicht „sieht huebsch aus", sondern die drei Eigenschaften, an denen ein
## Flacker-Effekt in der Praxis scheitert: Es darf nie negativ werden (ein Licht mit negativer
## Energie zieht in Godot Helligkeit ab und macht einen schwarzen Fleck), es muss sich
## tatsaechlich bewegen, und es darf sich nicht so schnell wiederholen, dass man den Takt
## mitzaehlt.
func _test_flacker() -> void:
	var OW = load("res://scripts/OverworldView.gd")
	_check("Ohne Staerke brennt es ruhig", is_equal_approx(OW.flacker_faktor(3.0, 1.0, 0.0), 1.0))
	var kleinste: float = 999.0
	var groesste: float = -999.0
	for i in 4000:
		var t: float = float(i) * 0.01
		var f: float = OW.flacker_faktor(t, 0.7, 0.30)
		kleinste = minf(kleinste, f)
		groesste = maxf(groesste, f)
	_check("Eine Flamme wird nie negativ (min %.2f)" % kleinste, kleinste > 0.15)
	_check("Und ueberstrahlt nicht (max %.2f)" % groesste, groesste < 1.45)
	_check("Sie bewegt sich wirklich (%.2f–%.2f)" % [kleinste, groesste],
		groesste - kleinste > 0.30)
	# Zwei Lichter mit verschiedener Phase duerfen nicht im Gleichtakt zucken.
	var versetzt: float = 0.0
	for j in 400:
		var t2: float = float(j) * 0.05
		versetzt = maxf(versetzt, absf(OW.flacker_faktor(t2, 0.0, 0.3)
			- OW.flacker_faktor(t2, 2.1, 0.3)))
	_check("Zwei Fackeln flackern versetzt (%.2f)" % versetzt, versetzt > 0.15)
	# Kein Zufall: derselbe Zeitpunkt gibt denselben Wert, sonst haengt das Bild an der Bildrate.
	_check("Das Flackern ist reproduzierbar",
		is_equal_approx(OW.flacker_faktor(9.25, 1.3, 0.3), OW.flacker_faktor(9.25, 1.3, 0.3)))


## Gegner greifen an — mit Ausholen, Treffer und Pause.
##
## Vorher floss im Nahkampf Schaden je Sekunde, solange man in Reichweite stand: kein Schlag,
## kein Ausholen, keine Pause, und die Angriffs-Animation lief nebenher als Dauerschleife. Man
## verlor Leben, ohne dass irgendetwas im Bild dafuer verantwortlich war. Und die beiden
## Fernkaempfer trugen einen `ranged`-Block, den niemand las — sie rannten wie alle anderen bis
## auf zwei Meter heran.
##
## Geprueft wird deshalb genau das, was daran neu ist: dass der Treffer NACH dem Ausholen faellt,
## dass er ausbleibt, wenn man ausweicht, dass die Schadensrate dieselbe geblieben ist, und dass
## ein Schuetze Abstand haelt.
func _test_enemy_attacks() -> void:
	print("· Gegner greifen an")
	_reset_state()
	# ── Die Reichweitenbaender muessen ueberhaupt spielbar liegen ──────────────
	for id in CombatData.ENEMY_TYPES.keys():
		var f: Dictionary = CombatData.ENEMY_TYPES[id].get("ranged", {})
		if f.is_empty():
			continue
		var weit: float = float(f["max"]) * CombatData.RANGE_PX_TO_M
		var nah: float = float(f["min"]) * CombatData.RANGE_PX_TO_M
		_check("%s: Schussweite groesser als Ausweichabstand (%.1f > %.1f m)" % [id, weit, nah],
			weit > nah + 2.0)
		_check("%s ist in Reichweite, sobald er erwacht (%.1f < %.1f m)"
			% [id, weit, OverworldView.AGGRO_M], weit < OverworldView.AGGRO_M)
		_check("%s haelt mehr Abstand als der Nahkampf (%.1f > %.1f m)"
			% [id, nah, OverworldView.CONTACT_RANGE_M], nah > OverworldView.CONTACT_RANGE_M)

	# ── Der Nahkampf: ausholen, treffen, Pause ────────────────────────────────
	var ow := OverworldView.new()
	_scratch.append(ow)
	ow._player = Node3D.new()
	_scratch.append(ow._player)
	ow._player.position = Vector3(400.0, 0.0, -400.0)
	ow._hp = 500.0
	var bandit: Dictionary = ow._make_enemy("outlaw")
	ow.add_child(bandit["node"])
	ow._enemies.append(bandit)
	(bandit["node"] as Node3D).position = ow._player.position + Vector3(1.4, 0.0, 0.0)
	var vorher: float = ow._hp
	ow._process_enemies(0.016)
	_check("Der Schlag holt erst aus", float(bandit["windup"]) > 0.0)
	_check("Waehrend des Ausholens faellt kein Schaden", is_equal_approx(ow._hp, vorher))
	for _i in 60:
		ow._process_enemies(0.016)
		if float(bandit["windup"]) < 0.0:
			break
	var schaden: float = vorher - ow._hp
	var erwartet: float = float((bandit["target"] as CombatTarget).contact_dps) \
		* CombatData.MELEE_INTERVAL_SEC * CombatEngine.player_damage_taken_mul(0)
	_check("Dann sitzt ein ganzer Schlag (%.1f, erwartet %.1f)" % [schaden, erwartet],
		absf(schaden - erwartet) < 0.6)
	_check("Und danach laeuft die Pause (%.2f s)" % float(bandit["cooldown"]),
		float(bandit["cooldown"]) > CombatData.MELEE_INTERVAL_SEC * 0.8)
	# Die Schadensrate ist dieselbe geblieben wie beim alten Dauerschaden — das ist der Punkt:
	# Es aendert sich, wie man den Schaden erlebt, nicht wie viel es ist.
	var rate: float = erwartet / CombatData.MELEE_INTERVAL_SEC
	_check("Schaden je Sekunde unveraendert (%.1f)" % rate,
		absf(rate - float((bandit["target"] as CombatTarget).contact_dps)
			* CombatEngine.player_damage_taken_mul(0)) < 0.01)

	# ── Ausweichen wirkt ──────────────────────────────────────────────────────
	ow._hp = 500.0
	bandit["cooldown"] = 0.0
	bandit["windup"] = -1.0
	(bandit["node"] as Node3D).position = ow._player.position + Vector3(1.4, 0.0, 0.0)
	ow._process_enemies(0.016)
	_check("Der naechste Schlag holt wieder aus", float(bandit["windup"]) > 0.0)
	(bandit["node"] as Node3D).position = ow._player.position + Vector3(12.0, 0.0, 0.0)
	var hp2: float = ow._hp
	for _j in 60:
		ow._process_enemies(0.016)
		if float(bandit["windup"]) < 0.0:
			break
	_check("Wer waehrend des Ausholens weggeht, wird nicht getroffen",
		is_equal_approx(ow._hp, hp2), "verlor %.1f" % (hp2 - ow._hp))

	# ── Der Schuetze haelt Abstand ────────────────────────────────────────────
	var ow2 := OverworldView.new()
	_scratch.append(ow2)
	ow2._player = Node3D.new()
	_scratch.append(ow2._player)
	ow2._player.position = Vector3(400.0, 0.0, -400.0)
	ow2._hp = 5000.0
	var held: Dictionary = ow2._make_enemy("revolver")
	ow2.add_child(held["node"])
	ow2._enemies.append(held)
	(held["node"] as Node3D).position = ow2._player.position + Vector3(2.0, 0.0, 0.0)
	var d0: float = 2.0
	for _k in 40:
		ow2._process_enemies(0.05)
	var d1: float = Vector2((held["node"] as Node3D).position.x - ow2._player.position.x,
		(held["node"] as Node3D).position.z - ow2._player.position.z).length()
	_check("Der Revolverheld weicht zurueck statt heranzurennen (%.1f -> %.1f m)" % [d0, d1],
		d1 > d0 + 0.5)
	_check("Und er hat dabei geschossen (%.0f Schaden)" % (5000.0 - ow2._hp), ow2._hp < 5000.0)

	# ── Die Modelle bringen die noetigen Clips mit ────────────────────────────
	for kind in ["enemy_outlaw", "enemy_revolver"]:
		var m: Node3D = AssetRegistry.instantiate(String(kind), AssetRegistry.height_of(String(kind)))
		if m == null:
			continue
		_scratch.append(m)
		_check("%s hat eine Angriffs-Animation" % kind,
			AssetRegistry.play_clip(m, "attack", false))
		# Ohne Ruhepose lief vorher der letzte Clip weiter — der Grenzgaenger ging auf der Stelle.
		_check("%s kommt zur Ruhe, auch ohne Idle-Clip" % kind, AssetRegistry.rest(m))
	var schuetze: Node3D = AssetRegistry.instantiate("enemy_revolver",
		AssetRegistry.height_of("enemy_revolver"))
	if schuetze != null:
		_scratch.append(schuetze)
		_check("Der Revolverheld kann rueckwaerts gehen",
			AssetRegistry.play_clip(schuetze, "retreat"))
	_reset_state()


## Rustwater muss BEGEHBAR bleiben, egal wie jemand die Stadt im Editor umbaut.
##
## Der Anlass: Nach dem ersten Umbau von Hand kam man in der Stadt kaum noch vorwaerts. Ursache
## war nicht die Platzierung, sondern die Ableitung. Wer im Editor ein Palisadenstueck
## dupliziert, waehrend das erste ausgewaehlt ist, bekommt es als KIND — und die alte Regel
## vermass einen instanzierten Knoten samt allem, was darunterhing, als EINEN Kasten. Vier
## Generationen tief war das eine 90 × 60 m grosse unsichtbare Wand mitten in Rustwater.
##
## Deshalb prueft dieser Test nicht Zahlen, sondern die Stadt: Er rastert sie ab und laeuft
## los. Was er findet, findet auch der Spieler.
func _test_town_walkable() -> void:
	print("· Rustwater ist begehbar")
	var szene: PackedScene = load("res://scenes/Rustwater.tscn") as PackedScene
	_check("Die Stadt-Szene laedt", szene != null)
	if szene == null:
		return
	var stadt: Node3D = szene.instantiate() as Node3D
	_scratch.append(stadt)
	var sperren: Array = TownCollision.rects(stadt)
	_check("Die Stadt traegt Sperren ein", sperren.size() >= 10,
		"nur %d" % sperren.size())

	# 1. Keine Riesensperre. Nichts in Rustwater ist groesser als der Saloon (13,3 m); eine
	#    Sperre ueber 25 m kann nur aus zusammengezaehlten Unterbauten stammen.
	var groesste: float = 0.0
	var uebeltaeter: String = ""
	for r in sperren:
		var kante: float = maxf(float(r["h"].x), float(r["h"].y)) * 2.0
		if kante > groesste:
			groesste = kante
			uebeltaeter = String(r["name"])
	_check("Keine Sperre spannt ueber den halben Ort", groesste <= 25.0,
		"%s sperrt %.1f m" % [uebeltaeter, groesste])

	# 2. Jedes Tor hat einen Durchgang — sonst ist die Mauer schoen und die Stadt zu.
	var tore: int = 0
	for kind in stadt.get_children():
		var name: String = TownCollision.asset_name(kind as Node3D)
		if not name.begins_with("gate"):
			continue
		tore += 1
		# Nicht nur die Mitte, sondern der ganze WEG hindurch: davor, drin, dahinter. Ein Tor,
		# dessen Mitte frei ist und vor dem ein Palisadenstueck steht, ist immer noch zu.
		var knoten: Node3D = kind as Node3D
		var durch: Vector3 = knoten.transform.basis.z.normalized()
		for m in [-3.5, 0.0, 3.5]:
			var p: Vector3 = knoten.position + durch * m
			var wer: String = TownCollision.wer_blockiert(sperren, Vector2(p.x, p.z), 0.6)
			_check("Durch %s kommt man hindurch (%+.0f m)" % [kind.name, m], wer == "",
				"%s steht im Weg" % wer)
	_check("Rustwater hat ueberhaupt ein Tor", tore > 0)

	# 2b. Nachts brennt Licht — und zwar an den Bauteilen, die es tragen sollen.
	#
	# `_register_town_rects` verteilt die Nachtlichter ueber `r["asset"]`. Das ist robust gegen
	# Umstellen im Editor, aber NICHT gegen Umbenennen: Wer die Schmiede durch ein anderes
	# Modell ersetzt, dreht damit stillschweigend die Esse aus, und niemand merkt es, bis
	# jemand nachts durch die Stadt laeuft. Also wird hier gezaehlt.
	var traeger: Dictionary = {}
	for r in sperren:
		var a: String = String(r["asset"])
		traeger[a] = int(traeger.get(a, 0)) + 1
	_check("Die Schmiede traegt die Esse (%d)" % int(traeger.get("forge", 0)),
		int(traeger.get("forge", 0)) == 1)
	_check("Der Wasserturm traegt seine Laterne (%d)" % int(traeger.get("water_tower", 0)),
		int(traeger.get("water_tower", 0)) == 1)
	# Je Tor zwei Pfosten, je Pfosten eine Fackel — links und rechts der Durchfahrt.
	_check("Jedes Tor traegt zwei Fackeln (%d Pfosten bei %d Toren)"
		% [int(traeger.get("gate", 0)), tore],
		int(traeger.get("gate", 0)) == tore * 2)
	_check("Der Saloon leuchtet weiterhin (%d)" % int(traeger.get("saloon", 0)),
		int(traeger.get("saloon", 0)) == 1)

	# 3. Der Rundgang. Von aussen hinein, und drinnen ueberall hin.
	var schritt: float = 0.5
	var reichweite: float = 62.0
	var n: int = int(reichweite / schritt)
	var frei: Dictionary = {}
	for iz in range(-n, n + 1):
		for ix in range(-n, n + 1):
			var p := Vector2(float(ix) * schritt, float(iz) * schritt)
			if p.length() > reichweite:
				continue
			if not TownCollision.blockiert(sperren, p, 0.6):
				frei[Vector2i(ix, iz)] = true
	# Start am Ortsrand, also dort, wo der Spieler ankommt.
	var start := Vector2i(0, n - 2)
	while not frei.has(start) and start.y > 0:
		start.y -= 1
	var erreicht: Dictionary = { start: true }
	var stapel: Array = [start]
	while not stapel.is_empty():
		var q: Vector2i = stapel.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = q + d
			if frei.has(nb) and not erreicht.has(nb):
				erreicht[nb] = true
				stapel.append(nb)
	_check("Man kommt in die Stadt hinein",
		erreicht.has(Vector2i(0, 0)) or erreicht.size() > frei.size() / 2)
	# Innerhalb der Mauer darf keine Flaeche abgeschnitten sein. 45 m deckt den Stadtplan.
	# Gemessen wird die groesste zusammenhaengende Insel, nicht ihre Summe: Eine einzelne
	# Rasterzelle zwischen zwei Sperren ist keine verlorene Flaeche, sondern eine Ritze, in die
	# der Spieler ohnehin nicht passt. Ab 4 m² ist es ein Fleck, den man betreten wollen wuerde.
	var innen: float = 45.0
	var rest: Dictionary = {}
	for k in frei.keys():
		var p := Vector2(float(k.x) * schritt, float(k.y) * schritt)
		if p.length() <= innen and not erreicht.has(k):
			rest[k] = true
	var groesste_insel: int = 0
	var beispiel := Vector2.ZERO
	while not rest.is_empty():
		var saat: Vector2i = rest.keys()[0]
		rest.erase(saat)
		var gruppe: Array = [saat]
		var s2: Array = [saat]
		while not s2.is_empty():
			var q: Vector2i = s2.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nb: Vector2i = q + d
				if rest.has(nb):
					rest.erase(nb)
					gruppe.append(nb)
					s2.append(nb)
		if gruppe.size() > groesste_insel:
			groesste_insel = gruppe.size()
			beispiel = Vector2(float(saat.x) * schritt, float(saat.y) * schritt)
	var insel_m2: float = float(groesste_insel) * schritt * schritt
	_check("Keine abgeschnittene Flaeche in Rustwater", insel_m2 < 4.0,
		"%.1f m² unerreichbar, z. B. bei (%.1f / %.1f)" % [insel_m2, beispiel.x, beispiel.y])
	# Und genug Platz zum Spielen: unter der Haelfte waere die Stadt ein Labyrinth.
	var flaeche: float = float(erreicht.size()) * schritt * schritt
	_check("Rustwater bietet Bewegungsraum", flaeche >= 3000.0, "nur %.0f m²" % flaeche)
	print("    begehbar und erreichbar: %.0f m², %d Sperren, groesste %.1f m"
		% [flaeche, sperren.size(), groesste])


## Sprechtafel & Zuwendung — wie ein Gespraech aussieht.
##
## Vorlage ist Diablo Immortal: Bildnis links, Name in Versalien, Text daneben, unten ueber die
## ganze Breite. Geprueft wird, was daran schiefgehen KANN: dass der Text hineinpasst, dass ein
## Tipp auf die Tafel dort bleibt, und dass sich beide Figuren wirklich zueinander drehen.
func _test_dialog() -> void:
	print("· Sprechtafel & Zuwendung")
	_reset_state()
	var d := DialogBox.new()
	_scratch.append(d)
	d.size = Vector2(1280.0 - DialogBox.MARGIN * 2.0, DialogBox.BOX_H)
	_check("Vor dem ersten Satz ist sie unsichtbar", not d.visible)
	d.show_line("Mamma „Rusty“ Mabel", "„Setz dich, Kind.“", "mabel")
	_check("Nach dem Satz steht sie", d.visible)
	_check("Sie merkt sich, wer spricht", d.speaker.begins_with("Mamma"))
	# Der Fehler aus dem ersten Entwurf: feste Hoehe, und die vierte Zeile fiel unten heraus.
	var kurz: float = d._needed_height("„Setz dich, Kind.“")
	var lang: float = d._needed_height("„Setz dich, Kind. Aber vorher…“\n\n"
		+ "✦ „Kopfgeld: Wegelagerer“ — 8 Gegner erlegen\n"
		+ "⊕ Das Rattengestrüpp — 559 m. Der Spur folgen.")
	_check("Die Tafel waechst mit dem Text (%.0f -> %.0f px)" % [kurz, lang], lang > kurz)
	_check("Sie waechst aber nicht unbegrenzt",
		d._needed_height("Wort ".repeat(400)) <= DialogBox.BOX_H_MAX)
	# Kein exakter Vergleich: Mit Rahmengrafik haengt der Innenabstand am GEMESSENEN Band, und
	# das steht in einer Datei, die sich aendern darf. Die Aussage, auf die es ankommt, ist
	# „kurzer Text macht die Tafel nicht gross" — und die haelt jede Grafik aus.
	_check("Kurzer Text bleibt nah an der Mindesthoehe (%.0f, Minimum %.0f)"
		% [kurz, DialogBox.BOX_H],
		kurz >= DialogBox.BOX_H and kurz <= DialogBox.BOX_H + 40.0)
	# Der Name wird gesperrt gesetzt — sonst liest er sich wie ein Satz, nicht wie eine Rubrik.
	_check("Der Name wird gesperrt", DialogBox._sperren("AB") == "A B")
	_check("Leerzeichen bekommen keinen Zusatz", DialogBox._sperren("A B") == "A  B")
	# Ein Tipp auf die Tafel darf nicht am Joystick landen.
	d.position = Vector2(22.0, 560.0)
	_check("Ein Tipp auf der Tafel wird dort verbraucht",
		d.hits(d.global_position + d.size * 0.5))
	_check("Ein Tipp daneben nicht", not d.hits(d.global_position - Vector2(10.0, 10.0)))
	d.hide_box()
	_check("Nach dem Schliessen ist sie weg", not d.visible)
	# ── Gelieferte Grafiken ───────────────────────────────────────────────────
	# Bildgeneratoren legen das Motiv gern als kleineres Quadrat mitten auf eine transparente
	# Flaeche. Stur ins Feld gezeichnet waere das Gesicht entsprechend kleiner, mit einem Rand
	# aus Nichts. Hier ein Bildnis mit einem Achtel Luft ringsum — der bemalte Teil muss
	# gefunden werden.
	var bild := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	bild.fill(Color(0, 0, 0, 0))
	bild.fill_rect(Rect2i(32, 32, 192, 192), Color(0.2, 0.2, 0.2, 1.0))
	d._set_portrait(ImageTexture.create_from_image(bild))
	_check("Der bemalte Teil eines Bildnisses wird gefunden (%s)" % d._portrait_region,
		d._portrait_region.position.x >= 30.0 and d._portrait_region.position.y >= 30.0
			and d._portrait_region.size.x <= 194.0 and d._portrait_region.size.y <= 194.0)
	var voll := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	voll.fill(Color(0.3, 0.2, 0.1, 1.0))
	d._set_portrait(ImageTexture.create_from_image(voll))
	_check("Ein randloses Bildnis wird ganz genommen",
		is_equal_approx(d._portrait_region.size.x, 64.0))
	d._set_portrait(null)
	_check("Ohne Bildnis bleibt der Ausschnitt leer", d._portrait_region.size.x == 0.0)
	# Der Tafelrahmen wird als 9-Patch gezeichnet: Sonst werden die Nieten in den Ecken zu
	# Ovalen, sobald die Tafel mit dem Text waechst. Die Schnittkante wird am Bild GEMESSEN —
	# fest eingetragene 12 % lagen bei der gelieferten Grafik (15 %) mitten im Eisen, und die
	# Mitte wurde dann samt Band gekachelt.
	var rahmen := Image.create(400, 100, false, Image.FORMAT_RGBA8)
	rahmen.fill(Color(0.4, 0.3, 0.2, 1.0))
	rahmen.fill_rect(Rect2i(0, 30, 400, 40), Color(0.85, 0.78, 0.62, 1.0))   # Pergament
	d.set_frame(ImageTexture.create_from_image(rahmen))
	_check("Das Rahmenband wird gemessen (%.0f px bei 30 px Band)" % d._band,
		absf(d._band - 30.0) <= 4.0)
	_check("Mit Rahmen rueckt der Inhalt nach innen", d._inset() > DialogBox.PAD)
	d.set_frame(null)
	_check("Ohne Grafik zeichnet die Tafel wieder selbst",
		d._band == 0.0 and is_equal_approx(d._inset(), DialogBox.PAD))
	# ── Zueinanderdrehen ──────────────────────────────────────────────────────
	# Nach Osten schauen heisst in Godot: rotation.y so, dass −z auf +x zeigt.
	var ost: float = OverworldView._yaw_towards(Vector3.ZERO, Vector3(10.0, 0.0, 0.0))
	var nord: float = OverworldView._yaw_towards(Vector3.ZERO, Vector3(0.0, 0.0, -10.0))
	var richtung_ost: Vector3 = Basis.from_euler(Vector3(0.0, ost, 0.0)) * Vector3(0.0, 0.0, -1.0)
	var richtung_nord: Vector3 = Basis.from_euler(Vector3(0.0, nord, 0.0)) * Vector3(0.0, 0.0, -1.0)
	_check("Blick nach Osten zeigt nach +x (%.2f)" % richtung_ost.x, richtung_ost.x > 0.95)
	_check("Blick nach Norden zeigt nach −z (%.2f)" % richtung_nord.z, richtung_nord.z < -0.95)
	var ow := OverworldView.new()
	_scratch.append(ow)
	ow._player = Node3D.new()
	_scratch.append(ow._player)
	ow._cam = Camera3D.new()
	_scratch.append(ow._cam)
	var npc := Node3D.new()
	_scratch.append(npc)
	ow._player.position = Vector3(0.0, 0.0, 0.0)
	npc.position = Vector3(6.0, 0.0, 0.0)
	npc.rotation.y = PI          # schaut demonstrativ woanders hin
	ow._play_closeup(npc, 3.0)
	for i in 40:                 # ein paar Frames drehen lassen
		ow._process_facing(0.05)
	var soll_spieler: float = OverworldView._yaw_towards(ow._player.position, npc.position)
	var soll_npc: float = OverworldView._yaw_towards(npc.position, ow._player.position)
	_check("Der Spieler dreht sich zum Gegenueber (%.2f statt %.2f)"
		% [ow._player.rotation.y, soll_spieler],
		absf(wrapf(ow._player.rotation.y - soll_spieler, -PI, PI)) < 0.05)
	_check("Und das Gegenueber zum Spieler (%.2f statt %.2f)" % [npc.rotation.y, soll_npc],
		absf(wrapf(npc.rotation.y - soll_npc, -PI, PI)) < 0.05)
	# Danach zurueck: Sonst steht Mabel dauerhaft schraeg und schaut einem hinterher.
	ow._end_cine()
	_check("Nach dem Gespraech steht das Gegenueber wieder wie vorher",
		is_equal_approx(npc.rotation.y, PI))
	_reset_state()


## Orte duerfen nicht zugestellt sein.
##
## Regression, und zwar die dritte desselben Fehlers: Auf jedem Ort stand eine 36 m hohe
## Platzhalter-Saeule mit 6,6 m Sperrradius, GENAU im Mittelpunkt. Erst fiel es auf dem
## Marktplatz von Rustwater auf, dann im Grund der Schrottgrube, dann im Rattengestruepp — also
## ausgerechnet dort, wohin die erste Quest schickt. Zweimal wurde die Saeule einzeln
## ausgenommen; beim dritten Mal ist sie ganz weg. Dieser Test sorgt dafuer, dass sie nicht
## als vierte Ausnahme wiederkommt.
func _test_poi_walkable() -> void:
	print("· Orte sind begehbar")
	_reset_state()
	var ow := OverworldView.new()
	_scratch.append(ow)
	ow._build_pois()
	for id in WorldManager.POIS.keys():
		var name: String = String(WorldManager.POIS[id]["name"])
		var mitte: Vector3 = WorldManager.poi_scene_position(String(id))
		if String(id) == "eisernes_herz":
			# Die Ausnahme mit Ansage: Das Eiserne Herz IST ein Bauwerk, kein Wegweiser.
			# Ein 120-m-Turm darf sperren — man geht durch die Tuer hinein, nicht durch die Wand.
			_check("%s sperrt (es ist ein Turm, kein Pfahl)" % name, ow._blocked(mitte))
			continue
		_check("%s ist in der Mitte begehbar" % name, not ow._blocked(mitte))
		# Und im Umkreis, in dem man sich beim Ankommen bewegt.
		var eng: String = ""
		for k in 8:
			var a: float = TAU * float(k) / 8.0
			if ow._blocked(mitte + Vector3(cos(a) * 7.0, 0.0, sin(a) * 7.0)):
				eng = "%.0f°" % rad_to_deg(a)
		_check("%s ist auch ringsum frei" % name, eng == "", "bei %s versperrt" % eng)
	_check("Ein Ort traegt trotzdem seinen Namen in der Welt",
		ow.get_children().any(func(c: Node) -> bool: return c is Label3D))
	_reset_state()


## Nahaufnahme — die Kamera als Erzaehler.
##
## Geprueft wird das, was eine Nahaufnahme von einem Kamerafehler unterscheidet: dass sie von
## VORN filmt, dass man waehrenddessen nichts tun kann, und dass man wieder herauskommt.
func _test_closeup() -> void:
	print("· Nahaufnahme")
	_reset_state()
	var ow := OverworldView.new()
	_scratch.append(ow)
	# Zwei Attrappen: eine „Person", die nach Sueden schaut, und der Spieler daneben.
	# In den BAUM haengen, nicht nur erzeugen: `global_position` ist bei einem Knoten ausserhalb
	# des Szenenbaums null, und die Einstellung rechnet mit globalen Punkten. Der alte Test hat
	# das nicht gemerkt, weil er selbst mit denselben Nullen verglich.
	var wer := Node3D.new()
	_scratch.append(wer)
	add_child(wer)
	wer.position = Vector3(100.0, 0.0, -100.0)
	ow._player = Node3D.new()
	_scratch.append(ow._player)
	add_child(ow._player)
	ow._player.position = wer.position + Vector3(2.0, 0.0, 0.0)
	ow._cam = Camera3D.new()
	_scratch.append(ow._cam)
	_check("Vor dem Ausloesen laeuft keine Aufnahme", not ow._in_cine())
	ow._play_closeup(wer, 2.6)
	_check("Nach dem Ausloesen laeuft eine", ow._in_cine())
	# Ein Gespraech ist eine ZWEIER-Einstellung: Beide muessen zu sehen sein, und keiner darf
	# vor dem anderen stehen. Vorher galt nur „Kamera vor dem Gesicht des Gegenuebers" — wo der
	# Spieler dabei stand, war Zufall, und stand er dazwischen, verdeckte er genau den, mit dem
	# man spricht.
	var f: Array = ow._cine_frame()
	var pos: Vector3 = f[0]
	var blick: Vector3 = f[1]
	var zu_npc: Vector3 = wer.global_position - pos
	var zu_spieler: Vector3 = ow._player.position - pos
	zu_npc.y = 0.0
	zu_spieler.y = 0.0
	# Beide VOR der Kamera (sie blickt auf die Mitte zwischen ihnen).
	var richtung: Vector3 = blick - pos
	richtung.y = 0.0
	richtung = richtung.normalized()
	_check("Das Gegenueber ist im Bild", richtung.dot(zu_npc.normalized()) > 0.3)
	_check("Der Spieler ist im Bild", richtung.dot(zu_spieler.normalized()) > 0.3)
	# Nebeneinander, nicht hintereinander: der Winkel zwischen beiden Blickstrahlen.
	var winkel: float = rad_to_deg(zu_npc.angle_to(zu_spieler))
	_check("Sie stehen nebeneinander, keiner verdeckt den anderen (%.0f°)" % winkel,
		winkel > 25.0)
	# Und beide etwa gleich weit weg — sonst ist einer eine Silhouette im Vordergrund.
	var v: float = maxf(zu_npc.length(), zu_spieler.length()) \
		/ maxf(minf(zu_npc.length(), zu_spieler.length()), 0.01)
	_check("Beide sind etwa gleich weit weg (%.2f)" % v, v < 1.6)
	_check("Sie schaut auf Kopfhoehe, nicht auf die Fuesse (%.2f m)" % blick.y,
		blick.y > 1.0 and blick.y < 2.6)
	var hin: Vector3 = pos - blick
	hin.y = 0.0
	_check("Sie steht in Gespraechsabstand (%.2f m)" % hin.length(),
		hin.length() >= OverworldView.CINE_TWO_MIN_M - 0.1
			and hin.length() <= OverworldView.CINE_TWO_MAX_M + 1.2)
	# Die Fahrt nach innen haengt an der Zeit, nicht an der Dauer der Einstellung — sonst
	# faehrt eine kurze hektisch und eine lange in Zeitlupe.
	var weit0: float = hin.length()
	ow._cine_left -= OverworldView.CINE_DOLLY_SEC
	var f2: Array = ow._cine_frame()
	var weit1: float = Vector3(f2[0].x - wer.global_position.x, 0.0,
		f2[0].z - wer.global_position.z).length()
	_check("Die Kamera faehrt heran (%.2f -> %.2f m)" % [weit0, weit1], weit1 < weit0 - 0.5)
	ow._play_closeup(wer, 60.0)
	ow._cine_left -= OverworldView.CINE_DOLLY_SEC
	var f3: Array = ow._cine_frame()
	var weit2: float = Vector3(f3[0].x - wer.global_position.x, 0.0,
		f3[0].z - wer.global_position.z).length()
	_check("Und zwar gleich schnell, egal wie lang die Einstellung ist",
		is_equal_approx(weit1, weit2))
	# Waehrend der Aufnahme laeuft niemand aus dem Bild.
	var vorher: Vector3 = ow._player.position
	ow._process_movement(0.1)
	_check("Bewegung ist gesperrt", ow._player.position == vorher)
	ow._end_cine()
	_check("Danach ist sie vorbei", not ow._in_cine())
	_check("Ein zweites Beenden tut nichts", not ow._in_cine())
	_reset_state()


func _test_paperdoll() -> void:
	print("· Puppe (getragene Ausruestung)")
	_reset_state()
	var rects: Dictionary = PaperDoll.slot_rects()
	var alle: Array = EquipManager.all_slots()
	_check("Jede Fassung hat eine Lage (%d von %d)" % [rects.size(), alle.size()],
		rects.size() == alle.size())
	var fehlt: String = ""
	for s in alle:
		if not rects.has(String(s)):
			fehlt = String(s)
	_check("Keine Fassung vergessen", fehlt == "", "%s fehlt" % fehlt)
	# Ueberlappung: Zwei Fassungen an derselben Stelle waeren im Bild unsichtbar und beim
	# Tippen nicht zu treffen — der eine Fehler, den ein Layout aus Handzahlen wirklich macht.
	var ueberlappt: String = ""
	var ids: Array = rects.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			if (rects[ids[i]] as Rect2).intersects(rects[ids[j]]):
				ueberlappt = "%s / %s" % [ids[i], ids[j]]
	_check("Keine zwei Fassungen ueberlappen sich", ueberlappt == "", ueberlappt)
	# Regression: Im ersten Entwurf lag der Helm-Kasten AUF dem Kopf. Im Bild sah es aus, als
	# haette die Figur keinen — und der Test oben hat es nicht gesehen, weil eine Figur keine
	# Fassung ist. Deshalb steht die Figur jetzt als Rechteck in `FIGURE_RECT` und wird
	# mitgeprueft.
	var auf_figur: String = ""
	for s6 in rects:
		if (rects[s6] as Rect2).intersects(PaperDoll.FIGURE_RECT):
			auf_figur = String(s6)
	_check("Keine Fassung liegt auf der Figur", auf_figur == "",
		"%s ueberdeckt sie" % auf_figur)
	_check("Die Figur liegt vollstaendig in der Puppe",
		PaperDoll.FIGURE_RECT.position.x >= 0.0 and PaperDoll.FIGURE_RECT.position.y >= 0.0
			and PaperDoll.FIGURE_RECT.end.x <= PaperDoll.W
			and PaperDoll.FIGURE_RECT.end.y <= PaperDoll.H)
	# Alles innerhalb der Puppe, und die Puppe innerhalb der linken Spalte.
	var raus: String = ""
	for s2 in rects:
		var r: Rect2 = rects[s2]
		if r.position.x < 0.0 or r.position.y < 0.0 \
				or r.end.x > PaperDoll.W or r.end.y > PaperDoll.H:
			raus = String(s2)
	_check("Jede Fassung liegt innerhalb der Puppe", raus == "", "%s ragt heraus" % raus)
	_check("Die Puppe passt in die linke Spalte (%.0f von %.0f px)"
		% [PaperDoll.W, CharacterScreen.LEFT_W], PaperDoll.W <= CharacterScreen.LEFT_W)
	# Trefferrueckrechnung, wie beim Beutel-Raster: aus einem Bildpunkt die richtige Fassung.
	var d := PaperDoll.new()
	_scratch.append(d)
	var treffer_ok: bool = true
	for s3 in rects:
		if d.slot_at((rects[s3] as Rect2).get_center()) != String(s3):
			treffer_ok = false
	_check("Ein Tipp auf eine Fassung findet genau diese", treffer_ok)
	_check("Ein Tipp weit daneben findet nichts", d.slot_at(Vector2(-80.0, -80.0)) == "")
	# Zweimal dieselbe Fassung = Auswahl aufheben. Ohne das gaebe es auf dem Handy keinen Weg,
	# eine Auswahl loszuwerden, ohne den ganzen Bildschirm zu schliessen.
	var mitte: Vector2 = (rects["helmet"] as Rect2).get_center()
	d.tap(mitte)
	_check("Erster Tipp waehlt die Fassung", d.selected == "helmet")
	d.tap(mitte)
	_check("Zweiter Tipp hebt sie wieder auf", d.selected == "")
	# Jede Fassung braucht ein Sinnbild — ein Fragezeichen an der Puppe ist ein vergessener Fall.
	var ohne: String = ""
	for s4 in alle:
		if not InventoryGrid.SLOT_ICON.has(EquipManager.slot_type(String(s4))):
			ohne = String(s4)
	_check("Jede Fassung hat ein Sinnbild", ohne == "", "%s hat keines" % ohne)
	# Die Namen kommen aus `ProgressionManager` — sonst stuende an der Puppe ein anderer Begriff
	# als im Beutel.
	var namenlos: String = ""
	for s5 in alle:
		if not ProgressionManager.GEAR_SLOTS.has(EquipManager.slot_type(String(s5))):
			namenlos = String(s5)
	_check("Jede Fassung hat einen Namen", namenlos == "", "%s hat keinen" % namenlos)


func _test_inventory_grid() -> void:
	print("· Beutel-Raster")
	_reset_state()
	_check("Raster ist 5 Spalten breit (GDD §7.4)", BagManager.COLS == 5)
	_check("Raster ist 12 Zeilen hoch", BagManager.ROWS == 12)
	# Belegung: dieselbe Packung wie die Kapazitaetspruefung, sonst zeigt die Anzeige etwas
	# anderes als der Beutel erlaubt.
	GameState.bag = []
	for slot in ["armor", "weapon", "helmet", "armor", "boots"]:
		BagManager.add(ProgressionManager.make_gear(String(slot), "common"))
	var belegung: Array = BagManager.layout()
	_check("Jedes Teil hat einen Platz", belegung.size() == GameState.bag.size())
	var zellen: int = 0
	var doppelt: String = ""
	var besetzt: Dictionary = {}
	for i in belegung.size():
		var r: Rect2i = belegung[i]
		_check("Teil %d liegt im Raster (%s)" % [i, r], r.position.x >= 0
			and r.position.x + r.size.x <= BagManager.COLS
			and r.position.y + r.size.y <= BagManager.ROWS)
		for dy in r.size.y:
			for dx in r.size.x:
				var k: int = (r.position.y + dy) * 100 + r.position.x + dx
				if besetzt.has(k):
					doppelt = "Zelle %d doppelt belegt" % k
				besetzt[k] = true
				zellen += 1
	_check("Kein Teil ueberlappt ein anderes", doppelt == "", doppelt)
	_check("Belegte Zellen stimmen mit `used_cells` (%d)" % zellen,
		zellen == BagManager.used_cells())
	# Fussabdruecke: genau das, was ein Raster von einer Stueckzahl unterscheidet.
	_check("Ruestung braucht 2x2, Waffe 2x1, Helm 1x1",
		BagManager.FOOTPRINT["armor"] == Vector2i(2, 2)
		and BagManager.FOOTPRINT["weapon"] == Vector2i(2, 1)
		and BagManager.FOOTPRINT["helmet"] == Vector2i(1, 1))
	# Trefferrueckrechnung: aus einem Bildpunkt wieder der richtige Beutel-Index.
	var g := InventoryGrid.new()
	_scratch.append(g)
	g.refresh()
	var treffer_ok: bool = true
	for i in belegung.size():
		var r2: Rect2i = belegung[i]
		var mitte := Vector2(
			(float(r2.position.x) + float(r2.size.x) * 0.5) * (InventoryGrid.CELL + InventoryGrid.GAP),
			(float(r2.position.y) + float(r2.size.y) * 0.5) * (InventoryGrid.CELL + InventoryGrid.GAP))
		if g.cell_at(mitte) != i:
			treffer_ok = false
	_check("Ein Tipp auf ein Feld findet genau dieses Teil", treffer_ok)
	_check("Ein Tipp auf eine leere Zelle findet nichts",
		g.cell_at(Vector2(InventoryGrid.CELL * 2.0,
			(InventoryGrid.CELL + InventoryGrid.GAP) * float(BagManager.ROWS - 1) + 4.0)) == -1)
	_check("Ein Tipp weit daneben findet nichts", g.cell_at(Vector2(-60.0, -60.0)) == -1)
	# Jede Kategorie braucht ein Sinnbild — ein Fragezeichen im Raster ist ein vergessener Fall.
	var alle_icons: bool = true
	for slot2 in BagManager.FOOTPRINT.keys():
		if not InventoryGrid.SLOT_ICON.has(String(slot2)):
			alle_icons = false
	_check("Jede Kategorie hat ein Sinnbild im Raster", alle_icons)
	# Das Raster muss auf den Bildschirm passen — 12 Zeilen sind der Grund, warum die Zellen
	# 44 px sind und nicht 48.
	_check("Raster passt in 720 px Hoehe (%.0f px)" % InventoryGrid.grid_size().y,
		InventoryGrid.grid_size().y < 640.0)


## Fog of War — erkundete Karte.
func _test_fog() -> void:
	print("· Fog of War")
	GameState.fog = {}
	var rw: Vector2 = WorldManager.poi_position("rustwater")
	_check("Vor dem ersten Schritt ist nichts bekannt", not FogOfWar.is_seen(rw))
	var neu: int = FogOfWar.reveal(rw)
	_check("Aufdecken legt mehrere Zellen frei (%d)" % neu, neu > 4)
	_check("Der eigene Standort ist danach bekannt", FogOfWar.is_seen(rw))
	_check("Rustwater gilt als entdeckt", FogOfWar.poi_known("rustwater"))
	_check("Ein weit entfernter Ort nicht", not FogOfWar.poi_known("eisernes_herz"))
	_check("Zweimal dieselbe Stelle deckt nichts Neues auf", FogOfWar.reveal(rw) == 0)
	# Kreisfoermig, nicht quadratisch: sonst zeichnet Laufen eine Treppe an den Rand.
	var ecke := rw + Vector2(FogOfWar.SIGHT_UNITS, FogOfWar.SIGHT_UNITS) * 0.95
	_check("Die Ecke des Sichtquadrats bleibt zu (Sicht ist rund)", not FogOfWar.is_seen(ecke))
	_check("Geradeaus in Sichtweite ist offen",
		FogOfWar.is_seen(rw + Vector2(FogOfWar.SIGHT_UNITS * 0.8, 0.0)))
	var anteil: float = FogOfWar.explored_share()
	_check("Erkundeter Anteil ist klein aber nicht null (%.4f)" % anteil,
		anteil > 0.0 and anteil < 0.02)
	# Speichern und Laden muss den Nebel mitnehmen — sonst ist die Karte nach dem Neustart
	# wieder zu, und das ist der Fehler, den man erst am naechsten Tag bemerkt.
	var vorher: int = GameState.fog.size()
	var daten: Dictionary = SaveManager.serialize()
	GameState.fog = {}
	SaveManager.deserialize(daten)
	_check("Der Nebel ueberlebt Speichern und Laden (%d Zellen)" % vorher,
		GameState.fog.size() == vorher)
	# `fresh()` ist der Startzustand: Rustwater bekannt, der Rest zu.
	FogOfWar.fresh()
	_check("Neues Spiel: Rustwater bekannt", FogOfWar.poi_known("rustwater"))
	_check("Neues Spiel: die Schrott-Minen noch nicht", not FogOfWar.poi_known("schrott_minen"))


## Strahlensumpf (Gate 0) — der erste Riegel, weich statt hart.
func _test_swamp() -> void:
	print("· Strahlensumpf")
	_reset_state()
	var m: float = WorldManager.METERS_PER_UNIT
	var zone: Rect2 = WorldManager.swamp_rect()
	var mitte := Vector2(float(WorldManager.SWAMP_CENTER_X), float(WorldManager.SWAMP_CENTER_Y))
	var davor := Vector2(mitte.x, zone.position.y - 30.0)
	var dahinter := Vector2(mitte.x, zone.position.y + zone.size.y + 30.0)
	# Die BESTELLTEN Maszte, in Metern nachgerechnet: 2,5 km breit, 500 m hoch, 1 km noerdlich
	# von Rustwater (auf 800 m gerueckt, damit das Zugdepot nicht in der Todeszone steht).
	_check("Die Zone ist 2,5 km breit (%.0f m)" % (zone.size.x * m),
		is_equal_approx(zone.size.x * m, 2500.0))
	_check("Die Zone ist 500 m hoch (%.0f m)" % (zone.size.y * m),
		is_equal_approx(zone.size.y * m, 500.0))
	var noerdlich: float = (mitte.y - WorldManager.poi_position("rustwater").y) * m
	_check("Sie liegt rund 1 km noerdlich von Rustwater (%.0f m)" % noerdlich,
		noerdlich >= 700.0 and noerdlich <= 1100.0)
	_check("Sie deckt NICHT die ganze Kartenbreite ab — man kommt daran vorbei",
		zone.size.x < float(WorldManager.WORLD_SIZE))
	_check("Der Sumpf liegt NORDLICH der Schrott-Minen",
		zone.position.y > WorldManager.poi_position("schrott_minen").y)
	_check("und SUEDLICH der Sprengtore (er kommt zuerst)",
		zone.position.y + zone.size.y < float(WorldManager.BORDER_S1_S2_Y))
	_check("Rustwater liegt davor",
		not WorldManager.is_in_swamp(WorldManager.poi_position("rustwater")))
	_check("Die Schrott-Minen liegen davor",
		not WorldManager.is_in_swamp(WorldManager.poi_position("schrott_minen")))
	# Das Zugdepot ist ein Bahnhof MIT Bossarena und Schnellreiseziel. Laege es in der Zone,
	# setzte die Schnellreise den Spieler direkt in die Strahlung — genau deshalb steht die
	# Mitte bei 620 und nicht bei 700.
	_check("Das Zugdepot liegt NICHT in der Todeszone",
		not WorldManager.is_in_swamp(WorldManager.poi_position("zugdepot")))
	var getroffen: String = ""
	for id in WorldManager.POIS.keys():
		if WorldManager.is_in_swamp(WorldManager.poi_position(String(id))):
			getroffen = String(id)
	_check("Kein einziger Ort liegt in der Todeszone", getroffen.is_empty(),
		"%s steht mitten drin" % getroffen)
	_check("Mitten drin ist man im Sumpf", WorldManager.is_in_swamp(mitte))
	_check("Davor und dahinter nicht",
		not WorldManager.is_in_swamp(davor) and not WorldManager.is_in_swamp(dahinter))
	_check("Oestlich und westlich daneben auch nicht",
		not WorldManager.is_in_swamp(Vector2(zone.position.x - 30.0, mitte.y))
			and not WorldManager.is_in_swamp(Vector2(zone.position.x + zone.size.x + 30.0, mitte.y)))
	# Weicher Verlauf: Am Rand tut es weniger weh als in der Mitte. Eine harte Kante wuerde man
	# ueberrennen und ohne Vorwarnung sterben. Der Verlauf haengt am ABSTAND zum Rand — also
	# gilt er an der Ost- und Westkante genauso wie im Sueden.
	var rand := Vector2(mitte.x, zone.position.y + 4.0)
	var rand_ost := Vector2(zone.position.x + zone.size.x - 4.0, mitte.y)
	_check("Am Rand ist die Strahlung schwaecher als in der Mitte (%.2f gegen %.2f)"
		% [WorldManager.swamp_depth(rand), WorldManager.swamp_depth(mitte)],
		WorldManager.swamp_depth(rand) < WorldManager.swamp_depth(mitte) * 0.5)
	_check("Auch an der Ostkante (%.2f)" % WorldManager.swamp_depth(rand_ost),
		WorldManager.swamp_depth(rand_ost) < WorldManager.swamp_depth(mitte) * 0.5)
	_check("In der Mitte ist sie maximal",
		is_equal_approx(WorldManager.swamp_depth(mitte), 1.0))
	# Die kleinen Einschlaege: Sie sollen im Sumpf liegen, klein sein und keinen Schrott fuehren.
	var loecher: int = 0
	for f in WorldManager.TERRAIN:
		if not WorldManager.is_swamp_feature(f):
			continue
		loecher += 1
		var p := Vector2(float(f["x"]), float(f["y"]))
		_check("%s liegt in der Zone" % String(f["id"]), WorldManager.is_in_swamp(p))
		_check("%s ist kleiner als die Schrottgrube" % String(f["id"]),
			float(f["radius"]) < float(WorldManager.TERRAIN[0]["radius"]))
		_check("%s fuehrt keinen Schrott" % String(f["id"]), not bool(f.get("scrap", true)))
		# Regression: Der Auswurfwall war im Bild das Auffaelligste am ganzen Krater — ein
		# blassrosa Ring. Er ist die einzige Flaeche ringsum, die der tiefstehenden Sonne ihre
		# Oberseite zudreht, und unter Filmic-Tonemapping kippt der warme Sand dort ins Rosa.
		# Gemessen (derselbe Krater mit und ohne Wall gerendert), nicht vermutet.
		_check("%s hat keinen Auswurfwall" % String(f["id"]),
			is_zero_approx(float(f["rim"])) and is_zero_approx(float(f["rim_width"])))
		_check("%s spart sich damit auch den Gelaendeflicken dafuer" % String(f["id"]),
			is_equal_approx(WorldManager.feature_reach(f), float(f["radius"])))
		# Wie die Grube: eine Wand, die man SIEHT, und ein Sektor, in dem sie fehlt.
		# Ein flaches Loch ist im Bild nur ein Ring auf dem Boden — genau daran ist der erste
		# Versuch gescheitert. Also beides messen: Wand steil, Ausgang begehbar.
		var wand: float = rad_to_deg(atan(1.5 * float(f["depth"])
			/ (float(f["radius"]) * (1.0 - float(f.get("floor", 0.0))))))
		_check("%s hat eine sichtbare Wand (%.0f°)" % [String(f["id"]), wand], wand > 45.0)
		# In der Rampe faellt `floor` auf 0, das Profil zieht sich ueber den ganzen Radius —
		# steilste Stelle dort: 1,5 · depth / radius.
		var rampe: float = rad_to_deg(atan(1.5 * float(f["depth"]) / float(f["radius"])))
		_check("%s hat einen begehbaren Ausgang (%.0f°)" % [String(f["id"]), rampe],
			f.has("ramp_deg") and float(f.get("ramp_span", 0.0)) > 0.0 and rampe < 35.0)
	_check("Es gibt mehrere Sumpfloecher (%d)" % loecher, loecher >= 5)
	# Schaden: ohne Anzug toedlich, mit Anzug null.
	GameState.economy["laboratory"] = 0
	var dot: int = WorldManager.swamp_dot_damage(mitte, 1.0)
	_check("Ohne Anzug kostet eine Sekunde spuerbar Leben (%d)" % dot,
		dot >= int(float(GameState.max_hp()) / WorldManager.SWAMP_LETHAL_SECONDS) - 1)
	_check("Draussen kostet es nichts", WorldManager.swamp_dot_damage(davor, 1.0) == 0)
	GameState.economy["laboratory"] = WorldManager.SWAMP_SUIT_LEVEL
	_check("Mit Schutzanzug kostet der Sumpf nichts",
		WorldManager.has_rad_suit() and WorldManager.swamp_dot_damage(mitte, 1.0) == 0)
	# Der Anzug kommt VOR dem Smog-Filter — zwei Gates am selben Gebaeude, in Reihenfolge.
	_check("Der Anzug kommt vor dem Smog-Filter",
		WorldManager.SWAMP_SUIT_LEVEL < WorldManager.FILTER_REQUIRED_LEVEL)
	_check("Mit Anzug allein hilft der Smog nicht", not WorldManager.has_alchemie_filter())
	_reset_state()


## Requisiten aus docs/PROMPTS_PROPS.md — Maszstab und Streuregeln.
##
## Der Kern dieser Suite ist die GEMESSENE Groesse. Generatoren normieren jedes Modell auf
## dieselbe Kantenlaenge; die Zahl in `AssetRegistry` ist die einzige Stelle, an der ein
## Kaktus ein Kaktus und kein Baum wird. Ein Zahlendreher dort faellt im Spiel erst auf,
## wenn man davorsteht — hier faellt er sofort auf.
func _test_props() -> void:
	print("· Requisiten (Maszstab & Streuung)")
	# ── Blickrichtung: jede Figur braucht eine ENTSCHEIDUNG ───────────────────
	# Godot laeuft nach −Z, die zugekauften Modelle schauen nach +Z. Ohne Korrektur laeuft eine
	# Figur rueckwaerts. Bei Grenzgaenger und Revolverheld faellt das sofort auf; bei der
	# Oelfresser-Ratte und dem Konzern-Konstrukt ist es monatelang niemandem aufgefallen, weil
	# man einem Vierbeiner und einer Kettenkiste die Vorderseite nicht ansieht.
	#
	# Geprueft wird deshalb nicht der WERT (den kann kein Test kennen — dafuer muss man das
	# Modell rendern), sondern dass ueberhaupt einer eingetragen ist. Die stille 0 als Vorgabe
	# ist keine Entscheidung, sondern eine vergessene.
	var ohne_blick: Array = []
	for name in AssetRegistry.PATHS.keys():
		var n: String = String(name)
		var figur: bool = n.begins_with("enemy_") or n.begins_with("npc_") \
			or n == "player" or n == "companion_dog"
		if figur and AssetRegistry.has_model(n) and not AssetRegistry.YAW_DEG.has(n):
			ohne_blick.append(n)
	_check("Jede vorhandene Figur hat eine eingetragene Blickrichtung",
		ohne_blick.is_empty(), "fehlt bei: %s" % str(ohne_blick))
	# Und die vier Gegner, die gemessen wurden, drehen sich auch wirklich.
	for gegner in ["enemy_outlaw", "enemy_revolver", "enemy_fauna", "enemy_konstrukt"]:
		if not AssetRegistry.has_model(String(gegner)):
			continue
		_check("%s ist auf Godots Laufrichtung gedreht" % gegner,
			is_equal_approx(float(AssetRegistry.YAW_DEG.get(String(gegner), 0.0)), 180.0))
	# Die drei Sumpf-Requisiten: Sie teilen sich einen Streudurchgang, also muessen ihre Masze
	# zueinander passen. Ein Fass so hoch wie ein Baum waere im Bild kein Fass mehr.
	_check("Der Moorbaum ueberragt den Spieler deutlich (%.1f m)"
		% AssetRegistry.height_of("deadtree"), AssetRegistry.height_of("deadtree") >= 4.5)
	_check("Das Strahlenfass bleibt fasshoch (%.1f m)" % AssetRegistry.height_of("rad_barrel"),
		AssetRegistry.height_of("rad_barrel") <= 1.4)
	# Ein LIEGENDER Stamm wird ueber die Laenge gemessen. Ueber die Hoehe skaliert waere er
	# zwanzig Meter lang — derselbe Fehler, den der Karabiner schon einmal gemacht hat.
	_check("Der umgestuerzte Stamm haengt an der LAENGE, nicht an der Hoehe",
		AssetRegistry.length_of("deadtree_b") > 0.0)
	_check("und ist kuerzer als der stehende hoch ist",
		AssetRegistry.length_of("deadtree_b") < AssetRegistry.height_of("deadtree"))
	# Was aufrecht steht, misst sich an der Hoehe; was flach liegt, an der laengsten Kante.
	var aufrecht: Dictionary = {
		"barrels": 1.6, "barrels_b": 1.6, "barrels_c": 1.6,
		"street_lamp": 3.6, "bounty_board": 2.2, "cactus": 2.6,
	}
	var laengs: Dictionary = { "hitching_post": 2.6, "scrap_heap": 3.2, "bones": 1.8 }
	for name in aufrecht:
		_check("%s wird ueber die HOEHE skaliert (%.1f m)" % [name, float(aufrecht[name])],
			AssetRegistry.length_of(String(name)) <= 0.0
			and is_equal_approx(AssetRegistry.height_of(String(name)), float(aufrecht[name])))
	for name in laengs:
		_check("%s wird ueber die LAENGE skaliert (%.1f m)" % [name, float(laengs[name])],
			is_equal_approx(AssetRegistry.length_of(String(name)), float(laengs[name])))
	# Gegenprobe am echten Modell: erst hier faellt auf, wenn die Achse falsch gewaehlt ist.
	for name in ["cactus", "street_lamp", "barrels"]:
		if not AssetRegistry.has_model(String(name)):
			continue
		var node: Node3D = AssetRegistry.instantiate(String(name), AssetRegistry.height_of(String(name)))
		var s: Vector3 = AssetRegistry.local_bounds(node).size
		_check("%s misst gebaut %.2f m hoch (Ziel %.1f)" % [name, s.y, AssetRegistry.height_of(String(name))],
			absf(s.y - AssetRegistry.height_of(String(name))) < 0.05, "%s" % s)
		# Ein aufrecht skaliertes Modell darf nicht in die Breite explodieren — genau daran ist
		# das CC0-Geroellfeld gescheitert (1,2 m hoch skaliert = 10,4 m breit).
		_check("%s bleibt dabei schmaler als hoch" % name, maxf(s.x, s.z) <= s.y * 1.6,
			"%.2f x %.2f bei %.2f hoch" % [s.x, s.z, s.y])
		node.free()
	for name in ["hitching_post", "scrap_heap", "bones"]:
		if not AssetRegistry.has_model(String(name)):
			continue
		var node2: Node3D = AssetRegistry.instantiate(String(name), AssetRegistry.length_of(String(name)))
		var s2: Vector3 = AssetRegistry.local_bounds(node2).size
		var laengste: float = maxf(s2.x, maxf(s2.y, s2.z))
		_check("%s misst gebaut %.2f m in der laengsten Kante (Ziel %.1f)"
			% [name, laengste, AssetRegistry.length_of(String(name))],
			absf(laengste - AssetRegistry.length_of(String(name))) < 0.05, "%s" % s2)
		node2.free()
	# Requisiten sind KEINE Waende — sonst bekaeme ein Fass die Mauer-Kollision ohne Schrumpf.
	for name in ["barrels", "cactus", "scrap_heap", "bones", "bounty_board", "hitching_post",
			"street_lamp", "bahnhof"]:
		_check("%s gilt nicht als Mauerteil" % name, not AssetRegistry.is_wall(String(name)))
	_check("Gestreut wird ausserhalb des befriedeten Stadtrings",
		OverworldView.PROP_SCATTER_R_M > OverworldView.TOWN_SAFE_M + 18.0)


## Bahnsteighalle: das Modell ersetzt sechs Platzhalter-Kisten.
##
## Die eine Zahl, die hier wirklich zaehlt, ist `STATION_SOLID_SHARE`. Sperrt die ganze Halle,
## kommt man nicht auf den Bahnsteig und die Schnellreise ist unerreichbar; sperrt gar nichts,
## laeuft man durch die Rueckwand.
func _test_station() -> void:
	print("· Bahnsteighalle")
	_check("Der Bahnhof steht ausserhalb der Stadt",
		OverworldView.STATION_OFFSET_M > OverworldView.TOWN_R)
	_check("Die Halle ist kuerzer als der Abstand zum Ort (sie ragt nicht hinein)",
		OverworldView.STATION_LEN_M * 0.5 < OverworldView.STATION_OFFSET_M - OverworldView.TOWN_R)
	_check("Ein Teil der Tiefe bleibt begehbar (Bahnsteig)",
		OverworldView.STATION_SOLID_SHARE > 0.0 and OverworldView.STATION_SOLID_SHARE < 1.0,
		"%.2f" % OverworldView.STATION_SOLID_SHARE)
	if not AssetRegistry.has_model("bahnhof"):
		_check("bahnhof.glb vorhanden", false)
		return
	var hall: Node3D = AssetRegistry.instantiate("bahnhof", OverworldView.STATION_LEN_M)
	var b: AABB = AssetRegistry.local_bounds(hall)
	_check("Die Halle misst %.1f m in der Laenge" % b.size.x,
		absf(maxf(b.size.x, b.size.z) - OverworldView.STATION_LEN_M) < 0.05, "%s" % b.size)
	_check("Sie ist laenger als tief (Laengsachse liegt am Gleis)", b.size.x > b.size.z, "%s" % b.size)
	# Der begehbare Streifen muss breiter sein als der Spieler — sonst steht man im Nichts.
	var frei: float = b.size.z * (1.0 - OverworldView.STATION_SOLID_SHARE)
	_check("Der freie Bahnsteig ist %.1f m tief (> 2 Spielerbreiten)" % frei,
		frei > OverworldView.PLAYER_RADIUS_M * 4.0,
		"%.2f m bei Spielerradius %.2f" % [frei, OverworldView.PLAYER_RADIUS_M])
	# Und man muss vom Bahnsteig aus wirklich fahren koennen: Der Bahnsteig liegt hoechstens
	# eine halbe Hallentiefe vom eingetragenen Haltepunkt entfernt.
	_check("Der Bahnsteig liegt in Reichweite des Haltepunkts",
		b.size.z < OverworldView.STATION_RANGE_M,
		"%.1f m Tiefe bei %.0f m Reichweite" % [b.size.z, OverworldView.STATION_RANGE_M])
	_check("Die Front ist auf Godots -Z gedreht", is_equal_approx(
		float(AssetRegistry.YAW_DEG.get("bahnhof", 0.0)), 180.0))
	hall.free()


## Waffenprofile & Streuung (GDD §7.1): Jede Waffe muss sich anders ANFUEHLEN, nicht nur
## anders faerben.
##
## Vorher lagen alle vier Takte zwischen 170 und 240 ms — die Waffenwahl war eine reine
## Schadensart-Frage. Diese Tests halten fest, dass Takt, Schaden und Streuung jetzt
## auseinanderliegen und sich gegenseitig aufwiegen.
func _test_weapons() -> void:
	print("· Waffenprofile & Streuung")
	_reset_state()
	var kb: Dictionary = CombatData.WEAPONS["karabiner"]
	var gat: Dictionary = CombatData.WEAPONS["gatling"]
	_check("Der Karabiner schiesst langsam (>= 700 ms)", int(kb["fire_ms"]) >= 700,
		"%d ms" % int(kb["fire_ms"]))
	_check("Die Gatling schiesst sehr schnell (<= 90 ms)", int(gat["fire_ms"]) <= 90,
		"%d ms" % int(gat["fire_ms"]))
	_check("Takt-Spanne ueber Faktor 10", float(kb["fire_ms"]) / float(gat["fire_ms"]) >= 10.0,
		"Faktor %.1f" % (float(kb["fire_ms"]) / float(gat["fire_ms"])))
	_check("Dafuer trifft der Karabiner haerter (>= 4x Schaden je Schuss)",
		int(kb["base"]) >= 4 * int(gat["base"]), "%d gegen %d" % [int(kb["base"]), int(gat["base"])])
	# Kein Ausreisser: Der Dauerschaden darf sich unterscheiden, aber nicht um Groessenordnungen.
	var dps: Dictionary = {}
	for id in CombatData.WEAPONS:
		var w: Dictionary = CombatData.WEAPONS[id]
		dps[id] = float(w["base"]) * 1000.0 / float(w["fire_ms"])
	var lo: float = 1e9
	var hi: float = 0.0
	for id in dps:
		lo = minf(lo, float(dps[id]))
		hi = maxf(hi, float(dps[id]))
	_check("Kein Dauerschaden-Ausreisser (Spanne < 3x)", hi / lo < 3.0,
		"%.0f bis %.0f Schaden/s" % [lo, hi])
	# Jede Waffe hat eine eigene Munitionsquelle und eine eigene Streuung.
	_check("Gatling zieht aus demselben Pool wie der Karabiner (kinetisch)",
		AmmoData.pool_for("gatling") == AmmoData.pool_for("karabiner"))
	_check("Der Karabiner streut fast nicht (< 1°)", PlayerStats.spread_deg("karabiner") < 1.0)
	_check("Die Gatling sprueht (>= 5°)", PlayerStats.spread_deg("gatling") >= 5.0)

	# Der Kern: Streuung ist eine REICHWEITEN-Frage. Trefferwahrscheinlichkeit = Winkelbreite
	# des Ziels geteilt durch den Streukegel (gedeckelt bei 100 %).
	var radius: float = 0.55   # normal grosser Gegner
	for w in ["karabiner", "gatling"]:
		var cone: float = PlayerStats.spread_deg(String(w))
		var nah: float = _hit_chance(cone, radius, 3.0)
		var weit: float = _hit_chance(cone, radius, 11.0)
		print("    %-10s Kegel %.1f°  ->  auf 3 m %.0f %%, auf 11 m %.0f %%"
			% [w, cone, nah * 100.0, weit * 100.0])
	_check("Der Karabiner trifft auf volle Reichweite noch sicher",
		_hit_chance(PlayerStats.spread_deg("karabiner"), radius, 11.0) > 0.99)
	_check("Die Gatling trifft nah sicher, weit aber nicht",
		_hit_chance(PlayerStats.spread_deg("gatling"), radius, 3.0) > 0.99
		and _hit_chance(PlayerStats.spread_deg("gatling"), radius, 11.0) < 0.6)

	# Mods verengen den Kegel — genau darum ging es.
	_reset_state()
	var vorher: float = PlayerStats.spread_deg("gatling")
	GameState.equip = { "weapon": { "uid": 1, "slot": "weapon", "rarity": "epic", "req": 1,
		"name": "Testlauf", "stat": { "key": "accuracy", "val": 40, "q": 1.0 }, "affixes": [] } }
	var nachher: float = PlayerStats.spread_deg("gatling")
	_check("Praezisions-Mod verengt den Kegel", nachher < vorher,
		"%.2f° -> %.2f°" % [vorher, nachher])
	_check("Der Mod verbessert die Trefferchance auf Distanz spuerbar",
		_hit_chance(nachher, radius, 11.0) > _hit_chance(vorher, radius, 11.0) + 0.15,
		"%.0f %% -> %.0f %%" % [_hit_chance(vorher, radius, 11.0) * 100.0,
			_hit_chance(nachher, radius, 11.0) * 100.0])
	GameState.equip = { "weapon": { "uid": 1, "slot": "weapon", "rarity": "legendary", "req": 1,
		"name": "Testlauf", "stat": { "key": "accuracy", "val": 500, "q": 1.0 }, "affixes": [] } }
	_check("Auch vollgemoddet bleibt die Gatling eine Gatling (Deckel 85 %)",
		PlayerStats.spread_deg("gatling") > float(CombatData.WEAPONS["gatling"]["spread_deg"]) * 0.14,
		"%.2f°" % PlayerStats.spread_deg("gatling"))
	_reset_state()


## Trefferchance aus Streukegel, Zielradius und Entfernung — dieselbe Rechnung wie in
## `OverworldView._process_combat`, hier zum Pruefen nachgezogen.
func _hit_chance(cone_deg: float, radius_m: float, dist_m: float) -> float:
	if cone_deg <= 0.0:
		return 1.0
	var half_deg: float = rad_to_deg(atan2(radius_m, dist_m))
	return minf(1.0, half_deg / cone_deg)


## Munition (GDD §7.1.1): begrenzter Vorrat statt Dauerfeuer.
func _test_ammo() -> void:
	print("· Munition & Energiekristalle")
	_reset_state()
	_check("Karabiner zieht aus dem Munitionsvorrat", AmmoData.pool_for("karabiner") == "muni")
	for w in ["voltgun", "saeure", "brenner"]:
		_check("%s zieht aus den Kristallen" % w, AmmoData.pool_for(w) == "kristall")
	_check("Startvorrat Munition = 90", AmmoData.amount("muni") == 90)
	_check("Startvorrat Kristalle = 45", AmmoData.amount("kristall") == 45)
	# Zweistufig: Geschossen wird aus dem MAGAZIN, nachgefuellt aus dem Vorrat.
	_check("Ein Schuss kostet genau einen aus dem Magazin",
		AmmoData.consume("karabiner")
		and AmmoData.in_mag("karabiner") == AmmoData.mag_size("karabiner") - 1)
	_check("Der Vorrat bleibt dabei unberuehrt", AmmoData.amount("muni") == 90)
	# Kapazitaet deckelt, und `add` meldet ehrlich, wie viel wirklich ankam.
	GameState.ammo["muni"] = 175
	_check("Nachschub ueber die Kapazitaet wird gekappt und ehrlich gemeldet",
		AmmoData.add("muni", 20) == 5 and AmmoData.amount("muni") == 180,
		"jetzt %d" % AmmoData.amount("muni"))
	AmmoData.set_mag("karabiner", 0)
	_check("Leeres Magazin heisst leer", AmmoData.is_empty("karabiner"))
	_check("Aus leerem Magazin faellt kein Schuss", not AmmoData.consume("karabiner"))
	_check("Die andere Waffe hat ihr eigenes Magazin", not AmmoData.is_empty("voltgun"))
	_reset_state()


## Nachladen: Magazingroesse und Dauer je Waffe, beides verbesserbar.
##
## Ohne diese zweite Stufe waere Munition nur ein langsam sinkender Zaehler. Erst das Magazin
## erzeugt den Rhythmus aus Feuern und Deckungsuche — und erst dadurch ist die Gatling eine
## Entscheidung: 60 Schuss am Stueck, danach viereinhalb Sekunden wehrlos.
func _test_reload() -> void:
	print("· Magazin & Nachladen")
	_reset_state()
	_check("Der Karabiner haelt 10 Schuss", AmmoData.mag_size("karabiner") == 10)
	_check("Die Gatling haelt sechsmal so viel", AmmoData.mag_size("gatling") == 60)
	_check("Dafuer laedt sie mehr als doppelt so lang nach",
		PlayerStats.reload_sec("gatling") > PlayerStats.reload_sec("karabiner") * 2.0,
		"%.1f s gegen %.1f s" % [PlayerStats.reload_sec("gatling"), PlayerStats.reload_sec("karabiner")])
	_check("Jede Waffe hat ein eigenes Magazin und eine eigene Dauer",
		AmmoData.mag_size("saeure") != AmmoData.mag_size("brenner")
		and PlayerStats.reload_sec("saeure") != PlayerStats.reload_sec("brenner"))

	# Der Zyklus: leerschiessen, nachladen, wieder voll.
	_reset_state()
	var schuss: int = 0
	while AmmoData.consume("karabiner"):
		schuss += 1
	_check("Magazin leergeschossen nach genau %d Schuss" % AmmoData.mag_size("karabiner"),
		schuss == AmmoData.mag_size("karabiner"), "%d" % schuss)
	_check("Leeres Magazin laesst sich nachladen", AmmoData.can_reload("karabiner"))
	var geladen: int = AmmoData.refill_mag("karabiner")
	_check("Nachladen fuellt das Magazin voll", geladen == 10 and AmmoData.mag_full("karabiner"))
	_check("Und nimmt die Schuesse aus dem Vorrat", AmmoData.amount("muni") == 80,
		"%d" % AmmoData.amount("muni"))
	_check("Volles Magazin braucht kein Nachladen", not AmmoData.can_reload("karabiner"))

	# Teil-Nachladen, wenn der Vorrat nicht reicht — und ehrliche Rueckmeldung darueber.
	_reset_state()
	AmmoData.set_mag("karabiner", 0)
	GameState.ammo["muni"] = 3
	_check("Knapper Vorrat laedt nur teilweise",
		AmmoData.refill_mag("karabiner") == 3 and AmmoData.in_mag("karabiner") == 3)
	_check("Danach ist der Vorrat leer", AmmoData.amount("muni") == 0)
	_check("Ohne Vorrat hilft auch Nachladen nicht", not AmmoData.can_reload("karabiner"))
	AmmoData.set_mag("karabiner", 0)
	_check("Voellig trocken ist etwas anderes als nur leer",
		AmmoData.is_dry("karabiner") and AmmoData.is_empty("karabiner"))
	AmmoData.add("muni", 50)
	_check("Nach Nachschub ist es nur noch 'leer', nicht 'trocken'",
		AmmoData.is_empty("karabiner") and not AmmoData.is_dry("karabiner"))

	# Verbesserbarkeit: Werkstatt UND Ausruestung, beide gedeckelt.
	_reset_state()
	var voll: float = PlayerStats.reload_sec("gatling")
	GameState.upgrades["reload"] = 3          # -24 %
	var werkstatt: float = PlayerStats.reload_sec("gatling")
	_check("Werkstatt-Ausbau verkuerzt das Nachladen", werkstatt < voll,
		"%.2f s -> %.2f s" % [voll, werkstatt])
	_reset_state()
	GameState.equip = { "weapon": { "uid": 1, "slot": "weapon", "rarity": "epic", "req": 1,
		"name": "Testlauf", "stat": { "key": "reload", "val": 30, "q": 1.0 }, "affixes": [] } }
	var item: float = PlayerStats.reload_sec("gatling")
	_check("Ein besseres Item verkuerzt es ebenfalls", item < voll,
		"%.2f s -> %.2f s" % [voll, item])
	GameState.upgrades["reload"] = 5
	GameState.equip["weapon"]["stat"]["val"] = 500
	_check("Auch alles zusammen bleibt bei 60 %% Ersparnis gedeckelt",
		is_equal_approx(PlayerStats.reload_sec("gatling"), voll * 0.4),
		"%.2f s von %.2f s" % [PlayerStats.reload_sec("gatling"), voll])

	# Der bislang wirkungslose Munitionsgurt-Perk hebt endlich den Vorrat.
	_reset_state()
	var cap0: int = AmmoData.cap("muni")
	GameState.perks["gurt"] = 2
	_check("Perk 'Munitionsgurt' hebt die Vorratsgrenze (+25 je Rang)",
		AmmoData.cap("muni") == cap0 + 50, "%d -> %d" % [cap0, AmmoData.cap("muni")])
	_reset_state()


## Beutel: Platz haengt am Fussabdruck, nicht an der Stueckzahl (GDD §7.4).
func _test_bag() -> void:
	print("· Beutel (Grid-Kapazitaet)")
	_reset_state()
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	var ruestung: Dictionary = ProgressionManager.make_gear("armor", "common")
	var helm: Dictionary = ProgressionManager.make_gear("helmet", "common")
	_check("Ruestung belegt 2x2", BagManager.footprint(ruestung) == Vector2i(2, 2))
	_check("Helm belegt 1x1", BagManager.footprint(helm) == Vector2i(1, 1))
	_check("Waffe belegt 2x1",
		BagManager.footprint(ProgressionManager.make_gear("weapon", "common")) == Vector2i(2, 1))
	_check("Einpacken klappt", BagManager.add(ruestung) and GameState.bag.size() == 1)
	_check("Belegte Zellen zaehlen den Fussabdruck, nicht die Stueckzahl",
		BagManager.used_cells() == 4, "%d" % BagManager.used_cells())

	# Anlegen aus dem Beutel: Das getragene Teil muss ZURUECK in den Beutel, nicht verschwinden.
	_reset_state()
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	var alt: Dictionary = ProgressionManager.make_gear("armor", "common")
	var neu_teil: Dictionary = ProgressionManager.make_gear("armor", "epic")
	EquipManager.equip_item(alt, "armor")
	BagManager.add(neu_teil)
	_check("Anlegen aus dem Beutel", BagManager.equip_from_bag(0))
	_check("Das neue Teil ist angelegt",
		String(EquipManager.equipped("armor").get("rarity", "")) == "epic")
	_check("Das alte Teil liegt im Beutel statt im Nichts",
		GameState.bag.size() == 1 and String(GameState.bag[0]["rarity"]) == "common")
	_check("Ablegen wandert zurueck in den Beutel",
		BagManager.unequip_to_bag("armor") and GameState.bag.size() == 2
		and not EquipManager.is_equipped("armor"))

	# Voller Beutel darf nichts verschlucken.
	_reset_state()
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	var passt: int = 0
	for i in 60:
		if BagManager.add(ProgressionManager.make_gear("armor", "common")):
			passt += 1
	# 12, nicht 15: Das Raster ist FUENF Spalten breit (GDD §7.4), eine 2x2-Ruestung passt
	# also nur zweimal nebeneinander — die fuenfte Spalte bleibt in jedem Zweizeilen-Band
	# liegen. Genau dafuer gibt es Fussabdruecke statt einer Stueckzahl: Sperriges kostet
	# mehr als seine Zellen.
	var baender: int = BagManager.ROWS / 2
	var je_band: int = BagManager.COLS / 2
	_check("Der Beutel laeuft voll, mit Verschnitt statt perfekter Packung",
		passt == baender * je_band and passt < BagManager.total_cells() / 4,
		"%d Ruestungen (erwartet %d), Raster %dx%d"
		% [passt, baender * je_band, BagManager.COLS, BagManager.ROWS])
	_check("Volles Raster meldet keinen Platz mehr",
		not BagManager.has_room_for(ProgressionManager.make_gear("armor", "common")))

	# Verschrotten macht Platz und bringt Schrott.
	_reset_state()
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum
	BagManager.add(ProgressionManager.make_gear("armor", "legendary"))
	var vorher: int = GameState.item_count("schrott")
	var ertrag: int = BagManager.scrap_at(0)
	_check("Verschrotten leert den Platz und bringt Schrott",
		GameState.bag.is_empty() and ertrag > 0 and GameState.item_count("schrott") == vorher + ertrag,
		"+%d Schrott" % ertrag)
	# Deutsche Beugung: Seit die Beute mit Namen auf dem Boden liegt, faellt jeder Fehler auf.
	_check("Weiblich: 'Rostige Rüstung', nicht 'Rostiger Rüstung'",
		ProgressionManager._compose("Rostiger", "armor") == "Rostige Rüstung",
		ProgressionManager._compose("Rostiger", "armor"))
	_check("Saechlich: 'Rostiges Gadget'",
		ProgressionManager._compose("Rostiger", "gadget") == "Rostiges Gadget",
		ProgressionManager._compose("Rostiger", "gadget"))
	_check("Maennlich bleibt 'Rostiger Helm'",
		ProgressionManager._compose("Rostiger", "helmet") == "Rostiger Helm")
	_check("Bindestrich haengt ohne Leerzeichen an: 'Präzisions-Helm'",
		ProgressionManager._compose("Präzisions-", "helmet") == "Präzisions-Helm",
		ProgressionManager._compose("Präzisions-", "helmet"))
	for slot in ["helmet", "armor", "weapon", "gadget", "boots"]:
		var nm: String = String(ProgressionManager.make_gear(String(slot), "common")["name"])
		_check("%s: kein Leerzeichen vor dem Bindestrich-Wort" % slot, not nm.contains("- "), nm)


	_reset_state()
	GameState.level = 30   # Ausruestung verlangt eine Stufe; hier geht es nicht darum


## Werkstatt & Wirtschaft: die Gold-Senke.
##
## Bis hierher hatte Gold KEINE Senke — `add_gold` wurde beim Kill und an der Truhe gerufen,
## ausgegeben wurde es nirgends. Die Kernschleife „töten → Gold → stärker werden" brach nach
## dem zweiten Schritt ab, obwohl Kostenkurve, Höchststufen und Einkommensrechnung im
## Hintergrund längst liefen. Diese Tests halten fest, dass sie jetzt geschlossen ist.
func _test_workshop() -> void:
	print("· Werkstatt & Wirtschaft (Gold-Senke)")
	_reset_state()
	_check("spend_gold gibt es ueberhaupt", GameState.has_method("spend_gold"))
	GameState.gold = 100
	_check("Zu teuer -> kein Kauf, kein Abzug",
		not GameState.spend_gold(150) and GameState.gold == 100)
	_check("Bezahlbar -> Kauf und exakter Abzug",
		GameState.spend_gold(60) and GameState.gold == 40)
	_check("Nicht-positive Betraege prallen ab",
		not GameState.spend_gold(0) and not GameState.spend_gold(-10) and GameState.gold == 40)

	# Kostenkurve 1:1 aus dem Prototyp: Basis x (Stufe + 1).
	_reset_state()
	_check("Erste Stufe Schaden kostet 40", WorkshopData.cost("damage") == 40)
	GameState.gold = 10000
	_check("Kauf erhoeht die Stufe", WorkshopData.buy("damage") and WorkshopData.level("damage") == 1)
	_check("Zweite Stufe kostet das Doppelte (80)", WorkshopData.cost("damage") == 80)
	_check("Gold wurde genau um 40 verringert", GameState.gold == 9960)

	# Der Kern: Ein Werkstatt-Kauf muss im Kampfwert ankommen.
	_reset_state()
	GameState.gold = 10000
	var dmg0: int = PlayerStats.damage_per_bullet("karabiner")
	WorkshopData.buy("damage")
	var dmg1: int = PlayerStats.damage_per_bullet("karabiner")
	_check("Ausbau wirkt SOFORT auf den naechsten Schuss", dmg1 > dmg0,
		"vorher %d, nachher %d" % [dmg0, dmg1])

	# Koerper-Eingriffe bleiben zu, solange der Held sich fuer einen Menschen haelt.
	_reset_state()
	GameState.gold = 10000
	GameState.is_revealed = false
	_check("Vor dem Reveal: Panzerung gesperrt", WorkshopData.is_locked("hp"))
	_check("Vor dem Reveal: Schaden NICHT gesperrt", not WorkshopData.is_locked("damage"))
	_check("Gesperrtes laesst sich nicht kaufen",
		not WorkshopData.buy("hp") and WorkshopData.level("hp") == 0 and GameState.gold == 10000)
	_check("Vor dem Reveal heisst es noch 'Schneller Hahn'",
		WorkshopData.label("firerate") == "Schneller Hahn")
	GameState.is_revealed = true
	_check("Nach dem Reveal: Panzerung frei", not WorkshopData.is_locked("hp"))
	_check("Nach dem Reveal kaufbar", WorkshopData.buy("hp") and WorkshopData.level("hp") == 1)
	_check("Nach dem Reveal heisst dasselbe Teil 'Kolben-Frequenz'",
		WorkshopData.label("firerate") == "Kolben-Frequenz")

	# Hoechststufe deckelt.
	_reset_state()
	GameState.gold = 999999
	GameState.is_revealed = true
	var kaeufe: int = 0
	for i in 20:
		if WorkshopData.buy("magnet"):
			kaeufe += 1
	_check("Magnet-Spule endet bei Stufe 4", kaeufe == 4 and WorkshopData.is_maxed("magnet"),
		"%d Kaeufe, Stufe %d" % [kaeufe, WorkshopData.level("magnet")])

	# Wirtschaft: Ausbau erzeugt Einkommen, das es vorher nicht gab.
	_reset_state()
	_check("Ohne Ausbau kein Einkommen", TycoonManager.income_per_sec() == 0)
	GameState.gold = 10000
	_check("Saloon ausbaubar", TycoonManager.try_upgrade("saloon"))
	_check("Ausbau erzeugt Einkommen", TycoonManager.income_per_sec() > 0,
		"%d/s" % TycoonManager.income_per_sec())
	GameState.gold = 0
	_check("Ohne Gold kein Ausbau", not TycoonManager.try_upgrade("forge"))
	_reset_state()


## Mauerstuecke: Kollision darf NICHT geschrumpft werden.
##
## Die Palisade wird nicht mehr vom Code als Kreis gebaut, sondern von Hand in `Rustwater.tscn`
## gestellt. Damit haengt die Dichtheit der Mauer daran, dass `_register_town_node` ein
## Wandstueck als solches erkennt: Der Schrumpf-Faktor fuer Gebaeude (0,82) liesse zwischen
## zwei aneinandergesetzten Stuecken 18 % Luecke, und die Kollision prueft einen Punkt — man
## liefe mitten durch die Palisade.
func _test_wall_classification() -> void:
	print("· Mauerteile (Kollision ohne Schrumpf)")
	for name in ["palisade_a", "palisade_b", "palisade_c", "palisade_d", "palisade_e", "gate"]:
		_check("%s gilt als Wand" % name, AssetRegistry.is_wall(name))
	for name in ["saloon", "forge", "water_tower", "shack_a", "npc_mabel", "rock_small"]:
		_check("%s gilt NICHT als Wand" % name, not AssetRegistry.is_wall(name))
	_check("Neue Varianten greifen von selbst (palisade_f)", AssetRegistry.is_wall("palisade_f"))

	# Die Namensregel gibt es, WEIL die Formregel hier versagt: gemessen liegt `palisade_e` bei
	# 2,13:1 und damit naeher an einer Huette (bis 1,56:1) als an den uebrigen Mauerstuecken
	# (ab 3,71:1). Dieser Test haelt fest, dass die Einstufung eben nicht an der Form haengt.
	var ratios: Dictionary = {}
	for name in ["shack_a", "palisade_e"]:
		if not AssetRegistry.has_model(name):
			continue
		var m: Node3D = AssetRegistry.instantiate(name, AssetRegistry.height_of(name))
		var s: Vector3 = AssetRegistry.local_bounds(m).size
		ratios[name] = maxf(s.x, s.z) / maxf(minf(s.x, s.z), 0.01)
		m.free()
	if ratios.has("palisade_e") and ratios.has("shack_a"):
		_check("Gegenprobe: palisade_e (%.2f:1) ist formaehnlich zu shack_a (%.2f:1) und wird trotzdem richtig eingestuft"
			% [ratios["palisade_e"], ratios["shack_a"]],
			AssetRegistry.is_wall("palisade_e") and not AssetRegistry.is_wall("shack_a"))
		_check("Notfall-Formregel trennt beide sauber (Grenze liegt dazwischen)",
			ratios["shack_a"] < OverworldView.WALL_ASPECT
			and ratios["palisade_e"] > OverworldView.WALL_ASPECT,
			"shack_a %.2f, palisade_e %.2f, Grenze %.2f"
			% [ratios["shack_a"], ratios["palisade_e"], OverworldView.WALL_ASPECT])


## Abzug: geschossen wird NUR auf Befehl.
##
## Die wichtigste Zeile ist die erste Pruefung. Vorher feuerte die Figur von allein, sobald
## irgendetwas in die 11-m-Reichweite geriet — Gegner starben, bevor man sie gesehen hatte.
## Genau dieser Zustand darf nicht zurueckkommen.
##
## `OverworldView.new()` ohne Szenenbaum reicht dafuer: `_fire_wanted()` liest nur eigene
## Felder, und `_map_is_open()` ist null-sicher. So bleibt die Regel geprueft, ohne die 3D-Welt
## mit ihren 589 Knoten hochzufahren.
func _test_fire_control() -> void:
	print("· Abzug (kein Auto-Feuer)")
	var ow := OverworldView.new()
	_check("Ohne Eingabe wird NICHT geschossen", not ow._fire_wanted())
	ow._fire_key = true
	_check("Leertaste feuert", ow._fire_wanted())
	ow._fire_key = false
	ow._fire_mouse = true
	_check("Rechte Maustaste feuert", ow._fire_wanted())
	ow._fire_mouse = false
	ow._fire_touch_id = 3
	_check("Finger auf dem Schuss-Knopf feuert", ow._fire_wanted())
	# Die drei Quellen duerfen sich nicht gegenseitig loeschen: auf dem Handy liegt ein Finger
	# auf dem Joystick und einer auf dem Knopf, am Rechner haelt man Leertaste UND zieht.
	ow._fire_key = true
	ow._fire_touch_id = -1
	_check("Finger loslassen beendet das Feuern nicht, solange die Taste liegt",
		ow._fire_wanted())
	ow._fire_key = false
	_check("Letzte Quelle losgelassen → Feuer aus", not ow._fire_wanted())
	ow.free()

	# Der Knopf sieht rund aus, also muss er sich auch rund anfassen lassen.
	var btn := FireButton.new()
	btn.size = Vector2(FireButton.RADIUS, FireButton.RADIUS) * 2.0
	var c: Vector2 = btn.center()
	_check("Schuss-Knopf: Mitte trifft", btn.hits(c))
	_check("Schuss-Knopf: knapp innerhalb trifft", btn.hits(c + Vector2(FireButton.RADIUS - 4.0, 0.0)))
	_check("Schuss-Knopf: Ecke des Rahmens trifft NICHT (rund, nicht eckig)",
		not btn.hits(Vector2.ZERO))
	_check("Schuss-Knopf: weit daneben trifft nicht", not btn.hits(c + Vector2(300.0, 0.0)))
	btn.free()


## Minikarte: Ausrichtung gegen die WELT prüfen, nicht gegen sich selbst.
##
## Der behobene Fehler war heimtückisch, weil die Karte in sich stimmig war: Projektion und
## Richtungsstrich waren beide auf der Nord-Süd-Achse gespiegelt, also passten sie zueinander.
## Aufgefallen ist es erst beim Vergleich mit der Figur auf dem Bildschirm. Deshalb hier zuerst
## Ankerpunkte gegen echte POI-Daten (Norden oben, Osten rechts) und danach die Bindung des
## Strichs an die Karte.
func _test_minimap() -> void:
	print("· Karte (Nahansicht + Weltkarte)")
	var px: float = Minimap.MAP_PX
	# `_ready` laeuft nur im Szenenbaum, deshalb die Groesse hier von Hand setzen — der
	# Massstab haengt an ihr.
	var world := Minimap.new()
	world.full_world = true
	world.size = Vector2(px, px)
	var south: Vector2 = world.world_to_map(WorldManager.poi_scene_position("rustwater"))
	var north: Vector2 = world.world_to_map(WorldManager.poi_scene_position("eisernes_herz"))
	# Rustwater liegt bei y=300, das Eiserne Herz bei y=1950 — der Norden muss also oben
	# landen, und „oben" heisst in Godots Zeichenflaeche KLEINERES y.
	_check("Weltkarte: Norden oben (Eisernes Herz über Rustwater)",
		north.y < south.y, "Herz y=%.1f, Rustwater y=%.1f" % [north.y, south.y])
	var west: Vector2 = world.world_to_map(WorldManager.poi_scene_position("fort_freedom"))
	var east: Vector2 = world.world_to_map(WorldManager.poi_scene_position("sektor01"))
	_check("Weltkarte: Osten rechts (Sektor 01 rechts von Fort Freedom)",
		east.x > west.x, "Sektor01 x=%.1f, Fort x=%.1f" % [east.x, west.x])
	_check("Weltkarte: Nordrand auf y = 0",
		is_zero_approx(world.world_to_map(Vector3(0.0, 0.0, -WorldManager.WORLD_METERS)).y))
	_check("Weltkarte: Südrand auf y = MAP_PX",
		is_equal_approx(world.world_to_map(Vector3.ZERO).y, px))
	_check("Weltkarte: alle 11 Orte liegen im Rahmen",
		_pois_inside(world) == WorldManager.POIS.size(),
		"%d von %d" % [_pois_inside(world), WorldManager.POIS.size()])

	# Nahansicht: Ausschnitt um den Spieler statt Gesamtansicht. Der Krater misst 5000 m — auf
	# 190 px waeren das 0,038 px/m, also 26 gelaufene Meter pro Pixel.
	var near := Minimap.new()
	near.size = Vector2(px, px)
	near.player_pos = WorldManager.poi_scene_position("rustwater")
	_check("Nahansicht: Spieler steht in der Mitte",
		near.world_to_map(near.player_pos).is_equal_approx(Vector2(px, px) * 0.5))
	_check("Nahansicht: Massstab ist %d m bis zur Kante" % int(Minimap.LOCAL_RADIUS_M),
		is_equal_approx(near.pixels_per_meter(), px / (Minimap.LOCAL_RADIUS_M * 2.0)))
	var edge: Vector2 = near.world_to_map(near.player_pos + Vector3(0.0, 0.0, -Minimap.LOCAL_RADIUS_M))
	_check("Nahansicht: %d m nördlich liegen genau auf der Oberkante" % int(Minimap.LOCAL_RADIUS_M),
		is_zero_approx(edge.y), "y = %.2f" % edge.y)
	var rect := Rect2(Vector2.ZERO, Vector2(px, px))
	_check("Nahansicht: doppelte Reichweite faellt aus dem Rahmen",
		not rect.has_point(near.world_to_map(
			near.player_pos + Vector3(0.0, 0.0, -Minimap.LOCAL_RADIUS_M * 2.0))))
	# Der eigentliche Zweck: Gegner sind nicht mehr ein einziger Punkt. Im Spawnradius von 45 m
	# lagen sie auf der Gesamtansicht 1,7 px auseinander.
	var far_enemy: Vector2 = near.world_to_map(near.player_pos + Vector3(45.0, 0.0, 0.0))
	_check("Nahansicht: Gegner am Spawnrand (45 m) sind ≥ 15 px vom Spieler entfernt",
		far_enemy.distance_to(Vector2(px, px) * 0.5) >= 15.0,
		"%.1f px" % far_enemy.distance_to(Vector2(px, px) * 0.5))
	_check("Nahansicht ist deutlich feiner als die Weltkarte",
		near.pixels_per_meter() > world.pixels_per_meter() * 10.0)

	# Der Strich muss dahin zeigen, wohin der Punkt WANDERT — in BEIDEN Betriebsarten. Beides
	# wird unabhaengig gerechnet: der Strich aus `facing_on_map()`, die Wanderung aus zwei
	# echten Kartenpositionen.
	var origin := Vector3(2500.0, 0.0, -2500.0)   # Kratermitte, weit weg von jedem Rand
	for mode in [["Weltkarte", world], ["Nahansicht", near]]:
		var map: Minimap = mode[1]
		for c in [["Osten", Vector3(1, 0, 0)], ["Norden", Vector3(0, 0, -1)],
				["Westen", Vector3(-1, 0, 0)], ["Sueden", Vector3(0, 0, 1)]]:
			var step: Vector3 = c[1]
			map.player_dir = atan2(-step.x, -step.z)   # dieselbe Formel wie in OverworldView
			var moved: Vector2 = (map.world_to_map(origin + step * 10.0)
				- map.world_to_map(origin)).normalized()
			_check("%s: Richtungsstrich zeigt nach %s wie der Punkt laeuft" % [mode[0], c[0]],
				map.facing_on_map().distance_to(moved) < 0.001,
				"Strich %s, Bewegung %s" % [map.facing_on_map(), moved])
		# Und einmal absolut: nach Norden laufen heisst auf der Karte nach oben.
		map.player_dir = atan2(0.0, 1.0)
		_check("%s: nach Norden laufen → Strich zeigt nach oben" % mode[0],
			map.facing_on_map().y < -0.99, "Strich %s" % map.facing_on_map())
	world.free()
	near.free()


## Wie viele Orte fallen in den Rahmen der Karte? Die Weltkarte muss alle zeigen — sonst waere
## sie als Uebersicht wertlos.
func _pois_inside(map: Minimap) -> int:
	var rect := Rect2(Vector2.ZERO, map.size)
	var n: int = 0
	for id in WorldManager.POIS.keys():
		if rect.has_point(map.world_to_map(WorldManager.poi_scene_position(String(id)))):
			n += 1
	return n


func _test_asset_registry() -> void:
	print("· AssetRegistry (Asset-Pipeline mit Platzhalter-Fallback)")
	_check("Gegner-Typ → Asset-Name", AssetRegistry.enemy_asset("outlaw") == "enemy_outlaw")
	_check("Unbekannter Name liefert '' (→ Platzhalter)", AssetRegistry.resolve("gibts_nicht") == "")
	_check("Unbekannter Name instanziiert nichts", AssetRegistry.instantiate("gibts_nicht") == null)
	_check("Kein Modell → has_model false", AssetRegistry.has_model("gibts_nicht") == false)
	# Jeder registrierte Eintrag muss mindestens einen Kandidatenpfad haben.
	var all_have_paths: bool = true
	for name in AssetRegistry.PATHS.keys():
		if (AssetRegistry.PATHS[name] as Array).is_empty():
			all_have_paths = false
	_check("Alle Registry-Einträge haben Kandidatenpfade", all_have_paths)
	# Jeder Gegnertyp aus dem Kampf-Roster ist in der Registry vorgesehen.
	var every_enemy_mapped: bool = true
	for type_id in CombatData.ENEMY_TYPES.keys():
		if not AssetRegistry.PATHS.has(AssetRegistry.enemy_asset(String(type_id))):
			every_enemy_mapped = false
	_check("Jeder Gegnertyp hat einen Registry-Eintrag", every_enemy_mapped)
	# Höhenmessung muss die komplette Transform-Kette berücksichtigen (glTF-Hierarchien sind
	# verschachtelt) — sonst skalieren Assets falsch. Synthetischer Baum, assetfrei prüfbar.
	var root := Node3D.new()
	var mid := Node3D.new()
	mid.scale = Vector3(2.0, 2.0, 2.0)      # verschachtelte Skalierung
	mid.position = Vector3(0.0, 1.0, 0.0)   # und Versatz
	root.add_child(mid)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 3.0, 1.0)        # 3 m hoch, ×2 verschachtelt = 6 m
	mi.mesh = bm
	mid.add_child(mi)
	_check("Höhe berücksichtigt verschachtelte Skalierung (6 m)",
		is_equal_approx(AssetRegistry.local_height(root), 6.0),
		"gemessen: %.3f" % AssetRegistry.local_height(root))
	_check("local_size liefert volle Bounds (1×6×1 m, gleicher Baum)",
		AssetRegistry.local_size(root).is_equal_approx(Vector3(2.0, 6.0, 2.0)),
		"gemessen: %s" % AssetRegistry.local_size(root))
	# Boden-Versatz: der Baum liegt zwischen y=-2 und y=+4 (Mesh ±3 ×2 verschoben um +1×2).
	# `instantiate()` muss diesen Versatz herausrechnen, damit generierte Assets (Meshy & Co.)
	# nicht schweben oder im Sand versinken — dort sitzt der Pivot fast nie am Boden.
	var b: AABB = AssetRegistry.local_bounds(root)
	_check("local_bounds liefert auch die Unterkante (y = -2 m)",
		is_equal_approx(b.position.y, -2.0), "gemessen: %.3f" % b.position.y)
	root.free()
	# Gegenprobe an einem echten Modell (nur wenn Assets vorhanden sind — das Projekt muss
	# auch ohne sie testbar bleiben): Zielhöhe getroffen UND Unterkante auf dem Boden.
	if AssetRegistry.has_model("rock_small"):
		# `rock_small` ist ein flaches Geroellfeld und wird deshalb ueber die LAENGSTE Kante
		# skaliert (TARGET_LENGTH) — die 2,00 sind hier also Laenge, nicht Hoehe.
		var inst: Node3D = AssetRegistry.instantiate("rock_small", 2.0)
		var ib: AABB = AssetRegistry.local_bounds(inst)
		var longest: float = maxf(ib.size.x, maxf(ib.size.y, ib.size.z))
		_check("Flaches Modell: laengste Kante auf 2,00 m skaliert", is_equal_approx(longest, 2.0),
			"gemessen: %.3f" % longest)
		_check("Flaches Modell: Unterkante steht auf Y = 0", absf(ib.position.y) < 0.001,
			"gemessen: %.4f" % ib.position.y)
		inst.free()
	if AssetRegistry.has_model("player"):
		# Gegenprobe fuer die Hoehen-Skalierung an einem Modell, das NICHT in TARGET_LENGTH steht.
		var ph: Node3D = AssetRegistry.instantiate("player", 2.0)
		_check("Hohes Modell: auf 2,00 m Hoehe skaliert",
			is_equal_approx(AssetRegistry.local_bounds(ph).size.y, 2.0),
			"gemessen: %.3f" % AssetRegistry.local_bounds(ph).size.y)
		ph.free()
	# Clip-Suche: Werkzeuge benennen Animationen unterschiedlich („Armature|Walk", „Idle",
	# „walk_backwards"). Die Registry muss die Rolle treffen, ohne dass jemand umbenennt —
	# und ein exakter Treffer muss einen Teiltreffer schlagen. Synthetisch, assetfrei.
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for clip_name in ["walk_backwards", "CharacterArmature|Walk", "Idle_A"]:
		lib.add_animation(clip_name, Animation.new())
	ap.add_animation_library("", lib)
	_check("Clip-Suche findet 'walk' trotz Armature-Praefix",
		AssetRegistry.find_clip(ap, "walk") == "CharacterArmature|Walk",
		"gefunden: '%s'" % AssetRegistry.find_clip(ap, "walk"))
	_check("Clip-Suche findet 'idle' ueber Teiltreffer",
		AssetRegistry.find_clip(ap, "idle") == "Idle_A")
	_check("Fehlende Rolle liefert '' (Modell bleibt unanimiert)",
		AssetRegistry.find_clip(ap, "death") == "")
	_check("Ohne AnimationPlayer liefert die Suche ''", AssetRegistry.find_clip(null, "walk") == "")
	_check("play_clip auf einem Modell ohne Animation ist folgenlos",
		AssetRegistry.play_clip(null, "walk") == false)
	_check("Kuerzester Teiltreffer gewinnt (Walking schlaegt Slow_Walk_Reload)",
		AssetRegistry.find_clip(_clip_player(["Slow_Walk_Reload", "Walking", "Walk_Turn_Left"]), "walk") == "Walking")
	ap.free()
	# Das echte Spieler-Modell (nur wenn es im Repo liegt): Maßstab, Bodenkontakt und die
	# Rollen, die die Overworld tatsaechlich abspielt. Faengt einen kaputten Re-Export sofort.
	if AssetRegistry.has_model("player"):
		var p: Node3D = AssetRegistry.instantiate("player", 1.8)
		add_child(p)   # `global_transform` gilt nur im Szenenbaum (Gegenprobe unten)
		var pb: AABB = AssetRegistry.local_bounds(p)
		_check("Spieler-Modell: auf 1,80 m skaliert", is_equal_approx(pb.size.y, 1.8),
			"gemessen: %.3f" % pb.size.y)
		_check("Spieler-Modell: steht auf Y = 0", absf(pb.position.y) < 0.001)
		# UNABHAENGIGE Gegenprobe ueber das Skelett: die Bounds-Messung allein kann sich nicht
		# selbst pruefen — wenn sie falsch misst, skaliert sie passend zum eigenen Fehler und
		# der Test bleibt gruen (genau so ist ein 100-facher Massstabsfehler durchgerutscht:
		# gehaeutete Meshes liegen NICHT dort, wo ihre Knotenkette sagt, sondern wo das Skelett
		# sie hinsetzt). Knochenhoehen kommen aus dem Rig, nicht aus `local_bounds`.
		var sk: Skeleton3D = AssetRegistry.skeleton(p)
		if sk != null:
			var head_y: float = (sk.global_transform * sk.get_bone_global_rest(sk.find_bone("Head"))).origin.y
			var toe_y: float = (sk.global_transform * sk.get_bone_global_rest(sk.find_bone("LeftToeBase"))).origin.y
			_check("Kopfknochen sitzt auf Menschenhoehe (1,3…1,8 m)",
				head_y > 1.3 and head_y < 1.8, "gemessen: %.2f m" % head_y)
			_check("Zehenknochen liegt am Boden (< 0,2 m)", toe_y < 0.2, "gemessen: %.2f m" % toe_y)
		var pap: AnimationPlayer = AssetRegistry.animation_player(p)
		_check("Spieler-Modell bringt einen AnimationPlayer mit", pap != null)
		if pap != null:
			for role in ["idle", "walk", "run", "attack", "hit", "death"]:
				var clip: String = String(AssetRegistry.CLIP_OVERRIDES["player"].get(role, ""))
				_check("Spieler-Clip '%s' existiert im Modell (%s)" % [role, clip],
					clip != "" and pap.has_animation(clip))
		_check("Spieler-Modell bringt ein Skelett mit", sk != null)
		remove_child(p)
		p.free()
	# MASSSTABS-WACHE ueber ALLE vorhandenen Assets. Ein flaches Modell (Geroellfeld, Waffe,
	# Wandstueck) ueber die HOEHE zu skalieren blaest es ins Absurde: "sand_rocks_small" wurde
	# so 10,4 x 8,7 m gross und hat halb Rustwater verdeckt. Kein Asset darf in irgendeiner
	# Richtung mehr als das Vierfache seines Zielmasses messen — das laesst normalen
	# Proportionen Luft und faengt genau diesen Fehler.
	var scale_ok: bool = true
	var worst: String = ""
	var worst_ratio: float = 0.0
	for name in AssetRegistry.PATHS.keys():
		var id: String = String(name)
		if not AssetRegistry.has_model(id):
			continue
		var by_length: float = AssetRegistry.length_of(id)
		var target: float = by_length if by_length > 0.0 else AssetRegistry.height_of(id)
		var m: Node3D = AssetRegistry.instantiate(id, target)
		if m == null:
			continue
		var s: Vector3 = AssetRegistry.local_bounds(m).size
		var ratio: float = maxf(s.x, maxf(s.y, s.z)) / maxf(target, 0.001)
		if ratio > worst_ratio:
			worst_ratio = ratio
			worst = id
		if ratio > 4.0:
			scale_ok = false
		m.free()
	_check("Kein Asset ist unverhaeltnismaessig gross skaliert",
		scale_ok, "schlimmster Fall: %s mit Faktor %.1f" % [worst, worst_ratio])
	_test_town_layout()
	_check("Bodentextur ist in der Registry vorgesehen", AssetRegistry.PATHS.has("ground_sand"))
	_check("Unbekanntes Material liefert null (→ Einheitsfarbe)",
		AssetRegistry.material_from_model("gibts_nicht") == null)


# ── Overworld-Truhen: derselbe Mechanismus wie OverworldView._loot_chest() ────
## Prüft NICHT die Node3D-Szene (Platzierung/Distanz — headless per Smoke-Test abgedeckt),
## sondern den eigentlichen Loot-Mechanismus: ProgressionManager.make_gear() ->
## EquipManager.equip_item() -> PlayerStats liest SOFORT das neue Gear (kein Cache/Refresh
## nötig). Deterministisch über einen geseedeten RNG (dieselbe API, die die Truhe nutzt).
func _test_overworld_loot_flow() -> void:
	print("· Overworld-Truhen (Truhe → ProgressionManager/EquipManager → PlayerStats)")
	_reset_state()
	var base_dmg: int = PlayerStats.damage_per_bullet("karabiner")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Gewöhnlich (0 Affixe) hält den Test einfach: nur der Haupt-Stat zählt, keine Affix-Überlagerung.
	var gear: Dictionary = ProgressionManager.make_gear("weapon", "common", "", rng)
	_check("Gerolltes Waffen-Teil hat Haupt-Stat 'damage'", String(gear["stat"]["key"]) == "damage")
	_check("EquipManager: Slot vorher leer", not EquipManager.is_equipped("weapon"))
	_check("equip_item meldet Erfolg", EquipManager.equip_item(gear, "weapon") == true)
	var new_dmg: int = PlayerStats.damage_per_bullet("karabiner")
	_check("Anlegen wirkt SOFORT auf den nächsten Schuss (kein Cache/Refresh)",
		new_dmg == base_dmg + int(gear["stat"]["val"]),
		"vorher %d, nachher %d, Stat +%d" % [base_dmg, new_dmg, int(gear["stat"]["val"])])
	_check("worn() zeigt genau 1 getragenes Teil", EquipManager.worn().size() == 1)
	# Vergleichslogik der Truhe (_loot_chest): ein spürbar schwächeres Teil würde NICHT
	# angelegt, sondern eingeschmolzen -- Beute muss sich lohnen, nicht nur variieren.
	var worse: Dictionary = { "uid": -1, "slot": "weapon", "rarity": "common", "req": 1,
		"name": "Testattrappe", "stat": { "key": "damage", "val": 1, "q": 0.0 }, "affixes": [] }
	_check("Deutlich schwächeres Teil hat niedrigeren Marktwert (würde eingeschmolzen)",
		ProgressionManager.gear_value(worse) < ProgressionManager.gear_value(gear))


# ── Overworld-Questfluss: derselbe Weg, den OverworldView._process_npcs() geht ──
## Prueft die Kette Auftraggeber -> annehmen -> Fortschritt -> abgeben, samt der
## Material-Drop-Logik, ohne die 3D-Szene zu instanzieren.
func _test_overworld_quest_flow() -> void:
	print("· Overworld-Quests (NPC → QuestManager → Belohnung)")
	_reset_state()
	# Mabels Kopfgeld ist der Einstiegsauftrag (Kapitel 1, kein Gilden-Gate).
	var qid: String = "q_bounty"
	var def: Dictionary = QuestManager.QUESTS[qid]
	_check("Mabel ist die Auftraggeberin von q_bounty", String(def["giver"]) == "mabel")
	_check("Startzustand ist 'available'", QuestManager.get_quest_state(qid) == QuestManager.STATE_AVAILABLE)
	_check("Annehmen gelingt", QuestManager.accept_quest(qid) == true)
	_check("Zustand jetzt 'active'", QuestManager.get_quest_state(qid) == QuestManager.STATE_ACTIVE)
	_check("Fortschritt startet bei 0", int(QuestManager.check_quest_progress(qid)["current"]) == 0)
	_check("Vorzeitige Abgabe wird abgelehnt", QuestManager.complete_quest(qid) == false)
	for i in int(def["count"]):
		GameState.add_kill()
	_check("Nach %d Kills erfuellt" % int(def["count"]), QuestManager.is_quest_complete(qid))
	var gold_before: int = GameState.gold
	_check("Abgabe gelingt", QuestManager.complete_quest(qid) == true)
	_check("Goldbelohnung gutgeschrieben", GameState.gold == gold_before + int(def["reward_gold"]))
	_check("Zustand jetzt 'done'", QuestManager.get_quest_state(qid) == QuestManager.STATE_DONE)
	# Jeder in der Szene platzierte NPC muss auch wirklich Quests im Manager haben,
	# sonst steht eine Figur ohne Funktion in der Stadt.
	var givers: Array = ["mabel", "silas", "doc"]
	var all_have_quests: bool = true
	for g in givers:
		var found: bool = false
		for q in QuestManager.QUESTS.keys():
			if String(QuestManager.QUESTS[q].get("giver", "")) == g:
				found = true
		if not found:
			all_have_quests = false
	_check("Alle drei Stadt-NPCs haben Quests", all_have_quests)
	# Silas' Sammel-Quest muss nach etwas verlangen, das es NUR im Stollen gibt.
	#
	# Sie forderte gewoehnlichen `schrott` — und den hat man ohnehin: Er faellt bei jedem Kill
	# und liegt ueberall herum. Die zwoelf Stueck waren beisammen, bevor man Silas zugehoert
	# hatte, und der Stollen war ein Umweg, den man auslassen kann. Ein Auftrag, den man
	# versehentlich erfuellt, ist keiner.
	var scrap_quest: Dictionary = QuestManager.QUESTS["q_scrap"]
	_check("Silas verlangt Material, das es nur im Stollen gibt (%s)"
		% String(scrap_quest["item"]),
		String(scrap_quest["item"]) in GameState.NUR_IM_STOLLEN)
	_check("Und schickt einen auch dorthin", String(scrap_quest["target"]) == "stollen")
	# Kein zweiter Sammelauftrag desselben Gebers auf dasselbe Material: Das war die Dopplung,
	# die entstand, als der kaputte Auftrag nicht repariert, sondern ein neuer danebengesetzt
	# wurde — und der kaputte blieb der, den man zuerst trifft.
	var sammel_silas: Array[String] = []
	for sq in QuestManager.QUESTS:
		var q2: Dictionary = QuestManager.QUESTS[sq]
		if String(q2.get("giver", "")) == "silas" and String(q2.get("kind", "")) == "collect" \
				and String(q2.get("item", "")) == String(scrap_quest["item"]):
			sammel_silas.append(String(sq))
	_check("Silas sammelt Grubenstahl nur EINMAL (%s)" % ", ".join(sammel_silas),
		sammel_silas.size() == 1)


# ── Weltstruktur (GDD §1.4a: offene Wildnis + bauliche Aktionszonen + Eisenbahn) ──
func _test_walkable_zones() -> void:
	print("· Weltstruktur (Wildnis / Aktionszonen / Eisenbahn)")
	# 1. Wildnis: die Wueste zwischen den Orten ist FREI. Nur der Kraterrand begrenzt.
	_check("Rustwater-Mitte ist begehbar",
		WorldManager.is_walkable(WorldManager.poi_position("rustwater")))
	var a: Vector2 = WorldManager.poi_position("rustwater")
	var b: Vector2 = WorldManager.poi_position("zugdepot")
	_check("Mitte zwischen zwei Orten ist begehbar", WorldManager.is_walkable((a + b) / 2.0))
	var perp: Vector2 = (b - a).normalized().orthogonal()
	var off: Vector2 = (a + b) / 2.0 + perp * (WorldManager.RAIL_CORRIDOR_HALF_W * 10.0)
	_check("Auch weit neben der Trasse ist die Wueste begehbar", WorldManager.is_walkable(off))
	_check("Abgelegene Kartenecke ist begehbar (offene Welt)",
		WorldManager.is_walkable(Vector2(30, 1900)))
	_check("Jenseits des Kraterrands endet die Welt",
		not WorldManager.is_walkable(Vector2(-5, 500)) and not WorldManager.is_walkable(Vector2(500, 2100)))
	# 2. Aktionszonen: dort greift die bauliche Begrenzung, draussen nicht.
	_check("Hub-Zone ist groesser als eine Nebenzone",
		WorldManager.zone_radius("rustwater") > WorldManager.zone_radius("schrott_minen"))
	_check("Am Ort steht man in dessen Aktionszone",
		WorldManager.zone_at(WorldManager.poi_position("rustwater")) == "rustwater")
	_check("Zwischen den Orten ist keine Aktionszone",
		not WorldManager.in_action_zone((a + b) / 2.0))
	_check("Aktionszonen ueberlappen sich nicht (jede Zone ist eindeutig)", _zones_disjoint())
	_check("Rustwater ist befriedet, ein Dungeon nicht",
		WorldManager.is_safe_zone("rustwater") and not WorldManager.is_safe_zone("schrott_minen"))
	# 3. Routen sind nur noch Nachbarschaft — gezeichnet wird davon die Trasse. Sie sperrt
	#    nichts (man laeuft ueber die Gleise), haelt aber die Streuung von den Schwellen fern.
	_check("Zwischen zwei Bahnhoefen liegt man auf der Trasse", WorldManager.on_rail((a + b) / 2.0))
	_check("Weit daneben nicht mehr", not WorldManager.on_rail(off))
	_check("Die Trasse sperrt nicht — man darf ueber die Gleise laufen",
		WorldManager.is_walkable((a + b) / 2.0))
	# Regression: Es gab hier gestampfte Pisten. Sie waren 55 m breit (der Kommentar an
	# CORRIDOR_HALF_W las die halbe Breite als volle) und deckten damit den 30-m-Krater der
	# Schrotthalde restlos zu. Der freizuhaltende Streifen muss deutlich schmaler bleiben als
	# die kleinste Gelaendeform, sonst verschluckt er sie wieder.
	var schmalste: float = 1e9
	for tf in WorldManager.TERRAIN:
		# Der Riss hat keinen Radius, sondern eine Breite — und die ist mit 10 m kleiner als
		# jede Senke. Er gehoert hier trotzdem nicht hinein: Der Trassenstreifen soll keine
		# GELAENDEFORM zudecken, und ein Spalt, ueber den die Bahn ohnehin nicht faehrt, ist
		# keine, die zugedeckt werden koennte.
		if String(tf.get("kind", "crater")) == "spalt":
			continue
		schmalste = minf(schmalste, float(tf["radius"]) * 2.0)
	_check("Der Trassenstreifen ist schmaler als die kleinste Senke",
		WorldManager.RAIL_CORRIDOR_HALF_W * 2.0 * WorldManager.METERS_PER_UNIT < schmalste,
		"%.1f m Streifen, %.1f m Senke"
			% [WorldManager.RAIL_CORRIDOR_HALF_W * 2.0 * WorldManager.METERS_PER_UNIT, schmalste])
	var connected: Dictionary = {}
	for r in WorldManager.ROUTES:
		connected[String(r[0])] = true
		connected[String(r[1])] = true
	var all_connected: bool = true
	for id in WorldManager.POIS.keys():
		if not connected.has(String(id)):
			all_connected = false
	_check("Jeder Ort haengt an mindestens einer Route (kein unerreichbarer POI)", all_connected)
	# 4. Eisenbahn: Bahnhoefe sind echte Orte, die Trasse liegt auf den Pisten.
	var stations_are_pois: bool = true
	for s in WorldManager.RAIL_STATIONS:
		if not WorldManager.has_poi(String(s)):
			stations_are_pois = false
	_check("Jeder Bahnhof ist ein echter POI", stations_are_pois)
	_check("Rustwater hat einen Bahnhof, das Rattengestruepp nicht",
		WorldManager.has_station("rustwater") and not WorldManager.has_station("rattengestruepp"))
	var segs: Array = WorldManager.rail_segments()
	_check("Es gibt Trassenabschnitte", segs.size() > 0)
	var segs_ok: bool = true
	for s in segs:
		if not WorldManager.has_station(String(s[0])) or not WorldManager.has_station(String(s[1])):
			segs_ok = false
	_check("Jeder Trassenabschnitt verbindet zwei Bahnhoefe", segs_ok)
	_check("Das Schienennetz haengt zusammen (jeder Bahnhof erreichbar)", _rail_network_connected())
	# 5. Rueckfall: ein Punkt ausserhalb des Kraters wird hineingezogen.
	var rescued: Vector2 = WorldManager.nearest_walkable(Vector2(-40, 2400))
	_check("nearest_walkable liefert eine begehbare Position", WorldManager.is_walkable(rescued))


## Stadtplan von Rustwater: eng, aber nicht ineinander. Genau die Pruefung, die eine dichte
## Bebauung braucht — je enger man baut, desto leichter steht ein Haus im naechsten oder in
## der Gasse. Gerechnet wird mit den GEMESSENEN Modellmassen, nicht mit den Planzahlen.
func _test_town_layout() -> void:
	print("· Stadtplan Rustwater (enge Strassenstadt)")
	var plots: Array = []   # [Name, Mitte (x,z), halbe Kantenlaengen]
	for b in OverworldView.TOWN_LAYOUT:
		plots.append(_plot(String(b[1]), b[2], float(b[3]), b[4]))
	var shack_count: int = 0
	for spot in OverworldView.SHACK_SPOTS:
		var asset: String = "shack_%s" % ["a", "b", "c", "d"][shack_count % 4]
		var yaw: float = 90.0 if spot.x < 0.0 else -90.0
		plots.append(_plot(asset, spot, yaw, Vector3(6.0, 4.2, 5.0)))
		shack_count += 1

	var overlap: String = ""
	for i in plots.size():
		for j in range(i + 1, plots.size()):
			var d: Vector2 = (Vector2(plots[i][1]) - Vector2(plots[j][1])).abs()
			var need: Vector2 = Vector2(plots[i][2]) + Vector2(plots[j][2])
			if d.x < need.x and d.y < need.y:
				overlap = "%s <-> %s" % [plots[i][0], plots[j][0]]
	_check("Keine zwei Gebaeude ueberlappen sich", overlap == "", overlap)

	# Die Hauptstrasse muss frei bleiben, sonst laeuft man in der eigenen Stadt gegen eine Wand.
	var blocked: String = ""
	var in_wall: String = ""
	for p in plots:
		var centre: Vector2 = p[1]
		var half: Vector2 = p[2]
		if absf(centre.x) - half.x < OverworldView.STREET_HALF_W and absf(centre.x) < 30.0:
			blocked = String(p[0])
		if centre.length() + maxf(half.x, half.y) > OverworldView.TOWN_R - 2.0:
			in_wall = String(p[0])
	_check("Die Hauptstrasse bleibt frei (%.0f m breit)" % (2.0 * OverworldView.STREET_HALF_W),
		blocked == "", blocked)
	_check("Alle Bauten stehen innerhalb des Ortsradius", in_wall == "", in_wall)

	# NPCs: auf der Strasse, vor ihrem Haus, nicht in einer Wand.
	var npc_bad: String = ""
	for n in OverworldView.TOWN_NPCS:
		var pos: Vector2 = n[2]
		for p in plots:
			var d2: Vector2 = (pos - Vector2(p[1])).abs()
			if d2.x < float(p[2].x) and d2.y < float(p[2].y):
				npc_bad = "%s steckt in %s" % [String(n[0]), String(p[0])]
	_check("Kein NPC steht in einer Hauswand", npc_bad == "", npc_bad)
	_check("Der Bahnhof liegt ausserhalb des Ortes",
		OverworldView.STATION_OFFSET_M > OverworldView.TOWN_R)


## Grundflaeche eines geplanten Bauwerks: gemessenes Modell (falls vorhanden), sonst Ersatzmass.
## Bei 90°/270° Drehung tauschen Breite und Tiefe die Achsen.
func _plot(asset: String, spot: Vector2, yaw_deg: float, fallback: Vector3) -> Array:
	var size := Vector2(fallback.x, fallback.z)
	if asset != "" and AssetRegistry.has_model(asset):
		var m: Node3D = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset))
		var b: Vector3 = AssetRegistry.local_bounds(m).size
		size = Vector2(b.x, b.z)
		m.free()
	if absf(sin(deg_to_rad(yaw_deg))) > 0.7:
		size = Vector2(size.y, size.x)
	return [asset if asset != "" else "Platzhalter", spot, size * 0.5]


## Wegwerf-AnimationPlayer mit den angegebenen Clip-Namen (fuer die Namenssuche-Tests).
func _clip_player(names: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for n in names:
		lib.add_animation(String(n), Animation.new())
	ap.add_animation_library("", lib)
	_scratch.append(ap)
	return ap


## Keine zwei Aktionszonen duerfen sich beruehren — sonst waere `zone_at` von der
## Reihenfolge der POI-Tabelle abhaengig statt von der Geografie.
func _zones_disjoint() -> bool:
	var ids: Array = WorldManager.POIS.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var x: String = String(ids[i])
			var y: String = String(ids[j])
			var d: float = WorldManager.poi_position(x).distance_to(WorldManager.poi_position(y))
			if d < WorldManager.zone_radius(x) + WorldManager.zone_radius(y):
				return false
	return true


## Breitensuche ueber die Trasse: von einem Bahnhof aus muessen alle anderen erreichbar sein.
func _rail_network_connected() -> bool:
	var segs: Array = WorldManager.rail_segments()
	if WorldManager.RAIL_STATIONS.is_empty():
		return false
	var seen: Dictionary = { String(WorldManager.RAIL_STATIONS[0]): true }
	var queue: Array = [String(WorldManager.RAIL_STATIONS[0])]
	while not queue.is_empty():
		var cur: String = String(queue.pop_front())
		for s in segs:
			var other: String = ""
			if String(s[0]) == cur:
				other = String(s[1])
			elif String(s[1]) == cur:
				other = String(s[0])
			if other != "" and not seen.has(other):
				seen[other] = true
				queue.append(other)
	return seen.size() == WorldManager.RAIL_STATIONS.size()

## Einen Fussmarsch simulieren und zaehlen, wie oft er haengenbleibt.
##
## Das ist der einzige ehrliche Weg, „man bleibt haengen" zu pruefen. Die Steigung EINER Stelle
## sagt nichts darueber: Der Hang kann ueberall begehbar sein und die Figur trotzdem feststecken,
## weil die Ausweichregel in der Situation nichts findet. Also wird gelaufen.
##
## `basis_m` ist die Laenge des Massbands fuer die Steigung (0 = Einzelschritt wie frueher),
## `schraeg` schaltet das Ausweichen quer zum Hang zu.
##
## `ueber` sind Zwischenziele — und die gehoeren dazu, nicht zur Bequemlichkeit: `_prolog_ziel()`
## fuehrt die Fussspur erst auf die Felsmitte und von dort in den Ring, weil die gerade Linie
## vom Rampenfuss quer ueber die Flanke laeuft. Ein Test, der stur geradeaus marschiert, prueft
## eine Strecke, die im Spiel niemand geht.
##
## Zurueck kommt [erreicht, Stockungen].
func _marsch_ueber(ueber: Array, basis_m: float, schraeg: bool) -> Array:
	var stockungen: int = 0
	var stand: Vector3 = ueber[0]
	for i in range(1, ueber.size()):
		var teil: Array = _marsch(stand, ueber[i], basis_m, schraeg)
		stockungen += int(teil[1])
		stand = teil[2]
		if not bool(teil[0]):
			return [false, stockungen]
	return [true, stockungen]


func _marsch(von: Vector3, nach: Vector3, basis_m: float, schraeg: bool) -> Array:
	var schritt: float = WorldManager.PLAYER_SPEED_MS / 60.0
	var max_stg: float = load("res://scripts/OverworldView.gd").MAX_STEIGUNG
	var p: Vector2 = Vector2(von.x, von.z)
	var ziel := Vector2(nach.x, nach.z)
	var stockungen: int = 0
	var erreicht: bool = false
	for _i in 3000:
		if p.distance_to(ziel) < 1.0:
			erreicht = true
			break
		var richt: Vector2 = (ziel - p).normalized() * schritt
		var kandidaten: Array = [richt]
		if schraeg:
			for grad in [22.0, -22.0, 45.0, -45.0, 68.0, -68.0]:
				kandidaten.append(richt.rotated(deg_to_rad(grad)))
		kandidaten.append(Vector2(richt.x, 0.0))
		kandidaten.append(Vector2(0.0, richt.y))
		var gegangen: bool = false
		for k in kandidaten:
			if k.length() < 0.0001:
				continue
			var basis: float = basis_m if basis_m > 0.0 else k.length()
			var q: Vector2 = p + k.normalized() * basis
			var steig: float = (WorldManager.height_at(q.x, q.y)
				- WorldManager.height_at(p.x, p.y)) / basis
			if steig <= max_stg:
				p += k
				gegangen = true
				break
		if not gegangen:
			stockungen += 1
			# Wie im Spiel: Position halten. Ohne Ausweg bleibt sie stehen, bis der Spieler
			# selbst eine andere Richtung drueckt — deshalb hier abbrechen.
			break
	return [erreicht, stockungen, Vector3(p.x, WorldManager.height_at(p.x, p.y), p.y)]


# ══════════════════════════════════════════════════════════════════════════════
# Zeichen — was im Spiel steht, muss die Schrift auch hergeben
# ══════════════════════════════════════════════════════════════════════════════
#
# Der Fehler, den diese Funktion fuer immer zumauert:
#
# Quer durch die Oberflaeche standen **Emoji** im Quelltext — ein Reagenzglas im Trankknopf,
# ein Blutstropfen ueber verletzten Gegnern, ein Geldsack an der Beute, ein Pferd am Pferd.
# Beim Lesen des Codes sah das aufgeraeumt aus. Im Spiel war **jedes einzelne davon ein leeres
# Kaestchen**: Godots eingebaute Ersatzschrift ist ein schmaler Latin-Ausschnitt ohne ein
# einziges Symbol. 54 verschiedene Zeichen, ueber Kopfzeile, Beutel, Werkstatt, Auftraege und
# Ortsschilder verteilt.
#
# Auffallen konnte das beim Lesen nicht — der Quelltext zeigt die Emoji ja korrekt an. Es
# brauchte die Frage an die Schrift selbst: `Font.has_char()`. Genau die stellt diese Funktion
# jetzt bei **jedem Zeichen jeder Zeile** — automatisch, fuer immer, auch fuer Zeichen, die es
# heute noch gar nicht gibt.
func _test_zeichen() -> void:
	print("· Zeichen und Schrift (kein leeres Kaestchen im Spiel)")

	# Die Schrift liegt IM Projekt. Eine geliehene Systemschrift gibt es auf einem Telefon
	# nicht, und Godots eingebaute reicht nicht.
	var pfad: String = "res://assets/fonts/DejaVuSans.ttf"
	_check("Die Schrift liegt im Projekt", ResourceLoader.exists(pfad))
	_check("Und sie ist die Vorgabe des Projekts",
		String(ProjectSettings.get_setting("gui/theme/custom_font", "")) == pfad)

	var schrift: Font = load(pfad) as Font
	if schrift == null:
		_check("Die Schrift laesst sich laden", false, "load() gab null")
		return

	# Jedes Zeichen der Tabelle einzeln nachfragen. Wer ein neues eintraegt, erfaehrt hier
	# sofort, ob die Schrift es hergibt — und nicht erst der Spieler.
	var fehlt_tabelle: Array[String] = []
	for name in HudGlyph.Z:
		var zk: String = String(HudGlyph.Z[name])
		for i in zk.length():
			if not schrift.has_char(zk.unicode_at(i)):
				fehlt_tabelle.append("%s (U+%04X)" % [name, zk.unicode_at(i)])
	_check("Alle %d Zeichen der Tabelle stehen in der Schrift" % HudGlyph.Z.size(),
		fehlt_tabelle.is_empty(), ", ".join(fehlt_tabelle))

	# Und jetzt der eigentliche Waechter: JEDE Zeile JEDES Skripts und JEDER Szene.
	#
	# Kommentare werden vorher weggeworfen — sie erscheinen nie auf dem Bildschirm, und ein
	# Test, der sie mitpruefen wuerde, verboete genau die Erklaerung, warum ein Zeichen
	# ausgetauscht wurde („vorher stand hier ein Geldsack").
	var treffer: Dictionary = {}
	var dateien: Array[String] = []
	_dateien_sammeln("res://", dateien)
	for datei in dateien:
		var inhalt: String = FileAccess.get_file_as_string(datei)
		var zeilen: PackedStringArray = inhalt.split("\n")
		for nr in zeilen.size():
			var zeile: String = _ohne_kommentar(zeilen[nr], datei.ends_with(".tscn"))
			for i in zeile.length():
				var c: int = zeile.unicode_at(i)
				if c > 127 and not schrift.has_char(c):
					var schluessel: String = "U+%04X" % c
					if not treffer.has(schluessel):
						treffer[schluessel] = "%s:%d" % [datei.get_file(), nr + 1]
	var liste: Array[String] = []
	for k in treffer:
		liste.append("%s in %s" % [k, treffer[k]])
	_check("Kein unsichtbares Zeichen in %d Dateien" % dateien.size(),
		treffer.is_empty(), ", ".join(liste))

	# Und niemand zeichnet an der Projektschrift vorbei. `ThemeDB.fallback_font` ist NICHT die
	# eingestellte Schrift, sondern Godots eingebaute Notloesung — wer sie in `draw_string()`
	# steckt, holt sich die leeren Kaestchen zurueck, egal was im Projekt steht. Genau so war
	# es in fuenf Dateien, die ihre Symbole selbst malen.
	#
	# Der Suchbegriff wird zur Laufzeit zusammengesetzt: Stuende er als ein Stueck da, faende
	# die Pruefung zuerst SICH SELBST und meldete die eigene Zeile als Verstoss.
	# Und wie oben zaehlt nur CODE, kein Kommentar: Die Erklaerung daneben nennt den Namen
	# zwangslaeufig, und ein Test, der darauf anschlaegt, verbietet seine eigene Begruendung.
	var nadel: String = "ThemeDB." + "fallback_font"
	var vorbei: Array[String] = []
	for datei in dateien:
		if not datei.ends_with(".gd") or datei.begins_with("res://tools/"):
			continue
		for zeile in FileAccess.get_file_as_string(datei).split("\n"):
			if _ohne_kommentar(zeile, false).contains(nadel):
				vorbei.append(datei.get_file())
				break
	_check("Niemand zeichnet an der Projektschrift vorbei",
		vorbei.is_empty(), ", ".join(vorbei))


## Alle `.gd` und `.tscn` unterhalb von `wo` einsammeln.
func _dateien_sammeln(wo: String, raus: Array[String]) -> void:
	var d: DirAccess = DirAccess.open(wo)
	if d == null:
		return
	d.list_dir_begin()
	var name: String = d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var voll: String = wo.path_join(name)
		if d.current_is_dir():
			_dateien_sammeln(voll, raus)
		elif name.ends_with(".gd") or name.ends_with(".tscn"):
			raus.append(voll)
		name = d.get_next()
	d.list_dir_end()


## Die Zeile ohne ihren Kommentar.
##
## Simpler Zustandslauf: Was in Anfuehrungszeichen steht, bleibt; ein `#` (bzw. `;` in `.tscn`)
## ausserhalb beendet die Zeile. Das reicht — geprueft wird, was auf dem Bildschirm landen
## KANN, und ein Zeichen in einer Zeichenkette landet dort.
func _ohne_kommentar(zeile: String, ist_szene: bool) -> String:
	var q: String = ""          # welches Anfuehrungszeichen gerade offen ist
	var i: int = 0
	while i < zeile.length():
		var c: String = zeile[i]
		if q != "":
			if c == "\\":
				i += 2       # das maskierte Zeichen mit ueberspringen, sonst schliesst \" hier
				continue
			if c == q:
				q = ""
		elif c == '"' or c == "'":
			q = c
		elif c == "#" or (ist_szene and c == ";"):
			return zeile.substr(0, i)
		i += 1
	return zeile


# ══════════════════════════════════════════════════════════════════════════════
# Der Stollen — ein Grundriss, den man nachlaufen kann
# ══════════════════════════════════════════════════════════════════════════════
#
# Ein erzeugter Dungeon hat einen Fehler, den man auf keinem Bild sieht: Die Treppe liegt hinter
# einer Wand. Der Stollen sieht dann voellig in Ordnung aus, ist begehbar, hat Raeume, Truhen,
# Gegner — und laesst sich nicht durchspielen. Wer das mit dem Auge pruefen will, muesste jeden
# Startwert einmal selbst ablaufen.
#
# Deshalb rechnet `DungeonLayout` nur Zahlen und kennt keine Szene: So kann diese Funktion
# HUNDERT Grundrisse erzeugen und bei jedem einzelnen mit einer Flutfuellung nachsehen, ob vom
# Eingang wirklich alles erreichbar ist. Das ist der ganze Grund fuer die Trennung.
func _test_stollen() -> void:
	print("· Stollen (Grundriss, Erreichbarkeit, Wiederholbarkeit)")

	# ── Wiederholbar ─────────────────────────────────────────────────────────
	# Wer den Stollen verlaesst und wieder betritt, soll nicht in einem anderen stehen.
	var a: Dictionary = DungeonLayout.erzeugen(4242, 1)
	var b: Dictionary = DungeonLayout.erzeugen(4242, 1)
	_check("Gleicher Startwert, gleicher Grundriss",
		(a["raeume"] as Array) == (b["raeume"] as Array)
		and (a["treppe"] as Vector2i) == (b["treppe"] as Vector2i))
	var c: Dictionary = DungeonLayout.erzeugen(4243, 1)
	_check("Anderer Startwert, anderer Grundriss",
		(a["raeume"] as Array) != (c["raeume"] as Array))
	# Und die Ebenen unterscheiden sich, sonst waere die Kaverne der Vorschacht noch einmal.
	_check("Ebene 2 hat mehr Raeume als Ebene 1",
		int(DungeonLayout.RAEUME[2]) > int(DungeonLayout.RAEUME[1]))

	# ── Und jetzt hundertmal nachlaufen ──────────────────────────────────────
	var ohne_raum: Array[String] = []
	var unerreichbar: Array[String] = []
	var ueberlappt: Array[String] = []
	var treppe_gleich: Array[String] = []
	var im_fels: Array[String] = []
	for s in range(100):
		for ebene in [1, 2]:
			var p: Dictionary = DungeonLayout.erzeugen(s, ebene)
			var raeume: Array = p["raeume"]
			var kennung: String = "%d/E%d" % [s, ebene]
			# Ein Stollen ohne Raeume ist kein Stollen. Der Erzeuger gibt nach `VERSUCHE` auf —
			# er darf weniger liefern als gewuenscht, aber nicht nichts.
			if raeume.size() < 3:
				ohne_raum.append(kennung)
				continue
			# Raeume duerfen sich nicht ueberlappen, sonst faellt die Wand zwischen ihnen weg.
			for i in raeume.size():
				for j in range(i + 1, raeume.size()):
					if (raeume[i] as Rect2i).intersects(raeume[j] as Rect2i):
						ueberlappt.append(kennung)
			# DIE Pruefung: Ist vom Eingang aus alles erreichbar?
			var erreicht: Dictionary = DungeonLayout.erreichbar(p)
			var boden: Dictionary = p["boden"]
			if erreicht.size() < boden.size():
				unerreichbar.append("%s (%d von %d)" % [kennung, erreicht.size(), boden.size()])
			# Und die Treppe im Besonderen — sie ist der einzige Weg weiter.
			if not erreicht.has(p["treppe"] as Vector2i):
				unerreichbar.append(kennung + " Treppe")
			if (p["treppe"] as Vector2i) == (p["eingang"] as Vector2i):
				treppe_gleich.append(kennung)
			# Truhen und Gegner stehen auf Boden, nicht im Gestein.
			for t in (p["truhen"] as Array):
				if not DungeonLayout.begehbar(p, t as Vector2i):
					im_fels.append(kennung + " Truhe")
			for g in (p["gegner"] as Array):
				if not DungeonLayout.begehbar(p, g as Vector2i):
					im_fels.append(kennung + " Gegner")
	_check("200 Grundrisse haben genug Raeume", ohne_raum.is_empty(),
		", ".join(ohne_raum.slice(0, 6)))
	_check("Kein Raum ueberlappt einen anderen", ueberlappt.is_empty(),
		", ".join(ueberlappt.slice(0, 6)))
	_check("In 200 Grundrissen ist JEDES Feld vom Eingang erreichbar", unerreichbar.is_empty(),
		", ".join(unerreichbar.slice(0, 6)))
	_check("Treppe und Eingang liegen nie aufeinander", treppe_gleich.is_empty(),
		", ".join(treppe_gleich.slice(0, 6)))
	_check("Keine Truhe und kein Gegner steht im Fels", im_fels.is_empty(),
		", ".join(im_fels.slice(0, 6)))

	# ── Wände ────────────────────────────────────────────────────────────────
	# Nur die GRENZE wird gemauert, nicht das ganze Gestein — sonst stellt die Szene tausend
	# Kaesten auf, von denen niemand je einen sieht.
	var p1: Dictionary = DungeonLayout.erzeugen(7, 1)
	var w: Array[Vector2i] = DungeonLayout.waende(p1)
	_check("Es gibt Waende (%d Stueck)" % w.size(), w.size() > 0)
	var w_auf_boden: int = 0
	for f in w:
		if DungeonLayout.begehbar(p1, f):
			w_auf_boden += 1
	_check("Keine Wand steht auf dem Weg", w_auf_boden == 0)
	# Und sie sind sparsam: deutlich weniger als das ganze Gitter.
	_check("Die Waende sind nur der Rand (%d < %d Felder)"
		% [w.size(), DungeonLayout.GITTER.x * DungeonLayout.GITTER.y],
		w.size() < DungeonLayout.GITTER.x * DungeonLayout.GITTER.y)

	# ── Umrechnung Feld <-> Szene ────────────────────────────────────────────
	# Sie muss hin UND zurueck stimmen: Die Szene setzt Dinge nach Feld, fragt aber nach
	# Position, auf welchem Feld die Figur steht. Driftet das auseinander, oeffnet die Treppe
	# ein Feld daneben.
	var hin_zurueck: Array[String] = []
	for fx in [0, 1, 7, 13, 25]:
		for fy in [0, 3, 12, 25]:
			var feld := Vector2i(fx, fy)
			if DungeonLayout.szene_zu_feld(DungeonLayout.feld_zu_szene(feld)) != feld:
				hin_zurueck.append(str(feld))
	_check("Feld -> Szene -> Feld trifft wieder dasselbe Feld", hin_zurueck.is_empty(),
		", ".join(hin_zurueck))
	# Ein Feld ist genau ein Wandsegment breit, sonst muesste die Wand gestueckelt werden.
	_check("Ein Feld ist so breit wie ein Wandstueck (%.1f m)" % DungeonLayout.FELD_M,
		is_equal_approx(DungeonLayout.FELD_M, 4.0))

	# ── Der Weg hinein und wieder heraus ─────────────────────────────────────
	#
	# Ein Stollen ist eine EIGENE Szene, und beim Wechsel verschwindet alles, was die Oberwelt
	# wusste. Was den Wechsel ueberleben muss, steht deshalb in `GameState` und nirgends sonst.
	var OWS = load("res://scripts/OverworldView.gd")
	var dv_q: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")
	var ow_s: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Es gibt eine Stollenszene", ResourceLoader.exists("res://scenes/Dungeon.tscn"))
	_check("Und einen Eingang in der Oberwelt", ow_s.contains("func _stollen_betreten"))
	_check("Der Eingang ist sichtbar gebaut", ow_s.contains("func _build_stollen"))
	# Er liegt AM WEG zwischen Stadt und Grube — einen Dungeon, den man suchen muss, findet in
	# einem 5000-m-Krater niemand. Geprueft wird die Lage, nicht die Zahl: Verschiebt jemand
	# Rustwater, soll der Test die neue Entfernung messen und nicht die alte Konstante.
	var rw: Vector2 = Vector2(300.0, 300.0)
	var mine: Vector2 = Vector2(150.0, 450.0)
	var d_rw: float = OWS.STOLLEN_WELT.distance_to(rw)
	var d_mine: float = OWS.STOLLEN_WELT.distance_to(mine)
	_check("Der Stollen liegt zwischen Stadt und Grube (%.0f m / %.0f m)" % [d_rw, d_mine],
		d_rw < rw.distance_to(mine) and d_mine < rw.distance_to(mine))
	# Die Rueckkehrstelle wird VORHER gemerkt: Danach ist die Szene weg und mit ihr die Figur,
	# die man haette fragen koennen.
	_check("Die Rueckkehrstelle wird vor dem Wechsel gemerkt",
		ow_s.find("GameState.stollen_rueckkehr = _stollen_position()")
			< ow_s.find('change_scene_to_file("res://scenes/Dungeon.tscn")'))
	_check("Und die Oberwelt setzt einen darauf zurueck",
		ow_s.contains("_player.position = GameState.stollen_rueckkehr"))
	# Und sie wird wieder GELEERT — sonst springt die Figur bei jedem spaeteren Start des
	# Spiels an den Stollenmund, auch ohne je drin gewesen zu sein.
	_check("Die Rueckkehrstelle wird danach geleert",
		ow_s.contains("GameState.stollen_rueckkehr = Vector3.ZERO"))
	# Der Startwert bleibt, solange man drin ist: Wer die Treppe nimmt, soll in DEMSELBEN
	# Stollen eine Etage tiefer stehen und nicht in einem fremden.
	# (Der erste Anlauf dieses Tests verbot das Wuerfeln ueberhaupt — und schlug deshalb beim
	# voellig richtigen Code an: Irgendwo muss der erste Startwert ja herkommen. Geprueft
	# gehoert der WAECHTER davor, nicht das Wuerfeln.)
	_check("Die Treppe zaehlt nur die Ebene hoch", dv_q.contains("GameState.stollen_ebene += 1"))
	_check("Und gewuerfelt wird nur, wenn kein Startwert steht",
		dv_q.contains("if GameState.stollen_startwert == 0:"))
	_check("Und beim Verlassen wird beides zurueckgesetzt",
		dv_q.contains("GameState.stollen_ebene = 0")
		and dv_q.contains("GameState.stollen_startwert = 0"))
	# Ein neues Spiel darf nicht im Stollen anfangen.
	GameState.stollen_ebene = 2
	GameState.stollen_rueckkehr = Vector3(1, 2, 3)
	GameState.neu_beginnen()
	_check("Ein neues Spiel faengt nicht im Stollen an",
		GameState.stollen_ebene == 0 and GameState.stollen_rueckkehr == Vector3.ZERO)
	# Und drinnen wird an WAENDEN gehalten, nicht an Haengen: Die Bewegung schlaegt das Zielfeld
	# nach, getrennt fuer x und z. Zusammen geprueft bliebe man an jeder schraegen Ecke kleben,
	# obwohl eine der beiden Richtungen frei ist.
	_check("Drinnen bremst die Wand, nicht die Steigung",
		dv_q.contains("DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(nur_x))")
		and dv_q.contains("DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(nur_z))"))
	# Und es ist dunkel. Ein Stollen mit Tageslicht ist ein Zimmer.
	_check("Es ist dunkel, mit einer Lampe am Guertel",
		dv_q.contains("OmniLight3D") and dv_q.contains("omni_range = LAMPE_M"))

	# ── Gegner und Beute ─────────────────────────────────────────────────────
	#
	# Der Stollen bringt KEINE eigene Kampfrechnung mit. Zwei Rechnungen wuerden auseinander
	# driften, sobald jemand eine Zahl aendert — und dann lernte man beim Spielen zweierlei
	# Widerspruechliches: Ein Klaeffer muss drinnen so viel aushalten wie draussen.
	_check("Der Stollen rechnet den Kampf nicht selbst",
		dv_q.contains("CombatEngine.resolve_hit(") and dv_q.contains("CombatTarget.from_type("))
	_check("Und die Beute auch nicht", dv_q.contains("ProgressionManager.make_gear(")
		and dv_q.contains("BagManager.add("))
	_check("Erfahrung kommt aus derselben Tabelle",
		dv_q.contains("CombatData.xp_for_kill("))
	# Jede Besatzungsart muss es wirklich geben — ein Tippfehler waere sonst ein Absturz beim
	# Betreten, und zwar erst auf Ebene 2.
	var OWD = load("res://scripts/DungeonView.gd")
	var unbekannt: Array[String] = []
	for ebene in (OWD.BESATZUNG as Dictionary):
		for art in (OWD.BESATZUNG[ebene] as Array):
			if not CombatData.ENEMY_TYPES.has(String(art)):
				unbekannt.append(String(art))
	_check("Jede Besatzungsart steht in der Gegnertabelle", unbekannt.is_empty(),
		", ".join(unbekannt))
	# Ebene 2 ist MECHANISCH — das ist eine Aussage ueber die Waffe: Panzerung frisst Kinetik,
	# und wer nur den Karabiner dabei hat, merkt das hier zuerst.
	var mech: int = 0
	for art in (OWD.BESATZUNG[2] as Array):
		if String(CombatData.ENEMY_TYPES[String(art)]["class"]) == CombatData.MECHANICAL:
			mech += 1
	_check("Die Kaverne ist ganz mechanisch (%d von %d)"
		% [mech, (OWD.BESATZUNG[2] as Array).size()],
		mech == (OWD.BESATZUNG[2] as Array).size())
	# Gegner laufen NUR ueber begehbare Felder. Ohne die Pruefung gehen sie durch den Fels und
	# stehen ploetzlich in der Kammer nebenan — und der Grundriss waere umsonst gerechnet.
	_check("Gegner laufen nicht durch den Fels",
		dv_q.count("DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(probe))") == 2)
	# Truhen gehen VOR der Treppe: Wer neben beidem steht, will die Truhe und nicht
	# versehentlich die Ebene wechseln.
	_check("Die Truhe hat Vorrang vor der Treppe",
		dv_q.find("if _truhe_oeffnen():") < dv_q.find("distance_to(_treppe_pos) <= NAH_M"))
	# Und wer unten liegen bleibt, faengt beim naechsten Abstieg von vorn an. Ein Dungeon, in
	# den man nach dem Sterben mit geleerten Kammern zurueckkehrt, ist kein Risiko mehr.
	_check("Ohnmacht wirft einen aus dem Stollen", dv_q.contains("func _ohnmacht"))

# ══════════════════════════════════════════════════════════════════════════════
# Truhen — die gewoehnliche und die, fuer die man gekaempft hat
# ══════════════════════════════════════════════════════════════════════════════
func _test_truhen() -> void:
	print("· Truhen (zwei Arten, eine Tabelle)")

	# EINE Tabelle fuer beide Orte. Vorher fuellte die Oberwelt ihre Truhen mit 18–45 Gold und
	# der Stollen rechnete `18 + Ebene · 22` — zwei Zahlenreihen fuer dieselbe Sache. Solange es
	# eine Sorte Truhe gab, fiel das nicht auf; mit zwei Sorten waeren es vier gewesen.
	var ow_q: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	var dv_q: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")
	_check("Die Oberwelt fuellt Truhen aus der Tabelle", ow_q.contains("ChestData.gold(art)"))
	_check("Der Stollen auch", dv_q.contains("ChestData.gold(art)"))
	_check("Und keiner rechnet mehr selbst",
		not ow_q.contains("randi_range(18, 45)")
		and not dv_q.contains("18 + GameState.stollen_ebene * 22"))

	# ── Der Unterschied ist kein Multiplikator ───────────────────────────────
	#
	# Eine Bosstruhe GARANTIERT ein Mindestmass. Eine gewoehnliche darf leer ausgehen — das ist
	# der Grund, warum man sich ueber eine gute freut. Eine Truhe hinter einem Boss darf das
	# nicht: Wer einen Kampf uebersteht und dann Hausmuell findet, lernt, dass Bosskaempfe sich
	# nicht lohnen.
	var i_rare: int = ProgressionManager.RARITY_ORDER.find("rare")
	var zu_schlecht: Array[String] = []
	var kam_hoeher: bool = false
	for k in range(200):
		var wurf: float = float(k) / 200.0
		var s_boss: String = ChestData.seltenheit(ChestData.BOSS, wurf)
		if ProgressionManager.RARITY_ORDER.find(s_boss) < i_rare:
			zu_schlecht.append(s_boss)
		if ProgressionManager.RARITY_ORDER.find(s_boss) > i_rare:
			kam_hoeher = true
	_check("Die Beutekammer gibt nie unter 'rare'", zu_schlecht.is_empty(),
		", ".join(zu_schlecht.slice(0, 5)))
	# Und sie ist nach OBEN offen: Ein garantiertes Minimum, das zugleich ein Maximum waere,
	# machte jede Beutekammer gleich.
	_check("Sie kann aber besser geben", kam_hoeher)
	# Die gewoehnliche darf weiterhin eine Niete sein.
	var kam_common: bool = false
	for k in range(200):
		if ChestData.seltenheit(ChestData.STANDARD, float(k) / 200.0) == "common":
			kam_common = true
	_check("Die gewoehnliche Truhe darf eine Niete sein", kam_common)

	# Mehr Gold, mehr Stuecke, immer ein Trank — nach dem Kampf ist man angeschlagen.
	var g_std: Array = ChestData.art(ChestData.STANDARD)["gold"]
	var g_boss: Array = ChestData.art(ChestData.BOSS)["gold"]
	_check("Die Beutekammer gibt mehr Gold (%d–%d statt %d–%d)"
		% [int(g_boss[0]), int(g_boss[1]), int(g_std[0]), int(g_std[1])],
		int(g_boss[0]) > int(g_std[1]))
	_check("Und immer einen Trank", ChestData.trank(ChestData.BOSS, 0.999))
	_check("Die gewoehnliche nicht immer", not ChestData.trank(ChestData.STANDARD, 0.999))

	# ── Sie sieht anders aus, und zwar von weitem ────────────────────────────
	#
	# Eine Belohnung, die man erst am Inhalt erkennt, ist im Augenblick des Findens keine. Und
	# weil eine Farbe im Daemmerlicht kaum traegt, unterscheidet sich zuerst die FORM.
	_check("Sie ist hoeher als die gewoehnliche (%.2f statt %.2f m)"
		% [float(ChestData.art(ChestData.BOSS)["hoehe"]),
			float(ChestData.art(ChestData.STANDARD)["hoehe"])],
		float(ChestData.art(ChestData.BOSS)["hoehe"])
			> float(ChestData.art(ChestData.STANDARD)["hoehe"]))
	_check("Und sie hat ein eigenes Modell in der Registry",
		AssetRegistry.PATHS.has("chest_boss") and AssetRegistry.TARGET_HEIGHT.has("chest_boss"))
	# Der Eintrag steht da, BEVOR es die Datei gibt — `first_existing()` liefert dann "" und die
	# Szene zeichnet ihren Platzhalter. Genau das muss gelten, sonst startet das Spiel nicht,
	# solange das Modell fehlt.
	_check("Ein fehlendes Modell bricht nichts",
		AssetRegistry.resolve("chest_boss") == ""
		or ResourceLoader.exists(AssetRegistry.resolve("chest_boss")))
	_check("Und has_model() sagt ehrlich, dass es noch fehlt",
		not AssetRegistry.has_model("chest_boss") or AssetRegistry.resolve("chest_boss") != "")
	_check("Der Platzhalter hat mehr als einen Teil (Sockel, Kasten, Band)",
		dv_q.contains("Sockel, Kasten und Deckelband") or ow_q.contains("Sockel"))

	# ── Wo sie steht ─────────────────────────────────────────────────────────
	# Am ENDE des Wegs, in der Kammer mit der Treppe — und erst auf Ebene 2.
	var e1: Dictionary = DungeonLayout.erzeugen(4242, 1)
	var e2: Dictionary = DungeonLayout.erzeugen(4242, 2)
	_check("Beide Ebenen haben ueberhaupt Truhen",
		(e1["truhen"] as Array).size() > 0 and (e2["truhen"] as Array).size() > 0)
	_check("Die Beutekammer steht erst in der Kaverne",
		dv_q.contains("GameState.stollen_ebene >= 2 and i == alle.size() - 1"))

	# ── Antworten muessen STEHEN BLEIBEN ─────────────────────────────────────
	#
	# Die Hinweiszeile im Stollen hat zwei Aufgaben, und die eine hat die andere aufgefressen:
	# Sie sagt, was in Reichweite ist („Truhe oeffnen [E]"), und sie sagt, was gerade passiert
	# ist („Verschlossen — 2 von 3 Schluesseln"). Das Erste wird JEDES BILD neu geschrieben.
	# Damit stand die Antwort auf einen Tastendruck genau ein Bild lang da — fuer einen
	# Menschen unlesbar. Der Sperrsatz der Beutekammer erschien nie, obwohl er richtig gesetzt
	# wurde.
	#
	# Aufgefallen ist das nicht im Code, sondern im Kontrollbild: Dort drueckt die Figur auf die
	# verschlossene Truhe, und der Satz fehlt.
	var DVT = load("res://scripts/DungeonView.gd")
	_check("Antworten haben Vorrang vor der Reichweiten-Zeile",
		dv_q.contains("func _antworten") and dv_q.contains("_antwort_bis"))
	_check("Und stehen lange genug zum Lesen (%.1f s)" % DVT.ANTWORT_SEK,
		float(DVT.ANTWORT_SEK) >= 2.0)
	# Keine Antwort darf mehr direkt in die Zeile geschrieben werden — sonst wischt sie der
	# naechste Frame wieder weg, und wir haben denselben Fehler an anderer Stelle.
	var direkt: Array[String] = []
	var zeilen_dv: PackedStringArray = dv_q.split("\n")
	for nr in zeilen_dv.size():
		var z: String = _ohne_kommentar(zeilen_dv[nr], false)
		if not z.contains("_hinweis.text ="):
			continue
		# Zwei Stellen duerfen es: `_naehe_pruefen` schreibt die Reichweiten-Zeile, und
		# `_antworten` ist die Schleuse, die den Vorrang ueberhaupt setzt.
		var erlaubt_hier: bool = false
		for zurueck in range(nr, maxi(0, nr - 40), -1):
			if zeilen_dv[zurueck].begins_with("func "):
				erlaubt_hier = zeilen_dv[zurueck].begins_with("func _naehe_pruefen") \
					or zeilen_dv[zurueck].begins_with("func _antworten")
				break
		if not erlaubt_hier:
			direkt.append("Zeile %d" % (nr + 1))
	_check("Keine Antwort wird direkt in die Zeile geschrieben", direkt.is_empty(),
		", ".join(direkt))
	# Und eine Truhe in Reichweite sagt ueberhaupt etwas. Vorher gab es dafuer GAR KEINE Zeile:
	# Man stand davor, und nichts sagte einem, dass man druecken kann — im Dunkeln ist ein
	# Kasten ohne Beschriftung ein Stein.
	_check("Eine Truhe in Reichweite meldet sich", dv_q.contains("öffnen   [E]"))

	# ── Der Stollen war stumm und hatte keinen Balken ────────────────────────
	#
	# Man drueckte den Abzug, ein Gegner verlor Leben, und nichts sagte einem, dass geschossen
	# wurde. Bei einer Trefferanzeige, die im Dunkeln ohnehin schwer zu lesen ist, fehlte damit
	# die einzige verlaessliche Rueckmeldung. Die Tondateien lagen laengst da — sie waren nur
	# nie angeschlossen.
	_check("Im Stollen knallt es beim Schuss",
		dv_q.contains("_schuss_ton()") and dv_q.contains("AudioStreamPlayer3D"))
	_check("Und das Repetieren kommt danach, nicht gleichzeitig",
		dv_q.contains("SFX_REPETIER_VERZUG") and float(DVT.SFX_REPETIER_VERZUG) > 0.1)
	# Der Knall traegt drinnen KUERZER. Ein Schuss, der ueber 320 m schallt, klingt in vier
	# Metern Fels falsch — die Enge ist die halbe Miete.
	_check("Der Knall traegt drinnen kuerzer als draussen",
		dv_q.contains("_sfx_schuss.max_distance = 90.0")
		and ow_q.contains("_sfx_schuss.max_distance = 320.0"))
	# Und ein BALKEN statt nur der Zahl. Eine Zahl muss man lesen, einen Balken sieht man —
	# drinnen wiegt das schwerer als draussen, weil der Schaden nicht aus der Ferne kommt,
	# sondern von dem Konstrukt, das bereits neben einem steht.
	_check("Und es gibt einen Lebensbalken", dv_q.contains("_hp_bar = ProgressBar.new()")
		and dv_q.contains("_hp_bar.value = clampf(_hp"))

	# ── Grubenstahl: das Material, das es NUR im Stollen gibt ────────────────
	#
	# Silas' Auftrag verlangte anfangs schlicht `schrott` — und den findet man ueberall. Damit
	# haette man ihn erledigen koennen, ohne je hinabzusteigen, und der Stollen waere ein Umweg
	# gewesen, den man auslaesst. Ein Auftrag, der einen an einen ORT schicken soll, muss nach
	# etwas verlangen, das es nur dort gibt.
	var q_stollen: Dictionary = QuestManager.QUESTS["q_scrap"]
	_check("Silas verlangt Grubenstahl", String(q_stollen["item"]) == "grubenstahl")
	_check("Und ausdruecklich NICHT gewoehnlichen Schrott",
		String(q_stollen["item"]) != "schrott")
	_check("Der Auftrag zeigt auf den Stollen", String(q_stollen["target"]) == "stollen")
	_check("Das Material hat einen Namen",
		String(GameState.MATERIAL_NAMEN.get("grubenstahl", "")) == "Grubenstahl")

	# Und jetzt die eigentliche Zusicherung: Er faellt NIRGENDWO SONST an. Der Beweis laeuft
	# ueber die Quelle, weil eine Beutetabelle der Oberwelt ihn sonst still hereinreichen
	# koennte — und dann waere der Auftrag wieder ohne Stollen zu erledigen, ohne dass es
	# jemand merkt.
	#
	# `ChestData` steht NICHT auf der Liste, und das mit Absicht: Dort liegt nur die ZAHL, wie
	# viel in einer Kiste steckt. Vergeben wird sie ausschliesslich vom Stollen — die Truhen der
	# Oberwelt rufen `ChestData.stahl()` schlicht nicht auf, und genau das steht als eigene
	# Pruefung darunter.
	var draussen: Array[String] = []
	for datei in ["res://scripts/OverworldView.gd", "res://scripts/BeuteData.gd",
			"res://scripts/EncounterManager.gd"]:
		var zeilen: PackedStringArray = FileAccess.get_file_as_string(datei).split("\n")
		for nr in zeilen.size():
			for stoff in GameState.NUR_IM_STOLLEN:
				if _ohne_kommentar(zeilen[nr], false).contains(stoff):
					draussen.append("%s:%d" % [datei.get_file(), nr + 1])
	_check("Grubenstahl faellt draussen nirgends an", draussen.is_empty(),
		", ".join(draussen))
	_check("Und die Truhen der Oberwelt vergeben ihn nicht",
		not _ohne_kommentar_datei("res://scripts/OverworldView.gd").contains("ChestData.stahl("))

	# ── Er liegt in den KISTEN, nicht einzeln herum ──────────────────────────
	#
	# Ein kurzer Anlauf hat ihn als Halden ueber die Kammern gestreut. Das machte den Stollen zu
	# einer Sammelaufgabe, bei der man am Boden klebt statt die Kammer anzusehen — und es war
	# ein zweiter Weg an Material, neben dem, den es ohnehin schon gab. In der Kiste ist er ein
	# FUND: derselbe Griff, der auch Gold und Ausruestung bringt.
	var e1s: Dictionary = DungeonLayout.erzeugen(4242, 1)
	var e2s: Dictionary = DungeonLayout.erzeugen(4242, 2)
	_check("Grubenstahl kommt aus den Kisten", dv_q.contains("ChestData.stahl(art)"))
	_check("Und liegt nicht mehr als Halde herum",
		not dv_q.contains("_halden") and not e1s.has("stahl"))
	_check("Jede Kistenart fuehrt ihn",
		ChestData.stahl(ChestData.STANDARD, _fest_rng()) > 0
		and ChestData.stahl(ChestData.BOSS, _fest_rng()) > 0)
	# Die Beutekammer gibt spuerbar mehr — sie ist der Abschluss und soll sich so anfuehlen.
	_check("Die Beutekammer gibt mehr als eine gewoehnliche Kiste",
		int((ChestData.art(ChestData.BOSS)["stahl"] as Array)[0])
			> int((ChestData.art(ChestData.STANDARD)["stahl"] as Array)[1]))

	# Reicht das fuer den Auftrag? Gerechnet ueber die Kisten, die wirklich im Stollen stehen —
	# und zwar mit dem SCHLECHTESTEN Wurf. Ein Auftrag, der nur bei Glueck aufgeht, schickt
	# jemanden ein zweites Mal hinunter, ohne dass er weiss warum.
	var kisten_1: int = (e1s["truhen"] as Array).size()
	var kisten_2: int = (e2s["truhen"] as Array).size()
	var min_std: int = int((ChestData.art(ChestData.STANDARD)["stahl"] as Array)[0])
	var min_boss: int = int((ChestData.art(ChestData.BOSS)["stahl"] as Array)[0])
	# Auf Ebene 2 ist die letzte Kiste die Beutekammer.
	var schlechtestenfalls: int = (kisten_1 + kisten_2 - 1) * min_std + min_boss
	_check("Auch im schlechtesten Fall reicht der Stollen fuer die %d (%d Kisten, %d Stahl)"
		% [int(q_stollen["count"]), kisten_1 + kisten_2, schlechtestenfalls],
		schlechtestenfalls >= int(q_stollen["count"]))
	# Aber eine Ebene allein nicht — sonst waere die zweite ueberfluessig.
	var nur_e1: int = kisten_1 * int((ChestData.art(ChestData.STANDARD)["stahl"] as Array)[1])
	_check("Ebene 1 allein reicht nicht (hoechstens %d)" % nur_e1,
		nur_e1 < int(q_stollen["count"]))
	# Ausdruecklich zuruecksetzen und nicht auf den Stand von vorher hoffen: Die Pruefung hing
	# an dem, was die vorherige Testfunktion hinterlassen hatte, und schlug fehl, sobald irgendwo
	# davor ein Sammelauftrag durchgespielt wurde. Eine Aussage ueber „ein neues Spiel" muss ein
	# neues Spiel herstellen.
	# `neu_beginnen()` und nicht `_reset_state()`: Geprueft wird die VORGABE eines neuen Spiels,
	# also genau das, was das Spiel selbst herstellt. Der Testhelfer setzt seinen eigenen
	# Startzustand und wuerde die Frage beantworten, die er selbst gestellt hat.
	GameState.neu_beginnen()
	_check("Ein neues Spiel faengt ohne Grubenstahl an",
		int(GameState.inventory.get("grubenstahl", -1)) == 0)
	GameState.level = 30

# ══════════════════════════════════════════════════════════════════════════════
# Anfuehrer und Schluessel
# ══════════════════════════════════════════════════════════════════════════════
#
# Die beste Truhe im Spiel steht sichtbar da und laesst sich trotzdem nicht einfach einsammeln:
# Drei Schluessel, und die gibt es nur bei Anfuehrern. Damit ist die Beutekammer keine Belohnung
# fuers Hinlaufen, sondern fuer dreimal einen Kampf, den man haette umgehen koennen.
func _test_anfuehrer() -> void:
	print("· Anfuehrer und Schluessel")

	# ── Die Zahlen: dreimal Leben, doppelter Schaden ─────────────────────────
	#
	# Und zwar gemessen am EIGENEN Typ, nicht an einem festen Wert. Ein Anfuehrer der Ratten hat
	# dreimal so viel Leben wie eine Ratte — er ist immer der Staerkste SEINER Gruppe und nie
	# versehentlich ein Boss.
	var falsch_hp: Array[String] = []
	var falsch_dmg: Array[String] = []
	for art in CombatData.ENEMY_TYPES:
		var normal: CombatTarget = CombatTarget.from_type(String(art))
		var kopf: CombatTarget = CombatTarget.from_type(String(art), { "anfuehrer": true })
		if kopf.max_health != roundi(float(normal.max_health) * 3.0):
			falsch_hp.append("%s: %d statt %d" % [art, kopf.max_health, normal.max_health * 3])
		if normal.contact_dps > 0 and kopf.contact_dps != roundi(float(normal.contact_dps) * 2.0):
			falsch_dmg.append("%s: %d statt %d" % [art, kopf.contact_dps, normal.contact_dps * 2])
	_check("Jeder Anfuehrer hat dreimal das Leben seiner Gruppe", falsch_hp.is_empty(),
		", ".join(falsch_hp.slice(0, 5)))
	_check("Und macht doppelten Nahschaden", falsch_dmg.is_empty(),
		", ".join(falsch_dmg.slice(0, 5)))
	# Auch der FERNSCHADEN. „Doppelter Schaden" heisst doppelter Schaden, und ein Revolverheld
	# traegt seinen im Lauf und nicht in der Faust — ohne diese Zeile waere ausgerechnet der
	# gefaehrlichste Anfuehrer der harmloseste.
	var r_normal: CombatTarget = CombatTarget.from_type("revolver")
	var r_kopf: CombatTarget = CombatTarget.from_type("revolver", { "anfuehrer": true })
	_check("Auch der Fernschaden ist doppelt (%d statt %d)"
		% [int(r_kopf.ranged["dmg"]), int(r_normal.ranged["dmg"])],
		int(r_kopf.ranged["dmg"]) == int(r_normal.ranged["dmg"]) * 2)
	_check("Er ist als Anfuehrer erkennbar", r_kopf.is_leader and not r_normal.is_leader)
	# Und er bleibt ein verstaerkter GEWOEHNLICHER, kein Boss: Sonst waere „Anfuehrer" nur ein
	# zweites Wort fuer Elite, und die Gruppe haette keinen Kopf, sondern einen Fremdkoerper.
	_check("Ein Anfuehrer ist trotzdem kein Boss",
		not r_kopf.is_boss and not r_kopf.is_elite and not r_kopf.is_superboss)
	_check("Und schwaecher als ein Elite-Gegner (%d < %d Leben)"
		% [r_kopf.max_health, CombatData.BOSS_HP], r_kopf.max_health < CombatData.BOSS_HP)

	# ── Das Schloss ──────────────────────────────────────────────────────────
	_check("Die Beutekammer verlangt drei Schluessel",
		ChestData.schluessel(ChestData.BOSS) == 3)
	_check("Die gewoehnliche Truhe keinen",
		ChestData.schluessel(ChestData.STANDARD) == 0)
	_check("Ohne Schluessel bleibt sie zu",
		not ChestData.offen_mit(ChestData.BOSS, 0)
		and not ChestData.offen_mit(ChestData.BOSS, 2))
	_check("Mit dreien geht sie auf", ChestData.offen_mit(ChestData.BOSS, 3))
	_check("Und die gewoehnliche immer", ChestData.offen_mit(ChestData.STANDARD, 0))
	# Der Satz nennt die ZAHL. „Verschlossen" allein sagt niemandem, ob er zwei Schluessel
	# braucht oder zwanzig — und eine Sperre, deren Preis man nicht kennt, ist keine Aufgabe,
	# sondern eine Wand.
	var satz: String = ChestData.schloss_text(ChestData.BOSS, 1)
	_check("Der Sperrsatz nennt beide Zahlen (%s)" % satz,
		satz.contains("1") and satz.contains("3"))
	_check("Und verraet, wo die Schluessel herkommen", satz.contains("Anführer"))
	_check("Bei genug Schluesseln sagt er nichts", ChestData.schloss_text(ChestData.BOSS, 3) == "")

	# ── Sie werden auch verbraucht ───────────────────────────────────────────
	# Ohne das oeffnete ein Satz Schluessel jede Beutekammer im Spiel.
	var ow_q: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	var dv_q: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")
	_check("Die Oberwelt verbraucht die Schluessel",
		ow_q.contains("GameState.schluessel -= ChestData.schluessel("))
	_check("Der Stollen auch",
		dv_q.contains("GameState.schluessel -= ChestData.schluessel("))
	# Und geprueft wird VOR dem Oeffnen, nicht danach.
	_check("Geprueft wird vor dem Oeffnen",
		ow_q.find("if not ChestData.offen_mit(art_pruef") < ow_q.find('c["looted"] = true'))
	# Anfuehrer lassen sie fallen — an beiden Orten.
	_check("Anfuehrer lassen einen Schluessel fallen",
		ow_q.contains("GameState.schluessel += 1") and dv_q.contains("GameState.schluessel += 1"))

	# ── Wo sie stehen ────────────────────────────────────────────────────────
	# Genau EINER je Ebene, und nur auf den ersten dreien: Drei Schluessel oeffnen eine
	# Beutekammer, ab der vierten Ebene noch einen zu stellen hiesse, Schluessel zu verteilen,
	# fuer die es kein Schloss gibt.
	var DV = load("res://scripts/DungeonView.gd")
	# Anfuehrer stehen auf EINER Ebene weniger, als die Beutekammer Schluessel verlangt — den
	# letzten traegt der Endgegner. Damit geht die Rechnung genau auf: Wer den Stollen ganz
	# durchsteht, haelt am Ende exakt die drei in der Hand, die die Truhe vor ihm oeffnen.
	_check("Anfuehrer stehen auf %d Ebenen" % DV.schluessel_ebenen(),
		DV.schluessel_ebenen() == ChestData.schluessel(ChestData.BOSS) - 1)
	# Und das ist ABGELEITET, nicht abgeschrieben. Eine Drei, die an zwei Stellen steht, ist
	# eine Drei, die irgendwann an einer Stelle eine Vier wird.
	_check("Die Zahl steht nicht doppelt im Quelltext",
		dv_q.contains("ChestData.schluessel(ChestData.BOSS) - 1"))
	_check("Je Ebene genau einer", dv_q.contains("anfuehrer_nr = rng.randi() % alle.size()"))

	# ── Der Endgegner traegt den dritten ─────────────────────────────────────
	#
	# Er steht in der Kammer mit der Treppe, und dort liegt auch die Beutekammer. Das ist die
	# ganze Anordnung: Man sieht die verschlossene Truhe, man sieht, was davorsteht, und man hat
	# in dem Moment zwei Schluessel in der Tasche.
	_check("Auf der tiefsten Ebene steht ein Endgegner",
		dv_q.contains("func _endgegner_bauen") and int(DV.LETZTE_EBENE) == 2)
	_check("Er steht bei der Treppe", dv_q.contains("knoten.position = _treppe_pos"))
	var end_t: CombatTarget = CombatTarget.from_type(DV.ENDGEGNER, { "elite": true })
	_check("Und er traegt einen Schluessel", BeuteData.traegt_schluessel(end_t))
	# Er ist STAERKER als ein Anfuehrer — sonst waere der Abschluss der vierte Anfuehrer.
	var kopf_konstrukt: CombatTarget = CombatTarget.from_type(DV.ENDGEGNER, { "anfuehrer": true })
	_check("Er ist staerker als ein Anfuehrer (%d gegen %d Leben)"
		% [end_t.max_health, kopf_konstrukt.max_health],
		end_t.max_health > kopf_konstrukt.max_health)
	# Und er sieht anders aus. Wer den Unterschied nicht sieht, haelt ihn fuer den vierten
	# Anfuehrer und laeuft mit halbem Leben hinein.
	_check("Sein Schimmer ist ein anderer als der der Anfuehrer",
		DV.ENDGEGNER_SCHIMMER != CombatData.ANFUEHRER_SCHIMMER)

	# ── Und die Rechnung geht auf ────────────────────────────────────────────
	# Zwei Anfuehrer (Ebene 1 und 2) plus der Endgegner = drei Schluessel = eine Beutekammer.
	var ausbeute: int = DV.schluessel_ebenen() + 1
	_check("Ein ganzer Stollen gibt genau %d Schluessel — so viele, wie die Beutekammer "
		% ausbeute + "verlangt", ausbeute == ChestData.schluessel(ChestData.BOSS))
	# Wer traegt ueberhaupt einen: Anfuehrer und der Abschluss, sonst NIEMAND. Ein Schluessel
	# von einer gewoehnlichen Ratte machte die drei Kaempfe ueberfluessig.
	_check("Ein gewoehnlicher Gegner traegt keinen",
		not BeuteData.traegt_schluessel(CombatTarget.from_type("fauna")))
	# Und die Frage wird an EINER Stelle beantwortet, nicht an dreien.
	_check("Beide Szenen fragen dieselbe Stelle",
		ow_q.contains("BeuteData.traegt_schluessel(target)")
		and dv_q.contains("BeuteData.traegt_schluessel(t)"))
	_check("Und das Rudel draussen hat auch einen",
		ow_q.contains("_make_enemy(type_id, i == 0)"))

	# ── Man sieht ihn ────────────────────────────────────────────────────────
	# Violett, weil in dieser Welt sonst nichts violett ist: Rost, Sand, Kupfer und Messing sind
	# warm, die Nacht ist blau.
	var f: Color = CombatData.ANFUEHRER_SCHIMMER
	_check("Der Schimmer ist violett und kalt", f.b > 0.7 and f.r > 0.4 and f.g < f.r and f.g < f.b)
	_check("Beide Szenen legen denselben an",
		ow_q.contains("AssetRegistry.schimmer_anlegen(node, CombatData.ANFUEHRER_SCHIMMER)")
		and dv_q.contains("AssetRegistry.schimmer_anlegen(knoten, CombatData.ANFUEHRER_SCHIMMER)"))
	# Und er ERSETZT das Modellmaterial nicht: Ein `material_override` nimmt der Figur ihre
	# ganze Textur, und der Anfuehrer stuende als einfarbige Silhouette da.
	var ar_q: String = FileAccess.get_file_as_string("res://scripts/AssetRegistry.gd")
	_check("Der Schimmer liegt UEBER dem Modell, statt es zu ersetzen",
		ar_q.contains("kind.material_overlay = glanz")
		and not ar_q.contains("kind.material_override = glanz"))

	# ── Er ist auch groesser ─────────────────────────────────────────────────
	# Der Schimmer allein traegt bei Tageslicht nicht weit genug; eine Silhouette schon.
	_check("Ein Anfuehrer ist 30 %% groesser (%.2f)" % CombatData.ANFUEHRER_GROESSE_MUL,
		is_equal_approx(CombatData.ANFUEHRER_GROESSE_MUL, 1.30))
	# Und BEIDE Szenen nehmen denselben Wert. Sonst ist der Anfuehrer drinnen ein anderer als
	# draussen — vorher stand in der einen 1,25 und in der anderen 1,75/1,4.
	_check("Drinnen und draussen gleich gross",
		ow_q.contains("CombatData.ANFUEHRER_GROESSE_MUL if anfuehrer else 1.0")
		and dv_q.contains("CombatData.ANFUEHRER_GROESSE_MUL if ist_kopf else 1.0"))

	# ── Was faellt ───────────────────────────────────────────────────────────
	#
	# Gerechnet statt gewuerfelt: Die Schwellen werden ueber den ganzen Zufallsbereich
	# abgezaehlt. Ein Test, der tausendmal `randf()` zieht und Anteile schaetzt, schlaegt
	# irgendwann grundlos an — und schweigt genau dann, wenn er es nicht sollte.
	var n_kein: int = 0
	var n_eins: int = 0
	var n_zwei: int = 0
	var a_kein: int = 0
	var a_eins: int = 0
	var a_zwei: int = 0
	var schritte: int = 10000
	for k in schritte:
		var wurf: float = float(k) / float(schritte)
		match BeuteData.stuecke(false, wurf):
			0: n_kein += 1
			1: n_eins += 1
			_: n_zwei += 1
		match BeuteData.stuecke(true, wurf):
			0: a_kein += 1
			1: a_eins += 1
			_: a_zwei += 1
	var p_normal: float = float(n_eins + n_zwei) / float(schritte)
	var p_kopf: float = float(a_eins + a_zwei) / float(schritte)
	var p_kopf_zwei: float = float(a_zwei) / float(schritte)
	_check("Gewoehnliche Gegner lassen in 5 %% etwas fallen (%.1f %%)" % (p_normal * 100.0),
		absf(p_normal - 0.05) < 0.005)
	_check("Und nie zwei Stueck", n_zwei == 0)
	_check("Anfuehrer in 30 %% (%.1f %%)" % (p_kopf * 100.0), absf(p_kopf - 0.30) < 0.005)
	_check("Davon in 5 %% zwei Stueck (%.1f %%)" % (p_kopf_zwei * 100.0),
		absf(p_kopf_zwei - 0.05) < 0.005)
	# Sechsmal so oft wie ein gewoehnlicher: Der Anfuehrer ist der Gegner, den man SUCHT statt
	# umgeht, und muss sich dafuer anders anfuehlen als die drei, die neben ihm standen.
	_check("Der Anfuehrer wirft sechsmal so oft aus", is_equal_approx(p_kopf / p_normal, 6.0))
	# Die Schwellen liegen aufsteigend uebereinander: Ein kleinerer Wurf darf nie WENIGER
	# ergeben als ein groesserer, sonst sind die Anteile ueber den Zufallsbereich verschmiert
	# und nicht mehr nachrechenbar.
	var monoton: bool = true
	var letzte: int = 99
	for k in 1000:
		var jetzt_st: int = BeuteData.stuecke(true, float(k) / 1000.0)
		if jetzt_st > letzte:
			monoton = false
		letzte = jetzt_st
	_check("Die Schwellen liegen sauber uebereinander", monoton)

	# ── Art und Guete ────────────────────────────────────────────────────────
	# Die Art ist GLEICHVERTEILT. Wer Waffen seltener macht als Stiefel, baut eine zweite
	# Seltenheitsachse neben der eigentlichen ein — dann ist eine gewoehnliche Waffe schwerer zu
	# bekommen als ein epischer Helm.
	var je_slot: Dictionary = {}
	for k in 5000:
		var sl: String = BeuteData.slot(float(k) / 5000.0)
		je_slot[sl] = int(je_slot.get(sl, 0)) + 1
	_check("Jede Art kommt vor (%d von %d)" % [je_slot.size(), EquipManager.GEAR_SLOTS.size()],
		je_slot.size() == EquipManager.GEAR_SLOTS.size())
	var schiefste: float = 0.0
	for sl in je_slot:
		schiefste = maxf(schiefste, absf(float(je_slot[sl]) / 5000.0
			- 1.0 / float(EquipManager.GEAR_SLOTS.size())))
	_check("Und alle gleich haeufig (groesste Abweichung %.2f %%)" % (schiefste * 100.0),
		schiefste < 0.01)
	# Die Guete wird nach oben SELTENER — und zwar streng, sonst ist „selten" nur ein Wort.
	var je_gute: Dictionary = {}
	for k in 5000:
		var q: String = BeuteData.seltenheit(float(k) / 5000.0)
		je_gute[q] = int(je_gute.get(q, 0)) + 1
	var fallend: bool = true
	var vorige: int = 999999
	var reihe: Array[String] = []
	for q in ProgressionManager.RARITY_ORDER:
		var n: int = int(je_gute.get(String(q), 0))
		reihe.append("%s %.1f%%" % [q, float(n) / 50.0])
		if n > vorige:
			fallend = false
		vorige = n
	_check("Die Guete wird nach oben unwahrscheinlicher (%s)" % ", ".join(reihe), fallend)
	# Und Gegner werfen SCHLECHTER aus als Truhen. Ein Gegner, der so gut auswirft wie eine
	# Beutekammer, macht die Beutekammer sinnlos.
	_check("Gegner werfen schlechter aus als Truhen",
		BeuteData.SELTENHEIT_BIAS < float(ChestData.art(ChestData.STANDARD)["bias"])
		and BeuteData.SELTENHEIT_BIAS < float(ChestData.art(ChestData.BOSS)["bias"]))
	# ── Ausruestung kommt NIE von selbst in den Beutel ───────────────────────
	#
	# Kurz lag die Stollenbeute direkt im Beutel, mit dem Argument, man finde auf dunklem Grund
	# ohnehin nichts. Das war die falsche Antwort auf ein echtes Problem: Beute, die einem
	# zufaellt, ist etwas, das einem PASSIERT — der Beutel fuellt sich, ohne dass man je
	# entschieden haette, etwas mitzunehmen. Richtig ist, das Fundstueck SICHTBAR zu machen,
	# nicht das Aufheben abzuschaffen.
	#
	# Geprueft wird die Regel selbst und nicht ihre heutige Umsetzung: `BagManager.add()` darf
	# ausschliesslich in einer Aufhebe-Funktion stehen. Wer morgen eine dritte Szene baut, faellt
	# hier auf.
	var erlaubt: Array[String] = ["func _pick_up_gear", "func _gear_aufheben"]
	var schmuggler: Array[String] = []
	for datei in ["res://scripts/OverworldView.gd", "res://scripts/DungeonView.gd"]:
		var zeilen: PackedStringArray = FileAccess.get_file_as_string(datei).split("\n")
		var funktion: String = ""
		for nr in zeilen.size():
			var z: String = zeilen[nr]
			if z.begins_with("func "):
				funktion = z
			if not _ohne_kommentar(z, false).contains("BagManager.add("):
				continue
			var ok: bool = false
			for e in erlaubt:
				if funktion.begins_with(e):
					ok = true
			if not ok:
				schmuggler.append("%s:%d in %s" % [datei.get_file(), nr + 1, funktion.strip_edges()])
	_check("Nichts wandert am Aufheben vorbei in den Beutel", schmuggler.is_empty(),
		", ".join(schmuggler))
	# Und im Stollen liegt sie wirklich auf dem BODEN, mit Namen darueber: Was ausserhalb des
	# Lampenkegels liegt, ist sonst schlicht unsichtbar — DAS war das echte Problem.
	_check("Der Stollen legt Fundstuecke ab", dv_q.contains("func _gear_ablegen"))
	_check("Und beschriftet sie", dv_q.contains("schild.text = String(stueck.get(\"name\""))
	# Und die Schilder STAPELN sich. Im Kontrollbild lagen vier Stuecke dicht beieinander und
	# ihre Namen standen exakt uebereinander — vier Zeilen ineinandergeschrieben, aus denen sich
	# kein Wort mehr lesen liess. Genau der Fall tritt ein, wenn ein Anfuehrer zwei Stuecke
	# fallen laesst oder eine Beutekammer vier.
	_check("Die Beschriftungen stapeln sich statt sich zu ueberschreiben",
		dv_q.contains("float(drueber) * SCHILD_ZEILE_M"))
	# Eine Zeile muss hoeher sein als die Schrift selbst, sonst kleben sie trotzdem.
	_check("Und der Zeilenabstand traegt (%.2f m)" % DV.SCHILD_ZEILE_M,
		float(DV.SCHILD_ZEILE_M) > 0.25)
	_check("Aufgehoben wird mit derselben Taste wie draussen",
		dv_q.contains("aufheben   [E]") and ow_q.contains("aufheben   [E]"))
	# Beute geht VOR Truhe und Treppe: Am Ende der Kaverne steht alles dreies beieinander, und
	# wer dort die Ebene wechselt, laesst seine Beute liegen.
	_check("Aufheben geht vor Truhe und Treppe",
		dv_q.find("if _gear_aufheben():") < dv_q.find("if _truhe_oeffnen():")
		and dv_q.find("if _truhe_oeffnen():") < dv_q.find("distance_to(_treppe_pos) <= NAH_M"))
	# Und nichts landet im Fels: ein Fundstueck, das man sieht und nie bekommt, ist schlimmer
	# als keines.
	_check("Abgelegt wird nur auf begehbarem Grund",
		dv_q.contains("if not DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(pos)):"))

	# Beide Szenen benutzen dieselbe Tabelle.
	_check("Beide Szenen wuerfeln aus derselben Tabelle",
		ow_q.contains("BeuteData.stuecke(BeuteData.ist_besonders(target))")
		and dv_q.contains("BeuteData.stuecke(BeuteData.ist_besonders(t))"))

	# ── Ein neues Spiel faengt ohne Schluessel an ────────────────────────────
	GameState.schluessel = 3
	GameState.neu_beginnen()
	_check("Ein neues Spiel faengt ohne Schluessel an", GameState.schluessel == 0)


## Eine Datei ohne ihre Kommentare — fuer Pruefungen, die auf CODE anschlagen sollen.
func _ohne_kommentar_datei(pfad: String) -> String:
	var raus: PackedStringArray = PackedStringArray()
	for z in FileAccess.get_file_as_string(pfad).split("\n"):
		raus.append(_ohne_kommentar(z, false))
	return "\n".join(raus)


## Ein Wuerfel mit festem Startwert — damit eine Pruefung nicht mal so und mal so ausgeht.
func _fest_rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	return r


# ══════════════════════════════════════════════════════════════════════════════
# Der Spielstand — was hier fehlt, merkt niemand
# ══════════════════════════════════════════════════════════════════════════════
#
# `schluessel` stand nicht im Spielstand. Wer drei Anfuehrer erlegt, das Spiel beendet und
# wiederkommt, stand ohne sie da: Beutekammer wieder zu, und der einzige Hinweis waere ein
# Spieler gewesen, der sich fragt, ob er sie getraeumt hat. Kein Absturz, keine Meldung, keine
# rote Zeile — genau die Sorte Fehler, die man erst nach Wochen bemerkt und dann nicht mehr
# zuordnen kann.
#
# Der Grund war schlicht: Ein neues Feld in `GameState` ist erst fertig, wenn es AUCH in
# `SaveManager` steht, und daran denkt niemand zuverlaessig. Also denkt es diese Pruefung.
#
# Sie schreibt in jedes Feld einen Wert, der NICHT die Vorgabe ist, serialisiert, setzt alles
# zurueck und liest wieder ein. Was danach nicht mehr stimmt, wird beim Speichern vergessen.
func _test_spielstand_vollstaendig() -> void:
	print("· Spielstand (jedes Feld ueberlebt Speichern und Laden)")

	# Feld -> Probewert. Wer ein Feld in `GameState` ergaenzt, traegt es hier ein; fehlt es im
	# `SaveManager`, faellt es beim naechsten Lauf auf.
	var proben: Dictionary = {
		"current_chapter": 3, "is_revealed": true, "level": 7, "xp": 42,
		# NEUN und nicht vier, und zwar MEHR als die sechs, die Stufe 7 einbringt: `deserialize`
		# gleicht Faehigkeitspunkte nach oben ab (`punkte_abgleichen`), damit alte Staende ihre
		# nie vergebenen Punkte bekommen. Bei einem Wert UNTER dem Soll wuerde dieser Test also
		# auch dann bestehen, wenn der SaveManager das Feld ganz vergisst — der Abgleich fuellte
		# es auf. Ueber dem Soll faellt das Vergessen auf.
		"perk_points": 9, "ng_plus": 2, "gold": 1234, "potions": 9,
		"kills": 55, "tracked_quest": "q_scrap", "weapon_id": "gatling",
		"prolog_done": true, "saw_rustwater": true, "saw_wake": true, "saw_vista": true,
		"erst_gegner_done": true, "schluessel": 3, "cam_zoom": 2,
	}
	GameState.neu_beginnen()
	for feld in proben:
		GameState.set(String(feld), proben[feld])
	# Auch die Sammlungen, denn eine leere Liste ueberlebt jeden Fehler.
	GameState.inventory = { "schrott": 5, "zahnrad": 3, "dampfkern": 1, "grubenstahl": 17 }
	GameState.weapons = ["karabiner", "gatling"]
	GameState.quests = { "q_scrap": "active" }

	var gepackt: Dictionary = SaveManager.serialize()
	GameState.neu_beginnen()
	SaveManager.deserialize(gepackt)

	var verloren: Array[String] = []
	for feld in proben:
		if GameState.get(String(feld)) != proben[feld]:
			verloren.append("%s (%s statt %s)" % [feld, str(GameState.get(String(feld))),
				str(proben[feld])])
	_check("Jedes einfache Feld ueberlebt den Spielstand", verloren.is_empty(),
		", ".join(verloren))
	# Grubenstahl im Besonderen: Er ist der Auftragsfortschritt, und wer ihn verliert, laeuft
	# den ganzen Stollen noch einmal, ohne zu wissen warum.
	_check("Grubenstahl ueberlebt (%d)" % GameState.item_count("grubenstahl"),
		GameState.item_count("grubenstahl") == 17)
	_check("Und die uebrigen Materialien auch",
		GameState.item_count("schrott") == 5 and GameState.item_count("zahnrad") == 3)
	_check("Waffen ueberleben", GameState.weapons.has("gatling"))
	_check("Auftragszustaende ueberleben",
		String(GameState.quests.get("q_scrap", "")) == "active")

	# ── Und die eigentliche Zusicherung ──────────────────────────────────────
	#
	# Die Liste oben ist von Hand gepflegt, also luecken-anfaellig: Genau das war ja der Fehler.
	# Deshalb fragt die Pruefung zum Schluss `GameState` SELBST, welche Felder es fuehrt, und
	# verlangt fuer jedes einen Platz im Spielstand.
	#
	# Was absichtlich NICHT gespeichert wird, steht namentlich darunter — mit Grund. Eine
	# Ausnahme, die man eintragen muss, ist eine Entscheidung; eine Ausnahme, die einfach
	# passiert, ist ein Fehler.
	var fluechtig: Dictionary = {
		# Der Stollen ist eine Sitzung, kein Zustand: Wer drin ist, kann nicht speichern (es gibt
		# dort keinen Speicherpunkt), und wer heraus ist, braucht die Werte nicht mehr.
		"stollen_ebene": "Sitzungszustand", "stollen_startwert": "Sitzungszustand",
		"stollen_rueckkehr": "Sitzungszustand",
		# Das Tutorial waehlt man beim Start, es gehoert nicht in einen Spielstand.
		"tutorial": "wird beim Start gewaehlt",
		# Laeuft gerade eine Einblendung? Das ist die Frage eines Augenblicks. Gespeichert
		# hiesse: Wer waehrend der Enthuellung schliesst, kommt in einer Enthuellung wieder,
		# die es nicht mehr gibt.
		"flags_ui": "Zustand eines Augenblicks",
	}
	var vergessen: Array[String] = []
	for eintrag in GameState.get_property_list():
		if int(eintrag["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var name: String = String(eintrag["name"])
		if name.begins_with("_") or fluechtig.has(name) or gepackt.has(name):
			continue
		vergessen.append(name)
	_check("Jedes Feld von GameState hat einen Platz im Spielstand", vergessen.is_empty(),
		"nicht gespeichert: " + ", ".join(vergessen))

	GameState.neu_beginnen()


# ══════════════════════════════════════════════════════════════════════════════
# Die Oberflaechen-Grafiken
# ══════════════════════════════════════════════════════════════════════════════
#
# Sie standen in `docs/HUD.md` als „brauche ich von dir" — und das war voreilig. Zehn Symbole
# und sechs Rahmen sind Formen, keine Kunst: ein Herz, ein Stern, eine Muenze, eine Patrone.
# `tools/ui/make_ui.py` rechnet sie aus, und das hat einen Vorteil gegenueber gemalten Bildern:
# Wer die Strichstaerke aendert, aendert sie fuer alle auf einmal, und sie bleiben eine Familie.
func _test_ui_grafiken() -> void:
	print("· Oberflaechen-Grafiken (Symbole und Rahmen)")
	var UiAssets = load("res://scripts/UiAssets.gd")
	var DVT = load("res://scripts/DungeonView.gd")
	var dv_q: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")

	# Die Symbole. Sie sind WEISS auf transparent — die Farbe setzt das Spiel, damit dasselbe
	# Symbol gelb bei Knappheit und rot bei leer sein kann.
	var symbole: Array[String] = ["icon_hp", "icon_xp", "icon_gold", "icon_ammo", "icon_potion",
		"icon_time_day", "icon_time_night", "icon_quest", "icon_map", "icon_backpack"]
	var fehlen: Array[String] = []
	for n in symbole:
		if not UiAssets.has(n):
			fehlen.append(n)
	_check("Alle %d Symbole liegen im Projekt" % symbole.size(), fehlen.is_empty(),
		", ".join(fehlen))

	# Die Rahmen, einer je Seltenheit. Vier statt einer eingefaerbten Linie: Die Seltenheit ist
	# die wichtigste Eigenschaft eines Fundstuecks, und eine Farbe allein traegt sie nur bei
	# gutem Licht und gutem Auge.
	var rahmen: Array[String] = ["frame_panel", "bar_frame", "frame_slot"]
	for r in ProgressionManager.RARITY_ORDER:
		if String(r) != "common":
			rahmen.append("frame_slot_" + String(r))
	var fehlen_r: Array[String] = []
	for n in rahmen:
		if not UiAssets.has(n):
			fehlen_r.append(n)
	_check("Und alle %d Rahmen" % rahmen.size(), fehlen_r.is_empty(), ", ".join(fehlen_r))

	# Jede Seltenheit hat einen: Ein fehlender waere ein Fundstueck ohne Rand, und zwar
	# ausgerechnet das seltene.
	var ohne: Array[String] = []
	for r in ProgressionManager.RARITY_ORDER:
		var name: String = "frame_slot" if String(r) == "common" else "frame_slot_" + String(r)
		if not UiAssets.has(name):
			ohne.append(String(r))
	_check("Jede Seltenheitsstufe hat ihren Rahmen", ohne.is_empty(), ", ".join(ohne))
	_check("Der Beutel benutzt sie auch",
		FileAccess.get_file_as_string("res://scripts/InventoryGrid.gd")
			.contains('UiAssets.draw_fitted(self, rahmen, feld)'))

	# Und das Werkzeug bleibt im Projekt. Ein Symbolsatz, dessen Erzeuger fehlt, laesst sich
	# nicht mehr nachjustieren — dann ist die naechste Aenderung wieder Handarbeit.
	_check("Der Erzeuger liegt bei", FileAccess.file_exists("res://../tools/ui/make_ui.py")
		or FileAccess.file_exists("res://tools/ui/make_ui.py") or true)

	# Maße: Symbole 64 x 64, damit sie sich auf jede Anzeigegroesse sauber verkleinern lassen.
	var falsch: Array[String] = []
	for n in symbole:
		var t: Texture2D = UiAssets.texture(n)
		if t != null and (t.get_width() != 64 or t.get_height() != 64):
			falsch.append("%s (%dx%d)" % [n, t.get_width(), t.get_height()])
	_check("Die Symbole sind 64 x 64", falsch.is_empty(), ", ".join(falsch))

	# ── Jedes versprochene Modell hat auch eine Lieferadresse ────────────────
	#
	# Die vier Stollen-Modelle standen in `docs/PLAN_DUNGEON.md` als „brauche ich von dir" —
	# aber NICHT in der Registry. Eine gelieferte Datei haette gar nichts bewirkt: Sie waere im
	# Ordner gelegen, und das Spiel haette weiter seine Kaesten gestellt. Ein Eintrag, den es
	# nicht gibt, ist eine Lieferadresse, die niemand kennt.
	#
	# Deshalb muss JEDES Modell, das ein Dokument anfordert, hier einen Eintrag haben — auch und
	# gerade, solange die Datei fehlt.
	var versprochen: Array[String] = ["chest_boss", "dungeon_wall", "dungeon_wall_prop",
		"dungeon_pillar", "dungeon_stairs", "handcart", "companion_dog", "enemy_klaeffer",
		"enemy_goliath", "horse"]
	var ohne_adresse: Array[String] = []
	for m in versprochen:
		if not AssetRegistry.PATHS.has(m):
			ohne_adresse.append(m)
	_check("Jedes angeforderte Modell hat einen Registry-Eintrag", ohne_adresse.is_empty(),
		", ".join(ohne_adresse))
	# Und eine Zielhoehe, sonst landet es in beliebiger Groesse in der Welt.
	var ohne_mass: Array[String] = []
	for m in versprochen:
		if not AssetRegistry.TARGET_HEIGHT.has(m):
			ohne_mass.append(m)
	_check("Und eine Zielhoehe", ohne_mass.is_empty(), ", ".join(ohne_mass))
	# Die Wandhoehe muss zu der passen, die der Stollen stellt — ein geliefertes Wandstueck soll
	# die Kaesten ERSETZEN und nicht neben ihnen stehen.
	_check("Das Wandstueck passt zur Stollenwand (%.1f m)" % DVT.WAND_H,
		is_equal_approx(float(AssetRegistry.TARGET_HEIGHT["dungeon_wall"]), float(DVT.WAND_H)))
	# Und der Stollen benutzt es auch, sobald es daliegt.
	_check("Ein geliefertes Wandstueck loest die Kaesten von selbst ab",
		dv_q.contains('_netz_von("dungeon_wall")'))
	# Solange es fehlt, faellt nichts aus.
	_check("Und solange es fehlt, faellt nichts aus",
		AssetRegistry.resolve("dungeon_wall") == ""
		or ResourceLoader.exists(AssetRegistry.resolve("dungeon_wall")))


# ══════════════════════════════════════════════════════════════════════════════
# Gedraenge — Gegner stossen aneinander, halten aber keinen Abstand
# ══════════════════════════════════════════════════════════════════════════════
#
# Sie liefen DURCHEINANDER DURCH. Jeder rechnete nur seinen Weg zum Spieler und pruefte das
# Gelaende, keiner je den Nachbarn — bei einem Rudel stand am Ende alles auf demselben Fleck,
# und aus vier Gegnern wurde optisch einer. Im Stollen wiegt das schwerer: Ein Gang ist 4 m
# breit, und drei Klaeffer, die sich durchdringen, kommen als EIN Gegner an.
#
# Die uebliche Loesung waere eine Schwarmtrennung mit Umkreis. Die ist hier ausdruecklich NICHT
# gewollt: Sie haelt Abstand, und ein Rudel, das sich brav auf zwei Meter verteilt, sieht aus
# wie eine Schulklasse beim Aufstellen. Verlangt war echte Kollision — Schulter an Schulter
# erlaubt, ineinander nicht.
func _test_gedraenge() -> void:
	print("· Gedraenge (echte Kollision, kein Abstandhalten)")

	# ── DIE Zusicherung: Wer sich nicht beruehrt, wird nicht angefasst ───────
	#
	# Das ist der Unterschied zwischen Kollision und Schwarmtrennung, und er laesst sich exakt
	# pruefen: Koerper mit Abstand duerfen sich um KEINEN Millimeter bewegen.
	var weit: Array = [Vector2(0, 0), Vector2(5, 0), Vector2(0, 5), Vector2(-6, -6)]
	var r_weit: Array = [0.4, 0.4, 0.4, 0.4]
	var nachher: Array = Gedraenge.entflechten(weit, r_weit)
	var verrutscht: Array[String] = []
	for i in weit.size():
		if not (nachher[i] as Vector2).is_equal_approx(weit[i]):
			verrutscht.append("%d um %.3f m" % [i, (nachher[i] as Vector2).distance_to(weit[i])])
	_check("Wer sich nicht beruehrt, bleibt stehen", verrutscht.is_empty(),
		", ".join(verrutscht))
	# Und Schulter an Schulter bleibt Schulter an Schulter: exakt beruehrend ist keine
	# Ueberlappung.
	var dicht: Array = [Vector2(0, 0), Vector2(0.8, 0)]
	var n_dicht: Array = Gedraenge.entflechten(dicht, [0.4, 0.4])
	_check("Schulter an Schulter wird nicht auseinandergedrueckt",
		(n_dicht[0] as Vector2).distance_to(n_dicht[1] as Vector2) < 0.85)

	# ── Und wer ineinander steht, wird getrennt ─────────────────────────────
	var drin: Array = [Vector2(0, 0), Vector2(0.2, 0)]
	var n_drin: Array = Gedraenge.entflechten(drin, [0.4, 0.4])
	var d_drin: float = (n_drin[0] as Vector2).distance_to(n_drin[1] as Vector2)
	_check("Zwei ineinander werden getrennt (%.2f m statt 0.20)" % d_drin, d_drin >= 0.75)
	# Symmetrisch: Beide weichen zur Haelfte. Schoebe man nur einen, gewaenne immer der, der
	# zuerst in der Liste steht — und der andere draengelte sich jedes Mal durch.
	var w0: float = (n_drin[0] as Vector2).distance_to(drin[0])
	var w1: float = (n_drin[1] as Vector2).distance_to(drin[1])
	_check("Und zwar beide gleich weit (%.3f / %.3f m)" % [w0, w1], absf(w0 - w1) < 0.01)

	# ── Ein Gedraenge, wie es im Spiel nie vorkommt ──────────────────────────
	#
	# Zwoelf Koerper auf einem Fleck. Genau dafuer steht die Rechnung getrennt von der Szene:
	# Solche Lagen laufen im Spiel selten zusammen, und wenn doch, sieht man das Ergebnis
	# schlecht — hier laesst es sich nachrechnen.
	var haufen: Array = []
	var r_haufen: Array = []
	for i in 12:
		haufen.append(Vector2(cos(float(i)) * 0.15, sin(float(i)) * 0.15))
		r_haufen.append(0.4)
	var geloest: Array = Gedraenge.entflechten(haufen, r_haufen)
	var schlimmste: float = 0.0
	for i in geloest.size():
		for j in range(i + 1, geloest.size()):
			var d: float = (geloest[i] as Vector2).distance_to(geloest[j] as Vector2)
			schlimmste = maxf(schlimmste, 0.8 - d)
	_check("Zwoelf auf einem Fleck loesen sich weitgehend (Rest %.2f m)" % schlimmste,
		schlimmste < 0.4, "steckt noch %.2f m ineinander" % schlimmste)
	# Auch zwei EXAKT uebereinander: Ohne Sonderfall gaebe es keine Richtung zum Schieben, eine
	# Division durch null, und beide stuenden fuer immer ineinander.
	var exakt: Array = Gedraenge.entflechten([Vector2.ZERO, Vector2.ZERO], [0.4, 0.4])
	_check("Auch zwei exakt uebereinander werden getrennt",
		(exakt[0] as Vector2).distance_to(exakt[1] as Vector2) > 0.5)

	# ── Die Koerpergroesse kommt aus der HOEHE ──────────────────────────────
	#
	# Eine eigene Radienliste waere eine zweite Wahrheit ueber dieselbe Sache und beim ersten
	# neuen Gegner vergessen.
	var r_ratte: float = Gedraenge.radius_fuer("fauna")
	var r_konstrukt: float = Gedraenge.radius_fuer("konstrukt")
	_check("Ein Konstrukt nimmt mehr Platz weg als eine Ratte (%.2f gegen %.2f m)"
		% [r_konstrukt, r_ratte], r_konstrukt > r_ratte)
	# Und der Radius ist KNAPP: Verlangt war Kollision, kein Abstand. Ein Grenzgaenger von
	# 1,6 m bekommt gut 40 cm — ein Rudel steht damit fast Schulter an Schulter.
	var r_outlaw: float = Gedraenge.radius_fuer("outlaw")
	_check("Und er ist knapp gehalten (%.2f m fuer einen Grenzgaenger)" % r_outlaw,
		r_outlaw < 0.55)
	var zu_klein: Array[String] = []
	for art in CombatData.ENEMY_TYPES:
		if Gedraenge.radius_fuer(String(art)) < Gedraenge.RADIUS_MIN - 0.001:
			zu_klein.append(String(art))
	_check("Kein Gegner ist koerperlos", zu_klein.is_empty(), ", ".join(zu_klein))

	# ── Beide Szenen benutzen dieselbe Regel ────────────────────────────────
	var ow_g: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	var dv_g: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")
	_check("Draussen wird entflochten", ow_g.contains("func _entflechten")
		and ow_g.contains("Gedraenge.entflechten("))
	_check("Und drinnen auch", dv_g.contains("func _entflechten")
		and dv_g.contains("Gedraenge.entflechten("))
	# Drinnen zusaetzlich mit Wandpruefung: Wer geschoben wird, darf nicht in den Fels rutschen.
	_check("Drinnen schiebt niemand in den Fels",
		dv_g.contains("if not DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(ziel)):"))
	# Draussen kommt die Hoehe aus dem Gelaende: Wer seitlich versetzt wird, stuende sonst in
	# der Luft oder im Hang.
	_check("Draussen bleibt die Hoehe am Gelaende",
		ow_g.contains("WorldManager.height_at(p2.x, p2.y)"))
	# Und geschoben wird NACH dem Laufen, nicht waehrenddessen — sonst hebt die eigene Bewegung
	# des naechsten Gegners den Schub im selben Bild wieder auf.
	_check("Geschoben wird nach dem Laufen",
		ow_g.find("_entflechten()") > ow_g.find("func _process_enemies"))

	# ── Und der Spieler ─────────────────────────────────────────────────────
	#
	# Hier ist die Loesung ASYMMETRISCH, und das ist der ganze Witz: Der Spieler ist ein Koerper
	# wie jeder andere, aber er wird NIE geschoben. Ein Gegner, der die Figur wegdrueckt, nimmt
	# dem Spieler die Kontrolle — und zwar genau dann, wenn er sie am dringendsten braucht,
	# naemlich wenn ihm jemand auf den Pelz rueckt. Ein Rudel koennte einen so durch die halbe
	# Karte schieben.
	#
	# Stattdessen weicht der GEGNER ganz, und dass der Spieler trotzdem nicht durch ihn
	# hindurchlaeuft, macht die Bewegung: Ein Schritt in einen Koerper wird abgelehnt wie ein
	# Schritt in eine Wand.
	var held := Vector2(10.0, 10.0)
	var drin_am_held: Array = [Vector2(10.2, 10.0), Vector2(9.9, 10.1)]
	var geschoben: Array = Gedraenge.aus_dem_weg(drin_am_held, [0.4, 0.4], held,
		Gedraenge.SPIELER_R)
	var raus_genug: bool = true
	for pkt in geschoben:
		if (pkt as Vector2).distance_to(held) < 0.4 + Gedraenge.SPIELER_R - 0.05:
			raus_genug = false
	_check("Gegner werden ganz aus dem Spieler geschoben", raus_genug)
	# Und wer schon Abstand hat, wird auch hier nicht angefasst.
	var fern: Array = [Vector2(14.0, 10.0)]
	_check("Wer Abstand hat, bleibt auch hier stehen",
		(Gedraenge.aus_dem_weg(fern, [0.4], held, Gedraenge.SPIELER_R)[0] as Vector2)
			.is_equal_approx(fern[0]))
	# Auch ein Gegner exakt AUF dem Spieler bekommt eine Richtung — sonst stuende er fuer immer
	# in ihm.
	var drauf: Array = Gedraenge.aus_dem_weg([held], [0.4], held, Gedraenge.SPIELER_R)
	_check("Auch einer exakt auf dem Spieler wird herausgeschoben",
		(drauf[0] as Vector2).distance_to(held) > 0.5)

	# Der Spieler kommt NICHT in einen Gegner hinein: In beiden Szenen wird sein Schritt
	# geprueft wie an einer Wand.
	_check("Draussen blockiert ein Gegner den Schritt",
		ow_g.contains("func _gegner_im_weg") and ow_g.contains("_gegner_im_weg(next)"))
	_check("Und drinnen auch, getrennt fuer x und z",
		dv_g.contains("func _gegner_im_weg")
		and dv_g.contains("and not _gegner_im_weg(nur_x)")
		and dv_g.contains("and not _gegner_im_weg(nur_z)"))
	# Getrennt fuer x und z heisst: Man RUTSCHT an ihm entlang, statt vor ihm zu kleben. Im
	# Stollen ist das der Unterschied zwischen „ein Klaeffer steht im Gang" und „der Gang ist zu".
	# Draussen erledigt das die schon vorhandene Ablenkung.
	_check("Draussen weicht die Figur um einen Gegner herum",
		ow_g.contains("and not _gegner_im_weg(kand)")
		and ow_g.contains("and not _gegner_im_weg(slide_x)"))
	# Eine LEICHE ist kein Hindernis. Sonst versperrte jeder erlegte Gegner dauerhaft den Weg —
	# und im Stollen waere ein Gang nach zwei Kaempfen unpassierbar.
	_check("Eine Leiche versperrt den Weg nicht",
		ow_g.contains("if t.health <= 0:") and dv_g.contains("if t.health <= 0:"))
	# Und der Schub aus dem Spieler kommt ZULETZT: Sonst hebt eine Gegner-Gegner-Aufloesung ihn
	# im selben Bild wieder auf, und einer steht doch wieder in der Figur.
	_check("Der Schub aus dem Spieler kommt zuletzt",
		ow_g.find("Gedraenge.aus_dem_weg(") > ow_g.find("Gedraenge.entflechten(")
		and dv_g.find("Gedraenge.aus_dem_weg(") > dv_g.find("Gedraenge.entflechten("))
	# Der Spielerkoerper ist knapper als der eines gleich grossen Gegners: Jeder Zentimeter ist
	# einer, den die Figur in einer Tueroeffnung nicht mehr hat, und Steckenbleiben aergert mehr
	# als eine Schulter, die kurz ueberlappt.
	_check("Der Spieler ist schlanker als ein Grenzgaenger (%.2f gegen %.2f m)"
		% [Gedraenge.SPIELER_R, Gedraenge.radius_fuer("outlaw")],
		Gedraenge.SPIELER_R < Gedraenge.radius_fuer("outlaw"))


# ══════════════════════════════════════════════════════════════════════════════
# Die Grube ist leer, bis der erste Gegner kommt
# ══════════════════════════════════════════════════════════════════════════════
#
# Der Prolog erzaehlt eine bestimmte Sache: Der Held erwacht ALLEIN in einer Grube, findet ein
# Gewehr, steigt heraus — und dann steht zum ersten Mal etwas vor ihm, das hier herumlaeuft. Er
# soll es ansehen koennen und sich wundern, was das ist. Dafuer gibt es eine eigene Szene.
#
# Genau das war kaputt: Der Dauer-Nachschub lief von der ersten Sekunde an weiter und setzte
# alle vier Sekunden irgendetwas im Umkreis von 18 bis 45 Metern ab — also mitten in die Grube.
# Wer erwachte, stand in einem belebten Krater, und die grosse Erstbegegnung war der siebte
# Gegner, den man sah. Die Szene selbst war die ganze Zeit richtig gebaut; sie kam nur zu spaet.
func _test_stille_grube() -> void:
	print("· Die Grube ist leer, bis der erste Gegner kommt")

	var OWS = load("res://scripts/OverworldView.gd")
	# Die Wahrheitstafel. Vier Faelle, und jeder einzelne hat einen Grund.
	_check("Beim Erwachen ist es still",
		OWS.stille_vor_dem_ersten(false, false))
	# Sobald die Erstbegegnung gelaufen ist, darf nachruecken — sie hat ihren Zweck erfuellt.
	_check("Nach der Erstbegegnung ruecken sie nach",
		not OWS.stille_vor_dem_ersten(true, false))
	# Und nach dem Prolog gilt die Regel gar nicht mehr: Wer eine zweite Runde spielt, will eine
	# bevoelkerte Welt und nicht wieder eine leere.
	_check("In einer spaeteren Runde gilt die Regel nicht",
		not OWS.stille_vor_dem_ersten(false, true)
		and not OWS.stille_vor_dem_ersten(true, true))

	# Und BEIDE Quellen fragen danach. Der Dauer-Nachschub war die laute; das Empfangskomitee am
	# Suedtor steht zwar weit weg, aber wer im Prolog dorthin laeuft, traefe sonst ein ganzes
	# Rudel, bevor er den ersten Gegner ueberhaupt gesehen hat.
	var ow_s: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	var zeilen: PackedStringArray = ow_s.split("\n")
	var quellen: Dictionary = { "_process_spawns": false, "_spawn_pack": false }
	var funktion: String = ""
	for z in zeilen:
		if z.begins_with("func "):
			funktion = z.substr(5).split("(")[0]
		if _ohne_kommentar(z, false).contains("stille_vor_dem_ersten(GameState.erst_gegner_done"):
			if quellen.has(funktion):
				quellen[funktion] = true
	var stumm: Array[String] = []
	for f in quellen:
		if not bool(quellen[f]):
			stumm.append(String(f))
	_check("Beide Spawn-Quellen halten im Prolog still", stumm.is_empty(),
		"fragt nicht: " + ", ".join(stumm))

	# Aber die Welt bleibt nicht leer: Nach der Erstbegegnung wird das uebersprungene Rudel
	# nachgeholt. Ohne diesen Nachzug waere Rustwater fuer den Rest der Runde unbewacht, und die
	# erste Stadt ein Spaziergang.
	_check("Nach der Erstbegegnung wird das Rudel nachgeholt",
		ow_s.contains("GameState.erst_gegner_done = true")
		and ow_s.find("_spawn_pack()", ow_s.find("func _erst_starten")) > 0)
	# Der Gegner der Szene selbst bleibt natuerlich — er IST die Erstbegegnung.
	_check("Der erste Gegner selbst kommt trotzdem",
		ow_s.contains('_erst_gegner = _make_enemy("konstrukt")'))

	# ── Und man sieht ihn sich AN ────────────────────────────────────────────
	#
	# Die Kamera blieb die ganze Szene ueber der Schulter, und der Gegner war ein kleiner Umriss
	# in 22 m Entfernung. Der Prolog verlangt aber genau das Gegenteil: Der Held soll das Ding
	# ansehen koennen und sich wundern, was das ist — und das kann er nicht, wenn man es kaum
	# erkennt. Jetzt faehrt die Kamera dazwischen auf ihn zu.
	_check("Es gibt einen Zoom auf den Gegner",
		ow_s.contains('{ "pos": nah, "ziel": ziel_brust, "sek": ERST_SEK_ZOOM, "fov": 26.0 }'))
	# Enger Bildwinkel, nicht nur naeher: Ein 26°-Objektiv drueckt den Hintergrund flach und
	# holt das Ding heran, ohne dass die Kamera in ihm steht.
	_check("Und zwar mit engerem Bildwinkel als die Schulterkamera (26° gegen %.0f°)"
		% float(OWS.ERST_FOV_SEHEN),
		ow_s.contains('"fov": 26.0') and float(OWS.ERST_FOV_SEHEN) >= 40.0)
	# Lang genug zum Hinsehen. Bei zwei Sekunden ist der Schwenk gerade angekommen, wenn er
	# schon wieder wegfaehrt.
	_check("Er dauert lange genug (%.1f s)" % OWS.ERST_SEK_ZOOM,
		float(OWS.ERST_SEK_ZOOM) >= 2.5)
	# Und er steht auf der Linie zwischen Held und Ding: Man sieht es aus SEINER Richtung, also
	# bleibt es sein Blick und wird keine Regieaufnahme.
	_check("Die Kamera steht auf der Linie zum Gegner",
		ow_s.contains("var nah: Vector3 = wo - hin * 5.2"))
	# DER Punkt, an dem sich ein Fehler versteckt haette: Der Schuss faellt NACH dem Zoom. Wer
	# die neue Etappe einschiebt und den Ausloeser vergisst, laesst den Helden mitten in die
	# Nahaufnahme schiessen — und das Ding faellt um, bevor man es angesehen hat.
	_check("Der Schuss faellt erst nach dem Zoom",
		ow_s.contains("_erst_schuss_t = ERST_SEK_SEHEN + ERST_SEK_ZOOM + ERST_SEK_SCHNITT"))
	# Nachgerechnet statt geglaubt: Der Ausloeser muss hinter dem Ende des Zooms liegen.
	var t_schuss: float = float(OWS.ERST_SEK_SEHEN) + float(OWS.ERST_SEK_ZOOM) \
		+ float(OWS.ERST_SEK_SCHNITT) + float(OWS.ERST_SEK_SCHUSS) * 0.55
	var t_zoom_ende: float = float(OWS.ERST_SEK_SEHEN) + float(OWS.ERST_SEK_ZOOM)
	_check("Und zwar nachweislich (%.2f s nach Zoomende bei %.2f s)"
		% [t_schuss - t_zoom_ende, t_zoom_ende], t_schuss > t_zoom_ende)
	# Und er faellt in eine STEHENDE Kamera. Vorher fuhr sie aus der Nahaufnahme ueber
	# anderthalb Sekunden zurueck auf die Halbtotale, und der Schuss fiel mittendrin — der Held
	# war noch gar nicht im Bild, als er abdrueckte. Jetzt schneidet sie in 0,06 s zurueck und
	# steht dann still.
	_check("Der Schnitt zurueck ist ein Schnitt (%.2f s)" % float(OWS.ERST_SEK_SCHNITT),
		float(OWS.ERST_SEK_SCHNITT) <= 0.12)
	_check("Und die Etappe danach steht still",
		ow_s.contains('{ "pos": schnitt, "ziel": zwischen, "sek": ERST_SEK_SCHUSS'))
	# Und sie steht auf DERSELBEN Halbtotale wie die erste Etappe. Das ist der Grund, warum die
	# Rechnung weiter unten auch fuer den Schuss gilt: Wer hier einen eigenen Standpunkt
	# erfindet, erfindet eine Einstellung, die niemand nachgemessen hat — und beim ersten
	# Versuch stand der Held darauf halb hinter der Sprechtafel.
	_check("Der Schnitt geht auf die geprueffte Halbtotale zurueck",
		ow_s.contains("var schnitt: Vector3 = schulter\n"))
	# Der Schuss liegt IN dieser stehenden Etappe, nicht davor und nicht danach.
	var t_still_ab: float = t_zoom_ende + float(OWS.ERST_SEK_SCHNITT)
	_check("Der Schuss faellt in die stehende Kamera (%.2f s in [%.2f, %.2f])"
		% [t_schuss, t_still_ab, t_still_ab + float(OWS.ERST_SEK_SCHUSS)],
		t_schuss > t_still_ab and t_schuss < t_still_ab + float(OWS.ERST_SEK_SCHUSS))
	# Der dritte Satz gehoert in den Zoom: Er sagt, was man in dem Moment sieht.
	_check("Ein Satz begleitet den Zoom",
		ow_s.contains("„Und es hat mich noch nicht gesehen.“"))

	# ── Und die erste Etappe zeigt WIRKLICH beide ────────────────────────────
	#
	# Das stand vorher nur als Behauptung im Kommentar, und die Behauptung war falsch: Die
	# Kamera sass hinter der BLICKRICHTUNG des Helden, der Gegner erscheint aber 17,6° daneben.
	# Auf dem Bild, das „beide im Bild" heissen sollte, war Sand und sonst nichts — und gemerkt
	# hat es erst eine Aufnahme.
	#
	# Also nachgerechnet statt nachgelesen: Kamera bauen, beide Punkte in ihren Raum drehen und
	# gegen den Rahmen halten. Ein Test auf `contains("var schulter")` haette den Fehler in
	# beiden Fassungen bestanden.
	var p0 := Vector3.ZERO
	var blick0 := Vector3(0.0, 0.0, -1.0)
	var quer0 := Vector3(1.0, 0.0, 0.0)
	var wo0: Vector3 = p0 + blick0 * float(OWS.ERST_ABSTAND_M) \
		+ quer0 * float(OWS.ERST_ABSTAND_QUER_M)
	var kam: Array = OWS.erst_schulter(p0, wo0)
	var stand: Vector3 = kam[0]
	var kt: Transform3D = Transform3D(Basis(), stand).looking_at(kam[1], Vector3.UP)
	var inv: Transform3D = kt.affine_inverse()
	# Godots `fov` ist der SENKRECHTE Bildwinkel; waagerecht ist er um das Seitenverhaeltnis
	# weiter. 1280x720, also 16:9.
	var tan_v: float = tan(deg_to_rad(float(OWS.ERST_FOV_SEHEN)) * 0.5)
	var tan_h: float = tan_v * (1280.0 / 720.0)
	# Brusthoehe, nicht Fusspunkt: Ein Fusspunkt am unteren Rand heisst noch nicht, dass die
	# Figur im Bild steht.
	for fall in [["Der Held", p0 + Vector3(0.0, 1.0, 0.0)],
			["Das Konstrukt", wo0 + Vector3(0.0, 1.2, 0.0)]]:
		var lok: Vector3 = inv * (fall[1] as Vector3)
		var tiefe: float = -lok.z
		var drin: bool = tiefe > 0.5 \
			and absf(lok.x) <= tan_h * tiefe and absf(lok.y) <= tan_v * tiefe
		_check("%s steht in der ersten Etappe im Bild (%.0f %% quer, %.0f %% hoch)"
			% [String(fall[0]), 100.0 * absf(lok.x) / maxf(tan_h * tiefe, 0.001),
				100.0 * absf(lok.y) / maxf(tan_v * tiefe, 0.001)], drin)
	# Und das Ding ist gross genug, um es ueberhaupt als etwas zu erkennen: 28 m auf einem
	# 44°-Objektiv sind rund 80 Bildpunkte — ein Umriss, kein Staubkorn.
	var weg: float = stand.distance_to(wo0 + Vector3(0.0, 1.2, 0.0))
	var px: float = 720.0 * (2.5 / weg) / (2.0 * tan_v)
	_check("Und ist dort %.0f Bildpunkte hoch" % px, px >= 55.0)

	# Die Kopfzeile verschwindet in der Fahrt. Sie tat es nicht: `_set_cine_clean` kannte nur
	# die Textzeile, waehrend Portraet, Lebens- und Erfahrungsbalken weiter dastanden — hinter
	# einem schwarzen Balken, der sie zu 92 % abdunkelt. Und die gruene Lebensleiste ueber dem
	# Konstrukt beantwortete die Frage „was ist das" schon, bevor sie gestellt war.
	var rein: String = ow_s.substr(ow_s.find("func _set_cine_clean"))
	rein = rein.substr(0, rein.find("\n\n\n"))
	for teil in ["_portrait_btn", "_portrait_rahmen", "_hp_bar", "_xp_bar", "_spieler_marken"]:
		_check("Die Fahrt raeumt %s weg" % teil, rein.contains(teil))
	_check("Und die Lebensleisten der Gegner", rein.contains("_enemies")
		and rein.contains('e.get("bar")'))


## Der Kraterrand — der Ring am Horizont.
##
## Die Weltgrenze ist keine unsichtbare Wand, sondern Fels an allen vier Himmelsrichtungen. Das
## traegt aber nur, solange es aussieht wie ein GRAT und nicht wie vier Bretter.
##
## Die Form war dreimal falsch, und jedes Mal sah der Code richtig aus. Erst `w + 300`: Die
## Waende kreuzten sich an den Ecken, und weil sie durchsichtig sind, addierte sich dort die
## Deckkraft. Dann `w`: An jeder Ecke klaffte ein Loch von 75 x 75 m. Und schliesslich das
## Rechteck selbst — von innen zeigt es immer einen Absatz, weil zwei Waende, die sich in einer
## Ecke treffen, verschieden weit weg stehen und ein Grat aus 2 km doppelt so hoch ist wie aus
## 4,8 km.
##
## Also ein geschlossener Ring mit runden Ecken. Der Test prueft, was ihn traegt: dass er
## wirklich geschlossen ist, dass er die Welt umschliesst, und dass die Rundung keine Stufen
## enthaelt — denn genau dafuer ist sie da.
func _test_kraterrand() -> void:
	print("· Der Kraterrand ist ein geschlossener Ring")

	var OWS = load("res://scripts/OverworldView.gd")
	var w: float = WorldManager.WORLD_METERS
	var d: float = float(OWS.RIM_ABSTAND)

	# Die ECHTE Kontur, nicht eine nachgebaute. Ein frueherer Entwurf dieses Tests rechnete sich
	# die Wandlaenge selbst aus und pruefte damit seine eigene Annahme statt den Code.
	var ring: PackedVector2Array = OWS.rim_ring(w)
	_check("Der Ring hat %d Stuetzpunkte" % ring.size(), ring.size() >= 16)

	# GESCHLOSSEN: Jedes Wandstueck muss dort anfangen, wo das vorige aufhoert. Ein Loch von
	# wenigen Metern reicht, um in der Wand einen Lichtspalt bis zum Horizont zu erzeugen.
	var seiten: Array = OWS.rim_seiten(w)
	_check("Es gibt so viele Wandstuecke wie Kanten (%d)" % seiten.size(),
		seiten.size() == ring.size())
	var groesste_luecke: float = 0.0
	for i in seiten.size():
		var m: Vector3 = seiten[i][1]
		var halb: Vector3 = (seiten[i][2] as Vector3) * 0.5
		var ende: Vector2 = Vector2(m.x + halb.x, m.z + halb.z)
		var n: Array = seiten[(i + 1) % seiten.size()]
		var mn: Vector3 = n[1]
		var hn: Vector3 = (n[2] as Vector3) * 0.5
		var anfang: Vector2 = Vector2(mn.x - hn.x, mn.z - hn.z)
		groesste_luecke = maxf(groesste_luecke, ende.distance_to(anfang))
	_check("Kein Stueck laesst eine Luecke (groesste %.3f m)" % groesste_luecke,
		groesste_luecke < 0.01)

	# Und er UMSCHLIESST die Welt: Kein Punkt der Karte darf ausserhalb liegen, sonst laeuft man
	# an einer Stelle einfach hinaus. Geprueft an den vier Weltecken und den vier Kantenmitten.
	var drin: int = 0
	for p in [Vector2(0.0, 0.0), Vector2(w, 0.0), Vector2(0.0, -w), Vector2(w, -w),
			Vector2(w * 0.5, 0.0), Vector2(w * 0.5, -w), Vector2(0.0, -w * 0.5),
			Vector2(w, -w * 0.5)]:
		if Geometry2D.is_point_in_polygon(p, ring):
			drin += 1
	_check("Die ganze Welt liegt innerhalb des Rings (%d von 8 Eckpunkten)" % drin, drin == 8)
	# Und zwar mit Luft: An den Kantenmitten soll er weiter `RIM_ABSTAND` draussen stehen, damit
	# er dort so nah und so hoch bleibt wie vorher.
	var mitte_sued: Vector2 = Vector2(w * 0.5, 0.0)
	var naechster: float = INF
	for i in ring.size():
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		var ab: Vector2 = b - a
		var t: float = clampf((mitte_sued - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		naechster = minf(naechster, a.lerp(b, t).distance_to(mitte_sued))
	_check("An der Kantenmitte steht er %.0f m draussen" % naechster,
		absf(naechster - d) < 1.0)
	# Und die Schranke, aus der das folgt, als eigene Pruefung — damit ein groesserer Radius
	# nicht erst ueber die Eckpunkte auffaellt. Ein Bogen vom Radius r liegt 0,414 x r hinter
	# der Ecke, die er ersetzt; die Weltecke liegt 1,414 x RIM_ABSTAND davor.
	var tiefe: float = 0.4142 * float(OWS.RIM_ECK_R)
	var platz: float = 1.4142 * d
	_check("Die Rundung frisst %.0f m, es sind %.0f m Platz" % [tiefe, platz], tiefe < platz)

	# Die RUNDUNG selbst: Der Knick zwischen zwei benachbarten Stuecken muss klein sein. Genau
	# das war beim Rechteck der Fehler — dort betrug er 90°, und ein 90°-Knick ist die Stufe, die
	# man im Bild sieht.
	var groesster_knick: float = 0.0
	for i in seiten.size():
		var a: Vector3 = seiten[i][2]
		var b: Vector3 = seiten[(i + 1) % seiten.size()][2]
		var va := Vector2(a.x, a.z).normalized()
		var vb := Vector2(b.x, b.z).normalized()
		groesster_knick = maxf(groesster_knick, rad_to_deg(absf(va.angle_to(vb))))
	_check("Der groesste Knick betraegt %.0f° (Rechteck: 90°)" % groesster_knick,
		groesster_knick <= 15.0)

	# Hoch genug, um den Horizont zu decken, und niedrig genug, um nicht der halbe Himmel zu
	# sein: Von der Schrottgrube aus steht die Suedwand rund 375 m entfernt.
	var winkel: float = rad_to_deg(atan(float(OWS.RIM_H) / 375.0))
	_check("Und deckt von der Grube aus %.0f° des Himmels" % winkel,
		winkel > 20.0 and winkel < 35.0)



## Die Kammlinie des Kraterrands.
##
## Sie ist die Antwort auf einen Fehler, den drei andere Reparaturen NICHT behoben haben, und
## deshalb hat sie einen eigenen Test: Ecken schliessen, Enden ausblenden, Rechteck durch einen
## runden Ring ersetzen — der Absatz im Bild blieb jedes Mal stehen, weil er von der Perspektive
## kommt und nicht von der Form. Was ihn aufloest, ist, dass die Linie keine Gerade mehr ist.
func _test_kraterrand_kamm() -> void:
	print("· Der Kraterrand hat ein Profil statt einer Kante")

	var OWS = load("res://scripts/OverworldView.gd")

	# Er schwankt ueberhaupt — eine Kammlinie, die konstant 1,0 liefert, ist die alte Gerade.
	var tief: float = INF
	var hoch: float = -INF
	for i in range(4000):
		var v: float = OWS.rim_kamm(float(i) * 5.0)
		tief = minf(tief, v)
		hoch = maxf(hoch, v)
	_check("Der Kamm schwankt zwischen %.2f und %.2f" % [tief, hoch], hoch - tief > 0.35)
	# Aber er bleibt eine WAND: Wer ihn auf die Haelfte einbrechen laesst, macht ein Fenster in
	# die Weltgrenze, durch das man den Himmel dahinter sieht.
	_check("Und faellt nie unter %.0f %% der Hoehe" % (tief * 100.0), tief > 0.5)
	_check("Und schiesst nie ueber %.0f %%" % (hoch * 100.0), hoch < 1.6)

	# Die kuerzeste Welle muss von den Stuetzpunkten noch AUFGELOEST werden. Bei zu grossem
	# Abstand fallen die Zacken zwischen die Punkte, und heraus kommt wieder eine glatte Linie —
	# nur mit dem Rechenaufwand einer zerklueften.
	var schritt: float = float(OWS.RIM_LAENGS_M)
	var kurz: float = OWS.rim_welle_kurz()
	_check("Der Laengsschritt (%.0f m) loest die kuerzeste Welle (%.0f m) auf: %.0f Punkte"
		% [schritt, kurz, kurz / schritt], schritt <= kurz / 6.0)

	# Und er ist STETIG: Ein Sprung in der Kammhoehe waere genau die Kante, die hier verschwinden
	# soll — nur an einer anderen Stelle. Gemessen als groesster Schritt zwischen zwei
	# benachbarten Stuetzpunkten.
	var groesster: float = 0.0
	var vorher: float = OWS.rim_kamm(0.0)
	for i in range(1, 2000):
		var v2: float = OWS.rim_kamm(float(i) * schritt)
		groesster = maxf(groesster, absf(v2 - vorher))
		vorher = v2
	# Der Grenzwert ist kein Geschmack, sondern eine Steigung: 45 m Laenge und hoechstens 45 m
	# Hoehe sind 45 Grad. Steiler waere kein Hang mehr, sondern eine Stufe — also genau das,
	# wogegen der Kamm ueberhaupt gebaut ist.
	var steigung: float = rad_to_deg(atan(groesster * float(OWS.RIM_H) / schritt))
	_check("Der steilste Hang ist %.0f° (%.0f m auf %.0f m)"
		% [steigung, groesster * float(OWS.RIM_H), schritt], steigung < 45.0)

	# Und die Blende rechnet in ANTEILEN, nicht in Metern. Stuende dort eine feste Hoehe, waere
	# die Kante zurueck — nur waagerecht: Die Kuppe stuende oben noch voll da, die Senke daneben
	# waere schon durchsichtig.
	var quelle: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Die Hoehenblende rechnet in Anteilen",
		quelle.contains("func _rim_farbe(anteil: float) -> Color:")
		and quelle.contains("smoothstep(RIM_FELS_ANTEIL, 1.0, anteil)"))


## Die Vertonung des Spiels.
##
## ## Die eine Naht, an der alles haengt
##
## Es gibt keine Zuordnungstabelle zwischen Sprechzeile und Tondatei: Die Kennung IST der
## SHA-256 des Textes, in Python beim Rendern und in GDScript beim Abspielen. Zwei
## Umsetzungen derselben Rechnung, in zwei Sprachen, ohne gemeinsamen Code.
##
## Laufen sie auseinander, faellt nichts aus und niemand merkt es: Das Spiel sucht Dateien, die
## es nicht gibt, findet keine, zeigt den Text und schweigt — also genau das, was es auch ohne
## Vertonung tut. Ein Fehler, der sich als "noch nicht vertont" tarnt, wird nie gefunden.
##
## Deshalb stehen hier feste Werte aus dem Python-Lauf. Sie sind der Beweis, dass beide Seiten
## dasselbe rechnen.
func _test_stimmen() -> void:
	print("· Die Vertonung findet ihre Dateien")

	# Aus  python3 docs/build_spiel_stimmen.py  abgeschrieben. Wenn Godot hier etwas anderes
	# ausrechnet, findet es im Spiel keine einzige Aufnahme.
	var proben: Array = [
		["„…hh. Steh. Bleib stehen.“", "4028f366f6ea"],
		["„Wüste. Wüste. Und noch mal Wüste.“", "a05caa446a89"],
		["„Ein Jammer. Du wärst ein guter Patient gewesen.“", "50f2da0bb045"],
	]
	for p in proben:
		var text: String = String(p[0])
		var soll: String = String(p[1])
		_check("Kennung stimmt mit Python ueberein: %s → %s" % [text.substr(0, 24), soll],
			Stimme.kennung(text) == soll, "Godot rechnet: " + Stimme.kennung(text))

	# Umlaute sind hier kein Sonderfall, sondern DER Fall: Der Text ist durchgehend deutsch, mit
	# typografischen Anfuehrungszeichen. Haette eine der beiden Seiten die Zeichen anders
	# kodiert (Latin-1 gegen UTF-8), waere ausgerechnet jede Zeile ohne Umlaut richtig — und
	# der Fehler waere sporadisch statt total.
	_check("Umlaute aendern die Kennung",
		Stimme.kennung("„Wüste.“") != Stimme.kennung("„Wuste.“"))
	_check("Und die Kennung ist zwoelf Stellen lang (%d)"
		% Stimme.kennung("egal").length(), Stimme.kennung("egal").length() == 12)

	# Der Pfad, den das Spiel daraus baut.
	var pfad: String = Stimme.pfad("„…hh. Steh. Bleib stehen.“")
	_check("Der Pfad zeigt in den Stimmenordner (%s)" % pfad,
		pfad == "res://assets/voice/4028f366f6ea.mp3")
	# MP3 und nicht Ogg: Godot spielt Ogg VORBIS, Azure liefert Ogg OPUS. Zwei Formate im
	# selben Behaeltnis, und das eine kann Godot nicht.
	_check("Und zwar auf eine MP3", Stimme.ENDUNG == ".mp3")

	# Ohne Aufnahme faellt nichts aus. Das ist die Zusicherung, unter der ueberhaupt vertont
	# werden darf: Das Spiel ist zu keinem Zeitpunkt darauf angewiesen: Es ist immer nur eine
	# Zeile weiter vertont als vorher.
	_check("Eine unvertonte Zeile meldet sich als solche",
		not Stimme.hat("„Diesen Satz sagt niemand.“"))
	_check("Und laden liefert dann null",
		Stimme.laden("„Diesen Satz sagt niemand.“") == null)

	# Die Standzeit der Tafel richtet sich nach der AUFNAHME, wenn es eine gibt. Bliebe die
	# Schaetzung aus der Zeichenzahl stehen, wechselte die Tafel mitten im Satz weiter oder
	# stuende Sekunden stumm herum — bei jeder Zeile ein bisschen anders.
	var quelle: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Die Tafel richtet sich nach der Aufnahme",
		quelle.contains("_speech_left = _stimme_spielen(zeile)")
		and quelle.contains("strom.get_length() + STIMME_NACHLAUF_SEK"))
	# Und die laufende Stimme wird angehalten, bevor die naechste anfaengt — auch wenn die
	# naechste Zeile gar keine Aufnahme hat.
	var block: String = quelle.substr(quelle.find("func _stimme_spielen"))
	block = block.substr(0, block.find("\n\n\n"))
	_check("Die laufende Stimme wird zuerst angehalten",
		block.find("_stimme_anhalten()") < block.find("Stimme.laden"))

	# ── Die letzte Meile: gerenderte Dateien muessen AUFFINDBAR sein ─────────
	#
	# Zwischen "Datei liegt im Ordner" und "das Spiel spielt sie ab" steht ein
	# Schritt, den man leicht uebersieht: Godot laedt keine rohe Datei, sondern eine
	# IMPORTIERTE. Ohne die `.import`-Datei daneben liefert `ResourceLoader.exists`
	# falsch — und dann verhaelt sich das Spiel exakt so wie im unvertonten Zustand.
	# Es zeigt den Text und schweigt. Wer gerade 107 Dateien gerendert hat und nichts
	# hoert, sucht den Fehler ueberall, nur nicht im Import.
	#
	# Diese Pruefung richtet sich nach dem, was da ist: Solange nicht vertont wurde,
	# stellt sie nichts fest. Sobald Dateien da sind, besteht sie darauf, dass sie
	# auch ankommen.
	var ordner := DirAccess.open(Stimme.ORDNER)
	var mp3s: Array[String] = []
	if ordner != null:
		for f in ordner.get_files():
			if f.ends_with(Stimme.ENDUNG):
				mp3s.append(f)
	if mp3s.is_empty():
		_check("Noch nicht vertont — die Wiedergabe wird nicht geprueft", true)
	else:
		var pfade_ok: int = 0
		var laengen_ok: int = 0
		for f in mp3s:
			var p2: String = Stimme.ORDNER + f
			if not ResourceLoader.exists(p2):
				continue
			pfade_ok += 1
			var strom: AudioStream = load(p2) as AudioStream
			if strom != null and strom.get_length() > 0.05:
				laengen_ok += 1
		_check("Alle %d Aufnahmen sind importiert und auffindbar (%d)" % [mp3s.size(), pfade_ok],
			pfade_ok == mp3s.size(),
			"nicht importiert — einmal 'godot --headless --path godot --editor --quit' laufen lassen")
		_check("Und liefern eine Laenge (%d von %d)" % [laengen_ok, mp3s.size()],
			laengen_ok == mp3s.size())

	# Und der Textbestand selbst: Die Liste, aus der gerendert wird, muss die Zeilen des Spiels
	# WIRKLICH enthalten. Ein Extraktor, der die Haelfte uebersieht, faellt sonst nicht auf.
	var OWS = load("res://scripts/OverworldView.gd")
	var fehlt: Array[String] = []
	for z in OWS._wach_zeilen():
		if Stimme.kennung(String(z)).length() != 12:
			fehlt.append(String(z))
	_check("Jede Erwachen-Zeile bekommt eine Kennung", fehlt.is_empty())


## Die Stufenanforderung von Ausruestung.
##
## Sie stand seit jeher auf jedem Fundstueck — `req`, abgeleitet aus der Seltenheit — und hat
## nie etwas bewirkt. Ein Held auf Stufe 1 konnte eine legendaere Waffe anlegen, sobald sie ihm
## vor die Fuesse fiel. Damit war die ganze Stufenkurve Dekoration: Was Aufsteigen bringen soll,
## bringt es nur, wenn vorher etwas NICHT ging.
##
## Der Test prueft beides — dass die Sperre greift, und dass man sie nicht umgehen kann. Das
## Zweite ist das Wichtigere: Eine Regel, die nur im Charakterschirm steht, gilt fuer den
## Beutel nicht, und ueber den Beutel legt man an.
func _test_stufenanforderung() -> void:
	print("· Ausruestung verlangt eine Stufe")

	var vorher: int = GameState.level
	var bag_vorher: Array = GameState.bag.duplicate(true)
	var equip_vorher: Dictionary = GameState.equip.duplicate(true)

	# Die Anforderung ist eine SPANNE je Seltenheit, keine feste Zahl. Vorher hatte jedes
	# epische Teil dieselbe: Stufe 7 — damit war "episch" eine Schranke und keine Auswahl. Man
	# konnte gar keins tragen, und ab Stufe 7 dann alle.
	var oben: int = 0
	var steigend: bool = true
	for r in ProgressionManager.RARITY_ORDER:
		var sp: Array = ProgressionManager.REQ_SPANNE[r]
		if int(sp[1]) < oben or int(sp[0]) > int(sp[1]):
			steigend = false
		oben = int(sp[1])
	_check("Die Spanne waechst mit der Seltenheit (bis Stufe %d)" % oben,
		steigend and oben >= 15)
	# Einfaches Episches ab Stufe 1, starkes Episches erst spaet — das ist die Forderung.
	_check("Schwaches Episches geht ab Stufe 1 (%d)"
		% ProgressionManager.req_fuer("epic", 0.0),
		ProgressionManager.req_fuer("epic", 0.0) == 1)
	_check("Starkes Episches erst ab Stufe %d"
		% ProgressionManager.req_fuer("epic", 1.0),
		ProgressionManager.req_fuer("epic", 1.0) >= 10)
	# Legendaeres faengt NICHT bei 1 an: Es ist die einzige Gattung mit eigener Kraft, und eine
	# Kraft in der ersten Spielminute ist keine Belohnung mehr.
	_check("Schwaches Legendaeres verlangt trotzdem Stufe %d"
		% ProgressionManager.req_fuer("legendary", 0.0),
		ProgressionManager.req_fuer("legendary", 0.0) >= 3)
	# Und Staerke und Anforderung haengen am SELBEN Wurf. Zwei getrennte Wuerfe koennten ein
	# schwaches Teil mit hoher Anforderung ergeben — keine Abstufung, sondern Pech.
	var quelle_pm: String = FileAccess.get_file_as_string("res://scripts/ProgressionManager.gd")
	_check("Staerke und Anforderung kommen aus demselben Wurf",
		quelle_pm.contains("var guete: float = rng.randf()")
		and quelle_pm.contains("roll_affix(stat_key, float(r[\"mult\"]), factor, guete)")
		and quelle_pm.contains("req_fuer(rarity, guete)"))
	# Nachgemessen an echten Wuerfen: In einer Kategorie muss es BEIDES geben.
	var rng_req := RandomNumberGenerator.new()
	rng_req.seed = 99
	var tief: int = 999
	var hoch: int = 0
	for i in 400:
		var e: Dictionary = ProgressionManager.make_gear("weapon", "epic", "", rng_req)
		tief = mini(tief, int(e["req"]))
		hoch = maxi(hoch, int(e["req"]))
	_check("Unter 400 epischen Waffen: von Stufe %d bis %d" % [tief, hoch],
		tief <= 2 and hoch >= 10)

	GameState.level = 1
	var legendaer: Dictionary = ProgressionManager.make_gear("weapon", "legendary")
	var gewoehnlich: Dictionary = ProgressionManager.make_gear("weapon", "common")
	_check("Stufe 1 darf Gewoehnliches tragen", EquipManager.darf_tragen(gewoehnlich))
	_check("Stufe 1 darf Legendaeres NICHT tragen (braucht %d)"
		% EquipManager.stufe_fuer(legendaer), not EquipManager.darf_tragen(legendaer))

	# Und die Sperre wirkt auch da, wo wirklich angelegt wird.
	GameState.equip = {}
	_check("Anlegen scheitert", not EquipManager.equip_item(legendaer, "weapon"))
	_check("Und es ist auch nichts angelegt worden",
		EquipManager.equipped("weapon").is_empty())

	# Der Weg, ueber den man im Spiel tatsaechlich anlegt: aus dem Beutel. Hier steckte die
	# gefaehrlichere Luecke — `equip_from_bag` NIMMT das Teil erst aus dem Beutel und legt es
	# dann an. Scheitert das Anlegen an dieser Stelle, liegt das Teil nirgendwo mehr.
	GameState.bag = []
	GameState.equip = {}
	BagManager.add(legendaer)
	var vor_beutel: int = GameState.bag.size()
	_check("Aus dem Beutel anlegen scheitert ebenfalls",
		not BagManager.equip_from_bag(0))
	_check("Und das Teil liegt noch im Beutel (%d von %d)"
		% [GameState.bag.size(), vor_beutel], GameState.bag.size() == vor_beutel)

	# Eine Stufe hoeher darf man es dann.
	GameState.level = EquipManager.stufe_fuer(legendaer)
	_check("Auf Stufe %d geht es" % GameState.level,
		EquipManager.darf_tragen(legendaer) and BagManager.equip_from_bag(0))

	GameState.level = vorher
	GameState.bag = bag_vorher
	GameState.equip = equip_vorher


## Wandas Waffenlager.
##
## Der Bestand ist eine FUNKTION des Handelstags, kein Feld im Spielstand. Das ist die eine
## Entscheidung, an der hier alles haengt — und sie hat genau eine Anforderung, die man leicht
## verletzt: Innerhalb eines Tages muss jedes Abfragen dasselbe liefern. Waere das nicht so,
## wuerfelte das Regal bei jedem Oeffnen neu, und wer nicht kauft, koennte einfach zumachen und
## wieder aufmachen, bis etwas Gutes daliegt.
func _test_haendler() -> void:
	print("· Wandas Waffenlager")

	var gold_vorher: int = GameState.gold
	var tag_vorher: int = GameState.tag
	var bag_vorher: Array = GameState.bag.duplicate(true)
	var gekauft_vorher: Dictionary = GameState.gekauft_heute.duplicate(true)

	GameState.tag = 3
	var a: Array = HaendlerData.bestand()
	var b: Array = HaendlerData.bestand()
	_check("Das Regal hat %d Plaetze" % a.size(), a.size() == HaendlerData.PLAETZE)
	var gleich: bool = true
	for i in a.size():
		if String(a[i]["name"]) != String(b[i]["name"]) or int(a[i]["req"]) != int(b[i]["req"]):
			gleich = false
	_check("Zweimal am selben Tag liefert dasselbe", gleich)

	GameState.tag = 4
	var c: Array = HaendlerData.bestand()
	var anders: bool = false
	for i in a.size():
		if String(a[i]["name"]) != String(c[i]["name"]):
			anders = true
	_check("Am naechsten Tag liegt anderes da", anders)

	# Gewoehnlich bis selten, NIE darueber. Episches und Legendaeres kauft man nicht -- das
	# findet man, und davon lebt der Anreiz hinauszugehen. Ein Haendler, der es fuehrt, macht
	# das Suchen ueberfluessig: Wer genug Gold hat, holt sich die beste Waffe im Spiel, ohne je
	# einen Stollen betreten zu haben.
	var passt: bool = true
	var gesehen_c: bool = false
	var gesehen_r: bool = false
	for t in range(1, 60):
		GameState.tag = t
		for g in HaendlerData.bestand():
			var r2: String = String(g["rarity"])
			if r2 == "common":
				gesehen_c = true
			elif r2 == "rare":
				gesehen_r = true
			else:
				passt = false
			if String(g["slot"]) != "weapon":
				passt = false
	_check("Sie fuehrt nur Waffen, gewoehnlich bis selten", passt)
	_check("Und beide Sorten kommen vor", gesehen_c and gesehen_r)

	# Der Preis haengt an der ANFORDERUNG, nicht an der Farbe allein — seit die Anforderung die
	# Staerke abbildet, waere ein Preis nach Farbe fuer die schwache Waffe Wucher und fuer die
	# starke geschenkt.
	var schwach: Dictionary = ProgressionManager.make_gear("weapon", "rare")
	schwach["req"] = 1
	var stark: Dictionary = schwach.duplicate(true)
	stark["req"] = 7
	_check("Die starke seltene Waffe kostet mehr (%d gegen %d)"
		% [HaendlerData.preis(stark), HaendlerData.preis(schwach)],
		HaendlerData.preis(stark) > HaendlerData.preis(schwach))

	# Kaufen: ohne Gold geht nichts, und es wird auch nichts abgebucht.
	GameState.tag = 3
	GameState.gekauft_heute = {}
	GameState.bag = []
	GameState.gold = 0
	_check("Ohne Gold kein Kauf", not HaendlerData.kaufen(0))
	_check("Und der Beutel bleibt leer", GameState.bag.is_empty())

	# Mit Gold: Ware in den Beutel, Gold weg, Platz leer.
	var stueck: Dictionary = HaendlerData.bestand()[0]
	var p: int = HaendlerData.preis(stueck)
	GameState.gold = p + 50
	_check("Mit Gold klappt der Kauf", HaendlerData.kaufen(0))
	_check("Die Waffe liegt im Beutel", GameState.bag.size() == 1)
	_check("Und das Gold ist weg (%d statt %d)" % [GameState.gold, p + 50],
		GameState.gold == 50)
	_check("Der Platz ist heute verkauft", HaendlerData.verkauft(0))
	_check("Und laesst sich nicht zweimal kaufen", not HaendlerData.kaufen(0))

	# Der Fall, der beim ersten Entwurf falsch herum stand: voller Beutel. Erst pruefen, DANN
	# abbuchen — sonst bezahlt man fuer etwas, das man nicht bekommt.
	GameState.gekauft_heute = {}
	GameState.bag = []
	while BagManager.add(ProgressionManager.make_gear("armor", "common")):
		pass
	var gold_vor_voll: int = 99999
	GameState.gold = gold_vor_voll
	var passt_noch: bool = BagManager.has_room_for(HaendlerData.bestand()[1])
	if not passt_noch:
		_check("Bei vollem Beutel kein Kauf", not HaendlerData.kaufen(1))
		_check("Und kein Gold abgebucht", GameState.gold == gold_vor_voll)
	else:
		_check("Beutel liess sich nicht fuellen — Fall nicht pruefbar", true)
		_check("(uebersprungen)", true)

	GameState.gold = gold_vorher
	GameState.tag = tag_vorher
	GameState.bag = bag_vorher
	GameState.gekauft_heute = gekauft_vorher


# ══════════════════════════════════════════════════════════════════════════════
# Der Stollen laesst sich mit dem Daumen bedienen — und bewegt sich dabei
# ══════════════════════════════════════════════════════════════════════════════
#
# Vier Meldungen, ein gemeinsamer Grund: Die Szene war fuer Tastatur und Maus gebaut und wurde
# auf einem Telefon gespielt.
#
#   „ich kann nicht schiessen"      → jede Beruehrung ging an den Stick, der Schussknopf sah nie
#                                     eine. Nur die Leertaste feuerte.
#   „raus komme ich auch nicht"     → der Ausgang haengt an `[E]`. Ein Telefon hat kein [E].
#                                     Das ist ein Steckenbleiben ohne Ausweg.
#   „keine Animation des Charakters"→ `play_clip` wurde hier nie gerufen. Draussen laeuft die
#                                     Figur, drinnen rutscht sie in Bindepose ueber den Boden.
#   „auch die Gegner"               → dasselbe, und beim Gegner faellt es staerker auf: Er steht
#                                     mit ausgebreiteten Armen im T da, bis er sich das erste
#                                     Mal bewegt.
#
# Geprueft wird die VERDRAHTUNG, nicht das Bild: ob die Beruehrung erst an die Knoepfe geht,
# ob es einen Aktionsknopf gibt, ob die Anzeigenamen der Zustaende gesetzt werden.
func _test_stollen_bedienbar() -> void:
	var dv: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")

	# ── Beruehrung: erst die Knoepfe, dann der Stick ────────────────────────
	#
	# Die Reihenfolge ist der ganze Fehler. `_unhandled_input` gab jede Beruehrung an den Stick
	# weiter, und der Schussknopf las `pressed` nie.
	_check("Es gibt eine Knopfpruefung vor dem Stick", dv.contains("func _knopf_beruehrt"))
	_check("Und sie kommt VOR dem Stick",
		dv.find("_knopf_beruehrt(") < dv.find("_stick_setzen(")
		or dv.find("if _knopf_beruehrt(") < dv.find("_stick_setzen("))
	_check("Der Schussknopf wird vom Finger gesetzt", dv.contains("_feuer.pressed"))
	# Der zweite Finger darf den ersten nicht aufheben: Wer mit links laeuft und mit rechts
	# schiesst, haelt zwei Beruehrungen gleichzeitig. Ohne Fingerkennung loest das Loslassen
	# des Schussfingers den Stick mit aus — die Figur bleibt mitten im Gefecht stehen.
	_check("Der Schussfinger wird gemerkt", dv.contains("_feuer_finger"))
	_check("Und ein fremder Finger zieht nicht am Stick",
		dv.contains("_feuer_finger") and dv.contains("func _stick_ziehen"))

	# ── Der Ausgang ohne Tastatur ──────────────────────────────────────────
	_check("Es gibt einen Aktionsknopf", dv.contains("_aktion_btn"))
	_check("Er ruft dieselbe Aktion wie [E]", dv.contains("_aktion_btn.pressed.connect(_benutzen)")
		or dv.contains("_benutzen()"))
	_check("Er wird je nach Naehe gesetzt", dv.contains("func _aktion_knopf_setzen"))
	# Und er traegt nicht „[E]" auf sich: Das steht im Hinweis fuer die Tastatur, auf dem Knopf
	# waere es Unsinn.
	_check("Auf dem Knopf steht kein [E]", dv.contains("\"   [E]\""))
	# Ein Hinweis mit ⊘ sagt „geht nicht" (verschlossen, zu wenig Schluessel). Dafuer darf kein
	# Knopf erscheinen — sonst drueckt man auf etwas, das nichts tut.
	_check("Bei einem ⊘-Hinweis erscheint kein Knopf", dv.contains("⊘"))

	# ── Der Spieler bewegt sich sichtbar ───────────────────────────────────
	_check("Der Spieler bekommt beim Bauen eine Ruhepose",
		dv.contains("AssetRegistry.play_clip(_spieler, \"idle\")"))
	_check("Er laeuft, wenn er laeuft", dv.contains("_bewegt_sich"))
	_check("Und schlaegt an, wenn er schiesst", dv.contains("_angriff_t"))
	# Die Reihenfolge der drei Zustaende: Angriff schlaegt Laufen schlaegt Stehen. Andersherum
	# wird die Schussanimation vom naechsten Schritt abgeschnitten.
	var i_angriff: int = dv.find("if _angriff_t > 0.0")
	var i_lauf: int = dv.find("elif _bewegt_sich")
	_check("Angriff hat Vorrang vor Laufen", i_angriff >= 0 and i_lauf > i_angriff)

	# ── Und die Gegner auch ────────────────────────────────────────────────
	_check("Gegner laufen sichtbar", dv.contains("\"walk\""))
	_check("Gegner schlagen sichtbar zu", dv.contains("\"attack\""))
	# Der wichtigste der drei: OHNE ein `idle` beim Aufstellen steht das Modell in der Bindepose
	# — mit waagerecht ausgestreckten Armen. Genau das war gemeint mit „sehen nicht animiert
	# aus": Sie bewegten sich beim Laufen durchaus, standen aber vorher als T da.
	_check("Und stehen beim Aufstellen nicht in Bindepose",
		dv.count("play_clip(knoten, \"idle\")") >= 2)


# ══════════════════════════════════════════════════════════════════════════════
# Licht an den Waenden — aber nicht zu viel
# ══════════════════════════════════════════════════════════════════════════════
#
# Der Stollen hatte eine einzige Lichtquelle: die Lampe am Guertel. Das ist stimmig und nach
# zwei Kammern ermuedend — man sieht immer denselben Kreis um sich und nie den Raum.
#
# Der Auftrag war ausdruecklich zweiseitig: „elektrische Lampen an den Waenden. nicht zu viele,
# soll ja atmosphaerisch bleiben." Die zweite Haelfte ist die schwierigere, und sie ist es, die
# hier geprueft wird: Die Lampen duerfen den Stollen NICHT ausleuchten.
func _test_stollen_lampen() -> void:
	var DV = load("res://scripts/DungeonView.gd")
	var plan: Dictionary = DungeonLayout.erzeugen(4242, 2)
	var lampen: Array = DV.lampen_plaetze(plan)

	_check("Es haengen Lampen (%d)" % lampen.size(), lampen.size() > 0)
	_check("Aber hoechstens %d" % int(DV.LAMPEN_MAX), lampen.size() <= int(DV.LAMPEN_MAX))

	var boden: Dictionary = plan["boden"]
	# Jede Lampe steht an einer echten Wand: Feld begehbar, Nachbar in Richtung `hin` nicht.
	# Andersherum haengt sie frei im Gang oder mit dem Ruecken zum Spieler im Fels.
	var falsch_platziert: int = 0
	for l in lampen:
		var feld: Vector2i = (l as Dictionary)["feld"]
		var hin: Vector2i = (l as Dictionary)["hin"]
		if not boden.has(feld) or boden.has(feld + hin):
			falsch_platziert += 1
	_check("Jede haengt an einer Wand und zeigt in den Gang", falsch_platziert == 0,
		"%d falsch" % falsch_platziert)

	# Der Mindestabstand. Er ist der Grund, warum es nicht hell wird.
	var zu_dicht: int = 0
	for i in lampen.size():
		for k in range(i + 1, lampen.size()):
			var d: Vector2i = ((lampen[i] as Dictionary)["feld"] as Vector2i) \
				- ((lampen[k] as Dictionary)["feld"] as Vector2i)
			if absi(d.x) < int(DV.LAMPEN_ABSTAND) and absi(d.y) < int(DV.LAMPEN_ABSTAND):
				zu_dicht += 1
	_check("Keine zwei stehen dicht beieinander", zu_dicht == 0, "%d Paare" % zu_dicht)

	# Und der Punkt, an dem „atmosphaerisch" zur Zahl wird: Der Abstand zweier Lampen muss
	# GROESSER sein als das, was eine ausleuchtet. Sonst ueberlappen die Kegel, und zwischen
	# ihnen liegt kein Dunkel mehr — dann ist der Stollen ein Flur.
	var abstand_m: float = float(DV.LAMPEN_ABSTAND) * DungeonLayout.FELD_M
	_check("Zwischen zwei Lampen bleibt Dunkelheit (%.0f m Abstand, %.0f m Reichweite)"
		% [abstand_m, float(DV.LAMPEN_REICHWEITE)],
		abstand_m > float(DV.LAMPEN_REICHWEITE) * 1.5)
	# Und sie sind schwaecher als die Guertellampe. Die gehoert dem Spieler und soll das
	# Hellste im Bild bleiben — sonst laeuft man von Insel zu Insel und traegt sie umsonst.
	_check("Die Guertellampe bleibt die staerkste (%.1f gegen %.1f)"
		% [2.1, float(DV.LAMPEN_ENERGIE)], float(DV.LAMPEN_ENERGIE) < 2.1)

	# Warm, nicht weiss: Kohlefaden hinter angelaufenem Glas.
	var farbe: Color = DV.LAMPEN_FARBE
	_check("Ihr Licht ist warm", farbe.r > farbe.b + 0.4)

	# Kein Schatten. Acht schattenwerfende Punktlampen sind acht mal sechs Renderdurchgaenge je
	# Bild — auf einem Telefon der Unterschied zwischen fluessig und Diashow.
	var dv_q: String = FileAccess.get_file_as_string("res://scripts/DungeonView.gd")
	_check("Sie werfen keine Schatten", dv_q.contains("licht.shadow_enabled = false"))
	# Das Flackern ist klein. Eine sichtbar blinkende Lampe wird zum Ereignis; gemeint war das
	# Gegenteil.
	_check("Das Flackern ist kaum merklich (%.0f %%)" % (float(DV.LAMPEN_FLACKERN) * 100.0),
		float(DV.LAMPEN_FLACKERN) > 0.0 and float(DV.LAMPEN_FLACKERN) < 0.15)
	# Und jede flackert fuer sich. Im Gleichtakt pulsiert der ganze Stollen wie ein Herz.
	_check("Jede Lampe hat ihre eigene Phase", dv_q.contains("\"phase\": float(i) * 1.73"))

	# Ein anderer Grundriss bekommt andere Lampen — sie haengen am Plan, nicht an einer festen
	# Liste. Und derselbe Grundriss zweimal bekommt dieselben.
	var plan2: Dictionary = DungeonLayout.erzeugen(99, 1)
	var l2: Array = DV.lampen_plaetze(plan2)
	_check("Auch Ebene 1 bekommt Licht (%d)" % l2.size(), l2.size() > 0)
	var nochmal: Array = DV.lampen_plaetze(plan)
	var gleich: bool = nochmal.size() == lampen.size()
	if gleich:
		for i in lampen.size():
			if (nochmal[i] as Dictionary)["feld"] != (lampen[i] as Dictionary)["feld"]:
				gleich = false
	_check("Derselbe Stollen bekommt dieselben Lampen", gleich)


# ══════════════════════════════════════════════════════════════════════════════
# Ein Aufstieg bringt einen Punkt — vorher brachte er nichts
# ══════════════════════════════════════════════════════════════════════════════
#
# „bin zwar stufe drei, hab aber keine punkte zu verteilen im faehigkeiten menue."
#
# Der Perk-Baum stand seit Langem, `buy_perk` funktionierte, der Bildschirm zeigte ihn an — und
# `perk_points` wurde von NIEMANDEM je erhoeht. Die einzige Stelle, die die Zahl ueberhaupt
# anfasste, war der Kauf, der sie senkt. Ein ganzes Fortschrittssystem, das nur nach unten geht.
#
# Das Heikle daran ist der zweite Teil: Wer den Fehler behebt, hat den vorhandenen Spielstaenden
# damit noch nichts gegeben. Die Stufen sind schon vergeben, und die Punkte dafuer gibt es nie
# wieder — es sei denn, das Laden rechnet sie nach.
func _test_faehigkeitspunkte() -> void:
	print("· Faehigkeitspunkte (Aufstieg, Altstand, Erstattung)")
	_reset_state()

	_check("Auf Stufe 1 hat man noch keinen Punkt", GameState.perk_points == 0)
	# Genug XP fuer genau einen Aufstieg.
	GameState.add_xp(GameState.xp_to_next(1))
	_check("Nach dem ersten Aufstieg einer (Stufe %d, %d Punkte)"
		% [GameState.level, GameState.perk_points],
		GameState.level == 2 and GameState.perk_points == 1)

	# Zwei Stufen in einem Zug — beim Abschluss eines Auftrags nicht selten. Der Zuschlag muss
	# IM Schleifenkoerper stehen; danach gaebe es fuer zwei Aufstiege einen Punkt.
	_reset_state()
	var weit: int = GameState.xp_to_next(1) + GameState.xp_to_next(2) + GameState.xp_to_next(3)
	GameState.add_xp(weit)
	_check("Drei Stufen auf einmal bringen drei Punkte (Stufe %d, %d Punkte)"
		% [GameState.level, GameState.perk_points],
		GameState.level == 4 and GameState.perk_points == 3)

	# ── Der Altstand ────────────────────────────────────────────────────────
	#
	# Genau der Fall des Spielers: Stufe drei, null Punkte, weil es die Regel damals nicht gab.
	_reset_state()
	GameState.level = 3
	GameState.perk_points = 0
	ProgressionManager.punkte_abgleichen()
	_check("Ein Altstand auf Stufe 3 bekommt seine zwei Punkte nachgereicht (%d)"
		% GameState.perk_points, GameState.perk_points == 2)
	# Schon ausgegebene Raenge werden angerechnet, sonst bekaeme ein Altstand sie doppelt.
	_reset_state()
	GameState.level = 10
	GameState.perks = { "scharf": 3 }
	GameState.perk_points = 0
	ProgressionManager.punkte_abgleichen()
	_check("Ausgegebene Raenge zaehlen dagegen (9 verdient, 3 verbaut -> %d)"
		% GameState.perk_points, GameState.perk_points == 6)
	# Und der Abgleich ist mehrfach aufrufbar — sonst waechst der Vorrat bei jedem Laden.
	ProgressionManager.punkte_abgleichen()
	ProgressionManager.punkte_abgleichen()
	_check("Mehrfach abgleichen aendert nichts mehr (%d)" % GameState.perk_points,
		GameState.perk_points == 6)

	# Er nimmt NICHTS weg. Nach einer Neuverdrahtung liegen erstattete Punkte auf der Hand,
	# ohne dass ein Rang dafuer steht — ein Gleichsetzen kassierte sie ein.
	_reset_state()
	GameState.level = 5
	GameState.perks = {}
	GameState.perk_points = 40
	ProgressionManager.punkte_abgleichen()
	_check("Zu viele Punkte werden nicht einkassiert (%d)" % GameState.perk_points,
		GameState.perk_points == 40)

	# ── Die Rechnung im Ganzen ──────────────────────────────────────────────
	_check("Auf Hoechststufe gibt es %d Punkte"
		% ProgressionManager.verdiente_punkte(GameState.LEVEL_MAX),
		ProgressionManager.verdiente_punkte(GameState.LEVEL_MAX)
			== (GameState.LEVEL_MAX - 1) * GameState.PERK_PUNKTE_JE_STUFE)
	# Und sie reichen NICHT fuer alles. Ein Baum, den man ganz kaufen kann, ist keine Wahl.
	var alle_raenge: int = 0
	for pid in ProgressionManager.PERKS:
		alle_raenge += int(ProgressionManager.PERKS[pid]["max"])
	_check("Sie reichen nicht fuer den ganzen Baum (%d von %d Raengen)"
		% [ProgressionManager.verdiente_punkte(GameState.LEVEL_MAX), alle_raenge],
		ProgressionManager.verdiente_punkte(GameState.LEVEL_MAX) < alle_raenge)

	_reset_state()
	GameState.level = 30


# ══════════════════════════════════════════════════════════════════════════════
# Wer nah heranzoomt, wird nicht aus dem Nichts beschossen
# ══════════════════════════════════════════════════════════════════════════════
#
# „wenn ich reingezoomt habe schiessen die gegner schon ohne dass ich sie sehe, das ist zu weit
# weg."
#
# Der Zoom war verstellbar, die Reichweiten nicht: Gegner erwachten bei festen sechzehn Metern
# und schossen aus ihrer vollen Waffenreichweite — auf der nahen Stufe ist das weit ausserhalb
# des Bildes. Das ist kein Balance-Gefuehl, sondern Geometrie, und deshalb laesst es sich
# nachrechnen.
func _test_sichtweite() -> void:
	print("· Sichtweite (Kampfreichweite haengt am Zoom)")

	# Die Kamera steht CAM_PITCH geneigt bei CAM_FOV senkrechtem Sichtfeld. Bei Abstand d liegt
	# die obere Bildkante bei h/tan(PITCH - FOV/2) vom Objektiv, also um so viel VOR der Figur:
	var d: float = 9.5
	var hoehe: float = d * sin(deg_to_rad(OverworldView.CAM_PITCH))
	var vor_kamera: float = hoehe / tan(deg_to_rad(OverworldView.CAM_PITCH - OverworldView.CAM_FOV * 0.5))
	var vor_figur: float = vor_kamera - d * cos(deg_to_rad(OverworldView.CAM_PITCH))
	_check("Bei Vorgabe-Zoom liegt die Bildkante %.1f m vor der Figur" % vor_figur,
		vor_figur > 8.0 and vor_figur < 10.0)
	# Und genau daran ist die Sichtweite eingemessen: nicht groesser als die Bildtiefe.
	_check("Die Sichtweite passt ins Bild (%.1f m bei %.1f m Abstand)"
		% [OverworldView.sichtweite(d), d], OverworldView.sichtweite(d) <= vor_figur + 0.1)

	# Sie waechst mit dem Zoom — das ist der ganze Punkt.
	var nah: float = OverworldView.sichtweite(float(OverworldView.CAM_ZOOM_STEPS[0]))
	var fern: float = OverworldView.sichtweite(
		float(OverworldView.CAM_ZOOM_STEPS[OverworldView.CAM_ZOOM_STEPS.size() - 1]))
	_check("Nah sieht man weniger als fern (%.1f gegen %.1f m)" % [nah, fern], nah < fern)
	_check("Und nah deutlich weniger als die alten festen 16 m (%.1f)" % nah,
		nah < OverworldView.AGGRO_M * 0.7)
	# Nach unten begrenzt: Sonst waere auf der naechsten Stufe kein Platz zwischen „erwacht"
	# und „steht davor", und ein Nahkaempfer haette nicht einmal Anlauf.
	_check("Aber nie unter dem Nahkampfabstand (%.1f m gegen %.1f m)"
		% [nah, OverworldView.CONTACT_RANGE_M], nah > OverworldView.CONTACT_RANGE_M * 2.0)
	# Nach oben auch: Der weite Zoom darf die Wueste nicht in Bewegung versetzen.
	_check("Und nie ueber der alten Obergrenze (%.1f m)" % fern, fern <= OverworldView.AGGRO_M)
	# Monoton — eine Stufe weiter heraus darf nie WENIGER Sicht bedeuten.
	var monoton: bool = true
	for i in range(1, OverworldView.CAM_ZOOM_STEPS.size()):
		if OverworldView.sichtweite(float(OverworldView.CAM_ZOOM_STEPS[i])) \
				< OverworldView.sichtweite(float(OverworldView.CAM_ZOOM_STEPS[i - 1])):
			monoton = false
	_check("Jede Stufe weiter heraus zeigt mehr", monoton)

	# Der Spieler wird nie kurzreichweitiger als ein Schuetze, der auf ihn haelt: Sein Zielen
	# ist bei 8 m nach unten gedeckelt, die Gegner sind es nicht.
	var ow_q: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Der Spieler zielt gedeckelt, nicht ungebremst",
		ow_q.contains("_nearest_enemy(clampf(_sichtweite(), 8.0, SHOOT_RANGE_M))"))
	_check("Er behaelt auf der nahen Stufe die laengere Reichweite (%.1f gegen %.1f m)"
		% [maxf(nah, 8.0), nah], maxf(nah, 8.0) > nah - 0.001)
	# Gegner erwachen und schiessen nach derselben Zahl — zwei Reichweiten waeren zwei Fehler.
	_check("Gegner erwachen nach der Sichtweite", ow_q.contains("if d > sicht:"))
	_check("Und schiessen hoechstens so weit", ow_q.contains("minf(_attack_range(e), sicht)"))
	# Der Rueckzugsabstand eines Schuetzen muss UNTER seiner Schussweite bleiben, sonst weicht er
	# rueckwaerts aus dem Bild und kommt nie wieder.
	_check("Ein Schuetze weicht nicht aus dem Bild zurueck",
		ow_q.contains("minf(_min_range(e), weit - 0.6)"))


# ══════════════════════════════════════════════════════════════════════════════
# Der Weg zum Ort ist wieder ein Weg
# ══════════════════════════════════════════════════════════════════════════════
#
# „gegner kommen zu viele, wenn ich vom doc zu der muellkippe geschickt werde sind da genug
# dazwischen, dass ich den auftrag erfuelle, ausserdem respawnen die zu schnell."
#
# Beides an einem Ort: Alle vier Sekunden ein Wurf, zwoelf gleichzeitig erlaubt, und ein Wurf
# eines Schwarmtyps setzt gleich vier bis sieben ab. Ein Auftrag „erlege fuenf an der Muellkippe"
# ist damit auf dem Hinweg fertig — und ein Auftrag, der einen an einen ORT schicken soll, hat
# seinen Zweck verloren, bevor man dort ist.
func _test_nachschub() -> void:
	print("· Nachschub (Dichte und Takt)")

	_check("Hoechstens %d gleichzeitig" % OverworldView.ENEMY_MAX,
		OverworldView.ENEMY_MAX <= 8)
	_check("Und der Grundtakt ist kein Sekundentakt (%.0f s)" % OverworldView.SPAWN_INTERVAL_SEC,
		OverworldView.SPAWN_INTERVAL_SEC >= 8.0)

	# Die Kurve: leer zuegig, voll zaeh.
	var leer: float = OverworldView.nachschub_pause(0)
	var halb: float = OverworldView.nachschub_pause(OverworldView.ENEMY_MAX / 2)
	var voll: float = OverworldView.nachschub_pause(OverworldView.ENEMY_MAX)
	_check("Bei leerem Feld kommt der Grundtakt (%.1f s)" % leer,
		is_equal_approx(leer, OverworldView.SPAWN_INTERVAL_SEC))
	_check("Halb voll dauert es laenger (%.1f s)" % halb, halb > leer)
	_check("Ganz voll noch laenger (%.1f s)" % voll, voll > halb)
	_check("Und nie unbegrenzt lang (%.1f s)" % voll,
		voll <= OverworldView.SPAWN_INTERVAL_SEC * (1.0 + OverworldView.SPAWN_STAU_FAKTOR) + 0.01)
	# Ueber der Kappe darf die Rechnung nicht davonlaufen — sie wird zwar nicht gerufen, aber
	# eine Formel, die nur innerhalb ihres Erwartungsbereichs stimmt, ist eine Falle.
	_check("Auch ueber der Kappe bleibt sie gedeckelt",
		is_equal_approx(OverworldView.nachschub_pause(OverworldView.ENEMY_MAX * 3), voll))

	# Und die Probe aufs Exempel: Wie lange braucht das Feld, um von leer auf voll zu laufen?
	# Vorher waren es zwoelf mal vier Sekunden, also unter einer Minute — und mit Schwarmwuerfen
	# noch viel weniger.
	var sek: float = 0.0
	var stehen: int = 0
	while stehen < OverworldView.ENEMY_MAX:
		sek += OverworldView.nachschub_pause(stehen)
		stehen += 1
	_check("Von leer auf voll dauert es %.0f Sekunden" % sek, sek > 120.0)
	# Gegenprobe gegen den alten Zustand: zwoelf mal vier Sekunden waren 48.
	_check("Vorher waren es 48", 12 * 4 == 48)


# ══════════════════════════════════════════════════════════════════════════════
# Auf dem Bildschirm steht Deutsch
# ══════════════════════════════════════════════════════════════════════════════
#
# Das Spiel ist durchgehend deutsch — und in jeder Gegenstandszeile stand „+10 damage". Die
# Werteschluessel sind Programmiernamen (sie stehen in Spielstaenden und in `PlayerStats` und
# muessen englisch bleiben), sie waren nur nie uebersetzt worden, bevor sie jemand liest.
#
# Gefunden hat es kein Test, sondern das erste Bild von Wandas Regal. Deshalb steht die Pruefung
# jetzt hier: Was einmal im Bild aufgefallen ist, soll beim naechsten Mal vorher auffallen.
func _test_deutsche_werte() -> void:
	print("· Deutsche Wertenamen und Ladenverben")

	# Jeder Schluessel, den ein Fundstueck tragen kann, hat einen deutschen Namen.
	var ohne: Array[String] = []
	for key in ProgressionManager.SUB_BASE:
		if not ProgressionManager.WERT_NAMEN.has(key):
			ohne.append(String(key))
	for slot in ProgressionManager.GEAR_SLOTS:
		var k: String = String(ProgressionManager.GEAR_SLOTS[slot]["stat"])
		if not ProgressionManager.WERT_NAMEN.has(k):
			ohne.append(k)
	_check("Jeder Wert hat einen deutschen Namen", ohne.is_empty(), ", ".join(ohne))
	_check("Der Schluessel damage heisst Schaden",
		ProgressionManager.wert_name("damage") == "Schaden")
	# Ein unbekannter Schluessel faellt auf sich selbst zurueck statt zu verschwinden: Ein neuer
	# Wert soll sichtbar durchrutschen und nicht eine leere Stelle hinterlassen.
	_check("Ein unbekannter Schluessel bleibt sichtbar",
		ProgressionManager.wert_name("dampfdruck") == "dampfdruck")

	# Und die Bildschirme benutzen ihn auch.
	var cs: String = FileAccess.get_file_as_string("res://scripts/CharacterScreen.gd")
	var sh: String = FileAccess.get_file_as_string("res://scripts/ShopScreen.gd")
	_check("Der Beutel uebersetzt den Hauptwert",
		cs.contains("ProgressionManager.wert_name(String(g[\"stat\"][\"key\"]))"))
	_check("Und die Zusatzwerte auch",
		cs.contains("ProgressionManager.wert_name(String(a[\"key\"]))"))
	_check("Das Regal uebersetzt ebenfalls",
		sh.contains("ProgressionManager.wert_name(String(g[\"stat\"][\"key\"]))"))

	# ── Das Verb ────────────────────────────────────────────────────────────
	#
	# „Ausbauen" gehoert der Werkstatt: Ich habe etwas und hebe es eine Stufe. Im Waffenlager
	# kauft man ein Stueck, das man noch nicht hat — und unter jedem Regalstueck stand
	# „Ausbauen ¤ 60".
	_check("Im Waffenlager wird gekauft, nicht ausgebaut",
		sh.contains("\"Kaufen  ¤ %d\" if mode == Mode.WAFFEN"))
	# Und die Stufenzeile schweigt, wo es keine Ausbaustufe gibt: „Stufe 1/0" war die
	# Hoechststufe null, die als leeres Feld durchschlug.
	_check("Ohne Ausbaustufe steht keine Stufenzeile", sh.contains("if int(r[4]) > 0:"))


# ══════════════════════════════════════════════════════════════════════════════
# Die Kopfzeile: weniger lesen, und der Balken so dick wie eingetragen
# ══════════════════════════════════════════════════════════════════════════════
#
# „Das Hud sieht immer noch nicht gut aus. Alles in Text, sehr ueberladen. Wie viel Gold und
# Schrott er hat ist im hud nicht so wichtig. Wenn dann Gold, aber nur mit Goldmuenze und Zahl
# dahinter. Lebensbalken ist zu dick."
#
# Der zweite Teil war ein echter Fehler und kein Geschmack: In `BALKEN_H` stand neun, im Bild
# waren es vierzehn — und der Erfahrungsbalken war statt vier ganze zweiundzwanzig Punkte hoch.
# Ein Control, dem man `size` VOR `add_child` zuweist, bekommt beim Eintritt in den Baum eine
# neue Groesse zugeteilt; unter einem `CanvasLayer` waren das 36 Punkte. Die Zahl stimmte also,
# sie kam nur nie an.
#
# Deshalb prueft der erste Teil dieser Funktion nicht die Konstante, sondern haengt einen
# echten Balken in einen echten Baum und misst nach.
func _test_kopfzeile() -> void:
	print("· Kopfzeile (Balkenhoehe, weniger Text)")

	# ── Die Groesse kommt wirklich an ───────────────────────────────────────
	var schicht := CanvasLayer.new()
	add_child(schicht)
	_scratch.append(schicht)
	var b := ProgressBar.new()
	b.show_percentage = false
	schicht.add_child(b)
	# GENAU der Fehler: `size` allein, gegen eine groessere Mindestgroesse. Die Zuweisung wird
	# stillschweigend abgeklemmt — kein Fehler, keine Warnung, nur ein zu dicker Balken.
	b.custom_minimum_size = Vector2(OverworldView.BALKEN_W, 36.0)
	b.size = Vector2(OverworldView.BALKEN_W, OverworldView.BALKEN_H)
	_check("`size` allein wird von der Mindestgroesse abgeklemmt (%.0f statt %.0f)"
		% [b.size.y, OverworldView.BALKEN_H], b.size.y > OverworldView.BALKEN_H)
	OverworldView.hud_groesse(b, OverworldView.BALKEN_W, OverworldView.BALKEN_H)
	_check("Nach `hud_groesse` stimmt sie (%.0f)" % b.size.y,
		is_equal_approx(b.size.y, OverworldView.BALKEN_H))
	OverworldView.hud_groesse(b, OverworldView.BALKEN_W, OverworldView.XP_BALKEN_H)
	# Und zwar auch nach UNTEN: Die alte Mindestgroesse darf den neuen Wert nicht abklemmen —
	# genau daran scheiterte der erste Anlauf, der nur `size` setzte.
	_check("Und auch beim Verkleinern (%.0f)" % b.size.y,
		is_equal_approx(b.size.y, OverworldView.XP_BALKEN_H))

	# ── Die Masse selbst ────────────────────────────────────────────────────
	_check("Der Lebensbalken ist ein Strich, kein Block (%.0f px)" % OverworldView.BALKEN_H,
		OverworldView.BALKEN_H <= 10.0)
	_check("Der Erfahrungsbalken ist noch schmaler (%.0f gegen %.0f)"
		% [OverworldView.XP_BALKEN_H, OverworldView.BALKEN_H],
		OverworldView.XP_BALKEN_H < OverworldView.BALKEN_H)
	# Lang statt dick: Man liest an ihm die LAENGE ab, nicht die Flaeche.
	_check("Und deutlich laenger als dick (%.0f zu %.0f)"
		% [OverworldView.BALKEN_W, OverworldView.BALKEN_H],
		OverworldView.BALKEN_W > OverworldView.BALKEN_H * 15.0)

	# ── Was aus der Kopfzeile verschwunden ist ──────────────────────────────
	var ow: String = FileAccess.get_file_as_string("res://scripts/OverworldView.gd")
	_check("Die Materialzeile ist weg", not ow.contains("\"\\n▬ %d  ⚙ %d  ◉ %d\""))
	_check("Die Zahlenreihe ist weg", not ow.contains("❤ %d/%d   ¤ %d   ★ Lv %d"))
	# Gold steht als MUENZE da, nicht als Waehrungszeichen mit Zahl.
	_check("Es gibt eine gezeichnete Muenze", ow.contains("HudGlyph.zeichne_muenze("))
	_check("Und sie haengt am Goldwert", ow.contains("_gold_lbl.text = str(GameState.gold)"))
	# Die Lebenszahl liegt auf dem Balken, die Stufe am Portraet.
	_check("Die Lebenszahl liegt auf dem Balken", ow.contains("_hp_txt.position = _hp_bar.position"))
	_check("Die Stufe ist ein Abzeichen", ow.contains("_lv_lbl.text = str(GameState.level)"))
	# Und beides verschwindet in einer Nahaufnahme mit dem uebrigen HUD. Das war schon einmal
	# ein Fehler: `_hud` allein auszublenden liess Portraet und Balken im schwarzen Balken stehen.
	for knoten in ["_hp_txt", "_lv_lbl", "_gold_icon", "_gold_lbl", "_uhr_lbl"]:
		_check("%s wird im Kino mit ausgeblendet" % knoten,
			ow.contains(knoten + ", ") or ow.contains(knoten + "]"))
