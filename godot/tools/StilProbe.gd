extends Node2D
## Drei Stilrichtungen fuer die gemalten Hintergruende — als Bild, nicht als Beschreibung.
##
## ## Wozu
##
## Die Hintergrundbilder sind die teuerste Entscheidung dieses Projekts: Sind zwanzig Stueck
## gemalt, aendert man die Richtung nicht mehr. Ein Prompt laesst sich in einer Minute
## umschreiben, zwanzig fertige Bilder nicht.
##
## Was eine Beschreibung NICHT leisten kann: zeigen, wie dunkel „dunkel" ist, wie viel vom Bild
## die Schatten fressen, ob ein Hotspot darin noch zu finden ist. Genau das entscheidet sich
## hier. Also wird derselbe Ort dreimal gezeichnet — gleiche Formen, gleiche Anordnung, nur
## die Behandlung von Licht, Kontrast und Linie ist anders.
##
## ## Was die Proben zeigen und was nicht
##
## **Zeigen:** Helligkeitsverteilung, Kontrastumfang, wie viel kuehler Akzent, wie stark die
## Figur sich abhebt, ob die Hotspot-Zonen lesbar bleiben.
##
## **Nicht zeigen:** Pinselduktus. Ob gemalt wie Gouache oder sauber wie Vektor, entscheidet
## das Bildmodell, nicht dieser Zeichner. Dafuer stehen in `docs/ABENTEUER.md` die Worte.
##
## ## Aufruf
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --path godot res://tools/StilProbe.tscn
##
## Die Bilder landen als `user://stil_a.png`, `stil_b.png`, `stil_c.png`.

const Palette = preload("res://scripts/Palette.gd")
const Schrift = preload("res://scripts/Schrift.gd")
const OrtDaten = preload("res://scripts/OrtDaten.gd")

const B: float = 1280.0
const H: float = 720.0
const HORIZONT: float = OrtDaten.BUEHNE_HORIZONT   # 430

## Welche Probe gerade gezeichnet wird.
var _stil: int = 0

const NAMEN: Array = ["a_gaslicht", "b_oelschwarz", "c_blaupause"]
const TITEL: Array = [
	"A — GASLICHT   ·   gemalt, mittlere Toene, hoechste Lesbarkeit",
	"B — OELSCHWARZ   ·   Intro-treu, Silhouetten gegen Gegenlicht",
	"C — BLAUPAUSE   ·   gemalt plus Konzern-Risszeichnung",
]


func _ready() -> void:
	get_window().size = Vector2i(int(B), int(H))
	await get_tree().process_frame
	for i in range(3):
		_stil = i
		queue_redraw()
		for _w in range(6):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var bild: Image = get_viewport().get_texture().get_image()
		var pfad: String = "user://stil_%s.png" % str(NAMEN[i])
		bild.save_png(pfad)
		print("  ", ProjectSettings.globalize_path(pfad))
	print("fertig")
	get_tree().quit()


func _draw() -> void:
	_himmel()
	_ferne()
	_gebaeude()
	_boden()
	_requisiten()
	_figur()
	if _stil == 2:
		_risszeichnung()
	_vignette()
	_beschriftung()


# ── Die drei Behandlungen als Zahlen ──────────────────────────────────────────
#
# Jede Richtung ist im Kern ein Satz Regler. Sie hier nebeneinanderzustellen ist der
# eigentliche Zweck dieser Datei: Man sieht, worin sie sich unterscheiden, bevor man sieht,
# wie es aussieht.

## Wie hell die Masse der Gebaeude ist (Anteil auf dem Farbkeil).
func _masse() -> float:
	match _stil:
		0: return 0.42   # Gaslicht: Gebaeude liegen in den mittleren Toenen
		1: return 0.08   # Oelschwarz: fast Silhouette
		_: return 0.38


## Wie hell der Himmel am Horizont wird.
func _horizont_hell() -> float:
	match _stil:
		0: return 0.78
		1: return 1.00   # hartes Gegenlicht
		_: return 0.74


## Wie weit der Himmel nach oben abdunkelt.
func _himmel_oben() -> float:
	match _stil:
		0: return 0.46
		1: return 0.14
		_: return 0.42


## Wie stark Kanten vom Gegenlicht gesaeumt werden.
func _saum() -> float:
	match _stil:
		0: return 0.18
		1: return 0.85
		_: return 0.22


## Wie stark die Ecken abgedunkelt werden.
func _vignette_staerke() -> float:
	match _stil:
		0: return 0.22
		1: return 0.58
		_: return 0.24


# ── Zeichnen ──────────────────────────────────────────────────────────────────

