extends RefCounted
## Die Gespräche als **Bäume** — Fallout-2-Bauform: der andere redet, man wählt aus Nummern.
##
## ## Warum Bäume und nicht die Liste aus `DialogData`
##
## `DialogData` liefert pro Anlass eine Liste von Sätzen, durch die eine Sprechtafel blättert.
## Das war richtig für ein Action-Spiel, in dem Reden eine Nebensache ist. In einem Adventure
## IST Reden das Spiel: Man muss nachfragen können, lügen können, eine Tür zumachen können.
## Dafür braucht jede Zeile Antwortmöglichkeiten, und die führen zu weiteren Zeilen — ein Baum.
##
## ## Der Ton bleibt, die Aufnahmen bleiben
##
## Die Sätze der Figuren sind, wo es ging, **wortgleich** aus `DialogData` übernommen. Das ist
## keine Bequemlichkeit: `Stimme.kennung()` bildet den Dateinamen aus dem SHA-256 des Textes.
## Ein wortgleicher Satz findet seine schon gerenderte MP3 in `assets/voice/` — ein umformu-
## lierter schweigt. Deshalb steht hinter übernommenen Zeilen `# vertont`.
##
## Die **Antworten des Helden sind absichtlich nicht vertont**. Genau so hält es Fallout 2: Der
## Gegenüber spricht, der Spieler liest. Das hat drei Gründe, und alle drei gelten hier auch —
## der Held bleibt stimmlich eine Leerstelle (sein ganzes Thema), man kann Antworten jederzeit
## umschreiben, ohne eine Aufnahme zu verlieren, und es halbiert die Vertonungsarbeit.
##
## ## Aufbau
##
## `BAEUME[kennung]` hat `person` (für Portrait und Stimme), `start` und `knoten`.
##
## Ein Knoten:
##
## | Feld | Bedeutung |
## |---|---|
## | `wer`        | wer in diesem Knoten spricht; fehlt es, gilt `person` des Baums |
## | `sagt`       | Liste von Sätzen; die Tafel blättert sie durch, bevor die Antworten kommen |
## | `sagt_enthuellt` | ersetzt `sagt`, sobald `GameState.is_revealed` gilt |
## | `antworten`  | Liste von Antwortmöglichkeiten, in dieser Reihenfolge nummeriert |
##
## Eine Antwort:
##
## | Feld | Bedeutung |
## |---|---|
## | `text`   | was dasteht; `[1]` setzt die Oberfläche davor |
## | `ziel`   | Knoten, der folgt. Fehlt es, endet das Gespräch |
## | `wenn`   | Welt-Flagge muss gesetzt sein |
## | `nicht`  | Welt-Flagge darf nicht gesetzt sein |
## | `hat`    | Gegenstand muss im Inventar sein |
## | `tut`    | Wirkung, siehe `MissionDaten.WIRKUNGEN` und `wirken()` |
## | `nur_enthuellt` / `nur_verhuellt` | nur vor bzw. nach dem Reveal wählbar |
##
## ## Eine Regel, die hier mit Absicht steht
##
## **Jeder Knoten braucht einen Ausweg.** Ein Knoten ohne Antwort, die das Gespräch beendet
## oder weiterführt, ist eine Falle, aus der der Spieler nur über das Hauptmenü kommt. Die
## Testsuite prüft das für jeden Knoten jedes Baums — es ist der Fehler, den man beim Schreiben
## am leichtesten macht und beim Spielen am spätesten merkt.

