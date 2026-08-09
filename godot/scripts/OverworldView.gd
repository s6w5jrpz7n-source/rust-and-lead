class_name OverworldView extends Node3D
## OverworldView — begehbarer Kraterboden im Produktions-Maßstab (Master-GDD §1.4/§1.6).
##
## Erste sichtbare Szene des Godot-Ports (Xogot-/Editor-tauglich, nur Primitives — keine
## Assets, lädt sofort). Alles wird zur Laufzeit aus den kanonischen `WorldManager`-Daten
## generiert: 5000×5000-m-Boden, Biom-Zonen, Sektor-Linien (Sprengtore/Smog), Kraterrand
## mit Rand-Tunnel, alle POIs als Landmarken. Dazu ein steuerbarer Spieler (4,7 m/s,
## virtueller Joystick + Tastatur), ein Gegner-Rudel bei Rustwater und Auto-Feuer über
## die ECHTEN Systeme (PlayerStats → CombatEngine → CombatTarget → GameState-XP/Gold).
## Truhen rollen echte Ausrüstung über `ProgressionManager`/`EquipManager` aus — Kämpfen wirkt
## sich dadurch sofort auf den nächsten Schuss aus (PlayerStats liest live aus GameState.equip).

# ── Kampf-Reichweiten: am SICHTBAREN Ausschnitt bemessen ─────────────────────
# Die Kamera zeigt bei 9,5 m Abstand und 50° Sichtfeld rund 15 m Breite und 13 m Tiefe um die
# Figur. Die alten Werte (32 m Schussweite, Spawn ab 140 m) stammen von einer viel weiter
# entfernten Kamera: der Spieler hat Gegner erledigt, die nie im Bild waren. Alles hier liegt
# jetzt INNERHALB des Ausschnitts — man sieht, worauf man schießt.
const AGGRO_M: float = 16.0          # Gegner erwachen, sobald sie im Bild sind
const SHOOT_RANGE_M: float = 11.0    # Auto-Ziel-Reichweite: gut sichtbar, nicht am Bildrand
const CONTACT_RANGE_M: float = 2.2   # Nahkampf-Kontakt
const ENEMY_SPEED_MS: float = 3.4    # Referenztempo (CombatData `speed` 100); Typen skalieren daran
## Ersatzbewegung für Modelle ohne Lauf-Animation (siehe `_scurry`).
const SCURRY_HZ: float = 9.0
const SCURRY_HOP: float = 0.09       # Anteil der Modellhöhe
const SCURRY_ROLL_RAD: float = 0.09
## Spawn liegt neben, nicht auf der Rustwater-Landmarken-Säule (die am exakten POI-Punkt steht).
const RUSTWATER_SPAWN_OFFSET: Vector3 = Vector3(0.0, 0.0, 25.0)   # 25 m südlich der Säule

# ── Kontinuierliches Spawning (echter Biom-Gegnermix aus WorldManager) ────────
const ENEMY_MAX: int = 12
const SPAWN_INTERVAL_SEC: float = 4.0
## Knapp außerhalb des Bildes bis kurze Laufdistanz — nah genug, dass Nachschub ankommt,
## solange man noch da ist, und weit genug, dass niemand vor der Nase aus dem Nichts auftaucht.
const SPAWN_MIN_DIST: float = 18.0
const SPAWN_MAX_DIST: float = 45.0
## Schwarm-Gegner (CombatData `"swarm": true` — Ölfresser-Ratten, Kessel-Kläffer) erscheinen
## als Rudel. Einzeln sind sie mit 32 Lebenspunkten weder gefährlich noch ein Bild.
const SWARM_MIN: int = 4
const SWARM_MAX: int = 7
const SWARM_SPREAD_M: float = 4.5

# ── Waffen (alle vier Schadensarten testbar — Kapitel-Gating folgt später über
# das Quest-/Reveal-System; dieser Sandbox-Screen ist bewusst ungesperrt). ────
const WEAPON_ORDER: Array = ["karabiner", "gatling", "voltgun", "saeure", "brenner"]
# Die Waffenzeichen stehen in `HudGlyph.Z` und nicht mehr hier: Jedes Zeichen des Spiels
# gehört an EINEN Ort, an dem die Prüfung nachsehen kann, ob die Schrift es überhaupt hergibt.
# Vorher stand hier eine Pistole als Emoji — im Spiel ein leeres Kästchen.
const TRACER_COLOR: Dictionary = {
	"karabiner": Color(0.98, 0.75, 0.14), "gatling": Color(0.95, 0.86, 0.55),
	"voltgun": Color(0.35, 0.75, 0.98),
	"saeure": Color(0.55, 0.85, 0.25), "brenner": Color(0.95, 0.42, 0.15),
}

# ── Truhen & Bodenbeute (Diablo-Achse) ────────────────────────────────────────
## Truhen sind SELTEN und stehen fest — nicht mehr alle 15 Sekunden eine im Umkreis von 220 m.
## Vorher waren sie damit ein Fließband: Man lief nirgendwo hin, sie kamen zu einem. Jetzt
## liegt genau eine am Mittelpunkt jedes Ortes außer dem Heimathafen — das Ziel eines
## Questlaufs ist damit auch das Ziel der Beute.
const CHEST_INTERACT_M: float = 3.0    # Reichweite für das Hand-Symbol
const CHEST_RESPAWN_SEC: float = 300.0 # geplünderte Truhe füllt sich nach 5 Spielminuten
const CHEST_RARITY_BIAS: float = 0.3   # etwas höher als Basis-Gegner-Loot -> Truhen lohnen sich
const CHEST_GEAR_MIN: int = 1
const CHEST_GEAR_MAX: int = 3

## Beim Öffnen fällt der Inhalt auf den Boden, statt still in die Taschen zu wandern. Der
## Streuradius ist bewusst klein: Man soll die Beute als HAUFEN sehen, nicht als Suchspiel.
const LOOT_SCATTER_M: float = 1.7
## Gold, Munition und Tränke sammeln sich beim Darüberlaufen auf — nur Ausrüstung will eine
## Entscheidung. Die Grundreichweite wächst mit der Magnet-Spule (`PlayerStats.magnet_dist`,
## Prototyp-Einheiten: 130 = Grundwert, +45 je Ausbaustufe).
const PICKUP_AUTO_BASE_M: float = 1.9
const PICKUP_HAND_M: float = 2.6       # Ausrüstung: Reichweite für das Hand-Symbol
## Farbe der Bodenbeschriftung = Seltenheit (GDD §7.4). Grau/Blau/Violett/Gold.
# ── Persistenz (SaveManager, seit Phase 2 fertig — hier zum ersten Mal an eine Szene
# angeschlossen): Slot 0 als laufender Spielstand dieser Sandbox. ──────────────
const SAVE_SLOT: int = 0
const AUTOSAVE_INTERVAL_SEC: float = 10.0

## Rustwater ist Schutzzone: innerhalb dieses Radius spawnt nichts Feindliches und es
## wird kein Dekor gestreut — die Stadt bleibt Stadt (GDD §1.6: befriedete Hubs).
## Befriedeter Umkreis: knapp außerhalb der Palisade (52 m) plus Bahnsteig-Vorfeld.
const TOWN_SAFE_M: float = 78.0
## Panzer-Rotte vor dem Tor beim Spielstart (der kontinuierliche Nachschub würfelt sie danach
## aus dem Biom-Mix — in der Wüste rund jeder zehnte Gegner, WorldManager.ENEMY_POOLS).
const STARTER_TANKS: int = 3

## Reiseziele (Tasten 1–5) sind exakt die Bahnhöfe — eine Liste, keine zweite Wahrheit.
const FAST_TRAVEL: Array = WorldManager.RAIL_STATIONS

const UiAssets = preload("res://scripts/UiAssets.gd")

const DialogData = preload("res://scripts/DialogData.gd")
const DialogBox = preload("res://scripts/DialogBox.gd")

const DayCycle = preload("res://scripts/DayCycle.gd")

const TownCollision = preload("res://scripts/TownCollision.gd")

# ── NPCs & Quests: der QuestManager ist seit Phase 2 fertig, hier zum ersten Mal
# an die sichtbare Welt angeschlossen. Auftraggeber stehen bei ihren Gebäuden. ──
const NPC_INTERACT_M: float = 4.5
## giver-Id (QuestManager.QUESTS[..].giver) → Anzeigename, Standort (Versatz vom Zentrum), Farbe.
## Jeder steht **vor seinem Haus** an der Straßenkante — Mabel vor dem Saloon, Silas vor der
## Schmiede, Doc vor dem Labor. Vorher standen sie auf einem eigenen Kreis irgendwo im Sand.
const TOWN_NPCS: Array = [
	["mabel", "Mamma „Rusty“ Mabel", Vector2(-5.0, 3.0), Color(0.85, 0.45, 0.35)],
	["silas", "Silas „Kupferauge“ Finch", Vector2(5.0, 3.0), Color(0.55, 0.50, 0.40)],
	["doc", "Doktor „Doc“ Aris", Vector2(5.5, 15.0), Color(0.88, 0.88, 0.90)],
]
## Material-Drops beim Kill — ohne sie ist die Sammel-Quest „Baumaterial: Schrott" unlösbar.
const DROP_TABLE: Array = [["schrott", 0.65], ["zahnrad", 0.22], ["dampfkern", 0.05]]

# ── Kamera (an Diablo-Immortal-Referenz eingemessen, GDD §1.5a) ───────────────
const CAM_FOV: float = 50.0     # eng statt Godots 75° — sonst wirkt die Figur winzig
## Abstand zur Figur. Sichtbare Höhe = 2·Abstand·tan(FOV/2) = 0,93·Abstand; bei 9,5 m sieht man
## also ~8,9 m, die 1,8-m-Figur füllt damit rund 20 % der Bildhöhe. Der frühere Wert (14 m)
## traf zwar die gemessenen 14 % der Vorlage, war am Bildschirm aber zu weit weg, um etwas
## zu erkennen — Spielbarkeit schlägt Messwert.
const CAM_DIST: float = 9.5     # Vorgabe; zur Laufzeit ueber CAM_ZOOM_STEPS verstellbar
const CAM_PITCH: float = 52.0   # Neigung nach unten (etwas flacher -> mehr von der Figur)
const CAM_YAW: float = 20.0     # leichte Gierung -> isometrischer Eindruck statt Frontalsicht

## Zoomstufen (Abstand Kamera→Figur in Metern) — BEWUSST von Hand statt automatisch.
##
## Automatisches Zoomen nimmt dem Spieler die Entscheidung ab und wechselt zuverlaessig im
## falschen Moment: beim Betreten der Stadt mitten im Gefecht, oder im Sekundentakt, wenn man
## am Ortsrand hin und her laeuft. In der Stadt und im Dungeon will man nah heran, fuer lange
## Wuestenwege weit heraus — das weiss nur, wer gerade spielt.
##
## Gemessen an der Bildhoehe (Sichthoehe = 2·Abstand·tan(FOV/2)) ist die Figur:
##   7,5 m -> 25,7 %   9,5 m -> 20,3 %   12,5 m -> 15,4 %   16,0 m -> 12,1 %
## Die Diablo-Vorlagen liegen bei 12–15 %; die weiteste Stufe trifft sie also genau, waehrend
## die Vorgabe naeher bleibt, weil auf dem Handy sonst nichts mehr zu erkennen ist. Weiter als
## 16 m lohnt nicht — bei 20 m waere die Figur 9,7 % hoch und damit nur noch ein Fleck.
const CAM_ZOOM_STEPS: Array = [7.5, 9.5, 12.5, 16.0]
const CAM_ZOOM_NAMES: Array = ["Nah", "Normal", "Weit", "Fern"]
const CAM_ZOOM_DEFAULT: int = 1
## Wie schnell der Zoom nachzieht (1/s). Springt er hart, verliert man die Orientierung.
const CAM_ZOOM_RATE: float = 6.0
## Fingerspreizung je Zoomstufe beim Kneifen.
const PINCH_PX_PER_STEP: float = 90.0
## Reichweite der Schattenkaskaden in Metern. Als Konstante, weil sie mit dem Zoom
## zusammenhaengt: Beim weitesten Zoom liegt die hintere Bildkante 27,8 m vom Objektiv — passt
## der Zoom kuenftig weiter heraus, muss dieser Wert mit. Ein Test rechnet das nach.
## Wie weit die Schatten reichen. 60 m war der Kompromiss einer wandernden Sonne. Seit sie
## feststeht (siehe `DayCycle`), zaehlt nur noch die Aufloesung: 38 m verteilen dieselbe
## 4096er Schattenkarte auf ein Drittel weniger Flaeche. Weiter als 38 m sieht man aus der
## Spielkamera ohnehin kaum Bodendetail.
const CAM_SHADOW_M: float = 38.0

## Versatz Kamera→Spieler beim gegebenen Abstand. Die Kamera behaelt ihre Ausrichtung IMMER —
## sie folgt nur der Position. Blickrichtung, Neigung und Gierung sind Weltkonstanten, kein
## Zustand der Figur. Frueher war das eine Konstante; seit der Abstand verstellbar ist, muss
## sie gerechnet werden.
func _cam_offset(dist: float) -> Vector3:
	return Vector3(
		sin(deg_to_rad(CAM_YAW)) * dist * cos(deg_to_rad(CAM_PITCH)),
		dist * sin(deg_to_rad(CAM_PITCH)),
		cos(deg_to_rad(CAM_YAW)) * dist * cos(deg_to_rad(CAM_PITCH)))

const CAM_FOLLOW: float = 10.0

# ── Virtueller Joystick (Finger und Maus, GDD §1.5) ───────────────────────────
const STICK_RADIUS: float = 96.0     # Pixel bis Vollausschlag
const STICK_DEADZONE: float = 10.0   # darunter passiert nichts (Zittern/Klick)
const MOUSE_STICK_ID: int = 9001     # eigene „Finger"-Id für die Maus (kollidiert mit keiner echten)
const TURN_RATE: float = 12.0        # wie schnell die Figur in die neue Richtung eindreht

# ── Waffe am Körper ───────────────────────────────────────────────────────────
## Knochen des Spieler-Rigs, an dem die Waffe haengen WIRD, sobald es eine Zweihand-Haltung
## gibt. Bis dahin sitzt sie an der Schulter (siehe `_equip_weapon_model`).
const WEAPON_BONE: String = "RightHand"
## Sitz im Griff — in Modell-Metern relativ zur Hand. Diese drei Zahlen kann man nicht
## ausrechnen, nur ansehen: sie sind der Stellknopf, wenn die Waffe schief in der Faust liegt.
## Gemessen im Bild, nicht geraten: Ohne Drehung lag der Karabiner QUER vor dem Bauch und
## zeigte nach rechts hinten — die Hand hielt ihn in der Mitte des Laufs, der Schaft ragte
## rechts heraus. Das Modell liegt entlang seiner X-Achse; +90° um Y drehen heisst, diese Achse
## auf Godots Vorne (−Z) zu legen. Der Versatz schiebt die Waffe dann so weit nach vorn, dass
## nicht ihre Mitte, sondern ihr Griffstueck in der Faust liegt.
const WEAPON_GRIP_OFFSET: Vector3 = Vector3(0.0, 0.02, -0.20)
const WEAPON_GRIP_ROT: Vector3 = Vector3(0.0, PI * 0.5, 0.0)   # Radiant (X, Y, Z)

# ── Bauliche Begrenzung (GDD §1.4a) ───────────────────────────────────────────
## Die Wüste ist offen, die Aktionszonen sind eng — und zwar durch ECHTE Bauten, nicht
## durch unsichtbare Wände: jedes Haus, jeder Palisadenpfosten, jedes Turmbein trägt sich
## beim Bauen selbst als Sperre ein (`_solid_box` / `_solid_pillar`). Was man sieht, blockt.
const PLAYER_RADIUS_M: float = 0.6
## Breite der Meldungszeile. Fest, damit sie mittig bleibt und nicht aus dem Bild waechst.
const TOAST_W: float = 720.0
## Wo die Meldungszeile sitzt — und wohin sie rutscht, solange der Kinobalken steht. Der reicht
## bis 78 px hinunter und deckte sie sonst zur Haelfte ab; ausgerechnet die Zeile zum Anflug
## („Rustwater. Licht in der Wueste.") war so nicht zu lesen.
const TOAST_TOP: float = 64.0
const TOAST_TOP_CINE: float = 92.0
## Aufloesung des Gelaendenetzes. Verfeinert von 0,5 auf 0,35 m, als aus der Schuessel eine
## Grube mit 66°-Waenden wurde: Bei 0,5 m Schrittweite steigt eine solche Wand je Viereck um
## 1,1 m — sichtbar treppig. Mit 0,35 m sind es 0,79 m, und die Kanten lesen sich als
## ausgewaschene Erde statt als Stufen. Kostet fuer die Schrotthalde (20 m Aussenradius)
## rund 33 000 Dreiecke; das ist der Preis fuer die einzige Gelaendeform im Spiel.
const TERRAIN_STEP_M: float = 0.35
## Zuschlag um jede Gelaendeform, damit der Flicken sicher auf y = 0 ausklingt, bevor die
## flache Restflaeche anschliesst.
const TERRAIN_MARGIN_M: float = 2.0
## Ausdehnung von Rustwater. Frueher war das der Palisadenradius, aus dem der Code die Mauer
## als Kreis gebaut hat — die Palisade wird inzwischen von Hand in `Rustwater.tscn` gestellt
## (siehe `_register_town`), und ein Kreis ist ohnehin nicht die einzige denkbare Form.
##
## Der Wert steuert jetzt nur noch, was NICHT von Hand gesetzt wird: die Groesse des Stadtbodens
## und die Frage, wo Pisten und Bahntrasse am Ortsrand enden. 84 m waren viel zu weit —
## Rustwater war ein Ring aus Einzelhaeusern mit zwanzig Metern Sand dazwischen, in dem man
## Schmiede und Wasserturm schlicht nicht fand. 52 m umschliessen den Stadtplan knapp.
const TOWN_R: float = 52.0

# ── Stadtplan Rustwater ───────────────────────────────────────────────────────
## Eine Hauptstraße von Süden (Tor bei 90°) nach Norden zum Platz, Kernbauten links und rechts
## davon, Hütten in Reihen dahinter, der Wasserturm am Kopfende als Blickfang. Alle Werte sind
## Versätze vom Stadtzentrum in Metern: **+x Ost, +z Süd**.
##
## Blickrichtung in Grad: **alle Fassaden zeigen zur Kamera**, nicht zur Straße. Das ist die
## Regel für eine feste Kamera und der Grund, warum isometrische Spiele „gestellt" wirken: Die
## Kamera steht immer 20° südöstlich (CAM_YAW), also sieht man von jedem Haus dieselbe Seite.
## Vorher schauten die Häuser einander an — die Schmiede stand damit 110° von der Kamera weg
## und zeigte zwangsläufig ihre Rückseite. Kleine Abweichungen je Haus, damit es nicht wie
## aufgereiht wirkt.
## Die Straße bleibt zwischen x = −6 und x = +6 frei, das sind zwölf Meter: eng genug, dass
## immer beide Seiten im Bild sind, breit genug für Kampf und Ausweichen.
const STREET_HALF_W: float = 6.0
## [Beschriftung, Registry-Name ("" = nur Platzhalter), Versatz, Blickrichtung, Ersatzmaße, Farbe]
const TOWN_LAYOUT: Array = [
	["♠ Gatling-Saloon", "saloon", Vector2(-13.5, 1.0), 14.0,
		Vector3(13.0, 8.5, 11.0), Color(0.45, 0.28, 0.16)],
	["⚒ Eiserne Schmiede", "forge", Vector2(13.5, 1.0), 28.0,
		Vector3(10.0, 7.0, 9.0), Color(0.36, 0.30, 0.27)],
	["♨ Destille", "", Vector2(-14.0, 17.0), 16.0,
		Vector3(11.0, 6.5, 9.0), Color(0.40, 0.34, 0.20)],
	["⚗ Alchemie-Labor", "", Vector2(14.0, 17.0), 25.0,
		Vector3(12.0, 6.0, 10.0), Color(0.30, 0.36, 0.31)],
	["", "water_tower", Vector2(-14.0, -18.0), 180.0,
		Vector3(9.0, 18.0, 9.0), Color(0.48, 0.38, 0.26)],
]
## Der Turm steht NEBEN dem Kopfende der Straße, nicht darauf: mit 9,4 m Breite würde er die
## zwölf Meter Gasse dichtmachen. Bei 18 m Höhe sieht man ihn von überall, auch von der Seite.
##
## Das gilt für die vom Code gebaute Stadt. Steht `Rustwater.tscn` zur Verfügung, ist SIE die
## Wahrheit — dort hat der Turm einen anderen Platz. Wer die Position braucht, fragt deshalb
## `_turm_punkt()` und nicht diese Konstante.
const TOWER_SPOT: Vector2 = Vector2(-14.0, -18.0)
## Hüttenplätze: zwei Reihen an der Straße, zwei Zeilen hinter den Kernbauten.
## Die editierbare Stadt-Szene. Liegt sie vor, wird sie geladen statt gebaut.
const TOWN_SCENE: String = "res://scenes/Rustwater.tscn"
## Radius des festen Stadtbodens — sieben Meter groesser als die Stadt selbst, damit eine
## Palisade auf dem Platz steht und nicht auf der Kante zwischen zwei Böden. Der Zuschlag ist
## genau dafür da: Wer die Mauer weiter aussen setzt, sollte diesen Wert mitziehen.
const TOWN_GROUND_R: float = TOWN_R + 7.0
const SHACK_SPOTS: Array = [
	Vector2(-11.0, 28.0), Vector2(11.0, 28.0),
	Vector2(-11.0, 36.0), Vector2(11.0, 36.0),
	Vector2(-11.0, 44.0), Vector2(11.0, 44.0),
	Vector2(-26.0, 8.0), Vector2(26.0, 8.0),
	Vector2(-26.0, -8.0), Vector2(26.0, -8.0),
]
## Gebäude-Kollision etwas kleiner als die Bounding-Box: Vordächer, Schornsteine und Anbauten
## stecken darin, und man soll am Haus entlanglaufen können, nicht an dessen Luftraum.
const BUILDING_COLLISION_SHRINK: float = TownCollision.GEBAEUDE_SCHRUMPF
## Notfall-Regel für Bauteile ohne feststellbaren Asset-Namen (rohe Meshes): Ab diesem
## Seitenverhältnis der Grundfläche gilt eines als WAND und wird nicht geschrumpft. Gemessen
## liegen die Häuser bei 1,01–1,56:1 und die Mauerstücke bei 2,13–16,22:1 — die Grenze sitzt
## genau in dieser Lücke. Der Regelfall läuft über `AssetRegistry.is_wall`.
const WALL_ASPECT: float = TownCollision.WAND_VERHAELTNIS

# ── Eisenbahn (GDD §1.4a): Schnellreise nur noch von Bahnhof zu Bahnhof ───────
const RAIL_GAUGE_M: float = 3.2        # Spurweite der Iron Rail (Breitspur, Panzerzug-tauglich)
const STATION_RANGE_M: float = 45.0    # so nah muss man am Bahnsteig stehen, um zu fahren
## Abstand des Bahnsteigs vom Ortsmittelpunkt — außerhalb von Rustwaters Palisade (52 m).
const STATION_OFFSET_M: float = 68.0
## Länge der Bahnsteighalle. Steht hier statt in `AssetRegistry`, weil daraus auch die
## Sperrfläche und der Abstand zum Gleis folgen — eine Zahl, drei Nutzer.
const STATION_LEN_M: float = 20.0
## Anteil der Gebäudetiefe, der SPERRT. Der Rest ist Bahnsteig unter dem Vordach: Dort steht
## man beim Einsteigen, dort erscheint die Fahrplan-Abfrage. Gemessen am Modell endet die
## Rückwand bei 67 % der Tiefe, davor liegt nur noch das Dach auf Stützen.
const STATION_SOLID_SHARE: float = 0.67

func _in_town(pos: Vector3) -> bool:
	return pos.distance_to(WorldManager.poi_scene_position("rustwater")) < TOWN_SAFE_M


# ── Erzählte Momente: Text, der auf die Bewegung wartet ───────────────────────
## Wer spricht, wenn der Held selbst spricht.
##
## Er hat keinen Namen — das ist Teil der Geschichte („Wer aus dem Schrott kommt, hat meistens
## keinen mehr"). Ein leeres Namensfeld saehe aber nach Fehler aus, und „DU" waere Erzaehlung
## statt Rede. Also das, was er in diesem Augenblick IST.
const HELD_NAME: String = "Der Namenlose"

## Mehrseitige Rede in der Sprechtafel — die Tafel wartet, der Spieler blättert.
##
## Bisher lief die Prolog-Erzählung durch `_say()`, also durch dieselbe Einblendung, die auch
## „Beutel voll" meldet: oben im Bild, hinter den Werten, nach vier Sekunden weg. Für einen
## Nebensatz reicht das; für den ersten Satz des Spiels nicht. Die Sprechtafel gibt es längst,
## sie stand nur den Auftraggebern allein zur Verfügung.
##
## Und der Held redet SELBST. Vorher stand dort ein Erzähler („Dein Schädel dröhnt") — das ist
## eine Stimme, die im ganzen restlichen Spiel nicht mehr vorkommt.
## Wie lange eine Zeile stehen bleibt, wenn niemand tippt.
##
## Aus der LAENGE, nicht als feste Zahl: „…hh. Mein Schädel." und ein Dreizeiler brauchen nicht
## dieselbe Zeit. Der Sockel ist die Pause zwischen zwei Saetzen, der Zuschlag das Lesen — grob
## zweihundert Zeichen in der Minute, also gemuetlich. Wer schneller ist, tippt.
const SPEECH_SOCKEL_SEK: float = 1.9
const SPEECH_JE_ZEICHEN_SEK: float = 0.052
static func speech_dauer(text: String) -> float:
	return clampf(SPEECH_SOCKEL_SEK + float(text.length()) * SPEECH_JE_ZEICHEN_SEK, 2.6, 9.0)


## Gesamtdauer einer Rede — damit eine Kamerafahrt sich danach richten kann statt umgekehrt.
static func speech_gesamt(zeilen: Array) -> float:
	var s: float = 0.0
	for z in zeilen:
		s += speech_dauer(String(z))
	return s


var _speech: Array = []
var _speech_name: String = ""
var _speech_giver: String = ""
var _speech_left: float = 0.0
## Jemanden sprechen lassen.
##
## Laeuft schon eine Rede DESSELBEN Sprechers, werden die Zeilen ANGEHAENGT statt sie zu
## ersetzen. Das ist kein Komfort, sondern eine Reparatur: Im Prolog beginnt der Held nach dem
## ersten Schuss einen Monolog von acht Zeilen, und mitten darin wird die Beute freigegeben —
## samt der ersten Steuerwalze, die ihrerseits reden will. Mit „ersetzen" brach der Satz ab, und
## was man las, war der Anfang eines Gedankens und das Ende eines anderen.
##
## Bei einem WECHSEL des Sprechers wird weiterhin ersetzt: Wenn Mabel etwas sagt, waehrend der
## Held noch denkt, hat sie das letzte Wort — sie steht ja vor einem.
func _play_speech(name_text: String, giver: String, zeilen: Array) -> void:
	if _dialog == null or zeilen.is_empty():
		return
	if not _speech.is_empty() and _speech_giver == giver:
		_speech.append_array(zeilen.duplicate())
		return
	_speech = zeilen.duplicate()
	_speech_name = name_text
	_speech_giver = giver
	_naechste_zeile()


func _in_speech() -> bool:
	return not _speech.is_empty()


func _naechste_zeile() -> void:
	if _dialog == null:
		return
	if _speech.is_empty():
		_dialog.visible = false
		_speech_left = 0.0
		return
	var zeile: String = String(_speech.pop_front())
	_dialog.show_line(_speech_name, zeile, _speech_giver)
	_speech_left = speech_dauer(zeile)


## Die Tafel blaettert von selbst weiter.
##
## Vorher wartete sie auf einen Tipp. Das ist richtig fuer ein Gespraech, in dem der Spieler
## gerade etwas entscheidet — und falsch fuer einen erzaehlten Augenblick, in dem er zusehen
## soll: Wer die Kamerafahrt betrachtet, tippt nicht, und dann steht der erste Satz bis zum
## Ende der Szene. Tippen bleibt moeglich und ueberspringt die Restzeit.
func _process_speech(delta: float) -> void:
	if _dialog == null or not _dialog.visible or _speech_left <= 0.0:
		return
	_speech_left -= delta
	if _speech_left <= 0.0:
		_naechste_zeile()


## Die Tafel wurde weggetippt. Erst blättern, dann beenden.
func _on_dialog_dismissed() -> void:
	if not _speech.is_empty():
		_naechste_zeile()
		return
	if _dialog != null:
		_dialog.visible = false
	_end_cine()


## Eine Folge von Textzeilen mit eigenen Einsätzen.
##
## `_say` kann einen Satz. Eine Szene besteht aber aus mehreren, und zwar zu bestimmten
## Zeitpunkten — der zweite Satz kommt, wenn die Figur aufgestanden ist, nicht wenn sie sich
## noch aufrappelt. Bisher hätte man dafür Timer-Knoten gebraucht oder alles in einen
## überlangen Satz gepresst.
##
## Bewusst eine flache Liste und kein Zustandsautomat: Ein erzählter Moment ist eine Abfolge,
## keine Verzweigung. Was verzweigt, ist das GESPRÄCH — und das gehört in die Dialogtabelle,
## nicht hierher.
##
## Einträge: `{ "t": Sekunde ab Start, "text": String, "sek": Anzeigedauer }`
var _beats: Array = []
var _beat_t: float = 0.0
func _play_beats(beats: Array) -> void:
	_beats = beats.duplicate()
	_beat_t = 0.0


func _process_beats(delta: float) -> void:
	if _beats.is_empty():
		return
	_beat_t += delta
	# Von vorne durchgehen und alles ausgeben, was fällig ist. Mehrere gleichzeitig fällige
	# Zeilen können nicht vorkommen, solange die Einsätze auseinanderliegen — und wenn doch,
	# gewinnt die letzte, was richtig ist: Bei einem Bildratenhänger will man den aktuellen
	# Stand sehen, nicht den übersprungenen.
	while not _beats.is_empty() and _beat_t >= float(_beats[0]["t"]):
		var b: Dictionary = _beats.pop_front()
		_say(String(b["text"]), float(b.get("sek", 4.0)))


## Das Aufwachen — der erste Augenblick des Spiels.
##
## Drei Dinge gleichzeitig: Die Figur steht auf (`Stand_Up1` liegt im Rig und wurde bisher nie
## benutzt), die Kamera kommt von oben herunter in die Spielhaltung, und der Text kommt in zwei
## Schüben statt als eine Wand.
##
## Warum von OBEN: Man liegt am Grund einer Grube. Der Blick von oben zeigt in einer Einstellung,
## wo man ist — mitten im Schutt, allein, ohne Weg nach draußen im Bild. Aus Spielerhöhe wäre es
## eine Nahaufnahme von Blech.
##
## Die alte Begrüßung („Willkommen im Krater — 5000 m Kante zu Kante") war ein Handbuch. Ein
## Spiel, das mit seinen eigenen Maßen anfängt, hat noch nicht angefangen.
## Wie lange das Aufwachen dauert — und warum nicht so lange wie der Clip.
##
## `Stand_Up1` dauert **8,27 s**. Die ersten Sekunden davon liegt die Figur nur da; das ist als
## Animation richtig und als Spielanfang eine Zumutung. Gezeigt wird deshalb das ENDE: Der Clip
## springt so weit hinein, dass er zusammen mit der Kamerafahrt aufhoert — man sieht das
## Hochstemmen, das Aufknien, das Aufstehen, und dann hat man die Steuerung.
##
## Die Zahl steht nicht doppelt da: Wie weit gesprungen wird, rechnet `_erwachen` aus der
## tatsaechlichen Clip-Laenge. Wer das Rig austauscht, bekommt automatisch den passenden
## Einsprung statt einer Figur, die zu frueh steht.
## Das Erwachen — der erste Augenblick des Spiels, und der laengste.
##
## Er dauert so lange, wie der Held zu reden hat. Nicht andersherum: Eine Kamerafahrt mit
## fester Laenge zwingt den Text in ihr Korsett, und was dabei herauskommt, sind vier
## Halbsaetze. Hier gibt `_wach_zeilen()` die Dauer vor, und die Kamera verteilt sich darauf.
##
## ## Die Kamera bleibt am KOPF
##
## Sie faengt dicht am Gesicht an — man sieht einen Mann im Dreck, bevor man sieht, wo er
## liegt. Waehrend er sich hochstemmt, wandert der Blickpunkt mit dem Kopf nach oben und die
## Kamera zieht sich zurueck; der Kopf bleibt dabei im Bild, der Ausschnitt wird groesser.
## Erst ganz zum Schluss gibt sie ihn frei und geht in die Spielhaltung.
##
## ## Er haelt zwischendurch inne
##
## `Stand_Up1` ist eine durchlaufende Bewegung — jemand steht auf, fertig. Wer nach Stunden im
## Schutt aufwacht, tut das nicht am Stueck: Er kommt auf einen Arm, bleibt liegen, versucht es
## noch einmal. Nachgebaut wird das mit ZWEI HALTEPUNKTEN, an denen der Clip stehenbleibt
## (`WACH_HALT`), und einem Grundtempo unter eins. Beides zusammen macht aus acht Sekunden
## Animation eine halbe Minute Aufstehen.
const WACH_HOCH_M: float = 16.0
const WACH_NAH_M: float = 1.15
const WACH_AUGE_M: float = 1.62
## Anteil der Szene, in dem er sich aufrichtet. Danach steht er und redet zu Ende.
const WACH_STEH_ANTEIL: float = 0.66
## Wo der Clip stehenbleibt, als Anteile der Aufsteh-Phase, und wie lange (Anteil der Phase).
const WACH_HALT: Array = [[0.30, 0.40], [0.63, 0.71]]
## Mindestdauer, falls einmal keine Zeilen da sind.
const WACH_SEK: float = 9.0

var _wach_left: float = 0.0
var _wach_total: float = 0.0
var _wach_tempo: float = 1.0

## Was er sagt, waehrend er sich aufrichtet.
##
## Der Held ist nicht Beobachter seiner selbst, sondern ein Mensch, der nicht weiss, wo er ist,
## wie er hierherkommt und wer er war. Genau in dieser Reihenfolge: erst der Koerper (Schaedel,
## Geschmack, das Klebrige im Haar), dann der Ort, dann die Frage nach ihm selbst — und die
## bleibt offen. Zum Schluss das Einzige, was jetzt zaehlt: Wasser, und etwas in der Hand.
##
## Dass die Frage nach dem Namen unbeantwortet stehenbleibt, ist der ganze Aufbau der Geschichte
## in einem Satz.
##
## Und der SCHLUSS nennt das naechste Ziel: „Der Fels da drueben." Damit begruendet die Szene
## die Fussspur, statt sie nur zu haben — der Spieler geht nicht einem Wegweiser nach, sondern
## dem, was die Figur gerade gesagt hat. Vorher endete sie mit „dann rede ich mit dem Ersten,
## der mir ueber den Weg laeuft", und das setzte voraus, dass er von Menschen weiss. Er weiss
## noch gar nichts.
static func _wach_zeilen() -> Array:
	return [
		"„…hh.“",
		"„Mein Schädel. Als hätte mir jemand einen Kessel drübergezogen und draufgeschlagen.“",
		"„Öl im Mund. Rost in der Nase. Und irgendwas Klebriges im Haar.“",
		"„…das ist Blut. Meins, nehm ich an.“",
		"„Wo bin ich hier? Blech. Fässer. Ein halber Zug.“",
		"„Eine Kippe. Ich lieg auf einer Müllkippe, in einer Pfütze aus irgendwas.“",
		"„Wie komm ich hierher? Denk nach. Irgendwas.“",
		"„Nichts. Kein Weg, kein Gesicht, kein gestern.“",
		"„Wer bringt einen Mann auf eine Halde und lässt ihn liegen? Und wofür?“",
		"„Wie heiße ich eigentlich.“",
		"„…“",
		"„Auch das noch nicht. Gut. Später.“",
		"„Wasser. Ich brauch Wasser, und was zu essen, und was zum Festhalten.“",
		"„Aber zuerst muss ich mich orientieren. Ich weiß ja nicht mal, wo ich hier bin.“",
		"„Da drüben ragt was aus dem Sand. Ein Fels, hoch genug.“",
		"„Von da oben sehe ich vielleicht mehr als Blech und Dreck.“",
	]


func _erwachen() -> void:
	if _cam == null or _player == null:
		return
	GameState.saw_wake = true
	var zeilen: Array = _wach_zeilen()
	_wach_total = maxf(speech_gesamt(zeilen) + 1.6, WACH_SEK)
	_wach_left = _wach_total
	# Tempo so, dass der Clip die Aufsteh-Phase ausfuellt — abzueglich der Zeit, die er
	# stillsteht. Aus der ECHTEN Cliplaenge, damit ein neues Rig nicht neu eingestellt werden
	# muss.
	var steh_sek: float = _wach_total * WACH_STEH_ANTEIL
	var halt_anteil: float = 0.0
	for h in WACH_HALT:
		halt_anteil += float(h[1]) - float(h[0])
	var laenge: float = AssetRegistry.clip_length(_player_model, "standup")
	_wach_tempo = clampf(laenge / maxf(steh_sek * (1.0 - halt_anteil), 0.5), 0.05, 2.0)
	AssetRegistry.play_clip(_player_model, "standup", false)
	var ap: AnimationPlayer = AssetRegistry.animation_player(_player_model)
	if ap != null:
		ap.speed_scale = _wach_tempo

	# Die Kamera: erst dicht am Kopf, dann mit ihm nach oben und zurueck.
	var p: Vector3 = _player.position
	# Die ersten vier Etappen haengen am KOPF (`"kopf": true`): `pos` ist ein Versatz von ihm,
	# geblickt wird auf ihn. Dadurch bleibt das Gesicht im Bild, waehrend es sich vom Boden bis
	# auf Augenhoehe bewegt — und der Ausschnitt wird nur groesser, weil der Versatz waechst.
	var kopf0: Vector3 = _kopf_welt()
	if kopf0.x >= INF:
		kopf0 = p + Vector3(0.0, 0.28, 0.0)
	var dreh := Basis(Vector3.UP, _player.rotation.y)
	_cam.position = kopf0 + dreh * Vector3(0.30, 0.42, -WACH_NAH_M)
	_cam.look_at(kopf0, Vector3.UP)
	# Alle Versaetze in SEINEM Bezugssystem: −Z ist vorn. Die Kamera steht also VOR ihm und
	# etwas ueber ihm — ein Gesicht sieht man von vorn, nicht von hinten.
	_play_flight([
		# 1. Am Gesicht. Ein Mann im Dreck, bevor man sieht, wo er liegt.
		{ "pos": Vector3(0.34, 0.44, -WACH_NAH_M), "kopf": true, "ziel": p,
			"sek": _wach_total * 0.22 },
		# 2. Er kommt auf den Arm — die Kamera weicht zurueck, der Kopf bleibt in der Mitte.
		{ "pos": Vector3(0.72, 0.62, -1.85), "kopf": true, "ziel": p, "sek": _wach_total * 0.24 },
		# 3. Auf die Knie. Jetzt ist der Oberkoerper im Bild.
		{ "pos": Vector3(1.15, 0.80, -2.55), "kopf": true, "ziel": p, "sek": _wach_total * 0.22 },
		# 4. Er steht. Weiter am Kopf, aber der Ausschnitt zeigt schon die Grube.
		{ "pos": Vector3(1.70, 1.15, -3.70), "kopf": true, "ziel": p, "sek": _wach_total * 0.20 },
		# 5. Und gibt ihn frei.
		{ "pos": p + _cam_offset(_cam_dist), "ziel": p + Vector3(0.0, 1.0, 0.0),
			"sek": _wach_total * 0.12 },
	])
	_wach_licht_setzen(p)
	_play_speech(HELD_NAME, "held", zeilen)


## Das Licht auf dem Helden — ein Abendrot, das die Kraterwand nicht durchlaesst.
##
## Der Prolog beginnt um 18:36. Die Sonne steht dann bei 54° … aber die Schrottgrube hat
## 66°-Waende, und in einem Krater ist tief stehendes Licht genau das, was NICHT ankommt. Der
## Grubenboden bekam nur Umgebungslicht, und die Figur war eine Silhouette ohne Gesicht — im
## ersten Augenblick des Spiels, in dem man ihr am naechsten ist.
##
## Also ein eigenes Licht, nur fuer diese Szene: warm, tief, von der Seite, wie die letzte
## Sonne, die ueber den Kraterrand faellt. Das ist kein Schummeln, sondern die Beleuchtung, die
## jede Filmszene bekommt — und es geht mit, wenn die Szene endet.
const WACH_LICHT_FARBE: Color = Color(1.0, 0.58, 0.30)
const WACH_LICHT_ENERGIE: float = 3.2
var _wach_licht: OmniLight3D = null
func _wach_licht_setzen(p: Vector3) -> void:
	if _wach_licht != null and is_instance_valid(_wach_licht):
		_wach_licht.queue_free()
	var l := OmniLight3D.new()
	l.light_color = WACH_LICHT_FARBE
	l.omni_range = 13.0
	l.light_energy = WACH_LICHT_ENERGIE
	l.shadow_enabled = false
	# Tief und seitlich VOR ihm — in seinem Bezugssystem, wie die Kamera. Streifendes Licht
	# zeichnet Falten und Kanten; von oben wird daraus ein flacher Fleck, und von hinten liegt
	# genau das im Schatten, was die Szene zeigen soll: sein Gesicht.
	var yaw: float = _player.rotation.y if _player != null else 0.0
	l.position = p + Basis(Vector3.UP, yaw) * Vector3(2.4, 1.5, -2.6)
	add_child(l)
	_wach_licht = l


## Wo der KOPF gerade wirklich ist — aus dem Skelett, nicht aus der Huelle.
##
## `_head_of` nimmt die waagerechte Knotenposition und die gemessene Oberkante. Das stimmt fuer
## jemanden, der STEHT. Wer liegt, hat seinen Kopf anderthalb Meter neben dem Knotenursprung
## und dreissig Zentimeter ueber dem Boden — die Kamera zielte im ersten Versuch punktgenau auf
## seine Stiefel.
##
## Der Knochen weiss es in jeder Haltung. Und weil er sich WAEHREND des Aufstehens bewegt,
## kann die Kamera ihm folgen, statt einer Reihe fester Zielpunkte hinterherzuraten: Der Kopf
## bleibt im Bild, wenn er hochkommt.
##
## `Vector3.INF`, wenn es kein Skelett oder keinen Kopfknochen gibt — dann greift der Aufrufer
## auf die Wegpunkte zurueck.
func _kopf_welt() -> Vector3:
	var skel: Skeleton3D = _skelett(_player_model)
	if skel == null:
		return Vector3.INF
	var i: int = skel.find_bone("Head")
	if i < 0:
		for b in skel.get_bone_count():
			if skel.get_bone_name(b).to_lower() == "head":
				i = b
				break
	if i < 0:
		return Vector3.INF
	return skel.global_transform * skel.get_bone_global_pose(i).origin


static func _skelett(root: Node) -> Skeleton3D:
	if root == null:
		return null
	if root is Skeleton3D:
		return root as Skeleton3D
	for c in root.get_children():
		var t: Skeleton3D = _skelett(c)
		if t != null:
			return t
	return null


## Die Aufsteh-Phase: Tempo und Haltepunkte.
func _process_wach(delta: float) -> void:
	if _wach_left <= 0.0:
		return
	_wach_left -= delta
	var ap: AnimationPlayer = AssetRegistry.animation_player(_player_model)
	if ap == null:
		return
	if _wach_left <= 0.0:
		ap.speed_scale = 1.0
		if _wach_licht != null and is_instance_valid(_wach_licht):
			_wach_licht.queue_free()
			_wach_licht = null
		return
	# Anteil der AUFSTEH-Phase (nicht der ganzen Szene): danach steht er und redet zu Ende.
	var f: float = (1.0 - _wach_left / maxf(_wach_total, 0.01)) / maxf(WACH_STEH_ANTEIL, 0.01)
	var haelt: bool = false
	for h in WACH_HALT:
		if f >= float(h[0]) and f < float(h[1]):
			haelt = true
	ap.speed_scale = 0.0 if haelt else _wach_tempo
	# Das Szenenlicht geht am Ende unter, waehrend die Kamera zurueckfaehrt — sonst erloescht
	# es auf einen Schlag und die Grube wird in einem Bild dunkel.
	if _wach_licht != null and is_instance_valid(_wach_licht):
		var aus: float = _wach_total * 0.18
		_wach_licht.light_energy = WACH_LICHT_ENERGIE * clampf(_wach_left / aus, 0.0, 1.0)


## Der Ausguck — die Rundsicht oben auf der Anhoehe.
##
## Zwischen Schrottgrube und Rustwater liegt eine 24 m hohe Anhoehe mit steiler Klippe auf der
## Stadtseite und einer Rampe auf der Grubenseite (siehe `WorldManager.TERRAIN`, „ausguck").
## Wer aus der Grube kommt, sieht sie vor sich, steigt hinauf, um sich zu orientieren — und
## genau dort oben nimmt die Kamera ihm die Sicht ab.
##
## Warum das der richtige Ort dafuer ist: Ein Ueberblick, den man sich ERGEHT, ist etwas anderes
## als einer, den man geschenkt bekommt. Der Held weiss nicht, wo er ist; er sucht sich den
## hoechsten Punkt und steigt hoch. Das ist eine Handlung, keine Zwischensequenz — die Kamera
## bestaetigt sie nur.
##
## Die Fahrt: erst zurueck und hoch, dann eine Umrundung UM IHN HERUM, damit sich der ganze
## Horizont hinter ihm dreht, dann ein Schwenk hinunter ins Tal auf Rustwater. Weitwinkel
## (`VISTA_FOV`) statt der engen Spielkamera — ein Ueberblick, der durch ein Fernrohr
## stattfindet, ist keiner.
const VISTA_FOV: float = 78.0
## Die Rundsicht folgt dem Muster der Aussichtspunkte in Assassin's Creed, und das besteht aus
## zwei Bewegungen, nicht aus einer:
##
##  1. **Eng und tief.** Die Kamera kommt von unten am Fels hoch und umrundet die Figur dicht —
##     sie ist gross im Bild, fast von unten gesehen, und der Horizont dreht sich HINTER ihr.
##     Das ist der Teil, der sagt: *er* steht da oben.
##  2. **Weit auf.** Danach zieht sie in einem Zug hinaus und hoch, bis die Figur klein und das
##     Land gross ist. Das ist der Teil, der sagt: *das* liegt vor ihm.
##
## Der ganze Effekt liegt im Verhaeltnis der beiden. Eine Umrundung auf mittlerer Distanz waere
## keins von beidem — sie zeigte eine Figur, die zu klein fuer ein Portraet und zu gross fuer
## eine Landschaft ist. Genau das war der erste Entwurf.
## Die Fahrt ist EINE Bewegung, keine Kette.
##
## Vorher waren es fuenf Etappen: von unten am Fels hoch, eng herum, in einem Zug weit hinaus,
## zurueck ueber die Schulter ins Tal, heim. Jede fuer sich war begruendet, und zusammen ruckelte
## es — weil an jeder Naht die Richtung sprang und `_flight_frame` jeden Abschnitt fuer sich
## sanft an- und abfaehrt. Aus fuenf sauberen Bewegungen wurden vier Bremsungen. Dazu tauchte die
## erste Etappe neun Meter UNTER den Standplatz, was aus dem Auftakt ein Hoch-Runter machte.
##
## Jetzt: eine Spirale. Die Kamera faehrt dort los, wo sie schon steht, dreht eine ganze Runde um
## die Figur und schraubt sich dabei hinaus und hoch — am weitesten bei etwa 55 % der Drehung —,
## kommt zum Ende der Runde wieder naeher heran und wird langsamer. Radius, Hoehe, Winkel und
## Bildwinkel laufen alle ueber DENSELBEN Parameter; es gibt keine Naht, an der etwas springen
## koennte. Danach nur noch zwei Dinge: der Schwenk auf Rustwater und das Verweilen dort.
const VISTA_FELS_M: float = 34.0       # groesster Abstand, in der Mitte der Drehung
const VISTA_FELS_H: float = 15.0       # und die Hoehe dort
const VISTA_ENDE_M: float = 11.0       # Abstand am Ende der Drehung — wieder nah bei ihr
const VISTA_ENDE_H: float = 3.2
## Wo im Bogen die Kamera am weitesten weg ist. 0,55 und nicht 0,5: Der Weg nach draussen darf
## etwas laenger dauern als der zurueck, sonst wirkt das Herankommen wie ein Rueckzug.
const VISTA_GIPFEL: float = 0.55
const VISTA_GRAD: float = 360.0
## Die Zeiten.
##
## 360° in 14 s sind 26°/s — unter der Grenze von 30°/s, ab der eine Establishing-Fahrt schmiert.
## Vorher waren es 230° in 6,6 s (35°/s), und das auf einem Kreis von 8,5 m Radius, wo der
## Vordergrund noch viel schneller durchs Bild zieht als bei 64 m um die Palisade.
const VISTA_SEK_RUNDE: float = 14.0
const VISTA_SEK_SCHWENK: float = 2.6
## Und dann bleibt die Kamera auf Rustwater STEHEN. Sechs Sekunden auf einem stehenden Bild sind
## viel; genau darum geht es. Der Ort ist das Ziel der naechsten Stunde Spielzeit, und bisher
## huschte er in vier Sekunden vorbei, waehrend die Kamera schon wieder unterwegs war.
const VISTA_SEK_STADT: float = 6.0
const VISTA_SEK_HEIM: float = 2.4
## Beim Verweilen enger: Aus 78° Weitwinkel ist Rustwater auf 500 m ein Fleck. 52° holen den Ort
## heran, ohne die Spielperspektive vorwegzunehmen.
const VISTA_STADT_FOV: float = 52.0

## Der Standplatz: der HÖCHSTE Punkt auf der rechten Kuppe.
##
## Drei Anläufe vorher, und alle drei erklären, warum es jetzt so gerechnet wird.
##
## Der erste Auslöser fragte nur den waagerechten Abstand zur Felsmitte ab — auf der Rampe ist
## man dort acht Meter zu tief, die Fahrt startete, und die Kamera lief durch den Berg. Der
## zweite zählte zusätzlich die Höhe: besser, aber immer noch geraten, denn *oben* heißt nicht
## *irgendwo*. Falsch war beide Male nicht die Formel, sondern der Ansatz — **ein Auslöser, den
## man nicht SIEHT, zwingt zum Raten.** Daher der leuchtende Ring, in den die Fußspur führt.
##
## Der dritte Anlauf maß die Vorderkante Richtung Rustwater. Das funktionierte, hatte aber einen
## Haken, den erst das Bild zeigte: Der Fels hat zwei Kuppen, und die Vorderkante liegt in der
## Senke dazwischen — man stand auf 14,7 m, während zwei Schritte weiter rechts 16,6 m gewesen
## wären. Wer sich auf einen Felsen stellt, um sich zu orientieren, stellt sich auf die höchste
## Stelle.
##
## Gesucht wird deshalb der **höchste Punkt der rechten Hälfte**, und „rechts" ist dabei nicht
## willkürlich: Es ist die Seite, auf die man beim Aufstieg zuläuft, gerechnet als Kreuzprodukt
## aus Blickrichtung und Hochachse — dieselbe Rechnung, die auch die Kamera für „rechts im Bild"
## benutzt.
##
## Ein Höhenmaximum allein reicht nicht: Eine Bergspitze ist der höchste Punkt und trägt keinen
## Ring von 1,8 m. Deshalb wird jeder Kandidat mit seinen acht Ringpunkten geprüft, und es
## gewinnt der höchste, auf dem der Reif noch ganz aufliegt. Damit wandert der Punkt mit, wenn
## jemand den Fels umbaut, statt als Zahl im Code zu veralten.
const VISTA_KANTE_TOL_M: float = 1.2
const VISTA_RING_R_M: float = 1.8
## Wie weit der Reif am Rand absacken darf, bevor der Platz als zu schmal gilt.
##
## 0,9 m — nachgemessen und nicht geschätzt. Bei 1,1 landet der Ring auf 16,1 m, 3,0 m rechts
## der Achse, und sein tiefster Rand liegt auf 15,3 m: Der Reif sackt also nur 0,8 m ab, die
## Toleranz war um einen Viertelmeter zu lasch. Bei 0,9 kommt exakt derselbe Punkt heraus, nur
## mit der schärferen Zusage. Enger geht es nicht: Bei 0,75 rutscht der Platz auf 15,9 m, bei
## 0,6 auf 15,3 m — dann steht man wieder fast auf dem Gipfelmittelpunkt statt auf der rechten
## Kuppe, und der Sinn der Sache wäre weg.
const VISTA_PLATZ_TOL_M: float = 0.9
var _vista_spot_cache: Vector3 = Vector3.ZERO
func _vista_spot() -> Vector3:
	# Gerechnet wird das EINMAL. `_maybe_vista()` fragt in jedem Bild, `_trail_goal()` auch, und
	# hier werden ein paar hundert Bodenhöhen abgetastet — der Fels bewegt sich dabei nie.
	if _vista_spot_cache != Vector3.ZERO:
		return _vista_spot_cache
	var f: Dictionary = _feature("ausguck")
	if f.is_empty():
		return Vector3.INF
	var mitte: Vector3 = WorldManager.feature_center(f)
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	var hin := Vector3(stadt.x - mitte.x, 0.0, stadt.z - mitte.z).normalized()
	# Rechts im Bild: Kreuzprodukt aus Blickrichtung und Hochachse.
	var rechts := Vector3(-hin.z, 0.0, hin.x)
	var suche: float = float(f["radius"]) * 0.45
	var best: Vector3 = Vector3(mitte.x, WorldManager.height_at(mitte.x, mitte.z), mitte.z)
	var best_h: float = -1e9
	var schritt: float = 0.5
	var n: int = int(suche / schritt)
	for ix in range(-n, n + 1):
		for iz in range(-n, n + 1):
			var off: Vector3 = rechts * (float(ix) * schritt) + hin * (float(iz) * schritt)
			# Nur die rechte Hälfte, und nur innerhalb des Suchkreises.
			if off.dot(rechts) <= 0.0 or off.length() > suche:
				continue
			var q: Vector3 = mitte + off
			var h: float = WorldManager.height_at(q.x, q.z)
			if h <= best_h:
				continue
			# Trägt der Platz den ganzen Reif? Acht Punkte auf dem Ring, keiner darf wegsacken.
			var traegt: bool = true
			for k in 8:
				var w: float = TAU * float(k) / 8.0
				var rx: float = q.x + cos(w) * VISTA_RING_R_M
				var rz: float = q.z + sin(w) * VISTA_RING_R_M
				if WorldManager.height_at(rx, rz) < h - VISTA_PLATZ_TOL_M:
					traegt = false
					break
			if not traegt:
				continue
			best_h = h
			best = Vector3(q.x, h, q.z)
	_vista_spot_cache = best
	return _vista_spot_cache


## Steht er im Ring? Das ist die ganze Bedingung.
##
## Waagerecht gemessen und ohne Höhenprüfung — die braucht es nicht mehr, seit der Punkt an der
## Kante liegt: Dorthin kommt man nur über die Kuppe. Der Parameter bleibt in der Signatur,
## damit die Aufrufstelle das Feature weiterhin einmal nachschlägt statt zweimal.
func _auf_ausguck(_f: Dictionary) -> bool:
	var spot: Vector3 = _vista_spot()
	if spot == Vector3.INF or _player == null:
		return false
	return Vector2(_player.position.x - spot.x, _player.position.z - spot.z).length() \
		<= VISTA_RING_R_M


func _maybe_vista() -> void:
	if GameState.saw_vista or GameState.prolog_done or _player == null:
		return
	if _in_cine() or _in_flight() or _overlay_open():
		return
	var f: Dictionary = _feature("ausguck")
	if f.is_empty():
		return
	if not _auf_ausguck(f):
		return
	GameState.saw_vista = true
	var p: Vector3 = _player.position
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	var zur_stadt := Vector3(stadt.x - p.x, 0.0, stadt.z - p.z).normalized()
	var heim: Transform3D = _cam.global_transform
	var brust: Vector3 = p + Vector3(0.0, 1.1, 0.0)
	var boden: Vector3 = Vector3(p.x, WorldManager.height_at(p.x, p.z), p.z)
	# Losgefahren wird DORT, WO DIE KAMERA STEHT. Kein eigener Anfangspunkt, kein Anfahren aus
	# einer anderen Ecke: Die erste Fassung tauchte neun Meter unter den Standplatz und kam von
	# unten am Fels hoch — im Bild ein Hoch-Runter, bevor die Fahrt ueberhaupt anfing. Wer bei
	# der Spielkamera beginnt, hat am Anfang gar keine Naht.
	var punkte: Array = spirale_punkte(boden, heim.origin, VISTA_GRAD,
		VISTA_FELS_M, VISTA_ENDE_M, VISTA_FELS_H, VISTA_ENDE_H, VISTA_GIPFEL,
		1.4, CAM_FOV, VISTA_FOV, VISTA_SEK_RUNDE)
	if punkte.is_empty():
		return
	# Der Schwenk auf Rustwater. Die Kamera bleibt fast stehen, nur der Blick wandert von ihr
	# hinueber ins Tal — und der Bildwinkel zieht dabei zu, damit der Ort nicht als Fleck am
	# Horizont endet. Das ist die einzige Stelle der Fahrt, die WEICH faehrt: ein einzelner,
	# eigenstaendiger Schwenk, kein Glied einer Kette.
	var schulter: Vector3 = p - zur_stadt * 6.0 + Vector3(0.0, 3.0, 0.0)
	punkte.append({ "pos": schulter, "ziel": stadt + Vector3(0.0, 6.0, 0.0),
		"sek": VISTA_SEK_SCHWENK, "fov": VISTA_STADT_FOV })
	# Und dann STEHENBLEIBEN. Gleiche Stelle, gleicher Blick, gleicher Bildwinkel — es bewegt
	# sich nichts, und das ist der Punkt: Der Ort ist das Ziel der naechsten Stunde Spielzeit.
	punkte.append({ "pos": schulter, "ziel": stadt + Vector3(0.0, 6.0, 0.0),
		"sek": VISTA_SEK_STADT, "fov": VISTA_STADT_FOV })
	punkte.append({ "pos": heim.origin, "ziel": heim.origin - heim.basis.z * 10.0,
		"sek": VISTA_SEK_HEIM, "fov": CAM_FOV })
	_play_flight(punkte)
	_play_speech(HELD_NAME, "held", [
		"„Von hier oben sieht man wenigstens etwas.“",
		"„Wüste. Wüste. Und noch mal Wüste.“",
		"„…da. Ganz hinten im Tal.“",
		"„Dächer. Ein Turm. Und Licht — da lebt jemand.“",
		"„Ein Fußmarsch. Aber der erste Weg, der irgendwohin führt.“",
	])


## Ein Gelaendestueck nach Kennung ({} = keins).
func _feature(id: String) -> Dictionary:
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == id:
			return f
	return {}


## Ein leuchtender Ring auf dem Boden: „hier hin".
##
## Gezeichnet, nicht als Modell — ein Ring ist zwei Zylinderringe und ein Material, und dafür
## lohnt keine Datei. Additiv und unbeleuchtet, damit er in der Dämmerung und nachts gleich gut
## zu sehen ist; ein beleuchteter Ring wäre im Schatten der Felskante genau dort unsichtbar, wo
## er gebraucht wird.
##
## Er ATMET (langsames Pulsieren). Ein stehender Ring liest sich als Bodendekoration; erst die
## Bewegung sagt „das gehört zu dir".
const MARKE_FARBE: Color = Color(1.0, 0.80, 0.38)
const MARKE_PULS_HZ: float = 0.55
## Wie breit das Band ist und wie hoch es über dem Fels liegt.
##
## Der erste Reif war 12 cm schmal und verschwand additiv über hellem Sand fast vollständig.
## 45 cm waren dann zu viel — bei 1,8 m Radius ist das ein Viertel davon, und aus flachem Blick
## ging der Reif in seine eigene Füllung über. 32 cm liest man aus jeder Entfernung und lässt
## den Platz in der Mitte noch als Platz erkennen.
const MARKE_BAND_M: float = 0.32
## Die schmale, dunklere Innenkante, die dem Band Tiefe gibt statt die Mitte zu fuellen.
const MARKE_KANTE_M: float = 0.14
const MARKE_LUFT_M: float = 0.06
var _marke: Node3D = null
## Ein Ring, der dem Fels FOLGT.
##
## Drei Anläufe, und die ersten beiden scheiterten am selben Punkt: Ein starrer Torus liegt auf
## einer Ebene, der Ausguck hat aber keine. Ohne Tiefentest lag der Reif deshalb über allem — im
## Bild trug die Figur ihn wie einen Hula-Hoop um die Hüfte, ein Kreis, den der Spieler nicht
## verdeckt, wenn er darin steht, liest sich als Bedienelement und nicht als Ort. Mit Tiefentest
## verschwand er ganz: Der Fels wellt sich über zwei Meter um mehr, als der Reif dick war.
##
## Also kein Fertigkörper, sondern ein **Band aus Dreiecken, dessen Ecken einzeln auf dem Boden
## sitzen** (`height_at()` + 6 cm). Es schmiegt sich an jede Beule, der Tiefentest kann anbleiben,
## und die Figur verdeckt es korrekt, sobald sie davorsteht.
func _marke_ring(pos: Vector3, radius: float) -> Node3D:
	var n := Node3D.new()
	var puls := Node3D.new()
	puls.name = "Puls"
	n.add_child(puls)
	# Additiv und unbeleuchtet: Der Ring soll glühen, nicht angestrahlt werden — auch mittags,
	# wenn der Fels heller ist als die Farbe selbst.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = MARKE_FARBE
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var band := SurfaceTool.new()
	band.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 48
	for i in seg:
		var w0: float = TAU * float(i) / float(seg)
		var w1: float = TAU * float(i + 1) / float(seg)
		var ecken: Array = []
		for w in [w0, w1]:
			for r in [radius - MARKE_BAND_M, radius]:
				var x: float = pos.x + cos(w) * r
				var z: float = pos.z + sin(w) * r
				# Ortsfest gerechnet, damit der Knoten selbst auf (0,0,0) stehen kann und die
				# Höhen unverändert bleiben, wenn `_process_marke` ihn skaliert.
				ecken.append(Vector3(x, WorldManager.height_at(x, z) + MARKE_LUFT_M, z))
		for idx in [0, 1, 3, 0, 3, 2]:
			band.add_vertex(ecken[idx])
	band.generate_normals()
	var reif := MeshInstance3D.new()
	reif.mesh = band.commit()
	reif.material_override = mat
	reif.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puls.add_child(reif)
	# KEINE Fuellscheibe mehr.
	#
	# Sie stand zuerst auf 0,16 Alpha, wurde im Betrieb auf 0,24 hochgezogen und dann auf 0,07
	# gedrosselt — und war in jeder dieser Fassungen falsch. Additiv ueber hellem Fels addiert
	# sich eine Flaeche zu einer Flaeche: Das Ergebnis war kein Ring mit einem Platz darin,
	# sondern eine leuchtende Scheibe. Die Begruendung dafuer („der blosse Umriss liest sich als
	# Loch") stimmt fuer einen duennen Strich; ein 32 cm breites Band ist keiner.
	#
	# Was den Kreis stattdessen lesbar macht, ist eine INNENKANTE: ein zweiter, schmalerer und
	# dunklerer Reif dicht am inneren Rand. Er gibt dem Band eine Tiefe, statt die Mitte zu
	# fuellen.
	var kante := SurfaceTool.new()
	kante.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r_i: float = radius - MARKE_BAND_M
	for i2 in seg:
		var v0: float = TAU * float(i2) / float(seg)
		var v1: float = TAU * float(i2 + 1) / float(seg)
		var ecken2: Array = []
		for v in [v0, v1]:
			for r2 in [r_i - MARKE_KANTE_M, r_i]:
				var kx: float = pos.x + cos(v) * r2
				var kz: float = pos.z + sin(v) * r2
				ecken2.append(Vector3(kx, WorldManager.height_at(kx, kz) + MARKE_LUFT_M, kz))
		for idx2 in [0, 1, 3, 0, 3, 2]:
			kante.add_vertex(ecken2[idx2])
	kante.generate_normals()
	var innen := MeshInstance3D.new()
	innen.mesh = kante.commit()
	var m2: StandardMaterial3D = mat.duplicate()
	m2.albedo_color = Color(MARKE_FARBE.r * 0.55, MARKE_FARBE.g * 0.42, MARKE_FARBE.b * 0.20, 1.0)
	innen.material_override = m2
	innen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puls.add_child(innen)
	add_child(n)
	return n


## Den Ring auf den Ausguck setzen — solange die Rundsicht noch aussteht.
func _build_vista_marke() -> void:
	if GameState.saw_vista or GameState.prolog_done:
		return
	var spot: Vector3 = _vista_spot()
	if spot == Vector3.INF:
		return
	_marke = _marke_ring(spot, VISTA_RING_R_M)
	# Die Schrift UNTER den Ring haengen, nicht neben ihn: Sie soll mit ihm verschwinden. Als
	# Geschwister blieb ein „◎ Aussicht" ueber leerem Fels stehen, nachdem die Rundsicht lief.
	var l: Label3D = _label(spot + Vector3(0.0, 1.9, 0.0), "◎ Aussicht", MARKE_FARBE,
		LBL_FIGUR, 120.0)
	l.reparent(_marke, true)


func _process_marke(_delta: float) -> void:
	if _marke == null or not is_instance_valid(_marke):
		return
	if GameState.saw_vista:
		_marke.queue_free()
		_marke = null
		return
	# Nur die Helligkeit atmet, nicht die Größe.
	#
	# Der Reif hat vorher zwischen 0,94 und 1,06 gepulst. Das ging, solange er ein Fertigkörper
	# an einer Knotenposition war; seit seine Ecken einzeln auf dem Boden sitzen, stehen sie in
	# WELTkoordinaten — eine Skalierung um den Knotenursprung schöbe den Ring über die halbe
	# Karte. Und ein Ring, der sich an den Fels schmiegt, soll ohnehin nicht wachsen: Er würde
	# bei jedem Schlag ein Stück über die Kante rutschen.
	var puls: Node3D = _marke.get_node_or_null("Puls") as Node3D
	if puls == null:
		return
	var t: float = sin(_flacker_t * TAU * MARKE_PULS_HZ) * 0.5 + 0.5
	for c in puls.get_children():
		var m: StandardMaterial3D = (c as MeshInstance3D).material_override
		m.albedo_color.a = lerpf(0.45, 1.0, t) * (1.0 if c.get_index() == 0 else 0.7)


## Geroell auf dem Ausguck.
##
## Die Formel liefert eine glatte Oberflaeche — richtig fuer Sand, falsch fuer Fels: Aus der
## Naehe sah der Ausguck aus wie ein Lehmhaufen. Was fehlt, ist das Kleinteilige, und dafuer
## gibt es keine Formel: Ein Fels ist ein Fels und Schutt an seinem Fuss.
##
## Gestreut wird nach STEILHEIT, nicht nach Zufallsposition: Broecken sammeln sich dort, wo
## etwas abbricht (an der Kante) und dort, wo es liegen bleibt (am Fuss); die glatte Flanke
## dazwischen bleibt frei. Das ist derselbe Gedanke wie beim Fels-Anstrich ueber die Hoehe —
## die Form entscheidet, nicht eine Liste von Koordinaten.
## 90 waren im Bild nicht zu sehen — auf einer Flanke von 30 m Radius sind das drei Steine je
## hundert Quadratmeter, und bei halber Modellgroesse verschwinden sie im Sandrauschen.
const AUSGUCK_STEINE: int = 300
func _dress_ausguck() -> void:
	var f: Dictionary = _feature("ausguck")
	if f.is_empty():
		return
	var mitte: Vector3 = WorldManager.feature_center(f)
	var reich: float = WorldManager.feature_reach(f) + 8.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	for i in AUSGUCK_STEINE:
		var w: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf()) * reich
		var x: float = mitte.x + cos(w) * d
		var z: float = mitte.z + sin(w) * d
		var y: float = WorldManager.height_at(x, z)
		if y < 0.3:
			continue   # draussen im Sand liegt kein Felsschutt
		# Steilheit an dieser Stelle: die Neigung der Gelaendenormalen.
		var steil: float = 1.0 - WorldManager.normal_at(x, z).y
		# Drei Lagen statt zwei: Auf den ABSAETZEN der Terrassen (flach, aber hoch oben) liegen
		# Broecken, die von der Stufe darueber gefallen sind; an den Stufen selbst haengt
		# Geroell; am Fuss sammeln sich Findlinge. Ohne die erste Lage bleiben die Baender
		# nackt, und genau sie sieht man aus der Kamerafahrt.
		var art: String = ""
		if steil > 0.22:
			art = "rock_small"
		elif y > 5.0 and rng.randf() < 0.45:
			art = "rock_small"
		elif y < 4.5 and rng.randf() < 0.60:
			art = "rock_boulder"
		if art == "":
			continue
		var hoehe: float = AssetRegistry.height_of(art) * rng.randf_range(0.55, 1.6)
		var n: Node3D = AssetRegistry.instantiate(art, hoehe)
		if n == null:
			continue
		n.position = Vector3(x, y, z)
		n.rotation.y = rng.randf() * TAU
		add_child(n)


## Rustwater betreten beendet den Prolog — einmalig.
##
## Ohne das wird `GameState.prolog_done` zwar gelesen (es entscheidet, wo eine Runde beginnt)
## und gespeichert, aber NIE gesetzt: Der Prolog endete nie, und jeder Start warf einen wieder
## auf die Kippe, auch mit zwei Kapiteln im Rücken.
func _check_prolog_done() -> void:
	if GameState.prolog_done or _player == null:
		return
	if not _in_town(_player.position):
		return
	GameState.prolog_done = true
	_play_speech(HELD_NAME, "held", [
		"„Rustwater. Es gibt sie also wirklich.“",
		"„Kupfer unter den Stiefeln. Fackeln am Tor. Hier wohnt jemand, der etwas zu verlieren hat.“",
		"„Im Saloon brennt Licht. Um die Zeit ist da noch wer wach.“",
		"„Ich hab keinen Namen, kein Geld und Blut im Haar. Mal sehen, wie weit ich damit komme.“",
	])

var _player: Node3D
var _cam: Camera3D
var _hp: float = 100.0
var _fire_cd: float = 0.0
var _spawn_cd: float = SPAWN_INTERVAL_SEC * 0.5   # erster Nachschub etwas früher
## Gefuehrte Waffe — "" heisst leere Haende. Das ist der Anfangszustand, nicht ein Fehler:
## Der Held erwacht ohne alles auf der Kippe.
var _weapon_id: String = ""
var _enemies: Array = []             # { node, target: CombatTarget, bar: MeshInstance3D }
var _chests: Array = []              # { node, label, pos: Vector3, looted: bool, cd: float }
## Beute am Boden: { node, label, kind, data, pos }. `kind` ist "gold" | "ammo" | "potion"
## | "material" | "gear" — die ersten vier sammeln sich von selbst auf, Ausrüstung nicht.
var _ground: Array = []
var _shimmer: float = 0.0            # Phase des Schimmerns am nächstgelegenen Fundstück
var _dry_cd: float = 0.0             # Drossel für den "kein Nachschub"-Hinweis
var _reload_left: float = 0.0        # Restdauer des laufenden Nachladens (0 = feuerbereit)
var _reload_total: float = 0.0       # Gesamtdauer, für die Fortschrittsanzeige
var _ground_tile_m: float = 2.5      # Kantenlaenge einer Bodentextur-Kachel (gemessen)
var _ammo_lbl: Label                 # Vorrat der getragenen Waffe, unter dem Schuss-Knopf
var _cam_dist: float = CAM_DIST      # aktueller Abstand, weich nachgezogen
var _zoom_btns: HBoxContainer        # +/− unter der Minikarte
var _hud_buttons: Array = []         # echte Knoepfe im HUD — duerfen den Joystick nicht ausloesen
var _touch_pos: Dictionary = {}      # Finger-Index -> Position (fuer das Kneifen)
var _pinch_a: int = -1               # die beiden Finger einer Kneifgeste
var _pinch_b: int = -1
var _pinch_ref: float = 0.0          # Fingerabstand beim Aufsetzen
var _pinch_zoom0: int = 0            # Zoomstufe beim Aufsetzen
var _zone_lbl: Label                 # Ortsschrift beim Betreten
var _zone_shown: String = ""         # welcher Ort zuletzt angesagt wurde
var _zone_t: float = 0.0             # Restzeit der Einblendung
var _npcs: Array = []                # { giver, name, node, label, pos: Vector3 }
var _actions: VBoxContainer          # Aktionsleiste unten (Sprechen, Bahnreise)
var _ctx: String = ""                # was gerade in Reichweite ist ("npc:silas", "station:…")
var _chest_spawn_cd: float = 3.0      # erste Truhe erscheint schnell
var _hud: Label
var _fire_btn: FireButton        # Schuss-Knopf unten rechts
# Der Abzug hat drei Quellen, die sich nicht gegenseitig ausschliessen duerfen: Auf dem Handy
# liegt EIN Finger auf dem Joystick und ein ZWEITER auf dem Knopf, am Rechner haelt man die
# Leertaste und zieht gleichzeitig mit der Maus. Deshalb je ein eigener Zustand statt eines
# gemeinsamen Flags — sonst loescht das Loslassen der einen Quelle die andere mit.
var _fire_key: bool = false      # Leertaste
var _fire_mouse: bool = false    # rechte Maustaste (links ist der Joystick)
var _fire_touch_id: int = -1     # Finger auf dem Knopf (-1 = keiner)
var _minimap: Minimap            # Nahansicht oben rechts (200-m-Umkreis)
var _world_map: Minimap          # dieselbe Klasse im Vollbild-Modus
var _map_overlay: Control        # Abdunklung + Weltkarte; unsichtbar, solange sie zu ist
var _shop: ShopScreen            # Werkstatt/Geschäfte; unsichtbar, solange zu
var _char: CharacterScreen       # Ausrüstung + Fähigkeiten
var _stick: VirtualStick
var _toast: Label
var _toast_until: float = 0.0
var _touch_id: int = -1
var _touch_start: Vector2 = Vector2.ZERO
var _touch_vec: Vector2 = Vector2.ZERO
var _save_loaded: bool = false
var _save_cd: float = AUTOSAVE_INTERVAL_SEC
var _blockers: Array = []            # rechteckige Sperren: { c: Vector2(x,z), h: Vector2 }
var _pillars: Array = []             # runde Sperren:       { c: Vector2(x,z), r: float }
var _rot_blockers: Array = []        # gedrehte Sperren:    { c: Vector2(x,z), h: Vector2, yaw }
var _stations: Array = []            # { id, pos: Vector3 } — Bahnsteige der Iron Rail
var _player_model: Node3D = null     # nur gesetzt, wenn ein echtes Modell geladen wurde
var _weapon_model: Node3D = null     # Waffe in der Hand (optional)
var _muzzle: Node3D = null           # Muendungspunkt, am Modell gemessen


func _ready() -> void:
	_load_or_init_save()   # vor allem Weiteren: GameState (Level/Gold/Ausrüstung) korrekt setzen
	_build_environment()
	_build_ground_and_biomes()
	_build_sector_lines_and_rim()
	_build_swamp()
	_build_railway()
	_build_pois()
	_build_township()
	_scatter_decor()
	_scatter_props()
	_fill_craters()
	_build_player()
	_build_hud()
	_build_npcs()
	_build_trail()
	_build_horse()
	_build_sfx()
	_build_riss()
	_build_steg()
	_build_moon()
	_spawn_pack()
	_build_chests()
	_dress_ausguck()
	_build_vista_marke()
	_build_stollen()
	_hp = float(PlayerStats.max_hp())
	# Wer aus dem Stollen kommt, kommt DORT heraus, wo er hineingestiegen ist — und nicht am
	# Startpunkt der Oberwelt, also unter Umstaenden quer ueber der Karte. Der Prolog bleibt
	# dabei aus: Wer schon einmal drin war, hat ihn laengst gesehen.
	if GameState.stollen_rueckkehr != Vector3.ZERO:
		_player.position = GameState.stollen_rueckkehr
		GameState.stollen_rueckkehr = Vector3.ZERO
		GameState.saw_wake = true
		_say("▲ Wieder an der Luft. Der Stollen liegt hinter dir.", 3.0)
		_update_hud()
		return
	# Das Erwachen haengt an `saw_wake`, NICHT daran, ob ein Spielstand geladen wurde. Vorher
	# hing es am Spielstand — und weil das Spiel automatisch speichert, bekam man die Szene nach
	# dem allerersten Start nie wieder zu sehen, auch nicht nach einem Zuruecksetzen.
	if not GameState.saw_wake and not GameState.prolog_done:
		# Erst der Film, dann das Erwachen — und wenn der Film fehlt, eben gleich das Erwachen.
		if not _vorspann_starten():
			_erwachen()
	elif _save_loaded:
		_say("❖ Spielstand geladen — Lv %d · %d ¤ · ▣ %d/%d" % [
			GameState.level, GameState.gold, EquipManager.worn().size(), EquipManager.GEAR_SLOTS.size()], 4.0)
	else:
		_say("☺ Willkommen im Krater — 5000 m Kante zu Kante. Ziehen (Maus/Finger) = laufen.", 5.0)


## Lädt den laufenden Spielstand (falls vorhanden), BEVOR irgendetwas anderes GameState liest
## (Leben/Schaden hängen an Level & Ausrüstung). Reine GameState-Mutation, keine Szenen-Abhängigkeit.
## Zwei Startschalter, beide fuer die Bauzeit am Anfang:
##
##   `--neu`     Spielstand loeschen und wirklich von vorn anfangen.
##   `--prolog`  Spielstand BEHALTEN (Level, Gold, Quests) und nur den Prolog zuruecksetzen.
##
## Der zweite ist der, den man beim Bauen tatsaechlich will: Wer nur pruefen moechte, ob das
## Aufwachen richtig aussieht, soll nicht jedes Mal seinen Fortschritt wegwerfen.
##
## Warum es die ueberhaupt braucht: Das Spiel speichert automatisch. Es gibt also keinen
## Zustand „noch nicht gespeichert" — wer einmal gestartet ist, faengt beim naechsten Mal mit
## Spielstand an und sieht das Erwachen in der Grube nie wieder.
##
## In Godot einzutragen unter *Projekt → Projekteinstellungen → Ausfuehren → Hauptargumente*;
## auf der Kommandozeile direkt anhaengen.
const ARG_NEU: String = "--neu"
const ARG_PROLOG: String = "--prolog"
func _load_or_init_save() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	if args.has(ARG_NEU):
		SaveManager.delete_slot(SAVE_SLOT)
	_save_loaded = SaveManager.has_slot(SAVE_SLOT)
	if _save_loaded:
		SaveManager.load_from_slot(SAVE_SLOT)
		if args.has(ARG_PROLOG):
			_prolog_zuruecksetzen()
	else:
		# Neues Spiel: Rustwater und Umgebung sind bekannt. Eine vollstaendig schwarze Karte
		# beim ersten Start haelt man fuer kaputt, nicht fuer eine Aufgabe.
		FogOfWar.fresh()


## `[F9]` — den Anfang noch einmal sehen, ohne in Einstellungen zu suchen.
##
## Die Startschalter (`--prolog`, `--neu`) funktionieren, stehen aber in den EDITOR-Einstellungen
## unter „Main Run Args" — und wer den Anfang zehnmal hintereinander pruefen will, will dabei
## nicht zehnmal durch ein Einstellungsfenster. Eine Taste im laufenden Spiel tut dasselbe.
##
## ZWEIMAL druecken. Ein einzelner Tastendruck, der die laufende Partie zurueckwirft, waere ein
## Fehler, den man nicht rueckgaengig machen kann — und `F9` liegt neben `F10` und `F11`.
const PROLOG_BESTAETIGUNG_SEK: float = 3.0
var _prolog_frage: float = 0.0
func _prolog_neu_anfordern() -> void:
	if _prolog_frage <= 0.0:
		_prolog_frage = PROLOG_BESTAETIGUNG_SEK
		_say("↺ Prolog von vorn? [F9] noch einmal drücken. (Fortschritt bleibt.)", 3.0)
		return
	_prolog_frage = 0.0
	_prolog_zuruecksetzen()
	# Erst schreiben, dann neu laden: Beim Neuaufbau liest `_load_or_init_save` die Datei, und
	# ohne das Schreiben stuende dort noch der alte Stand.
	SaveManager.save_to_slot(SAVE_SLOT)
	get_tree().reload_current_scene()


## Den Prolog noch einmal erleben, ohne den Spielstand zu verlieren.
##
## Zurueckgesetzt wird genau das, woran der Anfang haengt — und die WAFFEN, denn mit vollem
## Gewehr im Arm ist „leere Haende" keine Aussage mehr. Alles andere (Level, Gold, Quests,
## Nebel) bleibt, wie es war.
func _prolog_zuruecksetzen() -> void:
	GameState.prolog_done = false
	GameState.saw_rustwater = false
	GameState.saw_wake = false
	GameState.saw_vista = false
	GameState.erst_gegner_done = false
	GameState.hour = DayCycle.START_HOUR
	GameState.weapons = []
	GameState.equip.erase("weapon")
	GameState.weapon_id = ""


## Schreibt den Spielstand in festem Takt weg (Gold/Level/Ausrüstung/Kills — alles, was
## SaveManager.serialize() abdeckt). Reine Datei-I/O, kein Einfluss auf die laufende Szene.
func _process_autosave(delta: float) -> void:
	_save_cd -= delta
	if _save_cd <= 0.0:
		_save_cd = AUTOSAVE_INTERVAL_SEC
		SaveManager.save_to_slot(SAVE_SLOT)


# ── Weltaufbau ────────────────────────────────────────────────────────────────

func _mat(color: Color, unshaded: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3, pos: Vector3, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color, false, alpha)
	mi.position = pos
	add_child(mi)
	return mi


## Wie `_box`, aber die Grundfläche sperrt den Weg. Der Spielerradius wird schon beim
## Eintragen aufgeschlagen — der Lauftest ist damit ein reiner Punkt-in-Rechteck-Test.
func _solid_box(size: Vector3, pos: Vector3, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mi: MeshInstance3D = _box(size, pos, color, alpha)
	_blockers.append({
		"c": Vector2(pos.x, pos.z),
		"h": Vector2(size.x * 0.5 + PLAYER_RADIUS_M, size.z * 0.5 + PLAYER_RADIUS_M) })
	return mi


## Gedrehte Sperre: dieselbe Rechteck-Sperre, aber um `yaw` gedreht. Gebäude stehen im Kreis
## um das Stadtzentrum und schauen nach innen — eine achsenparallele Box würde dabei entweder
## in die Gasse ragen oder die Ecke des Hauses frei lassen.
func _solid_rect_rot(center: Vector3, half: Vector2, yaw: float) -> void:
	_rot_blockers.append({
		"c": Vector2(center.x, center.z), "yaw": yaw,
		"h": half + Vector2(PLAYER_RADIUS_M, PLAYER_RADIUS_M) })


## Runde Sperre (Säulen, Türme, Silos) — Radius inklusive Spielerradius.
func _solid_pillar(center: Vector3, radius: float) -> void:
	_pillars.append({ "c": Vector2(center.x, center.z), "r": radius + PLAYER_RADIUS_M })


## Steht dieser Punkt in einem Bauwerk? Grundlage der baulichen Begrenzung: in der Wildnis
## ist die Liste leer, in einer Aktionszone dicht — daher fühlt sich dieselbe Steuerung
## draußen weit und drinnen geführt an.
## Zu steil zum Hinaufgehen?
##
## Bis jetzt gab es keine Steigungsgrenze: Man lief die 66°-Wand der Schrottgrube hoch wie eine
## Fliege, und die Rampe war reine Deko. Das ist mit der Anhoehe nicht mehr tragbar — ihr ganzer
## Sinn ist, dass man IHREN Weg nimmt und oben ankommt, statt irgendwo die Klippe hochzulaufen.
##
## Nur BERGAUF wird gesperrt. Hinunter darf man ueberall: Wer von der Kante springt, hat sich
## dafuer entschieden, und eine Grenze in beide Richtungen wuerde jemanden festsetzen, der schon
## auf einem steilen Stueck steht.
##
## 1,0 ist die Tangente von 45°. Eine Duenenflanke (30°) laeuft man hoch, eine Kraterwand (57°
## im Mittel) nicht.
const MAX_STEIGUNG: float = 1.0
## Auf welcher Basislaenge die Steigung gemessen wird.
##
## Vorher wurde der EINZELSCHRITT gemessen, und der ist winzig: 4,7 m/s bei 60 Bildern sind 7,8 cm.
## Auf acht Zentimetern entscheidet nicht der Hang, sondern die Koernung — die aufgesetzten Buckel
## wellen den Fels um anderthalb Meter, und ein einzelner Kiesel darin ueberschreitet 45°, obwohl
## der Weg drumherum bequem ist. Das war das Haengenbleiben: nicht eine zu steile Flanke, sondern
## ein zu kurzes Massband.
##
## 0,7 m ist gut ein Schritt. Auf dieser Laenge misst man den HANG und nicht seine Oberflaeche.
const STEIGUNG_BASIS_M: float = 0.7
func _zu_steil(von: Vector3, nach: Vector3) -> bool:
	var d := Vector2(nach.x - von.x, nach.z - von.z)
	if d.length() < 0.001:
		return false
	var vor: Vector2 = d.normalized() * STEIGUNG_BASIS_M
	var hoch: float = WorldManager.height_at(von.x + vor.x, von.z + vor.y) \
		- WorldManager.height_at(von.x, von.z)
	return hoch / STEIGUNG_BASIS_M > MAX_STEIGUNG


func _blocked(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	for b in _blockers:
		var d: Vector2 = (q - Vector2(b["c"])).abs()
		if d.x <= float(b["h"].x) and d.y <= float(b["h"].y):
			return true
	for s in _pillars:
		if q.distance_to(Vector2(s["c"])) <= float(s["r"]):
			return true
	for r in _rot_blockers:
		var local: Vector2 = (q - Vector2(r["c"])).rotated(-float(r["yaw"])).abs()
		if local.x <= float(r["h"].x) and local.y <= float(r["h"].y):
			return true
	return false


## Echte Sand-PBR-Textur (Diffuse/Normal/ARM aus "ground_sand"), über die gesamte Fläche
## gekachelt — Kachelgröße wird aus den tatsächlichen Modell-Bounds abgeleitet (kein geratener
## Wert). Fällt auf die alte Einheitsfarbe zurück, solange kein Asset vorhanden ist.
func _ground_material() -> BaseMaterial3D:
	var mat: BaseMaterial3D = AssetRegistry.material_from_model("ground_sand")
	if mat == null:
		return _mat(Color(0.76, 0.64, 0.42))
	var tile_m: float = 2.5
	var probe: Node3D = AssetRegistry.instantiate("ground_sand")
	if probe != null:
		var sz: Vector3 = AssetRegistry.local_size(probe)
		tile_m = maxf(sz.x, sz.z)
		probe.queue_free()
	# UVs kommen jetzt in KACHEL-EINHEITEN direkt aus der Weltposition (siehe `_add_ground_quad`),
	# nicht mehr aus dem 0..1-Bereich einer Plane. Nur so passen Flicken und Restflaeche
	# nahtlos aneinander — sonst haette jedes Teilstueck seine eigene Kachelphase.
	_ground_tile_m = maxf(tile_m, 0.1)
	mat.uv1_scale = Vector3.ONE
	return mat


## Restflaechen des Bodens: die Weltflaeche minus der Bereiche, in denen Gelaende liegt.
## Rechteck-Subtraktion — je Form zerfaellt ein Rechteck in bis zu vier neue.
func _ground_rects() -> Array:
	var w: float = WorldManager.WORLD_METERS
	var rects: Array = [Rect2(Vector2(0.0, -w), Vector2(w, w))]
	for f in WorldManager.TERRAIN:
		var c: Vector3 = WorldManager.feature_center(f)
		# HALBAUSDEHNUNG, nicht Reichweite: Der Riss ist 10 m breit und 1900 m lang. Als Quadrat
		# um seine Reichweite gerechnet waere das Loch im Boden ein Drittel der Welt gross.
		var halb: Vector2 = WorldManager.feature_halb(f) + Vector2.ONE * TERRAIN_MARGIN_M
		var hole := Rect2(Vector2(c.x - halb.x, c.z - halb.y), halb * 2.0)
		var next: Array = []
		for r in rects:
			next.append_array(_subtract_rect(r, hole))
		rects = next
	return rects


## `a` minus `b` als Liste von Rechtecken (0 bis 4 Stueck).
func _subtract_rect(a: Rect2, b: Rect2) -> Array:
	if not a.intersects(b):
		return [a]
	var out: Array = []
	var x0: float = maxf(a.position.x, b.position.x)
	var x1: float = minf(a.end.x, b.end.x)
	if b.position.y > a.position.y:                       # Streifen oberhalb
		out.append(Rect2(a.position, Vector2(a.size.x, b.position.y - a.position.y)))
	if b.end.y < a.end.y:                                 # Streifen unterhalb
		out.append(Rect2(Vector2(a.position.x, b.end.y), Vector2(a.size.x, a.end.y - b.end.y)))
	var top: float = maxf(a.position.y, b.position.y)
	var bot: float = minf(a.end.y, b.end.y)
	if b.position.x > a.position.x:                       # Streifen links
		out.append(Rect2(Vector2(a.position.x, top), Vector2(b.position.x - a.position.x, bot - top)))
	if b.end.x < a.end.x:                                 # Streifen rechts
		out.append(Rect2(Vector2(b.end.x, top), Vector2(a.end.x - b.end.x, bot - top)))
	return out


## Flaches Bodenstueck. UV = Weltposition in Kacheln, damit alle Teilstuecke dieselbe
## Kachelphase haben und die Naht unsichtbar bleibt.
func _add_ground_quad(r: Rect2, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array = [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x, r.end.y), Vector2(r.position.x, r.end.y)]
	# Umlaufrichtung: siehe `_ist_vorderseitig` in den Tests. Sie stand hier jahrelang falsch
	# herum ([0,2,1 / 0,3,2]) — der Boden war damit RUECKSEITIG. Aufgefallen ist es nie, weil
	# das Sandmaterial aus dem CC0-Modell doppelseitig ist (`cull_mode = CULL_DISABLED`): Die
	# Flaeche blieb sichtbar, Godot dreht bei Rueckseiten aber die Normale um, und eine nach
	# UNTEN zeigende Normale bekommt keine Sonne. Gemessen lag die Helligkeit bei 0,24 statt
	# 0,96 — der ganze Boden der Welt lag nur im Umgebungslicht.
	for idx in [0, 1, 2, 0, 2, 3]:
		var p: Vector2 = corners[idx]
		st.set_normal(Vector3.UP)
		st.set_uv(p / _ground_tile_m)
		st.add_vertex(Vector3(p.x, 0.0, p.y))
	# Tangenten erzeugen, BEVOR das Netz festgeschrieben wird: Der Sandboden ist ein PBR-Satz
	# MIT Normalmap, und die wird im Tangentenraum gelesen. Ohne Tangenten rechnet der Shader
	# mit undefinierten Vektoren. (Gesucht war damit der Helligkeitsunterschied zwischen Boden
	# und Piste — der lag NICHT hieran und ist noch offen. Richtig ist es trotzdem.)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	# Eine waagerechte Flaeche kann keinen sinnvollen Schatten werfen — das spart auf dem Handy
	# die groesste Geometrie der Szene in jedem Schattendurchlauf.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Verformter Flicken ueber einer Gelaendeform. Die Hoehe kommt aus `WorldManager.height_at`,
## die Normale aus `normal_at` — also aus DERSELBEN Formel, aus der auch die Spielerhoehe
## kommt. Gemittelte Dreiecksnormalen waeren an der Naht zur flachen Flaeche sichtbar.
## Farbe und Übergangshöhe des Gesteins. Graubraun und entsättigt: Auf den hellen Sand
## multipliziert ergibt das Stein, ohne dass er sich vom Wüstenton löst — ein grauer Fels in
## gelbem Sand sähe aus wie hineinkopiert.
const FELS_TON: Color = Color(0.52, 0.45, 0.40)
const FELS_HOEHE_M: float = 4.5
var _fels_mat: BaseMaterial3D = null
func _fels_material(sand: Material) -> Material:
	if _fels_mat != null:
		return _fels_mat
	var m: BaseMaterial3D = (sand as BaseMaterial3D).duplicate() as BaseMaterial3D
	# Ohne das bleiben die Scheitelfarben ungenutzt und der Fels ist wieder Sand.
	m.vertex_color_use_as_albedo = true
	# Gestein ist matter als Flugsand — sonst glaenzt die Wand wie eine Duene.
	m.roughness = minf(1.0, m.roughness + 0.18)
	_fels_mat = m
	return m


func _add_terrain_patch(f: Dictionary, mat: Material) -> void:
	var c: Vector3 = WorldManager.feature_center(f)
	var halb: Vector2 = WorldManager.feature_halb(f) + Vector2.ONE * TERRAIN_MARGIN_M
	# Der Flicken deckt GENAU das Loch. Bei runden Formen ist er quadratisch wie bisher; beim
	# Riss ist er ein langer Streifen, und die Auflösung wird je Achse getrennt gerechnet —
	# sonst haette ein 1900 m langer Streifen quer dieselbe Punktdichte wie laengs und damit
	# gut anderthalb Millionen Dreiecke fuer einen zehn Meter breiten Spalt.
	# Auflösung je Form, nicht global: Die Grube braucht 0,35 m fuer ihre 66°-Wand, ein 220 m
	# breites Duenenfeld waere damit 940.000 Dreiecke — bei 19 m Wellenlaenge sieht man dort
	# 2 m nicht.
	#
	# Und je ACHSE, seit es den Riss gibt: Quer zu ihm zaehlt jeder halbe Meter, laengs sieht
	# man auf zweihundert nichts. `step_laengs` trennt beides; ohne die Trennung haette ein
	# 1900 m langer Streifen bei 0,5 m Punktabstand 45 Millionen Dreiecke.
	var schritt: float = float(f.get("step", TERRAIN_STEP_M))
	var schritt_l: float = float(f.get("step_laengs", schritt))
	var schritt_x: float = schritt if halb.x <= halb.y else schritt_l
	var schritt_z: float = schritt if halb.y <= halb.x else schritt_l
	var nx: int = maxi(8, int(ceil(halb.x * 2.0 / schritt_x)))
	var nz: int = maxi(8, int(ceil(halb.y * 2.0 / schritt_z)))
	var step_x: float = halb.x * 2.0 / float(nx)
	var step_z: float = halb.y * 2.0 / float(nz)
	# FELS statt Sand — aber ohne zweite Textur und ohne zweites Netz.
	#
	# Die Form allein macht keinen Felsen: Das Bild zeigte eine Sanddüne mit steilen Flanken,
	# weil überall dieselbe helle Sandtextur liegt. Eine eigene Gesteinstextur wäre ein zweiter
	# PBR-Satz und ein zweites Netz obendrauf; das ist viel Aufwand für eine Einfärbung.
	#
	# Stattdessen SCHEITELFARBEN. Der Boden-Shader multipliziert sie auf den Sand: Weiß lässt
	# ihn unverändert, ein graubraunes Grau macht daraus Stein. Der Übergang läuft über die
	# HÖHE — was mehr als vier Meter über der Ebene liegt, ist Fels, darunter blendet es in den
	# Sand. Genau das ist „aus dem Sand ragend": unten Sand, der sich anlegt, oben nackter Stein.
	var fels: bool = bool(f.get("fels", false))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var x0: float = c.x - halb.x + float(ix) * step_x
			var z0: float = c.z - halb.y + float(iz) * step_z
			# Dieselbe umgekehrte Umlaufrichtung wie beim flachen Bodenviereck — und derselbe
			# Grund, warum es nicht auffiel. Bei einer 66°-Wand wiegt es schwerer als beim
			# flachen Boden: Ohne Sonne hat die Wand keine Schattierung, und dann sieht man
			# die Grube ueberhaupt nicht mehr als Grube.
			for q in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1),
					Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x0 + q.x * step_x
				var pz: float = z0 + q.y * step_z
				var py: float = WorldManager.height_at(px, pz)
				st.set_normal(WorldManager.normal_at(px, pz))
				st.set_uv(Vector2(px, pz) / _ground_tile_m)
				if fels:
					st.set_color(Color.WHITE.lerp(FELS_TON,
						smoothstep(0.8, FELS_HOEHE_M, py)))
				st.add_vertex(Vector3(px, py, pz))
	# Tangenten erzeugen, BEVOR das Netz festgeschrieben wird: Der Sandboden ist ein PBR-Satz
	# MIT Normalmap, und die wird im Tangentenraum gelesen. Ohne Tangenten rechnet der Shader
	# mit undefinierten Vektoren. (Gesucht war damit der Helligkeitsunterschied zwischen Boden
	# und Piste — der lag NICHT hieran und ist noch offen. Richtig ist es trotzdem.)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _fels_material(mat) if fels else mat
	mi.name = "terrain_" + String(f["id"])
	add_child(mi)


var _sun: DirectionalLight3D = null
var _env: Environment = null
func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_energy = 1.6
	sun.light_color = Color(1.0, 0.94, 0.80)   # tiefstehende Wuestensonne, warm
	# ── Schatten: der groesste einzelne Unterschied zur Referenz ──────────────
	# Bis hierher warf NICHTS einen Schatten. Ohne ihn steht eine Figur nicht auf dem Boden,
	# sie klebt darauf — man sieht weder, wo sie aufsetzt, noch wie hoch etwas ist. In den
	# Diablo-Vorlagen wirft selbst der vorbeifliegende Rabe einen harten Schatten auf den Sand.
	sun.shadow_enabled = true
	# EINE Kaskade statt zwei. Aufgeteilt wird, um weit entfernte Schatten billiger zu machen —
	# bei 38 m Reichweite gibt es kein „weit entfernt" mehr, und die Naht zwischen zwei Kaskaden
	# ist eine sichtbare Kante, die man sich damit spart.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = CAM_SHADOW_M
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.1
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.55, 0.42)   # grüner Bronzehimmel (Story-Bibel)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.78)   # kuehler Himmelsanteil gegen die warme Sonne
	# Von 0,8 auf 0,32: Bei 0,8 Umgebung gegen 1,15 Sonne lag zwischen Licht- und Schattenseite
	# nur der Faktor 2,4 — deshalb wirkte jedes Objekt flach. Jetzt sind es rund 6.
	env.ambient_light_energy = 0.32
	# Godots Vorgabe ist lineares Tonemapping; helle Flaechen laufen damit aus und Sand wirkt
	# ausgewaschen. Filmic haelt die Lichter zusammen und vertieft die Schatten.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.5
	# Luftperspektive: In der Ferne blasst alles zum Himmel aus, das erzeugt Tiefe. Bewusst
	# duenn — Kraterrand und Eisernes Herz sollen als Landmarken am Horizont sichtbar bleiben.
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.62, 0.52)
	# Doppelt so dicht wie vorher, und aus einem Grund, den erst eine flache Kamera gezeigt hat:
	# Bei 0,0007 liegt auf 570 m ein Drittel Dunst — zu wenig, um die 350 m hohe Kraterwand am
	# Weltrand zu einem fernen Grat zu machen. Sie stand als brauner Klotz im Bild. Und Rustwater
	# war auf 255 m rasiermesserscharf, also so gross und so scharf wie ein Modell auf dem Tisch.
	#
	# Bei 0,0016 sind es auf 570 m zwei Drittel und auf 255 m ein Drittel: Die Weltgrenze wird
	# zum Dunststreifen, die Stadt bekommt Tiefe, und im Spielabstand (unter 40 m) merkt man
	# nichts davon. Luftperspektive hoch, damit der Dunst die Himmelsfarbe annimmt statt grau
	# davorzuliegen.
	env.fog_density = 0.0016
	env.fog_aerial_perspective = 0.85
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)
	# Die zweite gerichtete Lampe: der Mond. Sie steht dort, wo die Scheibe steht, und uebernimmt,
	# sobald die Sonne unter dem Horizont ist.
	var mond := DirectionalLight3D.new()
	mond.light_color = DayCycle.MOND_FARBE
	mond.light_energy = 0.0
	mond.shadow_enabled = true
	mond.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	mond.shadow_bias = 0.03
	mond.shadow_normal_bias = 1.1
	mond.directional_shadow_max_distance = sun.directional_shadow_max_distance
	add_child(mond)
	_moonlight = mond
	_sun = sun
	_env = env
	_apply_daytime()
	_apply_night_lights()


# ── Tageszeit ────────────────────────────────────────────────────────────────
## Die Uhr laeuft, das Licht folgt ihr.
##
## Warum ueberhaupt: Nachts wirft ein Muendungsfeuer zum ersten Mal Licht, das man SIEHT — bei
## Mittagssonne verpufft es. Dazu Gegner, die nur im Dunkeln aus ihrer Hoehle kommen, und
## Quests, die eine Uhrzeit verlangen. Die Rechnung dazu steht in `DayCycle`; hier wird sie nur
## angewendet.
##
## Nicht jeden Frame: Ein Spieltag dauert zwoelf Minuten, in einer Zehntelsekunde bewegt sich
## die Sonne um zwei Bogenminuten. Viermal je Sekunde reicht und ist unsichtbar.
const DAYTIME_INTERVAL: float = 0.25
var _daytime_cd: float = 0.0
func _process_daytime(delta: float) -> void:
	GameState.hour = DayCycle.advance(GameState.hour, delta)
	# Die Lichter JEDEN Frame: Sonne und Mond duerfen viermal je Sekunde nachziehen, eine Flamme
	# nicht — bei vier Stufen je Sekunde flackert sie nicht, sie stottert.
	_flacker_t += delta
	_apply_night_lights()
	_daytime_cd -= delta
	if _daytime_cd > 0.0:
		return
	_daytime_cd = DAYTIME_INTERVAL
	_apply_daytime()


# ── Nachtbeleuchtung ─────────────────────────────────────────────────────────
## Lichter, die mit der Dunkelheit angehen.
##
## Zwei Orte brennen die Nacht durch: der **Saloon** (der hat immer offen — bei Mabel ist immer
## jemand wach) und der **Bahnsteig** (eine Station ohne Licht findet nachts niemand, und man
## soll auch im Dunkeln reisen koennen).
##
## Warum das mehr ist als Stimmung: Eine Nacht, in der alles gleich dunkel ist, hat keine
## Orientierung. Ein warmer Fleck am Horizont sagt „dort ist die Stadt" — das ist dieselbe
## Aufgabe, die tagsueber der Wasserturm erfuellt.
##
## Die Lichter reichen ueber das Gebaeude hinaus auf den PLATZ davor: Ein Fenster, das leuchtet,
## ohne etwas anzuleuchten, ist ein Aufkleber.
const NIGHT_LIGHT_COLOR: Color = Color(1.0, 0.72, 0.38)   # Petroleum, warm
var _night_lights: Array = []
func _add_night_light(pos: Vector3, reichweite: float, energie: float,
		schatten: bool = false, glas_m: float = 0.55,
		farbe: Color = NIGHT_LIGHT_COLOR, flacker: float = 0.0) -> void:
	var l := OmniLight3D.new()
	l.light_color = farbe
	l.omni_range = reichweite
	l.light_energy = 0.0
	# Schatten kosten bei einem Punktlicht SECHS Schattenkarten. Ueber einem leeren Platz lohnt
	# das nicht — beim Licht IM Saloon schon: Ohne Schatten schiene es durch die Waende, und das
	# Haus saehe aus, als waere es aus Papier. Genau dieses eine Licht traegt den Effekt.
	l.shadow_enabled = schatten
	l.position = pos
	add_child(l)
	# Die Phase aus der Position: Vier Fackeln, die im Gleichtakt zucken, sehen aus wie ein
	# Wackelkontakt. Aus der Position abgeleitet statt gewuerfelt, damit dasselbe Licht bei
	# jedem Start gleich flackert — Zufall, der bei jedem Laden anders ausfaellt, ist keiner.
	_night_lights.append({ "node": l, "max": energie, "farbe": farbe,
		"flacker": flacker, "phase": fposmod(pos.x * 1.7 + pos.z * 2.9, TAU) })
	# Die Quelle selbst, damit man sie sieht und nicht nur ihren Schein.
	var glas := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(glas_m, glas_m)
	glas.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	glas.material_override = m
	glas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glas.position = pos
	add_child(glas)
	_night_lights[-1]["glas"] = glas


## Der Saloon leuchtet von INNEN.
##
## Der erste Versuch hat zwei Laternen vor die Tuer gestellt. Das beleuchtete den Platz, aber
## das Haus blieb ein dunkler Kasten mit einem Scheinwerfer davor — und der Saloon ist der Ort,
## an dem nachts noch jemand wach ist. Das muss man ihm ANSEHEN.
##
## Also: Kerzen und Laternen im Schankraum, und eine Laterne an der Tuer.
##
## Das Licht im Haus wirft SCHATTEN. Das ist der ganze Trick: Ohne sie schiene es durch die
## Waende, und der Saloon saehe aus, als waere er aus Papier. Mit Schatten kommt es nur dort
## heraus, wo das Modell Oeffnungen hat — durch Tuer und Fenster, und genau das ist das Bild.
##
## Nur EINES der Lichter wirft Schatten. Ein Punktlicht mit Schatten kostet sechs Schattenkarten;
## drei davon waeren achtzehn, fuer ein Haus. Die uebrigen sind Kerzen mit kleiner Reichweite —
## sie fuellen den Raum, sie muessen nicht hinaus.
const KERZE: Color = Color(1.0, 0.66, 0.30)
func _light_saloon(r: Dictionary, stadtmitte: Vector2) -> void:
	var mitte := Vector2(r["c"])
	var boden: float = WorldManager.height_at(mitte.x, mitte.y)
	var yaw: float = float(r["yaw"])
	var laengs := Vector2(cos(yaw), sin(yaw))
	var quer := Vector2(-laengs.y, laengs.x)
	# Der Schankraum: ein grosses Licht in der Mitte, das durch die Oeffnungen hinausfaellt …
	_add_night_light(Vector3(mitte.x, boden + 2.3, mitte.y), 16.0, 4.2, true, 0.0)
	# … und Kerzen an den Tischen, kurz und warm. Sie halten den Raum hell, auch wo das grosse
	# Licht von einem Balken verdeckt wird.
	for versatz in [Vector2(-0.45, -0.3), Vector2(0.5, 0.35), Vector2(-0.15, 0.55)]:
		var p: Vector2 = mitte + laengs * (r["h"].x * float(versatz.x)) \
			+ quer * (r["h"].y * float(versatz.y))
		_add_night_light(Vector3(p.x, boden + 1.25, p.y), 5.0, 1.3, false, 0.16, KERZE)
	# Die Laterne an der Tuer. Wohin „vor" zeigt, sagt die Stadtmitte — der Saloon steht an der
	# Strasse, und die fuehrt dorthin; damit stimmt es auch, wenn jemand das Haus umstellt.
	var zur_strasse: Vector2 = stadtmitte - mitte
	if zur_strasse.length() < 0.5:
		zur_strasse = Vector2(0.0, 1.0)
	zur_strasse = zur_strasse.normalized()
	var tuer: Vector2 = mitte + zur_strasse * (maxf(r["h"].x, r["h"].y) + 0.8)
	_add_night_light(Vector3(tuer.x, WorldManager.height_at(tuer.x, tuer.y) + 2.5, tuer.y),
		11.0, 2.2, false, 0.42)


## Die Esse in der Schmiede — das einzige Licht der Stadt, das nicht von einer Flamme im Glas
## kommt, sondern von gluehender Kohle.
##
## Deshalb hat sie eine eigene Farbe: tief orangerot, deutlich unter dem Petroleumgelb der
## Laternen. Zwei warme Lichter derselben Farbe waeren zwei Laternen; erst der Unterschied macht
## aus dem einen ein FEUER. Und sie flackert am staerksten von allem — eine Esse atmet, wenn der
## Blasebalg geht.
##
## Drei Lichter, jedes mit einer Aufgabe:
##
## 1. **Das Feuer selbst**, tief im Haus und mit SCHATTEN. Nur so faellt der Schein durch Tuer
##    und Fensterluke nach draussen statt durch die Waende — dieselbe Begruendung wie beim
##    Saloon, und aus demselben Grund traegt es hier auch die Schattenkosten.
## 2. **Der Widerschein**, weit, schwach, ohne Schatten, direkt ueber dem Boden. Godot rechnet
##    hier keine Lichtbrechung; was ein echtes Feuer ueber den Sand und die Hauswand zurueck
##    wirft, muss man von Hand hinstellen. Genau dafuer ist dieses Licht da — es soll man nicht
##    SEHEN, man soll den Boden gluehen sehen.
## 3. **Der Schornstein**, klein und hoch. Aus der Ferne — und der Anflug auf die Stadt kommt aus
##    der Ferne — ist das der Punkt, der sagt: hier arbeitet noch jemand.
const ESSE: Color = Color(1.0, 0.44, 0.14)
func _light_forge(r: Dictionary) -> void:
	var mitte := Vector2(r["c"])
	var boden: float = WorldManager.height_at(mitte.x, mitte.y)
	var deckel: float = float(r["deckel"])
	# Das Feuer steht nicht in der Mitte der Halle, sondern an der Wand — dort, wo der Amboss
	# Platz laesst. Ein Viertel nach hinten reicht, damit der Schein aus der Tuer schraeg faellt.
	var laengs := Vector2(cos(float(r["yaw"])), sin(float(r["yaw"])))
	var feuer: Vector2 = mitte + laengs * (r["h"].x * 0.35)
	_add_night_light(Vector3(feuer.x, boden + 1.05, feuer.y), 15.0, 3.6, true, 0.5, ESSE, 0.30)
	_add_night_light(Vector3(mitte.x, boden + 0.35, mitte.y), 23.0, 1.5, false, 0.0, ESSE, 0.22)
	_add_night_light(Vector3(mitte.x, deckel - 0.4, mitte.y), 6.0, 1.5, false, 0.30, ESSE, 0.34)


## Eine Fackel auf einem Torpfosten.
##
## `TownCollision` liefert ein Tor bereits als ZWEI Sperren — die beiden Pfosten, mit dem
## Durchgang dazwischen. Damit ist „links und rechts vom Tor" keine Rechnung mehr: Je Sperre
## eine Fackel, und sie sitzt richtig, auch wenn jemand das Tor im Editor dreht oder verschiebt.
##
## Sie steht OBEN AUF dem Pfosten, nicht daran. Von schraeg oben — und das ist die einzige
## Ansicht, die es im Spiel gibt — verschwindet eine Wandfackel hinter dem Balken, an dem sie
## haengt. Oben steht sie frei, und die beiden Flammen markieren die Toroeffnung wie zwei
## Landepunkte.
const FACKEL: Color = Color(1.0, 0.60, 0.24)
func _light_gate(r: Dictionary) -> void:
	var mitte := Vector2(r["c"])
	_add_night_light(Vector3(mitte.x, float(r["deckel"]) + 0.45, mitte.y),
		13.0, 2.6, false, 0.40, FACKEL, 0.20)


## Die Laterne im Wasserturm.
##
## Der Turm ist tagsueber die Landmarke, an der man Rustwater von weitem erkennt; nachts waere
## er ohne Licht ein schwarzer Fleck vor einem schwarzen Himmel — die Stadt haette dann genau
## die Silhouette verloren, an der man sie kennt. Das Licht sitzt UNTER dem Kessel, auf der
## Umlaufbuehne: hoch genug, dass es ueber die Palisade hinaus zu sehen ist, tief genug, dass es
## den Turm von unten anleuchtet statt in den Himmel zu strahlen.
##
## Weite Reichweite, wenig Energie: Es soll den Turm zeichnen, nicht den Platz darunter
## ueberstrahlen — dafuer sind die Fackeln und der Saloon da.
func _light_tower(r: Dictionary) -> void:
	var mitte := Vector2(r["c"])
	var boden: float = WorldManager.height_at(mitte.x, mitte.y)
	var hoehe: float = maxf(float(r["deckel"]) - boden, 4.0)
	_add_night_light(Vector3(mitte.x, boden + hoehe * 0.72, mitte.y),
		22.0, 2.4, false, 0.55, NIGHT_LIGHT_COLOR, 0.10)


## Wie weit reicht Rustwater? Groesster Abstand der Palisade von der Ortsmitte.
##
## Aus dem gemessenen Umriss, nicht aus einer Zahl: Wer im Editor ein Mauerstueck nach aussen
## setzt, verschiebt damit auch die Kamerafahrt, die aussen herumfliegen soll.
func _ort_radius() -> float:
	var groesste: float = 0.0
	for r in _wall_umriss:
		groesste = maxf(groesste, float(r))
	return groesste if groesste > 5.0 else 42.0


## Der Anflug auf Rustwater — einmal im Spiel, beim ersten Anblick der Stadt.
##
## Der Held erwacht in der Daemmerung auf der Kippe; waehrend er losgeht, wird es Nacht. Wenn
## Rustwater in Sicht kommt, uebernimmt die Kamera: erst in SEINE Sicht, damit man das sieht,
## was er sieht — eine beleuchtete Stadt in einer dunklen Wueste —, dann hinueber, um den
## Wasserturm herum und zurueck in die Spielhaltung.
##
## Der Turm ist nicht zufaellig das Ziel der Kurve: Er ist die Landmarke, an der man Rustwater
## von weitem erkennt, und die Fahrt sagt „das ist der Ort, auf den du zulaeufst", ohne ein
## Wort dafuer zu brauchen.
## Ab welcher Entfernung uebernimmt die Kamera?
##
## GEMESSEN, nicht geschaetzt: Bei 200 m ist Rustwater nachts ein schwarzer Streifen am
## Horizont. Die Nachtlichter haben 11 bis 23 m Reichweite; was davon auf 200 m ankommt, sind
## ein paar Pixel unterhalb der Nebelgrenze. Der Held sollte „eine beleuchtete Stadt in dunkler
## Wueste" sehen und sah nichts.
##
## Bei 95 m steht der Wasserturm als Silhouette im Bild, die vier Torfackeln sind einzeln zu
## erkennen und der Sand vor der Palisade glueht warm. Das ist das Bild, auf das der Anfang
## zulaeuft — also faengt der Anflug dort an.
const INTRO_SIGHT_M: float = 95.0
const INTRO_EYE_M: float = 1.62
## Die Umrundung: Abstand, Bogen, Hoehe am Anfang und am Ende.
##
## Umrundet wird die PALISADE, nicht der Wasserturm.
##
## Der erste Entwurf kreiste um den Turm, weil er die Landmarke ist. Im Bild war das aber eine
## Fahrt um ein Fass: Der Turm fuellte den Rahmen, die Stadt lag als Streifen dahinter, und die
## halbe Umrundung schaute nach draussen in die Wueste, weil der Turm am Ortsrand steht.
##
## Um die Mauer herum, mit dem Blick nach INNEN, zeigt jede Sekunde dasselbe Motiv aus einer
## neuen Richtung: den beleuchteten Ort. Der Turm ist dabei nicht weg — er dreht sich als
## Silhouette durch das Bild, so wie man ihn beim Herangehen auch sieht.
##
## Der Radius kommt aus dem tatsaechlichen Umriss der Palisade (`_wall_umriss`) plus Abstand;
## eine feste Zahl waere in dem Moment falsch, in dem jemand im Editor ein Mauerstueck
## versetzt.
##
## **Eine GANZE Runde**, und das ist eine Folge des Rueckwegs. 250° schwenkten mit knapp 30°/s —
## die Grenze, ab der eine Establishing-Fahrt schmiert —, also wurden daraus 230°. Beides endete
## aber auf der GEGENUEBERLIEGENDEN Seite des Ortes, und damit war der Heimweg 173 m lang. Im
## Anflugtempo sind das zwoelfeinhalb Sekunden allein fuer den Rueckflug; mit fester kurzer
## Dauer war es stattdessen ein Sprung mit 48 m/s.
##
## Bei 360° endet die Umrundung dort, wo sie angefangen hat — auf der Seite der Figur. Der
## Rueckweg ist dann der Hinweg rueckwaerts: dieselbe Strecke, dieselbe Dauer, dasselbe Tempo.
## Das ist nicht nur kuerzer als die 230°-Fassung (26 s statt 30 s), es ist auch der einzige
## Bogen, bei dem „zurueck wie hin" ueberhaupt eine Bedeutung hat.
const INTRO_ORBIT_RAND_M: float = 22.0
const INTRO_ORBIT_GRAD: float = 360.0
const INTRO_ORBIT_H0: float = 24.0
const INTRO_ORBIT_H1: float = 40.0
## Worauf geblickt wird: die Stadtmitte, etwas ueber den Daechern. Tiefer und man sieht die
## Rueckseite der naechsten Huette, hoeher und der Ort rutscht aus dem Bild.
const INTRO_BLICK_H: float = 7.0

## Die Zeiten. Zusammen **sechzehn Sekunden**.
##
## Erst waren es acht, und das war zu schnell: Die Umrundung schaffte 45°/s — das ist kein
## Herumfahren mehr, das ist ein Schwenk. Verdoppelt wird die GANZE Fahrt, nicht nur die
## Umrundung: Was hier zaehlt, ist das Verhaeltnis der Etappen zueinander, und wer nur eine
## davon streckt, verschiebt die Betonung, statt Zeit zu geben.
##
## Die Verteilung ist der eigentliche Inhalt: Nicht jede Etappe bekommt gleich viel, sondern
## jede bekommt so viel, wie ihr TEMPO sein soll. Der Anflug legt rund 95 m in 2,8 s zurueck
## (34 m/s) — das bleibt der schnelle Teil. Die Umrundung schafft 190° in 8,4 s (23°/s), und
## weil sie mehr als die Haelfte der Fahrt bekommt, wirkt sie ruhig, obwohl sie sich dauernd
## bewegt. Der Rueckweg ist mit zwei Sekunden der kuerzeste Abschnitt.
##
## **Der Rueckweg dauert so lange, wie er braucht.** Er ist als einziger Abschnitt keine feste
## Zahl, sondern eine Rechnung: Weg geteilt durch das Tempo des Anflugs. Vorher standen dort
## 1,2 s, und weil die Umrundung auf der anderen Seite des Ortes endet, war das ein Sprung —
## rund 48 m/s gegen 14 m/s beim Hereinfliegen. Im Bild sah das aus, als haette jemand die Fahrt
## abgebrochen.
##
## Eine feste Zahl kann das auch nicht loesen: Wo die Umrundung endet, haengt am Bogenwinkel,
## und wie weit es von dort nach Hause ist, am Standort der Figur. Beides darf sich aendern,
## ohne dass das Tempo kippt — also wird gerechnet und nicht eingetragen.
const INTRO_SEK_BLICK: float = 2.0
const INTRO_SEK_ANFLUG: float = 2.8
const INTRO_SEK_RUNDE: float = 13.3
## Untergrenze fuer den Rueckweg, falls die Figur schon fast in der Stadt steht.
const INTRO_SEK_HEIM_MIN: float = 1.6
## Der Blick auf Figur UND Stadt, bevor die Fahrt endet.
const INTRO_SEK_ZEIGEN: float = 1.6
## Das Einschwenken in die Spielperspektive — kippen und heranziehen, nicht schneiden.
const INTRO_SEK_EINSCHWENKEN: float = 1.6
## Wie weit hinter der Figur und wie hoch die Kamera fuer diesen Blick steht. Weiter zurueck als
## die Spielkamera und hoeher: Anders passen Figur im Vordergrund und Ort am Horizont nicht in
## dasselbe Bild.
const INTRO_RUECK_M: float = 26.0
const INTRO_RUECK_H: float = 13.0
func _maybe_intro_flight() -> void:
	if GameState.prolog_done or GameState.saw_rustwater or _player == null:
		return
	if _in_cine() or _in_flight() or _overlay_open():
		return
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	var flach := Vector3(stadt.x - _player.position.x, 0.0, stadt.z - _player.position.z)
	if flach.length() > INTRO_SIGHT_M:
		return
	GameState.saw_rustwater = true
	var hin: Vector3 = flach.normalized()
	var auge: Vector3 = _player.position + Vector3(0.0, INTRO_EYE_M, 0.0)
	# Der Kreis liegt um die MITTE des Ortes, sein Radius kommt aus der Palisade selbst.
	var mitte := Vector3(stadt.x, WorldManager.height_at(stadt.x, stadt.z), stadt.z)
	var radius: float = _ort_radius() + INTRO_ORBIT_RAND_M
	# Angefangen wird dort, wo die Kamera herkommt — auf der Seite der Figur. Sonst muesste sie
	# erst quer ueber die Stadt, bevor der Kreis ueberhaupt beginnt.
	var start: Vector3 = mitte - hin * radius + Vector3(0.0, INTRO_ORBIT_H0, 0.0)
	# Wohin die Fahrt am Ende zurueckkehrt: GENAU dorthin, wo sie angefangen hat. Nicht „ueber
	# die Figur nach `_cam_offset` gerechnet" — das waere dieselbe Haltung nur solange niemand
	# den Zoom verstellt hat. Die Ausgangshaltung merken und wieder anfahren ist die Zusage,
	# die man geben will: Nach dem Anflug steht das Bild wieder da, wo es stand.
	var heim: Transform3D = _cam.global_transform
	var punkte: Array = [
		# 1. In seine Sicht. Was er sieht, sieht der Spieler — der einzige Punkt, an dem die
		#    Fahrt STEHT. Alles andere ist Bewegung.
		{ "pos": auge, "ziel": stadt + Vector3(0.0, INTRO_BLICK_H, 0.0), "sek": INTRO_SEK_BLICK },
		# 2. Der Anflug, in einem Zug: ueber die Wueste und hinauf auf Umrundungshoehe.
		#    Frueher waren das zwei Etappen — fliegen, dann steigen. Das kostete Zeit und sah
		#    aus wie ein Aufzug; zusammen ist es ein Schwung, und das schnellste Stueck.
		{ "pos": start, "ziel": mitte + Vector3(0.0, INTRO_BLICK_H, 0.0),
			"sek": INTRO_SEK_ANFLUG },
	]
	# 3. Und herum um die Mauer, Blick nach innen — das langsame Stueck.
	punkte.append_array(orbit_punkte(mitte, start, INTRO_ORBIT_GRAD,
		INTRO_ORBIT_H0, INTRO_ORBIT_H1, INTRO_BLICK_H, INTRO_SEK_RUNDE))
	# 4. RUECKWAERTS hinaus, mit dem Blick weiter auf der Stadt.
	#
	#    Die Kamera faehrt zurueck und schaut dabei nach vorn — Rustwater bleibt im Bild und
	#    wird kleiner, statt aus dem Rahmen zu kippen. Das letzte, was man vom Ort sieht, soll
	#    der Ort sein und nicht der Hinterkopf der Figur.
	#
	#    Und zwar im TEMPO DES ANFLUGS. Vorher stand hier eine feste Sekundenzahl, und weil die
	#    Umrundung auf der anderen Seite des Ortes endet, wurde daraus ein Sprung: gut 48 m/s
	#    gegen 14 m/s beim Hereinfliegen. Jetzt wird das Anflugtempo gemessen und der Weg damit
	#    ausgerechnet.
	var orbit_ende: Vector3 = punkte[punkte.size() - 1]["pos"]
	var rueck: Vector3 = _player.position - hin * INTRO_RUECK_M \
		+ Vector3(0.0, INTRO_RUECK_H, 0.0)
	var v_anflug: float = maxf(auge.distance_to(start), 1.0) / INTRO_SEK_ANFLUG
	var sek_heim: float = maxf(orbit_ende.distance_to(rueck) / v_anflug, INTRO_SEK_HEIM_MIN)
	punkte.append({ "pos": rueck, "ziel": mitte + Vector3(0.0, INTRO_BLICK_H, 0.0),
		"sek": sek_heim })
	# 5. Stehenbleiben und BEIDES zeigen: die Figur im Vordergrund, Rustwater am Horizont. Das
	#    ist der Satz, den die ganze Fahrt sagen soll — da will er hin, und da steht er.
	#    Der Blickpunkt liegt zwischen beiden, sonst faellt eins davon aus dem Rahmen.
	punkte.append({ "pos": rueck,
		"ziel": _player.position.lerp(mitte, 0.30) + Vector3(0.0, 4.0, 0.0),
		"sek": INTRO_SEK_ZEIGEN })
	# 6. Und einschwenken: dieselbe Stelle, dieselbe Blickrichtung wie vor der Fahrt. Kippen und
	#    heranziehen statt schneiden — 1,6 s statt der frueheren 0,8, weil die Kamera jetzt von
	#    weiter hinten und hoeher kommt.
	punkte.append({ "pos": heim.origin, "ziel": heim.origin - heim.basis.z * 10.0,
		"sek": INTRO_SEK_EINSCHWENKEN })
	_play_flight(punkte)
	_say("☾ Rustwater. Licht in der Wüste.", 4.0)


## Die Mondscheibe am Himmel.
##
## Kein Schmuck: Eine helle Nacht ohne sichtbare Quelle wirkt wie ein vergessener Regler — man
## muss SEHEN, woher das Licht kommt. Ein leuchtendes Viereck, weit weg und immer zur Kamera
## gedreht; der Himmel ist eine Farbfläche ohne Sternen-Shader, mehr braucht es dafür nicht.
##
## Sie hängt am SPIELER und wandert mit: Bei 400 m Abstand bewegt sie sich beim Laufen nicht
## merklich, aber sie gerät auch nie hinter den Kraterrand.
const MOON_DIST_M: float = 400.0
const MOON_SIZE_M: float = 26.0
var _moon: MeshInstance3D = null
var _moonlight: DirectionalLight3D = null
func _build_moon() -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(MOON_SIZE_M, MOON_SIZE_M)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.94, 0.96, 1.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.disable_receive_shadows = true
	# Hinter allem: Der Mond steht am Himmel, nicht zwischen den Häusern.
	m.no_depth_test = false
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "mond"
	add_child(mi)
	_moon = mi


## Wie stark brennt eine Flamme gerade? 1,0 = ruhig.
##
## Zwei Sinus mit unrundem Verhaeltnis (7,3 zu 11,9) statt eines einzelnen: Ein einzelner ist
## ein Pulsschlag, den das Auge nach zwei Sekunden mitzaehlt. Zwei, deren Perioden nicht
## aufgehen, wiederholen sich erst nach Minuten — und genau das liest sich als Feuer.
##
## Kein Zufallsgenerator: Flackern aus `randf()` springt mit der Bildrate. Bei 30 fps waere es
## ein anderes Feuer als bei 120, und das darf ein Spiel nicht haben.
static func flacker_faktor(t: float, phase: float, staerke: float) -> float:
	if staerke <= 0.0:
		return 1.0
	return 1.0 + staerke * (sin(t * 7.3 + phase) * 0.62 + sin(t * 11.9 + phase * 2.3) * 0.38)


var _flacker_t: float = 0.0
## Die Nachtlichter: an, wenn es dunkel wird, und Flammen flackern dabei.
##
## Getrennt von `_apply_daytime`, weil beides in einer anderen Geschwindigkeit lebt — die Sonne
## steht viermal je Sekunde neu, eine Flamme in jedem Bild. Zwei Dutzend Punktlichter mit einer
## Zahl zu beschreiben kostet nichts; sie im Vierteltakt zucken zu lassen, kostet den Effekt.
func _apply_night_lights() -> void:
	# Weich hoch und runter mit der Daemmerung — eine Laterne, die auf die Sekunde umspringt,
	# liest sich als Schalter, nicht als Abend.
	var dunkel: float = 1.0 - smoothstep(0.0, 0.35, DayCycle.daylight(GameState.hour))
	for l in _night_lights:
		var f: float = flacker_faktor(_flacker_t, float(l.get("phase", 0.0)),
			float(l.get("flacker", 0.0)))
		(l["node"] as OmniLight3D).light_energy = float(l["max"]) * dunkel * f
		var glas: MeshInstance3D = l.get("glas")
		if glas != null:
			glas.visible = dunkel > 0.02
			if glas.visible:
				(glas.material_override as StandardMaterial3D).albedo_color = \
					Color(l.get("farbe", NIGHT_LIGHT_COLOR), clampf(dunkel * f, 0.0, 1.0))


func _apply_daytime() -> void:
	var h: float = GameState.hour
	# Die Lachen zeigen den Himmel — siehe `_add_puddle`. Nachts ist das Blaugrau, abends die
	# Horizontglut; damit ist eine Pfuetze zu jeder Tageszeit das Hellste am Grund der Grube.
	var himmel: Color = DayCycle.sky_color(h)
	for pm in _puddles:
		(pm as StandardMaterial3D).emission = himmel
	_rim_farben_ziehen()
	if _moon != null:
		var sicht: float = DayCycle.moon_visibility(h)
		_moon.visible = sicht > 0.01
		if _moon.visible:
			var hoehe: float = deg_to_rad(DayCycle.moon_altitude_deg(h))
			var az: float = deg_to_rad(DayCycle.moon_azimuth_deg(h))
			var richtung := Vector3(sin(az) * cos(hoehe), sin(hoehe), cos(az) * cos(hoehe))
			var wo: Vector3 = richtung * MOON_DIST_M
			if _player != null:
				wo += Vector3(_player.position.x, 0.0, _player.position.z)
			_moon.position = wo
			(_moon.material_override as StandardMaterial3D).albedo_color = \
				Color(0.94, 0.96, 1.0, sicht)
	if _sun != null:
		_sun.rotation_degrees = Vector3(-DayCycle.sun_altitude_deg(h),
			DayCycle.sun_azimuth_deg(h), 0.0)
		_sun.light_color = DayCycle.sun_color(h)
		_sun.light_energy = DayCycle.sun_energy(h)
		_sun.visible = _sun.light_energy > 0.01
	if _moonlight != null:
		# Der Mond leuchtet AUS SEINER RICHTUNG. Das klingt selbstverstaendlich und war es
		# nicht: Vorher lief das Nachtlicht ueber dieselbe Lampe wie die Sonne, also aus −14°
		# unter dem Horizont — waehrend die Scheibe bei +52° am Himmel stand.
		_moonlight.rotation_degrees = Vector3(-DayCycle.moon_altitude_deg(h),
			DayCycle.moon_azimuth_deg(h), 0.0)
		_moonlight.light_energy = DayCycle.moon_energy(h)
		_moonlight.visible = _moonlight.light_energy > 0.01
	if _env != null:
		_env.background_color = DayCycle.sky_color(h)
		_env.ambient_light_color = DayCycle.ambient_color(h)
		_env.ambient_light_energy = DayCycle.ambient_energy(h)
		_env.fog_light_color = DayCycle.fog_color(h)


## Deckkraft der Biom-Tönung. 0,30 statt 1,0 (siehe unten): Die Salzpfanne soll den Sand
## AUFHELLEN, nicht ersetzen — und vor allem soll man durch sie hindurch sehen, was im Boden
## liegt. Etwas kräftiger als der Sumpfschleier (0,16), weil ein Biom über einen Kilometer
## wirkt und nicht über hundert Meter.
const BIOME_TINT_ALPHA: float = 0.30
func _build_ground_and_biomes() -> void:
	# Der Boden ist nicht mehr EINE Platte: Wo Gelände liegt (WorldManager.TERRAIN), wird ein
	# Loch ausgespart und mit einem verformten Flicken gefuellt. Sonst laege die flache Platte
	# ueber der Senke und man saehe von der Vertiefung nichts.
	var mat: BaseMaterial3D = _ground_material()
	for r in _ground_rects():
		_add_ground_quad(r, mat)
	for f in WorldManager.TERRAIN:
		_add_terrain_patch(f, mat)
	# Benannte Biom-Kreiszonen (WorldManager.BIOMES) als getönte Scheiben.
	#
	# Sie waren DECKEND — eine 550-m-Platte aus Vollfarbe, 15 cm über dem Boden. Solange die
	# Welt flach war, fiel das nicht auf: Die Scheibe lag auf dem Sand und sah aus wie
	# eingefärbter Sand. Sobald aber Gelände darunter liegt, verschluckt sie es restlos — die
	# ersten Sumpflöcher lagen in der Salzpfanne und waren im Bild weiße Kreise mit einem
	# Sandring, weil man nur noch den Teil des Walls sah, der über die Platte ragte.
	# (Dieselbe Falle wie die Piste über dem Krater, nur mit einer Scheibe statt einem Balken.)
	#
	# Jetzt durchscheinend, wie Smog- und Sumpfschleier auch: Godot zeichnet Durchsichtiges
	# NACH dem Undurchsichtigen und ohne in den Tiefenpuffer zu schreiben. Die Senke rendert
	# also zuerst mit ihrer echten Tiefe und wird anschließend nur noch eingefärbt — das ist
	# genau das, was eine Biom-Tönung tun soll.
	var tint: Dictionary = {
		"oasis": Color(0.31, 0.56, 0.31), "salt": Color(0.85, 0.84, 0.78),
		"rostwald": Color(0.54, 0.29, 0.18), "kupfer_hochland": Color(0.61, 0.42, 0.24),
	}
	for id in WorldManager.BIOME_ZONE_ORDER:
		var b: Dictionary = WorldManager.BIOMES[id]
		var r_m: float = float(b["radius"]) * WorldManager.METERS_PER_UNIT
		var disc: MeshInstance3D = _biom_scheibe(r_m, tint[id])
		disc.position = WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))) + Vector3(0.0, 0.10, 0.0)
		add_child(disc)
	# Smog-Senke: alles nördlich der Smog-Linie liegt unter giftgrünem Schleier.
	var half: float = WorldManager.WORLD_METERS / 2.0
	var smog_depth_m: float = (float(WorldManager.WORLD_SIZE) - float(WorldManager.SMOG_LINE_Y)) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT + smog_depth_m / 2.0)
	_box(Vector3(WorldManager.WORLD_METERS, 0.4, smog_depth_m), Vector3(half, 0.35, smog_z), Color(0.35, 0.65, 0.30), 0.35)


## Der Strahlensumpf: ein Fleck von 2,5 × 0,5 km, 800 m nördlich von Rustwater.
##
## Optisch lebt er von drei Dingen, und zwei davon kosten nichts:
##
##  1. **Der Boden verfärbt sich.** Kein Modell, kein zweites Material — dieselbe Sandtextur
##     mit giftgrüner Tönung, als flaches Band knapp über dem Boden. Ein eigenes Biom wäre
##     dasselbe Ergebnis mit mehr Arbeit.
##  2. **Pfützen.** Das ist die Frage, die der Auftraggeber gestellt hat: wie macht man die
##     optisch? Antwort: als flache Scheiben mit LEUCHTENDEM Material (`emission`) und
##     niedriger Rauheit. Das Leuchten ist der Trick — eine Pfütze, die nur eine dunkle Fläche
##     ist, liest sich als Loch; eine, die von innen grün glimmt, liest sich als verseucht.
##     Godots `emission` braucht dafür keine Lichtquelle und kostet nichts.
##  3. **Tote Bäume.** Dafür fehlen Modelle (siehe `docs/ASSETS_OFFEN.md`); bis dahin stehen
##     dort kahle Stämme aus zwei Zylindern. Sie liefern die Silhouette, die aus einem grünen
##     Band ein Moor macht, und lassen sich später durch ein Modell ersetzen, ohne dass sich
##     hier etwas ändert.
## Die Zone misst 2,5 × 0,5 km — bei den ersten Zahlen (90 Pfützen, 44 Bäume) lag im Bild
## praktisch nichts, weil sich das damals sogar über die ganze Kartenbreite verteilte. 420 und
## 240 sind noch billig (Pfütze 28 Dreiecke, Baum 26) und ergeben auf 1,25 km² endlich eine
## Dichte, die man beim Durchlaufen sieht.
const SWAMP_PUDDLES: int = 420
const SWAMP_TREES: int = 240
func _build_swamp() -> void:
	var m: float = WorldManager.METERS_PER_UNIT
	var zone: Rect2 = WorldManager.swamp_rect()
	var breite_m: float = zone.size.x * m          # Ost–West
	var tiefe_m: float = zone.size.y * m           # Süd–Nord
	var mitte_x: float = (zone.position.x + zone.size.x * 0.5) * m
	var mitte_z: float = -(zone.position.y + zone.size.y * 0.5) * m
	var sued: float = zone.position.y * m          # Szenen-|z| des Südrands
	# 1. Die Verfärbung. Knapp über dem Boden, durchscheinend — der Sand bleibt sichtbar.
	# Alpha 0.16, nicht 0.55. Der erste Versuch war eine grüne Platte, die den Sand vollständig
	# verdeckte — das Bild sah aus wie eine Wiese, nicht wie verseuchter Boden. Ein Schleier muss
	# durchlassen, was er einfärbt; die Verseuchung liest man an den Pfützen, nicht am Anstrich.
	var band := _box(Vector3(breite_m, 0.24, tiefe_m),
		Vector3(mitte_x, 0.13, mitte_z),
		Color(0.30, 0.50, 0.18), 0.16)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_label(Vector3(mitte_x, 26.0, mitte_z),
		"☢ STRAHLENSUMPF — ohne Schutzanzug tödlich", Color(0.62, 1.0, 0.45), LBL_LANDMARKE, 900.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20250729
	# 2. Pfützen. Leuchtendes Material, flache Scheibe, zufällig gestreckt — ein Kreis liest
	#    sich als Deckel, eine Ellipse als Lache.
	var lache := StandardMaterial3D.new()
	lache.albedo_color = Color(0.16, 0.34, 0.13)
	lache.emission_enabled = true
	lache.emission = Color(0.35, 0.95, 0.28)
	lache.emission_energy_multiplier = 0.85
	lache.roughness = 0.14
	lache.metallic = 0.25
	for i in SWAMP_PUDDLES:
		var r: float = rng.randf_range(1.1, 4.2)
		# Nur dort, wo die Strahlung wirklich zubeisst: dichter in der Mitte der Zone.
		var x: float = 0.0
		var z: float = 0.0
		var flach: bool = false
		for versuch in 4:
			var t: float = 0.5 + (rng.randf() - 0.5) * 1.4
			z = -(sued + tiefe_m * clampf(t, 0.04, 0.96))
			x = _swamp_x(rng)
			if _liegt_flach(x, z, r):
				flach = true
				break
		if not flach:
			continue
		var mi := MeshInstance3D.new()
		var zyl := CylinderMesh.new()
		zyl.top_radius = r
		zyl.bottom_radius = r
		zyl.height = 0.06
		zyl.radial_segments = 14
		mi.mesh = zyl
		mi.material_override = lache
		mi.position = Vector3(x, WorldManager.height_at(x, z) + 0.05, z)
		mi.scale = Vector3(1.0, 1.0, rng.randf_range(0.45, 1.0))
		mi.rotation.y = rng.randf() * TAU
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# 2b. Jedes Sumpfloch bekommt seinen eigenen Tümpel — die Lache am tiefsten Punkt, wie in
	#     der Schrottgrube. Ein Krater ohne Wasser wäre im Sumpf eine Baugrube; mit Wasser ist
	#     er das, was die kleinen Einschläge überhaupt erzählen sollen.
	#
	#     Sie liegt NICHT in der Mitte, sondern der Rampe gegenüber. In der Rampe fällt der
	#     flache Grund weg (`_floor_share` läuft dort gegen 0) und die Wand zieht sich bis zum
	#     Mittelpunkt — eine mittige Scheibe wurde davon angeschnitten und sah aus wie ein
	#     angebissener Keks. Physikalisch ist die Verschiebung ohnehin richtig: Wasser sammelt
	#     sich am tiefsten Punkt, und der liegt bei einer einseitig offenen Senke abseits der
	#     Öffnung. Maße als Anteil des flachen Grundes, damit sie mit jeder Kratergröße mitgehen.
	for f in WorldManager.TERRAIN:
		if not WorldManager.is_swamp_feature(f):
			continue
		var c: Vector3 = WorldManager.feature_center(f)
		var grund: float = float(f["radius"]) * float(f.get("floor", 0.4))
		# Weg von der Rampe. `ramp_deg` ist 0° = Osten, 90° = Norden; Norden ist −z.
		var weg: float = deg_to_rad(float(f.get("ramp_deg", 0.0))) + PI
		var mx: float = c.x + cos(weg) * grund * 0.45
		var mz: float = c.z - sin(weg) * grund * 0.45
		var tuempel := MeshInstance3D.new()
		var scheibe := CylinderMesh.new()
		var tr: float = grund * 0.42
		scheibe.top_radius = tr
		scheibe.bottom_radius = tr
		scheibe.height = 0.08
		scheibe.radial_segments = 20
		tuempel.mesh = scheibe
		tuempel.material_override = lache
		tuempel.position = Vector3(mx, WorldManager.height_at(mx, mz) + 0.06, mz)
		tuempel.scale = Vector3(1.0, 1.0, rng.randf_range(0.72, 1.0))
		tuempel.rotation.y = rng.randf() * TAU
		tuempel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tuempel)
	# 3. Tote Stämme — jetzt Modelle statt zwei Zylindern.
	#
	# Drei Sorten in einem Durchgang, weil sie sich denselben Platz teilen: stehende Bäume
	# (`deadtree`), umgestürzte (`deadtree_b`) und aufgeplatzte Strahlenfässer (`rad_barrel`).
	# Getrennte Schleifen hätten dreimal dieselbe Streuung gebraucht, und die Fässer sollen
	# GENAU DA liegen, wo auch die Bäume stehen — sie erzählen zusammen, warum der Sumpf
	# verseucht ist.
	#
	# Die Mischung ist bewusst schief: acht Bäume auf einen umgestürzten und ein Fass. Ein
	# Wald aus lauter Umgestürzten sähe aus wie nach einem Sturm, und ein Fass hinter jedem
	# Baum nähme dem einzelnen Fund die Bedeutung.
	var holz: Material = _mat(Color(0.19, 0.17, 0.13))
	for i in SWAMP_TREES:
		var z2: float = -(sued + tiefe_m * rng.randf_range(0.08, 0.92))
		var x2: float = _swamp_x(rng)
		# Nicht auf die Gleise. Die Trasse quert den Sumpf genau dort, wo die Streuung am
		# dichtesten ist — im ersten Bild lag prompt ein Strahlenfass zwischen den Schwellen.
		# Ein Zug faehrt da durch; was dort liegt, sieht nach Fehler aus, nicht nach Absicht.
		if _auf_trasse(Vector3(x2, 0.0, z2)):
			continue
		var wuerfel: float = rng.randf()
		var art: String = "deadtree"
		if wuerfel > 0.90:
			art = "rad_barrel"
		elif wuerfel > 0.80:
			art = "deadtree_b"
		var boden: float = WorldManager.height_at(x2, z2)
		var modell: Node3D = null
		if AssetRegistry.has_model(art):
			# Umgestürztes wird über die LÄNGE gemessen, Stehendes über die Höhe — sonst wäre
			# ein liegender Stamm auf 5,5 m Höhe skaliert ein Baumstamm von zwanzig Metern.
			var mass: float = AssetRegistry.length_of(art)
			if mass <= 0.0:
				mass = AssetRegistry.height_of(art)
			modell = AssetRegistry.instantiate(art, mass * rng.randf_range(0.82, 1.18))
		if modell != null:
			add_child(modell)
			modell.position = Vector3(x2, boden, z2)
			modell.rotation.y = rng.randf() * TAU
			# Nur was STEHT, kippt ein wenig und sperrt. Über einen liegenden Stamm steigt man,
			# und ein Fass tritt man beiseite — eine Sperre daran wäre nur im Weg.
			if art == "deadtree":
				modell.rotation.z = deg_to_rad(rng.randf_range(-9.0, 9.0))
				_solid_pillar(modell.position, 0.4)
			continue
		# Ohne Modell bleibt der Platzhalter: schiefer Stamm plus ein Aststummel. Zwei Zylinder
		# sind das Minimum, ab dem ein Baum als Baum liest und nicht als Pfahl.
		var hoehe: float = rng.randf_range(3.4, 6.8)
		var baum := Node3D.new()
		add_child(baum)
		baum.position = Vector3(x2, boden, z2)
		baum.rotation.y = rng.randf() * TAU
		var stamm: MeshInstance3D = _child_cyl(baum, 0.22, hoehe, Vector3(0.0, hoehe * 0.5, 0.0), holz)
		stamm.rotation.z = deg_to_rad(rng.randf_range(-13.0, 13.0))
		var ast: MeshInstance3D = _child_cyl(baum, 0.10, hoehe * 0.42,
			Vector3(0.0, hoehe * 0.72, 0.0), holz)
		ast.rotation.z = deg_to_rad(rng.randf_range(52.0, 84.0) * (1.0 if rng.randf() < 0.5 else -1.0))
		_solid_pillar(baum.position, 0.35)


## Passt eine flache Scheibe vom Radius `r` an dieser Stelle auf den Boden?
##
## Eine Pfütze ist eine waagerechte Scheibe. Solange der Sumpf eine Tischplatte war, durfte sie
## überall liegen; seit Krater darin liegen, landet sonst eine auf einem Wall und ragt zur
## Hälfte heraus — im Bild ein grüner Keil, der aus dem Hang wächst.
##
## Geprüft wird über HÖHENUNTERSCHIEDE am Rand der Scheibe, nicht über die Normale. Der erste
## Versuch fragte `normal_at(x, z, r)` ab und ließ genau die schlimmsten Stellen durch: Auf
## einem Wallkamm liegen beide Abtastpunkte gleich tief, die gemittelte Normale zeigt sauber
## nach oben, und die Scheibe steckt trotzdem quer im Grat. Sechs Punkte auf dem Kreis
## beantworten stattdessen direkt die Frage, die zählt — passt sie hin, ohne einzutauchen?
const PUDDLE_FLAT_TOL_M: float = 0.16
func _liegt_flach(x: float, z: float, r: float) -> bool:
	var h0: float = WorldManager.height_at(x, z)
	for k in 6:
		var a: float = TAU * float(k) / 6.0
		var h: float = WorldManager.height_at(x + cos(a) * r, z + sin(a) * r)
		if absf(h - h0) > PUDDLE_FLAT_TOL_M:
			return false
	return true


## Ost-West-Lage eines Sumpf-Details, gewichtet zur ÜBERQUERUNG hin.
##
## Die Zone ist 2,5 km breit. Gleichmäßig gestreut sind selbst 420 Pfützen eine je 3 000 m² —
## bei 30 m Sichtweite läuft man daran vorbei, ohne eine zu sehen, und der Sumpf bleibt ein
## grüner Anstrich. Zwei Drittel der Details liegen deshalb in einem 700-m-Fenster um die
## Stelle, an der die Bahntrasse die Zone schneidet: Dort kommt praktisch jeder durch. Das
## letzte Drittel bleibt breit gestreut, damit der Sumpf auch abseits nicht plötzlich aufhört.
func _swamp_x(rng: RandomNumberGenerator) -> float:
	var zone: Rect2 = WorldManager.swamp_rect()
	var m: float = WorldManager.METERS_PER_UNIT
	var links: float = zone.position.x * m + 12.0
	var rechts: float = (zone.position.x + zone.size.x) * m - 12.0
	var rand_x: float = rng.randf_range(links, rechts)
	if rng.randf() > 0.66:
		return rand_x
	var mitte: float = _swamp_crossing_x()
	if mitte < links or mitte > rechts:
		return rand_x     # die Trasse quert daneben — dann gibt es keinen bevorzugten Ort
	return clampf(mitte + rng.randf_range(-350.0, 350.0), links, rechts)


## Wo schneidet die Bahntrasse den Sumpf (Szenen-x, −1 = nirgends)?
func _swamp_crossing_x() -> float:
	var y: float = WorldManager.swamp_center_y()
	for seg in WorldManager.rail_segments():
		var a: Vector2 = WorldManager.poi_position(String(seg[0]))
		var b: Vector2 = WorldManager.poi_position(String(seg[1]))
		if (a.y < y) == (b.y < y):
			continue     # beide Enden auf derselben Seite: kein Schnitt
		var t: float = (y - a.y) / (b.y - a.y)
		return (a.x + (b.x - a.x) * t) * WorldManager.METERS_PER_UNIT
	return -1.0


## Zylinder als Kind eines Knotens — fuer alles Stangenfoermige (Staemme, Rohre, Masten).
func _child_cyl(parent: Node3D, radius: float, hoehe: float, local_pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var zyl := CylinderMesh.new()
	zyl.top_radius = radius * 0.75      # oben schlanker: ein Stamm laeuft nach oben zu
	zyl.bottom_radius = radius
	zyl.height = hoehe
	zyl.radial_segments = 7             # aus zehn Metern zaehlt niemand die Kanten
	mi.mesh = zyl
	mi.material_override = mat
	mi.position = local_pos
	parent.add_child(mi)
	return mi


func _build_sector_lines_and_rim() -> void:
	var w: float = WorldManager.WORLD_METERS
	var half: float = w / 2.0
	var blast_z: float = -float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT
	# Gate 1 — Iron-Rail-Sprengtore (dunkle Stahlwand quer über den Krater).
	_box(Vector3(w, 22.0, 5.0), Vector3(half, 11.0, blast_z), Color(0.24, 0.16, 0.13))
	_label(Vector3(half, 30.0, blast_z), "✖ IRON-RAIL-SPRENGTORE", Color(1.0, 0.55, 0.35), LBL_LANDMARKE, 600.0)
	# Gate 2 — Smog-Linie (durchscheinend, giftgrün).
	_box(Vector3(w, 28.0, 4.0), Vector3(half, 14.0, smog_z), Color(0.35, 0.75, 0.30), 0.45)
	_label(Vector3(half, 38.0, smog_z), "☣ SMOG-LINIE", Color(0.6, 1.0, 0.5), LBL_LANDMARKE, 600.0)
	# Kraterrand: Fels an allen vier Horizonten — die diegetische Aussengrenze.
	#
	# Er war eine 350 m hohe Kiste in Felsfarbe, und im Bild war er das Auffaelligste am ganzen
	# Himmel: ein harter brauner Keil, nachts ein schwarzer Balken. Nachgemessen erklaert sich
	# das von selbst — von der Schrottgrube aus steht die Suedwand nur **375 m** entfernt und
	# deckt damit **43 Grad** des Himmels ab. Der Nebel greift auf dieser Strecke zu 45 %, also
	# gar nicht.
	#
	# Zwei Dinge dagegen, und keins davon ist „mehr Nebel":
	#
	#  1. **Niedriger.** 210 m statt 350 sind aus derselben Entfernung noch 29° — genug, um den
	#     Horizont zu decken, und ein Drittel weniger Himmel.
	#  2. **Oben loest er sich auf.** Die Wand traegt Scheitelfarben: unten Fels, oben die
	#     HIMMELSFARBE. Damit hat sie keine Oberkante mehr, an der etwas abschneidet — genau so
	#     sieht ein entfernter Grat aus, und genau das fehlte. Die Farbe wird im Tagesverlauf
	#     nachgezogen wie bei den Lachen, sonst waere sie nachts blau in einer schwarzen Nacht.
	_build_rim_walls(w, half)
	# Rand-Tunnel (§1.7.4): das eine, verriegelte Tor durch die Nordwand.
	_box(Vector3(60.0, 80.0, 40.0), Vector3(half, 40.0, -w - 20.0), Color(0.08, 0.07, 0.06))
	_label(Vector3(half, 95.0, -w + 5.0), "✖ RAND-TUNNEL (verriegelt)", Color(0.95, 0.85, 0.6), LBL_LANDMARKE, 500.0)


## Schwebende Beschriftung. Höhe in Weltmetern = font_size × pixel_size; mit LABEL_PIXEL
## ergibt `size` also grob die Zeichenhöhe in Zentimetern (150 ≈ 1,8 m) — vorher waren es
## 7,5 m, was die Szene zugepflastert hat. `fade_m` blendet die Schrift auf Distanz aus,
## damit ferne POI-Namen nicht über der halben Karte kleben.
const LABEL_PIXEL: float = 0.012
## Schriftgrößen als eigene Namen, weil sie zusammengehören und einzeln gesetzt auseinander
## laufen. `size × LABEL_PIXEL` ist die Zeichenhöhe in METERN — daran misst man sie:
## Ein Name über einer 1,8-m-Figur, der 1,0 m hoch ist, ist keine Beschriftung mehr, sondern
## eine Bauchbinde. Bei Kameraabstand 9,5 m entspricht ein Meter Welthöhe rund 73 Bildpunkten.
const LBL_FIGUR: int = 25       # Namen über Personen    ≈ 0,30 m  ≈ 22 px
const LBL_BEUTE: int = 20       # Beute am Boden         ≈ 0,24 m
const LBL_TRUHE: int = 24
const LBL_HAUS: int = 34        # Gebäudeschilder        ≈ 0,41 m
const LBL_ORT: int = 60         # Ortsnamen              ≈ 0,72 m
const LBL_LANDMARKE: int = 150  # Eisernes Herz, Zonengrenzen — die sieht man aus Kilometern

func _label(pos: Vector3, text: String, color: Color, size: int = 120, fade_m: float = 260.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = LABEL_PIXEL
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = maxi(1, int(size / 10.0))
	l.position = pos
	if fade_m > 0.0:
		l.visibility_range_end = fade_m
		l.visibility_range_end_margin = fade_m * 0.2
	add_child(l)
	return l


func _build_pois() -> void:
	var sector_color: Dictionary = {
		1: Color(0.83, 0.63, 0.27), 2: Color(0.36, 0.56, 0.83), 3: Color(0.78, 0.30, 0.24) }
	for id in WorldManager.POIS.keys():
		var p: Dictionary = WorldManager.POIS[id]
		var pos: Vector3 = WorldManager.poi_scene_position(id)
		var col: Color = sector_color[int(p["sector"])]
		if id == "eisernes_herz":
			# Zentrale Landmarke: hoher, dunkler Turm — von überall am Horizont sichtbar.
			# Der Turm trägt die Fernsicht; die Schrift bleibt dezent und blendet früher aus.
			_solid_box(Vector3(120.0, 420.0, 120.0), pos + Vector3(0.0, 210.0, 0.0), Color(0.15, 0.13, 0.14))
			_label(pos + Vector3(0.0, 445.0, 0.0), "♥ " + String(p["name"]), Color(1.0, 0.45, 0.35), LBL_LANDMARKE, 900.0)
			continue
		# Ein Ort ist eine SCHRIFT, kein Pfahl.
		#
		# Hier stand eine 36 m hohe, 12 m dicke Saeule in Vollfarbe, mit 6,6 m Sperrradius genau
		# im Mittelpunkt des Ortes. Sie hat dieselbe Falle dreimal gestellt: erst mitten auf dem
		# Marktplatz von Rustwater, dann im Grund der Schrottgrube (man lief die Flanke hinunter
		# und blieb unten stehen) — und zuletzt im Rattengestruepp, also ausgerechnet dort, wohin
		# die erste Quest schickt. Zweimal wurde sie einzeln ausgenommen; beim dritten Mal ist
		# klar, dass nicht die Ausnahme falsch war, sondern die Saeule.
		#
		# Sie war ein Platzhalter fuer Fernorientierung, und der Job ist inzwischen vergeben:
		# Minikarte und Weltkarte zeigen die Orte, der Nebel deckt auf, was man gesehen hat, die
		# Quest-Marke zeigt das Ziel, die Fussspur den Weg, das HUD die Entfernung, und beim
		# Ankommen zieht der Ortsname gross ueber den Bildschirm. Was bleibt, ist die schwebende
		# Schrift auf 420 m — sie sagt „hier ist etwas", ohne im Weg zu stehen.
		#
		# Landmarken macht ab jetzt das Gelaende: Krater, Duenenfeld, Sumpf. Die sieht man von
		# weitem, sie sperren nichts, und sie sehen nicht aus wie ein Baustellenpoller.
		var hoch: float = WorldManager.height_at(pos.x, pos.z) + 22.0
		_label(pos + Vector3(0.0, hoch, 0.0), String(p["name"]), col.lightened(0.35), LBL_ORT, 420.0)


## Gelaendeform an einem Ort ({} = keine).
func _terrain_at_poi(id: String) -> Dictionary:
	for f in WorldManager.TERRAIN:
		if String(f.get("poi", "")) == id:   # freie Formen (Duenen) haben keinen Ort
			return f
	return {}


## Bodennaher Streifen, der dem Gelaende FOLGT.
##
## Vorher war jede Piste EIN Balken von Ort zu Ort. Auf flachem Boden faellt das nicht auf —
## sobald aber eine Senke darunter liegt, deckt der Balken sie zu wie ein Brett ueber einem
## Loch. In der Schrotthalde verschwanden Figur und Truhe darunter, und vom Krater war nichts
## zu sehen: Man blickte auf die Unterseite der Piste.
##
## Die Schrittweite passt sich an: In der Naehe einer Gelaendeform alle 1,5 m, sonst alle 40 m.
## Ein Streifen ueber 1000 m flacher Wueste kostet damit 50 Dreiecke statt 1300, und die
## Stelle, auf die es ankommt, ist trotzdem fein aufgeloest.
##
## UV traegt METER, nicht 0..1 — quer in `u`, laengs in `v`. Der Gleisbett-Shader zeichnet
## daraus seine Schwellen; sonst haenge die Schwellenzahl an der Segmentlaenge.
const RIBBON_STEP_NEAR: float = 1.5
const RIBBON_STEP_FAR: float = 40.0

func _ribbon_step(p: Vector3) -> float:
	for f in WorldManager.TERRAIN:
		var c: Vector3 = WorldManager.feature_center(f)
		if Vector2(p.x - c.x, p.z - c.z).length() < WorldManager.feature_reach(f) + RIBBON_STEP_FAR:
			return RIBBON_STEP_NEAR
	return RIBBON_STEP_FAR


func _add_ribbon(a: Vector3, b: Vector3, half_w: float, lateral: float, lift: float,
		mat: Material) -> void:
	var flat: Vector3 = Vector3(b.x - a.x, 0.0, b.z - a.z)
	var total: float = flat.length()
	if total < 0.5:
		return
	var dir: Vector3 = flat / total
	var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
	var mitte: Vector3 = a + side * lateral
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d0: float = 0.0
	while d0 < total:
		var step: float = _ribbon_step(mitte + dir * d0)
		var d1: float = minf(d0 + step, total)
		# AUCH QUER unterteilen. Die Piste ist 55 m breit, der Krater misst 40 m — wird die
		# Hoehe nur an den beiden Raendern abgetastet, liegen beide auf flachem Boden und die
		# Strasse spannt sich als Bruecke ueber das Loch. Genau so verschwand die Figur darunter.
		var spalten: int = maxi(1, int(ceil(half_w * 2.0 / step)))
		for k in spalten:
			var q0: float = -half_w + half_w * 2.0 * float(k) / float(spalten)
			var q1: float = -half_w + half_w * 2.0 * float(k + 1) / float(spalten)
			for e in [[d0, q0], [d1, q1], [d0, q1], [d0, q0], [d1, q0], [d1, q1]]:
				var laengs: float = float(e[0])
				var quer: float = float(e[1])
				var v: Vector3 = mitte + dir * laengs + side * quer
				v.y = WorldManager.height_at(v.x, v.z) + lift
				st.set_normal(WorldManager.normal_at(v.x, v.z))
				st.set_uv(Vector2(quer, laengs))
				st.add_vertex(v)
		d0 = d1
	# Tangenten erzeugen, BEVOR das Netz festgeschrieben wird: Der Sandboden ist ein PBR-Satz
	# MIT Normalmap, und die wird im Tangentenraum gelesen. Ohne Tangenten rechnet der Shader
	# mit undefinierten Vektoren. (Gesucht war damit der Helligkeitsunterschied zwischen Boden
	# und Piste — der lag NICHT hieran und ist noch offen. Richtig ist es trotzdem.)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	# Durchnummeriert, nicht bloss "ribbon": Bei gleichem Namen vergibt Godot beim Einhaengen
	# eigene Namen der Bauart "@MeshInstance3D@23", und dann findet eine Suche nach "ribbon"
	# genau ein Band statt aller. Das hat beim Nachzaehlen der Pisten schon einmal ein
	# falsches Ergebnis geliefert.
	mi.name = "ribbon_%d" % get_child_count()
	# Ein bodennaher Streifen wirft keinen sinnvollen Schatten, kostet im Schattendurchlauf
	# aber die volle Laenge.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## KEINE PISTEN MEHR.
##
## Es gab hier `_build_roads()`: ein gestampftes Band auf jeder Route, gedacht als Wegfuehrung
## („die schnellste Linie zwischen zwei Orten, an der man sich orientiert, statt Waende zu
## haben"). In einer offenen Wueste, in der man ohnehin quer laeuft und ueber die Iron Rail
## reist, hat das nie getragen — die Strassen waren ein Band auf dem Boden, dem niemand folgte.
## Praktisch angerichtet haben sie dafuer einiges: 55 m breit deckten sie den 30-m-Krater der
## Schrotthalde restlos zu, und ihre Kante lief als harter Bodenwechsel quer durch die Senke.
##
## Geblieben ist, was wirklich Weg ist: die Iron-Rail-Trasse (`_build_railway`). Die Routen
## selbst bleiben als Nachbarschafts-Daten bestehen — das Schienennetz leitet sich aus ihnen ab.


## Kuerzt eine Strecke an beiden Enden auf das, was der Ort dort zulaesst.
##
## Routen verbinden die MITTELPUNKTE der Orte. Ungekuerzt laufen Piste und Trasse deshalb quer
## ueber den Marktplatz und durch die Haeuser — und, seit es Topografie gibt, bis auf den Grund
## des Kraters. Zwei Faelle, zwei Endpunkte:
##  • **bebaute Stadt** — bis knapp hinter den Stadtboden.
##  • **geformtes Gelaende** — bis an den Auswurfwall. Ein Fuhrwerk faehrt an den Rand der
##    Grube und laedt dort ab; es faehrt nicht hinein. Vorher endete die Piste in der Mitte
##    der Senke, und ihre abgeschnittene Kante lief quer durch den Krater.
func _trim_route(a: Vector3, b: Vector3, id_a: String, id_b: String) -> Array:
	var dir: Vector3 = (b - a).normalized()
	return [a + dir * _route_stop_m(id_a), b - dir * _route_stop_m(id_b)]


## Abstand vom Ortsmittelpunkt, an dem eine Strecke endet (0 = bis in die Mitte).
func _route_stop_m(poi_id: String) -> float:
	if _is_built_town(poi_id):
		return TOWN_GROUND_R
	var f: Dictionary = _terrain_at_poi(poi_id)
	if not f.is_empty():
		return WorldManager.feature_reach(f)
	return 0.0


## Ist an diesem Ort eine gebaute Stadt (mit eigenem Boden und Mauer)?
func _is_built_town(poi_id: String) -> bool:
	return poi_id == "rustwater" and ResourceLoader.exists(TOWN_SCENE)


## Die GLEISE sind vorerst AUS.
##
## Eine Trasse quer durch die Welt ist eine Entscheidung ueber die ganze Karte: Sie legt fest,
## welche Orte Nachbarn sind, wo man langlaeuft und wovon die Landschaft durchschnitten wird.
## Das macht man am Ende, wenn die Orte stehen — nicht am Anfang.
##
## Der BAHNSTEIG bleibt stehen: An ihm haengt die Schnellreise (`_fast_travel`), und ohne sie
## ist die Welt zum Ausprobieren zu gross. Wieder anschalten ist ein Wort.
const ZEIGE_GLEISE: bool = false


## Liegt dieser Punkt auf der Trasse — und ist die ueberhaupt zu sehen?
##
## Streuwerk (Baeume, Faesser, Steine) wird von der Trasse ferngehalten, damit nichts zwischen
## den Schwellen steht. Ohne sichtbare Gleise waere dieselbe Sperre ein 15 m breiter,
## schnurgerader, auffaellig LEERER Streifen quer durch die Wueste — der Abdruck von etwas, das
## man nicht sieht. Also faellt sie mit den Gleisen zusammen weg.
func _auf_trasse(pos: Vector3) -> bool:
	return ZEIGE_GLEISE and WorldManager.on_rail(WorldManager.scene_to_world(pos))


## Die Iron Rail (GDD §1.4a): Schotterbett mit Schwellen + zwei Schienen auf den Routen
## zwischen den Bahnhoefen, dazu an jedem Knoten ein Bahnsteig. Der lange Fussmarsch durch die
## Wueste bleibt moeglich — spaeter faehrt man ihn. Fahren darf man nur AM Bahnsteig, damit
## Schnellreise ein Ort in der Welt ist und kein Menuepunkt.
func _build_railway() -> void:
	for id in WorldManager.RAIL_STATIONS:
		_build_station(String(id))
	if not ZEIGE_GLEISE:
		return
	var steel: Material = _mat(Color(0.62, 0.60, 0.58))
	var bed_shader: Shader = load("res://shaders/rail_bed.gdshader") as Shader
	for seg_ids in WorldManager.rail_segments():
		# Auch die Trasse endet vor der Stadt statt ueber den Marktplatz zu laufen.
		var pair: Array = _trim_route(WorldManager.poi_scene_position(String(seg_ids[0])),
			WorldManager.poi_scene_position(String(seg_ids[1])),
			String(seg_ids[0]), String(seg_ids[1]))
		# Schotterbett und beide Schienen sind jetzt gelaendefolgende Streifen statt gedrehter
		# Balken — aus demselben Grund wie bei den Pisten. Die Schwellen zeichnet weiterhin der
		# Shader, er liest den Takt aber aus der UV-Laengskoordinate statt aus der Balkenlaenge.
		var bed_mat: Material = null
		if bed_shader != null:
			var sm := ShaderMaterial.new()
			sm.shader = bed_shader
			sm.set_shader_parameter("sleeper_reach", RAIL_GAUGE_M * 0.5 + 0.55)
			bed_mat = sm
		else:
			bed_mat = _mat(Color(0.30, 0.27, 0.24))
		_add_ribbon(pair[0], pair[1], (RAIL_GAUGE_M + 3.0) * 0.5, 0.0, 0.10, bed_mat)
		for side in [-1.0, 1.0]:
			_add_ribbon(pair[0], pair[1], 0.08, side * RAIL_GAUGE_M * 0.5, 0.30, steel)


## Richtung, in die die Trasse einen Knoten verlaesst (Einheitsvektor, XZ-Ebene).
## Ohne Nachbarn: nach Sueden, damit der Bahnsteig nicht in der Landschaft verschwindet.
func _rail_exit_dir(poi_id: String) -> Vector3:
	for seg in WorldManager.rail_segments():
		var other: String = ""
		if String(seg[0]) == poi_id:
			other = String(seg[1])
		elif String(seg[1]) == poi_id:
			other = String(seg[0])
		if other != "":
			var d: Vector3 = WorldManager.poi_scene_position(other) - WorldManager.poi_scene_position(poi_id)
			return Vector3(d.x, 0.0, d.z).normalized()
	return Vector3(0.0, 0.0, 1.0)


## Bahnsteig an einem Knoten — **auf der Trasse und vor den Toren**.
##
## Vorher lag er stur 14 m suedlich des Ortsmittelpunkts. Bei Rustwater verlaesst die Strecke
## den Ort aber nach Norden: der Bahnsteig stand 162° neben den eigenen Gleisen, und seit dem
## engen Stadtplan zusaetzlich mitten in der Stadt. Jetzt sitzt er dort, wo die Schienen
## wirklich verlaufen, ausserhalb der Palisade, und ist wie sie ausgerichtet.
func _build_station(poi_id: String) -> void:
	var c: Vector3 = WorldManager.poi_scene_position(poi_id)
	var dir: Vector3 = _rail_exit_dir(poi_id)
	var platform: Vector3 = c + dir * STATION_OFFSET_M
	var station := Node3D.new()
	add_child(station)
	station.position = platform
	station.look_at(platform + dir, Vector3.UP)   # Laengsachse parallel zum Gleis
	# Bahnsteig NEBEN dem Gleis, nicht darauf: Versatz quer zur Fahrtrichtung.
	var side: float = RAIL_GAUGE_M * 0.5 + 4.6
	if not _build_station_hall(station, side):
		_build_station_boxes(station, side)
	_dress_station(station, side, poi_id)
	# Ueber den First, nicht davor: Bei 6,4 m hing die Schrift mitten in der Fassade und war
	# breiter als die Halle. Die Halle misst 9,8 m — 13 m sind knapp darueber, und die kleinere
	# Schrift laesst das Gebaeude die Hauptsache bleiben.
	var label_at: Vector3 = platform + Vector3(0.0, 13.0, 0.0)
	_label(label_at, "⇄ Bahnhof " + String(WorldManager.poi(poi_id)["name"]),
		Color(0.92, 0.86, 0.70), LBL_HAUS, 200.0)
	_stations.append({ "id": poi_id, "pos": platform })
	# Eine Station ohne Licht findet nachts niemand — und reisen soll man auch im Dunkeln.
	_add_night_light(platform + Vector3(0.0, 4.2, 0.0), 20.0, 3.0)


## Bahnsteighalle aus dem Modell — `false`, wenn keins vorhanden ist.
##
## `station` schaut mit seinem lokalen −Z die Trasse entlang, lokales +X zeigt quer vom Gleis
## weg. Das Modell dagegen ist wie jedes Gebaeude gebaut: Laengsachse X, Front −Z (die
## Korrektur dahin steht in `AssetRegistry.YAW_DEG`). Beides passt erst nach einer weiteren
## Vierteldrehung zusammen — dann liegt die Halle laengs zum Gleis und schaut es an.
func _build_station_hall(station: Node3D, side: float) -> bool:
	var hall: Node3D = AssetRegistry.instantiate("bahnhof", STATION_LEN_M)
	if hall == null:
		return false
	var b: AABB = AssetRegistry.local_bounds(hall)
	var depth: float = maxf(b.size.z, 0.01)   # nach der Vierteldrehung die Tiefe zum Gleis hin
	hall.rotation.y = PI * 0.5
	# `side` ist der Abstand der Bahnsteig-VORDERKANTE zur Gleismitte, nicht der Hallenmitte:
	# Sonst haengt bei jeder Modellaenderung die halbe Halle ueber den Schienen.
	hall.position = Vector3(side + depth * 0.5, 0.0, 0.0)
	station.add_child(hall)
	# Gesperrt wird nur die Rueckwand-Haelfte. Der Bahnsteig unter dem Vordach ist der Ort, an
	# dem man auf den Zug wartet — waere er sperrend, koennte man den Bahnhof nicht betreten.
	var solid: float = depth * STATION_SOLID_SHARE
	var mid_local := Vector3(side + depth - solid * 0.5, 0.0, 0.0)
	_solid_rect_rot(station.global_transform * mid_local,
		Vector2(solid * 0.5, STATION_LEN_M * 0.5), station.rotation.y)
	return true


## Fracht und Licht auf dem Bahnsteig. Ein leerer Bahnsteig sieht aus wie ein Modell, das man
## vergessen hat einzurichten; drei Fassstapel und eine Laterne machen daraus einen Ort, an dem
## gearbeitet wird. Alles im Kollisionsschatten der Halle — nichts davon sperrt zusätzlich,
## sonst steht der Spieler beim Einsteigen im Weg seiner eigenen Kisten.
##
## Die Gaslaterne bekommt ein echtes Licht: Meshy hat die Flamme nur in die Farbtextur gemalt,
## die Emissive-Map ist schwarz (die Aufbereitung hat sie als tote Daten verworfen). Ohne
## `OmniLight3D` wäre die Laterne bei Nacht eine dunkle Stange mit einem hellen Fleck.
func _dress_station(station: Node3D, side: float, poi_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(poi_id)
	var stacks: Array = ["barrels", "barrels_b", "barrels_c"]
	for i in 3:
		var kind: String = stacks[i % stacks.size()]
		var node: Node3D = AssetRegistry.instantiate(kind,
			AssetRegistry.height_of(kind) * rng.randf_range(0.85, 1.15))
		if node == null:
			continue
		node.position = Vector3(side + 1.6 + rng.randf_range(0.0, 1.2),
			0.0, float(i - 1) * 6.0 + rng.randf_range(-1.2, 1.2))
		node.rotation.y = rng.randf() * TAU
		station.add_child(node)
	var lamp: Node3D = AssetRegistry.instantiate("street_lamp", AssetRegistry.height_of("street_lamp"))
	if lamp != null:
		lamp.position = Vector3(side + 1.0, 0.0, -STATION_LEN_M * 0.42)
		station.add_child(lamp)
		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.72, 0.36)
		glow.light_energy = 2.6
		glow.omni_range = 11.0
		glow.position = Vector3(side + 1.0, AssetRegistry.height_of("street_lamp") * 0.92,
			-STATION_LEN_M * 0.42)
		station.add_child(glow)
	var trough: Node3D = AssetRegistry.instantiate("hitching_post", AssetRegistry.length_of("hitching_post"))
	if trough != null:
		# Quer zur Halle und mit der Trogseite zum Bahnsteig — man tritt von vorn heran.
		trough.position = Vector3(side + 1.4, 0.0, STATION_LEN_M * 0.62)
		trough.rotation.y = PI * 0.5
		station.add_child(trough)


## Platzhalter-Bahnsteig aus Kisten — nur noch in Betrieb, solange `bahnhof.glb` fehlt.
func _build_station_boxes(station: Node3D, side: float) -> void:
	_child_box(station, Vector3(7.0, 0.9, 26.0), Vector3(side, 0.45, 0.0), Color(0.44, 0.38, 0.30))
	for z in [-11.0, 0.0, 11.0]:
		_child_box(station, Vector3(0.5, 3.4, 0.5), Vector3(side + 2.6, 2.6, z), Color(0.30, 0.26, 0.22))
	_child_box(station, Vector3(6.4, 0.4, 26.0), Vector3(side + 0.6, 4.5, 0.0), Color(0.34, 0.28, 0.22))
	var depot_local := Vector3(side + 8.0, 2.5, 8.0)
	_child_box(station, Vector3(9.0, 5.0, 6.0), depot_local, Color(0.38, 0.31, 0.24))
	_solid_rect_rot(station.global_transform * depot_local, Vector2(4.5, 3.0), station.rotation.y)


## Box als Kind eines gedrehten Knotens (lokale Koordinaten) — fuer alles, was an einer
## Trasse oder Fassade ausgerichtet gebaut wird.
func _child_box(parent: Node3D, size: Vector3, local_pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = local_pos
	parent.add_child(mi)
	return mi


## Rustwater. **Liegt `scenes/Rustwater.tscn` vor, ist SIE die Wahrheit** — die Stadt wird dann
## nur noch geladen, nicht gebaut. Genau dafuer ist sie da: Im Editor sieht man jedes Haus,
## kann es anfassen, drehen, verschieben; die Kollision wird beim Start aus den tatsaechlichen
## Positionen abgeleitet, nicht aus Zahlen im Code. Wer ein Haus dazustellt, muss nichts
## programmieren.
##
## Fehlt die Datei, baut der Code die Stadt weiter selbst (`TOWN_LAYOUT`) — das Projekt bleibt
## damit auch ohne die Szene lauffaehig, und der Stadtplan im Code ist die Vorlage, aus der die
## Szene einmal erzeugt wurde.
func _build_township() -> void:
	var c: Vector3 = WorldManager.poi_scene_position("rustwater")
	# Erst die Stadt, dann der Boden: Gepflastert wird nur INNERHALB der Palisade, und wo die
	# steht, weiss erst, wer die Szene geladen hat.
	var umriss := PackedFloat32Array()
	if ResourceLoader.exists(TOWN_SCENE):
		var town: Node3D = (load(TOWN_SCENE) as PackedScene).instantiate()
		town.position = c
		add_child(town)
		var sperren: Array = TownCollision.rects(town, town.transform)
		_register_town_rects(sperren)
		umriss = _wall_outline(sperren, c)
		_wall_umriss = umriss
		_wall_mitte = Vector2(c.x, c.z)
		_gates.clear()
		for r in sperren:
			if String(r["asset"]).begins_with("gate"):
				_gates.append(Vector2(r["c"]))
		# Ein Tor besteht aus ZWEI Pfosten, also stehen zwei Eintraege dicht beieinander. Die
		# Durchfahrt liegt zwischen ihnen — genau dorthin soll die Spur zeigen, nicht auf einen
		# der Pfosten.
		_gates = _paare_mitteln(_gates, 6.0)
	else:
		_build_township_from_code(c)
	_build_town_ground(c, umriss)
	_label(_turm_punkt(c) + Vector3(0.0, 21.0, 0.0), "RUSTWATER",
		Color(0.95, 0.82, 0.55), LBL_ORT, 350.0)


## Wo steht der Wasserturm? Die Landmarke, an der man Rustwater von weitem erkennt — daran
## haengen die Ortsbeschriftung und die Umrundung im Anflug.
##
## Aus der SZENE, sobald sie eine hergibt: `_register_town_rects` merkt sich die tatsaechliche
## Position, wenn es dort ein `water_tower` findet. Nur wenn der Code die Stadt selbst baut
## (oder jemand den Turm aus der Szene entfernt hat), gilt der Platz aus dem Stadtplan.
##
## Vorher stand hier `TOWER_SPOT` fest im Code. Das war 46 m daneben: Die Beschriftung schwebte
## neben dem Ort, und die Kamera umrundete beim Anflug ein Stueck leere Wueste.
var _turm_welt: Vector3 = Vector3.INF
func _turm_punkt(c: Vector3) -> Vector3:
	if _turm_welt.x < INF:
		return _turm_welt
	return c + Vector3(TOWER_SPOT.x, 0.0, TOWER_SPOT.y)


## Der Umriss der Palisade, als **Radius je Winkel**.
##
## Gebraucht, weil der Kupferboden an der Mauer enden soll und die Mauer kein Kreis ist: Beim
## Umbau von Hand ist sie im Osten weit ausgebeult und im Sueden dicht am Ort. Ein fester Radius
## haette den Boden mal weit in die Wueste hinaus, mal mitten durch die Stadt enden lassen.
##
## Warum Winkel-Eimer und nicht die Mauerstuecke der Reihe nach zu einem Polygon verbinden: Die
## Stuecke stehen in der Szene in beliebiger Reihenfolge und teils verschachtelt, und ein
## Polygon aus falsch sortierten Ecken schlaegt Schlaufen. Der groesste Radius je Winkelfach ist
## gegen beides unempfindlich.
##
## Luecken (das Tor, die offene Ostseite) werden zwischen den nachbarlichen Faechern
## ueberbrueckt — rundherum, ueber die 0°-Grenze hinweg. Sonst laege vor jedem Tor ein Keil
## ohne Boden.
const WALL_BUCKETS: int = 96
func _wall_outline(sperren: Array, c: Vector3) -> PackedFloat32Array:
	var eimer := PackedFloat32Array()
	eimer.resize(WALL_BUCKETS)
	eimer.fill(0.0)
	var besetzt: int = 0
	for r in sperren:
		if not AssetRegistry.is_wall(String(r["asset"])):
			continue
		var p: Vector2 = Vector2(r["c"]) - Vector2(c.x, c.z)
		var laenge: float = p.length()
		if laenge < 1.0:
			continue
		var i: int = int(fposmod(atan2(p.y, p.x), TAU) / TAU * float(WALL_BUCKETS)) % WALL_BUCKETS
		if eimer[i] <= 0.0:
			besetzt += 1
		eimer[i] = maxf(eimer[i], laenge)
	if besetzt < 8:
		return PackedFloat32Array()      # keine erkennbare Mauer — dann eben ohne Umriss
	var voll := PackedFloat32Array(eimer)
	for i in WALL_BUCKETS:
		if eimer[i] > 0.0:
			continue
		# Nachbarn in beide Richtungen suchen und dazwischen linear ueberbruecken.
		var vor: int = 1
		while vor < WALL_BUCKETS and eimer[(i - vor + WALL_BUCKETS) % WALL_BUCKETS] <= 0.0:
			vor += 1
		var nach: int = 1
		while nach < WALL_BUCKETS and eimer[(i + nach) % WALL_BUCKETS] <= 0.0:
			nach += 1
		var a: float = eimer[(i - vor + WALL_BUCKETS) % WALL_BUCKETS]
		var b: float = eimer[(i + nach) % WALL_BUCKETS]
		voll[i] = lerpf(a, b, float(vor) / float(vor + nach))
	return voll


## Palisade und Tore, gemerkt fuer die Wegweisung.
var _wall_umriss := PackedFloat32Array()
var _wall_mitte := Vector2.ZERO
var _gates: Array = []


## Punkte, die naeher als `abstand` beieinanderliegen, zu ihrem Mittelpunkt zusammenfassen.
## Aus zwei Torpfosten wird so die Durchfahrt.
func _paare_mitteln(punkte: Array, abstand: float) -> Array:
	var rest: Array = punkte.duplicate()
	var out: Array = []
	while not rest.is_empty():
		var a: Vector2 = rest.pop_back()
		var summe: Vector2 = a
		var n: int = 1
		var i: int = rest.size() - 1
		while i >= 0:
			if a.distance_to(rest[i]) <= abstand:
				summe += rest[i]
				n += 1
				rest.remove_at(i)
			i -= 1
		out.append(summe / float(n))
	return out


## Liegt dieser Punkt INNERHALB der Palisade?
func _im_ort(p: Vector2) -> bool:
	if _wall_umriss.is_empty():
		return false
	var d: Vector2 = p - _wall_mitte
	return d.length() < _outline_at(_wall_umriss, atan2(d.y, d.x))


## Zwischenziel, damit die Spur nicht durch die Mauer zeigt ("INF" = kein Umweg noetig).
##
## Eine Fussspur, die schnurgerade auf ein Ziel hinter der Palisade weist, fuehrt den Spieler
## vor eine Wand und laesst ihn dort suchen. Sie muss durch das TOR gehen — und nur dort, wo
## man wirklich durchkommt.
##
## Bewusst keine Wegfindung, sondern ein Zwischenziel, genau wie beim Sumpf (`swamp_detour`):
## Zwischen Wueste und Ort gibt es kein Labyrinth, es gibt eine Mauer mit Toren. Wer im Ort
## steht, geht zum naechsten Tor hinaus; wer draussen steht und hinein will, geht zum Tor, das
## dem Ziel am naechsten liegt.
const GATE_REACHED_M: float = 5.0
func _gate_detour(von: Vector2, nach: Vector2) -> Vector2:
	if _gates.is_empty() or _wall_umriss.is_empty():
		return Vector2.INF
	var drin_von: bool = _im_ort(von)
	var drin_nach: bool = _im_ort(nach)
	if drin_von == drin_nach:
		# Beide drinnen oder beide draussen. Draussen kann die Gerade trotzdem den Ort
		# durchschneiden — dann laeuft man aussen herum, nicht mittendurch.
		if not drin_von and _schneidet_ort(von, nach):
			return _um_den_ort(von, nach)
		return Vector2.INF
	# Ueber die Mauer hinweg: durch das Tor, das dem Ziel am naechsten liegt.
	var bestes: Vector2 = Vector2.INF
	var beste_laenge: float = INF
	for g in _gates:
		var tor: Vector2 = g
		var laenge: float = von.distance_to(tor) + tor.distance_to(nach)
		if laenge < beste_laenge:
			beste_laenge = laenge
			bestes = tor
	if bestes == Vector2.INF or von.distance_to(bestes) < GATE_REACHED_M:
		return Vector2.INF     # schon im Tor — ab hier zeigt die Spur wieder aufs Ziel
	return bestes


## Schneidet die Gerade den Ort? Grobprobe an zwoelf Punkten — genauer muss es nicht sein, es
## geht um „mittendurch oder aussen herum".
func _schneidet_ort(von: Vector2, nach: Vector2) -> bool:
	for i in range(1, 12):
		if _im_ort(von.lerp(nach, float(i) / 12.0)):
			return true
	return false


## Ausweichpunkt neben dem Ort: seitlich versetzt, auf Hoehe der groessten Annaeherung.
func _um_den_ort(von: Vector2, nach: Vector2) -> Vector2:
	var richtung: Vector2 = (nach - von).normalized()
	var quer := Vector2(-richtung.y, richtung.x)
	var laengs: float = (_wall_mitte - von).dot(richtung)
	var nah: Vector2 = von + richtung * laengs
	var seite: float = signf((nah - _wall_mitte).dot(quer))
	if is_zero_approx(seite):
		seite = 1.0
	var weite: float = _outline_at(_wall_umriss,
		atan2(quer.y * seite, quer.x * seite)) + 8.0
	return _wall_mitte + quer * seite * weite


## Umriss an einem Winkel ablesen, zwischen den Faechern geglaettet.
func _outline_at(umriss: PackedFloat32Array, winkel: float) -> float:
	var f: float = fposmod(winkel, TAU) / TAU * float(WALL_BUCKETS)
	var i: int = int(f) % WALL_BUCKETS
	var j: int = (i + 1) % WALL_BUCKETS
	return lerpf(umriss[i], umriss[j], f - floorf(f))


## Der Boden von Rustwater: **verlegte Kupferplatten**, kein Lehm.
##
## Vorher lag hier eine 59-m-Scheibe aus hellem Lehm. Sie hat ihren Zweck erfuellt (die Stadt
## stand nicht mehr auf derselben Wuestenduene wie das Umland), aber zwei Dinge falsch gemacht:
## Sie reichte weit ueber die Palisade hinaus — im Bild von oben eine helle Schuerze um den Ort,
## fuer die es keinen Grund gibt — und sie war eine Flaeche ohne Geschichte. Eine Stadt, die vom
## Schrott lebt, pflastert mit dem, was sie hat.
##
## Verlegt wird als MultiMesh: rund 900 Platten in ZWEI Zeichenaufrufen. Einzelne Knoten waeren
## 900 Objekte, die die Kamera jedes Bild einzeln durchsortiert.
##
## Der Rand loest sich auf, statt zu enden. Ein exakter Kreis aus Kupfer in der Wueste sieht aus
## wie ausgestanzt; im Auslaufband faellt mit wachsendem Abstand jede zweite, dritte, zehnte
## Platte weg, und der Sand nimmt sich den Platz zurueck. Aussen bleibt Wueste — sie ist ja eine.
const PLATE_M: float = 2.6            # Kantenlaenge einer Platte
## Kleiner Zuschlag gegen Fugen. Die grünspanige Platte davor war kein volles Quadrat — schräge
## Kanten, runde Ecken —, und ihr sichtbarer Umriss war so viel kleiner als die Hüllbox, auf die
## `instantiate` skaliert, dass sie 20 % Übermaß brauchte, um zu schließen. Die jetzige Platte
## füllt ihren Grundriss zu 100 % aus (gemessen: alle Rasterzellen belegt), also reichen 5 % für
## den Versatz beim Verlegen.
const PLATE_OVERLAP: float = 1.05
const PLATE_JITTER_M: float = 0.05    # von Hand verlegt, nicht gefraest
## Nur ohne Stadt-Szene gebraucht: Steht die Palisade, endet der Boden an IHR (`_wall_outline`).
const TOWN_FLOOR_R: float = 38.0      # geschlossen gepflastert
const TOWN_FLOOR_FADE: float = 11.0   # darin loest sich die Pflasterung auf
## Oberkante des Stadtbodens ueber dem Gelaende. Steht als Konstante da, weil etwas DARAUF
## liegen muss — und wer den Belag dicker macht, ohne das mitzuziehen, versenkt es. Die Platten
## werden so eingesenkt, dass ihre OBERSEITE genau hier liegt; alles, was auf dem Stadtboden
## liegt (Fussspur, Marken), rechnet weiter mit dieser einen Zahl.
const TOWN_GROUND_TOP: float = 0.08
func _build_town_ground(c: Vector3, umriss := PackedFloat32Array()) -> void:
	# Je Sorte einmal das Modell laden, vermessen und wieder wegwerfen — gebraucht werden nur
	# Netz und Masse, nicht der Knoten.
	var netze: Array = []
	var deckel: Array = []      # Hoehe der begehbaren Plattenflaeche in ihrem eigenen Raum
	var innen: Array = []       # Netz → Modellwurzel: die Kette, die `instantiate` aufbaut
	# EINE Sorte, nicht zwei. Der Wechsel zwischen zwei Platten sollte die Flaeche beleben; im
	# Bild wurde daraus ein Schachbrett aus zwei Brauntoenen, und der Boden las sich als Muster
	# statt als Belag. Die Vielfalt tragen jetzt allein die Vierteldrehungen — dieselbe Platte,
	# vier Lagen. `copper_plate_b` bleibt im Repo; umstellen ist ein Wort.
	for name in ["copper_plate_a"]:
		var probe: Node3D = AssetRegistry.instantiate(name, PLATE_M * PLATE_OVERLAP)
		if probe == null:
			continue
		var mi: MeshInstance3D = null
		for kandidat in AssetRegistry.mesh_instances(probe):
			mi = kandidat as MeshInstance3D
			break
		if mi == null or mi.mesh == null:
			probe.queue_free()
			continue
		# Ein MultiMesh kennt nur NETZE, keine Knoten — die Kette vom Netz bis zur Wurzel muss
		# deshalb ausgerechnet und in jede Instanz-Transform hineingerechnet werden. Genau das
		# hat beim ersten Versuch gefehlt: `instantiate` legt Skalierung, Drehung und das
		# Absetzen auf den Boden auf ZWISCHENknoten, nicht auf das Netz. Ohne diese Kette lagen
		# neunhundert Platten in Originalgroesse und falscher Lage im Sand — im Bild nichts.
		var kette := Transform3D.IDENTITY
		var lauf: Node = mi
		while lauf != null and lauf != probe:
			if lauf is Node3D:
				kette = (lauf as Node3D).transform * kette
			lauf = lauf.get_parent()
		netze.append(mi.mesh)
		innen.append(kette)
		deckel.append(_plate_top(mi.mesh, kette))
		probe.queue_free()
	if netze.is_empty():
		_build_town_ground_lehm(c)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260802
	var lagen: Array = []
	for _v in netze.size():
		lagen.append([])
	var weiteste: float = TOWN_FLOOR_R + TOWN_FLOOR_FADE
	for v in umriss:
		weiteste = maxf(weiteste, v)
	var n: int = int(ceil(weiteste / PLATE_M))
	for iz in range(-n, n + 1):
		for ix in range(-n, n + 1):
			var raster := Vector2(float(ix) * PLATE_M, float(iz) * PLATE_M)
			var r: float = raster.length()
			if not umriss.is_empty():
				# Mit Palisade: Der Boden endet AN IHR und franst nicht aus. Die Grenze liegt
				# auf der Mauerlinie, nicht davor — eine halbe Platte laeuft also unter die
				# Palisade. Genau so herum ist es richtig: Ein Streifen Sand zwischen Belag und
				# Mauer waere zu sehen, das Stueck Kupfer unter der Mauer nicht.
				if r > _outline_at(umriss, atan2(raster.y, raster.x)):
					continue
			elif r > TOWN_FLOOR_R + TOWN_FLOOR_FADE:
				continue
			elif r > TOWN_FLOOR_R \
					and rng.randf() < (r - TOWN_FLOOR_R) / TOWN_FLOOR_FADE:
				continue
			var v: int = rng.randi_range(0, netze.size() - 1)
			# Vierteldrehungen plus ein Hauch Schiefe: Eine Platte kann in jeder Lage liegen,
			# aber nicht in jedem Winkel — sie stossen ja aneinander.
			var yaw: float = float(rng.randi_range(0, 3)) * (PI * 0.5) \
				+ rng.randf_range(-0.025, 0.025)
			var x: float = c.x + raster.x + rng.randf_range(-PLATE_JITTER_M, PLATE_JITTER_M)
			var z: float = c.z + raster.y + rng.randf_range(-PLATE_JITTER_M, PLATE_JITTER_M)
			var y: float = WorldManager.height_at(x, z) + TOWN_GROUND_TOP - float(deckel[v])
			var platz := Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))
			(lagen[v] as Array).append(platz * (innen[v] as Transform3D))

	var gelegt: int = 0
	var reichweite: float = 0.0
	for liste2 in lagen:
		for t in liste2:
			reichweite = maxf(reichweite,
				Vector2((t as Transform3D).origin.x - c.x, (t as Transform3D).origin.z - c.z).length())
	reichweite += PLATE_M * 0.5
	for v in netze.size():
		var liste: Array = lagen[v]
		if liste.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = netze[v]
		mm.instance_count = liste.size()
		for i in liste.size():
			mm.set_instance_transform(i, liste[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "stadtboden_%d" % v
		# Ein Bodenbelag wirft keinen Schatten, der irgendwo hinfaellt — aber er EMPFAENGT
		# welche. Das Ausschalten spart 900 Instanzen im Schattendurchgang.
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		gelegt += liste.size()
	_town_plates = gelegt
	_town_floor_reach = reichweite


## Hoehe der BEGEHBAREN Flaeche einer Platte — nicht die Oberkante ihrer Huellbox.
##
## Die Platte hat einen erhabenen Rand mit Bolzen und eine vertiefte Mitte; zwischen beidem
## liegen 7,8 cm. Der erste Entwurf hat die HUELLBOX auf den Stadtboden gelegt, damit sass die
## Mitte 7,8 cm tiefer — bei 8 cm Stadtboden also 2 mm ueber dem Wuestenboden, praktisch in
## derselben Ebene. Der Sand hat das Pixelduell gewonnen, und jede Platte bekam einen
## sandfarbenen Fleck in der Mitte. Im Bild sah es aus wie ein Loch; es war eine Hoehe.
##
## Gemessen wird deshalb die Flaeche, auf der man STEHT: der hoechste nach oben zeigende Punkt
## im Ring zwischen 10 % und 40 % der halben Kantenlaenge. Der innerste Zehntel bleibt aussen
## vor (dort sitzt bei manchen Platten ein Bolzen), der Rand ebenso.
##
## Gemessen statt eingetragen, weil eine andere Platte andere Masse hat und niemand daran denken
## wird, hier eine Zahl nachzuziehen.
func _plate_top(mesh: Mesh, innen: Transform3D) -> float:
	var arr: Array = mesh.surface_get_arrays(0)
	var ecken: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var kanten: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	if ecken.is_empty() or kanten.size() < 3:
		return (innen * Vector3.ZERO).y
	var mi: Vector3 = ecken[0]
	var ma: Vector3 = ecken[0]
	for p in ecken:
		mi = Vector3(minf(mi.x, p.x), minf(mi.y, p.y), minf(mi.z, p.z))
		ma = Vector3(maxf(ma.x, p.x), maxf(ma.y, p.y), maxf(ma.z, p.z))
	var mitte_x: float = (mi.x + ma.x) * 0.5
	var mitte_z: float = (mi.z + ma.z) * 0.5
	var halb: float = maxf(ma.x - mi.x, ma.z - mi.z) * 0.5
	# Kein Normalen-Test: In diesem Ring liegen nur Ober- und Unterseite, und das Maximum ist
	# damit die Oberseite. Das ist unempfindlich gegen die Frage, wie herum das Netz gewickelt
	# ist — eine Falle, die in diesem Projekt schon einmal einen halben Tag gekostet hat.
	var hoechste: float = -INF
	var i: int = 0
	while i + 2 < kanten.size():
		var s: Vector3 = (ecken[kanten[i]] + ecken[kanten[i + 1]] + ecken[kanten[i + 2]]) / 3.0
		i += 3
		var d: float = maxf(absf(s.x - mitte_x), absf(s.z - mitte_z))
		if d < halb * 0.10 or d > halb * 0.40:
			continue
		hoechste = maxf(hoechste, s.y)
	if hoechste == -INF:
		hoechste = ma.y
	return (innen * Vector3(0.0, hoechste, 0.0)).y


## Wie viele Platten liegen (0 = die Modelle fehlen, es liegt Lehm).
var _town_plates: int = 0
## Wie weit der Belag reicht. Alles, was auf ihm LIEGT (Fussspur, Marken), muss um seine Dicke
## angehoben werden — und zwar genau dort, wo er ist. Mit der Palisade als Grenze ist das keine
## Konstante mehr, also wird beim Pflastern der groesste vorkommende Abstand gemerkt.
var _town_floor_reach: float = TOWN_FLOOR_R + TOWN_FLOOR_FADE


## Rueckfall ohne Plattenmodelle: die alte Lehmscheibe. Bleibt, damit das Projekt auch mit
## fehlenden Assets startet — dieselbe Regel wie ueberall sonst.
func _build_town_ground_lehm(c: Vector3) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = TOWN_FLOOR_R + TOWN_FLOOR_FADE
	mesh.bottom_radius = TOWN_FLOOR_R + TOWN_FLOOR_FADE
	mesh.height = TOWN_GROUND_TOP
	mesh.radial_segments = 64
	mesh.rings = 1
	disc.mesh = mesh
	disc.position = c + Vector3(0.0, TOWN_GROUND_TOP * 0.5, 0.0)
	var shader: Shader = load("res://shaders/town_ground.gdshader") as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		# Feinstruktur aus der vorhandenen Sand-PBR-Textur uebernehmen, Farbe kommt vom Shader.
		var src: BaseMaterial3D = AssetRegistry.material_from_model("ground_sand")
		if src != null and src.albedo_texture != null:
			mat.set_shader_parameter("albedo_tex", src.albedo_texture)
			mat.set_shader_parameter("has_tex", true)
			if src.normal_texture != null:
				mat.set_shader_parameter("normal_tex", src.normal_texture)
				mat.set_shader_parameter("has_normal", true)
		disc.material_override = mat
	else:
		disc.material_override = _mat(Color(0.80, 0.71, 0.54))
	add_child(disc)


## Traegt Kollision und Beschriftung fuer alles ein, was in der Stadt-Szene steht — egal ob es
## dort seit der Erzeugung liegt oder von Hand dazugestellt wurde. Verschiebt man ein Haus im
## Editor, wandert seine Sperre mit, ohne dass hier eine Zahl steht.
##
## Die Ableitung selbst steht in `TownCollision`, weil der Test sie ohne die gebaute Welt
## braucht: Er rastert Rustwater ab und faellt durch, sobald eine Flaeche nicht mehr erreichbar
## ist. Hier bleibt nur das Eintragen.
func _register_town(town: Node3D) -> void:
	_register_town_rects(TownCollision.rects(town, town.transform))


## Wie `_register_town`, aber mit bereits abgeleiteten Sperren — der Aufbau der Stadt braucht
## sie ohnehin ein zweites Mal (fuer den Umriss der Palisade) und soll sie nicht zweimal
## ausrechnen.
func _register_town_rects(sperren: Array) -> void:
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	for r in sperren:
		_solid_rect_rot(Vector3(r["c"].x, 0.0, r["c"].y), r["h"], float(r["yaw"]))
		# Wer nachts leuchtet, entscheidet sich am Bauteil — nicht an einer Koordinatenliste.
		# Stellt jemand die Schmiede im Editor um, wandert die Esse mit; stellt er ein zweites
		# Tor hin, brennen dort ebenfalls Fackeln, ohne dass hier eine Zeile dazukommt.
		match String(r["asset"]):
			"saloon":
				_light_saloon(r, Vector2(stadt.x, stadt.z))
			"forge":
				_light_forge(r)
			"gate":
				_light_gate(r)
			"water_tower":
				# Wo der Turm WIRKLICH steht. `TOWER_SPOT` ist sein Platz im Stadtplan des
				# Codes; in `Rustwater.tscn` steht er 46 m weiter noerdlich — und die Szene
				# ist die Wahrheit. An dieser Stelle haengen die Ortsbeschriftung und der
				# Anflug; beide zielten vorher auf leeren Sand neben der Stadt.
				_turm_welt = Vector3(r["c"].x, stadt.y, r["c"].y)
				_light_tower(r)
		var text: String = String(r["label"])
		if text != "":
			_label(Vector3(r["c"].x, float(r["deckel"]) + 2.2, r["c"].y), text,
				Color(0.98, 0.90, 0.72), LBL_HAUS, 150.0)


## Rueckfall: Stadt aus dem Stadtplan im Code bauen (Stand vor `Rustwater.tscn`).
func _build_township_from_code(c: Vector3) -> void:
	for b in TOWN_LAYOUT:
		var pos: Vector3 = c + Vector3(b[2].x, 0.0, b[2].y)
		var size: Vector3 = _place_building(String(b[1]), pos, deg_to_rad(float(b[3])),
			b[4], Color(b[5]))
		if String(b[0]) != "":
			_label(pos + Vector3(0.0, size.y + 2.2, 0.0), String(b[0]),
				Color(0.98, 0.90, 0.72), LBL_HAUS, 150.0)
	var shacks: Array = []
	for suffix in ["a", "b", "c", "d"]:
		if AssetRegistry.has_model("shack_" + suffix):
			shacks.append("shack_" + suffix)
	for i in SHACK_SPOTS.size():
		var spot: Vector2 = SHACK_SPOTS[i]
		var pos: Vector3 = c + Vector3(spot.x, 0.0, spot.y)
		var yaw: float = deg_to_rad(CAM_YAW + (7.0 if i % 2 == 0 else -9.0))
		var asset: String = "" if shacks.is_empty() else String(shacks[i % shacks.size()])
		_place_building(asset, pos, yaw, Vector3(6.0, 4.2, 5.0), Color(0.42, 0.33, 0.24))


## Setzt ein Gebaeude ab und traegt seine Kollision ein. Liefert die tatsaechliche Groesse
## zurueck (fuer die Hoehe der Beschriftung). `fallback` ist die Ersatzbox, falls kein Modell
## vorliegt; `extra_scale` variiert baugleiche Haeuser.
func _place_building(asset: String, pos: Vector3, yaw: float, fallback: Vector3,
		color: Color, extra_scale: float = 1.0) -> Vector3:
	var model: Node3D = null
	if asset != "":
		model = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset) * extra_scale)
	if model == null:
		_solid_box(fallback, pos + Vector3(0.0, fallback.y / 2.0, 0.0), color)
		return fallback
	model.position = pos
	model.rotation.y = yaw
	add_child(model)
	# Kollision aus dem gemessenen Modell. Etwas kleiner als die Bounding-Box, weil Vordaecher,
	# Schornsteine und Anbauten darin stecken — man soll am Haus entlanglaufen koennen, nicht
	# an dessen Luftraum.
	var size: Vector3 = AssetRegistry.local_bounds(model).size
	_solid_rect_rot(pos, Vector2(size.x, size.z) * 0.5 * BUILDING_COLLISION_SHRINK, yaw)
	return size




# ── NPCs & Quests ─────────────────────────────────────────────────────────────

func _build_npcs() -> void:
	var c: Vector3 = WorldManager.poi_scene_position("rustwater")
	for n in TOWN_NPCS:
		var spot: Vector2 = n[2]
		var pos: Vector3 = c + Vector3(spot.x, 0.0, spot.y)
		var node := Node3D.new()
		var asset: String = "npc_" + String(n[0])
		var model: Node3D = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset))
		if model != null:
			node.add_child(model)
			# `Stand_and_Chat` — die drei stehen an ihrem Platz und reden mit Leuten.
			AssetRegistry.play_clip(model, "idle")
		else:
			var body := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.42
			cap.height = 1.7
			body.mesh = cap
			body.material_override = _mat(n[3])
			body.position = Vector3(0.0, 0.85, 0.0)
			node.add_child(body)
		node.position = pos
		# Die NPCs schauen zur Stadtmitte, wie die Gebäude — nicht in die Wüste hinaus.
		# Zur Straßenmitte schauen (x = 0), wie die Häuser hinter ihnen — nicht zum Stadtplatz.
		node.rotation.y = PI * 0.5 if spot.x < 0.0 else -PI * 0.5
		add_child(node)
		var label: Label3D = _label(pos + Vector3(0.0, 2.5, 0.0), String(n[1]), Color(0.98, 0.94, 0.82), LBL_FIGUR, 140.0)
		_npcs.append({ "giver": String(n[0]), "name": String(n[1]), "node": node, "label": label, "pos": pos })


## Die (erste) Quest dieses Auftraggebers, die gerade relevant ist — offen oder aktiv.
## Fertige Quests werden übersprungen, damit ein NPC nach Abschluss die nächste anbietet.
func _quest_for_giver(giver: String) -> String:
	for qid in QuestManager.QUESTS.keys():
		var def: Dictionary = QuestManager.QUESTS[qid]
		if String(def.get("giver", "")) != giver:
			continue
		var st: String = QuestManager.get_quest_state(String(qid))
		if st != QuestManager.STATE_DONE:
			return String(qid)
	return ""


## Nähe zu einem NPC = Gespräch. Annehmen, Fortschritt melden oder abgeben — die
## Entscheidung trifft komplett der QuestManager (Kapitel-/Gilden-Gates inklusive).
## Bestimmt, was gerade in Reichweite ist, und baut die Aktionsleiste danach auf. Neu gebaut
## wird nur bei WECHSEL des Kontexts — sonst wuerde die Leiste sechzigmal pro Sekunde entstehen
## und waere nicht anklickbar.
func _process_interactions(_delta: float) -> void:
	var ctx: String = ""
	var npc: Dictionary = _npc_in_range()
	var station: String = _station_at_player()
	var chest: Dictionary = _chest_in_range()
	var gear: Dictionary = _gear_in_range()
	# Reihenfolge = Dringlichkeit: Was man aufheben kann, geht vor dem Schwatz. Der Kontext ist
	# ein String, weil die Leiste nur bei WECHSEL neu gebaut wird — bei der Ausruestung gehoert
	# deshalb das Fundstueck selbst hinein, sonst bliebe der Knopf beim Wechsel zum naechsten
	# Stueck auf dem alten Namen stehen.
	if not chest.is_empty():
		ctx = "chest:%d" % _chests.find(chest)
	elif not gear.is_empty():
		ctx = "gear:%d" % _ground.find(gear)
	elif not npc.is_empty():
		ctx = "npc:" + String(npc["giver"])
	elif station != "":
		ctx = "station:" + station
	elif _stollen_greifbar():
		ctx = "stollen"
	elif _pferd_greifbar():
		# Zuletzt in der Rangfolge, aber ueberhaupt drin: Das Pferd hatte GAR KEINEN Eintrag
		# hier. Es stand mit Namensschild am Kraterrand, und auf dem Handy — wo es keine
		# `[E]`-Taste gibt — war es damit reine Deko. Aufsitzen war nur am Schreibtisch
		# moeglich, und auch dort nur, wenn man die Taste erraten hat.
		ctx = "pferd:%d" % (1 if _mounted else 0)
	if ctx == _ctx:
		return
	_ctx = ctx
	# Erst aus dem Baum nehmen, dann freigeben: `queue_free` allein wirkt erst am Frame-Ende,
	# die alten Knöpfe stuenden also noch unter den neuen.
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	if ctx.begins_with("chest:"):
		_add_action("∅  Truhe öffnen   [E]", _open_chest.bind(_chest_in_range()))
	elif ctx.begins_with("gear:"):
		_add_action("∅  %s aufheben   [E]" % String(_gear_in_range()["data"]["name"]), _pick_up_gear)
	elif ctx.begins_with("npc:"):
		_add_action("«  %s ansprechen   [E]" % String(npc["name"]),
			_talk_to.bind(String(npc["giver"])))
		# Die Laeden haengen an den LEUTEN, nicht an ihren Haeusern. Zwei Gruende: Die Stadt
		# wird von Hand umgestellt, ein Haus kann also morgen woanders stehen — die NPCs setzt
		# `TOWN_NPCS` im Code. Und Destille und Labor haben noch gar kein Modell, waeren als
		# Anlaufstelle also unerreichbar.
		if String(npc["giver"]) == "silas":
			_add_action("⚒  Werkstatt", _open_shop.bind(ShopScreen.Mode.WERKSTATT))
		elif String(npc["giver"]) == "mabel":
			_add_action("¤  Geschäfte", _open_shop.bind(ShopScreen.Mode.WIRTSCHAFT))
	elif ctx == "stollen":
		_add_action("▼  In den Stollen steigen   [E]", _stollen_betreten)
	elif ctx.begins_with("pferd:"):
		if _mounted:
			_add_action("♞  Absteigen   [E]", _toggle_mount)
		else:
			_add_action("♞  Aufsitzen   [E]", _toggle_mount)
	elif ctx.begins_with("station:"):
		_add_action("⇄  Iron Rail — Ziel wählen", Callable())
		for i in FAST_TRAVEL.size():
			var id: String = String(FAST_TRAVEL[i])
			if id == station:
				continue
			_add_action("   %d  %s" % [i + 1, String(WorldManager.poi(id)["name"])],
				_fast_travel.bind(i))


## Naechster NPC in Gespraechsreichweite ({} = keiner).
func _npc_in_range() -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = NPC_INTERACT_M
	for n in _npcs:
		var d: float = _player.position.distance_to(n["pos"])
		if d < best_d:
			best_d = d
			best = n
	return best


## Eine Schaltflaeche in der Aktionsleiste. Ohne `action` ist es nur eine Ueberschrift.
func _add_action(text: String, action: Callable) -> void:
	if not action.is_valid():
		var head := Label.new()
		head.text = text
		head.add_theme_font_size_override("font_size", 15)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_actions.add_child(head)
		return
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 38.0)   # Daumengroesse, nicht Mausgroesse
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(action)
	_actions.add_child(btn)


## Ein Gespraech. Vorher lief das AUTOMATISCH beim Vorbeilaufen — man wurde angequatscht, statt
## zu entscheiden. Jetzt braucht es den Knopf (oder [E]).
## Jemanden ansprechen.
##
## Baut die Rede als LISTE von Zeilen und uebergibt sie am Stueck. Vorher stand in jedem Zweig
## ein eigener Aufruf mit einem einzelnen Satz — damit war ein Gespraech mit mehr als einem Satz
## nicht darstellbar, egal was in der Tabelle stand.
##
## Die Reihenfolge ist immer dieselbe: erst die Begruessung (nur beim ersten Mal), dann das
## Anliegen, dann die Sachlage (Quest-Titel, Fortschritt, Belohnung) als eigene Seite. Die
## Sachlage gehoert nicht in die Rede: Niemand sagt „Kopfgeld: Wegelagerer, 0 von 8".
func _talk_to(giver: String) -> void:
	var npc: Dictionary = {}
	for n in _npcs:
		if String(n["giver"]) == giver:
			npc = n
	if npc.is_empty():
		return
	var zeilen: Array = []
	# Die Begruessung kommt DAVOR, nicht STATT: Wer Mabel zum ersten Mal trifft und dabei einen
	# Auftrag bekommt, hoert beides.
	if not bool(GameState.met.get(giver, false)):
		zeilen.append_array(_dialog_zeilen(giver, "erst"))
		GameState.met[giver] = true
	var qid: String = _quest_for_giver(giver)
	if qid == "":
		zeilen.append_array(_dialog_zeilen(giver, "idle"))
		_talk_lines(npc, giver, zeilen)
		return
	var def: Dictionary = QuestManager.QUESTS[qid]
	var title: String = String(def["title"])
	var st: String = QuestManager.get_quest_state(qid)
	if st == QuestManager.STATE_AVAILABLE:
		if QuestManager.accept_quest(qid):
			var goal: String = ("%d Gegner erlegen" % int(def["count"])) if String(def["kind"]) == "kill" \
				else ("%dx %s sammeln" % [int(def["count"]), String(def["item"])])
			# WOHIN gehoert in denselben Satz wie WAS. Vorher stand hier „8 Gegner erlegen" und
			# man drehte sich danach in einer 5 km breiten Wueste um sich selbst.
			var ziel: String = QuestManager.quest_target(qid)
			var wohin: String = ""
			if ziel != "" and WorldManager.has_poi(ziel):
				var d: int = roundi(_player.position.distance_to(
					WorldManager.poi_scene_position(ziel)))
				wohin = "\n⊕ %s — %d m. Der Spur folgen." % [String(WorldManager.poi(ziel)["name"]), d]
			zeilen.append_array(_dialog_zeilen(giver, "offer"))
			zeilen.append("✦ „%s“ — %s%s" % [title, goal, wohin])
			_talk_lines(npc, giver, zeilen)
		else:
			_say("⊘ „%s“ ist noch nicht verfügbar." % title, 2.5)
	elif QuestManager.is_quest_complete(qid):
		var gold_before: int = GameState.gold
		if QuestManager.complete_quest(qid):
			zeilen.append_array(_dialog_zeilen(giver, "done"))
			zeilen.append("✓ „%s“ — +%d Gold" % [title, GameState.gold - gold_before])
			_talk_lines(npc, giver, zeilen)
			sfx_equip()
		else:
			_say("Hm — die Abgabe wurde abgelehnt.", 2.5)
	else:
		var p: Dictionary = QuestManager.check_quest_progress(qid)
		zeilen.append_array(_dialog_zeilen(giver, "wait"))
		zeilen.append("✦ „%s“: %d/%d" % [title, int(p["current"]), int(p["target"])])
		_talk_lines(npc, giver, zeilen)


## Ein Gespraech zeigen: Sprechtafel unten, Nahaufnahme dazu, beide drehen sich zueinander.
##
## EINE Stelle fuer alle vier Faelle (nichts zu tun, annehmen, warten, abgeben). Vorher stand in
## jedem Zweig ein eigenes `_say(...)` mit eigener Anzeigedauer, und die Nahaufnahme kam nur bei
## zweien davon — Mabel drehte sich also mal zum Spieler und mal nicht, je nachdem, ob gerade
## eine Quest anstand.
##
## Die Tafel laeuft OHNE Zeitlimit und die Aufnahme mit: Solange der Text steht, bleibt auch das
## Bild. Beendet wird beides zusammen — durch Tippen, durch eine Taste, oder von selbst, wenn
## `CLOSEUP_SEC` abgelaufen ist.
const CLOSEUP_SEC: float = 5.5
func _talk(npc: Dictionary, giver: String, text: String) -> void:
	_talk_lines(npc, giver, [text])


## Ein mehrseitiges Gespraech: Sprechtafel unten, Nahaufnahme dazu, beide so lange wie der Text.
##
## Die Aufnahme richtet sich nach der REDE, nicht nach einer festen Zahl. `CLOSEUP_SEC` war 5,5
## Sekunden — richtig fuer einen Satz, und fuer vier Saetze genau die Haelfte zu kurz: Die
## Kamera sprang zurueck, waehrend Mabel noch redete.
func _talk_lines(npc: Dictionary, giver: String, zeilen: Array) -> void:
	if zeilen.is_empty():
		zeilen = ["„…“"]
	_play_closeup(npc["node"] as Node3D, maxf(speech_gesamt(zeilen), CLOSEUP_SEC))
	_play_speech(String(npc["name"]), giver, zeilen)


## Zeilen aus der Tabelle, mit Rueckfall auf den alten Einzelsatz.
##
## `_npc_line` bleibt als Netz darunter: Wer eine Person in `TOWN_NPCS` eintraegt und die
## Dialogtabelle vergisst, bekommt einen Satz statt eines stummen Gespraechs.
func _dialog_zeilen(giver: String, anlass: String) -> Array:
	var z: Array = DialogData.lines(giver, anlass, GameState.is_revealed)
	if not z.is_empty():
		return z
	var einzeln: String = _npc_line(giver, anlass)
	return [] if einzeln == "„…“" else [einzeln]


## Die Stimmen aus der Story-Bibel (GDD §4). Nach dem Reveal reden alle drei anders mit einem —
## sie wissen dann, dass unter dem Mantel ein Automat steckt.
func _npc_line(giver: String, kind: String) -> String:
	var revealed: bool = GameState.is_revealed
	match giver:
		"mabel":
			if kind == "offer":
				return "„Setz dich, Kind. Aber vorher…“" if not revealed else "„Für dich hab ich Schmieröl statt Schnaps.“"
			if kind == "done":
				return "„Du bist zäher, als du aussiehst.“"
			if kind == "wait":
				return "„Die Wüste frisst Leute wie dich zum Frühstück.“"
			return "„Trink was, Fremder. Geht aufs Haus.“"
		"silas":
			if kind == "offer":
				return "„Diese Stadt frisst Material.“"
			if kind == "done":
				return "„Gute Arbeit. Das hält.“"
			if kind == "wait":
				return "„Ohne Schrott keine Mauer.“"
			return "„Mein Auge sieht mehr als deins, Fremder.“" if not revealed else "„Chassis-Platten? Für dich zum Selbstkostenpreis.“"
		"doc":
			if kind == "offer":
				return "„Die Viecher kommen aus den Rohren.“"
			if kind == "done":
				return "„Eine Plage weniger.“"
			if kind == "wait":
				return "„Zähl die Kadaver, nicht die Stunden.“"
			return "„Halt dich von den Ratten fern.“" if not revealed else "„Bei dir spar ich mir das Verarzten.“"
	return "„…“"


# ── Die Fußspur: der Wegweiser am Boden ───────────────────────────────────────
## Diablo löst die Frage „wohin jetzt?" mit zwei Mitteln, und wir übernehmen beide: eine Marke
## auf der Karte und eine leuchtende Spur am Boden. Die Marke beantwortet die Frage, wenn man
## die Karte aufmacht — die Spur beantwortet sie, ohne dass man sie aufmacht. Das ist der
## eigentliche Gewinn: Man läuft und wird geführt, statt zu laufen und nachzusehen.
##
## Bewusst KEINE Wegfindung. Die Welt ist offen, es gibt zwischen zwei Orten keine Hindernisse
## außer dem Strahlensumpf — und den umgeht `WorldManager.swamp_detour()`. Ein A* über 5 km
## Wüste wäre viel Maschinerie für eine gerade Linie.
##
## Die Spur läuft dem Spieler VORAUS und endet nach 30 m. Eine Spur bis zum Ziel wäre bei 1200 m
## Entfernung ein leuchtender Strich durch die halbe Welt — und würde die Reise erzählen, statt
## sie stattfinden zu lassen.
## Und die Spur STEHT. Der erste Versuch hat die vierzehn Abdrücke jeden Frame neu vor die Figur
## gerechnet — damit klebten sie am Spieler und glitten mit ihm über den Sand. Es sind aber
## Abdrücke: Sie gehören dem Boden, nicht dem Läufer. Sie schweben nicht in der Gegend herum.
##
## Deshalb hängt die Spur jetzt an einem **Anker** in der Welt. Zwischen zwei Schritten bewegt
## sich kein einziger Abdruck. Erst wenn der Spieler einen ganzen Schrittabstand zurückgelegt
## hat, rückt der Anker um genau diesen Abstand vor und richtet sich neu aufs Ziel aus: Vorn
## kommt ein Abdruck dazu, hinten verschwindet einer unter den Füßen. Man LÄUFT die Spur ab,
## statt sie vor sich herzuschieben.
## Maße eines SCHRITTS, nicht eines Wegpunkts.
##
## Der erste Entwurf hat 2,1 m Abstand und 88 cm lange Abdrücke gesetzt — das ist die Spur eines
## Riesen. Ein Mensch macht Schritte von rund 75 cm und hinterlässt Abdrücke von etwa 30 cm;
## danach sind diese Zahlen jetzt gemessen. Bei 4,7 m/s Laufgeschwindigkeit heißt das gut sechs
## Schritte je Sekunde — genau der Takt, in dem die Figur die Beine setzt.
const TRAIL_STEPS: int = 30        # Anzahl Abdrücke ≈ 23 m Vorlauf
const TRAIL_SPACING_M: float = 0.78
const TRAIL_SIDE_M: float = 0.15   # halbe Spurbreite — links/rechts, wie beim Gehen
## Weicht man so weit seitlich vom Anker ab, wird neu angesetzt. Ohne das zeigt die Spur noch in
## die Richtung, in die man vor zwanzig Metern gelaufen ist.
const TRAIL_DRIFT_M: float = 2.5
## Unter den Füßen blendet ein Abdruck aus, statt zu verschwinden. Ein Abdruck, der einen Meter
## vor der Figur wegploppt, ist auffälliger als einer, der nie da war.
const TRAIL_FADE_NEAR_M: float = 1.1
## Näher als das ist man da; dann verschwindet die Spur. Ein Wegweiser, der noch zeigt, wenn man
## schon steht, sieht aus wie ein Fehler.
const TRAIL_ARRIVED_M: float = 14.0
## Ein Abdruck ist eine VERTIEFUNG, also dunkel. Vorher war er ein gelbes Leuchtzeichen — auf
## dem hellen Stadtboden von Rustwater war davon nichts zu sehen, und draussen sah es aus, als
## schwebten Lichter ueber dem Sand. Jetzt liegt eingedrueckte Erde am Boden, und durch sie
## laeuft ein warmer Puls: Der traegt die Richtung, ohne dass der Abdruck aufhoert, einer zu sein.
const TRAIL_DUNKEL: Color = Color(0.22, 0.14, 0.06)
const TRAIL_HELL: Color = Color(0.98, 0.78, 0.34)
var _trail: Array = []             # MeshInstance3D je Abdruck
var _trail_mats: Array = []        # je Abdruck ein eigenes Material (für die Laufwelle)
var _trail_anker: Vector3 = Vector3.INF   # Weltpunkt, an dem der erste Abdruck liegt
var _trail_dir: Vector3 = Vector3.FORWARD # Richtung der Spur, wird beim Vorrücken erneuert
var _trail_paritaet: int = 0              # linker oder rechter Fuß zuerst


func _build_trail() -> void:
	# Ein Abdruck ist ein Viereck, kein Modell: 2 Dreiecke gegen ein Netz mit Textur. Bei
	# vierzehn Stück, die jeden Frame umgesetzt werden, zählt das.
	for i in TRAIL_STEPS:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.15, 0.32)
		mi.mesh = q
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(TRAIL_DUNKEL, 0.75)
		# Liegt eine Sohle (`footprint.png`), wird aus dem Viereck ein echter Abdruck. Die
		# Textur ist weiss und traegt nur die Deckung — die Farbe kommt aus `albedo_color`,
		# damit die Laufwelle weiter ueber `albedo_color.a` gesteuert werden kann.
		var sohle: Texture2D = UiAssets.texture("footprint")
		if sohle != null:
			m.albedo_texture = sohle
			var s_gr: Vector2 = sohle.get_size()
			q.size = Vector2(0.32 * (s_gr.x / maxf(s_gr.y, 1.0)), 0.32)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Nicht in den Tiefenpuffer schreiben: Der Abdruck liegt 6 cm über dem Sand und würde
		# sonst mit ihm um jedes Pixel streiten (Z-Fighting), sobald das Gelände ansteigt.
		m.no_depth_test = false
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		# Beidseitig. Ein waagerechtes Viereck, dessen Normale versehentlich nach unten zeigt,
		# ist unsichtbar — genau dieser Fehler hat schon einmal den ganzen Weltboden ins
		# Umgebungslicht gelegt. Bei vierzehn Vierecken kostet doppelseitig nichts.
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.rotation.x = -PI * 0.5    # flach auf den Boden legen
		mi.visible = false
		mi.name = "trail_%d" % i
		add_child(mi)
		_trail.append(mi)
		_trail_mats.append(m)


## Wohin zeigt die Spur gerade? (Szenenposition; `Vector3.INF` = nirgendwohin.)
##
## Zwischenziel vor Endziel: Liegt der Sumpf im Weg, führt die Spur erst um ihn herum. Sonst
## zöge das Spiel eine leuchtende Linie mitten durch die Todeszone — und der Spieler folgte ihr,
## weil das Spiel sie gezeichnet hat.
## Wohin die Fussspur zeigt.
##
## Im PROLOG an die Geschichte, danach an die verfolgte Quest. Vorher gab es waehrend des
## ganzen Prologs GAR KEINE Spur: Der Wegweiser haengt an `tracked_quest`, und die erste Quest
## bekommt man erst in Rustwater — also genau dann, wenn man den Weg schon gefunden hat.
func _trail_goal() -> Vector3:
	var szene_ziel: Vector3 = Vector3.INF
	if not GameState.prolog_done:
		szene_ziel = _prolog_ziel()
	elif not bool(GameState.met.get("mabel", false)):
		# In der Stadt angekommen, aber noch mit niemandem geredet. Die Spur fuehrt zu Mabel —
		# ohne das steht man in einer Stadt mit drei Namensschildern und keinem Grund, eines
		# davon anzusprechen. Sie ist die Erste, weil die ganze Kette in Akt I an ihr haengt
		# (GDD §3: Mabel → Silas → Doc → Mabel).
		szene_ziel = _npc_pos("mabel")
	if szene_ziel == Vector3.INF:
		var qid: String = QuestManager.tracked_quest()
		if qid == "":
			return Vector3.INF
		var ziel: String = QuestManager.quest_target(qid)
		if ziel == "" or not WorldManager.has_poi(ziel):
			return Vector3.INF
		szene_ziel = WorldManager.poi_scene_position(ziel)
	var hier: Vector2 = WorldManager.scene_to_world(_player.position)
	var dort: Vector2 = WorldManager.scene_to_world(szene_ziel)
	var umweg: Vector2 = WorldManager.swamp_detour(hier, dort)
	if umweg != Vector2.INF:
		return WorldManager.world_to_scene(umweg)
	# Die Mauer zuletzt: Sie ist das naechstliegende Hindernis, der Sumpf das weiter entfernte.
	# Erst um die Todeszone herum, dann durchs Tor.
	var tor: Vector2 = _gate_detour(Vector2(_player.position.x, _player.position.z),
		Vector2(szene_ziel.x, szene_ziel.z))
	if tor != Vector2.INF:
		return Vector3(tor.x, WorldManager.height_at(tor.x, tor.y), tor.y)
	return szene_ziel


## Wo jemand steht ({} = kennt ihn nicht).
func _npc_pos(giver: String) -> Vector3:
	for n in _npcs:
		if String(n["giver"]) == giver:
			return n["pos"]
	return Vector3.INF


## Das Ziel des Prologs: erst auf den Ausguck, dann in die Stadt.
##
## Der Ausguck zuerst, weil die Geschichte so laeuft — er weiss nicht, wo er ist, und sucht sich
## den hoechsten Punkt. Die Spur macht daraus eine Handlung: Sie zeigt auf den Fels, nicht ins
## Leere, und er geht ihr nach.
##
## Und sie zeigt auf den **Fuss der Rampe**, solange er noch draussen ist. Der Fels ist rundum
## 77° steil; eine Spur, die geradewegs auf den Gipfel weist, fuehrt gegen eine Wand — dasselbe
## Problem wie bei der Palisade, wo sie vor der Mauer endete statt durchs Tor zu gehen. Erst
## wenn er am Fels steht, zeigt sie hinauf.
const AUSGUCK_FUSS_M: float = 4.0
## Ab wie weit unter der Kuppe die Spur erst einmal AUF die Kuppe zeigt statt in den Ring.
const AUSGUCK_OBEN_M: float = 2.5
func _prolog_ziel() -> Vector3:
	if _player == null:
		return Vector3.INF
	if GameState.saw_vista:
		# Oben war er. Jetzt zaehlt die Stadt — den Rest (Palisade, Tor) macht `_trail_goal`.
		return WorldManager.poi_scene_position("rustwater")
	var f: Dictionary = _feature("ausguck")
	if f.is_empty():
		return Vector3.INF
	var mitte: Vector3 = WorldManager.feature_center(f)
	var reich: float = WorldManager.feature_reach(f)
	var d: float = Vector2(_player.position.x - mitte.x, _player.position.z - mitte.z).length()
	var kuppe: Vector3 = Vector3(mitte.x, WorldManager.height_at(mitte.x, mitte.z), mitte.z)
	if d <= reich + AUSGUCK_FUSS_M:
		var spot: Vector3 = _vista_spot()
		if spot == Vector3.INF:
			return kuppe
		# Am Fels, aber noch UNTEN: erst auf die Kuppe, dann in den Ring.
		#
		# Solange der Ring auf der Blickachse lag, brauchte es das nicht — die Rampe zeigt
		# dorthin, und wer ihr folgt, kommt an. Seit er auf der rechten Kuppe sitzt, laeuft die
		# gerade Linie vom Rampenfuss zum Ring quer ueber die Flanke, und die steht mit 72° weit
		# jenseits der Steigungsgrenze: Die Fussspur zeigte auf eine Wand. Derselbe Fehler wie
		# damals an der Palisade, wo sie vor der Mauer endete statt durchs Tor zu gehen.
		#
		# Die Felsmitte ist der Kopf der Rampe und von unten auf ihr erreichbar; von dort ist der
		# Ring einen Sattel weit entfernt, den man hinaufgehen kann.
		if _player.position.y < kuppe.y - AUSGUCK_OBEN_M:
			return kuppe
		return spot
	# Noch draussen: zum Fuss der Rampe. `ramp_deg` zaehlt wie ueberall im Gelaende — 0° ist
	# Osten, und Norden ist −z, deshalb das Minus beim Sinus.
	var w: float = deg_to_rad(float(f.get("ramp_deg", 0.0)))
	var fx: float = mitte.x + cos(w) * (reich + AUSGUCK_FUSS_M)
	var fz: float = mitte.z - sin(w) * (reich + AUSGUCK_FUSS_M)
	return Vector3(fx, WorldManager.height_at(fx, fz), fz)


## Hoehe, auf der ein FLACHER Marker liegen muss, damit man ihn sieht.
##
## `height_at` allein reicht nicht: In Rustwater liegt ueber dem Gelaende noch die Stadtscheibe
## (Oberkante `TOWN_GROUND_TOP`). Genau daran ist die Fussspur beim ersten Versuch gescheitert —
## vierzehn Abdruecke, alle korrekt gesetzt, alle `visible`, und im Bild nichts: Sie lagen bei
## 0,06 und damit zwei Zentimeter UNTER dem Stadtboden. Vom Rechnen an den Zahlen war das nicht
## zu sehen; erst ein Wuerfel an derselben Stelle, der brav erschien, hat es verraten.
const DECAL_LIFT_M: float = 0.06
func _decal_height(x: float, z: float) -> float:
	var boden: float = WorldManager.height_at(x, z)
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	if Vector2(x - stadt.x, z - stadt.z).length() <= _town_floor_reach:
		boden += TOWN_GROUND_TOP
	return boden + DECAL_LIFT_M


func _process_trail(_delta: float) -> void:
	if _trail.is_empty() or _player == null:
		return
	var ziel: Vector3 = _trail_goal()
	# WAEHREND DES ERWACHENS keine Spur.
	#
	# Die Figur liegt in der Lache und sagt sechzehn Zeilen lang, dass sie nicht weiss, wo sie
	# ist — und vor ihr leuchtete bereits ein Weg. Damit war der Monolog eine Ansage an jemanden,
	# der die Antwort schon hat, und die drei Schlusszeilen („Da drueben ragt was aus dem Sand")
	# verloren ihren Sinn: Die Spur ist SEINE Entscheidung, sie darf nicht vor ihr da sein.
	#
	# Auch die Kamerafahrten sperren sie. Eine Fussspur ist ein Hinweis fuer den Spieler am
	# Steuer; solange die Kamera anderswo ist, gibt es niemanden, dem sie etwas sagt.
	var sichtbar: bool = ziel != Vector3.INF and not _overlay_open() \
		and _wach_left <= 0.0 and not _in_flight() and not _in_cine()
	if sichtbar:
		var flach := Vector3(ziel.x - _player.position.x, 0.0, ziel.z - _player.position.z)
		if flach.length() < TRAIL_ARRIVED_M:
			sichtbar = false
		else:
			_advance_trail(flach.normalized())
			var quer := Vector3(-_trail_dir.z, 0.0, _trail_dir.x)
			for i in _trail.size():
				var mi: MeshInstance3D = _trail[i]
				var seite: float = TRAIL_SIDE_M * (1.0 if (i + _trail_paritaet) % 2 == 0 else -1.0)
				var p: Vector3 = _trail_anker + _trail_dir * (float(i) * TRAIL_SPACING_M) \
					+ quer * seite
				mi.position = Vector3(p.x, _decal_height(p.x, p.z), p.z)
				# Der Abdruck liegt flach; gedreht wird um die Hochachse in Laufrichtung.
				# Godots Vorne ist −Z, deshalb die negierten Komponenten — mit `atan2(x, z)`
				# zeigten alle Zehen nach hinten, und die Spur wies aus dem Ziel heraus.
				mi.rotation = Vector3(-PI * 0.5, atan2(-_trail_dir.x, -_trail_dir.z), 0.0)
				# Ein- und Ausblenden nach ECHTER Entfernung zum Spieler, nicht nach Platznummer:
				# Die Abdrücke stehen still, also wandert der Spieler durch sie hindurch — und
				# was er erreicht, muss unter ihm verlöschen statt wegzuploppen.
				var d: float = Vector2(p.x - _player.position.x, p.z - _player.position.z).length()
				var nah: float = smoothstep(0.0, TRAIL_FADE_NEAR_M, d)
				var fern: float = 1.0 - smoothstep(0.55, 1.0,
					d / (float(TRAIL_STEPS) * TRAIL_SPACING_M))
				# KEINE Laufwelle. Der erste Entwurf liess die Helligkeit vom Spieler weg
				# wandern — als Richtungsanzeige gedacht, im Bild ein Blinken. Ein Abdruck im
				# Boden blinkt nicht; die Richtung tragen die Zehen, dafuer zeigen sie hin.
				# Die Helligkeit haengt jetzt nur noch an der ENTFERNUNG: nah warm, fern
				# verlaufend. Das ist ueber die Zeit konstant und wandert mit dem Laeufer.
				var hell: float = 1.0 - smoothstep(0.0, 0.7, d / (float(TRAIL_STEPS) * TRAIL_SPACING_M))
				var m: StandardMaterial3D = _trail_mats[i]
				m.albedo_color = Color(TRAIL_DUNKEL.lerp(TRAIL_HELL, hell * 0.55), nah * fern * 0.9)
	for mi2 in _trail:
		(mi2 as MeshInstance3D).visible = sichtbar


## Rückt den Anker nach, wenn der Spieler einen Schritt gegangen ist — und nur dann.
##
## Zwei Fälle setzen neu an statt vorzurücken: der erste Frame (es gibt noch keinen Anker) und
## eine zu große seitliche Abweichung. Ohne den zweiten Fall zeigt die Spur nach einem Bogen
## noch dorthin, wo das Ziel vor zwanzig Metern lag.
func _advance_trail(dir: Vector3) -> void:
	var quer := Vector3(-_trail_dir.z, 0.0, _trail_dir.x)
	if _trail_anker == Vector3.INF \
			or absf((_player.position - _trail_anker).dot(quer)) > TRAIL_DRIFT_M:
		_trail_anker = _player.position
		_trail_dir = dir
		return
	var vor: float = (_player.position - _trail_anker).dot(_trail_dir)
	if vor < 0.0:
		# Rückwärts gelaufen: Der Anker darf nicht hinter dem Spieler bleiben.
		_trail_anker = _player.position
		_trail_dir = dir
		return
	# Mehrere Schritte auf einmal kommen beim Schnellreisen vor; dann wird ohnehin neu angesetzt,
	# sobald die Abweichung zu groß ist. Die Schleife ist deshalb gedeckelt.
	# Mit einem winzigen Zuschlag, weil `vor` bei einem exakten Schritt als 0,99999… ankommt und
	# `int()` daraus eine Null macht: Die Spur bliebe dann genau bei jedem vollen Schritt stehen.
	var schritte: int = mini(int(vor / TRAIL_SPACING_M + 1e-4), TRAIL_STEPS)
	if schritte <= 0:
		return
	_trail_anker += _trail_dir * (float(schritte) * TRAIL_SPACING_M)
	_trail_paritaet = (_trail_paritaet + schritte) % 2
	_trail_dir = dir


## Nächsten laufenden Auftrag verfolgen. Absichtlich auch bei offenem Overlay erlaubt: Man
## schaut auf die Karte, sieht zwei Marken und will umschalten, ohne sie zuzumachen.
func _cycle_tracked_quest() -> void:
	var laufend: Array = QuestManager.active_quests()
	if laufend.is_empty():
		_say("✦ Kein laufender Auftrag. Sprich in Rustwater mit Mabel, Silas oder Doc.", 3.0)
		return
	if laufend.size() == 1:
		_say("✦ Nur ein Auftrag läuft: „%s“"
			% String(QuestManager.QUESTS[QuestManager.tracked_quest()]["title"]), 2.5)
		return
	var neu_id: String = QuestManager.track_next()
	if neu_id == "":
		return
	var ziel: String = QuestManager.quest_target(neu_id)
	var wohin: String = String(WorldManager.poi(ziel)["name"]) if ziel != "" else "—"
	_say("⊕ Verfolgt: „%s“ → %s" % [String(QuestManager.QUESTS[neu_id]["title"]), wohin], 3.0)


## Zeile für den HUD-Quest-Tracker: der VERFOLGTE Auftrag mit Fortschritt und Wegangabe.
##
## Vorher stand hier nur „Kopfgeld: Wegelagerer 3/8". Das sagt, WAS zu tun ist, und verschweigt
## das Einzige, was man in einer 5 km breiten Wüste wirklich braucht: wo. Jetzt steht der Ort
## und die Entfernung daneben — dieselbe Information, die auch die Marke auf der Karte und die
## Fußspur am Boden tragen, nur in Worten.
func _active_quest_line() -> String:
	var qid: String = QuestManager.tracked_quest()
	if qid == "":
		return ""
	var def: Dictionary = QuestManager.QUESTS[qid]
	var p: Dictionary = QuestManager.check_quest_progress(qid)
	var fertig: bool = bool(p["complete"])
	var zeile: String = "%s %s  %d/%d" % ["✔" if fertig else "▸", String(def["title"]),
		int(p["current"]), int(p["target"])]
	var ziel: String = QuestManager.quest_target(qid)
	if ziel != "" and WorldManager.has_poi(ziel):
		var d: int = roundi(_player.position.distance_to(WorldManager.poi_scene_position(ziel)))
		# „abgeben bei" statt „nach", sobald das Ziel erfüllt ist: Der Ort ist derselbe Kasten
		# im HUD, aber die Aufgabe ist eine andere.
		zeile += "   %s %s (%d m)" % ["¤ abgeben bei" if fertig else "⊕ nach",
			String(WorldManager.poi(ziel)["name"]), d]
	var laufend: int = QuestManager.active_quests().size()
	if laufend > 1:
		zeile += "   [Q] wechseln (%d)" % laufend
	return zeile


func _scatter_decor() -> void:
	## Streut vorhandene CC0-Umgebungsmodelle um Rustwater — beweist die Asset-Pipeline und
	## gibt der Wüste Maßstab. Nur nahe dem Startbereich (der Rest der 5000 m folgt via
	## Streaming/LOD, GDD §1.4). Deterministisch, damit die Welt bei jedem Start gleich aussieht.
	var kinds: Array = ["rock_small", "rock_boulder", "cliff"]
	var available: Array = []
	for k in kinds:
		if AssetRegistry.has_model(k):
			available.append(k)
	if available.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var origin: Vector3 = WorldManager.poi_scene_position("rustwater")
	for i in 90:
		var kind: String = available[rng.randi_range(0, available.size() - 1)]
		# Zielgröße ist die LÄNGSTE Kante (AssetRegistry.TARGET_LENGTH), nicht die Höhe: die
		# CC0-Steine sind flache Geröllfelder — über die Höhe skaliert wurden aus „kleinen
		# Sandsteinen" zehn Meter breite Platten, die halb Rustwater verdeckt haben.
		var rock: Node3D = AssetRegistry.instantiate(kind,
			AssetRegistry.length_of(kind) * rng.randf_range(0.7, 1.5))
		if rock == null:
			continue
		var ang: float = rng.randf() * TAU
		# Große Felsen gehören in die Ferne, nicht vor das Stadttor: aus zehn Metern Entfernung
		# füllt eine Felsnase den Bildschirm und wirkt wie ein Bauwerk. Je größer das Stück,
		# desto weiter weg beginnt sein Streubereich.
		var near: float = TOWN_SAFE_M + 15.0 + AssetRegistry.length_of(kind) * 12.0
		var dist: float = rng.randf_range(near, 700.0)
		var pos: Vector3 = origin + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		# Nicht in die Smog-Zone streuen und im Kraterbecken bleiben.
		pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
		pos.z = clampf(pos.z, -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT), -20.0)
		# Weder in der Stadt noch auf Piste/Trasse — die Wege sollen frei und lesbar bleiben.
		if _in_town(pos) or _auf_trasse(pos):
			rock.queue_free()
			continue
		rock.position = pos
		rock.rotation.y = rng.randf() * TAU
		add_child(rock)


## Wüsten-Requisiten: Kakteen, Tierskelette, verwehte Schrotthaufen.
##
## Getrennt von `_scatter_decor`, obwohl beide streuen — die Regeln sind andere. Ein Felsen
## darf ueberall liegen; ein Kaktus, der mitten auf der Piste steht, sieht aus wie ein Fehler,
## und ein Skelett gehoert an den Wegrand, wo man es SIEHT. Die Wegnaehe ist hier also ein
## Ziel und kein Ausschlusskriterium.
const PROP_SCATTER_COUNT: int = 64
const PROP_SCATTER_R_M: float = 620.0
func _scatter_props() -> void:
	# Gewichte statt Gleichverteilung: Kakteen praegen die Wueste, Skelette sind der seltene
	# Fund, an dem man kurz stehenbleibt. Gleich verteilt waere die Wueste ein Beinhaus.
	var kinds: Array = [
		["cactus", 5], ["cactus", 5], ["bones", 1], ["bones_b", 1],
		["scrap_heap", 2], ["scrap_heap_b", 2],
	]
	var pool: Array = []
	for k in kinds:
		if AssetRegistry.has_model(String(k[0])):
			for _i in int(k[1]):
				pool.append(String(k[0]))
	if pool.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var origin: Vector3 = WorldManager.poi_scene_position("rustwater")
	for i in PROP_SCATTER_COUNT:
		var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
		var goal: float = AssetRegistry.length_of(kind)
		if goal <= 0.0:
			goal = AssetRegistry.height_of(kind)
		var node: Node3D = AssetRegistry.instantiate(kind, goal * rng.randf_range(0.75, 1.35))
		if node == null:
			continue
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(TOWN_SAFE_M + 18.0, PROP_SCATTER_R_M)
		var pos: Vector3 = origin + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
		pos.z = clampf(pos.z, -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT), -20.0)
		if _in_town(pos) or _auf_trasse(pos):
			node.queue_free()
			continue
		pos.y = WorldManager.height_at(pos.x, pos.z)   # Senken mitnehmen, sonst schwebt es
		node.position = pos
		node.rotation.y = rng.randf() * TAU
		add_child(node)
		# Nur der Kaktus sperrt. Ein Skelett tritt man beiseite, einen Schrotthaufen ueber-
		# steigt man — aber in einen zwei Meter dicken Saeulenkaktus laeuft niemand hinein.
		if kind == "cactus":
			_solid_pillar(pos, 0.9)


## Füllt jede Geländesenke mit dem, wonach sie benannt ist — bei der Schrotthalde also mit
## Schrott. Vorlage sind die Bilder, die der Auftraggeber geschickt hat: eine Grube, deren
## Grund von Rand zu Rand unter Metall verschwindet, mit einer Lache in der Mitte.
##
## Der Unterschied zur ersten Fassung ist nicht die Menge, sondern die ART der Verteilung.
## Vorher standen 26 Stücke einzeln herum, jedes auf dem Boden, jedes für sich erkennbar —
## das liest sich als „hier wurde etwas abgestellt". Ein Schrotthaufen liest sich erst als
## Haufen, wenn drei Dinge zusammenkommen:
##
##  1. **Kein Boden mehr sichtbar.** Deshalb wird nicht gestreut, sondern in drei Lagen
##     gefüllt: große Brocken, mittleres Zeug dazwischen, Kleinkram als Lückenfüller.
##  2. **Überlappung.** Die Stücke dürfen ineinanderstecken. Ein Mindestabstand — der erste
##     Reflex — erzeugt genau das Raster, das man vermeiden will.
##  3. **Teilweise vergraben.** Jedes Stück sinkt um 15–45 % seiner Höhe in den Grund. Ohne
##     das steht alles mit der Unterkante auf einer gemeinsamen Ebene, und die Ebene sieht
##     man sofort — sie verrät, dass da nichts liegt, sondern etwas platziert wurde.
##
## Gefüllt wird nur der FLACHE Grund plus ein Stück Wandfuß. Die Wand selbst bleibt frei:
## Bei 66° würde jedes Fass wie angeklebt aussehen.
## Die drei Lagen. Die Zahlen sind ein Kompromiss mit dem Dreiecksbudget: 80 Stücke kosten
## rund 190 000 Dreiecke, und das ist für den einen Ort, an dem das Spiel anfängt, vertretbar
## — für die Wüste daneben wäre es das nicht.
const CRATER_LAYERS: Array = [
	# n = Anzahl, min/max = Größe als Anteil der Normalgröße, sink = Einsinken (Anteil Höhe)
	{ "n": 22, "min": 0.95, "max": 1.55, "sink": [0.10, 0.30] },   # große Brocken
	{ "n": 44, "min": 0.50, "max": 0.90, "sink": [0.15, 0.40] },   # mittleres Zeug
	{ "n": 62, "min": 0.22, "max": 0.46, "sink": [0.20, 0.55] },   # Kleinkram in den Lücken
]
## Radius der Lache am tiefsten Punkt. Sie ist der einzige freie Fleck — und der Ort, an dem
## der Held erwacht, weil man dort als Einziges liegen kann.
const PUDDLE_R_M: float = 2.1
func _fill_craters() -> void:
	# Zuerst die von Hand gefuellten Gruben: Liegt eine Szene vor, wird sie GELADEN statt
	# gestreut — dieselbe Regel wie bei Rustwater.
	for f2 in WorldManager.TERRAIN:
		var id2: String = String(f2.get("id", ""))
		if _hand_gefuellt(id2):
			_load_pit(id2)
	var pool: Array = _scrap_pool()
	if pool.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	for f in WorldManager.TERRAIN:
		if String(f.get("kind", "crater")) != "crater":
			continue   # in ein Duenenfeld gehoert kein Schrott
		if not bool(f.get("scrap", true)):
			continue   # und in die Sumpfloecher auch nicht — dort liegt Wasser
		if _hand_gefuellt(String(f.get("id", ""))):
			continue   # von Hand gefuellt — die Szene ist die Wahrheit (wie bei Rustwater)
		_fill_crater(f, pool, rng)


## Eine einzelne Grube fuellen. Steht getrennt, weil zwei Aufrufer sie brauchen: der Weltaufbau
## und das Backwerkzeug, das aus derselben Streuung eine editierbare Szene macht.
func _fill_crater(f: Dictionary, pool: Array, rng: RandomNumberGenerator) -> void:
	var c: Vector3 = WorldManager.feature_center(f)
	var radius: float = float(f["radius"])
	# Bis an den Wandfuß plus ein Meter: Der Schrott soll die Wand berühren, nicht davor
	# aufhören. Eine sichtbare Fuge zwischen Haufen und Wand wäre das Verräterischste.
	var reichweite: float = radius * float(f.get("floor", 0.8)) + 1.0
	_add_puddle(c, f)
	_place_wreck(c, reichweite, rng)
	for lage in CRATER_LAYERS:
		for i in int(lage["n"]):
			_drop_scrap(c, reichweite, pool, lage, rng)
	_dress_rim(c, f, rng)


## Eine von Hand gefuellte Grube laden.
##
## Die Teile stehen in WELTkoordinaten (siehe `PitFloor`), die Wurzel bleibt also bei null.
##
## Kollision bekommt nur, was HOCH ist. Eine Schrotthalde, in der jedes Fass sperrt, ist keine
## Halde, sondern ein Labyrinth — man soll darueber steigen koennen. Ein dreizehn Meter langes
## Lokomotivenwrack dagegen laeuft man nicht durch. Die Grenze steht als Zahl da, damit man sie
## verschieben kann, ohne die Regel zu suchen.
const PIT_BLOCK_H_M: float = 1.5
## Das Lokomotivenwrack in einer gefuellten Grube — Weltposition, `Vector3.INF` wenn keins da ist.
##
## Gesucht wird am Modellnamen, nicht an einer Knotenbenennung: Beim Backen heissen die Teile
## `000_locomotive`, von Hand gestellte heissen, wie sie jemand genannt hat. Die Herkunftsdatei
## bleibt in beiden Faellen dieselbe.
var _pit_wrack: Vector3 = Vector3.INF
static func _finde_wrack(node: Node3D, welt: Transform3D) -> Vector3:
	for child in node.get_children():
		if not (child is Node3D):
			continue
		var c: Node3D = child as Node3D
		var w: Transform3D = welt * c.transform
		if TownCollision.asset_name(c).findn("locomotive") >= 0:
			return w.origin
		var tiefer: Vector3 = _finde_wrack(c, w)
		if tiefer != Vector3.INF:
			return tiefer
	return Vector3.INF


func _load_pit(id: String) -> void:
	var packed: PackedScene = load(pit_scene_path(id)) as PackedScene
	if packed == null:
		return
	var grube: Node3D = packed.instantiate() as Node3D
	if grube == null:
		return
	# Die Szene arbeitet lokal um die Kratermitte (damit sie sich im Editor oeffnen laesst,
	# ohne dass die Kamera im Nichts steht); hier bekommt sie ihren Platz in der Welt.
	for f0 in WorldManager.TERRAIN:
		if String(f0.get("id", "")) == id:
			var m: Vector3 = WorldManager.feature_center(f0)
			grube.position = Vector3(m.x, 0.0, m.z)
			break
	add_child(grube)
	# Das groesste Teil merken: An ihm haengt, wo die Truhe steht (siehe `_chest_spot`).
	_pit_wrack = _finde_wrack(grube, grube.transform)
	# Die Lache bleibt Sache des Codes, nicht der Bearbeitungsszene: Sie haengt an der Form des
	# Kraters (tiefster Punkt, Radius) und nicht am Geschmack dessen, der die Halde fuellt.
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == id:
			_add_puddle(WorldManager.feature_center(f), f)
			break
	for r in TownCollision.rects(grube, grube.transform):
		# `deckel` ist die Oberkante ueber Grund; darunter liegt Kleinkram, ueber den man geht.
		if float(r["deckel"]) - WorldManager.height_at(r["c"].x, r["c"].y) < PIT_BLOCK_H_M:
			continue
		_solid_rect_rot(Vector3(r["c"].x, 0.0, r["c"].y), r["h"], float(r["yaw"]))


## Szenendatei einer von Hand gefuellten Grube ("" = es gibt keine).
static func pit_scene_path(id: String) -> String:
	return "res://scenes/gruben/%s.tscn" % id


func _hand_gefuellt(id: String) -> bool:
	return id != "" and ResourceLoader.exists(pit_scene_path(id))


## Das eine grosse Stueck: eine gestrandete Werkslok, halb im Schutt.
##
## Eine Halde aus lauter gleich grossen Teilen hat keinen Massstab — man sieht einen Teppich
## und weiss nicht, ob er knietief oder haushoch ist. Ein Wrack von dreizehn Metern beantwortet
## das in dem Augenblick, in dem man ueber den Kraterrand schaut, und gibt der Grube ausserdem
## eine Mitte, auf die man zulaeuft.
##
## Am RAND des Grundes, nicht in der Mitte: Die Mitte gehoert der Lache, in der der Held
## erwacht. Ein Wrack quer darueber waere die Kulisse fuer eine andere Geschichte.
const WRECK_SINK: float = 0.22        # Anteil der Hoehe, der im Schutt steckt
func _place_wreck(c: Vector3, reichweite: float, rng: RandomNumberGenerator) -> void:
	if not AssetRegistry.has_model("locomotive"):
		return
	var lok: Node3D = AssetRegistry.instantiate("locomotive")
	if lok == null:
		return
	var ang: float = rng.randf() * TAU
	var dist: float = reichweite * 0.55
	var pos := Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
	pos.y = WorldManager.height_at(pos.x, pos.z)
	pos.y -= maxf(AssetRegistry.local_bounds(lok).size.y * lok.scale.y, 0.1) * WRECK_SINK
	lok.position = pos
	# Quer zur Blickrichtung aus der Grubenmitte: So sieht man ihre ganze Laenge, nicht die
	# Stirnseite. Leicht gekippt, weil sie liegt und nicht parkt.
	lok.rotation.y = ang + PI * 0.5 + rng.randf_range(-0.35, 0.35)
	lok.rotation.z = deg_to_rad(rng.randf_range(6.0, 14.0))
	lok.rotation.x = deg_to_rad(rng.randf_range(-5.0, 5.0))
	add_child(lok)


## Ein Stück Schrott an eine zufällige Stelle des Grundes.
func _drop_scrap(c: Vector3, reichweite: float, pool: Array, lage: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
	var basis: float = AssetRegistry.length_of(kind)
	if basis <= 0.0:
		basis = AssetRegistry.height_of(kind)
	var groesse: float = basis * rng.randf_range(float(lage["min"]), float(lage["max"]))
	var node: Node3D = AssetRegistry.instantiate(kind, groesse)
	if node == null:
		return
	# `sqrt` verteilt gleichmäßig über die FLÄCHE. Ohne die Wurzel drängt sich alles in der
	# Mitte und der Rand des Grundes bleibt kahl — bei einem Teppich fällt das sofort auf.
	var ang: float = rng.randf() * TAU
	var dist: float = sqrt(rng.randf()) * reichweite
	var pos := Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
	# Nur die Lache selbst bleibt frei, nicht ein Ring darum: Der Schnitt liegt INNERHALB des
	# Lachenrands, sodass Stuecke von aussen hineinragen duerfen. Sonst zieht sich ein
	# makellos runder Freiraum durch den Haufen, und ein makelloser Kreis ist das Letzte, was
	# in einer Schuttgrube liegt.
	if Vector2(pos.x - c.x, pos.z - c.z).length() < PUDDLE_R_M * 0.72:
		return
	pos.y = WorldManager.height_at(pos.x, pos.z)
	var hoehe: float = maxf(AssetRegistry.local_bounds(node).size.y, 0.05)
	pos.y -= hoehe * rng.randf_range(float(lage["sink"][0]), float(lage["sink"][1]))
	node.position = pos
	node.rotation.y = rng.randf() * TAU
	# Kippen: nicht nach der Hangneigung wie bisher (der Grund ist flach), sondern zufällig.
	# Geworfenes Metall liegt schief; alles waagerecht wirkt wie ein Regal.
	node.rotation.x = deg_to_rad(rng.randf_range(-26.0, 26.0))
	node.rotation.z = deg_to_rad(rng.randf_range(-26.0, 26.0))
	add_child(node)


## Sparsame Fassungen bevorzugen. Ein Stück Schrott liegt hier hundertfach — bei 12.000
## Dreiecken je Haufen wäre allein die Grube teurer als die ganze übrige Welt. Die `_lod`-
## Dateien sind dieselben Modelle mit 1.400 Dreiecken und 512er Textur; aus zehn Metern
## Entfernung, in einem Haufen aus dreißig anderen, sieht man den Unterschied nicht.
func _scrap_pool() -> Array:
	var pool: Array = []
	# Gewichtet nach KOSTEN, nicht nur nach Optik. Die beiden Schrotthaufen bleiben auch
	# reduziert bei 6.600 bzw. 3.600 Dreiecken haengen — die Reduktion kommt dort nicht weiter,
	# weil die Modelle aus vielen losen Einzelteilen bestehen und jede Bruchkante als Rand
	# geschuetzt wird. Die Fass-Stapel gehen dagegen sauber auf 1.400 herunter. Also liegen
	# mehr Faesser als Haufen in der Grube; im Gewirr faellt das nicht auf.
	# `bones` ist raus: kein sparsamer Zwilling, und ein Tierskelett gehoert in die Wueste,
	# nicht in eine Grube voller Maschinenteile.
	# Dazu der Sperrmüll: Regal, Schreibtisch, Bürostuhl, Ölfass, Stacheldraht, Rostmedaillon,
	# Betonplatte. Sie haben keinen sparsamen Zwilling, sind aber von vornherein knapp gebaut
	# (2.500–9.000 Dreiecke) und liegen einzeln statt zu Dutzenden — der Gewichtungswert 1 hält
	# ihre Zahl klein. Ihr Beitrag ist nicht Masse, sondern UNGLEICHHEIT: Bis hierher lagen in
	# der Grube fünf Sorten in hundert Kopien, und aus zehn Metern Höhe war das ein Muster.
	for zusatz in ["shelf", "desk", "office_chair", "oil_barrel", "barbed_wire",
			"medallion", "monolith"]:
		if AssetRegistry.has_model(zusatz):
			pool.append(zusatz)
	for eintrag in [["scrap_heap", 2], ["scrap_heap_b", 3], ["barrels", 4], ["barrels_b", 4],
			["barrels_c", 4]]:
		var name: String = String(eintrag[0])
		# Rostfassung zuerst, dann die sparsame, dann das volle Modell. Zwei Drittel der
		# Stuecke sollen rostig sein — die Vorlage ist ein Haufen Metall, kein Holzlager.
		for kandidat in [[name + "_rust_lod", 2], [name + "_lod", 1]]:
			var wie: String = String(kandidat[0])
			if not AssetRegistry.has_model(wie):
				continue
			for _i in int(eintrag[1]) * int(kandidat[1]):
				pool.append(wie)
		if pool.is_empty() and AssetRegistry.has_model(name):
			for _i in int(eintrag[1]):
				pool.append(name)
	return pool


## Steine auf der Lippe. In der Vorlage ist der Rand der Grube kein sauberer Kreis, sondern
## aufgebrochene Erde mit losem Geroell — daran erkennt man, dass hier etwas eingebrochen ist
## und nicht jemand ein Loch ausgehoben hat.
func _dress_rim(c: Vector3, f: Dictionary, rng: RandomNumberGenerator) -> void:
	var sorten: Array = []
	for k in ["rock_small", "rock_boulder"]:
		if AssetRegistry.has_model(k):
			sorten.append(k)
	if sorten.is_empty():
		return
	var radius: float = float(f["radius"])
	for i in 22:
		var kind: String = sorten[rng.randi_range(0, sorten.size() - 1)]
		# Klein halten: Bei voller Groesse standen dort helle Findlinge, die groesser waren als
		# die Faesser in der Grube — das las sich als Steinbruch, nicht als abgebrochene Kante.
		var node: Node3D = AssetRegistry.instantiate(kind,
			AssetRegistry.length_of(kind) * rng.randf_range(0.18, 0.45))
		if node == null:
			continue
		var ang: float = rng.randf() * TAU
		# Genau auf dem Wall, nicht davor und nicht dahinter: dort, wo die Kante bricht.
		var dist: float = radius * rng.randf_range(1.02, 1.0 + float(f["rim_width"]) * 0.9)
		var pos := Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
		pos.y = WorldManager.height_at(pos.x, pos.z) - 0.15   # etwas eingesunken
		node.position = pos
		node.rotation.y = rng.randf() * TAU
		node.rotation.x = deg_to_rad(rng.randf_range(-15.0, 15.0))
		node.rotation.z = deg_to_rad(rng.randf_range(-15.0, 15.0))
		add_child(node)


## Stehendes Wasser am tiefsten Punkt — Regen, Öl und was aus dem Metall läuft.
##
## Der einzige waagerechte, spiegelnde Fleck in einer Grube voller stumpfem Rost: Genau
## deshalb zieht er den Blick auf die Mitte, und genau dort soll der Held liegen.
## Wie stark eine Lache den Himmel zeigt. Genug, dass sie im Schatten der Kraterwand noch da
## ist — zu wenig, um im Sonnenlicht als Lampe zu wirken.
const PUDDLE_HIMMEL: float = 0.55
var _puddles: Array = []
func _add_puddle(c: Vector3, f: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = PUDDLE_R_M
	disc.bottom_radius = PUDDLE_R_M
	disc.height = 0.04
	disc.radial_segments = 24
	mi.mesh = disc
	var m := StandardMaterial3D.new()
	# Nicht schwarz: Ein schwarzer Fleck im hellen Sand liest sich als LOCH, nicht als Wasser.
	#
	# Genau das war er trotzdem, und der Grund ist eine PBR-Falle: `metallic` bedeutet „diese
	# Flaeche hat keine eigene Farbe, sie zeigt nur, was um sie herum ist". Die Welt hier steht
	# aber auf `AMBIENT_SOURCE_COLOR` — es gibt keine Himmelsreflexion, die eine metallische
	# Flaeche zurueckwerfen koennte. Ein Metall ohne Umgebung ist schwarz, und zwar vollstaendig.
	# Im ersten Augenblick des Spiels lag die Figur damit in einem schwarzen Loch.
	#
	# Also kein Metall. Der nasse Eindruck kommt aus dem, was auch ohne Reflexionen traegt:
	# geringe Rauheit fuer einen breiten Sonnenglanz (direktes Licht spiegelt sehr wohl),
	# ein Randschimmer, und eine Eigenfarbe, die das Umgebungslicht ueberhaupt annehmen kann.
	m.albedo_color = Color(0.20, 0.18, 0.14)
	m.metallic = 0.0
	m.roughness = 0.30
	m.rim_enabled = true
	m.rim = 0.6
	# Und das, was sie ueberhaupt erst sichtbar macht: Sie zeigt den HIMMEL.
	#
	# Eine waagerechte Wasserflaeche spiegelt nicht die Sonne, sondern die Kuppel darueber —
	# deshalb sieht man Pfuetzen auch im Schatten. Godot koennte das von selbst, wenn die Welt
	# auf Himmelsreflexion stuende; sie steht aber auf `AMBIENT_SOURCE_COLOR`. Also wird der
	# Himmel als Eigenleuchten nachgereicht, und `_apply_daytime` zieht ihn mit der Tageszeit
	# nach: abends kupfern, nachts blaugrau.
	m.emission_enabled = true
	m.emission_energy_multiplier = PUDDLE_HIMMEL
	# Gleich mit der richtigen Farbe anfangen. `_apply_daytime` zieht sie danach nach, laeuft
	# aber erst im naechsten Bild — und ein Bild lang eine WEISSE Scheibe (die Vorgabe fuer
	# `emission`) mitten in der Grube waere ein Blitz, den niemand erklaeren kann.
	m.emission = DayCycle.sky_color(GameState.hour)
	mi.mesh.surface_set_material(0, m)
	_puddles.append(m)
	mi.position = Vector3(c.x, WorldManager.height_at(c.x, c.z) + 0.02, c.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _rustwater_spawn() -> Vector3:
	return WorldManager.poi_scene_position("rustwater") + RUSTWATER_SPAWN_OFFSET


## Wo eine Runde ANFAENGT.
##
## Nicht mehr in Rustwater, sondern **in der Schrottgrube, in der Lache**. Das ist der Anfang,
## den die Geschichte erzaehlt (GDD Kap. 1): Der Held erwacht auf dem Muell, ohne Waffe, ohne
## Erinnerung, und muss sich erst die Truhe suchen und dann den Weg in die Stadt.
##
## Die Lache ist der einzige freie Fleck im Grund — der einzige Ort, an dem man liegen kann.
## Deshalb wird sie beim Fuellen ausgespart, und deshalb faengt es hier an.
##
## Nach dem Prolog (`prolog_done`) ist Rustwater der Startpunkt; ein Spielstand mitten im
## zweiten Kapitel soll nicht wieder auf der Kippe aufwachen.
func _start_spawn() -> Vector3:
	if GameState.prolog_done:
		return _rustwater_spawn()
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == "schrotthalde":
			var c: Vector3 = WorldManager.feature_center(f)
			return Vector3(c.x, WorldManager.height_at(c.x, c.z), c.z)
	return _rustwater_spawn()


func _build_player() -> void:
	_player = Node3D.new()
	# Modell, sobald eines unter assets/models/characters/player.glb liegt — sonst Kapsel.
	var model: Node3D = AssetRegistry.instantiate("player", AssetRegistry.height_of("player"))
	if model != null:
		_player.add_child(model)
		_player_model = model   # trägt den AnimationPlayer, sobald das Modell animiert ist
	else:
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.5
		cap.height = 1.8
		body.mesh = cap
		body.material_override = _mat(Color(0.23, 0.51, 0.96))
		body.position = Vector3(0.0, 0.9, 0.0)
		_player.add_child(body)
	_player.position = _start_spawn()
	# Gefuehrt wird, was angelegt ist — nicht, was im Spielstand als Wunsch steht.
	_weapon_id = _weapon_kind()
	GameState.weapon_id = _weapon_id
	add_child(_player)
	_equip_weapon_model()
	_cam = Camera3D.new()
	# Kamera nach Diablo-Immortal-Referenz eingemessen: enges Sichtfeld (Godots Standard-75°
	# zieht die Welt auseinander und lässt die Figur winzig wirken), feste Neigung, feste
	# Gierung für den isometrischen Eindruck.
	#
	# WICHTIG — die Kamera hängt NICHT am Spieler-Node: sie würde sonst dessen Drehung erben und
	# sich beim Laufen mitdrehen. Genau das macht Diablo nicht: dort ist die Blickrichtung fix,
	# die Welt behält ihre Orientierung, und nur die Figur dreht sich. Deshalb steht die Kamera
	# in der Szene und folgt dem Spieler in `_process_camera` **nur in der Position**.
	_cam.fov = CAM_FOV
	_cam.rotation_degrees = Vector3(-CAM_PITCH, CAM_YAW, 0.0)
	_cam.far = 8000.0   # Kraterrand & Herz bleiben trotzdem am Horizont sichtbar (Landmark-Navigation)
	add_child(_cam)
	_cam_dist = float(CAM_ZOOM_STEPS[_zoom_step()])
	_cam.position = _player.position + _cam_offset(_cam_dist)


## Hängt das Waffenmodell in die rechte Hand der Figur. Das Spieler-Rig bringt Gewehr-Clips mit
## („Rifle_Charge", „Run_and_Shoot") — die Hand ist also dafür gedacht, etwas zu halten.
##
## Sitz und Griffwinkel lassen sich nicht ausrechnen: wo genau eine generierte Waffe in einer
## generierten Hand liegt, sieht man nur. `WEAPON_GRIP_*` sind deshalb bewusst drei Zahlen an
## einer Stelle, keine verstreute Magie.
## Die Waffe sitzt an der SCHULTER, nicht in der Hand.
##
## Der Karabiner ist eine Zweihandwaffe. Am Handknochen befestigt haengt er an einer Faust, die
## nichts festhaelt — im Bild lag er quer vor dem Bauch, und selbst richtig gedreht bleibt er
## eine einhaendig geschulterte Flinte. Das laesst sich nicht durch Zahlen beheben, dafuer
## braucht es eine Zweihand-Animation, und die gibt es noch nicht.
##
## Solange sie fehlt, ist die ehrliche Loesung: **Kolben an der Schulter, Lauf in Laufrichtung.**
## Die Waffe haengt dafuer am SPIELERKNOTEN statt am Skelett — damit bleibt sie ruhig an ihrem
## Platz, statt einem Arm zu folgen, der etwas anderes tut. Sie bewegt sich nicht mit der
## Animation; das ist der Preis und er ist bewusst bezahlt.
##
## Sobald eine Zweihand-Haltung da ist, wandert sie zurueck an `WEAPON_BONE`.
##
## Die drei Zahlen unten kann man nicht ausrechnen, nur ansehen — sie stehen deshalb beieinander.
const SHOULDER_POS: Vector3 = Vector3(0.19, 1.36, 0.0)     # rechte Schulter, Spielerraum
const SHOULDER_FORWARD_M: float = 0.46                     # halbe Waffenlaenge nach vorn (−Z)
const SHOULDER_TILT_DEG: float = -6.0                      # Lauf leicht gesenkt, kein Parademarsch
func _equip_weapon_model() -> void:
	if _player == null:
		return
	var weapon: Node3D = AssetRegistry.instantiate("weapon_karabiner", 0.0, false)
	if weapon == null:
		return
	_player.add_child(weapon)
	# `fitted` traegt die Skalierung auf Ziellaenge aus `instantiate()` und muss erhalten
	# bleiben — ein direktes Ueberschreiben von `transform` verwirft sie.
	var fitted: Transform3D = weapon.transform
	# Das Modell liegt entlang X — und zwar mit dem KOLBEN bei +X und der Muendung bei −X.
	# Mit +90° um Y zeigte deshalb der Kolben nach vorn und der Lauf steckte in der Schulter.
	# −90° legt −X (die Muendung) auf Godots Vorne (−Z). Die Neigung kommt DANACH und im
	# Spielerraum, sonst kippt sie um die Laufachse und man sieht nichts davon.
	var b: Basis = Basis(Vector3.RIGHT, deg_to_rad(SHOULDER_TILT_DEG)) * Basis(Vector3.UP, -PI * 0.5)
	weapon.transform = Transform3D(b,
		SHOULDER_POS + Vector3(0.0, 0.0, -SHOULDER_FORWARD_M)) * fitted
	# UNSICHTBAR, bis eine Waffe gefuehrt wird.
	#
	# Das Modell wird beim Aufbau der Welt einmal erzeugt und danach nur noch ein- und
	# ausgeblendet — das ist richtig, spart eine Instanziierung im Spiel. Nur stand die
	# Sichtbarkeit bis jetzt auf dem Vorgabewert `true`, und `_refresh_weapon()` korrigierte das
	# erst beim ersten Waffenwechsel. Im Prolog gibt es keinen: Die Figur faengt mit leeren
	# Haenden an, findet den Karabiner erst in der Truhe — und trug ihn die ganze Zeit an der
	# Schulter.
	#
	# Beim Aufwachen war es noch auffaelliger. Die Waffe haengt an einem festen Punkt im
	# SPIELERKNOTEN, nicht an einem Knochen; waehrend die Figur am Boden liegt und sich
	# aufrichtet, bleibt der Knoten stehen. Der Karabiner schwebte also dort in der Luft, wo die
	# Schulter waere, wenn sie schon staende.
	weapon.visible = _weapon_id != "" and AssetRegistry.has_model("weapon_" + _weapon_id)
	_weapon_model = weapon
	_weapon_ruhe = weapon.transform
	# Die Muendung wird GEMESSEN, nicht eingetragen: das Ende der laengsten Achse des Modells.
	# Beim Karabiner ist das X (1,90 von 1,90 x 0,40 x 0,24). Tauscht jemand das Modell, wandert
	# der Punkt mit, und niemand muss eine Zahl nachziehen.
	_muzzle = Node3D.new()
	_muzzle.name = "muendung"
	weapon.add_child(_muzzle)
	_muzzle.position = _muzzle_spitze()


var _hud_layer: CanvasLayer
## Der Rand, an dem die Oberflaeche oben links anfaengt, und die Groesse des Portraets.
const HUD_RAND: float = 12.0
const PORTRAIT_PX: float = 72.0
const BALKEN_W: float = 210.0
const BALKEN_H: float = 16.0
## Wo die Trabanten am Schussknopf sitzen — als Winkel, 0° = rechts, gegen den Uhrzeigersinn.
##
## Der Trank steht **so weit rechts, wie er überhaupt stehen kann** — und das ist nicht 0°.
##
## Der erste Anlauf setzte ihn auf 0°, also genau rechts: kürzester Daumenweg, ohne den
## Schussknopf zu überstreichen. Auf dem Papier richtig. Im Kontrollbild lag er **halb außerhalb
## des Bildschirms**. Der Schussknopf klebt selbst schon in der Ecke, seine Mitte liegt nur
## `MARGIN + RADIUS` = 92 px vom rechten Rand entfernt, und der Trabant sitzt noch einmal 86 px
## weiter draußen. Rechts von diesem Knopf ist schlicht kein Bildschirm mehr.
##
## Der äußerste Winkel, der noch ganz ins Bild passt, folgt direkt aus der Geometrie:
##
##     abstand·cos(w) + trabantradius ≤ 92 − luft   →   w ≥ 47,6°
##
## Und weil der Schussknopf **am Rand verankert** ist, gilt das auf jeder Auflösung gleich: Der
## Abstand zur Kante ändert sich nie. 55° hält gut 16 px Luft und liegt trotzdem klar rechts
## oben — der Daumen bleibt auf seiner Seite. `_trabanten_setzen()` klemmt zusätzlich ins Bild,
## falls jemand später an `MARGIN` oder den Radien dreht.
const TRABANT_WINKEL: Array = [55.0]
## Wie viel Luft ein Trabant mindestens zum Bildrand behält.
const TRABANT_LUFT: float = 8.0
var _trabanten: Array = []
var _trank_btn: ActionSatellite = null
var _portrait_btn: TextureButton = null
var _portrait_rahmen: TextureRect = null
var _hp_bar: ProgressBar = null
var _xp_bar: ProgressBar = null
var _spieler_marken: Label = null
## Wie lange eine Spielermarke nach dem letzten Schaden noch stehen bleibt.
##
## Ohne Nachlauf flackert sie: Der Smog-Schaden faellt nicht jeden Frame an, sondern in
## Schueben — die Marke ginge im Sekundentakt an und aus und waere als Warnung wertlos.
const MARKE_NACHLAUF_SEK: float = 1.2
var _marke_smog_bis: float = 0.0
var _marke_sumpf_bis: float = 0.0


## Einen Trank trinken — und sagen, was passiert ist.
##
## Die Regel selbst steht in `GameState`, nicht hier: Wie viel ein Trank heilt, ist eine Frage
## der Spielbalance und keine der Oberflaeche. Die Oberflaeche fragt nur nach und zeigt an.
func _trank_trinken() -> void:
	if _in_cine() or _in_flight() or _overlay_open() or _wach_left > 0.0:
		return
	var neu_hp: float = GameState.trank_trinken(_hp)
	if neu_hp < 0.0:
		if GameState.potions <= 0:
			_say("⚗ Kein Trank mehr.", 1.6)
		else:
			_say("⚗ Nicht noetig — du bist heil.", 1.6)
		return
	var geheilt: int = roundi(neu_hp - _hp)
	_hp = neu_hp
	_say("⚗ Trank getrunken — %d Leben zurueck (%d uebrig)." % [geheilt, GameState.potions], 2.0)
	_update_hud()


## Ein Balken im Ton der Welt: dunkle Fassung, warme Fuellung, kein Rahmen.
func _hud_balken(voll: Color, leer: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(BALKEN_W, BALKEN_H)
	b.size = Vector2(BALKEN_W, BALKEN_H)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hinten := StyleBoxFlat.new()
	hinten.bg_color = leer
	hinten.set_corner_radius_all(3)
	hinten.set_border_width_all(1)
	hinten.border_color = Color(0.10, 0.08, 0.07, 0.85)
	var vorn := StyleBoxFlat.new()
	vorn.bg_color = voll
	vorn.set_corner_radius_all(3)
	b.add_theme_stylebox_override("background", hinten)
	b.add_theme_stylebox_override("fill", vorn)
	return b


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_layer = layer
	# ── Das Portraet oben links ───────────────────────────────────────────────
	#
	# Es ist kein Schmuck, sondern der KNOPF fuer den Rucksack. Auf dem Handy gab es dafuer
	# bisher nur `[Tab]` — also ausgerechnet auf der Zielplattform gar nichts. Und ein Portraet
	# ist der Ort, an dem jeder danach sucht: Wo man sich selbst sieht, greift man nach seinen
	# Sachen.
	#
	# Das Bild ist aus dem letzten Bild des Intro-Films geschnitten. Damit ist die Figur oben
	# links dieselbe, die man im Film gesehen hat und die auf dem Titel steht — drei Stellen,
	# ein Gesicht, ohne dass jemand etwas malen musste.
	_portrait_btn = TextureButton.new()
	_portrait_btn.texture_normal = UiAssets.texture("portrait_held")
	_portrait_btn.ignore_texture_size = true
	_portrait_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	_portrait_btn.custom_minimum_size = Vector2(PORTRAIT_PX, PORTRAIT_PX)
	_portrait_btn.size = Vector2(PORTRAIT_PX, PORTRAIT_PX)
	_portrait_btn.position = Vector2(HUD_RAND, HUD_RAND)
	_portrait_btn.tooltip_text = "Rucksack & Charakter  [Tab]"
	_portrait_btn.pressed.connect(_toggle_character)
	layer.add_child(_portrait_btn)
	# Der Rahmen liegt DARUEBER und schluckt keine Tipps — sonst waere der Knopf darunter tot.
	var rahmen: Texture2D = UiAssets.texture("portrait_frame")
	if rahmen != null:
		_portrait_rahmen = TextureRect.new()
		_portrait_rahmen.texture = rahmen
		# `expand_mode` MUSS gesetzt werden, sonst gilt die Bildgroesse.
		#
		# Godots Vorgabe ist `EXPAND_KEEP_SIZE`: Die Textur bestimmt die Mindestgroesse, und ein
		# gesetztes `size` wird beim Eintritt in den Baum wieder darauf hochgezogen. Im Bild
		# stand deshalb ein 470 px grosser Rahmen ueber dem halben Bildschirm, obwohl hier
		# 72 px zugewiesen sind. Es sah aus wie ein Fehler in der Grafik und war einer in einer
		# Vorgabe.
		_portrait_rahmen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_portrait_rahmen.stretch_mode = TextureRect.STRETCH_SCALE
		_portrait_rahmen.position = Vector2(HUD_RAND, HUD_RAND)
		_portrait_rahmen.custom_minimum_size = Vector2(PORTRAIT_PX, PORTRAIT_PX)
		_portrait_rahmen.size = Vector2(PORTRAIT_PX, PORTRAIT_PX)
		_portrait_rahmen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_portrait_rahmen)
	# Leben und Erfahrung als BALKEN neben dem Portraet. Eine Zahl muss man lesen; einen Balken
	# sieht man. Beides steht trotzdem noch als Zahl darin, weil „wie viel genau" im Kampf
	# zaehlt und ein Balken das nicht beantwortet.
	_hp_bar = _hud_balken(Color(0.72, 0.16, 0.14), Color(0.34, 0.09, 0.08))
	_hp_bar.position = Vector2(HUD_RAND + PORTRAIT_PX + 10.0, HUD_RAND + 6.0)
	layer.add_child(_hp_bar)
	_xp_bar = _hud_balken(Color(0.86, 0.68, 0.24), Color(0.32, 0.26, 0.10))
	_xp_bar.position = Vector2(HUD_RAND + PORTRAIT_PX + 10.0, HUD_RAND + 6.0 + BALKEN_H + 5.0)
	_xp_bar.size.y = BALKEN_H * 0.6
	layer.add_child(_xp_bar)
	# Was gerade AN MIR frisst — rechts neben dem Lebensbalken, wohin der Blick beim Sinken
	# ohnehin faellt.
	#
	# Ueber den Gegnern stehen diese Marken seit Langem, ueber dem Spieler stand nie eine.
	# Dabei ist der Schaden hier am schwersten zu deuten: Smog und Strahlensumpf ziehen Leben
	# ab, ohne dass jemand schiesst. Einen Satz dazu gab es, aber nur alle 2,2 Sekunden — wer
	# ihn verpasst, sieht bloss Leben verschwinden und haelt es fuer einen Fehler. Eine Marke,
	# die STEHT, solange es frisst, beantwortet das dauerhaft.
	_spieler_marken = Label.new()
	_spieler_marken.position = Vector2(HUD_RAND + PORTRAIT_PX + 10.0 + BALKEN_W + 8.0,
		HUD_RAND + 3.0)
	_spieler_marken.add_theme_font_size_override("font_size", 17)
	_spieler_marken.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_spieler_marken)
	_hud = Label.new()
	_hud.position = Vector2(HUD_RAND + PORTRAIT_PX + 10.0,
		HUD_RAND + 6.0 + BALKEN_H + 5.0 + BALKEN_H * 0.6 + 6.0)
	_hud.add_theme_font_size_override("font_size", 15)
	layer.add_child(_hud)
	# Ortsschrift: Beim Betreten eines Ortes zieht sein Name gross und gesperrt ueber die Mitte
	# und blendet wieder weg. Kostet nichts und macht aus einem Punkt auf der Karte einen Ort,
	# an dem man ANGEKOMMEN ist — genau die Einblendung aus den Diablo-Vorlagen.
	_zone_lbl = Label.new()
	_zone_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_zone_lbl.position = Vector2(-300.0, -40.0)
	_zone_lbl.custom_minimum_size = Vector2(600.0, 0.0)
	_zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_lbl.add_theme_font_size_override("font_size", 34)
	_zone_lbl.add_theme_constant_override("outline_size", 6)
	_zone_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	_zone_lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_zone_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_zone_lbl)
	# Die Meldungszeile bekommt eine feste Breite und wird um die halbe davon nach links
	# gerückt. Ohne das beginnt sie in der Bildmitte und wächst mit dem Text nach rechts aus
	# dem Bild heraus — gemessen ragte sie bei 1152 px Fensterbreite 260 px darüber hinaus.
	_dialog = DialogBox.new()
	_dialog.dismissed.connect(_on_dialog_dismissed)
	layer.add_child(_dialog)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -TOAST_W * 0.5
	_toast.offset_right = TOAST_W * 0.5
	_toast.offset_top = TOAST_TOP
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(_toast)
	# Minikarte oben rechts — Nahansicht im 200-m-Umkreis (Minimap.LOCAL_RADIUS_M).
	_minimap = Minimap.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.position = Vector2(-Minimap.MAP_PX - 14.0, 12.0)
	layer.add_child(_minimap)
	# Joystick-Anzeige ganz oben drüber (zeichnet nur, wenn gezogen wird).
	_stick = VirtualStick.new()
	_stick.radius = STICK_RADIUS
	layer.add_child(_stick)
	# Schuss-Knopf unten rechts — die Gegenhand zum Joystick unten links.
	_fire_btn = FireButton.new()
	layer.add_child(_fire_btn)
	# Munitionsanzeige direkt darunter (GDD §7.4.0): Der Vorrat gehoert dorthin, wo der Daumen
	# ohnehin hinschaut — gelb bei Knappheit, rot bei leer.
	_ammo_lbl = Label.new()
	_ammo_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ammo_lbl.position = Vector2(-FireButton.RADIUS * 2.0 - FireButton.MARGIN, -FireButton.MARGIN + 4.0)
	_ammo_lbl.custom_minimum_size = Vector2(FireButton.RADIUS * 2.0, 0.0)
	_ammo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ammo_lbl.add_theme_font_size_override("font_size", 15)
	layer.add_child(_ammo_lbl)
	# ── Die Trabanten am Schussknopf ──────────────────────────────────────────
	#
	# Traenke standen seit jeher im Spielstand und es gab keinen Weg, sie zu benutzen. Der erste
	# Anlauf haengte einen Knopf ueber den Abzug — richtig gedacht und trotzdem falsch: Er lag
	# NEBEN der Hand, und wer im Gefecht trinken will, muss den Daumen dorthin bringen, waehrend
	# jemand auf ihn schiesst.
	#
	# Jetzt liegen sie als Trabanten AUSSEN am Schussknopf, in derselben Handbewegung. Der
	# rechteste ist der Trank. Sie sind kleiner und liegen ausserhalb seines Randes, und beides
	# ist Absicht: Wer blind greift, trifft die Mitte — ein Fehlgriff soll den Schuss ausloesen
	# und nicht den Trank verbrauchen.
	_trank_btn = ActionSatellite.new()
	_trank_btn.ausgeloest.connect(_trank_trinken)
	layer.add_child(_trank_btn)
	_trabanten.append(_trank_btn)
	# Aktionsleiste unten Mitte: erscheint nur, wenn etwas in Reichweite ist. Ohne sie gäbe es
	# auf dem Handy keinen Weg, jemanden anzusprechen oder die Bahn zu nehmen — das ging bisher
	# nur über die Tastatur, also ausgerechnet nicht auf der Zielplattform.
	_actions = VBoxContainer.new()
	_actions.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_actions.position = Vector2(-140.0, -168.0)
	_actions.custom_minimum_size = Vector2(280.0, 0.0)
	_actions.add_theme_constant_override("separation", 6)
	layer.add_child(_actions)
	# Zoom-Knoepfe unter der Minikarte. Auf dem Handy der verlaessliche Weg — die Kneifgeste
	# gibt es zwar, aber beide Daumen liegen dort meist auf Joystick und Abzug.
	_zoom_btns = HBoxContainer.new()
	_zoom_btns.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_zoom_btns.position = Vector2(-Minimap.MAP_PX - 14.0, 12.0 + Minimap.MAP_PX + 8.0)
	_zoom_btns.add_theme_constant_override("separation", 6)
	for entry in [["−", -1], ["+", 1]]:
		var zb := Button.new()
		zb.text = String(entry[0])
		zb.custom_minimum_size = Vector2(46.0, 42.0)
		zb.add_theme_font_size_override("font_size", 19)
		zb.pressed.connect(_zoom_by.bind(int(entry[1])))
		_zoom_btns.add_child(zb)
		_hud_buttons.append(zb)
	layer.add_child(_zoom_btns)
	# Hier stand ein zweiter Knopf mit einem Rucksack-Zeichen, direkt unter dem Portraet — und
	# beide fuehrten an denselben Ort. Zwei Eingaenge zu einem Raum sind kein Komfort, sondern
	# die Frage, ob dahinter zweierlei liegt: Wer den Rucksack sieht, sucht seine Faehigkeiten
	# woanders und findet sie nie.
	#
	# Jetzt gibt es EINEN Eingang: das Portraet. Dort sucht ohnehin jeder — wo man sich selbst
	# sieht, greift man nach seinen Sachen —, und dahinter liegt alles in Reitern: Ausruestung
	# samt Beutel, und Faehigkeiten. Auf der Tastatur weiterhin [C].
	# Weltkarte ZULETZT: In einem CanvasLayer ist die Kindreihenfolge die Zeichenreihenfolge,
	# und eine Vollbildkarte, unter der die Aktionsleiste hervorlugt, ist keine.
	_build_world_map(layer)
	_shop = ShopScreen.new()
	layer.add_child(_shop)
	_char = CharacterScreen.new()
	layer.add_child(_char)


## Vollbild-Weltkarte: liegt fertig gebaut, aber unsichtbar über allem und geht per Tippen auf
## die Minikarte auf (oder mit M). Bewusst NICHT bei jedem Öffnen neu gebaut — die Karte zeichnet
## sich ohnehin bei jedem Frame neu, und ein Aufbau pro Öffnen wäre ein Ruckler ohne Gegenwert.
func _build_world_map(layer: CanvasLayer) -> void:
	_map_overlay = Control.new()
	_map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_overlay.visible = false
	layer.add_child(_map_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.04, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_overlay.add_child(dim)
	_world_map = Minimap.new()
	_world_map.full_world = true   # vor add_child: `_ready` wertet das Flag aus
	_map_overlay.add_child(_world_map)
	var hint := Label.new()
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-180.0, -46.0)
	hint.custom_minimum_size = Vector2(360.0, 0.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.text = "Tippen oder M schließt die Karte"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_overlay.add_child(hint)


func _map_is_open() -> bool:
	return _map_overlay != null and _map_overlay.visible


## Aktuelle Zoomstufe, gegen die Tabelle geklemmt — ein Altstand koennte einen Index tragen,
## den es nicht mehr gibt.
func _zoom_step() -> int:
	return clampi(GameState.cam_zoom, 0, CAM_ZOOM_STEPS.size() - 1)


## Zoomstufe setzen. Meldet die Stufe nur, wenn sie sich wirklich aendert — beim Kneifen
## kaeme sonst pro Frame eine Einblendung.
func _set_zoom(step: int) -> void:
	var neu: int = clampi(step, 0, CAM_ZOOM_STEPS.size() - 1)
	if neu == _zoom_step():
		return
	GameState.cam_zoom = neu
	_say("⊙ %s (%.1f m)" % [String(CAM_ZOOM_NAMES[neu]), float(CAM_ZOOM_STEPS[neu])], 1.2)


func _zoom_by(delta_steps: int) -> void:
	_set_zoom(_zoom_step() + delta_steps)


## Liegt IRGENDEIN Vollbild-Overlay ueber der Welt? Karte und Laden sperren beide dasselbe:
## Bewegung und Abzug. Eine gemeinsame Abfrage, damit ein spaeter dazukommender Bildschirm
## nicht wieder an zwei Stellen nachgetragen werden muss.
func _overlay_open() -> bool:
	return _map_is_open() or (_shop != null and _shop.visible) or (_char != null and _char.visible)


## Blendet aus, was sonst UEBER dem Overlay stehenbliebe. Die Aktionsleiste und der Schuss-Knopf
## sind eigene Controls; Zeichenreihenfolge allein genuegt bei ihnen nicht.
func _set_hud_hidden(hidden: bool) -> void:
	if _actions != null:
		_actions.visible = not hidden
	if _fire_btn != null:
		_fire_btn.visible = not hidden
	if _ammo_lbl != null:
		_ammo_lbl.visible = not hidden
	if _zoom_btns != null:
		_zoom_btns.visible = not hidden


## Oeffnet Werkstatt oder Geschaefte.
func _open_shop(which: int) -> void:
	if _shop == null:
		return
	_close_world_map()
	_shop.open(which)
	_end_stick()
	_set_hud_hidden(true)


func _close_shop() -> void:
	if _shop != null:
		_shop.close()
	_set_hud_hidden(false)


## Charakter-Bildschirm. Der einzige, der an keinem Ort haengt: Was man traegt und kann, geht
## einen ueberall etwas an.
func _toggle_character(which: int = CharacterScreen.Tab.AUSRUESTUNG) -> void:
	if _char == null:
		return
	if _char.visible:
		_close_character()
		return
	_close_world_map()
	_close_shop()
	_char.open(which)
	_end_stick()
	_set_hud_hidden(true)


func _close_character() -> void:
	if _char != null:
		_char.close()
	_set_hud_hidden(false)


## Beide Karten bekommen denselben Stand — die Nahansicht und die Weltkarte sind dieselbe
## Klasse und unterscheiden sich nur in Mittelpunkt und Maßstab.
func _feed_map(map: Minimap, enemies: Array) -> void:
	if map == null:
		return
	map.player_pos = _player.position
	map.player_dir = _player.rotation.y
	map.enemy_positions = enemies
	map.queue_redraw()


## Öffnet die Weltkarte und misst sie dabei auf den aktuellen Bildschirm ein. Die Messung
## gehört hierher und nicht in den Aufbau: Auf dem Handy dreht sich das Gerät, und eine beim
## Start berechnete Größe wäre nach dem ersten Drehen falsch.
func _open_world_map() -> void:
	if _map_overlay == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var s: float = minf(vp.x, vp.y) * 0.82
	_world_map.size = Vector2(s, s)
	_world_map.position = (vp - Vector2(s, s)) * 0.5
	_map_overlay.visible = true
	# Der Joystick darf nicht mit gedrücktem Daumen hängenbleiben, sonst läuft die Figur unter
	# der offenen Karte weiter.
	_end_stick()
	# Die Aktionsleiste zeichnet trotz Zeichenreihenfolge weiter ihre Knöpfe: Sie ist ein
	# eigenes Control und würde als Streifen über der Karte stehenbleiben. Der Schuss-Knopf
	# genauso — und ein sichtbarer Abzug, der nichts auslöst, sieht nach Fehler aus.
	_set_hud_hidden(true)


func _close_world_map() -> void:
	if _map_overlay != null:
		_map_overlay.visible = false
	_set_hud_hidden(false)


## Der Lebensbalken ist ein STRICH, kein Balken.
##
## Vorher war es ein Quader von 1,40 × 0,12 × 0,12 m über jedem Kopf — bei einer 1,8-m-Figur ein
## fingerdickes Brett, das breiter war als der Gegner und aus jeder Richtung Volumen zeigte.
## Ein Zustandsanzeiger soll man lesen, nicht ansehen. Jetzt: 4,5 cm hoch, immer zur Kamera
## gedreht (also nie schräg oder von der Kante), auf einem dunklen Untergrund, damit der Rest-
## anteil auch vor hellem Sand ablesbar bleibt.
const HP_BAR_W: float = 1.0
const HP_BAR_H: float = 0.045
const HP_BAR_RAND: float = 0.018


## Ein Streifen der Lebensleiste. `versatz` schiebt ihn minimal nach vorn, damit die Füllung
## nicht mit ihrem eigenen Untergrund um Bildpunkte streitet.
##
## Mittig verankert, nicht linksbündig: Die Leiste ist auf die Kamera gedreht, ihr Ursprung
## bleibt aber im Raum des Gegners. Ein Anker am linken Ende säße damit auf einem Punkt, der
## mitschwenkt, sobald sich der Gegner dreht — die Leiste würde beim Umdrehen seitlich
## weglaufen. Der Restanteil schrumpft deshalb symmetrisch.
func _hp_streifen(breite: float, hoehe: float, farbe: Color, versatz: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(breite, hoehe)
	q.center_offset = Vector3(0.0, 0.0, versatz)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if farbe.a < 1.0 \
		else BaseMaterial3D.TRANSPARENCY_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Baut einen Gegner-Node (Modell oder Primitive + Lebensleiste), fügt ihn NICHT in die Szene
## ein (Aufrufer setzt zuerst die Position) und trägt ihn NICHT in `_enemies` ein.
func _make_enemy(type_id: String, anfuehrer: bool = false) -> Dictionary:
	var target: CombatTarget = CombatTarget.from_type(type_id, { "anfuehrer": anfuehrer })
	var node := Node3D.new()
	# Modell, sobald eines unter assets/models/enemies/<typ>.glb liegt — sonst Primitive.
	var asset: String = AssetRegistry.enemy_asset(type_id)
	var hoehe: float = AssetRegistry.height_of(asset) \
		* (CombatData.ANFUEHRER_GROESSE_MUL if anfuehrer else 1.0)
	var model: Node3D = AssetRegistry.instantiate(asset, hoehe)
	if model != null:
		node.add_child(model)
		AssetRegistry.play_clip(model, "idle")
	else:
		var body := MeshInstance3D.new()
		if target.classification == CombatData.MECHANICAL:
			var bm := BoxMesh.new()                  # Kampf-Lesbarkeit: eckig = Maschine
			bm.size = Vector3(1.1, 1.4, 1.1)
			body.mesh = bm
			body.material_override = _mat(Color(0.49, 0.83, 0.99))
			body.position = Vector3(0.0, 0.7, 0.0)
		else:
			var cm := CapsuleMesh.new()              # rund = organisch
			cm.radius = 0.45
			cm.height = 1.6
			body.mesh = cm
			body.material_override = _mat(Color(0.97, 0.44, 0.44))
			body.position = Vector3(0.0, 0.8, 0.0)
		node.add_child(body)
	# Leiste über den Kopf des jeweiligen Gegners — bei einem 4-m-Goliath steckte eine feste
	# Höhe sonst mitten im Modell.
	var traeger := Node3D.new()
	traeger.position = Vector3(0.0, AssetRegistry.height_of(asset) + 0.32, 0.0)
	node.add_child(traeger)
	# Der Untergrund ist der VERLORENE Teil, nicht bloss ein Rand: Ein Strich, der nur kuerzer
	# wird, sagt „wenig"; einer, hinter dem dunkles Rot steht, sagt „so viel ist schon weg".
	traeger.add_child(_hp_streifen(HP_BAR_W + HP_BAR_RAND * 2.0, HP_BAR_H + HP_BAR_RAND * 2.0,
		Color(0.24, 0.05, 0.04, 0.88), 0.0))
	var bar: MeshInstance3D = _hp_streifen(HP_BAR_W, HP_BAR_H, Color(0.52, 0.80, 0.09), 0.004)
	traeger.add_child(bar)
	# Bringt das Modell eine Lauf-Animation mit? Wenn nicht, übernimmt `_scurry` die Bewegung —
	# sonst gleitet die Figur reglos über den Sand, was bei einem Rudel besonders auffällt.
	var animated: bool = model != null \
		and AssetRegistry.find_clip(AssetRegistry.animation_player(model), "walk") != ""
	# Trefferradius aus der Zielhoehe des Modells: Ein Kessel-Klaeffer (0,8 m) ist ein deutlich
	# kleineres Ziel als der Schwere Ernter (4 m), und genau das soll die Streuung spueren.
	# Gedeckelt, damit weder eine Ratte unmoeglich noch ein Boss trivial wird.
	var radius: float = clampf(AssetRegistry.height_of(asset) * 0.30, 0.32, 1.40)
	# `windup` = −1 heisst „holt gerade nicht aus", `cooldown` zaehlt bis zum naechsten Angriff.
	# Beide gehoeren in den Gegner, nicht in eine Nebenliste: Ein Gegner, der stirbt, nimmt
	# seinen halb ausgefuehrten Schlag mit.
	# ── Die Zustandsmarken ────────────────────────────────────────────────────
	#
	# Das Kampfsystem verteilt seit Langem Zustaende — Kurzschluss, Verbluten, Ueberhitzung,
	# Korrosion —, und der Spieler konnte KEINEN davon sehen. Wer eine Saeureflasche wirft und
	# nichts passiert, lernt daraus nur, dass Saeureflaschen nichts tun; dass sie gerade die
	# Panzerung aufgeloest hat, stand nirgends.
	#
	# Sie stehen ueber der Lebensleiste und nicht darunter: Der Blick geht beim Zielen nach oben
	# zum Kopf, und was dort steht, sieht man beilaeufig mit.
	var marken := Label3D.new()
	marken.font_size = 44
	marken.pixel_size = LABEL_PIXEL
	marken.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marken.outline_size = 5
	marken.position = Vector3(0.0, 0.30, 0.0)
	marken.visibility_range_end = 90.0
	traeger.add_child(marken)
	if anfuehrer:
		AssetRegistry.schimmer_anlegen(node, CombatData.ANFUEHRER_SCHIMMER)
	return { "node": node, "target": target, "bar": bar, "model": model, "marken": marken,
		"animated": animated, "phase": randf() * TAU, "radius": radius,
		"windup": -1.0, "cooldown": 0.0 }


## Welche Zustandsmarken traegt dieser Gegner gerade?
##
## Als Text und nicht als Bild, solange keine Symbole da sind (`docs/HUD.md` listet sie auf).
## Ein Zeichen, das man sieht, ist besser als ein Bild, das noch niemand gemalt hat — und wenn
## die Symbole kommen, wird hier eine Zeile ausgetauscht.
static func status_marken(t: CombatTarget, jetzt_ms: int) -> String:
	var m: String = ""
	if t.is_stunned(jetzt_ms):
		m += HudGlyph.z("kurzschluss")
	if t.has_dot():
		m += HudGlyph.z("dot")
	if t.armor <= 0 and t.max_armor > 0:
		m += HudGlyph.z("panzer_weg")
	return m


## Welche Zustandsmarken traegt der SPIELER gerade?
##
## Dieselbe Idee wie ueber den Gegnern, nur an der eigenen Lebensleiste — und hier wiegt sie
## schwerer: Ein Gegner, der Schaden nimmt, ist erklaert (man hat geschossen). Leben, das ohne
## sichtbaren Grund sinkt, liest sich als Fehler des Spiels. Genau das passiert im Smog und im
## Strahlensumpf.
##
## Rein gerechnet und ohne Zugriff auf die Szene, damit der Test die Wahrheitstafel durchgehen
## kann, statt ein Bild zu beschreiben.
static func spieler_marken(jetzt: float, smog_bis: float, sumpf_bis: float) -> String:
	var m: String = ""
	# Der Sumpf zuerst: Er ist die haertere Grenze und soll vorne stehen, wenn beides zutrifft.
	if jetzt < sumpf_bis:
		m += HudGlyph.z("strahlung")
	if jetzt < smog_bis:
		m += HudGlyph.z("smog")
	return m


func _spawn_pack() -> void:
	# Der erste Kontakt steht direkt VOR dem Südtor — Rustwater ist befriedet (TOWN_SAFE_M),
	# drinnen spawnt nichts, also gehört das Empfangskomitee dorthin, wo man beim Verlassen
	# der Stadt hinschaut. Danach übernimmt der kontinuierliche Spawner.
	# Auch das Empfangskomitee wartet, bis die Erstbegegnung gelaufen ist. Es steht zwar am
	# Suedtor und nicht in der Grube — aber wer im Prolog dorthin laeuft, traefe sonst ein
	# ganzes Rudel, bevor er den ersten Gegner ueberhaupt gesehen hat.
	if stille_vor_dem_ersten(GameState.erst_gegner_done, GameState.prolog_done):
		return
	var gate: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, TOWN_SAFE_M + 12.0)
	for i in 4:
		var type_id: String = "klaeffer" if i == 3 else "outlaw"
		# Einer fuehrt. Ein Rudel ohne Kopf ist eine Menge gleicher Gegner; mit einem hat es
		# eine Mitte, auf die man zuerst schiesst oder um die man einen Bogen macht.
		var e: Dictionary = _make_enemy(type_id, i == 0)
		(e["node"] as Node3D).position = gate + Vector3(float(i) * 5.0 - 7.5, 0.0, float(i % 2) * 6.0)
		add_child(e["node"])
		_enemies.append(e)
	# Dahinter eine Panzer-Rotte: schwerer, langsamer, aus der Ferne als Silhouette erkennbar —
	# und die zweite Welle, wenn das Rudel liegt.
	for i in STARTER_TANKS:
		var e: Dictionary = _make_enemy("konstrukt")
		(e["node"] as Node3D).position = gate + Vector3(float(i) * 9.0 - 9.0, 0.0, 22.0 + float(i % 2) * 7.0)
		add_child(e["node"])
		_enemies.append(e)


## Setzt ein Rudel um `center` ab (locker gestreut, nicht auf einem Punkt gestapelt).
## Kappe und Bauten-Sperre gelten pro Tier — lieber ein kleinerer Schwarm als einer in der Wand.
func _spawn_swarm(type_id: String, center: Vector3) -> void:
	var count: int = mini(randi_range(SWARM_MIN, SWARM_MAX), ENEMY_MAX - _enemies.size())
	for i in count:
		var a: float = randf() * TAU
		var r: float = randf_range(0.8, SWARM_SPREAD_M)
		var pos: Vector3 = center + Vector3(cos(a) * r, 0.0, sin(a) * r)
		if _blocked(pos):
			continue
		var e: Dictionary = _make_enemy(type_id)
		(e["node"] as Node3D).position = pos
		add_child(e["node"])
		_enemies.append(e)


## Nachschub aus dem echten Biom-Gegnermix (WorldManager), solange die Kappe nicht erreicht ist.
## Spawnt in Lauf-Distanz um den Spieler herum, aber nie in einem noch gesperrten Sektor
## (Gates sind aus GameState/WorldManager abgeleitet — sobald die Kampagne hier andockt,
## respektiert der Nachschub automatisch Kapitel-/Tor-Fortschritt).
## Ist die Welt noch LEER, weil der erste Gegner noch nicht gezeigt wurde?
##
## Der Prolog erzaehlt eine bestimmte Sache: Der Held erwacht allein in einer Grube, findet ein
## Gewehr, steigt heraus — und DANN steht zum ersten Mal etwas vor ihm, das hier herumlaeuft.
## Er soll es ansehen koennen, sich wundern, was das ist. Das ist der ganze Sinn der Szene.
##
## Genau das war kaputt: Der Dauer-Nachschub lief von der ersten Sekunde an weiter und setzte
## alle vier Sekunden irgendetwas im Umkreis von 18 bis 45 Metern ab — also mitten in die
## Grube. Wer erwachte, stand in einem belebten Krater, und die grosse Erstbegegnung war der
## siebte Gegner, den man sah.
##
## Rein gerechnet und ohne Szenenzugriff, damit der Test die Wahrheitstafel durchgehen kann.
static func stille_vor_dem_ersten(erst_gegner_done: bool, prolog_done: bool) -> bool:
	# Nach dem Prolog gilt die Regel nicht mehr — wer eine zweite Runde spielt, will eine
	# bevoelkerte Welt und nicht wieder eine leere.
	if prolog_done:
		return false
	# Und sobald die Erstbegegnung gelaufen ist, darf nachrücken: Sie hat ihren Zweck erfuellt.
	return not erst_gegner_done


func _process_spawns(delta: float) -> void:
	if stille_vor_dem_ersten(GameState.erst_gegner_done, GameState.prolog_done):
		return
	_spawn_cd -= delta
	if _spawn_cd > 0.0 or _enemies.size() >= ENEMY_MAX:
		return
	_spawn_cd = SPAWN_INTERVAL_SEC
	var ang: float = randf() * TAU
	var dist: float = randf_range(SPAWN_MIN_DIST, SPAWN_MAX_DIST)
	var pos: Vector3 = _player.position + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
	pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
	pos.z = clampf(pos.z, -(WorldManager.WORLD_METERS - 20.0), -20.0)
	if _in_town(pos):
		return   # Rustwater ist befriedet
	var rel: Vector2 = WorldManager.scene_to_world(pos)
	if not WorldManager.is_walkable(rel) or _blocked(pos):
		return   # nur dort, wo der Spieler auch hinkommt — und nicht mitten in einem Bau
	if not WorldManager.can_enter_sector(WorldManager.sector_of_pos(rel)):
		return   # jenseits eines noch geschlossenen Tors — hier siedelt sich (noch) nichts an
	var zone: String = WorldManager.zone_at(rel)
	if zone != "" and WorldManager.is_safe_zone(zone):
		return   # befriedete Aktionszone (Hub / eigene Fraktionsbasis)
	var biome_id: String = WorldManager.biome_at(rel)
	var type_id: String = WorldManager.pick_enemy_type(biome_id, GameState.is_revealed)
	# NACHTTIERE kommen nur im Dunkeln heraus. Das ist der Grund, warum die Uhr etwas aendert:
	# Wer bei Tag durch das Rattengestrueppp laeuft, sieht Sand; wer es nach Sonnenuntergang
	# tut, laeuft in ein Rudel. Wird bei Tag gewuerfelt, faellt der Wurf einfach aus — kein
	# Ersatzgegner, denn eine leere Wueste bei Mittagshitze ist die richtige Antwort.
	if bool(CombatData.ENEMY_TYPES[type_id].get("nocturnal", false)) \
			and not DayCycle.is_dark(GameState.hour):
		return
	# Schwarm-Typen (CombatData: Ratten, Kläffer) treten NIE einzeln auf — einzeln sind sie
	# weder gefährlich noch schön, im Rudel sind sie beides. Die Kappe gilt weiterhin.
	if bool(CombatData.ENEMY_TYPES[type_id].get("swarm", false)):
		_spawn_swarm(type_id, pos)
		return
	var e: Dictionary = _make_enemy(type_id)
	(e["node"] as Node3D).position = pos
	add_child(e["node"])
	_enemies.append(e)


## Truhen einmalig setzen: eine am Mittelpunkt jedes Ortes AUSSER Rustwater. Zehn Stueck auf
## 5000 x 5000 m — das ist die Seltenheit, die eine Truhe wieder zu einem Fund macht. Der
## Heimathafen bleibt leer: Beute holt man sich draussen.
func _build_chests() -> void:
	for id in WorldManager.POIS.keys():
		if String(id) == "rustwater":
			continue
		_spawn_chest_at(_chest_spot(String(id)))


## Wo die Truhe eines Ortes steht.
##
## Normalerweise in seiner Mitte. In der SCHROTTGRUBE nicht: Dort ist die Mitte der Platz, auf
## dem der Held liegt — die Truhe stand also buchstaeblich auf ihm, und im ersten Bild des
## Spiels sah man einen Kasten statt einer Figur.
##
## Sie rueckt deshalb an den Rand der Lache, in Richtung des Lokomotivenwracks: Das ist das
## groesste Ding in der Grube und das, worauf der Blick beim Aufwachen ohnehin faellt. Die
## Richtung kommt aus der SZENE (`_pit_wrack`), nicht aus einer Zahl — wer das Wrack im Editor
## verschiebt, nimmt die Truhe mit.
const CHEST_RIM_M: float = 0.7
func _chest_spot(id: String) -> Vector3:
	var mitte: Vector3 = WorldManager.poi_scene_position(id)
	if id != "schrott_minen" or _pit_wrack == Vector3.INF:
		return mitte
	var hin := Vector3(_pit_wrack.x - mitte.x, 0.0, _pit_wrack.z - mitte.z)
	if hin.length() < 1.0:
		return mitte
	return mitte + hin.normalized() * (PUDDLE_R_M + CHEST_RIM_M)


func _spawn_chest_at(raw: Vector3, art: String = ChestData.STANDARD) -> void:
	var pos: Vector3 = Vector3(raw.x, WorldManager.height_at(raw.x, raw.z), raw.z)
	var node := Node3D.new()
	var eintrag: Dictionary = ChestData.art(art)
	var modell_name: String = String(eintrag["modell"])
	var model: Node3D = AssetRegistry.instantiate(modell_name,
		AssetRegistry.height_of(modell_name))
	if model != null:
		node.add_child(model)
	else:
		node.add_child(_truhe_platzhalter(art))
	node.position = pos
	add_child(node)
	# Die Beutekammer wird auch in der SCHRIFT anders angesagt. Wer sie am Horizont sieht, soll
	# nicht erst hinlaufen muessen, um zu wissen, dass sich der Weg lohnt.
	var farbe: Color = Color(1.0, 0.85, 0.4) if art == ChestData.STANDARD \
		else Color(0.62, 0.92, 1.0)
	var label: Label3D = _label(pos + Vector3(0.0, 1.3, 0.0),
		"▩ %s" % String(eintrag["name"]), farbe, LBL_TRUHE, 120.0)
	_chests.append({ "node": node, "label": label, "pos": pos, "looted": false, "cd": 0.0,
		"art": art })


## Der gezeichnete Ersatz, solange kein Modell da ist.
##
## Er ist NICHT dieselbe Kiste in einer anderen Farbe. Eine Bosstruhe muss sich auf dreissig
## Meter von einer gewoehnlichen unterscheiden, sonst laeuft man an ihr vorbei — und weil eine
## Farbe im Daemmerlicht kaum traegt, unterscheidet sich zuerst die FORM: hoeher, mit Sockel
## und Deckelband, und ein leichtes Glimmen darauf.
func _truhe_platzhalter(art: String) -> Node3D:
	var wurzel := Node3D.new()
	if art == ChestData.STANDARD:
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 0.5, 0.4)
		body.mesh = bm
		body.material_override = _mat(Color(0.55, 0.38, 0.16))
		body.position = Vector3(0.0, 0.25, 0.0)
		wurzel.add_child(body)
		return wurzel
	# Beutekammer: Sockel, Kasten, Band — drei Teile statt einem.
	var messing: StandardMaterial3D = _mat(Color(0.78, 0.62, 0.26))
	messing.metallic = 0.7
	messing.roughness = 0.32
	messing.emission_enabled = true
	messing.emission = Color(0.95, 0.78, 0.34)
	messing.emission_energy_multiplier = 0.28
	for teil in [[Vector3(0.86, 0.12, 0.62), 0.06, _mat(Color(0.22, 0.20, 0.18))],
			[Vector3(0.74, 0.52, 0.52), 0.38, _mat(Color(0.30, 0.24, 0.14))],
			[Vector3(0.80, 0.10, 0.58), 0.66, messing]]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = teil[0]
		mi.mesh = box
		mi.material_override = teil[2]
		mi.position = Vector3(0.0, float(teil[1]), 0.0)
		wurzel.add_child(mi)
	return wurzel


## Ortsschrift. Sperrt den Namen mit Leerzeichen, damit er wie eine Inschrift wirkt und nicht
## wie eine Beschriftung, und blendet ihn ueber vier Sekunden ein und wieder aus.
##
## Ausgeloest wird beim WECHSEL der Zone — beim Verlassen genauso wie beim Betreten, damit die
## offene Wueste auch als Ort benannt ist. Wer an der Grenze hin und her laeuft, bekommt sie
## trotzdem nur einmal: Der zuletzt angesagte Ort bleibt gemerkt.
const ZONE_TITLE_SEC: float = 4.0

func _process_zone_title(delta: float) -> void:
	if _zone_lbl == null:
		return
	var rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var zone: String = WorldManager.zone_at(rel)
	if zone != _zone_shown:
		_zone_shown = zone
		_zone_t = ZONE_TITLE_SEC
		var name: String = "Offene Wüste" if zone == "" else String(WorldManager.poi(zone)["name"])
		_zone_lbl.text = " ".join(name.to_upper().split(""))
	if _zone_t <= 0.0:
		return
	_zone_t -= delta
	# Eine Sekunde auf, zwei stehen, eine ab.
	var t: float = ZONE_TITLE_SEC - _zone_t
	var a: float = clampf(t, 0.0, 1.0) * clampf(_zone_t, 0.0, 1.0)
	_zone_lbl.modulate = Color(0.98, 0.93, 0.80, a * 0.92)


## Naechste ungeoeffnete Truhe in Reichweite ({} = keine). Grundlage fuer das Hand-Symbol.
func _chest_in_range() -> Dictionary:
	for c in _chests:
		if not bool(c["looted"]) and _player.position.distance_to(c["pos"]) <= CHEST_INTERACT_M:
			return c
	return {}


## Truhen fuellen sich nach einer Weile wieder. Ohne das liefe die Welt nach zehn Funden
## endgueltig trocken — mit Sofort-Respawn waere die Seltenheit dahin.
func _process_chests(delta: float) -> void:
	for c in _chests:
		if not bool(c["looted"]):
			continue
		c["cd"] = float(c["cd"]) - delta
		if float(c["cd"]) <= 0.0:
			c["looted"] = false
			(c["node"] as Node3D).visible = true
			(c["label"] as Label3D).visible = true


## Truhe oeffnen: Der Inhalt FAELLT HERAUS, statt sich still in die Taschen zu buchen. Vorher
## wurde beim Vorbeilaufen automatisch geplündert und ein besseres Teil sofort angelegt — man
## sah nie, was man fand, und entschied nie etwas.
## Die Waffe, mit der das Spiel anfaengt. Sie liegt in der ersten Truhe, nicht in der Hand.
const ERSTE_WAFFE: String = "karabiner"
func _open_chest(c: Dictionary) -> void:
	if c.is_empty() or bool(c["looted"]):
		return
	# Erst das Schloss. Eine Beutekammer steht sichtbar da und laesst sich trotzdem nicht
	# einfach einsammeln — und wer davorsteht, muss ERFAHREN warum und mit welcher Zahl.
	# „Verschlossen" allein ist eine Wand, keine Aufgabe.
	var art_pruef: String = String(c.get("art", ChestData.STANDARD))
	if not ChestData.offen_mit(art_pruef, GameState.schluessel):
		_say(ChestData.schloss_text(art_pruef, GameState.schluessel), 3.0)
		return
	GameState.schluessel -= ChestData.schluessel(art_pruef)
	c["looted"] = true
	c["cd"] = CHEST_RESPAWN_SEC
	(c["node"] as Node3D).visible = false
	(c["label"] as Label3D).visible = false
	var at: Vector3 = c["pos"]
	# Die ERSTE Truhe des Spiels gibt die erste Waffe. Der Held erwacht ohne alles auf der
	# Kippe; ohne diesen Fund bliebe er es. Kein Zufall und keine Beutetabelle — der Anfang
	# einer Geschichte darf nicht auswuerfeln, ob sie stattfindet.
	if GameState.weapons.is_empty():
		var erste: Dictionary = ProgressionManager.make_gear("weapon", "common", "", null,
			ERSTE_WAFFE)
		# Direkt anlegen, nicht auf den Boden werfen: Es ist die einzige Waffe im Spiel, und ein
		# Held, der neben seinem Gewehr steht und die Hand nicht hebt, ist kein Anfang.
		EquipManager.equip_item(erste, "weapon")
		GameState.add_weapon(ERSTE_WAFFE)
		_sync_weapon()
		_say("⚔ %s gefunden — angelegt." % String(erste["name"]), 3.2)
		# Und er sagt etwas dazu. Der Satz stand seit Langem im Storyblatt und wurde im Spiel
		# nie gesprochen:
		#
		#   „Ein Karabiner, Lauf voller Sand. Er passt in deine Hand, als haettest du das schon
		#    tausendmal gemacht. Woher weisst du das?"
		#
		# Er ist die erste Stelle, an der die Figur etwas kann, was sie sich nicht erklaeren
		# kann — dieselbe Frage, die spaeter beim ersten Gegner wiederkommt und die die ganze
		# Geschichte traegt. Ohne ihn ist der Fund eine Ausruestungsmeldung.
		_erste_truhe_szene(at)
	# Was drin ist, steht in `ChestData` und nicht hier: Truhen stehen an zwei ganz
	# verschiedenen Orten (Oberwelt und Stollen), und zwei Zahlenreihen fuer dieselbe Sache
	# driften auseinander, sobald jemand an einer davon dreht.
	var art: String = art_pruef
	_drop(at, "gold", { "amount": ChestData.gold(art) })
	var pool: String = AmmoData.pool_for(_weapon_id if _weapon_id != "" else ERSTE_WAFFE)
	_drop(at, "ammo", { "pool": pool,
		"amount": AmmoData.roll_drop(pool) * int(ChestData.art(art)["muni_mul"]) })
	if ChestData.trank(art):
		_drop(at, "potion", { "amount": 1 })
	for i in ChestData.stuecke(art):
		var slot: String = EquipManager.GEAR_SLOTS[randi_range(0, EquipManager.GEAR_SLOTS.size() - 1)]
		_drop(at, "gear", ProgressionManager.make_gear(slot, ChestData.seltenheit(art)))
	if art == ChestData.STANDARD:
		_say("▩ Die Truhe springt auf.", 2.0)
	else:
		_say("▩ Die Beutekammer gibt nach. Messing, und darunter etwas Besseres.", 2.6)


## Legt ein Fundstueck auf den Boden. Die Beschriftung IST das Fundstueck: Aus Kamerahoehe
## erkennt man ein 30-cm-Objekt im Sand nicht, den Schriftzug darueber schon.
func _drop(at: Vector3, kind: String, data: Dictionary) -> void:
	var ang: float = randf() * TAU
	var r: float = sqrt(randf()) * LOOT_SCATTER_M   # Wurzel: gleichmaessig ueber die Flaeche
	var pos: Vector3 = at + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
	pos.y = WorldManager.height_at(pos.x, pos.z)   # Beute liegt auf dem Boden, nicht auf y = 0
	var text: String = ""
	var col: Color = Color.WHITE
	match kind:
		"gold":
			text = "¤ %d" % int(data["amount"])
			col = Color(1.0, 0.84, 0.35)
		"ammo":
			var p: Dictionary = AmmoData.POOLS[String(data["pool"])]
			text = "%s %d" % [String(p["icon"]), int(data["amount"])]
			col = p["color"]
		"potion":
			text = "⚗ Heiltrank"
			col = Color(0.95, 0.35, 0.45)
		"material":
			text = "▬ %s" % String(data["id"])
			col = Color(0.72, 0.68, 0.60)
		"gear":
			# Kategorie als Beschriftung, Farbe = Seltenheit. Was es GENAU ist, zeigt erst das
			# naechstgelegene Stueck (`_process_ground`) — sonst steht der Boden voller Romane.
			text = String(ProgressionManager.GEAR_SLOTS[String(data["slot"])]["name"])
			col = ProgressionManager.RARITY_COLOR.get(String(data["rarity"]), Color.WHITE)
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.16, 0.28)
	node.mesh = mesh
	node.material_override = _mat(col)
	node.position = pos + Vector3(0.0, 0.08, 0.0)
	add_child(node)
	var label: Label3D = _label(pos + Vector3(0.0, 0.75, 0.0), text, col, LBL_BEUTE, 60.0)
	_ground.append({ "node": node, "label": label, "kind": kind, "data": data, "pos": pos })


func _clear_drop(d: Dictionary) -> void:
	(d["node"] as Node3D).queue_free()
	(d["label"] as Label3D).queue_free()
	_ground.erase(d)


## Naechstes AUSRUESTUNGS-Stueck in Handreichweite ({} = keins).
func _gear_in_range() -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = PICKUP_HAND_M
	for d in _ground:
		if String(d["kind"]) != "gear":
			continue
		var dist: float = _player.position.distance_to(d["pos"])
		if dist < best_d:
			best_d = dist
			best = d
	return best


## Bodenbeute je Frame: Gold, Munition, Traenke und Material saugt der Spieler beim
## Darueberlaufen auf; Ausruestung bleibt liegen und bekommt am naechsten Stueck einen
## Schimmer, damit klar ist, welches der Handgriff erwischt.
func _process_ground(delta: float) -> void:
	_shimmer = fmod(_shimmer + delta * 3.2, TAU)
	# Magnet-Spule vergroessert den Aufsammelradius (Prototyp-Einheiten -> Meter).
	var auto_r: float = PICKUP_AUTO_BASE_M * (float(PlayerStats.magnet_dist()) / float(PlayerStats.BASE_MAGNET))
	var near: Dictionary = _gear_in_range()
	for d in _ground.duplicate():
		var dist: float = _player.position.distance_to(d["pos"])
		var kind: String = String(d["kind"])
		if kind == "gear":
			var lbl: Label3D = d["label"]
			if d == near:
				# Schimmer: pulsierender Umriss um die Beschriftung. Billiger als ein Leuchten
				# und aus Kamerahoehe deutlich besser zu sehen.
				lbl.outline_size = 12
				lbl.outline_modulate = Color(1.0, 1.0, 1.0, 0.35 + 0.45 * (0.5 + 0.5 * sin(_shimmer)))
				lbl.text = "%s\n%s" % [String(ProgressionManager.GEAR_SLOTS[String(d["data"]["slot"])]["name"]),
					String(d["data"]["name"])]
			else:
				lbl.outline_size = 0
				lbl.text = String(ProgressionManager.GEAR_SLOTS[String(d["data"]["slot"])]["name"])
			continue
		if dist > auto_r:
			continue
		match kind:
			"gold":
				GameState.add_gold(int(d["data"]["amount"]))
			"ammo":
				AmmoData.add(String(d["data"]["pool"]), int(d["data"]["amount"]))
			"potion":
				GameState.add_potion(int(d["data"]["amount"]))
			"material":
				GameState.add_item(String(d["data"]["id"]), int(d["data"]["amount"]))
		_clear_drop(d)


## Ausruestung aufheben — der einzige Handgriff, der eine Entscheidung ist.
func _pick_up_gear() -> void:
	var d: Dictionary = _gear_in_range()
	if d.is_empty():
		return
	var gear: Dictionary = d["data"]
	if not BagManager.add(gear):
		_say("▤ Der Beutel ist voll.", 2.5)
		return
	var rarity_name: String = String(ProgressionManager.RARITY[String(gear["rarity"])]["name"])
	_say("✦ %s %s eingesteckt" % [rarity_name, String(gear["name"])], 2.5)
	_clear_drop(d)


## Kleiner Aufblitz-Effekt beim Anlegen, damit ein Ausrüstungswechsel spürbar ist.
func sfx_equip() -> void:
	if _player == null:
		return
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.9, 0.5)
	flash.omni_range = 4.0
	flash.light_energy = 2.0
	_player.add_child(flash)
	get_tree().create_timer(0.25).timeout.connect(flash.queue_free)


# ── Eingabe: virtueller Joystick (Touch) + Schuss-Knopf + Tastatur ────────────

func _input(event: InputEvent) -> void:
	# Eine Sequenz, die man aussitzen MUSS, ist beim zweiten Mal eine Zumutung. Jeder Tipp und
	# jede Taste bricht ab — und wird dabei verbraucht, damit derselbe Tipp nicht gleich noch
	# den Joystick startet.
	var druck: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	# Der Vorspann geht VOR allem anderen — auch vor der Sprechtafel, denn waehrend er laeuft
	# steht dort nichts. Wer den Film schon kennt, tippt ihn weg.
	if druck and _im_vorspann():
		_vorspann_ueberspringen()
		get_viewport().set_input_as_handled()
		return
	# Solange Text auf der Tafel steht, BLAETTERT ein Tipp — er bricht nicht die Fahrt ab.
	# Andersherum waere der erste Tipp im Spiel gleichzeitig das Ueberspringen des Anfangs.
	if druck and _dialog != null and _dialog.visible:
		_naechste_zeile()
		get_viewport().set_input_as_handled()
		return
	if (_in_cine() or _in_flight()) and druck:
		if _in_flight():
			_end_flight()
		else:
			_end_cine()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_pos[event.index] = event.position
		else:
			_touch_pos.erase(event.index)
			if event.index == _pinch_a or event.index == _pinch_b:
				_pinch_a = -1
				_pinch_b = -1
		if event.pressed:
			# Reihenfolge ist hier alles: Karte, dann Schuss-Knopf, dann erst der Joystick.
			# Der Joystick beansprucht sonst jeden Finger, der irgendwo aufsetzt.
			if _handle_overlay_tap(event.position):
				return
			# Trabanten VOR dem Schussknopf: Ihre Trefferflaechen beruehren sich nicht, aber der
			# Schussknopf hat den groesseren Zuschlag (`TOUCH_SLACK`), und ohne diese
			# Reihenfolge schluckte er die Raender der Trabanten.
			if _trabant_tap(event.position):
				get_viewport().set_input_as_handled()
				return
			if _fire_touch_id == -1 and _fire_btn != null and _fire_btn.hits(event.position):
				_fire_touch_id = event.index
				get_viewport().set_input_as_handled()
				return
			# Kneifen zum Zoomen. Der Joystick beansprucht den ERSTEN freien Finger — ein
			# zweiter waere danach nie eine Geste. Deshalb die Umdeutung: Kommt ein zweiter
			# Finger, waehrend der erste noch in der Totzone liegt (man hat also noch nicht
			# gelenkt), war es von Anfang an ein Kneifen. Wer schon steuert, behaelt den Stick.
			if _touch_id != -1 and _touch_id != MOUSE_STICK_ID and _pinch_a == -1 \
					and _touch_vec == Vector2.ZERO:
				_pinch_a = _touch_id
				_pinch_b = event.index
				_pinch_ref = _touch_start.distance_to(event.position)
				_pinch_zoom0 = _zoom_step()
				_end_stick()
				return
			if _touch_id == -1:
				_begin_stick(event.position, event.index)
		else:
			# Beide Finger einzeln freigeben — der Daumen auf dem Knopf geht hoch, ohne dass
			# der auf dem Joystick etwas davon merkt.
			if event.index == _fire_touch_id:
				_fire_touch_id = -1
			if event.index == _touch_id:
				_end_stick()
	elif event is InputEventScreenDrag:
		_touch_pos[event.index] = event.position
		if _pinch_a != -1 and _touch_pos.has(_pinch_a) and _touch_pos.has(_pinch_b):
			var spread: float = Vector2(_touch_pos[_pinch_a]).distance_to(Vector2(_touch_pos[_pinch_b]))
			# Auseinanderziehen holt heran (kleinere Stufe), zusammenziehen zoomt heraus.
			_set_zoom(_pinch_zoom0 - int((spread - _pinch_ref) / PINCH_PX_PER_STEP))
		elif event.index == _touch_id:
			_drag_stick(event.position)
	# Maus verhält sich exakt wie ein Finger — derselbe Joystick, damit man am Rechner das
	# testet, was auf dem Handy auch passiert (statt einer zweiten, abweichenden Steuerung).
	#
	# `is_emulating_touch_from_mouse()` ist kein Zierrat: Steht Godots Maus-Emulation an,
	# erzeugt EIN Klick zwei Ereignisse — erst einen Finger-Tipp, dann den Mausknopf. Beide
	# liefen hier durch, und weil `_handle_overlay_tap` ein Umschalter ist, ging die Weltkarte
	# im ersten auf und im zweiten sofort wieder zu: Sie liess sich nicht oeffnen. Die
	# Projekteinstellung ist inzwischen aus, aber die Abfrage bleibt — sonst holt das jemand
	# zurueck, ohne den Zusammenhang zu kennen.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not Input.is_emulating_touch_from_mouse():
		if event.pressed and _touch_id == -1:
			if _handle_overlay_tap(event.position):
				return
			# Auch mit der Maus muss der Knopf anklickbar sein: Was auf dem Handy geht, muss
			# am Rechner nachstellbar sein, sonst testet man eine andere Steuerung.
			if _trabant_tap(event.position):
				get_viewport().set_input_as_handled()
				return
			if _fire_btn != null and _fire_btn.hits(event.position):
				_fire_mouse = true
				get_viewport().set_input_as_handled()
				return
			_begin_stick(event.position, MOUSE_STICK_ID)
		elif not event.pressed:
			_fire_mouse = false
			if _touch_id == MOUSE_STICK_ID:
				_end_stick()
	# Rechte Maustaste feuert direkt — links ist mit dem Joystick belegt.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_fire_mouse = event.pressed
	# Mausrad zoomt. Hoch = naeher heran, also eine Stufe KLEINER.
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_by(-1)
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_by(1)
	elif event is InputEventMouseMotion and _touch_id == MOUSE_STICK_ID \
			and not Input.is_emulating_touch_from_mouse():
		_drag_stick(event.position)
	# Leertaste: Halten feuert. Sie braucht auch das LOSLASSEN, deshalb steht sie vor dem
	# `pressed`-Filter der uebrigen Tasten.
	elif event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		_fire_key = event.pressed
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _overlay_open():
			_close_character()
			_close_shop()
			_close_world_map()
		elif event.keycode == KEY_R:
			_begin_reload()
		elif event.keycode == KEY_F:
			_trank_trinken()
		elif event.keycode == KEY_C:
			_toggle_character()
		elif event.keycode == KEY_PLUS or event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_zoom_by(-1)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_zoom_by(1)
		elif event.keycode == KEY_M:
			if _map_is_open():
				_close_world_map()
			else:
				_open_world_map()
		elif event.keycode == KEY_Q:
			_cycle_tracked_quest()
		elif _overlay_open():
			pass   # bei offenem Overlay schluckt es die restlichen Tasten
		elif event.keycode == KEY_TAB:
			# Frueher der Waffen-Umschalter. Waffen wechselt man jetzt dort, wo man sie auch
			# vergleicht: an der Puppe.
			_toggle_character(CharacterScreen.Tab.AUSRUESTUNG)
		elif event.keycode == KEY_E:
			# Dieselbe Rangfolge wie in der Aktionsleiste, damit Taste und Knopf nie etwas
			# Verschiedenes tun.
			var chest: Dictionary = _chest_in_range()
			var gear: Dictionary = _gear_in_range()
			var npc: Dictionary = _npc_in_range()
			if not chest.is_empty():
				_open_chest(chest)
			elif not gear.is_empty():
				_pick_up_gear()
			elif not npc.is_empty():
				_talk_to(String(npc["giver"]))
			elif _pferd_greifbar():
				_toggle_mount()
		elif event.keycode == KEY_F9:
			_prolog_neu_anfordern()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			_fast_travel(event.keycode - KEY_1)


## Tipp auf eines der Overlays. Liefert `true`, wenn der Joystick ihn NICHT bekommen darf.
##
## Warum das hier steht und nicht als `_gui_input` in den Controls selbst: `_input` läuft VOR
## der GUI-Verarbeitung. Ein Tipp auf die Minikarte würde also erst den Joystick starten und
## danach die Karte öffnen — die Figur liefe los, während man nur nachsehen wollte.
##
## Der Laden ist der Sonderfall, an dem sich die Regel bricht: Er hat ECHTE Knöpfe, die die GUI
## verarbeiten muss. Ein Tipp DARAUF wird deshalb zwar vom Joystick ferngehalten, aber NICHT
## mit `set_input_as_handled()` verbraucht — sonst käme kein Kauf jemals an. Nur ein Tipp
## DANEBEN schließt den Laden und wird verbraucht.
func _handle_overlay_tap(at: Vector2) -> bool:
	if _char != null and _char.visible:
		# Puppe und Beutel-Raster sind GEZEICHNET, keine Knoepfe — sie bekommen ihren Tipp
		# deshalb nicht von der GUI, sondern hier von Hand. Muss VOR `hits_panel` stehen, sonst
		# wird der Tipp als „irgendwo auf der Tafel" abgetan und die Auswahl aendert sich nie.
		if _char.tap_panel(at):
			get_viewport().set_input_as_handled()
			return true
		if _char.hits_panel(at):
			return true   # Knopf auf der Tafel: durchreichen, aber nicht als Joystick werten
		_close_character()
		get_viewport().set_input_as_handled()
		return true
	if _shop != null and _shop.visible:
		if _shop.hits_panel(at):
			return true   # Knopf im Laden: durchreichen, aber nicht als Joystick werten
		_close_shop()
		get_viewport().set_input_as_handled()
		return true
	if _map_is_open():
		_close_world_map()
		get_viewport().set_input_as_handled()
		return true
	if _minimap != null and _minimap.get_global_rect().has_point(at):
		_open_world_map()
		get_viewport().set_input_as_handled()
		return true
	# Echte Knoepfe im HUD: vom Joystick fernhalten, aber an die GUI durchreichen.
	for b in _hud_buttons:
		var btn: Button = b
		if btn.visible and btn.is_visible_in_tree() and btn.get_global_rect().has_point(at):
			return true
	return false


## Der Joystick erscheint dort, wo man aufsetzt (dynamischer Stick, GDD §1.5) — er hat keine
## feste Ecke, weil man auf dem Handy nicht hinschaut, bevor man den Daumen aufsetzt.
func _begin_stick(at: Vector2, id: int) -> void:
	_touch_id = id
	_touch_start = at
	_touch_vec = Vector2.ZERO
	if _stick != null:
		_stick.origin = at
		_stick.knob = at
		_stick.active = true
		_stick.queue_redraw()


func _drag_stick(at: Vector2) -> void:
	var v: Vector2 = at - _touch_start
	# Unter der Totzone passiert nichts (Zittern), darüber wächst es linear bis STICK_RADIUS.
	_touch_vec = Vector2.ZERO if v.length() < STICK_DEADZONE else (v / STICK_RADIUS).limit_length(1.0)
	if _stick != null:
		_stick.knob = _touch_start + v.limit_length(STICK_RADIUS)
		_stick.queue_redraw()


func _end_stick() -> void:
	_touch_id = -1
	_touch_vec = Vector2.ZERO
	if _stick != null:
		_stick.active = false
		_stick.queue_redraw()


## Bahnhof, an dem der Spieler gerade steht ("" = keiner in Reichweite).
func _station_at_player() -> String:
	for s in _stations:
		if _player.position.distance_to(s["pos"]) <= STATION_RANGE_M:
			return String(s["id"])
	return ""


## Iron-Rail-Reise (GDD §1.4a): von Bahnsteig zu Bahnsteig. Die Wüste dazwischen kann man
## immer zu Fuß durchqueren — die Bahn ersetzt nur den langen Marsch, und zwar erst, wenn
## man tatsächlich an einem Bahnhof steht. Gesperrte Sektoren bleiben gesperrt (WorldManager).
func _fast_travel(idx: int) -> void:
	if idx < 0 or idx >= FAST_TRAVEL.size():
		return
	var here: String = _station_at_player()
	if here == "":
		_say("⇄ Nur am Bahnhof. Die Iron Rail hält nicht mitten in der Wüste.", 2.5)
		return
	var poi_id: String = String(FAST_TRAVEL[idx])
	var p: Dictionary = WorldManager.POIS[poi_id]
	if poi_id == here:
		_say("⇄ Du stehst schon in %s." % String(p["name"]), 2.0)
		return
	var sec: int = int(p["sector"])
	if not WorldManager.can_enter_sector(sec):
		_say("✖ %s liegt hinter einem verschlossenen Tor (Sektor %d)." % [String(p["name"]), sec], 2.5)
		return
	_player.position = WorldManager.poi_scene_position(poi_id) + Vector3(0.0, 0.0, 25.0)
	_say("⇄ Iron Rail: %s → %s" % [String(WorldManager.poi(here)["name"]), String(p["name"])], 2.5)


## Womit wird geschossen? **Was im Waffen-Slot liegt** ("" = leere Haende).
##
## Vorher schaltete `[Tab]` durch eine feste Liste von fuenf Gattungen — eine zweite Wahrheit
## neben dem Inventar, in dem man Ausruestung ohnehin anlegt. Jetzt gibt es nur noch eine:
## Was an der Puppe haengt, wird gefuehrt. Der Umschalter ist damit ueberfluessig, und
## `[Tab]` macht das, was man in dem Moment will — es oeffnet das Inventar.
##
## Die GATTUNG steht am Gegenstand (`kind`), nicht in seinem Namen: „Rostiger Karabiner" und
## „Praezisions-Karabiner" schiessen beide als `karabiner`, treffen aber verschieden hart.
func _weapon_kind() -> String:
	var w: Variant = GameState.equip.get("weapon", null)
	if not (w is Dictionary):
		return ""
	var k: String = String((w as Dictionary).get("kind", ""))
	return k if CombatData.WEAPONS.has(k) else ""


## Gefuehrte Waffe nachziehen, wenn im Inventar etwas angelegt oder abgelegt wurde.
func _sync_weapon() -> void:
	var k: String = _weapon_kind()
	if k == _weapon_id:
		return
	_weapon_id = k
	GameState.weapon_id = k
	if k != "" and GameState.add_weapon(k):
		pass    # erste Waffe dieser Gattung — fuer Codex und Statistik vermerkt
	_refresh_weapon(false)


## Modell, Nachladen und Meldung an die gefuehrte Waffe anpassen.
func _refresh_weapon(gefunden: bool) -> void:
	# Der Wechsel bricht ein laufendes Nachladen ab. Sonst waere Umschalten ein kostenloser
	# Weg, die Wartezeit zu ueberspringen — jede Waffe haelt ihr eigenes Magazin.
	_reload_left = 0.0
	# Bisher gibt es nur ein Waffenmodell. Statt den Karabiner in der Hand zu lassen, während
	# der Säure-Sprüher feuert, verschwindet er — lieber leere Hand als falsche Waffe.
	if _weapon_model != null:
		_weapon_model.visible = _weapon_id != "" \
			and AssetRegistry.has_model("weapon_" + _weapon_id)
	if _weapon_id == "":
		return
	var dt: String = String(CombatData.WEAPONS[_weapon_id]["type"])
	var name: String = String(CombatData.WEAPONS[_weapon_id]["name"])
	if gefunden:
		_say("%s %s gefunden!" % [HudGlyph.z(_weapon_id), name], 3.0)
	else:
		_say("%s %s (%s)" % [HudGlyph.z(_weapon_id), name, dt], 2.0)


func _move_vector() -> Vector2:
	# Bei offenem Overlay steht die Figur. Sie ist verdeckt, also wäre jede Bewegung blind —
	# und man würde beim Kartenlesen oder Einkaufen ungewollt in eine Gegnergruppe laufen.
	if _overlay_open():
		return Vector2.ZERO
	var kb: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return kb if kb.length() > 0.05 else _touch_vec


# ── Spielschleife ─────────────────────────────────────────────────────────────

## Kamera folgt der Position des Spielers, NIE seiner Drehung (Diablo-Prinzip: die Welt behält
## ihre Orientierung, nur die Figur dreht sich). Weich nachgezogen, damit Richtungswechsel nicht
## ruckeln.
# ── Nahaufnahme: die Kamera als Erzaehler ─────────────────────────────────────
## Die Figuren sind Meshy-Modelle mit 1k-Textur — aus 12 m Iso-Entfernung sieht man davon
## nichts. Eine Quest anzunehmen ist der erste Moment im Spiel, in dem etwas ERZAEHLT wird;
## dafuer lohnt es sich, einmal heranzugehen.
##
## Bewusst klein gehalten: kein Sequenz-Editor, keine Kamerafahrten-Datei, kein Zustandsautomat.
## Eine Zielperson, eine Dauer, ein sanfter Zoom nach innen — das ist alles, was eine
## Nahaufnahme braucht, und alles Weitere waere Maschinerie fuer eine Sache, die es noch nicht
## gibt. Wer sie ausbauen will, verlaengert `_cine_frame()`.
##
## Zwei Dinge, die eine Nahaufnahme von einem Kamerafehler unterscheiden:
##  • **Man kann nichts tun.** Waehrend der Aufnahme sind Laufen und Schiessen gesperrt; sonst
##    rennt die Figur aus dem Bild, waehrend die Kamera ihr Gegenueber anschaut.
##  • **Man kommt raus.** Jeder Tipp und jede Taste bricht ab. Eine Sequenz, die man aussitzen
##    MUSS, ist beim zweiten Mal eine Zumutung.
const CINE_FOV: float = 34.0        # eng wie ein Portraitobjektiv, nicht wie das Spiel (50°)
const CINE_DIST_FROM: float = 3.6   # Abstand am Anfang …
const CINE_DIST_TO: float = 2.4     # … und am Ende: eine langsame Fahrt nach innen
## Wie lange die Fahrt nach innen dauert. Absichtlich UNABHAENGIG von der Dauer der Aufnahme:
## Sonst faehrt eine kurze Einstellung hektisch und eine lange in Zeitlupe, obwohl beide
## dieselbe Bewegung zeigen sollen.
const CINE_DOLLY_SEC: float = 2.0
const CINE_EYE_M: float = 1.62      # Augenhoehe der Figuren
const CINE_RATE: float = 6.0        # wie schnell die Kamera einschwenkt
const CINE_SIDE: float = 0.55       # seitlich versetzt — frontal wirkt wie ein Passfoto
var _cine: Node3D = null            # wen wir gerade ansehen (null = normale Kamera)
var _cine_left: float = 0.0
var _cine_total: float = 0.0
var _bars: Array = []               # die schwarzen Balken (oben; unten sitzt die Sprechtafel)
var _dialog: DialogBox              # die Sprechtafel
## Wen wir beim Gespraech zueinander drehen, und wie sie vorher standen.
var _face_a: Node3D = null
var _face_b: Node3D = null
var _face_back: float = 0.0         # urspruengliche Drehung von `_face_b`, zum Zuruecksetzen


## Nahaufnahme starten. `wer` ist die Zielperson, `secs` die Dauer.
func _play_closeup(wer: Node3D, secs: float) -> void:
	if wer == null or _cam == null:
		return
	_cine = wer
	_cine_total = maxf(secs, 0.3)
	_cine_left = _cine_total
	# Zueinander drehen. Ein Gespraech, bei dem beide geradeaus schauen, sieht aus wie zwei
	# Leute, die zufaellig nebeneinanderstehen — und in der Nahaufnahme faellt das sofort auf.
	_face_a = _player
	_face_b = wer
	_face_back = wer.rotation.y
	_set_hud_hidden(true)
	_set_cine_clean(true)
	_show_bars(true)
	_end_stick()


func _end_cine() -> void:
	if _cine == null:
		return
	_cine = null
	_cine_left = 0.0
	_face_a = null
	if _face_b != null and is_instance_valid(_face_b):
		# Die Zielperson dreht sich zurueck. Ohne das steht Mabel danach dauerhaft schraeg und
		# schaut einem hinterher, was auf Dauer unheimlicher ist als beabsichtigt.
		_face_b.rotation.y = _face_back
	_face_b = null
	if _dialog != null and _dialog.visible:
		_dialog.visible = false
	_show_bars(false)
	_set_cine_clean(false)
	_set_hud_hidden(false)


func _in_cine() -> bool:
	return _cine != null and is_instance_valid(_cine)


## Die schwarzen Balken. Sie tragen keine Information und sind trotzdem das Wichtigste an der
## Sache: Sie sagen „das hier ist erzaehlt, nicht gespielt", bevor die Kamera sich bewegt.
func _show_bars(an: bool) -> void:
	if _bars.is_empty():
		if not an or _hud_layer == null:
			return
		# Nur OBEN ein Balken. Unten sitzt die Sprechtafel, und die ist selbst dunkel gerahmt —
		# ein zweiter Balken darunter waere ein schwarzer Streifen unter einem schwarzen Rahmen.
		var r := ColorRect.new()
		r.color = Color(0.0, 0.0, 0.0, 0.92)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		r.offset_bottom = 78.0
		_hud_layer.add_child(r)
		_bars.append(r)
	for b in _bars:
		(b as ColorRect).visible = an
	# Die Meldungszeile sitzt bei 64 px, der Balken reicht bis 78 — waehrend einer Fahrt
	# verschwindet sie also zur Haelfte darunter. Genau die Zeile, die den Anflug betextet,
	# war so nicht zu lesen. Sie rutscht deshalb tiefer, solange der Balken steht.
	if _toast != null:
		_toast.offset_top = TOAST_TOP_CINE if an else TOAST_TOP


## Alles wegnehmen, was in einer Nahaufnahme nicht vorkommt.
##
## `_set_hud_hidden` allein reicht nicht: Es kuemmert sich um die Bedienelemente, nicht um
## Kopfzeile und Karte — und schon gar nicht um die schwebenden Weltbeschriftungen. Die sind in
## der Nahaufnahme das Schlimmste: Ein Ortsname ist auf 120 Punkt ausgelegt und aus zwei Metern
## Entfernung ein Buchstabengebirge quer durchs Bild. Die Sprechblase bleibt — sie IST die Szene.
func _set_cine_clean(an: bool) -> void:
	if _hud != null:
		_hud.visible = not an
	if _minimap != null:
		_minimap.visible = not an
	# Die KOPFZEILE gehoert dazu — und stand bis hierher weiter da. `_hud` ist nur die
	# Textzeile; Portraet, Rahmen, Lebens- und Erfahrungsbalken und die Zustandsmarken sind
	# eigene Knoten und wurden von niemandem angefasst. Sichtbar wurde das erst auf einem Bild
	# der Erstbegegnung: Sie lagen hinter dem schwarzen Balken, der sie zu 92 % abdunkelt, und
	# das ergibt genau das schlechteste Ergebnis — eine Bedienoberflaeche, die man gerade noch
	# erkennt, in einem Augenblick, aus dem sie verschwinden sollte.
	for c in [_portrait_btn, _portrait_rahmen, _hp_bar, _xp_bar, _spieler_marken]:
		if c != null and is_instance_valid(c):
			(c as CanvasItem).visible = not an
	# Und die Lebensleisten ueber den Gegnern. In der Erstbegegnung ist das keine Kosmetik: Die
	# Szene lebt davon, dass man nicht weiss, was da aus dem Blech kommt — ein gruener Balken
	# darueber beantwortet die Frage, bevor sie gestellt ist.
	for e in _enemies:
		var b: Variant = e.get("bar")
		if b == null or not is_instance_valid(b):
			continue
		var traeger: Node = (b as Node).get_parent()
		if traeger is Node3D:
			(traeger as Node3D).visible = not an
	for c in get_children():
		if c is Label3D:
			(c as Label3D).visible = not an


## Der Punkt, auf den die Nahaufnahme zielt — knapp unter dem Scheitel.
##
## GEMESSEN am Modell, nicht geraten. Der erste Versuch nahm „Knotenposition plus 1,62 m
## Augenhoehe". Das stimmt nie ganz: Meshy legt den Ursprung eines Modells irgendwohin, und
## im Bild stand die Figur dann unten rechts, waehrend die Kamera auf leeren Sand zielte.
## Ueber die Netzgrenzen ist der Kopf da, wo der Kopf ist — bei jedem Modell, ohne Zahlen.
func _cine_head() -> Vector3:
	return _head_of(_cine)


## Derselbe Kopfpunkt fuer eine beliebige Figur.
func _head_of(wer: Node3D) -> Vector3:
	if wer == null:
		return Vector3.ZERO
	for c in wer.get_children():
		if not (c is Node3D):
			continue
		var b: AABB = AssetRegistry.local_bounds(c as Node3D)
		if b.size.y < 0.2:
			continue
		var m: Transform3D = (c as Node3D).global_transform
		var scheitel: Vector3 = m * (b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5))
		# Waagerecht die KNOTENPOSITION, senkrecht das gemessene Modell.
		#
		# Nur die Hoehe wird gemessen, nicht die Mitte: Der Huellquader eines animierten Modells
		# umfasst die Ruhepose mit ausgestreckten Armen, sein waagerechter Mittelpunkt liegt
		# deshalb um bis zu einem halben Meter neben der Figur — im Bild stand sie dann am Rand,
		# waehrend die Kamera auf leeren Sand zielte. Der Knoten dagegen steht per Definition da,
		# wo die Figur steht.
		return Vector3(wer.global_position.x, scheitel.y - 0.16, wer.global_position.z)
	return wer.global_position + Vector3(0.0, CINE_EYE_M, 0.0)


## Wo steht die Kamera in diesem Augenblick der Aufnahme?
##
## Aus der BLICKRICHTUNG der Zielperson, leicht seitlich versetzt. Der erste Versuch nahm die
## Richtung des Spielers — und zeigte Mabels Hinterkopf: Die NPCs schauen zur Strassenmitte,
## der Spieler steht daneben. Eine Nahaufnahme, die das Gesicht nicht zeigt, ist keine.
## Genau frontal waere allerdings ein Passfoto, deshalb der Versatz.
## Ein GESPRAECH ist eine Zweier-Einstellung, kein Portrait.
##
## Vorher zielte die Kamera auf das Gesicht des Gegenuebers und stand vor ihm. Wo der Spieler
## dabei stand, war Zufall — und stand er zwischen Kamera und NPC, verdeckte er genau den, mit
## dem man spricht. Das haengt an der Laufrichtung, mit der man ankommt, und das ist nichts,
## worauf eine Einstellung sich verlassen darf.
##
## Jetzt steht die Kamera **quer zur Verbindungslinie** der beiden. Damit stehen sie im Bild
## nebeneinander statt hintereinander: Wer wen verdeckt, ist keine Frage mehr. Der Abstand
## folgt aus ihrem Abstand zueinander — beide sind immer drin, egal wie weit man stehen bleibt.
##
## Die Seite ist die, auf der die Kamera ohnehin schon steht. Ein Gespraech, das mit einem
## Sprung ueber die Achse beginnt, liest sich als Schnittfehler.
const CINE_TWO_MARGIN: float = 1.5   # Zuschlag zum halben Abstand, damit nichts am Rand klebt
const CINE_TWO_MIN_M: float = 2.6
const CINE_TWO_MAX_M: float = 6.0
func _cine_frame() -> Array:
	var kopf: Vector3 = _cine_head()
	var spieler: Vector3 = _head_of(_player)
	var achse := Vector3(spieler.x - kopf.x, 0.0, spieler.z - kopf.z)
	var abstand: float = achse.length()
	if abstand < 0.3:
		# Zu dicht aufeinander fuer eine Achse — dann wie frueher aus der Blickrichtung.
		achse = -_cine.global_transform.basis.z
		achse.y = 0.0
		abstand = 1.0
	if achse.length() < 0.2:
		achse = Vector3(0.0, 0.0, 1.0)
	achse = achse.normalized()
	var quer := Vector3(-achse.z, 0.0, achse.x)
	var mitte: Vector3 = (kopf + spieler) * 0.5
	if _cam != null and quer.dot(_cam.global_position - mitte) < 0.0:
		quer = -quer
	# Fortschritt 0 → 1 ueber `CINE_DOLLY_SEC`; die Kamera faehrt langsam heran.
	var t: float = clampf((_cine_total - _cine_left) / CINE_DOLLY_SEC, 0.0, 1.0)
	var noetig: float = clampf(abstand * 0.5 + CINE_TWO_MARGIN, CINE_TWO_MIN_M, CINE_TWO_MAX_M)
	var dist: float = lerpf(noetig + 1.1, noetig, smoothstep(0.0, 1.0, t))
	var pos: Vector3 = mitte + quer * dist + Vector3(0.0, 0.30, 0.0)
	return [pos, mitte]


## Spieler und Gegenueber drehen sich zueinander.
##
## Weich, nicht gesprungen: Ein harter Schnitt auf die neue Blickrichtung sieht aus, als haette
## jemand die Figur umgestellt. Ueber gut eine Viertelsekunde gedreht liest es sich als
## Zuwendung — und genau die ist der Grund, warum ueberhaupt gedreht wird.
##
## `lerp_angle` und nicht `lerpf`: Zwischen 170° und −170° liegen zwanzig Grad, nicht 340. Ohne
## das dreht sich die Figur einmal ganz herum, wenn das Gespraech ueber die Vorzeichengrenze
## geht — und das passiert genau bei jedem zweiten NPC.
const FACE_RATE: float = 7.0
func _process_facing(delta: float) -> void:
	if _face_a == null or _face_b == null:
		return
	if not is_instance_valid(_face_a) or not is_instance_valid(_face_b):
		return
	var k: float = clampf(delta * FACE_RATE, 0.0, 1.0)
	_face_a.rotation.y = lerp_angle(_face_a.rotation.y,
		_yaw_towards(_face_a.position, _face_b.position), k)
	_face_b.rotation.y = lerp_angle(_face_b.rotation.y,
		_yaw_towards(_face_b.position, _face_a.position), k)


## Blickrichtung von `von` nach `nach` als Node3D-Drehung um die Hochachse.
##
## Dieselbe Rechnung, mit der die Figur beim Laufen zum Laufvektor schaut
## (`rotation.y = atan2(-step.x, -step.z)`) — bewusst hier zentral, damit Laufen und Zuwenden
## nicht zwei verschiedene Vorstellungen von „vorn" haben.
static func _yaw_towards(von: Vector3, nach: Vector3) -> float:
	var d := Vector3(nach.x - von.x, 0.0, nach.z - von.z)
	if d.length() < 0.01:
		return 0.0
	return atan2(-d.x, -d.z)


# ── Kameraflug ───────────────────────────────────────────────────────────────
## Eine gefahrene Einstellung: eine Liste von Standpunkten mit Blickzielen und Dauern.
##
## Anders als die Nahaufnahme, die IMMER dasselbe tut (Kopf suchen, heranfahren), ist ein Flug
## ein Drehbuch. Deshalb kommt er als Daten herein und nicht als Formel — wer eine zweite Fahrt
## will, schreibt eine zweite Liste, keinen zweiten Sonderfall.
##
## Zwischen zwei Punkten wird mit `smoothstep` geblendet: Ein linearer Schnitt zwischen zwei
## Standpunkten faehrt an, faehrt und bremst nicht, und das liest sich als Kamerafahrt eines
## Anfaengers. Weich hinein, weich hinaus, und die Uebergaenge zwischen den Abschnitten
## verschwinden.
var _flight: Array = []          # [{ pos, ziel, sek }]
var _flight_t: float = 0.0
var _flight_von := Transform3D.IDENTITY


func _play_flight(punkte: Array) -> void:
	if _cam == null or punkte.is_empty():
		return
	_flight = punkte
	_flight_t = 0.0
	_flight_von = _cam.global_transform
	_set_hud_hidden(true)
	_set_cine_clean(true)
	_show_bars(true)
	_end_stick()


func _in_flight() -> bool:
	return not _flight.is_empty()


func _end_flight() -> void:
	_flight.clear()
	_set_hud_hidden(false)
	_set_cine_clean(false)
	_show_bars(false)


## Kamera fuer den aktuellen Augenblick des Fluges.
## Ein Wegpunkt, aufgeloest: Standpunkt und Blickziel in Weltkoordinaten.
##
## Ein Wegpunkt mit `"kopf": true` ist RELATIV zum Kopf der Figur — `pos` ist dann ein Versatz,
## und geblickt wird auf den Kopf selbst. Gebraucht fuer das Erwachen: Der Kopf wandert dabei
## ueber anderthalb Meter durch den Raum (er liegt, dann kniet er, dann steht er), und feste
## Zielpunkte zielen zwangslaeufig daneben — beim ersten Versuch punktgenau auf seine Stiefel.
func _flight_punkt(p: Dictionary) -> Array:
	if not bool(p.get("kopf", false)):
		return [p["pos"], p["ziel"], float(p.get("fov", CAM_FOV))]
	var kopf: Vector3 = _kopf_welt()
	if kopf.x >= INF:
		kopf = (_player.position + Vector3(0.0, 1.0, 0.0)) if _player != null else Vector3.ZERO
	# Der Versatz steht in SEINEM Bezugssystem, nicht in Weltachsen: −Z ist vorn, +X rechts.
	# Sonst haengt es vom Zufall der Figurendrehung ab, ob man ihr ins Gesicht oder auf den
	# Ruecken sieht — und beim ersten Versuch war es der Ruecken.
	var yaw: float = _player.rotation.y if _player != null else 0.0
	return [kopf + Basis(Vector3.UP, yaw) * Vector3(p["pos"]), kopf, float(p.get("fov", CAM_FOV))]


func _flight_frame() -> Array:
	var t: float = _flight_t
	var von_pos: Vector3 = _flight_von.origin
	var von_ziel: Vector3 = von_pos - _flight_von.basis.z * 10.0
	var von_fov: float = CAM_FOV
	for p in _flight:
		var sek: float = maxf(float(p["sek"]), 0.05)
		var aufgeloest: Array = _flight_punkt(p)
		if t <= sek:
			var roh: float = t / sek
			# `weich` (Vorgabe) faehrt den Abschnitt sanft an und wieder aus. Das ist richtig
			# fuer einen einzelnen Standortwechsel und FALSCH fuer eine Kette von Stuetzpunkten,
			# die zusammen EINE Bewegung ergeben: Zwoelf Bogenstuecke, die jedes fuer sich
			# anfahren und abbremsen, sind kein Kreis, sondern ein Stottern. Solche Ketten
			# setzen `weich` auf false und tragen ihre Beschleunigung in der Verteilung der
			# Stuetzpunkte (siehe `orbit_punkte`).
			var k: float = smoothstep(0.0, 1.0, roh) if bool(p.get("weich", true)) else roh
			return [von_pos.lerp(aufgeloest[0], k), von_ziel.lerp(aufgeloest[1], k),
				lerpf(von_fov, float(aufgeloest[2]), k)]
		t -= sek
		von_pos = aufgeloest[0]
		von_ziel = aufgeloest[1]
		von_fov = float(aufgeloest[2])
	return [von_pos, von_ziel, von_fov]


## Stuetzpunkte fuer eine Umrundung — eine echte Kurve, keine Gerade daran vorbei.
##
## `_flight_frame` interpoliert LINEAR zwischen zwei Standpunkten. Zwei Punkte auf einem Kreis
## ergeben damit die Sehne, nicht den Bogen: Die Kamera zieht an dem Ding vorbei, um das sie
## kreisen soll, und kommt ihm dabei in der Mitte naeher. Bei den urspruenglichen zwei Punkten
## um den Wasserturm waren das 26 m an den Enden und 21,6 m in der Mitte — sichtbar keine
## Umrundung.
##
## Also wird der Bogen in `stufen` Sehnen zerlegt. Bei sechzehn Stufen ueber 220° bleibt der
## groesste Abstandsfehler bei 0,43 m auf 27 m — 1,6 %, und das an der Stelle, an der die
## Kamera am schnellsten ist. Das sieht kein Mensch. (Zwoelf waeren 2,8 %, zwanzig 1,0 % — die
## Stuetzpunkte kosten nichts, aber irgendwo ist Schluss.)
##
## Die Beschleunigung steckt in der VERTEILUNG der Winkel, nicht in der Zeit: Alle Stufen
## dauern gleich lang, aber die Winkelschritte sind an den Enden kurz und in der Mitte lang
## (`smoothstep`). Dadurch faehrt die Umrundung als Ganzes sanft an und aus — waehrend jede
## einzelne Stufe mit gleichbleibendem Tempo laeuft und die Naht zur naechsten nicht auffaellt.
##
## `start` ist der Punkt, an dem die Kamera schon steht. Radius und Anfangswinkel kommen daraus,
## nicht aus Zahlen — so kann zwischen Anflug und Umrundung kein Sprung entstehen.
## Ein Wert, der von `a` ueber `b` nach `c` laeuft — mit `gipfel` als Wendepunkt.
##
## Beide Haelften laufen ueber `smoothstep`, damit am Gipfel keine Spitze entsteht: Dort ist die
## Aenderungsrate auf beiden Seiten null, also geht das Hinaus stufenlos ins Herankommen ueber.
static func _bogen_wert(k: float, a: float, b: float, c: float, gipfel: float) -> float:
	if k <= gipfel:
		return lerpf(a, b, smoothstep(0.0, 1.0, k / maxf(gipfel, 0.001)))
	return lerpf(b, c, smoothstep(0.0, 1.0, (k - gipfel) / maxf(1.0 - gipfel, 0.001)))


## Eine SPIRALE um einen Punkt: drehen, dabei hinausfahren und wieder heran.
##
## `orbit_punkte` haelt den Radius fest — richtig fuer eine Umrundung, bei der das Motiv gleich
## gross bleiben soll. Fuer die Rundsicht auf dem Fels ist es falsch: Dort soll die Figur erst
## gross sein, dann klein werden, waehrend das Land aufgeht, und am Ende wieder gross. Das als
## drei Etappen zu bauen, hiesse an jeder Naht anhalten und neu anfahren — genau das Ruckeln,
## das hier weggeht.
##
## Alles laeuft ueber DENSELBEN Parameter `k`: der Winkel mit `smoothstep` (langsam an, in der
## Mitte am schnellsten, langsam aus), Radius und Hoehe ueber `_bogen_wert` mit ihrem Gipfel bei
## `gipfel`, der Bildwinkel ebenso. Es gibt keine Stelle, an der eine Groesse springen koennte,
## und die Stuetzpunkte tragen `weich: false` — die Beschleunigung steckt in der Verteilung,
## nicht in einer Faltung pro Abschnitt.
static func spirale_punkte(um: Vector3, start: Vector3, bogen_grad: float,
		radius_bis: float, radius_ende: float, hoehe_bis: float, hoehe_ende: float,
		gipfel: float, ziel_hoehe: float, fov_von: float, fov_bis: float,
		sek: float, stufen: int = 60) -> Array:
	var speiche := Vector3(start.x - um.x, 0.0, start.z - um.z)
	var radius0: float = speiche.length()
	if radius0 < 0.5 or stufen < 1:
		return []
	var a0: float = atan2(speiche.z, speiche.x)
	var bogen: float = deg_to_rad(bogen_grad)
	var hoehe0: float = start.y - um.y
	var ziel: Vector3 = um + Vector3(0.0, ziel_hoehe, 0.0)
	var out: Array = []
	for i in range(1, stufen + 1):
		var k: float = float(i) / float(stufen)
		var a: float = a0 + bogen * smoothstep(0.0, 1.0, k)
		var r: float = _bogen_wert(k, radius0, radius_bis, radius_ende, gipfel)
		var h: float = _bogen_wert(k, hoehe0, hoehe_bis, hoehe_ende, gipfel)
		out.append({
			"pos": um + Vector3(cos(a) * r, h, sin(a) * r),
			"ziel": ziel,
			# Der Bildwinkel geht in der ERSTEN Haelfte auf und bleibt dann — das Aufziehen
			# gehoert zum Hinausfahren, das Herankommen soll nicht doppelt wirken.
			"fov": lerpf(fov_von, fov_bis, smoothstep(0.0, gipfel, k)),
			"sek": sek / float(stufen),
			"weich": false,
		})
	return out


static func orbit_punkte(um: Vector3, start: Vector3, bogen_grad: float,
		hoehe_von: float, hoehe_bis: float, ziel_hoehe: float,
		sek: float, stufen: int = 16) -> Array:
	var speiche := Vector3(start.x - um.x, 0.0, start.z - um.z)
	var radius: float = speiche.length()
	if radius < 0.5 or stufen < 1:
		return []
	var a0: float = atan2(speiche.z, speiche.x)
	var bogen: float = deg_to_rad(bogen_grad)
	var ziel: Vector3 = um + Vector3(0.0, ziel_hoehe, 0.0)
	var out: Array = []
	for i in range(1, stufen + 1):
		var k: float = smoothstep(0.0, 1.0, float(i) / float(stufen))
		var a: float = a0 + bogen * k
		out.append({
			"pos": um + Vector3(cos(a) * radius, lerpf(hoehe_von, hoehe_bis, k), sin(a) * radius),
			"ziel": ziel,
			"sek": sek / float(stufen),
			"weich": false,
		})
	return out


func _flight_total() -> float:
	var s: float = 0.0
	for p in _flight:
		s += maxf(float(p["sek"]), 0.05)
	return s


func _process_camera(delta: float) -> void:
	if _cam == null:
		return
	if _in_flight():
		_flight_t += delta
		var ff: Array = _flight_frame()
		_cam.position = ff[0]
		if ff[0].distance_to(ff[1]) > 0.05:
			_cam.look_at(ff[1], Vector3.UP)
		_cam.fov = float(ff[2])
		if _flight_t >= _flight_total():
			_end_flight()
		return
	if _in_cine():
		_cine_left -= delta
		var f: Array = _cine_frame()
		_cam.fov = lerpf(_cam.fov, CINE_FOV, clampf(delta * CINE_RATE, 0.0, 1.0))
		_cam.position = _cam.position.lerp(f[0], clampf(delta * CINE_RATE, 0.0, 1.0))
		_cam.look_at(f[1], Vector3.UP)
		if _cine_left <= 0.0:
			_end_cine()
		return
	# Zurueck in die Spielhaltung. Die Drehung wird NACHGEZOGEN statt zurueckgesetzt: `look_at`
	# hat sie waehrend der Aufnahme veraendert, und ein harter Sprung zurueck sieht aus wie ein
	# Ruckler. Winkelweise interpoliert, damit der Weg ueber ±180° nicht falsch herum geht.
	var ruhe := Vector3(deg_to_rad(-CAM_PITCH), deg_to_rad(CAM_YAW), 0.0)
	var k: float = clampf(delta * CINE_RATE, 0.0, 1.0)
	_cam.rotation = Vector3(
		lerp_angle(_cam.rotation.x, ruhe.x, k),
		lerp_angle(_cam.rotation.y, ruhe.y, k),
		lerp_angle(_cam.rotation.z, ruhe.z, k))
	_cam.fov = lerpf(_cam.fov, CAM_FOV, k)
	# Zoom weich nachziehen, dann die Position — beides mit derselben Zeitkonstanten-Logik.
	_cam_dist = lerpf(_cam_dist, float(CAM_ZOOM_STEPS[_zoom_step()]),
		clampf(delta * CAM_ZOOM_RATE, 0.0, 1.0))
	var want: Vector3 = _player.position + _cam_offset(_cam_dist)
	_cam.position = _cam.position.lerp(want, clampf(delta * CAM_FOLLOW, 0.0, 1.0))


func _process(delta: float) -> void:
	# Der Vorspann liegt VOR allem. Solange er laeuft, gibt es keine Welt, die etwas tun
	# koennte: keine Bewegung, keine Gegner, keine Ausloeser. Sonst spielte das Spiel hinter
	# dem Film weiter, und wer ihn zu Ende sieht, faende die Figur woanders vor als der, der
	# ihn wegtippt.
	#
	# ABER: `_process_vorspann` muss dabei WEITERLAUFEN. Hier stand
	#
	#     if _im_vorspann(): return
	#     _process_vorspann(delta)
	#
	# und das war ein Stillstand im ersten Bild des Spiels. `_im_vorspann()` ist wahr, solange
	# der Videoknoten existiert — und weggeraeumt wird er von `_process_vorspann`, das wegen des
	# Ausstiegs davor nie an die Reihe kam. Das Spiel blieb schwarz stehen: keine Bewegung,
	# keine Oberflaeche, kein Weiterkommen. Wer die Reihenfolge zweier Zeilen vertauscht, baut
	# sich einen Deadlock, und dieser hier hat es bis zum Spieler geschafft.
	if vorspann_regel(_im_vorspann(), _vorspann_t):
		_process_vorspann(delta)
		return
	_process_movement(delta)
	_process_facing(delta)
	_process_camera(delta)
	_process_combat(delta)
	_process_sfx(delta)
	_process_riss(delta)
	_process_erst(delta)
	_maybe_erst_gegner()
	_process_enemies(delta)
	_process_hazards(delta)
	_process_spawns(delta)
	_process_chests(delta)
	_process_ground(delta)
	_process_zone_title(delta)
	_process_fog(delta)
	_process_daytime(delta)
	_process_speech(delta)
	_process_wach(delta)
	_process_marke(delta)
	if _prolog_frage > 0.0:
		_prolog_frage -= delta
	_process_beats(delta)
	_maybe_vista()
	_maybe_intro_flight()
	_check_prolog_done()
	_process_interactions(delta)
	_process_trail(delta)
	_process_mount(delta)
	_sync_weapon()
	_process_recoil(delta)
	_process_autosave(delta)
	_update_hud()


## Nebel aufdecken, wo der Spieler war.
##
## Nicht jeden Frame: Bei 4,7 m/s und 40-m-Zellen dauert es acht Sekunden, bis eine neue Zelle
## erreicht ist — sechzigmal pro Sekunde 25 Zellen zu prüfen, um in 99,8 % der Fälle „schon
## bekannt" zu antworten, ist verschenkte Rechenzeit. Viermal pro Sekunde reicht und deckt
## selbst bei Schnellreise nichts unabsichtlich zu.
const FOG_INTERVAL_SEC: float = 0.25
var _fog_cd: float = 0.0
func _process_fog(delta: float) -> void:
	_fog_cd -= delta
	if _fog_cd > 0.0:
		return
	_fog_cd = FOG_INTERVAL_SEC
	# Nur bei WIRKLICH neuen Zellen neu zeichnen. Die Karte zeichnet sich sonst ohnehin jeden
	# Frame; hier geht es um die Vollbildkarte, die es nicht tut.
	if FogOfWar.reveal(WorldManager.scene_to_world(_player.position)) > 0 and _world_map != null:
		_world_map.queue_redraw()


func _process_movement(delta: float) -> void:
	# Waehrend einer Nahaufnahme laeuft niemand aus dem Bild — und waehrend einer KAMERAFAHRT
	# erst recht nicht. Das war offen und faellt genau im schlimmsten Fall auf: Der Anflug
	# springt an, WAEHREND man auf die Stadt zulaeuft, der Finger liegt also auf dem Stick. Die
	# Figur waere acht Sekunden lang weitergelaufen, waehrend die Kamera anderswo ist, und die
	# Fahrt endete dort, wo sie vor acht Sekunden stand — gut dreissig Meter hinter ihr.
	if _in_cine() or _in_flight():
		# Und zwar auch die BEINE.
		#
		# Das Anhalten stand hier schon, der Clip aber nicht: `play_clip()` wird erst weiter
		# unten aufgerufen, also hinter diesem Ausstieg. Wer gerade lief, als die Fahrt ansprang,
		# behielt den Lauf-Clip — die Figur stand auf der Stelle und rannte weiter.
		#
		# Beim Anflug auf Rustwater faellt das nicht auf, die Kamera ist dabei weit weg. Auf dem
		# Ausguck schon: Dort kreist sie auf 8,5 m um die Figur, und die ist das Motiv.
		#
		# Das Erwachen ist ausgenommen — es hat seinen eigenen Clip (`Stand_Up1`), und der laeuft
		# waehrend derselben Fahrt.
		if _wach_left <= 0.0:
			AssetRegistry.play_clip(_player_model, "idle")
		return
	if _wach_left > 0.0:
		return   # das Erwachen gehoert der Szene; `_process_wach` zaehlt es herunter
	var mv: Vector2 = _move_vector()
	var moving: bool = mv.length() >= 0.05
	# Animation folgt der Bewegung, sobald ein animiertes Modell da ist. Kennt das Modell den
	# Clip nicht (oder ist es der Kapsel-Platzhalter), passiert schlicht nichts.
	#
	# Der Schuss-Clip des Rigs heisst `Run_and_Shoot` — er zeigt eine RENNENDE Figur, die
	# feuert. Deshalb kommt er nur zum Zug, wenn auch tatsaechlich gelaufen wird. Im Stand
	# waere er genau der Rutsch-Effekt, den die Gangart-Regel gerade beseitigt hat; dafuer
	# fehlt dem Rig schlicht ein Clip fuers Schiessen aus dem Stand.
	var clip: String = "idle"
	if moving:
		clip = "attack" if _fire_wanted() else _gait(_speed_ms())
	AssetRegistry.play_clip(_player_model, clip)
	if not moving:
		return
	# Eingabe ist bildschirmbezogen: um die Kamera-Gierung zurückdrehen, damit „nach oben
	# ziehen" auch bei gedrehter Kamera nach oben läuft (sonst zieht es schräg).
	var dir: Vector2 = mv.rotated(-deg_to_rad(CAM_YAW))
	var step: Vector3 = Vector3(dir.x, 0.0, dir.y) * _speed_ms() * delta
	var next: Vector3 = _player.position + step
	# Weltgrenzen (Kraterrand).
	next.x = clampf(next.x, 2.0, WorldManager.WORLD_METERS - 2.0)
	next.z = clampf(next.z, -(WorldManager.WORLD_METERS - 2.0), -2.0)
	# Gate 1: Sprengtore blocken die Nord-Querung, bis Kapitel 5 (WorldManager entscheidet).
	var from_rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var to_rel: Vector2 = WorldManager.scene_to_world(next)
	if not WorldManager.can_cross_blast_line(from_rel.y, to_rel.y):
		next.z = maxf(next.z, -(float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT - 1.5))
		_say("✖ Die Sprengtore sind zu. Erst der Panzerzug (Kapitel 4) bricht sie auf.", 2.5)
		to_rel = WorldManager.scene_to_world(next)
	# Weltstruktur (GDD §1.4a): draußen ist offene Wüste, drinnen begrenzen BAUTEN. Beides
	# geht durch denselben Test — nur ist die Blocker-Liste in der Wildnis leer, weshalb sich
	# dort nichts anfühlt wie eine Wand. Achsenweise nachgeben, damit man an einer Hausecke
	# entlanggleitet statt hängenzubleiben.
	if not WorldManager.is_walkable(to_rel) or _blocked(next) or _gegner_im_weg(next) \
			or _zu_steil(_player.position, next) \
			or _am_riss(next):
		# Erst SCHRAEG zum Hang ausweichen, dann achsenweise.
		#
		# Das achsenweise Nachgeben ist fuer Hausecken gebaut und dort richtig: Waende stehen in
		# der Welt achsenparallel, also gleitet man an ihnen entlang. Ein Berg hat keine Achsen.
		# Wer gegen eine zu steile Stelle laeuft, bekam beide Achsenkandidaten ebenfalls als zu
		# steil zurueck und blieb stehen — obwohl zwanzig Grad daneben ein bequemer Weg lag.
		#
		# Genau so geht man einen Hang auch wirklich hinauf: nicht in der Falllinie, sondern
		# schraeg. Die Ablenkung waechst in Stufen, damit die naechstbeste Richtung gewinnt und
		# die Figur nicht unnoetig quer laeuft.
		var gefunden: bool = false
		for grad in [22.0, -22.0, 45.0, -45.0, 68.0, -68.0]:
			var abgelenkt: Vector2 = Vector2(step.x, step.z).rotated(deg_to_rad(grad))
			var kand: Vector3 = _player.position + Vector3(abgelenkt.x, 0.0, abgelenkt.y)
			kand.x = clampf(kand.x, 2.0, WorldManager.WORLD_METERS - 2.0)
			kand.z = clampf(kand.z, -(WorldManager.WORLD_METERS - 2.0), -2.0)
			if WorldManager.is_walkable(WorldManager.scene_to_world(kand)) \
					and not _blocked(kand) and not _gegner_im_weg(kand) \
					and not _zu_steil(_player.position, kand) \
					and not _am_riss(kand):
				next = kand
				gefunden = true
				break
		if not gefunden:
			var slide_x: Vector3 = Vector3(next.x, 0.0, _player.position.z)
			var slide_z: Vector3 = Vector3(_player.position.x, 0.0, next.z)
			if WorldManager.is_walkable(WorldManager.scene_to_world(slide_x)) and not _blocked(slide_x) \
					and not _gegner_im_weg(slide_x) \
					and not _zu_steil(_player.position, slide_x) and not _am_riss(slide_x):
				next = slide_x
			elif WorldManager.is_walkable(WorldManager.scene_to_world(slide_z)) and not _blocked(slide_z) \
					and not _gegner_im_weg(slide_z) \
					and not _zu_steil(_player.position, slide_z) and not _am_riss(slide_z):
				next = slide_z
			else:
				return   # in eine Ecke gelaufen — Position halten
		step = next - _player.position
	# Die Figur folgt dem Gelaende. Ohne diese Zeile liefe sie auf y = 0 durch jede Senke
	# hindurch — die Vertiefung waere blosse Kulisse.
	next.y = _boden_hoehe(next.x, next.z)
	_player.position = next
	# Drehung weich nachziehen statt hart umzuschnappen: bei einem Joystick wechselt die
	# Richtung stufenlos, und eine Figur, die pro Frame springt, wirkt wie ein Blechspielzeug.
	if Vector2(step.x, step.z).length() > 0.001:
		var want: float = atan2(-step.x, -step.z)
		_player.rotation.y = lerp_angle(_player.rotation.y, want, clampf(delta * TURN_RATE, 0.0, 1.0))


func _nearest_enemy(max_dist: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = max_dist
	for e in _enemies:
		var d: float = _player.position.distance_to(e["node"].position)
		if d < best_d:
			best_d = d
			best = e
	return best


## Liegt der Abzug an? Halten feuert dauerhaft im Waffentakt — bei 3 Schuss pro Sekunde waere
## Einzeltippen auf einem Touchscreen keine Steuerung, sondern eine Zumutung.
func _fire_wanted() -> bool:
	return (_fire_key or _fire_mouse or _fire_touch_id != -1) and not _overlay_open() \
		and _reload_left <= 0.0


## Nachladen anstossen. Laeuft ueber die Zeit und blockiert solange den Abzug — das ist der
## Preis, den eine Waffe mit grossem Magazin zahlt (die Gatling steht viereinhalb Sekunden
## wehrlos da). Ohne Vorrat passiert nichts ausser einem gedrosselten Hinweis: Ein Nachladen,
## das nichts bewirkt, waere schlimmer als gar keines.
func _begin_reload() -> void:
	if _reload_left > 0.0 or AmmoData.mag_full(_weapon_id):
		return
	if not AmmoData.can_reload(_weapon_id):
		if _dry_cd <= 0.0:
			_dry_cd = 1.5
			_say("⚔ %s aus — im Beutel eine andere anlegen"
				% String(AmmoData.POOLS[AmmoData.pool_for(_weapon_id)]["name"]), 1.5)
		return
	_reload_total = PlayerStats.reload_sec(_weapon_id)
	_reload_left = _reload_total


## Kampf. Gezielt wird automatisch auf den naechsten Gegner in Reichweite — es gibt keinen
## zweiten Stick zum Zielen, und den gaebe es auf dem Handy auch nicht sinnvoll. GESCHOSSEN
## wird aber nur auf Befehl: Vorher feuerte die Figur von selbst, sobald irgendetwas in die
## 11-m-Reichweite geriet. Damit war jeder Gegner tot, bevor man ihn ueberhaupt gesehen hatte,
## und der Kampf bestand darin, in die richtige Richtung zu laufen.
func _process_combat(delta: float) -> void:
	if _in_cine():
		return   # kein Abzug waehrend einer Nahaufnahme
	# Nach unten begrenzt, damit der Wert in langen Feuerpausen nicht ins Bodenlose laeuft.
	# Bei -1 s ist der naechste Druck ohnehin sofort ein Schuss.
	_fire_cd = maxf(_fire_cd - delta, -1.0)
	_dry_cd = maxf(_dry_cd - delta, 0.0)
	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			var geladen: int = AmmoData.refill_mag(_weapon_id)
			_reload_left = 0.0
			if geladen > 0 and geladen < AmmoData.mag_size(_weapon_id):
				_say("↻ Nur %d Schuss geladen — der Vorrat geht zur Neige." % geladen, 2.0)
	var e: Dictionary = _nearest_enemy(SHOOT_RANGE_M)
	var wants: bool = _fire_wanted()
	# Ohne Waffe wird nicht geschossen. Der Held erwacht mit leeren Haenden auf der Kippe —
	# bis zur ersten Truhe ist Weglaufen die einzige Antwort, und genau das soll man merken.
	if _weapon_id == "" or _mounted:
		if _fire_btn != null:
			_fire_btn.set_state(false, false)
		if wants and _weapon_id == "":
			_say("✖ Leere Hände. Such dir etwas.", 1.6)
		return
	# Der Knopf zeigt beides an: dass gedrueckt ist UND ob ueberhaupt jemand in Reichweite ist.
	# Ohne die zweite Anzeige waere „nichts passiert" nicht von „kaputt" zu unterscheiden.
	if _fire_btn != null:
		_fire_btn.set_state(wants, not e.is_empty())
	if not wants or e.is_empty() or _fire_cd > 0.0:
		return
	# Magazin statt Dauerfeuer (GDD §7.1.1). Ist es leer, wird von selbst nachgeladen — von
	# Hand geht es mit [R], bevor es leer ist.
	if not AmmoData.consume(_weapon_id):
		_begin_reload()
		return
	_fire_cd = float(PlayerStats.fire_ms(_weapon_id)) / 1000.0
	# ── Streuung: Der Schuss kann DANEBENGEHEN ────────────────────────────────
	# Gezielt wird automatisch, das bleibt so — aber Zielen und Treffen sind zweierlei. Die
	# Abweichung wird aus dem Streukegel der Waffe gewuerfelt und gegen die WINKELBREITE des
	# Gegners geprueft: Wie breit er aus dieser Entfernung erscheint, entscheidet, ob die
	# Abweichung noch auf ihm landet. Damit wird Streuung automatisch zur Reichweitenfrage,
	# ohne dass irgendwo eine Trefferwahrscheinlichkeit von Hand gesetzt waere.
	var to: Vector3 = (e["node"] as Node3D).position - _player.position
	var dist: float = maxf(Vector2(to.x, to.z).length(), 0.5)
	var half_deg: float = rad_to_deg(atan2(float(e["radius"]), dist))
	var dev_deg: float = randf_range(-1.0, 1.0) * PlayerStats.spread_deg(_weapon_id)
	var hit: bool = absf(dev_deg) <= half_deg
	# Der Leuchtspur folgt der ABWEICHUNG, nicht dem Ziel: Ein Fehlschuss muss zu sehen sein,
	# sonst wirkt er wie ein verschluckter Treffer.
	var aim: Vector3 = _player.position + Vector3(to.x, 0.0, to.z).rotated(Vector3.UP, deg_to_rad(dev_deg))
	_spawn_tracer(aim)
	# Der Ton haengt am SCHUSS, nicht am Treffer: Ein Fehlschuss knallt genauso, und alles
	# andere waere eine Trefferanzeige ueber den Ton.
	_schuss_ton()
	if not hit:
		return
	var target: CombatTarget = e["target"]
	var damage_type: String = String(CombatData.WEAPONS[_weapon_id]["type"])
	var acid: int = CombatData.weapon_acid(_weapon_id, 0)
	var res: Dictionary = CombatEngine.resolve_hit(
		damage_type, target, PlayerStats.damage_per_bullet(_weapon_id), acid, Time.get_ticks_msec())
	var frac: float = clampf(float(target.health) / float(target.max_health), 0.0, 1.0)
	(e["bar"] as MeshInstance3D).scale.x = maxf(frac, 0.02)
	if bool(res["killed"]):
		GameState.add_kill()
		GameState.add_xp(CombatData.xp_for_kill(target))
		# Beute FAELLT, statt sich still zu verbuchen. Gold, Munition und Material zieht der
		# Spieler beim Darueberlaufen ein — dadurch hat auch ein erledigter Kampf noch eine
		# Handlung, statt nur eine Zahl im Kopfbereich zu erhoehen.
		var at: Vector3 = (e["node"] as Node3D).position
		_drop(at, "gold", { "amount": target.gold })
		var pool: String = AmmoData.pool_for(_weapon_id)
		_drop(at, "ammo", { "pool": pool, "amount": AmmoData.roll_drop(pool) })
		_roll_material_drop(at)
		# Ausruestung faellt SELTEN — und beim Anfuehrer sechsmal so oft. Gold und Munition
		# liegen weiterhin ueberall; die braucht man laufend. Ausruestung ist der Grund, den
		# Beutel ueberhaupt zu oeffnen, und wenn sie bei jedem Kadaver liegt, ist sie
		# Verwaltungsarbeit statt Fund.
		for _k in BeuteData.stuecke(BeuteData.ist_besonders(target)):
			_drop(at, "gear", ProgressionManager.make_gear(BeuteData.slot(),
				BeuteData.seltenheit()))
		if BeuteData.traegt_schluessel(target):
			GameState.schluessel += 1
			# Der Satz nennt nicht mehr „Anführer": Seit der Endgegner ebenfalls einen trägt,
			# wäre das an einer von zwei Stellen gelogen.
			_say("✦ %s erlegt — ein Schlüssel. %d von %d." % [
				String(CombatData.ENEMY_TYPES[target.type_id]["name"]), GameState.schluessel,
				ChestData.schluessel(ChestData.BOSS)], 2.6)
		else:
			_say("☠ %s erlegt" % String(CombatData.ENEMY_TYPES[target.type_id]["name"]), 1.6)
		# ── Steuerwalzen ──────────────────────────────────────────────────────
		#
		# Sechzehn Erinnerungen stehen seit Langem fertig in `MemoryManager` — und nichts im
		# Spiel hat sie je aufgerufen. Der Kern der Geschichte lag unerreichbar herum.
		#
		# Sie kommen aus MECHANISCHEN Gegnern, und das ist keine Willkuer: Was der Held von
		# sich selbst nicht weiss, steckt in Maschinen derselben Bauart. Wer eine aufschneidet,
		# findet ein Stueck von sich.
		if String(CombatData.ENEMY_TYPES[target.type_id]["class"]) == CombatData.MECHANICAL:
			_walze_bergen(bool(CombatData.ENEMY_TYPES[target.type_id].get("boss", false)))
		(e["node"] as Node3D).queue_free()
		_enemies.erase(e)


## Material-Drop beim Kill (Schrott/Zahnrad/Dampfkern). Ohne diese Drops waeren die
## Sammel-Quests des QuestManagers in der Overworld gar nicht erfuellbar.
func _roll_material_drop(at: Vector3) -> void:
	for entry in DROP_TABLE:
		if randf() < float(entry[1]):
			_drop(at, "material", { "id": String(entry[0]), "amount": 1 })
			return


func _spawn_tracer(to_pos: Vector3) -> void:
	# Ab der MUENDUNG, nicht aus der Brust. Das ist erst aufgefallen, als daneben ein
	# Muendungsfeuer sass: Blitz an der Waffe, Leuchtspur aus dem Brustkorb.
	var von: Vector3 = _muzzle.global_position if _muzzle != null \
		else _player.position + Vector3(0.0, 1.2, 0.0)
	_tracer(von, Vector3(to_pos.x, 1.0, to_pos.z), TRACER_COLOR[_weapon_id])
	_muzzle_flash()


## Die Muendung, GEMESSEN am Modell: das vordere Ende seiner laengsten Achse.
##
## Beim Einbau gerechnet UND vor jedem Schuss nachgezogen. Der erste Entwurf hat nur einmal
## gemessen — und lag um knapp dreissig Zentimeter zu weit hinten, weil die Huellbox eines
## frisch eingehaengten Modells noch nicht die endgueltige ist. Im Bild sass der Blitz dann an
## der Huefte statt am Lauf. Einmal je Schuss messen kostet nichts und stimmt immer.
func _muzzle_spitze() -> Vector3:
	if _weapon_model == null:
		return Vector3.ZERO
	var wb: AABB = AssetRegistry.local_bounds(_weapon_model)
	var mitte: Vector3 = wb.position + wb.size * 0.5
	# Welche Achse ist die lange? Ihre beiden Enden sind die Kandidaten.
	var achse := Vector3(1.0, 0.0, 0.0)
	var halb: float = wb.size.x * 0.5
	if wb.size.z > wb.size.x:
		achse = Vector3(0.0, 0.0, 1.0)
		halb = wb.size.z * 0.5
	var a: Vector3 = mitte + achse * halb
	var b2: Vector3 = mitte - achse * halb
	# Genommen wird das Ende, das nach dem Anbauen am weitesten VORN liegt (Godots Vorne ist −Z
	# im Spielerraum). Damit ist es egal, wie herum ein Modell gebaut ist und wie es gedreht
	# eingehaengt wird — die Muendung ist per Definition das vordere Ende. Vorher stand hier
	# schlicht „+X", und als sich herausstellte, dass dort der Kolben sitzt, sass der Blitz an
	# der Schulter.
	var t: Transform3D = _weapon_model.transform
	return a if (t * a).z <= (t * b2).z else b2


# ── Muendungsfeuer ───────────────────────────────────────────────────────────
## Nicht der Blitz verkauft einen Schuss, sondern das LICHT.
##
## Ein Blitz allein liest sich als Aufkleber vor der Waffe: Er leuchtet, und die Welt daneben
## bleibt, wie sie war. Erst wenn Hand, Boden und Fassade fuer ein Bild mit aufhellen, glaubt
## das Auge, dass dort etwas explodiert ist. Deshalb hat jeder Schuss beides — und das Licht ist
## der teurere, aber unverzichtbare Teil.
##
## Die FARBE kommt aus der Schadensart (GDD §6.1). Das ist nicht Dekoration, sondern
## Kampf-Lesbarkeit (§8.4): Man sieht am eigenen Muendungsfeuer, womit man gerade schiesst,
## ohne ins HUD zu schauen.
##
## Zwei gekreuzte Vierecke statt eines: Ein einzelnes waere aus der Achse der Kamera unsichtbar,
## und ein Billboard drehte sich sichtbar mit, wenn man selbst laeuft.
const FLASH_SEC: float = 0.055
const FLASH_SIZE_M: float = 0.34
const FLASH_LIGHT_M: float = 5.5
const FLASH_LIGHT_ENERGY: float = 7.0
func _muzzle_flash(dauer: float = FLASH_SEC) -> void:
	if _muzzle == null or not is_inside_tree():
		return
	_muzzle.position = _muzzle_spitze()
	var farbe: Color = TRACER_COLOR.get(_weapon_id, Color(1.0, 0.86, 0.45))
	# Zum Weiss hin aufhellen: Ein Muendungsfeuer ist an der Wurzel glutweiss und faerbt sich
	# erst nach aussen. Reine Waffenfarbe saehe aus wie eine getoente Lampe.
	var kern: Color = farbe.lerp(Color(1.0, 1.0, 0.92), 0.55)
	var wurzel := Node3D.new()
	_muzzle.add_child(wurzel)
	wurzel.rotation.z = randf() * TAU
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(kern, 0.9)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_receive_shadows = true
	var sohle: Texture2D = UiAssets.texture("muzzle")
	if sohle != null:
		mat.albedo_texture = sohle
	var gr: float = FLASH_SIZE_M * randf_range(0.82, 1.25)
	for i in 2:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(gr, gr)
		mi.mesh = q
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Um die SCHUSSACHSE gekreuzt, nicht quer dazu.
		#
		# Ein Viereck liegt in der XY-Ebene und schaut nach +Z; seine Ebene ENTHAELT damit schon
		# die X-Achse, entlang der die Waffe zeigt. Genau so soll es sein: Die Flamme steht in
		# Schussrichtung. Der erste Versuch hat es um Y gedreht — damit stand es quer VOR der
		# Muendung und war von der Seite kantig, also unsichtbar. Im Bild war schlicht nichts.
		mi.rotation = Vector3(float(i) * PI * 0.5, 0.0, 0.0)
		wurzel.add_child(mi)
	var licht := OmniLight3D.new()
	licht.light_color = kern
	licht.light_energy = FLASH_LIGHT_ENERGY
	licht.omni_range = FLASH_LIGHT_M
	licht.shadow_enabled = false
	wurzel.add_child(licht)
	get_tree().create_timer(maxf(dauer, 0.01)).timeout.connect(wurzel.queue_free)
	_recoil = RECOIL_RAD


## Rueckstoss: der Lauf hebt sich und faellt zurueck.
##
## Ohne ihn steht die Waffe beim Schuss reglos da, waehrend vorn ein Blitz aufgeht — und die
## BEWEGUNG ist es, die aus einem Effekt einen Schuss macht. Bewusst an der Waffe und nicht an
## der Figur: Fuer den Koerper fehlt dem Rig der Clip fuers Schiessen im Stand.
##
## Gerechnet wird auf der RUHELAGE (`_weapon_ruhe`), nicht auf dem aktuellen Stand. Der erste
## Entwurf setzte `position` und `rotation` einzeln auf Nullwerte, die nie gefuellt wurden —
## beim ersten Schuss sprang die Waffe damit auf den Ursprung der Figur und lag ihr in
## Originalgroesse vor den Fuessen.
const RECOIL_RAD: float = 0.26
const RECOIL_SETTLE: float = 11.0
var _recoil: float = 0.0
var _weapon_ruhe := Transform3D.IDENTITY
func _process_recoil(delta: float) -> void:
	if _weapon_model == null or _recoil <= 0.0001:
		return
	_recoil = maxf(0.0, _recoil - delta * RECOIL_SETTLE * RECOIL_RAD)
	_weapon_model.transform = _weapon_ruhe * Transform3D(
		Basis(Vector3(0.0, 0.0, 1.0), _recoil), Vector3.ZERO)


## Ein Schuss als Strich, 70 ms lang. Eine Funktion fuer beide Richtungen: Seit die Gegner
## zurueckschiessen, gibt es zwei Quellen, und zwei Kopien derselben sieben Zeilen waeren
## genau die Stelle, an der eine Aenderung nur in einer Haelfte landet.
func _tracer(von: Vector3, nach: Vector3, farbe: Color) -> void:
	if not is_inside_tree():
		return           # Testlauf ohne Szenenbaum: es gibt kein Bild, in dem etwas aufblitzen kann
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, von.distance_to(nach))
	tracer.mesh = mesh
	tracer.material_override = _mat(farbe, true)
	add_child(tracer)
	tracer.position = (von + nach) / 2.0
	tracer.look_at(nach)
	get_tree().create_timer(0.07).timeout.connect(tracer.queue_free)


## Die Gegner: heranrücken, zuschlagen, Abstand halten.
##
## Vorher gab es zwei Zustände — laufen und „in Reichweite". In Reichweite floss Schaden je
## Sekunde, solange man dort stand: kein Schlag, kein Ausholen, keine Pause, und die
## Angriffs-Animation lief nebenher als Dauerschleife. Man verlor Leben, ohne dass irgendetwas
## im Bild dafür verantwortlich war.
##
## Jetzt hat ein Angriff einen ABLAUF: ausholen (`windup`) → treffen → nachladen (`cooldown`).
## Der Schaden fällt in dem Bild, in dem die Animation ihn zeigt, und wer in der Zeit aus der
## Reichweite geht, wird nicht getroffen. Die Schadensrate ist dieselbe geblieben
## (`contact × MELEE_INTERVAL_SEC` je Schlag) — es ändert sich nur, dass man sie sieht.
##
## Und Fernkämpfer kämpfen fern. Revolverheld und Konstrukt tragen in `CombatData` seit jeher
## einen `ranged`-Block, den niemand gelesen hat; sie sind bisher wie alle anderen bis auf zwei
## Meter herangerannt. Jetzt bleiben sie in ihrem Reichweitenband stehen und **weichen zurück**,
## wenn man ihnen zu nah kommt.
func _process_enemies(delta: float) -> void:
	var jetzt: int = Time.get_ticks_msec()
	# Erst laufen alle, dann werden Ueberlappungen aufgeloest — siehe `_entflechten()` unten.
	# Umgekehrt (waehrend des Laufens schieben) wuerde jeder Gegner den naechsten in eine Lage
	# druecken, die dessen eigene Bewegung im selben Bild schon wieder aufhebt.
	for e in _enemies:
		var node: Node3D = e["node"]
		if e.has("marken") and is_instance_valid(e["marken"]):
			(e["marken"] as Label3D).text = status_marken(e["target"], jetzt)
		var zu := Vector3(_player.position.x - node.position.x, 0.0,
			_player.position.z - node.position.z)
		var d: float = zu.length()
		e["cooldown"] = maxf(0.0, float(e.get("cooldown", 0.0)) - delta)
		# Im Ausholen wird weder gelaufen noch neu entschieden — sonst bricht der Schlag ab,
		# sobald sich der Spieler einen Schritt bewegt, und man sähe nie einen ganzen.
		if float(e.get("windup", -1.0)) >= 0.0:
			if _tick_windup(e, d, delta):
				return                       # Spieler gestorben; `_enemies` ist neu
			continue
		if d > AGGRO_M:
			if not AssetRegistry.play_clip(e["model"], "idle"):
				AssetRegistry.rest(e["model"])
			_scurry(e, false)
			continue
		var dir: Vector3 = zu / maxf(d, 0.001)
		node.rotation.y = atan2(-dir.x, -dir.z)   # wach heißt: zum Spieler gedreht
		var weit: float = _attack_range(e)
		var nah: float = _min_range(e)
		if d > weit:
			_move_enemy(e, dir, 1.0, delta)
			AssetRegistry.play_clip(e["model"], _gait(_enemy_speed(e)))
		elif nah > 0.0 and d < nah:
			# Zu nah für einen Schützen. Rückwärts, ohne den Spieler aus dem Blick zu lassen —
			# langsamer als vorwärts, sonst kommt man ihm nie bei.
			_move_enemy(e, dir, -RETREAT_SPEED_MUL, delta)
			if not AssetRegistry.play_clip(e["model"], "retreat"):
				AssetRegistry.play_clip(e["model"], _gait(_enemy_speed(e)))
			if float(e["cooldown"]) <= 0.0:
				_begin_attack(e)
		else:
			_scurry(e, false)
			if float(e["cooldown"]) <= 0.0:
				_begin_attack(e)
			elif not AssetRegistry.play_clip(e["model"], "idle"):
				AssetRegistry.rest(e["model"])
	_entflechten()


## Gegner, die sich ueberlappen, auseinanderschieben.
##
## Sie liefen vorher DURCHEINANDER DURCH: Jeder rechnete nur seinen Weg zum Spieler und pruefte
## das Gelaende, keiner je den Nachbarn. Bei einem Rudel stand am Ende alles auf demselben
## Fleck, und aus vier Gegnern wurde optisch einer.
##
## Bewusst KEINE Schwarmtrennung mit Umkreis: Die haelt Abstand, und ein Rudel, das sich brav
## verteilt, sieht aus wie eine Schulklasse beim Aufstellen. Hier wird nur geschoben, was sich
## wirklich beruehrt — Schulter an Schulter ist erlaubt, ineinander nicht.
## Steht an dieser Stelle ein Gegner?
##
## Wird in der Bewegung geprueft wie eine Wand — und das ist die HAELFTE der Spieler-Kollision,
## die dem Spieler nichts wegnimmt. Die andere Haelfte (`_entflechten`) schiebt Gegner aus ihm
## heraus, ohne IHN je zu verschieben: Ein Gegner, der die Figur wegdrueckt, nimmt die Kontrolle
## genau dann, wenn man sie am dringendsten braucht.
##
## Zusammen heisst das: Man laeuft an einem Rudel entlang statt hindurch, aber niemand
## verschiebt einen.
func _gegner_im_weg(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	for e in _enemies:
		var t: CombatTarget = e["target"]
		if t.health <= 0:
			continue        # eine Leiche ist kein Hindernis
		var n: Node3D = e["node"]
		if Gedraenge.beruehrt(q, Gedraenge.SPIELER_R,
				Vector2(n.position.x, n.position.z), Gedraenge.radius_fuer(String(t.type_id))):
			return true
	return false


func _entflechten() -> void:
	if _enemies.is_empty():
		return
	var punkte: Array = []
	var radien: Array = []
	for e in _enemies:
		var n: Node3D = e["node"]
		punkte.append(Vector2(n.position.x, n.position.z))
		radien.append(Gedraenge.radius_fuer(String((e["target"] as CombatTarget).type_id)))
	var neu_pos: Array = Gedraenge.entflechten(punkte, radien)
	# Und dann aus dem SPIELER heraus — er ist ein Koerper wie jeder andere, wird aber nie
	# geschoben. Zuletzt, damit dieser Schub nicht von einer Gegner-Gegner-Aufloesung wieder
	# aufgehoben wird: Lieber zwei Gegner, die sich kurz beruehren, als einer im Spieler.
	if _player != null:
		neu_pos = Gedraenge.aus_dem_weg(neu_pos, radien,
			Vector2(_player.position.x, _player.position.z), Gedraenge.SPIELER_R)
	for i in _enemies.size():
		var p2: Vector2 = neu_pos[i]
		if p2.is_equal_approx(punkte[i]):
			continue
		var n2: Node3D = _enemies[i]["node"]
		# Die HOEHE kommt aus dem Gelaende, nicht aus der Schiebung: Wer seitlich versetzt wird,
		# steht sonst in der Luft oder im Hang.
		n2.position = Vector3(p2.x, WorldManager.height_at(p2.x, p2.y), p2.y)


## Tempo beim Rückwärtsgehen, als Anteil des Vorwärtstempos.
const RETREAT_SPEED_MUL: float = 0.62
## Kulanz beim Treffer: So weit darf man sich während des Ausholens aus der Reichweite bewegt
## haben und wird trotzdem getroffen. Ohne sie verfehlt ein Schlag schon, wenn man beim Ausholen
## normal weitergeht — und Ausweichen wäre nicht Können, sondern Zufall.
const ATTACK_FORGIVE_M: float = 0.8
## Farbe der gegnerischen Leuchtspur. Bewusst NICHT die der eigenen Waffen: Wer im Getümmel
## sehen soll, was auf ihn zufliegt, darf es nicht mit dem eigenen Feuer verwechseln.
const ENEMY_TRACER_COLOR: Color = Color(1.0, 0.42, 0.22)


## Ein Schritt Gegnerbewegung. `mul` < 0 heißt rückwärts.
##
## Steht dort ein Bauwerk, bleibt der Gegner stehen, statt hineinzulaufen. Das galt vorher für
## niemanden — solange alle nur vorwärts auf den Spieler zuliefen, fiel es kaum auf; ein
## Schütze, der rückwärts durch eine Hauswand weicht, dagegen sofort.
func _move_enemy(e: Dictionary, dir: Vector3, mul: float, delta: float) -> void:
	var node: Node3D = e["node"]
	var ziel: Vector3 = node.position + dir * _enemy_speed(e) * mul * delta
	if not _blocked(ziel):
		node.position = Vector3(ziel.x, WorldManager.height_at(ziel.x, ziel.z), ziel.z)
	_scurry(e, true)


## Fernkampf-Block eines Gegners (leer = Nahkämpfer).
func _ranged(e: Dictionary) -> Dictionary:
	var id: String = (e["target"] as CombatTarget).type_id
	return CombatData.ENEMY_TYPES[id].get("ranged", {})


## Entfernung, ab der dieser Gegner angreifen kann.
func _attack_range(e: Dictionary) -> float:
	var f: Dictionary = _ranged(e)
	return CONTACT_RANGE_M if f.is_empty() else float(f["max"]) * CombatData.RANGE_PX_TO_M


## Entfernung, unter der er zurückweicht (0 = weicht nicht).
func _min_range(e: Dictionary) -> float:
	var f: Dictionary = _ranged(e)
	return 0.0 if f.is_empty() else float(f["min"]) * CombatData.RANGE_PX_TO_M


## Holt aus: Animation an, Uhr gestellt. Der Treffer fällt in `_tick_windup`.
func _begin_attack(e: Dictionary) -> void:
	var fern: bool = not _ranged(e).is_empty()
	e["windup"] = CombatData.WINDUP_SHOT_SEC if fern else CombatData.WINDUP_MELEE_SEC
	AssetRegistry.play_clip(e["model"], "attack", false)


## Läuft das Ausholen ab und setzt den Treffer. `true` = der Spieler ist dabei gestorben.
func _tick_windup(e: Dictionary, d: float, delta: float) -> bool:
	_scurry(e, false)
	e["windup"] = float(e["windup"]) - delta
	if float(e["windup"]) > 0.0:
		return false
	e["windup"] = -1.0
	var fern: Dictionary = _ranged(e)
	e["cooldown"] = float(fern["rate"]) / 1000.0 if not fern.is_empty() \
		else CombatData.MELEE_INTERVAL_SEC
	# Wer während des Ausholens weggegangen ist, wird nicht getroffen. Das ist der ganze Grund
	# für das Ausholen: Ohne es gäbe es kein Zeitfenster, in dem Ausweichen etwas nützt.
	if d > _attack_range(e) + ATTACK_FORGIVE_M:
		return false
	var schaden: float = float(fern["dmg"]) if not fern.is_empty() \
		else float((e["target"] as CombatTarget).contact_dps) * CombatData.MELEE_INTERVAL_SEC
	if not fern.is_empty():
		_enemy_tracer(e)
	_hp -= schaden * CombatEngine.player_damage_taken_mul(0)
	if _hp <= 0.0:
		_respawn()
		return true
	return false


## Leuchtspur vom Gegner zum Spieler. Ohne sie ist ein Fernkämpfer ein unsichtbarer Schaden aus
## dem Nichts: Man verliert Leben und sieht nicht, woher.
func _enemy_tracer(e: Dictionary) -> void:
	var node: Node3D = e["node"]
	var hoehe: float = AssetRegistry.height_of(
		AssetRegistry.enemy_asset((e["target"] as CombatTarget).type_id))
	_tracer(node.position + Vector3(0.0, hoehe * 0.72, 0.0),
		_player.position + Vector3(0.0, 1.1, 0.0), ENEMY_TRACER_COLOR)


## Gangart zur Geschwindigkeit. Eine Geh-Animation bei 4,7 m/s (knapp 17 km/h) sieht aus, als
## rutsche die Figur ueber den Boden — der Fusskontakt passt schlicht nicht zum Tempo. Ab
## Laufgeschwindigkeit wird deshalb der Renn-Clip gespielt, darunter der Geh-Clip. Fehlt dem
## Modell die Rolle, faellt `play_clip` von selbst zurueck.
const RUN_THRESHOLD_MS: float = 2.6

func _gait(speed: float) -> String:
	return "run" if speed >= RUN_THRESHOLD_MS else "walk"


## Tempo eines Gegners aus seinen echten Werten (CombatData `speed`, 100 = Referenz) statt
## einer Pauschale — eine Ratte (122) huscht, ein Panzer soll nicht wie ein Grenzgänger traben.
func _enemy_speed(e: Dictionary) -> float:
	var type_id: String = (e["target"] as CombatTarget).type_id
	var s: float = float(CombatData.ENEMY_TYPES[type_id].get("speed", 100))
	return ENEMY_SPEED_MS * (s / 100.0)


## Ersatzbewegung für Modelle OHNE Lauf-Animation, phasenversetzt je Einheit. Kein Ersatz für
## eine echte Animation, aber ein Rudel reglos über den Sand gleitender Ratten sieht kaputt aus.
##
## Nach Klasse getrennt, sonst wird es albern: **Organisches** hüpft (Huschen, Trippeln),
## **Maschinen** wanken nur (ein hüpfender Panzer ist kein Panzer). Die Amplitude hängt an der
## Modellhöhe — eine 0,6-m-Ratte darf nicht so weit vom Boden wie ein 2-m-Konstrukt.
func _scurry(e: Dictionary, moving: bool) -> void:
	if bool(e.get("animated", false)) or e["model"] == null:
		return
	var model: Node3D = e["model"]
	if not moving:
		model.position.y = 0.0
		model.rotation.z = 0.0
		return
	var target: CombatTarget = e["target"]
	var height: float = AssetRegistry.height_of(AssetRegistry.enemy_asset(target.type_id))
	var t: float = Time.get_ticks_msec() / 1000.0 * SCURRY_HZ + float(e["phase"])
	if target.classification == CombatData.MECHANICAL:
		model.position.y = 0.0
		model.rotation.z = sin(t * 0.35) * SCURRY_ROLL_RAD   # schweres Wanken, kein Hüpfen
	else:
		model.position.y = absf(sin(t)) * SCURRY_HOP * height
		model.rotation.z = sin(t * 0.5) * SCURRY_ROLL_RAD


# ── Das Pferd (GDD §8.1a) ────────────────────────────────────────────────────
## Der Krater ist 5 x 5 km und die Laufgeschwindigkeit 4,7 m/s — eine Querung dauert achtzehn
## Minuten. Die Iron Rail nimmt das zwischen den Bahnhoefen weg, aber alles daneben bleibt
## Fussmarsch. Ein Pferd ist deshalb keine Kosmetik, sondern die Antwort auf die Weltgroesse.
##
## Es steht am Rand der Schrottgrube, also **dort, wo das Spiel anfaengt**: Der erste Weg von
## der Kippe nach Rustwater ist gut einen Kilometer lang, und den soll man reiten koennen.
##
## Es gibt noch **kein Modell und keine Reit-Animation** — deshalb ein Platzhalter aus Kasten
## und Beinen, und die Figur sitzt nicht auf, sondern laeuft schneller, waehrend das Pferd
## neben ihr her bleibt. Das ist ehrlich: Es zeigt die Mechanik, ohne so zu tun, als waere die
## Darstellung fertig.
const MOUNT_SPEED_MUL: float = 3.0
const MOUNT_RANGE_M: float = 4.0
var _horse: Node3D = null
var _mounted: bool = false


## Tempo der Figur — zu Fuss oder im Sattel.
func _speed_ms() -> float:
	return WorldManager.PLAYER_SPEED_MS * (MOUNT_SPEED_MUL if _mounted else 1.0)


## Das Pferd absetzen: am Kraterrand der Schrotthalde, auf der Seite von Rustwater.
func _build_horse() -> void:
	var mitte := Vector3.ZERO
	var radius: float = 20.0
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == "schrotthalde":
			mitte = WorldManager.feature_center(f)
			radius = float(f.get("radius", 20.0)) * (1.0 + float(f.get("rim_width", 0.0)))
			break
	if mitte == Vector3.ZERO:
		return
	var nach_stadt: Vector3 = WorldManager.poi_scene_position("rustwater") - mitte
	nach_stadt.y = 0.0
	if nach_stadt.length() < 1.0:
		nach_stadt = Vector3(0.0, 0.0, 1.0)
	nach_stadt = nach_stadt.normalized()
	var wo: Vector3 = mitte + nach_stadt * (radius + 5.0)
	wo.y = WorldManager.height_at(wo.x, wo.z)
	_horse = AssetRegistry.instantiate("horse", 1.6)
	if _horse == null:
		_horse = _horse_dummy()
	_horse.position = wo
	_horse.rotation.y = atan2(-nach_stadt.x, -nach_stadt.z)
	add_child(_horse)
	_label(wo + Vector3(0.0, 2.1, 0.0), "♞ Pferd", Color(0.95, 0.88, 0.70), LBL_FIGUR, 90.0)


## Platzhalter, solange kein Modell da ist: Rumpf, Hals, Kopf, vier Beine. Bewusst grob — wer
## das sieht, weiss sofort, dass hier noch ein Modell fehlt, und haelt es nicht fuer den Stand.
func _horse_dummy() -> Node3D:
	var n := Node3D.new()
	var fell := Color(0.35, 0.24, 0.16)
	n.add_child(_box(Vector3(0.7, 0.8, 2.1), Vector3(0.0, 1.25, 0.0), fell))
	n.add_child(_box(Vector3(0.45, 0.8, 0.5), Vector3(0.0, 1.75, -1.0), fell))
	n.add_child(_box(Vector3(0.4, 0.4, 0.7), Vector3(0.0, 2.05, -1.3), fell))
	for sx in [-0.25, 0.25]:
		for sz in [-0.75, 0.75]:
			n.add_child(_box(Vector3(0.2, 0.9, 0.2), Vector3(sx, 0.45, sz),
				fell.darkened(0.25)))
	return n


## Auf- und absteigen. Im Sattel wird nicht geschossen (GDD §8.1a) — sonst waere das Pferd die
## bessere Version von allem.
## Ist das Pferd in Reichweite — oder sitzt man schon drauf (dann geht Absteigen immer)?
# ── Der Stollen ───────────────────────────────────────────────────────────────
#
# Er liegt bei world 210/380 — zwischen Rustwater (300/300) und den Schrott-Minen (150/450),
# also AM WEG, den man in den ersten Minuten ohnehin laeuft. Ein Dungeon, den man suchen muss,
# findet in einem 5000-m-Krater niemand.
const STOLLEN_WELT: Vector2 = Vector2(210.0, 380.0)
const STOLLEN_NAH_M: float = 4.0
var _stollen_mund: Vector3 = Vector3.ZERO


## Wo der Stolleneingang in der Szene liegt — auf dem Gelaende, nicht darueber.
func _stollen_position() -> Vector3:
	if _stollen_mund == Vector3.ZERO:
		var p: Vector3 = WorldManager.world_to_scene(STOLLEN_WELT)
		_stollen_mund = Vector3(p.x, WorldManager.height_at(p.x, p.z), p.z)
	return _stollen_mund


func _stollen_greifbar() -> bool:
	if _player == null:
		return false
	return _player.position.distance_to(_stollen_position()) <= STOLLEN_NAH_M


## Hinein. Die Rueckkehrstelle wird VORHER gemerkt — danach ist die Szene weg und mit ihr die
## Figur, die man haette fragen koennen.
func _stollen_betreten() -> void:
	GameState.stollen_rueckkehr = _stollen_position()
	GameState.stollen_ebene = 1
	GameState.stollen_startwert = 0    # 0 = der Stollen wuerfelt sich einen neuen Grundriss
	get_tree().change_scene_to_file("res://scenes/Dungeon.tscn")


## Der Einschnitt im Boden: ein dunkles Loch mit Balkenrahmen, dazu ein Schild.
##
## Ohne sichtbares Bauwerk waere der Eingang eine unsichtbare Stelle, an der ploetzlich ein
## Knopf erscheint — und niemand laeuft dorthin, wo nichts zu sehen ist.
func _build_stollen() -> void:
	var wo: Vector3 = _stollen_position()
	var loch := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(5.0, 0.4, 5.0)
	loch.mesh = lb
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.03, 0.03, 0.04)
	loch.material_override = lm
	loch.position = wo + Vector3(0.0, 0.2, 0.0)
	add_child(loch)
	# Vier Balken als Rahmen. Roh, aber sie machen aus einem dunklen Fleck ein BAUWERK — und nur
	# ein Bauwerk sagt „hier hat jemand gegraben".
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.24, 0.17, 0.10)
	for versatz in [Vector3(-2.6, 0.0, 0.0), Vector3(2.6, 0.0, 0.0),
			Vector3(0.0, 0.0, -2.6), Vector3(0.0, 0.0, 2.6)]:
		var balken := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.6, 1.4, 5.8) if absf(versatz.x) > 0.1 else Vector3(5.8, 1.4, 0.6)
		balken.mesh = bb
		balken.material_override = bm
		balken.position = wo + versatz + Vector3(0.0, 0.7, 0.0)
		add_child(balken)
	_label(wo + Vector3(0.0, 2.6, 0.0), "▼ Stollenmund", Color(0.92, 0.80, 0.52), LBL_TRUHE, 160.0)


func _pferd_greifbar() -> bool:
	if _horse == null or _player == null:
		return false
	return _mounted or _player.position.distance_to(_horse.position) <= MOUNT_RANGE_M


func _toggle_mount() -> void:
	if _horse == null:
		return
	if _mounted:
		_mounted = false
		_horse.position = _player.position + Vector3(1.2, 0.0, 0.6)
		_horse.position.y = WorldManager.height_at(_horse.position.x, _horse.position.z)
		_say("♞ Abgestiegen.", 1.8)
		return
	if _player.position.distance_to(_horse.position) > MOUNT_RANGE_M:
		return
	_mounted = true
	_say("♞ Aufgesessen — dreifaches Tempo, aber kein Schuss aus dem Sattel.", 2.6)


## Im Sattel laeuft das Pferd mit. Ohne Reit-Animation bleibt es NEBEN der Figur statt unter
## ihr — untergeschoben saehe es aus, als steckte sie im Ruecken des Tieres.
func _process_mount(delta: float) -> void:
	if _horse == null or not _mounted or _player == null:
		return
	var ziel: Vector3 = _player.position + (_player.global_transform.basis.x * 1.15)
	ziel.y = WorldManager.height_at(ziel.x, ziel.z)
	_horse.position = _horse.position.lerp(ziel, clampf(delta * 9.0, 0.0, 1.0))
	_horse.rotation.y = _player.rotation.y


var _swamp_warned: float = 0.0
func _process_hazards(delta: float) -> void:
	var rel: Vector2 = WorldManager.scene_to_world(_player.position)
	# Smog-DOT (Gate 2) und Strahlensumpf (Gate 0): WorldManager rechnet, die Szene wendet an.
	var dot: int = WorldManager.smog_dot_damage(rel, delta)
	dot += WorldManager.swamp_dot_damage(rel, delta)
	if dot > 0:
		_hp -= float(dot)
		# Sagen, WAS passiert. Leben, das ohne Erklaerung sinkt, liest sich als Fehler; erst der
		# Satz macht aus dem Schaden eine Grenze, die man versteht und respektiert.
		var jetzt: float = Time.get_ticks_msec() / 1000.0
		# Die Marke merkt sich, WAS gerade frisst — mit Nachlauf, weil der Schaden schubweise
		# anfaellt und eine flackernde Warnung keine ist.
		if WorldManager.is_in_swamp(rel):
			_marke_sumpf_bis = jetzt + MARKE_NACHLAUF_SEK
		else:
			_marke_smog_bis = jetzt + MARKE_NACHLAUF_SEK
		if jetzt - _swamp_warned > 2.2:
			_swamp_warned = jetzt
			if WorldManager.is_in_swamp(rel):
				_say("☢ Strahlung! Der Sumpf frisst dich — ohne Schutzanzug kein Durchkommen.", 2.4)
			else:
				_say("☣ Smog! Ohne Alchemie-Filter überlebt das niemand.", 2.4)
		if _hp <= 0.0:
			_respawn()


func _respawn() -> void:
	_hp = float(PlayerStats.max_hp())
	_player.position = _rustwater_spawn()
	_say("☠ Ausgeknockt — zurück in Rustwater.", 3.0)


func _say(text: String, secs: float) -> void:
	if _toast == null:
		return
	_toast.text = text
	_toast_until = Time.get_ticks_msec() / 1000.0 + secs


func _update_hud() -> void:
	# Ort, Entfernung, Sektor und Biom wurden hier jedes Bild ausgerechnet — fuer eine Zeile,
	# die es nicht mehr gibt. Mit ihr faellt die Rechnerei weg: `nearest_poi` laeuft ueber alle
	# Orte, und das sechzigmal in der Sekunde fuer einen Text, den niemand liest.
	var worn_n: int = EquipManager.worn().size()
	# Waffe kann LEER sein — der Held erwacht ohne alles. Ein harter Tabellenzugriff mit dem
	# leeren Namen waere hier der Absturz gleich im ersten Bild des Spiels; deshalb steht die
	# leere Hand als eigener Fall davor und `HudGlyph.z()` gibt fuer Unbekanntes ohnehin nach.
	var waffe: String = "∅ ohne Waffe"
	if _weapon_id != "":
		waffe = "%s %s" % [HudGlyph.z(_weapon_id),
			String(CombatData.WEAPONS[_weapon_id]["name"])]
	# Leben und Erfahrung stehen als BALKEN daneben — hier bleibt die Zahl, weil „wie viel
	# genau" im Kampf zaehlt und ein Balken das nicht beantwortet. Was WEG ist: der Hinweis
	# „[Tab] Inventar". Er stand dort fuer die Tastatur, und auf dem Handy gibt es keine; jetzt
	# ist das Portraet daneben der Knopf, und ein Bild braucht keine Beschriftung.
	if _hp_bar != null:
		_hp_bar.max_value = maxf(1.0, float(PlayerStats.max_hp()))
		_hp_bar.value = clampf(_hp, 0.0, _hp_bar.max_value)
	if _xp_bar != null:
		# `xp` zaehlt INNERHALB der Stufe und wird beim Aufstieg zurueckgesetzt — der Balken
		# braucht deshalb nur den Bedarf der laufenden Stufe, keine Summe ueber alle.
		_xp_bar.max_value = maxf(1.0, float(GameState.xp_to_next(GameState.level)))
		_xp_bar.value = clampf(float(GameState.xp), 0.0, _xp_bar.max_value)
	if _spieler_marken != null:
		var jetzt_s: float = Time.get_ticks_msec() / 1000.0
		_spieler_marken.text = spieler_marken(jetzt_s, _marke_smog_bis, _marke_sumpf_bis)
		# Giftgruen, wenn der Smog frisst, giftgelb bei Strahlung — die Farbe sagt schon aus
		# dem Augenwinkel, welche der beiden Grenzen man gerade uebertritt.
		_spieler_marken.add_theme_color_override("font_color",
			Color(1.0, 0.86, 0.25) if jetzt_s < _marke_sumpf_bis else Color(0.62, 0.95, 0.42))
	# Die Kopfzeile trägt nur noch, was man WÄHREND des Spielens braucht.
	#
	# Vorher standen hier vier dichte Zeilen mit vierzehn Zahlen: Leben, Gold, Stufe, getragene
	# Teile, Waffe, Uhrzeit, dann der nächste Ort mit Entfernung, dann Sektor und Biom, dann
	# noch einmal Zone oder „offene Wüste", dann der Auftrag, dann die Materialien. Im Gefecht
	# liest das niemand — und was niemand liest, verdeckt nur die Welt dahinter.
	#
	# Raus ist die ganze ORTSZEILE. Wo ich bin, beantwortet die Karte oben rechts besser als
	# eine Textzeile, und beim *Betreten* zieht der Name ohnehin groß über die Mitte
	# (`_zone_lbl`). Sektor und Biom waren reine Verwaltungsangaben: Was der Sektor sperrt,
	# erfährt man beim Anrennen; was das Biom tut, steht jetzt als Marke an der Lebensleiste
	# und liegt als Tönung über der Welt.
	#
	# Geblieben ist, was eine ENTSCHEIDUNG trägt — und die Iron-Rail-Zeile ist der Grund, warum
	# hier überhaupt noch eine zweite stehen darf: Sie nennt Tasten, die nur an diesem Fleck
	# etwas tun. Ohne sie wüsste niemand, dass er gerade fahren kann.
	_hud.text = "❤ %d/%d   ¤ %d   ★ Lv %d   ▣ %d/%d   %s   %s" % [
		maxi(0, roundi(_hp)), PlayerStats.max_hp(), GameState.gold, GameState.level,
		worn_n, EquipManager.GEAR_SLOTS.size(), waffe,
		DayCycle.phase_label(GameState.hour)]
	if _station_at_player() != "":
		_hud.text += "   ⇄ [1-5] Iron Rail"
	var q: String = _active_quest_line()
	if q != "":
		_hud.text += "\n✦ " + q
	# Die Trabanten haengen an der LAGE des Schussknopfes, und die steht erst, wenn er selbst
	# `_ready` durchlaufen hat. Einmal je Bild nachziehen kostet nichts und ist gegen jede
	# Reihenfolge unempfindlich — auch gegen eine Fenstergroesse, die sich aendert.
	_trabanten_setzen()
	if _trank_btn != null:
		# Ausgegraut statt versteckt: Ein Knopf, der verschwindet, laesst die Ecke springen —
		# und man greift dann daneben, weil der Daumen die alte Stelle kennt.
		_trank_btn.setzen("trank", GameState.potions,
			GameState.potions > 0 and _hp < float(PlayerStats.max_hp()) - 0.5)
	if _ammo_lbl != null and _weapon_id == "":
		# Leere Haende: Es gibt kein Magazin, also auch keinen Zaehler. Ein „0/0" waere die
		# Behauptung, hier fehle Munition — es fehlt aber die WAFFE, und das steht schon oben.
		_ammo_lbl.text = "∅ —"
		_ammo_lbl.add_theme_color_override("font_color", Color(0.62, 0.60, 0.56))
	elif _ammo_lbl != null:
		var pool: String = AmmoData.pool_for(_weapon_id)
		var mag: int = AmmoData.in_mag(_weapon_id)
		var col := Color(0.92, 0.90, 0.84)
		if _reload_left > 0.0:
			# Waehrend des Nachladens zaehlt die Restzeit — man muss WISSEN, wie lange man
			# noch wehrlos ist, sonst wirkt der blockierte Abzug wie ein Fehler.
			var voll: int = int(round((1.0 - _reload_left / maxf(_reload_total, 0.01)) * 8.0))
			_ammo_lbl.text = "↻ %s%s  %.1f s" % ["▮".repeat(voll), "▯".repeat(8 - voll), _reload_left]
			col = Color(0.55, 0.78, 1.0)
		else:
			_ammo_lbl.text = "%s %d/%d   %d" % [String(AmmoData.POOLS[pool]["icon"]), mag,
				AmmoData.mag_size(_weapon_id), AmmoData.amount(pool)]
			if mag <= 0:
				col = Color(1.0, 0.34, 0.30)
			elif mag <= maxi(1, AmmoData.mag_size(_weapon_id) / 4):
				col = Color(1.0, 0.82, 0.25)
		_ammo_lbl.add_theme_color_override("font_color", col)
	_hud.text += "\n▬ %d  ⚙ %d  ◉ %d" % [
		GameState.item_count("schrott"), GameState.item_count("zahnrad"), GameState.item_count("dampfkern")]
	if _minimap != null:
		var ep: Array = []
		for e in _enemies:
			ep.append((e["node"] as Node3D).position)
		_feed_map(_minimap, ep)
		# Die Weltkarte nur füttern, solange sie offen ist — sonst zeichnet ein unsichtbares
		# Control jeden Frame den ganzen Krater mit elf Ortsnamen neu.
		if _map_is_open():
			_feed_map(_world_map, ep)
	if Time.get_ticks_msec() / 1000.0 > _toast_until:
		_toast.text = ""

# ── Der Vorspann ──────────────────────────────────────────────────────────────
## Das Video laeuft VOR dem Erwachen und geht nahtlos hinein.
##
## Nahtlos heisst hier zweierlei, und das zweite ist das schwierigere:
##
##  1. **Kein Schnitt ins Helle.** Der Film endet, das Bild wird schwarz, und aus dem Schwarz
##     kommt die Spielszene hoch. Ein harter Wechsel vom Film auf die Grube waere ein Sprung
##     zwischen zwei Bildqualitaeten, und genau daran erkennt man eine eingeklebte Sequenz.
##  2. **Kein Wechsel der Erzaehlhaltung.** Der Film zeigt die Muellkippe; das Erwachen faengt
##     dicht am Gesicht an. Das eine geht ins andere ueber, weil beide dieselbe Frage stellen —
##     *wer liegt da* —, und nicht, weil sie aneinandergeklebt sind. Deshalb laeuft der Text
##     erst NACH dem Film an, nicht darueber.
##
## Godot 4 spielt ueber `VideoStreamPlayer` nur Ogg Theora. Fehlt die Datei (etwa in einem
## Zweig, in dem sie nicht mitgeliefert wird), faellt der Vorspann still aus und das Spiel
## faengt beim Erwachen an — ein Intro darf nie zwischen dem Spieler und dem Spiel stehen.
const VORSPANN_PFAD: String = "res://assets/video/intro_muellkippe.ogv"
## Wie lange das Bild am Ende ins Schwarze geht, und wie lange es schwarz BLEIBT, bevor die
## Grube auftaucht. Der Moment Schwarz ist der eigentliche Uebergang: Er nimmt dem Auge den
## Vergleich zwischen Film und Spielbild ab.
const VORSPANN_BLENDE_SEK: float = 1.2
const VORSPANN_SCHWARZ_SEK: float = 0.7
## Wie lange gewartet wird, ob der Film ueberhaupt anlaeuft — und wie lange er hoechstens darf.
##
## Beides ist eine Versicherung gegen dasselbe: Godot spielt nur Ogg Theora, und ob eine Datei
## auf einem bestimmten Geraet wirklich dekodiert wird, entscheidet sich erst dort. Faellt das
## aus, kommt `finished` nie.
const VORSPANN_ANLAUF_SEK: float = 1.5
const VORSPANN_FRIST_SEK: float = 60.0
var _vorspann: VideoStreamPlayer = null
var _vorspann_deckel: ColorRect = null
var _vorspann_t: float = -1.0        # < 0 = laeuft nicht; sonst Restzeit des Ausblendens
var _vorspann_wacht: float = -1.0    # Restzeit, bis der Anlauf geprueft wird
var _vorspann_frist: float = -1.0    # harte Obergrenze fuer den ganzen Vorspann


## Startet den Vorspann. `false`, wenn es keinen gibt — dann geht es sofort weiter.
func _vorspann_starten() -> bool:
	if not ResourceLoader.exists(VORSPANN_PFAD):
		return false
	var strom: VideoStream = load(VORSPANN_PFAD) as VideoStream
	if strom == null:
		return false
	var lage := CanvasLayer.new()
	# UEBER alles, auch ueber die Weltkarte und die Sprechtafel.
	lage.layer = 128
	add_child(lage)
	_vorspann = VideoStreamPlayer.new()
	_vorspann.stream = strom
	_vorspann.expand = true
	_vorspann.set_anchors_preset(Control.PRESET_FULL_RECT)
	lage.add_child(_vorspann)
	# Der Deckel liegt UEBER dem Film und wird am Ende aufgezogen. Er bleibt danach liegen,
	# bis die Spielszene steht — sonst blitzt zwischen letztem Filmbild und erstem Spielbild
	# ein Einzelbild der ungeblendeten Welt auf.
	_vorspann_deckel = ColorRect.new()
	_vorspann_deckel.color = Color(0.0, 0.0, 0.0, 0.0)
	_vorspann_deckel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vorspann_deckel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lage.add_child(_vorspann_deckel)
	_set_hud_hidden(true)
	_vorspann.finished.connect(_vorspann_ende)
	_vorspann.play()
	_vorspann_wacht = VORSPANN_ANLAUF_SEK
	_vorspann_frist = VORSPANN_FRIST_SEK
	return true


## Ein Tipp oder eine Taste ueberspringt den Film. Wer ihn schon kennt, soll ihn nicht
## aussitzen muessen — dieselbe Regel wie bei jeder Kamerafahrt im Prolog.
func _vorspann_ueberspringen() -> void:
	if _vorspann == null or not is_instance_valid(_vorspann):
		return
	if _vorspann.is_playing():
		_vorspann.stop()
	_vorspann_ende()


## Sofort abbrechen — ohne Blende, weil hier ohnehin nichts zu sehen war.
func _vorspann_abbrechen(warum: String) -> void:
	if _vorspann != null and is_instance_valid(_vorspann):
		var lage: Node = _vorspann.get_parent()
		if lage != null:
			lage.queue_free()
	_vorspann = null
	_vorspann_deckel = null
	_vorspann_t = -1.0
	_vorspann_wacht = -1.0
	_vorspann_frist = -1.0
	_set_hud_hidden(false)
	if warum != "":
		_say("◫ " + warum, 3.0)
	_erwachen()


func _vorspann_ende() -> void:
	if _vorspann_t >= 0.0:
		return   # laeuft schon aus
	_vorspann_t = VORSPANN_BLENDE_SEK + VORSPANN_SCHWARZ_SEK


## Ausblenden, Schwarz halten, aufraeumen, Erwachen starten.
func _process_vorspann(delta: float) -> void:
	# ── Zwei Wachhunde ────────────────────────────────────────────────────────
	#
	# Ein Vorspann darf unter keinen Umstaenden das Spiel behalten. Godot spielt nur Ogg
	# Theora, und ob eine bestimmte Datei auf einem bestimmten Geraet wirklich dekodiert wird,
	# entscheidet sich erst dort. Faellt das aus, kommt `finished` nie — und ohne diese beiden
	# Zaehler waere das ein schwarzer Bildschirm ohne Ausweg.
	#
	#  * `_vorspann_wacht` prueft den ANLAUF: Laeuft nach anderthalb Sekunden nichts, laeuft es
	#    gar nicht.
	#  * `_vorspann_frist` ist die harte Obergrenze fuer die ganze Sache.
	if _im_vorspann() and _vorspann_t < 0.0:
		_vorspann_frist -= delta
		if _vorspann_wacht > 0.0:
			_vorspann_wacht -= delta
			if _vorspann_wacht <= 0.0 and not _vorspann.is_playing():
				_vorspann_abbrechen("Der Film laeuft nicht — weiter ohne ihn.")
				return
		if _vorspann_frist <= 0.0:
			_vorspann_abbrechen("")
			return
	if _vorspann_t < 0.0:
		return
	_vorspann_t -= delta
	if _vorspann_deckel != null and is_instance_valid(_vorspann_deckel):
		# In der Blende zu, danach schwarz. Der Film laeuft dahinter aus; ihn zu stoppen waere
		# ein Bildsprung, denn sein letztes Bild bliebe sonst stehen.
		var zu: float = clampf(
			(VORSPANN_BLENDE_SEK + VORSPANN_SCHWARZ_SEK - _vorspann_t) / VORSPANN_BLENDE_SEK,
			0.0, 1.0)
		_vorspann_deckel.color = Color(0.0, 0.0, 0.0, zu)
	if _vorspann_t > 0.0:
		return
	_vorspann_t = -1.0
	if _vorspann != null and is_instance_valid(_vorspann):
		var lage: Node = _vorspann.get_parent()
		if lage != null:
			lage.queue_free()
	_vorspann = null
	_vorspann_deckel = null
	_set_hud_hidden(false)
	# Und jetzt die Szene, in die der Film gemuendet ist.
	_erwachen()


## Laeuft gerade der Vorspann? Solange sperrt er alles andere — Bewegung, Kamera, Ausloeser.
func _im_vorspann() -> bool:
	return _vorspann != null and is_instance_valid(_vorspann)


## Ruht die Welt gerade wegen des Vorspanns?
##
## Die Antwort steht bewusst in EINER Funktion, und die Aufrufstelle benutzt sie fuer beides —
## fuer das Ruhen der Welt UND dafuer, dass der Takt des Vorspanns laeuft. Damit koennen die
## zwei nicht mehr auseinanderlaufen.
##
## Sie liefen einmal auseinander, und das Ergebnis war ein Spiel, das im ersten Bild
## stehenblieb: Die Welt ruhte, weil ein Videoknoten existierte, und derselbe Videoknoten wurde
## nur von dem Takt weggeraeumt, der wegen des Ruhens nicht lief. Zwei Zeilen in der falschen
## Reihenfolge. Als eine Bedingung an einer Stelle ist dieser Fehler nicht mehr formulierbar.
static func vorspann_regel(hat_video: bool, rest_t: float) -> bool:
	return hat_video or rest_t >= 0.0

# ── Ton ───────────────────────────────────────────────────────────────────────
## Die Waffengeraeusche.
##
## Sie sind SYNTHETISCH erzeugt (`tools/sfx/make_sfx.py`), nicht gesammelt. Ein Aufnahme-Archiv
## bringt Lizenzfragen mit, die das ganze Projekt betreffen, und liefert trotzdem selten genau
## den Charakter, den eine Szene braucht. Hier war der Charakter die Vorgabe — peitschend —,
## und der laesst sich bauen.
##
## Zwei Fassungen des Schusses: Der Prolog beginnt im Abendrot und endet tief in der Nacht, und
## nachts traegt kuehle Luft weiter. Die Nachtfassung hat sechs einzelne Rueckwuerfe von den
## Kraterwaenden statt vier und laeuft 2,6 s statt 1,7 aus. Umgeschaltet wird nach `DayCycle`,
## nicht nach Uhrzeit von Hand.
const SFX_SCHUSS_NACHT: String = "res://assets/audio/karabiner_schuss_nacht.ogg"
const SFX_SCHUSS_TAG: String = "res://assets/audio/karabiner_schuss_tag.ogg"
const SFX_REPETIEREN: String = "res://assets/audio/karabiner_repetieren.ogg"
## Wie lange nach dem Schuss repetiert wird. Nicht gleichzeitig: Erst der Knall, dann faehrt der
## Verschluss. 0,22 s ist die Pause, die ein Mensch dafuer braucht — kuerzer klingt nach Automat,
## laenger nach Ladehemmung.
const SFX_REPETIER_VERZUG: float = 0.22
var _sfx_schuss: AudioStreamPlayer3D = null
var _sfx_repetieren: AudioStreamPlayer3D = null
var _repetier_t: float = -1.0


## Die Spieler baumeln AN DER FIGUR, nicht in der Welt: Godot rechnet die Entfernung zur
## Hoerposition selbst aus, und die Kamera wandert im Prolog weit weg. Ein Schuss, der in einer
## Kamerafahrt aus 34 m Abstand genauso laut ist wie aus zwei Metern, klingt wie eine Tonspur
## und nicht wie ein Ereignis in der Welt.
func _build_sfx() -> void:
	if _player == null:
		return
	_sfx_schuss = AudioStreamPlayer3D.new()
	_sfx_schuss.unit_size = 26.0
	_sfx_schuss.max_distance = 320.0
	_player.add_child(_sfx_schuss)
	_sfx_repetieren = AudioStreamPlayer3D.new()
	# Das Repetieren ist ein Geraeusch AN DER WAFFE, kein Schall ueber die Ebene: Es soll nah
	# und trocken bleiben, egal wie weit die Kamera weg ist.
	_sfx_repetieren.unit_size = 4.0
	_sfx_repetieren.max_distance = 40.0
	_sfx_repetieren.volume_db = -4.0
	_player.add_child(_sfx_repetieren)


func _spiel_ton(spieler: AudioStreamPlayer3D, pfad: String, hoehe: float = 0.0) -> void:
	if spieler == null or not is_instance_valid(spieler):
		return
	if not ResourceLoader.exists(pfad):
		return
	spieler.stream = load(pfad) as AudioStream
	# Kleine Tonhoehenstreuung pro Schuss. Ohne sie hoert man beim dritten Mal, dass es
	# dieselbe Datei ist — und ab da klingt jede weitere Salve wie ein Metronom.
	spieler.pitch_scale = 1.0 + hoehe
	spieler.play()


## Ein Schuss: Knall jetzt, Repetieren gleich darauf.
func _schuss_ton() -> void:
	var nacht: bool = DayCycle.daylight(GameState.hour) < 0.35
	_spiel_ton(_sfx_schuss, SFX_SCHUSS_NACHT if nacht else SFX_SCHUSS_TAG,
		randf_range(-0.04, 0.04))
	_repetier_t = SFX_REPETIER_VERZUG


func _process_sfx(delta: float) -> void:
	if _repetier_t < 0.0:
		return
	_repetier_t -= delta
	if _repetier_t <= 0.0:
		_repetier_t = -1.0
		_spiel_ton(_sfx_repetieren, SFX_REPETIEREN, randf_range(-0.06, 0.06))

# ── Der Riss ──────────────────────────────────────────────────────────────────
## Wie tief unter der Ebene die Sperre greift.
##
## Die Steigungsgrenze hilft hier NICHT, und das ist der ganze Punkt: Sie sperrt nur bergauf,
## weil sich niemand festsetzen soll, der schon auf einem steilen Stueck steht. An einem Riss
## laeuft man aber HINUNTER — und stuerbe unten, wenn es dort etwas zum Sterben gaebe. Es
## braucht also eine eigene Sperre, und sie haengt an der Hoehe, nicht an der Neigung.
##
## 1,2 m: Die Kante bricht ueber sieben Meter waagerecht um vierzig senkrecht ab. Wer 1,2 m
## unter der Ebene steht, ist noch keinen halben Schritt hinein und kommt jederzeit zurueck;
## einen Schritt weiter waere er im freien Fall.
const RISS_SPERRE_M: float = 1.2
## Wie weit vor der Kante das Warnband liegt.
const RISS_BAND_M: float = 2.6
var _riss: Dictionary = {}


## Steht dieser Punkt schon im Riss?
##
## ZWEI Fragen, und die erste ist die wichtige: Liegt der Punkt ueberhaupt in der Naehe des
## Risses? Erst danach zaehlt die Hoehe.
##
## Die Hoehe allein war der erste Entwurf, und er haette den Prolog vollstaendig gesperrt: Die
## Schrottgrube ist fuenf Meter tief, der Held erwacht an ihrem Grund — und `height_at()` meldet
## dort −5 m. Mit einer reinen Hoehenpruefung waere jeder Schritt in der Grube ein Schritt „in
## den Riss" gewesen, und das Spiel haette mit einer bewegungslosen Figur angefangen. Der Test
## hat es gefunden, bevor es jemand spielen musste.
##
## Die Hoehe wird trotzdem gebraucht, sobald man in der Naehe ist: Der Riss schlaengelt, und
## eine reine Abstandsrechnung muesste den Schlenker noch einmal nachbauen. `height_at()` weiss
## ihn schon.
func _am_riss(p: Vector3) -> bool:
	if _riss.is_empty():
		return false
	var c: Vector3 = WorldManager.feature_center(_riss)
	var halb: Vector2 = WorldManager.feature_halb(_riss)
	if absf(p.x - c.x) > halb.x or absf(p.z - c.z) > halb.y:
		return false
	# Auf dem Steg ist der Riss kein Riss. Er liegt von Anfang an da — nichts wird
	# aufgeschlossen, man muss nur die richtige Stelle finden.
	if _auf_steg(p):
		return false
	return WorldManager.height_at(p.x, p.z) < -RISS_SPERRE_M


## Ein Warnband entlang beider Kanten.
##
## Eine unsichtbare Sperre an einem Abgrund ist derselbe Fehler wie damals an der Palisade, wo
## die Fussspur vor der Mauer endete: Der Spieler laeuft dagegen und weiss nicht, warum. Also
## bekommt die Kante etwas, das man SIEHT — kein Zaun (den haette jemand gebaut), sondern das,
## was ein Abbruch von selbst hat: eine Linie, an der der Sand aufhoert und der Fels anfaengt.
func _build_riss() -> void:
	for f in WorldManager.TERRAIN:
		if String(f.get("kind", "crater")) == "spalt":
			_riss = f
			break
	if _riss.is_empty():
		return
	var c: Vector3 = WorldManager.feature_center(_riss)
	var halb: Vector2 = WorldManager.feature_halb(_riss)
	var nord: bool = String(_riss.get("achse", "nord")) == "nord"
	var laenge: float = float(_riss["laenge"])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.09, 0.10)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var schritte: int = 260
	for seite in [-1.0, 1.0]:
		for i in schritte:
			var streifen: Array = []
			for j in [0, 1]:
				var t: float = (float(i + j) / float(schritte) - 0.5) * laenge
				# Die Kante wird GESUCHT, nicht gerechnet: von aussen nach innen tasten, bis der
				# Boden abfaellt. Damit stimmt das Band auch dann noch, wenn jemand den
				# Schlenker aendert — dieselbe Regel wie beim Leuchtring auf dem Ausguck.
				var kante: float = 0.0
				var d: float = float(_riss.get("schlenker", 0.0)) + float(_riss["breite"])
				while d > 0.0:
					var px: float = c.x + (seite * d if nord else t)
					var pz: float = c.z + (t if nord else seite * d)
					if WorldManager.height_at(px, pz) < -0.35:
						kante = d
						break
					d -= 0.25
				if kante == 0.0:
					kante = float(_riss["breite"]) * 0.5
				for aussen in [kante + RISS_BAND_M, kante]:
					var qx: float = c.x + (seite * aussen if nord else t)
					var qz: float = c.z + (t if nord else seite * aussen)
					streifen.append(Vector3(qx, WorldManager.height_at(qx, qz) + 0.08, qz))
			if streifen.size() == 4:
				for idx in [0, 1, 3, 0, 3, 2]:
					st.add_vertex(streifen[idx])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.name = "riss_band"
	add_child(mi)
	# Und ein Name dafuer. Ohne den ist es ein Loch; mit ihm ist es ein Ort, an dem man schon
	# einmal war, wenn man das naechste Mal davon hoert.
	var lbl: Vector3 = c + (Vector3(0.0, 6.0, 0.0))
	_label(lbl, "☰ DER RISS", Color(0.72, 0.74, 0.80), LBL_LANDMARKE, 700.0)


## Meldung an der Kante — einmal, und dann eine Weile nicht wieder.
var _riss_hinweis: float = 0.0
func _process_riss(delta: float) -> void:
	_riss_hinweis = maxf(_riss_hinweis - delta, 0.0)
	if _riss.is_empty() or _player == null or _riss_hinweis > 0.0:
		return
	if _in_cine() or _in_flight() or _overlay_open():
		return
	if not _am_riss(_player.position):
		return
	_riss_hinweis = 12.0
	_say("☰ Der Riss. Zehn Meter Nichts — hier kommt niemand hinüber.", 3.0)

# ── Der erste Gegner ──────────────────────────────────────────────────────────
## Die Szene, in der aus der Welt ein Spiel wird.
##
## **Wann:** wenn er den Krater verlaesst — nicht vorher. In der Grube geht es um ihn selbst;
## draussen faengt die Welt an.
##
## **Einer**, nicht das uebliche Rudel. Wer zum ersten Mal etwas sieht, das hier herumlaeuft,
## soll es ANSEHEN koennen.
##
## Und eine MASCHINE. Zuerst stand hier ein Grenzgaenger — ein Mensch, weil die Frage „was bist
## du gewesen" bei etwas Menschlichem am staerksten traegt. Das war die falsche Rechnung: Ein
## bewaffneter Mann in der Wueste ist keine Ueberraschung, sondern das, was man dort erwartet.
## Ein zweibeiniger Kessel, der aus dem Blech kommt, ist eine — und er stellt die Frage, um die
## es im ganzen Spiel geht, gleich in der ersten Minute: Was ist hier Mensch und was Maschine.
## (Der Held weiss es von sich selbst noch nicht.)
##
## Der **Kessel-Klaeffer** waere das schoenere Tier gewesen — vierbeinig, hundegross, es gibt
## ihn als Gegnertyp. Es gibt ihn nur nicht als MODELL; `klaeffer.glb` steht noch auf der Liste
## der fehlenden Sachen. Also das naechstliegende, das da ist: das **Konzern-Konstrukt**. Zwei
## Meter hoch, gepanzert, mechanisch — keine Ratte, kein Mensch.
##
## Dass es hier mit einem Schuss faellt und spaeter nicht, traegt der Text: Dieses eine ist ein
## Wrack, das halb im Schrott gelegen hat. Wer spaeter einem heilen begegnet, merkt den
## Unterschied, und der Satz vorher hat ihn angekuendigt.
##
## **Und die Beute ist erst DANACH da.** Nicht vorher: Der Sinn der Szene ist, dass man es
## lernt, und wer vorher schon einsammeln kann, lernt nichts. Aus einer Maschine ist sie
## ausserdem selbsterklaerend — Schrauben, ein Zahnrad, ein Dampfkern. Aus einem Menschen waere
## sie eine Erklaerung gewesen, die man haette liefern muessen.
const ERST_ABSTAND_M: float = 22.0     # so weit vor ihm taucht der eine Gegner auf
const ERST_ABSTAND_QUER_M: float = 7.0 # und so weit seitlich daneben
const ERST_AUSLOESER_M: float = 34.0   # so weit vom Kraterrand weg springt die Szene an
const ERST_SEK_SEHEN: float = 1.8      # erst beide im Bild — „da ist etwas"
## Die Schulterkamera der ersten Etappe: zurueck, zur Seite, hoch — und wohin sie blickt.
const ERST_SCHULTER_ZURUECK: float = 4.6
const ERST_SCHULTER_QUER: float = 2.4
const ERST_SCHULTER_HOCH: float = 2.3
const ERST_BLICK_ANTEIL: float = 0.35
const ERST_FOV_SEHEN: float = 44.0
## Und dann der ZOOM auf das Ding selbst.
##
## Vorher blieb die Kamera die ganze Zeit ueber der Schulter, und der Gegner war ein kleiner
## Umriss in 22 m Entfernung. Der Prolog verlangt aber genau das Gegenteil: Der Held soll es
## ANSEHEN koennen und sich wundern, was das ist — und das kann er nicht, wenn man es kaum
## erkennt. Ein Weitwinkel beantwortet „wo bin ich"; hier ist die Frage „was ist das".
##
## Lang genug zum Hinsehen: Bei zwei Sekunden ist der Schwenk gerade angekommen, wenn er schon
## wieder wegfaehrt.
const ERST_SEK_ZOOM: float = 3.0
## Der SCHNITT zurueck auf die Halbtotale. Kein Rueckflug — ein Schnitt.
##
## Auch das hat erst ein Bild gezeigt: Nach dem Zoom stand als naechste Etappe wieder die
## Schulterkamera, und `_flight_frame` faehrt zwischen zwei Etappen weich hinueber. Die Kamera
## kroch also aus fuenf Metern Entfernung ueber anderthalb Sekunden zurueck — und als der Schuss
## fiel, war sie erst zur Haelfte da. Der Held stand nicht im Bild, als er abdrueckte.
##
## 0,06 s sind rund vier Bilder: schnell genug, dass es als Schnitt liest, und die eine Etappe,
## die danach folgt, hat Anfang und Ende am selben Punkt — sie steht also STILL. Genau das
## braucht der Augenblick, in dem etwas passiert.
const ERST_SEK_SCHNITT: float = 0.06
const ERST_SEK_SCHUSS: float = 1.6
const ERST_SEK_HIN: float = 3.4        # hinuebergehen und sich buecken
const ERST_SEK_LEICHE: float = 4.6     # die Kamera auf den Toten
const ERST_SEK_HEIM: float = 2.0
var _erst_gegner: Dictionary = {}
var _erst_phase: int = 0               # 0 = steht aus, 1 = laeuft, 2 = vorbei


## Springt an, sobald er weit genug vom Krater weg ist.
func _maybe_erst_gegner() -> void:
	if GameState.erst_gegner_done or _erst_phase != 0 or _player == null:
		return
	if GameState.prolog_done or _in_cine() or _in_flight() or _overlay_open():
		return
	if _weapon_id == "":
		return   # ohne Waffe waere es eine Hinrichtung ohne Werkzeug
	var f: Dictionary = _feature("schrotthalde")
	if f.is_empty():
		return
	var c: Vector3 = WorldManager.feature_center(f)
	var d: float = Vector2(_player.position.x - c.x, _player.position.z - c.z).length()
	if d < WorldManager.feature_reach(f) + ERST_AUSLOESER_M:
		return
	_erst_starten()


## Die Schulterkamera der ersten Etappe — als Rechnung, damit sie pruefbar ist.
##
## Zurueck kommen `[Standpunkt, Blickziel, Richtung zum Gegner]`.
##
## Sie steht hier und nicht in `_erst_starten`, weil sie einmal falsch war und niemand es
## gemerkt hat: Die erste Fassung setzte die Kamera hinter die BLICKRICHTUNG des Helden statt
## hinter die Linie zu dem Ding. Beides klingt gleich und ist es nicht — der Gegner erscheint
## seitlich vor ihm, die Richtungen liegen 17,6° auseinander. Damit lag der Held 36,2° neben
## der Bildachse, der Rahmen reicht bei 44° und 16:9 aber nur 35,7° weit, und auf der Aufnahme,
## die „beide im Bild" heissen sollte, war weder der eine noch der andere zu sehen: nur Sand.
##
## Als Rechnung kann der Test nachmessen, ob beide wirklich im Rahmen stehen. Als Zeile mitten
## in einer Szenenfunktion konnte er nur nachlesen, dass dort eine Kamera gesetzt wird.
static func erst_schulter(spieler: Vector3, gegner: Vector3) -> Array:
	var hin: Vector3 = Vector3(gegner.x - spieler.x, 0.0, gegner.z - spieler.z)
	hin = hin.normalized() if hin.length() > 0.001 else Vector3(0.0, 0.0, -1.0)
	var quer_hin := Vector3(-hin.z, 0.0, hin.x)
	# SEITLICH HINTER seiner Schulter, auf dieser Achse: der Held vorn, das Ding dahinter in
	# der Tiefe.
	var schulter: Vector3 = spieler - hin * ERST_SCHULTER_ZURUECK \
		+ quer_hin * ERST_SCHULTER_QUER + Vector3(0.0, ERST_SCHULTER_HOCH, 0.0)
	# Der Blick liegt bei gut einem Drittel zwischen beiden und nicht in der Mitte: Der Held ist
	# fuenf Meter weg, das Ding achtundzwanzig. Die Mitte haette ihn an den Rand gedraengt.
	var brust: Vector3 = spieler + Vector3(0.0, 1.3, 0.0)
	var ziel_brust: Vector3 = gegner + Vector3(0.0, 1.2, 0.0)
	return [schulter, brust.lerp(ziel_brust, ERST_BLICK_ANTEIL), hin]


func _erst_starten() -> void:
	_erst_phase = 1
	GameState.erst_gegner_done = true
	# Ab jetzt darf die Welt sich fuellen. Das Empfangskomitee am Suedtor wurde beim Aufbau
	# uebersprungen (die Grube sollte leer sein) — ohne diesen Nachzug bliebe Rustwater fuer
	# den Rest der Runde unbewacht, und die erste Stadt waere ein Spaziergang.
	_spawn_pack()
	var blick: Vector3 = -_player.global_transform.basis.z
	blick.y = 0.0
	if blick.length() < 0.1:
		blick = Vector3(0.0, 0.0, -1.0)
	blick = blick.normalized()
	var quer := Vector3(-blick.z, 0.0, blick.x)
	# SEITLICH vor ihm, nicht frontal: Er kommt aus dem Blech heraus und hat den Helden noch
	# nicht gesehen. Frontal waere es ein Duell; so ist es eine Begegnung.
	var wo: Vector3 = _player.position + blick * ERST_ABSTAND_M + quer * ERST_ABSTAND_QUER_M
	wo.y = WorldManager.height_at(wo.x, wo.z)
	_erst_gegner = _make_enemy("konstrukt")
	var n: Node3D = _erst_gegner["node"] as Node3D
	n.position = wo
	n.rotation.y = atan2(-quer.x, -quer.z)
	add_child(n)
	_enemies.append(_erst_gegner)
	var brust: Vector3 = _player.position + Vector3(0.0, 1.3, 0.0)
	var ziel_brust: Vector3 = wo + Vector3(0.0, 1.2, 0.0)
	var kamera: Array = erst_schulter(_player.position, wo)
	var schulter: Vector3 = kamera[0]
	var zwischen: Vector3 = kamera[1]
	var hin: Vector3 = kamera[2]
	# Die Kamera faehrt AUF DEN GEGNER ZU, dicht heran und mit engem Bildwinkel. Sie bleibt auf
	# derselben Achse — man sieht es aus SEINER Richtung und nicht von irgendwo, also bleibt es
	# sein Blick und wird keine Regieaufnahme.
	var nah: Vector3 = wo - hin * 5.2 + Vector3(0.0, 1.9, 0.0)
	# Zurueck auf GENAU die Einstellung der ersten Etappe — derselbe Standpunkt, dasselbe
	# Blickziel, derselbe Bildwinkel. Der erste Versuch nahm einen Meter naeher und zielte auf
	# die Brust des Gegners; das Bild zeigte, was davon uebrigbleibt: Der Held rutschte in die
	# untere linke Ecke und verschwand halb hinter der Sprechtafel — ausgerechnet in dem
	# Augenblick, in dem er abdrueckt. Die Halbtotale ist nachgemessen (der Test rechnet sie
	# nach), also wird sie wiederverwendet statt neu erfunden.
	var schnitt: Vector3 = schulter
	var punkte: Array = [
		{ "pos": schulter, "ziel": zwischen, "sek": ERST_SEK_SEHEN, "fov": ERST_FOV_SEHEN },
		# Der Zoom. Enger Bildwinkel statt naeher Position allein: Ein 26°-Objektiv druckt den
		# Hintergrund flach und holt das Ding heran, ohne dass die Kamera in ihm steht.
		{ "pos": nah, "ziel": ziel_brust, "sek": ERST_SEK_ZOOM, "fov": 26.0 },
		# Und zurueck auf die Halbtotale — als SCHNITT, nicht als Fahrt (siehe
		# ERST_SEK_SCHNITT). Danach steht die Kamera still, und in dieser Ruhe faellt der Schuss.
		{ "pos": schnitt, "ziel": zwischen, "sek": ERST_SEK_SCHNITT, "fov": ERST_FOV_SEHEN,
			"weich": false },
		{ "pos": schnitt, "ziel": zwischen, "sek": ERST_SEK_SCHUSS, "fov": ERST_FOV_SEHEN },
	]
	_play_flight(punkte)
	# Der zweite Satz faellt jetzt IN den Zoom: Er sagt, was man in dem Moment sieht.
	_play_speech(HELD_NAME, "held", [
		"„…was zum.“",
		"„Das läuft. Das ist Blech, und es läuft.“",
		"„Und es hat mich noch nicht gesehen.“",
	])
	_erst_schuss_t = ERST_SEK_SEHEN + ERST_SEK_ZOOM + ERST_SEK_SCHNITT \
		+ ERST_SEK_SCHUSS * 0.55


var _erst_schuss_t: float = -1.0
var _erst_leiche_t: float = -1.0


func _process_erst(delta: float) -> void:
	if _erst_phase != 1:
		return
	if _erst_schuss_t >= 0.0:
		_erst_schuss_t -= delta
		if _erst_schuss_t <= 0.0:
			_erst_schuss_t = -1.0
			_erst_abdruecken()
	if _erst_leiche_t >= 0.0:
		_erst_leiche_t -= delta
		if _erst_leiche_t <= 0.0:
			_erst_leiche_t = -1.0
			_erst_beute()


## Er drueckt ab, ohne dass jemand den Knopf gedrueckt haette.
##
## Die Schuss-ANIMATION fehlt noch; bis sie da ist, laeuft der vorhandene Angriffs-Clip. Der
## Rest der Szene haengt nicht daran: Muendungsfeuer, Leuchtspur und Ton stehen, und das ist
## das, was man hoert und sieht.
func _erst_abdruecken() -> void:
	if _erst_gegner.is_empty():
		return
	var n: Node3D = _erst_gegner["node"] as Node3D
	if not is_instance_valid(n):
		return
	_player.look_at(Vector3(n.position.x, _player.position.y, n.position.z), Vector3.UP)
	AssetRegistry.play_clip(_player_model, "attack", false)
	_spawn_tracer(n.position)
	_schuss_ton()
	# Der Gegner faellt. Bis eine Sterbe-Animation da ist: `idle` weiterlaufen lassen und das
	# Modell auf die Seite kippen. Das ist ein Platzhalter und sieht auch so aus — besser als
	# eine Leiche, die steht.
	n.rotation.x = -PI * 0.5
	n.position.y = WorldManager.height_at(n.position.x, n.position.z) + 0.35
	var e_ziel: Vector3 = n.position + Vector3(0.0, 0.5, 0.0)
	var blick: Vector3 = Vector3(n.position.x - _player.position.x, 0.0,
		n.position.z - _player.position.z).normalized()
	# Er geht hinueber und beugt sich darueber, und die Kamera faehrt langsam auf den Toten zu,
	# bis er das Bild fuellt. Erst hier sieht man, dass in ihm etwas steckt.
	_play_flight([
		{ "pos": _player.position - blick * 5.0 + Vector3(0.0, 2.4, 0.0),
			"ziel": e_ziel, "sek": ERST_SEK_HIN, "fov": 46.0 },
		{ "pos": n.position - blick * 2.6 + Vector3(0.0, 1.5, 0.0),
			"ziel": e_ziel, "sek": ERST_SEK_LEICHE, "fov": 40.0 },
		{ "pos": _player.position + _cam_offset(_cam_dist),
			"ziel": _player.position + Vector3(0.0, 1.0, 0.0),
			"sek": ERST_SEK_HEIM, "fov": CAM_FOV },
	])
	_play_speech(HELD_NAME, "held", [
		"„Das ging schnell. Zu schnell.“",
		"„Ich hab nicht nachgedacht. Meine Hände schon.“",
		"„…und woher weiß ich, wo man so ein Ding trifft?“",
		"„Der war halb hin. Rost bis zum Kessel. Ein heiler hätte gestanden.“",
		"„Es zischt noch. Ein Ding, das zischt, wenn es liegt.“",
		"„Da drin klappert was. Schrauben. Ein Zahnrad. Und ein Kern, der noch warm ist.“",
		"„Das hat jemand gebaut. Jemand baut so was und lässt es hier laufen.“",
		"„Also nehm ich, was drin ist. Es braucht das nicht mehr, und ich schon.“",
	])
	_erst_leiche_t = ERST_SEK_HIN + ERST_SEK_LEICHE


## Und ERST JETZT liegt etwas da.
func _erst_beute() -> void:
	_erst_phase = 2
	if _erst_gegner.is_empty():
		return
	var n: Node3D = _erst_gegner["node"] as Node3D
	if not is_instance_valid(n):
		return
	var at: Vector3 = n.position
	var pool: String = AmmoData.pool_for(_weapon_id)
	_drop(at, "ammo", { "pool": pool, "amount": AmmoData.roll_drop(pool) })
	_drop(at + Vector3(1.1, 0.0, 0.4), "material", { "id": "schrott", "amount": 2 })
	_drop(at + Vector3(-0.9, 0.0, 0.8), "material", { "id": "zahnrad", "amount": 1 })
	# Der Dampfkern liegt hier GARANTIERT und wird nicht ausgewuerfelt — der Held spricht ihn
	# aus („ein Kern, der noch warm ist"), und was ausgesprochen wird, muss auch dort liegen.
	_drop(at + Vector3(0.2, 0.0, -1.0), "material", { "id": "dampfkern", "amount": 1 })
	# Und die ERSTE Steuerwalze, garantiert. Der Anfang einer Geschichte darf nicht auswuerfeln,
	# ob sie stattfindet — dieselbe Regel wie beim Karabiner in der Truhe. Danach kommen sie mit
	# drei Prozent aus jeder Maschine, und der Spieler weiss dann schon, was sie sind.
	_walze_bergen(false, true)
	n.queue_free()
	_enemies.erase(_erst_gegner)
	_erst_gegner = {}
	_say("▤ Aufheben: darüberlaufen.", 3.0)


## Die vier Waende am Welthorizont — mit Scheitelfarben statt als Kiste.
const RIM_H: float = 210.0
## So weit DRAUSSEN vor der Weltgrenze steht der Ring. Er ist damit nicht erreichbar und
## verdeckt auch dann noch den Horizont, wenn man ganz am Rand steht.
##
## 220 m und nicht mehr 75: Die runden Ecken brauchen Platz. Eine Rundung schneidet die Ecke
## IMMER an — der Bogen liegt an seiner engsten Stelle 0,41 x Radius hinter der Rechteckecke —,
## und bei 75 m Abstand lagen die vier Weltecken damit ausserhalb des Rings. Man waere dort aus
## der Welt herausgelaufen. Der Test hat es gefangen (4 von 8 Eckpunkten drinnen).
##
## Was der groessere Abstand kostet, ist wenig: Am Rand steht die 210-m-Wand jetzt 220 m statt
## 75 m entfernt und deckt 44° statt 70° des Himmels. Sie ist dort immer noch eine Wand.
const RIM_ABSTAND: float = 220.0
const RIM_DICKE: float = 150.0
## Ab welcher Hoehe die Wand in den Himmel uebergeht. Darunter Fels, darueber Verlauf.
const RIM_FELS_ANTEIL: float = 0.34
var _rim_mats: Array = []
## Der Kraterrand als geschlossener RING mit runden Ecken — je `[Name, Mitte, Laengsvektor]`.
##
## ## Warum kein Rechteck mehr
##
## Weil ein Rechteck von innen IMMER eine Kante zeigt, und zwar unabhaengig davon, wie sauber
## die Ecken gebaut sind. Auf den Aussenaufnahmen stand rechts oben ein Absatz, an dem der Grat
## von einer Hoehe auf eine andere sprang. Ein Strahl durch genau diesen Bildpunkt hat es
## beantwortet: links die Westwand aus 2048 m, rechts die Nordwand aus 4752 m. Zwei Waende, die
## sich luecklos in einer Ecke treffen, stehen fuer den Betrachter trotzdem verschieden weit weg
## — und ein 210-m-Grat ist aus 2 km doppelt so hoch wie aus 4,8 km. Die Stufe IST die Ecke.
##
## Vorher waren an derselben Stelle zwei andere Erklaerungen naheliegend und beide falsch (ein
## Loch an der Ecke, eine fehlende Querblende). Beide sind repariert worden, und beide Male blieb
## der Absatz stehen. Erst der Strahl hat die Frage entschieden.
##
## ## Was stattdessen
##
## Ein Ring mit abgerundeten Ecken. An den Seiten liegt er weiter dort, wo er lag —
## `RIM_ABSTAND` vor der Weltgrenze, also nah und hoch —, und in den Ecken laeuft er auf einem
## Bogen herum. Damit aendert sich der Abstand zum Betrachter stetig, und mit ihm die Hoehe des
## Grats: kein Sprung mehr, weil es keine Ecke mehr gibt.
##
## Und weil der Ring GESCHLOSSEN ist, hat er keine Enden. Die Querblende, die die Enden weich
## machen sollte, ist damit ersatzlos weg — die beste Art, ein Problem zu loesen.
##
## `RIM_ECK_R` ist der Radius der Rundung, `RIM_ECK_STUFEN` ihre Aufloesung.
## Der Radius der Rundung. Er ist nach oben gebunden, und die Schranke ist keine Vorsicht,
## sondern Geometrie: Ein Bogen vom Radius `r`, der zwei rechtwinklige Kanten verbindet, liegt
## an seiner engsten Stelle `0,414 x r` hinter der Ecke, die er ersetzt. Damit die Weltecke
## (`RIM_ABSTAND x sqrt(2)` von der Rechteckecke entfernt) INNERHALB bleibt, muss gelten
## `0,414 x r <= 1,414 x RIM_ABSTAND`, also `r <= 3,41 x RIM_ABSTAND`. Mit Luft: 2,8.
const RIM_ECK_R: float = 600.0
const RIM_ECK_STUFEN: int = 10

static func rim_ring(w: float) -> PackedVector2Array:
	# Die Aussenkontur: das Weltquadrat, um RIM_ABSTAND aufgeblasen.
	var x0: float = -RIM_ABSTAND
	var x1: float = w + RIM_ABSTAND
	var z0: float = RIM_ABSTAND          # Sued (groesseres z)
	var z1: float = -w - RIM_ABSTAND     # Nord
	# Nach oben gebunden (siehe RIM_ECK_R): Sonst schneidet die Rundung die Weltecken ab.
	var r: float = minf(RIM_ECK_R, minf((x1 - x0) * 0.5 - 1.0, RIM_ABSTAND * 2.8))
	var punkte := PackedVector2Array()
	# Vier Ecken, je als Bogen um ihren Mittelpunkt. Reihenfolge im Uhrzeigersinn in der
	# x/z-Ebene; sie ist gleichgueltig, solange sie RUNDHERUM geht.
	#
	# Die Winkel sind in der Ebene (x nach rechts, NORDEN nach oben) gemeint, also 0° = Osten,
	# 90° = Norden. Der erste Versuch startete jeden Bogen 90° zu frueh; der Ring lief dann durch
	# die Welt statt um sie herum, und der groesste Knick betrug 95° statt der 90°, die er
	# ersetzen sollte. Der Test hat es gefangen — die Zeichnung im Kopf nicht.
	var ecken: Array = [
		[Vector2(x1 - r, z0 - r), 270.0],      # Suedost: von Sueden nach Osten
		[Vector2(x1 - r, z1 + r), 0.0],        # Nordost: von Osten nach Norden
		[Vector2(x0 + r, z1 + r), 90.0],       # Nordwest: von Norden nach Westen
		[Vector2(x0 + r, z0 - r), 180.0],      # Suedwest: von Westen nach Sueden
	]
	for e in ecken:
		var m: Vector2 = e[0]
		var a0: float = float(e[1])
		for i in range(RIM_ECK_STUFEN + 1):
			var a: float = deg_to_rad(a0 + 90.0 * float(i) / float(RIM_ECK_STUFEN))
			# +x bei 0°, dann nach −z (Norden) drehend.
			punkte.append(m + Vector2(cos(a), -sin(a)) * r)
	return punkte


## Dieselbe Kontur als Wandstuecke — jedes Stueck eine Sehne des Rings.
static func rim_seiten(w: float) -> Array:
	var ring: PackedVector2Array = rim_ring(w)
	var raus: Array = []
	for i in ring.size():
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		var m: Vector2 = (a + b) * 0.5
		var d: Vector2 = b - a
		raus.append(["seg%d" % i, Vector3(m.x, 0.0, m.y), Vector3(d.x, 0.0, d.y)])
	return raus


## Wie hoch der Kamm an dieser Stelle steht — als Faktor auf `RIM_H`, `s` ist die Bogenlaenge.
##
## ## Warum der Rand ein PROFIL braucht
##
## Weil eine schnurgerade, flache Kammlinie jede Aenderung an ihr wie einen Fehler aussehen
## laesst. Genau das war das eigentliche Problem am Horizont, und es hat drei Anlaeufe gebraucht,
## um dort anzukommen: Erst wurden die Ecken geschlossen, dann die Enden ausgeblendet, dann das
## Rechteck durch einen runden Ring ersetzt — und der Absatz im Bild blieb jedes Mal stehen.
##
## Nachgemessen hat die Kammlinie bei x = 700 auf y = 249 gelegen und bei x = 720 auf y = 278.
## Neunundzwanzig Bildpunkte auf zwanzig. Der Grund ist Perspektive und nicht Geometrie: Der
## Rand steht links 2317 m weit weg und rechts 4897 m, und ein 210-m-Grat ist aus 2,3 km doppelt
## so hoch wie aus 4,9 km. Die Rundung verteilt diesen Sprung zwar auf 942 m Bogen — nur liegt
## dieser Bogen fast in der Blickrichtung und wird auf wenige Bildpunkte zusammengedrueckt.
##
## Dagegen hilft keine Form. Was hilft, ist, dass die Linie ueberhaupt keine Gerade mehr ist:
## Ein Gebirgskamm springt staendig um dreissig Meter, und wer ihn ansieht, liest einen Sprung
## als Fels und nicht als Kante. Drei Sinus mit teilerfremden Wellenlaengen genuegen dafuer.
##
## Die Wellenlaengen stehen als WELLENLAENGEN da und nicht als Teiler im Sinus. Der erste
## Entwurf schrieb `sin(s / 71.0)` und der Kommentar daneben behauptete „71 m fuer die Zacken" —
## tatsaechlich sind es 2*pi*71 = 446 m. Der Test hat den Widerspruch gefunden, nicht das Auge:
## Ein Teiler im Sinus ist keine Wellenlaenge, und wer das einmal verwechselt, rechnet danach
## jede Aufloesung falsch.
const RIM_WELLEN: Array = [
	[2700.0, 0.20],   # die Bergzuege — was man aus fuenf Kilometern als Silhouette liest
	[1070.0, 0.13],   # Kuppen und Saettel
	[450.0, 0.07],    # die Kanten daran
]

static func rim_kamm(s: float) -> float:
	var h: float = 1.0
	var phase: float = 0.0
	for wl in RIM_WELLEN:
		h += float(wl[1]) * sin(s / float(wl[0]) * TAU + phase)
		# Fester Versatz je Welle, damit die drei nicht alle im selben Punkt ihren Scheitel
		# haben — sonst stuende dort ein einzelner Gipfel von 40 % ueber allem anderen.
		phase += 1.7
	return h


## Die kuerzeste Welle im Kamm — daran misst sich, wie fein er aufgeloest werden muss.
static func rim_welle_kurz() -> float:
	var k: float = INF
	for wl in RIM_WELLEN:
		k = minf(k, float(wl[0]))
	return k


## Wie fein der Kamm laengs aufgeloest wird (Meter). Rund ein Zehntel der kuerzesten Welle:
## Darunter kostet es Ecken ohne sichtbaren Gewinn, darueber faellt der Kamm zwischen die
## Stuetzpunkte und wird wieder die Gerade, die er nicht sein soll.
const RIM_LAENGS_M: float = 45.0


func _build_rim_walls(w: float, _half: float) -> void:
	# EIN Netz fuer den ganzen Ring, nicht 44 einzelne. Durchsichtige Flaechen werden je Objekt
	# sortiert; 44 Nachbarn, die sich an den Kanten beruehren, geben dem Sortierer 44 Gelegenheiten,
	# sich zu vertun. Und die Kammlinie laeuft ohnehin ueber alle Stuecke hinweg — sie braucht
	# eine durchgehende Bogenlaenge, keine, die an jeder Naht wieder bei null anfaengt.
	var ring: PackedVector2Array = rim_ring(w)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# 24 Stufen in der Hoehe: Der Verlauf laeuft ueber zwei Drittel davon, und mit zwoelf waren
	# es acht Sprossen auf 139 m — im Bild als Treppe zu sehen.
	var stufen: int = 24
	var s_lauf: float = 0.0
	for k in ring.size():
		var a: Vector2 = ring[k]
		var b: Vector2 = ring[(k + 1) % ring.size()]
		var laenge: float = a.distance_to(b)
		var n: int = maxi(1, int(ceil(laenge / RIM_LAENGS_M)))
		for u in n:
			var t0: float = float(u) / float(n)
			var t1: float = float(u + 1) / float(n)
			var p0: Vector2 = a.lerp(b, t0)
			var p1: Vector2 = a.lerp(b, t1)
			var h0: float = RIM_H * rim_kamm(s_lauf + laenge * t0)
			var h1: float = RIM_H * rim_kamm(s_lauf + laenge * t1)
			for i in stufen:
				var f0: float = float(i) / float(stufen)
				var f1: float = float(i + 1) / float(stufen)
				# Die Blende rechnet in ANTEILEN der oertlichen Hoehe, nicht in Metern: Sonst
				# stuende ein hoher Gipfel oben noch voll da, waehrend die Senke daneben schon
				# ausgeblendet ist — und die Kante waere zurueck, nur waagerecht.
				for q in [[p0, f0, h0], [p1, f0, h1], [p1, f1, h1],
						[p0, f0, h0], [p1, f1, h1], [p0, f1, h0]]:
					var pk: Vector2 = q[0]
					var f: float = float(q[1])
					st.set_color(_rim_farbe(f))
					st.add_vertex(Vector3(pk.x, f * float(q[2]), pk.y))
		s_lauf += laenge
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.28, 0.22, 0.18)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# UNBELEUCHTET. Eine 210-m-Wand, die von einer festen Sonne angestrahlt wird, ist auf
	# zwei Seiten hell und auf zwei schwarz — und die schwarzen sind genau die, die als
	# Balken auffallen. Ein entfernter Grat hat ohnehin keine erkennbare Schattierung mehr.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.name = "kraterrand"
	add_child(mi)
	_rim_mats.append(m)
	_rim_farben_ziehen()


## Der Verlauf ueber die Hoehe — als DECKKRAFT, nicht als Farbe.
##
## Der erste Entwurf blendete die Scheitelfarbe nach oben in die Himmelsfarbe. Das geht nur so
## lange gut, wie der Himmel gleichmaessig ist: Am Abend steht unten Glut und oben Blau, und die
## Wand haette gegen genau eine der beiden Farben gepasst und gegen die andere als Streifen
## gestanden.
##
## Deckkraft loest das ohne jede Rechnung: Oben wird die Wand durchsichtig, und was durchscheint,
## IST der Himmel — welcher auch immer gerade dort steht. Sie hat damit keine Oberkante mehr, an
## der etwas abschneidet, und braucht keine Anpassung an die Tageszeit.
## `anteil` ist die Hoehe als Bruchteil der OERTLICHEN Kammhoehe, nicht in Metern — siehe
## `rim_kamm`: Der Kamm schwankt um ein Fuenftel, und eine Blende in festen Metern haette an
## jeder Kuppe anders gegriffen als in der Senke daneben.
func _rim_farbe(anteil: float) -> Color:
	return Color(1.0, 1.0, 1.0, 1.0 - smoothstep(RIM_FELS_ANTEIL, 1.0, anteil))


## Die Waende an die Tageszeit anpassen.
##
## Nur noch die Grundfarbe: Unbeleuchteter Fels bliebe nachts genauso braun wie mittags und
## leuchtete dann gegen eine schwarze Nacht. Ein Viertel Himmel daruntergemischt haelt ihn
## dunkel, wenn es dunkel ist.
func _rim_farben_ziehen() -> void:
	var himmel: Color = DayCycle.sky_color(GameState.hour)
	for m in _rim_mats:
		var sm: StandardMaterial3D = m
		sm.albedo_color = Color(0.28, 0.22, 0.18).lerp(himmel, 0.30)


# ── Steuerwalzen ──────────────────────────────────────────────────────────────
## Eine Erinnerung bergen und zeigen.
##
## Gezeigt wird sie als Sprechtafel unter dem HELDENNAMEN, nicht als Fundmeldung. Eine
## Erinnerung ist kein Gegenstand, den man einsteckt — sie faellt jemandem ein. Deshalb steht
## sie in derselben Tafel, in der er auch sonst mit sich selbst redet.
##
## `erzwingen` ist fuer den ersten Fund im Prolog: Der Anfang einer Geschichte darf nicht
## auswuerfeln, ob sie stattfindet — dieselbe Regel wie beim Karabiner in der Truhe.
func _walze_bergen(ist_boss: bool, erzwingen: bool = false) -> void:
	var m: Dictionary = MemoryManager.try_recover_memory(ist_boss, 0.0 if erzwingen else -1.0)
	if m.is_empty():
		return
	_say("◫ Eine Steuerwalze. Sie laeuft noch.", 2.6)
	_play_speech(HELD_NAME, "held", [
		"„Da ist eine Walze drin. Sie dreht sich noch.“",
		"„%s“" % String(m.get("title", "")),
		"„%s“" % String(m.get("text", "")),
		"„…das war nicht meine Erinnerung. Das ist sie aber.“",
	])


# ── Die erste Truhe ───────────────────────────────────────────────────────────
## Eine kurze Nahaufnahme auf den Fund, und der Held sagt, was er nicht erklaeren kann.
##
## Kein Rundflug: Hier geht es um einen Gegenstand in zwei Haenden, nicht um einen Ort. Die
## Kamera geht heran, bleibt stehen, geht zurueck. Drei Wegpunkte, gut sechs Sekunden.
const TRUHE_SEK_HIN: float = 2.2
const TRUHE_SEK_HALT: float = 2.6
const TRUHE_SEK_HEIM: float = 1.6
func _erste_truhe_szene(at: Vector3) -> void:
	if _cam == null or _player == null:
		return
	var heim: Transform3D = _cam.global_transform
	var hin := Vector3(at.x - _player.position.x, 0.0, at.z - _player.position.z)
	if hin.length() < 0.5:
		hin = -_player.global_transform.basis.z
	hin = Vector3(hin.x, 0.0, hin.z).normalized()
	var brust: Vector3 = _player.position + Vector3(0.0, 1.15, 0.0)
	var nah: Vector3 = _player.position + hin * 2.2 + Vector3(0.0, 1.5, 0.0)
	_play_flight([
		{ "pos": nah, "ziel": brust, "sek": TRUHE_SEK_HIN, "fov": 42.0 },
		{ "pos": nah, "ziel": brust, "sek": TRUHE_SEK_HALT, "fov": 40.0 },
		{ "pos": heim.origin, "ziel": heim.origin - heim.basis.z * 10.0,
			"sek": TRUHE_SEK_HEIM, "fov": CAM_FOV },
	])
	_play_speech(HELD_NAME, "held", [
		"„Ein Karabiner. Lauf voller Sand.“",
		"„Er passt in meine Hand, als hätte ich das schon tausendmal gemacht.“",
		"„Woher weiß ich das?“",
	])


# ── Der Steg über den Riss ────────────────────────────────────────────────────
## Eine umgestürzte Werkslok liegt quer im Spalt. Darüber kommt man hinüber.
##
## Eine Brücke wäre die naheliegende Antwort und die langweiligste: Sie sagt „hier ist der
## Übergang vorgesehen". Ein Waggon, der irgendwann irgendwo hineingestürzt ist, sagt etwas
## anderes — dass hier einmal etwas passiert ist und dass der Weg ein **Fund** ist und keine
## Freischaltung. Deshalb liegt er auch von Anfang an da: Nichts wird aufgeschlossen, man muss
## nur die richtige Stelle finden.
##
## Er liegt bei 38 % der Rissläge und nicht in der Mitte. Die Mitte wäre die Stelle, an der man
## zuerst nachsieht, und dann wäre das Suchen keins.
const STEG_ANTEIL: float = 0.38
const STEG_BREITE_M: float = 3.4        # begehbare Breite auf dem Kessel
const STEG_HOEHE_M: float = -1.6        # so tief liegt er unter der Ebene
var _steg: Dictionary = {}


func _build_steg() -> void:
	if _riss.is_empty():
		return
	var c: Vector3 = WorldManager.feature_center(_riss)
	var nord: bool = String(_riss.get("achse", "nord")) == "nord"
	var laengs: float = (STEG_ANTEIL - 0.5) * float(_riss["laenge"])
	# Die Mittellinie des Risses an dieser Stelle SUCHEN, nicht rechnen: Er schlängelt, und ein
	# Steg, der die Rechnung nachbaut, liegt beim nächsten Umbau daneben.
	var mitte := Vector3(c.x, 0.0, c.z)
	if nord:
		mitte.z += laengs
	else:
		mitte.x += laengs
	var tiefste: float = 0.0
	var quer_best: float = 0.0
	var spanne: float = float(_riss.get("schlenker", 0.0)) + float(_riss["breite"])
	for i in 241:
		var q: float = -spanne + float(i) * (spanne * 2.0 / 240.0)
		var px: float = mitte.x + (q if nord else 0.0)
		var pz: float = mitte.z + (0.0 if nord else q)
		var h: float = WorldManager.height_at(px, pz)
		if h < tiefste:
			tiefste = h
			quer_best = q
	if nord:
		mitte.x += quer_best
	else:
		mitte.z += quer_best
	mitte.y = STEG_HOEHE_M
	var quer: Vector3 = Vector3(1.0, 0.0, 0.0) if nord else Vector3(0.0, 0.0, 1.0)
	_steg = { "mitte": mitte, "quer": quer, "nord": nord,
		"halb_quer": float(_riss["breite"]) * 0.5 + float(_riss.get("kante_m", 6.0)),
		"halb_laengs": STEG_BREITE_M * 0.5 }
	var lok: Node3D = AssetRegistry.instantiate("locomotive", 0.0, false)
	if lok == null:
		# Kein Modell: dann eben ein Balken. Sichtbar ein Platzhalter — aber begehbar, und das
		# ist der Teil, an dem die Welt hängt.
		lok = _box(Vector3(float(_riss["breite"]) + 12.0, 2.2, STEG_BREITE_M),
			mitte + Vector3(0.0, 1.1, 0.0), Color(0.20, 0.17, 0.15))
	else:
		lok.position = mitte + Vector3(0.0, 0.6, 0.0)
		# Quer über den Spalt und auf der Seite liegend — er ist hineingestürzt, nicht abgestellt.
		lok.rotation = Vector3(0.0, 0.0 if nord else PI * 0.5, PI * 0.5)
		add_child(lok)
	_label(mitte + Vector3(0.0, 4.0, 0.0), "⇄ Der gestürzte Kessel",
		Color(0.80, 0.76, 0.68), LBL_LANDMARKE, 320.0)


## Steht dieser Punkt auf dem Steg?
func _auf_steg(p: Vector3) -> bool:
	if _steg.is_empty():
		return false
	var dx: float = p.x - Vector3(_steg["mitte"]).x
	var dz: float = p.z - Vector3(_steg["mitte"]).z
	var quer: float = dx if bool(_steg["nord"]) else dz
	var laengs: float = dz if bool(_steg["nord"]) else dx
	return absf(quer) <= float(_steg["halb_quer"]) \
		and absf(laengs) <= float(_steg["halb_laengs"])


## Die Bodenhöhe, auf der die Figur steht — Gelände, oder der Steg, wenn sie darauf ist.
func _boden_hoehe(x: float, z: float) -> float:
	if _auf_steg(Vector3(x, 0.0, z)):
		return STEG_HOEHE_M + 1.2
	return WorldManager.height_at(x, z)


## Eine Biom-Toenung, die am Rand AUSBLENDET.
##
## Sie war ein Zylinder mit gleichmaessiger Deckkraft, und im Bild zog sich dadurch eine harte
## Linie quer durch die Wueste: hier gruenlich, einen Schritt weiter sandfarben. Ein Biom ist
## aber keine Verwaltungsgrenze — es hoert nicht auf, es wird weniger.
##
## Ein Zylinder kann das nicht: Seine Deckkraft steht im Material und gilt ueberall gleich.
## Also ein Faecher aus Dreiecken mit Scheitelfarben — in der Mitte volle Deckkraft, zum Rand
## hin null. Die inneren zwei Drittel bleiben satt, damit die Toenung noch etwas taugt; nur das
## aeussere Drittel laeuft aus.
const BIOM_KERN: float = 0.62
func _biom_scheibe(radius: float, farbe: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg: int = 72
	var ringe: int = 6
	for i in seg:
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		for k in ringe:
			var t0: float = float(k) / float(ringe)
			var t1: float = float(k + 1) / float(ringe)
			for e in [[a0, t0], [a1, t0], [a1, t1], [a0, t0], [a1, t1], [a0, t1]]:
				var w: float = float(e[0])
				var t: float = float(e[1])
				st.set_color(Color(farbe.r, farbe.g, farbe.b,
					BIOME_TINT_ALPHA * (1.0 - smoothstep(BIOM_KERN, 1.0, t))))
				st.add_vertex(Vector3(cos(w) * radius * t, 0.0, sin(w) * radius * t))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Nicht in den Tiefenpuffer schreiben: Die Toenung liegt UEBER dem Boden und soll ihn
	# einfaerben, nicht verdecken — dasselbe wie beim Smog- und Sumpfschleier.
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Trifft dieser Tipp einen Trabanten? Loest ihn dann aus.
##
## Ein Trabant hat keinen Halte-Zustand wie der Schussknopf: Trinken ist eine Handlung, kein
## Dauerfeuer. Er blinkt kurz auf und ist wieder aus.
func _trabant_tap(at: Vector2) -> bool:
	for t in _trabanten:
		var s: ActionSatellite = t
		if not is_instance_valid(s) or not s.hits(at):
			continue
		s.druecken(true)
		s.druecken(false)
		return true
	return false


## Die Trabanten um den Schussknopf legen.
##
## Gerechnet aus SEINER Mitte und nicht aus der Bildschirmecke: Wer den Schussknopf verschiebt
## oder vergroessert, nimmt sie mit. Und der Abstand ist die Summe beider Radien plus Spalt —
## so beruehren sich die Trefferflaechen nicht, und ein Fehlgriff landet auf dem Schuss statt
## auf dem Trank.
func _trabanten_setzen() -> void:
	if _fire_btn == null or _trabanten.is_empty():
		return
	var mitte: Vector2 = _fire_btn.position + _fire_btn.size * 0.5
	var abstand: float = FireButton.RADIUS + ActionSatellite.RADIUS + ActionSatellite.SPALT
	for i in _trabanten.size():
		var s: ActionSatellite = _trabanten[i]
		if not is_instance_valid(s):
			continue
		var w: float = deg_to_rad(float(TRABANT_WINKEL[i % TRABANT_WINKEL.size()]))
		# Godots y zeigt nach unten — ein Winkel von 0° ist damit rechts, und positive Winkel
		# laufen im Bild nach oben, wenn man den Sinus abzieht.
		s.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var ziel: Vector2 = mitte + Vector2(cos(w), -sin(w)) * abstand
		# Und dann INS BILD geklemmt. Der Winkel oben ist so gewaehlt, dass das gar nicht noetig
		# sein sollte — aber genau dieser Knopf lag schon einmal halb ausserhalb, weil niemand
		# nachgerechnet hatte, wie nah der Schussknopf selbst am Rand klebt. Eine Klemme kostet
		# zwei Zeilen; ein Trank, den man im Gefecht nicht treffen kann, kostet den Spieler.
		var bild: Vector2 = Vector2(get_viewport().get_visible_rect().size)
		var rand: float = ActionSatellite.RADIUS + TRABANT_LUFT
		ziel.x = clampf(ziel.x, rand, maxf(rand, bild.x - rand))
		ziel.y = clampf(ziel.y, rand, maxf(rand, bild.y - rand))
		s.position = ziel - Vector2(ActionSatellite.RADIUS, ActionSatellite.RADIUS)
