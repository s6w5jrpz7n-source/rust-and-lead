extends RefCounted
## Die Uhr der Welt: Tageszeit, Phasen und das Licht, das dazugehört.
##
## Warum das eine eigene Datei ist und nicht drei Zeilen in `OverworldView`: An der Tageszeit
## hängt mehr als die Beleuchtung. Gegner, die nur nachts aus ihrer Höhle kommen, Quests, die
## eine Uhrzeit verlangen, Händler, die schließen — das alles muss dieselbe Uhr lesen, und zwar
## auch dort, wo es keine Szene gibt (Tests, `QuestManager`). Deshalb: reine Rechnung, keine
## Knoten, alles statisch.
##
## ## Der Tag ist kurz — aber nicht mehr SO kurz
##
## Ein Spieltag dauert **vierundzwanzig Minuten** Echtzeit. Vorher waren es zwölf, und das war
## zu wenig: Man stand in Rustwater vor einem Händler, und während des Gesprächs wurde es
## Nacht. Bei zwölf Minuten vergeht in jeder Sekunde eine Spielminute — die Uhr rennt sichtbar,
## und eine Uhr, die man beim Zusehen laufen sieht, ist keine Tageszeit mehr, sondern ein
## Ticker.
##
## Kurz bleibt der Tag trotzdem, und mit Absicht: Wer eine Nachtquest hat, soll nicht eine
## Stunde warten, und wer die Wüste bei Abendlicht sehen will, soll sie heute noch sehen. Zum
## Vergleich: Eine Querung des Kraters zu Fuß dauert achtzehn Minuten — eine lange Reise führt
## also immer noch durch mehr als eine Tageszeit, und genau das soll sie.
##
## ## Fünf Phasen, nicht zwei
##
## „Tag" und „Nacht" wären zu grob. Die interessanten Bilder liegen dazwischen: Die Sonne steht
## tief, die Schatten sind lang, und ein Mündungsfeuer wirft zum ersten Mal Licht, das man sieht.
## Deshalb bekommen Dämmerung und Abendrot eigene Phasen — sie sind kurz und sollen es sein.

## Länge eines Spieltags in echten Sekunden.
##
## Die Zahl steht an genau einer Stelle, und alles andere rechnet sie sich aus (`advance`,
## `sun_energy`, die Phasen). Wer sie ändert, ändert die Uhr des ganzen Spiels und nichts
## sonst — deshalb war das Verdoppeln auch eine einzige Zeile.
const DAY_SEC: float = 1440.0

## Uhrzeit, bei der eine neue Runde beginnt: **Abendrot**.
##
## Der Prolog ist darauf gebaut: Der Held erwacht in der Dämmerung auf der Kippe, und während er
## Richtung Rustwater geht, wird es Nacht. Wenn die Stadt in Sicht kommt, liegt sie als warmer
## Lichtfleck in einer dunklen Wüste — das ist das Bild, auf das der ganze Anfang zuläuft.
##
## Die Rechnung dahinter: Ein Spieltag dauert vierundzwanzig Minuten, der Weg von der Grube
## nach Rustwater gut einen Kilometer, also vier Minuten zu Fuß. Das sind vier Spielstunden —
## von 18:36 aus wird es unterwegs verlässlich dunkel (Ankunft gegen 22:40), im Sattel
## (dreifaches Tempo) kommt man im letzten Abendrot an.
##
## Seit der Tag doppelt so lang ist, ist die Ankunft im Sattel also früher — 19:55 statt 21:20.
## Das bleibt so: Beide Ankünfte liegen weiterhin nach Sonnenuntergang, und wer reitet, soll
## auch etwas davon haben, dass er schneller da ist.
const START_HOUR: float = 18.6

