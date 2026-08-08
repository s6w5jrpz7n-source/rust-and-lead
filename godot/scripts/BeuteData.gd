class_name BeuteData
## Was ein erlegter Gegner an Ausrüstung hergibt.
##
## Gold und Munition fallen weiterhin überall — die braucht man laufend, und wer nach zehn
## Kämpfen ohne Patronen dasteht, spielt kein Spiel mehr, sondern wartet. **Ausrüstung** ist
## etwas anderes: Sie ist der Grund, den Beutel überhaupt zu öffnen, und genau deshalb darf sie
## nicht bei jedem Kadaver liegen.
##
## ## Die Zahlen und warum sie so weit auseinanderliegen
##
## | | gewöhnlicher Gegner | Anführer |
## |---|---|---|
## | irgendetwas | 5 % | 30 % |
## | zwei Stücke | — | 5 % |
##
## Fünf Prozent klingt nach fast nie, und das ist der Punkt. Vorher war jeder Gegner eine
## kleine Lotterie; bei einem Rudel von zwölf fiel dauernd etwas heraus, und der Beutel war nach
## zehn Minuten voll mit Zeug, das man einzeln durchsehen musste. Beute, die ständig kommt, ist
## Verwaltungsarbeit — kein Fund.
##
## Der **Anführer** ist die Gegenprobe: sechsmal so wahrscheinlich. Er ist der Gegner, den man
## sucht statt umgeht, und er muss sich dafür anders anfühlen als die drei, die neben ihm
## standen.
##
## ## Die Wahrscheinlichkeiten sind ABSOLUT, nicht gestaffelt
##
## „30 % ein Stück, 5 % zwei" heißt: In 5 von 100 Kämpfen fallen zwei, in 25 weiteren eines, in
## den übrigen 70 nichts. Nicht „30 %, und davon nochmal 5 %" — sonst wären zwei Stücke ein
## Prozent-und-ein-halb-Ereignis, das im ganzen Spiel dreimal vorkommt und das niemand als Regel
## erkennt.
const CHANCE_NORMAL: float = 0.05
const CHANCE_ANFUEHRER: float = 0.30
const CHANCE_ANFUEHRER_ZWEI: float = 0.05

## Wie stark die Seltenheit nach oben abfällt.
##
## `roll_rarity()` gewichtet die vier Stufen und der `bias` schiebt die Gewichte nach oben.
## Hier steht **0** — die reine Grundverteilung, also common am häufigsten und legendary am
## seltensten. Truhen haben einen positiven Bias (0,3 bzw. 1,1) und sind damit genau das, was
## sie sein sollen: der bessere Weg an gute Ausrüstung. Ein Gegner, der so gut auswirft wie eine
## Beutekammer, macht die Beutekammer sinnlos.
const SELTENHEIT_BIAS: float = 0.0


## Wie viele Ausrüstungsstücke dieser Gegner fallen lässt (0, 1 oder 2).
##
## `wurf` ist eine Zahl aus [0,1) — im Spiel gewürfelt, im Test durchgezählt. Die Schwellen
## liegen aufsteigend übereinander, damit ein kleinerer Wurf nie *weniger* ergibt als ein
## größerer; sonst wären die Anteile über den Zufallsbereich verschmiert und nicht mehr
## nachrechenbar.
static func stuecke(ist_anfuehrer: bool, wurf: float = -1.0) -> int:
	var x: float = wurf if wurf >= 0.0 else randf()
	if not ist_anfuehrer:
		return 1 if x < CHANCE_NORMAL else 0
	if x < CHANCE_ANFUEHRER_ZWEI:
		return 2
	return 1 if x < CHANCE_ANFUEHRER else 0


## Welche Art Stück — Helm, Panzerung, Waffe, Gerät, Stiefel.
##
## Gleichverteilt über die Slots. „Statistisch" heißt hier ausdrücklich *nicht* gewichtet: Wer
## Waffen seltener macht als Stiefel, baut eine zweite Seltenheitsachse neben der eigentlichen
## ein, und dann ist eine gewöhnliche Waffe schwerer zu bekommen als ein epischer Helm.
static func slot(wurf: float = -1.0) -> String:
	var slots: Array = EquipManager.GEAR_SLOTS
	var x: float = wurf if wurf >= 0.0 else randf()
	return String(slots[clampi(int(x * float(slots.size())), 0, slots.size() - 1)])


## Welche Güte — nach oben entsprechend unwahrscheinlicher.
static func seltenheit(wurf: float = -1.0) -> String:
	return ProgressionManager.roll_rarity(SELTENHEIT_BIAS, wurf)
