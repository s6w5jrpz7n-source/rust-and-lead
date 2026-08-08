extends Node3D
## Der Stollen — die zweite Spielszene.
##
## `DungeonLayout` rechnet den Grundriss, hier wird er gebaut: Boden, Wände, Dunkelheit, eine
## Lampe am Gürtel, Kisten als Platzhalter, Treppe nach unten und der Weg zurück ans Tageslicht.
##
## ## Was hier absichtlich anders ist als draußen
##
## Draußen ist die Welt eine **Formel**: `WorldManager.height_at()` beantwortet für jeden Punkt,
## wie hoch der Boden liegt, und daraus fallen Gehen, Fußspuren und Streugut heraus. Drinnen
## gibt es keine Höhe — der Boden ist flach, und die einzige Frage ist **Feld oder Fels**.
## Deshalb prüft die Bewegung hier keine Steigung, sondern schlägt das Zielfeld nach.
##
## Das ist kein Notbehelf, sondern der Grund, warum ein Stollen sich anders anfühlt: Draußen
## kann man überall langlaufen und wird von Hängen gebremst; drinnen gibt es Wände, und eine
## Wand ist eine Entscheidung, kein Widerstand.
##
## ## Was noch fehlt
##
## Schritt 3 aus `docs/PLAN_DUNGEON.md`: Gegner und Beute. Die Plätze dafür rechnet der
## Grundriss bereits aus (`gegner`, `truhen`), hier stehen an ihnen bisher **Kisten**. Das ist
## die im Plan vorgesehene Reihenfolge — nach Schritt 2 kann man hineingehen und sich verlaufen,
## nach Schritt 3 ist es ein Kampf.

const SPIELER_TEMPO: float = 7.0
## Wie weit die Gürtellampe trägt. 9 m laut Plan — weit genug, um den Raum zu ahnen, zu kurz,
## um ihn zu überblicken.
const LAMPE_M: float = 9.0
## Wie nah man an Treppe oder Ausgang muss.
const NAH_M: float = 2.6
const WAND_H: float = 3.5
const DECKE_H: float = 3.6

var _plan: Dictionary = {}
var _spieler: Node3D
var _kamera: Camera3D
var _stick: VirtualStick
var _lampe: OmniLight3D
var _text: Label
var _hinweis: Label
var _treppe_pos: Vector3 = Vector3.ZERO
var _eingang_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Der Startwert bleibt, die Ebene zählt hoch. Wer die Treppe nimmt, soll in DEMSELBEN
	# Stollen eine Etage tiefer stehen und nicht in einem fremden.
	if GameState.stollen_startwert == 0:
		GameState.stollen_startwert = randi() % 100000 + 1
	if GameState.stollen_ebene <= 0:
		GameState.stollen_ebene = 1
	_plan = DungeonLayout.erzeugen(GameState.stollen_startwert, GameState.stollen_ebene)

	_umgebung_bauen()
	_boden_bauen()
	_waende_bauen()
	_kisten_bauen()
	_spieler_bauen()
	_oberflaeche_bauen()


## Dunkelheit ist die halbe Miete. Ein Stollen mit Tageslicht ist ein Zimmer.
func _umgebung_bauen() -> void:
	var welt := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.013, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Nicht ganz null: Bei absoluter Schwärze sieht man außerhalb des Lampenkegels NICHTS, und
	# ein Spieler, der die Wand nicht ahnt, läuft nicht vorsichtig, sondern ratlos.
	env.ambient_light_color = Color(0.18, 0.17, 0.22)
	env.ambient_light_energy = 0.14
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.045, 0.055)
	env.fog_density = 0.035
	welt.environment = env
	add_child(welt)


func _boden_bauen() -> void:
	# Ein einziges Netz für alle Bodenfelder statt eines Knotens je Feld: Bei ~300 Feldern wären
	# das 300 Knoten, die jeden Frame durch die Sichtbarkeitsprüfung müssen, für eine Fläche,
	# die sich nie bewegt.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = DungeonLayout.FELD_M * 0.5
	for f in (_plan["boden"] as Dictionary):
		var m: Vector3 = DungeonLayout.feld_zu_szene(f as Vector2i)
		for e in [[Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h)],
				[Vector3(-h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]]:
			for p in e:
				st.set_normal(Vector3.UP)
				st.add_vertex(m + p)
	st.index()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.17, 0.15)
	mat.roughness = 0.95
	mi.material_override = mat
	add_child(mi)


