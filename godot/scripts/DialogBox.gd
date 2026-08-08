extends Control
## Die Sprechtafel — was ein NPC sagt, steht unten im Bild und nicht in einer Blase.
##
## Vorher lief jedes Gespräch über `_say()`, also über dieselbe Einblendung, die auch „Beutel
## voll" und „Munition leer" meldet. Zwei völlig verschiedene Dinge in derselben Zeile: Eine
## Systemmeldung verschwindet nach zwei Sekunden von selbst, ein Gespräch wartet auf einen.
##
## Vorlage ist Diablo Immortal (Bilder vom Auftraggeber): **Bildnis links, Name in Versalien,
## Text daneben, unten am Bildrand über die ganze Breite.** Das funktioniert dort aus drei
## Gründen, und alle drei gelten hier genauso:
##
##  1. **Unten.** Die Figuren stehen in der Bildmitte — eine Sprechblase an ihnen verdeckt genau
##     das, was die Nahaufnahme zeigen soll. Der untere Rand ist die einzige Fläche, die man
##     zudecken darf.
##  2. **Bildnis.** Es sagt in einem Blick, WER spricht, ohne dass man den Namen lesen muss. In
##     einer Stadt mit drei Auftraggebern ist das der Unterschied zwischen „jemand redet" und
##     „Mabel redet".
##  3. **Sie wartet.** Der Text steht, bis man tippt. Deshalb der Winkel unten rechts — er ist
##     das einzige Bedienelement und sagt „es geht weiter, wenn du willst".
##
## GEZEICHNET wie die Puppe und das Beutel-Raster. Sobald es Grafiken gibt (`docs/PROMPTS_UI.md`),
## ersetzt `set_frame()` den gemalten Rahmen und `set_portrait()` das Platzhalter-Bildnis, ohne
## dass sich am Rest etwas ändert.

signal dismissed

const UiAssets = preload("res://scripts/UiAssets.gd")

## Maße bei 1280×720 Bezugsauflösung.
const MARGIN: float = 22.0        # Abstand zum Bildrand
## Mindesthöhe. Die Tafel WÄCHST mit dem Text — der erste Entwurf stand fest auf 138 px, und
## sobald eine Quest ihre Zeile „⊕ Das Rattengestrüpp — 559 m" mitbrachte, wurde die unterste
## Zeile abgeschnitten. Ein Kasten, der Text verschluckt, ist schlimmer als ein hoher Kasten.
const BOX_H: float = 168.0
const BOX_H_MAX: float = 300.0
const PORTRAIT: float = 108.0     # Kantenlänge des Bildnisses ohne Rahmengrafik
const PAD: float = 15.0

## Farben. Pergament, aber ein verrußtes — reines Diablo-Creme wäre in dieser Welt ein
## Fremdkörper; hier ist alles Papier seit dreißig Jahren im Kesselrauch gehangen.
const PAPER: Color = Color(0.84, 0.79, 0.66)
const PAPER_DARK: Color = Color(0.74, 0.68, 0.55)
const IRON: Color = Color(0.13, 0.11, 0.10)
const BRASS: Color = Color(0.68, 0.54, 0.28)
const INK: Color = Color(0.16, 0.13, 0.10)

var speaker: String = ""
var line: String = ""

## Anteil der Bildhöhe, den das Rahmenband der Tafelgrafik einnimmt — die 9-Patch-Ränder.
##
## Warum überhaupt 9-Patch: Die Tafel ist im Spiel rund 1236 px breit und je nach Text 138 bis
## 268 px hoch, die gelieferte Grafik hat ein festes Seitenverhältnis. Einfach gestreckt würden
## die Nieten in den Ecken zu Ovalen und das Rahmenband oben und unten verschieden dick. Beim
## 9-Patch bleiben die vier Ecken unangetastet, gestreckt wird nur die Mitte.
const FRAME_BORDER_RATIO: float = 0.155

