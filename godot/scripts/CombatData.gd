class_name CombatData extends RefCounted
## CombatData — verbindliche Kampf-Registries & Konstanten (Master-GDD §6, §7.1, §7.3).
##
## Reine Daten-/Konstantenklasse (nie instanziiert). Zugriff statisch:
##   CombatData.WEAPONS, CombatData.ENEMY_TYPES, CombatData.xp_for_kill(target), ...
##
## Schadensarten & Klassen werden bewusst als String-Konstanten geführt (GDD-konform,
## save-/datenfreundlich, identisch zu den im Prototyp verifizierten Werten).

# ── Schadensarten ─────────────────────────────────────────────────────────────
const KINETIC: String = "KINETIC"
const GALVANIC: String = "GALVANIC"
const ALCHEMICAL: String = "ALCHEMICAL"
const THERMAL: String = "THERMAL"

# ── Gegner-Klassen ────────────────────────────────────────────────────────────
const BIOLOGICAL: String = "BIOLOGICAL"
const MECHANICAL: String = "MECHANICAL"

# ── Status-Effekte ────────────────────────────────────────────────────────────
const FX_NONE: String = ""
const FX_STUN: String = "SHORT_CIRCUIT_STUN"    # Kurzschluss (4 s bewegungsunfähig)
const FX_BLEED: String = "BLEEDING_DOT"         # Verbluten (DOT, organisch)
const FX_BURN: String = "OVERHEAT_DOT"          # Überhitzung (DOT)
const FX_CORRODE: String = "ARMOR_CORRODED"     # Korrosion (Rüstungs-Debuff)

const STUN_MS: int = 4000
const DOT_MS: int = 3000
const DOT_TICK_SEC: float = 0.4

# ── Boss-/Elite-/Superboss-Konstanten ─────────────────────────────────────────
# ── Anführer ──────────────────────────────────────────────────────────────────
#
# Der Kopf einer Gruppe: kein eigener Gegnertyp, sondern ein VERSTÄRKTER gewöhnlicher. Genau
# das ist der Reiz — man erkennt ihn als das, was man schon kennt, und merkt am dritten Schuss,
# dass diesmal etwas anderes davorsteht.
#
# Die Faktoren wirken auf den EIGENEN Typ, nicht auf einen festen Wert. Ein Anführer der Ratten
# hat dreimal so viel Leben wie eine Ratte, ein Anführer der Konstrukte dreimal so viel wie ein
# Konstrukt — er ist immer der Stärkste SEINER Gruppe und nie plötzlich ein Boss.
const ANFUEHRER_HP_MUL: float = 3.0
const ANFUEHRER_SCHADEN_MUL: float = 2.0
## Was er zusätzlich an Gold trägt. Er hat länger gelebt als die anderen.
const ANFUEHRER_GOLD_MUL: float = 2.5
## Wie viel groesser er ist. Der Schimmer allein traegt bei Tageslicht nicht weit genug — eine
## Silhouette schon, und die liest man auch dann noch, wenn die Figur halb hinter einem Felsen
## steht. Beide Szenen nehmen DIESEN Wert, sonst ist der Anfuehrer drinnen ein anderer als
## draussen.
const ANFUEHRER_GROESSE_MUL: float = 1.30
## Der violette Schimmer. Violett, weil in dieser Welt sonst nichts violett ist: Rost, Sand,
## Kupfer und Messing sind warm, die Nacht ist blau. Eine kalte Buntfarbe fällt hier auf, ohne
## dass man sie erklären muss — und sie ist auch für Rot-Grün-Blinde von allem anderen trennbar.
const ANFUEHRER_SCHIMMER: Color = Color(0.62, 0.30, 0.95)

const BOSS_HP: int = 700
const BOSS_CONTACT: int = 28
const BOSS_GOLD: int = 20
const SUPERBOSS_MULT: int = 4