const BAEUME: Dictionary = {

	# ── Der Held mit sich selbst ──────────────────────────────────────────────────
	# Das erste „Gespräch“ des Spiels, und es hat nur einen Teilnehmer. Es erklärt die
	# Oberfläche (man wählt Nummern) an einer Stelle, an der man nichts falsch machen
	# kann, und setzt gleichzeitig die Ausgangslage: keine Erinnerung, kein Schmerz.
	"held_selbst": {
		"person": "held",
		"start": "wach",
		"knoten": {
			"wach": {
				"sagt": [
					"Ich liege auf Schrott. Die Sonne steht hoch, mein Mund ist trocken, und ich weiß nicht, wie ich heiße.",
					"Was ich weiß: wie man eine Waffe hält. Wo man hintritt, damit Blech nicht verrät, dass man kommt. Dass man Wasser nicht teilt.",
					"Nützliches Wissen. Von wem ich es habe, steht nirgends.",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Woher kommt das Blut an meinem Hemd?", "ziel": "blut"},
					{"sinnbild": "frage", "text": "Wie lange liege ich hier?", "ziel": "zeit"},
					{"text": "Aufstehen. Fragen kosten Wasser.", "tut": {"flagge": "wach_geworden"}},
				],
			},
			"blut": {
				"sagt": [
					"Es ist getrocknet und es ist nicht meins — an mir finde ich keine Wunde. Keine einzige.",
					"Man wird nicht mit fremdem Blut auf einer Schrottkippe wach, ohne dass etwas passiert ist.",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Und es tut nichts weh. Nichts.", "ziel": "schmerz"},
					{"text": "Aufstehen.", "tut": {"flagge": "wach_geworden"}},
				],
			},
			"zeit": {
				"sagt": [
					"Die Sonne hat mir die rechte Seite verbrannt und die linke nicht. Also seit dem Morgen.",
					"Oder seit drei Tagen und sie dreht sich nur langsam. Ich habe keinen Anhaltspunkt, und das ist das eigentlich Beunruhigende.",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Woher kommt das Blut an meinem Hemd?", "ziel": "blut"},
					{"text": "Aufstehen.", "tut": {"flagge": "wach_geworden"}},
				],
			},
			"schmerz": {
				"sagt": [
					"Ich drücke auf die Rippen. Nichts. Ich beiße in den Handrücken, bis Haut nachgibt. Nichts.",
					"Irgendwo ganz hinten, so weit weg, dass es keine Empfindung mehr ist, meldet etwas einen Wert. Als läse jemand eine Zahl vor.",
					"Ich denke darüber nicht weiter nach. Nicht jetzt.",
				],
				"antworten": [
					{"text": "Aufstehen.", "tut": {"flagge": "wach_geworden", "notiz": "naht"}},
				],
			},
		},
	},

	# ── Mabel im Saloon ──────────────────────────────────────────────────────────
	# Die Mutterfigur. Alle ihre Sätze hier sind vertont. Sie gibt den ersten richtigen
	# Auftrag (Wegelagerer) und ist die Einzige, die nicht fragt, was man ist.
	"mabel_saloon": {
		"person": "mabel",
		"start": "erst",
		"knoten": {
			"erst": {
				"sagt": [
					"„Du siehst aus wie durchgekaut und wieder ausgespuckt. Setz dich, bevor du umfällst.“",   # vertont
					"„Von der Kippe rauf, ja? Da liegen normalerweise nur Blech und Knochen. Du bist mir ein hübsches drittes.“",   # vertont
				],
				"sagt_enthuellt": [
					"„Für dich hab ich Schmieröl statt Schnaps.“",   # vertont
					"„Wundert dich das? Mich wundert gar nichts mehr.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Ich weiß nicht, wie ich heiße.", "ziel": "name", "nicht": "mabel_kennt"},
					{"sinnbild": "ort:platz", "text": "Was ist das hier für eine Stadt?", "ziel": "stadt"},
					{"sinnbild": "frage", "text": "Gibt es Arbeit?", "ziel": "arbeit"},
					{"sinnbild": "wissen", "text": "Die Piste ist frei. Die acht sind weg.", "ziel": "abgabe",
					 "wenn": "wegelagerer_weg", "nicht": "q_wegelagerer_abgegeben"},
					{"sinnbild": "streit", "text": "Du wusstest es, oder? Von Anfang an.", "ziel": "wusste", "nur_enthuellt": true},
					{"text": "(Gehen)"},
				],
			},
			"name": {
				"sagt": [
					"„Namen brauch ich keinen. Wer aus dem Schrott kommt, hat meistens keinen mehr.“",   # vertont
					"„Trink das hier. Und dann hör mir zu.“",   # vertont
				],
				"antworten": [
					{"text": "Ich höre.", "ziel": "arbeit", "tut": {"flagge": "mabel_kennt", "erfahrung": 15}},
					{"sinnbild": "ort:platz", "text": "Was ist das hier für eine Stadt?", "ziel": "stadt", "tut": {"flagge": "mabel_kennt"}},
				],
			},
			"stadt": {
				"sagt": [
					"„Rustwater. Vierzig Seelen, wenn man die Hunde mitzählt, und das muss man.“",
					"„Wir sitzen auf dem einen Brunnen, der dem Konzern noch nicht gehört. Deshalb sind wir noch da, und deshalb sind wir nicht lange da.“",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Wer ist „der Konzern“?", "ziel": "konzern"},
					{"sinnbild": "frage", "text": "Gibt es Arbeit?", "ziel": "arbeit"},
					{"text": "(Gehen)"},
				],
			},
			"konzern": {
				"sagt": [
					"„Iron Rail Consolidated. Sie haben die Schienen, das Wasser und die Uhr.“",
					"„Was sie nicht haben, erklären sie zu Diebstahl. Dann kommen die Männer mit den Stempeln, und nach den Stempeln die mit den Gatlings.“",
					"„Frag Gideon da hinten, wenn du's ausführlich willst. Ich muss Gläser wischen.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Gibt es Arbeit?", "ziel": "arbeit"},
					{"text": "(Gehen)", "tut": {"notiz": "konzern"}},
				],
			},
			"arbeit": {
				"sagt": [
					"„Draußen sitzen Wegelagerer auf der Piste und nehmen sich, was durchkommt.“",   # vertont
					"„Acht Stück, sagt der Aushang. Bring mir den Beweis, dann bring ich dir was Ordentliches zu essen.“",   # vertont
				],
				"antworten": [
					{"text": "Ich mach's.", "tut": {"quest": "q_wegelagerer", "erfahrung": 10}},
					{"sinnbild": "streit", "text": "Acht gegen einen. Was zahlst du wirklich?", "ziel": "preis"},
					{"sinnbild": "streit", "text": "Nicht mein Problem.", "ziel": "abgelehnt"},
				],
			},
			"preis": {
				"sagt": [
					"„Vierzig Gold, Essen für eine Woche und einen Platz oben, wo keiner reinkommt.“",
					"„Und du kannst dich hier hinsetzen, ohne dass jemand fragt, woher du kommst. Das ist in dieser Gegend mehr wert als die vierzig.“",
				],
				"antworten": [
					{"text": "Abgemacht.", "tut": {"quest": "q_wegelagerer", "erfahrung": 20}},
					{"text": "Ich denk drüber nach.", "ziel": "abgelehnt"},
				],
			},
			"abgelehnt": {
				"sagt": [
					"„Die Wüste frisst Leute wie dich zum Frühstück.“",   # vertont
					"„Aber du bist ja noch da. Also weiter.“",   # vertont
				],
				"antworten": [
					{"text": "Vielleicht später.", "ziel": "erst"},
					{"text": "(Gehen)"},
				],
			},
			# Die Abgabe. Sie ist absichtlich kein Dankesritual: Mabel glaubt es erst nicht,
			# und als sie es glaubt, ist sie nicht geruehrt, sondern erleichtert -- so redet
			# jemand, der seit Jahren ausrechnet, wie lange die Stadt noch durchhaelt.
			"abgabe": {
				"sagt": [
					"„Weg. Einfach so.“",
					"„Kein Schuss, kein Blut, keine acht Leichen, die ihre Brüder holen kommen. Weißt du, wie viele hier schon losgezogen sind, um das zu erledigen?“",
					"„Vier. Zurückgekommen ist einer, und der hat danach nicht mehr geredet.“",
					"„Setz dich. Heute zahlst du nichts.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Wie hab ich's gemacht, willst du gar nicht wissen?", "ziel": "wie",
					 "tut": {"flagge": "q_wegelagerer_abgegeben"}},
					{"sinnbild": "weg", "text": "(Sich setzen)",
					 "tut": {"flagge": "q_wegelagerer_abgegeben"}},
				],
			},
			"wie": {
				"sagt": [
					"„Nein.“",
					"„Wenn ich's weiß, muss ich's irgendwann jemandem erzählen. Und dann wissen sie es auch.“",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "(Sich setzen)", "tut": {"erfahrung": 30}},
				],
			},
			"wusste": {
				"sagt": [
					"„Setz dich, Kind. Aber vorher…“",   # vertont
					"„Ich hab Männer gesehen, die nach drei Tagen Wüste nicht mehr zucken. Du hast nie gezuckt, nicht einmal.“",
					"„Was unter deinem Mantel steckt, hab ich nicht gewusst. Dass da was steckt, schon.“",
				],
				"antworten": [
					{"sinnbild": "person:mabel", "text": "Und du hast mich trotzdem reingelassen.", "ziel": "trotzdem"},
					{"text": "(Gehen)"},
				],
			},
			"trotzdem": {
				"sagt": [
					"„Du bist zäher, als du aussiehst.“",   # vertont
					"„Setz dich. Heute zahlst du nichts.“",   # vertont
				],
				"antworten": [
					{"text": "(Sitzen bleiben)", "tut": {"flagge": "mabel_treu", "erfahrung": 40}},
				],
			},
		},
	},

	# ── Silas in der Schmiede ────────────────────────────────────────────────────
	# Er sieht die Naht am Schlüsselbein, sagt es aber nicht. Wer nachfragt, bekommt
	# vor Kapitel 4 eine Ausweichantwort — und genau die ist der Hinweis.
	"silas_schmiede": {
		"person": "silas",
		"start": "erst",
		"knoten": {
			"erst": {
				"sagt": [
					"„Neu hier. Und schon kaputt.“",   # vertont
					"„Ich richte alles, was aus Metall ist. Für den Rest gibt's den Doc.“",   # vertont
				],
				"sagt_enthuellt": [
					"„Chassis-Platten? Für dich zum Selbstkostenpreis.“",   # vertont
					"„Reg dich nicht auf. Ich hab's vom ersten Tag an gesehen.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "person:silas", "text": "Was ist mit deinem Auge?", "ziel": "auge"},
					{"sinnbild": "wissen", "text": "Die Zeichnung da an der Wand — was ist das?", "ziel": "zeichnung"},
					{"sinnbild": "frage", "text": "Hast du Arbeit?", "ziel": "arbeit"},
					{"sinnbild": "person:held", "text": "Du siehst mehr als andere. Was siehst du an mir?", "ziel": "an_mir"},
					{"text": "(Gehen)"},
				],
			},
			"auge": {
				"sagt": [
					"„Mein Auge sieht mehr als deins, Fremder.“",   # vertont
					"„Kupfer, Glas und eine Linse aus dem Konzernlager. Das Fleischauge hab ich an einen Kessel verloren, der nicht halten wollte.“",
					"„Seitdem seh ich, wie Dinge gemacht sind. Das ist nicht immer ein Geschenk.“",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Du siehst mehr als andere. Was siehst du an mir?", "ziel": "an_mir"},
					{"sinnbild": "frage", "text": "Hast du Arbeit?", "ziel": "arbeit"},
					{"text": "(Gehen)"},
				],
			},
			"an_mir": {
				"sagt": [
					"„Gute Arbeit. Das hält.“",   # vertont
				],
				"sagt_enthuellt": [
					"„Reg dich nicht auf. Ich hab's vom ersten Tag an gesehen.“",   # vertont
					"„Eine Naht über dem Schlüsselbein, zu gerade für eine Narbe. Und du atmest in einem Takt, den kein Mensch hält.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Das war keine Antwort.", "ziel": "keine_antwort", "nur_verhuellt": true},
					{"sinnbild": "streit", "text": "Warum hast du nichts gesagt?", "ziel": "nichts_gesagt", "nur_enthuellt": true},
					{"text": "(Gehen)"},
				],
			},
			"keine_antwort": {
				"sagt": [
					"„Nein.“",
					"„Es gibt Sachen, die man nur selber rausfinden darf. Sonst richten sie mehr Schaden an, als sie klären.“",
					"„Frag mich in einem Monat nochmal. Wenn du dann noch fragen musst, sag ich's dir.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Hast du Arbeit?", "ziel": "arbeit", "tut": {"notiz": "naht"}},
					{"text": "(Gehen)", "tut": {"notiz": "naht"}},
				],
			},
			"nichts_gesagt": {
				"sagt": [
					"„Weil du's nicht geglaubt hättest, und dann wär ich der verrückte Alte mit dem Kupferauge gewesen.“",
					"„Und weil du gut warst für diese Stadt, solange du nicht wusstest, was du bist. Das ist kein schöner Satz. Ist trotzdem wahr.“",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Kannst du mich reparieren?", "ziel": "reparieren"},
					{"text": "(Gehen)"},
				],
			},
			"reparieren": {
				"sagt": [
					"„Chassis-Platten? Für dich zum Selbstkostenpreis.“",   # vertont
					"„Bring mir Grubenstahl, dann mach ich dir eine Platte, die einen Bolzen aushält. Mehr kann ich nicht versprechen.“",
				],
				"antworten": [
					{"sinnbild": "ding:grubenstahl", "text": "Ich hol dir Grubenstahl.", "tut": {"quest": "q_grubenstahl", "erfahrung": 25}},
					{"text": "(Gehen)"},
				],
			},
			"zeichnung": {
				"sagt": [
					"„Konzernarbeit. Ein Gelenk im Schnitt — Zahnrad in Knochenform.“",
					"„Hab sie aus einem Waggon, den wir aufgemacht haben. Sie bauen Dinge, die aussehen wie wir. Nicht grob, nicht als Maschine erkennbar. Genau wie wir.“",
					"„Ich hab sie aufgehängt, damit ich's nicht vergesse.“",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Wozu baut man sowas?", "ziel": "wozu", "tut": {"notiz": "mantel"}},
					{"text": "(Gehen)", "tut": {"notiz": "mantel"}},
				],
			},
			"wozu": {
				"sagt": [
					"„Um jemanden hinzuschicken, wo man selber nicht hin will. Und um ihn nachher nicht beerdigen zu müssen.“",
					"„Der Konzern hat kein Problem mit Toten. Er hat ein Problem mit Zeugen.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Hast du Arbeit?", "ziel": "arbeit"},
					{"text": "(Gehen)"},
				],
			},
			"arbeit": {
				"sagt": [
					"„Diese Stadt frisst Material.“",   # vertont
					"„Bring mir Grubenstahl aus dem Vorschacht, ich mach dir was daraus, das hält.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "ding:grubenstahl", "text": "Ich hol ihn.", "tut": {"quest": "q_grubenstahl", "erfahrung": 15}},
					{"sinnbild": "ort:vorschacht", "text": "Was ist da unten?", "ziel": "unten"},
					{"text": "Später.", "ziel": "spaeter"},
				],
			},
			"unten": {
				"sagt": [
					"„Ohne Grubenstahl keine Mauer. Und den holt keiner da unten raus.“",   # vertont
					"„Ratten, so groß wie Hunde, und etwas, das singt. Die Kumpel nennen's den Psalm. Ich hab's einmal gehört und bin nicht mehr runter.“",
				],
				"antworten": [
					{"sinnbild": "ding:grubenstahl", "text": "Ich hol ihn trotzdem.", "tut": {"quest": "q_grubenstahl", "erfahrung": 25, "notiz": "psalm"}},
					{"sinnbild": "wissen", "text": "Ich will wissen, was da unten singt.", "ziel": "psalm_frage",
					 "wenn": "gang_gewesen"},
					{"text": "Später.", "ziel": "spaeter"},
				],
			},
			"psalm_frage": {
				"sagt": [
					"„Dann bist du schon unten gewesen. Und du bist wiedergekommen, das sind schon zwei Dinge, die keiner schafft.“",
					"„Es gibt drei Ebenen. Auf der dritten war seit elf Jahren keiner, weil auf der zweiten etwas steht, an dem die Leute umdrehen.“",
					"„Wenn du runtergehst: Nimm dir Zeit für die Stützen. Nicht für die Wände — für die Stützen.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Was steht auf der zweiten Ebene?", "ziel": "zweite_ebene"},
					{"sinnbild": "ding:oellampe", "text": "Ich gehe runter.",
					 "tut": {"quest": "q_psalm", "erfahrung": 60}},
				],
			},
			"zweite_ebene": {
				"sagt": [
					"„Geh selber hin.“",
					"„Wenn ich's dir sage, siehst du, was ich gesagt hab. Wenn du's selber siehst, siehst du, was da ist. Das ist nicht dasselbe, und bei dieser Sache ist der Unterschied alles.“",
				],
				"antworten": [
					{"sinnbild": "ding:oellampe", "text": "Ich gehe runter.",
					 "tut": {"quest": "q_psalm", "erfahrung": 80}},
					{"sinnbild": "weg", "text": "(Gehen)"},
				],
			},
			"spaeter": {
				"sagt": ["„Mein Auge sieht mehr als deins, Fremder.“"],   # vertont
				"antworten": [
					{"text": "(Gehen)"},
				],
			},
		},
	},

	# ── Doc Aris im Lazarett ─────────────────────────────────────────────────────
	# Er hat den Helden zusammengebaut. Vor dem Reveal lügt er — und wird dabei
	# nervös, was der Text zeigt, ohne es zu sagen. Nach dem Reveal ist er kalt.
	"doc_lazarett": {
		"person": "doc",
		"start": "erst",
		"knoten": {
			"erst": {
				"sagt": [
					"„Blut im Haar. Setz dich, das seh ich mir an.“",   # vertont
					"„…und du zuckst nicht mal. Interessant.“",   # vertont
				],
				"sagt_enthuellt": [
					"„Bei dir spar ich mir das Verarzten.“",   # vertont
					"„Ein Jammer. Du wärst ein guter Patient gewesen.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Ich spüre keinen Schmerz. Ist das normal?", "ziel": "schmerz"},
					{"sinnbild": "wissen", "text": "Wer hat diese Riemen an der Bahre durchgewetzt?", "ziel": "riemen"},
					{"text": "Was ist PROJEKT MANTEL?", "ziel": "mantel", "hat": "akte_mantel"},
					{"sinnbild": "wissen", "text": "Das Rohr im Brunnen ist zu.", "ziel": "rohr_abgabe",
					 "wenn": "rohr_zu", "nicht": "q_ratten_abgegeben"},
					{"sinnbild": "frage", "text": "Hast du Arbeit?", "ziel": "arbeit"},
					{"text": "(Gehen)"},
				],
			},
			"rohr_abgabe": {
				"sagt": [
					"„Eine Plage weniger.“",   # vertont
					"„Du hast das Gitter verkeilt, statt sie einzeln totzuschlagen. Das hätte hier niemand gemacht. Die Leute wollen die Viecher sehen, wenn sie sterben.“",
					"„Es wird nicht halten. Aber es hält länger als ein Haufen Kadaver.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Du klingst nicht erleichtert.", "ziel": "nicht_erleichtert",
					 "tut": {"flagge": "q_ratten_abgegeben"}},
					{"sinnbild": "weg", "text": "(Gehen)", "tut": {"flagge": "q_ratten_abgegeben"}},
				],
			},
			"nicht_erleichtert": {
				"sagt": [
					"„Ich bin Feldscher. Erleichterung ist etwas, das ich anderen verschreibe.“",
					"„Geh schlafen. Du siehst müde aus, und das ist bei dir eine Seltenheit, über die ich lieber nicht nachdenke.“",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "(Gehen)", "tut": {"erfahrung": 25}},
				],
			},
			"schmerz": {
				"sagt": [
					"„Nach einem Schlag auf den Kopf? Kommt vor. Betäubung von innen, der Körper schützt sich.“",
					"„Das geht vorbei. Wenn nicht, komm wieder.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Du hast eben weggesehen.", "ziel": "weggesehen"},
					{"text": "In Ordnung.", "ziel": "erst"},
				],
			},
			"weggesehen": {
				"sagt": [
					"„Ich habe Instrumente sortiert.“",
					"„Hör zu — in dieser Gegend ist die Frage, warum einer lebt, meistens teurer als die Antwort. Du lebst. Nimm es mit.“",
				],
				"antworten": [
					{"text": "Was ist PROJEKT MANTEL?", "ziel": "mantel", "hat": "akte_mantel"},
					{"text": "(Gehen)", "tut": {"notiz": "doc_luegt", "flagge": "akte_sichtbar"}},
				],
			},
			"riemen": {
				"sagt": [
					"„Ein Kumpel, letzten Monat. Bolzen im Bein, musste raus, und Äther hatten wir nicht.“",
					"„Er hat die Riemen durchgebissen und sich an der Bahre festgehalten. Deshalb kauf ich neue, wenn ich Geld habe. Ich habe nie Geld.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Und die Riemen sind von INNEN durchgewetzt.", "ziel": "innen"},
					{"text": "In Ordnung.", "ziel": "erst"},
				],
			},
			"innen": {
				"sagt": [
					"„…Was?“",
					"„Nein. Nein, das ist — von der Haltung, wenn man sich aufstemmt, dann reibt das Leder von der Seite. Du siehst das falsch.“",
					"„Ich habe zu arbeiten.“",
				],
				"antworten": [
					{"text": "(Nicht weiter fragen)", "tut": {"notiz": "doc_luegt", "flagge": "akte_sichtbar", "erfahrung": 30}},
				],
			},
			"mantel": {
				"sagt": [
					"„Wo hast du das her.“",
					"„…egal. Es ist nicht das, was du denkst. Es ist nicht einmal von hier, das ist eine Konzernakte, die liegt bei mir, weil sie bei jemandem liegen muss.“",
					"„Einheit sieben. Du bist nicht Einheit sieben. Hör mir zu: Du bist, wofür du dich hältst, solange du dich dafür hältst.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Das ist die unaufrichtigste Sache, die mir heute gesagt wurde.", "ziel": "unaufrichtig"},
					{"text": "(Die Akte einstecken und gehen)", "tut": {"notiz": "einheit7", "erfahrung": 50}},
				],
			},
			"unaufrichtig": {
				"sagt": [
					"„Ja.“",
					"„Es ist auch das Freundlichste. Entscheide dich, was du davon brauchst.“",
				],
				"antworten": [
					{"text": "(Gehen)", "tut": {"notiz": "einheit7", "erfahrung": 50}},
				],
			},
			"arbeit": {
				"sagt": [
					"„Die Viecher kommen aus den Rohren.“",   # vertont
					"„Solange die da unten sind, verarzte ich hier oben Bisse statt Wunden.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Wie viele?", "ziel": "wieviele"},
					{"text": "Ich kümmere mich drum.", "tut": {"quest": "q_ratten", "erfahrung": 15}},
					{"text": "(Gehen)"},
				],
			},
			"wieviele": {
				"sagt": [
					"„Zähl die Kadaver, nicht die Stunden.“",   # vertont
					"„Zwölf wären ein Anfang. Und halt dich von den Ratten fern, die nicht weglaufen — die sind krank, und das ist eine andere Krankheit.“",
				],
				"antworten": [
					{"text": "Abgemacht.", "tut": {"quest": "q_ratten", "erfahrung": 25}},
					{"text": "(Gehen)"},
				],
			},
		},
	},

	# ── Gideon Cross im Saloon ───────────────────────────────────────────────────
	# Er wirbt nicht, er rechnet vor. Vor Kapitel 5 gibt er nur Hintergrund; die
	# Gildenwahl selbst steht später in Fort Freedom.
	"gideon_saloon": {
		"person": "gideon",
		"start": "erst",
		"knoten": {
			"erst": {
				"sagt": [
					"„Ich frag dich nicht, woher du kommst. Ich frag dich, wozu du taugst.“",   # vertont
				],
				"sagt_enthuellt": [
					"„Sie haben dich gebaut, und jetzt stehst du hier.“",   # vertont
					"„Das ist die beste Nachricht seit zehn Jahren.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "person:gideon", "text": "Wer bist du?", "ziel": "wer"},
					{"sinnbild": "wissen", "text": "Was willst du vom Konzern?", "ziel": "konzern"},
					{"sinnbild": "person:held", "text": "Wozu ich taugen soll, weiß ich selbst noch nicht.", "ziel": "weiss_nicht"},
					{"sinnbild": "streit", "text": "Warum ist das eine gute Nachricht?", "ziel": "gute_nachricht", "nur_enthuellt": true},
					{"text": "(Gehen)"},
				],
			},
			"wer": {
				"sagt": [
					"„Gideon Cross. Ich halte Fort Freedom, zwei Tagesritte nordwestlich, mit hundertzwanzig Leuten, die nichts mehr zu verlieren haben.“",
					"„Der Konzern besitzt die Schienen, das Wasser und die Zeit. Wir nehmen ihm eins nach dem anderen ab.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Und wie weit seid ihr damit?", "ziel": "wie_weit"},
					{"sinnbild": "wissen", "text": "Was willst du vom Konzern?", "ziel": "konzern"},
					{"text": "(Gehen)", "tut": {"notiz": "gideon"}},
				],
			},
			"wie_weit": {
				"sagt": [
					"„Wir haben die Zeit. Die Uhr am Fort geht nach uns, nicht nach der Schichtsirene.“",
					"„Das klingt klein. Frag einen, der zehn Jahre nach ihrer Sirene aufgestanden ist, wie klein das ist.“",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Was willst du vom Konzern?", "ziel": "konzern"},
					{"text": "(Gehen)", "tut": {"notiz": "gideon"}},
				],
			},
			"konzern": {
				"sagt": [
					"„Wir brechen das Monopol des Konzerns — oder sterben beim Versuch.“",   # vertont
					"„Es gibt Arbeit, und sie ist nicht sauber.“",   # vertont
					"„Wer sauber bleiben will, geht zurück nach Rustwater und trinkt bei Mabel.“",   # vertont
				],
				"antworten": [
					{"sinnbild": "person:mabel", "text": "Ich sitze gerade in Rustwater und trinke bei Mabel.", "ziel": "spott"},
					{"sinnbild": "frage", "text": "Erzähl von der Arbeit.", "ziel": "arbeit"},
					{"text": "(Gehen)"},
				],
			},
			"spott": {
				"sagt": [
					"„Ordentlich.“",   # vertont
					"„Du bist der Erste seit Monaten, der zurückredet statt zu nicken. Das rechne ich dir an, auch wenn's nichts kostet.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Erzähl von der Arbeit.", "ziel": "arbeit"},
					{"text": "(Gehen)", "tut": {"erfahrung": 20}},
				],
			},
			"arbeit": {
				"sagt": [
					"„Noch nicht. Du bist noch keinen Tag hier und weißt nicht, wem du was schuldest.“",
					"„Erledige, was Mabel dir gibt. Wenn du danach noch stehst, reden wir am Fort weiter.“",
				],
				"antworten": [
					{"text": "(Gehen)", "tut": {"notiz": "gideon", "flagge": "gideon_offen"}},
				],
			},
			"weiss_nicht": {
				"sagt": [
					"„Das ist die ehrlichste Antwort, die ich diese Woche gehört habe.“",
					"„Dann find's raus, solange es noch eine Stadt gibt, in der man das rausfinden kann.“",
				],
				"antworten": [
					{"sinnbild": "person:gideon", "text": "Wer bist du?", "ziel": "wer"},
					{"text": "(Gehen)", "tut": {"erfahrung": 15}},
				],
			},
			"gute_nachricht": {
				"sagt": [
					"„Weil sie dich gebaut haben, um in Dinge reinzugehen, aus denen niemand rauskommt.“",
					"„Und weil du jetzt selber entscheidest, in welche. Das haben sie nicht eingeplant.“",
				],
				"antworten": [
					{"text": "(Gehen)", "tut": {"notiz": "gideon", "flagge": "gideon_offen", "erfahrung": 40}},
				],
			},
		},
	},

	# ── Quentin Vale auf der Piste ───────────────────────────────────────────────
	# Erste Begegnung mit dem Konzern, und sie ist nicht gewalttätig — sie ist höflich
	# und rechnet. Hilft man ihm, bekommt man Geld und später eine Tür in Sektor 01.
	"quentin_piste": {
		"person": "quentin",
		"start": "erst",
		"knoten": {
			"erst": {
				"sagt": [
					"„Sektor 01. Sie betreten Konzerngebiet. Das ist kein Vorwurf, das ist eine Feststellung.“",   # vertont
					"„Verzeihung. Gewohnheit. Hier ist kein Sektor, hier ist eine gebrochene Achse.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Kann ich helfen?", "ziel": "helfen"},
					{"sinnbild": "wissen", "text": "Was transportierst du?", "ziel": "ladung"},
					{"text": "(Vorbeigehen)"},
				],
			},
			"helfen": {
				"sagt": [
					"„Ordnung ist Profit. Profit ist Ordnung.“",   # vertont
					"„Übersetzt: Ja. Ich brauche einen schweren Schraubstock, um die Achse zu richten. Der Schmied in Rustwater hat einen, den er nicht festgeschraubt hat.“",
					"„Zwanzig Gold, wenn Sie ihn bringen. Vierzig, wenn Sie nicht fragen, warum ich nicht selbst gehe.“",
				],
				"antworten": [
					{"sinnbild": "ding:schraubstock", "text": "Vierzig.", "tut": {"quest": "q_achse", "erfahrung": 20, "flagge": "quentin_vierzig"}},
					{"sinnbild": "streit", "text": "Warum gehst du nicht selbst?", "ziel": "warum_nicht"},
					{"text": "(Vorbeigehen)"},
				],
			},
			"warum_nicht": {
				"sagt": [
					"„Weil in Rustwater ein Mann sitzt, der zwei Gründe hat, mich zu erschießen, und einer davon ist gut.“",
					"„Zwanzig Gold, wie gesagt.“",
				],
				"antworten": [
					{"text": "Abgemacht.", "tut": {"quest": "q_achse", "erfahrung": 20}},
					{"text": "(Vorbeigehen)"},
				],
			},
			"ladung": {
				"sagt": [
					"„Der Unterschied zwischen Raub und Requirierung ist ein Stempel. Wir haben den Stempel.“",   # vertont
					"„In den Kisten ist Dokumentation. Für Sie wertlos, für mich die Stelle.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Kann ich helfen?", "ziel": "helfen"},
					{"text": "(Vorbeigehen)", "tut": {"notiz": "konzern"}},
				],
			},
		},
	},

	# ── SCHLUSSSZENE KAPITEL 1 ───────────────────────────────────────────────────
	#
	# Hier laufen die drei Straenge zusammen, und zwar sichtbar: Mabel zahlt aus (Hauptstrang),
	# Dolores spielt die gerichtete Walze (Seitenstrang), und der Konzernkarren, den man auf
	# der Piste geflickt hat, haelt vor der Tuer (Seitenstrang). Wer nur einen der Straenge
	# gespielt haette, saesse hier vor einer Szene mit zwei Luecken -- deshalb sind alle drei
	# Pflicht, und deshalb steht diese Szene am Ende und nicht irgendwo dazwischen.
	#
	# Sprecher wechseln je Knoten (`wer`). Der Spieler waehlt wenig; eine Schlussszene ist
	# kein Raetsel, sie ist die Belohnung dafuer, dass die Raetsel vorbei sind.
	"schluss_k1": {
		"person": "mabel",
		"start": "zu",
		"knoten": {
			"zu": {
				"wer": "mabel",
				"sagt": [
					"„Feierabend. Raus mit euch — ausser dir.“",
					"„Setz dich. Heute zahlst du nichts.“",   # vertont
					"„Acht Tücher. Ich hab sie gezählt, zweimal, weil ich's nicht glauben wollte.“",
				],
				"antworten": [
					{"text": "Es war Arbeit. Mehr nicht.", "ziel": "arbeit", "sinnbild": "frage"},
					{"text": "Du hast mich reingelassen, ohne zu fragen.", "ziel": "gefragt", "sinnbild": "person:mabel"},
				],
			},
			"arbeit": {
				"wer": "gideon",
				"sagt": [
					"„Ordentlich.“",   # vertont
					"„Acht Mann auf der Südpiste, an einem Tag, allein. Ich hab zwölf Leute, die das zusammen nicht schaffen.“",
					"„Ich frag dich nicht, woher du kommst. Ich frag dich, wozu du taugst.“",   # vertont
				],
				"antworten": [
					{"text": "Das hast du schon mal gefragt.", "ziel": "nochmal", "sinnbild": "person:gideon"},
					{"text": "Das weiß ich immer noch nicht.", "ziel": "nochmal", "sinnbild": "frage"},
				],
			},
			"gefragt": {
				"wer": "mabel",
				"sagt": [
					"„Wer aus dem Schrott kommt, hat meistens keinen mehr.“",
					"„Ich hab vor zwanzig Jahren auch keinen gehabt. Jemand hat mich trotzdem reingelassen. Das ist die ganze Erklärung.“",
				],
				"antworten": [
					{"text": "(Nichts sagen)", "ziel": "arbeit", "sinnbild": "frage"},
				],
			},
			"nochmal": {
				"wer": "gideon",
				"sagt": [
					"„Dann find's raus. Fort Freedom, zwei Tagesritte nordwestlich. Wenn du kommst, kommst du.“",
				],
				"antworten": [
					{"text": "(Dolores legt die Walze ein)", "ziel": "walze", "sinnbild": "ding:walze"},
				],
			},
			"walze": {
				"wer": "dolores",
				"sagt": [
					"„Silas hat die Stifte gesetzt. Zweiundfünfzig Stück, und er hat keinen Lohn genommen.“",
					"„Das ist das Lied. Hört es euch an und redet nicht dazwischen.“",
					"(Die Drehorgel spielt. Es ist eine einfache Melodie, und sie ist länger, als man erwartet. Im Saloon sagt niemand etwas. Mabel wischt ein Glas, das trocken ist.)",
				],
				"antworten": [
					{"text": "(Zuhören)", "ziel": "karren", "sinnbild": "frage",
					 "tut": {"flagge": "k1_lied_gehoert", "erfahrung": 60}},
				],
			},
			"karren": {
				"wer": "held",
				"sagt": [
					"Draußen hält ein Karren. Eine gebrochene Achse, die jemand gerichtet hat, und ich weiß, wer sie gerichtet hat, weil ich es war.",
					"Quentin Vale steigt nicht aus. Er sitzt da und sieht auf die Saloontür, als zähle er, wie viele Leute drin sind.",
					"Dann fährt er weiter, nach Norden, und der Karren ist leer. Er war nicht leer, als ich ihn geflickt habe.",
				],
				"antworten": [
					{"text": "(Hinterhersehen)", "ziel": "ende", "sinnbild": "wissen",
					 "tut": {"notiz": "konzern", "flagge": "k1_karren_gesehen"}},
				],
			},
			"ende": {
				"wer": "mabel",
				"sagt": [
					"„Lass ihn fahren. Was der holt, holt er morgen wieder.“",
					"„Schlaf oben. Die Tür klemmt, aber sie hält.“",
				],
				"antworten": [
					{"text": "(Schlafen gehen)", "tut": {"flagge": "kapitel_1_fertig", "erfahrung": 200}},
				],
			},
		},
	},

	# (Dolores' Knoten zur Zeichnung stehen in ihrem Baum weiter unten.)

	# ── SCHLUSSSZENE KAPITEL 2 ───────────────────────────────────────────────────
	#
	# "Zaehe Konstitution" (Story-Bibel, Kinoszene 2.2). Doc flickt einen Riss, der nicht
	# blutet, und redet dabei schneller als noetig. Er sagt die Wahrheit nicht -- aber er
	# sagt sie fast, dreimal, und bricht jedes Mal ab.
	#
	# Diese Szene ist die Haelfte der Vorbereitung auf Kapitel 4. Die andere Haelfte war
	# die Bahre mit den von innen durchgewetzten Riemen; wer beides gesehen hat, ist beim
	# Spiegel im Zugwaggon nicht ueberrascht, sondern bestaetigt -- und das ist der
	# staerkere der beiden Schrecken.
	"schluss_k2": {
		"person": "doc",
		"start": "naht",
		"knoten": {
			"naht": {
				"wer": "doc",
				"sagt": [
					"„Halt still. Das zieht jetzt.“",
					"„…“",
					"„Du blutest nicht. Ein Riss von dieser Länge, quer durch den Unterarm, und es kommt nichts.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Ist das schlecht?", "ziel": "schlecht"},
					{"sinnbild": "person:held", "text": "Du wunderst dich nicht.", "ziel": "wundert"},
				],
			},
			"schlecht": {
				"wer": "doc",
				"sagt": [
					"„Das ist — nein. Nein, das ist gut. Wer nicht blutet, verblutet nicht.“",
					"„Zähe Konstitution. Kommt vor. Höhenluft, trockenes Klima, die Leber tut was dazu.“",
					"„Das ist Unsinn, was ich da sage. Ich höre es selbst.“",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Du wunderst dich nicht.", "ziel": "wundert"},
					{"sinnbild": "streit", "text": "Dann sag etwas, das kein Unsinn ist.", "ziel": "kein_unsinn"},
				],
			},
			"wundert": {
				"wer": "doc",
				"sagt": [
					"„Ich bin Feldscher in einer Stadt, in der die Leute an Maschinen sterben. Ich wundere mich seit elf Jahren nicht mehr.“",
					"(Er setzt die Nadel neu an. Seine Hände sind vollkommen ruhig, und das ist der Grund, warum mir auffällt, dass seine Stimme es nicht ist.)",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Dann sag etwas, das kein Unsinn ist.", "ziel": "kein_unsinn"},
					{"sinnbild": "wissen", "text": "Die Riemen an deiner Bahre sind von innen durchgewetzt.",
					 "ziel": "riemen", "wenn": "bahre_gesehen"},
				],
			},
			"kein_unsinn": {
				"wer": "doc",
				"sagt": [
					"„Gut.“",
					"„Es gibt Dinge, die man einem Mann über sich selbst sagen kann, und es gibt Dinge, die er selbst finden muss. Der Unterschied ist nicht, wie wahr sie sind. Der Unterschied ist, was danach von ihm übrig ist.“",
					"„Fertig. Acht Stiche. Die hättest du auch ohne mich überstanden, und das ist die beunruhigendste Zeile in deiner Akte.“",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "In meiner Akte.", "ziel": "akte_doc"},
					{"sinnbild": "weg", "text": "(Den Arm nehmen und gehen)", "ziel": "ende"},
				],
			},
			"riemen": {
				"wer": "doc",
				"sagt": [
					"„…“",
					"„Ja.“",
					"„Und du fragst mich das, während ich eine Nadel in deinem Arm habe. Das sagt mehr über dich als über die Riemen.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Wer lag darauf?", "ziel": "wer_lag"},
					{"sinnbild": "weg", "text": "(Nicht weiter fragen)", "ziel": "ende"},
				],
			},
			"wer_lag": {
				"wer": "doc",
				"sagt": [
					"„Frag mich das nochmal, wenn du es aushältst. Heute hältst du es nicht aus, und ich auch nicht.“",
					"„Geh schlafen. Morgen kommt der Nachtzug, und die halbe Stadt will mit.“",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "(Gehen)", "ziel": "ende",
					 "tut": {"notiz": "doc_luegt", "erfahrung": 60}},
				],
			},
			"akte_doc": {
				"wer": "doc",
				"sagt": [
					"„Jeder, den ich flicke, bekommt eine. Papier ist billiger als Erinnerung.“",
					"„Deine ist dünn. Drei Wochen, und davor nichts. Für einen Mann in deinem Alter ist das keine Akte, das ist ein Anfang.“",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "(Den Arm nehmen und gehen)", "ziel": "ende",
					 "tut": {"notiz": "einheit7", "erfahrung": 80}},
				],
			},
			"ende": {
				"wer": "held",
				"sagt": [
					"Draußen ist es Nacht geworden. Die Esse bei Silas glüht noch, der Vorschacht steht offen, und irgendwo unter der Stadt singt etwas weiter, dem niemand das Singen beigebracht hat.",
					"Acht Stiche. Sie haben nicht wehgetan.",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "(Schlafen gehen)",
					 "tut": {"flagge": "kapitel_2_fertig", "erfahrung": 250}},
				],
			},
		},
	},

	# ── SCHLUSSSZENE KAPITEL 3 ───────────────────────────────────────────────────
	#
	# "Kupferauge" (Story-Bibel, Kinoszene 3.2). Silas legt die Rolle unter seine Linse
	# und rät dem Helden, sie in den tiefsten Schacht zu werfen. Dann nennt er trotzdem
	# den Zug -- weil er weiß, dass der Rat nicht angenommen wird, und weil er lieber
	# will, dass der Junge vorbereitet geht als blind.
	"schluss_k3": {
		"person": "silas",
		"start": "linse",
		"knoten": {
			"linse": {
				"wer": "silas",
				"sagt": [
					"(Er klemmt die Rolle unter die Kupferlinse. Das mechanische Auge surrt, Blende auf, Blende zu. Zweimal.)",
					"„Konzernwachs. Direktoratssiegel. Und eine Chiffre, die meine Linse zum Weinen bringt.“",
					"(Er legt die Rolle hin. Langsam, wie etwas Totes.)",
					"„Junge, ich sag dir das als Freund: Wirf das Ding in den tiefsten Schacht und vergiss den Weg dahin.“",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Da stand meine Zahl drauf, Silas.", "ziel": "meine_zahl"},
					{"sinnbild": "frage", "text": "Was hast du gesehen?", "ziel": "gesehen"},
				],
			},
			"gesehen": {
				"wer": "silas",
				"sagt": [
					"„Genug, um dir zu raten, nicht zu fragen. Und zu wenig, um dich davon abzuhalten.“",
					"„Es ist ein Verzeichnis. Namen tut der Konzern nicht in Wachs. Nummern schon.“",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "Da stand meine Zahl drauf, Silas.", "ziel": "meine_zahl"},
				],
			},
			"meine_zahl": {
				"wer": "held",
				"sagt": [
					"Frag mich nicht, woher ich das weiß. Ich weiß es einfach.",
					"(Lange Pause. Die Kupferlinse fixiert mich. Das Menschenauge weicht aus.)",
				],
				"antworten": [
					{"sinnbild": "person:silas", "text": "(Warten, bis er etwas sagt)", "ziel": "zug"},
				],
			},
			"zug": {
				"wer": "silas",
				"sagt": [
					"„… Es gibt einen Zug.“",
					"„Jeden Monat, Richtung Norden, Waggons versiegelt wie Särge. PSALM-Fracht.“",
					"„Was immer der Konzern dir genommen hat — wenn es Antworten gibt, fahren sie erster Klasse.“",
					"(Er nimmt den Hammer wieder auf.)",
					"„Aber Züge überfällt man nicht, Junge. Züge überlebt man. Höchstens.“",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Dann werd ich überleben. Das kann ich anscheinend gut.",
					 "ziel": "ende"},
					{"sinnbild": "streit", "text": "Du hättest mir den Zug nicht sagen müssen.", "ziel": "haette_nicht"},
				],
			},
			"haette_nicht": {
				"wer": "silas",
				"sagt": [
					"„Nein.“",
					"„Du wärst trotzdem gegangen. Nur eben nach Norden, ohne zu wissen wohin, und zwei Wochen später hätte mir jemand erzählt, dass sie dich irgendwo gefunden haben.“",
					"„Ich kann dich nicht aufhalten. Ich kann dafür sorgen, dass du nicht dumm stirbst. Das ist der ganze Unterschied, den ein alter Mann noch machen kann.“",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Dann werd ich überleben. Das kann ich anscheinend gut.",
					 "ziel": "ende", "tut": {"erfahrung": 80}},
				],
			},
			"ende": {
				"wer": "silas",
				"sagt": [
					"„Das Depot liegt nördlich, am Abzweig vor der Piste. Heute nacht fährt er.“",
					"(Er sieht mich nicht an, als er es sagt, und er schlägt beim Reden weiter auf das Eisen.)",
					"„Und Junge — nimm die Lampe mit. Nicht für den Zug. Für danach.“",
				],
				"antworten": [
					{"sinnbild": "ort:zugdepot", "text": "(Zum Depot aufbrechen)",
					 "tut": {"flaggen": ["zug_bekannt", "kapitel_3_fertig"], "quest": "q_zug",
						 "notiz": "zug", "erfahrung": 300}},
				],
			},
		},
	},

	# ── SCHLUSSSZENE KAPITEL 4 — DER SPIEGEL ─────────────────────────────────────
	#
	# Die wichtigste Szene des Spiels. Sie ist mit Absicht die Szene mit den WENIGSTEN
	# Wahlmoeglichkeiten: An drei Stellen entscheidet der Spieler etwas, und zwei davon
	# aendern nichts am Ausgang. Das ist kein Mangel an Spiel, das ist die Form -- es
	# gibt hier nichts zu entscheiden, es gibt nur etwas zu begreifen.
	#
	# Technisch passieren hier zwei Dinge, die sonst nirgends passieren: `enthuellen`
	# setzt `GameState.is_revealed`, und `spiegel_zerbrochen` tauscht den Hintergrund.
	# Beides haengt an genau einer Antwort, naemlich an der, bei der die Ramme trifft.
	"schluss_k4": {
		"person": "jack",
		"start": "jack",
		"knoten": {
			"jack": {
				"wer": "jack",
				"sagt": [
					"(Die Schiebetür fliegt auf. Regen und Fahrtwind reißen herein, und im Türrahmen steht zwei Meter Vorarbeiter in Konzerngrau. Wo der rechte Arm sein sollte, zischt eine dampfgetriebene Ramme Überdruck ab.)",
					"„Ich hab Männer unter Räder fallen sehen und Räder auf Männer!“",
					"„Aber du bist der Erste, der FREIWILLIG auf meinen Zug steigt!“",
					"(Die Ramme schnellt einmal vor. WHAM. Der ganze Wagen bebt, und die Karaffen im Gestell singen.)",
				],
				"antworten": [
					{"sinnbild": "ding:psalm_rolle", "text": "Ich will nur einen Waggon. Den mit der Dreizehn.",
					 "ziel": "erkennt"},
					{"sinnbild": "streit", "text": "Geh mir aus dem Weg.", "ziel": "weg_da"},
				],
			},
			"weg_da": {
				"wer": "jack",
				"sagt": [
					"„Aus dem Weg!“",
					"(Er lacht, und das Lachen ist echt.)",
					"„Weißt du, wie viele mir das gesagt haben? Zwei. Beide liegen unter Kilometer vierzig.“",
					"„Nun sag schon. Was willst du auf meinem Zug?“",
				],
				"antworten": [
					{"sinnbild": "ding:psalm_rolle", "text": "Ich will nur einen Waggon. Den mit der Dreizehn.",
					 "ziel": "erkennt"},
				],
			},
			"erkennt": {
				"wer": "jack",
				"sagt": [
					"(Er erstarrt. Zum ersten Mal weicht das Grinsen.)",
					"(Er kneift die Augen zusammen, tritt einen halben Schritt näher und mustert mein Gesicht im Blitzlicht. Und darin flackert etwas, das wie Erkennen aussieht und wie Aberglaube.)",
					"„… Nein. Neinneinnein. Dich ham sie doch abgeschrieben.“",
					"„Dich ham sie in die Wüste —“",
					"(Er reißt die Ramme hoch. Plötzlich ist Angst in seiner Stimme, und Angst macht ihn laut.)",
					"„EINHEIT—“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Sprich es aus.", "ziel": "ramme"},
					{"sinnbild": "person:held", "text": "Woher kennst du mich?", "ziel": "ramme"},
				],
			},
			"ramme": {
				"wer": "jack",
				"sagt": [
					"(Er spricht es nicht zu Ende.)",
					"(Er zündet den Notdruck. Die Ramme fährt mit dem Kreischen von tausend Kesseln aus und trifft mich voll in die Brust.)",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "…", "ziel": "spiegel",
					 "tut": {"flagge": "spiegel_zerbrochen", "enthuellen": true, "erfahrung": 500}},
				],
			},
			"spiegel": {
				"wer": "held",
				"sagt": [
					"(Ich durchschlage die Wand des Salonwaggons. Holz splittert, der Kartentisch zerbirst, die Kristallgläser hängen im Licht wie gefrorener Regen.)",
					"(Ich schlittere über das Parkett auf die gegenüberliegende Wand zu. Alles verstummt bis auf ein einzelnes, sauberes mechanisches Ticken, das immer lauter wird.)",
					"(Es ist meins.)",
					"(Der Spiegel zerbricht sternförmig, genau vor meinem Gesicht. Ich liege in den Scherben. Ich hebe den Kopf.)",
					"(Und sehe.)",
				],
				"antworten": [
					{"sinnbild": "wissen", "text": "(Hinsehen)", "ziel": "scherben"},
				],
			},
			"scherben": {
				"wer": "held",
				"sagt": [
					"In einer Scherbe ein Auge, das keins ist: eine glühende Okular-Iris.",
					"In der nächsten Zähne. Nein — verzahnter Stahl.",
					"In der dritten Rauch, der aus einem Kiefergelenk sickert.",
					"Die Haut flackert wie eine schlecht projizierte Kinetoskop-Aufnahme. Darunter ein rauchender, einäugiger Stahlschädel. Zahnräder drehen sich dort, wo ein Kiefer kauen sollte. Öl kocht in den Nähten wie schwarzes Blut.",
					"Ich bin keine Kreatur aus Fleisch. Ich bin eine Maschine.",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "Nein. Ich hab doch geblutet.", "ziel": "getraeumt"},
					{"sinnbild": "streit", "text": "(Die Hand vor das Auge halten)", "ziel": "getraeumt"},
				],
			},
			"getraeumt": {
				"wer": "held",
				"sagt": [
					"(Ich hebe die Hand vor das eine glühende Auge. Die Hand flackert: Haut — Stahl — Haut — Stahl — Stahl.)",
					"Nein. Nein, ich — ich hab doch geblutet. Ich hab doch …",
					"(Ich berühre meine Wange. Es klirrt leise.)",
					"… ich hab doch geträumt.",
					"(Stille. Dann lache ich. Ein kurzes, kaputtes Lachen, halb Schluchzen, halb Ventil, das Druck ablässt.)",
					"Wer hat mir mein Gesicht geschuldet … und mit einer Lüge bezahlt?",
				],
				"antworten": [
					{"sinnbild": "person:jack", "text": "(Hinter mir bricht jemand durch die Wand)", "ziel": "jack_zuletzt"},
				],
			},
			"jack_zuletzt": {
				"wer": "jack",
				"sagt": [
					"(Er hinkt. Die Ramme ist leckgeschlagen und zischt im Takt seiner Schritte.)",
					"„Na. Jetzt weißte's.“",
					"(Er spuckt Blut.)",
					"„Weißte was? Ich fahr seit zwanzig Jahren für den Konzern. Und du bist trotzdem der menschlichste Hurensohn, der je auf meinen Zug —“",
				],
				"antworten": [
					{"sinnbild": "person:held", "text": "(Aufstehen)", "ziel": "ende"},
				],
			},
			"ende": {
				"wer": "held",
				"sagt": [
					"(Ich erhebe mich. Zum ersten Mal in voller Silhouette, Rauch aus den Schulterventilen, das eine Auge eine ruhige, orange Glut.)",
					"(Meine Stimme bricht mitten im Satz von menschlich zu einem doppelten Timbre. Darunter liegt jetzt ein metallischer Resonanzraum.)",
					"Runter von meinem Zug.",
				],
				"antworten": [
					{"sinnbild": "weg", "text": "(Den Zug nehmen)",
					 "tut": {"flagge": "kapitel_4_fertig", "erfahrung": 800}},
				],
			},
		},
	},

	# ── Dolores am Brunnen ───────────────────────────────────────────────────────
	# Nebenbogen B7. Sie ist blind und erkennt den Helden am Gang — der erste Hinweis
	# überhaupt, und er kommt von jemandem, dem niemand zuhört.
	"dolores_platz": {
		"person": "dolores",
		"start": "erst",
		"knoten": {
			"erst": {
				"sagt": [
					"„Steh still, Junge. Ich hör dich falsch.“",
					"„Jeder Mensch setzt den zweiten Schritt schwerer als den ersten, weil er müde wird. Du nicht. Du setzt zwölf gleiche Schritte und dann nochmal zwölf.“",
				],
				"antworten": [
					{"sinnbild": "person:dolores", "text": "Du bist blind.", "ziel": "blind"},
					{"sinnbild": "ding:walze", "text": "Was spielst du da?", "ziel": "walze"},
					{"text": "(Gehen)"},
				],
			},
			"blind": {
				"sagt": [
					"„Seit vierzehn Jahren. Der Konzern nennt es einen Arbeitsunfall, ich nenn's einen Kesselriss, und beide haben recht.“",
					"„Seitdem hör ich, und Hören lügt weniger als Sehen. Deine Schritte sind die eines Uhrwerks, das Stiefel trägt.“",
				],
				"antworten": [
					{"sinnbild": "streit", "text": "Das ist ein harter Satz.", "ziel": "hart"},
					{"sinnbild": "ding:walze", "text": "Was spielst du da?", "ziel": "walze"},
					{"text": "(Gehen)", "tut": {"notiz": "naht"}},
				],
			},
			"hart": {
				"sagt": [
					"„Ich hab nicht gesagt, dass es was Schlechtes ist.“",
					"„Ein Uhrwerk hält durch, wenn alle anderen umfallen. Diese Stadt braucht was, das durchhält.“",
				],
				"antworten": [
					{"sinnbild": "ding:walze", "text": "Was spielst du da?", "ziel": "walze"},
					{"text": "(Gehen)", "tut": {"notiz": "naht", "erfahrung": 20}},
				],
			},
			"zeichnung_frage": {
				"sagt": [
					"„Auf der zweiten Ebene. Links, an der dritten Stütze von der Weiche.“",
					"„Du brauchst mir nicht zu sagen, was drauf ist. Ich weiß, was drauf ist. Ich hab dem Jungen die Kohle gegeben.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Wer war das Kind?", "ziel": "wer_kind"},
					{"sinnbild": "streit", "text": "Der Vater auf dem Bild ist kein Mensch.", "ziel": "kein_mensch"},
				],
			},
			"wer_kind": {
				"sagt": [
					"„Mein Enkel.“",
					"„Seine Mutter hat gesungen, bis sie nicht mehr konnte, und danach hat er gesungen, bis sie ihn auch geholt haben. Das war vor elf Jahren.“",
					"„Wenn du nochmal runtergehst: Im Hunt neben der Stütze liegt seine Jacke. Ich hab sie zweimal geflickt und nie wiedergesehen.“",
				],
				"antworten": [
					{"sinnbild": "ding:kinderjacke", "text": "Ich hole sie dir.",
					 "tut": {"quest": "q_jacke", "erfahrung": 80}},
					{"sinnbild": "weg", "text": "(Nichts sagen)", "tut": {"quest": "q_jacke"}},
				],
			},
			"kein_mensch": {
				"sagt": [
					"„Nein.“",
					"„Ein Kind malt, was es sieht, Junge. Es malt nicht, was wahr ist, und es malt nicht, was es glauben soll. Es malt, was dasteht.“",
					"(Sie dreht den Kopf ein Stück in meine Richtung, und ihre Augen gehen dabei an mir vorbei wie immer.)",
					"„Und du stehst hier und fragst mich danach.“",
				],
				"antworten": [
					{"sinnbild": "frage", "text": "Wer war das Kind?", "ziel": "wer_kind",
					 "tut": {"notiz": "naht", "erfahrung": 100}},
				],
			},
			"walze": {
				"sagt": [
					"„Drei Walzen. Zwei kann ich, die dritte ist gesprungen und keiner hier kann Stifte setzen.“",
					"„Auf der dritten ist ein Lied, das meine Tochter gesungen hat. Ich weiß die Melodie noch, aber meine Finger wissen sie nicht mehr.“",
				],
				"antworten": [
					{"sinnbild": "person:silas", "text": "Ich frag Silas, ob er Stifte setzen kann.", "tut": {"quest": "q_walze", "erfahrung": 20}},
					{"sinnbild": "wissen", "text": "Unten in der Mine hat ein Kind seine Familie an die Stütze gemalt.",
					 "ziel": "zeichnung_frage", "wenn": "zeichnung_gesehen"},
					{"text": "(Gehen)"},
				],
			},
		},
	},
}


