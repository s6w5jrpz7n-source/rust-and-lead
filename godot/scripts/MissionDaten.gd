extends RefCounted
## Gegenstände, Missionen, Tagebuch-Notizen und die Wirkung jedes „Benutzen“.
##
## ## Warum das zusammen in einer Datei steht
##
## Weil es dasselbe ist, von verschiedenen Seiten betrachtet: Ein Hotspot wird benutzt, das gibt
## einen Gegenstand, der schließt einen Missionsschritt ab, und das schreibt eine Zeile ins
## Tagebuch. Lägen die vier Tabellen in vier Dateien, müsste man beim Einbauen eines einzigen
## Rätsels vier Dateien anfassen und könnte in jeder etwas vergessen. Hier liest man ein Rätsel
## von oben nach unten.
##
## ## Die vier Tabellen
##
## * `GEGENSTAENDE` — was man tragen kann. `kombi` sagt, worauf es angewendet werden darf,
##   `bild` ist das freigestellte Sprite für die Inventarleiste (fehlt es, zeichnet
##   `Sinnbild` ein Ersatzzeichen).
## * `MISSIONEN` — Aufträge mit Schritten. Ein Schritt ist erfüllt, wenn seine `bedingung`
##   zutrifft; die Mission ist fertig, wenn alle Schritte erfüllt sind.
## * `NOTIZEN` — was der Held über die Welt weiß. Das ist kein Flavour: Im dritten Akt hängen
##   Gesprächsoptionen daran, ob man eine Notiz hat.
## * `WIRKUNGEN` — was „Benutzen“ an einem Hotspot tut.
##
## ## Eine Entscheidung, die hier festgeschrieben ist
##
## **Kein Rätsel darf nur einen Lösungsweg haben, wenn sein Gegenstand verloren gehen kann.**
## Gegenstände sind in diesem Spiel nie verbrauchbar, außer die Tabelle sagt `verbraucht: true`,
## und dann gibt es einen zweiten Weg. Das ist die Lehre aus dreißig Jahren Adventures: Ein
## Spielstand, in dem man weiterspielen kann, aber nicht mehr gewinnen, ist schlimmer als ein
## Absturz, weil man es erst drei Stunden später merkt.

