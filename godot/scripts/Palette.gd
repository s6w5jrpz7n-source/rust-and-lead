extends RefCounted
## Der Farbraum des Spiels — gemessen, nicht erfunden.
##
## ## Woher diese Zahlen kommen
##
## Aus den Bildern, die es schon gibt. `assets/ui/titelbild.webp` und das Intro-Video
## `assets/video/intro_muellkippe.mp4` wurden mit `ffmpeg -vf palettegen` auf je zwölf Farben
## heruntergerechnet. Das Ergebnis war in beiden Fällen dasselbe, und das ist die eigentliche
## Entdeckung: Unsere vorhandene Grafik liegt auf **einem einzigen warmen Keil** — Ton um 22°
## bis 28° (Ocker/Rost), von fast schwarz bis zu hellem Sandgelb durchgezogen.
##
##     Intro:    #090201  #140a06  #1e110b  #2b1b13  #3f291b  #583d27
##               #6f4c31  #865c3c  #a57950  #c19769  #e2bf91
##     Titel:    #110603  #23170e  #372316  #4c321e  #654126  #7a4e2e
##               #93603b  #ac774c  #c19262  #d6ac78  #ebcb99
##
## Zwei unabhängig entstandene Bilder, dieselbe Leiter. Das ist kein Zufall, sondern das, was
## die Bildgeneratoren aus unseren Prompts gemacht haben — und damit ist es der Hausfarbraum,
## ob wir ihn gewählt haben oder nicht. Jedes neue Hintergrundbild hat sich daran zu halten,
## sonst zerfällt das Spiel optisch in „vor dem Adventure" und „nach dem Adventure".
##
## ## Baphomets Fluch, aber nicht dessen Farben
##
## Die **Bauform** kommt von Baphomets Fluch: gemalte Bühnenbilder, flache Aufsicht, Figur in
## Dreiviertelansicht davor. Dessen **Farbigkeit** nicht — Revolution malte Paris im Herbst,
## mit Blau, Grün und Rot nebeneinander. Hier gibt es praktisch einen Ton. Was dort über die
## Buntheit getrennt wird (ein roter Mantel vor grüner Hecke), muss hier über die **Helligkeit**
## getrennt werden: Figur dunkel vor hellem Hintergrund oder umgekehrt, nie dunkel vor dunkel.
##
## Darum stehen unten nicht nur Farben, sondern **Helligkeitsstufen mit Pflicht-Abstand**.
##
## ## Die kühlen Töne sind Munition
##
## Es gibt genau drei nicht-warme Farben, und jede hat eine feste Bedeutung. Sie sind selten,
## damit sie wirken: Ein galvanisch blauer Lichtschein in einem Bild voller Ocker zieht das
## Auge sofort, ein zweiter halbiert das, ein dritter macht es zur Dekoration. **Höchstens ein
## kühler Akzent je Bild.**

# ── Der warme Keil ────────────────────────────────────────────────────────────
#
# Elf Stufen, von Ruß bis Sandlicht. Die Namen sind absichtlich Material und nicht „dunkel_3":
# Wer ein Bild beschreibt, soll „Ölschwarz" sagen können.

const RUSS: Color          = Color("#090201")   ## tiefster Schatten; nur dort, wo nichts ist
const OELSCHWARZ: Color    = Color("#140a06")   ## nasses Leder, Öl, Maschinenschatten
const SCHLACKE: Color      = Color("#1e110b")   ## Grundton von Innenräumen
const TEER: Color          = Color("#2b1b13")   ## Holz im Schatten, Palisaden
const ROSTERDE: Color      = Color("#3f291b")   ## der Boden draußen
const LEDER: Color         = Color("#583d27")   ## Mäntel, Riemen, Fässer
const ALTKUPFER: Color     = Color("#6f4c31")   ## Dächer, verwittertes Blech
const MESSING: Color       = Color("#865c3c")   ## Beschläge, Mechanik
const SAND: Color          = Color("#a57950")   ## Piste, trockene Erde im Licht
const DUNST: Color         = Color("#c19769")   ## Ferne, Staub in der Luft
const SANDLICHT: Color     = Color("#e2bf91")   ## Himmel am Horizont, Lampenschein

## Die elf Stufen in Reihenfolge — für Verläufe und für die Prüfung auf Abstand.
const KEIL: Array = [RUSS, OELSCHWARZ, SCHLACKE, TEER, ROSTERDE, LEDER,
	ALTKUPFER, MESSING, SAND, DUNST, SANDLICHT]

# ── Die drei kühlen Akzente ───────────────────────────────────────────────────
#
# Jeder hat eine Bedeutung, und die gilt im ganzen Spiel. Ein blaues Leuchten heisst immer
# „Konzern-Maschinerie unter Strom" — nie „hier ist zufällig was Blaues".