## Gemessene Breite des Rahmenbands in Texturpixeln (0 = keine Grafik). Der Inhalt rückt darum
## nach innen — sonst läge der Text auf dem Eisen statt auf dem Pergament.
var _band: float = 0.0

var _portrait: Texture2D = null
var _portrait_region: Rect2 = Rect2()   # der wirklich bemalte Teil, siehe `_set_portrait`
var _portrait_frame: Texture2D = null
var _frame: Texture2D = null
var _label: Label
var _blink: float = 0.0


## Aufbau in `_init` und nicht in `_ready`.
##
## `_ready` laeuft erst, wenn das Steuerelement im Szenenbaum haengt. Eine frisch erzeugte
## Sprechtafel waere bis dahin halb fertig: `visible` stuende auf `true` (Godots Vorgabe) und
## `_label` waere `null` — der erste Satz haette sie zum Absturz gebracht. `_init` laeuft bei
## `new()`, also immer. Das ist nicht nur fuer Tests richtig, sondern fuer jeden Aufrufer.
func _init() -> void:
	# Ganze Bildbreite unten. `set_anchors_AND_OFFSETS_preset` — die kurze Variante lässt die
	# Ränder auf 0 und das Ergebnis wäre wieder ein 0×0-Steuerelement (dieselbe Falle wie bei
	# allen anderen Vollbild-Oberflächen).
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = MARGIN
	offset_right = -MARGIN
	offset_top = -(BOX_H + MARGIN)
	offset_bottom = -MARGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# Der Fließtext als echtes Label, nicht gezeichnet: Umbruch über mehrere Zeilen ist die eine
	# Sache, die `draw_string` nicht kann und die hier jedes Mal gebraucht wird.
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", INK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Der Rahmen liegt UNTER dem Text. Als eigener Knoten und nicht in `_draw`, weil ein
	# `NinePatchRect` das Zerlegen in neun Kacheln von sich aus kann — von Hand waeren es
	# neun `draw_texture_rect_region`-Aufrufe mit vier Randbreiten.
	set_frame(_load_ui("dialog_frame"))
	add_child(_label)
	_portrait_frame = _load_ui("portrait_frame")
	resized.connect(_layout)
	_layout()


## Das Bildnis ÜBERSTEHT die Tafel oben und unten.
##
## So macht es die Vorlage, und es hat einen handfesten Grund: Das Eisenband frisst oben und
## unten je 37 Pixel. Ein Bildnis innerhalb des Pergaments wäre bei einer 168 px hohen Tafel
## noch 94 px groß — kleiner als der Text daneben hoch ist. Übersteht es, bekommt es die volle
## Tafelhöhe plus einen Daumen, und die Tafel wirkt nebenbei weniger wie ein Kasten.
func _portrait_rect() -> Rect2:
	var kante: float = size.y + 22.0 if _frame != null else PORTRAIT
	var y: float = (size.y - kante) * 0.5
	return Rect2(Vector2(_inset() * 0.6, y), Vector2(kante, kante))


## Abstand vom Tafelrand zum Inhalt. Mit Rahmengrafik das gemessene Band plus etwas Luft, ohne
## sie der gezeichnete Rahmen.
func _inset() -> float:
	return (_band + 10.0) if _frame != null else PAD


func _layout() -> void:
	if _label == null:
		return
	var p: Rect2 = _portrait_rect()
	var x: float = p.end.x + 16.0
	_label.position = Vector2(x, _inset() + 24.0)
	_label.size = Vector2(maxf(_text_width(), 40.0), maxf(size.y - _inset() * 2.0 - 24.0, 20.0))
	_label.custom_minimum_size = _label.size


## Eine Zeile zeigen. `giver` ist die Auftraggeber-Id — daraus wird das Bildnis gesucht.
func show_line(name_text: String, body: String, giver: String = "") -> void:
	speaker = name_text
	line = body
	_label.text = body
	_set_portrait(_load_ui("portrait_" + giver) if giver != "" else null)
	offset_top = -(_needed_height(body) + MARGIN)
	visible = true
	_blink = 0.0
	_layout()
	queue_redraw()


