extends Node
## Die Durchlauf-Probe: Startet das Spiel wirklich und läuft es durch.
##
## ## Warum es das gibt
##
## Der einzige richtig schlimme Fehler dieses Projekts war ein eingefrorener Bildschirm — keine
## Bewegung, kein HUD, schwarz. Die Testsuite war dabei **grün**, und schlimmer: Der Test hatte
## den Fehler sogar festgenagelt, weil er den kaputten Quelltext Zeichen für Zeichen abfragte.
##
## Kein Einzeltest kann das finden. Er prüft Regeln, Formeln und Tabellen — aber nicht, **ob
## sich die Figur bewegt, wenn man drückt**. Genau das macht diese Probe: Sie lädt die echten
## Szenen, lässt Bilder laufen, drückt und sieht nach, ob sich etwas rührt.
##
## Sie ersetzt die Suite nicht, sie beantwortet eine andere Frage. Die Suite fragt „stimmen die
## Zahlen", diese Probe fragt „läuft das Ding".
##
## ## Was sie durchgeht
##
## 1. Oberwelt starten — wird sie überhaupt steuerbar? (Das ist der Einfrier-Fall.)
## 2. Laufen — bewegt sich die Figur, wenn man den Stick auslenkt?
## 3. In den Stollen — lädt die zweite Szene?
## 4. Drinnen laufen, die Treppe nehmen, Ebene 2 erreichen.
## 5. Wieder heraus — steht die Figur am Stollenmund und nicht am Weltstart?
## 6. Der Auftragskreis — annehmen, erfüllen, abgeben, Belohnung. Für JEDEN Auftrag des
##    ersten Kapitels, nicht nur den einen, den ich gerade gebaut habe.
##
## ## Warum die Probe sich zur Seite stellt
##
## Sie hängt sich an die **Wurzel** und macht die geladene Spielszene zur `current_scene`. Das
## ist kein Kniff, sondern nötig: `change_scene_to_file()` — der Weg, den der Stollenknopf im
## Spiel wirklich geht — löscht die aktuelle Szene. Beim ersten Anlauf war das die Probe selbst.
## Sie hat sich mitten im Durchgang abgeräumt, und alles danach lief gegen ein `null`, weil es
## den Baum nicht mehr gab.
##
## So herum geht sie denselben Weg wie das Spiel, statt ihn nachzubauen — und ein Übergang, der
## nur in der Probe funktioniert, wäre keiner.
##
## Aufruf: `godot --headless --path godot res://tools/Durchlauf.tscn`
## Rückgabe: 0 = alles gut, 1 = irgendwo hängt es.

## Wie viele Bilder eine Etappe höchstens brauchen darf, bevor wir sie als hängend melden.
## 900 Bilder sind bei 60 Hz eine Viertelminute — großzügig für einen Ladevorgang und trotzdem
## endlich. Ohne Deckel würde eine hängende Szene die Probe selbst zum Hängen bringen, und dann
## meldet niemand etwas.
const FRIST: int = 900
## Wie weit die Figur sich rühren muss, damit „sie bewegt sich" gilt.
const WEG_M: float = 1.5

var _bestanden: int = 0
var _fehler: Array[String] = []


func _ready() -> void:
	print("──────────────────────────────────────────────")
	print("  Rust & Lead — Durchlauf-Probe")
	print("──────────────────────────────────────────────")
	# Ein Bild warten, BEVOR etwas an die Wurzel gehängt wird: Während `_ready()` richtet die
	# Wurzel ihre eigenen Kinder noch ein und weist jedes weitere ab („Parent node is busy
	# setting up children"). Die Szene wurde dadurch nie geladen, und die Probe meldete, die
	# Oberwelt baue keine Figur — dabei gab es gar keine Oberwelt.
	await get_tree().process_frame
	_lauf()


