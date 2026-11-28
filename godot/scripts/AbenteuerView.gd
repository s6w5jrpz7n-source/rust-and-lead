extends Node2D
## Die Spielansicht des Adventures — gemaltes Bühnenbild, Figur davor, Punkt und Klick.
##
## ## Die Bedienung ist die von Baphomets Fluch
##
## | Eingabe | was passiert |
## |---|---|
## | Linksklick auf Boden    | die Figur geht dorthin |
## | Linksklick auf Hotspot  | die Figur geht hin und **benutzt** (reden / nehmen / benutzen) |
## | Rechtsklick auf Hotspot | **ansehen** — die Figur sagt, was sie sieht, ohne hinzugehen |
## | Maus an den oberen Rand | die Inventarleiste fährt herunter |
## | Gegenstand anklicken    | er liegt „in der Hand"; der nächste Klick wendet ihn an |
## | Rechtsklick ins Leere   | Gegenstand aus der Hand legen |
##
## Auf dem Telefon gibt es keine zwei Maustasten, also: **Tippen = benutzen, Halten = ansehen**,
## und ein Wisch von oben öffnet das Inventar. Das ist dieselbe Bedienung, nur mit dem einen
## Finger, den man hat — und nicht ein zweites, schlechteres Bedienkonzept daneben.
##
## ## Was hier NICHT passiert
##
## Keine Spiellogik. Welche Wirkung ein Klick hat, steht in `MissionDaten`; ob ein Hotspot da
## ist, entscheidet `Welt`; wohin die Figur geht, rechnet `OrtDaten`. Diese Datei setzt
## zusammen und zeichnet. Das ist der Grund, warum die Testsuite ein ganzes Kapitel durch-
## spielen kann, ohne je eine Szene zu laden.
##
## ## Der Platzhalter-Hintergrund
##
## Solange für einen Ort kein gemaltes Bild da ist, zeichnet `_zeichne_buehne()` eines aus dem
## Farbkeil: Himmel, Ferne, Boden, eine Horizontlinie und Kästen an den Stellen der Hotspots.
## Das ist absichtlich kein hübscher Platzhalter — man soll sofort sehen, dass hier ein Bild
## fehlt. Aber es ist **spielbar**: Alle Rätsel, alle Wege, alle Gespräche funktionieren damit,
## und die Bilder können nachgeliefert werden, ohne dass eine Zeile Logik sich ändert.

const OrtDaten = preload("res://scripts/OrtDaten.gd")
const Schrift = preload("res://scripts/Schrift.gd")
const MissionDaten = preload("res://scripts/MissionDaten.gd")
const GespraechDaten = preload("res://scripts/GespraechDaten.gd")
const KapitelDaten = preload("res://scripts/KapitelDaten.gd")
const Palette = preload("res://scripts/Palette.gd")
const Welt = preload("res://scripts/Welt.gd")
const Sinnbild = preload("res://scripts/Sinnbild.gd")

# ── Masse ─────────────────────────────────────────────────────────────────────

## Wie schnell die Figur läuft, in Pixeln je Sekunde bei Massstab 1.0.
##
## 210 px/s heisst: Die Figur durchquert das Bild in gut sechs Sekunden. Baphomets Fluch ist
## dort langsamer, und das war schon 1996 der meistgenannte Kritikpunkt. Ein Doppelklick auf
## einen Ausgang springt deshalb sofort — genau wie dort nachgerüstet.
const TEMPO: float = 210.0

## Wie nah die Figur an ein Ziel kommen muss, damit es als erreicht gilt.
const NAH_GENUG: float = 6.0

## Höhe der Inventarleiste und wie weit oben die Maus sein muss, damit sie herunterfährt.
const LEISTE_HOEHE: float = 92.0
const LEISTE_FANG: float = 26.0

## Wie lange ein Druck dauern muss, um als „ansehen" zu gelten (Telefon).
const HALTEN_SEK: float = 0.45

## Wie hoch die stehende Figur bei Massstab 1.0 gezeichnet wird.
const FIGUR_HOEHE_SOLL: float = OrtDaten.FIGUR_HOEHE

## Wie lange ein Satz mindestens steht, und wie viel Zeit je Zeichen dazukommt.
const SATZ_MIN: float = 1.4
const SATZ_JE_ZEICHEN: float = 0.045