## Waffen-Loadout (Schadensart-Umschalter). Karabiner immer verfügbar; Rest nach Reveal.
## Waffen (GDD §7.1). Jede hat ein eigenes PROFIL aus vier Zahlen, nicht nur eine Schadensart:
##
##   `base`       Schaden pro Schuss
##   `fire_ms`    Takt zwischen zwei Schuessen
##   `spread_deg` Streuung als halber Oeffnungswinkel des Kegels — 0 = Laser
##   `acid`       Saeure-Potenz (nur Spruerer)
##
## Vorher lagen alle vier Waffen zwischen 170 und 240 ms: Der Karabiner feuerte so schnell wie
## der Dampf-Brenner, und die Wahl war eine reine Farbfrage. Jetzt spannt sich der Takt ueber
## den Faktor ZWOELF — vom Repetierer, der einmal pro Sekunde kracht, bis zur Gatling mit
## vierzehn Schuss pro Sekunde.
##
## Die Streuung macht daraus eine Reichweiten-Entscheidung: Bei 11 m misst ein normaler Gegner
## rund 2,6° Winkelbreite. Der Karabiner (0,8°) trifft auf jede Entfernung, die Gatling (7,0°)
## nur aus der Naehe zuverlaessig — auf volle Distanz geht knapp zwei Drittel daneben. Ein
## Praezisions-Mod (`accuracy`) verengt den Kegel.
##
## `mag` ist die Magazingroesse, `reload_ms` die Nachladedauer. Beides trennt die Waffen ein
## zweites Mal, und zwar gegenlaeufig zur Feuerrate: Die Gatling haelt 60 Schuss, verfeuert sie
## aber in 4,2 Sekunden und braucht danach 4,5 Sekunden zum Trommelwechsel. Der Karabiner
## kommt mit 10 Schuss ueber 8,5 Sekunden und ist in 2,2 Sekunden wieder voll.
##
## Gerechnet ueber den ganzen Zyklus liegt der Dauerschaden aller fuenf zwischen 31 und 43 pro
## Sekunde — der Spitzenschaden dagegen zwischen 40 und 86. Die Waffen unterscheiden sich also
## stark darin, WIE sie ihren Schaden abliefern, und nur wenig darin, wie viel.
##
## Munitionsverbrauch ist ein Schuss pro Schuss (AmmoData): Die Gatling leert 180 Schuss in
## dreizehn Sekunden, der Karabiner braucht dafuer zweieinhalb Minuten.
const WEAPONS: Dictionary = {
	"karabiner": { "name": "Blei-Karabiner", "type": KINETIC, "base": 34, "fire_ms": 850,
		"spread_deg": 0.8, "mag": 10, "reload_ms": 2200, "acid": 0, "always": true },
	"gatling":   { "name": "Messing-Gatling", "type": KINETIC, "base": 6, "fire_ms": 70,
		"spread_deg": 7.0, "mag": 60, "reload_ms": 4500, "acid": 0, "always": false },
	"voltgun":   { "name": "Leydener Volt-Karabiner", "type": GALVANIC, "base": 22, "fire_ms": 420,
		"spread_deg": 1.6, "mag": 10, "reload_ms": 2400, "acid": 0, "always": false },
	"saeure":    { "name": "Säure-Sprüher", "type": ALCHEMICAL, "base": 11, "fire_ms": 240,
		"spread_deg": 4.5, "mag": 24, "reload_ms": 2800, "acid": 10, "always": false },
	"brenner":   { "name": "Dampf-Brenner", "type": THERMAL, "base": 9, "fire_ms": 130,
		"spread_deg": 5.5, "mag": 40, "reload_ms": 3200, "acid": 0, "always": false },
}

## Gegner-Statblöcke (Master-GDD §7.3). `ranged` = Fernkämpfer-Parameter.
## Reichweiten der Fernkaempfer: die Tabellenwerte stehen in PIXELN, hier gilt METER.
##
## Die `ranged`-Angaben stammen aus dem Web-Prototyp. Unumgerechnet waeren 150–360 Pixel
## 150–360 Meter — der Revolverheld haette aus einem Drittel Kilometer geschossen, weit
## ausserhalb der Sichtweite, in der er ueberhaupt erwacht.
##
## Der Faktor ist nicht geraten, sondern angelegt: Die groesste Reichweite der Tabelle (360)
## soll knapp INNERHALB des Aggro-Radius liegen (`OverworldView.AGGRO_M` = 16 m), sonst waere
## ein Schuetze in dem Augenblick, in dem er aufwacht, ausserhalb seiner eigenen Reichweite.
## 360 px = 12 m ergibt genau 1/30. Damit schiesst der Revolverheld von 5,0–12,0 m, das
## Konstrukt von 4,3–11,3 m — und die im Prototyp erprobten VERHAELTNISSE bleiben erhalten
## (das Konstrukt haelt weniger Abstand als der Revolverheld).
const RANGE_PX_TO_M: float = 12.0 / 360.0

