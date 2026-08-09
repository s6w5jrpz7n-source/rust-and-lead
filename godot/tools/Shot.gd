extends Node
## Bildschirmfotos der laufenden Welt — das Werkzeug fuer "sieht falsch aus".
##
## Zweimal hat das Rechnen an Formeln hier in die Irre gefuehrt (die Piste ueber dem Krater,
## der Ring dunkler Flecken am Kraterrand). Beide Male hat erst ein echtes Bild gezeigt, was
## los war. Deshalb steht das hier im Projekt statt in einem Wegwerf-Ordner.
##
## Aufruf (braucht eine X-Attrappe, headless rendert nichts):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --path godot res://tools/Shot.tscn
## Die Bilder landen unter `user://shot_*.png`.
##
## Zwei Fallen, beide teuer gelernt:
##  • **Fenstergroesse setzen.** `--resolution` wirkt hier nicht; ohne `get_window().size`
##    rendert Godot in 64x64, und jede gemessene Bildschirmposition ist Unsinn.
##  • **Eigene Kamera.** Die Spielkamera folgt der Blickrichtung der Figur, und die ist nach
##    einem Sprung an einen Ort beliebig. Die ersten Bilder zeigten leeren Sand, waehrend
##    Stadt und Bahnhof hinter der Kamera lagen.
const DayCycle = preload("res://scripts/DayCycle.gd")
const OUT: String = "user://shot"
var _views: Array = []
var _i: int = -1
var _wait: int = 0
var _cam: Camera3D
var _welt: Node          # die geladene Overworld — fuer die Oberflaechen-Bilder
var _buehne: Vector3


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_welt = load("res://scenes/Overworld.tscn").instantiate()
	add_child(_welt)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	add_child(_cam)
	var rw: Vector3 = WorldManager.poi_scene_position("rustwater")
	var dir: Vector3 = Vector3.ZERO
	for seg in WorldManager.rail_segments():
		if String(seg[0]) == "rustwater":
			dir = WorldManager.poi_scene_position(String(seg[1])) - rw
			break
		if String(seg[1]) == "rustwater":
			dir = WorldManager.poi_scene_position(String(seg[0])) - rw
			break
	dir = Vector3(dir.x, 0.0, dir.z).normalized()
	var side := Vector3(-dir.z, 0.0, dir.x)
	var platform: Vector3 = rw + dir * 68.0
	var halle: Vector3 = platform + side * 11.9
	var krater: Vector3 = WorldManager.poi_scene_position("schrott_minen")
	_views = [
		["bahnhof_front", halle - side * 26.0 + Vector3(0.0, 14.0, 0.0), halle],
		["bahnhof_schraeg", halle - side * 20.0 - dir * 24.0 + Vector3(0.0, 16.0, 0.0), halle],
		["krater_ueber", krater + Vector3(0.0, 26.0, 30.0), krater],
		["krater_rand", krater + Vector3(0.0, 3.0, 17.0), krater + Vector3(0.0, -3.0, 0.0)],
		["wueste", rw + Vector3(160.0, 22.0, 160.0), rw + Vector3(210.0, 0.0, 210.0)],
	]
	# Der Strahlensumpf: einmal von oben über ein Sumpfloch (liegt das Wasser wirklich IM Loch?),
	# einmal aus Spielerhöhe davor (sieht man den Wall, bevor man drinsteht?) und einmal weit
	# oben über der ganzen Zone.
	for f in WorldManager.TERRAIN:
		if not WorldManager.is_swamp_feature(f):
			continue
		var id: String = String(f["id"])
		# _1 liegt in der Salzpfanne, _7 ausserhalb. Zwei Bilder desselben Bauwerks unter
		# unterschiedlicher Biom-Toenung — nur so laesst sich trennen, ob ein Farbunterschied
		# vom Gelaende kommt oder von der Toenung darueber.
		if id != "sumpfloch_1" and id != "sumpfloch_7":
			continue
		var loch: Vector3 = WorldManager.feature_center(f)
		_views.append([id + "_ueber", loch + Vector3(0.0, 24.0, 28.0), loch])
		_views.append([id + "_flach", loch + Vector3(0.0, 3.4, 34.0),
			loch + Vector3(0.0, -1.0, 0.0)])
	var sumpf: Vector3 = WorldManager.world_to_scene(
		Vector2(float(WorldManager.SWAMP_CENTER_X), float(WorldManager.SWAMP_CENTER_Y)))
	_views.append(["sumpf_weit", sumpf + Vector3(0.0, 140.0, 210.0), sumpf])
	# Aus Spielerhoehe an der Bahnquerung: Dort stehen die Baeume am dichtesten.
	var quer: Vector3 = WorldManager.world_to_scene(Vector2(407.0, float(WorldManager.SWAMP_CENTER_Y)))
	_views.append(["sumpf_nah", quer + Vector3(26.0, 7.0, 26.0), quer + Vector3(0.0, 2.0, 0.0)])
	# Oberflaechen-Bilder. Ein Eintrag mit `null` als Position ist kein Kamerastandpunkt,
	# sondern ein Bildschirm — `_process` erkennt das am Typ und ruft `_setup_ui` auf.
	_views.append(["ui_charakter", null, "charakter"])
	_views.append(["quest_spur", null, "quest"])
	_views.append(["nahaufnahme", null, "nahaufnahme"])
	# Die Erstbegegnung, an drei Stellen: beide im Bild, der ZOOM auf das Ding, und der Schuss.
	# Der mittlere ist der, um den es geht — ob man den Gegner darauf wirklich ANSIEHT.
	# 0,85 und nicht 0,92: Der Schuss faellt bei 5,68 s von 6,4 s, und damit endet die Fahrt in
	# diesem Augenblick — `_erst_abdruecken` startet sofort die naechste. Alles jenseits von
	# 0,888 ist eine Kameraposition, die im Spiel NIE auf dem Schirm steht.
	# 0,28 und nicht 0,20 fuer die erste Etappe: Bis 1,8 s blendet sie noch von der Spielkamera
	# herueber, bei 0,20 (1,28 s) ist die Ueberblendung erst zu 61 % durch. Was man dort sieht,
	# ist eine Mischung aus zwei Einstellungen und keine von beiden.
	for anteil in ["0.28", "0.55", "0.85"]:
		_views.append(["erst_" + anteil, null, "erst_" + anteil])
	_views.append(["quest_umweg", null, "umweg"])
	_views.append(["ui_charakter2", null, "charakter"])   # jetzt mit Sinnbildern und Puppe
	# Das SPIEL-HUD selbst: Kopfzeile, Abzug, Trank-Trabant. Es gab lange kein Bild davon, und
	# genau deshalb ist niemandem aufgefallen, dass die halbe Kopfzeile aus leeren Kaestchen
	# bestand — die Schrift kannte kein einziges der Symbole. Was man nicht knipst, prueft man
	# nicht.
	_views.append(["ui_hud", null, "hud"])
	# Die beiden neuen Gegner: nebeneinander, aus Spielerhoehe.
	var buehne: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 60.0)
	_views.append(["gegner_neu", null, "gegner"])
	_views.append(["blickrichtung", null, "blick"])
	_views.append(["gegner_leiste", null, "leiste"])
	_views.append(["gegner_kampf", null, "kampf"])
	_views.append(["neuzugang", null, "neuzugang"])
	_views.append(["figuren", null, "figuren"])
	_views.append(["waffe", null, "waffe"])
	for uz in [["tageszeit_nacht", "uhr_1.5"], ["tageszeit_daemmerung", "uhr_5.9"],
			["tageszeit_tag", "uhr_12.5"], ["tageszeit_abend", "uhr_19.6"]]:
		_views.append([String(uz[0]), null, String(uz[1])])
	# Die Nachtbeleuchtung als GANZES. Einzelbilder vom Saloon sagen nichts darueber, ob die
	# Stadt nachts als Lichtbild funktioniert — ob Esse, Torfackeln und Turmlaterne zusammen
	# eine Silhouette ergeben oder ob einer davon alles ueberstrahlt. Also von oben, und dann
	# aus Augenhoehe auf die Schmiede.
	_views.append(["nacht_stadt", null, "nachtstadt"])
	_views.append(["nacht_schmiede", null, "nachtschmiede"])
	# Der Anflug auf Rustwater, an fuenf Stellen abgegriffen. Eine Kamerafahrt laesst sich
	# rechnerisch pruefen (der Test tut das), aber ob sie ein BILD ergibt, sieht man erst im
	# Bild — vor allem, ob der Turm bei der Umrundung im Rahmen bleibt.
	#
	# Der erste Wert ist 0,17 und nicht 0,0: Zu Beginn blendet die Fahrt noch von der
	# STANDKAMERA herueber, und die steht hier im Werkzeug woanders als im Spiel. 0,17 ist das
	# Ende der ersten Etappe — der reine Blickpunkt des Helden, ohne Beimischung.
	# Die letzten drei Werte liegen dicht beieinander, und das ist Absicht: Der Rueckflug, der
	# Blick auf Figur UND Ort, und das Einschwenken in die Spielperspektive machen zusammen nur
	# das letzte Drittel aus — genau der Teil, der zweimal falsch war.
	for anteil in ["0.10", "0.30", "0.55", "0.78", "0.88", "0.95"]:
		_views.append(["flug_" + anteil, null, "flug_" + anteil])
	# Das Erwachen in der Schrottgrube — der erste Augenblick des Spiels. Zwei Stellen: der
	# Blick von oben in die Grube und die Haltung, in der man dann spielt.
	for anteil in ["0.25", "0.50", "0.72", "0.95"]:
		_views.append(["wach_" + anteil, null, "wach_" + anteil])
	# Der Ausguck: die Anhoehe zwischen Grube und Stadt. Einmal von der Seite (steht die Klippe
	# wirklich steil?) und einmal von oben herab Richtung Rustwater — der Blick, auf den der
	# ganze Aufstieg hinauslaeuft.
	var berg: Vector3 = WorldManager.world_to_scene(Vector2(348.0, 214.0))
	berg.y = WorldManager.height_at(berg.x, berg.z)
	var zur_stadt: Vector3 = (rw - berg)
	zur_stadt.y = 0.0
	zur_stadt = zur_stadt.normalized()
	_views.append(["ausguck_seite", berg + zur_stadt * 78.0 + Vector3(0.0, 14.0, 0.0),
		berg + Vector3(0.0, 5.0, 0.0)])
	_views.append(["ausguck_oben", berg + Vector3(0.0, 3.0, 0.0) - zur_stadt * 8.0,
		rw + Vector3(0.0, 6.0, 0.0)])
	# Und der Ring an der Kante, aus der Richtung, aus der man ankommt — sowie senkrecht von
	# oben. Das zweite Bild klingt nach Luxus und ist es nicht: Aus der Spielerperspektive
	# laesst sich an einem flachen Ring auf schraegem Fels weder Groesse noch Rundheit ablesen.
	# Beim ersten Anlauf sah er von hinten aus wie ein aufrechter Bilderrahmen, und ohne den
	# Blick von oben waere unklar geblieben, ob das an der Form liegt oder an der Perspektive.
	_views.append(["titel", null, "titel"])
	_views.append(["ausguck_marke", null, "marke"])
	_views.append(["ausguck_marke_oben", null, "markeoben"])
	# Die Rundsicht oben auf dem Fels, an vier Stellen. Gleiche Bauweise wie `flug_`/`wach_`.
	for anteil in ["0.16", "0.42", "0.68", "0.90"]:
		_views.append(["vista_" + anteil, null, "vista_" + anteil])
	_buehne = buehne
	# Am Ziel selbst: Hier stand die Platzhalter-Saeule mitten im Weg.
	var ratten: Vector3 = WorldManager.poi_scene_position("rattengestruepp")
	_views.append(["ort_rattengestruepp", ratten + Vector3(0.0, 12.0, 26.0), ratten])
	# Rustwater von oben, und dasselbe Bild noch einmal mit eingezeichneten Sperren. Ein
	# Kollisionsfehler ist als ZAHL kaum zu erkennen und als Ueberlagerung sofort: Wo Rot ueber
	# Sand liegt statt ueber einem Dach, steht eine unsichtbare Wand.
	_views.append(["stadt_oben", rw + Vector3(0.0, 96.0, 58.0), rw])
	_views.append(["stadt_sperren", null, "sperren"])
	_views.append(["stadt_sperren_oben", rw + Vector3(0.0, 96.0, 58.0), rw])
	# Aus Spielerhoehe durch das Tor hinein — der Weg, den jeder Spieler zuerst nimmt.
	_views.append(["stadt_tor", rw + Vector3(2.0, 2.6, -34.0), rw + Vector3(0.0, 2.0, 0.0)])
	# Und von INNEN, aus Spielkamera-Abstand: So sieht man den Kupferboden, wie man ihn spielt.
	_views.append(["stadt_innen", rw + Vector3(6.0, 5.2, 12.0), rw + Vector3(-2.0, 0.6, -6.0)])
	_wait = 60
	# Ein einzelnes Bild statt aller: `godot … res://tools/Shot.tscn -- stadt`
	var filter: PackedStringArray = OS.get_cmdline_user_args()
	if filter.size() > 0:
		var muster: PackedStringArray = filter[0].split(",", false)
		var gewaehlt: Array = []
		for v in _views:
			for m in muster:
				if String(v[0]).begins_with(m):
					gewaehlt.append(v)
					break
		if not gewaehlt.is_empty():
			_views = gewaehlt


