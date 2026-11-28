extends RefCounted
## Die Welt des Punkt-und-Klick-Abenteuers — als **Tabelle**, nicht als Szenenbaum.
##
## ## Warum Daten und keine .tscn je Ort
##
## Ein Adventure hat viele Orte und in jedem Ort viele anklickbare Stellen. Legt man jeden Ort
## als eigene Szene an, liegt die Logik in zwanzig Dateien, die man nur im Editor ansehen kann,
## und nichts davon ist headless pruefbar. Hier steht jeder Ort als Eintrag in `ORTE`:
## Hintergrundbild, begehbare Flaeche, Hotspots, Ausgaenge. `AbenteuerView` baut daraus zur
## Laufzeit die Szene. Folge: Die ganze Welt ist mit `godot --headless` messbar — ob jeder
## Ausgang ein Ziel hat, ob jeder Hotspot im begehbaren Bereich erreichbar ist, ob ein Ort
## ueberhaupt zu betreten ist. Genau die Fehler, die man im Editor erst beim Spielen merkt.
##
## ## Koordinaten
##
## Alles in Bildkoordinaten eines 1280x720-Rahmens — dieselbe Groesse wie
## `window/size/viewport_*` in project.godot. Das Hintergrundbild wird auf genau diesen Rahmen
## gezogen, also stimmen Hotspot-Rechtecke und Bild immer ueberein, egal auf welchem Geraet.
##
## ## Aufbau eines Ortes
##
## | Feld | Bedeutung |
## |---|---|
## | `name`       | was in der Kopfzeile steht |
## | `bild`       | Hintergrund; fehlt die Datei, zeichnet `AbenteuerView` den Platzhalter aus `farben` |
## | `farben`     | [Himmel, Ferne, Boden] fuer den Platzhalter — damit jeder Ort auch ohne Grafik eigen aussieht |
## | `gehfeld`    | Liste von Rect2: wo die Figur stehen darf. Mehrere Rechtecke duerfen sich ueberlappen; zusammen sind sie die begehbare Flaeche |
## | `start`      | wo die Figur steht, wenn man den Ort ohne Ausgang betritt (Spielbeginn, Kapitelsprung) |
## | `tiefe`      | [y_oben, y_unten] -> [Groesse_oben, Groesse_unten]: die Figur wird kleiner, je weiter hinten sie steht. Das ist die ganze Pseudo-Perspektive |
## | `punkte`     | die Hotspots, siehe unten |
## | `ausgaenge`  | Hotspots, die den Ort wechseln |
## | `musik`      | optional, Dateiname in assets/audio/ |
##
## ## Aufbau eines Hotspots (`punkte`)
##
## | Feld | Bedeutung |
## |---|---|
## | `name`      | Name unter dem Mauszeiger |
## | `rect`      | Trefferflaeche |
## | `hin`       | wohin die Figur geht, bevor die Aktion ausgeloest wird. Fehlt es, wird vor dem Rechteck gerechnet |
## | `ansehen`   | Text bei „Ansehen“. Jeder Hotspot MUSS das haben — ein Adventure, in dem Ansehen „nichts“ sagt, ist ein Adventure ohne Welt |
## | `reden`     | Kennung eines Gespraechs in `GespraechDaten` |
## | `nehmen`    | Kennung eines Gegenstands; wandert ins Inventar und der Hotspot verschwindet |
## | `benutzen`  | Kennung einer Wirkung; `AbenteuerView` fragt `MissionDaten.wirkung()` |
## | `braucht`   | Gegenstand, den man dafuer in der Hand haben muss (sonst sagt die Figur, was fehlt) |
## | `sicht`     | Welt-Flagge; ohne sie ist der Hotspot nicht da |
## | `weg`       | Welt-Flagge; MIT ihr ist der Hotspot nicht mehr da |
## | `person`    | Kennung der Figur fuer Portrait und Stimme |
## | `sprite`    | freigestelltes Bild, das im Ort gezeichnet wird |
## | `steht`     | Fusspunkt des Sprites — NUR fuer Personen. Mit `steht` wird in der Tiefe skaliert wie der Held, ohne `steht` fuellt das Sprite sein `rect` |
## | `groesse`   | Hoehe einer Person im Verhaeltnis zum Helden (1.0 = gleich gross) |
##
## ## Aufbau eines Ausgangs (`ausgaenge`)
##
## Wie ein Hotspot, zusaetzlich `ziel` (Ortskennung) und `dort` (wo man dort ankommt).
## `sperre` ist ein Text: steht er da und die Bedingung `frei` ist nicht erfuellt, kommt man
## nicht durch und die Figur sagt diesen Satz. So bleibt Gating im Ort und nicht im Code.

## Der Rahmen, in dem alle Koordinaten dieser Datei gelten.
const RAHMEN: Vector2 = Vector2(1280.0, 720.0)

# ── Die Buehne (Bauform Baphomets Fluch) ──────────────────────────────────────
#
# **Korrektur gegenueber der ersten Fassung.** Hier stand: "flache Theaterkulisse, eine
# Rueckwand mit Architektur, davor ein schmaler Streifen Boden, hoechstens 20 % Tiefe". Das
# war falsch, und es war die Sorte Fehler, die man nicht am Code merkt, sondern erst daran,
# dass die Bilder billig aussehen.
#
# Baphomets Fluch ist keine Theaterkulisse. Es hat **echte Architekturperspektive**: Gassen
# fluchten weg, Fassaden stehen schraeg im Raum, Innenraeume haben Ecken und eine Decke, und
# die Figur wird auf dem Weg nach hinten deutlich kleiner. Eine Pariser Strasse dort ist ein
# Raum, in den man hineinsieht -- nicht eine bemalte Wand.
#
# Mit der alten Regel KONNTE ein Hintergrund gar nicht gut aussehen. Wer einem Bildmodell
# "flat stage-like backdrop, shallow depth" vorgibt, bekommt genau das: eine Wand mit
# aufgeklebten Haeusern. Die Regeln lauten jetzt:
#
#  * **Ein Fluchtpunkt.** Jeder Ort hat einen, er steht in `flucht` und liegt auf oder nahe
#    der Augenhoehe der Kamera. An ihm richtet sich die gemalte Architektur aus, und an ihm
#    rechnet sich die Tiefenstaffelung aus.
#
#  * **Die Kamera steht auf Augenhoehe eines Erwachsenen**, hoechstens eine Handbreit
#    darueber. Das bleibt -- es ist der Unterschied zur Iso-Ansicht, und es ist der Grund,
#    warum man den Figuren ins Gesicht sieht.
#
#  * **Die Figur ist gross**: rund 210 px bei Massstab 1.0, knapp ein Drittel der Bildhoehe,
#    vorn an der Rampe. Hinten darf sie auf die Haelfte schrumpfen.
#
#  * **Die Tiefe ist echt.** Bis zu 50 % Groessenunterschied zwischen vorderster und
#    hinterster Standposition. Die alten 20 % waren zu wenig fuer einen Raum, in den man
#    hineinsieht; die noch aelteren 85 % waren die Iso-Kamera. Der Wert je Ort wird an der
#    GEMALTEN Perspektive eingemessen, nicht geschaetzt -- zwei Punkte im fertigen Bild,
#    vorne und hinten, an denen eine Figur stehen koennte.
#
#  * **Die begehbare Flaeche ist ein Vieleck** (`flaeche`), keine Rechtecke mehr. Eine
#    wegfluchtende Gasse ist ein Trapez, ein Zimmer mit Ecke ist ein L. Rechtecke zwingen
#    jeden Ort in dieselbe waagerechte Bank -- und damit wieder in die Theaterkulisse.
#    `gehfeld` (Rechtecke) bleibt als Rueckfall fuer Orte, die noch nicht eingemessen sind.
#
# Eingemessen wird ERST, wenn das gemalte Bild da ist. Eine begehbare Flaeche vorher
# festzulegen heisst, dem Maler vorzuschreiben, wo die Gasse langgeht -- und dann passen
# Bild und Flaeche genau so wenig zusammen wie jetzt.

