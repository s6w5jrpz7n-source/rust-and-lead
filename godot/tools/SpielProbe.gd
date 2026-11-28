extends Node2D

## Startversuch: Laesst sich das Spiel SPIELEN?
##
## Die Testsuite spielt alle vier Kapitel durch, aber auf der Datenschicht -- sie ruft `Welt`,
## `OrtDaten` und `GespraechDaten` auf, nicht die Szenen-Knoten. Das ist die richtige Schicht
## fuer 3500 Pruefungen, nur beantwortet sie eine Frage NICHT: Baut sich die Buehne auf, und
## passiert etwas, wenn man klickt?
##
## Diese Probe nimmt den Weg des Spielers. Sie haengt `Abenteuer.tscn` in den Baum, schickt
## echte Mausereignisse durch den Viewport und benutzt JEDEN Hotspot an JEDEM Ort. Ein Fehler
## in `_ausfuehren`, ein Signal ins Leere, ein Gespraechsbaum, den es nicht gibt -- hier
## faellt es auf, und nur hier.
##
##   godot --headless --path godot res://tools/SpielProbe.tscn
##
## Was sie NICHT kann: beurteilen, wie es aussieht. Headless gibt es keinen Rasterizer, also
## laeuft `_draw` ins Leere. Dass die Bilder stimmen, ist am Gemaelde eingemessen
## (`tools/EinmessProbe.gd`) -- das ist eine andere Frage und hat ihr eigenes Werkzeug.

const ABENTEUER := preload("res://scenes/Abenteuer.tscn")
const TITLE := preload("res://scenes/Title.tscn")
const OrtDaten := preload("res://scripts/OrtDaten.gd")
const MissionDaten := preload("res://scripts/MissionDaten.gd")
const KapitelDaten := preload("res://scripts/KapitelDaten.gd")
const Welt := preload("res://scripts/Welt.gd")

var _geprueft: int = 0
var _klicks: int = 0
var _meldungen: Array = []


func _ready() -> void:
	await get_tree().process_frame
	print("── Startversuch ──────────────────────────────────────────────")

	await _titel_pruefen()
	var wurzel: Node = await _buehne_aufbauen()
	if wurzel == null:
		_ende()
		return

	var buehne = wurzel.get("_buehne")
	await _orte_durchgehen(wurzel, buehne)
	await _maus_echt(buehne)
	await _tagebuch(wurzel)
	await _gespraeche(wurzel)

	_ende()


## Der Titelbildschirm -- weil das Spiel dort anfaengt und „Neues Spiel" ins Abenteuer fuehrt.
func _titel_pruefen() -> void:
	var t: Node = TITLE.instantiate()
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var knoepfe: Array = []
	_knoepfe_sammeln(t, knoepfe)
	var hat_neu: bool = false
	for b in knoepfe:
		if str(b.text) == "Neues Spiel":
			hat_neu = true
	_sagen("Titel: %d Knoepfe, „Neues Spiel\" %s" % [knoepfe.size(), "da" if hat_neu else "FEHLT"])
	if not hat_neu:
		_fehler("Titelbildschirm hat keinen Knopf „Neues Spiel\"")
	_geprueft += 1
	t.queue_free()
	await get_tree().process_frame


func _knoepfe_sammeln(n: Node, raus: Array) -> void:
	if n is Button:
		raus.append(n)
	for k in n.get_children():
		_knoepfe_sammeln(k, raus)


func _buehne_aufbauen() -> Node:
	GameState.neu_beginnen()
	Welt.neu()
	var w: Node = ABENTEUER.instantiate()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	if w.get("_buehne") == null:
		_fehler("Abenteuer.tscn baut keine Buehne auf")
		return null
	_sagen("Buehne steht. Startort: %s, Kapitel %d" % [GameState.ort, GameState.current_chapter])
	_geprueft += 1
	return w