signal gespraech_gewuenscht(baum: String)
signal tagebuch_gewuenscht
signal kapitel_schluss(nummer: int)

# ── Zustand ───────────────────────────────────────────────────────────────────

var _ort: String = ""
var _figur_pos: Vector2 = Vector2.ZERO
var _ziel: Vector2 = Vector2.ZERO
var _geht: bool = false

## Was getan wird, sobald die Figur angekommen ist: ["punkt_kennung", "benutzen"|"reden"|...]
var _auftrag: Array = []

## Der Gegenstand „in der Hand" — Baphomets Fluch nennt das den aufgenommenen Gegenstand.
var _in_hand: String = ""

## Die Sätze, die gerade angesagt werden, und wie lange der aktuelle noch steht.
var _saetze: Array = []
var _satz_rest: float = 0.0

var _leiste_offen: bool = false
var _leiste_y: float = -LEISTE_HOEHE
var _maus: Vector2 = Vector2.ZERO
var _unter_maus: String = ""
var _druck_seit: float = -1.0
var _druck_wo: Vector2 = Vector2.ZERO

var _hintergrund: Texture2D = null

## Die Vordergrundebene, falls es eine gibt.
##
## Ein gemalter Ort in dieser Bauform hat fast immer etwas, das angeschnitten am Bildrand
## steht -- einen Balken, einen Torbogen, den Anbindepfosten auf dem Stadtplatz. Erst das
## macht aus einem Bild einen Raum. Technisch ist es ein Problem: Die Figur wird ueber den
## Hintergrund gezeichnet, liefe also VOR dem Pfosten statt dahinter.
##
## Die Loesung ist eine zweite, freigestellte Ebene, die NACH der Figur kommt. Solange es
## keine gibt, spart die begehbare Flaeche den Vordergrund aus -- das geht, kostet aber
## Bildflaeche und sieht nie so gut aus.
var _vordergrund: Texture2D = null

## Die Figur in drei Haltungen, oder leer.
##
## Der Massstab kommt aus der STEHENDEN Haltung und gilt fuer alle drei. Jede einzeln auf
## `FIGUR_HOEHE` zu ziehen waere falsch: Die Laufbilder sind im Schritt ein paar Prozent
## niedriger als das Standbild, und genau so gehoert es sich -- wer sie alle gleich hoch
## macht, laesst die Figur beim Stehenbleiben wachsen.
var _figur_bild: Dictionary = {}
var _figur_faktor: float = 1.0

## Woher der Massstab kommt. Steht die Datei nicht da, bleibt es bei der Silhouette.
const FIGUR_ORDNER: String = "res://assets/figuren/"


func _ready() -> void:
	_figuren_laden()
	set_process(true)
	set_process_unhandled_input(true)
	betreten(GameState.ort if GameState.ort != "" else "kippe")


## Die drei Haltungen einmalig laden.
func _figuren_laden() -> void:
	for haltung in ["stand", "walk_left", "walk_right"]:
		var pfad: String = FIGUR_ORDNER + "held_" + haltung + ".webp"
		if ResourceLoader.exists(pfad):
			_figur_bild[haltung] = load(pfad) as Texture2D
	var steht: Texture2D = _figur_bild.get("stand", null) as Texture2D
	if steht != null and steht.get_height() > 0:
		_figur_faktor = FIGUR_HOEHE_SOLL / float(steht.get_height())


# ── Ort betreten ──────────────────────────────────────────────────────────────

## Einen Ort laden. `von` ist der Name der Ankunft (siehe `OrtDaten.ankunft`).
func betreten(kennung: String, von: String = "") -> void:
	if OrtDaten.ort(kennung).is_empty():
		push_warning("Ort unbekannt: %s" % kennung)
		return
	var erstes_mal: bool = Welt.betreten(kennung)
	_ort = kennung
	_auftrag = []
	_geht = false
	# Angefangene Saetze gehoeren zum alten Ort. Wer eine Tuer benutzt, waehrend die Figur noch
	# etwas sagt, bekaeme sonst im neuen Raum den Satz aus dem alten vorgelesen -- beim ersten
	# Bildschirmfoto prompt passiert: Auf dem Stadtplatz stand "Die Schrottkippe".
	_saetze = []
	_satz_rest = 0.0
	_in_hand = ""
	_figur_pos = OrtDaten.ankunft(kennung, von) if von != "" \
		else (OrtDaten.ort(kennung).get("start", OrtDaten.RAHMEN * 0.5) as Vector2)
	_ziel = _figur_pos
	_hintergrund = _bild_laden(kennung)
	_vordergrund = _bild_laden(kennung, "bild_vorn")
	if erstes_mal:
		sagen([str(OrtDaten.ort(kennung).get("name", kennung))])
	_missionen_pruefen()
	queue_redraw()