## Wie hoch muss die Tafel für diesen Text sein?
##
## GEMESSEN am Umbruch, nicht an der Zeichenzahl. `get_multiline_string_size` rechnet mit
## derselben Schrift und derselben Breite, mit der das Label gleich umbricht — jede andere
## Schätzung liegt bei einem Text mit Sonderzeichen und langen Ortsnamen daneben.
func _needed_height(body: String) -> float:
	var schrift: Font = get_theme_default_font()
	if schrift == null:
		return BOX_H
	var breite: float = maxf(_text_width(), 80.0)
	var h: float = schrift.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_LEFT,
		breite, 16).y
	return clampf(_inset() * 2.0 + 30.0 + h, BOX_H, BOX_H_MAX)


## Breite der Textspalte. Steht in einer eigenen Funktion, weil sie an ZWEI Stellen gebraucht
## wird — beim Messen und beim Setzen. Zwei Rechnungen liefen hier garantiert auseinander.
func _text_width() -> float:
	# Bei einem Control, das noch nie umbrochen wurde, ist `size.x` 0. Dann gilt die
	# Bezugsauflösung minus der beiden Ränder.
	var voll: float = size.x if size.x > 1.0 else 1280.0 - MARGIN * 2.0
	var breite_bildnis: float = (BOX_H + 22.0) if _frame != null else PORTRAIT
	return voll - (_inset() * 0.6 + breite_bildnis + 16.0) - _inset()


func hide_box() -> void:
	if not visible:
		return
	visible = false
	dismissed.emit()


## Wird der Tipp hier verbraucht? Die Tafel schluckt alles, was auf ihr landet — sonst startet
## derselbe Tipp, der weiterblättert, gleich noch den Joystick.
func hits(at: Vector2) -> bool:
	return visible and Rect2(global_position, size).has_point(at)


## Optionale Grafiken. Solange keine da sind, zeichnet die Tafel sich selbst; liegt eine Datei,
## wird sie genommen. Kein Fehler, kein Platzhalter-Rot — die Oberfläche funktioniert in beiden
## Zuständen, und der Auftraggeber kann liefern, wann er will.
static func _load_ui(basename: String) -> Texture2D:
	return UiAssets.texture(basename)


func set_frame(tex: Texture2D) -> void:
	_frame = tex
	_band = float(_messe_band(tex)) if tex != null else 0.0
	queue_redraw()


## Die Neunteilung von Hand statt als `NinePatchRect`-Kindknoten.
##
## Der Kindknoten war der naheliegende Weg und der falsche: In Godot zeichnet ein Control ERST
## sich selbst und DANN seine Kinder. Der Rahmen lag damit ueber Bildnis, Name und Winkel — im
## Bild war von allen dreien nichts zu sehen, nur der Teil des Bildnisrahmens, der ueber die
## Tafel hinausragte. Neun `draw_texture_rect_region`-Aufrufe an dieser Stelle kosten nichts
## und liegen garantiert UNTER dem Inhalt.
##
## Die vier Ecken bleiben in Originalgroesse, die vier Kanten werden je in einer Richtung
## gestreckt, die Mitte in beiden. Genau das macht ein 9-Patch.
func _draw_nine(tex: Texture2D, ziel: Rect2, rand: float) -> void:
	var tg: Vector2 = tex.get_size()
	var r: float = minf(rand, minf(tg.x, tg.y) * 0.45)
	var sx: Array = [0.0, r, tg.x - r, tg.x]
	var sy: Array = [0.0, r, tg.y - r, tg.y]
	var zx: Array = [ziel.position.x, ziel.position.x + r, ziel.end.x - r, ziel.end.x]
	var zy: Array = [ziel.position.y, ziel.position.y + r, ziel.end.y - r, ziel.end.y]
	for i in 3:
		for j in 3:
			var q := Rect2(Vector2(sx[i], sy[j]),
				Vector2(sx[i + 1] - sx[i], sy[j + 1] - sy[j]))
			var z := Rect2(Vector2(zx[i], zy[j]),
				Vector2(zx[i + 1] - zx[i], zy[j + 1] - zy[j]))
			if q.size.x <= 0.0 or q.size.y <= 0.0 or z.size.x <= 0.0 or z.size.y <= 0.0:
				continue
			draw_texture_rect_region(tex, z, q)