const GEGENSTAENDE: Dictionary = {
	"revolver": {
		"name": "Abgegriffener Revolver",
		"bild": "res://assets/dinge/revolver.webp",
		"text": "Sechs Kammern, zwei geladen. Der Griff hat die Form einer Hand, die nicht meine ist — und doch liegt er richtig.",
	},
	"schraubstock": {
		"name": "Schwerer Schraubstock",
		"bild": "res://assets/dinge/schraubstock.webp",
		"text": "Gusseisen, zwölf Pfund, nicht festgeschraubt. Silas wird ihn vermissen, aber nicht bald.",
		"kombi": ["karre"],
	},
	"grubenstahl": {
		"name": "Grubenstahl",
		"bild": "res://assets/dinge/grubenstahl.webp",
		"text": "Drei Barren aus dem Vorschacht. Kalt, schwer, und an einer Kante klebt etwas, das nicht Erz ist.",
		"kombi": ["esse"],
	},
	"linse": {
		"name": "Kinetoskop-Linse",
		"bild": "res://assets/dinge/linse.webp",
		"text": "Eine geschliffene Linse aus der Guckloch-Säule, handtellergroß. Sie bündelt, was hinter ihr brennt, zu einem Strahl, der weiter trägt als jede Lampe.",
		"kombi": ["oellampe"],
		"verbinden": {
			"mit": "oellampe",
			"wird": "signallampe",
			"text": "Ich klemme die Linse vor das Lampenglas. Der Schein wird aus einem Kreis ein Strahl — und ein Strahl ist keine Lampe mehr, sondern ein Zeichen.",
		},
	},
	"signallampe": {
		"name": "Signallampe",
		"bild": "res://assets/dinge/signallampe.webp",
		"text": "Grubenlampe mit Kinetoskop-Linse davor. Damit leuchtet man nicht, damit meldet man — und zwar in dem Takt, den der Konzern seinen Patrouillen beigebracht hat.",
		"kombi": ["felsen", "stollen_dunkel"],
	},
	"akte_mantel": {
		"name": "Akte „Projekt Mantel“",
		"bild": "res://assets/dinge/akte.webp",
		"text": "Eine Krankenakte ohne Namen. PROJEKT MANTEL — EINHEIT 7. Letzter Eintrag vor drei Wochen: Erinnerungswalze getauscht.",
	},
	"walze": {
		"name": "Gesprungene Musikwalze",
		"bild": "res://assets/dinge/walze.webp",
		"text": "Eine Holzwalze mit Messingstiften. Ein Drittel der Stifte fehlt, der Rest sitzt schief. Darin steckt das Lied einer Toten.",
		"kombi": ["silas", "dolores"],
	},
	"beweis_wegelagerer": {
		"name": "Acht Halstücher",
		"bild": "res://assets/dinge/halstuecher.webp",
		"text": "Acht rote Tücher, jedes mit einem eingenähten Zeichen. Wegelagerer markieren ihre Beute, damit sich die Banden nicht gegenseitig bestehlen. Jetzt markieren sie sich selbst.",
	},
	"oellampe": {
		"name": "Grubenlampe",
		"bild": "res://assets/dinge/oellampe.webp",
		"text": "Messing, verbeult, der Docht noch feucht. Brennt lange genug für einen Weg hinein und nicht lange genug für einen zurück.",
		"kombi": ["stollen_dunkel", "linse"],
	},
	"brecheisen": {
		"name": "Brecheisen",
		"bild": "res://assets/dinge/brecheisen.webp",
		"text": "Eine Elle Flachstahl mit Klaue. Der Griff ist mit Lappen umwickelt, damit die Hand nicht friert. Wer das gewickelt hat, hat hier Winter erlebt.",
		"kombi": ["foerderkorb", "schrank", "truhe"],
	},
	"kesselschluessel": {
		"name": "Sechskantschlüssel",
		"bild": "res://assets/dinge/kesselschluessel.webp",
		"text": "Aus Doc Aris' unterster Schublade. Für Verschlüsse, die nicht in Fleisch vorkommen.",
		"kombi": ["bahre", "kadaver"],
	},
}