## Sekunden, die eine Angriffs-Animation laeuft, BEVOR der Treffer sitzt.
##
## Ohne diese Verzoegerung faellt der Schaden in dem Bild, in dem die Animation ANFAENGT — man
## verliert Leben, waehrend der Gegner noch ausholt. Mit ihr liegt der Treffer da, wo das Auge
## ihn erwartet, und ein Wimpernschlag reicht, um aus der Reichweite zu gehen. Gemessen an den
## Clips: Der Schlag des Grenzgaengers trifft nach gut einem Drittel, der Schnellzieher des
## Revolverhelden frueher.
const WINDUP_MELEE_SEC: float = 0.34
const WINDUP_SHOT_SEC: float = 0.28

## Sekunden zwischen zwei Nahkampfschlaegen.
##
## Der Nahkampf war bisher ein Dauerschaden je Sekunde (`contact`), der floss, solange man in
## Reichweite stand — ohne Schlag, ohne Ausholen, ohne Pause. Als EINZELSCHLAG braucht er einen
## Takt. Der Schaden je Schlag ist `contact × dieser Takt`, die Schadensrate bleibt also exakt
## dieselbe wie vorher; es aendert sich nur, dass man sie sieht und ihr ausweichen kann.
const MELEE_INTERVAL_SEC: float = 1.1

## `nocturnal` = kommt nur im DUNKELN heraus (Nacht und Daemmerung, siehe `DayCycle.is_dark`).
##
## Das ist kein Schmuck, sondern der Grund, warum eine Uhr im Spiel etwas aendert: Wer bei Tag
## durch das Rattengestruepp laeuft, sieht Sand; wer es nach Sonnenuntergang tut, laeuft in ein
## Rudel. Damit wird die Tageszeit zu einer Entscheidung — und Quests koennen sie verlangen.
##
## Ratte und Klaeffer sind die beiden Schwaerme; genau bei ihnen faellt am meisten auf, ob eine
## Gegend leer oder voll ist.
const ENEMY_TYPES: Dictionary = {
	"outlaw":    { "name": "Grenzgänger", "class": BIOLOGICAL, "sub": "outlaw", "hp": 55, "speed": 82, "armor": 0, "contact": 12, "gold_min": 1, "gold_max": 3 },
	"fauna":     { "name": "Ölfresser-Ratte", "class": BIOLOGICAL, "sub": "fauna", "hp": 32, "speed": 122, "armor": 0, "contact": 9, "gold_min": 1, "gold_max": 2, "swarm": true, "nocturnal": true },
	"revolver":  { "name": "Revolverheld", "class": BIOLOGICAL, "sub": "outlaw", "hp": 48, "speed": 72, "armor": 0, "contact": 10, "gold_min": 2, "gold_max": 3, "ranged": { "min": 150, "max": 360, "dmg": 9, "rate": 1500 } },
	"konstrukt": { "name": "Konzern-Konstrukt", "class": MECHANICAL, "sub": "konstrukt", "hp": 95, "speed": 54, "armor": 15, "contact": 13, "gold_min": 2, "gold_max": 4, "ranged": { "min": 130, "max": 340, "dmg": 8, "rate": 1300 } },
	"klaeffer":  { "name": "Kessel-Kläffer", "class": MECHANICAL, "sub": "klaeffer", "hp": 40, "speed": 138, "armor": 5, "contact": 10, "gold_min": 1, "gold_max": 3, "swarm": true, "nocturnal": true },
	"goliath":   { "name": "Schwerer Ernter", "class": MECHANICAL, "sub": "goliath", "hp": 900, "speed": 40, "armor": 30, "contact": 28, "gold_min": 24, "gold_max": 24, "front_immune": true, "boss": true },
}

# ── Ableitungen ───────────────────────────────────────────────────────────────

## XP für einen Kill (Master-GDD §7.5): Superboss 300, Elite 50, sonst max(3, hp/11).
static func xp_for_kill(target) -> int:
	if target.is_superboss:
		return 300
	if target.is_elite:
		return 50
	return maxi(3, roundi(float(target.max_health) / 11.0))

## Effektive Säure-Potenz einer Waffe inkl. Waffen-Level (Säure-Sprüher +2/Stufe).
static func weapon_acid(weapon_id: String, weapon_level: int) -> int:
	var w: Dictionary = WEAPONS.get(weapon_id, WEAPONS["karabiner"])
	return int(w["acid"]) + (weapon_level * 2 if weapon_id == "saeure" else 0)
