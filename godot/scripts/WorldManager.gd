class_name WorldManager extends RefCounted
## WorldManager — Weltgeografie, Sektoren & Progressions-Gating (Master-GDD §1.6/§1.7).
##
## Reine Logik/Daten (`class_name`, statisch — kein Autoload nötig). Alle Gate-Zustände
## werden aus `GameState` abgeleitet (Kapitel, Gilde, Gebäudestufe); es gibt keinen
## dupliziten Zustand, der auseinanderlaufen könnte.
##
## Koordinatensystem: Ursprung (0,0) SW-Ecke, X = West→Ost, Y = Süd→Nord, jeweils 0…2000 m.

# ── Sektorgrenzen (horizontale Y-Linien) ──────────────────────────────────────
const WORLD_SIZE: int = 2000
const BORDER_S1_S2_Y: int = 800     # Sprengtore (Hard Gate 1)
const BORDER_S2_S3_Y: int = 1500    # Smog-Linie (Hard Gate 2), == SMOG_LINE_Y
const SMOG_LINE_Y: int = 1500

# ── Produktions-Maßstab (Master-GDD §1.4) ─────────────────────────────────────
## Die POI-Tabelle beschreibt das RELATIVE Layout (0…2000); die Produktion spannt den
## Kraterboden auf 5000×5000 m auf. Szenen-Mapping: X → +x (Ost), Y (Nord) → −z.
const WORLD_METERS: float = 5000.0
const METERS_PER_UNIT: float = WORLD_METERS / float(WORLD_SIZE)   # = 2.5
const PLAYER_SPEED_MS: float = 4.7                                # Laufgeschwindigkeit (m/s)

## Relative Weltkoordinate (0…2000) → Godot-Szenenposition in Metern.
static func world_to_scene(rel: Vector2) -> Vector3:
	return Vector3(rel.x * METERS_PER_UNIT, 0.0, -rel.y * METERS_PER_UNIT)

## Godot-Szenenposition → relative Weltkoordinate (für Gating-/Biom-Abfragen).
static func scene_to_world(p: Vector3) -> Vector2:
	return Vector2(p.x / METERS_PER_UNIT, -p.z / METERS_PER_UNIT)

## POI-Position direkt im Szenen-Maßstab (Meter).
static func poi_scene_position(poi_id: String) -> Vector3:
	return world_to_scene(poi_position(poi_id))


# ── Topografie: Senken und Wälle als FORMEL, nicht als Modell ─────────────────
## Der Boden war bis hierher eine flache Platte bei y = 0, und die Figur bekam ihr y nie von
## irgendwoher. Ein modellierter Krater wäre deshalb Kulisse geblieben, durch die man
## hindurchspaziert.
##
## Statt Geometrie steht hier eine Funktion: `height_at(x, z)` liefert für JEDEN Punkt der Welt
## die Bodenhöhe. Aus derselben Funktion entsteht das sichtbare Netz UND die Höhe, auf der
## Spieler, Gegner und Beute stehen — eine Quelle, mehrere Verbraucher. Ein Modell mit
## getrennter Kollision läuft dagegen früher oder später auseinander.
##
## Warum keine Textur-Heightmap: Bei der festen Kamera sind 15 m Bildbreite rund 128 Pixel pro
## Meter. Ein unikal texturiertes Gelände dieser Schärfe wäre für einen 30-m-Krater schon
## 15 Megapixel und ließe sich nicht kacheln. Eine Formel kostet null Byte, ist überall exakt
## und in beide Richtungen ableitbar (Normalen ohne Nachbarschaftssuche).

