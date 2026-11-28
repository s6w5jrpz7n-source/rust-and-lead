extends Node2D
## Die Einmessung eines Ortes als Overlay — damit man sieht, ob sie zum Bild passt.
##
## Zeichnet begehbare Flaeche, Sperren, Hotspot-Rechtecke, Standpunkte und die Figur in ihrer
## vordersten und hintersten Groesse auf schwarzen Grund. Das Ergebnis wird ausserhalb mit
## ffmpeg ueber das gemalte Bild gelegt:
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --path godot res://tools/EinmessProbe.tscn -- platz
##   ffmpeg -i assets/orte/platz.webp -i <overlay.png> \
##       -filter_complex "[0:v]scale=1280:720[b];[b][1:v]blend=all_mode=screen" probe.png
##
## Warum nicht alles in Godot: Unter xvfb gibt der Software-Renderer Texturen weiss aus (siehe
## AbenteuerShot.gd). Gezeichnete Formen kommen durch, geladene Bilder nicht. Also zeichnet
## Godot nur die Linien, und das Zusammenlegen macht ffmpeg.

const OrtDaten = preload("res://scripts/OrtDaten.gd")
const Schrift = preload("res://scripts/Schrift.gd")

var _ort: String = "platz"

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_ort = str(args[0])
	await get_tree().process_frame
	queue_redraw()
	for _w in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var bild: Image = get_viewport().get_texture().get_image()
	var pfad: String = "user://einmess_%s.png" % _ort
	bild.save_png(pfad)
	print("  ", ProjectSettings.globalize_path(pfad))
	get_tree().quit()


func _draw() -> void:
	var f: Font = Schrift.schrift()
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color.BLACK, true)

	# Begehbare Flaeche
	var poly: PackedVector2Array = OrtDaten.flaeche(_ort)
	if poly.size() >= 3:
		draw_colored_polygon(poly, Color(0.0, 0.85, 0.35, 0.22))
		for i in range(poly.size()):
			draw_line(poly[i], poly[(i + 1) % poly.size()], Color(0.2, 1.0, 0.4), 3.0)
	for r in OrtDaten.gehfeld(_ort):
		draw_rect(r as Rect2, Color(0.2, 1.0, 0.4, 0.8), false, 2.0)

	# Sperren
	for sp in OrtDaten.sperren(_ort):
		draw_rect(sp as Rect2, Color(1.0, 0.25, 0.2, 0.30), true)
		draw_rect(sp as Rect2, Color(1.0, 0.3, 0.25), false, 3.0)

	# Hotspots
	for k in OrtDaten.punkte_alle(_ort):
		var p: Dictionary = OrtDaten.punkte_alle(_ort)[k] as Dictionary
		var rect: Rect2 = p.get("rect", Rect2()) as Rect2
		var tuer: bool = p.has("ziel")
		var farbe: Color = Color(1.0, 0.85, 0.2) if tuer else Color(0.4, 0.75, 1.0)
		draw_rect(rect, farbe, false, 2.5)
		draw_string(f, rect.position + Vector2(5.0, 19.0), str(k),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, farbe)
		var hin: Vector2 = OrtDaten.hingehen(_ort, str(k))
		draw_circle(hin, 7.0, farbe)
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y), hin,
			Color(farbe.r, farbe.g, farbe.b, 0.55), 1.5)

	# Fluchtpunkt
	var fp: Vector2 = OrtDaten.fluchtpunkt(_ort)
	draw_line(Vector2(0.0, fp.y), Vector2(1280.0, fp.y), Color(1.0, 1.0, 1.0, 0.35), 1.5)
	draw_line(fp + Vector2(-22.0, -22.0), fp + Vector2(22.0, 22.0), Color.WHITE, 2.5)
	draw_line(fp + Vector2(22.0, -22.0), fp + Vector2(-22.0, 22.0), Color.WHITE, 2.5)
	draw_string(f, fp + Vector2(28.0, 6.0), "Fluchtpunkt / Augenhoehe",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# Die Figur vorn und hinten -- der eigentliche Pruefpunkt der Tiefenstaffelung
	var t: Array = OrtDaten.ort(_ort).get("tiefe", OrtDaten.TIEFE_STANDARD) as Array
	for y in [float(t[0]) + 6.0, (float(t[0]) + float(t[1])) * 0.5, float(t[1]) - 6.0]:
		var x: float = _mitte_bei(y)
		if x < 0.0:
			continue
		_figur(Vector2(x, y), OrtDaten.groesse_bei(_ort, y), f)


## Die Mitte der begehbaren Flaeche auf dieser Hoehe, oder -1.
func _mitte_bei(y: float) -> float:
	var links: float = -1.0
	var rechts: float = -1.0
	for x in range(0, 1280, 4):
		if OrtDaten.begehbar(_ort, Vector2(float(x), y)):
			if links < 0.0:
				links = float(x)
			rechts = float(x)
	if links < 0.0:
		return -1.0
	return (links + rechts) * 0.5


func _figur(fuss: Vector2, m: float, f: Font) -> void:
	var h: float = OrtDaten.FIGUR_HOEHE * m
	var b: float = h * 0.34
	var farbe: Color = Color(1.0, 1.0, 1.0, 0.9)
	draw_colored_polygon(PackedVector2Array([
		fuss + Vector2(-b * 0.5, 0.0), fuss + Vector2(-b * 0.62, -h * 0.52),
		fuss + Vector2(-b * 0.38, -h * 0.74), fuss + Vector2(b * 0.38, -h * 0.74),
		fuss + Vector2(b * 0.62, -h * 0.52), fuss + Vector2(b * 0.5, 0.0)]),
		Color(1.0, 1.0, 1.0, 0.55))
	draw_circle(fuss + Vector2(0.0, -h * 0.82), h * 0.085, farbe)
	draw_line(fuss + Vector2(-b * 0.78, -h * 0.87), fuss + Vector2(b * 0.78, -h * 0.87),
		farbe, maxf(2.0, h * 0.035))
	draw_string(f, fuss + Vector2(b * 0.9, -4.0), "%.0f px" % h,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