## Jeden Hotspot an jedem Ort benutzen und ansehen.
##
## Zwischen den Orten wird die Welt zurueckgesetzt, sonst traegt der vorige Ort seinen Zustand
## in den naechsten und die Probe prueft am Ende etwas anderes als das Spiel.
func _orte_durchgehen(wurzel: Node, buehne) -> void:
	var orte: Array = OrtDaten.alle()
	orte.sort()
	for ort in orte:
		Welt.neu()
		buehne.betreten(ort)
		await get_tree().process_frame
		var punkte: Dictionary = OrtDaten.punkte_alle(ort)
		var n: int = 0
		for name in punkte.keys():
			# Erst ansehen: aendert nie etwas, kann also nicht den naechsten Klick verfaelschen.
			buehne._ansehen_an(_mitte(punkte[name]))
			buehne.verstummen()
			# Dann benutzen -- direkt, ohne Laufweg. Der Laufweg wird unten einmal echt
			# geprueft; hier geht es um die Wirkung, und 60 Hotspots auszulaufen dauert
			# Minuten ohne eine einzige weitere Erkenntnis.
			buehne._ausfuehren(name, "benutzen")
			buehne.verstummen()
			# Ein Hotspot kann ein Gespraech aufziehen. Bleibt es offen, laufen alle
			# weiteren Klicks gegen eine Sprechtafel statt gegen das Bild.
			if wurzel.get("_gespraech").visible:
				wurzel._gespraech_schliessen()
				await get_tree().process_frame
			n += 1
			_klicks += 2
			# Ein Ausgang hat den Ort gewechselt. Zurueck, sonst laufen die restlichen
			# Hotspots gegen das falsche Bild.
			if buehne.get("_ort") != ort:
				buehne.betreten(ort)
				await get_tree().process_frame
		_sagen("%-16s %2d Hotspots" % [ort, n])
		_geprueft += 1


func _mitte(p: Dictionary) -> Vector2:
	var r: Rect2 = p.get("rect", Rect2()) as Rect2
	return r.position + r.size * 0.5


## Einmal der ganze Weg mit echten Mausereignissen: hinsehen, hinlaufen, benutzen.
func _maus_echt(buehne) -> void:
	Welt.neu()
	buehne.betreten("kippe")
	await get_tree().process_frame
	var punkte: Dictionary = OrtDaten.punkte_alle("kippe")
	# Den WEITESTEN Hotspot mit `nehmen` nehmen, nicht den ersten.
	#
	# Der erste war der Revolver, und der liegt zufaellig in Reichweite des Startpunkts: Die
	# Probe meldete „hingelaufen in 0 Rahmen" und war gruen, ohne den Laufweg ein einziges Mal
	# benutzt zu haben. Ein Test, der die Strecke nicht laeuft, prueft sie auch nicht.
	var ziel: String = ""
	var weit: float = -1.0
	var start: Vector2 = buehne.get("_figur_pos")
	for name in punkte.keys():
		if not punkte[name].has("nehmen"):
			continue
		var d: float = start.distance_to(OrtDaten.hingehen("kippe", str(name)))
		if d > weit:
			weit = d
			ziel = str(name)
	if ziel == "":
		ziel = str(punkte.keys()[0])
	var wo: Vector2 = _mitte(punkte[ziel])

	_maus_bewegen(wo)
	await get_tree().process_frame
	if buehne.get("_maus") != wo:
		_fehler("Mausposition kommt verzerrt an: geschickt %s, angekommen %s" % [wo, buehne.get("_maus")])
	var unter = buehne.get("_unter_maus")
	if str(unter) != ziel:
		_fehler("Maus ueber „%s\", Spiel meldet „%s\"" % [ziel, unter])
	else:
		_sagen("Maus ueber „%s\" -- Spiel erkennt den Hotspot" % ziel)
	_geprueft += 1

	buehne.verstummen()
	_klick(wo, MOUSE_BUTTON_RIGHT)
	await get_tree().process_frame
	var erwartet: String = str(punkte[ziel].get("ansehen", ""))
	var gesagt: String = buehne._satz_jetzt()
	if gesagt != erwartet:
		_fehler("Rechtsklick auf „%s\" sagt „%s\", erwartet „%s\"" % [
			ziel, gesagt.substr(0, 40), erwartet.substr(0, 40)])
	else:
		_sagen("Rechtsklick auf „%s\": „%s…\"" % [ziel, gesagt.substr(0, 45)])
	buehne.verstummen()
	_geprueft += 1

	_klick(wo, MOUSE_BUTTON_LEFT)
	# Hinlaufen braucht Zeit -- das ist der Punkt. Bis zu 10 Sekunden Spielzeit.
	var rahmen: int = 0
	while buehne.get("_geht") and rahmen < 600:
		await get_tree().process_frame
		rahmen += 1
	if rahmen == 0:
		_fehler("Figur war schon da -- der Laufweg wurde nicht geprueft (Ziel %s)" % ziel)
	elif rahmen >= 600:
		_fehler("Figur kommt nicht an (Ziel %s)" % ziel)
	else:
		_sagen("Linksklick: hingelaufen in %d Rahmen (%.1f s)" % [rahmen, rahmen / 60.0])
	# Der Hotspot hatte `nehmen` -- also liegt der Gegenstand jetzt im Beutel. Das ist die
	# Probe, die zaehlt: nicht „es gab keinen Fehler", sondern „es ist etwas passiert".
	var was: String = str(punkte[ziel].get("nehmen", ""))
	if not Welt.im_beutel(was):
		_fehler("„%s\" benutzt, aber „%s\" ist nicht im Beutel" % [ziel, was])
	else:
		_sagen("„%s\" liegt im Beutel -- der ganze Weg Klick→Laufen→Wirkung steht" % was)
	_geprueft += 1
	_klicks += 2


