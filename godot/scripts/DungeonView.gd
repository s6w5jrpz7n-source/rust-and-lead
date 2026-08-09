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
## ## Gekämpft wird nach denselben Regeln wie draußen
##
## Der Stollen bringt **keine eigene Kampfrechnung** mit. Schaden, Panzerung, Zustände und Beute
## kommen aus denselben Klassen wie draußen — `CombatEngine`, `CombatTarget`, `PlayerStats`,
## `AmmoData`. Was hier steht, ist nur die **Verdrahtung**: wer wen sieht, wer auf wen zuläuft,
## wann geschossen wird.
##
## Das ist die Grenze, an der ich es belasse. Zwei Kampf*rechnungen* würden auseinanderdriften,
## sobald jemand eine Zahl ändert — zwei Verdrahtungen sind bloß zweimal Arbeit. Und die
## Verdrahtung *muss* sich unterscheiden: Draußen hält man Abstand über offenes Gelände, drinnen
## kommt alles durch einen 4 m breiten Gang auf einen zu.

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
## Bis wann eine ANTWORT stehen bleibt (Sekunden, `Time.get_ticks_msec`-Basis).
##
## Die Hinweiszeile hat zwei Aufgaben, und die eine hat die andere aufgefressen: Sie sagt
## einerseits, was in Reichweite ist („Truhe öffnen [E]"), und andererseits, was gerade passiert
## ist („Verschlossen — 2 von 3 Schlüsseln"). Das Erste wird JEDES BILD neu geschrieben. Damit
## stand die Antwort auf einen Tastendruck genau ein Bild lang da und war für einen Menschen
## nicht lesbar — der Sperrsatz der Beutekammer erschien nie, obwohl er richtig gesetzt wurde.
##
## Aufgefallen ist das nicht im Code, sondern im Kontrollbild: Dort drückt die Figur auf die
## verschlossene Truhe, und der Satz fehlt.
var _antwort_bis: float = 0.0
## Wie lange eine Antwort stehen bleibt.
const ANTWORT_SEK: float = 3.0
var _treppe_pos: Vector3 = Vector3.ZERO
var _eingang_pos: Vector3 = Vector3.ZERO
var _truhen: Array = []
## Was auf dem Boden liegt und aufgehoben werden will.
var _boden: Array = []
var _gegner: Array = []
var _hp: float = 0.0
var _feuer: FireButton
var _feuer_bereit: float = 0.0
## Ton und Lebensbalken — beides fehlte hier, und beides fehlt man erst im Gefecht.
var _sfx_schuss: AudioStreamPlayer3D = null
var _sfx_repetieren: AudioStreamPlayer3D = null
var _repetier_t: float = -1.0
var _hp_bar: ProgressBar = null
## Im Stollen wird IMMER der Nachtklang genommen. Es gibt hier keine Sonne, und der trockene
## Tagesknall klaenge in einem Felsgang wie im Freien — der Hall ist der halbe Ort.
const SFX_SCHUSS: String = "res://assets/audio/karabiner_schuss_nacht.ogg"
const SFX_REPETIEREN: String = "res://assets/audio/karabiner_repetieren.ogg"
const SFX_REPETIER_VERZUG: float = 0.42