# ── Phasen ────────────────────────────────────────────────────────────────────
const NACHT: String = "nacht"
const DAEMMERUNG: String = "daemmerung"   # vor Sonnenaufgang
const TAG: String = "tag"
const ABEND: String = "abend"             # Abendrot
## Grenzen in Stunden. Zwischen `abend_ende` und `daemmerung_start` ist Nacht — der Übergang
## über Mitternacht ist deshalb der einzige, der „hinten herum" geht.
const H_DAEMMERUNG: float = 5.0
const H_TAG: float = 7.0
const H_ABEND: float = 18.5
const H_NACHT: float = 20.5

## Phase zu einer Stunde (0–24).
static func phase_at(stunde: float) -> String:
	var h: float = fposmod(stunde, 24.0)
	if h < H_DAEMMERUNG or h >= H_NACHT:
		return NACHT
	if h < H_TAG:
		return DAEMMERUNG
	if h < H_ABEND:
		return TAG
	return ABEND


## Ist es dunkel genug, dass Nachtgegner herauskommen? Dämmerung zählt mit — ein Tier, das das
## Licht scheut, wartet nicht auf Mitternacht, es wartet auf den Schatten.
static func is_dark(stunde: float) -> bool:
	var p: String = phase_at(stunde)
	return p == NACHT or p == DAEMMERUNG


## Wie hell ist es, 0 (tiefe Nacht) bis 1 (Mittag)? Weich, nicht gestuft — eine Beleuchtung, die
## an Phasengrenzen springt, liest sich als Fehler.
static func daylight(stunde: float) -> float:
	var h: float = fposmod(stunde, 24.0)
	# Sinus über den Bogen zwischen Auf- und Untergang, davor und danach null.
	var auf: float = H_DAEMMERUNG
	var unter: float = H_NACHT
	if h <= auf or h >= unter:
		return 0.0
	return sin(PI * (h - auf) / (unter - auf))


## ## Sonne und Mond STEHEN — sie wandern nicht
##
## Ein Spieltag dauert vierundzwanzig Minuten. Eine Sonne, die in dieser Zeit den ganzen Bogen
## abfaehrt, bewegt sich um ein Grad je Sekunde — und damit wandert jeder Schatten in der Welt
## sichtbar mit. Godot rechnet die Schattenkarte fuer jeden Frame neu, und weil sie eine
## begrenzte Aufloesung hat, tanzen die Kanten dabei: Was aussieht wie grobes Rauschen, ist
## eine Schattenkarte, die zwischen zwei Rasterpositionen hin- und herspringt.
##
## Das ist der Preis fuer eine Genauigkeit, die niemand sehen will. Also stehen beide fest —
## die Sonne auf einer hohen Nachmittagsposition, der Mond ihr gegenueber. Was sich mit der
## Tageszeit aendert, ist FARBE und STAERKE, und genau daran erkennt man die Uhrzeit ohnehin:
## Ein Abendrot ist rot, kein bestimmter Winkel.
##
## Der Gewinn ist doppelt. Die Schatten stehen still, also flimmern sie nicht. Und weil sie
## stillstehen, lohnt sich eine hoehere Aufloesung fuer sie (Projekteinstellung
## `directional_shadow/size`) — bei einer wandernden Sonne haette die nur schaerfer flimmern
## lassen.
const SONNE_HOEHE: float = 54.0
const SONNE_AZIMUT: float = 38.0

## Höhe der Sonne über dem Horizont in Grad. Konstant — siehe oben.
static func sun_altitude_deg(_stunde: float) -> float:
	return SONNE_HOEHE


## Richtung, aus der die Sonne scheint — wandert über den Tag von Ost nach West.
static func sun_azimuth_deg(_stunde: float) -> float:
	return SONNE_AZIMUT


## Lichtfarbe. Tief stehende Sonne ist rot, hohe ist fast weiß, Nacht ist Mondblau.
static func sun_color(stunde: float) -> Color:
	var t: float = daylight(stunde)
	if t <= 0.0:
		return Color(0.62, 0.70, 0.95)          # Vollmond: kühl, aber hell
	# Unter einem Viertel Helligkeit steht sie tief: Auf- und Untergangsrot.
	var tief := Color(1.0, 0.55, 0.30)
	var hoch := Color(1.0, 0.95, 0.84)
	return tief.lerp(hoch, smoothstep(0.0, 0.55, t))