## Der zweite Parameter von `push_input` ist der wichtigste in dieser Datei.
##
## `push_input(e)` erwartet FENSTER-Koordinaten und rechnet sie in Viewport-Koordinaten um.
## Das Projekt steht auf `window/stretch/mode = "canvas_items"`, also gibt es diese Umrechnung
## wirklich -- headless kam aus (755, 575) ein `_maus` von (15100, 11500), Faktor 20. Der
## Hotspot wurde korrekt nicht gefunden, weil dort keiner ist.
##
## Das ist die unangenehmste Sorte Testfehler: Er sah aus wie ein Fehler im Spiel. Schlimmer,
## der Linksklick „funktionierte" -- die Figur lief los, nur eben zu einem Punkt weit
## ausserhalb des Bildes, den `naechster_punkt` in die Lauffläche zurückholte. Ein gruener
## Test, der etwas anderes prueft als sein Name sagt.
##
## `true` heisst „die Koordinate ist schon lokal" und schaltet die Umrechnung ab.
func _maus_bewegen(wo: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = wo
	get_viewport().push_input(e, true)


func _klick(wo: Vector2, knopf: int) -> void:
	for gedrueckt in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = wo
		e.button_index = knopf
		e.pressed = gedrueckt
		get_viewport().push_input(e, true)


func _tagebuch(wurzel: Node) -> void:
	var tb = wurzel.get("_tagebuch")
	_taste(KEY_TAB)
	await get_tree().process_frame
	if not tb.visible:
		_fehler("Tab oeffnet das Tagebuch nicht")
	else:
		_sagen("Tab oeffnet das Tagebuch")
	_taste(KEY_ESCAPE)
	await get_tree().process_frame
	if tb.visible:
		_fehler("Escape schliesst das Tagebuch nicht")
	else:
		_sagen("Escape schliesst es wieder")
	_geprueft += 2


func _taste(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	get_viewport().push_input(e)


## Jede Schlussszene oeffnen und die erste Antwort waehlen -- das ist der Weg ins naechste
## Kapitel, und er geht durch die Szenen-Knoten, nicht durch die Daten.
func _gespraeche(wurzel: Node) -> void:
	var gv = wurzel.get("_gespraech")
	for k in range(1, KapitelDaten.letztes_ausgespieltes() + 1):
		var baum: String = str(KapitelDaten.schluss(k).get("gespraech", ""))
		if baum == "":
			continue
		Welt.neu()
		wurzel._gespraech_oeffnen(baum)
		await get_tree().process_frame
		if not gv.visible:
			_fehler("Schlussszene Kapitel %d oeffnet sich nicht (%s)" % [k, baum])
			continue
		var schritte: int = 0
		while gv.visible and schritte < 400:
			# Liegen Antworten vor, die erste waehlen; sonst die Lesepause ueberspringen.
			# `_rest` ist die Zeit, die ein Satz noch stehen bleibt -- die Probe liest nicht.
			if (gv.get("_antworten") as Array).size() > 0:
				gv._waehlen(0)
			else:
				# Ein laufender Satz wird vom Spieler weggeklickt, nicht ausgesessen.
				# `_rest` von aussen auf 0 zu setzen half NICHT: `_process` steigt bei
				# `_rest <= 0.0` sofort aus und der Satz blieb fuer immer stehen. Der Klick
				# ist der Weg, den das Spiel vorsieht.
				var e := InputEventMouseButton.new()
				e.position = Vector2(640.0, 360.0)
				e.button_index = MOUSE_BUTTON_LEFT
				e.pressed = true
				gv._eingabe(e)
			await get_tree().process_frame
			schritte += 1
		if schritte >= 400:
			_fehler("Schlussszene Kapitel %d endet nicht (%s)" % [k, baum])
		else:
			_sagen("Schlussszene K%d (%s): %d Schritte bis zum Ende" % [k, baum, schritte])
		_geprueft += 1


func _sagen(s: String) -> void:
	print("  ", s)


func _fehler(s: String) -> void:
	_meldungen.append(s)
	print("  FEHLER: ", s)


func _ende() -> void:
	print("──────────────────────────────────────────────────────────────")
	print("  %d Proben, %d Klicks, %d Fehler" % [_geprueft, _klicks, _meldungen.size()])
	for m in _meldungen:
		print("   * ", m)
	print("PROBE_FERTIG fehler=%d" % _meldungen.size())
	get_tree().quit(0 if _meldungen.is_empty() else 1)