## Hoehe der Figur in Pixeln bei Massstab 1.0 (vorne an der Rampe).
const FIGUR_HOEHE: float = 210.0

## Wo die Figur frueheste stehen darf, wenn ein Ort nichts anderes sagt. Kein Verbot mehr,
## sondern eine Vorgabe: Ein eingemessener Ort darf seine Flaeche weiter hinaufziehen, wenn
## die gemalte Perspektive es hergibt.
const BUEHNE_HORIZONT: float = 430.0

## Wie klein die Figur hinten und wie gross vorne, wenn ein Ort keine eigene `tiefe` angibt.
const TIEFE_STANDARD: Array = [430.0, 665.0, 0.74, 1.06]

## Wie viel Groessenunterschied ein Ort hoechstens haben darf (0.8 = 80 %).
##
## Dieser Wert ist zweimal gestiegen, und beide Male, weil er geraten war und die Wirklichkeit
## dagegensprach: erst 0.25 (aus der Annahme "flache Theaterkulisse"), dann 0.50. Am ersten
## wirklich gemalten Hintergrund eingemessen -- Saloontuer, Lazarettzelt und Schwelle als
## Massstaebe -- ergibt der Stadtplatz 67 %. Eine Grenze, die das verbietet, verbietet nicht
## die Iso-Ansicht, sondern das Bild.
##
## Die eigentliche Absicherung ist ohnehin eine andere: Die Werte je Ort werden an der
## gemalten Perspektive eingemessen, nicht geschaetzt. Diese Grenze faengt nur noch den Fall
## ab, dass jemand die Kamera wieder nach schraeg oben zieht.
const TIEFE_MAX: float = 0.80