func _himmel() -> void:
	# In zwanzig Baendern statt mit einem Verlaufs-Shader: Das Ergebnis ist dasselbe, und es
	# laeuft ohne eine einzige Ressource.
	var oben: float = _himmel_oben()
	var unten: float = _horizont_hell()
	for i in range(20):
		var a: float = float(i) / 19.0
		draw_rect(Rect2(0.0, HORIZONT * float(i) / 20.0, B, HORIZONT / 20.0 + 1.0),
			Palette.keil_bei(lerpf(oben, unten, a * a)))


## Die Kraterwand am Horizont — in jedem Aussenbild dieselbe Landmarke (GDD 1.4).
func _ferne() -> void:
	var farbe: Color = Palette.keil_bei(lerpf(_masse(), _horizont_hell(), 0.45))
	var punkte: PackedVector2Array = PackedVector2Array()
	punkte.append(Vector2(0.0, HORIZONT))
	var hoehen: Array = [118.0, 96.0, 152.0, 74.0, 134.0, 88.0, 166.0, 102.0, 126.0]
	for i in range(hoehen.size()):
		var x: float = B * float(i) / float(hoehen.size() - 1)
		punkte.append(Vector2(x, HORIZONT - float(hoehen[i])))
	punkte.append(Vector2(B, HORIZONT))
	draw_colored_polygon(punkte, farbe)


func _gebaeude() -> void:
	var masse: Color = Palette.keil_bei(_masse())
	var saum: Color = Palette.keil_bei(minf(_horizont_hell() + 0.08, 1.0))

	# Saloon links, Schmiede rechts, Lazarettzelt in der Mitte dahinter.
	_haus(Rect2(96.0, 170.0, 300.0, 262.0), masse, saum, 3, true)
	_haus(Rect2(886.0, 212.0, 300.0, 220.0), masse.darkened(0.12), saum, 2, false)
	_zelt(Rect2(470.0, 250.0, 330.0, 182.0), masse.lightened(0.04), saum)


## Ein Haus: Masse, Dachkante, Fenster, Lichtsaum an der dem Horizont zugewandten Kante.
func _haus(r: Rect2, masse: Color, saum: Color, fenster: int, veranda: bool) -> void:
	draw_rect(r, masse, true)
	# Dachkante
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(-18.0, 0.0),
		r.position + Vector2(r.size.x * 0.5, -34.0),
		r.position + Vector2(r.size.x + 18.0, 0.0),
		r.position + Vector2(r.size.x, 14.0),
		r.position + Vector2(0.0, 14.0)]), masse.lightened(0.06))

	# Fenster. Bei Oelschwarz sind sie die einzige Information im Haus — deshalb leuchten
	# sie dort, waehrend sie bei Gaslicht nur dunkle Loecher sind.
	for i in range(fenster):
		var fx: float = r.position.x + r.size.x * (float(i) + 0.8) / (float(fenster) + 0.6)
		var f: Rect2 = Rect2(fx, r.position.y + 58.0, 46.0, 62.0)
		if _stil == 1:
			draw_rect(f, Palette.keil_bei(0.86), true)
			draw_rect(f.grow(5.0), Color(Palette.SANDLICHT.r, Palette.SANDLICHT.g,
				Palette.SANDLICHT.b, 0.16), true)
		else:
			draw_rect(f, Palette.keil_bei(maxf(_masse() - 0.26, 0.0)), true)
			draw_rect(f, saum.darkened(0.3), false, 2.0)

	if veranda:
		draw_rect(Rect2(r.position.x - 10.0, r.end.y - 8.0, r.size.x + 20.0, 10.0),
			masse.darkened(0.25), true)
		for i in range(4):
			var px: float = r.position.x + 12.0 + float(i) * (r.size.x - 24.0) / 3.0
			draw_rect(Rect2(px, r.end.y - 92.0, 11.0, 84.0), masse.darkened(0.3), true)

	# Lichtsaum an der rechten Kante
	var s: float = _saum()
	if s > 0.05:
		draw_rect(Rect2(r.end.x - 4.0, r.position.y, 4.0, r.size.y),
			Color(saum.r, saum.g, saum.b, s), true)
		draw_rect(Rect2(r.position.x, r.position.y, 3.0, r.size.y),
			Color(saum.r, saum.g, saum.b, s * 0.35), true)


func _zelt(r: Rect2, masse: Color, saum: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(0.0, r.size.y),
		r.position + Vector2(r.size.x * 0.5, 0.0),
		r.position + Vector2(r.size.x, r.size.y)]), masse)
	draw_colored_polygon(PackedVector2Array([
		r.position + Vector2(r.size.x * 0.5, 0.0),
		r.position + Vector2(r.size.x, r.size.y),
		r.position + Vector2(r.size.x * 0.72, r.size.y)]), masse.darkened(0.14))
	var s: float = _saum()
	if s > 0.05:
		draw_line(r.position + Vector2(r.size.x * 0.5, 0.0),
			r.position + Vector2(r.size.x, r.size.y),
			Color(saum.r, saum.g, saum.b, s), 3.0)