func _pruef(was: String, ok: bool, info: String = "") -> bool:
	if ok:
		_bestanden += 1
		print("  [OK]   %s" % was)
	else:
		_fehler.append(was)
		print("  [FEHL] %s%s" % [was, ("  -> " + info) if info != "" else ""])
	return ok


func _lauf() -> void:
	# Von vorn, aber ohne Prolog: Der Vorspann ist eine eigene Frage (die die Suite stellt), und
	# hier geht es darum, ob das SPIEL läuft.
	GameState.neu_beginnen()
	GameState.saw_wake = true
	GameState.prolog_done = true

	# ── 1. Die Oberwelt ──────────────────────────────────────────────────────
	var ow: Node3D = _szene_laden("res://scenes/Overworld.tscn")
	await _bilder(30)
	var spieler: Node3D = ow.get("_player")
	if not _pruef("Die Oberwelt baut eine Figur", spieler != null):
		return _ende()
	# DER Einfrier-Fall: Wird sie steuerbar? `_overlay_open()` und der Vorspann blockieren die
	# Bewegung — wenn einer davon nie endet, ist das Spiel tot, und genau so ist es einmal
	# ausgeliefert worden.
	var frei: bool = false
	for _i in FRIST:
		await _bilder(1)
		if not ow.call("_overlay_open") and not ow.call("_in_cine"):
			frei = true
			break
	if not _pruef("Sie wird steuerbar (kein Einfrieren)", frei,
			"nach %d Bildern immer noch gesperrt" % FRIST):
		return _ende()

	# ── 2. Laufen ────────────────────────────────────────────────────────────
	var vorher: Vector3 = spieler.position
	ow.set("_touch_vec", Vector2(0.0, -1.0))
	await _bilder(90)
	var weg: float = spieler.position.distance_to(vorher)
	_pruef("Sie läuft, wenn man drückt (%.1f m)" % weg, weg >= WEG_M,
			"nur %.2f m in 90 Bildern" % weg)
	ow.set("_touch_vec", Vector2.ZERO)

	# ── 3. In den Stollen ────────────────────────────────────────────────────
	# Ueber dieselbe Funktion, die der Knopf im Spiel aufruft — nicht ueber nachgebaute Zeilen.
	# Ein Uebergang, der nur im Test funktioniert, ist keiner.
	ow.call("_stollen_betreten")
	_pruef("Der Stollenmund merkt sich den Rückweg",
		GameState.stollen_rueckkehr != Vector3.ZERO)
	_pruef("Und schaltet auf Ebene 1", GameState.stollen_ebene == 1)
	# Der Wechsel ist AUFGESCHOBEN — er läuft am Bildende. Wer sofort nachsieht, findet noch
	# die alte Szene und hält den Übergang für kaputt.
	await _bilder(30)
	var dv: Node3D = get_tree().current_scene as Node3D
	if not _pruef("Der Stollen wird geladen", dv != null and dv.name != "Overworld",
			"aktuelle Szene: %s" % ("null" if dv == null else dv.name)):
		return _ende()
	var held: Node3D = dv.get("_spieler")
	if not _pruef("Der Stollen baut eine Figur", held != null):
		return _ende()
	var plan: Dictionary = dv.get("_plan")
	_pruef("Und einen Grundriss mit Kammern", (plan.get("raeume", []) as Array).size() >= 3)

	# ── 4. Drinnen laufen und die Treppe nehmen ──────────────────────────────
	# Gelaufen wird ueber den echten Stick, nicht ueber ein direktes Setzen der Position: Sonst
	# prueft die Probe, ob Godot Vektoren addieren kann.
	var stick: VirtualStick = dv.get("_stick")
	var d_vorher: Vector3 = held.position
	if stick != null:
		stick.active = true
		stick.origin = Vector2(200.0, 400.0)
		stick.knob = Vector2(200.0, 400.0 - stick.radius)
	await _bilder(90)
	var d_weg: float = held.position.distance_to(d_vorher)
	_pruef("Drinnen läuft sie auch (%.1f m)" % d_weg, d_weg >= WEG_M,
			"nur %.2f m" % d_weg)
	if stick != null:
		stick.active = false
	# Und die Wand haelt: Ein Stollen, durch dessen Fels man laeuft, ist ein Feld mit Deko.
	_pruef("Und steht dabei auf begehbarem Grund",
		DungeonLayout.begehbar(plan, DungeonLayout.szene_zu_feld(held.position)))

	# An die Treppe stellen und benutzen — dieselbe Funktion wie die Taste [E].
	held.position = dv.get("_treppe_pos")
	dv.call("_benutzen")
	_pruef("Die Treppe führt auf Ebene 2", GameState.stollen_ebene == 2)
	await _bilder(30)
	var dv2: Node3D = get_tree().current_scene as Node3D
	if not _pruef("Ebene 2 wird geladen", dv2 != null):
		return _ende()
	_pruef("Ebene 2 baut sich auf", (dv2.get("_plan") as Dictionary).has("boden"))
	# Dort steht der Endgegner — und der traegt den dritten Schluessel.
	var endgegner: bool = false
	for e in (dv2.get("_gegner") as Array):
		if (e["target"] as CombatTarget).is_elite:
			endgegner = true
	_pruef("Auf Ebene 2 steht der Endgegner", endgegner)

	# ── 5. Wieder heraus ─────────────────────────────────────────────────────
	var mund: Vector3 = GameState.stollen_rueckkehr
	(dv2.get("_spieler") as Node3D).position = dv2.get("_treppe_pos")
	dv2.call("_benutzen")
	_pruef("Von Ebene 2 geht es wieder hinaus", GameState.stollen_ebene == 0)
	await _bilder(40)
	var ow2: Node3D = get_tree().current_scene as Node3D
	var raus: Node3D = null if ow2 == null else ow2.get("_player") as Node3D
	if _pruef("Die Oberwelt lädt wieder", raus != null):
		# Und zwar AM STOLLENMUND. Ohne das stünde man nach jedem Ausflug am Weltstart, also
		# unter Umständen quer über der Karte.
		var d: float = raus.position.distance_to(mund)
		_pruef("Und setzt einen am Stollenmund ab (%.1f m)" % d, d < 6.0,
				"%.0f m daneben" % d)

	# ── 6. Der Auftragskreis ─────────────────────────────────────────────────
	_auftraege_pruefen()
	_ende()


