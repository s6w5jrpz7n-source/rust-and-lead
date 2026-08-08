class_name ChestData
## Zwei Arten von Truhen — die gewöhnliche und die, für die man gekämpft hat.
##
## ## Warum das eine eigene Tabelle ist
##
## Truhen stehen an zwei völlig verschiedenen Orten: draußen an jedem Ort der Karte, drinnen in
## den Kammern des Stollens. Beide Stellen füllten sie vorher mit **eigenen Zahlen** — die
## Oberwelt würfelte 18–45 Gold, der Stollen rechnete `18 + Ebene · 22`. Solange es eine Sorte
## Truhe gab, fiel das nicht auf. Mit zwei Sorten wären es vier Zahlenreihen an zwei Orten
## gewesen, und beim ersten „die Bosstruhe gibt zu wenig" hätte man raten müssen, welche davon
## gemeint ist.
##
## Also: **Was eine Truhe hergibt, steht hier.** Wo sie steht und wie man sie öffnet, bleibt
## Sache der jeweiligen Szene.
##
## ## Der Unterschied ist kein Multiplikator
##
## Eine Bosstruhe ist nicht „dieselbe Truhe mal drei". Sie unterscheidet sich in dem, was man
## **erwartet**:
##
## * Sie **garantiert** ein Mindestmaß an Seltenheit. Eine gewöhnliche Truhe darf leer ausgehen
##   — das ist der Grund, warum man sich über eine gute freut. Eine Truhe hinter einem Boss darf
##   das *nicht*: Wer einen Kampf übersteht und dann Hausmüll findet, lernt, dass Bosskämpfe
##   sich nicht lohnen.
## * Sie gibt **immer** einen Trank. Nach einem Boss ist man angeschlagen.
## * Sie sieht **anders aus**, und zwar von weitem. Eine Belohnung, die man erst am Inhalt
##   erkennt, ist im Augenblick des Findens keine.
const STANDARD: String = "standard"
const BOSS: String = "boss"

## Was jede Art hergibt.
##
## `modell` ist der Registry-Name. Liegt die Datei nicht im Projekt, zeichnet die Szene ihren
## Platzhalter — deshalb kann der Eintrag hier stehen, bevor es das Modell gibt.
const ARTEN: Dictionary = {
	STANDARD: {
		"name": "Truhe",
		"modell": "chest",
		"gold": [18, 45],
		"stuecke": [1, 3],
		"bias": 0.3,              # etwas ueber Gegner-Beute, damit Truhen sich lohnen
		"min_seltenheit": "",     # nichts garantiert — eine Niete gehoert dazu
		"trank": 0.5,
		"muni_mul": 3,
		"hoehe": 0.7,
		"schluessel": 0,
		# Sieben gewoehnliche Kisten stehen im Stollen; bei drei Stueck im schlechtesten Fall sind
		# das 21 — genug fuer die 20 des Auftrags, OHNE dass man dafuer die Beutekammer aufbekommen
		# muss. Mit [2,4] traf der schlechteste Fall exakt 20, und damit haette ein einziger
		# uebersehener Kasten einen zweiten Abstieg erzwungen.
		"stahl": [3, 5],
	},
	BOSS: {
		"name": "Beutekammer",
		"modell": "chest_boss",
		"gold": [95, 170],
		"stuecke": [2, 4],
		"bias": 1.1,
		"min_seltenheit": "rare", # garantiert, siehe oben
		"trank": 1.0,
		"muni_mul": 7,
		"hoehe": 0.95,
		# Drei Schlüssel, und die gibt es nur bei Anführern. Die beste Truhe im Spiel steht damit
		# sichtbar da und lässt sich trotzdem nicht einfach einsammeln: Man muss dreimal einen
		# Kampf suchen, den man umgehen könnte.
		"schluessel": 3,
		"stahl": [6, 10],
	},
}


static func art(id: String) -> Dictionary:
	return ARTEN.get(id, ARTEN[STANDARD])


