class_name HudGlyph
## Ein Ort für alle Zeichen, die in der Oberfläche stehen.
##
## ## Warum es das gibt
##
## Vorher standen **Emoji** direkt im Quelltext — ein Reagenzglas für den Trank, ein
## Blutstropfen über den Gegnern, ein Geldsack bei der Beute. Das sah beim Schreiben gut aus
## und war **unsichtbar im Spiel**: Godots eingebaute Schrift ist ein schmaler
## Latin-Ausschnitt und kennt **kein einziges** dieser Zeichen. Wer das Spiel startete, sah
## leere Kästchen, wo Symbole stehen sollten — die Trankzahl schwebte neben einem Nichts, und
## über den Gegnern stand statt „betäubt" nur ein Loch. Es waren **54 verschiedene** Zeichen,
## quer durch Kopfzeile, Beutel, Werkstatt, Aufträge und Ortsschilder.
##
## Aufgefallen ist es nicht beim Lesen des Codes, sondern beim **Nachfragen bei der Schrift**:
## `Font.has_char()` sagte bei jedem einzelnen Symbol „nein".
##
## ## Was jetzt gilt
##
## Zwei Regeln, und die zweite wird von `TestRunner._test_zeichen()` erzwungen:
##
## 1. **Die Schrift liegt im Projekt** (`assets/fonts/DejaVuSans.ttf`, als Vorgabe in
##    `project.godot`). Sie deckt Umlaute, Typografie und die Symbolblöcke ab — aber **nicht**
##    den Emoji-Bereich ab U+1F300. Emoji sind Farbbilder, keine Buchstaben; keine normale
##    Schrift hat sie.
## 2. **Kein Zeichen darf in die Schrift fehlen.** `_test_zeichen()` liest **jede** Zeile
##    **jedes** Skripts und jeder Szene, wirft die Kommentare weg und fragt die Schrift zu
##    jedem übrigen Zeichen einzeln. Wer ein Emoji einbaut, sieht es beim nächsten Testlauf —
##    nicht erst der Spieler.
##
## Die Tabelle `Z` unten hält die Zeichen, die **im Code ausgerechnet** werden (Zustände,
## Waffen). Fließtext trägt sein Zeichen weiter direkt bei sich: „⚗ Trank getrunken" liest
## sich beim Schreiben besser als eine Formatierung, und die Prüfung fängt Fehler ohnehin ab.
##
## ## Und wo es wirklich zählt: gezeichnet statt gesetzt
##
## Der Trankknopf liegt unter dem Daumen und muss im Gefecht auf einen Blick erkennbar sein.
## Dafür ist ein Schriftzeichen zu schwach — es hängt an der Schrift, an der Größe und daran,
## dass jemand die Vorgabe nicht überschreibt. `zeichne_flakon()` malt den Flakon aus Punkten:
## Das sieht überall gleich aus und kann nicht zu einem leeren Kästchen werden.

## Die Zeichen des Spiels. Alles hier muss in `assets/fonts/DejaVuSans.ttf` vorkommen —
## `_test_zeichen()` fragt die Schrift bei **jedem** Eintrag einzeln nach.
const Z: Dictionary = {
	# ── Zustände über den Gegnern ──────────────────────────────────────────────
	"kurzschluss": "⚡",   # U+26A1 betäubt
	"dot":         "☣",   # U+2623 frisst weiter (Säure, Blutung)
	"panzer_weg":  "‼",   # U+203C Panzerung durch, Treffer gehen voll durch
	"tot":         "☠",   # U+2620

	# ── Zustände am Spieler ───────────────────────────────────────────────────
	"strahlung": "☢",   # U+2622 Strahlensumpf
	"smog":      "☣",   # U+2623 Smoggürtel

	# ── Beute am Boden ────────────────────────────────────────────────────────
	"gold":     "¤",   # U+00A4 Währung
	"material": "▬",   # U+25AC Schrottbalken
	"zahnrad":  "⚙",   # U+2699
	"dampfkern": "◉",  # U+25C9
	"trank":    "⚗",   # U+2697 Retorte — der Flakon selbst wird gezeichnet, nicht gesetzt

	# ── Waffen ────────────────────────────────────────────────────────────────
	# Sie stehen im Fließtext („⚔ Karabiner gefunden!"), deshalb Zeichen und keine Bilder.
	"karabiner": "⚔",   # U+2694
	"gatling":   "✳",   # U+2733 acht Speichen — der Lauf, der sich dreht
	"voltgun":   "⚡",   # U+26A1
	"saeure":    "⚗",   # U+2697
	"brenner":   "☼",   # U+263C Strahlenkranz — NICHT ☀, das ist der Tag

	# ── Sonstiges ─────────────────────────────────────────────────────────────
	"tag":     "☀",   # U+2600
	"nacht":   "☾",   # U+263E
	"warnung": "⚠",   # U+26A0
	"quest":   "✦",   # U+2726
	"punkt":   "·",   # U+00B7 Trenner zwischen Kopfzeilenfeldern
}


## Ein Zeichen holen. Unbekannte Namen geben den Namen selbst zurück statt abzustürzen —
## eine Oberfläche darf an einem fehlenden Symbol nicht sterben.
static func z(name: String) -> String:
	return String(Z.get(name, name))