## Welche Gegner in welcher Ebene stehen. Ebene 1 ist der Vorschacht — Ratten und Grenzgänger,
## also das, was man draußen schon kennt. Ebene 2 ist die Kaverne: Kläffer im Schwarm und ein
## Konstrukt, und beide sind MECHANISCH. Das ist kein Zierrat, sondern eine Aussage über die
## Waffe: Panzerung frisst Kinetik, und wer nur den Karabiner dabei hat, merkt das hier zuerst.
const BESATZUNG: Dictionary = {
	1: ["fauna", "fauna", "outlaw", "revolver"],
	2: ["klaeffer", "klaeffer", "klaeffer", "konstrukt"],
}
## Ab wann ein Gegner den Spieler bemerkt. Kürzer als draußen: Im Gang steht man plötzlich
## voreinander, und ein Kläffer, der einen quer durch den Berg riecht, nimmt dem Stollen jede
## Ruhe zwischen den Kammern.
const SICHT_M: float = 16.0
const ANGRIFF_M: float = 2.0
const SCHUSS_M: float = 26.0
## Ab welchem Abstand zwei Fundstuecke sich beim Beschriften ins Gehege kommen.
const SCHILD_NAH_M: float = 2.2
## Wie weit ein Schild hochrueckt, wenn schon eines darunter steht.
const SCHILD_ZEILE_M: float = 0.34
## Die tiefste Ebene. Dort steht der Endgegner, dort liegt die Beutekammer.
const LETZTE_EBENE: int = 2
## Wer dort steht. Der Plan nennt ihn beim Namen: ein Konzern-Konstrukt als Abschluss.
const ENDGEGNER: String = "konstrukt"
## Sein Schimmer — glühendes Rot, nicht das Violett der Anführer. Wer den Unterschied nicht
## sieht, hält ihn für den vierten Anführer und läuft mit halbem Leben hinein.
const ENDGEGNER_SCHIMMER: Color = Color(1.0, 0.32, 0.16)
## Auf wie vielen Ebenen ein Anfuehrer steht.
##
## Einer WENIGER, als die Beutekammer Schluessel verlangt — den letzten traegt der Endgegner.
## Damit geht die Rechnung genau auf: Wer den Stollen ganz durchsteht, hat am Ende exakt die
## drei Schluessel in der Hand, die die Truhe vor ihm oeffnen. Kein Rest, keine Luecke.
##
## Abgeleitet und nicht abgeschrieben: Wer das Schloss der Beutekammer aendert, aendert damit
## automatisch die Zahl der Anfuehrer mit. Eine Drei, die an zwei Stellen steht, ist eine Drei,
## die irgendwann an einer Stelle eine Vier wird.
static func schluessel_ebenen() -> int:
	return maxi(0, ChestData.schluessel(ChestData.BOSS) - 1)


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
	_gegner_bauen()
	_spieler_bauen()
	_oberflaeche_bauen()
	_ton_bauen()
	_hp = float(PlayerStats.max_hp())


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
	# Ein geliefertes Wandstueck loest die Kaesten von selbst ab: Liegt `dungeon_wall` im
	# Projekt, wird SEIN Netz vervielfacht; sonst der Kasten. So ersetzt eine abgelegte Datei
	# die Platzhalter, ohne dass hier eine Zeile geaendert werden muss — genau so ist es
	# in `docs/PLAN_DUNGEON.md` versprochen.
	var wand_netz: Mesh = _netz_von("dungeon_wall")
	if wand_netz != null:
		mm.mesh = wand_netz
	else:
		var box := BoxMesh.new()
		box.size = Vector3(DungeonLayout.FELD_M, WAND_H, DungeonLayout.FELD_M)
		mm.mesh = box
	var felder: Array[Vector2i] = DungeonLayout.waende(_plan)
	mm.instance_count = felder.size()
	for i in felder.size():
		var m: Vector3 = DungeonLayout.feld_zu_szene(felder[i])
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, m + Vector3(0.0, WAND_H * 0.5, 0.0)))
	multi.multimesh = mm
	# Die eigene Farbe nur ueber die KAESTEN legen. Ein geliefertes Modell bringt seine Textur
	# mit, und ein Override wuerde sie loeschen — dann waere die neue Wand ein grauer Block.
	if wand_netz == null:
		multi.material_override = mat
	add_child(multi)


## Truhen an ihre Plätze. Gegner macht `_gegner_bauen()`.
##
## Die **letzte** Truhe der Kaverne ist eine Beutekammer — sie liegt im Raum mit der Treppe,
## also am Ende des Wegs. Der Plan sieht sie genau dort vor: „Eine garantierte Truhe mit
## angehobener Seltenheit". Wer beide Ebenen durchsteht, soll dafür etwas sehen, sonst ist die
## zweite Ebene bloß länger als die erste.
func _kisten_bauen() -> void:
	var alle: Array = _plan["truhen"] as Array
	for i in alle.size():
		var f: Vector2i = alle[i] as Vector2i
		var art: String = ChestData.STANDARD
		if GameState.stollen_ebene >= 2 and i == alle.size() - 1:
			art = ChestData.BOSS
		var knoten: Node3D = _truhe_bauen(art)
		knoten.position = DungeonLayout.feld_zu_szene(f) + Vector3(0.0, 0.05, 0.0)
		add_child(knoten)
		_truhen.append({ "node": knoten, "offen": false, "art": art })

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
	# Die Lampe haengt UEBER der Figur, nicht in ihr.
	#
	# Der erste Anlauf setzte sie auf 1,5 m — also mitten in den Koerper. Im Kontrollbild war
	# der Held daraufhin eine pechschwarze Silhouette auf hellem Boden: Eine Punktlampe im
	# Inneren beleuchtet alles ringsum und die Figur selbst gar nicht, weil deren Flaechen von
	# der Lichtquelle WEGZEIGEN. Von 2,9 m faellt das Licht auf sie herab wie von einer Laterne
	# am Stollendach, und man sieht, wen man da steuert.
	_lampe.position = Vector3(0.0, 2.9, 0.0)
	_spieler.add_child(_lampe)
	# Und eine zweite, sehr schwache, die NUR die Figur aufhellt: Sie steht dem Spieler am
	# naechsten und ist das Einzige, was er dauernd ansieht.
	var vorne := OmniLight3D.new()
	vorne.omni_range = 3.4
	vorne.light_energy = 1.1
	vorne.light_color = Color(0.86, 0.90, 1.0)
	vorne.position = Vector3(0.0, 1.6, -1.7)
	_spieler.add_child(vorne)

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
	_feuer = FireButton.new()
	layer.add_child(_feuer)
	# Ein BALKEN, nicht nur die Zahl in der Kopfzeile. Draussen gibt es ihn seit Langem, hier
	# stand nur „69/100" zwischen fuenf anderen Angaben — und eine Zahl muss man lesen, einen
	# Balken sieht man. Im Stollen wiegt das schwerer als draussen: Dort kommt der Schaden aus
	# der Ferne, hier steht das Konstrukt bereits neben einem.
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(210.0, 16.0)
	_hp_bar.size = Vector2(210.0, 16.0)
	_hp_bar.position = Vector2(14.0, 36.0)
	_hp_bar.show_percentage = false
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hinten := StyleBoxFlat.new()
	hinten.bg_color = Color(0.34, 0.09, 0.08)
	hinten.set_corner_radius_all(3)
	var vorn := StyleBoxFlat.new()
	vorn.bg_color = Color(0.72, 0.16, 0.14)
	vorn.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", hinten)
	_hp_bar.add_theme_stylebox_override("fill", vorn)
	layer.add_child(_hp_bar)
	_kopf_setzen()