## Wie viel Gold diese Truhe hergibt.
static func gold(id: String, rng: RandomNumberGenerator = null) -> int:
	var a: Dictionary = art(id)
	var von: int = int((a["gold"] as Array)[0])
	var bis: int = int((a["gold"] as Array)[1])
	if rng != null:
		return rng.randi_range(von, bis)
	return randi_range(von, bis)


## Wie viele Ausrüstungsstücke.
static func stuecke(id: String, rng: RandomNumberGenerator = null) -> int:
	var a: Dictionary = art(id)
	var von: int = int((a["stuecke"] as Array)[0])
	var bis: int = int((a["stuecke"] as Array)[1])
	if rng != null:
		return rng.randi_range(von, bis)
	return randi_range(von, bis)


## Eine Seltenheit für diese Truhe würfeln — und bei Bedarf anheben.
##
## Das Anheben ist der Kern des Unterschieds: Gewürfelt wird immer, aber was unter dem
## garantierten Maß liegt, wird daraufgezogen. So bleibt die Bosstruhe nach oben offen (sie
## *kann* legendär geben) und nach unten dicht.
static func seltenheit(id: String, roll: float = -1.0) -> String:
	var a: Dictionary = art(id)
	var gewuerfelt: String = ProgressionManager.roll_rarity(float(a["bias"]), roll)
	var minimum: String = String(a["min_seltenheit"])
	if minimum == "":
		return gewuerfelt
	var i_ist: int = ProgressionManager.RARITY_ORDER.find(gewuerfelt)
	var i_min: int = ProgressionManager.RARITY_ORDER.find(minimum)
	return minimum if i_ist < i_min else gewuerfelt


## Gibt es hier einen Trank?
static func trank(id: String, roll: float = -1.0) -> bool:
	return (roll if roll >= 0.0 else randf()) < float(art(id)["trank"])


## Wie viele Schlüssel diese Truhe verlangt.
static func schluessel(id: String) -> int:
	return int(art(id).get("schluessel", 0))


## Darf sie mit dem aufgemacht werden, was man bei sich trägt?
static func offen_mit(id: String, im_beutel: int) -> bool:
	return im_beutel >= schluessel(id)


## Der Satz, der erklärt, warum sie zubleibt.
##
## Er nennt die Zahl — „verschlossen" allein sagt niemandem, ob er zwei Schlüssel braucht oder
## zwanzig, und eine Sperre, deren Preis man nicht kennt, ist keine Aufgabe, sondern eine Wand.
static func schloss_text(id: String, im_beutel: int) -> String:
	var noetig: int = schluessel(id)
	if im_beutel >= noetig:
		return ""
	return "⊘ Verschlossen — %d von %d Schlüsseln. Anführer tragen sie." % [im_beutel, noetig]


## Wie viel Grubenstahl in dieser Kiste liegt.
##
## **Nur der Stollen fragt danach.** Die Zahl steht hier, weil sie zum Kisteninhalt gehört wie
## Gold und Ausrüstung — aber Grubenstahl gibt es ausschließlich unter Tage, und die Truhen der
## Oberwelt rufen diese Funktion schlicht nicht auf. Der Test hält das fest.
##
## Vorher lag der Stahl als Halden über die Kammern gestreut. Das machte den Stollen zu einer
## Sammelaufgabe, bei der man am Boden klebt statt die Kammer anzusehen — und es war ein
## zweiter Weg, an Material zu kommen, neben dem, den es ohnehin schon gab. In der Kiste ist er
## ein **Fund**: derselbe Griff, der auch Gold und Ausrüstung bringt.
static func stahl(id: String, rng: RandomNumberGenerator = null) -> int:
	var spanne: Array = art(id).get("stahl", [0, 0])
	var von: int = int(spanne[0])
	var bis: int = int(spanne[1])
	if bis <= 0:
		return 0
	return rng.randi_range(von, bis) if rng != null else randi_range(von, bis)