## Jeden Auftrag des ersten Kapitels einmal ganz durchspielen.
##
## Ein Auftrag, den man nicht abschliessen kann, ist derselbe stille Fehler wie ein Feld, das
## nicht gespeichert wird: kein Absturz, keine Meldung, nur ein Spieler, der irgendwann aufgibt.
## Die Suite prueft die Quest-TABELLE; hier laeuft die Kette wirklich ab — annehmen, die
## Bedingung erfuellen, abgeben, und nachsehen, ob Gold und Belohnung ankommen.
func _auftraege_pruefen() -> void:
	var kapitel1: Array[String] = []
	for id in QuestManager.QUESTS:
		if int(QuestManager.QUESTS[id].get("chapter", 1)) == 1:
			kapitel1.append(String(id))
	_pruef("Kapitel 1 hat Auftraege (%d)" % kapitel1.size(), kapitel1.size() >= 3)

	var haengen: Array[String] = []
	var ohne_lohn: Array[String] = []
	for id in kapitel1:
		var def: Dictionary = QuestManager.QUESTS[id]
		# Jeder Auftrag einzeln, auf blankem Zustand: Sonst traegt ein frueherer die Bedingung
		# des naechsten schon mit, und ein kaputter faellt nicht auf.
		GameState.neu_beginnen()
		GameState.current_chapter = 1
		if not QuestManager.accept_quest(id):
			haengen.append(id + " (nicht annehmbar)")
			continue
		# Die Bedingung erfuellen — auf dem Weg, den auch das Spiel geht.
		match String(def.get("kind", "")):
			"kill":
				GameState.kills = int(GameState.quest_base.get(id, 0)) + int(def["count"])
			"collect":
				GameState.add_item(String(def["item"]), int(def["count"]))
			_:
				pass
		if not QuestManager.is_quest_complete(id):
			haengen.append("%s (%s %d nicht erfuellbar)" % [id, String(def.get("kind", "?")),
				int(def.get("count", 0))])
			continue
		var gold_vorher: int = GameState.gold
		if not QuestManager.complete_quest(id):
			haengen.append(id + " (nicht abgebbar)")
			continue
		if GameState.gold <= gold_vorher:
			ohne_lohn.append(id)
		# WIEDERHOLBARE Auftraege gehen auf „verfuegbar" zurueck, nicht auf „erledigt" — der
		# Auftraggeber bietet sie beim naechsten Gespraech erneut an. Ohne diese Unterscheidung
		# meldete die Probe drei Fehler, die keine waren: Sie hatte pauschal „erledigt"
		# erwartet und damit eine Entscheidung des Spiels fuer einen Defekt gehalten.
		var wiederholbar: bool = bool(def.get("repeatable", false))
		var soll: String = "available" if wiederholbar else "done"
		if QuestManager.get_quest_state(id) != soll:
			haengen.append("%s (%s statt %s)" % [id, QuestManager.get_quest_state(id), soll])
		# Und was wiederholbar heisst, muss auch stimmen: Er muss sich WIEDER annehmen lassen,
		# und der Fortschritt muss dabei bei null anfangen — sonst stuende er sofort auf voll.
		if wiederholbar:
			if not QuestManager.accept_quest(id):
				haengen.append(id + " (nicht wieder annehmbar)")
			elif QuestManager.is_quest_complete(id):
				haengen.append(id + " (steht sofort wieder auf voll)")
	_pruef("Jeder Auftrag aus Kapitel 1 laesst sich ganz durchspielen", haengen.is_empty(),
		", ".join(haengen))
	_pruef("Und jeder zahlt auch etwas aus", ohne_lohn.is_empty(), ", ".join(ohne_lohn))

	# Und Silas' Stollen-Auftrag im Besonderen: Er ist der einzige, dessen Material man
	# NIRGENDWO SONST bekommt — also der einzige, bei dem ein Fehler bedeutet, dass jemand
	# umsonst hinabsteigt.
	GameState.neu_beginnen()
	GameState.current_chapter = 1
	QuestManager.accept_quest("q_stollen")
	var noetig: int = int(QuestManager.QUESTS["q_stollen"]["count"])
	GameState.add_item("grubenstahl", noetig - 1)
	_pruef("Mit einem Stueck zu wenig bleibt der Stollen-Auftrag offen",
		not QuestManager.is_quest_complete("q_stollen"))
	GameState.add_item("grubenstahl", 1)
	_pruef("Mit dem letzten Stueck ist er erfuellt",
		QuestManager.is_quest_complete("q_stollen"))
	var vorher_gold: int = GameState.gold
	QuestManager.complete_quest("q_stollen")
	_pruef("Und die Abgabe zahlt (%d Gold)" % (GameState.gold - vorher_gold),
		GameState.gold - vorher_gold >= 100)
	GameState.neu_beginnen()


## Eine Spielszene laden und sie zur AKTUELLEN machen.
##
## Das Zweite ist der Punkt: Nur so löscht ein späteres `change_scene_to_file()` die Spielszene
## und nicht die Probe.
func _szene_laden(pfad: String) -> Node3D:
	var n: Node3D = load(pfad).instantiate()
	get_tree().root.add_child(n)
	get_tree().current_scene = n
	return n


func _bilder(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _ende() -> void:
	print("──────────────────────────────────────────────")
	print("  Ergebnis: %d bestanden, %d fehlgeschlagen" % [_bestanden, _fehler.size()])
	print("──────────────────────────────────────────────")
	get_tree().quit(0 if _fehler.is_empty() else 1)