func _kopf_setzen() -> void:
	var name: String = "Der Vorschacht" if GameState.stollen_ebene == 1 else "Die Kaverne"
	var steht: int = 0
	for e in _gegner:
		if (e["target"] as CombatTarget).health > 0:
			steht += 1
	_text.text = "⌂ %s — Ebene %d   ▩ %d Kammern   ❤ %d/%d   ¤ %d   ☠ %d/%d   ✦ %d/%d" % [
		name, GameState.stollen_ebene, (_plan["raeume"] as Array).size(),
		maxi(0, roundi(_hp)), PlayerStats.max_hp(), GameState.gold,
		_gegner.size() - steht, _gegner.size(),
		GameState.schluessel, ChestData.schluessel(ChestData.BOSS)]
	if GameState.item_count("grubenstahl") > 0:
		_text.text += "   ▬ %d" % GameState.item_count("grubenstahl")
	if _hp_bar != null:
		_hp_bar.max_value = maxf(1.0, float(PlayerStats.max_hp()))
		_hp_bar.value = clampf(_hp, 0.0, _hp_bar.max_value)


func _process(delta: float) -> void:
	_gehen(delta)
	_kamera_nachziehen()
	_kampf(delta)
	_ton_ticken(delta)
	_naehe_pruefen()
	_kopf_setzen()


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
	if DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(nur_x)) \
			and not _gegner_im_weg(nur_x):
		p = nur_x
	var nur_z := Vector3(p.x, p.y, p.z + schritt.z)
	if DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(nur_z)) \
			and not _gegner_im_weg(nur_z):
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


## Eine ANTWORT anzeigen — etwas, das gerade passiert ist.
##
## Sie hat für `ANTWORT_SEK` Vorrang vor der Reichweiten-Zeile. Ohne diesen Vorrang wischt der
## nächste Frame sie weg, und der Spieler drückt eine Taste, ohne je zu erfahren, was sie tat.
func _antworten(text: String) -> void:
	if _hinweis == null:
		return
	_hinweis.text = text
	_antwort_bis = Time.get_ticks_msec() / 1000.0 + ANTWORT_SEK


func _naehe_pruefen() -> void:
	if _spieler == null or _hinweis == null:
		return
	# Eine stehende Antwort nicht überschreiben.
	if Time.get_ticks_msec() / 1000.0 < _antwort_bis:
		return
	var liegt: Dictionary = _gear_in_range()
	if not liegt.is_empty():
		_hinweis.text = "✦ %s aufheben   [E]" % String((liegt["data"] as Dictionary).get(
			"name", "Fundstück"))
		return
	# Truhen hatten GAR KEINE Reichweiten-Zeile: Man stand davor, und nichts sagte einem, dass
	# man druecken kann. Im Dunkeln ist ein Kasten ohne Beschriftung ein Stein.
	for tr in _truhen:
		if bool(tr["offen"]):
			continue
		if (tr["node"] as Node3D).position.distance_to(_spieler.position) > NAH_M:
			continue
		var art_n: String = String(tr.get("art", ChestData.STANDARD))
		if ChestData.offen_mit(art_n, GameState.schluessel):
			_hinweis.text = "▩ %s öffnen   [E]" % String(ChestData.art(art_n)["name"])
		else:
			_hinweis.text = ChestData.schloss_text(art_n, GameState.schluessel)
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
	# Reihenfolge = Dringlichkeit. Was auf dem Boden liegt, geht vor der Truhe, und die geht
	# vor der Treppe: Wer neben allem dreien steht — und genau so steht es am Ende der Kaverne
	# beieinander —, will sicher nicht als Erstes die Ebene wechseln und seine Beute
	# zuruecklassen.
	if _gear_aufheben():
		return
	if _truhe_oeffnen():
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