## Die Missionen des ersten Aktes.
##
## `schritte` ist eine Liste; jeder Schritt hat `text` (was im Tagebuch steht) und `bedingung`:
##
## | Bedingung | erfüllt, wenn |
## |---|---|
## | `{"flagge": "x"}`     | Welt-Flagge x gesetzt |
## | `{"gegenstand": "x"}` | x im Inventar |
## | `{"zaehler": "x", "ab": 8}` | Zähler x ist mindestens 8 |
## | `{"ort": "x"}`        | Ort x schon betreten |
const MISSIONEN: Dictionary = {
	# Diese Mission hiess urspruenglich "acht Wegelagerer erledigen" und zaehlte Abschuesse.
	# Das war die Bauform des Action-Spiels, und in einem Adventure gibt es dafuer schlicht
	# keinen Weg: Der Held hat einen Revolver mit zwei Kugeln und steht acht Maennern
	# gegenueber. Die Loesung ist deshalb keine Schiesserei, sondern ein Trick -- und der
	# braucht zwei Gegenstaende von zwei verschiedenen Orten, die man verbinden muss.
	#
	# Die Kette: Grubenlampe (im Automatenkadaver auf der Kippe) + Kinetoskop-Linse (aus der
	# Saeule auf dem Platz, sichtbar erst nachdem man gekurbelt hat) = Signallampe. Damit
	# leuchtet man die Felsen an der Piste an. Die Wegelagerer ueberfallen Fuhrwerke, aber
	# niemals den Konzern -- wer dessen Zeichen gibt, ist ploetzlich uninteressant.
	"q_wegelagerer": {
		"titel": "Acht auf der Piste",
		"von": "mabel",
		"kapitel": 1,
		"anriss": "Mabel will acht Wegelagerer von der Piste haben. Gegen acht Mann hilft kein Revolver — aber vielleicht ein Zeichen, das sie kennen.",
		"schritte": [
			{"text": "Etwas finden, das weit genug leuchtet", "bedingung": {"gegenstand": "signallampe"}},
			{"text": "Den Felsen an der Piste das Konzernzeichen geben", "bedingung": {"flagge": "wegelagerer_weg"}},
			{"text": "Mabel Bescheid geben", "bedingung": {"flagge": "q_wegelagerer_abgegeben"}},
		],
		"lohn": {"gold": 40, "erfahrung": 120},
	},
	"q_grubenstahl": {
		"titel": "Material für die Mauer",
		"von": "silas",
		"kapitel": 2,
		"anriss": "Silas braucht Grubenstahl aus dem Vorschacht. Da unten singt etwas.",
		"schritte": [
			{"text": "In den Vorschacht hinunter", "bedingung": {"ort": "vorschacht"}},
			{"text": "Grubenstahl holen", "bedingung": {"gegenstand": "grubenstahl"}},
			{"text": "Silas den Stahl bringen", "bedingung": {"flagge": "q_grubenstahl_abgegeben"}},
		],
		"lohn": {"gold": 60, "erfahrung": 180},
	},
	"q_ratten": {
		"titel": "Was aus den Rohren kommt",
		"von": "doc",
		"kapitel": 2,
		"anriss": "Doc Aris verarztet Bisse statt Wunden. Sie kommen aus den Rohren — also muss das Rohr zu.",
		"schritte": [
			{"text": "Herausfinden, wo die Viecher herauskommen", "bedingung": {"flagge": "brunnen_gesehen"}},
			{"text": "Das Rohr aufbrechen und zusetzen", "bedingung": {"flagge": "rohr_zu"}},
			{"text": "Doc Bescheid geben", "bedingung": {"flagge": "q_ratten_abgegeben"}},
		],
		"lohn": {"gold": 35, "erfahrung": 100},
	},
	"q_achse": {
		"titel": "Eine gebrochene Achse",
		"von": "quentin",
		"kapitel": 1,
		"anriss": "Quentin Vale braucht Silas' Schraubstock. Er sagt nicht, warum er nicht selbst geht — und das kostet extra.",
		"schritte": [
			{"text": "Den Schraubstock aus der Schmiede holen", "bedingung": {"gegenstand": "schraubstock"}},
			{"text": "Die Achse richten", "bedingung": {"flagge": "achse_gerichtet"}},
		],
		"lohn": {"gold": 20, "erfahrung": 80},
	},
	"q_walze": {
		"titel": "Dolores' dritte Walze",
		"von": "dolores",
		"kapitel": 1,
		"anriss": "Auf der gesprungenen Walze steht das Lied ihrer Tochter. Silas kann Stifte setzen — wenn er will.",
		"schritte": [
			# Flagge und nicht `{"gegenstand": "walze"}`: Die Walze geht im letzten Schritt an
			# Dolores ueber. Haenge der erste Schritt am Besitz, faellt er in dem Moment
			# wieder auf, in dem der dritte erfuellt wird -- und weil Schritte eine
			# Reihenfolge sind, waere die Mission damit nie fertig.
			{"text": "Die gesprungene Walze an sich nehmen", "bedingung": {"flagge": "walze_genommen"}},
			{"text": "Silas die Walze bringen", "bedingung": {"flagge": "walze_gerichtet"}},
			{"text": "Dolores die Walze zurückgeben", "bedingung": {"flagge": "walze_zurueck"}},
		],
		"lohn": {"gold": 0, "erfahrung": 150},
	},
}

