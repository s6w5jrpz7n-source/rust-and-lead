extends RefCounted
## Der Aufbau der Kapitel — linear mit wenigen Seitensträngen, und einer Schlussszene,
## in der alle Stränge zusammenlaufen.
##
## ## Die Bauform, und warum genau diese
##
## Baphomets Fluch ist kein offenes Spiel. Es ist eine Kette von Kapiteln, in denen man an
## zwei, drei Fäden gleichzeitig zieht, und erst wenn **alle** abgearbeitet sind, geht es
## weiter. Das ist die Form, die der Spieler hier bekommt:
##
##     ┌─ Hauptstrang ──────────────────────────────┐
##     │  Schritt 1 → Schritt 2 → Schritt 3         │   verpflichtend, in dieser Reihenfolge
##     ├─ Seitenstrang A ───────────────────────────┤
##     │  (eigenes Rätsel, eigener Lohn)            │   verpflichtend, Reihenfolge egal
##     ├─ Seitenstrang B ───────────────────────────┤
##     │  (eigenes Rätsel, eigener Lohn)            │   verpflichtend, Reihenfolge egal
##     └────────────────┬───────────────────────────┘
##                      ▼
##               SCHLUSSSZENE            alle Stränge treffen sich an einem Ort
##                      ▼
##             nächstes Kapitel
##
## **Alle Stränge sind Pflicht.** Das ist eine bewusste Entscheidung gegen den Zeitgeist: Ein
## optionaler Nebenauftrag, den 60 % der Spieler nie sehen, ist Arbeit, die man einmal macht
## und fünfmal nicht gespielt bekommt. Hier ist jeder Strang gebaut, also wird jeder gespielt,
## also darf jeder etwas erzählen, das im nächsten Kapitel vorausgesetzt wird. Genau davon lebt
## Baphomets Fluch: Dass man in Kapitel 5 noch weiß, wem man in Kapitel 2 die Ziege gestohlen hat.
##
## **Die Schlussszene ist der Kitt.** Ohne sie wären die Stränge drei Rätsel nebeneinander.
## Mit ihr sind sie drei Vorbereitungen auf einen Abend, an dem alle Beteiligten am selben Tisch
## sitzen und sich die Lage ändert. Sie ist auch die Stelle, an der das Spiel speichern darf,
## ohne dass jemand in einem unlösbaren Zustand landet.
##
## ## Was hier steht und was nicht
##
## Dieses Verzeichnis kennt die **Struktur** aller zwölf Kapitel — Titel, Stränge, Schlussort.
## Ausgespielt (Orte, Gespräche, Rätsel) sind davon die, bei denen `fertig` auf `true` steht.
## Der Rest ist Gerüst, damit man beim Bauen sieht, worauf es zuläuft, und damit das Tagebuch
## die Kapitelnamen schon kennt.
##
## ## Felder
##
## | Feld | Bedeutung |
## |---|---|
## | `titel`     | Kapitelname, wie er im Tagebuch steht |
## | `akt`       | 1, 2 oder 3 — für die Kapitelkarte |
## | `ort_start` | wo das Kapitel anfängt |
## | `strang`    | Missionen des Hauptstrangs, in Reihenfolge |
## | `seiten`    | Missionen der Seitenstränge; Reihenfolge egal, aber alle Pflicht |
## | `schluss`   | die Szene, in der alles zusammenläuft |
## | `fertig`    | ist dieses Kapitel ausgespielt? |

const MissionDaten = preload("res://scripts/MissionDaten.gd")