## Gegner an ihre Plätze — aus derselben Tabelle wie draußen.
##
## `CombatTarget.from_type()` liefert Leben, Panzerung, Tempo und Beute; der Stollen legt nur
## fest, WER hier steht. Eigene Zahlen hätte er nicht verdient: Ein Kläffer muss drinnen so viel
## aushalten wie draußen, sonst lernt man beim Spielen zweierlei Widersprüchliches.
func _gegner_bauen() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("besatzung-%d-%d" % [GameState.stollen_startwert, GameState.stollen_ebene])
	var arten: Array = BESATZUNG.get(GameState.stollen_ebene, BESATZUNG[1])
	var alle: Array = _plan["gegner"] as Array
	# GENAU EINER je Ebene ist der Anfuehrer — und nur auf den ersten drei Ebenen. Drei
	# Schluessel oeffnen eine Beutekammer; ab der vierten Ebene noch einen zu stellen hiesse,
	# Schluessel zu verteilen, fuer die es kein Schloss gibt.
	var anfuehrer_nr: int = -1
	if GameState.stollen_ebene <= schluessel_ebenen() and not alle.is_empty():
		anfuehrer_nr = rng.randi() % alle.size()
	for i in alle.size():
		var f: Vector2i = alle[i] as Vector2i
		var art: String = String(arten[rng.randi() % arten.size()])
		var ist_kopf: bool = i == anfuehrer_nr
		var ziel: CombatTarget = CombatTarget.from_type(art, { "anfuehrer": ist_kopf })
		var knoten: Node3D = AssetRegistry.instantiate(art,
			1.4 * (CombatData.ANFUEHRER_GROESSE_MUL if ist_kopf else 1.0))
		if knoten == null:
			knoten = MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.9, 1.4, 0.9)
			(knoten as MeshInstance3D).mesh = box
		knoten.position = DungeonLayout.feld_zu_szene(f)
		add_child(knoten)
		if ist_kopf:
			AssetRegistry.schimmer_anlegen(knoten, CombatData.ANFUEHRER_SCHIMMER)
		# Die Lebensleiste über dem Kopf, wie draußen: Ohne sie sieht man nur, DASS man trifft,
		# nicht wie weit man ist.
		var leiste := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(1.0, 0.09, 0.02)
		leiste.mesh = lb
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(0.85, 0.22, 0.18)
		lm.emission_enabled = true
		lm.emission = Color(0.85, 0.22, 0.18)
		lm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		leiste.material_override = lm
		leiste.position = Vector3(0.0, 1.75, 0.0)
		knoten.add_child(leiste)
		_gegner.append({ "node": knoten, "target": ziel, "bar": leiste, "kaltzeit": 0.0 })
	if GameState.stollen_ebene >= LETZTE_EBENE:
		_endgegner_bauen()


## Der Endgegner der tiefsten Ebene — und der dritte Schlüssel.
##
## Er steht in der Kammer mit der TREPPE, und dort liegt auch die Beutekammer. Das ist die
## ganze Anordnung: Man sieht die verschlossene Truhe, man sieht, was davorsteht, und man hat
## in dem Moment zwei Schlüssel in der Tasche. Die Rechnung geht damit genau auf — wer den
## Stollen ganz durchsteht, hält am Ende exakt die drei in der Hand, die vor ihm liegen.
##
## `elite` und nicht „Anführer": Ein Anführer ist ein verstärkter gewöhnlicher Gegner, hier
## steht der Abschluss. `CombatTarget` hebt ihn auf Boss-Niveau, und der Plan nennt ihn beim
## Namen — ein Konzern-Konstrukt.
func _endgegner_bauen() -> void:
	var ziel: CombatTarget = CombatTarget.from_type(ENDGEGNER, { "elite": true })
	var knoten: Node3D = AssetRegistry.instantiate(ENDGEGNER, 2.6)
	if knoten == null:
		knoten = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.6, 2.6, 1.6)
		(knoten as MeshInstance3D).mesh = box
	# Neben die Treppe, nicht darauf: Wer die Ebene betritt und sofort im Gegner steht, hat
	# keinen Augenblick, ihn anzusehen — und genau der ist der Auftritt.
	knoten.position = _treppe_pos + Vector3(DungeonLayout.FELD_M * 1.2, 0.0, 0.0)
	add_child(knoten)
	# Ein ANDERES Rot als das Violett der Anführer. Beide leuchten, beide heißen „hier ist
	# etwas Besonderes" — aber wer den Unterschied nicht sieht, hält den Endgegner für den
	# vierten Anführer und läuft mit halbem Leben hinein.
	AssetRegistry.schimmer_anlegen(knoten, ENDGEGNER_SCHIMMER, 2.0)
	var leiste := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(1.8, 0.14, 0.02)
	leiste.mesh = lb
	var lm := StandardMaterial3D.new()
	lm.albedo_color = ENDGEGNER_SCHIMMER
	lm.emission_enabled = true
	lm.emission = ENDGEGNER_SCHIMMER
	lm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	leiste.material_override = lm
	leiste.position = Vector3(0.0, 3.0, 0.0)
	knoten.add_child(leiste)
	_gegner.append({ "node": knoten, "target": ziel, "bar": leiste, "kaltzeit": 0.0 })