## Die Orte des ersten Aktes. Reihenfolge ist die Reihenfolge der Geschichte, nicht Alphabet —
## wer hier liest, soll den Weg des Spielers sehen.
const ORTE: Dictionary = {

	# ── KAPITEL 1 ─────────────────────────────────────────────────────────────────
	# „Der Mann, der keiner war“. Man wacht auf dem Schrott auf, ohne Namen, ohne
	# Erinnerung. Der Ort hat absichtlich fast nichts: zwei Dinge zum Ansehen, eine
	# Waffe zum Nehmen, ein Weg nach unten. Das erste Raetsel eines Adventures darf
	# nicht schwer sein, es muss die Sprache des Spiels beibringen.
	"kippe": {
		"name": "Die Schrottkippe",
		"bild": "res://assets/orte/kippe.webp",
		"farben": [Color(0.42, 0.33, 0.24), Color(0.30, 0.25, 0.21), Color(0.19, 0.16, 0.14)],
		# Am gemalten Bild eingemessen (1280x720, also 1:1 zum Spielrahmen).
		"flaeche": [
			Vector2(620.0, 715.0), Vector2(1275.0, 715.0), Vector2(1275.0, 565.0),
			Vector2(1050.0, 505.0), Vector2(880.0, 465.0), Vector2(700.0, 455.0),
			Vector2(545.0, 465.0), Vector2(440.0, 505.0), Vector2(520.0, 600.0),
		],
		"sperren": [Rect2(970.0, 555.0, 70.0, 95.0),],
		"tiefe": [455.0, 715.0, 1.17, 2.03],
		"start": Vector2(760.0, 620.0),
		"punkte": {
			"haende": {
				"name": "Die eigenen Hände",
				"rect": Rect2(690.0, 600.0, 140.0, 110.0),
				"hin": Vector2(760.0, 655.0),
				"person": "held",
				"ansehen": "Zwei Hände. Schwielen, Schmutz, eine Narbe über dem rechten Knöchel. Sie gehören zu mir, und das ist alles, was ich über sie weiß.",
				"reden": "held_selbst",
			},
			"kadaver": {
				"name": "Ausgeweideter Automat",
				"rect": Rect2(480.0, 95.0, 300.0, 345.0),
				"hin": Vector2(660.0, 505.0),
				"ansehen": "Ein Automat, dem jemand die Brustplatte aufgeschnitten hat. Innen Zahnräder, ein geplatzter Druckkessel, Öl, das nicht mehr fließt. Irgendwer hat geholt, was zu holen war.",
				"benutzen": "kadaver_pluendern",
			},
			"revolver": {
				"sprite": "res://assets/dinge/revolver.webp",
				"name": "Revolver im Staub",
				"rect": Rect2(700.0, 545.0, 110.0, 60.0),
				"hin": Vector2(760.0, 625.0),
				"ansehen": "Ein Revolver, halb im Staub. Der Griff ist abgegriffen, als hätte ihn lange jemand gehalten. Sechs Kammern, zwei geladen.",
				"nehmen": "revolver",
			},
			"brecheisen": {
				"sprite": "res://assets/dinge/brecheisen.webp",
				"name": "Brecheisen im Schrott",
				"rect": Rect2(555.0, 480.0, 125.0, 55.0),
				"hin": Vector2(620.0, 550.0),
				"ansehen": "Ein Brecheisen zwischen zwei Blechplatten, eine Elle Flachstahl mit Klaue. Der Griff ist mit Lappen umwickelt, damit die Hand im Winter nicht am Metall klebt.",
				"nehmen": "brecheisen",
			},
			"tafel": {
				"name": "Verbogenes Blechschild",
				"rect": Rect2(930.0, 140.0, 215.0, 190.0),
				"hin": Vector2(925.0, 585.0),
				"ansehen": "Ein Schild, von der Sonne ausgebleicht: IRON RAIL CONSOLIDATED — ABWURFZONE 7. KEIN ZUTRITT. Darunter, mit Nagel gekratzt: „zu spät“.",
			},
		},
		"ausgaenge": {
			"abstieg": {
				"name": "Hinunter zur Piste",
				"rect": Rect2(1120.0, 560.0, 160.0, 160.0),
				"hin": Vector2(1200.0, 660.0),
				"ansehen": "Der Schrotthang fällt ab. Unten läuft eine Piste nach Süden, und am Horizont steht Rauch über Dächern.",
				"ziel": "piste",
				"dort": "von_kippe",
			},
		},
	},

	# Die Piste. Erster Ort mit einer Person darauf, und die erste Entscheidung:
	# Man kann Quentins Karre helfen oder vorbeigehen. Beides geht weiter.
	"piste": {
		"name": "Piste nach Rustwater",
		"bild": "res://assets/orte/piste.webp",
		"farben": [Color(0.55, 0.45, 0.31), Color(0.38, 0.32, 0.25), Color(0.24, 0.21, 0.17)],
		# Am gemalten Bild eingemessen (1280x720, also 1:1 zum Spielrahmen).
		"flaeche": [
			Vector2(130.0, 715.0), Vector2(1275.0, 715.0), Vector2(1275.0, 610.0),
			Vector2(1080.0, 530.0), Vector2(900.0, 445.0), Vector2(862.0, 402.0),
			Vector2(706.0, 402.0), Vector2(620.0, 455.0), Vector2(470.0, 520.0),
			Vector2(250.0, 600.0),
		],
		"tiefe": [402.0, 715.0, 0.86, 1.49],
		"start": Vector2(640.0, 620.0),
		"punkte": {
			"karre": {
				"name": "Liegengebliebene Karre",
				"rect": Rect2(0.0, 150.0, 500.0, 420.0),
				"hin": Vector2(420.0, 605.0),
				"ansehen": "Ein Dampfkarren mit gebrochener Achse. Der Kessel zischt noch, also steht er nicht lange hier.",
				"benutzen": "karre_flicken",
				"braucht": "schraubstock",
			},
			"quentin": {
				"sprite": "res://assets/figuren/quentin.webp",
				"steht": Vector2(485.0, 558.0),
				"groesse": 1.00,
				"name": "Quentin Vale",
				"rect": Rect2(430.0, 330.0, 110.0, 230.0),
				"hin": Vector2(520.0, 580.0),
				"person": "quentin",
				"ansehen": "Ein hagerer Mann im zu guten Mantel, der eine gebrochene Achse ansieht wie einen persönlichen Affront.",
				"reden": "quentin_piste",
			},
			"kaktus": {
				"name": "Stachelbusch",
				"rect": Rect2(1060.0, 380.0, 220.0, 180.0),
				"hin": Vector2(1030.0, 620.0),
				"ansehen": "Ein Busch, der mehr Dorn als Pflanze ist. In seinem Schatten liegt etwas Metallisches.",
				"benutzen": "kaktus_durchsuchen",
			},
			"felsen": {
				"name": "Felsen über der Piste",
				"rect": Rect2(900.0, 60.0, 380.0, 340.0),
				"hin": Vector2(960.0, 525.0),
				"ansehen": "Ein Felsriegel über der Piste, von dem man alles sieht, was unten durchkommt. Zwischen den Steinen bewegt sich etwas, und es bewegt sich in Deckung.",
				"benutzen": "felsen_leuchten",
				"braucht": "signallampe",
			},
			"knochen": {
				"name": "Knochen am Pistenrand",
				"rect": Rect2(860.0, 590.0, 250.0, 120.0),
				"hin": Vector2(850.0, 665.0),
				"ansehen": "Ein Brustkorb, sauber abgenagt. Daneben ein Stiefel, in dem noch ein Fuß steckt. Die Wüste räumt nicht auf, sie sortiert nur.",
			},
		},
		"ausgaenge": {
			"zurueck": {
				"name": "Zurück zur Kippe",
				"rect": Rect2(0.0, 600.0, 180.0, 120.0),
				"hin": Vector2(190.0, 680.0),
				"ansehen": "Der Hang hinauf, aus dem ich gekrochen bin. Da ist nichts mehr.",
				"ziel": "kippe",
				"dort": "von_piste",
			},
			"tor": {
				"name": "Stadttor von Rustwater",
				"rect": Rect2(655.0, 225.0, 250.0, 180.0),
				"hin": Vector2(785.0, 430.0),
				"ansehen": "Ein Palisadentor aus Schwellen und Blech. Darüber ein Schädel mit Zylinder — der Humor der Grenze.",
				"ziel": "platz",
				"dort": "von_piste",
			},
		},
	},

	# Der Stadtplatz. Nabe des Spiels: von hier gehen Saloon, Schmiede, Lazarett ab.
	# Jede Nabe braucht mehr Ansehen-Text als alles andere, weil der Spieler hier am
	# oeftesten steht.
	"platz": {
		"name": "Rustwater — Platz",
		"bild": "res://assets/orte/platz.webp",
		"farben": [Color(0.50, 0.42, 0.32), Color(0.33, 0.29, 0.26), Color(0.21, 0.19, 0.17)],

		# ── Am gemalten Bild eingemessen, nicht geschaetzt ────────────────────────
		#
		# Alles unterhalb kommt aus `assets/orte/platz.webp` (1672x941, exakt 16:9), auf den
		# Rahmen 1280x720 umgerechnet. Vorher standen hier Zahlen aus der Luft, und sie lagen
		# samt und sonders daneben: Der Saloon steht links und nicht hinten in der Mitte, das
		# Auftragsbrett ganz rechts am Bildrand, die Schmiede in der Mitte, das Lazarettzelt
		# rechts davor. Ein Ort laesst sich nicht einmessen, bevor es ihn gibt.
		#
		# Die begehbare Flaeche spart unten links den angeschnittenen Vordergrund aus
		# (Anbindepfosten mit Seil). Der Grund ist technisch: Die Figur wird UEBER den
		# Hintergrund gezeichnet, also liefe sie dort vor dem Pfosten statt dahinter. Richtig
		# geloest waere das mit einer Vordergrundebene (`bild_vorn`), die nach der Figur
		# gezeichnet wird -- die Fassung dafuer steht, es fehlt nur der Freisteller.
		# Zweiter Durchgang, nach dem Overlay (tools/EinmessProbe.gd). Der erste liess die
		# Figur links zu weit nach hinten laufen -- sie haette auf der Saloon-Veranda
		# gestanden statt davor -- und unten links in den angeschnittenen Anbindepfosten
		# hinein. Beides war am Zahlenwert nicht zu sehen, nur am Bild.
		"flaeche": [
			Vector2(520.0, 713.0), Vector2(1267.0, 713.0), Vector2(1267.0, 533.0),
			Vector2(1152.0, 443.0), Vector2(896.0, 432.0), Vector2(563.0, 448.0),
			Vector2(420.0, 500.0), Vector2(250.0, 528.0), Vector2(185.0, 560.0),
			Vector2(185.0, 620.0), Vector2(330.0, 676.0),
		],
		# Brunnen, Kinetoskop-Saeule und die Pfosten des Auftragsbretts stehen mitten darin.
		"sperren": [
			Rect2(563.0, 421.0, 243.0, 97.0),
			Rect2(141.0, 446.0, 121.0, 87.0),
			Rect2(1171.0, 414.0, 103.0, 90.0),
		],
		"flucht": Vector2(950.0, 330.0),   # an den Fluchtlinien von Veranda und Balkon abgelesen
		# Eingemessen an drei Massstaeben im Bild: Saloon-Schwingtuer, Lazarettzelt und die
		# Hoehe der Veranda-Schwelle. Vorn ist eine Figur 210 px hoch, hinten an der
		# Brunnenlinie noch rund 126 -- also 60 %. Das sind 67 % Spanne, und sie stehen so im
		# Bild. Siehe `TIEFE_MAX`.
		"tiefe": [450.0, 713.0, 1.17, 1.96],
		"start": Vector2(640.0, 600.0),
		"punkte": {
			"brunnen": {
				"name": "Trockener Brunnen",
				"rect": Rect2(550.0, 300.0, 256.0, 215.0),
				"hin": Vector2(680.0, 560.0),
				"ansehen": "Ein Brunnen aus geschichtetem Stein, Galgen und Eimer darüber. Der Eimer ist trocken bis ins Holz. Am Balken hängt ein Schild: „WASSER WIRD ZUGETEILT. IRON RAIL CONSOLIDATED“.",
				"benutzen": "brunnen_steigen",
			},
			"rohr": {
				"name": "Gitterrost im Brunnenschacht",
				"rect": Rect2(640.0, 395.0, 110.0, 60.0),
				"hin": Vector2(680.0, 560.0),
				"ansehen": "Zwei Meter tief sitzt ein Gitterrost vor dem waagerechten Rohr. Dahinter bewegt sich etwas, und es sind zu viele, um sie zu zählen.",
				"benutzen": "rohr_zusetzen",
				"braucht": "brecheisen",
				"sicht": "brunnen_gesehen",
			},
			"kinetoskop": {
				"name": "Kinetoskop-Säule",
				"rect": Rect2(141.0, 240.0, 121.0, 290.0),
				"hin": Vector2(300.0, 580.0),
				"ansehen": "Eine gusseiserne Säule mit Guckloch, Kurbel und dem Zahnrad-Wappen des Konzerns im Fuß. Er wirft hier seine Bilder: lachende Arbeiter, saubere Werkhallen. Niemand sieht hin.",
				"benutzen": "kinetoskop_kurbeln",
			},
			"linse": {
				"name": "Linse der Kinetoskop-Säule",
				"rect": Rect2(152.0, 262.0, 70.0, 58.0),
				"hin": Vector2(300.0, 580.0),
				"ansehen": "Hinter dem Guckloch sitzt eine geschliffene Linse in einer Messingfassung. Sie bündelt den Schein der Projektionslampe zu einem Strahl.",
				"benutzen": "linse_brechen",
				"braucht": "brecheisen",
				"sicht": "kinetoskop_gesehen",
			},
			"aushang": {
				"name": "Auftragsbrett",
				"rect": Rect2(1139.0, 170.0, 141.0, 250.0),
				"hin": Vector2(1110.0, 580.0),
				"ansehen": "Ein überdachtes Brett voller Zettel, in Lagen übereinander genagelt. Kopfgelder, Suchanzeigen, zwei Todesanzeigen, die noch keiner abgenommen hat.",
				"benutzen": "brett_lesen",
			},
			"dolores": {
				"sprite": "res://assets/figuren/dolores.webp",
				"steht": Vector2(487.0, 548.0),
				"groesse": 0.85,
				"name": "Dolores am Brunnenrand",
				"rect": Rect2(440.0, 400.0, 95.0, 150.0),
				"hin": Vector2(480.0, 560.0),
				"person": "dolores",
				"ansehen": "Eine alte Frau mit einer Drehorgel, die seit Jahren dieselben drei Walzen spielt. Sie sieht einen an, als kenne sie einen.",
				"reden": "dolores_platz",
				"benutzen": "walze_dolores",
			},
		},
		"ausgaenge": {
			"saloon": {
				"name": "Gatling-Saloon",
				"rect": Rect2(326.0, 300.0, 88.0, 120.0),
				"hin": Vector2(380.0, 530.0),
				"ansehen": "Ein zweistöckiger Kasten aus Bruchstein und Holz, Balkon über der Veranda, Schwingtür darunter. Über dem Eingang hängt ein Gatling-Lauf als Wirtshausschild.",
				"ziel": "saloon",
				"dort": "von_platz",
			},
			"schmiede": {
				"name": "Schmiede",
				"rect": Rect2(704.0, 236.0, 270.0, 190.0),
				"hin": Vector2(880.0, 520.0),
				"ansehen": "Ein offener Schuppen unter Steinschornstein, Esse am Glühen, Amboss davor. Der Hammerschlag kommt in einem Takt, der sich seit dreißig Jahren nicht geändert hat.",
				"ziel": "schmiede",
				"dort": "von_platz",
			},
			"lazarett": {
				"name": "Feldlazarett",
				"rect": Rect2(986.0, 236.0, 166.0, 182.0),
				"hin": Vector2(1050.0, 520.0),
				"ansehen": "Ein Zelt aus schwerem Segeltuch auf einem Steinfundament, Stufen davor, ein rotes Kreuz an der Plane. Die Plane ist an zwei Stellen geflickt und an einer nicht.",
				"ziel": "lazarett",
				"dort": "von_platz",
			},
			"schacht": {
				"name": "Weg zum Vorschacht",
				"rect": Rect2(890.0, 98.0, 225.0, 120.0),
				"hin": Vector2(980.0, 490.0),
				"ansehen": "Oben an der Kraterwand steht der Förderturm, und eine Serpentine führt hinauf. Früher gingen dort morgens vierzig Mann hoch. Heute geht die Straße leer.",
				"ziel": "vorschacht",
				"dort": "von_platz",
			},
			"raus": {
				"name": "Piste aus der Stadt",
				"rect": Rect2(330.0, 640.0, 280.0, 80.0),
				"hin": Vector2(590.0, 698.0),
				"ansehen": "Am Anbindepfosten vorbei führt die Piste aus der Stadt nach Süden. Die Wüste wartet, sie hat Zeit.",
				"ziel": "piste",
				"dort": "von_platz",
			},
		},
	},

	# Der Saloon. Mabel ist die erste Person, die mit einem redet, ohne zu fragen,
	# was man ist. Der ganze Reveal in Kapitel 4 haengt daran, dass dieser Ort warm ist.
	"saloon": {
		"name": "Gatling-Saloon",
		"bild": "res://assets/orte/saloon.webp",
		"farben": [Color(0.26, 0.17, 0.11), Color(0.34, 0.22, 0.13), Color(0.18, 0.13, 0.10)],
		# Am gemalten Bild eingemessen (1280x720, also 1:1 zum Spielrahmen).
		"flaeche": [
			Vector2(430.0, 715.0), Vector2(1180.0, 715.0), Vector2(1180.0, 560.0),
			Vector2(1120.0, 520.0), Vector2(960.0, 500.0), Vector2(780.0, 525.0),
			Vector2(640.0, 580.0), Vector2(520.0, 650.0),
		],
		"sperren": [Rect2(885.0, 515.0, 165.0, 205.0), Rect2(1040.0, 580.0, 240.0, 140.0), Rect2(450.0, 525.0, 115.0, 125.0), Rect2(855.0, 425.0, 205.0, 135.0),],
		"tiefe": [505.0, 700.0, 1.18, 1.97],
		# Im Saloon widersprechen sich die Massstaebe: Die Klaviatur rechnet auf 463 px,
		# die Faesser an der Theke auf 350, der Stuhl im Vordergrund auf 369. Erst war die
		# Klaviatur massgeblich, und die Figur wurde zu gross -- das Klavier steht weiter
		# hinten, als es aussieht. Jetzt gilt die Theke, an der die Figur tatsaechlich
		# steht: 371 px.
		"start": Vector2(700.0, 650.0),
		"punkte": {
			"mabel": {
				"sprite": "res://assets/figuren/mabel.webp",
				"steht": Vector2(250.0, 655.0),
				"groesse": 0.95,
				"name": "Mamma „Rusty“ Mabel",
				"rect": Rect2(150.0, 330.0, 200.0, 300.0),
				"hin": Vector2(540.0, 672.0),
				"person": "mabel",
				"ansehen": "Eine Frau um die fünfzig hinter der Theke, Unterarme wie Ankerketten. Sie wischt ein Glas, das schon trocken ist, weil ihre Hände etwas tun müssen, während sie einen abschätzt.",
				"reden": "mabel_saloon",
			},
			"theke": {
				"name": "Theke",
				"rect": Rect2(0.0, 410.0, 430.0, 290.0),
				"hin": Vector2(520.0, 682.0),
				"ansehen": "Ein Brett auf zwei Fässern, blank gewischt von dreißig Jahren Ellbogen. In das Holz sind Namen geschnitten, die meisten durchgestrichen.",
				"benutzen": "theke_trinken",
			},
			"klavier": {
				"name": "Mechanisches Klavier",
				"rect": Rect2(350.0, 285.0, 290.0, 370.0),
				"hin": Vector2(600.0, 662.0),
				"ansehen": "Ein Klavier, das sich selbst spielt — eine Walze dreht, Hämmer folgen. Drei Töne fehlen, und niemand hier hört das noch.",
				"benutzen": "klavier_walze",
			},
			"gideon": {
				"sprite": "res://assets/figuren/gideon.webp",
				"steht": Vector2(930.0, 575.0),
				"groesse": 1.05,
				"name": "Gideon Cross",
				"rect": Rect2(855.0, 400.0, 210.0, 160.0),
				"hin": Vector2(840.0, 640.0),
				"person": "gideon",
				"ansehen": "Ein breiter Mann an einem Tisch, mit dem Rücken zur Wand und freiem Blick zur Tür. Vor ihm ein Glas, das er nicht anfasst.",
				"reden": "gideon_saloon",
			},
			"brett": {
				"name": "Kopfgeldbrett",
				"rect": Rect2(970.0, 305.0, 75.0, 90.0),
				"hin": Vector2(860.0, 600.0),
				"ansehen": "Das Brett, auf dem der Saloon seine Rechnungen auslegt: wer wen tot sehen will, und wofür.",
				"benutzen": "kopfgeld_lesen",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Hinaus auf den Platz",
				"rect": Rect2(1105.0, 245.0, 175.0, 300.0),
				"hin": Vector2(1140.0, 565.0),
				"ansehen": "Die Schwingtür. Dahinter der Platz und zu viel Sonne.",
				"ziel": "platz",
				"dort": "von_saloon",
			},
		},
	},

	# Die Schmiede. Silas ist der einzige, der die Wahrheit ueber den Helden von Anfang
	# an sieht — er sagt sie nur nicht. Deshalb hat sein Ort das „Kupferauge“ als Hotspot:
	# Wer genau hinsieht, kann es ahnen, bevor Kapitel 4 es sagt.
	"schmiede": {
		"name": "Silas' Schmiede",
		"bild": "res://assets/orte/schmiede.webp",
		"farben": [Color(0.22, 0.14, 0.10), Color(0.42, 0.21, 0.09), Color(0.16, 0.12, 0.10)],
		# Am gemalten Bild eingemessen (1280x720, also 1:1 zum Spielrahmen).
		"flaeche": [
			Vector2(150.0, 715.0), Vector2(855.0, 715.0), Vector2(855.0, 640.0),
			Vector2(790.0, 598.0), Vector2(640.0, 578.0), Vector2(470.0, 585.0),
			Vector2(300.0, 605.0), Vector2(175.0, 650.0),
		],
		"sperren": [Rect2(300.0, 565.0, 235.0, 155.0),],
		"tiefe": [578.0, 715.0, 2.03, 2.59],
		"start": Vector2(640.0, 665.0),
		"punkte": {
			"silas": {
				"sprite": "res://assets/figuren/silas.webp",
				"steht": Vector2(625.0, 660.0),
				"groesse": 0.95,
				"name": "Silas „Kupferauge“ Finch",
				"rect": Rect2(545.0, 390.0, 160.0, 290.0),
				"hin": Vector2(660.0, 658.0),
				"person": "silas",
				"ansehen": "Ein alter Schmied, Lederschurz, Hände wie Werkzeug. Das linke Auge ist aus Kupfer und Glas und sitzt nicht ganz gerade in der Höhle.",
				"reden": "silas_schmiede",
				"benutzen": "walze_silas",
			},
			"esse": {
				"name": "Esse",
				"rect": Rect2(340.0, 250.0, 320.0, 330.0),
				"hin": Vector2(640.0, 645.0),
				"ansehen": "Kohlenglut unter einem Blasebalg. Die Hitze steht wie eine Wand davor.",
				"benutzen": "esse_benutzen",
			},
			"werkbank": {
				"name": "Werkbank",
				"rect": Rect2(845.0, 335.0, 435.0, 330.0),
				"hin": Vector2(800.0, 662.0),
				"ansehen": "Zangen, Feilen, ein halb fertiger Revolvertrommel-Rohling. Dazwischen ein schwerer Schraubstock, der nicht angeschraubt ist.",
				"nehmen": "schraubstock",
			},
			"plaene": {
				"name": "Angenagelte Risszeichnung",
				"rect": Rect2(980.0, 105.0, 225.0, 230.0),
				"hin": Vector2(800.0, 672.0),
				"ansehen": "Eine Zeichnung an der Wand: ein Gelenk im Schnitt, Zahnrad in Knochenform. Die Beschriftung ist in Konzernschrift, der Stempel durchgestrichen. Jemand hat daneben gekritzelt: „Naht am Schlüsselbein“.",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Hinaus auf den Platz",
				"rect": Rect2(0.0, 170.0, 270.0, 400.0),
				"hin": Vector2(205.0, 682.0),
				"ansehen": "Zurück in die Sonne.",
				"ziel": "platz",
				"dort": "von_schmiede",
			},
		},
	},

	# Das Lazarett. Doc Aris weiss, was der Held ist — er hat ihn geflickt. Sein Ort ist
	# der einzige, in dem Gegenstaende liegen, die den Reveal vorbereiten.
	"lazarett": {
		"name": "Feldlazarett von Doc Aris",
		"bild": "res://assets/orte/lazarett.webp",
		"farben": [Color(0.20, 0.21, 0.19), Color(0.28, 0.28, 0.25), Color(0.15, 0.16, 0.15)],
		# Am gemalten Bild eingemessen (1280x720, also 1:1 zum Spielrahmen).
		"flaeche": [
			Vector2(330.0, 715.0), Vector2(1000.0, 715.0), Vector2(1000.0, 640.0),
			Vector2(900.0, 620.0), Vector2(700.0, 640.0), Vector2(480.0, 660.0),
			Vector2(360.0, 680.0),
		],
		"sperren": [Rect2(745.0, 600.0, 110.0, 75.0),],
		"tiefe": [620.0, 715.0, 2.38, 2.82],
		"start": Vector2(620.0, 692.0),
		"punkte": {
			"doc": {
				"sprite": "res://assets/figuren/doc.webp",
				"steht": Vector2(920.0, 665.0),
				"groesse": 1.00,
				"name": "Doc Aris",
				"rect": Rect2(860.0, 330.0, 150.0, 300.0),
				"hin": Vector2(905.0, 678.0),
				"person": "doc",
				"ansehen": "Ein hagerer Mann mit Schürze, auf der zwei Arten Blut trocknen. Er wäscht sich die Hände länger, als nötig wäre.",
				"reden": "doc_lazarett",
			},
			"bahre": {
				"name": "Bahre",
				"rect": Rect2(200.0, 350.0, 640.0, 350.0),
				"hin": Vector2(620.0, 692.0),
				"ansehen": "Eine Bahre mit Lederriemen an Hand- und Fußende. Die Riemen sind von innen durchgewetzt. Was hier lag, hat sich gewehrt.",
				"benutzen": "bahre_ansehen",
			},
			"schrank": {
				"name": "Instrumentenschrank",
				"rect": Rect2(845.0, 65.0, 400.0, 610.0),
				"hin": Vector2(960.0, 682.0),
				"ansehen": "Zangen, Sägen, Klemmen — und in der untersten Reihe Werkzeug, das nicht in Fleisch gehört: Gewindeschneider, Fühlerlehre, ein Schlüssel für Sechskant.",
				"benutzen": "schrank_oeffnen",
			},
			"akte": {
				"sprite": "res://assets/dinge/akte.webp",
				"name": "Aufgeschlagene Akte",
				"rect": Rect2(1010.0, 560.0, 180.0, 90.0),
				"hin": Vector2(985.0, 692.0),
				"ansehen": "Eine Krankenakte ohne Namen, nur eine Nummer: PROJEKT MANTEL — EINHEIT 7. Darunter eine Liste von Eingriffen, die bis vor drei Wochen reicht. Die letzte Zeile: „Erinnerungswalze getauscht. Reaktion unauffällig.“",
				"nehmen": "akte_mantel",
				"sicht": "akte_sichtbar",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Hinaus auf den Platz",
				"rect": Rect2(170.0, 195.0, 165.0, 285.0),
				"hin": Vector2(395.0, 695.0),
				"ansehen": "Zurück in die Sonne, und die ist nach diesem Zelt ein Geschenk.",
				"ziel": "platz",
				"dort": "von_lazarett",
			},
		},
	},

	# ── KAPITEL 2 ─────────────────────────────────────────────────────────────────
	# Der Vorschacht. Hier steht das erste richtige Kombinations-Raetsel des Spiels, und es
	# ist absichtlich ueber zwei Kapitel gespannt: Die Grubenlampe liegt im Automatenkadaver
	# auf der SCHROTTKIPPE, also an dem Ort, an dem man das Spiel beginnt und zu dem man
	# normalerweise nie zurueckkehrt. Wer sie dort mitgenommen hat, kommt hier weiter. Wer
	# nicht, muss den ganzen Weg zurueck -- und genau das ist die Sorte Umweg, die ein
	# Adventure ausmacht, solange der Weg kurz und der Hinweis eindeutig ist. Beides ist
	# hier der Fall: Der dunkle Gang sagt beim Ansehen, was fehlt.
	"vorschacht": {
		"name": "Der Vorschacht",
		"bild": "res://assets/orte/vorschacht.webp",
		"farben": [Color(0.17, 0.14, 0.12), Color(0.24, 0.19, 0.15), Color(0.13, 0.11, 0.10)],
		# Am gemalten Bild eingemessen (1280x720, also 1:1 zum Spielrahmen).
		"flaeche": [
			Vector2(240.0, 715.0), Vector2(1040.0, 715.0), Vector2(1040.0, 640.0),
			Vector2(980.0, 600.0), Vector2(860.0, 585.0), Vector2(700.0, 590.0),
			Vector2(560.0, 605.0), Vector2(420.0, 625.0), Vector2(280.0, 660.0),
		],
		"sperren": [Rect2(345.0, 540.0, 180.0, 90.0), Rect2(720.0, 530.0, 165.0, 70.0),],
		"tiefe": [585.0, 715.0, 1.86, 2.38],
		"start": Vector2(640.0, 672.0),
		"punkte": {
			"stollen_dunkel": {
				"name": "Der dunkle Gang",
				"rect": Rect2(880.0, 200.0, 220.0, 340.0),
				"hin": Vector2(960.0, 662.0),
				"ansehen": "Nach zehn Schritten hört der Gang auf, hell zu sein. Was danach kommt, weiß ich nicht, und ohne Licht werde ich es nicht herausfinden. Von unten kommt ein Ton, der nicht aufhört.",
				"benutzen": "gang_hinab",
				"braucht": "oellampe",
			},
			"foerderkorb": {
				"name": "Förderkorb",
				"rect": Rect2(340.0, 250.0, 185.0, 365.0),
				"hin": Vector2(420.0, 682.0),
				"ansehen": "Ein Eisenkorb an einer Trommel, hochgezogen und verkeilt. Jemand hat den Keil von oben gesetzt — damit niemand hochkommt, nicht damit niemand runterfährt.",
				"benutzen": "korb_pruefen",
			},
			"schild": {
				"name": "Angenagelte Tafel",
				"rect": Rect2(250.0, 300.0, 110.0, 150.0),
				"hin": Vector2(330.0, 692.0),
				"ansehen": "Mit Kreide auf Blech: EBENE 3 GESPERRT. Darunter, von anderer Hand und tiefer eingeritzt: „es singt noch“. Die Kreide ist verwischt, die Ritzung nicht.",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Zurück nach Rustwater",
				"rect": Rect2(130.0, 600.0, 180.0, 120.0),
				"hin": Vector2(305.0, 692.0),
				"ansehen": "Der Pfad zurück in die Stadt. Von hier sieht Rustwater kleiner aus, als es sich anfühlt.",
				"ziel": "platz",
				"dort": "von_schacht",
			},
		},
	},
}