func _boden() -> void:
	# Der Laufstreifen. Er ist in jeder Richtung der hellste Teil der unteren Bildhaelfte —
	# nicht aus Geschmack: Die Figur ist dunkel, und sie muss darauf zu sehen sein.
	var hell: float = 0.0
	match _stil:
		0: hell = 0.52
		1: hell = 0.34
		_: hell = 0.48
	for i in range(14):
		var a: float = float(i) / 13.0
		draw_rect(Rect2(0.0, HORIZONT + (H - HORIZONT) * a, B, (H - HORIZONT) / 14.0 + 1.0),
			Palette.keil_bei(lerpf(hell, maxf(hell - 0.2, 0.02), a)))
	draw_line(Vector2(0.0, HORIZONT), Vector2(B, HORIZONT),
		Palette.keil_bei(maxf(_masse() - 0.1, 0.0)), 3.0)

	# Spurrinnen, damit der Streifen nicht wie eine Farbflaeche liegt.
	for i in range(5):
		var y: float = HORIZONT + 42.0 + float(i) * 54.0
		draw_line(Vector2(0.0, y), Vector2(B, y + float(i % 2) * 6.0 - 3.0),
			Color(0.0, 0.0, 0.0, 0.07), 2.0)


func _requisiten() -> void:
	var masse: Color = Palette.keil_bei(maxf(_masse() - 0.06, 0.0))
	var saum: Color = Palette.keil_bei(minf(_horizont_hell() + 0.08, 1.0))
	# Brunnen
	draw_rect(Rect2(556.0, 452.0, 176.0, 104.0), masse, true)
	draw_rect(Rect2(548.0, 442.0, 192.0, 18.0), masse.lightened(0.08), true)
	draw_line(Vector2(566.0, 442.0), Vector2(566.0, 352.0), masse, 8.0)
	draw_line(Vector2(722.0, 442.0), Vector2(722.0, 352.0), masse, 8.0)
	draw_line(Vector2(560.0, 356.0), Vector2(728.0, 356.0), masse, 9.0)
	var s: float = _saum()
	if s > 0.05:
		draw_line(Vector2(726.0, 442.0), Vector2(726.0, 352.0),
			Color(saum.r, saum.g, saum.b, s), 3.0)
	# Kinetoskop-Saeule
	draw_rect(Rect2(244.0, 392.0, 58.0, 170.0), masse.darkened(0.08), true)
	draw_circle(Vector2(273.0, 418.0), 15.0, Palette.keil_bei(0.2))
	if _stil != 1:
		draw_circle(Vector2(273.0, 418.0), 7.0, Palette.GALVANISCH)
	else:
		draw_circle(Vector2(273.0, 418.0), 9.0, Palette.GALVANISCH)
		draw_circle(Vector2(273.0, 418.0), 20.0,
			Color(Palette.GALVANISCH.r, Palette.GALVANISCH.g, Palette.GALVANISCH.b, 0.18))
	# Auftragsbrett
	draw_rect(Rect2(900.0, 404.0, 128.0, 150.0), masse.darkened(0.05), true)
	for i in range(5):
		draw_rect(Rect2(912.0 + float(i % 3) * 38.0, 416.0 + float(i / 3) * 44.0, 30.0, 36.0),
			Palette.keil_bei(0.72), true)