## Geländeformen. `poi` verankert sie an einem Ort, alle Maße in METERN.
##  • `radius`      Rand der Senke — dort ist die Höhe wieder 0
##  • `depth`       Tiefe des Grundes
##  • `rim`         Höhe des Auswurfwalls direkt außerhalb
##  • `rim_width`   Breite des Walls als Anteil des Radius
##  • `floor`       Anteil des Radius, der FLACHER GRUND ist (0 = Schüssel ohne Boden).
##                  Der Rest dazwischen ist die Wand: je größer `floor`, desto steiler.
##  • `ramp_deg`    Richtung der Rampe (0° = Osten, 90° = Norden) — dort bleibt die Wand weg
##  • `ramp_span`   Öffnungswinkel der Rampe in Grad (Gesamtbreite, nicht halbe)
const TERRAIN: Array = [
	# Die Schrotthalde: die Grube, in der der Held erwacht. 30 m Durchmesser — groß genug für
	# eine Szene, klein genug, dass man den Rand von der Mitte aus sieht.
	#
	# Kein Trichter mehr, sondern ein LOCH: flacher Grund, steile ausgewaschene Erdwände, eine
	# aufgeworfene Lippe. Eine Schüssel liest sich aus der Iso-Perspektive als sanfte Delle;
	# erst die Wand macht daraus einen Ort, in den man hinabsteigt und aus dem man nicht
	# einfach in jede Richtung herausläuft.
	#
	# Die Rampe im Nordosten ist die einzige Stelle, an der die Wand fehlt — dort geht man
	# hinein und hinaus. Ohne sie wäre die Grube entweder ein Käfig oder man liefe eine
	# senkrechte Wand hoch wie eine Fliege.
	# `ramp_deg` 119° zeigt zum Ausguck: Wer aus der Grube klettert, steht mit dem Gesicht in die
	# Richtung, in die er ohnehin geht. Vorher zeigte der Ausgang mit 55° irgendwohin — das fiel
	# nicht auf, solange niemand dort anfing, und faellt auf, seit der Prolog dort anfaengt.
	{ "id": "schrotthalde", "kind": "crater", "poi": "schrott_minen",
		"radius": 15.0, "depth": 5.0, "rim": 1.0, "rim_width": 0.36,
		"floor": 0.78, "ramp_deg": 119.0, "ramp_span": 70.0 },
	# Der Ausguck: eine Anhöhe auf halbem Weg zwischen Schrottgrube und Rustwater.
	#
	# Sie ist ein **umgedrehter Krater** — dieselbe Formel, `depth` negativ. Das ist kein Trick,
	# sondern die richtige Bauweise: Das Höhenprofil eines Kraters ist ein flacher Boden, eine
	# steile Wand und ein Sektor, in dem die Wand fehlt. Vorzeichen umgedreht ergibt genau das,
	# was hier gebraucht wird: ein flaches Plateau, eine steil abfallende Klippe ringsum und
	# EINE Seite, über die man hinaufkommt.
	#
	# Warum Gelände und kein 3D-Objekt: `height_at()` ist die einzige Wahrheit für Bodenhöhe im
	# ganzen Spiel — daran hängen Laufen, Fußspuren, Streuung, jede Figur und jede Kiste. Ein
	# aufgestelltes Modell wüsste davon nichts; man liefe hindurch, die Fußspur ginge darunter
	# her, und Gegner ständen in der Luft. Als Formel gilt es überall, ohne dass irgendwo eine
	# Zeile dafür geschrieben wird.
	#
	# Es ist ein FELS, kein Hügel. Der Unterschied steckt in drei Zahlen:
	#
	#  • **15 m statt 24.** Man will darüber stehen, nicht darauf thronen. Aus 15 m sieht man
	#    Rustwater in 255 m Entfernung unter einem Winkel von 3° — praktisch waagerecht, also
	#    unter der Felskante hindurch in die Ebene. Genau der Blick, um den es geht.
	#  • **Ein SCHMALER Standplatz.** `floor` 0,16 statt 0,60 — die flache Kuppe misst gut vier
	#    Meter im Radius statt sechzehn. Ein Ausguck ist ein Standplatz, kein Parkplatz: Der
	#    erste Versuch hatte ein Plateau, auf dem die Figur verloren stand wie auf einem Feld.
	#    Dazu zwei vorgelagerte Blöcke (siehe unten), damit es nicht EINE Form bleibt.
	#  • **`kerb` 0,27.** Der Umriss ist NICHT rund, sondern um bis zu 27 % je nach Richtung
	#    verzogen — Vorsprünge und Einbuchtungen statt eines Kegels. Ohne das bleibt jede
	#    Erhebung ein Hügel, egal wie steil sie ist.
	#
	# Die Rampe zeigt mit 135° zur Schrottgrube: Wer von dort kommt, findet den Aufstieg vor
	# sich; die Klippe liegt auf der Seite von Rustwater (−45°), also genau dort, wo man steht,
	# wenn man hinunterschaut.
	#
	# `scrap: false`, weil hier kein Müll liegt. Eine Anhöhe in der Wüste ist Fels, keine Halde.
	{ "id": "ausguck", "kind": "crater", "x": 348, "y": 214, "scrap": false,
		"radius": 27.0, "depth": -15.0, "rim": 0.0, "rim_width": 0.10, "kerb": 0.20, "fels": true, "step": 0.6,
		# `ramp_span` 96° statt 54°: Der Aufstieg war eine SCHLUCHT. 54° sind bei 27 m Radius am
		# Fuss zwar 25 m Bogen, aber `_rampen_anteil` blendet mit `smoothstep` von der Mitte nach
		# aussen aus — voll wirksam war davon nur der innere Kern, und was man beim Hochlaufen
		# sah, waren zwei Felswaende links und rechts und eine Rinne dazwischen. Der Weg auf einen
		# Aussichtsfelsen soll eine Flanke sein, die man hinaufgeht, keine Spalte, durch die man
		# sich zwaengt. Die Steigung in der Mitte aendert sich dadurch nicht — dort ist der
		# Rampenanteil in beiden Faellen 1 —, nur die Breite, auf der sie gilt.
		"floor": 0.16, "ramp_deg": 299.0, "ramp_span": 96.0,
		# Vier Gesteinsbaender mit flachen Absaetzen dazwischen — siehe `_terrassen`.
		"stufen": 4.0, "terrasse": 0.72,
		# Aufgesetzte Buckel: [Versatz x, Versatz z, Radius, Hoehe] in Metern vom Mittelpunkt.
		# Sie machen aus der einen Kuppe eine Stufenform mit Absaetzen und einem Nebengipfel.
		#
		# Warum INNERHALB der Form und nicht als zweite Erhebung daneben: Der Weltboden wird aus
		# Rechtecken gekachelt, in die je Gelaendeform EIN Loch geschnitten wird, und in das
		# Loch kommt der verformte Flicken. Zwei ueberlappende Formen schneiden ueberlappende
		# Loecher und legen zwei Flicken uebereinander — der Boden waere doppelt gezaehlt und die
		# beiden Netze wuerden um dieselbe Oberflaeche streiten. Als Buckel derselben Form ist es
		# ein Loch, ein Netz, eine Oberflaeche.
		# Beim Umzug nach Suedosten MITGEDREHT: −164,2°, genau der Winkel, um den sich die
		# Anlaufrichtung geaendert hat. Die Versaetze stehen in Metern vom Mittelpunkt und damit
		# in WELTachsen — laesst man sie stehen, waehrend der Fels umzieht, ist es derselbe Fels
		# aus einer anderen Richtung: Der Aufstieg laege an einer Flanke, der hoehere Gipfel
		# links statt rechts, und der Leuchtring faende keinen Platz mehr an der Kante. Gedreht
		# bleibt alles so, wie es festgezurrt wurde.
		"buckel": [
			[10.6, -4.3, 13.0, 4.5],    # Nebengipfel, etwas tiefer als die Hauptkuppe
			[-12.2, 2.8, 10.0, 3.0],    # Vorsprung ueber der Klippe zur Stadt hin
			[-0.6, -12.6, 15.0, -2.5],  # und eine Scharte, damit es nicht nur nach oben geht
		] },
	# Das Wellenmeer: ein Dünenfeld östlich von Rustwater, 220 m breit. Nicht an einem Ort
	# verankert, sondern frei auf der Karte — es IST die Landmarke.
	#
	# Warum überhaupt: Die Wüste ist bisher eine Tischplatte. Man läuft 900 m und die
	# Horizontlinie bewegt sich nicht. Dünen geben der Strecke einen Puls — man steigt, sieht
	# über den Kamm hinweg das nächste Tal, steigt wieder. Das kostet nichts außer der Formel.
	#
	# `wave` ist die Wellenlänge von Kamm zu Kamm, `amp` die Höhe, `skew` die Asymmetrie.
	#
	# Der erste Versuch stand bei 2,4 m auf 19 m — im Bild praktisch unsichtbar. Eine Düne
	# liest man nicht an ihrer Höhe, sondern an ihrem SCHATTEN, und der entsteht erst, wenn
	# die Leeseite steil genug ist. 5 m auf 42 m mit `skew` 0,55 ergibt eine flache Luvseite
	# (rund 13°) und eine steile Leeseite (rund 30°) — beide noch begehbar, aber mit einem
	# Schattenwurf, den man aus 100 m Entfernung sieht.
	#
	# `step` gröber als beim Krater: Bei 42 m Wellenlänge sieht man 2 m Netzauflösung nicht,
	# und ein 320-m-Feld in Kraterauflösung wären zwei Millionen Dreiecke.
	#
	# Auf y = 430 statt 500 gerückt: Der Strahlensumpf ist inzwischen ein Rechteck ab y = 520,
	# und der Nordrand des Dünenfelds lag bei 564 — mitten drin. Ein Dünenkamm, der aus einem
	# Moor ragt, ist keine Landschaft, sondern zwei Formeln, die sich nicht abgesprochen haben.
	# 26 Welteinheiten Abstand (65 m) sind genug, damit beides für sich steht.
	# ── Der Riss ──────────────────────────────────────────────────────────────
	#
	# Ein Spalt quer durch die Karte, zehn Meter breit, den man zunaechst nicht ueberquert.
	#
	# Sektor 1 und 2 trennen die Sprengtore, Sektor 2 und 3 die Smog-Linie. Beides sind
	# Bauwerke des Konzerns — Grenzen, die jemand gezogen hat. Der Riss ist die dritte Sorte
	# und die interessanteste: eine Grenze, die NIEMAND gezogen hat. Das gibt ihm eine Aufgabe,
	# die die anderen beiden nicht haben koennen — er ist der erste Hinweis darauf, dass mit
	# dieser Welt etwas nicht stimmt, lange bevor jemand erklaert, wer den Krater gemacht hat.
	#
	# Er laeuft nach Norden bei x = 700 und liegt damit rund einen Kilometer oestlich von
	# Rustwater: weit genug, dass der Prolog ihn nie beruehrt (Grube, Fels und Stadt liegen
	# alle westlich davon), nah genug, dass man ihn findet, sobald man sich umsieht. Zum
	# Rattengestruepp sind es 500 m, zum naechsten Sumpfloch 72 m.
	#
	# `schlenker` ist kein Schmuck: Ein schnurgerader Riss liest sich als Graben, den jemand
	# gezogen hat. Und `step_laengs` ist keine Feinabstimmung, sondern Notwendigkeit — quer
	# zaehlt jeder halbe Meter, laengs sieht man auf zweihundert nichts.
	{ "id": "ripple", "kind": "spalt", "x": 700, "y": 400, "achse": "nord",
		"laenge": 1900.0, "breite": 10.0, "tiefe": 40.0, "kante_m": 7.0,
		"schlenker": 26.0, "welle_m": 260.0, "auslauf_m": 110.0,
		"step": 0.6, "step_laengs": 6.0, "scrap": false },
	{ "id": "wellenmeer", "kind": "dunes", "x": 600, "y": 430,
		"radius": 160.0, "amp": 5.0, "wave": 42.0, "skew": 0.55,
		"dir_deg": 24.0, "step": 2.0 },
	# Kleine Einschläge im Strahlensumpf — dieselbe Formel wie die Schrotthalde, ein Drittel groß.
	#
	# Wozu: Der Sumpf war bisher eine grüne Fläche mit Pfützen darauf, also flach. Ein Loch im
	# Boden ist die billigste Art von Landschaft, die es gibt — es kostet neun Zeilen Zahlen und
	# verändert, wie man läuft: Man sieht erst den Wall, dann was dahinter liegt.
	#
	# Der erste Versuch war flach — `floor` um 0,45, Wand rund 30°, damit man ohne Rampe wieder
	# herauskommt. Im gerenderten Bild war das aus Spielerhöhe **kein Loch, sondern ein Ring auf
	# dem Boden**: 2,5 m Tiefe auf 23 m Breite sieht die Iso-Kamera nicht. Deshalb jetzt
	# dieselbe Bauart wie die Grube — steile Wand (50–55°), flacher Grund, und genau EIN Sektor,
	# in dem die Wand fehlt. Der Ausgang liegt bei jedem Loch woanders (`ramp_deg`).
	#
	# Der Rest unterscheidet sich von der Grube:
	#  • **`rim` 0 — kein Auswurfwall.** Er war da (0,5–0,85 m) und im Bild das Auffälligste am
	#    ganzen Krater: ein blassrosa Ring um jedes Loch. Der Wall ist die einzige Fläche weit
	#    und breit, die der tiefstehenden Sonne ihre Oberseite voll zudreht; unter dem
	#    Filmic-Tonemapping laufen die Lichter zusammen und der warme Sand kippt ins Rosa.
	#    Gemessen, indem derselbe Krater einmal mit und einmal ohne Wall gerendert wurde — ohne
	#    ihn ist der Ring restlos weg. Und aus Spielerhöhe liest sich das Loch DANACH besser:
	#    vorher ein heller Ring und darin nichts, jetzt eine Mulde mit Schatten. Die
	#    Schrottgrube behält ihren Wall — dort steht das Bild schon, und er liegt zur Hälfte
	#    unter Schrott.
	#  • **`step` 0,7 statt 0,35** — die Grube ist 5 m tief, hier sind es 3; die doppelte
	#    Auflösung wären viermal so viele Dreiecke ohne sichtbaren Gewinn.
	#  • **`ramp_span` 90° statt 70°** — bei einem Drittel der Größe wäre ein 70°-Sektor keine
	#    Rampe mehr, sondern eine Rinne.
	#  • **`scrap: false`** — `_fill_craters` schüttet sonst in jedes Loch der Welt einen
	#    Schrottteppich. Im Sumpf liegt kein Schrott, dort liegt Wasser.
	#
	# Sechs der neun liegen im 350-m-Fenster um die Bahnquerung, wo praktisch jeder durchkommt;
	# drei stehen weiter östlich, damit der Sumpf abseits nicht plötzlich glatt wird. Keiner
	# liegt näher als 75 m an der Trasse — `_ribbon_step` zieht das Gleisbett sonst in den
	# Krater hinein, und eine Bahnlinie durch ein Loch sieht man sofort.
	{ "id": "sumpfloch_1", "kind": "crater", "x": 283, "y": 599,
		"radius": 11.6, "depth": 3.2, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.70, "ramp_deg": 210, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_2", "kind": "crater", "x": 328, "y": 654,
		"radius": 12.0, "depth": 3.4, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.68, "ramp_deg": 40, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_3", "kind": "crater", "x": 370, "y": 694,
		"radius": 10.6, "depth": 2.8, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.72, "ramp_deg": 150, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_4", "kind": "crater", "x": 393, "y": 691,
		"radius": 13.6, "depth": 3.8, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.66, "ramp_deg": 300, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_5", "kind": "crater", "x": 459, "y": 576,
		"radius": 9.9, "depth": 2.6, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.70, "ramp_deg": 95, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_6", "kind": "crater", "x": 544, "y": 696,
		"radius": 13.1, "depth": 3.4, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.68, "ramp_deg": 20, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_7", "kind": "crater", "x": 610, "y": 558,
		"radius": 11.2, "depth": 3.0, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.72, "ramp_deg": 250, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_8", "kind": "crater", "x": 667, "y": 575,
		"radius": 12.4, "depth": 3.2, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.66, "ramp_deg": 120, "ramp_span": 90.0, "step": 0.7, "scrap": false },
	{ "id": "sumpfloch_9", "kind": "crater", "x": 852, "y": 621,
		"radius": 12.4, "depth": 3.0, "rim": 0.00, "rim_width": 0.00,
		"floor": 0.70, "ramp_deg": 330, "ramp_span": 90.0, "step": 0.7, "scrap": false },
]