## Wie breit ist das Rahmenband dieser Grafik, in Texturpixeln?
##
## GEMESSEN statt geschätzt. Der erste Anlauf stand auf festen 12 % der Bildhöhe; das Band der
## gelieferten Tafel misst aber 15 %, die Schnittkante lag also mitten im Eisen. Beim 9-Patch
## wird die Mitte gekachelt — im Bild lief dadurch ein zweites, gestrecktes Band quer über die
## Tafel und der Text darunter.
##
## Gesucht wird die mittlere Spalte abwärts nach dem längsten Block „Pergament": hell, aber
## FARBIG. Das Unterscheidungsmerkmal ist die Sättigung — die Lichtkante auf dem Eisen ist
## genauso hell wie das Papier, aber grau. Genau daran ist die erste Messung gescheitert, die
## nur nach Helligkeit suchte und das Band bei 21 statt 73 Pixeln enden ließ.
func _messe_band(tex: Texture2D) -> int:
	var vorgabe: int = int(round(float(tex.get_height()) * FRAME_BORDER_RATIO))
	var bild: Image = tex.get_image()
	if bild == null:
		return vorgabe
	var x: int = bild.get_width() / 2
	var von: int = -1
	var bis: int = -1
	var lauf: int = -1
	for y in bild.get_height():
		var c: Color = bild.get_pixel(x, y)
		var hell: float = (c.r + c.g + c.b) / 3.0
		var sat: float = maxf(maxf(c.r, c.g), c.b) - minf(minf(c.r, c.g), c.b)
		var papier: bool = hell > 0.59 and sat >= 0.085 and sat <= 0.34
		if papier and lauf < 0:
			lauf = y
		elif not papier and lauf >= 0:
			if y - lauf > bis - von:
				von = lauf
				bis = y
			lauf = -1
	if lauf >= 0 and bild.get_height() - lauf > bis - von:
		von = lauf
		bis = bild.get_height()
	if von < 0 or bis - von < bild.get_height() / 4:
		return vorgabe
	return maxi(von, bild.get_height() - bis)


## Bildnis setzen und dabei den WIRKLICH BEMALTEN Teil bestimmen.
##
## Bildgeneratoren liefern das Motiv gern als Quadrat mitten auf einer groesseren, transparenten
## Flaeche — bei den ersten Bildnissen war rund ein Achtel des Bildes ringsum leer. Stur in das
## Feld gezeichnet, waere das Gesicht entsprechend kleiner und haette einen Rand aus Nichts.
##
## `Image.get_used_rect()` liefert genau den Ausschnitt, der nicht durchsichtig ist. Damit passt
## jedes Bildnis in sein Feld, egal wie viel Luft drumherum liegt — und niemand muss vorher
## zuschneiden.
func _set_portrait(tex: Texture2D) -> void:
	_portrait = tex
	_portrait_region = Rect2()
	if tex == null:
		return
	var bild: Image = tex.get_image()
	if bild == null:
		return
	var benutzt: Rect2i = bild.get_used_rect()
	if benutzt.size.x > 0 and benutzt.size.y > 0:
		_portrait_region = Rect2(benutzt)


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _frame != null:
		_draw_nine(_frame, r, _band)
	else:
		_draw_frame(r)   # ohne Grafik zeichnet die Tafel sich selbst
	_draw_portrait(_portrait_rect())
	var schrift: Font = get_theme_default_font()
	if schrift == null:
		return
	# Name in VERSALIEN und gesperrt. Beides aus der Vorlage, und beides hat einen Grund: Der
	# Name ist eine Überschrift, kein Satz — gesperrte Versalien lesen sich als Rubrik und
	# geraten nicht mit dem Gesprochenen durcheinander.
	var x: float = _portrait_rect().end.x + 16.0
	draw_string(schrift, Vector2(x, _inset() + 15.0), _sperren(speaker.to_upper()),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.33, 0.26, 0.16))
	# Der Winkel unten rechts blinkt langsam: das einzige Bedienelement der Tafel.
	var a: float = 0.45 + 0.4 * sin(_blink * 3.2)
	var mx: float = size.x - _inset() - 12.0
	var my: float = size.y - _inset() - 6.0
	draw_line(Vector2(mx - 9.0, my - 5.0), Vector2(mx, my), Color(0.33, 0.26, 0.16, a), 2.0)
	draw_line(Vector2(mx, my), Vector2(mx + 9.0, my - 5.0), Color(0.33, 0.26, 0.16, a), 2.0)