const KAPITEL: Dictionary = {

	1: {
		"titel": "Staub & Blei",
		"akt": 1,
		"fertig": true,
		"ort_start": "kippe",
		"anriss": "Ein Mann wacht auf einer Schrottkippe auf, ohne Namen und ohne Schmerz. Bis zum Abend muss er sich in Rustwater so weit nützlich gemacht haben, dass ihn jemand behält.",
		# Der Hauptstrang ist absichtlich kurz: aufwachen, in die Stadt kommen, den ersten
		# Auftrag annehmen und erfüllen. Mehr braucht ein erstes Kapitel nicht, und weniger
		# würde nicht reichen, um die Bedienung beizubringen.
		"strang": ["q_wegelagerer"],
		# Zwei Seitenstränge, beide Pflicht. Sie sind nicht Beiwerk — der eine (Quentin) führt
		# den Konzern ein, ohne dass geschossen wird, der andere (Dolores) legt den ersten
		# Hinweis darauf, was der Held ist. Wer nur den Hauptstrang spielte, käme ohne beides
		# in Kapitel 2, und dann stünde Kapitel 4 ohne Vorbereitung da.
		"seiten": ["q_achse", "q_walze"],
		"schluss": {
			"ort": "saloon",
			"titel": "Erster Abend",
			"gespraech": "schluss_k1",
			"anriss": "Mabel macht zu, Gideon bleibt sitzen, Dolores spielt die dritte Walze. Und draußen hält ein Konzernkarren, der nicht halten sollte.",
		},
	},

	2: {
		"titel": "Sand im Räderwerk",
		"akt": 1,
		"fertig": true,
		"ort_start": "platz",
		"anriss": "Der Konzern sperrt die Wasserstelle. Silas braucht Grubenstahl für die Mauer, Doc braucht die Rohre frei — und beides liegt unter der Stadt.",
		"strang": ["q_grubenstahl"],
		"seiten": ["q_ratten"],
		"schluss": {
			"ort": "lazarett",
			"titel": "Zähe Konstitution",
			"gespraech": "schluss_k2",
			"anriss": "Doc Aris näht einen Riss, der nicht blutet, und redet dabei schneller als nötig.",
		},
	},

	3: {
		"titel": "Die Mine",
		"akt": 1,
		"fertig": false,
		"ort_start": "vorschacht",
		"anriss": "Drei Ebenen tief singt etwas. Die Kumpel nennen es den Psalm und gehen nicht mehr runter.",
		"strang": [],
		"seiten": [],
		"schluss": {"ort": "mine_ebene3", "titel": "PSALM", "gespraech": "", "anriss": "In der Schatzkammer steht eine Maschine, die betet."},
	},

	4: {
		"titel": "Der Zugüberfall",
		"akt": 1,
		"fertig": false,
		"ort_start": "zug_dach",
		"anriss": "Kolben-Jack überfällt den Nachtzug. Im dritten Waggon hängt ein Spiegel.",
		"strang": [],
		"seiten": [],
		"schluss": {"ort": "spiegel_wagen", "titel": "DER SPIEGEL", "gespraech": "", "anriss": "Die wichtigste Szene des Spiels. Danach ist nichts mehr, wie es war — und der Spieler weiß, was er die ganze Zeit war."},
	},

	5: {"titel": "Erwacht", "akt": 2, "fertig": false, "ort_start": "saloon",
		"anriss": "Drei Gilden werben. Man muss sich entscheiden, und die Entscheidung hält bis zum Ende.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "saloon", "titel": "Schmieröl", "gespraech": "", "anriss": "Mabel stellt Schmieröl statt Schnaps hin und sagt nichts dazu."}},

	6: {"titel": "Kupfer & Kesseldruck", "akt": 2, "fertig": false, "ort_start": "schmiede",
		"anriss": "Silas baut um, was der Konzern gebaut hat.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "unterschlupf", "titel": "Das Flackern", "gespraech": "", "anriss": "Nachts flackert ein Bild, das nicht zur eigenen Erinnerung gehört."}},

	7: {"titel": "Das flackernde Bild", "akt": 2, "fertig": false, "ort_start": "unterschlupf",
		"anriss": "Die getauschte Erinnerungswalze gibt zurück, was auf ihr stand.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "kinetoskop_halle", "titel": "Die Naht", "gespraech": "", "anriss": "Was man sieht, hängt davon ab, für wen man sich entschieden hat."}},

	8: {"titel": "Die Wahrheit im Kessel", "akt": 2, "fertig": false, "ort_start": "providence",
		"anriss": "Providence Cut. Der zweite Twist, und er ist schlimmer als der erste.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "providence", "titel": "Providence Cut", "gespraech": "", "anriss": "Aschgraue Dämmerung über einer Ruine, in der jemand gewohnt hat."}},

	9: {"titel": "Kriegsmaschine", "akt": 3, "fertig": false, "ort_start": "fort_freedom",
		"anriss": "Der Kreuzzug beginnt, und Doc stellt die Frage, die niemand stellen wollte.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "lazarett", "titel": "Docs Frage", "gespraech": "", "anriss": "„Wenn ich dich flicke — heile ich dich, oder repariere ich dich?“"}},

	10: {"titel": "Sabotage", "akt": 3, "fertig": false, "ort_start": "pipeline",
		"anriss": "Eine gesprengte Pipeline, und eine Stimme aus dem Norden, die den eigenen Namen kennt.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "pipeline", "titel": "Die Stimme aus dem Norden", "gespraech": "", "anriss": "Sie weiß, wie man heißt. Man selbst weiß es immer noch nicht."}},

	11: {"titel": "Die letzte Bastion", "akt": 3, "fertig": false, "ort_start": "saloon",
		"anriss": "Die Nacht vor dem Sturm. Jeder sagt, was er noch sagen will.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "saloon", "titel": "Die Nacht davor", "gespraech": "", "anriss": "Sperrstunde. Mabel schließt nicht ab."}},

	12: {"titel": "Sturm auf die Iron Rail", "akt": 3, "fertig": false, "ort_start": "eisernes_herz",
		"anriss": "Das Walzen-Archiv, die Herzkammer, der Mann aus Wachs — und drei Enden.",
		"strang": [], "seiten": [],
		"schluss": {"ort": "direktorat", "titel": "Der Mann aus Wachs", "gespraech": "", "anriss": "Im Direktorat sitzt jemand, der seit zwölf Jahren nicht gealtert ist."}},
}


static func kapitel(nummer: int) -> Dictionary:
	return KAPITEL.get(nummer, {}) as Dictionary


static func titel(nummer: int) -> String:
	return str(kapitel(nummer).get("titel", ""))


static func anzahl() -> int:
	return KAPITEL.size()


## Alle Missionen eines Kapitels — Hauptstrang zuerst, dann die Seitenstränge.
##
## Eine Liste und keine Menge: Das Tagebuch zeigt sie in dieser Reihenfolge, und die soll
## „erst die Geschichte, dann die Nebensachen" sein, nicht alphabetisch.
static func missionen(nummer: int) -> Array:
	var k: Dictionary = kapitel(nummer)
	var raus: Array = []
	for m in k.get("strang", []) as Array:
		raus.append(str(m))
	for m in k.get("seiten", []) as Array:
		raus.append(str(m))
	return raus


## Die Missionen dieses Kapitels, die noch nicht erledigt sind.
##
## `ist_fertig` kommt von außen (aus `Welt`), damit dieses Verzeichnis reine Daten bleibt und
## headless prüfbar ist, ohne dass ein Spielstand existiert.
static func offen(nummer: int, ist_fertig: Callable) -> Array:
	var raus: Array = []
	for m in missionen(nummer):
		if not (ist_fertig.is_valid() and bool(ist_fertig.call(str(m)))):
			raus.append(str(m))
	return raus


## Ist die Schlussszene erreichbar — also sind ALLE Stränge abgearbeitet?
##
## Das ist die eine Bedingung, die das Spiel vorwärts bewegt. Sie steht hier und nicht verteilt
## in den Orten, weil sie sonst in zwölf Kapiteln zwölfmal leicht anders geschrieben würde.
static func schluss_frei(nummer: int, ist_fertig: Callable) -> bool:
	return offen(nummer, ist_fertig).is_empty() and not missionen(nummer).is_empty()


## Wo die Schlussszene spielt, oder "" wenn das Kapitel keine hat.
static func schluss_ort(nummer: int) -> String:
	return str((kapitel(nummer).get("schluss", {}) as Dictionary).get("ort", ""))


static func schluss(nummer: int) -> Dictionary:
	return kapitel(nummer).get("schluss", {}) as Dictionary


## Ist dieses Kapitel ausgespielt — also mit Orten, Gesprächen und Rätseln hinterlegt?
static func ausgespielt(nummer: int) -> bool:
	return bool(kapitel(nummer).get("fertig", false))


## Das letzte ausgespielte Kapitel. Hinter ihm endet das Spiel mit einem ehrlichen Hinweis
## statt mit einer Tür, die ins Leere führt.
static func letztes_ausgespieltes() -> int:
	var letztes: int = 0
	for n in KAPITEL.keys():
		if ausgespielt(int(n)) and int(n) > letztes:
			letztes = int(n)
	return letztes


## Zu welchem Kapitel gehört diese Mission? 0, wenn zu keinem.
##
## Wird vom Tagebuch gebraucht, um Aufträge unter ihrem Kapitel einzusortieren — und von der
## Testsuite, um die Gegenprobe zu machen: Jede Mission in `MissionDaten` muss in genau einem
## Kapitel vorkommen. Eine Mission, die in keinem steht, kann der Spieler annehmen und nie
## abschließen, weil nichts sie je verlangt.
static func kapitel_von(mission: String) -> int:
	for n in KAPITEL.keys():
		if mission in missionen(int(n)):
			return int(n)
	return 0