## Die Runde: Gegner laufen, greifen an, der Spieler schießt zurück.
func _kampf(delta: float) -> void:
	if _spieler == null:
		return
	var jetzt: int = Time.get_ticks_msec()
	for e in _gegner:
		var t: CombatTarget = e["target"]
		if t.health <= 0:
			continue
		var n: Node3D = e["node"]
		# Schadensbrand tickt weiter, auch wenn niemand schießt — sonst wäre Säure eine
		# Anzeige ohne Wirkung.
		CombatEngine.tick_dot(t, jetzt, delta)
		if t.health <= 0:
			_faellt(e)
			continue
		var d: float = n.position.distance_to(_spieler.position)
		if d > SICHT_M or t.is_stunned(jetzt):
			continue
		if d > ANGRIFF_M:
			# Zu Fuß auf den Spieler zu, aber NUR über begehbare Felder: Ohne diese Prüfung
			# laufen sie durch den Fels und stehen plötzlich in der Kammer nebenan.
			var richtung: Vector3 = (_spieler.position - n.position).normalized()
			var tempo: float = float(CombatData.ENEMY_TYPES[t.type_id]["speed"]) * 0.03
			var schritt: Vector3 = richtung * tempo * delta
			var probe := Vector3(n.position.x + schritt.x, 0.0, n.position.z)
			if DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(probe)):
				n.position.x = probe.x
			probe = Vector3(n.position.x, 0.0, n.position.z + schritt.z)
			if DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(probe)):
				n.position.z = probe.z
			n.rotation.y = atan2(-richtung.x, -richtung.z)
		else:
			e["kaltzeit"] = float(e["kaltzeit"]) - delta
			if float(e["kaltzeit"]) <= 0.0:
				e["kaltzeit"] = CombatData.MELEE_INTERVAL_SEC
				_hp -= float(t.contact_dps) * CombatData.MELEE_INTERVAL_SEC \
					* CombatEngine.player_damage_taken_mul(PlayerStats.player_armor())
				if _hp <= 0.0:
					_ohnmacht()
					return
	_entflechten()
	_feuer_bereit -= delta
	if _feuern_gedrueckt() and _feuer_bereit <= 0.0:
		_schiessen(jetzt)
	if _feuer != null:
		_feuer.set_state(_feuern_gedrueckt(), _naechster() != null)


func _feuern_gedrueckt() -> bool:
	return (_feuer != null and _feuer.pressed) or Input.is_key_pressed(KEY_SPACE)


## Der nächste lebende Gegner in Schussweite — gezielt wird automatisch, wie draußen. Auf einem
## Telefon gibt es keinen zweiten Daumen für einen Zielstick.
func _naechster() -> Dictionary:
	var beste: Dictionary = {}
	var d_min: float = SCHUSS_M
	for e in _gegner:
		if (e["target"] as CombatTarget).health <= 0:
			continue
		var d: float = (e["node"] as Node3D).position.distance_to(_spieler.position)
		if d < d_min:
			d_min = d
			beste = e
	return beste


func _schiessen(jetzt: int) -> void:
	var waffe: String = GameState.weapon_id
	if waffe == "":
		return
	var e: Dictionary = _naechster()
	if e.is_empty():
		return
	_feuer_bereit = float(PlayerStats.fire_ms(waffe)) / 1000.0
	_schuss_ton()
	var t: CombatTarget = e["target"]
	var art: String = String(CombatData.WEAPONS[waffe]["type"])
	CombatEngine.resolve_hit(art, t, PlayerStats.damage_per_bullet(waffe),
		PlayerStats.armor_pen(), jetzt)
	_leiste_setzen(e)
	if t.health <= 0:
		_faellt(e)


func _leiste_setzen(e: Dictionary) -> void:
	var t: CombatTarget = e["target"]
	var bar: MeshInstance3D = e["bar"]
	bar.scale.x = clampf(float(t.health) / maxf(1.0, float(t.max_health)), 0.0, 1.0)


## Ein Gegner faellt: Gold und Munition wie draußen, das Modell bleibt als Leiche liegen.
func _faellt(e: Dictionary) -> void:
	var t: CombatTarget = e["target"]
	var n: Node3D = e["node"]
	GameState.gold += t.gold
	GameState.kills += 1
	GameState.add_xp(CombatData.xp_for_kill(t))
	# Ausruestung faellt auf den BODEN und wandert nicht in den Beutel.
	#
	# Kurz lag sie direkt im Beutel, mit dem Argument, man finde auf dunklem Grund ohnehin
	# nichts. Das war die falsche Antwort auf ein echtes Problem: Beute, die einem zufaellt,
	# ist etwas, das einem PASSIERT — und der Beutel fuellt sich, ohne dass man je entschieden
	# haette, etwas mitzunehmen. Richtig ist, das Fundstueck sichtbar zu machen, nicht das
	# Aufheben abzuschaffen. Deshalb traegt jedes Stueck seinen Namen als leuchtende Schrift
	# ueber sich.
	for _k in BeuteData.stuecke(BeuteData.ist_besonders(t)):
		_gear_ablegen(n.position, ProgressionManager.make_gear(BeuteData.slot(),
			BeuteData.seltenheit()))
	if BeuteData.traegt_schluessel(t):
		GameState.schluessel += 1
		_antworten("✦ Ein Schlüssel. %d von %d." % [GameState.schluessel,
			ChestData.schluessel(ChestData.BOSS)])
	# Auf die Seite kippen statt verschwinden. Wer im Dunkeln kämpft, verliert sonst den
	# Ueberblick, wen er schon erledigt hat — und laeuft dreimal um dieselbe Kammer.
	n.rotation.x = PI * 0.5
	(e["bar"] as MeshInstance3D).visible = false
	_kopf_setzen()