## Ein Ort oder ein leeres Dictionary. Nie `null` — ein Aufrufer, der auf `null` prueft, hat
## den Fehler schon gemacht; einer, der ein leeres Dictionary bekommt, kann weiterrechnen.
static func ort(kennung: String) -> Dictionary:
	return ORTE.get(kennung, {}) as Dictionary


## Alle Ortskennungen in Tabellen-Reihenfolge.
static func alle() -> Array:
	return ORTE.keys()


## Hotspots UND Ausgaenge eines Ortes in einem Durchgang.
##
## Der Aufrufer unterscheidet sie am Feld `ziel`; fuer alles andere — Treffer suchen, Namen
## anzeigen, Ansehen-Text holen — sind sie dasselbe, und zwei getrennte Schleifen waeren zwei
## Stellen, an denen man eine Regel vergessen kann.
static func punkte_alle(kennung: String) -> Dictionary:
	var o: Dictionary = ort(kennung)
	var raus: Dictionary = {}
	for k in o.get("punkte", {}):
		raus[k] = (o["punkte"] as Dictionary)[k]
	for k in o.get("ausgaenge", {}):
		raus[k] = (o["ausgaenge"] as Dictionary)[k]
	return raus


## Die begehbare Flaeche als Liste von Rechtecken (Rueckfall fuer nicht eingemessene Orte).
static func gehfeld(kennung: String) -> Array:
	return ort(kennung).get("gehfeld", []) as Array