## Was der Held über die Welt weiß.
##
## Gesetzt über die Wirkung `{"notiz": "x"}`. Das Tagebuch zeigt sie unter „Was ich weiß“ —
## getrennt von den Aufträgen, weil es kein Auftrag ist, sondern das, was man zusammenreimt.
const NOTIZEN: Dictionary = {
	"naht": {
		"titel": "Die Naht",
		"text": "Über meinem Schlüsselbein läuft eine Linie, zu gerade für eine Narbe. Ich spüre keinen Schmerz. Dolores sagt, ich gehe wie ein Uhrwerk in Stiefeln. Silas hat nicht widersprochen.",
	},
	"konzern": {
		"titel": "Iron Rail Consolidated",
		"text": "Besitzt die Schienen, das Wasser und die Uhr. Was er nicht besitzt, erklärt er zu Diebstahl. Dann kommen die Männer mit den Stempeln, und nach ihnen die mit den Gatlings.",
	},
	"mantel": {
		"titel": "Zahnrad in Knochenform",
		"text": "Silas hat eine Konzernzeichnung an der Wand: ein Gelenk im Schnitt, gebaut wie ein Knochen. Sie bauen Dinge, die nicht wie Maschinen aussehen. Daneben steht, von Hand: „Naht am Schlüsselbein“.",
	},
	"doc_luegt": {
		"titel": "Doc Aris lügt",
		"text": "Die Riemen an seiner Bahre sind von INNEN durchgewetzt. Was dort lag, wollte raus, nicht runter. Als ich nachfragte, hat er Instrumente sortiert, die schon sortiert waren.",
	},
	"einheit7": {
		"titel": "Einheit sieben",
		"text": "PROJEKT MANTEL, EINHEIT 7. Letzter Eintrag vor drei Wochen: „Erinnerungswalze getauscht. Reaktion unauffällig.“ Doc sagt, ich sei nicht Einheit sieben. Er hat es gesagt, bevor ich gefragt habe.",
	},
	"psalm": {
		"titel": "Der Psalm",
		"text": "Im Vorschacht singt etwas. Die Kumpel nennen es den Psalm und gehen nicht mehr runter. Silas hat es einmal gehört; er redet über Material, aber darüber nicht.",
	},
	"gideon": {
		"titel": "Gideon Cross",
		"text": "Hält Fort Freedom mit hundertzwanzig Leuten, die nichts zu verlieren haben. Will dem Konzern die Schienen, das Wasser und die Zeit abnehmen — in dieser Reihenfolge. Fragt nicht, woher einer kommt.",
	},
}