## Bodenhöhe an einem Punkt (Szenenmeter). Ausserhalb aller Formen exakt 0.
static func height_at(x: float, z: float) -> float:
	var h: float = 0.0
	for f in TERRAIN:
		var c: Vector3 = feature_center(f)   # Ort ODER freie Koordinate, siehe `feature_center`
		h += _feature_height(f, Vector2(x - c.x, z - c.z))
	return h


## Das Höhenprofil des RISSES.
##
## Gerechnet wird nicht der Abstand zu einem Punkt, sondern der Abstand zu einer **Linie** —
## sonst dieselbe Rechnung wie bei allen anderen Formen, und deshalb gilt sie automatisch für
## Laufen, Fußspuren, Streuung, Figuren und Kisten. Ein aufgestelltes Modell wüsste davon nichts:
## Man liefe hindurch, die Fußspur ginge darüber weg, Gegner ständen in der Luft.
##
## Drei Zonen quer zur Achse:
##
##   1. **Innen** (bis `breite`/2): der Abgrund, flach bei −`tiefe`. So tief, dass unten nichts
##      mehr zu erkennen ist — was man sieht, ist Schwärze, und das ist die Absicht.
##   2. **Die Kante** (`breite`/2 … + `kante_m`): der Abbruch. Über `kante_m` Meter geht es von
##      null auf volle Tiefe, mit waagerechtem Anschluss oben, damit man nicht schon drei Meter
##      vorher zu rutschen anfängt.
##   3. **Außen**: die Ebene, unberührt.
##
## Der **Schlenker** ist kein Schmuck. Ein schnurgerader Riss liest sich als Graben, den jemand
## gezogen hat; genau das ist er nicht. Zwei überlagerte Sinuswellen mit unterschiedlicher Länge
## geben ihm einen Verlauf, der keine Periode erkennen lässt.
static func _spalt_height(f: Dictionary, off: Vector2) -> float:
	var laengs: float = off.y if _spalt_laeuft_nord(f) else off.x
	var quer: float = off.x if _spalt_laeuft_nord(f) else off.y
	var halb_l: float = float(f["laenge"]) * 0.5
	if absf(laengs) > halb_l:
		return 0.0
	# Der Verlauf: zwei Wellen, deren Längen nicht ineinander aufgehen.
	var schlenker: float = float(f.get("schlenker", 0.0))
	if schlenker > 0.0:
		var w1: float = float(f.get("welle_m", 260.0))
		quer -= schlenker * (sin(laengs / w1 * TAU) * 0.62
			+ sin(laengs / (w1 * 0.37) * TAU + 1.1) * 0.38)
	var d: float = absf(quer)
	var innen: float = float(f["breite"]) * 0.5
	var kante: float = float(f.get("kante_m", 6.0))
	if d >= innen + kante:
		return 0.0
	var tiefe: float = float(f["tiefe"])
	if d <= innen:
		var t_ende: float = 1.0
		# An den beiden ENDEN läuft der Riss aus, statt als Rechteck aufzuhören. Ein Abgrund mit
		# senkrechter Stirnwand mitten in der Ebene wäre ein Bauteil, kein Riss.
		var aus: float = float(f.get("auslauf_m", 90.0))
		if halb_l - absf(laengs) < aus:
			t_ende = smoothstep(0.0, 1.0, (halb_l - absf(laengs)) / aus)
		return -tiefe * t_ende
	# Die Kante. `smoothstep` setzt an beiden Enden waagerecht an — oben also kein Knick, an dem
	# man hängenbleibt, unten kein Trichter, der zum Hineinrutschen einlädt.
	var k: float = smoothstep(0.0, 1.0, 1.0 - (d - innen) / kante)
	var t_ende2: float = 1.0
	var aus2: float = float(f.get("auslauf_m", 90.0))
	if halb_l - absf(laengs) < aus2:
		t_ende2 = smoothstep(0.0, 1.0, (halb_l - absf(laengs)) / aus2)
	return -tiefe * k * t_ende2


## Höhenprofil einer Form über den Abstand zur Mitte — jetzt richtungsabhängig (Rampe).
##
## Drei Abschnitte, alle mit waagerechtem Anschluss; es gibt also keine Kante, an der man
## hängenbleibt oder die als harter Knick auffällt:
##
##   1. **Grund** (0 … radius·floor): flach bei −depth. Dort liegt man beim Erwachen, dort
##      steht der Schrott, dort steht die Lache.
##   2. **Wand** (radius·floor … radius): `-depth · (1 − smoothstep(…))`, aber über eine
##      SCHMALE Spanne. Bei floor 0,78 sind das 3,3 m waagerecht auf 5 m senkrecht — im
##      Mittel 57°, an der steilsten Stelle 66°. Eine Wand, keine Böschung.
##   3. **Wall** (radius … radius·(1+rim_width)): `rim · sin²(…)`. Der Auswurf, den ein
##      Einschlag nach außen wirft. Sinus-Quadrat, weil es an beiden Enden waagerecht ansetzt.
##
## Die Rampe entsteht dadurch, dass `floor` in ihrem Sektor gegen 0 läuft — dann fällt
## Abschnitt 1 weg und Abschnitt 2 zieht sich über den ganzen Radius. Das ist exakt das alte
## Schüsselprofil (höchstens 27° bei 5 m Tiefe), nur eben nicht mehr rundum.
static func _feature_height(f: Dictionary, off: Vector2) -> float:
	var art: String = String(f.get("kind", "crater"))
	if art == "dunes":
		return _dune_height(f, off)
	if art == "spalt":
		return _spalt_height(f, off)
	# Der Umriss muss nicht rund sein. `kerb` verzieht den Radius je nach Richtung — aus dem
	# Kreis wird eine unregelmaessige Form mit Vorspruengen und Einbuchtungen. Ohne das ist
	# jede Erhebung ein Kegel, und ein Kegel liest sich als Huegel, nie als Fels.
	var radius: float = float(f["radius"]) * _kerbung(f, off)
	var t: float = off.length() / radius
	var w: float = float(f["rim_width"])
	if t >= 1.0 + w:
		return 0.0
	if t > 1.0:
		var s: float = sin(PI * (t - 1.0) / w)
		return float(f["rim"]) * s * s
	var k_rampe: float = _rampen_anteil(f, off)
	var boden: float = float(f.get("floor", 0.0)) * (1.0 - k_rampe)
	var buckel: float = _buckel_height(f, off)
	if t <= boden:
		return -float(f["depth"]) + buckel
	var u: float = (t - boden) / maxf(1.0 - boden, 0.0001)
	# Zwei Wandprofile, und der Unterschied ist der zwischen Düne und Fels.
	#
	# `smoothstep` setzt an BEIDEN Enden waagerecht an. Für eine ausgewaschene Erdwand ist das
	# richtig — oben rundet die Kante ab, unten läuft sie in den Boden. Für einen Felsen ist es
	# falsch: Die abgerundete Oberkante ist genau das, was ihn im Bild zur Kuppel macht, egal
	# wie steil die Flanke dazwischen ist.
	#
	# Deshalb für `fels` eine Potenz: `(1−u)^1,8` steht an der Oberkante am steilsten (68° bei
	# der Anhöhe) und flacht nach unten ab — die Kante ist eine Kante, und am Fuß legt sich der
	# Sand an. Das ist die Silhouette einer Tafelberg-Kuppe, und die erkennt man als Stein.
	if bool(f.get("fels", false)):
		# Terrassiert — ausser im Aufstieg: Eine Treppe dort waere ein Weg, den die
		# Steigungsgrenze sperrt, und der Fels haette keinen Zugang mehr.
		var q: float = _terrassen(pow(1.0 - u, 1.8), float(f.get("stufen", 4.0)),
			float(f.get("terrasse", 0.0)) * (1.0 - k_rampe))
		return -float(f["depth"]) * q + buckel * (1.0 - u)
	return -float(f["depth"]) * (1.0 - smoothstep(0.0, 1.0, u)) + buckel * (1.0 - u)