## Ohnmacht: zurueck an die Oberflaeche statt Bildschirmtod.
##
## Der Stollen behaelt seinen Startwert NICHT — wer hier unten liegen bleibt, faengt beim
## naechsten Abstieg von vorn an. Ein Dungeon, in den man nach dem Sterben mit geleerten
## Kammern zurueckkehrt, ist kein Risiko mehr.
func _ohnmacht() -> void:
	GameState.gold = maxi(0, GameState.gold - 10)
	_verlassen()


## Truhe oeffnen, wenn eine in Reichweite liegt.
func _truhe_oeffnen() -> bool:
	for tr in _truhen:
		if bool(tr["offen"]):
			continue
		var n: MeshInstance3D = tr["node"]
		if n.position.distance_to(_spieler.position) > NAH_M:
			continue
		var art_pruef: String = String(tr.get("art", ChestData.STANDARD))
		# Erst das Schloss. Wer davorsteht und nicht aufkriegt, muss ERFAHREN warum — und mit
		# welcher Zahl. „Verschlossen" allein ist eine Wand, keine Aufgabe.
		if not ChestData.offen_mit(art_pruef, GameState.schluessel):
			_antworten(ChestData.schloss_text(art_pruef, GameState.schluessel))
			return true
		tr["offen"] = true
		n.visible = false
		# Beute aus `ChestData` — dieselbe Tabelle wie draussen. Der Stollen rechnete vorher
		# `18 + Ebene · 22` und die Oberwelt wuerfelte 18–45: zwei Zahlenreihen fuer dieselbe
		# Sache, die beim ersten „die Truhe gibt zu wenig" niemand mehr auseinanderhaelt.
		var art: String = art_pruef
		GameState.schluessel -= ChestData.schluessel(art)
		var gold: int = ChestData.gold(art)
		GameState.gold += gold
		var wie_viele: int = ChestData.stuecke(art)
		for _k in wie_viele:
			# Auch aus der Truhe: auf den Boden, nicht in den Beutel. Eine Truhe, die ihren
			# Inhalt einsortiert, ist ein Knopf mit Zahlen dahinter.
			_gear_ablegen(n.position, ProgressionManager.make_gear(
				String(EquipManager.GEAR_SLOTS[randi() % EquipManager.GEAR_SLOTS.size()]),
				ChestData.seltenheit(art)))
		if ChestData.trank(art):
			GameState.potions += 1
		# Und der Grubenstahl. Er liegt bei den gewoehnlichen Sachen mit drin — derselbe Griff,
		# der Gold und Ausruestung bringt. Vorher lag er als Halden ueber die Kammern gestreut,
		# und der Stollen wurde zur Sammelaufgabe, bei der man am Boden klebt.
		var stahl: int = ChestData.stahl(art)
		if stahl > 0:
			GameState.add_item("grubenstahl", stahl)
		_antworten("▩ %s: %d ¤, %d ▬ Grubenstahl und %d Stück — sie liegen davor." % [
			String(ChestData.art(art)["name"]), gold, stahl, wie_viele])
		_kopf_setzen()
		return true
	return false


## Eine Truhe als Knoten — Modell, wenn es eines gibt, sonst gezeichnet.
##
## Auch drinnen glimmt sie. In einem Stollen, der nur so weit hell ist, wie die Lampe trägt,
## findet man eine Truhe sonst bloß durch Anstoßen — und eine Belohnung, die man übersieht, ist
## im Augenblick des Findens keine.
func _truhe_bauen(art: String) -> Node3D:
	var eintrag: Dictionary = ChestData.art(art)
	var modell_name: String = String(eintrag["modell"])
	var wurzel: Node3D = AssetRegistry.instantiate(modell_name,
		AssetRegistry.height_of(modell_name))
	if wurzel != null:
		return wurzel
	wurzel = Node3D.new()
	var ist_boss: bool = art == ChestData.BOSS
	# Die Beutekammer ist nicht dieselbe Kiste in Gold: Sie hat Sockel, Kasten und Deckelband,
	# ist hoeher und glimmt kuehler. Im Daemmerlicht traegt die FORM weiter als die Farbe.
	var teile: Array = [[Vector3(1.1, 0.8, 0.8), 0.4, Color(0.62, 0.48, 0.22),
		Color(0.85, 0.62, 0.25), 0.35]]
	if ist_boss:
		teile = [
			[Vector3(1.24, 0.14, 0.92), 0.07, Color(0.22, 0.20, 0.18), Color.BLACK, 0.0],
			[Vector3(1.06, 0.72, 0.78), 0.50, Color(0.30, 0.24, 0.14), Color.BLACK, 0.0],
			[Vector3(1.16, 0.14, 0.86), 0.93, Color(0.80, 0.64, 0.28),
				Color(0.72, 0.90, 1.0), 0.55],
		]
	for t in teile:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = t[0]
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = t[2]
		if float(t[4]) > 0.0:
			mat.metallic = 0.7
			mat.roughness = 0.32
			mat.emission_enabled = true
			mat.emission = t[3]
			mat.emission_energy_multiplier = float(t[4])
		mi.material_override = mat
		mi.position = Vector3(0.0, float(t[1]), 0.0)
		wurzel.add_child(mi)
	return wurzel