func _waende_bauen() -> void:
	# Nur die Grenzfelder — `DungeonLayout.waende()` liefert genau die. Das ganze Gestein zu
	# mauern hieße tausend Kästen, von denen niemand je einen sieht.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.12, 0.12)
	mat.roughness = 1.0
	var multi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(DungeonLayout.FELD_M, WAND_H, DungeonLayout.FELD_M)
	mm.mesh = box
	var felder: Array[Vector2i] = DungeonLayout.waende(_plan)
	mm.instance_count = felder.size()
	for i in felder.size():
		var m: Vector3 = DungeonLayout.feld_zu_szene(felder[i])
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, m + Vector3(0.0, WAND_H * 0.5, 0.0)))
	multi.multimesh = mm
	multi.material_override = mat
	add_child(multi)


## Kisten an den Plätzen, an denen später Truhen und Gegner stehen (Schritt 3 des Plans).
## Sie sind kein Zierrat: Ohne irgendetwas im Raum sieht ein erzeugter Stollen wie ein Flur aus,
## und man merkt beim Ablaufen nicht, ob der Grundriss taugt.
func _kisten_bauen() -> void:
	for art in [["truhen", Color(0.62, 0.48, 0.22), 1.1], ["gegner", Color(0.35, 0.30, 0.28), 0.8]]:
		for f in (_plan[String(art[0])] as Array):
			var mi := MeshInstance3D.new()
			var box := BoxMesh.new()
			var s: float = float(art[2])
			box.size = Vector3(s, s, s)
			mi.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = art[1]
			mi.material_override = mat
			mi.position = DungeonLayout.feld_zu_szene(f as Vector2i) + Vector3(0.0, s * 0.5, 0.0)
			add_child(mi)

	# Die Treppe: ein dunkles Loch mit Rahmen. Sie muss sich vom Rest abheben, sonst sucht man
	# in einem dunklen Stollen nach einem dunklen Kasten.
	_treppe_pos = DungeonLayout.feld_zu_szene(_plan["treppe"] as Vector2i)
	var tr := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(DungeonLayout.FELD_M * 0.8, 0.3, DungeonLayout.FELD_M * 0.8)
	tr.mesh = tb
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.05, 0.05, 0.06)
	tmat.emission_enabled = true
	tmat.emission = Color(0.35, 0.55, 0.75)
	tmat.emission_energy_multiplier = 0.5
	tr.material_override = tmat
	tr.position = _treppe_pos + Vector3(0.0, 0.16, 0.0)
	add_child(tr)

	# Und der Eingang, damit man den Rückweg wiederfindet. Ein Stollen, aus dem man nicht
	# herausfindet, ist keine Herausforderung, sondern ein Fehler.
	_eingang_pos = DungeonLayout.feld_zu_szene(_plan["eingang"] as Vector2i)
	var au := MeshInstance3D.new()
	var ab := BoxMesh.new()
	ab.size = Vector3(DungeonLayout.FELD_M * 0.8, 0.3, DungeonLayout.FELD_M * 0.8)
	au.mesh = ab
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.08, 0.07, 0.05)
	amat.emission_enabled = true
	amat.emission = Color(0.85, 0.62, 0.28)
	amat.emission_energy_multiplier = 0.5
	au.material_override = amat
	au.position = _eingang_pos + Vector3(0.0, 0.16, 0.0)
	add_child(au)


func _spieler_bauen() -> void:
	_spieler = AssetRegistry.instantiate("player", 1.8)
	if _spieler == null:
		_spieler = Node3D.new()
	_spieler.position = _eingang_pos
	add_child(_spieler)

	# Die Lampe haengt am Spieler, nicht an der Kamera: Sie soll zeigen, wo ER steht, und beim
	# Drehen mitgehen.
	_lampe = OmniLight3D.new()
	_lampe.omni_range = LAMPE_M
	_lampe.light_energy = 2.1
	_lampe.light_color = Color(1.0, 0.86, 0.62)
	_lampe.position = Vector3(0.0, 1.5, 0.0)
	_spieler.add_child(_lampe)

	_kamera = Camera3D.new()
	_kamera.current = true
	add_child(_kamera)
	_kamera_nachziehen()


func _oberflaeche_bauen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_stick = VirtualStick.new()
	_stick.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_stick)
	_text = Label.new()
	_text.position = Vector2(14.0, 12.0)
	_text.add_theme_font_size_override("font_size", 16)
	layer.add_child(_text)
	_hinweis = Label.new()
	_hinweis.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hinweis.position = Vector2(-190.0, -120.0)
	_hinweis.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hinweis)
	_kopf_setzen()


func _kopf_setzen() -> void:
	var name: String = "Der Vorschacht" if GameState.stollen_ebene == 1 else "Die Kaverne"
	_text.text = "⌂ %s — Ebene %d   ▩ %d Kammern" % [name, GameState.stollen_ebene,
		(_plan["raeume"] as Array).size()]