## Stärke des gerichteten Lichts. Nachts scheint der **Vollmond** — nicht als Restlicht,
## sondern als Lichtquelle: Er wirft eigene, harte Schatten und zeichnet die Landschaft in
## Blaugrau. Ein Viertel der Mittagssonne ist die Größenordnung, in der man eine Wüstennacht
## bei klarem Himmel tatsächlich erlebt; darunter sieht man nichts, darüber wird es Tag.
## GEMESSEN, nicht geschaetzt. Bei 0,42 waren 84 % eines Nachtbilds unter 12/255 — also
## schwarz, nicht dunkel. Man sah die Lichter der Stadt und sonst nichts; die Wueste dazwischen
## war ein Loch, und ein Spiel, in dem man nachts nicht laufen kann, hat keine Nacht, sondern
## eine Pause.
##
## Eine Wuestennacht bei Vollmond und klarem Himmel ist HELL — man liest keine Zeitung, aber man
## sieht den Weg, die Kante eines Felsens und den eigenen Schatten. Genau das ist der Anspruch:
## Der Mond wirft harte Schatten, die Farbe ist blaugrau, aber die Form der Welt bleibt lesbar.
const MOND_ENERGIE: float = 0.34
static func sun_energy(stunde: float) -> float:
	return lerpf(0.0, 1.7, daylight(stunde))


## Das Mondlicht — eine EIGENE gerichtete Lichtquelle, nicht ein Bodensatz der Sonnenenergie.
##
## Vorher war es genau das: `sun_energy` gab nachts einfach `MOND_ENERGIE` zurueck, und dieses
## Licht kam aus der Richtung der SONNE. Die steht nachts bei −14°, also unter dem Horizont —
## das Licht strich von unten durch den Boden und beleuchtete praktisch nichts. Gleichzeitig
## haengte die Mondscheibe sichtbar bei +52° am Himmel. Quelle und Wirkung widersprachen sich,
## und die Nacht war schwarz.
##
## Zwei gerichtete Lichter kosten eine zweite Schattenkarte. Das ist der Preis dafuer, dass
## Sonne und Mond gleichzeitig existieren duerfen — und in der Daemmerung tun sie das
## tatsaechlich, weshalb ein einzelnes umschaltendes Licht dort einen Sprung machen wuerde.
## Der Mond geht auf, BEVOR die Sonne unten ist — und das ist keine Kosmetik, sondern die
## Reparatur einer Luecke.
##
## Vorher verschwand er, sobald `daylight` ueber 0,28 lag. Um 18:36 (dem Beginn des Prologs)
## stand die Sonne bei +15° und der Mond bei 0,00 — und weil die 66°-Wand der Schrottgrube die
## tief stehende Sonne verdeckt, blieb der Grubenboden nur mit Umgebungslicht zurueck. Genau
## diese Stunde war die dunkelste des ganzen Tages, ausgerechnet im ersten Augenblick des
## Spiels.
##
## Am echten Himmel steht der Vollmond laengst am Osthorizont, waehrend die Sonne im Westen
## untergeht. Die Ueberblendung deckt jetzt diesen Bereich ab: Ab `daylight` 0,66 abwaerts
## uebernimmt er allmaehlich, bei 0,12 hat er die volle Staerke.
const MOND_FARBE: Color = Color(0.62, 0.70, 0.95)
## Wo der Mond steht. Etwas flacher als die Sonne und ihr gegenueber: So faellt sein Licht aus
## der anderen Richtung, und die Nachtschatten liegen woanders als die Tagschatten — der
## Unterschied ist zu sehen, ohne dass sich etwas bewegen muss.
const MOND_HOEHE: float = 44.0
static func moon_energy(stunde: float) -> float:
	return MOND_ENERGIE * (1.0 - smoothstep(0.12, 0.66, daylight(stunde)))