## Die begehbare Flaeche als Vieleck, oder leer.
##
## Das ist die Form, die ein eingemessener Ort benutzt: eine wegfluchtende Gasse ist ein
## Trapez, ein Zimmer mit Ecke ein L. Rechtecke koennen beides nicht und zwingen jeden Ort in
## dieselbe waagerechte Bank.
static func flaeche(kennung: String) -> PackedVector2Array:
	var f: Variant = ort(kennung).get("flaeche", null)
	if f is PackedVector2Array:
		return f as PackedVector2Array
	if f is Array:
		var raus: PackedVector2Array = PackedVector2Array()
		for p in f as Array:
			raus.append(p as Vector2)
		return raus
	return PackedVector2Array()


## Flaechen innerhalb des Gehfeldes, die trotzdem nicht betretbar sind.
##
## Ein gemalter Ort hat Dinge darin: einen Brunnen, eine Saeule, eine Treppe. Die stehen
## mitten auf dem Platz, und ohne sie waere die begehbare Flaeche entweder ein Vieleck mit
## Loechern -- unlesbar und von Hand nicht zu pflegen -- oder die Figur liefe durch den
## Brunnen hindurch. Rechtecke reichen dafuer: Eine Sperre muss nicht der Silhouette folgen,
## sie muss nur verhindern, dass die Figur im Stein steht.
static func sperren(kennung: String) -> Array:
	return ort(kennung).get("sperren", []) as Array