func _process(delta: float) -> void:
	_gehen(delta)
	_kamera_nachziehen()
	_naehe_pruefen()


## Bewegung mit Wand statt Hang.
##
## Der Wandtest schlaegt das ZIELFELD nach, und zwar getrennt fuer x und z. Das ist der
## Unterschied zwischen „bleibt an der Ecke kleben" und „rutscht an der Wand entlang": Wer beide
## Achsen zusammen prueft, steht bei jedem schraegen Anlauf still, obwohl eine der beiden
## Richtungen frei waere.
func _gehen(delta: float) -> void:
	if _spieler == null:
		return
	var v: Vector2 = _richtung()
	if v.length() < 0.01:
		return
	var schritt: Vector3 = Vector3(v.x, 0.0, v.y).normalized() * SPIELER_TEMPO * delta
	var p: Vector3 = _spieler.position
	var nur_x := Vector3(p.x + schritt.x, p.y, p.z)
	if DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(nur_x)):
		p = nur_x
	var nur_z := Vector3(p.x, p.y, p.z + schritt.z)
	if DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(nur_z)):
		p = nur_z
	_spieler.position = p
	_spieler.rotation.y = atan2(-schritt.x, -schritt.z)


func _richtung() -> Vector2:
	if _stick != null and _stick.active:
		var d: Vector2 = (_stick.knob - _stick.origin) / maxf(_stick.radius, 1.0)
		if d.length() > 0.12:
			return d.limit_length(1.0)
	return Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))


func _kamera_nachziehen() -> void:
	if _kamera == null or _spieler == null:
		return
	# Steiler als draussen: In einem engen Gang zeigt eine flache Kamera vor allem die Wand
	# direkt vor der Nase.
	_kamera.position = _spieler.position + Vector3(0.0, 13.0, 11.0)
	_kamera.look_at(_spieler.position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _naehe_pruefen() -> void:
	if _spieler == null or _hinweis == null:
		return
	var d_treppe: float = _spieler.position.distance_to(_treppe_pos)
	var d_aus: float = _spieler.position.distance_to(_eingang_pos)
	if d_treppe <= NAH_M:
		_hinweis.text = "▼ Tiefer steigen   [E]" if GameState.stollen_ebene < 2 \
			else "▲ Zurück ans Licht   [E]"
	elif d_aus <= NAH_M:
		_hinweis.text = "▲ Den Stollen verlassen   [E]"
	else:
		_hinweis.text = ""


## Der Stick zeichnet nur; wo er aufsetzt, entscheidet der Aufrufer — genauso wie draussen.
##
## Er setzt dort auf, wo der Finger HINFAELLT, und nicht an einer festen Stelle: Auf einem
## Telefon sieht man den eigenen Daumen nicht, und ein Stick mit fester Lage zwingt zum Zielen,
## bevor man losgehen kann.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		_stick_setzen(t.pressed, t.position)
	elif event is InputEventScreenDrag:
		_stick_ziehen((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			_stick_setzen(m.pressed, m.position)
	elif event is InputEventMouseMotion and _stick != null and _stick.active:
		_stick_ziehen((event as InputEventMouseMotion).position)
	elif event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_E:
		_benutzen()


func _stick_setzen(gedrueckt: bool, at: Vector2) -> void:
	if _stick == null:
		return
	_stick.active = gedrueckt
	if gedrueckt:
		_stick.origin = at
		_stick.knob = at
	_stick.queue_redraw()


func _stick_ziehen(at: Vector2) -> void:
	if _stick == null or not _stick.active:
		return
	_stick.knob = _stick.origin + (at - _stick.origin).limit_length(_stick.radius)
	_stick.queue_redraw()


func _benutzen() -> void:
	if _spieler == null:
		return
	if _spieler.position.distance_to(_treppe_pos) <= NAH_M:
		if GameState.stollen_ebene < 2:
			GameState.stollen_ebene += 1
			get_tree().reload_current_scene()
		else:
			_verlassen()
	elif _spieler.position.distance_to(_eingang_pos) <= NAH_M:
		_verlassen()


## Zurueck an die Oberflaeche — an die Stelle, an der man hineingestiegen ist.
##
## `stollen_ebene = 0` ist das Signal fuer die Oberwelt: Sie setzt die Figur beim Aufbau auf
## `stollen_rueckkehr`, statt den Prolog noch einmal zu starten.
func _verlassen() -> void:
	GameState.stollen_ebene = 0
	GameState.stollen_startwert = 0
	get_tree().change_scene_to_file("res://scenes/Overworld.tscn")