## Ein Fundstück auf den Boden legen.
##
## Die BESCHRIFTUNG ist das Fundstück — genau wie draußen. Aus Kamerahöhe erkennt man ein
## 30-cm-Ding im Schutt nicht, den Schriftzug darüber schon, und im Stollen gilt das doppelt:
## Was außerhalb des Lampenkegels liegt, ist sonst schlicht unsichtbar. Deshalb leuchtet die
## Schrift aus sich selbst und die Farbe sagt schon von weitem, ob sich das Hinlaufen lohnt.
func _gear_ablegen(wo: Vector3, stueck: Dictionary) -> void:
	if stueck.is_empty():
		return
	# Gestreut, damit zwei Stücke nicht ineinanderstehen und man beide erwischt.
	var winkel: float = randf() * TAU
	var r: float = sqrt(randf()) * 1.6
	var pos := Vector3(wo.x + cos(winkel) * r, 0.0, wo.z + sin(winkel) * r)
	# Aber nur auf begehbarem Grund: Ein Fundstück, das im Fels steckt, ist eine Belohnung, die
	# man sieht und nie bekommt.
	if not DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(pos)):
		pos = Vector3(wo.x, 0.0, wo.z)
	var farbe: Color = ProgressionManager.RARITY_COLOR.get(String(stueck["rarity"]),
		Color(0.9, 0.9, 0.9))
	var knoten := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.36, 0.22, 0.36)
	knoten.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = farbe
	mat.emission_enabled = true
	mat.emission = farbe
	mat.emission_energy_multiplier = 0.6
	knoten.material_override = mat
	knoten.position = pos + Vector3(0.0, 0.11, 0.0)
	add_child(knoten)
	# Die Beschriftung STAPELT sich, wenn schon etwas danebenliegt.
	#
	# Im Kontrollbild lagen vier Stücke dicht beieinander, und ihre Namen standen exakt
	# übereinander — vier Zeilen ineinandergeschrieben, aus denen sich kein einziges Wort mehr
	# lesen ließ. Genau der Fall tritt im Spiel ein, wenn ein Anführer zwei Stücke fallen lässt
	# oder eine Beutekammer vier. Also: Für jedes Stück in der Nähe rückt das Schild eine Zeile
	# höher.
	var drueber: int = 0
	for anderes in _boden:
		if (anderes["pos"] as Vector3).distance_to(pos) < SCHILD_NAH_M:
			drueber += 1
	var schild := Label3D.new()
	schild.text = String(stueck.get("name", "Fundstück"))
	schild.font_size = 48
	schild.pixel_size = 0.006
	schild.modulate = farbe
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	schild.no_depth_test = true
	schild.position = pos + Vector3(0.0, 0.95 + float(drueber) * SCHILD_ZEILE_M, 0.0)
	add_child(schild)
	_boden.append({ "node": knoten, "schild": schild, "data": stueck, "pos": pos })


## Das nächste Fundstück in Reichweite ({} = keins).
func _gear_in_range() -> Dictionary:
	for g in _boden:
		if _spieler.position.distance_to(g["pos"] as Vector3) <= NAH_M:
			return g
	return {}


## Aufheben — dieselbe Entscheidung wie draußen, mit derselben Taste.
func _gear_aufheben() -> bool:
	var g: Dictionary = _gear_in_range()
	if g.is_empty():
		return false
	var stueck: Dictionary = g["data"]
	if not BagManager.add(stueck):
		_antworten("▤ Der Beutel ist voll.")
		return true
	_antworten("✦ %s %s eingesteckt" % [
		String(ProgressionManager.RARITY[String(stueck["rarity"])]["name"]),
		String(stueck.get("name", "Fundstück"))])
	(g["node"] as Node3D).queue_free()
	(g["schild"] as Node3D).queue_free()
	_boden.erase(g)
	return true


## Zwei Tonquellen am Helden — dieselbe Aufteilung wie draußen.
##
## Der Stollen war **stumm**. Man drückte den Abzug, ein Gegner verlor Leben, und nichts sagte
## einem, dass geschossen wurde — bei einer Trefferanzeige, die im Dunkeln ohnehin schwer zu
## lesen ist, fehlte damit die einzige verlässliche Rückmeldung. Die Dateien lagen längst da;
## sie waren nur nie angeschlossen worden.
func _ton_bauen() -> void:
	if _spieler == null:
		return
	_sfx_schuss = AudioStreamPlayer3D.new()
	# Enger als draußen: Ein Gang ist kein offenes Feld, und ein Knall, der über 320 m trägt,
	# klingt in vier Metern Fels falsch.
	_sfx_schuss.unit_size = 14.0
	_sfx_schuss.max_distance = 90.0
	_spieler.add_child(_sfx_schuss)
	_sfx_repetieren = AudioStreamPlayer3D.new()
	_sfx_repetieren.unit_size = 4.0
	_sfx_repetieren.max_distance = 40.0
	_sfx_repetieren.volume_db = -4.0
	_spieler.add_child(_sfx_repetieren)