## Das gemalte Bild eines Ortes, oder `null`.
##
## `ResourceLoader.exists` und nicht `load()` im try: Ein fehlendes Bild ist der Normalfall,
## solange nicht alle Orte gemalt sind, und `load()` schreibt dann bei jedem Ortswechsel eine
## Fehlerzeile ins Protokoll. Ein Protokoll voller erwarteter Fehler ist ein Protokoll, in dem
## man die unerwarteten nicht mehr sieht.
func _bild_laden(kennung: String, feld: String = "bild") -> Texture2D:
	var pfad: String = str(OrtDaten.ort(kennung).get(feld, ""))
	if pfad == "" or not ResourceLoader.exists(pfad):
		return null
	return load(pfad) as Texture2D


# ── Sprechen ──────────────────────────────────────────────────────────────────

## Sätze nacheinander ansagen. Ein leerer Text sagt nichts — das ist kein Sonderfall, sondern
## der Normalfall bei Wirkungen, die nur Flaggen setzen.
func sagen(texte: Array) -> void:
	for t in texte:
		if str(t).strip_edges() != "":
			_saetze.append(str(t))
	if _satz_rest <= 0.0:
		_naechster_satz()


## Alles Gesagte abbrechen -- wird gebraucht, wenn eine andere Ansicht nach vorn kommt.
func verstummen() -> void:
	_saetze = []
	_satz_rest = 0.0
	queue_redraw()


func _naechster_satz() -> void:
	if _saetze.is_empty():
		_satz_rest = 0.0
		return
	var t: String = str(_saetze[0])
	_satz_rest = SATZ_MIN + float(t.length()) * SATZ_JE_ZEICHEN
	queue_redraw()


func _satz_jetzt() -> String:
	return str(_saetze[0]) if not _saetze.is_empty() else ""


## Den laufenden Satz abbrechen und den nächsten zeigen. Jeder Klick tut das — in einem
## Adventure wartet niemand gern auf Text, den er schon gelesen hat.
func satz_weiter() -> bool:
	if _saetze.is_empty():
		return false
	_saetze.remove_at(0)
	_naechster_satz()
	queue_redraw()
	return true


# ── Takt ──────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _satz_rest > 0.0:
		_satz_rest -= delta
		if _satz_rest <= 0.0:
			if not _saetze.is_empty():
				_saetze.remove_at(0)
			_naechster_satz()
			queue_redraw()

	if _druck_seit >= 0.0:
		_druck_seit += delta
		if _druck_seit >= HALTEN_SEK:
			_ansehen_an(_druck_wo)
			_druck_seit = -1.0

	var ziel_y: float = 0.0 if _leiste_offen else -LEISTE_HOEHE
	if not is_equal_approx(_leiste_y, ziel_y):
		_leiste_y = move_toward(_leiste_y, ziel_y, LEISTE_HOEHE * 4.0 * delta)
		queue_redraw()

	if _geht:
		_laufen(delta)


func _laufen(delta: float) -> void:
	var schritt: float = TEMPO * delta
	var weg: Vector2 = _ziel - _figur_pos
	if weg.length() <= maxf(schritt, NAH_GENUG):
		_figur_pos = _ziel
		_geht = false
		_angekommen()
	else:
		var neu: Vector2 = _figur_pos + weg.normalized() * schritt
		if not OrtDaten.begehbar(_ort, neu):
			# An der Kante entlangrutschen statt stehenzubleiben. Ohne das bleibt die Figur an
			# jeder Ecke zweier Rechtecke hängen, und der Spieler hält das für einen Absturz.
			var nur_x: Vector2 = Vector2(neu.x, _figur_pos.y)
			var nur_y: Vector2 = Vector2(_figur_pos.x, neu.y)
			if OrtDaten.begehbar(_ort, nur_x):
				neu = nur_x
			elif OrtDaten.begehbar(_ort, nur_y):
				neu = nur_y
			else:
				neu = OrtDaten.naechster_punkt(_ort, neu)
		_figur_pos = neu
	queue_redraw()


