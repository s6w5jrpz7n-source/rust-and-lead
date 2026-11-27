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
# Das ist KEINE isometrische Ansicht. Baphomets Fluch stellt die Kamera auf Augenhoehe eines
# Erwachsenen, hoechstens eine Handbreit darueber, und malt den Ort wie eine Theaterbuehne:
# eine Rueckwand mit Architektur, davor ein schmaler Streifen Boden, auf dem gelaufen wird.
# Die Figur steht in Dreiviertelansicht davor. Daraus folgen drei Masse, und sie gelten
# fuer jeden Ort dieses Spiels:
#
#  * **Der Laufstreifen liegt im unteren Drittel.** Oberhalb von y=430 wird nicht gelaufen,
#    dort steht das Bild. Wer die begehbare Flaeche hoeher zieht, bekommt die Iso-Ansicht
#    zurueck, die wir gerade verlassen haben.
#
#  * **Die Figur ist gross.** Rund 210 px bei Massstab 1.0, also knapp ein Drittel der
#    Bildhoehe. In einem Iso-Spiel ist die Figur klein, weil man die Umgebung ueberblicken
#    muss; in einem Adventure ist sie gross, weil man ihr Gesicht sehen soll.
#
#  * **Die Tiefe ist flach.** Zwischen hinterster und vorderster Standposition liegen
#    hoechstens 20 % Groessenunterschied. Baphomets Fluch skaliert kaum — ein Ort ist ein
#    Raum, keine Landschaft. Die alten Werte (0.62 bis 1.15, also 85 %) waren fuer eine
#    Kamera gedacht, die von schraeg oben auf eine Wueste sieht.

## Hoehe der Figur in Pixeln bei Massstab 1.0.
const FIGUR_HOEHE: float = 210.0

## Oberhalb dieser Linie wird nicht gelaufen — dort steht das gemalte Bild.
const BUEHNE_HORIZONT: float = 430.0