## Aufgesetzte Buckel einer Form: weiche Kuppen (und Scharten, bei negativer Hoehe), die auf das
## Grundprofil addiert werden.
##
## Sie sind das, was aus einer Kuppe einen FELSEN macht: Absaetze, ein Nebengipfel, eine
## Scharte. Weich (`smoothstep`), weil ein Buckel keine eigene Kante haben soll — die Kante
## liefert das Grundprofil, der Buckel nur die Unregelmaessigkeit darunter.
static func _buckel_height(f: Dictionary, off: Vector2) -> float:
	var liste: Array = f.get("buckel", [])
	if liste.is_empty():
		return 0.0
	var h: float = 0.0
	for b in liste:
		var d: float = off.distance_to(Vector2(float(b[0]), float(b[1])))
		var r: float = float(b[2])
		if d >= r:
			continue
		h += float(b[3]) * (1.0 - smoothstep(0.0, 1.0, d / r))
	return h


## Höhenprofil eines Dünenfelds. Zwei überlagerte Wellen und ein weicher Rand.
##
## Die Hauptwelle quer zum Wind erzeugt die Kämme. Allein sähe sie aus wie ein Wellblechdach:
## endlos gleiche, exakt parallele Rippen. Deshalb kommt eine zweite, viel längere Welle LÄNGS
## der Kämme dazu, die sie durchmoduliert — mal höher, mal flacher, mit versetzten Sätteln.
## Das ist der Unterschied zwischen „gewellt" und „Dünen".
##
## Die Höhe bleibt immer ≥ 0: Ein Dünenfeld liegt AUF der Ebene, es gräbt sich nicht ein.
## Am Rand blendet `smoothstep` es auf null aus, sonst stünde dort eine Stufe.
static func _dune_height(f: Dictionary, off: Vector2) -> float:
	var radius: float = float(f["radius"])
	var d: float = off.length()
	if d >= radius:
		return 0.0
	var a: float = deg_to_rad(float(f.get("dir_deg", 0.0)))
	var wave: float = maxf(float(f.get("wave", 20.0)), 0.1)
	# Längs = in Windrichtung (quer zu den Kämmen), quer = an den Kämmen entlang.
	var laengs: float = (off.x * cos(a) + off.y * sin(a)) / wave
	var quer: float = (-off.x * sin(a) + off.y * cos(a)) / (wave * 2.6)
	# Phasenverzerrung statt reiner Sinus: `theta + skew·sin(theta)` schiebt den Nulldurchgang
	# zur Seite und macht aus der symmetrischen Welle eine Düne — flach angeweht, steil
	# abfallend. Ohne das ist es ein Wellblechdach, egal wie hoch.
	var theta: float = TAU * laengs
	var kamm: float = 0.5 + 0.5 * sin(theta + float(f.get("skew", 0.0)) * sin(theta))
	var mod: float = 0.55 + 0.45 * sin(TAU * quer + 1.1)
	var rand: float = 1.0 - smoothstep(0.0, 1.0, d / radius)
	return float(f.get("amp", 2.0)) * kamm * mod * rand


## Wie viel des Radius ist an DIESER Stelle flacher Grund? In der Rampe: nichts.
##
## Der Übergang läuft über `smoothstep` statt hart auf den Sektor — sonst stünde links und
## rechts der Rampe je eine senkrechte Kante im Gelände, an der man entlangschrammt.
## Verzerrung des Radius je Richtung (1,0 = rund).
##
## Zwei Sinus mit unrunden Vielfachen (3 und 5) statt eines einzelnen: Ein einzelner ergibt eine
## Ellipse, drei Perioden allein eine gleichseitige Form, die man als Muster erkennt. Die
## Ueberlagerung wiederholt sich erst nach einer vollen Umdrehung und liest sich als gewachsen.
##
## Kein Rauschen: Das Gelaende ist eine FORMEL, die an tausend Stellen im Spiel abgefragt wird
## (Laufen, Fussspuren, Streuung, jede Figur). Sie muss ueberall dasselbe liefern und darf
## nichts kosten — zwei Sinus tun beides, eine Rauschtextur keins von beidem.
static func _kerbung(f: Dictionary, off: Vector2) -> float:
	var k: float = float(f.get("kerb", 0.0))
	if k <= 0.0 or off.length_squared() < 0.000001:
		return 1.0
	# Der groesste VORSPRUNG liegt auf der Rampe. Das ist keine Feinabstimmung, sondern die
	# Regel dahinter: Wo ein Fels einen Sporn hat, laeuft der Weg hinauf — und umgekehrt ist der
	# Aufstieg dort am flachsten, wo am meisten Material liegt.
	#
	# Ohne das war die Rampe steiler als die Steigungsgrenze und damit selbst gesperrt: Bei
	# gleicher Hoehe faellt der Anstieg umso steiler aus, je kuerzer die Strecke bis zum Fuss
	# ist — und die Verzerrung hatte den Radius ausgerechnet dort verkuerzt.
	var a: float = atan2(-off.y, off.x) - deg_to_rad(float(f.get("ramp_deg", 0.0)))
	return 1.0 + k * (sin(a * 3.0 + PI * 0.5) * 0.62 + sin(a * 5.0 + PI * 0.5) * 0.38)


static func _floor_share(f: Dictionary, off: Vector2) -> float:
	return float(f.get("floor", 0.0)) * (1.0 - _rampen_anteil(f, off))


## Wie stark liegt dieser Punkt IM Rampensektor? 0 = gar nicht, 1 = mittendrin.
##
## Steht getrennt, weil zwei Dinge davon abhaengen: der flache Grund (der in der Rampe
## verschwindet) und die Terrassierung (die dort NICHT stattfinden darf — eine Treppe im
## Aufstieg waere ein Aufstieg, den die Steigungsgrenze sperrt).
static func _rampen_anteil(f: Dictionary, off: Vector2) -> float:
	if off.length_squared() < 0.000001:
		return 0.0
	var halb: float = deg_to_rad(float(f.get("ramp_span", 0.0))) * 0.5
	if halb <= 0.0:
		return 0.0
	var ziel: float = deg_to_rad(float(f.get("ramp_deg", 0.0)))
	# Winkel des Punktes. `off` ist (x, z); Norden ist −z, deshalb das Minus.
	var ang: float = atan2(-off.y, off.x)
	var d: float = absf(wrapf(ang - ziel, -PI, PI))
	return 1.0 - smoothstep(0.0, 1.0, clampf(d / halb, 0.0, 1.0))


## Terrassen: aus einer glatten Flanke werden Baender mit flachen Absaetzen und steilen Stufen.
##
## Das ist der Unterschied zwischen einem Erdhaufen und geschichtetem Gestein. Ein Fels bricht
## nicht als glatte Kurve ab, sondern in Baendern — weiche Schichten waschen aus, harte bleiben
## als Vorsprung stehen. Im Bild ist das der Grund, warum man Fels ueberhaupt als Fels erkennt:
## die waagerechten Kanten, an denen sich Licht und Schatten trennen.
##
## `staerke` blendet zwischen der glatten Kurve und der Treppe. Ganz auf 1 waere es eine
## Hochzeitstorte; 0,7 laesst die Grundform durch und legt die Baender darueber.
static func _terrassen(q: float, stufen: float, staerke: float) -> float:
	if staerke <= 0.001 or stufen < 1.0:
		return q
	var sx: float = clampf(q, 0.0, 1.0) * stufen
	var i: float = floor(sx)
	# Absatz (flach) bis 0,62, dann die Stufe (steil). Genau umgekehrt zur Intuition: Der
	# flache Teil ist das BREITE Band, die Stufe der schmale Absturz dazwischen.
	var stufig: float = (i + smoothstep(0.62, 1.0, sx - i)) / stufen
	return lerpf(q, stufig, staerke)


