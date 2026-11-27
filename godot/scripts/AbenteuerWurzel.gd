extends Node2D
## Die Wurzel des Abenteuers — hält Bühne, Gespräch und Tagebuch zusammen.
##
## ## Warum es diese Datei gibt
##
## Damit `AbenteuerView` nichts über Gespräche und `GespraechView` nichts über die Bühne weiß.
## Die beiden reden nur über Signale, und zwar hierüber. Der Nutzen zeigt sich beim Testen: Man
## kann ein Gespräch öffnen, ohne dass ein Ort geladen ist, und einen Ort betreten, ohne dass
## ein Gesprächsbaum existiert. Hinge beides direkt aneinander, ginge keins von beidem.
##
## ## Was hier an Eingabe liegt
##
## Nur das, was überall gilt: Tagebuch auf und zu. Alles andere gehört in die Ansicht, die
## gerade oben liegt.

const AbenteuerView = preload("res://scripts/AbenteuerView.gd")
const GespraechView = preload("res://scripts/GespraechView.gd")
const TagebuchView = preload("res://scripts/TagebuchView.gd")
const KapitelDaten = preload("res://scripts/KapitelDaten.gd")
const OrtDaten = preload("res://scripts/OrtDaten.gd")
const Palette = preload("res://scripts/Palette.gd")
const Welt = preload("res://scripts/Welt.gd")

var _buehne: AbenteuerView = null
var _gespraech: GespraechView = null
var _tagebuch: TagebuchView = null


func _ready() -> void:
	_buehne = AbenteuerView.new()
	_buehne.gespraech_gewuenscht.connect(_gespraech_oeffnen)
	_buehne.tagebuch_gewuenscht.connect(_tagebuch_oeffnen)
	_buehne.kapitel_schluss.connect(_schluss_angesagt)
	add_child(_buehne)

	_gespraech = GespraechView.new()
	_gespraech.visible = false
	_gespraech.fertig.connect(_gespraech_schliessen)
	add_child(_gespraech)

	_tagebuch = TagebuchView.new()
	_tagebuch.visible = false
	_tagebuch.geschlossen.connect(_tagebuch_schliessen)
	add_child(_tagebuch)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not (e as InputEventKey).pressed:
		return
	var taste: int = (e as InputEventKey).keycode
	# Tab und J: beides, weil Tab auf dem Rechner naheliegt und J sich merken lässt. Escape
	# schliesst nur -- es darf nie etwas öffnen, sonst ist es keine Fluchttaste mehr.
	if taste == KEY_TAB or taste == KEY_J:
		if _tagebuch.visible:
			_tagebuch_schliessen()
		elif not _gespraech.visible:
			_tagebuch_oeffnen()
		get_viewport().set_input_as_handled()
	elif taste == KEY_ESCAPE and _tagebuch.visible:
		_tagebuch_schliessen()
		get_viewport().set_input_as_handled()


func _gespraech_oeffnen(baum: String) -> void:
	_buehne.set_process_unhandled_input(false)
	# Der angefangene Satz der Buehne gehoert nicht ins Gespraech. Ohne das stand im ersten
	# Bildschirmfoto "Gatling-Saloon" quer unter Mabels Sprechtafel.
	_buehne.verstummen()
	_gespraech.visible = true
	_gespraech.beginnen(baum)


func _gespraech_schliessen() -> void:
	_gespraech.visible = false
	_buehne.set_process_unhandled_input(true)
	# Ein Gespräch kann eine Mission abgeschlossen haben, ohne dass danach etwas angeklickt
	# wird. Also hier prüfen und nicht erst beim nächsten Klick.
	for fertig in Welt.missionen_pruefen():
		_buehne.sagen(["Erledigt: %s" % fertig])
	_buehne.queue_redraw()


func _tagebuch_oeffnen() -> void:
	_buehne.set_process_unhandled_input(false)
	_tagebuch.zeigen()


func _tagebuch_schliessen() -> void:
	_tagebuch.visible = false
	_buehne.set_process_unhandled_input(true)


## Alle Stränge eines Kapitels sind abgearbeitet — die Schlussszene steht offen.
##
## Das Spiel schiebt den Spieler nicht hin. Es sagt ihm, wohin, und er geht selbst. Das ist der
## Unterschied zwischen einem Adventure und einer Abfolge von Zwischensequenzen, und er kostet
## genau diese drei Zeilen.
func _schluss_angesagt(nummer: int) -> void:
	var s: Dictionary = KapitelDaten.schluss(nummer)
	var ort: String = str(s.get("ort", ""))
	if ort == "":
		return
	_buehne.sagen([str(s.get("anriss", ""))])