## Der Flakon, aus Punkten gemalt.
##
## `mitte` ist die Mitte des Knopfes, `r` sein Radius; die Form wird darauf skaliert. Gezeichnet
## wird auf `ci` — jeden Aufruf in `_draw()` hinein.
##
## Die Form ist bewusst grob: Hals, Bauch, Füllstand. Bei 26 px Radius auf einem Telefon ist
## alles Feinere Matsch, und was man nicht erkennt, hilft im Gefecht nicht.
static func zeichne_flakon(ci: CanvasItem, mitte: Vector2, r: float, farbe: Color,
		inhalt: Color) -> void:
	# Punkte in Einheiten von `r`, y zeigt nach unten. Der Bauch ist eine Zwiebel, der Hals
	# ein schmaler Schacht — die Silhouette, an der man einen Flakon erkennt.
	var form: Array[Vector2] = [
		Vector2(-0.17, -0.66), Vector2(0.17, -0.66),   # Hals oben
		Vector2(0.17, -0.22),                           # Hals unten
		Vector2(0.50, 0.10), Vector2(0.42, 0.46),       # Bauch rechts
		Vector2(0.0, 0.62),                             # Boden
		Vector2(-0.42, 0.46), Vector2(-0.50, 0.10),     # Bauch links
		Vector2(-0.17, -0.22),                          # zurück zum Hals
	]
	var umriss: PackedVector2Array = PackedVector2Array()
	for p in form:
		umriss.append(mitte + p * r)

	# Der Inhalt wird AUS DEM UMRISS geschnitten und nicht daneben noch einmal beschrieben.
	#
	# Der erste Anlauf tippte eigene Punkte für den Füllstand ab — und im Kontrollbild stand
	# der Saft links und rechts aus dem Glas heraus. Zwei Zahlenreihen, die dieselbe Kontur
	# meinen, driften auseinander, sobald jemand an einer davon dreht. Also: alles unterhalb
	# der Wasserlinie vom Umriss übernehmen und die Linie selbst dort schneiden, wo sie die
	# Wand trifft. Damit liegt der Inhalt **per Konstruktion** im Glas.
	var linie: float = 0.16
	var fuell: PackedVector2Array = PackedVector2Array()
	for i in form.size():
		var a: Vector2 = form[i]
		var b: Vector2 = form[(i + 1) % form.size()]
		if a.y >= linie:
			fuell.append(mitte + a * r)
		# Kreuzt die Kante die Wasserlinie, kommt der Schnittpunkt dazu.
		if (a.y < linie) != (b.y < linie) and not is_equal_approx(a.y, b.y):
			var t: float = (linie - a.y) / (b.y - a.y)
			fuell.append(mitte + Vector2(a.x + (b.x - a.x) * t, linie) * r)
	if fuell.size() >= 3:
		ci.draw_colored_polygon(fuell, inhalt)

	# Umriss als geschlossener Linienzug.
	var zug: PackedVector2Array = umriss.duplicate()
	zug.append(umriss[0])
	ci.draw_polyline(zug, farbe, maxf(1.5, r * 0.075), true)

	# Der Korken sitzt quer auf dem Hals.
	var k_h: float = r * 0.12
	ci.draw_line(mitte + Vector2(-0.24, -0.70) * r, mitte + Vector2(0.24, -0.70) * r,
		farbe, k_h * 2.0)


## Eine Goldmuenze — gezeichnet, nicht gesetzt.
##
## ## Warum eine Muenze und kein „¤ 340"
##
## Die Kopfzeile war eine Textzeile mit sieben Angaben nebeneinander („zu ueberladen, alles in
## Text"). Der Gegenvorschlag war ausdruecklich: Gold **nur mit Goldmuenze und Zahl dahinter**.
##
## Das ist mehr als Geschmack. Eine Zahl hinter einem Waehrungszeichen muss man LESEN — man
## erfasst erst das Zeichen, ordnet es zu, liest dann die Zahl. Ein rundes gelbes Ding erkennt
## man, ohne hinzusehen; danach ist die Zahl daneben nur noch eine Zahl. In einem Kopfbereich,
## den man im Gefecht mit einem Seitenblick streift, ist das der ganze Unterschied.
##
## Gezeichnet und nicht als Schriftzeichen — aus demselben Grund wie beim Flakon: `¤` haengt an
## der Schrift, an der Groesse und daran, dass niemand die Vorgabe ueberschreibt. Ein Kreis aus
## Punkten sieht ueberall gleich aus und kann nicht zum leeren Kaestchen werden.
##
## `r` ist der AUSSENradius. Alles andere leitet sich daraus ab, damit die Muenze in jeder
## Groesse dieselbe bleibt.
static func zeichne_muenze(ci: CanvasItem, mitte: Vector2, r: float) -> void:
	# Der Rand liegt zuerst und ganz — die Scheibe darueber laesst ihn als Ring stehen. Das ist
	# billiger und genauer als ein Ring aus zwei Boegen, und vor allem bricht es nicht auf,
	# wenn `r` klein wird.
	ci.draw_circle(mitte, r, Color(0.42, 0.28, 0.06))
	ci.draw_circle(mitte, r * 0.86, Color(0.94, 0.74, 0.22))
	# Eine Praegung in der Mitte: etwas dunkler als die Scheibe, damit die Muenze nicht als
	# flacher Punkt liest. Kein Motiv — bei 9 Punkten Radius waere jedes Motiv Matsch.
	ci.draw_circle(mitte, r * 0.46, Color(0.80, 0.60, 0.14))
	# Und ein Glanzpunkt oben links. Er macht aus der Scheibe eine Muenze: Er sagt, dass das
	# Ding Wölbung hat und Licht von irgendwo kommt.
	ci.draw_circle(mitte + Vector2(-r * 0.34, -r * 0.34), r * 0.20, Color(1.0, 0.95, 0.70, 0.85))
