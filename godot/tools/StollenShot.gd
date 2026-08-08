extends Node3D
## Ein Kontrollbild vom Stollen.
##
## Die Flutfuellung im Test beweist, dass jedes Feld erreichbar ist. Sie sagt nichts darueber,
## ob man in dem Ding etwas SIEHT — ob die Lampe traegt, ob die Waende stehen, ob der Grundriss
## nach Kammern aussieht oder nach einem Schlauch. Dafuer braucht es ein Bild.
##
## Zwei Ansichten, und die zweite ist die wichtigere: Aus Spielerhoehe steht man in einem Gang
## und weiss nicht, ob dahinter sechs Kammern liegen oder eine. Erst von oben sieht man, ob der
## Erzeuger etwas gebaut hat, das sich zu erkunden lohnt.
const OUT: String = "user://shot_stollen"
var _i: int = 0
var _warte: int = 45
var _oben: Camera3D
var _flut: DirectionalLight3D


func _ready() -> void:
	GameState.stollen_startwert = 4242
	GameState.stollen_ebene = 1
	add_child(load("res://scenes/Dungeon.tscn").instantiate())
	# Eine EIGENE Kamera, die spaeter uebernimmt. Die Kamera des Stollens wird jeden Frame an
	# den Spieler gezogen — eine dort gesetzte Position waere im naechsten Bild wieder weg.
	_oben = Camera3D.new()
	_oben.position = Vector3(0.0, 108.0, 1.0)
	add_child(_oben)
	# ERST in den Baum, DANN ausrichten. `look_at()` rechnet in Weltkoordinaten und braucht
	# dafuer einen Knoten, der im Baum haengt — davor bricht es mit „Node not inside tree" ab
	# und die Kamera behaelt ihre Ausgangslage. Sie schaute deshalb waagerecht ins Leere, und
	# das Bild blieb schwarz, obwohl Licht und Nebel laengst stimmten.
	#
	# Und `up` ist nicht `Vector3.UP`: Wer senkrecht nach unten schaut, haette eine
	# Blickrichtung, die zur Hilfsachse parallel ist — daraus laesst sich keine Drehung bilden.
	_oben.look_at(Vector3.ZERO, Vector3.FORWARD)
	# Fuer die Draufsicht wird das Licht angemacht — und NUR dafuer. Der erste Anlauf hat die
	# Uebersicht ohne Lampe geknipst und ein vollstaendig schwarzes Bild geliefert: voellig
	# richtig fuer einen Stollen, als Kontrollbild wertlos. Wer den GRUNDRISS beurteilen will,
	# muss ihn sehen; wer die Stimmung beurteilen will, nimmt das andere Bild.
	_flut = DirectionalLight3D.new()
	_flut.rotation_degrees = Vector3(-72.0, -28.0, 0.0)
	_flut.light_energy = 2.4
	_flut.visible = false
	add_child(_flut)


func _process(_dt: float) -> void:
	_warte -= 1
	if _warte > 0:
		return
	var bild: Image = get_viewport().get_texture().get_image()
	if _i == 0:
		bild.save_png("%s_spieler.png" % OUT)
		_oben.current = true
		_flut.visible = true
		# Und der NEBEL muss weg. Der zweite Anlauf hat nur das Licht angemacht und wieder ein
		# schwarzes Bild geliefert: Bei 0,035 Dichte bleibt ueber 108 m Kamerahoehe nichts
		# uebrig — exp(-0,035 · 108) ist rund zwei Prozent. Die Beleuchtung war nie das
		# Problem, die Sichtweite war es.
		_nebel_aus()
		_i = 1
		_warte = 25
		return
	bild.save_png("%s_oben.png" % OUT)
	get_tree().quit()


## Nebel und Dunkelheit der Stollen-Umgebung fuer die Uebersicht abschalten.
func _nebel_aus() -> void:
	for kind in get_child(0).get_children():
		if kind is WorldEnvironment:
			var env: Environment = (kind as WorldEnvironment).environment
			env.fog_enabled = false
			env.ambient_light_energy = 1.0
			env.background_color = Color(0.05, 0.05, 0.07)