## Ausgangslage fuer ein Oberflaechen-Bild. Eine leere Puppe und ein leerer Beutel zeigen
## nichts von dem, worauf es ankommt — also erst Beute erzeugen, dann anlegen, dann knipsen.
## Liegt ein Bildpunkt im sichtbaren Rahmen?
func _im_bild(p: Vector2) -> bool:
	return p.x >= 0.0 and p.x <= 1280.0 and p.y >= 0.0 and p.y <= 720.0


func _setup_ui(art: String) -> void:
	var ow: OverworldView = _welt as OverworldView
	if ow == null:
		return
	if art == "charakter":
		GameState.bag = []
		GameState.equip = {}
		for slot in ["helmet", "armor", "weapon", "boots"]:
			EquipManager.equip_item(ProgressionManager.make_gear(String(slot), "rare"), String(slot))
		EquipManager.equip_item(ProgressionManager.make_gear("plate", "legendary"), "plate1")
		EquipManager.equip_item(ProgressionManager.make_gear("plate", "common"), "plate3")
		for s2 in ["weapon", "armor", "gadget", "helmet", "boots", "armor"]:
			BagManager.add(ProgressionManager.make_gear(String(s2), "epic"))
		ow._toggle_character(CharacterScreen.Tab.AUSRUESTUNG)
	elif art == "quest":
		# Auftrag annehmen, damit Marke und Fussspur ueberhaupt etwas zu zeigen haben, und die
		# Kamera hinter die Figur setzen — die Spur laeuft NACH VORN, von hinten sieht man sie.
		# Zumachen statt umschalten: Mit dem Filterargument kann diese Ansicht die ERSTE sein,
		# und dann oeffnete ein Umschalter den Charakterschirm, statt ihn zu schliessen.
		ow._close_character()
		QuestManager.accept_quest("q_rats")
		var wo: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 26.0)
		ow._player.position = Vector3(wo.x, WorldManager.height_at(wo.x, wo.z), wo.z)
		# Auf das WIRKLICHE Ziel ausrichten, nicht auf ein hier notiertes: Welcher Auftrag
		# verfolgt wird, entscheidet der QuestManager — und mit jedem neuen Auftrag im Kapitel
		# zeigte die Kamera sonst woandershin als die Spur.
		var ziel: Vector3 = ow._trail_goal()
		if ziel == Vector3.INF:
			ziel = WorldManager.poi_scene_position("schrott_minen")
		var dir: Vector3 = Vector3(ziel.x - ow._player.position.x, 0.0,
			ziel.z - ow._player.position.z).normalized()
		_cam.position = ow._player.position - dir * 12.0 + Vector3(0.0, 9.0, 0.0)
		_cam.look_at(ow._player.position + dir * 20.0, Vector3.UP)
		_cam.current = true
	elif art == "sperren":
		# Jede eingetragene Sperre als rote Platte AUF dem Bild (ohne Tiefentest, sonst
		# verschwindet sie unter dem Dach, das sie beschreibt). Deckt sich das Rot mit den
		# Gebaeuden, stimmt die Kollision; liegt es daneben, steht dort eine unsichtbare Wand.
		for b in ow._rot_blockers:
			var c: Vector2 = b["c"]
			var h: Vector2 = b["h"]
			var platte := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(h.x * 2.0, 0.3, h.y * 2.0)
			platte.mesh = box
			platte.position = Vector3(c.x, WorldManager.height_at(c.x, c.y) + 0.3, c.y)
			platte.rotation.y = float(b["yaw"])
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.95, 0.15, 0.12, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.no_depth_test = true
			platte.material_override = mat
			ow.add_child(platte)
	elif art == "blick":
		# Blickrichtungspruefung: alle Figuren UNGEDREHT nebeneinander, Kamera auf +Z.
		# Wer sein Gesicht zeigt, schaut nach +Z und braucht die 180°-Korrektur, denn Godot
		# laeuft nach −Z. Wer den Ruecken zeigt, sitzt richtig.
		ow._end_cine()
		ow._close_character()
		var b3: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 90.0)
		var reihe: Array = ["enemy_outlaw", "enemy_revolver", "enemy_fauna", "enemy_konstrukt",
			"player", "npc_mabel"]
		for j in reihe.size():
			var kind2: String = String(reihe[j])
			var n2: Node3D = AssetRegistry.instantiate(kind2, AssetRegistry.height_of(kind2))
			if n2 == null:
				continue
			ow.add_child(n2)
			n2.position = b3 + Vector3(float(j) * 2.2 - 5.5, 0.0, 0.0)
			# MIT der eingetragenen Korrektur: Wer jetzt den Ruecken zeigt, laeuft richtig
			# herum. (Zum Nachmessen eines NEUEN Modells hier die Drehung der Kinder auf 0
			# setzen — dann sieht man den rohen Zustand.)
			ow._label(n2.position + Vector3(0.0, 2.4, 0.0), kind2, Color(1, 1, 0.5), 60, 90.0)
		_cam.position = b3 + Vector3(0.0, 1.7, 7.0)
		_cam.look_at(b3 + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "gegner":
		ow._end_cine()
		ow._close_character()
		var i2: int = 0
		for kind in ["enemy_outlaw", "enemy_revolver"]:
			var n: Node3D = AssetRegistry.instantiate(kind, AssetRegistry.height_of(kind))
			if n == null:
				continue
			ow.add_child(n)
			n.position = _buehne + Vector3(float(i2) * 1.6 - 0.8, 0.0, 0.0)
			n.rotation.y = PI
			AssetRegistry.play_clip(n, "idle")
			i2 += 1
		_cam.position = _buehne + Vector3(0.0, 1.5, 4.2)
		_cam.look_at(_buehne + Vector3(0.0, 0.9, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "hud":
		# Das HUD zeigt nur etwas, wenn es auch etwas zu zeigen GIBT: ohne Waffe keine
		# Munitionsanzeige, ohne Traenke ein ausgegrauter Trabant, ohne Auftrag keine
		# Auftragszeile. Also erst den Zustand herstellen, in dem man tatsaechlich spielt.
		ow._end_cine()
		ow._close_character()
		GameState.gold = 340
		GameState.potions = 3
		GameState.level = 4
		GameState.add_item("schrott", 12)
		GameState.add_item("zahnrad", 5)
		GameState.add_item("dampfkern", 2)
		for slot in ["helmet", "armor", "boots", "weapon"]:
			EquipManager.equip_item(ProgressionManager.make_gear(String(slot), "rare"), String(slot))
		QuestManager.accept_quest("q_rats")
		# Die gefuehrte Waffe haengt an der angelegten Ausruestung, sie wird nicht gesetzt.
		ow._sync_weapon()
		# Angeschlagen, sonst ist der Trankknopf ausgegraut — und ausgerechnet den soll das
		# Bild ja beurteilen.
		ow._hp = float(PlayerStats.max_hp()) * 0.45
		ow._update_hud()
		var hw: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 40.0)
		ow._player.position = Vector3(hw.x, WorldManager.height_at(hw.x, hw.z), hw.z)
		_cam.position = ow._player.position + Vector3(0.0, 9.0, 12.0)
		_cam.look_at(ow._player.position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "leiste":
		# Echte Gegner aus `_make_enemy`, nicht nur Modelle: Nur so ist die Lebensleiste dabei.
		# Zwei Zustaende nebeneinander — unverletzt und halb tot —, damit man sieht, ob der
		# Restanteil ueberhaupt schrumpft.
		ow._end_cine()
		ow._close_character()
		var i3: int = 0
		for anteil in [1.0, 0.45]:
			var e: Dictionary = ow._make_enemy("outlaw" if i3 == 0 else "revolver")
			var n2: Node3D = e["node"]
			ow.add_child(n2)
			n2.position = _buehne + Vector3(float(i3) * 1.8 - 0.9, 0.0, 0.0)
			n2.rotation.y = PI
			(e["bar"] as MeshInstance3D).scale.x = anteil
			i3 += 1
		_cam.position = _buehne + Vector3(0.0, 1.9, 3.4)
		_cam.look_at(_buehne + Vector3(0.0, 1.5, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "neuzugang" or art == "figuren":
		# Alle frisch gelieferten Modelle nebeneinander, in Einbaugroesse, auf einer Reihe.
		# Ein Modell, das man nur als Datei kennt, kauft man blind ein — das hier ist die
		# Abnahme: Groesse, Lage, Farbe, und ob es ueberhaupt so herum steht wie gedacht.
		ow._end_cine()
		ow._close_character()
		var reihe: Array = ["locomotive", "shelf", "desk", "office_chair", "oil_barrel",
			"barbed_wire", "medallion", "monolith", "copper_plate_a", "copper_plate_b",
			"figur_ohne_namen", "figur_mit_animationen"]
		if art == "figuren":
			reihe = ["figur_ohne_namen", "figur_mit_animationen"]
		var x: float = 0.0
		for kind2 in reihe:
			var name2: String = String(kind2)
			if not AssetRegistry.has_model(name2):
				continue
			var n4: Node3D = AssetRegistry.instantiate(name2)
			if n4 == null:
				continue
			ow.add_child(n4)
			var b4: AABB = AssetRegistry.local_bounds(n4)
			var breite: float = maxf(b4.size.x * n4.scale.x, 0.5)
			x += breite * 0.5 + 1.2
			n4.position = _buehne + Vector3(x, WorldManager.height_at(_buehne.x, _buehne.z), 0.0)
			x += breite * 0.5
			ow._label(n4.position + Vector3(0.0, 4.6, 0.0), name2,
				Color(1.0, 0.92, 0.7), OverworldView.LBL_HAUS, 300.0)
		_cam.position = _buehne + Vector3(x * 0.5, x * 0.28, x * 0.62)
		_cam.look_at(_buehne + Vector3(x * 0.5, 1.4, 0.0), Vector3.UP)
		if art == "figuren":
			# Naeher heran und auf Brusthoehe: Wer die Figuren erkennen soll, braucht Gesicht
			# und Kleidung, nicht die Silhouette am Horizont.
			_cam.position = _buehne + Vector3(x * 0.5, 1.5, 4.2)
			_cam.look_at(_buehne + Vector3(x * 0.5, 1.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art.begins_with("uhr_"):
		# Dieselbe Einstellung zu vier Tageszeiten. Nur so sieht man, ob die Beleuchtung eine
		# Kurve ist oder eine Treppe — und ob die Nacht dunkel genug ist, dass ein
		# Muendungsfeuer ueberhaupt etwas beleuchtet.
		ow._end_cine()
		ow._close_character()
		GameState.hour = float(art.get_slice("_", 1).to_float())
		ow._apply_daytime()
		ow._apply_night_lights()
		var rw2: Vector3 = WorldManager.poi_scene_position("rustwater")
		ow._player.position = Vector3(rw2.x + 4.0, WorldManager.height_at(rw2.x + 4.0, rw2.z + 6.0),
			rw2.z + 6.0)
		ow._muzzle_flash(30.0)
		# Auf den Saloon: Er hat immer offen und soll den Platz davor beleuchten. Vom
		# Stadtplatz aus schraeg darauf, damit Fassade UND Vorplatz im Bild sind.
		_cam.position = rw2 + Vector3(6.0, 5.0, 17.0)
		_cam.look_at(rw2 + Vector3(-11.0, 2.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "marke":
		# Der leuchtende Ring an der Vorderkante des Felsens — die Stelle, in die man treten
		# muss, damit die Rundsicht anspringt. Zweimal hat diese Fahrt zu frueh gestartet, weil
		# der Ausloeser eine RECHNUNG war (erst waagerechter Abstand zur Kuppe, dann Abstand
		# plus Hoehe) und der Spieler die Rechnung nicht sehen konnte. Ein Ring, auf den die
		# Fussspur zulaeuft, macht die Bedingung sichtbar: Man steht drin oder man steht nicht
		# drin.
		#
		# Die Kamera steht dahinter und schaut ueber den Ring hinweg nach Rustwater — genau die
		# Blickrichtung, aus der man ankommt. Damit beantwortet das Bild beides: Liegt der Ring
		# wirklich VORN an der Kante, und sieht man von dort die Stadt?
		ow.set_process(true)
		ow._end_flight()
		ow._end_cine()
		ow._close_character()
		GameState.hour = DayCycle.START_HOUR
		GameState.prolog_done = false
		GameState.saw_vista = false
		ow._apply_daytime()
		ow._apply_night_lights()
		# Den Ring NACHTRÄGLICH bauen. `_build_vista_marke()` laeuft beim Aufbau der Welt und
		# steigt aus, wenn der Prolog schon vorbei ist — und beim Start dieses Werkzeugs ist er
		# das. Die Flaggen oben kommen zu spaet, also hier noch einmal anstossen; sonst zeigt
		# ausgerechnet das Bild, das den Ring pruefen soll, keinen.
		if ow._marke == null:
			ow._build_vista_marke()
		var ring: Vector3 = ow._vista_spot()
		# Aus der Richtung, aus der man ANKOMMT — und die ist seit dem Umzug des Rings auf die
		# rechte Kuppe nicht mehr die Rustwater-Achse, sondern der Weg von der Felsmitte herueber.
		# Mit der alten Achse stand die Figur einen Hang tiefer und der Ring schwebte ueber ihr.
		var fmitte: Vector3 = WorldManager.feature_center(ow._feature("ausguck"))
		var hin: Vector3 = Vector3(ring.x - fmitte.x, 0.0, ring.z - fmitte.z).normalized()
		# Die Figur einen Schritt VOR dem Ring — so, wie sie ankommt, noch nicht ausgeloest.
		var steh: Vector3 = ring - hin * 3.4
		steh.y = WorldManager.height_at(steh.x, steh.z)
		ow._player.position = steh
		ow._player.rotation.y = atan2(-hin.x, -hin.z)
		_cam.position = steh - hin * 7.0 + Vector3(0.0, 4.4, 0.0)
		_cam.look_at(ring + Vector3(0.0, 0.6, 0.0), Vector3.UP)
		_cam.current = true
		# Die Zahlen mit ins Protokoll. Als der Ring einmal unsichtbar war, sah das Bild wie ein
		# Platzierungsfehler aus — die Ausgabe zeigte einen korrekt gesetzten Knoten 35 cm ueber
		# einem Boden auf 14,71 m, und damit war klar, dass es an der FORM lag und nicht am Ort.
		print("· Ring bei %.1f m ueber Boden %.1f m, Knoten: %s" % [ring.y,
			WorldManager.height_at(ring.x, ring.z),
			"da" if ow._marke != null else "FEHLT"])
		if ow._marke != null:
			var pl: Node3D = ow._marke.get_node("Puls")
			var mi: MeshInstance3D = pl.get_child(0) as MeshInstance3D
			print("· Reif-AABB pos=%s groesse=%s" % [mi.get_aabb().position, mi.get_aabb().size])
	elif art == "titel":
		# Der Titelbildschirm. Er laedt seine eigene Welt — also wird hier die des Werkzeugs
		# beiseitegeschoben und die echte Titelszene davorgesetzt. Alles andere waere ein
		# Nachbau, und ein Nachbau prueft sich selbst statt des Bildes, das der Spieler sieht.
		# Die Overworld des Werkzeugs wird WEGGEWORFEN, nicht versteckt.
		#
		# Erst stand hier `visible = false` plus `_set_hud_hidden(true)`, und im Bild lagen
		# trotzdem Lebensbalken, Kleinkarte und Schussknopf ueber dem Titel: Die Oberflaeche
		# haengt in eigenen `CanvasLayer`n, die weder an der Sichtbarkeit des Node3D noch an
		# jener einen Umschaltung haengen. Im Spiel gibt es das Problem nicht — dort laedt der
		# Titel die Welt gar nicht mehr. Ein Pruefbild, das etwas zeigt, was es im Spiel nicht
		# gibt, prueft aber nichts.
		ow.queue_free()
		_welt = null
		var titel: Node = load("res://scenes/Title.tscn").instantiate()
		add_child(titel)
		_wait = 20
	elif art == "markeoben":
		# Senkrecht von oben auf den Ring: Nur so sieht man, ob er RUND ist und wie gross.
		ow.set_process(true)
		ow._end_flight()
		ow._end_cine()
		ow._close_character()
		GameState.hour = DayCycle.START_HOUR
		GameState.prolog_done = false
		GameState.saw_vista = false
		ow._apply_daytime()
		ow._apply_night_lights()
		if ow._marke == null:
			ow._build_vista_marke()
		var ro: Vector3 = ow._vista_spot()
		ow._player.position = ro - Vector3(0.0, 0.0, 6.0)
		_cam.position = ro + Vector3(0.0, 12.0, 0.01)
		_cam.look_at(ro, Vector3.UP)
		_cam.fov = 55.0
		_cam.current = true
	elif art.begins_with("vista_"):
		# Oben auf dem Fels. Der Aufstieg wird uebersprungen — die Figur wird auf das Plateau
		# gesetzt, dann laeuft dieselbe Pruefung wie im Spiel.
		ow.set_process(true)
		ow._end_flight()
		ow._end_cine()
		ow._close_character()
		GameState.hour = DayCycle.START_HOUR
		GameState.prolog_done = false
		GameState.saw_vista = false
		ow._apply_daytime()
		ow._apply_night_lights()
		var rwv: Vector3 = WorldManager.poi_scene_position("rustwater")
		var felsm: Vector3 = WorldManager.world_to_scene(Vector2(348.0, 214.0))
		felsm.y = WorldManager.height_at(felsm.x, felsm.z)
		ow._player.position = felsm
		ow._player.rotation.y = atan2(-(rwv.x - felsm.x), -(rwv.z - felsm.z))
		ow._cam.position = felsm + ow._cam_offset(ow._cam_dist)
		ow._cam.look_at(felsm + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		ow._maybe_vista()
		ow._flight_t = ow._flight_total() * float(art.get_slice("_", 1).to_float())
		ow.set_process(false)
		var vf: Array = ow._flight_frame()
		_cam.position = vf[0]
		if vf[0].distance_to(vf[1]) > 0.05:
			_cam.look_at(vf[1], Vector3.UP)
		_cam.fov = float(vf[2])
		_cam.current = true
	elif art.begins_with("wach_"):
		# Der Anfang: die Figur liegt am Grund der Grube und steht auf, waehrend die Kamera von
		# oben herunterkommt. Derselbe Aufbau wie bei den Flug-Bildern (siehe dort, warum die
		# Welt dabei angehalten wird).
		ow.set_process(true)
		ow._end_flight()
		ow._end_cine()
		ow._close_character()
		# Die ECHTE Anfangszeit, nicht Mitternacht: Der Prolog beginnt im Abendrot, und wie hell
		# die Grube dabei ist, ist genau die Frage, die dieses Bild beantworten soll.
		GameState.hour = DayCycle.START_HOUR
		GameState.prolog_done = false
		# LEERE HAENDE — das ist der Zustand, in dem der Prolog anfaengt, und der Zustand, in
		# dem `_update_hud` schon einmal abgestuerzt ist (`AmmoData.pool_for("")`). Wird er hier
		# nicht hergestellt, prueft dieses Bild ihn auch nicht.
		GameState.weapons = []
		GameState.equip.erase("weapon")
		ow._weapon_id = ""
		ow._sync_weapon()
		ow._apply_daytime()
		ow._apply_night_lights()
		var grube: Vector3 = ow._start_spawn()
		ow._player.position = grube
		ow._cam.position = grube + ow._cam_offset(ow._cam_dist)
		ow._cam.look_at(grube + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		ow._erwachen()
		var anteil: float = float(art.get_slice("_", 1).to_float())
		ow._flight_t = ow._flight_total() * anteil
		# Die Animation an dieselbe Stelle stellen und die Pose ANWENDEN. Ohne das steht das
		# Skelett in der Ruhepose — und weil die Kamera dem Kopfknochen folgt, zielte sie auf
		# den Kopf eines Stehenden, waehrend die Figur am Boden lag.
		var ap: AnimationPlayer = AssetRegistry.animation_player(ow._player_model)
		if ap != null:
			var laenge: float = ap.current_animation_length
			ap.speed_scale = 1.0
			ap.seek(laenge * clampf(anteil / OverworldView.WACH_STEH_ANTEIL, 0.0, 1.0), true)
			ap.advance(0.0)
			# Und ANHALTEN. `set_process(false)` friert die Overworld ein, den AnimationPlayer
			# aber nicht — er hat seinen eigenen Takt. Ohne dies stand die Figur beim Abgreifen
			# sechzig Bilder spaeter auf, waehrend die Kamera noch auf den liegenden Kopf zielte:
			# Das Bild zeigte einen Rumpf, obwohl die Rechnung den Kopf punktgenau in der
			# Bildmitte hatte.
			ap.pause()
		ow.set_process(false)
		var wf: Array = ow._flight_frame()
		_cam.position = wf[0]
		if wf[0].distance_to(wf[1]) > 0.05:
			_cam.look_at(wf[1], Vector3.UP)
		_cam.current = true
		# Nachmessen statt beurteilen: Wo landet der Kopfknochen im Bild?
		var kopf: Vector3 = ow._kopf_welt()
		var fuss: Vector3 = ow._player.position
		print("MESSUNG %s  Kopf=%s  Fuss=%s  Kamera=%s  Ziel=%s"
			% [art, kopf, fuss, wf[0], wf[1]])
		if kopf.x < INF:
			print("   Kopf ueber Fuss: %.2f m   Bildpunkt: %s   (Mitte waere 640/360)"
				% [kopf.y - fuss.y, _cam.unproject_position(kopf)])
	elif art.begins_with("flug_"):
		# Der Anflug an einer bestimmten Stelle seiner Laufzeit. Die Fahrt wird echt ausgeloest
		# (nicht nachgebaut), dann die Uhr vorgestellt und das Bild abgegriffen — was hier steht,
		# ist genau das, was der Spieler sieht.
		# Aufraeumen, was das vorige Flug-Bild hinterlassen hat: Die Welt steht seit dem letzten
		# Aufruf still (siehe unten), die Fahrt ist also nie zu Ende gelaufen. Ohne das lehnt
		# `_maybe_intro_flight` den naechsten Anflug mit „laeuft schon" ab — und dann steht die
		# Kamera zwar richtig, aber die Bedienoberflaeche liegt wieder ueber dem Bild.
		ow.set_process(true)
		ow._end_flight()
		ow._end_cine()
		ow._close_character()
		GameState.hour = 1.5
		GameState.prolog_done = false
		GameState.saw_rustwater = false
		ow._apply_daytime()
		ow._apply_night_lights()
		var rwf: Vector3 = WorldManager.poi_scene_position("rustwater")
		# Knapp innerhalb der Sichtweite, damit die Fahrt beim naechsten Aufruf anspringt.
		var steh: Vector3 = rwf + Vector3(0.0, 0.0, OverworldView.INTRO_SIGHT_M - 4.0)
		ow._player.position = Vector3(steh.x, WorldManager.height_at(steh.x, steh.z), steh.z)
		ow._player.rotation.y = PI
		# Die SPIELKAMERA erst in ihre normale Haltung bringen. Sie folgt der Figur sonst noch
		# ueber mehrere Bilder hinweg — und der Anflug merkt sich beim Start genau diese Haltung
		# als das, wohin er zurueckkehrt. Ohne das endete die Fahrt dort, wo die Kamera beim
		# Laden zufaellig stand.
		ow._cam.position = ow._player.position + ow._cam_offset(ow._cam_dist)
		ow._cam.look_at(ow._player.position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		ow._maybe_intro_flight()
		ow._flight_t = ow._flight_total() * float(art.get_slice("_", 1).to_float())
		# Und die Welt anhalten. Sonst laeuft `_process` die verbleibenden Wartebilder weiter,
		# die Fahrt erreicht ihr Ende und raeumt Balken und Bedienoberflaeche wieder ein — das
		# Bild zeigte dann die richtige Kameraposition mit dem falschen Bildschirm darueber.
		ow.set_process(false)
		var ff: Array = ow._flight_frame()
		_cam.position = ff[0]
		if ff[0].distance_to(ff[1]) > 0.05:
			_cam.look_at(ff[1], Vector3.UP)
		_cam.current = true
		# WO im Bild die Figur und der Ort landen — als Zahl, nicht nach Augenmass.
		#
		# Die letzten Sekunden sollen "Figur im Vordergrund, Rustwater am Horizont" zeigen, und
		# das faellt nachts in einem Bild aus Silhouetten schlicht nicht zu erkennen: Auf dem
		# Sand stehen ausserdem Gegner, die genauso aussehen. Gemessen ist es eindeutig — 640/360
		# ist die Bildmitte, alles ausserhalb 0…1280 / 0…720 steht nicht im Bild.
		var s_fig: Vector2 = _cam.unproject_position(
			ow._player.position + Vector3(0.0, 1.0, 0.0))
		var s_ort: Vector2 = _cam.unproject_position(rwf + Vector3(0.0, 7.0, 0.0))
		print("· %s — Figur bei %.0f/%.0f%s, Rustwater bei %.0f/%.0f%s" % [art,
			s_fig.x, s_fig.y, "" if _im_bild(s_fig) else "  (AUSSERHALB)",
			s_ort.x, s_ort.y, "" if _im_bild(s_ort) else "  (AUSSERHALB)"])
	elif art == "nachtstadt" or art == "nachtschmiede":
		# Die Nachtbeleuchtung im Zusammenhang. Ein Bild vom Saloon allein beantwortet nicht die
		# Frage, die zaehlt: Ergibt die Stadt nachts eine LESBARE Silhouette — Torfackeln als
		# Eingang, Esse als Arbeitsplatz, Turmlaterne als Landmarke — oder ist es ein Haufen
		# oranger Flecken?
		ow._end_cine()
		ow._close_character()
		GameState.hour = 1.5
		ow._apply_daytime()
		ow._apply_night_lights()
		var rwn: Vector3 = WorldManager.poi_scene_position("rustwater")
		ow._player.position = Vector3(rwn.x, WorldManager.height_at(rwn.x, rwn.z), rwn.z)
		if art == "nachtstadt":
			_cam.position = rwn + Vector3(0.0, 74.0, 46.0)
			_cam.look_at(rwn, Vector3.UP)
		else:
			# Die Schmiede steht in `Rustwater.tscn` bei (16,9 | −7,0) im Ortsraum. Von der
			# Strasse aus darauf, aus Augenhoehe: So sieht man, ob der Schein aus der Oeffnung
			# faellt und den Boden davor traegt — oder ob das Haus nur innen gluetht.
			var schmiede: Vector3 = rwn + Vector3(16.9, 0.0, -7.0)
			var auge: Vector3 = schmiede + Vector3(-9.0, 4.0, 9.0)
			_cam.position = Vector3(auge.x, WorldManager.height_at(auge.x, auge.z) + 4.0, auge.z)
			_cam.look_at(schmiede + Vector3(0.0, 2.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "waffe":
		# Die Figur mit Waffe, gross im Bild — und mitten im Schuss. Zwei Fragen in einem Bild:
		# Liegt das Gewehr richtig in der Hand, und sitzt das Muendungsfeuer an der Muendung?
		ow._end_cine()
		ow._close_character()
		ow._enemies.clear()
		var mitte2: Vector3 = _buehne
		ow._player.position = Vector3(mitte2.x, WorldManager.height_at(mitte2.x, mitte2.z), mitte2.z)
		ow._player.rotation.y = 0.0
		EquipManager.equip_item(ProgressionManager.make_gear("weapon", "rare", "", null,
			"karabiner"), "weapon")
		ow._sync_weapon()
		# Von VORN: Die Figur schaut nach −Z, also steht die Kamera dort. Von hinten sah man
		# nur den Schaft in der Faust — das Gewehr zeigt ja vom Betrachter weg.
		_cam.position = ow._player.position + Vector3(1.15, 1.45, -2.4)
		_cam.look_at(ow._player.position + Vector3(0.0, 1.15, -0.6), Vector3.UP)
		_cam.current = true
	elif art == "kampf":
		# Ein Nahkaempfer im Schlag und ein Schuetze auf Schussdistanz — beide in dem Bild, in
		# dem der Treffer faellt. Nur so sieht man, ob die Animation zum Schaden passt.
		ow._end_cine()
		ow._close_character()
		ow._enemies.clear()
		var mitte: Vector3 = _buehne
		ow._player.position = Vector3(mitte.x, WorldManager.height_at(mitte.x, mitte.z), mitte.z)
		ow._hp = 500.0
		var stellen: Array = [["outlaw", Vector3(1.6, 0.0, 0.4)],
			["revolver", Vector3(-6.5, 0.0, 3.0)]]
		for eintrag in stellen:
			var e2: Dictionary = ow._make_enemy(String(eintrag[0]))
			var n3: Node3D = e2["node"]
			ow.add_child(n3)
			n3.position = ow._player.position + (eintrag[1] as Vector3)
			n3.position.y = WorldManager.height_at(n3.position.x, n3.position.z)
			ow._enemies.append(e2)
		# Bis kurz VOR den Treffer vorspulen: Dann steht die Angriffs-Animation im Bild.
		for _f in 12:
			ow._process_enemies(0.02)
		_cam.position = ow._player.position + Vector3(3.4, 2.2, 6.0)
		_cam.look_at(ow._player.position + Vector3(-1.0, 1.1, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "umweg":
		# Der Fall, der ohne Wegweisung toedlich endet: Die gerade Linie zum Zugdepot fuehrt
		# mitten durch den Strahlensumpf. Die Spur MUSS hier oestlich daran vorbeizeigen.
		ow._end_cine()
		GameState.quests = {}
		GameState.economy["laboratory"] = 0
		QuestManager.accept_quest("q_m3")
		var wo2: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 20.0)
		ow._player.position = Vector3(wo2.x, WorldManager.height_at(wo2.x, wo2.z), wo2.z)
		var ziel2: Vector3 = ow._trail_goal()
		var dir2: Vector3 = (ziel2 - ow._player.position).normalized()
		_cam.position = ow._player.position - dir2 * 14.0 + Vector3(0.0, 11.0, 0.0)
		_cam.look_at(ow._player.position + dir2 * 24.0, Vector3.UP)
		_cam.current = true
		print("UMWEG: Ziel der Spur bei %s (Welt %s)"
			% [ziel2, WorldManager.scene_to_world(ziel2)])
	elif art.begins_with("erst_"):
		# Die Szene ueber ihre eigene Funktion ausloesen und dann bis zum gewuenschten Anteil
		# der Gesamtdauer vorspulen — nicht die Kamerapunkte nachbauen. Ein Bild, das eine
		# nachgebaute Fahrt zeigt, beurteilt die falsche Fahrt.
		ow._end_cine()
		ow._close_character()
		GameState.prolog_done = false
		GameState.erst_gegner_done = false
		# Die Figur AN DIE STELLE setzen, an der die Szene im Spiel anspringt. Das erste Bild
		# zeigte Rustwater bei Nacht: Das vorige Bild hatte die Figur vor Mabel abgestellt, und
		# `_erst_starten` baut den Gegner immer VOR den Spieler — wo der gerade steht. Ein
		# Werkzeug, das den Zustand des Vorgaengers erbt, prueft die falsche Szene.
		var halde: Dictionary = ow._feature("schrotthalde")
		var kmitte: Vector3 = WorldManager.feature_center(halde)
		var raus: Vector3 = WorldManager.poi_scene_position("rustwater") - kmitte
		raus.y = 0.0
		raus = raus.normalized()
		var steh: Vector3 = kmitte + raus * (WorldManager.feature_reach(halde)
			+ OverworldView.ERST_AUSLOESER_M + 6.0)
		ow._player.position = Vector3(steh.x, WorldManager.height_at(steh.x, steh.z), steh.z)
		# Blickrichtung ist hier keine Kosmetik: Der Gegner erscheint seitlich VOR ihm, und
		# „vorn" liest `_erst_starten` aus der Drehung der Figur.
		ow._player.rotation.y = atan2(-raus.x, -raus.z)
		# Der Morgen nach dem Erwachen — dieselbe Uhrzeit wie im Spiel. Bei Nacht sieht man von
		# dem Ding im Zoom nichts als eine Silhouette, und genau das soll das Bild ja beurteilen.
		GameState.hour = DayCycle.START_HOUR
		ow._apply_daytime()
		ow._apply_night_lights()
		ow._enemies.clear()
		# Die SPIELKAMERA in ihre normale Haltung bringen, bevor die Fahrt startet. Sie ist der
		# Anfangspunkt: `_play_flight` merkt sie sich als `_flight_von` und blendet von dort
		# herueber. Im Werkzeug stand sie noch dort, wo das vorige Bild sie abgestellt hatte —
		# das erste Bild der Fahrt zeigte deshalb eine Ueberblendung aus einer Kameraposition,
		# die es im Spiel nicht gibt, und darauf war weder Held noch Gegner zu sehen.
		ow._cam.position = ow._player.position + ow._cam_offset(ow._cam_dist)
		ow._cam.look_at(ow._player.position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		ow._sync_weapon()
		if ow._weapon_id == "":
			EquipManager.equip_item(ProgressionManager.make_gear("weapon", "common", "",
				null, "karabiner"), "weapon")
			ow._sync_weapon()
		# Die Rede des VORIGEN Bildes wegraeumen. `_play_speech` haengt an, wenn derselbe
		# Sprecher noch redet — und der Held redet in allen drei Bildern. Ohne das hier stand
		# beim dritten Bild wieder der erste Satz auf der Tafel, weil die Warteschlange aus drei
		# Durchlaeufen uebereinander lag.
		ow._speech.clear()
		ow._erst_starten()
		# Dieselbe Mechanik wie bei den Anflug-Bildern: die Uhr der Fahrt vorstellen, das Bild
		# abgreifen, und die Welt dabei ANHALTEN. Lässt man sie weiterlaufen, erreicht die Fahrt
		# ihr Ende und räumt die Bedienoberfläche wieder ein — das Bild zeigte dann die richtige
		# Kameraposition mit dem falschen Bildschirm darüber.
		var bis: float = ow._flight_total() * float(art.substr(5))
		ow._flight_t = bis
		# Die REDE mitziehen. Sie hat ihre eigene Uhr, und die laeuft ueber `_process` — das
		# hier gleich stillsteht. Ohne diesen Vorlauf zeigt jedes der drei Bilder denselben
		# ersten Satz, und die Tafel behauptet etwas anderes als die Kamera.
		var rest: float = bis
		while rest > 0.0:
			var d: float = minf(0.05, rest)
			ow._process_speech(d)
			rest -= d
		ow.set_process(false)
		var ef: Array = ow._flight_frame()
		_cam.position = ef[0]
		if ef[0].distance_to(ef[1]) > 0.05:
			_cam.look_at(ef[1], Vector3.UP)
		# Auch den Bildwinkel uebernehmen — er IST hier die halbe Aussage: Der Zoom wirkt ueber
		# das 26°-Objektiv, nicht ueber die Position allein. Ein Bild mit 55° zeigte die richtige
		# Stelle und den falschen Eindruck.
		if ef.size() > 2:
			_cam.fov = float(ef[2])
		_cam.current = true
	elif art == "nahaufnahme":
		# Zur Auftraggeberin laufen und ansprechen — die Nahaufnahme startet dabei von selbst.
		# Danach uebernimmt die SPIELKAMERA; die Shot-Kamera muss also aus dem Weg.
		var mabel: Dictionary = {}
		for n in ow._npcs:
			if String(n["giver"]) == "mabel":
				mabel = n
		if mabel.is_empty():
			return
		ow._player.position = (mabel["pos"] as Vector3) + Vector3(2.2, 0.0, 1.6)
		ow._cam.current = true
		ow._talk_to("mabel")
		# Fuer das Bild verlaengert: Sonst haengt es vom Bildtakt des Rechners ab, ob die
		# Aufnahme beim Ausloesen noch laeuft. Die Fahrt nach innen ist davon unabhaengig.
		ow._play_closeup(mabel["node"] as Node3D, 999.0)
		# Die Drehung braucht ein paar Frames; das Bild wartet ohnehin.



func _process(_dt: float) -> void:
	if _wait > 0:
		_wait -= 1
		# Ein Muendungsfeuer lebt 55 ms. Ausgeloest werden muss es EIN Bild vor dem Knipsen:
		# `get_image()` liefert das zuletzt GERENDERTE Bild, im selben Aufruf ausgeloest waere
		# es also noch nicht drauf.
		if _wait == 1 and _i >= 0 and String(_views[_i][0]) == "waffe":
			# Im Bild lange genug: Der Blitz lebt im Spiel 55 ms, und headless rendert langsamer
			# als das. Sonst ist er beim Knipsen schon wieder weg — genau so ist das erste
			# Pruefbild entstanden, auf dem gar keiner zu sehen war.
			(_welt as OverworldView)._muzzle_flash(30.0)
		return
	if _i >= 0:
		if String(_views[_i][0]) == "quest_spur":
			var ow2: OverworldView = _welt as OverworldView
			var n: int = 0
			for t in ow2._trail:
				if (t as MeshInstance3D).visible:
					n += 1
			print("    Fussspur: %d von %d sichtbar" % [n, ow2._trail.size()])
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OUT, String(_views[_i][0])])
	_i += 1
	if _i >= _views.size():
		get_tree().quit()
		return
	if _views[_i][1] == null:
		_setup_ui(String(_views[_i][2]))
		# Laenger warten als bei einem Kamerastandpunkt: Eine Nahaufnahme FAEHRT heran, und ein
		# Bild nach zwoelf Bildern zeigt die Bewegung, nicht die Einstellung.
		_wait = 70
		return
	_cam.position = _views[_i][1]
	_cam.look_at(_views[_i][2], Vector3.UP)
	_cam.current = true
	_wait = 12