## Normale des Bodens — aus der Formel abgeleitet statt aus Nachbardreiecken gemittelt.
static func normal_at(x: float, z: float, eps: float = 0.25) -> Vector3:
	var dx: float = height_at(x + eps, z) - height_at(x - eps, z)
	var dz: float = height_at(x, z + eps) - height_at(x, z - eps)
	return Vector3(-dx, 2.0 * eps, -dz).normalized()


## Aussenradius einer Form inklusive Wall — bis hierhin muss ein Geländeflicken reichen.
static func feature_reach(f: Dictionary) -> float:
	var art: String = String(f.get("kind", "crater"))
	if art == "dunes":
		return float(f["radius"])
	# Beim Riss ist „Reichweite" die QUERausdehnung — das ist die Zahl, die alle Aufrufer
	# brauchen, die nach einem Sicherheitsabstand fragen. Für Flächen gibt es `feature_halb()`.
	if art == "spalt":
		return _spalt_reichweite(f)
	# `kerb` MUSS hier hinein: Es verlaengert den Radius je nach Richtung, und ein Loch, das
	# davon nichts weiss, ist auf der breitesten Seite zu klein — dort laege die flache
	# Bodenplatte ueber dem Fels.
	return float(f["radius"]) * (1.0 + float(f["rim_width"]) + float(f.get("kerb", 0.0)))


## Halbe Ausdehnung einer Form in x und z (Szenenmeter).
##
## Bis hierher war jede Geländeform rund, und ein einziger `feature_reach()` reichte für alles:
## das Loch im Boden, den verformten Flicken darüber, die Streuung. Der **Riss** ist die erste
## Form, die nicht rund ist — 10 m breit und 1900 m lang. Mit `reach` als Quadrat wäre das Loch
## im Boden 1900 × 1900 m groß, also ein Drittel der Welt.
##
## Deshalb fragt alles, was eine FLÄCHE braucht, ab jetzt hier nach und nicht mehr bei `reach`.
## Für runde Formen kommt dasselbe heraus wie vorher; nur der Riss antwortet mit einem Streifen.
static func feature_halb(f: Dictionary) -> Vector2:
	if String(f.get("kind", "crater")) == "spalt":
		var halb_l: float = float(f["laenge"]) * 0.5
		var halb_b: float = _spalt_reichweite(f)
		return Vector2(halb_b, halb_l) if _spalt_laeuft_nord(f) else Vector2(halb_l, halb_b)
	var r: float = feature_reach(f)
	return Vector2(r, r)


## Läuft der Riss nach Norden (entlang z) oder nach Osten (entlang x)?
static func _spalt_laeuft_nord(f: Dictionary) -> bool:
	return String(f.get("achse", "nord")) == "nord"


## Wie weit der Riss quer zu seiner Achse reicht: halbe Breite, Kante und der ganze Schlenker.
##
## Der Schlenker muss mit hinein. Ein Riss, der schnurgerade läuft, sieht aus wie ein Graben, den
## jemand gezogen hat — und genau das soll er nicht sein. Er schlängelt also, und das Loch im
## Boden muss den ganzen Schlenker fassen, sonst liegt die flache Platte über dem Spalt.
static func _spalt_reichweite(f: Dictionary) -> float:
	return float(f["breite"]) * 0.5 + float(f.get("kante_m", 6.0)) + float(f.get("schlenker", 0.0))


## Mittelpunkt einer Form in Szenenmetern.
##
## Zwei Verankerungen: an einem ORT (`poi`) oder frei auf der Karte (`x`/`y` in Welteinheiten).
## Der Krater gehört zu den Schrott-Minen und muss mitwandern, wenn der Ort verschoben wird;
## ein Dünenfeld gehört nirgendwohin — es ist selbst die Landmarke.
static func feature_center(f: Dictionary) -> Vector3:
	if f.has("poi"):
		return poi_scene_position(String(f["poi"]))
	return world_to_scene(Vector2(float(f["x"]), float(f["y"])))


# ── Weltstruktur: offene Wildnis + baulich begrenzte Aktionszonen (GDD §1.4a) ──
## Gemischtes Modell statt „alles offen" oder „alles Schlauch":
##  • **Wildnis** — die Wüste zwischen den Orten ist FREI begehbar. Weite, Reisezeit,
##    Landmark-Navigation und Biom-Takt aus §1.4 bleiben vollständig erhalten.
##  • **Aktionszonen** — Städte, Basen, Dungeons und Arenen sind **baulich** begrenzt
##    (Mauern, Palisaden, Geländer, Felskanten). Dort spielt der Kampf, dort ist es eng
##    und geführt wie in mobilen Action-RPGs. Die Grenzen sind echte Objekte, keine
##    unsichtbaren Wände — die Kollision setzt die Szene über ihre Bauten.
##  • **Eisenbahn** — verbindet die Hauptorte und ersetzt später den langen Fußmarsch.
## Alle Werte in relativen Weltkoordinaten (0…2000); ×METERS_PER_UNIT ergibt Meter.

## Radius einer Aktionszone um einen POI (dort greifen bauliche Begrenzung & Stadtregeln).
const ZONE_RADIUS_HUB: float = 46.0        # ≈ 115 m — Rustwater & Fraktionsbasen
const ZONE_RADIUS_DEFAULT: float = 26.0    # ≈ 65 m  — Dungeons, Jagdgründe, Arenen
## Halbe Breite des freizuhaltenden Streifens um die Iron-Rail-Trasse, in WELTEINHEITEN
## (`on_rail`). 3 Einheiten sind 7,5 m nach jeder Seite — Schotterbett (6,2 m) plus etwas Luft.
##
## Der Vorgaenger `CORRIDOR_HALF_W` stand bei 11 Einheiten = 27,5 m JE SEITE und galt fuer alle
## Routen. Sein Kommentar las „≈ 27 m breite Piste" und meinte damit die volle Breite — der
## Zahlendreher hat die gezeichnete Piste auf 55 m aufgeblasen, breiter als der 30-m-Krater der
## Schrotthalde. Die Pisten sind inzwischen ganz raus; was bleibt, ist die Trasse.
const RAIL_CORRIDOR_HALF_W: float = 3.0

## Nachbarschaft der Orte — welcher Ort mit welchem verbunden ist.
##
## Reine Topologie, keine Optik: Gezeichnet wird davon nur noch die Iron-Rail-Trasse
## (`rail_segments`, die Teilmenge mit Bahnhof an beiden Enden). Die gestampften Pisten, die
## hier frueher auch herauskamen, gibt es nicht mehr — in einer offenen Wueste, in der man
## ohnehin quer laeuft, war eine Strasse ohne Ziel nur ein Band auf dem Boden.
const ROUTES: Array = [
	["rustwater", "rattengestruepp"], ["rustwater", "schrott_minen"], ["rustwater", "zugdepot"],
	# Der Stollen liegt am Weg zwischen Stadt und Grube — genau das soll die Route auch zeigen.
	["rustwater", "stollen"], ["stollen", "schrott_minen"],
	["zugdepot", "rogues_landing"], ["rogues_landing", "fort_freedom"],
	["rogues_landing", "sektor01"], ["rogues_landing", "alchemie_raffinerie"],
	["fort_freedom", "goliath_testgelaende"], ["sektor01", "schmelzoefen_vulcan"],
	["alchemie_raffinerie", "eisernes_herz"],
]

## Bahnhöfe der Iron Rail: nur echte Knoten (GDD §1.4). Reisen zwischen ihnen ersetzt
## später den Fußmarsch; die Trasse verläuft entlang der Routen zwischen diesen Orten.
const RAIL_STATIONS: Array = ["rustwater", "zugdepot", "rogues_landing", "fort_freedom", "sektor01"]

static func has_station(poi_id: String) -> bool:
	return RAIL_STATIONS.has(poi_id)

## Trassenabschnitte der Iron Rail: alle Routen, deren BEIDE Enden einen Bahnhof haben.
## Damit liegt das Schienennetz zwangsläufig auf den bestehenden Straßen — es gibt keine
## zweite, widersprüchliche Geografie.
static func rail_segments() -> Array:
	var out: Array = []
	for r in ROUTES:
		if has_station(String(r[0])) and has_station(String(r[1])):
			out.append([String(r[0]), String(r[1])])
	return out

## Befriedete Zone: dort spawnt nichts Feindliches. Der Hub immer, Fraktionsbasen nur,
## solange die eigene Gilde dort willkommen ist (§1.7.3).
static func is_safe_zone(poi_id: String) -> bool:
	var t: String = String(poi(poi_id).get("type", ""))
	if t == "hub":
		return true
	return t == "base" and is_base_friendly(poi_id)

## Radius der Aktionszone eines POI (Hubs & Basen weiter, Rest enger).
static func zone_radius(poi_id: String) -> float:
	var t: String = String(poi(poi_id).get("type", ""))
	return ZONE_RADIUS_HUB if (t == "hub" or t == "base") else ZONE_RADIUS_DEFAULT

## Kürzester Abstand eines Punktes zur Strecke a→b (Standard-Punkt-Segment-Distanz).
static func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