func _schuss_ton() -> void:
	_ton(_sfx_schuss, SFX_SCHUSS, randf_range(-0.04, 0.04))
	_repetier_t = SFX_REPETIER_VERZUG


## Das Repetieren kommt NACH dem Knall, nicht mit ihm. Zusammen wäre es ein Geräusch; getrennt
## ist es eine Waffe, die man nachziehen muss.
func _ton_ticken(delta: float) -> void:
	if _repetier_t < 0.0:
		return
	_repetier_t -= delta
	if _repetier_t <= 0.0:
		_repetier_t = -1.0
		_ton(_sfx_repetieren, SFX_REPETIEREN, randf_range(-0.06, 0.06))


func _ton(quelle: AudioStreamPlayer3D, pfad: String, hoehe: float) -> void:
	if quelle == null or not is_instance_valid(quelle) or not ResourceLoader.exists(pfad):
		return
	quelle.stream = load(pfad) as AudioStream
	# Kleine Tonhöhenstreuung, sonst klingt die dritte Salve wie ein Metronom.
	quelle.pitch_scale = 1.0 + hoehe
	quelle.play()


## Das erste Netz eines Modells aus der Registry — oder `null`, wenn die Datei fehlt.
##
## Gebraucht fuer die Waende: Ein `MultiMesh` vervielfacht EIN Netz, keinen ganzen Szenenbaum.
## Wer ein `.glb` liefert, liefert aber einen Baum, und irgendwo darin haengt das Netz.
static func _netz_von(name: String) -> Mesh:
	var wurzel: Node3D = AssetRegistry.instantiate(name, 0.0)
	if wurzel == null:
		return null
	var gefunden: Mesh = null
	var offen: Array[Node] = [wurzel]
	while not offen.is_empty():
		var n: Node = offen.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			gefunden = (n as MeshInstance3D).mesh
			break
		offen.append_array(n.get_children())
	wurzel.queue_free()
	return gefunden


## Gegner, die sich überlappen, auseinanderschieben — dieselbe Regel wie draußen.
##
## Drinnen wiegt es schwerer: Ein Gang ist 4 m breit, und drei Kläffer, die sich durchdringen,
## kommen als **ein** Gegner an. Man schießt auf einen Klumpen und weiß nicht, wie viele darin
## stecken.
##
## Der Unterschied zur Oberwelt ist die Wand: Wer geschoben wird, darf nicht in den Fels
## rutschen. Landet die Korrektur auf einem nicht begehbaren Feld, bleibt der Körper stehen —
## lieber eine Überlappung als ein Gegner im Gestein.
## Steht an dieser Stelle ein Gegner?
##
## Ein Gegnerkörper wird in der Bewegung behandelt wie eine Wand — getrennt für x und z, damit
## man an ihm ENTLANGRUTSCHT statt vor ihm zu kleben. Genau das ist im Stollen der Unterschied
## zwischen „ein Kläffer steht im Gang" und „der Gang ist zu".
func _gegner_im_weg(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	for e in _gegner:
		var t: CombatTarget = e["target"]
		if t.health <= 0:
			continue        # eine Leiche ist kein Hindernis
		var n: Node3D = e["node"]
		if Gedraenge.beruehrt(q, Gedraenge.SPIELER_R,
				Vector2(n.position.x, n.position.z), _radius_von(t)):
			return true
	return false


## Der Platz, den dieser Gegner braucht. Anfuehrer und Endgegner sind groesser gebaut als ihr
## Typ — sie brauchen auch mehr davon.
func _radius_von(t: CombatTarget) -> float:
	var r: float = Gedraenge.radius_fuer(String(t.type_id))
	if t.is_elite:
		return r * 1.6
	return r * (CombatData.ANFUEHRER_GROESSE_MUL if t.is_leader else 1.0)


func _entflechten() -> void:
	if _gegner.is_empty():
		return
	var punkte: Array = []
	var radien: Array = []
	for e in _gegner:
		var n: Node3D = e["node"]
		punkte.append(Vector2(n.position.x, n.position.z))
		radien.append(_radius_von(e["target"] as CombatTarget))
	var neu_pos: Array = Gedraenge.entflechten(punkte, radien)
	# Und zuletzt aus dem SPIELER heraus — er wird dabei nie geschoben. Zuletzt, damit dieser
	# Schub nicht von einer Gegner-Gegner-Aufloesung wieder aufgehoben wird.
	if _spieler != null:
		neu_pos = Gedraenge.aus_dem_weg(neu_pos, radien,
			Vector2(_spieler.position.x, _spieler.position.z), Gedraenge.SPIELER_R)
	for i in _gegner.size():
		var p2: Vector2 = neu_pos[i]
		if p2.is_equal_approx(punkte[i]):
			continue
		var ziel := Vector3(p2.x, 0.0, p2.y)
		if not DungeonLayout.begehbar(_plan, DungeonLayout.szene_zu_feld(ziel)):
			continue
		(_gegner[i]["node"] as Node3D).position = ziel
