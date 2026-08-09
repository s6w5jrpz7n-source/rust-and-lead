class_name HaendlerData
## Wandas Waffenlager — was heute im Regal liegt, und was es kostet.
##
## ## Der Bestand wird nicht gespeichert, sondern GEWUERFELT
##
## Naheliegend waere: vier Waffen erzeugen, in `GameState` legen, mitspeichern. Das hat drei
## Nachteile, und der dritte ist der schlimme:
##
##  * Der Spielstand traegt Gegenstaende mit, die niemandem gehoeren.
##  * Wer laedt und neu laedt, sieht denselben Bestand — oder, schlimmer, einen neuen.
##  * Und beim Aendern der Waffentabelle liegen im Regal Dinge nach alten Regeln.
##
## Stattdessen ist der Bestand eine FUNKTION des Handelstags: Aus `GameState.tag` wird ein Keim,
## aus dem Keim vier Waffen. Innerhalb eines Tages kommt jedes Mal dasselbe heraus — beim
## Oeffnen, beim Schliessen, nach dem Laden. Am naechsten Morgen etwas anderes. Kein Zustand,
## kein Speicherfeld, keine Wanderung durch die Versionen.
##
## ## Was sie fuehrt
##
## Waffen, gewoehnlich bis selten. Ihr Zweck ist, dass Gold einen zweiten Zweck bekommt: Bei
## Silas baut man den Helden aus, bei ihr kauft man das Werkzeug.
##
## NICHT darueber. Episches und Legendaeres kauft man nicht — das findet man, und davon lebt
## der Anreiz hinauszugehen. Ein Haendler, der es fuehrt, macht das Suchen ueberfluessig.
##
## Sie verkauft auch, was man noch nicht tragen darf. Das ist Absicht: Ein Regal, in dem nur
## steht, was man ohnehin anlegen kann, gibt einem nichts zum Hinarbeiten. Die Zeile sagt es
## dazu (`⊘ ab Stufe 12`), und der Kauf ist trotzdem erlaubt — das Teil wandert in den Beutel
## und wartet.

## Wie viele Stuecke gleichzeitig ausliegen.
const PLAETZE: int = 4

## Woraus gewuerfelt wird, mit Gewichten. GEWOEHNLICH BIS SELTEN, nie darueber.
##
## Sie ist die verlaessliche Grundversorgung, nicht die Abkuerzung. Episches und Legendaeres
## kauft man nicht — das findet man, in Truhen und bei Anfuehrern, und genau davon lebt der
## Anreiz hinauszugehen. Ein Haendler, der es fuehrt, macht das Suchen ueberfluessig: Wer genug
## Gold hat, holt sich die beste Waffe im Spiel, ohne je einen Stollen betreten zu haben.
const ANGEBOT: Array = [
	["common", 42],
	["rare", 58],
]

## Preis je Seltenheit — Grundpreis und Aufschlag je Stufe, die das Teil verlangt.
##
## Der Aufschlag haengt an der ANFORDERUNG und nicht an der Seltenheit allein, weil die
## Anforderung seit Kurzem die Staerke abbildet (siehe `ProgressionManager.REQ_SPANNE`): Eine
## schwache epische Waffe verlangt Stufe 1 und ist wenig wert, eine starke verlangt zwoelf und
## ist viel wert. Ein Preis nach Farbe allein waere fuer die eine Wucher und fuer die andere
## geschenkt.
const PREIS_GRUND: Dictionary = {
	"common": 60, "rare": 180,
}
const PREIS_JE_STUFE: Dictionary = {
	"common": 0, "rare": 45,
}


## Der Keim des heutigen Bestands.
##
## `tag` allein waere ein schlechter Keim: Tag 0, 1, 2 liegen dicht beieinander, und viele
## Zufallsgeneratoren liefern fuer benachbarte Keime aehnliche erste Werte — das Regal saehe
## drei Tage lang fast gleich aus. Die Multiplikation streut sie auseinander.
static func keim(tag: int) -> int:
	return 0x9E3779B9 * (tag + 1) & 0x7FFFFFFF


## Was heute ausliegt.
static func bestand() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = keim(GameState.tag)
	var raus: Array = []
	for i in PLAETZE:
		raus.append(ProgressionManager.make_gear("weapon", _seltenheit(rng), "", rng))
	return raus


static func _seltenheit(rng: RandomNumberGenerator) -> String:
	var summe: int = 0
	for e in ANGEBOT:
		summe += int(e[1])
	var w: int = rng.randi_range(1, summe)
	for e in ANGEBOT:
		w -= int(e[1])
		if w <= 0:
			return String(e[0])
	return "rare"


static func preis(gear: Dictionary) -> int:
	var r: String = String(gear.get("rarity", "rare"))
	var grund: int = int(PREIS_GRUND.get(r, 200))
	var je: int = int(PREIS_JE_STUFE.get(r, 40))
	# `req - 1`, damit ein Teil mit der niedrigsten Anforderung seiner Farbe genau den
	# Grundpreis kostet und nicht schon einen Aufschlag traegt.
	return grund + je * maxi(0, int(gear.get("req", 1)) - 1)


## Kaufen. Falsch, wenn das Gold nicht reicht oder der Beutel voll ist.
##
## Die Reihenfolge ist wichtig und war beim ersten Entwurf falsch herum: Erst wird geprueft, ob
## das Teil ueberhaupt in den Beutel passt, DANN wird das Gold abgezogen. Andersherum bezahlt
## man fuer etwas, das man nicht bekommt — und merkt es erst, wenn man den Beutel aufmacht.
static func kaufen(index: int) -> bool:
	var regal: Array = bestand()
	if index < 0 or index >= regal.size():
		return false
	var gear: Dictionary = regal[index]
	var p: int = preis(gear)
	if GameState.gold < p:
		return false
	if not BagManager.has_room_for(gear):
		return false
	if not BagManager.add(gear):
		return false
	GameState.gold -= p
	# Verkauft ist verkauft: Der Platz bleibt bis zum naechsten Handelstag leer.
	if not GameState.gekauft_heute.has(GameState.tag):
		GameState.gekauft_heute[GameState.tag] = []
	(GameState.gekauft_heute[GameState.tag] as Array).append(index)
	return true


## Schon gekauft (und damit heute weg)?
static func verkauft(index: int) -> bool:
	var heute: Array = GameState.gekauft_heute.get(GameState.tag, [])
	return heute.has(index)