## In welcher Aktionszone steht der Punkt? ("" = offene Wildnis)
static func zone_at(rel: Vector2) -> String:
	for id in POIS.keys():
		if rel.distance_to(poi_position(String(id))) <= zone_radius(String(id)):
			return String(id)
	return ""

static func in_action_zone(rel: Vector2) -> bool:
	return zone_at(rel) != ""

## Steht der Punkt auf der Iron-Rail-Trasse? (Keine Sperre — man kann ueber die Gleise laufen.
## Die Abfrage sagt nur: hier darf nichts hingestreut werden, sonst waechst ein Kaktus zwischen
## den Schwellen.)
##
## Loeste `on_route` ab, das dasselbe fuer alle ROUTES tat. Solange es Pisten gab, war das
## richtig — mit ihnen ist der Grund weggefallen: Ein unsichtbarer 55-m-Streifen quer durch
## die Wueste, in dem nichts steht, ist keine Wegfuehrung mehr, sondern eine leere Gasse ohne
## erkennbaren Anlass. Die Trasse dagegen liegt sichtbar da und muss frei bleiben.
static func on_rail(rel: Vector2) -> bool:
	for r in rail_segments():
		if _dist_to_segment(rel, poi_position(String(r[0])), poi_position(String(r[1]))) <= RAIL_CORRIDOR_HALF_W:
			return true
	return false

## Liegt die Position im begehbaren Teil der Welt? Die Wüste ist offen — begrenzt wird nur
## durch den Kraterrand (Außengrenze der Welt). Bauten sperren zusätzlich lokal, das
## entscheidet aber die Szene über ihre Kollisionsobjekte, nicht diese Geografie-Schicht.
static func is_walkable(rel: Vector2) -> bool:
	return rel.x >= 1.0 and rel.x <= float(WORLD_SIZE) - 1.0 \
		and rel.y >= 1.0 and rel.y <= float(WORLD_SIZE) - 1.0

## Nächstgelegene gültige Position innerhalb des Kraters (Rückfall nach Schnellreise,
## Rückstoß oder einem Spielstand aus einer älteren Fassung).
static func nearest_walkable(rel: Vector2) -> Vector2:
	return Vector2(
		clampf(rel.x, 1.0, float(WORLD_SIZE) - 1.0),
		clampf(rel.y, 1.0, float(WORLD_SIZE) - 1.0))

# ── Gating-Parameter ──────────────────────────────────────────────────────────
const BLAST_GATE_CHAPTER: int = 5              # ab hier ist der Panzerzug durchgebrochen
const REFINERY_BUILDING: String = "laboratory" # Raffinerie/Labor fürs Smog-Gate (§1.7.2)
const FILTER_REQUIRED_LEVEL: int = 3           # Alchemie-Filter ab Gebäudestufe 3
const SMOG_LETHAL_SECONDS: float = 3.0         # Smog tickt Leben in 3 s auf 0

## Fraktions-HQs → besitzende Gilde (für dynamische Feindseligkeit, §1.7.3).
const BASE_GUILD: Dictionary = {
	"fort_freedom": "rebels",
	"sektor01": "corp",
	"rogues_landing": "smugglers",
}

## Points of Interest (Master-GDD §1.6.1). `sector` 1–3; `multilevel`/`floors` für Dungeons.
const POIS: Dictionary = {
	# ── Sektor 1 (Kapitel 1–4) ──
	"rustwater":            { "name": "Rustwater Hub & Basis", "x": 300, "y": 300, "sector": 1, "type": "hub" },
	# SUEDOESTLICH von Rustwater, nicht nordwestlich — und das ist eine Lichtfrage.
	#
	# Sonne und Mond stehen fest (siehe `DayCycle`), die Sonne im Suedosten. Der Prolog ist ein
	# langer Fussmarsch von der Grube zur Stadt, und der lief bisher genau in sie hinein:
	# Uebereinstimmung von Laufrichtung und Lichtrichtung −0,99, also volle Gegenlichtlage. Die
	# Kamera steht hinter der Figur, sah also die ganze Zeit ihre Schattenseite, und Rustwater
	# lag als Silhouette im Dunst. Von Suedosten aus laeuft man mit dem Licht im Ruecken: +0,99.
	# Dieselbe Rechnung gilt fuer den Ausguck — der Blick ins Tal geht jetzt vom Licht weg statt
	# hinein.
	#
	# Die Entfernung bleibt fast gleich (515 m statt 530 m), und zum Rattengestruepp sind es
	# noch 320 m. Die Ecke ist also weder leerer noch enger geworden.
	"schrott_minen":        { "name": "Die Schrott-Minen", "x": 400, "y": 120, "sector": 1, "type": "dungeon", "multilevel": true, "floors": 3 },
	"rattengestruepp":      { "name": "Das Rattengestrüpp", "x": 500, "y": 200, "sector": 1, "type": "hunting" },
	# Der Stollen ist ein ORT und nicht nur ein Loch. Vorher war er eine Stelle, an der
	# plötzlich ein Knopf erschien: nicht auf der Karte, nicht in der Wegweisung, kein Ziel für
	# einen Auftrag. Als POI kann die Fußspur dorthin führen, und Silas kann jemanden
	# hinschicken.
	"stollen":              { "name": "Der Vorschacht", "x": 210, "y": 380, "sector": 1, "type": "dungeon" },
	"zugdepot":             { "name": "Iron Rail Zugdepot", "x": 450, "y": 750, "sector": 1, "type": "boss_arena", "gate": "blast" },
	# ── Sektor 2 (Kapitel 5–8) ──
	"fort_freedom":         { "name": "Fort Freedom", "x": 200, "y": 1200, "sector": 2, "type": "base", "guild": "rebels" },
	"sektor01":             { "name": "Sektor 01", "x": 1700, "y": 1300, "sector": 2, "type": "base", "guild": "corp" },
	"rogues_landing":       { "name": "Rogue's Landing", "x": 950, "y": 950, "sector": 2, "type": "base", "guild": "smugglers" },
	"alchemie_raffinerie":  { "name": "Alchemie-Raffinerie", "x": 1000, "y": 1450, "sector": 2, "type": "refinery", "gate": "smog" },
	# ── Sektor 3 (Kapitel 9–12) ──
	"goliath_testgelaende": { "name": "Goliath-Testgelände", "x": 600, "y": 1750, "sector": 3, "type": "openworld" },
	"schmelzoefen_vulcan":  { "name": "Schmelzöfen von Vulcan", "x": 1400, "y": 1800, "sector": 3, "type": "dungeon", "multilevel": true, "floors": 4 },
	"eisernes_herz":        { "name": "Das Eiserne Herz", "x": 1000, "y": 1950, "sector": 3, "type": "final_dungeon", "multilevel": true, "floors": 5 },
}


# ── Biom-Zonierung: Daten (Master-GDD §1.6.3) ─────────────────────────────────
## Portiert aus dem validierten Web-Prototyp: geografische Zonen mit eigener Palette,
## Deko-Flora und Gegner-Leitmix; an die Sektor-Tore (§1.7) gebunden. `cx/cy/radius` in
## Weltkoordinaten (m) — Vector2 bewusst nicht im const (Konstant-Ausdrucks-Sicherheit).
const UNIQUE_CHAMPION_CHANCE: float = 0.30   # Kritter-Hallen: Chance auf benannten Unique

const BIOMES: Dictionary = {
	"desert":          { "name": "Wüste", "sector": 1, "flora": ["cactus"], "hazard": "" },
	"salt":            { "name": "Salzpfanne", "sector": 1, "cx": 250, "cy": 680, "radius": 220, "flora": ["salt"], "hazard": "" },
	"oasis":           { "name": "Grüne Senke", "sector": 1, "cx": 550, "cy": 250, "radius": 200, "flora": ["tree", "water"], "hazard": "" },
	"rostwald":        { "name": "Rostwald", "sector": 2, "cx": 1120, "cy": 1080, "radius": 320, "flora": ["tree"], "hazard": "" },
	"kupfer_hochland": { "name": "Kupfer-Hochland", "sector": 2, "cx": 1750, "cy": 1350, "radius": 280, "flora": ["rock"], "hazard": "" },
	"smog_oedland":    { "name": "Smog-Ödland", "sector": 3, "flora": ["deadtree"], "hazard": "smog" },
}