func _angekommen() -> void:
	if _auftrag.size() < 2:
		return
	var punkt: String = str(_auftrag[0])
	var was: String = str(_auftrag[1])
	_auftrag = []
	_ausfuehren(punkt, was)


# ── Eingabe ───────────────────────────────────────────────────────────────────

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_maus = (e as InputEventMouseMotion).position
		_leiste_offen = _leiste_offen or _maus.y <= LEISTE_FANG
		if _leiste_offen and _maus.y > LEISTE_HOEHE + 30.0:
			_leiste_offen = false
		var vorher: String = _unter_maus
		_unter_maus = OrtDaten.punkt_bei(_ort, _maus, Welt.sicht_pruefer())
		if vorher != _unter_maus:
			queue_redraw()
		return

	if e is InputEventMouseButton:
		var mb: InputEventMouseButton = e as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_druck_seit = 0.0
				_druck_wo = mb.position
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_ansehen_an(mb.position)
		else:
			if mb.button_index == MOUSE_BUTTON_LEFT and _druck_seit >= 0.0:
				_druck_seit = -1.0
				_benutzen_an(mb.position)


## Linksklick: benutzen, hingehen, oder Gegenstand anwenden.
func _benutzen_an(wo: Vector2) -> void:
	if satz_weiter():
		return

	# In der Leiste?
	if _leiste_y > -LEISTE_HOEHE + 1.0 and wo.y <= _leiste_y + LEISTE_HOEHE:
		_leiste_klick(wo)
		return

	var punkt: String = OrtDaten.punkt_bei(_ort, wo, Welt.sicht_pruefer())
	if punkt == "":
		if _in_hand != "":
			_in_hand = ""   # Gegenstand weglegen
			queue_redraw()
			return
		_hingehen(OrtDaten.naechster_punkt(_ort, wo))
		return

	_auftrag = [punkt, "benutzen"]
	_hingehen(OrtDaten.hingehen(_ort, punkt))


## Rechtsklick / Halten: ansehen. Ohne hinzugehen — man kann von weitem hinsehen, und das ist
## der Grund, warum „Ansehen" in diesen Spielen nie nervt.
func _ansehen_an(wo: Vector2) -> void:
	var punkt: String = OrtDaten.punkt_bei(_ort, wo, Welt.sicht_pruefer())
	if punkt == "":
		if _in_hand != "":
			var g: Dictionary = MissionDaten.gegenstand(_in_hand)
			sagen([str(g.get("text", ""))])
		return
	var p: Dictionary = OrtDaten.punkte_alle(_ort).get(punkt, {}) as Dictionary
	sagen([str(p.get("ansehen", "Da ist nichts, was mir etwas sagt."))])


func _hingehen(ziel: Vector2) -> void:
	_ziel = OrtDaten.naechster_punkt(_ort, ziel)
	_geht = _figur_pos.distance_to(_ziel) > NAH_GENUG
	if not _geht:
		_angekommen()


# ── Ausführen ─────────────────────────────────────────────────────────────────

## Was an einem Hotspot passiert, wenn man ihn benutzt.
##
## Die Reihenfolge ist Absicht und sie ist die von Baphomets Fluch: **Erst der Gegenstand in
## der Hand, dann reden, dann nehmen, dann benutzen.** Wer eine Walze in der Hand hat und auf
## Silas klickt, will sie ihm geben und nicht mit ihm plaudern.
func _ausfuehren(punkt: String, _was: String) -> void:
	var p: Dictionary = OrtDaten.punkte_alle(_ort).get(punkt, {}) as Dictionary
	if p.is_empty():
		return

	# 1. Gegenstand anwenden
	if _in_hand != "":
		var womit: String = _in_hand
		_in_hand = ""
		if MissionDaten.kombinierbar(womit, punkt):
			_wirkung_zeigen(Welt.wirken(str(p.get("benutzen", ""))))
		else:
			sagen([_passt_nicht(womit, str(p.get("name", "das")))])
		queue_redraw()
		return

	# 2. Ausgang
	if p.has("ziel"):
		if p.has("sperre") and not Welt.flagge(str(p.get("frei", ""))):
			sagen([str(p["sperre"])])
			return
		betreten(str(p["ziel"]), str(p.get("dort", "")))
		return

	# 3. Reden
	if p.has("reden"):
		gespraech_gewuenscht.emit(str(p["reden"]))
		return

	# 4. Nehmen
	if p.has("nehmen"):
		var g: String = str(p["nehmen"])
		if Welt.nehmen(g):
			var name: String = str(MissionDaten.gegenstand(g).get("name", g))
			sagen(["%s — eingesteckt." % name])
			GameState.add_xp(10)
		_missionen_pruefen()
		queue_redraw()
		return

	# 5. Benutzen
	if p.has("benutzen"):
		_wirkung_zeigen(Welt.wirken(str(p["benutzen"])))
		return

	# 6. Nichts davon: dann wenigstens hinsehen, statt stumm zu bleiben.
	sagen([str(p.get("ansehen", "Damit kann ich nichts anfangen."))])