## Ein Baum oder ein leeres Dictionary.
static func baum(kennung: String) -> Dictionary:
	return BAEUME.get(kennung, {}) as Dictionary


static func alle() -> Array:
	return BAEUME.keys()


## Die Person, deren Portrait und Stimme fuer den ganzen Baum gilt.
static func person(kennung: String) -> String:
	return str(baum(kennung).get("person", ""))


## Wer in DIESEM Knoten spricht.
##
## Die meisten Gespraeche haben einen Gegenueber, und dann steht die Person oben am Baum. Eine
## Schlussszene hat mehrere -- Mabel sagt etwas, Gideon antwortet, Dolores spielt dazu. Ohne
## einen Sprecher je Knoten muesste man dafuer drei Baeume aneinanderhaengen und bei jedem
## Wechsel das Gespraech schliessen und wieder oeffnen, was auf dem Schirm sichtbar waere.
static func person_im_knoten(baum_kennung: String, knoten_kennung: String) -> String:
	var k: Dictionary = knoten(baum_kennung, knoten_kennung)
	if k.has("wer"):
		return str(k["wer"])
	return person(baum_kennung)


## Ein Knoten eines Baums.
static func knoten(baum_kennung: String, knoten_kennung: String) -> Dictionary:
	return (baum(baum_kennung).get("knoten", {}) as Dictionary).get(knoten_kennung, {}) as Dictionary


