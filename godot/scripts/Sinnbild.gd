extends RefCounted
## Sinnbilder — die kleinen Zeichen, über die in diesem Spiel ausgewählt wird.
##
## ## Warum Bilder und keine Nummern
##
## Fallout 2 listet Antworten als nummerierte Sätze. Baphomets Fluch zeigt stattdessen eine
## Reihe **Sinnbilder** am unteren Rand: ein Gesicht, ein Gegenstand, ein Fragezeichen. Man
## klickt das Gesicht an und fragt damit nach dieser Person. Das ist nicht nur hübscher, es ist
## schneller zu erfassen — und es hält die Gesprächsoberfläche aus dem Bild heraus, das man
## ja ansehen soll.
##
## Hier gibt es beides: **Sinnbild und kurze Beschriftung**. Reine Sinnbilder funktionieren im
## Original, weil dort jedes Gespräch um greifbare Dinge geht (ein Ausweis, ein Clown, eine
## Ziege). Unsere Gespräche gehen um Begriffe — „die Naht", „der Konzern", „Einheit sieben" —
## und dafür reicht kein Bildchen. Auf dem Telefon kommt dazu, dass ein Sinnbild gross genug
## zum Treffen sein muss; dann ist daneben ohnehin Platz für zwei Wörter.
##
## ## Gezeichnet, nicht geladen
##
## Die Zeichen entstehen aus `draw_*`-Aufrufen. Das ist Absicht: Es gibt im Spiel ein paar
## Dutzend Gesprächsthemen, und für jedes eine PNG-Datei zu malen, wäre Arbeit, die keiner
## sieht — die Dinger sind 44 px gross. Wo es ein richtiges Bild gibt (`portrait_mabel.png`
## und die anderen aus `assets/ui/`), wird es benutzt; sonst wird gezeichnet.
##
## ## Die Kennungen
##
## | Form | Bedeutung |
## |---|---|
## | `person:mabel` | über diese Person reden (Portrait, sonst Kopf mit Anfangsbuchstabe) |
## | `ding:revolver`| über diesen Gegenstand reden / ihn anbieten |
## | `frage`        | allgemeine Nachfrage |
## | `weg`          | das Gespräch beenden |
## | `ort:platz`    | nach einem Ort fragen |
## | `streit`       | widersprechen, hart nachfassen |
## | `wissen`       | etwas, das man herausgefunden hat, ansprechen |

const Palette = preload("res://scripts/Palette.gd")
const Schrift = preload("res://scripts/Schrift.gd")

## Wo die gemalten Portraits liegen, falls es eines gibt.
const PORTRAIT_ORDNER: String = "res://assets/ui/portrait_"


## Das Portrait einer Person, oder `null`.
static func portrait(person: String) -> Texture2D:
	for endung in [".png", ".webp"]:
		var pfad: String = PORTRAIT_ORDNER + person + endung
		if ResourceLoader.exists(pfad):
			return load(pfad) as Texture2D
	return null


## Ein Sinnbild zeichnen. `mitte` ist der Mittelpunkt, `groesse` die Kantenlänge.
static func zeichne(auf: CanvasItem, kennung: String, mitte: Vector2, groesse: float,
		farbe: Color) -> void:
	var teile: PackedStringArray = kennung.split(":")
	var art: String = teile[0] if teile.size() > 0 else "frage"
	var wer: String = teile[1] if teile.size() > 1 else ""
	var h: float = groesse * 0.5

	match art:
		"person":
			var bild: Texture2D = portrait(wer)
			if bild != null:
				auf.draw_texture_rect(bild, Rect2(mitte - Vector2(h, h),
					Vector2(groesse, groesse)), false)
				return
			_kopf(auf, mitte, groesse, farbe, wer)
		"ding":
			_ding(auf, mitte, groesse, farbe, wer)
		"ort":
			_wegweiser(auf, mitte, groesse, farbe)
		"weg":
			_tuer(auf, mitte, groesse, farbe)
		"streit":
			_blitz(auf, mitte, groesse, farbe)
		"wissen":
			_auge(auf, mitte, groesse, farbe)
		_:
			_frage(auf, mitte, groesse, farbe)


# ── Die einzelnen Zeichen ─────────────────────────────────────────────────────

static func _kopf(auf: CanvasItem, m: Vector2, g: float, f: Color, wer: String) -> void:
	var h: float = g * 0.5
	auf.draw_circle(m + Vector2(0.0, -h * 0.28), h * 0.42, f)
	# Schultern als Kreisabschnitt
	var schultern: PackedVector2Array = PackedVector2Array([
		m + Vector2(-h * 0.78, h),
		m + Vector2(-h * 0.62, h * 0.22),
		m + Vector2(h * 0.62, h * 0.22),
		m + Vector2(h * 0.78, h),
	])
	auf.draw_colored_polygon(schultern, f)
	if wer != "":
		var schrift: Font = Schrift.schrift()
		var b: String = wer.substr(0, 1).to_upper()
		var breite: float = schrift.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1,
			int(g * 0.34)).x
		auf.draw_string(schrift, m + Vector2(-breite * 0.5, -h * 0.14), b,
			HORIZONTAL_ALIGNMENT_LEFT, -1, int(g * 0.34), Palette.RUSS)