## Die Figur an derselben Stelle wie im Spiel — der einzige Massstab, der zaehlt.
func _figur() -> void:
	var fuss: Vector2 = Vector2(640.0, 620.0)
	var h: float = OrtDaten.FIGUR_HOEHE * OrtDaten.groesse_bei("platz", fuss.y)
	var b: float = h * 0.34
	var grund: Color = Palette.keil_bei(_stil_bodenhelligkeit())
	var farbe: Color = Palette.abheben(Palette.OELSCHWARZ, grund)

	draw_set_transform(fuss, 0.0, Vector2(1.0, 0.26))
	draw_circle(Vector2.ZERO, b * 0.8, Color(0.0, 0.0, 0.0, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_colored_polygon(PackedVector2Array([
		fuss + Vector2(-b * 0.5, 0.0),
		fuss + Vector2(-b * 0.62, -h * 0.52),
		fuss + Vector2(-b * 0.38, -h * 0.74),
		fuss + Vector2(b * 0.38, -h * 0.74),
		fuss + Vector2(b * 0.62, -h * 0.52),
		fuss + Vector2(b * 0.5, 0.0)]), farbe)
	draw_circle(fuss + Vector2(0.0, -h * 0.82), h * 0.085, farbe)
	draw_line(fuss + Vector2(-b * 0.78, -h * 0.87), fuss + Vector2(b * 0.78, -h * 0.87),
		farbe, maxf(3.0, h * 0.036))
	# Gegenlichtsaum auf der Figur — bei Oelschwarz ist er das, was sie ueberhaupt lesbar macht.
	var s: float = _saum()
	if s > 0.3:
		var saum: Color = Palette.keil_bei(0.95)
		draw_line(fuss + Vector2(b * 0.5, 0.0), fuss + Vector2(b * 0.62, -h * 0.52),
			Color(saum.r, saum.g, saum.b, s * 0.8), 3.0)
		draw_line(fuss + Vector2(b * 0.62, -h * 0.52), fuss + Vector2(b * 0.38, -h * 0.74),
			Color(saum.r, saum.g, saum.b, s * 0.8), 3.0)


func _stil_bodenhelligkeit() -> float:
	match _stil:
		0: return 0.40
		1: return 0.20
		_: return 0.36


## Nur Richtung C: die Konzern-Risszeichnung ueber dem gemalten Bild.
##
## Diegetisch und nicht Dekoration — der Konzern vermisst und stempelt alles, auch Haeuser,
## die ihm nicht gehoeren. Die Linien liegen DARUEBER, als waeren sie auf eine Glasplatte
## gezeichnet, durch die man den Ort sieht.
func _risszeichnung() -> void:
	var linie: Color = Color(Palette.GALVANISCH.r, Palette.GALVANISCH.g,
		Palette.GALVANISCH.b, 0.34)
	var fein: Color = Color(Palette.GALVANISCH.r, Palette.GALVANISCH.g,
		Palette.GALVANISCH.b, 0.17)

	# Masslinien am Saloon
	draw_line(Vector2(96.0, 150.0), Vector2(396.0, 150.0), linie, 1.5)
	draw_line(Vector2(96.0, 142.0), Vector2(96.0, 158.0), linie, 1.5)
	draw_line(Vector2(396.0, 142.0), Vector2(396.0, 158.0), linie, 1.5)
	draw_line(Vector2(70.0, 170.0), Vector2(70.0, 432.0), linie, 1.5)

	# Zahnrad-Schema ueber der Schmiede
	var m: Vector2 = Vector2(1036.0, 300.0)
	draw_arc(m, 62.0, 0.0, TAU, 48, linie, 1.5)
	draw_arc(m, 44.0, 0.0, TAU, 40, fein, 1.2)
	draw_arc(m, 14.0, 0.0, TAU, 20, linie, 1.5)
	for i in range(12):
		var w: float = TAU * float(i) / 12.0
		draw_line(m + Vector2(cos(w), sin(w)) * 62.0,
			m + Vector2(cos(w), sin(w)) * 74.0, linie, 2.0)

	# Schnittlinie durch den Brunnen, mit Hilfslinien nach unten
	draw_line(Vector2(540.0, 352.0), Vector2(748.0, 352.0), fein, 1.2)
	for i in range(9):
		var x: float = 548.0 + float(i) * 24.0
		draw_line(Vector2(x, 356.0), Vector2(x, 372.0), fein, 1.0)

	# Raster ueber dem ganzen Bild, sehr schwach
	for i in range(13):
		draw_line(Vector2(float(i) * 100.0, 0.0), Vector2(float(i) * 100.0, HORIZONT),
			Color(fein.r, fein.g, fein.b, 0.07), 1.0)

	# Stempelrahmen oben rechts
	var st: Rect2 = Rect2(1038.0, 36.0, 206.0, 58.0)
	draw_rect(st, linie, false, 1.8)
	draw_line(st.position + Vector2(0.0, 30.0), st.position + Vector2(st.size.x, 30.0),
		fein, 1.2)
	draw_string(Schrift.schrift(), st.position + Vector2(10.0, 21.0),
		"IRON RAIL CONSOLIDATED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, linie)
	draw_string(Schrift.schrift(), st.position + Vector2(10.0, 50.0),
		"AUFNAHME 7 — RUSTWATER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, fein)


func _vignette() -> void:
	var staerke: float = _vignette_staerke()
	# Von aussen nach innen in Rahmen — billig und reicht voellig, weil die Vignette ohnehin
	# weich sein soll.
	for i in range(26):
		var a: float = float(i) / 25.0
		var rand: float = 26.0 * float(26 - i)
		draw_rect(Rect2(-rand, -rand, B + rand * 2.0, H + rand * 2.0),
			Color(0.0, 0.0, 0.0, staerke * 0.035 * (1.0 - a)), false, 54.0)


func _beschriftung() -> void:
	var f: Font = Schrift.schrift()
	var kasten: Rect2 = Rect2(0.0, H - 44.0, B, 44.0)
	draw_rect(kasten, Color(0.0, 0.0, 0.0, 0.72), true)
	draw_string(f, Vector2(22.0, H - 15.0), str(TITEL[_stil]),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.SANDLICHT)