## Gegner-Leitmix je Biom [Typ, Gewicht], pre-/post-Reveal (verschiebt sich mechanisch).
const ENEMY_POOLS: Dictionary = {
	"desert":          { "pre": [["outlaw", 4], ["fauna", 3], ["revolver", 2], ["konstrukt", 1]], "post": [["outlaw", 3], ["fauna", 2], ["revolver", 2], ["konstrukt", 4], ["klaeffer", 3]] },
	"oasis":           { "pre": [["fauna", 4], ["outlaw", 3], ["revolver", 1], ["konstrukt", 1]], "post": [["fauna", 4], ["klaeffer", 3], ["outlaw", 2], ["konstrukt", 2], ["revolver", 1]] },
	"salt":            { "pre": [["revolver", 4], ["outlaw", 4], ["fauna", 1]], "post": [["revolver", 3], ["outlaw", 3], ["konstrukt", 3], ["klaeffer", 1]] },
	"rostwald":        { "pre": [["fauna", 5], ["outlaw", 2], ["revolver", 1], ["konstrukt", 1]], "post": [["fauna", 4], ["klaeffer", 4], ["konstrukt", 2], ["outlaw", 1]] },
	"kupfer_hochland": { "pre": [["revolver", 3], ["outlaw", 3], ["konstrukt", 2], ["fauna", 1]], "post": [["konstrukt", 5], ["klaeffer", 3], ["revolver", 2], ["outlaw", 1]] },
	"smog_oedland":    { "pre": [["konstrukt", 5], ["klaeffer", 4], ["goliath", 1]], "post": [["konstrukt", 5], ["klaeffer", 4], ["goliath", 2]] },
}

## Reihenfolge der benannten Kreiszonen (erste Übereinstimmung gewinnt). Smog-Ödland = ganzer Sektor 3.
const BIOME_ZONE_ORDER: Array = ["oasis", "salt", "rostwald", "kupfer_hochland"]


# ── POI-Abfragen ──────────────────────────────────────────────────────────────

static func has_poi(poi_id: String) -> bool:
	return POIS.has(poi_id)

static func poi(poi_id: String) -> Dictionary:
	assert(POIS.has(poi_id), "WorldManager: unbekannter POI '%s'" % poi_id)
	return POIS[poi_id]

static func poi_position(poi_id: String) -> Vector2:
	var p: Dictionary = poi(poi_id)
	return Vector2(float(p["x"]), float(p["y"]))

static func dungeon_floors(poi_id: String) -> int:
	# 0 = kein (multilevel) Dungeon; 1 = einstufige Arena (z. B. Zugdepot).
	var p: Dictionary = poi(poi_id)
	if bool(p.get("multilevel", false)):
		return int(p.get("floors", 1))
	return 1 if String(p.get("type", "")) == "boss_arena" else 0

static func nearest_poi(pos: Vector2) -> String:
	var best_id: String = ""
	var best_d: float = INF
	for id in POIS.keys():
		var d: float = pos.distance_squared_to(poi_position(id))
		if d < best_d:
			best_d = d
			best_id = id
	return best_id


# ── Sektor-Logik ──────────────────────────────────────────────────────────────

static func sector_of_y(y: float) -> int:
	if y < BORDER_S1_S2_Y:
		return 1
	if y < BORDER_S2_S3_Y:
		return 2
	return 3

static func sector_of_pos(pos: Vector2) -> int:
	return sector_of_y(pos.y)


# ── Gate 1: Iron-Rail-Sprengtore (Y = 800), Kapitel-4-Reveal ──────────────────

## Ist der Panzerzug durch die Sprengtore gebrochen? (Kapitel 4 abgeschlossen.)
static func is_blast_gate_open() -> bool:
	return GameState.current_chapter >= BLAST_GATE_CHAPTER

## Darf der Spieler die Nordgrenze von Sektor 1 (Y = 800) überschreiten?
## Prüft nur die tatsächliche Nord-Querung; Bewegung innerhalb eines Sektors ist frei.
static func can_cross_blast_line(from_y: float, to_y: float) -> bool:
	var crossing_north: bool = from_y < BORDER_S1_S2_Y and to_y >= BORDER_S1_S2_Y
	if crossing_north:
		return is_blast_gate_open()
	return true


# ── Gate 2: Alchemistische Smog-Linie (Y = 1500), Raffinerie-Stufe 3 ──────────

## Hat das Chassis den Alchemie-Filter (Raffinerie/Labor auf Stufe 3)?
static func has_alchemie_filter() -> bool:
	return GameState.building_level(REFINERY_BUILDING) >= FILTER_REQUIRED_LEVEL

static func is_in_smog(pos: Vector2) -> bool:
	return pos.y >= SMOG_LINE_Y

## Umwelt-DOT der Smog-Zone für diesen Frame. Ohne Filter tödlich (max_hp in 3 s auf 0);
## mit Filter oder außerhalb der Zone 0. Der Player-Controller wendet das Ergebnis an.
static func smog_dot_damage(pos: Vector2, delta_sec: float) -> int:
	if not is_in_smog(pos) or has_alchemie_filter():
		return 0
	return ceili(float(GameState.max_hp()) / SMOG_LETHAL_SECONDS * delta_sec)


# ── Der Strahlensumpf (Gate 0) ────────────────────────────────────────────────
## Ein Riegel VOR den Sprengtoren, und der erste, den der Spieler überhaupt trifft.
##
## Wozu: Sektor 1 misst 800 × 2000 Welteinheiten, das sind zwei Quadratkilometer, die von
## Minute eins offenstehen. Wer dort loslaeuft, hat vier Orte in beliebiger Reihenfolge und
## keinen Grund, irgendwohin zu gehen. Die Sprengtore greifen erst in Kapitel 4 — bis dahin
## gibt es keine einzige Grenze.
##
## Warum ein Sumpf und keine Mauer: Eine Mauer sagt „hier nicht", ein verstrahltes Moor sagt
## „hier noch nicht, und du siehst schon, was dahinter liegt". Man kann hineinlaufen und
## nimmt Schaden — die Grenze ist eine Entscheidung, keine Wand.
##
## ── Ein FLECK, kein Band ─────────────────────────────────────────────────────
## Bis hierher lief der Sumpf als Band ueber die ganze Kartenbreite. Das riegelte den Norden
## zwar sicher ab, hatte aber zwei Fehler: Es sah aus wie ein gezeichneter Strich (2000
## Einheiten Verseuchung, exakt gerade an beiden Raendern), und es nahm dem Auftraggeber die
## Entscheidung, den Spieler woanders anders zu bremsen.
##
## Jetzt ist es ein Rechteck mit Ort und Groesse: **800 m noerdlich von Rustwater, 2,5 km
## breit, 500 m hoch.** Das ist eine Landschaft, an der man vorbeikommt — was links und rechts
## davon den Weg versperrt, entscheidet sich getrennt.
##
## Die Mitte liegt bei y = 620 und nicht bei 700 (= exakt 1 km): Bei 700 laege das **Zugdepot**
## (450/750) mitten in der Todeszone — ein Bahnhof mit Bossarena und Schnellreiseziel, das
## einen direkt in die Strahlung setzt. 800 m statt 1000 m halten es frei, alles andere bleibt
## wie bestellt.
const SWAMP_CENTER_X: int = 500     # Mitte der Zone (Welteinheiten)
const SWAMP_CENTER_Y: int = 620     # = 800 m noerdlich von Rustwater (y = 300)
const SWAMP_HALF_W: int = 500       # 2 × 500 × 2,5 m = 2,5 km breit
const SWAMP_HALF_H: int = 100       # 2 × 100 × 2,5 m = 500 m hoch
## Breite der weichen Randzone in Welteinheiten (34 = 85 m). Innerhalb davon steigt die
## Strahlung von 0 auf voll; der Rest ist Hochplateau.
const SWAMP_EDGE_UNITS: float = 34.0
## Sekunden bis zum Tod ohne Schutz, mitten in der Zone. Kuerzer als beim Smog (3 s): Der Sumpf
## kommt frueh, und ein frueher Riegel muss unmissverstaendlich sein.
const SWAMP_LETHAL_SECONDS: float = 6.0
## Der Schutzanzug haengt an derselben Werkstatt wie der Smog-Filter, nur eine Stufe frueher.
## Zwei Gates am gleichen Gebaeude geben dem Ausbau eine sichtbare Reihenfolge.
const SWAMP_SUIT_LEVEL: int = 1


static func has_rad_suit() -> bool:
	return GameState.building_level(REFINERY_BUILDING) >= SWAMP_SUIT_LEVEL


## Die Zone als Rechteck in Welteinheiten — eine Quelle fuer Karte, Gelaende und Schaden.
static func swamp_rect() -> Rect2:
	return Rect2(float(SWAMP_CENTER_X - SWAMP_HALF_W), float(SWAMP_CENTER_Y - SWAMP_HALF_H),
		float(SWAMP_HALF_W * 2), float(SWAMP_HALF_H * 2))


## Wie tief im Sumpf (0 = draussen, 1 = mitten drin)?
##
## Ein weicher Verlauf statt einer Kante: An den Raendern nimmt man wenig Schaden und merkt,
## dass es schlimmer wird. Eine harte Grenze wuerde man ueberrennen und ohne Vorwarnung
## sterben — das ist der Unterschied zwischen einer Warnung und einer Falle.
##
## Der Verlauf haengt am ABSTAND ZUM RAND, nicht am Anteil der Kantenlaenge. Ein Sinus ueber
## die ganze Form waere hier Unsinn: Die Zone ist fuenfmal so breit wie hoch, damit haenge die
## Strahlung davon ab, wie weit oestlich man steht. Eine feste Randzone von 85 m verhaelt sich
## an allen vier Seiten gleich — man merkt an derselben Strecke, dass es schlimmer wird.
static func swamp_depth(pos: Vector2) -> float:
	var dx: float = float(SWAMP_HALF_W) - absf(pos.x - float(SWAMP_CENTER_X))
	var dy: float = float(SWAMP_HALF_H) - absf(pos.y - float(SWAMP_CENTER_Y))
	if dx <= 0.0 or dy <= 0.0:
		return 0.0
	var rand: float = minf(dx, dy) / SWAMP_EDGE_UNITS   # 0 am Rand, ≥1 im Inneren
	return smoothstep(0.0, 1.0, clampf(rand, 0.0, 1.0))