## Was die Figur in diesem Knoten sagt — vor oder nach dem Reveal.
static func saetze(baum_kennung: String, knoten_kennung: String, enthuellt: bool) -> Array:
	var k: Dictionary = knoten(baum_kennung, knoten_kennung)
	if enthuellt and k.has("sagt_enthuellt"):
		return k["sagt_enthuellt"] as Array
	return k.get("sagt", []) as Array


## Die Antworten, die unter den gegebenen Bedingungen wählbar sind — in Tabellen-Reihenfolge,
## damit die Nummern stabil bleiben, solange sich die Bedingungen nicht ändern.
##
## `flagge_gesetzt` und `im_beutel` kommen von außen, weil der Weltzustand nicht hier liegt.
static func antworten(baum_kennung: String, knoten_kennung: String, enthuellt: bool,
		flagge_gesetzt: Callable = Callable(), im_beutel: Callable = Callable()) -> Array:
	var raus: Array = []
	for a in knoten(baum_kennung, knoten_kennung).get("antworten", []) as Array:
		var ant: Dictionary = a as Dictionary
		if bool(ant.get("nur_enthuellt", false)) and not enthuellt:
			continue
		if bool(ant.get("nur_verhuellt", false)) and enthuellt:
			continue
		if ant.has("wenn") and flagge_gesetzt.is_valid() \
				and not bool(flagge_gesetzt.call(str(ant["wenn"]))):
			continue
		if ant.has("nicht") and flagge_gesetzt.is_valid() \
				and bool(flagge_gesetzt.call(str(ant["nicht"]))):
			continue
		if ant.has("hat") and im_beutel.is_valid() \
				and not bool(im_beutel.call(str(ant["hat"]))):
			continue
		raus.append(ant)
	return raus


## Kommt man aus diesem Knoten wieder heraus?
##
## Heraus heißt: Es gibt mindestens eine Antwort, die das Gespräch beendet (kein `ziel`) oder
## auf einen anderen Knoten führt. Eine Antwort, die auf den eigenen Knoten zeigt, zählt nicht —
## sie dreht sich im Kreis. Bedingungen zählen hier nicht mit: Geprüft wird der Bauplan, nicht
## der Spielstand, denn ein Knoten, dessen einziger Ausweg an einer Flagge hängt, ist auch dann
## eine Falle, wenn die Flagge meistens gesetzt ist.
static func hat_ausweg(baum_kennung: String, knoten_kennung: String) -> bool:
	var liste: Array = knoten(baum_kennung, knoten_kennung).get("antworten", []) as Array
	if liste.is_empty():
		return false
	for a in liste:
		var ant: Dictionary = a as Dictionary
		if not ant.has("ziel"):
			return true   # beendet das Gespräch
		if str(ant["ziel"]) != knoten_kennung:
			return true
	return false