## Was „Benutzen“ an einem Hotspot tut.
##
## | Feld | Bedeutung |
## |---|---|
## | `text`      | was der Held dazu sagt oder denkt |
## | `gegenstand`| wandert ins Inventar |
## | `flagge`    | Welt-Flagge, die gesetzt wird |
## | `notiz`     | Tagebuch-Notiz |
## | `erfahrung` | Erfahrungspunkte |
## | `gold`      | Gold dazu (negativ: weg) |
## | `einmal`    | Flagge; ist sie gesetzt, kommt stattdessen `text_wieder` |
## | `text_wieder` | was beim zweiten Mal passiert |
## | `braucht`   | Gegenstand; fehlt er, kommt `text_fehlt`. **Darf eine Liste sein** — dann genügt einer davon |
## | `nur_wenn`  | Welt-Flagge, die vorher gesetzt sein muss; sonst kommt `text_noch_nicht` |
## | `verbraucht`| Gegenstand, der dabei weggeht |
const WIRKUNGEN: Dictionary = {
	"kadaver_pluendern": {
		"text": "Ich greife in die offene Brust des Automaten. Zahnräder, ein geplatzter Kessel — und zwischen zwei Rippenstreben eine Grubenlampe, die jemand dort versteckt hat.",
		"gegenstand": "oellampe",
		"einmal": "kadaver_leer",
		"text_wieder": "Da ist nichts mehr. Ich habe schon nachgesehen, und der Automat wird nicht voller.",
		"erfahrung": 20,
	},
	"kaktus_durchsuchen": {
		"text": "Unter dem Stachelbusch liegt eine Blechdose mit vierzehn Gold und einem Zahn. Jemand hat hier etwas vergraben und ist nicht zurückgekommen.",
		"gold": 14,
		"einmal": "kaktus_leer",
		"text_wieder": "Nur Dornen. Die Dose habe ich schon.",
		"erfahrung": 10,
	},
	"karre_flicken": {
		"text": "Ich setze den Schraubstock an die gebrochene Achse, ziehe sie gerade und klemme sie. Das hält bis Rustwater, vielleicht weiter.",
		"braucht": "schraubstock",
		"text_fehlt": "Die Achse ist gebrochen, nicht verbogen. Ohne schweres Werkzeug richte ich das mit der Hand nicht — ein Schraubstock müsste her.",
		"flagge": "achse_gerichtet",
		"erfahrung": 60,
		"gold": 40,
		"einmal": "achse_gerichtet",
		"text_wieder": "Die Achse hält. Mehr kann ich hier nicht tun.",
	},
	"brunnen_steigen": {
		"text": "Ich lehne mich über den Rand. Unten Münzen, Knochen, und zwei Meter tiefer ein Rohr, das nicht zum Brunnen gehört — es läuft waagerecht, nach Norden, Richtung Schienen.",
		"notiz": "konzern",
		"erfahrung": 15,
		"einmal": "brunnen_gesehen",
		"text_wieder": "Das Rohr ist noch da. Es führt nach Norden, und ich komme hier nicht hinein.",
	},
	"brett_lesen": {
		"text": "Drei Zettel sind noch lesbar: Wegelagerer auf der Südpiste, acht Stück. Nager in den Rohren, Kopf für Kopf bezahlt. Und ein Aufruf, dem Schmied Material zu bringen, mit Preis, aber ohne Name.",
		"erfahrung": 10,
	},
	"kinetoskop_kurbeln": {
		"text": "Ich kurbele. Im Guckloch laufen lachende Arbeiter durch eine saubere Werkhalle, dann ein Zug, dann eine Schrift: WIR BAUEN DEN MORGEN. Das Bild flackert, und für drei Bilder sieht man etwas anderes — eine Reihe Gestalten auf Bahren, Brust aufgeschnitten, und Männer, die hineingreifen.",
		"notiz": "mantel",
		"erfahrung": 40,
		"einmal": "kinetoskop_gesehen",
		"text_wieder": "Dieselbe Walze, dieselben drei Bilder dazwischen. Ich muss sie nicht nochmal sehen.",
	},
	"linse_brechen": {
		"text": "Ich hebele die Linse aus ihrer Fassung. Das Guckloch der Säule starrt jetzt blind auf den Platz, und der Konzern wirft seine Bilder an eine Wand, die keiner mehr sieht. Damit kann ich leben.",
		"braucht": "brecheisen",
		"text_fehlt": "Die Linse sitzt in einer Messingfassung, festgenietet. Mit den Fingern bekomme ich sie nicht heraus — dafür brauche ich etwas, das hebelt.",
		"gegenstand": "linse",
		"erfahrung": 40,
		"einmal": "linse_raus",
		"text_wieder": "Die Fassung ist leer. Die Linse habe ich.",
	},
	"felsen_leuchten": {
		"text": "Ich halte die Signallampe auf die Felsen und gebe den Takt, den der Konzern seinen Patrouillen beigebracht hat: lang, kurz, lang, Pause.\n\nOben bewegt sich etwas. Dann hört es auf, sich zu bewegen. Acht Männer gehen rückwärts über den Kamm und nehmen ihre Gewehre mit, und keiner von ihnen sieht nochmal her. Wegelagerer überfallen Fuhrwerke. Den Konzern überfällt man einmal.",
		"braucht": "signallampe",
		"text_fehlt": "Oben zwischen den Felsen sitzt jemand. Mehr als einer. Mit einem Revolver, in dem zwei Kugeln stecken, gehe ich da nicht hinauf.",
		"flagge": "wegelagerer_weg",
		"erfahrung": 150,
		"einmal": "wegelagerer_weg",
		"text_wieder": "Die Felsen sind leer. Die Piste gehört wieder dem, der sie geht.",
	},
	"rohr_zusetzen": {
		"text": "Ich breche das Gitter auf und sehe in das Rohr, das nicht zum Brunnen gehört. Drinnen bewegt sich etwas, viele davon. Ich schiebe den Gitterrost zurück, verkeile ihn mit dem Brecheisen und lege zwei Steine darauf. Das hält sie unten. Es löst nichts, aber es hält sie unten.",
		"braucht": "brecheisen",
		"text_fehlt": "Vor dem Rohr sitzt ein Gitterrost, festgerostet. Ohne Hebel bekomme ich den nicht auf.",
		"flagge": "rohr_zu",
		"erfahrung": 90,
		"einmal": "rohr_zu",
		"text_wieder": "Das Gitter ist verkeilt. Von unten kommt nichts mehr.",
	},
	"walze_silas": {
		"text": "Silas nimmt die Walze, dreht sie einmal im Licht und legt sie auf die Werkbank. „Zweiundfünfzig Stifte. Zwei Tage.“\n\nEs werden keine zwei Tage. Als ich am Abend wiederkomme, liegt sie fertig da, und er sagt nichts dazu. Auf meine Frage nach dem Lohn sieht er mich an, bis ich aufhöre zu fragen.",
		"braucht": "walze",
		"text_fehlt": "Silas sieht kurz auf und wieder weg. Ohne etwas in der Hand brauche ich ihm nicht die Zeit zu stehlen.",
		"flagge": "walze_gerichtet",
		"erfahrung": 70,
		"einmal": "walze_gerichtet",
		"text_wieder": "Die Walze ist gerichtet. Sie gehört nicht mir.",
	},
	"walze_dolores": {
		"text": "Ich lege Dolores die Walze in die Hände. Sie fährt mit dem Daumen über die Stifte, von vorn bis hinten, und zählt mit.\n\n„Zweiundfünfzig.“ Dann sagt sie eine Weile nichts. „Setz dich hin, Junge. Du musst nicht zuhören. Aber geh nicht weg, solange sie läuft.“",
		"braucht": "walze",
		"text_fehlt": "Die gesprungene Walze liegt im Saloon beim Klavier. Und richten kann ich sie nicht.",
		"nur_wenn": "walze_gerichtet",
		"text_noch_nicht": "Ich halte ihr die Walze hin und ziehe sie wieder zurück. Gesprungen, mit der Hälfte der Stifte — damit würde sie das Lied hören, wie es nicht ist. Erst muss jemand die Stifte setzen, der das kann.",
		"flagge": "walze_zurueck",
		"verbraucht": "walze",
		"erfahrung": 110,
		"einmal": "walze_zurueck",
		"text_wieder": "Sie hat ihre Walze. Mehr war nicht zu tun.",
	},
	"theke_trinken": {
		"text": "Mabel stellt mir was hin. Es schmeckt nach Terpentin und Zuckerrübe, und nach dem zweiten Schluck ist das ein Kompliment.",
		"einmal": "getrunken",
		"text_wieder": "Noch einen. Mabel hebt eine Augenbraue, schenkt aber nach.",
		"erfahrung": 5,
	},
	"klavier_walze": {
		"text": "Das Klavier spielt sich selbst, eine Holzwalze dreht unter den Hämmern. Drei Töne fehlen — und die Walze daneben, die abgelegte, ist gesprungen. Ich nehme sie mit.",
		"gegenstand": "walze",
		"einmal": "walze_genommen",
		"text_wieder": "Die gesprungene Walze habe ich. Die eingelegte lasse ich drin — der Saloon braucht seine drei Töne.",
		"erfahrung": 20,
	},
	"kopfgeld_lesen": {
		"text": "Vier Namen mit Preisen dahinter. „Kolben-Jack“, achthundert, lebend nicht gewünscht. Darunter drei, die schon durchgestrichen sind, und bei zweien steht der Name des Jägers auch durchgestrichen.",
		"erfahrung": 10,
	},
	"esse_benutzen": {
		"text": "Ich lege die Barren in die Glut und ziehe den Blasebalg. Silas sieht kurz hin, sagt nichts und nimmt mir die Zange aus der Hand — so hält man die nicht.",
		"braucht": "grubenstahl",
		"text_fehlt": "Eine Esse ohne Material ist ein heißes Loch. Silas wollte Grubenstahl aus dem Vorschacht.",
		"flagge": "q_grubenstahl_abgegeben",
		"erfahrung": 80,
	},
	"gang_hinab": {
		"text": "Ich zünde die Grubenlampe und gehe hinunter. Nach zwanzig Schritten liegt Grubenstahl in Barren an der Wand, gestapelt und stehengelassen — die Schicht ist gegangen, ohne mitzunehmen, wofür sie gekommen war.\n\nDer Ton kommt von tiefer. Er hat einen Takt, und auf dem Takt liegen Silben. Es singt nicht wie ein Mensch. Es singt wie etwas, dem jemand beigebracht hat, wie Menschen singen.",
		"braucht": ["oellampe", "signallampe"],
		"text_fehlt": "Zehn Schritte, und dann ist es dunkel. Ich taste, bis die Hand nichts mehr findet, und gehe zurück. Ohne Licht komme ich hier nicht weiter — im Automaten auf der Kippe lag eine Grubenlampe.",
		"gegenstand": "grubenstahl",
		"notiz": "psalm",
		"erfahrung": 120,
		"einmal": "gang_gewesen",
		"text_wieder": "Ich war unten. Der Stahl ist oben, der Gesang ist noch da, und Ebene 3 ist verkeilt. Weiter komme ich heute nicht.",
	},
	"korb_pruefen": {
		"text": "Der Keil sitzt von oben. Ich bekomme ihn mit der Hand nicht heraus — dafür bräuchte ich etwas Langes aus Stahl. Und ich bin mir nicht sicher, ob ich den Korb unbedingt freibekommen will.",
		"erfahrung": 15,
		"einmal": "korb_geprueft",
		"text_wieder": "Derselbe Keil, dieselbe Frage.",
	},
	"bahre_ansehen": {
		"text": "Ich fahre mit dem Finger über die Riemen. Das Leder ist von INNEN durchgewetzt, nicht außen. Was hier lag, hat nicht gezappelt — es hat gezogen, gleichmäßig, lange, bis das Leder nachgab.",
		"notiz": "doc_luegt",
		"flagge": "akte_sichtbar",
		"erfahrung": 35,
		"einmal": "bahre_gesehen",
		"text_wieder": "Von innen durchgewetzt. Daran ändert sich nichts, wenn ich nochmal hinsehe.",
	},
	"schrank_oeffnen": {
		"text": "Unterste Reihe: Gewindeschneider, Fühlerlehre, ein Sechskantschlüssel. Kein Feldscher der Welt braucht einen Sechskantschlüssel. Ich nehme ihn mit.",
		"gegenstand": "kesselschluessel",
		"flagge": "akte_sichtbar",
		"erfahrung": 30,
		"einmal": "schrank_leer",
		"text_wieder": "Der Rest ist Werkzeug für Fleisch. Das lasse ich ihm.",
	},
}