## Der Fluchtpunkt des Ortes -- woran sich die gemalte Architektur ausrichtet.
##
## Liegt auf oder nahe der Augenhoehe der Kamera. Wird beim Einmessen des fertigen Bildes
## eingetragen und dient als Angabe fuer den Maler, nicht als Rechengroesse: Die
## Tiefenstaffelung kommt aus `tiefe`, weil die an zwei echten Standpunkten eingemessen wird
## und damit auch dann stimmt, wenn das Bild nicht perfekt konstruiert ist.
static func fluchtpunkt(kennung: String) -> Vector2:
	return ort(kennung).get("flucht", Vector2(RAHMEN.x * 0.5, 360.0)) as Vector2


## Darf die Figur hier stehen?
##
## Vieleck schlaegt Rechtecke. Ein Ort, der beides hat, ist eingemessen -- dann gilt das
## Vieleck, und die Rechtecke sind nur noch Altlast.
static func begehbar(kennung: String, wo: Vector2) -> bool:
	for sp in sperren(kennung):
		if (sp as Rect2).has_point(wo):
			return false
	var poly: PackedVector2Array = flaeche(kennung)
	if poly.size() >= 3:
		return Geometry2D.is_point_in_polygon(wo, poly)
	for r in gehfeld(kennung):
		if (r as Rect2).has_point(wo):
			return true
	return false