## Buchstaben sperren (ein Leerzeichen dazwischen). Godots Standardschrift kennt kein
## `letter_spacing`; bei einer Überschrift aus fünf Wörtern ist das der billigste Weg.
static func _sperren(t: String) -> String:
	var out: String = ""
	for i in t.length():
		out += t[i]
		if i < t.length() - 1 and t[i] != " ":
			out += " "
	return out


## Der gemalte Rahmen: Pergamentfläche, dunkle Eisenkante, dünne Messinglinie innen.
##
## Drei Lagen statt einer, weil ein einzelnes Rechteck flach aussieht. Die Messinglinie ist der
## Trick — sie sitzt zwei Pixel innerhalb der Eisenkante und lässt die Tafel wie etwas
## Gefasstes wirken statt wie ein aufgeklebter Kasten.
func _draw_frame(r: Rect2) -> void:
	draw_rect(r, IRON)
	var innen: Rect2 = r.grow(-3.0)
	draw_rect(innen, PAPER)
	# Angeschmutzter Fuß: Ein gleichmäßig helles Feld sieht aus wie Papier aus dem Drucker.
	draw_rect(Rect2(innen.position + Vector2(0.0, innen.size.y - 7.0),
		Vector2(innen.size.x, 7.0)), PAPER_DARK)
	draw_rect(r.grow(-5.0), Color(BRASS.r, BRASS.g, BRASS.b, 0.55), false, 1.0)


## Das Bildnis. Ohne Datei ein dunkles Feld mit dem Anfangsbuchstaben — lesbar, ruhig, und
## unverwechselbar genug, dass man Mabel von Silas unterscheidet.
func _draw_portrait(r: Rect2) -> void:
	if _portrait_frame == null:
		draw_rect(r.grow(2.0), IRON)   # ohne Rahmengrafik eine schlichte Eisenkante
	if _portrait != null:
		if _portrait_region.size.x > 0.0:
			draw_texture_rect_region(_portrait, r, _portrait_region)
		else:
			draw_texture_rect(_portrait, r, false)
	else:
		draw_rect(r, Color(0.17, 0.15, 0.14))
		var schrift: Font = get_theme_default_font()
		if schrift != null and not speaker.is_empty():
			var z: String = speaker.substr(0, 1).to_upper()
			var m: Vector2 = schrift.get_string_size(z, HORIZONTAL_ALIGNMENT_LEFT, -1, 54)
			draw_string(schrift, r.position + (r.size - m) * 0.5 + Vector2(0.0, m.y * 0.78),
				z, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0.62, 0.54, 0.38))
	if _portrait_frame != null:
		# Der Rahmen liegt UEBER dem Bildnis und ragt bewusst darueber hinaus: Seine Mitte ist
		# durchsichtig, sein Band deckt die Kante des Bildnisses ab. Ohne den Ueberstand blitzt
		# zwischen Bild und Rahmen eine Fuge durch.
		draw_texture_rect(_portrait_frame, r.grow(r.size.x * 0.11), false)
	else:
		draw_rect(r, Color(BRASS.r, BRASS.g, BRASS.b, 0.7), false, 1.5)
