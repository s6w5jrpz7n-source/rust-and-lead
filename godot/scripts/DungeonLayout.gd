class_name DungeonLayout
## Der Grundriss eines Stollens — als Rechnung, ohne eine einzige Szene.
##
## ## Warum das hier kein Labyrinth von Hand ist
##
## Ein handgebauter Dungeon ist beim ersten schön und beim zweiten dieselbe Arbeit von vorn.
## Ein Erzeuger kostet einmal mehr und macht jeden weiteren zu einer Zeilenänderung — genau
## das steht so in `docs/PLAN_DUNGEON.md`.
##
## ## Warum er nichts von Godot weiß
##
## Hier stehen nur Zahlen: Räume als `Rect2i`, Böden als Feldermenge, ein Eingang, eine Treppe.
## Kein Knoten, kein Licht, keine Wand. Das ist Absicht — so kann der Test **hundert Grundrisse
## durchrechnen** und bei jedem einzelnen nachsehen, ob die Treppe vom Eingang aus überhaupt
## erreichbar ist. An einer fertigen Szene ginge das nur mit dem Auge, und ein Stollen, dessen
## Treppe hinter einer Wand liegt, sieht auf dem Bild völlig in Ordnung aus.
##
## Diese eine Eigenschaft — **alles ist erreichbar** — ist der ganze Grund für die Trennung.
## Sie lässt sich nicht durch Hinsehen prüfen und nicht durch Sorgfalt garantieren, sondern nur
## durch Nachlaufen. Deshalb läuft der Test sie nach, mit einer Flutfüllung, für jeden Startwert.
##
## ## Wie die Räume zusammenkommen
##
## Reihum: einen Platz würfeln, prüfen ob er frei ist, hinlegen. Dann **jeden neuen Raum mit dem
## vorigen verbinden** — nicht mit einem zufälligen. Das klingt kleinlich und ist der Kern:
## Wer Raum 5 mit Raum 2 verbindet, kann eine Insel erzeugen; wer immer an den Vorgänger
## anschließt, hängt an einer Kette, und eine Kette ist per Konstruktion zusammenhängend.

## Kantenlänge eines Feldes in Metern. 4 m, weil das Wandsegment 4 m breit ist — ein Feld ist
## genau ein Wandstück, und nichts muss gestückelt werden.
const FELD_M: float = 4.0

## Wie groß das Gitter je Ebene ist (Felder).
const GITTER: Vector2i = Vector2i(26, 26)

## Raumgrößen in Feldern, jeweils von/bis.
const RAUM_MIN: int = 3
const RAUM_MAX: int = 7

## Wie viele Räume je Ebene. Ebene 1 ist der Vorschacht, Ebene 2 die Kaverne.
const RAEUME: Dictionary = { 1: 6, 2: 9 }

## Wie oft ein Raum einen Platz suchen darf, bevor er aufgibt. Ohne Deckel läuft die Schleife
## bei dichtem Gitter ewig — und ein Spiel, das beim Betreten haengt, ist schlimmer als eines
## mit einem Raum weniger.
const VERSUCHE: int = 120


