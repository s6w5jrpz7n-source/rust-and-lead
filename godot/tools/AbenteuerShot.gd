extends Node
## Bildschirmfotos der Abenteuer-Buehne — damit "sieht falsch aus" nachpruefbar wird.
##
## Aufruf:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --path godot res://tools/AbenteuerShot.tscn -- <ort> [<ort> ...]
##
## Ohne Argumente werden alle Orte abgelichtet. "reden:<baum>" lichtet stattdessen die
## Gespraechsansicht ab. Die Bilder landen in `user://`.
##
## ## Eine Falle, die zwei Anlaeufe gekostet hat
##
## **Texturen sind auf diesen Bildern immer weiss.** Portraits, Sinnbilder, Hintergrundbilder —
## alles, was aus einer Datei kommt, erscheint als weisse Flaeche. Das ist KEIN Fehler im
## Spiel: Unter `xvfb` mit dem Software-Renderer (llvmpipe) laedt Godot die Texturen, gibt sie
## aber nicht aus. Gegengeprueft mit `icon_gold.png`, das im Spiel nachweislich sichtbar ist —
## auch weiss. Wer hier ein weisses Portrait sieht, hat ein Darstellungsproblem des Werkzeugs
## gefunden und keines der Oberflaeche.
##
## Was auf diesen Bildern ALSO geprueft werden kann: Anordnung, Groessen, Textumbruch,
## gezeichnete Formen, Farben aus dem Farbkeil. Was NICHT: ob ein Bild richtig aussieht.

const AbenteuerWurzel = preload("res://scripts/AbenteuerWurzel.gd")
const OrtDaten = preload("res://scripts/OrtDaten.gd")
const Welt = preload("res://scripts/Welt.gd")

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	var wunsch: Array = []
	for a in OS.get_cmdline_user_args():
		wunsch.append(str(a))
	if wunsch.is_empty():
		wunsch = OrtDaten.alle()

	var wurzel: AbenteuerWurzel = AbenteuerWurzel.new()
	add_child(wurzel)
	await get_tree().process_frame

	for ort in wunsch:
		Welt.neu()
		# "reden:<baum>" lichtet die Gespraechsansicht ab statt der Buehne -- die Sinnbild-
		# Reihe laesst sich sonst nur von Hand pruefen, und genau sie ist die Bauform, um
		# die es bei Baphomets Fluch geht.
		if str(ort).begins_with("reden:"):
			var baum: String = str(ort).substr(6)
			wurzel._buehne.betreten("saloon")
			await get_tree().process_frame
			wurzel._gespraech_oeffnen(baum)
			# Bis die Saetze durch sind und die Auswahl steht: Die Reihe erscheint erst,
			# wenn der letzte Satz abgelaufen ist.
			for i in range(40):
				if wurzel._gespraech._saetze.is_empty():
					break
				wurzel._gespraech._saetze.remove_at(0)
				wurzel._gespraech._satz_starten()
			wurzel._gespraech._ueber = 0
			wurzel._gespraech._flaeche.queue_redraw()
			# Mehrere Bilder warten: Auf llvmpipe ist eine Textur im ersten Bild nach dem
			# Laden noch weiss, und dann zeigt das Foto einen Fehler, den es nicht gibt.
			for _w in range(8):
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var b2: Image = get_viewport().get_texture().get_image()
			var pf2: String = "user://abenteuer_reden_%s.png" % baum
			b2.save_png(pf2)
			print("  ", ProjectSettings.globalize_path(pf2))
			wurzel._gespraech_schliessen()
			continue
		wurzel._buehne.betreten(str(ort))
		# Zwei Bilder warten: eins, damit `queue_redraw` greift, und eins, damit das
		# gezeichnete Bild auch im Puffer steht. Mit nur einem bekommt man das vorige.
		for _w2 in range(8):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var bild: Image = get_viewport().get_texture().get_image()
		var pfad: String = "user://abenteuer_%s.png" % str(ort)
		bild.save_png(pfad)
		print("  ", ProjectSettings.globalize_path(pfad))
	print("fertig")
	get_tree().quit()