const GALVANISCH: Color    = Color("#4a86a0")   ## Konzern-Energie, Kesselglimmen, Automatenaugen
const GRUENSPAN: Color     = Color("#5c7a63")   ## Fäulnis, Sumpf, altes Kupfer am Wasser
const LEICHENBLAU: Color   = Color("#6b7a8c")   ## Mondlicht, Kälte, Tod

## Signalfarbe. NICHT Teil des Bildes — nur Oberfläche: aktiver Hotspot, Treffer, Warnung.
const BLUT: Color          = Color("#8f2d20")

# ── Oberfläche ────────────────────────────────────────────────────────────────

const SCHRIFT: Color       = Color("#e8d6b8")   ## Fließtext auf dunklem Grund
const SCHRIFT_MATT: Color  = Color("#a08a6b")        ## Nebensätze, Mengenangaben
const TAFEL: Color         = Color("#140a06")   ## Grund der Sprechtafel
const RAHMEN: Color        = Color("#865c3c")   ## Linien, Kanten, Trennstriche

## Wie durchsichtig die Sprechtafel über dem Bild liegt. Baphomets Fluch legt Text direkt ins
## Bild, ohne Kasten. Das geht dort, weil die Hintergründe ruhige Flächen haben; unsere sind
## staubig und kontrastreich, und Text ohne Grund wäre unlesbar. Also ein Kasten, aber einer,
## der das Bild durchscheinen lässt.
const TAFEL_DECKUNG: float = 0.82

# ── Regeln, die sich nachrechnen lassen ───────────────────────────────────────

## Mindest-Helligkeitsabstand zwischen Figur und dem, wovor sie steht.
##
## 0.18 auf einer Skala von 0 bis 1. Darunter verschwindet eine ölschwarze Gestalt vor einer
## teerschwarzen Wand — der klassische Fehler eines einfarbigen Spiels, und er fällt erst auf,
## wenn jemand anders es spielt.
const ABSTAND_MIN: float = 0.18


## Wahrgenommene Helligkeit (0..1) — gewichtet, nicht der Mittelwert.
##
## Das Auge sieht Grün als deutlich heller als Blau bei gleichem Zahlenwert. Ein ungewichteter
## Mittelwert würde behaupten, Messing und Grünspan seien gleich hell; sie sind es nicht.
static func helligkeit(f: Color) -> float:
	return f.r * 0.299 + f.g * 0.587 + f.b * 0.114


## Stehen diese beiden Farben weit genug auseinander, um übereinander lesbar zu sein?
static func trennt_genug(a: Color, b: Color) -> bool:
	return absf(helligkeit(a) - helligkeit(b)) >= ABSTAND_MIN


## Die Stufe des Keils, die am weitesten von `f` entfernt liegt — für Umrisse und Schrift auf
## wechselndem Grund.
static func gegenstufe(f: Color) -> Color:
	var h: float = helligkeit(f)
	var beste: Color = SANDLICHT
	var weit: float = -1.0
	for stufe in KEIL:
		var d: float = absf(helligkeit(stufe as Color) - h)
		if d > weit:
			weit = d
			beste = stufe as Color
	return beste


## Eine Stufe des Keils nach Zahl (0..1) — für Verläufe im Platzhalter-Hintergrund.
static func keil_bei(anteil: float) -> Color:
	var a: float = clampf(anteil, 0.0, 1.0) * float(KEIL.size() - 1)
	var i: int = int(floorf(a))
	if i >= KEIL.size() - 1:
		return KEIL[KEIL.size() - 1] as Color
	return (KEIL[i] as Color).lerp(KEIL[i + 1] as Color, a - float(i))


## Dieselbe Farbe, aber so weit aufgehellt oder abgedunkelt, dass sie sich von `grund` abhebt.
##
## Wird für Figuren vor wechselndem Hintergrund gebraucht: Dieselbe Gestalt steht mal vor einer
## hellen Wüste, mal in einem dunklen Stollen, und soll in beiden Fällen sichtbar sein, ohne
## dass man zwei Sätze Grafik malt.
static func abheben(f: Color, grund: Color) -> Color:
	if trennt_genug(f, grund):
		return f
	var ziel: Color = RUSS if helligkeit(grund) > 0.5 else SANDLICHT
	var raus: Color = f
	# In zwanzig Schritten in Richtung Gegenpol, bis der Abstand reicht. Eine Schleife und keine
	# Formel, weil `lerp` auf Farben nicht linear in der Helligkeit ist.
	for i in range(20):
		if trennt_genug(raus, grund):
			return raus
		raus = raus.lerp(ziel, 0.1)
	return raus