## Der naechste begehbare Punkt zu `wo`.
##
## Ein Klick neben die Flaeche ist nicht nichts — der Spieler meint den Rand. Wer solche Klicks
## verwirft, baut ein Spiel, in dem die Figur scheinbar zufaellig nicht reagiert.
static func naechster_punkt(kennung: String, wo: Vector2) -> Vector2:
	if begehbar(kennung, wo):
		return wo

	# Steht der Punkt IN einer Sperre, wird er an deren naechste Kante geschoben -- und ein
	# Stueck darueber hinaus, weil `Rect2.has_point` die Kante selbst noch als drinnen zaehlt
	# und die Figur sonst am Brunnenrand klebt.
	for sp in sperren(kennung):
		var r2: Rect2 = sp as Rect2
		if not r2.has_point(wo):
			continue
		var kanten: Array = [
			Vector2(r2.position.x - 1.0, wo.y), Vector2(r2.end.x + 1.0, wo.y),
			Vector2(wo.x, r2.position.y - 1.0), Vector2(wo.x, r2.end.y + 1.0)]
		var nah: Vector2 = wo
		var nah_d: float = INF
		for k in kanten:
			var d2: float = (k as Vector2).distance_to(wo)
			if d2 < nah_d and begehbar(kennung, k as Vector2):
				nah_d = d2
				nah = k as Vector2
		if nah_d < INF:
			return nah

	var beste: Vector2 = wo
	var abstand: float = INF
	var poly: PackedVector2Array = flaeche(kennung)
	if poly.size() >= 3:
		# Auf die naechste Kante projizieren. Ohne das rutscht die Figur beim Klick neben die
		# Gasse auf deren Mitte statt an den Rand, und das sieht aus wie ein Sprung.
		for i in range(poly.size()):
			var a: Vector2 = poly[i]
			var b: Vector2 = poly[(i + 1) % poly.size()]
			var p: Vector2 = Geometry2D.get_closest_point_to_segment(wo, a, b)
			var d: float = p.distance_to(wo)
			if d < abstand:
				abstand = d
				beste = p
		return beste
	for r in gehfeld(kennung):
		var rect: Rect2 = r as Rect2
		var p: Vector2 = Vector2(
			clampf(wo.x, rect.position.x, rect.end.x),
			clampf(wo.y, rect.position.y, rect.end.y))
		var d: float = p.distance_to(wo)
		if d < abstand:
			abstand = d
			beste = p
	return beste