## Gegenstände bekommen eine Form nach Art, nicht nach Aussehen.
##
## Vier Formen reichen: Werkzeug (Rechteck mit Griff), Papier (Blatt mit Knick), Waffe
## (Winkel), Rundes (Kreis mit Achse). Der Spieler muss das Sinnbild nicht identifizieren —
## daneben steht der Name. Es muss nur zwei Gegenstände **auseinanderhalten** lassen.
static func _ding(auf: CanvasItem, m: Vector2, g: float, f: Color, was: String) -> void:
	var h: float = g * 0.5
	match _art_von(was):
		"waffe":
			auf.draw_colored_polygon(PackedVector2Array([
				m + Vector2(-h * 0.9, -h * 0.1), m + Vector2(h * 0.5, -h * 0.1),
				m + Vector2(h * 0.5, h * 0.18), m + Vector2(-h * 0.2, h * 0.18),
				m + Vector2(-h * 0.5, h * 0.9), m + Vector2(-h * 0.9, h * 0.9)]), f)
		"papier":
			auf.draw_rect(Rect2(m - Vector2(h * 0.6, h * 0.82),
				Vector2(h * 1.2, h * 1.64)), f, true)
			auf.draw_colored_polygon(PackedVector2Array([
				m + Vector2(h * 0.2, -h * 0.82), m + Vector2(h * 0.6, -h * 0.82),
				m + Vector2(h * 0.6, -h * 0.42)]), Palette.RUSS)
		"rund":
			auf.draw_circle(m, h * 0.72, f)
			auf.draw_circle(m, h * 0.22, Palette.RUSS)
		_:
			# Werkzeug
			auf.draw_rect(Rect2(m - Vector2(h * 0.82, h * 0.34),
				Vector2(h * 1.1, h * 0.68)), f, true)
			auf.draw_rect(Rect2(m + Vector2(h * 0.28, -h * 0.12),
				Vector2(h * 0.6, h * 0.24)), f, true)


## Welche Form ein Gegenstand bekommt.
##
## Die Zuordnung steht hier und nicht in `MissionDaten`, weil sie reine Darstellung ist: Ob der
## Schraubstock als Werkzeug gezeichnet wird, darf kein Rätsel ändern.
static func _art_von(was: String) -> String:
	match was:
		"revolver": return "waffe"
		"akte_mantel": return "papier"
		"walze", "oellampe": return "rund"
		_: return "werkzeug"


static func _frage(auf: CanvasItem, m: Vector2, g: float, f: Color) -> void:
	var schrift: Font = Schrift.schrift()
	var groesse: int = int(g * 0.9)
	var breite: float = schrift.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	auf.draw_string(schrift, m + Vector2(-breite * 0.5, g * 0.34), "?",
		HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, f)


static func _tuer(auf: CanvasItem, m: Vector2, g: float, f: Color) -> void:
	var h: float = g * 0.5
	auf.draw_rect(Rect2(m - Vector2(h * 0.6, h * 0.9), Vector2(h * 1.2, h * 1.8)), f, false, 3.0)
	auf.draw_circle(m + Vector2(h * 0.3, 0.0), h * 0.12, f)


static func _wegweiser(auf: CanvasItem, m: Vector2, g: float, f: Color) -> void:
	var h: float = g * 0.5
	auf.draw_line(m + Vector2(0.0, h * 0.9), m + Vector2(0.0, -h * 0.9), f, 3.0)
	auf.draw_colored_polygon(PackedVector2Array([
		m + Vector2(-h * 0.1, -h * 0.8), m + Vector2(h * 0.85, -h * 0.5),
		m + Vector2(-h * 0.1, -h * 0.2)]), f)


static func _blitz(auf: CanvasItem, m: Vector2, g: float, f: Color) -> void:
	var h: float = g * 0.5
	auf.draw_colored_polygon(PackedVector2Array([
		m + Vector2(h * 0.18, -h * 0.9), m + Vector2(-h * 0.55, h * 0.12),
		m + Vector2(-h * 0.05, h * 0.12), m + Vector2(-h * 0.28, h * 0.9),
		m + Vector2(h * 0.55, -h * 0.18), m + Vector2(h * 0.02, -h * 0.18)]), f)


static func _auge(auf: CanvasItem, m: Vector2, g: float, f: Color) -> void:
	var h: float = g * 0.5
	# Lid als zwei Bögen, angenähert durch Polygone — `draw_arc` wäre eine Linie ohne Füllung.
	auf.draw_colored_polygon(PackedVector2Array([
		m + Vector2(-h * 0.9, 0.0), m + Vector2(-h * 0.4, -h * 0.45),
		m + Vector2(h * 0.4, -h * 0.45), m + Vector2(h * 0.9, 0.0),
		m + Vector2(h * 0.4, h * 0.45), m + Vector2(-h * 0.4, h * 0.45)]), f)
	auf.draw_circle(m, h * 0.3, Palette.RUSS)
	auf.draw_circle(m, h * 0.13, Palette.GALVANISCH)


## Das Sinnbild, das zu einer Antwort gehört, wenn die Tabelle keines angibt.
##
## Eine Antwort ohne `ziel` beendet das Gespräch — die bekommt immer die Tür. Alles andere wird
## zur Frage. Das ist bewusst sparsam: Ein abgeleitetes Sinnbild soll nie *falsch* sein, nur
## allgemein. Wo es etwas bedeuten soll, steht es in `GespraechDaten` ausdrücklich dabei.
static func fuer_antwort(antwort: Dictionary) -> String:
	if antwort.has("sinnbild"):
		return str(antwort["sinnbild"])
	if not antwort.has("ziel"):
		return "weg"
	if antwort.has("hat"):
		return "ding:" + str(antwort["hat"])
	return "frage"