func _wirkung_zeigen(text: String) -> void:
	if text != "":
		sagen([text])
	_missionen_pruefen()
	queue_redraw()


## Ein abschlägiger Satz, der nach Figur klingt und nicht nach Fehlermeldung.
##
## „Das funktioniert nicht" ist der Satz, an dem man ein lieblos gebautes Adventure erkennt.
## Drei Varianten reichen, damit es nicht nach Automat klingt; welche kommt, hängt an der Länge
## des Namens, also ist es bei gleicher Eingabe immer derselbe Satz — ein Spieler, der zweimal
## dasselbe probiert, soll nicht glauben, beim zweiten Mal sei etwas anderes passiert.
func _passt_nicht(womit: String, woran: String) -> String:
	var name: String = str(MissionDaten.gegenstand(womit).get("name", womit))
	match name.length() % 3:
		0: return "%s und %s — daraus wird nichts." % [name, woran]
		1: return "Ich sehe nicht, was %s hier helfen soll." % name
		_: return "Nein. %s gehört nicht an %s." % [name, woran]


func _missionen_pruefen() -> void:
	for fertig in Welt.missionen_pruefen():
		var m: Dictionary = MissionDaten.mission(str(fertig))
		sagen(["Erledigt: %s" % str(m.get("titel", fertig))])
	var k: int = GameState.current_chapter
	if KapitelDaten.schluss_frei(k, func(id: String) -> bool: return Welt.mission_fertig(id)):
		if not Welt.flagge("schluss_%d_angesagt" % k):
			Welt.flagge_setzen("schluss_%d_angesagt" % k)
			var s: Dictionary = KapitelDaten.schluss(k)
			var ort_name: String = str(OrtDaten.ort(str(s.get("ort", ""))).get("name", ""))
			sagen(["Alles getan, was zu tun war. %s wartet." % ort_name])
			kapitel_schluss.emit(k)


# ── Inventarleiste ────────────────────────────────────────────────────────────

func _leiste_klick(wo: Vector2) -> void:
	var i: int = int(floorf((wo.x - 20.0) / 76.0))
	if i < 0 or i >= GameState.beutel.size():
		return
	var g: String = str(GameState.beutel[i])
	if _in_hand == g:
		_in_hand = ""
	elif _in_hand != "":
		# Gegenstand auf Gegenstand. Das ist die zweite Haelfte des Raetselsystems: Was man
		# findet, ist oft erst zusammen mit etwas anderem zu gebrauchen.
		var text: String = Welt.verbinden(_in_hand, g)
		if text != "":
			sagen([text])
			_missionen_pruefen()
		else:
			sagen([_passt_nicht(_in_hand, str(MissionDaten.gegenstand(g).get("name", g)))])
		_in_hand = ""
	else:
		_in_hand = g
	queue_redraw()


# ── Zeichnen ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	_zeichne_buehne()
	_zeichne_figur()
	if _vordergrund != null:
		draw_texture_rect(_vordergrund, Rect2(Vector2.ZERO, OrtDaten.RAHMEN), false)
	_zeichne_hotspot_name()
	_zeichne_satz()
	_zeichne_leiste()