static func gegenstand(kennung: String) -> Dictionary:
	return GEGENSTAENDE.get(kennung, {}) as Dictionary


static func mission(kennung: String) -> Dictionary:
	return MISSIONEN.get(kennung, {}) as Dictionary


static func notiz(kennung: String) -> Dictionary:
	return NOTIZEN.get(kennung, {}) as Dictionary


static func wirkung(kennung: String) -> Dictionary:
	return WIRKUNGEN.get(kennung, {}) as Dictionary


## Die Gegenstände, von denen EINER reichen muss, damit eine Wirkung eintritt.
##
## `braucht` darf ein einzelner Gegenstand oder eine Liste sein, und der Unterschied ist kein
## Komfort. Die Grubenlampe lässt sich mit der Kinetoskop-Linse zur Signallampe verbauen; wer
## das tut, hätte ohne diese Liste in Kapitel 2 kein Licht mehr für den Stollen und könnte das
## Spiel nicht mehr gewinnen, ohne es zu merken. Genau der Zustand, den der Kommentar oben in
## dieser Datei verbietet. Also nimmt der Stollen beide Lampen.
static func braucht_liste(w: Dictionary) -> Array:
	if not w.has("braucht"):
		return []
	if w["braucht"] is Array:
		return (w["braucht"] as Array).duplicate()
	return [str(w["braucht"])]


