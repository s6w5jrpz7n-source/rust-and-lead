class_name Gedraenge
## Körper, die sich nicht durchdringen — und sonst nichts.
##
## ## Was das hier ausdrücklich NICHT ist
##
## Es ist **kein Schwarmverhalten**. Die übliche Lösung für „Gegner laufen ineinander" ist eine
## Trennkraft, die jeden Nachbarn in einem Umkreis abstößt — und die erzeugt genau das, was hier
## nicht sein soll: Gegner, die *Abstand halten*. Ein Rudel, das sich brav auf zwei Meter
## verteilt, sieht aus wie eine Schulklasse beim Aufstellen, nicht wie etwas, das einen jagt.
##
## Hier wirkt nur **echte Kollision**: Zwei Körper werden auseinandergeschoben, wenn sie sich
## tatsächlich überlappen, und keinen Millimeter früher. Wer sich nicht berührt, wird nicht
## angefasst. Sie dürfen Schulter an Schulter stehen — sie dürfen nur nicht ineinander stehen.
##
## ## Wie es rechnet
##
## Für jedes Paar: Liegt der Abstand unter der Summe der Radien, wird die Überlappung **je zur
## Hälfte** auf beide verteilt. Das ist die einfachste Auflösung, die symmetrisch ist — schiebt
## man nur einen, drängelt sich der andere immer durch, und wer zuerst in der Liste steht,
## gewinnt jedes Gerangel.
##
## Mehrere Durchgänge, weil ein Schub eine neue Überlappung erzeugen kann: In einem Gang mit
## drei Kläffern hintereinander löst der erste Durchgang das vordere Paar und drückt den
## mittleren in den hinteren. Zwei bis drei Durchgänge reichen; danach ist der Rest kleiner als
## das, was man sieht.
##
## ## Warum es hier steht und nicht in den Szenen
##
## Es gibt zwei davon, und ein Gegner, der drinnen aneinanderstößt und draußen nicht, ist
## zweimal dieselbe Regel mit zwei Antworten. Und weil hier nur Zahlen stehen, kann der Test
## Gedränge bauen, die im Spiel selten vorkommen — zwölf Körper auf einem Fleck etwa — und
## nachrechnen, dass am Ende keiner mehr im anderen steckt.

## Wie oft nachgeschoben wird. Drei Durchgänge lösen auch eine Kette in einem engen Gang;
## mehr kostet Rechenzeit für einen Unterschied, den niemand sieht.
const DURCHGAENGE: int = 3

## Ab welcher Überlappung überhaupt geschoben wird (Meter).
##
## Ohne diese Schwelle zittern zwei Körper, die sich exakt berühren, um Rundungsfehler herum —
## und ein Gegner, der auf der Stelle vibriert, sieht kaputter aus als einer, der klemmt.
const SPIEL_M: float = 0.02


## Überlappungen auflösen.
##
## `punkte` sind die Standorte in der Ebene (x/z der Szene), `radien` die Körperradien dazu.
## Zurück kommen die **korrigierten** Standorte in derselben Reihenfolge.
##
## Wer sich nicht überlappt, kommt unverändert zurück — das ist die Zusicherung, an der der
## ganze Ansatz hängt.
static func entflechten(punkte: Array, radien: Array) -> Array:
	var raus: Array = punkte.duplicate()
	if raus.size() < 2:
		return raus
	for _runde in DURCHGAENGE:
		var ruhig: bool = true
		for i in raus.size():
			for j in range(i + 1, raus.size()):
				var a: Vector2 = raus[i]
				var b: Vector2 = raus[j]
				var soll: float = float(radien[i]) + float(radien[j])
				var weg: Vector2 = b - a
				var d: float = weg.length()
				if d >= soll - SPIEL_M:
					continue
				# Genau übereinander? Dann gibt es keine Richtung, in die man schieben könnte.
				# Ohne diesen Fall käme eine Division durch null heraus, und beide blieben für
				# immer ineinander stehen.
				var richtung: Vector2 = weg / d if d > 0.0001 \
					else Vector2(cos(float(i) * 2.399963), sin(float(i) * 2.399963))
				var haelfte: float = (soll - d) * 0.5
				raus[i] = a - richtung * haelfte
				raus[j] = b + richtung * haelfte
				ruhig = false
		if ruhig:
			break
	return raus


## Der Körperradius eines Gegnertyps.
##
## Abgeleitet aus seiner **Höhe** und nicht aus einer zweiten Tabelle: Ein Konstrukt ist doppelt
## so hoch wie eine Ratte und nimmt auch mehr Platz weg. Eine eigene Radienliste wäre eine
## zweite Wahrheit über dieselbe Sache und würde beim ersten neuen Gegner vergessen.
##
## Der Faktor ist knapp: 0,26 der Höhe. Ein 1,6-m-Grenzgänger bekommt damit 42 cm, ein Rudel
## steht also fast Schulter an Schulter. Das ist Absicht — verlangt war Kollision, kein Abstand.
const RADIUS_ANTEIL: float = 0.26
## Nach unten begrenzt, damit ein Schwarm Ratten nicht doch wieder ineinander verschwindet.
const RADIUS_MIN: float = 0.25


static func radius_fuer(type_id: String) -> float:
	var asset: String = AssetRegistry.enemy_asset(type_id)
	return maxf(RADIUS_MIN, AssetRegistry.height_of(asset) * RADIUS_ANTEIL)