func _zeichne_buehne() -> void:
	var r: Vector2 = OrtDaten.RAHMEN
	if _hintergrund != null:
		draw_texture_rect(_hintergrund, Rect2(Vector2.ZERO, r), false)
		return

	# Platzhalter aus dem Farbkeil.
	var f: Array = OrtDaten.ort(_ort).get("farben", []) as Array
	var himmel: Color = (f[0] as Color) if f.size() > 0 else Palette.DUNST
	var ferne: Color = (f[1] as Color) if f.size() > 1 else Palette.ALTKUPFER
	var boden: Color = (f[2] as Color) if f.size() > 2 else Palette.ROSTERDE
	var horizont: float = OrtDaten.BUEHNE_HORIZONT

	# Himmel als Verlauf in acht Bändern — kein Shader, keine Textur, und es sieht trotzdem
	# nach Dunst aus statt nach Farbfläche.
	for i in range(8):
		var a: float = float(i) / 8.0
		draw_rect(Rect2(0.0, horizont * a, r.x, horizont / 8.0 + 1.0),
			himmel.lerp(ferne, a))
	draw_rect(Rect2(0.0, horizont, r.x, r.y - horizont), boden)
	draw_line(Vector2(0.0, horizont), Vector2(r.x, horizont), Palette.OELSCHWARZ, 2.0)

	# Die Hotspots als Kästen — sichtbar, damit man ohne gemaltes Bild spielen kann.
	for k in OrtDaten.punkte_alle(_ort):
		var p: Dictionary = OrtDaten.punkte_alle(_ort)[k] as Dictionary
		if not Welt.sichtbar(p):
			continue
		var rect: Rect2 = p.get("rect", Rect2()) as Rect2
		var ist_tuer: bool = p.has("ziel")
		var farbe: Color = Palette.MESSING if ist_tuer else Palette.LEDER
		draw_rect(rect, Color(farbe.r, farbe.g, farbe.b, 0.35), true)
		draw_rect(rect, farbe, false, 2.0)


## Die Figur als Silhouette: Mantel, Hut, Beine.
##
## Kein Platzhalter-Rechteck. Eine Gestalt mit Hut liest sich auf den ersten Blick als Mensch,
## und man sieht sofort, ob Grösse und Standpunkt stimmen — ein Rechteck zeigt das nicht.
## Welche Haltung gerade gilt.
func _haltung() -> String:
	if not _geht:
		return "stand"
	return "walk_left" if (_ziel.x < _figur_pos.x) else "walk_right"