## Wie klein die Figur hinten und wie gross vorne, wenn ein Ort keine eigene `tiefe` angibt.
## Flach, siehe oben: 0.88 bis 1.08 sind 20 % ueber den ganzen Laufstreifen.
const TIEFE_STANDARD: Array = [450.0, 665.0, 0.88, 1.08]

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
		"gehfeld": [Rect2(120.0, 430.0, 1040.0, 230.0)],
		"start": Vector2(300.0, 540.0),
		"tiefe": [455.0, 665.0, 0.87, 1.08],
		"punkte": {
			"haende": {
				"name": "Die eigenen Hände",
				"rect": Rect2(250.0, 470.0, 110.0, 120.0),
				"hin": Vector2(330.0, 560.0),
				"person": "held",
				"ansehen": "Zwei Hände. Schwielen, Schmutz, eine Narbe über dem rechten Knöchel. Sie gehören zu mir, und das ist alles, was ich über sie weiß.",
				"reden": "held_selbst",
			},
			"kadaver": {
				"name": "Ausgeweideter Automat",
				"rect": Rect2(620.0, 440.0, 190.0, 160.0),
				"hin": Vector2(700.0, 620.0),
				"ansehen": "Ein Automat, dem jemand die Brustplatte aufgeschnitten hat. Innen Zahnräder, ein geplatzter Druckkessel, Öl, das nicht mehr fließt. Irgendwer hat geholt, was zu holen war.",
				"benutzen": "kadaver_pluendern",
			},
			"revolver": {
				"name": "Revolver im Staub",
				"rect": Rect2(830.0, 560.0, 100.0, 70.0),
				"hin": Vector2(880.0, 625.0),
				"ansehen": "Ein Revolver, halb im Staub. Der Griff ist abgegriffen, als hätte ihn lange jemand gehalten. Sechs Kammern, zwei geladen.",
				"nehmen": "revolver",
			},
			"brecheisen": {
				"name": "Brecheisen im Schrott",
				"rect": Rect2(380.0, 580.0, 150.0, 70.0),
				"hin": Vector2(450.0, 640.0),
				"ansehen": "Ein Brecheisen zwischen zwei Blechplatten, eine Elle Flachstahl mit Klaue. Der Griff ist mit Lappen umwickelt, damit die Hand im Winter nicht am Metall klebt.",
				"nehmen": "brecheisen",
			},
			"tafel": {
				"name": "Verbogenes Blechschild",
				"rect": Rect2(420.0, 400.0, 150.0, 90.0),
				"hin": Vector2(480.0, 500.0),
				"ansehen": "Ein Schild, von der Sonne ausgebleicht: IRON RAIL CONSOLIDATED — ABWURFZONE 7. KEIN ZUTRITT. Darunter, mit Nagel gekratzt: „zu spät“.",
			},
		},
		"ausgaenge": {
			"abstieg": {
				"name": "Hinunter zur Piste",
				"rect": Rect2(1120.0, 470.0, 150.0, 200.0),
				"hin": Vector2(1130.0, 600.0),
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
		"gehfeld": [Rect2(60.0, 450.0, 1160.0, 220.0)],
		"start": Vector2(640.0, 560.0),
		"punkte": {
			"karre": {
				"name": "Liegengebliebene Karre",
				"rect": Rect2(430.0, 420.0, 230.0, 180.0),
				"hin": Vector2(540.0, 620.0),
				"ansehen": "Ein Dampfkarren mit gebrochener Achse. Der Kessel zischt noch, also steht er nicht lange hier.",
				"benutzen": "karre_flicken",
				"braucht": "schraubstock",
			},
			"quentin": {
				"name": "Quentin Vale",
				"rect": Rect2(680.0, 410.0, 110.0, 200.0),
				"hin": Vector2(700.0, 610.0),
				"person": "quentin",
				"ansehen": "Ein hagerer Mann im zu guten Mantel, der eine gebrochene Achse ansieht wie einen persönlichen Affront.",
				"reden": "quentin_piste",
			},
			"kaktus": {
				"name": "Stachelbusch",
				"rect": Rect2(170.0, 480.0, 120.0, 130.0),
				"hin": Vector2(240.0, 620.0),
				"ansehen": "Ein Busch, der mehr Dorn als Pflanze ist. In seinem Schatten liegt etwas Metallisches.",
				"benutzen": "kaktus_durchsuchen",
			},
			"felsen": {
				"name": "Felsen über der Piste",
				"rect": Rect2(620.0, 230.0, 320.0, 190.0),
				"hin": Vector2(760.0, 560.0),
				"ansehen": "Ein Felsriegel über der Piste, von dem man alles sieht, was unten durchkommt. Zwischen den Steinen bewegt sich etwas, und es bewegt sich in Deckung.",
				"benutzen": "felsen_leuchten",
				"braucht": "signallampe",
			},
			"knochen": {
				"name": "Knochen am Pistenrand",
				"rect": Rect2(900.0, 580.0, 160.0, 70.0),
				"hin": Vector2(960.0, 630.0),
				"ansehen": "Ein Brustkorb, sauber abgenagt. Daneben ein Stiefel, in dem noch ein Fuß steckt. Die Wüste räumt nicht auf, sie sortiert nur.",
			},
		},
		"ausgaenge": {
			"zurueck": {
				"name": "Zurück zur Kippe",
				"rect": Rect2(0.0, 450.0, 70.0, 220.0),
				"hin": Vector2(70.0, 570.0),
				"ansehen": "Der Hang hinauf, aus dem ich gekrochen bin. Da ist nichts mehr.",
				"ziel": "kippe",
				"dort": "von_piste",
			},
			"tor": {
				"name": "Stadttor von Rustwater",
				"rect": Rect2(1140.0, 400.0, 140.0, 270.0),
				"hin": Vector2(1150.0, 580.0),
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
		"gehfeld": [Rect2(80.0, 460.0, 1120.0, 210.0), Rect2(520.0, 435.0, 260.0, 45.0)],
		"start": Vector2(640.0, 600.0),
		"punkte": {
			"brunnen": {
				"name": "Trockener Brunnen",
				"rect": Rect2(560.0, 470.0, 180.0, 150.0),
				"hin": Vector2(650.0, 640.0),
				"ansehen": "Ein Brunnen ohne Wasser. Auf dem Grund liegen Münzen, Knochen und ein Schild: „WASSER WIRD ZUGETEILT. IRON RAIL CONSOLIDATED“.",
				"benutzen": "brunnen_steigen",
			},
			"aushang": {
				"name": "Auftragsbrett",
				"rect": Rect2(880.0, 420.0, 150.0, 180.0),
				"hin": Vector2(950.0, 620.0),
				"ansehen": "Ein Brett voller Zettel. Kopfgelder, Suchanzeigen, zwei Todesanzeigen, die noch keiner abgenommen hat.",
				"benutzen": "brett_lesen",
			},
			"kinetoskop": {
				"name": "Kinetoskop-Säule",
				"rect": Rect2(240.0, 400.0, 130.0, 210.0),
				"hin": Vector2(300.0, 620.0),
				"ansehen": "Eine Säule mit Guckloch und Kurbel. Der Konzern wirft hier seine Bilder an die Wand: lachende Arbeiter, saubere Werkhallen. Niemand sieht hin.",
				"benutzen": "kinetoskop_kurbeln",
			},
			"linse": {
				"name": "Linse der Kinetoskop-Säule",
				"rect": Rect2(252.0, 430.0, 90.0, 80.0),
				"hin": Vector2(300.0, 620.0),
				"ansehen": "Hinter dem Guckloch sitzt eine geschliffene Linse in einer Messingfassung. Sie bündelt den Schein der Projektionslampe zu einem Strahl.",
				"benutzen": "linse_brechen",
				"braucht": "brecheisen",
				"sicht": "kinetoskop_gesehen",
			},
			"rohr": {
				"name": "Gitterrost im Brunnenschacht",
				"rect": Rect2(590.0, 560.0, 120.0, 70.0),
				"hin": Vector2(650.0, 648.0),
				"ansehen": "Zwei Meter tief sitzt ein Gitterrost vor dem waagerechten Rohr. Dahinter bewegt sich etwas, und es sind zu viele, um sie zu zählen.",
				"benutzen": "rohr_zusetzen",
				"braucht": "brecheisen",
				"sicht": "brunnen_gesehen",
			},
			"dolores": {
				"name": "Dolores am Brunnenrand",
				"rect": Rect2(420.0, 480.0, 100.0, 150.0),
				"hin": Vector2(450.0, 640.0),
				"person": "dolores",
				"ansehen": "Eine alte Frau mit einer Drehorgel, die seit Jahren dieselben drei Walzen spielt. Sie sieht einen an, als kenne sie einen.",
				"reden": "dolores_platz",
				"benutzen": "walze_dolores",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Tor nach draußen",
				"rect": Rect2(0.0, 460.0, 80.0, 210.0),
				"hin": Vector2(85.0, 590.0),
				"ansehen": "Zurück auf die Piste. Die Wüste wartet, sie hat Zeit.",
				"ziel": "piste",
				"dort": "von_platz",
			},
			"saloon": {
				"name": "Gatling-Saloon",
				"rect": Rect2(620.0, 230.0, 220.0, 200.0),
				"hin": Vector2(700.0, 470.0),
				"ansehen": "Ein zweistöckiger Kasten mit Schwingtür. Über dem Eingang hängt ein Gatling-Lauf als Wirtshausschild. Von drinnen Klavier und Gelächter.",
				"ziel": "saloon",
				"dort": "von_platz",
			},
			"schmiede": {
				"name": "Schmiede",
				"rect": Rect2(960.0, 250.0, 230.0, 180.0),
				"hin": Vector2(1050.0, 480.0),
				"ansehen": "Ein offener Schuppen mit Esse. Der Hammerschlag kommt in einem Takt, der sich seit dreißig Jahren nicht geändert hat.",
				"ziel": "schmiede",
				"dort": "von_platz",
			},
			"schacht": {
				"name": "Weg zum Vorschacht",
				"rect": Rect2(1180.0, 460.0, 100.0, 210.0),
				"hin": Vector2(1190.0, 600.0),
				"ansehen": "Hinter der Schmiede führt ein ausgetretener Pfad zum Schachtkopf. Früher gingen dort morgens vierzig Mann hinunter. Heute steht der Förderkorb oben und niemand daneben.",
				"ziel": "vorschacht",
				"dort": "von_platz",
			},
			"lazarett": {
				"name": "Feldlazarett",
				"rect": Rect2(330.0, 250.0, 200.0, 180.0),
				"hin": Vector2(420.0, 480.0),
				"ansehen": "Ein Zelt über einem Steinfundament, davor eine Bahre, die noch nass ist. Ein rotes Kreuz, mit Blut nachgezogen.",
				"ziel": "lazarett",
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
		"gehfeld": [Rect2(120.0, 470.0, 1040.0, 190.0)],
		"start": Vector2(400.0, 600.0),
		"tiefe": [485.0, 665.0, 0.92, 1.06],
		"punkte": {
			"mabel": {
				"name": "Mamma „Rusty“ Mabel",
				"rect": Rect2(560.0, 360.0, 150.0, 210.0),
				"hin": Vector2(600.0, 590.0),
				"person": "mabel",
				"ansehen": "Eine Frau um die fünfzig hinter der Theke, Unterarme wie Ankerketten. Sie wischt ein Glas, das schon trocken ist, weil ihre Hände etwas tun müssen, während sie einen abschätzt.",
				"reden": "mabel_saloon",
			},
			"theke": {
				"name": "Theke",
				"rect": Rect2(420.0, 480.0, 440.0, 120.0),
				"hin": Vector2(520.0, 620.0),
				"ansehen": "Ein Brett auf zwei Fässern, blank gewischt von dreißig Jahren Ellbogen. In das Holz sind Namen geschnitten, die meisten durchgestrichen.",
				"benutzen": "theke_trinken",
			},
			"klavier": {
				"name": "Mechanisches Klavier",
				"rect": Rect2(170.0, 430.0, 200.0, 170.0),
				"hin": Vector2(260.0, 620.0),
				"ansehen": "Ein Klavier, das sich selbst spielt — eine Walze dreht, Hämmer folgen. Drei Töne fehlen, und niemand hier hört das noch.",
				"benutzen": "klavier_walze",
			},
			"gideon": {
				"name": "Gideon Cross",
				"rect": Rect2(920.0, 390.0, 130.0, 200.0),
				"hin": Vector2(930.0, 600.0),
				"person": "gideon",
				"ansehen": "Ein breiter Mann an einem Tisch, mit dem Rücken zur Wand und freiem Blick zur Tür. Vor ihm ein Glas, das er nicht anfasst.",
				"reden": "gideon_saloon",
			},
			"brett": {
				"name": "Kopfgeldbrett",
				"rect": Rect2(1080.0, 400.0, 130.0, 170.0),
				"hin": Vector2(1100.0, 600.0),
				"ansehen": "Das Brett, auf dem der Saloon seine Rechnungen auslegt: wer wen tot sehen will, und wofür.",
				"benutzen": "kopfgeld_lesen",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Hinaus auf den Platz",
				"rect": Rect2(0.0, 420.0, 110.0, 250.0),
				"hin": Vector2(140.0, 600.0),
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
		"gehfeld": [Rect2(140.0, 480.0, 1000.0, 180.0)],
		"start": Vector2(300.0, 600.0),
		"tiefe": [490.0, 665.0, 0.92, 1.06],
		"punkte": {
			"silas": {
				"name": "Silas „Kupferauge“ Finch",
				"rect": Rect2(640.0, 370.0, 150.0, 220.0),
				"hin": Vector2(660.0, 600.0),
				"person": "silas",
				"ansehen": "Ein alter Schmied, Lederschurz, Hände wie Werkzeug. Das linke Auge ist aus Kupfer und Glas und sitzt nicht ganz gerade in der Höhle.",
				"reden": "silas_schmiede",
				"benutzen": "walze_silas",
			},
			"esse": {
				"name": "Esse",
				"rect": Rect2(880.0, 400.0, 200.0, 200.0),
				"hin": Vector2(940.0, 620.0),
				"ansehen": "Kohlenglut unter einem Blasebalg. Die Hitze steht wie eine Wand davor.",
				"benutzen": "esse_benutzen",
			},
			"werkbank": {
				"name": "Werkbank",
				"rect": Rect2(200.0, 470.0, 260.0, 130.0),
				"hin": Vector2(300.0, 620.0),
				"ansehen": "Zangen, Feilen, ein halb fertiger Revolvertrommel-Rohling. Dazwischen ein schwerer Schraubstock, der nicht angeschraubt ist.",
				"nehmen": "schraubstock",
			},
			"plaene": {
				"name": "Angenagelte Risszeichnung",
				"rect": Rect2(480.0, 350.0, 140.0, 120.0),
				"hin": Vector2(540.0, 560.0),
				"ansehen": "Eine Zeichnung an der Wand: ein Gelenk im Schnitt, Zahnrad in Knochenform. Die Beschriftung ist in Konzernschrift, der Stempel durchgestrichen. Jemand hat daneben gekritzelt: „Naht am Schlüsselbein“.",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Hinaus auf den Platz",
				"rect": Rect2(0.0, 440.0, 130.0, 230.0),
				"hin": Vector2(160.0, 600.0),
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
		"gehfeld": [Rect2(130.0, 480.0, 1020.0, 180.0)],
		"start": Vector2(280.0, 600.0),
		"tiefe": [490.0, 665.0, 0.92, 1.06],
		"punkte": {
			"doc": {
				"name": "Doc Aris",
				"rect": Rect2(560.0, 370.0, 140.0, 220.0),
				"hin": Vector2(580.0, 600.0),
				"person": "doc",
				"ansehen": "Ein hagerer Mann mit Schürze, auf der zwei Arten Blut trocknen. Er wäscht sich die Hände länger, als nötig wäre.",
				"reden": "doc_lazarett",
			},
			"bahre": {
				"name": "Bahre",
				"rect": Rect2(760.0, 470.0, 260.0, 130.0),
				"hin": Vector2(850.0, 620.0),
				"ansehen": "Eine Bahre mit Lederriemen an Hand- und Fußende. Die Riemen sind von innen durchgewetzt. Was hier lag, hat sich gewehrt.",
				"benutzen": "bahre_ansehen",
			},
			"schrank": {
				"name": "Instrumentenschrank",
				"rect": Rect2(220.0, 400.0, 170.0, 200.0),
				"hin": Vector2(290.0, 620.0),
				"ansehen": "Zangen, Sägen, Klemmen — und in der untersten Reihe Werkzeug, das nicht in Fleisch gehört: Gewindeschneider, Fühlerlehre, ein Schlüssel für Sechskant.",
				"benutzen": "schrank_oeffnen",
			},
			"akte": {
				"name": "Aufgeschlagene Akte",
				"rect": Rect2(440.0, 480.0, 120.0, 90.0),
				"hin": Vector2(480.0, 620.0),
				"ansehen": "Eine Krankenakte ohne Namen, nur eine Nummer: PROJEKT MANTEL — EINHEIT 7. Darunter eine Liste von Eingriffen, die bis vor drei Wochen reicht. Die letzte Zeile: „Erinnerungswalze getauscht. Reaktion unauffällig.“",
				"nehmen": "akte_mantel",
				"sicht": "akte_sichtbar",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Hinaus auf den Platz",
				"rect": Rect2(0.0, 440.0, 120.0, 230.0),
				"hin": Vector2(150.0, 600.0),
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
		"gehfeld": [Rect2(140.0, 475.0, 1000.0, 190.0)],
		"start": Vector2(1050.0, 590.0),
		"tiefe": [490.0, 665.0, 0.92, 1.06],
		"punkte": {
			"stollen_dunkel": {
				"name": "Der dunkle Gang",
				"rect": Rect2(420.0, 360.0, 230.0, 230.0),
				"hin": Vector2(530.0, 620.0),
				"ansehen": "Nach zehn Schritten hört der Gang auf, hell zu sein. Was danach kommt, weiß ich nicht, und ohne Licht werde ich es nicht herausfinden. Von unten kommt ein Ton, der nicht aufhört.",
				"benutzen": "gang_hinab",
				"braucht": "oellampe",
			},
			"foerderkorb": {
				"name": "Förderkorb",
				"rect": Rect2(820.0, 390.0, 190.0, 220.0),
				"hin": Vector2(880.0, 630.0),
				"ansehen": "Ein Eisenkorb an einer Trommel, hochgezogen und verkeilt. Jemand hat den Keil von oben gesetzt — damit niemand hochkommt, nicht damit niemand runterfährt.",
				"benutzen": "korb_pruefen",
			},
			"schild": {
				"name": "Angenagelte Tafel",
				"rect": Rect2(190.0, 420.0, 160.0, 120.0),
				"hin": Vector2(260.0, 600.0),
				"ansehen": "Mit Kreide auf Blech: EBENE 3 GESPERRT. Darunter, von anderer Hand und tiefer eingeritzt: „es singt noch“. Die Kreide ist verwischt, die Ritzung nicht.",
			},
		},
		"ausgaenge": {
			"raus": {
				"name": "Zurück nach Rustwater",
				"rect": Rect2(1150.0, 450.0, 130.0, 220.0),
				"hin": Vector2(1128.0, 600.0),
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


## Die begehbare Flaeche als Liste von Rechtecken.
static func gehfeld(kennung: String) -> Array:
	return ort(kennung).get("gehfeld", []) as Array


## Darf die Figur hier stehen?
static func begehbar(kennung: String, wo: Vector2) -> bool:
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
	var beste: Vector2 = wo
	var abstand: float = INF
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