static func is_in_swamp(pos: Vector2) -> bool:
	return swamp_depth(pos) > 0.0


## Strahlenschaden dieses Frames. Mit Anzug 0 — dann ist der Sumpf nur noch Gelaende.
static func swamp_dot_damage(pos: Vector2, delta_sec: float) -> int:
	var tiefe: float = swamp_depth(pos)
	if tiefe <= 0.0 or has_rad_suit():
		return 0
	return ceili(float(GameState.max_hp()) / SWAMP_LETHAL_SECONDS * delta_sec * tiefe)


## Mitte der Zone in Welteinheiten — fuer Karte und Gelaendeaufbau.
static func swamp_center_y() -> float:
	return float(SWAMP_CENTER_Y)


## Liegt diese Gelaendeform im Strahlensumpf? (Die kleinen Loecher tun es, die Grube nicht.)
static func is_swamp_feature(f: Dictionary) -> bool:
	return String(f.get("id", "")).begins_with("sumpfloch_")


## Zwischenziel, um den Sumpf HERUM ({} = direkter Weg ist frei).
##
## Wozu: Der Wegweiser zieht eine gerade Linie vom Spieler zum Ziel. Zwischen Rustwater und dem
## Zugdepot liegt aber die Todeszone — eine gerade Linie fuehrt mitten hindurch, und der Spieler
## folgt ihr, weil das Spiel sie gezeichnet hat. Ein Leitsystem, das einen umbringt, ist
## schlimmer als gar keines.
##
## Der Umweg ist bewusst PRIMITIV: eine Ecke der Zone, aussen herum. Ein echter Wegfinder waere
## hier verschwendet — die Zone ist ein Rechteck, es gibt genau vier Ecken, und die naeher am
## Ziel liegende Seite ist immer die richtige. Mit Schutzanzug faellt der Umweg weg; dann ist
## der Sumpf nur noch Gelaende.
## Zielt immer auf eine ECKE der Zone, diagonal ausserhalb. Zwei Fallen, beide beim ersten
## Anlauf hineingetappt und gemessen:
##
##  1. **Die naehere Seite ist nicht immer eine Seite.** Die Zone reicht von x = 0 bis 1000 auf
##     einer Karte, die bei 0 anfaengt — westlich herum gibt es GAR NICHTS. Der erste Entwurf
##     rechnete nur, welche Seite naeher liegt, und schickte den Spieler nach Westen gegen den
##     Kartenrand. Es zaehlen nur Seiten, die auf der Karte liegen.
##  2. **Ein Zwischenziel auf der Kante zeigt auf sich selbst.** Lag die Ecke exakt am Rand der
##     Zone, war der Weg dorthin formal immer noch „durch die Zone", und beim naechsten Aufruf
##     kam dieselbe Ecke wieder heraus — der Wegweiser stand still, waehrend der Spieler
##     daraufstand. Deshalb `rand` nach aussen, auf BEIDEN Achsen.
##
## Ein Aufruf liefert genau EIN Zwischenziel. Ist danach immer noch etwas im Weg, liefert der
## naechste Aufruf das naechste — die Spur laeuft die Ecken der Reihe nach ab, ohne dass hier
## jemand eine Wegliste verwalten muss.
static func swamp_detour(from: Vector2, to: Vector2) -> Vector2:
	if has_rad_suit():
		return Vector2.INF
	var zone: Rect2 = swamp_rect().grow(SWAMP_EDGE_UNITS * 0.5)
	if not _segment_hits_rect(from, to, zone):
		return Vector2.INF
	var rand: float = 24.0
	var seiten: Array = []
	if zone.position.x - rand >= 12.0:
		seiten.append(zone.position.x - rand)
	if zone.end.x + rand <= float(WORLD_SIZE) - 12.0:
		seiten.append(zone.end.x + rand)
	if seiten.is_empty():
		return Vector2.INF     # kein Weg herum — dann eben geradeaus, und die Warnung greift
	var beste: Vector2 = Vector2.INF
	var beste_laenge: float = INF
	for x in seiten:
		for y in [zone.position.y - rand, zone.end.y + rand]:
			var ecke := Vector2(float(x), float(y))
			if from.distance_squared_to(ecke) < 4.0:
				continue           # da stehen wir schon
			if _segment_hits_rect(from, ecke, zone):
				continue           # diese Ecke liegt hinter der Zone
			var laenge: float = from.distance_to(ecke) + ecke.distance_to(to)
			if laenge < beste_laenge:
				beste_laenge = laenge
				beste = ecke
	return beste


## Schneidet die Strecke das Rechteck? (Liegt ein Ende drin, zaehlt das auch.)
static func _segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b):
		return true
	# Godots `Rect2.intersects_segment` gibt es nicht — also gegen die vier Kanten pruefen.
	var ecken: Array = [r.position, Vector2(r.end.x, r.position.y), r.end,
		Vector2(r.position.x, r.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, ecken[i], ecken[(i + 1) % 4]) != null:
			return true
	return false


# ── Sektor-Zutritt (kombiniert) ───────────────────────────────────────────────

## Grundsätzlicher Zutritt zu einem Sektor (Story-/Ausrüstungs-Gate).
## Sektor 3 ist zwar physisch betretbar, aber ohne Filter durch den Smog-DOT tödlich —
## `can_enter_sector(3)` bildet die *sichere* Zugänglichkeit ab.
static func can_enter_sector(sector: int) -> bool:
	match sector:
		1:
			return true
		2:
			return is_blast_gate_open()
		3:
			return is_blast_gate_open() and has_alchemie_filter()
	return false


# ── Gate 3: Dynamische Fraktions-Feindseligkeit (Sektor 2) ────────────────────

## Ist ein Fraktions-HQ feindlich? Vor der Gildenwahl niemand; danach jedes fremde HQ
## (Geschützturm-Aggro & Verstärkung, §1.7.3). Basiert allein auf `GameState.chosen_guild`.
static func is_base_hostile(base_id: String) -> bool:
	if GameState.chosen_guild == null:
		return false
	var owner: Variant = BASE_GUILD.get(base_id, null)
	if owner == null:
		return false
	return owner != GameState.chosen_guild

## Ist ein Fraktions-HQ friedlich betretbar (Händler/Truhe/Dialog)?
static func is_base_friendly(base_id: String) -> bool:
	if not BASE_GUILD.has(base_id):
		return true
	return not is_base_hostile(base_id)


# ── Biom-Zonierung: Logik (Daten: BIOMES/ENEMY_POOLS/BIOME_ZONE_ORDER oben, §1.6.3) ──

## Welches Biom liegt an dieser Weltposition? Geografisch, deterministisch.
static func biome_at(pos: Vector2) -> String:
	if pos.y >= SMOG_LINE_Y:
		return "smog_oedland"
	for id in BIOME_ZONE_ORDER:
		var b: Dictionary = BIOMES[id]
		var c: Vector2 = Vector2(float(b["cx"]), float(b["cy"]))
		var rad: float = float(b["radius"])
		if pos.distance_squared_to(c) <= rad * rad:
			return id
	return "desert"

static func biome(biome_id: String) -> Dictionary:
	assert(BIOMES.has(biome_id), "WorldManager: unbekanntes Biom '%s'" % biome_id)
	return BIOMES[biome_id]

## Ist die Zone sicher betretbar? Erbt das Gating ihres Sektors (§1.7).
static func is_biome_unlocked(biome_id: String) -> bool:
	return can_enter_sector(int(biome(biome_id).get("sector", 1)))

## Gegner-Pool eines Bioms (post nach dem Reveal). Fällt auf Wüste zurück.
static func enemy_pool(biome_id: String, revealed: bool) -> Array:
	var pools: Dictionary = ENEMY_POOLS.get(biome_id, ENEMY_POOLS["desert"])
	return pools["post"] if revealed else pools["pre"]

## Gewichtete Gegner-Auswahl. `roll` (0..1) macht Tests deterministisch; sonst randf().
static func pick_enemy_type(biome_id: String, revealed: bool, roll: float = -1.0) -> String:
	var pool: Array = enemy_pool(biome_id, revealed)
	var total: int = 0
	for p in pool:
		total += int(p[1])
	var x: float = (roll if roll >= 0.0 else randf()) * float(total)
	for p in pool:
		x -= float(p[1])
		if x <= 0.0:
			return String(p[0])
	return "outlaw"