## Himmelsfarbe. Der Bronzehimmel der Story-Bibel bei Tag, tiefes Blaugrau bei Nacht.
static func sky_color(stunde: float) -> Color:
	var t: float = daylight(stunde)
	var nacht := Color(0.055, 0.068, 0.105)
	var glut := Color(0.42, 0.24, 0.16)      # Horizontglut zur Dämmerung
	var tag := Color(0.55, 0.55, 0.42)
	if t < 0.35:
		return nacht.lerp(glut, smoothstep(0.0, 0.35, t))
	return glut.lerp(tag, smoothstep(0.35, 0.75, t))


## Umgebungslicht (der Himmelsanteil, der in die Schatten fällt).
static func ambient_color(stunde: float) -> Color:
	var t: float = daylight(stunde)
	return Color(0.21, 0.26, 0.42).lerp(Color(0.62, 0.66, 0.78), smoothstep(0.0, 0.6, t))


static func ambient_energy(stunde: float) -> float:
	# Nachts DEUTLICH weniger, sonst ist die Nacht nur ein blauer Anstrich. Der Unterschied
	# zwischen Licht- und Schattenseite muss auch nachts bestehen bleiben, sonst wird alles flach.
	# Nachts DEUTLICH weniger als tagsueber — und deutlich weniger, als man beim ersten
	# Aufhellen versucht ist zu nehmen. Umgebungslicht hat keine Richtung: Es hebt alles
	# gleichmaessig an und macht aus einer Mondnacht einen truebe beleuchteten Tag. Die
	# Helligkeit muss vom gerichteten MONDLICHT kommen, das Schatten wirft; das Umgebungslicht
	# fuellt nur so weit auf, dass die Schattenseite nicht schwarz absaeuft.
	return lerpf(0.11, 0.42, daylight(stunde))


## Wo steht der Mond? Gegenüber der Sonne — er geht auf, wenn sie untergeht.
##
## Gebraucht für die Mondscheibe am Himmel. Sie ist kein Schmuck: Eine helle Nacht ohne
## sichtbare Quelle wirkt wie ein vergessener Regler. Man muss sehen, WOHER das Licht kommt.
static func moon_altitude_deg(_stunde: float) -> float:
	return MOND_HOEHE


static func moon_azimuth_deg(_stunde: float) -> float:
	return SONNE_AZIMUT + 180.0


## Sichtbarkeit der Mondscheibe (0–1). Sie verblasst, sobald es hell wird — am Taghimmel steht
## sie nicht.
static func moon_visibility(stunde: float) -> float:
	return 1.0 - smoothstep(0.0, 0.30, daylight(stunde))


## Nebelfarbe — nachts kalt, tagsüber staubig.
static func fog_color(stunde: float) -> Color:
	return Color(0.10, 0.13, 0.19).lerp(Color(0.62, 0.62, 0.52),
		smoothstep(0.0, 0.6, daylight(stunde)))


## „06:30" — für das HUD.
static func clock_text(stunde: float) -> String:
	var h: float = fposmod(stunde, 24.0)
	return "%02d:%02d" % [int(h), int(fposmod(h * 60.0, 60.0))]


## Name der Phase, wie er im Spiel steht.
const PHASE_NAME: Dictionary = {
	NACHT: "Nacht", DAEMMERUNG: "Dämmerung", TAG: "Tag", ABEND: "Abendrot",
}
const PHASE_ICON: Dictionary = {
	NACHT: "☾", DAEMMERUNG: "◔", TAG: "☀", ABEND: "◑",
}

static func phase_label(stunde: float) -> String:
	var p: String = phase_at(stunde)
	return "%s %s" % [String(PHASE_ICON[p]), clock_text(stunde)]


## Die Uhr um `delta` Sekunden Echtzeit weiterstellen.
static func advance(stunde: float, delta: float) -> float:
	return fposmod(stunde + delta * (24.0 / DAY_SEC), 24.0)