## Wie gross die Figur an dieser Hoehe gezeichnet wird.
##
## Linear zwischen den vier Zahlen aus `tiefe`. Kein Kamerasystem, keine Projektion — in einem
## Adventure mit gemalten Hintergruenden ist die Perspektive im Bild, und die Figur muss nur
## dazu passen.
static func groesse_bei(kennung: String, y: float) -> float:
	var t: Array = ort(kennung).get("tiefe", TIEFE_STANDARD) as Array
	if t.size() < 4:
		t = TIEFE_STANDARD
	var y0: float = float(t[0])
	var y1: float = float(t[1])
	var s0: float = float(t[2])
	var s1: float = float(t[3])
	if is_equal_approx(y0, y1):
		return s1
	var anteil: float = clampf((y - y0) / (y1 - y0), 0.0, 1.0)
	return lerpf(s0, s1, anteil)


## Wohin die Figur geht, um diesen Punkt zu bedienen.
##
## `hin` wenn angegeben, sonst die Mitte der Unterkante des Rechtecks, auf die begehbare Flaeche
## gezogen. Der Standard ist kein Notbehelf: Vor einer Sache zu stehen heisst in einem 2D-Bild
## fast immer, unterhalb davon zu stehen.
static func hingehen(kennung: String, punkt_kennung: String) -> Vector2:
	var p: Dictionary = punkte_alle(kennung).get(punkt_kennung, {}) as Dictionary
	if p.is_empty():
		return ort(kennung).get("start", RAHMEN * 0.5) as Vector2
	if p.has("hin"):
		return naechster_punkt(kennung, p["hin"] as Vector2)
	var r: Rect2 = p.get("rect", Rect2()) as Rect2
	return naechster_punkt(kennung, Vector2(r.position.x + r.size.x * 0.5, r.end.y))


## Die Sprites eines Ortes, als Liste von Eintraegen zum Zeichnen.
##
## Jeder Eintrag: {kennung, bild, fuss, rect, person, groesse}. `fuss` ist der Punkt, an dem
## das Sprite auf dem Boden steht (nur bei Personen gesetzt); fuer Gegenstaende ist es die
## Unterkante des Rechtecks, damit die Reihenfolge trotzdem stimmt.
##
## Warum hier und nicht in der Ansicht: Die Reihenfolge, in der gezeichnet wird, haengt an
## der Tiefe, und die Tiefe ist eine Eigenschaft des Ortes. Die Ansicht soll sortieren und
## zeichnen, nicht entscheiden, was wo steht.
static func sprites(kennung: String, sichtbar: Callable = Callable()) -> Array:
	var raus: Array = []
	var alle_p: Dictionary = punkte_alle(kennung)
	for k in alle_p:
		var p: Dictionary = alle_p[k] as Dictionary
		if str(p.get("sprite", "")) == "":
			continue
		if sichtbar.is_valid() and not bool(sichtbar.call(str(k), p)):
			continue
		var rect: Rect2 = p.get("rect", Rect2()) as Rect2
		var ist_person: bool = p.has("steht")
		raus.append({
			"kennung": str(k),
			"bild": str(p["sprite"]),
			"person": ist_person,
			"fuss": (p["steht"] as Vector2) if ist_person else Vector2(
				rect.position.x + rect.size.x * 0.5, rect.end.y),
			"rect": rect,
			"groesse": float(p.get("groesse", 1.0)),
		})
	return raus


## Welcher Punkt liegt unter `wo`?
##
## Der kleinste Treffer gewinnt. Sonst verdeckt ein grosses Rechteck — eine Theke, eine Wand —
## alles, was davor liegt, und der Spieler kann die Person hinter der Theke nicht anklicken.
## `sichtbar` entscheidet, ob ein Punkt ueberhaupt zaehlt; sie kommt von aussen, weil die
## Welt-Flaggen im `GameState` liegen und nicht hier.
static func punkt_bei(kennung: String, wo: Vector2, sichtbar: Callable = Callable()) -> String:
	var treffer: String = ""
	var flaeche: float = INF
	var alle_p: Dictionary = punkte_alle(kennung)
	for k in alle_p:
		var p: Dictionary = alle_p[k] as Dictionary
		if sichtbar.is_valid() and not bool(sichtbar.call(k, p)):
			continue
		var r: Rect2 = p.get("rect", Rect2()) as Rect2
		if not r.has_point(wo):
			continue
		var f: float = r.size.x * r.size.y
		if f < flaeche:
			flaeche = f
			treffer = k
	return treffer


## Wo die Figur ankommt, wenn sie durch `tuer` nach `ziel` geht.
##
## Das Ziel schreibt die Ankunft nicht selbst auf — es nennt sie nur beim Namen (`dort`), und
## der Zielort fuehrt unter `ankunft` eine Liste. Fehlt der Eintrag, gilt `start`. So kann man
## einen Ort ergaenzen, ohne jeden Ausgang zu finden, der auf ihn zeigt.
static func ankunft(ziel: String, name: String) -> Vector2:
	var o: Dictionary = ort(ziel)
	var liste: Dictionary = o.get("ankunft", {}) as Dictionary
	if liste.has(name):
		return liste[name] as Vector2
	# Ohne eigene Ankunft: vor dem Ausgang, der zurueckfuehrt — das ist fast immer richtig und
	# spart eine Tabelle, die man sonst zweimal pflegt.
	for k in o.get("ausgaenge", {}):
		return hingehen(ziel, k)
	return o.get("start", RAHMEN * 0.5) as Vector2