## Einen Grundriss rechnen.
##
## Gleicher `startwert` und gleiche `ebene` ergeben immer denselben Stollen. Das ist nicht nur
## ordentlich, sondern nötig: Wer den Dungeon verlässt und wieder betritt, soll nicht in einem
## anderen stehen.
##
## Rückgabe:
##   `raeume`  Array[Rect2i] — in Legereihenfolge
##   `boden`   Dictionary Vector2i -> true — jedes begehbare Feld (Räume UND Gänge)
##   `eingang` Vector2i — wo man hereinkommt
##   `treppe`  Vector2i — wo es weitergeht (Ebene 2: der Ausgang nach oben)
##   `truhen`  Array[Vector2i]
##   `gegner`  Array[Vector2i]
static func erzeugen(startwert: int, ebene: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("stollen-%d-%d" % [startwert, ebene])

	var raeume: Array[Rect2i] = []
	var soll: int = int(RAEUME.get(ebene, 6))
	for _i in VERSUCHE:
		if raeume.size() >= soll:
			break
		var b: int = rng.randi_range(RAUM_MIN, RAUM_MAX)
		var h: int = rng.randi_range(RAUM_MIN, RAUM_MAX)
		# −1 beim oberen Rand: Ein Raum, der bündig an der Gitterkante endet, hat dort keine
		# Wand mehr, in die eine Tür passt.
		var x: int = rng.randi_range(1, maxi(1, GITTER.x - b - 1))
		var y: int = rng.randi_range(1, maxi(1, GITTER.y - h - 1))
		var neu := Rect2i(x, y, b, h)
		# Ein Feld Luft ringsum, sonst kleben zwei Räume zu einem Saal zusammen und die Wand
		# dazwischen verschwindet.
		var luft := Rect2i(neu.position - Vector2i.ONE, neu.size + Vector2i.ONE * 2)
		var frei: bool = true
		for r in raeume:
			if luft.intersects(r):
				frei = false
				break
		if frei:
			raeume.append(neu)

	# Böden eintragen: erst die Räume, dann die Gänge.
	var boden: Dictionary = {}
	for r in raeume:
		for fx in range(r.position.x, r.end.x):
			for fy in range(r.position.y, r.end.y):
				boden[Vector2i(fx, fy)] = true

	# Und die Kette: jeder Raum an seinen VORGAENGER. Damit haengt alles zusammen, ohne dass
	# jemand hinterher nachsehen muss.
	for i in range(1, raeume.size()):
		var a: Vector2i = _mitte(raeume[i - 1])
		var b2: Vector2i = _mitte(raeume[i])
		# L-förmig, die Ecke abwechselnd waagerecht/senkrecht zuerst — sonst laufen alle Gänge
		# gleich und der Stollen sieht gerastert aus.
		if i % 2 == 0:
			_gang_x(boden, a.y, a.x, b2.x)
			_gang_y(boden, b2.x, a.y, b2.y)
		else:
			_gang_y(boden, a.x, a.y, b2.y)
			_gang_x(boden, b2.y, a.x, b2.x)

	# Eingang in den ersten Raum, Treppe in den LETZTEN — nicht in den entferntesten. Die Kette
	# legt die Räume ohnehin nacheinander, und „der letzte" ist verlässlich weit weg, ohne dass
	# eine Abstandsrechnung danebengreifen kann, wenn zwei Räume dicht beieinander liegen.
	var eingang: Vector2i = _mitte(raeume[0]) if not raeume.is_empty() else Vector2i.ZERO
	var treppe: Vector2i = _mitte(raeume[raeume.size() - 1]) if not raeume.is_empty() else Vector2i.ONE

	# Truhen und Gegner in die MITTLEREN Räume. Nicht in den ersten: Wer den Stollen betritt und
	# sofort auf einen Kläffer tritt, hat keine Gelegenheit, ihn kommen zu sehen.
	var truhen: Array[Vector2i] = []
	var gegner: Array[Vector2i] = []
	for i in range(1, raeume.size()):
		var r: Rect2i = raeume[i]
		if i % 2 == 1 or i == raeume.size() - 1:
			truhen.append(_streu(rng, r))
		var wie_viele: int = rng.randi_range(1, 2 if ebene == 1 else 3)
		for _k in wie_viele:
			gegner.append(_streu(rng, r))

	return { "raeume": raeume, "boden": boden, "eingang": eingang, "treppe": treppe,
		"truhen": truhen, "gegner": gegner, "ebene": ebene, "startwert": startwert }


## Ist dieses Feld begehbar?
static func begehbar(plan: Dictionary, feld: Vector2i) -> bool:
	return bool((plan.get("boden", {}) as Dictionary).get(feld, false))


## Feldmitte in Szenenkoordinaten. Das Gitter wird um seinen Mittelpunkt zentriert, damit der
## Stollen um (0|0) liegt und die Kamera nichts nachrechnen muss.
static func feld_zu_szene(feld: Vector2i) -> Vector3:
	return Vector3((float(feld.x) - float(GITTER.x) * 0.5) * FELD_M, 0.0,
		(float(feld.y) - float(GITTER.y) * 0.5) * FELD_M)


## Und zurück — für „auf welchem Feld steht die Figur gerade".
static func szene_zu_feld(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / FELD_M + float(GITTER.x) * 0.5 + 0.5)),
		int(floor(p.z / FELD_M + float(GITTER.y) * 0.5 + 0.5)))


## Welche Felder sind vom Eingang aus zu Fuß erreichbar?
##
## Die Flutfüllung steht HIER und nicht nur im Test: Wer den Erzeuger ändert, soll die Prüfung
## im selben Haus finden — und die Szene benutzt sie, um Truhen und Gegner zu verwerfen, die
## trotz allem in einer Nische gelandet sind.
static func erreichbar(plan: Dictionary) -> Dictionary:
	var boden: Dictionary = plan.get("boden", {})
	var start: Vector2i = plan.get("eingang", Vector2i.ZERO)
	var gesehen: Dictionary = {}
	if not boden.has(start):
		return gesehen
	var rand: Array[Vector2i] = [start]
	gesehen[start] = true
	while not rand.is_empty():
		var f: Vector2i = rand.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = f + d
			if boden.has(n) and not gesehen.has(n):
				gesehen[n] = true
				rand.append(n)
	return gesehen


## Wo eine Wand hin muss: jedes NICHT begehbare Feld, das an ein begehbares grenzt.
##
## Nur die Grenzfelder, nicht das ganze Gestein — sonst stellt die Szene tausend Kästen auf, von
## denen niemand je eines sieht.
static func waende(plan: Dictionary) -> Array[Vector2i]:
	var boden: Dictionary = plan.get("boden", {})
	var raus: Array[Vector2i] = []
	var gesehen: Dictionary = {}
	for f in boden:
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n: Vector2i = (f as Vector2i) + Vector2i(dx, dy)
				if boden.has(n) or gesehen.has(n):
					continue
				gesehen[n] = true
				raus.append(n)
	return raus


static func _mitte(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2


## Ein Platz IM Raum, aber nicht an seiner Wand — dort steht sonst eine Truhe halb im Fels.
static func _streu(rng: RandomNumberGenerator, r: Rect2i) -> Vector2i:
	return Vector2i(
		rng.randi_range(r.position.x, maxi(r.position.x, r.end.x - 1)),
		rng.randi_range(r.position.y, maxi(r.position.y, r.end.y - 1)))


static func _gang_x(boden: Dictionary, y: int, x1: int, x2: int) -> void:
	for x in range(mini(x1, x2), maxi(x1, x2) + 1):
		boden[Vector2i(x, y)] = true


static func _gang_y(boden: Dictionary, x: int, y1: int, y2: int) -> void:
	for y in range(mini(y1, y2), maxi(y1, y2) + 1):
		boden[Vector2i(x, y)] = true