func _zeichne_figur() -> void:
	var m: float = OrtDaten.groesse_bei(_ort, _figur_pos.y)

	# Gemalte Figur, wenn es sie gibt.
	var bild: Texture2D = _figur_bild.get(_haltung(), null) as Texture2D
	if bild != null:
		var breite: float = float(bild.get_width()) * _figur_faktor * m
		var hoehe: float = float(bild.get_height()) * _figur_faktor * m
		# Schatten zuerst, sonst liegt er auf den Stiefeln.
		draw_set_transform(_figur_pos, 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, breite * 0.42, Color(0.0, 0.0, 0.0, 0.30))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Verankert an den Fuessen, mittig -- `_figur_pos` ist der Standpunkt, nicht die Mitte.
		draw_texture_rect(bild, Rect2(_figur_pos - Vector2(breite * 0.5, hoehe),
			Vector2(breite, hoehe)), false)
		return

	var h: float = OrtDaten.FIGUR_HOEHE * m
	var b: float = h * 0.34
	var fuss: Vector2 = _figur_pos
	var grund: Color = (OrtDaten.ort(_ort).get("farben", [Palette.ROSTERDE]) as Array)[-1] as Color
	var farbe: Color = Palette.abheben(Palette.OELSCHWARZ, grund)

	# Mantel
	var mantel: PackedVector2Array = PackedVector2Array([
		fuss + Vector2(-b * 0.5, 0.0),
		fuss + Vector2(-b * 0.62, -h * 0.52),
		fuss + Vector2(-b * 0.38, -h * 0.74),
		fuss + Vector2(b * 0.38, -h * 0.74),
		fuss + Vector2(b * 0.62, -h * 0.52),
		fuss + Vector2(b * 0.5, 0.0),
	])
	draw_colored_polygon(mantel, farbe)
	# Kopf
	draw_circle(fuss + Vector2(0.0, -h * 0.82), h * 0.085, farbe)
	# Hutkrempe
	draw_line(fuss + Vector2(-b * 0.75, -h * 0.87), fuss + Vector2(b * 0.75, -h * 0.87),
		farbe, maxf(3.0, h * 0.035))
	# Schatten am Boden — ohne ihn schwebt die Figur, und das sieht man sofort.
	draw_set_transform(fuss, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, b * 0.72, Color(0.0, 0.0, 0.0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _zeichne_hotspot_name() -> void:
	if _unter_maus == "":
		return
	var p: Dictionary = OrtDaten.punkte_alle(_ort).get(_unter_maus, {}) as Dictionary
	var text: String = str(p.get("name", ""))
	if _in_hand != "":
		text = "%s an %s" % [str(MissionDaten.gegenstand(_in_hand).get("name", _in_hand)), text]
	var schrift: Font = Schrift.schrift()
	var breite: float = schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var wo: Vector2 = _maus + Vector2(-breite * 0.5, -18.0)
	wo.x = clampf(wo.x, 8.0, OrtDaten.RAHMEN.x - breite - 8.0)
	_schrift_mit_umriss(schrift, wo, text, 18, Palette.SANDLICHT)


func _zeichne_satz() -> void:
	var t: String = _satz_jetzt()
	if t == "":
		return
	var r: Vector2 = OrtDaten.RAHMEN
	var schrift: Font = Schrift.schrift()
	var kasten: Rect2 = Rect2(60.0, r.y - 132.0, r.x - 120.0, 108.0)
	draw_rect(kasten, Color(Palette.TAFEL.r, Palette.TAFEL.g, Palette.TAFEL.b,
		Palette.TAFEL_DECKUNG), true)
	draw_rect(kasten, Palette.RAHMEN, false, 2.0)
	draw_multiline_string(schrift, kasten.position + Vector2(18.0, 30.0), t,
		HORIZONTAL_ALIGNMENT_LEFT, kasten.size.x - 36.0, 20, 4, Palette.SCHRIFT)


func _zeichne_leiste() -> void:
	if _leiste_y <= -LEISTE_HOEHE + 0.5:
		return
	var r: Vector2 = OrtDaten.RAHMEN
	draw_rect(Rect2(0.0, _leiste_y, r.x, LEISTE_HOEHE),
		Color(Palette.TAFEL.r, Palette.TAFEL.g, Palette.TAFEL.b, 0.94), true)
	draw_line(Vector2(0.0, _leiste_y + LEISTE_HOEHE), Vector2(r.x, _leiste_y + LEISTE_HOEHE),
		Palette.RAHMEN, 2.0)
	var schrift: Font = Schrift.schrift()
	if GameState.beutel.is_empty():
		draw_string(schrift, Vector2(20.0, _leiste_y + LEISTE_HOEHE * 0.58),
			"Nichts dabei.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.SCHRIFT_MATT)
		return
	for i in range(GameState.beutel.size()):
		var g: String = str(GameState.beutel[i])
		var feld: Rect2 = Rect2(20.0 + float(i) * 76.0, _leiste_y + 12.0, 68.0, 68.0)
		var gewaehlt: bool = (g == _in_hand)
		draw_rect(feld, Color(Palette.LEDER.r, Palette.LEDER.g, Palette.LEDER.b,
			0.5 if gewaehlt else 0.25), true)
		draw_rect(feld, Palette.SANDLICHT if gewaehlt else Palette.RAHMEN, false,
			3.0 if gewaehlt else 1.5)
		Sinnbild.zeichne(self, "ding:" + g, feld.position + feld.size * 0.5, 44.0,
			Palette.SANDLICHT if gewaehlt else Palette.SAND)


## Schrift mit dunklem Umriss.
##
## Ein Spiel, dessen Hintergründe von Russ bis Sandlicht reichen, hat keine Schriftfarbe, die
## überall lesbar ist. Der Umriss löst das ein für alle Mal und kostet acht Zeichenaufrufe.
func _schrift_mit_umriss(schrift: Font, wo: Vector2, text: String, groesse: int,
		farbe: Color) -> void:
	for dx in [-1.5, 0.0, 1.5]:
		for dy in [-1.5, 0.0, 1.5]:
			if is_zero_approx(dx) and is_zero_approx(dy):
				continue
			draw_string(schrift, wo + Vector2(dx, dy), text, HORIZONTAL_ALIGNMENT_LEFT,
				-1, groesse, Palette.RUSS)
	draw_string(schrift, wo, text, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, farbe)