## Was aus `a` und `b` wird, oder ein leeres Dictionary.
##
## Die Verbindung steht bei EINEM der beiden Gegenstände; gesucht wird in beiden Richtungen,
## damit es keine Rolle spielt, welchen man zuerst anklickt. Alles andere wäre eine Regel, die
## der Spieler nicht sehen kann.
static func verbindung(a: String, b: String) -> Dictionary:
	for paar in [[a, b], [b, a]]:
		var v: Dictionary = gegenstand(str(paar[0])).get("verbinden", {}) as Dictionary
		if not v.is_empty() and str(v.get("mit", "")) == str(paar[1]):
			return v
	return {}


static func alle_missionen() -> Array:
	return MISSIONEN.keys()


## Darf `was` auf `ziel` angewendet werden?
##
## Ohne `kombi` ist ein Gegenstand nirgends anwendbar — das ist die richtige Vorgabe. Ein
## Adventure, in dem jeder Gegenstand überall ein „geht nicht“ auslöst, lädt zum Durchprobieren
## ein, und Durchprobieren ist kein Rätsel.
static func kombinierbar(was: String, ziel: String) -> bool:
	return ziel in (gegenstand(was).get("kombi", []) as Array)


## Ist dieser Schritt erfüllt?
##
## Die vier Prüfer kommen von außen (`flagge`, `beutel`, `zaehler`, `orte`), weil der Zustand im
## `GameState` liegt. Fehlt ein Prüfer, gilt der Schritt als offen — nicht als erfüllt. Eine
## Mission, die ohne Zustand als fertig gilt, würde beim Laden eines Spielstands durchrutschen.
static func schritt_erfuellt(schritt: Dictionary, flagge: Callable, beutel: Callable,
		zaehler: Callable, orte: Callable) -> bool:
	var b: Dictionary = schritt.get("bedingung", {}) as Dictionary
	if b.has("flagge"):
		return flagge.is_valid() and bool(flagge.call(str(b["flagge"])))
	if b.has("gegenstand"):
		return beutel.is_valid() and bool(beutel.call(str(b["gegenstand"])))
	if b.has("zaehler"):
		if not zaehler.is_valid():
			return false
		return int(zaehler.call(str(b["zaehler"]))) >= int(b.get("ab", 1))
	if b.has("ort"):
		return orte.is_valid() and bool(orte.call(str(b["ort"])))
	return false


## Wie viele Schritte einer Mission erfüllt sind — und wie viele es sind.
static func fortschritt(kennung: String, flagge: Callable, beutel: Callable,
		zaehler: Callable, orte: Callable) -> Array:
	var liste: Array = mission(kennung).get("schritte", []) as Array
	var fertig: int = 0
	for s in liste:
		if schritt_erfuellt(s as Dictionary, flagge, beutel, zaehler, orte):
			fertig += 1
		else:
			break   # Schritte sind eine Reihenfolge, keine Menge
	return [fertig, liste.size()]
